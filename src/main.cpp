
#include <imgui.h>
#include <iostream>
#include <imgui_app.h>

#include "imedit/editor.h"
#include "clangd_server.h"

#include <lsp/messages.h>
#include <lsp/connection.h>
#include <lsp/messagehandler.h>

#include <unistd.h>
#include <ext/stdio_filebuf.h>

int main(int, char*[])
{
    clangd_server ls("/usr/bin/clangd");

    ImEdit::editor editor("test.cpp");
    editor._style.token_style[ImEdit::token_type::constant] = ImColor(174, 129, 255, 255);
    editor._style.token_style[ImEdit::token_type::preprocessor] = ImColor(149, 117, 234, 255);
    editor._style.token_style[ImEdit::token_type::operators] = ImColor(249, 38, 114, 255);

    ls.setup_editor(editor);

    IMGUI_CHECKVERSION();
    ImGui::CreateContext();

    ImGuiApp* window = ImGuiApp_ImplDefault_Create();
    window->InitCreateWindow(window, "ImEdit testing", ImVec2(1440, 900));
    window->InitBackends(window);

    editor._width = 600;
    editor._height = 250;

    while (window->NewFrame(window))
    {

        ImGui::NewFrame();

        ImGui::ShowDemoWindow();

        ls.update(editor);

        if (ImGui::Begin("Editor")) {
            editor.render();
        }
        ImGui::End();

        ImGui::Render();
        window->ClearColor = window->ClearColor;
        window->Render(window);
    }

    window->ShutdownBackends(window);
    window->ShutdownCloseWindow(window);
    ImGui::DestroyContext();
    window->Destroy(window);
}
