#include "clangd_server.h"
#include "lsp/error.h"

#include <imedit/editor.h>

#include <lsp/messages.h>

#include <unistd.h>

#include <iostream>

namespace {
    template <typename PrintableT>
    void print_val(PrintableT&& v, const char* name, unsigned int indent) {
        while (indent--) {
            std::cout << "  ";
        }
        std::cout << name << ": " << v << '\n';
    }

    template <typename PrintableT>
    void print_val(const std::vector<PrintableT>& vect, const char* name, unsigned int indent) {
        while (indent--) {
            std::cout << "  ";
        }
        std::cout << name << ": ";
        for (const PrintableT& p : vect) {
            std::cout << '\'' << p << "' ";
        }
        std::cout << '\n';
    }
}

clangd_server::clangd_server(const std::filesystem::path &path_to_language_server)
{
    if (!std::filesystem::is_regular_file(path_to_language_server) || access(path_to_language_server.c_str(), X_OK) != F_OK) {
        throw std::runtime_error("\"" + path_to_language_server.generic_string() + "\" is not an executable file");
    }

    if (pipe(_parent_to_child_fd) == -1) {
        throw std::runtime_error("Failed to init Client > Server pipes");
    }

    if (pipe(_child_to_parent_fd) == -1) {
        close(_parent_to_child_fd[0]);
        close(_parent_to_child_fd[1]);
        throw std::runtime_error("Failed to init Server > Client pipes");
    }

    pid_t pid = fork();
    if (pid == -1) {
        close_pipes();
        throw std::runtime_error("Failed to fork process");
    }

    if (pid == 0) {
        dup2(_parent_to_child_fd[0], STDIN_FILENO);
        dup2(_child_to_parent_fd[1], STDOUT_FILENO);
        std::string arg1_str = "-offset-encoding=utf-8"; // needs non const char * for execve
        std::string arg0_str = path_to_language_server.generic_string();
        char* const args[] = {arg0_str.data(), arg1_str.data(), nullptr};
        execve(path_to_language_server.c_str(), args, nullptr);
    }

    _input_filebuf = {_child_to_parent_fd[0], std::ios_base::in};
    _output_filebuf = {_parent_to_child_fd[1], std::ios_base::out};

    _input_stream.emplace(&_input_filebuf);
    _output_stream.emplace(&_output_filebuf);

    _connection.emplace(*_input_stream, *_output_stream);
    _msg_handler.emplace(*_connection);

    _incomming_message_processing_thread.emplace([this](){ process_messages(); });

    auto future_result = _msg_handler->messageDispatcher().sendRequest<lsp::requests::Initialize>(
            lsp::requests::Initialize::Params{
                    lsp::_InitializeParams{
                            .workDoneToken = {},
                            .processId = getpid(),
                            .rootUri = nullptr,
                            .capabilities = {
                                    .workspace = {},
                                    .textDocument = {},
                                    .notebookDocument = {},
                                    .window = {},
                                    .general = lsp::GeneralClientCapabilities{
                                            .staleRequestSupport = {},
                                            .regularExpressions = lsp::RegularExpressionsClientCapabilities{
                                                    .engine = "ECMAScript",
                                                    .version = {}
                                            },
                                            .markdown = {},
                                            .positionEncodings = std::vector<lsp::PositionEncodingKind>{
                                                    lsp::PositionEncodingKind::UTF8,
                                                    lsp::PositionEncodingKind::UTF16,
                                            }
                                    },
                                    .experimental = {}
                            },
                            .clientInfo = lsp::_InitializeParamsClientInfo{
                                    .name = "ImEdit",
                                    .version = "0.1"
                            },
                            .locale = {},
                            .rootPath = std::string("/tmp"),
                            .initializationOptions = {},
                            .trace = lsp::TraceValues::Verbose
                    },
                    lsp::WorkspaceFoldersInitializeParams{
                            .workspaceFolders = {}
                    }

            }
    );

    process_initialize_answer(future_result.get());

    _msg_handler->messageDispatcher().sendNotification<lsp::notifications::TextDocument_DidOpen>(
            lsp::notifications::TextDocument_DidOpen::Params{
                .textDocument = {
                        .uri = {
                                "/tmp/test.cpp"
                        },
                        .languageId = "cpp",
                        .version = _document_version++,
                        .text = ""
                }
            }
    );

}

clangd_server::~clangd_server() {
    auto request = _msg_handler->messageDispatcher().sendRequest<lsp::requests::Shutdown>();
    request.wait();

    _running = false;
    _incomming_message_processing_thread->join();
    close_pipes();
}

void clangd_server::process_messages() {
    while (_running) {
        _msg_handler->processIncomingMessages();
        std::this_thread::sleep_for(std::chrono::microseconds(100));
    }
}

void clangd_server::close_pipes() {
    close(_parent_to_child_fd[0]);
    close(_parent_to_child_fd[1]);
    close(_child_to_parent_fd[0]);
    close(_child_to_parent_fd[1]);
}

void clangd_server::process_initialize_answer(const lsp::InitializeResult & result) {
    std::cout << std::boolalpha;
    if (result.serverInfo) {
        std::cout << "server info:\n";
        print_val(result.serverInfo->name, "name", 1);
        if (result.serverInfo->version) {
            print_val(result.serverInfo->version.value(), "value", 1);
        }
    }
    std::cout << "capabilities:\n";
    if (result.capabilities.positionEncoding) {
        print_val(result.capabilities.positionEncoding.value().value(), "position_encoding", 1);
        if (*result.capabilities.positionEncoding == lsp::PositionEncodingKind::ValueIndex::UTF8) {
            _lsp_conf.position_encoding = lsptypes::encoding::utf8;
        }
    }
    if (result.capabilities.textDocumentSync) {
        std::cout << "  text doc sync:\n";
        std::visit([this](auto&& v) {
            if constexpr (std::is_same_v<std::decay_t<decltype(v)>, lsp::TextDocumentSyncKind>) {
                std::string str;
                switch(v) {
                    case lsp::TextDocumentSyncKind::Full:
                        str = "Full";
                        break;
                    case lsp::TextDocumentSyncKind::Incremental:
                        str = "Incremental";
                        _lsp_conf.support_incremental_file_change = true;
                        break;
                    default:
                        str = "None";
                        break;
                }
                print_val(str, "text_document_sync_kind", 2);
            }
            else {
                if (v.openClose) {
                    print_val(v.openClose.value(), "open_close", 2);
                    _lsp_conf.support_open_close_notifications = v.openClose.value();
                }
                if (v.change) {
                    std::string str;
                    switch(v.change.value()) {
                        case lsp::TextDocumentSyncKind::Full:
                            str = "Full";
                            break;
                        case lsp::TextDocumentSyncKind::Incremental:
                            str = "Incremental";
                            _lsp_conf.support_incremental_file_change = true;
                            break;
                        default:
                            str = "None";
                            break;
                    }
                    print_val(str, "text_document_sync_kind", 2);
                }
                if (v.willSave) {
                    print_val(v.willSave.value(), "will_save", 2);
                    _lsp_conf.support_send_will_save_notifications = v.willSave.value();
                }
                if (v.willSaveWaitUntil) {
                    print_val(v.willSaveWaitUntil.value(), "will_save_wait_until", 2);
                    _lsp_conf.support_wait_will_save_request = v.willSaveWaitUntil.value();
                }
                if (v.save) {
                    std::cout << "    save:\n";
                    std::visit([this](auto&& v2){
                        if constexpr (std::is_same_v<std::decay_t<decltype(v2)>, bool>) {
                            print_val(v2, "value", 3);
                            _lsp_conf.support_save_notifications = v2;
                        } else if (v2.includeText){
                            print_val(v2.includeText.value(), "include_text", 3);
                            _lsp_conf.support_save_notifications = true;
                            _lsp_conf.send_text_on_save = v2.includeText.value();
                        }
                    }, v.save.value());
                }
            }
        }, result.capabilities.textDocumentSync.value());
    }

    if (result.capabilities.completionProvider) {
        std::cout << "  completion provider:\n";
        const lsp::CompletionOptions& completion = result.capabilities.completionProvider.value();
        if (completion.workDoneProgress) {
            print_val(completion.workDoneProgress.value(), "work done progress?", 2);
        }
        if (completion.triggerCharacters) {
            _lsp_conf.completion_option_trigger_characters = *completion.triggerCharacters;
            print_val(completion.triggerCharacters.value(), "trigger characters", 2);
        }
        if (completion.allCommitCharacters) {
            print_val(completion.allCommitCharacters.value(), "all commit characters", 2);
        }
        if (completion.resolveProvider) {
            _lsp_conf.is_completion_resolve_provider = *completion.resolveProvider;
            print_val(completion.resolveProvider.value(), "resolve provider", 2);
        }
        if (completion.completionItem && completion.completionItem->labelDetailsSupport) {
            print_val(completion.completionItem->labelDetailsSupport.value(), "label details support", 2);
        }
    }

    // TODO prints?
    if (result.capabilities.hoverProvider) {
        std::visit([this](auto&& val) {
            if constexpr (std::is_same_v<std::decay_t<decltype(val)>, bool>) {
                _lsp_conf.is_hover_provider = val;
            } else {
                _lsp_conf.is_hover_provider = true;
            }
        }, result.capabilities.hoverProvider.value());
    }

    if (result.capabilities.signatureHelpProvider) {
        _lsp_conf.is_signature_help_provider = true;
    }

    if (result.capabilities.declarationProvider) {
        std::visit([this](auto&& val) {
            if constexpr (std::is_same_v<std::decay_t<decltype(val)>, bool>) {
                _lsp_conf.is_declaration_provider = val;
            } else {
                _lsp_conf.is_declaration_provider = true;
            }
        }, result.capabilities.declarationProvider.value());
    }

    if (result.capabilities.definitionProvider) {
        std::visit([this](auto&& val) {
            if constexpr (std::is_same_v<std::decay_t<decltype(val)>, bool>) {
                _lsp_conf.is_definition_provider = val;
            } else {
                _lsp_conf.is_definition_provider = true;
            }
        }, result.capabilities.definitionProvider.value());
    }

    if (result.capabilities.typeDefinitionProvider) {
        std::visit([this](auto&& val) {
            if constexpr (std::is_same_v<std::decay_t<decltype(val)>, bool>) {
                _lsp_conf.is_type_definition_provider = val;
            } else {
                _lsp_conf.is_type_definition_provider = true;
            }
        }, result.capabilities.typeDefinitionProvider.value());
    }

    if (result.capabilities.implementationProvider) {
        std::visit([this](auto&& val) {
            if constexpr (std::is_same_v<std::decay_t<decltype(val)>, bool>) {
                _lsp_conf.is_implementation_provider = val;
            } else {
                _lsp_conf.is_implementation_provider = true;
            }
        }, result.capabilities.implementationProvider.value());
    }

    if (result.capabilities.colorProvider) {
        std::visit([this](auto&& val) {
            if constexpr (std::is_same_v<std::decay_t<decltype(val)>, bool>) {
                _lsp_conf.is_color_provider = val;
            } else {
                _lsp_conf.is_color_provider = true;
            }
        }, result.capabilities.colorProvider.value());
    }

    if (result.capabilities.semanticTokensProvider) {
        std::visit([this](auto&& val) {
            _lsp_conf.supports_semantic_tokens = true;
            _lsp_conf.token_modifiers = val.legend.tokenModifiers;
            _lsp_conf.token_types = val.legend.tokenTypes;
        }, result.capabilities.semanticTokensProvider.value());
    }




    std::unordered_map<std::string, ImEdit::token_type::enum_> str_to_tok_table;

    str_to_tok_table["variable"] = ImEdit::token_type::variable;
    str_to_tok_table["parameter"] = ImEdit::token_type::function;
    str_to_tok_table["function"] = ImEdit::token_type::function;
    str_to_tok_table["method"] = ImEdit::token_type::variable;
    str_to_tok_table["function"] = ImEdit::token_type::type;
    str_to_tok_table["property"] = ImEdit::token_type::unknown;
    str_to_tok_table["class"] = ImEdit::token_type::type;
    str_to_tok_table["interface"] = ImEdit::token_type::type;
    str_to_tok_table["enum"] = ImEdit::token_type::type;
    str_to_tok_table["enumMember"] = ImEdit::token_type::constant;
    str_to_tok_table["type"] = ImEdit::token_type::type;
    str_to_tok_table["unknown"] = ImEdit::token_type::unknown;
    str_to_tok_table["namespace"] = ImEdit::token_type::unknown;
    str_to_tok_table["typeParameter"] = ImEdit::token_type::type;
    str_to_tok_table["concept"] = ImEdit::token_type::type;
    str_to_tok_table["macro"] = ImEdit::token_type::preprocessor;
    str_to_tok_table["modifier"] = ImEdit::token_type::unknown;
    str_to_tok_table["operator"] = ImEdit::token_type::operators;
    str_to_tok_table["bracket"] = ImEdit::token_type::opening;
    str_to_tok_table["label"] = ImEdit::token_type::type;
    str_to_tok_table["comment"] = ImEdit::token_type::comment;
    str_to_tok_table["struct"] = ImEdit::token_type::type;
    str_to_tok_table["enum"] = ImEdit::token_type::type;
    str_to_tok_table["interface"] = ImEdit::token_type::type;
    str_to_tok_table["typeParameter"] = ImEdit::token_type::type;
    str_to_tok_table["parameter"] = ImEdit::token_type::variable;
    str_to_tok_table["variable"] = ImEdit::token_type::variable;
    str_to_tok_table["property"] = ImEdit::token_type::variable;
    str_to_tok_table["event"] = ImEdit::token_type::unknown;
    str_to_tok_table["function"] = ImEdit::token_type::function;
    str_to_tok_table["method"] = ImEdit::token_type::function;
    str_to_tok_table["macro"] = ImEdit::token_type::preprocessor;
    str_to_tok_table["keyword"] = ImEdit::token_type::keyword;
    str_to_tok_table["modifier"] = ImEdit::token_type::keyword;
    str_to_tok_table["comment"] = ImEdit::token_type::comment;
    str_to_tok_table["string"] = ImEdit::token_type::string_literal;
    str_to_tok_table["number"] = ImEdit::token_type::num_literal;
    str_to_tok_table["regexp"] = ImEdit::token_type::unknown;
    str_to_tok_table["operator"] = ImEdit::token_type::operator_;
    str_to_tok_table["decorator"] = ImEdit::token_type::keyword;


    for (const std::string& token_type : _lsp_conf.token_types) {
        _token_type_jump_table.emplace_back(str_to_tok_table.at(token_type));
    }

    std::cout << std::boolalpha;
}

void clangd_server::setup_editor(ImEdit::editor &ed) {


    ed._on_data_modified_data = this;
    ed._on_data_modified_new_line = [](std::any lsp, unsigned int new_line_idx, ImEdit::editor& e){
        std::any_cast<clangd_server*>(lsp)->newline_created(e, new_line_idx);
    };
    ed._on_data_modified_region_deleted = [](std::any lsp, ImEdit::region region, ImEdit::editor& e){
        std::any_cast<clangd_server*>(lsp)->region_deleted(e, region);
    };
    ed._on_data_modified_line_changed = [](std::any lsp, unsigned int line_idx, const ImEdit::line& before, ImEdit::editor& e) {
        std::any_cast<clangd_server*>(lsp)->line_changed(e, line_idx, before);
    };
    ed._on_data_modified_newline_delete = [](std::any lsp, unsigned int old_line_idx, ImEdit::editor& e){
        std::any_cast<clangd_server*>(lsp)->newline_deleted(e, old_line_idx);
    };
}

void clangd_server::line_changed(ImEdit::editor &ed, unsigned int, const ImEdit::line&) {
    request_token_update(ed);
}

void clangd_server::region_deleted(ImEdit::editor &ed, ImEdit::region) {
    request_token_update(ed);
}

void clangd_server::newline_deleted(ImEdit::editor &ed, unsigned int) {
    request_token_update(ed);
}

void clangd_server::newline_created(ImEdit::editor &ed, unsigned int) {
    request_token_update(ed);
}

void clangd_server::request_token_update(ImEdit::editor& ed) {

    lsp::VersionedTextDocumentIdentifier vtdi;
    vtdi.uri = std::string("/tmp/test.cpp");
    vtdi.version = _document_version++;

    std::string str;
    std::copy(ed.begin(), ed.end(), std::back_inserter(str));

    _msg_handler->messageDispatcher().sendNotification<lsp::notifications::TextDocument_DidChange>(
        lsp::notifications::TextDocument_DidChange::Params{
                .textDocument{
                    vtdi
                },
                .contentChanges{
                        lsp::TextDocumentContentChangeEvent{
                                lsp::TextDocumentContentChangeEvent_Text{
                                        str
                                }
                        }
                }
        }
    );

    _pending_requests_results.emplace_back(
            _msg_handler->messageDispatcher().sendRequest<lsp::requests::TextDocument_SemanticTokens_Full>(
            lsp::requests::TextDocument_SemanticTokens_Full::Params{
                .workDoneToken = {},
                .partialResultToken = {},
                .textDocument = {
                        .uri = std::string("/tmp/test.cpp")
                }
            })
    );
}

void clangd_server::update(ImEdit::editor &editor) {
    for (auto it = _pending_requests_results.begin() ; it != _pending_requests_results.end() ;) {
        if (it->wait_for(std::chrono::seconds(0)) == std::future_status::ready) {
            try {
                process_semantics(it->get(), editor);
            } catch (lsp::ResponseError& e) {
                std::cerr << e.what();
            }
            it = _pending_requests_results.erase(it);
        } else {
            ++it;
        }
    }
}

void clangd_server::process_semantics(const lsp::TextDocument_SemanticTokens_FullResult &toks, ImEdit::editor& ed) {
    if (toks.isNull()) {
        return;
    }

    unsigned int last_line = 0;
    unsigned int last_char_idx = 0;
    for (unsigned int i = 0 ; i < toks.value().data.size() ; i += 5) {
        auto& data = toks.value().data;
        assert(i + 4 < toks.value().data.size());
        auto line = last_line + data[i];
        auto char_idx = (line != last_line) ? data[i + 1] : (data[i + 1] + last_char_idx);

        last_line = line;
        last_char_idx = char_idx;

        ImEdit::token_view token;
        token.char_idx = char_idx;
        token.length = data[i + 2];
        token.type = _token_type_jump_table[data[i + 3]];

        ed.add_token(line, token);
    }

}
