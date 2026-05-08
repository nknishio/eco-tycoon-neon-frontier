--[[
	NeonAestheticController.client.lua
	Client-side script for managing neon pulsing effects on buildings
	Optimized for mobile with efficient tweening
]]

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Task = task

local Constants = require(ReplicatedStorage.Modules:WaitForChild("Constants"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local character = player.Character or player.CharacterAdded:Wait()

-- ========== NEON EFFECT MANAGER ==========

local NeonEffectManager = {}
NeonEffectManager.ActivePulses = {} -- { [part] = { tweenId, origColor } }

--- Apply neon pulsing effect to a part
function NeonEffectManager:EnableNeonPulse(part: Part)
	if not part or part.Parent == nil then return end
	
	-- Store original color if not already pulsing
	if not self.ActivePulses[part] then
		self.ActivePulses[part] = {
			originalColor = part.Color,
			tweenId = nil,
		}
		
		-- Start pulsing
		self:UpdatePulse(part)
	end
end

--- Update the pulsing effect for a part
function NeonEffectManager:UpdatePulse(part: Part)
	if not part or part.Parent == nil then
		self.ActivePulses[part] = nil
		return
	end
	
	local pulseData = self.ActivePulses[part]
	if not pulseData then return end
	
	-- Create brightness pulse tween
	local brightnessTween = TweenService:Create(
		part,
		TweenInfo.new(
			Constants.NEON.ACTIVE_TWEEN_DURATION / 2,
			Enum.EasingStyle.Sine,
			Enum.EasingDirection.InOut
		),
		{ Color = Constants.NEON.NEON_COLOR }
	)
	
	brightnessTween.Completed:Connect(function()
		if part.Parent == nil then
			self.ActivePulses[part] = nil
			return
		end
		
		-- Tween back to original
		local returnTween = TweenService:Create(
			part,
			TweenInfo.new(
				Constants.NEON.ACTIVE_TWEEN_DURATION / 2,
				Enum.EasingStyle.Sine,
				Enum.EasingDirection.InOut
			),
			{ Color = pulseData.originalColor }
		)
		
		returnTween.Completed:Connect(function()
			-- Repeat pulse
			if self.ActivePulses[part] and part.Parent ~= nil then
				self:UpdatePulse(part)
			end
		end)
		
		returnTween:Play()
	end)
	
	brightnessTween:Play()
end

--- Disable neon pulsing effect
function NeonEffectManager:DisableNeonPulse(part: Part)
	if not part then return end
	
	local pulseData = self.ActivePulses[part]
	if pulseData then
		part.Color = pulseData.originalColor
		self.ActivePulses[part] = nil
	end
end

--- Toggle neon effect for all children of a folder
function NeonEffectManager:ApplyNeonToFolder(folder: Folder, enabled: boolean)
	for _, part in ipairs(folder:GetDescendants()) do
		if part:IsA("BasePart") then
			if enabled then
				self:EnableNeonPulse(part)
			else
				self:DisableNeonPulse(part)
			end
		end
	end
end

-- ========== CLEANUP ==========

player.PlayerRemoving:Connect(function()
	for part, _ in pairs(NeonEffectManager.ActivePulses) do
		NeonEffectManager:DisableNeonPulse(part)
	end
	NeonEffectManager.ActivePulses = {}
end)

character.DescendantAdded:Connect(function(descendant)
	if descendant:IsA("BasePart") and descendant.Parent and descendant.Parent.Parent then
		-- Auto-enable neon for new buildings (optional)
		if descendant.Parent.Name:match("^Building") then
			NeonEffectManager:EnableNeonPulse(descendant)
		end
	end
end)

-- ========== EXPORT FOR USE ==========

return NeonEffectManager