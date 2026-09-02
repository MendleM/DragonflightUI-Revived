local addonName, addonTable = ...;
local DF = addonTable.DF;
local L = addonTable.L;
local Helper = addonTable.Helper;

local subModuleName = 'Party';
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

-- The health and mana readouts that sit INSIDE the bars (Interface -> Status
-- Text, off by default). The ones the classic reskin creates inherit
-- TextStatusBarText, which is sized for Blizzard's bars - ours are 10 and 7
-- pixels tall, so the numbers spilled out of them.
--
-- "Blizzard's own strings on the pooled frames" used to be the other half of
-- that sentence, and there are none. See EnsureBarStatusText.
local STATUS_TEXT_KEYS = {'TextString', 'LeftText', 'RightText', 'DFTextString', 'DFLeftText', 'DFRightText'}

-- The pooled bars have every part of the status text machinery except somewhere
-- to put it. They inherit TextStatusBar, call InitializeTextStatusBar, set
-- `cvar = "statusText"` and `textLockable = 1`, and the mixin re-runs
-- UpdateTextString on every value change, on CVAR_UPDATE and on mouseover. But
-- UpdateTextString opens with
--
--     local textString = self.TextString;
--     if (textString) then
--
-- and on 1.15.9 no unit frame has one. The TextStatusBar template carries only
-- scripts and a mixin - no FontStrings - and in the whole client only
-- Blizzard_PetBattleUI and the personal resource display declare a TextString.
-- Player, target and party bars all inherit the behaviour and none of them
-- supply the string, so the readouts were never being hidden or mis-sized:
-- there was nothing for the numbers to land in.
--
-- That is why the earlier pass here did not fix it. FitBarStatusText resizes
-- the strings, and on a pooled frame all six keys are nil, so it had nothing to
-- resize and reported no error.
--
-- Supplying the three strings is the entire fix. Blizzard's own code then fills
-- them on every value change, shows and hides them from the Status Text option,
-- switches between numeric, percentage and both, and reveals them on mouseover
-- through lockShow. LeftText and RightText matter: the "both" display mode
-- writes the percentage and the value into them rather than into TextString.
local function GetDFUIUnitframeFont()
    local newFont = 'Fonts\\FRIZQT__.ttf'
    local locale = GetLocale()
    if locale == "ruRU" then
        newFont = "Fonts\\FRIZQT___CYR.TTF"
    elseif locale == "koKR" then
        newFont = "Fonts\\2002.TTF"
    elseif locale == "zhCN" then
        newFont = "Fonts\\ARKai_T.TTF"
    elseif locale == "zhTW" then
        newFont = "Fonts\\blei00d.TTF"
    end
    return newFont
end

local function EnsureBarStatusText(bar)
    if not (bar and bar.CreateFontString) or bar.TextString then return end

    local function make(point, x)
        local fs = bar:CreateFontString(nil, 'OVERLAY', 'TextStatusBarText')
        fs:SetPoint(point, bar, point, x, 0)
        fs:Hide()
        return fs
    end

    bar.TextString = make('CENTER', 0)
    bar.LeftText = make('LEFT', 2)
    bar.RightText = make('RIGHT', -2)

    -- Nothing has changed value yet, so ask for the first fill rather than
    -- waiting for the member to take damage.
    if bar.UpdateTextString then bar:UpdateTextString() end
end

local function FitBarStatusText(bar)
    if not bar or not bar.GetHeight then return end

    local size = ((bar:GetHeight() or 10) >= 12) and 10 or 9
    local fontFile = GetDFUIUnitframeFont()

    for _, key in ipairs(STATUS_TEXT_KEYS) do
        local text = bar[key]
        if text and text.SetFont then
            text:SetFont(fontFile, size, 'OUTLINE')
        end
    end
end

function SubModuleMixin:Init()
    self.ModuleRef = DF:GetModule('Unitframe')
    self:SetDefaults()
    self:SetupOptions()
    self:SetScript('OnEvent', self.OnEvent);
end

function SubModuleMixin:SetDefaults()
    local defaults = {
        classcolor = false,
        gradient = false,
        breakUpLargeNumbers = true,
        scale = 1.0,
        override = false,
        anchorFrame = 'UIParent',
        customAnchorFrame = '',
        anchor = 'TOPLEFT',
        anchorParent = 'TOPLEFT',
        x = 16,
        y = -160,
        customHealthBarTexture = 'Default',
        customPowerBarTexture = 'Default',
        padding = 10,
        orientation = 'vertical',
        disableBuffTooltip = 'INCOMBAT',
        useCompactPartyFrames = false,
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

-- Use Raid-Style Party Frames.
--
-- Module.db.profile.party.useCompactPartyFrames is the single source of truth,
-- and the sync to Blizzard is one-way: DragonflightUI writes, Blizzard reads.
--
-- This is the one Blizzard setting that cannot be applied from here. Which party
-- system is live is decided inside Blizzard's own code, and every path through
-- it - UpdateRaidAndPartyFrames, CompactPartyFrame:ShouldShow,
-- CompactRaidFrameManager - asks EditModeManagerFrame:UseRaidStylePartyFrames(),
-- which resolves the value through GetRegisteredSystemFrame out of the layout.
-- So the layout is where the value has to go, and SyncRaidStylePartyFrameToBlizzard
-- puts it there through C_EditMode.GetLayouts/SaveLayouts. That is a settings
-- value, self-contained and still meaningful with this addon disabled - unlike an
-- anchorInfo pointing at a DragonflightUI frame, which is what must never be
-- written and no longer is.
--
-- What used to be here instead was an assignment:
--
--     EditModeManagerFrame.UseRaidStylePartyFrames = QuerySetting
--     EditModeManagerFrameMixin.UseRaidStylePartyFrames = QuerySetting
--
-- reinstalled on every ADDON_LOADED, with no backup, so Blizzard's own
-- implementation was gone for the session. It was added as a workaround one
-- commit after the argument-less UpdateLayoutInfo() call in Helper.lua nil'd
-- layoutInfo and broke the real accessor - treating the symptom of a bug that is
-- now fixed at the cause.
--
-- The cost was taint. Blizzard's ShouldShow for BOTH party systems ran an addon
-- function, so both inherited taint on a protected path, and the blocked actions
-- on the party frames followed from it. The taint analysis in DebugLog.lua had
-- already narrowed the seed to this exact call and was right.

-- Told once, when the setting is switched on, because the frames it produces are
-- configured somewhere other than the page the player is standing on.
--
-- This notice used to walk people through disabling the addon, reloading, opening
-- Blizzard's Edit Mode and enabling it again. That is obsolete: the raid frame Edit
-- Mode settings - raid size, frame width and height, group split, border, template,
-- opacity, icon size, sort order - are now offered directly under Unitframes, Raid
-- Frame, and on the Raid Frame entry in this addon's own edit mode. Blizzard's Edit
-- Mode stays blocked and no longer needs to be reached.
--
-- What is still Blizzard's own is the raid profile panel, which opens from a button on
-- the Raid Frame page and needs no reload either. Its exact contents are deliberately
-- not listed here or in the popup: they differ by flavour, and the list that used to be
-- quoted came from DFUI's old proxy-CVar names rather than from the panel itself.
--
-- So the notice has one job left, which is to say WHERE. Turning this on replaces the
-- portrait party frames with the compact ones, and from then on the settings that
-- matter live under Raid Frame rather than PartyFrame - which is not obvious.
local raidStyleNoticeShown = false

StaticPopupDialogs['DragonflightUIRaidStylePartyNotice'] = {
    text = 'DragonflightUI has switched your party frames to the raid-style (compact) frames.\n\n' ..
        'From now on these frames are configured under |cffffff78Unitframes > Raid Frame|r, not on this page - ' ..
        'position, scale, raid size, frame width and height, how groups are split, the border and the rest.\n\n' ..
        'You can also select |cffffff78Raid Frame|r in DragonflightUI\'s own Edit Mode to move it and change the ' ..
        'same settings there, with a preview.\n\n' ..
        'Blizzard\'s own raid profile options open from a button on the same page. Nothing here needs Blizzard\'s ' ..
        'Edit Mode or a reload.',
    -- button1 silences it for good, button2 just closes - the same way round as the
    -- leftover-layout notice, so the two behave alike.
    button1 = 'Do not show again',
    button2 = CLOSE or 'Close',
    showAlert = true,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
    OnAccept = function()
        local db = DF.db and DF.db.global
        if db then db.raidStyleNoticeDismissed = true end
        DF:Print('Notice about raid-style party frames will not be shown again. ' ..
                     'Type /df raidnotice to bring it back.')
    end
}

function addonTable:ShowRaidStylePartyNotice(force)
    if not force then
        if raidStyleNoticeShown then return false end

        local db = DF.db and DF.db.global
        if db and db.raidStyleNoticeDismissed then return true end
    end

    raidStyleNoticeShown = true
    StaticPopup_Show('DragonflightUIRaidStylePartyNotice')

    return false
end

function SubModuleMixin.GetRaidStylePartyFrames(self)
    local Module = (self and type(self) == 'table' and self.ModuleRef) or DF:GetModule('Unitframe')
    if Module and Module.db and Module.db.profile and Module.db.profile.party and Module.db.profile.party.useCompactPartyFrames ~= nil then
        return Module.db.profile.party.useCompactPartyFrames == true
    end
    if C_CVar and C_CVar.GetCVar and C_CVar.GetCVar('useCompactPartyFrames') ~= nil then
        return C_CVar.GetCVar('useCompactPartyFrames') == '1'
    end
    return false
end

function SubModuleMixin.SetRaidStylePartyFrames(selfOrEnabled, maybeEnabled)
    local enabled
    local selfRef
    if type(selfOrEnabled) == 'table' then
        selfRef = selfOrEnabled
        enabled = maybeEnabled
    else
        enabled = selfOrEnabled
    end
    local val = enabled and true or false

    local Module = (selfRef and type(selfRef) == 'table' and selfRef.ModuleRef) or DF:GetModule('Unitframe')
    if Module and Module.db and Module.db.profile and Module.db.profile.party then
        Module.db.profile.party.useCompactPartyFrames = val
    end

    -- Keep CVar in sync if client supports it
    if C_CVar and C_CVar.GetCVar and C_CVar.GetCVar('useCompactPartyFrames') ~= nil then
        pcall(SetCVar, 'useCompactPartyFrames', val and '1' or '0')
    elseif SetCVar then
        pcall(SetCVar, 'useCompactPartyFrames', val and '1' or '0')
    end

    if addonTable and addonTable.SyncRaidStylePartyFrameToBlizzard then
        addonTable:SyncRaidStylePartyFrameToBlizzard(val)
    end

    -- Only when switching on, and only once per session. Switching back to the
    -- portrait frames needs no explanation - those this addon does configure.
    if val and addonTable and addonTable.ShowRaidStylePartyNotice then
        addonTable:ShowRaidStylePartyNotice()
    end

    -- Update preview in Edit Mode
    local fakeParty = _G['DragonflightUIEditModePartyFramePreview']
    if fakeParty and fakeParty.Update then
        pcall(fakeParty.Update, fakeParty)
    end

    -- Safely trigger Blizzard updates out of combat on a clean tick
    Helper:RunOutOfCombat('RaidStylePartyFrames', function()
        C_Timer.After(0, function()
            if InCombatLockdown() then return end
            -- EditModeManagerFrame:UpdateSystem, not PartyFrame:UpdateSystem.
            --
            -- Two different functions with different arguments. The manager's
            -- version takes a system FRAME and looks the systemInfo up out of the
            -- active layout; the frame's own version takes that systemInfo table
            -- and iterates systemInfo.settings. This used to call the frame
            -- version with a setting enum, so it indexed a number and threw
            -- inside the pcall on every single toggle, without a word.
            if EditModeManagerFrame and EditModeManagerFrame.UpdateSystem and PartyFrame then
                local forceFullUpdate = true
                local ok, err = pcall(EditModeManagerFrame.UpdateSystem, EditModeManagerFrame, PartyFrame,
                                      forceFullUpdate)
                if not ok then geterrorhandler()('DFUI PartyFrame UpdateSystem: ' .. tostring(err)) end
            end
            if PartyFrame and PartyFrame.UpdatePartyFrames then
                pcall(PartyFrame.UpdatePartyFrames, PartyFrame)
            end
            if CompactPartyFrame and CompactPartyFrame.UpdateVisibility then
                pcall(CompactPartyFrame.UpdateVisibility, CompactPartyFrame)
            end
            if CompactPartyFrame and CompactPartyFrame.UpdateLayout then
                pcall(CompactPartyFrame.UpdateLayout, CompactPartyFrame)
            end
            if UIParent_UpdateRaidAndPartyFrames then
                pcall(UIParent_UpdateRaidAndPartyFrames)
            end
            if CompactRaidFrameManager_UpdateShown then
                pcall(CompactRaidFrameManager_UpdateShown, CompactRaidFrameManager)
            end
            if CompactRaidFrameContainer_UpdateDisplayedUnits then
                pcall(CompactRaidFrameContainer_UpdateDisplayedUnits, CompactRaidFrameContainer)
            end
        end)
    end)
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

    local optionsParty = {
        name = L["PartyFrameName"],
        desc = L["PartyFrameDesc"],
        advancedName = 'PartyFrame',
        sub = 'party',
        get = getOption,
        set = setOption,
        type = 'group',
        args = {
            headerStyling = {
                type = 'header',
                name = L["PartyFrameStyle"],
                desc = '',
                order = 20,
                isExpanded = true,
                editmode = true
            },
            classcolor = {
                type = 'toggle',
                name = L["PartyFrameClassColor"],
                desc = L["PartyFrameClassColorDesc"] .. getDefaultStr('classcolor', 'party'),
                group = 'headerStyling',
                order = 7,
                editmode = true
            },
            gradient = {
                type = 'toggle',
                name = L["PlayerFrameGradientColor"],
                desc = L["PlayerFrameGradientColorDesc"] .. getDefaultStr('gradient', 'party'),
                group = 'headerStyling',
                order = 2.1,
                new = true,
                editmode = true
            },
            breakUpLargeNumbers = {
                type = 'toggle',
                name = L["PartyFrameBreakUpLargeNumbers"],
                desc = L["PartyFrameBreakUpLargeNumbersDesc"] .. getDefaultStr('breakUpLargeNumbers', 'party'),
                group = 'headerStyling',
                order = 8,
                editmode = true
            }
        }
    }

    if true then
        local moreOptions = {
            useCompactPartyFrames = {
                type = 'toggle',
                name = USE_RAID_STYLE_PARTY_FRAMES,
                desc = OPTION_TOOLTIP_USE_RAID_STYLE_PARTY_FRAMES,
                group = 'headerStyling',
                order = 15,
                blizzard = true,
                editmode = true
            },
            -- Blizzard's Interface options panel, not the Edit Mode dialog. Named for
            -- what it actually opens: the two are easy to confuse, they hold
            -- different settings, and the Edit Mode ones are offered by this addon
            -- directly in the Raid section.
            raidFrameBtn = {
                type = 'execute',
                name = 'Blizzard raid profile options',
                desc = 'Opens Blizzard\'s own Interface options for raid frames - health text, class colours and ' ..
                    'the like. Frame size and group layout are Edit Mode settings and are in DragonflightUI\'s ' ..
                    'Raid section.',
                btnName = 'Open',
                func = function()
                    Settings.OpenToCategory(Settings.INTERFACE_CATEGORY_ID, RAID_FRAMES_LABEL);
                    PlaySound(SOUNDKIT.IG_MAINMENU_OPTION);
                end,
                group = 'headerStyling',
                order = 16,
                blizzard = true,
                editmode = true
            },
            orientation = {
                type = 'select',
                name = L["ButtonTableOrientation"],
                desc = L["ButtonTableOrientationDesc"] .. getDefaultStr('orientation', 'party'),
                dropdownValues = DF.Settings.OrientationTable,
                order = 2,
                group = 'headerStyling',
                editmode = true
            },
            disableBuffTooltip = {
                type = 'select',
                name = L["PartyFrameDisableBuffTooltip"],
                desc = L["PartyFrameDisableBuffTooltipDesc"] .. getDefaultStr('disableBuffTooltip', 'party'),
                dropdownValues = partyBuffTooltipTable,
                order = 3,
                group = 'headerStyling',
                editmode = true,
                new = false
            },
            padding = {
                type = 'range',
                name = L["ButtonTablePadding"],
                desc = L["ButtonTablePaddingDesc"] .. getDefaultStr('padding', 'party'),
                min = -50,
                max = 50,
                bigStep = 1,
                order = 3,
                group = 'headerStyling',
                editmode = true
            }
        }

        for k, v in pairs(moreOptions) do optionsParty.args[k] = v end

        optionsParty.get = function(info)
            local key = info[1]
            local sub = info[2]

            if sub == 'useCompactPartyFrames' then
                return SubModuleMixin.GetRaidStylePartyFrames()
            else
                return getOption(info)
            end
        end

        optionsParty.set = function(info, value)
            local key = info[1]
            local sub = info[2]

            if sub == 'useCompactPartyFrames' then
                SubModuleMixin.SetRaidStylePartyFrames(value)
            else
                setOption(info, value)
            end
        end
    end
    DF.Settings:AddPositionTable(Module, optionsParty, 'party', 'Party', getDefaultStr, frameTable)

    DragonflightUIStateHandlerMixin:AddStateTable(Module, optionsParty, 'party', 'Party', getDefaultStr)
    local optionsPartyEditmode = {
        name = 'party',
        desc = 'party',
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
                    local dbTable = Module.db.profile.party
                    local defaultsTable = self.Defaults
                    -- {scale = 1.0, anchor = 'TOPLEFT', anchorParent = 'TOPLEFT', x = -19, y = -4}
                    setPreset(dbTable, {
                        scale = defaultsTable.scale,
                        anchor = defaultsTable.anchor,
                        anchorParent = defaultsTable.anchorParent,
                        anchorFrame = defaultsTable.anchorFrame,
                        x = defaultsTable.x,
                        y = defaultsTable.y,
                        orientation = defaultsTable.orientation,
                        padding = defaultsTable.padding
                    })
                end,
                order = 16,
                editmode = true,
                new = false
            }
        }
    }

    self.Options = optionsParty;
    self.OptionsEditmode = optionsPartyEditmode;
end

-- The holder the party frames get reparented onto.
--
-- SecureFrameTemplate,SecureHandlerEnterLeaveTemplate - the same pair the
-- player, pet, target, focus and ToT holders inherit in Load.xml, and the thing
-- this one was missing: it was a bare Frame.
--
-- PartyFrame is protected and its member frames are pooled children of it.
-- Reparenting a protected frame onto an unprotected one leaves the client
-- holding a protected frame whose parent chain an addon owns, and its own
-- Show/Hide/SetAttribute on those members start coming back refused - the
-- "Interface action failed because of an AddOn" message, members that do not
-- appear, a party that collapses to one member on a pull. Every other unit
-- frame in this addon is reparented exactly the same way onto a secure holder,
-- and none of them have this problem; party was the one exception.
--
-- It is also why the reports were worse in the open world than in dungeons:
-- this is the party-style PartyFrame, and raid-style CompactPartyFrame - what a
-- five-man is more often on - is never reparented by this code at all.
--
-- Mouse explicitly off. On these clients a frame inheriting those templates
-- comes up mouse-enabled, and a UIParent-parented holder sitting over the party
-- frames' spot would swallow clicks meant for the world. Same lesson as the
-- unit frame holders.
function SubModuleMixin:EnsurePartyMoveFrame()
    if self.PartyMoveFrame then return self.PartyMoveFrame end

    -- From XML (Load.xml), not CreateFrame. A Lua-created frame gets an
    -- insecure global, and PartyFrame is reparented onto this one - which is
    -- what left the party members tainted. The five other unit frame holders
    -- have always come from XML; this was the odd one out.
    local moveFrame = _G['DragonflightUIPartyMoveFrame']
    if not moveFrame then return nil end

    moveFrame:SetParent(UIParent)
    moveFrame:SetPoint('CENTER', UIParent, 'CENTER', 0, 0)
    moveFrame:SetFrameStrata('LOW')
    moveFrame:SetFrameLevel(2)
    moveFrame:EnableMouse(false)
    self.PartyMoveFrame = moveFrame

    return moveFrame
end

-- era-1159: DF-restyle for the pooled modern party member frames. Mirrors
-- the geometry of the classic reskin above (frame 120x53, DF border art,
-- health 71x10 @ 44,-19, mana 74x7 @ 41,-30) using the parentKeys the
-- pooled PartyMemberFrameTemplate exposes.
function SubModuleMixin:SetupModern()
    local subModule = self
    local ATLAS = 'Interface\\Addons\\DragonflightUI\\Textures\\Partyframe\\uipartyframe'
    local BARS = 'Interface\\Addons\\DragonflightUI\\Textures\\Partyframe\\'
    local UpdateRoleIcon, UpdateBars

    -- The pooled PartyFrame anchors itself, so DFUI's position, scale and
    -- anchor settings did nothing at all on 1.15.9 - only the classic path
    -- had a move frame. Give the modern path the same one, and keep Blizzard
    -- from wandering off it.
    local holder = self:EnsurePartyMoveFrame()
    if not holder then return end
    holder:SetSize(120, 53 * 4 + 3 * 10)

    -- Put PartyFrame back on our move frame, out of combat only.
    --
    -- PartyFrame is protected, and its member frames are pooled: Blizzard's own
    -- party update acquires them, anchors them and shows them. Re-anchoring the
    -- container from inside that update - which is what doing this straight from
    -- a SetPoint hook amounts to - performs a protected call the client refuses
    -- mid-fight, and the update it interrupted never shows the members. That is
    -- how a party could lose everyone but one member the moment a boss pull
    -- started, and get them all back the instant combat ended, when Blizzard ran
    -- the update again unimpeded.
    --
    -- So never during lockdown, and never inside Blizzard's call: re-anchor on
    -- the next frame instead, and again when combat drops.
    local function ReanchorPartyFrame()
        if InCombatLockdown() then return end
        if not (PartyFrame and self.PartyMoveFrame) then return end

        local _, relativeTo = PartyFrame:GetPoint(1)
        if relativeTo == self.PartyMoveFrame then return end

        PartyFrame:ClearAllPoints()
        PartyFrame:SetPoint('TOPLEFT', self.PartyMoveFrame, 'TOPLEFT', 0, 0)
    end
    self.ReanchorPartyFrame = ReanchorPartyFrame

    if PartyFrame then
        if not InCombatLockdown() then
            PartyFrame:ClearAllPoints()
            PartyFrame:SetParent(self.PartyMoveFrame)
            PartyFrame:SetPoint('TOPLEFT', self.PartyMoveFrame, 'TOPLEFT', 0, 0)
        end

        if not self.PartyFrameAnchorHooked then
            self.PartyFrameAnchorHooked = true

            -- Blizzard re-anchors this frame from its own layout code; put it
            -- back afterwards, never during.
            hooksecurefunc(PartyFrame, 'SetPoint', function(frame, _, relativeTo)
                if relativeTo == self.PartyMoveFrame then return end
                if not InCombatLockdown() then
                    C_Timer.After(0, function()
                        ReanchorPartyFrame()
                    end)
                end
            end)

            -- Anything the fight refused is put right here.
            local regen = CreateFrame('Frame')
            regen:RegisterEvent('PLAYER_REGEN_ENABLED')
            -- Someone leaving the group does the same damage as a boss kill:
            -- it drives UpdateMember, the pool releases and reacquires frames,
            -- and any Show() refused on the way leaves a member missing. Same
            -- recovery, so listen for both.
            regen:RegisterEvent('GROUP_ROSTER_UPDATE')

            -- The rest of the ways a member goes missing.
            --
            -- Every one of these drives UpdateMember, so every one of them can
            -- lose a member to a refused Show(). Chasing them one report at a
            -- time is a losing game - a ding, a boss kill and someone leaving
            -- were three separate reports of one bug - so cover the paths we
            -- know and let the state check below catch the ones we do not.
            --
            -- Vehicles matter more than they look: ToPlayerArt and ToVehicleArt
            -- are the two halves of UpdateArt, and ToPlayerArt is the exact
            -- function in the captured stack.
            for _, ev in ipairs({
                'PLAYER_ENTERING_WORLD', 'PARTY_LEADER_CHANGED', 'PLAYER_ROLES_ASSIGNED', 'UNIT_PET',
                'UNIT_CONNECTION', 'UNIT_ENTERED_VEHICLE', 'UNIT_EXITED_VEHICLE', 'UPDATE_ACTIVE_BATTLEFIELD'
            }) do pcall(regen.RegisterEvent, regen, ev) end
            regen:SetScript('OnEvent', function()
                if not (PartyFrame and self.PartyMoveFrame) then return end
                if PartyFrame:GetParent() ~= self.PartyMoveFrame then
                    PartyFrame:SetParent(self.PartyMoveFrame)
                end
                ReanchorPartyFrame()

                -- And ask Blizzard to redraw the members.
                --
                -- Show() and SetAttribute() on a party member are protected, so
                -- while .unit is tainted they are refused for the whole of
                -- combat - which is why members vanish on a level-up or a boss
                -- kill and stay gone afterwards. Nothing re-runs UpdateMember
                -- once combat drops, so the frames sit hidden until the next
                -- roster change or a /reload.
                --
                -- Out of combat those same calls are allowed even from tainted
                -- code, so simply running Blizzard's own update here puts the
                -- missing members back. This treats the symptom, not the taint:
                -- members are still lost for the duration of a fight, and the
                -- seed hunt continues. But it turns "broken until I reload"
                -- into "back the moment the fight ends".
                -- Next frame, not this one: on a roster change Blizzard is
                -- part way through its own pass and the pool is still being
                -- rearranged, so redrawing now would be undone immediately.
                -- In combat this is pointless anyway - the calls are refused -
                -- and PLAYER_REGEN_ENABLED will bring us straight back.
                C_Timer.After(0, function()
                    if InCombatLockdown() then return end
                    if not (PartyFrame and PartyFrame.UpdatePartyFrames and PartyFrame.PartyMemberFramePool) then
                        return
                    end

                    -- Only redraw when a member is actually missing.
                    --
                    -- This is the part that does not depend on us having
                    -- guessed the right events: however the member was lost,
                    -- fewer are on screen than are in the group, and that is
                    -- checkable. It also keeps us from doing protected work on
                    -- every roster event for no reason.
                    local expected = GetNumSubgroupMembers and GetNumSubgroupMembers() or 0
                    if expected == 0 then return end

                    if SubModuleMixin.GetRaidStylePartyFrames() then return end

                    local shown = 0
                    for pf in PartyFrame.PartyMemberFramePool:EnumerateActive() do
                        if pf:IsShown() then shown = shown + 1 end
                    end

                    if shown < expected then pcall(PartyFrame.UpdatePartyFrames, PartyFrame) end
                end)
            end)
            self.PartyAnchorRegenWatcher = regen
        end
    end

    local POWER_BAR_ART = {
        MANA = 'Mana',
        RAGE = 'Rage',
        FOCUS = 'Focus',
        ENERGY = 'Energy',
        RUNIC_POWER = 'RunicPower'
    }

    -- Our bookkeeping about a party member frame, kept beside the frame rather
    -- than on it.
    --
    -- /df log seed finally named the seed on 2026-08-23, after seven theories
    -- and three instrumentation passes. At the moment a pooled member's .unit
    -- first comes back insecure:
    --
    --   FIELD member.DFRoleIcon         insecure, tainted by DragonflightUI
    --   FIELD member.DFPartyFrameBorder insecure, tainted by DragonflightUI
    --   FIELD member.DFStyled           insecure, tainted by Atlas
    --   FIELD member.unit               insecure, tainted by DragonflightUI
    --   frame.OnEvent                   secure
    --
    -- Three of those four are ours, written straight onto a frame the client
    -- owns. DFStyled being blamed on Atlas is the tell that makes the mechanism
    -- plain: the blame is whoever owned the execution at the moment of the
    -- write, not whoever wrote it - so any addon on the stack when we touch
    -- these frames ends up owning part of Blizzard's party member.
    --
    -- Weak keys, so a released pooled frame is not held alive by this table.
    local memberState = setmetatable({}, {__mode = 'k'})

    local function styleMember(pf)
        local st = memberState[pf]
        if st and st.styled then return end
        st = st or {}
        memberState[pf] = st
        st.styled = true

        pf:SetSize(120, 53)
        pf:SetHitRectInsets(0, 0, 0, 12)

        -- The classic ring art, vehicle art and the Name live on the
        -- PartyMemberOverlay CHILD frame - hiding pf.Texture etc. no-ops,
        -- and anything painted on pf renders UNDER the overlay.
        local overlay = pf.PartyMemberOverlay
        if pf.Background then pf.Background:Hide() end
        if pf.Border then pf.Border:Hide() end
        for _, holder in ipairs({pf, overlay}) do
            if holder and holder.Texture then
                holder.Texture:SetTexture(nil)
                holder.Texture:Hide()
            end
            if holder and holder.VehicleTexture then
                holder.VehicleTexture:SetTexture(nil)
                holder.VehicleTexture:Hide()
            end
        end

        -- The frame art goes BEHIND the bars, on pf, not on the overlay.
        --
        -- This art is not a hollow border: the atlas region carries the
        -- frame's dark interior with it. Sampled against the bars' own rects
        -- it averages RGBA (28,27,25,166) over the health bar and
        -- (31,30,28,177) over the mana bar - a near-black layer at ~65%
        -- opacity. On the overlay, which is a child FRAME, it draws above the
        -- bar frames whatever layer it sits on, and that is what made the bars
        -- look permanently dimmed: they were rendering at roughly a third of
        -- the texture's brightness.
        --
        -- Raising the bars above the overlay was tried first and reverted: it
        -- left them outliving the frame art in transitional states (a
        -- disconnected member showed as a bar floating over nothing). Putting
        -- the art underneath instead fixes the dimming AND keeps the art and
        -- the bars appearing and disappearing together. Nothing is lost by
        -- moving it: the overlay's own ring and vehicle art are cleared just
        -- above, and its name and role icons are separate children that still
        -- draw on top.
        local border = pf:CreateTexture(nil, 'BACKGROUND', nil, 1)
        border:SetSize(120, 49)
        border:SetTexture(ATLAS)
        border:SetTexCoord(0.480469, 0.949219, 0.222656, 0.414062)
        border:SetPoint('TOPLEFT', pf, 'TOPLEFT', 1, -2)
        st.border = border

        if pf.Flash then
            pf.Flash:SetSize(114, 47)
            pf.Flash:SetTexture(ATLAS)
            pf.Flash:SetTexCoord(0.480469, 0.925781, 0.453125, 0.636719)
            pf.Flash:ClearAllPoints()
            pf.Flash:SetPoint('TOPLEFT', 2, -2)
            pf.Flash:SetVertexColor(1, 0, 0, 1)
            pf.Flash:SetDrawLayer('ARTWORK', 5)
        end

        if pf.Portrait then
            pf.Portrait:SetSize(37, 37)
            pf.Portrait:ClearAllPoints()
            pf.Portrait:SetPoint('TOPLEFT', 7, -6)
            -- SetPortraitTexture swaps in a SQUARE snapshot once the unit
            -- gets in range; the DF ring art has transparent corners, so
            -- without the circular mask (which every other restyled portrait
            -- gets) the snapshot's corners poke out behind the border.
            Helper:AddCircleMask(pf, pf.Portrait)
        end

        local name = (overlay and overlay.Name) or pf.Name
        if name then
            name:ClearAllPoints()
            name:SetPoint('TOPLEFT', pf, 'TOPLEFT', 46, -6)
            -- Stop the name before the role icon (12px, inset 5 from the
            -- right edge of the 120px frame) instead of running underneath
            -- it, and hold it to a single line: with wrapping left on, a
            -- long name spilled onto a second line and pushed itself down
            -- over the health bar.
            name:SetWidth(UnitGroupRolesAssigned and 54 or 68)
            name:SetHeight(12)
            name:SetWordWrap(false)
            if name.SetMaxLines then name:SetMaxLines(1) end
            name:SetJustifyH('LEFT')
        end

        local healthbar = pf.HealthBar
        if healthbar then
            healthbar:SetSize(71, 10)
            healthbar:ClearAllPoints()
            healthbar:SetPoint('TOPLEFT', 44, -19)
            healthbar:SetStatusBarTexture(BARS .. 'UI-HUD-UnitFrame-Party-PortraitOn-Bar-Health')
            healthbar:SetStatusBarColor(1, 1, 1, 1)
            -- UnitFrameHealthBar_Update re-tints this green on every health
            -- event, and that green multiplied into the DF art is what made
            -- the bars look dark. lockColor is Blizzard's own opt-out.
            healthbar.lockColor = true

            local hpMask = healthbar:CreateMaskTexture()
            hpMask:SetPoint('CENTER', healthbar, 'CENTER', 0, 0)
            hpMask:SetTexture(BARS .. 'UI-HUD-UnitFrame-Party-PortraitOn-Bar-Health-Mask',
                              'CLAMPTOBLACKADDITIVE', 'CLAMPTOBLACKADDITIVE')
            hpMask:SetSize(71, 10)
            healthbar:GetStatusBarTexture():AddMaskTexture(hpMask)
        end

        local manabar = pf.ManaBar
        if manabar then
            manabar:SetSize(74, 7)
            manabar:ClearAllPoints()
            manabar:SetPoint('TOPLEFT', 41, -30)
            manabar:SetStatusBarTexture(BARS .. 'UI-HUD-UnitFrame-Party-PortraitOn-Bar-Mana')
            manabar:SetStatusBarColor(1, 1, 1, 1)
            -- Without this, UnitFrameManaBar_UpdateType swaps our art out
            -- for the plain UI-StatusBar and tints it by power color.
            manabar.lockColor = true

            local manaMask = manabar:CreateMaskTexture()
            manaMask:SetPoint('CENTER', manabar, 'CENTER', 0, 0)
            manaMask:SetTexture(BARS .. 'UI-HUD-UnitFrame-Party-PortraitOn-Bar-Mana-Mask',
                                'CLAMPTOBLACKADDITIVE', 'CLAMPTOBLACKADDITIVE')
            manaMask:SetSize(74, 7)
            manabar:GetStatusBarTexture():AddMaskTexture(manaMask)
        end

        -- Create before fitting: there is nothing to size until these exist.
        EnsureBarStatusText(pf.HealthBar)
        EnsureBarStatusText(pf.ManaBar)

        FitBarStatusText(pf.HealthBar)
        FitBarStatusText(pf.ManaBar)

        -- NOTE: lifting the bars above PartyMemberOverlay was tried here to
        -- test whether the overlay art was dimming them. It made the bars
        -- outlive the frame art in transitional states (a disconnected
        -- member rendered as a bar floating over nothing), so the bars stay
        -- in Blizzard's layering.

        -- Blizzard flips health-bar desaturation in UpdateOnlineStatus and the
        -- flag could stay stuck on a pooled frame reused for a connected
        -- player, so our own state has to be re-asserted after it runs. That
        -- used to be done with
        --
        --     hooksecurefunc(pf, 'UpdateOnlineStatus', ...)
        --
        -- and a per-object hook is a write into the frame's own table:
        -- hooksecurefunc(table, key, fn) replaces pf.UpdateOnlineStatus with an
        -- insecure function. These frames are protected, Blizzard reads that
        -- field every time it calls the method, and the read tainted the whole
        -- execution - which is why blocked stacks came back with
        -- "[C]: in function 'UpdateOnlineStatus'" in the middle of them and
        -- Hide() refused at PartyMemberFrame.lua:428. Members stopped appearing
        -- from there on.
        --
        -- The roster watcher below already registers UNIT_CONNECTION and
        -- already re-runs UpdateBars for every styled member, which is the same
        -- coverage from our own execution instead of inside Blizzard's. So the
        -- hook is not replaced with a safer hook - it is not needed at all.

        -- Debuff row. We adopted retail's bar geometry (mana 74x7 at
        -- 41,-30) but the template still carried Classic's aura anchor of
        -- (48,-32), which was written for Classic's mana bar ending at
        -- -29 - so the icons landed on top of our power bar. Retail pairs
        -- that bar geometry with (48,-43); use its number.
        local auras = pf.AuraFrameContainer
        if auras then
            auras:ClearAllPoints()
            auras:SetPoint('TOPLEFT', pf, 'TOPLEFT', 48, -43)
        end

        -- Name font (matching PlayerFrame / PlayerName)
        local nameText = pf.Name or pf.name or _G[pf:GetName() and (pf:GetName() .. 'Name')]
        if nameText and nameText.SetFont then
            nameText:SetFont(GetDFUIUnitframeFont(), 11, 'OUTLINE')
        end

        -- Role icon (Era 1.15.x has LFG roles), same treatment as the
        -- classic reskin: top-right corner of the member frame.
        if UnitGroupRolesAssigned then
            local roleIcon = pf:CreateTexture(nil, 'OVERLAY')
            roleIcon:SetSize(12, 12)
            roleIcon:SetPoint('TOPRIGHT', pf, 'TOPRIGHT', -5, -5)
            roleIcon:SetTexture('Interface\\Addons\\DragonflightUI\\Textures\\roleicons')
            st.roleIcon = roleIcon
            UpdateRoleIcon(pf)
        end
    end

    function UpdateRoleIcon(pf)
        local roleIcon = memberState[pf] and memberState[pf].roleIcon
        if not roleIcon then return end
        local unit = pf.unitToken or ('party' .. (pf.layoutIndex or 1))
        local role = UnitGroupRolesAssigned and UnitGroupRolesAssigned(unit)
        roleIcon:Show()
        if role == 'TANK' then
            roleIcon:SetTexCoord(0.578125, 0.828125, 0.03125, 0.53125)
        elseif role == 'HEALER' then
            roleIcon:SetTexCoord(0.296875, 0.546875, 0.03125, 0.53125)
        elseif role == 'DAMAGER' then
            roleIcon:SetTexCoord(0.015625, 0.265625, 0.03125, 0.53125)
        else
            roleIcon:Hide()
        end
    end

    -- With lockColor set, Blizzard no longer swaps the power art per power
    -- type or greys out offline members, so we own both. Uses
    -- GetStatusBarTexture():SetTexture so the bar's mask survives.
    function UpdateBars(pf)
        local unit = pf.unit or pf.unitToken
        if not (unit and UnitExists(unit)) then return end

        local connected = UnitIsConnected(unit)
        local shade = connected and 1 or 0.5

        local state = subModule.ModuleRef and subModule.ModuleRef.db.profile.party

        local healthbar = pf.HealthBar
        if healthbar then
            -- (re)assert here too, not just at first styling: frames styled
            -- before this ran would otherwise keep Blizzard's tint until a
            -- reload recreated them.
            healthbar.lockColor = true

            -- Retail's plain Bar-Health art is a muted green (49,153,8) and
            -- looks dull next to the player frame. The class-color and
            -- gradient options - which the classic reskin honours but this
            -- path never did - swap in the greyscale -Status art and tint
            -- it, exactly like PlayerFrame does.
            local tex = healthbar:GetStatusBarTexture()
            local r, g, b = shade, shade, shade
            if tex and state and state.classcolor then
                local _, class = UnitClass(unit)

                -- No class yet means the name cache entry has not arrived.
                --
                -- GROUP_ROSTER_UPDATE fires before the client has the class for a member,
                -- so UnitClass answers nil on login and on invite. GetClassColor(nil) hands
                -- back white, which is the priest colour - so everybody showed up as a
                -- priest until something repainted them. Use the plain green art until the
                -- class is known; UNIT_NAME_UPDATE brings us back here once it is.
                if class then
                    tex:SetTexture(BARS .. 'UI-HUD-UnitFrame-Party-PortraitOn-Bar-Health-Status')
                    r, g, b = DF:GetClassColor(class, 1)
                else
                    tex:SetTexture(BARS .. 'UI-HUD-UnitFrame-Party-PortraitOn-Bar-Health')
                end
            elseif tex and state and state.gradient then
                tex:SetTexture(BARS .. 'UI-HUD-UnitFrame-Party-PortraitOn-Bar-Health-Status')
                r, g, b = Helper:ColorGradiant(Helper:GetUnitHealthPercent(unit))
            elseif tex then
                tex:SetTexture(BARS .. 'UI-HUD-UnitFrame-Party-PortraitOn-Bar-Health')
            end
            -- Blizzard desaturates this bar for disconnected members
            -- (PartyMemberFrameMixin:UpdateOnlineStatus) and the flag could
            -- stay stuck on afterwards, which is what made bars look washed
            -- out. Drive it from the same connection check as the shade.
            if healthbar.SetStatusBarDesaturated then
                healthbar:SetStatusBarDesaturated(not connected)
            elseif tex and tex.SetDesaturated then
                tex:SetDesaturated(not connected)
            end
            if tex and tex.SetDesaturated then tex:SetDesaturated(not connected) end
            healthbar:SetStatusBarColor(r * shade, g * shade, b * shade, 1)
        end

        local manabar = pf.ManaBar
        if manabar then
            manabar.lockColor = true
            local _, powerToken = UnitPowerType(unit)
            local art = POWER_BAR_ART[powerToken] or 'Mana'
            local tex = manabar:GetStatusBarTexture()
            if tex then tex:SetTexture(BARS .. 'UI-HUD-UnitFrame-Party-PortraitOn-Bar-' .. art) end
            if manabar.SetStatusBarDesaturated then manabar:SetStatusBarDesaturated(false) end
            if tex and tex.SetDesaturated then tex:SetDesaturated(false) end
            manabar:SetStatusBarColor(shade, shade, shade, 1)
        end
    end

    -- A newly styled member frame gets the golden art, so anything Darkmode had
    -- recolored is undone the moment the roster changes. Rather than reading
    -- Darkmode's settings from here, ask it to re-apply - the same shape as
    -- Actionbar.lua's DarkmodeReapply step.
    --
    -- Deferred by a frame and coalesced: styleAll can run several times during one
    -- roster update, and a re-apply per member would be wasted work.
    local darkmodeReapplyPending = false
    local function ReapplyDarkmode()
        if darkmodeReapplyPending then return end
        darkmodeReapplyPending = true

        C_Timer.After(0, function()
            darkmodeReapplyPending = false
            local dm = DF:GetModule('Darkmode', true)
            if dm and dm.GetWasEnabled and dm:GetWasEnabled() then pcall(dm.ApplySettings, dm) end
        end)
    end

    local function styleAll()
        if not (PartyFrame and PartyFrame.PartyMemberFramePool) then return end
        local count = 0
        for pf in PartyFrame.PartyMemberFramePool:EnumerateActive() do
            count = count + 1
            local ok, err = pcall(styleMember, pf)
            if not ok then geterrorhandler()('DFPartyModern: ' .. tostring(err)) end
            pcall(UpdateBars, pf)
        end

        if count > 0 then ReapplyDarkmode() end
    end

    if PartyFrame and PartyFrame.InitializePartyMemberFrames then
        hooksecurefunc(PartyFrame, 'InitializePartyMemberFrames', styleAll)
    end
    styleAll()

    -- Reachable from Update(), so changing a setting re-applies immediately.
    -- Without this the only things that ever restyled a pooled member frame
    -- were InitializePartyMemberFrames above and the roster watcher below -
    -- both of which only fire when the group itself changes.
    subModule.RestyleModernParty = styleAll

    -- How Darkmode reaches the frame art on pooled member frames.
    --
    -- It cannot look the textures up itself. On this client there are no
    -- PartyMemberFrame1..4 globals to walk, and our border texture deliberately
    -- does not live on the frame - see the comment above memberState: writing
    -- pf.DFPartyFrameBorder is what tainted the pooled members in the first place.
    -- So the table stays private and callers get an iterator instead.
    subModule.ForEachPartyBorder = function(fn)
        if type(fn) ~= 'function' then return end
        if not (PartyFrame and PartyFrame.PartyMemberFramePool) then return end

        for pf in PartyFrame.PartyMemberFramePool:EnumerateActive() do
            local st = memberState[pf]
            if st and st.styled and st.border then pcall(fn, st.border) end
        end
    end

    -- Gradient coloring follows current health, so it needs health events.
    -- Unit-filtered to the four party slots: an unfiltered UNIT_HEALTH would
    -- fire for every unit in a raid.
    --
    -- UNIT_NAME_UPDATE shares the watcher but not the gradient gate. It is the client
    -- saying the name cache entry arrived, which is the moment UnitClass starts answering -
    -- Blizzard calls CompactUnitFrame_UpdateHealthColor on that same event and says so in a
    -- comment. Without it a member painted plain for a missing class stayed that way, since
    -- nothing repaints a bar whose health has not moved.
    --
    -- The gate stays on UNIT_HEALTH alone. That one fires constantly in combat for four
    -- units, and outside gradient mode there is nothing for it to change.
    for _, units in ipairs({{'party1', 'party2'}, {'party3', 'party4'}}) do
        local unitWatcher = CreateFrame('Frame')
        unitWatcher:RegisterUnitEvent('UNIT_HEALTH', units[1], units[2])
        unitWatcher:RegisterUnitEvent('UNIT_NAME_UPDATE', units[1], units[2])

        unitWatcher:SetScript('OnEvent', function(_, event, unit)
            if event == 'UNIT_HEALTH' then
                local state = subModule.ModuleRef and subModule.ModuleRef.db.profile.party
                if not (state and state.gradient) then return end
            end

            if not (PartyFrame and PartyFrame.PartyMemberFramePool) then return end

            for pf in PartyFrame.PartyMemberFramePool:EnumerateActive() do
                local st = memberState[pf]

                -- layoutIndex is the only handle a frame has before Blizzard has put a unit
                -- on it. PartyFrameMixin:InitializePartyMemberFrames assigns 1 through
                -- MAX_PARTY_MEMBERS, which maps straight onto party1 through party4.
                local slot = pf.layoutIndex and ('party' .. pf.layoutIndex)

                if st and st.styled and (pf.unit == unit or pf.unitToken == unit or slot == unit) then
                    pcall(UpdateBars, pf)
                end
            end
        end)
    end

    local roleWatcher = CreateFrame('Frame')
    roleWatcher:RegisterEvent('GROUP_ROSTER_UPDATE')
    -- Logging in or reloading while already in a group: GROUP_ROSTER_UPDATE can land before
    -- the frames have been styled, and a member skipped for that reason is never revisited.
    roleWatcher:RegisterEvent('PLAYER_ENTERING_WORLD')
    if C_EventUtils and C_EventUtils.IsEventValid and C_EventUtils.IsEventValid('PLAYER_ROLES_ASSIGNED') then
        roleWatcher:RegisterEvent('PLAYER_ROLES_ASSIGNED')
    end
    -- Power type changes (shapeshift, vehicle) and members going offline.
    -- Both are rare, so unfiltered is fine here - unlike the high-frequency
    -- UNIT_* events, which must always be unit-filtered on this client.
    roleWatcher:RegisterEvent('UNIT_DISPLAYPOWER')
    roleWatcher:RegisterEvent('UNIT_CONNECTION')
    roleWatcher:SetScript('OnEvent', function(_, event, unit)
        if not (PartyFrame and PartyFrame.PartyMemberFramePool) then return end
        local barsOnly = (event == 'UNIT_DISPLAYPOWER' or event == 'UNIT_CONNECTION')
        if barsOnly and not (unit and unit:find('party', 1, true)) then return end
        for pf in PartyFrame.PartyMemberFramePool:EnumerateActive() do
            if memberState[pf] and memberState[pf].styled then
                if not barsOnly then pcall(UpdateRoleIcon, pf) end
                pcall(UpdateBars, pf)
            end
        end
    end)
end

function SubModuleMixin:Setup()
    local function setDefaultSubValues(sub)
        self.ModuleRef:SetDefaultSubValues(sub)
    end

    DF.ConfigModule:RegisterSettingsData('party', 'unitframes', {
        options = self.Options,
        default = function()
            setDefaultSubValues('party')
        end
    })
    --
    self:RegisterEvent('CVAR_UPDATE')

    -- editmode
    local EditModeModule = DF:GetModule('Editmode');
    local fakeParty = CreateFrame('Frame', 'DragonflightUIEditModePartyFramePreview', UIParent,
                                  'DFEditModePreviewPartyFrameTemplate')
    fakeParty:OnLoad()
    self.PreviewParty = fakeParty;

    EditModeModule:AddEditModeToFrame(fakeParty)

    fakeParty.DFEditModeSelection:SetGetLabelTextFunction(function()
        return self.Options.name
    end)

    fakeParty.DFEditModeSelection:RegisterOptions({
        options = self.Options,
        extra = self.OptionsEditmode,
        -- parentExtra = Module.PartyMoveFrame,
        default = function()
            setDefaultSubValues('party')
        end,
        moduleRef = self.ModuleRef,
        -- fakeParty is a dummy party used to drag the real one into place; it
        -- must not survive edit mode, or it lingers as a second, made-up
        -- party next to the real frames.
        previewOnly = true
        -- showFunction = function()
        --     --           
        --     for k = 1, 4 do
        --         local p = _G['PartyMemberFrame' .. k]
        --         -- p:SetAlpha(0)
        --         -- print('p', k)
        --     end
        --     -- Module.PartyMoveFrame:Hide()
        -- end,
        -- hideFunction = function()
        --     --            
        --     for k = 1, 4 do
        --         local p = _G['PartyMemberFrame' .. k]
        --         -- p:SetAlpha(0)
        --         -- print('p', k)
        --     end
        --     -- Module.PartyMoveFrame:Show()
        -- end
    });

    -- Modern pooled party setup (Era 1.15.9+, TBC 2.5.6+, MoP 5.5.4+)
    self:SetupModern()

    if addonTable and addonTable.SyncRaidStylePartyFrameToBlizzard then
        addonTable:SyncRaidStylePartyFrameToBlizzard(self.GetRaidStylePartyFrames(self))
    end
end

function SubModuleMixin:OnEvent(event, ...)
    if event == 'CVAR_UPDATE' then
        local arg1 = ...;
        if arg1 == 'statusText' or arg1 == 'statusTextDisplay' then
            if self.RestyleModernParty then self.RestyleModernParty() end
        end
    end
end

function SubModuleMixin:UpdateState(state)
    self.state = state;
    self:Update();
end

function SubModuleMixin:Update()
    if self.PreviewParty and self.state then self.PreviewParty:UpdateState(self.state) end
    if not self.PartyMoveFrame then return end
    local state = self.state;
    if not state then return end

    local parent = _G[state.anchorFrame] or UIParent
    self.PartyMoveFrame:ClearAllPoints();
    self.PartyMoveFrame:SetPoint(state.anchor, parent, state.anchorParent, state.x, state.y)
    self.PartyMoveFrame:SetScale(state.scale)

    -- Pooled member frames are 120x53
    local sizeX, sizeY = 120, 53

    if state.orientation == 'vertical' then
        self.PartyMoveFrame:SetSize(sizeX, sizeY * 4 + 3 * state.padding)
    else
        self.PartyMoveFrame:SetSize(sizeX * 4 + 3 * state.padding, sizeY)
    end

    if not InCombatLockdown() and PartyFrame and self.PartyMoveFrame then
        if PartyFrame:GetParent() ~= self.PartyMoveFrame then
            PartyFrame:SetParent(self.PartyMoveFrame)
        end
        PartyFrame:ClearAllPoints()
        PartyFrame:SetPoint('TOPLEFT', self.PartyMoveFrame, 'TOPLEFT', 0, 0)
    end

    if self.RestyleModernParty then self.RestyleModernParty() end
end

