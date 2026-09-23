-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

-- State tracking
local highlightedPlayer: Player? = nil
local highlightEffect: Highlight? = nil

-- Create ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ModernTeleportMenu"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Create Main Frame (Modern Dark Theme)
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 280, 0, 380)
mainFrame.Position = UDim2.new(0.5, -140, 0.5, -190)
mainFrame.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
mainFrame.BorderSizePixel = 0
mainFrame.Visible = false
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 12)
mainCorner.Parent = mainFrame

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(45, 45, 55)
mainStroke.Thickness = 1
mainStroke.Parent = mainFrame

-- Header (Draggable Area)
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 45)
header.BackgroundTransparency = 1
header.Parent = mainFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -20, 1, 0)
titleLabel.Position = UDim2.new(0, 16, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Player Manager"
titleLabel.TextColor3 = Color3.fromRGB(240, 240, 245)
titleLabel.TextSize = 18
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = header

-- Tab Container Frame
local tabContainer = Instance.new("Frame")
tabContainer.Size = UDim2.new(1, -16, 0, 32)
tabContainer.Position = UDim2.new(0, 8, 0, 50)
tabContainer.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
tabContainer.BorderSizePixel = 0
tabContainer.Parent = mainFrame

local tabCorner = Instance.new("UICorner")
tabCorner.CornerRadius = UDim.new(0, 8)
tabCorner.Parent = tabContainer

-- Players Tab Button
local playersTabBtn = Instance.new("TextButton")
playersTabBtn.Size = UDim2.new(0.5, -4, 1, 0)
playersTabBtn.Position = UDim2.new(0, 2, 0, 0)
playersTabBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
playersTabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
playersTabBtn.TextSize = 13
playersTabBtn.Font = Enum.Font.GothamBold
playersTabBtn.Text = "Players"
playersTabBtn.Parent = tabContainer

local pBtnCorner = Instance.new("UICorner")
pBtnCorner.CornerRadius = UDim.new(0, 6)
pBtnCorner.Parent = playersTabBtn

-- Credits Tab Button
local creditsTabBtn = Instance.new("TextButton")
creditsTabBtn.Size = UDim2.new(0.5, -4, 1, 0)
creditsTabBtn.Position = UDim2.new(0.5, 2, 0, 0)
creditsTabBtn.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
creditsTabBtn.TextColor3 = Color3.fromRGB(150, 150, 160)
creditsTabBtn.TextSize = 13
creditsTabBtn.Font = Enum.Font.GothamBold
creditsTabBtn.Text = "Credits"
creditsTabBtn.Parent = tabContainer

local cBtnCorner = Instance.new("UICorner")
cBtnCorner.CornerRadius = UDim.new(0, 6)
cBtnCorner.Parent = creditsTabBtn

-- Pages Container
local pagesContainer = Instance.new("Frame")
pagesContainer.Size = UDim2.new(1, -16, 1, -95)
pagesContainer.Position = UDim2.new(0, 8, 0, 88)
pagesContainer.BackgroundTransparency = 1
pagesContainer.Parent = mainFrame

-- Players Page (Scrolling Frame)
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

-- Credits Page Frame
local creditsPage = Instance.new("Frame")
creditsPage.Size = UDim2.new(1, 0, 1, 0)
creditsPage.BackgroundTransparency = 1
creditsPage.Visible = false
creditsPage.Parent = pagesContainer

local creditsText = Instance.new("TextLabel")
creditsText.Size = UDim2.new(1, 0, 1, 0)
creditsText.BackgroundTransparency = 1
creditsText.Text = "UI & Script developed by:\n\n• C4N0Fz\n• @kp3g\n\nDiscord Credits & Special Thanks!"
creditsText.TextColor3 = Color3.fromRGB(200, 200, 210)
creditsText.TextSize = 14
creditsText.Font = Enum.Font.GothamMedium
creditsText.TextWrapped = true
creditsText.TextXAlignment = Enum.TextXAlignment.Center
creditsText.TextYAlignment = Enum.TextYAlignment.Center
creditsText.Parent = creditsPage

-- Tab Switching Logic
playersTabBtn.MouseButton1Click:Connect(function()
	scrollingFrame.Visible = true
	creditsPage.Visible = false
	playersTabBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	playersTabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	creditsTabBtn.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
	creditsTabBtn.TextColor3 = Color3.fromRGB(150, 150, 160)
end)

creditsTabBtn.MouseButton1Click:Connect(function()
	scrollingFrame.Visible = false
	creditsPage.Visible = true
	creditsTabBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	creditsTabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	playersTabBtn.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
	playersTabBtn.TextColor3 = Color3.fromRGB(150, 150, 160)
end)

-- Highlight Management
local function setHighlight(player: Player?)
	if highlightEffect then
		highlightEffect:Destroy()
		highlightEffect = nil
	end
	
	highlightedPlayer = player
	
	if player and player.Character then
		local highlight = Instance.new("Highlight")
		highlight.Name = "PlayerHighlight"
		highlight.Adornee = player.Character
		highlight.FillColor = Color3.fromRGB(0, 162, 255)
		highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
		highlight.FillTransparency = 0.5
		highlight.Parent = player.Character
		highlightEffect = highlight
	end
end

-- Update Player List UI
local function updatePlayerList()
	for _, child in ipairs(scrollingFrame:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= localPlayer then
			local itemFrame = Instance.new("Frame")
			itemFrame.Size = UDim2.new(1, 0, 0, 44)
			itemFrame.BackgroundColor3 = Color3.fromRGB(32, 32, 38)
			itemFrame.BorderSizePixel = 0
			itemFrame.Parent = scrollingFrame

			local itemCorner = Instance.new("UICorner")
			itemCorner.CornerRadius = UDim.new(0, 8)
			itemCorner.Parent = itemFrame

			local nameLabel = Instance.new("TextLabel")
			nameLabel.Size = UDim2.new(1, -130, 1, 0)
			nameLabel.Position = UDim2.new(0, 12, 0, 0)
			nameLabel.BackgroundTransparency = 1
			nameLabel.Text = player.Name
			nameLabel.TextColor3 = Color3.fromRGB(220, 220, 225)
			nameLabel.TextSize = 14
			nameLabel.Font = Enum.Font.GothamMedium
			nameLabel.TextXAlignment = Enum.TextXAlignment.Left
			nameLabel.Parent = itemFrame

			local tpButton = Instance.new("TextButton")
			tpButton.Size = UDim2.new(0, 55, 0, 28)
			tpButton.Position = UDim2.new(1, -125, 0.5, -14)
			tpButton.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
			tpButton.TextColor3 = Color3.fromRGB(255, 255, 255)
			tpButton.TextSize = 12
			tpButton.Font = Enum.Font.GothamBold
			tpButton.Text = "TP"
			tpButton.Parent = itemFrame

			local tpCorner = Instance.new("UICorner")
			tpCorner.CornerRadius = UDim.new(0, 6)
			tpCorner.Parent = tpButton

			local hlButton = Instance.new("TextButton")
			hlButton.Size = UDim2.new(0, 55, 0, 28)
			hlButton.Position = UDim2.new(1, -63, 0.5, -14)
			hlButton.BackgroundColor3 = highlightedPlayer == player and Color3.fromRGB(0, 162, 255) or Color3.fromRGB(50, 50, 60)
			hlButton.TextColor3 = Color3.fromRGB(200, 200, 210)
			hlButton.TextSize = 12
			hlButton.Font = Enum.Font.GothamBold
			hlButton.Text = "ESP"
			hlButton.Parent = itemFrame

			local hlCorner = Instance.new("UICorner")
			hlCorner.CornerRadius = UDim.new(0, 6)
			hlCorner.Parent = hlButton

			tpButton.MouseButton1Click:Connect(function()
				local targetChar = player.Character
				local localChar = localPlayer.Character
				if targetChar and targetChar:FindFirstChild("HumanoidRootPart") and 
				   localChar and localChar:FindFirstChild("HumanoidRootPart") then
					localChar.HumanoidRootPart.CFrame = targetChar.HumanoidRootPart.CFrame + Vector3.new(0, 3, 0)
					mainFrame.Visible = false
				end
			end)

			hlButton.MouseButton1Click:Connect(function()
				if highlightedPlayer == player then
					setHighlight(nil)
					hlButton.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
				else
					setHighlight(player)
					hlButton.BackgroundColor3 = Color3.fromRGB(0, 162, 255)
					updatePlayerList()
				end
			end)
		end
	end
end

Players.PlayerAdded:Connect(updatePlayerList)
Players.PlayerRemoving:Connect(updatePlayerList)

RunService.RenderStepped:Connect(function()
	if highlightedPlayer and not highlightEffect and highlightedPlayer.Character then
		setHighlight(highlightedPlayer)
	end
end)

-- Draggable Menu Logic
local dragging, dragInput, dragStart, startPos

header.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = mainFrame.Position
		
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
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
		mainFrame.Position = UDim2.new(
			startPos.X.Scale, 
			startPos.X.Offset + delta.X, 
			startPos.Y.Scale, 
			startPos.Y.Offset + delta.Y
		)
	end
end)

-- Toggle Menu with F5 key
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if not gameProcessed and input.KeyCode == Enum.KeyCode.F5 then
		mainFrame.Visible = not mainFrame.Visible
		if mainFrame.Visible then
			updatePlayerList()
		end
	end
end)