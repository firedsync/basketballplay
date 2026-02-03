-- MATCHA-STYLE AUTO GREEN SCRIPT (SAFE VERSION)
-- Author: Your Name
-- Works entirely in Roblox Studio

-- ===== GLOBAL SETTINGS =====
getgenv = getgenv or function() return _G end -- mimic Matcha global
getgenv().AutoGreenEnabled = false -- default OFF

-- ===== UI SETUP =====
local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AutoGreenUI"
screenGui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 200, 0, 50)
frame.Position = UDim2.new(0, 20, 0, 20)
frame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
frame.Parent = screenGui

local button = Instance.new("TextButton")
button.Size = UDim2.new(1, -10, 1, -10)
button.Position = UDim2.new(0, 5, 0, 5)
button.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
button.TextColor3 = Color3.fromRGB(255, 255, 255)
button.Text = "Auto Green: OFF"
button.Parent = frame

-- Toggle button
button.MouseButton1Click:Connect(function()
	getgenv().AutoGreenEnabled = not getgenv().AutoGreenEnabled
	if getgenv().AutoGreenEnabled then
		button.Text = "Auto Green: ON"
		button.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
	else
		button.Text = "Auto Green: OFF"
		button.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
	end
end)

-- ===== AUTO GREEN FUNCTION =====
-- Call this function when the player shoots
function AutoGreen(shotData)
	if getgenv().AutoGreenEnabled then
		-- Override values for perfect shot
		shotData.Timing = 1       -- perfect timing
		shotData.Accuracy = 1     -- 100% accuracy
		shotData.Power = 1        -- optional: max power
		print("[AutoGreen] Perfect shot applied!")
	end
	return shotData
end

-- ===== EXAMPLE HOOK =====
-- Replace this with your actual shot release logic
-- For demonstration only
local UserInputService = game:GetService("UserInputService")
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		-- Example shot data
		local shot = {
			Timing = math.random(),
			Accuracy = math.random(),
			Power = math.random()
		}

		-- Apply AutoGreen
		shot = AutoGreen(shot)
		print("Shot Data:", shot.Timing, shot.Accuracy, shot.Power)
	end
end)
