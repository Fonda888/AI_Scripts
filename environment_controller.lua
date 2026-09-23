-- ========================================================
-- ENVIRONMENT CONTROLLER MODULE
-- ========================================================
local Players = game:GetService("Players")
local Env = {}

function Env.GetGameState()
    -- Gathers basic game context to feed to the AI so it knows what it is manipulating
    local context = "Players in server: " .. #Players:GetPlayers() .. ". "
    context = context .. "LocalPlayer: " .. Players.LocalPlayer.Name .. ". "
    
    local parts = 0
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") then parts = parts + 1 end
    end
    context = context .. "Workspace BaseParts: " .. parts .. "."
    
    return context
end

function Env.Execute(codeString)
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
