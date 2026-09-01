-- // Universal Fly Script V2
-- // + Close & Minimize Button
-- // + Speed up to 1000 (Safe Range)
-- // Mobile: Joystick + Buttons | PC: WASD + Space/Ctrl

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ═══════════════════════════════════════════
-- CLEANUP
-- ═══════════════════════════════════════════
pcall(function() game:GetService("CoreGui"):FindFirstChild("FlyGuiV2"):Destroy() end)
pcall(function() LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("FlyGuiV2"):Destroy() end)

-- ═══════════════════════════════════════════
-- PLATFORM
-- ═══════════════════════════════════════════
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- ═══════════════════════════════════════════
-- FLY STATE
-- ═══════════════════════════════════════════
local isFlying = false
local flySpeed = 60
local noclipEnabled = false
local bodyVelocity = nil
local bodyGyro = nil
local flyConnection = nil
local noclipConnection = nil

local joystickActive = false
local joystickDir = Vector2.new(0, 0)
local mobileUp = false
local mobileDown = false
local keysDown = {}

-- ═══════════════════════════════════════════
-- HELPERS
-- ═══════════════════════════════════════════
local function SafeTween(obj, info, goals)
	if not obj or not obj.Parent then return end
	pcall(function() TweenService:Create(obj, info, goals):Play() end)
end

local function GetHRP()
	local char = LocalPlayer.Character
	return char and char:FindFirstChild("HumanoidRootPart")
end

local function GetHumanoid()
	local char = LocalPlayer.Character
	return char and char:FindFirstChildOfClass("Humanoid")
end

-- ═══════════════════════════════════════════
-- CORE FLY
-- ═══════════════════════════════════════════
local function StartFly()
	local hrp = GetHRP()
	local hum = GetHumanoid()
	if not hrp or not hum or isFlying then return end

	isFlying = true

	bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
	bodyVelocity.Velocity = Vector3.new(0, 0, 0)
	bodyVelocity.P = 9000
	bodyVelocity.Parent = hrp

	bodyGyro = Instance.new("BodyGyro")
	bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
	bodyGyro.CFrame = Camera.CFrame
	bodyGyro.P = 9000
	bodyGyro.D = 600
	bodyGyro.Parent = hrp

	pcall(function() hum.PlatformStand = true end)

	flyConnection = RunService.RenderStepped:Connect(function()
		local hrp2 = GetHRP()
		if not hrp2 or not isFlying then return end
		if not bodyVelocity or not bodyVelocity.Parent then return end
		if not bodyGyro or not bodyGyro.Parent then return end

		local camCF = Camera.CFrame
		local camLook = camCF.LookVector
		local camRight = camCF.RightVector
		local camUp = Vector3.new(0, 1, 0)
		local moveDir = Vector3.new(0, 0, 0)

		if isMobile then
			if joystickActive and joystickDir.Magnitude > 0.1 then
				moveDir = moveDir + camLook * (-joystickDir.Y)
				moveDir = moveDir + camRight * joystickDir.X
			end
			if mobileUp then moveDir = moveDir + camUp end
			if mobileDown then moveDir = moveDir - camUp end
		else
			if keysDown[Enum.KeyCode.W] then moveDir = moveDir + camLook end
			if keysDown[Enum.KeyCode.S] then moveDir = moveDir - camLook end
			if keysDown[Enum.KeyCode.D] then moveDir = moveDir + camRight end
			if keysDown[Enum.KeyCode.A] then moveDir = moveDir - camRight end
			if keysDown[Enum.KeyCode.Space] then moveDir = moveDir + camUp end
			if keysDown[Enum.KeyCode.LeftControl] or keysDown[Enum.KeyCode.LeftShift] then moveDir = moveDir - camUp end
		end

		bodyVelocity.Velocity = moveDir.Magnitude > 0 and moveDir.Unit * flySpeed or Vector3.new(0, 0, 0)
		bodyGyro.CFrame = camCF
	end)
end

local function StopFly()
	if not isFlying then return end
	isFlying = false
	if flyConnection then flyConnection:Disconnect(); flyConnection = nil end
	if bodyVelocity then pcall(function() bodyVelocity:Destroy() end); bodyVelocity = nil end
	if bodyGyro then pcall(function() bodyGyro:Destroy() end); bodyGyro = nil end
	local hum = GetHumanoid()
	if hum then pcall(function() hum.PlatformStand = false end) end
end

local function ToggleFly()
	if isFlying then StopFly() else StartFly() end
end

-- ═══════════════════════════════════════════
-- NOCLIP
-- ═══════════════════════════════════════════
local function SetNoclip(enable)
	noclipEnabled = enable
	if noclipConnection then noclipConnection:Disconnect(); noclipConnection = nil end
	if enable then
		noclipConnection = RunService.Stepped:Connect(function()
			local char = LocalPlayer.Character
			if not char then return end
			for _, p in pairs(char:GetDescendants()) do
				if p:IsA("BasePart") then p.CanCollide = false end
			end
		end)
	else
		local char = LocalPlayer.Character
		if char then
			for _, p in pairs(char:GetDescendants()) do
				if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then p.CanCollide = true end
			end
		end
	end
end

-- ═══════════════════════════════════════════
-- PC INPUT
-- ═══════════════════════════════════════════
UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.UserInputType == Enum.UserInputType.Keyboard then
		keysDown[input.KeyCode] = true
		if input.KeyCode == Enum.KeyCode.F then ToggleFly(); UpdateFlyBtn() end
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Keyboard then keysDown[input.KeyCode] = nil end
end)

LocalPlayer.CharacterAdded:Connect(function()
	StopFly()
	if noclipEnabled then task.wait(1); SetNoclip(true) end
end)

-- ═══════════════════════════════════════════
-- GUI
-- ═══════════════════════════════════════════
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "FlyGuiV2"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
pcall(function() ScreenGui.Parent = game:GetService("CoreGui") end)
if not ScreenGui.Parent then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local vpX = Camera.ViewportSize.X
local vpY = Camera.ViewportSize.Y

-- ═══════════════════════════════════════════
-- PANEL
-- ═══════════════════════════════════════════
local panelW = isMobile and 145 or 160
local panelH = isMobile and 175 or 190

local Panel = Instance.new("Frame", ScreenGui)
Panel.Size = UDim2.new(0, panelW, 0, panelH)
Panel.Position = UDim2.new(0, 10, 0, isMobile and 90 or 70)
Panel.BackgroundColor3 = Color3.fromRGB(14, 14, 24)
Panel.BorderSizePixel = 0
Panel.Active = true
Panel.ClipsDescendants = true
Instance.new("UICorner", Panel).CornerRadius = UDim.new(0, 10)

local PanelStroke = Instance.new("UIStroke", Panel)
PanelStroke.Color = Color3.fromRGB(80, 140, 255)
PanelStroke.Thickness = 1.5

-- ── Title Bar ──
local TitleBar = Instance.new("Frame", Panel)
TitleBar.Size = UDim2.new(1, 0, 0, 28)
TitleBar.BackgroundColor3 = Color3.fromRGB(20, 22, 36)
TitleBar.BorderSizePixel = 0
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 10)

local TFix = Instance.new("Frame", TitleBar)
TFix.Size = UDim2.new(1, 0, 0, 8)
TFix.Position = UDim2.new(0, 0, 1, -8)
TFix.BackgroundColor3 = Color3.fromRGB(20, 22, 36)
TFix.BorderSizePixel = 0

local TitleLbl = Instance.new("TextLabel", TitleBar)
TitleLbl.Size = UDim2.new(0.55, 0, 1, 0)
TitleLbl.Position = UDim2.new(0, 8, 0, 0)
TitleLbl.BackgroundTransparency = 1
TitleLbl.Text = "🕊️ Fly"
TitleLbl.TextSize = isMobile and 10 or 11
TitleLbl.Font = Enum.Font.GothamBold
TitleLbl.TextColor3 = Color3.fromRGB(100, 180, 255)
TitleLbl.TextXAlignment = Enum.TextXAlignment.Left

-- ── Close Button ──
local btnSz = isMobile and 20 or 22
local CloseBtn = Instance.new("TextButton", TitleBar)
CloseBtn.Size = UDim2.new(0, btnSz, 0, btnSz)
CloseBtn.Position = UDim2.new(1, -(btnSz + 4), 0, (28 - btnSz) / 2)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseBtn.Text = "X"
CloseBtn.TextSize = isMobile and 8 or 9
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextColor3 = Color3.new(1, 1, 1)
CloseBtn.ZIndex = 5
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 4)

-- ── Minimize Button ──
local MinBtn = Instance.new("TextButton", TitleBar)
MinBtn.Size = UDim2.new(0, btnSz, 0, btnSz)
MinBtn.Position = UDim2.new(1, -(btnSz * 2 + 8), 0, (28 - btnSz) / 2)
MinBtn.BackgroundColor3 = Color3.fromRGB(255, 175, 0)
MinBtn.Text = "-"
MinBtn.TextSize = isMobile and 10 or 12
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextColor3 = Color3.new(1, 1, 1)
MinBtn.ZIndex = 5
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 4)

-- ═══════════════════════════════════════════
-- CONTENT (di bawah title bar)
-- ═══════════════════════════════════════════
local contentTop = 32

-- Fly Toggle
local FlyBtn = Instance.new("TextButton", Panel)
FlyBtn.Size = UDim2.new(1, -12, 0, isMobile and 28 or 26)
FlyBtn.Position = UDim2.new(0, 6, 0, contentTop)
FlyBtn.BackgroundColor3 = Color3.fromRGB(40, 60, 120)
FlyBtn.Text = "▶ FLY: OFF"
FlyBtn.TextSize = isMobile and 10 or 11
FlyBtn.Font = Enum.Font.GothamBold
FlyBtn.TextColor3 = Color3.new(1, 1, 1)
FlyBtn.AutoButtonColor = false
Instance.new("UICorner", FlyBtn).CornerRadius = UDim.new(0, 6)

function UpdateFlyBtn()
	FlyBtn.Text = isFlying and "⏸ FLY: ON" or "▶ FLY: OFF"
	SafeTween(FlyBtn, TweenInfo.new(0.2), {
		BackgroundColor3 = isFlying and Color3.fromRGB(40, 160, 100) or Color3.fromRGB(40, 60, 120)
	})
	SafeTween(PanelStroke, TweenInfo.new(0.2), {
		Color = isFlying and Color3.fromRGB(80, 255, 150) or Color3.fromRGB(80, 140, 255)
	})
end

FlyBtn.MouseButton1Click:Connect(function() ToggleFly(); UpdateFlyBtn() end)
FlyBtn.TouchTap:Connect(function() ToggleFly(); UpdateFlyBtn() end)

-- Noclip Toggle
local NoclipBtn = Instance.new("TextButton", Panel)
NoclipBtn.Size = UDim2.new(1, -12, 0, isMobile and 24 or 22)
NoclipBtn.Position = UDim2.new(0, 6, 0, contentTop + 32)
NoclipBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 55)
NoclipBtn.Text = "👻 Noclip: OFF"
NoclipBtn.TextSize = isMobile and 9 or 9
NoclipBtn.Font = Enum.Font.GothamBold
NoclipBtn.TextColor3 = Color3.fromRGB(180, 180, 200)
NoclipBtn.AutoButtonColor = false
Instance.new("UICorner", NoclipBtn).CornerRadius = UDim.new(0, 5)

NoclipBtn.MouseButton1Click:Connect(function()
	noclipEnabled = not noclipEnabled
	SetNoclip(noclipEnabled)
	NoclipBtn.Text = noclipEnabled and "👻 Noclip: ON" or "👻 Noclip: OFF"
	SafeTween(NoclipBtn, TweenInfo.new(0.2), {
		BackgroundColor3 = noclipEnabled and Color3.fromRGB(100, 60, 160) or Color3.fromRGB(35, 35, 55)
	})
end)
NoclipBtn.TouchTap:Connect(function() NoclipBtn.MouseButton1Click:Fire() end)

-- Speed Label
local SpeedLbl = Instance.new("TextLabel", Panel)
SpeedLbl.Size = UDim2.new(1, -12, 0, 14)
SpeedLbl.Position = UDim2.new(0, 6, 0, contentTop + 60)
SpeedLbl.BackgroundTransparency = 1
SpeedLbl.Text = "Speed: " .. flySpeed
SpeedLbl.TextSize = 9
SpeedLbl.Font = Enum.Font.GothamBold
SpeedLbl.TextColor3 = Color3.fromRGB(150, 200, 255)
SpeedLbl.TextXAlignment = Enum.TextXAlignment.Left

-- Speed Slider (Max 1000)
local trackH = isMobile and 8 or 6
local sliderY = contentTop + 76
local Track = Instance.new("Frame", Panel)
Track.Size = UDim2.new(1, -16, 0, trackH)
Track.Position = UDim2.new(0, 8, 0, sliderY)
Track.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
Track.BorderSizePixel = 0
Instance.new("UICorner", Track).CornerRadius = UDim.new(1, 0)

local minSpd, maxSpd = 10, 1000
local ratio = (flySpeed - minSpd) / (maxSpd - minSpd)

local Fill = Instance.new("Frame", Track)
Fill.Size = UDim2.new(ratio, 0, 1, 0)
Fill.BackgroundColor3 = Color3.fromRGB(80, 140, 255)
Fill.BorderSizePixel = 0
Instance.new("UICorner", Fill).CornerRadius = UDim.new(1, 0)

local kw = isMobile and 16 or 12
local Knob = Instance.new("Frame", Track)
Knob.Size = UDim2.new(0, kw, 0, kw)
Knob.Position = UDim2.new(ratio, -kw / 2, 0.5, -kw / 2)
Knob.BackgroundColor3 = Color3.new(1, 1, 1)
Knob.BorderSizePixel = 0
Knob.ZIndex = 2
Instance.new("UICorner", Knob).CornerRadius = UDim.new(1, 0)

local hitPad = isMobile and 20 or 12
local HitArea = Instance.new("TextButton", Track)
HitArea.Size = UDim2.new(1, 0, 0, hitPad * 2)
HitArea.Position = UDim2.new(0, 0, 0.5, -hitPad)
HitArea.BackgroundTransparency = 1
HitArea.Text = ""; HitArea.ZIndex = 3

local sliding = false
local function UpdateSlider(xPos)
	local tP = Track.AbsolutePosition.X
	local tS = Track.AbsoluteSize.X
	if tS <= 0 then return end
	local r = math.clamp((xPos - tP) / tS, 0, 1)
	local v = math.floor(minSpd + (maxSpd - minSpd) * r)
	flySpeed = v
	Fill.Size = UDim2.new(r, 0, 1, 0)
	Knob.Position = UDim2.new(r, -kw / 2, 0.5, -kw / 2)
	SpeedLbl.Text = "Speed: " .. v

	-- Color warning jika speed tinggi
	if v > 700 then
		Fill.BackgroundColor3 = Color3.fromRGB(255, 80, 60)
		SpeedLbl.TextColor3 = Color3.fromRGB(255, 120, 100)
	elseif v > 400 then
		Fill.BackgroundColor3 = Color3.fromRGB(255, 180, 50)
		SpeedLbl.TextColor3 = Color3.fromRGB(255, 200, 100)
	else
		Fill.BackgroundColor3 = Color3.fromRGB(80, 140, 255)
		SpeedLbl.TextColor3 = Color3.fromRGB(150, 200, 255)
	end
end

HitArea.MouseButton1Down:Connect(function() sliding = true end)
HitArea.InputBegan:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.Touch then sliding = true; UpdateSlider(i.Position.X) end
end)
HitArea.InputEnded:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then sliding = false end
end)
UserInputService.InputEnded:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then sliding = false end
end)
UserInputService.InputChanged:Connect(function(i)
	if not sliding then return end
	if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then UpdateSlider(i.Position.X) end
end)
UserInputService.TouchMoved:Connect(function(t) if sliding then UpdateSlider(t.Position.X) end end)

-- Speed Presets
local presetY = sliderY + 14
local presets = {
	{text = "Slow",  speed = 30,  color = Color3.fromRGB(40, 100, 60)},
	{text = "Mid",   speed = 100, color = Color3.fromRGB(40, 80, 120)},
	{text = "Fast",  speed = 400, color = Color3.fromRGB(140, 100, 30)},
	{text = "Ultra", speed = 800, color = Color3.fromRGB(150, 40, 40)},
}

for idx, p in ipairs(presets) do
	local pb = Instance.new("TextButton", Panel)
	local bw = (panelW - 18) / 4
	pb.Size = UDim2.new(0, bw - 2, 0, isMobile and 20 or 18)
	pb.Position = UDim2.new(0, 6 + (idx - 1) * bw, 0, presetY)
	pb.BackgroundColor3 = p.color
	pb.Text = p.text
	pb.TextSize = isMobile and 8 or 7
	pb.Font = Enum.Font.GothamBold
	pb.TextColor3 = Color3.new(1, 1, 1)
	Instance.new("UICorner", pb).CornerRadius = UDim.new(0, 3)

	local function SetPreset()
		flySpeed = p.speed
		local r = (p.speed - minSpd) / (maxSpd - minSpd)
		Fill.Size = UDim2.new(r, 0, 1, 0)
		Knob.Position = UDim2.new(r, -kw / 2, 0.5, -kw / 2)
		SpeedLbl.Text = "Speed: " .. p.speed
		if p.speed > 700 then
			Fill.BackgroundColor3 = Color3.fromRGB(255, 80, 60)
			SpeedLbl.TextColor3 = Color3.fromRGB(255, 120, 100)
		elseif p.speed > 400 then
			Fill.BackgroundColor3 = Color3.fromRGB(255, 180, 50)
			SpeedLbl.TextColor3 = Color3.fromRGB(255, 200, 100)
		else
			Fill.BackgroundColor3 = Color3.fromRGB(80, 140, 255)
			SpeedLbl.TextColor3 = Color3.fromRGB(150, 200, 255)
		end
	end
	pb.MouseButton1Click:Connect(SetPreset)
	pb.TouchTap:Connect(SetPreset)
end

-- PC Info
if not isMobile then
	local infoLbl = Instance.new("TextLabel", Panel)
	infoLbl.Size = UDim2.new(1, -12, 0, 14)
	infoLbl.Position = UDim2.new(0, 6, 0, presetY + 22)
	infoLbl.BackgroundTransparency = 1
	infoLbl.Text = "F=Fly | WASD | Space/Ctrl"
	infoLbl.TextSize = 7
	infoLbl.Font = Enum.Font.Gotham
	infoLbl.TextColor3 = Color3.fromRGB(60, 60, 90)
end

-- ═══════════════════════════════════════════
-- MINIMIZE ICON
-- ═══════════════════════════════════════════
local MiniIcon = Instance.new("TextButton", ScreenGui)
MiniIcon.Size = UDim2.new(0, 38, 0, 38)
MiniIcon.Position = UDim2.new(0, 10, 0, isMobile and 90 or 70)
MiniIcon.BackgroundColor3 = Color3.fromRGB(14, 14, 24)
MiniIcon.Text = "🕊️"
MiniIcon.TextSize = 16
MiniIcon.Visible = false
MiniIcon.ZIndex = 10
Instance.new("UICorner", MiniIcon).CornerRadius = UDim.new(0, 10)
Instance.new("UIStroke", MiniIcon).Color = Color3.fromRGB(80, 140, 255)

-- Minimize Action
local function DoMinimize()
	SafeTween(Panel, TweenInfo.new(0.2, Enum.EasingStyle.Quart), {Size = UDim2.new(0, 0, 0, 0)})
	task.wait(0.2)
	Panel.Visible = false
	MiniIcon.Visible = true
	MiniIcon.Position = Panel.Position
	MiniIcon.Size = UDim2.new(0, 0, 0, 0)
	SafeTween(MiniIcon, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 38, 0, 38)
	})
end
MinBtn.MouseButton1Click:Connect(DoMinimize)
MinBtn.TouchTap:Connect(DoMinimize)

-- Restore Action
local lastTap = 0
local function DoRestore()
	if tick() - lastTap < 0.4 then return end
	lastTap = tick()
	local rPos = MiniIcon.Position
	SafeTween(MiniIcon, TweenInfo.new(0.15), {Size = UDim2.new(0, 0, 0, 0)})
	task.wait(0.15)
	MiniIcon.Visible = false
	Panel.Visible = true
	Panel.Position = rPos
	Panel.Size = UDim2.new(0, 0, 0, 0)
	SafeTween(Panel, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, panelW, 0, panelH)
	})
end
MiniIcon.MouseButton1Click:Connect(DoRestore)
MiniIcon.TouchTap:Connect(DoRestore)

-- Close Action
local function DoClose()
	StopFly()
	SetNoclip(false)
	pcall(function() ScreenGui:Destroy() end)
end
CloseBtn.MouseButton1Click:Connect(DoClose)
CloseBtn.TouchTap:Connect(DoClose)

-- ═══════════════════════════════════════════
-- MOBILE: JOYSTICK + UP/DOWN
-- ═══════════════════════════════════════════
if isMobile then
	local joySize = 110
	local joyRadius = joySize / 2
	local knobR = 22

	local JoyFrame = Instance.new("Frame", ScreenGui)
	JoyFrame.Size = UDim2.new(0, joySize, 0, joySize)
	JoyFrame.Position = UDim2.new(1, -(joySize + 16), 1, -(joySize + 90))
	JoyFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
	JoyFrame.BackgroundTransparency = 0.3
	JoyFrame.BorderSizePixel = 0
	Instance.new("UICorner", JoyFrame).CornerRadius = UDim.new(1, 0)
	Instance.new("UIStroke", JoyFrame).Color = Color3.fromRGB(80, 140, 255)

	local JoyKnob = Instance.new("Frame", JoyFrame)
	JoyKnob.Size = UDim2.new(0, knobR * 2, 0, knobR * 2)
	JoyKnob.Position = UDim2.new(0.5, -knobR, 0.5, -knobR)
	JoyKnob.BackgroundColor3 = Color3.fromRGB(100, 180, 255)
	JoyKnob.BorderSizePixel = 0
	JoyKnob.ZIndex = 3
	Instance.new("UICorner", JoyKnob).CornerRadius = UDim.new(1, 0)

	local JoyLabel = Instance.new("TextLabel", JoyFrame)
	JoyLabel.Size = UDim2.new(1, 0, 0, 12)
	JoyLabel.Position = UDim2.new(0, 0, 1, 2)
	JoyLabel.BackgroundTransparency = 1
	JoyLabel.Text = "MOVE"
	JoyLabel.TextSize = 8
	JoyLabel.Font = Enum.Font.GothamBold
	JoyLabel.TextColor3 = Color3.fromRGB(80, 140, 255)

	local joyTouchId = nil

	JoyFrame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch then
			joyTouchId = input
			joystickActive = true
		end
	end)

	UserInputService.TouchMoved:Connect(function(touch)
		if not joystickActive or not joyTouchId or touch ~= joyTouchId then return end
		local center = JoyFrame.AbsolutePosition + JoyFrame.AbsoluteSize / 2
		local delta = Vector2.new(touch.Position.X, touch.Position.Y) - center
		local maxDist = joyRadius - knobR
		if delta.Magnitude > maxDist then delta = delta.Unit * maxDist end
		JoyKnob.Position = UDim2.new(0.5, delta.X - knobR, 0.5, delta.Y - knobR)
		joystickDir = Vector2.new(delta.X / maxDist, delta.Y / maxDist)
	end)

	local function ResetJoy()
		joystickActive = false; joyTouchId = nil
		joystickDir = Vector2.new(0, 0)
		SafeTween(JoyKnob, TweenInfo.new(0.12), {Position = UDim2.new(0.5, -knobR, 0.5, -knobR)})
	end
	UserInputService.TouchEnded:Connect(function(t) if t == joyTouchId then ResetJoy() end end)

	-- UP / DOWN Buttons
	local bW, bH = 56, 46

	local UpBtn = Instance.new("TextButton", ScreenGui)
	UpBtn.Size = UDim2.new(0, bW, 0, bH)
	UpBtn.Position = UDim2.new(0, 16, 1, -(bH * 2 + 100))
	UpBtn.BackgroundColor3 = Color3.fromRGB(30, 80, 160)
	UpBtn.Text = "⬆ UP"
	UpBtn.TextSize = 11; UpBtn.Font = Enum.Font.GothamBold; UpBtn.TextColor3 = Color3.new(1, 1, 1)
	Instance.new("UICorner", UpBtn).CornerRadius = UDim.new(0, 10)
	Instance.new("UIStroke", UpBtn).Color = Color3.fromRGB(60, 120, 220)

	local DownBtn = Instance.new("TextButton", ScreenGui)
	DownBtn.Size = UDim2.new(0, bW, 0, bH)
	DownBtn.Position = UDim2.new(0, 16, 1, -(bH + 90))
	DownBtn.BackgroundColor3 = Color3.fromRGB(120, 50, 30)
	DownBtn.Text = "⬇ DOWN"
	DownBtn.TextSize = 11; DownBtn.Font = Enum.Font.GothamBold; DownBtn.TextColor3 = Color3.new(1, 1, 1)
	Instance.new("UICorner", DownBtn).CornerRadius = UDim.new(0, 10)
	Instance.new("UIStroke", DownBtn).Color = Color3.fromRGB(200, 80, 50)

	UpBtn.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.Touch then mobileUp = true end
	end)
	UpBtn.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.Touch then mobileUp = false end
	end)
	DownBtn.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.Touch then mobileDown = true end
	end)
	DownBtn.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.Touch then mobileDown = false end
	end)
end

-- ═══════════════════════════════════════════
-- DRAGGABLE (Title Bar Only)
-- ═══════════════════════════════════════════
do
	local dragging, dragStart, frameStart = false, nil, nil
	TitleBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = Vector2.new(input.Position.X, input.Position.Y)
			frameStart = Vector2.new(Panel.Position.X.Offset, Panel.Position.Y.Offset)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if not dragging then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			local d = Vector2.new(input.Position.X, input.Position.Y) - dragStart
			Panel.Position = UDim2.new(0, math.clamp(frameStart.X + d.X, 0, vpX - panelW), 0, math.clamp(frameStart.Y + d.Y, 0, vpY - 50))
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
	end)
end

-- Mini icon draggable
do
	local md, ms, fs = false, nil, nil
	MiniIcon.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
			md = true; ms = Vector2.new(i.Position.X, i.Position.Y)
			fs = Vector2.new(MiniIcon.Position.X.Offset, MiniIcon.Position.Y.Offset)
		end
	end)
	UserInputService.InputChanged:Connect(function(i)
		if not md then return end
		if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseMovement then
			local d = Vector2.new(i.Position.X, i.Position.Y) - ms
			if d.Magnitude > 5 then
				MiniIcon.Position = UDim2.new(0, math.clamp(fs.X + d.X, 0, vpX - 38), 0, math.clamp(fs.Y + d.Y, 0, vpY - 38))
			end
		end
	end)
	UserInputService.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then md = false end
	end)
end

-- ═══════════════════════════════════════════
-- OPEN ANIMATION
-- ═══════════════════════════════════════════
Panel.Size = UDim2.new(0, 0, 0, 0)
task.wait(0.1)
SafeTween(Panel, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
	Size = UDim2.new(0, panelW, 0, panelH)
})

print("🕊️ Fly V2 Loaded! Speed: 10-1000 | " .. (isMobile and "Mobile" or "PC"))
