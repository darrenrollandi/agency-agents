--!strict
-- CharacterService: owns character spawning. Players.CharacterAutoLoads is switched off so a player
-- who dies mid-round stays dead until DuelService respawns them; in the lobby we respawn after a delay.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Rounds = require(Shared.Config.Rounds)
local Log = require(Shared.Util.Log)
local Trove = require(Shared.Util.Trove)
local PlayerState = require(script.Parent.Parent.PlayerState)

local CharacterService = {}

local lobbyTroves: { [Player]: Trove.Trove } = {}

local function troveFor(player: Player): Trove.Trove
	local trove = lobbyTroves[player]
	if not trove then
		trove = Trove.new()
		lobbyTroves[player] = trove
	end
	return trove
end

local function loadCharacter(player: Player): Model?
	if player.Parent ~= Players then
		return nil
	end
	local ok, err = pcall(function()
		player:LoadCharacter()
	end)
	if not ok then
		Log.warn(`CharacterService: LoadCharacter failed for {player.Name}: {err}`)
		return nil
	end
	local character = player.Character
	if character then
		-- Roblox injects a "Health" script that regenerates 1% per second. Duels have no passive regen;
		-- healing is an ability (Second Wind).
		local regen = character:FindFirstChild("Health")
		if regen and regen:IsA("Script") then
			regen:Destroy()
		end
	end
	return character
end

local function hookLobbyDeath(player: Player, character: Model)
	local trove = troveFor(player)
	trove:clean()
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	trove:connect(humanoid.Died, function()
		task.delay(Rounds.LobbyRespawnSeconds, function()
			if
				player.Parent == Players
				and player.Character == character
				and not PlayerState.inDuel(player)
			then
				CharacterService.spawnInLobby(player)
			end
		end)
	end)
end

-- Fresh character at the lobby spawn, with the lobby respawn hook. No-op for players in a duel.
function CharacterService.spawnInLobby(player: Player)
	if PlayerState.inDuel(player) then
		return
	end
	local character = loadCharacter(player)
	if character then
		hookLobbyDeath(player, character)
	end
end

-- Fresh character at `cframe` (full health). The caller owns death handling.
function CharacterService.spawnAt(player: Player, cframe: CFrame): Model?
	troveFor(player):clean()
	local character = loadCharacter(player)
	if not character then
		return nil
	end
	character:PivotTo(cframe)
	-- The engine may re-place a character on its first physics step; pin it once more.
	task.defer(function()
		if player.Character == character then
			character:PivotTo(cframe)
		end
	end)
	return character
end

-- Freeze/unfreeze movement (used during the round countdown).
function CharacterService.setFrozen(character: Model, frozen: boolean)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	if frozen then
		humanoid.WalkSpeed = 0
		humanoid.JumpHeight = 0
		humanoid.JumpPower = 0
	else
		humanoid.WalkSpeed = StarterPlayer.CharacterWalkSpeed
		humanoid.JumpHeight = StarterPlayer.CharacterJumpHeight
		humanoid.JumpPower = StarterPlayer.CharacterJumpPower
	end
end

function CharacterService.start()
	Players.CharacterAutoLoads = false

	local function onPlayerAdded(player: Player)
		local existing = player.Character
		if existing then
			hookLobbyDeath(player, existing)
		else
			CharacterService.spawnInLobby(player)
		end
	end

	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end
	Players.PlayerRemoving:Connect(function(player)
		local trove = lobbyTroves[player]
		if trove then
			trove:clean()
		end
		lobbyTroves[player] = nil
	end)
end

return CharacterService
