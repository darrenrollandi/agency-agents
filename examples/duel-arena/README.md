# Duel Arena (working title)

A fast-paced first-person Roblox dueling game: 1v1 to 4v4, revolver and knife, first team to 5 rounds wins. Server-authoritative Luau, synced into Studio with Rojo, developed from this repo. Read [`CLAUDE.md`](CLAUDE.md) for the full handover and [`docs/STATUS.md`](docs/STATUS.md) for where things stand.

## Controls

| Action | Keyboard / mouse | Gamepad |
|---|---|---|
| Fire / knife swing | Left click | R2 |
| Reload | R | X |
| Revolver / Knife | 1 / 2, Q toggles | Y |
| Ability 1 / 2 | E / F | L1 / R1 |
| Locker (lobby) | L | Select |
| Settings | Tab | Start |

Touch devices get on-screen buttons for all of the above. Stand on a coloured pad to queue; step off to leave.

## Setup

```bash
# 1. Toolchain (once per machine)
#    Windows: Invoke-RestMethod https://raw.githubusercontent.com/rojo-rbx/rokit/main/scripts/install.ps1 | Invoke-Expression
#    macOS:   curl -sSf https://raw.githubusercontent.com/rojo-rbx/rokit/main/scripts/install.sh | bash
cd examples/duel-arena
rokit install                      # rojo, stylua, selene, luau-lsp pinned in rokit.toml
rojo plugin install                # puts the Rojo plugin into Studio

# 2. Every session
rojo serve                         # then click Connect in the Rojo plugin inside Studio

# 3. Before every commit
stylua src tests
selene src tests
```

Tests run inside Studio from the Edit DataModel (via the MCP `execute_luau` tool or the command bar):

```lua
require(game:GetService("ServerStorage").Tests.RunTests)()
```
