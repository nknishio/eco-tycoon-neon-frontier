--[[
	FogPollutionSystem.lua
	Manages fog/pollution parts and their clearing by Bio-Scrubbers
	Optimized for mobile with efficient Part pooling
]]

local FogPollutionSystem = {}
FogPollutionSystem.__index = FogPollutionSystem

local Constants = require(script.Parent:WaitForChild("Constants"))
local Task = task -- Modern task library

-- ========== INITIALIZATION ==========

function FogPollutionSystem.new(fogFolder: Folder, plotBounds: Region3): FogPollutionSystem
	local self = setmetatable({}, FogPollutionSystem)
	
	self.FogFolder = fogFolder or Instance.new("Folder")
	self.FogFolder.Name = "FogParts"
	self.PlotBounds = plotBounds
	
	self.ActiveFogParts = {} -- Currently visible fog parts
	self.ClearedFogData = {} -- { [part] = { clearedAt, originalPos, originalTransparency } }
	self.UpdateLoopRunning = false
	self.FogPartPool = {} -- Object pool for performance
	
	return self
end

-- ========== FOG GENERATION & SPAWNING ==========

--- Spawn fog at random location within bounds
function FogPollutionSystem:SpawnFogPart(): Part?
	-- Cap fog parts for mobile performance
	if #self.ActiveFogParts >= Constants.FOG.MAX_FOG_PARTS then
		return nil
	end
	
	-- Create or reuse fog part
	local fogPart: Part
	
	if #self.FogPartPool > 0 then
		fogPart = table.remove(self.FogPartPool)
		fogPart.Parent = self.FogFolder
	else
		fogPart = Instance.new("Part")
		fogPart.Name = "FogPart"
		fogPart.Shape = Enum.PartType.Ball -- Low poly shape
		fogPart.CanCollide = false
		fogPart.CanQuery = false -- Raycast optimization
		fogPart.CanTouch = false -- Physics optimization
		fogPart.Massless = true
		fogPart.Color = Color3.fromRGB(150, 150, 150) -- Gray fog
		fogPart.Material = Enum.Material.SmoothPlastic
		fogPart.Size = Vector3.new(Constants.FOG.FOG_PART_SIZE[1], Constants.FOG.FOG_PART_SIZE[2], Constants.FOG.FOG_PART_SIZE[3])
		fogPart.TopSurface = Enum.SurfaceType.Smooth
		fogPart.BottomSurface = Enum.SurfaceType.Smooth
		fogPart.Parent = self.FogFolder
	end
	
	-- Random position within bounds
	local randomX = math.random(-Constants.GRID.GRID_WIDTH // 2, Constants.GRID.GRID_WIDTH // 2)
	local randomZ = math.random(-Constants.GRID.GRID_HEIGHT // 2, Constants.GRID.GRID_HEIGHT // 2)
	fogPart.Position = Vector3.new(randomX, 2, randomZ)
	fogPart.Transparency = Constants.FOG.FOG_TRANSPARENCY
	
	self.ActiveFogParts[fogPart] = true
	self.ClearedFogData[fogPart] = {
		clearedAt = 0,
		originalPos = fogPart.Position,
		originalTransparency = Constants.FOG.FOG_TRANSPARENCY,
	}
	
	if Constants.DEBUG.ENABLE_LOGS then
		print("[FogPollutionSystem] Fog spawned. Active: " .. #self.ActiveFogParts)
	end
	
	return fogPart
end

--- Remove fog part and recycle it
function FogPollutionSystem:RemoveFogPart(fogPart: Part)
	if not self.ActiveFogParts[fogPart] then return end
	
	self.ActiveFogParts[fogPart] = nil
	self.ClearedFogData[fogPart] = nil
	fogPart.Parent = nil
	table.insert(self.FogPartPool, fogPart)
end

-- ========== CLEARING & BIO-SCRUBBER LOGIC ==========

--- Clear fog parts near a Bio-Scrubber
function FogPollutionSystem:ClearFogAround(scrubberPos: Vector3, radius: number): number
	local clearedCount = 0
	local currentTime = os.time()
	
	for fogPart, _ in pairs(self.ActiveFogParts) do
		if fogPart.Parent ~= nil then
			local distance = (fogPart.Position - scrubberPos).Magnitude
			
			if distance <= radius then
				-- Reduce transparency (clear the fog)
				local newTransparency = math.max(
					fogPart.Transparency - Constants.FOG.FOG_CLEAR_SPEED,
					0.95 -- Remove when nearly invisible
				)
				fogPart.Transparency = newTransparency
				
				-- Mark as cleared
				self.ClearedFogData[fogPart].clearedAt = currentTime
				
				-- Remove completely invisible parts
				if newTransparency >= 0.95 then
					self:RemoveFogPart(fogPart)
					clearedCount = clearedCount + 1
				end
			end
		end
	end
	
	return clearedCount
end

--- Respawn cleared fog parts after delay
function FogPollutionSystem:RespawnClearedFog()
	local currentTime = os.time()
	local toRespawn = {}
	
	for fogPart, data in pairs(self.ClearedFogData) do
		if data.clearedAt > 0 and (currentTime - data.clearedAt) >= Constants.FOG.FOG_RESPAWN_DELAY then
			table.insert(toRespawn, fogPart)
		end
	end
	
	for _, fogPart in ipairs(toRespawn) do
		if fogPart.Parent == nil then
			fogPart.Parent = self.FogFolder
			fogPart.Position = self.ClearedFogData[fogPart].originalPos
			fogPart.Transparency = self.ClearedFogData[fogPart].originalTransparency
			self.ActiveFogParts[fogPart] = true
			self.ClearedFogData[fogPart].clearedAt = 0
		end
	end
end

-- ========== MAIN UPDATE LOOP ==========

--- Start the continuous update loop
function FogPollutionSystem:StartUpdateLoop(scrubberGetter: function)
	if self.UpdateLoopRunning then return end
	
	self.UpdateLoopRunning = true
	local lastRespawnCheck = os.time()
	
	while self.UpdateLoopRunning do
		local currentTime = os.time()
		
		-- Respawn check every 5 seconds
		if (currentTime - lastRespawnCheck) >= 5 then
			self:RespawnClearedFog()
			lastRespawnCheck = currentTime
		end
		
		Task.wait(Constants.FOG.CLEAR_CHECK_INTERVAL)
	end
end

--- Stop the update loop
function FogPollutionSystem:StopUpdateLoop()
	self.UpdateLoopRunning = false
end

-- ========== UTILITY FUNCTIONS ==========

--- Get the number of active fog parts
function FogPollutionSystem:GetFogCount(): number
	return #self.ActiveFogParts
end

--- Clear all fog instantly (for testing)
function FogPollutionSystem:ClearAllFog()
	for fogPart, _ in pairs(self.ActiveFogParts) do
		self:RemoveFogPart(fogPart)
	end
end

return FogPollutionSystem