--!strict
local DuelRules = require(game:GetService("ReplicatedStorage").Shared.DuelRules)

type Assert = (actual: any, expected: any, label: string?) -> ()

return {
	["happy path transitions are allowed"] = function(assertEqual: Assert)
		assertEqual(DuelRules.canTransition("Waiting", "Countdown"), true, "Waiting->Countdown")
		assertEqual(DuelRules.canTransition("Countdown", "Live"), true, "Countdown->Live")
		assertEqual(DuelRules.canTransition("Live", "RoundOver"), true, "Live->RoundOver")
		assertEqual(DuelRules.canTransition("RoundOver", "Countdown"), true, "RoundOver->Countdown")
		assertEqual(DuelRules.canTransition("RoundOver", "DuelOver"), true, "RoundOver->DuelOver")
		assertEqual(DuelRules.canTransition("DuelOver", "Cleanup"), true, "DuelOver->Cleanup")
	end,

	["gameplay transitions are refused outside their order"] = function(assertEqual: Assert)
		assertEqual(DuelRules.canTransition("Waiting", "Live"), false, "Waiting->Live")
		assertEqual(DuelRules.canTransition("Live", "Countdown"), false, "Live->Countdown")
		assertEqual(DuelRules.canTransition("Live", "DuelOver"), false, "Live->DuelOver")
		assertEqual(DuelRules.canTransition("Cleanup", "Countdown"), false, "Cleanup->Countdown")
	end,

	["every live state can abort to Cleanup"] = function(assertEqual: Assert)
		for _, state in { "Waiting", "Countdown", "Live", "RoundOver", "DuelOver" } do
			assertEqual(DuelRules.canTransition(state :: any, "Cleanup"), true, `{state}->Cleanup`)
		end
	end,

	["round outcome follows elimination"] = function(assertEqual: Assert)
		assertEqual(DuelRules.roundOutcome(1, 1), nil, "both alive")
		assertEqual(DuelRules.roundOutcome(2, 0), "A", "B wiped")
		assertEqual(DuelRules.roundOutcome(0, 1), "B", "A wiped")
		assertEqual(DuelRules.roundOutcome(0, 0), "Draw", "both wiped")
	end,

	["timeout goes to the team with more survivors, else sudden death"] = function(
		assertEqual: Assert
	)
		assertEqual(DuelRules.timeoutOutcome(2, 1), "A", "A ahead")
		assertEqual(DuelRules.timeoutOutcome(1, 3), "B", "B ahead")
		assertEqual(DuelRules.timeoutOutcome(1, 1), nil, "tied")
	end,

	["duel ends at PointsToWin and the leader wins"] = function(assertEqual: Assert)
		assertEqual(DuelRules.isDuelOver(4, 4, 5), false, "4-4")
		assertEqual(DuelRules.isDuelOver(5, 3, 5), true, "5-3")
		assertEqual(DuelRules.isDuelOver(2, 5, 5), true, "2-5")
		assertEqual(DuelRules.duelWinner(5, 3), "A", "A leads")
		assertEqual(DuelRules.duelWinner(1, 2), "B", "B leads")
		assertEqual(DuelRules.duelWinner(2, 2), nil, "tied")
	end,

	["splitTeams alternates and respects team size"] = function(assertEqual: Assert)
		local a, b = DuelRules.splitTeams({ "p1", "p2" }, 1)
		assertEqual(#a, 1, "#a 1v1")
		assertEqual(#b, 1, "#b 1v1")
		assertEqual(a[1], "p1", "a[1]")
		assertEqual(b[1], "p2", "b[1]")

		local a2, b2 = DuelRules.splitTeams({ "p1", "p2", "p3", "p4", "p5" }, 2)
		assertEqual(#a2, 2, "#a 2v2")
		assertEqual(#b2, 2, "#b 2v2")
		assertEqual(a2[2], "p3", "a[2]")
		assertEqual(b2[2], "p4", "b[2]")
	end,
}
