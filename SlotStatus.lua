-- SlotStatus v1.1.12 - FINAL: Outer bars + Perfect Alignment + No White Background
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

-- ====================== EASY ADJUSTMENT SECTION ======================
local SIDE_BAR_WIDTH       = 2.2
local SIDE_BAR_HEIGHT_PAD  = 4
local WEAPON_BAR_WIDTH_PAD = 2
local WEAPON_BAR_HEIGHT    = 3
local WEAPON_BAR_Y_OFFSET  = 0
-- ====================================================================

-- BRIGHT FULL-COLOR VALUES
local GREEN_R, GREEN_G, GREEN_B = 0.00, 0.95, 0.35
local YELLOW_R, YELLOW_G, YELLOW_B = 1.00, 1.00, 0.00
local RED_R,    RED_G,    RED_B    = 0.85, 0.05, 0.05   -- deep red <40%
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

local function pct(cur, max)
    if not max or max <= 0 then return nil end
    return math.floor((cur / max) * 100 + 0.5)
end

local function setDurabilityColor(bar, p)
    if not p then return end
    if     p >= 75 then bar:SetStatusBarColor(GREEN_R,  GREEN_G,  GREEN_B)
    elseif p >= 40 then bar:SetStatusBarColor(YELLOW_R, YELLOW_G, YELLOW_B)
    else                bar:SetStatusBarColor(RED_R,    RED_G,    RED_B)
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
    
    -- === CHANGE THESE TWO NUMBERS ONLY ===
    local LEFT_OFFSET  = 19.3    -- ← change this for LEFT column bars
    local RIGHT_OFFSET = 20    -- ← change this for RIGHT column bars
    
    if slotFrame:GetCenter() < ((PaperDollFrame and PaperDollFrame:GetCenter()) or (CharacterFrame and CharacterFrame:GetCenter())) then
        -- LEFT column
        bar:SetPoint("CENTER", slotFrame, "CENTER", -LEFT_OFFSET, 0)
    else
        -- RIGHT column
        bar:SetPoint("CENTER", slotFrame, "CENTER", RIGHT_OFFSET, 0)
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
            bar:SetAlpha(st.alpha)
            bar:SetFrameLevel((slotFrame:GetFrameLevel() or 1) + 10)

            bar.bg = bar:CreateTexture(nil, "BACKGROUND")
            bar.bg:SetAllPoints(true)
            bar.bg:SetTexture("Interface\\Buttons\\WHITE8x8")
            bar.bg:SetVertexColor(BG_R, BG_G, BG_B, BG_A)

            if s.category == "weapon" then
                bar:SetOrientation("HORIZONTAL")
                bar:SetWidth( (slotFrame:GetWidth() or 37) - WEAPON_BAR_WIDTH_PAD )
                bar:SetHeight(WEAPON_BAR_HEIGHT)
                bar:SetPoint("BOTTOM", slotFrame, "BOTTOM", 0, WEAPON_BAR_Y_OFFSET)
            else
                bar:SetOrientation("VERTICAL")
                bar:SetWidth(SIDE_BAR_WIDTH)
                bar:SetHeight( (slotFrame:GetHeight() or 37) - SIDE_BAR_HEIGHT_PAD )
                placeVerticalBar(bar, slotFrame)
            end

            bars[s.id] = bar
            bar:Hide()
        end
    end
end

local function updateBars()
    for _, s in ipairs(SLOTS) do
        local bar = bars[s.id]
        if bar then
            local equipped = GetInventoryItemID("player", s.id) ~= nil
            if not equipped then
                bar:Hide()
            else
                local cur, max = GetInventoryItemDurability(s.id)
                local has_durability = (cur and max and max > 0)
                local p = has_durability and pct(cur, max) or 100

                bar:SetValue(p)

                if has_durability then
                    setDurabilityColor(bar, p)
                else
                    if     s.category == "utility" then bar:SetStatusBarColor(WHITE_R, WHITE_G, WHITE_B)
                    elseif s.category == "weapon"  then bar:SetStatusBarColor(GREEN_R, GREEN_G, GREEN_B)
                    else                                bar:SetStatusBarColor(GOLD_R,  GOLD_G,  GOLD_B)
                    end
                end

                bar:Show()
            end
        end
    end
end

local function enhanceTooltip(tooltip, unit, slot)
    if not slot or not unit then return end
    local itemID = GetInventoryItemID(unit, slot)
    if not itemID then return end

    local _, _, _, ilvl = GetItemInfo(itemID)
    if ilvl and ilvl > 0 then
        tooltip:AddLine("|cffffffffItem Level: |r" .. ilvl, 1,1,1)
    end

    local repairCost = GetRepairAllCost()
    if repairCost and repairCost > 0 then
        local gold   = math.floor(repairCost / 10000)
        local silver = math.floor((repairCost % 10000) / 100)
        local copper = repairCost % 100

        local text = "|cffffffffTotal Repair Cost: |r"
        if gold   > 0 then text = text .. gold   .. "|cffffd700g|r " end
        if silver > 0 then text = text .. silver .. "|cffc7c7cfs|r " end
        if copper > 0 then text = text .. copper .. "|cffeda55fc|r" end

        tooltip:AddLine(text)
    end
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("UPDATE_INVENTORY_DURABILITY")
f:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")

f:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        print("|cffffd200SlotStatus|r v1.1.12 FINAL loaded — perfectly aligned outer bars!")
        
        if not CharacterFrame or not PaperDollFrame then
            pcall(LoadAddOn, "Blizzard_CharacterUI")
        end
        
        discoverSlotFrames()
        createBars()
        updateBars()

        local anySlot = next(slotFrames)
        if anySlot then
            print("|cffffd200SlotStatus|r Slots are " .. anySlot:GetWidth() .. "×" .. anySlot:GetHeight() .. " pixels")
        end

        hooksecurefunc(GameTooltip, "SetInventoryItem", function(self, unit, slot)
            enhanceTooltip(self, unit, slot)
        end)
    else
        updateBars()
    end

end)
