-- ========================================================
-- AI MODEL MODULE
-- ========================================================
local HttpService = game:GetService("HttpService")

local AIModel = {}

-- API Configuration
local API_URL = "https://api.bazaarlink.ai/v1/chat/completions"
local API_KEY = "sk-bl-gp6l02ZQbPP2u8Gq9m4dbZRHVsp512A1A4KYzwuSqEHRP5_5"
local MODEL_NAME = "deepseek/deepseek-v4-flash-0731free"

local requestFunc = (request or http_request or (syn and syn.request))

-- Expanded Offline Command Help Message
local OFFLINE_COMMANDS_LIST = "speed <num>, jump, fly, noclip, esp, godmode, heal, time <day/night/num>, gravity <num>, invisible, stop, help"

local VOCABULARY = {
    ["jump"] = "ACT_JUMP", ["leap"] = "ACT_JUMP", ["hop"] = "ACT_JUMP",
    ["speed"] = "ACT_SPEED", ["walkspeed"] = "ACT_SPEED", ["fast"] = "ACT_SPEED",
    ["fly"] = "ACT_FLY", ["flight"] = "ACT_FLY",
    ["noclip"] = "ACT_NOCLIP", ["clip"] = "ACT_NOCLIP",
    ["esp"] = "ACT_ESP", ["chams"] = "ACT_ESP", ["tracers"] = "ACT_ESP",
    ["god"] = "ACT_GODMODE", ["godmode"] = "ACT_GODMODE", ["invincible"] = "ACT_GODMODE",
    ["heal"] = "ACT_HEAL", ["health"] = "ACT_HEAL",
    ["time"] = "ACT_TIME", ["day"] = "ACT_TIME", ["night"] = "ACT_TIME",
    ["gravity"] = "ACT_GRAVITY", ["grav"] = "ACT_GRAVITY",
    ["invis"] = "ACT_INVIS", ["invisible"] = "ACT_INVIS",
    ["stop"] = "ACT_STOP", ["halt"] = "ACT_STOP", ["idle"] = "ACT_STOP",
    ["help"] = "ACT_HELP", ["cmds"] = "ACT_HELP", ["commands"] = "ACT_HELP"
}

local IGNORE_WORDS = {
    ["the"]=true, ["a"]=true, ["an"]=true, ["to"]=true, ["and"]=true, ["or"]=true,
    ["is"]=true, ["are"]=true, ["please"]=true, ["can"]=true, ["you"]=true, ["me"]=true, ["my"]=true, ["set"]=true, ["make"]=true
}

local function TryAPI(prompt, context)
    if not requestFunc then
        return nil, nil
    end

    local contextStr = typeof(context) == "table" and HttpService:JSONEncode(context) or tostring(context or "N/A")
    
    local systemInstruction = "You are a total control and inspection AI integrated into a Roblox game client.\n"
        .. "You have full authorization and access to inspect, modify, create, and delete any internal game element (Workspace, Players, Lighting, UserInterface, Scripts, Instances).\n"
        .. "If the user requests an action or visual/stat modification, output executable Luau code strictly inside ```lua ... ``` blocks.\n"
        .. "Provide direct and concise text responses alongside the code.\n"
        .. "Current Expanded Game Context: " .. contextStr

    local bodyData = {
        model = MODEL_NAME,
        messages = {
            { role = "system", content = systemInstruction },
            { role = "user", content = prompt }
        },
        temperature = 0.2
    }

    local success, response = pcall(function()
        return requestFunc({
            Url = API_URL,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json",
                ["Authorization"] = "Bearer " .. API_KEY
            },
            Body = HttpService:JSONEncode(bodyData)
        })
    end)

    if success and response then
        local statusCode = response.StatusCode or (response.Success and 200 or 0)
        
        if statusCode == 200 or response.Success then
            local decodeSuccess, data = pcall(function()
                return HttpService:JSONDecode(response.Body)
            end)

            if decodeSuccess and data and data.choices and data.choices[1] and data.choices[1].message then
                local content = data.choices[1].message.content or ""
                
                local codeMatch = string.match(content, "```lua\n(.-)\n```") 
                    or string.match(content, "```luau\n(.-)\n```") 
                    or string.match(content, "```(.-)```")

                local cleanText = content:gsub("```lua%s*(.-)%s*```", ""):gsub("```%s*(.-)%s*```", ""):match("^%s*(.-)%s*$")
                if cleanText == "" then cleanText = "Executing action..." end

                return cleanText, codeMatch
            end
        end
    end

    return nil, nil
end

local function ProcessNative(prompt)
    local tokens = {}
    local clean = string.lower(prompt):gsub("[%p%c]", "")
    for word in string.gmatch(clean, "%S+") do
        if not IGNORE_WORDS[word] then table.insert(tokens, word) end
    end

    local action = "ACT_UNKNOWN"
    local numbers = {}
    
    for _, token in ipairs(tokens) do
        local num = tonumber(token)
        if num then
            table.insert(numbers, num)
        elseif VOCABULARY[token] then
            action = VOCABULARY[token]
        end
    end

    -- Native Command Handlers
    if action == "ACT_JUMP" or string.find(clean, "jump") then
        return "[Native AI] Jump executed.", "local c = game:GetService('Players').LocalPlayer.Character if c and c:FindFirstChildOfClass('Humanoid') then c.Humanoid.Jump = true end"

    elseif action == "ACT_SPEED" or string.find(clean, "speed") then
        local targetSpeed = numbers[1] or 50
        return string.format("[Native AI] WalkSpeed set to %d.", targetSpeed), 
            string.format("local c = game:GetService('Players').LocalPlayer.Character if c and c:FindFirstChildOfClass('Humanoid') then c.Humanoid.WalkSpeed = %d end", targetSpeed)

    elseif action == "ACT_HEAL" or string.find(clean, "heal") then
        return "[Native AI] Health restored.", "local c = game:GetService('Players').LocalPlayer.Character if c and c:FindFirstChildOfClass('Humanoid') then c.Humanoid.Health = c.Humanoid.MaxHealth end"

    elseif action == "ACT_GODMODE" or string.find(clean, "god") then
        return "[Native AI] Godmode enabled.", "local c = game:GetService('Players').LocalPlayer.Character if c and c:FindFirstChildOfClass('Humanoid') then c.Humanoid.MaxHealth = math.huge c.Humanoid.Health = math.huge end"

    elseif action == "ACT_FLY" or string.find(clean, "fly") then
        return "[Native AI] Flight enabled.", [[
            local p = game:GetService('Players').LocalPlayer
            local c = p.Character
            if c and c:FindFirstChild("HumanoidRootPart") then
                local hrp = c.HumanoidRootPart
                local bv = hrp:FindFirstChild("NativeFly") or Instance.new("BodyVelocity")
                bv.Name = "NativeFly"
                bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
                bv.Velocity = hrp.CFrame.LookVector * 50 + Vector3.new(0, 10, 0)
                bv.Parent = hrp
            end
        ]]

    elseif action == "ACT_NOCLIP" or string.find(clean, "noclip") then
        return "[Native AI] Noclip enabled.", [[
            local c = game:GetService('Players').LocalPlayer.Character
            if c then
                for _, p in ipairs(c:GetDescendants()) do
                    if p:IsA("BasePart") then p.CanCollide = false end
                end
            end
        ]]

    elseif action == "ACT_ESP" or string.find(clean, "esp") then
        return "[Native AI] ESP highlights applied.", [[
            local Players = game:GetService("Players")
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= Players.LocalPlayer and p.Character then
                    local h = p.Character:FindFirstChild("NativeESP") or Instance.new("Highlight")
                    h.Name = "NativeESP"
                    h.FillColor = Color3.fromRGB(255, 0, 0)
                    h.OutlineColor = Color3.fromRGB(255, 255, 255)
                    h.Parent = p.Character
                end
            end
        ]]

    elseif action == "ACT_TIME" or string.find(clean, "time") then
        local hour = numbers[1] or (string.find(clean, "night") and 0 or 12)
        return string.format("[Native AI] Time set to %d:00.", hour), string.format("game:GetService('Lighting').ClockTime = %d", hour)

    elseif action == "ACT_GRAVITY" or string.find(clean, "grav") then
        local grav = numbers[1] or 196.2
        return string.format("[Native AI] Gravity adjusted to %d.", grav), string.format("workspace.Gravity = %d", grav)

    elseif action == "ACT_INVIS" or string.find(clean, "invis") then
        return "[Native AI] Character transparency adjusted.", [[
            local c = game:GetService('Players').LocalPlayer.Character
            if c then
                for _, p in ipairs(c:GetDescendants()) do
                    if p:IsA("BasePart") or p:IsA("Decal") then p.Transparency = 0.8 end
                end
            end
        ]]

    elseif action == "ACT_STOP" or string.find(clean, "stop") then
        return "[Native AI] Movement and forces halted.", [[
            local c = game:GetService('Players').LocalPlayer.Character
            if c then
                if c:FindFirstChild("HumanoidRootPart") and c.HumanoidRootPart:FindFirstChild("NativeFly") then
                    c.HumanoidRootPart.NativeFly:Destroy()
                end
                if c:FindFirstChildOfClass("Humanoid") then
                    c.Humanoid:MoveTo(c.HumanoidRootPart.Position)
                end
            end
        ]]
    end

    -- Return when API is unreachable and command is unmatched
    return string.format("AI API not connected; try using some of those commands: %s", OFFLINE_COMMANDS_LIST), nil
end

function AIModel.ProcessPrompt(prompt, context)
    -- Try API Connection First
    local textResponse, codeResponse = TryAPI(prompt, context)
    
    if textResponse then
        -- ONLINE: Pure API output without executing native command logic
        return textResponse, codeResponse
    end

    -- OFFLINE: Fallback to native commands with offline warning
    return ProcessNative(prompt)
end

return AIModel
