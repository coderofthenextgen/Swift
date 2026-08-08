#include "overlay.h"
#include "roblox.h"
#include <imgui.h>
#include <glm/glm.hpp>

static auto get_health_color(float health, float max_health) -> ImU32 {
    float ratio = (max_health > 0) ? health / max_health : 0.f;
    if (ratio > 0.6f) return IM_COL32(0, 255, 0, 255);
    if (ratio > 0.3f) return IM_COL32(255, 255, 0, 255);
    return IM_COL32(255, 0, 0, 255);
}

static auto get_distance_color(float dist) -> ImU32 {
    if (dist < 50.f)  return IM_COL32(0, 255, 0, 255);
    if (dist < 150.f) return IM_COL32(255, 255, 0, 255);
    return IM_COL32(255, 80, 80, 255);
}

auto render_esp(float screen_w, float screen_h) -> void {
    auto* draw_list = ImGui::GetBackgroundDrawList();
    if (!draw_list) return;

    const auto& players = g_roblox.get_players();
    auto w2s = [&](const glm::vec3& world) -> std::optional<glm::vec2> {
        return g_roblox.world_to_screen(world, screen_w, screen_h);
    };

    float center_x = screen_w / 2.f;
    float bottom_y = screen_h;

    for (const auto& player : players) {
        if (player.model_address == 0) continue;

        auto root_pos = w2s(player.position);
        if (!root_pos) continue;

        float dist = 0.f;
        auto cam_pos = g_roblox.get_camera_position();
        if (cam_pos) {
            dist = glm::length(player.position - *cam_pos);
        }

        RobloxInstance model{player.model_address};
        auto head = model.find_first_child("Head");

        glm::vec3 head_pos = player.position;
        head_pos.y += 3.5f;

        auto head_screen = w2s(head_pos);
        if (!head_screen) continue;

        float box_h = std::abs(head_screen->y - root_pos->y) * 1.2f;
        float box_w = box_h * 0.6f;

        float x1 = root_pos->x - box_w / 2.f;
        float y1 = root_pos->y - box_h;
        float x2 = root_pos->x + box_w / 2.f;
        float y2 = root_pos->y;

        ImU32 dist_color = get_distance_color(dist);
        draw_list->AddRect(ImVec2(x1, y1), ImVec2(x2, y2), dist_color, 0.f, 0, 1.5f);

        draw_list->AddLine(
            ImVec2(center_x, bottom_y),
            ImVec2(root_pos->x, y2),
            IM_COL32(255, 255, 255, 60), 1.f
        );

        draw_list->AddCircleFilled(
            ImVec2(root_pos->x, y2),
            3.f, dist_color
        );

        std::string name_text = player.name;
        if (player.user_id > 0) {
            name_text += " [" + std::to_string(player.user_id) + "]";
        }

        auto text_size = ImGui::CalcTextSize(name_text.c_str());
        draw_list->AddText(
            ImVec2(root_pos->x - text_size.x / 2.f, y1 - text_size.y - 2.f),
            dist_color,
            name_text.c_str()
        );

        if (player.max_health > 0) {
            float bar_w = box_w;
            float bar_h = 3.f;
            float bar_x = x1;
            float bar_y = y1 - bar_h - 4.f;

            draw_list->AddRectFilled(
                ImVec2(bar_x, bar_y),
                ImVec2(bar_x + bar_w, bar_y + bar_h),
                IM_COL32(50, 50, 50, 200)
            );

            draw_list->AddRectFilled(
                ImVec2(bar_x, bar_y),
                ImVec2(bar_x + bar_w, bar_y + bar_h),
                get_health_color(player.max_health, player.max_health)
            );
        }

        if (dist > 0) {
            char dist_buf[32];
            snprintf(dist_buf, sizeof(dist_buf), "%.0f studs", dist);
            auto dist_size = ImGui::CalcTextSize(dist_buf);
            draw_list->AddText(
                ImVec2(root_pos->x - dist_size.x / 2.f, y2 + 4.f),
                dist_color,
                dist_buf
            );
        }
    }
}

auto render_player_list() -> void {
    ImGui::SetNextWindowSize(ImVec2(320, 400), ImGuiCond_FirstUseEver);

    if (!ImGui::Begin("Exa - Players")) {
        ImGui::End();
        return;
    }

    const auto& players = g_roblox.get_players();

    ImGui::Text("Players: %zu", players.size());
    ImGui::Separator();

    ImGui::BeginChild("PlayerList", ImVec2(0, -ImGui::GetFrameHeightWithSpacing()));

    for (size_t i = 0; i < players.size(); ++i) {
        const auto& p = players[i];

        ImGui::PushID(static_cast<int>(i));

        bool open = ImGui::TreeNodeEx(
            p.name.c_str(),
            ImGuiTreeNodeFlags_Framed | ImGuiTreeNodeFlags_DefaultOpen,
            "%s", p.name.c_str()
        );

        if (open) {
            ImGui::Text("User ID: %d", p.user_id);
            ImGui::Text("Walk Speed: %.1f", p.walk_speed);
            ImGui::Text("Max Health: %.1f", p.max_health);

            ImGui::Text("Position: (%.1f, %.1f, %.1f)",
                p.position.x, p.position.y, p.position.z);

            float dist = 0.f;
            auto cam_pos = g_roblox.get_camera_position();
            if (cam_pos) {
                dist = glm::length(p.position - *cam_pos);
            }
            ImGui::Text("Distance: %.0f studs", dist);

            ImGui::TreePop();
        }

        ImGui::PopID();
    }

    ImGui::EndChild();

    ImGui::Separator();
    ImGui::TextDisabled("F1: ESP  F2: This panel  ESC: Quit");

    ImGui::End();
}
