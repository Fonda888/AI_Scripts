-- ========================================================
-- UI CORE MODULE
-- ========================================================
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

local UI = {}
local MainColors = {
    Bg = Color3.fromRGB(64, 128, 128),
    Accent = Color3.fromRGB(64, 64, 64),
    Text = Color3.fromRGB(255, 255, 255)
}

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AI_Hub_Runtime"
ScreenGui.ResetOnSpawn = false
pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui", 5) end
if not ScreenGui.Parent then return end

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 450, 0, 320)
MainFrame.Position = UDim2.new(0.5, -225, 0.5, -160)
MainFrame.BackgroundColor3 = MainColors.Bg
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MainFrame

local TitleBar = Instance.new("TextLabel")
TitleBar.Size = UDim2.new(1, 0, 0, 30)
TitleBar.BackgroundColor3 = MainColors.Accent
TitleBar.Text = "  AI Runtime Core"
TitleBar.TextColor3 = MainColors.Text
TitleBar.Font = Enum.Font.SourceSansBold
TitleBar.TextSize = 16
TitleBar.TextXAlignment = Enum.TextXAlignment.Left
TitleBar.Active = true
TitleBar.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 8)
TitleCorner.Parent = TitleBar

local MinimizeButton = Instance.new("TextButton")
MinimizeButton.Name = "MinimizeButton"
MinimizeButton.Size = UDim2.new(0, 30, 0, 22)
MinimizeButton.Position = UDim2.new(1, -65, 0, 4)
MinimizeButton.BackgroundColor3 = MainColors.Bg
MinimizeButton.TextColor3 = MainColors.Text
MinimizeButton.Text = "-"
MinimizeButton.Font = Enum.Font.SourceSansBold
MinimizeButton.TextSize = 18
MinimizeButton.Parent = TitleBar

local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(0, 4)
MinCorner.Parent = MinimizeButton

local DestroyButton = Instance.new("TextButton")
DestroyButton.Name = "DestroyButton"
DestroyButton.Size = UDim2.new(0, 30, 0, 22)
DestroyButton.Position = UDim2.new(1, -33, 0, 4)
DestroyButton.BackgroundColor3 = Color3.fromRGB(128, 64, 64)
DestroyButton.TextColor3 = MainColors.Text
DestroyButton.Text = "X"
DestroyButton.Font = Enum.Font.SourceSansBold
DestroyButton.TextSize = 14
DestroyButton.Parent = TitleBar

local DestroyCorner = Instance.new("UICorner")
DestroyCorner.CornerRadius = UDim.new(0, 4)
DestroyCorner.Parent = DestroyButton

local RestoreButton = nil
local function CreateRestoreButton()
    if RestoreButton and RestoreButton.Parent then
        RestoreButton.Visible = true
        return
    end

    RestoreButton = Instance.new("TextButton")
    RestoreButton.Name = "AIRestoreButton"
    RestoreButton.Size = UDim2.new(0, 50, 0, 50)
    RestoreButton.Position = UDim2.new(0.05, 0, 0.75, 0)
    RestoreButton.BackgroundColor3 = MainColors.Bg
    RestoreButton.TextColor3 = MainColors.Text
    RestoreButton.Text = "AI"
    RestoreButton.Font = Enum.Font.SourceSansBold
    RestoreButton.TextSize = 20
    RestoreButton.Active = true
    RestoreButton.Draggable = true
    RestoreButton.Parent = ScreenGui

    local ResCorner = Instance.new("UICorner")
    ResCorner.CornerRadius = UDim.new(0, 8)
    ResCorner.Parent = RestoreButton

    RestoreButton.MouseButton1Click:Connect(function()
        MainFrame.Visible = true
        RestoreButton.Visible = false
    end)
end

MinimizeButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    CreateRestoreButton()
end)

DestroyButton.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

local OutputScroll = Instance.new("ScrollingFrame")
OutputScroll.Size = UDim2.new(1, -20, 1, -95)
OutputScroll.Position = UDim2.new(0, 10, 0, 40)
OutputScroll.BackgroundColor3 = MainColors.Accent
OutputScroll.BorderSizePixel = 0
OutputScroll.ScrollBarThickness = 4
OutputScroll.Parent = MainFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Parent = OutputScroll
UIListLayout.Padding = UDim.new(0, 4)
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder

local InputBox = Instance.new("TextBox")
InputBox.Size = UDim2.new(1, -55, 0, 35)
InputBox.Position = UDim2.new(0, 10, 1, -45)
InputBox.BackgroundColor3 = MainColors.Accent
InputBox.Text = ""
InputBox.PlaceholderText = " Enter instruction..."
InputBox.TextColor3 = MainColors.Text
InputBox.Font = Enum.Font.SourceSans
InputBox.TextSize = 15
InputBox.TextXAlignment = Enum.TextXAlignment.Left
InputBox.ClearTextOnFocus = false
InputBox.Parent = MainFrame

local InputCorner = Instance.new("UICorner")
InputCorner.CornerRadius = UDim.new(0, 6)
InputCorner.Parent = InputBox

-- ========================================================
-- SETTINGS MENU 
-- ========================================================
local SettingsBtn = Instance.new("TextButton")
SettingsBtn.Size = UDim2.new(0, 35, 0, 35)
SettingsBtn.Position = UDim2.new(1, -45, 1, -45)
SettingsBtn.BackgroundColor3 = MainColors.Accent
SettingsBtn.TextColor3 = MainColors.Text
SettingsBtn.Text = "⚙️"
SettingsBtn.Font = Enum.Font.SourceSansBold
SettingsBtn.TextSize = 18
SettingsBtn.Parent = MainFrame

local SettingsBtnCorner = Instance.new("UICorner")
SettingsBtnCorner.CornerRadius = UDim.new(0, 6)
SettingsBtnCorner.Parent = SettingsBtn

local SettingsFrame = Instance.new("Frame")
SettingsFrame.Size = UDim2.new(1, -20, 1, -95)
SettingsFrame.Position = UDim2.new(0, 10, 0, 40)
SettingsFrame.BackgroundColor3 = MainColors.Accent
SettingsFrame.BorderSizePixel = 0
SettingsFrame.Visible = false
SettingsFrame.Parent = MainFrame

local SettingsCorner = Instance.new("UICorner")
SettingsCorner.CornerRadius = UDim.new(0, 6)
SettingsCorner.Parent = SettingsFrame

local SettingsTitleLabel = Instance.new("TextLabel")
SettingsTitleLabel.Size = UDim2.new(1, 0, 0, 25)
SettingsTitleLabel.BackgroundTransparency = 1
SettingsTitleLabel.Text = "Settings"
SettingsTitleLabel.TextColor3 = MainColors.Text
SettingsTitleLabel.Font = Enum.Font.SourceSansBold
SettingsTitleLabel.TextSize = 16
SettingsTitleLabel.Parent = SettingsFrame

local BgSubtitle = Instance.new("TextLabel")
BgSubtitle.Size = UDim2.new(1, -10, 0, 20)
BgSubtitle.Position = UDim2.new(0, 10, 0, 25)
BgSubtitle.BackgroundTransparency = 1
BgSubtitle.Text = "Background"
BgSubtitle.TextColor3 = Color3.fromRGB(200, 200, 200)
BgSubtitle.Font = Enum.Font.SourceSansBold
BgSubtitle.TextSize = 14
BgSubtitle.TextXAlignment = Enum.TextXAlignment.Left
BgSubtitle.Parent = SettingsFrame

local ColorContainer = Instance.new("Frame")
ColorContainer.Size = UDim2.new(1, -10, 0, 30)
ColorContainer.Position = UDim2.new(0, 10, 0, 45)
ColorContainer.BackgroundTransparency = 1
ColorContainer.Parent = SettingsFrame

local UIListLayoutColors = Instance.new("UIListLayout")
UIListLayoutColors.FillDirection = Enum.FillDirection.Horizontal
UIListLayoutColors.Padding = UDim.new(0, 5)
UIListLayoutColors.Parent = ColorContainer

local backgroundColors = {
    Color3.fromRGB(0, 0, 0),
    Color3.fromRGB(128, 128, 128),
    Color3.fromRGB(64, 128, 128),
    Color3.fromRGB(128, 64, 128),
    Color3.fromRGB(128, 128, 64)
}

for _, color in ipairs(backgroundColors) do
    local colorBtn = Instance.new("TextButton")
    colorBtn.Size = UDim2.new(0, 30, 0, 30)
    colorBtn.BackgroundColor3 = color
    colorBtn.Text = ""
    colorBtn.Parent = ColorContainer
    
    local cCorner = Instance.new("UICorner")
    cCorner.CornerRadius = UDim.new(0, 4)
    cCorner.Parent = colorBtn
    
    colorBtn.MouseButton1Click:Connect(function()
        MainFrame.BackgroundColor3 = color
    end)
end

local OthersSubtitle = Instance.new("TextLabel")
OthersSubtitle.Size = UDim2.new(1, -10, 0, 20)
OthersSubtitle.Position = UDim2.new(0, 10, 0, 85)
OthersSubtitle.BackgroundTransparency = 1
OthersSubtitle.Text = "Others"
OthersSubtitle.TextColor3 = Color3.fromRGB(200, 200, 200)
OthersSubtitle.Font = Enum.Font.SourceSansBold
OthersSubtitle.TextSize = 14
OthersSubtitle.TextXAlignment = Enum.TextXAlignment.Left
OthersSubtitle.Parent = SettingsFrame

local function createActionBtn(text, yPos)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -20, 0, 25)
    btn.Position = UDim2.new(0, 10, 0, yPos)
    btn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    btn.TextColor3 = MainColors.Text
    btn.Text = text
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 14
    btn.Parent = SettingsFrame
    
    local bCorner = Instance.new("UICorner")
    bCorner.CornerRadius = UDim.new(0, 4)
    bCorner.Parent = btn
    return btn
end

local ClearBtn = createActionBtn("Clear cache", 110)
local RejoinBtn = createActionBtn("Rejoin", 140)
local HopBtn = createActionBtn("Server hop", 170)

-- Settings Footer Labels
local MadeByLabel = Instance.new("TextLabel")
MadeByLabel.Size = UDim2.new(0, 150, 0, 20)
MadeByLabel.Position = UDim2.new(0, 10, 1, -22)
MadeByLabel.BackgroundTransparency = 1
MadeByLabel.RichText = true
MadeByLabel.Text = "<i>Made by <b>Fonda888</b></i>"
MadeByLabel.TextColor3 = Color3.fromRGB(128, 128, 128)
MadeByLabel.Font = Enum.Font.SourceSans
MadeByLabel.TextSize = 13
MadeByLabel.TextXAlignment = Enum.TextXAlignment.Left
MadeByLabel.Parent = SettingsFrame

local VersionLabel = Instance.new("TextLabel")
VersionLabel.Size = UDim2.new(0, 150, 0, 20)
VersionLabel.Position = UDim2.new(1, -160, 1, -22)
VersionLabel.BackgroundTransparency = 1
VersionLabel.Text = "v0.8 (BETA)"
VersionLabel.TextColor3 = Color3.fromRGB(128, 128, 128)
VersionLabel.Font = Enum.Font.SourceSans
VersionLabel.TextSize = 13
VersionLabel.TextXAlignment = Enum.TextXAlignment.Right
VersionLabel.Parent = SettingsFrame

SettingsBtn.MouseButton1Click:Connect(function()
    SettingsFrame.Visible = not SettingsFrame.Visible
    OutputScroll.Visible = not SettingsFrame.Visible
end)

local logCount = 0

ClearBtn.MouseButton1Click:Connect(function()
    for _, child in ipairs(OutputScroll:GetChildren()) do
        if child:IsA("TextLabel") then
            child:Destroy()
        end
    end
    logCount = 0
    OutputScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
end)

RejoinBtn.MouseButton1Click:Connect(function()
    if #Players:GetPlayers() <= 1 then
        LocalPlayer:Kick("\nRejoining...")
        task.wait()
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    else
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end
end)

HopBtn.MouseButton1Click:Connect(function()
    local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
    local success, result = pcall(function()
        return HttpService:JSONDecode(game:HttpGet(url))
    end)
    
    if success and result and result.data then
        for _, server in ipairs(result.data) do
            if server.playing < server.maxPlayers and server.id ~= game.JobId then
                TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, LocalPlayer)
                break
            end
        end
    end
end)

-- ========================================================
-- DRAGGING & LOGGING
-- ========================================================

local dragging = false
local dragStart = nil
local startPos = nil

TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
    end
end)

TitleBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) and dragging then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

function UI.Log(text, customColor)
    logCount = logCount + 1
    local msg = Instance.new("TextLabel")
    msg.Size = UDim2.new(1, -10, 0, 0)
    msg.AutomaticSize = Enum.AutomaticSize.Y
    msg.BackgroundTransparency = 1
    msg.Text = "> " .. tostring(text)
    
    msg.TextColor3 = customColor or MainColors.Text 
    
    msg.Font = Enum.Font.Code
    msg.TextSize = 13
    msg.TextXAlignment = Enum.TextXAlignment.Left
    msg.TextWrapped = true
    msg.LayoutOrder = logCount
    msg.Parent = OutputScroll
    
    task.defer(function()
        OutputScroll.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y + 10)
        OutputScroll.CanvasPosition = Vector2.new(0, OutputScroll.CanvasSize.Y.Offset)
    end)
end

function UI.OnInput(callback)
    InputBox.FocusLost:Connect(function(enterPressed)
        if enterPressed and InputBox.Text ~= "" then
            local text = InputBox.Text
            InputBox.Text = ""
            callback(text)
        end
    end)
end

return UI
