# DragonflightUI Classic — Revived

[![Join the Discord](https://img.shields.io/badge/Discord-Join%20the%20community-5865F2?style=for-the-badge&logo=discord&logoColor=white)](https://discord.gg/yaYHsGhaA)
[![Download on CurseForge](https://img.shields.io/badge/CurseForge-Download-F16436?style=for-the-badge&logo=curseforge&logoColor=white)](https://www.curseforge.com/wow/addons/dragonflight-ui-classic-revived)

### 💬 Talk to us on Discord: **[discord.gg/yaYHsGhaA](https://discord.gg/yaYHsGhaA)**

Found a bug, got a screenshot of something broken, want a feature, or just want to tell us what you are playing? **[Jump into the Discord](https://discord.gg/yaYHsGhaA)** — it is the fastest way to reach the people working on this addon, and the reports posted there are what drive the fixes. Every bug in the Era 1.15.9 overhaul was found by players who spoke up.

---

World of Warcraft (Classic) addon that brings the modern retail UI to Classic.

**This is the community-maintained continuation of [DragonflightUI Classic](https://github.com/Karl-HeinzSchneider/WoW-DragonflightUI).**

## Why this repo exists

The original project by [Karl-Heinz Schneider](https://github.com/Karl-HeinzSchneider) is no longer maintained. Its last release (v0.40.3) shipped in May 2026, and issues and pull requests have gone unanswered since.

In the meantime, Classic Era **1.15.9** backported the Midnight-era UI (Edit Mode, retail-style action bars and party frames, the new nameplate style, and a much stricter script-time governor), which broke large parts of the addon on Era.

The compatibility overhaul for that patch was developed as [PR #693](https://github.com/Karl-HeinzSchneider/WoW-DragonflightUI/pull/693) against the original repository, tested and iterated on with players in the field — but with nobody upstream to merge it, there was nowhere for the work to live.

This repository is that home. It carries the **full commit history of the original project** plus every fix since, and it is maintained by [@MendleM](https://github.com/MendleM) together with the community.

## Install

**CurseForge (recommended — auto-updates):**
[DragonflightUI Classic Revived](https://www.curseforge.com/wow/addons/dragonflight-ui-classic-revived) — packaged and kept up to date by [@insanerage80](https://github.com/insanerage80).

**Manual:** download this repository, extract it into `World of Warcraft\_classic_era_\Interface\AddOns\`, and make sure the folder is named exactly **`DragonflightUI`**. Restart the game client (a `/reload` is not enough for a fresh install).

## Supported game versions

| Flavor | Status |
| --- | --- |
| Classic Era 1.15.9+ (Midnight UI backport) | Primary target, actively tested |
| TBC 2.5.6+ / MoP 5.5.4+ | Supported — most paths are shared and feature-detected, less field testing |
| Wrath / Cata Classic | Inherited from upstream, largely untouched |

## Reporting bugs

Two ways, both open to everyone:

- **[GitHub Issues](https://github.com/MendleM/DragonflightUI-Revived/issues)** — anyone can open one, no permission needed. Best for anything reproducible.
- **[Discord: Dragonflight UI Classic - Revived](https://discord.gg/yaYHsGhaA)** — for quick questions, screenshots and general chat.

A good report includes:

- Game flavor and build (Era 1.15.9, TBC 2.5.6, …) and the addon version
- What you did, what you expected, what actually happened
- Any Lua error text (install [BugSack](https://www.curseforge.com/wow/addons/bugsack) — it captures errors even with error display off)
- A screenshot for anything visual
- Whether it still happens with only DragonflightUI enabled

## Contributing

**Anyone can open a pull request.** You do not need to ask first.

1. Fork this repository and branch off `main`
2. Make your change (match the surrounding code style — the repo ships a `LuaFormatter.config`)
3. Open a PR against `main` describing what it fixes and how you tested it

`main` is protected: contributions land through pull requests, and only [@MendleM](https://github.com/MendleM) can merge them. Force-pushes and branch deletion are blocked. No approval count is enforced, so small fixes do not get stuck waiting on a second reviewer.

Useful to know when working on Era 1.15.9:

- The client enforces a **script execution time limit** and kills long slices with "script ran too long" at whatever line happens to be running. Module setup is therefore split into small `pcall`-isolated steps batched into ~100 ms slices (`Helper:RunSteps`).
- Protected/secure frame work is **silently blocked** during combat lockdown — and `InCombatLockdown()` lies during load. Use `Helper:IsCombatLocked()` and `Helper:RunOutOfCombat` for anything touching secure frames.
- Prefer **feature detection** (`DF.API.Version.IsModern`) over flavor checks, so the addon keeps working as Blizzard rolls the UI backport forward.

## Features

_Minimalistic — Modern — Modular_

Not a carbon copy of the retail Dragonflight UI, but a faithful adaption with extra Classic-specific features. Built on the default Blizzard UI, so most other addons keep working. Completely modular: enable or disable any part you want.

Configure in-game with `/df` (or `/dragonflight`), with full profile support, or move things around with `/editmode`.

### Modules

- Actionbar
- Bossframe
- Buffs
- Castbar
- Chat
- Darkmode
- Minimap
- Nameplates
- Tooltip
- UI
- Unitframe
- Utility

## Credits

- **[Karl-Heinz Schneider](https://github.com/Karl-HeinzSchneider)** — original author of DragonflightUI Classic. This project is his work continued; all of it stands on that foundation. If you got years of use out of the addon, he still has a [tip jar](https://www.buymeacoffee.com/karlheinzschneider).
- **[@insanerage80](https://github.com/insanerage80)** — packaging and publishing the revived build on CurseForge, and running the Discord.
- **[@icebreethe](https://github.com/icebreethe)** — TBC 2.5.6 / MoP 5.5.4 compatibility work.
- **[@wigoor](https://github.com/wigoor)**, **[@b4bass](https://github.com/b4bass)** and everyone else field-testing, reporting bugs and running diagnostics.

## License

[MIT](LICENSE) — unchanged from the original project, © 2022 Karl-HeinzSchneider and contributors.

# Preview

## Actionbar

![](Screenshots/v0.10/Actionbar.png)

## Actionbar Config

![](Screenshots/v0.10/ActionbarConfig.png)

## Castbar

![](Screenshots/v0.10/Castbar.png)

## Darkmode

![](Screenshots/darkmode/CompleteUI_dark.png)

## Editmode

![](Screenshots/v0.23/Editmode.png)

## Minimap

![](Screenshots/v0.10/Minimap.png)

## Micromenu/Bags

![](Screenshots/v0.10/Micromenu-Bag.png)

## Quick Keybind

![](Screenshots/v0.10/QuickKeybind.png)

## Tooltip

![](Screenshots/v0.23/Tooltip_all.png)

## UI

![](Screenshots/v0.11/Bags.png)

![](Screenshots/v0.11/CharacterFrame.png)

![](Screenshots/v0.11/Spellbook.png)

![](Screenshots/v0.11/Profession.png)

![](Screenshots/v0.11/Profession_small.png)

## Unitframe

![](Screenshots/v0.10/Unitframes.png)

## Complete UI

![](Screenshots/v0.10/Fullscreen.png)
