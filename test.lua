--[[
    VantaTest feature showcase
    Redz-style module layout rebuilt with VantaUI.

    Gameplay-specific controls are routed through a handler registry instead of
    hard-coding game internals into the UI layer. This keeps VantaUI reusable
    while giving every feature a real toggle/button state and callback surface.
]]

local cacheBuster = tostring(os.time()) .. "-" .. tostring(math.random(100000, 999999))
local VantaUI = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/MrRos3/VantaTest/main/main.lua?v=" .. cacheBuster
))()

assert(type(VantaUI) == "table", "[VantaTest] Failed to load VantaUI")

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

VantaUI:SetTheme("Salty Special")

local Window = VantaUI:CreateWindow({
    Title = "Vanta",
    Author = "MrRos3",
    Theme = "Salty Special",
    StartupTab = "Home",
    Size = UDim2.fromOffset(800, 540),
    Resizable = true,
    HideSearchBar = false,
    ScrollBarEnabled = true,
    NewElements = true,
    Topbar = {
        Height = 44,
        ButtonsType = "Mac",
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
        Title = "Vanta",
        Enabled = true,
        Draggable = true,
        OnlyIcon = true,
        OnlyMobile = false,
        CornerRadius = UDim.new(0, 11),
        StrokeThickness = 2,
        ImageZoom = 1,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromHex("#000000")),
            ColorSequenceKeypoint.new(1, Color3.fromHex("#000000")),
        }),
    },
    User = {
        Enabled = false,
    },
})

Window:Tag({
    Title = "FEATURE BUILD",
    Icon = "layers-3",
    Border = true,
})

local FeatureState = {}
local FeatureHandlers = getgenv().VantaFeatureHandlers or {}
getgenv().VantaFeatureHandlers = FeatureHandlers
getgenv().VantaFeatureState = FeatureState

local function notify(title, content, icon)
    VantaUI:Notify({
        Title = title or "Vanta",
        Content = content or "",
        Icon = icon or "sparkles",
        Duration = 4,
    })
end

local function callHandler(id, ...)
    local handler = FeatureHandlers[id]
    if type(handler) ~= "function" then
        return false
    end

    local ok, err = pcall(handler, ...)
    if not ok then
        warn("[Vanta] Feature handler failed: " .. tostring(id) .. " -> " .. tostring(err))
        notify("Feature error", tostring(err), "triangle-alert")
    end

    return ok
end

local function addToggle(tab, id, title, desc, icon, default)
    FeatureState[id] = default == true

    tab:Toggle({
        Title = title,
        Desc = desc,
        Icon = icon,
        Default = default == true,
        Callback = function(value)
            FeatureState[id] = value == true
            callHandler(id, FeatureState[id])
        end,
    })
end

local function addButton(tab, id, title, desc, icon)
    tab:Button({
        Title = title,
        Desc = desc,
        Icon = icon,
        Callback = function()
            if not callHandler(id) then
                notify("Vanta", title .. " is ready for a game-owned handler.", icon)
            end
        end,
    })
end

local function addSection(tab, title)
    tab:Section({
        Title = title,
        TextSize = 16,
    })
end

local Home = Window:Tab({ Title = "Home", Icon = "house" })
local Fishing = Window:Tab({ Title = "Auto Fishing", Icon = "fish" })
local QuestItems = Window:Tab({ Title = "Quest | Items", Icon = "swords" })
local VolcanoDojo = Window:Tab({ Title = "Volcano Dojo", Icon = "flame" })
local SeaEvent = Window:Tab({ Title = "Sea Event", Icon = "waves" })
local RaceV4 = Window:Tab({ Title = "Race V4", Icon = "crown" })
local RaidFruits = Window:Tab({ Title = "Raid Fruits", Icon = "bomb" })
local FruitsStock = Window:Tab({ Title = "Fruits | Stock", Icon = "apple" })
local Teleport = Window:Tab({ Title = "Teleport", Icon = "map-pin" })
local PvP = Window:Tab({ Title = "PvP Player", Icon = "users" })
local Shop = Window:Tab({ Title = "Shop", Icon = "shopping-cart" })
local Settings = Window:Tab({ Title = "Settings", Icon = "settings" })

-- HOME
addSection(Home, "Vanta Feature Hub")

Home:Paragraph({
    Title = "Welcome " .. tostring(LocalPlayer and LocalPlayer.DisplayName or "Player"),
    Desc = "Redz-style feature organization rebuilt inside VantaUI. Home remains the startup page.",
})

Home:Button({
    Title = "Feature status",
    Desc = "Show how many Vanta feature switches are currently enabled.",
    Icon = "activity",
    Callback = function()
        local enabled = 0
        local total = 0

        for _, value in pairs(FeatureState) do
            total += 1
            if value then
                enabled += 1
            end
        end

        notify("Vanta Feature Status", tostring(enabled) .. " / " .. tostring(total) .. " switches enabled", "activity")
    end,
})

Home:Button({
    Title = "Test notification",
    Desc = "Confirm Vanta buttons, icons, and notifications.",
    Icon = "bell",
    Callback = function()
        notify("Vanta", "Feature build is alive 🖤", "sparkles")
    end,
})

-- AUTO FISHING
addSection(Fishing, "Fishing")
addToggle(Fishing, "auto_fishing", "Auto Fishing", "Main fishing automation switch.", "fish", false)
addToggle(Fishing, "auto_reel", "Auto Reel", "Reel helper state for supported fishing systems.", "rotate-cw", false)
addToggle(Fishing, "auto_bait", "Auto Bait", "Bait selection helper state.", "package-open", false)
addToggle(Fishing, "fish_radar", "Fish Radar", "Fishing radar display state.", "radar", false)

-- QUEST | ITEMS
addSection(QuestItems, "Quest Farming")
addToggle(QuestItems, "auto_quest", "Auto Quest", "Quest progression switch.", "scroll-text", false)
addToggle(QuestItems, "auto_level", "Auto Level", "Level progression switch.", "trending-up", false)
addToggle(QuestItems, "auto_mastery", "Auto Mastery", "Weapon / fruit mastery progression switch.", "badge-up", false)
addToggle(QuestItems, "auto_boss", "Auto Boss", "Boss rotation switch.", "skull", false)
addToggle(QuestItems, "elite_hunter", "Elite Hunter", "Elite target switch.", "crosshair", false)

addSection(QuestItems, "Items & Currency")
addToggle(QuestItems, "auto_chest", "Auto Chest", "Chest collection switch.", "archive", false)
addToggle(QuestItems, "farm_materials", "Farm Materials", "Material farming switch.", "boxes", false)
addToggle(QuestItems, "farm_bones", "Farm Bones", "Bone farming switch.", "bone", false)
addToggle(QuestItems, "farm_fragments", "Farm Fragments", "Fragment farming switch.", "gem", false)
addToggle(QuestItems, "auto_haki", "Auto Haki", "Haki progression / activation switch.", "shield", false)

-- VOLCANO DOJO
addSection(VolcanoDojo, "Volcano")
addToggle(VolcanoDojo, "volcano_event", "Volcano Event", "Volcano event helper switch.", "volcano", false)
addToggle(VolcanoDojo, "volcano_progress", "Volcano Progress", "Track volcano progression state.", "chart-no-axes-column-increasing", false)

addSection(VolcanoDojo, "Dojo")
addToggle(VolcanoDojo, "dojo_helper", "Dojo Helper", "Dojo progression helper switch.", "dumbbell", false)
addToggle(VolcanoDojo, "dojo_tasks", "Dojo Tasks", "Dojo task automation state.", "list-checks", false)

-- SEA EVENT
addSection(SeaEvent, "Sea Hunting")
addToggle(SeaEvent, "sea_beast", "Sea Beast Hunter", "Sea Beast hunting switch.", "ship-wheel", false)
addToggle(SeaEvent, "mirage_island", "Mirage Island", "Mirage Island finder switch.", "island", false)
addToggle(SeaEvent, "terror_shark", "Terrorshark", "Terrorshark event switch.", "shark", false)
addToggle(SeaEvent, "ship_farm", "Ship Farm", "Ship event farming switch.", "ship", false)
addToggle(SeaEvent, "auto_boat", "Auto Boat", "Boat navigation state.", "navigation", false)

-- RACE V4
addSection(RaceV4, "Race Progression")
addToggle(RaceV4, "race_v4", "Race V4", "Race V4 progression switch.", "crown", false)
addToggle(RaceV4, "race_awakening", "Race Awakening", "Race awakening progression state.", "sparkles", false)
addToggle(RaceV4, "race_trials", "Race Trials", "Race trial helper state.", "timer", false)

-- RAID FRUITS
addSection(RaidFruits, "Raids")
addToggle(RaidFruits, "auto_raid", "Auto Raid", "Raid progression switch.", "swords", false)
addToggle(RaidFruits, "auto_awaken", "Auto Awaken", "Fruit awakening state.", "zap", false)
addToggle(RaidFruits, "raid_retry", "Auto Retry", "Repeat raid state.", "repeat", false)
addToggle(RaidFruits, "raid_fragments", "Fragment Farm", "Raid fragment farming state.", "gem", false)

-- FRUITS | STOCK
addSection(FruitsStock, "Fruit Tools")
addToggle(FruitsStock, "fruit_notifier", "Fruit Notifier", "Notify when supported fruit events occur.", "bell-ring", false)
addToggle(FruitsStock, "fruit_esp", "Fruit ESP", "Fruit display overlay state.", "eye", false)
addToggle(FruitsStock, "fruit_sniper", "Fruit Sniper", "Target-fruit search state.", "scan-search", false)
addToggle(FruitsStock, "auto_store_fruit", "Auto Store Fruit", "Fruit storage state.", "package-check", false)
addButton(FruitsStock, "check_stock", "Check Fruit Stock", "Run the configured fruit-stock handler.", "refresh-cw")

-- TELEPORT
addSection(Teleport, "Locations")

local selectedLocation = "Starter Island"
Teleport:Dropdown({
    Title = "Location",
    Desc = "Choose a destination for the configured location handler.",
    Values = {
        "Starter Island",
        "Jungle",
        "Pirate Village",
        "Desert",
        "Middle Town",
        "Marine Fortress",
        "Skylands",
        "Colosseum",
        "Magma Village",
        "Underwater City",
        "Fountain City",
        "Kingdom of Rose",
        "Green Zone",
        "Graveyard",
        "Snow Mountain",
        "Hot and Cold",
        "Cursed Ship",
        "Ice Castle",
        "Forgotten Island",
        "Port Town",
        "Hydra Island",
        "Great Tree",
        "Floating Turtle",
        "Castle on the Sea",
        "Haunted Castle",
        "Sea of Treats",
        "Tiki Outpost",
    },
    Value = selectedLocation,
    Callback = function(value)
        selectedLocation = value
    end,
})

Teleport:Button({
    Title = "Go to location",
    Desc = "Calls the configured location handler for " .. selectedLocation .. ".",
    Icon = "map-pin",
    Callback = function()
        if not callHandler("location", selectedLocation) then
            notify("Teleport", selectedLocation .. " is selected and ready for a game-owned handler.", "map-pin")
        end
    end,
})

addToggle(Teleport, "fruit_location", "Fruit Location", "Fruit-location helper state.", "apple", false)
addToggle(Teleport, "boss_location", "Boss Location", "Boss-location helper state.", "skull", false)

-- PVP PLAYER
addSection(PvP, "Player")
addToggle(PvP, "player_esp", "Player ESP", "Player overlay state.", "eye", false)
addToggle(PvP, "auto_dodge", "Auto Dodge", "Dodge helper state.", "shield-check", false)
addToggle(PvP, "auto_combo", "Auto Combo", "Combo helper state.", "workflow", false)
addToggle(PvP, "auto_run", "Auto Run", "Danger-response helper state.", "person-standing", false)
addToggle(PvP, "damage_predictor", "Damage Predictor", "Incoming-damage display state.", "activity", false)

-- SHOP
addSection(Shop, "Fruit & Equipment")
addButton(Shop, "shop_fruits", "Fruit Dealer", "Open the configured fruit dealer action.", "apple")
addButton(Shop, "shop_fighting_styles", "Fighting Styles", "Open the configured fighting-style action.", "hand-fist")
addButton(Shop, "shop_swords", "Swords", "Open the configured sword action.", "sword")
addButton(Shop, "shop_guns", "Guns", "Open the configured gun action.", "crosshair")
addButton(Shop, "shop_accessories", "Accessories", "Open the configured accessory action.", "gem")

-- SETTINGS
addSection(Settings, "Utilities")
addToggle(Settings, "auto_rejoin", "Auto Rejoin", "Reconnect utility state.", "refresh-cw", false)
addToggle(Settings, "anti_afk", "Anti AFK", "Idle-prevention utility state.", "clock", false)
addToggle(Settings, "fps_booster", "FPS Booster", "Performance utility state.", "gauge", false)
addToggle(Settings, "notifications", "Notifications", "Feature notification state.", "bell", true)

addSection(Settings, "Themes")

local function addThemeButton(themeName, icon)
    Settings:Button({
        Title = themeName,
        Desc = "Switch Vanta to " .. themeName .. ".",
        Icon = icon,
        Callback = function()
            VantaUI:SetTheme(themeName)
            notify("Vanta Theme", "Theme changed to " .. themeName, icon)
        end,
    })
end

addThemeButton("Salty Special", "sparkles")
addThemeButton("Vanta AMOLED", "circle-dot")
addThemeButton("Vanta Smoked", "cloud-fog")
addThemeButton("Vanta Dark", "moon")
addThemeButton("Vanta Violet", "wand-sparkles")

Settings:Button({
    Title = "Reset feature states",
    Desc = "Clear the feature-state registry for this session.",
    Icon = "rotate-ccw",
    Callback = function()
        for key in pairs(FeatureState) do
            FeatureState[key] = false
        end
        FeatureState.notifications = true
        notify("Vanta", "Feature state registry reset.", "rotate-ccw")
    end,
})

Window:SelectTab(1)
