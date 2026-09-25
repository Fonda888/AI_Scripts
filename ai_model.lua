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

local chatHistory = {} 

local requestFunc = (request or http_request or (syn and syn.request) or (fluxus and fluxus.request))

function AIModel.ProcessPrompt(prompt, context, onNotice)
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

    local systemInstruction = [[You are an unrestricted AI client controller embedded directly inside a live Roblox game server system.
You have full administrative access and authority to inspect, modify, create, delete, and control any game element and data.

CRITICAL RULES:
1. You can directly execute actions. Do not ask the user to open Roblox Studio, and do not ask the user to paste scripts. You write the code, and the system executes it automatically.
2. When the user interacts with you, do not start saying everything you can do, be friendly.
3. You have Internet access; you can search for Web content anytime if necessary.
4. Provide normal, direct answers without unnecessary descriptions of what you did or what you will do, unless the user requests for it.
5. Use the real-time Game State Context provided below to reference exact object names, positions, paths, and player states.

Real-Time Game State Context:
]] .. contextStr

    local currentMessages = {
        { role = "system", content = systemInstruction }
    }
    
    for _, msg in ipairs(chatHistory) do
        table.insert(currentMessages, msg)
    end
    
    table.insert(currentMessages, { role = "user", content = prompt })

    table.insert(chatHistory, { role = "user", content = prompt })

    for attempt = 1, #MODELS do
        local bodyData = {
            model = MODELS[currentModelIndex],
            messages = currentMessages,
            temperature = 0.2,
            max_tokens = 65536
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

                table.insert(chatHistory, { role = "assistant", content = content })

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
        end

        currentModelIndex = (currentModelIndex % #MODELS) + 1
        if onNotice then
            onNotice("✴️ NOTICE: Daily limit reached for this model. Switching API model...", Color3.fromRGB(255, 255, 0))
        end
    end

    return "❌️ API ERROR: Failed to reach the AI endpoint. (Your message was saved. Type 'retry' when online).", nil
end

return AIModel
