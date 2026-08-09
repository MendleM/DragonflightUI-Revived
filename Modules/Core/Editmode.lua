local addonName, addonTable = ...;
local Helper = addonTable.Helper;
local DF = LibStub('AceAddon-3.0'):GetAddon('DragonflightUI')
local L = LibStub("AceLocale-3.0"):GetLocale("DragonflightUI")
local mName = 'Editmode'
local Module = DF:NewModule(mName, 'AceConsole-3.0', 'AceHook-3.0')

Mixin(Module, DragonflightUIModulesMixin)
Mixin(Module, CallbackRegistryMixin)

local defaults = {
    profile = {
        scale = 1,
        general = {
            showGrid = true,
            gridSize = 20,
            snapGrid = true,
            snapElements = true,
            blockBlizzardEditMode = true
        },
        advanced = {
            -- actionbar
            ActionBars = true,
            StanceBar = true,
            PossessBar = true,
            PetBar = true,
            TotemBar = true,
            Bags = true,
            MicroMenu = true,
            FPS = true,
            XPBar = true,
            RepBar = true,
            ExtraActionButton = true,
            FlyoutBar = true,
            GroupLootContainer = true,
            VehicleLeave = true,
            -- Bossframe
            BossFrames = true,
            -- buffs,
            Buffs = true,
            Debuffs = true,
            -- castbar
            Castbars = true,
            MirrorTimer = true,
            -- minimap
            Minimap = true,
            Tracker = true,
            Durability = true,
            LFG = true,
            -- tooltip
            GameTooltip = true,
            -- UI
            WidgetBelow = true,
            -- unitframes
            PlayerFrame = true,
            Player_PowerBarAlt = true,
            PlayerSecondaryRes = true,
            PlayerTotemFrame = true,
            PetFrame = true,
            TargetFrame = true,
            TargetOfTargetFrame = true,
            FocusFrame = true,
            FocusTargetFrame = true,
            PartyFrame = true,
            RaidFrame = true
        }
    }
}
Module:SetDefaults(defaults)

-- Modules whose frame positions the Blizzard layout knows nothing about, and
-- which therefore have to be re-applied after every layout application (see
-- applyNow). Modules can add themselves at load time.
addonTable.BlizzEditmodeReapply = addonTable.BlizzEditmodeReapply or {'Unitframe', 'Chat'}

function addonTable:RegisterBlizzEditmodeReapply(name)
    for _, existing in ipairs(addonTable.BlizzEditmodeReapply) do
        if existing == name then return end
    end
    table.insert(addonTable.BlizzEditmodeReapply, name)
end

local function getDefaultStr(key, sub)
    return Module:GetDefaultStr(key, sub)
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

local generalOptions = {
    type = 'group',
    name = 'EditMode',
    get = getOption,
    set = setOption,
    hideDefault = true,
    args = {
        showGrid = {
            type = 'toggle',
            name = 'Show Grid',
            desc = '' .. getDefaultStr('showGrid', 'general'),
            order = 100.5,
            small = true
        },
        gridSize = {
            type = 'range',
            name = 'Grid Size',
            desc = '' .. getDefaultStr('gridSize', 'general'),
            min = 8,
            max = 128,
            bigStep = 4,
            order = 101,
            small = true
        },
        snapGrid = {
            type = 'toggle',
            name = 'Snap to Grid',
            desc = '' .. getDefaultStr('snapGrid', 'general'),
            order = 102,
            small = true
        },
        blockBlizzardEditMode = {
            type = 'toggle',
            name = "Disable Blizzard's Edit Mode",
            desc = "Blizzard's Edit Mode moves the same frames this one does, and saving in it writes its whole layout over ours. With this on, the game hides its own way in - the Escape menu entry, the right-click menu on a unit frame, the raid manager button. " ..
                getDefaultStr('blockBlizzardEditMode', 'general'),
            order = 103,
            width = 'double'
        }
        -- snapElements = {
        --     type = 'toggle',
        --     name = 'Snap to Elements',
        --     desc = '*NOT YET IMPLEMENTED - COMING SOON*' .. getDefaultStr('snapElements', 'general'),
        --     order = 103,
        --     small = true
        -- }
    }
}

local advancedOptions;
if true then
    --
    advancedOptions = {
        type = 'group',
        name = 'EditMode',
        get = getOption,
        set = setOption,
        hideDefault = true,
        args = {
            headerActionbar = {
                type = 'header',
                name = 'Actionbar',
                desc = '...',
                order = 100,
                sortComparator = DFSettingsListMixin.AlphaSortComparator,
                isExpanded = true,
                editmode = true
            },
            headerCombat = {
                type = 'header',
                name = 'Combat',
                desc = '...',
                order = 200,
                sortComparator = DFSettingsListMixin.AlphaSortComparator,
                isExpanded = true,
                editmode = true
            },
            headerFrames = {
                type = 'header',
                name = 'Frames',
                desc = '...',
                order = 300,
                sortComparator = DFSettingsListMixin.AlphaSortComparator,
                isExpanded = true,
                editmode = true
            },
            headerMisc = {
                type = 'header',
                name = 'Misc',
                desc = '...',
                order = 400,
                sortComparator = DFSettingsListMixin.AlphaSortComparator,
                isExpanded = true,
                editmode = true
            }
        }
    }

    local displayTable = {}
    -- actionbar
    displayTable['ActionBars'] = L['ActionbarName']
    displayTable['FlyoutBar'] = L['ModuleFlyout']
    displayTable['MicroMenu'] = L['MicroMenu']
    displayTable['PetBar'] = L['PetBar']
    displayTable['PossessBar'] = L['PossessBar']
    displayTable['StanceBar'] = L['StanceBar']
    displayTable['TotemBar'] = L['TotemBar']
    displayTable['ExtraActionButton'] = L['ExtraActionButtonOptionsName']
    displayTable['VehicleLeave'] = L['VehicleLeaveButton']

    -- combat
    displayTable['Buffs'] = L['BuffsOptionsName']
    displayTable['Debuffs'] = L['DebuffsOptionsName']
    displayTable['Castbars'] = L['CastbarName']
    displayTable['MirrorTimer'] = L['CastbarMirrorTimerName']

    -- frames
    displayTable['PlayerFrame'] = L['PlayerFrameName']
    displayTable['PlayerSecondaryRes'] = L['PlayerSecondaryResName']
    displayTable['PlayerTotemFrame'] = L['PlayerTotemFrameName']
    displayTable['PetFrame'] = L['PetFrameName']
    displayTable['TargetFrame'] = L['TargetFrameName']
    displayTable['TargetOfTargetFrame'] = L['TargetOfTargetFrameName']
    displayTable['FocusFrame'] = L['FocusFrameName']
    displayTable['FocusTargetFrame'] = L['FocusFrameToTName']
    displayTable['PartyFrame'] = L['PartyFrameName']
    displayTable['RaidFrame'] = L['RaidFrameName']
    displayTable['BossFrames'] = L['BossFrameName']

    -- misc
    displayTable['Bags'] = L['BagsOptionsName']
    displayTable['FPS'] = L['FPSOptionsName']
    displayTable['LFG'] = L['MinimapLFGName']
    displayTable['Minimap'] = L['MinimapName']
    displayTable['Tracker'] = L['MinimapTrackerName']
    displayTable['Durability'] = L['MinimapDurabilityName']
    displayTable['GameTooltip'] = L['TooltipName']
    displayTable['Player_PowerBarAlt'] = L['PowerBarAltName']
    displayTable['GroupLootContainer'] = L['GroupLootContainerName']
    displayTable['WidgetBelow'] = L['WidgetBelowName']

    local function AddTableToCategory(t, header)
        for k, v in ipairs(t) do
            --
            advancedOptions.args[v] = {
                type = 'toggle',
                name = displayTable[v] or v,
                desc = '' .. getDefaultStr(v, 'advanced'),
                order = k,
                small = true,
                group = header,
                editmode = true
            }
        end
    end

    -- actionbar
    local actionbarFrames = {
        'ActionBars', 'FlyoutBar', 'MicroMenu', 'PetBar', 'PossessBar', 'StanceBar', 'TotemBar', 'VehicleLeave'
    };
    if DF.Cata then table.insert(actionbarFrames, 'ExtraActionButton') end
    AddTableToCategory(actionbarFrames, 'headerActionbar');

    -- combat
    local combatFrames = {'Buffs', 'Debuffs', 'Castbars', 'MirrorTimer'};
    AddTableToCategory(combatFrames, 'headerCombat');

    -- frames
    local framesFrames = {
        'PlayerFrame', 'PlayerSecondaryRes', 'PlayerTotemFrame', 'PetFrame', 'TargetFrame', 'TargetOfTargetFrame',
        'PartyFrame', 'RaidFrame'
    }
    if DF.Wrath then
        table.insert(framesFrames, 'FocusFrame')
        table.insert(framesFrames, 'FocusTargetFrame')
        table.insert(framesFrames, 'BossFrames')

    end
    AddTableToCategory(framesFrames, 'headerFrames')

    -- misc
    local miscFrames = {
        'Bags', 'FPS', 'LFG', 'GroupLootContainer', 'Minimap', 'Tracker', 'Durability', 'GameTooltip', 'WidgetBelow'
    }
    if DF.Cata then table.insert(miscFrames, 'Player_PowerBarAlt') end
    AddTableToCategory(miscFrames, 'headerMisc')

    advancedOptions.set = function(...)
        setOption(...)
        -- only the overlays change; see RefreshSelectionVisibility
        Module:RefreshSelectionVisibility()
    end
end

function Module:OnInitialize()
    DF:Debug(self, 'Module ' .. mName .. ' OnInitialize()')
    self.db = DF.db:RegisterNamespace(mName, defaults)

    self:SetEnabledState(DF.ConfigModule:GetModuleEnabled(mName))

    -- DF:RegisterModuleOptions(mName, generalOptions)

    ---@diagnostic disable-next-line: param-type-mismatch
    CallbackRegistryMixin.OnLoad(self);
end

function Module:OnEnable()
    DF:Debug(self, 'Module ' .. mName .. ' OnEnable()')
    self:SetWasEnabled(true)

    self:EnableAddonSpecific()

    Module:CreateGrid()
    Module:SetupMainmenuButton()

    Module:RegisterChatCommand('editmode', 'SlashCommand')

    Module:GenerateCallbackEvents({"OnEditMode", 'OnSelection'})
    self:RegisterCallback('OnEditMode', function(self, value)
        DF:Debug(self, '~> OnEditMode', value)
    end, self)
    self:RegisterCallback('OnSelection', function(self, value)
        DF:Debug(self, '~> OnSelection', value and value:GetName())
    end, self)

    Module:ApplySettings()
    Module:RegisterOptionScreens()

    self:SecureHook(DF, 'RefreshConfig', function()
        -- print('RefreshConfig', mName)
        Module:ApplySettings()
        Module:RefreshOptionScreens()
    end)
end

function Module:OnDisable()
end

function Module:RegisterOptionScreens()
    -- DF.ConfigModule:RegisterOptionScreen('Misc', 'Darkmode', {
    --     name = 'Darkmode',
    --     sub = 'general',
    --     options = generalOptions,
    --     default = function()
    --         setDefaultSubValues('general')
    --     end
    -- })

    Module.EditModeFrame:SetupOptions({
        name = 'EditMode',
        sub = 'general',
        options = generalOptions,
        default = function()
            setDefaultSubValues('general')
        end,
        shouldDisplayAsap = true
    }, true)

    Module.EditModeFrame:SetupAdvancedOptions({
        name = 'EditMode',
        sub = 'advanced',
        options = advancedOptions,
        default = function()
            setDefaultSubValues('advanced')
        end,
        shouldDisplayAsap = true
    })
end

function Module:RefreshOptionScreens()
    -- print('Module:RefreshOptionScreens()')

    local configFrame = DF.ConfigModule.ConfigFrame
    local cat = 'Misc'
    -- configFrame:RefreshCatSub(cat, 'Darkmode')
end

function Module:ApplySettings(sub, key)
    Helper:Benchmark(string.format('ApplySettings(%s,%s)', tostring(sub), tostring(key)), function()
        Module:ApplySettingsInternal(sub, key)
    end, 0, self)
end

-- Blizzard's Edit Mode manages the same frames this one does, and its Save
-- writes its whole layout over ours - so people who wander into it come back
-- with a broken UI and no idea what they did. Blizzard has a supported way to
-- say "not now": CanEnterEditMode() is false while FramesBlockingEditMode is
-- non-empty (EditModeManager.lua:1638), and BlockEnteringEditMode is how their
-- own pet battle and override action bar code says it.
--
-- Going through that gate rather than hiding buttons ourselves means every
-- entry point disables itself - the Escape menu never adds its button, the
-- unit-frame right-click entry hides, the raid manager button greys, the micro
-- menu stops offering its helptip - and we touch none of them.
--
-- Our own layout applications are unaffected: LibEditModeOverride:ApplyChanges
-- reaches the frame through ShowUIPanel, which never consults the gate.
local blockerFrame

function Module:SetBlizzEditmodeBlocked(blocked)
    if not (EditModeManagerFrame and EditModeManagerFrame.BlockEnteringEditMode and
        EditModeManagerFrame.UnblockEnteringEditMode) then
        return false
    end

    blockerFrame = blockerFrame or CreateFrame('Frame', 'DragonflightUIEditModeBlocker')

    if blocked then
        EditModeManagerFrame:BlockEnteringEditMode(blockerFrame)
    else
        EditModeManagerFrame:UnblockEnteringEditMode(blockerFrame)
    end

    return true
end

function Module:IsBlizzEditmodeBlocked()
    return Module.db and Module.db.profile.general.blockBlizzardEditMode and true or false
end

function Module:ApplySettingsInternal(sub, key)
    local db = Module.db.profile
    local state = db.general

    local f = Module.EditModeFrame

    if Module.IsEditMode then
        f.Grid:SetShown(state.showGrid)
        f.Grid:SetGridSpacing(state.gridSize)
    else
        f.Grid:SetShown(false)
    end

    -- Driven from here rather than from its own lifecycle so that it follows
    -- the setting, survives a profile switch, and re-asserts itself if
    -- EditModeManagerFrame was not there the first time we asked.
    Module:SetBlizzEditmodeBlocked(state.blockBlizzardEditMode)
end

local frame = CreateFrame('FRAME')

function frame:OnEvent(event, arg1, arg2, arg3)
    -- print('event', event, InCombatLockdown())
    if event == 'PLAYER_REGEN_DISABLED' then
        Module:CombatHandler(true)
    elseif event == 'PLAYER_REGEN_ENABLED' then
        Module:CombatHandler(false)
    end
end
frame:SetScript('OnEvent', frame.OnEvent)
frame:RegisterEvent('PLAYER_REGEN_DISABLED')
frame:RegisterEvent('PLAYER_REGEN_ENABLED')

function Module:CreateGrid()
    DF:Debug(self, 'CreateGrid()')
    local editModeFrame = CreateFrame('Frame', 'DragonflightUIEditModeFrame', UIParent,
                                      'DragonflightUIEditModeFrameTemplate');
    editModeFrame:SetupGrid();
    editModeFrame:SetupMouseOverChecker();
    if DF.Era or DF.Cata then editModeFrame:SetupLayoutDropdown(); end
    editModeFrame:Hide()
    -- editModeFrame.Grid:Hide()
    Module.IsEditMode = false;
    Module.EditModeFrame = editModeFrame;
    Module.SelectionFrames = {}
end

function Module:SlashCommand()
    Module:SetEditMode(not Module.IsEditMode);
end

function Module:SetupMainmenuButton()
    local configModule = DF:GetModule('Config')

    local btn = configModule.EditModeButton

    btn:SetScript('OnClick', function()
        -- 
        DF:Debug(self, 'editmode')
        Module:SetEditMode(not Module.IsEditMode)
    end)
end

-- WasEditMode is a request, not a memory: "the player wants edit mode open and
-- the fight is in the way". Combat ending honours it; closing edit mode - by
-- any route a player can take - withdraws it.
function Module:CombatHandler(preCombat)
    if preCombat then
        local wasOpen = self.IsEditMode

        if wasOpen then
            self:Print('Combat started while in edit mode - deactivating until combat is over.')
            self:SetEditMode(false)
        end

        -- after the close, never before: SetEditMode(false) withdraws the
        -- request, and this one is the addon's own doing rather than the
        -- player's, so it re-arms behind it
        self.WasEditMode = wasOpen
    else
        if self.WasEditMode then
            self:Print('Combat ended - restoring edit mode.')
            self:SetEditMode(true)
            self.WasEditMode = false;
        end
    end
end

function Module:SetEditMode(isEditMode)
    DF:Debug(self, 'SetEditMode', isEditMode)

    -- Moving frames is protected work: in combat the drags are refused by the
    -- client without a word, so the mode would look open and do nothing.
    if isEditMode and Helper:IsCombatLocked() then
        -- The button is a toggle, and it has to stay one in combat: IsEditMode
        -- never goes true here, so without this a second press just re-queues
        -- and the player has no way to take the request back.
        if Module.WasEditMode then
            Module.WasEditMode = false
            Module:Print('Edit mode no longer queued - it will stay closed when combat ends.')
        else
            Module.WasEditMode = true
            Module:Print('Edit mode is not available in combat - it will open when combat ends.')
        end
        return
    end

    Module.IsEditMode = isEditMode;

    -- Closing edit mode answers the question the queue is waiting on, so it
    -- withdraws any pending restore. Otherwise a fight that interrupted edit
    -- mode - or a single press of the button during one - reopens it after
    -- combat no matter what the player did in between.
    if not isEditMode then Module.WasEditMode = false end
    Module.EditModeFrame:SetShown(isEditMode)

    Module:ApplySettings()

    if isEditMode then
        if not InCombatLockdown() then
            HideUIPanel(GameMenuFrame)
            HideUIPanel(SettingsPanel)

            -- Blizzard's own Edit Mode manages several of the same frames -
            -- the player and target frames, the chat window, the minimap, the
            -- action bars. Two overlays on one frame fight over the drag, and
            -- Blizzard's Save writes its whole layout over ours, so only one
            -- of the two may be open.
            if EditModeManagerFrame and EditModeManagerFrame:IsShown() then
                Module:Print("Closing Blizzard's Edit Mode - only one edit mode can be open at a time.")
                HideUIPanel(EditModeManagerFrame)
            end
        end
    end

    -- Undo records only while the mode is open, and its history ends with it.
    if addonTable.EditmodeUndo then addonTable.EditmodeUndo:SetActive(isEditMode) end

    self.SelectedFrame = nil;
    self:TriggerEvent(self.Event.OnEditMode, isEditMode)
end

-- Re-evaluates which frames edit mode may show, and nothing else.
--
-- Toggling one frame's "show in edit mode" flag used to call
-- SetEditMode(IsEditMode), which re-broadcast the whole edit-mode state: every
-- module re-applied its settings, every frame that re-anchors did so again, and
-- a full Blizzard layout application got scheduled off the back of it. Ticking
-- a checkbox moved the chat window and hid the pet frame. It is a checkbox: it
-- may touch the overlays and nothing more.
function Module:RefreshSelectionVisibility()
    for _, selection in ipairs(self.SelectionFrames or {}) do
        if selection.RefreshEditModeState then
            local ok, err = pcall(selection.RefreshEditModeState, selection, self.IsEditMode)
            if not ok then geterrorhandler()('DFUI Editmode refresh: ' .. tostring(err)) end
        end
    end
end

function Module:AddEditModeToFrame(frameRef)
    if not frameRef then return end
    local f = CreateFrame('Frame', frameRef:GetName() .. '_DFEditModeSelection', frameRef,
                          'DFEditModeSystemSelectionTemplate')

    return f;
end

function Module:SelectFrame(frameRef)
    if frameRef and self.SelectedFrame == frameRef then
        -- already selected
    else
        DF:Debug(self, 'Module:SelectFrame(frameRef)', frameRef and frameRef:GetName())
        self.SelectedFrame = frameRef
        self:TriggerEvent(self.Event.OnSelection, frameRef)
    end
end

function Module:InitEditmodeOverride()
    -- print('InitEditmodeOverride')

    local LibEditModeOverride = LibStub("LibEditModeOverride-1.0");
    LibEditModeOverride:LoadLayouts();

    addonTable.LibEditModeOverride = LibEditModeOverride;

    local DFLayoutName = 'DragonflightUI_Layout'
    if not LibEditModeOverride:DoesLayoutExist(DFLayoutName) then
        --
        LibEditModeOverride:AddLayout(Enum.EditModeLayoutType.Character, DFLayoutName)
    end

    -- force edit profile - TODO?
    LibEditModeOverride:SetActiveLayout(DFLayoutName)

    -- if not LibEditModeOverride:CanEditActiveLayout() then
    --     --
    --     LibEditModeOverride:SetActiveLayout(DFLayoutName)
    -- end
    --
    -- Deliberately NOT ApplyChanges() here. See BlizzEditmodeApplyAllowed
    -- below: applying the layout from our own code during login is what
    -- tainted the party frames for the whole session. Saving is enough -
    -- Blizzard applies the layout itself at PLAYER_ENTERING_WORLD, securely,
    -- and picks this up.
    LibEditModeOverride:SaveOnly()

    -- ApplyChanges() show/hides EditModeManagerFrame, which is a FULL
    -- Blizzard layout application: it re-anchors every managed system,
    -- fires EditMode enter/exit hooks and resets frames whose positions
    -- DFUI owns but the layout does not know about. Calling it once per
    -- re-anchored frame - as this did - meant a burst of full layout
    -- applications during setup, which is where "frames move after a
    -- loading screen", the vanishing LFG eye, and the MicroMenuContainer
    -- anchor-family errors come from. Save every change immediately, and
    -- collapse the applications into one debounced pass.
    local applyScheduled = false
    local combatGate

    -- A layout application resets every frame whose position DFUI owns but the
    -- Blizzard layout has no record of - player and target above all. Without
    -- this the frames sit correctly for a moment after login and then jump to
    -- the layout's spots.
    --
    -- Chat belongs on this list for the same reason: ChatFrame1 is a Blizzard
    -- edit-mode system on 1.15.9+, so an application re-anchors and re-sizes it
    -- from the layout. That is why toggling a frame's edit-mode visibility -
    -- which broadcasts OnEditMode, which makes a module re-anchor, which
    -- schedules an application - dragged the chat window off its configured
    -- spot.
    --
    -- This runs after ANY application, not only ours. Opening Blizzard's own
    -- Edit Mode shows EditModeManagerFrame, and showing that frame IS a full
    -- application - the very property LibEditModeOverride:ApplyChanges() relies
    -- on. So the player opening it displaced the unit frames exactly as one of
    -- our own applications would, and nothing put them back until the next
    -- PLAYER_REGEN_ENABLED, where Unitframe's own re-apply happens to catch it.
    -- That is the "opening edit mode moves my frames, leaving combat fixes
    -- them" report.
    local function ReapplyOwnedPositions()
        -- Positioning these is protected work; in combat it is refused
        -- silently. Unitframe's own regen re-apply is the safety net.
        if Helper:IsCombatLocked() then return end

        for _, name in ipairs(addonTable.BlizzEditmodeReapply) do
            local m = DF:GetModule(name, true)
            if m and m.GetWasEnabled and m:GetWasEnabled() then
                local ok, err = pcall(function() m:ApplySettings() end)
                if not ok then geterrorhandler()('DFUI Editmode reapply ' .. name .. ': ' .. tostring(err)) end
            end
        end
    end

    local function applyNow()
        applyScheduled = false
        if not (LibEditModeOverride and LibEditModeOverride.ApplyChanges) then return end
        if not (LibEditModeOverride:GetActiveLayout() == DFLayoutName) then return end

        if Helper:IsCombatLocked() then
            -- Protected work is blocked in combat; retry once it drops.
            if not combatGate then
                combatGate = CreateFrame('Frame')
                combatGate:SetScript('OnEvent', function(g)
                    g:UnregisterAllEvents()
                    applyNow()
                end)
            end
            combatGate:RegisterEvent('PLAYER_REGEN_ENABLED')
            return
        end

        -- ApplyChanges works by showing and immediately hiding
        -- EditModeManagerFrame. If the player has Blizzard's Edit Mode open
        -- right now, that slams their session shut mid-edit and discards what
        -- they were doing. Wait for them to leave it.
        if EditModeManagerFrame and EditModeManagerFrame:IsShown() then
            addonTable.BlizzApplyPending = true
            return
        end

        -- ApplyChanges saves before it applies, so it writes the cached layout
        -- table like any other write. This one matters most: it is debounced,
        -- and BlizzApplyPending above deliberately holds it until the player
        -- leaves Blizzard's Edit Mode - which means it ran immediately after
        -- they had finished changing something, with a copy that predated the
        -- change.
        addonTable:RefreshBlizzEditmodeLayouts()

        -- Our own application fires Blizzard's EditMode.Enter and .Exit as a
        -- side effect of that show/hide. Flag it, so the handlers that react to
        -- the player opening the native edit mode do not react to us.
        addonTable.ApplyingBlizzLayout = true
        LibEditModeOverride:ApplyChanges()
        addonTable.ApplyingBlizzLayout = false

        ReapplyOwnedPositions()
    end

    -- Applications are refused until login is over. This is the party-frame
    -- taint fix, and it is worth spelling out.
    --
    -- ApplyChanges works by showing and hiding EditModeManagerFrame, and that is
    -- a FULL layout application: Blizzard re-sets-up every Edit Mode system
    -- inside our call. The field assignments it makes on the way through belong
    -- to whoever is on the stack, so CompactPartyFrameMemberN.optionTable and
    -- .isLootObject came out tainted by DragonflightUI and stayed that way for
    -- the session. Every later CompactUnitFrame_UpdateAll then tainted itself on
    -- the optionTable read and had its SetSize/SetAttribute/Show refused - party
    -- members that never appear, a party that collapses to one, "Interface
    -- action failed because of an AddOn". Proven with /df log party: those two
    -- fields insecure on all five members, with PartyFrame, CompactPartyFrame
    -- and every EditModeManagerFrame field clean.
    --
    -- OverrideBlizzEditmode is called at enable from about ten places, so this
    -- fired on every single login. It does not need to. SaveOnly writes the
    -- anchors, and Blizzard applies the layout itself at PLAYER_ENTERING_WORLD -
    -- from its own execution, so the same setup happens without our taint on it.
    --
    -- After that first application the gate opens, because an application from
    -- then on is the player having just changed something: rare, deliberate, and
    -- gone at the next reload.
    -- Nothing is replayed when the gate opens. Everything that asked for an
    -- application during login had already saved its anchors, and Blizzard's own
    -- PEW application is what puts them into effect - running ours afterwards
    -- would re-taint the frames for exactly no gain, which is the whole bug.
    local function OpenApplyGate()
        addonTable.BlizzEditmodeApplyAllowed = true
    end

    if not addonTable.BlizzEditmodeApplyGateInstalled then
        addonTable.BlizzEditmodeApplyGateInstalled = true

        local gate = CreateFrame('Frame')
        gate:RegisterEvent('PLAYER_ENTERING_WORLD')
        gate:SetScript('OnEvent', function(g)
            g:UnregisterAllEvents()
            -- After Blizzard's own application for this PEW, not before it.
            C_Timer.After(2, OpenApplyGate)
        end)
    end

    function addonTable:ScheduleBlizzEditmodeApply()
        if not addonTable.BlizzEditmodeApplyAllowed then
            if DF and DF.Log then
                DF:Log('editmode', 'layout apply skipped during login - saved only, Blizzard applies it at PEW')
            end
            return
        end

        if applyScheduled then return end
        applyScheduled = true
        C_Timer.After(0.5, applyNow)
    end

    -- One edit mode at a time, and hands off theirs. Registered once: this
    -- function runs per flavour entry point and must stay re-entrant.
    if not addonTable.BlizzEditmodeHooksInstalled then
        addonTable.BlizzEditmodeHooksInstalled = true

        EventRegistry:RegisterCallback('EditMode.Enter', function()
            if addonTable.ApplyingBlizzLayout then return end

            -- CanEnterEditMode gates the ways a player gets in, but not
            -- ShowUIPanel itself - Blizzard_DamageMeter calls that directly,
            -- and so can any addon. Close it again rather than let it apply
            -- its layout over ours. Hiding a panel is protected work, so in
            -- combat we can only let it stand and repair afterwards.
            if Module:IsBlizzEditmodeBlocked() and not Helper:IsCombatLocked() then
                Module:Print("Blizzard's Edit Mode is turned off by DragonflightUI - use /editmode instead. " ..
                                 'The setting is under EditMode options.')
                HideUIPanel(EditModeManagerFrame)
                C_Timer.After(0, ReapplyOwnedPositions)
                return
            end

            if Module.IsEditMode then
                Module:Print("Blizzard's Edit Mode opened - closing Dragonflight edit mode so the two do not fight"
                                 .. ' over the same frames.')
                Module:SetEditMode(false)
            end

            -- Opening it applied the layout and displaced our frames. Next
            -- frame, so the application has finished before we answer it.
            C_Timer.After(0, ReapplyOwnedPositions)
        end)

        EventRegistry:RegisterCallback('EditMode.Exit', function()
            if addonTable.ApplyingBlizzLayout then return end

            -- Leaving applies the layout again, Save or no Save.
            C_Timer.After(0, ReapplyOwnedPositions)

            -- a layout application we deferred while their session was open
            if addonTable.BlizzApplyPending then
                addonTable.BlizzApplyPending = nil
                addonTable:ScheduleBlizzEditmodeApply()
            end
        end)
    end

    -- LibEditModeOverride reads every layout once, in LoadLayouts, and keeps
    -- that table; SaveOnly writes the whole of it back with
    -- C_EditMode.SaveLayouts. So the copy we save is the one we read at login,
    -- and anything the player changed in Blizzard's Edit Mode since then is not
    -- in it - saving quietly replaces their change with our stale value.
    --
    -- That is what "Use Raid-Style Party Frames turns itself back off" was.
    -- The setting is not a CVar; it lives in the layout
    -- (Enum.EditModeUnitFrameSetting.UseRaidStylePartyFrames on the Party unit
    -- frame system), so ticking the box edits the same table we are holding a
    -- stale copy of. The next re-anchor - entering a dungeon, a module
    -- re-applying - wrote our copy over it, and the frames reverted at the next
    -- layout application, which is why it looked like a reload did it.
    --
    -- Re-read immediately before touching the table. Every writer here saves
    -- straight after mutating, so there is never an unsaved change of ours to
    -- lose by refreshing.
    function addonTable:RefreshBlizzEditmodeLayouts()
        if LibEditModeOverride and LibEditModeOverride.LoadLayouts and LibEditModeOverride:IsReady() then
            LibEditModeOverride:LoadLayouts()
        end
    end

    function addonTable:OverrideBlizzEditmode(f, ...)
        addonTable:RefreshBlizzEditmodeLayouts()
        if not (LibEditModeOverride:GetActiveLayout() == DFLayoutName) then
            print('Wrong EditMode layout detected - please use ' .. DFLayoutName .. ' and /reload .')
            return;
        end
        LibEditModeOverride:ReanchorFrame(f, ...)
        LibEditModeOverride:SaveOnly()
        addonTable:ScheduleBlizzEditmodeApply()
    end

    function addonTable:HookBlizzEditmodeAndFunc(fun, both)
        local lastUpdate = GetTime()

        EventRegistry:RegisterCallback("EditMode.Exit", function()
            -- print('EditMode.Exit', GetTime())
            local newUpdate = GetTime()

            if newUpdate > lastUpdate then
                lastUpdate = newUpdate;
                print('~> update')
                fun()
            end
        end)
        if both then
            EventRegistry:RegisterCallback("EditMode.Enter", function()
                -- print('EditMode.Enter')
                local newUpdate = GetTime()

                if newUpdate > lastUpdate then
                    lastUpdate = newUpdate;
                    print('~> update')
                    fun()
                end
            end)
        end
        fun()
    end

    function addonTable:GetBlizzEditmodeFrameSetting(f, setting)
        return LibEditModeOverride:GetFrameSetting(f, setting)
    end

    function addonTable:GetBlizzEditmodeFrameSettingBool(f, setting)
        -- Read the layout as it is now, not as it was at login. Without this a
        -- settings page shows our stale copy, so a checkbox can disagree with
        -- the thing it controls after the player has been in Blizzard's Edit
        -- Mode. Same reason the writers refresh.
        addonTable:RefreshBlizzEditmodeLayouts()

        local value = LibEditModeOverride:GetFrameSetting(f, setting)
        if value == 1 then
            return true;
        else
            return false;
        end
    end

    function addonTable:SetBlizzEditmodeFrameSetting(f, setting, value, saveOnly)
        addonTable:RefreshBlizzEditmodeLayouts()
        LibEditModeOverride:SetFrameSetting(f, setting, value)
        LibEditModeOverride:SaveOnly()

        if not saveOnly then addonTable:ScheduleBlizzEditmodeApply() end
    end
end

function Module:GetEditmodeSettingValue(setting)
    local accountSettings = C_EditMode.GetAccountSettings()

    for k, v in ipairs(accountSettings) do if v.setting == setting then return v.value; end end

    return -1;
end

function Module:ShowEditmodeWarning(setting, value, str)
    if self:GetEditmodeSettingValue(setting) == value then return; end

    local valueStr = tostring(value);

    if value == 0 then
        valueStr = 'unchecked'
    elseif value == 1 then
        valueStr = 'checked'
    end

    local outputStr = string.format(
                          "Conflicting blizzard editmode setting found! Please enter the blizzard editmode and change setting |cff8080ff%s|r to |cff8080ff%s|r, or you risk game breaking issues.",
                          str, valueStr);

    C_Timer.After(5, function()
        DF:Print(outputStr)
    end)
end

function Module:Era()
    -- 1.15.9+: Era carries Blizzard Edit Mode. Every modern-UI code path
    -- (ForceMoveBlizzEditModeGhosts, BagsBar/micromenu re-anchors, ...) calls
    -- addonTable:OverrideBlizzEditmode, which only exists after this init -
    -- without it the Actionbar module dies at enable time and nothing gets
    -- styled. The init applies an EditMode layout (protected panel work), so
    -- it must wait for combat to drop on a mid-combat load; Editmode enables
    -- before Actionbar/Unitframe, so this regen gate fires before theirs and
    -- the override exists by the time the deferred chains run.
    if DF.API.Version.IsModern then
        addonTable.Helper:RunOutOfCombat('edit mode', function()
            self:InitEditmodeOverride()
        end)
    end
end

function Module:TBC()
    self:InitEditmodeOverride()
end

function Module:Wrath()
end

function Module:Cata()
end

function Module:Mists()
    self:InitEditmodeOverride()
end
