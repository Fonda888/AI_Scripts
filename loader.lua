-- ========================================================
-- LOADER
-- ========================================================
local REPO_URL = "https://raw.githubusercontent.com/Fonda888/AI_Scripts/main/"

local function fetch(fileName)
    local url = REPO_URL .. fileName .. "?t=" .. tostring(os.time())
    local content = nil
    
    local success, err = pcall(function()
        if game and game.HttpGet then
            content = game:HttpGet(url)
        else
            local reqFunc = (request or http_request or (syn and syn.request) or (fluxus and fluxus.request))
            if reqFunc then
                local req = reqFunc({Url = url, Method = "GET"})
                content = req.Body
            end
        end
    end)

    if not success or not content or content == "" then 
        error("LOADING ERROR: Failed to load module: " .. fileName .. (err and (" | ERROR: " .. tostring(err)) or ""))
    end
    
    local loadFunc = loadstring or (getgenv and getgenv().loadstring)
    local compiledFunc, compileErr = loadFunc(content)
    if not compiledFunc then
        error("LOADING ERROR: Failed to compile module: " .. fileName .. " | " .. tostring(compileErr))
    end

    return compiledFunc()
end

print("Loading modules, please wait...")

local UI = fetch("ui.lua")
local Env = fetch("environment_controller.lua")
local AI = fetch("ai_model.lua")

UI.Log("All modules loaded. AI system ready.", Color3.fromRGB(0, 255, 128))
UI.Log("⚠️ WARNING: Use the AI for scripting/modifying at your own risk.", Color3.fromRGB(255, 128, 0))
UI.Log("ℹ️ INFO: Daily limit applies per API tier.", Color3.fromRGB(0, 128, 255))

UI.OnInput(function(prompt)
    UI.Log("YOU: " .. prompt)
    UI.Log("Analyzing instruction...")
    
    task.spawn(function()
        local context = Env.GetGameState()
        local aiResponse, actionCode = AI.ProcessPrompt(prompt, context, function(noticeText, noticeColor)
            UI.Log(noticeText, noticeColor)
        end)
        
        if string.find(aiResponse, "❌") then
            UI.Log(tostring(aiResponse), Color3.fromRGB(255, 128, 128))
        else
            UI.Log("AI: " .. tostring(aiResponse))
        end
        
        if actionCode and actionCode ~= "" then
            UI.Log("Executing generated code...")
            local success, err = Env.Execute(actionCode)
            if not success then
                UI.Log("❌ EXECUTION ERROR: " .. tostring(err))
                AI.AppendExecutionResult("Error: " .. tostring(err))
            else
                UI.Log("Executed successfully.")
                AI.AppendExecutionResult("Success: Code executed without errors.")
            end
        end
    end)
end)
