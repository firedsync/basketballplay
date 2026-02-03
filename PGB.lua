-- Handlers and State Management
local Player = game:GetService("Players").LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()

local Handlers = {
    Ping = {},
    Player = { States = { HasBall = false, IsShooting = false, Extended = false } },
    Input = { States = { Triggered = 0, Pending = false, Cooldown = 0 } },
    Autoblock = { States = { Active = false, Blocked = 0 } }
}

-- Safe Ping Reader (Uses Game Stats)
Handlers.Ping.Get = function()
    local stats = game:GetService("Stats")
    return math.floor(stats.Network.ServerStatsItem["Data Ping"]:GetValue())
end

Handlers.Player.Update = function()
    local HasBall = Player:GetAttribute("HasBall")
    Handlers.Player.States.HasBall = (HasBall == true)
    
    if Handlers.Player.States.HasBall then
        local Action = Character:GetAttribute("Action")
        Handlers.Player.States.IsShooting = (Action == "Shooting" or Action == "Dunking")
    else
        Handlers.Player.States.IsShooting = false
    end
end

Handlers.Player.Extender = function()
    local Active = Handlers.Player.States.Extended and not Handlers.Player.States.HasBall
    for _, limb in ipairs({"RightHand", "LeftHand"}) do
        local part = Character:FindFirstChild(limb)
        if part then
            part.Size = Active and Vector3.new(3, 15, 3) or Vector3.new(0.693, 1.101, 0.744)
            part.Transparency = 1
            part.CanCollide = true
        end
    end
end

Handlers.Input.Release = function()
    local Time = tick() -- Using tick() for universal compatibility
    if not Handlers.Input.States.Pending then
        Handlers.Input.States.Triggered = Time
        Handlers.Input.States.Pending = true
    end

    local Ping = Handlers.Ping.Get()
    local Delay = 0.37 -- Converted to seconds for tick()
    if Ping > 0 then
        Delay = math.max(0, Delay - ((Ping / 1000) * 0.5))
    end

    if Handlers.Input.States.Pending and (Time - Handlers.Input.States.Triggered) >= Delay then
        keypress(0x45) -- Key E
        keypress(0x20) -- Space
        task.wait(0.05)
        keyrelease(0x45)
        keyrelease(0x20)
        Handlers.Input.States.Pending = false
        Handlers.Input.States.Cooldown = Time
    end
end

-- UI Initialization (Matcha API)
-- Note: Ensure 'ui' and 'cheat' globals are provided by your executor/Matcha
if ui and cheat then
    ui.NewTab("PGB", "PGB")
    ui.NewContainer("PGB", "Settings", "Settings", {autosize = true})
    ui.NewCheckbox("PGB", "Settings", "Autotime")
    ui.NewCheckbox("PGB", "Settings", "Range Extender")
    ui.NewCheckbox("PGB", "Settings", "Autoblock")
    ui.NewInputText("PGB", "Settings", "Keybind", "f")

    cheat.Register("onUpdate", function()
        if ui.GetValue("PGB", "Settings", "Autotime") then
            Handlers.Player.Update()
            if Handlers.Player.States.HasBall and Handlers.Player.States.IsShooting then
                Handlers.Input.Release()
            end
        end
        
        Handlers.Player.States.Extended = ui.GetValue("PGB", "Settings", "Range Extender")
        Handlers.Player.Extender()
        
        if ui.GetValue("PGB", "Settings", "Autoblock") then
            local Bind = ui.GetValue("PGB", "Settings", "Keybind")
            -- Checking if key is pressed (Standard Executor function)
            if isrbxactive() and game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode[Bind:upper()]) then   
                Handlers.Autoblock.Update()
            end
        end
    end)
end
