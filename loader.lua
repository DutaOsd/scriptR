-- ════════════════════════════════════════════════════════
-- SCRIPTR LOADER  ·  One script to run them all
-- Menu GUI launcher untuk semua script di repo DutaOsd/scriptR
-- Branch: arena/e872378e-scriptr
--
-- Cara pakai:
--   Jalankan file ini lewat executor kamu, lalu klik script
--   yang ingin dijalankan. Script di-fetch dari raw GitHub.
--
-- Catatan:
--   - Repo HARUS public (atau raw URL bisa diakses).
--   - Butuh koneksi internet saat fetch.
--   - Kalau raw.githubusercontent.com diblokir, ganti BASE_URL
--     ke jsdelivr, contoh:
--     https://cdn.jsdelivr.net/gh/DutaOsd/scriptR@arena/e872378e-scriptr/
-- ════════════════════════════════════════════════════════

local BASE_URL = "https://raw.githubusercontent.com/DutaOsd/scriptR/arena/e872378e-scriptr/"

-- Daftar script yang tersedia (nama file -> judul & deskripsi di menu)
local SCRIPTS = {
    { file = "BoatyardDelta.lua", title = "Boatyard Delta",  desc = "Shop Item Finder Pro · auto-buy, anti-AFK" },
    { file = "K2.lua",            title = "Solara Hub V5",   desc = "Full bright, zoom, HP regen, fly, ESP" },
    { file = "ObbyHelperPro.lua", title = "Obby Helper Pro", desc = "Auto-complete obby v3.2" },
    { file = "antartika.lua",     title = "Antartika Vision",desc = "Fog, cuaca, waktu, night vision, speed" },
    { file = "bag.lua",           title = "Custom Hotbar",   desc = "Hotbar 10 slot custom" },
    { file = "daun.lua",          title = "Leaf Simulator",  desc = "Configurator V2 · mobile + PC" },
    { file = "fly.lua",           title = "Universal Fly",   desc = "Fly V2 · mobile joystick + PC WASD" },
    { file = "jump.lua",          title = "Jump Settings",   desc = "Atur ukuran & posisi tombol jump (mobile)" },
    { file = "noclip.lua",        title = "NoClip",          desc = "NoClip · shortcut K" },
    { file = "path.lua",          title = "Path Movement",   desc = "Path visualizer + record/replay obby" },
    { file = "rejoin.lua",        title = "Rejoin",          desc = "Auto rejoin server · hotkey R" },
    { file = "wasd.lua",          title = "WASD Mobile",     desc = "Tombol WASD virtual untuk mobile" },
}

-- ════════════════════════════════════════════════════════
-- SERVICES
-- ════════════════════════════════════════════════════════
local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local StarterGui       = game:GetService("StarterGui")
local HttpService      = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    warn("ScriptR Loader: LocalPlayer tidak ditemukan, jalankan di client!")
    return
end

local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- ════════════════════════════════════════════════════════
-- CLEANUP GUI LAMA
-- ════════════════════════════════════════════════════════
local guiParent = nil
pcall(function() guiParent = game:GetService("CoreGui") end)
if not guiParent then
    guiParent = LocalPlayer:WaitForChild("PlayerGui")
end

local old = guiParent:FindFirstChild("ScriptRLoader")
if old then old:Destroy() end

-- ════════════════════════════════════════════════════════
-- HELPERS
-- ════════════════════════════════════════════════════════
local function notify(title, text)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = 4,
        })
    end)
end

local function httpGet(url)
    local ok, result = pcall(function()
        return game:HttpGet(url)
    end)
    if ok and result then return result end
    -- Fallback untuk executor yang pakai syn.request / request
    local req = (syn and syn.request) or (http and http.request) or request
    if req then
        local ok2, res = pcall(req, { Url = url, Method = "GET" })
        if ok2 and res and res.Body then return res.Body end
    end
    return nil
end

local function runScript(entry, statusLabel)
    local url = BASE_URL .. entry.file
    statusLabel.Text = "⏳ Fetching " .. entry.file .. " ..."
    statusLabel.TextColor3 = Color3.fromRGB(255, 200, 80)

    local source = httpGet(url)
    if not source then
        statusLabel.Text = "❌ Gagal fetch " .. entry.file .. " (cek internet / repo public / URL)"
        statusLabel.TextColor3 = Color3.fromRGB(255, 90, 90)
        notify("ScriptR Loader", "Gagal fetch " .. entry.file)
        return
    end

    local fn, compileErr = loadstring(source, entry.file)
    if not fn then
        statusLabel.Text = "❌ Gagal compile: " .. tostring(compileErr)
        statusLabel.TextColor3 = Color3.fromRGB(255, 90, 90)
        notify("ScriptR Loader", "Gagal compile " .. entry.file)
        return
    end

    local ok, runErr = pcall(fn)
    if ok then
        statusLabel.Text = "✅ " .. entry.title .. " berjalan"
        statusLabel.TextColor3 = Color3.fromRGB(90, 255, 150)
        notify("ScriptR Loader", entry.title .. " berhasil dijalankan")
    else
        statusLabel.Text = "❌ Error: " .. tostring(runErr):sub(1, 120)
        statusLabel.TextColor3 = Color3.fromRGB(255, 90, 90)
        notify("ScriptR Loader", "Error di " .. entry.file)
    end
end

-- ════════════════════════════════════════════════════════
-- GUI
-- ════════════════════════════════════════════════════════
local sg = Instance.new("ScreenGui")
sg.Name = "ScriptRLoader"
sg.ResetOnSpawn = false
sg.IgnoreGuiInset = true
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.Parent = guiParent

local main = Instance.new("Frame")
main.Name = "Main"
main.Size = isMobile and UDim2.new(0, 320, 0, 420) or UDim2.new(0, 380, 0, 460)
main.Position = UDim2.new(0.5, -main.Size.X.Offset / 2, 0.5, -main.Size.Y.Offset / 2)
main.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
main.BorderSizePixel = 0
main.Parent = sg

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 14)
mainCorner.Parent = main

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(120, 90, 255)
mainStroke.Thickness = 1.5
mainStroke.Transparency = 0.3
mainStroke.Parent = main

-- ===== Header (draggable) =====
local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 46)
header.BackgroundColor3 = Color3.fromRGB(26, 24, 40)
header.BorderSizePixel = 0
header.Parent = main

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 14)
headerCorner.Parent = header

-- Tutup sudut bawah header supaya nyatu dengan body
local headerFix = Instance.new("Frame")
headerFix.Size = UDim2.new(1, 0, 0, 14)
headerFix.Position = UDim2.new(0, 0, 1, -14)
headerFix.BackgroundColor3 = header.BackgroundColor3
headerFix.BorderSizePixel = 0
headerFix.Parent = header

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -110, 0, 26)
title.Position = UDim2.new(0, 14, 0, 2)
title.BackgroundTransparency = 1
title.Text = "SCRIPTR LOADER"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 17
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(1, -110, 0, 16)
subtitle.Position = UDim2.new(0, 14, 0, 22)
subtitle.BackgroundTransparency = 1
subtitle.Text = "Pilih script yang mau dijalankan"
subtitle.TextColor3 = Color3.fromRGB(160, 160, 190)
subtitle.Font = Enum.Font.Gotham
subtitle.TextSize = 11
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Parent = header

local function makeHeaderButton(text, color, xOffset)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 34, 0, 30)
    btn.Position = UDim2.new(1, xOffset, 0.5, -15)
    btn.BackgroundColor3 = color
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 15
    btn.AutoButtonColor = true
    btn.Parent = header
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 8)
    c.Parent = btn
    return btn
end

local minimizeBtn = makeHeaderButton("–", Color3.fromRGB(60, 60, 85), -84)
local closeBtn    = makeHeaderButton("×", Color3.fromRGB(200, 70, 70), -44)

-- ===== Status bar =====
local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -20, 0, 22)
status.Position = UDim2.new(0, 10, 0, 52)
status.BackgroundTransparency = 1
status.Text = "Siap. Klik salah satu script di bawah."
status.TextColor3 = Color3.fromRGB(170, 170, 200)
status.Font = Enum.Font.Gotham
status.TextSize = 11
status.TextXAlignment = Enum.TextXAlignment.Left
status.TextTruncate = Enum.TextTruncate.AtEnd
status.Parent = main

-- ===== Scroll list =====
local scroll = Instance.new("ScrollingFrame")
scroll.Name = "List"
scroll.Size = UDim2.new(1, -20, 1, -96)
scroll.Position = UDim2.new(0, 10, 0, 78)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 4
scroll.ScrollBarImageColor3 = Color3.fromRGB(120, 90, 255)
scroll.CanvasSize = UDim2.new(0, 0, 0, #SCRIPTS * 62 + 8)
scroll.Parent = main

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 8)
listLayout.Parent = scroll

local function makeScriptButton(entry)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -6, 0, 54)
    btn.BackgroundColor3 = Color3.fromRGB(32, 30, 50)
    btn.AutoButtonColor = true
    btn.Text = ""
    btn.Parent = scroll

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 10)
    c.Parent = btn

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(70, 65, 110)
    stroke.Thickness = 1
    stroke.Transparency = 0.4
    stroke.Parent = btn

    local t = Instance.new("TextLabel")
    t.Size = UDim2.new(1, -20, 0, 22)
    t.Position = UDim2.new(0, 12, 0, 4)
    t.BackgroundTransparency = 1
    t.Text = entry.title
    t.TextColor3 = Color3.fromRGB(255, 255, 255)
    t.Font = Enum.Font.GothamBold
    t.TextSize = 14
    t.TextXAlignment = Enum.TextXAlignment.Left
    t.Parent = btn

    local d = Instance.new("TextLabel")
    d.Size = UDim2.new(1, -20, 0, 16)
    d.Position = UDim2.new(0, 12, 0, 27)
    d.BackgroundTransparency = 1
    d.Text = entry.desc
    d.TextColor3 = Color3.fromRGB(155, 155, 185)
    d.Font = Enum.Font.Gotham
    d.TextSize = 11
    d.TextXAlignment = Enum.TextXAlignment.Left
    d.TextTruncate = Enum.TextTruncate.AtEnd
    d.Parent = btn

    btn.MouseButton1Click:Connect(function()
        -- Feedback visual kecil
        TweenService:Create(btn, TweenInfo.new(0.08), { BackgroundColor3 = Color3.fromRGB(60, 55, 100) }):Play()
        task.delay(0.12, function()
            TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(32, 30, 50) }):Play()
        end)
        task.spawn(runScript, entry, status)
    end)

    return btn
end

for _, entry in ipairs(SCRIPTS) do
    makeScriptButton(entry)
end

-- ===== Minimize / Close =====
local minimized = false
local expandedSize = main.Size
minimizeBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        scroll.Visible = false
        status.Visible = false
        TweenService:Create(main, TweenInfo.new(0.2), { Size = UDim2.new(expandedSize.X.Scale, expandedSize.X.Offset, 0, 46) }):Play()
        minimizeBtn.Text = "+"
    else
        scroll.Visible = true
        status.Visible = true
        TweenService:Create(main, TweenInfo.new(0.2), { Size = expandedSize }):Play()
        minimizeBtn.Text = "–"
    end
end)

closeBtn.MouseButton1Click:Connect(function()
    sg:Destroy()
end)

-- ===== Drag (header) =====
local dragging, dragInput, dragStart, startPos

header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = main.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

header.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input == dragInput then
        local delta = input.Position - dragStart
        main.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

notify("ScriptR Loader", "Loader siap · pilih script dari menu")
print("✅ ScriptR Loader loaded · " .. #SCRIPTS .. " scripts tersedia")
