-- ========================================================
-- UI CORE MODULE
-- ========================================================
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local UI = {}
local MainColors = {
    Bg = Color3.fromRGB(64, 128, 128),     -- #408080
    Accent = Color3.fromRGB(64, 64, 64),   -- #404040
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
-- Converted #804040 to RGB (128, 64, 64) for mobile compatibility
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
    RestoreButton.TextSize = 18
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
InputBox.Size = UDim2.new(1, -20, 0, 35)
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

local logCount = 0
function UI.Log(text)
    logCount = logCount + 1
    local msg = Instance.new("TextLabel")
    msg.Size = UDim2.new(1, -10, 0, 0)
    msg.AutomaticSize = Enum.AutomaticSize.Y
    msg.BackgroundTransparency = 1
    msg.Text = "> " .. tostring(text)
    msg.TextColor3 = MainColors.Text
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
