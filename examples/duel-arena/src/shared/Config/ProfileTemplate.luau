--!strict
-- ProfileTemplate: the only place new player-data fields are added (see CLAUDE.md §6 Data).
export type ProfileData = {
	Version: number,
}

local ProfileTemplate: ProfileData = {
	Version = 1,
}

return ProfileTemplate
