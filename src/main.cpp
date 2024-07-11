
#include <imgui.h>
#include <iostream>
#include <imgui_app.h>

#include "imedit/editor.h"
#include "language_server.h"

#include <lsp/messages.h>
#include <lsp/connection.h>
#include <lsp/messagehandler.h>

#include <unistd.h>
#include <ext/stdio_filebuf.h>

int main(int, char*[])
{
    language_server ls("/usr/bin/clangd");

    IMGUI_CHECKVERSION();
    ImGui::CreateContext();

    ImGuiApp* window = ImGuiApp_ImplDefault_Create();
    window->InitCreateWindow(window, "ImEdit testing", ImVec2(1440, 900));
    window->InitBackends(window);

    while (window->NewFrame(window))
    {

        ImGui::NewFrame();

        ImGui::ShowDemoWindow();

        ImGui::Render();
        window->ClearColor = window->ClearColor;
        window->Render(window);
    }

    window->ShutdownBackends(window);
    window->ShutdownCloseWindow(window);
    ImGui::DestroyContext();
    window->Destroy(window);
}
