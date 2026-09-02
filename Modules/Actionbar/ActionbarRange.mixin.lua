local addonName, addonTable = ...;
local DF = addonTable.DF;
local L = addonTable.L;
local Helper = addonTable.Helper;

local CreateColor = DFCreateColor

local subModuleName = 'ActionbarRange';
local SubModuleMixin = {};
addonTable.SubModuleMixins[subModuleName] = SubModuleMixin;

function SubModuleMixin:Init()
    self.ModuleRef = DF:GetModule('Actionbar')
    self:SetDefaults()
    self:SetupOptions()
end

function SubModuleMixin:SetDefaults()
    local defaults = {
        activate = true,
        -- unitframeDesaturate = true,
        hotkeyColor = CreateColor(LIGHTGRAY_FONT_COLOR:GetRGB()):GenerateHexColorNoAlpha(),
        hotkeyColorOutOfRange = CreateColor(RED_FONT_COLOR:GetRGB()):GenerateHexColorNoAlpha(),
        -- not usable
        notUsableColor = CreateColor(0.4, 0.4, 0.4):GenerateHexColorNoAlpha(),
        notUsableDesaturate = false,
        -- out of range
        oorColor = CreateColor(1.0, 0.5, 0.5):GenerateHexColorNoAlpha(),
        oorDesaturate = true,
        -- out of mana
        oomColor = CreateColor(0.5, 0.5, 1.0):GenerateHexColorNoAlpha(),
        oomDesaturate = false
    };
    self.Defaults = defaults;
end

function SubModuleMixin:SetupOptions()
    local Module = self.ModuleRef;
    local function getDefaultStr(key, sub, extra)
        -- return Module:GetDefaultStr(key, sub)
        local value = self.Defaults[key]
        local defaultFormat = L["SettingsDefaultStringFormat"]
        return string.format(defaultFormat, (extra or '') .. tostring(value))
    end

    local function setDefaultValues()
        Module:SetDefaultValues()
    end

    local function setDefaultSubValues(sub)
        Module:SetDefaultSubValues(sub)
    end

    local function getOption(info)
        return Module:GetOption(info)
    end

    local function setOption(info, value)
        Module:SetOption(info, value)
    end

    local function setPreset(T, preset, sub)
        for k, v in pairs(preset) do
            --
            T[k] = v;
        end
        Module:ApplySettings(sub)
        Module:RefreshOptionScreens()
    end

    local options = {
        name = L["ActionbarRangeName"],
        desc = L["ActionbarRangeNameDesc"],
        -- advancedName = 'VehicleLeave',
        sub = 'actionbarRange',
        get = getOption,
        set = setOption,
        type = 'group',
        args = {
            activate = {
                type = 'toggle',
                name = L["ButtonTableActive"],
                desc = L["ButtonTableActiveDesc"] .. getDefaultStr('activate', 'actionbarRange'),
                order = -1,
                new = false
            },
            -- headerRange = {
            --     type = 'header',
            --     name = L["ActionbarRangeHeader"],
            --     desc = L["ActionbarRangeHeaderDesc"],
            --     order = 10,
            --     isExpanded = true
            -- },
            headerHotkey = {
                type = 'header',
                name = L["ActionbarRangeHeaderHotkey"],
                desc = L["ActionbarRangeHeaderHotkeyDesc"],
                order = 60,
                isExpanded = true
            },
            hotkeyColor = {
                type = 'color',
                name = L["ActionbarRangeHotkeyColor"],
                desc = L["ActionbarRangeHotkeyColorDesc"] .. getDefaultStr('hotkeyColor', 'actionbarRange', '#'),
                group = 'headerHotkey',
                order = 1
            },
            hotkeyColorOutOfRange = {
                type = 'color',
                name = L["ActionbarRangeHotkeyOutOfRangeColor"],
                desc = L["ActionbarRangeHotkeyOutOfRangeColorDesc"] ..
                    getDefaultStr('hotkeyColorOutOfRange', 'actionbarRange', '#'),
                group = 'headerHotkey',
                order = 2
            },
            -- not usable
            headerNotUsable = {
                type = 'header',
                name = L["ActionbarRangeHeaderNotUsable"],
                desc = L["ActionbarRangeHeaderNotUsableDesc"],
                order = 30,
                isExpanded = true
            },
            notUsableDesaturate = {
                type = 'toggle',
                name = L["DarkmodeDesaturate"],
                desc = '' .. getDefaultStr('notUsableDesaturate', 'actionbarRange'),
                group = 'headerNotUsable',
                order = 1,
                new = false
            },
            notUsableColor = {
                type = 'color',
                name = L["DarkmodeColor"],
                desc = '' .. getDefaultStr('notUsableColor', 'actionbarRange', '#'),
                group = 'headerNotUsable',
                order = 2
            },
            -- oor
            headerOutOfRange = {
                type = 'header',
                name = L["ActionbarRangeHeaderOutOfRange"],
                desc = L["ActionbarRangeHeaderOutOfRangeDesc"],
                order = 40,
                isExpanded = true
            },
            oorDesaturate = {
                type = 'toggle',
                name = L["DarkmodeDesaturate"],
                desc = '' .. getDefaultStr('oorDesaturate', 'actionbarRange'),
                group = 'headerOutOfRange',
                order = 1,
                new = false
            },
            oorColor = {
                type = 'color',
                name = L["DarkmodeColor"],
                desc = '' .. getDefaultStr('oorColor', 'actionbarRange', '#'),
                group = 'headerOutOfRange',
                order = 2
            },
            -- oom
            headerOutOfMana = {
                type = 'header',
                name = L["ActionbarRangeHeaderOutOfMana"],
                desc = L["ActionbarRangeHeaderOutOfManaDesc"],
                order = 50,
                isExpanded = true
            },
            oomDesaturate = {
                type = 'toggle',
                name = L["DarkmodeDesaturate"],
                desc = '' .. getDefaultStr('oomDesaturate', 'actionbarRange'),
                group = 'headerOutOfMana',
                order = 1,
                new = false
            },
            oomColor = {
                type = 'color',
                name = L["DarkmodeColor"],
                desc = '' .. getDefaultStr('oomColor', 'actionbarRange', '#'),
                group = 'headerOutOfMana',
                order = 2
            }
        }
    }

    self.Options = options;
end

function SubModuleMixin:Setup()
    local function setDefaultSubValues(sub)
        self.ModuleRef:SetDefaultSubValues(sub)
    end

    DF.ConfigModule:RegisterSettingsData('actionbarRange', 'actionbar', {
        options = self.Options,
        default = function()
            setDefaultSubValues(self.Options.sub)
        end
    })

    --

    self.activate = false;
    -- local db = self.ModuleRef.db.profile.actionbarRange;

    -- TOOLTIP_UPDATE_TIME , = 0.2  update frequency
    -- ActionButton_UpdateRangeIndicator

    hooksecurefunc('ActionButton_UpdateRangeIndicator', function(btn, checksRange, inRange)
        if not self.activate then return end
        if not btn.HotKey then return end

        -- if btn ~= _G['ActionButton9'] then return end
        -- print('ActionButton_UpdateRangeIndicator', btn:GetName())

        if (checksRange and not inRange) then
            btn.HotKey:SetVertexColor(self.hotkeyColorOutOfRange:GetRGB());
        else
            btn.HotKey:SetVertexColor(self.hotkeyColor:GetRGB());
        end

        if btn.checksRange ~= checksRange or btn.inRange ~= inRange then
            -- something changed ~> also update icons etc
            btn.checksRange = checksRange;
            btn.inRange = inRange;
            self:UpdateRangeAndUsable(btn, checksRange, inRange);
        end
    end)

    -- ActionButton_UpdateUsable (Legacy fallback if present)
    if ActionButton_UpdateUsable then
        hooksecurefunc('ActionButton_UpdateUsable', function(btn)
            if not self.activate then return end
            self:UpdateRangeAndUsable(btn, btn.checksRange or false, btn.inRange or false);
        end)
    end
end

-- On 1.15.9 the ActionButton_UpdateUsable global no longer exists, so the
-- hook above never installs and our recoloring only ever ran off range
-- events. Anything else that repainted a button (ACTION_USABLE_CHANGED, a
-- macro re-resolving to a different spell) left Blizzard's flat colors in
-- place - and because Blizzard's UpdateUsable never clears desaturation,
-- an icon we desaturated for out-of-range could stay grey until the next
-- range event, which is what "grey buttons that recover on mouseover"
-- was. Buttons own a copy of the mixin method, so hook per button.
-- Tracked outside the frames: writing a marker field onto a button taints
-- its table, and Blizzard's mouseover path performs protected calls on it.
local usableHooked = setmetatable({}, {__mode = 'k'})

function SubModuleMixin:HookButtonUsable(btn)
    if not btn or usableHooked[btn] then return end

    local function repaint(b, label)
        if not self.activate then return end
        -- Never let a repaint break the click that triggered it.
        local ok, err = pcall(self.UpdateRangeAndUsable, self, b, b.checksRange or false, b.inRange or false)
        if not ok and not self.DFUsableErrorLogged then
            self.DFUsableErrorLogged = true
            geterrorhandler()('DFUI ActionbarRange:' .. label .. ': ' .. tostring(err))
        end
    end

    local hooked = false

    if type(btn.UpdateUsable) == 'function' then
        hooked = true
        hooksecurefunc(btn, 'UpdateUsable', function(b) repaint(b, 'UpdateUsable') end)
    end

    -- The count has its own path. Blizzard reaches UpdateCount from SPELL_UPDATE_CHARGES
    -- and from UpdateAction after a bag change, and neither goes through UpdateUsable - so
    -- spending the last item repaints the number while our tint keeps the colour it had
    -- while the stack still existed.
    if type(btn.UpdateCount) == 'function' then
        hooked = true
        hooksecurefunc(btn, 'UpdateCount', function(b) repaint(b, 'UpdateCount') end)
    end

    -- Flagged only once something was actually installed. Marking a button that had
    -- neither method would leave it unhooked for good if its mixin arrived afterwards,
    -- because every later call bails on the flag.
    if hooked then usableHooked[btn] = true end
end

function SubModuleMixin:OnEvent(event, ...)
    -- print('event', event, ...)
end

function SubModuleMixin:UpdateState(state)
    self.state = state;
    self:Update();
end

function SubModuleMixin:Update()
    local state = self.state;
    if not state then return end

    self.activate = state.activate;

    self.hotkeyColor = CreateColorFromRGBHexString(state.hotkeyColor)
    self.hotkeyColorOutOfRange = CreateColorFromRGBHexString(state.hotkeyColorOutOfRange)

    self.notUsableColor = CreateColorFromRGBHexString(state.notUsableColor)
    self.oorColor = CreateColorFromRGBHexString(state.oorColor)
    self.oomColor = CreateColorFromRGBHexString(state.oomColor)
end

-- Hot path: cache the two static lookups - whether a macro is a
-- #showtooltip macro (invalidated on UPDATE_MACROS) and each spell's power
-- costs (invalidated on player max-power changes; percent-based costs
-- scale with it). GetMacroSpell stays live: its result depends on the
-- macro's conditionals.
local macroIsShowtooltip = {}
local powerCostCache = {}
do
    local inv = CreateFrame('Frame')
    inv:RegisterEvent('UPDATE_MACROS')
    inv:RegisterUnitEvent('UNIT_MAXPOWER', 'player')
    inv:RegisterEvent('PLAYER_ENTERING_WORLD')
    inv:SetScript('OnEvent', function(_, event)
        if event == 'UPDATE_MACROS' then
            wipe(macroIsShowtooltip)
        else
            wipe(powerCostCache)
        end
    end)
end

-- The four action queries this needs all moved to C_ActionBar, and only survive as
-- globals through Blizzard_DeprecatedActionBar - Deprecated_ActionBar.lua forwards each
-- one straight to the namespace. Present on Era, TBC Anniversary and MoP alike, but a
-- deprecated addon is a poor thing to depend on, so ask the namespace first. Same shape
-- Actionbar.Controller already uses for IsEquippedAction.
local function ActionQuery(namespaced, legacy, slot)
    if C_ActionBar and C_ActionBar[namespaced] then return C_ActionBar[namespaced](slot) end

    local fallback = _G[legacy]
    if fallback then return fallback(slot) end

    return nil
end

-- Is this an item action with none of it left?
--
-- Ordered so a spell costs a single call. This runs inside CustomIsUsableAction, which the
-- comment further down rightly calls a hot path, and most buttons hold spells - they leave
-- on the first check. Asking for the count first would have been three more calls for
-- every spell on the bar, because a spell's use count is zero too.
--
-- Equipped items are excluded: they are not in the bags to be counted, so they read as
-- zero while being perfectly usable. Consumables need no separate test, a consumable on a
-- bar is an item action.
--
-- A nil count means the query is unavailable, not that the stack is empty, so this has to
-- answer false there rather than dim every item on a client that tells us nothing.
local function ActionStackIsEmpty(action)
    if not ActionQuery('IsItemAction', 'IsItemAction', action) then return false end
    if ActionQuery('IsEquippedAction', 'IsEquippedAction', action) then return false end

    return ActionQuery('GetActionUseCount', 'GetActionCount', action) == 0
end

local function CustomIsUsableAction(action)
    if not action then return true, false end
    local actionType, id = GetActionInfo(action)

    if actionType == 'macro' then
        local isShowtooltip = macroIsShowtooltip[id]
        if isShowtooltip == nil then
            local name = GetMacroInfo(id)
            isShowtooltip = (name and name:sub(1, 1) == '#') or false
            macroIsShowtooltip[id] = isShowtooltip
        end

        if isShowtooltip then
            local spellID = GetMacroSpell(id);

            if spellID then
                local costs = powerCostCache[spellID]
                if costs == nil then
                    local apiCosts = C_Spell.GetSpellPowerCost(spellID)
                    if apiCosts then
                        costs = {}
                        for i = 1, #apiCosts do
                            costs[i] = {type = apiCosts[i].type, minCost = apiCosts[i].minCost}
                        end
                    else
                        costs = false
                    end
                    powerCostCache[spellID] = costs
                end

                if costs then
                    for i = 1, #costs do
                        local cost = costs[i]
                        if UnitPower('player', cost.type) < cost.minCost then
                            return false, true;
                        end
                    end
                end
            end
        end
    end

    local isUsable, notEnoughMana = IsUsableAction(action);

    -- An empty stack still answers "usable".
    --
    -- IsUsableAction reports mana, reagents and cooldown. Running out of an item is none
    -- of those, so the answer does not change when the last potion leaves your bags and
    -- the button stays bright with a 0 next to it. Colouring it as unusable is what the
    -- icon tint is for.
    if isUsable and ActionStackIsEmpty(action) then return false, false end

    return isUsable, notEnoughMana
end

function SubModuleMixin:UpdateRangeAndUsable(btn, checksRange, inRange)
    if btn.ignoreRange then return end
    -- Pet, stance and possess buttons carry no action slot; the usable
    -- APIs error outright on a nil one.
    if not btn.action then return end
    -- hidden buttons refresh via ActionButton_OnShow when they appear
    if not btn:IsVisible() then return end
    -- Blizzard's own ActionBarActionButtonMixin keeps this as lowercase icon; only our
    -- restyled buttons carry Icon. Checking both means a native button is tinted too
    -- rather than silently skipped.
    local icon = btn.Icon or btn.icon
    if not icon then return end
    local state = self.state;
    if not state then return end

    local isUsable, notEnoughMana = CustomIsUsableAction(btn.action);
    -- print('UpdateRangeAndUsable', btn:GetName(), checksRange, inRange)  
    -- print('~>', isUsable, notEnoughMana)

    if isUsable then
        -- sufficient mana, reagents and not on cooldown
        if checksRange and not inRange then
            icon:SetVertexColor(self.oorColor:GetRGBA())
            icon:SetDesaturated(state.oorDesaturate)
        else
            icon:SetVertexColor(1.0, 1.0, 1.0, 1.0) -- default
            icon:SetDesaturated(false) -- default
        end
    else
        -- not useable
        if notEnoughMana then
            icon:SetVertexColor(self.oomColor:GetRGBA())
            icon:SetDesaturated(state.oomDesaturate)
        else
            icon:SetVertexColor(self.notUsableColor:GetRGBA())
            icon:SetDesaturated(state.notUsableDesaturate)
        end
    end
end
