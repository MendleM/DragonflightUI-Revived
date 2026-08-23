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

    for _, key in ipairs(STATUS_TEXT_KEYS) do
        local text = bar[key]
        if text and text.SetFont then
            -- GetFont returns nil when the string draws from a font OBJECT
            -- rather than a file, so fall back rather than passing nil on
            local file, _, flags = text:GetFont()
            file = file or STANDARD_TEXT_FONT or 'Fonts\\FRIZQT__.ttf'
            text:SetFont(file, size, (flags and flags ~= '') and flags or 'OUTLINE')
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
        anchorFrame = 'CompactRaidFrameManager',
        customAnchorFrame = '',
        anchor = 'TOPLEFT',
        anchorParent = 'TOPRIGHT',
        x = 0,
        y = 0,
        customHealthBarTexture = 'Default',
        customPowerBarTexture = 'Default',
        padding = 10,
        orientation = 'vertical',
        disableBuffTooltip = 'INCOMBAT',
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
-- This used to read and write the useCompactPartyFrames CVar, which is what it
-- was on the old clients. On 1.15.9 that CVar is dead - the string does not
-- appear anywhere in the client - and the answer moved into the Edit Mode
-- layout. Both frames ask the same question:
--
--   CompactPartyFrameMixin:ShouldShow()
--     return ShouldShowPartyFrames() and EditModeManagerFrame:UseRaidStylePartyFrames()
--   PartyFrameMixin:ShouldShow()
--     return ShouldShowPartyFrames() and not EditModeManagerFrame:UseRaidStylePartyFrames()
--
-- and UseRaidStylePartyFrames reads the layout setting, not a CVar. So the
-- toggle was writing somewhere nothing reads, which is exactly the "doesn't do
-- anything when toggled on and off" report.
--
-- Older flavours still have the CVar, so keep it for them and pick by what the
-- client actually offers rather than by flavour.
local function HasModernRaidStyleSetting()
    return (EditModeManagerFrame and EditModeManagerFrame.UseRaidStylePartyFrames and Enum and
               Enum.EditModeUnitFrameSetting and Enum.EditModeUnitFrameSetting.UseRaidStylePartyFrames) and true or false
end

function SubModuleMixin.GetRaidStylePartyFrames()
    if HasModernRaidStyleSetting() then
        local ok, value = pcall(EditModeManagerFrame.UseRaidStylePartyFrames, EditModeManagerFrame)
        if ok then return value and true or false end
    end

    return C_CVar and C_CVar.GetCVar('useCompactPartyFrames') == '1'
end

function SubModuleMixin.SetRaidStylePartyFrames(enabled)
    if HasModernRaidStyleSetting() and PartyFrame and addonTable.SetBlizzEditmodeFrameSetting then
        -- Goes through the layout, so it survives a reload and reaches both
        -- frames. SetBlizzEditmodeFrameSetting schedules the application that
        -- makes them swap.
        addonTable:SetBlizzEditmodeFrameSetting(PartyFrame, Enum.EditModeUnitFrameSetting.UseRaidStylePartyFrames,
                                                enabled and 1 or 0)
        return
    end

    if SetCVar then SetCVar('useCompactPartyFrames', enabled and '1' or '0') end
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
            raidFrameBtn = {
                type = 'execute',
                name = 'Raid Frame Settings',
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
                if self.PartyAnchorPending then return end

                self.PartyAnchorPending = true
                C_Timer.After(0, function()
                    self.PartyAnchorPending = nil
                    ReanchorPartyFrame()
                end)
            end)

            -- Anything the fight refused is put right here.
            local regen = CreateFrame('Frame')
            regen:RegisterEvent('PLAYER_REGEN_ENABLED')
            -- Someone leaving the group does the same damage as a boss kill:
            -- it drives UpdateMember, the pool releases and reacquires frames,
            -- and any Show() refused on the way leaves a member missing. Same
            -- recovery, so listen for both.
            regen:RegisterEvent('GROUP_ROSTER_UPDATE')
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
                    if PartyFrame and PartyFrame.UpdatePartyFrames then
                        pcall(PartyFrame.UpdatePartyFrames, PartyFrame)
                    end
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
                tex:SetTexture(BARS .. 'UI-HUD-UnitFrame-Party-PortraitOn-Bar-Health-Status')
                local _, class = UnitClass(unit)
                r, g, b = DF:GetClassColor(class, 1)
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

    local function styleAll()
        if not (PartyFrame and PartyFrame.PartyMemberFramePool) then return end
        local count = 0
        for pf in PartyFrame.PartyMemberFramePool:EnumerateActive() do
            count = count + 1
            local ok, err = pcall(styleMember, pf)
            if not ok then geterrorhandler()('DFPartyModern: ' .. tostring(err)) end
            pcall(UpdateBars, pf)
        end
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

    -- Gradient coloring follows current health, so it needs health events.
    -- Unit-filtered to the four party slots: an unfiltered UNIT_HEALTH would
    -- fire for every unit in a raid.
    for _, units in ipairs({{'party1', 'party2'}, {'party3', 'party4'}}) do
        local healthWatcher = CreateFrame('Frame')
        healthWatcher:RegisterUnitEvent('UNIT_HEALTH', units[1], units[2])
        healthWatcher:SetScript('OnEvent', function(_, _, unit)
            local state = subModule.ModuleRef and subModule.ModuleRef.db.profile.party
            if not (state and state.gradient) then return end
            if not (PartyFrame and PartyFrame.PartyMemberFramePool) then return end
            for pf in PartyFrame.PartyMemberFramePool:EnumerateActive() do
                local st = memberState[pf]
                if st and st.styled and (pf.unit == unit or pf.unitToken == unit) then pcall(UpdateBars, pf) end
            end
        end)
    end

    local roleWatcher = CreateFrame('Frame')
    roleWatcher:RegisterEvent('GROUP_ROSTER_UPDATE')
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

    -- Styling last, and per flavour. The settings page and the edit-mode
    -- registration above are shared: this used to return early on modern
    -- clients, straight after SetupModern, so on 1.15.9 the party page was
    -- never registered at all and the frames could not be configured or
    -- selected in edit mode.
    if _G['PartyMemberFrame1'] then
        self:ChangePartyFrame()
        self:AddStateUpdater()
    elseif DF.API.Version.IsModern then
        -- Modern (Midnight-UI) clients pool anonymous PartyFrame member
        -- frames; the classic PartyMemberFrame1-4 reskin cannot attach, so
        -- restyle the pooled frames in place instead (era-1159).
        self:SetupModern()
    end
end

function SubModuleMixin:OnEvent(event, ...)
    if event == 'CVAR_UPDATE' then
        local arg1 = ...;
        if arg1 == 'statusText' or arg1 == 'statusTextDisplay' then
            for i = 1, 4 do
                if _G['PartyMemberFrame' .. i] then
                    self:UpdatePartyHPBar(i)
                    self:UpdatePartyManaBar(i)
                end
            end
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

    -- local party1 = _G['PartyMemberFrame' .. 1]
    -- party1:ClearAllPoints()
    -- party1:SetPoint('TOPLEFT', PartyMoveFrame, 'TOPLEFT', 0, 0)

    -- pooled member frames are 120x53; only the classic ones can be measured
    local sizeX, sizeY = 120, 53
    if _G['PartyMemberFrame' .. 1] then sizeX, sizeY = _G['PartyMemberFrame' .. 1]:GetSize() end

    if state.orientation == 'vertical' then
        self.PartyMoveFrame:SetSize(sizeX, sizeY * 4 + 3 * state.padding)
    else
        self.PartyMoveFrame:SetSize(sizeX * 4 + 3 * state.padding, sizeY)
    end

    -- On pooled clients this is the ONLY place a settings change can reach the
    -- member frames, and it did not: everything below is the classic reskin,
    -- and the early return under it meant Update() did the move frame and then
    -- stopped. The bars were left to be restyled by whatever restyled them
    -- next, and the only two things that do are the InitializePartyMemberFrames
    -- hook and the roster watcher - so health colour, power art and Class Color
    -- appeared to apply only when somebody joined or left the group.
    if self.RestyleModernParty then self.RestyleModernParty() end

    -- Everything below belongs to the classic reskin: on pooled clients the
    -- member frames are laid out by PartyFrame itself, and the move frame
    -- above is what carries our position and scale.
    if not _G['PartyMemberFrame1'] then return end

    for i = 2, 4 do
        local pf = _G['PartyMemberFrame' .. i]
        pf:ClearAllPoints()

        if state.orientation == 'vertical' then
            pf:SetPoint('TOPLEFT', _G['PartyMemberFrame' .. (i - 1)], 'BOTTOMLEFT', 0, -state.padding)
        else
            pf:SetPoint('TOPLEFT', _G['PartyMemberFrame' .. (i - 1)], 'TOPRIGHT', state.padding, 0)
        end
    end

    for i = 1, 4 do
        local pf = _G['PartyMemberFrame' .. i]

        local debuffOne = _G['PartyMemberFrame' .. i .. 'Debuff1']
        if state.orientation == 'vertical' then
            debuffOne:SetPoint('TOPLEFT', 120, -20)
        else
            debuffOne:SetPoint('TOPLEFT', 40 + 2, -40)
        end

        self:UpdatePartyHPBar(i)
        TextStatusBar_UpdateTextString(_G['PartyMemberFrame' .. i .. 'HealthBar'])
        TextStatusBar_UpdateTextString(_G['PartyMemberFrame' .. i .. 'ManaBar'])

        pf:UpdateStateHandler(state)
        PartyMemberFrame_UpdateMember(pf)
    end
end

function SubModuleMixin:ChangePartyFrame()
    local PartyMoveFrame = self:EnsurePartyMoveFrame()
    if not PartyMoveFrame then return end

    local sizeX, sizeY = _G['PartyMemberFrame' .. 1]:GetSize()
    local gap = 10;
    PartyMoveFrame:SetSize(sizeX, sizeY * 4 + 3 * gap)

    local first = _G['PartyMemberFrame' .. 1]
    -- first:SetPoint('TOPLEFT', CompactRaidFrameManager, 'TOPRIGHT', 0, 0)
    first:ClearAllPoints()
    first:SetPoint('TOPLEFT', PartyMoveFrame, 'TOPLEFT', 0, 0)

    for i = 1, 4 do
        local pf = _G['PartyMemberFrame' .. i]
        pf:SetParent(PartyMoveFrame)
        pf:SetSize(120, 53)
        -- pf:ClearAllPoints()
        -- pf:SetPoint('TOPLEFT', CompactRaidFrameManager, 'TOPRIGHT', 0, 0)

        pf:SetHitRectInsets(0, 0, 0, 12)

        -- layer = 'BACKGROUND => Flash,Portrait,Background
        local bg = _G['PartyMemberFrame' .. i .. 'Background']
        bg:Hide()

        local flash = _G['PartyMemberFrame' .. i .. 'Flash']
        flash:SetSize(114, 47)
        flash:SetTexture('Interface\\Addons\\DragonflightUI\\Textures\\Partyframe\\uipartyframe')
        flash:SetTexCoord(0.480469, 0.925781, 0.453125, 0.636719)
        flash:SetPoint('TOPLEFT', 1 + 1, -2)
        flash:SetVertexColor(1, 0, 0, 1)
        flash:SetDrawLayer('ARTWORK', 5)

        local portrait = _G['PartyMemberFrame' .. i .. 'Portrait']
        -- portrait:SetSize(37,37)
        -- portrait:SetPoint('TOPLEFT',7,-6)

        -- layer = 'BORDER' => Texture, VehicleTexture,Name
        local texture = _G['PartyMemberFrame' .. i .. 'Texture']
        texture:SetTexture()
        texture:Hide()

        local name = _G['PartyMemberFrame' .. i .. 'Name']
        name:ClearAllPoints()
        name:SetSize(57, 12)
        name:SetPoint('TOPLEFT', 46, -6)

        if not UnitGroupRolesAssigned then name:SetWidth(100) end

        -- layer = 'ARTWORK' => Status

        if not pf.PartyFrameBorder then
            local border = pf:CreateTexture('DragonflightUIPartyFrameBorder')
            -- border = _G['PartyMemberFrame' .. i .. 'HealthBar']:CreateTexture('DragonflightUIPartyFrameBorder')
            border:SetDrawLayer('ARTWORK', 3)
            border:SetSize(120, 49)
            border:SetTexture('Interface\\Addons\\DragonflightUI\\Textures\\Partyframe\\uipartyframe')
            border:SetTexCoord(0.480469, 0.949219, 0.222656, 0.414062)
            border:SetPoint('TOPLEFT', 1, -2)
            -- border:SetPoint('TOPLEFT', pf, 'TOPLEFT', 1, -2)
            -- border:Hide()

            pf.PartyFrameBorder = border
        end

        local status = _G['PartyMemberFrame' .. i .. 'Status']
        status:SetSize(114, 47)
        status:SetTexture('Interface\\Addons\\DragonflightUI\\Textures\\Partyframe\\uipartyframe')
        status:SetTexCoord(0.00390625, 0.472656, 0.453125, 0.644531)
        status:SetPoint('TOPLEFT', 1, -2)
        status:SetDrawLayer('ARTWORK', 5)

        -- layer = 'OVERLAY' => LeaderIcon etc

        local updateSmallIcons = function()
            local leaderIcon = _G['PartyMemberFrame' .. i .. 'LeaderIcon']
            leaderIcon:ClearAllPoints()
            leaderIcon:SetPoint('BOTTOM', pf, 'TOP', -10, -6)

            local masterIcon = _G['PartyMemberFrame' .. i .. 'MasterIcon']
            masterIcon:ClearAllPoints()
            masterIcon:SetPoint('BOTTOM', pf, 'TOP', -10 + 16, -6)

            local guideIcon = _G['PartyMemberFrame' .. i .. 'GuideIcon']
            guideIcon:ClearAllPoints()
            guideIcon:SetPoint('BOTTOM', pf, 'TOP', -10, -6)

            local pvpIcon = _G['PartyMemberFrame' .. i .. 'PVPIcon']
            pvpIcon:ClearAllPoints()
            pvpIcon:SetPoint('CENTER', pf, 'TOPLEFT', 7, -24)

            local readyCheck = _G['PartyMemberFrame' .. i .. 'ReadyCheck']
            readyCheck:ClearAllPoints()
            readyCheck:SetPoint('CENTER', portrait, 'CENTER', 0, -2)

            local notPresentIcon = _G['PartyMemberFrame' .. i .. 'NotPresentIcon']
            notPresentIcon:ClearAllPoints()
            notPresentIcon:SetPoint('LEFT', pf, 'RIGHT', 2, -2)
        end
        updateSmallIcons()

        if UnitGroupRolesAssigned then
            local roleIcon = pf:CreateTexture('DragonflightUIPartyFrameRoleIcon')
            roleIcon:SetSize(12, 12)
            roleIcon:SetPoint('TOPRIGHT', -5, -5)
            roleIcon:SetTexture('Interface\\Addons\\DragonflightUI\\Textures\\roleicons')
            roleIcon:SetTexCoord(0.015625, 0.265625, 0.03125, 0.53125)

            pf.RoleIcon = roleIcon

            local updateRoleIcon = function()
                local role = UnitGroupRolesAssigned(pf.unit)
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

            updateRoleIcon()

            pf:HookScript('OnEvent', function(self, event, ...)
                -- print('events', event)
                if event == 'GROUP_ROSTER_UPDATE' then updateRoleIcon() end
            end)
        end

        local healthbar = _G['PartyMemberFrame' .. i .. 'HealthBar']
        healthbar:SetSize(70 + 1, 10)
        healthbar:ClearAllPoints()
        healthbar:SetPoint('TOPLEFT', 45 - 1, -19)
        healthbar:GetStatusBarTexture():SetTexture(
            'Interface\\Addons\\DragonflightUI\\Textures\\Partyframe\\UI-HUD-UnitFrame-Party-PortraitOn-Bar-Health')
        healthbar:SetStatusBarColor(1, 1, 1, 1)

        local hpMask = healthbar:CreateMaskTexture()
        -- hpMask:SetPoint('TOPLEFT', pf, 'TOPLEFT', -29, 3)
        hpMask:SetPoint('CENTER', healthbar, 'CENTER', 0, 0)
        hpMask:SetTexture(
            'Interface\\Addons\\DragonflightUI\\Textures\\Partyframe\\UI-HUD-UnitFrame-Party-PortraitOn-Bar-Health-Mask',
            'CLAMPTOBLACKADDITIVE', 'CLAMPTOBLACKADDITIVE')
        hpMask:SetSize(70 + 1, 10)
        healthbar:GetStatusBarTexture():AddMaskTexture(hpMask)

        healthbar.DFHealthBarText = healthbar:CreateFontString('DragonflightUIHealthBarText', 'OVERLAY',
                                                               'TextStatusBarText')
        healthbar.DFHealthBarText:SetPoint('CENTER', healthbar, 'CENTER', 0, 0)
        healthbar.DFTextString = healthbar.DFHealthBarText

        healthbar.DFHealthBarTextLeft = healthbar:CreateFontString('DragonflightUIHealthBarTextLeft', 'OVERLAY',
                                                                   'TextStatusBarText')
        healthbar.DFHealthBarTextLeft:SetPoint('LEFT', healthbar, 'LEFT', 0, 0)
        healthbar.DFLeftText = healthbar.DFHealthBarTextLeft

        healthbar.DFHealthBarTextRight = healthbar:CreateFontString('DragonflightUIHealthBarTextRight', 'OVERLAY',
                                                                    'TextStatusBarText')
        healthbar.DFHealthBarTextRight:SetPoint('RIGHT', healthbar, 'RIGHT', 0, 0)
        healthbar.DFRightText = healthbar.DFHealthBarTextRight

        FitBarStatusText(healthbar)

        healthbar:HookScript('OnEnter', function(self)
            if healthbar.DFHealthBarTextRight:IsVisible() or healthbar.DFTextString:IsVisible() then
            else
                local max_health = UnitHealthMax('party' .. i)
                local health = UnitHealth('party' .. i)
                healthbar.DFTextString:SetText(health .. ' / ' .. max_health)
                healthbar.DFTextString:Show()
            end
            PartyMemberBuffTooltip_Update(pf);
        end)
        healthbar:HookScript('OnLeave', function(hb)
            healthbar.DFTextString:Hide()
            self:UpdatePartyHPBar(i)
        end)
        healthbar:HookScript('OnValueChanged', function(_)
            -- print('OnValueChanged', i)
            self:UpdatePartyHPBar(i)
        end)
        healthbar:HookScript('OnEvent', function(_, event, arg1)
            -- print('OnValueChanged', i)
            if event == 'UNIT_MAXHEALTH' then self:UpdatePartyHPBar(i) end
        end)

        self:UpdatePartyHPBar(i)

        local manabar = _G['PartyMemberFrame' .. i .. 'ManaBar']
        manabar:SetSize(74, 7)
        manabar:ClearAllPoints()
        manabar:SetPoint('TOPLEFT', 41, -30)
        manabar:GetStatusBarTexture():SetTexture(
            'Interface\\Addons\\DragonflightUI\\Textures\\Partyframe\\UI-HUD-UnitFrame-Party-PortraitOn-Bar-Mana')
        manabar:SetStatusBarColor(1, 1, 1, 1)

        local manaMask = manabar:CreateMaskTexture()
        -- hpMask:SetPoint('TOPLEFT', pf, 'TOPLEFT', -29, 3)
        manaMask:SetPoint('CENTER', manabar, 'CENTER', 0, 0)
        manaMask:SetTexture(
            'Interface\\Addons\\DragonflightUI\\Textures\\Partyframe\\UI-HUD-UnitFrame-Party-PortraitOn-Bar-Mana-Mask',
            'CLAMPTOBLACKADDITIVE', 'CLAMPTOBLACKADDITIVE')
        manaMask:SetSize(74, 7)
        manabar:GetStatusBarTexture():AddMaskTexture(manaMask)

        manabar.DFManaBarText = manabar:CreateFontString('DragonflightUIManaBarText', 'OVERLAY', 'TextStatusBarText')
        manabar.DFManaBarText:SetPoint('CENTER', manabar, 'CENTER', 1.5, 0)
        manabar.DFTextString = manabar.DFManaBarText

        manabar.DFManaBarTextLeft = manabar:CreateFontString('DragonflightUIManaBarTextLeft', 'OVERLAY',
                                                             'TextStatusBarText')
        manabar.DFManaBarTextLeft:SetPoint('LEFT', manabar, 'LEFT', 3, 0)
        manabar.DFLeftText = manabar.DFManaBarTextLeft

        manabar.DFManaBarTextRight = manabar:CreateFontString('DragonflightUIManaBarTextRight', 'OVERLAY',
                                                              'TextStatusBarText')
        manabar.DFManaBarTextRight:SetPoint('RIGHT', manabar, 'RIGHT', 0, 0)
        manabar.DFRightText = manabar.DFManaBarTextRight

        FitBarStatusText(manabar)

        manabar:HookScript('OnEnter', function(self)
            if manabar.DFManaBarTextRight:IsVisible() or manabar.DFTextString:IsVisible() then
            else
                local max_mana = UnitPowerMax('party' .. i)
                local mana = UnitPower('party' .. i)

                if max_mana == 0 then
                    manabar.DFTextString:SetText('')
                else
                    manabar.DFTextString:SetText(mana .. ' / ' .. max_mana)
                end
                manabar.DFTextString:Show()
            end
            PartyMemberBuffTooltip_Update(pf);
        end)
        manabar:HookScript('OnLeave', function(mb)
            manabar.DFTextString:Hide()
            self:UpdatePartyManaBar(i)
        end)

        self:UpdatePartyManaBar(i)

        manabar.DFUpdateFunc = function()
            self:UpdatePartyManaBar(i)
        end

        -- debuff
        local debuffOne = _G['PartyMemberFrame' .. i .. 'Debuff1']
        debuffOne:SetPoint('TOPLEFT', 120, -20)

        -- CompactUnitFrame_UpdateInRange
        local function updateRange()
            local inRange, checkedRange = UnitInRange('party' .. i);
            if (checkedRange and not inRange) then
                pf:SetAlpha(0.55);
            else
                pf:SetAlpha(1);
            end
        end

        pf:HookScript('OnUpdate', updateRange)

        pf:HookScript('OnEvent', function(p, event, ...)
            local texture = _G['PartyMemberFrame' .. i .. 'Texture']
            texture:SetTexture()
            texture:Hide()
            healthbar:SetStatusBarColor(1, 1, 1, 1)

            updateSmallIcons()
            updateRange()

            self:UpdatePartyHPBar(i)
        end)
    end

    local moduleRef = self.ModuleRef
    hooksecurefunc('PartyMemberBuffTooltip_Update', function(self)
        -- print('PartyMemberBuffTooltip_Update', self:GetName())
        local tooltip = PartyMemberBuffTooltip;

        local state = moduleRef.db.profile.party;
        local disableBuffTooltip = state.disableBuffTooltip

        if disableBuffTooltip == 'NEVER' then
            -- do nothing
        elseif disableBuffTooltip == 'ALWAYS' then
            tooltip:Hide()
            return;
        elseif disableBuffTooltip == 'INCOMBAT' then
            if InCombatLockdown() then
                tooltip:Hide()
                return;
            end
        end

        if state.orientation == 'vertical' then
            tooltip:ClearAllPoints()
            tooltip:SetPoint('LEFT', self, 'RIGHT', 0, 0)
        else
            tooltip:ClearAllPoints()
            tooltip:SetPoint('BOTTOMRIGHT', self, 'TOPRIGHT', 0, 0)
        end

        local scale = state.scale;
        if scale > 2 then
            scale = 2
        else
        end
        tooltip:SetScale(0.8 * scale)
    end)
end

local function DFTextStatusBar_UpdateTextStringWithValues(statusFrame, textString, value, valueMin, valueMax)
    if (statusFrame.DFLeftText and statusFrame.DFRightText) then
        statusFrame.DFLeftText:SetText("");
        statusFrame.DFRightText:SetText("");
        statusFrame.DFLeftText:Hide();
        statusFrame.DFRightText:Hide();
    end

    if ((tonumber(valueMax) ~= valueMax or valueMax > 0) and not (statusFrame.pauseUpdates)) then
        statusFrame:Show();

        if ((statusFrame.cvar and GetCVar(statusFrame.cvar) == "1" and statusFrame.textLockable) or
            statusFrame.forceShow) then
            textString:Show();
        elseif (statusFrame.lockShow > 0 and (not statusFrame.forceHideText)) then
            textString:Show();
        else
            textString:SetText("");
            textString:Hide();
            return;
        end

        local valueDisplay = value;
        local valueMaxDisplay = valueMax;
        -- Modern WoW always breaks up large numbers, whereas Classic never did.
        -- We'll remove breaking-up by default for Classic, but add a flag to reenable it.
        if (statusFrame.breakUpLargeNumbers) then
            if (statusFrame.capNumericDisplay) then
                valueDisplay = AbbreviateLargeNumbers(value);
                valueMaxDisplay = AbbreviateLargeNumbers(valueMax);
            else
                valueDisplay = BreakUpLargeNumbers(value);
                valueMaxDisplay = BreakUpLargeNumbers(valueMax);
            end
        end

        local textDisplay = GetCVar("statusTextDisplay");
        if (value and valueMax > 0 and
            ((textDisplay ~= "NUMERIC" and textDisplay ~= "NONE") or statusFrame.showPercentage) and
            not statusFrame.showNumeric) then
            if (value == 0 and statusFrame.zeroText) then
                textString:SetText(statusFrame.zeroText);
                statusFrame.isZero = 1;
                textString:Show();
            elseif (textDisplay == "BOTH" and not statusFrame.showPercentage) then
                if (statusFrame.DFLeftText and statusFrame.DFRightText) then
                    if (not statusFrame.powerToken or statusFrame.powerToken == "MANA") then
                        statusFrame.DFLeftText:SetText(math.ceil((value / valueMax) * 100) .. "%");
                        statusFrame.DFLeftText:Show();
                    end
                    statusFrame.DFRightText:SetText(valueDisplay);
                    statusFrame.DFRightText:Show();
                    textString:Hide();
                else
                    valueDisplay = "(" .. math.ceil((value / valueMax) * 100) .. "%) " .. valueDisplay .. " / " ..
                                       valueMaxDisplay;
                end
                textString:SetText(valueDisplay);
            else
                valueDisplay = math.ceil((value / valueMax) * 100) .. "%";
                if (statusFrame.prefix and
                    (statusFrame.alwaysPrefix or
                        not (statusFrame.cvar and GetCVar(statusFrame.cvar) == "1" and statusFrame.textLockable))) then
                    textString:SetText(statusFrame.prefix .. " " .. valueDisplay);
                else
                    textString:SetText(valueDisplay);
                end
            end
        elseif (value == 0 and statusFrame.zeroText) then
            textString:SetText(statusFrame.zeroText);
            statusFrame.isZero = 1;
            textString:Show();
            return;
        else
            statusFrame.isZero = nil;
            if (statusFrame.prefix and
                (statusFrame.alwaysPrefix or
                    not (statusFrame.cvar and GetCVar(statusFrame.cvar) == "1" and statusFrame.textLockable))) then
                textString:SetText(statusFrame.prefix .. " " .. valueDisplay .. " / " .. valueMaxDisplay);
            else
                textString:SetText(valueDisplay .. " / " .. valueMaxDisplay);
            end
        end
    else
        textString:Hide();
        textString:SetText("");
        if (not statusFrame.alwaysShow) then
            statusFrame:Hide();
        else
            statusFrame:SetValue(0);
        end
    end
end

local function DFTextStatusBar_UpdateTextString(textStatusBar)
    local textString = textStatusBar.DFTextString;
    if (textString) then
        local value = textStatusBar:GetValue();
        local valueMin, valueMax = textStatusBar:GetMinMaxValues();
        DFTextStatusBar_UpdateTextStringWithValues(textStatusBar, textString, value, valueMin, valueMax);
    end
end

function SubModuleMixin:UpdatePartyManaBar(i)
    local pf = _G['PartyMemberFrame' .. i]
    local manabar = _G['PartyMemberFrame' .. i .. 'ManaBar']
    if UnitExists(pf.unit) then
        local powerType, powerTypeString = UnitPowerType(pf.unit)
        -- powerTypeString = 'RUNIC_POWER'

        if powerTypeString == 'MANA' then
            manabar:GetStatusBarTexture():SetTexture(
                'Interface\\Addons\\DragonflightUI\\Textures\\Partyframe\\UI-HUD-UnitFrame-Party-PortraitOn-Bar-Mana')
        elseif powerTypeString == 'FOCUS' then
            manabar:GetStatusBarTexture():SetTexture(
                'Interface\\Addons\\DragonflightUI\\Textures\\Partyframe\\UI-HUD-UnitFrame-Party-PortraitOn-Bar-Focus')
        elseif powerTypeString == 'RAGE' then
            manabar:GetStatusBarTexture():SetTexture(
                'Interface\\Addons\\DragonflightUI\\Textures\\Partyframe\\UI-HUD-UnitFrame-Party-PortraitOn-Bar-Rage')
        elseif powerTypeString == 'ENERGY' then
            manabar:GetStatusBarTexture():SetTexture(
                'Interface\\Addons\\DragonflightUI\\Textures\\Partyframe\\UI-HUD-UnitFrame-Party-PortraitOn-Bar-Energy')
        elseif powerTypeString == 'RUNIC_POWER' then
            manabar:GetStatusBarTexture():SetTexture(
                'Interface\\Addons\\DragonflightUI\\Textures\\Partyframe\\UI-HUD-UnitFrame-Party-PortraitOn-Bar-RunicPower')
        end
        manabar:SetStatusBarColor(1, 1, 1, 1)
        DFTextStatusBar_UpdateTextString(manabar)
    else
    end
    -- print('UpdatePartyManaBar', i, powerType, powerTypeString)
end

function SubModuleMixin:UpdatePartyHPBar(i)
    local pf = _G['PartyMemberFrame' .. i]
    local healthbar = _G['PartyMemberFrame' .. i .. 'HealthBar']
    if UnitExists(pf.unit) then
        if self.ModuleRef.db.profile.party.classcolor then
            healthbar:GetStatusBarTexture():SetTexture(
                'Interface\\Addons\\DragonflightUI\\Textures\\Partyframe\\UI-HUD-UnitFrame-Party-PortraitOn-Bar-Health-Status')
            local localizedClass, englishClass, classIndex = UnitClass(pf.unit)
            healthbar:SetStatusBarColor(DF:GetClassColor(englishClass, 1))
        elseif self.ModuleRef.db.profile.party.gradient then
            healthbar:GetStatusBarTexture():SetTexture(
                'Interface\\Addons\\DragonflightUI\\Textures\\Partyframe\\UI-HUD-UnitFrame-Party-PortraitOn-Bar-Health-Status')
            local r, g, b = Helper:ColorGradiant(Helper:GetUnitHealthPercent(pf.unit))
            healthbar:SetStatusBarColor(r, g, b, 1)
        else
            healthbar:GetStatusBarTexture():SetTexture(
                'Interface\\Addons\\DragonflightUI\\Textures\\Partyframe\\UI-HUD-UnitFrame-Party-PortraitOn-Bar-Health')
            healthbar:SetStatusBarColor(1, 1, 1, 1)
        end
        DFTextStatusBar_UpdateTextString(healthbar)
    else
    end
end

function SubModuleMixin:AddStateUpdater()
    for i = 1, 4 do
        local pf = _G['PartyMemberFrame' .. i]
        Mixin(pf, DragonflightUIStateHandlerMixin)
        pf:InitStateHandler()
        pf:SetUnit('party' .. i)
    end
end

