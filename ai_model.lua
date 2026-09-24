-- ========================================================
-- AI MODEL MODULE
-- ========================================================
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local PathfindingService = game:GetService("PathfindingService")

local AIModel = {}
AIModel.__index = AIModel

local VOCABULARY = {
    ["jump"] = "ACT_JUMP", ["leap"] = "ACT_JUMP", ["hop"] = "ACT_JUMP",
    ["run"] = "ACT_EVADE", ["flee"] = "ACT_EVADE", ["evade"] = "ACT_EVADE", ["escape"] = "ACT_EVADE",
    ["follow"] = "ACT_FOLLOW", ["track"] = "ACT_FOLLOW", ["goto"] = "ACT_FOLLOW", ["pursue"] = "ACT_FOLLOW",
    ["scan"] = "ACT_SCAN", ["analyze"] = "ACT_SCAN", ["check"] = "ACT_SCAN", ["status"] = "ACT_SCAN",
    ["find"] = "ACT_LOCATE", ["locate"] = "ACT_LOCATE", ["search"] = "ACT_LOCATE",
    ["items"] = "ACT_ITEMS", ["inventory"] = "ACT_ITEMS", ["equip"] = "ACT_EQUIP",
    ["stop"] = "ACT_STOP", ["halt"] = "ACT_STOP", ["freeze"] = "ACT_STOP", ["idle"] = "ACT_STOP",
    ["player"] = "TGT_PLAYER", ["threat"] = "TGT_THREAT", ["danger"] = "TGT_THREAT",
    ["me"] = "TGT_SELF", ["gui"] = "TGT_GUI"
}

local IGNORE_WORDS = {
    ["the"]=true, ["a"]=true, ["an"]=true, ["to"]=true, ["and"]=true, ["or"]=true,
    ["is"]=true, ["are"]=true, ["please"]=true, ["can"]=true, ["you"]=true, ["me"]=true, ["my"]=true
}

function AIModel.new()
    local self = setmetatable({}, AIModel)
    self.LocalPlayer = Players.LocalPlayer
    self.State = "IDLE"
    self.Memory = {}
    return self
end

function AIModel:Tokenize(text)
    local tokens = {}
    local clean = string.lower(text):gsub("[%p%c]", "")
    for word in string.gmatch(clean, "%S+") do
        if not IGNORE_WORDS[word] then
            table.insert(tokens, word)
        end
    end
    return tokens
end

function AIModel:Parse(tokens)
    local action, target = "ACT_UNKNOWN", "TGT_NONE"
    local keywords = {}

    for _, token in ipairs(tokens) do
        local mapped = VOCABULARY[token]
        if mapped then
            if string.sub(mapped, 1, 3) == "ACT" then
                action = mapped
            elseif string.sub(mapped, 1, 3) == "TGT" then
                target = mapped
            end
        else
            table.insert(keywords, token)
        end
    end

    return action, target, keywords
end

function AIModel:ScanEnvironment()
    local env = {
        Position = Vector3.zero,
        Health = 100,
        MaxHealth = 100,
        WalkSpeed = 16,
        ObstacleAhead = false,
        HazardBelow = false,
        NearestPlayer = nil,
        AllPlayers = {},
        Inventory = {},
        MovingThreats = {},
        GuiLabels = {}
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

    -- Forward obstacle check
    local hitForward = Workspace:Raycast(hrp.Position, hrp.CFrame.LookVector * 15, rayParams)
    if hitForward then env.ObstacleAhead = true end

    -- Downward hazard check (killbrick/lava detection)
    local hitDown = Workspace:Raycast(hrp.Position, Vector3.new(0, -6, 0), rayParams)
    if hitDown and hitDown.Instance then
        local partName = string.lower(hitDown.Instance.Name)
        if partName:find("kill") or partName:find("lava") or partName:find("hazard") or hitDown.Instance:FindFirstChildOfClass("TouchTransmitter") then
            env.HazardBelow = true
        end
    end

    -- Nearest player scan
    local minDist = math.huge
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= self.LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local pPos = player.Character.HumanoidRootPart.Position
            local dist = (pPos - hrp.Position).Magnitude
            local pData = {Player = player, Name = player.Name, Distance = math.floor(dist), Position = pPos}
            table.insert(env.AllPlayers, pData)

            if dist < minDist then
                minDist = dist
                env.NearestPlayer = pData
            end
        end
    end

    -- Inventory tools scan
    local backpack = self.LocalPlayer and self.LocalPlayer:FindFirstChildOfClass("Backpack")
    if backpack then
        for _, item in ipairs(backpack:GetChildren()) do
            if item:IsA("Tool") then
                table.insert(env.Inventory, item.Name)
            end
        end
    end
    for _, item in ipairs(char:GetChildren()) do
        if item:IsA("Tool") then
            table.insert(env.Inventory, item.Name .. " (Equipped)")
        end
    end

    -- Fast-moving unanchored objects scan
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj:IsA("BasePart") and not obj.Anchored and obj.AssemblyLinearVelocity.Magnitude > 25 then
            local dist = (obj.Position - hrp.Position).Magnitude
            if dist < 120 then
                table.insert(env.MovingThreats, {Name = obj.Name, Speed = math.floor(obj.AssemblyLinearVelocity.Magnitude), Distance = math.floor(dist)})
            end
        end
    end

    return env
end

function AIModel:MoveToPoint(targetPos)
    local char = self.LocalPlayer and self.LocalPlayer.Character
    if not char then return end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not humanoid or not hrp then return end

    local path = PathfindingService:CreatePath({AgentRadius = 2, AgentHeight = 5, AgentCanJump = true})
    local success, _ = pcall(function() path:ComputeAsync(hrp.Position, targetPos) end)

    if success and path.Status == Enum.PathStatus.Success then
        local waypoints = path:GetWaypoints()
        task.spawn(function()
            for _, wp in ipairs(waypoints) do
                if wp.Action == Enum.PathWaypointAction.Jump then humanoid.Jump = true end
                humanoid:MoveTo(wp.Position)
                local arrived = humanoid.MoveToFinished:Wait()
                if not arrived then break end
            end
        end)
    else
        humanoid:MoveTo(targetPos)
    end
end

function AIModel:Process(prompt)
    local tokens = self:Tokenize(prompt)
    local action, target, keywords = self:Parse(tokens)
    local env = self:ScanEnvironment()

    table.insert(self.Memory, prompt)
    if #self.Memory > 20 then table.remove(self.Memory, 1) end

    local msg = ""
    local callback = nil

    if action == "ACT_JUMP" then
        msg = "Executing jump action."
        callback = function()
            local char = self.LocalPlayer and self.LocalPlayer.Character
            if char and char:FindFirstChildOfClass("Humanoid") then char.Humanoid.Jump = true end
        end

    elseif action == "ACT_EVADE" or target == "TGT_THREAT" or env.HazardBelow then
        self.State = "EVADING"
        if env.HazardBelow then
            msg = "Hazard detected directly below! Jumping and moving to safety."
        elseif #env.MovingThreats > 0 then
            msg = string.format("Threat '%s' moving at %d studs/s. Evading.", env.MovingThreats[1].Name, env.MovingThreats[1].Speed)
        else
            msg = "Executing evasion maneuver."
        end

        callback = function()
            local char = self.LocalPlayer and self.LocalPlayer.Character
            if char and char:FindFirstChildOfClass("Humanoid") then
                char.Humanoid.Jump = true
                if env.NearestPlayer then
                    local escapeDir = (env.Position - env.NearestPlayer.Position).Unit * 35
                    char.Humanoid:MoveTo(env.Position + escapeDir)
                end
            end
        end

    elseif action == "ACT_FOLLOW" then
        self.State = "FOLLOWING"
        local targetP = nil
        if #keywords > 0 then
            local search = keywords[1]
            for _, p in ipairs(env.AllPlayers) do
                if string.lower(p.Name):find(search) then targetP = p break end
            end
        elseif env.NearestPlayer then
            targetP = env.NearestPlayer
        end

        if targetP then
            msg = string.format("Following %s (%d studs away).", targetP.Name, targetP.Distance)
            callback = function() self:MoveToPoint(targetP.Position) end
        else
            msg = "Target player not found."
        end

    elseif action == "ACT_LOCATE" or target == "TGT_PLAYER" then
        if #keywords > 0 then
            local search = keywords[1]
            local matched = nil
            for _, p in ipairs(env.AllPlayers) do
                if string.lower(p.Name):find(search) then matched = p break end
            end

            if matched and matched.Player.Character then
                msg = string.format("Located player %s at %d studs. Highlighting target.", matched.Name, matched.Distance)
                callback = function()
                    local hl = Instance.new("Highlight")
                    hl.Adornee = matched.Player.Character
                    hl.FillColor = Color3.fromRGB(0, 255, 120)
                    hl.Parent = matched.Player.Character
                    task.delay(5, function() if hl then hl:Destroy() end end)
                end
            else
                msg = string.format("Player matching '%s' not found.", search)
            end
        elseif env.NearestPlayer then
            msg = string.format("Nearest player: %s (%d studs).", env.NearestPlayer.Name, env.NearestPlayer.Distance)
        else
            msg = "No players found in surrounding area."
        end

    elseif action == "ACT_SCAN" or target == "TGT_SELF" then
        msg = string.format("State: %s | Health: %d/%d | Pos: (%.1f, %.1f, %.1f) | Threats: %d",
            self.State, math.floor(env.Health), math.floor(env.MaxHealth), env.Position.X, env.Position.Y, env.Position.Z, #env.MovingThreats)

    elseif action == "ACT_ITEMS" then
        if #env.Inventory > 0 then
            msg = "Inventory: " .. table.concat(env.Inventory, ", ")
        else
            msg = "Inventory is empty."
        end

    elseif action == "ACT_EQUIP" and #keywords > 0 then
        local toolName = keywords[1]
        msg = "Attempting to equip item matching '" .. toolName .. "'."
        callback = function()
            local backpack = self.LocalPlayer and self.LocalPlayer:FindFirstChildOfClass("Backpack")
            local char = self.LocalPlayer and self.LocalPlayer.Character
            if backpack and char then
                for _, item in ipairs(backpack:GetChildren()) do
                    if item:IsA("Tool") and string.lower(item.Name):find(toolName) then
                        item.Parent = char
                        break
                    end
                end
            end
        end

    elseif action == "ACT_STOP" then
        self.State = "IDLE"
        msg = "Halt command executed."
        callback = function()
            local char = self.LocalPlayer and self.LocalPlayer.Character
            if char and char:FindFirstChildOfClass("Humanoid") then char.Humanoid:MoveTo(env.Position) end
        end

    else
        msg = string.format("Parsed prompt: '%s'. Current State: %s.", prompt, self.State)
    end

    if callback then pcall(callback) end
    return msg
end

return AIModel
