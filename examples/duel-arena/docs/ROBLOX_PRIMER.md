# Roblox Primer

Roblox concepts for D, written as they come up. Five short paragraphs to start; grow it when something new matters.

**Script vs LocalScript vs ModuleScript.** A `Script` runs on the server: trusted, sees everything, the only place that may decide damage or touch player data. A `LocalScript` runs on one player's machine: untrusted, like browser JS, one copy per player. A `ModuleScript` is an importable module (`require`) that runs wherever it is required, so the same file can serve both sides if it avoids server-only or client-only APIs. Rojo maps `*.server.luau` → Script, `*.client.luau` → LocalScript, `*.luau` → ModuleScript, and `init.*.luau` makes the folder itself the instance.

**Where things live.** `ReplicatedStorage` is shared code and assets visible to both sides (our `Shared`). `ServerScriptService` and `ServerStorage` are server-only; clients literally cannot see their contents, which is why arena templates and tests sit there. `StarterPlayerScripts` is copied into every player on join (our `Client`). `Workspace` is the 3D world, replicated to everyone. `StarterGui` is UI copied to each player.

**The client/server boundary.** Client and server are separate programs talking over the network. A `RemoteEvent` is a fire-and-forget message; a `RemoteFunction` is an RPC with a return value. Everything a client sends is attacker-controlled input: validate the shape, rate-limit it, and re-check the claim (we re-raycast every shot on the server). Never call a `RemoteFunction` from server to client; a hostile client can just never answer.

**Replication and attributes.** The server owns the world. Changes the server makes to instances in `Workspace` replicate to clients automatically; changes a client makes stay local (except its own character's movement). Attributes (`instance:SetAttribute("Health", 100)`) are a cheap way for the server to publish state that clients read, which is how the HUD will learn health and ammo.

**Rojo and Studio.** Rojo is the build tool that turns files into instances, think `next dev`: `rojo serve` watches `src/`, the Studio plugin pulls changes in on save. Studio "Play" runs client and server in one process for quick checks; "Test → Clients and Servers" launches real separate clients and is the only honest way to test a duel. The MCP server lets Claude inspect the DataModel, run Luau and drive playtests, but scripts still come from Rojo.
