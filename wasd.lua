local p = game.Players.LocalPlayer
local pg = p:WaitForChild("PlayerGui")
local rs = game:GetService("RunService")

-- Tunggu game fully loaded
if not game:IsLoaded() then
    game.Loaded:Wait()
end
task.wait(2)

local mv = {W=false, A=false, S=false, D=false}

-- Stop-flag kooperatif: diset loader.lua saat tombol "Tutup" ditekan
local function isStopped()
    local ok, env = pcall(function()
        if type(getgenv) == "function" then return getgenv() end
        return _G
    end)
    if not ok or type(env) ~= "table" then return false end
    local t = env.ScriptR_Stop
    return type(t) == "table" and t["wasd.lua"] == true
end

-- Fungsi buat GUI
local function createGUI()
    -- Hapus yang lama kalau ada
    local old = pg:FindFirstChild("WASD_X")
    if old then old:Destroy() end

    -- Coba parent ke CoreGui dulu (lebih susah dihapus game)
    local parent = pg
    pcall(function()
        local cg = game:GetService("CoreGui")
        if cg then parent = cg end
    end)

    local sg = Instance.new("ScreenGui")
    sg.Name = "WASD_X"
    sg.ResetPlayerGuiOnSpawn = false
    sg.DisplayOrder = 999
    sg.IgnoreGuiInset = true
    sg.Parent = parent

    local function btn(t, x, y)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0, 60, 0, 60)
        b.Position = UDim2.new(0, x, 1, y)
        b.AnchorPoint = Vector2.new(0, 0)
        b.Text = t
        b.TextSize = 26
        b.Font = Enum.Font.GothamBold
        b.TextColor3 = Color3.new(1, 1, 1)
        b.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        b.BackgroundTransparency = 0.3
        b.Active = true
        b.AutoButtonColor = true
        b.ZIndex = 100
        b.Parent = sg
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 12)
        local st = Instance.new("UIStroke")
        st.Color = Color3.new(1, 1, 1)
        st.Thickness = 2
        st.Transparency = 0.5
        st.Parent = b
        return b
    end

    local W = btn("W", 75, -200)
    local A = btn("A", 10, -135)
    local S = btn("S", 75, -135)
    local D = btn("D", 140, -135)

    W.MouseButton1Down:Connect(function() mv.W = true end)
    W.MouseButton1Up:Connect(function() mv.W = false end)
    A.MouseButton1Down:Connect(function() mv.A = true end)
    A.MouseButton1Up:Connect(function() mv.A = false end)
    S.MouseButton1Down:Connect(function() mv.S = true end)
    S.MouseButton1Up:Connect(function() mv.S = false end)
    D.MouseButton1Down:Connect(function() mv.D = true end)
    D.MouseButton1Up:Connect(function() mv.D = false end)

    return sg
end

-- Buat GUI pertama kali
local gui = createGUI()
print("GUI dibuat!")

-- Loop: kalau GUI dihapus game, buat lagi (berhenti kalau loader stop-flag aktif)
task.spawn(function()
    while task.wait(1) do
        if isStopped() then break end
        if not gui or not gui.Parent then
            gui = createGUI()
            print("GUI dibuat ulang!")
        end
    end
end)

-- Loop gerak
rs.RenderStepped:Connect(function()
    if isStopped() then return end
    local c = p.Character
    if not c then return end
    local h = c:FindFirstChildOfClass("Humanoid")
    if not h then return end
    local d = Vector3.new(0, 0, 0)
    if mv.W then d = d + Vector3.new(0, 0, -1) end
    if mv.S then d = d + Vector3.new(0, 0, 1) end
    if mv.A then d = d + Vector3.new(-1, 0, 0) end
    if mv.D then d = d + Vector3.new(1, 0, 0) end
    if d.Magnitude > 0 then
        h:Move(d.Unit, true)
    end
end)

print("✅ WASD aktif! Cek kiri bawah layar.")
