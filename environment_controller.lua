-- ========================================================
-- ENVIRONMENT CONTROLLER MODULE
-- ========================================================
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EnvironmentController = {}
local LocalPlayer = Players.LocalPlayer

local function safeGetAttributes(instance)
    local attrs = {}
    if instance and pcall(function() return instance.GetAttributes end) and instance.GetAttributes then
        pcall(function()
            for k, v in pairs(instance:GetAttributes()) do
                if type(v) == "string" or type(v) == "number" or type(v) == "boolean" then
                    attrs[k] = tostring(v)
                end
            end
        end)
    end
    return attrs
end

function EnvironmentController.GetGameState()
    local success, state = pcall(function()
        local camera = Workspace.CurrentCamera
        local mouse = LocalPlayer:GetMouse()
        local char = LocalPlayer and LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")

        local playerState = {
            Name = LocalPlayer.Name,
            DisplayName = LocalPlayer.DisplayName,
            UserId = LocalPlayer.UserId,
            Team = LocalPlayer.Team and LocalPlayer.Team.Name or "None",
            Leaderstats = {},
            Attributes = safeGetAttributes(LocalPlayer),
            Position = hrp and string.format("%.1f, %.1f, %.1f", hrp.Position.X, hrp.Position.Y, hrp.Position.Z) or "N/A",
            Health = humanoid and math.floor(humanoid.Health) or 100,
            MaxHealth = humanoid and math.floor(humanoid.MaxHealth) or 100,
            WalkSpeed = humanoid and humanoid.WalkSpeed or 16,
            JumpPower = humanoid and (humanoid.UseJumpPower and humanoid.JumpPower or humanoid.JumpHeight) or 50,
            EquippedTool = (char and char:FindFirstChildOfClass("Tool")) and char:FindFirstChildOfClass("Tool").Name or "None"
        }

        local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
        if leaderstats then
            for _, v in ipairs(leaderstats:GetChildren()) do
                -- Check to ensure it's a value object
                if v:IsA("ValueBase") or v.Value ~= nil then
                    playerState.Leaderstats[v.Name] = tostring(v.Value)
                end
            end
        end

        local mouseTargetInfo = { Target = "None" }
        if mouse and mouse.Target then
            local t = mouse.Target
            mouseTargetInfo = {
                Name = t.Name,
                FullName = t:GetFullName(),
                ClassName = t.ClassName,
                Position = string.format("%.1f, %.1f, %.1f", t.Position.X, t.Position.Y, t.Position.Z),
                CanCollide = t.CanCollide,
                ParentName = t.Parent and t.Parent.Name or "None"
            }
        end

        local raycastInfo = { ObstacleAhead = false, HazardBelow = false, FloorMaterial = "Air" }
        if hrp then
            local rayParams = RaycastParams.new()
            rayParams.FilterDescendantsInstances = {char}
            rayParams.FilterType = Enum.RaycastFilterType.Exclude

            pcall(function()
                local lookVec = hrp.CFrame.LookVector
                if lookVec.Magnitude > 0 then
                    local hitForward = Workspace:Raycast(hrp.Position, lookVec * 15, rayParams)
                    if hitForward then
                        raycastInfo.ObstacleAhead = true
                        raycastInfo.ObstacleName = hitForward.Instance.Name
                    end
                end

                local hitDown = Workspace:Raycast(hrp.Position, Vector3.new(0, -10, 0), rayParams)
                if hitDown and hitDown.Instance then
                    raycastInfo.FloorMaterial = hitDown.Material.Name
                    local lowerName = string.lower(hitDown.Instance.Name)
                    if lowerName:find("kill") or lowerName:find("lava") or lowerName:find("hazard") or lowerName:find("death") then
                        raycastInfo.HazardBelow = true
                    end
                end
            end)
        end

        local workspaceTree = {}
        for _, item in ipairs(Workspace:GetChildren()) do
            if item ~= camera and item ~= char then
                table.insert(workspaceTree, { Name = item.Name, Class = item.ClassName })
                if #workspaceTree >= 20 then break end
            end
        end

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
                        Health = otherHum and math.floor(otherHum.Health) or 0,
                        Position = string.format("%.1f, %.1f, %.1f", otherHrp.Position.X, otherHrp.Position.Y, otherHrp.Position.Z)
                    })
                end
            end
        end

        local inventory = {}
        local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
        if backpack then
            for _, item in ipairs(backpack:GetChildren()) do
                table.insert(inventory, { Name = item.Name, Class = item.ClassName })
            end
        end

        return {
            Player = playerState,
            MouseTarget = mouseTargetInfo,
            Raycast = raycastInfo,
            World = { Gravity = Workspace.Gravity, TimeOfDay = Lighting.TimeOfDay, ClockTime = Lighting.ClockTime },
            WorkspaceOverview = workspaceTree,
            NearbyEntities = nearbyEntities,
            Inventory = inventory
        }
    end)

    return success and state or { Error = "Failed to retrieve game state: " .. tostring(state) }
end

function EnvironmentController.Execute(codeString)
    if not codeString or codeString == "" then 
        return true, "No code to execute." 
    end

    local cleanCode = codeString:gsub("^```%w*%s*", ""):gsub("%s*```$", "")
    local loadFunc = loadstring or (getgenv and getgenv().loadstring)
    
    if not loadFunc then
        return false, "EXECUTION ERROR: No loadstring function available in current environment."
    end

    local compiledFunc, compileErr = loadFunc(cleanCode)
    if not compiledFunc then
        return false, "COMPILATION ERROR: " .. tostring(compileErr)
    end

    local success, execErr = pcall(function() return compiledFunc() end)
    if not success then
        return false, "RUNTIME ERROR: " .. tostring(execErr)
    end

    return true, "Executed successfully."
end

return EnvironmentController
