--!strict
-- Rounds: duel-flow tunables. Defaults set 07/09/2026 (see GAME_DESIGN.md); tune after Mason's first playtest.
local Rounds = {
	-- First team to this many round wins takes the duel.
	PointsToWin = 5,
	-- Players are frozen at their spawns for this long before a round goes Live.
	CountdownSeconds = 3,
	-- Round timer. On expiry the team with more survivors wins; a tie becomes sudden death (no timer).
	RoundTimeSeconds = 90,
	-- Pause between a round ending and the next countdown.
	RoundOverSeconds = 3,
	-- Time the result is shown before everyone is sent back to the lobby.
	DuelOverSeconds = 5,
	-- Lobby respawn delay after dying outside a duel.
	LobbyRespawnSeconds = 3,
	-- Arena slots: concurrent duels supported and where their arenas are placed.
	MaxArenas = 8,
	ArenaOrigin = Vector3.new(1000, 0, 1000),
	ArenaSpacing = 300,
}

return Rounds
