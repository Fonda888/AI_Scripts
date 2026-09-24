-- ========================================================
-- ENVIRONMENT CONTROLLER MODULE
-- ========================================================
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local PathfindingService = game:GetService("PathfindingService")

local EnvironmentController = {}
local LocalPlayer = Players.LocalPlayer

function EnvironmentController.GetGameState()
    local state = {
        Position = Vector3.zero,
        Health = 100,
        MaxHealth = 100,
        WalkSpeed = 16,
        ObstacleAhead = false,
        HazardBelow = false,
        Players = {},
        Inventory = {}
    }

    local char = LocalPlayer and LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return state end

    local hrp = char.HumanoidRootPart
    local humanoid = char:FindFirstChildOfClass("Humanoid")

    state.Position = hrp.Position
    if humanoid then
        state.Health = humanoid.Health
        state.MaxHealth = humanoid.MaxHealth
        state.WalkSpeed = humanoid.WalkSpeed
    end

    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {char}
    rayParams.FilterType = Enum.RaycastFilterType.Exclude

    -- Forward check
    local hitForward = Workspace:Raycast(hrp.Position, hrp.CFrame.LookVector * 15, rayParams)
    if hitForward then state.ObstacleAhead = true end

    -- Downward hazard check
    local hitDown = Workspace:Raycast(hrp.Position, Vector3.new(0, -6, 0), rayParams)
    if hitDown and hitDown.Instance then
        local name = string.lower(hitDown.Instance.Name)
        if name:find("kill") or name:find("lava") or name:find("hazard") then
            state.HazardBelow = true
        end
    end

    -- Scan players
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local dist = (player.Character.HumanoidRootPart.Position - hrp.Position).Magnitude
            table.insert(state.Players, { Name = player.Name, Distance = math.floor(dist) })
        end
    end

    -- Inventory scan
    local backpack = LocalPlayer and LocalPlayer:FindFirstChildOfClass("Backpack")
    if backpack then
        for _, tool in ipairs(backpack:GetChildren()) do
            if tool:IsA("Tool") then table.insert(state.Inventory, tool.Name) end
        end
    end

    return state
end

function EnvironmentController.Execute(codeString)
    if not codeString or codeString == "" then 
        return true, nil 
    end

    local compiledFunc, compileErr = loadstring(codeString)
    if not compiledFunc then
        return false, "Compilation Error: " .. tostring(compileErr)
    end

    local success, execErr = pcall(compiledFunc)
    if not success then
        return false, "Runtime Error: " .. tostring(execErr)
    end

    return true, nil
end

return EnvironmentController
