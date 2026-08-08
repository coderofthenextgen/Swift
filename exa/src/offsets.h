#pragma once
#include <cstdint>

namespace offsets {
    inline constexpr uintptr_t VisualEnginePointer = 0x744F728;

    namespace Instance {
        inline constexpr uintptr_t ChildrenStart = 0x70;
        inline constexpr uintptr_t ChildrenEnd = 0x8;
        inline constexpr uintptr_t Name = 0x98;
        inline constexpr uintptr_t Parent = 0x68;
        inline constexpr uintptr_t ClassDescriptor = 0x18;
        inline constexpr uintptr_t ClassName = 0x8;
    }

    namespace VisualEngine {
        inline constexpr uintptr_t FakeDataModel = 0xA80;
        inline constexpr uintptr_t RenderView = 0xBA8;
        inline constexpr uintptr_t ViewMatrix = 0x140;
    }

    namespace FakeDataModel {
        inline constexpr uintptr_t RealDataModel = 0x1D0;
    }

    namespace DataModel {
        inline constexpr uintptr_t Workspace = 0x150;
    }

    namespace Players {
        inline constexpr uintptr_t LocalPlayer = 0x120;
    }

    namespace Player {
        inline constexpr uintptr_t UserId = 0x1B0;
        inline constexpr uintptr_t DisplayName = 0x98;
        inline constexpr uintptr_t ModelInstance = 0x250;
    }

    namespace Humanoid {
        inline constexpr uintptr_t WalkSpeed = 0x1C0;
        inline constexpr uintptr_t MaxHealth = 0x178;
        inline constexpr uintptr_t HipHeight = 0x190;
    }

    namespace BasePart {
        inline constexpr uintptr_t Primitive = 0x118;
        inline constexpr uintptr_t Color3 = 0x98;
        inline constexpr uintptr_t Transparency = 0x80;
    }

    namespace Primitive {
        inline constexpr uintptr_t Flags = 0x0;
        inline constexpr uintptr_t Position = 0xEC;
    }

    namespace PrimitiveFlags {
        inline constexpr uint8_t Anchored = 0x2;
        inline constexpr uint8_t CanCollide = 0x8;
        inline constexpr uint8_t CanTouch = 0x10;
        inline constexpr uint8_t CanQuery = 0x20;
    }

    namespace Camera {
        inline constexpr uintptr_t CFrame = 0xD0;
        inline   constexpr uintptr_t FieldOfView = 0x138;   // float in radians
        inline constexpr uintptr_t Position = 0xF4;
    }

    namespace Workspace {
        inline constexpr uintptr_t CurrentCamera = 0x438;
    }
}
