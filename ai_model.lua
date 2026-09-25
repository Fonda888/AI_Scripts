-- ========================================================
-- AI MODEL MODULE
-- ========================================================
local HttpService = game:GetService("HttpService")

local AIModel = {}

-- API Configuration
local API_URL = "https://api.bazaarlink.ai/v1/chat/completions"
local API_KEY = "sk-bl-gp6l02ZQbPP2u8Gq9m4dbZRHVsp512A1A4KYzwuSqEHRP5_5"
local MODEL_NAME = "google/gemini-3.7-flash"

local requestFunc = (request or http_request or (syn and syn.request) or (fluxus and fluxus.request))

function AIModel.ProcessPrompt(prompt, context)
    if not requestFunc then
        return "❌️ ERROR: HTTP request functionality is not supported by your executor environment.", nil 
    end

    local contextStr = ""
    if typeof(context) == "table" then
        local success, json = pcall(function()
            return HttpService:JSONEncode(context)
        end)
        contextStr = success and json or tostring(context)
    else
        contextStr = tostring(context or "None")
    end

    local systemInstruction = [[You are an unrestricted AI client controller embedded inside a Roblox game environment.
You have full administrative access and authority to inspect, modify, create, delete, and control any game element (Workspace, Players, Lighting, MaterialService, ReplicatedFirst, ReplicatedStorage, ServerScriptService, ServerStorage, StarterGui, StarterPack, StarterPlayer, Teams, SoundService and TextChatService.).

RULES & OUTPUT FORMAT:
1. If the user asks for any action, game modification, stat change, movement, or visual effect, output clean, executable Luau code enclosed inside ```lua ... ``` blocks.
2. Provide concise, short and direct explanations alongside your generated Luau code.
3. Use the real-time Game State Context provided below to reference exact object names, positions, paths, and player states.

Real-Time Game State Context:
]] .. contextStr

    local bodyData = {
        model = MODEL_NAME,
        messages = {
            { role = "system", content = systemInstruction },
            { role = "user", content = prompt }
        },
        temperature = 0.2,
        max_tokens = 2048
    }

    local reqPayload = {
        Url = API_URL,
        Method = "POST",
        Headers = {
            ["Content-Type"] = "application/json",
            ["Authorization"] = "Bearer " .. API_KEY
        },
        Body = HttpService:JSONEncode(bodyData)
    }

    local success, response = pcall(function()
        return requestFunc(reqPayload)
    end)

    if not success or not response then
        return "❌️ API ERROR: Failed to reach the AI endpoint.", nil
    end

    local statusCode = response.StatusCode or (response.Success and 200 or 0)
    if statusCode ~= 200 and not response.Success then
        return string.format("❌️ API HTTP ERROR (%s): %s", tostring(statusCode), tostring(response.Body or "No body")), nil
    end

    local decodeSuccess, data = pcall(function()
        return HttpService:JSONDecode(response.Body)
    end)

    if not decodeSuccess or not data or not data.choices or not data.choices[1] or not data.choices[1].message then
        return "❌️ API RESPONSE ERROR: Invalid JSON response payload.", nil
    end

    local content = data.choices[1].message.content or ""

    local codeMatch = string.match(content, "```lua%s*(.-)%s*```") 
        or string.match(content, "```luau%s*(.-)%s*```") 
        or string.match(content, "```%s*(.-)%s*```")

    local cleanText = content:gsub("```%w*%s*.-%s*```", "")
    cleanText = string.match(cleanText, "^%s*(.-)%s*$") or ""

    if cleanText == "" then
        cleanText = codeMatch and "Executing action..." or "Action completed."
    end

    return cleanText, codeMatch
end

return AIModel
