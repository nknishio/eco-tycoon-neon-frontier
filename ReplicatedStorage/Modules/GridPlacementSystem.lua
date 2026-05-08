--[[
	GridPlacementSystem.lua
	Handles player building placement on a grid system with validation
	Supports undo, collision detection, and mobile-optimized placement
]]

local GridPlacementSystem = {}
GridPlacementSystem.__index = GridPlacementSystem

local Constants = require(script.Parent:WaitForChild("Constants"))

-- ========== INITIALIZATION ==========

function GridPlacementSystem.new(plotFolder: Folder): GridPlacementSystem
	local self = setmetatable({}, GridPlacementSystem)
	
	self.PlotFolder = plotFolder
	self.Buildings = {} -- { [gridX_gridY] = { gridX, gridY, modelInstance, modelName } }
	self.PlacementHistory = {} -- For undo functionality
	self.MaxUndoSteps = 20
	
	-- Validate plot folder exists
	if not plotFolder then
		error("GridPlacementSystem: PlotFolder is required")
	end
	
	return self
end

-- ========== PLACEMENT LOGIC ==========

--- Attempts to place a building at grid coordinates
function GridPlacementSystem:PlaceBuilding(
	building_template: Model,
	gridX: number,
	gridY: number,
	playerCurrency: number
): (boolean, string)
	
	-- Input validation
	if not building_template then
		return false, "Building template is required"
	end
	
	-- Check grid bounds
	if not Constants.IsGridPositionValid(gridX, gridY) then
		return false, "Position outside plot boundaries"
	end
	
	-- Check if cell is occupied
	local cellKey = gridX .. "_" .. gridY
	if self.Buildings[cellKey] then
		return false, "Cell already occupied"
	end
	
	-- Check collision with adjacent buildings (optional for multi-cell buildings)
	if self:HasCollision(gridX, gridY, building_template) then
		return false, "Collision detected with nearby buildings"
	end
	
	-- Retrieve building cost
	local buildingCost = self:GetBuildingCost(building_template)
	if playerCurrency < buildingCost then
		return false, "Insufficient currency. Need " .. buildingCost
	end
	
	-- Clone and position the building
	local newBuilding = building_template:Clone()
	newBuilding:MoveTo(Constants.GridToWorld(gridX, gridY))
	newBuilding.Parent = self.PlotFolder
	
	-- Store building reference
	self.Buildings[cellKey] = {
		gridX = gridX,
		gridY = gridY,
		model = newBuilding,
		name = building_template.Name,
		placedAt = os.time(),
	}
	
	-- Add to history for undo
	table.insert(self.PlacementHistory, {
		action = "place",
		cellKey = cellKey,
		building = newBuilding,
		gridX = gridX,
		gridY = gridY,
	})
	
	if #self.PlacementHistory > self.MaxUndoSteps then
		table.remove(self.PlacementHistory, 1)
	end
	
	if Constants.DEBUG.ENABLE_LOGS then
		print("[GridPlacementSystem] Building placed at (" .. gridX .. ", " .. gridY .. ")")
	end
	
	return true, "Building placed successfully"
end

--- Removes a building from the grid
function GridPlacementSystem:RemoveBuilding(gridX: number, gridY: number): (boolean, string)
	local cellKey = gridX .. "_" .. gridY
	
	if not self.Buildings[cellKey] then
		return false, "No building at this position"
	end
	
	local buildingData = self.Buildings[cellKey]
	buildingData.model:Destroy()
	self.Buildings[cellKey] = nil
	
	if Constants.DEBUG.ENABLE_LOGS then
		print("[GridPlacementSystem] Building removed from (" .. gridX .. ", " .. gridY .. ")")
	end
	
	return true, "Building removed"
end

--- Undo the last placement
function GridPlacementSystem:Undo(): (boolean, string)
	if #self.PlacementHistory == 0 then
		return false, "Nothing to undo"
	end
	
	local lastAction = table.remove(self.PlacementHistory)
	
	if lastAction.action == "place" then
		self.Buildings[lastAction.cellKey] = nil
		lastAction.building:Destroy()
	end
	
	if Constants.DEBUG.ENABLE_LOGS then
		print("[GridPlacementSystem] Action undone")
	end
	
	return true, "Action undone"
end

-- ========== VALIDATION & DETECTION ==========

--- Check if placement would collide with existing buildings
function GridPlacementSystem:HasCollision(gridX: number, gridY: number, template: Model): boolean
	-- For single-cell buildings, check the immediate cell
	local cellKey = gridX .. "_" .. gridY
	
	if self.Buildings[cellKey] then
		return true
	end
	
	-- Optional: Check adjacent cells if building is large
	local modelSize = template:FindFirstChild("PrimaryPart")
				 or template:GetChildren()[1]
	if not modelSize then
		return false
	end
	
	-- Check 3x3 area for safety
	for dx = -1, 1 do
		for dy = -1, 1 do
			local checkKey = (gridX + dx) .. "_" .. (gridY + dy)
			if self.Buildings[checkKey] then
				return true
			end
		end
	end
	
	return false
end

--- Get the cost of a building
function GridPlacementSystem:GetBuildingCost(building: Model): number
	-- Check for cost attribute on the model
	local costAttr = building:GetAttribute("BuildingCost")
	if costAttr and type(costAttr) == "number" then
		return costAttr
	end
	
	-- Default costs by building name
	local defaultCosts = {
		["BiouScrubber"] = Constants.BIO_SCRUBBER.COST,
	}
	
	return defaultCosts[building.Name] or 100
end

--- Get all buildings in a radius from a point
function GridPlacementSystem:GetBuildingsInRadius(centerPos: Vector3, radius: number): {Model}
	local buildingsInRadius = {}
	
	for _, buildingData in pairs(self.Buildings) do
		local distance = (buildingData.model:FindFirstChild("PrimaryPart") or buildingData.model).Position - centerPos
		local magnitude = distance.Magnitude
		
		if magnitude <= radius then
			table.insert(buildingsInRadius, buildingData.model)
		end
	end
	
	return buildingsInRadius
end

--- Get all placed buildings
function GridPlacementSystem:GetAllBuildings(): {Model}
	local allBuildings = {}
	
	for _, buildingData in pairs(self.Buildings) do
		table.insert(allBuildings, buildingData.model)
	end
	
	return allBuildings
end

return GridPlacementSystem