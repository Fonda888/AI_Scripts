-- ========================================================
-- UI MODULE
-- ========================================================

local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local LocalPlayer = Players.LocalPlayer

local UI = {}
local MainColors = {
    Bg = Color3.fromRGB(64, 128, 128),
    Accent = Color3.fromRGB(64, 64, 64),
    Text = Color3.fromRGB(255, 255, 255)
}

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AI_HUB"
ScreenGui.ResetOnSpawn = false

local function MountUI()
    local target = nil
    pcall(function() target = (gethui and gethui()) or CoreGui end)
    if not target then target = LocalPlayer:WaitForChild("PlayerGui", 5) end
    return target
end

ScreenGui.Parent = MountUI()
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
TitleBar.Text = "  In-game AI assistant"
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
DestroyButton.Size = UDim2.new(0, 30, 0, 22)
DestroyButton.Position = UDim2.new(1, -33, 0, 4)
DestroyButton.BackgroundColor3 = Color3.fromRGB(128, 64, 64)
DestroyButton.TextColor3 = MainColors.Text
DestroyButton.Text = "X"
DestroyButton.Font = Enum.Font.SourceSansBold
DestroyButton.TextSize = 14
DestroyButton.TextXAlignment = Enum.TextXAlignment.Center
DestroyButton.TextYAlignment = Enum.TextYAlignment.Center
DestroyButton.Parent = TitleBar

local DestroyCorner = Instance.new("UICorner")
DestroyCorner.CornerRadius = UDim.new(0, 4)
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
    RestoreButton.BackgroundColor3 = MainColors.Bg
    RestoreButton.TextColor3 = MainColors.Text
    RestoreButton.Text = "AI"
    RestoreButton.Font = Enum.Font.SourceSansBold
    RestoreButton.TextSize = 20
    RestoreButton.Active = true
    RestoreButton.Parent = ScreenGui

    local ResCorner = Instance.new("UICorner")
    ResCorner.CornerRadius = UDim.new(0, 8)
    ResCorner.Parent = RestoreButton

    RestoreButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragRestore = true
            hasDraggedRes = false
            dragStartRes = input.Position
            startPosRes = RestoreButton.Position
        end
    end)

    RestoreButton.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if not hasDraggedRes then
                MainFrame.Visible = true
                RestoreButton.Visible = false
            end
            dragRestore = false
            hasDraggedRes = false
        end
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
UIListLayout.Padding = UDim.new(0, 16)
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder

local InputBox = Instance.new("TextBox")
InputBox.Size = UDim2.new(1, -55, 0, 35)
InputBox.Position = UDim2.new(0, 10, 1, -45)
InputBox.BackgroundColor3 = MainColors.Accent
InputBox.Text = ""
InputBox.PlaceholderText = ' Ask something like "Play specific sound" or "Give specific item"...'
InputBox.TextColor3 = MainColors.Text
InputBox.Font = Enum.Font.SourceSans
InputBox.TextSize = 14
InputBox.TextXAlignment = Enum.TextXAlignment.Left
InputBox.ClearTextOnFocus = false
InputBox.Parent = MainFrame

local InputCorner = Instance.new("UICorner")
InputCorner.CornerRadius = UDim.new(0, 6)
InputCorner.Parent = InputBox

local firstFocus = true
InputBox.Focused:Connect(function()
    if firstFocus then
        InputBox.PlaceholderText = " Ask anything..."
        firstFocus = false
    end
end)

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
SettingsBtnCorner.CornerRadius = UDim.new(0.5, 0)
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

local SettingsTitle = Instance.new("TextLabel")
SettingsTitle.Size = UDim2.new(1, 0, 0, 25)
SettingsTitle.BackgroundTransparency = 1
SettingsTitle.Text = "Settings"
SettingsTitle.TextColor3 = MainColors.Text
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

local function CreateHeader(text, order)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -10, 0, 20)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(200, 200, 200)
    lbl.Font = Enum.Font.SourceSansBold
    lbl.TextSize = 14
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.LayoutOrder = order
    lbl.Parent = SettingsScroll
end

local function CreateButton(text, order)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, 30)
    btn.BackgroundColor3 = MainColors.Bg
    btn.TextColor3 = MainColors.Text
    btn.Text = text
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 14
    btn.LayoutOrder = order
    btn.Parent = SettingsScroll
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn
    return btn
end

CreateHeader("Background", 1)

local BgColorsFrame = Instance.new("Frame")
BgColorsFrame.Size = UDim2.new(1, -10, 0, 30)
BgColorsFrame.BackgroundTransparency = 1
BgColorsFrame.LayoutOrder = 2
BgColorsFrame.Parent = SettingsScroll

local cList = Instance.new("UIListLayout")
cList.FillDirection = Enum.FillDirection.Horizontal
cList.Padding = UDim.new(0, 8)
cList.Parent = BgColorsFrame

local function AddColorBtn(col)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 30, 0, 30)
    b.BackgroundColor3 = col
    b.Text = ""
    b.Parent = BgColorsFrame
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = b
    b.MouseButton1Click:Connect(function()
        MainFrame.BackgroundColor3 = col
        if RestoreButton then
            RestoreButton.BackgroundColor3 = col
        end
        MinimizeButton.BackgroundColor3 = col
    end)
end

AddColorBtn(Color3.fromRGB(0, 0, 0))
AddColorBtn(Color3.fromRGB(128, 128, 128))
AddColorBtn(Color3.fromRGB(64, 128, 128))
AddColorBtn(Color3.fromRGB(128, 64, 128))
AddColorBtn(Color3.fromRGB(128, 128, 64))

CreateHeader("Others", 3)

local btnClear = CreateButton("Clear cache", 4)
local btnRejoin = CreateButton("Rejoin server", 5)
local btnHop = CreateButton("Switch server", 6)

btnClear.MouseButton1Click:Connect(function()
end)

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

task.spawn(function()
    SettingsScroll.CanvasSize = UDim2.new(0, 0, 0, SetList.AbsoluteContentSize.Y + 10)
end)

local FooterLeft = Instance.new("TextLabel")
FooterLeft.Size = UDim2.new(0.5, -5, 0, 20)
FooterLeft.Position = UDim2.new(0, 5, 1, -20)
FooterLeft.BackgroundTransparency = 1
FooterLeft.Text = '<i>Made by <b>Fonda888</b></i>'
FooterLeft.RichText = true
FooterLeft.TextColor3 = Color3.fromRGB(128, 128, 128)
FooterLeft.TextXAlignment = Enum.TextXAlignment.Left
FooterLeft.TextSize = 12
FooterLeft.Font = Enum.Font.SourceSans
FooterLeft.Parent = SettingsFrame

local FooterRight = Instance.new("TextLabel")
FooterRight.Size = UDim2.new(0.5, -5, 0, 20)
FooterRight.Position = UDim2.new(0.5, 0, 1, -20)
FooterRight.BackgroundTransparency = 1
FooterRight.Text = "v0.9 (BETA)"
FooterRight.TextColor3 = Color3.fromRGB(128, 128, 128)
FooterRight.TextXAlignment = Enum.TextXAlignment.Right
FooterRight.TextSize = 12
FooterRight.Font = Enum.Font.SourceSans
FooterRight.Parent = SettingsFrame

SettingsBtn.MouseButton1Click:Connect(function()
    SettingsFrame.Visible = not SettingsFrame.Visible
    OutputScroll.Visible = not SettingsFrame.Visible
end)

local dragging, dragStart, startPos = false, nil, nil

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
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        if dragging then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        elseif dragRestore and RestoreButton and RestoreButton.Visible then
            local delta = input.Position - dragStartRes
            if delta.Magnitude > 5 then
                hasDraggedRes = true
            end
            RestoreButton.Position = UDim2.new(
                startPosRes.X.Scale, startPosRes.X.Offset + delta.X,
                startPosRes.Y.Scale, startPosRes.Y.Offset + delta.Y
            )
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
