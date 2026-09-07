--!strict
-- Types: shared type definitions used by both server and client.
export type TeamMode = "1v1" | "2v2" | "3v3" | "4v4"

export type TeamId = "A" | "B"

export type DuelState = "Waiting" | "Countdown" | "Live" | "RoundOver" | "DuelOver" | "Cleanup"

export type WeaponId = "Revolver" | "Knife"

-- Server → client while a player stands in a pad queue. nil means "no longer queued".
export type QueueStatus = {
	padName: string,
	mode: TeamMode,
	count: number,
	needed: number,
}

-- Server → client snapshot of the duel a player is in. Optional fields exist only in the
-- state they belong to. Timestamps are workspace:GetServerTimeNow() seconds.
export type DuelUpdate = {
	duelId: number,
	state: DuelState,
	mode: TeamMode,
	round: number,
	team: TeamId,
	scoreA: number,
	scoreB: number,
	aliveA: number,
	aliveB: number,
	suddenDeath: boolean,
	forfeit: boolean,
	countdownEndsAt: number?,
	roundEndsAt: number?,
	roundWinner: TeamId?,
	duelWinner: TeamId?,
}

-- Server → client whenever progression data changes (load, duel result, equip).
export type ProgressionSnapshot = {
	xp: number,
	level: number,
	nextLevelXP: number,
	wins: number,
	losses: number,
	owned: { string },
	equippedRevolver: string,
	equippedKnife: string,
	boostActive: boolean,
	sensitivity: number,
	fieldOfView: number,
}

-- Server → client after a duel: what it earned them.
export type DuelReward = {
	won: boolean,
	xpGained: number,
	boosted: boolean,
	level: number,
	leveledUp: boolean,
	unlocked: { string },
}

-- Server → shooter after a hit the server accepted.
export type HitConfirm = {
	victimName: string,
	damage: number,
	headshot: boolean,
	killed: boolean,
}

return {}
