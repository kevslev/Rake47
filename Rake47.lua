local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Utility function to add rounded corners
local function roundify(uiElement, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 8)
	corner.Parent = uiElement
end

local remotes = {
	{
		name = "Door",
		key = Enum.KeyCode.C,
		path = workspace:WaitForChild("Map"):WaitForChild("SafeHouse"):WaitForChild("Door"):WaitForChild("RemoteEvent"),
		args = { "Door" },
		enabled = true
	},
	{
		name = "Light (SafeHouse)",
		key = Enum.KeyCode.V,
		path = workspace:WaitForChild("Map"):WaitForChild("SafeHouse"):WaitForChild("Door"):WaitForChild("RemoteEvent"),
		args = { "Light" },
		enabled = true
	},
	{
		name = "Door (Obs)",
		key = Enum.KeyCode.X,
		path = workspace:WaitForChild("Map"):WaitForChild("ObservationTower"):WaitForChild("Lights"):WaitForChild("RemoteEvent"),
		args = { "Door", true },
		enabled = true
	},
	{
		name = "Door2 (Obs)",
		key = Enum.KeyCode.N,
		path = workspace:WaitForChild("Map"):WaitForChild("ObservationTower"):WaitForChild("Lights"):WaitForChild("RemoteEvent"),
		args = { "Door2" },
		enabled = true
	},
	{
		name = "Radar (Obs)",
		key = Enum.KeyCode.M,
		path = workspace:WaitForChild("Map"):WaitForChild("ObservationTower"):WaitForChild("Lights"):WaitForChild("RemoteEvent"),
		args = { "Radar" },
		enabled = true
	},
	{
		name = "Light (Obs)",
		key = Enum.KeyCode.B,
		path = workspace:WaitForChild("Map"):WaitForChild("ObservationTower"):WaitForChild("Lights"):WaitForChild("RemoteEvent"),
		args = { "Light" },
		enabled = true
	}
}

local openKey = Enum.KeyCode.RightControl
local uiVisible = true
local waitingForKeybind = nil
local waitingForUIKeyChange = false
local inputConnection
local labelRefs = {}
local activeChangeButtons = {}

-- UI Setup
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RemoteControlUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
screenGui.DisplayOrder = 1000
screenGui.Parent = playerGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 440, 0, 380)
mainFrame.Position = UDim2.new(0, 100, 0, 100)
mainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
mainFrame.BackgroundTransparency = 0.2
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.ZIndex = 100
mainFrame.Parent = screenGui
roundify(mainFrame, 10)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -120, 0, 30)
title.Position = UDim2.new(0, 10, 0, 0)
title.BackgroundTransparency = 1
title.Text = "Rake47"
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.GothamBold
title.TextSize = 22
title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex = 101
title.Parent = mainFrame

local destroyButton = Instance.new("TextButton")
destroyButton.Size = UDim2.new(0, 100, 0, 30)
destroyButton.Position = UDim2.new(1, -110, 0, 0)
destroyButton.Text = "Delete"
destroyButton.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
destroyButton.BackgroundTransparency = 0.1
destroyButton.TextColor3 = Color3.new(1, 1, 1)
destroyButton.Font = Enum.Font.GothamBold
destroyButton.TextSize = 16
destroyButton.ZIndex = 101
destroyButton.Parent = mainFrame
roundify(destroyButton, 6)

local uiKeyLabel = Instance.new("TextLabel")
uiKeyLabel.Size = UDim2.new(0, 200, 0, 25)
uiKeyLabel.Position = UDim2.new(0, 10, 0, 35)
uiKeyLabel.BackgroundTransparency = 1
uiKeyLabel.Text = "UI Toggle Key: " .. openKey.Name
uiKeyLabel.TextColor3 = Color3.new(1, 1, 1)
uiKeyLabel.Font = Enum.Font.Gotham
uiKeyLabel.TextSize = 16
uiKeyLabel.TextXAlignment = Enum.TextXAlignment.Left
uiKeyLabel.ZIndex = 101
uiKeyLabel.Parent = mainFrame

local uiKeyButton = Instance.new("TextButton")
uiKeyButton.Size = UDim2.new(0, 120, 0, 25)
uiKeyButton.Position = UDim2.new(1, -130, 0, 35)
uiKeyButton.Text = "Change Key"
uiKeyButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
uiKeyButton.BackgroundTransparency = 0.2
uiKeyButton.TextColor3 = Color3.new(1, 1, 1)
uiKeyButton.Font = Enum.Font.GothamBold
uiKeyButton.TextSize = 14
uiKeyButton.ZIndex = 101
uiKeyButton.Parent = mainFrame
roundify(uiKeyButton, 6)

local overlayPrompt = Instance.new("TextLabel")
overlayPrompt.Size = UDim2.new(1, 0, 0, 30)
overlayPrompt.Position = UDim2.new(0, 0, 0, -35)
overlayPrompt.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
overlayPrompt.BackgroundTransparency = 0.4
overlayPrompt.Text = ""
overlayPrompt.TextColor3 = Color3.new(1, 1, 0)
overlayPrompt.TextSize = 18
overlayPrompt.Font = Enum.Font.GothamBold
overlayPrompt.Visible = false
overlayPrompt.ZIndex = 999
overlayPrompt.Parent = screenGui

uiKeyButton.MouseButton1Click:Connect(function()
	waitingForUIKeyChange = true
	uiKeyButton.Text = "Press a key..."
	overlayPrompt.Text = "Press a key for UI toggle"
	overlayPrompt.Visible = true
end)

local function createRemoteEntry(remote, index)
	local entry = Instance.new("Frame")
	entry.Size = UDim2.new(1, -20, 0, 40)
	entry.Position = UDim2.new(0, 10, 0, 70 + (index - 1) * 45)
	entry.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	entry.BackgroundTransparency = 0.2
	entry.ZIndex = 100
	entry.Parent = mainFrame
	roundify(entry, 8)

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0.4, 0, 1, 0)
	label.Position = UDim2.new(0, 0, 0, 0)
	label.Text = remote.name .. " - " .. remote.key.Name
	label.TextColor3 = Color3.new(1, 1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.Gotham
	label.TextSize = 15
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.ZIndex = 101
	label.Parent = entry

	local toggle = Instance.new("TextButton")
	toggle.Size = UDim2.new(0, 60, 0, 25)
	toggle.Position = UDim2.new(1, -130, 0.5, -12)
	toggle.Text = remote.enabled and "ON" or "OFF"
	toggle.BackgroundColor3 = remote.enabled and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(100, 0, 0)
	toggle.BackgroundTransparency = 0.1
	toggle.TextColor3 = Color3.new(1, 1, 1)
	toggle.Font = Enum.Font.GothamBold
	toggle.TextSize = 14
	toggle.ZIndex = 101
	toggle.Parent = entry
	roundify(toggle, 6)

	toggle.MouseButton1Click:Connect(function()
		remote.enabled = not remote.enabled
		toggle.Text = remote.enabled and "ON" or "OFF"
		toggle.BackgroundColor3 = remote.enabled and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(100, 0, 0)
	end)

	local changeBtn = Instance.new("TextButton")
	changeBtn.Size = UDim2.new(0, 60, 0, 25)
	changeBtn.Position = UDim2.new(1, -65, 0.5, -12)
	changeBtn.Text = "Change"
	changeBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
	changeBtn.BackgroundTransparency = 0.2
	changeBtn.TextColor3 = Color3.new(1, 1, 1)
	changeBtn.Font = Enum.Font.GothamBold
	changeBtn.TextSize = 14
	changeBtn.ZIndex = 101
	changeBtn.Parent = entry
	roundify(changeBtn, 6)

	changeBtn.MouseButton1Click:Connect(function()
		waitingForKeybind = index
		changeBtn.Text = "Press..."
		overlayPrompt.Text = "Press a key for " .. remote.name
		overlayPrompt.Visible = true
		activeChangeButtons[index] = changeBtn
	end)

	return label
end

for i, remote in ipairs(remotes) do
	local label = createRemoteEntry(remote, i)
	labelRefs[i] = label
end

inputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if waitingForUIKeyChange then
		openKey = input.KeyCode
		uiKeyLabel.Text = "UI Toggle Key: " .. openKey.Name
		uiKeyButton.Text = "Change Key"
		waitingForUIKeyChange = false
		overlayPrompt.Visible = false
		return
	end

	if waitingForKeybind then
		local r = remotes[waitingForKeybind]
		r.key = input.KeyCode
		labelRefs[waitingForKeybind].Text = r.name .. " - " .. input.KeyCode.Name
		if activeChangeButtons[waitingForKeybind] then
			activeChangeButtons[waitingForKeybind].Text = "Change"
		end
		waitingForKeybind = nil
		overlayPrompt.Visible = false
		return
	end

	if input.KeyCode == openKey then
		uiVisible = not uiVisible
		if screenGui then
			screenGui.Enabled = uiVisible
		end
		return
	end

	for _, remote in ipairs(remotes) do
		if remote.enabled and input.KeyCode == remote.key then
			remote.path:FireServer(unpack(remote.args))
		end
	end
end)

destroyButton.MouseButton1Click:Connect(function()
	if inputConnection then
		inputConnection:Disconnect()
	end
	screenGui:Destroy()
	remotes = nil
end)
