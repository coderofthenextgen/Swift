#pragma once
#include "process.h"
#include <glm/glm.hpp>
#include <string>
#include <vector>

struct ViewMatrix {
    float m[16];
};

struct PlayerInfo {
    uintptr_t address = 0;
    uintptr_t model_address = 0;
    std::string name;
    std::string display_name;
    int user_id = 0;
    float health = 0;
    float max_health = 0;
    float walk_speed = 0;
    glm::vec3 position{0.f};
    bool is_local = false;
};

struct RobloxInstance {
    uintptr_t address = 0;

    auto get_name() const -> std::optional<std::string>;
    auto get_class_name() const -> std::optional<std::string>;
    auto get_children() const -> std::vector<RobloxInstance>;
    auto find_first_child(const std::string& name) const -> std::optional<RobloxInstance>;
    auto find_first_child_of_class(const std::string& class_name) const -> std::optional<RobloxInstance>;
    auto find_descendant_of_class(const std::string& class_name) const -> std::optional<RobloxInstance>;
    auto is_valid() const -> bool;
};

class Roblox {
public:
    auto initialize() -> bool;
    auto refresh_players() -> void;
    auto update_camera() -> bool { return update_view_matrix(); }
    auto get_players() const -> const std::vector<PlayerInfo>& { return m_players; }
    auto get_camera_position() const -> std::optional<glm::vec3>;
    auto get_view_matrix() const -> std::optional<ViewMatrix> { return m_view_matrix; }
    auto get_camera_address() const -> uintptr_t { return m_camera; }
    auto world_to_screen(const glm::vec3& world, float screen_w, float screen_h) const -> std::optional<glm::vec2>;
    auto teleport_local_player(float offset_y) const -> bool;
    auto set_camera_rotation(const glm::vec3& target_world, float smooth) -> bool;

    auto get_screen_size() const -> std::pair<float, float> { return m_screen_size; }

private:
    auto find_data_model() -> bool;
    auto find_workspace() -> bool;
    auto find_players() -> bool;
    auto find_camera() -> bool;
    auto update_view_matrix() -> bool;
    auto get_character_position(uintptr_t model_addr) const -> std::optional<glm::vec3>;

    uintptr_t m_data_model = 0;
    uintptr_t m_workspace = 0;
    uintptr_t m_players_service = 0;
    uintptr_t m_camera = 0;
    ViewMatrix m_vm{};
    std::optional<ViewMatrix> m_view_matrix;
    std::vector<PlayerInfo> m_players;
    std::pair<float, float> m_screen_size{0, 0};
};

inline Roblox g_roblox;
