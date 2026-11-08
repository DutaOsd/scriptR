-- Force Enable Backpack (Anti-Disable Loop)
local StarterGui = game:GetService("StarterGui")

-- Matikan dulu custom UI developer (kalau ada)
local playerGui = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
if playerGui then
    for _, gui in ipairs(playerGui:GetChildren()) do
        -- Hapus custom hotbar/inventory developer
        local name = gui.Name:lower()
        if name:find("hotbar") or name:find("inventory") or name:find("backpack") then
            gui.Enabled = false
        end
    end
end

-- Paksa aktifkan backpack default dengan loop
task.spawn(function()
    while task.wait(0.5) do
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true)
    end
end)

print("✅ Backpack default 10 slot dipaksa aktif!")
