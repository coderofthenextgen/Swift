#include "roblox.h"
#include "offsets.h"
#include <spdlog/spdlog.h>
#include <glm/gtc/matrix_transform.hpp>
#include <algorithm>
#include <cmath>
#include <ApplicationServices/ApplicationServices.h>

#define GLM_ENABLE_EXPERIMENTAL
#include <glm/gtx/normal.hpp>
#include <glm/gtx/quaternion.hpp>

auto RobloxInstance::get_name() const -> std::optional<std::string> {
    auto name_ptr = g_process.read<uintptr_t>(address + offsets::Instance::Name);
    if (!name_ptr || *name_ptr == 0) return std::nullopt;
    return g_process.read_sso_string(*name_ptr);
}

auto RobloxInstance::get_class_name() const -> std::optional<std::string> {
    auto class_descriptor = g_process.read<uintptr_t>(address + offsets::Instance::ClassDescriptor);
    if (!class_descriptor || *class_descriptor == 0) return std::nullopt;

    auto class_name_ptr = g_process.read<uintptr_t>(*class_descriptor + offsets::Instance::ClassName);
    if (!class_name_ptr || *class_name_ptr == 0) return std::nullopt;

    return g_process.read_sso_string(*class_name_ptr);
}

auto RobloxInstance::get_children() const -> std::vector<RobloxInstance> {
    std::vector<RobloxInstance> children;

    auto container = g_process.read<uintptr_t>(address + offsets::Instance::ChildrenStart);
    if (!container || *container == 0) return children;

    auto end = g_process.read<uintptr_t>(*container + offsets::Instance::ChildrenEnd);
    if (!end) return children;

    auto first_node = g_process.read<uintptr_t>(*container);
    if (!first_node) return children;

    auto current_addr = *first_node;
    auto end_addr = *end;

    constexpr size_t MAX_CHILDREN = 2048;
    size_t iterations = 0;

    while (current_addr != end_addr && iterations < MAX_CHILDREN) {
        auto child_addr = g_process.read<uintptr_t>(current_addr);
        if (child_addr && *child_addr != 0) {
            children.push_back({*child_addr});
        }
        current_addr += 0x10;
        iterations++;
    }

    return children;
}

auto RobloxInstance::find_first_child(const std::string& name) const -> std::optional<RobloxInstance> {
    auto children = get_children();
    for (const auto& child : children) {
        auto child_name = child.get_name();
        if (child_name && *child_name == name) {
            return child;
        }
    }
    return std::nullopt;
}

auto RobloxInstance::find_first_child_of_class(const std::string& class_name) const -> std::optional<RobloxInstance> {
    auto children = get_children();
    for (const auto& child : children) {
        auto cn = child.get_class_name();
        if (cn && *cn == class_name) {
            return child;
        }
    }
    return std::nullopt;
}

auto RobloxInstance::find_descendant_of_class(const std::string& class_name) const -> std::optional<RobloxInstance> {
    auto stack = get_children();
    while (!stack.empty()) {
        auto current = stack.back();
        stack.pop_back();

        auto cn = current.get_class_name();
        if (cn && *cn == class_name) {
            return current;
        }

        auto children = current.get_children();
        for (auto it = children.rbegin(); it != children.rend(); ++it) {
            stack.push_back(*it);
        }
    }
    return std::nullopt;
}

auto RobloxInstance::is_valid() const -> bool {
    return address != 0 && g_process.read<uint8_t>(address).has_value();
}

auto Roblox::initialize() -> bool {
    CGRect display_bounds = CGDisplayBounds(CGMainDisplayID());
    m_screen_size = {display_bounds.size.width, display_bounds.size.height};
    spdlog::info("Screen: {}x{}", (int)m_screen_size.first, (int)m_screen_size.second);

    uintptr_t ve_slot = g_process.get_module_base() + offsets::VisualEnginePointer;
    auto ve_ptr = g_process.read<uintptr_t>(ve_slot);
    if (!ve_ptr || *ve_ptr == 0) {
        spdlog::error("Failed to read VisualEngine pointer at module_base+0x{:X}", offsets::VisualEnginePointer);
        return false;
    }

    spdlog::info("VisualEngine @ 0x{:X}", *ve_ptr);

    auto fdm = g_process.read<uintptr_t>(*ve_ptr + offsets::VisualEngine::FakeDataModel);
    if (!fdm || *fdm == 0) {
        spdlog::error("Failed to read FakeDataModel");
        return false;
    }

    auto rdm = g_process.read<uintptr_t>(*fdm + offsets::FakeDataModel::RealDataModel);
    if (!rdm || *rdm == 0) {
        spdlog::error("Failed to read RealDataModel");
        return false;
    }

    m_data_model = *rdm;
    spdlog::info("DataModel @ 0x{:X}", m_data_model);

    auto dm = RobloxInstance{m_data_model};
    auto dm_children = dm.get_children();
    spdlog::info("DataModel has {} children", dm_children.size());

    for (size_t i = 0; i < std::min<size_t>(dm_children.size(), 20); ++i) {
        auto cn = dm_children[i].get_class_name();
        auto nm = dm_children[i].get_name();
        spdlog::info("  [{}] {} ({}) @ 0x{:X}",
            i,
            nm.value_or("<no name>"),
            cn.value_or("<no class>"),
            dm_children[i].address);
    }

    return find_workspace() && find_players() && find_camera();
}

auto Roblox::find_workspace() -> bool {
    auto dm = RobloxInstance{m_data_model};
    auto ws = dm.find_first_child_of_class("Workspace");
    if (!ws) {
        spdlog::error("Failed to find Workspace");
        return false;
    }
    m_workspace = ws->address;
    spdlog::info("Workspace @ 0x{:X}", m_workspace);
    return true;
}

auto Roblox::find_players() -> bool {
    auto dm = RobloxInstance{m_data_model};
    auto players = dm.find_first_child_of_class("Players");
    if (!players) {
        spdlog::error("Failed to find Players service");
        return false;
    }
    m_players_service = players->address;
    spdlog::info("Players @ 0x{:X}", m_players_service);
    return true;
}

auto Roblox::find_camera() -> bool {
    auto ws = RobloxInstance{m_workspace};
    auto cam = ws.find_first_child_of_class("Camera");
    if (!cam) {
        spdlog::error("Failed to find Camera");
        return false;
    }
    m_camera = cam->address;
    spdlog::info("Camera @ 0x{:X}", m_camera);
    return true;
}

auto Roblox::update_view_matrix() -> bool {
    struct CFrameData {
        float right[3];
        float up[3];
        float back[3];
        float position[3];
    };

    auto cf = g_process.read<CFrameData>(m_camera + offsets::Camera::CFrame);
    if (!cf) {
        static bool logged = false;
        if (!logged) { spdlog::error("Failed to read CFrame at Camera+0x{:X}", offsets::Camera::CFrame); logged = true; }
        return false;
    }

    for (int i = 0; i < 12; ++i) {
        if (!std::isfinite(cf->right[i])) {
            static bool logged = false;
            if (!logged) {
                spdlog::error("CFrame contains non-finite values");
                for (int j = 0; j < 12; ++j) spdlog::error("  cf[{}] = {}", j, cf->right[j]);
                logged = true;
            }
            return false;
        }
    }

    auto fov_rad = g_process.read<float>(m_camera + offsets::Camera::FieldOfView);
    if (!fov_rad || !std::isfinite(*fov_rad) || *fov_rad < 0.3f || *fov_rad > 3.1f) {
        static bool logged = false;
        if (!logged) { spdlog::error("Invalid FOV at Camera+0x{:X}: {}", offsets::Camera::FieldOfView,
            fov_rad ? std::to_string(*fov_rad) : "null"); logged = true; }
        return false;
    }

    glm::vec3 right(cf->right[0], cf->right[1], cf->right[2]);
    glm::vec3 up(cf->up[0], cf->up[1], cf->up[2]);
    glm::vec3 back(cf->back[0], cf->back[1], cf->back[2]);
    glm::vec3 pos(cf->position[0], cf->position[1], cf->position[2]);

    float rlen = glm::length(right);
    float ulen = glm::length(up);
    float blen = glm::length(back);
    if (rlen < 0.5f || ulen < 0.5f || blen < 0.5f) {
        static bool logged = false;
        if (!logged) { spdlog::error("CFrame vectors too short: right={} up={} back={}", rlen, ulen, blen); logged = true; }
        return false;
    }

    static bool logged_ok = false;
    if (!logged_ok) {
        spdlog::info("CFrame OK: right=({:.2f},{:.2f},{:.2f}) up=({:.2f},{:.2f},{:.2f}) back=({:.2f},{:.2f},{:.2f}) pos=({:.1f},{:.1f},{:.1f}) fov={:.1f}deg",
            right.x, right.y, right.z, up.x, up.y, up.z, back.x, back.y, back.z,
            pos.x, pos.y, pos.z, *fov_rad * 180.f / 3.14159265f);
        logged_ok = true;
    }

    right /= rlen;
    up /= ulen;
    back /= blen;

    glm::mat4 view(1.0f);
    view[0] = glm::vec4(right.x, up.x, back.x, 0.f);
    view[1] = glm::vec4(right.y, up.y, back.y, 0.f);
    view[2] = glm::vec4(right.z, up.z, back.z, 0.f);
    view[3] = glm::vec4(-glm::dot(right, pos), -glm::dot(up, pos), -glm::dot(back, pos), 1.f);

    float aspect = m_screen_size.first / m_screen_size.second;
    glm::mat4 proj = glm::perspective(*fov_rad, aspect, 0.1f, 10000.f);

    glm::mat4 vp = proj * view;

    for (int col = 0; col < 4; ++col) {
        for (int row = 0; row < 4; ++row) {
            m_vm.m[col * 4 + row] = vp[col][row];
        }
    }

    m_view_matrix = m_vm;
    return true;
}

auto Roblox::get_character_position(uintptr_t model_addr) const -> std::optional<glm::vec3> {
    RobloxInstance model{model_addr};

    auto root_part = model.find_first_child("HumanoidRootPart");
    if (!root_part) {
        auto head = model.find_first_child("Head");
        if (!head) return std::nullopt;
        root_part = head;
    }

    auto prim = g_process.read<uintptr_t>(root_part->address + offsets::BasePart::Primitive);
    if (!prim || *prim == 0) return std::nullopt;

    auto x = g_process.read<float>(*prim + offsets::Primitive::Position);
    auto y = g_process.read<float>(*prim + offsets::Primitive::Position + 4);
    auto z = g_process.read<float>(*prim + offsets::Primitive::Position + 8);

    if (!x || !y || !z) return std::nullopt;
    if (!std::isfinite(*x) || !std::isfinite(*y) || !std::isfinite(*z)) return std::nullopt;

    return glm::vec3(*x, *y, *z);
}

auto Roblox::refresh_players() -> void {
    m_players.clear();
    update_view_matrix();

    auto dm = RobloxInstance{m_data_model};

    auto players_instance = RobloxInstance{m_players_service};

    auto local_ptr = g_process.read<uintptr_t>(m_players_service + offsets::Players::LocalPlayer);
    uintptr_t local_player_addr = (local_ptr && *local_ptr) ? *local_ptr : 0;

    auto player_children = players_instance.get_children();

    for (const auto& player : player_children) {
        auto cn = player.get_class_name();
        if (!cn || *cn != "Player") continue;

        PlayerInfo info;
        info.address = player.address;
        info.is_local = (player.address == local_player_addr);
        info.name = player.get_name().value_or("Unknown");
        info.display_name = info.name;

        auto uid = g_process.read<int>(player.address + offsets::Player::UserId);
        if (uid) info.user_id = *uid;

        auto model = g_process.read<uintptr_t>(player.address + offsets::Player::ModelInstance);
        if (model && *model != 0) {
            info.model_address = *model;

            auto pos = get_character_position(*model);
            if (pos) {
                info.position = *pos;
            }

            RobloxInstance model_inst{*model};
            auto humanoid = model_inst.find_first_child_of_class("Humanoid");
            if (humanoid) {
                auto hp = g_process.read<float>(humanoid->address + offsets::Humanoid::MaxHealth);
                if (hp) info.max_health = *hp;
                auto ws = g_process.read<float>(humanoid->address + offsets::Humanoid::WalkSpeed);
                if (ws) info.walk_speed = *ws;
            }
        }

        m_players.push_back(info);
    }

    spdlog::info("Found {} players", m_players.size());
}

auto Roblox::world_to_screen(const glm::vec3& world, float screen_w, float screen_h) const -> std::optional<glm::vec2> {
    if (!m_view_matrix) return std::nullopt;

    const float* vm = m_vm.m;

    float clip_x = vm[0] * world.x + vm[4] * world.y + vm[8] * world.z + vm[12];
    float clip_y = vm[1] * world.x + vm[5] * world.y + vm[9] * world.z + vm[13];
    float clip_w = vm[3] * world.x + vm[7] * world.y + vm[11] * world.z + vm[15];

    if (clip_w < 0.1f) return std::nullopt;

    float ndc_x = clip_x / clip_w;
    float ndc_y = clip_y / clip_w;

    float screen_x = (screen_w / 2.f) + (ndc_x * screen_w / 2.f);
    float screen_y = (screen_h / 2.f) - (ndc_y * screen_h / 2.f);

    if (screen_x < -screen_w || screen_x > screen_w * 2.f) return std::nullopt;
    if (screen_y < -screen_h || screen_y > screen_h * 2.f) return std::nullopt;

    return glm::vec2(screen_x, screen_y);
}

auto Roblox::get_camera_position() const -> std::optional<glm::vec3> {
    auto x = g_process.read<float>(m_camera + offsets::Camera::Position);
    auto y = g_process.read<float>(m_camera + offsets::Camera::Position + 4);
    auto z = g_process.read<float>(m_camera + offsets::Camera::Position + 8);
    if (!x || !y || !z) return std::nullopt;
    if (!std::isfinite(*x) || !std::isfinite(*y) || !std::isfinite(*z)) return std::nullopt;
    return glm::vec3(*x, *y, *z);
}

auto Roblox::set_camera_rotation(const glm::vec3& target_world, float smooth) -> bool {
    auto cam_pos = get_camera_position();
    if (!cam_pos) {
        static bool logged = false;
        if (!logged) {
            spdlog::error("Failed to get camera position for rotation");
            logged = true;
        }
        return false;
    }

    struct CFrameData {
        float right[3];
        float up[3];
        float back[3];
        float position[3];
    };

    auto cf = g_process.read<CFrameData>(m_camera + offsets::Camera::CFrame);
    if (!cf) {
        static bool logged = false;
        if (!logged) {
            spdlog::error("Failed to read CFrame for rotation at Camera+0x{:X}", offsets::Camera::CFrame);
            logged = true;
        }
        return false;
    }

    for (int i = 0; i < 12; ++i) {
        if (!std::isfinite(cf->right[i])) {
            static bool logged = false;
            if (!logged) {
                spdlog::error("CFrame contains non-finite values for rotation");
                logged = true;
            }
            return false;
        }
    }

    glm::vec3 current_right(cf->right[0], cf->right[1], cf->right[2]);
    glm::vec3 current_up(cf->up[0], cf->up[1], cf->up[2]);
    glm::vec3 current_back(cf->back[0], cf->back[1], cf->back[2]);
    
    current_right /= glm::length(current_right);
    current_up /= glm::length(current_up);
    current_back /= glm::length(current_back);

    float t = std::clamp(smooth, 0.0f, 1.0f);

    glm::vec3 direction = glm::normalize(target_world - *cam_pos);
    glm::mat4 target_lookat = glm::lookAt(*cam_pos, target_world, glm::vec3(0.f, 1.f, 0.f));
    
    float interp_t = t;
    
    glm::mat4 interp_lookat = glm::mat4(1.0f);
    for (int i = 0; i < 4; ++i) {
        for (int j = 0; j < 4; ++j) {
            float current = interp_lookat[j][i];
            float target = target_lookat[j][i];
            interp_lookat[j][i] = current + (target - current) * interp_t;
        }
    }
    
    glm::vec3 right = interp_lookat[0];
    glm::vec3 up = interp_lookat[1];
    glm::vec3 back = interp_lookat[2];

    struct CFrameWrite {
        float right[3];
        float up[3];
        float back[3];
        float padding;
    };

    CFrameWrite cfw;
    cfw.right[0] = right.x;
    cfw.right[1] = right.y;
    cfw.right[2] = right.z;
    cfw.up[0] = up.x;
    cfw.up[1] = up.y;
    cfw.up[2] = up.z;
    cfw.back[0] = back.x;
    cfw.back[1] = back.y;
    cfw.back[2] = back.z;
    cfw.padding = 0.f;

    bool write_ok = g_process.write<CFrameWrite>(m_camera + offsets::Camera::CFrame, cfw);
    return write_ok;
}

auto Roblox::teleport_local_player(float offset_y) const -> bool {
    auto players_instance = RobloxInstance{m_players_service};
    auto lp = players_instance.find_first_child_of_class("Player");
    if (!lp) return false;

    auto model = g_process.read<uintptr_t>(lp->address + offsets::Player::ModelInstance);
    if (!model || *model == 0) return false;

    RobloxInstance model_inst{*model};
    auto root_part = model_inst.find_first_child("HumanoidRootPart");
    if (!root_part) return false;

    auto prim = g_process.read<uintptr_t>(root_part->address + offsets::BasePart::Primitive);
    if (!prim || *prim == 0) return false;

    auto x = g_process.read<float>(*prim + offsets::Primitive::Position);
    auto y = g_process.read<float>(*prim + offsets::Primitive::Position + 4);
    auto z = g_process.read<float>(*prim + offsets::Primitive::Position + 8);
    if (!x || !y || !z) return false;

    auto flags = g_process.read<uint8_t>(*prim + offsets::Primitive::Flags);
    if (!flags) return false;

    uint8_t anchored = *flags | offsets::PrimitiveFlags::Anchored;
    g_process.write<uint8_t>(*prim + offsets::Primitive::Flags, anchored);

    float new_y = *y + offset_y;
    g_process.write<float>(*prim + offsets::Primitive::Position, *x);
    g_process.write<float>(*prim + offsets::Primitive::Position + 4, new_y);
    g_process.write<float>(*prim + offsets::Primitive::Position + 8, *z);

    spdlog::info("Teleported to ({:.1f}, {:.1f}, {:.1f})", *x, new_y, *z);
    return true;
}
