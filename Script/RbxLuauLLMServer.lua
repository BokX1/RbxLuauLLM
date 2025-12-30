-- RbxLuauLLMServer.lua
-- Server-side LLM proxy caller (HttpService works here). No secrets in this repo.
-- Authorized use only.

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- === CONFIG (safe defaults) ===
local CONFIG = {
	Endpoint = "https://<your-worker-domain>/v1/chat/completions", -- Cloudflare Worker (OpenAI-style)
	Model = "grok",
	Temperature = 0.3,
	MaxRetries = 2,

	-- Optional: require a token from clients (recommended if your place is public)
	RequireClientToken = false,
	ExpectedClientToken = "",

	-- Anti-spam/rate limit
	MinSecondsBetweenCalls = 1.0,

	-- Input limits
	MaxUserChars = 300,
	MaxOutputChars = 400,
}

-- RemoteFunction used by the client UI
local RF_NAME = "RbxLuauLLM_Request"
local Remote = ReplicatedStorage:FindFirstChild(RF_NAME)
if not Remote then
	Remote = Instance.new("RemoteFunction")
	Remote.Name = RF_NAME
	Remote.Parent = ReplicatedStorage
end

local lastCallAt: {[number]: number} = {}

local function now()
	return os.clock()
end

local function buildPlayerList()
	local names = {}
	for _, plr in ipairs(Players:GetPlayers()) do
		table.insert(names, plr.Name)
	end
	return names
end

local function makeTranslatorPrompt()
	-- Keep this “safe” and general. Contributors can extend the allowed command set.
	return [[
You are RbxLuauLLM Translator.

GOAL:
- Convert the user's request into ONE actionable output string.

OUTPUT RULES (critical):
- Output ONLY the action text. No explanations. No markdown. No quotes.
- If outputting a command string, it MUST start with a semicolon: ;
- Keep it short.

ALLOWED COMMAND EXAMPLES (edit/extend for your project):
- ";speed 50"
- ";jump 80"
- ";fly"
- ";unfly"
- ";tp <playerName>"

TARGETING:
- If the user refers to a player target, choose ONLY from [SYSTEM DATA] player names.
- If [FEEDBACK ERROR] appears, correct the target and output a corrected action.

If you cannot comply, output:
";notify Unable to translate request"
]]
end

local function makeAssistantPrompt(gameName, playerName)
	return ([
You are RbxLuauLLM Assistant for a Roblox experience.

Context:
- Player: %s
- Experience: %s

Rules:
- Be concise (1–3 sentences).
- If unsure, say so briefly.
- No claims of hidden/secret mechanics.
]]):format(playerName, gameName)
end

local function postChatCompletions(systemText, userText)
	local payload = {
		model = CONFIG.Model,
		messages = {
			{ role = "system", content = systemText },
			{ role = "user", content = userText },
		},
		temperature = CONFIG.Temperature,
	}

	local ok, res = pcall(function()
		return HttpService:RequestAsync({
			Url = CONFIG.Endpoint,
			Method = "POST",
			Headers = { ["Content-Type"] = "application/json" },
			Body = HttpService:JSONEncode(payload),
		})
	end)

	if not ok then
		return nil, "RequestAsync failed: " .. tostring(res)
	end
	if not res.Success then
		return nil, ("HTTP %s: %s"):format(tostring(res.StatusCode), tostring(res.StatusMessage))
	end

	local decoded
	local ok2, err2 = pcall(function()
		decoded = HttpService:JSONDecode(res.Body)
	end)
	if not ok2 then
		return nil, "JSON decode failed: " .. tostring(err2)
	end

	local content =
		decoded
		and decoded.choices
		and decoded.choices[1]
		and decoded.choices[1].message
		and decoded.choices[1].message.content

	if type(content) ~= "string" or content == "" then
		return nil, "Empty/invalid model response."
	end

	-- clamp output length
	if #content > CONFIG.MaxOutputChars then
		content = content:sub(1, CONFIG.MaxOutputChars)
	end

	return content, nil
end

local function findTargetInCommand(cmd)
	-- naive parse: ";tp NAME" or ";goto NAME" etc.
	local parts = string.split(cmd:gsub("^%s+", ""):gsub("%s+$", ""), " ")
	if #parts >= 2 then
		return parts[2]
	end
	return nil
end

local function isNameInList(name, list)
	for _, v in ipairs(list) do
		if v == name then return true end
	end
	return false
end

Remote.OnServerInvoke = function(player, req)
	-- req = { mode = "translator"|"assistant", text = "...", clientToken? = "..." }
	if type(req) ~= "table" then
		return { ok = false, error = "Bad request." }
	end

	-- Rate limiting
	local t = now()
	local last = lastCallAt[player.UserId] or 0
	if (t - last) < CONFIG.MinSecondsBetweenCalls then
		return { ok = false, error = "Rate limited. Try again." }
	end
	lastCallAt[player.UserId] = t

	-- Optional token check
	if CONFIG.RequireClientToken then
		if req.clientToken ~= CONFIG.ExpectedClientToken or CONFIG.ExpectedClientToken == "" then
			return { ok = false, error = "Unauthorized client token." }
		end
	end

	local mode = tostring(req.mode or "translator"):lower()
	local userText = tostring(req.text or "")
	userText = userText:sub(1, CONFIG.MaxUserChars)

	local playerNames = buildPlayerList()
	local systemText

	if mode == "assistant" then
		-- We can’t reliably fetch “game name” server-side without a product lookup; keep it simple
		systemText = makeAssistantPrompt("Your Experience", player.Name)
	else
		systemText = makeTranslatorPrompt()
	end

	-- Add system data context for targeting (translator mode)
	local contextBlock = ""
	if mode ~= "assistant" then
		contextBlock = "\n\n[SYSTEM DATA]\nPlayers: " .. table.concat(playerNames, ", ")
	end

	local output, err = postChatCompletions(systemText, userText .. contextBlock)
	if not output then
		return { ok = false, error = err }
	end

	-- Optional retry loop for bad player targets (translator mode)
	if mode ~= "assistant" and output:match("^%s*;") then
		local retries = 0
		while retries < CONFIG.MaxRetries do
			local target = findTargetInCommand(output)
			if not target then break end
			if isNameInList(target, playerNames) then break end

			retries += 1
			local feedback = ("\n\n[FEEDBACK ERROR]\nTarget '%s' not found. Use ONLY one of: %s"):format(
				target, table.concat(playerNames, ", ")
			)

			local retryOut, retryErr = postChatCompletions(systemText, userText .. contextBlock .. feedback)
			if not retryOut then
				return { ok = false, error = retryErr }
			end
			output = retryOut
		end
	end

	return { ok = true, output = output, mode = mode }
end
