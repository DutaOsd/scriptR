--[[
    REJOIN SCRIPT - FULL GUI
    Features:
    - Confirmation dialog
    - Countdown timer
    - Cancel option
    - Hotkey R
]]

local plrs = game:GetService("Players")
local tp = game:GetService("TeleportService")
local uis = game:GetService("UserInputService")
local ts = game:GetService("TweenService")

local plr = plrs.LocalPlayer
local pg = plr:WaitForChild("PlayerGui")

-- ========================================
-- REJOIN FUNCTION
-- ========================================
local function rejoin()
    print("🔄 Rejoining server...")
    tp:TeleportToPlaceInstance(game.PlaceId, game.JobId, plr)
end

-- ========================================
-- CREATE GUI
-- ========================================
local function create_gui()
    -- cleanup existing
    local existing = pg:FindFirstChild("RejoinGUI")
    if existing then existing:Destroy() end
    
    local sg = Instance.new("ScreenGui")
    sg.Name = "RejoinGUI"
    sg.ResetOnSpawn = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.Parent = pg
    
    -- Button (kanan atas)
    local btn = Instance.new("TextButton")
    btn.Name = "RejoinBtn"
    btn.Size = UDim2.new(0, 110, 0, 45)
    btn.Position = UDim2.new(1, -120, 0, 10)
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    btn.Text = ""
    btn.BorderSizePixel = 0
    btn.Parent = sg
    
    local btn_corner = Instance.new("UICorner")
    btn_corner.CornerRadius = UDim.new(0, 10)
    btn_corner.Parent = btn
    
    local btn_stroke = Instance.new("UIStroke")
    btn_stroke.Color = Color3.fromRGB(100, 100, 120)
    btn_stroke.Thickness = 2
    btn_stroke.Parent = btn
    
    -- Icon
    local icon = Instance.new("TextLabel")
    icon.Size = UDim2.new(0, 30, 0, 30)
    icon.Position = UDim2.new(0, 8, 0.5, -15)
    icon.BackgroundTransparency = 1
    icon.Text = "🔄"
    icon.TextSize = 18
    icon.Parent = btn
    
    -- Text
    local text = Instance.new("TextLabel")
    text.Size = UDim2.new(1, -45, 1, 0)
    text.Position = UDim2.new(0, 40, 0, 0)
    text.BackgroundTransparency = 1
    text.Text = "REJOIN\nSERVER"
    text.TextColor3 = Color3.new(1, 1, 1)
    text.TextSize = 11
    text.Font = Enum.Font.GothamBold
    text.TextXAlignment = Enum.TextXAlignment.Left
    text.Parent = btn
    
    -- Info label
    local info = Instance.new("TextLabel")
    info.Size = UDim2.new(0, 100, 0, 15)
    info.Position = UDim2.new(0, 5, 1, 2)
    info.BackgroundTransparency = 1
    info.Text = "Hotkey: R"
    info.TextColor3 = Color3.fromRGB(150, 150, 170)
    info.TextSize = 9
    info.Font = Enum.Font.Gotham
    info.Parent = btn
    
    -- Confirmation Dialog (hidden by default)
    local dialog = Instance.new("Frame")
    dialog.Name = "Dialog"
    dialog.Size = UDim2.new(0, 300, 0, 150)
    dialog.Position = UDim2.new(0.5, -150, 0.5, -75)
    dialog.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    dialog.BorderSizePixel = 0
    dialog.Visible = false
    dialog.Parent = sg
    
    local dialog_corner = Instance.new("UICorner")
    dialog_corner.CornerRadius = UDim.new(0, 12)
    dialog_corner.Parent = dialog
    
    local dialog_stroke = Instance.new("UIStroke")
    dialog_stroke.Color = Color3.fromRGB(80, 80, 100)
    dialog_stroke.Thickness = 2
    dialog_stroke.Parent = dialog
    
    -- Dialog Title
    local dialog_title = Instance.new("TextLabel")
    dialog_title.Size = UDim2.new(1, 0, 0, 40)
    dialog_title.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    dialog_title.Text = "🔄 Rejoin Server?"
    dialog_title.TextColor3 = Color3.new(1, 1, 1)
    dialog_title.TextSize = 15
    dialog_title.Font = Enum.Font.GothamBold
    dialog_title.BorderSizePixel = 0
    dialog_title.Parent = dialog
    
    local title_corner = Instance.new("UICorner")
    title_corner.CornerRadius = UDim.new(0, 12)
    title_corner.Parent = dialog_title
    
    local title_fix = Instance.new("Frame")
    title_fix.Size = UDim2.new(1, 0, 0, 12)
    title_fix.Position = UDim2.new(0, 0, 1, -12)
    title_fix.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    title_fix.BorderSizePixel = 0
    title_fix.Parent = dialog_title
    
    -- Dialog Message
    local dialog_msg = Instance.new("TextLabel")
    dialog_msg.Size = UDim2.new(1, -20, 0, 40)
    dialog_msg.Position = UDim2.new(0, 10, 0, 50)
    dialog_msg.BackgroundTransparency = 1
    dialog_msg.Text = "You will be teleported back\nto this server"
    dialog_msg.TextColor3 = Color3.fromRGB(200, 200, 220)
    dialog_msg.TextSize = 12
    dialog_msg.Font = Enum.Font.Gotham
    dialog_msg.Parent = dialog
    
    -- Countdown Label
    local countdown = Instance.new("TextLabel")
    countdown.Size = UDim2.new(1, 0, 0, 20)
    countdown.Position = UDim2.new(0, 0, 0, 90)
    countdown.BackgroundTransparency = 1
    countdown.Text = ""
    countdown.TextColor3 = Color3.fromRGB(255, 150, 0)
    countdown.TextSize = 11
    countdown.Font = Enum.Font.GothamBold
    countdown.Parent = dialog
    
    -- Confirm Button
    local confirm_btn = Instance.new("TextButton")
    confirm_btn.Size = UDim2.new(0, 130, 0, 35)
    confirm_btn.Position = UDim2.new(0, 10, 1, -45)
    confirm_btn.BackgroundColor3 = Color3.fromRGB(0, 150, 80)
    confirm_btn.Text = "✓ CONFIRM"
    confirm_btn.TextColor3 = Color3.new(1, 1, 1)
    confirm_btn.TextSize = 12
    confirm_btn.Font = Enum.Font.GothamBold
    confirm_btn.BorderSizePixel = 0
    confirm_btn.Parent = dialog
    
    local confirm_corner = Instance.new("UICorner")
    confirm_corner.CornerRadius = UDim.new(0, 8)
    confirm_corner.Parent = confirm_btn
    
    -- Cancel Button
    local cancel_btn = Instance.new("TextButton")
    cancel_btn.Size = UDim2.new(0, 130, 0, 35)
    cancel_btn.Position = UDim2.new(1, -140, 1, -45)
    cancel_btn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    cancel_btn.Text = "✗ CANCEL"
    cancel_btn.TextColor3 = Color3.new(1, 1, 1)
    cancel_btn.TextSize = 12
    cancel_btn.Font = Enum.Font.GothamBold
    cancel_btn.BorderSizePixel = 0
    cancel_btn.Parent = dialog
    
    local cancel_corner = Instance.new("UICorner")
    cancel_corner.CornerRadius = UDim.new(0, 8)
    cancel_corner.Parent = cancel_btn
    
    -- ========================================
    -- FUNCTIONS
    -- ========================================
    local countdown_active = false
    
    local function show_dialog()
        dialog.Visible = true
        
        -- Opening animation
        dialog.Size = UDim2.new(0, 0, 0, 0)
        ts:Create(dialog, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 300, 0, 150)
        }):Play()
    end
    
    local function hide_dialog()
        ts:Create(dialog, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, 0)
        }):Play()
        
        wait(0.2)
        dialog.Visible = false
        countdown.Text = ""
        countdown_active = false
    end
    
    local function start_countdown()
        countdown_active = true
        
        for i = 3, 1, -1 do
            if not countdown_active then break end
            countdown.Text = "Rejoining in " .. i .. "..."
            wait(1)
        end
        
        if countdown_active then
            rejoin()
        end
    end
    
    -- ========================================
    -- EVENT HANDLERS
    -- ========================================
    
    -- Main button click
    btn.MouseButton1Click:Connect(function()
        show_dialog()
    end)
    
    -- Confirm button
    confirm_btn.MouseButton1Click:Connect(function()
        start_countdown()
    end)
    
    -- Cancel button
    cancel_btn.MouseButton1Click:Connect(function()
        hide_dialog()
    end)
    
    -- Hover effects
    btn.MouseEnter:Connect(function()
        ts:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(60, 60, 70)}):Play()
        ts:Create(btn_stroke, TweenInfo.new(0.2), {Thickness = 3}):Play()
    end)
    
    btn.MouseLeave:Connect(function()
        ts:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(40, 40, 50)}):Play()
        ts:Create(btn_stroke, TweenInfo.new(0.2), {Thickness = 2}):Play()
    end)
    
    -- Drag button
    local dragging = false
    local drag_start = nil
    local start_pos = nil
    
    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            drag_start = input.Position
            start_pos = btn.Position
        end
    end)
    
    uis.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or
           input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - drag_start
            btn.Position = UDim2.new(
                start_pos.X.Scale,
                start_pos.X.Offset + delta.X,
                start_pos.Y.Scale,
                start_pos.Y.Offset + delta.Y
            )
        end
    end)
    
    uis.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    
    return sg
end

-- ========================================
-- HOTKEY (R)
-- ========================================
uis.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.R then
        rejoin()
    end
end)

-- ========================================
-- INIT
-- ========================================
create_gui()

print("━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("🔄 REJOIN SCRIPT LOADED")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("📌 Press R for instant rejoin")
print("📌 Or click button for confirmation")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━")
