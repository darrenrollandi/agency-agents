--!strict
-- Camera: first-person feel. Sensitivity and FOV become player settings in P5.
local Camera = {
	FieldOfView = 80,
	-- Upward pitch kick per revolver shot and how fast it settles back.
	RecoilPitchDegrees = 2.5,
	RecoilRecoveryPerSecond = 10,
	-- Viewmodel pushed back on fire (studs) and how fast it recovers.
	ViewmodelKick = 0.25,
	ViewmodelRecoveryPerSecond = 12,
}

return Camera
