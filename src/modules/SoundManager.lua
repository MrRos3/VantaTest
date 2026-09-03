local cloneref = (cloneref or clonereference or function(instance)
	return instance
end)

local Debris = cloneref(game:GetService("Debris"))
local SoundService = cloneref(game:GetService("SoundService"))

local SoundManager = {
	WindUI = nil,
	Request = http_request or (syn and syn.request) or request,
	Cache = {},
	Loading = {},
	LastPlayed = {},
	Warned = {},
}

local DEFAULT_BASE_URL = "https://raw.githubusercontent.com/MrRos3/VantaTest/main/assets/sounds"
local FALLBACK_SOUND = "rbxasset://sounds/electronicpingshort.wav"

local Events = {
	"Hover",
	"Click",
	"Tab",
	"ToggleOn",
	"ToggleOff",
	"DropdownOpen",
	"DropdownClose",
	"Select",
	"SliderTick",
	"InputFocus",
	"InputSubmit",
	"Notification",
	"NotificationClose",
	"WindowOpen",
	"WindowClose",
	"Success",
	"Error",
}

local Assets = {
	["vanta-tap"] = "vanta-tap.wav",
	["vanta-pulse"] = "vanta-pulse.wav",
	["glass-tap"] = "glass-tap.wav",
	["glass-chime"] = "glass-chime.wav",
	["soft-pop"] = "soft-pop.wav",
	["soft-tick"] = "soft-tick.wav",
	["mechanical-click"] = "mechanical-click.wav",
	["mechanical-switch"] = "mechanical-switch.wav",
	["digital-blip"] = "digital-blip.wav",
	["digital-confirm"] = "digital-confirm.wav",
	["cyber-pulse"] = "cyber-pulse.wav",
	["cyber-sweep"] = "cyber-sweep.wav",
	["deep-thump"] = "deep-thump.wav",
	["deep-close"] = "deep-close.wav",
	["arcade-coin"] = "arcade-coin.wav",
	["arcade-select"] = "arcade-select.wav",
	["crystal-tick"] = "crystal-tick.wav",
	["crystal-chime"] = "crystal-chime.wav",
	["bubble-pop"] = "bubble-pop.wav",
	["bubble-drop"] = "bubble-drop.wav",
	["minimal-tick"] = "minimal-tick.wav",
	["minimal-confirm"] = "minimal-confirm.wav",
	["retro-click"] = "retro-click.wav",
	["retro-power"] = "retro-power.wav",
	["airy-rise"] = "airy-rise.wav",
	["airy-fall"] = "airy-fall.wav",
	["notification-chime"] = "notification-chime.wav",
	["notification-bell"] = "notification-bell.wav",
	["success-sparkle"] = "success-sparkle.wav",
	["error-buzz"] = "error-buzz.wav",
}

local PackSources = {
	["Vanta Pulse"] = { "vanta-tap", "vanta-pulse" },
	Glass = { "glass-tap", "glass-chime" },
	Soft = { "soft-tick", "soft-pop" },
	Mechanical = { "mechanical-click", "mechanical-switch" },
	Digital = { "digital-blip", "digital-confirm" },
	Cyber = { "cyber-pulse", "cyber-sweep" },
	Deep = { "deep-thump", "deep-close" },
	Arcade = { "arcade-select", "arcade-coin" },
	Crystal = { "crystal-tick", "crystal-chime" },
	Bubble = { "bubble-drop", "bubble-pop" },
	Minimal = { "minimal-tick", "minimal-confirm" },
	Retro = { "retro-click", "retro-power" },
}

local PresetOrder = {
	"Vanta Pulse",
	"Glass",
	"Soft",
	"Mechanical",
	"Digital",
	"Cyber",
	"Deep",
	"Arcade",
	"Crystal",
	"Bubble",
	"Minimal",
	"Retro",
}

local RateLimits = {
	Hover = 0.075,
	SliderTick = 0.045,
	Click = 0.025,
	Tab = 0.04,
}

local function makePreset(primary, accent)
	return {
		Hover = { Sound = primary, Volume = 0.18, Pitch = 1.22 },
		Click = { Sound = primary, Volume = 0.72, Pitch = 1 },
		Tab = { Sound = accent, Volume = 0.62, Pitch = 1.06 },
		ToggleOn = { Sound = accent, Volume = 0.7, Pitch = 1.12 },
		ToggleOff = { Sound = primary, Volume = 0.55, Pitch = 0.86 },
		DropdownOpen = { Sound = accent, Volume = 0.54, Pitch = 1.2 },
		DropdownClose = { Sound = primary, Volume = 0.44, Pitch = 0.78 },
		Select = { Sound = primary, Volume = 0.62, Pitch = 1.08 },
		SliderTick = { Sound = primary, Volume = 0.24, Pitch = 1.28 },
		InputFocus = { Sound = primary, Volume = 0.34, Pitch = 1.16 },
		InputSubmit = { Sound = accent, Volume = 0.55, Pitch = 1 },
		Notification = { Sound = accent, Volume = 0.76, Pitch = 0.96 },
		NotificationClose = { Sound = primary, Volume = 0.4, Pitch = 0.76 },
		WindowOpen = { Sound = accent, Volume = 0.8, Pitch = 0.82 },
		WindowClose = { Sound = primary, Volume = 0.64, Pitch = 0.7 },
		Success = { Sound = accent, Volume = 0.82, Pitch = 1.18 },
		Error = { Sound = "error-buzz", Volume = 0.7, Pitch = 1 },
	}
end

local Presets = {}
for name, sources in pairs(PackSources) do
	Presets[name] = makePreset(sources[1], sources[2])
end

local function copyTable(value)
	local result = {}
	if typeof(value) == "table" then
		for key, item in pairs(value) do
			result[key] = typeof(item) == "table" and copyTable(item) or item
		end
	end
	return result
end

local function sanitize(value)
	return tostring(value):gsub("[^%w%-_]", "_"):sub(1, 80)
end

local function ensureFolder(path)
	if not makefolder then
		return
	end

	local current = ""
	for part in string.gmatch(path, "[^/]+") do
		current = current == "" and part or current .. "/" .. part
		if not isfolder or not isfolder(current) then
			pcall(makefolder, current)
		end
	end
end

local function mergeEntry(base, override)
	if override == false then
		return false
	end
	if typeof(override) == "string" then
		override = { Sound = override }
	end

	local result = copyTable(base)
	if typeof(override) == "table" then
		for key, value in pairs(override) do
			result[key] = value
		end
	end
	return result
end

function SoundManager:Init(WindUI)
	self.WindUI = WindUI
	self.Config = {
		Enabled = false,
		Preset = "Vanta Pulse",
		Volume = 0.45,
		Pitch = 1,
		Folder = "VantaUI",
		BaseUrl = DEFAULT_BASE_URL,
		Overrides = {},
		Assets = {},
	}
	self.ActiveMap = copyTable(Presets[self.Config.Preset])
	return self
end

function SoundManager:_warnOnce(key, message)
	if self.Warned[key] then
		return
	end
	self.Warned[key] = true
	warn("[VantaUI Sounds] " .. message)
end

function SoundManager:_download(url)
	local errors = {}
	if game.HttpGet then
		local success, body = pcall(function()
			return game:HttpGet(url)
		end)
		if success and typeof(body) == "string" and #body > 0 then
			return body
		end
		table.insert(errors, tostring(body))
	end

	if self.Request then
		local success, response = pcall(function()
			return self.Request({
				Url = url,
				Method = "GET",
				Headers = { ["User-Agent"] = "Roblox/Executor" },
			})
		end)
		local body = success and typeof(response) == "table" and (response.Body or response.body) or response
		if success and typeof(body) == "string" and #body > 0 then
			return body
		end
		table.insert(errors, tostring(response))
	end

	error("Unable to download sound: " .. table.concat(errors, "; "))
end

function SoundManager:_sourceFor(soundName)
	local source = self.Config.Assets[soundName] or Assets[soundName] or soundName
	if typeof(source) ~= "string" then
		return nil
	end

	if Assets[soundName] and not string.match(source, "^https?://") and not string.match(source, "^rbxasset") then
		return self.Config.BaseUrl:gsub("/+$", "") .. "/" .. source
	end
	return source
end

function SoundManager:_loadSoundId(soundName)
	local source = self:_sourceFor(soundName)
	if not source then
		return FALLBACK_SOUND
	end
	if string.match(source, "^rbxasset") or string.match(source, "^synasset") then
		return source
	end
	if not string.match(source, "^https?://") then
		return source
	end
	if self.Cache[source] then
		return self.Cache[source]
	end

	while self.Loading[source] do
		task.wait()
	end
	if self.Cache[source] then
		return self.Cache[source]
	end

	local getAsset = getcustomasset or getsynasset
	if not writefile or not getAsset then
		self:_warnOnce("unsupported", "This executor cannot load downloaded audio, so the built-in fallback sound is being used.")
		self.Cache[source] = FALLBACK_SOUND
		return FALLBACK_SOUND
	end

	self.Loading[source] = true
	local success, result = pcall(function()
		local cleanSource = source:match("^([^?#]+)") or source
		local extension = cleanSource:match("%.([%w]+)$") or "wav"
		local soundFolder = "WindUI/" .. sanitize(self.Config.Folder) .. "/sounds"
		local fileName = soundFolder .. "/" .. sanitize(soundName) .. "." .. string.lower(extension)
		ensureFolder(soundFolder)

		if not isfile or not isfile(fileName) then
			writefile(fileName, self:_download(source))
		end

		local loaded, asset = pcall(getAsset, fileName)
		if not loaded then
			writefile(fileName, self:_download(source))
			asset = getAsset(fileName)
		end
		return asset
	end)
	self.Loading[source] = nil

	if success and result then
		self.Cache[source] = result
		return result
	end

	self:_warnOnce(source, "Could not load " .. tostring(soundName) .. ": " .. tostring(result))
	self.Cache[source] = FALLBACK_SOUND
	return FALLBACK_SOUND
end

function SoundManager:_playEntry(eventName, entry, options)
	if not entry or entry == false or not entry.Sound then
		return false
	end
	options = options or {}

	local now = os.clock()
	local rateLimit = tonumber(options.RateLimit) or RateLimits[eventName] or 0
	if not options.Force and now - (self.LastPlayed[eventName] or 0) < rateLimit then
		return false
	end
	self.LastPlayed[eventName] = now

	task.spawn(function()
		local soundId = self:_loadSoundId(entry.Sound)
		local sound = Instance.new("Sound")
		sound.Name = "VantaUI_" .. sanitize(eventName)
		sound.SoundId = soundId
		sound.Volume = math.clamp(
			(tonumber(options.Volume) or tonumber(entry.Volume) or 1) * self.Config.Volume,
			0,
			10
		)
		sound.PlaybackSpeed = math.clamp(
			(tonumber(options.Pitch) or tonumber(entry.Pitch) or 1) * self.Config.Pitch,
			0.25,
			4
		)
		sound.Parent = SoundService
		sound:Play()
		Debris:AddItem(sound, 6)
	end)
	return true
end

function SoundManager:_refreshMap()
	local preset = Presets[self.Config.Preset] or Presets["Vanta Pulse"]
	self.ActiveMap = copyTable(preset)
	for eventName, override in pairs(self.Config.Overrides) do
		self.ActiveMap[eventName] = mergeEntry(self.ActiveMap[eventName], override)
	end
end

function SoundManager:Configure(config)
	if config == false then
		self.Config.Enabled = false
		return self:GetConfig()
	end
	config = config or {}

	if config.Enabled ~= nil then
		self.Config.Enabled = config.Enabled == true
	end
	if config.Preset and Presets[config.Preset] then
		self.Config.Preset = config.Preset
	end
	if config.Volume ~= nil then
		self.Config.Volume = math.clamp(tonumber(config.Volume) or self.Config.Volume, 0, 2)
	end
	if config.Pitch ~= nil then
		self.Config.Pitch = math.clamp(tonumber(config.Pitch) or self.Config.Pitch, 0.5, 2)
	end
	if config.Folder then
		self.Config.Folder = tostring(config.Folder)
	end
	if config.BaseUrl then
		self.Config.BaseUrl = tostring(config.BaseUrl)
	end
	if typeof(config.Assets) == "table" then
		for name, source in pairs(config.Assets) do
			self.Config.Assets[name] = source
		end
	end
	if typeof(config.Overrides) == "table" then
		for eventName, entry in pairs(config.Overrides) do
			self.Config.Overrides[eventName] = typeof(entry) == "table" and copyTable(entry) or entry
		end
	end

	self:_refreshMap()
	if self.Config.Enabled then
		self:PreloadPreset(self.Config.Preset)
	end
	return self:GetConfig()
end

function SoundManager:SetEnabled(value)
	self.Config.Enabled = value == true
	if self.Config.Enabled then
		self:PreloadPreset(self.Config.Preset)
	end
	return self.Config.Enabled
end

function SoundManager:SetPreset(name)
	if not Presets[name] then
		return false
	end
	self.Config.Preset = name
	self:_refreshMap()
	if self.Config.Enabled then
		self:PreloadPreset(name)
	end
	return true
end

function SoundManager:SetVolume(value)
	self.Config.Volume = math.clamp(tonumber(value) or self.Config.Volume, 0, 2)
	return self.Config.Volume
end

function SoundManager:SetPitch(value)
	self.Config.Pitch = math.clamp(tonumber(value) or self.Config.Pitch, 0.5, 2)
	return self.Config.Pitch
end

function SoundManager:SetSoundForEvent(eventName, sound, options)
	if not table.find(Events, eventName) then
		return false
	end
	if sound == false then
		self.Config.Overrides[eventName] = false
	else
		local entry = typeof(sound) == "table" and copyTable(sound) or copyTable(options)
		if typeof(sound) == "string" then
			entry.Sound = sound
		end
		self.Config.Overrides[eventName] = entry
	end
	self:_refreshMap()
	return true
end

function SoundManager:ClearSoundOverride(eventName)
	self.Config.Overrides[eventName] = nil
	self:_refreshMap()
end

function SoundManager:ClearSoundOverrides()
	self.Config.Overrides = {}
	self:_refreshMap()
end

function SoundManager:Play(eventName, options)
	options = options or {}
	if not self.Config.Enabled and not options.Force then
		return false
	end
	return self:_playEntry(eventName, self.ActiveMap[eventName], options)
end

function SoundManager:Preview(soundName, options)
	options = copyTable(options)
	options.Force = true
	return self:_playEntry("Preview_" .. tostring(soundName), {
		Sound = soundName,
		Volume = 0.82,
		Pitch = 1,
	}, options)
end

function SoundManager:PreloadPreset(name)
	local preset = Presets[name]
	if not preset then
		return
	end
	task.spawn(function()
		local seen = {}
		for _, entry in pairs(preset) do
			if entry and entry.Sound and not seen[entry.Sound] then
				seen[entry.Sound] = true
				self:_loadSoundId(entry.Sound)
			end
		end
	end)
end

function SoundManager:GetConfig()
	return copyTable(self.Config)
end

function SoundManager:GetEvents()
	return copyTable(Events)
end

function SoundManager:GetPresetNames()
	return copyTable(PresetOrder)
end

function SoundManager:GetSoundNames()
	local names = {}
	for name in pairs(Assets) do
		table.insert(names, name)
	end
	for name in pairs(self.Config.Assets) do
		if not table.find(names, name) then
			table.insert(names, name)
		end
	end
	table.sort(names)
	return names
end

return SoundManager
