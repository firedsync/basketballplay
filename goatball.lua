--// Matcha UI Initialization
local Matcha = loadstring(game:HttpGet("https://raw.githubusercontent.com/matcha-latte/matcha/main/library.lua"))()
local Window = Matcha:CreateWindow({
    Title = "Matcha Latte | Auto Green",
    Theme = "Dark"
})

local Tab = Window:AddTab({ Title = "Main", Icon = "rbxassetid://4483345998" })
local Settings = Tab:AddSection({ Name = "Settings" })

--// Variables & States
local Player = game.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Config = {
    AutoGreen = false,
    RangeExtender = false,
    HoldingE = false
}

--// UI Components
Settings:AddToggle({
    Name = "Auto Green (Hold E)",
    Default = false,
    Callback = function(Value)
        Config.AutoGreen = Value
    end
})

Settings:AddToggle({
    Name = "Range Extender",
    Default = false,
    Callback = function(Value)
        Config.RangeExtender = Value
    end
})

--// Logic Handlers
local function GetPing()
    return game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()
end

local function UpdateExtender()
    local RightHand = Character:FindFirstChild("RightHand")
    local LeftHand = Character:FindFirstChild("LeftHand")
    
    if RightHand and LeftHand then
        local Size = Config.RangeExtender and Vector3.new(3, 15, 3) or Vector3.new(0.69, 1.1, 0.74)
        RightHand.Size = Size
        LeftHand.Size = Size
        RightHand.Transparency = Config.RangeExtender and 1 or 0
        LeftHand.Transparency = Config.RangeExtender and 1 or 0
    end
end

--// Auto Green Logic (Hold E version)
UserInputService.InputBegan:Connect(function(input, processed)
    if not processed and input.KeyCode == Enum.KeyCode.E then
        Config.HoldingE = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.E then
        Config.HoldingE = false
    end
end)

RunService.RenderStepped:Connect(function()
    if Config.AutoGreen and Config.HoldingE then
        local HasBall = Player:GetAttribute("HasBall")
        local Action = Character:GetAttribute("Action")
        
        -- Check if shooting
        if HasBall and (Action == "Shooting" or Action == "Dunking") then
            local Ping = GetPing()
            local Delay = 0.37 - (Ping * 0.0005) -- Adjusted for seconds (370ms base)
            
            task.wait(math.max(0, Delay))
            keypress(0x45) -- Keycode for E
            task.wait(0.05)
            keyrelease(0x45)
        end
    end
    
    UpdateExtender()
end)
