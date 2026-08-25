# Swift — MM2 Exclusive

> Premium Murder Mystery 2 script hub. **Only works on MM2 (PlaceId 142823291)** — refuses to run anywhere else.

**Repo:** `coderofthenextgen/Swift` • **UI:** [WindUI](https://github.com/Footagesus/WindUI) (modern glass, 10+ themes, motion) — fallback to [swift-ui](https://github.com/coderofthenextgen/swift-ui) (Obsidian-dark boxy style)  
**Loader:**
```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/coderofthenextgen/Swift/main/swift.lua"))()
-- or
loadstring(game:HttpGet("https://raw.githubusercontent.com/coderofthenextgen/Swift/main/loader.lua"))()
```

## Features

### Visuals (ESP)
- **Role-aware Highlights** — Murderer `rgb(255,55,55)`, Sheriff `rgb(55,130,255)`, Innocent/Hero distinct, AlwaysOnTop depth
- **Billboard ESP** — Name + `[Role]` + `HP` + distance (meters)
- **Gun Drop ESP** — yellow Highlight + `🔫 GUN DROP` billboard, tracks `Workspace.GunDrop`
- **Tracers** (Drawing API, bottom-center → HRP)
- **Max distance slider** (300–9000 studs), role colors toggle, customizable palette

### Combat — Knife (from `KnifeClient` dumps)
- **Kill Aura** — Heartbeat loop, `KillAuraRange` 8–28, `Delay` 0.08–0.9s, target filter All/Murderer/Sheriff/Innocent; only fires when holding `Knife`, calls `KnifeStabbed:FireServer()` (dump @131, debounce 0.85s bypassed)
- **Throw Aimbot + Silent Throw** — `KnifeThrown:FireServer(CFrame)` (dump @147) — closest to cursor within FOV; silent mode fires remote directly bypassing arc

### Combat — Gun (from `GunClient` dump @69)
- **Gun Aimbot (Hold RMB)** — camera lerp 0.42 to `Head`/`HumanoidRootPart`, FOV 60–900, optional wallbang check via `Workspace:Raycast`
- **Gun Silent Aim** — `hookmetamethod(__namecall)` hook on `GunFired:FireServer` (alias scan: `GunFired`/`ShootGun` etc., plus `ReplicatedStorage.ClientServices.WeaponService.GunFired`) — redirects any CFrame/Vector3 arg to closest head
- **Auto Shoot** + **FOV Circle** (Drawing Circle, purple idle / red silent)

### Player
- WalkSpeed 16–120, JumpPower 50–220, infinite jump toggle (`UserInputService.JumpRequest`)

## Strict MM2 Guard

```lua
local MM2_PLACE_IDS = { [142823291] = true }
local MM2_UNIVERSE_IDS = { [66654135] = true }
if not (PlaceOk or UniverseOk) then
    StarterGui:SetCore("SendNotification", {Title="Swift — MM2 Only", ...})
    return
end
```

## Dump References Emulated

| Dump | Address | Constants hooked |
|------|---------|------------------|
| `stabKnife` | `0xf76c3742e923b6dc` @131 | `KnifeStabbed:FireServer()`, `PreSimulation:Wait`, `Random.new():NextInteger` |
| `throwKnife` | `0xc5dd16f60068497c` @147 | `KnifeThrown:FireServer(CFrame)` + overload `ThrowKnife` anim |
| `GunClient` | `0x08d5c15d4293c97c` @69 | `GunFired:FireServer(CFrame, CFrame)` via `GetMouseTargetCFrame` |

Remote resolver scans `ReplicatedStorage` recursively + alias lists + `ClientServices.WeaponService`.

## UI

- **WindUI** window `560×520`, `SideBarWidth 170`, `Transparent + HasOutline`, tabs: Home / Combat / Visuals / Player / Settings
- Search, config manager, notifications, mobile `IsMobile` aware
- Unload button destroys all Highlights/Billboards/Tracers/FOV cleanly

## File Map

```
swift.lua  — main MM2 hub (~750 lines, !strict)
loader.lua — one-line HttpGet wrapper
swift-ui   — separate repo: coderofthenextgen/swift-ui (UI.lua + ThemeManager etc.)
```

## Dev

```bash
gh repo create Swift --public --description "Swift — Premium MM2 Script Hub | ESP, Combat, WindUI"
git remote add origin https://github.com/coderofthenextgen/Swift.git
git push -u origin main
```

`getgenv().Swift` exposes `Flags`, `Remotes`, `ESP`, `Combat`, `Window` for debugging.
