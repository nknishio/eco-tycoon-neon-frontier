--[[
	Constants.lua
	Centralized configuration for Eco-Tycoon: Neon Frontier
	Defines all gameplay, grid, and system parameters
]]

local Constants = {}

-- ========== GRID PLACEMENT SYSTEM ==========
Constants.GRID = {
	CELL_SIZE = 5, -- Size of each grid cell in studs
	GRID_WIDTH = 40, -- Width of tycoon plot in studs
	GRID_HEIGHT = 40, -- Height of tycoon plot in studs
	SNAP_ENABLED = true, -- Snap buildings to grid
	VISUAL_PREVIEW = true, -- Show placement preview
}

-- ========== BIO-SCRUBBER SPECIFICATIONS ==========
Constants.BIO_SCRUBBER = {
	COST = 250, -- Currency cost to place
	POWER_CONSUMPTION = 5, -- Power units required
	FOG_CLEAR_RADIUS = 20, -- Studs
	FOG_CLEAR_SPEED = 0.5, -- Transparency reduction per update
	CLEAR_EFFICIENCY = 1.0, -- Multiplier for clearing speed
	MODEL_SIZE = 3, -- Studs (for collision detection)
}

-- ========== FOG/POLLUTION SYSTEM ==========
Constants.FOG = {
	BASE_SPAWN_RATE = 2, -- New fog parts per minute (spawn-like behavior)
	MAX_FOG_PARTS = 100, -- Maximum fog parts in the world
	FOG_TRANSPARENCY = 0.6, -- Base transparency for fog parts
	CLEAR_CHECK_INTERVAL = 0.5, -- Seconds between clearing checks
	FOG_PART_SIZE = {4, 3, 4}, -- Default fog part dimensions
	FOG_RESPAWN_DELAY = 30, -- Seconds before cleared fog respawns
}

-- ========== POWER GRID SYSTEM ==========
Constants.POWER_GRID = {
	TOUCH_DETECTION_RANGE = 2, -- Studs (for touching detection)
	MULTIPLIER_ACTIVE = 1.2, -- Currency multiplier when grids touch
	CHECK_INTERVAL = 1, -- Seconds between grid checks
	MIN_POWER_HUB_DISTANCE = 3, -- Minimum studs between hubs to register touch
}

-- ========== CURRENCY SYSTEM ==========
Constants.CURRENCY = {
	BASE_GENERATION = 1, -- Base currency per second
	UPGRADE_COST_MULTIPLIER = 1.15, -- Each upgrade costs 15% more
	MAX_STORAGE = 999999, -- Maximum currency that can be held
}

-- ========== NEON AESTHETICS ==========
Constants.NEON = {
	PULSE_SPEED = 1.5, -- Seconds per pulse cycle
	PULSE_MIN_BRIGHTNESS = 0.5,
	PULSE_MAX_BRIGHTNESS = 2.0,
	NEON_COLOR = Color3.fromRGB(0, 255, 200), -- Cyan neon
	ACTIVE_TWEEN_DURATION = 0.8, -- Seconds
}

-- ========== DATA MANAGEMENT ==========
Constants.DATA = {
	AUTOSAVE_INTERVAL = 60, -- Seconds between autosaves
	MODE = "ProfileService", -- "ProfileService" or "DataStore2"
	DATASTORE_NAME = "EcoTycoonProfiles", -- DataStore key
}

-- ========== MOBILE OPTIMIZATION ==========
Constants.MOBILE = {
	LOW_QUALITY_MODE = true, -- Disable certain visual effects on mobile
	MAX_VISIBLE_FOG_PARTS = 30, -- Limit fog rendering
	LOOP_UPDATE_INTERVAL = 0.1, -- Seconds (10 FPS minimum for mobile)
}

-- ========== DEBUG SETTINGS ==========
Constants.DEBUG = {
	ENABLE_LOGS = true,
	VISUAL_DEBUG = false, -- Show grid lines and collision boxes
	FORCE_OFFLINE_MODE = false, -- Test without DataStore
}

-- ========== HELPER FUNCTIONS ==========

--- Converts grid coordinates to world position
function Constants.GridToWorld(gridX: number, gridY: number): Vector3
	return Vector3.new(
		gridX * Constants.GRID.CELL_SIZE,
		0,
		gridY * Constants.GRID.CELL_SIZE
	)
end

--- Converts world position to grid coordinates
function Constants.WorldToGrid(position: Vector3): (number, number)
	local gridX = math.round(position.X / Constants.GRID.CELL_SIZE)
	local gridY = math.round(position.Z / Constants.GRID.CELL_SIZE)
	return gridX, gridY
end

--- Check if grid position is valid
function Constants.IsGridPositionValid(gridX: number, gridY: number): boolean
	return
		gridX >= 0
		and gridX < Constants.GRID.GRID_WIDTH
		and gridY >= 0
		and gridY < Constants.GRID.GRID_HEIGHT
end

return Constants