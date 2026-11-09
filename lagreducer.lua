-- ════════════════════════════════════════════════════════
-- LAG REDUCER  · HARDCORE EXTREME
-- Untuk HP Android low-end & PC low-end.
-- Menargetkan FPS drop & biaya rendering semaksimal mungkin.
--
-- ⚠️  SCRIPT INI SEKALI JALAN & TIDAK BISA DI-UNDO.
--     Untuk mengembalikan tampilan normal: REJOIN server.
--
-- Efek samping visual (disengaja):
--   - Tidak ada bayangan / VFX / post-processing
--   - Tekstur & decal hilang (objek jadi flat color)
--   - Mesh low detail / Material jadi Plastic
--   - Banjir cahaya dihapus, ambient dinaikkan biar tidak gelap
-- ════════════════════════════════════════════════════════

local Lighting   = game:GetService("Lighting")
local Workspace  = game:GetService("Workspace")
local Terrain    = Workspace:FindFirstChildOfClass("Terrain") or Workspace.Terrain

local OK = 0
local function try(fn)
    local ok = pcall(fn)
    if ok then OK += 1 end
    return ok
end

print("⚙️ Lag Reducer HARDCORE: memulai optimasi...")

-- ════════════════════════════════════════════════════════
-- 1. QUALITY SETTINGS PALING RENDAH
-- ════════════════════════════════════════════════════════
try(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
try(function() settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Performance end)
try(function() settings().Rendering.EnableMeshPartCache = true end)

-- ════════════════════════════════════════════════════════
-- 2. LIGHTING: TANPA SHADOW, TANPA EFEK, AMBIENT CERAH
-- ════════════════════════════════════════════════════════
try(function() Lighting.GlobalShadows = false end)
try(function() Lighting.ShadowSoftness = 1 end)
try(function() Lighting.Brightness = 1 end)
try(function() Lighting.ExposureCompensation = 0 end)
try(function() Lighting.Ambient = Color3.fromRGB(205, 205, 205) end)
try(function() Lighting.OutdoorAmbient = Color3.fromRGB(205, 205, 205) end)
try(function() Lighting.EnvironmentDiffuseScale = 0 end)
try(function() Lighting.EnvironmentSpecularScale = 0 end)
try(function() Lighting.GlobalWindSpeed = 0 end)
try(function() Lighting.FogStart = 1000000 end)
try(function() Lighting.FogEnd = 1000001 end)
try(function() Lighting.Technology = Enum.Technology.Voxel end) -- lebih ringan dari Future/ShadowMap

-- Hapus post-processing & atmosphere
for _, child in ipairs(Lighting:GetChildren()) do
    pcall(function()
        if child:IsA("BloomEffect") or child:IsA("DepthOfFieldEffect")
            or child:IsA("SunRaysEffect") or child:IsA("BlurEffect")
            or child:IsA("ColorCorrectionEffect") or child:IsA("ColorConvolutionEffect")
            or child:IsA("ColorGradingEffect") or child:IsA("ColorEffect") then
            child:Destroy()
        elseif child:IsA("Atmosphere") then
            child.Density = 0
            child.Offset = 0
            child.Glare = 0
            child.Haze = 0
        end
    end)
end

-- ════════════════════════════════════════════════════════
-- 3. TERRAIN: MATIKAN DEKORASI & GELOMBANG AIR
-- ════════════════════════════════════════════════════════
if Terrain then
    try(function() Terrain.Decoration = false end)
    try(function() Terrain.WaterWaveSize = 0 end)
    try(function() Terrain.WaterWaveSpeed = 0 end)
    try(function() Terrain.WaterReflectance = 0 end)
    try(function() Terrain.WaterTransparency = 0 end)
end

-- ════════════════════════════════════════════════════════
-- 4. BERSIHKAN SEMUA INSTANCE BERAT (sekarang & yang muncul nanti)
-- ════════════════════════════════════════════════════════
local function sanitize(obj)
    pcall(function()
        -- Mesh paling kasar
        if obj:IsA("MeshPart") then
            obj.RenderFidelity = Enum.RenderFidelity.Performance
        end
        -- Material termurah + tanpa shadow casting
        if obj:IsA("BasePart") then
            obj.Material = Enum.Material.Plastic
            obj.CastShadow = false
        end
        -- Tekstur semua hilang (flat color)
        if obj:IsA("Decal") or obj:IsA("Texture") then
            obj.Transparency = 1
        end
        -- SurfaceAppearance (detail maps) dihapus total
        if obj:IsA("SurfaceAppearance") then
            obj:Destroy()
            return
        end
        -- VFX dimatikan
        if obj:IsA("ParticleEmitter") or obj:IsA("Fire") or obj:IsA("Smoke")
            or obj:IsA("Sparkles") or obj:IsA("Beam") or obj:IsA("Trail") then
            obj.Enabled = false
        end
        -- Cahaya dinamis dimatikan (ambient sudah ditinggikan)
        if obj:IsA("PointLight") or obj:IsA("SpotLight") or obj:IsA("SurfaceLight") then
            obj.Enabled = false
        end
    end)
end

local descendants = Workspace:GetDescendants()
for i = 1, #descendants do
    sanitize(descendants[i])
    -- Yield ringan setiap 200 instance biar tidak freeze lama
    if i % 200 == 0 then task.wait() end
end

-- Tetap sanitasi part/efek baru yang muncul setelah ini (mis. loading berikutnya)
Workspace.DescendantAdded:Connect(sanitize)

-- Lighting juga bisa berubah (beberapa game pasang efek saat jalan)
Lighting.ChildAdded:Connect(function(child)
    pcall(function()
        if child:IsA("BloomEffect") or child:IsA("DepthOfFieldEffect")
            or child:IsA("SunRaysEffect") or child:IsA("BlurEffect")
            or child:IsA("ColorCorrectionEffect") then
            child:Destroy()
        end
    end)
end)

-- ════════════════════════════════════════════════════════
-- 5. BERSIHKAN MEMORI
-- ════════════════════════════════════════════════════════
try(function() collectgarbage("collect") end)
try(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)

print(string.format("✅ Lag Reducer HARDCORE selesai! %d optimasi diterapkan.", OK))
print("⚠️  Tampilan akan terlihat 'flat' (tanpa tekstur/bayangan/VFX).")
print("🔄 Untuk kembali normal: REJOIN server.")
