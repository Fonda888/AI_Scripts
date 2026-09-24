-- ========================================================
-- AI BRIDGE MODULE
-- ========================================================
local HttpService = game:GetService("HttpService")

local AIBridge = {}
local requestFunc = (request or http_request or (syn and syn.request))

local API_URL = "https://api.bazaarlink.ai/v1/chat/completions"
local API_KEY = "sk-bl-gp6l02ZQbPP2u8Gq9m4dbZRHVsp512A1A4KYzwuSqEHRP5_5"

function AIBridge.ProcessPrompt(prompt, context)
    if not requestFunc then
        return "Error: Executor lacks HTTP request capability.", nil
    end

    local contextString = typeof(context) == "table" and HttpService:JSONEncode(context) or tostring(context or "No context")

    local systemInstructions = "You are an AI integrated into a Roblox game environment. "
        .. "Provide direct, concise responses to the player. "
        .. "Current game state context: " .. contextString

    local bodyData = {
        model = "gpt-3.5-turbo",
        messages = {
            { role = "system", content = systemInstructions },
            { role = "user", content = prompt }
        },
        temperature = 0.7
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
            local aiResponse = data.choices[1].message.content
            return aiResponse, nil
        else
            return "Error: Failed to parse API response (Invalid JSON).", nil
        end
    else
        local errCode = response and (response.StatusCode or response.StatusMessage) or "No response"
        return "API Request Failed (Status: " .. tostring(errCode) .. ")", nil
    end
end

return AIBridge
