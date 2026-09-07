--!strict
-- Camera: first-person feel and the ranges the Settings panel may pick from.
local Camera = {
	FieldOfView = 80,
	FieldOfViewMin = 60,
	FieldOfViewMax = 100,
	FieldOfViewStep = 5,
	-- Mouse sensitivity multiplier (UserInputService.MouseDeltaSensitivity).
	Sensitivity = 1,
	SensitivityMin = 0.2,
	SensitivityMax = 3,
	SensitivityStep = 0.1,
	-- Upward pitch kick per revolver shot and how fast it settles back.
	RecoilPitchDegrees = 2.5,
	RecoilRecoveryPerSecond = 10,
	-- Viewmodel pushed back on fire (studs) and how fast it recovers.
	ViewmodelKick = 0.25,
	ViewmodelRecoveryPerSecond = 12,
}

return Camera
