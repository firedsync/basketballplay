-- Handlers and State Management
local Player = game:GetService("Players").LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()

local Handlers = {
    Ping = {},
    Player = { States = { HasBall = false, IsShooting = false, Extended = false } },
    Input = { States = { Triggered = 0, Pending = false, Cooldown = 0 } },
    Autoblock = { States = { Active = false, Blocked = 0 } }
}

-- Safe Ping Reader
Handlers.Ping.Get = function()
    local stats = game:GetService("Stats")
    local ping = stats.Network.ServerStatsItem["Data Ping"]:GetValue()
    return math.floor(ping or 0)
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
            part.Transparency = Active and 0.5 or 0 -- Set to 0.5 so you can see if it's working
            part.CanCollide = true
        end
    end
end

Handlers.Autoblock.Update = function()
    local Time = tick()
    if Time - Handlers.Autoblock.States.Blocked < 1 then return end
    
    if not Handlers.Player.States.HasBall then
        local ClientRoot = Character:FindFirstChild("HumanoidRootPart")
        if not ClientRoot then return end

        for _, P in ipairs(game:GetService("Players"):GetPlayers()) do
            if P ~= Player and P.Character and P.Character:FindFirstChild("HumanoidRootPart") then
                local P_HasBall = P:GetAttribute("HasBall")
                local P_Action = P.Character:GetAttribute("Action")
                local Distance = (ClientRoot.Position - P.Character.HumanoidRootPart.Position).Magnitude
                
                if P_HasBall and (P_Action == "Shooting" or P_Action == "Dunking") and Distance <= 15 then
                    -- Automated Block Sequence
                    keypress(0xA0) -- Left Shift
                    keypress(0x20) -- Space
                    task.wait(0.1)
                    keyrelease(0xA0)
                    keyrelease(0x20)
                    Handlers.Autoblock.States.Blocked = Time
                    break
                end
            end
        end
    end
end

-- UI Initialization for Matcha
if ui then
    ui.NewTab("PGB", "PGB")
    ui.NewContainer("PGB", "Settings", "Settings", {autosize = true})
    ui.NewCheckbox("PGB", "Settings", "Autotime")
    ui.NewCheckbox("PGB", "Settings", "Range Extender")
    ui.NewCheckbox("PGB", "Settings", "Autoblock")
    ui.NewInputText("PGB", "Settings", "Keybind", "f")

    cheat.Register("onUpdate", function()
        if ui.GetValue("PGB", "Settings", "Autotime") then
            Handlers.Player.Update()
            -- Logic for release would go here
        end
        
        Handlers.Player.States.Extended = ui.GetValue("PGB", "Settings", "Range Extender")
        Handlers.Player.Extender()
        
        if ui.GetValue("PGB", "Settings", "Autoblock") then
            Handlers.Autoblock.Update()
        end
    end)
end
