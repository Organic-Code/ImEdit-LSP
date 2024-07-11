#include "language_server.h"

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

language_server::language_server(const std::filesystem::path &path_to_language_server)
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
        execve(path_to_language_server.c_str(), nullptr, nullptr);
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
                            .rootPath = {},
                            .initializationOptions = {},
                            .trace = {}
                    },
                    lsp::WorkspaceFoldersInitializeParams{
                            .workspaceFolders = {}
                    }

            }
    );

    process_initialize_answer(future_result.get());

}

language_server::~language_server() {
    auto request = _msg_handler->messageDispatcher().sendRequest<lsp::requests::Shutdown>();
    request.wait();

    _running = false;
    _incomming_message_processing_thread->join();
    close_pipes();
}

void language_server::process_messages() {
    while (_running) {
        _msg_handler->processIncomingMessages();
        std::this_thread::sleep_for(std::chrono::microseconds(100));
    }
}

void language_server::close_pipes() {
    close(_parent_to_child_fd[0]);
    close(_parent_to_child_fd[1]);
    close(_child_to_parent_fd[0]);
    close(_child_to_parent_fd[1]);
}

void language_server::process_initialize_answer(const lsp::InitializeResult & result) {
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
    if (result.capabilities.notebookDocumentSync) {
        // TODO
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
    // rest: TODO



    std::cout << std::boolalpha;
}
