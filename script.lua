-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")
local camera = Workspace.CurrentCamera

-- Detect Drawing library support
local hasDrawing = (typeof(Drawing) == "table" and typeof(Drawing.new) == "function")
if not hasDrawing then
	warn("[APM] Drawing library not available - ESP visuals disabled")
end

-- Safe wrapper
local function safe(fn, ...)
	local ok, err = pcall(fn, ...)
	if not ok then warn("[APM] Error:", err) end
	return ok
end

-- State
local highlightedPlayers = {}
local activeHighlights = {}

local flying = false
local flySpeed = 1
local flightKey = Enum.KeyCode.E
local isBindingKey = false
local isBindingJumpKey = false
local isBindingWalkKey = false

local flyPart, flyVelocity
local idleAnim1, idleAnim2, flyAnim
local loadIdle1, loadIdle2, loadFly
local equipFunctionActive = false

local superJumpPower = 35
local superJumpKey = Enum.KeyCode.Q

local customWalkSpeed = 16
local walkSpeedKey = Enum.KeyCode.R
local walkSpeedToggled = false

local customJumpPower = 50
local jumpPowerToggled = false

local targetLockEnabled = false
local targetLockKey = Enum.KeyCode.T
local isBindingTargetLockKey = false
local targetLockConnection = nil
local camlockSmoothness = 12
local camlockSnappiness = 8

local tracersEnabled = false
local tracerFollowMouse = false
local skeletonEnabled = false
local boxEspEnabled = false
local nameEspEnabled = false
local distanceEnabled = false
local healthEspEnabled = false
local espColor = Color3.fromRGB(0, 162, 255)

local spinbotEnabled = false
local spinbotSpeed = 15
local spinbotConnection = nil

local fullbrightEnabled = false
local fullbrightPrev = {}
local noFogEnabled = false
local fogPrev = nil

local crosshairEnabled = false
local crosshairGui = nil
local watermarkEnabled = true
local watermarkGui = nil

local noclipEnabled = false
local noclipConnection = nil
local antiFlingEnabled = false
local clickTeleportEnabled = false
local autoSprintEnabled = false
local autoSprintConnection = nil
local hoverEnabled = false
local antiVoidEnabled = false
local antiVoidConnection = nil
local freezeEnabled = false
local fakeLagEnabled = false
local fakeLagAmount = 5
local hitboxEnabled = false
local hitboxSize = 10
local autoResetEnabled = false
local autoRejoinEnabled = false
local antiAfkEnabled = false
local antiAfkConnection = nil
local cameraFovEnabled = false
local cameraFov = 70

local coordsHudEnabled = false
local coordsGui = nil
local pingHudEnabled = false
local pingGui = nil
local speedHudEnabled = false
local speedGui = nil

local espDrawings = {}

-- Character setup
local function setupCharacter(character)
	local humanoid = character:WaitForChild("Humanoid")
	local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

	humanoid.WalkSpeed = walkSpeedToggled and customWalkSpeed or 20
	humanoid.JumpPower = jumpPowerToggled and customJumpPower or 50

	if flyPart then flyPart:Destroy() end

	flyPart = Instance.new("Part")
	flyPart.Anchored = true
	flyPart.CanCollide = false
	flyPart.Transparency = 1
	flyPart.Size = humanoidRootPart.Size
	flyPart.CFrame = humanoidRootPart.CFrame
	flyPart.Parent = camera

	flyVelocity = Instance.new("BodyVelocity")
	flyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
	flyVelocity.Velocity = Vector3.new(0, 0, 0)
	flyVelocity.Parent = flyPart

	local function createAnim(id)
		local anim = Instance.new("Animation")
		anim.AnimationId = id
		return anim
	end

	safe(function()
		idleAnim1 = createAnim("rbxassetid://10921144709")
		idleAnim2 = createAnim("rbxassetid://10921132962")
		flyAnim = createAnim("rbxassetid://10921294559")

		loadIdle1 = humanoid:LoadAnimation(idleAnim1)
		loadIdle2 = humanoid:LoadAnimation(idleAnim2)
		loadFly = humanoid:LoadAnimation(flyAnim)

		loadIdle1.Priority = Enum.AnimationPriority.Action
		loadIdle2.Priority = Enum.AnimationPriority.Action
		loadFly.Priority = Enum.AnimationPriority.Action
		loadIdle1.Looped = true
		loadIdle2.Looped = true
		loadFly.Looped = true
	end)
end

if localPlayer.Character then
	safe(setupCharacter, localPlayer.Character)
end

localPlayer.CharacterAdded:Connect(function(newChar)
	task.wait(0.05)
	safe(setupCharacter, newChar)
	equipFunctionActive = false
	flying = false
	local hum = newChar:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.WalkSpeed = walkSpeedToggled and customWalkSpeed or 20
		hum.JumpPower = jumpPowerToggled and customJumpPower or 50
	end
end)

-- ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AdvancedPlayerManager"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Watermark
watermarkGui = Instance.new("TextLabel")
watermarkGui.Size = UDim2.new(0, 260, 0, 26)
watermarkGui.Position = UDim2.new(0, 10, 0, 10)
watermarkGui.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
watermarkGui.BackgroundTransparency = 0.3
watermarkGui.BorderSizePixel = 0
watermarkGui.Text = "  Advanced Player Manager | FPS: 0"
watermarkGui.TextColor3 = Color3.fromRGB(0, 162, 255)
watermarkGui.TextSize = 12
watermarkGui.Font = Enum.Font.GothamBold
watermarkGui.TextXAlignment = Enum.TextXAlignment.Left
watermarkGui.Parent = screenGui
Instance.new("UICorner", watermarkGui).CornerRadius = UDim.new(0, 6)

task.spawn(function()
	local fps = 0
	local frameCount = 0
	local lastTime = tick()
	while watermarkGui and watermarkGui.Parent do
		frameCount = frameCount + 1
		if tick() - lastTime >= 1 then
			fps = frameCount
			frameCount = 0
			lastTime = tick()
		end
		watermarkGui.Text = "  Advanced Player Manager | FPS: " .. fps
		RunService.RenderStepped:Wait()
	end
end)

local function createCrosshair()
	if crosshairGui then crosshairGui:Destroy() end
	crosshairGui = Instance.new("Frame")
	crosshairGui.Size = UDim2.new(0, 20, 0, 20)
	crosshairGui.Position = UDim2.new(0.5, -10, 0.5, -10)
	crosshairGui.BackgroundTransparency = 1
	crosshairGui.Parent = screenGui

	local h1 = Instance.new("Frame")
	h1.Size = UDim2.new(0, 2, 0, 8)
	h1.Position = UDim2.new(0.5, -1, 0, 0)
	h1.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
	h1.BorderSizePixel = 0
	h1.Parent = crosshairGui

	local h2 = Instance.new("Frame")
	h2.Size = UDim2.new(0, 2, 0, 8)
	h2.Position = UDim2.new(0.5, -1, 1, -8)
	h2.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
	h2.BorderSizePixel = 0
	h2.Parent = crosshairGui

	local v1 = Instance.new("Frame")
	v1.Size = UDim2.new(0, 8, 0, 2)
	v1.Position = UDim2.new(0, 0, 0.5, -1)
	v1.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
	v1.BorderSizePixel = 0
	v1.Parent = crosshairGui

	local v2 = Instance.new("Frame")
	v2.Size = UDim2.new(0, 8, 0, 2)
	v2.Position = UDim2.new(1, -8, 0.5, -1)
	v2.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
	v2.BorderSizePixel = 0
	v2.Parent = crosshairGui
end

-- Main Frame
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 450, 0, 520)
mainFrame.Position = UDim2.new(0.5, -225, 0.5, -260)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
mainFrame.BorderSizePixel = 0
mainFrame.Visible = true
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 14)
mainCorner.Parent = mainFrame

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(45, 45, 60)
mainStroke.Thickness = 1
mainStroke.Parent = mainFrame

local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 48)
header.BackgroundTransparency = 1
header.Parent = mainFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -20, 1, 0)
titleLabel.Position = UDim2.new(0, 16, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Advanced Player Manager"
titleLabel.TextColor3 = Color3.fromRGB(240, 240, 245)
titleLabel.TextSize = 16
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = header

local tabContainer = Instance.new("Frame")
tabContainer.Size = UDim2.new(1, -20, 0, 36)
tabContainer.Position = UDim2.new(0, 10, 0, 50)
tabContainer.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
tabContainer.BorderSizePixel = 0
tabContainer.Parent = mainFrame

local tabCorner = Instance.new("UICorner")
tabCorner.CornerRadius = UDim.new(0, 8)
tabCorner.Parent = tabContainer

local function createTabButton(name, sizeScale, positionScale)
	local btn = Instance.new("TextButton")
	btn.Size = sizeScale
	btn.Position = positionScale
	btn.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
	btn.TextColor3 = Color3.fromRGB(140, 140, 155)
	btn.TextSize = 10
	btn.Font = Enum.Font.GothamBold
	btn.Text = name
	btn.Parent = tabContainer
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = btn
	return btn
end

local tabWidth = UDim2.new(0.1666, -2, 1, 0)
local playersTabBtn  = createTabButton("Players",  tabWidth, UDim2.new(0.0,    1, 0, 0))
playersTabBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
playersTabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
local movementTabBtn = createTabButton("Movement", tabWidth, UDim2.new(0.1666, 1, 0, 0))
local combatTabBtn   = createTabButton("Combat",   tabWidth, UDim2.new(0.3332, 1, 0, 0))
local visualsTabBtn  = createTabButton("Visuals",  tabWidth, UDim2.new(0.4998, 1, 0, 0))
local utilityTabBtn  = createTabButton("Utility",  tabWidth, UDim2.new(0.6664, 1, 0, 0))
local creditsTabBtn  = createTabButton("Credits",  tabWidth, UDim2.new(0.8330, 1, 0, 0))

local pagesContainer = Instance.new("Frame")
pagesContainer.Size = UDim2.new(1, -20, 1, -100)
pagesContainer.Position = UDim2.new(0, 10, 0, 94)
pagesContainer.BackgroundTransparency = 1
pagesContainer.Parent = mainFrame

local scrollingFrame = Instance.new("ScrollingFrame")
scrollingFrame.Size = UDim2.new(1, 0, 1, 0)
scrollingFrame.BackgroundTransparency = 1
scrollingFrame.BorderSizePixel = 0
scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollingFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
scrollingFrame.ScrollBarThickness = 4
scrollingFrame.ScrollBarImageColor3 = Color3.fromRGB(60, 60, 75)
scrollingFrame.Visible = true
scrollingFrame.Parent = pagesContainer

local uiListLayout = Instance.new("UIListLayout")
uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
uiListLayout.Padding = UDim.new(0, 6)
uiListLayout.Parent = scrollingFrame

local function createCategoryHeader(parentPage, titleText)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 22)
	label.BackgroundTransparency = 1
	label.Text = titleText
	label.TextColor3 = Color3.fromRGB(0, 162, 255)
	label.TextSize = 12
	label.Font = Enum.Font.GothamBold
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = parentPage
end

local function createToggleRow(parent, name, callback, defaultState)
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 0, 42)
	frame.BackgroundColor3 = Color3.fromRGB(26, 26, 33)
	frame.Parent = parent
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0.6, 0, 1, 0)
	label.Position = UDim2.new(0, 12, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = name
	label.TextColor3 = Color3.fromRGB(220, 220, 225)
	label.TextSize = 13
	label.Font = Enum.Font.GothamMedium
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = frame

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 80, 0, 26)
	btn.Position = UDim2.new(1, -92, 0.5, -13)
	btn.BackgroundColor3 = defaultState and Color3.fromRGB(0, 162, 255) or Color3.fromRGB(45, 45, 55)
	btn.TextColor3 = Color3.fromRGB(200, 200, 210)
	btn.TextSize = 12
	btn.Font = Enum.Font.GothamBold
	btn.Text = defaultState and "ON" or "OFF"
	btn.Parent = frame
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

	btn.MouseButton1Click:Connect(function()
		local active = btn.Text == "OFF"
		btn.Text = active and "ON" or "OFF"
		btn.BackgroundColor3 = active and Color3.fromRGB(0, 162, 255) or Color3.fromRGB(45, 45, 55)
		safe(callback, active)
	end)
	return btn
end

local function createSliderRow(parent, name, initialValue, step, minV, maxV, suffix, onChange)
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 0, 60)
	frame.BackgroundColor3 = Color3.fromRGB(26, 26, 33)
	frame.Parent = parent
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

	local value = initialValue
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -24, 0, 22)
	label.Position = UDim2.new(0, 12, 0, 5)
	label.BackgroundTransparency = 1
	label.Text = name .. ": " .. tostring(value) .. (suffix or "")
	label.TextColor3 = Color3.fromRGB(220, 220, 225)
	label.TextSize = 13
	label.Font = Enum.Font.GothamMedium
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = frame

	local sub = Instance.new("TextButton")
	sub.Size = UDim2.new(0, 40, 0, 24)
	sub.Position = UDim2.new(0, 12, 0, 28)
	sub.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
	sub.TextColor3 = Color3.fromRGB(255, 255, 255)
	sub.Text = "-"
	sub.TextSize = 11
	sub.Font = Enum.Font.GothamBold
	sub.Parent = frame
	Instance.new("UICorner", sub).CornerRadius = UDim.new(0, 5)

	local add = Instance.new("TextButton")
	add.Size = UDim2.new(0, 40, 0, 24)
	add.Position = UDim2.new(0, 58, 0, 28)
	add.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
	add.TextColor3 = Color3.fromRGB(255, 255, 255)
	add.Text = "+"
	add.TextSize = 11
	add.Font = Enum.Font.GothamBold
	add.Parent = frame
	Instance.new("UICorner", add).CornerRadius = UDim.new(0, 5)

	sub.MouseButton1Click:Connect(function()
		value = math.clamp(value - step, minV, maxV)
		label.Text = name .. ": " .. tostring(value) .. (suffix or "")
		safe(onChange, value)
	end)
	add.MouseButton1Click:Connect(function()
		value = math.clamp(value + step, minV, maxV)
		label.Text = name .. ": " .. tostring(value) .. (suffix or "")
		safe(onChange, value)
	end)
	return label
end

-- ============== MOVEMENT PAGE ==============
local movementPage = Instance.new("ScrollingFrame")
movementPage.Size = UDim2.new(1, 0, 1, 0)
movementPage.BackgroundTransparency = 1
movementPage.BorderSizePixel = 0
movementPage.AutomaticCanvasSize = Enum.AutomaticSize.Y
movementPage.ScrollBarThickness = 4
movementPage.Visible = false
movementPage.Parent = pagesContainer

local mList = Instance.new("UIListLayout")
mList.SortOrder = Enum.SortOrder.LayoutOrder
mList.Padding = UDim.new(0, 10)
mList.Parent = movementPage

createCategoryHeader(movementPage, "FLIGHT SYSTEM")

createToggleRow(movementPage, "Superman Flight (E)", function(state)
	local character = localPlayer.Character
	if not character then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root then return end

	flying = state
	if flying then
		if flyPart then flyPart.CFrame = root.CFrame end
	else
		equipFunctionActive = false
		if loadIdle1 then loadIdle1:Stop() end
		if loadIdle2 then loadIdle2:Stop() end
		if loadFly then loadFly:Stop() end

		local Enums = Enum.HumanoidStateType:GetEnumItems()
		table.remove(Enums, table.find(Enums, Enum.HumanoidStateType.None))
		for _, v in pairs(Enums) do humanoid:SetStateEnabled(v, true) end
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall, true)
		humanoid.AutoRotate = true
		root.Velocity = Vector3.zero
		root.RotVelocity = Vector3.zero
		if character:FindFirstChild("Animate") then character.Animate.Enabled = true end
	end
end)

createSliderRow(movementPage, "Flight Speed", 1, 0.5, 0.5, 10, "", function(v) flySpeed = v end)
createSliderRow(movementPage, "Super Jump Power", 35, 5, 10, 150, "", function(v) superJumpPower = v end)
createSliderRow(movementPage, "WalkSpeed", 16, 25, 8, 365, "", function(v)
	customWalkSpeed = v
	local char = localPlayer.Character
	if char and walkSpeedToggled then
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then hum.WalkSpeed = customWalkSpeed end
	end
end)
createSliderRow(movementPage, "Jump Power", 50, 10, 10, 500, "", function(v)
	customJumpPower = v
	local char = localPlayer.Character
	if char and jumpPowerToggled then
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then hum.JumpPower = customJumpPower end
	end
end)

createCategoryHeader(movementPage, "MOVEMENT UTILITY")

createToggleRow(movementPage, "Infinite Jump", function(state)
	if state then
		infiniteJumpConnection = UserInputService.JumpRequest:Connect(function()
			local char = localPlayer.Character
			if char then
				local hum = char:FindFirstChildOfClass("Humanoid")
				if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
			end
		end)
	else
		if infiniteJumpConnection then
			infiniteJumpConnection:Disconnect()
			infiniteJumpConnection = nil
		end
	end
end)

createToggleRow(movementPage, "Noclip", function(state)
	noclipEnabled = state
	if state then
		noclipConnection = RunService.Stepped:Connect(function()
			local char = localPlayer.Character
			if char then
				for _, part in ipairs(char:GetDescendants()) do
					if part:IsA("BasePart") then part.CanCollide = false end
				end
			end
		end)
	else
		if noclipConnection then noclipConnection:Disconnect() noclipConnection = nil end
		local char = localPlayer.Character
		if char then
			for _, part in ipairs(char:GetDescendants()) do
				if part:IsA("BasePart") then part.CanCollide = true end
			end
		end
	end
end)

createToggleRow(movementPage, "Anti-Fling", function(state) antiFlingEnabled = state end)
createToggleRow(movementPage, "Auto Sprint", function(state)
	autoSprintEnabled = state
	if state then
		autoSprintConnection = RunService.RenderStepped:Connect(function()
			local char = localPlayer.Character
			if char then
				local hum = char:FindFirstChildOfClass("Humanoid")
				if hum and hum.MoveDirection.Magnitude > 0 then
					hum.WalkSpeed = customWalkSpeed + 10
				end
			end
		end)
	else
		if autoSprintConnection then autoSprintConnection:Disconnect() autoSprintConnection = nil end
	end
end)
createToggleRow(movementPage, "Hover Fly Vertical", function(state) hoverEnabled = state end)
createToggleRow(movementPage, "Freeze Player", function(state)
	freezeEnabled = state
	local char = localPlayer.Character
	if char then
		local root = char:FindFirstChild("HumanoidRootPart")
		if root then root.Anchored = state end
	end
end)
createToggleRow(movementPage, "Anti-Void", function(state)
	antiVoidEnabled = state
	if state then
		antiVoidConnection = RunService.Heartbeat:Connect(function()
			local char = localPlayer.Character
			if char then
				local root = char:FindFirstChild("HumanoidRootPart")
				if root and root.Position.Y < -50 then
					root.CFrame = CFrame.new(root.Position.X, 50, root.Position.Z)
				end
			end
		end)
	else
		if antiVoidConnection then antiVoidConnection:Disconnect() antiVoidConnection = nil end
	end
end)

-- ============== COMBAT PAGE ==============
local combatPage = Instance.new("ScrollingFrame")
combatPage.Size = UDim2.new(1, 0, 1, 0)
combatPage.BackgroundTransparency = 1
combatPage.BorderSizePixel = 0
combatPage.AutomaticCanvasSize = Enum.AutomaticSize.Y
combatPage.ScrollBarThickness = 4
combatPage.Visible = false
combatPage.Parent = pagesContainer

local cList = Instance.new("UIListLayout")
cList.SortOrder = Enum.SortOrder.LayoutOrder
cList.Padding = UDim.new(0, 10)
cList.Parent = combatPage

createCategoryHeader(combatPage, "CAMLOCK AIMBOT")
createToggleRow(combatPage, "Camlock Aimbot (T)", function(state)
	targetLockEnabled = state
	if state then
		targetLockConnection = RunService.RenderStepped:Connect(function(dt)
			local target = getClosestPlayerToCursor()
			if target and target.Character then
				local targetHead = target.Character:FindFirstChild("Head")
				if targetHead then
					local currentPos = camera.CFrame.Position
					local targetCF = CFrame.new(currentPos, targetHead.Position)
					local alpha = math.clamp(dt * camlockSmoothness * (camlockSnappiness * 0.4), 0, 1)
					camera.CFrame = camera.CFrame:Lerp(targetCF, alpha)
				end
			end
		end)
	else
		if targetLockConnection then targetLockConnection:Disconnect() targetLockConnection = nil end
	end
end)
createSliderRow(combatPage, "Camlock Smoothness", 12, 2, 2, 50, "", function(v) camlockSmoothness = v end)
createSliderRow(combatPage, "Camlock Snappiness", 8, 1, 1, 20, "", function(v) camlockSnappiness = v end)

createCategoryHeader(combatPage, "SPINBOT")
createToggleRow(combatPage, "Spinbot", function(state)
	spinbotEnabled = state
	if state then
		spinbotConnection = RunService.RenderStepped:Connect(function(dt)
			local char = localPlayer.Character
			if not char then return end
			local root = char:FindFirstChild("HumanoidRootPart")
			if not root then return end
			local spinAmount = math.rad(spinbotSpeed * 60) * dt
			root.CFrame = root.CFrame * CFrame.Angles(0, spinAmount, 0)
		end)
	else
		if spinbotConnection then spinbotConnection:Disconnect() spinbotConnection = nil end
	end
end)
createSliderRow(combatPage, "Spin Speed", 15, 5, 5, 100, "", function(v) spinbotSpeed = v end)

createCategoryHeader(combatPage, "HITBOX EXPANDER")
createSliderRow(combatPage, "Hitbox Size", 10, 5, 5, 100, "", function(v)
	hitboxSize = v
	if hitboxEnabled then
		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= localPlayer and player.Character then
				local hrp = player.Character:FindFirstChild("HumanoidRootPart")
				if hrp then hrp.Size = Vector3.new(hitboxSize, hitboxSize, hitboxSize) end
			end
		end
	end
end)
createToggleRow(combatPage, "Enable Hitbox Expander", function(state)
	hitboxEnabled = state
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= localPlayer and player.Character then
			local hrp = player.Character:FindFirstChild("HumanoidRootPart")
			if hrp then
				if state then
					hrp.Size = Vector3.new(hitboxSize, hitboxSize, hitboxSize)
					hrp.Transparency = 0.5
					hrp.CanCollide = false
				else
					hrp.Size = Vector3.new(2, 2, 1)
					hrp.Transparency = 1
				end
			end
		end
	end
end)

-- ============== VISUALS PAGE ==============
local visualsPage = Instance.new("ScrollingFrame")
visualsPage.Size = UDim2.new(1, 0, 1, 0)
visualsPage.BackgroundTransparency = 1
visualsPage.BorderSizePixel = 0
visualsPage.AutomaticCanvasSize = Enum.AutomaticSize.Y
visualsPage.ScrollBarThickness = 4
visualsPage.Visible = false
visualsPage.Parent = pagesContainer

local vList = Instance.new("UIListLayout")
vList.SortOrder = Enum.SortOrder.LayoutOrder
vList.Padding = UDim.new(0, 10)
vList.Parent = visualsPage

createCategoryHeader(visualsPage, "PLAYER ESP")
if hasDrawing then
	createToggleRow(visualsPage, "Tracers", function(state) tracersEnabled = state end)
	createToggleRow(visualsPage, "Tracers Follow Mouse", function(state) tracerFollowMouse = state end)
	createToggleRow(visualsPage, "2D Box ESP", function(state) boxEspEnabled = state end)
	createToggleRow(visualsPage, "Skeleton ESP", function(state) skeletonEnabled = state end)
	createToggleRow(visualsPage, "Name ESP", function(state) nameEspEnabled = state end)
	createToggleRow(visualsPage, "Distance Indicators", function(state) distanceEnabled = state end)
	createToggleRow(visualsPage, "Health Bar ESP", function(state) healthEspEnabled = state end)
else
	local warnLabel = Instance.new("TextLabel")
	warnLabel.Size = UDim2.new(1, 0, 0, 30)
	warnLabel.BackgroundTransparency = 1
	warnLabel.Text = "⚠ Drawing library not supported by this executor"
	warnLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
	warnLabel.TextSize = 12
	warnLabel.Font = Enum.Font.GothamMedium
	warnLabel.Parent = visualsPage
end

createCategoryHeader(visualsPage, "WORLD VISUALS")
createToggleRow(visualsPage, "Fullbright", function(state)
	fullbrightEnabled = state
	if state then
		fullbrightPrev.Ambient = Lighting.Ambient
		fullbrightPrev.OutdoorAmbient = Lighting.OutdoorAmbient
		fullbrightPrev.Brightness = Lighting.Brightness
		fullbrightPrev.ClockTime = Lighting.ClockTime
		Lighting.Ambient = Color3.fromRGB(255, 255, 255)
		Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
		Lighting.Brightness = 3
		Lighting.ClockTime = 12
	else
		if fullbrightPrev.Ambient then
			Lighting.Ambient = fullbrightPrev.Ambient
			Lighting.OutdoorAmbient = fullbrightPrev.OutdoorAmbient
			Lighting.Brightness = fullbrightPrev.Brightness
			Lighting.ClockTime = fullbrightPrev.ClockTime
		end
	end
end)
createToggleRow(visualsPage, "No Fog", function(state)
	noFogEnabled = state
	if state then
		fogPrev = {Lighting.FogEnd, Lighting.FogStart, Lighting.FogColor}
		Lighting.FogEnd = 100000
		Lighting.FogStart = 100000
	else
		if fogPrev then
			Lighting.FogEnd = fogPrev[1]
			Lighting.FogStart = fogPrev[2]
			Lighting.FogColor = fogPrev[3]
		end
	end
end)
createSliderRow(visualsPage, "Camera FOV", 70, 10, 20, 120, "", function(v)
	cameraFov = v
	if cameraFovEnabled then camera.FieldOfView = v end
end)
createToggleRow(visualsPage, "Custom Camera FOV", function(state)
	cameraFovEnabled = state
	if state then camera.FieldOfView = cameraFov else camera.FieldOfView = 70 end
end)

createCategoryHeader(visualsPage, "UI / HUD")
createToggleRow(visualsPage, "Crosshair", function(state)
	crosshairEnabled = state
	if state then createCrosshair()
	else if crosshairGui then crosshairGui:Destroy() crosshairGui = nil end end
end)
createToggleRow(visualsPage, "Watermark", function(state)
	watermarkEnabled = state
	if watermarkGui then watermarkGui.Visible = state end
end, true)

-- ============== UTILITY PAGE ==============
local utilityPage = Instance.new("ScrollingFrame")
utilityPage.Size = UDim2.new(1, 0, 1, 0)
utilityPage.BackgroundTransparency = 1
utilityPage.BorderSizePixel = 0
utilityPage.AutomaticCanvasSize = Enum.AutomaticSize.Y
utilityPage.ScrollBarThickness = 4
utilityPage.Visible = false
utilityPage.Parent = pagesContainer

local uList = Instance.new("UIListLayout")
uList.SortOrder = Enum.SortOrder.LayoutOrder
uList.Padding = UDim.new(0, 10)
uList.Parent = utilityPage

createCategoryHeader(utilityPage, "PLAYER UTILITIES")
createToggleRow(utilityPage, "Click Teleport", function(state) clickTeleportEnabled = state end)
createToggleRow(utilityPage, "Auto Reset On Low HP", function(state) autoResetEnabled = state end)
createToggleRow(utilityPage, "Auto Rejoin On Death", function(state) autoRejoinEnabled = state end)
createToggleRow(utilityPage, "Anti-AFK", function(state)
	antiAfkEnabled = state
	if state then
		antiAfkConnection = localPlayer.Idled:Connect(function()
			local vu = game:GetService("VirtualUser")
			vu:CaptureController()
			vu:ClickButton2(Vector2.new())
		end)
	else
		if antiAfkConnection then antiAfkConnection:Disconnect() antiAfkConnection = nil end
	end
end)
createToggleRow(utilityPage, "Fake Lag", function(state) fakeLagEnabled = state end)
createSliderRow(utilityPage, "Fake Lag Amount", 5, 5, 5, 100, "", function(v) fakeLagAmount = v end)

createCategoryHeader(utilityPage, "SERVER")
local rejoinBtn = Instance.new("TextButton")
rejoinBtn.Size = UDim2.new(1, 0, 0, 36)
rejoinBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
rejoinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
rejoinBtn.TextSize = 12
rejoinBtn.Font = Enum.Font.GothamBold
rejoinBtn.Text = "Rejoin Server"
rejoinBtn.Parent = utilityPage
Instance.new("UICorner", rejoinBtn).CornerRadius = UDim.new(0, 8)
rejoinBtn.MouseButton1Click:Connect(function()
	TeleportService:Teleport(game.PlaceId, localPlayer)
end)

local serverHopBtn = Instance.new("TextButton")
serverHopBtn.Size = UDim2.new(1, 0, 0, 36)
serverHopBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
serverHopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
serverHopBtn.TextSize = 12
serverHopBtn.Font = Enum.Font.GothamBold
serverHopBtn.Text = "Server Hop"
serverHopBtn.Parent = utilityPage
Instance.new("UICorner", serverHopBtn).CornerRadius = UDim.new(0, 8)
serverHopBtn.MouseButton1Click:Connect(function()
	safe(function()
		local result = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"))
		if result and result.data then
			for _, server in ipairs(result.data) do
				if server.playing < server.maxPlayers and server.id ~= game.JobId then
					TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, localPlayer)
					return
				end
			end
		end
	end)
end)

-- ============== CREDITS PAGE ==============
local creditsPage = Instance.new("Frame")
creditsPage.Size = UDim2.new(1, 0, 1, 0)
creditsPage.BackgroundTransparency = 1
creditsPage.Visible = false
creditsPage.Parent = pagesContainer

local creditsTitle = Instance.new("TextLabel")
creditsTitle.Size = UDim2.new(1, 0, 0, 30)
creditsTitle.BackgroundTransparency = 1
creditsTitle.Text = "Advanced Player Manager Hub"
creditsTitle.TextColor3 = Color3.fromRGB(0, 162, 255)
creditsTitle.TextSize = 18
creditsTitle.Font = Enum.Font.GothamBold
creditsTitle.TextXAlignment = Enum.TextXAlignment.Center
creditsTitle.Parent = creditsPage

local creditsText = Instance.new("TextLabel")
creditsText.Size = UDim2.new(1, -20, 0, 260)
creditsText.Position = UDim2.new(0, 10, 0, 50)
creditsText.BackgroundTransparency = 1
creditsText.Text = "Developed by C4N0Fz & @kp3g\n\nFEATURES:\n• Superman Flight with custom animations\n• Camlock Aimbot\n• Spinbot & Hitbox Expander\n• ESP Suite (Tracers, Box, Skeleton, Name, Distance, Health)\n• Movement: Super Jump, Infinite Jump, Noclip, Auto Sprint\n• Utility: Anti-Fling, Anti-Void, Freeze, Fake Lag\n• HUDs: Watermark, Crosshair\n• Server: Rejoin & Server Hop"
creditsText.TextColor3 = Color3.fromRGB(200, 200, 210)
creditsText.TextSize = 13
creditsText.Font = Enum.Font.GothamMedium
creditsText.TextWrapped = true
creditsText.TextXAlignment = Enum.TextXAlignment.Left
creditsText.TextYAlignment = Enum.TextYAlignment.Top
creditsText.Parent = creditsPage

-- ============== TAB SWITCHING ==============
local function switchTab(activeTab)
	scrollingFrame.Visible = (activeTab == "Players")
	movementPage.Visible = (activeTab == "Movement")
	combatPage.Visible = (activeTab == "Combat")
	visualsPage.Visible = (activeTab == "Visuals")
	utilityPage.Visible = (activeTab == "Utility")
	creditsPage.Visible = (activeTab == "Credits")

	local tabs = {
		{playersTabBtn, "Players"},
		{movementTabBtn, "Movement"},
		{combatTabBtn, "Combat"},
		{visualsTabBtn, "Visuals"},
		{utilityTabBtn, "Utility"},
		{creditsTabBtn, "Credits"},
	}
	for _, t in ipairs(tabs) do
		t[1].BackgroundColor3 = activeTab == t[2] and Color3.fromRGB(35, 35, 45) or Color3.fromRGB(20, 20, 25)
		t[1].TextColor3 = activeTab == t[2] and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(140, 140, 155)
	end
end

playersTabBtn.MouseButton1Click:Connect(function() switchTab("Players") end)
movementTabBtn.MouseButton1Click:Connect(function() switchTab("Movement") end)
combatTabBtn.MouseButton1Click:Connect(function() switchTab("Combat") end)
visualsTabBtn.MouseButton1Click:Connect(function() switchTab("Visuals") end)
utilityTabBtn.MouseButton1Click:Connect(function() switchTab("Utility") end)
creditsTabBtn.MouseButton1Click:Connect(function() switchTab("Credits") end)

-- ============== FUNCTIONS ==============
function getClosestPlayerToCursor()
	local mousePos = UserInputService:GetMouseLocation()
	local ray = camera:ViewportPointToRay(mousePos.X, mousePos.Y)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = {localPlayer.Character}
	local result = Workspace:Raycast(ray.Origin, ray.Direction * 100000, raycastParams)
	if result and result.Instance then
		local character = result.Instance:FindFirstAncestorOfClass("Model")
		if character then
			local targetPlayer = Players:GetPlayerFromCharacter(character)
			if targetPlayer and targetPlayer ~= localPlayer then
				return targetPlayer
			end
		end
	end
	local closestPlayer = nil
	local shortestDistance = 300
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= localPlayer and player.Character then
			local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
			local head = player.Character:FindFirstChild("Head")
			if humanoid and humanoid.Health > 0 and head then
				local screenPos, onScreen = camera:WorldToViewportPoint(head.Position)
				if onScreen then
					local distance = (Vector2.new(mousePos.X, mousePos.Y) - Vector2.new(screenPos.X, screenPos.Y)).Magnitude
					if distance < shortestDistance then
						shortestDistance = distance
						closestPlayer = player
					end
				end
			end
		end
	end
	return closestPlayer
end

local function triggerSuperJump()
	local character = localPlayer.Character
	if not character then return end
	local root = character:FindFirstChild("HumanoidRootPart")
	if root then
		local impulseForce = Vector3.new(0, superJumpPower * 35, 0)
		if root.AssemblyMass and root.AssemblyMass > 0 then
			root:ApplyImpulse(impulseForce)
		else
			root.Velocity = root.Velocity + Vector3.new(0, superJumpPower, 0)
		end
	end
end

-- Highlight / player list
local function updateHighlights()
	for _, highlight in pairs(activeHighlights) do highlight:Destroy() end
	activeHighlights = {}
	for _, player in ipairs(highlightedPlayers) do
		if player and player.Character then
			local highlight = Instance.new("Highlight")
			highlight.Name = "MultiPlayerHighlight"
			highlight.Adornee = player.Character
			highlight.FillColor = espColor
			highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
			highlight.FillTransparency = 0.5
			highlight.Parent = player.Character
			activeHighlights[player] = highlight
		end
	end
end

local function toggleHighlight(player)
	local index = table.find(highlightedPlayers, player)
	if index then table.remove(highlightedPlayers, index) else table.insert(highlightedPlayers, player) end
	updateHighlights()
end

local function updatePlayerList()
	for _, child in ipairs(scrollingFrame:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= localPlayer then
			local itemFrame = Instance.new("Frame")
			itemFrame.Size = UDim2.new(1, 0, 0, 44)
			itemFrame.BackgroundColor3 = Color3.fromRGB(26, 26, 33)
			itemFrame.BorderSizePixel = 0
			itemFrame.Parent = scrollingFrame
			Instance.new("UICorner", itemFrame).CornerRadius = UDim.new(0, 8)

			local nameLabel = Instance.new("TextLabel")
			nameLabel.Size = UDim2.new(1, -110, 1, 0)
			nameLabel.Position = UDim2.new(0, 10, 0, 0)
			nameLabel.BackgroundTransparency = 1
			nameLabel.Text = player.Name
			nameLabel.TextColor3 = Color3.fromRGB(220, 220, 225)
			nameLabel.TextSize = 13
			nameLabel.Font = Enum.Font.GothamMedium
			nameLabel.TextXAlignment = Enum.TextXAlignment.Left
			nameLabel.Parent = itemFrame

			local tpButton = Instance.new("TextButton")
			tpButton.Size = UDim2.new(0, 42, 0, 26)
			tpButton.Position = UDim2.new(1, -100, 0.5, -13)
			tpButton.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
			tpButton.TextColor3 = Color3.fromRGB(255, 255, 255)
			tpButton.TextSize = 11
			tpButton.Font = Enum.Font.GothamBold
			tpButton.Text = "TP"
			tpButton.Parent = itemFrame
			Instance.new("UICorner", tpButton).CornerRadius = UDim.new(0, 5)

			local hlButton = Instance.new("TextButton")
			hlButton.Size = UDim2.new(0, 42, 0, 26)
			hlButton.Position = UDim2.new(1, -54, 0.5, -13)
			local isHighlighted = table.find(highlightedPlayers, player) ~= nil
			hlButton.BackgroundColor3 = isHighlighted and Color3.fromRGB(0, 162, 255) or Color3.fromRGB(45, 45, 55)
			hlButton.TextColor3 = Color3.fromRGB(200, 200, 210)
			hlButton.TextSize = 11
			hlButton.Font = Enum.Font.GothamBold
			hlButton.Text = "ESP"
			hlButton.Parent = itemFrame
			Instance.new("UICorner", hlButton).CornerRadius = UDim.new(0, 5)

			tpButton.MouseButton1Click:Connect(function()
				local targetChar = player.Character
				local localChar = localPlayer.Character
				if targetChar and targetChar:FindFirstChild("HumanoidRootPart") and localChar and localChar:FindFirstChild("HumanoidRootPart") then
					localChar.HumanoidRootPart.CFrame = targetChar.HumanoidRootPart.CFrame + Vector3.new(0, 3, 0)
					mainFrame.Visible = false
				end
			end)
			hlButton.MouseButton1Click:Connect(function()
				toggleHighlight(player)
				updatePlayerList()
			end)
		end
	end
end

updatePlayerList()

Players.PlayerAdded:Connect(updatePlayerList)
Players.PlayerRemoving:Connect(function(player)
	local index = table.find(highlightedPlayers, player)
	if index then table.remove(highlightedPlayers, index) end
	if espDrawings[player] then
		for _, obj in pairs(espDrawings[player]) do
			if typeof(obj) == "table" then
				for _, line in pairs(obj) do pcall(function() line:Remove() end) end
			else
				pcall(function() obj:Remove() end)
			end
		end
		espDrawings[player] = nil
	end
	updatePlayerList()
end)

local skeletonPairs = {
	{"Head", "UpperTorso"},
	{"UpperTorso", "LowerTorso"},
	{"UpperTorso", "LeftUpperArm"},
	{"LeftUpperArm", "LeftLowerArm"},
	{"LeftLowerArm", "LeftHand"},
	{"UpperTorso", "RightUpperArm"},
	{"RightUpperArm", "RightLowerArm"},
	{"RightLowerArm", "RightHand"},
	{"LowerTorso", "LeftUpperLeg"},
	{"LeftUpperLeg", "LeftLowerLeg"},
	{"LeftLowerLeg", "LeftFoot"},
	{"LowerTorso", "RightUpperLeg"},
	{"RightUpperLeg", "RightLowerLeg"},
	{"RightLowerLeg", "RightFoot"}
}

-- Click teleport
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if clickTeleportEnabled and input.UserInputType == Enum.UserInputType.MouseButton1 then
		local mousePos = UserInputService:GetMouseLocation()
		local ray = camera:ViewportPointToRay(mousePos.X, mousePos.Y)
		local result = Workspace:Raycast(ray.Origin, ray.Direction * 10000)
		if result then
			local char = localPlayer.Character
			if char then
				local root = char:FindFirstChild("HumanoidRootPart")
				if root then
					root.CFrame = CFrame.new(result.Position + Vector3.new(0, 3, 0))
				end
			end
		end
	end
end)

RunService.Heartbeat:Connect(function()
	if antiFlingEnabled then
		local char = localPlayer.Character
		if char then
			local root = char:FindFirstChild("HumanoidRootPart")
			if root then
				if root.Velocity.Magnitude > 500 then root.Velocity = Vector3.zero end
				if root.RotVelocity.Magnitude > 50 then root.RotVelocity = Vector3.zero end
			end
		end
	end
	if autoResetEnabled then
		local char = localPlayer.Character
		if char then
			local hum = char:FindFirstChildOfClass("Humanoid")
			if hum and hum.Health > 0 and hum.Health < hum.MaxHealth * 0.2 then
				char:BreakJoints()
			end
		end
	end
	if freezeEnabled then
		local char = localPlayer.Character
		if char then
			local root = char:FindFirstChild("HumanoidRootPart")
			if root and not root.Anchored then root.Anchored = true end
		end
	end
end)

local fakeLagLastUpdate = 0
RunService.Heartbeat:Connect(function(dt)
	if fakeLagEnabled then
		fakeLagLastUpdate = fakeLagLastUpdate + dt
		if fakeLagLastUpdate < (fakeLagAmount / 100) then
			local char = localPlayer.Character
			if char then
				local root = char:FindFirstChild("HumanoidRootPart")
				if root then root.Anchored = true end
			end
		else
			fakeLagLastUpdate = 0
			local char = localPlayer.Character
			if char then
				local root = char:FindFirstChild("HumanoidRootPart")
				if root and not freezeEnabled then root.Anchored = false end
			end
		end
	end
end)

localPlayer.CharacterAdded:Connect(function()
	if autoRejoinEnabled then
		task.wait(1)
		TeleportService:Teleport(game.PlaceId, localPlayer)
	end
end)

-- Main loop
RunService.RenderStepped:Connect(function(dt)
	updateHighlights()

	local localChar = localPlayer.Character
	if localChar then
		local hum = localChar:FindFirstChildOfClass("Humanoid")
		local targetSpeed = walkSpeedToggled and customWalkSpeed or 20
		if hum and hum.WalkSpeed ~= targetSpeed and not flying and not autoSprintEnabled then
			hum.WalkSpeed = targetSpeed
		end
		local targetJump = jumpPowerToggled and customJumpPower or 50
		if hum and hum.JumpPower ~= targetJump and not flying then
			hum.JumpPower = targetJump
		end
	end

	if hasDrawing then
		local tracerOrigin = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)
		if tracerFollowMouse then
			local mouseLocation = UserInputService:GetMouseLocation()
			tracerOrigin = Vector2.new(mouseLocation.X, mouseLocation.Y)
		end

		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= localPlayer then
				if not espDrawings[player] then
					espDrawings[player] = {
						Tracer = Drawing.new("Line"),
						Box = Drawing.new("Square"),
						Name = Drawing.new("Text"),
						Distance = Drawing.new("Text"),
						HealthBar = Drawing.new("Square"),
						HealthText = Drawing.new("Text"),
						Skeleton = {}
					}
					for i = 1, #skeletonPairs do
						local line = Drawing.new("Line")
						line.Visible = false
						line.Thickness = 1.5
						espDrawings[player].Skeleton[i] = line
					end
					espDrawings[player].Tracer.Visible = false
					espDrawings[player].Tracer.Thickness = 1.5
					espDrawings[player].Box.Visible = false
					espDrawings[player].Box.Filled = false
					espDrawings[player].Box.Thickness = 1.5
					espDrawings[player].Name.Visible = false
					espDrawings[player].Name.Size = 13
					espDrawings[player].Name.Center = true
					espDrawings[player].Name.Outline = true
					espDrawings[player].Distance.Visible = false
					espDrawings[player].Distance.Size = 13
					espDrawings[player].Distance.Center = true
					espDrawings[player].Distance.Outline = true
					espDrawings[player].HealthBar.Visible = false
					espDrawings[player].HealthBar.Filled = true
					espDrawings[player].HealthText.Visible = false
					espDrawings[player].HealthText.Size = 12
					espDrawings[player].HealthText.Center = true
					espDrawings[player].HealthText.Outline = true
				end

				local drawings = espDrawings[player]
				local character = player.Character
				local rootPart = character and character:FindFirstChild("HumanoidRootPart")
				local humanoid = character and character:FindFirstChildOfClass("Humanoid")

				if character and rootPart and humanoid and humanoid.Health > 0 then
					local vector, onScreen = camera:WorldToViewportPoint(rootPart.Position)
					if onScreen then
						local headPart = character:FindFirstChild("Head")
						local topVector = headPart and camera:WorldToViewportPoint(headPart.Position + Vector3.new(0, 0.5, 0)) or vector
						local legVector = camera:WorldToViewportPoint(rootPart.Position - Vector3.new(0, 3, 0))
						local height = math.abs(topVector.Y - legVector.Y)
						local width = height / 2

						if boxEspEnabled then
							drawings.Box.Visible = true
							drawings.Box.Size = Vector2.new(width, height)
							drawings.Box.Position = Vector2.new(vector.X - width / 2, topVector.Y)
							drawings.Box.Color = espColor
						else drawings.Box.Visible = false end

						if nameEspEnabled then
							drawings.Name.Visible = true
							drawings.Name.Text = player.DisplayName or player.Name
							drawings.Name.Position = Vector2.new(vector.X, legVector.Y + 4)
							drawings.Name.Color = espColor
						else drawings.Name.Visible = false end

						if distanceEnabled then
							local localRoot = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
							if localRoot then
								local dist = math.floor((localRoot.Position - rootPart.Position).Magnitude)
								drawings.Distance.Visible = true
								drawings.Distance.Text = "[" .. dist .. "m]"
								drawings.Distance.Position = Vector2.new(vector.X, (nameEspEnabled and legVector.Y + 18 or legVector.Y + 4))
								drawings.Distance.Color = espColor
							else drawings.Distance.Visible = false end
						else drawings.Distance.Visible = false end

						if healthEspEnabled then
							local hp = humanoid.Health / humanoid.MaxHealth
							local barHeight = height
							drawings.HealthBar.Visible = true
							drawings.HealthBar.Size = Vector2.new(3, barHeight * hp)
							drawings.HealthBar.Position = Vector2.new(vector.X - width/2 - 6, topVector.Y + barHeight * (1 - hp))
							drawings.HealthBar.Color = Color3.fromRGB(0, 255, 0):Lerp(Color3.fromRGB(255, 0, 0), 1 - hp)
							drawings.HealthText.Visible = true
							drawings.HealthText.Text = math.floor(humanoid.Health) .. "/" .. math.floor(humanoid.MaxHealth)
							drawings.HealthText.Position = Vector2.new(vector.X, topVector.Y - 16)
							drawings.HealthText.Color = Color3.fromRGB(255, 255, 255)
						else
							drawings.HealthBar.Visible = false
							drawings.HealthText.Visible = false
						end

						if tracersEnabled then
							drawings.Tracer.Visible = true
							drawings.Tracer.From = tracerOrigin
							drawings.Tracer.To = Vector2.new(vector.X, legVector.Y)
							drawings.Tracer.Color = espColor
						else drawings.Tracer.Visible = false end

						if skeletonEnabled then
							for i, pair in ipairs(skeletonPairs) do
								local partA = character:FindFirstChild(pair[1])
								local partB = character:FindFirstChild(pair[2])
								local line = drawings.Skeleton[i]
								if partA and partB and line then
									local posA, onA = camera:WorldToViewportPoint(partA.Position)
									local posB, onB = camera:WorldToViewportPoint(partB.Position)
									if onA or onB then
										line.Visible = true
										line.From = Vector2.new(posA.X, posA.Y)
										line.To = Vector2.new(posB.X, posB.Y)
										line.Color = espColor
									else line.Visible = false end
								else if line then line.Visible = false end end
							end
						else
							for _, line in pairs(drawings.Skeleton) do line.Visible = false end
						end
					else
						drawings.Tracer.Visible = false
						drawings.Box.Visible = false
						drawings.Name.Visible = false
						drawings.Distance.Visible = false
						drawings.HealthBar.Visible = false
						drawings.HealthText.Visible = false
						for _, line in pairs(drawings.Skeleton) do line.Visible = false end
					end
				else
					drawings.Tracer.Visible = false
					drawings.Box.Visible = false
					drawings.Name.Visible = false
					drawings.Distance.Visible = false
					drawings.HealthBar.Visible = false
					drawings.HealthText.Visible = false
					for _, line in pairs(drawings.Skeleton) do line.Visible = false end
				end
			end
		end
	end

	local character = localPlayer.Character
	if not character then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")

	if root and flyPart then
		if flying then
			if humanoid and humanoid.Health > 0 then
				task.spawn(function()
					local Enums = Enum.HumanoidStateType:GetEnumItems()
					table.remove(Enums, table.find(Enums, Enum.HumanoidStateType.None))
					for _, v in pairs(Enums) do humanoid:SetStateEnabled(v, false) end
				end)
			end
			humanoid.AutoRotate = false
			equipFunctionActive = true
			root.CFrame = flyPart.CFrame
			root.Velocity = Vector3.zero
			root.RotVelocity = Vector3.zero
			if character:FindFirstChild("Animate") then character.Animate.Enabled = false end

			local moving = UserInputService:IsKeyDown(Enum.KeyCode.W) or UserInputService:IsKeyDown(Enum.KeyCode.S) or UserInputService:IsKeyDown(Enum.KeyCode.A) or UserInputService:IsKeyDown(Enum.KeyCode.D)
			local vertical = 0
			if hoverEnabled then
				if UserInputService:IsKeyDown(Enum.KeyCode.Space) then vertical = 1
				elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then vertical = -1 end
			end

			if not moving and vertical == 0 then
				if loadIdle1 and not loadIdle1.IsPlaying then
					loadIdle1:Play()
					loadIdle2:Play()
					loadIdle2:AdjustWeight(0.5)
				end
				if loadFly then loadFly:Stop() end
				if flyVelocity then flyVelocity.Velocity = Vector3.zero end
				local lookVector = flyPart.Position + camera.CFrame.LookVector
				local idleCFrame = CFrame.lookAt(flyPart.Position, lookVector)
				flyPart.CFrame = flyPart.CFrame:Lerp(idleCFrame, math.clamp(dt * 15, 0, 1))
			else
				if loadFly and not loadFly.IsPlaying then
					loadFly:Play(0.1)
					loadFly:AdjustSpeed(0)
					loadFly.TimePosition = 0.5
				end
				if loadIdle1 then loadIdle1:Stop() end
				if loadIdle2 then loadIdle2:Stop() end
				local lookVector = camera.CFrame.LookVector
				local flyCFrame = CFrame.lookAt(flyPart.Position, flyPart.Position + lookVector) * CFrame.Angles(math.rad(-65), 0, 0)
				if flyVelocity then flyVelocity.Velocity = Vector3.zero end
				local targetFlyCF = flyCFrame + (lookVector * 5) * flySpeed + Vector3.new(0, vertical * 5 * flySpeed, 0)
				flyPart.CFrame = flyPart.CFrame:Lerp(targetFlyCF, math.clamp(dt * 15, 0, 1))
			end
		else
			if flyPart and root then flyPart.CFrame = root.CFrame end
		end
	end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if not gameProcessed then
		if input.KeyCode == Enum.KeyCode.F5 then
			mainFrame.Visible = not mainFrame.Visible
			if mainFrame.Visible then updatePlayerList() end
		elseif input.KeyCode == flightKey then
			local character = localPlayer.Character
			if character then
				local humanoid = character:FindFirstChildOfClass("Humanoid")
				local root = character:FindFirstChild("HumanoidRootPart")
				if humanoid and root then
					flying = not flying
					if not flying then
						equipFunctionActive = false
						if loadIdle1 then loadIdle1:Stop() end
						if loadIdle2 then loadIdle2:Stop() end
						if loadFly then loadFly:Stop() end
						local Enums = Enum.HumanoidStateType:GetEnumItems()
						table.remove(Enums, table.find(Enums, Enum.HumanoidStateType.None))
						for _, v in pairs(Enums) do humanoid:SetStateEnabled(v, true) end
						humanoid.AutoRotate = true
						root.Velocity = Vector3.zero
						if character:FindFirstChild("Animate") then character.Animate.Enabled = true end
					end
				end
			end
		elseif input.KeyCode == superJumpKey then
			triggerSuperJump()
		elseif input.KeyCode == walkSpeedKey then
			walkSpeedToggled = not walkSpeedToggled
			local char = localPlayer.Character
			if char and char:FindFirstChildOfClass("Humanoid") then
				local hum = char:FindFirstChildOfClass("Humanoid")
				hum.WalkSpeed = walkSpeedToggled and customWalkSpeed or 20
			end
		elseif input.KeyCode == targetLockKey then
			local c = targetLockConnection
			targetLockEnabled = not targetLockEnabled
			if targetLockEnabled then
				targetLockConnection = RunService.RenderStepped:Connect(function(dt)
					local target = getClosestPlayerToCursor()
					if target and target.Character then
						local targetHead = target.Character:FindFirstChild("Head")
						if targetHead then
							local currentPos = camera.CFrame.Position
							local targetCF = CFrame.new(currentPos, targetHead.Position)
							local alpha = math.clamp(dt * camlockSmoothness * (camlockSnappiness * 0.4), 0, 1)
							camera.CFrame = camera.CFrame:Lerp(targetCF, alpha)
						end
					end
				end)
			else
				if c then c:Disconnect() end
				if targetLockConnection then targetLockConnection:Disconnect() targetLockConnection = nil end
			end
		end
	end
end)

-- Dragging
local dragging, dragInput, dragStart, startPos
header.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = mainFrame.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then dragging = false end
		end)
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end
end)

RunService.RenderStepped:Connect(function()
	if dragging and dragInput then
		local delta = dragInput.Position - dragStart
		mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)

print("[APM] Advanced Player Manager loaded successfully!")
