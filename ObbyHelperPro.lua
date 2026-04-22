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

local ESP = {}
local Connections = {}
local ObstacleFolder = {}
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- ================== SETTINGS ==================
local Settings = {
    ObstacleTransparency = 0.7,
    ObstacleColor = Color3.fromRGB(255, 0, 0),
    SpeedValue = 32,
    JumpValue = 100
}

-- ================== SERVER HOP DATA ==================
local ServerHopData = {
    Servers = {},
    CurrentPage = 1,
    PerPage = 25,
    TotalPages = 1,
    IsLoading = false
}

-- ================== PLAYER ACTION DATA ==================
local PlayerAction = {
    SpectateTarget = nil,
    FollowTarget = nil,
    IsSpectating = false,
    IsFollowing = false,
    OriginalCameraSubject = nil,
    TPConfirmPending = false
}

-- ================== SCREEN GUI ==================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ObbyHelperGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = player:WaitForChild("PlayerGui")

-- ================== MINIMIZE BUTTON (FLOATING) ==================
local MinimizedBox = Instance.new("TextButton")
MinimizedBox.Size = isMobile and UDim2.new(0, 70, 0, 70) or UDim2.new(0, 60, 0, 60)
MinimizedBox.Position = isMobile and UDim2.new(0.85, 0, 0.1, 0) or UDim2.new(0.02, 0, 0.2, 0)
MinimizedBox.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
MinimizedBox.Text = "🔥"
MinimizedBox.TextColor3 = Color3.new(1, 1, 1)
MinimizedBox.TextSize = isMobile and 35 or 30
MinimizedBox.Font = Enum.Font.GothamBold
MinimizedBox.Visible = false
MinimizedBox.Active = true
MinimizedBox.Draggable = true
MinimizedBox.ZIndex = 100
MinimizedBox.Parent = ScreenGui

Instance.new("UICorner", MinimizedBox).CornerRadius = UDim.new(0.3, 0)
local MinBoxStroke = Instance.new("UIStroke", MinimizedBox)
MinBoxStroke.Color = Color3.fromRGB(80, 80, 255)
MinBoxStroke.Thickness = 3

-- ================== MAIN FRAME ==================
local Main = Instance.new("Frame")
if isMobile then
    Main.Size = UDim2.new(0.92, 0, 0.78, 0)
    Main.Position = UDim2.new(0.04, 0, 0.11, 0)
else
    Main.Size = UDim2.new(0, 420, 0, 660)
    Main.Position = UDim2.new(0.02, 0, 0.03, 0)
end
Main.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = not isMobile
Main.ClipsDescendants = true
Main.ZIndex = 1
Main.Parent = ScreenGui

Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 15)
local MainStroke = Instance.new("UIStroke", Main)
MainStroke.Color = Color3.fromRGB(80, 80, 255)
MainStroke.Thickness = 2

-- ================== TITLE BAR ==================
local TitleBar = Instance.new("Frame")
TitleBar.Size = isMobile and UDim2.new(1, 0, 0, 65) or UDim2.new(1, 0, 0, 55)
TitleBar.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
TitleBar.BorderSizePixel = 0
TitleBar.ZIndex = 2
TitleBar.Parent = Main

Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 15)

local TitleBarBottom = Instance.new("Frame")
TitleBarBottom.Size = UDim2.new(1, 0, 0.4, 0)
TitleBarBottom.Position = UDim2.new(0, 0, 0.6, 0)
TitleBarBottom.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
TitleBarBottom.BorderSizePixel = 0
TitleBarBottom.ZIndex = 2
TitleBarBottom.Parent = TitleBar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(0.5, 0, 1, 0)
Title.Position = UDim2.new(0.04, 0, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "🔥 Obby Helper"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = isMobile and 20 or 18
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.TextScaled = isMobile
Title.ZIndex = 3
Title.Parent = TitleBar

-- ================== MINIMIZE & CLOSE ==================
local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Size = isMobile and UDim2.new(0, 42, 0, 42) or UDim2.new(0, 34, 0, 34)
MinimizeBtn.Position = isMobile and UDim2.new(1, -95, 0.5, -21) or UDim2.new(1, -80, 0.5, -17)
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(255, 180, 0)
MinimizeBtn.Text = "─"
MinimizeBtn.TextColor3 = Color3.new(1, 1, 1)
MinimizeBtn.TextSize = isMobile and 22 or 18
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.ZIndex = 3
MinimizeBtn.AutoButtonColor = false
MinimizeBtn.Parent = TitleBar
Instance.new("UICorner", MinimizeBtn).CornerRadius = UDim.new(0.5, 0)

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = isMobile and UDim2.new(0, 42, 0, 42) or UDim2.new(0, 34, 0, 34)
CloseBtn.Position = isMobile and UDim2.new(1, -48, 0.5, -21) or UDim2.new(1, -42, 0.5, -17)
CloseBtn.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.new(1, 1, 1)
CloseBtn.TextSize = isMobile and 20 or 16
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.ZIndex = 3
CloseBtn.AutoButtonColor = false
CloseBtn.Parent = TitleBar
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0.5, 0)

local isMinimized = false

MinimizeBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    Main.Visible = not isMinimized
    MinimizedBox.Visible = isMinimized
end)

MinimizedBox.MouseButton1Click:Connect(function()
    isMinimized = false
    Main.Visible = true
    MinimizedBox.Visible = false
end)

-- ================== TAB SYSTEM (4 TABS) ==================
local TabBar = Instance.new("Frame")
TabBar.Size = isMobile and UDim2.new(1, 0, 0, 46) or UDim2.new(1, 0, 0, 40)
TabBar.Position = isMobile and UDim2.new(0, 0, 0, 65) or UDim2.new(0, 0, 0, 55)
TabBar.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
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
    btn.Size = UDim2.new(0.25, 0, 1, 0)
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
    btn.Text = icon .. (isMobile and "" or (" " .. name))
    btn.TextColor3 = Color3.fromRGB(130, 130, 160)
    btn.TextSize = isMobile and 16 or 12
    btn.Font = Enum.Font.GothamBold
    btn.ZIndex = 3
    btn.AutoButtonColor = false
    btn.LayoutOrder = layoutOrder
    btn.Parent = TabBar

    local indicator = Instance.new("Frame")
    indicator.Size = UDim2.new(0.5, 0, 0, 3)
    indicator.Position = UDim2.new(0.25, 0, 1, -3)
    indicator.BackgroundColor3 = Color3.fromRGB(80, 100, 255)
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
        data.Button.TextColor3 = active and Color3.new(1, 1, 1) or Color3.fromRGB(130, 130, 160)
        data.Button.BackgroundColor3 = active and Color3.fromRGB(40, 40, 58) or Color3.fromRGB(30, 30, 42)
        data.Indicator.Visible = active
    end
    for name, frame in pairs(TabFrames) do
        frame.Visible = name == tabName
    end
end

local MainTabBtn = createTab("Main", "⚙️", 1)
local PlayersTabBtn = createTab("Players", "👥", 2)
local ServerTabBtn = createTab("Servers", "🌐", 3)
local InfoTabBtn = createTab("Info", "ℹ️", 4)

MainTabBtn.MouseButton1Click:Connect(function() switchTab("main") end)
PlayersTabBtn.MouseButton1Click:Connect(function() switchTab("players") end)
ServerTabBtn.MouseButton1Click:Connect(function() switchTab("servers") end)
InfoTabBtn.MouseButton1Click:Connect(function() switchTab("info") end)

-- ================== CONTENT FRAMES ==================
local contentY = isMobile and 111 or 95

local function createContentFrame(name)
    local frame = Instance.new("ScrollingFrame")
    frame.Size = UDim2.new(1, -10, 1, -(contentY + 5))
    frame.Position = UDim2.new(0, 5, 0, contentY)
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.ScrollBarThickness = isMobile and 6 or 5
    frame.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 255)
    frame.CanvasSize = UDim2.new(0, 0, 0, 0)
    frame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    frame.ZIndex = 2
    frame.Visible = false
    frame.Parent = Main

    local pad = Instance.new("UIPadding", frame)
    pad.PaddingTop = UDim.new(0, 5)
    pad.PaddingBottom = UDim.new(0, 10)
    pad.PaddingLeft = UDim.new(0, 3)
    pad.PaddingRight = UDim.new(0, 3)

    local layout = Instance.new("UIListLayout", frame)
    layout.Padding = UDim.new(0, isMobile and 7 or 6)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center

    TabFrames[name] = frame
    return frame
end

local MainContent = createContentFrame("main")
local PlayersContent = createContentFrame("players")
local ServerContent = createContentFrame("servers")
local InfoContent = createContentFrame("info")

-- ================== HELPER FUNCTIONS ==================
local function createCategory(text, parent, order)
    local label = Instance.new("TextLabel")
    label.Size = isMobile and UDim2.new(1, -4, 0, 30) or UDim2.new(1, -4, 0, 26)
    label.BackgroundColor3 = Color3.fromRGB(30, 30, 48)
    label.Text = "  " .. text
    label.TextColor3 = Color3.fromRGB(140, 150, 255)
    label.TextSize = isMobile and 14 or 12
    label.Font = Enum.Font.GothamBold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 3
    label.LayoutOrder = order or 0
    label.Parent = parent
    Instance.new("UICorner", label).CornerRadius = UDim.new(0, 8)
    return label
end

local function createButton(text, parent, callback, order)
    local button = Instance.new("TextButton")
    button.Size = isMobile and UDim2.new(1, -4, 0, 52) or UDim2.new(1, -4, 0, 44)
    button.BackgroundColor3 = Color3.fromRGB(45, 45, 62)
    button.Text = text
    button.TextColor3 = Color3.new(1, 1, 1)
    button.TextSize = isMobile and 15 or 13
    button.Font = Enum.Font.Gotham
    button.ZIndex = 3
    button.AutoButtonColor = false
    button.LayoutOrder = order or 0
    button.Parent = parent

    Instance.new("UICorner", button).CornerRadius = UDim.new(0, 10)
    local stroke = Instance.new("UIStroke", button)
    stroke.Color = Color3.fromRGB(55, 55, 80)
    stroke.Thickness = 1

    button.MouseEnter:Connect(function()
        if button:GetAttribute("active") then return end
        TweenService:Create(button, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(58, 58, 80)}):Play()
    end)
    button.MouseLeave:Connect(function()
        if button:GetAttribute("active") then return end
        TweenService:Create(button, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(45, 45, 62)}):Play()
    end)

    if callback then button.MouseButton1Click:Connect(callback) end
    return button
end

local function setToggleVisual(btn, active)
    btn:SetAttribute("active", active)
    btn.BackgroundColor3 = active and Color3.fromRGB(35, 115, 35) or Color3.fromRGB(45, 45, 62)
end

local function createWarningBox(text, parent, order)
    local box = Instance.new("Frame")
    box.Size = UDim2.new(1, -4, 0, 0)
    box.AutomaticSize = Enum.AutomaticSize.Y
    box.BackgroundColor3 = Color3.fromRGB(80, 30, 30)
    box.ZIndex = 3
    box.LayoutOrder = order or 0
    box.Parent = parent

    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 10)

    local wStroke = Instance.new("UIStroke", box)
    wStroke.Color = Color3.fromRGB(255, 80, 80)
    wStroke.Thickness = 2

    local wLabel = Instance.new("TextLabel")
    wLabel.Size = UDim2.new(1, 0, 0, 0)
    wLabel.AutomaticSize = Enum.AutomaticSize.Y
    wLabel.BackgroundTransparency = 1
    wLabel.Text = text
    wLabel.TextColor3 = Color3.fromRGB(255, 200, 200)
    wLabel.TextSize = isMobile and 13 or 11
    wLabel.Font = Enum.Font.Gotham
    wLabel.TextWrapped = true
    wLabel.RichText = true
    wLabel.TextXAlignment = Enum.TextXAlignment.Left
    wLabel.ZIndex = 4
    wLabel.Parent = box

    local wPad = Instance.new("UIPadding", wLabel)
    wPad.PaddingTop = UDim.new(0, 10)
    wPad.PaddingBottom = UDim.new(0, 10)
    wPad.PaddingLeft = UDim.new(0, 12)
    wPad.PaddingRight = UDim.new(0, 12)

    return box
end

-- ================== SLIDER ==================
local function createSlider(labelText, parent, minVal, maxVal, default, suffix, callback, order)
    local container = Instance.new("Frame")
    container.Size = isMobile and UDim2.new(1, -4, 0, 78) or UDim2.new(1, -4, 0, 68)
    container.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    container.ZIndex = 3
    container.LayoutOrder = order or 0
    container.Parent = parent
    Instance.new("UICorner", container).CornerRadius = UDim.new(0, 10)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.62, 0, 0, 24)
    label.Position = UDim2.new(0, 10, 0, 5)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextSize = isMobile and 13 or 11
    label.Font = Enum.Font.GothamBold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 4
    label.Parent = container

    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(0.32, 0, 0, 24)
    valueLabel.Position = UDim2.new(0.66, 0, 0, 5)
    valueLabel.BackgroundTransparency = 1
    valueLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
    valueLabel.TextSize = isMobile and 13 or 11
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
    sliderBack.Size = UDim2.new(1, -20, 0, isMobile and 26 or 22)
    sliderBack.Position = UDim2.new(0, 10, 0, 35)
    sliderBack.BackgroundColor3 = Color3.fromRGB(28, 28, 42)
    sliderBack.ZIndex = 4
    sliderBack.Parent = container
    Instance.new("UICorner", sliderBack).CornerRadius = UDim.new(1, 0)

    local initFill = math.clamp((default - minVal) / (maxVal - minVal), 0, 1)

    local sliderFill = Instance.new("Frame")
    sliderFill.Size = UDim2.new(initFill, 0, 1, 0)
    sliderFill.BackgroundColor3 = Color3.fromRGB(70, 90, 255)
    sliderFill.ZIndex = 5
    sliderFill.Parent = sliderBack
    Instance.new("UICorner", sliderFill).CornerRadius = UDim.new(1, 0)

    local knobSize = isMobile and 20 or 16
    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, knobSize, 0, knobSize)
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Position = UDim2.new(initFill, 0, 0.5, 0)
    knob.BackgroundColor3 = Color3.fromRGB(220, 220, 255)
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

-- ================================================================
-- ==================== MAIN TAB ==================================
-- ================================================================
createCategory("📡 ESP & Vision", MainContent, 1)

local espEnabled = false
local PlayerESPToggle = createButton("❌ Player ESP: OFF", MainContent, nil, 2)

local function cleanupPlayerESP(plr)
    if ESP[plr] then
        pcall(function()
            if ESP[plr].Box then ESP[plr].Box:Destroy() end
            if ESP[plr].NameTag then ESP[plr].NameTag:Destroy() end
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

        local box = Instance.new("SelectionBox")
        box.Color3 = Color3.fromRGB(0, 255, 100)
        box.LineThickness = 0.05
        box.SurfaceTransparency = 0.7
        box.SurfaceColor3 = Color3.fromRGB(0, 255, 100)
        box.Adornee = char
        box.Parent = ScreenGui

        local nameTag = Instance.new("BillboardGui")
        nameTag.Size = UDim2.new(0, 200, 0, 55)
        nameTag.AlwaysOnTop = true
        nameTag.StudsOffset = Vector3.new(0, 3.5, 0)
        nameTag.Adornee = head
        nameTag.Parent = ScreenGui

        local bg = Instance.new("Frame")
        bg.Size = UDim2.new(1, 0, 1, 0)
        bg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        bg.BackgroundTransparency = 0.5
        bg.BorderSizePixel = 0
        bg.Parent = nameTag
        Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 6)

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, 0, 1, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
        nameLabel.TextStrokeTransparency = 0.5
        nameLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
        nameLabel.TextScaled = true
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.Text = plr.Name
        nameLabel.Parent = bg

        ESP[plr] = {Box = box, NameTag = nameTag, Label = nameLabel}
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

            local dist = 0
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                dist = math.floor((player.Character.HumanoidRootPart.Position - hrp.Position).Magnitude)
            end
            data.Label.Text = string.format("%s\n%d studs | %.0f HP", plr.Name, dist, hum.Health)
            if hum.Health <= 0 then cleanupPlayerESP(plr) end
        end)
    end
end

PlayerESPToggle.MouseButton1Click:Connect(function()
    espEnabled = not espEnabled
    PlayerESPToggle.Text = espEnabled and "✅ Player ESP: ON" or "❌ Player ESP: OFF"
    setToggleVisual(PlayerESPToggle, espEnabled)

    if espEnabled then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= player then createPlayerESP(plr) end
        end
        Connections.UpdateESP = RunService.Heartbeat:Connect(updateAllESP)
    else
        if Connections.UpdateESP then Connections.UpdateESP:Disconnect() Connections.UpdateESP = nil end
        for plr in pairs(ESP) do cleanupPlayerESP(plr) end
        ESP = {}
    end
end)

-- Obstacle Visualizer
local obstacleEnabled = false
local ObstacleToggle = createButton("❌ Obstacle Visualizer: OFF", MainContent, nil, 3)

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

ObstacleToggle.MouseButton1Click:Connect(function()
    obstacleEnabled = not obstacleEnabled
    ObstacleToggle.Text = obstacleEnabled and "✅ Obstacle Visualizer: ON" or "❌ Obstacle Visualizer: OFF"
    setToggleVisual(ObstacleToggle, obstacleEnabled)

    if obstacleEnabled then
        for _, part in ipairs(Workspace:GetDescendants()) do
            pcall(function()
                if part:IsA("BasePart") and part.CanCollide and part.Transparency >= 0.9 and not ObstacleFolder[part] then
                    local origT, origC, origM = part.Transparency, part.Color, part.Material
                    part.Transparency = Settings.ObstacleTransparency
                    part.Color = Settings.ObstacleColor
                    part.Material = Enum.Material.Neon

                    local hl = Instance.new("Highlight")
                    hl.FillColor = Settings.ObstacleColor
                    hl.OutlineColor = Color3.fromRGB(255, 255, 0)
                    hl.FillTransparency = Settings.ObstacleTransparency
                    hl.OutlineTransparency = 0.2
                    hl.Adornee = part
                    hl.Parent = part

                    ObstacleFolder[part] = {OriginalTransparency = origT, OriginalColor = origC, OriginalMaterial = origM, Highlight = hl}
                end
            end)
        end
    else
        clearObstacles()
    end
end)

createSlider("🎚️ Obstacle Transparency", MainContent, 0.1, 0.95, Settings.ObstacleTransparency, "%", function(v)
    Settings.ObstacleTransparency = v
    if obstacleEnabled then updateObstacleAppearance() end
end, 4)

-- Movement
createCategory("⚡ Movement", MainContent, 10)

local speedEnabled = false
local SpeedToggle = createButton("❌ Speed Boost: OFF", MainContent, nil, 11)

local function applySpeed()
    pcall(function()
        if player.Character then
            local hum = player.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = speedEnabled and Settings.SpeedValue or 16 end
        end
    end)
end

SpeedToggle.MouseButton1Click:Connect(function()
    speedEnabled = not speedEnabled
    SpeedToggle.Text = speedEnabled and "✅ Speed Boost: ON" or "❌ Speed Boost: OFF"
    setToggleVisual(SpeedToggle, speedEnabled)
    applySpeed()
end)

createSlider("🏃 Speed Value", MainContent, 16, 150, Settings.SpeedValue, "", function(v)
    Settings.SpeedValue = math.floor(v)
    if speedEnabled then applySpeed() end
end, 12)

local jumpEnabled = false
local JumpToggle = createButton("❌ Jump Power: OFF", MainContent, nil, 13)

local function applyJump()
    pcall(function()
        if player.Character then
            local hum = player.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.UseJumpPower = true hum.JumpPower = jumpEnabled and Settings.JumpValue or 50 end
        end
    end)
end

JumpToggle.MouseButton1Click:Connect(function()
    jumpEnabled = not jumpEnabled
    JumpToggle.Text = jumpEnabled and "✅ Jump Power: ON" or "❌ Jump Power: OFF"
    setToggleVisual(JumpToggle, jumpEnabled)
    applyJump()
end)

createSlider("🦘 Jump Value", MainContent, 50, 300, Settings.JumpValue, "", function(v)
    Settings.JumpValue = math.floor(v)
    if jumpEnabled then applyJump() end
end, 14)

local infJumpEnabled = false
local InfJumpToggle = createButton("❌ Infinite Jump: OFF", MainContent, nil, 15)
InfJumpToggle.MouseButton1Click:Connect(function()
    infJumpEnabled = not infJumpEnabled
    InfJumpToggle.Text = infJumpEnabled and "✅ Infinite Jump: ON" or "❌ Infinite Jump: OFF"
    setToggleVisual(InfJumpToggle, infJumpEnabled)
end)

Connections.InfJump = UserInputService.JumpRequest:Connect(function()
    if not infJumpEnabled then return end
    pcall(function()
        if player.Character then
            local hum = player.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum:GetState() ~= Enum.HumanoidStateType.Dead then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end)
end)

local noclipEnabled = false
local NoclipToggle = createButton("❌ Noclip: OFF", MainContent, nil, 16)
NoclipToggle.MouseButton1Click:Connect(function()
    noclipEnabled = not noclipEnabled
    NoclipToggle.Text = noclipEnabled and "✅ Noclip: ON" or "❌ Noclip: OFF"
    setToggleVisual(NoclipToggle, noclipEnabled)

    if noclipEnabled then
        Connections.Noclip = RunService.Stepped:Connect(function()
            pcall(function()
                if player.Character then
                    for _, p in ipairs(player.Character:GetDescendants()) do
                        if p:IsA("BasePart") then p.CanCollide = false end
                    end
                end
            end)
        end)
    else
        if Connections.Noclip then Connections.Noclip:Disconnect() Connections.Noclip = nil end
        pcall(function()
            if player.Character then
                for _, p in ipairs(player.Character:GetDescendants()) do
                    if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then p.CanCollide = true end
                end
            end
        end)
    end
end)

local antiVoidEnabled = false
local AntiVoidToggle = createButton("❌ Anti-Void: OFF", MainContent, nil, 17)
AntiVoidToggle.MouseButton1Click:Connect(function()
    antiVoidEnabled = not antiVoidEnabled
    AntiVoidToggle.Text = antiVoidEnabled and "✅ Anti-Void: ON" or "❌ Anti-Void: OFF"
    setToggleVisual(AntiVoidToggle, antiVoidEnabled)

    if antiVoidEnabled then
        Connections.AntiVoid = RunService.Heartbeat:Connect(function()
            pcall(function()
                if player.Character then
                    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                    if hrp and hrp.Position.Y < -100 then
                        hrp.CFrame = CFrame.new(hrp.Position.X, 50, hrp.Position.Z)
                    end
                end
            end)
        end)
    else
        if Connections.AntiVoid then Connections.AntiVoid:Disconnect() Connections.AntiVoid = nil end
    end
end)

-- Visual
createCategory("👁️ Visual", MainContent, 20)

local fullbrightEnabled = false
local oldLighting = {}
local FullbrightToggle = createButton("❌ Fullbright: OFF", MainContent, nil, 21)
FullbrightToggle.MouseButton1Click:Connect(function()
    fullbrightEnabled = not fullbrightEnabled
    FullbrightToggle.Text = fullbrightEnabled and "✅ Fullbright: ON" or "❌ Fullbright: OFF"
    setToggleVisual(FullbrightToggle, fullbrightEnabled)

    if fullbrightEnabled then
        oldLighting.Ambient = Lighting.Ambient
        oldLighting.Brightness = Lighting.Brightness
        oldLighting.OutdoorAmbient = Lighting.OutdoorAmbient
        oldLighting.ClockTime = Lighting.ClockTime
        oldLighting.FogEnd = Lighting.FogEnd
        Lighting.Ambient = Color3.new(1, 1, 1)
        Lighting.Brightness = 2
        Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
        Lighting.ClockTime = 12
        Lighting.FogEnd = 100000
    else
        pcall(function()
            Lighting.Ambient = oldLighting.Ambient
            Lighting.Brightness = oldLighting.Brightness
            Lighting.OutdoorAmbient = oldLighting.OutdoorAmbient
            Lighting.ClockTime = oldLighting.ClockTime
            Lighting.FogEnd = oldLighting.FogEnd
        end)
    end
end)

-- Utility
createCategory("🔧 Utility", MainContent, 30)
createButton("🔁 Reset Character", MainContent, function()
    pcall(function()
        if player.Character then
            local hum = player.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.Health = 0 end
        end
    end)
end, 31)

-- ================================================================
-- ==================== PLAYERS TAB ===============================
-- ================================================================

-- Warning Banner
createWarningBox(
    "⚠️ <b>PERINGATAN PENTING!</b>\n\n" ..
    "🚨 <b>Teleport ke Player</b> sangat berisiko!\n" ..
    "• Bisa terdeteksi anti-cheat dan kena <b>BAN</b>\n" ..
    "• Bisa stuck di dalam wall atau jatuh ke void\n" ..
    "• Posisi bisa ter-reset ke checkpoint awal\n" ..
    "• Beberapa game memiliki <b>teleport detection</b>\n\n" ..
    "⚡ <b>Spectate</b> dan <b>Follow</b> lebih aman karena\nhanya mengubah kamera, bukan posisi karakter.\n\n" ..
    "🔴 <b>Gunakan dengan risiko sendiri!</b>",
    PlayersContent, 0
)

-- Status Bar
local PlayerStatusBar = Instance.new("Frame")
PlayerStatusBar.Size = UDim2.new(1, -4, 0, 0)
PlayerStatusBar.AutomaticSize = Enum.AutomaticSize.Y
PlayerStatusBar.BackgroundColor3 = Color3.fromRGB(30, 45, 65)
PlayerStatusBar.ZIndex = 3
PlayerStatusBar.LayoutOrder = 1
PlayerStatusBar.Visible = false
PlayerStatusBar.Parent = PlayersContent
Instance.new("UICorner", PlayerStatusBar).CornerRadius = UDim.new(0, 8)

local StatusStroke = Instance.new("UIStroke", PlayerStatusBar)
StatusStroke.Color = Color3.fromRGB(80, 160, 255)
StatusStroke.Thickness = 1

local PlayerStatusLabel = Instance.new("TextLabel")
PlayerStatusLabel.Size = UDim2.new(1, 0, 0, 0)
PlayerStatusLabel.AutomaticSize = Enum.AutomaticSize.Y
PlayerStatusLabel.BackgroundTransparency = 1
PlayerStatusLabel.Text = ""
PlayerStatusLabel.TextColor3 = Color3.fromRGB(140, 220, 255)
PlayerStatusLabel.TextSize = isMobile and 13 or 11
PlayerStatusLabel.Font = Enum.Font.GothamBold
PlayerStatusLabel.TextWrapped = true
PlayerStatusLabel.RichText = true
PlayerStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
PlayerStatusLabel.ZIndex = 4
PlayerStatusLabel.Parent = PlayerStatusBar

local statusPad = Instance.new("UIPadding", PlayerStatusLabel)
statusPad.PaddingTop = UDim.new(0, 8)
statusPad.PaddingBottom = UDim.new(0, 8)
statusPad.PaddingLeft = UDim.new(0, 10)
statusPad.PaddingRight = UDim.new(0, 10)

local function updateStatusBar(text, color)
    if text == "" then
        PlayerStatusBar.Visible = false
    else
        PlayerStatusBar.Visible = true
        PlayerStatusLabel.Text = text
        if color then
            PlayerStatusBar.BackgroundColor3 = color
        end
    end
end

-- Stop All Actions Button
local StopAllBtn = createButton("🛑 Stop All Actions", PlayersContent, nil, 2)
StopAllBtn.BackgroundColor3 = Color3.fromRGB(120, 30, 30)
StopAllBtn:SetAttribute("stopbtn", true)

-- Search Box
local SearchFrame = Instance.new("Frame")
SearchFrame.Size = UDim2.new(1, -4, 0, isMobile and 46 or 40)
SearchFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
SearchFrame.ZIndex = 3
SearchFrame.LayoutOrder = 3
SearchFrame.Parent = PlayersContent
Instance.new("UICorner", SearchFrame).CornerRadius = UDim.new(0, 10)

local SearchIcon = Instance.new("TextLabel")
SearchIcon.Size = UDim2.new(0, 35, 1, 0)
SearchIcon.Position = UDim2.new(0, 5, 0, 0)
SearchIcon.BackgroundTransparency = 1
SearchIcon.Text = "🔍"
SearchIcon.TextSize = isMobile and 18 or 16
SearchIcon.ZIndex = 4
SearchIcon.Parent = SearchFrame

local SearchBox = Instance.new("TextBox")
SearchBox.Size = UDim2.new(1, -45, 1, -8)
SearchBox.Position = UDim2.new(0, 38, 0, 4)
SearchBox.BackgroundTransparency = 1
SearchBox.PlaceholderText = "Search player name..."
SearchBox.PlaceholderColor3 = Color3.fromRGB(120, 120, 150)
SearchBox.Text = ""
SearchBox.TextColor3 = Color3.new(1, 1, 1)
SearchBox.TextSize = isMobile and 15 or 13
SearchBox.Font = Enum.Font.Gotham
SearchBox.TextXAlignment = Enum.TextXAlignment.Left
SearchBox.ClearTextOnFocus = false
SearchBox.ZIndex = 4
SearchBox.Parent = SearchFrame

-- Player Count
local PlayerCountLabel = Instance.new("TextLabel")
PlayerCountLabel.Size = UDim2.new(1, -4, 0, 24)
PlayerCountLabel.BackgroundTransparency = 1
PlayerCountLabel.Text = "👥 Players: 0"
PlayerCountLabel.TextColor3 = Color3.fromRGB(160, 160, 200)
PlayerCountLabel.TextSize = isMobile and 12 or 11
PlayerCountLabel.Font = Enum.Font.Gotham
PlayerCountLabel.ZIndex = 3
PlayerCountLabel.LayoutOrder = 4
PlayerCountLabel.Parent = PlayersContent

-- Player List Container
local PlayerListFrame = Instance.new("Frame")
PlayerListFrame.Size = UDim2.new(1, -4, 0, 20)
PlayerListFrame.BackgroundTransparency = 1
PlayerListFrame.AutomaticSize = Enum.AutomaticSize.Y
PlayerListFrame.ZIndex = 3
PlayerListFrame.LayoutOrder = 5
PlayerListFrame.Parent = PlayersContent

local PlayerListLayout = Instance.new("UIListLayout", PlayerListFrame)
PlayerListLayout.Padding = UDim.new(0, 5)
PlayerListLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- ================== TP CONFIRM DIALOG ==================
local ConfirmOverlay = Instance.new("Frame")
ConfirmOverlay.Size = UDim2.new(1, 0, 1, 0)
ConfirmOverlay.BackgroundColor3 = Color3.new(0, 0, 0)
ConfirmOverlay.BackgroundTransparency = 0.4
ConfirmOverlay.ZIndex = 50
ConfirmOverlay.Visible = false
ConfirmOverlay.Parent = ScreenGui

local ConfirmBox = Instance.new("Frame")
ConfirmBox.Size = isMobile and UDim2.new(0.85, 0, 0, 280) or UDim2.new(0, 360, 0, 260)
ConfirmBox.AnchorPoint = Vector2.new(0.5, 0.5)
ConfirmBox.Position = UDim2.new(0.5, 0, 0.5, 0)
ConfirmBox.BackgroundColor3 = Color3.fromRGB(35, 25, 30)
ConfirmBox.ZIndex = 51
ConfirmBox.Parent = ConfirmOverlay
Instance.new("UICorner", ConfirmBox).CornerRadius = UDim.new(0, 15)

local confirmStroke = Instance.new("UIStroke", ConfirmBox)
confirmStroke.Color = Color3.fromRGB(255, 80, 80)
confirmStroke.Thickness = 3

local ConfirmTitle = Instance.new("TextLabel")
ConfirmTitle.Size = UDim2.new(1, 0, 0, 45)
ConfirmTitle.BackgroundTransparency = 1
ConfirmTitle.Text = "⚠️ TELEPORT WARNING"
ConfirmTitle.TextColor3 = Color3.fromRGB(255, 100, 100)
ConfirmTitle.TextSize = isMobile and 20 or 18
ConfirmTitle.Font = Enum.Font.GothamBold
ConfirmTitle.ZIndex = 52
ConfirmTitle.Parent = ConfirmBox

local ConfirmMsg = Instance.new("TextLabel")
ConfirmMsg.Size = UDim2.new(1, -20, 0, 120)
ConfirmMsg.Position = UDim2.new(0, 10, 0, 45)
ConfirmMsg.BackgroundTransparency = 1
ConfirmMsg.Text = ""
ConfirmMsg.TextColor3 = Color3.fromRGB(255, 200, 200)
ConfirmMsg.TextSize = isMobile and 14 or 12
ConfirmMsg.Font = Enum.Font.Gotham
ConfirmMsg.TextWrapped = true
ConfirmMsg.RichText = true
ConfirmMsg.TextYAlignment = Enum.TextYAlignment.Top
ConfirmMsg.ZIndex = 52
ConfirmMsg.Parent = ConfirmBox

local ConfirmBtnRow = Instance.new("Frame")
ConfirmBtnRow.Size = UDim2.new(1, -20, 0, isMobile and 50 or 42)
ConfirmBtnRow.Position = UDim2.new(0, 10, 1, -(isMobile and 60 or 52))
ConfirmBtnRow.BackgroundTransparency = 1
ConfirmBtnRow.ZIndex = 52
ConfirmBtnRow.Parent = ConfirmBox

local ConfirmBtnLayout = Instance.new("UIListLayout", ConfirmBtnRow)
ConfirmBtnLayout.FillDirection = Enum.FillDirection.Horizontal
ConfirmBtnLayout.Padding = UDim.new(0, 10)
ConfirmBtnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

local CancelTPBtn = Instance.new("TextButton")
CancelTPBtn.Size = UDim2.new(0.45, 0, 1, 0)
CancelTPBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
CancelTPBtn.Text = "❌ Cancel"
CancelTPBtn.TextColor3 = Color3.new(1, 1, 1)
CancelTPBtn.TextSize = isMobile and 16 or 14
CancelTPBtn.Font = Enum.Font.GothamBold
CancelTPBtn.ZIndex = 53
CancelTPBtn.AutoButtonColor = false
CancelTPBtn.LayoutOrder = 1
CancelTPBtn.Parent = ConfirmBtnRow
Instance.new("UICorner", CancelTPBtn).CornerRadius = UDim.new(0, 10)

local ConfirmTPBtn = Instance.new("TextButton")
ConfirmTPBtn.Size = UDim2.new(0.45, 0, 1, 0)
ConfirmTPBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
ConfirmTPBtn.Text = "⚡ TELEPORT"
ConfirmTPBtn.TextColor3 = Color3.new(1, 1, 1)
ConfirmTPBtn.TextSize = isMobile and 16 or 14
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
                local targetCF = pendingTPTarget.Character.HumanoidRootPart.CFrame
                player.Character.HumanoidRootPart.CFrame = targetCF * CFrame.new(0, 0, 5)
                updateStatusBar(
                    string.format("📌 Teleported to <b>%s</b>!", pendingTPTarget.Name),
                    Color3.fromRGB(30, 60, 45)
                )
            end
        end)
    else
        updateStatusBar("❌ Player not found or has no character!", Color3.fromRGB(60, 30, 30))
    end
    pendingTPTarget = nil
end)

-- ================== PLAYER ACTION FUNCTIONS ==================
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

        updateStatusBar(
            string.format("👁️ Spectating: <b>%s</b>\n💡 Kamera mengikuti player. Karakter kamu tetap diam.", targetPlr.Name),
            Color3.fromRGB(30, 45, 65)
        )

        -- Monitor jika target leave/die
        local checkConn
        checkConn = RunService.Heartbeat:Connect(function()
            if not PlayerAction.IsSpectating or PlayerAction.SpectateTarget ~= targetPlr then
                checkConn:Disconnect()
                return
            end
            if not targetPlr or not targetPlr.Parent or not targetPlr.Character 
                or not targetPlr.Character:FindFirstChildOfClass("Humanoid") then
                stopSpectate()
                updateStatusBar("⚠️ Spectate ended - player left or died", Color3.fromRGB(60, 50, 30))
                checkConn:Disconnect()
            end
        end)
        table.insert(Connections, checkConn)
    else
        updateStatusBar("❌ Cannot spectate - player has no character!", Color3.fromRGB(60, 30, 30))
    end
end

local function startFollow(targetPlr)
    if targetPlr == player then return end
    stopAllActions()

    if targetPlr.Character and targetPlr.Character:FindFirstChild("HumanoidRootPart") then
        PlayerAction.IsFollowing = true
        PlayerAction.FollowTarget = targetPlr

        updateStatusBar(
            string.format("🚶 Following: <b>%s</b>\n💡 Karakter kamu berjalan menuju player secara otomatis.", targetPlr.Name),
            Color3.fromRGB(30, 50, 40)
        )

        Connections.Follow = RunService.Heartbeat:Connect(function()
            pcall(function()
                if not PlayerAction.IsFollowing or PlayerAction.FollowTarget ~= targetPlr then
                    return
                end

                if not targetPlr or not targetPlr.Parent or not targetPlr.Character 
                    or not targetPlr.Character:FindFirstChild("HumanoidRootPart") then
                    stopFollow()
                    updateStatusBar("⚠️ Follow ended - player left or died", Color3.fromRGB(60, 50, 30))
                    return
                end

                if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") 
                    or not player.Character:FindFirstChildOfClass("Humanoid") then
                    return
                end

                local myHRP = player.Character.HumanoidRootPart
                local targetHRP = targetPlr.Character.HumanoidRootPart
                local hum = player.Character:FindFirstChildOfClass("Humanoid")
                local distance = (myHRP.Position - targetHRP.Position).Magnitude

                if distance > 5 then
                    hum:MoveTo(targetHRP.Position)
                else
                    hum:MoveTo(myHRP.Position)
                end
            end)
        end)
    else
        updateStatusBar("❌ Cannot follow - player has no character!", Color3.fromRGB(60, 30, 30))
    end
end

local function requestTP(targetPlr)
    if targetPlr == player then return end
    if PlayerAction.TPConfirmPending then return end

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
        "Kamu akan teleport ke <b>%s</b>\n" ..
        "📏 Jarak: <b>%s studs</b>\n\n" ..
        "🚨 <b>Risiko:</b>\n" ..
        "• Anti-cheat bisa mendeteksi teleport\n" ..
        "• Kamu bisa kena kick atau ban\n" ..
        "• Posisi bisa stuck di dalam objek\n\n" ..
        "Yakin ingin melanjutkan?",
        targetPlr.Name, dist
    )

    ConfirmOverlay.Visible = true
end

StopAllBtn.MouseButton1Click:Connect(function()
    stopAllActions()
    updateStatusBar("🛑 All actions stopped", Color3.fromRGB(50, 40, 40))
    task.delay(2, function()
        if PlayerStatusLabel.Text == "🛑 All actions stopped" then
            updateStatusBar("")
        end
    end)
end)

-- ================== CREATE PLAYER ENTRY ==================
local function clearPlayerList()
    for _, child in ipairs(PlayerListFrame:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
end

local function createPlayerEntry(targetPlr, index)
    if targetPlr == player then return end

    local entry = Instance.new("Frame")
    entry.Size = UDim2.new(1, 0, 0, isMobile and 90 or 78)
    entry.BackgroundColor3 = Color3.fromRGB(38, 38, 55)
    entry.ZIndex = 4
    entry.LayoutOrder = index
    entry.Parent = PlayerListFrame
    Instance.new("UICorner", entry).CornerRadius = UDim.new(0, 10)

    local eStroke = Instance.new("UIStroke", entry)
    eStroke.Color = Color3.fromRGB(50, 50, 72)
    eStroke.Thickness = 1

    -- Avatar placeholder
    local avatarFrame = Instance.new("Frame")
    avatarFrame.Size = UDim2.new(0, isMobile and 44 or 38, 0, isMobile and 44 or 38)
    avatarFrame.Position = UDim2.new(0, 8, 0, 8)
    avatarFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 90)
    avatarFrame.ZIndex = 5
    avatarFrame.Parent = entry
    Instance.new("UICorner", avatarFrame).CornerRadius = UDim.new(0.5, 0)

    local avatarText = Instance.new("TextLabel")
    avatarText.Size = UDim2.new(1, 0, 1, 0)
    avatarText.BackgroundTransparency = 1
    avatarText.Text = string.sub(targetPlr.Name, 1, 2):upper()
    avatarText.TextColor3 = Color3.new(1, 1, 1)
    avatarText.TextSize = isMobile and 16 or 14
    avatarText.Font = Enum.Font.GothamBold
    avatarText.ZIndex = 6
    avatarText.Parent = avatarFrame

    -- Player name
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -(isMobile and 60 or 52), 0, 22)
    nameLabel.Position = UDim2.new(0, isMobile and 58 or 50, 0, 6)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = targetPlr.Name
    nameLabel.TextColor3 = Color3.new(1, 1, 1)
    nameLabel.TextSize = isMobile and 14 or 12
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    nameLabel.ZIndex = 5
    nameLabel.Parent = entry

    -- Display name
    local displayLabel = Instance.new("TextLabel")
    displayLabel.Size = UDim2.new(1, -(isMobile and 60 or 52), 0, 18)
    displayLabel.Position = UDim2.new(0, isMobile and 58 or 50, 0, 26)
    displayLabel.BackgroundTransparency = 1
    displayLabel.TextColor3 = Color3.fromRGB(140, 140, 180)
    displayLabel.TextSize = isMobile and 11 or 10
    displayLabel.Font = Enum.Font.Gotham
    displayLabel.TextXAlignment = Enum.TextXAlignment.Left
    displayLabel.ZIndex = 5
    displayLabel.Parent = entry

    local displayName = targetPlr.DisplayName ~= targetPlr.Name 
        and ("@" .. targetPlr.DisplayName) or ""
    displayLabel.Text = displayName

    -- Action buttons row
    local btnRow = Instance.new("Frame")
    btnRow.Size = UDim2.new(1, -12, 0, isMobile and 32 or 28)
    btnRow.Position = UDim2.new(0, 6, 1, -(isMobile and 38 or 34))
    btnRow.BackgroundTransparency = 1
    btnRow.ZIndex = 5
    btnRow.Parent = entry

    local btnLayout = Instance.new("UIListLayout", btnRow)
    btnLayout.FillDirection = Enum.FillDirection.Horizontal
    btnLayout.Padding = UDim.new(0, 5)
    btnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left

    local function createActionBtn(text, color, order2)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, isMobile and 90 or 80, 1, 0)
        btn.BackgroundColor3 = color
        btn.Text = text
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.TextSize = isMobile and 12 or 10
        btn.Font = Enum.Font.GothamBold
        btn.ZIndex = 6
        btn.AutoButtonColor = false
        btn.LayoutOrder = order2
        btn.Parent = btnRow
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
        return btn
    end

    -- TP Button (RED - dangerous)
    local tpBtn = createActionBtn("📌 TP", Color3.fromRGB(150, 40, 40), 1)
    tpBtn.MouseButton1Click:Connect(function()
        requestTP(targetPlr)
    end)

    -- Spectate Button (BLUE - safe)
    local specBtn = createActionBtn("👁️ Spectate", Color3.fromRGB(40, 70, 140), 2)
    specBtn.MouseButton1Click:Connect(function()
        startSpectate(targetPlr)
    end)

    -- Follow Button (GREEN - moderate)
    local followBtn = createActionBtn("🚶 Follow", Color3.fromRGB(40, 100, 50), 3)
    followBtn.MouseButton1Click:Connect(function()
        startFollow(targetPlr)
    end)

    return entry
end

local function refreshPlayerList(filter)
    clearPlayerList()
    filter = filter or ""
    filter = filter:lower()

    local plrs = Players:GetPlayers()
    local count = 0

    for i, plr in ipairs(plrs) do
        if plr ~= player then
            local nameMatch = filter == "" 
                or plr.Name:lower():find(filter) 
                or plr.DisplayName:lower():find(filter)
            if nameMatch then
                createPlayerEntry(plr, i)
                count += 1
            end
        end
    end

    PlayerCountLabel.Text = string.format(
        "👥 Players: %d/%d (you excluded)", 
        count, #plrs - 1
    )
end

-- Search handler
SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
    refreshPlayerList(SearchBox.Text)
end)

-- Auto refresh saat tab switch
local function onPlayersTabOpen()
    refreshPlayerList(SearchBox.Text)
end

PlayersTabBtn.MouseButton1Click:Connect(function()
    switchTab("players")
    onPlayersTabOpen()
end)

-- Auto refresh saat player join/leave
Players.PlayerAdded:Connect(function()
    task.wait(0.5)
    if currentTab == "players" then
        refreshPlayerList(SearchBox.Text)
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
    if currentTab == "players" then
        refreshPlayerList(SearchBox.Text)
    end
end)

-- ================================================================
-- ==================== SERVER TAB ================================
-- ================================================================

local ServerStatus = Instance.new("TextLabel")
ServerStatus.Size = UDim2.new(1, -4, 0, 28)
ServerStatus.BackgroundColor3 = Color3.fromRGB(30, 30, 48)
ServerStatus.Text = "  🌐 Tap Refresh to load servers"
ServerStatus.TextColor3 = Color3.fromRGB(140, 200, 255)
ServerStatus.TextSize = isMobile and 13 or 11
ServerStatus.Font = Enum.Font.GothamBold
ServerStatus.TextXAlignment = Enum.TextXAlignment.Left
ServerStatus.ZIndex = 3
ServerStatus.LayoutOrder = 0
ServerStatus.Parent = ServerContent
Instance.new("UICorner", ServerStatus).CornerRadius = UDim.new(0, 8)

-- Per page
local PerPageFrame = Instance.new("Frame")
PerPageFrame.Size = UDim2.new(1, -4, 0, 40)
PerPageFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
PerPageFrame.ZIndex = 3
PerPageFrame.LayoutOrder = 1
PerPageFrame.Parent = ServerContent
Instance.new("UICorner", PerPageFrame).CornerRadius = UDim.new(0, 10)

local PerPageLabel = Instance.new("TextLabel")
PerPageLabel.Size = UDim2.new(0.4, 0, 1, 0)
PerPageLabel.Position = UDim2.new(0, 10, 0, 0)
PerPageLabel.BackgroundTransparency = 1
PerPageLabel.Text = "Per Page:"
PerPageLabel.TextColor3 = Color3.new(1, 1, 1)
PerPageLabel.TextSize = isMobile and 13 or 11
PerPageLabel.Font = Enum.Font.GothamBold
PerPageLabel.TextXAlignment = Enum.TextXAlignment.Left
PerPageLabel.ZIndex = 4
PerPageLabel.Parent = PerPageFrame

local function createPerPageBtn(text, value, posX)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, isMobile and 55 or 50, 0, isMobile and 28 or 26)
    btn.Position = UDim2.new(0, posX, 0.5, -(isMobile and 14 or 13))
    btn.BackgroundColor3 = (ServerHopData.PerPage == value) and Color3.fromRGB(70, 90, 255) or Color3.fromRGB(50, 50, 70)
    btn.Text = text
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.TextSize = isMobile and 13 or 11
    btn.Font = Enum.Font.GothamBold
    btn.ZIndex = 5
    btn.AutoButtonColor = false
    btn.Parent = PerPageFrame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    return btn
end

local perPage25 = createPerPageBtn("25", 25, isMobile and 160 or 150)
local perPage50 = createPerPageBtn("50", 50, isMobile and 222 or 208)

local function updatePerPageBtns()
    perPage25.BackgroundColor3 = (ServerHopData.PerPage == 25) and Color3.fromRGB(70, 90, 255) or Color3.fromRGB(50, 50, 70)
    perPage50.BackgroundColor3 = (ServerHopData.PerPage == 50) and Color3.fromRGB(70, 90, 255) or Color3.fromRGB(50, 50, 70)
end

-- Controls
local ControlRow = Instance.new("Frame")
ControlRow.Size = UDim2.new(1, -4, 0, isMobile and 44 or 38)
ControlRow.BackgroundTransparency = 1
ControlRow.ZIndex = 3
ControlRow.LayoutOrder = 2
ControlRow.Parent = ServerContent

local CLayout = Instance.new("UIListLayout", ControlRow)
CLayout.FillDirection = Enum.FillDirection.Horizontal
CLayout.Padding = UDim.new(0, 5)
CLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

local function createCtrlBtn(text, color, order)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.31, 0, 1, 0)
    btn.BackgroundColor3 = color
    btn.Text = text
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.TextSize = isMobile and 12 or 10
    btn.Font = Enum.Font.GothamBold
    btn.ZIndex = 4
    btn.AutoButtonColor = false
    btn.LayoutOrder = order
    btn.Parent = ControlRow
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    return btn
end

local PrevBtn = createCtrlBtn("◀ Prev", Color3.fromRGB(50, 50, 75), 1)
local RefreshBtn = createCtrlBtn("🔄 Refresh", Color3.fromRGB(50, 100, 50), 2)
local NextBtn = createCtrlBtn("Next ▶", Color3.fromRGB(50, 50, 75), 3)

local PageIndicator = Instance.new("TextLabel")
PageIndicator.Size = UDim2.new(1, -4, 0, 24)
PageIndicator.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
PageIndicator.Text = "Page 0 / 0 | 0 servers"
PageIndicator.TextColor3 = Color3.fromRGB(180, 180, 255)
PageIndicator.TextSize = isMobile and 12 or 10
PageIndicator.Font = Enum.Font.GothamBold
PageIndicator.ZIndex = 3
PageIndicator.LayoutOrder = 3
PageIndicator.Parent = ServerContent
Instance.new("UICorner", PageIndicator).CornerRadius = UDim.new(0, 6)

local RandomServerBtn = createButton("🎲 Join Random Server", ServerContent, nil, 4)

local ServerListFrame = Instance.new("Frame")
ServerListFrame.Size = UDim2.new(1, -4, 0, 20)
ServerListFrame.BackgroundTransparency = 1
ServerListFrame.AutomaticSize = Enum.AutomaticSize.Y
ServerListFrame.ZIndex = 3
ServerListFrame.LayoutOrder = 5
ServerListFrame.Parent = ServerContent

local SrvListLayout = Instance.new("UIListLayout", ServerListFrame)
SrvListLayout.Padding = UDim.new(0, 5)
SrvListLayout.SortOrder = Enum.SortOrder.LayoutOrder

local function clearServerList()
    for _, child in ipairs(ServerListFrame:GetChildren()) do
        if not child:IsA("UIListLayout") then child:Destroy() end
    end
end

local function createServerEntry(sData, index)
    local entry = Instance.new("Frame")
    entry.Size = UDim2.new(1, 0, 0, isMobile and 66 or 58)
    entry.BackgroundColor3 = Color3.fromRGB(38, 38, 55)
    entry.ZIndex = 4
    entry.LayoutOrder = index
    entry.Parent = ServerListFrame
    Instance.new("UICorner", entry).CornerRadius = UDim.new(0, 8)

    local sID = sData.id or "?"
    local playing = sData.playing or 0
    local maxP = sData.maxPlayers or 0
    local isCurrent = (sID == game.JobId)

    local infoL = Instance.new("TextLabel")
    infoL.Size = UDim2.new(0.62, 0, 0.48, 0)
    infoL.Position = UDim2.new(0, 8, 0, 4)
    infoL.BackgroundTransparency = 1
    infoL.Text = isCurrent and ("⭐ #" .. index .. " Current") or ("#" .. index .. " " .. string.sub(sID, 1, 10) .. "...")
    infoL.TextColor3 = isCurrent and Color3.fromRGB(255, 220, 80) or Color3.fromRGB(200, 200, 255)
    infoL.TextSize = isMobile and 11 or 10
    infoL.Font = Enum.Font.GothamBold
    infoL.TextXAlignment = Enum.TextXAlignment.Left
    infoL.TextTruncate = Enum.TextTruncate.AtEnd
    infoL.ZIndex = 5
    infoL.Parent = entry

    local fillRatio = maxP > 0 and (playing / maxP) or 0
    local fColor = fillRatio > 0.8 and "rgb(255,80,80)" or (fillRatio > 0.5 and "rgb(255,200,80)" or "rgb(80,255,120)")

    local detL = Instance.new("TextLabel")
    detL.Size = UDim2.new(0.62, 0, 0.45, 0)
    detL.Position = UDim2.new(0, 8, 0.5, 0)
    detL.BackgroundTransparency = 1
    detL.RichText = true
    detL.Text = string.format("👥 <font color='%s'>%d/%d</font>", fColor, playing, maxP)
    detL.TextColor3 = Color3.fromRGB(160, 160, 200)
    detL.TextSize = isMobile and 10 or 9
    detL.Font = Enum.Font.Gotham
    detL.TextXAlignment = Enum.TextXAlignment.Left
    detL.ZIndex = 5
    detL.Parent = entry

    local joinBtn = Instance.new("TextButton")
    joinBtn.Size = UDim2.new(0, isMobile and 65 or 58, 0, isMobile and 30 or 26)
    joinBtn.Position = UDim2.new(1, -(isMobile and 73 or 66), 0.5, -(isMobile and 15 or 13))
    joinBtn.BackgroundColor3 = isCurrent and Color3.fromRGB(55, 55, 75) or Color3.fromRGB(45, 110, 45)
    joinBtn.Text = isCurrent and "Here" or "Join"
    joinBtn.TextColor3 = Color3.new(1, 1, 1)
    joinBtn.TextSize = isMobile and 13 or 11
    joinBtn.Font = Enum.Font.GothamBold
    joinBtn.ZIndex = 6
    joinBtn.AutoButtonColor = not isCurrent
    joinBtn.Parent = entry
    Instance.new("UICorner", joinBtn).CornerRadius = UDim.new(0, 6)

    if not isCurrent then
        joinBtn.MouseButton1Click:Connect(function()
            joinBtn.Text = "..."
            joinBtn.BackgroundColor3 = Color3.fromRGB(140, 120, 30)
            pcall(function()
                TeleportService:TeleportToPlaceInstance(game.PlaceId, sID, player)
            end)
            task.wait(4)
            joinBtn.Text = "Join"
            joinBtn.BackgroundColor3 = Color3.fromRGB(45, 110, 45)
        end)
    end
end

local function displayServerPage()
    clearServerList()
    local servers = ServerHopData.Servers
    local pp = ServerHopData.PerPage
    local page = ServerHopData.CurrentPage
    local total = #servers

    ServerHopData.TotalPages = math.max(1, math.ceil(total / pp))
    if page > ServerHopData.TotalPages then page = ServerHopData.TotalPages ServerHopData.CurrentPage = page end
    if page < 1 then page = 1 ServerHopData.CurrentPage = 1 end

    PageIndicator.Text = string.format("Page %d / %d | %d servers", page, ServerHopData.TotalPages, total)

    local s = (page - 1) * pp + 1
    local e = math.min(page * pp, total)

    if total == 0 then
        local noData = Instance.new("TextLabel")
        noData.Size = UDim2.new(1, 0, 0, 40)
        noData.BackgroundTransparency = 1
        noData.Text = "No servers. Tap Refresh!"
        noData.TextColor3 = Color3.fromRGB(150, 150, 180)
        noData.TextSize = isMobile and 13 or 11
        noData.Font = Enum.Font.Gotham
        noData.ZIndex = 4
        noData.Parent = ServerListFrame
        return
    end

    for i = s, e do
        if servers[i] then createServerEntry(servers[i], i) end
    end

    PrevBtn.BackgroundColor3 = page > 1 and Color3.fromRGB(50, 60, 100) or Color3.fromRGB(40, 40, 55)
    PrevBtn.TextColor3 = page > 1 and Color3.new(1, 1, 1) or Color3.fromRGB(70, 70, 90)
    NextBtn.BackgroundColor3 = page < ServerHopData.TotalPages and Color3.fromRGB(50, 60, 100) or Color3.fromRGB(40, 40, 55)
    NextBtn.TextColor3 = page < ServerHopData.TotalPages and Color3.new(1, 1, 1) or Color3.fromRGB(70, 70, 90)
end

local function fetchAllServers()
    if ServerHopData.IsLoading then return end
    ServerHopData.IsLoading = true
    ServerHopData.Servers = {}
    ServerHopData.CurrentPage = 1

    ServerStatus.Text = "  ⏳ Loading..."
    RefreshBtn.Text = "⏳..."
    RefreshBtn.BackgroundColor3 = Color3.fromRGB(120, 100, 30)
    clearServerList()

    local allSrv = {}
    local cursor = ""
    local pages = 0

    local ok, err = pcall(function()
        repeat
            pages += 1
            local url = string.format(
                "https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100%s",
                game.PlaceId,
                cursor ~= "" and ("&cursor=" .. cursor) or ""
            )
            local resp = HttpService:JSONDecode(game:HttpGet(url))

            if resp and resp.data then
                for _, s in ipairs(resp.data) do
                    table.insert(allSrv, s)
                end
            end
            cursor = (resp and resp.nextPageCursor) or ""
            ServerStatus.Text = string.format("  ⏳ %d servers (page %d)...", #allSrv, pages)
            if cursor ~= "" and pages < 20 then task.wait(0.3) end
        until cursor == "" or pages >= 20
    end)

    ServerHopData.Servers = allSrv
    ServerHopData.IsLoading = false
    ServerStatus.Text = ok
        and string.format("  ✅ %d servers loaded", #allSrv)
        or ("  ❌ Error: " .. tostring(err))
    RefreshBtn.Text = "🔄 Refresh"
    RefreshBtn.BackgroundColor3 = Color3.fromRGB(50, 100, 50)
    displayServerPage()
end

RefreshBtn.MouseButton1Click:Connect(function() task.spawn(fetchAllServers) end)
PrevBtn.MouseButton1Click:Connect(function()
    if ServerHopData.CurrentPage > 1 then ServerHopData.CurrentPage -= 1 displayServerPage() end
end)
NextBtn.MouseButton1Click:Connect(function()
    if ServerHopData.CurrentPage < ServerHopData.TotalPages then ServerHopData.CurrentPage += 1 displayServerPage() end
end)
perPage25.MouseButton1Click:Connect(function()
    ServerHopData.PerPage = 25 ServerHopData.CurrentPage = 1 updatePerPageBtns() displayServerPage()
end)
perPage50.MouseButton1Click:Connect(function()
    ServerHopData.PerPage = 50 ServerHopData.CurrentPage = 1 updatePerPageBtns() displayServerPage()
end)

RandomServerBtn.MouseButton1Click:Connect(function()
    local svrs = ServerHopData.Servers
    if #svrs == 0 then
        RandomServerBtn.Text = "⚠️ Load servers first!"
        task.wait(2)
        RandomServerBtn.Text = "🎲 Join Random Server"
        return
    end
    local avail = {}
    for _, s in ipairs(svrs) do
        if s.id ~= game.JobId and s.playing and s.maxPlayers and s.playing < s.maxPlayers then
            table.insert(avail, s)
        end
    end
    if #avail == 0 then
        RandomServerBtn.Text = "⚠️ No available servers!"
        task.wait(2)
        RandomServerBtn.Text = "🎲 Join Random Server"
        return
    end
    local chosen = avail[math.random(#avail)]
    RandomServerBtn.Text = "⏳ Joining..."
    pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, chosen.id, player) end)
    task.wait(5)
    RandomServerBtn.Text = "🎲 Join Random Server"
end)

-- ================================================================
-- ==================== INFO TAB ==================================
-- ================================================================
local function createInfoBlock(text, parent, order)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -4, 0, 0)
    lbl.AutomaticSize = Enum.AutomaticSize.Y
    lbl.BackgroundColor3 = Color3.fromRGB(35, 35, 52)
    lbl.TextColor3 = Color3.fromRGB(200, 200, 255)
    lbl.TextSize = isMobile and 12 or 11
    lbl.Font = Enum.Font.Gotham
    lbl.TextWrapped = true
    lbl.RichText = true
    lbl.TextYAlignment = Enum.TextYAlignment.Top
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 3
    lbl.LayoutOrder = order or 0
    lbl.Text = text
    lbl.Parent = parent
    local p = Instance.new("UIPadding", lbl)
    p.PaddingTop = UDim.new(0, 8)
    p.PaddingBottom = UDim.new(0, 8)
    p.PaddingLeft = UDim.new(0, 10)
    p.PaddingRight = UDim.new(0, 10)
    Instance.new("UICorner", lbl).CornerRadius = UDim.new(0, 10)
    return lbl
end

createCategory("ℹ️ About", InfoContent, 1)
createInfoBlock(string.format(
    "<b>✨ Obby Helper Pro v2.1</b>\n\n" ..
    "📱 Device: <font color='#64C8FF'>%s</font>\n" ..
    "👤 Player: <font color='#64FF96'>%s</font>\n" ..
    "🆔 PlaceId: <font color='#FFD700'>%d</font>",
    isMobile and "Mobile" or "PC", player.Name, game.PlaceId
), InfoContent, 2)

createCategory("📋 All Features", InfoContent, 3)
createInfoBlock(
    "<b>📡 ESP</b> — Player ESP, Obstacle Visualizer\n\n" ..
    "<b>⚡ Movement</b> — Speed (16-150), Jump (50-300),\n" ..
    "Infinite Jump, Noclip, Anti-Void\n\n" ..
    "<b>👁️ Visual</b> — Fullbright\n\n" ..
    "<b>👥 Players</b>\n" ..
    "• <font color='#FF6666'>📌 TP to Player</font> — <b>BERBAHAYA</b>, ada konfirmasi\n" ..
    "• <font color='#6699FF'>👁️ Spectate</font> — Lihat dari sudut pandang player lain\n" ..
    "• <font color='#66CC77'>🚶 Follow</font> — Ikuti player otomatis\n" ..
    "• 🔍 Search by name\n\n" ..
    "<b>🌐 Server Hop</b> — Browse & join servers,\n" ..
    "pagination 25/50, random join",
    InfoContent, 4
)

createCategory("⚠️ Safety Guide", InfoContent, 5)
createInfoBlock(
    "<font color='#FF8888'><b>🔴 HIGH RISK:</b></font>\n" ..
    "• Teleport to Player — dapat terdeteksi\n\n" ..
    "<font color='#FFCC66'><b>🟡 MEDIUM RISK:</b></font>\n" ..
    "• Speed/Jump Boost — beberapa game cek ini\n" ..
    "• Noclip — sering terdeteksi\n\n" ..
    "<font color='#88FF88'><b>🟢 LOW RISK:</b></font>\n" ..
    "• Spectate — hanya mengubah kamera\n" ..
    "• Follow — menggunakan MoveTo biasa\n" ..
    "• ESP — client-side, sulit terdeteksi\n" ..
    "• Fullbright — hanya ubah lighting lokal",
    InfoContent, 6
)

-- ================================================================
-- ==================== CLEANUP ===================================
-- ================================================================
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
    if fullbrightEnabled then
        pcall(function()
            Lighting.Ambient = oldLighting.Ambient
            Lighting.Brightness = oldLighting.Brightness
            Lighting.OutdoorAmbient = oldLighting.OutdoorAmbient
            Lighting.ClockTime = oldLighting.ClockTime
            Lighting.FogEnd = oldLighting.FogEnd
        end)
    end
    pcall(function()
        if player.Character then
            local hum = player.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = 16 hum.JumpPower = 50 end
        end
    end)
    ConfirmOverlay:Destroy()
    ScreenGui:Destroy()
end)

-- ================================================================
-- ==================== CHARACTER RESPAWN =========================
-- ================================================================
player.CharacterAdded:Connect(function(char)
    local hum = char:WaitForChild("Humanoid", 10)
    if not hum then return end
    task.wait(0.5)

    pcall(function()
        if speedEnabled then hum.WalkSpeed = Settings.SpeedValue end
        if jumpEnabled then hum.UseJumpPower = true hum.JumpPower = Settings.JumpValue end
    end)

    -- Restore camera jika spectating
    if PlayerAction.IsSpectating and PlayerAction.SpectateTarget 
        and PlayerAction.SpectateTarget.Character then
        pcall(function()
            Camera.CameraSubject = PlayerAction.SpectateTarget.Character:FindFirstChildOfClass("Humanoid")
        end)
    end

    if espEnabled then
        task.wait(0.5)
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= player and plr.Character then createPlayerESP(plr) end
        end
    end
end)

Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function()
        task.wait(1)
        if espEnabled then createPlayerESP(plr) end
    end)
end)

-- ================================================================
-- ==================== INIT ======================================
-- ================================================================
switchTab("main")
displayServerPage()

task.delay(1, function()
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "✅ Obby Helper Pro v2.1";
            Text = "4 tabs: Main, Players, Servers, Info";
            Duration = 5;
        })
    end)
end)

print("╔══════════════════════════════════╗")
print("║  ✅ Obby Helper Pro v2.1         ║")
print("║  📱 " .. (isMobile and "Mobile" or "PC"))
print("║  👤 " .. player.Name)
print("║  👥 Players tab with TP/Spec/Follow")
print("╚══════════════════════════════════╝")
