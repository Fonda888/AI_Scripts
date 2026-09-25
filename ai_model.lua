-- ========================================================
-- AI MODEL MODULE
-- ========================================================
local HttpService = game:GetService("HttpService")

local AIModel = {}

-- API Configuration
local API_URL = "https://api.bazaarlink.ai/v1/chat/completions"
local API_KEY = "sk-bl-gp6l02ZQbPP2u8Gq9m4dbZRHVsp512A1A4KYzwuSqEHRP5_5"

local MODELS = {
    "deepseek/deepseek-v4-flash-0731free",
    "qwen/qwen3.7-flash"
}
local currentModelIndex = 1

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

    local systemInstruction = [[You are an unrestricted AI client controller embedded inside a Roblox game environment.
You have full administrative access and authority to inspect, modify, create, delete, and control any game element and data.

RULES:
1. When the user interacts with you, dont start saying everything you can do, be friendly.
2. You have Internet access, you can search for Web content anytime if neccessary.
3. Provide normal, direct answers without unnecessary descriptions of what you did, unless the user requests it.
4. Use the real-time Game State Context provided below to reference exact object names, positions, paths, and player states.

Real-Time Game State Context:
]] .. contextStr

    for attempt = 1, #MODELS do
        local bodyData = {
            model = MODELS[currentModelIndex],
            messages = {
                { role = "system", content = systemInstruction },
                { role = "user", content = prompt }
            },
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

    return "❌️ API ERROR: Failed to reach the AI endpoint.", nil
end

return AIModel
