local addonName, addonTable = ...;
local DF = addonTable.DF;
local L = addonTable.L;
local Helper = addonTable.Helper;
local LSM = LibStub('LibSharedMedia-3.0')
local RangeCheck = LibStub("LibRangeCheck-3.0")
local AuraDurations = LibStub and LibStub('AuraDurations-1.0', true)

local subModuleName = 'Target';
local SubModuleMixin = {};
addonTable.SubModuleMixins[subModuleName] = SubModuleMixin;

-- TODOTBC
local TextStatusBar_UpdateTextString_orig = TextStatusBar_UpdateTextString;
local function TextStatusBar_UpdateTextString(f)
    if TextStatusBar_UpdateTextString_orig then
        TextStatusBar_UpdateTextString_orig(f)
    elseif f.UpdateTextString then
        f:UpdateTextString()
    end
end

function SubModuleMixin:Init()
    self.ModuleRef = DF:GetModule('Unitframe')
    self:SetDefaults()
    self:SetupOptions()

    local f = _G['DragonflightUITargetFrame']
    if f then
        f:SetSize(232, 100)
        f:SetParent(UIParent)
        f:SetScale(1.0)
        f:SetClampedToScreen(true)
        f:SetMovable(true)
        f:SetFrameStrata('LOW')
        f:EnableMouse(false)
        f:Hide()
    end

    self.famous = {['Norbert'] = true}

    self:SetScript('OnEvent', self.OnEvent);
end

function SubModuleMixin:SetDefaults()
    local defaults = {
        classcolor = false,
        gradient = false,
        reactioncolor = false,
        classicon = false,
        breakUpLargeNumbers = true,
        enableNumericThreat = true,
        numericThreatAnchor = 'TOP',
        enableThreatGlow = true,
        comboPointsOnPlayerFrame = false,
        hideComboPoints = false,
        hideNameBackground = false,
        hidePVP = false,
        fadeOut = false,
        fadeOutDistance = 40,
        scale = 1.0,
        override = false,
        anchorFrame = 'UIParent',
        customAnchorFrame = '',
        anchor = 'TOPLEFT',
        anchorParent = 'TOPLEFT',
        x = 250,
        y = -4,
        customHealthBarTexture = 'Default',
        customPowerBarTexture = 'Default',
        -- buff - from AuraDurations
        auraSizeSmall = 17, -- SMALL_AURA_SIZE,
        auraSizeLarge = 21, -- LARGE_AURA_SIZE,
        auraStartX = 5, -- AURA_START_X 5
        auraStartY = 32, -- AURA_START_Y 32
        auraOffsetY = 1, -- AURA_OFFSET_Y,
        noDebuffFilter = true, -- noBuffDebuffFilterOnTarget
        dynamicBuffSize = true, -- showDynamicBuffSize
        auraRowWidth = 122, -- AURA_ROW_WIDTH
        totAuraRowWidth = 101, -- TOT_AURA_ROW_WIDTH
        numTotAuraRows = 2, -- NUM_TOT_AURA_ROWS
        -- Visibility
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
        hideCustomCond = ''
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

    local optionsTarget = {
        name = L["TargetFrameName"],
        desc = L["TargetFrameDesc"],
        advancedName = 'TargetFrame',
        sub = "target",
        get = getOption,
        set = setOption,
        type = 'group',
        args = {
            headerStyling = {
                type = 'header',
                name = L["TargetFrameStyle"],
                desc = '',
                order = 20,
                isExpanded = true,
                editmode = true
            },
            classcolor = {
                type = 'toggle',
                name = L["TargetFrameClassColor"],
                desc = L["TargetFrameClassColorDesc"] .. getDefaultStr('classcolor', 'target'),
                group = 'headerStyling',
                order = 2,
                editmode = true
            },
            gradient = {
                type = 'toggle',
                name = L["PlayerFrameGradientColor"],
                desc = L["PlayerFrameGradientColorDesc"] .. getDefaultStr('gradient', 'target'),
                group = 'headerStyling',
                order = 2.1,
                new = true,
                editmode = true
            },
            reactioncolor = {
                type = 'toggle',
                name = L["TargetFrameReactionColor"],
                desc = L["TargetFrameReactionColorDesc"] .. getDefaultStr('reactioncolor', 'target'),
                group = 'headerStyling',
                order = 3,
                new = false,
                editmode = true
            },
            customHealthBarTexture = {
                type = 'select',
                name = L["PlayerFrameCustomHealthbarTexture"],
                desc = L["PlayerFrameCustomHealthbarTextureDesc"] .. getDefaultStr('customHealthBarTexture', 'target'),
                dropdownValuesFunc = Helper:CreateSharedMediaStatusBarGenerator(function(name)
                    return getOption({'target', 'customHealthBarTexture'}) == name;
                end, function(name)
                    setOption({'target', 'customHealthBarTexture'}, name)
                end),
                group = 'headerStyling',
                order = 4,
                new = true
            },
            customPowerBarTexture = {
                type = 'select',
                name = L["PlayerFrameCustomPowerbarTexture"],
                desc = L["PlayerFrameCustomPowerbarTextureDesc"] .. getDefaultStr('customPowerBarTexture', 'target'),
                dropdownValuesFunc = Helper:CreateSharedMediaStatusBarGenerator(function(name)
                    return getOption({'target', 'customPowerBarTexture'}) == name;
                end, function(name)
                    setOption({'target', 'customPowerBarTexture'}, name)
                end),
                group = 'headerStyling',
                order = 5,
                new = true
            },
            classicon = {
                type = 'toggle',
                name = L["TargetFrameClassIcon"],
                desc = L["TargetFrameClassIconDesc"] .. getDefaultStr('classicon', 'target'),
                group = 'headerStyling',
                order = 1,
                disabled = true,
                new = false,
                editmode = true
            },
            breakUpLargeNumbers = {
                type = 'toggle',
                name = L["TargetFrameBreakUpLargeNumbers"],
                desc = L["TargetFrameBreakUpLargeNumbersDesc"] .. getDefaultStr('breakUpLargeNumbers', 'target'),
                group = 'headerStyling',
                order = 3.5,
                editmode = true
            },
            enableThreatGlow = {
                type = 'toggle',
                name = L["TargetFrameThreatGlow"],
                desc = L["TargetFrameThreatGlowDesc"] .. getDefaultStr('enableThreatGlow', 'target'),
                group = 'headerStyling',
                order = 10,
                disabled = true,
                editmode = true
            },
            hideNameBackground = {
                type = 'toggle',
                name = L["TargetFrameHideNameBackground"],
                desc = L["TargetFrameHideNameBackgroundDesc"] .. getDefaultStr('hideNameBackground', 'target'),
                group = 'headerStyling',
                order = 11,
                new = false,
                editmode = true
            },
            hidePVP = {
                type = 'toggle',
                name = L["PlayerFrameHidePVP"],
                desc = L["PlayerFrameHidePVPDesc"] .. getDefaultStr('hidePVP', 'target'),
                group = 'headerStyling',
                order = 11.5,
                new = true,
                editmode = true
            },
            comboPointsOnPlayerFrame = {
                type = 'toggle',
                name = L["TargetFrameComboPointsOnPlayerFrame"],
                desc = L["TargetFrameComboPointsOnPlayerFrameDesc"] ..
                    getDefaultStr('comboPointsOnPlayerFrame', 'target'),
                group = 'headerStyling',
                order = 12,
                new = false,
                editmode = true
            },
            hideComboPoints = {
                type = 'toggle',
                name = L["TargetFrameHideComboPoints"],
                desc = L["TargetFrameHideComboPointsDesc"] .. getDefaultStr('hideComboPoints', 'target'),
                group = 'headerStyling',
                order = 12.5,
                new = false,
                editmode = true
            },
            fadeOut = {
                type = 'toggle',
                name = L["TargetFrameFadeOut"],
                desc = L["TargetFrameFadeOutDesc"] .. getDefaultStr('fadeOut', 'target'),
                group = 'headerStyling',
                order = 9.5,
                new = false,
                editmode = true
            },
            fadeOutDistance = {
                type = 'range',
                name = L["TargetFrameFadeOutDistance"],
                desc = L["TargetFrameFadeOutDistanceDesc"] .. getDefaultStr('fadeOutDistance', 'target'),
                min = 0,
                max = 50,
                bigStep = 1,
                order = 9.6,
                group = 'headerStyling',
                new = false,
                editmode = true
            }
        }
    }

    if DF.Era then
        -- numericThreatAnchor
        optionsTarget.args['enableNumericThreat'] = {
            type = 'toggle',
            name = L["TargetFrameNumericThreat"],
            desc = L["TargetFrameNumericThreatDesc"] .. getDefaultStr('enableNumericThreat', 'target'),
            group = 'headerStyling',
            order = 9,
            disabled = not DF.Era,
            editmode = true
        }
        optionsTarget.args['numericThreatAnchor'] = {
            type = 'select',
            name = L["TargetFrameNumericThreatAnchor"],
            desc = L["TargetFrameNumericThreatAnchorDesc"] .. getDefaultStr('numericThreatAnchor', 'target'),
            dropdownValues = DF.Settings.DropdownCrossAnchorTable,
            order = 9.5,
            group = 'headerStyling',
            editmode = true
        }
    end

    if true then
        local moreOptions = {
            targetOfTarget = {
                type = 'toggle',
                name = SHOW_TARGET_OF_TARGET_TEXT,
                desc = OPTION_TOOLTIP_SHOW_TARGET_OF_TARGET,
                group = 'headerStyling',
                order = 15,
                blizzard = true,
                editmode = true
            },
            buffsOnTop = {
                type = 'toggle',
                name = BUFFS_ON_TOP,
                desc = '',
                group = 'headerStyling',
                order = 16,
                blizzard = true,
                editmode = true
            }
        }

        if true then
            moreOptions['headerBuffs'] = {
                type = 'header',
                name = L["TargetFrameHeaderBuffs"],
                desc = '',
                order = 19,
                isExpanded = true,
                editmode = true
            }
            moreOptions['buffsOnTop'].group = 'headerBuffs'
            moreOptions['buffsOnTop'].order = 0.5

            moreOptions['auraSizeSmall'] = {
                type = 'range',
                name = L["TargetFrameAuraSizeSmall"],
                desc = L["TargetFrameAuraSizeSmallDesc"] .. getDefaultStr('auraSizeSmall', 'target'),
                min = 8,
                max = 64,
                bigStep = 1,
                group = 'headerBuffs',
                order = 4,
                new = true,
                editmode = true
            }
            moreOptions['auraSizeLarge'] = {
                type = 'range',
                name = L["TargetFrameAuraSizeLarge"],
                desc = L["TargetFrameAuraSizeLargeDesc"] .. getDefaultStr('auraSizeLarge', 'target'),
                min = 8,
                max = 64,
                bigStep = 1,
                group = 'headerBuffs',
                order = 2,
                new = true,
                editmode = true
            }
            moreOptions['noDebuffFilter'] = {
                type = 'toggle',
                name = L["TargetFrameNoDebuffFilter"],
                desc = L["TargetFrameNoDebuffFilterDesc"] .. getDefaultStr('noDebuffFilter', 'target'),
                group = 'headerBuffs',
                order = 1,
                new = true,
                editmode = true
            }
            moreOptions['dynamicBuffSize'] = {
                type = 'toggle',
                name = L["TargetFrameDynamicBuffSize"],
                desc = L["TargetFrameDynamicBuffSizeDesc"] .. getDefaultStr('dynamicBuffSize', 'target'),
                group = 'headerBuffs',
                order = 3,
                new = true,
                editmode = true
            }
            -- advanced
            moreOptions['headerBuffsAdvanced'] = {
                type = 'header',
                name = L["TargetFrameHeaderBuffsAdvanced"],
                desc = '',
                order = 19.5,
                isExpanded = false,
                editmode = true
            }
            moreOptions['auraOffsetY'] = {
                type = 'range',
                name = L["TargetFrameAuraOffsetY"],
                desc = L["TargetFrameAuraOffsetYDesc"] .. getDefaultStr('auraOffsetY', 'target'),
                min = 0,
                max = 16,
                bigStep = 0.25,
                group = 'headerBuffsAdvanced',
                order = 10,
                new = true,
                editmode = true
            }
            moreOptions['auraRowWidth'] = {
                type = 'range',
                name = L["TargetFrameAuraRowWidth"],
                desc = L["TargetFrameAuraRowWidthDesc"] .. getDefaultStr('auraRowWidth', 'target'),
                min = 1,
                max = 256,
                bigStep = 1,
                group = 'headerBuffsAdvanced',
                order = 11,
                new = true,
                editmode = true
            }
            moreOptions['totAuraRowWidth'] = {
                type = 'range',
                name = L["TargetFrameAuraRowWidthToT"],
                desc = L["TargetFrameAuraRowWidthToTDesc"] .. getDefaultStr('totAuraRowWidth', 'target'),
                min = 1,
                max = 256,
                bigStep = 1,
                group = 'headerBuffsAdvanced',
                order = 12,
                new = true,
                editmode = true
            }
            moreOptions['numTotAuraRows'] = {
                type = 'range',
                name = L["TargetFrameToTAuraRows"],
                desc = L["TargetFrameToTAuraRowsDesc"] .. getDefaultStr('numTotAuraRows', 'target'),
                min = 0,
                max = 8,
                bigStep = 1,
                group = 'headerBuffsAdvanced',
                order = 13,
                new = true,
                editmode = true
            }
        end

        for k, v in pairs(moreOptions) do optionsTarget.args[k] = v end

        optionsTarget.get = function(info)
            local key = info[1]
            local sub = info[2]

            if sub == 'targetOfTarget' then
                local tot = C_CVar.GetCVar("showTargetOfTarget");
                if tot == '1' then
                    return true
                else
                    return false
                end
            elseif sub == 'buffsOnTop' then
                -- Our own profile, not Blizzard's Edit Mode layout.
                --
                -- Deliberately unset by default: as long as nobody has touched
                -- this here, report whatever the client currently has, so an
                -- upgrade never flips a choice the player made in Blizzard's UI.
                -- The first toggle writes our profile and we own it from then on.
                local stored = Module.db and Module.db.profile and Module.db.profile.target and
                                   Module.db.profile.target.buffsOnTop
                if stored ~= nil then return stored and true or false end
                return TARGET_FRAME_BUFFS_ON_TOP and true or false
            else
                return getOption(info)
            end
        end

        optionsTarget.set = function(info, value)
            local key = info[1]
            local sub = info[2]

            if sub == 'targetOfTarget' then
                if value then
                    SetCVar("showTargetOfTarget", "1");
                else
                    SetCVar("showTargetOfTarget", "0");
                end
            elseif sub == 'buffsOnTop' then
                local val = value and true or false

                -- Store in our profile, then apply. Blizzard's applier for this
                -- setting is UpdateSystemSettingBuffsOnTop, and all it does is
                -- set self.buffsOnTop and refresh the auras - which is what the
                -- next three lines do. The layout write that used to be here
                -- bought nothing but a round trip to Blizzard's server.
                if Module.db and Module.db.profile and Module.db.profile.target then
                    Module.db.profile.target.buffsOnTop = val
                end

                TARGET_FRAME_BUFFS_ON_TOP = val
                TargetFrame.buffsOnTop = val
                -- Not TargetFrame_UpdateAuras directly: driving it from here
                -- can make Blizzard create a TargetFrameDebuffN global inside
                -- our tainted execution, which taints that global for the
                -- session. See Helper:RefreshUnitAuras.
                Helper:RefreshUnitAuras(TargetFrame)
            else
                setOption(info, value)
            end
        end
    end
    DF.Settings:AddPositionTable(Module, optionsTarget, 'target', 'Target', getDefaultStr,
                                 frameTableWithout('TargetFrame'))

    DragonflightUIStateHandlerMixin:AddStateTable(Module, optionsTarget, 'target', 'Target', getDefaultStr)
    local optionsTargetEditmode = {
        name = 'Target',
        desc = 'Targetframedesc',
        get = getOption,
        set = setOption,
        type = 'group',
        args = {
            resetPosition = {
                type = 'execute',
                name = L["ExtraOptionsPreset"],
                btnName = L["ExtraOptionsResetToDefaultPosition"],
                desc = L["ExtraOptionsPresetDesc"],
                func = function()
                    local dbTable = Module.db.profile.target
                    local defaultsTable = self.Defaults
                    -- {scale = 1.0, anchor = 'TOPLEFT', anchorParent = 'TOPLEFT', x = -19, y = -4}
                    setPreset(dbTable, {
                        scale = defaultsTable.scale,
                        anchor = defaultsTable.anchor,
                        anchorParent = defaultsTable.anchorParent,
                        anchorFrame = defaultsTable.anchorFrame,
                        x = defaultsTable.x,
                        y = defaultsTable.y
                    })
                end,
                order = 16,
                editmode = true,
                new = false
            }
        }
    }
    self.Options = optionsTarget;
    self.OptionsEditmode = optionsTargetEditmode;
end

function SubModuleMixin:Setup()
    local function setDefaultSubValues(sub)
        self.ModuleRef:SetDefaultSubValues(sub)
    end

    DF.ConfigModule:RegisterSettingsData('target', 'unitframes', {
        options = self.Options,
        default = function()
            setDefaultSubValues('target')
        end
    })
    --
    self:RegisterEvent('PLAYER_TARGET_CHANGED')
    --
    self:ChangeTargetFrame()
    self:ReApplyTargetFrame()
    self:ChangeTargetComboFrame()

    self:AddMobhealth()
    self:CreatThreatIndicator();

    -- Two hooks, and OnValueChanged is the one that does the work.
    --
    -- UnitFrame_Initialize calls UnitFrameHealthBar_Initialize(unit, healthbar, healthtext,
    -- true) at UnitFrame.lua:114 - frequentUpdates is hard-coded for every unit frame. That
    -- means UNIT_HEALTH is never registered on this bar: Blizzard polls it in
    -- UnitFrameHealthBar_OnUpdate, which calls SetValue, which fires OnValueChanged. So
    -- UnitFrameHealthBar_Update runs on target changes and little else, and hooking it alone
    -- would leave the re-apply out of every health change - measured on the party frames,
    -- where the same mistake cost the bar colour: 4 matches against 21 repaints needed.
    --
    -- _Update still earns its place: it covers the setup pass on a target change, where the
    -- value has not moved yet and OnValueChanged never fires.
    hooksecurefunc('UnitFrameHealthBar_Update', function(statusbar, unit)
        if statusbar == TargetFrameHealthBar and (unit == 'target' or unit == nil) then
            self:ReApplyTargetFrame()
        end
    end)

    if type(UnitFrameHealthBar_OnValueChanged) == 'function' then
        hooksecurefunc('UnitFrameHealthBar_OnValueChanged', function(statusbar)
            if statusbar == TargetFrameHealthBar then self:ReApplyTargetFrame() end
        end)
    end

    self.ModuleRef:RegisterManaBarCallback(TargetFrameManaBar, function()
        self:ReApplyTargetFrame()
    end)

    if TargetFrame_CheckFaction then
        hooksecurefunc('TargetFrame_CheckFaction', function(f)
            --
            if f ~= TargetFrame then return end
            if self.ModuleRef.db.profile.target.hidePVP then f.pvpIcon:Hide() end
        end)
    else
        hooksecurefunc(TargetFrame, 'CheckFaction', function(f)
            --
            if f ~= TargetFrame then return end
            if self.ModuleRef.db.profile.target.hidePVP then f.pvpIcon:Hide() end
        end)
    end

    local f = _G['DragonflightUITargetFrame']
    f:SetSize(232, 100)
    f:SetParent(UIParent)
    f:SetScale(1.0)
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:SetFrameStrata('LOW')

    -- A holder only positions things, so it must never take mouse input. It is
    -- parented to UIParent and keeps its anchors when the unit frame is hidden,
    -- so any input it accepts is input swallowed over an empty patch of screen
    -- - no target, and the right-drag that should turn the camera does nothing.
    -- The bar holders inherit the same secure templates and have disabled this
    -- since day one (DragonflightUIActionbarMixin:Init); the unit frame holders
    -- never did.
    f:EnableMouse(false)

    f:Hide()

    if addonTable.OverrideBlizzEditmode then
        addonTable:OverrideBlizzEditmode(TargetFrame, 'CENTER', f, 'CENTER', 0, 0)
    end

    -- state
    Mixin(f, DragonflightUIStateHandlerMixin)
    f:InitStateHandler()
    f:SetUnit('target')
    f:SetHideFrame(TargetFrame, 1)

    -- editmode
    local EditModeModule = DF:GetModule('Editmode');
    local fakeTarget = CreateFrame('Frame', 'DragonflightUIEditModeTargetFramePreview', UIParent,
                                   'DFEditModePreviewTargetTemplate')
    fakeTarget:OnLoad()
    fakeTarget:SetPoint('CENTER', f, 'CENTER', 0, 0)
    self.PreviewTarget = fakeTarget;

    EditModeModule:AddEditModeToFrame(f)

    f.DFEditModeSelection:SetGetLabelTextFunction(function()
        return self.Options.name
    end)

    f.DFEditModeSelection:RegisterOptions({
        options = self.Options,
        extra = self.OptionsEditmode,
        -- parentExtra = TargetFrame,
        default = function()
            setDefaultSubValues('target')
        end,
        moduleRef = self.ModuleRef,
        showFunction = function()
            --
            -- TargetFrame.unit = 'player';
            -- TargetFrame_Update(TargetFrame);
            -- TargetFrame:Show()
            -- TargetFrame:SetAlpha(0)
            fakeTarget:Show()
        end,
        hideFunction = function()
            --        
            -- TargetFrame.unit = 'target';
            -- TargetFrame_Update(TargetFrame);
            -- TargetFrame:SetAlpha(1)
            fakeTarget:Hide()
        end
    });
end

function SubModuleMixin:OnEvent(event, ...)
    if event == 'PLAYER_TARGET_CHANGED' then self:ReApplyTargetFrame() end
end

function SubModuleMixin:UpdateState(state)
    self.state = state;
    self:Update();
end

function SubModuleMixin:Update()
    local state = self.state;
    if not state then return end

    local f_orig = TargetFrame
    local f = _G['DragonflightUITargetFrame']

    local parent;
    if DF.Settings.ValidateFrame(state.customAnchorFrame) then
        parent = _G[state.customAnchorFrame]
    else
        parent = _G[state.anchorFrame]
    end

    f:SetScale(state.scale)
    f:ClearAllPoints()
    f:SetPoint(state.anchor, parent, state.anchorParent, state.x, state.y)

    -- Deferred rather than skipped. SetPoint and SetScale on a protected frame are refused
    -- in combat, and a plain `if not InCombatLockdown()` drops the change on the floor -
    -- the frame then keeps the old position until something else happens to call Update
    -- again. DeferOutOfCombat runs it now when it can and once combat drops when it cannot,
    -- keyed by label so repeated calls collapse into one.
    Helper:DeferOutOfCombat('target frame position', function()
        f_orig:ClearAllPoints()
        f_orig:SetPoint('CENTER', f, 'CENTER', 0, 0)
        f_orig:SetScale(state.scale)
    end)

    self:ReApplyTargetFrame()
    -- Module.ReApplyToT()
    TargetFrameHealthBar.breakUpLargeNumbers = state.breakUpLargeNumbers
    TextStatusBar_UpdateTextString(TargetFrameHealthBar)
    self:UpdateComboFrameState(state)
    TargetFrameNameBackground:SetShown(not state.hideNameBackground)

    -- buffsOnTop is ours now, so this is where it gets re-asserted.
    --
    -- Blizzard drives its copy of this setting off the Edit Mode layout at login
    -- (UpdateSystemSettingBuffsOnTop). Keeping the value in the layout - which is
    -- what this addon used to do - was only ever a way of making that login pass
    -- produce the right answer. Applying it here does the same thing without a
    -- server-side copy, and it also survives Blizzard re-applying its layout.
    --
    -- nil means the player has never set it here, so Blizzard's value stands.
    --
    -- TargetFrame.buffsOnTop is a field of ours on a protected frame, and Blizzard reads it
    -- four times in TargetFrame.lua - 596 in UpdateAuras, then 1083, 1089 and 1095 in the
    -- aura row layout. By the rule that cost us lockColor on the party bars, that makes it a
    -- taint seed, and it is left in place knowingly:
    --
    -- Blizzard never writes this field. Not in TargetFrame.lua, not in TargetFrame.xml - it
    -- only ever reads it, and TARGET_FRAME_BUFFS_ON_TOP is not consulted on this client. So
    -- the field is nil unless an addon sets it, and without setting it the option cannot
    -- work at all. There is no second way in, the way hooksecurefunc was for the colour.
    --
    -- What makes it bearable is the blast radius. The party members are pooled and Blizzard
    -- re-assigns them with SetAttribute, Show and Hide on every roster change, which is what
    -- the client refuses in combat. TargetFrame is a single frame whose unit attribute never
    -- changes, so a tainted execution there has no protected call to break. If that
    -- assumption ever proves wrong, the honest fix is to drop the option rather than to
    -- keep writing the field.
    if state.buffsOnTop ~= nil then
        local buffsOnTop = state.buffsOnTop and true or false
        TARGET_FRAME_BUFFS_ON_TOP = buffsOnTop
        TargetFrame.buffsOnTop = buffsOnTop
        if UnitExists('target') and not InCombatLockdown() then
            Helper:RefreshUnitAuras(TargetFrame)
        end
    end

    if AuraDurations and AuraDurations.frame then
        AuraDurations.frame:SetState(state)
    end
    UnitFramePortrait_Update(TargetFrame)
    f:UpdateStateHandler(state)

    self.PreviewTarget:UpdateState(state);
end

function SubModuleMixin:ChangeTargetFrameGeneral(self, frame)
    local tex2xBase = 'Interface\\Addons\\DragonflightUI\\Textures\\Unitframe2x\\'

    -- The frame art and the in-combat glow are the same picture - the glow file
    -- is the frame with red drawn around it, and both atlases are 512x256 with
    -- the art in the same place. So they have to be cut, sized and positioned
    -- identically or the glow traces a different outline than the frame it is
    -- supposed to be glowing around. Shared here rather than written twice,
    -- which is how they drifted apart.
    local ART_L, ART_R, ART_T, ART_B = 0, 384 / 512, 0, 134 / 256
    local ART_W, ART_H = 192, 67
    local ART_X, ART_Y = -20, 6

    local fName = frame:GetName()
    local port = frame.portrait or frame.Portrait or _G[fName .. 'Portrait']
    local healthBar = frame.healthbar or frame.HealthBar or _G[fName .. 'HealthBar']
    local manaBar = frame.manabar or frame.ManaBar or _G[fName .. 'ManaBar']
    local name = frame.name or frame.Name or _G[fName .. 'TextureFrameName'] or _G[fName .. 'Name']
    -- 1.15.9 exposes this as parentKey 'nameBackground' (lower case); with a
    -- nil lookup the reskin block below silently skips and the Blizzard
    -- reaction-colored gradient stays at its DEFAULT anchor - rendering as a
    -- colored bar hanging under the rearranged frame (blue on friendly
    -- players). CheckClassification re-shows it on every target change.
    local nameBackground = frame.NameBackground or frame.nameBackground or
                               _G[fName .. 'NameBackground'] or _G[fName .. 'TextureFrameNameBackground'];
    local flash = frame.flash or frame.Flash or _G[fName .. 'Flash'];
    local levelText = frame.LevelText or _G[fName .. 'TextureFrameLevelText'];
    local deadText = frame.deadText or frame.DeadText or _G[fName .. 'TextureFrameDeadText'];
    local unconsciousText = frame.unconsciousText or frame.UnconsciousText or
                                _G[fName .. 'TextureFrameUnconsciousText'];

    local portDelta = 0; -- not 100% centered without it
    port:SetSize(56, 56)
    port:ClearAllPoints()
    port:SetPoint('CENTER', frame, 'CENTER', 41, 8)
    port:SetDrawLayer('BACKGROUND', 0)

    if not self[frame:GetName() .. 'Background'] then
        local background = frame:CreateTexture('DragonflightUI' .. frame:GetName() .. 'Background')
        background:SetDrawLayer('BACKGROUND', 1)
        background:SetTexture(tex2xBase .. 'ui-hud-unitframe-target-portraiton-2x')
        background:SetTexCoord(ART_L, ART_R, ART_T, ART_B)
        background:SetSize(ART_W, ART_H)
        background:SetPoint('CENTER', frame, 'CENTER', ART_X, ART_Y)

        self[frame:GetName() .. 'Background'] = background
        self.TargetFrameBackground = background;
    end

    healthBar:ClearAllPoints()
    healthBar:SetPoint('CENTER', frame, 'CENTER', -50.5, 6)
    healthBar:SetSize(126, 20)
    healthBar:GetStatusBarTexture():SetTexture(
        'Interface\\Addons\\DragonflightUI\\Textures\\Unitframe\\UI-HUD-UnitFrame-Target-PortraitOn-Bar-Health')

    self.TargetMasks = self.TargetMasks or {}

    if not self.TargetMasks[healthBar] then
        local hpMask = healthBar:CreateMaskTexture()
        healthBar:GetStatusBarTexture():AddMaskTexture(hpMask)
        self.TargetMasks[healthBar] = hpMask
        hpMask:ClearAllPoints()
        hpMask:SetPoint('TOPLEFT', healthBar, 'TOPLEFT', -1, 6)
        hpMask:SetTexture(tex2xBase .. 'uiunitframetargethealthmask2x', 'CLAMPTOBLACKADDITIVE', 'CLAMPTOBLACKADDITIVE')
        hpMask:SetTexCoord(0, 1, 0, 1)
        hpMask:SetSize(128 + 1, 32)
    end

    manaBar:ClearAllPoints()
    manaBar:SetPoint('TOPLEFT', healthBar, 'BOTTOMLEFT', 0, -1)
    manaBar:SetSize(134, 10)
    manaBar:GetStatusBarTexture():SetTexture(
        'Interface\\Addons\\DragonflightUI\\Textures\\Unitframe\\UI-HUD-UnitFrame-Target-PortraitOn-Bar-Mana')
    manaBar:GetStatusBarTexture():SetVertexColor(1, 1, 1, 1)

    if not self.TargetMasks[manaBar] then
        local manaMask = manaBar:CreateMaskTexture()
        manaMask:ClearAllPoints()
        manaMask:SetPoint('TOPLEFT', manaBar, 'TOPLEFT', -62, 3)
        manaMask:SetTexture(tex2xBase .. 'uiunitframetargetmanamask2x', 'CLAMPTOBLACKADDITIVE', 'CLAMPTOBLACKADDITIVE')
        manaMask:SetTexCoord(0, 1, 0, 1)
        manaMask:SetSize(256 + 3, 16)
        manaBar:GetStatusBarTexture():AddMaskTexture(manaMask)
        self.TargetMasks[manaBar] = manaMask
    end

    if nameBackground then
        nameBackground:SetTexture(tex2xBase .. 'ui-hud-unitframe-target-portraiton-type-2x')
        nameBackground:SetTexCoord(0, 270 / 512, 0, 35 / 64)
        nameBackground:SetSize(135, 17.5)
        nameBackground:ClearAllPoints()
        nameBackground:SetPoint('BOTTOMLEFT', healthBar, 'TOPLEFT', -1 + 0.5, -3)
    end

    name:ClearAllPoints()
    -- name:SetPoint('LEFT', port, 'RIGHT', 1 + 1, 2 + 12 - 1)
    name:SetPoint('BOTTOMRIGHT', healthBar, 'TOPRIGHT', -2, 1)
    name:SetJustifyH('CENTER')
    name:SetJustifyV('MIDDLE')
    name:SetFontObject(GameFontNormalSmall)
    name:SetSize(100, 12)

    if levelText then
        levelText:SetJustifyH('LEFT')
        levelText:SetJustifyV('MIDDLE')
        levelText:SetFontObject(GameFontNormalSmall)

        local function FixLevelText(f)
            local hBar = f and (f.healthbar or f.HealthBar or _G[f:GetName() .. 'HealthBar'])
            local lText = f and (f.LevelText or _G[f:GetName() .. 'TextureFrameLevelText'])
            if lText and hBar then
                lText:ClearAllPoints()
                lText:SetPoint('BOTTOMLEFT', hBar, 'TOPLEFT', 5, 1)
                lText:SetHeight(12)
            end
        end
        FixLevelText(frame)

        local module = DF:GetModule('Unitframe');
        if module and not module.TargetFrameNameHooked and TargetFrame_UpdateLevelTextAnchor then
            module.TargetFrameNameHooked = true;
            hooksecurefunc('TargetFrame_UpdateLevelTextAnchor', function(f, targetLevel)
                FixLevelText(f)
            end)
        end
    end

    if deadText then
        deadText:ClearAllPoints()
        deadText:SetPoint('CENTER', healthBar, 'CENTER', 0, 0)
    end

    if unconsciousText then
        unconsciousText:ClearAllPoints()
        unconsciousText:SetPoint('CENTER', healthBar, 'CENTER', 0, 0)
    end

    -- Era needs this as much as TBC does. Blizzard anchors the faction icon to
    -- its own target frame art, and we replace that art, so left alone it sits
    -- off the frame - reported as "faction logo has the wrong position on
    -- targets", with a screenshot from 1.15.9. The icon is the same region on
    -- both (TargetFrameTextureFramePVPIcon, reached as TargetFrame.pvpIcon) and
    -- both use the classic frame, so the TBC placement applies unchanged.
    local t = TargetFrame and TargetFrame.pvpIcon
    if t and TargetFramePortrait then
        t:ClearAllPoints()
        t:SetPoint('LEFT', TargetFramePortrait, 'RIGHT', -22, -18)
    end

    -- Blizzard's own combat flash, however this flavour happens to expose it: a
    -- named Flash on the frame, or an anonymous texture carrying file id 137016.
    -- This used to be gated on DF.Wrath, so on TBC nothing here ran and
    -- Blizzard's flash stayed on screen - drawn for Blizzard's frame, over ours.
    local blizzFlash = flash
    if not blizzFlash then
        for _, region in ipairs({frame:GetRegions()}) do
            if region:GetObjectType() == 'Texture' and region.GetTexture and region:GetTexture() == 137016 then
                blizzFlash = region
                break
            end
        end
    end

    if blizzFlash then
        local flash = blizzFlash
        flash:SetTexture('')

        -- Keyed per frame, the way the background texture right above is.
        --
        -- This function dresses four different frames - the target, the focus,
        -- each boss frame and the edit-mode preview - and the glow is a child of
        -- whichever one it was first created for. Cached under one shared key,
        -- the second frame through here adopts the first frame's texture: the
        -- glow then draws at the first frame's position and size while a
        -- different frame is the one in combat, which is a glow sitting away
        -- from the frame it belongs to and shaped for the wrong one.
        local flashKey = frame:GetName() .. 'Flash'

        if not self[flashKey] then
            -- The glow is the frame's own art, not a picture of a glow.
            --
            -- No supplied texture traces this silhouette, because the silhouette
            -- is a rounded bar with a circular portrait bulging out of one end,
            -- and the shipped in-combat art does not line up with what DFUI
            -- actually draws. There is exactly one shape guaranteed to match the
            -- frame: the frame.
            --
            -- So stack copies of the background art underneath it, each a little
            -- larger than the last and fainter, tinted red and added rather than
            -- blended. Everything inside the frame is covered by the frame; what
            -- is left is a halo following the outline exactly, with a soft
            -- falloff from the layering. It cannot go out of shape, because it
            -- is derived from the same art at the same cut.
            local glow = CreateFrame('Frame', 'DragonflightUI' .. frame:GetName() .. 'Flash', frame)
            glow:SetAllPoints(frame)
            glow:Hide()

            -- One texture, the shipped in-combat art.
            --
            -- Stacking scaled copies of the frame art was wrong: that art has
            -- internal detail, so enlarging it produces offset copies of the
            -- whole picture rather than a stroke, which reads as concentric
            -- ghosts. The in-combat file is already what is wanted - a stroke
            -- around the silhouette with a falloff, transparent inside.
            --
            -- The catch is that a glow lives OUTSIDE the outline, so its art
            -- covers more ground than the frame does. Drawn at exactly the
            -- frame's size it cannot line up: the stroke has to sit proud of the
            -- frame by however much margin the art carries. Hence a tunable
            -- size rather than a copy of the background's.
            -- On top of the frame, not behind it.
            --
            -- The in-combat art is the same frame with its border recoloured
            -- solid and a glow either side of that border - inner and outer. It
            -- is meant to sit over the frame so the red ring takes the place of
            -- the gold one. Put behind, the opaque ring hides exactly the part
            -- that matters, which is what made the last attempt look like
            -- ghosting rather than a lit-up border.
            -- Two passes: one to replace the ring, more to make it burn.
            --
            -- BLEND paints over, so the base pass puts solid red where the gold
            -- was rather than tinting it. Brightness beyond that cannot come
            -- from alpha - vertex alpha clamps at 1, which is why the intensity
            -- slider did nothing past its halfway point - so extra punch comes
            -- from drawing the same art again additively on top. Each pass adds
            -- light, and that stacks.
            local tex = glow:CreateTexture(nil, 'ARTWORK', nil, 3)
            tex:SetTexture(tex2xBase .. 'ui-hud-unitframe-target-portraiton-incombat-2x')
            glow.Tex = tex

            glow.Adds = {}
            for i = 1, 2 do
                local add = glow:CreateTexture(nil, 'ARTWORK', nil, 3 + i)
                add:SetTexture(tex2xBase .. 'ui-hud-unitframe-target-portraiton-incombat-2x')
                add:SetBlendMode('ADD')
                glow.Adds[i] = add
            end

            glow.Blend = 'BLEND'

            -- Geometry dialled in against a live frame: the art's own size and
            -- cut, nudged two pixels right and one up from where the background
            -- sits.
            glow.Width = ART_W
            glow.Height = ART_H
            glow.OffsetX = -18
            glow.OffsetY = 7
            glow.CoordRight = ART_R
            glow.CoordBottom = ART_B
            -- Settled at 0.9 against a live frame: the replacing pass just under
            -- full, additive passes off. They only come in past 1.
            glow.Intensity = 0.9
            glow.Red, glow.Green, glow.Blue = 1.0, 0.0, 0.0

            function glow:ApplyGlow()
                local function place(t)
                    t:SetTexCoord(ART_L, self.CoordRight, ART_T, self.CoordBottom)
                    t:SetSize(self.Width, self.Height)
                    t:ClearAllPoints()
                    t:SetPoint('CENTER', frame, 'CENTER', self.OffsetX, self.OffsetY)
                end

                -- up to 1, the replacing pass fades in; past 1, the additive
                -- passes take over and keep going
                local base = math.min(self.Intensity, 1)
                local extra = math.max(0, self.Intensity - 1)

                self.Tex:SetBlendMode(self.Blend or 'BLEND')
                place(self.Tex)
                self.Tex:SetVertexColor(self.Red, self.Green, self.Blue, base)

                for _, add in ipairs(self.Adds) do
                    place(add)
                    add:SetVertexColor(self.Red, self.Green, self.Blue, extra * 0.5)
                    add:SetShown(extra > 0)
                end
            end

            glow:ApplyGlow()
            self[flashKey] = glow
        end

        -- kept for anything still reading the old field
        self.TargetFrameFlash = self[flashKey]

        -- Hook once per frame. This runs again on every settings apply, and
        -- stacked hooks meant every combat flash started another UIFrameFlash on
        -- the same texture.
        if not self[flashKey .. 'Hooked'] then
            self[flashKey .. 'Hooked'] = true

            local ownFlash = self[flashKey]

            hooksecurefunc(flash, 'Show', function()
                -- print('show')
                flash:SetTexture('')
                ownFlash:Show()
                if (UIFrameIsFlashing(ownFlash)) then
                else
                    -- print('go flash')
                    local dt = 0.5
                    UIFrameFlash(ownFlash, dt, dt, -1)
                end
            end)

            hooksecurefunc(flash, 'Hide', function()
                -- print('hide')
                flash:SetTexture('')
                if (UIFrameIsFlashing(ownFlash)) then UIFrameFlashStop(ownFlash) end
                ownFlash:Hide()
            end)
        end
    end

    if not self.PortraitExtra then
        local extra = frame:CreateTexture('DragonflightUI' .. frame:GetName() .. 'PortraitExtra')
        extra:SetTexture('Interface\\Addons\\DragonflightUI\\Textures\\uiunitframeboss2x')
        extra:SetTexCoord(0.001953125, 0.314453125, 0.322265625, 0.630859375)
        extra:SetSize(80, 79)
        extra:SetDrawLayer('ARTWORK', 3)
        extra:SetPoint('CENTER', port, 'CENTER', 4, 1)

        extra.UpdateStyle = function()
            local class = UnitClassification(frame.unit)
            --[[ "worldboss", "rareelite", "elite", "rare", "normal", "trivial" or "minus" ]]
            if class == 'worldboss' then
                self.PortraitExtra:Show()
                self.PortraitExtra:SetSize(99, 81)
                self.PortraitExtra:SetTexCoord(0.001953125, 0.388671875, 0.001953125, 0.31835937)
                self.PortraitExtra:SetPoint('CENTER', port, 'CENTER', 13, 1)
            elseif class == 'rareelite' or class == 'rare' then
                self.PortraitExtra:Show()
                self.PortraitExtra:SetSize(80, 79)
                self.PortraitExtra:SetTexCoord(0.00390625, 0.31640625, 0.64453125, 0.953125)
                self.PortraitExtra:SetPoint('CENTER', port, 'CENTER', 4, 1)
            elseif class == 'elite' then
                self.PortraitExtra:Show()
                self.PortraitExtra:SetTexCoord(0.001953125, 0.314453125, 0.322265625, 0.630859375)
                self.PortraitExtra:SetSize(80, 79)
                self.PortraitExtra:SetPoint('CENTER', port, 'CENTER', 4, 1)
            else
                local targetName, realm = UnitName('target')
                if self.ModuleRef.famous[targetName] then
                    self.PortraitExtra:Show()
                    self.PortraitExtra:SetSize(99, 81)
                    self.PortraitExtra:SetTexCoord(0.001953125, 0.388671875, 0.001953125, 0.31835937)
                    self.PortraitExtra:SetPoint('CENTER', port, 'CENTER', 13, 1)
                else
                    self.PortraitExtra:Hide()
                end
            end
        end

        self.PortraitExtra = extra
    end
end

function SubModuleMixin:ChangeTargetFrame()
    local base = 'Interface\\Addons\\DragonflightUI\\Textures\\uiunitframe'

    TargetFrameTextureFrameTexture:Hide()
    TargetFrameBackground:Hide()

    self:ChangeTargetFrameGeneral(self, TargetFrame)

    -- TargetFrameTextureFrameRaidTargetIcon:SetPoint('CENTER',TargetFrameTextureFrame,'TOPRIGHT',-73,-14)
    -- TargetFrameTextureFrameRaidTargetIcon:GetHeight()
    TargetFrameTextureFrameRaidTargetIcon:SetPoint('CENTER', TargetFramePortrait, 'TOP', 0, 2)

    -- TargetFrameBuff1:SetPoint('TOPLEFT', TargetFrame, 'BOTTOMLEFT', 5, 0)  

    if not self.TargetNameBackgroundHooked then
        self.TargetNameBackgroundHooked = true

        hooksecurefunc(TargetFrameNameBackground, 'Show', function(bg)
            local db = self.ModuleRef.db.profile.target
            if db.hideNameBackground then
                bg:SetAlpha(0)
            end
        end)
    end

    local parent = TargetFrameTextureFrame
    if parent then
        local hText = parent.HealthBarText or (TargetFrameHealthBar and TargetFrameHealthBar.TextString)
        local hLeft = parent.HealthBarTextLeft or (TargetFrameHealthBar and TargetFrameHealthBar.LeftText)
        local hRight = parent.HealthBarTextRight or (TargetFrameHealthBar and TargetFrameHealthBar.RightText)
        local mText = parent.ManaBarText or (TargetFrameManaBar and TargetFrameManaBar.TextString)
        local mLeft = parent.ManaBarTextLeft or (TargetFrameManaBar and TargetFrameManaBar.LeftText)
        local mRight = parent.ManaBarTextRight or (TargetFrameManaBar and TargetFrameManaBar.RightText)

        if hText and TargetFrameHealthBar then
            local dx = 5
            local deltaSize = 134 - 125

            hText:SetPoint('CENTER', TargetFrameHealthBar, 'CENTER', 0, 0)
            if hLeft then hLeft:SetPoint('LEFT', TargetFrameHealthBar, 'LEFT', dx, 0) end
            if hRight then hRight:SetPoint('RIGHT', TargetFrameHealthBar, 'RIGHT', -dx, 0) end

            if mText and TargetFrameManaBar then
                mText:SetPoint('CENTER', TargetFrameManaBar, 'CENTER', -deltaSize / 2, 0)
                if mLeft then mLeft:SetPoint('LEFT', TargetFrameManaBar, 'LEFT', dx, 0) end
                if mRight then mRight:SetPoint('RIGHT', TargetFrameManaBar, 'RIGHT', -dx - deltaSize, 0) end
            end
        end
    end

end

local texBase = 'Interface\\Addons\\DragonflightUI\\Textures\\Unitframe\\'
local texBaseToT = texBase .. 'UI-HUD-UnitFrame-Target-PortraitOn-Bar-'

local powerTable = {
    MANA = 'Mana',
    FOCUS = 'Focus',
    RAGE = 'Rage',
    ENERGY = 'Energy',
    RUNIC_POWER = 'RunicPower',
    POWER_TYPE_FEL_ENERGY = 'Energy' -- TODO
}

function SubModuleMixin:UpdateTargetHealthBarTexture(bar, state, unit)
    if state.customHealthBarTexture == 'Default' or not LSM then
        if (not UnitPlayerControlled(unit) and UnitIsTapDenied(unit)) then
            bar:GetStatusBarTexture():SetTexture(texBaseToT .. 'Health')
            bar:SetStatusBarColor(0.5, 0.5, 0.5, 1)
        elseif state.classcolor and UnitIsPlayer(unit) then
            bar:GetStatusBarTexture():SetTexture(texBaseToT .. 'Health-Status')
            local _, englishClass, _ = UnitClass(unit)
            bar:SetStatusBarColor(DF:GetClassColor(englishClass, 1))
        elseif state.gradient then
            bar:GetStatusBarTexture():SetTexture(texBaseToT .. 'Health-Status')
            local r, g, b = Helper:ColorGradiant(Helper:GetUnitHealthPercent(unit))
            bar:SetStatusBarColor(r, g, b, 1)
        elseif state.reactioncolor then
            bar:GetStatusBarTexture():SetTexture(texBaseToT .. 'Health-Status')
            bar:SetStatusBarColor(DF:GetUnitSelectionColor(unit))
        else
            bar:GetStatusBarTexture():SetTexture(texBaseToT .. 'Health')
            bar:SetStatusBarColor(1, 1, 1, 1)
        end
    else
        local customTex = LSM:Fetch("statusbar", state.customHealthBarTexture)
        bar:GetStatusBarTexture():SetTexture(customTex)

        if (not UnitPlayerControlled(unit) and UnitIsTapDenied(unit)) then
            bar:SetStatusBarColor(0.5, 0.5, 0.5, 1)
        elseif state.classcolor and UnitIsPlayer(unit) then
            local _, englishClass, _ = UnitClass(unit)
            bar:SetStatusBarColor(DF:GetClassColor(englishClass, 1))
        elseif state.reactioncolor then
            bar:SetStatusBarColor(DF:GetUnitSelectionColor(unit))
        else
            bar:SetStatusBarColor(0.0, 1.0, 0.0, 1)
        end
    end
end

function SubModuleMixin:UpdateTargetPowerBarTexture(bar, state, unit)
    if state.customPowerBarTexture == 'Default' or not LSM then
        local _, powerTypeString = UnitPowerType(unit)

        local powerTexStr = powerTable[powerTypeString] or powerTable['MANA']
        bar:GetStatusBarTexture():SetTexture(texBaseToT .. powerTexStr)

        bar:GetStatusBarTexture():SetVertexColor(1, 1, 1, 1)
    else
        -- Blizzard's own UnitFrameManaBar_UpdateType would do this, and writing to
        -- the bar is exactly why we do not call it - see Helper:GetPowerBarColor.
        -- This branch is the hot one: ReApplyTargetFrame runs from
        -- UnitFrameHealthBar_OnValueChanged, so it used to reseed the taint on every
        -- health poll tick.
        bar:SetStatusBarColor(Helper:GetPowerBarColor(unit))
        local customTex = LSM:Fetch("statusbar", state.customPowerBarTexture)
        bar:GetStatusBarTexture():SetTexture(customTex)
    end
end

function SubModuleMixin:ReApplyTargetFrame()
    self:UpdateTargetHealthBarTexture(TargetFrameHealthBar, self.ModuleRef.db.profile.target, 'target')
    self:UpdateTargetPowerBarTexture(TargetFrameManaBar, self.ModuleRef.db.profile.target, 'target')

    if DF.Wrath then TargetFrameFlash:SetTexture('') end
    if self.PortraitExtra then self.PortraitExtra:UpdateStyle() end
end

function SubModuleMixin:ChangeTargetComboFrame()
    local c = ComboFrame
    c:SetParent(TargetFrame)
    c:SetFrameLevel(10)

    local tex = 'Interface\\Addons\\DragonflightUI\\Textures\\Unitframe\\classoverlaycombopoints'

    for i = 1, 5 do
        --
        local point = _G['ComboPoint' .. i]

        local regions = {point:GetRegions()}

        for k, v in ipairs(regions) do
            --
            local layer = v:GetDrawLayer()
            -- print(k, layer)
            v:ClearAllPoints()
            v:SetSize(12, 12)
            v:SetPoint('CENTER', point, 'CENTER', 0, 0)
            v:SetTexture(tex)

            if layer == 'BACKGROUND' then
                v:SetTexCoord(0.226562, 0.382812, 0.515625, 0.671875)
            elseif layer == 'ARTWORK' then
                v:SetTexCoord(0.226562, 0.382812, 0.34375, 0.5)
            elseif layer == 'OVERLAY' then
                v:SetTexCoord(0.0078125, 0.210938, 0.164062, 0.375)
            end
        end
    end
end

function SubModuleMixin:UpdateComboFrameState(state)
    local c = ComboFrame

    if state.comboPointsOnPlayerFrame then
        c:SetParent(PlayerFrame)
        c:SetSize(116, 20)
        c:ClearAllPoints()
        -- c:SetPoint('TOP', PlayerFrame, 'BOTTOM', 50 - 8, 34 + 4)
        -- ShardBarFrame:SetPoint('TOP', PlayerFrame, 'BOTTOM', 50, 34 - 1)   

        local localizedClass, englishClass, classIndex = UnitClass('player');
        if englishClass == 'DRUID' then
            local deltaY = 16;
            c:SetPoint('TOP', PlayerFrame, 'BOTTOM', 50 - 8, 34 + 4 - deltaY)
        else
            c:SetPoint('TOP', PlayerFrame, 'BOTTOM', 50 - 8, 34 + 4)
        end

        for i = 1, 5 do
            --
            local size = 20
            local scaling = 20 / 12

            local point = _G['ComboPoint' .. i]
            point:SetSize(20, 20)
            point:ClearAllPoints()
            local dx = (i - 1) * 24 / scaling
            point:SetPoint('TOPLEFT', c, 'TOPLEFT', dx, 0)

            point:SetScale(scaling)
        end
    else
        -- default
        c:SetParent(TargetFrame)
        c:SetSize(256, 32)
        c:ClearAllPoints()
        c:SetPoint('TOPRIGHT', TargetFrame, 'TOPRIGHT', -44, -9)

        local comboDefaults = {{0, 0}, {7, -8}, {12, -19}, {14, -30}, {12, -41}}

        for i = 1, 5 do
            --
            local scaling = 1

            local point = _G['ComboPoint' .. i]
            point:SetSize(12, 12)
            point:ClearAllPoints()
            point:SetPoint('TOPRIGHT', c, 'TOPRIGHT', comboDefaults[i][1], comboDefaults[i][2])

            point:SetScale(scaling)
        end
    end

    if state.hideComboPoints then
        c:ClearAllPoints()
        c:SetPoint('TOP', UIParent, 'TOP', 0, 50)
    end
end

function SubModuleMixin:ShouldKnowHealth(unit)
    local guid = UnitGUID(unit)
    local matched = guid and guid:match("^(.-)%-")

    return UnitIsUnit(unit, 'Player') or UnitIsUnit(unit, 'Pet') or UnitPlayerOrPetInRaid(unit) or
               UnitPlayerOrPetInParty(unit) or (matched == 'Creature')
end

function SubModuleMixin:AddMobhealth()
    -- In WoW Classic (1.15+ / 2.5.6), creature health is natively provided by the server.
    -- Directly mutating statusbar.showPercentage on TargetFrameHealthBar taints the secure status bar.
end

function SubModuleMixin:CreatThreatIndicator()
    local sizeX, sizeY = 42, 16

    local indi = CreateFrame('Frame', 'DragonflightUIThreatIndicator', TargetFrame)
    indi:SetSize(sizeX, sizeY)
    indi:SetPoint('BOTTOM', TargetFrameTextureFrameName, 'TOP', 0, 2)

    local bg = indi:CreateTexture(nil, 'BACKGROUND')
    bg:SetTexture("Interface\\TargetingFrame\\UI-StatusBar");
    bg:SetTexture(
        "Interface\\Addons\\DragonflightUI\\Textures\\Unitframe\\UI-HUD-UnitFrame-Target-PortraitOn-Bar-Health");
    bg:SetPoint('CENTER', 0, 0)
    bg:SetSize(sizeX, sizeY)

    -- TargetFrameHealthBar:GetStatusBarTexture():SetTexture('Interface\\Addons\\DragonflightUI\\Textures\\Unitframe\\UI-HUD-UnitFrame-Target-PortraitOn-Bar-Health')
    -- TargetFrameHealthBar:SetStatusBarColor(1, 1, 1, 1)

    local text = indi:CreateFontString(nil, 'BACKGROUND', 'GameFontHighlight')
    text:SetPoint('CENTER', 0, 0)
    text:SetText('999%')

    indi.Background = bg
    indi.Text = text
    self.ThreatIndicator = indi

    local function UpdateIndicator()
        local db = self.ModuleRef.db.profile
        local enableNumeric = db.target.enableNumericThreat
        local threatAnchor = db.target.numericThreatAnchor
        local enableGlow = db.target.enableThreatGlow

        if UnitExists('TARGET') and (enableNumeric or enableGlow) then
            local isTanking, status, percentage, rawPercentage = UnitDetailedThreatSituation('PLAYER', 'TARGET')
            local display = rawPercentage;

            if enableNumeric then
                if isTanking then
                    ---@diagnostic disable-next-line: cast-local-type
                    display = UnitThreatPercentageOfLead('PLAYER', 'TARGET')
                    -- print('IsTanking')
                end

                if display and display ~= 0 then
                    -- print('t:', display)
                    display = min(display, MAX_DISPLAYED_THREAT_PERCENT);
                    text:SetText(format("%1.0f", display) .. "%")
                    bg:SetVertexColor(GetThreatStatusColor(status))
                    indi:Show()
                else
                    indi:Hide()
                end
            else
                indi:Hide()
            end

            if enableGlow then
                -- show
            else
                -- hide
            end

            indi:ClearAllPoints()
            if threatAnchor == 'TOP' then
                indi:SetPoint('BOTTOM', TargetFrameTextureFrameName, 'TOP', 0, 2)
            elseif threatAnchor == 'RIGHT' then
                indi:SetPoint('LEFT', TargetFramePortrait, 'RIGHT', 5, 0)
            elseif threatAnchor == 'BOTTOM' then
                indi:SetPoint('TOP', TargetFrameManaBar, 'BOTTOM', 0, -2)
            elseif threatAnchor == 'LEFT' then
                indi:SetPoint('RIGHT', TargetFrameHealthBar, 'LEFT', -2, 0)
            else
                -- should not happen
                indi:SetPoint('BOTTOM', TargetFrameTextureFrameName, 'TOP', 0, 2)
            end
        else
            indi:Hide()
            -- disable glow
        end
    end

    indi:RegisterEvent('PLAYER_TARGET_CHANGED')
    indi:RegisterUnitEvent('UNIT_THREAT_LIST_UPDATE', 'TARGET')

    indi:SetScript('OnEvent', UpdateIndicator)
    UpdateIndicator()
end

