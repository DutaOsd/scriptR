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
-- beta = true  → ditandai BETA (masih bermasalah)
-- stop = {...} → instance (di CoreGui/PlayerGui/workspace/Lighting) yang
--                dihancurkan saat tombol "Tutup" di tab Running ditekan.
--                Nama harus sama persis dengan yang dibuat script.
local SCRIPTS = {
    { file = "BoatyardDelta.lua", title = "Boatyard Delta",  desc = "Shop Item Finder Pro · auto-buy, anti-AFK", stop = { "ShopFinderGUI_Clean" } },
    { file = "K2.lua",            title = "Solara Hub V5",   desc = "Full bright, zoom, HP regen, fly, ESP",     stop = { "SolaraHubV5", "SolaraESPv5", "SolaraESPParts" } },
    { file = "ObbyHelperPro.lua", title = "Obby Helper Pro", desc = "Auto-complete obby v3.2",                   stop = { "ObbyHelperGUI" } },
    { file = "antartika.lua",     title = "Antartika Vision",desc = "Fog, cuaca, waktu, night vision, speed",    stop = { "VisionControlGUI", "NightVisionCC" } },
    { file = "bag.lua",           title = "Custom Hotbar",   desc = "Hotbar 10 slot custom",                     stop = { "CustomHotbar10" }, beta = true },
    { file = "daun.lua",          title = "Leaf Simulator",  desc = "Configurator V2 · mobile + PC",             stop = { "LeafSimV2" }, beta = true },
    { file = "fly.lua",           title = "Universal Fly",   desc = "Fly V2 · mobile joystick + PC WASD",        stop = { "FlyGuiV2" } },
    { file = "jump.lua",          title = "Jump Settings",   desc = "Atur ukuran & posisi tombol jump (mobile)", stop = { "JumpSettingsGUI" } },
    { file = "noclip.lua",        title = "NoClip",          desc = "NoClip · shortcut K",                       stop = { "GrokNoClip" }, beta = true },
    { file = "path.lua",          title = "Path Movement",   desc = "Path visualizer + record/replay obby",      stop = { "PathMovementGUI", "PathVisuals" }, beta = true },
    { file = "lagreducer.lua",    title = "Lag Reducer",     desc = "HARDCORE FPS boost · tampilan flat · reset = rejoin", stop = {}, beta = true, noStop = true },
    { file = "rejoin.lua",        title = "Rejoin",          desc = "Auto rejoin server · hotkey R",             stop = { "RejoinGUI" } },
    { file = "speedometer.lua",   title = "Speedometer",     desc = "Kecepatan gerak avatar di atas kepala",     stop = { "SpeedometerToggle" } },
    { file = "wasd.lua",          title = "WASD Mobile",     desc = "Tombol WASD virtual untuk mobile",          stop = { "WASD_X" }, beta = true },
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
-- VIEWPORT + CLAMP HELPERS (agar GUI tidak keluar layar)
-- ════════════════════════════════════════════════════════
local camera = workspace.CurrentCamera
local function getViewport()
    local size = camera and camera.ViewportSize or nil
    if size and size.X > 0 and size.Y > 0 then return size end
    return Vector2.new(1280, 720)
end

local function clampToViewport(absX, absY, objW, objH)
    local vp = getViewport()
    local maxX = math.max(0, vp.X - objW)
    local maxY = math.max(0, vp.Y - objH)
    return math.clamp(absX, 0, maxX), math.clamp(absY, 0, maxY)
end

-- ════════════════════════════════════════════════════════
-- STOP-FLAG + CLEANUP HELPERS
-- Flag disimpan di getgenv() (fallback _G) dengan key = nama file,
-- dibaca oleh script yang punya loop (wasd, jump, ...).
-- ════════════════════════════════════════════════════════
local running = {}             -- daftar record script yang sedang berjalan
local refreshRunningTab        -- forward declaration (didefinisikan di bawah)

local function setStopFlag(fileName, value)
    pcall(function()
        local env = (type(getgenv) == "function" and getgenv()) or _G
        env.ScriptR_Stop = env.ScriptR_Stop or {}
        env.ScriptR_Stop[fileName] = value and true or nil
        _G.ScriptR_Stop = env.ScriptR_Stop
    end)
end

local function destroyEverywhere(name)
    local parents = {}
    pcall(function() table.insert(parents, game:GetService("CoreGui")) end)
    pcall(function() table.insert(parents, LocalPlayer:FindFirstChild("PlayerGui")) end)
    pcall(function() table.insert(parents, workspace) end)
    pcall(function() table.insert(parents, game:GetService("Lighting")) end)
    for _, parent in ipairs(parents) do
        if parent then
            pcall(function()
                local inst = parent:FindFirstChild(name)
                if inst then inst:Destroy() end
            end)
        end
    end
end

local function findRunning(fileName)
    for _, rec in ipairs(running) do
        if rec.entry.file == fileName then return rec end
    end
    return nil
end

local function stopScript(rec)
    setStopFlag(rec.entry.file, true)
    for _, name in ipairs(rec.entry.stop or {}) do
        destroyEverywhere(name)
    end
    for i, r in ipairs(running) do
        if r == rec then table.remove(running, i) break end
    end
    if refreshRunningTab then refreshRunningTab() end
    return true
end

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
    -- Cegah double-run: script yang sama tidak bisa dijalankan 2x
    if findRunning(entry.file) then
        statusLabel.Text = "⚠️ " .. entry.title .. " sudah berjalan — tutup dulu lewat tab Running"
        statusLabel.TextColor3 = Color3.fromRGB(255, 200, 80)
        notify("ScriptR Loader", entry.title .. " sudah berjalan")
        return
    end

    -- Reset stop-flag supaya loop lama bisa jalan lagi
    setStopFlag(entry.file, false)

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
        table.insert(running, { entry = entry, start = os.clock(), timeLabel = nil })
        if refreshRunningTab then refreshRunningTab() end
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

local PANEL_W = isMobile and 320 or 380
local PANEL_H = isMobile and 420 or 460
local vp = getViewport()
-- Ukuran panel tidak boleh lebih besar dari layar (dengan margin 16px)
local panelW = math.min(PANEL_W, vp.X - 16)
local panelH = math.min(PANEL_H, vp.Y - 16)
local startX, startY = clampToViewport((vp.X - panelW) / 2, (vp.Y - panelH) / 2, panelW, panelH)

local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.new(0, panelW, 0, panelH)
main.Position = UDim2.new(0, startX, 0, startY)
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

-- ===== Tab bar (Scripts / Running) =====
local TAB_INACTIVE = Color3.fromRGB(38, 36, 58)
local TAB_ACTIVE   = Color3.fromRGB(120, 90, 255)

local tabBar = Instance.new("Frame")
tabBar.Name = "TabBar"
tabBar.Size = UDim2.new(1, 0, 0, 38)
tabBar.Position = UDim2.new(0, 0, 0, 46)
tabBar.BackgroundColor3 = Color3.fromRGB(22, 20, 34)
tabBar.BorderSizePixel = 0
tabBar.Parent = main

local function makeTabButton(text, xScale, xOffset)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0.5, -6, 1, -8)
    b.Position = UDim2.new(xScale, xOffset, 0, 4)
    b.BackgroundColor3 = TAB_INACTIVE
    b.Text = text
    b.TextColor3 = Color3.fromRGB(220, 220, 235)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 12
    b.AutoButtonColor = false
    b.Parent = tabBar
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 8)
    c.Parent = b
    return b
end

local tabScriptsBtn = makeTabButton("📦  Scripts", 0, 4)
local tabRunningBtn = makeTabButton("📡  Running (0)", 0.5, 2)

local function styleTab(active)
    local on, off = TAB_ACTIVE, TAB_INACTIVE
    tabScriptsBtn.BackgroundColor3 = active == "scripts" and on or off
    tabRunningBtn.BackgroundColor3 = active == "running" and on or off
    tabScriptsBtn.TextColor3 = active == "scripts" and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(190, 190, 215)
    tabRunningBtn.TextColor3 = active == "running" and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(190, 190, 215)
end

-- ===== Status bar =====
local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -20, 0, 22)
status.Position = UDim2.new(0, 10, 0, 88)
status.BackgroundTransparency = 1
status.Text = "Siap. Klik salah satu script di bawah."
status.TextColor3 = Color3.fromRGB(170, 170, 200)
status.Font = Enum.Font.Gotham
status.TextSize = 11
status.TextXAlignment = Enum.TextXAlignment.Left
status.TextTruncate = Enum.TextTruncate.AtEnd
status.Parent = main

-- ===== Scroll list (tab Scripts) =====
local scroll = Instance.new("ScrollingFrame")
scroll.Name = "List"
scroll.Size = UDim2.new(1, -20, 1, -128)
scroll.Position = UDim2.new(0, 10, 0, 114)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 4
scroll.ScrollBarImageColor3 = Color3.fromRGB(120, 90, 255)
scroll.CanvasSize = UDim2.new(0, 0, 0, #SCRIPTS * 62 + 8)
scroll.Parent = main

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 8)
listLayout.Parent = scroll

-- ===== Tab Running: daftar script yang sedang berjalan =====
local runScroll = Instance.new("ScrollingFrame")
runScroll.Name = "RunningList"
runScroll.Size = UDim2.new(1, -20, 1, -128)
runScroll.Position = UDim2.new(0, 10, 0, 114)
runScroll.BackgroundTransparency = 1
runScroll.BorderSizePixel = 0
runScroll.ScrollBarThickness = 4
runScroll.ScrollBarImageColor3 = Color3.fromRGB(255, 120, 120)
runScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
runScroll.Visible = false
runScroll.Parent = main

local runLayout = Instance.new("UIListLayout")
runLayout.Padding = UDim.new(0, 8)
runLayout.Parent = runScroll

local runEmpty = Instance.new("TextLabel")
runEmpty.Name = "RunEmpty"
runEmpty.Size = UDim2.new(1, -40, 0, 120)
runEmpty.Position = UDim2.new(0, 20, 0.32, 0)
runEmpty.BackgroundTransparency = 1
runEmpty.Text = "Belum ada script yang berjalan.\n\nScript yang kamu jalankan akan muncul di sini\nbeserta tombol Tutup."
runEmpty.TextColor3 = Color3.fromRGB(140, 140, 170)
runEmpty.Font = Enum.Font.Gotham
runEmpty.TextSize = 12
runEmpty.TextWrapped = true
runEmpty.Visible = false
runEmpty.Parent = main

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
    t.Size = UDim2.new(1, entry.beta and -80 or -20, 0, 22)
    t.Position = UDim2.new(0, 12, 0, 4)
    t.BackgroundTransparency = 1
    t.Text = entry.title
    t.TextColor3 = Color3.fromRGB(255, 255, 255)
    t.Font = Enum.Font.GothamBold
    t.TextSize = 14
    t.TextXAlignment = Enum.TextXAlignment.Left
    t.Parent = btn

    if entry.beta then
        local badge = Instance.new("TextLabel")
        badge.Size = UDim2.new(0, 46, 0, 17)
        badge.Position = UDim2.new(1, -56, 0, 6)
        badge.BackgroundColor3 = Color3.fromRGB(255, 170, 60)
        badge.Text = "BETA"
        badge.TextColor3 = Color3.fromRGB(70, 40, 0)
        badge.Font = Enum.Font.GothamBold
        badge.TextSize = 10
        badge.Parent = btn
        local bc = Instance.new("UICorner")
        bc.CornerRadius = UDim.new(0, 6)
        bc.Parent = badge
    end

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

-- ════════════════════════════════════════════
-- RUNNING TAB (monitoring + tombol tutup)
-- ════════════════════════════════════════════
local currentTab = "scripts"

local function formatElapsed(sec)
    sec = math.max(0, math.floor(sec))
    return string.format("%02d:%02d", math.floor(sec / 60), sec % 60)
end

local function setTab(name)
    currentTab = name
    scroll.Visible = (name == "scripts")
    runScroll.Visible = (name == "running")
    runEmpty.Visible = (name == "running") and (#running == 0)
    styleTab(name)
end

tabScriptsBtn.MouseButton1Click:Connect(function() setTab("scripts") end)
tabRunningBtn.MouseButton1Click:Connect(function() setTab("running") end)

refreshRunningTab = function()
    for _, child in ipairs(runScroll:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    tabRunningBtn.Text = string.format("📡  Running (%d)", #running)

    for _, rec in ipairs(running) do
        local item = Instance.new("Frame")
        item.Name = "Running_" .. rec.entry.file
        item.Size = UDim2.new(1, -6, 0, 58)
        item.BackgroundColor3 = Color3.fromRGB(32, 30, 50)
        item.BorderSizePixel = 0
        item.Parent = runScroll

        local ic = Instance.new("UICorner")
        ic.CornerRadius = UDim.new(0, 10)
        ic.Parent = item

        local ist = Instance.new("UIStroke")
        ist.Color = Color3.fromRGB(120, 60, 60)
        ist.Thickness = 1
        ist.Transparency = 0.3
        ist.Parent = item

        local t = Instance.new("TextLabel")
        t.Size = UDim2.new(1, -96, 0, 22)
        t.Position = UDim2.new(0, 12, 0, 4)
        t.BackgroundTransparency = 1
        t.Text = rec.entry.title .. (rec.entry.beta and "  ⚠ BETA" or "")
        t.TextColor3 = Color3.fromRGB(255, 255, 255)
        t.Font = Enum.Font.GothamBold
        t.TextSize = 13
        t.TextXAlignment = Enum.TextXAlignment.Left
        t.TextTruncate = Enum.TextTruncate.AtEnd
        t.Parent = item

        local timeLbl = Instance.new("TextLabel")
        timeLbl.Size = UDim2.new(1, -96, 0, 16)
        timeLbl.Position = UDim2.new(0, 12, 0, 28)
        timeLbl.BackgroundTransparency = 1
        timeLbl.Text = "Berjalan · " .. formatElapsed(os.clock() - rec.start)
        timeLbl.TextColor3 = Color3.fromRGB(120, 255, 160)
        timeLbl.Font = Enum.Font.Gotham
        timeLbl.TextSize = 11
        timeLbl.TextXAlignment = Enum.TextXAlignment.Left
        timeLbl.Parent = item
        rec.timeLabel = timeLbl

        if rec.entry.noStop then
            -- Script ini tidak bisa di-"tutup" (tidak bisa di-undo) —
            -- tampilkan info permanen, bukan tombol Tutup.
            local perm = Instance.new("TextLabel")
            perm.Name = "PermNote"
            perm.Size = UDim2.new(0, 92, 0, 34)
            perm.Position = UDim2.new(1, -100, 0.5, -17)
            perm.BackgroundColor3 = Color3.fromRGB(60, 55, 30)
            perm.Text = "Permanen\ns/d rejoin"
            perm.TextColor3 = Color3.fromRGB(255, 215, 120)
            perm.Font = Enum.Font.GothamBold
            perm.TextSize = 9
            perm.TextWrapped = true
            perm.Parent = item
            local pc = Instance.new("UICorner")
            pc.CornerRadius = UDim.new(0, 8)
            pc.Parent = perm
        else
            local stopBtn = Instance.new("TextButton")
            stopBtn.Name = "StopBtn"
            stopBtn.Size = UDim2.new(0, 68, 0, 30)
            stopBtn.Position = UDim2.new(1, -78, 0.5, -15)
            stopBtn.BackgroundColor3 = Color3.fromRGB(200, 70, 70)
            stopBtn.Text = "Tutup"
            stopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            stopBtn.Font = Enum.Font.GothamBold
            stopBtn.TextSize = 12
            stopBtn.AutoButtonColor = true
            stopBtn.Parent = item
            local sc = Instance.new("UICorner")
            sc.CornerRadius = UDim.new(0, 8)
            sc.Parent = stopBtn

            stopBtn.MouseButton1Click:Connect(function()
                stopScript(rec)
                status.Text = "⏹ " .. rec.entry.title .. " ditutup"
                status.TextColor3 = Color3.fromRGB(255, 200, 80)
                notify("ScriptR Loader", rec.entry.title .. " ditutup")
            end)
        end
    end

    runScroll.CanvasSize = UDim2.new(0, 0, 0, #running * 66 + 8)
    runEmpty.Visible = (currentTab == "running") and (#running == 0)
end

-- Timer: update label "Berjalan · mm:ss" tiap detik
task.spawn(function()
    while sg.Parent do
        for _, rec in ipairs(running) do
            if rec.timeLabel and rec.timeLabel.Parent then
                rec.timeLabel.Text = "Berjalan · " .. formatElapsed(os.clock() - rec.start)
            end
        end
        task.wait(1)
    end
end)

styleTab("scripts")

-- ===== Floating minimize icon (muncul saat minimize) =====
local MIN_ICON_SIZE = 54

local minIcon = Instance.new("TextButton")
minIcon.Name = "MinIcon"
minIcon.Size = UDim2.new(0, MIN_ICON_SIZE, 0, MIN_ICON_SIZE)
minIcon.Position = UDim2.new(0, 20, 0.4, 0)
minIcon.BackgroundColor3 = Color3.fromRGB(120, 90, 255)
minIcon.Text = "S"
minIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
minIcon.Font = Enum.Font.GothamBlack
minIcon.TextSize = 26
minIcon.AutoButtonColor = false
minIcon.Visible = false
minIcon.ZIndex = 400
minIcon.Parent = sg

local minIconCorner = Instance.new("UICorner")
minIconCorner.CornerRadius = UDim.new(0, MIN_ICON_SIZE / 2)
minIconCorner.Parent = minIcon

local minIconStroke = Instance.new("UIStroke")
minIconStroke.Color = Color3.fromRGB(205, 195, 255)
minIconStroke.Thickness = 2
minIconStroke.Transparency = 0.15
minIconStroke.Parent = minIcon

-- Tap vs drag detection (tap = restore, drag = pindah posisi)
local iDrag, iDragStart, iStartPos, iMoved = false, nil, nil, 0
minIcon.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        iDrag = true
        iMoved = 0
        iDragStart = input.Position
        iStartPos = minIcon.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                iDrag = false
            end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if iDrag and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - iDragStart
        iMoved = math.max(iMoved, delta.Magnitude)
        -- Clamp: icon tidak boleh keluar layar
        local nx, ny = clampToViewport(iStartPos.X.Offset + delta.X, iStartPos.Y.Offset + delta.Y, MIN_ICON_SIZE, MIN_ICON_SIZE)
        minIcon.Position = UDim2.new(0, nx, 0, ny)
    end
end)

minIcon.MouseButton1Click:Connect(function()
    if iMoved > 8 then return end -- tadi digeser, jangan restore
    minIcon.Visible = false
    main.Visible = true
end)

minimizeBtn.MouseButton1Click:Connect(function()
    -- Sembunyikan panel, tampilkan icon di dekat posisi panel (clamp ke layar)
    local mp = main.Position
    local nx, ny = clampToViewport(mp.X.Offset, mp.Y.Offset, MIN_ICON_SIZE, MIN_ICON_SIZE)
    minIcon.Position = UDim2.new(0, nx, 0, ny)
    main.Visible = false
    minIcon.Visible = true
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
        -- Clamp: panel tidak boleh keluar layar
        local nx, ny = clampToViewport(startPos.X.Offset + delta.X, startPos.Y.Offset + delta.Y, main.AbsoluteSize.X, main.AbsoluteSize.Y)
        main.Position = UDim2.new(0, nx, 0, ny)
    end
end)

notify("ScriptR Loader", "Loader siap · pilih script dari menu")
print("✅ ScriptR Loader loaded · " .. #SCRIPTS .. " scripts tersedia")
