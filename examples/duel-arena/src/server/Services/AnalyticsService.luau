--!strict
-- AnalyticsService: thin wrapper over Roblox's AnalyticsService. Every call is pcall-guarded and
-- gated by Config/Analytics.Enabled, so analytics can never break gameplay. Funnel steps are
-- deduplicated per profile so a returning player never re-enters the onboarding funnel.
-- Data shows up in Creator Hub → Analytics only for a published experience.
local RobloxAnalytics = game:GetService("AnalyticsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local AnalyticsConfig = require(Shared.Config.Analytics)
local Log = require(Shared.Util.Log)
local DataService = require(script.Parent.DataService)

local AnalyticsService = {}

local function guarded(label: string, fn: () -> ())
	if not AnalyticsConfig.Enabled then
		return
	end
	local ok, err = pcall(fn)
	if not ok then
		Log.debug(`Analytics: {label} not recorded: {err}`)
	end
end

-- Onboarding funnel step by name (order in Config/Analytics.Funnel). Recorded once per profile.
function AnalyticsService.funnel(player: Player, stepName: string)
	local step = table.find(AnalyticsConfig.Funnel, stepName)
	if not step then
		Log.warn(`Analytics: unknown funnel step "{stepName}"`)
		return
	end
	local profile = DataService.getProfile(player)
	if not profile or profile.Data.Funnel[stepName] then
		return
	end
	profile.Data.Funnel[stepName] = true
	guarded("funnel", function()
		RobloxAnalytics:LogOnboardingFunnelStepEvent(player, step, stepName)
	end)
	Log.debug(`Analytics: {player.Name} reached funnel step {step} ({stepName})`)
end

-- XP earned through play.
function AnalyticsService.xpEarned(player: Player, amount: number, balance: number, source: string)
	guarded("xp", function()
		RobloxAnalytics:LogEconomyEvent(
			player,
			Enum.AnalyticsEconomyFlowType.Source,
			AnalyticsConfig.CurrencyXP,
			amount,
			balance,
			Enum.AnalyticsEconomyTransactionType.Gameplay.Name,
			source
		)
	end)
end

-- A level reached.
function AnalyticsService.levelReached(player: Player, level: number)
	guarded("level", function()
		RobloxAnalytics:LogProgressionEvent(
			player,
			AnalyticsConfig.ProgressionPath,
			Enum.AnalyticsProgressionType.Complete,
			level,
			`Level {level}`
		)
	end)
end

-- A developer-product purchase that granted `minutes` of XP boost.
function AnalyticsService.boostPurchased(player: Player, minutes: number, totalMinutesLeft: number)
	guarded("purchase", function()
		RobloxAnalytics:LogEconomyEvent(
			player,
			Enum.AnalyticsEconomyFlowType.Source,
			AnalyticsConfig.CurrencyBoostMinutes,
			minutes,
			totalMinutesLeft,
			Enum.AnalyticsEconomyTransactionType.IAP.Name,
			"XPBoost"
		)
	end)
end

-- Anything else worth counting (duel outcomes, abilities used, ...).
function AnalyticsService.custom(player: Player, eventName: string, value: number?)
	guarded(eventName, function()
		RobloxAnalytics:LogCustomEvent(player, eventName, value or 1)
	end)
end

function AnalyticsService.start()
	DataService.onProfileLoaded(function(player)
		AnalyticsService.funnel(player, "Joined")
	end)
	Log.info(`Analytics: {if AnalyticsConfig.Enabled then "enabled" else "disabled"}`)
end

return AnalyticsService
