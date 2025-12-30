-- RbxLuauLLMClient.lua
-- Simple UI for Translator/Assistant. Uses server RemoteFunction for HTTP.
-- Authorized use only.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local RF = ReplicatedStorage:WaitForChild("RbxLuauLLM_Request")

-- Optional bridge (adapter). Developers can override:
-- _G.RbxLuauLLM_Bridge = { Exec = function(outputText) ... end }
local Bridge = rawget(_G, "RbxLuauLLM_Bridge")
if type(Bridge) ~= "table" or type(Bridge.Exec) ~= "function" then
	Bridge = {
		Exec = function(outputText)
			print("[RbxLuauLLM OUTPUT]", outputText)
		end
	}
end

local function notify(msg)
	pcall(function()
		StarterGui:SetCore("SendNotification", {
			Title = "RbxLuauLLM",
			Text = tostring(msg),
			Duration = 4,
		})
	end)
end

-- === UI ===
local gui = Instance.new("ScreenGui")
gui.Name = "RbxLuauLLM_GUI"
gui.ResetOnSpawn = false
gui.Parent = PlayerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 420, 0, 160)
frame.Position = UDim2.new(0, 24, 0, 120)
frame.BackgroundTransparency = 0.1
frame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -12, 0, 28)
title.Position = UDim2.new(0, 6, 0, 6)
title.BackgroundTransparency = 1
title.Text = "RbxLuauLLM"
title.TextXAlignment = Enum.TextXAlignment.Left
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.Parent = frame

local modeBtn = Instance.new("TextButton")
modeBtn.Size = UDim2.new(0, 120, 0, 26)
modeBtn.Position = UDim2.new(1, -126, 0, 6)
modeBtn.Text = "Mode: Translator"
modeBtn.Font = Enum.Font.Gotham
modeBtn.TextSize = 12
modeBtn.Parent = frame

local input = Instance.new("TextBox")
input.Size = UDim2.new(1, -12, 0, 64)
input.Position = UDim2.new(0, 6, 0, 40)
input.PlaceholderText = "Type what you want…"
input.Text = ""
input.ClearTextOnFocus = false
input.TextWrapped = true
input.TextXAlignment = Enum.TextXAlignment.Left
input.TextYAlignment = Enum.TextYAlignment.Top
input.Font = Enum.Font.Gotham
input.TextSize = 14
input.Parent = frame

local sendBtn = Instance.new("TextButton")
sendBtn.Size = UDim2.new(0, 90, 0, 28)
sendBtn.Position = UDim2.new(1, -96, 1, -34)
sendBtn.Text = "Send"
sendBtn.Font = Enum.Font.GothamBold
sendBtn.TextSize = 13
sendBtn.Parent = frame

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -110, 0, 28)
status.Position = UDim2.new(0, 6, 1, -34)
status.BackgroundTransparency = 1
status.Text = "Idle"
status.TextXAlignment = Enum.TextXAlignment.Left
status.Font = Enum.Font.Gotham
status.TextSize = 13
status.Parent = frame

-- Dragging
do
	local dragging = false
	local dragStart, startPos

	title.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = i.Position
			startPos = frame.Position
			i.Changed:Connect(function()
				if i.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	UserInputService.InputChanged:Connect(function(i)
		if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = i.Position - dragStart
			frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
end

local mode = "translator"
modeBtn.MouseButton1Click:Connect(function()
	if mode == "translator" then
		mode = "assistant"
		modeBtn.Text = "Mode: Assistant"
	else
		mode = "translator"
		modeBtn.Text = "Mode: Translator"
	end
end)

local busy = false

local function setBusy(on)
	busy = on
	sendBtn.AutoButtonColor = not on
	sendBtn.Active = not on
	input.TextEditable = not on
	status.Text = on and "Thinking…" or "Idle"
end

local function send()
	if busy then return end
	local text = input.Text
	if not text or text:gsub("%s+", "") == "" then
		notify("Type something first.")
		return
	end

	setBusy(true)

	local ok, res = pcall(function()
		return RF:InvokeServer({
			mode = mode,
			text = text,
			-- clientToken = "" -- only if you enable token requirement server-side
		})
	end)

	setBusy(false)

	if not ok then
		notify("Request failed: " .. tostring(res))
		return
	end

	if type(res) ~= "table" or not res.ok then
		notify("Error: " .. tostring(res and res.error or "Unknown"))
		return
	end

	local out = tostring(res.output or "")
	if mode == "assistant" then
		notify(out)
	else
		-- Translator output is routed through your adapter/bridge.
		Bridge.Exec(out)
		notify("Generated output sent to bridge.")
	end
end

sendBtn.MouseButton1Click:Connect(send)
input.FocusLost:Connect(function(enterPressed)
	if enterPressed then
		send()
	end
end)
