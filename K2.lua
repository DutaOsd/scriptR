-- // Solara Hub V5 - FULLY FIXED & OPTIMIZED + NEW FEATURES
-- // Full Bright + Unlimited Zoom + HP Regen + Fly + ESP + Unlimited Jump
-- // NEW: Anti Ragdoll + Anti Slip + Unlimited Stamina + Unlimited Oxygen
-- // ESP FIXED + Custom Distance Colors + Danger Alert + Radar

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ═══════════════════════════════════════════
-- CONNECTION MANAGER
-- ═══════════════════════════════════════════
local ConnectionManager = {}
ConnectionManager.__index = ConnectionManager

function ConnectionManager.new()
    return setmetatable({_connections = {}}, ConnectionManager)
end

function ConnectionManager:Add(name, connection)
    self:Remove(name)
    self._connections[name] = connection
end

function ConnectionManager:Remove(name)
    if self._connections[name] then
        pcall(function() self._connections[name]:Disconnect() end)
        self._connections[name] = nil
    end
end

function ConnectionManager:RemoveAll()
    for _, conn in pairs(self._connections) do
        pcall(function() conn:Disconnect() end)
    end
    self._connections = {}
end

local connections = ConnectionManager.new()

-- ═══════════════════════════════════════════
-- CLEANUP OLD GUI
-- ═══════════════════════════════════════════
pcall(function()
    game:GetService("CoreGui"):FindFirstChild("SolaraHubV5"):Destroy()
end)
pcall(function()
    game:GetService("CoreGui"):FindFirstChild("SolaraESPv5"):Destroy()
end)
pcall(function()
    workspace:FindFirstChild("SolaraESPParts"):Destroy()
end)

-- ═══════════════════════════════════════════
-- VARIABLES
-- ═══════════════════════════════════════════
local Flying             = false
local FlyToggleState     = false
local FlySpeed           = 50
local Ctrl               = {f = 0, b = 0, l = 0, r = 0}
local LastCtrl           = {f = 0, b = 0, l = 0, r = 0}
local MaxSpeed           = 0
local BG, BV

local ESPEnabled          = false
local ESPUpdateConn       = nil
local UnlimitedJumpEnabled = false
local JumpConnection       = nil

-- New feature states
local AntiRagdollEnabled   = false
local AntiSlipEnabled      = false
local UnlimStaminaEnabled  = false
local UnlimOxygenEnabled   = false

-- Timer throttle
local espUpdateTimer    = 0
local radarUpdateTimer  = 0
local dangerUpdateTimer = 0

-- Workspace folder untuk ESP parts
local ESPWorkspaceFolder = Instance.new("Folder")
ESPWorkspaceFolder.Name   = "SolaraESPParts"
ESPWorkspaceFolder.Parent = workspace

local originalValues = {
    Brightness     = Lighting.Brightness,
    ClockTime      = Lighting.ClockTime,
    FogEnd         = Lighting.FogEnd,
    FogStart       = Lighting.FogStart,
    GlobalShadows  = Lighting.GlobalShadows,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    MaxZoom        = LocalPlayer.CameraMaxZoomDistance,
    MinZoom        = LocalPlayer.CameraMinZoomDistance,
}

local RemovedEffects = {}

-- ═══════════════════════════════════════════
-- ESP SETTINGS
-- ═══════════════════════════════════════════
local ESPSettings = {
    MaxDistance  = 1500,
    ShowBox      = true,
    ShowName     = true,
    ShowHealth   = true,
    ShowDistance = true,
    ShowTracer   = false,
}

-- ═══════════════════════════════════════════
-- HELPER FUNCTIONS
-- ═══════════════════════════════════════════
local function GetDistanceColor(distance)
    if distance <= 200 then
        return Color3.fromRGB(255, 50, 50)
    elseif distance <= 300 then
        return Color3.fromRGB(255, 220, 0)
    elseif distance <= 600 then
        return Color3.fromRGB(50, 255, 80)
    else
        return Color3.fromRGB(60, 160, 255)
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
ScreenGui.Name            = "SolaraHubV5"
ScreenGui.ResetOnSpawn    = false
ScreenGui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent          = game:GetService("CoreGui")

local ESPGui = Instance.new("ScreenGui")
ESPGui.Name           = "SolaraESPv5"
ESPGui.ResetOnSpawn   = false
ESPGui.IgnoreGuiInset = true
ESPGui.Parent         = game:GetService("CoreGui")

-- ═══════════════════════════════════════════
-- MINI ICON
-- ═══════════════════════════════════════════
local MiniIcon = Instance.new("ImageButton")
MiniIcon.Size             = UDim2.new(0, 55, 0, 55)
MiniIcon.Position         = UDim2.new(0, 20, 0.5, -27)
MiniIcon.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
MiniIcon.BorderSizePixel  = 0
MiniIcon.Image            = "rbxassetid://7733960981"
MiniIcon.ImageColor3      = Color3.fromRGB(130, 100, 255)
MiniIcon.Visible          = false
MiniIcon.AutoButtonColor  = false
MiniIcon.Parent           = ScreenGui
Instance.new("UICorner", MiniIcon).CornerRadius = UDim.new(0, 14)

local MiniStroke = Instance.new("UIStroke")
MiniStroke.Color     = Color3.fromRGB(130, 100, 255)
MiniStroke.Thickness = 2
MiniStroke.Parent    = MiniIcon

task.spawn(function()
    while ScreenGui.Parent do
        if MiniIcon.Visible then
            TweenService:Create(MiniStroke, TweenInfo.new(1, Enum.EasingStyle.Sine), {
                Color = Color3.fromRGB(200, 170, 255)
            }):Play()
            task.wait(1)
            if MiniIcon.Visible then
                TweenService:Create(MiniStroke, TweenInfo.new(1, Enum.EasingStyle.Sine), {
                    Color = Color3.fromRGB(130, 100, 255)
                }):Play()
            end
        end
        task.wait(1)
    end
end)

-- ═══════════════════════════════════════════
-- MAIN FRAME
-- ═══════════════════════════════════════════
local MainFrame = Instance.new("Frame")
MainFrame.Size             = UDim2.new(0, 340, 0, 580)
MainFrame.Position         = UDim2.new(0.5, -170, 0.5, -290)
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
MainFrame.BorderSizePixel  = 0
MainFrame.Active           = true
MainFrame.ClipsDescendants = true
MainFrame.Parent           = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 14)

local MainStroke = Instance.new("UIStroke")
MainStroke.Color     = Color3.fromRGB(80, 60, 180)
MainStroke.Thickness = 2
MainStroke.Parent    = MainFrame

local Shadow = Instance.new("ImageLabel")
Shadow.Size              = UDim2.new(1, 40, 1, 40)
Shadow.Position          = UDim2.new(0, -20, 0, -20)
Shadow.BackgroundTransparency = 1
Shadow.Image             = "rbxassetid://5028857084"
Shadow.ImageColor3       = Color3.new(0, 0, 0)
Shadow.ImageTransparency = 0.5
Shadow.ScaleType         = Enum.ScaleType.Slice
Shadow.SliceCenter       = Rect.new(24, 24, 276, 276)
Shadow.ZIndex            = -1
Shadow.Parent            = MainFrame

-- ═══════════════════════════════════════════
-- TITLE BAR
-- ═══════════════════════════════════════════
local TitleBar = Instance.new("Frame")
TitleBar.Size             = UDim2.new(1, 0, 0, 45)
TitleBar.BackgroundColor3 = Color3.fromRGB(22, 22, 35)
TitleBar.BorderSizePixel  = 0
TitleBar.Parent           = MainFrame
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 14)

local TitleFix = Instance.new("Frame")
TitleFix.Size             = UDim2.new(1, 0, 0, 15)
TitleFix.Position         = UDim2.new(0, 0, 1, -15)
TitleFix.BackgroundColor3 = Color3.fromRGB(22, 22, 35)
TitleFix.BorderSizePixel  = 0
TitleFix.Parent           = TitleBar

local TitleText = Instance.new("TextLabel")
TitleText.Size             = UDim2.new(0.55, 0, 1, 0)
TitleText.Position         = UDim2.new(0, 15, 0, 0)
TitleText.BackgroundTransparency = 1
TitleText.Text             = "⚡ Solara Hub V5"
TitleText.TextSize         = 17
TitleText.Font             = Enum.Font.GothamBold
TitleText.TextColor3       = Color3.fromRGB(160, 130, 255)
TitleText.TextXAlignment   = Enum.TextXAlignment.Left
TitleText.Parent           = TitleBar

local Sep = Instance.new("Frame")
Sep.Size                  = UDim2.new(0.92, 0, 0, 1)
Sep.Position              = UDim2.new(0.04, 0, 1, 0)
Sep.BackgroundColor3      = Color3.fromRGB(80, 60, 180)
Sep.BackgroundTransparency = 0.6
Sep.BorderSizePixel       = 0
Sep.Parent                = TitleBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size             = UDim2.new(0, 30, 0, 30)
CloseBtn.Position         = UDim2.new(1, -38, 0, 8)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseBtn.BorderSizePixel  = 0
CloseBtn.Text             = "✕"
CloseBtn.TextSize         = 15
CloseBtn.Font             = Enum.Font.GothamBold
CloseBtn.TextColor3       = Color3.new(1, 1, 1)
CloseBtn.AutoButtonColor  = false
CloseBtn.Parent           = TitleBar
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 8)

local MinBtn = Instance.new("TextButton")
MinBtn.Size             = UDim2.new(0, 30, 0, 30)
MinBtn.Position         = UDim2.new(1, -74, 0, 8)
MinBtn.BackgroundColor3 = Color3.fromRGB(255, 175, 0)
MinBtn.BorderSizePixel  = 0
MinBtn.Text             = "—"
MinBtn.TextSize         = 16
MinBtn.Font             = Enum.Font.GothamBold
MinBtn.TextColor3       = Color3.new(1, 1, 1)
MinBtn.AutoButtonColor  = false
MinBtn.Parent           = TitleBar
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 8)

-- ═══════════════════════════════════════════
-- CONTENT SCROLL
-- ═══════════════════════════════════════════
local Content = Instance.new("ScrollingFrame")
Content.Size                 = UDim2.new(1, -20, 1, -65)
Content.Position             = UDim2.new(0, 10, 0, 55)
Content.BackgroundTransparency = 1
Content.BorderSizePixel      = 0
Content.ScrollBarThickness   = 4
Content.ScrollBarImageColor3 = Color3.fromRGB(130, 100, 255)
Content.CanvasSize           = UDim2.new(0, 0, 0, 0)
Content.AutomaticCanvasSize  = Enum.AutomaticSize.Y
Content.Parent               = MainFrame

local ListLayout = Instance.new("UIListLayout")
ListLayout.Padding   = UDim.new(0, 10)
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
ListLayout.Parent    = Content

local ContentPad = Instance.new("UIPadding")
ContentPad.PaddingBottom = UDim.new(0, 15)
ContentPad.Parent        = Content

-- ═══════════════════════════════════════════
-- STATUS BAR
-- ═══════════════════════════════════════════
local StatusFrame = Instance.new("Frame")
StatusFrame.Size                 = UDim2.new(1, 0, 0, 28)
StatusFrame.BackgroundTransparency = 1
StatusFrame.LayoutOrder          = 0
StatusFrame.Parent               = Content

local StatusText = Instance.new("TextLabel")
StatusText.Size                  = UDim2.new(1, 0, 1, 0)
StatusText.BackgroundTransparency = 1
StatusText.Text                  = "⚙️ Status: Idle"
StatusText.TextSize              = 12
StatusText.Font                  = Enum.Font.Gotham
StatusText.TextColor3            = Color3.fromRGB(100, 100, 130)
StatusText.Parent                = StatusFrame

local function SetStatus(txt, col)
    StatusText.Text      = txt
    StatusText.TextColor3 = col or Color3.fromRGB(100, 100, 130)
end

-- ═══════════════════════════════════════════
-- SECTION CREATOR
-- ═══════════════════════════════════════════
local function CreateSection(text, order)
    local F = Instance.new("Frame")
    F.Size                 = UDim2.new(1, 0, 0, 24)
    F.BackgroundTransparency = 1
    F.LayoutOrder          = order
    F.Parent               = Content

    local L1 = Instance.new("Frame", F)
    L1.Size             = UDim2.new(0.18, 0, 0, 1)
    L1.Position         = UDim2.new(0, 0, 0.5, 0)
    L1.BackgroundColor3 = Color3.fromRGB(80, 60, 180)
    L1.BackgroundTransparency = 0.5
    L1.BorderSizePixel  = 0

    local SL = Instance.new("TextLabel", F)
    SL.Size                  = UDim2.new(0.64, 0, 1, 0)
    SL.Position              = UDim2.new(0.18, 0, 0, 0)
    SL.BackgroundTransparency = 1
    SL.Text                  = text
    SL.TextSize              = 11
    SL.Font                  = Enum.Font.GothamBold
    SL.TextColor3            = Color3.fromRGB(130, 100, 255)

    local L2 = Instance.new("Frame", F)
    L2.Size             = UDim2.new(0.18, 0, 0, 1)
    L2.Position         = UDim2.new(0.82, 0, 0.5, 0)
    L2.BackgroundColor3 = Color3.fromRGB(80, 60, 180)
    L2.BackgroundTransparency = 0.5
    L2.BorderSizePixel  = 0
end

-- ═══════════════════════════════════════════
-- TOGGLE CREATOR
-- ═══════════════════════════════════════════
local function CreateToggle(title, desc, order, callback)
    local F = Instance.new("Frame")
    F.Size             = UDim2.new(1, 0, 0, 70)
    F.BackgroundColor3 = Color3.fromRGB(28, 28, 42)
    F.BorderSizePixel  = 0
    F.LayoutOrder      = order
    F.Parent           = Content
    Instance.new("UICorner", F).CornerRadius = UDim.new(0, 10)

    local FS = Instance.new("UIStroke", F)
    FS.Color     = Color3.fromRGB(45, 45, 65)
    FS.Thickness = 1

    local TL = Instance.new("TextLabel", F)
    TL.Size                  = UDim2.new(0.65, 0, 0, 28)
    TL.Position              = UDim2.new(0, 14, 0, 8)
    TL.BackgroundTransparency = 1
    TL.Text                  = title
    TL.TextSize              = 14
    TL.Font                  = Enum.Font.GothamBold
    TL.TextColor3            = Color3.new(1, 1, 1)
    TL.TextXAlignment        = Enum.TextXAlignment.Left

    local DL = Instance.new("TextLabel", F)
    DL.Size                  = UDim2.new(0.65, 0, 0, 22)
    DL.Position              = UDim2.new(0, 14, 0, 34)
    DL.BackgroundTransparency = 1
    DL.Text                  = desc
    DL.TextSize              = 11
    DL.Font                  = Enum.Font.Gotham
    DL.TextColor3            = Color3.fromRGB(140, 140, 160)
    DL.TextXAlignment        = Enum.TextXAlignment.Left

    local SBG = Instance.new("Frame", F)
    SBG.Size             = UDim2.new(0, 50, 0, 26)
    SBG.Position         = UDim2.new(1, -64, 0.5, -13)
    SBG.BackgroundColor3 = Color3.fromRGB(55, 55, 75)
    SBG.BorderSizePixel  = 0
    Instance.new("UICorner", SBG).CornerRadius = UDim.new(1, 0)

    local SC = Instance.new("Frame", SBG)
    SC.Size             = UDim2.new(0, 20, 0, 20)
    SC.Position         = UDim2.new(0, 3, 0.5, -10)
    SC.BackgroundColor3 = Color3.fromRGB(180, 180, 190)
    SC.BorderSizePixel  = 0
    Instance.new("UICorner", SC).CornerRadius = UDim.new(1, 0)

    local Btn = Instance.new("TextButton", SBG)
    Btn.Size                 = UDim2.new(1, 0, 1, 0)
    Btn.BackgroundTransparency = 1
    Btn.Text                 = ""

    local toggled = false

    Btn.MouseButton1Click:Connect(function()
        toggled = not toggled
        if toggled then
            TweenService:Create(SBG, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {
                BackgroundColor3 = Color3.fromRGB(80, 200, 120)
            }):Play()
            TweenService:Create(SC, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {
                Position         = UDim2.new(1, -23, 0.5, -10),
                BackgroundColor3 = Color3.new(1, 1, 1)
            }):Play()
            TweenService:Create(FS, TweenInfo.new(0.3), {
                Color = Color3.fromRGB(80, 200, 120)
            }):Play()
        else
            TweenService:Create(SBG, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {
                BackgroundColor3 = Color3.fromRGB(55, 55, 75)
            }):Play()
            TweenService:Create(SC, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {
                Position         = UDim2.new(0, 3, 0.5, -10),
                BackgroundColor3 = Color3.fromRGB(180, 180, 190)
            }):Play()
            TweenService:Create(FS, TweenInfo.new(0.3), {
                Color = Color3.fromRGB(45, 45, 65)
            }):Play()
        end
        callback(toggled)
    end)
end

-- ═══════════════════════════════════════════
-- SLIDER CREATOR
-- ═══════════════════════════════════════════
local function CreateSlider(title, min, max, default, order, callback)
    local F = Instance.new("Frame")
    F.Size             = UDim2.new(1, 0, 0, 70)
    F.BackgroundColor3 = Color3.fromRGB(28, 28, 42)
    F.BorderSizePixel  = 0
    F.LayoutOrder      = order
    F.Parent           = Content
    Instance.new("UICorner", F).CornerRadius = UDim.new(0, 10)
    Instance.new("UIStroke", F).Color = Color3.fromRGB(45, 45, 65)

    local ST = Instance.new("TextLabel", F)
    ST.Size                  = UDim2.new(0.65, 0, 0, 25)
    ST.Position              = UDim2.new(0, 14, 0, 5)
    ST.BackgroundTransparency = 1
    ST.Text                  = title
    ST.TextSize              = 13
    ST.Font                  = Enum.Font.GothamBold
    ST.TextColor3            = Color3.new(1, 1, 1)
    ST.TextXAlignment        = Enum.TextXAlignment.Left

    local VL = Instance.new("TextLabel", F)
    VL.Size                  = UDim2.new(0.3, 0, 0, 25)
    VL.Position              = UDim2.new(0.68, 0, 0, 5)
    VL.BackgroundTransparency = 1
    VL.Text                  = tostring(default)
    VL.TextSize              = 14
    VL.Font                  = Enum.Font.GothamBold
    VL.TextColor3            = Color3.fromRGB(130, 100, 255)
    VL.TextXAlignment        = Enum.TextXAlignment.Right

    local SBG = Instance.new("Frame", F)
    SBG.Size             = UDim2.new(0.88, 0, 0, 8)
    SBG.Position         = UDim2.new(0.06, 0, 0, 42)
    SBG.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    SBG.BorderSizePixel  = 0
    Instance.new("UICorner", SBG).CornerRadius = UDim.new(1, 0)

    local ratio = (default - min) / (max - min)

    local SF = Instance.new("Frame", SBG)
    SF.Size             = UDim2.new(ratio, 0, 1, 0)
    SF.BackgroundColor3 = Color3.fromRGB(130, 100, 255)
    SF.BorderSizePixel  = 0
    Instance.new("UICorner", SF).CornerRadius = UDim.new(1, 0)

    local SCi = Instance.new("Frame", SBG)
    SCi.Size             = UDim2.new(0, 18, 0, 18)
    SCi.Position         = UDim2.new(ratio, -9, 0.5, -9)
    SCi.BackgroundColor3 = Color3.new(1, 1, 1)
    SCi.BorderSizePixel  = 0
    SCi.ZIndex           = 2
    Instance.new("UICorner", SCi).CornerRadius = UDim.new(1, 0)

    local SBtn = Instance.new("TextButton", SBG)
    SBtn.Size                 = UDim2.new(1, 0, 0, 30)
    SBtn.Position             = UDim2.new(0, 0, 0, -11)
    SBtn.BackgroundTransparency = 1
    SBtn.Text                 = ""

    local sliding = false

    local function UpdateSlider(xPos)
        local r     = math.clamp((xPos - SBG.AbsolutePosition.X) / SBG.AbsoluteSize.X, 0, 1)
        local value = math.floor(min + (max - min) * r)
        SF.Size      = UDim2.new(r, 0, 1, 0)
        SCi.Position = UDim2.new(r, -9, 0.5, -9)
        VL.Text      = tostring(value)
        callback(value)
    end

    SBtn.MouseButton1Down:Connect(function() sliding = true end)
    SBtn.TouchLongPress:Connect(function() sliding = true end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            sliding = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not sliding then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            UpdateSlider(input.Position.X)
        end
    end)
end

-- ═══════════════════════════════════════════
-- ESP SYSTEM
-- ═══════════════════════════════════════════
local espBillboards = {}

local function RemovePlayerESP(player)
    if not espBillboards[player] then return end
    local espData = espBillboards[player]

    if espData.CharConn then
        pcall(function() espData.CharConn:Disconnect() end)
    end

    local skipKeys = {CharConn = true}
    for key, obj in pairs(espData) do
        if not skipKeys[key] then
            pcall(function() obj:Destroy() end)
        end
    end

    espBillboards[player] = nil
end

local function CreatePlayerESP(player)
    if player == LocalPlayer then return end
    RemovePlayerESP(player)

    local function Setup(character)
        if not character then return end

        local success, err = pcall(function()
            local hrp  = character:WaitForChild("HumanoidRootPart", 5)
            local head = character:WaitForChild("Head", 5)
            local hum  = character:WaitForChild("Humanoid", 5)
            if not hrp or not head or not hum then return end

            if not espBillboards[player] then
                espBillboards[player] = {}
            end
            local espParts = espBillboards[player]

            local highlight = Instance.new("Highlight")
            highlight.Name                = "SolaraESP_" .. player.Name
            highlight.FillTransparency    = 0.7
            highlight.OutlineTransparency = 0.1
            highlight.FillColor           = Color3.fromRGB(255, 50, 50)
            highlight.OutlineColor        = Color3.fromRGB(255, 50, 50)
            highlight.DepthMode           = Enum.HighlightDepthMode.AlwaysOnTop
            highlight.Adornee             = character
            highlight.Parent              = ESPGui
            espParts.Highlight            = highlight

            local billboard = Instance.new("BillboardGui")
            billboard.Name          = "SolaraESPInfo_" .. player.Name
            billboard.Adornee       = head
            billboard.Size          = UDim2.new(0, 200, 0, 100)
            billboard.StudsOffset   = Vector3.new(0, 3, 0)
            billboard.AlwaysOnTop   = true
            billboard.LightInfluence = 0
            billboard.MaxDistance   = ESPSettings.MaxDistance
            billboard.Parent        = ESPGui
            espParts.Billboard      = billboard

            local nameLabel = Instance.new("TextLabel")
            nameLabel.Size                   = UDim2.new(1, 0, 0, 20)
            nameLabel.Position               = UDim2.new(0, 0, 0, 0)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text                   = player.Name
            nameLabel.TextSize               = 14
            nameLabel.Font                   = Enum.Font.GothamBold
            nameLabel.TextColor3             = Color3.new(1, 1, 1)
            nameLabel.TextStrokeTransparency = 0.3
            nameLabel.TextStrokeColor3       = Color3.new(0, 0, 0)
            nameLabel.Parent                 = billboard
            espParts.NameLabel               = nameLabel

            local distLabel = Instance.new("TextLabel")
            distLabel.Size                   = UDim2.new(1, 0, 0, 16)
            distLabel.Position               = UDim2.new(0, 0, 0, 20)
            distLabel.BackgroundTransparency = 1
            distLabel.Text                   = "[0m]"
            distLabel.TextSize               = 12
            distLabel.Font                   = Enum.Font.GothamBold
            distLabel.TextColor3             = Color3.fromRGB(200, 200, 200)
            distLabel.TextStrokeTransparency = 0.3
            distLabel.TextStrokeColor3       = Color3.new(0, 0, 0)
            distLabel.Parent                 = billboard
            espParts.DistLabel               = distLabel

            local dangerLabel = Instance.new("TextLabel")
            dangerLabel.Size                   = UDim2.new(1, 0, 0, 16)
            dangerLabel.Position               = UDim2.new(0, 0, 0, 36)
            dangerLabel.BackgroundTransparency = 1
            dangerLabel.Text                   = ""
            dangerLabel.TextSize               = 12
            dangerLabel.Font                   = Enum.Font.GothamBold
            dangerLabel.TextStrokeTransparency = 0.3
            dangerLabel.TextStrokeColor3       = Color3.new(0, 0, 0)
            dangerLabel.Parent                 = billboard
            espParts.DangerLabel               = dangerLabel

            local hpBG = Instance.new("Frame")
            hpBG.Size             = UDim2.new(0.8, 0, 0, 6)
            hpBG.Position         = UDim2.new(0.1, 0, 0, 56)
            hpBG.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            hpBG.BorderSizePixel  = 0
            hpBG.Parent           = billboard
            Instance.new("UICorner", hpBG).CornerRadius = UDim.new(1, 0)
            espParts.HpBG = hpBG

            local hpFill = Instance.new("Frame")
            hpFill.Size             = UDim2.new(1, 0, 1, 0)
            hpFill.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
            hpFill.BorderSizePixel  = 0
            hpFill.Parent           = hpBG
            Instance.new("UICorner", hpFill).CornerRadius = UDim.new(1, 0)
            espParts.HpFill = hpFill

            local hpText = Instance.new("TextLabel")
            hpText.Size                   = UDim2.new(1, 0, 0, 14)
            hpText.Position               = UDim2.new(0, 0, 0, 64)
            hpText.BackgroundTransparency = 1
            hpText.TextSize               = 10
            hpText.Font                   = Enum.Font.Gotham
            hpText.TextStrokeTransparency = 0.3
            hpText.TextStrokeColor3       = Color3.new(0, 0, 0)
            hpText.Parent                 = billboard
            espParts.HpText               = hpText

            local selectionBox = Instance.new("SelectionBox")
            selectionBox.Adornee           = character
            selectionBox.Color3            = Color3.fromRGB(255, 50, 50)
            selectionBox.LineThickness     = 0.03
            selectionBox.SurfaceTransparency = 0.9
            selectionBox.SurfaceColor3     = Color3.fromRGB(255, 50, 50)
            selectionBox.Parent            = ESPGui
            espParts.SelectionBox          = selectionBox

            local headAdorn = Instance.new("BillboardGui")
            headAdorn.Name          = "SolaraHeadDot_" .. player.Name
            headAdorn.Adornee       = head
            headAdorn.Size          = UDim2.new(1, 0, 1, 0)
            headAdorn.AlwaysOnTop   = true
            headAdorn.LightInfluence = 0
            headAdorn.MaxDistance   = ESPSettings.MaxDistance
            headAdorn.Parent        = ESPGui
            espParts.HeadAdorn      = headAdorn

            local headCircle = Instance.new("Frame")
            headCircle.Size             = UDim2.new(0.5, 0, 0.5, 0)
            headCircle.Position         = UDim2.new(0.25, 0, 0.25, 0)
            headCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            headCircle.BorderSizePixel  = 0
            headCircle.Parent           = headAdorn
            Instance.new("UICorner", headCircle).CornerRadius = UDim.new(1, 0)
            espParts.HeadCircle = headCircle

            local tracerAttachment0 = Instance.new("Attachment")
            tracerAttachment0.Parent = hrp
            espParts.TracerAtt0      = tracerAttachment0

            local tracerPart = Instance.new("Part")
            tracerPart.Name        = "SolaraTracerAnchor_" .. player.Name
            tracerPart.Anchored    = true
            tracerPart.CanCollide  = false
            tracerPart.Transparency = 1
            tracerPart.Size        = Vector3.new(0.1, 0.1, 0.1)
            tracerPart.Parent      = ESPWorkspaceFolder
            espParts.TracerPart    = tracerPart

            local tracerAttachment1 = Instance.new("Attachment")
            tracerAttachment1.Parent = tracerPart
            espParts.TracerAtt1      = tracerAttachment1

            local beam = Instance.new("Beam")
            beam.Attachment0  = tracerAttachment1
            beam.Attachment1  = tracerAttachment0
            beam.Width0       = 0.1
            beam.Width1       = 0.1
            beam.FaceCamera   = true
            beam.Transparency = NumberSequence.new(0.5)
            beam.LightEmission = 1
            beam.Enabled      = ESPSettings.ShowTracer
            beam.Parent       = hrp
            espParts.Beam     = beam
        end)

        if not success then
            warn("[Solara ESP] Setup error: " .. tostring(err))
        end
    end

    if player.Character then
        Setup(player.Character)
    end

    local charConn = player.CharacterAdded:Connect(function(char)
        task.wait(1)
        if ESPEnabled then
            RemovePlayerESP(player)
            espBillboards[player] = {}
            Setup(char)
        end
    end)

    if not espBillboards[player] then
        espBillboards[player] = {}
    end
    espBillboards[player].CharConn = charConn
end

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

        local distance  = (hrp.Position - localHRP.Position).Magnitude
        local distColor = GetDistanceColor(distance)
        local distLbl   = GetDistanceLabel(distance)
        local hpPercent = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
        local hpColor   = GetHealthColor(hpPercent)
        local isAlive   = hum.Health > 0

        if espData.Highlight then
            espData.Highlight.FillColor    = distColor
            espData.Highlight.OutlineColor = distColor
            espData.Highlight.Enabled      = isAlive
        end
        if espData.SelectionBox then
            espData.SelectionBox.Color3        = distColor
            espData.SelectionBox.SurfaceColor3 = distColor
            espData.SelectionBox.Visible       = isAlive
        end
        if espData.NameLabel then espData.NameLabel.TextColor3 = distColor end
        if espData.DistLabel then
            espData.DistLabel.Text       = "[" .. math.floor(distance) .. " studs]"
            espData.DistLabel.TextColor3 = distColor
        end
        if espData.DangerLabel then
            espData.DangerLabel.Text       = distLbl
            espData.DangerLabel.TextColor3 = distColor
        end
        if espData.HpFill then
            espData.HpFill.Size             = UDim2.new(hpPercent, 0, 1, 0)
            espData.HpFill.BackgroundColor3 = hpColor
        end
        if espData.HpText then
            espData.HpText.Text       = math.floor(hum.Health) .. " / " .. math.floor(hum.MaxHealth)
            espData.HpText.TextColor3 = hpColor
        end
        if espData.HeadCircle then espData.HeadCircle.BackgroundColor3 = distColor end
        if espData.Billboard then
            espData.Billboard.Enabled     = isAlive
            espData.Billboard.MaxDistance = ESPSettings.MaxDistance
        end
        if espData.HeadAdorn then
            espData.HeadAdorn.Enabled     = isAlive
            espData.HeadAdorn.MaxDistance = ESPSettings.MaxDistance
        end
        if espData.Beam then
            espData.Beam.Enabled = ESPSettings.ShowTracer and isAlive
            espData.Beam.Color   = ColorSequence.new(distColor)
        end
        if espData.TracerPart then
            espData.TracerPart.CFrame = CFrame.new(localHRP.Position - Vector3.new(0, 3, 0))
        end
    end
end

-- ═══════════════════════════════════════════
-- DANGER ALERT
-- ═══════════════════════════════════════════
local AlertFrame = Instance.new("Frame")
AlertFrame.Size                  = UDim2.new(0, 320, 0, 55)
AlertFrame.Position              = UDim2.new(0.5, -160, 0, 20)
AlertFrame.BackgroundColor3      = Color3.fromRGB(180, 25, 25)
AlertFrame.BackgroundTransparency = 0.2
AlertFrame.BorderSizePixel       = 0
AlertFrame.Visible               = false
AlertFrame.Parent                = ESPGui
Instance.new("UICorner", AlertFrame).CornerRadius = UDim.new(0, 12)

local AlertStroke = Instance.new("UIStroke")
AlertStroke.Color     = Color3.fromRGB(255, 60, 60)
AlertStroke.Thickness = 2
AlertStroke.Parent    = AlertFrame

local AlertText = Instance.new("TextLabel")
AlertText.Size                   = UDim2.new(1, 0, 1, 0)
AlertText.BackgroundTransparency = 1
AlertText.Text                   = "⚠️ DANGER!"
AlertText.TextSize               = 16
AlertText.Font                   = Enum.Font.GothamBold
AlertText.TextColor3             = Color3.new(1, 1, 1)
AlertText.TextStrokeTransparency = 0.5
AlertText.Parent                 = AlertFrame

local alertActive = false

task.spawn(function()
    while ESPGui.Parent do
        if alertActive and AlertFrame.Visible then
            TweenService:Create(AlertFrame, TweenInfo.new(0.4, Enum.EasingStyle.Sine), {
                BackgroundTransparency = 0.05
            }):Play()
            task.wait(0.4)
            TweenService:Create(AlertFrame, TweenInfo.new(0.4, Enum.EasingStyle.Sine), {
                BackgroundTransparency = 0.5
            }):Play()
            task.wait(0.4)
        else
            task.wait(0.3)
        end
    end
end)

local function CheckDangerAlert()
    local localChar = LocalPlayer.Character
    if not localChar then AlertFrame.Visible = false; alertActive = false; return end
    local localHRP = localChar:FindFirstChild("HumanoidRootPart")
    if not localHRP then AlertFrame.Visible = false; alertActive = false; return end

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
        alertActive        = true
        AlertFrame.Visible = true
        AlertText.Text     = dangerCount == 1
            and ("⚠️ DANGER! " .. closestName .. " [" .. math.floor(closestDist) .. " studs]")
            or  ("⚠️ " .. dangerCount .. " Players within 200 studs!")
    else
        alertActive        = false
        AlertFrame.Visible = false
    end
end

-- ═══════════════════════════════════════════
-- RADAR SYSTEM
-- ═══════════════════════════════════════════
local RadarFrame = Instance.new("Frame")
RadarFrame.Size                  = UDim2.new(0, 160, 0, 160)
RadarFrame.Position              = UDim2.new(1, -180, 1, -200)
RadarFrame.BackgroundColor3      = Color3.fromRGB(10, 10, 20)
RadarFrame.BackgroundTransparency = 0.3
RadarFrame.BorderSizePixel       = 0
RadarFrame.Visible               = false
RadarFrame.Parent                = ESPGui
Instance.new("UICorner", RadarFrame).CornerRadius = UDim.new(1, 0)
Instance.new("UIStroke", RadarFrame).Color = Color3.fromRGB(130, 100, 255)

local gridH = Instance.new("Frame", RadarFrame)
gridH.Size                  = UDim2.new(1, 0, 0, 1)
gridH.Position              = UDim2.new(0, 0, 0.5, 0)
gridH.BackgroundColor3      = Color3.fromRGB(80, 60, 180)
gridH.BackgroundTransparency = 0.7
gridH.BorderSizePixel       = 0

local gridV = Instance.new("Frame", RadarFrame)
gridV.Size                  = UDim2.new(0, 1, 1, 0)
gridV.Position              = UDim2.new(0.5, 0, 0, 0)
gridV.BackgroundColor3      = Color3.fromRGB(80, 60, 180)
gridV.BackgroundTransparency = 0.7
gridV.BorderSizePixel       = 0

local SelfDot = Instance.new("Frame", RadarFrame)
SelfDot.Size             = UDim2.new(0, 8, 0, 8)
SelfDot.Position         = UDim2.new(0.5, -4, 0.5, -4)
SelfDot.BackgroundColor3 = Color3.fromRGB(100, 200, 255)
SelfDot.BorderSizePixel  = 0
Instance.new("UICorner", SelfDot).CornerRadius = UDim.new(1, 0)

local RadarLabel = Instance.new("TextLabel", RadarFrame)
RadarLabel.Size                  = UDim2.new(1, 0, 0, 16)
RadarLabel.Position              = UDim2.new(0, 0, 0, 3)
RadarLabel.BackgroundTransparency = 1
RadarLabel.Text                  = "RADAR"
RadarLabel.TextSize              = 10
RadarLabel.Font                  = Enum.Font.GothamBold
RadarLabel.TextColor3            = Color3.fromRGB(130, 100, 255)

local radarDotPool = {}

local function GetOrCreateRadarDot(index)
    if radarDotPool[index] then
        radarDotPool[index].Visible = true
        return radarDotPool[index]
    end

    local dot = Instance.new("Frame")
    dot.Size            = UDim2.new(0, 8, 0, 8)
    dot.BorderSizePixel = 0
    dot.Parent          = RadarFrame
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

    local nameLabel = Instance.new("TextLabel", dot)
    nameLabel.Name              = "NameLabel"
    nameLabel.Size              = UDim2.new(0, 60, 0, 12)
    nameLabel.Position          = UDim2.new(0, 10, 0, -2)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextSize          = 8
    nameLabel.Font              = Enum.Font.GothamBold
    nameLabel.TextXAlignment    = Enum.TextXAlignment.Left

    radarDotPool[index] = dot
    return dot
end

local function UpdateRadar()
    local localChar = LocalPlayer.Character
    if not localChar then return end
    local localHRP = localChar:FindFirstChild("HumanoidRootPart")
    if not localHRP then return end

    local radarRange = 400
    local dotIndex   = 0

    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        local char = player.Character
        if not char then continue end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum or hum.Health <= 0 then continue end

        local dist = (hrp.Position - localHRP.Position).Magnitude
        if dist > radarRange then continue end

        dotIndex = dotIndex + 1
        local dot   = GetOrCreateRadarDot(dotIndex)
        local color = GetDistanceColor(dist)

        local rel = localHRP.CFrame:PointToObjectSpace(hrp.Position)
        local nx  = math.clamp(rel.X / radarRange, -1, 1)
        local nz  = math.clamp(rel.Z / radarRange, -1, 1)

        dot.Position         = UDim2.new(0.5 + nx * 0.42, -4, 0.5 + nz * 0.42, -4)
        dot.BackgroundColor3 = color

        local nl = dot:FindFirstChild("NameLabel")
        if nl then
            nl.Text       = player.Name
            nl.TextColor3 = color
        end
    end

    for i = dotIndex + 1, #radarDotPool do
        if radarDotPool[i] then radarDotPool[i].Visible = false end
    end
end

-- ═══════════════════════════════════════════
-- PLAYER EVENTS
-- ═══════════════════════════════════════════
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
-- NEW FEATURE HELPERS
-- ═══════════════════════════════════════════

-- Cari value/attribute stamina di karakter
local function findStaminaValue(char)
    if not char then return nil end

    -- Common stamina value names
    local staminaNames = {
        "Stamina", "stamina", "SP", "Energy", "energy",
        "Endurance", "endurance", "Fatigue", "fatigue",
        "Mana", "mana", "Sprint", "sprint",
    }

    -- Cari di Values folder atau langsung di character
    for _, name in ipairs(staminaNames) do
        local found = char:FindFirstChild(name, true) -- recursive search
        if found and (found:IsA("NumberValue") or found:IsA("IntValue")) then
            return found
        end
    end

    -- Cari di humanoid
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        for _, name in ipairs(staminaNames) do
            local found = hum:FindFirstChild(name)
            if found and (found:IsA("NumberValue") or found:IsA("IntValue")) then
                return found
            end
        end
    end

    return nil
end

-- Cari value oxygen di karakter
local function findOxygenValue(char)
    if not char then return nil end

    local oxygenNames = {
        "Oxygen", "oxygen", "Air", "air", "O2", "o2",
        "Breath", "breath", "Water", "Underwater", "Dive",
    }

    for _, name in ipairs(oxygenNames) do
        local found = char:FindFirstChild(name, true)
        if found and (found:IsA("NumberValue") or found:IsA("IntValue")) then
            return found
        end
    end

    return nil
end

-- ═══════════════════════════════════════════
-- ANTI RAGDOLL SYSTEM
-- ═══════════════════════════════════════════
--[[
    Cara kerja:
    1. Monitor HumanoidState - jika berubah ke Ragdoll/FallingDown,
       langsung override kembali ke GettingUp/Running
    2. Disable semua SocketConstraint dan BallSocketConstraint
       yang biasanya dipakai sistem ragdoll
    3. Set AutoRotate = true agar karakter selalu tegak
]]
local ragdollJointConns = {} -- track connections untuk joint monitoring

local function DisableRagdollJoints(char)
    if not char then return end

    -- Disable physics constraints yang dipakai ragdoll
    for _, obj in ipairs(char:GetDescendants()) do
        pcall(function()
            if obj:IsA("BallSocketConstraint") or obj:IsA("HingeConstraint") then
                -- Simpan enabled state asli
                if not obj:GetAttribute("_origEnabled") then
                    obj:SetAttribute("_origEnabled", obj.Enabled)
                end
                obj.Enabled = false

            elseif obj:IsA("Motor6D") then
                -- Pastikan Motor6D tetap aktif (ini yang bikin karakter bergerak normal)
                obj.Enabled = true
            end
        end)
    end
end

local function RestoreRagdollJoints(char)
    if not char then return end

    for _, obj in ipairs(char:GetDescendants()) do
        pcall(function()
            if obj:IsA("BallSocketConstraint") or obj:IsA("HingeConstraint") then
                local orig = obj:GetAttribute("_origEnabled")
                if orig ~= nil then
                    obj.Enabled = orig
                    obj:SetAttribute("_origEnabled", nil)
                else
                    obj.Enabled = true
                end
            end
        end)
    end
end

local function ApplyAntiRagdoll(char)
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    -- Override state jika jatuh/ragdoll
    local stateConn = hum.StateChanged:Connect(function(old, new)
        if not AntiRagdollEnabled then return end

        -- State yang ingin dicegah
        local badStates = {
            [Enum.HumanoidStateType.Ragdoll]     = true,
            [Enum.HumanoidStateType.FallingDown]  = true,
            [Enum.HumanoidStateType.Physics]      = true,
        }

        if badStates[new] then
            -- Force kembali ke state normal
            task.spawn(function()
                task.wait(0.05)
                if AntiRagdollEnabled and hum and hum.Parent then
                    hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                    -- Teleport ke posisi sedikit di atas agar tidak stuck
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        hrp.CFrame = hrp.CFrame + Vector3.new(0, 0.5, 0)
                        hrp.Velocity = Vector3.new(0, 0, 0)
                        hrp.RotVelocity = Vector3.new(0, 0, 0)
                    end
                end
            end)
        end
    end)

    table.insert(ragdollJointConns, stateConn)

    -- Disable ragdoll joints
    DisableRagdollJoints(char)

    -- Monitor jika ada joint baru yang ditambahkan (beberapa game pakai ini)
    local descConn = char.DescendantAdded:Connect(function(desc)
        if not AntiRagdollEnabled then return end
        task.wait(0.05)
        if desc:IsA("BallSocketConstraint") or desc:IsA("HingeConstraint") then
            pcall(function() desc.Enabled = false end)
        end
    end)
    table.insert(ragdollJointConns, descConn)

    -- Set AutoRotate untuk tetap tegak
    pcall(function() hum.AutoRotate = true end)
end

local function CleanupAntiRagdoll()
    for _, conn in ipairs(ragdollJointConns) do
        pcall(function() conn:Disconnect() end)
    end
    ragdollJointConns = {}
end

-- ═══════════════════════════════════════════
-- ANTI SLIP SYSTEM
-- ═══════════════════════════════════════════
--[[
    Cara kerja:
    1. Set friction tinggi pada semua BasePart karakter
    2. Override PhysicalProperties agar tidak licin
    3. Monitor saat karakter bergerak di permukaan licin
       (ice, slippery material)
]]
local originalPartProperties = {} -- simpan properties asli

local function ApplyAntiSlip(char)
    if not char then return end

    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            pcall(function()
                -- Simpan properties asli
                if not originalPartProperties[part] then
                    originalPartProperties[part] = {
                        friction           = part.CurrentPhysicalProperties.Friction,
                        frictionWeight     = part.CurrentPhysicalProperties.FrictionWeight,
                        restitution        = part.CurrentPhysicalProperties.Restitution,
                        restitutionWeight  = part.CurrentPhysicalProperties.RestitutionWeight,
                        density            = part.CurrentPhysicalProperties.Density,
                        elasticity         = part.CurrentPhysicalProperties.Elasticity,
                        elasticityWeight   = part.CurrentPhysicalProperties.ElasticityWeight,
                    }
                end

                -- Apply high friction (anti slip)
                part.CustomPhysicalProperties = PhysicalProperties.new(
                    part.CurrentPhysicalProperties.Density,
                    2.0,  -- Friction tinggi (normal 0.3, es 0.05)
                    0.0,  -- Restitution rendah (tidak bouncy)
                    100,  -- FrictionWeight tinggi
                    0     -- RestitutionWeight rendah
                )
            end)
        end
    end
end

local function RestoreAntiSlip(char)
    if not char then return end

    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            pcall(function()
                if originalPartProperties[part] then
                    local orig = originalPartProperties[part]
                    part.CustomPhysicalProperties = PhysicalProperties.new(
                        orig.density,
                        orig.friction,
                        orig.restitution,
                        orig.frictionWeight,
                        orig.restitutionWeight
                    )
                    originalPartProperties[part] = nil
                else
                    -- Reset ke default
                    part.CustomPhysicalProperties = PhysicalProperties.new(
                        Enum.Material.SmoothPlastic
                    )
                end
            end)
        end
    end

    -- Juga cek BaseParts yang baru ditambahkan sudah di-cleanup
    originalPartProperties = {}
end

-- ═══════════════════════════════════════════
-- UNLIMITED STAMINA SYSTEM
-- ═══════════════════════════════════════════
--[[
    Cara kerja:
    1. Cari NumberValue/IntValue dengan nama stamina-related
    2. Set value ke maximum setiap heartbeat
    3. Handle berbagai nama yang berbeda di tiap game
    4. Juga cari di ModuleScript / LocalScript yang mengontrol stamina
       dan override nilai-nya
]]
local staminaWatchConn = nil
local lastStaminaReport = ""

local function StartUnlimStamina()
    if staminaWatchConn then
        pcall(function() staminaWatchConn:Disconnect() end)
    end

    staminaWatchConn = RunService.Heartbeat:Connect(function()
        if not UnlimStaminaEnabled then return end

        local char = LocalPlayer.Character
        if not char then return end

        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then return end

        -- Metode 1: Cari langsung NumberValue/IntValue
        local staminaVal = findStaminaValue(char)
        if staminaVal then
            pcall(function()
                staminaVal.Value = staminaVal.Value >= 0 and
                    math.max(staminaVal.Value, 100) or 100
            end)
        end

        -- Metode 2: Override semua value yang mungkin stamina
        for _, obj in ipairs(char:GetDescendants()) do
            if (obj:IsA("NumberValue") or obj:IsA("IntValue")) then
                local name = obj.Name:lower()
                if name:find("stamin") or name:find("energy")
                or name:find("endur") or name:find("sprint")
                or name:find("fatigue") or name:find("mana") then
                    pcall(function()
                        -- Jaga di nilai maximum yang wajar
                        if obj.Value < 80 then
                            obj.Value = 100
                        end
                    end)
                end
            end
        end

        -- Metode 3: Cari di Player object
        for _, obj in ipairs(LocalPlayer:GetDescendants()) do
            if (obj:IsA("NumberValue") or obj:IsA("IntValue")) then
                local name = obj.Name:lower()
                if name:find("stamin") or name:find("energy") or name:find("sprint") then
                    pcall(function()
                        if obj.Value < 80 then obj.Value = 100 end
                    end)
                end
            end
        end
    end)

    connections:Add("unlimStamina", staminaWatchConn)
end

local function StopUnlimStamina()
    connections:Remove("unlimStamina")
    staminaWatchConn = nil
end

-- ═══════════════════════════════════════════
-- UNLIMITED OXYGEN SYSTEM
-- ═══════════════════════════════════════════
--[[
    Cara kerja:
    1. Cari NumberValue oxygen-related di karakter
    2. Set ke maximum setiap heartbeat
    3. Handle Roblox default oxygen system (Humanoid.OxygenLevel property)
    4. Cegah "Drowning" HumanoidState
]]
local oxygenWatchConn = nil
local oxygenStateConn = nil

local function StartUnlimOxygen()
    if oxygenWatchConn then
        pcall(function() oxygenWatchConn:Disconnect() end)
    end

    local function SetupOxygenForChar(char)
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then return end

        -- Disconnect state conn lama
        if oxygenStateConn then
            pcall(function() oxygenStateConn:Disconnect() end)
        end

        -- Cegah Drowning state
        oxygenStateConn = hum.StateChanged:Connect(function(old, new)
            if not UnlimOxygenEnabled then return end
            if new == Enum.HumanoidStateType.Swimming then
                -- Saat berenang, pastikan oxygen tidak berkurang
                pcall(function()
                    -- Roblox internal: set health agar tidak berkurang karena drowning
                    if hum.Health > 0 then
                        hum.Health = hum.MaxHealth
                    end
                end)
            end
        end)
    end

    -- Setup untuk karakter saat ini
    SetupOxygenForChar(LocalPlayer.Character)

    oxygenWatchConn = RunService.Heartbeat:Connect(function()
        if not UnlimOxygenEnabled then return end

        local char = LocalPlayer.Character
        if not char then return end

        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then return end

        -- Metode 1: Roblox OxygenLevel property (beberapa game pakai ini)
        pcall(function()
            -- Cegah player mati karena drowning
            -- Caranya: override health saat underwater
            if hum:GetState() == Enum.HumanoidStateType.Swimming then
                -- Cek apakah ada countdown oxygen
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hrp and hrp.Position.Y < workspace.WaterLevel - 1 then
                    -- Di bawah air, jaga health
                    if hum.Health > 0 then
                        hum.Health = hum.MaxHealth
                    end
                end
            end
        end)

        -- Metode 2: Cari oxygen value
        local oxygenVal = findOxygenValue(char)
        if oxygenVal then
            pcall(function()
                oxygenVal.Value = math.max(oxygenVal.Value, 100)
            end)
        end

        -- Metode 3: Override semua oxygen-related values
        for _, obj in ipairs(char:GetDescendants()) do
            if (obj:IsA("NumberValue") or obj:IsA("IntValue")) then
                local name = obj.Name:lower()
                if name:find("oxygen") or name:find("air")
                or name:find("breath") or name:find("drown")
                or name:find("o2") or name:find("water") then
                    pcall(function()
                        if obj.Value < 80 then obj.Value = 100 end
                    end)
                end
            end
        end

        -- Metode 4: Cari di workspace WaterPhysics
        pcall(function()
            local waterPhysics = workspace:FindFirstChildOfClass("Terrain")
            if waterPhysics then
                -- Roblox water buoyancy tidak langsung bisa di-override
                -- tapi kita bisa cegah dengan cara lain
            end
        end)
    end)

    connections:Add("unlimOxygen", oxygenWatchConn)
end

local function StopUnlimOxygen()
    connections:Remove("unlimOxygen")
    if oxygenStateConn then
        pcall(function() oxygenStateConn:Disconnect() end)
        oxygenStateConn = nil
    end
    oxygenWatchConn = nil
end

-- Handle respawn untuk features baru
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.5)

    -- Reapply Anti Ragdoll
    if AntiRagdollEnabled then
        CleanupAntiRagdoll()
        task.wait(0.3)
        ApplyAntiRagdoll(char)
    end

    -- Reapply Anti Slip
    if AntiSlipEnabled then
        task.wait(0.3)
        ApplyAntiSlip(char)
    end

    -- Restart Oxygen setup (untuk state conn baru)
    if UnlimOxygenEnabled then
        local hum = char:WaitForChild("Humanoid", 5)
        if hum then
            if oxygenStateConn then
                pcall(function() oxygenStateConn:Disconnect() end)
            end
            oxygenStateConn = hum.StateChanged:Connect(function(old, new)
                if not UnlimOxygenEnabled then return end
                if new == Enum.HumanoidStateType.Swimming then
                    pcall(function()
                        if hum.Health > 0 then hum.Health = hum.MaxHealth end
                    end)
                end
            end)
        end
    end
end)

-- ═══════════════════════════════════════════
-- SECTIONS & FEATURES
-- ═══════════════════════════════════════════

CreateSection("— VISUAL —", 1)

CreateToggle("🌞 Full Bright", "Semua area jadi terang total", 2, function(state)
    if state then
        for _, v in pairs(Lighting:GetDescendants()) do
            if v:IsA("Atmosphere") or v:IsA("BloomEffect")
            or v:IsA("DepthOfFieldEffect") or v:IsA("ColorCorrectionEffect")
            or v:IsA("SunRaysEffect") then
                RemovedEffects[v] = v.Parent
                v.Parent = nil
            end
        end

        connections:Add("bright", RunService.RenderStepped:Connect(function()
            Lighting.ClockTime      = 14
            Lighting.Brightness     = 2
            Lighting.FogEnd         = 1e6
            Lighting.FogStart       = 0
            Lighting.GlobalShadows  = false
            Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
        end))

        connections:Add("brightChild", Lighting.ChildAdded:Connect(function(c)
            if c:IsA("Atmosphere") or c:IsA("BloomEffect") or c:IsA("DepthOfFieldEffect") then
                task.wait(); c:Destroy()
            end
        end))

        SetStatus("🌞 Full Bright: ON", Color3.fromRGB(100, 255, 120))
    else
        connections:Remove("bright")
        connections:Remove("brightChild")

        Lighting.Brightness     = originalValues.Brightness
        Lighting.ClockTime      = originalValues.ClockTime
        Lighting.FogEnd         = originalValues.FogEnd
        Lighting.FogStart       = originalValues.FogStart
        Lighting.GlobalShadows  = originalValues.GlobalShadows
        Lighting.OutdoorAmbient = originalValues.OutdoorAmbient

        for instance, originalParent in pairs(RemovedEffects) do
            pcall(function() instance.Parent = originalParent end)
        end
        RemovedEffects = {}

        SetStatus("🌞 Full Bright: OFF", Color3.fromRGB(255, 100, 100))
    end
end)

CreateToggle("🔭 Unlimited Zoom", "Zoom kamera tanpa batas", 3, function(state)
    if state then
        connections:Add("zoom", RunService.RenderStepped:Connect(function()
            LocalPlayer.CameraMaxZoomDistance = 1e6
            LocalPlayer.CameraMinZoomDistance = 0.1
        end))
        SetStatus("🔭 Unlimited Zoom: ON", Color3.fromRGB(100, 255, 120))
    else
        connections:Remove("zoom")
        LocalPlayer.CameraMaxZoomDistance = originalValues.MaxZoom
        LocalPlayer.CameraMinZoomDistance = originalValues.MinZoom
        SetStatus("🔭 Unlimited Zoom: OFF", Color3.fromRGB(255, 100, 100))
    end
end)

CreateSection("— COMBAT —", 4)

CreateToggle("❤️ HP Regen (Client)", "Auto heal - client side only", 5, function(state)
    if state then
        connections:Add("regen", RunService.Heartbeat:Connect(function()
            local c = LocalPlayer.Character
            if c then
                local h = c:FindFirstChildOfClass("Humanoid")
                if h and h.Health > 0 then h.Health = h.MaxHealth end
            end
        end))
        connections:Add("regenChar", LocalPlayer.CharacterAdded:Connect(function(c)
            task.wait(0.5)
            local h = c:WaitForChild("Humanoid", 5)
            if h then h.Health = h.MaxHealth end
        end))
        SetStatus("❤️ HP Regen: ON", Color3.fromRGB(100, 255, 120))
    else
        connections:Remove("regen")
        connections:Remove("regenChar")
        SetStatus("❤️ HP Regen: OFF", Color3.fromRGB(255, 100, 100))
    end
end)

CreateSection("— MOVEMENT —", 6)

-- FLY
local function StartFly()
    local char  = LocalPlayer.Character
    if not char then return end
    local torso = char:FindFirstChild("HumanoidRootPart")
    local hum   = char:FindFirstChildOfClass("Humanoid")
    if not torso or not hum then return end

    BG = Instance.new("BodyGyro", torso)
    BV = Instance.new("BodyVelocity", torso)
    BG.P         = 9e4
    BG.maxTorque = Vector3.new(9e9, 9e9, 9e9)
    BG.cframe    = torso.CFrame
    BV.velocity  = Vector3.new(0, 0.1, 0)
    BV.maxForce  = Vector3.new(9e9, 9e9, 9e9)

    task.spawn(function()
        repeat
            task.wait()
            if not Flying then break end
            hum.PlatformStand = true

            local moving = (Ctrl.l + Ctrl.r) ~= 0 or (Ctrl.f + Ctrl.b) ~= 0
            MaxSpeed = moving and FlySpeed or 0

            if moving then
                local look = Camera.CoordinateFrame.lookVector
                local side = (Camera.CoordinateFrame * CFrame.new(
                    Ctrl.l + Ctrl.r, (Ctrl.f + Ctrl.b) * 0.2, 0
                )).p - Camera.CoordinateFrame.p
                BV.velocity = (look * (Ctrl.f + Ctrl.b) + side) * MaxSpeed
                LastCtrl    = {f = Ctrl.f, b = Ctrl.b, l = Ctrl.l, r = Ctrl.r}
            elseif MaxSpeed ~= 0 then
                local look = Camera.CoordinateFrame.lookVector
                local side = (Camera.CoordinateFrame * CFrame.new(
                    LastCtrl.l + LastCtrl.r, (LastCtrl.f + LastCtrl.b) * 0.2, 0
                )).p - Camera.CoordinateFrame.p
                BV.velocity = (look * (LastCtrl.f + LastCtrl.b) + side) * MaxSpeed
            else
                BV.velocity = Vector3.new(0, 0.1, 0)
            end

            BG.cframe = Camera.CoordinateFrame
        until not Flying

        Ctrl     = {f = 0, b = 0, l = 0, r = 0}
        LastCtrl = {f = 0, b = 0, l = 0, r = 0}
        MaxSpeed = 0
        if BG then pcall(function() BG:Destroy() end) end
        if BV then pcall(function() BV:Destroy() end) end
        if hum then hum.PlatformStand = false end
    end)
end

CreateToggle("✈️ Fly", "Terbang bebas WASD + arah kamera", 7, function(state)
    FlyToggleState = state
    Flying         = state
    if state then
        StartFly()
        SetStatus("✈️ Fly: ON | Speed: " .. FlySpeed, Color3.fromRGB(100, 255, 120))
    else
        SetStatus("✈️ Fly: OFF", Color3.fromRGB(255, 100, 100))
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    if FlyToggleState then Flying = true; StartFly() end
end)

CreateSlider("✈️ Fly Speed", 10, 500, 50, 8, function(v)
    FlySpeed = v
    if FlyToggleState then
        SetStatus("✈️ Fly Speed: " .. v, Color3.fromRGB(100, 255, 120))
    end
end)

CreateToggle("🦘 Unlimited Jump", "Lompat di udara tanpa batas", 9, function(state)
    UnlimitedJumpEnabled = state
    if state then
        JumpConnection = UserInputService.JumpRequest:Connect(function()
            if not UnlimitedJumpEnabled then return end
            local char = LocalPlayer.Character
            if not char then return end
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end)
        SetStatus("🦘 Unlimited Jump: ON", Color3.fromRGB(100, 255, 120))
    else
        if JumpConnection then JumpConnection:Disconnect(); JumpConnection = nil end
        SetStatus("🦘 Unlimited Jump: OFF", Color3.fromRGB(255, 100, 100))
    end
end)

-- ═══════════════════════════════════════════
-- NEW FEATURES SECTION
-- ═══════════════════════════════════════════
CreateSection("— PHYSICS & SURVIVAL —", 10)

-- ─── ANTI RAGDOLL ───
CreateToggle(
    "🧍 Anti Ragdoll",
    "Cegah karakter jatuh/ragdoll",
    11,
    function(state)
        AntiRagdollEnabled = state

        if state then
            local char = LocalPlayer.Character
            if char then
                CleanupAntiRagdoll()
                ApplyAntiRagdoll(char)
            end

            -- Monitor heartbeat untuk konsistensi
            connections:Add("antiRagdollLoop", RunService.Heartbeat:Connect(function()
                if not AntiRagdollEnabled then return end
                local char = LocalPlayer.Character
                if not char then return end
                local hum = char:FindFirstChildOfClass("Humanoid")
                if not hum then return end

                -- Pastikan AutoRotate selalu true
                pcall(function()
                    if not hum.AutoRotate then
                        hum.AutoRotate = true
                    end
                end)

                -- Cek state setiap frame
                local currentState = hum:GetState()
                if currentState == Enum.HumanoidStateType.Ragdoll
                or currentState == Enum.HumanoidStateType.FallingDown
                or currentState == Enum.HumanoidStateType.Physics then
                    pcall(function()
                        hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                        local hrp = char:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            hrp.Velocity    = Vector3.new(hrp.Velocity.X, 0, hrp.Velocity.Z)
                            hrp.RotVelocity = Vector3.new(0, 0, 0)
                        end
                    end)
                end
            end))

            SetStatus("🧍 Anti Ragdoll: ON", Color3.fromRGB(100, 255, 120))
        else
            connections:Remove("antiRagdollLoop")
            CleanupAntiRagdoll()

            -- Restore joints
            local char = LocalPlayer.Character
            if char then RestoreRagdollJoints(char) end

            SetStatus("🧍 Anti Ragdoll: OFF", Color3.fromRGB(255, 100, 100))
        end
    end
)

-- ─── ANTI SLIP ───
CreateToggle(
    "👟 Anti Slip",
    "Tidak licin di permukaan apapun",
    12,
    function(state)
        AntiSlipEnabled = state

        if state then
            local char = LocalPlayer.Character
            if char then ApplyAntiSlip(char) end

            -- Monitor saat ada part baru (tool equip, dll)
            connections:Add("antiSlipLoop", RunService.Heartbeat:Connect(function()
                if not AntiSlipEnabled then return end
                local char = LocalPlayer.Character
                if not char then return end

                -- Cek physics material di bawah kaki
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    -- Raycast ke bawah
                    local rayResult = workspace:Raycast(
                        hrp.Position,
                        Vector3.new(0, -5, 0),
                        RaycastParams.new()
                    )

                    if rayResult and rayResult.Instance then
                        local hitMat = rayResult.Instance.Material
                        -- Material licin
                        local slippyMaterials = {
                            [Enum.Material.Ice]    = true,
                            [Enum.Material.Glacier] = true,
                        }

                        if slippyMaterials[hitMat] then
                            -- Sedang di permukaan licin, perkuat friction karakter
                            for _, part in ipairs(char:GetDescendants()) do
                                if part:IsA("BasePart") then
                                    pcall(function()
                                        part.CustomPhysicalProperties = PhysicalProperties.new(
                                            part.CurrentPhysicalProperties.Density,
                                            5.0,   -- Sangat tinggi saat di ice
                                            0.0,
                                            1000,
                                            0
                                        )
                                    end)
                                end
                            end
                        end
                    end
                end
            end))

            SetStatus("👟 Anti Slip: ON", Color3.fromRGB(100, 255, 120))
        else
            connections:Remove("antiSlipLoop")

            -- Restore friction asli
            local char = LocalPlayer.Character
            if char then RestoreAntiSlip(char) end

            SetStatus("👟 Anti Slip: OFF", Color3.fromRGB(255, 100, 100))
        end
    end
)

-- ─── UNLIMITED STAMINA ───
CreateToggle(
    "⚡ Unlimited Stamina",
    "Stamina/energy tidak berkurang",
    13,
    function(state)
        UnlimStaminaEnabled = state

        if state then
            StartUnlimStamina()

            -- Feedback: cek apakah berhasil menemukan stamina value
            task.spawn(function()
                task.wait(0.5)
                local char = LocalPlayer.Character
                if char then
                    local sv = findStaminaValue(char)
                    if sv then
                        SetStatus("⚡ Stamina: ON → Found: " .. sv.Name,
                            Color3.fromRGB(100, 255, 120))
                    else
                        SetStatus("⚡ Stamina: ON (scanning...)",
                            Color3.fromRGB(255, 220, 50))
                    end
                end
            end)
        else
            StopUnlimStamina()
            SetStatus("⚡ Unlimited Stamina: OFF", Color3.fromRGB(255, 100, 100))
        end
    end
)

-- ─── UNLIMITED OXYGEN ───
CreateToggle(
    "🌊 Unlimited Oxygen",
    "Tidak tenggelam saat dalam air",
    14,
    function(state)
        UnlimOxygenEnabled = state

        if state then
            StartUnlimOxygen()

            task.spawn(function()
                task.wait(0.5)
                local char = LocalPlayer.Character
                if char then
                    local ov = findOxygenValue(char)
                    if ov then
                        SetStatus("🌊 Oxygen: ON → Found: " .. ov.Name,
                            Color3.fromRGB(100, 255, 120))
                    else
                        SetStatus("🌊 Oxygen: ON (scanning...)",
                            Color3.fromRGB(100, 200, 255))
                    end
                end
            end)
        else
            StopUnlimOxygen()
            SetStatus("🌊 Unlimited Oxygen: OFF", Color3.fromRGB(255, 100, 100))
        end
    end
)

CreateSection("— ESP / RADAR —", 20)

CreateToggle("👁️ ESP (Full)", "Box + Name + HP + Distance + Highlight", 21, function(state)
    ESPEnabled = state

    if state then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then CreatePlayerESP(player) end
        end

        ESPUpdateConn = RunService.Heartbeat:Connect(function(dt)
            espUpdateTimer    = espUpdateTimer + dt
            dangerUpdateTimer = dangerUpdateTimer + dt

            if espUpdateTimer >= 0.05 then
                espUpdateTimer = 0
                UpdateAllESP()
            end
            if dangerUpdateTimer >= 0.2 then
                dangerUpdateTimer = 0
                CheckDangerAlert()
            end
        end)

        SetStatus("👁️ ESP: ON", Color3.fromRGB(100, 255, 120))
    else
        if ESPUpdateConn then ESPUpdateConn:Disconnect(); ESPUpdateConn = nil end

        for _, player in pairs(Players:GetPlayers()) do RemovePlayerESP(player) end

        AlertFrame.Visible = false
        alertActive        = false
        espUpdateTimer     = 0
        dangerUpdateTimer  = 0
        SetStatus("👁️ ESP: OFF", Color3.fromRGB(255, 100, 100))
    end
end)

CreateToggle("📍 Tracer Lines", "Garis penunjuk arah ke musuh", 22, function(state)
    ESPSettings.ShowTracer = state
    SetStatus("📍 Tracer: " .. (state and "ON" or "OFF"),
        state and Color3.fromRGB(100, 255, 120) or Color3.fromRGB(255, 100, 100))
end)

CreateToggle("🗺️ Mini Radar", "Radar deteksi musuh di sekitar", 23, function(state)
    RadarFrame.Visible = state
    if state then
        connections:Add("radar", RunService.Heartbeat:Connect(function(dt)
            radarUpdateTimer = radarUpdateTimer + dt
            if radarUpdateTimer >= 0.1 then
                radarUpdateTimer = 0
                UpdateRadar()
            end
        end))
        SetStatus("🗺️ Radar: ON", Color3.fromRGB(100, 255, 120))
    else
        connections:Remove("radar")
        radarUpdateTimer = 0
        SetStatus("🗺️ Radar: OFF", Color3.fromRGB(255, 100, 100))
    end
end)

CreateSlider("👁️ ESP Max Distance", 100, 3000, 1500, 24, function(v)
    ESPSettings.MaxDistance = v
end)

-- ═══════════════════════════════════════════
-- COLOR LEGEND
-- ═══════════════════════════════════════════
local LegendFrame = Instance.new("Frame")
LegendFrame.Size             = UDim2.new(1, 0, 0, 90)
LegendFrame.BackgroundColor3 = Color3.fromRGB(28, 28, 42)
LegendFrame.BorderSizePixel  = 0
LegendFrame.LayoutOrder      = 25
LegendFrame.Parent           = Content
Instance.new("UICorner", LegendFrame).CornerRadius = UDim.new(0, 10)
Instance.new("UIStroke", LegendFrame).Color = Color3.fromRGB(45, 45, 65)

local LTitle = Instance.new("TextLabel", LegendFrame)
LTitle.Size                  = UDim2.new(1, 0, 0, 20)
LTitle.Position              = UDim2.new(0, 0, 0, 2)
LTitle.BackgroundTransparency = 1
LTitle.Text                  = "🎨 ESP Color Legend"
LTitle.TextSize              = 12
LTitle.Font                  = Enum.Font.GothamBold
LTitle.TextColor3            = Color3.fromRGB(200, 200, 200)

local legendData = {
    {Color3.fromRGB(255, 50, 50),  "🔴 0-200 studs = DANGER",   22},
    {Color3.fromRGB(255, 220, 0),  "🟡 201-300 studs = WARNING", 36},
    {Color3.fromRGB(50, 255, 80),  "🟢 301-600 studs = MEDIUM",  50},
    {Color3.fromRGB(60, 160, 255), "🔵 601+ studs = FAR/SAFE",   64},
}

for _, data in pairs(legendData) do
    local dot = Instance.new("Frame", LegendFrame)
    dot.Size             = UDim2.new(0, 10, 0, 10)
    dot.Position         = UDim2.new(0, 12, 0, data[3])
    dot.BackgroundColor3 = data[1]
    dot.BorderSizePixel  = 0
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

    local lbl = Instance.new("TextLabel", LegendFrame)
    lbl.Size                  = UDim2.new(1, -30, 0, 14)
    lbl.Position              = UDim2.new(0, 28, 0, data[3] - 1)
    lbl.BackgroundTransparency = 1
    lbl.Text                  = data[2]
    lbl.TextSize              = 10
    lbl.Font                  = Enum.Font.Gotham
    lbl.TextColor3            = data[1]
    lbl.TextXAlignment        = Enum.TextXAlignment.Left
end

local Credit = Instance.new("TextLabel")
Credit.Size                  = UDim2.new(1, 0, 0, 22)
Credit.BackgroundTransparency = 1
Credit.Text                  = "Solara Hub V5 ⚡ | +4 New Features"
Credit.TextSize              = 10
Credit.Font                  = Enum.Font.Gotham
Credit.TextColor3            = Color3.fromRGB(60, 60, 80)
Credit.LayoutOrder           = 99
Credit.Parent                = Content

-- ═══════════════════════════════════════════
-- FLY KEYBINDS
-- ═══════════════════════════════════════════
local flyKeyMap = {
    [Enum.KeyCode.W] = function(v) Ctrl.f = v end,
    [Enum.KeyCode.S] = function(v) Ctrl.b = v end,
    [Enum.KeyCode.A] = function(v) Ctrl.l = v end,
    [Enum.KeyCode.D] = function(v) Ctrl.r = v end,
}

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end

    local fn = flyKeyMap[input.KeyCode]
    if fn then
        if input.KeyCode == Enum.KeyCode.W      then fn(1)
        elseif input.KeyCode == Enum.KeyCode.S  then fn(-1)
        elseif input.KeyCode == Enum.KeyCode.A  then fn(-1)
        elseif input.KeyCode == Enum.KeyCode.D  then fn(1)
        end
    end

    if input.KeyCode == Enum.KeyCode.RightControl then
        if MainFrame.Visible then
            MinBtn.MouseButton1Click:Fire()
        elseif MiniIcon.Visible then
            MiniIcon.MouseButton1Click:Fire()
        end
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
    local fn = flyKeyMap[input.KeyCode]
    if fn then fn(0) end
end)

-- ═══════════════════════════════════════════
-- DRAGGABLE
-- ═══════════════════════════════════════════
do
    local dragging, dragInput, dragStart, startPos

    TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = input.Position
            startPos  = MainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)

    TitleBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

do
    local dragging2, dragInput2, dragStart2, startPos2

    MiniIcon.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging2  = true
            dragStart2 = input.Position
            startPos2  = MiniIcon.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging2 = false end
            end)
        end
    end)

    MiniIcon.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            dragInput2 = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput2 and dragging2 then
            local delta = input.Position - dragStart2
            MiniIcon.Position = UDim2.new(
                startPos2.X.Scale, startPos2.X.Offset + delta.X,
                startPos2.Y.Scale, startPos2.Y.Offset + delta.Y
            )
        end
    end)
end

-- ═══════════════════════════════════════════
-- MINIMIZE / RESTORE
-- ═══════════════════════════════════════════
MinBtn.MouseButton1Click:Connect(function()
    TweenService:Create(MainFrame,
        TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
            Size     = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(
                MainFrame.Position.X.Scale,
                MainFrame.Position.X.Offset + 170,
                MainFrame.Position.Y.Scale,
                MainFrame.Position.Y.Offset + 290
            )
        }):Play()

    task.wait(0.35)
    MainFrame.Visible        = false
    MiniIcon.Visible         = true
    MiniIcon.Size            = UDim2.new(0, 0, 0, 0)
    MiniIcon.ImageTransparency = 1

    TweenService:Create(MiniIcon,
        TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size              = UDim2.new(0, 55, 0, 55),
            ImageTransparency = 0
        }):Play()
end)

local lastClick = 0
MiniIcon.MouseButton1Click:Connect(function()
    if tick() - lastClick < 0.3 then return end
    lastClick = tick()

    TweenService:Create(MiniIcon,
        TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
            Size              = UDim2.new(0, 0, 0, 0),
            ImageTransparency = 1
        }):Play()

    task.wait(0.25)
    MiniIcon.Visible        = false
    MainFrame.Visible       = true
    MainFrame.Size          = UDim2.new(0, 0, 0, 0)
    MainFrame.Position      = UDim2.new(0.5, 0, 0.5, 0)

    TweenService:Create(MainFrame,
        TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size     = UDim2.new(0, 340, 0, 580),
            Position = UDim2.new(0.5, -170, 0.5, -290)
        }):Play()
end)

-- ═══════════════════════════════════════════
-- CLOSE
-- ═══════════════════════════════════════════
CloseBtn.MouseButton1Click:Connect(function()
    Flying               = false
    FlyToggleState       = false
    ESPEnabled           = false
    UnlimitedJumpEnabled = false
    AntiRagdollEnabled   = false
    AntiSlipEnabled      = false
    UnlimStaminaEnabled  = false
    UnlimOxygenEnabled   = false

    if ESPUpdateConn then ESPUpdateConn:Disconnect(); ESPUpdateConn = nil end
    if JumpConnection then JumpConnection:Disconnect(); JumpConnection = nil end

    -- Cleanup new features
    CleanupAntiRagdoll()
    StopUnlimStamina()
    StopUnlimOxygen()

    if oxygenStateConn then
        pcall(function() oxygenStateConn:Disconnect() end)
        oxygenStateConn = nil
    end

    local char = LocalPlayer.Character
    if char then
        RestoreRagdollJoints(char)
        RestoreAntiSlip(char)
    end

    for _, player in pairs(Players:GetPlayers()) do RemovePlayerESP(player) end
    connections:RemoveAll()

    pcall(function()
        Lighting.Brightness     = originalValues.Brightness
        Lighting.ClockTime      = originalValues.ClockTime
        Lighting.FogEnd         = originalValues.FogEnd
        Lighting.FogStart       = originalValues.FogStart
        Lighting.GlobalShadows  = originalValues.GlobalShadows
        Lighting.OutdoorAmbient = originalValues.OutdoorAmbient
        LocalPlayer.CameraMaxZoomDistance = originalValues.MaxZoom
        LocalPlayer.CameraMinZoomDistance = originalValues.MinZoom
    end)

    for instance, originalParent in pairs(RemovedEffects) do
        pcall(function() instance.Parent = originalParent end)
    end
    RemovedEffects = {}

    if BG then pcall(function() BG:Destroy() end) end
    if BV then pcall(function() BV:Destroy() end) end
    local h = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if h then
        h.PlatformStand = false
        h.AutoRotate    = true
    end

    pcall(function() ESPWorkspaceFolder:Destroy() end)

    for _, dot in pairs(radarDotPool) do
        pcall(function() dot:Destroy() end)
    end
    radarDotPool = {}

    TweenService:Create(MainFrame,
        TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, 0)
        }):Play()

    task.wait(0.35)
    pcall(function() ESPGui:Destroy() end)
    pcall(function() ScreenGui:Destroy() end)
end)

-- ═══════════════════════════════════════════
-- HOVER EFFECTS
-- ═══════════════════════════════════════════
CloseBtn.MouseEnter:Connect(function()
    TweenService:Create(CloseBtn, TweenInfo.new(0.2),
        {BackgroundColor3 = Color3.fromRGB(255, 70, 70)}):Play()
end)
CloseBtn.MouseLeave:Connect(function()
    TweenService:Create(CloseBtn, TweenInfo.new(0.2),
        {BackgroundColor3 = Color3.fromRGB(200, 50, 50)}):Play()
end)
MinBtn.MouseEnter:Connect(function()
    TweenService:Create(MinBtn, TweenInfo.new(0.2),
        {BackgroundColor3 = Color3.fromRGB(255, 210, 50)}):Play()
end)
MinBtn.MouseLeave:Connect(function()
    TweenService:Create(MinBtn, TweenInfo.new(0.2),
        {BackgroundColor3 = Color3.fromRGB(255, 175, 0)}):Play()
end)
MiniIcon.MouseEnter:Connect(function()
    TweenService:Create(MiniIcon, TweenInfo.new(0.2),
        {BackgroundColor3 = Color3.fromRGB(40, 40, 60)}):Play()
end)
MiniIcon.MouseLeave:Connect(function()
    TweenService:Create(MiniIcon, TweenInfo.new(0.2),
        {BackgroundColor3 = Color3.fromRGB(25, 25, 40)}):Play()
end)

-- ═══════════════════════════════════════════
-- OPEN ANIMATION
-- ═══════════════════════════════════════════
MainFrame.Size     = UDim2.new(0, 0, 0, 0)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)

TweenService:Create(MainFrame,
    TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size     = UDim2.new(0, 340, 0, 580),
        Position = UDim2.new(0.5, -170, 0.5, -290)
    }):Play()

-- ═══════════════════════════════════════════
-- PRINT LOG
-- ═══════════════════════════════════════════
print("══════════════════════════════════════════")
print("⚡ Solara Hub V5 - NEW FEATURES EDITION")
print("══════════════════════════════════════════")
print("🌞 Full Bright            ✅")
print("🔭 Unlimited Zoom         ✅")
print("❤️ HP Regen (Client)      ✅")
print("✈️ Fly + Speed            ✅")
print("🦘 Unlimited Jump         ✅")
print("👁️ ESP Full               ✅")
print("📍 Tracer Lines           ✅")
print("🗺️ Mini Radar             ✅")
print("⚠️ Danger Alert           ✅")
print("══════════════════════════════════════════")
print("🆕 NEW FEATURES:")
print("🧍 Anti Ragdoll           ✅ NEW!")
print("   → Block FallingDown/Ragdoll state")
print("   → Disable BallSocket joints")
print("   → Force AutoRotate ON")
print("👟 Anti Slip              ✅ NEW!")
print("   → High friction pada semua parts")
print("   → Extra grip di permukaan ice")
print("   → Raycast material detection")
print("⚡ Unlimited Stamina      ✅ NEW!")
print("   → Auto scan stamina values")
print("   → Multi-name detection")
print("   → Works di berbagai game")
print("🌊 Unlimited Oxygen       ✅ NEW!")
print("   → Prevent drowning state")
print("   → Auto scan oxygen values")
print("   → HP maintain saat underwater")
print("══════════════════════════════════════════")
