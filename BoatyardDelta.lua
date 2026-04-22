-- ================== SHOP ITEM FINDER PRO - CLEAN VERSION ==================
-- 3 Tab System | Anti-AFK | Unified List | Persistent | Auto-Buy

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

print("🛒 Shop Finder Pro Clean - Starting...")

-- ================== ANTI-AFK SYSTEM ==================
local antiAfkActive = true

local function startAntiAfk()
    player.Idled:Connect(function()
        if antiAfkActive then
            pcall(function()
                VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
                task.wait(0.1)
                VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
            end)
            print("🔄 Anti-AFK: Idle prevented")
        end
    end)

    task.spawn(function()
        while true do
            task.wait(55)
            if antiAfkActive then
                pcall(function()
                    VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
                    task.wait(0.1)
                    VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
                    VirtualUser:MoveMouse(Vector2.new(1, 0))
                    task.wait(0.05)
                    VirtualUser:MoveMouse(Vector2.new(-1, 0))
                end)
            end
        end
    end)

    print("✅ Anti-AFK Active")
end

startAntiAfk()

-- ================== SETTINGS ==================
local Settings = {
    AutoRefresh = true,
    RefreshInterval = 5,
    SearchRadius = 10000,
    AutoTP = false,
    AutoBuy = false,
    TeleportDelay = 0.5,
    BuyDelay = 0.3,
}

local watchedNames = {}
local currentTab = "shop"
local isAutoBuying = false
local isMinimized = false

-- ================== PERSISTENT ITEM REGISTRY ==================
local itemRegistry = {}

local function registerItem(obj)
    local name = obj.Name
    local nameClean = name:gsub("%s+", "")

    local category = (#nameClean <= 2) and "utilities" or "shop"

    -- Extract price
    local price = nil
    for _, descendant in pairs(obj:GetDescendants()) do
        if descendant:IsA("BillboardGui") or descendant:IsA("SurfaceGui") then
            for _, child in pairs(descendant:GetDescendants()) do
                if child:IsA("TextLabel") or child:IsA("TextBox") then
                    local text = child.Text
                    local patterns = {
                        {pattern = "%$([%d,]+)", currency = "$"},
                        {pattern = "([%d,]+)%s*[Cc]oins?", currency = " Coins"},
                        {pattern = "([%d,]+)%s*[Cc]ash", currency = " Cash"},
                        {pattern = "([%d,]+)%s*[Gg]ems?", currency = " Gems"},
                        {pattern = "([%d,]+)%s*[Gg]old", currency = " Gold"},
                        {pattern = "([%d,]+)%s*[Tt]okens?", currency = " Tokens"},
                        {pattern = "([%d,]+)%s*[Dd]ollars?", currency = "$"},
                        {pattern = "[Pp]rice:?%s*([%d,]+)", currency = ""},
                        {pattern = "[Cc]ost:?%s*([%d,]+)", currency = ""},
                        {pattern = "([%d,]+)%s*[Bb]ucks?", currency = " Bucks"},
                    }
                    for _, p in ipairs(patterns) do
                        local match = text:match(p.pattern)
                        if match then
                            price = match:gsub(",", "") .. p.currency
                            break
                        end
                    end
                    if price then break end
                end
            end
            if price then break end
        end
    end

    local hasProx = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
    local hasClick = obj:FindFirstChildWhichIsA("ClickDetector", true)
    local intType = hasProx and "ProximityPrompt" or (hasClick and "ClickDetector" or "None")

    if itemRegistry[name] then
        local entry = itemRegistry[name]
        entry.lastSeen = tick()
        if price then entry.price = price end
        entry.interactionType = intType

        -- Clean dead, add new
        for i = #entry.instances, 1, -1 do
            if not entry.instances[i] or not entry.instances[i].Parent then
                table.remove(entry.instances, i)
            end
        end
        local found = false
        for _, inst in ipairs(entry.instances) do
            if inst == obj then found = true break end
        end
        if not found then table.insert(entry.instances, obj) end
        entry.count = #entry.instances
    else
        itemRegistry[name] = {
            name = name,
            category = category,
            price = price or "No Price",
            interactionType = intType,
            lastSeen = tick(),
            count = 1,
            instances = {obj},
        }
    end
end

local function getAliveInstance(name)
    local entry = itemRegistry[name]
    if not entry then return nil end

    local best, bestDist = nil, math.huge

    for i = #entry.instances, 1, -1 do
        local inst = entry.instances[i]
        if inst and inst.Parent then
            local dist = math.huge
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local hrp = player.Character.HumanoidRootPart
                local pos
                if inst:IsA("Model") then
                    local part = inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart", true)
                    if part then pos = part.Position end
                elseif inst:IsA("BasePart") then
                    pos = inst.Position
                end
                if pos then dist = (hrp.Position - pos).Magnitude end
            end
            if dist < bestDist then bestDist = dist best = inst end
        else
            table.remove(entry.instances, i)
        end
    end

    entry.count = #entry.instances
    return best, bestDist
end

-- ================== NOTIFICATION ==================
local function notify(text)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "🛒 Shop Finder";
            Text = text;
            Duration = 3;
        })
    end)
end

-- ================== HELPER FUNCTIONS ==================
local function getDistance(obj)
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return math.huge end
    local hrp = player.Character.HumanoidRootPart
    local pos
    if obj:IsA("Model") then
        local part = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)
        if part then pos = part.Position else return math.huge end
    elseif obj:IsA("BasePart") then pos = obj.Position
    else return math.huge end
    return (hrp.Position - pos).Magnitude
end

local function formatDistance(dist)
    if dist == math.huge then return "???" end
    if dist < 1000 then return string.format("%.0fm", dist)
    else return string.format("%.1fk", dist / 1000) end
end

local function hasClickable(obj)
    return obj:FindFirstChildWhichIsA("ClickDetector", true) or
           obj:FindFirstChildWhichIsA("ProximityPrompt", true)
end

local function isWatched(name) return watchedNames[name] == true end
local function setWatched(name, state) watchedNames[name] = state or nil end

-- ================== TELEPORT & BUY ==================
local function teleportTo(obj)
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return false end
    local pos
    if obj:IsA("Model") then
        local part = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)
        if part then pos = part.Position end
    elseif obj:IsA("BasePart") then pos = obj.Position end
    if not pos then return false end
    player.Character.HumanoidRootPart.CFrame = CFrame.new(pos + Vector3.new(0, 5, 0))
    task.wait(Settings.TeleportDelay)
    return true
end

local function buyItem(obj)
    if not obj or not obj.Parent then return false end
    local prox = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
    if prox then pcall(function() fireproximityprompt(prox) end) task.wait(Settings.BuyDelay) return true end
    local click = obj:FindFirstChildWhichIsA("ClickDetector", true)
    if click then pcall(function() fireclickdetector(click) end) task.wait(Settings.BuyDelay) return true end
    return false
end

local function teleportAndBuy(obj)
    if not obj or not obj.Parent then notify("❌ Item gone!") return false end
    notify("📍 TP: " .. obj.Name)
    if teleportTo(obj) then
        task.wait(0.3)
        notify("🛒 Buy: " .. obj.Name)
        return buyItem(obj)
    end
    return false
end

-- ================== SCREEN GUI ==================
repeat task.wait() until player:FindFirstChild("PlayerGui")

local oldGui = player.PlayerGui:FindFirstChild("ShopFinderGUI_Clean")
if oldGui then oldGui:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ShopFinderGUI_Clean"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 999999999
ScreenGui.Parent = player.PlayerGui

-- ================== MINI ICON (saat minimize) ==================
local MiniIcon = Instance.new("TextButton")
MiniIcon.Name = "MiniIcon"
MiniIcon.Size = UDim2.new(0, 46, 0, 46)
MiniIcon.Position = isMobile and UDim2.new(0, 8, 0.4, 0) or UDim2.new(0, 8, 0.5, -23)
MiniIcon.BackgroundColor3 = Color3.fromRGB(50, 50, 180)
MiniIcon.Text = "🛒"
MiniIcon.TextSize = 24
MiniIcon.Font = Enum.Font.GothamBold
MiniIcon.TextColor3 = Color3.new(1, 1, 1)
MiniIcon.Visible = false
MiniIcon.Active = true
MiniIcon.Draggable = true
MiniIcon.Parent = ScreenGui
Instance.new("UICorner", MiniIcon).CornerRadius = UDim.new(0, 12)

local miniStroke = Instance.new("UIStroke", MiniIcon)
miniStroke.Color = Color3.fromRGB(100, 100, 255)
miniStroke.Thickness = 2

-- Pulse animation untuk mini icon
local function startPulse()
    task.spawn(function()
        while MiniIcon.Visible do
            TweenService:Create(miniStroke, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                Color = Color3.fromRGB(150, 150, 255)
            }):Play()
            task.wait(0.8)
            if not MiniIcon.Visible then break end
            TweenService:Create(miniStroke, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                Color = Color3.fromRGB(80, 80, 200)
            }):Play()
            task.wait(0.8)
        end
    end)
end

-- ================== MAIN FRAME ==================
local Main = Instance.new("Frame")
Main.Name = "MainFrame"
Main.Size = isMobile and UDim2.new(0.92, 0, 0.72, 0) or UDim2.new(0, 420, 0, 580)
Main.Position = isMobile and UDim2.new(0.04, 0, 0.14, 0) or UDim2.new(0.02, 0, 0.1, 0)
Main.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = not isMobile
Main.Visible = true
Main.ClipsDescendants = true
Main.Parent = ScreenGui

Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 14)
local mainStroke = Instance.new("UIStroke", Main)
mainStroke.Color = Color3.fromRGB(80, 80, 255)
mainStroke.Thickness = 2

-- ================== MINIMIZE / RESTORE ==================
local function minimizeGUI()
    isMinimized = true
    TweenService:Create(Main, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
        Size = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(
            MiniIcon.Position.X.Scale,
            MiniIcon.Position.X.Offset + 23,
            MiniIcon.Position.Y.Scale,
            MiniIcon.Position.Y.Offset + 23
        )
    }):Play()

    task.delay(0.3, function()
        Main.Visible = false
        MiniIcon.Visible = true
        startPulse()
    end)
end

local function restoreGUI()
    isMinimized = false
    MiniIcon.Visible = false
    Main.Visible = true

    local targetSize = isMobile and UDim2.new(0.92, 0, 0.72, 0) or UDim2.new(0, 420, 0, 580)
    local targetPos = isMobile and UDim2.new(0.04, 0, 0.14, 0) or UDim2.new(0.02, 0, 0.1, 0)

    TweenService:Create(Main, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = targetSize,
        Position = targetPos
    }):Play()
end

MiniIcon.MouseButton1Click:Connect(restoreGUI)

-- ================== TITLE BAR ==================
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 44)
TitleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = Main
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 14)

local TBCover = Instance.new("Frame")
TBCover.Size = UDim2.new(1, 0, 0, 14)
TBCover.Position = UDim2.new(0, 0, 1, -14)
TBCover.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
TBCover.BorderSizePixel = 0
TBCover.Parent = TitleBar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(0.6, 0, 1, 0)
Title.Position = UDim2.new(0.04, 0, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "🛒 Shop Finder Pro"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.TextSize = isMobile and 14 or 15
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TitleBar

-- AFK Badge di title bar
local afkBadge = Instance.new("TextLabel")
afkBadge.Size = UDim2.new(0, 58, 0, 16)
afkBadge.Position = UDim2.new(1, -140, 0, 14)
afkBadge.BackgroundColor3 = Color3.fromRGB(40, 140, 200)
afkBadge.Text = "⏰ AFK-ON"
afkBadge.TextColor3 = Color3.new(1, 1, 1)
afkBadge.TextSize = 8
afkBadge.Font = Enum.Font.GothamBold
afkBadge.Parent = TitleBar
Instance.new("UICorner", afkBadge).CornerRadius = UDim.new(0, 4)

-- Minimize Button
local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 30, 0, 30)
MinBtn.Position = UDim2.new(1, -68, 0, 7)
MinBtn.BackgroundColor3 = Color3.fromRGB(255, 180, 0)
MinBtn.Text = "—"
MinBtn.TextColor3 = Color3.new(1, 1, 1)
MinBtn.TextSize = 16
MinBtn.Font = Enum.Font.GothamBold
MinBtn.Parent = TitleBar
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0.5, 0)

MinBtn.MouseButton1Click:Connect(minimizeGUI)

-- Close Button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -34, 0, 7)
CloseBtn.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.new(1, 1, 1)
CloseBtn.TextSize = 14
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Parent = TitleBar
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0.5, 0)

CloseBtn.MouseButton1Click:Connect(function()
    Settings.AutoTP = false
    Settings.AutoBuy = false
    antiAfkActive = false
    ScreenGui:Destroy()
end)

-- ================== TAB BAR (3 Tabs) ==================
local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(1, -12, 0, 32)
TabBar.Position = UDim2.new(0, 6, 0, 48)
TabBar.BackgroundTransparency = 1
TabBar.Parent = Main

local tabDefs = {
    {id = "utilities", icon = "🔧", label = "Utils"},
    {id = "shop",      icon = "🛒", label = "Shop"},
    {id = "watched",   icon = "👁️", label = "Watched"},
}

local tabButtons = {}

for i, def in ipairs(tabDefs) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1/3, -4, 1, 0)
    btn.Position = UDim2.new((i-1)/3, 2, 0, 0)
    btn.BackgroundColor3 = (currentTab == def.id)
        and Color3.fromRGB(80, 80, 255) or Color3.fromRGB(40, 40, 55)
    btn.Text = def.icon .. " " .. def.label
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.TextSize = isMobile and 11 or 12
    btn.Font = Enum.Font.GothamBold
    btn.Parent = TabBar
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    tabButtons[def.id] = btn
end

-- ================== INFO BAR ==================
local InfoBar = Instance.new("Frame")
InfoBar.Size = UDim2.new(1, -12, 0, 28)
InfoBar.Position = UDim2.new(0, 6, 0, 84)
InfoBar.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
InfoBar.BorderSizePixel = 0
InfoBar.Parent = Main
Instance.new("UICorner", InfoBar).CornerRadius = UDim.new(0, 7)

local ItemCountLabel = Instance.new("TextLabel")
ItemCountLabel.Size = UDim2.new(0.45, 0, 1, 0)
ItemCountLabel.Position = UDim2.new(0, 8, 0, 0)
ItemCountLabel.BackgroundTransparency = 1
ItemCountLabel.Text = "📦 Items: 0"
ItemCountLabel.TextColor3 = Color3.new(1, 1, 1)
ItemCountLabel.TextSize = 11
ItemCountLabel.Font = Enum.Font.GothamBold
ItemCountLabel.TextXAlignment = Enum.TextXAlignment.Left
ItemCountLabel.Parent = InfoBar

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(0.55, 0, 1, 0)
StatusLabel.Position = UDim2.new(0.45, 0, 0, 0)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "✅ Ready"
StatusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
StatusLabel.TextSize = 10
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextXAlignment = Enum.TextXAlignment.Right
StatusLabel.Parent = InfoBar

-- ================== CONTROL BAR (5 Buttons) ==================
local ControlBar = Instance.new("Frame")
ControlBar.Size = UDim2.new(1, -12, 0, 30)
ControlBar.Position = UDim2.new(0, 6, 0, 116)
ControlBar.BackgroundTransparency = 1
ControlBar.Parent = Main

local ctrlBtnDefs = {
    {id = "scan",    label = "🔄 Scan",    color = Color3.fromRGB(60, 150, 60)},
    {id = "autotp",  label = "📍 AutoTP",  color = Color3.fromRGB(60, 60, 80)},
    {id = "autobuy", label = "🛒 AutoBuy", color = Color3.fromRGB(60, 60, 80)},
    {id = "autoref", label = "🔁 AutoRef", color = Color3.fromRGB(60, 150, 60)},
    {id = "antiafk", label = "✅ AFK",     color = Color3.fromRGB(40, 140, 200)},
}

local ctrlButtons = {}

for i, def in ipairs(ctrlBtnDefs) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1/#ctrlBtnDefs, -3, 1, 0)
    btn.Position = UDim2.new((i-1)/#ctrlBtnDefs, 1.5, 0, 0)
    btn.BackgroundColor3 = def.color
    btn.Text = def.label
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.TextSize = isMobile and 8 or 9
    btn.Font = Enum.Font.GothamBold
    btn.Parent = ControlBar
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 7)
    ctrlButtons[def.id] = btn
end

-- ================== SCROLL FRAME ==================
local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Size = UDim2.new(1, -12, 1, -156)
ScrollFrame.Position = UDim2.new(0, 6, 0, 150)
ScrollFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 38)
ScrollFrame.BorderSizePixel = 0
ScrollFrame.ScrollBarThickness = 5
ScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 255)
ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ScrollFrame.Parent = Main
Instance.new("UICorner", ScrollFrame).CornerRadius = UDim.new(0, 8)

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Padding = UDim.new(0, 4)
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Parent = ScrollFrame

local UIPadding = Instance.new("UIPadding")
UIPadding.PaddingTop = UDim.new(0, 4)
UIPadding.PaddingLeft = UDim.new(0, 4)
UIPadding.PaddingRight = UDim.new(0, 4)
UIPadding.Parent = ScrollFrame

UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y + 12)
end)

-- ================== CREATE UNIFIED CARD ==================
local function createUnifiedCard(entry, index)
    local name = entry.name
    local watched = isWatched(name)
    local aliveObj, closestDist = getAliveInstance(name)
    local isAvailable = aliveObj ~= nil

    local card = Instance.new("Frame")
    card.Name = "Card_" .. name
    card.Size = isMobile and UDim2.new(1, -4, 0, 76) or UDim2.new(1, -4, 0, 72)
    card.BackgroundColor3 = watched and Color3.fromRGB(30, 48, 35)
        or (isAvailable and Color3.fromRGB(38, 38, 52) or Color3.fromRGB(48, 33, 33))
    card.BorderSizePixel = 0
    card.LayoutOrder = index
    card.Parent = ScrollFrame

    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)

    local stroke = Instance.new("UIStroke", card)
    stroke.Color = watched and Color3.fromRGB(80, 200, 80)
        or (isAvailable and Color3.fromRGB(55, 55, 75) or Color3.fromRGB(110, 45, 45))
    stroke.Thickness = 1
    stroke.Transparency = 0.3

    -- Checkbox
    local checkboxBtn = Instance.new("TextButton")
    checkboxBtn.Size = UDim2.new(0, 22, 0, 22)
    checkboxBtn.Position = UDim2.new(0, 5, 0, 5)
    checkboxBtn.BackgroundColor3 = watched and Color3.fromRGB(80, 200, 80) or Color3.fromRGB(55, 55, 75)
    checkboxBtn.Text = watched and "✔" or ""
    checkboxBtn.TextColor3 = Color3.new(1, 1, 1)
    checkboxBtn.TextSize = 13
    checkboxBtn.Font = Enum.Font.GothamBold
    checkboxBtn.Parent = card
    Instance.new("UICorner", checkboxBtn).CornerRadius = UDim.new(0, 5)
    local checkStroke = Instance.new("UIStroke", checkboxBtn)
    checkStroke.Color = watched and Color3.fromRGB(80, 200, 80) or Color3.fromRGB(100, 100, 130)
    checkStroke.Thickness = 2

    checkboxBtn.MouseButton1Click:Connect(function()
        local newState = not isWatched(name)
        setWatched(name, newState)
        checkboxBtn.Text = newState and "✔" or ""
        checkboxBtn.BackgroundColor3 = newState and Color3.fromRGB(80, 200, 80) or Color3.fromRGB(55, 55, 75)
        checkStroke.Color = newState and Color3.fromRGB(80, 200, 80) or Color3.fromRGB(100, 100, 130)
        card.BackgroundColor3 = newState and Color3.fromRGB(30, 48, 35) or Color3.fromRGB(38, 38, 52)
        stroke.Color = newState and Color3.fromRGB(80, 200, 80) or Color3.fromRGB(55, 55, 75)
        notify(newState and ("👁️ Watch: " .. name) or ("❌ Unwatch: " .. name))
    end)

    -- Name
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -180, 0, 17)
    nameLabel.Position = UDim2.new(0, 32, 0, 3)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = name
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 120)
    nameLabel.TextSize = 12
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    nameLabel.Parent = card

    -- Info: Price + Count
    local countText = entry.count > 0 and ("x" .. entry.count) or "x0"
    local availIcon = isAvailable and "🟢" or "🔴"

    local infoLabel = Instance.new("TextLabel")
    infoLabel.Size = UDim2.new(1, -180, 0, 14)
    infoLabel.Position = UDim2.new(0, 32, 0, 20)
    infoLabel.BackgroundTransparency = 1
    infoLabel.Text = string.format("💰 %s  •  %s %s", entry.price, availIcon, countText)
    infoLabel.TextColor3 = Color3.fromRGB(140, 190, 255)
    infoLabel.TextSize = 10
    infoLabel.Font = Enum.Font.Gotham
    infoLabel.TextXAlignment = Enum.TextXAlignment.Left
    infoLabel.Parent = card

    -- Info: Distance + Type
    local distText = isAvailable and formatDistance(closestDist) or "N/A"
    local infoLabel2 = Instance.new("TextLabel")
    infoLabel2.Size = UDim2.new(1, -180, 0, 13)
    infoLabel2.Position = UDim2.new(0, 32, 0, 34)
    infoLabel2.BackgroundTransparency = 1
    infoLabel2.Text = string.format("📍 %s  •  🔘 %s", distText, entry.interactionType)
    infoLabel2.TextColor3 = Color3.fromRGB(100, 200, 100)
    infoLabel2.TextSize = 9
    infoLabel2.Font = Enum.Font.Gotham
    infoLabel2.TextXAlignment = Enum.TextXAlignment.Left
    infoLabel2.Parent = card

    -- Status
    local statusText = isAvailable and "✅ Available" or "⏳ Waiting respawn..."
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(1, -180, 0, 13)
    statusLabel.Position = UDim2.new(0, 32, 0, 48)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = statusText
    statusLabel.TextColor3 = isAvailable and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 150, 50)
    statusLabel.TextSize = 9
    statusLabel.Font = Enum.Font.GothamBold
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.Parent = card

    -- ===== BUTTONS =====
    local btnW = 46
    local rm = 5

    -- TP+Buy (top)
    local tpBuyBtn = Instance.new("TextButton")
    tpBuyBtn.Size = UDim2.new(0, btnW * 2 + 4, 0, 20)
    tpBuyBtn.Position = UDim2.new(1, -(btnW * 2 + 4 + rm), 0, 3)
    tpBuyBtn.BackgroundColor3 = isAvailable and Color3.fromRGB(150, 85, 220) or Color3.fromRGB(70, 55, 90)
    tpBuyBtn.Text = "⚡ TP+Buy"
    tpBuyBtn.TextColor3 = Color3.new(1, 1, 1)
    tpBuyBtn.TextSize = 10
    tpBuyBtn.Font = Enum.Font.GothamBold
    tpBuyBtn.AutoButtonColor = isAvailable
    tpBuyBtn.Parent = card
    Instance.new("UICorner", tpBuyBtn).CornerRadius = UDim.new(0, 6)

    -- TP (bottom left)
    local tpBtn = Instance.new("TextButton")
    tpBtn.Size = UDim2.new(0, btnW, 0, 20)
    tpBtn.Position = UDim2.new(1, -(btnW * 2 + 4 + rm), 0, 27)
    tpBtn.BackgroundColor3 = isAvailable and Color3.fromRGB(65, 115, 220) or Color3.fromRGB(45, 55, 85)
    tpBtn.Text = "📍 TP"
    tpBtn.TextColor3 = Color3.new(1, 1, 1)
    tpBtn.TextSize = 10
    tpBtn.Font = Enum.Font.GothamBold
    tpBtn.AutoButtonColor = isAvailable
    tpBtn.Parent = card
    Instance.new("UICorner", tpBtn).CornerRadius = UDim.new(0, 6)

    -- Buy (bottom right)
    local buyBtn = Instance.new("TextButton")
    buyBtn.Size = UDim2.new(0, btnW, 0, 20)
    buyBtn.Position = UDim2.new(1, -(btnW + rm), 0, 27)
    buyBtn.BackgroundColor3 = isAvailable and Color3.fromRGB(45, 145, 45) or Color3.fromRGB(35, 65, 35)
    buyBtn.Text = "🛒 Buy"
    buyBtn.TextColor3 = Color3.new(1, 1, 1)
    buyBtn.TextSize = 10
    buyBtn.Font = Enum.Font.GothamBold
    buyBtn.AutoButtonColor = isAvailable
    buyBtn.Parent = card
    Instance.new("UICorner", buyBtn).CornerRadius = UDim.new(0, 6)

    -- Watched badge
    if watched then
        local wb = Instance.new("TextLabel")
        wb.Size = UDim2.new(0, btnW * 2 + 4, 0, 15)
        wb.Position = UDim2.new(1, -(btnW * 2 + 4 + rm), 0, 51)
        wb.BackgroundColor3 = Color3.fromRGB(55, 150, 55)
        wb.Text = "👁️ Watched"
        wb.TextColor3 = Color3.new(1, 1, 1)
        wb.TextSize = 8
        wb.Font = Enum.Font.GothamBold
        wb.Parent = card
        Instance.new("UICorner", wb).CornerRadius = UDim.new(0, 4)
    end

    -- Button actions
    local function getClosest()
        local obj = getAliveInstance(name)
        if not obj then notify("⏳ " .. name .. " tidak tersedia saat ini.") end
        return obj
    end

    tpBtn.MouseButton1Click:Connect(function()
        local obj = getClosest()
        if obj then notify("📍 TP: " .. name) teleportTo(obj) notify("✅ Arrived!") end
    end)

    buyBtn.MouseButton1Click:Connect(function()
        local obj = getClosest()
        if obj then
            notify("🛒 Buy: " .. name)
            local ok = buyItem(obj)
            notify(ok and "✅ Done!" or "❌ Failed!")
        end
    end)

    tpBuyBtn.MouseButton1Click:Connect(function()
        local obj = getClosest()
        if obj then teleportAndBuy(obj) end
    end)

    -- Hover
    for _, btn in ipairs({tpBtn, buyBtn, tpBuyBtn}) do
        local orig = btn.BackgroundColor3
        btn.MouseEnter:Connect(function()
            if isAvailable then
                TweenService:Create(btn, TweenInfo.new(0.15), {
                    BackgroundColor3 = Color3.new(
                        math.min(orig.R + 0.1, 1),
                        math.min(orig.G + 0.1, 1),
                        math.min(orig.B + 0.1, 1))
                }):Play()
            end
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = orig}):Play()
        end)
    end

    return card
end

-- ================== SCAN & DISPLAY ==================
local function clearList()
    for _, child in pairs(ScrollFrame:GetChildren()) do
        if child:IsA("Frame") or child:IsA("TextLabel") then child:Destroy() end
    end
end

local function scanForItems()
    StatusLabel.Text = "🔄 Scanning..."
    StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 0)

    task.spawn(function()
        local scanned = 0

        for _, obj in pairs(Workspace:GetDescendants()) do
            if (obj:IsA("Model") or obj:IsA("BasePart")) and hasClickable(obj) then
                registerItem(obj)
            end
            scanned = scanned + 1
            if scanned % 600 == 0 then task.wait() end
        end

        -- Clean dead instances
        for name, entry in pairs(itemRegistry) do
            for i = #entry.instances, 1, -1 do
                if not entry.instances[i] or not entry.instances[i].Parent then
                    table.remove(entry.instances, i)
                end
            end
            entry.count = #entry.instances
        end

        -- Build lists
        clearList()

        local utilsList, shopList, watchedList = {}, {}, {}

        for name, entry in pairs(itemRegistry) do
            if entry.category == "utilities" then
                table.insert(utilsList, entry)
            else
                table.insert(shopList, entry)
            end
            if isWatched(name) then
                table.insert(watchedList, entry)
            end
        end

        local function sortAlpha(a, b) return a.name < b.name end
        table.sort(utilsList, sortAlpha)
        table.sort(shopList, sortAlpha)
        table.sort(watchedList, sortAlpha)

        local displayList, tabLabel = {}, ""

        if currentTab == "utilities" then
            displayList = utilsList tabLabel = "Utils"
        elseif currentTab == "shop" then
            displayList = shopList tabLabel = "Shop"
        elseif currentTab == "watched" then
            displayList = watchedList tabLabel = "Watched"
        end

        for i, entry in ipairs(displayList) do
            createUnifiedCard(entry, i)
        end

        ItemCountLabel.Text = string.format("📦 %s: %d", tabLabel, #displayList)
        StatusLabel.Text = string.format("✅ S:%d U:%d W:%d",
            #shopList, #utilsList, #watchedList)
        StatusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)

        if #displayList == 0 then
            local h = Instance.new("TextLabel")
            h.Size = UDim2.new(1, -8, 0, 100)
            h.BackgroundTransparency = 1
            h.TextWrapped = true
            h.TextColor3 = Color3.fromRGB(255, 200, 100)
            h.TextSize = 12
            h.Font = Enum.Font.Gotham
            h.Parent = ScrollFrame

            if currentTab == "watched" then
                h.Text = "👁️ Belum ada item di-watch!\n\nGunakan ✔ checkbox\ndi tab Utils / Shop."
            elseif currentTab == "utilities" then
                h.Text = "🔧 Tidak ada utility items!\n\nItem dengan nama 1-2 karakter."
            else
                h.Text = "🛒 Tidak ada shop items!\n\nDekatilah area toko\nlalu tekan 🔄 Scan."
            end
        end
    end)
end

-- ================== TAB SWITCHING ==================
local function switchTab(tabId)
    currentTab = tabId
    for id, btn in pairs(tabButtons) do
        TweenService:Create(btn, TweenInfo.new(0.2), {
            BackgroundColor3 = (id == tabId)
                and Color3.fromRGB(80, 80, 255) or Color3.fromRGB(40, 40, 55)
        }):Play()
    end
    scanForItems()
end

for id, btn in pairs(tabButtons) do
    btn.MouseButton1Click:Connect(function() switchTab(id) end)
end

-- ================== CONTROL BUTTONS ==================
ctrlButtons["scan"].MouseButton1Click:Connect(function() scanForItems() end)

ctrlButtons["autotp"].MouseButton1Click:Connect(function()
    Settings.AutoTP = not Settings.AutoTP
    ctrlButtons["autotp"].BackgroundColor3 = Settings.AutoTP
        and Color3.fromRGB(60, 150, 60) or Color3.fromRGB(60, 60, 80)
    ctrlButtons["autotp"].Text = Settings.AutoTP and "✅ AutoTP" or "📍 AutoTP"
    notify(Settings.AutoTP and "✅ Auto-TP ON" or "⏸️ Auto-TP OFF")
end)

ctrlButtons["autobuy"].MouseButton1Click:Connect(function()
    Settings.AutoBuy = not Settings.AutoBuy
    ctrlButtons["autobuy"].BackgroundColor3 = Settings.AutoBuy
        and Color3.fromRGB(60, 150, 60) or Color3.fromRGB(60, 60, 80)
    ctrlButtons["autobuy"].Text = Settings.AutoBuy and "✅ AutoBuy" or "🛒 AutoBuy"
    notify(Settings.AutoBuy and "✅ Auto-Buy ON" or "⏸️ Auto-Buy OFF")
end)

ctrlButtons["autoref"].MouseButton1Click:Connect(function()
    Settings.AutoRefresh = not Settings.AutoRefresh
    ctrlButtons["autoref"].BackgroundColor3 = Settings.AutoRefresh
        and Color3.fromRGB(60, 150, 60) or Color3.fromRGB(60, 60, 80)
    ctrlButtons["autoref"].Text = Settings.AutoRefresh and "✅ AutoRef" or "🔁 AutoRef"
    notify(Settings.AutoRefresh and "✅ Auto-Refresh ON" or "⏸️ Auto-Refresh OFF")
end)

ctrlButtons["antiafk"].MouseButton1Click:Connect(function()
    antiAfkActive = not antiAfkActive
    ctrlButtons["antiafk"].BackgroundColor3 = antiAfkActive
        and Color3.fromRGB(40, 140, 200) or Color3.fromRGB(60, 60, 80)
    ctrlButtons["antiafk"].Text = antiAfkActive and "✅ AFK" or "⏰ AFK"
    afkBadge.Text = antiAfkActive and "⏰ AFK-ON" or "⏰ AFK-OFF"
    afkBadge.BackgroundColor3 = antiAfkActive
        and Color3.fromRGB(40, 140, 200) or Color3.fromRGB(100, 60, 60)
    notify(antiAfkActive and "✅ Anti-AFK ON" or "⏸️ Anti-AFK OFF")
    if antiAfkActive then startAntiAfk() end
end)

-- ================== AUTO-BUY / AUTO-TP LOOP ==================
task.spawn(function()
    while task.wait(1.5) do
        if (Settings.AutoTP or Settings.AutoBuy) and not isAutoBuying then
            isAutoBuying = true

            local targets = {}
            for name, _ in pairs(watchedNames) do
                local obj, dist = getAliveInstance(name)
                if obj then table.insert(targets, {name = name, obj = obj, distance = dist}) end
            end

            table.sort(targets, function(a, b) return a.distance < b.distance end)

            for _, t in ipairs(targets) do
                if not Settings.AutoTP and not Settings.AutoBuy then break end
                if not t.obj or not t.obj.Parent then continue end

                if Settings.AutoTP then teleportTo(t.obj) end
                if Settings.AutoBuy then task.wait(0.3) buyItem(t.obj) end
                task.wait(0.5)
            end

            isAutoBuying = false
        end
    end
end)

-- ================== AUTO REFRESH LOOP ==================
task.spawn(function()
    while task.wait(Settings.RefreshInterval) do
        if Settings.AutoRefresh then scanForItems() end
    end
end)

-- ================== AUTO-DETECT NEW ITEMS ==================
Workspace.DescendantAdded:Connect(function(obj)
    task.wait(0.2)
    if (obj:IsA("Model") or obj:IsA("BasePart")) and hasClickable(obj) then
        registerItem(obj)
    end
end)

-- ================== MOBILE DRAG ==================
if isMobile then
    local dragging = false
    local dragStart, startPos

    TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = Main.Position
        end
    end)

    TitleBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch and dragging then
            local delta = input.Position - dragStart
            Main.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)

    TitleBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

-- ================== INITIAL ==================
task.wait(1)
scanForItems()
notify("✅ Shop Finder Pro Loaded!")

print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("✅ SHOP FINDER PRO - CLEAN VERSION LOADED!")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("📂 3 Tabs: Utils | Shop | Watched")
print("⏰ Anti-AFK: Active")
print("📦 Unified List: Grouped & Persistent")
print("🔽 Minimize: Icon kecil melayang")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
