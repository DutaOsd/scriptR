-- // Obby Helper Pro v3.2 - COMPLETE
-- // Clean ESP + Speed Meter + Anti-AFK + All Features

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

pcall(function() player.PlayerGui:FindFirstChild("ObbyHelperGUI"):Destroy() end)

-- ════════════════════════════════════════════
-- VARIABLES
-- ════════════════════════════════════════════
local ESP = {}
local Connections = {}
local ObstacleFolder = {}
local SpeedData = {}
local SelfSpeedData = {
    lastPos = nil, lastTime = 0, speed = 0,
    billboard = nil, label = nil, barFill = nil,
}

local Settings = {
    ObstacleTransparency = 0.7,
    ObstacleColor = Color3.fromRGB(255, 50, 50),
    SpeedValue = 32,
    JumpValue = 100
}

local ESP_SETTINGS = {
    MaxDistance = 1000,
    FadeStart = 600,
    TextSize = 13,
    MinTextSize = 8,
    NameOffset = 2.8,
    ShowDot = true,
    OutlineOnly = true,
}

local SPEED_SETTINGS = {
    Enabled = false,
    ShowSelf = true,
    ShowOthers = true,
    MaxSpeed = 100,
    UpdateRate = 0.1,
    SelfOffset = Vector3.new(0, 4.5, 0),
    OtherOffset = Vector3.new(0, 1.8, 0),
}

local ServerHopData = {
    Servers = {}, CurrentPage = 1, PerPage = 25,
    TotalPages = 1, IsLoading = false, SortMode = "players"
}

local PlayerAction = {
    SpectateTarget = nil, FollowTarget = nil,
    IsSpectating = false, IsFollowing = false, TPConfirmPending = false
}

local ToggleStates = {
    ESP = false, Obstacle = false, Speed = false, Jump = false,
    InfJump = false, Noclip = false, AntiVoid = false,
    Fullbright = false, AntiAFK = false, AutoJump = false,
}

local oldLighting = {}

-- ════════════════════════════════════════════
-- SCREEN GUI
-- ════════════════════════════════════════════
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ObbyHelperGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = player:WaitForChild("PlayerGui")

-- ════════════════════════════════════════════
-- MINIMIZED ICON
-- ════════════════════════════════════════════
local MinimizedBox = Instance.new("TextButton")
MinimizedBox.Size = isMobile and UDim2.new(0, 65, 0, 65) or UDim2.new(0, 55, 0, 55)
MinimizedBox.Position = isMobile and UDim2.new(0.82, 0, 0.1, 0) or UDim2.new(0.02, 0, 0.2, 0)
MinimizedBox.BackgroundColor3 = Color3.fromRGB(30, 30, 48)
MinimizedBox.Text = "🔥"
MinimizedBox.TextColor3 = Color3.new(1, 1, 1)
MinimizedBox.TextSize = isMobile and 32 or 26
MinimizedBox.Font = Enum.Font.GothamBold
MinimizedBox.Visible = false
MinimizedBox.Active = true
MinimizedBox.Draggable = true
MinimizedBox.ZIndex = 100
MinimizedBox.Parent = ScreenGui
Instance.new("UICorner", MinimizedBox).CornerRadius = UDim.new(0.3, 0)

local MinBoxStroke = Instance.new("UIStroke", MinimizedBox)
MinBoxStroke.Color = Color3.fromRGB(80, 100, 255)
MinBoxStroke.Thickness = 3

spawn(function()
    while ScreenGui.Parent do
        if MinimizedBox.Visible then
            TweenService:Create(MinBoxStroke, TweenInfo.new(1, Enum.EasingStyle.Sine), {
                Color = Color3.fromRGB(150, 170, 255)
            }):Play()
            task.wait(1)
            if MinimizedBox.Visible then
                TweenService:Create(MinBoxStroke, TweenInfo.new(1, Enum.EasingStyle.Sine), {
                    Color = Color3.fromRGB(80, 100, 255)
                }):Play()
            end
        end
        task.wait(1)
    end
end)

-- ════════════════════════════════════════════
-- MAIN FRAME
-- ════════════════════════════════════════════
local Main = Instance.new("Frame")
if isMobile then
    Main.Size = UDim2.new(0.93, 0, 0.8, 0)
    Main.Position = UDim2.new(0.035, 0, 0.1, 0)
else
    Main.Size = UDim2.new(0, 430, 0, 670)
    Main.Position = UDim2.new(0.02, 0, 0.03, 0)
end
Main.BackgroundColor3 = Color3.fromRGB(22, 22, 34)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = not isMobile
Main.ClipsDescendants = true
Main.ZIndex = 1
Main.Parent = ScreenGui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 14)
Instance.new("UIStroke", Main).Color = Color3.fromRGB(80, 100, 255)

-- ════════════════════════════════════════════
-- TITLE BAR
-- ════════════════════════════════════════════
local TitleBar = Instance.new("Frame")
TitleBar.Size = isMobile and UDim2.new(1, 0, 0, 60) or UDim2.new(1, 0, 0, 50)
TitleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 46)
TitleBar.BorderSizePixel = 0
TitleBar.ZIndex = 2
TitleBar.Parent = Main
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 14)

local TBarFix = Instance.new("Frame", TitleBar)
TBarFix.Size = UDim2.new(1, 0, 0.4, 0)
TBarFix.Position = UDim2.new(0, 0, 0.6, 0)
TBarFix.BackgroundColor3 = Color3.fromRGB(30, 30, 46)
TBarFix.BorderSizePixel = 0
TBarFix.ZIndex = 2

local Title = Instance.new("TextLabel", TitleBar)
Title.Size = UDim2.new(0.55, 0, 1, 0)
Title.Position = UDim2.new(0.04, 0, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "🔥 Obby Helper"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.TextSize = isMobile and 19 or 17
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.ZIndex = 3

local VerBadge = Instance.new("TextLabel", TitleBar)
VerBadge.Size = UDim2.new(0, 36, 0, 18)
VerBadge.Position = UDim2.new(0, isMobile and 165 or 148, 0.5, -9)
VerBadge.BackgroundColor3 = Color3.fromRGB(80, 100, 255)
VerBadge.Text = "v3.2"
VerBadge.TextColor3 = Color3.new(1, 1, 1)
VerBadge.TextSize = 9
VerBadge.Font = Enum.Font.GothamBold
VerBadge.ZIndex = 4
Instance.new("UICorner", VerBadge).CornerRadius = UDim.new(0, 6)

local MinimizeBtn = Instance.new("TextButton", TitleBar)
MinimizeBtn.Size = isMobile and UDim2.new(0, 40, 0, 40) or UDim2.new(0, 32, 0, 32)
MinimizeBtn.Position = isMobile and UDim2.new(1, -90, 0.5, -20) or UDim2.new(1, -76, 0.5, -16)
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(255, 175, 0)
MinimizeBtn.Text = "─"
MinimizeBtn.TextColor3 = Color3.new(1, 1, 1)
MinimizeBtn.TextSize = isMobile and 20 or 16
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.ZIndex = 3
MinimizeBtn.AutoButtonColor = false
Instance.new("UICorner", MinimizeBtn).CornerRadius = UDim.new(0.5, 0)

local CloseBtn = Instance.new("TextButton", TitleBar)
CloseBtn.Size = isMobile and UDim2.new(0, 40, 0, 40) or UDim2.new(0, 32, 0, 32)
CloseBtn.Position = isMobile and UDim2.new(1, -45, 0.5, -20) or UDim2.new(1, -40, 0.5, -16)
CloseBtn.BackgroundColor3 = Color3.fromRGB(220, 55, 55)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.new(1, 1, 1)
CloseBtn.TextSize = isMobile and 18 or 15
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.ZIndex = 3
CloseBtn.AutoButtonColor = false
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0.5, 0)

for _, pair in ipairs({
    {MinimizeBtn, Color3.fromRGB(255, 210, 50), Color3.fromRGB(255, 175, 0)},
    {CloseBtn, Color3.fromRGB(255, 80, 80), Color3.fromRGB(220, 55, 55)}
}) do
    pair[1].MouseEnter:Connect(function()
        TweenService:Create(pair[1], TweenInfo.new(0.15), {BackgroundColor3 = pair[2]}):Play()
    end)
    pair[1].MouseLeave:Connect(function()
        TweenService:Create(pair[1], TweenInfo.new(0.15), {BackgroundColor3 = pair[3]}):Play()
    end)
end

MinimizeBtn.MouseButton1Click:Connect(function()
    TweenService:Create(Main, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
        Size = UDim2.new(0, 0, 0, 0)
    }):Play()
    task.wait(0.3)
    Main.Visible = false
    MinimizedBox.Visible = true
    MinimizedBox.Size = UDim2.new(0, 0, 0, 0)
    TweenService:Create(MinimizedBox, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
        Size = isMobile and UDim2.new(0, 65, 0, 65) or UDim2.new(0, 55, 0, 55)
    }):Play()
end)

MinimizedBox.MouseButton1Click:Connect(function()
    TweenService:Create(MinimizedBox, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
        Size = UDim2.new(0, 0, 0, 0)
    }):Play()
    task.wait(0.2)
    MinimizedBox.Visible = false
    Main.Visible = true
    Main.Size = UDim2.new(0, 0, 0, 0)
    TweenService:Create(Main, TweenInfo.new(0.4, Enum.EasingStyle.Back), {
        Size = isMobile and UDim2.new(0.93, 0, 0.8, 0) or UDim2.new(0, 430, 0, 670)
    }):Play()
end)

-- ════════════════════════════════════════════
-- TAB SYSTEM
-- ════════════════════════════════════════════
local TabBarHeight = isMobile and 46 or 40
local TitleBarHeight = isMobile and 60 or 50

local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(1, 0, 0, TabBarHeight)
TabBar.Position = UDim2.new(0, 0, 0, TitleBarHeight)
TabBar.BackgroundColor3 = Color3.fromRGB(28, 28, 42)
TabBar.BorderSizePixel = 0
TabBar.ZIndex = 2
TabBar.Parent = Main
Instance.new("UIListLayout", TabBar).FillDirection = Enum.FillDirection.Horizontal

local currentTab = "main"
local TabFrames = {}
local TabButtons = {}

local function createTab(name, icon, layoutOrder)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.2, 0, 1, 0)
    btn.BackgroundColor3 = Color3.fromRGB(28, 28, 42)
    btn.Text = isMobile and icon or (icon .. " " .. name)
    btn.TextColor3 = Color3.fromRGB(120, 120, 150)
    btn.TextSize = isMobile and 15 or 11
    btn.Font = Enum.Font.GothamBold
    btn.ZIndex = 3
    btn.AutoButtonColor = false
    btn.LayoutOrder = layoutOrder
    btn.Parent = TabBar

    local indicator = Instance.new("Frame", btn)
    indicator.Size = UDim2.new(0.6, 0, 0, 3)
    indicator.Position = UDim2.new(0.2, 0, 1, -3)
    indicator.BackgroundColor3 = Color3.fromRGB(100, 120, 255)
    indicator.BorderSizePixel = 0
    indicator.ZIndex = 4
    indicator.Visible = false
    Instance.new("UICorner", indicator).CornerRadius = UDim.new(1, 0)

    TabButtons[name:lower()] = {Button = btn, Indicator = indicator}
    return btn
end

local function switchTab(tabName)
    currentTab = tabName
    for name, data in pairs(TabButtons) do
        local active = name == tabName
        data.Button.TextColor3 = active and Color3.new(1, 1, 1) or Color3.fromRGB(120, 120, 150)
        data.Button.BackgroundColor3 = active and Color3.fromRGB(38, 38, 56) or Color3.fromRGB(28, 28, 42)
        data.Indicator.Visible = active
    end
    for name, frame in pairs(TabFrames) do
        frame.Visible = name == tabName
    end
end

local tabBtns = {}
for _, t in ipairs({{"Main","⚙️",1},{"Players","👥",2},{"Servers","🌐",3},{"Extra","⭐",4},{"Info","ℹ️",5}}) do
    tabBtns[t[1]:lower()] = createTab(t[1], t[2], t[3])
end

-- ════════════════════════════════════════════
-- CONTENT FRAMES
-- ════════════════════════════════════════════
local contentY = TitleBarHeight + TabBarHeight + 5

local function createContentFrame(name)
    local frame = Instance.new("ScrollingFrame")
    frame.Size = UDim2.new(1, -10, 1, -(contentY + 5))
    frame.Position = UDim2.new(0, 5, 0, contentY)
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.ScrollBarThickness = isMobile and 5 or 4
    frame.ScrollBarImageColor3 = Color3.fromRGB(80, 100, 255)
    frame.CanvasSize = UDim2.new(0, 0, 0, 0)
    frame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    frame.ZIndex = 2
    frame.Visible = false
    frame.Parent = Main

    local pad = Instance.new("UIPadding", frame)
    pad.PaddingTop = UDim.new(0, 6)
    pad.PaddingBottom = UDim.new(0, 12)
    pad.PaddingLeft = UDim.new(0, 3)
    pad.PaddingRight = UDim.new(0, 3)

    local layout = Instance.new("UIListLayout", frame)
    layout.Padding = UDim.new(0, isMobile and 6 or 5)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center

    TabFrames[name] = frame
    return frame
end

local MainContent = createContentFrame("main")
local PlayersContent = createContentFrame("players")
local ServerContent = createContentFrame("servers")
local ExtraContent = createContentFrame("extra")
local InfoContent = createContentFrame("info")

for name, btn in pairs(tabBtns) do
    btn.MouseButton1Click:Connect(function()
        switchTab(name)
        if name == "players" then task.spawn(refreshPlayerList) end
    end)
end

-- ════════════════════════════════════════════
-- HELPER FUNCTIONS
-- ════════════════════════════════════════════
local function createCategory(text, parent, order)
    local lbl = Instance.new("TextLabel")
    lbl.Size = isMobile and UDim2.new(1, -4, 0, 28) or UDim2.new(1, -4, 0, 24)
    lbl.BackgroundColor3 = Color3.fromRGB(28, 28, 48)
    lbl.Text = "  " .. text
    lbl.TextColor3 = Color3.fromRGB(130, 150, 255)
    lbl.TextSize = isMobile and 13 or 11
    lbl.Font = Enum.Font.GothamBold
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 3
    lbl.LayoutOrder = order or 0
    lbl.Parent = parent
    Instance.new("UICorner", lbl).CornerRadius = UDim.new(0, 8)
end

local function createButton(text, parent, callback, order)
    local btn = Instance.new("TextButton")
    btn.Size = isMobile and UDim2.new(1, -4, 0, 50) or UDim2.new(1, -4, 0, 42)
    btn.BackgroundColor3 = Color3.fromRGB(42, 42, 60)
    btn.Text = text
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.TextSize = isMobile and 14 or 12
    btn.Font = Enum.Font.Gotham
    btn.ZIndex = 3
    btn.AutoButtonColor = false
    btn.LayoutOrder = order or 0
    btn.Parent = parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)
    Instance.new("UIStroke", btn).Color = Color3.fromRGB(55, 55, 80)

    btn.MouseEnter:Connect(function()
        if not btn:GetAttribute("active") then
            TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(55, 55, 78)}):Play()
        end
    end)
    btn.MouseLeave:Connect(function()
        if not btn:GetAttribute("active") then
            TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(42, 42, 60)}):Play()
        end
    end)

    if callback then btn.MouseButton1Click:Connect(callback) end
    return btn
end

local function setToggleVisual(btn, active)
    btn:SetAttribute("active", active)
    TweenService:Create(btn, TweenInfo.new(0.2), {
        BackgroundColor3 = active and Color3.fromRGB(30, 105, 40) or Color3.fromRGB(42, 42, 60)
    }):Play()
end

local function createSlider(labelText, parent, minVal, maxVal, default, suffix, callback, order)
    local container = Instance.new("Frame")
    container.Size = isMobile and UDim2.new(1, -4, 0, 75) or UDim2.new(1, -4, 0, 65)
    container.BackgroundColor3 = Color3.fromRGB(38, 38, 54)
    container.ZIndex = 3
    container.LayoutOrder = order or 0
    container.Parent = parent
    Instance.new("UICorner", container).CornerRadius = UDim.new(0, 10)

    local label = Instance.new("TextLabel", container)
    label.Size = UDim2.new(0.6, 0, 0, 22)
    label.Position = UDim2.new(0, 10, 0, 5)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextSize = isMobile and 12 or 10
    label.Font = Enum.Font.GothamBold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 4

    local valueLabel = Instance.new("TextLabel", container)
    valueLabel.Size = UDim2.new(0.35, 0, 0, 22)
    valueLabel.Position = UDim2.new(0.63, 0, 0, 5)
    valueLabel.BackgroundTransparency = 1
    valueLabel.TextColor3 = Color3.fromRGB(100, 190, 255)
    valueLabel.TextSize = isMobile and 12 or 10
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.ZIndex = 4

    suffix = suffix or ""
    local function formatVal(v)
        if suffix == "%" then return string.format("%.0f%%", v * 100)
        else return string.format("%.0f%s", v, suffix) end
    end
    valueLabel.Text = formatVal(default)

    local sliderBack = Instance.new("Frame", container)
    sliderBack.Size = UDim2.new(1, -20, 0, isMobile and 24 or 20)
    sliderBack.Position = UDim2.new(0, 10, 0, 33)
    sliderBack.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
    sliderBack.ZIndex = 4
    Instance.new("UICorner", sliderBack).CornerRadius = UDim.new(1, 0)

    local initFill = math.clamp((default - minVal) / (maxVal - minVal), 0, 1)

    local sliderFill = Instance.new("Frame", sliderBack)
    sliderFill.Size = UDim2.new(initFill, 0, 1, 0)
    sliderFill.BackgroundColor3 = Color3.fromRGB(70, 100, 255)
    sliderFill.ZIndex = 5
    Instance.new("UICorner", sliderFill).CornerRadius = UDim.new(1, 0)

    local kSize = isMobile and 20 or 16
    local knob = Instance.new("Frame", sliderBack)
    knob.Size = UDim2.new(0, kSize, 0, kSize)
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Position = UDim2.new(initFill, 0, 0.5, 0)
    knob.BackgroundColor3 = Color3.fromRGB(220, 230, 255)
    knob.ZIndex = 7
    Instance.new("UICorner", knob).CornerRadius = UDim.new(0.5, 0)
    local ks = Instance.new("UIStroke", knob)
    ks.Color = Color3.fromRGB(80, 100, 255)
    ks.Thickness = 2

    local sliderBtn = Instance.new("TextButton", sliderBack)
    sliderBtn.Size = UDim2.new(1, 0, 1, 0)
    sliderBtn.BackgroundTransparency = 1
    sliderBtn.Text = ""
    sliderBtn.ZIndex = 8

    local dragging = false
    local function updateFromX(absX)
        local rel = math.clamp((absX - sliderBack.AbsolutePosition.X) / sliderBack.AbsoluteSize.X, 0, 1)
        local value = minVal + (maxVal - minVal) * rel
        sliderFill.Size = UDim2.new(rel, 0, 1, 0)
        knob.Position = UDim2.new(rel, 0, 0.5, 0)
        valueLabel.Text = formatVal(value)
        if callback then callback(value) end
    end

    sliderBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; updateFromX(input.Position.X)
        end
    end)
    sliderBtn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    table.insert(Connections, UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            updateFromX(input.Position.X)
        end
    end))
end

local function createWarningBox(text, parent, order)
    local box = Instance.new("Frame")
    box.Size = UDim2.new(1, -4, 0, 0)
    box.AutomaticSize = Enum.AutomaticSize.Y
    box.BackgroundColor3 = Color3.fromRGB(75, 25, 25)
    box.ZIndex = 3
    box.LayoutOrder = order or 0
    box.Parent = parent
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 10)
    Instance.new("UIStroke", box).Color = Color3.fromRGB(220, 70, 70)

    local wl = Instance.new("TextLabel", box)
    wl.Size = UDim2.new(1, 0, 0, 0)
    wl.AutomaticSize = Enum.AutomaticSize.Y
    wl.BackgroundTransparency = 1
    wl.Text = text
    wl.TextColor3 = Color3.fromRGB(255, 195, 195)
    wl.TextSize = isMobile and 12 or 10
    wl.Font = Enum.Font.Gotham
    wl.TextWrapped = true
    wl.RichText = true
    wl.TextXAlignment = Enum.TextXAlignment.Left
    wl.ZIndex = 4
    local wp = Instance.new("UIPadding", wl)
    wp.PaddingTop = UDim.new(0, 10); wp.PaddingBottom = UDim.new(0, 10)
    wp.PaddingLeft = UDim.new(0, 12); wp.PaddingRight = UDim.new(0, 12)
end

-- ════════════════════════════════════════════
-- NOTIFICATION
-- ════════════════════════════════════════════
local NotifFrame = Instance.new("Frame")
NotifFrame.Size = UDim2.new(0, 280, 0, 55)
NotifFrame.Position = UDim2.new(0.5, -140, 0, -70)
NotifFrame.BackgroundColor3 = Color3.fromRGB(30, 40, 60)
NotifFrame.BorderSizePixel = 0
NotifFrame.ZIndex = 200
NotifFrame.Parent = ScreenGui
Instance.new("UICorner", NotifFrame).CornerRadius = UDim.new(0, 12)
Instance.new("UIStroke", NotifFrame).Color = Color3.fromRGB(80, 120, 255)

local NotifText = Instance.new("TextLabel", NotifFrame)
NotifText.Size = UDim2.new(1, -20, 1, 0)
NotifText.Position = UDim2.new(0, 10, 0, 0)
NotifText.BackgroundTransparency = 1
NotifText.TextSize = 13
NotifText.Font = Enum.Font.GothamBold
NotifText.TextColor3 = Color3.new(1, 1, 1)
NotifText.TextWrapped = true
NotifText.ZIndex = 201

local notifActive = false
local function showNotif(text, color)
    if notifActive then return end
    notifActive = true
    NotifText.Text = text
    NotifFrame.BackgroundColor3 = color or Color3.fromRGB(30, 40, 60)
    TweenService:Create(NotifFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back), {
        Position = UDim2.new(0.5, -140, 0, 15)
    }):Play()
    task.wait(2.5)
    TweenService:Create(NotifFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
        Position = UDim2.new(0.5, -140, 0, -70)
    }):Play()
    task.wait(0.3)
    notifActive = false
end

-- ════════════════════════════════════════════
-- SPEED METER HELPERS
-- ════════════════════════════════════════════
local function getSpeedColor(speed)
    if speed <= 5 then return Color3.fromRGB(150, 150, 180)
    elseif speed <= 20 then return Color3.fromRGB(100, 220, 100)
    elseif speed <= 50 then return Color3.fromRGB(255, 200, 50)
    elseif speed <= 100 then return Color3.fromRGB(255, 120, 50)
    else return Color3.fromRGB(255, 60, 60) end
end

local function getSpeedIcon(speed)
    if speed <= 2 then return "🔴"
    elseif speed <= 16 then return "🚶"
    elseif speed <= 32 then return "🏃"
    elseif speed <= 60 then return "💨"
    else return "⚡" end
end

-- ════════════════════════════════════════════
-- SELF SPEED BILLBOARD
-- ════════════════════════════════════════════
local function createSelfSpeedBillboard()
    if SelfSpeedData.billboard then
        pcall(function() SelfSpeedData.billboard:Destroy() end)
    end

    if not player.Character then return end
    local head = player.Character:FindFirstChild("Head")
    if not head then return end

    local bb = Instance.new("BillboardGui")
    bb.Name = "SelfSpeedBB"
    bb.Adornee = head
    bb.AlwaysOnTop = true
    bb.LightInfluence = 0
    bb.StudsOffset = SPEED_SETTINGS.SelfOffset
    bb.Size = UDim2.new(0, 180, 0, 40)
    bb.Parent = ScreenGui

    local container = Instance.new("Frame", bb)
    container.Size = UDim2.new(1, 0, 1, 0)
    container.BackgroundTransparency = 1
    container.BorderSizePixel = 0

    -- Speed Label
    local label = Instance.new("TextLabel", container)
    label.Size = UDim2.new(1, 0, 0, 17)
    label.BackgroundTransparency = 1
    label.Text = "🔴 0.0 st/s"
    label.TextColor3 = Color3.fromRGB(200, 200, 255)
    label.TextSize = 13
    label.Font = Enum.Font.GothamBold
    label.TextStrokeTransparency = 0.2
    label.TextStrokeColor3 = Color3.new(0, 0, 0)
    label.ZIndex = 2

    -- YOU Badge
    local youBadge = Instance.new("TextLabel", container)
    youBadge.Size = UDim2.new(0, 34, 0, 13)
    youBadge.Position = UDim2.new(0, 0, 0, 18)
    youBadge.BackgroundColor3 = Color3.fromRGB(80, 100, 220)
    youBadge.Text = "YOU"
    youBadge.TextColor3 = Color3.new(1, 1, 1)
    youBadge.TextSize = 8
    youBadge.Font = Enum.Font.GothamBold
    youBadge.ZIndex = 3
    Instance.new("UICorner", youBadge).CornerRadius = UDim.new(0, 4)

    -- Speed Bar
    local barBG = Instance.new("Frame", container)
    barBG.Size = UDim2.new(1, -40, 0, 6)
    barBG.Position = UDim2.new(0, 38, 0, 21)
    barBG.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
    barBG.BorderSizePixel = 0
    Instance.new("UICorner", barBG).CornerRadius = UDim.new(1, 0)

    local barFill = Instance.new("Frame", barBG)
    barFill.Size = UDim2.new(0, 0, 1, 0)
    barFill.BackgroundColor3 = Color3.fromRGB(100, 220, 100)
    barFill.BorderSizePixel = 0
    Instance.new("UICorner", barFill).CornerRadius = UDim.new(1, 0)

    SelfSpeedData.billboard = bb
    SelfSpeedData.label = label
    SelfSpeedData.barFill = barFill
    SelfSpeedData.lastPos = nil
    SelfSpeedData.lastTime = tick()
    SelfSpeedData.speed = 0
end

-- ════════════════════════════════════════════
-- OTHER PLAYER SPEED BILLBOARD
-- ════════════════════════════════════════════
local function createPlayerSpeedBB(plr)
    if plr == player then return end
    if not plr.Character then return end

    if SpeedData[plr] and SpeedData[plr].billboard then
        pcall(function() SpeedData[plr].billboard:Destroy() end)
    end

    local head = plr.Character:FindFirstChild("Head")
    if not head then return end

    local bb = Instance.new("BillboardGui")
    bb.Name = "SpeedBB_" .. plr.Name
    bb.Adornee = head
    bb.AlwaysOnTop = true
    bb.LightInfluence = 0
    bb.StudsOffset = SPEED_SETTINGS.OtherOffset
    bb.Size = UDim2.new(0, 120, 0, 14)
    bb.MaxDistance = ESP_SETTINGS.MaxDistance
    bb.Parent = ScreenGui

    local label = Instance.new("TextLabel", bb)
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = "🔴 0.0 st/s"
    label.TextColor3 = Color3.fromRGB(150, 150, 180)
    label.TextSize = 10
    label.Font = Enum.Font.GothamBold
    label.TextStrokeTransparency = 0.3
    label.TextStrokeColor3 = Color3.new(0, 0, 0)

    if not SpeedData[plr] then
        SpeedData[plr] = {lastPos = nil, lastTime = tick(), speed = 0}
    end
    SpeedData[plr].billboard = bb
    SpeedData[plr].label = label
    SpeedData[plr].char = plr.Character
end

local function removePlayerSpeedBB(plr)
    if SpeedData[plr] then
        pcall(function()
            if SpeedData[plr].billboard then SpeedData[plr].billboard:Destroy() end
        end)
        SpeedData[plr] = nil
    end
end

-- ════════════════════════════════════════════
-- SPEED UPDATE LOOP
-- ════════════════════════════════════════════
local lastSpeedUpdate = 0

local function updateAllSpeeds()
    local now = tick()
    if now - lastSpeedUpdate < SPEED_SETTINGS.UpdateRate then return end
    lastSpeedUpdate = now

    -- SELF
    if SPEED_SETTINGS.ShowSelf and SelfSpeedData.billboard then
        pcall(function()
            local char = player.Character
            if not char then return end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end

            local currentPos = hrp.Position
            if SelfSpeedData.lastPos then
                local dt = now - SelfSpeedData.lastTime
                if dt > 0 then
                    local rawSpeed = (currentPos - SelfSpeedData.lastPos).Magnitude / dt
                    SelfSpeedData.speed = SelfSpeedData.speed * 0.6 + rawSpeed * 0.4
                end
            end
            SelfSpeedData.lastPos = currentPos
            SelfSpeedData.lastTime = now

            local speed = SelfSpeedData.speed
            local speedColor = getSpeedColor(speed)
            local speedIcon = getSpeedIcon(speed)
            local barRatio = math.clamp(speed / SPEED_SETTINGS.MaxSpeed, 0, 1)

            if SelfSpeedData.label then
                SelfSpeedData.label.Text = string.format("%s %.1f st/s", speedIcon, speed)
                SelfSpeedData.label.TextColor3 = speedColor
            end
            if SelfSpeedData.barFill then
                SelfSpeedData.barFill.Size = UDim2.new(barRatio, 0, 1, 0)
                SelfSpeedData.barFill.BackgroundColor3 = speedColor
            end
        end)
    end

    -- OTHERS
    if SPEED_SETTINGS.ShowOthers then
        local localHRP = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        for plr, data in pairs(SpeedData) do
            pcall(function()
                if not plr or not plr.Parent then removePlayerSpeedBB(plr) return end

                local char = plr.Character
                if not char then return end

                if data.char ~= char then
                    removePlayerSpeedBB(plr)
                    task.delay(0.5, function()
                        if SPEED_SETTINGS.Enabled and plr and plr.Parent then
                            createPlayerSpeedBB(plr)
                        end
                    end)
                    return
                end

                local hrp = char:FindFirstChild("HumanoidRootPart")
                local hum = char:FindFirstChildOfClass("Humanoid")
                if not hrp or not hum then return end

                local currentPos = hrp.Position
                if data.lastPos then
                    local dt = now - data.lastTime
                    if dt > 0 then
                        local rawSpeed = (currentPos - data.lastPos).Magnitude / dt
                        data.speed = (data.speed or 0) * 0.6 + rawSpeed * 0.4
                    end
                end
                data.lastPos = currentPos
                data.lastTime = now

                local speed = data.speed or 0
                local speedColor = getSpeedColor(speed)
                local speedIcon = getSpeedIcon(speed)

                -- Fade berdasarkan jarak
                local fadeAlpha = 1
                if localHRP then
                    local dist = (localHRP.Position - hrp.Position).Magnitude
                    if dist > ESP_SETTINGS.FadeStart then
                        fadeAlpha = 1 - math.clamp(
                            (dist - ESP_SETTINGS.FadeStart) / (ESP_SETTINGS.MaxDistance - ESP_SETTINGS.FadeStart), 0, 1
                        )
                    end
                end

                if data.label then
                    data.label.Text = string.format("%s %.1f st/s", speedIcon, speed)
                    data.label.TextColor3 = speedColor
                    data.label.TextTransparency = 1 - fadeAlpha
                    data.label.TextStrokeTransparency = 0.3 + (1 - fadeAlpha) * 0.7
                end
                if data.billboard then
                    data.billboard.Enabled = hum.Health > 0
                end
            end)
        end
    end
end

-- ════════════════════════════════════════════
-- ESP SYSTEM
-- ════════════════════════════════════════════
local function cleanupPlayerESP(plr)
    if ESP[plr] then
        pcall(function()
            for _, obj in pairs(ESP[plr]) do
                if typeof(obj) == "Instance" then obj:Destroy() end
            end
        end)
        ESP[plr] = nil
    end
end

local function createPlayerESP(plr)
    if plr == player then return end
    cleanupPlayerESP(plr)
    if not plr.Character then return end

    pcall(function()
        local char = plr.Character
        local head = char:FindFirstChild("Head")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not head or not hum then return end

        local espData = {}

        -- Highlight
        local highlight = Instance.new("Highlight")
        highlight.Adornee = char
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.FillTransparency = 1
        highlight.OutlineTransparency = 0.3
        highlight.FillColor = Color3.new(0, 0, 0)
        highlight.OutlineColor = Color3.fromRGB(0, 255, 120)
        highlight.Parent = ScreenGui
        espData.Highlight = highlight

        -- Billboard
        local billboard = Instance.new("BillboardGui")
        billboard.Adornee = head
        billboard.AlwaysOnTop = true
        billboard.LightInfluence = 0
        billboard.StudsOffset = Vector3.new(0, ESP_SETTINGS.NameOffset, 0)
        billboard.Size = UDim2.new(0, 140, 0, 42)
        billboard.MaxDistance = ESP_SETTINGS.MaxDistance
        billboard.Parent = ScreenGui
        espData.Billboard = billboard

        local container = Instance.new("Frame", billboard)
        container.Size = UDim2.new(1, 0, 1, 0)
        container.BackgroundTransparency = 1
        container.BorderSizePixel = 0

        -- Name
        local nameLabel = Instance.new("TextLabel", container)
        nameLabel.Size = UDim2.new(1, 0, 0, 14)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = plr.Name
        nameLabel.TextColor3 = Color3.new(1, 1, 1)
        nameLabel.TextSize = ESP_SETTINGS.TextSize
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextStrokeTransparency = 0.2
        nameLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
        espData.NameLabel = nameLabel

        -- Info
        local infoLabel = Instance.new("TextLabel", container)
        infoLabel.Size = UDim2.new(1, 0, 0, 12)
        infoLabel.Position = UDim2.new(0, 0, 0, 14)
        infoLabel.BackgroundTransparency = 1
        infoLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        infoLabel.TextSize = ESP_SETTINGS.TextSize - 3
        infoLabel.Font = Enum.Font.Gotham
        infoLabel.TextStrokeTransparency = 0.3
        infoLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
        espData.InfoLabel = infoLabel

        -- HP Bar
        local hpBG = Instance.new("Frame", container)
        hpBG.Size = UDim2.new(0.8, 0, 0, 3)
        hpBG.Position = UDim2.new(0.1, 0, 0, 28)
        hpBG.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        hpBG.BackgroundTransparency = 0.3
        hpBG.BorderSizePixel = 0
        Instance.new("UICorner", hpBG).CornerRadius = UDim.new(1, 0)
        espData.HpBG = hpBG

        local hpFill = Instance.new("Frame", hpBG)
        hpFill.Size = UDim2.new(1, 0, 1, 0)
        hpFill.BackgroundColor3 = Color3.fromRGB(0, 220, 80)
        hpFill.BorderSizePixel = 0
        Instance.new("UICorner", hpFill).CornerRadius = UDim.new(1, 0)
        espData.HpFill = hpFill

        -- Head Dot
        if ESP_SETTINGS.ShowDot then
            local dotBB = Instance.new("BillboardGui")
            dotBB.Adornee = head
            dotBB.AlwaysOnTop = true
            dotBB.LightInfluence = 0
            dotBB.Size = UDim2.new(0.4, 0, 0.4, 0)
            dotBB.MaxDistance = ESP_SETTINGS.MaxDistance
            dotBB.Parent = ScreenGui
            espData.DotBillboard = dotBB

            local dot = Instance.new("Frame", dotBB)
            dot.Size = UDim2.new(0.6, 0, 0.6, 0)
            dot.Position = UDim2.new(0.2, 0, 0.2, 0)
            dot.BackgroundColor3 = Color3.new(1, 1, 1)
            dot.BorderSizePixel = 0
            Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
            espData.Dot = dot

            local ds = Instance.new("UIStroke", dot)
            ds.Color = Color3.new(0, 0, 0)
            ds.Thickness = 1
            espData.DotStroke = ds
        end

        espData.Char = char
        ESP[plr] = espData
    end)
end

local function updateAllESP()
    local localChar = player.Character
    local localHRP = localChar and localChar:FindFirstChild("HumanoidRootPart")

    for plr, data in pairs(ESP) do
        local ok = pcall(function()
            if not plr or not plr.Parent then cleanupPlayerESP(plr) return end

            local char = plr.Character
            if not char then cleanupPlayerESP(plr) return end

            if data.Char ~= char then
                cleanupPlayerESP(plr)
                task.delay(0.5, function()
                    if ToggleStates.ESP and plr and plr.Parent and plr.Character then
                        createPlayerESP(plr)
                    end
                end)
                return
            end

            local hum = char:FindFirstChildOfClass("Humanoid")
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hum or not hrp then cleanupPlayerESP(plr) return end

            local alive = hum.Health > 0
            if data.Billboard then data.Billboard.Enabled = alive end
            if data.DotBillboard then data.DotBillboard.Enabled = alive end
            if data.Highlight then data.Highlight.Enabled = alive end
            if not alive then return end

            local distance = localHRP and math.floor((localHRP.Position - hrp.Position).Magnitude) or 0

            local distColor
            if distance <= 30 then distColor = Color3.fromRGB(255, 70, 70)
            elseif distance <= 80 then distColor = Color3.fromRGB(255, 200, 60)
            elseif distance <= 200 then distColor = Color3.fromRGB(100, 255, 120)
            else distColor = Color3.fromRGB(100, 180, 255) end

            local fadeAlpha = 1
            if distance > ESP_SETTINGS.FadeStart then
                fadeAlpha = 1 - math.clamp(
                    (distance - ESP_SETTINGS.FadeStart) / (ESP_SETTINGS.MaxDistance - ESP_SETTINGS.FadeStart), 0, 1
                )
            end

            local dynSize = math.clamp(ESP_SETTINGS.TextSize - (distance / 80), ESP_SETTINGS.MinTextSize, ESP_SETTINGS.TextSize)

            if data.Highlight then
                data.Highlight.OutlineColor = distColor
                data.Highlight.OutlineTransparency = 0.3 + (1 - fadeAlpha) * 0.7
                data.Highlight.FillTransparency = 1
            end

            if data.NameLabel then
                data.NameLabel.Text = plr.Name
                data.NameLabel.TextColor3 = distColor
                data.NameLabel.TextSize = math.floor(dynSize)
                data.NameLabel.TextTransparency = 1 - fadeAlpha
                data.NameLabel.TextStrokeTransparency = 0.2 + (1 - fadeAlpha) * 0.8
            end

            if data.InfoLabel then
                local hpPct = math.floor((hum.Health / hum.MaxHealth) * 100)
                data.InfoLabel.Text = string.format("%dm • %d%%", distance, hpPct)
                data.InfoLabel.TextColor3 = Color3.fromRGB(
                    math.floor(distColor.R * 255 * 0.7 + 60),
                    math.floor(distColor.G * 255 * 0.7 + 60),
                    math.floor(distColor.B * 255 * 0.7 + 60)
                )
                data.InfoLabel.TextSize = math.floor(dynSize - 2)
                data.InfoLabel.TextTransparency = 1 - fadeAlpha
                data.InfoLabel.TextStrokeTransparency = 0.3 + (1 - fadeAlpha) * 0.7
            end

            if data.HpFill then
                local hpR = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                data.HpFill.Size = UDim2.new(hpR, 0, 1, 0)
                data.HpFill.BackgroundColor3 = Color3.fromRGB(math.floor(255*(1-hpR)), math.floor(255*hpR), 30)
            end
            if data.HpBG then
                data.HpBG.BackgroundTransparency = 0.3 + (1 - fadeAlpha) * 0.7
            end

            if data.Dot then
                data.Dot.BackgroundColor3 = distColor
                data.Dot.BackgroundTransparency = 1 - fadeAlpha
            end
            if data.DotStroke then data.DotStroke.Transparency = 1 - fadeAlpha end

            if data.Billboard then
                local scale = math.clamp(1 - (distance / 800), 0.5, 1)
                data.Billboard.Size = UDim2.new(0, math.floor(140 * scale), 0, math.floor(42 * scale))
            end
            if data.DotBillboard then
                local ds2 = math.clamp(0.5 - (distance / 2000), 0.15, 0.5)
                data.DotBillboard.Size = UDim2.new(ds2, 0, ds2, 0)
            end
        end)
        if not ok then cleanupPlayerESP(plr) end
    end
end

-- ════════════════════════════════════════════
-- MAIN TAB
-- ════════════════════════════════════════════
createCategory("📡 ESP & Vision", MainContent, 1)

-- ESP Toggle
local PlayerESPToggle = createButton("❌ Player ESP: OFF", MainContent, nil, 2)
PlayerESPToggle.MouseButton1Click:Connect(function()
    ToggleStates.ESP = not ToggleStates.ESP
    PlayerESPToggle.Text = ToggleStates.ESP and "✅ Player ESP: ON" or "❌ Player ESP: OFF"
    setToggleVisual(PlayerESPToggle, ToggleStates.ESP)

    if ToggleStates.ESP then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= player then createPlayerESP(plr) end
        end
        Connections.UpdateESP = RunService.Heartbeat:Connect(updateAllESP)
        showNotif("👁️ Clean ESP: ON", Color3.fromRGB(20, 70, 40))
    else
        if Connections.UpdateESP then Connections.UpdateESP:Disconnect() Connections.UpdateESP = nil end
        for plr in pairs(ESP) do cleanupPlayerESP(plr) end
        ESP = {}
        showNotif("👁️ ESP: OFF", Color3.fromRGB(70, 20, 20))
    end
end)

-- Speed Meter Toggle
local SpeedMeterToggle = createButton("❌ Speed Meter: OFF", MainContent, nil, 3)
SpeedMeterToggle.MouseButton1Click:Connect(function()
    SPEED_SETTINGS.Enabled = not SPEED_SETTINGS.Enabled
    SpeedMeterToggle.Text = SPEED_SETTINGS.Enabled and "✅ Speed Meter: ON" or "❌ Speed Meter: OFF"
    setToggleVisual(SpeedMeterToggle, SPEED_SETTINGS.Enabled)

    if SPEED_SETTINGS.Enabled then
        createSelfSpeedBillboard()
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= player then createPlayerSpeedBB(plr) end
        end
        Connections.SpeedUpdate = RunService.Heartbeat:Connect(updateAllSpeeds)
        showNotif("⚡ Speed Meter: ON", Color3.fromRGB(20, 70, 40))
    else
        if Connections.SpeedUpdate then Connections.SpeedUpdate:Disconnect() Connections.SpeedUpdate = nil end
        if SelfSpeedData.billboard then
            pcall(function() SelfSpeedData.billboard:Destroy() end)
            SelfSpeedData.billboard = nil
            SelfSpeedData.label = nil
            SelfSpeedData.barFill = nil
        end
        for plr in pairs(SpeedData) do removePlayerSpeedBB(plr) end
        SpeedData = {}
        showNotif("⚡ Speed Meter: OFF", Color3.fromRGB(70, 20, 20))
    end
end)

-- Obstacle
local ObstacleToggle = createButton("❌ Obstacle Visualizer: OFF", MainContent, nil, 4)

local function clearObstacles()
    for part, data in pairs(ObstacleFolder) do
        pcall(function()
            if part and part.Parent then
                part.Transparency = data.OT; part.Color = data.OC; part.Material = data.OM
            end
            if data.HL then data.HL:Destroy() end
        end)
    end
    ObstacleFolder = {}
end

ObstacleToggle.MouseButton1Click:Connect(function()
    ToggleStates.Obstacle = not ToggleStates.Obstacle
    ObstacleToggle.Text = ToggleStates.Obstacle and "✅ Obstacle Visualizer: ON" or "❌ Obstacle Visualizer: OFF"
    setToggleVisual(ObstacleToggle, ToggleStates.Obstacle)

    if ToggleStates.Obstacle then
        local count = 0
        for _, part in ipairs(Workspace:GetDescendants()) do
            pcall(function()
                if part:IsA("BasePart") and part.CanCollide and part.Transparency >= 0.85 and not ObstacleFolder[part] then
                    local hl = Instance.new("Highlight")
                    hl.FillColor = Settings.ObstacleColor
                    hl.OutlineColor = Color3.fromRGB(255, 255, 0)
                    hl.FillTransparency = Settings.ObstacleTransparency
                    hl.Adornee = part
                    hl.Parent = part
                    ObstacleFolder[part] = {OT = part.Transparency, OC = part.Color, OM = part.Material, HL = hl}
                    part.Transparency = Settings.ObstacleTransparency
                    part.Color = Settings.ObstacleColor
                    part.Material = Enum.Material.Neon
                    count += 1
                end
            end)
        end
        showNotif("🧱 Found " .. count .. " obstacles", Color3.fromRGB(80, 50, 20))
    else
        clearObstacles()
    end
end)

createSlider("🎚️ Obstacle Transparency", MainContent, 0.1, 0.95, Settings.ObstacleTransparency, "%", function(v)
    Settings.ObstacleTransparency = v
    if ToggleStates.Obstacle then
        for part, data in pairs(ObstacleFolder) do
            pcall(function()
                if part and part.Parent then
                    part.Transparency = v
                    if data.HL then data.HL.FillTransparency = v end
                end
            end)
        end
    end
end, 5)

-- Movement
createCategory("⚡ Movement", MainContent, 10)

local function applySpeed()
    pcall(function()
        if player.Character then
            local h = player.Character:FindFirstChildOfClass("Humanoid")
            if h then h.WalkSpeed = ToggleStates.Speed and Settings.SpeedValue or 16 end
        end
    end)
end

local SpeedToggle = createButton("❌ Speed Boost: OFF", MainContent, nil, 11)
SpeedToggle.MouseButton1Click:Connect(function()
    ToggleStates.Speed = not ToggleStates.Speed
    SpeedToggle.Text = ToggleStates.Speed and "✅ Speed Boost: ON" or "❌ Speed Boost: OFF"
    setToggleVisual(SpeedToggle, ToggleStates.Speed)
    applySpeed()
end)

createSlider("🏃 Speed Value", MainContent, 16, 200, Settings.SpeedValue, "", function(v)
    Settings.SpeedValue = math.floor(v)
    if ToggleStates.Speed then applySpeed() end
end, 12)

local function applyJump()
    pcall(function()
        if player.Character then
            local h = player.Character:FindFirstChildOfClass("Humanoid")
            if h then h.UseJumpPower = true; h.JumpPower = ToggleStates.Jump and Settings.JumpValue or 50 end
        end
    end)
end

local JumpToggle = createButton("❌ Jump Power: OFF", MainContent, nil, 13)
JumpToggle.MouseButton1Click:Connect(function()
    ToggleStates.Jump = not ToggleStates.Jump
    JumpToggle.Text = ToggleStates.Jump and "✅ Jump Power: ON" or "❌ Jump Power: OFF"
    setToggleVisual(JumpToggle, ToggleStates.Jump)
    applyJump()
end)

createSlider("🦘 Jump Value", MainContent, 50, 350, Settings.JumpValue, "", function(v)
    Settings.JumpValue = math.floor(v)
    if ToggleStates.Jump then applyJump() end
end, 14)

local InfJumpToggle = createButton("❌ Infinite Jump: OFF", MainContent, nil, 15)
InfJumpToggle.MouseButton1Click:Connect(function()
    ToggleStates.InfJump = not ToggleStates.InfJump
    InfJumpToggle.Text = ToggleStates.InfJump and "✅ Infinite Jump: ON" or "❌ Infinite Jump: OFF"
    setToggleVisual(InfJumpToggle, ToggleStates.InfJump)
end)

Connections.InfJump = UserInputService.JumpRequest:Connect(function()
    if not ToggleStates.InfJump then return end
    pcall(function()
        local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if h and h:GetState() ~= Enum.HumanoidStateType.Dead then
            h:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end)
end)

local NoclipToggle = createButton("❌ Noclip: OFF", MainContent, nil, 16)
NoclipToggle.MouseButton1Click:Connect(function()
    ToggleStates.Noclip = not ToggleStates.Noclip
    NoclipToggle.Text = ToggleStates.Noclip and "✅ Noclip: ON" or "❌ Noclip: OFF"
    setToggleVisual(NoclipToggle, ToggleStates.Noclip)

    if ToggleStates.Noclip then
        Connections.Noclip = RunService.Stepped:Connect(function()
            pcall(function()
                if not player.Character then return end
                for _, p in ipairs(player.Character:GetDescendants()) do
                    if p:IsA("BasePart") then p.CanCollide = false end
                end
            end)
        end)
    else
        if Connections.Noclip then Connections.Noclip:Disconnect() Connections.Noclip = nil end
        pcall(function()
            if player.Character then
                for _, p in ipairs(player.Character:GetDescendants()) do
                    if p:IsA("BasePart") then p.CanCollide = true end
                end
            end
        end)
    end
end)

local AntiVoidToggle = createButton("❌ Anti-Void: OFF", MainContent, nil, 17)
AntiVoidToggle.MouseButton1Click:Connect(function()
    ToggleStates.AntiVoid = not ToggleStates.AntiVoid
    AntiVoidToggle.Text = ToggleStates.AntiVoid and "✅ Anti-Void: ON" or "❌ Anti-Void: OFF"
    setToggleVisual(AntiVoidToggle, ToggleStates.AntiVoid)

    if ToggleStates.AntiVoid then
        local lastSafe, lastTime = nil, 0
        Connections.AntiVoid = RunService.Heartbeat:Connect(function()
            pcall(function()
                if not player.Character then return end
                local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                if not hrp then return end
                if hrp.Position.Y > -50 and tick() - lastTime > 2 then
                    lastSafe = hrp.CFrame; lastTime = tick()
                end
                if hrp.Position.Y < -80 then
                    hrp.CFrame = lastSafe and (lastSafe + Vector3.new(0, 10, 0)) or CFrame.new(hrp.Position.X, 80, hrp.Position.Z)
                    showNotif("🛡️ Anti-Void saved you!", Color3.fromRGB(20, 60, 100))
                end
            end)
        end)
    else
        if Connections.AntiVoid then Connections.AntiVoid:Disconnect() Connections.AntiVoid = nil end
    end
end)

-- Visual
createCategory("👁️ Visual", MainContent, 20)

local FullbrightToggle = createButton("❌ Fullbright: OFF", MainContent, nil, 21)
FullbrightToggle.MouseButton1Click:Connect(function()
    ToggleStates.Fullbright = not ToggleStates.Fullbright
    FullbrightToggle.Text = ToggleStates.Fullbright and "✅ Fullbright: ON" or "❌ Fullbright: OFF"
    setToggleVisual(FullbrightToggle, ToggleStates.Fullbright)

    if ToggleStates.Fullbright then
        oldLighting = {
            Ambient = Lighting.Ambient, Brightness = Lighting.Brightness,
            OutdoorAmbient = Lighting.OutdoorAmbient, ClockTime = Lighting.ClockTime,
            FogEnd = Lighting.FogEnd, GlobalShadows = Lighting.GlobalShadows
        }
        Lighting.Ambient = Color3.new(1,1,1); Lighting.Brightness = 2
        Lighting.OutdoorAmbient = Color3.new(1,1,1); Lighting.ClockTime = 12
        Lighting.FogEnd = 100000; Lighting.GlobalShadows = false
        for _, v in ipairs(Lighting:GetChildren()) do
            if v:IsA("Atmosphere") or v:IsA("BloomEffect") or v:IsA("DepthOfFieldEffect") then v.Enabled = false end
        end
    else
        pcall(function()
            for k, v in pairs(oldLighting) do Lighting[k] = v end
            for _, v in ipairs(Lighting:GetChildren()) do
                if v:IsA("Atmosphere") or v:IsA("BloomEffect") or v:IsA("DepthOfFieldEffect") then v.Enabled = true end
            end
        end)
    end
end)

-- Utility
createCategory("🔧 Utility", MainContent, 30)

createButton("🔁 Reset Character", MainContent, function()
    pcall(function()
        local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if h then h.Health = 0 end
    end)
end, 31)

createButton("📋 Copy Player Name", MainContent, function()
    pcall(function() setclipboard(player.Name) end)
    showNotif("📋 Copied: " .. player.Name, Color3.fromRGB(30, 50, 80))
end, 32)

createButton("📌 Copy Position", MainContent, function()
    pcall(function()
        local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local p = hrp.Position
            setclipboard(string.format("%.1f, %.1f, %.1f", p.X, p.Y, p.Z))
            showNotif("📌 Pos copied!", Color3.fromRGB(30, 50, 80))
        end
    end)
end, 33)

-- ════════════════════════════════════════════
-- EXTRA TAB
-- ════════════════════════════════════════════
createCategory("🤖 Auto Features", ExtraContent, 1)

local AntiAFKToggle = createButton("❌ Anti-AFK: OFF", ExtraContent, nil, 2)
AntiAFKToggle.MouseButton1Click:Connect(function()
    ToggleStates.AntiAFK = not ToggleStates.AntiAFK
    AntiAFKToggle.Text = ToggleStates.AntiAFK and "✅ Anti-AFK: ON" or "❌ Anti-AFK: OFF"
    setToggleVisual(AntiAFKToggle, ToggleStates.AntiAFK)

    if ToggleStates.AntiAFK then
        Connections.AntiAFK = player.Idled:Connect(function()
            local VU = game:GetService("VirtualUser")
            VU:Button2Down(Vector2.new(0, 0), Camera.CFrame)
            task.wait(1)
            VU:Button2Up(Vector2.new(0, 0), Camera.CFrame)
        end)
        showNotif("🛡️ Anti-AFK: ON", Color3.fromRGB(20, 70, 35))
    else
        if Connections.AntiAFK then Connections.AntiAFK:Disconnect() Connections.AntiAFK = nil end
        showNotif("🛡️ Anti-AFK: OFF", Color3.fromRGB(70, 20, 20))
    end
end)

local AutoJumpToggle = createButton("❌ Auto Jump: OFF", ExtraContent, nil, 3)
AutoJumpToggle.MouseButton1Click:Connect(function()
    ToggleStates.AutoJump = not ToggleStates.AutoJump
    AutoJumpToggle.Text = ToggleStates.AutoJump and "✅ Auto Jump: ON" or "❌ Auto Jump: OFF"
    setToggleVisual(AutoJumpToggle, ToggleStates.AutoJump)

    if ToggleStates.AutoJump then
        Connections.AutoJump = RunService.Heartbeat:Connect(function()
            pcall(function()
                local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
                if h and h:GetState() == Enum.HumanoidStateType.Running then
                    h:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end)
        end)
    else
        if Connections.AutoJump then Connections.AutoJump:Disconnect() Connections.AutoJump = nil end
    end
end)

createCategory("🎨 Character", ExtraContent, 10)

local InvisToggle = createButton("❌ Invisible (Local): OFF", ExtraContent, nil, 11)
InvisToggle.MouseButton1Click:Connect(function()
    local s = not InvisToggle:GetAttribute("active")
    setToggleVisual(InvisToggle, s)
    InvisToggle.Text = s and "✅ Invisible (Local): ON" or "❌ Invisible (Local): OFF"
    pcall(function()
        if player.Character then
            for _, p in ipairs(player.Character:GetDescendants()) do
                if p:IsA("BasePart") then p.LocalTransparencyModifier = s and 1 or 0 end
            end
        end
    end)
end)

for _, cfg in ipairs({{"Big Character", 12, 2}, {"Small Character", 13, 0.4}}) do
    local toggle = createButton("❌ " .. cfg[1] .. ": OFF", ExtraContent, nil, cfg[2] + 9)
    toggle.MouseButton1Click:Connect(function()
        local s = not toggle:GetAttribute("active")
        setToggleVisual(toggle, s)
        toggle.Text = s and ("✅ " .. cfg[1] .. ": ON") or ("❌ " .. cfg[1] .. ": OFF")
        pcall(function()
            local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
            if h then
                local v = s and cfg[3] or 1
                for _, n in ipairs({"BodyDepthScale","BodyHeightScale","BodyWidthScale","HeadScale"}) do
                    if h:FindFirstChild(n) then h[n].Value = v end
                end
            end
        end)
    end)
end

-- ════════════════════════════════════════════
-- PLAYERS TAB
-- ════════════════════════════════════════════
createWarningBox(
    "⚠️ <b>TELEPORT WARNING!</b>\n🔴 TP — BERBAHAYA\n🟡 Follow — Moderate\n🟢 Spectate — Aman",
    PlayersContent, 0
)

local PlayerStatusBar = Instance.new("Frame")
PlayerStatusBar.Size = UDim2.new(1, -4, 0, 0)
PlayerStatusBar.AutomaticSize = Enum.AutomaticSize.Y
PlayerStatusBar.BackgroundColor3 = Color3.fromRGB(28, 42, 60)
PlayerStatusBar.ZIndex = 3; PlayerStatusBar.LayoutOrder = 1
PlayerStatusBar.Visible = false; PlayerStatusBar.Parent = PlayersContent
Instance.new("UICorner", PlayerStatusBar).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", PlayerStatusBar).Color = Color3.fromRGB(80, 140, 255)

local PlayerStatusLabel = Instance.new("TextLabel", PlayerStatusBar)
PlayerStatusLabel.Size = UDim2.new(1, 0, 0, 0)
PlayerStatusLabel.AutomaticSize = Enum.AutomaticSize.Y
PlayerStatusLabel.BackgroundTransparency = 1
PlayerStatusLabel.TextColor3 = Color3.fromRGB(140, 220, 255)
PlayerStatusLabel.TextSize = isMobile and 12 or 10
PlayerStatusLabel.Font = Enum.Font.GothamBold
PlayerStatusLabel.TextWrapped = true; PlayerStatusLabel.RichText = true
PlayerStatusLabel.TextXAlignment = Enum.TextXAlignment.Left; PlayerStatusLabel.ZIndex = 4
local sp = Instance.new("UIPadding", PlayerStatusLabel)
sp.PaddingTop = UDim.new(0,8); sp.PaddingBottom = UDim.new(0,8)
sp.PaddingLeft = UDim.new(0,10); sp.PaddingRight = UDim.new(0,10)

local function updateStatusBar(t, c)
    if t == "" then PlayerStatusBar.Visible = false
    else PlayerStatusBar.Visible = true; PlayerStatusLabel.Text = t; if c then PlayerStatusBar.BackgroundColor3 = c end end
end

local StopAllBtn = createButton("🛑 Stop All Actions", PlayersContent, nil, 2)
StopAllBtn.BackgroundColor3 = Color3.fromRGB(100, 25, 25)

local SearchFrame = Instance.new("Frame")
SearchFrame.Size = UDim2.new(1, -4, 0, isMobile and 44 or 38)
SearchFrame.BackgroundColor3 = Color3.fromRGB(38, 38, 54)
SearchFrame.ZIndex = 3; SearchFrame.LayoutOrder = 3
SearchFrame.Parent = PlayersContent
Instance.new("UICorner", SearchFrame).CornerRadius = UDim.new(0, 10)

local si = Instance.new("TextLabel", SearchFrame)
si.Size = UDim2.new(0, 32, 1, 0); si.Position = UDim2.new(0, 5, 0, 0)
si.BackgroundTransparency = 1; si.Text = "🔍"; si.TextSize = isMobile and 16 or 14; si.ZIndex = 4

local SearchBox = Instance.new("TextBox", SearchFrame)
SearchBox.Size = UDim2.new(1, -40, 1, -8); SearchBox.Position = UDim2.new(0, 35, 0, 4)
SearchBox.BackgroundTransparency = 1; SearchBox.PlaceholderText = "Search player..."
SearchBox.PlaceholderColor3 = Color3.fromRGB(110, 110, 140); SearchBox.Text = ""
SearchBox.TextColor3 = Color3.new(1,1,1); SearchBox.TextSize = isMobile and 14 or 12
SearchBox.Font = Enum.Font.Gotham; SearchBox.TextXAlignment = Enum.TextXAlignment.Left
SearchBox.ClearTextOnFocus = false; SearchBox.ZIndex = 4

local PlayerCountLabel = Instance.new("TextLabel")
PlayerCountLabel.Size = UDim2.new(1, -4, 0, 22); PlayerCountLabel.BackgroundTransparency = 1
PlayerCountLabel.TextColor3 = Color3.fromRGB(150, 150, 190); PlayerCountLabel.TextSize = isMobile and 11 or 10
PlayerCountLabel.Font = Enum.Font.Gotham; PlayerCountLabel.ZIndex = 3; PlayerCountLabel.LayoutOrder = 4
PlayerCountLabel.Parent = PlayersContent

local PlayerListFrame = Instance.new("Frame")
PlayerListFrame.Size = UDim2.new(1, -4, 0, 20); PlayerListFrame.BackgroundTransparency = 1
PlayerListFrame.AutomaticSize = Enum.AutomaticSize.Y; PlayerListFrame.ZIndex = 3; PlayerListFrame.LayoutOrder = 5
PlayerListFrame.Parent = PlayersContent
Instance.new("UIListLayout", PlayerListFrame).Padding = UDim.new(0, 5)

-- TP Confirm
local ConfirmOverlay = Instance.new("Frame")
ConfirmOverlay.Size = UDim2.new(1,0,1,0); ConfirmOverlay.BackgroundColor3 = Color3.new(0,0,0)
ConfirmOverlay.BackgroundTransparency = 0.4; ConfirmOverlay.ZIndex = 50; ConfirmOverlay.Visible = false
ConfirmOverlay.Parent = ScreenGui

local ConfirmBox = Instance.new("Frame")
ConfirmBox.Size = isMobile and UDim2.new(0.88,0,0,260) or UDim2.new(0,360,0,240)
ConfirmBox.AnchorPoint = Vector2.new(0.5,0.5); ConfirmBox.Position = UDim2.new(0.5,0,0.5,0)
ConfirmBox.BackgroundColor3 = Color3.fromRGB(32,22,28); ConfirmBox.ZIndex = 51; ConfirmBox.Parent = ConfirmOverlay
Instance.new("UICorner", ConfirmBox).CornerRadius = UDim.new(0,14)
Instance.new("UIStroke", ConfirmBox).Color = Color3.fromRGB(220,70,70)

local CT = Instance.new("TextLabel", ConfirmBox)
CT.Size = UDim2.new(1,0,0,40); CT.BackgroundTransparency = 1; CT.Text = "⚠️ TELEPORT WARNING"
CT.TextColor3 = Color3.fromRGB(255,90,90); CT.TextSize = isMobile and 18 or 16
CT.Font = Enum.Font.GothamBold; CT.ZIndex = 52

local CM = Instance.new("TextLabel", ConfirmBox)
CM.Size = UDim2.new(1,-20,0,110); CM.Position = UDim2.new(0,10,0,40)
CM.BackgroundTransparency = 1; CM.TextColor3 = Color3.fromRGB(255,200,200)
CM.TextSize = isMobile and 12 or 10; CM.Font = Enum.Font.Gotham
CM.TextWrapped = true; CM.RichText = true; CM.TextYAlignment = Enum.TextYAlignment.Top; CM.ZIndex = 52

local CBR = Instance.new("Frame", ConfirmBox)
CBR.Size = UDim2.new(1,-20,0,isMobile and 45 or 38)
CBR.Position = UDim2.new(0,10,1,-(isMobile and 55 or 48))
CBR.BackgroundTransparency = 1; CBR.ZIndex = 52
local cbl = Instance.new("UIListLayout", CBR)
cbl.FillDirection = Enum.FillDirection.Horizontal; cbl.Padding = UDim.new(0,10)
cbl.HorizontalAlignment = Enum.HorizontalAlignment.Center

local CancelTP = Instance.new("TextButton", CBR)
CancelTP.Size = UDim2.new(0.45,0,1,0); CancelTP.BackgroundColor3 = Color3.fromRGB(55,55,78)
CancelTP.Text = "❌ Cancel"; CancelTP.TextColor3 = Color3.new(1,1,1)
CancelTP.TextSize = isMobile and 14 or 12; CancelTP.Font = Enum.Font.GothamBold
CancelTP.ZIndex = 53; CancelTP.AutoButtonColor = false; CancelTP.LayoutOrder = 1
Instance.new("UICorner", CancelTP).CornerRadius = UDim.new(0,10)

local ConfirmTP = Instance.new("TextButton", CBR)
ConfirmTP.Size = UDim2.new(0.45,0,1,0); ConfirmTP.BackgroundColor3 = Color3.fromRGB(170,45,45)
ConfirmTP.Text = "⚡ TELEPORT"; ConfirmTP.TextColor3 = Color3.new(1,1,1)
ConfirmTP.TextSize = isMobile and 14 or 12; ConfirmTP.Font = Enum.Font.GothamBold
ConfirmTP.ZIndex = 53; ConfirmTP.AutoButtonColor = false; ConfirmTP.LayoutOrder = 2
Instance.new("UICorner", ConfirmTP).CornerRadius = UDim.new(0,10)

local pendingTP = nil

CancelTP.MouseButton1Click:Connect(function()
    ConfirmOverlay.Visible = false; pendingTP = nil; PlayerAction.TPConfirmPending = false
end)

ConfirmTP.MouseButton1Click:Connect(function()
    ConfirmOverlay.Visible = false; PlayerAction.TPConfirmPending = false
    if pendingTP and pendingTP.Character and pendingTP.Character:FindFirstChild("HumanoidRootPart") then
        pcall(function()
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                player.Character.HumanoidRootPart.CFrame = pendingTP.Character.HumanoidRootPart.CFrame * CFrame.new(2,0,2)
                updateStatusBar("📌 Teleported to <b>"..pendingTP.Name.."</b>!", Color3.fromRGB(25,55,40))
            end
        end)
    end
    pendingTP = nil
end)

local function stopSpectate()
    if PlayerAction.IsSpectating then
        PlayerAction.IsSpectating = false; PlayerAction.SpectateTarget = nil
        pcall(function()
            if player.Character then
                Camera.CameraSubject = player.Character:FindFirstChildOfClass("Humanoid")
                Camera.CameraType = Enum.CameraType.Custom
            end
        end)
    end
end

local function stopFollow()
    if PlayerAction.IsFollowing then
        PlayerAction.IsFollowing = false; PlayerAction.FollowTarget = nil
        if Connections.Follow then Connections.Follow:Disconnect() Connections.Follow = nil end
    end
end

local function stopAllActions() stopSpectate(); stopFollow(); updateStatusBar("") end

local function startSpectate(t)
    if t == player then return end; stopAllActions()
    if t.Character and t.Character:FindFirstChildOfClass("Humanoid") then
        PlayerAction.IsSpectating = true; PlayerAction.SpectateTarget = t
        pcall(function()
            Camera.CameraSubject = t.Character:FindFirstChildOfClass("Humanoid")
            Camera.CameraType = Enum.CameraType.Custom
        end)
        updateStatusBar("👁️ Spectating: <b>"..t.Name.."</b>", Color3.fromRGB(25,40,60))
    end
end

local function startFollow(t)
    if t == player then return end; stopAllActions()
    if t.Character and t.Character:FindFirstChild("HumanoidRootPart") then
        PlayerAction.IsFollowing = true; PlayerAction.FollowTarget = t
        updateStatusBar("🚶 Following: <b>"..t.Name.."</b>", Color3.fromRGB(25,48,30))
        Connections.Follow = RunService.Heartbeat:Connect(function()
            pcall(function()
                if not PlayerAction.IsFollowing then return end
                if not t or not t.Parent or not t.Character or not t.Character:FindFirstChild("HumanoidRootPart") then
                    stopFollow(); updateStatusBar("⚠️ Follow ended", Color3.fromRGB(55,45,25)); return
                end
                if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end
                local d = (player.Character.HumanoidRootPart.Position - t.Character.HumanoidRootPart.Position).Magnitude
                local h = player.Character:FindFirstChildOfClass("Humanoid")
                if d > 6 and h then h:MoveTo(t.Character.HumanoidRootPart.Position) end
            end)
        end)
    end
end

local function requestTP(t)
    if t == player or PlayerAction.TPConfirmPending then return end
    PlayerAction.TPConfirmPending = true; pendingTP = t
    local d = "?"
    pcall(function()
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") and t.Character and t.Character:FindFirstChild("HumanoidRootPart") then
            d = tostring(math.floor((player.Character.HumanoidRootPart.Position - t.Character.HumanoidRootPart.Position).Magnitude))
        end
    end)
    CM.Text = string.format("Target: <b>%s</b>\n📏 Distance: <b>%s studs</b>\n\n🚨 Risks:\n• Anti-cheat → BAN\n• Stuck in object", t.Name, d)
    ConfirmOverlay.Visible = true
end

StopAllBtn.MouseButton1Click:Connect(function()
    stopAllActions(); showNotif("🛑 Stopped", Color3.fromRGB(60,30,30))
end)

local function clearPlayerList()
    for _, c in ipairs(PlayerListFrame:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
end

local function createPlayerEntry(t, idx)
    if t == player then return end
    local entry = Instance.new("Frame")
    entry.Size = UDim2.new(1, 0, 0, isMobile and 88 or 76)
    entry.BackgroundColor3 = Color3.fromRGB(36, 36, 52)
    entry.ZIndex = 4; entry.LayoutOrder = idx; entry.Parent = PlayerListFrame
    Instance.new("UICorner", entry).CornerRadius = UDim.new(0, 10)
    Instance.new("UIStroke", entry).Color = Color3.fromRGB(50, 50, 70)

    local oX = isMobile and 56 or 48

    local av = Instance.new("Frame", entry)
    av.Size = UDim2.new(0, isMobile and 42 or 36, 0, isMobile and 42 or 36)
    av.Position = UDim2.new(0,8,0,8); av.BackgroundColor3 = Color3.fromRGB(55,55,88); av.ZIndex = 5
    Instance.new("UICorner", av).CornerRadius = UDim.new(0.5, 0)

    local avT = Instance.new("TextLabel", av)
    avT.Size = UDim2.new(1,0,1,0); avT.BackgroundTransparency = 1
    avT.Text = t.Name:sub(1,2):upper(); avT.TextColor3 = Color3.new(1,1,1)
    avT.TextSize = isMobile and 15 or 13; avT.Font = Enum.Font.GothamBold; avT.ZIndex = 6

    local nL = Instance.new("TextLabel", entry)
    nL.Size = UDim2.new(1,-(oX+5),0,20); nL.Position = UDim2.new(0,oX,0,6)
    nL.BackgroundTransparency = 1; nL.Text = t.Name; nL.TextColor3 = Color3.new(1,1,1)
    nL.TextSize = isMobile and 13 or 11; nL.Font = Enum.Font.GothamBold
    nL.TextXAlignment = Enum.TextXAlignment.Left; nL.TextTruncate = Enum.TextTruncate.AtEnd; nL.ZIndex = 5

    local hL = Instance.new("TextLabel", entry)
    hL.Size = UDim2.new(1,-(oX+5),0,16); hL.Position = UDim2.new(0,oX,0,24)
    hL.BackgroundTransparency = 1; hL.TextColor3 = Color3.fromRGB(130,130,160)
    hL.TextSize = isMobile and 10 or 9; hL.Font = Enum.Font.Gotham
    hL.TextXAlignment = Enum.TextXAlignment.Left; hL.ZIndex = 5

    spawn(function()
        while entry.Parent do
            pcall(function()
                if t.Character then
                    local hum = t.Character:FindFirstChildOfClass("Humanoid")
                    local hrp = t.Character:FindFirstChild("HumanoidRootPart")
                    if hum and hrp then
                        local d2 = 0
                        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                            d2 = math.floor((player.Character.HumanoidRootPart.Position - hrp.Position).Magnitude)
                        end
                        -- Ambil speed dari SpeedData jika ada
                        local speedText = ""
                        if SpeedData[t] then
                            speedText = string.format(" • ⚡%.0f st/s", SpeedData[t].speed or 0)
                        end
                        hL.Text = string.format("❤️ %.0f • 📏 %d st%s", hum.Health, d2, speedText)
                    end
                else hL.Text = "💀 No char" end
            end)
            task.wait(0.5)
        end
    end)

    local bR = Instance.new("Frame", entry)
    bR.Size = UDim2.new(1,-12,0,isMobile and 30 or 26)
    bR.Position = UDim2.new(0,6,1,-(isMobile and 36 or 32))
    bR.BackgroundTransparency = 1; bR.ZIndex = 5
    Instance.new("UIListLayout", bR).FillDirection = Enum.FillDirection.Horizontal

    local function mkBtn(txt, col, cb)
        local b = Instance.new("TextButton", bR)
        b.Size = UDim2.new(0, isMobile and 86 or 76, 1, 0)
        b.BackgroundColor3 = col; b.Text = txt; b.TextColor3 = Color3.new(1,1,1)
        b.TextSize = isMobile and 11 or 9; b.Font = Enum.Font.GothamBold
        b.ZIndex = 6; b.AutoButtonColor = false
        Instance.new("UICorner", b).CornerRadius = UDim.new(0,6)
        b.MouseButton1Click:Connect(cb)
    end

    mkBtn("📌 TP", Color3.fromRGB(140,35,35), function() requestTP(t) end)
    mkBtn("👁️ Spec", Color3.fromRGB(35,65,140), function() startSpectate(t) end)
    mkBtn("🚶 Follow", Color3.fromRGB(35,90,45), function() startFollow(t) end)
end

function refreshPlayerList(filter)
    clearPlayerList()
    filter = (filter or ""):lower()
    local c = 0
    for i, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player then
            if filter == "" or plr.Name:lower():find(filter,1,true) or plr.DisplayName:lower():find(filter,1,true) then
                createPlayerEntry(plr, i); c += 1
            end
        end
    end
    PlayerCountLabel.Text = string.format("👥 %d players", c)
end

SearchBox:GetPropertyChangedSignal("Text"):Connect(function() refreshPlayerList(SearchBox.Text) end)

Players.PlayerAdded:Connect(function(plr)
    task.wait(0.5)
    if currentTab == "players" then refreshPlayerList(SearchBox.Text) end
    plr.CharacterAdded:Connect(function()
        task.wait(1)
        if ToggleStates.ESP then createPlayerESP(plr) end
        if SPEED_SETTINGS.Enabled then createPlayerSpeedBB(plr) end
    end)
end)

Players.PlayerRemoving:Connect(function(plr)
    cleanupPlayerESP(plr)
    removePlayerSpeedBB(plr)
    if PlayerAction.SpectateTarget == plr then stopSpectate() end
    if PlayerAction.FollowTarget == plr then stopFollow() end
    if pendingTP == plr then ConfirmOverlay.Visible = false; pendingTP = nil; PlayerAction.TPConfirmPending = false end
    task.wait(0.3)
    if currentTab == "players" then refreshPlayerList(SearchBox.Text) end
end)

-- ════════════════════════════════════════════
-- SERVER TAB
-- ════════════════════════════════════════════
local ServerStatus = Instance.new("TextLabel")
ServerStatus.Size = UDim2.new(1,-4,0,26); ServerStatus.BackgroundColor3 = Color3.fromRGB(28,28,46)
ServerStatus.Text = "  🌐 Tap Refresh to load"; ServerStatus.TextColor3 = Color3.fromRGB(130,190,255)
ServerStatus.TextSize = isMobile and 12 or 10; ServerStatus.Font = Enum.Font.GothamBold
ServerStatus.TextXAlignment = Enum.TextXAlignment.Left; ServerStatus.ZIndex = 3; ServerStatus.LayoutOrder = 0
ServerStatus.Parent = ServerContent; Instance.new("UICorner", ServerStatus).CornerRadius = UDim.new(0,8)

local ControlRow = Instance.new("Frame")
ControlRow.Size = UDim2.new(1,-4,0,isMobile and 42 or 36)
ControlRow.BackgroundTransparency = 1; ControlRow.ZIndex = 3; ControlRow.LayoutOrder = 1
ControlRow.Parent = ServerContent
local cl2 = Instance.new("UIListLayout", ControlRow)
cl2.FillDirection = Enum.FillDirection.Horizontal; cl2.Padding = UDim.new(0,4)
cl2.HorizontalAlignment = Enum.HorizontalAlignment.Center

local function mkCtrl(t, c, o)
    local b = Instance.new("TextButton", ControlRow)
    b.Size = UDim2.new(0.32,0,1,0); b.BackgroundColor3 = c; b.Text = t
    b.TextColor3 = Color3.new(1,1,1); b.TextSize = isMobile and 11 or 9
    b.Font = Enum.Font.GothamBold; b.ZIndex = 4; b.AutoButtonColor = false; b.LayoutOrder = o
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,8)
    return b
end

local PrevBtn = mkCtrl("◀ Prev", Color3.fromRGB(46,46,70), 1)
local RefreshBtn = mkCtrl("🔄 Refresh", Color3.fromRGB(40,90,40), 2)
local NextBtn = mkCtrl("Next ▶", Color3.fromRGB(46,46,70), 3)

local PageInd = Instance.new("TextLabel")
PageInd.Size = UDim2.new(1,-4,0,22); PageInd.BackgroundColor3 = Color3.fromRGB(32,32,48)
PageInd.Text = "Page 0/0 | 0 servers"; PageInd.TextColor3 = Color3.fromRGB(170,170,255)
PageInd.TextSize = isMobile and 11 or 9; PageInd.Font = Enum.Font.GothamBold
PageInd.ZIndex = 3; PageInd.LayoutOrder = 2; PageInd.Parent = ServerContent
Instance.new("UICorner", PageInd).CornerRadius = UDim.new(0,6)

local RandomBtn = createButton("🎲 Join Random Server", ServerContent, nil, 3)

local ServerListFrame = Instance.new("Frame")
ServerListFrame.Size = UDim2.new(1,-4,0,20); ServerListFrame.BackgroundTransparency = 1
ServerListFrame.AutomaticSize = Enum.AutomaticSize.Y; ServerListFrame.ZIndex = 3; ServerListFrame.LayoutOrder = 4
ServerListFrame.Parent = ServerContent
Instance.new("UIListLayout", ServerListFrame).Padding = UDim.new(0,4)

local function clearServerList()
    for _, c in ipairs(ServerListFrame:GetChildren()) do if not c:IsA("UIListLayout") then c:Destroy() end end
end

local function createServerEntry(s, idx)
    local e = Instance.new("Frame")
    e.Size = UDim2.new(1,0,0,isMobile and 56 or 48)
    e.BackgroundColor3 = Color3.fromRGB(36,36,52); e.ZIndex = 4; e.LayoutOrder = idx
    e.Parent = ServerListFrame; Instance.new("UICorner", e).CornerRadius = UDim.new(0,8)

    local playing, maxP = s.playing or 0, s.maxPlayers or 0
    local isCur = s.id == game.JobId

    local iL = Instance.new("TextLabel", e)
    iL.Size = UDim2.new(0.65,0,0.5,0); iL.Position = UDim2.new(0,8,0,4)
    iL.BackgroundTransparency = 1
    iL.Text = isCur and ("⭐ #"..idx.." [HERE]") or ("#"..idx.." "..s.id:sub(1,10).."...")
    iL.TextColor3 = isCur and Color3.fromRGB(255,215,70) or Color3.fromRGB(190,190,255)
    iL.TextSize = isMobile and 10 or 9; iL.Font = Enum.Font.GothamBold
    iL.TextXAlignment = Enum.TextXAlignment.Left; iL.ZIndex = 5

    local dL = Instance.new("TextLabel", e)
    dL.Size = UDim2.new(0.65,0,0.45,0); dL.Position = UDim2.new(0,8,0.5,0)
    dL.BackgroundTransparency = 1; dL.RichText = true
    local fr = maxP > 0 and playing/maxP or 0
    local fc = fr > 0.85 and "rgb(255,70,70)" or fr > 0.5 and "rgb(255,200,70)" or "rgb(80,255,120)"
    dL.Text = string.format("👥 <font color='%s'><b>%d</b>/%d</font>", fc, playing, maxP)
    dL.TextColor3 = Color3.fromRGB(160,160,200); dL.TextSize = isMobile and 9 or 8
    dL.Font = Enum.Font.Gotham; dL.TextXAlignment = Enum.TextXAlignment.Left; dL.ZIndex = 5

    local jB = Instance.new("TextButton", e)
    jB.Size = UDim2.new(0,isMobile and 60 or 52,0,isMobile and 26 or 22)
    jB.Position = UDim2.new(1,-(isMobile and 68 or 60),0.5,-(isMobile and 13 or 11))
    jB.BackgroundColor3 = isCur and Color3.fromRGB(50,50,70) or Color3.fromRGB(40,105,40)
    jB.Text = isCur and "Here" or "Join"; jB.TextColor3 = Color3.new(1,1,1)
    jB.TextSize = isMobile and 11 or 9; jB.Font = Enum.Font.GothamBold; jB.ZIndex = 6
    jB.AutoButtonColor = not isCur; Instance.new("UICorner", jB).CornerRadius = UDim.new(0,6)

    if not isCur then
        jB.MouseButton1Click:Connect(function()
            jB.Text = "..."; pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, player) end)
            task.wait(4); jB.Text = "Join"
        end)
    end
end

local function displayPage()
    clearServerList()
    local srv = ServerHopData.Servers
    local pp, pg = ServerHopData.PerPage, ServerHopData.CurrentPage
    ServerHopData.TotalPages = math.max(1, math.ceil(#srv / pp))
    ServerHopData.CurrentPage = math.clamp(pg, 1, ServerHopData.TotalPages)
    pg = ServerHopData.CurrentPage
    PageInd.Text = string.format("Page %d/%d | %d servers", pg, ServerHopData.TotalPages, #srv)
    if #srv == 0 then return end
    for i = (pg-1)*pp+1, math.min(pg*pp, #srv) do
        if srv[i] then createServerEntry(srv[i], i) end
    end
end

local function fetchServers()
    if ServerHopData.IsLoading then return end
    ServerHopData.IsLoading = true; ServerHopData.Servers = {}; ServerHopData.CurrentPage = 1
    ServerStatus.Text = "  ⏳ Loading..."; RefreshBtn.Text = "⏳..."
    clearServerList()

    local all, cursor, pages = {}, "", 0
    pcall(function()
        repeat
            pages += 1
            local url = string.format("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100%s",
                game.PlaceId, cursor ~= "" and ("&cursor="..cursor) or "")
            local r = nil
            for retry = 1, 3 do
                local ok, res = pcall(function() return HttpService:JSONDecode(game:HttpGet(url)) end)
                if ok then r = res; break end
                task.wait(1)
            end
            if not r then break end
            if r.data then for _, s in ipairs(r.data) do table.insert(all, s) end end
            cursor = r.nextPageCursor or ""
            ServerStatus.Text = string.format("  ⏳ %d servers...", #all)
            if cursor ~= "" and pages < 25 then task.wait(0.25) end
        until cursor == "" or pages >= 25
    end)

    table.sort(all, function(a, b) return (a.playing or 0) > (b.playing or 0) end)
    ServerHopData.Servers = all; ServerHopData.IsLoading = false
    ServerStatus.Text = string.format("  ✅ %d servers", #all)
    RefreshBtn.Text = "🔄 Refresh"; displayPage()
    showNotif("🌐 "..#all.." servers loaded", Color3.fromRGB(20,60,40))
end

RefreshBtn.MouseButton1Click:Connect(function() task.spawn(fetchServers) end)
PrevBtn.MouseButton1Click:Connect(function()
    if ServerHopData.CurrentPage > 1 then ServerHopData.CurrentPage -= 1; displayPage() end
end)
NextBtn.MouseButton1Click:Connect(function()
    if ServerHopData.CurrentPage < ServerHopData.TotalPages then ServerHopData.CurrentPage += 1; displayPage() end
end)

RandomBtn.MouseButton1Click:Connect(function()
    local avail = {}
    for _, s in ipairs(ServerHopData.Servers) do
        if s.id ~= game.JobId and (s.playing or 0) < (s.maxPlayers or 0) then table.insert(avail, s) end
    end
    if #avail == 0 then showNotif("⚠️ Load servers first!", Color3.fromRGB(80,50,20)); return end
    showNotif("🎲 Joining...", Color3.fromRGB(30,50,90))
    pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, avail[math.random(#avail)].id, player) end)
end)

-- ════════════════════════════════════════════
-- INFO TAB
-- ════════════════════════════════════════════
local function mkInfo(t, p, o)
    local l = Instance.new("TextLabel", p)
    l.Size = UDim2.new(1,-4,0,0); l.AutomaticSize = Enum.AutomaticSize.Y
    l.BackgroundColor3 = Color3.fromRGB(32,32,50); l.TextColor3 = Color3.fromRGB(200,200,255)
    l.TextSize = isMobile and 11 or 10; l.Font = Enum.Font.Gotham; l.TextWrapped = true
    l.RichText = true; l.TextYAlignment = Enum.TextYAlignment.Top
    l.TextXAlignment = Enum.TextXAlignment.Left; l.ZIndex = 3; l.LayoutOrder = o; l.Text = t
    Instance.new("UICorner", l).CornerRadius = UDim.new(0,10)
    local ip = Instance.new("UIPadding", l)
    ip.PaddingTop = UDim.new(0,8); ip.PaddingBottom = UDim.new(0,8)
    ip.PaddingLeft = UDim.new(0,10); ip.PaddingRight = UDim.new(0,10)
end

createCategory("ℹ️ About", InfoContent, 1)
mkInfo(string.format(
    "<b>🔥 Obby Helper Pro v3.2</b>\n\n📱 %s | 👤 %s\n🆔 PlaceId: %d",
    isMobile and "Mobile" or "PC", player.Name, game.PlaceId
), InfoContent, 2)

createCategory("⚡ Speed Meter Guide", InfoContent, 3)
mkInfo(
    "<font color='#9696B4'>🔴 0-5 st/s = Diam</font>\n" ..
    "<font color='#64DC64'>🚶 5-20 st/s = Normal Walk</font>\n" ..
    "<font color='#FFC832'>🏃 20-50 st/s = Speed Boost</font>\n" ..
    "<font color='#FF7832'>💨 50-100 st/s = Fast</font>\n" ..
    "<font color='#FF3C3C'>⚡ 100+ st/s = Extreme / Hack</font>\n\n" ..
    "• YOU badge = data kecepatan diri sendiri\n" ..
    "• Bar biru = visual speed real-time\n" ..
    "• Angka = studs per second",
    InfoContent, 4
)

createCategory("📋 All Features v3.2", InfoContent, 5)
mkInfo(
    "<b>Main:</b> ESP, Speed Meter, Obstacle, Speed, Jump,\n" ..
    "Inf Jump, Noclip, Anti-Void, Fullbright\n\n" ..
    "<b>Extra:</b> Anti-AFK, Auto Jump, Invisible, Big/Small\n\n" ..
    "<b>Players:</b> TP (confirm), Spectate, Follow, Search\n\n" ..
    "<b>Servers:</b> Refresh, Prev/Next, Random Join",
    InfoContent, 6
)

-- ════════════════════════════════════════════
-- CLOSE
-- ════════════════════════════════════════════
CloseBtn.MouseButton1Click:Connect(function()
    stopAllActions()

    -- Cleanup Speed Meter
    SPEED_SETTINGS.Enabled = false
    if SelfSpeedData.billboard then
        pcall(function() SelfSpeedData.billboard:Destroy() end)
    end
    for plr in pairs(SpeedData) do removePlayerSpeedBB(plr) end
    SpeedData = {}

    for k, c in pairs(Connections) do
        pcall(function() if typeof(c) == "RBXScriptConnection" then c:Disconnect() end end)
    end
    Connections = {}

    for p in pairs(ESP) do cleanupPlayerESP(p) end
    clearObstacles()

    if ToggleStates.Fullbright then
        pcall(function()
            for k, v in pairs(oldLighting) do Lighting[k] = v end
            for _, v in ipairs(Lighting:GetChildren()) do
                if v:IsA("Atmosphere") or v:IsA("BloomEffect") or v:IsA("DepthOfFieldEffect") then v.Enabled = true end
            end
        end)
    end

    pcall(function()
        if player.Character then
            local h = player.Character:FindFirstChildOfClass("Humanoid")
            if h then h.WalkSpeed = 16; h.JumpPower = 50; h.UseJumpPower = false end
            for _, p in ipairs(player.Character:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = true; p.LocalTransparencyModifier = 0 end
            end
        end
    end)

    ConfirmOverlay:Destroy()
    ScreenGui:Destroy()
end)

-- ════════════════════════════════════════════
-- CHARACTER RESPAWN
-- ════════════════════════════════════════════
player.CharacterAdded:Connect(function(char)
    local h = char:WaitForChild("Humanoid", 10)
    if not h then return end
    task.wait(0.5)

    pcall(function()
        if ToggleStates.Speed then h.WalkSpeed = Settings.SpeedValue end
        if ToggleStates.Jump then h.UseJumpPower = true; h.JumpPower = Settings.JumpValue end
    end)

    if PlayerAction.IsSpectating and PlayerAction.SpectateTarget and PlayerAction.SpectateTarget.Character then
        pcall(function() Camera.CameraSubject = PlayerAction.SpectateTarget.Character:FindFirstChildOfClass("Humanoid") end)
    end

    if ToggleStates.ESP then
        task.wait(0.5)
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= player and plr.Character and not ESP[plr] then createPlayerESP(plr) end
        end
    end

    if SPEED_SETTINGS.Enabled then
        task.wait(0.5)
        createSelfSpeedBillboard()
    end
end)

-- ════════════════════════════════════════════
-- INIT
-- ════════════════════════════════════════════
switchTab("main")
displayPage()
task.delay(0.8, function() showNotif("🔥 Obby Helper v3.2 Ready!", Color3.fromRGB(30, 40, 80)) end)

print("╔════════════════════════════════════╗")
print("║  🔥 Obby Helper Pro v3.2           ║")
print("║  ⚡ Speed Meter Added!              ║")
print("║  📱 " .. (isMobile and "Mobile" or "PC") .. " | 👤 " .. player.Name)
print("╚════════════════════════════════════╝")
