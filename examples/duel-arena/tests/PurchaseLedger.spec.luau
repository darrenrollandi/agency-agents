--!strict
local PurchaseLedger = require(game:GetService("ReplicatedStorage").Shared.Util.PurchaseLedger)
local Definitions = require(game:GetService("ReplicatedStorage").Shared.Net.Definitions)
local Monetisation = require(game:GetService("ReplicatedStorage").Shared.Config.Monetisation)

type Assert = (actual: any, expected: any, label: string?) -> ()

return {
	["record is idempotent"] = function(assertEqual: Assert)
		local history = {}
		assertEqual(PurchaseLedger.record(history, "r1", 50), true, "first")
		assertEqual(PurchaseLedger.record(history, "r1", 50), false, "replay")
		assertEqual(PurchaseLedger.has(history, "r1"), true, "has")
		assertEqual(PurchaseLedger.has(history, "r2"), false, "has other")
		assertEqual(#history, 1, "length")
	end,

	["record trims to the limit, oldest first"] = function(assertEqual: Assert)
		local history = {}
		for i = 1, 5 do
			PurchaseLedger.record(history, `r{i}`, 3)
		end
		assertEqual(#history, 3, "length")
		assertEqual(history[1], "r3", "oldest kept")
		assertEqual(history[3], "r5", "newest")
		assertEqual(PurchaseLedger.has(history, "r1"), false, "evicted")
	end,

	["config ids are numbers and unconfigured means 0"] = function(assertEqual: Assert)
		for skinId, id in Monetisation.SkinPasses do
			assertEqual(typeof(id), "number", `{skinId} id`)
		end
		assertEqual(typeof(Monetisation.DevProducts.XPBoost.id), "number", "XPBoost id")
		assertEqual(Monetisation.isConfigured(0), false, "0 unconfigured")
		assertEqual(Monetisation.isConfigured(12345), true, "positive configured")
	end,

	["RequestPurchase validator"] = function(assertEqual: Assert)
		local validate = Definitions.RequestPurchase.validate :: (...any) -> boolean
		assertEqual(validate("GamePass", "RevolverVoid"), true, "pass")
		assertEqual(validate("Product", "XPBoost"), true, "product")
		assertEqual(validate("Robux", "XPBoost"), false, "unknown kind")
		assertEqual(validate("GamePass"), false, "missing key")
		assertEqual(validate("GamePass", 5), false, "numeric key")
		assertEqual(validate("GamePass", string.rep("a", 41)), false, "long key")
	end,
}
