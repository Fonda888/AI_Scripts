-- ========================================================
-- AI BRIDGE MODULE
-- ========================================================
local HttpService = game:GetService("HttpService")
local AI = {}

-- Configure these to point to your backend LLM
local API_URL = "YOUR_API_ENDPOINT" 
local API_KEY = "YOUR_API_KEY"
local requestFunc = (request or http_request or (syn and syn.request))

function AI.ProcessPrompt(prompt, gameState)
    if not requestFunc then
        return "Offline Mode: Executor does not support HTTP requests.", nil
    end

    local payload = {
        model = "gpt-4", -- Or your specific model
        messages = {
            {role = "system", content = "You are a Luau game execution modifier. The user provides a prompt and context. Return valid Luau code to achieve the goal."},
            {role = "user", content = "Game Context: " .. gameState .. "\nRequest: " .. prompt}
        }
    }
    
    local success, response = pcall(function()
        return requestFunc({
            Url = API_URL,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json",
                ["Authorization"] = "Bearer " .. API_KEY
            },
            Body = HttpService:JSONEncode(payload)
        })
    end)

    if success and response.StatusCode == 200 then
        -- This parsing assumes a standard OpenAI-style response format
        local data = HttpService:JSONDecode(response.Body)
        local rawText = data.choices[1].message.content
        
        -- Extract code block if AI wrapped it in markdown
        local codeMatch = string.match(rawText, "```lua\n(.-)\n```") or string.match(rawText, "```luau\n(.-)\n```")
        
        if codeMatch then
            return "Compiled executable logic from response.", codeMatch
        else
            return rawText, nil
        end
    else
        return "Failed to contact AI API. Verify endpoint and executor capabilities.", nil
    end
end

return AI
