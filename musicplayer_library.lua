-- VantaTest named-track metadata layer.
-- Keeps the premium player intact while adding polished metadata for the user's songs.

local CACHE_BUSTER = tostring(os.time()) .. "-" .. tostring(math.random(100000, 999999))
local PREMIUM_URL = "https://raw.githubusercontent.com/MrRos3/VantaTest/main/musicplayer_premium.lua?v=" .. CACHE_BUSTER

local ok, source = pcall(function()
    return game:HttpGet(PREMIUM_URL)
end)
assert(ok and type(source) == "string" and #source > 0, "[VantaTest Music] Could not load premium player")

local loader, loadError = loadstring(source)
assert(loader, "[VantaTest Music] Premium player compile failed: " .. tostring(loadError))

local MusicPlayer = loader()
assert(type(MusicPlayer) == "table", "[VantaTest Music] Premium player returned an invalid value")

local TRACK_META = {
    ["Azeri Kavkaz"] = {
        Title = "Azeri Kavkaz",
        Artist = "Caucasus Dance",
        Album = "Azeri Kavkaz",
    },
    ["I Love You So (Arabic Version - Slowed)"] = {
        Title = "I Love You So (Arabic Version - Slowed)",
        Artist = "aessy • Tom Vaulbert",
        Album = "I Love You So (Arabic Version - Slowed)",
    },
}

local BaseUpdate = MusicPlayer._update
local BaseRenderList = MusicPlayer._renderList

function MusicPlayer:_trackMeta(track)
    if not track then
        return nil
    end
    return TRACK_META[tostring(track.Name or "")]
end

function MusicPlayer:_update()
    BaseUpdate(self)

    if not self.UI then
        return
    end

    local track = self.CurrentIndex and self.Tracks[self.CurrentIndex] or nil
    local meta = self:_trackMeta(track)
    if not meta then
        return
    end

    if self.UI.Title then
        self.UI.Title.Text = meta.Title
    end
    if self.UI.Sub then
        self.UI.Sub.Text = meta.Artist .. "  •  " .. meta.Album
    end
    if self.UI.MiniPremiumTitle then
        self.UI.MiniPremiumTitle.Text = meta.Title
    end
end

function MusicPlayer:_renderList()
    BaseRenderList(self)

    for index, row in ipairs(self.Rows or {}) do
        local track = self.Tracks and self.Tracks[index]
        local meta = self:_trackMeta(track)
        if row and row.Parent and meta then
            local labels = {}
            for _, child in ipairs(row:GetChildren()) do
                if child:IsA("TextLabel") then
                    table.insert(labels, child)
                end
            end

            table.sort(labels, function(a, b)
                return a.Position.Y.Offset < b.Position.Y.Offset
            end)

            if labels[1] then
                labels[1].Text = meta.Title
            end
            if labels[2] then
                labels[2].Text = meta.Artist
            end
        end
    end
end

return MusicPlayer
