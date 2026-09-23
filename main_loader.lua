-- ========================================================
-- ADVANCED AI HUB - MAIN LOADER
-- ========================================================
local REPO_URL = "https://raw.githubusercontent.com/Fonda888/AI_Scripts/main/"

local function fetch(fileName)
    local url = REPO_URL .. fileName
    local content
    if game and game.HttpGet then
        content = game:HttpGet(url)
    elseif request or http_request then
        local req = (request or http_request)({Url = url, Method = "GET"})
        content = req.Body
    end
    if not content or content == "" then error("Failed to load: " .. fileName) end
    return loadstring(content)()
end

print("[AI Hub] Loading modules...")
local UI = fetch("ui_core.lua")
local Env = fetch("environment_controller.lua")
local Web = fetch("web_scraper.lua")
local AI = fetch("ai_bridge.lua")

-- Connect the systems
UI.Log("Modules loaded successfully. Core systems online.")

UI.OnInput(function(prompt)
    UI.Log("User: " .. prompt)
    local lowerPrompt = string.lower(prompt)
    
    if string.find(lowerPrompt, "search") or string.find(lowerPrompt, "lookup") then
        UI.Log("Initiating web search...")
        local result = Web.Search(prompt)
        UI.Log("Web: " .. result)
    else
        UI.Log("Analyzing environment and prompt...")
        local context = Env.GetGameState()
        local aiResponse, actionCode = AI.ProcessPrompt(prompt, context)
        
        UI.Log("AI: " .. aiResponse)
        if actionCode then
            local success, err = Env.Execute(actionCode)
            if not success then
                UI.Log("Execution Error: " .. tostring(err))
            end
        end
    end
end)
