--[[
	GameInitializer.server.lua
	Main server initialization script for Eco-Tycoon: Neon Frontier
	Sets up all game systems and manages player joining
]]

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Task = task

-- Load modules
local Constants = require(ReplicatedStorage.Modules:WaitForChild("Constants"))
local GridPlacementSystem = require(ReplicatedStorage.Modules:WaitForChild("GridPlacementSystem"))
local FogPollutionSystem = require(ReplicatedStorage.Modules:WaitForChild("FogPollutionSystem"))
local PowerGridSystem = require(ReplicatedStorage.Modules:WaitForChild("PowerGridSystem"))
local DataManager = require(ReplicatedStorage.Modules:WaitForChild("DataManager"))

-- ========== GLOBALS ==========

local GlobalGameData = {
	PlayerSystems = {}, -- { [playerId] = { gridSystem, fogSystem, powerGridSystem } }
	DataManager = DataManager.new(),
	PowerGridSystem = PowerGridSystem.new(),
}

-- ========== INITIALIZATION ==========

local function Initialize()
	if Constants.DEBUG.ENABLE_LOGS then
		print("[GameInitializer] Eco-Tycoon: Neon Frontier initializing...")
	end
	
	-- Start global power grid detection
	GlobalGameData.PowerGridSystem:StartUpdateLoop()
	
	-- Start data autosave
	Task.spawn(function()
		GlobalGameData.DataManager:StartAutosave()
	end)
	
	if Constants.DEBUG.ENABLE_LOGS then
		print("[GameInitializer] Core systems initialized")
	end
end

-- ========== PLAYER JOINING ==========

local function SetupPlayer(player: Player)
	local playerId = player.UserId
	
	if Constants.DEBUG.ENABLE_LOGS then
		print("[GameInitializer] Player " .. playerId .. " (" .. player.Name .. ") joining...")
	end
	
	-- Load player data
	local playerData = GlobalGameData.DataManager:LoadPlayerData(playerId)
	
	-- Create tycoon plot folder
	local plotFolder = Instance.new("Folder")
	plotFolder.Name = "Plot_" .. playerId
	plotFolder.Parent = workspace:FindFirstChild("Plots") or workspace
	
	-- Initialize player-specific systems
	local gridSystem = GridPlacementSystem.new(plotFolder)
	local fogSystem = FogPollutionSystem.new(plotFolder)
	
	GlobalGameData.PlayerSystems[playerId] = {
		gridSystem = gridSystem,
		fogSystem = fogSystem,
		plotFolder = plotFolder,
		player = player,
	}
	
	-- Start fog update loop for this player
	Task.spawn(function()
		fogSystem:StartUpdateLoop(function()
			return gridSystem:GetBuildingsInRadius(plotFolder.Position, Constants.BIO_SCRUBBER.FOG_CLEAR_RADIUS)
		end)
	end)
	
	-- Spawn initial fog
	for i = 1, 10 do
		fogSystem:SpawnFogPart()
	end
	
	if Constants.DEBUG.ENABLE_LOGS then
		print("[GameInitializer] Player " .. playerId .. " systems initialized")
	end
end

-- ========== PLAYER LEAVING ==========

local function CleanupPlayer(player: Player)
	local playerId = player.UserId
	
	if Constants.DEBUG.ENABLE_LOGS then
		print("[GameInitializer] Player " .. playerId .. " leaving...")
	end
	
	-- Save player data
	GlobalGameData.DataManager:SavePlayerData(playerId)
	
	-- Cleanup player systems
	local playerSystems = GlobalGameData.PlayerSystems[playerId]
	if playerSystems then
		playerSystems.fogSystem:StopUpdateLoop()
		playerSystems.plotFolder:Destroy()
		GlobalGameData.PlayerSystems[playerId] = nil
	end
	
	-- Unregister power grid
	GlobalGameData.PowerGridSystem:UnregisterGrid(playerId)
end

-- ========== CURRENCY GENERATION LOOP ==========

local function StartCurrencyGeneration()
	local lastUpdateTime = os.time()
	
	while true do
		local currentTime = os.time()
		local deltaTime = math.max(currentTime - lastUpdateTime, 0.1) -- Prevent division by zero
		lastUpdateTime = currentTime
		
		for playerId, playerData in pairs(GlobalGameData.DataManager.PlayerData) do
			-- Get player's multiplier
			local multiplier = GlobalGameData.PowerGridSystem:GetCurrencyMultiplier(playerId)
			
			-- Get upgrade level for currency generation
			local upgradeLevel = GlobalGameData.DataManager:GetUpgradeLevel(playerId, "CurrencyGenerator")
			local currencyPerSecond = Constants.CURRENCY.BASE_GENERATION * upgradeLevel
			
			-- Generate currency (passive income)
			local amountToAdd = currencyPerSecond * deltaTime
			GlobalGameData.DataManager:AddCurrency(playerId, amountToAdd, multiplier)
		end
		
		Task.wait(1) -- Check every second
	end
end

-- ========== CONNECTIONS ==========

Players.PlayerAdded:Connect(SetupPlayer)
Players.PlayerRemoving:Connect(CleanupPlayer)

-- Setup existing players
for _, player in ipairs(Players:GetPlayers()) do
	SetupPlayer(player)
end

-- Start core loops
Task.spawn(Initialize)
Task.spawn(StartCurrencyGeneration)

-- ========== REMOTE EVENTS & FUNCTIONS (for client communication) ==========

-- Create RemoteEvents in ReplicatedStorage if not exists
local RemotesFolder = ReplicatedStorage:FindFirstChild("Remotes") or Instance.new("Folder")
RemotesFolder.Name = "Remotes"
RemotesFolder.Parent = ReplicatedStorage

-- Place Building Event
local PlaceBuilding = Instance.new("RemoteFunction")
PlaceBuilding.Name = "PlaceBuilding"
PlaceBuilding.Parent = RemotesFolder

function PlaceBuilding:InvokeClient(player, gridX, gridY, buildingName)
	-- Server-side validation will happen before calling this
end

function PlaceBuilding.OnServerInvoke(player, gridX, gridY, buildingName)
	local playerId = player.UserId
	local playerSystems = GlobalGameData.PlayerSystems[playerId]
	
	if not playerSystems then
		return false, "Player systems not initialized"
	end
	
	local currency = GlobalGameData.DataManager:GetCurrency(playerId)
	local template = ReplicatedStorage.Templates:FindFirstChild(buildingName)
	
	if not template then
		return false, "Building template not found"
	end
	
	local success, message = playerSystems.gridSystem:PlaceBuilding(
		template,
		gridX,
		gridY,
		currency
	)
	
	if success then
		local cost = playerSystems.gridSystem:GetBuildingCost(template)
		GlobalGameData.DataManager:SubtractCurrency(playerId, cost)
		GlobalGameData.DataManager:RecordBuildingPlacement(playerId, gridX, gridY, buildingName)
	end
	
	return success, message
end

if Constants.DEBUG.ENABLE_LOGS then
	print("[GameInitializer] Game initialization complete!")
end