-- Handlers and Logic
local Player = game.LocalPlayer
if not Player then return end
local Character = Player.Character or Player.CharacterAdded:Wait()

local Stats = game:GetService("Stats")
local Network = Stats:FindFirstChild("Network")
local ServerStatsItem = Network:FindFirstChild("ServerStatsItem")
local Ping = ServerStatsItem and ServerStatsItem:FindFirstChild("Data Ping")

local Handlers = {
    Ping = {},
    Player = {
        States = {
            HasBall = false,
            IsShooting = false,
            Extended = false
        }
    },
    Input = {
        States = {
            Triggered = 0,
            Pending = false,
            Cooldown = 0
        }
    },
    Autoblock = {
        States = {
            Active = false,
            Blocked = 0
        }
    }
}

-- Matcha specific Ping reader via memory
Handlers.Ping.Get = function()
    if not Ping then return 0 end
    -- Reading the ping string from memory as per the original script's logic
    local rawPing = memory.Read("string", Ping.Address + 0xC8)
    if not rawPing then return 0 end
    
    local spacePos = string.find(rawPing, " ")
    if spacePos then
        local num = tonumber(string.sub(rawPing, 1, spacePos - 1))
        return num and math.floor(num) or 0
    end
    return 0
end

Handlers.Player.Update = function()
    local HasBallAttr = Player:GetAttribute("HasBall")
    Handlers.Player.States.HasBall = (HasBallAttr == true)

    if Handlers.Player.States.HasBall then
        local Action = Character:GetAttribute("Action")
        Handlers.Player.States.IsShooting = (Action == "Shooting" or Action == "Dunking")
    else
        Handlers.Player.States.IsShooting = false
    end
end

Handlers.Player.Extender = function()
    local RightHand = Character:FindFirstChild("RightHand")
    local LeftHand = Character:FindFirstChild("LeftHand")
    local Active = Handlers.Player.States.Extended and not Handlers.Player.States.HasBall

    if RightHand then
        RightHand.Size = Active and Vector3.new(3, 15, 3) or Vector3.new(0.69, 1.1, 0.74)
        RightHand.Transparency = 1
        RightHand.CanCollide = true
    end
    if LeftHand then
        LeftHand.Size = Active and Vector3.new(3, 15, 3) or Vector3.new(0.69, 1.1, 0.74)
        LeftHand.Transparency = 1
        LeftHand.CanCollide = true
    end
end

Handlers.Input.Release = function()
    local Time = utility.GetTickCount()
    if not Handlers.Input.States.Pending then
        Handlers.Input.States.Triggered = Time
        Handlers.Input.States.Pending = true
    end

    local currentPing = Handlers.Ping.Get()
    local Delay = 370
    if currentPing > 0 then
        Delay = math.max(0, Delay - math.floor(currentPing * 0.5))
    end

    if Handlers.Input.States.Pending and (Time - Handlers.Input.States.Triggered) >= Delay then
        keyboard.Release("e")
        keyboard.Release("space")
        Handlers.Input.States.Pending = false
        Handlers.Input.States.Cooldown = Time
    end
end

Handlers.Input.Update = function()
    local Time = utility.GetTickCount()
    if (Time - Handlers.Input.States.Cooldown) < 500 then return end

    if Handlers.Player.States.HasBall and Handlers.Player.States.IsShooting then
        Handlers.Input.Release()
    else
        Handlers.Input.States.Pending = false
    end
end

Handlers.Autoblock.GetClosestPlayer = function()
    local ClientRoot = Character:FindFirstChild("HumanoidRootPart")
    if not ClientRoot then return math.huge, nil end

    local Minimum = math.huge
    local Closest = nil

    for _, p in ipairs(game:GetService("Players"):GetPlayers()) do
        if p ~= Player and p.Character then
            local pHasBall = p:GetAttribute("HasBall")
            if pHasBall then
                local pRoot = p.Character:FindFirstChild("HumanoidRootPart")
                if pRoot then
                    local dist = (ClientRoot.Position - pRoot.Position).Magnitude
                    if dist < Minimum then
                        Minimum = dist
                        Closest = p
                    end
                end
            end
        end
    end
    return Minimum, Closest
end

Handlers.Autoblock.Update = function()
    local Time = utility.GetTickCount()
    if (Time - Handlers.Autoblock.States.Blocked) < 1000 then return end
    
    if not Handlers.Player.States.HasBall then
        local Distance, Closest = Handlers.Autoblock.GetClosestPlayer()
        if Closest and Closest.Character then
            local Action = Closest.Character:GetAttribute("Action")
            if (Action == "Shooting" or Action == "Dunking") and Distance <= 15 then
                keyboard.Click("lshift", 100)
                keyboard.Click("space", 100)
                Handlers.Autoblock.States.Blocked = Time
            end
        end
    end
end

-- UI Setup (Matcha Library)
local Tab = "PGB"
local Container = "Settings"

ui.NewTab(Tab, "PGB Script")
ui.NewContainer(Tab, Container, "Main Settings", {autosize = true})

ui.NewCheckbox(Tab, Container, "Autotime")
ui.NewCheckbox(Tab, Container, "Range Extender")
ui.NewCheckbox(Tab, Container, "Autoblock")
ui.NewInputText(Tab, Container, "Keybind", "f")

-- Main Loop
cheat.Register("onUpdate", function()
    -- Update Character if respawned
    if not Character or not Character.Parent then
        Character = Player.Character or Player.CharacterAdded:Wait()
    end

    -- Autotime Logic
    if ui.GetValue(Tab, Container, "Autotime") then
        Handlers.Player.Update()
        Handlers.Input.Update()
    end

    -- Range Extender Logic
    Handlers.Player.States.Extended = ui.GetValue(Tab, Container, "Range Extender")
    Handlers.Player.Extender()

    -- Autoblock Logic
    if ui.GetValue(Tab, Container, "Autoblock") then
        local Key = ui.GetValue(Tab, Container, "Keybind")
        if Key ~= "" and keyboard.IsPressed(Key) then
            Handlers.Autoblock.Update()
        end
    end
end)
