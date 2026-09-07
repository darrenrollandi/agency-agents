--!strict
-- TeamHighlightController: outlines your teammates (through walls) during a duel so 2v2+ reads at a
-- glance. Client-only, driven by DuelUpdate.roster, so opponents never get an outline on you.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Types = require(Shared.Types)
local Net = require(Shared.Net.Net)

local REFRESH_INTERVAL = 0.5
local TEAM_COLORS: { [Types.TeamId]: Color3 } = {
	A = Color3.fromRGB(0, 170, 255),
	B = Color3.fromRGB(255, 120, 40),
}

local player = Players.LocalPlayer

local TeamHighlightController = {}

local teammates: { [string]: boolean } = {}
local myTeam: Types.TeamId? = nil
local highlights: { [Model]: Highlight } = {}
local lastRefresh = 0

local function clear()
	for _, highlight in highlights do
		highlight:Destroy()
	end
	highlights = {}
end

local function refresh()
	lastRefresh = os.clock()
	local team = myTeam
	if not team then
		clear()
		return
	end
	local wanted: { [Model]: boolean } = {}
	for name in teammates do
		local who = Players:FindFirstChild(name)
		local character = if who and who:IsA("Player") then who.Character else nil
		if character and character.Parent then
			wanted[character] = true
			if not highlights[character] then
				local highlight = Instance.new("Highlight")
				highlight.Name = "TeamHighlight"
				highlight.FillTransparency = 1
				highlight.OutlineTransparency = 0
				highlight.OutlineColor = TEAM_COLORS[team]
				highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
				highlight.Adornee = character
				highlight.Parent = character
				highlights[character] = highlight
			end
		end
	end
	for character, highlight in highlights do
		if not wanted[character] then
			highlight:Destroy()
			highlights[character] = nil
		end
	end
end

function TeamHighlightController.start()
	Net.onClient("DuelUpdate", function(update: Types.DuelUpdate)
		teammates = {}
		if update.state == "Cleanup" then
			myTeam = nil
		else
			myTeam = update.team
			for _, entry in update.roster do
				if entry.team == update.team and entry.name ~= player.Name then
					teammates[entry.name] = true
				end
			end
		end
		refresh()
	end)
	RunService.Heartbeat:Connect(function()
		if myTeam and os.clock() - lastRefresh >= REFRESH_INTERVAL then
			refresh()
		end
	end)
end

return TeamHighlightController
