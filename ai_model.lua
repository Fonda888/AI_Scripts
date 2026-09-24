-- ========================================================
-- AI MODEL MODULE
-- ========================================================
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local PathfindingService = game:GetService("PathfindingService")

local AIModel = {}
local API_URL = "https://api.bazaarlink.ai/v1/chat/completions"
local API_KEY = "sk-bl-gp6l02ZQbPP2u8Gq9m4dbZRHVsp512A1A4KYzwuSqEHRP5_5"
local requestFunc = (request or http_request or (syn and syn.request))

-- Native Vocabulary for Offline Fallback
local VOCABULARY = {
    ["jump"] = "ACT_JUMP", ["leap"] = "ACT_JUMP", ["hop"] = "ACT_JUMP",
    ["speed"] = "ACT_SPEED", ["walkspeed"] = "ACT_SPEED",
    ["fly"] = "ACT_FLY",
    ["run"] = "ACT_EVADE", ["flee"] = "ACT_EVADE", ["evade"] = "ACT_EVADE",
    ["follow"] = "ACT_FOLLOW", ["track"] = "ACT_FOLLOW", ["goto"] = "ACT_FOLLOW",
    ["scan"] = "ACT_SCAN", ["analyze"] = "ACT_SCAN", ["status"] = "ACT_SCAN",
    ["stop"] = "ACT_STOP", ["halt"] = "ACT_STOP", ["idle"] = "ACT_STOP"
}

local IGNORE_WORDS = {
    ["the"]=true, ["a"]=true, ["an"]=true, ["to"]=true, ["and"]=true, ["or"]=true,
    ["is"]=true, ["are"]=true, ["please"]=true, ["can"]=true, ["you"]=true, ["me"]=true, ["my"]=true, ["set"]=true, ["make"]=true
}

-- ========================================================
-- EXTERNAL API PROCESSOR
-- ========================================================
local function TryAPI(prompt, context)
    if not requestFunc then return nil, nil end

    local contextStr = typeof(context) == "table" and HttpService:JSONEncode(context) or tostring(context or "N/A")
    local systemInstruction = "You are an AI integrated into a Roblox game environment.\n"
        .. "Analyze the prompt and context. If an action is required, output Luau executable code wrapped strictly in ```lua ... ``` blocks.\n"
        .. "Provide direct, concise text responses alongside any code.\n"
        .. "Current Context: " .. contextStr

    local bodyData = {
        model = "gpt-3.5-turbo",
        messages = {
            { role = "system", content = systemInstruction },
            { role = "user", content = prompt }
        },
        temperature = 0.3
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

    if success and response and (response.StatusCode == 200 or response.Success) then
        local decodeSuccess, data = pcall(function()
            return HttpService:JSONDecode(response.Body)
        end)

        if decodeSuccess and data and data.choices and data.choices[1] and data.choices[1].message then
            local content = data.choices[1].message.content or ""
            
            -- Extract code blocks if present
            local codeMatch = string.match(content, "```lua\n(.-)\n```") 
                or string.match(content, "```luau\n(.-)\n```") 
                or string.match(content, "```(.-)```")

            local cleanText = content:gsub("```lua%s*(.-)%s*```", ""):gsub("```%s*(.-)%s*```", ""):match("^%s*(.-)%s*$")
            if cleanText == "" then cleanText = "Executing action..." end

            return cleanText, codeMatch
        end
    end

    return nil, nil
end

-- ========================================================
-- NATIVE OFFLINE PROCESSOR
-- ========================================================
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

    if action == "ACT_JUMP" or string.find(clean, "jump") then
        return "[Native AI] Jumping.", "local char = game:GetService('Players').LocalPlayer.Character if char and char:FindFirstChildOfClass('Humanoid') then char.Humanoid.Jump = true end"

    elseif action == "ACT_SPEED" or string.find(clean, "speed") then
        local targetSpeed = numbers[1] or 50
        return string.format("[Native AI] WalkSpeed set to %d.", targetSpeed), 
            string.format("local char = game:GetService('Players').LocalPlayer.Character if char and char:FindFirstChildOfClass('Humanoid') then char.Humanoid.WalkSpeed = %d end", targetSpeed)

    elseif action == "ACT_STOP" or string.find(clean, "stop") then
        return "[Native AI] Movement halted.", "local char = game:GetService('Players').LocalPlayer.Character if char and char:FindFirstChildOfClass('Humanoid') then char.Humanoid:MoveTo(char.HumanoidRootPart.Position) end"

    else
        return string.format("[Native AI] Command parsed: '%s'. No native executable action matched.", prompt), nil
    end
end

-- ========================================================
-- MAIN EXPORT FUNCTION
-- ========================================================
function AIModel.ProcessPrompt(prompt, context)
    -- Step 1: Attempt External API
    local textResponse, codeResponse = TryAPI(prompt, context)
    if textResponse then
        return textResponse, codeResponse
    end

    -- Step 2: Fallback to Native Local Model
    print("[AI Model] External API unreachable. Operating on Native Model...")
    return ProcessNative(prompt)
end

return AIModel
