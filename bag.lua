local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- 1. Paksa backpack default + set max slot ke 10
local function forceBackpack()
    pcall(function()
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true)
    end)
    pcall(function()
        StarterGui:SetCore("BackpackMaxSlots", 10)
    end)
end

-- 2. Hapus custom UI developer yang mungkin menutupi
local function killCustomUI()
    local pg = player:FindFirstChild("PlayerGui")
    if not pg then return end
    for _, gui in ipairs(pg:GetChildren()) do
        local n = gui.Name:lower()
        if n:find("hotbar") or n:find("inventory") or n:find("backpack")
        or n:find("toolbar") or n:find("slot") or n:find("bag") then
            pcall(function() gui:Destroy() end)
        end
    end
end

-- Jalankan langsung
forceBackpack()
killCustomUI()

-- Loop cepat lawan script developer
task.spawn(function()
    while task.wait(0.1) do
        forceBackpack()
    end
end)

task.spawn(function()
    while task.wait(1) do
        killCustomUI()
    end
end)

print("✅ Force 10 Slot aktif!")
