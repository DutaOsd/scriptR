-- // Solara Hub V5 - All In One FIXED
-- // Full Bright + Unlimited Zoom + HP Regen + Fly + ESP + Unlimited Jump
-- // ESP FIXED + Custom Distance Colors + Danger Alert + Radar

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Camera = workspace.CurrentCamera

-- ═══════════════════════════════════════════
-- CLEANUP OLD GUI
-- ═══════════════════════════════════════════
pcall(function()
    game:GetService("CoreGui"):FindFirstChild("SolaraHubV5"):Destroy()
end)
pcall(function()
    game:GetService("CoreGui"):FindFirstChild("SolaraESPv5"):Destroy()
end)

-- ═══════════════════════════════════════════
-- VARIABLES
-- ═══════════════════════════════════════════
local connections = {}
local Flying = false
local FlyToggleState = false
local FlySpeed = 50
local Ctrl = {f = 0, b = 0, l = 0, r = 0}
local LastCtrl = {f = 0, b = 0, l = 0, r = 0}
local MaxSpeed = 0
local BG, BV

local ESPEnabled = false
local ESPFolder = nil
local ESPUpdateConn = nil
local UnlimitedJumpEnabled = false
local JumpConnection = nil

local originalValues = {
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    FogEnd = Lighting.FogEnd,
    FogStart = Lighting.FogStart,
    GlobalShadows = Lighting.GlobalShadows,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    MaxZoom = LocalPlayer.CameraMaxZoomDistance,
    MinZoom = LocalPlayer.CameraMinZoomDistance,
}

local RemovedEffects = {}

-- ═══════════════════════════════════════════
-- ESP DISTANCE COLOR SYSTEM (CUSTOM)
-- Merah: 0-200 studs (DANGER)
-- Kuning: 201-300 studs (WARNING)
-- Hijau: 301-600 studs (MEDIUM)
-- Biru: 601+ studs (FAR/SAFE)
-- ═══════════════════════════════════════════
local ESPSettings = {
    MaxDistance = 1500,
    ShowBox = true,
    ShowName = true,
    ShowHealth = true,
    ShowDistance = true,
    ShowTracer = false,
}

local function GetDistanceColor(distance)
    if distance <= 200 then
        return Color3.fromRGB(255, 50, 50) -- MERAH
    elseif distance <= 300 then
        return Color3.fromRGB(255, 220, 0) -- KUNING
    elseif distance <= 600 then
        return Color3.fromRGB(50, 255, 80) -- HIJAU
    else
        return Color3.fromRGB(60, 160, 255) -- BIRU
    end
end

local function GetDistanceLabel(distance)
    if distance <= 200 then
        return "⚠️ DANGER"
    elseif distance <= 300 then
        return "⚡ WARNING"
    elseif distance <= 600 then
        return "🟢 MEDIUM"
    else
        return "🔵 FAR"
    end
end

local function GetHealthColor(percent)
    local r = math.floor(255 * (1 - percent))
    local g = math.floor(255 * percent)
    return Color3.fromRGB(r, g, 0)
end

-- ═══════════════════════════════════════════
-- SCREEN GUI
-- ═══════════════════════════════════════════
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SolaraHubV5"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = game:GetService("CoreGui")

-- ═══════════════════════════════════════════
-- ESP GUI (terpisah)
-- ═══════════════════════════════════════════
local ESPGui = Instance.new("ScreenGui")
ESPGui.Name = "SolaraESPv5"
ESPGui.ResetOnSpawn = false
ESPGui.IgnoreGuiInset = true
ESPGui.Parent = game:GetService("CoreGui")

-- ═══════════════════════════════════════════
-- MINI ICON
-- ═══════════════════════════════════════════
local MiniIcon = Instance.new("ImageButton")
MiniIcon.Size = UDim2.new(0, 55, 0, 55)
MiniIcon.Position = UDim2.new(0, 20, 0.5, -27)
MiniIcon.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
MiniIcon.BorderSizePixel = 0
MiniIcon.Image = "rbxassetid://7733960981"
MiniIcon.ImageColor3 = Color3.fromRGB(130, 100, 255)
MiniIcon.Visible = false
MiniIcon.AutoButtonColor = false
MiniIcon.Parent = ScreenGui
Instance.new("UICorner", MiniIcon).CornerRadius = UDim.new(0, 14)

local MiniStroke = Instance.new("UIStroke")
MiniStroke.Color = Color3.fromRGB(130, 100, 255)
MiniStroke.Thickness = 2
MiniStroke.Parent = MiniIcon

spawn(function()
    while ScreenGui.Parent do
        if MiniIcon.Visible then
            TweenService:Create(MiniStroke, TweenInfo.new(1, Enum.EasingStyle.Sine), {Color = Color3.fromRGB(200, 170, 255)}):Play()
            task.wait(1)
            if MiniIcon.Visible then
                TweenService:Create(MiniStroke, TweenInfo.new(1, Enum.EasingStyle.Sine), {Color = Color3.fromRGB(130, 100, 255)}):Play()
            end
        end
        task.wait(1)
    end
end)

-- ═══════════════════════════════════════════
-- MAIN FRAME
-- ═══════════════════════════════════════════
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 340, 0, 580)
MainFrame.Position = UDim2.new(0.5, -170, 0.5, -290)
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 14)

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(80, 60, 180)
MainStroke.Thickness = 2
MainStroke.Parent = MainFrame

-- Shadow
local Shadow = Instance.new("ImageLabel")
Shadow.Size = UDim2.new(1, 40, 1, 40)
Shadow.Position = UDim2.new(0, -20, 0, -20)
Shadow.BackgroundTransparency = 1
Shadow.Image = "rbxassetid://5028857084"
Shadow.ImageColor3 = Color3.new(0, 0, 0)
Shadow.ImageTransparency = 0.5
Shadow.ScaleType = Enum.ScaleType.Slice
Shadow.SliceCenter = Rect.new(24, 24, 276, 276)
Shadow.ZIndex = -1
Shadow.Parent = MainFrame

-- ═══════════════════════════════════════════
-- TITLE BAR
-- ═══════════════════════════════════════════
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 45)
TitleBar.BackgroundColor3 = Color3.fromRGB(22, 22, 35)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 14)

local TitleFix = Instance.new("Frame")
TitleFix.Size = UDim2.new(1, 0, 0, 15)
TitleFix.Position = UDim2.new(0, 0, 1, -15)
TitleFix.BackgroundColor3 = Color3.fromRGB(22, 22, 35)
TitleFix.BorderSizePixel = 0
TitleFix.Parent = TitleBar

local TitleText = Instance.new("TextLabel")
TitleText.Size = UDim2.new(0.55, 0, 1, 0)
TitleText.Position = UDim2.new(0, 15, 0, 0)
TitleText.BackgroundTransparency = 1
TitleText.Text = "⚡ Solara Hub V5"
TitleText.TextSize = 17
TitleText.Font = Enum.Font.GothamBold
TitleText.TextColor3 = Color3.fromRGB(160, 130, 255)
TitleText.TextXAlignment = Enum.TextXAlignment.Left
TitleText.Parent = TitleBar

local Sep = Instance.new("Frame")
Sep.Size = UDim2.new(0.92, 0, 0, 1)
Sep.Position = UDim2.new(0.04, 0, 1, 0)
Sep.BackgroundColor3 = Color3.fromRGB(80, 60, 180)
Sep.BackgroundTransparency = 0.6
Sep.BorderSizePixel = 0
Sep.Parent = TitleBar

-- Close
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -38, 0, 8)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseBtn.BorderSizePixel = 0
CloseBtn.Text = "✕"
CloseBtn.TextSize = 15
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextColor3 = Color3.new(1, 1, 1)
CloseBtn.AutoButtonColor = false
CloseBtn.Parent = TitleBar
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 8)

-- Minimize
local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 30, 0, 30)
MinBtn.Position = UDim2.new(1, -74, 0, 8)
MinBtn.BackgroundColor3 = Color3.fromRGB(255, 175, 0)
MinBtn.BorderSizePixel = 0
MinBtn.Text = "—"
MinBtn.TextSize = 16
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextColor3 = Color3.new(1, 1, 1)
MinBtn.AutoButtonColor = false
MinBtn.Parent = TitleBar
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 8)

-- ═══════════════════════════════════════════
-- CONTENT
-- ═══════════════════════════════════════════
local Content = Instance.new("ScrollingFrame")
Content.Size = UDim2.new(1, -20, 1, -65)
Content.Position = UDim2.new(0, 10, 0, 55)
Content.BackgroundTransparency = 1
Content.BorderSizePixel = 0
Content.ScrollBarThickness = 4
Content.ScrollBarImageColor3 = Color3.fromRGB(130, 100, 255)
Content.CanvasSize = UDim2.new(0, 0, 0, 0)
Content.AutomaticCanvasSize = Enum.AutomaticSize.Y
Content.Parent = MainFrame

local ListLayout = Instance.new("UIListLayout")
ListLayout.Padding = UDim.new(0, 10)
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
ListLayout.Parent = Content

Instance.new("UIPadding", Content).PaddingBottom = UDim.new(0, 15)

-- ═══════════════════════════════════════════
-- STATUS
-- ═══════════════════════════════════════════
local StatusFrame = Instance.new("Frame")
StatusFrame.Size = UDim2.new(1, 0, 0, 28)
StatusFrame.BackgroundTransparency = 1
StatusFrame.LayoutOrder = 0
StatusFrame.Parent = Content

local StatusText = Instance.new("TextLabel")
StatusText.Size = UDim2.new(1, 0, 1, 0)
StatusText.BackgroundTransparency = 1
StatusText.Text = "⚙️ Status: Idle"
StatusText.TextSize = 12
StatusText.Font = Enum.Font.Gotham
StatusText.TextColor3 = Color3.fromRGB(100, 100, 130)
StatusText.Parent = StatusFrame

local function SetStatus(txt, col)
    StatusText.Text = txt
    StatusText.TextColor3 = col or Color3.fromRGB(100, 100, 130)
end

-- ═══════════════════════════════════════════
-- SECTION CREATOR
-- ═══════════════════════════════════════════
local function CreateSection(text, order)
    local F = Instance.new("Frame")
    F.Size = UDim2.new(1, 0, 0, 24)
    F.BackgroundTransparency = 1
    F.LayoutOrder = order
    F.Parent = Content

    local L1 = Instance.new("Frame", F)
    L1.Size = UDim2.new(0.18, 0, 0, 1)
    L1.Position = UDim2.new(0, 0, 0.5, 0)
    L1.BackgroundColor3 = Color3.fromRGB(80, 60, 180)
    L1.BackgroundTransparency = 0.5
    L1.BorderSizePixel = 0

    local SL = Instance.new("TextLabel", F)
    SL.Size = UDim2.new(0.64, 0, 1, 0)
    SL.Position = UDim2.new(0.18, 0, 0, 0)
    SL.BackgroundTransparency = 1
    SL.Text = text
    SL.TextSize = 11
    SL.Font = Enum.Font.GothamBold
    SL.TextColor3 = Color3.fromRGB(130, 100, 255)

    local L2 = Instance.new("Frame", F)
    L2.Size = UDim2.new(0.18, 0, 0, 1)
    L2.Position = UDim2.new(0.82, 0, 0.5, 0)
    L2.BackgroundColor3 = Color3.fromRGB(80, 60, 180)
    L2.BackgroundTransparency = 0.5
    L2.BorderSizePixel = 0
end

-- ═══════════════════════════════════════════
-- TOGGLE CREATOR
-- ═══════════════════════════════════════════
local function CreateToggle(title, desc, order, callback)
    local F = Instance.new("Frame")
    F.Size = UDim2.new(1, 0, 0, 70)
    F.BackgroundColor3 = Color3.fromRGB(28, 28, 42)
    F.BorderSizePixel = 0
    F.LayoutOrder = order
    F.Parent = Content
    Instance.new("UICorner", F).CornerRadius = UDim.new(0, 10)

    local FS = Instance.new("UIStroke", F)
    FS.Color = Color3.fromRGB(45, 45, 65)
    FS.Thickness = 1

    Instance.new("TextLabel", F).Size = UDim2.new(0.65, 0, 0, 28)
    local TL = F:FindFirstChildOfClass("TextLabel")
    TL.Position = UDim2.new(0, 14, 0, 8)
    TL.BackgroundTransparency = 1
    TL.Text = title
    TL.TextSize = 14
    TL.Font = Enum.Font.GothamBold
    TL.TextColor3 = Color3.new(1, 1, 1)
    TL.TextXAlignment = Enum.TextXAlignment.Left

    local DL = Instance.new("TextLabel", F)
    DL.Size = UDim2.new(0.65, 0, 0, 22)
    DL.Position = UDim2.new(0, 14, 0, 34)
    DL.BackgroundTransparency = 1
    DL.Text = desc
    DL.TextSize = 11
    DL.Font = Enum.Font.Gotham
    DL.TextColor3 = Color3.fromRGB(140, 140, 160)
    DL.TextXAlignment = Enum.TextXAlignment.Left

    local SBG = Instance.new("Frame", F)
    SBG.Size = UDim2.new(0, 50, 0, 26)
    SBG.Position = UDim2.new(1, -64, 0.5, -13)
    SBG.BackgroundColor3 = Color3.fromRGB(55, 55, 75)
    SBG.BorderSizePixel = 0
    Instance.new("UICorner", SBG).CornerRadius = UDim.new(1, 0)

    local SC = Instance.new("Frame", SBG)
    SC.Size = UDim2.new(0, 20, 0, 20)
    SC.Position = UDim2.new(0, 3, 0.5, -10)
    SC.BackgroundColor3 = Color3.fromRGB(180, 180, 190)
    SC.BorderSizePixel = 0
    Instance.new("UICorner", SC).CornerRadius = UDim.new(1, 0)

    local Btn = Instance.new("TextButton", SBG)
    Btn.Size = UDim2.new(1, 0, 1, 0)
    Btn.BackgroundTransparency = 1
    Btn.Text = ""

    local toggled = false

    Btn.MouseButton1Click:Connect(function()
        toggled = not toggled
        if toggled then
            TweenService:Create(SBG, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {BackgroundColor3 = Color3.fromRGB(80, 200, 120)}):Play()
            TweenService:Create(SC, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {Position = UDim2.new(1, -23, 0.5, -10), BackgroundColor3 = Color3.new(1, 1, 1)}):Play()
            TweenService:Create(FS, TweenInfo.new(0.3), {Color = Color3.fromRGB(80, 200, 120)}):Play()
        else
            TweenService:Create(SBG, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {BackgroundColor3 = Color3.fromRGB(55, 55, 75)}):Play()
            TweenService:Create(SC, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {Position = UDim2.new(0, 3, 0.5, -10), BackgroundColor3 = Color3.fromRGB(180, 180, 190)}):Play()
            TweenService:Create(FS, TweenInfo.new(0.3), {Color = Color3.fromRGB(45, 45, 65)}):Play()
        end
        callback(toggled)
    end)
end

-- ═══════════════════════════════════════════
-- SLIDER CREATOR
-- ═══════════════════════════════════════════
local function CreateSlider(title, min, max, default, order, callback)
    local F = Instance.new("Frame")
    F.Size = UDim2.new(1, 0, 0, 70)
    F.BackgroundColor3 = Color3.fromRGB(28, 28, 42)
    F.BorderSizePixel = 0
    F.LayoutOrder = order
    F.Parent = Content
    Instance.new("UICorner", F).CornerRadius = UDim.new(0, 10)
    Instance.new("UIStroke", F).Color = Color3.fromRGB(45, 45, 65)

    local ST = Instance.new("TextLabel", F)
    ST.Size = UDim2.new(0.65, 0, 0, 25)
    ST.Position = UDim2.new(0, 14, 0, 5)
    ST.BackgroundTransparency = 1
    ST.Text = title
    ST.TextSize = 13
    ST.Font = Enum.Font.GothamBold
    ST.TextColor3 = Color3.new(1, 1, 1)
    ST.TextXAlignment = Enum.TextXAlignment.Left

    local VL = Instance.new("TextLabel", F)
    VL.Size = UDim2.new(0.3, 0, 0, 25)
    VL.Position = UDim2.new(0.68, 0, 0, 5)
    VL.BackgroundTransparency = 1
    VL.Text = tostring(default)
    VL.TextSize = 14
    VL.Font = Enum.Font.GothamBold
    VL.TextColor3 = Color3.fromRGB(130, 100, 255)
    VL.TextXAlignment = Enum.TextXAlignment.Right

    local SBG = Instance.new("Frame", F)
    SBG.Size = UDim2.new(0.88, 0, 0, 8)
    SBG.Position = UDim2.new(0.06, 0, 0, 42)
    SBG.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    SBG.BorderSizePixel = 0
    Instance.new("UICorner", SBG).CornerRadius = UDim.new(1, 0)

    local ratio = (default - min) / (max - min)

    local SF = Instance.new("Frame", SBG)
    SF.Size = UDim2.new(ratio, 0, 1, 0)
    SF.BackgroundColor3 = Color3.fromRGB(130, 100, 255)
    SF.BorderSizePixel = 0
    Instance.new("UICorner", SF).CornerRadius = UDim.new(1, 0)

    local SCi = Instance.new("Frame", SBG)
    SCi.Size = UDim2.new(0, 18, 0, 18)
    SCi.Position = UDim2.new(ratio, -9, 0.5, -9)
    SCi.BackgroundColor3 = Color3.new(1, 1, 1)
    SCi.BorderSizePixel = 0
    SCi.ZIndex = 2
    Instance.new("UICorner", SCi).CornerRadius = UDim.new(1, 0)

    local SBtn = Instance.new("TextButton", SBG)
    SBtn.Size = UDim2.new(1, 0, 0, 30)
    SBtn.Position = UDim2.new(0, 0, 0, -11)
    SBtn.BackgroundTransparency = 1
    SBtn.Text = ""

    local sliding = false
    SBtn.MouseButton1Down:Connect(function() sliding = true end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then sliding = false end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if sliding and input.UserInputType == Enum.UserInputType.MouseMovement then
            local r = math.clamp((input.Position.X - SBG.AbsolutePosition.X) / SBG.AbsoluteSize.X, 0, 1)
            local value = math.floor(min + (max - min) * r)
            SF.Size = UDim2.new(r, 0, 1, 0)
            SCi.Position = UDim2.new(r, -9, 0.5, -9)
            VL.Text = tostring(value)
            callback(value)
        end
    end)
end

-- ═══════════════════════════════════════════
-- ESP SYSTEM (FIXED - BillboardGui Method)
-- ═══════════════════════════════════════════
local espBillboards = {}

local function RemovePlayerESP(player)
    if espBillboards[player] then
        for _, obj in pairs(espBillboards[player]) do
            pcall(function() obj:Destroy() end)
        end
        espBillboards[player] = nil
    end
end

local function CreatePlayerESP(player)
    if player == LocalPlayer then return end
    RemovePlayerESP(player)

    local function Setup(character)
        if not character then return end

        local hrp = character:WaitForChild("HumanoidRootPart", 5)
        local head = character:WaitForChild("Head", 5)
        local hum = character:WaitForChild("Humanoid", 5)
        if not hrp or not head or not hum then return end

        local espParts = {}
        espBillboards[player] = espParts

        -- ══════ HIGHLIGHT (Through Wall) ══════
        local highlight = Instance.new("Highlight")
        highlight.Name = "SolaraESP"
        highlight.FillTransparency = 0.7
        highlight.OutlineTransparency = 0.1
        highlight.FillColor = Color3.fromRGB(255, 50, 50)
        highlight.OutlineColor = Color3.fromRGB(255, 50, 50)
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Adornee = character
        highlight.Parent = ESPGui
        espParts.Highlight = highlight

        -- ══════ BILLBOARD INFO ══════
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "SolaraESPInfo"
        billboard.Adornee = head
        billboard.Size = UDim2.new(0, 200, 0, 100)
        billboard.StudsOffset = Vector3.new(0, 3, 0)
        billboard.AlwaysOnTop = true
        billboard.LightInfluence = 0
        billboard.MaxDistance = ESPSettings.MaxDistance
        billboard.Parent = ESPGui
        espParts.Billboard = billboard

        -- Player Name Label
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, 0, 0, 20)
        nameLabel.Position = UDim2.new(0, 0, 0, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = player.Name
        nameLabel.TextSize = 14
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextColor3 = Color3.new(1, 1, 1)
        nameLabel.TextStrokeTransparency = 0.3
        nameLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
        nameLabel.Parent = billboard
        espParts.NameLabel = nameLabel

        -- Distance Label
        local distLabel = Instance.new("TextLabel")
        distLabel.Size = UDim2.new(1, 0, 0, 16)
        distLabel.Position = UDim2.new(0, 0, 0, 20)
        distLabel.BackgroundTransparency = 1
        distLabel.Text = "[0m]"
        distLabel.TextSize = 12
        distLabel.Font = Enum.Font.GothamBold
        distLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        distLabel.TextStrokeTransparency = 0.3
        distLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
        distLabel.Parent = billboard
        espParts.DistLabel = distLabel

        -- Danger Status Label
        local dangerLabel = Instance.new("TextLabel")
        dangerLabel.Size = UDim2.new(1, 0, 0, 16)
        dangerLabel.Position = UDim2.new(0, 0, 0, 36)
        dangerLabel.BackgroundTransparency = 1
        dangerLabel.Text = ""
        dangerLabel.TextSize = 12
        dangerLabel.Font = Enum.Font.GothamBold
        dangerLabel.TextStrokeTransparency = 0.3
        dangerLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
        dangerLabel.Parent = billboard
        espParts.DangerLabel = dangerLabel

        -- Health Bar Background
        local hpBG = Instance.new("Frame")
        hpBG.Size = UDim2.new(0.8, 0, 0, 6)
        hpBG.Position = UDim2.new(0.1, 0, 0, 56)
        hpBG.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        hpBG.BorderSizePixel = 0
        hpBG.Parent = billboard
        Instance.new("UICorner", hpBG).CornerRadius = UDim.new(1, 0)
        espParts.HpBG = hpBG

        local hpFill = Instance.new("Frame")
        hpFill.Size = UDim2.new(1, 0, 1, 0)
        hpFill.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        hpFill.BorderSizePixel = 0
        hpFill.Parent = hpBG
        Instance.new("UICorner", hpFill).CornerRadius = UDim.new(1, 0)
        espParts.HpFill = hpFill

        -- HP Text
        local hpText = Instance.new("TextLabel")
        hpText.Size = UDim2.new(1, 0, 0, 14)
        hpText.Position = UDim2.new(0, 0, 0, 64)
        hpText.BackgroundTransparency = 1
        hpText.TextSize = 10
        hpText.Font = Enum.Font.Gotham
        hpText.TextStrokeTransparency = 0.3
        hpText.TextStrokeColor3 = Color3.new(0, 0, 0)
        hpText.Parent = billboard
        espParts.HpText = hpText

        -- ══════ BOX HIGHLIGHT (Selection Box) ══════
        local selectionBox = Instance.new("SelectionBox")
        selectionBox.Adornee = character
        selectionBox.Color3 = Color3.fromRGB(255, 50, 50)
        selectionBox.LineThickness = 0.03
        selectionBox.SurfaceTransparency = 0.9
        selectionBox.SurfaceColor3 = Color3.fromRGB(255, 50, 50)
        selectionBox.Parent = ESPGui
        espParts.SelectionBox = selectionBox

        -- ══════ HEAD DOT ══════
        local headAdorn = Instance.new("BillboardGui")
        headAdorn.Name = "HeadDot"
        headAdorn.Adornee = head
        headAdorn.Size = UDim2.new(1, 0, 1, 0)
        headAdorn.AlwaysOnTop = true
        headAdorn.LightInfluence = 0
        headAdorn.MaxDistance = ESPSettings.MaxDistance
        headAdorn.Parent = ESPGui
        espParts.HeadAdorn = headAdorn

        local headCircle = Instance.new("Frame")
        headCircle.Size = UDim2.new(0.5, 0, 0.5, 0)
        headCircle.Position = UDim2.new(0.25, 0, 0.25, 0)
        headCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        headCircle.BorderSizePixel = 0
        headCircle.Parent = headAdorn
        Instance.new("UICorner", headCircle).CornerRadius = UDim.new(1, 0)
        espParts.HeadCircle = headCircle

        -- ══════ BEAM TRACER ══════
        local tracerAttachment0 = Instance.new("Attachment")
        tracerAttachment0.Parent = hrp
        espParts.TracerAtt0 = tracerAttachment0

        local tracerPart = Instance.new("Part")
        tracerPart.Name = "SolaraTracerAnchor"
        tracerPart.Anchored = true
        tracerPart.CanCollide = false
        tracerPart.Transparency = 1
        tracerPart.Size = Vector3.new(0.1, 0.1, 0.1)
        tracerPart.Parent = workspace
        espParts.TracerPart = tracerPart

        local tracerAttachment1 = Instance.new("Attachment")
        tracerAttachment1.Parent = tracerPart
        espParts.TracerAtt1 = tracerAttachment1

        local beam = Instance.new("Beam")
        beam.Attachment0 = tracerAttachment1
        beam.Attachment1 = tracerAttachment0
        beam.Width0 = 0.1
        beam.Width1 = 0.1
        beam.FaceCamera = true
        beam.Transparency = NumberSequence.new(0.5)
        beam.LightEmission = 1
        beam.Enabled = ESPSettings.ShowTracer
        beam.Parent = hrp
        espParts.Beam = beam
    end

    -- Setup langsung
    if player.Character then
        Setup(player.Character)
    end

    -- Setup ulang saat respawn
    local charConn = player.CharacterAdded:Connect(function(char)
        task.wait(1)
        if ESPEnabled then
            RemovePlayerESP(player)
            Setup(char)
        end
    end)

    if not espBillboards[player] then
        espBillboards[player] = {}
    end
    espBillboards[player].CharConn = charConn
end

-- ═══════════════════════════════════════════
-- ESP AUTO UPDATE LOOP
-- ═══════════════════════════════════════════
local function UpdateAllESP()
    local localChar = LocalPlayer.Character
    if not localChar then return end
    local localHRP = localChar:FindFirstChild("HumanoidRootPart")
    if not localHRP then return end

    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end

        local espData = espBillboards[player]
        if not espData then continue end

        local char = player.Character
        if not char then continue end

        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum then continue end

        local distance = (hrp.Position - localHRP.Position).Magnitude
        local distColor = GetDistanceColor(distance)
        local distLabel = GetDistanceLabel(distance)
        local hpPercent = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
        local hpColor = GetHealthColor(hpPercent)

        -- Update Highlight
        if espData.Highlight then
            espData.Highlight.FillColor = distColor
            espData.Highlight.OutlineColor = distColor
            espData.Highlight.Enabled = (hum.Health > 0)
        end

        -- Update Selection Box
        if espData.SelectionBox then
            espData.SelectionBox.Color3 = distColor
            espData.SelectionBox.SurfaceColor3 = distColor
            espData.SelectionBox.Visible = (hum.Health > 0)
        end

        -- Update Name
        if espData.NameLabel then
            espData.NameLabel.TextColor3 = distColor
            espData.NameLabel.Text = player.Name
        end

        -- Update Distance
        if espData.DistLabel then
            espData.DistLabel.Text = "[" .. math.floor(distance) .. " studs]"
            espData.DistLabel.TextColor3 = distColor
        end

        -- Update Danger Label
        if espData.DangerLabel then
            espData.DangerLabel.Text = distLabel
            espData.DangerLabel.TextColor3 = distColor
        end

        -- Update HP Bar
        if espData.HpFill then
            espData.HpFill.Size = UDim2.new(hpPercent, 0, 1, 0)
            espData.HpFill.BackgroundColor3 = hpColor
        end

        -- Update HP Text
        if espData.HpText then
            espData.HpText.Text = math.floor(hum.Health) .. " / " .. math.floor(hum.MaxHealth)
            espData.HpText.TextColor3 = hpColor
        end

        -- Update Head Circle
        if espData.HeadCircle then
            espData.HeadCircle.BackgroundColor3 = distColor
        end

        -- Update Billboard visibility
        if espData.Billboard then
            espData.Billboard.Enabled = (hum.Health > 0)
            espData.Billboard.MaxDistance = ESPSettings.MaxDistance
        end
        if espData.HeadAdorn then
            espData.HeadAdorn.Enabled = (hum.Health > 0)
            espData.HeadAdorn.MaxDistance = ESPSettings.MaxDistance
        end

        -- Update Tracer
        if espData.Beam then
            espData.Beam.Enabled = ESPSettings.ShowTracer and (hum.Health > 0)
            espData.Beam.Color = ColorSequence.new(distColor)
        end

        -- Update Tracer Part position (kaki player lokal)
        if espData.TracerPart then
            espData.TracerPart.CFrame = CFrame.new(localHRP.Position - Vector3.new(0, 3, 0))
        end
    end
end

-- Auto handle new players
Players.PlayerAdded:Connect(function(player)
    if ESPEnabled then
        task.wait(2)
        CreatePlayerESP(player)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    RemovePlayerESP(player)
end)

-- ═══════════════════════════════════════════
-- DANGER ALERT SYSTEM
-- ═══════════════════════════════════════════
local AlertFrame = Instance.new("Frame")
AlertFrame.Size = UDim2.new(0, 300, 0, 55)
AlertFrame.Position = UDim2.new(0.5, -150, 0, 20)
AlertFrame.BackgroundColor3 = Color3.fromRGB(180, 25, 25)
AlertFrame.BackgroundTransparency = 0.2
AlertFrame.BorderSizePixel = 0
AlertFrame.Visible = false
AlertFrame.Parent = ESPGui
Instance.new("UICorner", AlertFrame).CornerRadius = UDim.new(0, 12)

local AlertStroke2 = Instance.new("UIStroke")
AlertStroke2.Color = Color3.fromRGB(255, 60, 60)
AlertStroke2.Thickness = 2
AlertStroke2.Parent = AlertFrame

local AlertText = Instance.new("TextLabel")
AlertText.Size = UDim2.new(1, 0, 1, 0)
AlertText.BackgroundTransparency = 1
AlertText.Text = "⚠️ DANGER!"
AlertText.TextSize = 16
AlertText.Font = Enum.Font.GothamBold
AlertText.TextColor3 = Color3.new(1, 1, 1)
AlertText.TextStrokeTransparency = 0.5
AlertText.Parent = AlertFrame

local alertActive = false
spawn(function()
    while ESPGui.Parent do
        if alertActive and AlertFrame.Visible then
            TweenService:Create(AlertFrame, TweenInfo.new(0.4, Enum.EasingStyle.Sine), {BackgroundTransparency = 0.05}):Play()
            task.wait(0.4)
            TweenService:Create(AlertFrame, TweenInfo.new(0.4, Enum.EasingStyle.Sine), {BackgroundTransparency = 0.5}):Play()
            task.wait(0.4)
        else
            task.wait(0.3)
        end
    end
end)

local function CheckDangerAlert()
    local localChar = LocalPlayer.Character
    if not localChar then AlertFrame.Visible = false; alertActive = false return end
    local localHRP = localChar:FindFirstChild("HumanoidRootPart")
    if not localHRP then AlertFrame.Visible = false; alertActive = false return end

    local closestDist = math.huge
    local closestName = ""
    local dangerCount = 0

    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        local char = player.Character
        if not char then continue end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum or hum.Health <= 0 then continue end

        local dist = (hrp.Position - localHRP.Position).Magnitude
        if dist <= 200 then
            dangerCount += 1
            if dist < closestDist then
                closestDist = dist
                closestName = player.Name
            end
        end
    end

    if dangerCount > 0 then
        alertActive = true
        AlertFrame.Visible = true
        if dangerCount == 1 then
            AlertText.Text = "⚠️ DANGER! " .. closestName .. " [" .. math.floor(closestDist) .. " studs]"
        else
            AlertText.Text = "⚠️ DANGER! " .. dangerCount .. " Players within 200 studs!"
        end
    else
        alertActive = false
        AlertFrame.Visible = false
    end
end

-- ═══════════════════════════════════════════
-- RADAR
-- ═══════════════════════════════════════════
local RadarFrame = Instance.new("Frame")
RadarFrame.Size = UDim2.new(0, 160, 0, 160)
RadarFrame.Position = UDim2.new(1, -180, 1, -200)
RadarFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 20)
RadarFrame.BackgroundTransparency = 0.3
RadarFrame.BorderSizePixel = 0
RadarFrame.Visible = false
RadarFrame.Parent = ESPGui
Instance.new("UICorner", RadarFrame).CornerRadius = UDim.new(1, 0)
Instance.new("UIStroke", RadarFrame).Color = Color3.fromRGB(130, 100, 255)

-- Grid lines
for _, v in pairs({{true}, {false}}) do
    local l = Instance.new("Frame", RadarFrame)
    l.BackgroundColor3 = Color3.fromRGB(80, 60, 180)
    l.BackgroundTransparency = 0.7
    l.BorderSizePixel = 0
    if v[1] then
        l.Size = UDim2.new(0, 1, 1, 0)
        l.Position = UDim2.new(0.5, 0, 0, 0)
    else
        l.Size = UDim2.new(1, 0, 0, 1)
        l.Position = UDim2.new(0, 0, 0.5, 0)
    end
end

-- Self dot
local SelfDot = Instance.new("Frame", RadarFrame)
SelfDot.Size = UDim2.new(0, 8, 0, 8)
SelfDot.Position = UDim2.new(0.5, -4, 0.5, -4)
SelfDot.BackgroundColor3 = Color3.fromRGB(100, 200, 255)
SelfDot.BorderSizePixel = 0
Instance.new("UICorner", SelfDot).CornerRadius = UDim.new(1, 0)

local RadarLabel = Instance.new("TextLabel", RadarFrame)
RadarLabel.Size = UDim2.new(1, 0, 0, 16)
RadarLabel.Position = UDim2.new(0, 0, 0, 3)
RadarLabel.BackgroundTransparency = 1
RadarLabel.Text = "RADAR"
RadarLabel.TextSize = 10
RadarLabel.Font = Enum.Font.GothamBold
RadarLabel.TextColor3 = Color3.fromRGB(130, 100, 255)

local radarDots = {}

local function UpdateRadar()
    for _, d in pairs(radarDots) do pcall(function() d:Destroy() end) end
    radarDots = {}

    local localChar = LocalPlayer.Character
    if not localChar then return end
    local localHRP = localChar:FindFirstChild("HumanoidRootPart")
    if not localHRP then return end

    local radarRange = 400

    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        local char = player.Character
        if not char then continue end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum or hum.Health <= 0 then continue end

        local dist = (hrp.Position - localHRP.Position).Magnitude
        if dist > radarRange then continue end

        local rel = localHRP.CFrame:PointToObjectSpace(hrp.Position)
        local nx = math.clamp(rel.X / radarRange, -1, 1)
        local nz = math.clamp(rel.Z / radarRange, -1, 1)
        local color = GetDistanceColor(dist)

        local dot = Instance.new("Frame", RadarFrame)
        dot.Size = UDim2.new(0, 8, 0, 8)
        dot.Position = UDim2.new(0.5 + nx * 0.42, -4, 0.5 + nz * 0.42, -4)
        dot.BackgroundColor3 = color
        dot.BorderSizePixel = 0
        Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

        local dName = Instance.new("TextLabel", dot)
        dName.Size = UDim2.new(0, 60, 0, 12)
        dName.Position = UDim2.new(0, 10, 0, -2)
        dName.BackgroundTransparency = 1
        dName.Text = player.Name
        dName.TextSize = 8
        dName.Font = Enum.Font.GothamBold
        dName.TextColor3 = color
        dName.TextXAlignment = Enum.TextXAlignment.Left

        table.insert(radarDots, dot)
    end
end

-- ═══════════════════════════════════════════
-- CREATE ALL TOGGLES & SECTIONS
-- ═══════════════════════════════════════════

CreateSection("— VISUAL —", 1)

-- Full Bright
CreateToggle("🌞 Full Bright", "Semua area jadi terang total", 2, function(state)
    if state then
        for _, v in pairs(Lighting:GetDescendants()) do
            if v:IsA("Atmosphere") or v:IsA("BloomEffect") or v:IsA("DepthOfFieldEffect") or v:IsA("ColorCorrectionEffect") or v:IsA("SunRaysEffect") then
                v.Parent = nil
                table.insert(RemovedEffects, v)
            end
        end
        connections["bright"] = RunService.RenderStepped:Connect(function()
            Lighting.ClockTime = 14; Lighting.Brightness = 2; Lighting.FogEnd = 1e6; Lighting.FogStart = 0; Lighting.GlobalShadows = false; Lighting.OutdoorAmbient = Color3.new(1,1,1)
        end)
        connections["brightChild"] = Lighting.ChildAdded:Connect(function(c)
            if c:IsA("Atmosphere") or c:IsA("BloomEffect") or c:IsA("DepthOfFieldEffect") then task.wait() c:Destroy() end
        end)
        SetStatus("🌞 Full Bright: ON", Color3.fromRGB(100, 255, 120))
    else
        if connections["bright"] then connections["bright"]:Disconnect() end
        if connections["brightChild"] then connections["brightChild"]:Disconnect() end
        Lighting.Brightness = originalValues.Brightness; Lighting.ClockTime = originalValues.ClockTime; Lighting.FogEnd = originalValues.FogEnd; Lighting.FogStart = originalValues.FogStart; Lighting.GlobalShadows = originalValues.GlobalShadows; Lighting.OutdoorAmbient = originalValues.OutdoorAmbient
        for _, v in pairs(RemovedEffects) do pcall(function() v.Parent = Lighting end) end
        RemovedEffects = {}
        SetStatus("🌞 Full Bright: OFF", Color3.fromRGB(255, 100, 100))
    end
end)

-- Unlimited Zoom
CreateToggle("🔭 Unlimited Zoom", "Zoom kamera tanpa batas", 3, function(state)
    if state then
        connections["zoom"] = RunService.RenderStepped:Connect(function()
            LocalPlayer.CameraMaxZoomDistance = 1e6; LocalPlayer.CameraMinZoomDistance = 0.1
        end)
        SetStatus("🔭 Unlimited Zoom: ON", Color3.fromRGB(100, 255, 120))
    else
        if connections["zoom"] then connections["zoom"]:Disconnect() end
        LocalPlayer.CameraMaxZoomDistance = originalValues.MaxZoom; LocalPlayer.CameraMinZoomDistance = originalValues.MinZoom
        SetStatus("🔭 Unlimited Zoom: OFF", Color3.fromRGB(255, 100, 100))
    end
end)

CreateSection("— COMBAT —", 4)

-- HP Regen
CreateToggle("❤️ HP Regen", "Instant auto heal setiap frame", 5, function(state)
    if state then
        connections["regen"] = RunService.Heartbeat:Connect(function()
            local c = LocalPlayer.Character
            if c then local h = c:FindFirstChildOfClass("Humanoid") if h and h.Health > 0 then h.Health = h.MaxHealth end end
        end)
        connections["regenR"] = LocalPlayer.CharacterAdded:Connect(function(c)
            task.wait(0.5)
            local h = c:WaitForChild("Humanoid", 5)
            if h then h.Health = h.MaxHealth end
        end)
        SetStatus("❤️ HP Regen: ON", Color3.fromRGB(100, 255, 120))
    else
        if connections["regen"] then connections["regen"]:Disconnect() end
        if connections["regenR"] then connections["regenR"]:Disconnect() end
        SetStatus("❤️ HP Regen: OFF", Color3.fromRGB(255, 100, 100))
    end
end)

CreateSection("— MOVEMENT —", 6)

-- Fly
local function StartFly()
    local char = LocalPlayer.Character
    if not char then return end
    local torso = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not torso or not hum then return end

    BG = Instance.new("BodyGyro", torso)
    BV = Instance.new("BodyVelocity", torso)
    BG.P = 9e4; BG.maxTorque = Vector3.new(9e9,9e9,9e9); BG.cframe = torso.CFrame
    BV.velocity = Vector3.new(0,0.1,0); BV.maxForce = Vector3.new(9e9,9e9,9e9)

    spawn(function()
        repeat task.wait()
            if not Flying then break end
            hum.PlatformStand = true
            MaxSpeed = ((Ctrl.l+Ctrl.r)~=0 or (Ctrl.f+Ctrl.b)~=0) and FlySpeed or 0

            if (Ctrl.l+Ctrl.r)~=0 or (Ctrl.f+Ctrl.b)~=0 then
                BV.velocity = ((Camera.CoordinateFrame.lookVector*(Ctrl.f+Ctrl.b))+((Camera.CoordinateFrame*CFrame.new(Ctrl.l+Ctrl.r,(Ctrl.f+Ctrl.b)*0.2,0).p)-Camera.CoordinateFrame.p))*MaxSpeed
                LastCtrl = {f=Ctrl.f,b=Ctrl.b,l=Ctrl.l,r=Ctrl.r}
            elseif MaxSpeed~=0 then
                BV.velocity = ((Camera.CoordinateFrame.lookVector*(LastCtrl.f+LastCtrl.b))+((Camera.CoordinateFrame*CFrame.new(LastCtrl.l+LastCtrl.r,(LastCtrl.f+LastCtrl.b)*0.2,0).p)-Camera.CoordinateFrame.p))*MaxSpeed
            else
                BV.velocity = Vector3.new(0,0.1,0)
            end
            BG.cframe = Camera.CoordinateFrame
        until not Flying

        Ctrl={f=0,b=0,l=0,r=0}; LastCtrl={f=0,b=0,l=0,r=0}; MaxSpeed=0
        if BG then BG:Destroy() end
        if BV then BV:Destroy() end
        if hum then hum.PlatformStand = false end
    end)
end

CreateToggle("✈️ Fly", "Terbang bebas WASD + arah kamera", 7, function(state)
    FlyToggleState = state; Flying = state
    if state then StartFly(); SetStatus("✈️ Fly: ON | Speed: "..FlySpeed, Color3.fromRGB(100,255,120))
    else SetStatus("✈️ Fly: OFF", Color3.fromRGB(255,100,100)) end
end)

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    if FlyToggleState then Flying = true; StartFly() end
end)

CreateSlider("✈️ Fly Speed", 10, 500, 50, 8, function(v)
    FlySpeed = v
    if FlyToggleState then SetStatus("✈️ Fly Speed: "..v, Color3.fromRGB(100,255,120)) end
end)

-- ═══════════════════════════════════════════
-- UNLIMITED JUMP
-- ═══════════════════════════════════════════
CreateToggle("🦘 Unlimited Jump", "Lompat di udara tanpa batas", 9, function(state)
    UnlimitedJumpEnabled = state

    if state then
        JumpConnection = UserInputService.JumpRequest:Connect(function()
            if UnlimitedJumpEnabled then
                local char = LocalPlayer.Character
                if char then
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if hum then
                        hum:ChangeState(Enum.HumanoidStateType.Jumping)
                    end
                end
            end
        end)
        SetStatus("🦘 Unlimited Jump: ON", Color3.fromRGB(100, 255, 120))
    else
        if JumpConnection then
            JumpConnection:Disconnect()
            JumpConnection = nil
        end
        SetStatus("🦘 Unlimited Jump: OFF", Color3.fromRGB(255, 100, 100))
    end
end)

CreateSection("— ESP / RADAR —", 10)

-- ESP Toggle
CreateToggle("👁️ ESP (Full)", "Box + Name + HP + Distance + Highlight", 11, function(state)
    ESPEnabled = state

    if state then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                CreatePlayerESP(player)
            end
        end

        ESPUpdateConn = RunService.RenderStepped:Connect(function()
            UpdateAllESP()
            CheckDangerAlert()
        end)

        SetStatus("👁️ ESP: ON (Auto Updating)", Color3.fromRGB(100, 255, 120))
    else
        if ESPUpdateConn then ESPUpdateConn:Disconnect(); ESPUpdateConn = nil end

        for _, player in pairs(Players:GetPlayers()) do
            RemovePlayerESP(player)
        end

        AlertFrame.Visible = false
        alertActive = false
        SetStatus("👁️ ESP: OFF", Color3.fromRGB(255, 100, 100))
    end
end)

-- Tracer Toggle
CreateToggle("📍 Tracer Lines", "Garis penunjuk arah ke musuh", 12, function(state)
    ESPSettings.ShowTracer = state
    SetStatus("📍 Tracer: "..(state and "ON" or "OFF"), state and Color3.fromRGB(100,255,120) or Color3.fromRGB(255,100,100))
end)

-- Radar Toggle
CreateToggle("🗺️ Mini Radar", "Radar deteksi musuh di sekitar", 13, function(state)
    RadarFrame.Visible = state
    if state then
        connections["radar"] = RunService.RenderStepped:Connect(function() UpdateRadar() end)
        SetStatus("🗺️ Radar: ON", Color3.fromRGB(100, 255, 120))
    else
        if connections["radar"] then connections["radar"]:Disconnect() end
        SetStatus("🗺️ Radar: OFF", Color3.fromRGB(255, 100, 100))
    end
end)

-- ESP Distance Slider
CreateSlider("👁️ ESP Max Distance", 100, 3000, 1500, 14, function(v)
    ESPSettings.MaxDistance = v
end)

-- ═══════════════════════════════════════════
-- COLOR LEGEND
-- ═══════════════════════════════════════════
local LegendFrame = Instance.new("Frame")
LegendFrame.Size = UDim2.new(1, 0, 0, 90)
LegendFrame.BackgroundColor3 = Color3.fromRGB(28, 28, 42)
LegendFrame.BorderSizePixel = 0
LegendFrame.LayoutOrder = 15
LegendFrame.Parent = Content
Instance.new("UICorner", LegendFrame).CornerRadius = UDim.new(0, 10)
Instance.new("UIStroke", LegendFrame).Color = Color3.fromRGB(45, 45, 65)

local LTitle = Instance.new("TextLabel", LegendFrame)
LTitle.Size = UDim2.new(1, 0, 0, 20)
LTitle.Position = UDim2.new(0, 0, 0, 2)
LTitle.BackgroundTransparency = 1
LTitle.Text = "🎨 ESP Color Legend"
LTitle.TextSize = 12
LTitle.Font = Enum.Font.GothamBold
LTitle.TextColor3 = Color3.fromRGB(200, 200, 200)

local legendData = {
    {Color3.fromRGB(255,50,50), "🔴 0-200 studs = DANGER", 22},
    {Color3.fromRGB(255,220,0), "🟡 201-300 studs = WARNING", 36},
    {Color3.fromRGB(50,255,80), "🟢 301-600 studs = MEDIUM", 50},
    {Color3.fromRGB(60,160,255), "🔵 601+ studs = FAR/SAFE", 64},
}

for _, data in pairs(legendData) do
    local dot = Instance.new("Frame", LegendFrame)
    dot.Size = UDim2.new(0, 10, 0, 10)
    dot.Position = UDim2.new(0, 12, 0, data[3])
    dot.BackgroundColor3 = data[1]
    dot.BorderSizePixel = 0
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

    local lbl = Instance.new("TextLabel", LegendFrame)
    lbl.Size = UDim2.new(1, -30, 0, 14)
    lbl.Position = UDim2.new(0, 28, 0, data[3] - 1)
    lbl.BackgroundTransparency = 1
    lbl.Text = data[2]
    lbl.TextSize = 10
    lbl.Font = Enum.Font.Gotham
    lbl.TextColor3 = data[1]
    lbl.TextXAlignment = Enum.TextXAlignment.Left
end

-- Credit
local Credit = Instance.new("TextLabel")
Credit.Size = UDim2.new(1, 0, 0, 22)
Credit.BackgroundTransparency = 1
Credit.Text = "Made for Solara ⚡ | V5 ESP Fixed"
Credit.TextSize = 10
Credit.Font = Enum.Font.Gotham
Credit.TextColor3 = Color3.fromRGB(60, 60, 80)
Credit.LayoutOrder = 99
Credit.Parent = Content

-- ═══════════════════════════════════════════
-- FLY CONTROLS
-- ═══════════════════════════════════════════
Mouse.KeyDown:Connect(function(k)
    k = k:lower()
    if k=="w" then Ctrl.f=1 elseif k=="s" then Ctrl.b=-1 elseif k=="a" then Ctrl.l=-1 elseif k=="d" then Ctrl.r=1 end
end)
Mouse.KeyUp:Connect(function(k)
    k = k:lower()
    if k=="w" then Ctrl.f=0 elseif k=="s" then Ctrl.b=0 elseif k=="a" then Ctrl.l=0 elseif k=="d" then Ctrl.r=0 end
end)

-- ═══════════════════════════════════════════
-- DRAGGABLE
-- ═══════════════════════════════════════════
do
    local d,di,ds,sp
    TitleBar.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then
            d=true; ds=i.Position; sp=MainFrame.Position
            i.Changed:Connect(function() if i.UserInputState==Enum.UserInputState.End then d=false end end)
        end
    end)
    TitleBar.InputChanged:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseMovement then di=i end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if i==di and d then
            local delta=i.Position-ds
            MainFrame.Position=UDim2.new(sp.X.Scale,sp.X.Offset+delta.X,sp.Y.Scale,sp.Y.Offset+delta.Y)
        end
    end)
end

-- Draggable Mini Icon
do
    local d2,di2,ds2,sp2
    MiniIcon.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then
            d2=true; ds2=i.Position; sp2=MiniIcon.Position
            i.Changed:Connect(function() if i.UserInputState==Enum.UserInputState.End then d2=false end end)
        end
    end)
    MiniIcon.InputChanged:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseMovement then di2=i end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if i==di2 and d2 then
            local delta=i.Position-ds2
            MiniIcon.Position=UDim2.new(sp2.X.Scale,sp2.X.Offset+delta.X,sp2.Y.Scale,sp2.Y.Offset+delta.Y)
        end
    end)
end

-- ═══════════════════════════════════════════
-- MINIMIZE
-- ═══════════════════════════════════════════
MinBtn.MouseButton1Click:Connect(function()
    TweenService:Create(MainFrame, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
        Size = UDim2.new(0,0,0,0),
        Position = UDim2.new(MainFrame.Position.X.Scale, MainFrame.Position.X.Offset+170, MainFrame.Position.Y.Scale, MainFrame.Position.Y.Offset+290)
    }):Play()
    task.wait(0.35)
    MainFrame.Visible = false
    MiniIcon.Visible = true
    MiniIcon.Size = UDim2.new(0,0,0,0); MiniIcon.ImageTransparency = 1
    TweenService:Create(MiniIcon, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size=UDim2.new(0,55,0,55), ImageTransparency=0}):Play()
end)

-- RESTORE
local lastClick = 0
MiniIcon.MouseButton1Click:Connect(function()
    if tick()-lastClick < 0.3 then return end
    lastClick = tick()
    TweenService:Create(MiniIcon, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {Size=UDim2.new(0,0,0,0), ImageTransparency=1}):Play()
    task.wait(0.25)
    MiniIcon.Visible = false
    MainFrame.Visible = true
    MainFrame.Size = UDim2.new(0,0,0,0); MainFrame.Position = UDim2.new(0.5,0,0.5,0)
    TweenService:Create(MainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size=UDim2.new(0,340,0,580), Position=UDim2.new(0.5,-170,0.5,-290)}):Play()
end)

-- CLOSE
CloseBtn.MouseButton1Click:Connect(function()
    Flying = false; FlyToggleState = false; ESPEnabled = false; UnlimitedJumpEnabled = false

    if ESPUpdateConn then ESPUpdateConn:Disconnect() end
    if JumpConnection then JumpConnection:Disconnect() end

    for _, player in pairs(Players:GetPlayers()) do RemovePlayerESP(player) end
    for _, conn in pairs(connections) do pcall(function() conn:Disconnect() end) end

    pcall(function()
        Lighting.Brightness=originalValues.Brightness; Lighting.ClockTime=originalValues.ClockTime
        Lighting.FogEnd=originalValues.FogEnd; Lighting.OutdoorAmbient=originalValues.OutdoorAmbient
        LocalPlayer.CameraMaxZoomDistance=originalValues.MaxZoom; LocalPlayer.CameraMinZoomDistance=originalValues.MinZoom
    end)

    if BG then pcall(function() BG:Destroy() end) end
    if BV then pcall(function() BV:Destroy() end) end
    local h = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if h then h.PlatformStand=false end

    TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {Size=UDim2.new(0,0,0,0)}):Play()
    task.wait(0.35)
    ESPGui:Destroy(); ScreenGui:Destroy()
end)

-- HOVER EFFECTS
CloseBtn.MouseEnter:Connect(function() TweenService:Create(CloseBtn, TweenInfo.new(0.2), {BackgroundColor3=Color3.fromRGB(255,70,70)}):Play() end)
CloseBtn.MouseLeave:Connect(function() TweenService:Create(CloseBtn, TweenInfo.new(0.2), {BackgroundColor3=Color3.fromRGB(200,50,50)}):Play() end)
MinBtn.MouseEnter:Connect(function() TweenService:Create(MinBtn, TweenInfo.new(0.2), {BackgroundColor3=Color3.fromRGB(255,210,50)}):Play() end)
MinBtn.MouseLeave:Connect(function() TweenService:Create(MinBtn, TweenInfo.new(0.2), {BackgroundColor3=Color3.fromRGB(255,175,0)}):Play() end)
MiniIcon.MouseEnter:Connect(function() TweenService:Create(MiniIcon, TweenInfo.new(0.2), {BackgroundColor3=Color3.fromRGB(40,40,60)}):Play() end)
MiniIcon.MouseLeave:Connect(function() TweenService:Create(MiniIcon, TweenInfo.new(0.2), {BackgroundColor3=Color3.fromRGB(25,25,40)}):Play() end)

-- OPEN ANIMATION
MainFrame.Size = UDim2.new(0,0,0,0); MainFrame.Position = UDim2.new(0.5,0,0.5,0)
TweenService:Create(MainFrame, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size=UDim2.new(0,340,0,580), Position=UDim2.new(0.5,-170,0.5,-290)}):Play()

-- ═══════════════════════════════════════════
print("══════════════════════════════════════════")
print("⚡ Solara Hub V5 - LOADED!")
print("══════════════════════════════════════════")
print("🌞 Full Bright        ✅")
print("🔭 Unlimited Zoom     ✅")
print("❤️ HP Regen           ✅")
print("✈️ Fly + Speed        ✅")
print("🦘 Unlimited Jump     ✅ NEW!")
print("👁️ ESP Full (FIXED)   ✅ FIXED!")
print("📍 Tracer Lines       ✅")
print("🗺️ Mini Radar         ✅")
print("⚠️ Danger Alert       ✅ Auto")
print("══════════════════════════════════════════")
print("🎨 ESP Color System:")
print("  🔴 0-200 studs = DANGER")
print("  🟡 201-300 studs = WARNING")
print("  🟢 301-600 studs = MEDIUM")
print("  🔵 601+ studs = FAR/SAFE")
print("══════════════════════════════════════════")
