local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- ============================================
-- APPROACH 1: Paksa Backpack Default 10 Slot
-- ============================================
local function forceDefault()
    pcall(function()
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true)
    end)
    pcall(function()
        StarterGui:SetCore("BackpackMaxSlots", 10)
    end)
end

-- ============================================
-- APPROACH 2: Hapus Custom Inventory Developer
-- ============================================
local function destroyCustomInventory()
    local pg = player:FindFirstChild("PlayerGui")
    if not pg then return end
    for _, gui in ipairs(pg:GetChildren()) do
        local n = gui.Name:lower()
        if n:find("invent") or n:find("hotbar") or n:find("backpack")
        or n:find("toolbar") or n:find("slot") or n:find("bag")
        or n:find("item") or n:find("equipment") or n:find("hud") then
            pcall(function()
                gui.Enabled = false
                task.wait(0.05)
                gui:Destroy()
            end)
        end
    end
end

-- ============================================
-- APPROACH 3: Spoof Platform ke Desktop
-- (Biar game kira kita di PC, bukan mobile)
-- ============================================
local function spoofDesktop()
    pcall(function()
        -- Beberapa game cek TouchEnabled
        -- Kita coba override metatable-nya
        local mt = getrawmetatable(UserInputService)
        if mt then
            local oldIndex = mt.__index
            setreadonly(mt, false)
            mt.__index = function(self, key)
                if key == "TouchEnabled" then
                    return false -- Paksa bilang bukan mobile
                end
                if key == "KeyboardEnabled" then
                    return true -- Paksa bilang ada keyboard
                end
                return oldIndex(self, key)
            end
            setreadonly(mt, true)
        end
    end)
end

-- ============================================
-- APPROACH 4: Cari & Modifikasi GUI Secara Langsung
-- ============================================
local function modifyExistingGUI()
    local pg = player:FindFirstChild("PlayerGui")
    if not pg then return end

    -- Cari semua frame yang mirip hotbar
    for _, gui in ipairs(pg:GetDescendants()) do
        if gui:IsA("Frame") or gui:IsA("ScrollingFrame") then
            local n = gui.Name:lower()
            if n:find("slot") or n:find("hotbar") or n:find("bar") then
                pcall(function()
                    gui.Visible = true
                    gui.Active = true
                end)
            end
        end
    end
end

-- ============================================
-- JALANKAN SEMUA APPROACH
-- ============================================
spoofDesktop()
task.wait(0.5)
destroyCustomInventory()
task.wait(0.3)
forceDefault()
task.wait(0.3)
modifyExistingGUI()

-- Loop biar tetap aktif
task.spawn(function()
    while task.wait(0.2) do
        forceDefault()
    end
end)

task.spawn(function()
    while task.wait(2) do
        destroyCustomInventory()
        modifyExistingGUI()
    end
end)

print("✅ Multi-Approach 10 Slot aktif!")
print("⚠️ Kalau masih 3 slot, berarti server-side limit.")
