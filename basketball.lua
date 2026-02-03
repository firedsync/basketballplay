-- Initialize Matcha Library
local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Matcha-Latte/Matcha/main/Library.lua"))()

local Player = game.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()

local Stats = game:GetService("Stats")
local Network = Stats:FindFirstChild("Network")
local ServerStatsItem = Network:FindFirstChild("ServerStatsItem")
local Ping = ServerStatsItem and ServerStatsItem:FindFirstChild("Data Ping")

-- Handlers
local Handlers = {
    Ping = {},
    Player = { States = { HasBall = false, IsShooting = false, Extended = false } },
    Input = { States = { Triggered = 0, Pending = false, Cooldown = 0 } },
    Autoblock = { States = { Active = false, Blocked = 0 } }
}

-- Logic Functions
Handlers.Ping.Get = function()
    if not Ping then return 0 end
    local rawPing = memory.Read("string", Ping.Address + 0xC8)
    local spacePos = string.find(rawPing or "", " ")
    if spacePos then
        return math.floor(tonumber(string.sub(rawPing, 1, spacePos - 1)) or 0)
    end
    return 0
end

Handlers.Player.Update = function()
    local HasBall = Player:GetAttribute("HasBall")
    Handlers.Player.States.HasBall = HasBall == true
    if Handlers.Player.States.HasBall then
        local Action = Character:GetAttribute("Action")
        Handlers.Player.States.IsShooting = (Action == "Shooting" or Action == "Dunking")
    else
        Handlers.Player.States.IsShooting = false
    end
end

Handlers.Player.Extender = function()
    local Active = Handlers.Player.States.Extended and not Handlers.Player.States.HasBall
    for _, handName in pairs({"RightHand", "LeftHand"}) do
        local hand = Character:FindFirstChild(handName)
        if hand then
            hand.Size = Active and Vector3.new(3, 15, 3) or Vector3.new(0.69, 1.1, 0.74)
            hand.Transparency = 1
            hand.CanCollide = true
        end
    end
end

Handlers.Input.Release = function()
    local Time = utility.GetTickCount()
    if not Handlers.Input.States.Pending then
        Handlers.Input.States.Triggered = Time
        Handlers.Input.States.Pending = true
    end
    local Delay = 370 - math.floor(Handlers.Ping.Get() * 0.5)
    if Handlers.Input.States.Pending and (Time - Handlers.Input.States.Triggered) >= math.max(0, Delay) then
        keyboard.Release("e")
        keyboard.Release("space")
        Handlers.Input.States.Pending = false
        Handlers.Input.States.Cooldown = Time
    end
end

-- UI Setup
local Window = ui.NewWindow("Matcha | PGB Script", {size = Vector2.new(500, 400)})
local Tab = Window.NewTab("Main")
local Section = Tab.NewSection("Settings")

local AutoTime = Section.NewCheckbox("Autotime", false)
local Extender = Section.NewCheckbox("Range Extender", false)
local AutoBlock = Section.NewCheckbox("Autoblock", false)
local KeyInput = Section.NewInput("Block Key", "f")

-- Loop
cheat.Register("onUpdate", function()
    if not Character or not Character.Parent then Character = Player.Character end
    
    if AutoTime.GetValue() then
        Handlers.Player.Update()
        if Handlers.Player.States.HasBall and Handlers.Player.States.IsShooting then
            Handlers.Input.Release()
        end
    end

    Handlers.Player.States.Extended = Extender.GetValue()
    Handlers.Player.Extender()

    if AutoBlock.GetValue() and keyboard.IsPressed(KeyInput.GetValue()) then
        local Time = utility.GetTickCount()
        if (Time - Handlers.Autoblock.States.Blocked) > 1000 then
            -- Closest Player Logic
            local Min = 15
            for _, p in pairs(game.Players:GetPlayers()) do
                if p ~= Player and p.Character and p:GetAttribute("HasBall") then
                    local dist = (Character.HumanoidRootPart.Position - p.Character.HumanoidRootPart.Position).Magnitude
                    if dist < Min then
                        keyboard.Click("lshift", 100)
                        keyboard.Click("space", 100)
                        Handlers.Autoblock.States.Blocked = Time
                    end
                end
            end
        end
    end
end)
