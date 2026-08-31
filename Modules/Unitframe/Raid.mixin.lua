local addonName, addonTable = ...;
local DF = addonTable.DF;
local L = addonTable.L;
local Helper = addonTable.Helper;

local subModuleName = 'RaidFrame';
local SubModuleMixin = {};
addonTable.SubModuleMixins[subModuleName] = SubModuleMixin;


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
-- Always converted, in both directions, using Blizzard's own function.
--
-- The stored value is NOT the displayed one. Blizzard's dialog writes through
-- ConvertValue(value, false) and reads through ConvertValue(value, true):
--
--   ConvertValueDiffFromMin: stored = shown - minValue
--   ConvertValueDefault:     stored = (shown - minValue) / stepSize
--
-- An earlier version of this took the stored number as absolute whenever it happened
-- to fall inside the setting's range, which was a guess and it was wrong. FrameWidth
-- is minValue 72, maxValue 144, DiffFromMin, and a stored 98 therefore means 170 -
-- past the maximum, clamped to 144. Showing it as 98 and writing 98 straight back
-- made every reload come up at the far end of the slider, and it got worse each time.
--
-- Every slider was affected the same way: frame width, frame height, row size,
-- opacity, icon size. Dropdowns and checkboxes were not - they carry no ConvertValue,
-- their stored value is the enum or the flag itself.
--
-- The forDisplay direction calls self:ClampValue, which lives on the dialog's slider
-- rather than on the data. A proxy supplies it so Blizzard's arithmetic still runs;
-- clamping to minValue..maxValue is what the field names describe, and it is also what
-- repairs a value stored out of range - the next write brings it back in.
local function ConvertSettingValue(info, value, forDisplay)
    if not (info and info.ConvertValue and value) then return value end

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

function SubModuleMixin:Init()
    self.ModuleRef = DF:GetModule('Unitframe')
    self:SetDefaults()
    self:SetupOptions()
    -- self:SetScript('OnEvent', self.OnEvent);
end

function SubModuleMixin:SetDefaults()
    -- Position, scale and visibility are live now, so they are no longer commented out.
    --
    -- The anchor default is deliberately UIParent TOPLEFT at a zero offset rather than
    -- invented coordinates: Update() calibrates once from wherever the raid container
    -- already sits and writes that into the profile, so the first run does not teleport
    -- anybody's raid frames to a spot this file guessed at.
    --
    -- The commented block that used to trail this table is gone. Ten of its keys were
    -- duplicates of the visibility defaults above, and the other five - breakUpLarge-
    -- Numbers, enableThreatGlow, hideStatusbarText, offset, hideIndicator - belong to
    -- the focus, target and pet frames and were never read here. 'override' went with
    -- them: nothing in the addon reads it, on any frame.
    local defaults = {
        scale = 1.0,
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

                -- Said out loud, per setting, where it does and does not show up.
                --
                -- The preview is built from DFEditModePreviewRaidTemplate, whose UpdateState
                -- reads seven fields. Sort order, the profile template and icon size are
                -- not among them, and row size is fixed at five unless the groups are
                -- combined - that last one is Blizzard's own rule, mirrored from
                -- UpdateRaidContainerFlow. All of them still apply to the real raid frames.
                --
                -- Blizzard hides settings that do not apply through ShouldShowSetting, but
                -- this settings list has no dynamic hidden support, so saying it is the
                -- honest option: a control that silently does nothing is worse than one
                -- that explains itself.
                local NOTES = {
                    RowSize = ' Only applies when Groups is set to one of the combined options.',
                    SortPlayersBy = ' Affects the real raid frames; the preview does not reorder.',
                    IconSize = ' Affects the real raid frames; not shown in the preview.'
                }

                local note = ''
                if Enum and Enum.EditModeUnitFrameSetting then
                    for key, text in pairs(NOTES) do
                        if Enum.EditModeUnitFrameSetting[key] == setting then note = text end
                    end
                end

                local option = {
                    name = info.name or tostring(setting),
                    desc = 'Blizzard Edit Mode setting. Applied at once and kept in your Edit Mode layout.' .. note,
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
        }
    }
    if true then
        local moreOptions = {
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
        -- Exposed so Setup can build these BEFORE it registers the edit mode selection.
        -- RegisterOptions copies options.args into its own filtered table once
        -- (Editmode.mixin.lua:994) and never looks again, so anything added later shows
        -- up in the config window - which reads the table lazily - but never in the edit
        -- mode panel. That is the difference the report describes.
        self.BuildEditModeArgs = function() return BuildRaidEditModeArgs(optionsRaid.args) end

        if self.BuildEditModeArgs() == 0 then
            local optsWatcher = CreateFrame('Frame')
            optsWatcher:RegisterEvent('PLAYER_ENTERING_WORLD')
            optsWatcher:SetScript('OnEvent', function(watcherSelf)
                -- One frame later: PLAYER_ENTERING_WORLD fires before some systems
                -- finish registering themselves with the Edit Mode manager.
                C_Timer.After(0, function()
                    if self.BuildEditModeArgs() > 0 then watcherSelf:UnregisterAllEvents() end
                end)
            end)
        end

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

            -- The Settings.GetValue branch for proxy CVars is gone with the options that
            -- used it. Fourteen of them were commented out here under a header warning
            -- that setting them from an addon taints the UI - keepGroupsTogether,
            -- horizontalGroups, sortBy, class colours, frame height and width and the
            -- rest. They are all Edit Mode settings now, read from the registered system
            -- frame above, so nothing declares a proxy any more. Re-add the branch along
            -- with the option if one ever needs it.

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

                -- Re-applied so the preview follows. Frame width, height, row size, the
                -- group display type and the raid size all change how it has to be laid
                -- out, and UpdateRaidPreview reads them straight back out of the system
                -- frame.
                if Module.ApplySettings then Module:ApplySettings('raid') end

                -- Deliberately NOT for sliders.
                --
                -- Refreshing an option panel rebuilds its rows, which replaces the very
                -- widget the mouse is holding - so a slider could only ever be nudged by
                -- clicking, never dragged. Dropdowns and checkboxes fire once per change
                -- and are safe.
                --
                -- The slider being dragged already shows its own value; the other panel
                -- catches up when it is next opened.
                if blizz.kind ~= 'range' then
                    if Module.RefreshOptionScreens then Module:RefreshOptionScreens() end

                    local editmode = DF.GetModule and DF:GetModule('Editmode')
                    if editmode and editmode.RefreshOptionScreens then
                        pcall(editmode.RefreshOptionScreens, editmode)
                    end
                end

                return
            end

            if sub == 'useCompactPartyFrames' then
                addonTable.SubModuleMixins['Party'].SetRaidStylePartyFrames(value)
                return
            end

            -- Same as the getter: no option here declares a proxy any more.

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

        -- The fake raid preview is optional, and on this client it cannot work.
        --
        -- DragonflightUIEditModePreviewRaidFrameMixin:UpdateState opens with
        --
        --   local settings = GetRaidProfileFlattenedOptions(GetActiveRaidProfile())
        --   local managerSize = CompactRaidFrameManager.container:GetHeight()
        --
        -- which is the pre-Edit-Mode raid profile API. None of it exists now that raid
        -- frames are an Edit Mode system, so OnLoad threw "attempt to call a nil value"
        -- - and because this runs inside SetupSubmodules, it took every submodule after
        -- the raid one with it. That is the broken edit mode in the report.
        --
        -- The CompactUnitFrameProfiles gate that used to sit in front of all this was
        -- what kept it unreachable. Removing that gate is what finally produced a
        -- selection, so the preview is what has to become conditional: it is decoration
        -- inside the placeholder, while the selection is the thing being fixed.
        local hasRaidProfileApi = type(GetRaidProfileFlattenedOptions) == 'function' and
                                      type(GetActiveRaidProfile) == 'function' and CompactRaidFrameManager ~= nil and
                                      CompactRaidFrameManager.container ~= nil

        if hasRaidProfileApi then
            local ok, err = pcall(function()
                local fakeRaid = CreateFrame('Frame', 'DragonflightUIEditModeRaidFramePreview', f,
                                             'DFEditModePreviewRaidFrameTemplate')
                fakeRaid:OnLoad()
                fakeRaid:SetPoint('TOPLEFT', f, 'TOPLEFT', 4, -7)
                fakeRaid:SetPoint('BOTTOMRIGHT', f, 'BOTTOMRIGHT', 0, 0)
                fakeRaid:Show()

                self.PreviewRaid = fakeRaid
            end)

            -- Reported, not swallowed, but never fatal: a missing preview must not cost
            -- the selection or the submodules that come after this one.
            if not ok then geterrorhandler()('DFUI raid edit mode preview: ' .. tostring(err)) end
        end

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
            -- Blizzard's own way of putting raid frames on screen for editing, copied
            -- from EditModeAccountSettingsMixin:RefreshRaidFrames:
            --
            --   CompactRaidFrameManager_SetSetting("IsShown", true)
            --   CompactRaidFrameContainer:ApplyToFrames("group", CompactRaidGroup_UpdateUnits)
            --   CompactRaidFrameContainer:TryUpdate()
            --   EditModeManagerFrame:UpdateRaidContainerFlow()
            --   UpdateRaidAndPartyFrames()
            --
            -- That is what fills the container and gives it a real size, which is also
            -- what the placeholder needs - so there is no reason to rebuild a preview of
            -- our own. UpdateRaidContainerFlow derives the layout from the same settings
            -- this panel now edits: RaidGroupDisplayType picks the orientation, RowSize
            -- the frames per line.
            --
            -- The old ResizeFrame_SavePosition call and the
            -- CompactRaidFrameManager_UpdateContainerVisibility hook are gone: they drove
            -- the pre-Edit-Mode raid manager, and position now lives in our profile.
            showFunction = function()
                f:Show()

                local ok, err = pcall(function()
                    if CompactRaidFrameManager_SetSetting then
                        CompactRaidFrameManager_SetSetting('IsShown', true)
                    end

                    local c = _G['CompactRaidFrameContainer']
                    if c and c.ApplyToFrames and CompactRaidGroup_UpdateUnits then
                        c:ApplyToFrames('group', CompactRaidGroup_UpdateUnits)
                    end
                    if c and c.TryUpdate then c:TryUpdate() end

                    if EditModeManagerFrame and EditModeManagerFrame.UpdateRaidContainerFlow then
                        EditModeManagerFrame:UpdateRaidContainerFlow()
                    end
                    if UpdateRaidAndPartyFrames then UpdateRaidAndPartyFrames() end
                end)
                if not ok then geterrorhandler()('DFUI raid preview show: ' .. tostring(err)) end

                -- Re-measure once the container has content, so the selection covers it.
                C_Timer.After(0, function() self:Update() end)
            end,
            hideFunction = function()
                -- Only what we turned on. TryUpdate afterwards so the container shrinks
                -- back rather than keeping the forced-open extent.
                local ok, err = pcall(function()
                    if CompactRaidFrameManager_SetSetting then
                        CompactRaidFrameManager_SetSetting('IsShown', false)
                    end

                    local c = _G['CompactRaidFrameContainer']
                    if c and c.TryUpdate then c:TryUpdate() end
                    if UpdateRaidAndPartyFrames then UpdateRaidAndPartyFrames() end
                end)
                if not ok then geterrorhandler()('DFUI raid preview hide: ' .. tostring(err)) end
            end
        });

        if self.PreviewRaid then pcall(self.PreviewRaid.UpdateState, self.PreviewRaid, nil) end
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

    -- Isolated, because this runs inside SetupSubmodules. An error thrown from here
    -- used to abort the whole chain, so the raid frame took the submodules after it
    -- down as well - the same reasoning Unitframe.lua's updateSub already applies to
    -- UpdateState. Report it and let the rest set itself up.
    local function initRaidTracked()
        if addonTable.RaidInitDiag.initRan then return end

        -- Deliberately gated on the settings existing first. RegisterOptions snapshots
        -- options.args, so registering before Blizzard's Edit Mode data is readable
        -- produces a panel with only scale, position and visibility in it - exactly what
        -- the report showed, while the config window had all ten.
        local built = (self.BuildEditModeArgs and self.BuildEditModeArgs()) or 0
        addonTable.RaidInitDiag.settingsBuilt = built

        if built == 0 then return end

        addonTable.RaidInitDiag.initRan = true

        local ok, err = pcall(initRaid)
        if not ok then
            addonTable.RaidInitDiag.initError = tostring(err)
            geterrorhandler()('DFUI raid edit mode setup: ' .. tostring(err))
        end
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
            -- Kept registered until it actually works: the settings can be unreadable at
            -- the first PLAYER_ENTERING_WORLD, and unregistering there would leave the
            -- selection unbuilt for the session.
            C_Timer.After(0, function()
                initRaidTracked()
                if addonTable.RaidInitDiag.initRan then watcherSelf:UnregisterAllEvents() end
            end)
        end)
    end
end

function SubModuleMixin:OnEvent(event, ...)
end

-- The preview inside the edit mode placeholder.
--
-- Built from DFEditModePreviewRaidTemplate, the same template the party frame's preview
-- uses for its raid-style variant, which is why this needs nothing new: the per-frame
-- DragonflightUIEditModePreviewRaidMixin:UpdateState is a pure function of a state table
-- and reads only frameWidth, frameHeight, keepGroupsTogether, horizontalGroups,
-- displayBorder, displayPowerBar and useClassColors.
--
-- The dead raid profile API was never in that mixin. It sat one level up, in the
-- container's own UpdateState, which fetched GetRaidProfileFlattenedOptions and fed the
-- children from it. So the fix is to build that state table from Blizzard's Edit Mode
-- settings instead - the same values UpdateRaidContainerFlow uses.
-- Forty, because that is the largest raid ViewRaidSize offers. Frames are created once
-- and the surplus stays hidden.
local RAID_PREVIEW_MAX = 40

-- How many member frames the chosen raid size shows.
--
-- Blizzard's numbers, from EditModeManagerFrameMixin:GetNumRaidMembersForcedShown - Ten
-- gives 10, TwentyFive 25, Forty 40. The first version of this ignored ViewRaidSize
-- entirely and always drew ten, which is why switching to 25 or 40 did nothing.
local function GetRaidPreviewMemberCount()
    if not (Enum and Enum.EditModeUnitFrameSetting and Enum.ViewRaidSize) then return 10 end

    local size = addonTable:GetRaidEditModeSettingBySetting(Enum.EditModeUnitFrameSetting.ViewRaidSize)

    if size == Enum.ViewRaidSize.Forty then return 40 end
    if size == Enum.ViewRaidSize.TwentyFive then return 25 end

    return 10
end

-- How many member frames per line, and which way the rows run.
--
-- Mirrors EditModeManagerFrameMixin:UpdateRaidContainerFlow: separate groups always run
-- five to a line, combined groups take RowSize, and the display type decides whether the
-- flow is vertical or horizontal.
local function GetRaidPreviewLayout()
    -- Display values, not stored ones.
    --
    -- The preview draws in pixels, so it needs what the slider shows, and the two are
    -- not the same number - see ConvertSettingValue. Reading them raw is what made the
    -- preview frames the wrong size while the real ones were right.
    --
    -- Dropdowns and checkboxes have no ConvertValue, so this is a no-op for them and
    -- their enum values come through untouched.
    local displayInfo = GetUnitFrameDisplayInfo()

    local function setting(key)
        if not (Enum and Enum.EditModeUnitFrameSetting) then return nil end

        local id = Enum.EditModeUnitFrameSetting[key]
        if id == nil then return nil end

        local stored = addonTable:GetRaidEditModeSettingBySetting(id)
        if stored == nil then return nil end

        if displayInfo then
            for _, info in ipairs(displayInfo) do
                if info.setting == id then return ConvertSettingValue(info, stored, true) end
            end
        end

        return stored
    end

    local displayType = setting('RaidGroupDisplayType')
    local rowSize = setting('RowSize') or 5

    local combined, horizontal = false, false

    if Enum and Enum.RaidGroupDisplayType then
        local t = Enum.RaidGroupDisplayType
        horizontal = (displayType == t.SeparateGroupsHorizontal) or (displayType == t.CombineGroupsHorizontal)
        combined = (displayType == t.CombineGroupsVertical) or (displayType == t.CombineGroupsHorizontal)
    end

    return {
        frameWidth = setting('FrameWidth') or 72,
        frameHeight = setting('FrameHeight') or 36,
        perLine = combined and math.max(rowSize, 1) or 5,
        horizontal = horizontal,
        combined = combined,
        displayBorder = (setting('DisplayBorder') or 0) ~= 0,
        opacity = setting('Opacity')
    }
end

function SubModuleMixin:EnsureRaidPreview(holder)
    if self.PreviewFrames then return self.PreviewFrames end
    if not holder then return nil end

    self.PreviewFrames = {}

    for i = 1, RAID_PREVIEW_MAX do
        local ok, frame = pcall(CreateFrame, 'Frame', 'DragonflightUIEditModeRaidPreview' .. i, holder,
                                'DFEditModePreviewRaidTemplate')
        if not (ok and frame) then break end

        -- OnLoad sizes itself and picks a random unit for the fake name and class
        -- colour. Guarded because a throw here would leave a half-built preview.
        pcall(frame.OnLoad, frame)
        frame:Hide()

        self.PreviewFrames[i] = frame
    end

    if #self.PreviewFrames == 0 then self.PreviewFrames = nil end

    return self.PreviewFrames
end

-- Lay the preview out, and report the extent it needs.
function SubModuleMixin:UpdateRaidPreview(holder)
    local frames = self:EnsureRaidPreview(holder)
    if not frames then return 0, 0 end

    local layout = GetRaidPreviewLayout()

    -- Only while our edit mode is open, and only when the real frames are not already
    -- there.
    --
    -- The selection's showFunction asks Blizzard to force the raid frames on screen, so
    -- in a group there is something real to look at and stacking fakes on top of it would
    -- just be two sets of frames in the same place. Alone, the container stays empty at
    -- about a pixel wide, and that is when the preview earns its keep.
    local editmode = DF.GetModule and DF:GetModule('Editmode')
    local container = _G['CompactRaidFrameContainer']
    local realFramesUp = container and container:IsShown() and (container:GetWidth() or 0) > 2

    if not (editmode and editmode.IsEditMode) or realFramesUp then
        for _, frame in ipairs(frames) do frame:Hide() end
        return 0, 0
    end

    -- Blizzard's own state shape, so the template's UpdateState needs no changes.
    local state = {
        frameWidth = layout.frameWidth,
        frameHeight = layout.frameHeight,
        keepGroupsTogether = layout.combined,
        horizontalGroups = layout.horizontal,
        displayBorder = layout.displayBorder,
        displayPowerBar = true,
        useClassColors = true
    }

    local maxX, maxY = 0, 0
    local wanted = GetRaidPreviewMemberCount()

    for i, frame in ipairs(frames) do
        if i > wanted then
            frame:Hide()
        else
            pcall(frame.UpdateState, frame, state)

            -- Column and row, flowing the way UpdateRaidContainerFlow would.
            local index = i - 1
            local major = index % layout.perLine
            local minor = math.floor(index / layout.perLine)

            local col, row
            if layout.horizontal then
                col, row = major, minor
            else
                col, row = minor, major
            end

            local x = col * layout.frameWidth
            local y = row * layout.frameHeight

            frame:ClearAllPoints()
            frame:SetPoint('TOPLEFT', holder, 'TOPLEFT', x, -y)
            frame:SetSize(layout.frameWidth, layout.frameHeight)

            -- Opacity is not one of the seven fields the template's UpdateState reads, but
            -- it is the one remaining setting the preview can honour honestly: it is a
            -- plain alpha on the frame.
            if layout.opacity then frame:SetAlpha(math.max(layout.opacity, 1) / 100) end

            frame:Show()

            maxX = math.max(maxX, x + layout.frameWidth)
            maxY = math.max(maxY, y + layout.frameHeight)
        end
    end

    return maxX, maxY
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

    -- Without this a drag moves nothing and commits nothing.
    -- DFEditModeSystemSelectionBaseMixin:OnDragStop is what writes anchor, x and y back
    -- into the profile and then calls ApplySettings and RefreshOptionScreens - but it
    -- never runs on a frame the client will not move. Every other unit frame holder
    -- here sets this in its own Setup; the raid one was the omission.
    moveFrame:SetMovable(true)

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

    -- Sized from the real container, but never below something a mouse can grab.
    --
    -- The previous version took the container's size whenever it was wider than one
    -- pixel, and /df log raidopts caught the result: "DragonflightUIRaidMoveFrame 1x200".
    -- An empty CompactRaidFrameContainer reports a width just over 1, so the holder came
    -- out one pixel wide and there was nothing to drag - which is why moving the frame
    -- did nothing, not the missing SetMovable.
    --
    -- A floor rather than a threshold: the holder grows with the container when there is
    -- one, and stays usable when there is not.
    -- The preview is laid out first, because while edit mode is open it is what defines
    -- how big the placeholder has to be. Outside edit mode it reports nothing and the
    -- real container decides.
    local previewW, previewH = self:UpdateRaidPreview(holder)

    local MIN_HOLDER_SIZE = 200
    local w = math.max((container and container:GetWidth()) or 0, previewW)
    local h = math.max((container and container:GetHeight()) or 0, previewH)
    holder:SetSize(math.max(w, MIN_HOLDER_SIZE), math.max(h, MIN_HOLDER_SIZE))

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
