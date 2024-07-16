#ifndef IMEDIT_LS_LSP_H
#define IMEDIT_LS_LSP_H

#include <filesystem>
#include <thread>
#include <optional>
#include <list>

#include <ext/stdio_filebuf.h>

#include <lsp/connection.h>
#include <lsp/messagehandler.h>
#include <lsp/messages.h>

#include <imedit/simple_types.h>

namespace lsp {
    struct InitializeResult;
}

namespace ImEdit {
    class editor;
}

namespace lsptypes {
    enum class encoding {
        utf8,
        utf16,
        utf32
    };
}

class clangd_server {
public:
    explicit clangd_server(const std::filesystem::path& path_to_language_server);
    ~clangd_server();

    lsp::MessageHandler* operator->() noexcept {
        return &*_msg_handler;
    }

    void setup_editor(ImEdit::editor& editor);

    void update(ImEdit::editor& editor);

private:
    void process_messages();

    void process_semantics(const lsp::TextDocument_SemanticTokens_FullResult& toks, ImEdit::editor& ed);

    void close_pipes();

    void process_initialize_answer(const lsp::InitializeResult&);

    void line_changed(ImEdit::editor& ed, unsigned int line_idx, const ImEdit::line& before);
    void region_deleted(ImEdit::editor& ed, ImEdit::region old_region);
    void newline_deleted(ImEdit::editor& ed, unsigned int old_line_idx);
    void newline_created(ImEdit::editor& ed, unsigned int new_line_idx);

    void request_token_update(ImEdit::editor& ed);

    //using optionals to delay the construction of objects
    std::optional<std::thread> _incomming_message_processing_thread{};
    std::atomic_bool _running{true};

    __gnu_cxx::stdio_filebuf<char> _input_filebuf{};
    std::optional<std::istream> _input_stream{};
    __gnu_cxx::stdio_filebuf<char> _output_filebuf{};

    std::optional<std::ostream> _output_stream{};
    std::optional<lsp::Connection> _connection{};

    std::optional<lsp::MessageHandler> _msg_handler{};
    int _parent_to_child_fd[2]{};

    int _child_to_parent_fd[2]{};

    int _document_version{};

    struct {
        lsptypes::encoding position_encoding{lsptypes::encoding::utf16};
        bool support_incremental_file_change{false};
        bool support_open_close_notifications{false};
        bool support_send_will_save_notifications{false};
        bool support_wait_will_save_request{false};
        bool support_save_notifications{false};
        bool send_text_on_save{false};

        std::vector<std::string> completion_option_trigger_characters{};
        bool is_completion_resolve_provider{false};

        bool is_hover_provider{false};
        bool is_signature_help_provider{false};
        bool is_declaration_provider{false};
        bool is_definition_provider{false};
        bool is_type_definition_provider{false};
        bool is_implementation_provider{false};
        bool is_color_provider{false};

        bool supports_semantic_tokens{false};
        std::vector<std::string> token_types;
        std::vector<std::string> token_modifiers;
    } _lsp_conf{};

    std::vector<ImEdit::token_type::enum_> _token_type_jump_table;

    std::list<std::future<lsp::TextDocument_SemanticTokens_FullResult>> _pending_requests_results;

};


#endif //IMEDIT_LS_LSP_H
