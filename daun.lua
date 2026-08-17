-- // Leaf Simulator Configurator V2
-- // Fixed: Mobile UI, Draggable, Sizing, Button positions
-- // Semua parameter bisa di-setting via GUI
-- // Support Mobile + PC

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ═══════════════════════════════════════════
-- PLATFORM
-- ═══════════════════════════════════════════
local IsMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- ═══════════════════════════════════════════
-- CLEANUP
-- ═══════════════════════════════════════════
pcall(function() game:GetService("CoreGui"):FindFirstChild("LeafSimV2"):Destroy() end)
pcall(function() LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("LeafSimV2"):Destroy() end)

-- ═══════════════════════════════════════════
-- GAME MODULES
-- ═══════════════════════════════════════════
local LeafSim, SoundController, PlayerUpgradeConfig
local modulesLoaded = false

pcall(function()
	local PS = LocalPlayer:WaitForChild("PlayerScripts", 5)
	if PS then LeafSim = require(PS:WaitForChild("LeafSim", 5)) end
end)
pcall(function()
	SoundController = require(ReplicatedStorage:WaitForChild("SoundController", 5))
end)
pcall(function()
	PlayerUpgradeConfig = require(ReplicatedStorage:WaitForChild("PlayerUpgradeConfig", 5))
end)

modulesLoaded = (LeafSim ~= nil)

-- ═══════════════════════════════════════════
-- CONFIG STATE
-- ═══════════════════════════════════════════
local Config = {
	Tools = {
		Rake       = { enabled = false, attr = "OwnsRake",       perm = "PermRake" },
		LeafBlower = { enabled = false, attr = "OwnsLeafBlower", perm = "PermLeafBlower" },
		LeafVacuum = { enabled = false, attr = "OwnsLeafVacuum", perm = "PermLeafVacuum" },
		Molotov    = { enabled = false, attr = "OwnsMolotov",    perm = "PermMolotov" },
	},
	Hand = {
		Hold      = { enabled = false, value = 1, min = 1, max = 5, attr = "Upg_Hand_Hold" },
		Dexterity = { enabled = false, value = 5, min = 1, max = 5, attr = "Upg_Hand_Dexterity" },
		Grasp     = { enabled = false, value = 5, min = 1, max = 5, attr = "Upg_Hand_Grasp" },
	},
	Rake = {
		Radius     = { enabled = false, value = 5, min = 1, max = 5, attr = "Upg_Rake_Radius" },
		Range      = { enabled = false, value = 4, min = 1, max = 5, attr = "Upg_Rake_Range" },
		Stickiness = { enabled = false, value = 4, min = 1, max = 5, attr = "Upg_Rake_Stickiness" },
	},
	LeafBlower = {
		Width  = { enabled = false, value = 5, min = 1, max = 5, attr = "Upg_LeafBlower_Width" },
		Power  = { enabled = false, value = 4, min = 1, max = 5, attr = "Upg_LeafBlower_Power" },
		Spread = { enabled = false, value = 4, min = 1, max = 5, attr = "Upg_LeafBlower_Spread" },
	},
	Lobby = {
		WalkSpeed      = { enabled = false, value = 21,  min = 16, max = 50,  attr = "LobbyWalkSpeed" },
		BagBonus       = { enabled = false, value = 125, min = 0,  max = 500, attr = "LobbyBagBonus" },
		CashMult       = { enabled = false, value = 1.5, min = 1,  max = 5,   attr = "LobbyCashMult",      step = 0.1 },
		GemsMult       = { enabled = false, value = 1.5, min = 1,  max = 5,   attr = "LobbyGemsMult",      step = 0.1 },
		RakeDiscount   = { enabled = false, value = 1,   min = 0,  max = 1,   attr = "LobbyRakeDiscount" },
		BlowerDiscount = { enabled = false, value = 1,   min = 0,  max = 1,   attr = "LobbyBlowerDiscount" },
	},
	Cooldowns = {
		Hand    = { enabled = false, attr = "HandCooldown" },
		Rake    = { enabled = false, attr = "RakeCooldown" },
		Molotov = { enabled = false, attr = "MolotovCooldown" },
	},
	AutoRake = { enabled = false, interval = 0.08 },
	OverrideEffects = {
		enabled = false,
		Hand_Dexterity  = 0,
		Hand_Hold       = 1,
		Hand_Grasp      = 6,
		Rake_Range      = 20,
		Rake_Radius     = 6,
		Rake_Stickiness = 160,
		Blower_Width    = 6,
		Blower_Power    = 2.5,
		Blower_Spread   = 0.2,
	},
	LevelOverride = { enabled = false, level = 5 },
}

-- ═══════════════════════════════════════════
-- CONNECTIONS
-- ═══════════════════════════════════════════
local watcherConns = {}
local originalFns = {}
local isHolding = false
local autoRakeConns = nil

local function ClearWatchers()
	for _, c in pairs(watcherConns) do pcall(function() c:Disconnect() end) end
	watcherConns = {}
end

-- ═══════════════════════════════════════════
-- APPLY FUNCTIONS
-- ═══════════════════════════════════════════
local function ApplyAll()
	for _, d in pairs(Config.Tools) do
		if d.enabled then
			LocalPlayer:SetAttribute(d.attr, true)
			LocalPlayer:SetAttribute(d.perm, true)
		end
	end
	local function ApplyGroup(group)
		for _, d in pairs(group) do
			if d.enabled and d.attr then
				LocalPlayer:SetAttribute(d.attr, d.value)
			end
		end
	end
	ApplyGroup(Config.Hand)
	ApplyGroup(Config.Rake)
	ApplyGroup(Config.LeafBlower)
	ApplyGroup(Config.Lobby)
	for _, d in pairs(Config.Cooldowns) do
		if d.enabled then LocalPlayer:SetAttribute(d.attr, false) end
	end
end

local function SetupWatchers()
	ClearWatchers()
	for _, d in pairs(Config.Tools) do
		if d.enabled then
			table.insert(watcherConns, LocalPlayer:GetAttributeChangedSignal(d.attr):Connect(function()
				if d.enabled and LocalPlayer:GetAttribute(d.attr) ~= true then
					LocalPlayer:SetAttribute(d.attr, true)
				end
			end))
			table.insert(watcherConns, LocalPlayer:GetAttributeChangedSignal(d.perm):Connect(function()
				if d.enabled and LocalPlayer:GetAttribute(d.perm) ~= true then
					LocalPlayer:SetAttribute(d.perm, true)
				end
			end))
		end
	end
	local function WatchGroup(group)
		for _, d in pairs(group) do
			if d.enabled and d.attr then
				table.insert(watcherConns, LocalPlayer:GetAttributeChangedSignal(d.attr):Connect(function()
					if d.enabled and LocalPlayer:GetAttribute(d.attr) ~= d.value then
						LocalPlayer:SetAttribute(d.attr, d.value)
					end
				end))
			end
		end
	end
	WatchGroup(Config.Hand)
	WatchGroup(Config.Rake)
	WatchGroup(Config.LeafBlower)
	WatchGroup(Config.Lobby)
	for _, d in pairs(Config.Cooldowns) do
		if d.enabled then
			table.insert(watcherConns, LocalPlayer:GetAttributeChangedSignal(d.attr):Connect(function()
				if d.enabled and LocalPlayer:GetAttribute(d.attr) == true then
					LocalPlayer:SetAttribute(d.attr, false)
				end
			end))
		end
	end
end

local function ApplyOverrides()
	if not modulesLoaded then return end
	if Config.LevelOverride.enabled and PlayerUpgradeConfig then
		if not originalFns.levelOf then originalFns.levelOf = PlayerUpgradeConfig.levelOf end
		PlayerUpgradeConfig.levelOf = function() return Config.LevelOverride.level end
	elseif originalFns.levelOf and PlayerUpgradeConfig then
		PlayerUpgradeConfig.levelOf = originalFns.levelOf
	end
	if Config.OverrideEffects.enabled and LeafSim then
		if not originalFns.upgEffect then originalFns.upgEffect = LeafSim.upgEffect end
		LeafSim.upgEffect = function(tool, upgrade)
			local c = Config.OverrideEffects
			if tool == "Hand" then
				if upgrade == "Dexterity" then return c.Hand_Dexterity end
				if upgrade == "Hold" then return c.Hand_Hold end
				if upgrade == "Grasp" then return c.Hand_Grasp end
			elseif tool == "Rake" then
				if upgrade == "Range" then return c.Rake_Range end
				if upgrade == "Radius" then return c.Rake_Radius end
				if upgrade == "Stickiness" then return c.Rake_Stickiness end
			elseif tool == "LeafBlower" then
				if upgrade == "Width" then return c.Blower_Width end
				if upgrade == "Power" then return c.Blower_Power end
				if upgrade == "Spread" then return c.Blower_Spread end
			end
			return originalFns.upgEffect(tool, upgrade)
		end
	elseif originalFns.upgEffect and LeafSim then
		LeafSim.upgEffect = originalFns.upgEffect
	end
end

-- Auto Rake
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.IgnoreWater = true

local function ComputeRakeAim()
	local cam = Workspace.CurrentCamera
	local char = LocalPlayer.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not cam or not hrp then return nil end
	rayParams.FilterDescendantsInstances = {char}
	local r = Workspace:Raycast(cam.CFrame.Position, cam.CFrame.LookVector * 50, rayParams)
	return r and r.Position or (hrp.Position + cam.CFrame.LookVector * 10)
end

local function DoRake()
	if not LeafSim then return end
	local aim = ComputeRakeAim()
	if aim then
		pcall(function() SoundController.play("RakeSFX") end)
		pcall(function() LeafSim.rake(aim) end)
	end
end

local function StopAutoRake()
	isHolding = false
	if autoRakeConns then
		for _, c in pairs(autoRakeConns) do pcall(function() c:Disconnect() end) end
		autoRakeConns = nil
	end
end

local function StartAutoRake()
	StopAutoRake()
	local c1 = UserInputService.InputBegan:Connect(function(inp, gp)
		if gp then return end
		if inp.UserInputType == Enum.UserInputType.MouseButton1
			or inp.UserInputType == Enum.UserInputType.Touch then
			isHolding = true
			if Config.AutoRake.enabled
				and (LocalPlayer:GetAttribute("SelectedTool") or "Hand") == "Rake" then
				DoRake()
				task.spawn(function()
					while isHolding and Config.AutoRake.enabled do
						if (LocalPlayer:GetAttribute("SelectedTool") or "Hand") == "Rake"
							and not LocalPlayer:GetAttribute("JournalOpen")
							and not LocalPlayer:GetAttribute("ToolShopFocus") then
							DoRake()
							task.wait(Config.AutoRake.interval)
						else break end
					end
				end)
			end
		end
	end)
	local c2 = UserInputService.InputEnded:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1
			or inp.UserInputType == Enum.UserInputType.Touch then
			isHolding = false
		end
	end)
	autoRakeConns = {c1, c2}
end

local function MasterApply()
	ApplyAll()
	SetupWatchers()
	ApplyOverrides()
	if Config.AutoRake.enabled then StartAutoRake() else StopAutoRake() end
end

-- ═══════════════════════════════════════════
-- HELPER
-- ═══════════════════════════════════════════
local function SafeTween(obj, info, goals)
	if not obj or not obj.Parent then return end
	pcall(function() TweenService:Create(obj, info, goals):Play() end)
end

-- ═══════════════════════════════════════════
-- GUI SETUP
-- ═══════════════════════════════════════════
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "LeafSimV2"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Coba CoreGui dulu, fallback ke PlayerGui
pcall(function() ScreenGui.Parent = game:GetService("CoreGui") end)
if not ScreenGui.Parent then
	ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

-- ═══════════════════════════════════════════
-- UKURAN RESPONSIVE
-- ═══════════════════════════════════════════
local vpX = Camera.ViewportSize.X
local vpY = Camera.ViewportSize.Y

local frameW, frameH
if IsMobile then
	frameW = math.min(vpX - 20, 300)
	frameH = math.min(vpY - 80, 420)
else
	frameW = 350
	frameH = 520
end

-- ═══════════════════════════════════════════
-- MAIN FRAME
-- ═══════════════════════════════════════════
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, frameW, 0, frameH)
MainFrame.Position = UDim2.new(0, 10, 0, 40)
MainFrame.BackgroundColor3 = Color3.fromRGB(12, 14, 22)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 12)

local MainStroke = Instance.new("UIStroke", MainFrame)
MainStroke.Color = Color3.fromRGB(80, 200, 120)
MainStroke.Thickness = 2

-- ═══════════════════════════════════════════
-- TITLE BAR
-- ═══════════════════════════════════════════
local titleH = IsMobile and 40 or 44
local TitleBar = Instance.new("Frame", MainFrame)
TitleBar.Size = UDim2.new(1, 0, 0, titleH)
TitleBar.BackgroundColor3 = Color3.fromRGB(18, 20, 32)
TitleBar.BorderSizePixel = 0
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 12)

local TitleFix = Instance.new("Frame", TitleBar)
TitleFix.Size = UDim2.new(1, 0, 0, 12)
TitleFix.Position = UDim2.new(0, 0, 1, -12)
TitleFix.BackgroundColor3 = Color3.fromRGB(18, 20, 32)
TitleFix.BorderSizePixel = 0

-- Title text
local TitleText = Instance.new("TextLabel", TitleBar)
TitleText.Size = UDim2.new(0.6, -10, 0, 18)
TitleText.Position = UDim2.new(0, 10, 0, 4)
TitleText.BackgroundTransparency = 1
TitleText.Text = "🍃 Leaf Config"
TitleText.TextSize = IsMobile and 12 or 14
TitleText.Font = Enum.Font.GothamBold
TitleText.TextColor3 = Color3.fromRGB(80, 220, 130)
TitleText.TextXAlignment = Enum.TextXAlignment.Left
TitleText.TextTruncate = Enum.TextTruncate.AtEnd

local SubTitle = Instance.new("TextLabel", TitleBar)
SubTitle.Size = UDim2.new(0.6, -10, 0, 12)
SubTitle.Position = UDim2.new(0, 10, 0, 22)
SubTitle.BackgroundTransparency = 1
SubTitle.Text = modulesLoaded and "✅ Ready" or "⚠️ No modules"
SubTitle.TextSize = 8
SubTitle.Font = Enum.Font.Gotham
SubTitle.TextColor3 = modulesLoaded
	and Color3.fromRGB(80, 200, 120)
	or Color3.fromRGB(255, 180, 60)
SubTitle.TextXAlignment = Enum.TextXAlignment.Left

-- Buttons (PASTI muat di layar)
local btnSz = IsMobile and 26 or 28
local btnGap = 4

local CloseBtn = Instance.new("TextButton", TitleBar)
CloseBtn.Size = UDim2.new(0, btnSz, 0, btnSz)
CloseBtn.Position = UDim2.new(1, -(btnSz + btnGap), 0, (titleH - btnSz) / 2)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseBtn.BorderSizePixel = 0
CloseBtn.Text = "X"
CloseBtn.TextSize = IsMobile and 10 or 12
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextColor3 = Color3.new(1, 1, 1)
CloseBtn.ZIndex = 5
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)

local MinBtn = Instance.new("TextButton", TitleBar)
MinBtn.Size = UDim2.new(0, btnSz, 0, btnSz)
MinBtn.Position = UDim2.new(1, -(btnSz * 2 + btnGap * 2), 0, (titleH - btnSz) / 2)
MinBtn.BackgroundColor3 = Color3.fromRGB(255, 175, 0)
MinBtn.BorderSizePixel = 0
MinBtn.Text = "-"
MinBtn.TextSize = IsMobile and 12 or 16
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextColor3 = Color3.new(1, 1, 1)
MinBtn.ZIndex = 5
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 6)

-- Separator
local Sep = Instance.new("Frame", MainFrame)
Sep.Size = UDim2.new(0.94, 0, 0, 1)
Sep.Position = UDim2.new(0.03, 0, 0, titleH)
Sep.BackgroundColor3 = Color3.fromRGB(80, 200, 120)
Sep.BackgroundTransparency = 0.5
Sep.BorderSizePixel = 0

-- ═══════════════════════════════════════════
-- TAB BAR
-- ═══════════════════════════════════════════
local tabH = IsMobile and 30 or 32
local tabTop = titleH + 3

local TabBar = Instance.new("ScrollingFrame", MainFrame)
TabBar.Size = UDim2.new(1, -8, 0, tabH)
TabBar.Position = UDim2.new(0, 4, 0, tabTop)
TabBar.BackgroundTransparency = 1
TabBar.BorderSizePixel = 0
TabBar.ScrollBarThickness = 0
TabBar.CanvasSize = UDim2.new(0, 0, 0, 0)
TabBar.AutomaticCanvasSize = Enum.AutomaticSize.X
TabBar.ScrollingDirection = Enum.ScrollingDirection.X
TabBar.ElasticBehavior = Enum.ElasticBehavior.Always

local TabLayout = Instance.new("UIListLayout", TabBar)
TabLayout.FillDirection = Enum.FillDirection.Horizontal
TabLayout.Padding = UDim.new(0, 3)
TabLayout.VerticalAlignment = Enum.VerticalAlignment.Center

local tabs = {}
local tabPages = {}
local activeTab = nil

local tabNames = {"Tools", "Upgrade", "Lobby", "Combat", "Effect"}
local tabIcons = {
	Tools   = "🔧",
	Upgrade = "⬆",
	Lobby   = "🏠",
	Combat  = "⚔",
	Effect  = "🔬",
}

for _, name in ipairs(tabNames) do
	local btn = Instance.new("TextButton", TabBar)
	local tabW = IsMobile and 58 or 64
	btn.Size = UDim2.new(0, tabW, 0, tabH - 4)
	btn.BackgroundColor3 = Color3.fromRGB(28, 30, 45)
	btn.BorderSizePixel = 0
	btn.Text = (tabIcons[name] or "") .. " " .. name
	btn.TextSize = IsMobile and 9 or 10
	btn.Font = Enum.Font.GothamBold
	btn.TextColor3 = Color3.fromRGB(120, 120, 150)
	btn.AutoButtonColor = false
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
	tabs[name] = btn
end

-- Content area
local contentTop = tabTop + tabH + 4

for _, name in ipairs(tabNames) do
	local page = Instance.new("ScrollingFrame", MainFrame)
	page.Name = "Page_" .. name
	page.Size = UDim2.new(1, -10, 1, -(contentTop + 4))
	page.Position = UDim2.new(0, 5, 0, contentTop)
	page.BackgroundTransparency = 1
	page.BorderSizePixel = 0
	page.ScrollBarThickness = IsMobile and 3 or 2
	page.ScrollBarImageColor3 = Color3.fromRGB(80, 200, 120)
	page.CanvasSize = UDim2.new(0, 0, 0, 0)
	page.AutomaticCanvasSize = Enum.AutomaticSize.Y
	page.ScrollingDirection = Enum.ScrollingDirection.Y
	page.ElasticBehavior = Enum.ElasticBehavior.Always
	page.Visible = false

	Instance.new("UIListLayout", page).Padding = UDim.new(0, 4)
	local pad = Instance.new("UIPadding", page)
	pad.PaddingTop = UDim.new(0, 2)
	pad.PaddingBottom = UDim.new(0, 12)

	tabPages[name] = page
end

local function SwitchTab(name)
	activeTab = name
	for tn, btn in pairs(tabs) do
		local a = (tn == name)
		SafeTween(btn, TweenInfo.new(0.15), {
			BackgroundColor3 = a and Color3.fromRGB(50, 140, 80) or Color3.fromRGB(28, 30, 45)
		})
		btn.TextColor3 = a and Color3.new(1, 1, 1) or Color3.fromRGB(120, 120, 150)
	end
	for pn, pg in pairs(tabPages) do pg.Visible = (pn == name) end
end

for _, name in ipairs(tabNames) do
	local n = name
	tabs[name].MouseButton1Click:Connect(function() SwitchTab(n) end)
	tabs[name].TouchTap:Connect(function() SwitchTab(n) end)
end

-- ═══════════════════════════════════════════
-- COMPONENT BUILDERS
-- ═══════════════════════════════════════════
local layoutOrders = {}
local function NextOrder(p)
	local k = p.Name
	layoutOrders[k] = (layoutOrders[k] or 0) + 1
	return layoutOrders[k]
end

local function MakeSection(page, text)
	local f = Instance.new("Frame", page)
	f.Size = UDim2.new(1, 0, 0, 18)
	f.BackgroundTransparency = 1
	f.LayoutOrder = NextOrder(page)

	local l = Instance.new("TextLabel", f)
	l.Size = UDim2.new(1, 0, 1, 0)
	l.BackgroundTransparency = 1
	l.Text = text
	l.TextSize = 9
	l.Font = Enum.Font.GothamBold
	l.TextColor3 = Color3.fromRGB(80, 200, 120)
	l.TextXAlignment = Enum.TextXAlignment.Left

	local line = Instance.new("Frame", f)
	line.Size = UDim2.new(1, 0, 0, 1)
	line.Position = UDim2.new(0, 0, 1, -1)
	line.BackgroundColor3 = Color3.fromRGB(40, 60, 50)
	line.BorderSizePixel = 0
end

local function MakeToggle(page, text, default, callback)
	local h = IsMobile and 34 or 32
	local f = Instance.new("Frame", page)
	f.Size = UDim2.new(1, 0, 0, h)
	f.BackgroundColor3 = Color3.fromRGB(22, 24, 36)
	f.BorderSizePixel = 0
	f.LayoutOrder = NextOrder(page)
	Instance.new("UICorner", f).CornerRadius = UDim.new(0, 6)

	local lbl = Instance.new("TextLabel", f)
	lbl.Size = UDim2.new(1, -60, 1, 0)
	lbl.Position = UDim2.new(0, 8, 0, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = text
	lbl.TextSize = IsMobile and 10 or 11
	lbl.Font = Enum.Font.GothamBold
	lbl.TextColor3 = Color3.new(1, 1, 1)
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.TextTruncate = Enum.TextTruncate.AtEnd

	local sw = IsMobile and 40 or 36
	local sh = IsMobile and 18 or 18
	local sbg = Instance.new("Frame", f)
	sbg.Size = UDim2.new(0, sw, 0, sh)
	sbg.Position = UDim2.new(1, -(sw + 6), 0.5, -sh / 2)
	sbg.BackgroundColor3 = default and Color3.fromRGB(50, 180, 90) or Color3.fromRGB(45, 45, 65)
	sbg.BorderSizePixel = 0
	Instance.new("UICorner", sbg).CornerRadius = UDim.new(1, 0)

	local ks = sh - 4
	local knob = Instance.new("Frame", sbg)
	knob.Size = UDim2.new(0, ks, 0, ks)
	knob.Position = default
		and UDim2.new(1, -(ks + 2), 0.5, -ks / 2)
		or UDim2.new(0, 2, 0.5, -ks / 2)
	knob.BackgroundColor3 = Color3.new(1, 1, 1)
	knob.BorderSizePixel = 0
	Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

	local toggled = default
	local btn = Instance.new("TextButton", f)
	btn.Size = UDim2.new(1, 0, 1, 0)
	btn.BackgroundTransparency = 1
	btn.Text = ""
	btn.ZIndex = 3

	local tw = TweenInfo.new(0.15)
	local function Do()
		toggled = not toggled
		SafeTween(sbg, tw, {BackgroundColor3 = toggled and Color3.fromRGB(50, 180, 90) or Color3.fromRGB(45, 45, 65)})
		SafeTween(knob, tw, {Position = toggled and UDim2.new(1, -(ks + 2), 0.5, -ks / 2) or UDim2.new(0, 2, 0.5, -ks / 2)})
		callback(toggled)
		MasterApply()
	end
	btn.MouseButton1Click:Connect(Do)
	btn.TouchTap:Connect(Do)
end

local function MakeToggleSlider(page, text, ref, onChange)
	local h = IsMobile and 58 or 54
	local f = Instance.new("Frame", page)
	f.Size = UDim2.new(1, 0, 0, h)
	f.BackgroundColor3 = Color3.fromRGB(22, 24, 36)
	f.BorderSizePixel = 0
	f.LayoutOrder = NextOrder(page)
	Instance.new("UICorner", f).CornerRadius = UDim.new(0, 6)

	-- Label
	local lbl = Instance.new("TextLabel", f)
	lbl.Size = UDim2.new(0.45, 0, 0, 18)
	lbl.Position = UDim2.new(0, 8, 0, 3)
	lbl.BackgroundTransparency = 1
	lbl.Text = text
	lbl.TextSize = IsMobile and 9 or 10
	lbl.Font = Enum.Font.GothamBold
	lbl.TextColor3 = Color3.new(1, 1, 1)
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.TextTruncate = Enum.TextTruncate.AtEnd

	-- Value
	local step = ref.step or 1
	local isDecimal = (step < 1)
	local valLbl = Instance.new("TextLabel", f)
	valLbl.Size = UDim2.new(0, 36, 0, 16)
	valLbl.Position = UDim2.new(0.46, 0, 0, 4)
	valLbl.BackgroundColor3 = Color3.fromRGB(35, 35, 55)
	valLbl.Text = isDecimal and string.format("%.1f", ref.value) or tostring(ref.value)
	valLbl.TextSize = 9
	valLbl.Font = Enum.Font.GothamBold
	valLbl.TextColor3 = Color3.fromRGB(80, 220, 130)
	Instance.new("UICorner", valLbl).CornerRadius = UDim.new(0, 4)

	-- Toggle
	local sw = IsMobile and 36 or 34
	local sh = IsMobile and 16 or 16
	local sbg = Instance.new("Frame", f)
	sbg.Size = UDim2.new(0, sw, 0, sh)
	sbg.Position = UDim2.new(1, -(sw + 6), 0, 4)
	sbg.BackgroundColor3 = ref.enabled and Color3.fromRGB(50, 180, 90) or Color3.fromRGB(45, 45, 65)
	sbg.BorderSizePixel = 0
	Instance.new("UICorner", sbg).CornerRadius = UDim.new(1, 0)

	local ks = sh - 4
	local knob = Instance.new("Frame", sbg)
	knob.Size = UDim2.new(0, ks, 0, ks)
	knob.Position = ref.enabled
		and UDim2.new(1, -(ks + 2), 0.5, -ks / 2)
		or UDim2.new(0, 2, 0.5, -ks / 2)
	knob.BackgroundColor3 = Color3.new(1, 1, 1)
	knob.BorderSizePixel = 0
	Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

	local togBtn = Instance.new("TextButton", f)
	togBtn.Size = UDim2.new(1, 0, 0, 22)
	togBtn.BackgroundTransparency = 1
	togBtn.Text = ""
	togBtn.ZIndex = 3

	local tw = TweenInfo.new(0.15)
	local function DoTog()
		ref.enabled = not ref.enabled
		SafeTween(sbg, tw, {BackgroundColor3 = ref.enabled and Color3.fromRGB(50, 180, 90) or Color3.fromRGB(45, 45, 65)})
		SafeTween(knob, tw, {Position = ref.enabled and UDim2.new(1, -(ks + 2), 0.5, -ks / 2) or UDim2.new(0, 2, 0.5, -ks / 2)})
		if onChange then onChange() end
		MasterApply()
	end
	togBtn.MouseButton1Click:Connect(DoTog)
	togBtn.TouchTap:Connect(DoTog)

	-- Slider track
	local trackH = IsMobile and 6 or 5
	local track = Instance.new("Frame", f)
	track.Size = UDim2.new(0.9, 0, 0, trackH)
	track.Position = UDim2.new(0.05, 0, 0, h - trackH - 8)
	track.BackgroundColor3 = Color3.fromRGB(32, 32, 50)
	track.BorderSizePixel = 0
	Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

	local minV = ref.min or 0
	local maxV = ref.max or 5
	local ratio = math.clamp((ref.value - minV) / (maxV - minV), 0, 1)

	local fill = Instance.new("Frame", track)
	fill.Size = UDim2.new(ratio, 0, 1, 0)
	fill.BackgroundColor3 = Color3.fromRGB(50, 180, 90)
	fill.BorderSizePixel = 0
	Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

	local kw = IsMobile and 16 or 12
	local kn = Instance.new("Frame", track)
	kn.Size = UDim2.new(0, kw, 0, kw)
	kn.Position = UDim2.new(ratio, -kw / 2, 0.5, -kw / 2)
	kn.BackgroundColor3 = Color3.new(1, 1, 1)
	kn.BorderSizePixel = 0
	kn.ZIndex = 2
	Instance.new("UICorner", kn).CornerRadius = UDim.new(1, 0)

	-- Hit area
	local tp = IsMobile and 20 or 14
	local hit = Instance.new("TextButton", track)
	hit.Size = UDim2.new(1, 0, 0, tp * 2)
	hit.Position = UDim2.new(0, 0, 0.5, -tp)
	hit.BackgroundTransparency = 1
	hit.Text = ""
	hit.ZIndex = 4

	local sliding = false
	local function Upd(xPos)
		local tP = track.AbsolutePosition.X
		local tS = track.AbsoluteSize.X
		if tS <= 0 then return end
		local r = math.clamp((xPos - tP) / tS, 0, 1)
		local rawV = minV + (maxV - minV) * r
		local v
		if isDecimal then
			v = math.floor(rawV / step + 0.5) * step
			v = math.clamp(v, minV, maxV)
			valLbl.Text = string.format("%.1f", v)
		else
			v = math.floor(rawV + 0.5)
			v = math.clamp(v, minV, maxV)
			valLbl.Text = tostring(v)
		end
		ref.value = v
		local dR = (v - minV) / (maxV - minV)
		fill.Size = UDim2.new(dR, 0, 1, 0)
		kn.Position = UDim2.new(dR, -kw / 2, 0.5, -kw / 2)
		if onChange then onChange() end
		if ref.enabled then MasterApply() end
	end

	hit.MouseButton1Down:Connect(function() sliding = true end)
	hit.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.Touch then sliding = true; Upd(i.Position.X) end
	end)
	hit.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then sliding = false end
	end)
	UserInputService.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then sliding = false end
	end)
	UserInputService.InputChanged:Connect(function(i)
		if not sliding then return end
		if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then Upd(i.Position.X) end
	end)
	UserInputService.TouchMoved:Connect(function(t) if sliding then Upd(t.Position.X) end end)
end

local function MakeButton(page, text, color, callback)
	local h = IsMobile and 34 or 32
	local btn = Instance.new("TextButton", page)
	btn.Size = UDim2.new(1, 0, 0, h)
	btn.BackgroundColor3 = color
	btn.BorderSizePixel = 0
	btn.Text = text
	btn.TextSize = IsMobile and 10 or 11
	btn.Font = Enum.Font.GothamBold
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.LayoutOrder = NextOrder(page)
	btn.AutoButtonColor = false
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

	local function Fire()
		SafeTween(btn, TweenInfo.new(0.08), {BackgroundColor3 = Color3.fromRGB(80, 220, 130)})
		task.wait(0.08)
		SafeTween(btn, TweenInfo.new(0.15), {BackgroundColor3 = color})
		callback()
	end
	btn.MouseButton1Click:Connect(Fire)
	btn.TouchTap:Connect(Fire)
end

local function MakeInfo(page, text, color)
	local l = Instance.new("TextLabel", page)
	l.Size = UDim2.new(1, 0, 0, 30)
	l.BackgroundColor3 = Color3.fromRGB(30, 25, 20)
	l.Text = text
	l.TextSize = 8
	l.Font = Enum.Font.Gotham
	l.TextColor3 = color or Color3.fromRGB(255, 180, 80)
	l.TextWrapped = true
	l.LayoutOrder = NextOrder(page)
	Instance.new("UICorner", l).CornerRadius = UDim.new(0, 4)
end

-- ═══════════════════════════════════════════
-- PAGE: TOOLS
-- ═══════════════════════════════════════════
local p = tabPages["Tools"]
MakeSection(p, "UNLOCK TOOLS")
for n, d in pairs(Config.Tools) do
	MakeToggle(p, "🔓 " .. n, d.enabled, function(v) d.enabled = v end)
end
MakeSection(p, "COOLDOWN BYPASS")
for n, d in pairs(Config.Cooldowns) do
	MakeToggle(p, "⏱ No " .. n .. " CD", d.enabled, function(v) d.enabled = v end)
end
MakeButton(p, "✅ Apply", Color3.fromRGB(40, 120, 70), MasterApply)

-- ═══════════════════════════════════════════
-- PAGE: UPGRADE
-- ═══════════════════════════════════════════
p = tabPages["Upgrade"]
MakeSection(p, "HAND")
for n, d in pairs(Config.Hand) do
	MakeToggleSlider(p, "✋ " .. n, d)
end
MakeSection(p, "RAKE")
for n, d in pairs(Config.Rake) do
	MakeToggleSlider(p, "🧹 " .. n, d)
end
MakeSection(p, "LEAF BLOWER")
for n, d in pairs(Config.LeafBlower) do
	MakeToggleSlider(p, "💨 " .. n, d)
end
MakeButton(p, "✅ Apply", Color3.fromRGB(40, 120, 70), MasterApply)

-- ═══════════════════════════════════════════
-- PAGE: LOBBY
-- ═══════════════════════════════════════════
p = tabPages["Lobby"]
MakeSection(p, "LOBBY STATS")
local lobbyIcons = {
	WalkSpeed = "🏃", BagBonus = "🎒",
	CashMult = "💰", GemsMult = "💎",
	RakeDiscount = "🏷", BlowerDiscount = "🏷",
}
for n, d in pairs(Config.Lobby) do
	MakeToggleSlider(p, (lobbyIcons[n] or "📊") .. " " .. n, d)
end
MakeButton(p, "✅ Apply", Color3.fromRGB(40, 120, 70), MasterApply)

-- ═══════════════════════════════════════════
-- PAGE: COMBAT
-- ═══════════════════════════════════════════
p = tabPages["Combat"]
MakeSection(p, "AUTO RAKE")
MakeToggle(p, "⚡ Auto Rake (Hold)", Config.AutoRake.enabled, function(v)
	Config.AutoRake.enabled = v
end)

-- Interval slider
do
	local ref = { enabled = true, value = Config.AutoRake.interval, min = 0.02, max = 0.5, step = 0.01 }
	MakeToggleSlider(p, "⏱ Interval (sec)", ref, function()
		Config.AutoRake.interval = ref.value
	end)
end

MakeInfo(p, "⚠ Lower = faster but higher kick risk. Safe: 0.08-0.15s")

-- ═══════════════════════════════════════════
-- PAGE: EFFECT OVERRIDES
-- ═══════════════════════════════════════════
p = tabPages["Effect"]
MakeSection(p, "FUNCTION OVERRIDE")
MakeToggle(p, "🔬 Override Effects", Config.OverrideEffects.enabled, function(v)
	Config.OverrideEffects.enabled = v
end)
MakeToggle(p, "📊 Override Level", Config.LevelOverride.enabled, function(v)
	Config.LevelOverride.enabled = v
end)

MakeSection(p, "HAND EFFECTS")
local handOv = {
	{k = "Hand_Dexterity", n = "Dexterity", mn = 0, mx = 5, s = 0.1},
	{k = "Hand_Hold",      n = "Hold",      mn = 1, mx = 10},
	{k = "Hand_Grasp",     n = "Grasp",     mn = 1, mx = 20},
}
for _, o in pairs(handOv) do
	local ref = { enabled = true, value = Config.OverrideEffects[o.k], min = o.mn, max = o.mx, step = o.s }
	MakeToggleSlider(p, "✋ " .. o.n, ref, function()
		Config.OverrideEffects[o.k] = ref.value
	end)
end

MakeSection(p, "RAKE EFFECTS")
local rakeOv = {
	{k = "Rake_Range",      n = "Range",      mn = 5,  mx = 50},
	{k = "Rake_Radius",     n = "Radius",     mn = 1,  mx = 20},
	{k = "Rake_Stickiness", n = "Stickiness", mn = 10, mx = 500, s = 10},
}
for _, o in pairs(rakeOv) do
	local ref = { enabled = true, value = Config.OverrideEffects[o.k], min = o.mn, max = o.mx, step = o.s }
	MakeToggleSlider(p, "🧹 " .. o.n, ref, function()
		Config.OverrideEffects[o.k] = ref.value
	end)
end

MakeSection(p, "BLOWER EFFECTS")
local blowOv = {
	{k = "Blower_Width",  n = "Width",  mn = 1,   mx = 20},
	{k = "Blower_Power",  n = "Power",  mn = 0.5, mx = 10, s = 0.1},
	{k = "Blower_Spread", n = "Spread", mn = 0.1, mx = 2,  s = 0.1},
}
for _, o in pairs(blowOv) do
	local ref = { enabled = true, value = Config.OverrideEffects[o.k], min = o.mn, max = o.mx, step = o.s }
	MakeToggleSlider(p, "💨 " .. o.n, ref, function()
		Config.OverrideEffects[o.k] = ref.value
	end)
end

MakeSection(p, "LEVEL")
do
	local ref = { enabled = Config.LevelOverride.enabled, value = Config.LevelOverride.level, min = 1, max = 10 }
	MakeToggleSlider(p, "📊 Level Value", ref, function()
		Config.LevelOverride.level = ref.value
	end)
end

MakeButton(p, "✅ Apply All", Color3.fromRGB(40, 120, 70), MasterApply)
MakeInfo(p, "⚠ Override values terlalu tinggi bisa kick/ban", Color3.fromRGB(255, 100, 100))

-- ═══════════════════════════════════════════
-- DEFAULT TAB
-- ═══════════════════════════════════════════
SwitchTab("Tools")

-- ═══════════════════════════════════════════
-- DRAGGABLE (FIXED untuk mobile)
-- ═══════════════════════════════════════════
do
	local dragging = false
	local dragStart = nil
	local frameStart = nil

	TitleBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = Vector2.new(input.Position.X, input.Position.Y)
			frameStart = Vector2.new(MainFrame.Position.X.Offset, MainFrame.Position.Y.Offset)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if not dragging then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch then
			local delta = Vector2.new(input.Position.X, input.Position.Y) - dragStart
			local newX = math.clamp(frameStart.X + delta.X, 0, vpX - frameW)
			local newY = math.clamp(frameStart.Y + delta.Y, 0, vpY - 50)
			MainFrame.Position = UDim2.new(0, newX, 0, newY)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
end

-- ═══════════════════════════════════════════
-- MINIMIZE / RESTORE
-- ═══════════════════════════════════════════
local MiniIcon = Instance.new("TextButton", ScreenGui)
MiniIcon.Size = UDim2.new(0, 44, 0, 44)
MiniIcon.Position = UDim2.new(0, 10, 0, 40)
MiniIcon.BackgroundColor3 = Color3.fromRGB(18, 20, 32)
MiniIcon.BorderSizePixel = 0
MiniIcon.Text = "🍃"
MiniIcon.TextSize = 20
MiniIcon.Visible = false
MiniIcon.ZIndex = 10
Instance.new("UICorner", MiniIcon).CornerRadius = UDim.new(0, 12)
Instance.new("UIStroke", MiniIcon).Color = Color3.fromRGB(80, 200, 120)

local function DoMin()
	SafeTween(MainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
		Size = UDim2.new(0, 0, 0, 0)
	})
	task.wait(0.25)
	MainFrame.Visible = false
	MiniIcon.Visible = true
	MiniIcon.Position = MainFrame.Position
	MiniIcon.Size = UDim2.new(0, 0, 0, 0)
	SafeTween(MiniIcon, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 44, 0, 44)
	})
end
MinBtn.MouseButton1Click:Connect(DoMin)
MinBtn.TouchTap:Connect(DoMin)

local lastTap = 0
local function DoRestore()
	if tick() - lastTap < 0.4 then return end
	lastTap = tick()
	local restorePos = MiniIcon.Position
	SafeTween(MiniIcon, TweenInfo.new(0.15), {Size = UDim2.new(0, 0, 0, 0)})
	task.wait(0.15)
	MiniIcon.Visible = false
	MainFrame.Visible = true
	MainFrame.Position = restorePos
	MainFrame.Size = UDim2.new(0, 0, 0, 0)
	SafeTween(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, frameW, 0, frameH)
	})
end
MiniIcon.MouseButton1Click:Connect(DoRestore)
MiniIcon.TouchTap:Connect(DoRestore)

-- Mini icon juga draggable
do
	local md, ms, fs = false, nil, nil
	MiniIcon.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.Touch
			or i.UserInputType == Enum.UserInputType.MouseButton1 then
			md = true
			ms = Vector2.new(i.Position.X, i.Position.Y)
			fs = Vector2.new(MiniIcon.Position.X.Offset, MiniIcon.Position.Y.Offset)
		end
	end)
	UserInputService.InputChanged:Connect(function(i)
		if not md then return end
		if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseMovement then
			local d = Vector2.new(i.Position.X, i.Position.Y) - ms
			if d.Magnitude > 5 then -- Hanya geser kalau jarak cukup
				MiniIcon.Position = UDim2.new(0,
					math.clamp(fs.X + d.X, 0, vpX - 44), 0,
					math.clamp(fs.Y + d.Y, 0, vpY - 44))
			end
		end
	end)
	UserInputService.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
			md = false
		end
	end)
end

-- ═══════════════════════════════════════════
-- CLOSE
-- ═══════════════════════════════════════════
local function DoClose()
	ClearWatchers()
	StopAutoRake()
	if originalFns.levelOf and PlayerUpgradeConfig then
		PlayerUpgradeConfig.levelOf = originalFns.levelOf
	end
	if originalFns.upgEffect and LeafSim then
		LeafSim.upgEffect = originalFns.upgEffect
	end
	pcall(function() ScreenGui:Destroy() end)
end
CloseBtn.MouseButton1Click:Connect(DoClose)
CloseBtn.TouchTap:Connect(DoClose)

-- ═══════════════════════════════════════════
-- OPEN ANIMATION
-- ═══════════════════════════════════════════
MainFrame.Size = UDim2.new(0, 0, 0, 0)
task.wait(0.1)
SafeTween(MainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
	Size = UDim2.new(0, frameW, 0, frameH)
})

print("==========================================")
print("  🍃 Leaf Sim Config V2 - Loaded")
print("  Screen: " .. vpX .. "x" .. vpY)
print("  Frame:  " .. frameW .. "x" .. frameH)
print("  Mobile: " .. tostring(IsMobile))
print("  Module: " .. (modulesLoaded and "OK" or "Not Found"))
print("==========================================")
