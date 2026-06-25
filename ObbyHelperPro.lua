-- // Obby Helper Pro v3.0 - FIXED & IMPROVED
-- // Semua bug diperbaiki + fitur baru

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local PathfindingService = game:GetService("PathfindingService")

local player = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- ════════════════════════════════════════════
-- CLEANUP OLD GUI
-- ════════════════════════════════════════════
pcall(function()
    player.PlayerGui:FindFirstChild("ObbyHelperGUI"):Destroy()
end)

-- ════════════════════════════════════════════
-- VARIABLES
-- ════════════════════════════════════════════
local ESP = {}
local Connections = {}
local ObstacleFolder = {}

local Settings = {
    ObstacleTransparency = 0.7,
    ObstacleColor = Color3.fromRGB(255, 50, 50),
    SpeedValue = 32,
    JumpValue = 100
}

local ServerHopData = {
    Servers = {},
    CurrentPage = 1,
    PerPage = 25,
    TotalPages = 1,
    IsLoading = false,
    SortMode = "players" -- "players", "id"
}

local PlayerAction = {
    SpectateTarget = nil,
    FollowTarget = nil,
    IsSpectating = false,
    IsFollowing = false,
    TPConfirmPending = false
}

local ToggleStates = {
    ESP = false,
    Obstacle = false,
    Speed = false,
    Jump = false,
    InfJump = false,
    Noclip = false,
    AntiVoid = false,
    Fullbright = false,
    AntiAFK = false,
    AutoJump = false,
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

-- Pulse animation untuk icon
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

local MainStroke = Instance.new("UIStroke", Main)
MainStroke.Color = Color3.fromRGB(80, 100, 255)
MainStroke.Thickness = 2

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

-- Fix bottom corner
local TBarFix = Instance.new("Frame")
TBarFix.Size = UDim2.new(1, 0, 0.4, 0)
TBarFix.Position = UDim2.new(0, 0, 0.6, 0)
TBarFix.BackgroundColor3 = Color3.fromRGB(30, 30, 46)
TBarFix.BorderSizePixel = 0
TBarFix.ZIndex = 2
TBarFix.Parent = TitleBar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(0.55, 0, 1, 0)
Title.Position = UDim2.new(0.04, 0, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "🔥 Obby Helper"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = isMobile and 19 or 17
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.ZIndex = 3
Title.Parent = TitleBar

-- Version badge
local VerBadge = Instance.new("TextLabel")
VerBadge.Size = UDim2.new(0, 36, 0, 18)
VerBadge.Position = UDim2.new(0, isMobile and 165 or 148, 0.5, -9)
VerBadge.BackgroundColor3 = Color3.fromRGB(80, 100, 255)
VerBadge.Text = "v3.0"
VerBadge.TextColor3 = Color3.new(1, 1, 1)
VerBadge.TextSize = 9
VerBadge.Font = Enum.Font.GothamBold
VerBadge.ZIndex = 4
VerBadge.Parent = TitleBar
Instance.new("UICorner", VerBadge).CornerRadius = UDim.new(0, 6)

-- Minimize Button
local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Size = isMobile and UDim2.new(0, 40, 0, 40) or UDim2.new(0, 32, 0, 32)
MinimizeBtn.Position = isMobile and UDim2.new(1, -90, 0.5, -20) or UDim2.new(1, -76, 0.5, -16)
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(255, 175, 0)
MinimizeBtn.Text = "─"
MinimizeBtn.TextColor3 = Color3.new(1, 1, 1)
MinimizeBtn.TextSize = isMobile and 20 or 16
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.ZIndex = 3
MinimizeBtn.AutoButtonColor = false
MinimizeBtn.Parent = TitleBar
Instance.new("UICorner", MinimizeBtn).CornerRadius = UDim.new(0.5, 0)

-- Close Button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = isMobile and UDim2.new(0, 40, 0, 40) or UDim2.new(0, 32, 0, 32)
CloseBtn.Position = isMobile and UDim2.new(1, -45, 0.5, -20) or UDim2.new(1, -40, 0.5, -16)
CloseBtn.BackgroundColor3 = Color3.fromRGB(220, 55, 55)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.new(1, 1, 1)
CloseBtn.TextSize = isMobile and 18 or 15
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.ZIndex = 3
CloseBtn.AutoButtonColor = false
CloseBtn.Parent = TitleBar
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0.5, 0)

-- Hover effects
MinimizeBtn.MouseEnter:Connect(function()
    TweenService:Create(MinimizeBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(255, 210, 50)}):Play()
end)
MinimizeBtn.MouseLeave:Connect(function()
    TweenService:Create(MinimizeBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(255, 175, 0)}):Play()
end)
CloseBtn.MouseEnter:Connect(function()
    TweenService:Create(CloseBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(255, 80, 80)}):Play()
end)
CloseBtn.MouseLeave:Connect(function()
    TweenService:Create(CloseBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(220, 55, 55)}):Play()
end)

-- Minimize / Restore
local isMinimized = false

MinimizeBtn.MouseButton1Click:Connect(function()
    isMinimized = true
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
    isMinimized = false
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

local TabLayout = Instance.new("UIListLayout", TabBar)
TabLayout.FillDirection = Enum.FillDirection.Horizontal
TabLayout.SortOrder = Enum.SortOrder.LayoutOrder

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

    local indicator = Instance.new("Frame")
    indicator.Size = UDim2.new(0.6, 0, 0, 3)
    indicator.Position = UDim2.new(0.2, 0, 1, -3)
    indicator.BackgroundColor3 = Color3.fromRGB(100, 120, 255)
    indicator.BorderSizePixel = 0
    indicator.ZIndex = 4
    indicator.Visible = false
    indicator.Parent = btn
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

local tabList = {
    {"Main", "⚙️", 1},
    {"Players", "👥", 2},
    {"Servers", "🌐", 3},
    {"Extra", "⭐", 4},
    {"Info", "ℹ️", 5},
}

local tabBtns = {}
for _, t in ipairs(tabList) do
    local btn = createTab(t[1], t[2], t[3])
    tabBtns[t[1]:lower()] = btn
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

-- Tab click connections
for name, btn in pairs(tabBtns) do
    btn.MouseButton1Click:Connect(function()
        switchTab(name)
        if name == "players" then
            task.spawn(refreshPlayerList)
        end
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
    return lbl
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

    local stroke = Instance.new("UIStroke", btn)
    stroke.Color = Color3.fromRGB(55, 55, 80)
    stroke.Thickness = 1

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

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.6, 0, 0, 22)
    label.Position = UDim2.new(0, 10, 0, 5)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextSize = isMobile and 12 or 10
    label.Font = Enum.Font.GothamBold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 4
    label.Parent = container

    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(0.35, 0, 0, 22)
    valueLabel.Position = UDim2.new(0.63, 0, 0, 5)
    valueLabel.BackgroundTransparency = 1
    valueLabel.TextColor3 = Color3.fromRGB(100, 190, 255)
    valueLabel.TextSize = isMobile and 12 or 10
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.ZIndex = 4
    valueLabel.Parent = container

    suffix = suffix or ""
    local function formatVal(v)
        if suffix == "%" then return string.format("%.0f%%", v * 100)
        else return string.format("%.0f%s", v, suffix) end
    end
    valueLabel.Text = formatVal(default)

    local sliderBack = Instance.new("Frame")
    sliderBack.Size = UDim2.new(1, -20, 0, isMobile and 24 or 20)
    sliderBack.Position = UDim2.new(0, 10, 0, 33)
    sliderBack.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
    sliderBack.ZIndex = 4
    sliderBack.Parent = container
    Instance.new("UICorner", sliderBack).CornerRadius = UDim.new(1, 0)

    local initFill = math.clamp((default - minVal) / (maxVal - minVal), 0, 1)

    local sliderFill = Instance.new("Frame")
    sliderFill.Size = UDim2.new(initFill, 0, 1, 0)
    sliderFill.BackgroundColor3 = Color3.fromRGB(70, 100, 255)
    sliderFill.ZIndex = 5
    sliderFill.Parent = sliderBack
    Instance.new("UICorner", sliderFill).CornerRadius = UDim.new(1, 0)

    local kSize = isMobile and 20 or 16
    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, kSize, 0, kSize)
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Position = UDim2.new(initFill, 0, 0.5, 0)
    knob.BackgroundColor3 = Color3.fromRGB(220, 230, 255)
    knob.ZIndex = 7
    knob.Parent = sliderBack
    Instance.new("UICorner", knob).CornerRadius = UDim.new(0.5, 0)

    local kStroke = Instance.new("UIStroke", knob)
    kStroke.Color = Color3.fromRGB(80, 100, 255)
    kStroke.Thickness = 2

    local sliderBtn = Instance.new("TextButton")
    sliderBtn.Size = UDim2.new(1, 0, 1, 0)
    sliderBtn.BackgroundTransparency = 1
    sliderBtn.Text = ""
    sliderBtn.ZIndex = 8
    sliderBtn.Parent = sliderBack

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
            dragging = true
            updateFromX(input.Position.X)
        end
    end)

    sliderBtn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    local moveConn = UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            updateFromX(input.Position.X)
        end
    end)
    table.insert(Connections, moveConn)

    return container
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

    local ws = Instance.new("UIStroke", box)
    ws.Color = Color3.fromRGB(220, 70, 70)
    ws.Thickness = 2

    local wl = Instance.new("TextLabel")
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
    wl.Parent = box

    local wp = Instance.new("UIPadding", wl)
    wp.PaddingTop = UDim.new(0, 10); wp.PaddingBottom = UDim.new(0, 10)
    wp.PaddingLeft = UDim.new(0, 12); wp.PaddingRight = UDim.new(0, 12)

    return box
end

-- ════════════════════════════════════════════
-- NOTIFICATION SYSTEM
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

local NotifText = Instance.new("TextLabel")
NotifText.Size = UDim2.new(1, -20, 1, 0)
NotifText.Position = UDim2.new(0, 10, 0, 0)
NotifText.BackgroundTransparency = 1
NotifText.Text = ""
NotifText.TextSize = 13
NotifText.Font = Enum.Font.GothamBold
NotifText.TextColor3 = Color3.new(1, 1, 1)
NotifText.TextWrapped = true
NotifText.ZIndex = 201
NotifText.Parent = NotifFrame

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
-- ESP SYSTEM (FIXED)
-- ════════════════════════════════════════════
local function cleanupPlayerESP(plr)
    if ESP[plr] then
        pcall(function()
            if ESP[plr].Box then ESP[plr].Box:Destroy() end
            if ESP[plr].NameTag then ESP[plr].NameTag:Destroy() end
            if ESP[plr].Highlight then ESP[plr].Highlight:Destroy() end
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
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local head = char:FindFirstChild("Head")
        if not hrp or not head then return end

        -- Highlight (through wall, FIXED)
        local highlight = Instance.new("Highlight")
        highlight.FillColor = Color3.fromRGB(0, 255, 100)
        highlight.OutlineColor = Color3.fromRGB(0, 255, 100)
        highlight.FillTransparency = 0.7
        highlight.OutlineTransparency = 0.1
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Adornee = char
        highlight.Parent = ScreenGui

        -- Selection Box
        local box = Instance.new("SelectionBox")
        box.Color3 = Color3.fromRGB(0, 255, 100)
        box.LineThickness = 0.04
        box.SurfaceTransparency = 0.85
        box.SurfaceColor3 = Color3.fromRGB(0, 255, 100)
        box.Adornee = char
        box.Parent = ScreenGui

        -- Billboard Name Tag (IMPROVED)
        local nameTag = Instance.new("BillboardGui")
        nameTag.Size = UDim2.new(0, 220, 0, 65)
        nameTag.AlwaysOnTop = true
        nameTag.StudsOffset = Vector3.new(0, 3.5, 0)
        nameTag.Adornee = head
        nameTag.LightInfluence = 0
        nameTag.Parent = ScreenGui

        local bg = Instance.new("Frame")
        bg.Size = UDim2.new(1, 0, 1, 0)
        bg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        bg.BackgroundTransparency = 0.45
        bg.BorderSizePixel = 0
        bg.Parent = nameTag
        Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 8)

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, -8, 0.5, 0)
        nameLabel.Position = UDim2.new(0, 4, 0, 2)
        nameLabel.BackgroundTransparency = 1
        nameLabel.TextColor3 = Color3.fromRGB(50, 255, 120)
        nameLabel.TextStrokeTransparency = 0.4
        nameLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
        nameLabel.TextScaled = true
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.Text = plr.Name
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = bg

        local infoLabel = Instance.new("TextLabel")
        infoLabel.Size = UDim2.new(1, -8, 0.45, 0)
        infoLabel.Position = UDim2.new(0, 4, 0.52, 0)
        infoLabel.BackgroundTransparency = 1
        infoLabel.TextColor3 = Color3.fromRGB(200, 255, 220)
        infoLabel.TextStrokeTransparency = 0.5
        infoLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
        infoLabel.TextScaled = true
        infoLabel.Font = Enum.Font.Gotham
        infoLabel.Text = "Loading..."
        infoLabel.TextXAlignment = Enum.TextXAlignment.Left
        infoLabel.Parent = bg

        -- HP Bar
        local hpBarBG = Instance.new("Frame")
        hpBarBG.Size = UDim2.new(1, -8, 0, 4)
        hpBarBG.Position = UDim2.new(0, 4, 1, -6)
        hpBarBG.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        hpBarBG.BorderSizePixel = 0
        hpBarBG.Parent = bg
        Instance.new("UICorner", hpBarBG).CornerRadius = UDim.new(1, 0)

        local hpBar = Instance.new("Frame")
        hpBar.Size = UDim2.new(1, 0, 1, 0)
        hpBar.BackgroundColor3 = Color3.fromRGB(0, 220, 80)
        hpBar.BorderSizePixel = 0
        hpBar.Parent = hpBarBG
        Instance.new("UICorner", hpBar).CornerRadius = UDim.new(1, 0)

        ESP[plr] = {
            Box = box,
            NameTag = nameTag,
            Label = nameLabel,
            InfoLabel = infoLabel,
            HpBar = hpBar,
            Highlight = highlight,
            Char = char
        }
    end)
end

local function updateAllESP()
    for plr, data in pairs(ESP) do
        pcall(function()
            if not plr or not plr.Parent or not plr.Character then
                cleanupPlayerESP(plr)
                return
            end

            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
            if not hum or not hrp then cleanupPlayerESP(plr) return end

            if hum.Health <= 0 then
                cleanupPlayerESP(plr)
                return
            end

            -- Kalau character berubah (respawn), recreate
            if data.Char ~= plr.Character then
                cleanupPlayerESP(plr)
                createPlayerESP(plr)
                return
            end

            local dist = 0
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                dist = math.floor((player.Character.HumanoidRootPart.Position - hrp.Position).Magnitude)
            end

            local hpPercent = hum.Health / hum.MaxHealth
            local hpR = math.floor(255 * (1 - hpPercent))
            local hpG = math.floor(255 * hpPercent)
            local hpColor = Color3.fromRGB(hpR, hpG, 0)

            data.HpBar.Size = UDim2.new(hpPercent, 0, 1, 0)
            data.HpBar.BackgroundColor3 = hpColor

            -- Distance color
            local distColor
            if dist <= 30 then distColor = Color3.fromRGB(255, 80, 80)
            elseif dist <= 100 then distColor = Color3.fromRGB(255, 200, 0)
            else distColor = Color3.fromRGB(50, 255, 120) end

            data.Label.TextColor3 = distColor
            data.InfoLabel.Text = string.format("📏 %d st | ❤️ %.0f/%.0f", dist, hum.Health, hum.MaxHealth)

            if data.Highlight then
                data.Highlight.FillColor = distColor
                data.Highlight.OutlineColor = distColor
            end
        end)
    end
end

-- ════════════════════════════════════════════
-- MAIN TAB
-- ════════════════════════════════════════════
createCategory("📡 ESP & Vision", MainContent, 1)

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
        showNotif("👁️ Player ESP: ON", Color3.fromRGB(20, 80, 40))
    else
        if Connections.UpdateESP then Connections.UpdateESP:Disconnect() Connections.UpdateESP = nil end
        for plr in pairs(ESP) do cleanupPlayerESP(plr) end
        ESP = {}
        showNotif("👁️ Player ESP: OFF", Color3.fromRGB(80, 20, 20))
    end
end)

-- Obstacle Visualizer
local ObstacleToggle = createButton("❌ Obstacle Visualizer: OFF", MainContent, nil, 3)

local function clearObstacles()
    for part, data in pairs(ObstacleFolder) do
        pcall(function()
            if part and part.Parent then
                part.Transparency = data.OriginalTransparency
                part.Color = data.OriginalColor
                part.Material = data.OriginalMaterial
            end
            if data.Highlight then data.Highlight:Destroy() end
        end)
    end
    ObstacleFolder = {}
end

local function updateObstacleAppearance()
    for part, data in pairs(ObstacleFolder) do
        pcall(function()
            if part and part.Parent then
                part.Transparency = Settings.ObstacleTransparency
                if data.Highlight then data.Highlight.FillTransparency = Settings.ObstacleTransparency end
            end
        end)
    end
end

ObstacleToggle.MouseButton1Click:Connect(function()
    ToggleStates.Obstacle = not ToggleStates.Obstacle
    ObstacleToggle.Text = ToggleStates.Obstacle and "✅ Obstacle Visualizer: ON" or "❌ Obstacle Visualizer: OFF"
    setToggleVisual(ObstacleToggle, ToggleStates.Obstacle)

    if ToggleStates.Obstacle then
        local count = 0
        for _, part in ipairs(Workspace:GetDescendants()) do
            pcall(function()
                if part:IsA("BasePart") and part.CanCollide
                    and part.Transparency >= 0.85 and not ObstacleFolder[part]
                    and part ~= player.Character then
                    local origT = part.Transparency
                    local origC = part.Color
                    local origM = part.Material
                    part.Transparency = Settings.ObstacleTransparency
                    part.Color = Settings.ObstacleColor
                    part.Material = Enum.Material.Neon

                    local hl = Instance.new("Highlight")
                    hl.FillColor = Settings.ObstacleColor
                    hl.OutlineColor = Color3.fromRGB(255, 255, 0)
                    hl.FillTransparency = Settings.ObstacleTransparency
                    hl.OutlineTransparency = 0.1
                    hl.Adornee = part
                    hl.Parent = part

                    ObstacleFolder[part] = {
                        OriginalTransparency = origT,
                        OriginalColor = origC,
                        OriginalMaterial = origM,
                        Highlight = hl
                    }
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
    if ToggleStates.Obstacle then updateObstacleAppearance() end
end, 4)

-- Movement
createCategory("⚡ Movement", MainContent, 10)

local function applySpeed()
    pcall(function()
        if player.Character then
            local hum = player.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = ToggleStates.Speed and Settings.SpeedValue or 16 end
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
            local hum = player.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.UseJumpPower = true
                hum.JumpPower = ToggleStates.Jump and Settings.JumpValue or 50
            end
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
        if player.Character then
            local hum = player.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum:GetState() ~= Enum.HumanoidStateType.Dead then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end)
end)

-- Noclip (FIXED - more stable)
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
                    if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
                        p.CanCollide = false
                    end
                end
                -- HRP juga
                local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                if hrp then hrp.CanCollide = false end
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

-- Anti-Void (IMPROVED - faster response)
local AntiVoidToggle = createButton("❌ Anti-Void: OFF", MainContent, nil, 17)
AntiVoidToggle.MouseButton1Click:Connect(function()
    ToggleStates.AntiVoid = not ToggleStates.AntiVoid
    AntiVoidToggle.Text = ToggleStates.AntiVoid and "✅ Anti-Void: ON" or "❌ Anti-Void: OFF"
    setToggleVisual(AntiVoidToggle, ToggleStates.AntiVoid)

    if ToggleStates.AntiVoid then
        local lastSafePos = nil
        local lastSafeTime = 0

        Connections.AntiVoid = RunService.Heartbeat:Connect(function()
            pcall(function()
                if not player.Character then return end
                local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                if not hrp then return end

                local y = hrp.Position.Y

                -- Save safe position setiap 2 detik
                if y > -50 and tick() - lastSafeTime > 2 then
                    lastSafePos = hrp.CFrame
                    lastSafeTime = tick()
                end

                -- Teleport jika jatuh
                if y < -80 then
                    if lastSafePos then
                        hrp.CFrame = lastSafePos + Vector3.new(0, 10, 0)
                    else
                        hrp.CFrame = CFrame.new(hrp.Position.X, 80, hrp.Position.Z)
                    end
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
        oldLighting.Ambient = Lighting.Ambient
        oldLighting.Brightness = Lighting.Brightness
        oldLighting.OutdoorAmbient = Lighting.OutdoorAmbient
        oldLighting.ClockTime = Lighting.ClockTime
        oldLighting.FogEnd = Lighting.FogEnd
        oldLighting.GlobalShadows = Lighting.GlobalShadows

        Lighting.Ambient = Color3.new(1, 1, 1)
        Lighting.Brightness = 2
        Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
        Lighting.ClockTime = 12
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false

        -- Remove dark effects
        for _, v in ipairs(Lighting:GetChildren()) do
            if v:IsA("Atmosphere") or v:IsA("BloomEffect") or v:IsA("DepthOfFieldEffect") then
                v.Enabled = false
            end
        end
    else
        pcall(function()
            Lighting.Ambient = oldLighting.Ambient
            Lighting.Brightness = oldLighting.Brightness
            Lighting.OutdoorAmbient = oldLighting.OutdoorAmbient
            Lighting.ClockTime = oldLighting.ClockTime
            Lighting.FogEnd = oldLighting.FogEnd
            Lighting.GlobalShadows = oldLighting.GlobalShadows

            for _, v in ipairs(Lighting:GetChildren()) do
                if v:IsA("Atmosphere") or v:IsA("BloomEffect") or v:IsA("DepthOfFieldEffect") then
                    v.Enabled = true
                end
            end
        end)
    end
end)

-- Utility
createCategory("🔧 Utility", MainContent, 30)

createButton("🔁 Reset Character", MainContent, function()
    pcall(function()
        local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.Health = 0 end
    end)
end, 31)

createButton("📋 Copy Player Name", MainContent, function()
    pcall(function()
        setclipboard(player.Name)
        showNotif("📋 Copied: " .. player.Name, Color3.fromRGB(30, 50, 80))
    end)
end, 32)

createButton("📌 Copy Position", MainContent, function()
    pcall(function()
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local pos = player.Character.HumanoidRootPart.Position
            local txt = string.format("%.1f, %.1f, %.1f", pos.X, pos.Y, pos.Z)
            setclipboard(txt)
            showNotif("📌 " .. txt, Color3.fromRGB(30, 50, 80))
        end
    end)
end, 33)

-- ════════════════════════════════════════════
-- EXTRA TAB (NEW!)
-- ════════════════════════════════════════════
createCategory("🤖 Auto Features", ExtraContent, 1)

-- Anti AFK
local AntiAFKToggle = createButton("❌ Anti-AFK: OFF", ExtraContent, nil, 2)
AntiAFKToggle.MouseButton1Click:Connect(function()
    ToggleStates.AntiAFK = not ToggleStates.AntiAFK
    AntiAFKToggle.Text = ToggleStates.AntiAFK and "✅ Anti-AFK: ON" or "❌ Anti-AFK: OFF"
    setToggleVisual(AntiAFKToggle, ToggleStates.AntiAFK)

    if ToggleStates.AntiAFK then
        Connections.AntiAFK = task.spawn(function()
            while ToggleStates.AntiAFK do
                pcall(function()
                    local vc = game:GetService("VirtualUser")
                    vc:Button2Down(Vector2.new(0, 0), CFrame.new())
                    task.wait(0.1)
                    vc:Button2Up(Vector2.new(0, 0), CFrame.new())
                end)
                task.wait(60)
            end
        end)
    end
end)

-- Auto Jump
local AutoJumpToggle = createButton("❌ Auto Jump: OFF", ExtraContent, nil, 3)
AutoJumpToggle.MouseButton1Click:Connect(function()
    ToggleStates.AutoJump = not ToggleStates.AutoJump
    AutoJumpToggle.Text = ToggleStates.AutoJump and "✅ Auto Jump: ON" or "❌ Auto Jump: OFF"
    setToggleVisual(AutoJumpToggle, ToggleStates.AutoJump)

    if ToggleStates.AutoJump then
        Connections.AutoJump = RunService.Heartbeat:Connect(function()
            pcall(function()
                if not player.Character then return end
                local hum = player.Character:FindFirstChildOfClass("Humanoid")
                if hum and hum:GetState() == Enum.HumanoidStateType.Running then
                    hum:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end)
        end)
    else
        if Connections.AutoJump then Connections.AutoJump:Disconnect() Connections.AutoJump = nil end
    end
end)

createCategory("🎨 Character", ExtraContent, 10)

-- Invisible (experimental)
local InvisToggle = createButton("❌ Invisible (Local): OFF", ExtraContent, nil, 11)
InvisToggle.MouseButton1Click:Connect(function()
    local state = not InvisToggle:GetAttribute("active")
    setToggleVisual(InvisToggle, state)
    InvisToggle.Text = state and "✅ Invisible (Local): ON" or "❌ Invisible (Local): OFF"

    pcall(function()
        if player.Character then
            for _, part in ipairs(player.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.LocalTransparencyModifier = state and 1 or 0
                end
            end
        end
    end)
end)

-- Big Character
local BigCharToggle = createButton("❌ Big Character: OFF", ExtraContent, nil, 12)
BigCharToggle.MouseButton1Click:Connect(function()
    local state = not BigCharToggle:GetAttribute("active")
    setToggleVisual(BigCharToggle, state)
    BigCharToggle.Text = state and "✅ Big Character: ON" or "❌ Big Character: OFF"

    pcall(function()
        if player.Character then
            local hum = player.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.BodyDepthScale.Value = state and 2 or 1
                hum.BodyHeightScale.Value = state and 2 or 1
                hum.BodyWidthScale.Value = state and 2 or 1
                hum.HeadScale.Value = state and 2 or 1
            end
        end
    end)
end)

-- Small Character  
local SmallCharToggle = createButton("❌ Small Character: OFF", ExtraContent, nil, 13)
SmallCharToggle.MouseButton1Click:Connect(function()
    local state = not SmallCharToggle:GetAttribute("active")
    setToggleVisual(SmallCharToggle, state)
    SmallCharToggle.Text = state and "✅ Small Character: ON" or "❌ Small Character: OFF"

    pcall(function()
        if player.Character then
            local hum = player.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.BodyDepthScale.Value = state and 0.4 or 1
                hum.BodyHeightScale.Value = state and 0.4 or 1
                hum.BodyWidthScale.Value = state and 0.4 or 1
                hum.HeadScale.Value = state and 0.4 or 1
            end
        end
    end)
end)

createCategory("🌟 Misc", ExtraContent, 20)

-- Chat bypass hint
local chatBtn = createButton("💬 Chat Bypass (Clipboard)", ExtraContent, function()
    pcall(function() setclipboard("𝓗𝓮𝓵𝓵𝓸") end)
    showNotif("💬 Special text copied!", Color3.fromRGB(40, 40, 80))
end, 21)

-- ════════════════════════════════════════════
-- PLAYERS TAB (IMPROVED)
-- ════════════════════════════════════════════
createWarningBox(
    "⚠️ <b>TELEPORT WARNING!</b>\n" ..
    "🔴 TP Player — BERBAHAYA, bisa kena BAN\n" ..
    "🟡 Follow — Moderate risk\n" ..
    "🟢 Spectate — Paling aman",
    PlayersContent, 0
)

-- Status bar
local PlayerStatusBar = Instance.new("Frame")
PlayerStatusBar.Size = UDim2.new(1, -4, 0, 0)
PlayerStatusBar.AutomaticSize = Enum.AutomaticSize.Y
PlayerStatusBar.BackgroundColor3 = Color3.fromRGB(28, 42, 60)
PlayerStatusBar.ZIndex = 3
PlayerStatusBar.LayoutOrder = 1
PlayerStatusBar.Visible = false
PlayerStatusBar.Parent = PlayersContent
Instance.new("UICorner", PlayerStatusBar).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", PlayerStatusBar).Color = Color3.fromRGB(80, 140, 255)

local PlayerStatusLabel = Instance.new("TextLabel")
PlayerStatusLabel.Size = UDim2.new(1, 0, 0, 0)
PlayerStatusLabel.AutomaticSize = Enum.AutomaticSize.Y
PlayerStatusLabel.BackgroundTransparency = 1
PlayerStatusLabel.TextColor3 = Color3.fromRGB(140, 220, 255)
PlayerStatusLabel.TextSize = isMobile and 12 or 10
PlayerStatusLabel.Font = Enum.Font.GothamBold
PlayerStatusLabel.TextWrapped = true
PlayerStatusLabel.RichText = true
PlayerStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
PlayerStatusLabel.ZIndex = 4
PlayerStatusLabel.Parent = PlayerStatusBar
local sp2 = Instance.new("UIPadding", PlayerStatusLabel)
sp2.PaddingTop = UDim.new(0, 8); sp2.PaddingBottom = UDim.new(0, 8)
sp2.PaddingLeft = UDim.new(0, 10); sp2.PaddingRight = UDim.new(0, 10)

local function updateStatusBar(text, color)
    if text == "" then
        PlayerStatusBar.Visible = false
    else
        PlayerStatusBar.Visible = true
        PlayerStatusLabel.Text = text
        if color then PlayerStatusBar.BackgroundColor3 = color end
    end
end

local StopAllBtn = createButton("🛑 Stop All Actions", PlayersContent, nil, 2)
StopAllBtn.BackgroundColor3 = Color3.fromRGB(100, 25, 25)

-- Search
local SearchFrame = Instance.new("Frame")
SearchFrame.Size = UDim2.new(1, -4, 0, isMobile and 44 or 38)
SearchFrame.BackgroundColor3 = Color3.fromRGB(38, 38, 54)
SearchFrame.ZIndex = 3
SearchFrame.LayoutOrder = 3
SearchFrame.Parent = PlayersContent
Instance.new("UICorner", SearchFrame).CornerRadius = UDim.new(0, 10)

local SearchIcon2 = Instance.new("TextLabel")
SearchIcon2.Size = UDim2.new(0, 32, 1, 0)
SearchIcon2.Position = UDim2.new(0, 5, 0, 0)
SearchIcon2.BackgroundTransparency = 1
SearchIcon2.Text = "🔍"
SearchIcon2.TextSize = isMobile and 16 or 14
SearchIcon2.ZIndex = 4
SearchIcon2.Parent = SearchFrame

local SearchBox = Instance.new("TextBox")
SearchBox.Size = UDim2.new(1, -40, 1, -8)
SearchBox.Position = UDim2.new(0, 35, 0, 4)
SearchBox.BackgroundTransparency = 1
SearchBox.PlaceholderText = "Search player..."
SearchBox.PlaceholderColor3 = Color3.fromRGB(110, 110, 140)
SearchBox.Text = ""
SearchBox.TextColor3 = Color3.new(1, 1, 1)
SearchBox.TextSize = isMobile and 14 or 12
SearchBox.Font = Enum.Font.Gotham
SearchBox.TextXAlignment = Enum.TextXAlignment.Left
SearchBox.ClearTextOnFocus = false
SearchBox.ZIndex = 4
SearchBox.Parent = SearchFrame

local PlayerCountLabel = Instance.new("TextLabel")
PlayerCountLabel.Size = UDim2.new(1, -4, 0, 22)
PlayerCountLabel.BackgroundTransparency = 1
PlayerCountLabel.Text = "👥 Players: 0"
PlayerCountLabel.TextColor3 = Color3.fromRGB(150, 150, 190)
PlayerCountLabel.TextSize = isMobile and 11 or 10
PlayerCountLabel.Font = Enum.Font.Gotham
PlayerCountLabel.ZIndex = 3
PlayerCountLabel.LayoutOrder = 4
PlayerCountLabel.Parent = PlayersContent

local PlayerListFrame = Instance.new("Frame")
PlayerListFrame.Size = UDim2.new(1, -4, 0, 20)
PlayerListFrame.BackgroundTransparency = 1
PlayerListFrame.AutomaticSize = Enum.AutomaticSize.Y
PlayerListFrame.ZIndex = 3
PlayerListFrame.LayoutOrder = 5
PlayerListFrame.Parent = PlayersContent
Instance.new("UIListLayout", PlayerListFrame).Padding = UDim.new(0, 5)

-- TP Confirm Dialog
local ConfirmOverlay = Instance.new("Frame")
ConfirmOverlay.Size = UDim2.new(1, 0, 1, 0)
ConfirmOverlay.BackgroundColor3 = Color3.new(0, 0, 0)
ConfirmOverlay.BackgroundTransparency = 0.4
ConfirmOverlay.ZIndex = 50
ConfirmOverlay.Visible = false
ConfirmOverlay.Parent = ScreenGui

local ConfirmBox = Instance.new("Frame")
ConfirmBox.Size = isMobile and UDim2.new(0.88, 0, 0, 280) or UDim2.new(0, 360, 0, 260)
ConfirmBox.AnchorPoint = Vector2.new(0.5, 0.5)
ConfirmBox.Position = UDim2.new(0.5, 0, 0.5, 0)
ConfirmBox.BackgroundColor3 = Color3.fromRGB(32, 22, 28)
ConfirmBox.ZIndex = 51
ConfirmBox.Parent = ConfirmOverlay
Instance.new("UICorner", ConfirmBox).CornerRadius = UDim.new(0, 14)
local cStroke = Instance.new("UIStroke", ConfirmBox)
cStroke.Color = Color3.fromRGB(220, 70, 70)
cStroke.Thickness = 3

local ConfirmTitle2 = Instance.new("TextLabel")
ConfirmTitle2.Size = UDim2.new(1, 0, 0, 44)
ConfirmTitle2.BackgroundTransparency = 1
ConfirmTitle2.Text = "⚠️ TELEPORT WARNING"
ConfirmTitle2.TextColor3 = Color3.fromRGB(255, 90, 90)
ConfirmTitle2.TextSize = isMobile and 19 or 17
ConfirmTitle2.Font = Enum.Font.GothamBold
ConfirmTitle2.ZIndex = 52
ConfirmTitle2.Parent = ConfirmBox

local ConfirmMsg = Instance.new("TextLabel")
ConfirmMsg.Size = UDim2.new(1, -20, 0, 120)
ConfirmMsg.Position = UDim2.new(0, 10, 0, 44)
ConfirmMsg.BackgroundTransparency = 1
ConfirmMsg.Text = ""
ConfirmMsg.TextColor3 = Color3.fromRGB(255, 200, 200)
ConfirmMsg.TextSize = isMobile and 13 or 11
ConfirmMsg.Font = Enum.Font.Gotham
ConfirmMsg.TextWrapped = true
ConfirmMsg.RichText = true
ConfirmMsg.TextYAlignment = Enum.TextYAlignment.Top
ConfirmMsg.ZIndex = 52
ConfirmMsg.Parent = ConfirmBox

local ConfirmBtnRow = Instance.new("Frame")
ConfirmBtnRow.Size = UDim2.new(1, -20, 0, isMobile and 48 or 40)
ConfirmBtnRow.Position = UDim2.new(0, 10, 1, -(isMobile and 58 or 50))
ConfirmBtnRow.BackgroundTransparency = 1
ConfirmBtnRow.ZIndex = 52
ConfirmBtnRow.Parent = ConfirmBox
local cbLayout = Instance.new("UIListLayout", ConfirmBtnRow)
cbLayout.FillDirection = Enum.FillDirection.Horizontal
cbLayout.Padding = UDim.new(0, 10)
cbLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

local CancelTPBtn = Instance.new("TextButton")
CancelTPBtn.Size = UDim2.new(0.45, 0, 1, 0)
CancelTPBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 78)
CancelTPBtn.Text = "❌ Cancel"
CancelTPBtn.TextColor3 = Color3.new(1, 1, 1)
CancelTPBtn.TextSize = isMobile and 15 or 13
CancelTPBtn.Font = Enum.Font.GothamBold
CancelTPBtn.ZIndex = 53
CancelTPBtn.AutoButtonColor = false
CancelTPBtn.LayoutOrder = 1
CancelTPBtn.Parent = ConfirmBtnRow
Instance.new("UICorner", CancelTPBtn).CornerRadius = UDim.new(0, 10)

local ConfirmTPBtn = Instance.new("TextButton")
ConfirmTPBtn.Size = UDim2.new(0.45, 0, 1, 0)
ConfirmTPBtn.BackgroundColor3 = Color3.fromRGB(170, 45, 45)
ConfirmTPBtn.Text = "⚡ TELEPORT"
ConfirmTPBtn.TextColor3 = Color3.new(1, 1, 1)
ConfirmTPBtn.TextSize = isMobile and 15 or 13
ConfirmTPBtn.Font = Enum.Font.GothamBold
ConfirmTPBtn.ZIndex = 53
ConfirmTPBtn.AutoButtonColor = false
ConfirmTPBtn.LayoutOrder = 2
ConfirmTPBtn.Parent = ConfirmBtnRow
Instance.new("UICorner", ConfirmTPBtn).CornerRadius = UDim.new(0, 10)

local pendingTPTarget = nil

CancelTPBtn.MouseButton1Click:Connect(function()
    ConfirmOverlay.Visible = false
    pendingTPTarget = nil
    PlayerAction.TPConfirmPending = false
end)

ConfirmTPBtn.MouseButton1Click:Connect(function()
    ConfirmOverlay.Visible = false
    PlayerAction.TPConfirmPending = false
    if pendingTPTarget and pendingTPTarget.Character and pendingTPTarget.Character:FindFirstChild("HumanoidRootPart") then
        pcall(function()
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local tCF = pendingTPTarget.Character.HumanoidRootPart.CFrame
                player.Character.HumanoidRootPart.CFrame = tCF * CFrame.new(2, 0, 2)
                updateStatusBar("📌 Teleported to <b>" .. pendingTPTarget.Name .. "</b>!", Color3.fromRGB(25, 55, 40))
                showNotif("📌 TP to " .. pendingTPTarget.Name, Color3.fromRGB(25, 55, 40))
            end
        end)
    else
        updateStatusBar("❌ Player not found!", Color3.fromRGB(55, 25, 25))
    end
    pendingTPTarget = nil
end)

-- Player Action Functions
local function stopSpectate()
    if PlayerAction.IsSpectating then
        PlayerAction.IsSpectating = false
        PlayerAction.SpectateTarget = nil
        pcall(function()
            if player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
                Camera.CameraSubject = player.Character:FindFirstChildOfClass("Humanoid")
                Camera.CameraType = Enum.CameraType.Custom
            end
        end)
    end
end

local function stopFollow()
    if PlayerAction.IsFollowing then
        PlayerAction.IsFollowing = false
        PlayerAction.FollowTarget = nil
        if Connections.Follow then
            Connections.Follow:Disconnect()
            Connections.Follow = nil
        end
    end
end

local function stopAllActions()
    stopSpectate()
    stopFollow()
    updateStatusBar("")
end

local function startSpectate(targetPlr)
    if targetPlr == player then return end
    stopAllActions()

    if targetPlr.Character and targetPlr.Character:FindFirstChildOfClass("Humanoid") then
        PlayerAction.IsSpectating = true
        PlayerAction.SpectateTarget = targetPlr

        pcall(function()
            Camera.CameraSubject = targetPlr.Character:FindFirstChildOfClass("Humanoid")
            Camera.CameraType = Enum.CameraType.Custom
        end)

        updateStatusBar("👁️ Spectating: <b>" .. targetPlr.Name .. "</b>", Color3.fromRGB(25, 40, 60))

        local checkConn
        checkConn = RunService.Heartbeat:Connect(function()
            if not PlayerAction.IsSpectating or PlayerAction.SpectateTarget ~= targetPlr then
                checkConn:Disconnect()
                return
            end
            if not targetPlr or not targetPlr.Parent or not targetPlr.Character then
                stopSpectate()
                updateStatusBar("⚠️ Spectate ended", Color3.fromRGB(55, 45, 25))
                checkConn:Disconnect()
            end
        end)
        table.insert(Connections, checkConn)
        showNotif("👁️ Spectating " .. targetPlr.Name, Color3.fromRGB(25, 40, 80))
    else
        updateStatusBar("❌ Cannot spectate - no character!", Color3.fromRGB(55, 25, 25))
    end
end

local function startFollow(targetPlr)
    if targetPlr == player then return end
    stopAllActions()

    if targetPlr.Character and targetPlr.Character:FindFirstChild("HumanoidRootPart") then
        PlayerAction.IsFollowing = true
        PlayerAction.FollowTarget = targetPlr

        updateStatusBar("🚶 Following: <b>" .. targetPlr.Name .. "</b>", Color3.fromRGB(25, 48, 30))

        Connections.Follow = RunService.Heartbeat:Connect(function()
            pcall(function()
                if not PlayerAction.IsFollowing or PlayerAction.FollowTarget ~= targetPlr then return end

                if not targetPlr or not targetPlr.Parent or not targetPlr.Character
                    or not targetPlr.Character:FindFirstChild("HumanoidRootPart") then
                    stopFollow()
                    updateStatusBar("⚠️ Follow ended", Color3.fromRGB(55, 45, 25))
                    return
                end

                if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end

                local myHRP = player.Character.HumanoidRootPart
                local targetHRP = targetPlr.Character.HumanoidRootPart
                local hum = player.Character:FindFirstChildOfClass("Humanoid")
                local dist = (myHRP.Position - targetHRP.Position).Magnitude

                if dist > 6 and hum then
                    hum:MoveTo(targetHRP.Position)
                end
            end)
        end)
        showNotif("🚶 Following " .. targetPlr.Name, Color3.fromRGB(25, 60, 30))
    else
        updateStatusBar("❌ Cannot follow - no character!", Color3.fromRGB(55, 25, 25))
    end
end

local function requestTP(targetPlr)
    if targetPlr == player or PlayerAction.TPConfirmPending then return end
    PlayerAction.TPConfirmPending = true
    pendingTPTarget = targetPlr

    local dist = "?"
    pcall(function()
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            and targetPlr.Character and targetPlr.Character:FindFirstChild("HumanoidRootPart") then
            dist = tostring(math.floor(
                (player.Character.HumanoidRootPart.Position - targetPlr.Character.HumanoidRootPart.Position).Magnitude
            ))
        end
    end)

    ConfirmMsg.Text = string.format(
        "Target: <b>%s</b>\n📏 Distance: <b>%s studs</b>\n\n" ..
        "🚨 Risks:\n• Anti-cheat detection → BAN\n• Stuck in object\n• Position reset\n\nYakin teleport?",
        targetPlr.Name, dist
    )
    ConfirmOverlay.Visible = true
end

StopAllBtn.MouseButton1Click:Connect(function()
    stopAllActions()
    showNotif("🛑 All actions stopped", Color3.fromRGB(60, 30, 30))
end)

-- Create Player Entry
local function clearPlayerList()
    for _, child in ipairs(PlayerListFrame:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
end

local function createPlayerEntry(targetPlr, index)
    if targetPlr == player then return end

    local entry = Instance.new("Frame")
    entry.Size = UDim2.new(1, 0, 0, isMobile and 88 or 76)
    entry.BackgroundColor3 = Color3.fromRGB(36, 36, 52)
    entry.ZIndex = 4
    entry.LayoutOrder = index
    entry.Parent = PlayerListFrame
    Instance.new("UICorner", entry).CornerRadius = UDim.new(0, 10)
    Instance.new("UIStroke", entry).Color = Color3.fromRGB(50, 50, 70)

    -- Avatar
    local av = Instance.new("Frame")
    av.Size = UDim2.new(0, isMobile and 42 or 36, 0, isMobile and 42 or 36)
    av.Position = UDim2.new(0, 8, 0, 8)
    av.BackgroundColor3 = Color3.fromRGB(55, 55, 88)
    av.ZIndex = 5
    av.Parent = entry
    Instance.new("UICorner", av).CornerRadius = UDim.new(0.5, 0)

    local avTxt = Instance.new("TextLabel")
    avTxt.Size = UDim2.new(1, 0, 1, 0)
    avTxt.BackgroundTransparency = 1
    avTxt.Text = string.sub(targetPlr.Name, 1, 2):upper()
    avTxt.TextColor3 = Color3.new(1, 1, 1)
    avTxt.TextSize = isMobile and 15 or 13
    avTxt.Font = Enum.Font.GothamBold
    avTxt.ZIndex = 6
    avTxt.Parent = av

    local ofsX = isMobile and 56 or 48

    local nameL = Instance.new("TextLabel")
    nameL.Size = UDim2.new(1, -(ofsX + 5), 0, 20)
    nameL.Position = UDim2.new(0, ofsX, 0, 6)
    nameL.BackgroundTransparency = 1
    nameL.Text = targetPlr.Name
    nameL.TextColor3 = Color3.new(1, 1, 1)
    nameL.TextSize = isMobile and 13 or 11
    nameL.Font = Enum.Font.GothamBold
    nameL.TextXAlignment = Enum.TextXAlignment.Left
    nameL.TextTruncate = Enum.TextTruncate.AtEnd
    nameL.ZIndex = 5
    nameL.Parent = entry

    -- HP Display (Live Update)
    local hpL = Instance.new("TextLabel")
    hpL.Size = UDim2.new(1, -(ofsX + 5), 0, 16)
    hpL.Position = UDim2.new(0, ofsX, 0, 24)
    hpL.BackgroundTransparency = 1
    hpL.TextColor3 = Color3.fromRGB(130, 130, 160)
    hpL.TextSize = isMobile and 10 or 9
    hpL.Font = Enum.Font.Gotham
    hpL.TextXAlignment = Enum.TextXAlignment.Left
    hpL.ZIndex = 5
    hpL.Parent = entry

    -- Live HP update
    spawn(function()
        while entry.Parent do
            pcall(function()
                if targetPlr.Character then
                    local hum = targetPlr.Character:FindFirstChildOfClass("Humanoid")
                    local hrp = targetPlr.Character:FindFirstChild("HumanoidRootPart")
                    if hum and hrp then
                        local dist2 = 0
                        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                            dist2 = math.floor((player.Character.HumanoidRootPart.Position - hrp.Position).Magnitude)
                        end
                        hpL.Text = string.format("❤️ %.0f/%.0f | 📏 %d st", hum.Health, hum.MaxHealth, dist2)
                    end
                else
                    hpL.Text = "💀 No Character"
                end
            end)
            task.wait(0.5)
        end
    end)

    -- Buttons
    local btnRow = Instance.new("Frame")
    btnRow.Size = UDim2.new(1, -12, 0, isMobile and 30 or 26)
    btnRow.Position = UDim2.new(0, 6, 1, -(isMobile and 36 or 32))
    btnRow.BackgroundTransparency = 1
    btnRow.ZIndex = 5
    btnRow.Parent = entry
    local brl = Instance.new("UIListLayout", btnRow)
    brl.FillDirection = Enum.FillDirection.Horizontal
    brl.Padding = UDim.new(0, 5)

    local function makeBtn(txt, col, cbk)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0, isMobile and 86 or 76, 1, 0)
        b.BackgroundColor3 = col
        b.Text = txt
        b.TextColor3 = Color3.new(1, 1, 1)
        b.TextSize = isMobile and 11 or 9
        b.Font = Enum.Font.GothamBold
        b.ZIndex = 6
        b.AutoButtonColor = false
        b.Parent = btnRow
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
        b.MouseButton1Click:Connect(cbk)
        b.MouseEnter:Connect(function()
            TweenService:Create(b, TweenInfo.new(0.1), {BackgroundTransparency = 0.3}):Play()
        end)
        b.MouseLeave:Connect(function()
            TweenService:Create(b, TweenInfo.new(0.1), {BackgroundTransparency = 0}):Play()
        end)
        return b
    end

    makeBtn("📌 TP", Color3.fromRGB(140, 35, 35), function() requestTP(targetPlr) end)
    makeBtn("👁️ Spec", Color3.fromRGB(35, 65, 140), function() startSpectate(targetPlr) end)
    makeBtn("🚶 Follow", Color3.fromRGB(35, 90, 45), function() startFollow(targetPlr) end)

    return entry
end

function refreshPlayerList(filter)
    clearPlayerList()
    filter = (filter or ""):lower()

    local plrs = Players:GetPlayers()
    local count = 0

    for i, plr in ipairs(plrs) do
        if plr ~= player then
            local match = filter == ""
                or plr.Name:lower():find(filter, 1, true)
                or plr.DisplayName:lower():find(filter, 1, true)
            if match then
                createPlayerEntry(plr, i)
                count += 1
            end
        end
    end

    PlayerCountLabel.Text = string.format("👥 %d players (excluding you)", count)
end

SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
    refreshPlayerList(SearchBox.Text)
end)

Players.PlayerAdded:Connect(function()
    task.wait(0.5)
    if currentTab == "players" then refreshPlayerList(SearchBox.Text) end
    if ToggleStates.ESP then
        task.wait(1)
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= player and not ESP[plr] then createPlayerESP(plr) end
        end
    end
end)

Players.PlayerRemoving:Connect(function(plr)
    cleanupPlayerESP(plr)
    if PlayerAction.SpectateTarget == plr then stopSpectate() end
    if PlayerAction.FollowTarget == plr then stopFollow() end
    if pendingTPTarget == plr then
        ConfirmOverlay.Visible = false
        pendingTPTarget = nil
        PlayerAction.TPConfirmPending = false
    end
    task.wait(0.3)
    if currentTab == "players" then refreshPlayerList(SearchBox.Text) end
end)

-- ════════════════════════════════════════════
-- SERVER TAB (IMPROVED)
-- ════════════════════════════════════════════
local ServerStatus = Instance.new("TextLabel")
ServerStatus.Size = UDim2.new(1, -4, 0, 26)
ServerStatus.BackgroundColor3 = Color3.fromRGB(28, 28, 46)
ServerStatus.Text = "  🌐 Tap Refresh to load servers"
ServerStatus.TextColor3 = Color3.fromRGB(130, 190, 255)
ServerStatus.TextSize = isMobile and 12 or 10
ServerStatus.Font = Enum.Font.GothamBold
ServerStatus.TextXAlignment = Enum.TextXAlignment.Left
ServerStatus.ZIndex = 3
ServerStatus.LayoutOrder = 0
ServerStatus.Parent = ServerContent
Instance.new("UICorner", ServerStatus).CornerRadius = UDim.new(0, 8)

-- Sort options
local SortRow = Instance.new("Frame")
SortRow.Size = UDim2.new(1, -4, 0, isMobile and 38 or 32)
SortRow.BackgroundColor3 = Color3.fromRGB(35, 35, 52)
SortRow.ZIndex = 3
SortRow.LayoutOrder = 1
SortRow.Parent = ServerContent
Instance.new("UICorner", SortRow).CornerRadius = UDim.new(0, 8)

local SortLabel = Instance.new("TextLabel")
SortLabel.Size = UDim2.new(0.35, 0, 1, 0)
SortLabel.Position = UDim2.new(0, 8, 0, 0)
SortLabel.BackgroundTransparency = 1
SortLabel.Text = "Sort:"
SortLabel.TextColor3 = Color3.new(1, 1, 1)
SortLabel.TextSize = isMobile and 12 or 10
SortLabel.Font = Enum.Font.GothamBold
SortLabel.TextXAlignment = Enum.TextXAlignment.Left
SortLabel.ZIndex = 4
SortLabel.Parent = SortRow

local sortBtns = {}
local function createSortBtn(text, value, posX)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, isMobile and 80 or 70, 0, isMobile and 26 or 22)
    btn.Position = UDim2.new(0, posX, 0.5, -(isMobile and 13 or 11))
    btn.BackgroundColor3 = (ServerHopData.SortMode == value) and Color3.fromRGB(70, 90, 255) or Color3.fromRGB(48, 48, 68)
    btn.Text = text
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.TextSize = isMobile and 11 or 9
    btn.Font = Enum.Font.GothamBold
    btn.ZIndex = 5
    btn.AutoButtonColor = false
    btn.Parent = SortRow
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    sortBtns[value] = btn
    return btn
end

local sortByPlayers = createSortBtn("👥 Players", "players", isMobile and 120 or 105)
local sortByID = createSortBtn("🆔 ID", "id", isMobile and 210 or 183)

local function updateSortBtns()
    for v, b in pairs(sortBtns) do
        b.BackgroundColor3 = (ServerHopData.SortMode == v)
            and Color3.fromRGB(70, 90, 255) or Color3.fromRGB(48, 48, 68)
    end
end

-- Controls
local ControlRow = Instance.new("Frame")
ControlRow.Size = UDim2.new(1, -4, 0, isMobile and 42 or 36)
ControlRow.BackgroundTransparency = 1
ControlRow.ZIndex = 3
ControlRow.LayoutOrder = 2
ControlRow.Parent = ServerContent
local cl = Instance.new("UIListLayout", ControlRow)
cl.FillDirection = Enum.FillDirection.Horizontal
cl.Padding = UDim.new(0, 4)
cl.HorizontalAlignment = Enum.HorizontalAlignment.Center

local function makeCtrlBtn(text, color, order)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0.32, 0, 1, 0)
    b.BackgroundColor3 = color
    b.Text = text
    b.TextColor3 = Color3.new(1, 1, 1)
    b.TextSize = isMobile and 11 or 9
    b.Font = Enum.Font.GothamBold
    b.ZIndex = 4
    b.AutoButtonColor = false
    b.LayoutOrder = order
    b.Parent = ControlRow
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
    return b
end

local PrevBtn = makeCtrlBtn("◀ Prev", Color3.fromRGB(46, 46, 70), 1)
local RefreshBtn = makeCtrlBtn("🔄 Refresh", Color3.fromRGB(40, 90, 40), 2)
local NextBtn = makeCtrlBtn("Next ▶", Color3.fromRGB(46, 46, 70), 3)

-- Per page
local PerPageRow = Instance.new("Frame")
PerPageRow.Size = UDim2.new(1, -4, 0, 32)
PerPageRow.BackgroundTransparency = 1
PerPageRow.ZIndex = 3
PerPageRow.LayoutOrder = 3
PerPageRow.Parent = ServerContent
local prl = Instance.new("UIListLayout", PerPageRow)
prl.FillDirection = Enum.FillDirection.Horizontal
prl.Padding = UDim.new(0, 5)
prl.HorizontalAlignment = Enum.HorizontalAlignment.Center

local function makePerPageBtn(text, value)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, isMobile and 65 or 58, 0, isMobile and 28 or 26)
    b.BackgroundColor3 = (ServerHopData.PerPage == value) and Color3.fromRGB(70, 90, 255) or Color3.fromRGB(48, 48, 68)
    b.Text = text
    b.TextColor3 = Color3.new(1, 1, 1)
    b.TextSize = isMobile and 12 or 10
    b.Font = Enum.Font.GothamBold
    b.ZIndex = 4
    b.AutoButtonColor = false
    b.Parent = PerPageRow
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
    return b
end

local perPageLabel = Instance.new("TextLabel")
perPageLabel.Size = UDim2.new(0, isMobile and 70 or 60, 0, 26)
perPageLabel.BackgroundTransparency = 1
perPageLabel.Text = "Per page:"
perPageLabel.TextColor3 = Color3.fromRGB(160, 160, 200)
perPageLabel.TextSize = isMobile and 11 or 9
perPageLabel.Font = Enum.Font.GothamBold
perPageLabel.ZIndex = 4
perPageLabel.Parent = PerPageRow

local pp25 = makePerPageBtn("25", 25)
local pp50 = makePerPageBtn("50", 50)
local pp100 = makePerPageBtn("100", 100)

local function updatePerPageVisual()
    local btns = {[25] = pp25, [50] = pp50, [100] = pp100}
    for v, b in pairs(btns) do
        b.BackgroundColor3 = (ServerHopData.PerPage == v)
            and Color3.fromRGB(70, 90, 255) or Color3.fromRGB(48, 48, 68)
    end
end

local PageIndicator = Instance.new("TextLabel")
PageIndicator.Size = UDim2.new(1, -4, 0, 22)
PageIndicator.BackgroundColor3 = Color3.fromRGB(32, 32, 48)
PageIndicator.Text = "Page 0 / 0 | 0 servers"
PageIndicator.TextColor3 = Color3.fromRGB(170, 170, 255)
PageIndicator.TextSize = isMobile and 11 or 9
PageIndicator.Font = Enum.Font.GothamBold
PageIndicator.ZIndex = 3
PageIndicator.LayoutOrder = 4
PageIndicator.Parent = ServerContent
Instance.new("UICorner", PageIndicator).CornerRadius = UDim.new(0, 6)

local RandomBtn = createButton("🎲 Join Random Server", ServerContent, nil, 5)
local BestServerBtn = createButton("⭐ Join Best Server (Most Players)", ServerContent, nil, 6)

local ServerListFrame = Instance.new("Frame")
ServerListFrame.Size = UDim2.new(1, -4, 0, 20)
ServerListFrame.BackgroundTransparency = 1
ServerListFrame.AutomaticSize = Enum.AutomaticSize.Y
ServerListFrame.ZIndex = 3
ServerListFrame.LayoutOrder = 7
ServerListFrame.Parent = ServerContent
local sll = Instance.new("UIListLayout", ServerListFrame)
sll.Padding = UDim.new(0, 4)
sll.SortOrder = Enum.SortOrder.LayoutOrder

local function clearServerList()
    for _, c in ipairs(ServerListFrame:GetChildren()) do
        if not c:IsA("UIListLayout") then c:Destroy() end
    end
end

local function createServerEntry(sData, index)
    local entry = Instance.new("Frame")
    entry.Size = UDim2.new(1, 0, 0, isMobile and 62 or 54)
    entry.BackgroundColor3 = Color3.fromRGB(36, 36, 52)
    entry.ZIndex = 4
    entry.LayoutOrder = index
    entry.Parent = ServerListFrame
    Instance.new("UICorner", entry).CornerRadius = UDim.new(0, 8)

    local sID = sData.id or "?"
    local playing = sData.playing or 0
    local maxP = sData.maxPlayers or 0
    local isCurrent = (sID == game.JobId)
    local fillRatio = maxP > 0 and (playing / maxP) or 0

    local fillColor = fillRatio > 0.85 and "rgb(255,70,70)"
        or fillRatio > 0.5 and "rgb(255,200,70)"
        or "rgb(80,255,120)"

    local infoL = Instance.new("TextLabel")
    infoL.Size = UDim2.new(0.65, 0, 0.5, 0)
    infoL.Position = UDim2.new(0, 8, 0, 4)
    infoL.BackgroundTransparency = 1
    infoL.Text = isCurrent and ("⭐ #" .. index .. " [CURRENT]") or ("#" .. index .. " " .. string.sub(sID, 1, 12) .. "...")
    infoL.TextColor3 = isCurrent and Color3.fromRGB(255, 215, 70) or Color3.fromRGB(190, 190, 255)
    infoL.TextSize = isMobile and 10 or 9
    infoL.Font = Enum.Font.GothamBold
    infoL.TextXAlignment = Enum.TextXAlignment.Left
    infoL.ZIndex = 5
    infoL.Parent = entry

    local detL = Instance.new("TextLabel")
    detL.Size = UDim2.new(0.65, 0, 0.45, 0)
    detL.Position = UDim2.new(0, 8, 0.5, 0)
    detL.BackgroundTransparency = 1
    detL.RichText = true
    detL.Text = string.format("👥 <font color='%s'><b>%d</b>/%d</font>", fillColor, playing, maxP)
    detL.TextColor3 = Color3.fromRGB(160, 160, 200)
    detL.TextSize = isMobile and 9 or 8
    detL.Font = Enum.Font.Gotham
    detL.TextXAlignment = Enum.TextXAlignment.Left
    detL.ZIndex = 5
    detL.Parent = entry

    -- Fill bar
    local fillBG = Instance.new("Frame")
    fillBG.Size = UDim2.new(0.6, 0, 0, 4)
    fillBG.Position = UDim2.new(0, 8, 1, -8)
    fillBG.BackgroundColor3 = Color3.fromRGB(30, 30, 46)
    fillBG.ZIndex = 5
    fillBG.Parent = entry
    Instance.new("UICorner", fillBG).CornerRadius = UDim.new(1, 0)

    local fillBar = Instance.new("Frame")
    fillBar.Size = UDim2.new(fillRatio, 0, 1, 0)
    fillBar.BackgroundColor3 = fillRatio > 0.85 and Color3.fromRGB(255, 70, 70)
        or fillRatio > 0.5 and Color3.fromRGB(255, 200, 70)
        or Color3.fromRGB(80, 255, 120)
    fillBar.ZIndex = 6
    fillBar.Parent = fillBG
    Instance.new("UICorner", fillBar).CornerRadius = UDim.new(1, 0)

    local joinBtn = Instance.new("TextButton")
    joinBtn.Size = UDim2.new(0, isMobile and 62 or 55, 0, isMobile and 28 or 24)
    joinBtn.Position = UDim2.new(1, -(isMobile and 70 or 63), 0.5, -(isMobile and 14 or 12))
    joinBtn.BackgroundColor3 = isCurrent and Color3.fromRGB(50, 50, 70) or Color3.fromRGB(40, 105, 40)
    joinBtn.Text = isCurrent and "Here" or "Join"
    joinBtn.TextColor3 = Color3.new(1, 1, 1)
    joinBtn.TextSize = isMobile and 12 or 10
    joinBtn.Font = Enum.Font.GothamBold
    joinBtn.ZIndex = 6
    joinBtn.AutoButtonColor = not isCurrent
    joinBtn.Parent = entry
    Instance.new("UICorner", joinBtn).CornerRadius = UDim.new(0, 6)

    if not isCurrent then
        joinBtn.MouseButton1Click:Connect(function()
            joinBtn.Text = "..."
            joinBtn.BackgroundColor3 = Color3.fromRGB(130, 115, 25)
            pcall(function()
                TeleportService:TeleportToPlaceInstance(game.PlaceId, sID, player)
            end)
            task.wait(4)
            joinBtn.Text = "Join"
            joinBtn.BackgroundColor3 = Color3.fromRGB(40, 105, 40)
        end)
    end
end

local function getSortedServers()
    local sorted = table.clone(ServerHopData.Servers)
    if ServerHopData.SortMode == "players" then
        table.sort(sorted, function(a, b)
            return (a.playing or 0) > (b.playing or 0)
        end)
    end
    return sorted
end

local function displayServerPage()
    clearServerList()
    local servers = getSortedServers()
    local pp = ServerHopData.PerPage
    local page = ServerHopData.CurrentPage
    local total = #servers

    ServerHopData.TotalPages = math.max(1, math.ceil(total / pp))
    ServerHopData.CurrentPage = math.clamp(page, 1, ServerHopData.TotalPages)
    page = ServerHopData.CurrentPage

    PageIndicator.Text = string.format("Page %d / %d | %d servers total", page, ServerHopData.TotalPages, total)

    if total == 0 then
        local nd = Instance.new("TextLabel")
        nd.Size = UDim2.new(1, 0, 0, 40)
        nd.BackgroundTransparency = 1
        nd.Text = "No servers found. Tap Refresh!"
        nd.TextColor3 = Color3.fromRGB(140, 140, 170)
        nd.TextSize = isMobile and 12 or 10
        nd.Font = Enum.Font.Gotham
        nd.ZIndex = 4
        nd.Parent = ServerListFrame
        return
    end

    local s = (page - 1) * pp + 1
    local e = math.min(page * pp, total)

    for i = s, e do
        if servers[i] then createServerEntry(servers[i], i) end
    end

    PrevBtn.BackgroundColor3 = page > 1 and Color3.fromRGB(46, 60, 100) or Color3.fromRGB(36, 36, 52)
    NextBtn.BackgroundColor3 = page < ServerHopData.TotalPages and Color3.fromRGB(46, 60, 100) or Color3.fromRGB(36, 36, 52)
end

-- Fetch with retry
local function fetchAllServers()
    if ServerHopData.IsLoading then return end
    ServerHopData.IsLoading = true
    ServerHopData.Servers = {}
    ServerHopData.CurrentPage = 1

    ServerStatus.Text = "  ⏳ Loading servers..."
    RefreshBtn.Text = "⏳..."
    RefreshBtn.BackgroundColor3 = Color3.fromRGB(110, 90, 20)
    clearServerList()

    local allSrv = {}
    local cursor = ""
    local pages = 0
    local maxRetry = 3

    local ok, err = pcall(function()
        repeat
            pages += 1
            local url = string.format(
                "https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100%s",
                game.PlaceId,
                cursor ~= "" and ("&cursor=" .. cursor) or ""
            )

            local resp = nil
            local retry = 0
            repeat
                local success, result = pcall(function()
                    return HttpService:JSONDecode(game:HttpGet(url))
                end)
                if success then resp = result end
                retry += 1
                if not success and retry < maxRetry then task.wait(1) end
            until resp ~= nil or retry >= maxRetry

            if not resp then break end

            if resp.data then
                for _, s in ipairs(resp.data) do
                    if s.id and s.playing and s.maxPlayers then
                        table.insert(allSrv, s)
                    end
                end
            end

            cursor = resp.nextPageCursor or ""
            ServerStatus.Text = string.format("  ⏳ %d servers (page %d)...", #allSrv, pages)
            if cursor ~= "" and pages < 25 then task.wait(0.25) end
        until cursor == "" or pages >= 25
    end)

    ServerHopData.Servers = allSrv
    ServerHopData.IsLoading = false
    RefreshBtn.Text = "🔄 Refresh"
    RefreshBtn.BackgroundColor3 = Color3.fromRGB(40, 90, 40)

    if ok then
        ServerStatus.Text = string.format("  ✅ %d servers loaded", #allSrv)
        showNotif("🌐 " .. #allSrv .. " servers loaded", Color3.fromRGB(20, 60, 40))
    else
        ServerStatus.Text = "  ❌ Failed to load servers"
        showNotif("❌ Server load failed!", Color3.fromRGB(70, 20, 20))
    end

    displayServerPage()
end

RefreshBtn.MouseButton1Click:Connect(function() task.spawn(fetchAllServers) end)
PrevBtn.MouseButton1Click:Connect(function()
    if ServerHopData.CurrentPage > 1 then ServerHopData.CurrentPage -= 1 displayServerPage() end
end)
NextBtn.MouseButton1Click:Connect(function()
    if ServerHopData.CurrentPage < ServerHopData.TotalPages then ServerHopData.CurrentPage += 1 displayServerPage() end
end)
pp25.MouseButton1Click:Connect(function()
    ServerHopData.PerPage = 25 ServerHopData.CurrentPage = 1 updatePerPageVisual() displayServerPage()
end)
pp50.MouseButton1Click:Connect(function()
    ServerHopData.PerPage = 50 ServerHopData.CurrentPage = 1 updatePerPageVisual() displayServerPage()
end)
pp100.MouseButton1Click:Connect(function()
    ServerHopData.PerPage = 100 ServerHopData.CurrentPage = 1 updatePerPageVisual() displayServerPage()
end)
sortByPlayers.MouseButton1Click:Connect(function()
    ServerHopData.SortMode = "players" updateSortBtns() displayServerPage()
end)
sortByID.MouseButton1Click:Connect(function()
    ServerHopData.SortMode = "id" updateSortBtns() displayServerPage()
end)

RandomBtn.MouseButton1Click:Connect(function()
    local avail = {}
    for _, s in ipairs(ServerHopData.Servers) do
        if s.id ~= game.JobId and s.playing and s.maxPlayers and s.playing < s.maxPlayers then
            table.insert(avail, s)
        end
    end
    if #avail == 0 then
        showNotif("⚠️ No servers! Load first!", Color3.fromRGB(80, 50, 20))
        return
    end
    local chosen = avail[math.random(#avail)]
    showNotif("🎲 Joining random server...", Color3.fromRGB(30, 50, 90))
    pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, chosen.id, player) end)
end)

BestServerBtn.MouseButton1Click:Connect(function()
    local best = nil
    local bestCount = -1
    for _, s in ipairs(ServerHopData.Servers) do
        if s.id ~= game.JobId and (s.playing or 0) > bestCount
            and (s.playing or 0) < (s.maxPlayers or 0) then
            best = s
            bestCount = s.playing
        end
    end
    if not best then
        showNotif("⚠️ No servers! Load first!", Color3.fromRGB(80, 50, 20))
        return
    end
    showNotif("⭐ Joining best server (" .. bestCount .. " players)...", Color3.fromRGB(30, 60, 40))
    pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, best.id, player) end)
end)

-- ════════════════════════════════════════════
-- INFO TAB (IMPROVED)
-- ════════════════════════════════════════════
local function createInfoBlock(text, parent, order)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -4, 0, 0)
    lbl.AutomaticSize = Enum.AutomaticSize.Y
    lbl.BackgroundColor3 = Color3.fromRGB(32, 32, 50)
    lbl.TextColor3 = Color3.fromRGB(200, 200, 255)
    lbl.TextSize = isMobile and 11 or 10
    lbl.Font = Enum.Font.Gotham
    lbl.TextWrapped = true
    lbl.RichText = true
    lbl.TextYAlignment = Enum.TextYAlignment.Top
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 3
    lbl.LayoutOrder = order or 0
    lbl.Text = text
    lbl.Parent = parent
    Instance.new("UICorner", lbl).CornerRadius = UDim.new(0, 10)
    local p = Instance.new("UIPadding", lbl)
    p.PaddingTop = UDim.new(0, 8); p.PaddingBottom = UDim.new(0, 8)
    p.PaddingLeft = UDim.new(0, 10); p.PaddingRight = UDim.new(0, 10)
    return lbl
end

createCategory("ℹ️ About", InfoContent, 1)
createInfoBlock(string.format(
    "<b>🔥 Obby Helper Pro v3.0</b>\n\n" ..
    "📱 Device: <font color='#64C8FF'>%s</font>\n" ..
    "👤 Player: <font color='#64FF96'>%s</font>\n" ..
    "🆔 PlaceId: <font color='#FFD700'>%d</font>\n" ..
    "🕐 Loaded: <font color='#CCCCFF'>%s</font>",
    isMobile and "Mobile" or "PC",
    player.Name,
    game.PlaceId,
    os.date("%H:%M:%S")
), InfoContent, 2)

createCategory("📋 Features v3.0", InfoContent, 3)
createInfoBlock(
    "<b>Main Tab:</b>\n" ..
    "• 👁️ Player ESP (Highlight + NameTag + HP)\n" ..
    "• 🧱 Obstacle Visualizer\n" ..
    "• ⚡ Speed Boost (16-200)\n" ..
    "• 🦘 Jump Power (50-350)\n" ..
    "• ∞ Infinite Jump\n" ..
    "• 👻 Noclip (FIXED)\n" ..
    "• 🛡️ Anti-Void (save last safe pos)\n" ..
    "• 🌟 Fullbright\n\n" ..
    "<b>Extra Tab (NEW!):</b>\n" ..
    "• 🤖 Anti-AFK\n" ..
    "• 🦘 Auto Jump\n" ..
    "• 👁️ Invisible (Local)\n" ..
    "• 📏 Big/Small Character\n\n" ..
    "<b>Players Tab:</b>\n" ..
    "• 📌 TP (with confirm dialog)\n" ..
    "• 👁️ Spectate • 🚶 Follow\n" ..
    "• 🔍 Search filter • Live HP\n\n" ..
    "<b>Server Tab:</b>\n" ..
    "• Sort by Players / ID\n" ..
    "• Per page 25/50/100\n" ..
    "• 🎲 Random Server\n" ..
    "• ⭐ Best Server (most players)\n" ..
    "• Retry on error",
    InfoContent, 4
)

createCategory("⚠️ Risk Guide", InfoContent, 5)
createInfoBlock(
    "<font color='#FF8080'><b>🔴 HIGH RISK:</b></font>\n" ..
    "• Teleport to Player\n" ..
    "• Speed > 100 (obvious)\n\n" ..
    "<font color='#FFCC66'><b>🟡 MEDIUM:</b></font>\n" ..
    "• Speed 16-100 • Jump Boost\n" ..
    "• Noclip • Follow\n\n" ..
    "<font color='#88FF88'><b>🟢 LOW RISK:</b></font>\n" ..
    "• Spectate • ESP • Fullbright\n" ..
    "• Anti-Void • Anti-AFK\n" ..
    "• Obstacle Visualizer",
    InfoContent, 6
)

-- ════════════════════════════════════════════
-- CLEANUP / CLOSE
-- ════════════════════════════════════════════
CloseBtn.MouseButton1Click:Connect(function()
    stopAllActions()

    for key, conn in pairs(Connections) do
        pcall(function()
            if typeof(conn) == "RBXScriptConnection" then conn:Disconnect() end
        end)
    end
    Connections = {}

    for plr in pairs(ESP) do cleanupPlayerESP(plr) end
    clearObstacles()

    if ToggleStates.Fullbright then
        pcall(function()
            Lighting.Ambient = oldLighting.Ambient
            Lighting.Brightness = oldLighting.Brightness
            Lighting.OutdoorAmbient = oldLighting.OutdoorAmbient
            Lighting.ClockTime = oldLighting.ClockTime
            Lighting.FogEnd = oldLighting.FogEnd
            if oldLighting.GlobalShadows ~= nil then
                Lighting.GlobalShadows = oldLighting.GlobalShadows
            end
            for _, v in ipairs(Lighting:GetChildren()) do
                if v:IsA("Atmosphere") or v:IsA("BloomEffect") or v:IsA("DepthOfFieldEffect") then
                    v.Enabled = true
                end
            end
        end)
    end

    pcall(function()
        if player.Character then
            local hum = player.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.WalkSpeed = 16
                hum.JumpPower = 50
                hum.UseJumpPower = false
            end
            for _, p in ipairs(player.Character:GetDescendants()) do
                if p:IsA("BasePart") then
                    p.CanCollide = true
                    p.LocalTransparencyModifier = 0
                end
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
    local hum = char:WaitForChild("Humanoid", 10)
    if not hum then return end
    task.wait(0.5)

    pcall(function()
        if ToggleStates.Speed then hum.WalkSpeed = Settings.SpeedValue end
        if ToggleStates.Jump then hum.UseJumpPower = true; hum.JumpPower = Settings.JumpValue end
    end)

    if PlayerAction.IsSpectating and PlayerAction.SpectateTarget
        and PlayerAction.SpectateTarget.Character then
        pcall(function()
            Camera.CameraSubject = PlayerAction.SpectateTarget.Character:FindFirstChildOfClass("Humanoid")
        end)
    end

    if ToggleStates.ESP then
        task.wait(0.5)
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= player and plr.Character then createPlayerESP(plr) end
        end
    end
end)

-- ESP untuk player baru
Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function()
        task.wait(1)
        if ToggleStates.ESP then createPlayerESP(plr) end
    end)
end)

-- ════════════════════════════════════════════
-- INIT
-- ════════════════════════════════════════════
switchTab("main")
displayServerPage()

task.delay(0.8, function()
    showNotif("🔥 Obby Helper Pro v3.0 Ready!", Color3.fromRGB(30, 40, 80))
end)

print("╔═══════════════════════════════════╗")
print("║  🔥 Obby Helper Pro v3.0          ║")
print("║  📱 " .. (isMobile and "Mobile" or "PC    ") .. "               ║")
print("║  👤 " .. player.Name)
print("║  ✅ All bugs fixed + new features  ║")
print("╚═══════════════════════════════════╝")
