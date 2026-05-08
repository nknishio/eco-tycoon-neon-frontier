# Eco-Tycoon: Neon Frontier 🌆

A foundational Roblox tycoon game framework featuring Bio-Scrubbers, pollution management, and interconnected power grids.

## 🎮 Core Features

### 1. **Grid Placement System**
- Snap-to-grid building placement with collision detection
- Currency cost validation
- Undo functionality with 20-step history
- Mobile-optimized placement queries

### 2. **Fog/Pollution System**
- Dynamic fog part spawning (capped at 100 parts for performance)
- Bio-Scrubber clearing within 20-stud radius
- Automatic fog respawn after 30 seconds
- Object pooling for efficient memory usage

### 3. **Power Grid System**
- Automatic detection of touching power grids
- 1.2x currency multiplier when grids are connected
- Real-time multiplier updates
- Spatial tracking of all active grids

### 4. **Data Management**
- ProfileService-ready architecture
- Per-player currency tracking
- Building placement history
- Upgrade level system
- Neon skin unlocking
- Automatic 60-second autosave

### 5. **Neon Aesthetics**
- TweenService-based pulsing effects
- Cyan neon color interpolation (RGB: 0, 255, 200)
- Smooth sine-wave animation
- Mobile-optimized tweening

## 📁 Project Structure

```
ReplicatedStorage/
├── Modules/
│   ├── Constants.lua              # Centralized configuration
│   ├── GridPlacementSystem.lua    # Building placement logic
│   ├── FogPollutionSystem.lua     # Fog management
│   ├── PowerGridSystem.lua        # Multiplier detection
│   └── DataManager.lua            # Player data persistence

ServerScriptService/
└── GameInitializer.server.lua     # Main server initialization

StarterPlayer/StarterPlayerScripts/
└── NeonAestheticController.client.lua  # Client visual effects
```

## ⚡ Quick Start

1. **Create folder structure** in your Roblox game:
   - ReplicatedStorage/Modules
   - ServerScriptService
   - StarterPlayer/StarterPlayerScripts

2. **Copy all module scripts** into ReplicatedStorage/Modules

3. **Place GameInitializer.server.lua** in ServerScriptService

4. **Place NeonAestheticController.client.lua** in StarterPlayer/StarterPlayerScripts

5. **Create a `Plots` folder** in Workspace (or it will default to Workspace)

6. **Create building templates** in ReplicatedStorage/Templates
   - Example: BiouScrubber model with `BuildingCost` attribute set to 250

## 🛠️ Configuration

All game parameters are in `Constants.lua`:

```lua
-- Grid Settings
Constants.GRID.CELL_SIZE = 5          -- Studs per grid cell
Constants.GRID.GRID_WIDTH = 40        -- Plot width
Constants.GRID.GRID_HEIGHT = 40       -- Plot height

-- Bio-Scrubber Settings
Constants.BIO_SCRUBBER.COST = 250
Constants.BIO_SCRUBBER.FOG_CLEAR_RADIUS = 20

-- Power Grid Multiplier
Constants.POWER_GRID.MULTIPLIER_ACTIVE = 1.2

-- Currency Generation
Constants.CURRENCY.BASE_GENERATION = 1  -- Per second
```

## 📊 API Examples

### Placing a Building
```lua
local gridSystem = GlobalGameData.PlayerSystems[playerId].gridSystem
local template = ReplicatedStorage.Templates:FindFirstChild("BiouScrubber")
local success, message = gridSystem:PlaceBuilding(template, gridX, gridY, playerCurrency)
```

### Adding Currency
```lua
local newBalance = GlobalGameData.DataManager:AddCurrency(playerId, 100, multiplier)
```

### Enabling Neon Pulsing
```lua
local neonManager = require(ReplicatedStorage.Modules.NeonAestheticController)
neonManager:EnableNeonPulse(buildingPart)
```

## 🔧 Optimization Features

✅ **Mobile-Friendly**
- Object pooling for fog parts
- Capped particle counts (30 visible max)
- Sphere parts instead of complex models
- Efficient update loops

✅ **DRY Principles**
- Centralized Constants module
- Reusable helper functions
- Module-based architecture

✅ **Modern Luau**
- Task.wait() instead of wait()
- Type annotations
- `:Connect()` instead of `.connect()`
- Proper error handling

## 📝 Debug Mode

Toggle in Constants.lua:
```lua
Constants.DEBUG.ENABLE_LOGS = true      -- Console output
Constants.DEBUG.VISUAL_DEBUG = false     -- Show grid/collision
Constants.DEBUG.FORCE_OFFLINE_MODE = false  -- Skip DataStore
```

## 🎨 Customization

### Change Neon Color
```lua
Constants.NEON.NEON_COLOR = Color3.fromRGB(255, 0, 255)  -- Magenta
```

### Adjust Fog Respawn
```lua
Constants.FOG.FOG_RESPAWN_DELAY = 60  -- Seconds
```

### Modify Currency Multiplier
```lua
Constants.POWER_GRID.MULTIPLIER_ACTIVE = 1.5  -- 50% boost
```

## 🚀 Future Extensions

- [ ] ProfileService implementation for real DataStore integration
- [ ] Client-side placement preview
- [ ] UI for currency display and upgrades
- [ ] Audio effects for building placement
- [ ] Advanced power grid visualization
- [ ] Seasonal fog themes
- [ ] Leaderboard system

## 📄 License

Open-source framework for educational and commercial use.

---

**Built with ❤️ for the Roblox community**