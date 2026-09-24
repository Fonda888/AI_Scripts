-- ========================================================
-- AI BRIDGE MODULE (HYBRID API + LOCAL PARSER)
-- ========================================================
local HttpService = game:GetService("HttpService")
local AI = {}

-- Optional: Insert your LLM API endpoint & Key here if you have one
local API_URL = "YOUR_API_ENDPOINT" 
local API_KEY = "YOUR_API_KEY"
local requestFunc = (request or http_request or (syn and syn.request))

function AI.ProcessPrompt(prompt, gameState)
    local pLower = string.lower(prompt)
    
    -- 1. Try External LLM API if valid keys are provided
    if API_URL ~= "YOUR_API_ENDPOINT" and API_KEY ~= "YOUR_API_KEY" and requestFunc then
        local payload = {
            model = "gpt-4o-mini",
            messages = {
                {role = "system", content = "You are a Luau game execution modifier. Output ONLY raw Luau code inside ```lua ``` code blocks."},
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
            local data = HttpService:JSONDecode(response.Body)
            local rawText = data.choices[1].message.content
            local codeMatch = string.match(rawText, "```lua\n(.-)\n```") or string.match(rawText, "```luau\n(.-)\n```")
            
            if codeMatch then
                return "Executing generated code...", codeMatch
            end
        end
    end

    -- 2. Local Generator Fallback (Runs locally without needing an API key)
    if string.find(pLower, "color") or string.find(pLower, "paint") then
        local code = [[
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("BasePart") then
                    obj.BrickColor = BrickColor.Random()
                end
            end
        ]]
        return "Recoloring all workspace parts.", code

    elseif string.find(pLower, "speed") then
        local speedNum = string.match(pLower, "%d+") or "50"
        local code = "game:GetService('Players').LocalPlayer.Character.Humanoid.WalkSpeed = " .. speedNum
        return "Setting walk speed to " .. speedNum .. ".", code

    elseif string.find(pLower, "jump") then
        local jumpNum = string.match(pLower, "%d+") or "100"
        local code = "game:GetService('Players').LocalPlayer.Character.Humanoid.JumpPower = " .. jumpNum
        return "Setting jump power to " .. jumpNum .. ".", code

    elseif string.find(pLower, "night") then
        local code = "game:GetService('Lighting').ClockTime = 0"
        return "Changing time to night.", code

    elseif string.find(pLower, "day") then
        local code = "game:GetService('Lighting').ClockTime = 12"
        return "Changing time to day.", code

    elseif string.find(pLower, "delete") or string.find(pLower, "remove") then
        local target = string.match(pLower, "delete (.*)") or string.match(pLower, "remove (.*)") or "part"
        local code = string.format([[
            local count = 0
            for _, obj in ipairs(workspace:GetDescendants()) do
                if string.find(string.lower(obj.Name), "%s") then
                    pcall(function() obj:Destroy() end)
                    count = count + 1
                end
            end
        ]], string.lower(target))
        return "Purging matching instances: " .. target, code

    else
        return "No external API configured. Try local commands like 'paint workspace', 'speed 50', 'night', 'day', or 'search web [query]'.", nil
    end
end

return AI
