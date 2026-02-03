-- PGB.lua - Main Script Logic
local Player = game:GetService("Players").LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()

-- Handlers for Cheat States
local States = {
    Autotime = false,
    Extended = false,
    Autoblock = false
}

-- Range Extender Function
local function UpdateExtender(enabled)
    local hasBall = Player:GetAttribute("HasBall")
    local active = enabled and not hasBall
    for _, name in ipairs({"RightHand", "LeftHand"}) do
        local part = Character:FindFirstChild(name)
        if part then
            part.Size = active and Vector3.new(3, 15, 3) or Vector3.new(0.69, 1.1, 0.74)
            part.Transparency = active and 0.5 or 1
        end
    end
end

-- UI Setup (Using Matcha API)
if ui and cheat then
    ui.NewTab("PGB", "PGB")
    ui.NewContainer("PGB", "Settings", "Settings", {autosize = true})
    ui.NewCheckbox("PGB", "Settings", "Autotime")
    ui.NewCheckbox("PGB", "Settings", "Range Extender")
    ui.NewCheckbox("PGB", "Settings", "Autoblock")
    ui.NewInputText("PGB", "Settings", "Keybind", "f")

    cheat.Register("onUpdate", function()
        -- Sync UI states to script
        States.Autotime = ui.GetValue("PGB", "Settings", "Autotime")
        States.Extended = ui.GetValue("PGB", "Settings", "Range Extender")
        States.Autoblock = ui.GetValue("PGB", "Settings", "Autoblock")

        -- Run Extender
        UpdateExtender(States.Extended)
        
        -- Run Autoblock logic
        if States.Autoblock then
            -- (Autoblock logic here)
        end
    end)
end
