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
        error("❌️ LOADING ERROR: Failed to load module: " .. fileName .. (err and (" | ERROR: " .. tostring(err)) or ""))
    end
    
    local compiledFunc, compileErr = loadstring(content)
    if not compiledFunc then
        error("❌️ LOADING ERROR: Failed to compile module: " .. fileName .. " | " .. tostring(compileErr))
    end

    return compiledFunc()
end

print("Loading modules, please wait...")

local UI = fetch("ui_core.lua")
local Env = fetch("environment_controller.lua")
local AI = fetch("ai_model.lua")

UI.Log("All modules loaded. AI ready.")

UI.Log("⚠️ WARNING: Use the AI for exploiting at your own risk.")
UI.Log.TextColor = Color3.fromRGB("255, 128, 0")

UI.Log("ℹ️ INFO: There is a daily limit of use.")
UI.Log.TextColor = Color3.fromRGB("0, 128, 255")

UI.OnInput(function(prompt)
    UI.Log("YOU: " .. prompt)
    local lowerPrompt = string.lower(prompt)
    
        UI.Log("Analyzing instruction...")
        task.spawn(function()
            local context = Env.GetGameState()
            local aiResponse, actionCode = AI.ProcessPrompt(prompt, context)
            
            UI.Log("AI: " .. tostring(aiResponse))
            if actionCode and actionCode ~= "" then
                UI.Log("Executing generated code...")
                local success, err = Env.Execute(actionCode)
                if not success then
                    UI.Log("❌️ EXECUTION ERROR: " .. tostring(err))
                    UI.Log.TextColor = Color3.fromRGB("255, 0, 0")
                else
                    UI.Log("Executed successfully.")
                end
            end
        end)
    end
end)
