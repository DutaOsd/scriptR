-- ════════════════════════════════════════════════════════
-- CUSTOM JUMP BUTTON SETTINGS GUI - Mobile
-- Atur ukuran & posisi tombol jump dengan GUI
-- ════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LP = Players.LocalPlayer

-- ════════════════════════════════════════════════════════
-- CEK MOBILE
-- ════════════════════════════════════════════════════════
if not UIS.TouchEnabled then
    warn("Script ini khusus untuk Mobile!")
    return
end

-- ════════════════════════════════════════════════════════
-- HAPUS GUI LAMA
-- ════════════════════════════════════════════════════════
local oldGui = LP.PlayerGui:FindFirstChild("JumpSettingsGUI")
if oldGui then oldGui:Destroy() end

-- ════════════════════════════════════════════════════════
-- NILAI DEFAULT
-- ════════════════════════════════════════════════════════
-- VIEWPORT CLAMP HELPERS (GUI pas di layar)
local Camera = workspace.CurrentCamera
local function vpSize()
    local ok, s = pcall(function() return Camera.ViewportSize end)
    if ok and s and s.X > 0 and s.Y > 0 then return s end
    return Vector2.new(1280, 720)
end
local function clampAbs(x, y, w, h)
    local vp = vpSize()
    return math.clamp(x, 0, math.max(0, vp.X - w)), math.clamp(y, 0, math.max(0, vp.Y - h))
end
local PANEL_W = math.min(280, vpSize().X - 16)
local PANEL_H_MAX = math.min(460, vpSize().Y - 32)

local Values = {
    Size = 120,
    FromRight = 40,
    FromBottom = 60,
    -- Shift Lock (tombol floating + mode)
    ShiftLock = { Size = 88, FromRight = 40, FromBottom = 210 },
    ShowShiftLockBtn = true,
    ShiftLockOn = false,
}

-- ════════════════════════════════════════════════════════
-- HELPER
-- ════════════════════════════════════════════════════════
local function Tween(obj, t, props)
    TweenService:Create(obj, TweenInfo.new(t, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), props):Play()
end

local function CreateCorner(parent, r)
    local c = Instance.new("UICorner", parent)
    c.CornerRadius = UDim.new(0, r or 8)
    return c
end

local function CreateStroke(parent, col, thick, trans)
    local s = Instance.new("UIStroke", parent)
    s.Color = col or Color3.fromRGB(60, 65, 75)
    s.Thickness = thick or 1
    s.Transparency = trans or 0.4
    return s
end

-- ════════════════════════════════════════════════════════
-- WARNA
-- ════════════════════════════════════════════════════════
local C = {
    bg = Color3.fromRGB(22, 22, 32),
    bg2 = Color3.fromRGB(32, 32, 46),
    bg3 = Color3.fromRGB(42, 42, 58),
    bg4 = Color3.fromRGB(52, 52, 68),
    accent = Color3.fromRGB(85, 120, 255),
    accentDark = Color3.fromRGB(65, 95, 210),
    accentGlow = Color3.fromRGB(110, 145, 255),
    green = Color3.fromRGB(75, 210, 130),
    red = Color3.fromRGB(220, 75, 75),
    text = Color3.fromRGB(235, 235, 245),
    text2 = Color3.fromRGB(170, 175, 195),
    text3 = Color3.fromRGB(110, 115, 135),
    border = Color3.fromRGB(55, 60, 75),
    white = Color3.fromRGB(255, 255, 255),
}

-- ════════════════════════════════════════════════════════
-- SCREEN GUI
-- ════════════════════════════════════════════════════════
local GUI = Instance.new("ScreenGui")
GUI.Name = "JumpSettingsGUI"
GUI.ResetOnSpawn = false
GUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
GUI.Parent = LP.PlayerGui

-- ════════════════════════════════════════════════════════
-- CARI & APPLY JUMP BUTTON
-- ════════════════════════════════════════════════════════
local function GetJumpButton()
    local ok, result = pcall(function()
        return LP.PlayerGui.TouchGui.TouchControlFrame.JumpButton
    end)
    return ok and result or nil
end

local function ApplyJump()
    local btn = GetJumpButton()
    if not btn then return end
    btn.Size = UDim2.new(0, Values.Size, 0, Values.Size)
    btn.Position = UDim2.new(
        1, -(Values.FromRight + Values.Size),
        1, -(Values.FromBottom + Values.Size)
    )
end

task.spawn(function()
    while not isStopped() and not GetJumpButton() do task.wait(0.5) end
    if isStopped() then return end
    ApplyJump()
    while not isStopped() do task.wait(3) ApplyJump() end
end)

-- ════════════════════════════════════════════════════════
-- TOGGLE BUTTON (Tombol buka/tutup settings)
-- ════════════════════════════════════════════════════════
local ToggleBtn = Instance.new("TextButton", GUI)
ToggleBtn.Size = UDim2.new(0, 44, 0, 44)
ToggleBtn.Position = UDim2.new(0, 14, 0.4, 0)
ToggleBtn.BackgroundColor3 = C.accent
ToggleBtn.Text = ""
ToggleBtn.AutoButtonColor = false
ToggleBtn.ZIndex = 300
CreateCorner(ToggleBtn, 22)
CreateStroke(ToggleBtn, C.accentDark, 2, 0.2)

local toggleLabel = Instance.new("TextLabel", ToggleBtn)
toggleLabel.Size = UDim2.new(1, 0, 1, 0)
toggleLabel.BackgroundTransparency = 1
toggleLabel.Text = "⚙️"
toggleLabel.TextSize = 20
toggleLabel.ZIndex = 301

-- Toggle draggable
local tDrag, tDragStart, tStartPos
ToggleBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch then
        tDrag = true
        tDragStart = input.Position
        tStartPos = ToggleBtn.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                tDrag = false
            end
        end)
    end
end)
UIS.InputChanged:Connect(function(input)
    if tDrag and input.UserInputType == Enum.UserInputType.Touch then
        local d = input.Position - tDragStart
        if d.Magnitude > 6 then
            local vp = vpSize()
            local absX = tStartPos.X.Scale * vp.X + tStartPos.X.Offset + d.X
            local absY = tStartPos.Y.Scale * vp.Y + tStartPos.Y.Offset + d.Y
            local nx, ny = clampAbs(absX, absY, ToggleBtn.AbsoluteSize.X, ToggleBtn.AbsoluteSize.Y)
            ToggleBtn.Position = UDim2.new(0, nx, 0, ny)
        end
    end
end)

-- ════════════════════════════════════════════════════════
-- SHIFT LOCK (mobile) — karakter menghadap arah kamera
-- ════════════════════════════════════════════════════════
local shiftConnection = nil

local SLLockBtn = Instance.new("TextButton", GUI)
SLLockBtn.Name = "ShiftLockBtn"
SLLockBtn.Size = UDim2.new(0, Values.ShiftLock.Size, 0, Values.ShiftLock.Size)
SLLockBtn.Position = UDim2.new(1, -(Values.ShiftLock.FromRight + Values.ShiftLock.Size), 1, -(Values.ShiftLock.FromBottom + Values.ShiftLock.Size))
SLLockBtn.BackgroundColor3 = C.bg2
SLLockBtn.Text = "🔒"
SLLockBtn.TextColor3 = C.white
SLLockBtn.Font = Enum.Font.GothamBold
SLLockBtn.TextSize = math.floor(Values.ShiftLock.Size * 0.5)
SLLockBtn.AutoButtonColor = false
SLLockBtn.ZIndex = 300
SLLockBtn.Visible = Values.ShowShiftLockBtn
CreateCorner(SLLockBtn, 18)
CreateStroke(SLLockBtn, C.border, 2, 0.2)

local function ApplySLBtn()
    local sl = Values.ShiftLock
    SLLockBtn.Size = UDim2.new(0, sl.Size, 0, sl.Size)
    SLLockBtn.Position = UDim2.new(1, -(sl.FromRight + sl.Size), 1, -(sl.FromBottom + sl.Size))
    SLLockBtn.TextSize = math.max(16, math.floor(sl.Size * 0.5))
    SLLockBtn.Visible = Values.ShowShiftLockBtn
end

-- Forward declaration: di-assign nanti di tab Shift Lock
local RefreshSLVisuals = function() end

local function SetAutoRotate(state)
    local char = LP.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then hum.AutoRotate = not state end
end

local function SetShiftLock(on)
    Values.ShiftLockOn = on == true
    if shiftConnection then
        shiftConnection:Disconnect()
        shiftConnection = nil
    end
    SetAutoRotate(Values.ShiftLockOn)
    if Values.ShiftLockOn then
        shiftConnection = RunService.RenderStepped:Connect(function()
            local camera = workspace.CurrentCamera
            local char = LP.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not (camera and hrp) then return end
            local look = camera.CFrame.LookVector
            local flat = Vector3.new(look.X, 0, look.Z)
            if flat.Magnitude < 0.05 then return end
            hrp.CFrame = CFrame.lookAt(hrp.Position, hrp.Position + flat)
        end)
    end
    RefreshSLVisuals()
end

SLLockBtn.MouseButton1Click:Connect(function()
    SetShiftLock(not Values.ShiftLockOn)
end)

LP.CharacterAdded:Connect(function()
    task.wait(0.5)
    if Values.ShiftLockOn then
        SetAutoRotate(true)
        SetShiftLock(true)
    end
end)

-- ════════════════════════════════════════════════════════
-- SETTINGS PANEL
-- ════════════════════════════════════════════════════════
local panelOpen = false

local Panel = Instance.new("Frame", GUI)
Panel.Size = UDim2.new(0, PANEL_W, 0, 0)
Panel.Position = UDim2.new(0.5, -PANEL_W/2, 0.5, -PANEL_H_MAX/2)
Panel.BackgroundColor3 = C.bg
Panel.ClipsDescendants = true
Panel.Visible = false
Panel.ZIndex = 200
CreateCorner(Panel, 14)
CreateStroke(Panel, C.border, 1.5, 0.3)

-- Drag panel dipindah ke Title Bar (lihat bagian TITLE BAR di bawah)
-- supaya geser slider tidak ikut menggeser panel.

-- ════════════════════════════════════════════════════════
-- TITLE BAR
-- ════════════════════════════════════════════════════════
local TitleBar = Instance.new("Frame", Panel)
TitleBar.Size = UDim2.new(1, 0, 0, 44)
TitleBar.BackgroundColor3 = C.bg2
TitleBar.BorderSizePixel = 0
TitleBar.ZIndex = 201
CreateCorner(TitleBar, 14)

local tbPatch = Instance.new("Frame", TitleBar)
tbPatch.Size = UDim2.new(1, 0, 0, 14)
tbPatch.Position = UDim2.new(0, 0, 1, -14)
tbPatch.BackgroundColor3 = C.bg2
tbPatch.BorderSizePixel = 0
tbPatch.ZIndex = 201

local accentLine = Instance.new("Frame", TitleBar)
accentLine.Size = UDim2.new(1, 0, 0, 2)
accentLine.Position = UDim2.new(0, 0, 1, -2)
accentLine.BackgroundColor3 = C.accent
accentLine.BorderSizePixel = 0
accentLine.ZIndex = 202

local titleIcon = Instance.new("TextLabel", TitleBar)
titleIcon.Size = UDim2.new(0, 28, 1, 0)
titleIcon.Position = UDim2.new(0, 12, 0, 0)
titleIcon.BackgroundTransparency = 1
titleIcon.Text = "🎮"
titleIcon.TextSize = 18
titleIcon.ZIndex = 202

local titleText = Instance.new("TextLabel", TitleBar)
titleText.Size = UDim2.new(1, -80, 1, 0)
titleText.Position = UDim2.new(0, 42, 0, 0)
titleText.BackgroundTransparency = 1
titleText.Text = "Jump Settings"
titleText.TextColor3 = C.white
titleText.TextSize = 14
titleText.Font = Enum.Font.GothamBold
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.ZIndex = 202

-- Close button
local closeBtn = Instance.new("TextButton", TitleBar)
closeBtn.Size = UDim2.new(0, 32, 0, 32)
closeBtn.Position = UDim2.new(1, -38, 0.5, -16)
closeBtn.BackgroundColor3 = C.red
closeBtn.BackgroundTransparency = 0.7
closeBtn.Text = ""
closeBtn.AutoButtonColor = false
closeBtn.ZIndex = 202
CreateCorner(closeBtn, 8)

local closeLbl = Instance.new("TextLabel", closeBtn)
closeLbl.Size = UDim2.new(1, 0, 1, 0)
closeLbl.BackgroundTransparency = 1
closeLbl.Text = "✕"
closeLbl.TextColor3 = C.red
closeLbl.TextSize = 13
closeLbl.Font = Enum.Font.GothamBold
closeLbl.ZIndex = 203

closeBtn.MouseEnter:Connect(function() Tween(closeBtn, 0.15, {BackgroundTransparency = 0.3}) end)
closeBtn.MouseLeave:Connect(function() Tween(closeBtn, 0.15, {BackgroundTransparency = 0.7}) end)

-- ════════════════════════════════════════════════════════
-- PANEL DRAG — hanya lewat Title Bar (bagian atas panel)
-- Input di area slider/preset/content TIDAK menggeser panel.
-- Input di close button juga diabaikan agar tidak drag.
-- ════════════════════════════════════════════════════════
local pDrag, pDragStart, pStartPos
local blockDragInput = nil
closeBtn.InputBegan:Connect(function(input)
    blockDragInput = input
end)
TitleBar.InputBegan:Connect(function(input)
    if input == blockDragInput then return end
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        pDrag = true
        pDragStart = input.Position
        pStartPos = Panel.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                pDrag = false
            end
        end)
    end
end)
UIS.InputChanged:Connect(function(input)
    if pDrag and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
        local d = input.Position - pDragStart
        local vp = vpSize()
        local absX = pStartPos.X.Scale * vp.X + pStartPos.X.Offset + d.X
        local absY = pStartPos.Y.Scale * vp.Y + pStartPos.Y.Offset + d.Y
        local nx, ny = clampAbs(absX, absY, Panel.AbsoluteSize.X, Panel.AbsoluteSize.Y)
        Panel.Position = UDim2.new(0, nx, 0, ny)
    end
end)

-- ════════════════════════════════════════════════════════
-- TAB BAR (Jump / Shift Lock)
-- ════════════════════════════════════════════════════════
local TabBar = Instance.new("Frame", Panel)
TabBar.Size = UDim2.new(1, 0, 0, 34)
TabBar.Position = UDim2.new(0, 0, 0, 46)
TabBar.BackgroundColor3 = C.bg2
TabBar.BorderSizePixel = 0
TabBar.ZIndex = 201

local tabJumpBtn = Instance.new("TextButton", TabBar)
tabJumpBtn.Name = "TabJump"
tabJumpBtn.Size = UDim2.new(0.5, -6, 0, 26)
tabJumpBtn.Position = UDim2.new(0, 4, 0, 4)
tabJumpBtn.BackgroundColor3 = C.accent
tabJumpBtn.Text = "🪂  Jump"
tabJumpBtn.TextColor3 = C.white
tabJumpBtn.Font = Enum.Font.GothamBold
tabJumpBtn.TextSize = 12
tabJumpBtn.AutoButtonColor = false
tabJumpBtn.ZIndex = 202
CreateCorner(tabJumpBtn, 8)

local tabShiftBtn = Instance.new("TextButton", TabBar)
tabShiftBtn.Name = "TabShiftLock"
tabShiftBtn.Size = UDim2.new(0.5, -6, 0, 26)
tabShiftBtn.Position = UDim2.new(0.5, 2, 0, 4)
tabShiftBtn.BackgroundColor3 = C.bg3
tabShiftBtn.Text = "🔒  Shift Lock"
tabShiftBtn.TextColor3 = C.text2
tabShiftBtn.Font = Enum.Font.GothamBold
tabShiftBtn.TextSize = 12
tabShiftBtn.AutoButtonColor = false
tabShiftBtn.ZIndex = 202
CreateCorner(tabShiftBtn, 8)

-- ════════════════════════════════════════════════════════
-- CONTENT (tab Jump)
-- ════════════════════════════════════════════════════════
local Content = Instance.new("ScrollingFrame", Panel)
Content.Size = UDim2.new(1, -20, 1, -88)
Content.Position = UDim2.new(0, 10, 0, 84)
Content.BackgroundTransparency = 1
Content.ZIndex = 201
Content.BorderSizePixel = 0
Content.ScrollBarThickness = 3
Content.ScrollBarImageColor3 = C.accent
Content.CanvasSize = UDim2.new(0, 0, 0, 0)
Content.AutomaticCanvasSize = Enum.AutomaticSize.Y

local ContentPad = Instance.new("UIPadding", Content)
ContentPad.PaddingLeft = UDim.new(0, 2)
ContentPad.PaddingRight = UDim.new(0, 6)

local Layout = Instance.new("UIListLayout", Content)
Layout.Padding = UDim.new(0, 8)
Layout.SortOrder = Enum.SortOrder.LayoutOrder

-- ════════════════════════════════════════════════════════
-- CONTENT (tab Shift Lock)
-- ════════════════════════════════════════════════════════
local ContentShift = Instance.new("ScrollingFrame", Panel)
ContentShift.Size = UDim2.new(1, -20, 1, -88)
ContentShift.Position = UDim2.new(0, 10, 0, 84)
ContentShift.BackgroundTransparency = 1
ContentShift.ZIndex = 201
ContentShift.Visible = false
ContentShift.BorderSizePixel = 0
ContentShift.ScrollBarThickness = 3
ContentShift.ScrollBarImageColor3 = C.accent
ContentShift.CanvasSize = UDim2.new(0, 0, 0, 0)
ContentShift.AutomaticCanvasSize = Enum.AutomaticSize.Y

local ContentShiftPad = Instance.new("UIPadding", ContentShift)
ContentShiftPad.PaddingLeft = UDim.new(0, 2)
ContentShiftPad.PaddingRight = UDim.new(0, 6)

local LayoutShift = Instance.new("UIListLayout", ContentShift)
LayoutShift.Padding = UDim.new(0, 8)
LayoutShift.SortOrder = Enum.SortOrder.LayoutOrder

local function switchTab(tab)
    local isJump = tab == "jump"
    Content.Visible = isJump
    ContentShift.Visible = not isJump
    tabJumpBtn.BackgroundColor3 = isJump and C.accent or C.bg3
    tabJumpBtn.TextColor3 = isJump and C.white or C.text2
    tabShiftBtn.BackgroundColor3 = (not isJump) and C.accent or C.bg3
    tabShiftBtn.TextColor3 = (not isJump) and C.white or C.text2
end

tabJumpBtn.MouseButton1Click:Connect(function() switchTab("jump") end)
tabShiftBtn.MouseButton1Click:Connect(function() switchTab("shift") end)

-- ════════════════════════════════════════════════════════
-- SLIDER BUILDER
-- ════════════════════════════════════════════════════════
local function CreateSlider(parent, name, icon, min, max, default, unit, callback)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, 0, 0, 70)
    frame.BackgroundColor3 = C.bg2
    frame.ZIndex = 202
    CreateCorner(frame, 10)
    CreateStroke(frame, C.border, 1, 0.5)

    -- Header row
    local headerIcon = Instance.new("TextLabel", frame)
    headerIcon.Size = UDim2.new(0, 24, 0, 24)
    headerIcon.Position = UDim2.new(0, 10, 0, 8)
    headerIcon.BackgroundTransparency = 1
    headerIcon.Text = icon
    headerIcon.TextSize = 14
    headerIcon.ZIndex = 203

    local nameLabel = Instance.new("TextLabel", frame)
    nameLabel.Size = UDim2.new(0.5, -40, 0, 24)
    nameLabel.Position = UDim2.new(0, 36, 0, 8)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = name
    nameLabel.TextColor3 = C.text
    nameLabel.TextSize = 12
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.ZIndex = 203

    -- Value input box
    local inputFrame = Instance.new("Frame", frame)
    inputFrame.Size = UDim2.new(0, 70, 0, 26)
    inputFrame.Position = UDim2.new(1, -80, 0, 7)
    inputFrame.BackgroundColor3 = C.bg3
    inputFrame.ZIndex = 203
    CreateCorner(inputFrame, 6)
    CreateStroke(inputFrame, C.border, 1, 0.5)

    local inputBox = Instance.new("TextBox", inputFrame)
    inputBox.Size = UDim2.new(1, -8, 1, 0)
    inputBox.Position = UDim2.new(0, 4, 0, 0)
    inputBox.BackgroundTransparency = 1
    inputBox.Text = tostring(default)
    inputBox.TextColor3 = C.accent
    inputBox.PlaceholderText = "..."
    inputBox.PlaceholderColor3 = C.text3
    inputBox.TextSize = 13
    inputBox.Font = Enum.Font.GothamBold
    inputBox.TextXAlignment = Enum.TextXAlignment.Center
    inputBox.ClearTextOnFocus = true
    inputBox.ZIndex = 204

    local unitLabel = Instance.new("TextLabel", frame)
    unitLabel.Size = UDim2.new(0, 20, 0, 26)
    unitLabel.Position = UDim2.new(1, -82, 0, 7)
    unitLabel.BackgroundTransparency = 1
    unitLabel.Text = unit or "px"
    unitLabel.TextColor3 = C.text3
    unitLabel.TextSize = 9
    unitLabel.Font = Enum.Font.Gotham
    unitLabel.TextXAlignment = Enum.TextXAlignment.Right
    unitLabel.ZIndex = 203

    -- Slider track
    local sliderBg = Instance.new("Frame", frame)
    sliderBg.Size = UDim2.new(1, -24, 0, 8)
    sliderBg.Position = UDim2.new(0, 12, 0, 46)
    sliderBg.BackgroundColor3 = C.bg4
    sliderBg.ZIndex = 203
    CreateCorner(sliderBg, 4)

    local sliderFill = Instance.new("Frame", sliderBg)
    local pct = (default - min) / (max - min)
    sliderFill.Size = UDim2.new(pct, 0, 1, 0)
    sliderFill.BackgroundColor3 = C.accent
    sliderFill.ZIndex = 204
    CreateCorner(sliderFill, 4)

    -- Gradient on fill
    local fillGrad = Instance.new("UIGradient", sliderFill)
    fillGrad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, C.accentDark),
        ColorSequenceKeypoint.new(1, C.accentGlow),
    }

    local knob = Instance.new("Frame", sliderBg)
    knob.Size = UDim2.new(0, 20, 0, 20)
    knob.Position = UDim2.new(pct, -10, 0.5, -10)
    knob.BackgroundColor3 = C.white
    knob.ZIndex = 205
    CreateCorner(knob, 10)

    local knobInner = Instance.new("Frame", knob)
    knobInner.Size = UDim2.new(0, 8, 0, 8)
    knobInner.Position = UDim2.new(0.5, -4, 0.5, -4)
    knobInner.BackgroundColor3 = C.accent
    knobInner.ZIndex = 206
    CreateCorner(knobInner, 4)

    -- Min/Max labels
    local minLabel = Instance.new("TextLabel", frame)
    minLabel.Size = UDim2.new(0, 30, 0, 12)
    minLabel.Position = UDim2.new(0, 12, 0, 56)
    minLabel.BackgroundTransparency = 1
    minLabel.Text = tostring(min)
    minLabel.TextColor3 = C.text3
    minLabel.TextSize = 9
    minLabel.Font = Enum.Font.Gotham
    minLabel.TextXAlignment = Enum.TextXAlignment.Left
    minLabel.ZIndex = 203

    local maxLabel = Instance.new("TextLabel", frame)
    maxLabel.Size = UDim2.new(0, 30, 0, 12)
    maxLabel.Position = UDim2.new(1, -42, 0, 56)
    maxLabel.BackgroundTransparency = 1
    maxLabel.Text = tostring(max)
    maxLabel.TextColor3 = C.text3
    maxLabel.TextSize = 9
    maxLabel.Font = Enum.Font.Gotham
    maxLabel.TextXAlignment = Enum.TextXAlignment.Right
    maxLabel.ZIndex = 203

    -- UPDATE FUNCTION
    local function UpdateSlider(val)
        val = math.clamp(math.floor(val), min, max)
        local p = (val - min) / (max - min)
        sliderFill.Size = UDim2.new(p, 0, 1, 0)
        knob.Position = UDim2.new(p, -10, 0.5, -10)
        inputBox.Text = tostring(val)
        callback(val)
    end

    -- Slider drag
    local sliding = false

    local function StartSlide(input)
        sliding = true
        local absX = sliderBg.AbsolutePosition.X
        local absW = sliderBg.AbsoluteSize.X
        local rel = math.clamp((input.Position.X - absX) / absW, 0, 1)
        local val = min + (max - min) * rel
        UpdateSlider(val)
    end

    sliderBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            StartSlide(input)
        end
    end)

    knob.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            sliding = true
        end
    end)

    UIS.InputChanged:Connect(function(input)
        if sliding and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
            local absX = sliderBg.AbsolutePosition.X
            local absW = sliderBg.AbsoluteSize.X
            local rel = math.clamp((input.Position.X - absX) / absW, 0, 1)
            local val = min + (max - min) * rel
            UpdateSlider(val)
        end
    end)

    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            sliding = false
        end
    end)

    -- Input box manual
    inputBox.FocusLost:Connect(function(enter)
        local num = tonumber(inputBox.Text)
        if num then
            UpdateSlider(num)
        else
            inputBox.Text = tostring(math.floor(min + (max - min) * pct))
        end
    end)

    inputBox.Focused:Connect(function()
        Tween(inputFrame, 0.15, {BackgroundColor3 = C.bg4})
        local s = inputFrame:FindFirstChildOfClass("UIStroke")
        if s then Tween(s, 0.15, {Color = C.accent, Transparency = 0}) end
    end)
    inputBox.FocusLost:Connect(function()
        Tween(inputFrame, 0.15, {BackgroundColor3 = C.bg3})
        local s = inputFrame:FindFirstChildOfClass("UIStroke")
        if s then Tween(s, 0.15, {Color = C.border, Transparency = 0.5}) end
    end)

    return frame
end

-- ════════════════════════════════════════════════════════
-- PRESET BUTTONS BUILDER
-- ════════════════════════════════════════════════════════
local sliderRefs = {}

local function CreatePresets(parent)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, 0, 0, 36)
    frame.BackgroundTransparency = 1
    frame.ZIndex = 202

    local presetLabel = Instance.new("TextLabel", frame)
    presetLabel.Size = UDim2.new(1, 0, 0, 14)
    presetLabel.BackgroundTransparency = 1
    presetLabel.Text = "⚡ Quick Presets"
    presetLabel.TextColor3 = C.text3
    presetLabel.TextSize = 10
    presetLabel.Font = Enum.Font.GothamMedium
    presetLabel.TextXAlignment = Enum.TextXAlignment.Left
    presetLabel.ZIndex = 203

    local btnRow = Instance.new("Frame", frame)
    btnRow.Size = UDim2.new(1, 0, 0, 28)
    btnRow.Position = UDim2.new(0, 0, 0, 12)
    btnRow.BackgroundTransparency = 1
    btnRow.ZIndex = 202

    local rowLayout = Instance.new("UIListLayout", btnRow)
    rowLayout.FillDirection = Enum.FillDirection.Horizontal
    rowLayout.Padding = UDim.new(0, 6)

    local presets = {
        {name = "Small",  size = 70,  r = 30,  b = 40},
        {name = "Medium", size = 110, r = 40,  b = 60},
        {name = "Large",  size = 150, r = 50,  b = 80},
        {name = "XL",     size = 200, r = 30,  b = 50},
    }

    for _, preset in ipairs(presets) do
        local btn = Instance.new("TextButton", btnRow)
        btn.Size = UDim2.new(0.25, -5, 1, 0)
        btn.BackgroundColor3 = C.bg3
        btn.Text = ""
        btn.AutoButtonColor = false
        btn.ZIndex = 203
        CreateCorner(btn, 6)
        CreateStroke(btn, C.border, 1, 0.6)

        local lbl = Instance.new("TextLabel", btn)
        lbl.Size = UDim2.new(1, 0, 1, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = preset.name
        lbl.TextColor3 = C.text2
        lbl.TextSize = 11
        lbl.Font = Enum.Font.GothamMedium
        lbl.ZIndex = 204

        btn.MouseEnter:Connect(function()
            Tween(btn, 0.12, {BackgroundColor3 = C.accent})
            Tween(lbl, 0.12, {TextColor3 = C.white})
        end)
        btn.MouseLeave:Connect(function()
            Tween(btn, 0.12, {BackgroundColor3 = C.bg3})
            Tween(lbl, 0.12, {TextColor3 = C.text2})
        end)

        btn.MouseButton1Click:Connect(function()
            Values.Size = preset.size
            Values.FromRight = preset.r
            Values.FromBottom = preset.b
            ApplyJump()

            -- Flash effect
            Tween(btn, 0.1, {BackgroundColor3 = C.green})
            Tween(lbl, 0.1, {TextColor3 = C.white})
            task.wait(0.3)
            Tween(btn, 0.2, {BackgroundColor3 = C.bg3})
            Tween(lbl, 0.2, {TextColor3 = C.text2})

            -- Update semua slider
            for _, ref in pairs(sliderRefs) do
                if ref.update then ref.update() end
            end
        end)
    end

    return frame
end

-- ════════════════════════════════════════════════════════
-- RESET BUTTON
-- ════════════════════════════════════════════════════════
local function CreateResetButton(parent)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(1, 0, 0, 38)
    btn.BackgroundColor3 = C.bg2
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.ZIndex = 202
    CreateCorner(btn, 10)
    CreateStroke(btn, C.border, 1, 0.5)

    local lbl = Instance.new("TextLabel", btn)
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = "🔄 Reset to Default"
    lbl.TextColor3 = C.text2
    lbl.TextSize = 12
    lbl.Font = Enum.Font.GothamMedium
    lbl.ZIndex = 203

    btn.MouseEnter:Connect(function()
        Tween(btn, 0.12, {BackgroundColor3 = C.bg3})
    end)
    btn.MouseLeave:Connect(function()
        Tween(btn, 0.12, {BackgroundColor3 = C.bg2})
    end)

    btn.MouseButton1Click:Connect(function()
        Values.Size = 120
        Values.FromRight = 40
        Values.FromBottom = 60
        ApplyJump()

        Tween(btn, 0.1, {BackgroundColor3 = C.green})
        Tween(lbl, 0.1, {TextColor3 = C.white})
        lbl.Text = "✅ Reset Done!"
        task.wait(0.8)
        lbl.Text = "🔄 Reset to Default"
        Tween(btn, 0.2, {BackgroundColor3 = C.bg2})
        Tween(lbl, 0.2, {TextColor3 = C.text2})

        for _, ref in pairs(sliderRefs) do
            if ref.update then ref.update() end
        end
    end)

    return btn
end

-- ════════════════════════════════════════════════════════
-- BUILD SLIDERS
-- ════════════════════════════════════════════════════════
local sizeSlider = CreateSlider(Content, "Button Size", "📏", 40, 250, Values.Size, "px", function(val)
    Values.Size = val
    ApplyJump()
end)

local rightSlider = CreateSlider(Content, "From Right", "➡️", 0, 300, Values.FromRight, "px", function(val)
    Values.FromRight = val
    ApplyJump()
end)

local bottomSlider = CreateSlider(Content, "From Bottom", "⬆️", 0, 400, Values.FromBottom, "px", function(val)
    Values.FromBottom = val
    ApplyJump()
end)

-- Store refs for preset updates
local function findInputBox(slider)
    for _, v in pairs(slider:GetDescendants()) do
        if v:IsA("TextBox") then return v end
    end
end
local function findSliderParts(slider)
    local fill, kn
    for _, v in pairs(slider:GetDescendants()) do
        if v.Name == "UICorner" then continue end
        if v:IsA("Frame") and v.ZIndex == 204 and v.Parent.ZIndex == 203 then fill = v end
        if v:IsA("Frame") and v.ZIndex == 205 then kn = v end
    end
    return fill, kn
end

-- Preset update functions
table.insert(sliderRefs, {
    update = function()
        local box = findInputBox(sizeSlider)
        if box then
            box.Text = tostring(Values.Size)
            local p = (Values.Size - 40) / (250 - 40)
            local fill, kn = findSliderParts(sizeSlider)
            if fill then fill.Size = UDim2.new(p, 0, 1, 0) end
            if kn then kn.Position = UDim2.new(p, -10, 0.5, -10) end
        end
    end
})
table.insert(sliderRefs, {
    update = function()
        local box = findInputBox(rightSlider)
        if box then
            box.Text = tostring(Values.FromRight)
            local p = Values.FromRight / 300
            local fill, kn = findSliderParts(rightSlider)
            if fill then fill.Size = UDim2.new(p, 0, 1, 0) end
            if kn then kn.Position = UDim2.new(p, -10, 0.5, -10) end
        end
    end
})
table.insert(sliderRefs, {
    update = function()
        local box = findInputBox(bottomSlider)
        if box then
            box.Text = tostring(Values.FromBottom)
            local p = Values.FromBottom / 400
            local fill, kn = findSliderParts(bottomSlider)
            if fill then fill.Size = UDim2.new(p, 0, 1, 0) end
            if kn then kn.Position = UDim2.new(p, -10, 0.5, -10) end
        end
    end
})

CreatePresets(Content)
CreateResetButton(Content)

-- ════════════════════════════════════════════════════════
-- BUILD SHIFT LOCK TAB
-- ════════════════════════════════════════════════════════
-- Status toggle besar
local slStatusBtn = Instance.new("TextButton", ContentShift)
slStatusBtn.Size = UDim2.new(1, 0, 0, 52)
slStatusBtn.BackgroundColor3 = C.bg3
slStatusBtn.Text = ""
slStatusBtn.AutoButtonColor = false
slStatusBtn.ZIndex = 202
CreateCorner(slStatusBtn, 10)
CreateStroke(slStatusBtn, C.border, 1, 0.5)

local slStatusIcon = Instance.new("TextLabel", slStatusBtn)
slStatusIcon.Size = UDim2.new(0, 32, 1, 0)
slStatusIcon.Position = UDim2.new(0, 10, 0, 0)
slStatusIcon.BackgroundTransparency = 1
slStatusIcon.Text = "🔓"
slStatusIcon.TextSize = 20
slStatusIcon.ZIndex = 203

local slStatusText = Instance.new("TextLabel", slStatusBtn)
slStatusText.Size = UDim2.new(1, -54, 0, 22)
slStatusText.Position = UDim2.new(0, 44, 0, 4)
slStatusText.BackgroundTransparency = 1
slStatusText.Text = "Shift Lock: OFF"
slStatusText.TextColor3 = C.text2
slStatusText.Font = Enum.Font.GothamBold
slStatusText.TextSize = 14
slStatusText.TextXAlignment = Enum.TextXAlignment.Left
slStatusText.ZIndex = 203

local slStatusHint = Instance.new("TextLabel", slStatusBtn)
slStatusHint.Size = UDim2.new(1, -54, 0, 14)
slStatusHint.Position = UDim2.new(0, 44, 0, 27)
slStatusHint.BackgroundTransparency = 1
slStatusHint.Text = "Karakter selalu menghadap arah kamera"
slStatusHint.TextColor3 = C.text3
slStatusHint.Font = Enum.Font.Gotham
slStatusHint.TextSize = 10
slStatusHint.TextXAlignment = Enum.TextXAlignment.Left
slStatusHint.ZIndex = 203

slStatusBtn.MouseButton1Click:Connect(function()
    SetShiftLock(not Values.ShiftLockOn)
end)

-- Row: tampilkan / sembunyikan tombol floating
local slShowFrame = Instance.new("Frame", ContentShift)
slShowFrame.Size = UDim2.new(1, 0, 0, 44)
slShowFrame.BackgroundColor3 = C.bg2
slShowFrame.ZIndex = 202
CreateCorner(slShowFrame, 10)
CreateStroke(slShowFrame, C.border, 1, 0.5)

local slShowLbl = Instance.new("TextLabel", slShowFrame)
slShowLbl.Size = UDim2.new(1, -80, 1, 0)
slShowLbl.Position = UDim2.new(0, 12, 0, 0)
slShowLbl.BackgroundTransparency = 1
slShowLbl.Text = "Tampilkan Tombol di Layar"
slShowLbl.TextColor3 = C.text
slShowLbl.Font = Enum.Font.GothamBold
slShowLbl.TextSize = 11
slShowLbl.TextXAlignment = Enum.TextXAlignment.Left
slShowLbl.ZIndex = 203

local slPill = Instance.new("TextButton", slShowFrame)
slPill.Size = UDim2.new(0, 52, 0, 24)
slPill.Position = UDim2.new(1, -62, 0.5, -12)
slPill.BackgroundColor3 = C.green
slPill.Text = "ON"
slPill.TextColor3 = Color3.fromRGB(20, 40, 25)
slPill.Font = Enum.Font.GothamBold
slPill.TextSize = 11
slPill.AutoButtonColor = false
slPill.ZIndex = 203
CreateCorner(slPill, 12)

local function RefreshPill()
    if Values.ShowShiftLockBtn then
        slPill.BackgroundColor3 = C.green
        slPill.Text = "ON"
        slPill.TextColor3 = Color3.fromRGB(20, 40, 25)
    else
        slPill.BackgroundColor3 = C.bg4
        slPill.Text = "OFF"
        slPill.TextColor3 = C.text2
    end
end

slPill.MouseButton1Click:Connect(function()
    Values.ShowShiftLockBtn = not Values.ShowShiftLockBtn
    ApplySLBtn()
    RefreshPill()
end)

-- Slider ukuran & posisi (sama seperti jump button)
CreateSlider(ContentShift, "Button Size", "📏", 40, 220, Values.ShiftLock.Size, "px", function(val)
    Values.ShiftLock.Size = val
    ApplySLBtn()
end)
CreateSlider(ContentShift, "From Right", "➡️", 0, 300, Values.ShiftLock.FromRight, "px", function(val)
    Values.ShiftLock.FromRight = val
    ApplySLBtn()
end)
CreateSlider(ContentShift, "From Bottom", "⬆️", 0, 400, Values.ShiftLock.FromBottom, "px", function(val)
    Values.ShiftLock.FromBottom = val
    ApplySLBtn()
end)

-- Note kecil
local slNote = Instance.new("TextLabel", ContentShift)
slNote.Size = UDim2.new(1, 0, 0, 28)
slNote.BackgroundTransparency = 1
slNote.Text = "💡 Seperti Shift Lock di PC: karakter menghadap sesuai arah kamera. Tap tombol 🔒 di layar untuk ON/OFF."
slNote.TextColor3 = C.text3
slNote.Font = Enum.Font.Gotham
slNote.TextSize = 10
slNote.TextXAlignment = Enum.TextXAlignment.Left
slNote.TextWrapped = true
slNote.ZIndex = 202

-- Sinkron visual tombol floating + status (dipanggil SetShiftLock)
RefreshSLVisuals = function()
    if Values.ShiftLockOn then
        SLLockBtn.BackgroundColor3 = C.accent
        slStatusBtn.BackgroundColor3 = C.accentDark
        slStatusIcon.Text = "🔒"
        slStatusText.Text = "Shift Lock: ON"
        slStatusText.TextColor3 = C.green
    else
        SLLockBtn.BackgroundColor3 = C.bg2
        slStatusBtn.BackgroundColor3 = C.bg3
        slStatusIcon.Text = "🔓"
        slStatusText.Text = "Shift Lock: OFF"
        slStatusText.TextColor3 = C.text2
    end
end
ApplySLBtn()
RefreshPill()
RefreshSLVisuals()

-- ════════════════════════════════════════════════════════
-- PANEL OPEN/CLOSE
-- ════════════════════════════════════════════════════════
local PANEL_H = PANEL_H_MAX

local function OpenPanel()
    panelOpen = true
    Panel.Visible = true
    Panel.Size = UDim2.new(0, PANEL_W, 0, 0)
    Tween(Panel, 0.35, {Size = UDim2.new(0, PANEL_W, 0, PANEL_H)})
end

local function ClosePanel()
    panelOpen = false
    Tween(Panel, 0.25, {Size = UDim2.new(0, PANEL_W, 0, 0)})
    task.delay(0.25, function()
        Panel.Visible = false
    end)
end

ToggleBtn.MouseButton1Click:Connect(function()
    if panelOpen then
        ClosePanel()
    else
        OpenPanel()
    end
end)

closeBtn.MouseButton1Click:Connect(function()
    ClosePanel()
end)

-- ════════════════════════════════════════════════════════
-- DONE
-- ════════════════════════════════════════════════════════
print("✅ Jump Settings GUI loaded!")
print("📱 Tap ⚙️ untuk buka settings")
print("📏 Geser slider atau ketik angka untuk atur ukuran")
print("⚡ Gunakan preset untuk pengaturan cepat")
