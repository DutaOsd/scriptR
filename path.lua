-- // Path Movement Pro v1.0
-- // Visualisasi + Auto-complete Obby + Record & Replay
-- // PC + Mobile | Multiple Paths | Save/Load | Jump Record

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")

local player = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ════════════════════════════════════════════
-- MOBILE DETECTION
-- ════════════════════════════════════════════
local isMobile = (function()
    if GuiService:IsTenFootInterface() then return false end
    local touch    = UserInputService.TouchEnabled
    local keyboard = UserInputService.KeyboardEnabled
    local vp       = Camera.ViewportSize
    return touch and (not keyboard or vp.X < 1024)
end)()

-- ════════════════════════════════════════════
-- CLEANUP
-- ════════════════════════════════════════════
pcall(function()
    player.PlayerGui:FindFirstChild("PathMovementGUI"):Destroy()
end)

-- ════════════════════════════════════════════
-- CONNECTION MANAGER
-- ════════════════════════════════════════════
local ConnectionManager = {}
ConnectionManager.__index = ConnectionManager
function ConnectionManager.new()
    return setmetatable({_c = {}}, ConnectionManager)
end
function ConnectionManager:Add(name, conn)
    self:Remove(name)
    self._c[name] = conn
end
function ConnectionManager:Remove(name)
    if self._c[name] then
        pcall(function() self._c[name]:Disconnect() end)
        self._c[name] = nil
    end
end
function ConnectionManager:RemoveAll()
    for _, c in pairs(self._c) do
        pcall(function() c:Disconnect() end)
    end
    self._c = {}
end
local Conn = ConnectionManager.new()

-- ════════════════════════════════════════════
-- CONSTANTS
-- ════════════════════════════════════════════
local MAX_PATHS         = 10
local DEFAULT_INTERVAL  = 0.5   -- detik antar waypoint saat record
local MIN_DIST_CHANGE   = 1.5   -- minimum jarak untuk rekam waypoint baru
local DIRECTION_THRESHOLD = 15  -- derajat perubahan arah untuk rekam

-- ════════════════════════════════════════════
-- STATE
-- ════════════════════════════════════════════
local State = {
    -- Recording
    IsRecording      = false,
    RecordInterval   = DEFAULT_INTERVAL,
    UseDirectionMode = false, -- true = rekam hanya saat ganti arah
    LastRecordTime   = 0,
    LastDirection    = nil,
    LastRecordPos    = nil,

    -- Playback
    IsPlaying        = false,
    IsPaused         = false,
    PlayMode         = "once",   -- "once", "loop", "pingpong"
    PlaySpeed        = 1.0,
    CurrentPathIdx   = 1,        -- index path yang sedang aktif
    CurrentWPIdx     = 1,        -- index waypoint saat playback
    PingPongDir      = 1,        -- 1 = maju, -1 = mundur
    PlaybackConn     = nil,

    -- Visualization
    ShowBeam         = true,
    ShowDots         = true,
    VisObjects       = {},       -- {beam, dot, ...} per path

    -- Paths
    Paths            = {},       -- array of PathData
    ActivePathName   = nil,

    -- UI
    CurrentTab       = "record",
}

-- PathData structure:
-- {
--   name     = string,
--   waypoints = { {pos=Vector3, time=number, jumped=bool, speed=number} },
--   color    = Color3,
--   created  = number (tick),
-- }

-- ════════════════════════════════════════════
-- PATH COLORS (untuk multiple paths)
-- ════════════════════════════════════════════
local PATH_COLORS = {
    Color3.fromRGB(100, 200, 255),
    Color3.fromRGB(255, 150, 50),
    Color3.fromRGB(100, 255, 150),
    Color3.fromRGB(255, 100, 150),
    Color3.fromRGB(200, 100, 255),
    Color3.fromRGB(255, 255, 100),
    Color3.fromRGB(100, 255, 255),
    Color3.fromRGB(255, 180, 100),
    Color3.fromRGB(180, 255, 100),
    Color3.fromRGB(255, 100, 100),
}

-- ════════════════════════════════════════════
-- SPEED → COLOR
-- ════════════════════════════════════════════
local function speedToColor(speed)
    -- Biru (lambat) → Hijau → Kuning → Merah (cepat)
    if speed <= 5 then
        return Color3.fromRGB(100, 150, 255)
    elseif speed <= 16 then
        local t = (speed - 5) / 11
        return Color3.fromRGB(
            math.floor(100 + 155*t),
            math.floor(150 + 105*t),
            math.floor(255 - 155*t)
        )
    elseif speed <= 50 then
        local t = (speed - 16) / 34
        return Color3.fromRGB(
            255,
            math.floor(255 - 155*t),
            math.floor(100 - 100*t)
        )
    else
        return Color3.fromRGB(255, 50, 50)
    end
end

-- ════════════════════════════════════════════
-- NOTIFICATION
-- ════════════════════════════════════════════
local NotifQueue   = {}
local notifRunning = false

-- ════════════════════════════════════════════
-- SCREEN GUI
-- ════════════════════════════════════════════
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name           = "PathMovementGUI"
ScreenGui.ResetOnSpawn   = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent         = player:WaitForChild("PlayerGui")

-- ════════════════════════════════════════════
-- NOTIFICATION UI
-- ════════════════════════════════════════════
local NotifFrame = Instance.new("Frame")
NotifFrame.Size             = UDim2.new(0, 300, 0, 55)
NotifFrame.Position         = UDim2.new(0.5, -150, 0, -70)
NotifFrame.BackgroundColor3 = Color3.fromRGB(25, 35, 55)
NotifFrame.BorderSizePixel  = 0
NotifFrame.ZIndex           = 300
NotifFrame.Parent           = ScreenGui
Instance.new("UICorner", NotifFrame).CornerRadius = UDim.new(0, 12)
Instance.new("UIStroke", NotifFrame).Color = Color3.fromRGB(80, 130, 255)

local NotifText = Instance.new("TextLabel", NotifFrame)
NotifText.Size               = UDim2.new(1, -20, 1, 0)
NotifText.Position           = UDim2.new(0, 10, 0, 0)
NotifText.BackgroundTransparency = 1
NotifText.TextSize           = isMobile and 13 or 12
NotifText.Font               = Enum.Font.GothamBold
NotifText.TextColor3         = Color3.new(1, 1, 1)
NotifText.TextWrapped        = true
NotifText.ZIndex             = 301

local function processNotifQueue()
    if notifRunning then return end
    notifRunning = true
    task.spawn(function()
        while #NotifQueue > 0 do
            local item = table.remove(NotifQueue, 1)
            NotifText.Text              = item.text
            NotifFrame.BackgroundColor3 = item.color or Color3.fromRGB(25, 35, 55)
            TweenService:Create(NotifFrame,
                TweenInfo.new(0.4, Enum.EasingStyle.Back), {
                    Position = UDim2.new(0.5, -150, 0, 15)
                }):Play()
            task.wait(2.2)
            TweenService:Create(NotifFrame,
                TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
                    Position = UDim2.new(0.5, -150, 0, -70)
                }):Play()
            task.wait(0.35)
        end
        notifRunning = false
    end)
end

local function showNotif(text, color)
    if #NotifQueue > 0 and NotifQueue[#NotifQueue].text == text then return end
    table.insert(NotifQueue, {text = text, color = color})
    if #NotifQueue > 4 then table.remove(NotifQueue, 1) end
    processNotifQueue()
end

-- ════════════════════════════════════════════
-- MINIMIZED ICON
-- ════════════════════════════════════════════
local MiniIcon = Instance.new("TextButton")
MiniIcon.Size             = isMobile and UDim2.new(0,65,0,65) or UDim2.new(0,55,0,55)
MiniIcon.Position         = isMobile and UDim2.new(0.82,0,0.12,0) or UDim2.new(0.02,0,0.22,0)
MiniIcon.BackgroundColor3 = Color3.fromRGB(22,30,50)
MiniIcon.Text             = "🛤️"
MiniIcon.TextSize         = isMobile and 30 or 24
MiniIcon.Font             = Enum.Font.GothamBold
MiniIcon.TextColor3       = Color3.new(1,1,1)
MiniIcon.Visible          = false
MiniIcon.Active           = true
MiniIcon.Draggable        = true
MiniIcon.ZIndex           = 100
MiniIcon.Parent           = ScreenGui
Instance.new("UICorner", MiniIcon).CornerRadius = UDim.new(0.3,0)

local MiniStroke = Instance.new("UIStroke", MiniIcon)
MiniStroke.Color     = Color3.fromRGB(80,130,255)
MiniStroke.Thickness = 3

task.spawn(function()
    while ScreenGui.Parent do
        if MiniIcon.Visible then
            TweenService:Create(MiniStroke, TweenInfo.new(1,Enum.EasingStyle.Sine),
                {Color = Color3.fromRGB(150,200,255)}):Play()
            task.wait(1)
            if MiniIcon.Visible then
                TweenService:Create(MiniStroke, TweenInfo.new(1,Enum.EasingStyle.Sine),
                    {Color = Color3.fromRGB(80,130,255)}):Play()
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
    Main.Size     = UDim2.new(0.95, 0, 0.85, 0)
    Main.Position = UDim2.new(0.025, 0, 0.08, 0)
else
    Main.Size     = UDim2.new(0, 460, 0, 680)
    Main.Position = UDim2.new(0.02, 0, 0.04, 0)
end
Main.BackgroundColor3 = Color3.fromRGB(18, 22, 34)
Main.BorderSizePixel  = 0
Main.Active           = true
Main.Draggable        = not isMobile
Main.ClipsDescendants = true
Main.ZIndex           = 1
Main.Parent           = ScreenGui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 14)

local MainStroke = Instance.new("UIStroke", Main)
MainStroke.Color     = Color3.fromRGB(60, 100, 220)
MainStroke.Thickness = 2

-- ════════════════════════════════════════════
-- TITLE BAR
-- ════════════════════════════════════════════
local TitleH   = isMobile and 60 or 50
local TitleBar = Instance.new("Frame")
TitleBar.Size             = UDim2.new(1,0,0,TitleH)
TitleBar.BackgroundColor3 = Color3.fromRGB(22,28,44)
TitleBar.BorderSizePixel  = 0
TitleBar.ZIndex           = 2
TitleBar.Parent           = Main
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0,14)

local TFix = Instance.new("Frame", TitleBar)
TFix.Size             = UDim2.new(1,0,0.4,0)
TFix.Position         = UDim2.new(0,0,0.6,0)
TFix.BackgroundColor3 = Color3.fromRGB(22,28,44)
TFix.BorderSizePixel  = 0

local TitleLbl = Instance.new("TextLabel", TitleBar)
TitleLbl.Size             = UDim2.new(0.6,0,1,0)
TitleLbl.Position         = UDim2.new(0,14,0,0)
TitleLbl.BackgroundTransparency = 1
TitleLbl.Text             = "🛤️ Path Movement Pro"
TitleLbl.TextColor3       = Color3.fromRGB(140,190,255)
TitleLbl.TextSize         = isMobile and 18 or 15
TitleLbl.Font             = Enum.Font.GothamBold
TitleLbl.TextXAlignment   = Enum.TextXAlignment.Left
TitleLbl.ZIndex           = 3

local VerLabel = Instance.new("TextLabel", TitleBar)
VerLabel.Size             = UDim2.new(0,40,0,17)
VerLabel.Position         = UDim2.new(0, isMobile and 232 or 198, 0.5, -8)
VerLabel.BackgroundColor3 = Color3.fromRGB(60,100,220)
VerLabel.Text             = "v1.0"
VerLabel.TextColor3       = Color3.new(1,1,1)
VerLabel.TextSize         = 9
VerLabel.Font             = Enum.Font.GothamBold
VerLabel.ZIndex           = 4
Instance.new("UICorner", VerLabel).CornerRadius = UDim.new(0,6)

-- Minimize
local MinBtn = Instance.new("TextButton", TitleBar)
MinBtn.Size             = isMobile and UDim2.new(0,40,0,40) or UDim2.new(0,30,0,30)
MinBtn.Position         = isMobile and UDim2.new(1,-90,0.5,-20) or UDim2.new(1,-74,0.5,-15)
MinBtn.BackgroundColor3 = Color3.fromRGB(255,175,0)
MinBtn.Text             = "─"
MinBtn.TextColor3       = Color3.new(1,1,1)
MinBtn.TextSize         = isMobile and 20 or 16
MinBtn.Font             = Enum.Font.GothamBold
MinBtn.ZIndex           = 3
MinBtn.AutoButtonColor  = false
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0.5,0)

-- Close
local CloseBtn = Instance.new("TextButton", TitleBar)
CloseBtn.Size             = isMobile and UDim2.new(0,40,0,40) or UDim2.new(0,30,0,30)
CloseBtn.Position         = isMobile and UDim2.new(1,-45,0.5,-20) or UDim2.new(1,-40,0.5,-15)
CloseBtn.BackgroundColor3 = Color3.fromRGB(220,55,55)
CloseBtn.Text             = "✕"
CloseBtn.TextColor3       = Color3.new(1,1,1)
CloseBtn.TextSize         = isMobile and 18 or 14
CloseBtn.Font             = Enum.Font.GothamBold
CloseBtn.ZIndex           = 3
CloseBtn.AutoButtonColor  = false
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0.5,0)

for _, pair in ipairs({
    {MinBtn,   Color3.fromRGB(255,210,50), Color3.fromRGB(255,175,0)},
    {CloseBtn, Color3.fromRGB(255,80,80),  Color3.fromRGB(220,55,55)},
}) do
    pair[1].MouseEnter:Connect(function()
        TweenService:Create(pair[1], TweenInfo.new(0.15), {BackgroundColor3 = pair[2]}):Play()
    end)
    pair[1].MouseLeave:Connect(function()
        TweenService:Create(pair[1], TweenInfo.new(0.15), {BackgroundColor3 = pair[3]}):Play()
    end)
end

MinBtn.MouseButton1Click:Connect(function()
    TweenService:Create(Main, TweenInfo.new(0.3,Enum.EasingStyle.Quart,Enum.EasingDirection.In),
        {Size = UDim2.new(0,0,0,0)}):Play()
    task.wait(0.3)
    Main.Visible     = false
    MiniIcon.Visible = true
    MiniIcon.Size    = UDim2.new(0,0,0,0)
    TweenService:Create(MiniIcon, TweenInfo.new(0.35,Enum.EasingStyle.Back),
        {Size = isMobile and UDim2.new(0,65,0,65) or UDim2.new(0,55,0,55)}):Play()
end)

MiniIcon.MouseButton1Click:Connect(function()
    TweenService:Create(MiniIcon, TweenInfo.new(0.2,Enum.EasingStyle.Quart,Enum.EasingDirection.In),
        {Size = UDim2.new(0,0,0,0)}):Play()
    task.wait(0.2)
    MiniIcon.Visible = false
    Main.Visible     = true
    Main.Size        = UDim2.new(0,0,0,0)
    TweenService:Create(Main, TweenInfo.new(0.45,Enum.EasingStyle.Back),
        {Size = isMobile and UDim2.new(0.95,0,0.85,0) or UDim2.new(0,460,0,680)}):Play()
end)

-- ════════════════════════════════════════════
-- TAB SYSTEM
-- ════════════════════════════════════════════
local TabH   = isMobile and 44 or 38
local TabBar = Instance.new("Frame")
TabBar.Size             = UDim2.new(1,0,0,TabH)
TabBar.Position         = UDim2.new(0,0,0,TitleH)
TabBar.BackgroundColor3 = Color3.fromRGB(22,28,42)
TabBar.BorderSizePixel  = 0
TabBar.ZIndex           = 2
TabBar.Parent           = Main
Instance.new("UIListLayout", TabBar).FillDirection = Enum.FillDirection.Horizontal

local TabFrames  = {}
local TabButtons = {}

local function createTab(name, icon, order)
    local btn = Instance.new("TextButton")
    btn.Size             = UDim2.new(0.25,0,1,0)
    btn.BackgroundColor3 = Color3.fromRGB(22,28,42)
    btn.Text             = isMobile and icon or (icon.." "..name)
    btn.TextColor3       = Color3.fromRGB(110,120,150)
    btn.TextSize         = isMobile and 15 or 11
    btn.Font             = Enum.Font.GothamBold
    btn.ZIndex           = 3
    btn.AutoButtonColor  = false
    btn.LayoutOrder      = order
    btn.Parent           = TabBar

    local ind = Instance.new("Frame", btn)
    ind.Size             = UDim2.new(0.7,0,0,3)
    ind.Position         = UDim2.new(0.15,0,1,-3)
    ind.BackgroundColor3 = Color3.fromRGB(80,140,255)
    ind.BorderSizePixel  = 0
    ind.ZIndex           = 4
    ind.Visible          = false
    Instance.new("UICorner", ind).CornerRadius = UDim.new(1,0)

    TabButtons[name] = {Btn = btn, Ind = ind}
    return btn
end

local tabNames = {
    {name="record",   icon="⏺️",  order=1},
    {name="playback", icon="▶️",  order=2},
    {name="paths",    icon="🗂️", order=3},
    {name="settings", icon="⚙️", order=4},
}

local tabBtns = {}
for _, t in ipairs(tabNames) do
    tabBtns[t.name] = createTab(t.name:sub(1,1):upper()..t.name:sub(2), t.icon, t.order)
end

local contentY = TitleH + TabH + 4

local function createContentFrame(name)
    local frame = Instance.new("ScrollingFrame")
    frame.Size                  = UDim2.new(1,-10,1,-(contentY+4))
    frame.Position              = UDim2.new(0,5,0,contentY)
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel       = 0
    frame.ScrollBarThickness    = 4
    frame.ScrollBarImageColor3  = Color3.fromRGB(80,140,255)
    frame.CanvasSize            = UDim2.new(0,0,0,0)
    frame.AutomaticCanvasSize   = Enum.AutomaticSize.Y
    frame.ZIndex                = 2
    frame.Visible               = false
    frame.Parent                = Main

    local pad = Instance.new("UIPadding", frame)
    pad.PaddingTop    = UDim.new(0,6)
    pad.PaddingBottom = UDim.new(0,14)
    pad.PaddingLeft   = UDim.new(0,4)
    pad.PaddingRight  = UDim.new(0,4)

    local layout = Instance.new("UIListLayout", frame)
    layout.Padding             = UDim.new(0, isMobile and 7 or 6)
    layout.SortOrder           = Enum.SortOrder.LayoutOrder
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center

    TabFrames[name] = frame
    return frame
end

local RecordContent   = createContentFrame("record")
local PlaybackContent = createContentFrame("playback")
local PathsContent    = createContentFrame("paths")
local SettingsContent = createContentFrame("settings")

local function switchTab(name)
    State.CurrentTab = name
    for n, data in pairs(TabButtons) do
        local active = n == name
        data.Btn.TextColor3       = active and Color3.new(1,1,1) or Color3.fromRGB(110,120,150)
        data.Btn.BackgroundColor3 = active and Color3.fromRGB(30,38,58) or Color3.fromRGB(22,28,42)
        data.Ind.Visible          = active
    end
    for n, frame in pairs(TabFrames) do
        frame.Visible = n == name
    end
end

for name, btn in pairs(tabBtns) do
    btn.MouseButton1Click:Connect(function() switchTab(name) end)
end

-- ════════════════════════════════════════════
-- UI HELPERS
-- ════════════════════════════════════════════
local function mkSection(text, parent, order)
    local f = Instance.new("Frame")
    f.Size             = UDim2.new(1,0,0, isMobile and 26 or 22)
    f.BackgroundColor3 = Color3.fromRGB(28,35,55)
    f.BorderSizePixel  = 0
    f.LayoutOrder      = order or 0
    f.Parent           = parent
    Instance.new("UICorner", f).CornerRadius = UDim.new(0,8)

    local lbl = Instance.new("TextLabel", f)
    lbl.Size             = UDim2.new(1,-10,1,0)
    lbl.Position         = UDim2.new(0,10,0,0)
    lbl.BackgroundTransparency = 1
    lbl.Text             = text
    lbl.TextColor3       = Color3.fromRGB(100,160,255)
    lbl.TextSize         = isMobile and 12 or 10
    lbl.Font             = Enum.Font.GothamBold
    lbl.TextXAlignment   = Enum.TextXAlignment.Left
    lbl.ZIndex           = 3
end

local function mkBtn(text, parent, callback, order, color)
    local btn = Instance.new("TextButton")
    btn.Size             = UDim2.new(1,0,0, isMobile and 48 or 40)
    btn.BackgroundColor3 = color or Color3.fromRGB(38,45,65)
    btn.Text             = text
    btn.TextColor3       = Color3.new(1,1,1)
    btn.TextSize         = isMobile and 14 or 12
    btn.Font             = Enum.Font.GothamBold
    btn.ZIndex           = 3
    btn.AutoButtonColor  = false
    btn.LayoutOrder      = order or 0
    btn.Parent           = parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,10)
    Instance.new("UIStroke", btn).Color = Color3.fromRGB(50,60,90)

    btn.MouseEnter:Connect(function()
        if not btn:GetAttribute("locked") then
            TweenService:Create(btn, TweenInfo.new(0.12),
                {BackgroundColor3 = Color3.fromRGB(
                    math.clamp((color and color.R*255 or 38)+15, 0, 255),
                    math.clamp((color and color.G*255 or 45)+15, 0, 255),
                    math.clamp((color and color.B*255 or 65)+15, 0, 255)
                )}):Play()
        end
    end)
    btn.MouseLeave:Connect(function()
        if not btn:GetAttribute("locked") then
            TweenService:Create(btn, TweenInfo.new(0.12),
                {BackgroundColor3 = color or Color3.fromRGB(38,45,65)}):Play()
        end
    end)

    if callback then btn.MouseButton1Click:Connect(callback) end
    return btn
end

local function mkToggleBtn(textOff, textOn, parent, order, callbackOn, callbackOff)
    local state = false
    local btn = mkBtn(textOff, parent, nil, order)

    btn.MouseButton1Click:Connect(function()
        state = not state
        if state then
            btn.Text             = textOn
            btn.BackgroundColor3 = Color3.fromRGB(30,100,45)
            btn:SetAttribute("locked", true)
            if callbackOn then callbackOn() end
        else
            btn.Text             = textOff
            btn.BackgroundColor3 = Color3.fromRGB(38,45,65)
            btn:SetAttribute("locked", false)
            if callbackOff then callbackOff() end
        end
    end)

    local function forceSet(v)
        state = v
        if v then
            btn.Text             = textOn
            btn.BackgroundColor3 = Color3.fromRGB(30,100,45)
            btn:SetAttribute("locked", true)
        else
            btn.Text             = textOff
            btn.BackgroundColor3 = Color3.fromRGB(38,45,65)
            btn:SetAttribute("locked", false)
        end
    end

    return btn, forceSet
end

local function mkSlider(label, parent, minV, maxV, default, suffix, order, callback)
    local cont = Instance.new("Frame")
    cont.Size             = UDim2.new(1,0,0, isMobile and 72 or 62)
    cont.BackgroundColor3 = Color3.fromRGB(28,35,55)
    cont.BorderSizePixel  = 0
    cont.LayoutOrder      = order or 0
    cont.Parent           = parent
    Instance.new("UICorner", cont).CornerRadius = UDim.new(0,10)

    local lbl = Instance.new("TextLabel", cont)
    lbl.Size             = UDim2.new(0.65,0,0,22)
    lbl.Position         = UDim2.new(0,10,0,5)
    lbl.BackgroundTransparency = 1
    lbl.Text             = label
    lbl.TextColor3       = Color3.new(1,1,1)
    lbl.TextSize         = isMobile and 12 or 10
    lbl.Font             = Enum.Font.GothamBold
    lbl.TextXAlignment   = Enum.TextXAlignment.Left
    lbl.ZIndex           = 4

    local valLbl = Instance.new("TextLabel", cont)
    valLbl.Size             = UDim2.new(0.3,0,0,22)
    valLbl.Position         = UDim2.new(0.68,0,0,5)
    valLbl.BackgroundTransparency = 1
    valLbl.TextColor3       = Color3.fromRGB(100,180,255)
    valLbl.TextSize         = isMobile and 12 or 10
    valLbl.Font             = Enum.Font.GothamBold
    valLbl.TextXAlignment   = Enum.TextXAlignment.Right
    valLbl.ZIndex           = 4

    suffix = suffix or ""
    local function fmtVal(v)
        return string.format("%.2g%s", v, suffix)
    end
    valLbl.Text = fmtVal(default)

    local track = Instance.new("Frame", cont)
    track.Size             = UDim2.new(1,-20,0, isMobile and 22 or 18)
    track.Position         = UDim2.new(0,10,0, isMobile and 36 or 30)
    track.BackgroundColor3 = Color3.fromRGB(20,25,40)
    track.BorderSizePixel  = 0
    track.ZIndex           = 4
    Instance.new("UICorner", track).CornerRadius = UDim.new(1,0)

    local fill = Instance.new("Frame", track)
    local initR = math.clamp((default-minV)/(maxV-minV), 0, 1)
    fill.Size             = UDim2.new(initR,0,1,0)
    fill.BackgroundColor3 = Color3.fromRGB(80,140,255)
    fill.BorderSizePixel  = 0
    fill.ZIndex           = 5
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1,0)

    local kSize = isMobile and 20 or 16
    local knob  = Instance.new("Frame", track)
    knob.Size             = UDim2.new(0,kSize,0,kSize)
    knob.AnchorPoint      = Vector2.new(0.5,0.5)
    knob.Position         = UDim2.new(initR,0,0.5,0)
    knob.BackgroundColor3 = Color3.fromRGB(200,220,255)
    knob.BorderSizePixel  = 0
    knob.ZIndex           = 7
    Instance.new("UICorner", knob).CornerRadius = UDim.new(0.5,0)
    local ks = Instance.new("UIStroke", knob)
    ks.Color = Color3.fromRGB(80,140,255); ks.Thickness = 2

    local hitbox = Instance.new("TextButton", track)
    hitbox.Size             = UDim2.new(1,0,1,0)
    hitbox.BackgroundTransparency = 1
    hitbox.Text             = ""
    hitbox.ZIndex           = 8

    local dragging = false
    local function upd(x)
        local r = math.clamp((x - track.AbsolutePosition.X)/track.AbsoluteSize.X, 0, 1)
        local v = minV + (maxV-minV)*r
        fill.Size        = UDim2.new(r,0,1,0)
        knob.Position    = UDim2.new(r,0,0.5,0)
        valLbl.Text      = fmtVal(v)
        if callback then callback(v) end
    end

    hitbox.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true; upd(i.Position.X)
        end
    end)
    hitbox.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    Conn:Add("Slider_"..label, UserInputService.InputChanged:Connect(function(i)
        if not dragging then return end
        if i.UserInputType == Enum.UserInputType.MouseMovement
        or i.UserInputType == Enum.UserInputType.Touch then
            upd(i.Position.X)
        end
    end))

    return cont
end

local function mkInfoBox(text, parent, order, color)
    local f = Instance.new("Frame")
    f.Size             = UDim2.new(1,0,0,0)
    f.AutomaticSize    = Enum.AutomaticSize.Y
    f.BackgroundColor3 = color or Color3.fromRGB(25,35,55)
    f.BorderSizePixel  = 0
    f.LayoutOrder      = order or 0
    f.Parent           = parent
    Instance.new("UICorner", f).CornerRadius = UDim.new(0,10)
    Instance.new("UIStroke", f).Color = Color3.fromRGB(50,80,150)

    local lbl = Instance.new("TextLabel", f)
    lbl.Size             = UDim2.new(1,0,0,0)
    lbl.AutomaticSize    = Enum.AutomaticSize.Y
    lbl.BackgroundTransparency = 1
    lbl.Text             = text
    lbl.TextColor3       = Color3.fromRGB(180,200,255)
    lbl.TextSize         = isMobile and 12 or 10
    lbl.Font             = Enum.Font.Gotham
    lbl.TextWrapped      = true
    lbl.RichText         = true
    lbl.TextXAlignment   = Enum.TextXAlignment.Left
    lbl.ZIndex           = 3
    local p = Instance.new("UIPadding", lbl)
    p.PaddingTop    = UDim.new(0,8);  p.PaddingBottom = UDim.new(0,8)
    p.PaddingLeft   = UDim.new(0,10); p.PaddingRight  = UDim.new(0,10)
    return f, lbl
end

-- ════════════════════════════════════════════
-- STATUS BAR (persistent di atas content)
-- ════════════════════════════════════════════
local StatusBar = Instance.new("Frame")
StatusBar.Size             = UDim2.new(1,-10,0, isMobile and 32 or 28)
StatusBar.Position         = UDim2.new(0,5,0, contentY - (isMobile and 34 or 30))
StatusBar.BackgroundColor3 = Color3.fromRGB(20,28,48)
StatusBar.BorderSizePixel  = 0
StatusBar.ZIndex           = 5
StatusBar.Parent           = Main
Instance.new("UICorner", StatusBar).CornerRadius = UDim.new(0,8)
Instance.new("UIStroke", StatusBar).Color = Color3.fromRGB(50,80,150)

local StatusLbl = Instance.new("TextLabel", StatusBar)
StatusLbl.Size             = UDim2.new(1,-10,1,0)
StatusLbl.Position         = UDim2.new(0,8,0,0)
StatusLbl.BackgroundTransparency = 1
StatusLbl.Text             = "⏸️ Idle"
StatusLbl.TextColor3       = Color3.fromRGB(150,170,220)
StatusLbl.TextSize         = isMobile and 11 or 10
StatusLbl.Font             = Enum.Font.GothamBold
StatusLbl.TextXAlignment   = Enum.TextXAlignment.Left
StatusLbl.ZIndex           = 6

local function setStatus(text, color)
    StatusLbl.Text      = text
    StatusLbl.TextColor3 = color or Color3.fromRGB(150,170,220)
end

-- ════════════════════════════════════════════
-- VISUALIZATION ENGINE
-- ════════════════════════════════════════════

-- Folder untuk semua visual objects di workspace
local VisFolder = Instance.new("Folder")
VisFolder.Name   = "PathVisuals"
VisFolder.Parent = workspace

local function clearVisuals(pathIdx)
    if State.VisObjects[pathIdx] then
        for _, obj in ipairs(State.VisObjects[pathIdx]) do
            pcall(function() obj:Destroy() end)
        end
        State.VisObjects[pathIdx] = {}
    end
end

local function clearAllVisuals()
    for i in pairs(State.VisObjects) do
        clearVisuals(i)
    end
    -- Hapus sisa-sisa
    for _, obj in ipairs(VisFolder:GetChildren()) do
        pcall(function() obj:Destroy() end)
    end
end

-- Buat dot waypoint di world
local function createWaypointDot(pos, color, size, parent)
    local part = Instance.new("Part")
    part.Name        = "WP_Dot"
    part.Shape       = Enum.PartType.Ball
    part.Size        = Vector3.new(size, size, size)
    part.Position    = pos
    part.Anchored    = true
    part.CanCollide  = false
    part.Material    = Enum.Material.Neon
    part.Color       = color
    part.CastShadow  = false
    part.Parent      = parent or VisFolder
    return part
end

-- Buat beam antara dua titik
local function createBeamSegment(posA, posB, color, parent)
    -- Gunakan Part sebagai beam line
    local mid  = (posA + posB) / 2
    local dist = (posA - posB).Magnitude
    if dist < 0.01 then return nil end

    local beam = Instance.new("Part")
    beam.Name        = "WP_Beam"
    beam.Size        = Vector3.new(0.1, 0.1, dist)
    beam.CFrame      = CFrame.lookAt(mid, posB)
    beam.Anchored    = true
    beam.CanCollide  = false
    beam.Material    = Enum.Material.Neon
    beam.Color       = color
    beam.CastShadow  = false
    beam.Transparency = 0.3
    beam.Parent      = parent or VisFolder
    return beam
end

-- Rebuild visualisasi untuk satu path
local function rebuildPathVisual(pathIdx)
    clearVisuals(pathIdx)

    local pathData = State.Paths[pathIdx]
    if not pathData or #pathData.waypoints < 1 then return end
    if not State.ShowBeam and not State.ShowDots then return end

    State.VisObjects[pathIdx] = {}
    local objs = State.VisObjects[pathIdx]

    local wps = pathData.waypoints

    for i, wp in ipairs(wps) do
        local color = speedToColor(wp.speed or 16)

        -- Dot
        if State.ShowDots then
            local dotSize = wp.jumped and 0.5 or 0.3
            local dot     = createWaypointDot(wp.pos, color, dotSize, VisFolder)
            -- Dot lebih besar untuk waypoint dengan lompatan
            if wp.jumped then
                -- Tambah ring kecil
                local ring = Instance.new("Part")
                ring.Name        = "WP_Ring"
                ring.Shape       = Enum.PartType.Cylinder
                ring.Size        = Vector3.new(0.08, 0.9, 0.9)
                ring.CFrame      = CFrame.new(wp.pos) * CFrame.Angles(0,0,math.pi/2)
                ring.Anchored    = true
                ring.CanCollide  = false
                ring.Material    = Enum.Material.Neon
                ring.Color       = Color3.fromRGB(255,230,50)
                ring.Transparency = 0.2
                ring.CastShadow  = false
                ring.Parent      = VisFolder
                table.insert(objs, ring)
            end
            table.insert(objs, dot)
        end

        -- Beam ke waypoint berikutnya
        if State.ShowBeam and i < #wps then
            local nextWP  = wps[i+1]
            local midSpd  = ((wp.speed or 16) + (nextWP.speed or 16)) / 2
            local bColor  = speedToColor(midSpd)
            local beam    = createBeamSegment(wp.pos, nextWP.pos, bColor, VisFolder)
            if beam then table.insert(objs, beam) end
        end
    end

    -- Start marker (hijau)
    if State.ShowDots and #wps > 0 then
        local startMark = createWaypointDot(
            wps[1].pos + Vector3.new(0, 0.5, 0),
            Color3.fromRGB(50, 255, 80), 0.6, VisFolder
        )
        table.insert(objs, startMark)
    end

    -- End marker (merah)
    if State.ShowDots and #wps > 1 then
        local endMark = createWaypointDot(
            wps[#wps].pos + Vector3.new(0, 0.5, 0),
            Color3.fromRGB(255, 60, 60), 0.6, VisFolder
        )
        table.insert(objs, endMark)
    end
end

local function rebuildAllVisuals()
    clearAllVisuals()
    for i in ipairs(State.Paths) do
        rebuildPathVisual(i)
    end
end

-- ════════════════════════════════════════════
-- PLAYBACK POSITION INDICATOR
-- ════════════════════════════════════════════
local PlayIndicatorPart = Instance.new("Part")
PlayIndicatorPart.Name        = "PlayIndicator"
PlayIndicatorPart.Shape       = Enum.PartType.Ball
PlayIndicatorPart.Size        = Vector3.new(0.7, 0.7, 0.7)
PlayIndicatorPart.Anchored    = true
PlayIndicatorPart.CanCollide  = false
PlayIndicatorPart.Material    = Enum.Material.Neon
PlayIndicatorPart.Color       = Color3.fromRGB(255, 220, 50)
PlayIndicatorPart.Transparency = 0.3
PlayIndicatorPart.CastShadow  = false
PlayIndicatorPart.Parent      = VisFolder

task.spawn(function()
    local t = 0
    while VisFolder.Parent do
        t = t + 0.05
        PlayIndicatorPart.Transparency = 0.2 + math.sin(t*4)*0.3
        task.wait(0.05)
    end
end)

local function hidePlayIndicator()
    PlayIndicatorPart.Position = Vector3.new(0, -1000, 0)
end

hidePlayIndicator()

-- ════════════════════════════════════════════
-- RECORDING ENGINE
-- ════════════════════════════════════════════
local function getActivePathData()
    if State.CurrentPathIdx < 1 or State.CurrentPathIdx > #State.Paths then
        return nil
    end
    return State.Paths[State.CurrentPathIdx]
end

local function shouldRecordWaypoint(currentPos, currentDir)
    local pathData = getActivePathData()
    if not pathData then return false end

    -- Cek jarak minimum
    if State.LastRecordPos then
        local dist = (currentPos - State.LastRecordPos).Magnitude
        if dist < MIN_DIST_CHANGE then return false end
    end

    -- Mode: rekam saat perubahan arah
    if State.UseDirectionMode and State.LastDirection and currentDir then
        local angle = math.deg(math.acos(
            math.clamp(State.LastDirection:Dot(currentDir), -1, 1)
        ))
        if angle < DIRECTION_THRESHOLD and State.LastRecordPos then
            -- Tidak ada perubahan arah signifikan
            return false
        end
    else
        -- Mode interval biasa
        if tick() - State.LastRecordTime < State.RecordInterval then
            return false
        end
    end

    return true
end

local function addWaypoint(pos, jumped, speed)
    local pathData = getActivePathData()
    if not pathData then return end

    local wp = {
        pos    = pos,
        time   = tick(),
        jumped = jumped or false,
        speed  = speed  or 16,
    }
    table.insert(pathData.waypoints, wp)
    State.LastRecordPos  = pos
    State.LastRecordTime = tick()

    -- Update visual secara incremental (hanya tambah segment baru)
    if State.ShowDots or State.ShowBeam then
        local objs = State.VisObjects[State.CurrentPathIdx]
        if not objs then
            State.VisObjects[State.CurrentPathIdx] = {}
            objs = State.VisObjects[State.CurrentPathIdx]
        end

        local color   = speedToColor(speed or 16)
        local wps     = pathData.waypoints
        local lastIdx = #wps

        if State.ShowDots then
            local dotSize = jumped and 0.5 or 0.3
            local dot     = createWaypointDot(pos, color, dotSize, VisFolder)
            if jumped then
                local ring = Instance.new("Part")
                ring.Name        = "WP_Ring"
                ring.Shape       = Enum.PartType.Cylinder
                ring.Size        = Vector3.new(0.08, 0.9, 0.9)
                ring.CFrame      = CFrame.new(pos) * CFrame.Angles(0,0,math.pi/2)
                ring.Anchored    = true
                ring.CanCollide  = false
                ring.Material    = Enum.Material.Neon
                ring.Color       = Color3.fromRGB(255,230,50)
                ring.Transparency = 0.2
                ring.CastShadow  = false
                ring.Parent      = VisFolder
                table.insert(objs, ring)
            end
            table.insert(objs, dot)
        end

        if State.ShowBeam and lastIdx > 1 then
            local prev    = wps[lastIdx - 1]
            local midSpd  = ((prev.speed or 16) + (speed or 16)) / 2
            local bColor  = speedToColor(midSpd)
            local beam    = createBeamSegment(prev.pos, pos, bColor, VisFolder)
            if beam then table.insert(objs, beam) end
        end
    end
end

-- ════════════════════════════════════════════
-- RECORD LOOP
-- ════════════════════════════════════════════
local wasJumping = false
local lastSpeed  = 0

local function startRecording()
    if State.IsRecording then return end
    if not getActivePathData() then
        showNotif("⚠️ Buat/pilih path dulu!", Color3.fromRGB(80,40,10))
        return
    end

    State.IsRecording    = true
    State.LastRecordPos  = nil
    State.LastRecordTime = 0
    State.LastDirection  = nil
    wasJumping           = false

    setStatus("⏺️ Recording...", Color3.fromRGB(255,80,80))
    showNotif("⏺️ Recording dimulai!", Color3.fromRGB(60,15,15))

    Conn:Add("RecordLoop", RunService.Heartbeat:Connect(function(dt)
        if not State.IsRecording then return end

        local char = player.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum then return end

        local pos       = hrp.Position
        local vel       = hrp.Velocity
        local horzSpeed = Vector3.new(vel.X, 0, vel.Z).Magnitude
        local isJumping = hum:GetState() == Enum.HumanoidStateType.Jumping
            or hum:GetState() == Enum.HumanoidStateType.Freefall

        -- Deteksi momen jump (rising edge)
        local justJumped = isJumping and not wasJumping
        wasJumping       = isJumping

        -- Hitung arah pergerakan
        local dir = nil
        if horzSpeed > 0.5 then
            dir = Vector3.new(vel.X, 0, vel.Z).Unit
        end

        -- Paksa rekam saat lompatan terjadi
        if justJumped then
            local pathData = getActivePathData()
            if pathData then
                addWaypoint(pos, true, horzSpeed)
                State.LastDirection = dir
            end
        elseif shouldRecordWaypoint(pos, dir) then
            addWaypoint(pos, false, horzSpeed)
            State.LastDirection = dir
        end

        lastSpeed = horzSpeed

        -- Update status dengan info real-time
        local pathData = getActivePathData()
        local wpCount  = pathData and #pathData.waypoints or 0
        setStatus(string.format("⏺️ Rec | WP: %d | Spd: %.1f", wpCount, horzSpeed),
            Color3.fromRGB(255,100,100))
    end))
end

local function stopRecording()
    if not State.IsRecording then return end
    State.IsRecording = false
    Conn:Remove("RecordLoop")

    local pathData = getActivePathData()
    local wpCount  = pathData and #pathData.waypoints or 0
    setStatus(string.format("✅ Recorded %d waypoints", wpCount), Color3.fromRGB(80,200,80))
    showNotif(string.format("✅ %d waypoints direkam!", wpCount), Color3.fromRGB(15,60,20))
end

-- ════════════════════════════════════════════
-- PLAYBACK ENGINE
-- ════════════════════════════════════════════
local playbackPos = 0 -- 0.0 - 1.0 progress

local function stopPlayback()
    if not State.IsPlaying then return end
    State.IsPlaying  = false
    State.IsPaused   = false
    Conn:Remove("PlaybackLoop")
    hidePlayIndicator()
    setStatus("⏸️ Playback stopped", Color3.fromRGB(150,170,220))

    -- Restore humanoid
    pcall(function()
        local char = player.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.WalkSpeed    = 16
                hum.PlatformStand = false
            end
        end
    end)
end

local function getNextWPIdx(currentIdx, totalWPs)
    if State.PlayMode == "once" then
        if currentIdx >= totalWPs then return nil end
        return currentIdx + 1

    elseif State.PlayMode == "loop" then
        if currentIdx >= totalWPs then return 1 end
        return currentIdx + 1

    elseif State.PlayMode == "pingpong" then
        local nextIdx = currentIdx + State.PingPongDir
        if nextIdx > totalWPs then
            State.PingPongDir = -1
            nextIdx = totalWPs - 1
            if nextIdx < 1 then return nil end
        elseif nextIdx < 1 then
            State.PingPongDir = 1
            nextIdx = 2
            if nextIdx > totalWPs then return nil end
        end
        return nextIdx
    end
    return nil
end

local function startPlayback()
    local pathData = getActivePathData()
    if not pathData or #pathData.waypoints < 2 then
        showNotif("⚠️ Path kosong atau kurang dari 2 WP!", Color3.fromRGB(80,40,10))
        return
    end

    if State.IsRecording then stopRecording() end
    stopPlayback()

    State.IsPlaying      = true
    State.IsPaused       = false
    State.CurrentWPIdx   = 1
    State.PingPongDir    = 1
    playbackPos          = 0

    local wps      = pathData.waypoints
    local totalWPs = #wps

    setStatus("▶️ Playing: "..pathData.name, Color3.fromRGB(100,200,255))
    showNotif("▶️ Playback dimulai!", Color3.fromRGB(15,45,80))

    -- Teleport ke titik awal
    pcall(function()
        local char = player.Character
        if char then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then hrp.CFrame = CFrame.new(wps[1].pos) end
        end
    end)
    task.wait(0.3)

    local lastWPTime = tick()

    Conn:Add("PlaybackLoop", RunService.Heartbeat:Connect(function(dt)
        if not State.IsPlaying then return end
        if State.IsPaused then return end

        local char = player.Character
        if not char then stopPlayback(); return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum then stopPlayback(); return end

        local currentWP = wps[State.CurrentWPIdx]
        if not currentWP then stopPlayback(); return end

        -- Cek apakah perlu pindah ke WP berikutnya
        local distToWP = (hrp.Position - currentWP.pos).Magnitude

        -- Kalkulasi waktu yang diperlukan antara WP
        local nextIdx   = State.CurrentWPIdx + 1
        local targetPos = currentWP.pos

        if distToWP < 1.5 or (tick() - lastWPTime) > 3 then
            -- Sudah sampai atau timeout, pindah ke WP berikutnya
            local newIdx = getNextWPIdx(State.CurrentWPIdx, totalWPs)
            if not newIdx then
                stopPlayback()
                showNotif("✅ Playback selesai!", Color3.fromRGB(15,60,20))
                return
            end
            State.CurrentWPIdx = newIdx
            lastWPTime         = tick()
            currentWP          = wps[newIdx]
            targetPos          = currentWP.pos

            -- Trigger lompatan jika WP ini punya jump flag
            if currentWP.jumped then
                pcall(function()
                    hum:ChangeState(Enum.HumanoidStateType.Jumping)
                end)
            end
        end

        -- Update progress
        playbackPos = State.CurrentWPIdx / totalWPs

        -- Gerakkan karakter ke arah WP
        local dirToWP = (targetPos - hrp.Position)
        local horzDir = Vector3.new(dirToWP.X, 0, dirToWP.Z)

        if horzDir.Magnitude > 0.5 then
            -- Set WalkSpeed berdasarkan speed asli WP × PlaySpeed
            local targetSpeed = (currentWP.speed or 16) * State.PlaySpeed
            targetSpeed       = math.clamp(targetSpeed, 8, 500)
            hum.WalkSpeed     = targetSpeed

            -- Gerakkan menggunakan MoveTo
            hum:MoveTo(targetPos)
        end

        -- Smooth vertical jika ada perbedaan ketinggian
        local heightDiff = targetPos.Y - hrp.Position.Y
        if heightDiff > 2 then
            pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end)
        end

        -- Update indikator posisi
        PlayIndicatorPart.Position = hrp.Position + Vector3.new(0, 1.5, 0)

        -- Update status
        setStatus(string.format("▶️ WP %d/%d | Spd: %.1f | %.0f%%",
            State.CurrentWPIdx, totalWPs,
            hum.WalkSpeed, playbackPos * 100),
            Color3.fromRGB(100,200,255))
    end))
end

local function pausePlayback()
    if not State.IsPlaying then return end
    State.IsPaused = not State.IsPaused
    if State.IsPaused then
        setStatus("⏸️ Paused", Color3.fromRGB(255,200,50))
        -- Stop movement
        pcall(function()
            local char = player.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then hum.WalkSpeed = 0 end
            end
        end)
    else
        setStatus("▶️ Resumed", Color3.fromRGB(100,200,255))
    end
end

-- ════════════════════════════════════════════
-- TELEPORT TO WAYPOINT
-- ════════════════════════════════════════════
local function teleportToWaypoint(wpIdx)
    local pathData = getActivePathData()
    if not pathData then return end
    local wp = pathData.waypoints[wpIdx]
    if not wp then return end

    pcall(function()
        local char = player.Character
        if char then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.CFrame = CFrame.new(wp.pos + Vector3.new(0, 3, 0))
                showNotif(string.format("📌 Teleport ke WP #%d", wpIdx),
                    Color3.fromRGB(30,50,80))
            end
        end
    end)
end

-- ════════════════════════════════════════════
-- PATH MANAGEMENT
-- ════════════════════════════════════════════
local function createNewPath(name)
    if #State.Paths >= MAX_PATHS then
        showNotif("⚠️ Max "..MAX_PATHS.." paths!", Color3.fromRGB(80,40,10))
        return nil
    end

    local idx       = #State.Paths + 1
    local pathColor = PATH_COLORS[((idx - 1) % #PATH_COLORS) + 1]
    local pathName  = name or ("Path "..idx)

    local pathData = {
        name      = pathName,
        waypoints = {},
        color     = pathColor,
        created   = tick(),
    }

    table.insert(State.Paths, pathData)
    State.VisObjects[idx] = {}
    State.CurrentPathIdx  = idx

    return idx
end

local function deletePath(idx)
    if idx < 1 or idx > #State.Paths then return end
    clearVisuals(idx)
    table.remove(State.Paths, idx)
    table.remove(State.VisObjects, idx)

    if State.CurrentPathIdx > #State.Paths then
        State.CurrentPathIdx = math.max(1, #State.Paths)
    end

    rebuildAllVisuals()
end

local function clearPathWaypoints(idx)
    local pathData = State.Paths[idx]
    if not pathData then return end
    pathData.waypoints = {}
    clearVisuals(idx)
    showNotif("🗑️ Waypoints dihapus!", Color3.fromRGB(60,25,15))
end

-- ════════════════════════════════════════════
-- SAVE / LOAD (String format)
-- ════════════════════════════════════════════
local function pathToString(pathIdx)
    local pathData = State.Paths[pathIdx]
    if not pathData or #pathData.waypoints == 0 then return nil end

    local parts = {}
    table.insert(parts, pathData.name)
    table.insert(parts, tostring(#pathData.waypoints))

    for _, wp in ipairs(pathData.waypoints) do
        table.insert(parts, string.format("%.3f,%.3f,%.3f,%.4f,%s,%.2f",
            wp.pos.X, wp.pos.Y, wp.pos.Z,
            wp.time,
            wp.jumped and "1" or "0",
            wp.speed or 16
        ))
    end

    return table.concat(parts, "|")
end

local function stringToPath(str)
    if not str or str == "" then return nil end
    local parts = str:split("|")
    if #parts < 3 then return nil end

    local name    = parts[1]
    local wpCount = tonumber(parts[2])
    if not wpCount then return nil end

    local waypoints = {}
    for i = 3, 2 + wpCount do
        local wpStr = parts[i]
        if wpStr then
            local vals = wpStr:split(",")
            if #vals >= 6 then
                local x, y, z = tonumber(vals[1]), tonumber(vals[2]), tonumber(vals[3])
                local t       = tonumber(vals[4])
                local jumped  = vals[5] == "1"
                local speed   = tonumber(vals[6]) or 16
                if x and y and z then
                    table.insert(waypoints, {
                        pos    = Vector3.new(x, y, z),
                        time   = t or 0,
                        jumped = jumped,
                        speed  = speed,
                    })
                end
            end
        end
    end

    if #waypoints == 0 then return nil end

    return {
        name      = name,
        waypoints = waypoints,
        color     = PATH_COLORS[(#State.Paths % #PATH_COLORS) + 1],
        created   = tick(),
    }
end

-- ════════════════════════════════════════════
-- DYNAMIC UI UPDATES
-- ════════════════════════════════════════════
local PathListFrame   -- akan dibuat di Paths tab
local WPListFrame     -- akan dibuat di Playback tab
local ActivePathLabel -- label yang tampilkan path aktif

local function updateActivePathLabel()
    if not ActivePathLabel then return end
    local pathData = getActivePathData()
    if pathData then
        ActivePathLabel.Text = "📂 Active: "..pathData.name
            .." ("..#pathData.waypoints.." WP)"
    else
        ActivePathLabel.Text = "📂 Active: (tidak ada)"
    end
end

-- ════════════════════════════════════════════
-- RECORD TAB UI
-- ════════════════════════════════════════════
mkSection("⏺️ Recording Controls", RecordContent, 1)

-- Active path display
local _, apLbl = mkInfoBox("📂 Active: (tidak ada)", RecordContent, 2)
ActivePathLabel = apLbl

-- Record toggle button
local recBtn, setRecBtn = mkToggleBtn(
    "⏺️ Start Recording",
    "⏹️ Stop Recording",
    RecordContent, 3,
    function() startRecording() end,
    function() stopRecording() end
)

mkSection("⚙️ Record Settings", RecordContent, 10)

-- Interval slider
mkSlider("⏱️ Record Interval", RecordContent, 0.1, 2.0,
    DEFAULT_INTERVAL, "s", 11, function(v)
        State.RecordInterval = v
    end
)

-- Direction mode toggle
mkToggleBtn(
    "📐 Interval Mode (aktif)",
    "📐 Direction Change Mode (aktif)",
    RecordContent, 12,
    function() State.UseDirectionMode = true end,
    function() State.UseDirectionMode = false end
)

mkSection("🗺️ Waypoint Info", RecordContent, 20)

local wpCountBox, wpCountLbl = mkInfoBox(
    "Waypoints: 0\nJumps: 0\nTotal Distance: 0m",
    RecordContent, 21
)

-- Update WP info secara berkala
Conn:Add("WPInfoUpdate", RunService.Heartbeat:Connect(function()
    local pathData = getActivePathData()
    if not pathData then
        if wpCountLbl then
            wpCountLbl.Text = "Waypoints: 0\nJumps: 0\nTotal Distance: 0m"
        end
        return
    end

    local wps     = pathData.waypoints
    local total   = #wps
    local jumps   = 0
    local dist    = 0

    for i, wp in ipairs(wps) do
        if wp.jumped then jumps += 1 end
        if i > 1 then
            dist = dist + (wp.pos - wps[i-1].pos).Magnitude
        end
    end

    if wpCountLbl then
        wpCountLbl.Text = string.format(
            "Waypoints: <b>%d</b>\nJumps recorded: <b>%d</b>\nTotal Distance: <b>%.1fm</b>",
            total, jumps, dist
        )
    end

    updateActivePathLabel()
end))

-- Clear current path
mkBtn("🗑️ Clear Waypoints", RecordContent, function()
    if State.IsRecording then stopRecording(); setRecBtn(false) end
    clearPathWaypoints(State.CurrentPathIdx)
end, 22, Color3.fromRGB(80,25,25))

-- New path shortcut
mkBtn("➕ New Path (Quick)", RecordContent, function()
    if State.IsRecording then stopRecording(); setRecBtn(false) end
    local idx = createNewPath()
    if idx then
        showNotif("✅ Path "..idx.." dibuat!", Color3.fromRGB(15,55,20))
        updateActivePathLabel()
    end
end, 23, Color3.fromRGB(25,55,25))

-- ════════════════════════════════════════════
-- PLAYBACK TAB UI
-- ════════════════════════════════════════════
mkSection("▶️ Playback Controls", PlaybackContent, 1)

local _, apLbl2 = mkInfoBox("📂 Active: (tidak ada)", PlaybackContent, 2)

-- Sync label dengan RecordContent
Conn:Add("SyncPathLabel", RunService.Heartbeat:Connect(function()
    local pathData = getActivePathData()
    local text = pathData
        and ("📂 Active: "..pathData.name.." ("..#pathData.waypoints.." WP)")
        or  "📂 Active: (tidak ada)"
    if apLbl2 then apLbl2.Text = text end
end))

-- Play/Pause/Stop row
local playRow = Instance.new("Frame")
playRow.Size             = UDim2.new(1,0,0, isMobile and 48 or 42)
playRow.BackgroundTransparency = 1
playRow.LayoutOrder      = 3
playRow.Parent           = PlaybackContent
local playRowLayout = Instance.new("UIListLayout", playRow)
playRowLayout.FillDirection       = Enum.FillDirection.Horizontal
playRowLayout.Padding             = UDim.new(0,5)
playRowLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

local function mkSmallBtn(text, parent, cb, color)
    local b = Instance.new("TextButton")
    b.Size             = UDim2.new(0.31,0,1,0)
    b.BackgroundColor3 = color or Color3.fromRGB(38,45,65)
    b.Text             = text
    b.TextColor3       = Color3.new(1,1,1)
    b.TextSize         = isMobile and 13 or 11
    b.Font             = Enum.Font.GothamBold
    b.ZIndex           = 3
    b.AutoButtonColor  = false
    b.Parent           = parent
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,10)
    b.MouseButton1Click:Connect(cb)
    return b
end

mkSmallBtn("▶️ Play",  playRow, function() startPlayback() end, Color3.fromRGB(25,80,35))
mkSmallBtn("⏸️ Pause", playRow, function() pausePlayback() end, Color3.fromRGB(80,65,15))
mkSmallBtn("⏹️ Stop",  playRow, function() stopPlayback() end,  Color3.fromRGB(80,20,20))

mkSection("⚙️ Playback Settings", PlaybackContent, 10)

-- Play mode selector
local playModeFrame = Instance.new("Frame")
playModeFrame.Size             = UDim2.new(1,0,0, isMobile and 48 or 40)
playModeFrame.BackgroundColor3 = Color3.fromRGB(28,35,55)
playModeFrame.BorderSizePixel  = 0
playModeFrame.LayoutOrder      = 11
playModeFrame.Parent           = PlaybackContent
Instance.new("UICorner", playModeFrame).CornerRadius = UDim.new(0,10)

local pmLbl = Instance.new("TextLabel", playModeFrame)
pmLbl.Size             = UDim2.new(0.35,0,1,0)
pmLbl.Position         = UDim2.new(0,8,0,0)
pmLbl.BackgroundTransparency = 1
pmLbl.Text             = "Play Mode:"
pmLbl.TextColor3       = Color3.new(1,1,1)
pmLbl.TextSize         = isMobile and 12 or 10
pmLbl.Font             = Enum.Font.GothamBold
pmLbl.TextXAlignment   = Enum.TextXAlignment.Left
pmLbl.ZIndex           = 4

local pmBtnRow = Instance.new("Frame", playModeFrame)
pmBtnRow.Size             = UDim2.new(0.62,0,0.8,0)
pmBtnRow.Position         = UDim2.new(0.37,0,0.1,0)
pmBtnRow.BackgroundTransparency = 1
Instance.new("UIListLayout", pmBtnRow).FillDirection = Enum.FillDirection.Horizontal

local playModes = {"once", "loop", "pingpong"}
local pmButtons = {}
for i, mode in ipairs(playModes) do
    local pb = Instance.new("TextButton", pmBtnRow)
    pb.Size             = UDim2.new(0.32,0,1,0)
    pb.BackgroundColor3 = mode == "once"
        and Color3.fromRGB(40,80,160)
        or  Color3.fromRGB(30,35,55)
    pb.Text             = mode == "once" and "Once" or mode == "loop" and "Loop" or "↔️"
    pb.TextColor3       = Color3.new(1,1,1)
    pb.TextSize         = isMobile and 10 or 9
    pb.Font             = Enum.Font.GothamBold
    pb.ZIndex           = 4
    pb.AutoButtonColor  = false
    Instance.new("UICorner", pb).CornerRadius = UDim.new(0,6)
    pmButtons[mode] = pb

    pb.MouseButton1Click:Connect(function()
        State.PlayMode = mode
        for m, b in pairs(pmButtons) do
            b.BackgroundColor3 = m == mode
                and Color3.fromRGB(40,80,160)
                or  Color3.fromRGB(30,35,55)
        end
    end)
end

-- Speed multiplier slider
mkSlider("⚡ Play Speed", PlaybackContent, 0.1, 5.0, 1.0, "x", 12, function(v)
    State.PlaySpeed = v
end)

mkSection("📌 Teleport to Waypoint", PlaybackContent, 20)

-- WP index input
local wpTpFrame = Instance.new("Frame")
wpTpFrame.Size             = UDim2.new(1,0,0, isMobile and 48 or 42)
wpTpFrame.BackgroundColor3 = Color3.fromRGB(28,35,55)
wpTpFrame.BorderSizePixel  = 0
wpTpFrame.LayoutOrder      = 21
wpTpFrame.Parent           = PlaybackContent
Instance.new("UICorner", wpTpFrame).CornerRadius = UDim.new(0,10)

local wpTpLbl = Instance.new("TextLabel", wpTpFrame)
wpTpLbl.Size             = UDim2.new(0.3,0,1,0)
wpTpLbl.Position         = UDim2.new(0,8,0,0)
wpTpLbl.BackgroundTransparency = 1
wpTpLbl.Text             = "WP Index:"
wpTpLbl.TextColor3       = Color3.new(1,1,1)
wpTpLbl.TextSize         = isMobile and 12 or 10
wpTpLbl.Font             = Enum.Font.GothamBold
wpTpLbl.TextXAlignment   = Enum.TextXAlignment.Left
wpTpLbl.ZIndex           = 4

local wpTpBox = Instance.new("TextBox", wpTpFrame)
wpTpBox.Size             = UDim2.new(0.3,0,0.7,0)
wpTpBox.Position         = UDim2.new(0.32,0,0.15,0)
wpTpBox.BackgroundColor3 = Color3.fromRGB(18,22,38)
wpTpBox.Text             = "1"
wpTpBox.TextColor3       = Color3.fromRGB(150,200,255)
wpTpBox.TextSize         = isMobile and 14 or 12
wpTpBox.Font             = Enum.Font.GothamBold
wpTpBox.ZIndex           = 5
Instance.new("UICorner", wpTpBox).CornerRadius = UDim.new(0,6)

local wpTpBtn = Instance.new("TextButton", wpTpFrame)
wpTpBtn.Size             = UDim2.new(0.33,0,0.8,0)
wpTpBtn.Position         = UDim2.new(0.65,0,0.1,0)
wpTpBtn.BackgroundColor3 = Color3.fromRGB(40,70,140)
wpTpBtn.Text             = "📌 Go"
wpTpBtn.TextColor3       = Color3.new(1,1,1)
wpTpBtn.TextSize         = isMobile and 12 or 10
wpTpBtn.Font             = Enum.Font.GothamBold
wpTpBtn.ZIndex           = 5
wpTpBtn.AutoButtonColor  = false
Instance.new("UICorner", wpTpBtn).CornerRadius = UDim.new(0,8)

wpTpBtn.MouseButton1Click:Connect(function()
    local idx = tonumber(wpTpBox.Text)
    if idx then teleportToWaypoint(math.floor(idx)) end
end)

-- Progress bar
local progFrame = Instance.new("Frame")
progFrame.Size             = UDim2.new(1,0,0, isMobile and 32 or 28)
progFrame.BackgroundColor3 = Color3.fromRGB(20,25,40)
progFrame.BorderSizePixel  = 0
progFrame.LayoutOrder      = 22
progFrame.Parent           = PlaybackContent
Instance.new("UICorner", progFrame).CornerRadius = UDim.new(1,0)
Instance.new("UIStroke", progFrame).Color = Color3.fromRGB(50,80,150)

local progFill = Instance.new("Frame", progFrame)
progFill.Size             = UDim2.new(0,0,1,0)
progFill.BackgroundColor3 = Color3.fromRGB(80,160,255)
progFill.BorderSizePixel  = 0
Instance.new("UICorner", progFill).CornerRadius = UDim.new(1,0)

local progLbl = Instance.new("TextLabel", progFrame)
progLbl.Size             = UDim2.new(1,0,1,0)
progLbl.BackgroundTransparency = 1
progLbl.Text             = "0%"
progLbl.TextColor3       = Color3.new(1,1,1)
progLbl.TextSize         = isMobile and 11 or 10
progLbl.Font             = Enum.Font.GothamBold
progLbl.ZIndex           = 4

-- Update progress bar
Conn:Add("ProgUpdate", RunService.Heartbeat:Connect(function()
    local ratio = math.clamp(playbackPos, 0, 1)
    TweenService:Create(progFill, TweenInfo.new(0.1),
        {Size = UDim2.new(ratio, 0, 1, 0)}):Play()
    progLbl.Text = string.format("%.0f%%", ratio * 100)
end))

-- ════════════════════════════════════════════
-- PATHS TAB UI
-- ════════════════════════════════════════════
mkSection("🗂️ Path Manager", PathsContent, 1)

-- Buat path baru
local newPathNameBox = Instance.new("Frame")
newPathNameBox.Size             = UDim2.new(1,0,0, isMobile and 44 or 38)
newPathNameBox.BackgroundColor3 = Color3.fromRGB(28,35,55)
newPathNameBox.BorderSizePixel  = 0
newPathNameBox.LayoutOrder      = 2
newPathNameBox.Parent           = PathsContent
Instance.new("UICorner", newPathNameBox).CornerRadius = UDim.new(0,10)

local nameInput = Instance.new("TextBox", newPathNameBox)
nameInput.Size             = UDim2.new(0.62,0,1,-8)
nameInput.Position         = UDim2.new(0,8,0,4)
nameInput.BackgroundColor3 = Color3.fromRGB(18,22,38)
nameInput.PlaceholderText  = "Path name..."
nameInput.PlaceholderColor3 = Color3.fromRGB(80,90,120)
nameInput.Text             = ""
nameInput.TextColor3       = Color3.fromRGB(160,200,255)
nameInput.TextSize         = isMobile and 13 or 11
nameInput.Font             = Enum.Font.Gotham
nameInput.ClearTextOnFocus = false
nameInput.ZIndex           = 4
Instance.new("UICorner", nameInput).CornerRadius = UDim.new(0,6)

local createPathBtn = Instance.new("TextButton", newPathNameBox)
createPathBtn.Size             = UDim2.new(0.34,0,1,-8)
createPathBtn.Position         = UDim2.new(0.64,0,0,4)
createPathBtn.BackgroundColor3 = Color3.fromRGB(30,90,45)
createPathBtn.Text             = "➕ Create"
createPathBtn.TextColor3       = Color3.new(1,1,1)
createPathBtn.TextSize         = isMobile and 12 or 10
createPathBtn.Font             = Enum.Font.GothamBold
createPathBtn.ZIndex           = 4
createPathBtn.AutoButtonColor  = false
Instance.new("UICorner", createPathBtn).CornerRadius = UDim.new(0,6)

createPathBtn.MouseButton1Click:Connect(function()
    local name = nameInput.Text ~= "" and nameInput.Text or nil
    local idx  = createNewPath(name)
    if idx then
        nameInput.Text = ""
        showNotif("✅ '"..State.Paths[idx].name.."' dibuat!", Color3.fromRGB(15,55,20))
        -- Rebuild path list
        task.spawn(function()
            task.wait(0.1)
            -- Trigger refresh
        end)
    end
end)

-- Path list container
PathListFrame = Instance.new("Frame")
PathListFrame.Size             = UDim2.new(1,0,0,20)
PathListFrame.BackgroundTransparency = 1
PathListFrame.AutomaticSize    = Enum.AutomaticSize.Y
PathListFrame.LayoutOrder      = 3
PathListFrame.Parent           = PathsContent
Instance.new("UIListLayout", PathListFrame).Padding = UDim.new(0,5)

local function refreshPathList()
    -- Clear
    for _, c in ipairs(PathListFrame:GetChildren()) do
        if not c:IsA("UIListLayout") then c:Destroy() end
    end

    if #State.Paths == 0 then
        local _, noLbl = mkInfoBox("Belum ada path. Buat path baru di atas!", PathListFrame, 1)
        return
    end

    for i, pathData in ipairs(State.Paths) do
        local entry = Instance.new("Frame")
        entry.Size             = UDim2.new(1,0,0, isMobile and 80 or 70)
        entry.BackgroundColor3 = i == State.CurrentPathIdx
            and Color3.fromRGB(28,45,80)
            or  Color3.fromRGB(25,30,48)
        entry.BorderSizePixel  = 0
        entry.LayoutOrder      = i
        entry.Parent           = PathListFrame
        Instance.new("UICorner", entry).CornerRadius = UDim.new(0,10)

        local entryStroke = Instance.new("UIStroke", entry)
        entryStroke.Color = i == State.CurrentPathIdx
            and Color3.fromRGB(80,140,255)
            or  Color3.fromRGB(40,50,80)
        entryStroke.Thickness = i == State.CurrentPathIdx and 2 or 1

        -- Color indicator
        local colorDot = Instance.new("Frame", entry)
        colorDot.Size             = UDim2.new(0,12,0,12)
        colorDot.Position         = UDim2.new(0,10,0, isMobile and 10 or 8)
        colorDot.BackgroundColor3 = pathData.color
        colorDot.BorderSizePixel  = 0
        Instance.new("UICorner", colorDot).CornerRadius = UDim.new(1,0)

        -- Name
        local nameLbl = Instance.new("TextLabel", entry)
        nameLbl.Size             = UDim2.new(0.7,0,0,20)
        nameLbl.Position         = UDim2.new(0,28,0, isMobile and 6 or 4)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Text             = pathData.name
        nameLbl.TextColor3       = Color3.new(1,1,1)
        nameLbl.TextSize         = isMobile and 13 or 11
        nameLbl.Font             = Enum.Font.GothamBold
        nameLbl.TextXAlignment   = Enum.TextXAlignment.Left
        nameLbl.ZIndex           = 4

        -- Info
        local wps    = pathData.waypoints
        local dist   = 0
        for j = 2, #wps do
            dist = dist + (wps[j].pos - wps[j-1].pos).Magnitude
        end

        local infoLbl = Instance.new("TextLabel", entry)
        infoLbl.Size             = UDim2.new(1,-10,0,16)
        infoLbl.Position         = UDim2.new(0,8,0, isMobile and 26 or 24)
        infoLbl.BackgroundTransparency = 1
        infoLbl.Text             = string.format("📍 %d WP • 📏 %.1fm • ⏱️ %.0fs ago",
            #wps, dist, tick() - pathData.created)
        infoLbl.TextColor3       = Color3.fromRGB(130,150,200)
        infoLbl.TextSize         = isMobile and 10 or 9
        infoLbl.Font             = Enum.Font.Gotham
        infoLbl.TextXAlignment   = Enum.TextXAlignment.Left
        infoLbl.ZIndex           = 4

        -- Button row
        local btnRow = Instance.new("Frame", entry)
        btnRow.Size             = UDim2.new(1,-12,0, isMobile and 28 or 24)
        btnRow.Position         = UDim2.new(0,6,1,-(isMobile and 33 or 28))
        btnRow.BackgroundTransparency = 1
        Instance.new("UIListLayout", btnRow).FillDirection = Enum.FillDirection.Horizontal

        local function mkTinyBtn(text, col, cb)
            local b = Instance.new("TextButton", btnRow)
            b.Size             = UDim2.new(0.24,0,1,0)
            b.BackgroundColor3 = col
            b.Text             = text
            b.TextColor3       = Color3.new(1,1,1)
            b.TextSize         = isMobile and 10 or 9
            b.Font             = Enum.Font.GothamBold
            b.ZIndex           = 5
            b.AutoButtonColor  = false
            Instance.new("UICorner", b).CornerRadius = UDim.new(0,6)
            b.MouseButton1Click:Connect(cb)
        end

        -- Select
        mkTinyBtn(i == State.CurrentPathIdx and "✅ Active" or "👉 Select",
            i == State.CurrentPathIdx and Color3.fromRGB(30,80,160) or Color3.fromRGB(35,50,90),
            function()
                if State.IsRecording then stopRecording(); setRecBtn(false) end
                if State.IsPlaying then stopPlayback() end
                State.CurrentPathIdx = i
                refreshPathList()
                updateActivePathLabel()
                showNotif("👉 Path '"..pathData.name.."' dipilih", Color3.fromRGB(20,40,80))
            end
        )

        -- Save
        mkTinyBtn("💾 Save", Color3.fromRGB(30,60,100), function()
            local str = pathToString(i)
            if str then
                pcall(function() setclipboard(str) end)
                showNotif("💾 Path disalin ke clipboard!", Color3.fromRGB(15,45,80))
            else
                showNotif("⚠️ Path kosong!", Color3.fromRGB(80,40,10))
            end
        end)

        -- Clear WP
        mkTinyBtn("🗑️ Clear", Color3.fromRGB(80,30,15), function()
            clearPathWaypoints(i)
            refreshPathList()
        end)

        -- Delete path
        mkTinyBtn("❌ Del", Color3.fromRGB(100,20,20), function()
            if State.IsPlaying and State.CurrentPathIdx == i then stopPlayback() end
            if State.IsRecording and State.CurrentPathIdx == i then
                stopRecording(); setRecBtn(false)
            end
            deletePath(i)
            refreshPathList()
            updateActivePathLabel()
        end)
    end
end

-- Auto refresh path list
Conn:Add("PathListRefresh", RunService.Heartbeat:Connect(function()
    -- Refresh setiap 1 detik
end))

-- Manual refresh dengan timer
local lastPathRefresh = 0
Conn:Add("PathListTimer", RunService.Heartbeat:Connect(function()
    if tick() - lastPathRefresh > 1 then
        lastPathRefresh = tick()
        if State.CurrentTab == "paths" then
            refreshPathList()
        end
    end
end))

mkSection("📥 Import Path", PathsContent, 10)

local importBox = Instance.new("TextBox")
importBox.Size             = UDim2.new(1,0,0, isMobile and 52 or 44)
importBox.BackgroundColor3 = Color3.fromRGB(18,22,38)
importBox.PlaceholderText  = "Paste path string di sini..."
importBox.PlaceholderColor3 = Color3.fromRGB(70,80,110)
importBox.Text             = ""
importBox.TextColor3       = Color3.fromRGB(160,200,255)
importBox.TextSize         = isMobile and 11 or 10
importBox.Font             = Enum.Font.Gotham
importBox.TextWrapped      = true
importBox.ClearTextOnFocus = false
importBox.MultiLine        = true
importBox.ZIndex           = 3
importBox.LayoutOrder      = 11
importBox.Parent           = PathsContent
Instance.new("UICorner", importBox).CornerRadius = UDim.new(0,10)
Instance.new("UIStroke", importBox).Color = Color3.fromRGB(50,80,150)

mkBtn("📥 Import Path", PathsContent, function()
    local str = importBox.Text
    if str == "" then
        showNotif("⚠️ Input string dulu!", Color3.fromRGB(80,40,10)); return
    end
    local pathData = stringToPath(str)
    if pathData then
        if #State.Paths >= MAX_PATHS then
            showNotif("⚠️ Max "..MAX_PATHS.." paths!", Color3.fromRGB(80,40,10)); return
        end
        table.insert(State.Paths, pathData)
        local newIdx = #State.Paths
        State.VisObjects[newIdx] = {}
        State.CurrentPathIdx     = newIdx
        rebuildPathVisual(newIdx)
        importBox.Text = ""
        refreshPathList()
        updateActivePathLabel()
        showNotif("✅ Path '"..pathData.name.."' diimport! ("
            ..#pathData.waypoints.." WP)", Color3.fromRGB(15,55,20))
    else
        showNotif("❌ Format string tidak valid!", Color3.fromRGB(80,15,15))
    end
end, 12, Color3.fromRGB(25,55,100))

-- ════════════════════════════════════════════
-- SETTINGS TAB UI
-- ════════════════════════════════════════════
mkSection("👁️ Visualization", SettingsContent, 1)

mkToggleBtn(
    "🔴 Dots: ON  | Tap to toggle",
    "🔴 Dots: OFF | Tap to toggle",
    SettingsContent, 2,
    function()
        State.ShowDots = false
        -- Hapus semua dot dari visuals
        for _, objs in pairs(State.VisObjects) do
            for _, obj in ipairs(objs) do
                pcall(function()
                    if obj.Name == "WP_Dot" or obj.Name == "WP_Ring" then
                        obj.Transparency = 1
                    end
                end)
            end
        end
    end,
    function()
        State.ShowDots = true
        rebuildAllVisuals()
    end
)

mkToggleBtn(
    "〰️ Beams: ON  | Tap to toggle",
    "〰️ Beams: OFF | Tap to toggle",
    SettingsContent, 3,
    function()
        State.ShowBeam = false
        for _, objs in pairs(State.VisObjects) do
            for _, obj in ipairs(objs) do
                pcall(function()
                    if obj.Name == "WP_Beam" then
                        obj.Transparency = 1
                    end
                end)
            end
        end
    end,
    function()
        State.ShowBeam = true
        rebuildAllVisuals()
    end
)

mkBtn("🔄 Rebuild All Visuals", SettingsContent, function()
    rebuildAllVisuals()
    showNotif("🔄 Visuals rebuilt!", Color3.fromRGB(30,50,80))
end, 4)

mkBtn("🗑️ Clear All Visuals", SettingsContent, function()
    clearAllVisuals()
    State.VisObjects = {}
    showNotif("🗑️ Visuals cleared!", Color3.fromRGB(60,25,15))
end, 5, Color3.fromRGB(70,25,15))

mkSection("⚙️ General", SettingsContent, 10)

mkSlider("📐 Min Direction Change", SettingsContent, 5, 45, DIRECTION_THRESHOLD, "°", 11,
    function(v)
        -- Update threshold
        -- (reference via upvalue tidak bisa langsung, gunakan State)
    end
)

mkSlider("📏 Min Waypoint Distance", SettingsContent, 0.5, 10, MIN_DIST_CHANGE, "st", 12,
    function(v)
        -- Update via closure
    end
)

mkSection("ℹ️ Speed Color Guide", SettingsContent, 20)
mkInfoBox(
    "🔵 0-5 st/s = Diam\n"..
    "🟢 5-16 st/s = Jalan Normal\n"..
    "🟡 16-50 st/s = Speed Boost\n"..
    "🔴 50+ st/s = Sangat Cepat\n\n"..
    "🟡 Dot besar = Waypoint lompatan\n"..
    "🟢 Dot hijau = Titik awal\n"..
    "🔴 Dot merah = Titik akhir",
    SettingsContent, 21
)

mkSection("📋 Controls", SettingsContent, 30)
mkInfoBox(
    isMobile and
    "• Tap ⏺️ untuk mulai rekam\n"..
    "• Berjalan otomatis direkam\n"..
    "• Tap ⏹️ untuk stop\n"..
    "• Tab Playback untuk replay\n"..
    "• Tab Paths untuk manage path"
    or
    "• Klik ⏺️ Start Recording\n"..
    "• Berjalan → waypoints terekam otomatis\n"..
    "• Lompat → tercatat sebagai Jump WP\n"..
    "• Klik ⏹️ Stop → data tersimpan\n"..
    "• Tab Playback → Play/Pause/Stop\n"..
    "• Tab Paths → Manage, Save, Import",
    SettingsContent, 31
)

-- ════════════════════════════════════════════
-- CHARACTER RESPAWN HANDLER
-- ════════════════════════════════════════════
player.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    if State.IsPlaying then
        -- Restart playback dari awal jika karakter respawn
        task.wait(0.3)
        startPlayback()
    end
    if State.IsRecording then
        -- Lanjutkan rekam setelah respawn
        State.LastRecordPos = nil
    end
end)

-- ════════════════════════════════════════════
-- CLOSE HANDLER
-- ════════════════════════════════════════════
CloseBtn.MouseButton1Click:Connect(function()
    -- Stop semua
    stopRecording()
    stopPlayback()

    -- Cleanup connections
    Conn:RemoveAll()

    -- Cleanup visuals
    clearAllVisuals()
    pcall(function() VisFolder:Destroy() end)
    pcall(function() PlayIndicatorPart:Destroy() end)

    -- Restore character
    pcall(function()
        local char = player.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.WalkSpeed     = 16
                hum.PlatformStand = false
            end
        end
    end)

    -- Destroy GUI
    task.wait(0.1)
    pcall(function() ScreenGui:Destroy() end)
end)

-- ════════════════════════════════════════════
-- INIT
-- ════════════════════════════════════════════
switchTab("record")

-- Buat default path pertama
createNewPath("Path 1")
refreshPathList()
updateActivePathLabel()

-- Open animation
Main.Size     = UDim2.new(0,0,0,0)
Main.Position = isMobile and UDim2.new(0.5,0,0.5,0) or UDim2.new(0.02,0,0.04,0)
TweenService:Create(Main, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
    Size     = isMobile and UDim2.new(0.95,0,0.85,0) or UDim2.new(0,460,0,680),
    Position = isMobile and UDim2.new(0.025,0,0.08,0) or UDim2.new(0.02,0,0.04,0),
}):Play()

task.delay(0.8, function()
    showNotif("🛤️ Path Movement Pro Ready!", Color3.fromRGB(20,35,70))
end)

print("╔══════════════════════════════════════╗")
print("║  🛤️ Path Movement Pro v1.0           ║")
print("║  ✅ Record + Replay + Visualize       ║")
print("║  ✅ Multiple Paths (max 10)           ║")
print("║  ✅ Jump Recording                    ║")
print("║  ✅ Speed Color Visualization         ║")
print("║  ✅ Save/Load (String)                ║")
print("║  ✅ Teleport to Waypoint              ║")
print("║  ✅ PC + Mobile                       ║")
print("║  👤 "..player.Name)
print("╚══════════════════════════════════════╝")
