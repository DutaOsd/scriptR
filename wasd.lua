local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

-- Hapus GUI lama kalau ada
local pg = player:WaitForChild("PlayerGui")
local old = pg:FindFirstChild("WASD_Mobile")
if old then old:Destroy() end

-- Buat ScreenGui
local sg = Instance.new("ScreenGui")
sg.Name = "WASD_Mobile"
sg.ResetPlayerGuiOnSpawn = false
sg.IgnoreGuiInset = true
sg.Parent = pg

-- Container (kiri bawah layar)
local container = Instance.new("Frame")
container.Size = UDim2.new(0, 175, 0, 175)
container.Position = UDim2.new(0, 15, 1, -210)
container.BackgroundTransparency = 1
container.Parent = sg

-- Fungsi buat tombol
local function makeBtn(text, x, y)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 52, 0, 52)
    btn.Position = UDim2.new(0, x, 0, y)
    btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    btn.BackgroundTransparency = 0.6
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 22
    btn.Font = Enum.Font.GothamBold
    btn.Parent = container
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 12)
    local s = Instance.new("UIStroke")
    s.Color = Color3.fromRGB(200, 200, 200)
    s.Thickness = 2
    s.Transparency = 0.4
    s.Parent = btn
    return btn
end

-- Susunan tombol:
--      [ W ]
--   [ A ] [ D ]
--      [ S ]
local btnW = makeBtn("W", 62, 0)
local btnA = makeBtn("A", 0, 62)
local btnD = makeBtn("D", 124, 62)
local btnS = makeBtn("S", 62, 124)

-- Track tombol yang sedang ditekan
local pressed = {}

local function bindBtn(btn, key)
    btn.MouseButton1Down:Connect(function()
        pressed[key] = true
        btn.BackgroundTransparency = 0.25
        btn.BackgroundColor3 = Color3.fromRGB(100, 200, 255)
    end)
    btn.MouseButton1Up:Connect(function()
        pressed[key] = nil
        btn.BackgroundTransparency = 0.6
        btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    end)
end

bindBtn(btnW, "W")
bindBtn(btnA, "A")
bindBtn(btnS, "S")
bindBtn(btnD, "D")

-- Arah gerak (relative ke kamera)
local dirs = {
    W = Vector3.new(0, 0, -1),  -- maju
    A = Vector3.new(-1, 0, 0),  -- kiri
    S = Vector3.new(0, 0, 1),   -- mundur
    D = Vector3.new(1, 0, 0),   -- kanan
}

-- Loop gerak setiap frame
RunService.RenderStepped:Connect(function()
    local char = player.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    local moveDir = Vector3.new(0, 0, 0)
    for key, _ in pairs(pressed) do
        moveDir = moveDir + dirs[key]
    end

    if moveDir.Magnitude > 0 then
        moveDir = moveDir.Unit
        hum:Move(moveDir, true) -- true = relatif ke kamera
    end
end)

print("✅ WASD Mobile aktif!")
print("💡 Tombol W-A-S-D ada di kiri bawah layar")
