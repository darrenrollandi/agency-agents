--!strict
-- CombatService: server-authoritative weapons. The revolver is hitscan validated by a server
-- re-raycast; the knife is a server hitbox. Ammo, fire rate, reloads and damage are decided here;
-- the client only predicts visuals. Friendly fire is off. Non-player humanoids (training dummies)
-- can always be hit.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Types = require(Shared.Types)
local Weapons = require(Shared.Config.Weapons)
local Net = require(Shared.Net.Net)
local Log = require(Shared.Util.Log)
local WeaponModels = require(Shared.WeaponModels)
local PlayerState = require(script.Parent.Parent.PlayerState)

type WeaponId = Types.WeaponId

type Loadout = {
	weapon: WeaponId,
	ammo: number,
	reloading: boolean,
	reloadToken: number,
	lastFireAt: number,
	lastSwingAt: number,
	-- Dead Eye: the next shot before empowerUntil (os.clock) is multiplied.
	empowerMultiplier: number,
	empowerUntil: number,
}

local WORLD_MODEL_NAME = "WorldWeapon"
-- Where the weapon grip sits relative to the hand.
local HAND_OFFSET = CFrame.new(0, -0.3, -0.45)

local CombatService = {}

-- Present only while a player is armed (round Live and alive).
local loadouts: { [Player]: Loadout } = {}

-- Publish the parts of the loadout the client HUD needs as Player attributes.
local function publish(player: Player, loadout: Loadout?)
	if loadout then
		player:SetAttribute("Weapon", loadout.weapon)
		player:SetAttribute("Ammo", loadout.ammo)
		player:SetAttribute("Reloading", loadout.reloading)
		player:SetAttribute("Empowered", loadout.empowerUntil > os.clock())
	else
		player:SetAttribute("Weapon", nil)
		player:SetAttribute("Ammo", nil)
		player:SetAttribute("Reloading", nil)
		player:SetAttribute("Empowered", nil)
	end
end

local function humanoidOf(model: Model): Humanoid?
	return model:FindFirstChildOfClass("Humanoid")
end

-- The character-like model (has a Humanoid) an instance belongs to, if any.
local function characterOf(instance: Instance?): Model?
	local current = instance
	while current do
		if current:IsA("Model") and humanoidOf(current) then
			return current
		end
		current = current.Parent
	end
	return nil
end

local function isEnemy(attacker: Player, victim: Player): boolean
	if attacker == victim then
		return false
	end
	local a = PlayerState.get(attacker)
	local v = PlayerState.get(victim)
	return a.duelId ~= nil and a.duelId == v.duelId and a.team ~= v.team
end

local function canDamage(attacker: Player, model: Model): boolean
	local victim = Players:GetPlayerFromCharacter(model)
	if victim then
		return isEnemy(attacker, victim)
	end
	return true -- non-player humanoid: training dummy
end

-- Applies damage; true if this hit killed the target.
local function applyDamage(model: Model, damage: number): boolean
	local humanoid = humanoidOf(model)
	if not humanoid or humanoid.Health <= 0 then
		return false
	end
	humanoid:TakeDamage(damage)
	return humanoid.Health <= 0
end

local function aliveCharacter(player: Player): Model?
	local character = player.Character
	local humanoid = if character then humanoidOf(character) else nil
	if not character or not humanoid or humanoid.Health <= 0 then
		return nil
	end
	return character
end

local function confirmHit(
	attacker: Player,
	model: Model,
	damage: number,
	headshot: boolean,
	killed: boolean
)
	local confirm: Types.HitConfirm = {
		victimName = model.Name,
		damage = damage,
		headshot = headshot,
		killed = killed,
	}
	Net.fireClient(attacker, "HitConfirm", confirm)
	Log.debug(
		`Combat: {attacker.Name} hit {model.Name} for {damage}{if headshot
			then " (headshot)"
			else ""}{if killed then " KILL" else ""}`
	)
end

local function removeWorldModel(player: Player)
	local character = player.Character
	local existing = if character then character:FindFirstChild(WORLD_MODEL_NAME) else nil
	if existing then
		existing:Destroy()
	end
end

-- Third-person weapon welded to the right hand so opponents can see what you hold.
local function attachWorldModel(player: Player, weapon: WeaponId)
	removeWorldModel(player)
	local character = player.Character
	if not character then
		return
	end
	local hand = character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")
	if not hand or not hand:IsA("BasePart") then
		return
	end
	local model = WeaponModels.build(weapon, false)
	model.Name = WORLD_MODEL_NAME
	local grip = model.PrimaryPart :: BasePart
	model:PivotTo(hand.CFrame * HAND_OFFSET)
	local weld = Instance.new("Weld")
	weld.Part0 = hand
	weld.Part1 = grip
	weld.C0 = HAND_OFFSET
	weld.Parent = grip
	model.Parent = character
end

local function onFire(
	player: Player,
	origin: Vector3,
	direction: Vector3,
	hitPart: Instance?,
	_timestamp: number
)
	local loadout = loadouts[player]
	if not loadout or loadout.weapon ~= "Revolver" then
		return
	end
	local character = aliveCharacter(player)
	if not character then
		return
	end
	local head = character:FindFirstChild("Head")
	if not head or not head:IsA("BasePart") then
		return
	end
	if (head.Position - origin).Magnitude > Weapons.Revolver.OriginTolerance then
		Log.debug(`Combat: {player.Name} fired from too far away from their head; dropped`)
		return
	end
	local now = os.clock()
	if now - loadout.lastFireAt < Weapons.Revolver.FireInterval * 0.9 then
		return
	end
	if loadout.reloading or loadout.ammo <= 0 then
		return
	end
	loadout.lastFireAt = now
	loadout.ammo -= 1
	publish(player, loadout)

	-- The server ray is the truth.
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }
	local result = Workspace:Raycast(origin, direction * Weapons.Revolver.MaxRange, params)
	local hitPosition = if result
		then result.Position
		else origin + direction * Weapons.Revolver.MaxRange
	local victim = if result then characterOf(result.Instance) else nil
	local headshot = result ~= nil and victim ~= nil and result.Instance.Name == "Head"

	-- Lag tolerance: the client saw a hit the server ray narrowly missed. Accept a body hit if the
	-- claimed victim's root is within HitTolerance of the ray and nothing solid is in the way.
	if not victim and hitPart then
		local claimed = characterOf(hitPart)
		local root = if claimed then claimed:FindFirstChild("HumanoidRootPart") else nil
		if claimed and root and root:IsA("BasePart") then
			local rel = root.Position - origin
			local along = rel:Dot(direction)
			local perpendicular = (rel - direction * along).Magnitude
			local blocked = result ~= nil and (result.Position - origin).Magnitude < along - 2
			if
				along > 0
				and along <= Weapons.Revolver.MaxRange
				and perpendicular <= Weapons.Revolver.HitTolerance
				and not blocked
			then
				victim = claimed
				hitPosition = root.Position
			end
		end
	end

	-- Dead Eye is spent by the shot whether or not it lands.
	local empowered = loadout.empowerUntil > now
	if empowered then
		loadout.empowerUntil = 0
		publish(player, loadout)
	end

	if victim and canDamage(player, victim) then
		local multiplier = if headshot then Weapons.Revolver.HeadshotMultiplier else 1
		if empowered then
			multiplier *= loadout.empowerMultiplier
		end
		local damage = Weapons.Revolver.Damage * multiplier
		local killed = applyDamage(victim, damage)
		confirmHit(player, victim, damage, headshot, killed)
	end
	Net.fireAllClients("ShotFired", player, origin, hitPosition)
end

local function onReload(player: Player)
	local loadout = loadouts[player]
	if
		not loadout
		or loadout.weapon ~= "Revolver"
		or loadout.reloading
		or loadout.ammo >= Weapons.Revolver.Cylinder
		or not aliveCharacter(player)
	then
		return
	end
	loadout.reloading = true
	loadout.reloadToken += 1
	local token = loadout.reloadToken
	publish(player, loadout)
	task.delay(Weapons.Revolver.ReloadSeconds, function()
		if loadouts[player] == loadout and loadout.reloadToken == token and loadout.reloading then
			loadout.reloading = false
			loadout.ammo = Weapons.Revolver.Cylinder
			publish(player, loadout)
		end
	end)
end

local function onSwing(player: Player)
	local loadout = loadouts[player]
	if not loadout or loadout.weapon ~= "Knife" then
		return
	end
	local character = aliveCharacter(player)
	if not character then
		return
	end
	local now = os.clock()
	if now - loadout.lastSwingAt < Weapons.Knife.SwingInterval * 0.9 then
		return
	end
	loadout.lastSwingAt = now
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return
	end
	local center = root.CFrame * CFrame.new(0, 0, -Weapons.Knife.Range / 2)
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }
	local hit: { [Model]: boolean } = {}
	for _, part in Workspace:GetPartBoundsInBox(center, Weapons.Knife.HitboxSize, params) do
		local model = characterOf(part)
		if model and not hit[model] and canDamage(player, model) then
			hit[model] = true
			local killed = applyDamage(model, Weapons.Knife.Damage)
			confirmHit(player, model, Weapons.Knife.Damage, false, killed)
		end
	end
end

local function onEquip(player: Player, weapon: WeaponId)
	local loadout = loadouts[player]
	if not loadout or loadout.weapon == weapon then
		return
	end
	loadout.weapon = weapon
	if loadout.reloading then
		-- Swapping cancels a reload.
		loadout.reloading = false
		loadout.reloadToken += 1
	end
	publish(player, loadout)
	attachWorldModel(player, weapon)
end

-- Give the player a full revolver and the knife. DuelService calls this when a round goes Live.
function CombatService.arm(player: Player)
	local loadout: Loadout = {
		weapon = "Revolver",
		ammo = Weapons.Revolver.Cylinder,
		reloading = false,
		reloadToken = 0,
		lastFireAt = 0,
		lastSwingAt = 0,
		empowerMultiplier = 1,
		empowerUntil = 0,
	}
	loadouts[player] = loadout
	publish(player, loadout)
	attachWorldModel(player, "Revolver")
end

-- The weapon in hand, or nil when disarmed.
function CombatService.currentWeapon(player: Player): WeaponId?
	local loadout = loadouts[player]
	return if loadout then loadout.weapon else nil
end

-- Speed Loader: instant full cylinder. False if there was nothing to reload.
function CombatService.refill(player: Player): boolean
	local loadout = loadouts[player]
	if not loadout or loadout.weapon ~= "Revolver" then
		return false
	end
	if loadout.ammo >= Weapons.Revolver.Cylinder and not loadout.reloading then
		return false
	end
	loadout.reloading = false
	loadout.reloadToken += 1
	loadout.ammo = Weapons.Revolver.Cylinder
	publish(player, loadout)
	return true
end

-- Dead Eye: the next revolver shot fired within `seconds` deals `multiplier` × damage.
function CombatService.empowerNextShot(player: Player, multiplier: number, seconds: number): boolean
	local loadout = loadouts[player]
	if not loadout or loadout.weapon ~= "Revolver" then
		return false
	end
	loadout.empowerMultiplier = multiplier
	loadout.empowerUntil = os.clock() + seconds
	publish(player, loadout)
	task.delay(seconds, function()
		if loadouts[player] == loadout and loadout.empowerUntil <= os.clock() then
			publish(player, loadout)
		end
	end)
	return true
end

-- Take everything away (round over, death, leave).
function CombatService.disarm(player: Player)
	if loadouts[player] then
		loadouts[player] = nil
		publish(player, nil)
	end
	removeWorldModel(player)
end

function CombatService.isArmed(player: Player): boolean
	return loadouts[player] ~= nil
end

function CombatService.start()
	Net.onServer("Fire", onFire)
	Net.onServer("Reload", onReload)
	Net.onServer("Swing", onSwing)
	Net.onServer("Equip", onEquip)
	Players.PlayerRemoving:Connect(function(player)
		CombatService.disarm(player)
	end)
end

return CombatService
