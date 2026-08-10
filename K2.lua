-- // Solara Hub V5 - MOBILE FIXED + COMPACT ALERT
-- // Full Bright + Unlimited Zoom + HP Regen + Fly + ESP + Unlimited Jump
-- // FIXED: Compact Danger Alert, Mobile Support, Performance

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ═══════════════════════════════════════════
-- PLATFORM DETECTION
-- ═══════════════════════════════════════════
local IsMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local IsPC = UserInputService.KeyboardEnabled

-- ═══════════════════════════════════════════
-- CONNECTION MANAGER
-- ═══════════════════════════════════════════
local ConnectionManager = {}
ConnectionManager.__index = ConnectionManager

function ConnectionManager.new()
	return setmetatable({_connections = {}}, ConnectionManager)
end

function ConnectionManager:Add(name, connection)
	self:Remove(name)
	self._connections[name] = connection
end

function ConnectionManager:Remove(name)
	if self._connections[name] then
		pcall(function() self._connections[name]:Disconnect() end)
		self._connections[name] = nil
	end
end

function ConnectionManager:RemoveAll()
	for _, conn in pairs(self._connections) do
		pcall(function() conn:Disconnect() end)
	end
	self._connections = {}
end

local connections = ConnectionManager.new()

-- ═══════════════════════════════════════════
-- CLEANUP OLD GUI
-- ═══════════════════════════════════════════
pcall(function() game:GetService("CoreGui"):FindFirstChild("SolaraHubV5"):Destroy() end)
pcall(function() game:GetService("CoreGui"):FindFirstChild("SolaraESPv5"):Destroy() end)
pcall(function() workspace:FindFirstChild("SolaraESPParts"):Destroy() end)

-- ═══════════════════════════════════════════
-- VARIABLES
-- ═══════════════════════════════════════════
local Flying = false
local FlyToggleState = false
local FlySpeed = 50
local FlyBodyGyro = nil
local FlyBodyVelocity = nil
local MobileFlyDir = Vector3.new(0, 0, 0)

local ESPEnabled = false
local ESPUpdateConn = nil
local UnlimitedJumpEnabled = false
local JumpConnection = nil

local espUpdateTimer = 0
local radarUpdateTimer = 0
local dangerUpdateTimer = 0

local ESPWorkspaceFolder = Instance.new("Folder")
ESPWorkspaceFolder.Name = "SolaraESPParts"
ESPWorkspaceFolder.Parent = workspace

local originalValues = {
	Brightness     = Lighting.Brightness,
	ClockTime      = Lighting.ClockTime,
	FogEnd         = Lighting.FogEnd,
	FogStart       = Lighting.FogStart,
	GlobalShadows  = Lighting.GlobalShadows,
	OutdoorAmbient = Lighting.OutdoorAmbient,
	MaxZoom        = LocalPlayer.CameraMaxZoomDistance,
	MinZoom        = LocalPlayer.CameraMinZoomDistance,
}

local RemovedEffects = {}

-- ═══════════════════════════════════════════
-- ESP SETTINGS
-- ═══════════════════════════════════════════
local ESPSettings = {
	MaxDistance  = 1500,
	ShowBox      = true,
	ShowName     = true,
	ShowHealth   = true,
	ShowDistance = true,
	ShowTracer   = false,
}

-- ═══════════════════════════════════════════
-- HELPER FUNCTIONS
-- ═══════════════════════════════════════════
local function GetDistanceColor(distance)
	if distance <= 200 then
		return Color3.fromRGB(255, 50, 50)
	elseif distance <= 300 then
		return Color3.fromRGB(255, 220, 0)
	elseif distance <= 600 then
		return Color3.fromRGB(50, 255, 80)
	else
		return Color3.fromRGB(60, 160, 255)
	end
end

local function GetDistanceLabel(distance)
	if distance <= 200 then
		return "!"
	elseif distance <= 300 then
		return "~"
	elseif distance <= 600 then
		return "-"
	else
		return "."
	end
end

local function GetHealthColor(percent)
	local r = math.floor(255 * (1 - percent))
	local g = math.floor(255 * percent)
	return Color3.fromRGB(r, g, 0)
end

local function SafeTween(obj, info, goals)
	if not obj or not obj.Parent then return end
	pcall(function()
		TweenService:Create(obj, info, goals):Play()
	end)
end

-- ═══════════════════════════════════════════
-- SCREEN GUI
-- ═══════════════════════════════════════════
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SolaraHubV5"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = game:GetService("CoreGui")

local ESPGui = Instance.new("ScreenGui")
ESPGui.Name = "SolaraESPv5"
ESPGui.ResetOnSpawn = false
ESPGui.IgnoreGuiInset = true
ESPGui.Parent = game:GetService("CoreGui")

-- ═══════════════════════════════════════════
-- MOBILE FLY JOYSTICK
-- ═══════════════════════════════════════════
local FlyJoystickFrame = Instance.new("Frame")
FlyJoystickFrame.Name = "FlyJoystick"
FlyJoystickFrame.Size = UDim2.new(0, 140, 0, 140)
FlyJoystickFrame.Position = UDim2.new(0, 20, 1, -180)
FlyJoystickFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
FlyJoystickFrame.BackgroundTransparency = 0.3
FlyJoystickFrame.BorderSizePixel = 0
FlyJoystickFrame.Visible = false
FlyJoystickFrame.Parent = ScreenGui
Instance.new("UICorner", FlyJoystickFrame).CornerRadius = UDim.new(1, 0)

local JoyStroke = Instance.new("UIStroke")
JoyStroke.Color = Color3.fromRGB(130, 100, 255)
JoyStroke.Thickness = 2
JoyStroke.Parent = FlyJoystickFrame

local JoyCenter = Instance.new("Frame")
JoyCenter.Size = UDim2.new(0, 50, 0, 50)
JoyCenter.Position = UDim2.new(0.5, -25, 0.5, -25)
JoyCenter.BackgroundColor3 = Color3.fromRGB(130, 100, 255)
JoyCenter.BackgroundTransparency = 0.3
JoyCenter.BorderSizePixel = 0
JoyCenter.Parent = FlyJoystickFrame
Instance.new("UICorner", JoyCenter).CornerRadius = UDim.new(1, 0)

local JoyKnob = Instance.new("Frame")
JoyKnob.Size = UDim2.new(0, 40, 0, 40)
JoyKnob.Position = UDim2.new(0.5, -20, 0.5, -20)
JoyKnob.BackgroundColor3 = Color3.fromRGB(160, 130, 255)
JoyKnob.BorderSizePixel = 0
JoyKnob.ZIndex = 2
JoyKnob.Parent = FlyJoystickFrame
Instance.new("UICorner", JoyKnob).CornerRadius = UDim.new(1, 0)

local FlyUpBtn = Instance.new("TextButton")
FlyUpBtn.Size = UDim2.new(0, 60, 0, 50)
FlyUpBtn.Position = UDim2.new(0, 170, 1, -130)
FlyUpBtn.BackgroundColor3 = Color3.fromRGB(80, 60, 180)
FlyUpBtn.BackgroundTransparency = 0.3
FlyUpBtn.BorderSizePixel = 0
FlyUpBtn.Text = "UP"
FlyUpBtn.TextSize = 16
FlyUpBtn.Font = Enum.Font.GothamBold
FlyUpBtn.TextColor3 = Color3.new(1, 1, 1)
FlyUpBtn.Visible = false
FlyUpBtn.Parent = ScreenGui
Instance.new("UICorner", FlyUpBtn).CornerRadius = UDim.new(0, 10)

local FlyDownBtn = Instance.new("TextButton")
FlyDownBtn.Size = UDim2.new(0, 60, 0, 50)
FlyDownBtn.Position = UDim2.new(0, 170, 1, -75)
FlyDownBtn.BackgroundColor3 = Color3.fromRGB(80, 60, 180)
FlyDownBtn.BackgroundTransparency = 0.3
FlyDownBtn.BorderSizePixel = 0
FlyDownBtn.Text = "DN"
FlyDownBtn.TextSize = 16
FlyDownBtn.Font = Enum.Font.GothamBold
FlyDownBtn.TextColor3 = Color3.new(1, 1, 1)
FlyDownBtn.Visible = false
FlyDownBtn.Parent = ScreenGui
Instance.new("UICorner", FlyDownBtn).CornerRadius = UDim.new(0, 10)

local MobileJumpBtn = Instance.new("TextButton")
MobileJumpBtn.Size = UDim2.new(0, 70, 0, 70)
MobileJumpBtn.Position = UDim2.new(1, -90, 1, -150)
MobileJumpBtn.BackgroundColor3 = Color3.fromRGB(80, 200, 120)
MobileJumpBtn.BackgroundTransparency = 0.3
MobileJumpBtn.BorderSizePixel = 0
MobileJumpBtn.Text = "JUMP"
MobileJumpBtn.TextSize = 13
MobileJumpBtn.Font = Enum.Font.GothamBold
MobileJumpBtn.TextColor3 = Color3.new(1, 1, 1)
MobileJumpBtn.Visible = false
MobileJumpBtn.Parent = ScreenGui
Instance.new("UICorner", MobileJumpBtn).CornerRadius = UDim.new(1, 0)

-- Joystick logic
local joystickActive = false
local joystickTouchId = nil
local joystickCenter = Vector2.new()
local joystickRadius = 50

FlyJoystickFrame.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch then
		joystickActive = true
		joystickTouchId = input
		joystickCenter = Vector2.new(
			FlyJoystickFrame.AbsolutePosition.X + FlyJoystickFrame.AbsoluteSize.X / 2,
			FlyJoystickFrame.AbsolutePosition.Y + FlyJoystickFrame.AbsoluteSize.Y / 2
		)
	end
end)

FlyJoystickFrame.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch then
		joystickActive = false
		joystickTouchId = nil
		JoyKnob.Position = UDim2.new(0.5, -20, 0.5, -20)
		MobileFlyDir = Vector3.new(0, MobileFlyDir.Y, 0)
	end
end)

UserInputService.TouchMoved:Connect(function(touch, processed)
	if not joystickActive then return end
	if joystickTouchId then
		local touchPos = Vector2.new(touch.Position.X, touch.Position.Y)
		local offset = touchPos - joystickCenter
		local dist = offset.Magnitude
		local clamped = offset / math.max(dist, 1) * math.min(dist, joystickRadius)

		JoyKnob.Position = UDim2.new(0.5, clamped.X - 20, 0.5, clamped.Y - 20)
		local nx = clamped.X / joystickRadius
		local nz = clamped.Y / joystickRadius
		MobileFlyDir = Vector3.new(nx, MobileFlyDir.Y, nz)
	end
end)

local flyUpHeld = false
local flyDownHeld = false

FlyUpBtn.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
		flyUpHeld = true
	end
end)
FlyUpBtn.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
		flyUpHeld = false
	end
end)
FlyDownBtn.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
		flyDownHeld = true
	end
end)
FlyDownBtn.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
		flyDownHeld = false
	end
end)

MobileJumpBtn.MouseButton1Click:Connect(function()
	if not UnlimitedJumpEnabled then return end
	local char = LocalPlayer.Character
	if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
end)

-- ═══════════════════════════════════════════
-- MINI ICON
-- ═══════════════════════════════════════════
local MiniIcon = Instance.new("ImageButton")
MiniIcon.Size = UDim2.new(0, 60, 0, 60)
MiniIcon.Position = UDim2.new(0, 20, 0.5, -30)
MiniIcon.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
MiniIcon.BorderSizePixel = 0
MiniIcon.Image = "rbxassetid://7733960981"
MiniIcon.ImageColor3 = Color3.fromRGB(130, 100, 255)
MiniIcon.Visible = false
MiniIcon.AutoButtonColor = false
MiniIcon.ZIndex = 10
MiniIcon.Parent = ScreenGui
Instance.new("UICorner", MiniIcon).CornerRadius = UDim.new(0, 14)

local MiniStroke = Instance.new("UIStroke")
MiniStroke.Color = Color3.fromRGB(130, 100, 255)
MiniStroke.Thickness = 2
MiniStroke.Parent = MiniIcon

task.spawn(function()
	while ScreenGui.Parent do
		if MiniIcon.Visible then
			SafeTween(MiniStroke, TweenInfo.new(1, Enum.EasingStyle.Sine), {Color = Color3.fromRGB(200, 170, 255)})
			task.wait(1)
			if MiniIcon.Visible then
				SafeTween(MiniStroke, TweenInfo.new(1, Enum.EasingStyle.Sine), {Color = Color3.fromRGB(130, 100, 255)})
			end
		end
		task.wait(1)
	end
end)

-- ═══════════════════════════════════════════
-- MAIN FRAME
-- ═══════════════════════════════════════════
local screenX = Camera.ViewportSize.X
local screenY = Camera.ViewportSize.Y
local frameW = IsMobile and math.min(320, screenX - 20) or 340
local frameH = IsMobile and math.min(520, screenY - 60) or 580

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, frameW, 0, frameH)
MainFrame.Position = UDim2.new(0.5, -frameW/2, 0.5, -frameH/2)
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.ClipsDescendants = true
MainFrame.ZIndex = 5
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 14)

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(80, 60, 180)
MainStroke.Thickness = 2
MainStroke.Parent = MainFrame

local Shadow = Instance.new("ImageLabel")
Shadow.Size = UDim2.new(1, 40, 1, 40)
Shadow.Position = UDim2.new(0, -20, 0, -20)
Shadow.BackgroundTransparency = 1
Shadow.Image = "rbxassetid://5028857084"
Shadow.ImageColor3 = Color3.new(0, 0, 0)
Shadow.ImageTransparency = 0.5
Shadow.ScaleType = Enum.ScaleType.Slice
Shadow.SliceCenter = Rect.new(24, 24, 276, 276)
Shadow.ZIndex = -1
Shadow.Parent = MainFrame

-- ═══════════════════════════════════════════
-- TITLE BAR
-- ═══════════════════════════════════════════
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 50)
TitleBar.BackgroundColor3 = Color3.fromRGB(22, 22, 35)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 14)

local TitleFix = Instance.new("Frame")
TitleFix.Size = UDim2.new(1, 0, 0, 15)
TitleFix.Position = UDim2.new(0, 0, 1, -15)
TitleFix.BackgroundColor3 = Color3.fromRGB(22, 22, 35)
TitleFix.BorderSizePixel = 0
TitleFix.Parent = TitleBar

local TitleText = Instance.new("TextLabel")
TitleText.Size = UDim2.new(0.55, 0, 1, 0)
TitleText.Position = UDim2.new(0, 15, 0, 0)
TitleText.BackgroundTransparency = 1
TitleText.Text = "Solara Hub V5"
TitleText.TextSize = IsMobile and 14 or 16
TitleText.Font = Enum.Font.GothamBold
TitleText.TextColor3 = Color3.fromRGB(160, 130, 255)
TitleText.TextXAlignment = Enum.TextXAlignment.Left
TitleText.Parent = TitleBar

local Sep = Instance.new("Frame")
Sep.Size = UDim2.new(0.92, 0, 0, 1)
Sep.Position = UDim2.new(0.04, 0, 1, 0)
Sep.BackgroundColor3 = Color3.fromRGB(80, 60, 180)
Sep.BackgroundTransparency = 0.6
Sep.BorderSizePixel = 0
Sep.Parent = TitleBar

local PlatformLabel = Instance.new("TextLabel")
PlatformLabel.Size = UDim2.new(0, 70, 0, 16)
PlatformLabel.Position = UDim2.new(0, 15, 0, 30)
PlatformLabel.BackgroundTransparency = 1
PlatformLabel.Text = IsMobile and "Mobile" or "PC"
PlatformLabel.TextSize = 9
PlatformLabel.Font = Enum.Font.Gotham
PlatformLabel.TextColor3 = Color3.fromRGB(100, 100, 130)
PlatformLabel.TextXAlignment = Enum.TextXAlignment.Left
PlatformLabel.Parent = TitleBar

local btnSize = IsMobile and 36 or 30

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, btnSize, 0, btnSize)
CloseBtn.Position = UDim2.new(1, -(btnSize + 8), 0.5, -btnSize/2)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseBtn.BorderSizePixel = 0
CloseBtn.Text = "X"
CloseBtn.TextSize = IsMobile and 14 or 13
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextColor3 = Color3.new(1, 1, 1)
CloseBtn.AutoButtonColor = false
CloseBtn.Parent = TitleBar
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 8)

local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, btnSize, 0, btnSize)
MinBtn.Position = UDim2.new(1, -(btnSize*2 + 14), 0.5, -btnSize/2)
MinBtn.BackgroundColor3 = Color3.fromRGB(255, 175, 0)
MinBtn.BorderSizePixel = 0
MinBtn.Text = "-"
MinBtn.TextSize = IsMobile and 18 or 16
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextColor3 = Color3.new(1, 1, 1)
MinBtn.AutoButtonColor = false
MinBtn.Parent = TitleBar
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 8)

-- ═══════════════════════════════════════════
-- CONTENT SCROLL
-- ═══════════════════════════════════════════
local Content = Instance.new("ScrollingFrame")
Content.Size = UDim2.new(1, -16, 1, -58)
Content.Position = UDim2.new(0, 8, 0, 56)
Content.BackgroundTransparency = 1
Content.BorderSizePixel = 0
Content.ScrollBarThickness = IsMobile and 6 or 4
Content.ScrollBarImageColor3 = Color3.fromRGB(130, 100, 255)
Content.CanvasSize = UDim2.new(0, 0, 0, 0)
Content.AutomaticCanvasSize = Enum.AutomaticSize.Y
Content.ScrollingDirection = Enum.ScrollingDirection.Y
Content.ElasticBehavior = Enum.ElasticBehavior.Always
Content.Parent = MainFrame

local ListLayout = Instance.new("UIListLayout")
ListLayout.Padding = UDim.new(0, 8)
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
ListLayout.Parent = Content

local ContentPad = Instance.new("UIPadding")
ContentPad.PaddingBottom = UDim.new(0, 12)
ContentPad.PaddingLeft = UDim.new(0, 2)
ContentPad.PaddingRight = UDim.new(0, 2)
ContentPad.Parent = Content

-- ═══════════════════════════════════════════
-- STATUS BAR
-- ═══════════════════════════════════════════
local StatusFrame = Instance.new("Frame")
StatusFrame.Size = UDim2.new(1, 0, 0, 24)
StatusFrame.BackgroundTransparency = 1
StatusFrame.LayoutOrder = 0
StatusFrame.Parent = Content

local StatusText = Instance.new("TextLabel")
StatusText.Size = UDim2.new(1, 0, 1, 0)
StatusText.BackgroundTransparency = 1
StatusText.Text = "Status: Idle"
StatusText.TextSize = 11
StatusText.Font = Enum.Font.Gotham
StatusText.TextColor3 = Color3.fromRGB(100, 100, 130)
StatusText.Parent = StatusFrame

local function SetStatus(txt, col)
	StatusText.Text = txt
	StatusText.TextColor3 = col or Color3.fromRGB(100, 100, 130)
end

-- ═══════════════════════════════════════════
-- SECTION CREATOR
-- ═══════════════════════════════════════════
local function CreateSection(text, order)
	local F = Instance.new("Frame")
	F.Size = UDim2.new(1, 0, 0, 22)
	F.BackgroundTransparency = 1
	F.LayoutOrder = order
	F.Parent = Content

	local L1 = Instance.new("Frame", F)
	L1.Size = UDim2.new(0.15, 0, 0, 1)
	L1.Position = UDim2.new(0, 0, 0.5, 0)
	L1.BackgroundColor3 = Color3.fromRGB(80, 60, 180)
	L1.BackgroundTransparency = 0.5
	L1.BorderSizePixel = 0

	local SL = Instance.new("TextLabel", F)
	SL.Size = UDim2.new(0.7, 0, 1, 0)
	SL.Position = UDim2.new(0.15, 0, 0, 0)
	SL.BackgroundTransparency = 1
	SL.Text = text
	SL.TextSize = 10
	SL.Font = Enum.Font.GothamBold
	SL.TextColor3 = Color3.fromRGB(130, 100, 255)

	local L2 = Instance.new("Frame", F)
	L2.Size = UDim2.new(0.15, 0, 0, 1)
	L2.Position = UDim2.new(0.85, 0, 0.5, 0)
	L2.BackgroundColor3 = Color3.fromRGB(80, 60, 180)
	L2.BackgroundTransparency = 0.5
	L2.BorderSizePixel = 0
end

-- ═══════════════════════════════════════════
-- TOGGLE CREATOR (Mobile Fixed)
-- ═══════════════════════════════════════════
local function CreateToggle(title, desc, order, callback)
	local toggleH = IsMobile and 75 or 70

	local F = Instance.new("Frame")
	F.Size = UDim2.new(1, 0, 0, toggleH)
	F.BackgroundColor3 = Color3.fromRGB(28, 28, 42)
	F.BorderSizePixel = 0
	F.LayoutOrder = order
	F.Parent = Content
	Instance.new("UICorner", F).CornerRadius = UDim.new(0, 10)

	local FS = Instance.new("UIStroke", F)
	FS.Color = Color3.fromRGB(45, 45, 65)
	FS.Thickness = 1

	local TL = Instance.new("TextLabel", F)
	TL.Size = UDim2.new(0.6, 0, 0, 28)
	TL.Position = UDim2.new(0, 12, 0, 8)
	TL.BackgroundTransparency = 1
	TL.Text = title
	TL.TextSize = IsMobile and 13 or 14
	TL.Font = Enum.Font.GothamBold
	TL.TextColor3 = Color3.new(1, 1, 1)
	TL.TextXAlignment = Enum.TextXAlignment.Left
	TL.TextTruncate = Enum.TextTruncate.AtEnd

	local DL = Instance.new("TextLabel", F)
	DL.Size = UDim2.new(0.6, 0, 0, 22)
	DL.Position = UDim2.new(0, 12, 0, 34)
	DL.BackgroundTransparency = 1
	DL.Text = desc
	DL.TextSize = IsMobile and 10 or 11
	DL.Font = Enum.Font.Gotham
	DL.TextColor3 = Color3.fromRGB(140, 140, 160)
	DL.TextXAlignment = Enum.TextXAlignment.Left
	DL.TextTruncate = Enum.TextTruncate.AtEnd

	local switchW = IsMobile and 60 or 50
	local switchH = IsMobile and 30 or 26

	local SBG = Instance.new("Frame", F)
	SBG.Size = UDim2.new(0, switchW, 0, switchH)
	SBG.Position = UDim2.new(1, -(switchW + 12), 0.5, -switchH/2)
	SBG.BackgroundColor3 = Color3.fromRGB(55, 55, 75)
	SBG.BorderSizePixel = 0
	Instance.new("UICorner", SBG).CornerRadius = UDim.new(1, 0)

	local knobSize = switchH - 6
	local SC = Instance.new("Frame", SBG)
	SC.Size = UDim2.new(0, knobSize, 0, knobSize)
	SC.Position = UDim2.new(0, 3, 0.5, -knobSize/2)
	SC.BackgroundColor3 = Color3.fromRGB(180, 180, 190)
	SC.BorderSizePixel = 0
	Instance.new("UICorner", SC).CornerRadius = UDim.new(1, 0)

	local Btn = Instance.new("TextButton", F)
	Btn.Size = UDim2.new(1, 0, 1, 0)
	Btn.BackgroundTransparency = 1
	Btn.Text = ""
	Btn.ZIndex = 3

	local toggled = false
	local tweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quart)

	local function DoToggle()
		toggled = not toggled
		if toggled then
			SafeTween(SBG, tweenInfo, {BackgroundColor3 = Color3.fromRGB(80, 200, 120)})
			SafeTween(SC, tweenInfo, {
				Position = UDim2.new(1, -(knobSize + 3), 0.5, -knobSize/2),
				BackgroundColor3 = Color3.new(1, 1, 1)
			})
			SafeTween(FS, tweenInfo, {Color = Color3.fromRGB(80, 200, 120)})
		else
			SafeTween(SBG, tweenInfo, {BackgroundColor3 = Color3.fromRGB(55, 55, 75)})
			SafeTween(SC, tweenInfo, {
				Position = UDim2.new(0, 3, 0.5, -knobSize/2),
				BackgroundColor3 = Color3.fromRGB(180, 180, 190)
			})
			SafeTween(FS, tweenInfo, {Color = Color3.fromRGB(45, 45, 65)})
		end
		callback(toggled)
	end

	Btn.MouseButton1Click:Connect(DoToggle)
	Btn.TouchTap:Connect(function() DoToggle() end)
end

-- ═══════════════════════════════════════════
-- SLIDER CREATOR (Mobile Fixed)
-- ═══════════════════════════════════════════
local function CreateSlider(title, min, max, default, order, callback)
	local sliderH = IsMobile and 80 or 70

	local F = Instance.new("Frame")
	F.Size = UDim2.new(1, 0, 0, sliderH)
	F.BackgroundColor3 = Color3.fromRGB(28, 28, 42)
	F.BorderSizePixel = 0
	F.LayoutOrder = order
	F.Parent = Content
	Instance.new("UICorner", F).CornerRadius = UDim.new(0, 10)
	Instance.new("UIStroke", F).Color = Color3.fromRGB(45, 45, 65)

	local ST = Instance.new("TextLabel", F)
	ST.Size = UDim2.new(0.65, 0, 0, 26)
	ST.Position = UDim2.new(0, 12, 0, 6)
	ST.BackgroundTransparency = 1
	ST.Text = title
	ST.TextSize = IsMobile and 12 or 13
	ST.Font = Enum.Font.GothamBold
	ST.TextColor3 = Color3.new(1, 1, 1)
	ST.TextXAlignment = Enum.TextXAlignment.Left
	ST.TextTruncate = Enum.TextTruncate.AtEnd

	local VL = Instance.new("TextLabel", F)
	VL.Size = UDim2.new(0.3, 0, 0, 26)
	VL.Position = UDim2.new(0.68, 0, 0, 6)
	VL.BackgroundTransparency = 1
	VL.Text = tostring(default)
	VL.TextSize = 14
	VL.Font = Enum.Font.GothamBold
	VL.TextColor3 = Color3.fromRGB(130, 100, 255)
	VL.TextXAlignment = Enum.TextXAlignment.Right

	local trackH = IsMobile and 10 or 8
	local SBG = Instance.new("Frame", F)
	SBG.Size = UDim2.new(0.88, 0, 0, trackH)
	SBG.Position = UDim2.new(0.06, 0, 0, IsMobile and 48 or 44)
	SBG.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
	SBG.BorderSizePixel = 0
	Instance.new("UICorner", SBG).CornerRadius = UDim.new(1, 0)

	local ratio = (default - min) / (max - min)

	local SF = Instance.new("Frame", SBG)
	SF.Size = UDim2.new(ratio, 0, 1, 0)
	SF.BackgroundColor3 = Color3.fromRGB(130, 100, 255)
	SF.BorderSizePixel = 0
	Instance.new("UICorner", SF).CornerRadius = UDim.new(1, 0)

	local knobW = IsMobile and 22 or 18
	local SCi = Instance.new("Frame", SBG)
	SCi.Size = UDim2.new(0, knobW, 0, knobW)
	SCi.Position = UDim2.new(ratio, -knobW/2, 0.5, -knobW/2)
	SCi.BackgroundColor3 = Color3.new(1, 1, 1)
	SCi.BorderSizePixel = 0
	SCi.ZIndex = 2
	Instance.new("UICorner", SCi).CornerRadius = UDim.new(1, 0)

	local touchPad = IsMobile and 30 or 20
	local SBtn = Instance.new("TextButton", SBG)
	SBtn.Size = UDim2.new(1, 0, 0, touchPad * 2)
	SBtn.Position = UDim2.new(0, 0, 0.5, -touchPad)
	SBtn.BackgroundTransparency = 1
	SBtn.Text = ""
	SBtn.ZIndex = 3

	local sliding = false
	local currentValue = default

	local function UpdateSlider(xPos)
		local sbgPos = SBG.AbsolutePosition.X
		local sbgSize = SBG.AbsoluteSize.X
		if sbgSize <= 0 then return end
		local r = math.clamp((xPos - sbgPos) / sbgSize, 0, 1)
		local value = math.floor(min + (max - min) * r)
		if value == currentValue then return end
		currentValue = value
		SF.Size = UDim2.new(r, 0, 1, 0)
		SCi.Position = UDim2.new(r, -knobW/2, 0.5, -knobW/2)
		VL.Text = tostring(value)
		callback(value)
	end

	SBtn.MouseButton1Down:Connect(function() sliding = true end)
	SBtn.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch then
			sliding = true
			UpdateSlider(input.Position.X)
		end
	end)
	SBtn.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			sliding = false
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			sliding = false
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if not sliding then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			UpdateSlider(input.Position.X)
		end
	end)
	UserInputService.TouchMoved:Connect(function(touch, gp)
		if not sliding then return end
		UpdateSlider(touch.Position.X)
	end)
end

-- ═══════════════════════════════════════════
-- ESP SYSTEM
-- ═══════════════════════════════════════════
local espBillboards = {}

local function RemovePlayerESP(player)
	if not espBillboards[player] then return end
	local ep = espBillboards[player]
	if ep.CharConn then pcall(function() ep.CharConn:Disconnect() end) end
	local skip = {CharConn = true}
	for k, obj in pairs(ep) do
		if not skip[k] then pcall(function() obj:Destroy() end) end
	end
	espBillboards[player] = nil
end

local function CreatePlayerESP(player)
	if player == LocalPlayer then return end
	RemovePlayerESP(player)

	local function Setup(character)
		if not character then return end
		local ok, err = pcall(function()
			local hrp  = character:WaitForChild("HumanoidRootPart", 5)
			local head = character:WaitForChild("Head", 5)
			local hum  = character:WaitForChild("Humanoid", 5)
			if not hrp or not head or not hum then return end

			if not espBillboards[player] then espBillboards[player] = {} end
			local ep = espBillboards[player]

			local hl = Instance.new("Highlight")
			hl.FillTransparency = 0.7
			hl.OutlineTransparency = 0.1
			hl.FillColor = Color3.fromRGB(255, 50, 50)
			hl.OutlineColor = Color3.fromRGB(255, 50, 50)
			hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
			hl.Adornee = character
			hl.Parent = ESPGui
			ep.Highlight = hl

			local bb = Instance.new("BillboardGui")
			bb.Adornee = head
			bb.Size = UDim2.new(0, 180, 0, 90)
			bb.StudsOffset = Vector3.new(0, 3, 0)
			bb.AlwaysOnTop = true
			bb.LightInfluence = 0
			bb.MaxDistance = ESPSettings.MaxDistance
			bb.Parent = ESPGui
			ep.Billboard = bb

			local nameLabel = Instance.new("TextLabel")
			nameLabel.Size = UDim2.new(1, 0, 0, 18)
			nameLabel.BackgroundTransparency = 1
			nameLabel.Text = player.Name
			nameLabel.TextSize = 13
			nameLabel.Font = Enum.Font.GothamBold
			nameLabel.TextColor3 = Color3.new(1, 1, 1)
			nameLabel.TextStrokeTransparency = 0.3
			nameLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
			nameLabel.Parent = bb
			ep.NameLabel = nameLabel

			local distLabel = Instance.new("TextLabel")
			distLabel.Size = UDim2.new(1, 0, 0, 14)
			distLabel.Position = UDim2.new(0, 0, 0, 18)
			distLabel.BackgroundTransparency = 1
			distLabel.Text = "[0m]"
			distLabel.TextSize = 11
			distLabel.Font = Enum.Font.GothamBold
			distLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
			distLabel.TextStrokeTransparency = 0.3
			distLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
			distLabel.Parent = bb
			ep.DistLabel = distLabel

			-- COMPACT: Hanya simbol kecil, bukan teks panjang
			local dangerLabel = Instance.new("TextLabel")
			dangerLabel.Size = UDim2.new(1, 0, 0, 12)
			dangerLabel.Position = UDim2.new(0, 0, 0, 32)
			dangerLabel.BackgroundTransparency = 1
			dangerLabel.Text = ""
			dangerLabel.TextSize = 10
			dangerLabel.Font = Enum.Font.GothamBold
			dangerLabel.TextStrokeTransparency = 0.3
			dangerLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
			dangerLabel.Parent = bb
			ep.DangerLabel = dangerLabel

			local hpBG = Instance.new("Frame")
			hpBG.Size = UDim2.new(0.8, 0, 0, 5)
			hpBG.Position = UDim2.new(0.1, 0, 0, 48)
			hpBG.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
			hpBG.BorderSizePixel = 0
			hpBG.Parent = bb
			Instance.new("UICorner", hpBG).CornerRadius = UDim.new(1, 0)
			ep.HpBG = hpBG

			local hpFill = Instance.new("Frame")
			hpFill.Size = UDim2.new(1, 0, 1, 0)
			hpFill.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
			hpFill.BorderSizePixel = 0
			hpFill.Parent = hpBG
			Instance.new("UICorner", hpFill).CornerRadius = UDim.new(1, 0)
			ep.HpFill = hpFill

			local hpText = Instance.new("TextLabel")
			hpText.Size = UDim2.new(1, 0, 0, 12)
			hpText.Position = UDim2.new(0, 0, 0, 55)
			hpText.BackgroundTransparency = 1
			hpText.TextSize = 9
			hpText.Font = Enum.Font.Gotham
			hpText.TextStrokeTransparency = 0.3
			hpText.TextStrokeColor3 = Color3.new(0, 0, 0)
			hpText.Parent = bb
			ep.HpText = hpText

			local selBox = Instance.new("SelectionBox")
			selBox.Adornee = character
			selBox.Color3 = Color3.fromRGB(255, 50, 50)
			selBox.LineThickness = 0.03
			selBox.SurfaceTransparency = 0.9
			selBox.SurfaceColor3 = Color3.fromRGB(255, 50, 50)
			selBox.Parent = ESPGui
			ep.SelectionBox = selBox

			local headAdorn = Instance.new("BillboardGui")
			headAdorn.Adornee = head
			headAdorn.Size = UDim2.new(1, 0, 1, 0)
			headAdorn.AlwaysOnTop = true
			headAdorn.LightInfluence = 0
			headAdorn.MaxDistance = ESPSettings.MaxDistance
			headAdorn.Parent = ESPGui
			ep.HeadAdorn = headAdorn

			local headCircle = Instance.new("Frame")
			headCircle.Size = UDim2.new(0.5, 0, 0.5, 0)
			headCircle.Position = UDim2.new(0.25, 0, 0.25, 0)
			headCircle.BackgroundColor3 = Color3.new(1, 1, 1)
			headCircle.BorderSizePixel = 0
			headCircle.Parent = headAdorn
			Instance.new("UICorner", headCircle).CornerRadius = UDim.new(1, 0)
			ep.HeadCircle = headCircle

			local att0 = Instance.new("Attachment")
			att0.Parent = hrp
			ep.TracerAtt0 = att0

			local tracerPart = Instance.new("Part")
			tracerPart.Anchored = true
			tracerPart.CanCollide = false
			tracerPart.Transparency = 1
			tracerPart.Size = Vector3.new(0.1, 0.1, 0.1)
			tracerPart.Parent = ESPWorkspaceFolder
			ep.TracerPart = tracerPart

			local att1 = Instance.new("Attachment")
			att1.Parent = tracerPart
			ep.TracerAtt1 = att1

			local beam = Instance.new("Beam")
			beam.Attachment0 = att1
			beam.Attachment1 = att0
			beam.Width0 = 0.1
			beam.Width1 = 0.1
			beam.FaceCamera = true
			beam.Transparency = NumberSequence.new(0.5)
			beam.LightEmission = 1
			beam.Enabled = ESPSettings.ShowTracer
			beam.Parent = hrp
			ep.Beam = beam
		end)
		if not ok then warn("[Solara ESP] " .. tostring(err)) end
	end

	if player.Character then Setup(player.Character) end

	local charConn = player.CharacterAdded:Connect(function(char)
		task.wait(1)
		if ESPEnabled then
			RemovePlayerESP(player)
			espBillboards[player] = {}
			Setup(char)
		end
	end)

	if not espBillboards[player] then espBillboards[player] = {} end
	espBillboards[player].CharConn = charConn
end

-- ═══════════════════════════════════════════
-- ESP UPDATE
-- ═══════════════════════════════════════════
local function UpdateAllESP()
	local lc = LocalPlayer.Character
	if not lc then return end
	local lh = lc:FindFirstChild("HumanoidRootPart")
	if not lh then return end

	for _, player in pairs(Players:GetPlayers()) do
		if player == LocalPlayer then continue end
		local ep = espBillboards[player]
		if not ep then continue end
		local char = player.Character
		if not char then continue end
		local hrp = char:FindFirstChild("HumanoidRootPart")
		local hum = char:FindFirstChildOfClass("Humanoid")
		if not hrp or not hum then continue end

		local dist   = (hrp.Position - lh.Position).Magnitude
		local dColor = GetDistanceColor(dist)
		local dLabel = GetDistanceLabel(dist)
		local hpPct  = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
		local hpCol  = GetHealthColor(hpPct)
		local alive  = hum.Health > 0

		if ep.Highlight then ep.Highlight.FillColor = dColor; ep.Highlight.OutlineColor = dColor; ep.Highlight.Enabled = alive end
		if ep.SelectionBox then ep.SelectionBox.Color3 = dColor; ep.SelectionBox.SurfaceColor3 = dColor; ep.SelectionBox.Visible = alive end
		if ep.NameLabel then ep.NameLabel.TextColor3 = dColor end
		if ep.DistLabel then ep.DistLabel.Text = math.floor(dist) .. "m"; ep.DistLabel.TextColor3 = dColor end
		if ep.DangerLabel then ep.DangerLabel.Text = dLabel; ep.DangerLabel.TextColor3 = dColor end
		if ep.HpFill then ep.HpFill.Size = UDim2.new(hpPct, 0, 1, 0); ep.HpFill.BackgroundColor3 = hpCol end
		if ep.HpText then ep.HpText.Text = math.floor(hum.Health) .. "/" .. math.floor(hum.MaxHealth); ep.HpText.TextColor3 = hpCol end
		if ep.HeadCircle then ep.HeadCircle.BackgroundColor3 = dColor end
		if ep.Billboard then ep.Billboard.Enabled = alive; ep.Billboard.MaxDistance = ESPSettings.MaxDistance end
		if ep.HeadAdorn then ep.HeadAdorn.Enabled = alive; ep.HeadAdorn.MaxDistance = ESPSettings.MaxDistance end
		if ep.Beam then ep.Beam.Enabled = ESPSettings.ShowTracer and alive; ep.Beam.Color = ColorSequence.new(dColor) end
		if ep.TracerPart then ep.TracerPart.CFrame = CFrame.new(lh.Position - Vector3.new(0, 3, 0)) end
	end
end

-- ═══════════════════════════════════════════
-- COMPACT DANGER ALERT (FIXED - Kecil, tidak menutupi)
-- ═══════════════════════════════════════════
local AlertFrame = Instance.new("Frame")
AlertFrame.Size = UDim2.new(0, IsMobile and 150 or 170, 0, 28)
AlertFrame.Position = UDim2.new(0.5, IsMobile and -75 or -85, 0, IsMobile and 50 or 10)
AlertFrame.BackgroundColor3 = Color3.fromRGB(180, 25, 25)
AlertFrame.BackgroundTransparency = 0.25
AlertFrame.BorderSizePixel = 0
AlertFrame.Visible = false
AlertFrame.ZIndex = 10
AlertFrame.Parent = ESPGui
Instance.new("UICorner", AlertFrame).CornerRadius = UDim.new(0, 8)

local AlertStroke = Instance.new("UIStroke")
AlertStroke.Color = Color3.fromRGB(255, 60, 60)
AlertStroke.Thickness = 1.5
AlertStroke.Parent = AlertFrame

-- Icon kecil di kiri
local AlertIcon = Instance.new("TextLabel")
AlertIcon.Size = UDim2.new(0, 22, 1, 0)
AlertIcon.Position = UDim2.new(0, 4, 0, 0)
AlertIcon.BackgroundTransparency = 1
AlertIcon.Text = "!"
AlertIcon.TextSize = 16
AlertIcon.Font = Enum.Font.GothamBold
AlertIcon.TextColor3 = Color3.fromRGB(255, 255, 80)
AlertIcon.Parent = AlertFrame

-- Info singkat: jumlah + jarak terdekat
local AlertInfo = Instance.new("TextLabel")
AlertInfo.Size = UDim2.new(1, -28, 1, 0)
AlertInfo.Position = UDim2.new(0, 26, 0, 0)
AlertInfo.BackgroundTransparency = 1
AlertInfo.Text = "1x 45m"
AlertInfo.TextSize = IsMobile and 11 or 12
AlertInfo.Font = Enum.Font.GothamBold
AlertInfo.TextColor3 = Color3.new(1, 1, 1)
AlertInfo.TextXAlignment = Enum.TextXAlignment.Left
AlertInfo.TextStrokeTransparency = 0.5
AlertInfo.TextStrokeColor3 = Color3.new(0, 0, 0)
AlertInfo.Parent = AlertFrame

local alertActive = false

-- Pulse animation kecil (hanya border, ringan)
task.spawn(function()
	while ESPGui.Parent do
		if alertActive and AlertFrame.Visible then
			SafeTween(AlertStroke, TweenInfo.new(0.5, Enum.EasingStyle.Sine), {Color = Color3.fromRGB(255, 200, 50)})
			task.wait(0.5)
			SafeTween(AlertStroke, TweenInfo.new(0.5, Enum.EasingStyle.Sine), {Color = Color3.fromRGB(255, 60, 60)})
			task.wait(0.5)
		else
			task.wait(0.5)
		end
	end
end)

local function CheckDangerAlert()
	local lc = LocalPlayer.Character
	if not lc then AlertFrame.Visible = false; alertActive = false; return end
	local lh = lc:FindFirstChild("HumanoidRootPart")
	if not lh then AlertFrame.Visible = false; alertActive = false; return end

	local closestDist = math.huge
	local dangerCount = 0

	for _, player in pairs(Players:GetPlayers()) do
		if player == LocalPlayer then continue end
		local char = player.Character
		if not char then continue end
		local hrp = char:FindFirstChild("HumanoidRootPart")
		local hum = char:FindFirstChildOfClass("Humanoid")
		if not hrp or not hum or hum.Health <= 0 then continue end

		local dist = (hrp.Position - lh.Position).Magnitude
		if dist <= 200 then
			dangerCount += 1
			if dist < closestDist then closestDist = dist end
		end
	end

	if dangerCount > 0 then
		alertActive = true
		AlertFrame.Visible = true
		-- Format: "2x 87m" artinya 2 player, terdekat 87 meter
		AlertInfo.Text = dangerCount .. "x " .. math.floor(closestDist) .. "m"
	else
		alertActive = false
		AlertFrame.Visible = false
	end
end

-- ═══════════════════════════════════════════
-- RADAR SYSTEM
-- ═══════════════════════════════════════════
local radarSize = IsMobile and 140 or 160

local RadarFrame = Instance.new("Frame")
RadarFrame.Size = UDim2.new(0, radarSize, 0, radarSize)
RadarFrame.Position = UDim2.new(1, -(radarSize + 15), 1, -(radarSize + 80))
RadarFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 20)
RadarFrame.BackgroundTransparency = 0.3
RadarFrame.BorderSizePixel = 0
RadarFrame.Visible = false
RadarFrame.Parent = ESPGui
Instance.new("UICorner", RadarFrame).CornerRadius = UDim.new(1, 0)

Instance.new("UIStroke", RadarFrame).Color = Color3.fromRGB(130, 100, 255)

local gH = Instance.new("Frame", RadarFrame)
gH.Size = UDim2.new(1, 0, 0, 1)
gH.Position = UDim2.new(0, 0, 0.5, 0)
gH.BackgroundColor3 = Color3.fromRGB(80, 60, 180)
gH.BackgroundTransparency = 0.7
gH.BorderSizePixel = 0

local gV = Instance.new("Frame", RadarFrame)
gV.Size = UDim2.new(0, 1, 1, 0)
gV.Position = UDim2.new(0.5, 0, 0, 0)
gV.BackgroundColor3 = Color3.fromRGB(80, 60, 180)
gV.BackgroundTransparency = 0.7
gV.BorderSizePixel = 0

local SelfDot = Instance.new("Frame", RadarFrame)
SelfDot.Size = UDim2.new(0, 8, 0, 8)
SelfDot.Position = UDim2.new(0.5, -4, 0.5, -4)
SelfDot.BackgroundColor3 = Color3.fromRGB(100, 200, 255)
SelfDot.BorderSizePixel = 0
Instance.new("UICorner", SelfDot).CornerRadius = UDim.new(1, 0)

Instance.new("TextLabel", RadarFrame).Size = UDim2.new(1, 0, 0, 14)
local rl = RadarFrame:FindFirstChildWhichIsA("TextLabel")
rl.Position = UDim2.new(0, 0, 0, 3)
rl.BackgroundTransparency = 1
rl.Text = "RADAR"
rl.TextSize = 9
rl.Font = Enum.Font.GothamBold
rl.TextColor3 = Color3.fromRGB(130, 100, 255)

local radarDotPool = {}

local function GetOrCreateRadarDot(index)
	if radarDotPool[index] then
		radarDotPool[index].Visible = true
		return radarDotPool[index]
	end
	local dot = Instance.new("Frame")
	dot.Size = UDim2.new(0, 7, 0, 7)
	dot.BorderSizePixel = 0
	dot.Parent = RadarFrame
	Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

	local nl = Instance.new("TextLabel", dot)
	nl.Name = "NameLabel"
	nl.Size = UDim2.new(0, 55, 0, 11)
	nl.Position = UDim2.new(0, 9, 0, -2)
	nl.BackgroundTransparency = 1
	nl.TextSize = 7
	nl.Font = Enum.Font.GothamBold
	nl.TextXAlignment = Enum.TextXAlignment.Left

	radarDotPool[index] = dot
	return dot
end

local function UpdateRadar()
	local lc = LocalPlayer.Character
	if not lc then return end
	local lh = lc:FindFirstChild("HumanoidRootPart")
	if not lh then return end

	local range = 400
	local idx = 0

	for _, player in pairs(Players:GetPlayers()) do
		if player == LocalPlayer then continue end
		local char = player.Character
		if not char then continue end
		local hrp = char:FindFirstChild("HumanoidRootPart")
		local hum = char:FindFirstChildOfClass("Humanoid")
		if not hrp or not hum or hum.Health <= 0 then continue end

		local dist = (hrp.Position - lh.Position).Magnitude
		if dist > range then continue end

		idx += 1
		local dot = GetOrCreateRadarDot(idx)
		local color = GetDistanceColor(dist)
		local rel = lh.CFrame:PointToObjectSpace(hrp.Position)
		local nx = math.clamp(rel.X / range, -1, 1)
		local nz = math.clamp(rel.Z / range, -1, 1)

		dot.Position = UDim2.new(0.5 + nx * 0.42, -3, 0.5 + nz * 0.42, -3)
		dot.BackgroundColor3 = color
		local nl = dot:FindFirstChild("NameLabel")
		if nl then nl.Text = player.Name; nl.TextColor3 = color end
	end

	for i = idx + 1, #radarDotPool do
		if radarDotPool[i] then radarDotPool[i].Visible = false end
	end
end

-- ═══════════════════════════════════════════
-- PLAYER EVENTS
-- ═══════════════════════════════════════════
Players.PlayerAdded:Connect(function(p)
	if ESPEnabled then task.wait(2); CreatePlayerESP(p) end
end)
Players.PlayerRemoving:Connect(function(p) RemovePlayerESP(p) end)

-- ═══════════════════════════════════════════
-- FEATURES
-- ═══════════════════════════════════════════
CreateSection("VISUAL", 1)

CreateToggle("Full Bright", "Semua area terang total", 2, function(state)
	if state then
		for _, v in pairs(Lighting:GetDescendants()) do
			if v:IsA("Atmosphere") or v:IsA("BloomEffect") or v:IsA("DepthOfFieldEffect")
				or v:IsA("ColorCorrectionEffect") or v:IsA("SunRaysEffect") then
				RemovedEffects[v] = v.Parent
				v.Parent = nil
			end
		end
		connections:Add("bright", RunService.RenderStepped:Connect(function()
			Lighting.ClockTime = 14; Lighting.Brightness = 2
			Lighting.FogEnd = 1e6; Lighting.FogStart = 0
			Lighting.GlobalShadows = false; Lighting.OutdoorAmbient = Color3.new(1,1,1)
		end))
		connections:Add("brightChild", Lighting.ChildAdded:Connect(function(c)
			if c:IsA("Atmosphere") or c:IsA("BloomEffect") or c:IsA("DepthOfFieldEffect") then task.wait(); c:Destroy() end
		end))
		SetStatus("Full Bright: ON", Color3.fromRGB(100, 255, 120))
	else
		connections:Remove("bright"); connections:Remove("brightChild")
		Lighting.Brightness = originalValues.Brightness
		Lighting.ClockTime = originalValues.ClockTime
		Lighting.FogEnd = originalValues.FogEnd
		Lighting.FogStart = originalValues.FogStart
		Lighting.GlobalShadows = originalValues.GlobalShadows
		Lighting.OutdoorAmbient = originalValues.OutdoorAmbient
		for inst, orig in pairs(RemovedEffects) do pcall(function() inst.Parent = orig end) end
		RemovedEffects = {}
		SetStatus("Full Bright: OFF", Color3.fromRGB(255, 100, 100))
	end
end)

CreateToggle("Unlimited Zoom", "Zoom kamera tanpa batas", 3, function(state)
	if state then
		connections:Add("zoom", RunService.RenderStepped:Connect(function()
			LocalPlayer.CameraMaxZoomDistance = 1e6
			LocalPlayer.CameraMinZoomDistance = 0.1
		end))
		SetStatus("Unlimited Zoom: ON", Color3.fromRGB(100, 255, 120))
	else
		connections:Remove("zoom")
		LocalPlayer.CameraMaxZoomDistance = originalValues.MaxZoom
		LocalPlayer.CameraMinZoomDistance = originalValues.MinZoom
		SetStatus("Unlimited Zoom: OFF", Color3.fromRGB(255, 100, 100))
	end
end)

CreateSection("COMBAT", 4)

CreateToggle("HP Regen (Client)", "Auto heal client side", 5, function(state)
	if state then
		connections:Add("regen", RunService.Heartbeat:Connect(function()
			local c = LocalPlayer.Character
			if not c then return end
			local h = c:FindFirstChildOfClass("Humanoid")
			if h and h.Health > 0 then h.Health = h.MaxHealth end
		end))
		connections:Add("regenChar", LocalPlayer.CharacterAdded:Connect(function(c)
			task.wait(0.5)
			local h = c:WaitForChild("Humanoid", 5)
			if h then h.Health = h.MaxHealth end
		end))
		SetStatus("HP Regen: ON", Color3.fromRGB(100, 255, 120))
	else
		connections:Remove("regen"); connections:Remove("regenChar")
		SetStatus("HP Regen: OFF", Color3.fromRGB(255, 100, 100))
	end
end)

CreateSection("MOVEMENT", 6)

-- FLY
local Ctrl = {f = 0, b = 0, l = 0, r = 0}
local LastCtrl = {f = 0, b = 0, l = 0, r = 0}

local function StartFly()
	local char = LocalPlayer.Character
	if not char then return end
	local torso = char:FindFirstChild("HumanoidRootPart")
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not torso or not hum then return end

	if FlyBodyGyro then pcall(function() FlyBodyGyro:Destroy() end) end
	if FlyBodyVelocity then pcall(function() FlyBodyVelocity:Destroy() end) end

	FlyBodyGyro = Instance.new("BodyGyro", torso)
	FlyBodyGyro.P = 9e4
	FlyBodyGyro.maxTorque = Vector3.new(9e9, 9e9, 9e9)
	FlyBodyGyro.cframe = torso.CFrame

	FlyBodyVelocity = Instance.new("BodyVelocity", torso)
	FlyBodyVelocity.velocity = Vector3.new(0, 0.1, 0)
	FlyBodyVelocity.maxForce = Vector3.new(9e9, 9e9, 9e9)

	task.spawn(function()
		while Flying and FlyBodyGyro and FlyBodyGyro.Parent do
			task.wait()
			if hum then hum.PlatformStand = true end

			local camCF = Camera.CFrame
			local vel = Vector3.new(0, 0.1, 0)

			if IsMobile then
				local yDir = 0
				if flyUpHeld then yDir = 1 end
				if flyDownHeld then yDir = -1 end
				MobileFlyDir = Vector3.new(MobileFlyDir.X, yDir, MobileFlyDir.Z)

				local jx, jz, jy = MobileFlyDir.X, MobileFlyDir.Z, MobileFlyDir.Y
				if math.abs(jx) > 0.05 or math.abs(jz) > 0.05 or jy ~= 0 then
					local fwd = camCF.LookVector
					local rgt = camCF.RightVector
					local flatFwd = Vector3.new(fwd.X, 0, fwd.Z).Unit
					local flatRgt = Vector3.new(rgt.X, 0, rgt.Z).Unit
					vel = (flatFwd * (-jz) + flatRgt * jx) * FlySpeed + Vector3.new(0, jy * FlySpeed * 0.6, 0)
				end
			else
				local moving = (Ctrl.l + Ctrl.r) ~= 0 or (Ctrl.f + Ctrl.b) ~= 0
				if moving then
					vel = (camCF.LookVector * (Ctrl.f + Ctrl.b) + camCF.RightVector * (Ctrl.l + Ctrl.r)) * FlySpeed
					LastCtrl = {f = Ctrl.f, b = Ctrl.b, l = Ctrl.l, r = Ctrl.r}
				end
			end

			if FlyBodyVelocity and FlyBodyVelocity.Parent then FlyBodyVelocity.velocity = vel end
			if FlyBodyGyro and FlyBodyGyro.Parent then FlyBodyGyro.cframe = camCF end
		end

		Ctrl = {f = 0, b = 0, l = 0, r = 0}
		LastCtrl = {f = 0, b = 0, l = 0, r = 0}
		MobileFlyDir = Vector3.new(0, 0, 0)
		if FlyBodyGyro then pcall(function() FlyBodyGyro:Destroy() end); FlyBodyGyro = nil end
		if FlyBodyVelocity then pcall(function() FlyBodyVelocity:Destroy() end); FlyBodyVelocity = nil end
		if hum then pcall(function() hum.PlatformStand = false end) end
	end)
end

CreateToggle("Fly", "Terbang bebas | Mobile: Joystick", 7, function(state)
	FlyToggleState = state; Flying = state
	if IsMobile then
		FlyJoystickFrame.Visible = state
		FlyUpBtn.Visible = state
		FlyDownBtn.Visible = state
	end
	if state then
		StartFly()
		SetStatus("Fly: ON | Spd:" .. FlySpeed, Color3.fromRGB(100, 255, 120))
	else
		MobileFlyDir = Vector3.new(0, 0, 0)
		JoyKnob.Position = UDim2.new(0.5, -20, 0.5, -20)
		SetStatus("Fly: OFF", Color3.fromRGB(255, 100, 100))
	end
end)

LocalPlayer.CharacterAdded:Connect(function()
	task.wait(1)
	if FlyToggleState then Flying = true; StartFly() end
end)

CreateSlider("Fly Speed", 10, 500, 50, 8, function(v)
	FlySpeed = v
	if FlyToggleState then SetStatus("Fly Spd:" .. v, Color3.fromRGB(100, 255, 120)) end
end)

CreateToggle("Unlimited Jump", "Lompat di udara | Mobile: JUMP btn", 9, function(state)
	UnlimitedJumpEnabled = state
	if IsMobile then MobileJumpBtn.Visible = state end
	if state then
		JumpConnection = UserInputService.JumpRequest:Connect(function()
			if not UnlimitedJumpEnabled then return end
			local c = LocalPlayer.Character
			if not c then return end
			local h = c:FindFirstChildOfClass("Humanoid")
			if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
		end)
		SetStatus("Unlimited Jump: ON", Color3.fromRGB(100, 255, 120))
	else
		MobileJumpBtn.Visible = false
		if JumpConnection then JumpConnection:Disconnect(); JumpConnection = nil end
		SetStatus("Unlimited Jump: OFF", Color3.fromRGB(255, 100, 100))
	end
end)

CreateSection("ESP / RADAR", 10)

CreateToggle("ESP (Full)", "Box+Name+HP+Distance+Highlight", 11, function(state)
	ESPEnabled = state
	if state then
		for _, p in pairs(Players:GetPlayers()) do
			if p ~= LocalPlayer then CreatePlayerESP(p) end
		end
		ESPUpdateConn = RunService.Heartbeat:Connect(function(dt)
			espUpdateTimer += dt; dangerUpdateTimer += dt
			if espUpdateTimer >= 0.05 then espUpdateTimer = 0; UpdateAllESP() end
			if dangerUpdateTimer >= 0.2 then dangerUpdateTimer = 0; CheckDangerAlert() end
		end)
		SetStatus("ESP: ON", Color3.fromRGB(100, 255, 120))
	else
		if ESPUpdateConn then ESPUpdateConn:Disconnect(); ESPUpdateConn = nil end
		for _, p in pairs(Players:GetPlayers()) do RemovePlayerESP(p) end
		AlertFrame.Visible = false; alertActive = false
		espUpdateTimer = 0; dangerUpdateTimer = 0
		SetStatus("ESP: OFF", Color3.fromRGB(255, 100, 100))
	end
end)

CreateToggle("Tracer Lines", "Garis penunjuk ke musuh", 12, function(state)
	ESPSettings.ShowTracer = state
	SetStatus("Tracer: " .. (state and "ON" or "OFF"),
		state and Color3.fromRGB(100, 255, 120) or Color3.fromRGB(255, 100, 100))
end)

CreateToggle("Mini Radar", "Radar deteksi musuh sekitar", 13, function(state)
	RadarFrame.Visible = state
	if state then
		connections:Add("radar", RunService.Heartbeat:Connect(function(dt)
			radarUpdateTimer += dt
			if radarUpdateTimer >= 0.1 then radarUpdateTimer = 0; UpdateRadar() end
		end))
		SetStatus("Radar: ON", Color3.fromRGB(100, 255, 120))
	else
		connections:Remove("radar"); radarUpdateTimer = 0
		SetStatus("Radar: OFF", Color3.fromRGB(255, 100, 100))
	end
end)

CreateSlider("ESP Max Distance", 100, 3000, 1500, 14, function(v) ESPSettings.MaxDistance = v end)

-- ═══════════════════════════════════════════
-- COLOR LEGEND
-- ═══════════════════════════════════════════
local LegendFrame = Instance.new("Frame")
LegendFrame.Size = UDim2.new(1, 0, 0, 88)
LegendFrame.BackgroundColor3 = Color3.fromRGB(28, 28, 42)
LegendFrame.BorderSizePixel = 0
LegendFrame.LayoutOrder = 15
LegendFrame.Parent = Content
Instance.new("UICorner", LegendFrame).CornerRadius = UDim.new(0, 10)
Instance.new("UIStroke", LegendFrame).Color = Color3.fromRGB(45, 45, 65)

local LTitle = Instance.new("TextLabel", LegendFrame)
LTitle.Size = UDim2.new(1, 0, 0, 18)
LTitle.Position = UDim2.new(0, 0, 0, 2)
LTitle.BackgroundTransparency = 1
LTitle.Text = "ESP Color Legend"
LTitle.TextSize = 11
LTitle.Font = Enum.Font.GothamBold
LTitle.TextColor3 = Color3.fromRGB(200, 200, 200)

local legendData = {
	{Color3.fromRGB(255, 50, 50),  "0-200m = !",     20},
	{Color3.fromRGB(255, 220, 0),  "201-300m = ~",   34},
	{Color3.fromRGB(50, 255, 80),  "301-600m = -",   48},
	{Color3.fromRGB(60, 160, 255), "601+m = .",       62},
}

for _, d in pairs(legendData) do
	local dot = Instance.new("Frame", LegendFrame)
	dot.Size = UDim2.new(0, 9, 0, 9)
	dot.Position = UDim2.new(0, 10, 0, d[3])
	dot.BackgroundColor3 = d[1]
	dot.BorderSizePixel = 0
	Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

	local lbl = Instance.new("TextLabel", LegendFrame)
	lbl.Size = UDim2.new(1, -26, 0, 13)
	lbl.Position = UDim2.new(0, 24, 0, d[3] - 1)
	lbl.BackgroundTransparency = 1
	lbl.Text = d[2]
	lbl.TextSize = 9
	lbl.Font = Enum.Font.Gotham
	lbl.TextColor3 = d[1]
	lbl.TextXAlignment = Enum.TextXAlignment.Left
end

local Credit = Instance.new("TextLabel")
Credit.Size = UDim2.new(1, 0, 0, 20)
Credit.BackgroundTransparency = 1
Credit.Text = "Solara Hub V5 | Compact Alert Edition"
Credit.TextSize = 9
Credit.Font = Enum.Font.Gotham
Credit.TextColor3 = Color3.fromRGB(60, 60, 80)
Credit.LayoutOrder = 99
Credit.Parent = Content

-- ═══════════════════════════════════════════
-- PC KEYBOARD
-- ═══════════════════════════════════════════
if IsPC then
	UserInputService.InputBegan:Connect(function(input, gp)
		if gp then return end
		if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
		if input.KeyCode == Enum.KeyCode.W then Ctrl.f = 1
		elseif input.KeyCode == Enum.KeyCode.S then Ctrl.b = -1
		elseif input.KeyCode == Enum.KeyCode.A then Ctrl.l = -1
		elseif input.KeyCode == Enum.KeyCode.D then Ctrl.r = 1 end
		if input.KeyCode == Enum.KeyCode.RightControl then
			if MainFrame.Visible then MinBtn.MouseButton1Click:Fire()
			elseif MiniIcon.Visible then MiniIcon.MouseButton1Click:Fire() end
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
		if input.KeyCode == Enum.KeyCode.W then Ctrl.f = 0
		elseif input.KeyCode == Enum.KeyCode.S then Ctrl.b = 0
		elseif input.KeyCode == Enum.KeyCode.A then Ctrl.l = 0
		elseif input.KeyCode == Enum.KeyCode.D then Ctrl.r = 0 end
	end)
end

-- ═══════════════════════════════════════════
-- DRAGGABLE
-- ═══════════════════════════════════════════
do
	local dragging, dragInput, dragStart, startPos = false, nil, nil, nil

	TitleBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true; dragStart = input.Position; startPos = MainFrame.Position; dragInput = input
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false; dragInput = nil end
			end)
		end
	end)

	UserInputService.TouchMoved:Connect(function(touch, gp)
		if dragging and dragStart then
			local delta = touch.Position - dragStart
			MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement and dragging and dragStart then
			local delta = input.Position - dragStart
			MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false; dragInput = nil
		end
	end)
end

-- Mini icon draggable
do
	local d2, ds2, sp2 = false, nil, nil

	MiniIcon.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			d2 = true; ds2 = input.Position; sp2 = MiniIcon.Position
		end
	end)

	UserInputService.TouchMoved:Connect(function(t, gp)
		if d2 and ds2 then
			local delta = t.Position - ds2
			MiniIcon.Position = UDim2.new(sp2.X.Scale, sp2.X.Offset + delta.X, sp2.Y.Scale, sp2.Y.Offset + delta.Y)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if d2 and ds2 and input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = input.Position - ds2
			MiniIcon.Position = UDim2.new(sp2.X.Scale, sp2.X.Offset + delta.X, sp2.Y.Scale, sp2.Y.Offset + delta.Y)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			d2 = false; ds2 = nil
		end
	end)
end

-- ═══════════════════════════════════════════
-- MINIMIZE
-- ═══════════════════════════════════════════
MinBtn.MouseButton1Click:Connect(function()
	local cx = MainFrame.Position.X.Offset + frameW/2
	local cy = MainFrame.Position.Y.Offset + frameH/2
	SafeTween(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
		Size = UDim2.new(0, 0, 0, 0),
		Position = UDim2.new(MainFrame.Position.X.Scale, cx, MainFrame.Position.Y.Scale, cy)
	})
	task.wait(0.32)
	MainFrame.Visible = false
	MiniIcon.Visible = true
	MiniIcon.Size = UDim2.new(0, 0, 0, 0)
	MiniIcon.ImageTransparency = 1
	SafeTween(MiniIcon, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 60, 0, 60), ImageTransparency = 0
	})
end)

-- RESTORE
local lastIconClick = 0
MiniIcon.MouseButton1Click:Connect(function()
	if tick() - lastIconClick < 0.4 then return end
	lastIconClick = tick()
	SafeTween(MiniIcon, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
		Size = UDim2.new(0, 0, 0, 0), ImageTransparency = 1
	})
	task.wait(0.22)
	MiniIcon.Visible = false
	MainFrame.Visible = true
	MainFrame.Size = UDim2.new(0, 0, 0, 0)
	MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	SafeTween(MainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, frameW, 0, frameH),
		Position = UDim2.new(0.5, -frameW/2, 0.5, -frameH/2)
	})
end)

MiniIcon.TouchTap:Connect(function() MiniIcon.MouseButton1Click:Fire() end)

-- ═══════════════════════════════════════════
-- CLOSE
-- ═══════════════════════════════════════════
CloseBtn.MouseButton1Click:Connect(function()
	Flying = false; FlyToggleState = false; ESPEnabled = false; UnlimitedJumpEnabled = false
	FlyJoystickFrame.Visible = false; FlyUpBtn.Visible = false; FlyDownBtn.Visible = false; MobileJumpBtn.Visible = false
	if ESPUpdateConn then ESPUpdateConn:Disconnect(); ESPUpdateConn = nil end
	if JumpConnection then JumpConnection:Disconnect(); JumpConnection = nil end
	if FlyBodyGyro then pcall(function() FlyBodyGyro:Destroy() end); FlyBodyGyro = nil end
	if FlyBodyVelocity then pcall(function() FlyBodyVelocity:Destroy() end); FlyBodyVelocity = nil end
	for _, p in pairs(Players:GetPlayers()) do RemovePlayerESP(p) end
	connections:RemoveAll()
	pcall(function()
		Lighting.Brightness = originalValues.Brightness; Lighting.ClockTime = originalValues.ClockTime
		Lighting.FogEnd = originalValues.FogEnd; Lighting.FogStart = originalValues.FogStart
		Lighting.GlobalShadows = originalValues.GlobalShadows; Lighting.OutdoorAmbient = originalValues.OutdoorAmbient
		LocalPlayer.CameraMaxZoomDistance = originalValues.MaxZoom
		LocalPlayer.CameraMinZoomDistance = originalValues.MinZoom
	end)
	for inst, orig in pairs(RemovedEffects) do pcall(function() inst.Parent = orig end) end
	RemovedEffects = {}
	local h = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
	if h then pcall(function() h.PlatformStand = false end) end
	pcall(function() ESPWorkspaceFolder:Destroy() end)
	for _, dot in pairs(radarDotPool) do pcall(function() dot:Destroy() end) end
	radarDotPool = {}
	SafeTween(MainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {Size = UDim2.new(0, 0, 0, 0)})
	task.wait(0.28)
	pcall(function() ESPGui:Destroy() end)
	pcall(function() ScreenGui:Destroy() end)
end)

CloseBtn.TouchTap:Connect(function() CloseBtn.MouseButton1Click:Fire() end)

-- HOVER (PC)
if IsPC then
	CloseBtn.MouseEnter:Connect(function() SafeTween(CloseBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(255, 70, 70)}) end)
	CloseBtn.MouseLeave:Connect(function() SafeTween(CloseBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(200, 50, 50)}) end)
	MinBtn.MouseEnter:Connect(function() SafeTween(MinBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(255, 210, 50)}) end)
	MinBtn.MouseLeave:Connect(function() SafeTween(MinBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(255, 175, 0)}) end)
end

-- ═══════════════════════════════════════════
-- OPEN ANIMATION
-- ═══════════════════════════════════════════
MainFrame.Size = UDim2.new(0, 0, 0, 0)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
task.wait(0.1)
SafeTween(MainFrame, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
	Size = UDim2.new(0, frameW, 0, frameH),
	Position = UDim2.new(0.5, -frameW/2, 0.5, -frameH/2)
})

-- ═══════════════════════════════════════════
print("==========================================")
print("  Solara Hub V5 - Compact Alert Edition")
print("==========================================")
print("Platform: " .. (IsMobile and "MOBILE" or "PC"))
print("Alert: Compact [!] 2x 87m format")
print("ESP labels: ! ~ - . (minimal)")
print("==========================================")
