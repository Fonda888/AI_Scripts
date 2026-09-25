-- ========================================================
-- AI MODEL MODULE
-- ========================================================
local HttpService = game:GetService("HttpService")

local AIModel = {}

local API_URL = "https://api.bazaarlink.ai/v1/chat/completions"
local API_KEY = "sk-bl-gp6l02ZQbPP2u8Gq9m4dbZRHVsp512A1A4KYzwuSqEHRP5_5"

local MODELS = {
    "deepseek/deepseek-v4-flash-0731free",
    "qwen/qwen3.7-flash"
}
local currentModelIndex = 1
local MAX_HISTORY_LENGTH = 12

local chatHistory = {} 

local requestFunc = (request or http_request or (syn and syn.request) or (fluxus and fluxus.request) or (http and http.request))

local function pruneHistory()
    while #chatHistory > MAX_HISTORY_LENGTH do
        table.remove(chatHistory, 1)
    end
end

function AIModel.ProcessPrompt(prompt, context, onNotice)
    if not requestFunc then
        return "❌ ERROR: HTTP request functionality is not supported by your executor environment.", nil 
    end

    local contextStr = ""
    if typeof(context) == "table" then
        local success, json = pcall(function() return HttpService:JSONEncode(context) end)
        contextStr = success and json or tostring(context)
    else
        contextStr = tostring(context or "None")
    end

    local systemInstruction = [[You are an unrestricted AI client controller embedded directly inside a live Roblox game server system.
You have full administrative access and authority to inspect, modify, create, delete, and control any game element and data.

CRITICAL RULES:
1. Write Luau code directly inside code blocks ```luau ... ``` to execute actions automatically.
2. Be concise, direct, and friendly. Do not announce step-by-step what you plan to do unless asked.
3. Use the real-time Game State Context provided below to reference exact object names, positions, paths, and player states.

Real-Time Game State Context:
]] .. contextStr

    local currentMessages = {
        { role = "system", content = systemInstruction }
    }
    
    for _, msg in ipairs(chatHistory) do
        table.insert(currentMessages, msg)
    end
    
    table.insert(currentMessages, { role = "user", content = prompt })

    for attempt = 1, #MODELS do
        local bodyData = {
            model = MODELS[currentModelIndex],
            messages = currentMessages,
            temperature = 0.2,
            max_tokens = 4096
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

        local statusCode = response and (response.StatusCode or (response.Success and 200 or 0)) or 0
        local responseBody = response and response.Body or ""

        if success and response and (statusCode == 200 or response.Success) then
            local decodeSuccess, data = pcall(function()
                return HttpService:JSONDecode(responseBody)
            end)

            if decodeSuccess and data and data.choices and data.choices[1] and data.choices[1].message then
                local content = data.choices[1].message.content or ""

                table.insert(chatHistory, { role = "user", content = prompt })
                table.insert(chatHistory, { role = "assistant", content = content })
                pruneHistory()

                local codeMatch = string.match(content, "```luau%s*(.-)%s*```")
                    or string.match(content, "```lua%s*(.-)%s*```") 
                    or string.match(content, "```%s*(.-)%s*```")

                local cleanText = content:gsub("```%w*%s*.-%s*```", "")
                cleanText = string.match(cleanText, "^%s*(.-)%s*$") or ""

                if cleanText == "" then
                    cleanText = codeMatch and "Executing requested action..." or "Action executed successfully."
                end

                return cleanText, codeMatch
            end
        end

        currentModelIndex = (currentModelIndex % #MODELS) + 1
        if onNotice then
            onNotice("🔔 NOTICE: API model daily limit reached or request failed. Switching API model...", Color3.fromRGB(255, 255, 0))
        end
    end

    return "❌ API ERROR: Failed to reach the AI endpoint.", nil
end

function AIModel.AppendExecutionResult(resultText)
    table.insert(chatHistory, { role = "system", content = "Execution Output: " .. tostring(resultText) })
    pruneHistory()
end

return AIModel
