--!strict
local Analytics = require(game:GetService("ReplicatedStorage").Shared.Config.Analytics)

type Assert = (actual: any, expected: any, label: string?) -> ()

return {
	["funnel steps are unique, non-empty strings in order"] = function(assertEqual: Assert)
		local seen = {}
		assertEqual(#Analytics.Funnel >= 2, true, "at least two steps")
		for index, step in Analytics.Funnel do
			assertEqual(typeof(step), "string", `step {index} type`)
			assertEqual(#step > 0, true, `step {index} non-empty`)
			assertEqual(seen[step], nil, `duplicate {step}`)
			seen[step] = true
			assertEqual(table.find(Analytics.Funnel, step), index, `{step} index`)
		end
		assertEqual(Analytics.Funnel[1], "Joined", "first step is Joined")
	end,
}
