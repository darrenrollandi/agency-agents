--!strict
-- Server entry point. Boot order matters: Net creates remotes before any Service can fire one, and
-- CharacterService takes over spawning before Matchmaking can put anyone in a duel.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared.Net.Net)
local Log = require(Shared.Util.Log)
local PlayerState = require(script.PlayerState)
local CharacterService = require(script.Services.CharacterService)
local CombatService = require(script.Services.CombatService)
local AbilityService = require(script.Services.AbilityService)
local DuelService = require(script.Services.DuelService)
local MatchmakingService = require(script.Services.MatchmakingService)
local DebugCommands = require(script.DebugCommands)

Net.init()
CharacterService.start()
CombatService.start()
AbilityService.start()
DuelService.start()
MatchmakingService.start()
DebugCommands.start()

-- Connected last so every Service above has already read the leaving player's state.
Players.PlayerRemoving:Connect(PlayerState.clear)

Log.info("Services started: Character, Combat, Duel, Matchmaking")
print("[Server] Duel Arena booted")
