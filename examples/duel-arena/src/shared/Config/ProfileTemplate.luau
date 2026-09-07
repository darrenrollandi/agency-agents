--!strict
-- ProfileTemplate: the only place new player-data fields are added (see CLAUDE.md §6 Data).
-- ProfileStore reconciles missing keys from this template on every load, so adding a field here
-- is a migration. Never remove or rename a field without bumping Version and handling the old one.
-- Rules: no numeric tables with gaps, no mixed keys, no Roblox types (JSON-safe only).
export type ProfileData = {
	Version: number,
	XP: number,
	Wins: number,
	Losses: number,
	Duels: number,
	RoundsWon: number,
	-- skinId → true
	OwnedSkins: { [string]: boolean },
	EquippedRevolver: string,
	EquippedKnife: string,
	-- Receipt ids already granted (idempotent ProcessReceipt, P6).
	PurchaseHistory: { string },
	-- Unix time until which XP is doubled (P6 dev product).
	XPBoostUntil: number,
	Settings: {
		Sensitivity: number,
		FieldOfView: number,
	},
	FirstJoin: number,
	LastJoin: number,
	-- Analytics funnel steps already logged (P7).
	Funnel: { [string]: boolean },
}

local ProfileTemplate: ProfileData = {
	Version = 1,
	XP = 0,
	Wins = 0,
	Losses = 0,
	Duels = 0,
	RoundsWon = 0,
	OwnedSkins = {},
	EquippedRevolver = "RevolverDefault",
	EquippedKnife = "KnifeDefault",
	PurchaseHistory = {},
	XPBoostUntil = 0,
	Settings = {
		Sensitivity = 1,
		FieldOfView = 80,
	},
	FirstJoin = 0,
	LastJoin = 0,
	Funnel = {},
}

return ProfileTemplate
