--!strict
-- MonetisationService: game passes (skins) and developer products (XP boost). Owns
-- MarketplaceService.ProcessReceipt, which is idempotent through the profile's PurchaseHistory, and
-- is the only code besides ProgressionService that writes Profile.Data (purchase fields only).
-- Product ids come from Config/Monetisation; anything left at 0 is inert.
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Monetisation = require(Shared.Config.Monetisation)
local Skins = require(Shared.Config.Skins)
local Net = require(Shared.Net.Net)
local Log = require(Shared.Util.Log)
local PurchaseLedger = require(Shared.Util.PurchaseLedger)
local DataService = require(script.Parent.DataService)
local ProgressionService = require(script.Parent.ProgressionService)

export type ReceiptInfo = {
	PlayerId: number,
	ProductId: number,
	PurchaseId: string,
}

-- Studio only: a fake product id the DebugCommands "receipt" harness can grant, so ProcessReceipt
-- idempotency is testable before the real product exists. Never registered outside Studio.
local DEBUG_BOOST_PRODUCT_ID = 999999001

local MonetisationService = {}

MonetisationService.DebugBoostProductId = DEBUG_BOOST_PRODUCT_ID

-- productId → grant function; true if granted.
local productGrants: { [number]: (Player, DataService.Profile) -> boolean } = {}

local function passIdForSkin(skinId: string): number?
	local id = Monetisation.SkinPasses[skinId]
	if id and Monetisation.isConfigured(id) then
		return id
	end
	return nil
end

local function skinForPass(passId: number): string?
	for skinId, id in Monetisation.SkinPasses do
		if id == passId then
			return skinId
		end
	end
	return nil
end

-- Grant every game-pass skin the player owns. Called on profile load and after a purchase.
local function syncGamePasses(player: Player)
	for skinId, passId in Monetisation.SkinPasses do
		if not Monetisation.isConfigured(passId) or not Skins.get(skinId) then
			continue
		end
		local ok, owns = pcall(function()
			return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passId)
		end)
		if ok and owns then
			ProgressionService.grantSkin(player, skinId)
		elseif not ok then
			Log.warn(
				`Monetisation: UserOwnsGamePassAsync failed for {player.Name}/{skinId}: {owns}`
			)
		end
	end
end

-- The core of ProcessReceipt, separated so it can be exercised with a fake receipt in Studio.
function MonetisationService.handleReceipt(receipt: ReceiptInfo): Enum.ProductPurchaseDecision
	local player = Players:GetPlayerByUserId(receipt.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local profile = DataService.getProfile(player)
	if not profile then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	if PurchaseLedger.has(profile.Data.PurchaseHistory, receipt.PurchaseId) then
		-- Replayed receipt: already granted, just acknowledge.
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	local grant = productGrants[receipt.ProductId]
	if not grant then
		Log.warn(`Monetisation: receipt for unknown product {receipt.ProductId}; not granting`)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	if not grant(player, profile) then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	PurchaseLedger.record(
		profile.Data.PurchaseHistory,
		receipt.PurchaseId,
		Monetisation.PurchaseHistoryLimit
	)
	ProgressionService.refresh(player)
	Log.info(
		`Monetisation: granted product {receipt.ProductId} to {player.Name} ({receipt.PurchaseId})`
	)
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

local function onRequestPurchase(player: Player, kind: string, key: string)
	if kind == "GamePass" then
		local passId = passIdForSkin(key)
		if not passId then
			return
		end
		MarketplaceService:PromptGamePassPurchase(player, passId)
	elseif kind == "Product" then
		local product = (Monetisation.DevProducts :: { [string]: any })[key]
		if not product or not Monetisation.isConfigured(product.id) then
			return
		end
		MarketplaceService:PromptProductPurchase(player, product.id)
	end
end

function MonetisationService.start()
	local boost = Monetisation.DevProducts.XPBoost
	local function grantBoost(_player: Player, profile: DataService.Profile): boolean
		local now = os.time()
		local from = math.max(now, profile.Data.XPBoostUntil)
		profile.Data.XPBoostUntil = from + boost.minutes * 60
		return true
	end
	if Monetisation.isConfigured(boost.id) then
		productGrants[boost.id] = grantBoost
	end
	if Config.Debug then
		productGrants[DEBUG_BOOST_PRODUCT_ID] = grantBoost
	end

	MarketplaceService.ProcessReceipt = function(receipt)
		return MonetisationService.handleReceipt(receipt :: any)
	end

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(
		function(player: Player, passId: number, wasPurchased: boolean)
			if not wasPurchased then
				return
			end
			local skinId = skinForPass(passId)
			if skinId then
				ProgressionService.grantSkin(player, skinId)
				Net.fireClient(
					player,
					"Notify",
					`Unlocked {(Skins.get(skinId) :: Skins.SkinDef).name}!`
				)
			end
		end
	)

	DataService.onProfileLoaded(function(player)
		syncGamePasses(player)
	end)
	Net.onServer("RequestPurchase", onRequestPurchase)

	local configured = 0
	for _, id in Monetisation.SkinPasses do
		if Monetisation.isConfigured(id) then
			configured += 1
		end
	end
	if Monetisation.isConfigured(boost.id) then
		configured += 1
	end
	Log.info(`Monetisation: {configured} product(s) configured`)
end

return MonetisationService
