local addonName, addonTable = ...;
local DF = addonTable.DF;
local L = addonTable.L;
local Helper = addonTable.Helper;

local subModuleName = 'RaidFrame';
local SubModuleMixin = {};
addonTable.SubModuleMixins[subModuleName] = SubModuleMixin;

function SubModuleMixin:Init()
    self.ModuleRef = DF:GetModule('Unitframe')
    self:SetDefaults()
    self:SetupOptions()
    -- self:SetScript('OnEvent', self.OnEvent);
end

function SubModuleMixin:SetDefaults()
    -- Position and scale are live now, so these are no longer commented out.
    --
    -- The default anchor is deliberately UIParent TOPLEFT with a zero offset rather
    -- than invented coordinates: Update() calibrates once from wherever the raid
    -- container already sits and writes that into the profile, so the first run does
    -- not teleport anybody's raid frames to a spot this file guessed at.
    local defaults = {
        -- breakUpLargeNumbers = true,
        -- enableThreatGlow = true,
        scale = 1.0,
        override = false,
        anchorFrame = 'UIParent',
        customAnchorFrame = '',
        anchor = 'TOPLEFT',
        anchorParent = 'TOPLEFT',
        x = 0,
        y = 0,
        calibrated = false,
        -- Visibility, and every key AddStateTable offers has to be here.
        --
        -- A missing default means getOption returns nil, and the settings list feeds
        -- that straight into Slider:SetValue - which is the "bad argument #1 to
        -- SetValue" the alpha rows threw. Same list as the party frame's.
        alphaNormal = 1.0,
        alphaCombat = 1.0,
        showMouseover = false,
        hideAlways = false,
        hideCombat = false,
        hideOutOfCombat = false,
        hideVehicle = false,
        hidePet = false,
        hideNoPet = false,
        hideStance = false,
        hideStealth = false,
        hideNoStealth = false,
        hideBattlePet = false,
        hideCustom = false,
        hideCustomCond = '',
        -- hideStatusbarText = false,
        -- offset = false,
        -- hideIndicator = false,
        -- -- Visibility
        -- showMouseover = false,
        -- hideAlways = false,
        -- hideCombat = false,
        -- hideOutOfCombat = false,
        -- hidePet = false,
        -- hideNoPet = false,
        -- hideStance = false,
        -- hideStealth = false,
        -- hideNoStealth = false,
        -- hideCustom = false,
        -- hideCustomCond = ''
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

    local frameTable = {
        {value = 'UIParent', text = 'UIParent', tooltip = 'descr', label = 'label'},
        {value = 'PlayerFrame', text = 'PlayerFrame', tooltip = 'descr', label = 'label'},
        {value = 'TargetFrame', text = 'TargetFrame', tooltip = 'descr', label = 'label'},
        {value = 'CompactRaidFrameManager', text = 'CompactRaidFrameManager', tooltip = 'descr', label = 'label'}
    }

    local partyBuffTooltipTable = {
        {value = 'NEVER', text = 'Never', tooltip = 'descr', label = 'label'},
        {value = 'ALWAYS', text = 'Always', tooltip = 'descr', label = 'label'},
        {value = 'INCOMBAT', text = 'In Combat', tooltip = 'descr', label = 'label'}
    }

    if DF.Wrath then
        table.insert(frameTable, {value = 'FocusFrame', text = 'FocusFrame', tooltip = 'descr', label = 'label'})
    end

    local function frameTableWithout(without)
        local newTable = {}

        for k, v in ipairs(frameTable) do
            --
            if v.value ~= without then
                --      
                table.insert(newTable, v);
            end
        end

        return newTable
    end

    -- The raid frame Edit Mode settings, offered here instead of sending people out
    -- to Blizzard's Edit Mode - which this addon blocks, so reaching it meant
    -- disabling the addon and reloading twice.
    --
    -- These cannot be applied to the frames directly. Every applier in
    -- EditModeUnitFrameSystemMixin reads its value back through GetSettingValue ->
    -- GetRegisteredSystemFrame, so the value has to reach the registered system
    -- frame and the layout. Helper's SetRaidEditModeSetting does both, the same way
    -- the party raid-style switch already did.
    --
    -- Bounds and choices are taken from Blizzard's own display info rather than
    -- invented here, because inventing them is how you ship a slider that lets
    -- people set a value the client then rejects. Anything Blizzard does not
    -- describe is left out.
    -- Blizzard's own description of the unit frame settings, read straight from
    -- EditModeSettingDisplayInfoManager.systemSettingDisplayInfo. It is an array per
    -- system, each entry carrying setting, name, type, and either minValue/maxValue/
    -- stepSize or an options list of {value, text}. Reading it does not taint it.
    local function GetUnitFrameDisplayInfo()
        if not (Enum and Enum.EditModeSystem) then return nil end

        local mgr = _G['EditModeSettingDisplayInfoManager']
        if not (mgr and mgr.systemSettingDisplayInfo) then return nil end

        return mgr.systemSettingDisplayInfo[Enum.EditModeSystem.UnitFrame]
    end

    -- The stored value is not the displayed value.
    --
    --   ConvertValueDiffFromMin: stored = shown - minValue
    --   ConvertValueDefault:     stored = (shown - minValue) / stepSize
    --
    -- Blizzard picks one per setting and hands it over as entry.ConvertValue, so it
    -- is called rather than reimplemented - getting this wrong silently writes
    -- nonsense into the layout.
    --
    -- The forDisplay direction runs self:ClampValue, which lives on the dialog's
    -- slider rather than on the data. A proxy supplies it, so Blizzard's arithmetic
    -- is still what runs.
    -- Only converted when the stored value clearly is not already the real one.
    --
    -- The live values say the stored form is absolute. FrameWidth is described as
    -- minValue 72, maxValue 144, ConvertValueDiffFromMin, and /df log raidopts read it
    -- back as 98 - applying DiffFromMin would make that 170, past the maximum, and pin
    -- the slider at the far end. FrameHeight reads 44 against 36 to 72, RowSize 5,
    -- Transparency and IconSize 100: every one of them already inside its own range.
    --
    -- ConvertValue exists for Blizzard's own slider widget, whose internal value is not
    -- the setting value. Reading the setting straight off the system frame skips that
    -- widget entirely, so there is nothing to undo.
    --
    -- It is still used as a fallback for any setting whose stored value does land
    -- outside its range, rather than assuming this holds everywhere. Identical bounds
    -- in classic_era, classic_anniversary and classic, so this reasoning covers Era,
    -- TBC and MoP alike.
    local function ConvertSettingValue(info, value, forDisplay)
        if not info then return value end

        local minV, maxV = info.minValue, info.maxValue
        local inRange = minV and maxV and value and value >= minV and value <= maxV

        if inRange or not info.ConvertValue then return value end

        local host = info
        if forDisplay and not info.ClampValue then
            host = setmetatable({
                ClampValue = function(selfRef, v)
                    return math.max(selfRef.minValue or v, math.min(selfRef.maxValue or v, v))
                end
            }, {__index = info})
        end

        local ok, converted = pcall(info.ConvertValue, host, value, forDisplay)
        if not ok then return value end

        return converted
    end

    -- One AceConfig entry per setting the raid system actually has.
    --
    -- Driven entirely off Blizzard's table: the label is Blizzard's localised name,
    -- the slider bounds are Blizzard's, the dropdown values are Blizzard's enums. The
    -- earlier version of this hardcoded English labels and a guessed value scheme,
    -- and produced an empty panel because none of the guesses matched.
    --
    -- HasSetting on the registered system frame decides what appears, so a flavour
    -- without a given setting simply does not show it.
    -- Which option key maps to which Edit Mode setting.
    --
    -- Needed because SettingsList builds every row with the GROUP's get and set -
    -- SettingsList.mixin.lua:859 does "get = data.options.get" - and ignores whatever
    -- an individual option defines. So the group handlers below have to recognise
    -- these keys, and this is how they do it. Per-option get/set are still set for
    -- correctness, they simply are not what runs.
    local blizzRaidSettings = {}

    -- Returns how many entries it added, so the caller can tell "not ready yet" from
    -- "nothing to offer" and stop retrying once it has worked.
    local function BuildRaidEditModeArgs(args)
        addonTable.RaidEditModeOptionCount = addonTable.RaidEditModeOptionCount or 0

        if not (addonTable.SetRaidEditModeSetting and Enum and Enum.EditModeSettingDisplayType) then return 0 end

        local displayInfo = GetUnitFrameDisplayInfo()
        if not displayInfo then return 0 end

        local raidFrame = addonTable.GetRaidSystemFrameForOptions and addonTable:GetRaidSystemFrameForOptions()
        if not (raidFrame and raidFrame.HasSetting) then return 0 end

        local added = 0

        local types = Enum.EditModeSettingDisplayType
        local order = 20

        for _, info in ipairs(displayInfo) do
            local setting = info.setting

            -- Both return values checked: a failed pcall hands back an error string,
            -- which is truthy, so testing only the second one would treat every
            -- failure as "yes, it has this setting".
            local hasIt = false
            if setting ~= nil then
                local ok, has = pcall(raidFrame.HasSetting, raidFrame, setting)
                hasIt = ok and has and true or false
            end

            if hasIt then
                order = order + 0.01

                local option = {
                    name = info.name or tostring(setting),
                    desc = 'Blizzard Edit Mode setting. Applied at once and kept in your Edit Mode layout.',
                    order = order,
                    editmode = true
                }

                local function GetStored() return addonTable:GetRaidEditModeSettingBySetting(setting) end
                local function SetStored(value) addonTable:SetRaidEditModeSettingBySetting(setting, value) end

                if info.type == types.Checkbox then
                    option.type = 'toggle'
                    option.get = function() return (GetStored() or 0) ~= 0 end
                    option.set = function(_, value) SetStored(value and 1 or 0) end
                elseif info.type == types.Slider then
                    -- bigStep, not step. DFSettingsList's slider does
                    -- SetValueStep(args.bigStep), so a step field it does not read
                    -- leaves the slider with no increment and no usable handle.
                    option.type = 'range'
                    option.min = info.minValue or 0
                    option.max = info.maxValue or 100
                    option.bigStep = info.stepSize or 1
                    option.get = function() return ConvertSettingValue(info, GetStored() or 0, true) end
                    option.set = function(_, value) SetStored(ConvertSettingValue(info, value, false)) end
                elseif info.type == types.Dropdown then
                    -- dropdownValues, an ARRAY of {value, text}, walked with ipairs by
                    -- DFSettingsListDropdownContainerMixin:Init. Not AceConfig's
                    -- values map keyed by value - that field is never read here, which
                    -- is why the dropdowns came up empty.
                    --
                    -- Blizzard's own options list is already in exactly that shape, so
                    -- it is copied rather than reshaped, dropping only malformed
                    -- entries.
                    local choices = {}
                    for _, choice in ipairs(info.options or {}) do
                        if choice.value ~= nil then
                            table.insert(choices, {value = choice.value, text = choice.text or tostring(choice.value)})
                        end
                    end

                    -- Guard rather than a goto: this is Lua 5.1, which has neither
                    -- goto nor labels.
                    if #choices > 0 then
                        option.type = 'select'
                        option.dropdownValues = choices
                        option.get = GetStored
                        option.set = function(_, value) SetStored(value) end
                    end
                end

                -- Only the branches that produced something usable set a type.
                if option.type then
                    local key = 'blizzRaid' .. tostring(setting)
                    args[key] = option
                    blizzRaidSettings[key] = {setting = setting, info = info, kind = option.type}
                    added = added + 1
                end
            end
        end

        addonTable.RaidEditModeOptionCount = added
        return added
    end

    local optionsRaid = {
        name = L["RaidFrameName"],
        advancedName = 'RaidFrame',
        sub = 'raid',
        get = getOption,
        set = setOption,
        type = 'group',
        args = {
            -- scale = {
            --     type = 'range',
            --     name = 'Scale',
            --     desc = '' .. getDefaultStr('scale', 'party'),
            --     min = 0.1,
            --     max = 5,
            --     bigStep = 0.1,
            --     order = 1,
            --     editmode = true
            -- },
            -- anchorFrame = {
            --     type = 'select',
            --     name = 'Anchorframe',
            --     desc = 'Anchor' .. getDefaultStr('anchorFrame', 'party'),
            --     values = frameTable,
            --     order = 4,
            --     editmode = true
            -- },
            -- anchor = {
            --     type = 'select',
            --     name = 'Anchor',
            --     desc = 'Anchor' .. getDefaultStr('anchor', 'party'),
            --     values = {
            --         ['TOP'] = 'TOP',
            --         ['RIGHT'] = 'RIGHT',
            --         ['BOTTOM'] = 'BOTTOM',
            --         ['LEFT'] = 'LEFT',
            --         ['TOPRIGHT'] = 'TOPRIGHT',
            --         ['TOPLEFT'] = 'TOPLEFT',
            --         ['BOTTOMLEFT'] = 'BOTTOMLEFT',
            --         ['BOTTOMRIGHT'] = 'BOTTOMRIGHT',
            --         ['CENTER'] = 'CENTER'
            --     },
            --     order = 2,
            --     editmode = true
            -- },
            -- anchorParent = {
            --     type = 'select',
            --     name = 'AnchorParent',
            --     desc = 'AnchorParent' .. getDefaultStr('anchorParent', 'party'),
            --     values = {
            --         ['TOP'] = 'TOP',
            --         ['RIGHT'] = 'RIGHT',
            --         ['BOTTOM'] = 'BOTTOM',
            --         ['LEFT'] = 'LEFT',
            --         ['TOPRIGHT'] = 'TOPRIGHT',
            --         ['TOPLEFT'] = 'TOPLEFT',
            --         ['BOTTOMLEFT'] = 'BOTTOMLEFT',
            --         ['BOTTOMRIGHT'] = 'BOTTOMRIGHT',
            --         ['CENTER'] = 'CENTER'
            --     },
            --     order = 3,
            --     editmode = true
            -- },
            -- x = {
            --     type = 'range',
            --     name = 'X',
            --     desc = 'X relative to *ANCHOR*' .. getDefaultStr('x', 'party'),
            --     min = -2500,
            --     max = 2500,
            --     bigStep = 1,
            --     order = 5,
            --     editmode = true
            -- },
            -- y = {
            --     type = 'range',
            --     name = 'Y',
            --     desc = 'Y relative to *ANCHOR*' .. getDefaultStr('y', 'party'),
            --     min = -2500,
            --     max = 2500,
            --     bigStep = 1,
            --     order = 6,
            --     editmode = true
            -- }     
        }
    }
    if true then
        local moreOptions = {
            -- useCompactPartyFrames = {
            --     type = 'toggle',
            --     name = USE_RAID_STYLE_PARTY_FRAMES,
            --     desc = OPTION_TOOLTIP_USE_RAID_STYLE_PARTY_FRAMES,
            --     order = 15,
            --     blizzard = true,
            --     editmode = false
            -- },
            -- Blizzard's Interface options panel, not the Edit Mode dialog.
            raidFrameBtn = {
                type = 'execute',
                name = 'Blizzard raid profile options',
                desc = 'Opens Blizzard\'s own Interface options for raid frames - health text, class colours and ' ..
                    'the like. The Edit Mode settings, frame size and group layout, are above.',
                btnName = 'Open',
                func = function()
                    Settings.OpenToCategory(Settings.INTERFACE_CATEGORY_ID, RAID_FRAMES_LABEL);
                    PlaySound(SOUNDKIT.IG_MAINMENU_OPTION);
                end,
                order = 5,
                blizzard = true,
                editmode = false
            }
            -- headerTaint = {type = 'header', name = 'May Cause Taint Issues - /reload after setup', desc = '', order = 10},
            -- keepGroupsTogether = {
            --     type = 'toggle',
            --     name = COMPACT_UNIT_FRAME_PROFILE_KEEPGROUPSTOGETHER,
            --     desc = OPTION_TOOLTIP_KEEP_GROUPS_TOGETHER,
            --     proxy = 'PROXY_RAID_FRAME_KEEP_GROUPS_TOGETHER',
            --     order = 20.1,
            --     blizzard = true,
            --     editmode = true
            -- },
            -- horizontalGroups = {
            --     type = 'toggle',
            --     name = COMPACT_UNIT_FRAME_PROFILE_HORIZONTALGROUPS,
            --     desc = '',
            --     proxy = 'PROXY_RAID_FRAME_KEEP_HORIZONTAL_GROUPS',
            --     order = 20.2,
            --     blizzard = true,
            --     editmode = true
            -- },
            -- sortBy = {
            --     type = 'select',
            --     name = COMPACT_UNIT_FRAME_PROFILE_SORTBY,
            --     desc = '',
            --     values = {['role'] = 'role', ['group'] = 'group', ['alphabetical'] = 'alphabetical'},
            --     proxy = 'PROXY_RAID_FRAME_SORT_BY',
            --     order = 20.21,
            --     blizzard = true,
            --     editmode = true
            -- },
            -- displayPowerBar = {
            --     type = 'toggle',
            --     name = COMPACT_UNIT_FRAME_PROFILE_DISPLAYPOWERBAR,
            --     desc = OPTION_TOOLTIP_COMPACT_UNIT_FRAME_PROFILE_DISPLAYPOWERBAR,
            --     proxy = 'PROXY_RAID_FRAME_POWER_BAR',
            --     order = 20.3,
            --     blizzard = true,
            --     editmode = true
            -- },
            -- useClassColors = {
            --     type = 'toggle',
            --     name = COMPACT_UNIT_FRAME_PROFILE_USECLASSCOLORS,
            --     desc = OPTION_TOOLTIP_COMPACT_UNIT_FRAME_PROFILE_USECLASSCOLORS,
            --     proxy = 'PROXY_RAID_FRAME_CLASS_COLORS',
            --     order = 20.4,
            --     blizzard = true,
            --     editmode = true
            -- },
            -- displayPets = {
            --     type = 'toggle',
            --     name = COMPACT_UNIT_FRAME_PROFILE_DISPLAYPETS,
            --     desc = OPTION_TOOLTIP_COMPACT_UNIT_FRAME_PROFILE_DISPLAYPETS,
            --     proxy = 'PROXY_RAID_FRAME_PETS',
            --     order = 20.5,
            --     blizzard = true,
            --     editmode = true
            -- },
            -- displayMainTankAndAssist = {
            --     type = 'toggle',
            --     name = COMPACT_UNIT_FRAME_PROFILE_DISPLAYMAINTANKANDASSIST,
            --     desc = OPTION_TOOLTIP_COMPACT_UNIT_FRAME_PROFILE_DISPLAYMAINTANKANDASSIST,
            --     proxy = 'PROXY_RAID_FRAME_TANK_ASSIST',
            --     order = 20.6,
            --     blizzard = true,
            --     editmode = true
            -- },
            -- displayBorder = {
            --     type = 'toggle',
            --     name = COMPACT_UNIT_FRAME_PROFILE_DISPLAYBORDER,
            --     desc = '',
            --     proxy = 'PROXY_RAID_FRAME_BORDER',
            --     order = 20.7,
            --     blizzard = true,
            --     editmode = true
            -- },
            -- displayNonBossDebuffs = {
            --     type = 'toggle',
            --     name = COMPACT_UNIT_FRAME_PROFILE_DISPLAYNONBOSSDEBUFFS,
            --     desc = OPTION_TOOLTIP_COMPACT_UNIT_FRAME_PROFILE_DISPLAYNONBOSSDEBUFFS,
            --     proxy = 'PROXY_RAID_FRAME_SHOW_DEBUFFS',
            --     order = 20.8,
            --     blizzard = true,
            --     editmode = true
            -- },
            -- displayOnlyDispellableDebuffs = {
            --     type = 'toggle',
            --     name = DISPLAY_ONLY_DISPELLABLE_DEBUFFS,
            --     desc = OPTION_TOOLTIP_COMPACT_UNIT_FRAME_PROFILE_DISPLAYONLYDISPELLABLEDEBUFFS,
            --     proxy = 'PROXY_RAID_FRAME_DISPELLABLE_DEBUFFS',
            --     order = 21.1,
            --     blizzard = true,
            --     editmode = true
            -- },
            -- healthText = {
            --     type = 'select',
            --     name = COMPACT_UNIT_FRAME_PROFILE_HEALTHTEXT,
            --     desc = OPTION_TOOLTIP_COMPACT_UNIT_FRAME_PROFILE_HEALTHTEXT,
            --     values = {['none'] = 'none', ['health'] = 'health', ['losthealth'] = 'losthealth', ['perc'] = 'perc'},
            --     proxy = 'PROXY_RAID_HEALTH_TEXT',
            --     order = 21.2,
            --     blizzard = true,
            --     editmode = true
            -- },
            -- frameHeight = {
            --     type = 'range',
            --     name = COMPACT_UNIT_FRAME_PROFILE_FRAMEHEIGHT,
            --     desc = '',
            --     proxy = 'PROXY_RAID_FRAME_HEIGHT',
            --     min = 20,
            --     max = 128,
            --     bigStep = 1,
            --     order = 22.1,
            --     editmode = true,
            --     blizzard = true
            -- },
            -- frameWidth = {
            --     type = 'range',
            --     name = COMPACT_UNIT_FRAME_PROFILE_FRAMEWIDTH,
            --     desc = '',
            --     proxy = 'PROXY_RAID_FRAME_WIDTH',
            --     min = 20,
            --     max = 256,
            --     bigStep = 1,
            --     order = 22.2,
            --     editmode = true,
            --     blizzard = true
            -- }
        }

        for k, v in pairs(moreOptions) do optionsRaid.args[k] = v end

        -- After moreOptions, so a hand-written entry can still override one of these
        -- if a flavour ever needs it.
        --
        -- And again after login, because this attempt usually fails. /df log raidopts
        -- showed everything present at runtime - Blizzard_EditMode loaded, the display
        -- info there, CompactRaidFrameContainer answering HasSetting for eleven
        -- settings - while the panel stayed empty. Options are built during our init,
        -- which happens before Blizzard's Edit Mode data and the raid container exist,
        -- so the first pass has nothing to read.
        --
        -- AceConfig reads the args table when the panel opens rather than caching it,
        -- so filling it later is enough; no re-registration needed.
        if BuildRaidEditModeArgs(optionsRaid.args) == 0 then
            local optsWatcher = CreateFrame('Frame')
            optsWatcher:RegisterEvent('PLAYER_ENTERING_WORLD')
            optsWatcher:SetScript('OnEvent', function(watcherSelf)
                -- One frame later: PLAYER_ENTERING_WORLD fires before some systems
                -- finish registering themselves with the Edit Mode manager.
                C_Timer.After(0, function()
                    if BuildRaidEditModeArgs(optionsRaid.args) > 0 then
                        watcherSelf:UnregisterAllEvents()
                    end
                end)
            end)
        end

        local defaultFuncs = {}

        -- Proxy
        -- RevertSetting("PROXY_RAID_FRAME_CLASS_COLORS");
        -- RevertSetting("PROXY_RAID_FRAME_PETS");
        -- RevertSetting("PROXY_RAID_FRAME_TANK_ASSIST");
        -- RevertSetting("PROXY_RAID_FRAME_BORDER");
        -- RevertSetting("PROXY_RAID_FRAME_SHOW_DEBUFFS");
        -- RevertSetting("PROXY_RAID_FRAME_KEEP_GROUPS_TOGETHER");
        -- RevertSetting("PROXY_RAID_FRAME_KEEP_HORIZONTAL_GROUPS");
        -- RevertSetting("PROXY_RAID_FRAME_SORT_BY");
        -- RevertSetting("PROXY_RAID_FRAME_POWER_BAR");
        -- RevertSetting("PROXY_RAID_FRAME_DISPELLABLE_DEBUFFS");
        -- RevertSetting("PROXY_RAID_HEALTH_TEXT");
        -- RevertSetting("PROXY_RAID_FRAME_HEIGHT");
        -- RevertSetting("PROXY_RAID_FRAME_WIDTH");
        -- RevertSetting("PROXY_RAID_AUTO_ACTIVATE");
        -- RevertSetting("PROXY_RAID_AUTO_ACTIVATE_2");
        -- RevertSetting("PROXY_RAID_AUTO_ACTIVATE_3");
        -- RevertSetting("PROXY_RAID_AUTO_ACTIVATE_5");
        -- RevertSetting("PROXY_RAID_AUTO_ACTIVATE_10");
        -- RevertSetting("PROXY_RAID_AUTO_ACTIVATE_15");
        -- RevertSetting("PROXY_RAID_AUTO_ACTIVATE_20");
        -- RevertSetting("PROXY_RAID_AUTO_ACTIVATE_40");

        optionsRaid.get = function(info)
            local key = info[1]
            local sub = info[2]

            -- The Edit Mode settings, read from Blizzard's registered raid system.
            -- Sliders show the converted value; dropdowns and checkboxes compare
            -- against the stored one, which is what the enum values are.
            local blizz = blizzRaidSettings[sub]
            if blizz then
                local stored = addonTable:GetRaidEditModeSettingBySetting(blizz.setting)

                if blizz.kind == 'toggle' then return (stored or 0) ~= 0 end
                if blizz.kind == 'range' then return ConvertSettingValue(blizz.info, stored or 0, true) end

                return stored
            end

            -- Same setting as the party page's copy, and on 1.15.9 it lives in
            -- the Edit Mode layout rather than in the dead useCompactPartyFrames
            -- CVar. One implementation, in Party.mixin.lua.
            if sub == 'useCompactPartyFrames' then
                return addonTable.SubModuleMixins['Party'].GetRaidStylePartyFrames()
            end

            -- Guarded: args now also holds the Edit Mode settings, which are not in
            -- moreOptions. They carry their own get/set so this should never be
            -- reached for them, but an unguarded index here would be an error rather
            -- than a fallback.
            if moreOptions[sub] and moreOptions[sub].proxy then
                -- proxy
                local value = Settings.GetValue(moreOptions[sub].proxy);
                return value;
            end

            -- Everything else out of our own profile. Party's copy of this has always
            -- ended in getOption; Raid's did not, and returned nil for anything it did
            -- not recognise - which would have silently broken the position, scale and
            -- visibility options the moment they were registered.
            return getOption(info)
        end

        optionsRaid.set = function(info, value)
            local key = info[1]
            local sub = info[2]

            -- Converted back to Blizzard's stored form before writing: the slider
            -- shows 72 to 144, the layout holds the difference from the minimum.
            local blizz = blizzRaidSettings[sub]
            if blizz then
                local stored = value
                if blizz.kind == 'toggle' then
                    stored = value and 1 or 0
                elseif blizz.kind == 'range' then
                    stored = ConvertSettingValue(blizz.info, value, false)
                end

                addonTable:SetRaidEditModeSettingBySetting(blizz.setting, stored)
                return
            end

            if sub == 'useCompactPartyFrames' then
                addonTable.SubModuleMixins['Party'].SetRaidStylePartyFrames(value)
                return
            end

            if moreOptions[sub] and moreOptions[sub].proxy then
                -- proxy
                Settings.SetValue(moreOptions[sub].proxy, value);
                -- InterfaceOverrides.SetRaidProfileOption(sub, value);
                -- local isSecure, taint = issecurevariable('CompactRaidGroup1Member1')
                -- print('SECURE? ', isSecure, ', TAINT? ', taint)
                return
            end

            -- Same fallback as the getter, and for the same reason.
            setOption(info, value)
        end
    end
    local optionsRaidEditmode = {
        name = 'Raid',
        desc = 'Raid',
        get = getOption,
        set = setOption,
        type = 'group',
        args = {
            raidFrameBtn = {
                type = 'execute',
                name = 'Raid Frame Settings',
                btnName = 'Open',
                func = function()
                    Settings.OpenToCategory(Settings.INTERFACE_CATEGORY_ID, RAID_FRAMES_LABEL);
                    PlaySound(SOUNDKIT.IG_MAINMENU_OPTION);
                end,
                order = 5,
                blizzard = true,
                editmode = true
            }
        }
    }

    -- Position, scale and visibility, the same tables every other unit frame here
    -- registers. Raid was the only one without them, which is why its edit mode entry
    -- offered nothing to change even once the selection was reachable.
    DF.Settings:AddPositionTable(Module, optionsRaid, 'raid', 'Raid', getDefaultStr, frameTable)
    DragonflightUIStateHandlerMixin:AddStateTable(Module, optionsRaid, 'raid', 'Raid', getDefaultStr)

    self.Options = optionsRaid;
    self.OptionsEditmode = optionsRaidEditmode;
end

function SubModuleMixin:Setup()
    local function setDefaultSubValues(sub)
        self.ModuleRef:SetDefaultSubValues(sub)
    end

    DF.ConfigModule:RegisterSettingsData('raid', 'unitframes', {
        options = self.Options
        -- default = function()
        --     setDefaultSubValues('raid')
        -- end
    })
    --
    self:AddRaidframeRoleIcons()

    -- edit mode
    local EditModeModule = DF:GetModule('Editmode');
    local initRaid = function()
        --         
        -- Our own holder, not Blizzard's resize frame.
        --
        -- This used to be CompactRaidFrameManagerContainerResizeFrame. That frame
        -- lives under CompactRaidFrameManager, which the client keeps hidden now that
        -- raid frames are an Edit Mode system, and it has no anchor points - /df log
        -- frame reported "shown=true visible=false points=0". So the selection existed
        -- but could never be seen or dragged, which is why the raid entry in our edit
        -- mode did nothing while the party one worked.
        local f = self:EnsureRaidMoveFrame()
        if not f then return end

        local resizer = _G['CompactRaidFrameManagerContainerResizeFrameResizer']
        if resizer then resizer:SetFrameLevel(15) end

        local fakeRaid = CreateFrame('Frame', 'DragonflightUIEditModeRaidFramePreview', f,
                                     'DFEditModePreviewRaidFrameTemplate')
        fakeRaid:OnLoad()
        fakeRaid:SetPoint('TOPLEFT', f, 'TOPLEFT', 4, -7)
        fakeRaid:SetPoint('BOTTOMRIGHT', f, 'BOTTOMRIGHT', 0, 0)

        -- fakeRaid:ClearAllPoints()
        -- fakeRaid:SetPoint('TOPLEFT', UIParent, 'CENTER', -50, 50)
        -- fakeRaid:SetParent(UIParent)

        fakeRaid:Show()

        self.PreviewRaid = fakeRaid;

        EditModeModule:AddEditModeToFrame(f)

        f.DFEditModeSelection:SetGetLabelTextFunction(function()
            return self.Options.name
        end)

        f.DFEditModeSelection:ClearAllPoints()
        f.DFEditModeSelection:SetPoint('TOPLEFT', f, 'TOPLEFT', 0, -7)
        f.DFEditModeSelection:SetPoint('BOTTOMRIGHT', f, 'BOTTOMRIGHT', 0, 11)

        f.DFEditModeSelection:RegisterOptions({
            options = self.Options,
            extra = self.OptionsEditmode,
            -- parentExtra = FocusFrame,
            default = function()
                -- setDefaultSubValues('focus')
            end,
            moduleRef = self.ModuleRef,
            -- The old CompactRaidFrameManager_SetSetting('Locked', ...) pair is gone
            -- from both of these, along with the ResizeFrame_SavePosition call and the
            -- CompactRaidFrameManager_UpdateContainerVisibility hook that kept
            -- re-unlocking it.
            --
            -- All of that drove Blizzard's old raid manager, which the client now keeps
            -- hidden. Dragging happens on our own holder and its position is stored in
            -- the DragonflightUI profile through the position table, the same as every
            -- other unit frame here - so writing Blizzard's resize-frame position was
            -- both pointless and a write into a frame we no longer use.
            showFunction = function() f:Show() end,
            hideFunction = function() end
        });

        fakeRaid:UpdateState(nil)
    end

    -- Recorded so /df log raidopts can say whether the edit mode selection was ever
    -- built, and if not, which half of this gate stopped it. HasLoadedCUFProfiles is a
    -- Blizzard global and CompactUnitFrameProfiles is the pre-Edit-Mode profile system,
    -- neither of which is guaranteed to be there now that raid frames are a system.
    addonTable.RaidInitDiag = {
        hasLoadedCUFProfilesFn = type(HasLoadedCUFProfiles),
        profilesTable = CompactUnitFrameProfiles ~= nil,
        variablesLoaded = CompactUnitFrameProfiles and CompactUnitFrameProfiles.variablesLoaded or false,
        initRan = false
    }

    local function initRaidTracked()
        if addonTable.RaidInitDiag.initRan then return end
        addonTable.RaidInitDiag.initRan = true
        initRaid()
    end

    -- The CompactUnitFrameProfiles gate that used to be here is gone.
    --
    -- It required HasLoadedCUFProfiles() and CompactUnitFrameProfiles.variablesLoaded,
    -- and /df log raidopts showed why nothing ever appeared: on 1.15.9
    -- CompactUnitFrameProfiles does not exist at all, so the condition could never
    -- become true and the fallback sat waiting for COMPACT_UNIT_FRAME_PROFILES_LOADED,
    -- an event that never fires. initRan stayed false and the selection was never built.
    --
    -- That gate also no longer guards anything. It was there for the
    -- CompactRaidFrameManager_SetSetting and ResizeFrame_SavePosition calls, which
    -- drove the pre-Edit-Mode raid manager and have been removed. What initRaid needs
    -- now is our own XML holder and the Editmode module, both of which are already
    -- there by the time Setup runs.
    --
    -- PLAYER_ENTERING_WORLD is still worth waiting on as a second attempt, because the
    -- raid container registers itself with the Edit Mode manager during load.
    initRaidTracked()

    if not addonTable.RaidInitDiag.initRan then
        local waitFrame = CreateFrame('Frame')
        waitFrame:RegisterEvent('PLAYER_ENTERING_WORLD')
        waitFrame:SetScript('OnEvent', function(watcherSelf)
            watcherSelf:UnregisterAllEvents()
            initRaidTracked()
        end)
    end
end

function SubModuleMixin:OnEvent(event, ...)
end

-- The anchor the raid container is parked on.
--
-- From XML, never CreateFrame. CompactRaidFrameContainer is protected and gets
-- reparented onto this frame; a Lua-created global would be insecure and Blizzard
-- would taint itself updating the raid members, the same way the pooled party members
-- broke. Load.xml carries the reasoning in full.
function SubModuleMixin:EnsureRaidMoveFrame()
    if self.RaidMoveFrame then return self.RaidMoveFrame end

    local moveFrame = _G['DragonflightUIRaidMoveFrame']
    if not moveFrame then return nil end

    moveFrame:SetParent(UIParent)
    moveFrame:SetFrameStrata('LOW')
    moveFrame:SetFrameLevel(2)
    moveFrame:EnableMouse(false)
    moveFrame:SetSize(200, 200)
    self.RaidMoveFrame = moveFrame

    return moveFrame
end

function SubModuleMixin:UpdateState(state)
    self.state = state;
    self:Update();
end

function SubModuleMixin:Update()
    local state = self.state;
    if not state then return end

    local holder = self:EnsureRaidMoveFrame()
    if not holder then return end

    local container = _G['CompactRaidFrameContainer']

    -- One-time calibration, so enabling this feature does not move anybody's raid
    -- frames. Whatever position the container already has becomes the stored default;
    -- after that the profile is the source of truth.
    if not state.calibrated and container and container:GetNumPoints() > 0 then
        local point, relativeTo, relativePoint, x, y = container:GetPoint(1)
        local relName = (relativeTo and relativeTo.GetName and relativeTo:GetName()) or 'UIParent'

        state.anchor = point or state.anchor
        state.anchorParent = relativePoint or state.anchorParent
        state.anchorFrame = relName
        state.x = x or 0
        state.y = y or 0
        state.calibrated = true
    end

    holder:SetScale(state.scale or 1.0)

    -- Helper resolves the anchor frame and rejects a chain that would close a loop,
    -- falling back to UIParent and reporting it once per session. The other unit
    -- frames go through the same pair, so a bad anchor behaves the same everywhere.
    local parent, legal, chain = Helper:ResolveAnchorParent(holder, state)
    if not legal then Helper:WarnIllegalAnchor(holder, chain) end

    holder:ClearAllPoints()
    holder:SetPoint(state.anchor or 'TOPLEFT', parent, state.anchorParent or 'TOPLEFT', state.x or 0, state.y or 0)
    holder:Show()

    -- Park Blizzard's container on the holder, out of combat only.
    --
    -- Protected frame: the client refuses SetParent and SetPoint on it mid-fight, and
    -- reparenting is why this holder has to come from XML. Blizzard's Edit Mode also
    -- re-places the container from its layout at login, so this runs from Update,
    -- which the module calls again on every settings apply.
    if container and not Helper:IsCombatLocked() then
        local ok, err = pcall(function()
            if container:GetParent() ~= holder then container:SetParent(holder) end
            container:ClearAllPoints()
            container:SetPoint('TOPLEFT', holder, 'TOPLEFT', 0, 0)
        end)
        if not ok then geterrorhandler()('DFUI raid container anchor: ' .. tostring(err)) end
    end
end

function SubModuleMixin:AddRaidframeRoleIcons()
    local function updateRoleIcons(f)
        if not f.roleIcon then
            return
        else
            f.roleIcon:SetDrawLayer('OVERLAY')
            local size = math.min(f.roleIcon:GetHeight(), 12);
            local role = UnitGroupRolesAssigned(f.unit);
            if (role == "TANK" or role == "HEALER" or role == "DAMAGER") then
                f.roleIcon:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES");
                f.roleIcon:SetTexCoord(GetTexCoordsForRoleSmallCircle(role));
                f.roleIcon:Show();
                f.roleIcon:SetSize(size, size);
                if strmatch(tostring(f.unit), 'target') then f.roleIcon:Hide() end
            else
                f.roleIcon:Hide();
                f.roleIcon:SetSize(1, size);
            end
        end
    end
    hooksecurefunc("CompactUnitFrame_UpdateRoleIcon", function(f)
        --
        -- print('CompactUnitFrame_UpdateRoleIcon')
        updateRoleIcons(f)
    end)
end
