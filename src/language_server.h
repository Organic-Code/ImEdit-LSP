#ifndef IMEDIT_LS_LSP_H
#define IMEDIT_LS_LSP_H

#include <filesystem>
#include <thread>
#include <optional>
#include <ext/stdio_filebuf.h>

#include <lsp/connection.h>
#include <lsp/messagehandler.h>


namespace lsp {
    struct InitializeResult;
}

namespace lsptypes {
    enum class encoding {
        utf8,
        utf16,
        utf32
    };
}

class language_server {
public:
    explicit language_server(const std::filesystem::path& path_to_language_server);
    ~language_server();

    lsp::MessageHandler* operator->() noexcept {
        return &*_msg_handler;
    }

private:
    void process_messages();

    void close_pipes();

    void process_initialize_answer(const lsp::InitializeResult&);

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
    } _lsp_conf{};
};


#endif //IMEDIT_LS_LSP_H
