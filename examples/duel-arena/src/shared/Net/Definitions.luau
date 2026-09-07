--!strict
-- Definitions: every remote in the game, by name. The server creates them from this table at boot.
-- ClientToServer remotes MUST set `ratePerSecond` and a pure `validate` so tests can cover it.
export type Direction = "ClientToServer" | "ServerToClient"
export type Kind = "Event" | "Unreliable"

export type Definition = {
	kind: Kind,
	direction: Direction,
	ratePerSecond: number?,
	validate: ((...any) -> boolean)?,
}

local Definitions: { [string]: Definition } = {
	-- Lobby: Types.QueueStatus, or nil when the player leaves a queue.
	QueueStatus = { kind = "Event", direction = "ServerToClient" },
	-- Duel flow: Types.DuelUpdate on every state change.
	DuelUpdate = { kind = "Event", direction = "ServerToClient" },
	-- One-line HUD message (string).
	Notify = { kind = "Event", direction = "ServerToClient" },
}

return Definitions
