-- ========================================================
-- ENVIRONMENT CONTROLLER MODULE
-- ========================================================
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Env = {}

function Env.GetGameState()
    local localPlayer = Players.LocalPlayer
    local context = "Players in server: " .. #Players:GetPlayers() .. ". "
    
    if localPlayer then
        context = context .. "LocalPlayer: " .. localPlayer.Name .. ". "
        local char = localPlayer.Character
        if char then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            
            if hrp then
                context = context .. string.format("Pos: (%.1f, %.1f, %.1f). ", hrp.Position.X, hrp.Position.Y, hrp.Position.Z)
            end
            if humanoid then
                context = context .. string.format("Health: %d/%d. WalkSpeed: %d. ", math.floor(humanoid.Health), math.floor(humanoid.MaxHealth), humanoid.WalkSpeed)
            end
        end
    end

    local parts = 0
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            parts = parts + 1
        end
    end
    context = context .. "Workspace BaseParts: " .. parts .. "."

    return context
end

function Env.Execute(codeString)
    if not codeString or codeString == "" then
        return false, "No code provided to execute."
    end

    local func, compileError = loadstring(codeString)
    if func then
        local success, runtimeError = pcall(func)
        if success then
            return true, "Execution complete."
        else
            return false, "Runtime Error: " .. tostring(runtimeError)
        end
    else
        return false, "Compilation Error: " .. tostring(compileError)
    end
end

return Env
