# Roblox Primer

Roblox concepts for D, written as they come up. Five short paragraphs to start; grow it when something new matters.

**Script vs LocalScript vs ModuleScript.** A `Script` runs on the server: trusted, sees everything, the only place that may decide damage or touch player data. A `LocalScript` runs on one player's machine: untrusted, like browser JS, one copy per player. A `ModuleScript` is an importable module (`require`) that runs wherever it is required, so the same file can serve both sides if it avoids server-only or client-only APIs. Rojo maps `*.server.luau` → Script, `*.client.luau` → LocalScript, `*.luau` → ModuleScript, and `init.*.luau` makes the folder itself the instance.

**Where things live.** `ReplicatedStorage` is shared code and assets visible to both sides (our `Shared`). `ServerScriptService` and `ServerStorage` are server-only; clients literally cannot see their contents, which is why arena templates and tests sit there. `StarterPlayerScripts` is copied into every player on join (our `Client`). `Workspace` is the 3D world, replicated to everyone. `StarterGui` is UI copied to each player.

**The client/server boundary.** Client and server are separate programs talking over the network. A `RemoteEvent` is a fire-and-forget message; a `RemoteFunction` is an RPC with a return value. Everything a client sends is attacker-controlled input: validate the shape, rate-limit it, and re-check the claim (we re-raycast every shot on the server). Never call a `RemoteFunction` from server to client; a hostile client can just never answer.

**Replication and attributes.** The server owns the world. Changes the server makes to instances in `Workspace` replicate to clients automatically; changes a client makes stay local (except its own character's movement). Attributes (`instance:SetAttribute("Health", 100)`) are a cheap way for the server to publish state that clients read, which is how the HUD will learn health and ammo.

**Rojo and Studio.** Rojo is the build tool that turns files into instances, think `next dev`: `rojo serve` watches `src/`, the Studio plugin pulls changes in on save. Studio "Play" runs client and server in one process for quick checks; "Test → Clients and Servers" launches real separate clients and is the only honest way to test a duel. The MCP server lets Claude inspect the DataModel, run Luau and drive playtests, but scripts still come from Rojo.

**ProximityPrompts need to be on screen.** A `ProximityPrompt` shows its "Press E" bubble only while the player is within `MaxActivationDistance` *and* the parent part is inside the camera's view. In locked first person the pad you're standing on is below the frame, so the prompt never appears. That is why duel pads are step-on zones: the server checks who is standing in the pad's footprint with `Workspace:GetPartBoundsInBox`, the same spatial query the knife hitbox uses.

**Characters and respawning.** By default `Players.CharacterAutoLoads` is true and the engine respawns a dead player at a `SpawnLocation` after `Players.RespawnTime` seconds. We switch it off and call `player:LoadCharacter()` ourselves, then `character:PivotTo(cframe)` to place the new character. That is the only way a dead duelist stays dead until the next round instead of popping up in the lobby. `Humanoid.Died` is the death signal; `Humanoid.Health = 0` or `Humanoid:TakeDamage(n)` kills.

**Tools.** A `Tool` in a player's `Backpack` is equipped by pressing its slot key or via `Humanoid:EquipTool`. `Tool.Activated` fires when the player clicks with it equipped, on the client *and* on the server, so a server script can react to a click with no RemoteEvent at all. That is how the P1 Tag weapon works and how the knife will start.

**Clocks.** `os.clock()` is a high-resolution local timer, fine for cooldowns on one machine. `workspace:GetServerTimeNow()` is the same clock on server and every client, so the server can send "the round ends at T" once and each client counts down locally without drift.

**Module instances.** `require(module)` caches per Lua VM. A server `Script`, the command bar and MCP `execute_luau` each have their own cache, so requiring `DuelService` from the command bar gives you a fresh copy that knows nothing about the duels the real server is running. Reach the live one through `ServerStorage.DebugCommands` (Studio only).
