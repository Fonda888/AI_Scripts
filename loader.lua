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

local SettingsMan = fetch("settings_manager.lua")
local UI = fetch("ui.lua")
local Env = fetch("environment_controller.lua")
local AI = fetch("ai_model.lua")

local savedSettings = SettingsMan.Load()
UI.SaveSettings = function()
    local colorArray = nil
end

local originalInit = UI.InitializeSettings
UI.SaveSettings = function()
end

UI.InitializeSettings(savedSettings.Theme, savedSettings.CustomBgColor)

UI.Log("All modules loaded. Ready for use.", Color3.fromRGB(0, 255, 128))
UI.Log("<b>⚠️ WARNING:</b> Use the AI for exploiting at your own risk.", Color3.fromRGB(255, 128, 0))
UI.Log("<b>ℹ️ INFO:</b> There is a daily limit of use.", Color3.fromRGB(0, 128, 255))

UI.OnInput(function(prompt)
    UI.Log("<b>USER:</b> " .. prompt)
    UI.Log("Analyzing message...", Color3.fromRGB(255, 128, 255))
    
    task.spawn(function()
        local context = Env.GetGameState()
        local aiResponse, actionCode = AI.ProcessPrompt(prompt, context, function(noticeText, noticeColor)
            UI.Log(noticeText, noticeColor)
        end)
        
        if actionCode and actionCode ~= "" then
            UI.Log("Executing requested action...", Color3.fromRGB(255, 128, 255))
            local success, err = Env.Execute(actionCode)
            if not success then
                UI.Log("<b>❌ EXECUTION ERROR:</b> " .. tostring(err), Color3.fromRGB(255, 128, 128))
                AI.AppendExecutionResult("Error: " .. tostring(err))
            else
                AI.AppendExecutionResult("Success: Code executed without errors.")
            end
        end
        
         UI.Log("<b>AI:</b> " .. tostring(aiResponse))
    end)
end)
