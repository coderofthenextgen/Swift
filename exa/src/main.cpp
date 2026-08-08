#include "process.h"
#include "roblox.h"
#include <spdlog/spdlog.h>
#include <chrono>
#include <thread>
#include <cmath>
#include <atomic>
#include <cfloat>

#include <ApplicationServices/ApplicationServices.h>

static std::atomic<bool> g_x_held{false};
static std::atomic<bool> g_running{true};

static CGEventRef event_tap_callback(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void* refcon) {
    if (type == kCGEventKeyDown || type == kCGEventKeyUp) {
        CGKeyCode keyCode = CGEventGetIntegerValueField(event, kCGKeyboardEventKeycode);
        bool is_repeat = CGEventGetIntegerValueField(event, kCGKeyboardEventAutorepeat);
        if (keyCode == 0x07 && !is_repeat) g_x_held.store(type == kCGEventKeyDown);
        if (keyCode == 0x35 && !is_repeat) g_running.store(false);
    }
    return event;
}

static void event_tap_thread() {
    CFMachPortRef tap = CGEventTapCreate(
        kCGSessionEventTap, kCGHeadInsertEventTap, kCGEventTapOptionListenOnly,
        CGEventMaskBit(kCGEventKeyDown) | CGEventMaskBit(kCGEventKeyUp),
        event_tap_callback, nullptr);
    if (!tap) {
        spdlog::error("Event tap failed. Grant Accessibility in System Settings > Privacy & Security > Accessibility.");
        return;
    }
    CFRunLoopSourceRef source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0);
    CFRunLoopAddSource(CFRunLoopGetCurrent(), source, kCFRunLoopCommonModes);
    CGEventTapEnable(tap, true);
    CFRunLoopRun();
}

auto main() -> int {
    spdlog::info("Exa v1.0 - Aimbot (debug)");
    spdlog::info("Hold X to aim. ESC to quit.");

    if (!g_process.attach("RobloxPlayer")) {
        spdlog::error("Failed to attach to Roblox. Run with sudo.");
        return 1;
    }
    if (!g_roblox.initialize()) {
        spdlog::error("Failed to initialize Roblox reader");
        return 1;
    }

    g_roblox.refresh_players();

    std::thread tap(event_tap_thread);
    tap.detach();
    std::this_thread::sleep_for(std::chrono::milliseconds(200));

    CGRect display_bounds = CGDisplayBounds(CGMainDisplayID());
    float screen_w = display_bounds.size.width;
    float screen_h = display_bounds.size.height;
    spdlog::info("Screen: {}x{} origin=({:.0f},{:.0f})", (int)screen_w, (int)screen_h,
        display_bounds.origin.x, display_bounds.origin.y);

    auto last_refresh = std::chrono::steady_clock::now();
    auto last_debug = std::chrono::steady_clock::now();
    int frame_count = 0;

    while (g_running.load()) {
        auto now = std::chrono::steady_clock::now();
        if (std::chrono::duration_cast<std::chrono::seconds>(now - last_refresh).count() >= 2) {
            g_roblox.refresh_players();
            last_refresh = now;
        }

        g_roblox.update_camera();

        if (g_x_held.load()) {
            frame_count++;

            const auto& players = g_roblox.get_players();

            CGEventRef mouseEvent = CGEventCreate(nullptr);
            CGPoint mousePos = CGEventGetLocation(mouseEvent);
            CFRelease(mouseEvent);



            if (!players.empty()) {
                float min_dist = FLT_MAX;
                glm::vec3 target_world{0.f};
                bool found = false;

                for (const auto& player : players) {
                    if (player.model_address == 0 || player.is_local || player.position == glm::vec3{0.f}) continue;

                    auto screen_pos = g_roblox.world_to_screen(player.position, screen_w, screen_h);
                    if (!screen_pos) continue;

                    float dx = screen_pos->x - mousePos.x;
                    float dy = screen_pos->y - mousePos.y;
                    float dist = std::sqrt(dx * dx + dy * dy);

                    if (dist > 500.f) continue;

                    if (dist < min_dist) {
                        min_dist = dist;
                        target_world = player.position;
                        found = true;
                    }
                }

                if (found && min_dist > 1.f) {
                    float smooth = 0.15f;
                    g_roblox.set_camera_rotation(target_world, smooth);
                }
            }
        }

        std::this_thread::sleep_for(std::chrono::milliseconds(1));
    }

    g_process.detach();
    spdlog::info("Exa shutdown complete.");
    return 0;
}
