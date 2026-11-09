local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local UIS = game:GetService("UserInputService")
local player = Players.LocalPlayer

-- Matikan backpack bawaan
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

-- Hapus GUI lama kalau ada
local pg = player:WaitForChild("PlayerGui")
local old = pg:FindFirstChild("CustomHotbar10")
if old then old:Destroy() end

-- Buat ScreenGui baru
local sg = Instance.new("ScreenGui")
sg.Name = "CustomHotbar10"
sg.ResetPlayerGuiOnSpawn = false
sg.IgnoreGuiInset = true
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.Parent = pg

-- Frame utama
local main = Instance.new("Frame")
main.Size = UDim2.new(0, 0, 0, 56)
main.Position = UDim2.new(0.5, 0, 1, -65)
main.AnchorPoint = Vector2.new(0.5, 0)
main.BackgroundTransparency = 1
main.Parent = sg

local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Horizontal
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.Padding = UDim.new(0, 3)
layout.Parent = main

-- Deteksi layar mobile biar ukuran pas + diklam agar muat layar
local isMobile = UIS.TouchEnabled
local vp = (workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize) or Vector2.new(1280, 720)
local maxSlot = math.floor((vp.X - 16 - 27 - 10) / 10) -- 10 slot + 9 gap(3px) + padding
local slotSize = math.max(26, math.min(isMobile and 42 or 50, maxSlot))

-- Buat 10 slot
local slots = {}
for i = 1, 10 do
    local btn = Instance.new("ImageButton")
    btn.Name = "S" .. i
    btn.Size = UDim2.new(0, slotSize, 0, slotSize)
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    btn.BackgroundTransparency = 0.4
    btn.BorderSizePixel = 0
    btn.Image = ""
    btn.ScaleType = Enum.ScaleType.Fit
    btn.Parent = main

    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Thickness = 2
    stroke.Enabled = false
    stroke.Parent = btn

    local num = Instance.new("TextLabel")
    num.Size = UDim2.new(1, 0, 0, 14)
    num.Position = UDim2.new(0, 0, 1, -14)
    num.BackgroundTransparency = 1
    num.Text = tostring(i % 10)
    num.TextColor3 = Color3.fromRGB(220, 220, 220)
    num.TextSize = 10
    num.Font = Enum.Font.GothamBold
    num.ZIndex = 3
    num.Parent = btn

    -- Nama item
    local lbl = Instance.new("TextLabel")
    lbl.Name = "ItemName"
    lbl.Size = UDim2.new(1, 0, 0, 12)
    lbl.Position = UDim2.new(0, 0, 0, 2)
    lbl.BackgroundTransparency = 1
    lbl.Text = ""
    lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    lbl.TextSize = 7
    lbl.Font = Enum.Font.Gotham
    lbl.TextTruncate = Enum.TextTruncate.AtEnd
    lbl.ZIndex = 3
    lbl.Parent = btn

    slots[i] = {Btn = btn, Stroke = stroke, Tool = nil}

    -- Tap untuk equip (mobile & desktop)
    btn.MouseButton1Click:Connect(function()
        equipSlot(i)
    end)
end

-- Sesuaikan ukuran frame utama
main.Size = UDim2.new(0, 10 * slotSize + 9 * 3 + 10, 0, slotSize + 8)

-- ============================================
-- FUNGSI EQUIP
-- ============================================
function equipSlot(i)
    local tool = slots[i].Tool
    if not tool then return end
    local char = player.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    if tool.Parent == player:FindFirstChild("Backpack") then
        hum:EquipTool(tool)
    elseif tool.Parent == char then
        hum:UnequipTools()
    end
end

-- ============================================
-- FUNGSI UPDATE TAMPILAN
-- ============================================
local function refresh()
    -- Reset semua
    for i = 1, 10 do
        slots[i].Tool = nil
        slots[i].Btn.Image = ""
        slots[i].Btn.ItemName.Text = ""
        slots[i].Btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        slots[i].Stroke.Enabled = false
    end

    local idx = 1
    local char = player.Character
    local bp = player:FindFirstChild("Backpack")

    -- Tool yang sedang dipegang (di character)
    if char then
        for _, v in ipairs(char:GetChildren()) do
            if v:IsA("Tool") and idx <= 10 then
                slots[idx].Tool = v
                slots[idx].Btn.Image = v.TextureId
                slots[idx].Btn.ItemName.Text = v.Name
                slots[idx].Btn.BackgroundColor3 = Color3.fromRGB(60, 120, 60)
                slots[idx].Stroke.Enabled = true
                idx = idx + 1
            end
        end
    end

    -- Tool di backpack
    if bp then
        for _, v in ipairs(bp:GetChildren()) do
            if v:IsA("Tool") and idx <= 10 then
                slots[idx].Tool = v
                slots[idx].Btn.Image = v.TextureId
                slots[idx].Btn.ItemName.Text = v.Name
                idx = idx + 1
            end
        end
    end
end

-- ============================================
-- KEYBOARD (Desktop)
-- ============================================
local keys = {
    [Enum.KeyCode.One]=1,[Enum.KeyCode.Two]=2,[Enum.KeyCode.Three]=3,
    [Enum.KeyCode.Four]=4,[Enum.KeyCode.Five]=5,[Enum.KeyCode.Six]=6,
    [Enum.KeyCode.Seven]=7,[Enum.KeyCode.Eight]=8,[Enum.KeyCode.Nine]=9,
    [Enum.KeyCode.Zero]=10
}
UIS.InputBegan:Connect(function(input, gp)
    if gp then return end
    if keys[input.KeyCode] then
        equipSlot(keys[input.KeyCode])
    end
end)

-- ============================================
-- LISTENER OTOMATIS
-- ============================================
local bp = player:WaitForChild("Backpack")
bp.ChildAdded:Connect(function() task.wait(0.1) refresh() end)
bp.ChildRemoved:Connect(function() task.wait(0.1) refresh() end)

player.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    refresh()
    char.ChildAdded:Connect(function(c) if c:IsA("Tool") then task.wait(0.1) refresh() end end)
    char.ChildRemoved:Connect(function(c) if c:IsA("Tool") then task.wait(0.1) refresh() end end)
end)

task.wait(1)
refresh()
print("✅ Custom GUI 10 Slot aktif!")
