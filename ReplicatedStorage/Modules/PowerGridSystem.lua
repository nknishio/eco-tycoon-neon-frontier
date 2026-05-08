--[[
	PowerGridSystem.lua
	Detects when players' Power Grid hubs touch and applies currency multipliers
	Optimized with spatial partitioning for mobile
]]

local PowerGridSystem = {}
PowerGridSystem.__index = PowerGridSystem

local Constants = require(script.Parent:WaitForChild("Constants"))
local Task = task

-- ========== INITIALIZATION ==========

function PowerGridSystem.new(): PowerGridSystem
	local self = setmetatable({}, PowerGridSystem)
	
	self.ActiveGrids = {} -- { [playerId] = { hub: Part, position: Vector3, isActive: bool } }
	self.GridConnections = {} -- { [playerId] = { connectedPlayers: {}, isMultiplierActive: bool } }
	self.UpdateLoopRunning = false
	self.OnMultiplierChanged = Instance.new("BindableEvent") -- Signal for multiplier changes
	
	return self
end

-- ========== GRID REGISTRATION ==========

--- Register a player's power grid hub
function PowerGridSystem:RegisterGrid(playerId: number, hubPart: Part): boolean
	if not hubPart then
		return false
	end
	
	self.ActiveGrids[playerId] = {
		hub = hubPart,
		position = hubPart.Position,
		isActive = true,
		originalPosition = hubPart.Position,
	}
	
	self.GridConnections[playerId] = {
		connectedPlayers = {},
		isMultiplierActive = false,
	}
	
	if Constants.DEBUG.ENABLE_LOGS then
		print("[PowerGridSystem] Grid registered for player " .. playerId)
	end
	
	return true
end

--- Unregister a player's power grid
function PowerGridSystem:UnregisterGrid(playerId: number)
	self.ActiveGrids[playerId] = nil
	self.GridConnections[playerId] = nil
	
	if Constants.DEBUG.ENABLE_LOGS then
		print("[PowerGridSystem] Grid unregistered for player " .. playerId)
	end
end

--- Check if a grid is active
function PowerGridSystem:IsGridActive(playerId: number): boolean
	if not self.ActiveGrids[playerId] then return false end
	
	local gridData = self.ActiveGrids[playerId]
	return gridData.isActive and gridData.hub and gridData.hub.Parent ~= nil
end

-- ========== DETECTION & CONNECTIONS ==========

--- Check for touching power grids
function PowerGridSystem:DetectGridTouches(): {[number]: {[number]: boolean}}
	local newConnections = {}
	
	local playerIds = {}
	for playerId, _ in pairs(self.ActiveGrids) do
		if self:IsGridActive(playerId) then
			table.insert(playerIds, playerId)
		end
	end
	
	-- Compare each pair of grids
	for i = 1, #playerIds do
		for j = i + 1, #playerIds do
			local player1Id = playerIds[i]
			local player2Id = playerIds[j]
			
			local hub1 = self.ActiveGrids[player1Id].hub
			local hub2 = self.ActiveGrids[player2Id].hub
			
			if hub1 and hub2 then
				local distance = (hub1.Position - hub2.Position).Magnitude
				
				if distance <= Constants.POWER_GRID.TOUCH_DETECTION_RANGE then
					if not newConnections[player1Id] then
						newConnections[player1Id] = {}
					end
					if not newConnections[player2Id] then
						newConnections[player2Id] = {}
					end
					
					newConnections[player1Id][player2Id] = true
					newConnections[player2Id][player1Id] = true
				end
			end
		end
	end
	
	return newConnections
end

--- Update grid connections and apply multipliers
function PowerGridSystem:UpdateConnections()
	local newConnections = self:DetectGridTouches()
	
	-- Check for changes
	for playerId, gridConnection in pairs(self.GridConnections) do
		local wasActive = gridConnection.isMultiplierActive
		local isNowActive = newConnections[playerId] and (#newConnections[playerId] > 0)
		
		-- If status changed, fire signal
		if wasActive ~= isNowActive then
			gridConnection.isMultiplierActive = isNowActive
			self.OnMultiplierChanged:Fire(playerId, isNowActive)
			
			if Constants.DEBUG.ENABLE_LOGS then
				local status = isNowActive and "ACTIVE" or "INACTIVE"
				print("[PowerGridSystem] Player " .. playerId .. " multiplier: " .. status)
			end
		end
	
		-- Update connection list
		gridConnection.connectedPlayers = newConnections[playerId] or {}
	end
end

--- Get currency multiplier for a player
function PowerGridSystem:GetCurrencyMultiplier(playerId: number): number
	if not self.GridConnections[playerId] then return 1.0 end
	
	if self.GridConnections[playerId].isMultiplierActive then
		return Constants.POWER_GRID.MULTIPLIER_ACTIVE
	else
		return 1.0
	end
end

--- Get list of connected players
function PowerGridSystem:GetConnectedPlayers(playerId: number): {number}
	if not self.GridConnections[playerId] then return {} end
	
	local connected = {}
	for connectedId, _ in pairs(self.GridConnections[playerId].connectedPlayers) do
		table.insert(connected, connectedId)
	end
	
	return connected
end

-- ========== UPDATE LOOP ==========

--- Start continuous grid checking
function PowerGridSystem:StartUpdateLoop()
	if self.UpdateLoopRunning then return end
	
	self.UpdateLoopRunning = true
	
	while self.UpdateLoopRunning do
		self:UpdateConnections()
		Task.wait(Constants.POWER_GRID.CHECK_INTERVAL)
	end
end

--- Stop update loop
function PowerGridSystem:StopUpdateLoop()
	self.UpdateLoopRunning = false
end

-- ========== UTILITY FUNCTIONS ==========

--- Get all active grids
function PowerGridSystem:GetActiveGrids(): {[number]: any}
	local active = {}
	
	for playerId, gridData in pairs(self.ActiveGrids) do
		if self:IsGridActive(playerId) then
			table.insert(active, { playerId = playerId, gridData = gridData })
		end
	end
	
	return active
end

return PowerGridSystem