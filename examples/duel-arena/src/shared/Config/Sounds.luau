--!strict
-- Sounds: every sound the game plays, by event name. Placeholders are Roblox's built-in client sounds
-- (rbxasset://sounds/...), which ship with the client and need no upload. Swap any id for a Creator
-- Store asset (rbxassetid://...) once the art direction is chosen. Volume 0–1, speed = PlaybackSpeed,
-- range = roll-off distance in studs for sounds other players hear.
export type SoundDef = {
	id: string,
	volume: number,
	speed: number,
	range: number?,
}

local Sounds = {}

Sounds.Defs = {
	Fire = { id = "rbxasset://sounds/Rocket shot.wav", volume = 0.6, speed = 1.7, range = 140 },
	Reload = { id = "rbxasset://sounds/snap.mp3", volume = 0.5, speed = 0.8 },
	ReloadDone = { id = "rbxasset://sounds/button.wav", volume = 0.4, speed = 1.3 },
	Swing = { id = "rbxasset://sounds/action_jump.mp3", volume = 0.5, speed = 1.8, range = 40 },
	Hit = { id = "rbxasset://sounds/electronicpingshort.wav", volume = 0.5, speed = 1.0 },
	Headshot = { id = "rbxasset://sounds/electronicpingshort.wav", volume = 0.6, speed = 1.5 },
	Kill = { id = "rbxasset://sounds/collide.wav", volume = 0.7, speed = 0.9 },
	Death = { id = "rbxasset://sounds/uuhhh.mp3", volume = 0.7, speed = 1.0, range = 80 },
	Hurt = { id = "rbxasset://sounds/Kid saying Ouch.wav", volume = 0.3, speed = 1.0 },
	Tick = { id = "rbxasset://sounds/button.wav", volume = 0.5, speed = 1.0 },
	Fight = { id = "rbxasset://sounds/bass.wav", volume = 0.8, speed = 1.0 },
	RoundWon = { id = "rbxasset://sounds/victory.wav", volume = 0.6, speed = 1.0 },
	RoundLost = { id = "rbxasset://sounds/bass.wav", volume = 0.5, speed = 0.7 },
	Ability = { id = "rbxasset://sounds/snap.mp3", volume = 0.6, speed = 1.3, range = 60 },
	Dash = { id = "rbxasset://sounds/action_jump.mp3", volume = 0.6, speed = 1.2, range = 60 },
	UI = { id = "rbxasset://sounds/button.wav", volume = 0.3, speed = 1.0 },
} :: { [string]: SoundDef }

return Sounds
