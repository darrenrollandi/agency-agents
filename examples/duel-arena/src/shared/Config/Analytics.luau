--!strict
-- Analytics: what we report to Roblox's AnalyticsService (Creator Hub → Analytics).
-- Funnel steps are ordered; the index is the step number Roblox receives. Never reorder a shipped
-- funnel: add steps at the end or start a new funnel name.
local Analytics = {
	Enabled = true,
	-- Onboarding funnel, once per player for life (deduplicated in Profile.Data.Funnel).
	Funnel = { "Joined", "SteppedOnPad", "FirstDuel", "FirstWin" },
	-- Progression path reported on level up.
	ProgressionPath = "Level",
	-- Economy currency names.
	CurrencyXP = "XP",
	CurrencyBoostMinutes = "BoostMinutes",
}

return Analytics
