--!strict
-- XP: rewards and the level curve. Defaults chosen 07/09/2026; tune from analytics (P7).
-- Level L needs 50·L·(L+1) XP: L1 = 100, L2 = 300, L3 = 600, L5 = 1500, L10 = 5500, L20 = 21000.
local XP = {
	Rewards = {
		DuelWin = 100,
		DuelLoss = 40,
		RoundWin = 10,
	},
	MaxLevel = 50,
	BoostMultiplier = 2,
}

-- Total XP required to reach `level` (level 0 = 0).
function XP.xpForLevel(level: number): number
	local clamped = math.clamp(math.floor(level), 0, XP.MaxLevel)
	return 50 * clamped * (clamped + 1)
end

-- Level reached with `xp` total XP.
function XP.levelForXP(xp: number): number
	local level = 0
	while level < XP.MaxLevel and XP.xpForLevel(level + 1) <= xp do
		level += 1
	end
	return level
end

-- XP earned for one duel result, before any boost.
function XP.forDuel(won: boolean, roundsWon: number): number
	local base = if won then XP.Rewards.DuelWin else XP.Rewards.DuelLoss
	return base + math.max(0, roundsWon) * XP.Rewards.RoundWin
end

return XP
