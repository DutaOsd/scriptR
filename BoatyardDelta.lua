-- ================== SHOP ITEM FINDER & TELEPORTER - FULL VERSION ==================
-- 3 Tab System | Checklist/Watch | Auto-TP | Auto-Buy | Manual Buttons

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local player = Players.LocalPlayer
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

print("🛒 Shop Finder Full - Starting...")

-- ================== SETTINGS ==================
local Settings = {
    AutoRefresh = true,
    RefreshInterval = 5,
    SearchRadius = 10000,
    RequireValidPrice = false,
    AutoTP = false,
    AutoBuy = false,
    TeleportDelay = 0.5,
    BuyDelay = 0.3,
}

local foundItems = {}
local watchedItems = {} -- {objRef = true/false}
local watchedNames = {} -- persist by name {name = true}
local currentTab = "utilities" -- "utilities" | "shop" | "watched"
local isAutoBuying = false

-- ================== NOTIFICATION ==================
local function notify(text)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "🛒 Shop Finder";
            Text = text;
            Duration = 3;
        })
    end)
end

-- ================== SCREEN GUI ==================
repeat task.wait() until player:FindFirstChild("PlayerGui")

-- Cleanup old GUI
local oldGui = player.PlayerGui:FindFirstChild("ShopFinderGUI_Full")
if oldGui then oldGui:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ShopFinderGUI_Full"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 999999999
ScreenGui.Parent = player.PlayerGui

-- ================== MAIN FRAME ==================
local Main = Instance.new("Frame")
Main.Name = "MainFrame"
Main.Size = isMobile and UDim2.new(0.92, 0, 0.7, 0) or UDim2.new(0, 420, 0, 560)
Main.Position = isMobile and UDim2.new(0.04, 0, 0.15, 0) or UDim2.new(0.02, 0, 0.15, 0)
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

-- ================== TITLE BAR ==================
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 46)
TitleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = Main
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 14)

-- Bottom cover for rounded corners
local TBCover = Instance.new("Frame")
TBCover.Size = UDim2.new(1, 0, 0, 14)
TBCover.Position = UDim2.new(0, 0, 1, -14)
TBCover.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
TBCover.BorderSizePixel = 0
TBCover.Parent = TitleBar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(0.7, 0, 1, 0)
Title.Position = UDim2.new(0.04, 0, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "🛒 Shop Finder Pro"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.TextSize = isMobile and 17 or 16
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TitleBar

-- Minimize Button
local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 30, 0, 30)
MinBtn.Position = UDim2.new(1, -70, 0, 8)
MinBtn.BackgroundColor3 = Color3.fromRGB(255, 180, 0)
MinBtn.Text = "—"
MinBtn.TextColor3 = Color3.new(1, 1, 1)
MinBtn.TextSize = 16
MinBtn.Font = Enum.Font.GothamBold
MinBtn.Parent = TitleBar
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0.5, 0)

local isMinimized = false
local savedSize

MinBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        savedSize = Main.Size
        TweenService:Create(Main, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {
            Size = isMobile and UDim2.new(0.92, 0, 0, 46) or UDim2.new(0, 420, 0, 46)
        }):Play()
        MinBtn.Text = "+"
    else
        TweenService:Create(Main, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {
            Size = savedSize
        }):Play()
        MinBtn.Text = "—"
    end
end)

-- Close Button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -36, 0, 8)
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
    ScreenGui:Destroy()
end)

-- ================== TAB BAR ==================
local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(1, -12, 0, 36)
TabBar.Position = UDim2.new(0, 6, 0, 50)
TabBar.BackgroundTransparency = 1
TabBar.Parent = Main

local tabDefs = {
    {id = "utilities", icon = "🔧", label = "Utilities"},
    {id = "shop",      icon = "🛒", label = "Shop"},
    {id = "watched",   icon = "👁️", label = "Watched"},
}

local tabButtons = {}

for i, def in ipairs(tabDefs) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1/3, -4, 1, 0)
    btn.Position = UDim2.new((i-1)/3, 2, 0, 0)
    btn.BackgroundColor3 = (currentTab == def.id) and Color3.fromRGB(80, 80, 255) or Color3.fromRGB(40, 40, 55)
    btn.Text = def.icon .. " " .. def.label
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.TextSize = isMobile and 12 or 12
    btn.Font = Enum.Font.GothamBold
    btn.Parent = TabBar
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    
    tabButtons[def.id] = btn
end

-- ================== INFO BAR ==================
local InfoBar = Instance.new("Frame")
InfoBar.Size = UDim2.new(1, -12, 0, 32)
InfoBar.Position = UDim2.new(0, 6, 0, 90)
InfoBar.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
InfoBar.BorderSizePixel = 0
InfoBar.Parent = Main
Instance.new("UICorner", InfoBar).CornerRadius = UDim.new(0, 8)

local ItemCountLabel = Instance.new("TextLabel")
ItemCountLabel.Size = UDim2.new(0.5, 0, 1, 0)
ItemCountLabel.Position = UDim2.new(0, 8, 0, 0)
ItemCountLabel.BackgroundTransparency = 1
ItemCountLabel.Text = "📦 Items: 0"
ItemCountLabel.TextColor3 = Color3.new(1, 1, 1)
ItemCountLabel.TextSize = 12
ItemCountLabel.Font = Enum.Font.GothamBold
ItemCountLabel.TextXAlignment = Enum.TextXAlignment.Left
ItemCountLabel.Parent = InfoBar

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(0.5, 0, 1, 0)
StatusLabel.Position = UDim2.new(0.5, 0, 0, 0)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "✅ Ready"
StatusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
StatusLabel.TextSize = 11
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextXAlignment = Enum.TextXAlignment.Right
StatusLabel.Parent = InfoBar

-- ================== CONTROL BAR (4 Buttons) ==================
local ControlBar = Instance.new("Frame")
ControlBar.Size = UDim2.new(1, -12, 0, 34)
ControlBar.Position = UDim2.new(0, 6, 0, 126)
ControlBar.BackgroundTransparency = 1
ControlBar.Parent = Main

local ctrlBtnDefs = {
    {id = "scan",     label = "🔄 Scan",      color = Color3.fromRGB(60, 150, 60)},
    {id = "autotp",   label = "📍 Auto-TP",   color = Color3.fromRGB(60, 60, 80)},
    {id = "autobuy",  label = "🛒 Auto-Buy",  color = Color3.fromRGB(60, 60, 80)},
    {id = "autoref",  label = "✅ Auto-Ref",   color = Color3.fromRGB(60, 150, 60)},
}

local ctrlButtons = {}

for i, def in ipairs(ctrlBtnDefs) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1/4, -3, 1, 0)
    btn.Position = UDim2.new((i-1)/4, 1.5, 0, 0)
    btn.BackgroundColor3 = def.color
    btn.Text = def.label
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.TextSize = isMobile and 10 or 10
    btn.Font = Enum.Font.GothamBold
    btn.Parent = ControlBar
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    
    ctrlButtons[def.id] = btn
end

-- ================== SCROLL FRAME ==================
local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Size = UDim2.new(1, -12, 1, -172)
ScrollFrame.Position = UDim2.new(0, 6, 0, 166)
ScrollFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 38)
ScrollFrame.BorderSizePixel = 0
ScrollFrame.ScrollBarThickness = 5
ScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 255)
ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ScrollFrame.Parent = Main
Instance.new("UICorner", ScrollFrame).CornerRadius = UDim.new(0, 8)

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Padding = UDim.new(0, 5)
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

print("✅ GUI Created")

-- ================== HELPER FUNCTIONS ==================

local function getDistance(obj)
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
        return math.huge
    end
    local hrp = player.Character.HumanoidRootPart
    local pos
    if obj:IsA("Model") then
        local part = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)
        if part then pos = part.Position else return math.huge end
    elseif obj:IsA("BasePart") then
        pos = obj.Position
    else
        return math.huge
    end
    return (hrp.Position - pos).Magnitude
end

local function formatDistance(dist)
    if dist == math.huge then return "???" end
    if dist < 1000 then
        return string.format("%.0fm", dist)
    else
        return string.format("%.1fk", dist / 1000)
    end
end

local function extractPrice(obj)
    local priceFound = nil
    local currencyType = "?"

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
                            priceFound = match:gsub(",", "")
                            currencyType = p.currency
                            break
                        end
                    end
                    if priceFound then break end
                end
            end
            if priceFound then break end
        end
    end

    if not priceFound then
        local namePrice = obj.Name:match("([%d,]+)")
        if namePrice and tonumber(namePrice:gsub(",", "")) then
            priceFound = namePrice:gsub(",", "")
            currencyType = ""
        end
    end

    if priceFound and tonumber(priceFound) then
        return priceFound .. currencyType, true
    else
        return nil, false
    end
end

local function hasClickable(obj)
    return obj:FindFirstChildWhichIsA("ClickDetector", true) or 
           obj:FindFirstChildWhichIsA("ProximityPrompt", true)
end

local function getItemCategory(obj)
    local name = obj.Name:gsub("%s+", "")
    if #name <= 2 then
        return "utilities"
    else
        return "shop"
    end
end

local function isWatched(obj)
    return watchedNames[obj.Name] == true
end

local function setWatched(obj, state)
    watchedNames[obj.Name] = state or nil
end

-- ================== TELEPORT FUNCTION ==================
local function getTargetPosition(obj)
    local pos
    if obj:IsA("Model") then
        local part = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)
        if part then pos = part.Position end
    elseif obj:IsA("BasePart") then
        pos = obj.Position
    end
    return pos
end

local function teleportTo(obj)
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
        notify("❌ No character!")
        return false
    end

    local targetPos = getTargetPosition(obj)
    if not targetPos then
        notify("❌ Can't find position!")
        return false
    end

    local hrp = player.Character.HumanoidRootPart
    hrp.CFrame = CFrame.new(targetPos + Vector3.new(0, 5, 0))
    task.wait(Settings.TeleportDelay)
    return true
end

-- ================== BUY FUNCTION ==================
local function buyItem(obj)
    if not obj or not obj.Parent then
        return false
    end

    -- Try ProximityPrompt first
    local proxPrompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
    if proxPrompt then
        pcall(function()
            fireproximityprompt(proxPrompt)
        end)
        task.wait(Settings.BuyDelay)
        return true
    end

    -- Try ClickDetector
    local clickDetector = obj:FindFirstChildWhichIsA("ClickDetector", true)
    if clickDetector then
        pcall(function()
            fireclickdetector(clickDetector)
        end)
        task.wait(Settings.BuyDelay)
        return true
    end

    return false
end

local function teleportAndBuy(obj)
    if not obj or not obj.Parent then
        notify("❌ Item gone!")
        return false
    end

    notify("📍 TP to: " .. obj.Name)
    local tpOk = teleportTo(obj)
    if tpOk then
        task.wait(0.3)
        notify("🛒 Buying: " .. obj.Name)
        return buyItem(obj)
    end
    return false
end

-- ================== CREATE ITEM CARD ==================
local function createItemCard(obj, index)
    local distance = getDistance(obj)
    local price, isValid = extractPrice(obj)
    local watched = isWatched(obj)

    if not price then price = "No Price" end

    local card = Instance.new("Frame")
    card.Name = "Card_" .. index
    card.Size = isMobile and UDim2.new(1, -4, 0, 78) or UDim2.new(1, -4, 0, 74)
    card.BackgroundColor3 = watched and Color3.fromRGB(35, 50, 40) or Color3.fromRGB(38, 38, 52)
    card.BorderSizePixel = 0
    card.LayoutOrder = math.floor(distance)
    card.Parent = ScrollFrame

    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)

    local stroke = Instance.new("UIStroke", card)
    stroke.Color = watched and Color3.fromRGB(80, 200, 80) or Color3.fromRGB(55, 55, 75)
    stroke.Thickness = 1
    stroke.Transparency = 0.3

    -- ===== CHECKBOX =====
    local checkboxBtn = Instance.new("TextButton")
    checkboxBtn.Size = UDim2.new(0, 24, 0, 24)
    checkboxBtn.Position = UDim2.new(0, 6, 0, 6)
    checkboxBtn.BackgroundColor3 = watched and Color3.fromRGB(80, 200, 80) or Color3.fromRGB(55, 55, 75)
    checkboxBtn.Text = watched and "✔" or ""
    checkboxBtn.TextColor3 = Color3.new(1, 1, 1)
    checkboxBtn.TextSize = 14
    checkboxBtn.Font = Enum.Font.GothamBold
    checkboxBtn.Parent = card
    Instance.new("UICorner", checkboxBtn).CornerRadius = UDim.new(0, 5)

    local checkStroke = Instance.new("UIStroke", checkboxBtn)
    checkStroke.Color = watched and Color3.fromRGB(80, 200, 80) or Color3.fromRGB(100, 100, 130)
    checkStroke.Thickness = 2

    checkboxBtn.MouseButton1Click:Connect(function()
        local newState = not isWatched(obj)
        setWatched(obj, newState)

        -- Update visuals
        checkboxBtn.Text = newState and "✔" or ""
        checkboxBtn.BackgroundColor3 = newState and Color3.fromRGB(80, 200, 80) or Color3.fromRGB(55, 55, 75)
        checkStroke.Color = newState and Color3.fromRGB(80, 200, 80) or Color3.fromRGB(100, 100, 130)
        card.BackgroundColor3 = newState and Color3.fromRGB(35, 50, 40) or Color3.fromRGB(38, 38, 52)
        stroke.Color = newState and Color3.fromRGB(80, 200, 80) or Color3.fromRGB(55, 55, 75)

        notify(newState and ("👁️ Watching: " .. obj.Name) or ("❌ Unwatched: " .. obj.Name))
    end)

    -- ===== INDEX BADGE =====
    local indexBadge = Instance.new("TextLabel")
    indexBadge.Size = UDim2.new(0, 24, 0, 18)
    indexBadge.Position = UDim2.new(0, 6, 0, 34)
    indexBadge.BackgroundColor3 = Color3.fromRGB(55, 55, 75)
    indexBadge.Text = tostring(index)
    indexBadge.TextColor3 = Color3.fromRGB(180, 180, 200)
    indexBadge.TextSize = 10
    indexBadge.Font = Enum.Font.GothamBold
    indexBadge.Parent = card
    Instance.new("UICorner", indexBadge).CornerRadius = UDim.new(0, 4)

    -- ===== NAME =====
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -210, 0, 18)
    nameLabel.Position = UDim2.new(0, 36, 0, 5)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = obj.Name
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 120)
    nameLabel.TextSize = 13
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    nameLabel.Parent = card

    -- ===== PRICE & DISTANCE =====
    local infoLabel = Instance.new("TextLabel")
    infoLabel.Size = UDim2.new(1, -210, 0, 16)
    infoLabel.Position = UDim2.new(0, 36, 0, 24)
    infoLabel.BackgroundTransparency = 1
    infoLabel.Text = string.format("💰 %s  •  📍 %s", price, formatDistance(distance))
    infoLabel.TextColor3 = Color3.fromRGB(140, 190, 255)
    infoLabel.TextSize = 11
    infoLabel.Font = Enum.Font.Gotham
    infoLabel.TextXAlignment = Enum.TextXAlignment.Left
    infoLabel.Parent = card

    -- ===== INTERACTION TYPE =====
    local hasProx = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
    local hasClick = obj:FindFirstChildWhichIsA("ClickDetector", true)
    local intType = hasProx and "ProximityPrompt" or (hasClick and "ClickDetector" or "None")

    local typeLabel = Instance.new("TextLabel")
    typeLabel.Size = UDim2.new(1, -210, 0, 14)
    typeLabel.Position = UDim2.new(0, 36, 0, 41)
    typeLabel.BackgroundTransparency = 1
    typeLabel.Text = "🔘 " .. intType
    typeLabel.TextColor3 = Color3.fromRGB(100, 230, 100)
    typeLabel.TextSize = 10
    typeLabel.Font = Enum.Font.Gotham
    typeLabel.TextXAlignment = Enum.TextXAlignment.Left
    typeLabel.Parent = card

    -- ===== BUTTONS AREA =====
    local btnWidth = isMobile and 50 or 50
    local btnHeight = 22
    local rightMargin = 6

    -- Helper to create a small button
    local function makeBtn(text, yPos, color)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0, btnWidth, 0, btnHeight)
        b.Position = UDim2.new(1, -(btnWidth + rightMargin), 0, yPos)
        b.BackgroundColor3 = color
        b.Text = text
        b.TextColor3 = Color3.new(1, 1, 1)
        b.TextSize = 10
        b.Font = Enum.Font.GothamBold
        b.Parent = card
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)

        -- Hover
        b.MouseEnter:Connect(function()
            TweenService:Create(b, TweenInfo.new(0.15), {
                BackgroundColor3 = Color3.new(
                    math.min(color.R + 0.12, 1),
                    math.min(color.G + 0.12, 1),
                    math.min(color.B + 0.12, 1)
                )
            }):Play()
        end)
        b.MouseLeave:Connect(function()
            TweenService:Create(b, TweenInfo.new(0.15), {BackgroundColor3 = color}):Play()
        end)

        return b
    end

    -- TP + Buy (combo)
    local tpBuyBtnWidth = 60
    local tpBuyBtn = Instance.new("TextButton")
    tpBuyBtn.Size = UDim2.new(0, tpBuyBtnWidth, 0, btnHeight)
    tpBuyBtn.Position = UDim2.new(1, -(btnWidth + tpBuyBtnWidth + rightMargin + 4), 0, 4)
    tpBuyBtn.BackgroundColor3 = Color3.fromRGB(180, 100, 255)
    tpBuyBtn.Text = "⚡TP+Buy"
    tpBuyBtn.TextColor3 = Color3.new(1, 1, 1)
    tpBuyBtn.TextSize = 10
    tpBuyBtn.Font = Enum.Font.GothamBold
    tpBuyBtn.Parent = card
    Instance.new("UICorner", tpBuyBtn).CornerRadius = UDim.new(0, 6)

    tpBuyBtn.MouseEnter:Connect(function()
        TweenService:Create(tpBuyBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(200, 130, 255)}):Play()
    end)
    tpBuyBtn.MouseLeave:Connect(function()
        TweenService:Create(tpBuyBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(180, 100, 255)}):Play()
    end)

    -- TP button
    local tpBtn = makeBtn("📍 TP", 4, Color3.fromRGB(80, 130, 255))

    -- Buy button
    local buyBtn = makeBtn("🛒 Buy", 30, Color3.fromRGB(60, 160, 60))

    -- Buy button (shift left)
    buyBtn.Position = UDim2.new(1, -(btnWidth + rightMargin), 0, 30)

    -- TP button (shift left more)
    tpBtn.Position = UDim2.new(1, -(btnWidth + rightMargin), 0, 4)

    -- Rearrange: TP+Buy | TP | Buy vertically? 
    -- Better layout: 3 buttons on the right side stacked/side by side
    -- Let's do: right column with TP and Buy stacked, TP+Buy wider above them

    -- Re-layout
    local colRight = rightMargin
    tpBuyBtn.Size = UDim2.new(0, btnWidth * 2 + 4, 0, btnHeight)
    tpBuyBtn.Position = UDim2.new(1, -(btnWidth * 2 + 4 + colRight), 0, 4)

    tpBtn.Size = UDim2.new(0, btnWidth, 0, btnHeight)
    tpBtn.Position = UDim2.new(1, -(btnWidth * 2 + 4 + colRight), 0, 30)

    buyBtn.Size = UDim2.new(0, btnWidth, 0, btnHeight)
    buyBtn.Position = UDim2.new(1, -(btnWidth + colRight), 0, 30)

    -- ===== BUTTON ACTIONS =====
    tpBtn.MouseButton1Click:Connect(function()
        if obj and obj.Parent then
            notify("📍 Teleporting to " .. obj.Name)
            teleportTo(obj)
            notify("✅ Arrived!")
        else
            notify("❌ Item gone!")
            card:Destroy()
        end
    end)

    buyBtn.MouseButton1Click:Connect(function()
        if obj and obj.Parent then
            notify("🛒 Buying " .. obj.Name)
            local ok = buyItem(obj)
            notify(ok and "✅ Buy triggered!" or "❌ Buy failed!")
        else
            notify("❌ Item gone!")
            card:Destroy()
        end
    end)

    tpBuyBtn.MouseButton1Click:Connect(function()
        if obj and obj.Parent then
            teleportAndBuy(obj)
        else
            notify("❌ Item gone!")
            card:Destroy()
        end
    end)

    -- ===== WATCHED INDICATOR =====
    if watched then
        local watchBadge = Instance.new("TextLabel")
        watchBadge.Size = UDim2.new(0, 20, 0, 14)
        watchBadge.Position = UDim2.new(0, 36, 0, 56)
        watchBadge.BackgroundColor3 = Color3.fromRGB(80, 200, 80)
        watchBadge.Text = "👁️"
        watchBadge.TextSize = 9
        watchBadge.Font = Enum.Font.Gotham
        watchBadge.TextColor3 = Color3.new(1, 1, 1)
        watchBadge.Parent = card
        Instance.new("UICorner", watchBadge).CornerRadius = UDim.new(0, 4)
    end

    return card
end

-- ================== SCAN FUNCTION ==================

local function clearList()
    for _, child in pairs(ScrollFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
end

local function scanForItems()
    StatusLabel.Text = "🔄 Scanning..."
    StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
    clearList()
    foundItems = {}

    task.spawn(function()
        local scanned = 0
        local tempUtils = {}
        local tempShop = {}

        for _, obj in pairs(Workspace:GetDescendants()) do
            if (obj:IsA("Model") or obj:IsA("BasePart")) and hasClickable(obj) then
                local distance = getDistance(obj)
                if distance <= Settings.SearchRadius then
                    local cat = getItemCategory(obj)
                    local data = {obj = obj, distance = distance, category = cat}

                    if cat == "utilities" then
                        table.insert(tempUtils, data)
                    else
                        table.insert(tempShop, data)
                    end

                    table.insert(foundItems, data)
                end
            end

            scanned = scanned + 1
            if scanned % 500 == 0 then task.wait() end
        end

        -- Sort each by distance
        table.sort(tempUtils, function(a, b) return a.distance < b.distance end)
        table.sort(tempShop, function(a, b) return a.distance < b.distance end)

        -- Build watched list from foundItems
        local tempWatched = {}
        for _, data in ipairs(foundItems) do
            if isWatched(data.obj) then
                table.insert(tempWatched, data)
            end
        end
        table.sort(tempWatched, function(a, b) return a.distance < b.distance end)

        -- Pick which list to show
        local displayList = {}
        if currentTab == "utilities" then
            displayList = tempUtils
        elseif currentTab == "shop" then
            displayList = tempShop
        elseif currentTab == "watched" then
            displayList = tempWatched
        end

        -- Create cards
        for i, data in ipairs(displayList) do
            if data.obj and data.obj.Parent then
                createItemCard(data.obj, i)
            end
        end

        local totalCount = #displayList
        ItemCountLabel.Text = string.format("📦 %s: %d", 
            currentTab == "utilities" and "Utilities" or (currentTab == "shop" and "Shop" or "Watched"),
            totalCount
        )

        StatusLabel.Text = string.format("✅ Total: %d | U:%d S:%d W:%d", 
            #foundItems, #tempUtils, #tempShop, #tempWatched)
        StatusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)

        if totalCount == 0 then
            local helpLabel = Instance.new("TextLabel")
            helpLabel.Size = UDim2.new(1, -8, 0, 120)
            helpLabel.BackgroundTransparency = 1
            helpLabel.TextWrapped = true
            helpLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
            helpLabel.TextSize = 12
            helpLabel.Font = Enum.Font.Gotham
            helpLabel.Parent = ScrollFrame

            if currentTab == "watched" then
                helpLabel.Text = "👁️ No watched items yet!\n\nUse ✔ checkbox on items\nin Utilities or Shop tabs\nto add them here."
            elseif currentTab == "utilities" then
                helpLabel.Text = "🔧 No utility items found!\n\nLooking for items with\n1-2 character names\n(like ClickDetectors/Prompts)"
            else
                helpLabel.Text = "🛒 No shop items found!\n\nMust have ClickDetector or\nProximityPrompt.\n\nTry walking closer to shops!"
            end
        end
    end)
end

-- ================== TAB SWITCHING ==================
local function switchTab(tabId)
    currentTab = tabId

    for id, btn in pairs(tabButtons) do
        if id == tabId then
            TweenService:Create(btn, TweenInfo.new(0.2), {
                BackgroundColor3 = Color3.fromRGB(80, 80, 255)
            }):Play()
        else
            TweenService:Create(btn, TweenInfo.new(0.2), {
                BackgroundColor3 = Color3.fromRGB(40, 40, 55)
            }):Play()
        end
    end

    scanForItems()
end

-- Connect tab buttons
for id, btn in pairs(tabButtons) do
    btn.MouseButton1Click:Connect(function()
        switchTab(id)
    end)
end

-- ================== CONTROL BUTTON ACTIONS ==================

-- Scan
ctrlButtons["scan"].MouseButton1Click:Connect(function()
    scanForItems()
end)

-- Auto-TP toggle
ctrlButtons["autotp"].MouseButton1Click:Connect(function()
    Settings.AutoTP = not Settings.AutoTP
    ctrlButtons["autotp"].BackgroundColor3 = Settings.AutoTP 
        and Color3.fromRGB(60, 150, 60) or Color3.fromRGB(60, 60, 80)
    ctrlButtons["autotp"].Text = Settings.AutoTP 
        and "✅ Auto-TP" or "📍 Auto-TP"
    notify(Settings.AutoTP and "✅ Auto-TP ON" or "⏸️ Auto-TP OFF")
end)

-- Auto-Buy toggle
ctrlButtons["autobuy"].MouseButton1Click:Connect(function()
    Settings.AutoBuy = not Settings.AutoBuy
    ctrlButtons["autobuy"].BackgroundColor3 = Settings.AutoBuy 
        and Color3.fromRGB(60, 150, 60) or Color3.fromRGB(60, 60, 80)
    ctrlButtons["autobuy"].Text = Settings.AutoBuy 
        and "✅ Auto-Buy" or "🛒 Auto-Buy"
    notify(Settings.AutoBuy and "✅ Auto-Buy ON" or "⏸️ Auto-Buy OFF")
end)

-- Auto-Refresh toggle
ctrlButtons["autoref"].MouseButton1Click:Connect(function()
    Settings.AutoRefresh = not Settings.AutoRefresh
    ctrlButtons["autoref"].BackgroundColor3 = Settings.AutoRefresh 
        and Color3.fromRGB(60, 150, 60) or Color3.fromRGB(60, 60, 80)
    ctrlButtons["autoref"].Text = Settings.AutoRefresh 
        and "✅ Auto-Ref" or "⏸️ Auto-Ref"
    notify(Settings.AutoRefresh and "✅ Auto-Refresh ON" or "⏸️ Auto-Refresh OFF")
end)

-- ================== AUTO-BUY / AUTO-TP LOOP ==================
task.spawn(function()
    while task.wait(1) do
        if (Settings.AutoTP or Settings.AutoBuy) and not isAutoBuying then
            isAutoBuying = true
            
            -- Find all watched items that still exist
            local watchTargets = {}
            for _, data in ipairs(foundItems) do
                if data.obj and data.obj.Parent and isWatched(data.obj) then
                    table.insert(watchTargets, data)
                end
            end

            -- Sort by distance
            table.sort(watchTargets, function(a, b) 
                return getDistance(a.obj) < getDistance(b.obj) 
            end)

            for _, data in ipairs(watchTargets) do
                if not Settings.AutoTP and not Settings.AutoBuy then break end
                if not data.obj or not data.obj.Parent then continue end

                if Settings.AutoTP then
                    teleportTo(data.obj)
                end

                if Settings.AutoBuy then
                    task.wait(0.3)
                    buyItem(data.obj)
                end

                task.wait(0.5)
            end

            isAutoBuying = false
        end
    end
end)

-- ================== AUTO REFRESH LOOP ==================
task.spawn(function()
    while task.wait(Settings.RefreshInterval) do
        if Settings.AutoRefresh then
            scanForItems()
        end
    end
end)

-- ================== MOBILE DRAG SUPPORT ==================
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

-- ================== INITIAL SCAN ==================
task.wait(1)
scanForItems()
notify("✅ Shop Finder Pro Loaded!")

print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("✅ SHOP FINDER PRO - FULL VERSION LOADED!")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("📂 3 Tabs: Utilities | Shop | Watched")
print("✅ Checklist / Watch System")
print("⚡ Auto-TP & Auto-Buy for watched items")
print("🔘 Manual TP / Buy / TP+Buy per item")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
