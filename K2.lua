-- // Solara Hub V5 - MOBILE READY + FIXED PHYSICS
-- // Anti Ragdoll FIXED: Block ALL ragdoll methods
-- // Anti Slip FIXED: Slope protection + velocity correction
-- // Mobile: Touch controls + responsive UI + drag support

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ═══════════════════════════════════════════
-- MOBILE DETECTION (Improved)
-- ═══════════════════════════════════════════
local isMobile = (function()
    if GuiService:IsTenFootInterface() then return false end
    local touch    = UserInputService.TouchEnabled
    local keyboard = UserInputService.KeyboardEnabled
    local vp       = Camera.ViewportSize
    return touch and (not keyboard or vp.X < 1200)
end)()

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
pcall(function() game:GetService("CoreGui"):FindFirstChild("SolaraHubV5"):Destroy() end)
pcall(function() game:GetService("CoreGui"):FindFirstChild("SolaraESPv5"):Destroy() end)
pcall(function() workspace:FindFirstChild("SolaraESPParts"):Destroy() end)

-- ═══════════════════════════════════════════
-- VARIABLES
-- ═══════════════════════════════════════════
local Flying              = false
local FlyToggleState      = false
local FlySpeed            = 50
local Ctrl                = {f = 0, b = 0, l = 0, r = 0}
local LastCtrl            = {f = 0, b = 0, l = 0, r = 0}
local MaxSpeed            = 0
local BG, BV

local ESPEnabled           = false
local ESPUpdateConn        = nil
local UnlimitedJumpEnabled = false
local JumpConnection       = nil

local AntiRagdollEnabled   = false
local AntiSlipEnabled      = false
local UnlimStaminaEnabled  = false
local UnlimOxygenEnabled   = false

local espUpdateTimer    = 0
local radarUpdateTimer  = 0
local dangerUpdateTimer = 0

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

local ESPSettings = {
    MaxDistance = 1500,
    ShowBox     = true,
    ShowName    = true,
    ShowHealth  = true,
    ShowDistance = true,
    ShowTracer  = false,
}

-- Anti Ragdoll state
local ragdollConns         = {}
local disabledStates       = {}
local antiRagdollBodyMovers = {}

-- Anti Slip state
local originalPartProps    = {}
local antiSlipBodyForce    = nil
local lastGroundNormal     = Vector3.new(0, 1, 0)

-- ═══════════════════════════════════════════
-- HELPER FUNCTIONS
-- ═══════════════════════════════════════════
local function GetDistanceColor(distance)
    if distance <= 200 then return Color3.fromRGB(255, 50, 50)
    elseif distance <= 300 then return Color3.fromRGB(255, 220, 0)
    elseif distance <= 600 then return Color3.fromRGB(50, 255, 80)
    else return Color3.fromRGB(60, 160, 255) end
end

local function GetDistanceLabel(distance)
    if distance <= 200 then return "⚠️ DANGER"
    elseif distance <= 300 then return "⚡ WARNING"
    elseif distance <= 600 then return "🟢 MEDIUM"
    else return "🔵 FAR" end
end

local function GetHealthColor(percent)
    return Color3.fromRGB(math.floor(255 * (1 - percent)), math.floor(255 * percent), 0)
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
-- MINI ICON (Mobile Responsive)
-- ═══════════════════════════════════════════
local MiniIcon = Instance.new("ImageButton")
MiniIcon.Size             = isMobile and UDim2.new(0, 60, 0, 60) or UDim2.new(0, 55, 0, 55)
MiniIcon.Position         = isMobile and UDim2.new(0.85, 0, 0.15, 0) or UDim2.new(0, 20, 0.5, -27)
MiniIcon.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
MiniIcon.BorderSizePixel  = 0
MiniIcon.Image            = "rbxassetid://7733960981"
MiniIcon.ImageColor3      = Color3.fromRGB(130, 100, 255)
MiniIcon.Visible          = false
MiniIcon.AutoButtonColor  = false
MiniIcon.Parent           = ScreenGui
Instance.new("UICorner", MiniIcon).CornerRadius = UDim.new(0, 14)

local MiniStroke = Instance.new("UIStroke", MiniIcon)
MiniStroke.Color     = Color3.fromRGB(130, 100, 255)
MiniStroke.Thickness = 2

task.spawn(function()
    while ScreenGui.Parent do
        if MiniIcon.Visible then
            TweenService:Create(MiniStroke, TweenInfo.new(1, Enum.EasingStyle.Sine),
                {Color = Color3.fromRGB(200, 170, 255)}):Play()
            task.wait(1)
            if MiniIcon.Visible then
                TweenService:Create(MiniStroke, TweenInfo.new(1, Enum.EasingStyle.Sine),
                    {Color = Color3.fromRGB(130, 100, 255)}):Play()
            end
        end
        task.wait(1)
    end
end)

-- ═══════════════════════════════════════════
-- MAIN FRAME (Mobile Responsive)
-- ═══════════════════════════════════════════
local MainFrame = Instance.new("Frame")
if isMobile then
    MainFrame.Size     = UDim2.new(0.92, 0, 0.82, 0)
    MainFrame.Position = UDim2.new(0.04, 0, 0.09, 0)
else
    MainFrame.Size     = UDim2.new(0, 340, 0, 580)
    MainFrame.Position = UDim2.new(0.5, -170, 0.5, -290)
end
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
MainFrame.BorderSizePixel  = 0
MainFrame.Active           = true
MainFrame.ClipsDescendants = true
MainFrame.Parent           = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 14)

local MainStroke = Instance.new("UIStroke", MainFrame)
MainStroke.Color     = Color3.fromRGB(80, 60, 180)
MainStroke.Thickness = 2

local Shadow = Instance.new("ImageLabel")
Shadow.Size               = UDim2.new(1, 40, 1, 40)
Shadow.Position            = UDim2.new(0, -20, 0, -20)
Shadow.BackgroundTransparency = 1
Shadow.Image              = "rbxassetid://5028857084"
Shadow.ImageColor3        = Color3.new(0, 0, 0)
Shadow.ImageTransparency  = 0.5
Shadow.ScaleType          = Enum.ScaleType.Slice
Shadow.SliceCenter        = Rect.new(24, 24, 276, 276)
Shadow.ZIndex             = -1
Shadow.Parent             = MainFrame

-- ═══════════════════════════════════════════
-- TITLE BAR (Mobile Touch Drag)
-- ═══════════════════════════════════════════
local TitleH   = isMobile and 52 or 45
local TitleBar = Instance.new("Frame")
TitleBar.Size             = UDim2.new(1, 0, 0, TitleH)
TitleBar.BackgroundColor3 = Color3.fromRGB(22, 22, 35)
TitleBar.BorderSizePixel  = 0
TitleBar.Parent           = MainFrame
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 14)

local TitleFix = Instance.new("Frame", TitleBar)
TitleFix.Size             = UDim2.new(1, 0, 0, 15)
TitleFix.Position         = UDim2.new(0, 0, 1, -15)
TitleFix.BackgroundColor3 = Color3.fromRGB(22, 22, 35)
TitleFix.BorderSizePixel  = 0

local TitleText = Instance.new("TextLabel", TitleBar)
TitleText.Size                = UDim2.new(0.55, 0, 1, 0)
TitleText.Position            = UDim2.new(0, 15, 0, 0)
TitleText.BackgroundTransparency = 1
TitleText.Text                = "⚡ Solara Hub V5"
TitleText.TextSize            = isMobile and 18 or 17
TitleText.Font                = Enum.Font.GothamBold
TitleText.TextColor3          = Color3.fromRGB(160, 130, 255)
TitleText.TextXAlignment      = Enum.TextXAlignment.Left

local Sep = Instance.new("Frame", TitleBar)
Sep.Size                  = UDim2.new(0.92, 0, 0, 1)
Sep.Position              = UDim2.new(0.04, 0, 1, 0)
Sep.BackgroundColor3      = Color3.fromRGB(80, 60, 180)
Sep.BackgroundTransparency = 0.6
Sep.BorderSizePixel       = 0

-- Buttons (larger for mobile touch)
local btnSize = isMobile and UDim2.new(0, 38, 0, 38) or UDim2.new(0, 30, 0, 30)

local CloseBtn = Instance.new("TextButton", TitleBar)
CloseBtn.Size             = btnSize
CloseBtn.Position         = isMobile and UDim2.new(1, -46, 0.5, -19) or UDim2.new(1, -38, 0, 8)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseBtn.BorderSizePixel  = 0
CloseBtn.Text             = "✕"
CloseBtn.TextSize         = isMobile and 18 or 15
CloseBtn.Font             = Enum.Font.GothamBold
CloseBtn.TextColor3       = Color3.new(1, 1, 1)
CloseBtn.AutoButtonColor  = false
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 8)

local MinBtn = Instance.new("TextButton", TitleBar)
MinBtn.Size             = btnSize
MinBtn.Position         = isMobile and UDim2.new(1, -92, 0.5, -19) or UDim2.new(1, -74, 0, 8)
MinBtn.BackgroundColor3 = Color3.fromRGB(255, 175, 0)
MinBtn.BorderSizePixel  = 0
MinBtn.Text             = "—"
MinBtn.TextSize         = isMobile and 20 or 16
MinBtn.Font             = Enum.Font.GothamBold
MinBtn.TextColor3       = Color3.new(1, 1, 1)
MinBtn.AutoButtonColor  = false
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 8)

-- ═══════════════════════════════════════════
-- CONTENT SCROLL (Mobile: larger items)
-- ═══════════════════════════════════════════
local Content = Instance.new("ScrollingFrame")
Content.Size                 = UDim2.new(1, -16, 1, -(TitleH + 18))
Content.Position             = UDim2.new(0, 8, 0, TitleH + 10)
Content.BackgroundTransparency = 1
Content.BorderSizePixel      = 0
Content.ScrollBarThickness   = isMobile and 6 or 4
Content.ScrollBarImageColor3 = Color3.fromRGB(130, 100, 255)
Content.CanvasSize           = UDim2.new(0, 0, 0, 0)
Content.AutomaticCanvasSize  = Enum.AutomaticSize.Y
Content.Parent               = MainFrame

local ListLayout = Instance.new("UIListLayout", Content)
ListLayout.Padding   = UDim.new(0, isMobile and 8 or 10)
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder

local ContentPad = Instance.new("UIPadding", Content)
ContentPad.PaddingBottom = UDim.new(0, 15)

-- ═══════════════════════════════════════════
-- STATUS BAR
-- ═══════════════════════════════════════════
local StatusFrame = Instance.new("Frame")
StatusFrame.Size                  = UDim2.new(1, 0, 0, isMobile and 32 or 28)
StatusFrame.BackgroundTransparency = 1
StatusFrame.LayoutOrder           = 0
StatusFrame.Parent                = Content

local StatusText = Instance.new("TextLabel", StatusFrame)
StatusText.Size                  = UDim2.new(1, 0, 1, 0)
StatusText.BackgroundTransparency = 1
StatusText.Text                  = "⚙️ Status: Idle"
StatusText.TextSize              = isMobile and 13 or 12
StatusText.Font                  = Enum.Font.Gotham
StatusText.TextColor3            = Color3.fromRGB(100, 100, 130)

local function SetStatus(txt, col)
    StatusText.Text       = txt
    StatusText.TextColor3 = col or Color3.fromRGB(100, 100, 130)
end

-- ═══════════════════════════════════════════
-- SECTION CREATOR (Mobile scaled)
-- ═══════════════════════════════════════════
local function CreateSection(text, order)
    local F = Instance.new("Frame")
    F.Size                  = UDim2.new(1, 0, 0, isMobile and 28 or 24)
    F.BackgroundTransparency = 1
    F.LayoutOrder           = order
    F.Parent                = Content

    local L1 = Instance.new("Frame", F)
    L1.Size                  = UDim2.new(0.15, 0, 0, 1)
    L1.Position              = UDim2.new(0, 0, 0.5, 0)
    L1.BackgroundColor3      = Color3.fromRGB(80, 60, 180)
    L1.BackgroundTransparency = 0.5
    L1.BorderSizePixel       = 0

    local SL = Instance.new("TextLabel", F)
    SL.Size                  = UDim2.new(0.7, 0, 1, 0)
    SL.Position              = UDim2.new(0.15, 0, 0, 0)
    SL.BackgroundTransparency = 1
    SL.Text                  = text
    SL.TextSize              = isMobile and 13 or 11
    SL.Font                  = Enum.Font.GothamBold
    SL.TextColor3            = Color3.fromRGB(130, 100, 255)

    local L2 = Instance.new("Frame", F)
    L2.Size                  = UDim2.new(0.15, 0, 0, 1)
    L2.Position              = UDim2.new(0.85, 0, 0.5, 0)
    L2.BackgroundColor3      = Color3.fromRGB(80, 60, 180)
    L2.BackgroundTransparency = 0.5
    L2.BorderSizePixel       = 0
end

-- ═══════════════════════════════════════════
-- TOGGLE CREATOR (Mobile: larger touch targets)
-- ═══════════════════════════════════════════
local function CreateToggle(title, desc, order, callback)
    local toggleH = isMobile and 80 or 70

    local F = Instance.new("Frame")
    F.Size             = UDim2.new(1, 0, 0, toggleH)
    F.BackgroundColor3 = Color3.fromRGB(28, 28, 42)
    F.BorderSizePixel  = 0
    F.LayoutOrder      = order
    F.Parent           = Content
    Instance.new("UICorner", F).CornerRadius = UDim.new(0, 10)

    local FS = Instance.new("UIStroke", F)
    FS.Color     = Color3.fromRGB(45, 45, 65)
    FS.Thickness = 1

    local TL = Instance.new("TextLabel", F)
    TL.Size                  = UDim2.new(0.62, 0, 0, 28)
    TL.Position              = UDim2.new(0, 14, 0, isMobile and 10 or 8)
    TL.BackgroundTransparency = 1
    TL.Text                  = title
    TL.TextSize              = isMobile and 15 or 14
    TL.Font                  = Enum.Font.GothamBold
    TL.TextColor3            = Color3.new(1, 1, 1)
    TL.TextXAlignment        = Enum.TextXAlignment.Left

    local DL = Instance.new("TextLabel", F)
    DL.Size                  = UDim2.new(0.62, 0, 0, 22)
    DL.Position              = UDim2.new(0, 14, 0, isMobile and 38 or 34)
    DL.BackgroundTransparency = 1
    DL.Text                  = desc
    DL.TextSize              = isMobile and 12 or 11
    DL.Font                  = Enum.Font.Gotham
    DL.TextColor3            = Color3.fromRGB(140, 140, 160)
    DL.TextXAlignment        = Enum.TextXAlignment.Left

    -- Larger switch for mobile
    local switchW = isMobile and 56 or 50
    local switchH = isMobile and 30 or 26
    local circleS = isMobile and 24 or 20

    local SBG = Instance.new("Frame", F)
    SBG.Size             = UDim2.new(0, switchW, 0, switchH)
    SBG.Position         = UDim2.new(1, -(switchW + 14), 0.5, -(switchH / 2))
    SBG.BackgroundColor3 = Color3.fromRGB(55, 55, 75)
    SBG.BorderSizePixel  = 0
    Instance.new("UICorner", SBG).CornerRadius = UDim.new(1, 0)

    local SC = Instance.new("Frame", SBG)
    SC.Size             = UDim2.new(0, circleS, 0, circleS)
    SC.Position         = UDim2.new(0, 3, 0.5, -(circleS / 2))
    SC.BackgroundColor3 = Color3.fromRGB(180, 180, 190)
    SC.BorderSizePixel  = 0
    Instance.new("UICorner", SC).CornerRadius = UDim.new(1, 0)

    local Btn = Instance.new("TextButton", SBG)
    Btn.Size                  = UDim2.new(1, 0, 1, 0)
    Btn.BackgroundTransparency = 1
    Btn.Text                  = ""

    local toggled = false

    Btn.MouseButton1Click:Connect(function()
        toggled = not toggled
        if toggled then
            TweenService:Create(SBG, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {
                BackgroundColor3 = Color3.fromRGB(80, 200, 120)
            }):Play()
            TweenService:Create(SC, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {
                Position         = UDim2.new(1, -(circleS + 3), 0.5, -(circleS / 2)),
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
                Position         = UDim2.new(0, 3, 0.5, -(circleS / 2)),
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
-- SLIDER CREATOR (Mobile: Touch + larger)
-- ═══════════════════════════════════════════
local function CreateSlider(title, min, max, default, order, callback)
    local sliderH = isMobile and 78 or 70

    local F = Instance.new("Frame")
    F.Size             = UDim2.new(1, 0, 0, sliderH)
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
    ST.TextSize              = isMobile and 14 or 13
    ST.Font                  = Enum.Font.GothamBold
    ST.TextColor3            = Color3.new(1, 1, 1)
    ST.TextXAlignment        = Enum.TextXAlignment.Left

    local VL = Instance.new("TextLabel", F)
    VL.Size                  = UDim2.new(0.3, 0, 0, 25)
    VL.Position              = UDim2.new(0.68, 0, 0, 5)
    VL.BackgroundTransparency = 1
    VL.Text                  = tostring(default)
    VL.TextSize              = isMobile and 15 or 14
    VL.Font                  = Enum.Font.GothamBold
    VL.TextColor3            = Color3.fromRGB(130, 100, 255)
    VL.TextXAlignment        = Enum.TextXAlignment.Right

    local trackH = isMobile and 12 or 8

    local SBG = Instance.new("Frame", F)
    SBG.Size             = UDim2.new(0.88, 0, 0, trackH)
    SBG.Position         = UDim2.new(0.06, 0, 0, isMobile and 46 or 42)
    SBG.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    SBG.BorderSizePixel  = 0
    Instance.new("UICorner", SBG).CornerRadius = UDim.new(1, 0)

    local ratio = (default - min) / (max - min)

    local SF = Instance.new("Frame", SBG)
    SF.Size             = UDim2.new(ratio, 0, 1, 0)
    SF.BackgroundColor3 = Color3.fromRGB(130, 100, 255)
    SF.BorderSizePixel  = 0
    Instance.new("UICorner", SF).CornerRadius = UDim.new(1, 0)

    local knobS = isMobile and 24 or 18

    local SCi = Instance.new("Frame", SBG)
    SCi.Size             = UDim2.new(0, knobS, 0, knobS)
    SCi.Position         = UDim2.new(ratio, -(knobS/2), 0.5, -(knobS/2))
    SCi.BackgroundColor3 = Color3.new(1, 1, 1)
    SCi.BorderSizePixel  = 0
    SCi.ZIndex           = 2
    Instance.new("UICorner", SCi).CornerRadius = UDim.new(1, 0)

    -- Larger hit area for mobile
    local SBtn = Instance.new("TextButton", SBG)
    SBtn.Size                  = UDim2.new(1, 10, 0, isMobile and 44 or 30)
    SBtn.Position              = UDim2.new(0, -5, 0.5, -(isMobile and 22 or 15))
    SBtn.BackgroundTransparency = 1
    SBtn.Text                  = ""

    local sliding = false

    local function UpdateSlider(xPos)
        local r     = math.clamp((xPos - SBG.AbsolutePosition.X) / SBG.AbsoluteSize.X, 0, 1)
        local value = math.floor(min + (max - min) * r)
        SF.Size      = UDim2.new(r, 0, 1, 0)
        SCi.Position = UDim2.new(r, -(knobS/2), 0.5, -(knobS/2))
        VL.Text      = tostring(value)
        callback(value)
    end

    SBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            sliding = true
            UpdateSlider(input.Position.X)
        end
    end)

    SBtn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            sliding = false
        end
    end)

    connections:Add("Slider_"..title, UserInputService.InputChanged:Connect(function(input)
        if not sliding then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            UpdateSlider(input.Position.X)
        end
    end))
end

-- ═══════════════════════════════════════════
-- ANTI RAGDOLL V2 (COMPLETELY REWRITTEN)
-- Now blocks ALL ragdoll methods:
-- 1. HumanoidState blocking
-- 2. Joint/constraint disabling
-- 3. BodyMover cleanup
-- 4. Velocity reset
-- 5. PlatformStand prevention
-- ═══════════════════════════════════════════
local BLOCKED_STATES = {
    Enum.HumanoidStateType.Ragdoll,
    Enum.HumanoidStateType.FallingDown,
    Enum.HumanoidStateType.Physics,
}

local function BlockRagdollStates(hum)
    if not hum then return end

    -- Method 1: Disable ragdoll states entirely
    for _, state in ipairs(BLOCKED_STATES) do
        pcall(function()
            hum:SetStateEnabled(state, false)
        end)
    end
end

local function UnblockRagdollStates(hum)
    if not hum then return end
    for _, state in ipairs(BLOCKED_STATES) do
        pcall(function()
            hum:SetStateEnabled(state, true)
        end)
    end
end

local function CleanupRagdollConstraints(char)
    if not char then return end

    for _, obj in ipairs(char:GetDescendants()) do
        pcall(function()
            -- Disable ragdoll constraints
            if obj:IsA("BallSocketConstraint") then
                if not obj:GetAttribute("_arOrigEnabled") then
                    obj:SetAttribute("_arOrigEnabled", obj.Enabled)
                end
                obj.Enabled = false

            -- Disable NoCollisionConstraint (ragdoll systems add these)
            elseif obj:IsA("NoCollisionConstraint") then
                if not obj:GetAttribute("_arOrigEnabled") then
                    obj:SetAttribute("_arOrigEnabled", obj.Enabled)
                end
                obj.Enabled = false

            -- Re-enable Motor6D (ragdoll disables these)
            elseif obj:IsA("Motor6D") then
                if not obj.Enabled then
                    obj.Enabled = true
                end
            end
        end)
    end
end

local function RestoreRagdollConstraints(char)
    if not char then return end

    for _, obj in ipairs(char:GetDescendants()) do
        pcall(function()
            if obj:IsA("BallSocketConstraint") or obj:IsA("NoCollisionConstraint") then
                local orig = obj:GetAttribute("_arOrigEnabled")
                if orig ~= nil then
                    obj.Enabled = orig
                    obj:SetAttribute("_arOrigEnabled", nil)
                end
            end
        end)
    end
end

local function ForceStanding(char, hum)
    if not char or not hum then return end

    pcall(function()
        -- Force state ke running/getting up
        local state = hum:GetState()
        if state == Enum.HumanoidStateType.Ragdoll
        or state == Enum.HumanoidStateType.FallingDown
        or state == Enum.HumanoidStateType.Physics then
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        end

        -- Prevent PlatformStand
        if hum.PlatformStand and not Flying then
            hum.PlatformStand = false
        end

        -- Force AutoRotate
        hum.AutoRotate = true

        -- Reset rotation velocity
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.RotVelocity = Vector3.zero

            -- Jika karakter miring terlalu jauh, straighten up
            local upVec = hrp.CFrame.UpVector
            if upVec.Y < 0.5 then
                local pos    = hrp.Position
                local lookVec = hrp.CFrame.LookVector
                local flatLook = Vector3.new(lookVec.X, 0, lookVec.Z)
                if flatLook.Magnitude > 0.01 then
                    hrp.CFrame = CFrame.lookAt(pos, pos + flatLook)
                end
            end
        end
    end)
end

local function ApplyAntiRagdollFull(char)
    if not char then return end

    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    -- Block states pertama kali
    BlockRagdollStates(hum)

    -- Cleanup existing ragdoll constraints
    CleanupRagdollConstraints(char)

    -- Monitor state changes
    local stateConn = hum.StateChanged:Connect(function(old, new)
        if not AntiRagdollEnabled then return end

        for _, blocked in ipairs(BLOCKED_STATES) do
            if new == blocked then
                task.defer(function()
                    if hum and hum.Parent then
                        ForceStanding(char, hum)
                        CleanupRagdollConstraints(char)
                    end
                end)
                return
            end
        end
    end)
    table.insert(ragdollConns, stateConn)

    -- Monitor descendants untuk ragdoll constraints baru
    local descConn = char.DescendantAdded:Connect(function(desc)
        if not AntiRagdollEnabled then return end

        task.defer(function()
            pcall(function()
                if desc:IsA("BallSocketConstraint") or desc:IsA("NoCollisionConstraint") then
                    desc.Enabled = false
                elseif desc:IsA("Motor6D") and not desc.Enabled then
                    desc.Enabled = true
                end
            end)
        end)
    end)
    table.insert(ragdollConns, descConn)

    -- Monitor Motor6D being disabled (ragdoll disables them)
    for _, motor in ipairs(char:GetDescendants()) do
        if motor:IsA("Motor6D") then
            local propConn = motor:GetPropertyChangedSignal("Enabled"):Connect(function()
                if not AntiRagdollEnabled then return end
                if not motor.Enabled then
                    task.defer(function()
                        pcall(function() motor.Enabled = true end)
                    end)
                end
            end)
            table.insert(ragdollConns, propConn)
        end
    end
end

local function CleanupAntiRagdoll()
    for _, conn in ipairs(ragdollConns) do
        pcall(function() conn:Disconnect() end)
    end
    ragdollConns = {}
end

-- ═══════════════════════════════════════════
-- ANTI SLIP V2 (COMPLETELY REWRITTEN)
-- Now handles:
-- 1. Slope detection via raycast
-- 2. Counter-force on slopes
-- 3. Friction override
-- 4. Velocity clamping on steep terrain
-- 5. BodyForce to prevent sliding
-- ═══════════════════════════════════════════
local SLOPE_ANGLE_THRESHOLD = 20 -- derajat: slope lebih dari ini = apply anti slip
local MAX_SLOPE_SPEED       = 2  -- max speed saat sliding di slope
local ANTI_SLIP_FRICTION    = 3.0

local function GetGroundInfo(hrp)
    if not hrp then return nil, nil, nil end

    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = {hrp.Parent} -- exclude karakter

    -- Raycast ke bawah lebih panjang untuk deteksi slope
    local result = workspace:Raycast(hrp.Position, Vector3.new(0, -6, 0), rayParams)

    if result then
        local normal      = result.Normal
        local slopeAngle  = math.deg(math.acos(math.clamp(normal:Dot(Vector3.yAxis), -1, 1)))
        local material    = result.Material
        return normal, slopeAngle, material
    end

    return nil, nil, nil
end

local function ApplyAntiSlipFriction(char)
    if not char then return end

    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            pcall(function()
                -- Simpan properties asli
                if not originalPartProps[part] then
                    local pp = part.CurrentPhysicalProperties
                    originalPartProps[part] = {
                        density     = pp.Density,
                        friction    = pp.Friction,
                        elasticity  = pp.Elasticity,
                        fWeight     = pp.FrictionWeight,
                        eWeight     = pp.ElasticityWeight,
                    }
                end

                -- Apply high friction
                part.CustomPhysicalProperties = PhysicalProperties.new(
                    originalPartProps[part].density,
                    ANTI_SLIP_FRICTION,
                    0,    -- zero elasticity
                    200,  -- very high friction weight
                    0     -- zero elasticity weight
                )
            end)
        end
    end
end

local function RestoreAntiSlipFriction(char)
    if not char then return end

    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") and originalPartProps[part] then
            pcall(function()
                local orig = originalPartProps[part]
                part.CustomPhysicalProperties = PhysicalProperties.new(
                    orig.density,
                    orig.friction,
                    orig.elasticity,
                    orig.fWeight,
                    orig.eWeight
                )
            end)
        end
    end

    originalPartProps = {}

    -- Remove anti slip body force
    if antiSlipBodyForce then
        pcall(function() antiSlipBodyForce:Destroy() end)
        antiSlipBodyForce = nil
    end
end

local function AntiSlipUpdate()
    if not AntiSlipEnabled then return end

    local char = LocalPlayer.Character
    if not char then return end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    -- Jangan apply saat fly mode
    if Flying then return end

    local normal, slopeAngle, material = GetGroundInfo(hrp)

    if not normal or not slopeAngle then
        -- Di udara, remove body force
        if antiSlipBodyForce then
            pcall(function() antiSlipBodyForce:Destroy() end)
            antiSlipBodyForce = nil
        end
        return
    end

    lastGroundNormal = normal

    -- Material licin
    local slipperyMaterials = {
        [Enum.Material.Ice]     = true,
        [Enum.Material.Glacier] = true,
        [Enum.Material.Marble]  = true,
    }

    local isSlippery = slipperyMaterials[material] or false
    local isOnSlope  = slopeAngle > SLOPE_ANGLE_THRESHOLD

    if isOnSlope or isSlippery then
        -- Hitung arah gravitasi di slope
        local gravityDir = Vector3.new(0, -1, 0)
        local slideDir   = (gravityDir - gravityDir:Dot(normal) * normal)

        if slideDir.Magnitude > 0.01 then
            slideDir = slideDir.Unit
        else
            slideDir = Vector3.zero
        end

        -- Apply counter force untuk melawan gravitasi di slope
        local counterForce = -slideDir * workspace.Gravity * hrp.AssemblyMass

        -- Extra force untuk material licin
        if isSlippery then
            counterForce = counterForce * 1.5
        end

        -- Clamp horizontal velocity saat di slope
        local vel = hrp.AssemblyLinearVelocity
        local horzVel = Vector3.new(vel.X, 0, vel.Z)

        -- Hanya clamp jika player tidak sengaja bergerak
        local moveDir = hum.MoveDirection
        if moveDir.Magnitude < 0.1 and horzVel.Magnitude > MAX_SLOPE_SPEED then
            -- Player diam tapi masih sliding = apply brake
            local brakeForce = -horzVel * hrp.AssemblyMass * 5
            counterForce = counterForce + brakeForce
        end

        -- Create atau update BodyForce
        if not antiSlipBodyForce or not antiSlipBodyForce.Parent then
            antiSlipBodyForce = Instance.new("BodyForce")
            antiSlipBodyForce.Name   = "AntiSlipForce"
            antiSlipBodyForce.Parent = hrp
        end

        antiSlipBodyForce.Force = counterForce

        -- Extra friction saat di slope licin
        if isSlippery or slopeAngle > 35 then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    pcall(function()
                        part.CustomPhysicalProperties = PhysicalProperties.new(
                            part.CurrentPhysicalProperties.Density,
                            5.0,    -- sangat tinggi
                            0,
                            1000,
                            0
                        )
                    end)
                end
            end
        end
    else
        -- Terrain datar, kurangi counter force
        if antiSlipBodyForce and antiSlipBodyForce.Parent then
            antiSlipBodyForce.Force = Vector3.zero
        end

        -- Re-apply normal anti slip friction
        if AntiSlipEnabled then
            ApplyAntiSlipFriction(char)
        end
    end
end

-- ═══════════════════════════════════════════
-- STAMINA & OXYGEN HELPERS
-- ═══════════════════════════════════════════
local function findValueByPatterns(root, patterns)
    if not root then return {} end
    local found = {}

    for _, obj in ipairs(root:GetDescendants()) do
        if obj:IsA("NumberValue") or obj:IsA("IntValue") then
            local name = obj.Name:lower()
            for _, pattern in ipairs(patterns) do
                if name:find(pattern:lower(), 1, true) then
                    table.insert(found, obj)
                    break
                end
            end
        end
    end

    return found
end

local staminaPatterns = {
    "stamina", "energy", "sprint", "endurance", "fatigue",
    "mana", "sp", "run", "breath",
}

local oxygenPatterns = {
    "oxygen", "air", "o2", "breath", "water",
    "dive", "drown", "lung",
}

-- ═══════════════════════════════════════════
-- ESP SYSTEM (Same as before, abbreviated)
-- ═══════════════════════════════════════════
local espBillboards = {}

local function RemovePlayerESP(plr)
    if not espBillboards[plr] then return end
    local d = espBillboards[plr]
    if d.CharConn then pcall(function() d.CharConn:Disconnect() end) end
    for k, obj in pairs(d) do
        if k ~= "CharConn" then pcall(function() obj:Destroy() end) end
    end
    espBillboards[plr] = nil
end

local function CreatePlayerESP(plr)
    if plr == LocalPlayer then return end
    RemovePlayerESP(plr)

    local function Setup(character)
        if not character then return end
        pcall(function()
            local hrp  = character:WaitForChild("HumanoidRootPart", 5)
            local head = character:WaitForChild("Head", 5)
            local hum  = character:WaitForChild("Humanoid", 5)
            if not hrp or not head or not hum then return end

            if not espBillboards[plr] then espBillboards[plr] = {} end
            local e = espBillboards[plr]

            e.Highlight = Instance.new("Highlight")
            e.Highlight.FillTransparency    = 0.7
            e.Highlight.OutlineTransparency = 0.1
            e.Highlight.DepthMode           = Enum.HighlightDepthMode.AlwaysOnTop
            e.Highlight.Adornee             = character
            e.Highlight.Parent              = ESPGui

            e.Billboard = Instance.new("BillboardGui")
            e.Billboard.Adornee      = head
            e.Billboard.Size         = UDim2.new(0, 200, 0, 100)
            e.Billboard.StudsOffset  = Vector3.new(0, 3, 0)
            e.Billboard.AlwaysOnTop  = true
            e.Billboard.LightInfluence = 0
            e.Billboard.MaxDistance  = ESPSettings.MaxDistance
            e.Billboard.Parent       = ESPGui

            e.NameLabel = Instance.new("TextLabel", e.Billboard)
            e.NameLabel.Size = UDim2.new(1,0,0,20)
            e.NameLabel.BackgroundTransparency = 1
            e.NameLabel.Text = plr.Name
            e.NameLabel.TextSize = 14; e.NameLabel.Font = Enum.Font.GothamBold
            e.NameLabel.TextColor3 = Color3.new(1,1,1)
            e.NameLabel.TextStrokeTransparency = 0.3
            e.NameLabel.TextStrokeColor3 = Color3.new(0,0,0)

            e.DistLabel = Instance.new("TextLabel", e.Billboard)
            e.DistLabel.Size = UDim2.new(1,0,0,16)
            e.DistLabel.Position = UDim2.new(0,0,0,20)
            e.DistLabel.BackgroundTransparency = 1
            e.DistLabel.TextSize = 12; e.DistLabel.Font = Enum.Font.GothamBold
            e.DistLabel.TextStrokeTransparency = 0.3; e.DistLabel.TextStrokeColor3 = Color3.new(0,0,0)

            e.DangerLabel = Instance.new("TextLabel", e.Billboard)
            e.DangerLabel.Size = UDim2.new(1,0,0,16)
            e.DangerLabel.Position = UDim2.new(0,0,0,36)
            e.DangerLabel.BackgroundTransparency = 1
            e.DangerLabel.TextSize = 12; e.DangerLabel.Font = Enum.Font.GothamBold
            e.DangerLabel.TextStrokeTransparency = 0.3; e.DangerLabel.TextStrokeColor3 = Color3.new(0,0,0)

            local hpBG = Instance.new("Frame", e.Billboard)
            hpBG.Size = UDim2.new(0.8,0,0,6); hpBG.Position = UDim2.new(0.1,0,0,56)
            hpBG.BackgroundColor3 = Color3.fromRGB(30,30,30); hpBG.BorderSizePixel = 0
            Instance.new("UICorner", hpBG).CornerRadius = UDim.new(1,0)
            e.HpBG = hpBG

            e.HpFill = Instance.new("Frame", hpBG)
            e.HpFill.Size = UDim2.new(1,0,1,0); e.HpFill.BackgroundColor3 = Color3.fromRGB(0,255,0)
            e.HpFill.BorderSizePixel = 0; Instance.new("UICorner", e.HpFill).CornerRadius = UDim.new(1,0)

            e.HpText = Instance.new("TextLabel", e.Billboard)
            e.HpText.Size = UDim2.new(1,0,0,14); e.HpText.Position = UDim2.new(0,0,0,64)
            e.HpText.BackgroundTransparency = 1; e.HpText.TextSize = 10
            e.HpText.Font = Enum.Font.Gotham; e.HpText.TextStrokeTransparency = 0.3
            e.HpText.TextStrokeColor3 = Color3.new(0,0,0)

            e.SelectionBox = Instance.new("SelectionBox")
            e.SelectionBox.Adornee = character; e.SelectionBox.Color3 = Color3.fromRGB(255,50,50)
            e.SelectionBox.LineThickness = 0.03; e.SelectionBox.SurfaceTransparency = 0.9
            e.SelectionBox.Parent = ESPGui

            e.HeadAdorn = Instance.new("BillboardGui")
            e.HeadAdorn.Adornee = head; e.HeadAdorn.Size = UDim2.new(1,0,1,0)
            e.HeadAdorn.AlwaysOnTop = true; e.HeadAdorn.LightInfluence = 0
            e.HeadAdorn.MaxDistance = ESPSettings.MaxDistance; e.HeadAdorn.Parent = ESPGui

            e.HeadCircle = Instance.new("Frame", e.HeadAdorn)
            e.HeadCircle.Size = UDim2.new(0.5,0,0.5,0); e.HeadCircle.Position = UDim2.new(0.25,0,0.25,0)
            e.HeadCircle.BackgroundColor3 = Color3.new(1,1,1); e.HeadCircle.BorderSizePixel = 0
            Instance.new("UICorner", e.HeadCircle).CornerRadius = UDim.new(1,0)

            e.TracerAtt0 = Instance.new("Attachment", hrp)
            e.TracerPart = Instance.new("Part")
            e.TracerPart.Anchored = true; e.TracerPart.CanCollide = false
            e.TracerPart.Transparency = 1; e.TracerPart.Size = Vector3.new(0.1,0.1,0.1)
            e.TracerPart.Parent = ESPWorkspaceFolder
            e.TracerAtt1 = Instance.new("Attachment", e.TracerPart)

            e.Beam = Instance.new("Beam", hrp)
            e.Beam.Attachment0 = e.TracerAtt1; e.Beam.Attachment1 = e.TracerAtt0
            e.Beam.Width0 = 0.1; e.Beam.Width1 = 0.1; e.Beam.FaceCamera = true
            e.Beam.Transparency = NumberSequence.new(0.5); e.Beam.LightEmission = 1
            e.Beam.Enabled = ESPSettings.ShowTracer
        end)
    end

    if plr.Character then Setup(plr.Character) end

    local charConn = plr.CharacterAdded:Connect(function(char)
        task.wait(1)
        if ESPEnabled then RemovePlayerESP(plr); espBillboards[plr] = {}; Setup(char) end
    end)

    if not espBillboards[plr] then espBillboards[plr] = {} end
    espBillboards[plr].CharConn = charConn
end

local function UpdateAllESP()
    local localChar = LocalPlayer.Character; if not localChar then return end
    local localHRP  = localChar:FindFirstChild("HumanoidRootPart"); if not localHRP then return end

    for _, plr in pairs(Players:GetPlayers()) do
        if plr == LocalPlayer then continue end
        local d = espBillboards[plr]; if not d then continue end
        local char = plr.Character; if not char then continue end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum then continue end

        local dist   = (hrp.Position - localHRP.Position).Magnitude
        local dColor = GetDistanceColor(dist)
        local dLbl   = GetDistanceLabel(dist)
        local hpP    = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
        local hpC    = GetHealthColor(hpP)
        local alive  = hum.Health > 0

        if d.Highlight then d.Highlight.FillColor = dColor; d.Highlight.OutlineColor = dColor; d.Highlight.Enabled = alive end
        if d.SelectionBox then d.SelectionBox.Color3 = dColor; d.SelectionBox.SurfaceColor3 = dColor; d.SelectionBox.Visible = alive end
        if d.NameLabel then d.NameLabel.TextColor3 = dColor end
        if d.DistLabel then d.DistLabel.Text = "["..math.floor(dist).." studs]"; d.DistLabel.TextColor3 = dColor end
        if d.DangerLabel then d.DangerLabel.Text = dLbl; d.DangerLabel.TextColor3 = dColor end
        if d.HpFill then d.HpFill.Size = UDim2.new(hpP,0,1,0); d.HpFill.BackgroundColor3 = hpC end
        if d.HpText then d.HpText.Text = math.floor(hum.Health).." / "..math.floor(hum.MaxHealth); d.HpText.TextColor3 = hpC end
        if d.HeadCircle then d.HeadCircle.BackgroundColor3 = dColor end
        if d.Billboard then d.Billboard.Enabled = alive; d.Billboard.MaxDistance = ESPSettings.MaxDistance end
        if d.HeadAdorn then d.HeadAdorn.Enabled = alive; d.HeadAdorn.MaxDistance = ESPSettings.MaxDistance end
        if d.Beam then d.Beam.Enabled = ESPSettings.ShowTracer and alive; d.Beam.Color = ColorSequence.new(dColor) end
        if d.TracerPart then d.TracerPart.CFrame = CFrame.new(localHRP.Position - Vector3.new(0,3,0)) end
    end
end

-- ═══════════════════════════════════════════
-- DANGER ALERT
-- ═══════════════════════════════════════════
local AlertFrame = Instance.new("Frame")
AlertFrame.Size = UDim2.new(0, isMobile and 280 or 320, 0, isMobile and 48 or 55)
AlertFrame.Position = UDim2.new(0.5, isMobile and -140 or -160, 0, 20)
AlertFrame.BackgroundColor3 = Color3.fromRGB(180,25,25)
AlertFrame.BackgroundTransparency = 0.2; AlertFrame.BorderSizePixel = 0
AlertFrame.Visible = false; AlertFrame.Parent = ESPGui
Instance.new("UICorner", AlertFrame).CornerRadius = UDim.new(0,12)
Instance.new("UIStroke", AlertFrame).Color = Color3.fromRGB(255,60,60)

local AlertText = Instance.new("TextLabel", AlertFrame)
AlertText.Size = UDim2.new(1,0,1,0); AlertText.BackgroundTransparency = 1
AlertText.Text = "⚠️ DANGER!"; AlertText.TextSize = isMobile and 14 or 16
AlertText.Font = Enum.Font.GothamBold; AlertText.TextColor3 = Color3.new(1,1,1)
AlertText.TextStrokeTransparency = 0.5

local alertActive = false
task.spawn(function()
    while ESPGui.Parent do
        if alertActive and AlertFrame.Visible then
            TweenService:Create(AlertFrame, TweenInfo.new(0.4, Enum.EasingStyle.Sine),
                {BackgroundTransparency = 0.05}):Play()
            task.wait(0.4)
            TweenService:Create(AlertFrame, TweenInfo.new(0.4, Enum.EasingStyle.Sine),
                {BackgroundTransparency = 0.5}):Play()
            task.wait(0.4)
        else task.wait(0.3) end
    end
end)

local function CheckDangerAlert()
    local lc = LocalPlayer.Character
    if not lc then AlertFrame.Visible = false; alertActive = false; return end
    local lh = lc:FindFirstChild("HumanoidRootPart")
    if not lh then AlertFrame.Visible = false; alertActive = false; return end

    local closestDist, closestName, count = math.huge, "", 0
    for _, p in pairs(Players:GetPlayers()) do
        if p == LocalPlayer then continue end
        local c = p.Character; if not c then continue end
        local h = c:FindFirstChild("HumanoidRootPart")
        local u = c:FindFirstChildOfClass("Humanoid")
        if not h or not u or u.Health <= 0 then continue end
        local d = (h.Position - lh.Position).Magnitude
        if d <= 200 then count += 1; if d < closestDist then closestDist = d; closestName = p.Name end end
    end

    if count > 0 then
        alertActive = true; AlertFrame.Visible = true
        AlertText.Text = count == 1
            and ("⚠️ DANGER! "..closestName.." ["..math.floor(closestDist).." studs]")
            or  ("⚠️ "..count.." Players within 200 studs!")
    else alertActive = false; AlertFrame.Visible = false end
end

-- ═══════════════════════════════════════════
-- RADAR (Same with object pool)
-- ═══════════════════════════════════════════
local RadarFrame = Instance.new("Frame")
RadarFrame.Size = UDim2.new(0, isMobile and 140 or 160, 0, isMobile and 140 or 160)
RadarFrame.Position = isMobile and UDim2.new(0.02, 0, 1, -160) or UDim2.new(1, -180, 1, -200)
RadarFrame.BackgroundColor3 = Color3.fromRGB(10,10,20)
RadarFrame.BackgroundTransparency = 0.3; RadarFrame.BorderSizePixel = 0
RadarFrame.Visible = false; RadarFrame.Parent = ESPGui
Instance.new("UICorner", RadarFrame).CornerRadius = UDim.new(1,0)
Instance.new("UIStroke", RadarFrame).Color = Color3.fromRGB(130,100,255)

for _, cfg in ipairs({
    {UDim2.new(1,0,0,1), UDim2.new(0,0,0.5,0)},
    {UDim2.new(0,1,1,0), UDim2.new(0.5,0,0,0)},
}) do
    local g = Instance.new("Frame", RadarFrame)
    g.Size = cfg[1]; g.Position = cfg[2]
    g.BackgroundColor3 = Color3.fromRGB(80,60,180)
    g.BackgroundTransparency = 0.7; g.BorderSizePixel = 0
end

local SelfDot = Instance.new("Frame", RadarFrame)
SelfDot.Size = UDim2.new(0,8,0,8); SelfDot.Position = UDim2.new(0.5,-4,0.5,-4)
SelfDot.BackgroundColor3 = Color3.fromRGB(100,200,255); SelfDot.BorderSizePixel = 0
Instance.new("UICorner", SelfDot).CornerRadius = UDim.new(1,0)

local RL = Instance.new("TextLabel", RadarFrame)
RL.Size = UDim2.new(1,0,0,16); RL.Position = UDim2.new(0,0,0,3)
RL.BackgroundTransparency = 1; RL.Text = "RADAR"; RL.TextSize = 10
RL.Font = Enum.Font.GothamBold; RL.TextColor3 = Color3.fromRGB(130,100,255)

local radarDotPool = {}
local function GetOrCreateRadarDot(i)
    if radarDotPool[i] then radarDotPool[i].Visible = true; return radarDotPool[i] end
    local d = Instance.new("Frame"); d.Size = UDim2.new(0,8,0,8); d.BorderSizePixel = 0; d.Parent = RadarFrame
    Instance.new("UICorner", d).CornerRadius = UDim.new(1,0)
    local n = Instance.new("TextLabel", d); n.Name = "NameLabel"
    n.Size = UDim2.new(0,60,0,12); n.Position = UDim2.new(0,10,0,-2)
    n.BackgroundTransparency = 1; n.TextSize = 8; n.Font = Enum.Font.GothamBold
    n.TextXAlignment = Enum.TextXAlignment.Left
    radarDotPool[i] = d; return d
end

local function UpdateRadar()
    local lc = LocalPlayer.Character; if not lc then return end
    local lh = lc:FindFirstChild("HumanoidRootPart"); if not lh then return end
    local rng, idx = 400, 0
    for _, p in pairs(Players:GetPlayers()) do
        if p == LocalPlayer then continue end
        local c = p.Character; if not c then continue end
        local h = c:FindFirstChild("HumanoidRootPart")
        local u = c:FindFirstChildOfClass("Humanoid")
        if not h or not u or u.Health <= 0 then continue end
        local dist = (h.Position - lh.Position).Magnitude
        if dist > rng then continue end
        idx += 1
        local dot = GetOrCreateRadarDot(idx)
        local col = GetDistanceColor(dist)
        local rel = lh.CFrame:PointToObjectSpace(h.Position)
        dot.Position = UDim2.new(0.5 + math.clamp(rel.X/rng,-1,1)*0.42, -4,
                                 0.5 + math.clamp(rel.Z/rng,-1,1)*0.42, -4)
        dot.BackgroundColor3 = col
        local nl = dot:FindFirstChild("NameLabel")
        if nl then nl.Text = p.Name; nl.TextColor3 = col end
    end
    for i = idx+1, #radarDotPool do
        if radarDotPool[i] then radarDotPool[i].Visible = false end
    end
end

-- ═══════════════════════════════════════════
-- PLAYER EVENTS
-- ═══════════════════════════════════════════
Players.PlayerAdded:Connect(function(p)
    if ESPEnabled then task.wait(2); CreatePlayerESP(p) end
end)
Players.PlayerRemoving:Connect(function(p) RemovePlayerESP(p) end)

-- ═══════════════════════════════════════════
-- CREATE ALL UI FEATURES
-- ═══════════════════════════════════════════

CreateSection("— VISUAL —", 1)

CreateToggle("🌞 Full Bright", "Semua area terang total", 2, function(state)
    if state then
        for _, v in pairs(Lighting:GetDescendants()) do
            if v:IsA("Atmosphere") or v:IsA("BloomEffect") or v:IsA("DepthOfFieldEffect")
            or v:IsA("ColorCorrectionEffect") or v:IsA("SunRaysEffect") then
                RemovedEffects[v] = v.Parent; v.Parent = nil
            end
        end
        connections:Add("bright", RunService.RenderStepped:Connect(function()
            Lighting.ClockTime = 14; Lighting.Brightness = 2
            Lighting.FogEnd = 1e6; Lighting.FogStart = 0
            Lighting.GlobalShadows = false; Lighting.OutdoorAmbient = Color3.new(1,1,1)
        end))
        connections:Add("brightChild", Lighting.ChildAdded:Connect(function(c)
            if c:IsA("Atmosphere") or c:IsA("BloomEffect") or c:IsA("DepthOfFieldEffect") then
                task.wait(); c:Destroy()
            end
        end))
        SetStatus("🌞 Full Bright: ON", Color3.fromRGB(100,255,120))
    else
        connections:Remove("bright"); connections:Remove("brightChild")
        Lighting.Brightness = originalValues.Brightness
        Lighting.ClockTime = originalValues.ClockTime
        Lighting.FogEnd = originalValues.FogEnd; Lighting.FogStart = originalValues.FogStart
        Lighting.GlobalShadows = originalValues.GlobalShadows
        Lighting.OutdoorAmbient = originalValues.OutdoorAmbient
        for inst, par in pairs(RemovedEffects) do pcall(function() inst.Parent = par end) end
        RemovedEffects = {}
        SetStatus("🌞 Full Bright: OFF", Color3.fromRGB(255,100,100))
    end
end)

CreateToggle("🔭 Unlimited Zoom", "Zoom kamera tanpa batas", 3, function(state)
    if state then
        connections:Add("zoom", RunService.RenderStepped:Connect(function()
            LocalPlayer.CameraMaxZoomDistance = 1e6; LocalPlayer.CameraMinZoomDistance = 0.1
        end))
        SetStatus("🔭 Zoom: ON", Color3.fromRGB(100,255,120))
    else
        connections:Remove("zoom")
        LocalPlayer.CameraMaxZoomDistance = originalValues.MaxZoom
        LocalPlayer.CameraMinZoomDistance = originalValues.MinZoom
        SetStatus("🔭 Zoom: OFF", Color3.fromRGB(255,100,100))
    end
end)

CreateSection("— COMBAT —", 4)

CreateToggle("❤️ HP Regen (Client)", "Auto heal client side", 5, function(state)
    if state then
        connections:Add("regen", RunService.Heartbeat:Connect(function()
            local c = LocalPlayer.Character
            if c then local h = c:FindFirstChildOfClass("Humanoid")
                if h and h.Health > 0 then h.Health = h.MaxHealth end end
        end))
        SetStatus("❤️ HP Regen: ON", Color3.fromRGB(100,255,120))
    else
        connections:Remove("regen")
        SetStatus("❤️ HP Regen: OFF", Color3.fromRGB(255,100,100))
    end
end)

CreateSection("— MOVEMENT —", 6)

local function StartFly()
    local char = LocalPlayer.Character; if not char then return end
    local torso = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not torso or not hum then return end

    BG = Instance.new("BodyGyro", torso)
    BV = Instance.new("BodyVelocity", torso)
    BG.P = 9e4; BG.maxTorque = Vector3.new(9e9,9e9,9e9); BG.cframe = torso.CFrame
    BV.velocity = Vector3.new(0,0.1,0); BV.maxForce = Vector3.new(9e9,9e9,9e9)

    task.spawn(function()
        repeat task.wait()
            if not Flying then break end
            hum.PlatformStand = true
            local moving = (Ctrl.l+Ctrl.r) ~= 0 or (Ctrl.f+Ctrl.b) ~= 0
            MaxSpeed = moving and FlySpeed or 0
            if moving then
                local look = Camera.CoordinateFrame.lookVector
                local side = (Camera.CoordinateFrame*CFrame.new(Ctrl.l+Ctrl.r,(Ctrl.f+Ctrl.b)*0.2,0)).p - Camera.CoordinateFrame.p
                BV.velocity = (look*(Ctrl.f+Ctrl.b)+side)*MaxSpeed
                LastCtrl = {f=Ctrl.f,b=Ctrl.b,l=Ctrl.l,r=Ctrl.r}
            elseif MaxSpeed ~= 0 then
                local look = Camera.CoordinateFrame.lookVector
                local side = (Camera.CoordinateFrame*CFrame.new(LastCtrl.l+LastCtrl.r,(LastCtrl.f+LastCtrl.b)*0.2,0)).p - Camera.CoordinateFrame.p
                BV.velocity = (look*(LastCtrl.f+LastCtrl.b)+side)*MaxSpeed
            else BV.velocity = Vector3.new(0,0.1,0) end
            BG.cframe = Camera.CoordinateFrame
        until not Flying
        Ctrl = {f=0,b=0,l=0,r=0}; LastCtrl = {f=0,b=0,l=0,r=0}; MaxSpeed = 0
        if BG then pcall(function() BG:Destroy() end) end
        if BV then pcall(function() BV:Destroy() end) end
        if hum then hum.PlatformStand = false end
    end)
end

CreateToggle("✈️ Fly", "Terbang bebas WASD + kamera", 7, function(state)
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
    if FlyToggleState then SetStatus("✈️ Speed: "..v, Color3.fromRGB(100,255,120)) end
end)

CreateToggle("🦘 Unlimited Jump", "Lompat di udara tanpa batas", 9, function(state)
    UnlimitedJumpEnabled = state
    if state then
        JumpConnection = UserInputService.JumpRequest:Connect(function()
            if not UnlimitedJumpEnabled then return end
            local c = LocalPlayer.Character; if not c then return end
            local h = c:FindFirstChildOfClass("Humanoid")
            if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
        end)
        SetStatus("🦘 Unlimited Jump: ON", Color3.fromRGB(100,255,120))
    else
        if JumpConnection then JumpConnection:Disconnect(); JumpConnection = nil end
        SetStatus("🦘 Unlimited Jump: OFF", Color3.fromRGB(255,100,100))
    end
end)

-- ═══════════════════════════════════════════
-- PHYSICS & SURVIVAL (NEW - FIXED)
-- ═══════════════════════════════════════════
CreateSection("— PHYSICS & SURVIVAL —", 15)

-- ─── ANTI RAGDOLL V2 ───
CreateToggle("🧍 Anti Ragdoll", "Block semua ragdoll 100%", 16, function(state)
    AntiRagdollEnabled = state

    if state then
        local char = LocalPlayer.Character
        if char then
            CleanupAntiRagdoll()
            ApplyAntiRagdollFull(char)
        end

        connections:Add("antiRagdollLoop", RunService.Heartbeat:Connect(function()
            if not AntiRagdollEnabled then return end
            local char = LocalPlayer.Character; if not char then return end
            local hum = char:FindFirstChildOfClass("Humanoid"); if not hum then return end

            ForceStanding(char, hum)
            BlockRagdollStates(hum)
        end))

        SetStatus("🧍 Anti Ragdoll: ON", Color3.fromRGB(100,255,120))
    else
        connections:Remove("antiRagdollLoop")
        CleanupAntiRagdoll()

        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then UnblockRagdollStates(hum) end
            RestoreRagdollConstraints(char)
        end

        SetStatus("🧍 Anti Ragdoll: OFF", Color3.fromRGB(255,100,100))
    end
end)

-- ─── ANTI SLIP V2 ───
CreateToggle("👟 Anti Slip/Slide", "Anti licin + anti slide slope", 17, function(state)
    AntiSlipEnabled = state

    if state then
        local char = LocalPlayer.Character
        if char then ApplyAntiSlipFriction(char) end

        connections:Add("antiSlipLoop", RunService.Heartbeat:Connect(function()
            AntiSlipUpdate()
        end))

        SetStatus("👟 Anti Slip: ON", Color3.fromRGB(100,255,120))
    else
        connections:Remove("antiSlipLoop")

        local char = LocalPlayer.Character
        if char then RestoreAntiSlipFriction(char) end

        SetStatus("👟 Anti Slip: OFF", Color3.fromRGB(255,100,100))
    end
end)

-- ─── UNLIMITED STAMINA ───
CreateToggle("⚡ Unlimited Stamina", "Stamina/energy tak terbatas", 18, function(state)
    UnlimStaminaEnabled = state

    if state then
        connections:Add("unlimStamina", RunService.Heartbeat:Connect(function()
            if not UnlimStaminaEnabled then return end

            -- Scan character
            local char = LocalPlayer.Character
            if char then
                local found = findValueByPatterns(char, staminaPatterns)
                for _, val in ipairs(found) do
                    pcall(function() if val.Value < 80 then val.Value = 100 end end)
                end
            end

            -- Scan player
            local pFound = findValueByPatterns(LocalPlayer, staminaPatterns)
            for _, val in ipairs(pFound) do
                pcall(function() if val.Value < 80 then val.Value = 100 end end)
            end
        end))

        SetStatus("⚡ Stamina: ON", Color3.fromRGB(100,255,120))
    else
        connections:Remove("unlimStamina")
        SetStatus("⚡ Stamina: OFF", Color3.fromRGB(255,100,100))
    end
end)

-- ─── UNLIMITED OXYGEN ───
CreateToggle("🌊 Unlimited Oxygen", "Tidak tenggelam dalam air", 19, function(state)
    UnlimOxygenEnabled = state

    if state then
        connections:Add("unlimOxygen", RunService.Heartbeat:Connect(function()
            if not UnlimOxygenEnabled then return end

            local char = LocalPlayer.Character; if not char then return end
            local hum = char:FindFirstChildOfClass("Humanoid"); if not hum then return end

            -- Protect from drowning
            pcall(function()
                if hum:GetState() == Enum.HumanoidStateType.Swimming then
                    if hum.Health > 0 then hum.Health = hum.MaxHealth end
                end
            end)

            -- Scan oxygen values
            local found = findValueByPatterns(char, oxygenPatterns)
            for _, val in ipairs(found) do
                pcall(function() if val.Value < 80 then val.Value = 100 end end)
            end

            local pFound = findValueByPatterns(LocalPlayer, oxygenPatterns)
            for _, val in ipairs(pFound) do
                pcall(function() if val.Value < 80 then val.Value = 100 end end)
            end
        end))

        SetStatus("🌊 Oxygen: ON", Color3.fromRGB(100,200,255))
    else
        connections:Remove("unlimOxygen")
        SetStatus("🌊 Oxygen: OFF", Color3.fromRGB(255,100,100))
    end
end)

-- ═══════════════════════════════════════════
-- ESP SECTION
-- ═══════════════════════════════════════════
CreateSection("— ESP / RADAR —", 25)

CreateToggle("👁️ ESP (Full)", "Box + Name + HP + Distance", 26, function(state)
    ESPEnabled = state
    if state then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then CreatePlayerESP(p) end
        end
        ESPUpdateConn = RunService.Heartbeat:Connect(function(dt)
            espUpdateTimer += dt; dangerUpdateTimer += dt
            if espUpdateTimer >= 0.05 then espUpdateTimer = 0; UpdateAllESP() end
            if dangerUpdateTimer >= 0.2 then dangerUpdateTimer = 0; CheckDangerAlert() end
        end)
        SetStatus("👁️ ESP: ON", Color3.fromRGB(100,255,120))
    else
        if ESPUpdateConn then ESPUpdateConn:Disconnect(); ESPUpdateConn = nil end
        for _, p in pairs(Players:GetPlayers()) do RemovePlayerESP(p) end
        AlertFrame.Visible = false; alertActive = false
        espUpdateTimer = 0; dangerUpdateTimer = 0
        SetStatus("👁️ ESP: OFF", Color3.fromRGB(255,100,100))
    end
end)

CreateToggle("📍 Tracer Lines", "Garis ke arah musuh", 27, function(state)
    ESPSettings.ShowTracer = state
    SetStatus("📍 Tracer: "..(state and "ON" or "OFF"),
        state and Color3.fromRGB(100,255,120) or Color3.fromRGB(255,100,100))
end)

CreateToggle("🗺️ Mini Radar", "Radar deteksi musuh", 28, function(state)
    RadarFrame.Visible = state
    if state then
        connections:Add("radar", RunService.Heartbeat:Connect(function(dt)
            radarUpdateTimer += dt
            if radarUpdateTimer >= 0.1 then radarUpdateTimer = 0; UpdateRadar() end
        end))
        SetStatus("🗺️ Radar: ON", Color3.fromRGB(100,255,120))
    else
        connections:Remove("radar"); radarUpdateTimer = 0
        SetStatus("🗺️ Radar: OFF", Color3.fromRGB(255,100,100))
    end
end)

CreateSlider("👁️ ESP Max Distance", 100, 3000, 1500, 29, function(v)
    ESPSettings.MaxDistance = v
end)

-- ═══════════════════════════════════════════
-- COLOR LEGEND
-- ═══════════════════════════════════════════
local LegendFrame = Instance.new("Frame")
LegendFrame.Size = UDim2.new(1,0,0,90); LegendFrame.BackgroundColor3 = Color3.fromRGB(28,28,42)
LegendFrame.BorderSizePixel = 0; LegendFrame.LayoutOrder = 30; LegendFrame.Parent = Content
Instance.new("UICorner", LegendFrame).CornerRadius = UDim.new(0,10)
Instance.new("UIStroke", LegendFrame).Color = Color3.fromRGB(45,45,65)

local LT = Instance.new("TextLabel", LegendFrame)
LT.Size = UDim2.new(1,0,0,20); LT.Position = UDim2.new(0,0,0,2)
LT.BackgroundTransparency = 1; LT.Text = "🎨 ESP Color Legend"
LT.TextSize = isMobile and 13 or 12; LT.Font = Enum.Font.GothamBold
LT.TextColor3 = Color3.fromRGB(200,200,200)

for _, d in ipairs({
    {Color3.fromRGB(255,50,50),  "🔴 0-200 = DANGER",   22},
    {Color3.fromRGB(255,220,0),  "🟡 201-300 = WARNING", 36},
    {Color3.fromRGB(50,255,80),  "🟢 301-600 = MEDIUM",  50},
    {Color3.fromRGB(60,160,255), "🔵 601+ = FAR/SAFE",   64},
}) do
    local dot = Instance.new("Frame", LegendFrame)
    dot.Size = UDim2.new(0,10,0,10); dot.Position = UDim2.new(0,12,0,d[3])
    dot.BackgroundColor3 = d[1]; dot.BorderSizePixel = 0
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1,0)

    local l = Instance.new("TextLabel", LegendFrame)
    l.Size = UDim2.new(1,-30,0,14); l.Position = UDim2.new(0,28,0,d[3]-1)
    l.BackgroundTransparency = 1; l.Text = d[2]
    l.TextSize = isMobile and 11 or 10; l.Font = Enum.Font.Gotham
    l.TextColor3 = d[1]; l.TextXAlignment = Enum.TextXAlignment.Left
end

local Credit = Instance.new("TextLabel")
Credit.Size = UDim2.new(1,0,0,22); Credit.BackgroundTransparency = 1
Credit.Text = "Solara Hub V5 ⚡ | Mobile Ready + Physics Fixed"
Credit.TextSize = isMobile and 11 or 10; Credit.Font = Enum.Font.Gotham
Credit.TextColor3 = Color3.fromRGB(60,60,80); Credit.LayoutOrder = 99
Credit.Parent = Content

-- ═══════════════════════════════════════════
-- FLY KEYBINDS (PC) + MOBILE FLY CONTROLS
-- ═══════════════════════════════════════════
if not isMobile then
    local flyKeyMap = {
        [Enum.KeyCode.W] = function(v) Ctrl.f = v end,
        [Enum.KeyCode.S] = function(v) Ctrl.b = v end,
        [Enum.KeyCode.A] = function(v) Ctrl.l = v end,
        [Enum.KeyCode.D] = function(v) Ctrl.r = v end,
    }

    UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
        local fn = flyKeyMap[input.KeyCode]
        if fn then
            if input.KeyCode == Enum.KeyCode.W then fn(1)
            elseif input.KeyCode == Enum.KeyCode.S then fn(-1)
            elseif input.KeyCode == Enum.KeyCode.A then fn(-1)
            elseif input.KeyCode == Enum.KeyCode.D then fn(1) end
        end
        if input.KeyCode == Enum.KeyCode.RightControl then
            if MainFrame.Visible then MinBtn.MouseButton1Click:Fire()
            elseif MiniIcon.Visible then MiniIcon.MouseButton1Click:Fire() end
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
        local fn = flyKeyMap[input.KeyCode]
        if fn then fn(0) end
    end)
else
    -- Mobile: Use thumbstick / Humanoid MoveDirection for fly
    connections:Add("mobileFlyInput", RunService.Heartbeat:Connect(function()
        if not Flying then return end
        local char = LocalPlayer.Character; if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid"); if not hum then return end

        local moveDir = hum.MoveDirection
        if moveDir.Magnitude > 0.1 then
            Ctrl.f = moveDir.Z < -0.3 and 1 or (moveDir.Z > 0.3 and -1 or 0)
            Ctrl.r = moveDir.X > 0.3 and 1 or (moveDir.X < -0.3 and -1 or 0)
            Ctrl.l = 0; Ctrl.b = 0
        else
            Ctrl = {f=0, b=0, l=0, r=0}
        end
    end))
end

-- ═══════════════════════════════════════════
-- DRAGGABLE (Touch + Mouse)
-- ═══════════════════════════════════════════
do
    local dragging, dragInput, dragStart, startPos

    TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = input.Position; startPos = MainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    TitleBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

do
    local d2, di2, ds2, sp2
    MiniIcon.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            d2 = true; ds2 = input.Position; sp2 = MiniIcon.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then d2 = false end
            end)
        end
    end)
    MiniIcon.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then di2 = input end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == di2 and d2 then
            local delta = input.Position - ds2
            MiniIcon.Position = UDim2.new(sp2.X.Scale, sp2.X.Offset + delta.X,
                sp2.Y.Scale, sp2.Y.Offset + delta.Y)
        end
    end)
end

-- ═══════════════════════════════════════════
-- MINIMIZE / RESTORE
-- ═══════════════════════════════════════════
MinBtn.MouseButton1Click:Connect(function()
    TweenService:Create(MainFrame, TweenInfo.new(0.35,Enum.EasingStyle.Quart,Enum.EasingDirection.In), {
        Size = UDim2.new(0,0,0,0)
    }):Play()
    task.wait(0.35)
    MainFrame.Visible = false; MiniIcon.Visible = true
    MiniIcon.Size = UDim2.new(0,0,0,0); MiniIcon.ImageTransparency = 1
    TweenService:Create(MiniIcon, TweenInfo.new(0.4,Enum.EasingStyle.Back,Enum.EasingDirection.Out), {
        Size = isMobile and UDim2.new(0,60,0,60) or UDim2.new(0,55,0,55),
        ImageTransparency = 0
    }):Play()
end)

local lastClick = 0
MiniIcon.MouseButton1Click:Connect(function()
    if tick() - lastClick < 0.3 then return end; lastClick = tick()
    TweenService:Create(MiniIcon, TweenInfo.new(0.25,Enum.EasingStyle.Quart,Enum.EasingDirection.In), {
        Size = UDim2.new(0,0,0,0), ImageTransparency = 1
    }):Play()
    task.wait(0.25)
    MiniIcon.Visible = false; MainFrame.Visible = true
    MainFrame.Size = UDim2.new(0,0,0,0)
    TweenService:Create(MainFrame, TweenInfo.new(0.5,Enum.EasingStyle.Back,Enum.EasingDirection.Out), {
        Size = isMobile and UDim2.new(0.92,0,0.82,0) or UDim2.new(0,340,0,580),
        Position = isMobile and UDim2.new(0.04,0,0.09,0) or UDim2.new(0.5,-170,0.5,-290)
    }):Play()
end)

-- ═══════════════════════════════════════════
-- CHARACTER RESPAWN (Reapply all features)
-- ═══════════════════════════════════════════
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.5)

    if AntiRagdollEnabled then
        CleanupAntiRagdoll()
        task.wait(0.2)
        ApplyAntiRagdollFull(char)
    end

    if AntiSlipEnabled then
        task.wait(0.2)
        ApplyAntiSlipFriction(char)
    end
end)

-- ═══════════════════════════════════════════
-- CLOSE
-- ═══════════════════════════════════════════
CloseBtn.MouseButton1Click:Connect(function()
    Flying = false; FlyToggleState = false; ESPEnabled = false
    UnlimitedJumpEnabled = false; AntiRagdollEnabled = false
    AntiSlipEnabled = false; UnlimStaminaEnabled = false; UnlimOxygenEnabled = false

    if ESPUpdateConn then ESPUpdateConn:Disconnect(); ESPUpdateConn = nil end
    if JumpConnection then JumpConnection:Disconnect(); JumpConnection = nil end

    CleanupAntiRagdoll()

    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then UnblockRagdollStates(hum); hum.PlatformStand = false; hum.AutoRotate = true end
        RestoreRagdollConstraints(char)
        RestoreAntiSlipFriction(char)
    end

    for _, p in pairs(Players:GetPlayers()) do RemovePlayerESP(p) end
    connections:RemoveAll()

    pcall(function()
        Lighting.Brightness = originalValues.Brightness; Lighting.ClockTime = originalValues.ClockTime
        Lighting.FogEnd = originalValues.FogEnd; Lighting.FogStart = originalValues.FogStart
        Lighting.GlobalShadows = originalValues.GlobalShadows
        Lighting.OutdoorAmbient = originalValues.OutdoorAmbient
        LocalPlayer.CameraMaxZoomDistance = originalValues.MaxZoom
        LocalPlayer.CameraMinZoomDistance = originalValues.MinZoom
    end)

    for inst, par in pairs(RemovedEffects) do pcall(function() inst.Parent = par end) end
    RemovedEffects = {}

    if BG then pcall(function() BG:Destroy() end) end
    if BV then pcall(function() BV:Destroy() end) end

    pcall(function() ESPWorkspaceFolder:Destroy() end)
    for _, d in pairs(radarDotPool) do pcall(function() d:Destroy() end) end

    TweenService:Create(MainFrame, TweenInfo.new(0.3,Enum.EasingStyle.Quart,Enum.EasingDirection.In),
        {Size = UDim2.new(0,0,0,0)}):Play()
    task.wait(0.35)
    pcall(function() ESPGui:Destroy() end)
    pcall(function() ScreenGui:Destroy() end)
end)

-- ═══════════════════════════════════════════
-- HOVER EFFECTS
-- ═══════════════════════════════════════════
for _, pair in ipairs({
    {CloseBtn, Color3.fromRGB(255,70,70), Color3.fromRGB(200,50,50)},
    {MinBtn, Color3.fromRGB(255,210,50), Color3.fromRGB(255,175,0)},
    {MiniIcon, Color3.fromRGB(40,40,60), Color3.fromRGB(25,25,40)},
}) do
    pair[1].MouseEnter:Connect(function()
        TweenService:Create(pair[1], TweenInfo.new(0.2), {BackgroundColor3 = pair[2]}):Play()
    end)
    pair[1].MouseLeave:Connect(function()
        TweenService:Create(pair[1], TweenInfo.new(0.2), {BackgroundColor3 = pair[3]}):Play()
    end)
end

-- ═══════════════════════════════════════════
-- OPEN ANIMATION
-- ═══════════════════════════════════════════
MainFrame.Size     = UDim2.new(0, 0, 0, 0)
MainFrame.Position = isMobile and UDim2.new(0.5, 0, 0.5, 0) or UDim2.new(0.5, 0, 0.5, 0)

TweenService:Create(MainFrame, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
    Size     = isMobile and UDim2.new(0.92, 0, 0.82, 0) or UDim2.new(0, 340, 0, 580),
    Position = isMobile and UDim2.new(0.04, 0, 0.09, 0) or UDim2.new(0.5, -170, 0.5, -290)
}):Play()

print("══════════════════════════════════════════")
print("⚡ Solara Hub V5 - MOBILE + PHYSICS FIXED")
print("══════════════════════════════════════════")
print("📱 Platform: " .. (isMobile and "MOBILE" or "PC"))
print("══════════════════════════════════════════")
print("🧍 Anti Ragdoll V2:")
print("   → SetStateEnabled(false) for all ragdoll states")
print("   → Motor6D protection (prevent disable)")
print("   → CFrame straighten jika miring")
print("   → DescendantAdded constraint blocking")
print("👟 Anti Slip V2:")
print("   → Slope detection via Raycast + normal angle")
print("   → BodyForce counter-gravity pada slope")
print("   → Velocity brake saat diam di slope")
print("   → Ice/Glacier/Marble material detection")
print("   → Extra friction saat angle > 35°")
print("⚡ Unlimited Stamina: pattern scan")
print("🌊 Unlimited Oxygen: drowning block + scan")
print("══════════════════════════════════════════")
