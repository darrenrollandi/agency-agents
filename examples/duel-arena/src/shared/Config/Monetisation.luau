--!strict
-- Monetisation: every Robux product in one place. D creates the passes/products on the Creator
-- Dashboard (CLAUDE.md §9) and pastes the ids here. 0 means "not created yet": the feature stays
-- hidden in the UI and the server refuses to prompt for it. Cosmetic + convenience only, never power.
local Monetisation = {
	-- skinId → game pass id. The skin must exist in Config/Skins with gamePass = true.
	SkinPasses = {
		RevolverVoid = 0,
		KnifeVoid = 0,
	} :: { [string]: number },

	DevProducts = {
		XPBoost = {
			id = 0,
			-- Duration added per purchase; purchases stack.
			minutes = 30,
			name = "XP Boost ×2 (30 min)",
		},
	},

	-- Receipt ids kept per profile for idempotent ProcessReceipt.
	PurchaseHistoryLimit = 50,
}

function Monetisation.isConfigured(id: number): boolean
	return typeof(id) == "number" and id > 0
end

return Monetisation
