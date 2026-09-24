-- ========================================================
-- ENVIRONMENT CONTROLLER MODULE
-- ========================================================
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local PathfindingService = game:GetService("PathfindingService")

local EnvironmentController = {}
EnvironmentController.__index = EnvironmentController

function EnvironmentController.new()
    local self = setmetatable({}, EnvironmentController)
    self.LocalPlayer = Players.LocalPlayer
    return self
end

function EnvironmentController:Scan()
    local env = {
        Position = Vector3.zero,
        Health = 100,
        MaxHealth = 100,
        WalkSpeed = 16,
        ObstacleAhead = false,
        HazardBelow = false,
        NearestPlayer = nil,
        Players = {},
        Inventory = {},
        Threats = {}
    }

    local char = self.LocalPlayer and self.LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return env end

    local hrp = char.HumanoidRootPart
    local humanoid = char:FindFirstChildOfClass("Humanoid")

    env.Position = hrp.Position
    if humanoid then
        env.Health = humanoid.Health
        env.MaxHealth = humanoid.MaxHealth
        env.WalkSpeed = humanoid.WalkSpeed
    end

    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {char}
    rayParams.FilterType = Enum.RaycastFilterType.Exclude

    -- Forward check
    local hitForward = Workspace:Raycast(hrp.Position, hrp.CFrame.LookVector * 15, rayParams)
    if hitForward then env.ObstacleAhead = true end

    -- Downward hazard check
    local hitDown = Workspace:Raycast(hrp.Position, Vector3.new(0, -6, 0), rayParams)
    if hitDown and hitDown.Instance then
        local name = string.lower(hitDown.Instance.Name)
        if name:find("kill") or name:find("lava") or name:find("hazard") then
            env.HazardBelow = true
        end
    end

    -- Scan players
    local minDist = math.huge
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= self.LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local dist = (player.Character.HumanoidRootPart.Position - hrp.Position).Magnitude
            local pData = { Name = player.Name, Distance = math.floor(dist) }
            table.insert(env.Players, pData)

            if dist < minDist then
                minDist = dist
                env.NearestPlayer = pData
            end
        end
    end

    -- Inventory scan
    local backpack = self.LocalPlayer and self.LocalPlayer:FindFirstChildOfClass("Backpack")
    if backpack then
        for _, tool in ipairs(backpack:GetChildren()) do
            if tool:IsA("Tool") then table.insert(env.Inventory, tool.Name) end
        end
    end

    return env
end

function EnvironmentController:MoveTo(targetPos)
    local char = self.LocalPlayer and self.LocalPlayer.Character
    if not char then return end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not humanoid or not hrp then return end

    local path = PathfindingService:CreatePath({ AgentRadius = 2, AgentHeight = 5, AgentCanJump = true })
    local success = pcall(function() path:ComputeAsync(hrp.Position, targetPos) end)

    if success and path.Status == Enum.PathStatus.Success then
        for _, wp in ipairs(path:GetWaypoints()) do
            if wp.Action == Enum.PathWaypointAction.Jump then humanoid.Jump = true end
            humanoid:MoveTo(wp.Position)
            local arrived = humanoid.MoveToFinished:Wait()
            if not arrived then break end
        end
    else
        humanoid:MoveTo(targetPos)
    end
end

return EnvironmentController
