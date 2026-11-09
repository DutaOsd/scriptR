-- ════════════════════════════════════════════════════════
-- SPEEDOMETER  ·  Kecepatan gerak avatar
-- Menampilkan kecepatan gerakan (studs/s + ~km/h) di atas kepala.
-- Warna berubah: hijau (santai) → kuning (cepat) → merah (super cepat)
--
-- Cara pakai: jalankan lewat loader atau executor.
-- Tombol floating 🏃 di kanan atas = tampilkan/sembunyikan.
-- ════════════════════════════════════════════════════════

local Players        = game:GetService("Players")
local RunService     = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LP = Players.LocalPlayer
if not LP then
    warn("Speedometer: LocalPlayer tidak ditemukan, jalankan di client!")
    return
end

local BILLBOARD_NAME = "SpeedometerBillboard"
local TOGGLE_NAME    = "SpeedometerToggle"
local STUD_TO_KMH    = 0.28 * 3.6  -- 1 stud ≈ 0.28 meter → kalikan 3.6 untuk km/h
local UPDATE_INTERVAL = 0.1

-- ════════════════════════════════════════════════════════
-- HAPUS GUI LAMA
-- ════════════════════════════════════════════════════════
local function cleanupOld()
    local guiParent = nil
    pcall(function() guiParent = game:GetService("CoreGui") end)
    if not guiParent then
        pcall(function() guiParent = LP:WaitForChild("PlayerGui") end)
    end
    if guiParent then
        local old = guiParent:FindFirstChild(TOGGLE_NAME)
        if old then old:Destroy() end
    end
    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        local old = hrp:FindFirstChild(BILLBOARD_NAME)
        if old then old:Destroy() end
    end
end
cleanupOld()

-- ════════════════════════════════════════════════════════
-- STOP-FLAG KOOPERATIF (loader tombol "Tutup")
-- ════════════════════════════════════════════════════════
local function isStopped()
    local ok, env = pcall(function()
        if type(getgenv) == "function" then return getgenv() end
        return _G
    end)
    if not ok or type(env) ~= "table" then return false end
    local t = env.ScriptR_Stop
    return type(t) == "table" and t["speedometer.lua"] == true
end

-- ════════════════════════════════════════════════════════
-- BILLBOARD (di atas kepala avatar)
-- ════════════════════════════════════════════════════════
local billboard = nil
local speedText = nil
local detailText = nil

local function createBillboard(char)
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local old = hrp:FindFirstChild(BILLBOARD_NAME)
    if old then old:Destroy() end

    local bb = Instance.new("BillboardGui")
    bb.Name = BILLBOARD_NAME
    bb.Size = UDim2.new(0, 150, 0, 52)
    bb.StudsOffset = Vector3.new(0, 3.1, 0)
    bb.AlwaysOnTop = true
    bb.MaxDistance = 0 -- selalu tampil (milik sendiri)
    bb.Parent = hrp

    local bg = Instance.new("Frame", bb)
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
    bg.BackgroundTransparency = 0.15
    bg.BorderSizePixel = 0
    Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 10)

    local stroke = Instance.new("UIStroke", bg)
    stroke.Color = Color3.fromRGB(120, 90, 255)
    stroke.Thickness = 1.5
    stroke.Transparency = 0.2

    speedText = Instance.new("TextLabel", bg)
    speedText.Size = UDim2.new(1, -12, 0, 26)
    speedText.Position = UDim2.new(0, 6, 0, 2)
    speedText.BackgroundTransparency = 1
    speedText.Text = "0.0"
    speedText.TextColor3 = Color3.fromRGB(120, 255, 160)
    speedText.Font = Enum.Font.GothamBlack
    speedText.TextSize = 21
    speedText.Parent = bg

    detailText = Instance.new("TextLabel", bg)
    detailText.Size = UDim2.new(1, -12, 0, 14)
    detailText.Position = UDim2.new(0, 6, 0, 29)
    detailText.BackgroundTransparency = 1
    detailText.Text = "studs/s · ~0 km/h"
    detailText.TextColor3 = Color3.fromRGB(170, 170, 200)
    detailText.Font = Enum.Font.Gotham
    detailText.TextSize = 10
    detailText.Parent = bg

    billboard = bb
end

-- Pasang pada karakter saat ini & setiap respawn
if LP.Character then
    createBillboard(LP.Character)
end
LP.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    createBillboard(char)
end)

-- ════════════════════════════════════════════════════════
-- TOMBOL FLOATING (tampilkan / sembunyikan billboard)
-- ════════════════════════════════════════════════════════
local guiParent = nil
pcall(function() guiParent = game:GetService("CoreGui") end)
if not guiParent then
    guiParent = LP:WaitForChild("PlayerGui")
end

local sg = Instance.new("ScreenGui")
sg.Name = TOGGLE_NAME
sg.ResetOnSpawn = false
sg.IgnoreGuiInset = true
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.Parent = guiParent

local toggleBtn = Instance.new("TextButton", sg)
toggleBtn.Size = UDim2.new(0, 42, 0, 42)
toggleBtn.Position = UDim2.new(1, -52, 0, 120)
toggleBtn.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
toggleBtn.BackgroundTransparency = 0.1
toggleBtn.Text = "🏃"
toggleBtn.TextSize = 20
toggleBtn.AutoButtonColor = false
toggleBtn.ZIndex = 100
toggleBtn.Parent = sg
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(1, 0)
local toggleStroke = Instance.new("UIStroke", toggleBtn)
toggleStroke.Color = Color3.fromRGB(120, 90, 255)
toggleStroke.Thickness = 2

local billboardVisible = true
toggleBtn.MouseButton1Click:Connect(function()
    billboardVisible = not billboardVisible
    if billboard then billboard.Enabled = billboardVisible end
    toggleStroke.Color = billboardVisible and Color3.fromRGB(120, 90, 255) or Color3.fromRGB(80, 80, 80)
    toggleBtn.Text = billboardVisible and "🏃" or "🚫"
end)

-- ════════════════════════════════════════════════════════
-- UPDATE LOOP
-- ════════════════════════════════════════════════════════
local acc = 0
local updateConn
updateConn = RunService.Heartbeat:Connect(function(dt)
    -- Stop-flag kooperatif: bersihkan semuanya lalu disconnect
    if isStopped() then
        if billboard then
            billboard:Destroy()
            billboard = nil
        end
        sg:Destroy()
        if updateConn then updateConn:Disconnect() end
        return
    end

    acc += dt
    if acc < UPDATE_INTERVAL then return end
    acc = 0

    local char = LP.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    -- Kalau billboard hilang (mis. respawn), pasang ulang
    local bb = hrp:FindFirstChild(BILLBOARD_NAME)
    if not bb then
        createBillboard(char)
        bb = billboard
        if bb then bb.Enabled = billboardVisible end
    else
        bb.Enabled = billboardVisible
        billboard = bb
    end

    -- Kecepatan horizontal (mengabaikan lompat/jatuh biar tidak bias)
    local vel = hrp.AssemblyLinearVelocity
    local hSpeed = Vector3.new(vel.X, 0, vel.Z).Magnitude

    local color
    if hSpeed < 17 then
        color = Color3.fromRGB(120, 255, 160)  -- santai
    elseif hSpeed < 60 then
        color = Color3.fromRGB(255, 215, 90)   -- cepat
    else
        color = Color3.fromRGB(255, 95, 85)    -- super cepat
    end

    if speedText then
        speedText.Text = string.format("%.1f", hSpeed)
        speedText.TextColor3 = color
    end
    if detailText then
        detailText.Text = string.format("studs/s · ~%.0f km/h", hSpeed * STUD_TO_KMH)
    end
end)

print("✅ Speedometer aktif! Kecepatanmu tampil di atas kepala. Tombol 🏃 kanan atas = show/hide.")
