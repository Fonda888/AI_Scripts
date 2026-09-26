-- ========================================================
-- UI MODULE
-- ========================================================
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local LocalPlayer = Players.LocalPlayer

local UI = {}
local currentTheme = "Old"
local customBgColor = nil

local Themes = {
    Old = {
        Bg = Color3.fromRGB(64, 128, 128),
        Accent = Color3.fromRGB(64, 64, 64),
        Text = Color3.fromRGB(255, 255, 255),
        RadiusMain = 8, RadiusBtn = 6,
        BgOptions = {
            Color3.fromRGB(0, 0, 0), Color3.fromRGB(128, 128, 128),
            Color3.fromRGB(64, 128, 128), Color3.fromRGB(128, 64, 128), Color3.fromRGB(128, 128, 64)
        }
    },
    New = {
        Bg = Color3.fromRGB(25, 27, 31),
        Accent = Color3.fromRGB(40, 42, 48),
        Text = Color3.fromRGB(240, 240, 245),
        RadiusMain = 14, RadiusBtn = 10,
        BgOptions = {
            Color3.fromRGB(15, 15, 18), Color3.fromRGB(45, 45, 50),
            Color3.fromRGB(30, 45, 45), Color3.fromRGB(45, 30, 45), Color3.fromRGB(45, 45, 35)
        }
    }
}

local function MountUI()
    local target = nil
    pcall(function() target = (gethui and gethui()) or CoreGui end)
    if not target then target = LocalPlayer:WaitForChild("PlayerGui", 5) end
    return target
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AI_HUB"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = MountUI()
if not ScreenGui.Parent then return end

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 450, 0, 320)
MainFrame.Position = UDim2.new(0.5, -225, 0.5, -160)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.Parent = MainFrame

local TitleBar = Instance.new("TextLabel")
TitleBar.Size = UDim2.new(1, 0, 0, 30)
TitleBar.Text = "  In-game AI assistant"
TitleBar.Font = Enum.Font.SourceSansBold
TitleBar.TextSize = 16
TitleBar.TextXAlignment = Enum.TextXAlignment.Left
TitleBar.Active = true
TitleBar.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.Parent = TitleBar

local MinimizeButton = Instance.new("TextButton")
MinimizeButton.Size = UDim2.new(0, 30, 0, 22)
MinimizeButton.Position = UDim2.new(1, -65, 0, 4)
MinimizeButton.Text = "-"
MinimizeButton.Font = Enum.Font.SourceSansBold
MinimizeButton.TextSize = 18
MinimizeButton.Parent = TitleBar

local MinCorner = Instance.new("UICorner")
MinCorner.Parent = MinimizeButton

local DestroyButton = Instance.new("TextButton")
DestroyButton.Size = UDim2.new(0, 30, 0, 22)
DestroyButton.Position = UDim2.new(1, -33, 0, 4)
DestroyButton.BackgroundColor3 = Color3.fromRGB(190, 60, 60)
DestroyButton.Text = "X"
DestroyButton.Font = Enum.Font.SourceSansBold
DestroyButton.TextSize = 14
DestroyButton.Parent = TitleBar

local DestroyCorner = Instance.new("UICorner")
DestroyCorner.Parent = DestroyButton

local RestoreButton = nil
local dragRestore, dragStartRes, startPosRes = false, nil, nil
local hasDraggedRes = false

local function CreateRestoreButton()
    if RestoreButton and RestoreButton.Parent then
        RestoreButton.Visible = true
        return
    end

    RestoreButton = Instance.new("TextButton")
    RestoreButton.Size = UDim2.new(0, 50, 0, 50)
    RestoreButton.Position = UDim2.new(0.05, 0, 0.75, 0)
    RestoreButton.Text = "AI"
    RestoreButton.Font = Enum.Font.SourceSansBold
    RestoreButton.TextSize = 20
    RestoreButton.Active = true
    RestoreButton.Parent = ScreenGui

    local ResCorner = Instance.new("UICorner")
    ResCorner.Parent = RestoreButton
    
    local cTheme = Themes[currentTheme]
    RestoreButton.BackgroundColor3 = customBgColor or cTheme.Bg
    RestoreButton.TextColor3 = cTheme.Text
    ResCorner.CornerRadius = UDim.new(0, cTheme.RadiusBtn)

    RestoreButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragRestore = true; hasDraggedRes = false; dragStartRes = input.Position; startPosRes = RestoreButton.Position
        end
    end)

    RestoreButton.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if not hasDraggedRes then MainFrame.Visible = true; RestoreButton.Visible = false end
            dragRestore = false; hasDraggedRes = false
        end
    end)
end

MinimizeButton.MouseButton1Click:Connect(function() MainFrame.Visible = false; CreateRestoreButton() end)
DestroyButton.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

local OutputScroll = Instance.new("ScrollingFrame")
OutputScroll.Size = UDim2.new(1, -20, 1, -95)
OutputScroll.Position = UDim2.new(0, 10, 0, 40)
OutputScroll.BorderSizePixel = 0
OutputScroll.ScrollBarThickness = 4
OutputScroll.Parent = MainFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Parent = OutputScroll
UIListLayout.Padding = UDim.new(0, 12)
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder

local InputBox = Instance.new("TextBox")
InputBox.Size = UDim2.new(1, -55, 0, 35)
InputBox.Position = UDim2.new(0, 10, 1, -45)
InputBox.Text = ""
InputBox.PlaceholderText = ' Ask something like "Play specific sound"...'
InputBox.Font = Enum.Font.SourceSans
InputBox.TextSize = 14
InputBox.TextXAlignment = Enum.TextXAlignment.Left
InputBox.ClearTextOnFocus = false
InputBox.Parent = MainFrame

local InputCorner = Instance.new("UICorner")
InputCorner.Parent = InputBox

local firstFocus = true
InputBox.Focused:Connect(function()
    if firstFocus then InputBox.PlaceholderText = " Ask anything..."; firstFocus = false end
end)

local SettingsBtn = Instance.new("TextButton")
SettingsBtn.Size = UDim2.new(0, 35, 0, 35)
SettingsBtn.Position = UDim2.new(1, -45, 1, -45)
SettingsBtn.Text = "⚙️"
SettingsBtn.Font = Enum.Font.SourceSansBold
SettingsBtn.TextSize = 18
SettingsBtn.Parent = MainFrame

local SettingsBtnCorner = Instance.new("UICorner")
SettingsBtnCorner.Parent = SettingsBtn

local SettingsFrame = Instance.new("Frame")
SettingsFrame.Size = UDim2.new(1, -20, 1, -95)
SettingsFrame.Position = UDim2.new(0, 10, 0, 40)
SettingsFrame.BorderSizePixel = 0
SettingsFrame.Visible = false
SettingsFrame.Parent = MainFrame

local SettingsCorner = Instance.new("UICorner")
SettingsCorner.Parent = SettingsFrame

local SettingsTitle = Instance.new("TextLabel")
SettingsTitle.Size = UDim2.new(1, 0, 0, 25)
SettingsTitle.BackgroundTransparency = 1
SettingsTitle.Text = "Settings"
SettingsTitle.Font = Enum.Font.SourceSansBold
SettingsTitle.TextSize = 16
SettingsTitle.TextXAlignment = Enum.TextXAlignment.Center
SettingsTitle.Parent = SettingsFrame

local SettingsScroll = Instance.new("ScrollingFrame")
SettingsScroll.Size = UDim2.new(1, -10, 1, -55)
SettingsScroll.Position = UDim2.new(0, 5, 0, 30)
SettingsScroll.BackgroundTransparency = 1
SettingsScroll.BorderSizePixel = 0
SettingsScroll.ScrollBarThickness = 3
SettingsScroll.Parent = SettingsFrame

local SetList = Instance.new("UIListLayout")
SetList.Parent = SettingsScroll
SetList.Padding = UDim.new(0, 8)
SetList.HorizontalAlignment = Enum.HorizontalAlignment.Center
SetList.SortOrder = Enum.SortOrder.LayoutOrder

local dynamicElements = {Corners = {}, Backgrounds = {}, Accents = {}, Texts = {}}

local function TrackElement(elType, element)
    table.insert(dynamicElements[elType], element)
end

TrackElement("Corners", UICorner); TrackElement("Corners", TitleCorner); TrackElement("Corners", MinCorner);
TrackElement("Corners", InputCorner); TrackElement("Corners", SettingsBtnCorner); TrackElement("Corners", SettingsCorner);
TrackElement("Corners", DestroyCorner);
TrackElement("Backgrounds", MainFrame); TrackElement("Backgrounds", MinimizeButton);
TrackElement("Accents", TitleBar); TrackElement("Accents", OutputScroll); TrackElement("Accents", InputBox); 
TrackElement("Accents", SettingsBtn); TrackElement("Accents", SettingsFrame);
TrackElement("Texts", TitleBar); TrackElement("Texts", MinimizeButton); TrackElement("Texts", InputBox); 
TrackElement("Texts", SettingsBtn); TrackElement("Texts", SettingsTitle);

local function CreateHeader(text, order)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -10, 0, 20)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.Font = Enum.Font.SourceSansBold
    lbl.TextSize = 14
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.LayoutOrder = order
    lbl.Parent = SettingsScroll
    TrackElement("Texts", lbl)
    return lbl
end

local function CreateButton(text, order, customParent)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, 30)
    btn.Text = text
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 14
    btn.LayoutOrder = order
    btn.Parent = customParent or SettingsScroll
    local corner = Instance.new("UICorner")
    corner.Parent = btn
    
    TrackElement("Corners", corner)
    TrackElement("Backgrounds", btn)
    TrackElement("Texts", btn)
    return btn
end

CreateHeader("Style", 1)
local StyleFrame = Instance.new("Frame")
StyleFrame.Size = UDim2.new(1, -10, 0, 30)
StyleFrame.BackgroundTransparency = 1
StyleFrame.LayoutOrder = 2
StyleFrame.Parent = SettingsScroll

local btnOld = CreateButton("Old", 1, StyleFrame)
btnOld.Size = UDim2.new(0.5, -5, 1, 0)
btnOld.Position = UDim2.new(0, 0, 0, 0)

local btnNew = CreateButton("New", 2, StyleFrame)
btnNew.Size = UDim2.new(0.5, -5, 1, 0)
btnNew.Position = UDim2.new(0.5, 5, 0, 0)

CreateHeader("Background", 3)
local BgColorsFrame = Instance.new("Frame")
BgColorsFrame.Size = UDim2.new(1, -10, 0, 30)
BgColorsFrame.BackgroundTransparency = 1
BgColorsFrame.LayoutOrder = 4
BgColorsFrame.Parent = SettingsScroll

local cList = Instance.new("UIListLayout")
cList.FillDirection = Enum.FillDirection.Horizontal
cList.Padding = UDim.new(0, 8)
cList.Parent = BgColorsFrame

local bgButtons = {}
local function BuildBgButtons()
    for _, btn in ipairs(bgButtons) do btn:Destroy() end
    table.clear(bgButtons)
    
    local opts = Themes[currentTheme].BgOptions
    for _, col in ipairs(opts) do
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0, 30, 0, 30)
        b.BackgroundColor3 = col
        b.Text = ""
        b.Parent = BgColorsFrame
        local c = Instance.new("UICorner")
        c.Parent = b
        TrackElement("Corners", c)
        
        b.MouseButton1Click:Connect(function()
            customBgColor = col
            MainFrame.BackgroundColor3 = col
            MinimizeButton.BackgroundColor3 = col
            if RestoreButton then RestoreButton.BackgroundColor3 = col end
            if UI.SaveSettings then UI.SaveSettings() end
        end)
        table.insert(bgButtons, b)
    end
end

CreateHeader("Others", 5)
local btnClear = CreateButton("Clear cache", 6)
local btnRejoin = CreateButton("Rejoin server", 7)
local btnHop = CreateButton("Switch server", 8)

btnClear.MouseButton1Click:Connect(function() end)

btnRejoin.MouseButton1Click:Connect(function()
    if #Players:GetPlayers() <= 1 then
        LocalPlayer:Kick("\nRejoining...")
        task.wait()
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    else
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end
end)

btnHop.MouseButton1Click:Connect(function()
    TeleportService:Teleport(game.PlaceId, LocalPlayer)
end)

local FooterLeft = Instance.new("TextLabel")
FooterLeft.Size = UDim2.new(0.5, -5, 0, 20)
FooterLeft.Position = UDim2.new(0, 5, 1, -20)
FooterLeft.BackgroundTransparency = 1
FooterLeft.Text = '<i>Made by <b>Fonda888</b></i>'
FooterLeft.RichText = true
FooterLeft.TextXAlignment = Enum.TextXAlignment.Left
FooterLeft.TextSize = 12
FooterLeft.Font = Enum.Font.SourceSans
FooterLeft.Parent = SettingsFrame

local FooterRight = Instance.new("TextLabel")
FooterRight.Size = UDim2.new(0.5, -5, 0, 20)
FooterRight.Position = UDim2.new(0.5, 0, 1, -20)
FooterRight.BackgroundTransparency = 1
FooterRight.Text = "v0.9 (BETA)"
FooterRight.TextXAlignment = Enum.TextXAlignment.Right
FooterRight.TextSize = 12
FooterRight.Font = Enum.Font.SourceSans
FooterRight.Parent = SettingsFrame

TrackElement("Texts", FooterLeft); TrackElement("Texts", FooterRight);

-- Theme Application
local function ApplyTheme()
    local t = Themes[currentTheme]
    for _, el in ipairs(dynamicElements.Backgrounds) do 
        if el == MainFrame or el == MinimizeButton then
            el.BackgroundColor3 = customBgColor or t.Bg
        else
            el.BackgroundColor3 = t.Bg 
        end
    end
    for _, el in ipairs(dynamicElements.Accents) do el.BackgroundColor3 = t.Accent end
    for _, el in ipairs(dynamicElements.Texts) do 
        if el.Parent == SettingsFrame and el.BackgroundTransparency == 1 then
            el.TextColor3 = Color3.new(t.Text.R*0.8, t.Text.G*0.8, t.Text.B*0.8)
        else
            el.TextColor3 = t.Text 
        end
    end
    for _, el in ipairs(dynamicElements.Corners) do 
        el.CornerRadius = (el.Parent == MainFrame) and UDim.new(0, t.RadiusMain) or UDim.new(0, t.RadiusBtn)
    end
    
    DestroyCorner.CornerRadius = UDim.new(0, t.RadiusBtn)
    SettingsBtnCorner.CornerRadius = UDim.new(0, t.RadiusBtn)
    
    if RestoreButton then
        RestoreButton.BackgroundColor3 = customBgColor or t.Bg
        RestoreButton.TextColor3 = t.Text
        RestoreButton:FindFirstChildOfClass("UICorner").CornerRadius = UDim.new(0, t.RadiusBtn)
    end
    
    for _, child in ipairs(OutputScroll:GetChildren()) do
        if child:IsA("TextLabel") then child.TextColor3 = t.Text end
    end
    
    BuildBgButtons()
    if UI.SaveSettings then UI.SaveSettings() end
end

btnOld.MouseButton1Click:Connect(function() currentTheme = "Old"; customBgColor = nil; ApplyTheme() end)
btnNew.MouseButton1Click:Connect(function() currentTheme = "New"; customBgColor = nil; ApplyTheme() end)

SettingsBtn.MouseButton1Click:Connect(function()
    SettingsFrame.Visible = not SettingsFrame.Visible
    OutputScroll.Visible = not SettingsFrame.Visible
    SettingsScroll.CanvasSize = UDim2.new(0, 0, 0, SetList.AbsoluteContentSize.Y + 10)
end)

local dragging, dragStart, startPos = false, nil, nil
TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true; dragStart = input.Position; startPos = MainFrame.Position
    end
end)
TitleBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
end)
UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        if dragging then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        elseif dragRestore and RestoreButton and RestoreButton.Visible then
            local delta = input.Position - dragStartRes
            if delta.Magnitude > 5 then hasDraggedRes = true end
            RestoreButton.Position = UDim2.new(startPosRes.X.Scale, startPosRes.X.Offset + delta.X, startPosRes.Y.Scale, startPosRes.Y.Offset + delta.Y)
        end
    end
end)

local logCount = 0
function UI.Log(text, customColor)
    logCount = logCount + 1
    local msg = Instance.new("TextLabel")
    msg.Size = UDim2.new(1, -10, 0, 0)
    msg.AutomaticSize = Enum.AutomaticSize.Y
    msg.BackgroundTransparency = 1
    msg.Text = "> " .. tostring(text)
    msg.RichText = true
    msg.TextColor3 = customColor or Themes[currentTheme].Text 
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

function UI.InitializeSettings(themeName, bgColorArray)
    if themeName and Themes[themeName] then currentTheme = themeName end
    if bgColorArray and #bgColorArray == 3 then customBgColor = Color3.fromRGB(unpack(bgColorArray)) end
    ApplyTheme()
end

return UI
