if getgenv().NEHUB_LOADED then return end
getgenv().NEHUB_LOADED = true

getgenv().NEHUB_AP = true
getgenv().NEHUB_BLOCK_GAME_PARRY = true
getgenv().NEHUB_HOOK_READY = false
getgenv().NEHUB_HOOK_CAPTURED = false
getgenv().NEHUB_TOKEN_READY = false
getgenv().NEHUB_LOCK_UNTIL = 0
getgenv().NEHUB_LAST_SUCCESS = 0
getgenv().NEHUB_LAST_FIRE = 0

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Stats = game:GetService("Stats")
local LocalPlayer = Players.LocalPlayer
local Workspace = workspace
local RS = ReplicatedStorage
local UIS = UserInputService

local function clamp(v, minValue, maxValue)
	return math.max(minValue, math.min(maxValue, v))
end

local function xor(a, b)
	if bit32 and bit32.bxor then return bit32.bxor(a, b) end
	local r, bit = 0, 1
	while a > 0 or b > 0 do
		local abit = a % 2
		local bbit = b % 2
		if abit ~= bbit then r = r + bit end
		a = math.floor(a / 2)
		b = math.floor(b / 2)
		bit = bit * 2
	end
	return r
end

local function notify(title, text, duration)
	pcall(function()
		game:GetService("StarterGui"):SetCore("SendNotification", {
			Title = title,
			Text = text,
			Icon = "rbxassetid://135351041318579",
			Duration = duration or 5,
			Button1 = "OK",
		})
	end)
end

local uiState = {
	AP = true,
	ManualSpam = false,
	Trigger = false,
	AutoSpam = false,
}
getgenv().NEHUB_AP = uiState.AP
getgenv().NEHUB_MANUAL_SPAM = uiState.ManualSpam
getgenv().NEHUB_TRIGGER = uiState.Trigger
getgenv().NEHUB_AUTO_SPAM = uiState.AutoSpam

pcall(function()
	local gui = Instance.new("ScreenGui")
	gui.Name = "NEHUB_UI"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromOffset(230, 176)
	frame.Position = UDim2.fromOffset(18, 18)
	frame.BackgroundColor3 = Color3.fromRGB(6, 6, 12)
	frame.BorderSizePixel = 0
	frame.Draggable = true
	frame.Active = true
	frame.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 255, 255)
	stroke.Transparency = 0.82
	stroke.Parent = frame

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 30)
	title.BackgroundTransparency = 1
	title.Text = "NoEnemiesHub"
	title.Font = Enum.Font.GothamBold
	title.TextSize = 15
	title.TextColor3 = Color3.fromRGB(235, 235, 245)
	title.Parent = frame

	local flagNames = {
		AP = "NEHUB_AP",
		ManualSpam = "NEHUB_MANUAL_SPAM",
		Trigger = "NEHUB_TRIGGER",
		AutoSpam = "NEHUB_AUTO_SPAM",
	}
	local function addToggle(name, y, key)
		local button = Instance.new("TextButton")
		button.Size = UDim2.new(1, -24, 0, 30)
		button.Position = UDim2.fromOffset(12, y)
		button.Font = Enum.Font.GothamBold
		button.TextSize = 12
		button.Parent = frame
		local function refresh()
			local on = uiState[key]
			button.Text = name .. ": " .. (on and "ON" or "OFF")
			button.BackgroundColor3 = on and Color3.fromRGB(30, 120, 80) or Color3.fromRGB(28, 28, 38)
			button.TextColor3 = on and Color3.new(1, 1, 1) or Color3.fromRGB(170, 170, 180)
		end
		button.MouseButton1Click:Connect(function()
			uiState[key] = not uiState[key]
			getgenv()[flagNames[key]] = uiState[key]
			refresh()
		end)
		refresh()
	end

	addToggle("AUTO PARRY", 34, "AP")
	addToggle("MANUAL SPAM", 70, "ManualSpam")
	addToggle("TRIGGER BOT", 106, "Trigger")
	addToggle("AUTO SPAM", 142, "AutoSpam")
end)

local NEParry = (function()
	local getgc2 = getgc
	local getraw2 = getrawmetatable
	local setro2 = setreadonly
	local isro2 = isreadonly
	local byte2 = string.byte
	local char2 = string.char
	local unpack2 = table.unpack or unpack

	local tokenFn = nil
	local bootAt = os.clock()
	local tokenList = nil
	local tokenIndex = 1
	local tokenDone = false

	local function findToken()
		if type(tokenFn) == "function" then return true end
		if os.clock() - bootAt < 2 then return false end
		if tokenDone then return false end
		if not tokenList then
			if type(getgc2) ~= "function" then return false end
			local ok, list = pcall(function() return getgc2(true) end)
			if not ok or type(list) ~= "table" then return false end
			tokenList = list
			tokenIndex = 1
		end
		local deadline = os.clock() + 0.003
		while tokenIndex <= #tokenList and os.clock() < deadline do
			local f = tokenList[tokenIndex]
			tokenIndex = tokenIndex + 1
			if type(f) == "function" then
				local okSrc, src = pcall(debug.info, f, "s")
				if okSrc and type(src) == "string" and src:find("PRY", 1, true) then
					local okUp, ups = pcall(debug.getupvalues, f)
					if okUp and type(ups) == "table" then
						for _, u in pairs(ups) do
							if type(u) == "function" then
								local okTest, value = pcall(u, 123, "TIME")
								if okTest and type(value) == "string" and #value > 0 then
									tokenFn = u
									getgenv().NEHUB_TOKEN_READY = true
									return true
								end
							end
						end
					end
				end
			end
		end
		if tokenIndex > #tokenList then
			tokenDone = true
			tokenList = nil
		end
		return false
	end

	local function polygon(seed)
		if type(tokenFn) ~= "function" then findToken() end
		if type(tokenFn) ~= "function" then return nil end
		local sec = tostring(math.floor(Workspace:GetServerTimeNow() * 100))
		local ok, tok = pcall(tokenFn, seed, "TIME")
		if not ok or type(tok) ~= "string" or #tok == 0 then return nil end
		local out = {}
		local n = #tok
		for i = 1, #sec do
			local a = (byte2(sec, i) + i) % 256
			local b = byte2(tok, (i - 1) % n + 1)
			out[i] = char2(xor(a, b))
		end
		return table.concat(out)
	end

	local captured = {}
	local hooked = {}
	local originals = {}
	local ownCall = false

	local function validArgs(args)
		return type(args) == "table" and #args >= 7 and #args <= 12
			and type(args[2]) == "string" and type(args[3]) == "string"
			and type(args[4]) == "number"
			and type(args[6]) == "table" and type(args[7]) == "table"
	end

	local function callIndex(idx, self, key)
		if type(idx) == "function" then return idx(self, key) end
		if type(idx) == "table" then return idx[key] end
		return nil
	end

	local function unhook()
		for meta, idx in pairs(originals) do
			pcall(function()
				if type(setro2) == "function" then pcall(setro2, meta, false) end
				meta.__index = idx
				if type(setro2) == "function" then pcall(setro2, meta, true) end
			end)
		end
		hooked = {}
		originals = {}
	end

	local function hook(remote)
		if next(captured) ~= nil then return end
		if type(getraw2) ~= "function" then return end
		local okMeta, meta = pcall(getraw2, remote)
		if not okMeta or type(meta) ~= "table" then return end
		if hooked[meta] then return end
		hooked[meta] = true
		local wasRO = false
		if type(isro2) == "function" then
			local okRO, ro = pcall(isro2, meta)
			wasRO = okRO and ro and true or false
		end
		if wasRO and type(setro2) == "function" then pcall(setro2, meta, false) end
		local idx = meta.__index
		originals[meta] = idx
		meta.__index = function(self, key)
			if (key == "FireServer" and self:IsA("RemoteEvent")) or (key == "InvokeServer" and self:IsA("RemoteFunction")) then
				return function(_, ...)
					local args = { ... }
					if validArgs(args) then
						if captured[self] and not ownCall and getgenv().NEHUB_BLOCK_GAME_PARRY ~= false then
							return nil
						end
						captured = { [self] = args }
						getgenv().NEHUB_HOOK_READY = true
						getgenv().NEHUB_HOOK_CAPTURED = true
						getgenv().NEHUB_REMOTE_NAME = self.Name
						getgenv().NEHUB_PARRY_ARGS = #args
						unhook()
					end
					local fn = callIndex(idx, self, key)
					if type(fn) == "function" then return fn(_, unpack2(args)) end
				end
			end
			return callIndex(idx, self, key)
		end
		if wasRO and type(setro2) == "function" then pcall(setro2, meta, true) end
	end

	local scanList = nil
	local scanIndex = 1
	local scanDone = false

	local function ensureHook()
		if next(captured) ~= nil then return end
		if os.clock() - bootAt < 2 then return end
		if scanDone then return end
		if not scanList then
			local ok, list = pcall(function() return RS:GetDescendants() end)
			if not ok or type(list) ~= "table" then return end
			scanList = list
			scanIndex = 1
		end
		local deadline = os.clock() + 0.003
		while scanIndex <= #scanList and os.clock() < deadline do
			local d = scanList[scanIndex]
			scanIndex = scanIndex + 1
			local ok, isRemote = pcall(function()
				return d:IsA("RemoteEvent") or d:IsA("RemoteFunction")
			end)
			if ok and isRemote then pcall(hook, d) end
		end
		if scanIndex > #scanList then
			scanDone = true
			scanList = nil
		end
	end

	local function buildArgs()
		local cam = Workspace.CurrentCamera
		if not cam then return nil end
		local cf = cam.CFrame
		local vs = cam.ViewportSize
		local ch = LocalPlayer.Character
		local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
		local alive = Workspace:FindFirstChild("Alive")
		local targetChar = nil
		if alive then
			local center = cam:ViewportPointToRay(vs.X * 0.5, vs.Y * 0.5).Direction
			local look = cf.LookVector
			local best = -math.huge
			for _, other in ipairs(alive:GetChildren()) do
				if other ~= ch and other.PrimaryPart then
					local rel = other.PrimaryPart.Position - cf.Position
					if rel.Magnitude > 0 and look:Dot(rel.Unit) > 0 then
						local score = center:Dot(rel.Unit)
						if score > best then best = score; targetChar = other end
					end
				end
			end
			if not targetChar then
				for _, other in ipairs(alive:GetChildren()) do
					if other ~= ch and other.PrimaryPart then targetChar = other; break end
				end
			end
		end
		local aim = targetChar and targetChar.PrimaryPart and targetChar.PrimaryPart.Position
			or (hrp and hrp.Position + cf.LookVector * 100)
			or cf.Position + cf.LookVector * 100
		local pt, vis = cam:WorldToScreenPoint(aim)
		local coords = (vis or pt.Z > 0) and { pt.X, pt.Y } or { vs.X * 0.5, vs.Y * 0.5 }
		local targets = {}
		if alive then
			for _, other in ipairs(alive:GetChildren()) do
				local pp = other.PrimaryPart
				if pp then
					local sp, sv = cam:WorldToScreenPoint(pp.Position)
					if sv or sp.Z > 0 then targets[other.Name] = sp end
				end
			end
		end
		return cf, targets, coords
	end

	local firstSignal = nil

	local function directFire()
		if not firstSignal then
			pcall(function()
				local signalOk, signalMod = false, nil
				local pryOk, pryFn = false, nil
				local packages = RS:FindFirstChild("Packages")
				local controllers = RS:FindFirstChild("Controllers")
				local signalInst = packages and packages:FindFirstChild("Signal")
				if signalInst then signalOk, signalMod = pcall(require, signalInst) end
				if controllers then
					for _, ctrl in ipairs(controllers:GetChildren()) do
						if ctrl.Name:find("SwordsController", 1, true) then
							local pry = ctrl:FindFirstChild("PRY")
							if pry then pryOk, pryFn = pcall(require, pry) end
							if pryOk then break end
						end
					end
				end
				if signalOk and pryOk and type(signalMod) == "table" and type(signalMod.new) == "function" and type(pryFn) == "function" then
					firstSignal = signalMod.new()
					firstSignal:Connect(pryFn)
				end
			end)
		end
		if not firstSignal then return false end
		local curve, targets, coords = buildArgs()
		if not curve then return false end
		local ok = pcall(function() firstSignal:Fire(0.5, curve, targets, coords, false) end)
		if ok then getgenv().NEHUB_LAST_FIRE = os.clock() end
		return ok
	end

	local api = {}

	function api.ready()
		findToken()
		ensureHook()
		return next(captured) ~= nil
	end

	function api.fire()
		findToken()
		ensureHook()
		if next(captured) == nil or type(tokenFn) ~= "function" then return false end
		local curve, targets, coords = buildArgs()
		if not curve then return false end
		local remote, sample = next(captured)
		local token = polygon(sample[2])
		if not token then return false end
		local args = {}
		for i = 1, #sample do args[i] = sample[i] end
		args[2] = sample[2]
		args[3] = token
		args[4] = sample[4] or 0.5
		args[5] = curve
		args[6] = targets
		args[7] = coords
		args[8] = false
		local ok = false
		ownCall = true
		if remote:IsA("RemoteEvent") then
			ok = pcall(function() remote:FireServer(unpack2(args)) end)
		elseif remote:IsA("RemoteFunction") then
			ok = pcall(function() remote:InvokeServer(unpack2(args)) end)
		end
		ownCall = false
		if ok then getgenv().NEHUB_LAST_FIRE = os.clock() end
		return ok
	end

	function api.directFire()
		return directFire()
	end

	return api
end)()

local ballsFolder = Workspace:WaitForChild("Balls", 5)
local ballCache = {}

local function refreshBalls()
	for i = #ballCache, 1, -1 do ballCache[i] = nil end
	if not ballsFolder then return end
	for _, ball in ipairs(ballsFolder:GetChildren()) do
		if ball:GetAttribute("realBall") then ballCache[#ballCache + 1] = ball end
	end
end

refreshBalls()

if ballsFolder then
	ballsFolder.ChildAdded:Connect(function(ball)
		refreshBalls()
		if ball then
			ball:GetAttributeChangedSignal("realBall"):Connect(refreshBalls)
		end
	end)
	ballsFolder.ChildRemoved:Connect(refreshBalls)
end

local cachedPing = 0
local pingAt = 0

local function pingValue()
	local now = os.clock()
	if now - pingAt > 0.4 then
		pingAt = now
		pcall(function()
			local item = Stats.Network.ServerStatsItem and Stats.Network.ServerStatsItem["Data Ping"]
			cachedPing = item and item:GetValue() or 0
		end)
	end
	return cachedPing
end

pcall(function()
	local remotes = RS:FindFirstChild("Remotes")
	if not remotes then return end
	for _, n in ipairs({ "ParrySuccess", "ParrySuccessAll" }) do
		local event = remotes:FindFirstChild(n)
		if event and event:IsA("RemoteEvent") then
			event.OnClientEvent:Connect(function()
				getgenv().NEHUB_LAST_SUCCESS = os.clock()
				getgenv().NEHUB_LOCK_UNTIL = os.clock() + 0.8
			end)
		end
	end
end)

local function speedDivisor(speed)
	return 2.2 + 0.9 * math.log(1 + speed / 80)
end

local lastAttempt = 0
local lastManual = 0
local lastAutoSpam = 0

local function tryFire()
	local now = os.clock()
	if now < (getgenv().NEHUB_LOCK_UNTIL or 0) then return false end
	if now - lastAttempt < 0.05 then return false end
	lastAttempt = now
	local ok = NEParry.fire()
	if not ok then ok = NEParry.directFire() end
	if ok then getgenv().NEHUB_LOCK_UNTIL = now + 0.3 end
	return ok
end

local function targetedBall()
	for _, candidate in ipairs(ballCache) do
		if candidate and candidate.Parent and candidate:GetAttribute("target") == LocalPlayer.Name then
			return candidate
		end
	end
	return nil
end

RunService.PreSimulation:Connect(function()
	local ch = LocalPlayer.Character
	local hum = ch and ch:FindFirstChildOfClass("Humanoid")
	local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
	if not hum or not hrp or hum.Health <= 0 then return end

	if getgenv().NEHUB_MANUAL_SPAM then
		local now = os.clock()
		if now - lastManual >= 0.15 then
			lastManual = now
			tryFire()
		end
	end

	local ball = targetedBall()
	if not ball then return end
	local zoomies = ball:FindFirstChild("zoomies")
	if not zoomies then return end
	local velocity = zoomies.VectorVelocity
	local speed = velocity.Magnitude
	if speed < 1 then return end
	local rel = hrp.Position - ball.Position
	local distance = rel.Magnitude
	local approach = velocity:Dot(rel / math.max(distance, 0.001))
	local threshold = clamp(pingValue() / 80, 4, 22) + math.max(speed / speedDivisor(speed), 9.5)
	local tti = distance / speed
	local pingAllowance = clamp(pingValue() / 1000, 0, 0.12)

	if getgenv().NEHUB_AP and approach > speed * 0.18 and (tti <= 0.55 + pingAllowance or distance <= threshold) then
		tryFire()
	end
	if getgenv().NEHUB_TRIGGER and approach > speed * 0.1 and distance <= threshold * 1.35 then
		tryFire()
	end
	if getgenv().NEHUB_AUTO_SPAM and approach > speed * 0.15 and distance <= threshold * 1.2 then
		local now = os.clock()
		if now - lastAutoSpam >= 0.08 then
			lastAutoSpam = now
			tryFire()
		end
	end
end)

pcall(function()
	local gui = Instance.new("ScreenGui")
	gui.Name = "NEHUB_VISUALIZER"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

	local part = Instance.new("Part")
	part.Name = "NEHubVisualizer"
	part.Anchored = true
	part.CanCollide = false
	part.CastShadow = false
	part.CanQuery = false
	part.Size = Vector3.new(10, 0.4, 10)
	part.Color = Color3.new(1, 0, 0)
	part.Transparency = 0.75
	part.Parent = Workspace

	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.FileMesh
	mesh.MeshId = "rbxassetid://471124075"
	mesh.Scale = Vector3.new(1, 1, 1)
	mesh.Parent = part

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(160, 60)
	billboard.StudsOffset = Vector3.new(0, 2, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = part

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.4
	label.Font = Enum.Font.GothamBold
	label.TextSize = 16
	label.Text = "Distance"
	label.Parent = billboard

	RunService.RenderStepped:Connect(function()
		local ball = nil
		for _, candidate in ipairs(ballCache) do
			if candidate and candidate.Parent then ball = candidate; break end
		end
		if not ball or not ball.Parent then
			part.Transparency = 1
			return
		end
		part.Transparency = 0.75
		part.Position = ball.Position
		local hrpChar = LocalPlayer.Character
		local hrp = hrpChar and hrpChar:FindFirstChild("HumanoidRootPart")
		local dist = hrp and (hrp.Position - ball.Position).Magnitude or 0
		local scale = clamp(dist / 12, 0.4, 4)
		mesh.Scale = Vector3.new(scale, 1, scale)
		part.Color = ball:GetAttribute("target") == LocalPlayer.Name and Color3.new(1, 0, 0) or Color3.new(1, 1, 1)
		label.Text = string.format("Distance\n%d", math.floor(dist + 0.5))
	end)
end)

task.delay(3, function()
	pcall(function() NEParry.ready() end)
	local status = getgenv().NEHUB_HOOK_READY and "HOOK OK" or "HOOK NOT FOUND"
	local detail = " | token=" .. tostring(getgenv().NEHUB_TOKEN_READY == true)
		.. " | captured=" .. tostring(getgenv().NEHUB_HOOK_CAPTURED == true)
	notify("Remote Hook", status .. detail, 6)
end)
