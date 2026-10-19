-- ════════════════════════════════════════════════════════
-- VISION CONTROL GUI - Local/Client Side (Anti Ban)
-- Fog, Weather, Time, Night Vision, Zoom, Brightness
-- + Speed Control (Normal 17 / Boost 21) - Toggle UI Only
-- ════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local LP = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local isMobile = UIS.TouchEnabled and not UIS.KeyboardEnabled

-- ════════════════════════════════════════════════════════
-- HAPUS GUI LAMA
-- ════════════════════════════════════════════════════════
local oldGui = LP.PlayerGui:FindFirstChild("VisionControlGUI")
if oldGui then oldGui:Destroy() end

-- ════════════════════════════════════════════════════════
-- SIMPAN NILAI ASLI
-- ════════════════════════════════════════════════════════
local Original = {
    FogStart = Lighting.FogStart,
    FogEnd = Lighting.FogEnd,
    FogColor = Lighting.FogColor,
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    ExposureCompensation = Lighting.ExposureCompensation,
    GlobalShadows = Lighting.GlobalShadows,
    EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale,
    EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale,
}

local OriginalZoom = {
    MinDistance = LP.CameraMinZoomDistance,
    MaxDistance = LP.CameraMaxZoomDistance,
    FOV = Camera.FieldOfView,
}

local OriginalEffects = {}
for _, v in pairs(Lighting:GetChildren()) do
    if v:IsA("Atmosphere") or v:IsA("BloomEffect") or v:IsA("BlurEffect")
        or v:IsA("ColorCorrectionEffect") or v:IsA("SunRaysEffect")
        or v:IsA("DepthOfFieldEffect") then
        OriginalEffects[v] = v.Enabled
    end
end

local OriginalSpeed = 16
pcall(function()
    local char = LP.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            OriginalSpeed = hum.WalkSpeed
        end
    end
end)

-- ════════════════════════════════════════════════════════
-- STATE
-- ════════════════════════════════════════════════════════
local State = {
    FogRemoved = false,
    WeatherRemoved = false,
    TimeLocked = false,
    LockTime = 12,
    NightVision = false,
    FullBright = false,
    NoShadows = false,
    NoEffects = false,
    NoParticles = false,
    UnlimitedZoom = false,
    MaxZoom = 500,
    FOV = 70,
    SpeedEnabled = false,
    SpeedBoosted = false,
    NormalSpeed = 17,
    BoostSpeed = 21,
}

-- ════════════════════════════════════════════════════════
-- WARNA
-- ════════════════════════════════════════════════════════
local C = {
    bg = Color3.fromRGB(18, 18, 28),
    bg2 = Color3.fromRGB(28, 28, 42),
    bg3 = Color3.fromRGB(38, 38, 54),
    bg4 = Color3.fromRGB(48, 48, 64),
    accent = Color3.fromRGB(80, 160, 255),
    accentDark = Color3.fromRGB(60, 120, 200),
    accentGlow = Color3.fromRGB(110, 180, 255),
    green = Color3.fromRGB(70, 210, 125),
    greenDark = Color3.fromRGB(50, 170, 100),
    red = Color3.fromRGB(220, 70, 70),
    orange = Color3.fromRGB(240, 170, 60),
    purple = Color3.fromRGB(160, 100, 255),
    cyan = Color3.fromRGB(60, 210, 220),
    text = Color3.fromRGB(235, 235, 245),
    text2 = Color3.fromRGB(170, 175, 195),
    text3 = Color3.fromRGB(100, 105, 125),
    border = Color3.fromRGB(50, 55, 70),
    white = Color3.fromRGB(255, 255, 255),
    yellow = Color3.fromRGB(255, 220, 80),
}

-- ════════════════════════════════════════════════════════
-- HELPER
-- ════════════════════════════════════════════════════════
local function Tw(obj, t, props)
    TweenService:Create(obj, TweenInfo.new(t, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), props):Play()
end

local function Corner(p, r)
    local c = Instance.new("UICorner", p)
    c.CornerRadius = UDim.new(0, r or 8)
end

local function Stroke(p, col, thick, trans)
    local s = Instance.new("UIStroke", p)
    s.Color = col or C.border
    s.Thickness = thick or 1
    s.Transparency = trans or 0.4
    return s
end

-- ════════════════════════════════════════════════════════
-- SCREEN GUI
-- ════════════════════════════════════════════════════════
local GUI = Instance.new("ScreenGui")
GUI.Name = "VisionControlGUI"
GUI.ResetOnSpawn = false
GUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
GUI.Parent = LP.PlayerGui

-- ════════════════════════════════════════════════════════
-- TOGGLE BUTTON
-- ════════════════════════════════════════════════════════
local ToggleBtn = Instance.new("TextButton", GUI)
ToggleBtn.Size = UDim2.new(0, 46, 0, 46)
ToggleBtn.Position = UDim2.new(0, 14, 0.35, 0)
ToggleBtn.BackgroundColor3 = C.accent
ToggleBtn.Text = ""
ToggleBtn.AutoButtonColor = false
ToggleBtn.ZIndex = 500
Corner(ToggleBtn, 23)
Stroke(ToggleBtn, C.accentDark, 2, 0.2)

local togIcon = Instance.new("TextLabel", ToggleBtn)
togIcon.Size = UDim2.new(1, 0, 1, 0)
togIcon.BackgroundTransparency = 1
togIcon.Text = "👁"
togIcon.TextSize = 22
togIcon.ZIndex = 501

local tDrag, tDS, tSP
ToggleBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        tDrag = true; tDS = input.Position; tSP = ToggleBtn.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then tDrag = false end
        end)
    end
end)
UIS.InputChanged:Connect(function(input)
    if tDrag and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
        local d = input.Position - tDS
        if d.Magnitude > 5 then
            ToggleBtn.Position = UDim2.new(tSP.X.Scale, tSP.X.Offset + d.X, tSP.Y.Scale, tSP.Y.Offset + d.Y)
        end
    end
end)

-- ════════════════════════════════════════════════════════
-- MAIN PANEL
-- ════════════════════════════════════════════════════════
local PW = isMobile and 300 or 340
local PH = isMobile and 580 or 620
local panelOpen = false

local Panel = Instance.new("Frame", GUI)
Panel.Size = UDim2.new(0, PW, 0, 0)
Panel.Position = UDim2.new(0.5, -PW/2, 0.5, -PH/2)
Panel.BackgroundColor3 = C.bg
Panel.ClipsDescendants = true
Panel.Visible = false
Panel.ZIndex = 200
Corner(Panel, 14)
Stroke(Panel, C.border, 1.5, 0.3)

local pD, pDS, pSP
Panel.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        pD = true; pDS = input.Position; pSP = Panel.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then pD = false end
        end)
    end
end)
UIS.InputChanged:Connect(function(input)
    if pD and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
        local d = input.Position - pDS
        Panel.Position = UDim2.new(pSP.X.Scale, pSP.X.Offset + d.X, pSP.Y.Scale, pSP.Y.Offset + d.Y)
    end
end)

-- ════════════════════════════════════════════════════════
-- TITLE BAR
-- ════════════════════════════════════════════════════════
local TBar = Instance.new("Frame", Panel)
TBar.Size = UDim2.new(1, 0, 0, 46)
TBar.BackgroundColor3 = C.bg2
TBar.ZIndex = 201
Corner(TBar, 14)

local tbPatch = Instance.new("Frame", TBar)
tbPatch.Size = UDim2.new(1, 0, 0, 14)
tbPatch.Position = UDim2.new(0, 0, 1, -14)
tbPatch.BackgroundColor3 = C.bg2
tbPatch.BorderSizePixel = 0
tbPatch.ZIndex = 201

local aLine = Instance.new("Frame", TBar)
aLine.Size = UDim2.new(1, 0, 0, 2)
aLine.Position = UDim2.new(0, 0, 1, -2)
aLine.BackgroundColor3 = C.accent
aLine.BorderSizePixel = 0
aLine.ZIndex = 202

local tIcon = Instance.new("TextLabel", TBar)
tIcon.Size = UDim2.new(0, 28, 1, 0)
tIcon.Position = UDim2.new(0, 12, 0, 0)
tIcon.BackgroundTransparency = 1
tIcon.Text = "👁"
tIcon.TextSize = 20
tIcon.ZIndex = 202

local tTitle = Instance.new("TextLabel", TBar)
tTitle.Size = UDim2.new(0, 160, 1, 0)
tTitle.Position = UDim2.new(0, 42, 0, 0)
tTitle.BackgroundTransparency = 1
tTitle.Text = "Vision Control"
tTitle.TextColor3 = C.white
tTitle.TextSize = isMobile and 14 or 15
tTitle.Font = Enum.Font.GothamBold
tTitle.TextXAlignment = Enum.TextXAlignment.Left
tTitle.ZIndex = 202

local badge = Instance.new("Frame", TBar)
badge.Size = UDim2.new(0, 50, 0, 18)
badge.Position = UDim2.new(0, 155, 0.5, -9)
badge.BackgroundColor3 = C.green
badge.BackgroundTransparency = 0.7
badge.ZIndex = 202
Corner(badge, 4)

local badgeLbl = Instance.new("TextLabel", badge)
badgeLbl.Size = UDim2.new(1, 0, 1, 0)
badgeLbl.BackgroundTransparency = 1
badgeLbl.Text = "LOCAL"
badgeLbl.TextColor3 = C.green
badgeLbl.TextSize = 8
badgeLbl.Font = Enum.Font.GothamBold
badgeLbl.ZIndex = 203

local xBtn = Instance.new("TextButton", TBar)
xBtn.Size = UDim2.new(0, 32, 0, 32)
xBtn.Position = UDim2.new(1, -38, 0.5, -16)
xBtn.BackgroundColor3 = C.red
xBtn.BackgroundTransparency = 0.75
xBtn.Text = ""
xBtn.AutoButtonColor = false
xBtn.ZIndex = 202
Corner(xBtn, 8)

local xLbl = Instance.new("TextLabel", xBtn)
xLbl.Size = UDim2.new(1, 0, 1, 0)
xLbl.BackgroundTransparency = 1
xLbl.Text = "✕"
xLbl.TextColor3 = C.red
xLbl.TextSize = 13
xLbl.Font = Enum.Font.GothamBold
xLbl.ZIndex = 203

xBtn.MouseEnter:Connect(function() Tw(xBtn, 0.12, {BackgroundTransparency = 0.3}) end)
xBtn.MouseLeave:Connect(function() Tw(xBtn, 0.12, {BackgroundTransparency = 0.75}) end)

-- ════════════════════════════════════════════════════════
-- SCROLL CONTENT
-- ════════════════════════════════════════════════════════
local Scroll = Instance.new("ScrollingFrame", Panel)
Scroll.Size = UDim2.new(1, -16, 1, -56)
Scroll.Position = UDim2.new(0, 8, 0, 52)
Scroll.BackgroundTransparency = 1
Scroll.ScrollBarThickness = 3
Scroll.ScrollBarImageColor3 = C.accent
Scroll.CanvasSize = UDim2.new(0, 0, 0, 1300)
Scroll.ZIndex = 201

local SLayout = Instance.new("UIListLayout", Scroll)
SLayout.Padding = UDim.new(0, 6)

SLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    Scroll.CanvasSize = UDim2.new(0, 0, 0, SLayout.AbsoluteContentSize.Y + 12)
end)

-- ════════════════════════════════════════════════════════
-- UI BUILDERS
-- ════════════════════════════════════════════════════════

local function MakeSection(parent, text, icon)
    local f = Instance.new("Frame", parent)
    f.Size = UDim2.new(1, 0, 0, 24)
    f.BackgroundTransparency = 1
    f.ZIndex = 202

    local lbl = Instance.new("TextLabel", f)
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = icon .. "  " .. text
    lbl.TextColor3 = C.text3
    lbl.TextSize = 11
    lbl.Font = Enum.Font.GothamBold
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 203
    return f
end

local function MakeToggle(parent, name, icon, color, default, callback)
    local f = Instance.new("Frame", parent)
    f.Size = UDim2.new(1, 0, 0, 42)
    f.BackgroundColor3 = C.bg2
    f.ZIndex = 202
    Corner(f, 10)
    Stroke(f, C.border, 1, 0.5)

    local ic = Instance.new("TextLabel", f)
    ic.Size = UDim2.new(0, 28, 1, 0)
    ic.Position = UDim2.new(0, 10, 0, 0)
    ic.BackgroundTransparency = 1
    ic.Text = icon
    ic.TextSize = 16
    ic.ZIndex = 203

    local nm = Instance.new("TextLabel", f)
    nm.Size = UDim2.new(1, -100, 1, 0)
    nm.Position = UDim2.new(0, 40, 0, 0)
    nm.BackgroundTransparency = 1
    nm.Text = name
    nm.TextColor3 = C.text
    nm.TextSize = 12
    nm.Font = Enum.Font.GothamMedium
    nm.TextXAlignment = Enum.TextXAlignment.Left
    nm.ZIndex = 203

    local togBg = Instance.new("TextButton", f)
    togBg.Size = UDim2.new(0, 46, 0, 24)
    togBg.Position = UDim2.new(1, -56, 0.5, -12)
    togBg.BackgroundColor3 = default and (color or C.green) or C.bg4
    togBg.Text = ""
    togBg.AutoButtonColor = false
    togBg.ZIndex = 203
    Corner(togBg, 12)

    local knob = Instance.new("Frame", togBg)
    knob.Size = UDim2.new(0, 20, 0, 20)
    knob.Position = default and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)
    knob.BackgroundColor3 = C.white
    knob.ZIndex = 204
    Corner(knob, 10)

    local state = default or false

    local function SetState(val)
        state = val
        Tw(togBg, 0.2, {BackgroundColor3 = state and (color or C.green) or C.bg4})
        Tw(knob, 0.2, {Position = state and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)})
        callback(state)
    end

    togBg.MouseButton1Click:Connect(function()
        SetState(not state)
    end)

    return f, SetState
end

local function MakeSlider(parent, name, icon, min, max, default, showDecimal, callback)
    local f = Instance.new("Frame", parent)
    f.Size = UDim2.new(1, 0, 0, 56)
    f.BackgroundColor3 = C.bg2
    f.ZIndex = 202
    Corner(f, 10)
    Stroke(f, C.border, 1, 0.5)

    local ic = Instance.new("TextLabel", f)
    ic.Size = UDim2.new(0, 24, 0, 20)
    ic.Position = UDim2.new(0, 10, 0, 6)
    ic.BackgroundTransparency = 1
    ic.Text = icon
    ic.TextSize = 14
    ic.ZIndex = 203

    local nm = Instance.new("TextLabel", f)
    nm.Size = UDim2.new(0.5, -30, 0, 20)
    nm.Position = UDim2.new(0, 36, 0, 6)
    nm.BackgroundTransparency = 1
    nm.Text = name
    nm.TextColor3 = C.text
    nm.TextSize = 12
    nm.Font = Enum.Font.GothamMedium
    nm.TextXAlignment = Enum.TextXAlignment.Left
    nm.ZIndex = 203

    local valLbl = Instance.new("TextLabel", f)
    valLbl.Size = UDim2.new(0, 50, 0, 20)
    valLbl.Position = UDim2.new(1, -58, 0, 6)
    valLbl.BackgroundTransparency = 1
    valLbl.TextColor3 = C.accent
    valLbl.TextSize = 12
    valLbl.Font = Enum.Font.GothamBold
    valLbl.TextXAlignment = Enum.TextXAlignment.Right
    valLbl.ZIndex = 203

    local track = Instance.new("Frame", f)
    track.Size = UDim2.new(1, -24, 0, 8)
    track.Position = UDim2.new(0, 12, 0, 36)
    track.BackgroundColor3 = C.bg4
    track.ZIndex = 203
    Corner(track, 4)

    local pct = (default - min) / (max - min)

    local fill = Instance.new("Frame", track)
    fill.Size = UDim2.new(pct, 0, 1, 0)
    fill.BackgroundColor3 = C.accent
    fill.ZIndex = 204
    Corner(fill, 4)

    local kn = Instance.new("Frame", track)
    kn.Size = UDim2.new(0, 18, 0, 18)
    kn.Position = UDim2.new(pct, -9, 0.5, -9)
    kn.BackgroundColor3 = C.white
    kn.ZIndex = 205
    Corner(kn, 9)

    local function FormatVal(val)
        if showDecimal then
            return string.format("%.1f", val)
        else
            return tostring(math.floor(val))
        end
    end

    valLbl.Text = FormatVal(default)

    local function UpdateVal(val)
        val = math.clamp(val, min, max)
        local p = (val - min) / (max - min)
        fill.Size = UDim2.new(p, 0, 1, 0)
        kn.Position = UDim2.new(p, -9, 0.5, -9)
        valLbl.Text = FormatVal(val)
        callback(val)
    end

    local sliding = false

    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            sliding = true
            local rel = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            UpdateVal(min + (max - min) * rel)
        end
    end)
    kn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            sliding = true
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if sliding and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
            local rel = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            UpdateVal(min + (max - min) * rel)
        end
    end)
    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            sliding = false
        end
    end)

    return f, UpdateVal
end

-- ════════════════════════════════════════════════════════
-- VISION FUNCTIONS
-- ════════════════════════════════════════════════════════

local function SetFog(removed)
    State.FogRemoved = removed
    if removed then
        Lighting.FogStart = 9999999
        Lighting.FogEnd = 99999999
    else
        Lighting.FogStart = Original.FogStart
        Lighting.FogEnd = Original.FogEnd
    end
end

local function SetWeather(removed)
    State.WeatherRemoved = removed
    for _, v in pairs(Lighting:GetChildren()) do
        if v:IsA("Atmosphere") then
            v.Density = removed and 0 or 0.395
            v.Glare = removed and 0 or 0
            v.Haze = removed and 0 or 0
        end
    end
    pcall(function()
        for _, v in pairs(workspace.Terrain:GetChildren()) do
            if v:IsA("Clouds") then
                v.Enabled = not removed
            end
        end
    end)
end

local nvCC = nil
local function SetNightVision(on)
    State.NightVision = on
    if on then
        if not nvCC then
            nvCC = Instance.new("ColorCorrectionEffect")
            nvCC.Name = "NightVisionCC"
            nvCC.Parent = Lighting
        end
        nvCC.Enabled = true
        nvCC.Brightness = 0.15
        nvCC.Contrast = 0.1
        nvCC.Saturation = -0.6
        nvCC.TintColor = Color3.fromRGB(120, 255, 120)
    else
        if nvCC then nvCC.Enabled = false end
    end
end

local function SetFullBright(on)
    State.FullBright = on
    if on then
        Lighting.Brightness = 3
        Lighting.Ambient = Color3.fromRGB(200, 200, 200)
        Lighting.OutdoorAmbient = Color3.fromRGB(200, 200, 200)
        Lighting.EnvironmentDiffuseScale = 1
        Lighting.EnvironmentSpecularScale = 1
    else
        Lighting.Brightness = Original.Brightness
        Lighting.Ambient = Original.Ambient
        Lighting.OutdoorAmbient = Original.OutdoorAmbient
        Lighting.EnvironmentDiffuseScale = Original.EnvironmentDiffuseScale
        Lighting.EnvironmentSpecularScale = Original.EnvironmentSpecularScale
    end
end

local function SetNoShadows(on)
    State.NoShadows = on
    Lighting.GlobalShadows = not on
end

local function SetNoEffects(on)
    State.NoEffects = on
    for v, orig in pairs(OriginalEffects) do
        if v and v.Parent then
            v.Enabled = on and false or orig
        end
    end
end

local function SetNoParticles(on)
    State.NoParticles = on
    for _, v in pairs(workspace:GetDescendants()) do
        pcall(function()
            if v:IsA("ParticleEmitter") or v:IsA("Smoke") or v:IsA("Fire") or v:IsA("Sparkles") then
                v.Enabled = not on
            end
        end)
    end
end

local zoomConn = nil

local function SetUnlimitedZoom(on)
    State.UnlimitedZoom = on
    if on then
        LP.CameraMinZoomDistance = 0.5
        LP.CameraMaxZoomDistance = State.MaxZoom
        if zoomConn then zoomConn:Disconnect() end
        zoomConn = RunService.Heartbeat:Connect(function()
            if State.UnlimitedZoom then
                if LP.CameraMaxZoomDistance ~= State.MaxZoom then
                    LP.CameraMaxZoomDistance = State.MaxZoom
                end
                if LP.CameraMinZoomDistance ~= 0.5 then
                    LP.CameraMinZoomDistance = 0.5
                end
            end
        end)
    else
        if zoomConn then
            zoomConn:Disconnect()
            zoomConn = nil
        end
        LP.CameraMinZoomDistance = OriginalZoom.MinDistance
        LP.CameraMaxZoomDistance = OriginalZoom.MaxDistance
    end
end

local function SetMaxZoom(val)
    State.MaxZoom = val
    if State.UnlimitedZoom then
        LP.CameraMaxZoomDistance = val
    end
end

local function SetFOV(val)
    State.FOV = val
    Camera.FieldOfView = val
end

local timeConn = nil

local function SetTimeLock(on)
    State.TimeLocked = on
    if on then
        if timeConn then timeConn:Disconnect() end
        timeConn = RunService.Heartbeat:Connect(function()
            Lighting.ClockTime = State.LockTime
        end)
    else
        if timeConn then
            timeConn:Disconnect()
            timeConn = nil
        end
        Lighting.ClockTime = Original.ClockTime
    end
end

local function SetTime(t)
    State.LockTime = t
    Lighting.ClockTime = t
end

-- ═══════════════════════════════════════════════════════
-- SPEED FUNCTIONS
-- ═══════════════════════════════════════════════════════
local speedConn = nil
local speedDisplayLabel = nil

local function GetHumanoid()
    local char = LP.Character
    if char then
        return char:FindFirstChildOfClass("Humanoid")
    end
    return nil
end

local function ApplySpeed()
    local hum = GetHumanoid()
    if not hum then return end
    if State.SpeedEnabled then
        if State.SpeedBoosted then
            hum.WalkSpeed = State.BoostSpeed
        else
            hum.WalkSpeed = State.NormalSpeed
        end
    end
end

local function SetSpeedEnabled(on)
    State.SpeedEnabled = on
    if on then
        ApplySpeed()
        if speedConn then speedConn:Disconnect() end
        speedConn = RunService.Heartbeat:Connect(function()
            if State.SpeedEnabled then
                local hum = GetHumanoid()
                if hum then
                    local target = State.SpeedBoosted and State.BoostSpeed or State.NormalSpeed
                    if hum.WalkSpeed ~= target then
                        hum.WalkSpeed = target
                    end
                end
            end
        end)
    else
        if speedConn then
            speedConn:Disconnect()
            speedConn = nil
        end
        local hum = GetHumanoid()
        if hum then
            hum.WalkSpeed = OriginalSpeed
        end
    end
end

local function SetSpeedBoosted(on)
    State.SpeedBoosted = on
    ApplySpeed()
end

local function SetNormalSpeed(val)
    State.NormalSpeed = val
    if State.SpeedEnabled and not State.SpeedBoosted then
        ApplySpeed()
    end
end

local function SetBoostSpeed(val)
    State.BoostSpeed = val
    if State.SpeedEnabled and State.SpeedBoosted then
        ApplySpeed()
    end
end

LP.CharacterAdded:Connect(function(char)
    char:WaitForChild("Humanoid")
    task.wait(0.5)
    if State.SpeedEnabled then
        ApplySpeed()
    end
end)

-- ════════════════════════════════════════════════════════
-- BUILD GUI CONTROLS
-- ════════════════════════════════════════════════════════

MakeSection(Scroll, "FOG & WEATHER", "🌫️")

MakeToggle(Scroll, "Remove Fog", "🌁", C.accent, false, function(on)
    SetFog(on)
end)

MakeToggle(Scroll, "Remove Weather/Clouds", "⛈️", C.accent, false, function(on)
    SetWeather(on)
end)

MakeToggle(Scroll, "No Particles/Smoke", "💨", C.accent, false, function(on)
    SetNoParticles(on)
end)

MakeSection(Scroll, "CAMERA & ZOOM", "🔭")

local _, zoomToggleSet
_, zoomToggleSet = MakeToggle(Scroll, "Unlimited Zoom", "🔍", C.cyan, false, function(on)
    SetUnlimitedZoom(on)
end)

local _, maxZoomUpdate = MakeSlider(Scroll, "Max Zoom Distance", "📏", 50, 2000, 500, false, function(val)
    SetMaxZoom(val)
end)

local _, fovUpdate = MakeSlider(Scroll, "Field of View", "👁", 20, 120, 70, false, function(val)
    SetFOV(val)
end)

local zoomPresetFrame = Instance.new("Frame", Scroll)
zoomPresetFrame.Size = UDim2.new(1, 0, 0, 40)
zoomPresetFrame.BackgroundTransparency = 1
zoomPresetFrame.ZIndex = 202

local zpLayout = Instance.new("UIListLayout", zoomPresetFrame)
zpLayout.FillDirection = Enum.FillDirection.Horizontal
zpLayout.Padding = UDim.new(0, 5)

local zoomPresets = {
    {name = "🔬 Close",  zoom = 50,   fov = 70},
    {name = "👤 Normal", zoom = 128,  fov = 70},
    {name = "🏠 Far",    zoom = 500,  fov = 70},
    {name = "🗺️ Ultra",  zoom = 2000, fov = 90},
}

for _, preset in ipairs(zoomPresets) do
    local btn = Instance.new("TextButton", zoomPresetFrame)
    btn.Size = UDim2.new(0.25, -4, 1, 0)
    btn.BackgroundColor3 = C.bg3
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.ZIndex = 203
    Corner(btn, 8)
    Stroke(btn, C.border, 1, 0.6)

    local lbl = Instance.new("TextLabel", btn)
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = preset.name
    lbl.TextColor3 = C.text2
    lbl.TextSize = isMobile and 9 or 10
    lbl.Font = Enum.Font.GothamMedium
    lbl.ZIndex = 204

    btn.MouseEnter:Connect(function()
        Tw(btn, 0.12, {BackgroundColor3 = C.cyan})
        Tw(lbl, 0.12, {TextColor3 = C.white})
    end)
    btn.MouseLeave:Connect(function()
        Tw(btn, 0.12, {BackgroundColor3 = C.bg3})
        Tw(lbl, 0.12, {TextColor3 = C.text2})
    end)

    btn.MouseButton1Click:Connect(function()
        if not State.UnlimitedZoom then
            zoomToggleSet(true)
        end
        SetMaxZoom(preset.zoom)
        SetFOV(preset.fov)
        maxZoomUpdate(preset.zoom)
        fovUpdate(preset.fov)

        Tw(btn, 0.1, {BackgroundColor3 = C.green})
        task.wait(0.3)
        Tw(btn, 0.2, {BackgroundColor3 = C.bg3})
    end)
end

MakeSection(Scroll, "LIGHTING", "☀️")

MakeToggle(Scroll, "Fullbright", "💡", C.yellow, false, function(on)
    SetFullBright(on)
end)

MakeToggle(Scroll, "Night Vision", "🌙", C.green, false, function(on)
    SetNightVision(on)
end)

MakeToggle(Scroll, "No Shadows", "🔲", C.orange, false, function(on)
    SetNoShadows(on)
end)

MakeToggle(Scroll, "No Post Effects", "✨", C.purple, false, function(on)
    SetNoEffects(on)
end)

MakeSection(Scroll, "TIME CONTROL", "🕐")

local _, timeSliderUpdate = MakeSlider(Scroll, "Set Time", "☀️", 0, 24, 12, true, function(val)
    SetTime(val)
end)

MakeToggle(Scroll, "Lock Time", "🔒", C.orange, false, function(on)
    SetTimeLock(on)
end)

MakeSection(Scroll, "QUICK TIME", "⚡")

local presetFrame = Instance.new("Frame", Scroll)
presetFrame.Size = UDim2.new(1, 0, 0, 40)
presetFrame.BackgroundTransparency = 1
presetFrame.ZIndex = 202

local presetLayout = Instance.new("UIListLayout", presetFrame)
presetLayout.FillDirection = Enum.FillDirection.Horizontal
presetLayout.Padding = UDim.new(0, 6)

local timePresets = {
    {name = "🌅 Dawn",  time = 6,   color = C.orange},
    {name = "☀️ Noon",  time = 12,  color = C.yellow},
    {name = "🌆 Dusk",  time = 18,  color = C.purple},
    {name = "🌙 Night", time = 0,   color = C.accentDark},
}

for _, preset in ipairs(timePresets) do
    local btn = Instance.new("TextButton", presetFrame)
    btn.Size = UDim2.new(0.25, -5, 1, 0)
    btn.BackgroundColor3 = C.bg3
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.ZIndex = 203
    Corner(btn, 8)
    Stroke(btn, C.border, 1, 0.6)

    local lbl = Instance.new("TextLabel", btn)
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = preset.name
    lbl.TextColor3 = C.text2
    lbl.TextSize = isMobile and 10 or 11
    lbl.Font = Enum.Font.GothamMedium
    lbl.ZIndex = 204

    btn.MouseEnter:Connect(function()
        Tw(btn, 0.12, {BackgroundColor3 = preset.color})
        Tw(lbl, 0.12, {TextColor3 = C.white})
    end)
    btn.MouseLeave:Connect(function()
        Tw(btn, 0.12, {BackgroundColor3 = C.bg3})
        Tw(lbl, 0.12, {TextColor3 = C.text2})
    end)

    btn.MouseButton1Click:Connect(function()
        SetTime(preset.time)
        timeSliderUpdate(preset.time)
        Tw(btn, 0.1, {BackgroundColor3 = C.green})
        task.wait(0.3)
        Tw(btn, 0.2, {BackgroundColor3 = C.bg3})
    end)
end

-- ═══════════════════════════════════════════════════════
-- 🏃 SPEED CONTROL
-- ═══════════════════════════════════════════════════════
MakeSection(Scroll, "SPEED CONTROL", "🏃")

local speedInfoFrame = Instance.new("Frame", Scroll)
speedInfoFrame.Size = UDim2.new(1, 0, 0, 36)
speedInfoFrame.BackgroundColor3 = C.bg2
speedInfoFrame.ZIndex = 202
Corner(speedInfoFrame, 10)
Stroke(speedInfoFrame, C.border, 1, 0.5)

local speedInfoIcon = Instance.new("TextLabel", speedInfoFrame)
speedInfoIcon.Size = UDim2.new(0, 28, 1, 0)
speedInfoIcon.Position = UDim2.new(0, 10, 0, 0)
speedInfoIcon.BackgroundTransparency = 1
speedInfoIcon.Text = "📊"
speedInfoIcon.TextSize = 14
speedInfoIcon.ZIndex = 203

speedDisplayLabel = Instance.new("TextLabel", speedInfoFrame)
speedDisplayLabel.Size = UDim2.new(1, -50, 1, 0)
speedDisplayLabel.Position = UDim2.new(0, 40, 0, 0)
speedDisplayLabel.BackgroundTransparency = 1
speedDisplayLabel.Text = "Current: " .. OriginalSpeed .. " studs/s"
speedDisplayLabel.TextColor3 = C.text2
speedDisplayLabel.TextSize = 12
speedDisplayLabel.Font = Enum.Font.GothamMedium
speedDisplayLabel.TextXAlignment = Enum.TextXAlignment.Left
speedDisplayLabel.ZIndex = 203

local _, speedToggleSet
_, speedToggleSet = MakeToggle(Scroll, "Enable Speed Control", "⚡", C.green, false, function(on)
    SetSpeedEnabled(on)
end)

local _, boostToggleSet
_, boostToggleSet = MakeToggle(Scroll, "Speed Boost (Sprint)", "🚀", C.orange, false, function(on)
    SetSpeedBoosted(on)
end)

local _, normalSpeedUpdate = MakeSlider(Scroll, "Normal Speed", "🚶", 10, 30, 17, false, function(val)
    SetNormalSpeed(val)
end)

local _, boostSpeedUpdate = MakeSlider(Scroll, "Boost Speed", "🏃", 15, 40, 21, false, function(val)
    SetBoostSpeed(val)
end)

local speedPresetFrame = Instance.new("Frame", Scroll)
speedPresetFrame.Size = UDim2.new(1, 0, 0, 40)
speedPresetFrame.BackgroundTransparency = 1
speedPresetFrame.ZIndex = 202

local spLayout = Instance.new("UIListLayout", speedPresetFrame)
spLayout.FillDirection = Enum.FillDirection.Horizontal
spLayout.Padding = UDim.new(0, 5)

local speedPresets = {
    {name = "🐌 16/20", normal = 16, boost = 20, color = C.accent},
    {name = "🚶 17/21", normal = 17, boost = 21, color = C.green},
    {name = "🏃 18/23", normal = 18, boost = 23, color = C.yellow},
    {name = "⚡ 19/25", normal = 19, boost = 25, color = C.orange},
}

for _, preset in ipairs(speedPresets) do
    local btn = Instance.new("TextButton", speedPresetFrame)
    btn.Size = UDim2.new(0.25, -4, 1, 0)
    btn.BackgroundColor3 = C.bg3
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.ZIndex = 203
    Corner(btn, 8)
    Stroke(btn, C.border, 1, 0.6)

    local lbl = Instance.new("TextLabel", btn)
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = preset.name
    lbl.TextColor3 = C.text2
    lbl.TextSize = isMobile and 9 or 10
    lbl.Font = Enum.Font.GothamMedium
    lbl.ZIndex = 204

    btn.MouseEnter:Connect(function()
        Tw(btn, 0.12, {BackgroundColor3 = preset.color})
        Tw(lbl, 0.12, {TextColor3 = C.white})
    end)
    btn.MouseLeave:Connect(function()
        Tw(btn, 0.12, {BackgroundColor3 = C.bg3})
        Tw(lbl, 0.12, {TextColor3 = C.text2})
    end)

    btn.MouseButton1Click:Connect(function()
        if not State.SpeedEnabled then
            speedToggleSet(true)
        end
        SetNormalSpeed(preset.normal)
        SetBoostSpeed(preset.boost)
        normalSpeedUpdate(preset.normal)
        boostSpeedUpdate(preset.boost)

        Tw(btn, 0.1, {BackgroundColor3 = C.green})
        task.wait(0.3)
        Tw(btn, 0.2, {BackgroundColor3 = C.bg3})
    end)
end

-- Speed display updater
RunService.Heartbeat:Connect(function()
    if speedDisplayLabel then
        local hum = GetHumanoid()
        if hum then
            local spd = math.floor(hum.WalkSpeed)
            local status = ""
            if State.SpeedEnabled then
                if State.SpeedBoosted then
                    status = "  🚀 BOOST"
                    speedDisplayLabel.TextColor3 = C.orange
                else
                    status = "  ⚡ ACTIVE"
                    speedDisplayLabel.TextColor3 = C.green
                end
            else
                status = "  ⏸️ OFF"
                speedDisplayLabel.TextColor3 = C.text3
            end
            speedDisplayLabel.Text = "Current: " .. spd .. " studs/s" .. status
        end
    end
end)

-- 🔄 RESTORE ALL
MakeSection(Scroll, "RESTORE", "🔄")

local restoreBtn = Instance.new("TextButton", Scroll)
restoreBtn.Size = UDim2.new(1, 0, 0, 42)
restoreBtn.BackgroundColor3 = C.bg2
restoreBtn.Text = ""
restoreBtn.AutoButtonColor = false
restoreBtn.ZIndex = 202
Corner(restoreBtn, 10)
Stroke(restoreBtn, C.border, 1, 0.5)

local restoreLbl = Instance.new("TextLabel", restoreBtn)
restoreLbl.Size = UDim2.new(1, 0, 1, 0)
restoreLbl.BackgroundTransparency = 1
restoreLbl.Text = "🔄  Restore All to Default"
restoreLbl.TextColor3 = C.text2
restoreLbl.TextSize = 12
restoreLbl.Font = Enum.Font.GothamMedium
restoreLbl.ZIndex = 203

restoreBtn.MouseEnter:Connect(function()
    Tw(restoreBtn, 0.12, {BackgroundColor3 = C.bg3})
end)
restoreBtn.MouseLeave:Connect(function()
    Tw(restoreBtn, 0.12, {BackgroundColor3 = C.bg2})
end)

restoreBtn.MouseButton1Click:Connect(function()
    SetFog(false)
    SetWeather(false)
    SetNightVision(false)
    SetFullBright(false)
    SetNoShadows(false)
    SetNoEffects(false)
    SetNoParticles(false)
    SetTimeLock(false)
    SetUnlimitedZoom(false)
    SetTime(Original.ClockTime)
    SetFOV(OriginalZoom.FOV)
    SetSpeedEnabled(false)
    SetSpeedBoosted(false)
    speedToggleSet(false)
    boostToggleSet(false)
    normalSpeedUpdate(17)
    boostSpeedUpdate(21)
    timeSliderUpdate(Original.ClockTime)
    maxZoomUpdate(OriginalZoom.MaxDistance)
    fovUpdate(OriginalZoom.FOV)

    Lighting.FogColor = Original.FogColor
    Lighting.ExposureCompensation = Original.ExposureCompensation

    Tw(restoreBtn, 0.1, {BackgroundColor3 = C.green})
    restoreLbl.Text = "✅  All Restored!"
    task.wait(1)
    restoreLbl.Text = "🔄  Restore All to Default"
    Tw(restoreBtn, 0.2, {BackgroundColor3 = C.bg2})
end)

local spacer = Instance.new("Frame", Scroll)
spacer.Size = UDim2.new(1, 0, 0, 10)
spacer.BackgroundTransparency = 1

-- ════════════════════════════════════════════════════════
-- PANEL OPEN/CLOSE
-- ════════════════════════════════════════════════════════
local function OpenPanel()
    panelOpen = true
    Panel.Visible = true
    Panel.Size = UDim2.new(0, PW, 0, 0)
    Tw(Panel, 0.35, {Size = UDim2.new(0, PW, 0, PH)})
end

local function ClosePanel()
    panelOpen = false
    Tw(Panel, 0.25, {Size = UDim2.new(0, PW, 0, 0)})
    task.delay(0.25, function() Panel.Visible = false end)
end

ToggleBtn.MouseButton1Click:Connect(function()
    if panelOpen then ClosePanel() else OpenPanel() end
end)

xBtn.MouseButton1Click:Connect(function()
    ClosePanel()
end)

-- ════════════════════════════════════════════════════════
-- KEYBOARD SHORTCUT (HANYA V UNTUK TOGGLE PANEL)
-- ════════════════════════════════════════════════════════
if not isMobile then
    UIS.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == Enum.KeyCode.V then
            if panelOpen then ClosePanel() else OpenPanel() end
        end
    end)
end

-- ════════════════════════════════════════════════════════
-- FOV MONITOR
-- ════════════════════════════════════════════════════════
RunService.Heartbeat:Connect(function()
    if State.FOV ~= 70 then
        if Camera.FieldOfView ~= State.FOV then
            Camera.FieldOfView = State.FOV
        end
    end
end)

print("✅ Vision Control + Speed Control loaded!")
print("👁 Tap tombol mata untuk buka menu")
print("🔒 Semua perubahan LOCAL / Client-Side")
print("🏃 Speed: Normal = 17 | Boost = 21 (toggle di UI)")
if not isMobile then
    print("⌨️ Tekan V untuk toggle menu")
end
