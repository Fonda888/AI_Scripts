-- ========================================================
-- ENVIRONMENT CONTROLLER MODULE
-- ========================================================
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

local EnvironmentController = {}
local LocalPlayer = Players.LocalPlayer

function EnvironmentController.GetGameState()
    local camera = Workspace.CurrentCamera
    local mouse = LocalPlayer:GetMouse()

    local state = {
        Player = {
            Name = LocalPlayer.Name,
            UserId = LocalPlayer.UserId,
            Team = LocalPlayer.Team and LocalPlayer.Team.Name or "None",
            Leaderstats = {},
            Position = Vector3.zero,
            CFrame = "N/A",
            Health = 100,
            MaxHealth = 100,
            WalkSpeed = 16,
            JumpPower = 50,
            HipHeight = 0,
            EquippedTool = "None"
        },
        Camera = {
            Position = camera and camera.CFrame.Position or Vector3.zero,
            LookVector = camera and camera.CFrame.LookVector or Vector3.zero,
            FieldOfView = camera and camera.FieldOfView or 70
        },
        World = {
            Gravity = Workspace.Gravity,
            TimeOfDay = Lighting.TimeOfDay,
            ClockTime = Lighting.ClockTime,
            Brightness = Lighting.Brightness,
            FogEnd = Lighting.FogEnd,
            Ambient = tostring(Lighting.Ambient)
        },
        Raycast = {
            ObstacleAhead = false,
            HazardBelow = false,
            TargetPart = mouse and mouse.Target and mouse.Target:GetFullName() or "None"
        },
        NearbyEntities = {},
        Inventory = {},
        ActiveUIElements = {}
    }

    -- 1. Character & Player Stats
    local char = LocalPlayer and LocalPlayer.Character
    if char then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        local tool = char:FindFirstChildOfClass("Tool")

        if hrp then
            state.Player.Position = hrp.Position
            state.Player.CFrame = tostring(hrp.CFrame)

            local rayParams = RaycastParams.new()
            rayParams.FilterDescendantsInstances = {char}
            rayParams.FilterType = Enum.RaycastFilterType.Exclude

            local hitForward = Workspace:Raycast(hrp.Position, hrp.CFrame.LookVector * 15, rayParams)
            if hitForward then state.Raycast.ObstacleAhead = true end

            local hitDown = Workspace:Raycast(hrp.Position, Vector3.new(0, -6, 0), rayParams)
            if hitDown and hitDown.Instance then
                local name = string.lower(hitDown.Instance.Name)
                if name:find("kill") or name:find("lava") or name:find("hazard") then
                    state.Raycast.HazardBelow = true
                end
            end
        end

        if humanoid then
            state.Player.Health = humanoid.Health
            state.Player.MaxHealth = humanoid.MaxHealth
            state.Player.WalkSpeed = humanoid.WalkSpeed
            state.Player.JumpPower = humanoid.JumpPower
            state.Player.HipHeight = humanoid.HipHeight
        end

        if tool then
            state.Player.EquippedTool = tool.Name
        end
    end

    -- Leaderstats Inspection
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    if leaderstats then
        for _, v in ipairs(leaderstats:GetChildren()) do
            state.Player.Leaderstats[v.Name] = v.Value
        end
    end

    -- 2. Nearby Entities
    if char and char:FindFirstChild("HumanoidRootPart") then
        local myPos = char.HumanoidRootPart.Position
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local otherHrp = p.Character.HumanoidRootPart
                local dist = (otherHrp.Position - myPos).Magnitude
                if dist <= 150 then
                    local otherHum = p.Character:FindFirstChildOfClass("Humanoid")
                    table.insert(state.NearbyEntities, {
                        Name = p.Name,
                        Distance = math.floor(dist),
                        Health = otherHum and otherHum.Health or 0,
                        Position = otherHrp.Position
                    })
                end
            end
        end
    end

    -- 3. Inventory Items
    local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
    if backpack then
        for _, item in ipairs(backpack:GetChildren()) do
            table.insert(state.Inventory, { Name = item.Name, Class = item.ClassName })
        end
    end

    -- 4. Visual UI Elements Inspection
    local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if playerGui then
        for _, gui in ipairs(playerGui:GetChildren()) do
            if gui:IsA("ScreenGui") and gui.Enabled then
                table.insert(state.ActiveUIElements, gui.Name)
            end
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
