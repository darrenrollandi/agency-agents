--!strict
local XP = require(game:GetService("ReplicatedStorage").Shared.Config.XP)

type Assert = (actual: any, expected: any, label: string?) -> ()

return {
	["curve anchors"] = function(assertEqual: Assert)
		assertEqual(XP.xpForLevel(0), 0, "L0")
		assertEqual(XP.xpForLevel(1), 100, "L1")
		assertEqual(XP.xpForLevel(2), 300, "L2")
		assertEqual(XP.xpForLevel(5), 1500, "L5")
		assertEqual(XP.xpForLevel(10), 5500, "L10")
	end,

	["levelForXP inverts xpForLevel and is monotonic"] = function(assertEqual: Assert)
		for level = 0, XP.MaxLevel do
			local xp = XP.xpForLevel(level)
			assertEqual(XP.levelForXP(xp), level, `exact L{level}`)
			if level < XP.MaxLevel then
				assertEqual(XP.levelForXP(xp + 1), level, `just over L{level}`)
				assertEqual(
					XP.levelForXP(XP.xpForLevel(level + 1) - 1),
					level,
					`just under L{level + 1}`
				)
			end
		end
		assertEqual(XP.levelForXP(10 ^ 9), XP.MaxLevel, "cap")
	end,

	["duel XP rewards"] = function(assertEqual: Assert)
		assertEqual(XP.forDuel(true, 5), XP.Rewards.DuelWin + 5 * XP.Rewards.RoundWin, "win 5-x")
		assertEqual(XP.forDuel(false, 3), XP.Rewards.DuelLoss + 3 * XP.Rewards.RoundWin, "loss 3-5")
		assertEqual(XP.forDuel(false, 0), XP.Rewards.DuelLoss, "loss 0-5")
	end,
}
