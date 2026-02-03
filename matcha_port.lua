--// Matcha External UI Check
local Matcha = loadstring(game:HttpGet("https://raw.githubusercontent.com/matcha-latte/matcha/main/library.lua"))()

if not Matcha then
    print("Matcha UI library failed to load.")
    return
end

local Window = Matcha:CreateWindow({
    Title = "Matcha External | Auto Green",
    Theme = "Dark"
})

local Tab = Window:AddTab({ Title = "Main", Icon = "rbxassetid://4483345998" })
local Settings = Tab:AddSection({ Name = "Automation" })

--// Configuration
local Player = game.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Toggles = {
    AutoGreen = false,
    Extender = false,
    IsHoldingE = false
}

--// UI Elements
Settings:AddToggle({
    Name = "Auto Green",
    Default = false,
    Callback = function(v) Toggles.AutoGreen = v end
})

Settings:AddToggle({
    Name = "Range Extender",
    Default = false,
    Callback = function(v) Toggles.Extender = v end
})

--// Helper Functions
local function GetPing()
    local stats = game:GetService("Stats").Network:FindFirstChild("ServerStatsItem")
    local ping = stats and stats:FindFirstChild("Data Ping")
    return ping and ping:GetValue() or 100
end

--// Logic Loop
RunService.RenderStepped:Connect(function()
    -- Range Extender Logic
    local Right = Character:FindFirstChild("RightHand")
    local Left = Character:FindFirstChild("LeftHand")
    if Right and Left then
        local size = Toggles.Extender and Vector3.new(3, 15, 3) or Vector3.new(0.69, 1.1, 0.74)
        Right.Size = size
        Left.Size = size
        Right.Transparency = Toggles.Extender and 1 or 0
        Left.Transparency = Toggles.Extender and 1 or 0
    end

    -- Auto Green (Hold E Logic)
    -- Checking if E is held via UserInputService
    Toggles.IsHoldingE = UIS:IsKeyDown(Enum.KeyCode.E)

    if Toggles.AutoGreen and Toggles.IsHoldingE then
        local Ball = Player:GetAttribute("HasBall")
        local Action = Character:GetAttribute("Action")

        if Ball and (Action == "Shooting" or Action == "Dunking") then
            local Ping = GetPing()
            -- Formula: 370ms base - (Ping * 0.5)
            local Delay = (370 - (Ping * 0.5)) / 1000
            
            task.wait(math.max(0, Delay))
            
            -- External key simulation
            if typeof(keypress) == "function" then
                keyrelease(0x45) -- Force release the "E" key (0x45 is E)
            end
        end
    end
end)
