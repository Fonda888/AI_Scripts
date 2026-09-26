-- ========================================================
-- SETTINGS MANAGER MODULE
-- ========================================================
local HttpService = game:GetService("HttpService")

local SettingsManager = {}
local SETTINGS_FILE = "AI_Hub_Settings.json"

local DefaultSettings = {
    Theme = "Old",
    CustomBgColor = nil
}

local CurrentSettings = table.clone(DefaultSettings)

local writefile = writefile or (pcall(function() return writefile end) and writefile) or nil
local readfile = readfile or (pcall(function() return readfile end) and readfile) or nil
local isfile = isfile or (pcall(function() return isfile end) and isfile) or nil

function SettingsManager.Load()
    if isfile and readfile and isfile(SETTINGS_FILE) then
        local success, data = pcall(function()
            return HttpService:JSONDecode(readfile(SETTINGS_FILE))
        end)
        if success and type(data) == "table" then
            CurrentSettings.Theme = data.Theme or DefaultSettings.Theme
            CurrentSettings.CustomBgColor = data.CustomBgColor
        end
    end
    return CurrentSettings
end

function SettingsManager.Save(settingsTable)
    if writefile then
        for k, v in pairs(settingsTable) do
            CurrentSettings[k] = v
        end
        pcall(function()
            writefile(SETTINGS_FILE, HttpService:JSONEncode(CurrentSettings))
        end)
    end
end

function SettingsManager.Get()
    return CurrentSettings
end

return SettingsManager
