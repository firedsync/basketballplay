-- Matcha Library Initialization
local Matcha = loadstring(game:HttpGet("https://matcha-latte.gitbook.io/matcha"))() -- Placeholder for library load

local Player = game.LocalPlayer
if not Player then return end
local Character = Player.Character or Player.CharacterAdded:Wait()

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

-- Matcha-specific Ping Reader (Using the provided memory pattern)
Handlers.Ping.Get = function()
    local Stats = game:GetService("Stats")
    local Network = Stats:FindFirstChild("Network")
    local ServerStatsItem = Network and Network:FindFirstChild("ServerStatsItem")
    local PingObj = ServerStatsItem and ServerStatsItem:FindFirstChild("Data Ping")
    
    if not PingObj then return 0 end
    -- Memory reading logic preserved from your source
    local raw = memory.Read("string", PingObj.Address + 0xC8)
    local spacePos = string.find(raw, " ")
    if spacePos then
        local Number = tonumber(string.sub(raw, 1, spacePos - 1))
        return math.floor(Number or 0)
    end
    return 0
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
    local RightHand = Character:FindFirstChild("RightHand")
    local LeftHand = Character:FindFirstChild("LeftHand")
    local Active = Handlers.Player.States.Extended and not Handlers.Player.States.HasBall
    
    if RightHand then
        RightHand.Size = Active and Vector3.new(3, 15, 3) or Vector3.new(0.69334, 1.10182, 0.744331)
        RightHand.Transparency = 1
        RightHand.CanCollide = true
    end
    if LeftHand then
        LeftHand.Size = Active and Vector3.new(3, 15, 3) or Vector3.new(0.69334, 1.10182, 0.744331)
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

    local Ping = Handlers.Ping.Get()
    local Delay = 370
    if Ping > 0 then
        Delay = math.max(0, Delay - math.floor(Ping * 0.5))
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
    if Time - Handlers.Input.States.Cooldown < 500 then return end
    
    if Handlers.Player.States.HasBall and Handlers.Player.States.IsShooting then
        Handlers.Input.Release()
    else
        Handlers.Input.States.Pending = false
    end
end

Handlers.Autoblock.Update = function()
    local Time = utility.GetTickCount()
    if Time - Handlers.Autoblock.States.Blocked < 1000 then return end
    
    if not Handlers.Player.States.HasBall then
        local Players = game:GetService("Players")
        local ClientRoot = Character:FindFirstChild("HumanoidRootPart")
        if not ClientRoot then return end

        for _, P in ipairs(Players:GetPlayers()) do
            if P ~= Player and P.Character and P.Character:FindFirstChild("HumanoidRootPart") then
                local HasBall = P:GetAttribute("HasBall")
                local Action = P.Character:GetAttribute("Action")
                local Distance = (ClientRoot.Position - P.Character.HumanoidRootPart.Position).Magnitude
                
                if HasBall and (Action == "Shooting" or Action == "Dunking") and Distance <= 15 then
                    keyboard.Click("lshift", 100)
                    keyboard.Click("space", 100)
                    Handlers.Autoblock.States.Blocked = Time
                    break
                end
            end
        end
    end
end

-- Matcha UI Implementation
local TabName = "PGB"
local GroupName = "Settings"

ui.NewTab(TabName, "PGB")
ui.NewContainer(TabName, GroupName, "Settings", {autosize = true})

ui.NewCheckbox(TabName, GroupName, "Autotime")
ui.NewCheckbox(TabName, GroupName, "Range Extender")
ui.NewCheckbox(TabName, GroupName, "Autoblock")
ui.NewInputText(TabName, GroupName, "Keybind", "f")

-- Matcha Callback Hooks
cheat.Register("onUpdate", function()
    if ui.GetValue(TabName, GroupName, "Autotime") then
        Handlers.Player.Update()
        Handlers.Input.Update()
    end
    
    Handlers.Player.States.Extended = ui.GetValue(TabName, GroupName, "Range Extender")
    Handlers.Player.Extender()
    
    if ui.GetValue(TabName, GroupName, "Autoblock") then
        local Bind = ui.GetValue(TabName, GroupName, "Keybind")
        if Bind ~= "" and keyboard.IsPressed(Bind:lower()) then   
            Handlers.Autoblock.Update()
        end
    end
end)

-- Re-init on Place Change
cheat.Register("onNewPlace", function()
    Player = game.LocalPlayer
    Character = Player.Character or Player.CharacterAdded:Wait()
    
    -- Reset States
    Handlers.Input.States.Pending = false
    Handlers.Autoblock.States.Blocked = 0
end)
