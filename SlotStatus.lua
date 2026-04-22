-- SlotStatus v1.4.1 - Fix: visible map pins (gold circle + hammer icon) + viewed-zone matching
local addonName = ...

local SLOTS = {
    { id = 1,  category = "armor",     label = "Head"      },
    { id = 3,  category = "armor",     label = "Shoulder"  },
    { id = 5,  category = "armor",     label = "Chest"     },
    { id = 6,  category = "armor",     label = "Waist"     },
    { id = 7,  category = "armor",     label = "Legs"      },
    { id = 8,  category = "armor",     label = "Feet"      },
    { id = 9,  category = "armor",     label = "Wrist"     },
    { id = 10, category = "armor",     label = "Hands"     },
    { id = 16, category = "weapon",    label = "MainHand"  },
    { id = 17, category = "weapon",    label = "OffHand"   },
    { id = 18, category = "weapon",    label = "Ranged"    },
    { id = 2,  category = "accessory", label = "Neck"      },
    { id = 11, category = "accessory", label = "Ring1"     },
    { id = 12, category = "accessory", label = "Ring2"     },
    { id = 13, category = "accessory", label = "Trinket1"  },
    { id = 14, category = "accessory", label = "Trinket2"  },
    { id = 15, category = "accessory", label = "Back"      },
    { id = 4,  category = "utility",   label = "Shirt"     },
    { id = 19, category = "utility",   label = "Tabard"    },
}

-- Known repair vendors keyed by ZONE name (GetZoneText()).
-- Each vendor can optionally tag a subzone (GetSubZoneText()) and/or faction.
-- Lookup prefers subzone-match (exact GetSubZoneText() string) -> faction-
-- compatible -> distance-based.
--
-- Contributing: add entries freely, but please verify NPC name + coords
-- against Warcraft Wiki / Wowpedia before committing. Prefer multiple
-- vendors per major zone so the distance picker has something to work
-- with when the player isn't standing in a tagged subzone.
--
-- v1.0.0 expansion notes (Tier 1, data-only):
--   * Added Blood Elf / Draenei starter zones (Azuremyst Isle, Eversong
--     Woods, Ghostlands) and the Isle of Quel'Danas daily hub.
--   * Added a second vendor in Shattrath (Anwehu, Terrace of Light) and
--     fixed a copy-paste bug where Lolo + Haalan shared identical coords.
--   * Added Old Town coverage for Stormwind (Osric Strang) and a second
--     Area 52 vendor in Netherstorm (Dealer Jafax).
--   * Added the Arathi Basin entrance vendor (Rutherford Twing) so the
--     "Find Nearest Vendor" hint works while queueing for BGs.
local REPAIR_VENDORS = {
    -- ===== Alliance capitals =====
    ["Stormwind City"] = {
        { name = "Aimee",        subzone = "Trade District", x = 57.8, y = 70.4 },
        { name = "Osric Strang", subzone = "Old Town",       x = 74.2, y = 42.8 },
    },
    ["Ironforge"]      = { { name = "Bromiir Ormsen", subzone = "Mystic Ward",  x = 53.8, y = 53.2 } },
    ["Darnassus"]      = { { name = "Lheredor",       subzone = "Warrior's Terrace", x = 59.0, y = 24.0 } },
    ["The Exodar"]     = { { name = "Rendelle",       subzone = "Trader's Tier", x = 50.3, y = 22.0 } },

    -- ===== Horde capitals =====
    ["Orgrimmar"]      = { { name = "Borgosh Corebender", subzone = "Valley of Strength", x = 53.9, y = 61.2 } },
    ["Thunder Bluff"]  = { { name = "Kaga Mistrunner",    subzone = "Lower Rise",         x = 46.5, y = 48.6 } },
    ["Undercity"]      = { { name = "Kaern Stonebrow",    subzone = "Trade Quarter",      x = 71.7, y = 45.0 } },
    ["Silvermoon City"]= { { name = "Halthenis",          subzone = "Walk of Elders",     x = 80.0, y = 56.8 } },

    -- ===== Neutral capitals =====
    -- Shattrath has two confirmed general-purpose repair vendors in
    -- different districts. The old table listed Lolo + Haalan at the
    -- same coords (63.3, 31.9) which was almost certainly a copy-paste
    -- bug, so Haalan was replaced with Anwehu on the Terrace of Light.
    ["Shattrath City"] = {
        { name = "Anwehu",           subzone = "Terrace of Light", x = 48.1, y = 42.9 },
        { name = "Lolo the Lookout", subzone = "Lower City",       x = 63.3, y = 31.9 },
    },

    -- ===== Blood Elf / Draenei starter zones (TBC) =====
    ["Azuremyst Isle"] = {
        { name = "Nabek", subzone = "Azure Watch", x = 49.6, y = 53.0, faction = "Alliance" },
    },
    ["Eversong Woods"] = {
        { name = "Farsil", subzone = "Falconwing Square", x = 49.0, y = 46.0, faction = "Horde" },
    },
    ["Ghostlands"] = {
        { name = "Master Smith Helbrim", subzone = "Tranquillien", x = 46.7, y = 29.4, faction = "Horde" },
    },
    ["Isle of Quel'Danas"] = {
        { name = "Smith Hauthaa", subzone = "Sun's Reach Harbor", x = 52.0, y = 32.0 },
    },

    -- ===== Outland =====
    ["Hellfire Peninsula"] = {
        { name = "Drix Blackwrench", subzone = "Honor Hold", x = 55.1, y = 64.0, faction = "Alliance" },
        { name = "Gunny", subzone = "Thrallmar", x = 54.2, y = 63.9, faction = "Horde" },
    },
    ["Zangarmarsh"] = {
        { name = "Smult", subzone = "Telredor", x = 68.2, y = 51.0, faction = "Alliance" },
        { name = "Innkeeper Biribi", subzone = "Zabra'jin", x = 32.4, y = 49.4, faction = "Horde" },
        { name = "Vendor-Tron 1000", subzone = "Cenarion Refuge", x = 78.6, y = 63.0 },
    },
    ["Terokkar Forest"] = {
        { name = "Jellik", subzone = "Allerian Stronghold", x = 61.0, y = 53.0, faction = "Alliance" },
        { name = "Kalandrios", subzone = "Stonebreaker Hold", x = 56.4, y = 54.2, faction = "Horde" },
    },
    ["Nagrand"] = {
        { name = "Provisioner Nasela", subzone = "Garadar", x = 55.7, y = 37.8, faction = "Horde" },
        { name = "Innkeeper Biccum", subzone = "Telaar", x = 53.4, y = 66.0, faction = "Alliance" },
    },
    ["Blade's Edge Mountains"] = {
        { name = "Yatheon", subzone = "Sylvanaar", x = 36.5, y = 62.0, faction = "Alliance" },
        { name = "Magos Shadowreaver", subzone = "Thunderlord Stronghold", x = 49.5, y = 58.2, faction = "Horde" },
        { name = "Mailanil", subzone = "Evergrove", x = 60.0, y = 37.0 },
    },
    ["Netherstorm"] = {
        { name = "Gahruj",       subzone = "Area 52", x = 33.7, y = 65.9 },
        { name = "Dealer Jafax", subzone = "Area 52", x = 32.5, y = 65.5 },
    },
    ["Shadowmoon Valley"] = {
        { name = "Fizit \"Doc\" Clocktock", subzone = "Wildhammer Stronghold", x = 36.0, y = 55.0, faction = "Alliance" },
        { name = "Nakansi", subzone = "Shadowmoon Village", x = 31.0, y = 28.0, faction = "Horde" },
    },

    -- ===== Vanilla zones (keyed by zone, tagged with subzone) =====
    ["Elwynn Forest"]        = { { name = "Smith Argus", subzone = "Goldshire", x = 42.6, y = 65.6 } },
    ["Westfall"]             = { { name = "Salma Saldean", subzone = "Saldean's Farm", x = 56.0, y = 31.0 },
                                 { name = "Farmer Furlbrow", x = 31.0, y = 58.0 } },
    ["Redridge Mountains"]   = { { name = "Wallace the Blind", subzone = "Lakeshire", x = 26.5, y = 54.0 } },
    ["Duskwood"]             = { { name = "Alexander Calder", subzone = "Darkshire", x = 74.3, y = 48.0 } },
    ["Stranglethorn Vale"]   = {
        { name = "Deeg", subzone = "Booty Bay", x = 27.5, y = 77.0 },
        { name = "Corporal Bluth", subzone = "Rebel Camp", x = 31.5, y = 35.5, faction = "Alliance" },
        { name = "Vharr", subzone = "Grom'gol Base Camp", x = 31.7, y = 26.5, faction = "Horde" },
    },
    ["Dun Morogh"]           = { { name = "Zarrin", subzone = "Kharanos", x = 48.0, y = 51.8 } },
    ["Loch Modan"]           = { { name = "Thamner Pol", subzone = "Thelsamar", x = 33.0, y = 47.0 } },
    ["Wetlands"]             = { { name = "Mrs. Gibbs", subzone = "Menethil Harbor", x = 10.0, y = 58.0 } },
    ["Arathi Highlands"]     = { { name = "Gurda Wildmane",   subzone = "Refuge Pointe",          x = 45.0, y = 46.0, faction = "Alliance" },
                                 { name = "Kuray'bin",        subzone = "Hammerfall",             x = 72.0, y = 33.0, faction = "Horde" },
                                 { name = "Rutherford Twing", subzone = "Arathi Basin Entrance",  x = 73.0, y = 29.0 } },
    ["Hillsbrad Foothills"]  = { { name = "Loremaster Dibbs", subzone = "Southshore", x = 55.0, y = 60.0, faction = "Alliance" },
                                 { name = "Magistrate Henren Burdent", subzone = "Tarren Mill", x = 60.0, y = 19.0, faction = "Horde" } },
    ["Alterac Mountains"]    = { { name = "Hannah Bladeleaf", subzone = "Ravenholdt Manor", x = 79.0, y = 20.0 } },
    ["The Hinterlands"]      = { { name = "Innkeeper Thulbek", subzone = "Aerie Peak", x = 12.0, y = 46.0, faction = "Alliance" },
                                 { name = "Innkeeper Gryshka", subzone = "Revantusk Village", x = 79.0, y = 81.0, faction = "Horde" } },
    ["Western Plaguelands"]  = { { name = "Argent Officer Garush", subzone = "Chillwind Camp", x = 42.0, y = 85.0 } },
    ["Eastern Plaguelands"]  = { { name = "Argent Quartermaster Hasana", subzone = "Light's Hope Chapel", x = 82.0, y = 60.0 } },

    ["Durotar"]              = { { name = "Kzak Deepforge", subzone = "Razor Hill", x = 52.6, y = 43.8, faction = "Horde" } },
    ["The Barrens"]          = { { name = "Kixxle", subzone = "Crossroads", x = 51.0, y = 30.0 },
                                 { name = "Jannos Lighthoof", subzone = "Ratchet", x = 62.9, y = 37.4 } },
    ["Mulgore"]              = { { name = "Willik", subzone = "Bloodhoof Village", x = 47.0, y = 59.0 } },
    ["Stonetalon Mountains"] = { { name = "Kaya Flathoof", subzone = "Sun Rock Retreat", x = 51.0, y = 63.0, faction = "Horde" },
                                 { name = "Innkeeper Jayka", subzone = "Stonetalon Peak", x = 38.0, y = 7.0, faction = "Alliance" } },
    ["Ashenvale"]            = { { name = "Innkeeper Kaylisk", subzone = "Astranaar", x = 37.0, y = 51.0, faction = "Alliance" },
                                 { name = "Innkeeper Duras", subzone = "Splintertree Post", x = 73.0, y = 60.0, faction = "Horde" } },
    ["Thousand Needles"]     = { { name = "Karolek", subzone = "Freewind Post", x = 45.0, y = 55.0, faction = "Horde" },
                                 { name = "Grub", subzone = "Mirage Raceway", x = 77.0, y = 77.0 } },
    ["Dustwallow Marsh"]     = { { name = "Innkeeper Janene", subzone = "Theramore Isle", x = 66.0, y = 48.0, faction = "Alliance" },
                                 { name = "Innkeeper Lhakadd", subzone = "Brackenwall Village", x = 36.0, y = 31.0, faction = "Horde" } },
    ["Desolace"]             = { { name = "Innkeeper Lylandris", subzone = "Nijel's Point", x = 66.0, y = 8.0, faction = "Alliance" },
                                 { name = "Innkeeper Lhakadd", subzone = "Shadowprey Village", x = 24.0, y = 69.0, faction = "Horde" } },
    ["Feralas"]              = { { name = "Innkeeper Shaussiy", subzone = "Feathermoon Stronghold", x = 30.0, y = 43.0, faction = "Alliance" },
                                 { name = "Innkeeper Vizzie", subzone = "Camp Mojache", x = 75.0, y = 45.0, faction = "Horde" } },
    ["Tanaris"]              = { { name = "Kyros", subzone = "Gadgetzan", x = 50.6, y = 27.4 } },
    ["Un'Goro Crater"]       = { { name = "A-Me 01", subzone = "Marshal's Refuge", x = 56.0, y = 63.0 } },
    ["Silithus"]             = { { name = "Merchant Al-Tabim", subzone = "Cenarion Hold", x = 50.0, y = 35.0 } },
    ["Winterspring"]         = { { name = "Bryan Landers", subzone = "Everlook", x = 61.0, y = 37.6 } },
    ["Azshara"]              = { { name = "Loolruhi", subzone = "Valormok", x = 32.0, y = 47.0, faction = "Horde" } },

    ["Teldrassil"]           = { { name = "Deeana Darkspell", subzone = "Dolanaar", x = 55.0, y = 52.0 } },
    ["Darkshore"]            = { { name = "Innkeeper Saelienne", subzone = "Auberdine", x = 37.0, y = 42.0 } },
    ["Tirisfal Glades"]      = { { name = "Innkeeper Renee", subzone = "Brill", x = 60.0, y = 53.0 } },
    ["Silverpine Forest"]    = { { name = "Innkeeper Bates", subzone = "The Sepulcher", x = 45.0, y = 40.0 } },

    ["Blasted Lands"]        = { { name = "Innkeeper Wiley", subzone = "Nethergarde Keep", x = 66.0, y = 20.0, faction = "Alliance" } },
    ["Burning Steppes"]      = { { name = "Mayda Thane", subzone = "Morgan's Vigil", x = 85.0, y = 68.0, faction = "Alliance" },
                                 { name = "Innkeeper Heather", subzone = "Flame Crest", x = 65.0, y = 25.0, faction = "Horde" } },
    ["Searing Gorge"]        = { { name = "Kalaran Windblade", subzone = "Thorium Point", x = 34.0, y = 29.0 } },
}

-- v1.0.0 Tier 2: auto-discovered vendor merge.
-- Returns the list of vendors to consider for a zone, combining the
-- hardcoded `REPAIR_VENDORS` above with anything the player has learned
-- organically from `MERCHANT_SHOW` (see `recordVendorVisit`). Dedup is
-- by NPC name: if a name is present in both sources, the discovered
-- entry wins because its coords were captured in the player's own
-- client rather than copied out of a wiki.
--
-- The returned list is shape-compatible with the existing hardcoded
-- table (fields: name, subzone, x, y, faction), so `getNearestRepairVendor`
-- and `updateMapPins` can consume it without any additional changes to
-- their scoring / rendering logic.
local function getVendorsForZone(zone)
    if not zone or zone == "" then return nil end
    local hardcoded = REPAIR_VENDORS[zone]
    local discovered = SlotStatusDB and SlotStatusDB.discoveredVendors
                       and SlotStatusDB.discoveredVendors[zone]

    if (not discovered) or (not next(discovered)) then
        return hardcoded
    end

    local seen = {}
    local out  = {}

    for name, v in pairs(discovered) do
        seen[name] = true
        table.insert(out, {
            name    = name,
            subzone = v.subzone,
            x       = v.x,
            y       = v.y,
            faction = v.faction,
        })
    end
    if hardcoded then
        for _, v in ipairs(hardcoded) do
            if not seen[v.name] then
                table.insert(out, v)
            end
        end
    end
    return out
end

-- ====================== EASY ADJUSTMENT SECTION (defaults) ======================
-- These are DEFAULTS only. The live values come from SlotStatusDB so users
-- can tweak them from the Advanced options panel without editing Lua.
local SIDE_BAR_WIDTH       = 2.2
local SIDE_BAR_HEIGHT_PAD  = 4
local WEAPON_BAR_WIDTH_PAD = 2
local WEAPON_BAR_HEIGHT    = 2.2
local WEAPON_BAR_Y_OFFSET  = 0
local LEFT_COLUMN_OFFSET   = 19.3
local RIGHT_COLUMN_OFFSET  = 20
-- ==============================================================================

-- BRIGHT FULL-COLOR DEFAULTS (overridable via SlotStatusDB.color*)
local GREEN_R, GREEN_G, GREEN_B = 0.00, 0.95, 0.35
local YELLOW_R, YELLOW_G, YELLOW_B = 1.00, 1.00, 0.00
local RED_R,    RED_G,    RED_B    = 0.85, 0.05, 0.05
local GOLD_R,  GOLD_G,  GOLD_B  = 1.10, 1.10, 0.50
local WHITE_R,  WHITE_G,  WHITE_B  = 1.00, 1.00, 1.00

-- NO WHITE BACKGROUND TRACK
local BG_R, BG_G, BG_B, BG_A = 0.00, 0.00, 0.00, 0.00

local STYLE = {
    armor     = { alpha = 0.72 },
    weapon    = { alpha = 0.82 },
    accessory = { alpha = 0.62 },
    utility   = { alpha = 0.62 },
}

local slotFrames = {}
local bars = {}

-- Small helpers: read configured colors/thresholds from the DB (with
-- safe fallbacks so the addon still works before initDefaults runs).
local function cfgColor(key, fallbackR, fallbackG, fallbackB)
    local c = SlotStatusDB and SlotStatusDB[key]
    if type(c) == "table" and #c == 3 then return c[1], c[2], c[3] end
    return fallbackR, fallbackG, fallbackB
end

local function cfgNum(key, fallback)
    local v = SlotStatusDB and SlotStatusDB[key]
    if type(v) == "number" then return v end
    return fallback
end

local function pct(cur, max)
    if not max or max <= 0 then return nil end
    return math.floor((cur / max) * 100 + 0.5)
end

local function setDurabilityColor(bar, p)
    if not p then return end
    local g2y = cfgNum("threshG2Y", 75)
    local y2r = cfgNum("threshY2R", 40)
    if p >= g2y then
        bar:SetStatusBarColor(cfgColor("colorHigh", GREEN_R,  GREEN_G,  GREEN_B))
    elseif p >= y2r then
        bar:SetStatusBarColor(cfgColor("colorMid",  YELLOW_R, YELLOW_G, YELLOW_B))
    else
        bar:SetStatusBarColor(cfgColor("colorLow",  RED_R,    RED_G,    RED_B))
    end
end

local function discoverSlotFrames()
    wipe(slotFrames)
    for name, obj in pairs(_G) do
        if type(name) == "string" and name:match("^Character.*Slot$") then
            if type(obj) == "table" and obj.GetID and obj.GetName then
                local id = obj:GetID()
                if type(id) == "number" and id > 0 then
                    for _, s in ipairs(SLOTS) do
                        if s.id == id then
                            slotFrames[id] = obj
                            break
                        end
                    end
                end
            end
        end
    end
end

local function placeVerticalBar(bar, slotFrame)
    bar:ClearAllPoints()
    local leftOff  = cfgNum("barLeftOffset",  LEFT_COLUMN_OFFSET)
    local rightOff = cfgNum("barRightOffset", RIGHT_COLUMN_OFFSET)
    local centerRef = (PaperDollFrame and PaperDollFrame:GetCenter())
                   or (CharacterFrame and CharacterFrame:GetCenter())
    if slotFrame:GetCenter() < centerRef then
        bar:SetPoint("CENTER", slotFrame, "CENTER", -leftOff, 0)
    else
        bar:SetPoint("CENTER", slotFrame, "CENTER",  rightOff, 0)
    end
end

local function createBars()
    wipe(bars)
    for _, s in ipairs(SLOTS) do
        local slotFrame = slotFrames[s.id]
        if slotFrame then
            local st = STYLE[s.category] or STYLE.armor

            local bar = CreateFrame("StatusBar", nil, slotFrame)
            bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
            bar:SetMinMaxValues(0, 100)
            bar:SetValue(100)
            bar.baseAlpha = st.alpha
            bar:SetAlpha(st.alpha * cfgNum("barAlphaMult", 1.0))
            bar:SetFrameLevel((slotFrame:GetFrameLevel() or 1) + 10)

            bar.bg = bar:CreateTexture(nil, "BACKGROUND")
            bar.bg:SetAllPoints(true)
            bar.bg:SetTexture("Interface\\Buttons\\WHITE8x8")
            bar.bg:SetVertexColor(BG_R, BG_G, BG_B, BG_A)

            bar.slotInfo = s
            bar.slotFrame = slotFrame

            local thickness = cfgNum("barThickness", SIDE_BAR_WIDTH)
            if s.category == "weapon" then
                bar:SetOrientation("HORIZONTAL")
                bar:SetWidth( (slotFrame:GetWidth() or 37) - WEAPON_BAR_WIDTH_PAD )
                bar:SetHeight(WEAPON_BAR_HEIGHT)
                bar:SetPoint("BOTTOM", slotFrame, "BOTTOM", 0, WEAPON_BAR_Y_OFFSET)
            else
                bar:SetOrientation("VERTICAL")
                bar:SetWidth(thickness)
                bar:SetHeight( (slotFrame:GetHeight() or 37) - SIDE_BAR_HEIGHT_PAD )
                placeVerticalBar(bar, slotFrame)
            end

            bars[s.id] = bar
            bar:Hide()
        end
    end
end

-- Live-apply changes to existing bars when the user tweaks sliders in the
-- Advanced options panel. No re-creation needed.
local function applyBarAppearance()
    local alphaMult = cfgNum("barAlphaMult", 1.0)
    local thickness = cfgNum("barThickness", SIDE_BAR_WIDTH)
    for _, bar in pairs(bars) do
        local base = bar.baseAlpha or 0.72
        bar:SetAlpha(math.max(0.05, math.min(1.0, base * alphaMult)))
        if bar.slotInfo and bar.slotInfo.category ~= "weapon" then
            bar:SetWidth(thickness)
            if bar.slotFrame then placeVerticalBar(bar, bar.slotFrame) end
        end
    end
end

local function updateBars()
    local hideAll = (SlotStatusDB and SlotStatusDB.showBars == false)
    for _, s in ipairs(SLOTS) do
        local bar = bars[s.id]
        if bar then
            local equipped = GetInventoryItemID("player", s.id) ~= nil
            if not equipped or hideAll then
                bar:Hide()
            else
                local cur, max = GetInventoryItemDurability(s.id)
                local has_durability = (cur and max and max > 0)
                local p = has_durability and pct(cur, max) or 100

                bar:SetValue(p)

                -- Armor & weapons expose a durability value -> threshold
                -- dispatcher (colorHigh / colorMid / colorLow per wear).
                --
                -- Slots without durability: accessory (ring/neck/trinket/
                -- back) and utility (shirt, tabard) keep DELIBERATE fixed
                -- category tints (gold / grey) so the bar reads at a
                -- glance as "what kind of slot is this?".
                --
                -- Slot 17 / OffHand fix: for the WEAPON category when
                -- the API reports no durability (caster off-hand "Held
                -- in Off-hand" items -- tomes, orbs, wands, etc.), we
                -- must NOT hardcode green. That was the old bug: the
                -- bar ignored SlotStatusDB.colorHigh and stayed green
                -- forever no matter what the user picked. Route it
                -- through setDurabilityColor at 100% so the user's
                -- Healthy color applies, matching the other weapons.
                -- Slot 17 (OffHand) visually groups with the accessory
                -- slots (rings 11/12, trinkets 13/14): always paint it
                -- with the accessory GOLD tint regardless of durability,
                -- so caster off-hands and shields read the same as rings
                -- and trinkets at a glance.
                if s.id == 17 then
                    bar:SetStatusBarColor(cfgColor("colorAccessory", GOLD_R, GOLD_G, GOLD_B))
                elseif has_durability then
                    setDurabilityColor(bar, p)
                else
                    if     s.category == "utility" then bar:SetStatusBarColor(cfgColor("colorUtility",   WHITE_R, WHITE_G, WHITE_B))
                    elseif s.category == "weapon"  then setDurabilityColor(bar, 100)
                    else                                bar:SetStatusBarColor(cfgColor("colorAccessory", GOLD_R,  GOLD_G,  GOLD_B))
                    end
                end

                bar:Show()
            end
        end
    end
end

local QUALITY_MULT = {
    [0] = 0.00,  -- Poor
    [1] = 1.00,  -- Common
    [2] = 1.15,  -- Uncommon
    [3] = 1.35,  -- Rare
    [4] = 1.60,  -- Epic
    [5] = 2.00,  -- Legendary
    [6] = 2.50,  -- Artifact
    [7] = 2.50,  -- Heirloom
}

-- Approximation of TBC repair cost. Real formula scales roughly with ilvl^2.
-- Tuned against known values: lvl 40 rare weapon ~50s half-repair, lvl 70 epic ~2g half-repair.
local function estimateSlotRepairCost(slot)
    local cur, max = GetInventoryItemDurability(slot)
    if not cur or not max or max <= 0 then return nil end
    local lost = max - cur
    if lost <= 0 then return 0 end

    local link = GetInventoryItemLink("player", slot)
    if not link then return nil end

    local _, _, quality, ilvl = GetItemInfo(link)
    quality = quality or 1
    ilvl = ilvl or 1
    if ilvl < 1 then ilvl = 1 end

    local qm = QUALITY_MULT[quality] or 1.0
    local cost = lost * (ilvl * ilvl) / 40 * qm
    return math.floor(cost + 0.5)
end

local function formatMoney(copper)
    if not copper or copper <= 0 then return nil end
    local gold   = math.floor(copper / 10000)
    local silver = math.floor((copper % 10000) / 100)
    local c      = copper % 100

    local text = ""
    if gold   > 0 then text = text .. gold   .. "|cffffd700g|r " end
    if silver > 0 then text = text .. silver .. "|cffc7c7cfs|r " end
    if c      > 0 or text == "" then text = text .. c .. "|cffeda55fc|r" end
    return text
end

local function getNearestRepairVendor()
    local zone = GetZoneText()
    if not zone or zone == "" then return nil end

    -- v1.0.0: use the merged hardcoded + discovered vendor list so the
    -- "Find Nearest Vendor" hint picks up any repair NPC the player has
    -- personally visited, even if we don't ship them in REPAIR_VENDORS.
    local vendors = getVendorsForZone(zone)
    if not vendors then return nil end

    local playerFaction = UnitFactionGroup("player")
    local subzone = GetSubZoneText and GetSubZoneText() or ""

    local faction_ok = {}
    for _, v in ipairs(vendors) do
        if not v.faction or v.faction == playerFaction then
            table.insert(faction_ok, v)
        end
    end
    if #faction_ok == 0 then faction_ok = vendors end

    if subzone and subzone ~= "" then
        for _, v in ipairs(faction_ok) do
            if v.subzone and v.subzone == subzone then
                return { name = v.name, zone = zone, subzone = v.subzone, x = v.x, y = v.y, here = true }
            end
        end
    end

    if #faction_ok == 1 then
        local v = faction_ok[1]
        return { name = v.name, zone = zone, subzone = v.subzone, x = v.x, y = v.y }
    end

    local px, py
    if GetPlayerMapPosition then
        px, py = GetPlayerMapPosition("player")
    end
    if px and px ~= 0 then
        px, py = px * 100, py * 100
        local best, bestDist
        for _, v in ipairs(faction_ok) do
            local dx, dy = v.x - px, v.y - py
            local d = dx*dx + dy*dy
            if not bestDist or d < bestDist then
                bestDist = d
                best = v
            end
        end
        if best then
            return { name = best.name, zone = zone, subzone = best.subzone, x = best.x, y = best.y }
        end
    end

    local v = faction_ok[1]
    return { name = v.name, zone = zone, subzone = v.subzone, x = v.x, y = v.y }
end

local function debugPrint(msg)
    if SlotStatusDB and SlotStatusDB.debug then
        print("|cffffd200SlotStatus|r|cff888888 debug:|r " .. msg)
    end
end

local function enhanceTooltip(tooltip, unit, slot)
    if not slot or not unit or not tooltip then return end

    if tooltip.slotStatusLastSlot == slot then
        debugPrint("skip duplicate for slot " .. slot)
        return
    end
    tooltip.slotStatusLastSlot = slot

    local itemID = GetInventoryItemID(unit, slot)
    if not itemID then
        debugPrint("no item in slot " .. slot)
        return
    end

    debugPrint("hook fired (slot=" .. slot .. " itemID=" .. tostring(itemID) .. ")")

    local _, _, _, ilvl = GetItemInfo(itemID)
    if ilvl and ilvl > 0 then
        tooltip:AddLine("|cffffffffItem Level: |r" .. ilvl, 1,1,1)
    end

    local repairCost = GetRepairAllCost()
    if repairCost and repairCost > 0 then
        local moneyText = formatMoney(repairCost)
        if moneyText then
            tooltip:AddLine("|cffffffffTotal Repair Cost: |r" .. moneyText)
        end
    end

    local slotCost = estimateSlotRepairCost(slot)
    if slotCost and slotCost > 0 then
        local moneyText = formatMoney(slotCost)
        if moneyText then
            tooltip:AddLine("|cffffffffSlot Repair: |r" .. moneyText .. " |cff888888(estimated)|r")
        end
    end

    local total = 0
    for _, s in ipairs(SLOTS) do
        local c = estimateSlotRepairCost(s.id)
        if c and c > 0 then total = total + c end
    end
    if total > 0 then
        tooltip:AddLine("|cffffffffTotal (all slots): |r" .. (formatMoney(total) or "0") .. " |cff888888(estimated)|r")
    end

    local vendor = getNearestRepairVendor()
    if vendor then
        local label = vendor.here and "|cff00ff00Repair here:|r" or "|cffffffffNearest Repair:|r"
        local place = vendor.subzone and (vendor.subzone .. ", " .. vendor.zone) or vendor.zone
        tooltip:AddLine(string.format(
            "%s |cffffd200%s|r |cffaaaaaa\226\128\148|r %s |cff888888(%.1f, %.1f)|r",
            label, vendor.name, place, vendor.x, vendor.y
        ))
    end

    tooltip:Show()
end

-- ====================== WORLD MAP PINS ======================
local mapPins = {}

local function getViewedZoneName()
    -- In TBC Classic, GetMapInfo() returns (mapFileName, width, height).
    -- The mapFileName is like "Tanaris", "StormwindCity", "HellfirePeninsula" etc.
    -- We normalize both sides to compare against REPAIR_VENDORS keys.
    if GetMapInfo then
        local mapFile = GetMapInfo()
        if mapFile then
            -- Try exact match first
            if REPAIR_VENDORS[mapFile] then return mapFile end
            -- Try matching by stripping spaces/apostrophes
            for zoneName in pairs(REPAIR_VENDORS) do
                local normalized = zoneName:gsub("[%s'%-]", "")
                if normalized == mapFile then return zoneName end
            end
        end
    end
    -- Fallback: use player's current zone if nothing else matched
    return GetZoneText and GetZoneText() or ""
end

local function getPinParent()
    -- In TBC Classic 2.5.5 the world map uses a ScrollContainer with a Child
    -- that represents the full-resolution map. Pins parented to it will
    -- clip and zoom correctly. Fall back to the classic detail frame.
    if WorldMapFrame and WorldMapFrame.ScrollContainer
       and WorldMapFrame.ScrollContainer.Child then
        return WorldMapFrame.ScrollContainer.Child
    end
    return WorldMapDetailFrame or WorldMapButton or WorldMapFrame
end

local function createMapPin()
    local parent = getPinParent()
    if not parent then return nil end
    local pin = CreateFrame("Button", nil, parent)
    -- v1.0.0: use the in-game minimap-tracking anvil. The texture is a
    -- transparent BLP shipped with every WoW client, so there's no
    -- background rectangle, no icon border, no bundled asset -- just
    -- the anvil silhouette on top of the world map. Slightly larger
    -- than the old 12 px chip because the anvil art fills less of its
    -- texel area than the previous filled circle + hammer icon did.
    pin:SetSize(18, 18)
    pin:SetFrameStrata("FULLSCREEN_DIALOG")
    pin:SetFrameLevel((parent:GetFrameLevel() or 10) + 50)

    -- Primary anvil art. `Interface\Minimap\Tracking\Repair` is the
    -- built-in repair-vendor tracking icon (the anvil used by Blizzard's
    -- own minimap POI system). It has an alpha channel, so it renders
    -- directly over the map parchment with no background.
    local tex = pin:CreateTexture(nil, "OVERLAY")
    tex:SetAllPoints()
    local ok = tex:SetTexture("Interface\\Minimap\\Tracking\\Repair")
    -- Defensive fallback for any exotic client that's missing the
    -- tracking atlas -- drop back to the blacksmithing anvil icon,
    -- trimmed to remove its square icon border so we still render as
    -- "just the anvil" rather than a bordered chip.
    if ok == false or tex:GetTexture() == nil then
        tex:SetTexture("Interface\\ICONS\\Trade_BlackSmithing")
        tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    end
    pin.tex = tex

    pin:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("|cff00ff00Repair Vendor|r", 1, 1, 1)
        GameTooltip:AddLine(self.vendorName or "?", 1, 0.82, 0)
        if self.subzone then
            GameTooltip:AddLine(self.subzone, 0.7, 0.7, 0.7)
        end
        if self.faction then
            GameTooltip:AddLine("Faction: " .. self.faction, 0.8, 0.8, 0.8)
        end
        GameTooltip:AddLine(string.format("%.1f, %.1f", self.vx or 0, self.vy or 0), 0.6, 0.6, 0.6)
        GameTooltip:Show()
    end)
    pin:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return pin
end

local function updateMapPins()
    for _, pin in ipairs(mapPins) do pin:Hide() end
    if not WorldMapFrame or not WorldMapFrame:IsShown() then return end
    if not SlotStatusDB or SlotStatusDB.mapPins == false then return end

    local zone = getViewedZoneName()
    -- v1.0.0: merged hardcoded + discovered vendors, same source as the
    -- "Find Nearest Vendor" lookup, so discovered NPCs also get pins.
    local vendors = getVendorsForZone(zone)
    if not vendors then
        debugPrint("map: no vendors for viewed map '" .. tostring(zone) .. "'")
        return
    end

    local detail = getPinParent()
    if not detail then return end
    local w, h = detail:GetSize()
    if not w or w <= 1 then
        debugPrint(string.format("map: pin parent has no size yet (%sx%s)",
            tostring(w), tostring(h)))
        return
    end

    local playerFaction = UnitFactionGroup("player")
    local i = 0
    for _, v in ipairs(vendors) do
        if not v.faction or v.faction == playerFaction then
            i = i + 1
            if not mapPins[i] then
                mapPins[i] = createMapPin()
            end
            local pin = mapPins[i]
            if pin then
                pin.vendorName = v.name
                pin.subzone = v.subzone
                pin.faction = v.faction
                pin.vx = v.x
                pin.vy = v.y
                pin:ClearAllPoints()
                pin:SetParent(detail)
                pin:SetFrameStrata("FULLSCREEN_DIALOG")
                pin:SetFrameLevel((detail:GetFrameLevel() or 10) + 50)
                pin:SetPoint("CENTER", detail, "TOPLEFT", (v.x / 100) * w, -(v.y / 100) * h)
                pin:Show()
                debugPrint(string.format("map: placed pin '%s' at (%.1f,%.1f) on %dx%d",
                    v.name, v.x, v.y, w, h))
            end
        end
    end
end

local function registerMapPins()
    if not WorldMapFrame then return end
    WorldMapFrame:HookScript("OnShow", updateMapPins)
    WorldMapFrame:HookScript("OnSizeChanged", updateMapPins)

    -- Event registration, version-defensively.
    --
    -- WORLD_MAP_UPDATE was removed from the modern world-map system that
    -- the Anniversary client runs on, but still exists on vanilla Classic
    -- Era 1.x and some TBC builds. A hard RegisterEvent on a non-existent
    -- event throws and takes the whole pin system with it. We try a
    -- prioritized list of map/zone events and accept whichever the current
    -- build recognises. If ALL of them are rejected, the OnShow and
    -- OnSizeChanged hooks above still refresh pins whenever the map is
    -- actually visible -- so pins never fully stop working.
    local mapWatcher = CreateFrame("Frame")
    local candidates = {
        "WORLD_MAP_UPDATE",       -- Classic Era / older TBC
        "ZONE_CHANGED_NEW_AREA",  -- ubiquitous, fires on zone entry
        "ZONE_CHANGED",           -- sub-zone transitions
        "ZONE_CHANGED_INDOORS",   -- indoor transitions
        "PLAYER_ENTERING_WORLD",  -- login / reload / teleport
    }
    local registered = 0
    for _, ev in ipairs(candidates) do
        -- IsEventValid only exists on modern clients; when present it lets
        -- us skip the pcall cost and avoid the benign error line some
        -- builds still emit from inside RegisterEvent even when wrapped.
        local valid = true
        if C_EventUtils and C_EventUtils.IsEventValid then
            valid = C_EventUtils.IsEventValid(ev)
        end
        if valid then
            local ok = pcall(mapWatcher.RegisterEvent, mapWatcher, ev)
            if ok then registered = registered + 1 end
        end
    end
    mapWatcher:SetScript("OnEvent", updateMapPins)
    debugPrint(string.format("map: pin watcher registered %d event(s)", registered))
end

-- ====================== MERCHANT AUTOMATION ======================
-- v1.0.0 Tier 2: organic vendor discovery.
--
-- When the player opens a merchant frame, if that merchant can repair
-- (`CanMerchantRepair`) and we have enough context to pin them on the
-- world map, stash them in `SlotStatusDB.discoveredVendors` keyed by
-- zone and name. The merged lookup in `getVendorsForZone` will then
-- expose them to the "Find Nearest Vendor" hint and the world-map pin
-- system on subsequent visits.
--
-- Design notes:
--  * Keyed by NPC name so re-visits dedup naturally. Coords are
--    re-captured on later visits if they've drifted more than 0.5% of
--    the zone -- harmless for stationary merchants, self-correcting
--    for the occasional roving one.
--  * Deliberately does NOT store a faction tag. We don't know whether
--    the NPC is Alliance-only, Horde-only, or neutral without seeing
--    them from the other faction, and an over-zealous tag would hide
--    legitimate discoveries from the other half of the player base
--    when users share saved variables.
--  * Silent on re-visits. First-sighting prints one short confirmation
--    so the user knows the feature is working.
--  * Instance merchants (`GetPlayerMapPosition` returns 0,0 indoors in
--    most Classic clients) are skipped -- the pin would be useless
--    without a map position anyway.
local function recordVendorVisit()
    if not SlotStatusDB then return end
    if SlotStatusDB.discoverVendors == false then return end
    if not (CanMerchantRepair and CanMerchantRepair()) then return end

    local npcName
    if UnitName then
        npcName = UnitName("npc")
        if not npcName or npcName == "" then
            npcName = UnitName("target")
        end
    end
    if not npcName or npcName == "" then return end

    local zone = GetZoneText and GetZoneText() or ""
    if zone == "" then return end

    local subzone = GetSubZoneText and GetSubZoneText() or ""
    if subzone == "" then subzone = nil end

    local px, py
    if GetPlayerMapPosition then px, py = GetPlayerMapPosition("player") end
    if not px or not py or (px == 0 and py == 0) then return end
    px, py = px * 100, py * 100

    SlotStatusDB.discoveredVendors = SlotStatusDB.discoveredVendors or {}
    local bucket = SlotStatusDB.discoveredVendors[zone]
    if not bucket then
        bucket = {}
        SlotStatusDB.discoveredVendors[zone] = bucket
    end

    local existing = bucket[npcName]
    if existing then
        -- Soft-refresh drifted coords without a chat message.
        if math.abs((existing.x or 0) - px) > 0.5
        or math.abs((existing.y or 0) - py) > 0.5 then
            existing.x = px
            existing.y = py
            existing.subzone = subzone or existing.subzone
            existing.updated = time and time() or nil
        end
        return
    end

    bucket[npcName] = {
        subzone    = subzone,
        x          = px,
        y          = py,
        discovered = time and time() or nil,
    }

    print(string.format(
        "|cffffd200SlotStatus|r learned repair vendor \"|cffffffff%s|r\" in %s%s.",
        npcName, zone,
        subzone and (" (|cffaaaaaa" .. subzone .. "|r)") or ""))

    -- Refresh pins in case the world map is open on this zone right now.
    if updateMapPins then pcall(updateMapPins) end
end

-- ==========================================================================
-- Stats accounting (v1.0.0)
-- --------------------------------------------------------------------------
-- `SlotStatusDB.stats` is SavedVariablesPerCharacter, so every counter in
-- it is a LIFETIME total. The Stats tab renders two columns (Session |
-- Lifetime); to produce the "Session" column we snapshot the lifetime
-- values at PLAYER_LOGIN into `sessionStatsBase` and any later read
-- returns the delta. `sessionStatsBase` is intentionally NOT persisted.
-- --------------------------------------------------------------------------
local sessionStatsBase = {}

local function snapshotSessionStats()
    local s = (SlotStatusDB and SlotStatusDB.stats) or {}
    sessionStatsBase.visits         = s.visits         or 0
    sessionStatsBase.repair_count   = s.repair_count   or 0
    sessionStatsBase.grays_sold     = s.grays_sold     or 0
    sessionStatsBase.gold_repaired  = s.gold_repaired  or 0
    sessionStatsBase.gold_from_gray = s.gold_from_gray or 0
end

local function sessionValue(key)
    local lifetime = (SlotStatusDB and SlotStatusDB.stats and SlotStatusDB.stats[key]) or 0
    return lifetime - (sessionStatsBase[key] or 0)
end

-- Central repair-event accounting. Both auto-repair (handleMerchantVisit)
-- and the "Repair All" button in the Gear Overview route through here so
-- the three counters -- total spent / event count / biggest single repair
-- -- stay in lock-step regardless of which code path triggered the repair.
local function recordRepairEvent(cost)
    if not SlotStatusDB then return end
    if not cost or cost <= 0 then return end
    SlotStatusDB.stats = SlotStatusDB.stats or {}
    local stats = SlotStatusDB.stats
    stats.gold_repaired = (stats.gold_repaired or 0) + cost
    stats.repair_count  = (stats.repair_count  or 0) + 1
    if cost > (stats.biggest_repair or 0) then
        stats.biggest_repair = cost
    end
end

local function handleMerchantVisit()
    if not SlotStatusDB then return end
    SlotStatusDB.stats = SlotStatusDB.stats or {}
    local stats = SlotStatusDB.stats
    stats.visits = (stats.visits or 0) + 1

    -- v1.0.0: attempt to learn this merchant before running auto-sell
    -- or auto-repair. Wrapped by the function itself, not here, so any
    -- failure inside is invisible to the rest of this function.
    recordVendorVisit()

    if SlotStatusDB.autoSell then
        local soldTotal, soldCount = 0, 0
        for bag = 0, 4 do
            local slots = GetContainerNumSlots and GetContainerNumSlots(bag) or 0
            for slot = 1, slots do
                local link = GetContainerItemLink and GetContainerItemLink(bag, slot)
                if link then
                    local _, _, quality, _, _, _, _, _, _, _, sellPrice = GetItemInfo(link)
                    if quality == 0 and sellPrice and sellPrice > 0 then
                        local _, count = GetContainerItemInfo(bag, slot)
                        count = count or 1
                        UseContainerItem(bag, slot)
                        soldTotal = soldTotal + sellPrice * count
                        soldCount = soldCount + 1
                    end
                end
            end
        end
        if soldCount > 0 then
            stats.gold_from_gray = (stats.gold_from_gray or 0) + soldTotal
            stats.grays_sold = (stats.grays_sold or 0) + soldCount
            print(string.format("|cffffd200SlotStatus|r auto-sold %d junk item%s for %s",
                soldCount, soldCount == 1 and "" or "s", formatMoney(soldTotal) or "0"))
        end
    end

    if SlotStatusDB.autoRepair and CanMerchantRepair and CanMerchantRepair() then
        local cost, canRepair = GetRepairAllCost()
        if canRepair and cost and cost > 0 then
            local useGuild = false
            if SlotStatusDB.autoRepairGuild and IsInGuild and IsInGuild()
                and CanGuildBankRepair and CanGuildBankRepair()
                and GetGuildBankWithdrawMoney and GetGuildBankWithdrawMoney() >= cost then
                useGuild = true
            end
            RepairAllItems(useGuild)
            recordRepairEvent(cost)
            print(string.format("|cffffd200SlotStatus|r auto-repaired all gear for %s%s",
                formatMoney(cost) or "0",
                useGuild and " |cff00ff88(guild funds)|r" or ""))
        end
    end
end

-- ====================== LOW-DURABILITY WARNINGS ======================
local lastWarned = {}

-- Briefly pulse a bar's alpha so a slot crossing the warning threshold
-- is visible on the character frame (if it happens to be open).
local function flashBar(bar, duration)
    if not bar or not bar.SetAlpha then return end
    duration = duration or 0.9
    bar.flashStart = GetTime()
    bar.flashEnd   = GetTime() + duration
    bar.flashBase  = bar:GetAlpha() or 1.0
    bar:SetScript("OnUpdate", function(self)
        local t = GetTime()
        if t >= (self.flashEnd or 0) then
            self:SetAlpha(self.flashBase or 1.0)
            self:SetScript("OnUpdate", nil)
            return
        end
        -- 3 Hz pulse between 30% and 100% of original alpha
        local phase = (t - (self.flashStart or t)) * 6
        local pulse = 0.5 + 0.5 * math.sin(phase * math.pi)
        self:SetAlpha(math.max(0.05, (self.flashBase or 1) * (0.30 + 0.70 * pulse)))
    end)
end

-- v0.9.25: small on-screen error-style notification.
-- Pipes a short warning string into UIErrorsFrame — the same top-centre
-- small-text area Blizzard uses for "Not enough gold", "Out of range"
-- etc. It auto-fades, is non-intrusive, and respects the user's UI
-- scale (so it reads as "small on screen" without any custom frame).
-- Wrapped in pcall because UIErrorsFrame has historically been a
-- globally-available frame in every WoW client since vanilla but we
-- still don't want a missing global to break the warning path.
-- Text is plain (no |cff codes): UIErrorsFrame:AddMessage takes its
-- colour as explicit r, g, b floats instead of embedded escapes.
local function showOnScreenWarning(text, r, g, b)
    if not text or text == "" then return end
    pcall(function()
        if UIErrorsFrame and UIErrorsFrame.AddMessage then
            UIErrorsFrame:AddMessage(text, r or 1.0, g or 0.25, b or 0.25, 1.0)
        end
    end)
end

-- Returns the current warning mode: "off", "chat", or "full".
-- Also honors the legacy warnEnabled bool if warnMode isn't set yet.
local function currentWarnMode()
    if not SlotStatusDB then return "off" end
    local mode = SlotStatusDB.warnMode
    if mode == "off" or mode == "chat" or mode == "full" then return mode end
    -- Back-compat with the pre-0.5.0 boolean setting
    if SlotStatusDB.warnEnabled == false then return "off" end
    return "full"
end

local function checkDurabilityWarnings()
    local mode = currentWarnMode()
    if mode == "off" then return end
    local threshold = SlotStatusDB.warnThreshold or 25
    for _, s in ipairs(SLOTS) do
        local cur, max = GetInventoryItemDurability(s.id)
        if cur and max and max > 0 then
            local p = math.floor((cur / max) * 100 + 0.5)
            if p <= threshold then
                local key = s.id .. ":" .. threshold
                if not lastWarned[key] or (GetTime() - lastWarned[key]) > 60 then
                    lastWarned[key] = GetTime()
                    print(string.format(
                        "|cffff8800SlotStatus:|r |cffff3333%s is at %d%% durability|r",
                        s.label, p))
                    -- v0.9.25: also flash a small on-screen notice so the
                    -- warning is visible when the chat frame is scrolled
                    -- away or hidden.
                    showOnScreenWarning(
                        string.format("SlotStatus: %s at %d%% durability", s.label, p),
                        1.0, 0.40, 0.20)
                    if mode == "full" then
                        if PlaySound then
                            -- "igQuestFailed" is a soft alert tone available
                            -- in every WoW client since vanilla.
                            pcall(PlaySound, 847)  -- SOUNDKIT.IG_QUEST_FAILED
                        end
                        flashBar(bars[s.id], 0.9)
                    end
                end
            else
                lastWarned[s.id .. ":" .. threshold] = nil
            end
        end
    end
end

-- ====================== LIBDATABROKER INTEGRATION ======================
-- Broadcasts current durability as an LDB "data source" so Titan Panel,
-- ElvUI DataBars, Bazooka, etc. can display a SlotStatus text/icon.
-- Silently no-ops if LibStub / LibDataBroker-1.1 aren't loaded by another
-- addon. We do NOT ship LibStub to avoid dependencies.
SlotStatusLDB = nil

-- Forward-decls so registerLDB's OnClick closure (defined immediately
-- below) can capture these as upvalues. They are assigned further down
-- the file. Without forward-decl, the closure resolves them as globals
-- (nil at runtime) and silently does nothing when the LDB icon is
-- left-clicked. Same root cause pattern as build3DPreviewWindow earlier.
local openSlotStatusOptions
local settingsCategoryID

local function registerLDB()
    local LibStub = _G.LibStub
    if not LibStub then return end
    local ok, LDB = pcall(LibStub.GetLibrary, LibStub, "LibDataBroker-1.1", true)
    if not ok or not LDB then return end

    local ldb = LDB:NewDataObject("SlotStatus", {
        type  = "data source",
        label = "SlotStatus",
        text  = "--",
        icon  = "Interface\\ICONS\\INV_Hammer_16",
        OnClick = function(_, button)
            if button == "LeftButton" then
                openSlotStatusOptions()
            elseif button == "RightButton" then
                SlotStatusDB.autoRepair = not SlotStatusDB.autoRepair
                print("|cffffd200SlotStatus|r auto-repair " ..
                    (SlotStatusDB.autoRepair and "|cff00ff00ON|r" or "|cffff0000OFF|r"))
            end
        end,
        OnTooltipShow = function(tooltip)
            tooltip:AddLine("SlotStatus", 1, 0.82, 0)
            local worstLabel, worstPct
            for _, s in ipairs(SLOTS) do
                local cur, max = GetInventoryItemDurability(s.id)
                if cur and max and max > 0 then
                    local p = math.floor((cur / max) * 100 + 0.5)
                    if not worstPct or p < worstPct then
                        worstLabel, worstPct = s.label, p
                    end
                end
            end
            if worstLabel then
                tooltip:AddDoubleLine("Lowest slot:",
                    worstLabel .. " (" .. worstPct .. "%)",
                    1, 1, 1, 1, 1, 1)
            end
            local total = 0
            for _, s in ipairs(SLOTS) do
                local c = estimateSlotRepairCost(s.id)
                if c then total = total + c end
            end
            if total > 0 then
                tooltip:AddDoubleLine("Est. repair:",
                    formatMoney(total) or "0c",
                    1, 1, 1, 0, 1, 0)
            end
            tooltip:AddLine(" ")
            tooltip:AddLine("|cffaaaaaaLeft-click|r for options", 0.7, 0.7, 0.7)
            tooltip:AddLine("|cffaaaaaaRight-click|r to toggle auto-repair", 0.7, 0.7, 0.7)
        end,
    })

    ldb._update = function()
        local worst
        for _, s in ipairs(SLOTS) do
            local cur, max = GetInventoryItemDurability(s.id)
            if cur and max and max > 0 then
                local p = math.floor((cur / max) * 100 + 0.5)
                if not worst or p < worst then worst = p end
            end
        end
        if worst then
            local color = "|cff00ff00"
            if worst < cfgNum("threshY2R", 40) then
                color = "|cffff3333"
            elseif worst < cfgNum("threshG2Y", 75) then
                color = "|cffffff00"
            end
            ldb.text = color .. worst .. "%|r"
        else
            ldb.text = "100%"
        end
    end

    SlotStatusLDB = ldb
    ldb._update()
end

-- ====================== MINIMAP BUTTON ======================
--
-- Hand-built minimap button. We deliberately don't use LibDBIcon-1.0
-- because the addon already goes to pains NOT to ship LibStub (see
-- registerLDB comment above); adding LibDBIcon would force that. A
-- from-scratch minimap button is ~80 lines of Lua and gives us full
-- control of the tooltip content and click behaviour.
--
-- Position is stored as an ANGLE (in degrees) around the minimap, so
-- the button visually stays "clipped" to the minimap ring regardless
-- of which edge the user drags it to. Classic convention.

local minimapButton -- file-local so /ss mm toggle can find it

-- Forward-decl. The OnClick closure in buildMinimapButton below references
-- build3DPreviewWindow, but that function is declared later in the file as
-- `local function build3DPreviewWindow()`. Without this forward-decl, the
-- earlier closure resolves the name as a global (nil at runtime), and the
-- WoW default UI silently swallows the resulting error. With the decl here
-- and `function build3DPreviewWindow()` (no `local`) at the definition
-- site, both the minimap click path and the options-panel button bind to
-- the same upvalue.
local build3DPreviewWindow

-- Forward-decl for the v1.5.0 welcome popup, for the EXACT same reason
-- as build3DPreviewWindow above: the slash-command handler inside
-- registerSlashCommands (line ~1485) references `showWelcomePopup`
-- inside its closure. Without declaring the local BEFORE that closure
-- is parsed, Lua binds the reference as a global. Later, `function
-- showWelcomePopup()` (no `local`) at the real definition would then
-- assign to a different local and the slash handler would see nil.
-- The `welcomeFrame` singleton cache rides along here for symmetry
-- with `preview3D` (also declared near its builder).
local welcomeFrame
local showWelcomePopup

-- settingsCategoryID is forward-declared near registerLDB above so the
-- LDB OnClick closure can capture it. It is captured at options-panel
-- registration time when the modern Settings API is in use. Used by
-- openSlotStatusOptions() below so the open call can identify the
-- category by its real ID (most reliable across clients) rather than by
-- name string. Nil on legacy clients, in which case the legacy
-- InterfaceOptionsFrame_OpenToCategory path is used instead.

-- Compat-safe settings opener. The current Anniversary build has removed
-- InterfaceOptionsFrame_OpenToCategory (confirmed at runtime by the
-- "InterfaceOptionsFrame_OpenToCategory is nil" error). On those clients
-- Settings.OpenToCategory is the replacement. Legacy Classic/TBC Classic
-- still ship the old API. Try modern first, then fall back to legacy.
-- No `local` here: this assigns to the forward-declared upvalue near
-- registerLDB above, so the LDB OnClick can resolve this by reference.
function openSlotStatusOptions(tabIndex)
    local panel = SlotStatusOptionsPanel
    if not panel then
        print("|cffff5555SlotStatus|r options panel not built yet.")
        return false
    end

    if Settings and Settings.OpenToCategory then
        Settings.OpenToCategory(settingsCategoryID or panel.name)
        if tabIndex and panel.selectTab then
            panel.selectTab(tabIndex)
        end
        return true
    end

    if InterfaceOptionsFrame_OpenToCategory then
        -- Legacy double-call: first invocation sometimes doesn't focus
        -- the right panel on first open. Preserved verbatim for compat.
        InterfaceOptionsFrame_OpenToCategory(panel)
        InterfaceOptionsFrame_OpenToCategory(panel)
        if tabIndex and panel.selectTab then
            panel.selectTab(tabIndex)
        end
        return true
    end

    print("|cffff5555SlotStatus|r no options API available on this client.")
    return false
end

local function minimapButton_UpdatePosition()
    if not minimapButton then return end
    local angle = (SlotStatusDB and SlotStatusDB.minimapAngle) or 215
    local rad = math.rad(angle)
    -- Radius 80: just outside Minimap's default 70px radius, matching
    -- every other Blizzard-style minimap button in the wild.
    local x = math.cos(rad) * 80
    local y = math.sin(rad) * 80
    minimapButton:ClearAllPoints()
    minimapButton:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

local function buildMinimapButton()
    if minimapButton then return minimapButton end
    if not Minimap then return nil end

    local btn = CreateFrame("Button", "SlotStatusMinimapButton", Minimap)
    btn:SetFrameStrata("MEDIUM")
    btn:SetFrameLevel(Minimap:GetFrameLevel() + 8)
    btn:SetSize(31, 31)
    -- The tracking-border overlay below is 53x53 anchored at the button's
    -- TOPLEFT (no offset), so the visible ring extends +22px right and
    -- +22px down past the 31x31 hit rect. Without this, clicks on most of
    -- the visible button land outside the hit rect and never reach OnClick.
    btn:SetHitRectInsets(0, -22, 0, -22)
    btn:SetClampedToScreen(true)
    btn:SetMovable(true)
    btn:EnableMouse(true)
    -- Explicit button list (instead of "AnyUp") because some Classic-era
    -- clients have been observed to not enroll RightButton under "AnyUp".
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    btn:RegisterForDrag("LeftButton")

    -- Inner icon: our hammer. TexCoord trim removes Blizzard icon's stock
    -- 2px border so the icon sits clean inside the minimap-ring overlay.
    local icon = btn:CreateTexture(nil, "BACKGROUND")
    icon:SetTexture("Interface\\ICONS\\INV_Hammer_16")
    icon:SetSize(20, 20)
    icon:SetPoint("TOPLEFT", 7, -5)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    btn.icon = icon

    -- Authentic Blizzard minimap button ring overlay (tracking-border).
    local overlay = btn:CreateTexture(nil, "OVERLAY")
    overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    overlay:SetSize(53, 53)
    overlay:SetPoint("TOPLEFT")

    -- Click. Final mapping: Left = Preview, Right = Settings.
    --
    -- Click-path instrumentation has been removed (the click path was
    -- proven in a prior debug session). The nil-checks + pcall wrappers
    -- below are NOT instrumentation: they prevent the default UI from
    -- silently swallowing a future regression. They only print on actual
    -- failure, so they cost nothing on the happy path.
    btn:SetScript("OnClick", function(_, mouseButton)
        if mouseButton == "LeftButton" then
            if type(build3DPreviewWindow) ~= "function" then
                print("|cffff5555SlotStatus|r build3DPreviewWindow is "
                    .. type(build3DPreviewWindow) .. " (expected function)")
                return
            end
            local ok, wOrErr = pcall(build3DPreviewWindow)
            if not ok then
                print("|cffff5555SlotStatus|r preview error: " .. tostring(wOrErr))
                return
            end
            local w = wOrErr
            if not w then
                print("|cffff5555SlotStatus|r preview returned nil")
                return
            end
            if w:IsShown() then w:Hide() else w:Show() end

        elseif mouseButton == "RightButton" then
            -- openSlotStatusOptions handles modern Settings API vs legacy
            -- InterfaceOptionsFrame_OpenToCategory. The current Anniversary
            -- build doesn't have the legacy function, so this goes through
            -- Settings.OpenToCategory with the captured category ID.
            local ok, err = pcall(openSlotStatusOptions, 3)
            if not ok then
                print("|cffff5555SlotStatus|r settings open error: " .. tostring(err))
            end
        end
    end)

    -- Drag to reposition on the minimap ring. We compute angle from the
    -- cursor's position relative to the minimap centre each frame while
    -- dragging, and persist the final angle to DB on drag stop.
    btn:SetScript("OnDragStart", function(self)
        self:SetScript("OnUpdate", function()
            local mx, my = Minimap:GetCenter()
            if not mx then return end
            local px, py = GetCursorPosition()
            local s = Minimap:GetEffectiveScale()
            px, py = px / s, py / s
            local angle = math.deg(math.atan2(py - my, px - mx))
            if SlotStatusDB then SlotStatusDB.minimapAngle = angle end
            minimapButton_UpdatePosition()
        end)
    end)
    btn:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
    end)

    -- Tooltip -- matches spec exactly, plus a small "worst slot" line so
    -- the button is useful at a glance without a click.
    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        -- UI_GOLD_R/G/B isn't in lexical scope here (it's declared later
        -- in the file), so we use literal softer-amber values that match.
        GameTooltip:AddLine("SlotStatus", 0.92, 0.78, 0.32)

        local worstLabel, worstPct
        for _, s in ipairs(SLOTS) do
            local cur, mx = GetInventoryItemDurability(s.id)
            if cur and mx and mx > 0 then
                local p = math.floor((cur / mx) * 100 + 0.5)
                if not worstPct or p < worstPct then
                    worstLabel, worstPct = s.label, p
                end
            end
        end
        if worstLabel then
            GameTooltip:AddDoubleLine("Lowest slot:",
                worstLabel .. " (" .. worstPct .. "%)",
                0.9, 0.9, 0.9, 1, 1, 1)
        end

        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Left-click: Open Preview",  1, 1, 1)
        GameTooltip:AddLine("Right-click: Open Settings", 1, 1, 1)
        GameTooltip:AddLine("Drag to reposition on the minimap.", 0.55, 0.55, 0.6)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    minimapButton = btn
    minimapButton_UpdatePosition()

    if SlotStatusDB and SlotStatusDB.hideMinimap then
        btn:Hide()
    end
    return btn
end

local function toggleMinimapButton()
    if not minimapButton then buildMinimapButton() end
    if not minimapButton then return end
    if minimapButton:IsShown() then
        minimapButton:Hide()
        SlotStatusDB.hideMinimap = true
    else
        minimapButton:Show()
        SlotStatusDB.hideMinimap = false
    end
end

-- ====================== PRE-COMBAT WARNING ======================
local lastCombatWarn = 0
local function checkPreCombatWarning()
    if not SlotStatusDB or SlotStatusDB.combatWarn == false then return end
    if (GetTime() - lastCombatWarn) < 30 then return end
    local threshold = cfgNum("combatThresh", 35)

    local worst, worstPct, worstSlot
    for _, s in ipairs(SLOTS) do
        local cur, max = GetInventoryItemDurability(s.id)
        if cur and max and max > 0 then
            local p = math.floor((cur / max) * 100 + 0.5)
            if p <= threshold and (not worstPct or p < worstPct) then
                worst, worstPct, worstSlot = s.label, p, s.id
            end
        end
    end
    if not worst then return end
    lastCombatWarn = GetTime()

    print(string.format(
        "|cffff3333\226\154\160 SlotStatus \226\128\148 LOW DURABILITY|r : %s at |cffffff00%d%%|r (threshold %d%%)",
        worst, worstPct, threshold))
    -- v0.9.25: small on-screen echo of the pre-combat warning. Uses a
    -- slightly brighter red than the threshold-cross notice to read as
    -- an alarm rather than a status update.
    showOnScreenWarning(
        string.format("SlotStatus: LOW DURABILITY \226\128\148 %s at %d%%", worst, worstPct),
        1.0, 0.20, 0.20)
    if PlaySound then pcall(PlaySound, 847) end
    if worstSlot then flashBar(bars[worstSlot], 1.2) end
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("PLAYER_REGEN_DISABLED")
f:RegisterEvent("UPDATE_INVENTORY_DURABILITY")
f:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
f:RegisterEvent("MERCHANT_SHOW")

local function registerTooltipHooks()
    -- Single route into enhanceTooltip for CharacterFrame paperdoll slots.
    -- Blizzard's PaperDollItemSlotButton_OnEnter in 2.5.5 always calls
    -- GameTooltip:SetInventoryItem("player", slot) for an equipped slot,
    -- so this hooksecurefunc catches every paperdoll hover exactly once.
    --
    -- A previous OnTooltipSetItem hook was removed from this function: it
    -- fired AFTER SetInventoryItem had already populated the tooltip, so
    -- it only ever ran as a second call for the same tooltip/same slot,
    -- producing the duplicate "hook fired / skip duplicate for slot N"
    -- pairs in debug output. Its owner-name filter was ^Character.*Slot$,
    -- i.e. exactly the set SetInventoryItem already covers, so removing
    -- it loses zero coverage.
    hooksecurefunc(GameTooltip, "SetInventoryItem", function(self, unit, slot)
        enhanceTooltip(self, unit, slot)
    end)

    GameTooltip:HookScript("OnHide", function(tooltip)
        tooltip.slotStatusLastSlot = nil
    end)

    -- Fires whenever the tooltip is wiped (e.g. SetOwner). TBC's paper-doll
    -- UpdateTooltip loop clears+refills many times per second; without this
    -- reset our lines would be added once and then stripped on every refresh.
    GameTooltip:HookScript("OnTooltipCleared", function(tooltip)
        tooltip.slotStatusLastSlot = nil
    end)
end

local function onoff(b) return b and "|cff00ff00ON|r" or "|cffff0000OFF|r" end

-- v1.0.0: these are LIFETIME totals -- SlotStatusDB is per-character and
-- stats persist across sessions. The old "session stats" labels were
-- misleading; this function now prints the same authoritative lifetime
-- numbers shown in the Lifetime column of the Stats tab. For a split
-- session/lifetime view, open the options panel (`/ss options`) instead.
local function showStats()
    local s = SlotStatusDB and SlotStatusDB.stats or {}
    print("|cffffd200SlotStatus|r lifetime stats:")
    print(string.format("  Repair visits:   |cffffffff%d|r", s.visits or 0))
    print(string.format("  Repairs done:    |cffffffff%d|r", s.repair_count or 0))
    print(string.format("  Gold on repairs: |cffffffff%s|r", formatMoney(s.gold_repaired or 0) or "0c"))
    print(string.format("  Junk sold:       |cffffffff%d item(s)|r", s.grays_sold or 0))
    print(string.format("  Gold from junk:  |cffffffff%s|r", formatMoney(s.gold_from_gray or 0) or "0c"))
    local net = (s.gold_from_gray or 0) - (s.gold_repaired or 0)
    local color = net >= 0 and "|cff00ff00" or "|cffff5555"
    print(string.format("  Net:             %s%s|r", color, formatMoney(math.abs(net)) or "0c"))
end

local function resetStats()
    SlotStatusDB.stats = {}
    -- Re-baseline the Session column so it zeros out immediately rather
    -- than going negative against the pre-reset lifetime snapshot.
    if snapshotSessionStats then snapshotSessionStats() end
    print("|cffffd200SlotStatus|r stats reset.")
end

local function showHelp()
    print("|cffffd200SlotStatus|r commands:")
    print("  |cffffffff/ss|r or |cffffffff/slotstatus|r \226\128\148 this help")
    print("  |cffffffff/ss options|r      \226\128\148 open the options panel")
    print("  |cffffffff/ss advanced|r     \226\128\148 open options and jump to the Advanced tab")
    print("  |cffffffff/ss stats|r        \226\128\148 show session gold in/out")
    print("  |cffffffff/ss reset|r        \226\128\148 reset session stats")
    print("  |cffffffff/ss autorepair|r   \226\128\148 toggle auto-repair at vendor")
    print("  |cffffffff/ss autosell|r     \226\128\148 toggle auto-sell gray items")
    print("  |cffffffff/ss guild|r        \226\128\148 toggle \"use guild bank first for repairs\"")
    print("  |cffffffff/ss warn|r         \226\128\148 cycle warning mode (off / chat / full)")
    print("  |cffffffff/ss warn <N>|r     \226\128\148 set warning threshold percent (e.g. 25)")
    print("  |cffffffff/ss warn off|chat|full|r \226\128\148 pick mode directly")
    print("  |cffffffff/ss pins|r         \226\128\148 toggle world-map vendor pins")
    print("  |cffffffff/ss mm|r           \226\128\148 toggle minimap button")
    print("  |cffffffff/ss vendors|r      \226\128\148 list repair vendors you've discovered")
    print("  |cffffffff/ss vendors clear|r \226\128\148 forget all discovered vendors")
    print("  |cffffffff/ss discover|r     \226\128\148 toggle auto-discovery of repair vendors")
    print("  |cffffffff/ss debug|r        \226\128\148 toggle debug prints")
    print("  |cffffffff/ss test|r         \226\128\148 force a chest-slot tooltip")
    print("  |cffffffff/ss welcome|r      \226\128\148 re-open the welcome popup")
end

local function registerSlashCommands()
    SLASH_SLOTSTATUS1 = "/slotstatus"
    SLASH_SLOTSTATUS2 = "/ss"
    SlashCmdList["SLOTSTATUS"] = function(msg)
        msg = (msg or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
        local cmd, arg = msg:match("^(%S+)%s*(.-)$")
        cmd = cmd or ""

        if cmd == "" or cmd == "help" then
            showHelp()
        elseif cmd == "options" or cmd == "config" or cmd == "opt" then
            openSlotStatusOptions()
        elseif cmd == "advanced" or cmd == "adv" then
            openSlotStatusOptions(3)
        elseif cmd == "stats" then
            showStats()
        elseif cmd == "reset" then
            resetStats()
        elseif cmd == "autorepair" then
            SlotStatusDB.autoRepair = not SlotStatusDB.autoRepair
            print("|cffffd200SlotStatus|r auto-repair " .. onoff(SlotStatusDB.autoRepair))
        elseif cmd == "autosell" then
            SlotStatusDB.autoSell = not SlotStatusDB.autoSell
            print("|cffffd200SlotStatus|r auto-sell grays " .. onoff(SlotStatusDB.autoSell))
        elseif cmd == "guild" then
            SlotStatusDB.autoRepairGuild = not SlotStatusDB.autoRepairGuild
            print("|cffffd200SlotStatus|r use guild bank for repairs " .. onoff(SlotStatusDB.autoRepairGuild))
        elseif cmd == "warn" then
            if arg and arg ~= "" and tonumber(arg) then
                SlotStatusDB.warnThreshold = math.max(1, math.min(99, tonumber(arg)))
                if currentWarnMode() == "off" then SlotStatusDB.warnMode = "full" end
                print(string.format("|cffffd200SlotStatus|r low-durability warnings |cff00ff00ON|r at |cffffffff%d%%|r (mode: %s)",
                    SlotStatusDB.warnThreshold, currentWarnMode()))
            elseif arg == "off" or arg == "chat" or arg == "full" then
                SlotStatusDB.warnMode = arg
                print(string.format("|cffffd200SlotStatus|r warning mode: |cffffffff%s|r", arg))
            else
                -- cycle: off -> chat -> full -> off
                local m = currentWarnMode()
                local nextMode = (m == "off" and "chat") or (m == "chat" and "full") or "off"
                SlotStatusDB.warnMode = nextMode
                print(string.format("|cffffd200SlotStatus|r warning mode: |cffffffff%s|r (threshold: %d%%)",
                    nextMode, SlotStatusDB.warnThreshold or 25))
            end
        elseif cmd == "pins" then
            SlotStatusDB.mapPins = not (SlotStatusDB.mapPins ~= false)
            print("|cffffd200SlotStatus|r map pins " .. onoff(SlotStatusDB.mapPins))
            updateMapPins()
        elseif cmd == "mm" or cmd == "minimap" then
            toggleMinimapButton()
            print("|cffffd200SlotStatus|r minimap button " ..
                onoff(not SlotStatusDB.hideMinimap))
        elseif cmd == "discover" then
            SlotStatusDB.discoverVendors = not (SlotStatusDB.discoverVendors ~= false)
            print("|cffffd200SlotStatus|r auto-discover repair vendors " ..
                onoff(SlotStatusDB.discoverVendors))
        elseif cmd == "vendors" then
            local sub = arg or ""
            if sub == "clear" or sub == "reset" then
                SlotStatusDB.discoveredVendors = {}
                if updateMapPins then pcall(updateMapPins) end
                print("|cffffd200SlotStatus|r cleared all discovered repair vendors.")
            else
                local zones = SlotStatusDB.discoveredVendors or {}
                local zoneNames, total = {}, 0
                for z, bucket in pairs(zones) do
                    local n = 0
                    for _ in pairs(bucket) do n = n + 1 end
                    if n > 0 then
                        table.insert(zoneNames, z)
                        total = total + n
                    end
                end
                if total == 0 then
                    print("|cffffd200SlotStatus|r no repair vendors discovered yet. Open any merchant that can repair to start the list.")
                else
                    table.sort(zoneNames)
                    print(string.format("|cffffd200SlotStatus|r discovered |cffffffff%d|r repair vendor%s across |cffffffff%d|r zone%s:",
                        total, total == 1 and "" or "s",
                        #zoneNames, #zoneNames == 1 and "" or "s"))
                    for _, z in ipairs(zoneNames) do
                        print("  |cffc7c7cf" .. z .. "|r")
                        local names = {}
                        for n in pairs(zones[z]) do table.insert(names, n) end
                        table.sort(names)
                        for _, n in ipairs(names) do
                            local v = zones[z][n]
                            print(string.format("    \226\128\162 %s  |cff888888[%.1f, %.1f]%s|r",
                                n, v.x or 0, v.y or 0,
                                v.subzone and (" \226\128\147 " .. v.subzone) or ""))
                        end
                    end
                end
            end
        elseif cmd == "debug" then
            SlotStatusDB.debug = not SlotStatusDB.debug
            print("|cffffd200SlotStatus|r debug mode " .. onoff(SlotStatusDB.debug))
        elseif cmd == "test" then
            print("|cffffd200SlotStatus|r test: forcing tooltip on slot 5")
            GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR")
            GameTooltip:SetInventoryItem("player", 5)
            GameTooltip:Show()
        elseif cmd == "map" then
            print("|cffffd200SlotStatus|r map diagnostics:")
            local mi = GetMapInfo and GetMapInfo() or "(no GetMapInfo)"
            print("  GetMapInfo()       = " .. tostring(mi))
            print("  GetZoneText()      = " .. tostring(GetZoneText and GetZoneText() or "?"))
            print("  GetSubZoneText()   = " .. tostring(GetSubZoneText and GetSubZoneText() or "?"))
            print("  getViewedZoneName  = " .. tostring(getViewedZoneName()))
            print("  WorldMapFrame      = " .. tostring(WorldMapFrame and "yes" or "NIL") ..
                  "  shown=" .. tostring(WorldMapFrame and WorldMapFrame:IsShown()))
            print("  WorldMapDetailFrame= " .. tostring(WorldMapDetailFrame and "yes" or "NIL"))
            if WorldMapDetailFrame then
                print(string.format("    size=%dx%d",
                    WorldMapDetailFrame:GetWidth(), WorldMapDetailFrame:GetHeight()))
            end
            print("  WorldMapButton     = " .. tostring(WorldMapButton and "yes" or "NIL"))
            local scroll = WorldMapFrame and WorldMapFrame.ScrollContainer
            print("  ScrollContainer    = " .. tostring(scroll and "yes" or "NIL"))
            if scroll and scroll.Child then
                print(string.format("    Child size=%dx%d",
                    scroll.Child:GetWidth(), scroll.Child:GetHeight()))
            end
            local nPins, visPins = 0, 0
            for _, p in ipairs(mapPins) do
                nPins = nPins + 1
                if p:IsShown() then visPins = visPins + 1 end
            end
            print(string.format("  mapPins: total=%d shown=%d", nPins, visPins))
            local z = getViewedZoneName()
            print("  REPAIR_VENDORS['" .. tostring(z) .. "'] = " ..
                  (REPAIR_VENDORS[z] and (#REPAIR_VENDORS[z] .. " vendors") or "nil"))
            updateMapPins()
        elseif cmd == "welcome" or cmd == "testwelcome" then
            -- v1.5.0: opens the first-run welcome popup on demand.
            -- `testwelcome` is a dev-friendly alias while the auto-
            -- show-on-first-login switch is still disabled; once the
            -- auto-show flip lands, players can also reopen the
            -- popup anytime with `/ss welcome`. Same defensive
            -- pcall + type-check pattern as the minimap button's
            -- call into build3DPreviewWindow.
            if type(showWelcomePopup) ~= "function" then
                print("|cffff5555SlotStatus|r welcome popup not ready ("
                    .. type(showWelcomePopup) .. ")")
            else
                local ok, err = pcall(showWelcomePopup)
                if not ok then
                    print("|cffff5555SlotStatus|r welcome error: " .. tostring(err))
                end
            end
        else
            print("|cffffd200SlotStatus|r unknown command: " .. cmd)
            showHelp()
        end
    end
end

-- ====================== OPTIONS PANEL ======================
-- v0.8.0 palette: softer warm-amber accent (AtlasLoot-inspired), neutral
-- dark panel tones, subtle gradients instead of flat fills. Less yellow
-- glow, more depth, same WoW Classic/TBC silhouette.
local UI_GOLD_R, UI_GOLD_G, UI_GOLD_B = 0.92, 0.78, 0.32

-- Deep warm-neutral surface colors. Panel uses (TOP -> BOT) gradient so
-- the UI reads as a lit card instead of a flat rectangle.
local PANEL_BG_TOP_R, PANEL_BG_TOP_G, PANEL_BG_TOP_B, PANEL_BG_TOP_A = 0.10, 0.08, 0.06, 0.92
local PANEL_BG_BOT_R, PANEL_BG_BOT_G, PANEL_BG_BOT_B, PANEL_BG_BOT_A = 0.03, 0.02, 0.02, 0.96

local TAB_BG_TOP_R,   TAB_BG_TOP_G,   TAB_BG_TOP_B,   TAB_BG_TOP_A   = 0.05, 0.04, 0.03, 0.55
local TAB_BG_BOT_R,   TAB_BG_BOT_G,   TAB_BG_BOT_B,   TAB_BG_BOT_A   = 0.02, 0.015, 0.01, 0.70

-- Softer gold for borders so the panel stops shouting "yellow".
local EDGE_GOLD_R, EDGE_GOLD_G, EDGE_GOLD_B = UI_GOLD_R * 0.75, UI_GOLD_G * 0.65, 0.18

-- Vertical gradient helper -- tries each known API in order. The
-- Texture:SetGradient{,Alpha} surface has churned across versions:
--
--   Vanilla/TBC/Wrath (pre-DF):  SetGradientAlpha(orient, 4f, 4f)   -- legacy 9-arg
--                                SetGradient     (orient, r, g, b)  -- 3-arg midpoint
--   Dragonflight+ / Classic 1.15+:
--                                SetGradient     (orient, minColor, maxColor)
--                                  where colors are CreateColor() mixin objects
--                                SetGradientAlpha is REMOVED
--
-- We try modern first (because that's what current Anniversary/Classic
-- clients ship), fall back to legacy SetGradientAlpha (TBC 2.5.5, Wrath
-- 3.4.x), fall back to the 3-arg SetGradient (really old clients), and
-- finally to a flat SetVertexColor so the UI always renders *something*.
-- Each call is pcall'd so a signature mismatch can't nuke the panel build.
local function applyVerticalGradient(tex, r1, g1, b1, a1, r2, g2, b2, a2)
    -- Modern API: ColorMixin objects
    if tex.SetGradient and CreateColor then
        local c1 = CreateColor(r1, g1, b1, a1)
        local c2 = CreateColor(r2, g2, b2, a2)
        if pcall(tex.SetGradient, tex, "VERTICAL", c1, c2) then return end
    end
    -- Legacy 9-arg API
    if tex.SetGradientAlpha then
        if pcall(tex.SetGradientAlpha, tex, "VERTICAL",
                 r1, g1, b1, a1, r2, g2, b2, a2) then return end
    end
    -- Ancient 3-arg midpoint API
    if tex.SetGradient then
        if pcall(tex.SetGradient, tex, "VERTICAL",
                 (r1 + r2) / 2, (g1 + g2) / 2, (b1 + b2) / 2) then return end
    end
    -- Last resort: flat fill (top color, averaged alpha) so at least
    -- something renders.
    tex:SetVertexColor(r1, g1, b1, (a1 + a2) * 0.5)
end

-- v0.8.0: the 5th arg is now an EXPLICIT width in pixels, not a
-- right-inset. That change is deliberate -- computing the right edge
-- from "parent width minus inset" was the root cause of the Advanced
-- tab's column overlap: it let left-column headers reach into the right
-- column. Now every header divider ends at a caller-chosen width, so
-- two columns can never collide.
--   width  = pixels              -> line goes TOPLEFT+width
--   width  = nil or <=0          -> short dividing line (160px)
local function makeSectionHeader(parent, text, yOffset, xOffset, width)
    xOffset = xOffset or 20
    local fs = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    fs:SetPoint("TOPLEFT", xOffset, yOffset)
    fs:SetText(text)
    fs:SetTextColor(UI_GOLD_R, UI_GOLD_G, UI_GOLD_B)

    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetTexture("Interface\\Buttons\\WHITE8x8")
    line:SetVertexColor(EDGE_GOLD_R, EDGE_GOLD_G, EDGE_GOLD_B, 0.35)
    line:SetPoint("TOPLEFT", fs, "BOTTOMLEFT", 0, -3)
    line:SetWidth((width and width > 0) and width or 160)
    line:SetHeight(1)
    return fs
end

-- Lightweight sub-header used inside a section to tag a sub-group of rows
-- (e.g. "Durability" / "Category" under the "Bar Colors" section header).
-- Intentionally smaller and unlined so it never competes with the main
-- section header's underline treatment.
local function makeSubHeader(parent, text, yOffset, xOffset)
    xOffset = xOffset or 20
    local fs = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    fs:SetPoint("TOPLEFT", xOffset, yOffset)
    fs:SetText(text)
    fs:SetTextColor(UI_GOLD_R * 0.90, UI_GOLD_G * 0.82, UI_GOLD_B * 0.50)
    return fs
end

-- Thin amber hairline used as an in-section divider between sub-groups.
-- Matches the closing hairline above "Reset to defaults" in tone and alpha.
local function makeHairline(parent, yOffset, xOffset, width)
    xOffset = xOffset or 20
    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetTexture("Interface\\Buttons\\WHITE8x8")
    line:SetVertexColor(EDGE_GOLD_R, EDGE_GOLD_G, EDGE_GOLD_B, 0.25)
    line:SetPoint("TOPLEFT", xOffset, yOffset)
    line:SetWidth(width or 220)
    line:SetHeight(1)
    return line
end

local function makeCheckbox(parent, label, tooltip, getter, setter, yOffset, indent)
    local cb = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
    cb:SetPoint("TOPLEFT", 24 + (indent or 0), yOffset)
    cb.Text:SetText(label)
    cb.tooltipText = label
    cb.tooltipRequirement = tooltip
    cb:SetChecked(getter())

    local function sync()
        if cb:GetChecked() then
            cb.Text:SetTextColor(1.0, 0.90, 0.40)
        else
            cb.Text:SetTextColor(0.75, 0.75, 0.75)
        end
    end
    cb:SetScript("OnClick", function(self)
        setter(self:GetChecked() and true or false)
        sync()
    end)
    cb:HookScript("OnShow", sync)
    sync()
    return cb
end

local function makeMiniBar(parent, xFromRight, yFromTop, r, g, b, fillPct, label, tooltipTitle, tooltipBody)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(16, 64)
    frame:SetPoint("TOPRIGHT", parent, "TOPRIGHT", xFromRight, yFromTop)
    frame:EnableMouse(true)

    local border = frame:CreateTexture(nil, "BACKGROUND")
    border:SetPoint("TOPLEFT", -1, 1)
    border:SetPoint("BOTTOMRIGHT", 1, -1)
    border:SetTexture("Interface\\Buttons\\WHITE8x8")
    border:SetVertexColor(UI_GOLD_R, UI_GOLD_G, UI_GOLD_B, 0.55)

    local bg = frame:CreateTexture(nil, "BACKGROUND", nil, 1)
    bg:SetAllPoints()
    bg:SetTexture("Interface\\Buttons\\WHITE8x8")
    bg:SetVertexColor(0, 0, 0, 0.75)

    local fill = frame:CreateTexture(nil, "ARTWORK")
    fill:SetPoint("BOTTOMLEFT", 1, 1)
    fill:SetPoint("BOTTOMRIGHT", -1, 1)
    fill:SetTexture("Interface\\Buttons\\WHITE8x8")
    fill:SetVertexColor(r, g, b, 0.92)
    fill:SetHeight((64 - 2) * fillPct)

    local lbl = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    lbl:SetPoint("TOP", frame, "BOTTOM", 0, -2)
    lbl:SetText(label)
    lbl:SetTextColor(0.85, 0.85, 0.85)

    if tooltipTitle then
        frame:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine(tooltipTitle, UI_GOLD_R, UI_GOLD_G, UI_GOLD_B)
            if tooltipBody then
                GameTooltip:AddLine(tooltipBody, 1, 1, 1, true)
            end
            GameTooltip:Show()
        end)
        frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end
    return frame
end

-- ====================== SHARED ADVANCED-TAB HELPERS ======================

-- WoW's built-in ColorPickerFrame wrapper -- HARDENED for TBC Classic.
--
-- Why this is more defensive than a simple OpenColorPicker(info) call:
--
--   Blizzard's stock dispatch from OnColorSelect -> ColorPickerFrame.func()
--   is known to be flaky on TBC Classic 2.5.5 when another addon (Bagnon,
--   ElvUI, etc.) overwrites ColorPickerFrame.func or installs its own
--   SetScript("OnColorSelect", ...) without hooking. Our callbacks get
--   silently dropped and the user's color change never reaches our DB.
--
-- Three redundant paths apply the same color update, so only ONE of them
-- needs to succeed:
--
--   1. swatchFunc fires from stock OpenColorPicker on drag + Okay  (best)
--   2. A HookScript("OnColorSelect") we install once, gated by a flag
--   3. A HookScript("OnHide")         we install once, final safety net
--
-- All three funnel through applyNow(), which also tolerates being called
-- with a named table {r=,g=,b=} (retail cancelFunc payload) or a positional
-- array {r,g,b,opacity} (TBC Classic cancelFunc payload).

local _ssActiveColorCallback  -- the currently-active onChange, or nil

-- v0.8.8 premium polish. Installs ONCE per session.
--
--   Modal behavior (from v0.8.5/0.8.6, unchanged)
--     - FULLSCREEN_DIALOG strata + SetToplevel + :Raise() on open
--     - Fullscreen darkened backdrop (black @ 0.35), mouse-blocking
--
--   Visual polish
--     - Wheel housing: 9-layer composite matching the Bar Colors
--       swatch language. Vertical gradient base + 4 directional outer
--       edges + 4 inner bezel accents (2px inset). The gradient kills
--       the previous dead-black look.
--     - Right-side group housing: same 9-layer composite, anchored to
--       the right of the wheel at matched height. The Current and
--       Previous color swatches visually 'seat' inside it, and the
--       modal now reads as wheel-group / right-group / action-row,
--       not three unrelated floating elements.
--     - OK / Cancel: explicit 90x22 sizes, both anchored to the
--       frame's BOTTOM edge at the same Y inset. Baseline alignment
--       is bulletproof across locales and template changes.
--     - Hairline divider above the action row, 20px horizontal inset
--       matching the housings.
--     - Insets bumped ~4px across the board (PAD 6->8, BTN_INSET_Y
--       18->22) for breathing room without resizing the frame.
--
-- Blizzard internals NOT touched: title text, wheel texture, Current
-- /Previous swatch positions, opacity slider. Those get re-anchored
-- by many other picker addons; we only paint around them.
local _ssCPPolished = false
local function ensureColorPickerPolish()
    if _ssCPPolished then return end
    local cp = ColorPickerFrame
    if not cp then return end
    _ssCPPolished = true

    -- Each setup block is pcall-guarded so one unsupported API call on
    -- a given client build cannot halt the rest of the polish.
    local function pstep(_, fn) pcall(fn) end

    -- ---- Fullscreen modal backdrop ---------------------------------------
    local backdrop
    pstep("backdrop CreateFrame", function()
        backdrop = CreateFrame("Frame", "SlotStatusCPBackdrop", UIParent)
        backdrop:SetFrameStrata("FULLSCREEN")
        backdrop:SetAllPoints(UIParent)
        backdrop:EnableMouse(true)
        backdrop:Hide()

        local dim = backdrop:CreateTexture(nil, "BACKGROUND")
        dim:SetAllPoints()
        dim:SetTexture("Interface\\Buttons\\WHITE8x8")
        dim:SetVertexColor(0, 0, 0, 0.35)
    end)

    pstep("cp strata/toplevel/clamp", function()
        cp:SetFrameStrata("FULLSCREEN_DIALOG")
        cp:SetToplevel(true)
        cp:SetClampedToScreen(true)
    end)

    pstep("cp HookScript OnShow/OnHide for backdrop", function()
        if backdrop then
            cp:HookScript("OnShow", function() backdrop:Show() end)
            cp:HookScript("OnHide", function() backdrop:Hide() end)
        end
    end)

    -- ---- Shared premium-housing builder ----------------------------------
    -- Paints a 9-layer composite inside the given anchor rect:
    --   1. gradient base (warm-dark top -> darker bottom)
    --   2. 4x directional outer edges (top = light, bot = shadow,
    --      sides = mid bronze)
    --   3. 4x inner bezel accents 2px inside the outer edges
    -- All parented to ColorPickerFrame. The caller just sets the
    -- anchor rect on the returned base texture.
    local function paintHousing(setupAnchors)
        local base = cp:CreateTexture(nil, "BACKGROUND")
        base:SetTexture("Interface\\Buttons\\WHITE8x8")
        setupAnchors(base)
        -- Vertical gradient via the addon's existing helper. It tolerates
        -- every WoW client gradient API variant and falls back cleanly.
        applyVerticalGradient(base,
            0.09, 0.07, 0.05, 0.88,   -- top   (warmer)
            0.04, 0.03, 0.02, 0.78)   -- bot   (darker)

        local function edge(layer, r, g, b, a)
            local t = cp:CreateTexture(nil, layer)
            t:SetTexture("Interface\\Buttons\\WHITE8x8")
            t:SetVertexColor(r, g, b, a)
            return t
        end

        -- Outer edges: directional light
        local eT = edge("BORDER", UI_GOLD_R * 0.62, UI_GOLD_G * 0.50, 0.10, 0.78)
        eT:SetPoint("TOPLEFT",     base, "TOPLEFT",     0, 0)
        eT:SetPoint("TOPRIGHT",    base, "TOPRIGHT",    0, 0)
        eT:SetHeight(1)

        local eB = edge("BORDER", 0.10, 0.07, 0.04, 0.85)
        eB:SetPoint("BOTTOMLEFT",  base, "BOTTOMLEFT",  0, 0)
        eB:SetPoint("BOTTOMRIGHT", base, "BOTTOMRIGHT", 0, 0)
        eB:SetHeight(1)

        local eL = edge("BORDER", UI_GOLD_R * 0.48, UI_GOLD_G * 0.38, 0.10, 0.68)
        eL:SetPoint("TOPLEFT",     base, "TOPLEFT",     0, 0)
        eL:SetPoint("BOTTOMLEFT",  base, "BOTTOMLEFT",  0, 0)
        eL:SetWidth(1)

        local eR = edge("BORDER", UI_GOLD_R * 0.48, UI_GOLD_G * 0.38, 0.10, 0.68)
        eR:SetPoint("TOPRIGHT",    base, "TOPRIGHT",    0, 0)
        eR:SetPoint("BOTTOMRIGHT", base, "BOTTOMRIGHT", 0, 0)
        eR:SetWidth(1)

        -- Inner bezel: 1px warm-gold accents 2px inside the outer frame.
        -- Same containment language as the Bar Colors swatches.
        local function bezel()
            local t = cp:CreateTexture(nil, "BORDER")
            t:SetTexture("Interface\\Buttons\\WHITE8x8")
            t:SetVertexColor(UI_GOLD_R * 0.70, UI_GOLD_G * 0.58, 0.15, 0.40)
            return t
        end
        local bT = bezel(); bT:SetPoint("TOPLEFT",     base,  2, -2); bT:SetPoint("TOPRIGHT",    base, -2, -2); bT:SetHeight(1)
        local bB = bezel(); bB:SetPoint("BOTTOMLEFT",  base,  2,  2); bB:SetPoint("BOTTOMRIGHT", base, -2,  2); bB:SetHeight(1)
        local bL = bezel(); bL:SetPoint("TOPLEFT",     base,  2, -2); bL:SetPoint("BOTTOMLEFT",  base,  2,  2); bL:SetWidth(1)
        local bR = bezel(); bR:SetPoint("TOPRIGHT",    base, -2, -2); bR:SetPoint("BOTTOMRIGHT", base, -2,  2); bR:SetWidth(1)

        return base
    end

    -- ---- Wheel housing ---------------------------------------------------
    local wheel = _G.ColorPickerWheel
    local WHEEL_PAD = 8
    pstep("wheel housing paint", function()
        if wheel then
            paintHousing(function(base)
                base:SetPoint("TOPLEFT",     wheel, "TOPLEFT",     -WHEEL_PAD,  WHEEL_PAD)
                base:SetPoint("BOTTOMRIGHT", wheel, "BOTTOMRIGHT",  WHEEL_PAD, -WHEEL_PAD)
            end)
        end
    end)

    -- ---- Right-side group housing ----------------------------------------
    pstep("right-side group housing paint", function()
        if wheel then
            paintHousing(function(base)
                base:SetPoint("TOPLEFT",    wheel, "TOPRIGHT",    18,  WHEEL_PAD)
                base:SetPoint("BOTTOMLEFT", wheel, "BOTTOMRIGHT", 18, -WHEEL_PAD)
                base:SetWidth(150)
            end)
        end
    end)

    -- ---- OK / Cancel: explicit equal weight, explicit baseline -----------
    local okayBtn   = _G.ColorPickerOkayButton
    local cancelBtn = _G.ColorPickerCancelButton
    pstep("buttons + divider", function()
        if okayBtn and cancelBtn then
            local BTN_W, BTN_H = 90, 22
            local BTN_INSET_Y  = 22
            local BTN_GAP      = 14
            local H_INSET      = 20

            okayBtn:SetSize(BTN_W, BTN_H)
            cancelBtn:SetSize(BTN_W, BTN_H)

            cancelBtn:ClearAllPoints()
            cancelBtn:SetPoint("BOTTOMRIGHT", cp, "BOTTOMRIGHT", -H_INSET, BTN_INSET_Y)

            okayBtn:ClearAllPoints()
            okayBtn:SetPoint("BOTTOMRIGHT", cancelBtn, "BOTTOMLEFT", -BTN_GAP, 0)

            local divider = cp:CreateTexture(nil, "BORDER")
            divider:SetTexture("Interface\\Buttons\\WHITE8x8")
            divider:SetVertexColor(UI_GOLD_R * 0.45, UI_GOLD_G * 0.35, 0.08, 0.30)
            divider:SetPoint("BOTTOMLEFT",  cp, "BOTTOMLEFT",   H_INSET, BTN_INSET_Y + BTN_H + 14)
            divider:SetPoint("BOTTOMRIGHT", cp, "BOTTOMRIGHT", -H_INSET, BTN_INSET_Y + BTN_H + 14)
            divider:SetHeight(1)
        end
    end)
end

local function openColorPicker(r, g, b, onChange)
    local function applyNow(nr, ng, nb)
        if type(nr) == "table" then
            nr, ng, nb = nr.r or nr[1], nr.g or nr[2], nr.b or nr[3]
        end
        if nr and ng and nb then
            onChange(nr, ng, nb)
            if SlotStatusDB and SlotStatusDB.debug then
                print(string.format(
                    "|cffffd200SlotStatus|r |cff888888color applied: %.2f, %.2f, %.2f|r",
                    nr, ng, nb))
            end
        end
    end

    _ssActiveColorCallback = applyNow

    -- One-shot install of the belt + suspenders hooks. HookScript runs
    -- AFTER the stock handler, so we see the color the user actually
    -- selected regardless of what the stock dispatcher did with it.
    if not ColorPickerFrame._slotStatusHooked then
        ColorPickerFrame:HookScript("OnColorSelect", function(self)
            if _ssActiveColorCallback then
                local nr, ng, nb = self:GetColorRGB()
                _ssActiveColorCallback(nr, ng, nb)
            end
        end)
        ColorPickerFrame:HookScript("OnHide", function()
            -- Clear the callback once the picker closes so stale hooks
            -- can't fire into a different swatch later.
            _ssActiveColorCallback = nil
        end)
        ColorPickerFrame._slotStatusHooked = true
    end

    local info = {
        r = r, g = g, b = b,
        hasOpacity = false,
        swatchFunc = function(...)
            -- Accept both 0-arg (stock Classic path) and (r,g,b) args.
            local nr, ng, nb = ...
            if not nr then
                nr, ng, nb = ColorPickerFrame:GetColorRGB()
            end
            applyNow(nr, ng, nb)
        end,
        cancelFunc = function(prev) applyNow(prev) end,
    }

    if OpenColorPicker then
        OpenColorPicker(info)
    else
        -- Ultimate fallback for custom UI replacements that removed the
        -- global helper entirely.
        ColorPickerFrame:SetColorRGB(r, g, b)
        ColorPickerFrame.func           = info.swatchFunc
        ColorPickerFrame.cancelFunc     = info.cancelFunc
        ColorPickerFrame.hasOpacity     = false
        ColorPickerFrame.previousValues = { r = r, g = g, b = b }
        ColorPickerFrame:Show()
    end

    -- Center the picker on every open. Previously we anchored it to
    -- the right edge of the options frame, which read as "floating
    -- window glued to the panel" rather than "modal over the panel".
    -- Centering every time also resets any manual drag from the last
    -- session, so each swatch click feels deliberate.
    --
    -- ensureColorPickerPolish() installs the darkened backdrop and
    -- strata handling -- together with the centered anchor this is
    -- what makes the picker feel like a real active modal.
    ensureColorPickerPolish()

    if ColorPickerFrame then
        ColorPickerFrame:ClearAllPoints()
        local host = _G.InterfaceOptionsFrame
        if host and host:IsShown() then
            ColorPickerFrame:SetPoint("CENTER", host, "CENTER", 0, 0)
        else
            ColorPickerFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        end
        ColorPickerFrame:Raise()
    end
end

-- Color row: the swatch IS a live in-tab durability-bar preview.
--
-- Layout:  Healthy  [███████████████████████████]
--          ^label   ^live color bar (looks like the in-game bar)
--
-- Clicking anywhere on the row (label or bar) opens the color picker.
-- The hex code is in the tooltip, not inline, to reduce visual noise.
--
-- This row is the single most important element on the Advanced tab:
-- users never have to open a separate window to see color changes -- the
-- bar they're editing IS rendered in the same style as the in-game bar.
-- Row height is generous (26px / 20px bar) because the user explicitly
-- asked for these bars to feel like PRIMARY interactive elements, not
-- tiny color chips.
-- v0.8.4 double-frame polish.
--
-- Each swatch is a 7-layer composite carved to feel like an embedded
-- Blizzard settings control, not a status bar. Layer stack:
--
--   1. frame base       -- warm near-black, fills the whole housing
--   2. outer edge (4x)  -- directional: top=light bronze, bot=near-black,
--                          sides=mid bronze. Simulates a light source so
--                          the frame reads as carved, not flat-outlined.
--   3. inner bezel (4x) -- 1px warm-gold accent at 2px inset. The 'one
--                          more level of containment' layer: outer slot
--                          -> inner accent -> color fill.
--   4. fill             -- StatusBar, INSET 4px on all sides (fill 14h
--                          inside a 22h row), blended 82% raw + 18%
--                          warm-neutral -- greens/yellows calm down
--                          harder than red does (perceptual weighting).
--   5. top highlight    -- 2-row white falloff (0.18 / 0.07) inside fill
--   6. bottom shadow    -- 2-row black falloff (0.40 / 0.18) inside fill
--   7. hover highlight  -- full-frame white @ 0.08
--
-- Stored SlotStatusDB[dbKey] is untouched -- the blend happens only in
-- the paint path, so the color picker and tooltip always show the
-- user's real chosen color.
local function makeColorSwatch(parent, x, y, labelText, dbKey, onChanged, width, tooltipExtra)
    local ROW_W, ROW_H   = width or 220, 22
    local LABEL_W          = 78
    local FRAME_INSET      = 4    -- v0.8.4: fill inset moved past the new bezel
    local BEZEL_INSET      = 2    -- inner accent line, 2px in from outer edge

    -- Render-time blend toward a warm-neutral, NOT a uniform scalar mute.
    -- A flat x0.90 hit green/yellow/red equally, but because green and
    -- yellow have higher perceptual luminance they kept reading as loud
    -- while red looked fine. Mixing 18% warm-grey pulls high-luminance
    -- channels harder toward the neutral, so greens/yellows calm down
    -- more than red does. Stored SlotStatusDB[dbKey] is never touched.
    local COLOR_KEEP       = 0.82
    local NEUTRAL_R        = 0.26
    local NEUTRAL_G        = 0.22
    local NEUTRAL_B        = 0.16

    local holder = CreateFrame("Button", nil, parent)
    holder:SetSize(ROW_W, ROW_H)
    holder:SetPoint("TOPLEFT", x, y)

    local lbl = holder:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    lbl:SetPoint("LEFT", 0, 0)
    lbl:SetWidth(LABEL_W)
    lbl:SetJustifyH("LEFT")
    lbl:SetText(labelText)

    -- ---- Housing (dark inset frame) --------------------------------------
    local frame = CreateFrame("Frame", nil, holder)
    frame:SetPoint("TOPLEFT",     LABEL_W, 0)
    frame:SetPoint("BOTTOMRIGHT", 0,       0)

    local frameBg = frame:CreateTexture(nil, "BACKGROUND")
    frameBg:SetAllPoints()
    frameBg:SetTexture("Interface\\Buttons\\WHITE8x8")
    frameBg:SetVertexColor(0.06, 0.05, 0.04, 1.0)

    -- Directional outer edge (top = light catch, bottom = shadow, sides
    -- = mid bronze). Four single-color lines so each pixel of border is
    -- fully opaque against the dark base -- no translucent overlay that
    -- would wash the frame color out.
    local function edge(layer, r, g, b, a)
        local t = frame:CreateTexture(nil, layer)
        t:SetTexture("Interface\\Buttons\\WHITE8x8")
        t:SetVertexColor(r, g, b, a)
        return t
    end

    -- Top (brighter bronze -- 'catches the light')
    local eT = edge("BORDER", UI_GOLD_R * 0.62, UI_GOLD_G * 0.50, 0.10, 0.78)
    eT:SetPoint("TOPLEFT",  0, 0); eT:SetPoint("TOPRIGHT",     0, 0); eT:SetHeight(1)

    -- Bottom (near-black -- 'in shadow')
    local eB = edge("BORDER", 0.10, 0.07, 0.04, 0.85)
    eB:SetPoint("BOTTOMLEFT", 0, 0); eB:SetPoint("BOTTOMRIGHT", 0, 0); eB:SetHeight(1)

    -- Sides (mid bronze)
    local eL = edge("BORDER", UI_GOLD_R * 0.48, UI_GOLD_G * 0.38, 0.10, 0.68)
    eL:SetPoint("TOPLEFT",  0, 0); eL:SetPoint("BOTTOMLEFT",    0, 0); eL:SetWidth(1)
    local eR = edge("BORDER", UI_GOLD_R * 0.48, UI_GOLD_G * 0.38, 0.10, 0.68)
    eR:SetPoint("TOPRIGHT", 0, 0); eR:SetPoint("BOTTOMRIGHT",   0, 0); eR:SetWidth(1)

    -- Inner bezel accent: a second thin rectangle, 2px inside the outer
    -- edge. This is the 'one more level of containment' the polish pass
    -- called for -- outer dark slot -> inner accent -> color fill.
    local function bezel()
        local t = frame:CreateTexture(nil, "ARTWORK")
        t:SetTexture("Interface\\Buttons\\WHITE8x8")
        t:SetVertexColor(UI_GOLD_R * 0.70, UI_GOLD_G * 0.58, 0.15, 0.42)
        return t
    end
    local bT = bezel(); bT:SetPoint("TOPLEFT",     BEZEL_INSET, -BEZEL_INSET); bT:SetPoint("TOPRIGHT",    -BEZEL_INSET, -BEZEL_INSET); bT:SetHeight(1)
    local bB = bezel(); bB:SetPoint("BOTTOMLEFT",  BEZEL_INSET,  BEZEL_INSET); bB:SetPoint("BOTTOMRIGHT", -BEZEL_INSET,  BEZEL_INSET); bB:SetHeight(1)
    local bL = bezel(); bL:SetPoint("TOPLEFT",     BEZEL_INSET, -BEZEL_INSET); bL:SetPoint("BOTTOMLEFT",   BEZEL_INSET,  BEZEL_INSET); bL:SetWidth(1)
    local bR = bezel(); bR:SetPoint("TOPRIGHT",   -BEZEL_INSET, -BEZEL_INSET); bR:SetPoint("BOTTOMRIGHT", -BEZEL_INSET,  BEZEL_INSET); bR:SetWidth(1)

    -- ---- Fill (color, inset INSIDE the inner bezel) ----------------------
    -- Same StatusBar render path the real durability bars use, so the
    -- swatch is WYSIWYG even with the blend + depth treatment.
    local bar = CreateFrame("StatusBar", nil, frame)
    bar:SetPoint("TOPLEFT",     FRAME_INSET, -FRAME_INSET)
    bar:SetPoint("BOTTOMRIGHT", -FRAME_INSET, FRAME_INSET)
    bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
    bar:SetMinMaxValues(0, 100)
    bar:SetValue(100)
    bar:SetFrameLevel(frame:GetFrameLevel() + 1)

    -- ---- Depth cues (2-row top highlight + 2-row bottom shadow) ----------
    -- A single 1px line at 0.10 / 0.35 alpha was below the threshold of
    -- visibility at normal read distance. Stacking two rows each side
    -- gives a soft falloff that's clearly felt but never flashy.
    local function depthLine(a, alpha, dyFromInset)
        local t = frame:CreateTexture(nil, "OVERLAY")
        t:SetTexture("Interface\\Buttons\\WHITE8x8")
        t:SetVertexColor(a, a, a, alpha)
        return t
    end
    local topHi1 = depthLine(1, 0.18)
    topHi1:SetPoint("TOPLEFT",  FRAME_INSET,     -FRAME_INSET);       topHi1:SetPoint("TOPRIGHT", -FRAME_INSET,     -FRAME_INSET);       topHi1:SetHeight(1)
    local topHi2 = depthLine(1, 0.07)
    topHi2:SetPoint("TOPLEFT",  FRAME_INSET,     -(FRAME_INSET + 1)); topHi2:SetPoint("TOPRIGHT", -FRAME_INSET,     -(FRAME_INSET + 1)); topHi2:SetHeight(1)

    local botSh1 = depthLine(0, 0.40)
    botSh1:SetPoint("BOTTOMLEFT",  FRAME_INSET,  FRAME_INSET);        botSh1:SetPoint("BOTTOMRIGHT", -FRAME_INSET,  FRAME_INSET);        botSh1:SetHeight(1)
    local botSh2 = depthLine(0, 0.18)
    botSh2:SetPoint("BOTTOMLEFT",  FRAME_INSET,  FRAME_INSET + 1);    botSh2:SetPoint("BOTTOMRIGHT", -FRAME_INSET,  FRAME_INSET + 1);    botSh2:SetHeight(1)

    -- ---- Hover (covers the whole housing, not just the fill) -------------
    local highlight = holder:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints(frame)
    highlight:SetTexture("Interface\\Buttons\\WHITE8x8")
    highlight:SetVertexColor(1, 1, 1, 0.08)

    -- Single source of truth: reads from DB, blends toward warm-neutral,
    -- repaints the bar. SlotStatusDB[dbKey] is never touched -- mute
    -- happens only in the paint path, so the color picker and tooltip
    -- always show the user's real chosen color.
    local function refresh()
        local c = SlotStatusDB and SlotStatusDB[dbKey] or {1, 1, 1}
        local r = c[1] * COLOR_KEEP + NEUTRAL_R * (1 - COLOR_KEEP)
        local g = c[2] * COLOR_KEEP + NEUTRAL_G * (1 - COLOR_KEEP)
        local b = c[3] * COLOR_KEEP + NEUTRAL_B * (1 - COLOR_KEEP)
        bar:SetStatusBarColor(r, g, b)
    end
    holder.refresh = refresh

    local function applyColor(nr, ng, nb)
        SlotStatusDB[dbKey] = {nr, ng, nb}
        refresh()
        if onChanged then onChanged() end
    end

    holder:SetScript("OnClick", function()
        local c = SlotStatusDB[dbKey] or {1, 1, 1}
        openColorPicker(c[1], c[2], c[3], applyColor)
    end)
    holder:SetScript("OnEnter", function(self)
        local c = SlotStatusDB[dbKey] or {1, 1, 1}
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(labelText, 1, 0.82, 0)
        if tooltipExtra then
            GameTooltip:AddLine(tooltipExtra, 0.85, 0.78, 0.60, true)
        end
        GameTooltip:AddLine(string.format("#%02X%02X%02X",
            math.floor(c[1] * 255 + 0.5),
            math.floor(c[2] * 255 + 0.5),
            math.floor(c[3] * 255 + 0.5)), 0.7, 0.7, 0.7)
        GameTooltip:AddLine("Click to change color.", 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)
    holder:SetScript("OnLeave", function() GameTooltip:Hide() end)

    refresh()
    return holder
end

-- Labeled slider bound to a SlotStatusDB key.
-- Layout:
--     <title>   <current value in gold>
--     [=====O================]
--     min                    max
-- v1.0.0: restyled to match the Advanced tab's `makeInlineSlider` so both
-- tabs use a single visual language -- thin hairline track + jewel thumb
-- + dimmed Low/High labels + gold right-aligned value. Previously this
-- function used Blizzard's `OptionsSliderTemplate` (recessed groove +
-- chevron thumb), which made the General tab's warning sliders look
-- like a different product from the Advanced tab's bar-color sliders.
--
-- Function signature unchanged: (parent, name, y, labelText, minV,
-- maxV, step, dbKey, suffix, onChanged, xLeft, width) -> slider, nextY.
-- Vertical footprint unchanged at 54 px so existing `y = ny` math at
-- call sites (lines ~4085, ~4088) still lines up without adjustment.
local function makeLabeledSlider(parent, name, y, labelText, minV, maxV, step, dbKey, suffix, onChanged, xLeft, width)
    xLeft  = xLeft or 24
    width  = width or 240
    suffix = suffix or ""

    -- ---- Row 1: label (left) + value (right) ------------------------
    local lbl = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    lbl:SetPoint("TOPLEFT", xLeft, y)
    lbl:SetWidth(width)
    lbl:SetJustifyH("LEFT")
    lbl:SetText(labelText)

    local valueText = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    valueText:SetPoint("TOPRIGHT", lbl, "TOPRIGHT", 0, 0)
    valueText:SetJustifyH("RIGHT")
    valueText:SetTextColor(UI_GOLD_R, UI_GOLD_G, 0.28)

    -- ---- Row 2: minimal hairline track + jewel thumb ----------------
    local TRACK_H = 12   -- interaction hit-area height
    local TRACK_Y = y - 22
    local THUMB_W = 16
    local THUMB_H = 16

    local slider = CreateFrame("Slider", name, parent)
    slider:SetOrientation("HORIZONTAL")
    slider:SetSize(width, TRACK_H)
    slider:SetPoint("TOPLEFT", xLeft, TRACK_Y)
    slider:SetMinMaxValues(minV, maxV)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)
    slider:EnableMouse(true)

    -- 1-pixel bronze hairline anchored across the slider's full width.
    local trackLine = slider:CreateTexture(nil, "ARTWORK")
    trackLine:SetTexture("Interface\\Buttons\\WHITE8x8")
    trackLine:SetVertexColor(0.55, 0.47, 0.30, 0.55)
    trackLine:SetPoint("LEFT",  slider, "LEFT",  0, 0)
    trackLine:SetPoint("RIGHT", slider, "RIGHT", 0, 0)
    trackLine:SetHeight(1)

    -- Blizzard's built-in slider jewel (small kite/diamond). Matches
    -- the reference image and is shipped with every WoW client.
    local thumbTex = slider:CreateTexture(nil, "OVERLAY")
    thumbTex:SetTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
    thumbTex:SetSize(THUMB_W, THUMB_H)
    slider:SetThumbTexture(thumbTex)

    -- ---- Row 3: min / max reference labels --------------------------
    local lowText = parent:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    lowText:SetPoint("TOPLEFT", slider, "BOTTOMLEFT", 0, -6)
    lowText:SetJustifyH("LEFT")
    lowText:SetTextColor(0.55, 0.55, 0.58)

    local highText = parent:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    highText:SetPoint("TOPRIGHT", slider, "BOTTOMRIGHT", 0, -6)
    highText:SetJustifyH("RIGHT")
    highText:SetTextColor(0.55, 0.55, 0.58)

    local function fmt(v)
        if step < 0.1 then
            return string.format("%.2f%s", v, suffix)
        elseif step < 1 then
            return string.format("%.1f%s", v, suffix)
        end
        return string.format("%d%s", math.floor(v + 0.5), suffix)
    end

    lowText:SetText(fmt(minV))
    highText:SetText(fmt(maxV))

    slider.refresh = function()
        local v = cfgNum(dbKey, minV)
        slider:SetValue(v)
        valueText:SetText(fmt(v))
    end
    slider:SetScript("OnValueChanged", function(self, v)
        if step >= 1 then v = math.floor(v + 0.5) end
        if SlotStatusDB then SlotStatusDB[dbKey] = v end
        valueText:SetText(fmt(v))
        if onChanged then onChanged(v) end
    end)
    slider.refresh()
    -- Total vertical footprint: 54 px (same as before, preserves the
    -- callers' y-advance math).
    return slider, y - 54
end

-- Forward-declared so the Reset button in the Advanced tab can call it.
local initDefaults

-- ============ GEAR & REPAIR OVERVIEW WINDOW (floating, movable) ============
--
-- v0.8.9: Rebuilt from scratch. The previous window was a paper-doll
-- preview with a decorative "durability scrubber" -- both features
-- duplicated things Blizzard's character sheet already shows. The new
-- window is a single-screen repair cockpit: the one thing the addon
-- doesn't offer anywhere else.
--
--   +----------------------------------------------------------+
--   | SlotStatus - Gear Overview                           [X] |
--   +--------------------+-------------------------------------+
--   |                    |  Total repair:   3g 42s 18c         |
--   |                    |  Gold on hand:  12g 08s 00c  OK     |
--   |     [3D MODEL]     |  -------------------------------    |
--   |     (smaller,      |  Critical: 2    Worn: 3    OK: 5    |
--   |      decorative)   |  Avg durability:  58%               |
--   |                    +-------------------------------------+
--   |                    |  Slot/Item      Dur.   Repair   *   |
--   |                    |  -------------------------------    |
--   |                    |  Chest  Hauberk 22%    42s      *   |
--   |                    |  Legs   Pants   38%    65s      *   |
--   |                    |  ... sorted worst-first, max 11     |
--   +--------------------+-------------------------------------+
--   | [ Repair All ]  [ Find Nearest Vendor ]        v0.8.9    |
--   +----------------------------------------------------------+
--
-- Backend plumbing is shared with the options panel and the live bars:
-- estimateSlotRepairCost / getNearestRepairVendor / formatMoney / cfgColor
-- / cfgNum / SlotStatusDB.stats. No new persistent state is introduced.
local preview3D -- file-local so Advanced tab refreshers can find it
-- `welcomeFrame` and `showWelcomePopup` forward-decls live near line
-- ~1160 next to build3DPreviewWindow — they MUST be declared before
-- registerSlashCommands is parsed or the slash handler binds them as
-- globals. See the comment block up there for the full rationale.

-- NOTE: no `local` keyword here — this assigns to the forward-declared
-- file-chunk local near the top of the file, so earlier closures (notably
-- the minimap button's OnClick) can resolve this reference as an upvalue.
--
-- v0.8.9: this window was previously a paper-doll preview with a
-- decorative "durability scrubber". That layout duplicated Blizzard's
-- character sheet and didn't surface any information the user couldn't
-- see elsewhere. Rebuilt as a Gear & Repair Overview: a 3D model for
-- visual anchor on the left, and on the right a live summary card +
-- per-slot repair table + Repair All / Find Nearest Vendor footer. It
-- reuses the existing estimateSlotRepairCost / getNearestRepairVendor /
-- formatMoney / setDurabilityColor / cfgColor / cfgNum plumbing.
function build3DPreviewWindow()
    if preview3D then return preview3D end

    -- ---------------- WINDOW GEOMETRY (single source of truth) ----------------
    -- All child offsets derive from these. Change one, everything follows.
    -- v0.9.9: the left character/model pane was removed. The window now
    -- hosts a single content column (summary + slot table), so it is
    -- narrower than before and the content fills the full width.
    -- v0.9.21: footer strip trimmed from 36 → 28 (just enough to house a
    -- 24-px button with a 2-px halo above/below) and the window shortened
    -- by 12 px so the empty band below the buttons no longer dominates
    -- the bottom of the panel.
    local W, H          = 540, 508
    local TITLE_H       = 26
    local FOOTER_H      = 28
    local CONTENT_L     = 14       -- content left padding (inside OUT_INSET)
    local RIGHT_INSET_R = 14       -- content right padding
    local ROW_H         = 20       -- table row height
    local ROW_GAP       = 2        -- vertical gap between rows

    local f = CreateFrame("Frame", "SlotStatus3DPreviewWindow", UIParent)
    f:SetSize(W, H)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:SetFrameLevel(10)
    f:SetToplevel(true)
    f:SetMovable(true)
    f:SetClampedToScreen(true)
    f:EnableMouse(true)
    -- Drag is registered on the title bar only (Blizzard dialog pattern).
    f:Hide()

    -- ESC-to-close: register the named frame with Blizzard's UISpecialFrames
    -- table. When the user presses ESC, ToggleGameMenu walks this table
    -- first and hides any entries that are currently shown, so our window
    -- closes cleanly before the game menu opens. The named frame on line
    -- ~2146 is the required dependency. Idempotent guard in case /reload
    -- quirks ever cause this block to execute twice in one session.
    do
        local wanted = "SlotStatus3DPreviewWindow"
        local already = false
        for _, n in ipairs(UISpecialFrames) do
            if n == wanted then already = true; break end
        end
        if not already then
            tinsert(UISpecialFrames, wanted)
        end
    end

    -- ---- Blizzard-style shell (tiled dialog bg + metallic gold frame) ----
    -- v0.9.22: wBg's BOTTOMRIGHT offset dropped from OUT_INSET (+5) to 0
    -- so the tiled dialog-bg texture now extends all the way down to the
    -- frame's bottom edge. Previously the bottom 5 px of the frame was a
    -- bare un-tiled outer bezel; the footer buttons (BTN_Y=2) sat with
    -- their lower 3 px inside that bezel, producing a visible dark ledge
    -- across the full width below [Repair All] [Find Nearest Vendor].
    -- The bronze hairline (`eBot`) still draws on top in BORDER layer, so
    -- the panel's bottom edge remains crisp.
    local OUT_INSET = 5
    local wBg = f:CreateTexture(nil, "BACKGROUND")
    wBg:SetPoint("TOPLEFT",     OUT_INSET, -OUT_INSET)
    wBg:SetPoint("BOTTOMRIGHT", -OUT_INSET, 0)
    wBg:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
    if wBg.SetHorizTile then wBg:SetHorizTile(true) end
    if wBg.SetVertTile then wBg:SetVertTile(true) end
    wBg:SetVertexColor(0.78, 0.76, 0.72, 1)

    local function outerEdge(ly, r, g, b, a)
        local t = f:CreateTexture(nil, ly)
        t:SetTexture("Interface\\Buttons\\WHITE8x8")
        t:SetVertexColor(r, g, b, a)
        return t
    end
    -- v0.9.10 frame polish: the old 2-px metallic-gold outline was too loud
    -- and pulled the eye off the content. Swapped to a single 1-px bronze
    -- hairline with a muted top highlight, a soft near-black bottom shadow,
    -- and quiet side rails. The content is now the figure, not the chrome.
    local oGoldT, oGoldB = 0.46, 0.36       -- dim bronze highlight (was UI_GOLD*0.72)
    local eTop = outerEdge("BORDER", oGoldT, oGoldB, 0.14, 0.55)
    eTop:SetPoint("TOPLEFT",     f, "TOPLEFT",     0, 0)
    eTop:SetPoint("TOPRIGHT",    f, "TOPRIGHT",    0, 0)
    eTop:SetHeight(1)
    local eBot = outerEdge("BORDER", 0.08, 0.06, 0.04, 0.75)
    eBot:SetPoint("BOTTOMLEFT",  f, "BOTTOMLEFT",  0, 0)
    eBot:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
    eBot:SetHeight(1)
    local eL = outerEdge("BORDER", 0.32, 0.24, 0.10, 0.50)
    eL:SetPoint("TOPLEFT",     f, "TOPLEFT",     0, 0)
    eL:SetPoint("BOTTOMLEFT",  f, "BOTTOMLEFT",  0, 0)
    eL:SetWidth(1)
    local eR = outerEdge("BORDER", 0.32, 0.24, 0.10, 0.50)
    eR:SetPoint("TOPRIGHT",    f, "TOPRIGHT",    0, 0)
    eR:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
    eR:SetWidth(1)

    -- -------------------------- TITLE BAR --------------------------
    local tb = CreateFrame("Frame", nil, f)
    tb:SetPoint("TOPLEFT",  OUT_INSET, -OUT_INSET)
    tb:SetPoint("TOPRIGHT", -OUT_INSET, -OUT_INSET)
    tb:SetHeight(TITLE_H)
    tb:SetFrameLevel(f:GetFrameLevel() + 20)
    tb:EnableMouse(true)
    tb:RegisterForDrag("LeftButton")
    tb:SetScript("OnDragStart", function() f:StartMoving() end)
    tb:SetScript("OnDragStop", function()
        f:StopMovingOrSizing()
        if SlotStatusDB then
            local p, _, rp, x, y = f:GetPoint()
            SlotStatusDB.preview3dPos = {p, rp, x, y}
        end
    end)

    local tbBg = tb:CreateTexture(nil, "ARTWORK")
    tbBg:SetAllPoints()
    tbBg:SetTexture("Interface\\Buttons\\WHITE8x8")
    applyVerticalGradient(tbBg,
        0.06, 0.09, 0.16, 1,
        0.02, 0.04, 0.08, 1)
    local tbBot = tb:CreateTexture(nil, "ARTWORK")
    tbBot:SetPoint("BOTTOMLEFT",  tb, "BOTTOMLEFT",  0, 0)
    tbBot:SetPoint("BOTTOMRIGHT", tb, "BOTTOMRIGHT", 0, 0)
    tbBot:SetHeight(1)
    tbBot:SetTexture("Interface\\Buttons\\WHITE8x8")
    tbBot:SetVertexColor(oGoldT, oGoldB, 0.15, 0.55)

    local title = tb:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("LEFT", 10, 0)
    title:SetText("SlotStatus \226\128\148 Gear Overview")
    title:SetTextColor(0.96, 0.94, 0.88)

    local close = CreateFrame("Button", nil, tb, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", 4, 4)
    close:SetFrameLevel(tb:GetFrameLevel() + 2)
    close:SetScript("OnClick", function() f:Hide() end)

    -- ==================== LAYOUT SCAFFOLDING ====================
    -- Content sits between the title bar and the footer. Vertically:
    --   [ title bar     ]  0 .. -TITLE_H
    --   [ content area  ] -TITLE_H .. -(H - FOOTER_H)   (title 26, footer 28)
    --   [ footer        ] -(H - FOOTER_H) .. -H         (-480 .. -508)
    -- Horizontally the content fills the entire window (v0.9.9). The old
    -- vertical divider that separated the left model pane from the right
    -- content has been removed along with the pane itself.
    local footerDiv = f:CreateTexture(nil, "ARTWORK")
    footerDiv:SetTexture("Interface\\Buttons\\WHITE8x8")
    footerDiv:SetVertexColor(EDGE_GOLD_R, EDGE_GOLD_G, EDGE_GOLD_B, 0.45)
    footerDiv:SetPoint("BOTTOMLEFT",  OUT_INSET, FOOTER_H)
    footerDiv:SetPoint("BOTTOMRIGHT", -OUT_INSET, FOOTER_H)
    footerDiv:SetHeight(1)

    -- Single-column content x-range (used by summary, table rows, hairlines).
    local rxL = OUT_INSET + CONTENT_L
    local rxR = W - RIGHT_INSET_R
    local rW  = rxR - rxL

    -- Inset content pane: subtle second-layer dialog tile. Hosts the summary
    -- card and the slot table. Now spans the full content width.
    local rightPane = CreateFrame("Frame", nil, f)
    rightPane:SetFrameLevel(f:GetFrameLevel() - 1) -- paints under summary/table rows
    rightPane:SetPoint("TOPLEFT",     f, "TOPLEFT",     rxL - 6, -OUT_INSET - TITLE_H - 4)
    rightPane:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -RIGHT_INSET_R + 2, FOOTER_H + 4)
    local rpTex = rightPane:CreateTexture(nil, "BACKGROUND")
    rpTex:SetPoint("TOPLEFT",     2, -2)
    rpTex:SetPoint("BOTTOMRIGHT", -2, 2)
    rpTex:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
    if rpTex.SetHorizTile then rpTex:SetHorizTile(true) end
    if rpTex.SetVertTile then rpTex:SetVertTile(true) end
    rpTex:SetVertexColor(0.22, 0.20, 0.18, 0.65)
    -- Inset-pane edges: very quiet so the pane reads as a soft recess rather
    -- than a second framed card competing with the outer hairline.
    local rpEdgeT = rightPane:CreateTexture(nil, "BORDER")
    rpEdgeT:SetTexture("Interface\\Buttons\\WHITE8x8")
    rpEdgeT:SetVertexColor(oGoldT, oGoldB, 0.14, 0.32)
    rpEdgeT:SetPoint("TOPLEFT",     rightPane, "TOPLEFT",     0, 0)
    rpEdgeT:SetPoint("TOPRIGHT",    rightPane, "TOPRIGHT",    0, 0)
    rpEdgeT:SetHeight(1)
    local rpEdgeB = rightPane:CreateTexture(nil, "BORDER")
    rpEdgeB:SetTexture("Interface\\Buttons\\WHITE8x8")
    rpEdgeB:SetVertexColor(0.06, 0.05, 0.03, 0.40)
    rpEdgeB:SetPoint("BOTTOMLEFT",  rightPane, "BOTTOMLEFT",  0, 0)
    rpEdgeB:SetPoint("BOTTOMRIGHT", rightPane, "BOTTOMRIGHT", 0, 0)
    rpEdgeB:SetHeight(1)
    local rpEdgeL = rightPane:CreateTexture(nil, "BORDER")
    rpEdgeL:SetTexture("Interface\\Buttons\\WHITE8x8")
    rpEdgeL:SetVertexColor(0.26, 0.20, 0.08, 0.30)
    rpEdgeL:SetPoint("TOPLEFT",     rightPane, "TOPLEFT",     0, 0)
    rpEdgeL:SetPoint("BOTTOMLEFT",  rightPane, "BOTTOMLEFT",  0, 0)
    rpEdgeL:SetWidth(1)
    local rpEdgeR = rightPane:CreateTexture(nil, "BORDER")
    rpEdgeR:SetTexture("Interface\\Buttons\\WHITE8x8")
    rpEdgeR:SetVertexColor(0.26, 0.20, 0.08, 0.30)
    rpEdgeR:SetPoint("TOPRIGHT",    rightPane, "TOPRIGHT",    0, 0)
    rpEdgeR:SetPoint("BOTTOMRIGHT", rightPane, "BOTTOMRIGHT", 0, 0)
    rpEdgeR:SetWidth(1)

    -- ==================== LEFT CHARACTER PANEL — REMOVED (v0.9.9) =============
    -- The 3D model, portrait well, identity text block, drag/zoom scripts,
    -- and PlayerModel frame have all been deleted. The panel is now a pure
    -- durability + repair utility; the character showcase added no value
    -- and caused the dead-space / yellow-backdrop issues documented in the
    -- v0.9.x polish cycle. The remaining content (summary card + slot
    -- table + footer) fills the full window width, anchored to rxL / rxR.
    --
    -- If you need to add an identity anchor back later, a single GameFont
    -- line under the title bar is enough; do NOT re-introduce a model well.

    -- ==================== SUMMARY CARD ====================
    -- Three self-contained groups, each with its own typographic primary and
    -- a closing hairline (or a deliberate small-text tail):
    --   1. CONDITION    — small-caps header, big severity headline, hairline
    --   2. REPAIR COST  — header, large Total, muted Gold w/ afford glyph, hairline
    --   3. GEAR WEAR    — header, Needs repair (med), Lowest (small),
    --                     band breakdown (smaller), Avg durability (muted)
    local SUMMARY_TOP    = -OUT_INSET - TITLE_H - 6
    local SUMMARY_ROW_H  = 16
    local LABEL_COL_W    = 108
    -- v0.9.14: both Repair-Cost values (`valTotal` and `valGold`) anchor
    -- with a SINGLE `RIGHT` point to their own label's `RIGHT`, offset by
    -- `rW - LABEL_COL_W` (the horizontal gap from label-right to pane-right,
    -- i.e. `rxR`). A single-anchor RIGHT on a FontString keeps the right
    -- edge pinned while the text naturally grows leftward — so "No repair
    -- needed", a large "8g 78s 91c", and "0c" all land on the same right
    -- rail as the slot-table hairlines below, regardless of font object.
    -- (Previous dual LEFT+RIGHT anchors stretched the rect but drifted when
    -- SetFontObject swapped between GameFontNormalLarge and GameFontNormal
    -- on the zero-state.)
    -- v0.9.10: widened HEADER_DROP so each group's mini-header reads as a
    -- titled region rather than another stacked line; trimmed COND_TAIL_PAD
    -- slightly to keep the whole summary within the same vertical budget.
    -- v0.9.23 neatness pass:
    --   * HEADER_DROP nudged up (14 → 12) now that the condition headline
    --     is GameFontNormal, not Large — keeps the header visually tied
    --     to its first row without the "stacked" feel.
    --   * GROUP_GAP widened (12 → 14) so the three groups read as three
    --     distinct titled regions rather than one running list.
    --   * COND_TAIL_PAD tightened (20 → 14) to match the smaller headline
    --     — no more dead space between "Critical" and its hairline.
    --   * SEC_HDR tint brightened slightly so the small-caps headers are
    --     clearly legible instead of fading into the tiled dialog bg.
    -- v1.4.2 typography refinement (text-layout-only):
    --   * CONDITION headline is now centered in the content column and
    --     restored to GameFontNormalLarge. Because REPAIR COST's value
    --     rail is right-aligned and CONDITION's gravity is now the pane
    --     center, the two no longer compete — centering alone gives
    --     the verdict word its "main message" role through placement.
    --   * COND_TAIL_PAD widened (14 → 18) so the larger centered headline
    --     has proper breathing room above the hairline.
    --   * REPAIR_ROW_GAP replaces the previous ad-hoc `SUMMARY_ROW_H + 4`
    --     spacing between Total and Gold. Named constant makes the row
    --     rhythm deliberate and trivially tunable.
    --   * Row labels in REPAIR COST are now uppercase stat labels
    --     ("TOTAL REPAIR" / "GOLD ON HAND") rendered in a single shared
    --     font + tone, so both rows read as one clean label column.
    --     Tier is carried by the VALUE fonts (Large vs Small), not the
    --     labels, which is stronger typography than the old mixed-label
    --     approach.
    -- v1.4.3 tier-hierarchy pass:
    --   * The v1.4.2 pass collapsed the REPAIR block into three identical
    --     tiny-amber-uppercase lines (section header + two row labels),
    --     so the eye read three stacked headers instead of one header
    --     plus two stat rows. Root cause: row labels and section headers
    --     were both GameFontNormalSmall-class at nearly the same tint.
    --   * Fix: establish one 3-tier system used consistently across all
    --     three blocks.
    --       T1 Section header     GameFontDisableSmall, UPPERCASE, dim
    --                             amber (SEC_HDR).
    --       T2 Row label / status GameFontNormal, warm cream (ROW_LBL).
    --                             v1.4.3: uppercase for stat labels,
    --                             sentence case for status prose.
    --                             v1.4.5: sentence case for ALL T2
    --                             (stat labels included). Keeps the
    --                             T1->T2 jump carrying both size AND
    --                             case, instead of two T1/T2 rows of
    --                             uppercase collapsing together.
    --       T3 Value / detail     GameFontNormalLarge white (primary
    --                             VALUES) or GameFontNormalSmall/Disable-
    --                             Small muted cream (supporting details).
    --     The critical jump is T1 -> T2: a clear size AND brightness
    --     break. That's what was missing in REPAIR previously.
    --   * HEADER_DROP renamed to HDR_TO_CONTENT for clarity (same value,
    --     same role: gap from each section header to its first content
    --     line).
    --   * REPAIR_ROW_GAP bumped 18 -> 20: row labels grew from Small
    --     (~10pt) to Normal (~12pt) and needed a touch more breathing
    --     so the two stat rows don't feel cramped.
    --   * SEC_HDR dimmed so the T1 tier recedes visually against the
    --     dialog tile; ROW_LBL brightened so the T2 tier clearly pops.
    local HDR_TO_CONTENT = 12
    local GROUP_GAP      = 14
    local COND_TAIL_PAD  = 18
    local REPAIR_ROW_GAP = 20
    -- T1 tone: dim amber. Section headers (CONDITION / REPAIR COST /
    -- GEAR WEAR) sit quiet against the tiled dialog bg so they read as
    -- chapter markers, not as another content row competing with the
    -- T2 labels directly below them.
    local SEC_HDR_R, SEC_HDR_G, SEC_HDR_B = 0.68, 0.58, 0.30
    -- T2 tone: warm cream. Shared by REPAIR COST's row labels (Total
    -- repair / Gold on hand) AND GEAR WEAR's four row labels (Needs
    -- repair / Lowest / Status / Average). This is the tier the eye
    -- scans, so it has to be clearly brighter than SEC_HDR —
    -- otherwise T1 and T2 collapse back into one tier (the v1.4.2
    -- bug).
    local ROW_LBL_R, ROW_LBL_G, ROW_LBL_B = 0.88, 0.82, 0.60

    local function makeLabel(layer, font, x, y, w, align, r, g, b)
        local fs = f:CreateFontString(nil, layer, font)
        fs:SetPoint("TOPLEFT", x, y)
        if w then fs:SetWidth(w) end
        fs:SetJustifyH(align or "LEFT")
        if r then fs:SetTextColor(r, g, b) end
        return fs
    end

    local function makeHairline(y, alpha)
        local t = f:CreateTexture(nil, "ARTWORK")
        t:SetTexture("Interface\\Buttons\\WHITE8x8")
        t:SetVertexColor(EDGE_GOLD_R, EDGE_GOLD_G, EDGE_GOLD_B, alpha)
        t:SetPoint("TOPLEFT",  rxL, y)
        t:SetPoint("TOPRIGHT", f, "TOPRIGHT", -RIGHT_INSET_R, y)
        t:SetHeight(1)
        return t
    end

    -- ==================== GROUP 1 — CONDITION ====================
    -- v1.4.3: section header is center-aligned so the entire CONDITION
    -- block shares one vertical axis (header + status). The status is
    -- a large centered headline — a left-anchored header above it used
    -- to look off-balance. Centering both creates one composed block
    -- where the "main message" placement reads as deliberate.
    -- v1.4.4: -6 px nudge on the header's top anchor so there's a bit
    -- more breathing room between the title-bar bottom and the small-
    -- caps CONDITION header. Because every subsequent Y in this group
    -- (headline, hairline, and via moneySepY the REPAIR COST block) is
    -- derived from ySec, the whole CONDITION region shifts together as
    -- one block — no downstream anchors need touching.
    local ySec = SUMMARY_TOP - 6
    local secOverview = makeLabel("ARTWORK", "GameFontDisableSmall", rxL, ySec, rW, "CENTER", SEC_HDR_R, SEC_HDR_G, SEC_HDR_B)
    secOverview:SetText("CONDITION")

    -- v0.9.23: condition headline dropped from GameFontNormalLarge to
    -- GameFontNormal. The Large size was competing with the primary
    -- repair-cost number below ("1g 81s 53c") for the role of "headline".
    -- Keeping the verdict word at medium weight lets the cost value
    -- dominate as intended, and reads tidier next to the matching
    -- "Needs repair: 10 items" line in GEAR WEAR below.
    -- v1.4.2: Large restored AND centered. The v0.9.23 competition with
    -- the cost number only existed because both sat on the left rail at
    -- similar sizes. Now that the condition is centered in the content
    -- column, its visual gravity is the middle of the pane while the
    -- cost value's gravity is the right rail — so they read as two
    -- separate focal regions rather than two left-anchored headlines
    -- fighting for the same role. The verdict word is the first thing
    -- the user should see on open, and centered placement makes that
    -- hierarchy explicit.
    local yCond = ySec - HDR_TO_CONTENT
    local conditionText = f:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    conditionText:SetPoint("TOPLEFT", rxL, yCond)
    conditionText:SetWidth(rW)
    conditionText:SetJustifyH("CENTER")
    conditionText:SetText("\226\128\148")
    conditionText:SetTextColor(0.92, 0.90, 0.82)

    -- v1.4.4: short decorative tick directly under the condition
    -- verdict word. Anchored `TOP` -> `BOTTOM` of `conditionText` so
    -- it hugs the text's baseline region and slides with it (the
    -- verdict word changes between "Excellent" / "Needs repair" /
    -- "Worn" / "Critical" at refresh time, but the headline's center
    -- and bottom stay fixed because `conditionText` has `SetWidth(rW)`
    -- + `SetJustifyH("CENTER")`). Fixed 100 px width (not text-width-
    -- matched) keeps the tick a stable decorative accent regardless
    -- of which verdict is displayed. 140 px comfortably overshoots
    -- even the longest verdict ("Needs repair") at GameFontNormalLarge
    -- by ~20 px on each side, giving the tick a clear decorative-rule
    -- feel (a small framed underline) rather than a tight underline
    -- that has to perfectly match the word. It still reads as a
    -- "short hairline" compared to the full-pane block-separators
    -- below (`condSep`, `moneySep`), so the CONDITION block stays
    -- visually distinct from the group boundaries. Alpha 0.55 is
    -- brighter than the 0.30 block-
    -- separators below because this tick is a headline accent tied
    -- to a single word, not a group boundary; it needs to read as
    -- decoration-on-the-word, not as a dim structural divider.
    -- v1.4.7: promoted from a 140 px decorative tick to a full-width
    -- hairline (rxL -> rxR, same span as the REPAIR/GEAR WEAR divider
    -- below). Anchors to `conditionText`'s BOTTOM with a small -3 px
    -- gap so the line reads as a heavy underline directly under the
    -- verdict rather than a mid-gap divider. Alpha stays 0.55 (hotter
    -- than the 0.30 structural separators) because this line pulls
    -- double duty — it's BOTH the verdict's underline AND the
    -- CONDITION section's bottom boundary, so it needs to announce
    -- itself the way the short tick used to while also separating
    -- CONDITION from REPAIR COST. The old dim `condSep` at
    -- `condSepY` has been retired (would've stacked a second gold
    -- line ~20 px below this one), but `condSepY` is preserved as a
    -- pure layout anchor so nothing below this block shifts.
    local condTick = f:CreateTexture(nil, "ARTWORK")
    condTick:SetTexture("Interface\\Buttons\\WHITE8x8")
    condTick:SetVertexColor(EDGE_GOLD_R, EDGE_GOLD_G, EDGE_GOLD_B, 0.55)
    condTick:SetHeight(1)
    -- Full-width underline anchor set:
    --   * TOP  -> conditionText.BOTTOM - 3   (vertical position,
    --     tracks the verdict so the line hugs the word)
    --   * LEFT -> frame.LEFT  + rxL          (left pane rail)
    --   * RIGHT-> frame.RIGHT - RIGHT_INSET_R (right pane rail)
    -- Three-point anchoring means the line's width is derived from
    -- the rails, not from SetWidth, so it always spans the full
    -- summary pane regardless of window geometry.
    condTick:SetPoint("TOP",   conditionText, "BOTTOM", 0, -3)
    condTick:SetPoint("LEFT",  f, "LEFT",  rxL, 0)
    condTick:SetPoint("RIGHT", f, "RIGHT", -RIGHT_INSET_R, 0)

    local condSepY = yCond - COND_TAIL_PAD
    -- v1.4.7: dim structural separator retired — `condTick` above is
    -- now full-width and serves as the CONDITION/REPAIR COST
    -- boundary. `condSepY` kept as a pure anchor so `yCostHdr` below
    -- doesn't shift.

    -- ==================== GROUP 2 — REPAIR COST ==================
    local yCostHdr = condSepY - GROUP_GAP
    local secCost = makeLabel("ARTWORK", "GameFontDisableSmall", rxL, yCostHdr, rW, "LEFT", SEC_HDR_R, SEC_HDR_G, SEC_HDR_B)
    secCost:SetText("REPAIR COST")

    -- Two-column value layout — shared right rail:
    --   label ...................................... value
    -- Each value fontstring has a SINGLE `RIGHT` anchor to its label's
    -- RIGHT, offset by (rW - LABEL_COL_W) horizontally. That offset is
    -- exactly the distance from the label's right edge to the pane's
    -- right edge (rxR), so both values land on the same right rail as
    -- the hairlines above/below. Vertical centers lock to the label's
    -- vertical center, so a GameFontNormalLarge cost, a GameFontNormal
    -- "No repair needed", and a GameFontNormalSmall gold total all sit
    -- on the same baseline-relative center — no drift when the font
    -- object is swapped in refresh().
    local VALUE_RIGHT_OFFSET = rW - LABEL_COL_W

    -- v1.4.2: both row labels use the same small font + shared amber
    -- tone (ROW_LBL_*) so they stack as a single clean label column
    -- under the "REPAIR COST" section header. Tier between the two
    -- rows is expressed by the VALUES (Large white total vs. Small
    -- muted wallet), not by the labels — that keeps the label column
    -- visually quiet and stat-sheet-like.
    -- v1.4.5: row labels reverted from ALL-CAPS ("TOTAL REPAIR" /
    -- "GOLD ON HAND") to sentence case ("Total repair" / "Gold on
    -- hand"). The uppercase treatment read as shouty next to the
    -- already-uppercase CONDITION / REPAIR COST / GEAR WEAR section
    -- headers above; two tiers of uppercase collapsed visually into
    -- one dense block. Sentence case on the row labels keeps the T1
    -- section headers (UPPERCASE amber) clearly distinct from the T2
    -- row labels (sentence-case amber) — the casing itself now
    -- carries the tier shift that used to be carried only by size.
    local yTotal = yCostHdr - HDR_TO_CONTENT
    local lblTotal = makeLabel("ARTWORK", "GameFontNormal", rxL, yTotal, LABEL_COL_W, "LEFT", ROW_LBL_R, ROW_LBL_G, ROW_LBL_B)
    lblTotal:SetText("Total repair")

    local valTotal = f:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    valTotal:SetPoint("RIGHT", lblTotal, "RIGHT", VALUE_RIGHT_OFFSET, 0)
    valTotal:SetJustifyH("RIGHT")
    valTotal:SetTextColor(1, 1, 1)

    -- Wallet row: same label font/tone as Total repair (one clean
    -- label column), but the VALUE stays small + muted so the afford
    -- glyph reads as metadata, not a second headline.
    local yGold = yTotal - REPAIR_ROW_GAP
    local lblGold = makeLabel("ARTWORK", "GameFontNormal", rxL, yGold, LABEL_COL_W, "LEFT", ROW_LBL_R, ROW_LBL_G, ROW_LBL_B)
    lblGold:SetText("Gold on hand")

    local valGold = f:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    valGold:SetPoint("RIGHT", lblGold, "RIGHT", VALUE_RIGHT_OFFSET, 0)
    valGold:SetJustifyH("RIGHT")
    valGold:SetTextColor(0.82, 0.80, 0.72)

    -- v0.9.24: afford glyph lives in its own fontstring so `valGold` can
    -- right-anchor cleanly at rxR and share a value column with `valTotal`.
    -- Previously the "OK" / "short X" text was concatenated into `valGold`
    -- itself; because the fontstring is right-justified, the badge sat
    -- flush at rxR and the actual money amount got shoved leftward by the
    -- badge's width — so `valTotal` and `valGold` no longer shared a
    -- right edge. Splitting the badge into its own fontstring, anchored
    -- to the LEFT of `valGold` with a small gap, restores the shared
    -- right rail and puts the badge in the gutter between label and
    -- value where it reads as metadata, not a competing value.
    local valGoldStatus = f:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    valGoldStatus:SetPoint("RIGHT", valGold, "LEFT", -8, 0)
    valGoldStatus:SetJustifyH("RIGHT")
    valGoldStatus:SetText("")

    -- v1.4.6: the hairline drops an extra HAIRLINE_DROP px away from
    -- `yGold` so there's a real breath between "Gold on hand" and the
    -- divider. `yWearHdr` adds that same offset back so the GEAR WEAR
    -- block (and the slot table below it) stays anchored exactly
    -- where it was before — only the hairline itself moves, splitting
    -- the GROUP_GAP asymmetrically (more above the divider, less
    -- below) so it sits closer to the section it introduces.
    local HAIRLINE_DROP = 8
    local moneySepY = yGold - SUMMARY_ROW_H + 2 - HAIRLINE_DROP
    -- v1.4.3: matches condSep's 0.22 -> 0.30 bump so the REPAIR/GEAR
    -- WEAR block boundary reads as firmly as the CONDITION/REPAIR one.
    local moneySep = makeHairline(moneySepY, 0.30)

    -- ==================== GROUP 3 — GEAR WEAR ====================
    -- v1.4.4: -6 px nudge on yWearHdr to match the CONDITION header's
    -- -6 px drop. Keeps the "section gets a real breath above it"
    -- treatment consistent across both section boundaries (rather than
    -- only CONDITION feeling more spacious). All of GEAR WEAR's
    -- content rows and the slot-table header below derive from
    -- yWearHdr / yLow, so the whole block slides down together.
    -- v1.4.6: `+ HAIRLINE_DROP` compensates for the hairline drop
    -- above so this header stays at its previous Y.
    local yWearHdr = moneySepY - GROUP_GAP - 6 + HAIRLINE_DROP
    local secWear = makeLabel("ARTWORK", "GameFontDisableSmall", rxL, yWearHdr, rW, "LEFT", SEC_HDR_R, SEC_HDR_G, SEC_HDR_B)
    secWear:SetText("GEAR WEAR")

    -- v1.4.5 unified stat-sheet layout (replaces v1.4.4's two-column
    -- block, which itself replaced the v0.9.24 four-row stack):
    --   Row 1: Needs repair ............. N items
    --   Row 2: Lowest ............. <item> — NN%
    --   Row 3: Status ....... Critical N   Worn N   OK N
    --   Row 4: Average ....................... NN%
    --
    -- Rationale:
    --   * GEAR WEAR now uses the SAME row idiom as REPAIR COST
    --     directly above it: `lblX` (GameFontNormal amber at rxL) +
    --     `valX` (GameFontNormal cream, RIGHT->RIGHT anchored to the
    --     label with VALUE_RIGHT_OFFSET so its right edge lands at
    --     rxR). Both blocks share one left rail (labels) and one
    --     right rail (values), so the entire summary card reads as a
    --     single stat sheet.
    --   * Baselines align per-row because label+value use the same
    --     font object on the same row, pinned via RIGHT->RIGHT.
    --   * Row rhythm uses REPAIR_ROW_GAP (20 px) — same as REPAIR
    --     COST, so both blocks breathe identically.
    --   * The v1.4.4 two-column layout looked like a stat sheet but
    --     actually used two independent rails (one for left prose,
    --     one for right counts/avg) with mixed fonts; the eye saw
    --     four alignments instead of two. This pass collapses that
    --     to two rails.
    --   * All four data points are peer-level stats (count, item+%,
    --     band breakdown, avg%), so no Large/Small hierarchy inside
    --     GEAR WEAR — every row is GameFontNormal. REPAIR COST keeps
    --     its Large(Total)/Small(Gold) hierarchy because those two
    --     rows are a genuine headline+metadata pair.
    --   * Terse labels ("Lowest", "Status", "Average") fit inside
    --     the existing LABEL_COL_W = 108 so no global constants
    --     change. Swapping to fuller labels ("Lowest durability",
    --     "Average durability") would need LABEL_COL_W bumped to
    --     ~140 and is a trivial follow-up.
    --   * GEAR WEAR grows ~20 px vs v1.4.4 (4 rows * 20 gap vs 2 rows
    --     * 14 gap). Dialog height stays fixed at (540, 508); the
    --     slot table's top edge slides down the same 20 px, so the
    --     bottom end of the table loses ~one row of worst-case room
    --     (equipped characters typically have 8-10 items, well under
    --     the MAX_ROWS = 11 worst case).
    local yNeed   = yWearHdr - HDR_TO_CONTENT
    local yLow    = yNeed    - REPAIR_ROW_GAP
    local yStatus = yLow     - REPAIR_ROW_GAP
    local yAvg    = yStatus  - REPAIR_ROW_GAP

    -- Row 1: Needs repair | N items
    local lblNeeds = makeLabel("ARTWORK", "GameFontNormal", rxL, yNeed, LABEL_COL_W, "LEFT", ROW_LBL_R, ROW_LBL_G, ROW_LBL_B)
    lblNeeds:SetText("Needs repair")
    local valNeeds = f:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    valNeeds:SetPoint("RIGHT", lblNeeds, "RIGHT", VALUE_RIGHT_OFFSET, 0)
    valNeeds:SetJustifyH("RIGHT")
    valNeeds:SetTextColor(0.92, 0.90, 0.82)
    valNeeds:SetText("\226\128\148")

    -- Row 2: Lowest | <item> — NN%
    local lblLowest = makeLabel("ARTWORK", "GameFontNormal", rxL, yLow, LABEL_COL_W, "LEFT", ROW_LBL_R, ROW_LBL_G, ROW_LBL_B)
    lblLowest:SetText("Lowest")
    local valLowest = f:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    valLowest:SetPoint("RIGHT", lblLowest, "RIGHT", VALUE_RIGHT_OFFSET, 0)
    valLowest:SetJustifyH("RIGHT")
    valLowest:SetTextColor(0.92, 0.90, 0.82)
    valLowest:SetText("\226\128\148")

    -- Row 3: Status | colored band breakdown
    local lblStatus = makeLabel("ARTWORK", "GameFontNormal", rxL, yStatus, LABEL_COL_W, "LEFT", ROW_LBL_R, ROW_LBL_G, ROW_LBL_B)
    lblStatus:SetText("Status")
    local valStatus = f:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    valStatus:SetPoint("RIGHT", lblStatus, "RIGHT", VALUE_RIGHT_OFFSET, 0)
    valStatus:SetJustifyH("RIGHT")
    valStatus:SetTextColor(0.92, 0.90, 0.82)
    valStatus:SetText("\226\128\148")

    -- Row 4: Average | NN%
    local lblAvg = makeLabel("ARTWORK", "GameFontNormal", rxL, yAvg, LABEL_COL_W, "LEFT", ROW_LBL_R, ROW_LBL_G, ROW_LBL_B)
    lblAvg:SetText("Average")
    local valAvg = f:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    valAvg:SetPoint("RIGHT", lblAvg, "RIGHT", VALUE_RIGHT_OFFSET, 0)
    valAvg:SetJustifyH("RIGHT")
    valAvg:SetTextColor(0.92, 0.90, 0.82)
    valAvg:SetText("\226\128\148")

    -- ==================== TABLE ====================
    -- Columns: icon | name (flex) | Dur. | Repair | Alert (conditional chip)
    -- The alert column is *only* drawn for Worn / Critical rows; OK rows
    -- leave it empty so the far-right edge stays quiet and non-OK rows
    -- actually jump out.
    --
    -- Fixed columns are sized to their *worst-case* rendered width (100%,
    -- 99g 99s 99c, "!! Crit") with a ~2 px breathing buffer. Everything else
    -- belongs to the name column so item names like "Crown of Destruction"
    -- render in full instead of being clipped mid-word.
    local ICON_W, ICON_GAP   = 20, 6
    local PCT_W, COST_W      = 32, 66
    local STATUS_W           = 54   -- holds "!! Crit" chip with breathing room
    local GUTTER             = 10
    -- v0.9.23: +4 px extra breathing room between GEAR WEAR's trailing
    -- line and the table's column header. Previously 12 felt cramped
    -- against the hairline/column labels.
    -- v1.4.5: reanchored to `yAvg` (the new trailing row in the
    -- unified 4-row stat sheet — previously `yLow` under the v1.4.4
    -- two-column layout). Same 18 px breath preserved.
    local TBL_HEADER_Y       = yAvg - 18

    local hdrWName = rW - PCT_W - COST_W - STATUS_W - GUTTER
    local hdrSlot = makeLabel("ARTWORK", "GameFontNormalSmall", rxL, TBL_HEADER_Y, hdrWName, "LEFT",  UI_GOLD_R * 0.90, UI_GOLD_G * 0.82, 0.40)
    hdrSlot:SetText("Slot / Item")
    local hdrPct  = makeLabel("ARTWORK", "GameFontNormalSmall", rxR - STATUS_W - COST_W - PCT_W - 6, TBL_HEADER_Y, PCT_W, "RIGHT", UI_GOLD_R * 0.90, UI_GOLD_G * 0.82, 0.40)
    hdrPct:SetText("Dur.")
    local hdrCost = makeLabel("ARTWORK", "GameFontNormalSmall", rxR - STATUS_W - COST_W - 2, TBL_HEADER_Y, COST_W, "RIGHT", UI_GOLD_R * 0.90, UI_GOLD_G * 0.82, 0.40)
    hdrCost:SetText("Repair")
    local hdrAlert = makeLabel("ARTWORK", "GameFontNormalSmall", rxR - STATUS_W, TBL_HEADER_Y, STATUS_W, "CENTER", UI_GOLD_R * 0.90, UI_GOLD_G * 0.82, 0.40)
    hdrAlert:SetText("Alert")

    local hdrLine = f:CreateTexture(nil, "ARTWORK")
    hdrLine:SetTexture("Interface\\Buttons\\WHITE8x8")
    hdrLine:SetVertexColor(EDGE_GOLD_R, EDGE_GOLD_G, EDGE_GOLD_B, 0.20)
    hdrLine:SetPoint("TOPLEFT",  rxL, TBL_HEADER_Y - 14)
    hdrLine:SetPoint("TOPRIGHT", f, "TOPRIGHT", -RIGHT_INSET_R, TBL_HEADER_Y - 14)
    hdrLine:SetHeight(1)

    -- v0.9.26: the previous offset of -16 placed row 1's top just 1 px
    -- below the header hairline (`hdrLine` sits at TBL_HEADER_Y - 14,
    -- 1 px thick — i.e. its bottom is at TBL_HEADER_Y - 15). With only
    -- a 1 px gap, row 1's alert chip (3 px margin inside a 20 px row)
    -- effectively landed 4 px below the hairline, visually cramming the
    -- chip's top edge against the divider and reading as "top of the
    -- alert badge is clipped". Pushing first row to TBL_HEADER_Y - 20
    -- opens the gap from 1 → 5 px between hairline and row edge, and
    -- from 4 → 8 px between hairline and chip top.
    local TBL_FIRST_ROW_Y = TBL_HEADER_Y - 20
    local MAX_ROWS = 11  -- 8 armor + MainHand + OffHand + Ranged, upper bound
    local rowWidgets = {}
    local nameRightPad = PCT_W + COST_W + STATUS_W + GUTTER + 4
    local NAME_CELL_W  = rW - (ICON_W + ICON_GAP) - nameRightPad

    -- Proper ellipsis fit: try full + optional dim suffix; if too wide, drop
    -- the suffix; if still too wide, binary-shrink `full` and append an
    -- ellipsis. Uses GetStringWidth so color escapes don't distort sizing.
    local ELLIPSIS = "\226\128\166"   -- utf-8 …
    local function fitToWidth(fs, full, coloredSuffix, maxW)
        full = full or ""
        coloredSuffix = coloredSuffix or ""
        fs:SetText(full .. coloredSuffix)
        if fs:GetStringWidth() <= maxW then return end
        fs:SetText(full)
        if fs:GetStringWidth() <= maxW then return end
        local lo, hi = 1, string.len(full)
        while lo < hi do
            local mid = math.floor((lo + hi + 1) / 2)
            fs:SetText(string.sub(full, 1, mid) .. ELLIPSIS)
            if fs:GetStringWidth() <= maxW then lo = mid else hi = mid - 1 end
        end
        fs:SetText(string.sub(full, 1, lo) .. ELLIPSIS)
    end

    for i = 1, MAX_ROWS do
        local row = CreateFrame("Button", nil, f)
        row:SetPoint("TOPLEFT",  rxL, TBL_FIRST_ROW_Y - (i - 1) * (ROW_H + ROW_GAP))
        row:SetPoint("TOPRIGHT", f, "TOPRIGHT", -RIGHT_INSET_R, TBL_FIRST_ROW_Y - (i - 1) * (ROW_H + ROW_GAP))
        row:SetHeight(ROW_H)
        row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        row:EnableMouse(true)

        -- Subtle alt-row tint gives the eye a scan rhythm without adding
        -- chrome. Matches the merchant/bank frame zebra cadence used by
        -- the base client, just dimmer to sit behind the dialog tile.
        local zebra = row:CreateTexture(nil, "BACKGROUND")
        zebra:SetAllPoints()
        zebra:SetTexture("Interface\\Buttons\\WHITE8x8")
        if (i % 2) == 0 then
            zebra:SetVertexColor(1.00, 0.96, 0.86, 0.045)
        else
            zebra:SetVertexColor(0, 0, 0, 0)
        end

        local hover = row:CreateTexture(nil, "HIGHLIGHT")
        hover:SetAllPoints()
        hover:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
        hover:SetBlendMode("ADD")
        hover:SetVertexColor(1, 1, 1, 0.35)

        local iconBg = row:CreateTexture(nil, "BACKGROUND")
        iconBg:SetPoint("LEFT", 0, 0)
        iconBg:SetSize(ICON_W, ICON_W)
        iconBg:SetTexture("Interface\\PaperDoll\\UI-Backpack-EmptySlot")

        local iconTex = row:CreateTexture(nil, "ARTWORK")
        iconTex:SetAllPoints(iconBg)
        iconTex:SetTexCoord(0.08, 0.92, 0.08, 0.92)

        -- Item name is the primary value in each row, so promote it to the
        -- brighter highlight font; slot label rides along as a dim suffix.
        local nameText = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        nameText:SetPoint("LEFT",  iconBg, "RIGHT",  ICON_GAP, 0)
        nameText:SetPoint("RIGHT", row,    "RIGHT", -nameRightPad, 0)
        nameText:SetJustifyH("LEFT")
        nameText:SetWordWrap(false)

        local pctText = row:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        pctText:SetPoint("RIGHT", row, "RIGHT", -(STATUS_W + COST_W + 6), 0)
        pctText:SetWidth(PCT_W)
        pctText:SetJustifyH("RIGHT")

        local costText = row:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        costText:SetPoint("RIGHT", row, "RIGHT", -(STATUS_W + 4), 0)
        costText:SetWidth(COST_W)
        costText:SetJustifyH("RIGHT")

        -- Alert chip: conditional marker for non-OK rows only. Hidden entirely
        -- on Healthy so the right column stays quiet and Worn/Critical rows
        -- read as actual warnings instead of a repeating label.
        --
        -- v0.9.28: previous versions built the chip from a BG fill plus four
        -- separate 1-px edge textures anchored to each side. That looked
        -- correct at native UI scale but was fundamentally fragile — WoW
        -- scales textures linearly, so a 1-px edge at a fractional UI scale
        -- (e.g. 0.80, or non-integer DPI scaling) renders as sub-pixel alpha
        -- and can effectively disappear on the top and/or bottom rows. That
        -- is exactly the "top or bottom edge of the chip is missing"
        -- symptom: the edge is still there in theory, but at the user's
        -- scale it's blended into the row background and the eye reads it
        -- as clipping. Earlier geometric fixes (adjusting row padding,
        -- chip height, chip margin) didn't help because the root cause
        -- isn't geometry — it's sub-pixel rendering of hairline textures.
        --
        -- The robust fix is to stop relying on hairlines. We layer two
        -- full-alpha rectangles: `alertEdge` fills the chip (this is the
        -- border color) and `alertBg` is inset 2 px on every side (this is
        -- the interior fill). The "border" is simply the 2-px margin of
        -- `alertEdge` that remains visible around `alertBg`. Because both
        -- textures are full rectangles at full opacity, neither can
        -- sub-pixel away at any UI scale — the border is guaranteed to
        -- render at ≥ 1 screen pixel on any reasonable display. Chip
        -- height bumps to `ROW_H - 4` (16 px) so the 2-px border plus
        -- 10-px label text have 2 px of internal breathing room, and
        -- the chip keeps a 2-px margin from the row's top and bottom.
        local alert = CreateFrame("Frame", nil, row)
        alert:SetSize(STATUS_W - 6, ROW_H - 4)
        alert:SetPoint("RIGHT", row, "RIGHT", -2, 0)

        local alertEdge = alert:CreateTexture(nil, "BACKGROUND")
        alertEdge:SetAllPoints()
        alertEdge:SetTexture("Interface\\Buttons\\WHITE8x8")
        alertEdge:SetVertexColor(EDGE_GOLD_R, EDGE_GOLD_G, EDGE_GOLD_B, 1.0)

        local alertBg = alert:CreateTexture(nil, "BACKGROUND", nil, 1)
        alertBg:SetPoint("TOPLEFT",     alert, "TOPLEFT",      2, -2)
        alertBg:SetPoint("BOTTOMRIGHT", alert, "BOTTOMRIGHT", -2,  2)
        alertBg:SetTexture("Interface\\Buttons\\WHITE8x8")
        alertBg:SetVertexColor(0.06, 0.05, 0.04, 1.0)

        local alertLbl = alert:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        alertLbl:SetPoint("CENTER", alert, "CENTER", 0, 0)
        alertLbl:SetJustifyH("CENTER")
        alertLbl:SetText("")

        alert:Hide()

        row:SetScript("OnEnter", function(self)
            if self.slotId and GetInventoryItemLink("player", self.slotId) then
                GameTooltip:SetOwner(self, "ANCHOR_LEFT")
                GameTooltip:SetInventoryItem("player", self.slotId)
                GameTooltip:Show()
            end
        end)
        row:SetScript("OnLeave", function() GameTooltip:Hide() end)
        row:SetScript("OnClick", function(self, button)
            local link = self.slotId and GetInventoryItemLink("player", self.slotId)
            if not link then return end
            -- Right-click or shift-click: insert link to the active chat
            -- edit box, or open a new one pre-filled with the link.
            local wantLink = (button == "RightButton") or (IsShiftKeyDown and IsShiftKeyDown())
            if wantLink then
                local box = ChatEdit_GetActiveWindow and ChatEdit_GetActiveWindow()
                if box and ChatEdit_InsertLink then
                    ChatEdit_InsertLink(link)
                elseif ChatFrame_OpenChat then
                    ChatFrame_OpenChat(link)
                end
            end
        end)

        row:Hide()
        rowWidgets[i] = {
            frame      = row,
            iconTex    = iconTex,
            nameText   = nameText,
            pctText    = pctText,
            costText   = costText,
            alert      = alert,
            alertBg    = alertBg,
            alertEdge  = alertEdge,
            alertLbl   = alertLbl,
        }
    end

    -- Shown when the player has nothing equipped with durability (fresh
    -- reroll, corpse run, etc.). Replaces the row list so the table area
    -- never reads as broken when empty.
    local emptyText = f:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    emptyText:SetPoint("TOPLEFT",  rxL, TBL_FIRST_ROW_Y - 4)
    emptyText:SetPoint("TOPRIGHT", f, "TOPRIGHT", -RIGHT_INSET_R, TBL_FIRST_ROW_Y - 4)
    emptyText:SetJustifyH("CENTER")
    emptyText:SetText("No equipped gear with durability.")
    emptyText:SetTextColor(0.55, 0.55, 0.58)
    emptyText:Hide()

    -- ==================== FOOTER BUTTONS ====================
    -- Footer midline: (FOOTER_H - buttonH) / 2 = (28 - 24) / 2 = 2 for
    -- buttons, and matched at y=9 for GameFontDisableSmall so the button
    -- centers and the version text baseline share the strip's midline.
    --
    -- v0.9.20: the mid-strip row-interaction hint was removed. At the
    -- current window width the hint overlapped "Find Nearest Vendor" and
    -- read as cut-off garbage ("-click: link..."). Row-click behaviors
    -- (right-click to link, shift-click to compare) are already surfaced
    -- via the per-row tooltip, so the hint was redundant chrome competing
    -- with the buttons. The footer now reads as a clean two-pole bar:
    -- action buttons on the left, version tag on the right.
    local BTN_Y   = 2
    local TEXT_Y  = 9

    local repairBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    repairBtn:SetSize(120, 24)
    repairBtn:SetPoint("BOTTOMLEFT", OUT_INSET + 10, BTN_Y)
    repairBtn:SetText("Repair All")

    local findBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    findBtn:SetSize(160, 24)
    findBtn:SetPoint("BOTTOMLEFT", repairBtn, "BOTTOMRIGHT", 10, 0)
    findBtn:SetText("Find Nearest Vendor")

    local versionText = f:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    versionText:SetPoint("BOTTOMRIGHT", -OUT_INSET - 10, TEXT_Y)
    versionText:SetText("v" .. ((GetAddOnMetadata and GetAddOnMetadata(addonName, "Version")) or "1.0.0"))
    versionText:SetTextColor(0.45, 0.45, 0.50)

    -- ==================== REFRESH ====================
    -- Rebuilds the summary + rows from live inventory state. Idempotent;
    -- safe to call from multiple event sources (inventory change, money
    -- change, merchant open/close, UPDATE_INVENTORY_DURABILITY, and the
    -- Advanced tab's refresher chain via preview3D.refresh).
    local function refresh()
        local g2y = cfgNum("threshG2Y", 75)
        local y2r = cfgNum("threshY2R", 40)
        local cr1, cg1, cb1 = cfgColor("colorHigh", GREEN_R,  GREEN_G,  GREEN_B)
        local cr2, cg2, cb2 = cfgColor("colorMid",  YELLOW_R, YELLOW_G, YELLOW_B)
        local cr3, cg3, cb3 = cfgColor("colorLow",  RED_R,    RED_G,    RED_B)

        local function hexRgb(r, g, b)
            return string.format("%02x%02x%02x",
                math.floor(r * 255 + 0.5),
                math.floor(g * 255 + 0.5),
                math.floor(b * 255 + 0.5))
        end

        -- Durability-bearing slots only. Accessories and utility slots
        -- don't wear, so they'd never have a repair cost and would just
        -- clutter the list.
        local rows = {}
        local totalCost, critCt, wornCt, okCt = 0, 0, 0, 0
        local pctSum, pctCount = 0, 0

        for _, s in ipairs(SLOTS) do
            local cur, max = GetInventoryItemDurability(s.id)
            local link     = GetInventoryItemLink("player", s.id)
            if link and cur and max and max > 0 then
                local p    = math.floor(cur / max * 100 + 0.5)
                local cost = estimateSlotRepairCost(s.id) or 0
                local br, bg, bb
                if p >= g2y then
                    okCt = okCt + 1;     br, bg, bb = cr1, cg1, cb1
                elseif p >= y2r then
                    wornCt = wornCt + 1; br, bg, bb = cr2, cg2, cb2
                else
                    critCt = critCt + 1; br, bg, bb = cr3, cg3, cb3
                end
                totalCost = totalCost + cost
                pctSum    = pctSum + p
                pctCount  = pctCount + 1
                local itemName = (GetItemInfo and GetItemInfo(link)) or s.label
                table.insert(rows, {
                    slotId   = s.id,
                    label    = s.label,
                    itemName = itemName,
                    pct      = p,
                    cost     = cost,
                    icon     = GetInventoryItemTexture and GetInventoryItemTexture("player", s.id),
                    br = br, bg = bg, bb = bb,
                })
            end
        end

        -- Worst first: matches what the user actually cares about when
        -- they open the window ("which of my items is about to break?").
        table.sort(rows, function(a, b) return a.pct < b.pct end)

        local function truncItemName(s, maxLen)
            if not s or s == "" then return "" end
            maxLen = maxLen or 34
            if string.len(s) <= maxLen then return s end
            return string.sub(s, 1, maxLen - 1) .. "…"
        end

        local needRepairCt = 0
        for _, r in ipairs(rows) do
            if r.pct < 100 then needRepairCt = needRepairCt + 1 end
        end

        -- Headline condition from worst band (matches bar thresholds).
        local condStr, cR, cG, cB
        if critCt > 0 then
            condStr, cR, cG, cB = "Critical", cr3, cg3, cb3
        elseif wornCt > 0 then
            condStr, cR, cG, cB = "Worn", cr2, cg2, cb2
        elseif needRepairCt > 0 then
            condStr, cR, cG, cB = "Needs repair", 0.95, 0.82, 0.48
        else
            condStr, cR, cG, cB = "Excellent", cr1, cg1, cb1
        end
        conditionText:SetText(condStr)
        conditionText:SetTextColor(cR, cG, cB)

        -- v1.4.5: GEAR WEAR is now a 4-row stat sheet (see build-time
        -- comment block above `yNeed`). Labels (lblNeeds, lblLowest,
        -- lblStatus, lblAvg) are static prose pinned at rxL; we only
        -- write values here. Right-aligned values land at rxR via
        -- VALUE_RIGHT_OFFSET, so no label prefixes in the strings.
        if pctCount == 0 then
            valNeeds:SetText("\226\128\148")
            valLowest:SetText("\226\128\148")
        else
            valNeeds:SetText(string.format(
                "%d item%s", needRepairCt, needRepairCt == 1 and "" or "s"))
            local wst = rows[1]
            -- Budget raised 26 -> 30. The value column now runs the
            -- full right rail (label col is only LABEL_COL_W = 108),
            -- so a few more glyphs fit before crowding the right
            -- edge. Longer names still truncate gracefully.
            valLowest:SetText(string.format(
                "%s — %d%%",
                truncItemName(wst.itemName or wst.label, 30),
                wst.pct))
        end

        -- Summary card: total repair cost + gold on hand + afford glyph.
        -- Zero-state (totalCost == 0) used to render a dim "none", which
        -- read like missing data. It now renders "No repair needed" in a
        -- muted green — a positive status on the same line instead of a
        -- negation of the label. Font shrinks to GameFontNormal so the
        -- phrase fits inside the same right-aligned column as the big
        -- money value; it returns to GameFontNormalLarge when there is a
        -- real cost to display.
        if totalCost > 0 then
            valTotal:SetFontObject("GameFontNormalLarge")
            valTotal:SetText(formatMoney(totalCost) or "0c")
            valTotal:SetTextColor(1, 1, 1)
        else
            valTotal:SetFontObject("GameFontNormal")
            valTotal:SetText("No repair needed")
            valTotal:SetTextColor(0.58, 0.84, 0.58)
        end

        -- v0.9.24: money amount and afford badge populate two different
        -- fontstrings. `valGold` holds only the money so it lands flush at
        -- rxR alongside `valTotal`; `valGoldStatus` carries the OK / short
        -- glyph in the label-to-value gutter.
        local onHand = (GetMoney and GetMoney()) or 0
        local goldStr = formatMoney(onHand) or "0c"
        valGold:SetText(goldStr)
        if totalCost > 0 then
            if onHand >= totalCost then
                valGoldStatus:SetText("|cff00ff88OK|r")
            else
                local short = totalCost - onHand
                valGoldStatus:SetText("|cffff5555short " .. (formatMoney(short) or "") .. "|r")
            end
        else
            valGoldStatus:SetText("")
        end

        valStatus:SetText(string.format(
            "|cff%sCritical %d|r   |cff%sWorn %d|r   |cff%sOK %d|r",
            hexRgb(cr3, cg3, cb3), critCt,
            hexRgb(cr2, cg2, cb2), wornCt,
            hexRgb(cr1, cg1, cb1), okCt))

        if pctCount > 0 then
            valAvg:SetText(string.format("%d%%", math.floor(pctSum / pctCount + 0.5)))
        else
            valAvg:SetText("\226\128\148")
        end

        -- Populate the row pool in sorted order.
        for i = 1, MAX_ROWS do
            local w = rowWidgets[i]
            local d = rows[i]
            if d then
                w.frame.slotId = d.slotId
                if d.icon then
                    w.iconTex:SetTexture(d.icon)
                    w.iconTex:Show()
                else
                    w.iconTex:Hide()
                end
                -- Primary: item name (bright). Trailing dim slot label when
                -- the item is known and differs from the slot label itself.
                local nameFull, nameSuffix
                if d.itemName and d.itemName ~= "" and d.itemName ~= d.label then
                    nameFull   = d.itemName
                    nameSuffix = "  |cff808080\194\183 " .. d.label .. "|r"
                else
                    nameFull   = d.label
                    nameSuffix = ""
                end
                fitToWidth(w.nameText, nameFull, nameSuffix, NAME_CELL_W)
                w.pctText:SetText(string.format("%d%%", d.pct))
                w.pctText:SetTextColor(d.br, d.bg, d.bb)
                if d.cost > 0 then
                    w.costText:SetText(formatMoney(d.cost) or "0c")
                else
                    w.costText:SetText("|cff888888-|r")
                end

                if d.pct < y2r then
                    -- v0.9.28: both chip states now drive two textures
                    -- instead of one fill + four edges. `alertEdge` is the
                    -- border color (fills the chip rectangle); `alertBg`
                    -- is the interior fill (inset 2 px on every side). The
                    -- visible "border" is just the 2-px margin of
                    -- `alertEdge` peeking out. Both are full-opacity
                    -- rectangles so neither can sub-pixel away at any UI
                    -- scale — that's what caused the "top/bottom edge is
                    -- missing" perception on row 1 and the last row.
                    --
                    -- Crit chip: bright red interior + warm amber border.
                    -- Contrast between fill hue (red) and border hue
                    -- (amber) guarantees the border reads as an actual
                    -- frame, not as a lighter band of the fill.
                    w.alertBg:SetVertexColor(cr3 * 0.45, cg3 * 0.08, cb3 * 0.08, 1.00)
                    w.alertEdge:SetVertexColor(1.00, 0.62, 0.22, 1.00)
                    w.alertLbl:SetText("!! Crit")
                    w.alertLbl:SetTextColor(1.00, 0.88, 0.80)
                    w.alert:Show()
                elseif d.pct < g2y then
                    -- Worn chip: dim amber interior + bright gold border.
                    w.alertBg:SetVertexColor(cr2 * 0.28, cg2 * 0.20, cb2 * 0.06, 1.00)
                    w.alertEdge:SetVertexColor(cr2, cg2 * 0.78, cb2 * 0.30, 1.00)
                    w.alertLbl:SetText("!  Worn")
                    w.alertLbl:SetTextColor(1.00, 0.92, 0.74)
                    w.alert:Show()
                else
                    w.alert:Hide()
                end
                w.frame:Show()
            else
                w.frame.slotId = nil
                w.frame:Hide()
            end
        end

        if #rows == 0 then emptyText:Show() else emptyText:Hide() end

        -- Footer buttons: enable only when the action is meaningful.
        if (CanMerchantRepair and CanMerchantRepair()) and totalCost > 0 then
            repairBtn:Enable()
        else
            repairBtn:Disable()
        end

        local vendor = getNearestRepairVendor()
        if vendor then
            findBtn:Enable()
            findBtn.vendor = vendor
        else
            findBtn:Disable()
            findBtn.vendor = nil
        end
    end
    f.refresh = refresh

    -- ==================== BUTTON ACTIONS ====================
    repairBtn:SetScript("OnClick", function()
        if not (CanMerchantRepair and CanMerchantRepair()) then return end
        local cost, can = GetRepairAllCost()
        if not (can and cost and cost > 0) then
            print("|cffffd200SlotStatus|r nothing to repair.")
            return
        end
        local useGuild = false
        if SlotStatusDB and SlotStatusDB.autoRepairGuild
            and IsInGuild and IsInGuild()
            and CanGuildBankRepair and CanGuildBankRepair()
            and GetGuildBankWithdrawMoney and GetGuildBankWithdrawMoney() >= cost then
            useGuild = true
        end
        RepairAllItems(useGuild)
        recordRepairEvent(cost)
        print(string.format("|cffffd200SlotStatus|r repaired all for %s%s",
            formatMoney(cost) or "0",
            useGuild and " |cff00ff88(guild funds)|r" or ""))
        refresh()
    end)

    findBtn:SetScript("OnClick", function(self)
        local v = self.vendor or getNearestRepairVendor()
        if not v then
            print("|cffffd200SlotStatus|r no known repair vendor in "
                .. (GetZoneText() or "this zone") .. ".")
            return
        end
        print(string.format(
            "|cffffd200SlotStatus|r nearest repair: |cffffffff%s|r \226\128\148 %s%s (%.1f, %.1f)",
            v.name, v.zone or "?",
            v.subzone and (" \226\128\148 " .. v.subzone) or "",
            v.x or 0, v.y or 0))
        if ToggleWorldMap and WorldMapFrame and not WorldMapFrame:IsShown() then
            pcall(ToggleWorldMap)
        end
    end)

    -- Footer tooltips explain why a disabled button is disabled rather
    -- than leaving the user wondering.
    repairBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine("Repair All", 1, 0.82, 0)
        if self:IsEnabled() then
            GameTooltip:AddLine("Costs the total shown above.", 0.8, 0.8, 0.8, true)
            if SlotStatusDB and SlotStatusDB.autoRepairGuild then
                GameTooltip:AddLine("Guild bank funds will be used first when available.",
                    0.7, 0.85, 0.7, true)
            end
        else
            GameTooltip:AddLine("Available while interacting with a repair merchant.",
                0.8, 0.8, 0.8, true)
        end
        GameTooltip:Show()
    end)
    repairBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    findBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine("Find Nearest Vendor", 1, 0.82, 0)
        if self:IsEnabled() and self.vendor then
            GameTooltip:AddLine(self.vendor.name, 1, 1, 1)
            if self.vendor.subzone then
                GameTooltip:AddLine(self.vendor.subzone, 0.8, 0.8, 0.8)
            end
            GameTooltip:AddLine(string.format("(%.1f, %.1f)",
                self.vendor.x or 0, self.vendor.y or 0), 0.7, 0.7, 0.7)
        else
            GameTooltip:AddLine("No known repair vendor in this zone.",
                0.8, 0.8, 0.8, true)
        end
        GameTooltip:Show()
    end)
    findBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- ==================== EVENTS ====================
    f:RegisterEvent("UNIT_INVENTORY_CHANGED")
    pcall(function() f:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")    end)
    pcall(function() f:RegisterEvent("PLAYER_MONEY")                end)
    pcall(function() f:RegisterEvent("UPDATE_INVENTORY_DURABILITY") end)
    pcall(function() f:RegisterEvent("MERCHANT_SHOW")               end)
    pcall(function() f:RegisterEvent("MERCHANT_CLOSED")             end)
    f:SetScript("OnEvent", function(self, event, unit)
        if not self:IsShown() then return end
        if event == "UNIT_INVENTORY_CHANGED" and unit and unit ~= "player" then return end
        refresh()
    end)

    -- Restore saved position on show, then refresh so inventory swaps that
    -- happened while the window was hidden are picked up immediately.
    f:HookScript("OnShow", function(self)
        if SlotStatusDB and SlotStatusDB.preview3dPos then
            local p, rp, x, y = unpack(SlotStatusDB.preview3dPos)
            self:ClearAllPoints()
            self:SetPoint(p or "CENTER", UIParent, rp or "CENTER", x or 0, y or 0)
        end
        refresh()
    end)

    preview3D = f
    return f
end

-- ============================================================================
--                          v1.1.0 — WELCOME POPUP (LIVE)
-- ============================================================================
-- First-run onboarding dialog for new players. Auto-shows once per
-- character on PLAYER_LOGIN when SlotStatusDB.welcomeShown is not
-- true; see the live wiring at the bottom of the main PLAYER_LOGIN
-- handler (search for `welcomeShown`). Also reachable on demand via
-- `/ss welcome` or `/ss testwelcome` (both bypass the flag).
--
-- Design goals:
--   * Reuse the Gear Overview's visual vocabulary so the welcome frame
--     reads as a sibling dialog, not a bolt-on. Same outer bezel, same
--     title bar idiom, same hairline helper, same amber/cream tier
--     system.
--   * Small — 380 x 300. Leaves plenty of room beside Blizzard's default
--     loading-screen chatter and won't dominate a 1080p display at
--     standard UI scale.
--   * One screen, no scrolling, no tabs. A first-run dialog should
--     announce what the addon is, tell the player how to open it, and
--     get out of the way. Anything more belongs in the options panel.
--   * Content structure mirrors the Gear Overview's GROUP pattern:
--       GROUP 1 — hero headline ("WELCOME" cap + verdict-style line)
--       GROUP 2 — HOW TO OPEN (slash command)
--       GROUP 3 — WHAT YOU GET (three bullets)
--     separated by hairlines exactly the same way CONDITION / REPAIR
--     COST / GEAR WEAR are separated.
--
-- Singleton: `welcomeFrame` caches the frame after first build so
-- repeated `/ss welcome` calls just re-show the same frame (same
-- pattern as `preview3D`). Idempotent early-return at the top of the
-- function.
function showWelcomePopup()
    if welcomeFrame then
        welcomeFrame:Show()
        return welcomeFrame
    end

    -- ---------------- GEOMETRY (single source of truth) ----------------
    local W, H          = 380, 300
    local TITLE_H       = 26
    local FOOTER_H      = 28
    local CONTENT_L     = 14
    local RIGHT_INSET_R = 14
    local OUT_INSET     = 5

    local f = CreateFrame("Frame", "SlotStatusWelcomeFrame", UIParent)
    f:SetSize(W, H)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:SetFrameLevel(20)
    f:SetToplevel(true)
    f:SetMovable(true)
    f:SetClampedToScreen(true)
    f:EnableMouse(true)

    -- ESC closes — same UISpecialFrames idiom as the Gear Overview.
    do
        local wanted = "SlotStatusWelcomeFrame"
        local already = false
        for _, n in ipairs(UISpecialFrames) do
            if n == wanted then already = true; break end
        end
        if not already then
            tinsert(UISpecialFrames, wanted)
        end
    end

    -- ---- Outer chrome: tiled dialog bg + bronze hairline frame ----
    -- Values mirror build3DPreviewWindow so both frames look like they
    -- came from the same addon (because they did).
    local wBg = f:CreateTexture(nil, "BACKGROUND")
    wBg:SetPoint("TOPLEFT",     OUT_INSET, -OUT_INSET)
    wBg:SetPoint("BOTTOMRIGHT", -OUT_INSET, 0)
    wBg:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
    if wBg.SetHorizTile then wBg:SetHorizTile(true) end
    if wBg.SetVertTile  then wBg:SetVertTile(true)  end
    wBg:SetVertexColor(0.78, 0.76, 0.72, 1)

    local function outerEdge(ly, r, g, b, a)
        local t = f:CreateTexture(nil, ly)
        t:SetTexture("Interface\\Buttons\\WHITE8x8")
        t:SetVertexColor(r, g, b, a)
        return t
    end
    local oGoldT, oGoldB = 0.46, 0.36
    local eTop = outerEdge("BORDER", oGoldT, oGoldB, 0.14, 0.55)
    eTop:SetPoint("TOPLEFT",  f, "TOPLEFT",  0, 0)
    eTop:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
    eTop:SetHeight(1)
    local eBot = outerEdge("BORDER", 0.08, 0.06, 0.04, 0.75)
    eBot:SetPoint("BOTTOMLEFT",  f, "BOTTOMLEFT",  0, 0)
    eBot:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
    eBot:SetHeight(1)
    local eL = outerEdge("BORDER", 0.32, 0.24, 0.10, 0.50)
    eL:SetPoint("TOPLEFT",    f, "TOPLEFT",    0, 0)
    eL:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, 0)
    eL:SetWidth(1)
    local eR = outerEdge("BORDER", 0.32, 0.24, 0.10, 0.50)
    eR:SetPoint("TOPRIGHT",    f, "TOPRIGHT",    0, 0)
    eR:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
    eR:SetWidth(1)

    -- -------------------------- TITLE BAR --------------------------
    local tb = CreateFrame("Frame", nil, f)
    tb:SetPoint("TOPLEFT",  OUT_INSET, -OUT_INSET)
    tb:SetPoint("TOPRIGHT", -OUT_INSET, -OUT_INSET)
    tb:SetHeight(TITLE_H)
    tb:SetFrameLevel(f:GetFrameLevel() + 20)
    tb:EnableMouse(true)
    tb:RegisterForDrag("LeftButton")
    tb:SetScript("OnDragStart", function() f:StartMoving() end)
    tb:SetScript("OnDragStop",  function() f:StopMovingOrSizing() end)

    local tbBg = tb:CreateTexture(nil, "ARTWORK")
    tbBg:SetAllPoints()
    tbBg:SetTexture("Interface\\Buttons\\WHITE8x8")
    applyVerticalGradient(tbBg,
        0.06, 0.09, 0.16, 1,
        0.02, 0.04, 0.08, 1)
    local tbBot = tb:CreateTexture(nil, "ARTWORK")
    tbBot:SetPoint("BOTTOMLEFT",  tb, "BOTTOMLEFT",  0, 0)
    tbBot:SetPoint("BOTTOMRIGHT", tb, "BOTTOMRIGHT", 0, 0)
    tbBot:SetHeight(1)
    tbBot:SetTexture("Interface\\Buttons\\WHITE8x8")
    tbBot:SetVertexColor(oGoldT, oGoldB, 0.15, 0.55)

    local title = tb:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("LEFT", 10, 0)
    title:SetText("SlotStatus \226\128\148 Welcome")
    title:SetTextColor(0.96, 0.94, 0.88)

    local close = CreateFrame("Button", nil, tb, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", 4, 4)
    close:SetFrameLevel(tb:GetFrameLevel() + 2)
    close:SetScript("OnClick", function() f:Hide() end)

    -- -------------------------- FOOTER --------------------------
    local footerDiv = f:CreateTexture(nil, "ARTWORK")
    footerDiv:SetTexture("Interface\\Buttons\\WHITE8x8")
    footerDiv:SetVertexColor(EDGE_GOLD_R, EDGE_GOLD_G, EDGE_GOLD_B, 0.45)
    footerDiv:SetPoint("BOTTOMLEFT",  OUT_INSET, FOOTER_H)
    footerDiv:SetPoint("BOTTOMRIGHT", -OUT_INSET, FOOTER_H)
    footerDiv:SetHeight(1)

    -- Got it button: quieter than the main panel's red "Find Nearest
    -- Vendor" action button — this is an acknowledgment, not an
    -- action. Uses the stock UIPanelButtonTemplate in its default
    -- gray tone so it reads as "dismiss", not "go do something".
    local btnGot = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    btnGot:SetSize(90, 22)
    btnGot:SetPoint("BOTTOMRIGHT", -RIGHT_INSET_R, 3)
    btnGot:SetText("Got it")
    btnGot:SetScript("OnClick", function() f:Hide() end)

    -- ==================== CONTENT AREA ====================
    -- Content rails (rxL .. rxR) and hairline helper mirror the Gear
    -- Overview so spacing reads identically on both dialogs.
    local rxL = OUT_INSET + CONTENT_L
    local rxR = W - RIGHT_INSET_R
    local rW  = rxR - rxL

    local function makeLabel(layer, font, x, y, w, align, r, g, b)
        local fs = f:CreateFontString(nil, layer, font)
        fs:SetPoint("TOPLEFT", x, y)
        if w then fs:SetWidth(w) end
        fs:SetJustifyH(align or "LEFT")
        fs:SetFont(fs:GetFont(), select(2, fs:GetFont()))
        fs:SetTextColor(r or 1, g or 1, b or 1)
        return fs
    end

    local function makeHairline(y, alpha)
        local t = f:CreateTexture(nil, "ARTWORK")
        t:SetTexture("Interface\\Buttons\\WHITE8x8")
        t:SetVertexColor(EDGE_GOLD_R, EDGE_GOLD_G, EDGE_GOLD_B, alpha)
        t:SetPoint("TOPLEFT",  rxL, y)
        t:SetPoint("TOPRIGHT", f, "TOPRIGHT", -RIGHT_INSET_R, y)
        t:SetHeight(1)
        return t
    end

    -- Same color tiers as the Gear Overview: dim amber caps + warm
    -- cream body. Duplicated locally (rather than hoisted to file
    -- scope) to keep both functions self-contained — if you ever want
    -- to tweak just one dialog's tone, you can without tangling the
    -- other.
    local SEC_HDR_R, SEC_HDR_G, SEC_HDR_B = 0.68, 0.58, 0.30
    local ROW_LBL_R, ROW_LBL_G, ROW_LBL_B = 0.88, 0.82, 0.60
    local BODY_R,    BODY_G,    BODY_B    = 0.92, 0.90, 0.82

    -- Content y starts just below the title bar. Everything below
    -- derives from this, so nudging the whole content block up or
    -- down is a one-line change.
    local yTop = -OUT_INSET - TITLE_H - 10

    -- ==================== GROUP 1 — WELCOME HERO ====================
    -- Dim amber uppercase cap, like CONDITION / REPAIR COST / GEAR WEAR.
    local secWelcome = makeLabel("ARTWORK", "GameFontDisableSmall", rxL, yTop, rW, "CENTER", SEC_HDR_R, SEC_HDR_G, SEC_HDR_B)
    secWelcome:SetText("WELCOME")

    -- Hero verdict line, same font object as the CONDITION verdict in
    -- the Gear Overview so both "headline" moments look like family.
    local yHero = yTop - 16
    local hero = makeLabel("OVERLAY", "GameFontNormalLarge", rxL, yHero, rW, "CENTER", 0.98, 0.96, 0.82)
    hero:SetText("Gear, at a glance")

    -- Full-width hot hairline (alpha 0.55) under the verdict. Same
    -- idiom as the CONDITION underline you just dialed in.
    local heroSepY = yHero - 24
    makeHairline(heroSepY, 0.55)

    -- Body paragraph — warm cream, normal font, two lines.
    local yBody = heroSepY - 12
    local body = makeLabel("ARTWORK", "GameFontNormal", rxL, yBody, rW, "CENTER", BODY_R, BODY_G, BODY_B)
    body:SetText("Track durability, repair costs, and\nthe nearest vendor in one quick panel.")

    -- ==================== GROUP 2 — HOW TO OPEN ====================
    -- Quiet structural hairline (alpha 0.30) — the GROUP_GAP rhythm.
    local openSepY = yBody - 38
    makeHairline(openSepY, 0.30)

    local yOpenHdr = openSepY - 12
    local secOpen = makeLabel("ARTWORK", "GameFontDisableSmall", rxL, yOpenHdr, rW, "LEFT", SEC_HDR_R, SEC_HDR_G, SEC_HDR_B)
    secOpen:SetText("HOW TO OPEN")

    local yOpenLine = yOpenHdr - 16
    local openLine = makeLabel("ARTWORK", "GameFontNormal", rxL, yOpenLine, rW, "LEFT", ROW_LBL_R, ROW_LBL_G, ROW_LBL_B)
    -- Highlighted slash-commands so the eye snaps to "oh, that's what I type".
    openLine:SetText("Type  |cffffffff/ss|r  or  |cffffffff/slotstatus|r")

    -- ==================== GROUP 3 — WHAT YOU GET ====================
    local getSepY = yOpenLine - 22
    makeHairline(getSepY, 0.30)

    local yGetHdr = getSepY - 12
    local secGet = makeLabel("ARTWORK", "GameFontDisableSmall", rxL, yGetHdr, rW, "LEFT", SEC_HDR_R, SEC_HDR_G, SEC_HDR_B)
    secGet:SetText("WHAT YOU GET")

    -- Bullets — small amber dot + cream body, one line each.
    local BULLET_GAP = 15
    local function makeBullet(y, text)
        local dot = makeLabel("ARTWORK", "GameFontNormal", rxL, y, 10, "LEFT", SEC_HDR_R + 0.1, SEC_HDR_G + 0.1, SEC_HDR_B)
        dot:SetText("\226\128\162") -- • bullet
        local line = makeLabel("ARTWORK", "GameFontNormal", rxL + 14, y, rW - 14, "LEFT", ROW_LBL_R, ROW_LBL_G, ROW_LBL_B)
        line:SetText(text)
    end
    makeBullet(yGetHdr - 16,                 "Live durability for every slot")
    makeBullet(yGetHdr - 16 - BULLET_GAP,    "Per-slot repair cost + gold check")
    makeBullet(yGetHdr - 16 - BULLET_GAP*2,  "One-click repair & vendor finder")

    -- ==================== AUTO-SHOW (LIVE) ====================
    -- v1.1.0: auto-show on first login is LIVE. Implementation lives
    -- in the main PLAYER_LOGIN handler near the bottom of this file
    -- (search for `welcomeShown`). Flow, end to end:
    --
    --   1. Character finishes loading → PLAYER_LOGIN fires.
    --   2. Main handler runs its usual init (initDefaults, slash
    --      commands, map pins, minimap button, slot bars).
    --   3. If `SlotStatusDB.welcomeShown` ~= true, schedule a
    --      2-second-delayed call to this function. The delay keeps
    --      the popup from landing on top of Blizzard's loading
    --      messages and our own "loaded" print.
    --   4. Popup appears centered on screen; player dismisses via
    --      [X], [Got it], or Escape.
    --   5. `SlotStatusDB.welcomeShown = true` is written regardless
    --      of whether the show succeeded — we never want to re-spam
    --      the player on every login if something went wrong once.
    --
    -- Re-openable anytime with `/ss welcome` (ignores the flag), so
    -- a player who dismissed it too quickly can get it back.

    welcomeFrame = f
    return f
end

-- ===================== LEGACY PREVIEW CODE REMOVED (v0.8.9) ===================
-- Everything below up to the next "===" banner is intentionally left empty;
-- the old paper-doll preview + scrubber lived here and was replaced by the
-- dashboard above. Kept as a marker so anyone git-blaming this file can see
-- a clean transition point.
do
    -- placeholder so the banner above doesn't dangle
end

-- ========================== (old removed content) ==========================
--[[
    -- Three compact color chips on one row, so the user always knows what
    -- the current Healthy/Worn/Critical colors look like even when all
    -- visible gear happens to fall in the same band. Small and slim so the
    -- model remains the focal point.
    local legendBars = {} -- {bar, key, fr, fg, fb}
    local LEGEND_Y          = -34
    local LEGEND_BAR_W      = 72
    local LEGEND_BAR_H      = 8
    local LEGEND_LABEL_W    = 56
    local LEGEND_CHIP_W     = LEGEND_LABEL_W + 4 + LEGEND_BAR_W  -- 132
    local LEGEND_CHIP_GAP   = 16
    local LEGEND_TOTAL_W    = 3 * LEGEND_CHIP_W + 2 * LEGEND_CHIP_GAP  -- 428
    local LEGEND_START_X    = (W - LEGEND_TOTAL_W) / 2  -- 66

    local legendDefs = {
        { label = "Healthy",  key = "colorHigh", fr = GREEN_R,  fg = GREEN_G,  fb = GREEN_B  },
        { label = "Worn",     key = "colorMid",  fr = YELLOW_R, fg = YELLOW_G, fb = YELLOW_B },
        { label = "Critical", key = "colorLow",  fr = RED_R,    fg = RED_G,    fb = RED_B    },
    }
    for i, info in ipairs(legendDefs) do
        local chipX = LEGEND_START_X + (i - 1) * (LEGEND_CHIP_W + LEGEND_CHIP_GAP)
        local lbl = f:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        lbl:SetPoint("TOPLEFT", chipX, LEGEND_Y)
        lbl:SetWidth(LEGEND_LABEL_W)
        lbl:SetJustifyH("LEFT")
        lbl:SetText(info.label)
        lbl:SetTextColor(0.82, 0.78, 0.55)

        local bar = CreateFrame("StatusBar", nil, f)
        bar:SetPoint("TOPLEFT", chipX + LEGEND_LABEL_W + 4, LEGEND_Y - 3)
        bar:SetSize(LEGEND_BAR_W, LEGEND_BAR_H)
        bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
        bar:SetMinMaxValues(0, 1)
        bar:SetValue(1)

        local bBg = bar:CreateTexture(nil, "BACKGROUND")
        bBg:SetAllPoints()
        bBg:SetTexture("Interface\\Buttons\\WHITE8x8")
        bBg:SetVertexColor(0.06, 0.06, 0.08, 1)

        local bEdge = bar:CreateTexture(nil, "BORDER")
        bEdge:SetPoint("TOPLEFT",     -1,  1)
        bEdge:SetPoint("BOTTOMRIGHT",  1, -1)
        bEdge:SetTexture("Interface\\Buttons\\WHITE8x8")
        bEdge:SetVertexColor(UI_GOLD_R * 0.55, UI_GOLD_G * 0.45, 0.1, 0.5)
        bEdge:SetDrawLayer("BORDER", -1)

        table.insert(legendBars, {bar = bar, key = info.key, fr = info.fr, fg = info.fg, fb = info.fb})
    end

    -- Divider under the legend.
    local divider = f:CreateTexture(nil, "ARTWORK")
    divider:SetPoint("TOPLEFT",  14, -56)
    divider:SetPoint("TOPRIGHT", -14, -56)
    divider:SetHeight(1)
    divider:SetTexture("Interface\\Buttons\\WHITE8x8")
    divider:SetVertexColor(UI_GOLD_R * 0.45, UI_GOLD_G * 0.35, 0.1, 0.6)

    -- -------------------------- 3D MODEL --------------------------
    -- A soft dark vignette behind the model only. Keeps the model reading
    -- as the visual anchor without making the whole window look busy.
    local modelBg = f:CreateTexture(nil, "BACKGROUND", nil, 2)
    modelBg:SetPoint("TOP", f, "TOP", 0, MODEL_TOP_Y)
    modelBg:SetSize(MODEL_W + 12, MODEL_H + 12)
    modelBg:SetTexture("Interface\\Buttons\\WHITE8x8")
    modelBg:SetVertexColor(0.02, 0.02, 0.03, 1)

    local modelEdge = f:CreateTexture(nil, "BACKGROUND", nil, 3)
    modelEdge:SetPoint("TOPLEFT",     modelBg, "TOPLEFT",     -1,  1)
    modelEdge:SetPoint("BOTTOMRIGHT", modelBg, "BOTTOMRIGHT",  1, -1)
    modelEdge:SetTexture("Interface\\Buttons\\WHITE8x8")
    modelEdge:SetVertexColor(UI_GOLD_R * 0.55, UI_GOLD_G * 0.45, 0.1, 0.5)

    -- DressUpModel is the right pick: it auto-equips the player's current
    -- gear (so swapping a weapon in-game and reopening the preview Just
    -- Works). It's been available on every Classic/TBC build, so we use
    -- it directly -- no fallback needed at interface 20505.
    local model = CreateFrame("DressUpModel", "SlotStatus3DPreviewModel", f)
    model:SetPoint("TOP", f, "TOP", 0, MODEL_TOP_Y)
    model:SetSize(MODEL_W, MODEL_H)
    model:SetFrameLevel(f:GetFrameLevel() + 2)
    model:EnableMouse(true)
    model:EnableMouseWheel(true)

    -- Lightweight drag-to-rotate. When the user holds left button on the
    -- model and drags horizontally, we rotate it. Feels like the Classic
    -- dress-up frame does when you grab the character.
    local rotating, lastX
    model:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            rotating = true
            lastX = GetCursorPosition()
        end
    end)
    model:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" then rotating = false end
    end)
    model:SetScript("OnUpdate", function(self)
        if rotating then
            local x = GetCursorPosition()
            if lastX then
                local dx = x - lastX
                local f0 = (self.GetFacing and self:GetFacing()) or 0
                if self.SetFacing then self:SetFacing(f0 + dx * 0.015) end
            end
            lastX = x
        end
    end)
    -- Mouse-wheel zoom (Classic paper doll trick).
    model:SetScript("OnMouseWheel", function(self, delta)
        if self.GetModelScale and self.SetModelScale then
            local s = self:GetModelScale() or 1
            s = math.max(0.5, math.min(2.5, s + delta * 0.1))
            self:SetModelScale(s)
        end
    end)

    -- Helper: (re)load the player into the model and zero its camera. We
    -- guard every optional API with its own existence check because the
    -- 3D widget surface area differs subtly between Classic and TBC builds.
    local function reloadModel()
        if model.SetAutoDress    then model:SetAutoDress(true)   end
        if model.SetUnit         then model:SetUnit("player")    end
        if model.Dress           then model:Dress()              end
        if model.SetPortraitZoom then model:SetPortraitZoom(0)   end
        if model.SetPosition     then model:SetPosition(0, 0, 0) end
        if model.SetFacing       then model:SetFacing(0.4)       end
        if model.SetModelScale   then model:SetModelScale(1)     end
    end

    -- Gear changes at runtime: reload so the model re-dresses. In TBC
    -- Classic the main equipment event is UNIT_INVENTORY_CHANGED; some
    -- builds also fire PLAYER_EQUIPMENT_CHANGED. Register both defensively
    -- (pcall the second one in case a given build doesn't publish it).
    f:RegisterEvent("UNIT_INVENTORY_CHANGED")
    pcall(function() f:RegisterEvent("PLAYER_EQUIPMENT_CHANGED") end)
    f:SetScript("OnEvent", function(self, event, unit)
        if not self:IsShown() then return end
        if event == "UNIT_INVENTORY_CHANGED" and unit ~= "player" then return end
        reloadModel()
        if self.refresh then self.refresh() end
    end)

    -- -------------------------- SLOT TILES --------------------------
    -- Shared factory. `info` must have {id, col, row, category, label,
    -- slotArt}. Returns the refresh handle (iconTex/iconEmpty/bar/etc.).
    --
    -- Bar orientation follows the real bars:
    --   armor / accessory / utility -> vertical bar on the OUTER edge
    --   weapon                      -> horizontal bar UNDER the icon
    local gearTiles = {}
    local function makePreviewSlot(info)
        -- ---- icon button ----
        local iconBtn = CreateFrame("Button", nil, f)
        iconBtn:SetSize(SLOT_SIZE, SLOT_SIZE)
        iconBtn:SetFrameLevel(f:GetFrameLevel() + 4)
        iconBtn:EnableMouse(true)

        -- Every slot anchors to the 3D model frame so the character itself
        -- is the one and only alignment reference. This guarantees the
        -- paper-doll is symmetric about the model's vertical axis -- no
        -- window-edge arithmetic, no chance for the weapon row to drift
        -- off-centre when the window (or model) moves or resizes.
        --
        --   col "L" -> icon TOPRIGHT pinned off model's TOPLEFT   (grows down)
        --   col "R" -> icon TOPLEFT  pinned off model's TOPRIGHT  (grows down)
        --   col "B" -> icon TOP      pinned off model's BOTTOM    (x=0 is centre)
        --
        -- The anchor corner differs per column on purpose: pinning each
        -- icon's OUTER corner lets the vertical bar (left of L, right of R)
        -- naturally grow away from the character without needing extra
        -- offsets, and pinning weapon icons by their TOP centre puts
        -- row-1 exactly under the model's centre and rows 0/2 a symmetric
        -- step to either side.
        iconBtn:ClearAllPoints()
        if info.col == "L" then
            iconBtn:SetPoint("TOPRIGHT", model, "TOPLEFT",
                -COL_GAP_X, COL_OFFSET_Y - info.row * SLOT_ROW_STEP)
        elseif info.col == "R" then
            iconBtn:SetPoint("TOPLEFT", model, "TOPRIGHT",
                COL_GAP_X, COL_OFFSET_Y - info.row * SLOT_ROW_STEP)
        else  -- "B" = weapon row, centred beneath the model
            iconBtn:SetPoint("TOP", model, "BOTTOM",
                (info.row - 1) * (SLOT_SIZE + WEAPON_GAP), -WEAPON_VGAP)
        end

        -- Gold border (slightly brighter on hover).
        local border = iconBtn:CreateTexture(nil, "BACKGROUND")
        border:SetPoint("TOPLEFT",     -1,  1)
        border:SetPoint("BOTTOMRIGHT",  1, -1)
        border:SetTexture("Interface\\Buttons\\WHITE8x8")
        border:SetVertexColor(UI_GOLD_R * 0.75, UI_GOLD_G * 0.6, 0.1, 0.85)

        local inset = iconBtn:CreateTexture(nil, "BORDER")
        inset:SetAllPoints()
        inset:SetTexture("Interface\\Buttons\\WHITE8x8")
        inset:SetVertexColor(0.04, 0.04, 0.06, 1)

        -- Blizzard empty-slot placeholder. Shows through when unequipped
        -- so the window never looks like a grid of blank boxes.
        local iconEmpty = iconBtn:CreateTexture(nil, "ARTWORK")
        iconEmpty:SetAllPoints()
        iconEmpty:SetTexture(info.slotArt)
        iconEmpty:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        iconEmpty:SetVertexColor(0.5, 0.5, 0.55)

        -- Equipped-item icon. When present, overlays the placeholder.
        local iconTex = iconBtn:CreateTexture(nil, "ARTWORK", nil, 1)
        iconTex:SetAllPoints()
        iconTex:SetTexCoord(0.08, 0.92, 0.08, 0.92)

        local hover = iconBtn:CreateTexture(nil, "HIGHLIGHT")
        hover:SetAllPoints()
        hover:SetTexture("Interface\\Buttons\\WHITE8x8")
        hover:SetVertexColor(1, 1, 1, 0.08)

        -- ---- durability bar ----
        -- The bar pulls its thickness from the SAME config the real bars
        -- use, so the preview visually matches the live character sheet.
        local bar = CreateFrame("StatusBar", nil, iconBtn)
        bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
        bar:SetMinMaxValues(0, 1)
        bar:SetValue(1)
        bar:SetFrameLevel(iconBtn:GetFrameLevel() + 1)

        local barBg = bar:CreateTexture(nil, "BACKGROUND")
        barBg:SetAllPoints()
        barBg:SetTexture("Interface\\Buttons\\WHITE8x8")
        barBg:SetVertexColor(0.04, 0.04, 0.06, 0.9)

        if info.category == "weapon" then
            bar:SetOrientation("HORIZONTAL")
            bar:ClearAllPoints()
            bar:SetPoint("TOPLEFT",  iconBtn, "BOTTOMLEFT",  0, -2)
            bar:SetPoint("TOPRIGHT", iconBtn, "BOTTOMRIGHT", 0, -2)
            bar:SetHeight(WEAPON_BAR_H)
        else
            bar:SetOrientation("VERTICAL")
            bar:SetWidth(BAR_THICK)
            bar:SetHeight(SLOT_SIZE)
            bar:ClearAllPoints()
            if info.col == "L" then
                -- Left column: bar on LEFT (outer) edge of the icon.
                bar:SetPoint("TOPRIGHT",    iconBtn, "TOPLEFT", -2, 0)
                bar:SetPoint("BOTTOMRIGHT", iconBtn, "BOTTOMLEFT", -2, 0)
            else
                -- Right column: bar on RIGHT (outer) edge.
                bar:SetPoint("TOPLEFT",    iconBtn, "TOPRIGHT", 2, 0)
                bar:SetPoint("BOTTOMLEFT", iconBtn, "BOTTOMRIGHT", 2, 0)
            end
        end

        -- Slot tooltip on hover: item link (when equipped) or slot name.
        iconBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            if GetInventoryItemLink and GetInventoryItemLink("player", info.id) then
                GameTooltip:SetInventoryItem("player", info.id)
            else
                GameTooltip:AddLine(info.label, 1, 0.82, 0)
                GameTooltip:AddLine("Empty", 0.7, 0.7, 0.7)
            end
            -- Durability line (only when real durability is available).
            if GetInventoryItemDurability then
                local cur, max = GetInventoryItemDurability(info.id)
                if cur and max and max > 0 then
                    GameTooltip:AddLine(string.format(
                        "Durability: %d / %d (%d%%)", cur, max, math.floor(cur / max * 100 + 0.5)),
                        1, 1, 1)
                end
            end
            GameTooltip:Show()
            border:SetVertexColor(UI_GOLD_R, UI_GOLD_G, 0.2, 1)
        end)
        iconBtn:SetScript("OnLeave", function()
            GameTooltip:Hide()
            border:SetVertexColor(UI_GOLD_R * 0.75, UI_GOLD_G * 0.6, 0.1, 0.85)
        end)

        return {
            slotId    = info.id,
            category  = info.category,
            iconBtn   = iconBtn,
            iconTex   = iconTex,
            iconEmpty = iconEmpty,
            bar       = bar,
        }
    end

    for _, info in ipairs(PREVIEW_LAYOUT) do
        table.insert(gearTiles, makePreviewSlot(info))
    end

    -- -------------------------- FOOTER: READOUT + SCRUBBER --------------------------
    local scrubberReadout = f:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    scrubberReadout:SetPoint("BOTTOM", 0, 52)
    scrubberReadout:SetText("All gear at 75%  \226\128\148  Worn")

    local scrubber = CreateFrame("Slider", "SlotStatus3DPreviewScrubber", f, "OptionsSliderTemplate")
    scrubber:SetWidth(360)
    scrubber:SetPoint("BOTTOM", 0, 22)
    scrubber:SetMinMaxValues(0, 100)
    scrubber:SetValueStep(1)
    scrubber:SetObeyStepOnDrag(true)
    _G[scrubber:GetName() .. "Low"]:SetText("0%")
    _G[scrubber:GetName() .. "High"]:SetText("100%")
    _G[scrubber:GetName() .. "Low"]:SetTextColor(0.55, 0.55, 0.58)
    _G[scrubber:GetName() .. "High"]:SetTextColor(0.55, 0.55, 0.58)
    _G[scrubber:GetName() .. "Text"]:SetText("")

    local function readPct() return cfgNum("previewPct", 75) end
    local function labelForPct(p)
        local g2y = cfgNum("threshG2Y", 75)
        local y2r = cfgNum("threshY2R", 40)
        if p >= g2y then return "Healthy",  "colorHigh", GREEN_R,  GREEN_G,  GREEN_B end
        if p >= y2r then return "Worn",     "colorMid",  YELLOW_R, YELLOW_G, YELLOW_B end
        return                  "Critical", "colorLow",  RED_R,    RED_G,    RED_B
    end

    -- -------------------------- REFRESH --------------------------
    -- Idempotent: safe to call as often as needed. Pulls every visible
    -- piece of state from SlotStatusDB + the scrubber + the player's
    -- current inventory, so any external change (color picker tweak,
    -- threshold slider, newly-equipped item) is correctly reflected.
    local function refresh()
        local alphaMult = cfgNum("barAlphaMult", 1.0)

        -- 1. Legend chips reflect current color choices.
        for _, r in ipairs(legendBars) do
            local cr, cg, cb = cfgColor(r.key, r.fr, r.fg, r.fb)
            r.bar:SetStatusBarColor(cr, cg, cb)
            r.bar:SetAlpha(math.max(0.5, alphaMult))
        end

        -- 2. Per-slot: swap the icon to the equipped item (or leave the
        --    placeholder showing), set bar fill to the scrubber %, tint
        --    to the matching band via the SAME function the live bars
        --    use, and hide the bar for slots that lack durability so the
        --    preview doesn't lie about accessory slots.
        local p = readPct()
        for _, t in ipairs(gearTiles) do
            local tex = GetInventoryItemTexture and GetInventoryItemTexture("player", t.slotId)
            if tex then
                t.iconTex:SetTexture(tex)
                t.iconTex:Show()
            else
                t.iconTex:Hide()
            end

            -- Real bars only exist when the slot has durability. For the
            -- preview we still WANT to show the bar even on slots that
            -- COULD have durability (so color tweaks are visible on every
            -- bar category); but rings/trinkets never do, so we dim their
            -- bar bg and skip the fill to communicate "no durability".
            local hasDura = false
            if GetInventoryItemDurability then
                local cur, max = GetInventoryItemDurability(t.slotId)
                hasDura = (cur and max and max > 0)
            end

            if t.category == "accessory" and not hasDura then
                t.bar:SetValue(0)
                t.bar:SetAlpha(0.15)
            else
                t.bar:SetValue(p / 100)
                t.bar:SetAlpha(math.max(0.3, 0.9 * alphaMult))
                setDurabilityColor(t.bar, p)
            end
        end

        -- 3. Footer readout tinted with the matching band's color.
        local labelName, colorKey, fr, fg, fb = labelForPct(p)
        local cr, cg, cb = cfgColor(colorKey, fr, fg, fb)
        scrubberReadout:SetText(string.format("All gear at %d%%  \226\128\148  %s", p, labelName))
        scrubberReadout:SetTextColor(cr, cg, cb)
    end
    f.refresh = refresh

    scrubber:SetScript("OnValueChanged", function(_, v)
        v = math.floor(v + 0.5)
        if SlotStatusDB then SlotStatusDB.previewPct = v end
        refresh()
    end)

    -- Restore saved window position on show, reload the 3D model, refresh
    -- all slots. OnShow runs every time the preview opens, so if the user
    -- equipped new items while the window was closed, we'll pick them up.
    f:HookScript("OnShow", function(self)
        if SlotStatusDB and SlotStatusDB.preview3dPos then
            local p, rp, x, y = unpack(SlotStatusDB.preview3dPos)
            self:ClearAllPoints()
            self:SetPoint(p or "CENTER", UIParent, rp or "CENTER", x or 0, y or 0)
        end
        reloadModel()
        scrubber:SetValue(readPct())
        refresh()
    end)

]]
-- ====================== MAIN OPTIONS PANEL (tabbed) ======================
local function buildOptionsPanel()
    local panel = CreateFrame("Frame", "SlotStatusOptionsPanel", UIParent)
    panel.name = "SlotStatus"

    -- v0.8.0: warm-neutral vertical gradient. Subtle lift from top to
    -- bottom so the panel reads as a lit card, not a painted rectangle.
    -- Values in PANEL_BG_{TOP,BOT}_* (AtlasLoot-inspired).
    local bg = panel:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture("Interface\\Buttons\\WHITE8x8")
    applyVerticalGradient(bg,
        PANEL_BG_TOP_R, PANEL_BG_TOP_G, PANEL_BG_TOP_B, PANEL_BG_TOP_A,
        PANEL_BG_BOT_R, PANEL_BG_BOT_G, PANEL_BG_BOT_B, PANEL_BG_BOT_A)

    -- Warm gradient band behind the header for that "quest log" feel
    -- Glow band ends EXACTLY at the gold divider so there's no 4px overshoot
    -- below the line. Small thing, but it was the kind of tiny misalignment
    -- that makes a panel read as "prototype" instead of "polished".
    -- v0.6.4: header height trimmed (88 -> 74) so the branding block takes
    -- ~15% less vertical space. Content now gets more of the panel.
    -- v0.8.0: gradient glow -- warm amber band that fades to near-nothing
    -- before the divider, so the title area has depth without shouting.
    local headerGlow = panel:CreateTexture(nil, "BACKGROUND", nil, 1)
    headerGlow:SetPoint("TOPLEFT", 0, 0)
    headerGlow:SetPoint("TOPRIGHT", 0, 0)
    headerGlow:SetHeight(74)
    headerGlow:SetTexture("Interface\\Buttons\\WHITE8x8")
    applyVerticalGradient(headerGlow,
        0.18, 0.14, 0.05, 0.55,
        0.05, 0.04, 0.02, 0.20)

    -- Logo / icon block: we draw a gold-bordered square. Inside it we put
    -- a fallback hammer icon (BACKGROUND layer) and then a custom logo on
    -- top (ARTWORK layer). If "logo.tga" is saved in the addon folder, the
    -- custom texture will load and cover the hammer. Otherwise the hammer
    -- shows through. Either way, nothing breaks.
    local LOGO_SIZE = 54
    local iconBorder = panel:CreateTexture(nil, "ARTWORK", nil, 0)
    iconBorder:SetSize(LOGO_SIZE, LOGO_SIZE)
    iconBorder:SetPoint("TOPLEFT", 14, -10)
    iconBorder:SetTexture("Interface\\Buttons\\WHITE8x8")
    iconBorder:SetVertexColor(UI_GOLD_R, UI_GOLD_G, UI_GOLD_B, 1)

    local iconBg = panel:CreateTexture(nil, "ARTWORK", nil, 1)
    iconBg:SetPoint("TOPLEFT", iconBorder, "TOPLEFT", 2, -2)
    iconBg:SetPoint("BOTTOMRIGHT", iconBorder, "BOTTOMRIGHT", -2, 2)
    iconBg:SetTexture("Interface\\Buttons\\WHITE8x8")
    iconBg:SetVertexColor(0, 0, 0, 1)

    -- Fallback hammer icon (drawn first, covered by custom logo if present)
    local fallback = panel:CreateTexture(nil, "ARTWORK", nil, 2)
    fallback:SetPoint("TOPLEFT", iconBorder, "TOPLEFT", 4, -4)
    fallback:SetPoint("BOTTOMRIGHT", iconBorder, "BOTTOMRIGHT", -4, 4)
    fallback:SetTexture("Interface\\ICONS\\INV_Hammer_16")
    fallback:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    -- Custom logo. If logo.tga isn't present in the addon folder, this
    -- texture simply renders as nothing (transparent) and the hammer below
    -- is visible instead.
    local logo = panel:CreateTexture(nil, "ARTWORK", nil, 3)
    logo:SetPoint("TOPLEFT", iconBorder, "TOPLEFT", 2, -2)
    logo:SetPoint("BOTTOMRIGHT", iconBorder, "BOTTOMRIGHT", -2, 2)
    logo:SetTexture("Interface\\AddOns\\SlotStatus\\logo")

    -- Title & subtitle -- tighter vertical stack now that the header
    -- glow is 14px shorter. Version is rendered on the same line as the
    -- subtitle (right-aligned to the logo edge) to save a whole line.
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", iconBorder, "TOPRIGHT", 12, -2)
    title:SetText("SlotStatus")
    title:SetTextColor(UI_GOLD_R, UI_GOLD_G, UI_GOLD_B)

    local version = panel:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    version:SetPoint("LEFT", title, "RIGHT", 8, 0)
    version:SetText("v" .. ((GetAddOnMetadata and GetAddOnMetadata(addonName, "Version")) or "1.0.0"))
    version:SetTextColor(0.55, 0.45, 0.15)

    local sub = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 1, -3)
    sub:SetText("Durability bars \194\183 repair estimates \194\183 auto-vendor QoL")
    sub:SetTextColor(0.72, 0.72, 0.74)

    -- v0.8.0: 1px hairline divider (down from 2px) with a soft gradient
    -- glow above/below. Reads as a defined line without dominating.
    local hdrLine = panel:CreateTexture(nil, "ARTWORK")
    hdrLine:SetTexture("Interface\\Buttons\\WHITE8x8")
    hdrLine:SetVertexColor(EDGE_GOLD_R, EDGE_GOLD_G, EDGE_GOLD_B, 0.75)
    hdrLine:SetPoint("TOPLEFT", 16, -74)
    hdrLine:SetPoint("TOPRIGHT", -16, -74)
    hdrLine:SetHeight(1)

    local hdrLineGlow = panel:CreateTexture(nil, "ARTWORK", nil, -1)
    hdrLineGlow:SetTexture("Interface\\Buttons\\WHITE8x8")
    hdrLineGlow:SetPoint("TOPLEFT", hdrLine, "TOPLEFT", 0, 2)
    hdrLineGlow:SetPoint("BOTTOMRIGHT", hdrLine, "BOTTOMRIGHT", 0, -2)
    applyVerticalGradient(hdrLineGlow,
        EDGE_GOLD_R, EDGE_GOLD_G, EDGE_GOLD_B, 0.18,
        EDGE_GOLD_R, EDGE_GOLD_G, EDGE_GOLD_B, 0.02)

    -- ============ TAB BAR ============
    -- Pulled up 14px to track the shorter header (glow -> 74, divider -> -74).
    local TAB_TOP = -86
    local tabBar = CreateFrame("Frame", nil, panel)
    tabBar:SetPoint("TOPLEFT",  16, TAB_TOP)
    tabBar:SetPoint("TOPRIGHT", -16, TAB_TOP)
    tabBar:SetHeight(26)

    local tabButtons = {}
    local tabFrames  = {}
    local activeTab  = 1

    local function selectTab(idx)
        for i = 1, #tabButtons do
            local btn = tabButtons[i]
            if i == idx then
                btn.bg:SetVertexColor(0.25, 0.19, 0.06, 0.95)
                btn.text:SetTextColor(UI_GOLD_R, UI_GOLD_G, UI_GOLD_B)
                btn.underline:Show()
                tabFrames[i]:Show()
                if tabFrames[i].refresh then tabFrames[i].refresh() end
            else
                btn.bg:SetVertexColor(0.06, 0.06, 0.09, 0.85)
                btn.text:SetTextColor(0.68, 0.68, 0.68)
                btn.underline:Hide()
                tabFrames[i]:Hide()
            end
        end
        activeTab = idx
    end
    panel.selectTab = selectTab  -- exposed so /ss advanced can pick tab 3

    local function makeTab(idx, label)
        local btnW = 108
        local btn = CreateFrame("Button", nil, tabBar)
        btn:SetSize(btnW, 24)
        btn:SetPoint("TOPLEFT", (idx - 1) * (btnW + 4), 0)

        btn.bg = btn:CreateTexture(nil, "BACKGROUND")
        btn.bg:SetAllPoints()
        btn.bg:SetTexture("Interface\\Buttons\\WHITE8x8")

        local brd = btn:CreateTexture(nil, "BORDER")
        brd:SetPoint("TOPLEFT", -1, 1)
        brd:SetPoint("BOTTOMRIGHT", 1, -1)
        brd:SetTexture("Interface\\Buttons\\WHITE8x8")
        brd:SetVertexColor(UI_GOLD_R, UI_GOLD_G, UI_GOLD_B, 0.45)
        brd:SetDrawLayer("BACKGROUND", -1)

        btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        btn.text:SetPoint("CENTER")
        btn.text:SetText(label)

        btn.underline = btn:CreateTexture(nil, "OVERLAY")
        btn.underline:SetTexture("Interface\\Buttons\\WHITE8x8")
        btn.underline:SetVertexColor(UI_GOLD_R, UI_GOLD_G, UI_GOLD_B, 1.0)
        btn.underline:SetPoint("BOTTOMLEFT", 3, -2)
        btn.underline:SetPoint("BOTTOMRIGHT", -3, -2)
        btn.underline:SetHeight(2)

        btn:SetScript("OnClick", function() selectTab(idx) end)
        btn:SetScript("OnEnter", function(self)
            if activeTab ~= idx then
                self.bg:SetVertexColor(0.15, 0.14, 0.18, 0.95)
            end
        end)
        btn:SetScript("OnLeave", function(self)
            if activeTab ~= idx then
                self.bg:SetVertexColor(0.06, 0.06, 0.09, 0.85)
            end
        end)

        tabButtons[idx] = btn

        local content = CreateFrame("Frame", nil, panel)
        content:SetPoint("TOPLEFT", tabBar, "BOTTOMLEFT", 0, -8)
        content:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -16, 40)
        content:Hide()

        -- v0.8.0: warm-neutral gradient card with softer gold edge.
        local cbg = content:CreateTexture(nil, "BACKGROUND")
        cbg:SetAllPoints()
        cbg:SetTexture("Interface\\Buttons\\WHITE8x8")
        applyVerticalGradient(cbg,
            TAB_BG_TOP_R, TAB_BG_TOP_G, TAB_BG_TOP_B, TAB_BG_TOP_A,
            TAB_BG_BOT_R, TAB_BG_BOT_G, TAB_BG_BOT_B, TAB_BG_BOT_A)

        local cbd = content:CreateTexture(nil, "BORDER")
        cbd:SetPoint("TOPLEFT", -1, 1)
        cbd:SetPoint("BOTTOMRIGHT", 1, -1)
        cbd:SetTexture("Interface\\Buttons\\WHITE8x8")
        cbd:SetVertexColor(EDGE_GOLD_R, EDGE_GOLD_G, EDGE_GOLD_B, 0.35)
        cbd:SetDrawLayer("BACKGROUND", -1)

        tabFrames[idx] = content
        return content
    end

    -- ============ TAB 1: GENERAL ============
    -- Three grouped subsections -- Display, Repair & Vendor, Developer --
    -- instead of a flat 6-checkbox list. Uses the same rhythm constants as
    -- the Advanced tab so the two tabs read as the same product.
    local gTab = makeTab(1, "General")
    do
        -- Rhythm: pulled from the Advanced tab so both tabs read as the
        -- same product. HEADER_TO_BODY is 18 (not 22 like Advanced) because
        -- checkboxes already include ~4px of top padding inside their
        -- template; matching 22 would leave the first row feeling marooned.
        local HEADER_TO_BODY = 18
        local ROW_GAP        = 22   -- between sibling checkboxes
        local SECTION_GAP    = 22   -- between grouped subsections
        local LEFT_X         = 20

        -- Start 20px below the tab bar's bottom edge so the "Display"
        -- header clears the tab buttons comfortably instead of hugging
        -- the top seam.
        local y = -20

        -- Section header underline width is 300 (not the full 552) so the
        -- General tab's rhythm matches the Advanced tab's column-scoped
        -- underlines. Keeps the two tabs reading as the same product.
        local HEADER_UNDERLINE_W = 300

        -- --- Display -------------------------------------------------------
        makeSectionHeader(gTab, "Display", y, LEFT_X, HEADER_UNDERLINE_W)
        y = y - HEADER_TO_BODY
        makeCheckbox(gTab, "Show durability bars on character frame",
            "Toggle the thin vertical durability indicators next to each equipped slot.",
            function() return SlotStatusDB and (SlotStatusDB.showBars ~= false) end,
            function(v) SlotStatusDB.showBars = v; updateBars() end, y)
        y = y - ROW_GAP
        makeCheckbox(gTab, "Show world-map vendor pins",
            "Display gold hammer icons on the world map for repair vendors.",
            function() return SlotStatusDB and (SlotStatusDB.mapPins ~= false) end,
            function(v) SlotStatusDB.mapPins = v; updateMapPins() end, y)
        y = y - ROW_GAP - SECTION_GAP

        -- --- Repair & Vendor -----------------------------------------------
        makeSectionHeader(gTab, "Repair & Vendor", y, LEFT_X, HEADER_UNDERLINE_W)
        y = y - HEADER_TO_BODY
        makeCheckbox(gTab, "Auto-repair at vendor",
            "Automatically Repair All when you open a repair vendor.",
            function() return SlotStatusDB and SlotStatusDB.autoRepair end,
            function(v) SlotStatusDB.autoRepair = v end, y)
        y = y - ROW_GAP
        makeCheckbox(gTab, "Use guild bank funds first (if available)",
            "Prefer guild bank money over personal gold when repairing.",
            function() return SlotStatusDB and SlotStatusDB.autoRepairGuild end,
            function(v) SlotStatusDB.autoRepairGuild = v end, y, 20)
        y = y - ROW_GAP
        makeCheckbox(gTab, "Auto-sell gray (Poor) items",
            "On vendor open, sell all Poor-quality items in your bags.",
            function() return SlotStatusDB and SlotStatusDB.autoSell end,
            function(v) SlotStatusDB.autoSell = v end, y)
        y = y - ROW_GAP - SECTION_GAP

        -- --- Developer -----------------------------------------------------
        makeSectionHeader(gTab, "Developer", y, LEFT_X, HEADER_UNDERLINE_W)
        y = y - HEADER_TO_BODY
        makeCheckbox(gTab, "Debug prints",
            "Print diagnostic messages in chat (spammy).",
            function() return SlotStatusDB and SlotStatusDB.debug end,
            function(v) SlotStatusDB.debug = v end, y)

        -- --- Footer (anchored to the tab's bottom edge) --------------------
        -- The General tab has far fewer rows than Advanced, so without a
        -- footer the lower ~45% of the panel reads as empty space. A thin
        -- amber hairline + muted pointer gives the eye a soft bottom cap
        -- without adding any interactive noise.
        local footerLine = gTab:CreateTexture(nil, "ARTWORK")
        footerLine:SetTexture("Interface\\Buttons\\WHITE8x8")
        footerLine:SetVertexColor(EDGE_GOLD_R, EDGE_GOLD_G, EDGE_GOLD_B, 0.25)
        footerLine:SetPoint("BOTTOMLEFT",  gTab, "BOTTOMLEFT",  LEFT_X,     24)
        footerLine:SetPoint("BOTTOMRIGHT", gTab, "BOTTOMRIGHT", -LEFT_X,    24)
        footerLine:SetHeight(1)

        local footerText = gTab:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
        footerText:SetPoint("BOTTOMLEFT",  gTab, "BOTTOMLEFT",  LEFT_X,   8)
        footerText:SetPoint("BOTTOMRIGHT", gTab, "BOTTOMRIGHT", -LEFT_X,  8)
        footerText:SetJustifyH("LEFT")
        footerText:SetText("Looking for colors or thresholds? See the Advanced tab.")
        footerText:SetTextColor(0.55, 0.55, 0.58)
    end

    -- ============ TAB 2: WARNINGS ============
    local wTab = makeTab(2, "Warnings")
    do
        local y = -14
        makeCheckbox(wTab, "Low-durability warnings",
            "Print a chat message when a slot drops below the threshold.",
            function() return SlotStatusDB and currentWarnMode() ~= "off" end,
            function(v) SlotStatusDB.warnMode = v and "full" or "off" end, y)
        y = y - 22
        local fullCb = makeCheckbox(wTab, "Play sound + flash the slot bar",
            "When a slot crosses the threshold, also play a soft alert and pulse the bar.",
            function() return SlotStatusDB and currentWarnMode() == "full" end,
            function(v)
                if currentWarnMode() == "off" then return end
                SlotStatusDB.warnMode = v and "full" or "chat"
            end, y, 20)

        -- Small "Test" trigger beside the checkbox. Plays the same alert
        -- sound and flashes the lowest-durability equipped bar (fallback:
        -- all tracked bars) so the user can verify the effect without
        -- actually dropping a slot below the threshold. Runs independent
        -- of the checkbox state -- it's a one-shot preview, not a toggle.
        local testBtn = CreateFrame("Button", nil, wTab, "UIPanelButtonTemplate")
        testBtn:SetSize(52, 20)
        testBtn:SetPoint("LEFT", fullCb.Text, "RIGHT", 10, 0)
        testBtn:SetText("Test")
        local tbFont = testBtn:GetFontString()
        if tbFont then tbFont:SetTextColor(0.95, 0.88, 0.55) end
        testBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("Preview alert")
            GameTooltip:AddLine(
                "Plays the warning sound and pulses the lowest-durability bar.",
                0.9, 0.9, 0.9, true)
            GameTooltip:Show()
        end)
        testBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        testBtn:SetScript("OnClick", function()
            if PlaySound then pcall(PlaySound, 847) end
            -- Find the worst-durability tracked slot.
            local worstId, worstPct = nil, 101
            for _, s in ipairs(SLOTS) do
                local cur, max = GetInventoryItemDurability(s.id)
                if cur and max and max > 0 then
                    local p = (cur / max) * 100
                    if p < worstPct then worstPct, worstId = p, s.id end
                end
            end
            if worstId and bars[worstId] then
                flashBar(bars[worstId], 1.2)
            else
                -- No durability data yet (e.g. character unequipped or
                -- tooltip cache cold). Flash every tracked bar so the
                -- user still sees the effect.
                for _, s in ipairs(SLOTS) do
                    if bars[s.id] then flashBar(bars[s.id], 1.0) end
                end
            end
        end)
        y = y - 22
        makeCheckbox(wTab, "Warn at combat start if any slot is critical",
            "When you enter combat, print one warning if any slot is below the combat threshold.",
            function() return SlotStatusDB and SlotStatusDB.combatWarn ~= false end,
            function(v) SlotStatusDB.combatWarn = v end, y)
        y = y - 34

        local _, ny = makeLabeledSlider(wTab, "SlotStatusWarnSlider", y,
            "Warning threshold", 5, 75, 5, "warnThreshold", "%")
        y = ny
        makeLabeledSlider(wTab, "SlotStatusCombatSlider", y,
            "Pre-combat warning threshold", 10, 75, 5, "combatThresh", "%")

        wTab.refresh = function()
            if _G.SlotStatusWarnSlider   and _G.SlotStatusWarnSlider.refresh   then _G.SlotStatusWarnSlider.refresh()   end
            if _G.SlotStatusCombatSlider and _G.SlotStatusCombatSlider.refresh then _G.SlotStatusCombatSlider.refresh() end
        end
    end

    -- ============ TAB 3: ADVANCED (v0.8.0 clean 2-column grid) ============
    --
    -- Structural fix: the two columns used to share x=220. Left column
    -- swatches were 220px wide starting at x=24 -> ran to x=244. Right
    -- column headers/sliders started at x=220. The 24px collision was
    -- the "messy" feel. Now columns are strictly separated by a 32px
    -- blank gutter (left body ends at x=264, right body starts at x=304).
    --
    --   0      16 ───── LEFT COL (248w) ───── 264   296 ── RIGHT COL (248w) ── 544
    --   │      │                               │    │                          │
    --   │      LEFT_X    LEFT_BODY_X           │    RIGHT_X / RIGHT_BODY_X     │
    --   │      16        20                    │    296                        │
    --   │                                       GUTTER = 32px, never violated  │
    --
    local aTab = makeTab(3, "Advanced")
    local advRefreshers = {}
    do
        -- Forward-declared so swatch/slider callbacks can refresh the preview.
        local updatePreview

        local function onCosmeticsChanged()
            updateBars()
            if updatePreview then updatePreview() end
        end
        -- ---------- GRID (single source of truth) ----------
        -- v0.8.2: HEADER_TO_BODY bumped from 10 -> 22 so the header
        -- underline clears the first body element (GameFontNormalLarge is
        -- ~18px tall and the underline sits 3px below the baseline; at 10
        -- the swatches and slider titles were clipping the underline).
        local SECTION_START   = -14
        local HEADER_TO_BODY  = 22
        local ELEMENT_GAP     =  8
        local SECTION_GAP     = 18
        local LEFT_X          = 16
        local LEFT_BODY_X     = 20
        local LEFT_W          = 244
        local RIGHT_X         = 296
        local RIGHT_BODY_X    = 300
        local RIGHT_W         = 244

        local SWATCH_H        = 22   -- v0.8.3: matches the framed-housing row height
        local BUTTON_H        = 32   -- was 26, bumped to balance Preview vs Bar Colors

        -- ---------- unified inline slider helper ----------
        -- Single slider idiom used by BOTH Thresholds and Bar Appearance.
        -- Layout per slider (block height = 52):
        --
        --   y        <TitleText>                               <Value>
        --   y-18     [=========================O=========]
        --   y-36     min                                            max
        --   y-52     (next element lives here)
        --
        -- The OptionsSliderTemplate's built-in "<name>Text" value is blanked
        -- so the ONLY value label is the inline one at top-right -- no
        -- floating duplicates, no competing styles between sections.
        --
        -- `fmt(v)` defaults to: integer + suffix for step>=1, one decimal
        -- for 0.1<=step<1, two decimals for step<0.1. Pass a custom fmt
        -- for full control (not needed for the two current sections).
        -- v0.9.17: minimal Blizzard-style slider. The previous bronze-housed
        -- amber StatusBar read as decorative and heavy; swapped for a thin
        -- hairline track with the classic UI-SliderBar jewel thumb that
        -- hangs off the line. The title + right-aligned value and the
        -- min/max footer labels carry the quantitative read, and the jewel
        -- gives a precise at-a-glance position without any chrome.
        local function makeInlineSlider(name, y, titleText, minV, maxV, step, dbKey, suffix, onChange, fmt)
            suffix = suffix or ""
            fmt = fmt or function(v)
                if step < 0.1 then
                    return string.format("%.2f%s", v, suffix)
                elseif step < 1 then
                    return string.format("%.1f%s", v, suffix)
                else
                    return string.format("%d%s", math.floor(v + 0.5), suffix)
                end
            end

            -- ---- Row 1: title (left) + value (right) --------------------
            local title = aTab:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
            title:SetPoint("TOPLEFT", RIGHT_BODY_X, y)
            title:SetWidth(RIGHT_W)
            title:SetJustifyH("LEFT")
            title:SetText(titleText)

            local valueText = aTab:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
            valueText:SetPoint("TOPRIGHT", title, "TOPRIGHT", 0, 0)
            valueText:SetJustifyH("RIGHT")
            valueText:SetTextColor(UI_GOLD_R, UI_GOLD_G, 0.28)

            -- ---- Row 2: minimal track + jewel thumb ---------------------
            -- v0.9.17: bronze housing + amber fill swapped for a minimal
            -- Blizzard-style line + jewel thumb. The visual read is now:
            -- a thin hairline across the row with a small diamond handle
            -- hanging below the line. Cleaner, quieter, matches the rest
            -- of the panel's restrained language.
            local TRACK_H        = 12                 -- interaction hit-area height
            local TRACK_Y        = y - 22             -- baseline of the hairline
            local THUMB_W        = 16
            local THUMB_H        = 16

            -- Hit-area / Slider frame: covers the full row width so both
            -- click-on-track and drag-the-thumb work naturally.
            local slider = CreateFrame("Slider", name, aTab)
            slider:SetOrientation("HORIZONTAL")
            slider:SetSize(RIGHT_W, TRACK_H)
            slider:SetPoint("TOPLEFT", RIGHT_BODY_X, TRACK_Y)
            slider:SetMinMaxValues(minV, maxV)
            slider:SetValueStep(step)
            slider:SetObeyStepOnDrag(true)
            slider:EnableMouse(true)

            -- Thin hairline that represents the track. Anchored vertically
            -- centered on the Slider frame so the jewel thumb (which WoW
            -- centers on the track by default) sits naturally on the line.
            local trackLine = slider:CreateTexture(nil, "ARTWORK")
            trackLine:SetTexture("Interface\\Buttons\\WHITE8x8")
            trackLine:SetVertexColor(0.55, 0.47, 0.30, 0.55)
            trackLine:SetPoint("LEFT",  slider, "LEFT",  0, 0)
            trackLine:SetPoint("RIGHT", slider, "RIGHT", 0, 0)
            trackLine:SetHeight(1)

            -- Blizzard's default slider jewel. Classic ships this texture
            -- and it exactly matches the reference look (small kite/diamond
            -- hanging off the track). Using it via SetThumbTexture means
            -- the Slider frame positions it for us based on value.
            local thumbTex = slider:CreateTexture(nil, "OVERLAY")
            thumbTex:SetTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
            thumbTex:SetSize(THUMB_W, THUMB_H)
            slider:SetThumbTexture(thumbTex)

            -- ---- Row 3: min / max labels --------------------------------
            local lowText = aTab:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
            lowText:SetPoint("TOPLEFT",  slider, "BOTTOMLEFT",  0, -6)
            lowText:SetJustifyH("LEFT")
            lowText:SetTextColor(0.55, 0.55, 0.58)
            lowText:SetText(fmt(minV))

            local highText = aTab:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
            highText:SetPoint("TOPRIGHT", slider, "BOTTOMRIGHT", 0, -6)
            highText:SetJustifyH("RIGHT")
            highText:SetTextColor(0.55, 0.55, 0.58)
            highText:SetText(fmt(maxV))

            local function render(v)
                valueText:SetText(fmt(v))
            end

            slider.refresh = function()
                local v = cfgNum(dbKey, minV)
                slider:SetValue(v)
                render(v)
            end

            slider:SetScript("OnValueChanged", function(_, v)
                SlotStatusDB[dbKey] = v
                render(v)
                if onChange then onChange(v) end
            end)

            slider.refresh()
            return slider, y - 52
        end

        -- ====================== LEFT COLUMN ======================
        local yL = SECTION_START

        -- --- Bar Colors -----------------------------------------------------
        -- Two-tier grouping so the eye scans Durability (wear bands) and
        -- Category (fixed slot tints) as separate ideas. Per-row tooltips
        -- carry the "what does this actually affect" copy so the footer
        -- stays a single short line instead of a wall of text.
        makeSectionHeader(aTab, "Bar Colors", yL, LEFT_X, LEFT_W)
        yL = yL - HEADER_TO_BODY

        -- Sub-group 1: durability bands
        makeSubHeader(aTab, "Durability", yL, LEFT_BODY_X)
        yL = yL - 16

        local sw1 = makeColorSwatch(aTab, LEFT_BODY_X, yL, "Healthy",  "colorHigh", onCosmeticsChanged, LEFT_W,
            "Used when an item's durability is at or above the Warning threshold.")
        yL = yL - SWATCH_H - ELEMENT_GAP
        local sw2 = makeColorSwatch(aTab, LEFT_BODY_X, yL, "Worn",     "colorMid",  onCosmeticsChanged, LEFT_W,
            "Used when durability falls below the Warning threshold.")
        yL = yL - SWATCH_H - ELEMENT_GAP
        local sw3 = makeColorSwatch(aTab, LEFT_BODY_X, yL, "Critical", "colorLow",  onCosmeticsChanged, LEFT_W,
            "Used when durability falls below the Critical threshold.")
        yL = yL - SWATCH_H

        -- Divider between the two sub-groups
        yL = yL - 10
        makeHairline(aTab, yL, LEFT_BODY_X, LEFT_W)
        yL = yL - 10

        -- Sub-group 2: non-durability category tints
        makeSubHeader(aTab, "Category", yL, LEFT_BODY_X)
        yL = yL - 16

        local sw4 = makeColorSwatch(aTab, LEFT_BODY_X, yL, "Accessory", "colorAccessory", onCosmeticsChanged, LEFT_W,
            "Tints slots without durability: neck, rings, trinkets, cloak, and off-hand shields / held items.")
        yL = yL - SWATCH_H - ELEMENT_GAP
        local sw5 = makeColorSwatch(aTab, LEFT_BODY_X, yL, "Utility",   "colorUtility",   onCosmeticsChanged, LEFT_W,
            "Tints shirt and tabard.")
        yL = yL - SWATCH_H
        table.insert(advRefreshers, sw1.refresh)
        table.insert(advRefreshers, sw2.refresh)
        table.insert(advRefreshers, sw3.refresh)
        table.insert(advRefreshers, sw4.refresh)
        table.insert(advRefreshers, sw5.refresh)

        local colorsHint = aTab:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
        colorsHint:SetPoint("TOPLEFT",  LEFT_BODY_X, yL - ELEMENT_GAP)
        colorsHint:SetPoint("TOPRIGHT", LEFT_BODY_X + LEFT_W, yL - ELEMENT_GAP)
        colorsHint:SetJustifyH("LEFT")
        colorsHint:SetText("Click a bar to change its color. Hover for details.")
        colorsHint:SetTextColor(0.55, 0.55, 0.58)
        yL = yL - ELEMENT_GAP - 14 - SECTION_GAP

        -- --- Preview --------------------------------------------------------
        makeSectionHeader(aTab, "Preview", yL, LEFT_X, LEFT_W)
        yL = yL - HEADER_TO_BODY

        local openPreviewBtn = CreateFrame("Button", nil, aTab, "UIPanelButtonTemplate")
        openPreviewBtn:SetSize(LEFT_W, BUTTON_H)
        openPreviewBtn:SetPoint("TOPLEFT", LEFT_BODY_X, yL)
        openPreviewBtn:SetText("Open gear & repair overview")
        local opFont = openPreviewBtn:GetFontString()
        if opFont then opFont:SetTextColor(0.95, 0.88, 0.55) end
        openPreviewBtn:SetScript("OnClick", function()
            local w = build3DPreviewWindow()
            if w:IsShown() then w:Hide() else w:Show() end
        end)
        yL = yL - BUTTON_H - ELEMENT_GAP

        -- Two-line hint balances the Preview block against Bar Colors'
        -- 3-swatch stack in the left column.
        local previewHint = aTab:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
        previewHint:SetPoint("TOPLEFT",  LEFT_BODY_X, yL)
        previewHint:SetPoint("TOPRIGHT", LEFT_BODY_X + LEFT_W, yL)
        previewHint:SetJustifyH("LEFT")
        previewHint:SetJustifyV("TOP")
        previewHint:SetText("Single-screen repair cockpit: total cost, per-slot\nbreakdown, Repair All, and Find Nearest Vendor.")
        previewHint:SetTextColor(0.55, 0.55, 0.58)

        updatePreview = function()
            if preview3D and preview3D:IsShown() and preview3D.refresh then
                preview3D.refresh()
            end
        end
        table.insert(advRefreshers, updatePreview)

        -- ====================== RIGHT COLUMN ======================
        local yR = SECTION_START

        -- --- Thresholds -----------------------------------------------------
        makeSectionHeader(aTab, "Thresholds", yR, RIGHT_X, RIGHT_W)
        yR = yR - HEADER_TO_BODY

        -- Two coupled sliders. Warning (G->Y) must always stay >= Critical
        -- (Y->R) + 5; we enforce it silently on change. The "stays above"
        -- hint below the pair tells the user why the other slider moves.
        local sG2Y, sY2R
        sG2Y, yR = makeInlineSlider("SlotStatusAdvG2Y", yR,
            "Warning starts below", 30, 95, 5, "threshG2Y", "%",
            function(v)
                if sY2R and cfgNum("threshY2R", 40) >= v then
                    local nv = math.max(5, v - 5)
                    SlotStatusDB.threshY2R = nv
                    sY2R:SetValue(nv)
                end
                onCosmeticsChanged()
            end)

        yR = yR - ELEMENT_GAP

        sY2R, yR = makeInlineSlider("SlotStatusAdvY2R", yR,
            "Critical starts below", 5, 60, 5, "threshY2R", "%",
            function(v)
                if sG2Y and cfgNum("threshG2Y", 75) <= v then
                    local nv = math.min(95, v + 5)
                    SlotStatusDB.threshG2Y = nv
                    sG2Y:SetValue(nv)
                end
                onCosmeticsChanged()
            end)

        -- Relationship hint: tells the user why the OTHER slider moves
        -- when they drag one into the other. Muted grey, small font.
        local threshHint = aTab:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
        threshHint:SetPoint("TOPLEFT", RIGHT_BODY_X, yR - ELEMENT_GAP)
        threshHint:SetText("Warning stays above Critical automatically.")
        threshHint:SetTextColor(0.55, 0.55, 0.58)
        yR = yR - ELEMENT_GAP - 14 - SECTION_GAP

        table.insert(advRefreshers, function()
            if _G.SlotStatusAdvG2Y   and _G.SlotStatusAdvG2Y.refresh   then _G.SlotStatusAdvG2Y.refresh()   end
            if _G.SlotStatusAdvY2R   and _G.SlotStatusAdvY2R.refresh   then _G.SlotStatusAdvY2R.refresh()   end
        end)

        -- --- Closing hairline + Reset (pulled INTO the right-column flow) --
        -- Previously Reset floated at the tab's BOTTOMRIGHT with ~80px of
        -- dead space above it. Now it sits 18px below the last slider,
        -- visually capped by a soft amber hairline. Feels intentional, not
        -- orphaned.
        yR = yR - SECTION_GAP

        local closeLine = aTab:CreateTexture(nil, "ARTWORK")
        closeLine:SetTexture("Interface\\Buttons\\WHITE8x8")
        closeLine:SetVertexColor(EDGE_GOLD_R, EDGE_GOLD_G, EDGE_GOLD_B, 0.30)
        closeLine:SetPoint("TOPLEFT", RIGHT_BODY_X, yR)
        closeLine:SetSize(RIGHT_W, 1)
        yR = yR - ELEMENT_GAP

        local resetAdvBtn = CreateFrame("Button", nil, aTab, "UIPanelButtonTemplate")
        resetAdvBtn:SetSize(140, 22)
        resetAdvBtn:SetPoint("TOPRIGHT", aTab, "TOPLEFT", RIGHT_BODY_X + RIGHT_W, yR)
        resetAdvBtn:SetText("Reset to defaults")
        local raFont = resetAdvBtn:GetFontString()
        if raFont then raFont:SetTextColor(0.85, 0.82, 0.72) end
        resetAdvBtn:SetScript("OnClick", function()
            SlotStatusDB.colorHigh      = nil
            SlotStatusDB.colorMid       = nil
            SlotStatusDB.colorLow       = nil
            SlotStatusDB.colorAccessory = nil
            SlotStatusDB.colorUtility   = nil
            SlotStatusDB.threshG2Y      = nil
            SlotStatusDB.threshY2R      = nil
            SlotStatusDB.barAlphaMult   = nil
            SlotStatusDB.barThickness   = nil
            SlotStatusDB.barLeftOffset  = nil
            SlotStatusDB.barRightOffset = nil
            initDefaults()
            for _, fn in ipairs(advRefreshers) do pcall(fn) end
            applyBarAppearance()
            updateBars()
            print("|cffffd200SlotStatus|r advanced settings reset.")
        end)

        aTab.refresh = function()
            for _, fn in ipairs(advRefreshers) do pcall(fn) end
        end
    end

    -- ============ TAB 4: STATS ============
    -- v1.0.0 rebuild. Previously this tab was a single GameFontHighlight
    -- FontString rendering a six-line string-formatted blob with a single
    -- "Net this session" label that was actually showing lifetime totals
    -- (stats are SavedVariablesPerCharacter, so they persist across
    -- sessions -- the old label was a lie). The rewrite splits each
    -- counter into Session vs Lifetime columns, adds a small "Insights"
    -- block (avg per repair, biggest single repair, vendors discovered),
    -- and groups the rows under bronze Activity / Gold / Insights section
    -- headers so the tab reads like a designed ledger instead of a
    -- stacked debug dump.
    local sTab = makeTab(4, "Stats")
    local refreshStats
    do
        -- ---------- layout constants -----------------------------------
        -- Strict 3-column table: [label] [session] [lifetime].
        --
        -- The label column is LEFT-anchored at LABEL_X. Both numeric
        -- columns are RIGHT-anchored: each column's caption ("SESSION"
        -- / "LIFETIME") and every value beneath it share the SAME
        -- right-edge x (SESSION_X / LIFETIME_X), so a 1-char "0" and
        -- a 7-char "SESSION" line up along their trailing edge like
        -- figures in a ledger. No per-row SetPoint math, no drift
        -- based on string width, no row-specific offsets -- all three
        -- row-building call sites feed the same factory with only y
        -- changing.
        --
        -- Previous implementation centred each column on a fixed x
        -- via "TOP" + SetJustifyH("CENTER"). That worked structurally
        -- but read as loose: centring a 1-char value under a 7-char
        -- caption leaves half the caption's width as visual air on
        -- either side of the digit, so the column felt floaty instead
        -- of columnar. Right-aligning both the caption and the values
        -- to the same x gives a crisp, deliberate stack.
        local LABEL_X          = 20    -- TOPLEFT x for every row label (and section title)
        local SESSION_X        = -128  -- SESSION column CENTER x (offset from sTab TOPRIGHT); every session value is centered here
        local LIFETIME_X       = -55   -- LIFETIME column CENTER x (offset from sTab TOPRIGHT); every lifetime value is centered here
        local RIGHT_EDGE_X     = -22   -- right edge of the grid (divider right anchor)
        local ROW_Y_START      = -16   -- y of the first section title
        local ROW_HEIGHT       = 18    -- uniform row-to-row vertical stride
        local TITLE_TO_ROW     = 28    -- section title top -> first row top; used identically by all three sections (Activity, Gold, Insights)
        local TITLE_TO_CAPTION = 8     -- section title top -> column caption top (Activity only); caption visible glyphs share a baseline with the section title text to the left and sit ~2px above the hairline, so "Activity" and "SESSION"/"LIFETIME" read as one title row
        local SECTION_GAP      = 14    -- breathing room between sections

        -- ---------- section header helper -------------------------------
        -- Stats-tab-local variant of makeSectionHeader. The hairline
        -- anchors TOPLEFT at LABEL_X and TOPRIGHT at RIGHT_EDGE_X, so
        -- the divider spans the ENTIRE section block (all the way
        -- past the lifetime column).
        --
        -- xNudge: optical-alignment correction for the header text
        -- ONLY. Different capital letters have different left-side
        -- bearings at the same SetPoint x. "G" and "S" both curve in
        -- from the box edge by the same amount, so Gold's header
        -- reads aligned with its first row ("Spent on repair"). "A"
        -- has a sharp diagonal apex that starts ~2px inside the box,
        -- while "V" below it (first row "Vendor visits") starts at
        -- ~0px inside the box -- so even though both FontStrings sit
        -- at LABEL_X=20, the visible glyphs drift. xNudge shifts the
        -- header FontString only; the hairline stays anchored to
        -- LABEL_X/RIGHT_EDGE_X so the grid structure is unaffected.
        local function makeStatsHeader(yTop, text, xNudge)
            xNudge = xNudge or 0
            local fs = sTab:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
            fs:SetPoint("TOPLEFT", LABEL_X + xNudge, yTop)
            fs:SetText(text)
            fs:SetTextColor(UI_GOLD_R, UI_GOLD_G, UI_GOLD_B)

            local line = sTab:CreateTexture(nil, "OVERLAY")
            line:SetTexture("Interface\\Buttons\\WHITE8x8")
            -- 2px / alpha 0.55 reads clearly against the dark panel
            -- without shouting over the section title above it.
            line:SetVertexColor(EDGE_GOLD_R, EDGE_GOLD_G, EDGE_GOLD_B, 0.55)
            line:SetPoint("TOPLEFT",  sTab, "TOPLEFT",  LABEL_X,      yTop - 22)
            line:SetPoint("TOPRIGHT", sTab, "TOPRIGHT", RIGHT_EDGE_X, yTop - 22)
            line:SetHeight(2)
            return fs, line
        end

        -- ---------- column caption helper -------------------------------
        -- Used for Activity only. Caption's TOP-CENTER anchor is pinned
        -- to the column's centre x, so a "SESSION" caption and every
        -- "0" value below it share one vertical centre line. Caption
        -- sits in the section-title band (above the gold hairline), so
        -- it decorates the title row rather than consuming vertical
        -- space in the data-row flow.
        local function makeColumnCaption(y, centerX, text)
            local fs = sTab:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
            fs:SetPoint("TOP", sTab, "TOPRIGHT", centerX, y)
            fs:SetJustifyH("CENTER")
            fs:SetTextColor(0.55, 0.55, 0.58)
            fs:SetText(text)
            return fs
        end

        -- ---------- row factory ----------------------------------------
        -- Three fixed anchors per row: label LEFT at LABEL_X, session
        -- value CENTER at SESSION_X, lifetime value CENTER at
        -- LIFETIME_X. The only per-row input is y; column geometry is
        -- shared across every row in the tab, and the "TOP" anchor
        -- point pins each value's horizontal centre regardless of its
        -- string width.
        local function makeRow(y, labelText, lifetimeOnly)
            local lbl = sTab:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
            lbl:SetPoint("TOPLEFT", LABEL_X, y)
            lbl:SetJustifyH("LEFT")
            lbl:SetText(labelText)

            local sesVal
            if not lifetimeOnly then
                sesVal = sTab:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
                sesVal:SetPoint("TOP", sTab, "TOPRIGHT", SESSION_X, y)
                sesVal:SetJustifyH("CENTER")
                -- Muted white: session is the "fresh" column, useful
                -- but not the authoritative figure.
                sesVal:SetTextColor(0.78, 0.78, 0.80)
            end

            local lifeVal = sTab:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
            lifeVal:SetPoint("TOP", sTab, "TOPRIGHT", LIFETIME_X, y)
            lifeVal:SetJustifyH("CENTER")
            -- Soft gold: lifetime is the canonical number.
            lifeVal:SetTextColor(1.00, 0.95, 0.70)

            return lbl, sesVal, lifeVal
        end

        -- ---------- SECTION 1 · ACTIVITY -------------------------------
        -- Data-driven: one table describes the three rows, and both
        -- the builder below and refreshStats() iterate the same list.
        -- Adding/removing/renaming a row is one edit here; nothing
        -- else in this section needs to change.
        local ACTIVITY_ROWS = {
            { key = "visits",       label = "Vendor visits" },
            { key = "repair_count", label = "Repair events" },
            { key = "grays_sold",   label = "Grays sold"    },
        }
        local activityHandles = {}

        local y = ROW_Y_START
        -- xNudge = -2: compensate for "A"'s sharp-apex left-side
        -- bearing so the visible glyph aligns with the "V" of
        -- "Vendor visits" beneath it. See makeStatsHeader() comment.
        makeStatsHeader(y, "Activity", -2)

        -- SESSION / LIFETIME captions live in the title band, above
        -- the hairline, so they share the "Activity" baseline on the
        -- right side and don't push the data rows down. The rows
        -- themselves still start at TITLE_TO_ROW below the title, same
        -- as Gold and Insights.
        makeColumnCaption(y - TITLE_TO_CAPTION, SESSION_X,  "SESSION")
        makeColumnCaption(y - TITLE_TO_CAPTION, LIFETIME_X, "LIFETIME")

        y = y - TITLE_TO_ROW

        for _, row in ipairs(ACTIVITY_ROWS) do
            local _, sesVal, lifeVal = makeRow(y, row.label)
            activityHandles[row.key] = { ses = sesVal, life = lifeVal }
            y = y - ROW_HEIGHT
        end

        -- ---------- SECTION 2 · GOLD -----------------------------------
        y = y - SECTION_GAP
        makeStatsHeader(y, "Gold")
        y = y - TITLE_TO_ROW

        local _, spentSes, spentLife = makeRow(y, "Spent on repair"); y = y - ROW_HEIGHT
        local _, junkSes,  junkLife  = makeRow(y, "Gold from junk");  y = y - ROW_HEIGHT
        local _, netSes,   netLife   = makeRow(y, "Net");             y = y - ROW_HEIGHT

        -- ---------- SECTION 3 · INSIGHTS -------------------------------
        -- Lifetime-only derived stats. No session column: average-per-
        -- repair and biggest-single-repair only become interesting
        -- with a handful of data points, and "vendors discovered" is
        -- conceptually a lifetime figure.
        y = y - SECTION_GAP
        makeStatsHeader(y, "Insights")
        y = y - TITLE_TO_ROW

        local _, _, avgLife     = makeRow(y, "Avg per repair",        true); y = y - ROW_HEIGHT
        local _, _, biggestLife = makeRow(y, "Biggest single repair", true); y = y - ROW_HEIGHT
        local _, _, vendLife    = makeRow(y, "Vendors discovered",    true); y = y - ROW_HEIGHT

        -- ---------- refresh --------------------------------------------
        local function netStr(delta)
            local abs = formatMoney(math.abs(delta)) or "0c"
            if delta > 0 then
                return "|cff00ff00+" .. abs .. "|r"
            elseif delta < 0 then
                return "|cffff5555-" .. abs .. "|r"
            else
                return "|cff8888880c|r"  -- dim zero, never shout "positive"
            end
        end

        refreshStats = function()
            local s = (SlotStatusDB and SlotStatusDB.stats) or {}

            -- Activity: integer counts. Iterate the same table that
            -- built the rows, so the refresh path can never drift out
            -- of sync with the layout path.
            for _, row in ipairs(ACTIVITY_ROWS) do
                local h = activityHandles[row.key]
                h.ses:SetText(tostring(sessionValue(row.key)))
                h.life:SetText(tostring(s[row.key] or 0))
            end

            -- Gold: formatted money strings
            spentSes:SetText(formatMoney(sessionValue("gold_repaired"))  or "0c")
            spentLife:SetText(formatMoney(s.gold_repaired or 0)          or "0c")
            junkSes:SetText(formatMoney(sessionValue("gold_from_gray"))  or "0c")
            junkLife:SetText(formatMoney(s.gold_from_gray or 0)          or "0c")

            local sesNet  = sessionValue("gold_from_gray") - sessionValue("gold_repaired")
            local lifeNet = (s.gold_from_gray or 0) - (s.gold_repaired or 0)
            netSes:SetText(netStr(sesNet))
            netLife:SetText(netStr(lifeNet))

            -- Insights
            local repairs = s.repair_count or 0
            if repairs > 0 then
                local avgCost = math.floor((s.gold_repaired or 0) / repairs + 0.5)
                avgLife:SetText(formatMoney(avgCost) or "0c")
            else
                avgLife:SetText("|cff888888\226\128\148|r")  -- em-dash
            end

            if (s.biggest_repair or 0) > 0 then
                biggestLife:SetText(formatMoney(s.biggest_repair) or "0c")
            else
                biggestLife:SetText("|cff888888\226\128\148|r")
            end

            -- Count merged zones with at least one discovered vendor.
            local zones = (SlotStatusDB and SlotStatusDB.discoveredVendors) or {}
            local nVendors, nZones = 0, 0
            for _, bucket in pairs(zones) do
                local z = 0
                for _ in pairs(bucket) do z = z + 1 end
                if z > 0 then
                    nVendors = nVendors + z
                    nZones = nZones + 1
                end
            end
            if nVendors == 0 then
                vendLife:SetText("|cff888888none yet|r")
            else
                vendLife:SetText(string.format("%d across %d zone%s",
                    nVendors, nZones, nZones == 1 and "" or "s"))
            end

        end
        sTab.refresh = refreshStats

        -- ---------- buttons (bottom row, unchanged positions) ----------
        local printBtn = CreateFrame("Button", nil, sTab, "UIPanelButtonTemplate")
        printBtn:SetSize(120, 22)
        printBtn:SetPoint("BOTTOMLEFT", sTab, "BOTTOMLEFT", 12, 10)
        printBtn:SetText("Print to Chat")
        printBtn:SetScript("OnClick", showStats)

        local resetStatsBtn = CreateFrame("Button", nil, sTab, "UIPanelButtonTemplate")
        resetStatsBtn:SetSize(110, 22)
        resetStatsBtn:SetPoint("LEFT", printBtn, "RIGHT", 8, 0)
        resetStatsBtn:SetText("Reset Stats")
        resetStatsBtn:SetScript("OnClick", function()
            -- resetStats() wipes SlotStatusDB.stats AND re-baselines the
            -- session snapshot, so the Session column zeros out here.
            resetStats()
            refreshStats()
        end)

        local refreshBtn = CreateFrame("Button", nil, sTab, "UIPanelButtonTemplate")
        refreshBtn:SetSize(90, 22)
        refreshBtn:SetPoint("LEFT", resetStatsBtn, "RIGHT", 8, 0)
        refreshBtn:SetText("Refresh")
        refreshBtn:SetScript("OnClick", refreshStats)

        refreshStats()
    end

    -- ============ FOOTER ============
    local helpText = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    helpText:SetPoint("BOTTOMLEFT", 16, 14)
    helpText:SetText("Type |cffffd200/ss|r for commands. Missing map pins? |cffffd200/ss map|r.")
    helpText:SetTextColor(0.6, 0.6, 0.6)

    selectTab(1)

    -- Refresh whenever the panel is opened
    panel.refresh = function()
        if tabFrames[activeTab] and tabFrames[activeTab].refresh then
            tabFrames[activeTab].refresh()
        end
    end
    panel:HookScript("OnShow", panel.refresh)

    if InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(panel)
    elseif Settings and Settings.RegisterCanvasLayoutCategory then
        local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
        Settings.RegisterAddOnCategory(category)
        -- Expose the ID to openSlotStatusOptions(). category.ID is the
        -- string Settings.OpenToCategory expects on modern clients.
        settingsCategoryID = category and category.ID or nil
    end
end

function initDefaults()
    SlotStatusDB = SlotStatusDB or {}
    if SlotStatusDB.debug            == nil then SlotStatusDB.debug = false end
    if SlotStatusDB.autoRepair       == nil then SlotStatusDB.autoRepair = true end
    if SlotStatusDB.autoRepairGuild  == nil then SlotStatusDB.autoRepairGuild = false end
    if SlotStatusDB.autoSell         == nil then SlotStatusDB.autoSell = true end
    if SlotStatusDB.warnThreshold    == nil then SlotStatusDB.warnThreshold = 25 end
    if SlotStatusDB.mapPins          == nil then SlotStatusDB.mapPins = true end
    if SlotStatusDB.showBars         == nil then SlotStatusDB.showBars = true end

    -- v1.0.0 Tier 2: auto-discover repair vendors from MERCHANT_SHOW.
    -- On by default; the captured data lives in `discoveredVendors` and
    -- is exposed via `/ss vendors`.
    if SlotStatusDB.discoverVendors  == nil then SlotStatusDB.discoverVendors = true end
    SlotStatusDB.discoveredVendors = SlotStatusDB.discoveredVendors or {}

    -- v1.0.0 release hygiene: scrub development-only instrumentation keys
    -- from pre-existing SV files. Testers accumulated these during the
    -- 0.9.x hypothesis-driven debugging sessions; new installs never
    -- write them. Setting to nil drops the key entirely on next SV flush.
    SlotStatusDB._debugProbe      = nil
    SlotStatusDB._debugProbeH5    = nil
    SlotStatusDB._hairlineProbe   = nil
    SlotStatusDB._loginMarker     = nil
    SlotStatusDB._buildPanelMarker = nil
    SlotStatusDB._statsShowMarker = nil
    SlotStatusDB._alignProbe      = nil
    -- The legacy 'debug' key was a table in the DEBUG build but is a
    -- boolean in shipping builds. Coerce it so /ss debug doesn't crash.
    if type(SlotStatusDB.debug) == "table" then
        SlotStatusDB.debug = false
    end

    -- New in v0.5.0: warning mode supersedes the old warnEnabled bool.
    if SlotStatusDB.warnMode == nil then
        if SlotStatusDB.warnEnabled == false then
            SlotStatusDB.warnMode = "off"
        else
            SlotStatusDB.warnMode = "full"
        end
    end

    -- Pre-combat warning
    if SlotStatusDB.combatWarn   == nil then SlotStatusDB.combatWarn   = true end
    if SlotStatusDB.combatThresh == nil then SlotStatusDB.combatThresh = 35   end

    -- Bar color boundaries
    if SlotStatusDB.threshG2Y == nil then SlotStatusDB.threshG2Y = 75 end
    if SlotStatusDB.threshY2R == nil then SlotStatusDB.threshY2R = 40 end

    -- Bar colors (stored as {r,g,b})
    SlotStatusDB.colorHigh      = SlotStatusDB.colorHigh      or {GREEN_R,  GREEN_G,  GREEN_B}
    SlotStatusDB.colorMid       = SlotStatusDB.colorMid       or {YELLOW_R, YELLOW_G, YELLOW_B}
    SlotStatusDB.colorLow       = SlotStatusDB.colorLow       or {RED_R,    RED_G,    RED_B}
    SlotStatusDB.colorAccessory = SlotStatusDB.colorAccessory or {GOLD_R,   GOLD_G,   GOLD_B}
    SlotStatusDB.colorUtility   = SlotStatusDB.colorUtility   or {WHITE_R,  WHITE_G,  WHITE_B}

    -- Bar appearance
    if SlotStatusDB.barAlphaMult   == nil then SlotStatusDB.barAlphaMult   = 1.0                end
    if SlotStatusDB.barThickness   == nil then SlotStatusDB.barThickness   = SIDE_BAR_WIDTH     end
    if SlotStatusDB.barLeftOffset  == nil then SlotStatusDB.barLeftOffset  = LEFT_COLUMN_OFFSET end
    if SlotStatusDB.barRightOffset == nil then SlotStatusDB.barRightOffset = RIGHT_COLUMN_OFFSET end

    -- v0.5.1 migration: v0.5.0 had integer-step sliders for bar layout, which
    -- silently truncated 19.3 -> 19, 2.2 -> 2, etc. That left the left-column
    -- bars clipped inside the slot icon and looking unaligned. If we detect
    -- the old rounded values (and the user has a version older than 0.5.1),
    -- reset them to clean float defaults.
    if SlotStatusDB.version ~= "0.5.1" then
        SlotStatusDB.barLeftOffset  = LEFT_COLUMN_OFFSET
        SlotStatusDB.barRightOffset = RIGHT_COLUMN_OFFSET
        SlotStatusDB.barThickness   = SIDE_BAR_WIDTH
        SlotStatusDB.barAlphaMult   = 1.0
        SlotStatusDB.version = "0.5.1"
    end

    SlotStatusDB.stats = SlotStatusDB.stats or {}

    -- v0.8.0: minimap button. Default visible; position on the minimap
    -- ring stored as angle in degrees. 215 = lower-left, which avoids
    -- the default tracking icon and most third-party broker panels.
    if SlotStatusDB.hideMinimap   == nil then SlotStatusDB.hideMinimap   = false end
    if SlotStatusDB.minimapAngle  == nil then SlotStatusDB.minimapAngle  = 215   end
end

f:SetScript("OnEvent", function(_, event, ...)
    if event == "PLAYER_LOGIN" then
        initDefaults()
        -- Freeze the lifetime totals NOW so the Stats tab's "Session"
        -- column renders zeros immediately after /reload. Must run after
        -- initDefaults() (which guarantees SlotStatusDB.stats exists).
        snapshotSessionStats()

        print("|cffffd200SlotStatus|r v" .. ((GetAddOnMetadata and GetAddOnMetadata(addonName, "Version")) or "1.0.0") .. " loaded \226\128\148 |cffffffff/ss options|r for the panel.")
        if SlotStatusDB.debug then
            print("|cffffd200SlotStatus|r |cff888888debug mode is ON|r")
        end

        -- v0.8.8 cleanup: if a prior session left debug tint textures
        -- parented to ColorPickerFrame (from the v0.8.7-DEBUG pass),
        -- hide them so the user doesn't see a purple/cyan sheet the
        -- next time the picker opens. We only hide -- textures can't
        -- be destroyed at runtime in WoW, and a /reload clears them.
        pcall(function()
            local cp = _G.ColorPickerFrame
            if cp then
                if cp._ssDebugMagenta    then cp._ssDebugMagenta:Hide()    end
                if cp._ssIndependentBg   then cp._ssIndependentBg:Hide()   end
            end
        end)

        registerSlashCommands()
        registerTooltipHooks()
        -- v0.8.1: each UI setup step is pcall'd in isolation. Previously a
        -- crash in buildOptionsPanel (missing API, bad anchor, etc.) would
        -- abort the entire PLAYER_LOGIN handler, leaving no options panel
        -- AND no minimap button AND no map pins -- while the durability
        -- bars still showed up via the PLAYER_ENTERING_WORLD safety net.
        -- That was impossible to diagnose without BugSack; each failure
        -- now self-reports instead.
        local okOpt, errOpt = pcall(buildOptionsPanel)
        if not okOpt then
            print("|cffff5555SlotStatus|r options panel failed to build: " .. tostring(errOpt))
        end
        local okPins, errPins = pcall(registerMapPins)
        if not okPins then
            print("|cffff5555SlotStatus|r map pins failed to register: " .. tostring(errPins))
        end
        pcall(registerLDB)
        pcall(buildMinimapButton)

        if not CharacterFrame or not PaperDollFrame then
            pcall(LoadAddOn, "Blizzard_CharacterUI")
        end

        local ok, err = pcall(function()
            discoverSlotFrames()
            createBars()
            updateBars()
        end)
        if not ok then
            print("|cffff0000SlotStatus|r error during bar setup: " .. tostring(err))
        end

        local _, anySlotFrame = next(slotFrames)
        if anySlotFrame and anySlotFrame.GetWidth then
            local nFrames, nBars = 0, 0
            for _ in pairs(slotFrames) do nFrames = nFrames + 1 end
            for _ in pairs(bars) do nBars = nBars + 1 end
            print(string.format(
                "|cffffd200SlotStatus|r Slots are %d\195\151%d px \226\128\148 found %d slot frames, created %d bars",
                anySlotFrame:GetWidth(), anySlotFrame:GetHeight(), nFrames, nBars))
        else
            print("|cffff5555SlotStatus|r could NOT find any Character*Slot frames \226\128\148 bars will not render")
        end

        -- v1.5.0: first-run welcome popup. Show ONCE per character. The
        -- `welcomeShown` flag is intentionally NOT seeded in
        -- initDefaults() — its absence is the signal that this is a
        -- fresh install on this character. 2-second delay lets
        -- Blizzard's own loading-screen chatter and our own "loaded"
        -- print finish first, so the popup isn't buried in chat spam
        -- or stepped on by other addons racing PLAYER_LOGIN.
        --
        -- pcall'd on its own (not wrapped around a whole group) so a
        -- freak failure inside the popup builder can never stomp on
        -- the character-bar init path that just ran above. The show
        -- is also pcall'd so an error there doesn't prevent the flag
        -- from being set (better to fail silently once than to
        -- re-spam the player every login).
        if SlotStatusDB and SlotStatusDB.welcomeShown ~= true then
            local showDelayed = function()
                if type(showWelcomePopup) == "function" then
                    pcall(showWelcomePopup)
                end
                SlotStatusDB.welcomeShown = true
            end
            if C_Timer and C_Timer.After then
                C_Timer.After(2, showDelayed)
            else
                -- Fallback for any build that doesn't ship C_Timer
                -- (shouldn't happen on Anniversary / 20505, but cheap
                -- insurance): fire immediately instead of skipping.
                showDelayed()
            end
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        -- Safety net: if bars weren't created yet (e.g. CharacterUI wasn't
        -- ready at PLAYER_LOGIN), rebuild them now.
        local nBars = 0
        for _ in pairs(bars) do nBars = nBars + 1 end
        if nBars == 0 then
            if not CharacterFrame or not PaperDollFrame then
                pcall(LoadAddOn, "Blizzard_CharacterUI")
            end
            local ok, err = pcall(function()
                discoverSlotFrames()
                createBars()
                updateBars()
            end)
            if ok then
                local recount = 0
                for _ in pairs(bars) do recount = recount + 1 end
                if recount > 0 then
                    print(string.format(
                        "|cffffd200SlotStatus|r bars rebuilt at zone-in (%d bars)", recount))
                end
            else
                print("|cffff0000SlotStatus|r rebuild error: " .. tostring(err))
            end
        end
        updateBars()
    elseif event == "MERCHANT_SHOW" then
        pcall(handleMerchantVisit)
    elseif event == "UPDATE_INVENTORY_DURABILITY" then
        updateBars()
        checkDurabilityWarnings()
        if SlotStatusLDB and SlotStatusLDB._update then SlotStatusLDB._update() end
    elseif event == "PLAYER_REGEN_DISABLED" then
        checkPreCombatWarning()
    else
        updateBars()
        if SlotStatusLDB and SlotStatusLDB._update then SlotStatusLDB._update() end
    end
end)