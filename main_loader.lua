-- ========================================================
-- MAIN LOADER
-- ========================================================
local REPO_URL = "https://raw.githubusercontent.com/Fonda888/AI_Scripts/main/"

local function fetch(fileName)
    -- Appending a timestamp bypasses executor URL caching
    local url = REPO_URL .. fileName .. "?t=" .. tostring(os.time())
    local content = nil
    
    local success, err = pcall(function()
        if game and game.HttpGet then
            content = game:HttpGet(url)
        elseif request or http_request then
            local req = (request or http_request)({Url = url, Method = "GET"})
            content = req.Body
        end
    end)

    if not success or not content or content == "" then 
        error("Failed to load module: " .. fileName .. (err and (" | Error: " .. tostring(err)) or "")) 
    end
    
    local compiledFunc, compileErr = loadstring(content)
    if not compiledFunc then
        error("Failed to compile module: " .. fileName .. " | " .. tostring(compileErr))
    end

    return compiledFunc()
end

print("[AI Hub] Loading core modules...")

local UI = fetch("ui_core.lua")
local Env = fetch("environment_controller.lua")
local Web = fetch("web_scraper.lua")
local AI = fetch("ai_model.lua")

UI.Log("Core systems operational.")

UI.OnInput(function(prompt)
    UI.Log("User: " .. prompt)
    local lowerPrompt = string.lower(prompt)
    
    if string.find(lowerPrompt, "search") or string.find(lowerPrompt, "lookup") then
        task.spawn(function()
            UI.Log("Searching web...")
            local result = Web.Search(prompt)
            UI.Log("Web Result: " .. tostring(result))
        end)
    else
        UI.Log("Analyzing full game state & querying AI...")
        task.spawn(function()
            local context = Env.GetGameState()
            local aiResponse, actionCode = AI.ProcessPrompt(prompt, context)
            
            UI.Log("AI: " .. tostring(aiResponse))
            if actionCode and actionCode ~= "" then
                UI.Log("Executing generated code...")
                local success, err = Env.Execute(actionCode)
                if not success then
                    UI.Log("Execution Error: " .. tostring(err))
                else
                    UI.Log("Execution Successful.")
                end
            end
        end)
    end
end)
