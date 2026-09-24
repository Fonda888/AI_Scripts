-- ========================================================
-- ENVIRONMENT CONTROLLER MODULE
-- ========================================================
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EnvironmentController = {}
local LocalPlayer = Players.LocalPlayer

local function safeGetAttributes(instance)
    local attrs = {}
    if instance and instance.GetAttributes then
        pcall(function()
            for k, v in pairs(instance:GetAttributes()) do
                attrs[k] = tostring(v)
            end
        end)
    end
    return attrs
end

function EnvironmentController.GetGameState()
    local camera = Workspace.CurrentCamera
    local mouse = LocalPlayer:GetMouse()
    local char = LocalPlayer and LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")

    -- 1. Detailed Local Player Info
    local playerState = {
        Name = LocalPlayer.Name,
        DisplayName = LocalPlayer.DisplayName,
        UserId = LocalPlayer.UserId,
        Team = LocalPlayer.Team and LocalPlayer.Team.Name or "None",
        Leaderstats = {},
        Attributes = safeGetAttributes(LocalPlayer),
        Position = hrp and tostring(hrp.Position) or "N/A",
        CFrame = hrp and tostring(hrp.CFrame) or "N/A",
        Velocity = hrp and tostring(hrp.AssemblyLinearVelocity) or "N/A",
        Health = humanoid and humanoid.Health or 100,
        MaxHealth = humanoid and humanoid.MaxHealth or 100,
        WalkSpeed = humanoid and humanoid.WalkSpeed or 16,
        JumpPower = humanoid and (humanoid.UseJumpPower and humanoid.JumpPower or humanoid.JumpHeight) or 50,
        HipHeight = humanoid and humanoid.HipHeight or 0,
        EquippedTool = (char and char:FindFirstChildOfClass("Tool")) and char:FindFirstChildOfClass("Tool").Name or "None"
    }

    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    if leaderstats then
        for _, v in ipairs(leaderstats:GetChildren()) do
            playerState.Leaderstats[v.Name] = v.Value
        end
    end

    -- 2. Mouse Target & Raycast Inspection
    local mouseTargetInfo = { Target = "None" }
    if mouse and mouse.Target then
        local t = mouse.Target
        mouseTargetInfo = {
            Name = t.Name,
            FullName = t:GetFullName(),
            ClassName = t.ClassName,
            Position = tostring(t.Position),
            Size = tostring(t.Size),
            Transparency = t.Transparency,
            CanCollide = t.CanCollide,
            ParentName = t.Parent and t.Parent.Name or "None"
        }
    end

    local raycastInfo = {
        ObstacleAhead = false,
        HazardBelow = false,
        FloorMaterial = "Air"
    }

    if hrp then
        local rayParams = RaycastParams.new()
        rayParams.FilterDescendantsInstances = {char}
        rayParams.FilterType = Enum.RaycastFilterType.Exclude

        local hitForward = Workspace:Raycast(hrp.Position, hrp.CFrame.LookVector * 15, rayParams)
        if hitForward then
            raycastInfo.ObstacleAhead = true
            raycastInfo.ObstacleName = hitForward.Instance.Name
        end

        local hitDown = Workspace:Raycast(hrp.Position, Vector3.new(0, -10, 0), rayParams)
        if hitDown and hitDown.Instance then
            raycastInfo.FloorMaterial = hitDown.Material.Name
            local lowerName = string.lower(hitDown.Instance.Name)
            if lowerName:find("kill") or lowerName:find("lava") or lowerName:find("hazard") or lowerName:find("death") then
                raycastInfo.HazardBelow = true
            end
        end
    end

    -- 3. World & Lighting
    local worldState = {
        Gravity = Workspace.Gravity,
        FallenPartsDestroyHeight = Workspace.FallenPartsDestroyHeight,
        TimeOfDay = Lighting.TimeOfDay,
        ClockTime = Lighting.ClockTime,
        Brightness = Lighting.Brightness,
        FogStart = Lighting.FogStart,
        FogEnd = Lighting.FogEnd,
        Ambient = tostring(Lighting.Ambient),
        OutdoorAmbient = tostring(Lighting.OutdoorAmbient)
    }

    -- 4. Workspace Top-Level Instance Tree Summary
    local workspaceTree = {}
    for _, item in ipairs(Workspace:GetChildren()) do
        if item ~= camera and item ~= char then
            table.insert(workspaceTree, { Name = item.Name, Class = item.ClassName })
            if #workspaceTree >= 30 then break end
        end
    end

    -- 5. Nearby Players & Entities
    local nearbyEntities = {}
    local myPos = hrp and hrp.Position or Vector3.zero
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local otherHrp = p.Character.HumanoidRootPart
            local dist = (otherHrp.Position - myPos).Magnitude
            if dist <= 250 then
                local otherHum = p.Character:FindFirstChildOfClass("Humanoid")
                table.insert(nearbyEntities, {
                    Name = p.Name,
                    DisplayName = p.DisplayName,
                    Team = p.Team and p.Team.Name or "None",
                    Distance = math.floor(dist),
                    Health = otherHum and otherHum.Health or 0,
                    MaxHealth = otherHum and otherHum.MaxHealth or 0,
                    Position = tostring(otherHrp.Position)
                })
            end
        end
    end

    -- 6. Inventory Items
    local inventory = {}
    local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
    if backpack then
        for _, item in ipairs(backpack:GetChildren()) do
            table.insert(inventory, { Name = item.Name, Class = item.ClassName })
        end
    end

    -- 7. Active UI Elements
    local activeUI = {}
    local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if playerGui then
        for _, gui in ipairs(playerGui:GetChildren()) do
            if gui:IsA("ScreenGui") then
                table.insert(activeUI, { Name = gui.Name, Enabled = gui.Enabled })
            end
        end
    end

    -- 8. ReplicatedStorage Structure Overview
    local replicatedStorageItems = {}
    for _, item in ipairs(ReplicatedStorage:GetChildren()) do
        table.insert(replicatedStorageItems, { Name = item.Name, Class = item.ClassName })
        if #replicatedStorageItems >= 20 then break end
    end

    return {
        Player = playerState,
        MouseTarget = mouseTargetInfo,
        Raycast = raycastInfo,
        Camera = {
            Position = camera and tostring(camera.CFrame.Position) or "N/A",
            LookVector = camera and tostring(camera.CFrame.LookVector) or "N/A",
            FieldOfView = camera and camera.FieldOfView or 70
        },
        World = worldState,
        WorkspaceOverview = workspaceTree,
        NearbyEntities = nearbyEntities,
        Inventory = inventory,
        ActiveUIElements = activeUI,
        ReplicatedStorageOverview = replicatedStorageItems
    }
end

function EnvironmentController.Execute(codeString)
    if not codeString or codeString == "" then 
        return true, nil 
    end

    -- Clean code markup
    local cleanCode = codeString:gsub("^```%w*%s*", ""):gsub("%s*```$", "")

    local compiledFunc, compileErr = loadstring(cleanCode)
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
