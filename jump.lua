-- ════════════════════════════════════════════════════════
-- CUSTOM JUMP BUTTON SETTINGS GUI - Mobile
-- Atur ukuran & posisi tombol jump dengan GUI
-- ════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
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
local Values = {
    Size = 120,
    FromRight = 40,
    FromBottom = 60,
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
    while not GetJumpButton() do task.wait(0.5) end
    ApplyJump()
    while task.wait(3) do ApplyJump() end
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
            ToggleBtn.Position = UDim2.new(
                tStartPos.X.Scale, tStartPos.X.Offset + d.X,
                tStartPos.Y.Scale, tStartPos.Y.Offset + d.Y
            )
        end
    end
end)

-- ════════════════════════════════════════════════════════
-- SETTINGS PANEL
-- ════════════════════════════════════════════════════════
local panelOpen = false

local Panel = Instance.new("Frame", GUI)
Panel.Size = UDim2.new(0, 280, 0, 0)
Panel.Position = UDim2.new(0.5, -140, 0.5, -160)
Panel.BackgroundColor3 = C.bg
Panel.ClipsDescendants = true
Panel.Visible = false
Panel.ZIndex = 200
CreateCorner(Panel, 14)
CreateStroke(Panel, C.border, 1.5, 0.3)

-- Panel Drag
local pDrag, pDragStart, pStartPos
Panel.InputBegan:Connect(function(input)
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
        Panel.Position = UDim2.new(
            pStartPos.X.Scale, pStartPos.X.Offset + d.X,
            pStartPos.Y.Scale, pStartPos.Y.Offset + d.Y
        )
    end
end)

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
-- CONTENT
-- ════════════════════════════════════════════════════════
local Content = Instance.new("Frame", Panel)
Content.Size = UDim2.new(1, -20, 1, -54)
Content.Position = UDim2.new(0, 10, 0, 50)
Content.BackgroundTransparency = 1
Content.ZIndex = 201

local Layout = Instance.new("UIListLayout", Content)
Layout.Padding = UDim.new(0, 8)
Layout.SortOrder = Enum.SortOrder.LayoutOrder

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
-- PANEL OPEN/CLOSE
-- ════════════════════════════════════════════════════════
local PANEL_H = 370

local function OpenPanel()
    panelOpen = true
    Panel.Visible = true
    Panel.Size = UDim2.new(0, 280, 0, 0)
    Tween(Panel, 0.35, {Size = UDim2.new(0, 280, 0, PANEL_H)})
end

local function ClosePanel()
    panelOpen = false
    Tween(Panel, 0.25, {Size = UDim2.new(0, 280, 0, 0)})
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
