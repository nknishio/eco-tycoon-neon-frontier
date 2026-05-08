--[[
	DataManager.lua
	Handles player data persistence using ProfileService
	Manages currency, skins, and building positions
]]

local DataManager = {}
DataManager.__index = DataManager

local Constants = require(script.Parent:WaitForChild("Constants"))
local Task = task

-- ========== INITIALIZATION ==========

function DataManager.new(useProfileService: boolean?): DataManager
	local self = setmetatable({}, DataManager)
	
	self.UseProfileService = useProfileService ~= false
	self.PlayerData = {} -- { [playerId] = playerProfile }
	self.AutosaveInterval = Constants.DATA.AUTOSAVE_INTERVAL
	self.IsSaving = false
	
	-- Will be set by game initializer
	self.ProfileService = nil
	self.DataStore = nil
	
	return self
end

-- ========== PLAYER PROFILE STRUCTURE ==========

--- Create a new player profile template
function DataManager.CreatePlayerProfile(playerId: number): {}
	return {
		PlayerId = playerId,
		CreatedAt = os.time(),
		LastSaved = os.time(),
		
		-- Currency System
		Currency = 0,
		CurrencyEarned = 0, -- Total earned in session
		
		-- Buildings & Placements
		Buildings = {}, -- { { gridX, gridY, buildingName, placedAt } }
		PlacedBuildingCount = 0,
		
		-- Upgrades
		Upgrades = {
			CurrencyGenerator = 1, -- Level
			BioScrubberEfficiency = 1,
			PowerGridCapacity = 1,
		},
		
		-- Cosmetics
		UnlockedSkins = { "Default" }, -- Neon color skins
		ActiveSkin = "Default",
		
		-- Statistics
		SessionStartTime = os.time(),
		Playtime = 0, -- Seconds
		FogCleared = 0, -- Total fog parts cleared
		BuildingsPlaced = 0,
		
		-- Power Grid
		PowerGridActive = false,
		PowerGridPosition = nil,
		
		-- Multipliers
		ActiveMultipliers = {}, -- { multiplierName = multiplierValue }
	}
end

-- ========== DATA LOADING & SAVING ==========

--- Load player data (stub - implement with ProfileService)
function DataManager:LoadPlayerData(playerId: number): {}
	if Constants.DEBUG.FORCE_OFFLINE_MODE then
		return self.CreatePlayerProfile(playerId)
	end
	
	-- This will be implemented with ProfileService
	if self.PlayerData[playerId] then
		return self.PlayerData[playerId]
	end
	
	local newProfile = DataManager.CreatePlayerProfile(playerId)
	self.PlayerData[playerId] = newProfile
	
	if Constants.DEBUG.ENABLE_LOGS then
		print("[DataManager] Player " .. playerId .. " data loaded/created")
	end
	
	return newProfile
end

--- Save player data
function DataManager:SavePlayerData(playerId: number): boolean
	if Constants.DEBUG.FORCE_OFFLINE_MODE then
		return true
	end
	
	if not self.PlayerData[playerId] then
		return false
	end
	
	local profile = self.PlayerData[playerId]
	profile.LastSaved = os.time()
	
	-- Update playtime
	if profile.SessionStartTime then
		profile.Playtime = profile.Playtime + (os.time() - profile.SessionStartTime)
		profile.SessionStartTime = os.time()
	end
	
	if Constants.DEBUG.ENABLE_LOGS then
		print("[DataManager] Player " .. playerId .. " data saved")
	end
	
	return true
end

--- Autosave all player data periodically
function DataManager:StartAutosave()

while true do
		for playerId, _ in pairs(self.PlayerData) do
			self:SavePlayerData(playerId)
		end
		
		Task.wait(self.AutosaveInterval)
	end
end

-- ========== CURRENCY OPERATIONS ==========

--- Add currency to player
function DataManager:AddCurrency(playerId: number, amount: number, multiplier: number?): number
	if not self.PlayerData[playerId] then
		return 0
	end
	
	multiplier = multiplier or 1
	local finalAmount = math.floor(amount * multiplier)
	
	local profile = self.PlayerData[playerId]
	profile.Currency = math.min(
		profile.Currency + finalAmount,
		Constants.CURRENCY.MAX_STORAGE
	)
	profile.CurrencyEarned = profile.CurrencyEarned + finalAmount
	
	return profile.Currency
end

--- Subtract currency from player
function DataManager:SubtractCurrency(playerId: number, amount: number): (boolean, number)
	if not self.PlayerData[playerId] then
		return false, 0
	end
	
	local profile = self.PlayerData[playerId]
	
	if profile.Currency >= amount then
		profile.Currency = profile.Currency - amount
		return true, profile.Currency
	else
		return false, profile.Currency
	end
end

--- Get player currency
function DataManager:GetCurrency(playerId: number): number
	if not self.PlayerData[playerId] then
		return 0
	end
	
	return self.PlayerData[playerId].Currency
end

-- ========== BUILDING OPERATIONS ==========

--- Record building placement
function DataManager:RecordBuildingPlacement(
	playerId: number,
	gridX: number,
	gridY: number,
	buildingName: string
): boolean
	if not self.PlayerData[playerId] then
		return false
	end
	
	local profile = self.PlayerData[playerId]
	
	table.insert(profile.Buildings, {
		gridX = gridX,
		gridY = gridY,
		buildingName = buildingName,
		placedAt = os.time(),
	})
	
	profile.BuildingsPlaced = profile.BuildingsPlaced + 1
	
	return true
end

--- Get all placed buildings for player
function DataManager:GetPlacedBuildings(playerId: number): {}
	if not self.PlayerData[playerId] then
		return {}
	end
	
	return self.PlayerData[playerId].Buildings
end

-- ========== UPGRADE OPERATIONS ==========

--- Get upgrade level
function DataManager:GetUpgradeLevel(playerId: number, upgradeType: string): number
	if not self.PlayerData[playerId] then
		return 1
	end
	
	local profile = self.PlayerData[playerId]
	return profile.Upgrades[upgradeType] or 1
end

--- Increase upgrade level
function DataManager:UpgradeLevel(playerId: number, upgradeType: string): boolean
	if not self.PlayerData[playerId] then
		return false
	end
	
	local profile = self.PlayerData[playerId]
	profile.Upgrades[upgradeType] = (profile.Upgrades[upgradeType] or 1) + 1
	
	return true
end

-- ========== SKIN OPERATIONS ==========

--- Unlock a skin
function DataManager:UnlockSkin(playerId: number, skinName: string): boolean
	if not self.PlayerData[playerId] then
		return false
	end
	
	local profile = self.PlayerData[playerId]
	
	-- Check if already unlocked
	for _, skin in ipairs(profile.UnlockedSkins) do
		if skin == skinName then
			return false
		end
	end
	
	table.insert(profile.UnlockedSkins, skinName)
	
	return true
end

--- Set active skin
function DataManager:SetActiveSkin(playerId: number, skinName: string): boolean
	if not self.PlayerData[playerId] then
		return false
	end
	
	local profile = self.PlayerData[playerId]
	
	-- Check if owned
	for _, skin in ipairs(profile.UnlockedSkins) do
		if skin == skinName then
			profile.ActiveSkin = skinName
			return true
		end
	end
	
	return false
end

-- ========== STATISTICS ==========

--- Record fog cleared
function DataManager:RecordFogCleared(playerId: number, count: number)
	if not self.PlayerData[playerId] then return end
	
	self.PlayerData[playerId].FogCleared = self.PlayerData[playerId].FogCleared + count
end

--- Get player statistics
function DataManager:GetStatistics(playerId: number): {}
	if not self.PlayerData[playerId] then
		return {}
	end
	
	local profile = self.PlayerData[playerId]
	
	return {
		CurrencyEarned = profile.CurrencyEarned,
		BuildingsPlaced = profile.BuildingsPlaced,
		FogCleared = profile.FogCleared,
		Playtime = profile.Playtime,
	}
end

return DataManager