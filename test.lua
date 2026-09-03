local cacheBuster = tostring(os.time()) .. "-" .. tostring(math.random(100000, 999999))
local VantaUI = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/MrRos3/VantaTest/main/main.lua?v=" .. cacheBuster
))()
local HttpService = game:GetService("HttpService")

local Window = VantaUI:CreateWindow({
    Title = "VantaTest Sound Lab",
    Icon = "music",
    Theme = "Salty Special",
    StartupTab = "Sound Lab",
    HideSearchBar = false,
    Sounds = {
        Enabled = true,
        Preset = "Vanta Pulse",
        Volume = 0.45,
        Pitch = 1,
        Folder = "VantaTest",
    },
    Branding = {
        Name = "VANTA",
        Image = VantaUI.Brand.Image,
        Folder = "VantaUI",
        IconSize = 24,
        IconRadius = 7,
        OpenButtonIconRadius = 8,
        Intro = false,
    },
    OpenButton = {
        Title = "Open VantaUI",
        Enabled = true,
        Draggable = true,
        OnlyMobile = false,
        OnlyIcon = true,
        CornerRadius = UDim.new(0, 11),
        StrokeThickness = 2,
        ImageZoom = 1,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromHex("#000000")),
            ColorSequenceKeypoint.new(1, Color3.fromHex("#000000")),
        }),
    },
})

Window:Tag({
    Title = "SOUND LAB • v" .. VantaUI.Version,
    Icon = "audio-lines",
    Color = Color3.fromHex("#151116"),
    Border = true,
})

local Home = Window:Tab({ Title = "Home", Icon = "house" })
local SoundLab = Window:Tab({ Title = "Sound Lab", Icon = "sliders-horizontal" })
local Presets = Window:Tab({ Title = "Sound Packs", Icon = "list-music" })
local Events = Window:Tab({ Title = "Event Tester", Icon = "mouse-pointer-click" })
local Gallery = Window:Tab({ Title = "Sound Gallery", Icon = "music-2" })
local Themes = Window:Tab({ Title = "Themes", Icon = "palette" })
local About = Window:Tab({ Title = "About", Icon = "info" })

Home:Button({
    Title = "VantaTest sound system is active",
    Desc = "Every major control now has audio. Use the Sound Lab to tune it live.",
    Icon = "audio-lines",
    Callback = function()
        VantaUI:Notify({
            Content = "VantaTest v" .. VantaUI.Version .. " sound lab is running 🎧",
            Icon = "music",
        })
    end,
})

Home:Toggle({
    Title = "Try the toggle sounds",
    Desc = "Listen for separate ON and OFF sounds.",
    Value = false,
    Callback = function() end,
})

Home:Dropdown({
    Title = "Try the dropdown sounds",
    Desc = "Opening, closing, and selecting each have their own event.",
    Values = { "Vanta", "Glass", "Cyber", "Arcade" },
    Value = "Vanta",
    Callback = function() end,
})

Home:Slider({
    Title = "Try the slider ticks",
    Desc = "The tick pitch follows the slider position.",
    Value = { Min = 0, Max = 100, Default = 50 },
    Step = 1,
    Callback = function() end,
})

Home:Input({
    Title = "Try input focus",
    Desc = "Focus the box, type something, then submit it.",
    Placeholder = "Type here...",
    Value = "",
    Callback = function() end,
})

Home:Button({
    Title = "Test a real notification",
    Desc = "Plays the notification sound and opens a notification card.",
    Icon = "bell",
    Callback = function()
        VantaUI:Notify({
            Title = "Sound check",
            Content = "This is the current notification sound.",
            Icon = "bell",
            Duration = 5,
        })
    end,
})

Home:Button({
    Title = "Minimize and test the open sound",
    Desc = "The close sound plays now; click the Vanta badge to hear the open sound.",
    Icon = "minimize-2",
    Callback = function()
        Window:Close()
    end,
})

local presetNames = VantaUI:GetSoundPresets()
local eventNames = VantaUI:GetSoundEvents()
local soundNames = VantaUI:GetSoundNames()
local selectedEvent = "Click"
local selectedSound = "vanta-tap"

SoundLab:Toggle({
    Title = "GUI sounds enabled",
    Desc = "Mute or restore every automatic interface sound.",
    Value = true,
    Callback = function(value)
        VantaUI:SetSoundEnabled(value)
    end,
})

local presetControlReady = false
SoundLab:Dropdown({
    Title = "Active sound pack",
    Desc = "Switch all event defaults at once.",
    Values = presetNames,
    Value = "Vanta Pulse",
    SearchBarEnabled = true,
    Callback = function(value)
        if not presetControlReady then
            return
        end
        VantaUI:SetSoundPreset(value)
        VantaUI:PlaySound("Success", { Force = true })
    end,
})
presetControlReady = true

SoundLab:Slider({
    Title = "Master volume",
    Desc = "0% to 200% so quiet sounds can be compared easily.",
    Value = { Min = 0, Max = 200, Default = 45 },
    Step = 1,
    Callback = function(value)
        VantaUI:SetSoundVolume(value / 100)
    end,
})

SoundLab:Slider({
    Title = "Master pitch",
    Desc = "50% is deep and slow; 200% is bright and fast.",
    Value = { Min = 50, Max = 200, Default = 100 },
    Step = 1,
    Callback = function(value)
        VantaUI:SetSoundPitch(value / 100)
    end,
})

SoundLab:Dropdown({
    Title = "Event to customize",
    Desc = "Choose which GUI action you want to change.",
    Values = eventNames,
    Value = selectedEvent,
    SearchBarEnabled = true,
    Callback = function(value)
        selectedEvent = value
    end,
})

SoundLab:Dropdown({
    Title = "Replacement sound",
    Desc = "Any of the 30 sound files can be used for any event.",
    Values = soundNames,
    Value = selectedSound,
    SearchBarEnabled = true,
    Callback = function(value)
        selectedSound = value
    end,
})

SoundLab:Button({
    Title = "Preview the selected sound",
    Desc = "Plays only the replacement sound, without changing anything.",
    Icon = "play",
    Sound = false,
    HoverSound = false,
    Callback = function()
        VantaUI:PreviewSound(selectedSound)
    end,
})

SoundLab:Button({
    Title = "Apply sound to selected event",
    Desc = "Creates a live override for this event.",
    Icon = "check",
    Sound = false,
    HoverSound = false,
    Callback = function()
        VantaUI:SetSoundForEvent(selectedEvent, selectedSound)
        VantaUI:PreviewSound(selectedSound)
        VantaUI:Notify({
            Title = "Sound assigned",
            Content = selectedEvent .. " now uses " .. selectedSound .. ".",
            Icon = "check",
        })
    end,
})

SoundLab:Button({
    Title = "Restore this event to the pack default",
    Desc = "Removes the individual override without changing the active pack.",
    Icon = "rotate-ccw",
    Sound = false,
    HoverSound = false,
    Callback = function()
        VantaUI:ClearSoundOverride(selectedEvent)
        VantaUI:PlaySound(selectedEvent, { Force = true })
    end,
})

SoundLab:Button({
    Title = "Clear every custom event sound",
    Desc = "Returns all 17 events to the active pack defaults.",
    Icon = "eraser",
    Sound = false,
    HoverSound = false,
    Callback = function()
        VantaUI:ClearSoundOverrides()
        VantaUI:PlaySound("Success", { Force = true })
    end,
})

SoundLab:Button({
    Title = "Copy my current sound settings",
    Desc = "Copies the setup when supported and always prints it to the console.",
    Icon = "copy",
    Sound = false,
    HoverSound = false,
    Callback = function()
        local encoded = HttpService:JSONEncode(VantaUI:GetSoundConfig())
        print("[VantaTest Sound Config] " .. encoded)
        if setclipboard then
            setclipboard(encoded)
        end
        VantaUI:Notify({
            Title = "Sound settings ready",
            Content = setclipboard and "Copied to your clipboard." or "Printed to the executor console.",
            Icon = "copy",
        })
    end,
})

SoundLab:Button({
    Title = "Preview all event sounds",
    Desc = "Plays the current sound for every supported GUI event in order.",
    Icon = "list-music",
    Sound = false,
    HoverSound = false,
    Callback = function()
        task.spawn(function()
            for _, eventName in ipairs(eventNames) do
                VantaUI:PlaySound(eventName, { Force = true })
                task.wait(0.38)
            end
        end)
    end,
})

for _, presetName in ipairs(presetNames) do
    local name = presetName
    Presets:Button({
        Title = name,
        Desc = "Use and preview the " .. name .. " sound pack.",
        Icon = "disc-3",
        Sound = false,
        HoverSound = false,
        Callback = function()
            VantaUI:SetSoundPreset(name)
            VantaUI:PlaySound("Success", { Force = true })
        end,
    })
end

for _, eventName in ipairs(eventNames) do
    local name = eventName
    Events:Button({
        Title = name,
        Desc = "Preview the current " .. name .. " event sound.",
        Icon = "play",
        Sound = false,
        HoverSound = false,
        Callback = function()
            VantaUI:PlaySound(name, { Force = true })
        end,
    })
end

for _, soundName in ipairs(soundNames) do
    local name = soundName
    Gallery:Button({
        Title = name,
        Desc = "Preview this original VantaTest sound file.",
        Icon = "volume-2",
        Sound = false,
        HoverSound = false,
        Callback = function()
            VantaUI:PreviewSound(name)
        end,
    })
end

local function addThemeButton(themeName, icon)
    Themes:Button({
        Title = themeName,
        Desc = "Switch the whole interface to " .. themeName .. ".",
        Icon = icon,
        Callback = function()
            VantaUI:SetTheme(themeName)
            VantaUI:Notify({
                Content = "Theme changed to " .. themeName,
                Icon = icon,
            })
        end,
    })
end

addThemeButton("Salty Special", "sparkles")
addThemeButton("Vanta Smoked", "cloud-fog")
addThemeButton("Vanta Dark", "moon")
addThemeButton("Vanta AMOLED", "circle-dot")
addThemeButton("Vanta Violet", "wand-sparkles")

About:Button({
    Title = "VantaTest sound experiment",
    Desc = "12 packs • 30 sounds • 17 independently configurable GUI events.",
    Icon = "github",
    Callback = function()
        VantaUI:Notify({
            Content = "Try everything, then tell me the pack and sounds you want to keep 🖤",
            Icon = "heart",
        })
    end,
})
