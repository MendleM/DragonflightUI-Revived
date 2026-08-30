local addonName, addonTable = ...;
local DF = LibStub('AceAddon-3.0'):GetAddon('DragonflightUI')
local L = LibStub("AceLocale-3.0"):GetLocale("DragonflightUI")

local Helper = {};
addonTable.Helper = Helper;

-- era-1159 diagnostics: phase timings, so a slow spot can be found when "script
-- ran too long" hides the real sink - that error surfaces wherever the shared
-- load-time budget happens to expire, not where the time went.
--
-- In memory only. This used to be a SavedVariable so it could be read off disk
-- after logout, which meant every player wrote a diagnostic file every session
-- for the benefit of nobody but whoever was chasing era-1159 load times. Read it
-- in the session that produced it: /dump DragonflightUIPerfLog.
local perfLog = { boot = true }
DragonflightUIPerfLog = perfLog

-- make globally available
_G['DragonflightUI_Helper'] = Helper;

function addonTable:OverrideBlizzEditmode(f, ...)
    if f and not Helper:IsCombatLocked() then
        local ok, err = pcall(function(...)
            f:ClearAllPoints()
            f:SetPoint(...)
        end, ...)
        if not ok then
            geterrorhandler()('DFUI direct anchor ' .. tostring(f and f.GetName and f:GetName()) .. ': ' .. tostring(err))
        end
    end
end

-- EditModeManagerFrame.layoutInfo is Blizzard's, and nothing here may write it.
--
-- There used to be a FixBlizzEditModeManagerLayouts() at this spot that
-- "repaired" layoutInfo when activeLayout pointed past the end of layouts. It
-- was treating damage this file caused, and it caused more of its own:
--
--   1. Blizzard already builds that list as presets .. savedLayouts, at the top
--      of UpdateLayoutInfo. Merging GetCopyOfPresetLayouts() in a second time
--      duplicated every preset and shifted every index, which is what made
--      activeLayout run past the end in the first place.
--   2. Assigning info.layouts / info.layouts[i] from here is an addon write
--      into a Blizzard table. Blizzard walks that table under
--      secureexecuterange (InitSystemAnchors, UpdateSystems) and ends up
--      calling SetPoint on the action bars and unit frames with it, so the
--      taint lands on protected frames and their actions get blocked.
--
-- The condition it checked cannot occur once the argument-less
-- UpdateLayoutInfo() call below is gone: that call was what nil'd layoutInfo.
-- Read layouts through C_EditMode.GetLayouts(), which hands out a copy, mutate
-- that, and give it to C_EditMode.SaveLayouts(). Never touch the live table.

-- One-time repair of leftover DragonflightUI anchors in Blizzard's Edit Mode layout.
--
-- An earlier version of this addon anchored Blizzard's Edit Mode systems to its
-- own holder frames and let that be written into Blizzard's layout. Those
-- layouts live on Blizzard's server, so the references outlived every reinstall
-- and every WTF wipe: with DragonflightUI disabled, the client restored a layout
-- anchoring PlayerFrame to DragonflightUIPlayerFrame - a frame that no longer
-- exists - and the UI came up broken.
--
-- Repointing those anchors at UIParent, which is what the first attempt at this
-- did, is not a repair. The offsets stored beside them were measured against a
-- DragonflightUI frame, so keeping point/relativePoint/offsetX/offsetY and only
-- swapping the reference leaves the frame at a position that means nothing - and
-- then saves it back to the server as though it were deliberate.
--
-- Blizzard's own answer to "this system has no custom position" is
-- EditModeSystemMixin:ResetToDefaultPosition:
--
--     self.systemInfo.anchorInfo = EditModePresetLayoutManager:GetDefaultSystemAnchorInfo(...)
--     self.systemInfo.anchorInfo2 = nil
--     self.systemInfo.isInDefaultPosition = true
--
-- isInDefaultPosition is the flag the rest of the system actually reads -
-- initSystemAnchor skips managed frames that report it, and the action bar
-- placement only positions bars that report it - so that is what this sets, on
-- the copy C_EditMode.GetLayouts() hands out.
local ANCHOR_MIGRATION_VERSION = 1
local migrationRunning = false

local function IsLegacyDFUIAnchor(anchorInfo)
    if not (anchorInfo and anchorInfo.relativeTo) then return false end

    -- Narrow on purpose. The frames that can legitimately turn up here are the
    -- holders this addon anchors Blizzard systems to, and every one of them is
    -- named DragonflightUI* (PlayerFrame, TargetFrame, PartyMoveFrame, the edit
    -- mode frames). Also matching '^DF' would catch DFTrainerInset*, which is
    -- never an anchor target, at the price of resetting positions the player
    -- chose themselves.
    return tostring(anchorInfo.relativeTo):find('^DragonflightUI') ~= nil
end

local function ResetSystemToDefaultPosition(sys)
    if not (sys and sys.system) then return false end
    if not (EditModePresetLayoutManager and EditModePresetLayoutManager.GetDefaultSystemAnchorInfo) then
        return false
    end

    local ok, defaultAnchor = pcall(EditModePresetLayoutManager.GetDefaultSystemAnchorInfo,
                                    EditModePresetLayoutManager, sys.system, sys.systemIndex)

    -- A half-finished reset is worse than none. ApplySystemAnchor indexes
    -- anchorInfo.point without checking, and C_EditMode.SaveLayouts validates
    -- the structure and throws on a malformed one - which is exactly how people
    -- end up with a layout that is corrupt on the server for good. If Blizzard
    -- will not hand over the default for this system, leave the system alone.
    if not (ok and type(defaultAnchor) == 'table' and defaultAnchor.point) then return false end

    sys.anchorInfo = defaultAnchor
    sys.anchorInfo2 = nil
    sys.isInDefaultPosition = true
    return true
end

-- Returns true once this character has nothing left to migrate.
function addonTable:SanitizeLegacyEditModeAnchors()
    if migrationRunning then return false end
    if not (C_EditMode and C_EditMode.GetLayouts and C_EditMode.SaveLayouts) then return false end

    -- Per character, not global. GetLayouts() only ever returns the layouts that
    -- apply to the character you are on, so a character-scoped layout carrying a
    -- stale anchor is invisible until that character logs in. A global flag would
    -- mark the job done after the first one and never look at the rest.
    local db = DF.db and DF.db.char
    if not db then return false end
    if (db.editModeAnchorMigration or 0) >= ANCHOR_MIGRATION_VERSION then return true end

    migrationRunning = true

    local ok, layoutInfo = pcall(C_EditMode.GetLayouts)
    if not (ok and layoutInfo and layoutInfo.layouts) then
        migrationRunning = false
        return false
    end

    local repaired, skipped = 0, 0
    for _, layout in ipairs(layoutInfo.layouts) do
        if layout.systems then
            for _, sys in ipairs(layout.systems) do
                if IsLegacyDFUIAnchor(sys.anchorInfo) or IsLegacyDFUIAnchor(sys.anchorInfo2) then
                    if ResetSystemToDefaultPosition(sys) then
                        repaired = repaired + 1
                    else
                        skipped = skipped + 1
                    end
                end
            end
        end
    end

    if repaired > 0 then
        pcall(C_EditMode.SaveLayouts, layoutInfo)
        DF:Print(string.format('reset %d frame(s) in Blizzard\'s Edit Mode layout that were still anchored to ' ..
                                   'DragonflightUI frames from an older version. They are back at their default ' ..
                                   'position and this will not run again.', repaired))
    end

    -- A clean scan counts as done: it is the same answer the next login would
    -- get, and re-scanning only risks another write to a server-side layout.
    -- Anything we could not reset safely leaves the flag unset, so a later
    -- client - or a later login - gets another attempt. That costs a scan and
    -- never a write, because repaired stays 0.
    if skipped == 0 then
        db.editModeAnchorMigration = ANCHOR_MIGRATION_VERSION
    else
        DF:Debug(DF, string.format('editmode anchor migration: %d system(s) had no default anchor, deferred', skipped))
    end

    migrationRunning = false
    return skipped == 0
end

-- EDIT_MODE_LAYOUTS_UPDATED, not PLAYER_LOGIN.
--
-- The first attempt ran this out of Editmode's OnEnable, where C_EditMode need
-- not exist yet: Blizzard_EditMode is load-on-demand and no TOC in this addon
-- lists it under OptionalDeps, so the call returned silently and the migration
-- simply never happened that session. This event is the moment the layout data
-- is known to be present - it is the one Blizzard's own OnEvent uses to fill
-- layoutInfo in the first place.
local anchorMigrationWatcher = CreateFrame('Frame')
anchorMigrationWatcher:SetScript('OnEvent', function(self)
    -- SaveLayouts drags the whole layout-apply chain behind it, and that ends in
    -- SetPoint on the action bars and unit frames, which the client refuses in
    -- combat. RunOutOfCombat queues by label, so a fight only delays it.
    Helper:RunOutOfCombat('editmode anchor migration', function()
        if addonTable:SanitizeLegacyEditModeAnchors() then self:UnregisterAllEvents() end
    end)
end)
-- Not every flavour has this event, and RegisterEvent throws on an unknown one.
pcall(anchorMigrationWatcher.RegisterEvent, anchorMigrationWatcher, 'EDIT_MODE_LAYOUTS_UPDATED')

function addonTable:SyncRaidStylePartyFrameToBlizzard(enabled)
    local val = (enabled and 1) or 0

    if not (Enum and Enum.EditModeSystem and Enum.EditModeUnitFrameSetting) then
        return
    end

    local targetSystem = Enum.EditModeSystem.UnitFrame
    local targetSystemIndex = Enum.EditModeUnitFrameSystemIndices and Enum.EditModeUnitFrameSystemIndices.Party
    local targetSetting = Enum.EditModeUnitFrameSetting.UseRaidStylePartyFrames

    if not targetSystem or not targetSetting then return end

    if PartyFrame then
        PartyFrame.system = PartyFrame.system or targetSystem
        PartyFrame.systemIndex = PartyFrame.systemIndex or targetSystemIndex
    end

    local function EnsureSettingInLayout(layout)
        if not layout then return end
        layout.systems = layout.systems or {}
        local foundSys = false
        for _, sys in ipairs(layout.systems) do
            if sys.system == targetSystem and (not targetSystemIndex or sys.systemIndex == targetSystemIndex) then
                foundSys = true
                sys.settings = sys.settings or {}
                local foundSetting = false
                for _, s in ipairs(sys.settings) do
                    if s.setting == targetSetting then
                        s.value = val
                        foundSetting = true
                    end
                end
                if not foundSetting then
                    table.insert(sys.settings, {setting = targetSetting, value = val})
                end
            end
        end
        if not foundSys then
            table.insert(layout.systems, {
                system = targetSystem,
                systemIndex = targetSystemIndex or 3,
                settings = {
                    {setting = targetSetting, value = val}
                },
                isInDefaultPosition = true,
            })
        end
    end

    -- The live EditModeManagerFrame.layoutInfo.layouts is deliberately not
    -- written here. It holds Blizzard's preset layouts alongside the saved ones,
    -- so writing settings into it both corrupts the presets and taints the table
    -- Blizzard hands to SetPoint on protected frames. The GetLayouts() copy
    -- below carries the same change into the saved data, and the
    -- EDIT_MODE_LAYOUTS_UPDATED that SaveLayouts triggers is what brings the
    -- live table back in sync - on Blizzard's own execution, not ours.

    -- Push the value into Blizzard's live system frame, which is what actually
    -- switches the party frames.
    --
    -- This is OnSystemSettingChange, and the name matters. The call here used to
    -- be OnEditModeSystemSettingChange, which does not exist on
    -- EditModeManagerFrame - so the guard was nil, the block never ran, and the
    -- layout write below was the only thing happening. That write alone does not
    -- switch anything: Blizzard reads this setting through
    --
    --   UseRaidStylePartyFrames() -> GetSettingValueBool(...)
    --     -> GetRegisteredSystemFrame(...) -> systemFrame:GetSettingValueBool(...)
    --
    -- so the value has to reach the registered system frame's setting map, and
    -- the layout only feeds that on the next EDIT_MODE_LAYOUTS_UPDATED. Blizzard's
    -- own setter does it now, and its UpdateSystemSetting hop runs
    -- UpdateSystemSettingUseRaidStylePartyFrames -> UpdateRaidAndPartyFrames,
    -- which is the switch itself.
    --
    -- Out of combat only: that chain ends in Show/Hide and SetPoint on the
    -- protected party frames, which the client refuses mid-fight.
    if EditModeManagerFrame and EditModeManagerFrame.OnSystemSettingChange and PartyFrame then
        Helper:RunOutOfCombat('party raid style setting', function()
            local ok, err = pcall(EditModeManagerFrame.OnSystemSettingChange, EditModeManagerFrame, PartyFrame,
                                  targetSetting, val)
            if not ok then geterrorhandler()('DFUI OnSystemSettingChange: ' .. tostring(err)) end
        end)
    end

    if C_EditMode and C_EditMode.GetLayouts and C_EditMode.SaveLayouts then
        local ok, layoutInfo = pcall(C_EditMode.GetLayouts)
        if ok and layoutInfo and layoutInfo.layouts then
            for _, layout in ipairs(layoutInfo.layouts) do
                EnsureSettingInLayout(layout)
            end
            pcall(C_EditMode.SaveLayouts, layoutInfo)
        end
    end
end

-- SetBlizzEditmodeFrameSetting / GetBlizzEditmodeFrameSettingBool used to live
-- here. Both are gone, and with them the last general-purpose route from this
-- addon into Blizzard's Edit Mode layout.
--
-- They read and wrote Blizzard's server-side layout for five settings. For four
-- of them the write bought nothing, because this addon already produces the
-- effect itself and Blizzard's applier either does the same thing or has been
-- stubbed out here:
--
--   AlwaysShowButtons  Blizzard applies it in UpdateShownButtons, which
--                      Actionbar.Controller replaces with an empty function.
--                      The effect comes from our showgrid attribute.
--   FrameSize (pet)    Blizzard applies it as PetFrame:SetScale(); Pet.mixin
--                      sets the scale directly one line earlier.
--   BuffsOnTop         Blizzard sets self.buffsOnTop and refreshes auras;
--                      Target.mixin does exactly that from its own profile.
--   UseLargerFrame     Blizzard calls FocusFrame:SetSmallSize(not v);
--                      Focus.mixin now makes that call itself.
--
-- RotateMinimap was the one where Blizzard would overwrite us, because it pushes
-- the layout value into the rotateMinimap CVar on every layout application.
-- Minimap.mixin keeps the value in our profile and re-asserts it on
-- EDIT_MODE_LAYOUTS_UPDATED instead of handing it to the layout.
--
-- The one write that remains is SyncRaidStylePartyFrameToBlizzard above, and it
-- is not optional: which party system is live is decided inside Blizzard's code,
-- every path through it asks EditModeManagerFrame:UseRaidStylePartyFrames(), and
-- that resolves out of the layout. A settings value there is fine - it stays
-- meaningful with this addon disabled. An anchorInfo pointing at one of our
-- frames is not, and is what SanitizeLegacyEditModeAnchors cleans up.
--
-- Standing rule, learned the expensive way: never call
-- EditModeManagerFrame:UpdateLayoutInfo() from addon code.
--
--   function EditModeManagerFrameMixin:UpdateLayoutInfo(layoutInfo, reconcileLayouts)
--       self.layoutApplyInProgress = true;
--       self.layoutInfo = layoutInfo;          -- nil when called with no args
--       ...
--       local savedLayouts = self.layoutInfo.layouts;   -- throws here
--       ...
--       self.layoutApplyInProgress = false;             -- never reached
--
-- It is not a refresh, it is the setter behind EDIT_MODE_LAYOUTS_UPDATED, and the
-- layout table is its first argument. Called with no argument it nil'd
-- layoutInfo, threw on the next line, and left layoutApplyInProgress stuck true -
-- inside a pcall, so nothing was reported. From that point EditModeManagerFrame
-- had no layoutInfo, IsInitialized() answered false for the session, and every
-- Blizzard caller that reads the active layout died on the nil: GetDefaultAnchor
-- via PlayerFrame_ResetPosition, SetToLayoutAnchor via
-- UIParent_ManageFramePositions. That was issues #26 and #28.
--
-- SaveLayouts already makes the client fire EDIT_MODE_LAYOUTS_UPDATED, and
-- Blizzard's own OnEvent calls UpdateLayoutInfo with the real payload.

function Helper:Benchmark(label, func, level, moduleRef)
    if level == nil or type(level) ~= 'number' then level = 1; end
    -- level = level or 1;
    if level < 1 then
        local firstStr = string.format('|cffffd100-----Start Bench: |r|cff8080ff%s|r-----', label)
        -- print(firstStr)
        DF:Debug(moduleRef or DF, firstStr)
    end
    local startTime = GetTimePreciseSec()
    local results = {func()}
    local endTime = GetTimePreciseSec()
    local duration = endTime - startTime

    local levelStr = '';
    if level > 0 then levelStr = string.rep("~", level) .. '>'; end

    -- local str = string.format("|cffffd100%sBench: |r|cff8080ff%s|r took %.4f ms (%.6f seconds)", levelStr, label,
    --                           duration * 1000, duration)
    local str = string.format("|cffffd100%sBench: |r|cff8080ff%s|r took |cffffd100%.4f|r ms", levelStr, label,
                              duration * 1000)
    -- print(str)
    DF:Debug(moduleRef or DF, str)
    if #perfLog < 400 then
        perfLog[#perfLog + 1] = string.format('%.1fms %s', duration * 1000, label)
    end
    return results, duration, startTime, endTime;
end

-- Run {label, fn} steps one per frame. Each step gets a fresh watchdog
-- slice; a failing step is reported but never breaks the chain.
-- The one true combat check for load-time gates. InCombatLockdown() reads
-- FALSE during the entire load sequence of a mid-combat login or /reload
-- on 1.15.9 - lockdown only engages around PLAYER_ENTERING_WORLD - while
-- protected operations are ALREADY being blocked (proven: secure frame
-- creation failed with the API reporting no lockdown). UnitAffectingCombat
-- is the server-side combat state and is truthful during load.
function Helper:IsCombatLocked()
    return InCombatLockdown() or UnitAffectingCombat('player')
end

-- One shared gate for everything a combat /reload has to postpone.
--
-- The client refuses the protected half of this addon's setup while you are in
-- combat: SetPoint, SetScale, Show, Hide, SetParent and SetAttribute on secure
-- frames (the action bars, the unit frames, the pet and micro-menu holders),
-- RegisterStateDriver, and any Blizzard edit-mode layout application. Almost
-- none of it errors - the calls simply do nothing - which is why a /reload
-- mid-fight leaves the UI half native. There is no way around that part: it is
-- the engine's rule, and no addon can move a protected frame in combat.
--
-- What is ours to get right is the recovery. Work that cannot run yet is queued
-- here rather than each caller growing its own gate, so combat ending drains it
-- in one pass, with one message, followed by a full settings re-application:
-- the modules that DID run during combat had their protected calls refused
-- silently, and nothing else ever retries those.
local pendingOutOfCombat = {}
local pendingOrder = {}
local combatGate
local loadedInCombat = false

local function DrainOutOfCombatQueue()
    if #pendingOrder == 0 then return end

    local loadingState = addonTable.LoadingState
    if loadingState then loadingState:ShowFinishing(pendingOrder) end

    local labels = {}
    for _, label in ipairs(pendingOrder) do
        local fn = pendingOutOfCombat[label]
        pendingOutOfCombat[label] = nil
        if fn then
            table.insert(labels, label)
            local ok, err = pcall(fn)
            if not ok then geterrorhandler()('DFUI deferred setup (' .. label .. '): ' .. tostring(err)) end
        end
    end
    table.wipe(pendingOrder)

    print('|cff0070ddDragonflightUI:|r combat ended - finishing setup (' .. table.concat(labels, ', ') .. ').')

    -- The enable chains slice themselves across frames, so let them land before
    -- re-applying settings on top.
    C_Timer.After(0.1, Helper.ReapplyAfterCombat)
end

-- Everything the client refused during combat, asked for once more: every
-- module re-applies its settings off RefreshConfig, so positions, scales and
-- visibility that silently did nothing mid-fight land here.
function Helper.ReapplyAfterCombat()
    if Helper:IsCombatLocked() then
        -- straight back into combat; catch the next lull
        Helper:QueueOutOfCombat('settings re-apply', Helper.ReapplyAfterCombat)
        return
    end

    if DF and DF.RefreshConfig then
        local ok, err = pcall(DF.RefreshConfig, DF)
        if not ok then geterrorhandler()('DFUI post-combat re-apply: ' .. tostring(err)) end
    end

    if addonTable.LoadingState then addonTable.LoadingState:Complete() end
end

function Helper:QueueOutOfCombat(label, fn)
    loadedInCombat = true

    if not pendingOutOfCombat[label] then table.insert(pendingOrder, label) end
    pendingOutOfCombat[label] = fn

    if #perfLog < 400 then perfLog[#perfLog + 1] = 'deferred ' .. label .. ' to end of combat' end

    -- on screen as well as in chat: a line in the chat frame during a pull is
    -- easy to miss, and a half-built UI with no explanation reads as a broken
    -- addon
    if addonTable.LoadingState then addonTable.LoadingState:ShowWaiting(pendingOrder) end

    if not combatGate then
        combatGate = CreateFrame('Frame')
        combatGate:RegisterEvent('PLAYER_REGEN_ENABLED')
        combatGate:SetScript('OnEvent', function()
            -- PLAYER_REGEN_ENABLED fires as lockdown lifts; the next frame is
            -- safely out of it
            C_Timer.After(0, DrainOutOfCombatQueue)
        end)
    end
end

-- Did this session start (or reload) mid-combat? Anything that wants to explain
-- itself to the player can ask.
function Helper:LoadedInCombat()
    return loadedInCombat
end

-- Run now when it is safe, otherwise once combat drops.
function Helper:RunOutOfCombat(label, fn)
    if not Helper:IsCombatLocked() then
        fn()
        return
    end

    if not loadedInCombat then
        print('|cff0070ddDragonflightUI:|r in combat - the parts of the UI the game will not let an addon touch'
                  .. ' mid-fight will finish setting up the moment combat ends.')
    end

    Helper:QueueOutOfCombat(label, fn)
end

-- Would anchoring `frame` to `parent` form a cycle?
--
-- Frames can be anchored to each other through the options - the XP bar to an
-- action bar, the reputation bar to the XP bar - and the client refuses a
-- SetPoint that would close a loop ("Cannot anchor to a region dependent on
-- it"). So walk the prospective parent's own anchor chain and look for us in
-- it.
--
-- Every step is nil-guarded, which the original of this was not. A frame in the
-- chain can perfectly well have no points: it may be anchored to its parent
-- implicitly, or - the case that actually bit - its own SetPoint may have just
-- been refused, leaving it with none at all after ClearAllPoints. Walking into
-- that threw, and because this runs inside ApplySettings, the throw took out
-- the whole pass and every bar after it went unplaced. A loop check that
-- crashes is worse than no loop check.
--
-- Returns: loops (boolean), chain (string, for the message).
function Helper:AnchorChainLoops(frame, parent)
    local chain = (frame and frame.GetName and frame:GetName()) or '?'
    if not (frame and parent) then return false, chain end

    local toCheck = parent
    local depth = 0

    -- A cycle is caught by finding ourselves; the cap is for chains that close
    -- on each other without including us, which we have no business hanging on.
    while toCheck and toCheck ~= UIParent and depth < 32 do
        depth = depth + 1
        chain = chain .. ' -> ' .. ((toCheck.GetName and toCheck:GetName()) or '?')

        if toCheck == frame then return true, chain end

        local _, relativeTo = toCheck:GetPoint(1)
        toCheck = relativeTo
    end

    if toCheck == UIParent then chain = chain .. ' -> UIParent' end
    return false, chain
end

-- The frame an element should anchor to, and whether that was the one asked
-- for. Falls back to UIParent when the choice is missing or would form a loop,
-- so the element still lands somewhere visible instead of being skipped.
function Helper:ResolveAnchorParent(frame, state)
    local parent
    if DF.Settings.ValidateFrame(state.customAnchorFrame) then
        parent = _G[state.customAnchorFrame]
    else
        parent = _G[state.anchorFrame]
    end

    if not parent then return UIParent, false, (frame:GetName() or '?') .. ' -> <missing frame>' end

    local loops, chain = Helper:AnchorChainLoops(frame, parent)
    if loops then return UIParent, false, chain end

    return parent, true, chain
end

-- One complaint per frame per session. This runs on every settings pass, so
-- erroring here - as it used to - produced the same message dozens of times in
-- a log and drowned whatever else was wrong.
local anchorWarned = {}

function Helper:WarnIllegalAnchor(frame, chain)
    local key = frame:GetName() or tostring(frame)
    if anchorWarned[key] then return end
    anchorWarned[key] = true

    print('|cffFF0000DragonflightUI:|r ' .. key ..
              ' cannot be anchored there - it would form a loop, so it has been anchored to the screen instead.' ..
              ' Pick a different Anchor Frame in the options. Chain: ' .. (chain or '?'):gsub('DragonflightUI', 'DF'))
end

function Helper:RunSteps(steps, moduleRef, chainLabel)
    local index = 0
    -- Batch steps into ~100ms slices: one step per frame made the UI
    -- visibly assemble itself for ~a second after loading (40 steps = 40
    -- frames of latency for ~250ms of actual work). 100ms + one overshooting
    -- step stays well under the lowest observed LimitedLuaResources kill
    -- (~350ms), and the whole chain now finishes in 2-3 frames.
    local SLICE_BUDGET_MS = 100
    local resumeFrame
    local function runNext()
        -- Combat pause: these chains create secure-template frames and do
        -- protected setup, which FAILS under combat lockdown (and cascades:
        -- later steps index the bars earlier steps never produced). This
        -- includes the mid-combat LOGIN case, where InCombatLockdown() reads
        -- false during the load sequence and lockdown engages mid-chain -
        -- so a single gate at chain start is not enough. Park the chain and
        -- resume when combat drops.
        if Helper:IsCombatLocked() then
            if not resumeFrame then
                resumeFrame = CreateFrame('Frame')
                resumeFrame:RegisterEvent('PLAYER_REGEN_ENABLED')
                resumeFrame:SetScript('OnEvent', function()
                    C_Timer.After(0, runNext)
                end)
            end
            if #perfLog < 400 then
                perfLog[#perfLog + 1] = ('chain %s paused for combat before step %d'):format(
                    tostring(chainLabel), index + 1)
            end
            return
        end
        local sliceStart = GetTimePreciseSec()
        repeat
            index = index + 1
            local step = steps[index]
            if not step then return end
            local name = (chainLabel or 'Chain') .. ':' .. (step[1] or index)
            local startTime = GetTimePreciseSec()
            local ok, err = pcall(step[2])
            local ms = (GetTimePreciseSec() - startTime) * 1000
            if #perfLog < 400 then
                perfLog[#perfLog + 1] = string.format('%.1fms %s%s', ms, name, ok and '' or ' [ERROR]')
            end
            if not ok then geterrorhandler()(name .. ': ' .. tostring(err)) end
        until (GetTimePreciseSec() - sliceStart) * 1000 > SLICE_BUDGET_MS
        C_Timer.After(0, runNext)
    end
    -- Fully async: even the first slice runs outside the caller's slice.
    C_Timer.After(0, runNext)
end

-- local playerMaskTexture = 'Interface\\Addons\\DragonflightUI\\Textures\\uiunitframeplayerportraitmask'
local circularMaskTexture = 'Interface\\Addons\\DragonflightUI\\Textures\\tempportraitalphamask'

function Helper:AddCircleMask(f, port, maskTexture)
    if not f or not port then return end
    if not maskTexture then maskTexture = circularMaskTexture end
    local mask = f:CreateMaskTexture()
    mask:SetAllPoints(port)
    mask:SetTexture(maskTexture, 'CLAMPTOBLACKADDITIVE', 'CLAMPTOBLACKADDITIVE')
    port:AddMaskTexture(mask)
end

function Helper:GetUnitHealthPercent(unit)
    if not unit then return 0 end

    local max_health = UnitHealthMax(unit)
    local health = UnitHealth(unit)

    return health / max_health
end

-- override with _G['DragonflightUI_Helper'].UnitFrameColorGradiantTable = [...]
-- maybe I'll add some color picker on advanced options, but for now a simple macro/addon/weakaura should be enough, if not
-- contact me on discord!
local UnitFrameColorGradiantTable = {
    DFCreateColor(1.0, 0, 0), -- red
    DFCreateColor(1.0, 0.6, 0), -- amber
    DFCreateColor(0.3, 1.0, 0.2) -- green
}
Helper.UnitFrameColorGradiantTable = UnitFrameColorGradiantTable;
Helper.UnitFrameColorGradiantCutoff = 0.60; -- 0.5

function Helper:LerpColor(percent, colorOne, colorTwo)
    if percent < 0 then
        percent = 0
    elseif percent > 1.0 then
        percent = 1.0;
    end

    local red = colorOne.r + (colorTwo.r - colorOne.r) * percent;
    local green = colorOne.g + (colorTwo.g - colorOne.g) * percent;
    local blue = colorOne.b + (colorTwo.b - colorOne.b) * percent;

    return red, green, blue
end

function Helper:ColorGradiant(percent)
    local red, green, blue;

    if percent < 0 then
        percent = 0
    elseif percent > 1.0 then
        percent = 1.0;
    end

    local cutoff = Helper.UnitFrameColorGradiantCutoff;
    if cutoff <= 0 then
        cutoff = 0.5
    elseif cutoff > 1.0 then
        cutoff = 0.5;
    end
    local cutoffMult = 1 / cutoff;

    if percent <= cutoff then
        red, green, blue = Helper:LerpColor(percent * cutoffMult, UnitFrameColorGradiantTable[1],
                                            UnitFrameColorGradiantTable[2])
    else
        red, green, blue = Helper:LerpColor((percent - (1 - cutoff)) * cutoffMult, UnitFrameColorGradiantTable[2],
                                            UnitFrameColorGradiantTable[3])
    end

    return red, green, blue
end

-- Escape closes this window, without putting its name in UISpecialFrames.
--
-- UISpecialFrames holds frame NAMES, and Blizzard's CloseSpecialWindows walks
-- it doing `local frame = _G[value]` - reading a global an addon created, which
-- taints that execution. Blizzard knows: the function carries a comment saying
-- it "handles possibly tainted values and so should always be called from
-- secure code using securecall()", and their one call site does exactly that.
--
-- The containment holds while it is Blizzard's function being called. It stops
-- holding when an addon replaces the global, which AceConfigDialog-3.0 does
-- permanently the first time any Ace options window is opened - ours or any
-- other addon's, and the library ships with half of them. From that point the
-- read escapes, and it is attributed to whoever owns the global it read. Four
-- DFUI windows were in that list, so it was regularly us - which is why our
-- name kept appearing on other people's taint reports.
--
-- Handling the key ourselves costs nothing and takes us out of it entirely.
-- Propagation stays ON except for the Escape we consume, so typing in the
-- window still works and every other key reaches the game.
-- Two rules make this safe, and the first version of it broke both.
--
-- SetPropagateKeyboardInput may only be called from inside a keyboard handler.
-- Called anywhere else it does not take - and the first version called it at
-- setup, on show and on hide, where it silently did nothing, inside a pcall
-- that hid the failure. So the window came up holding the keyboard with
-- propagation off, and every key it swallowed was a key that did not reach the
-- game: no movement, no spells, for as long as the window was open. Reported
-- as "any window open and I cannot move or cast", which is exactly what it is,
-- and the frames this is applied to - character, spellbook, quest log, trade,
-- inspect, talents - are exactly "any window".
--
-- A frame that is not shown should not hold the keyboard at all. Enabling it
-- once at setup left every one of these windows holding it for the whole
-- session, shown or not.
--
-- So: keyboard only while the window is up, and propagation touched only from
-- the one place the API allows, where every key that is not the Escape we
-- consume is explicitly passed through.
function Helper:CloseWithEscape(frame)
    if not frame or frame.DFEscapeHandled then return end
    frame.DFEscapeHandled = true

    local function hold(f) f:EnableKeyboard(true) end
    local function release(f) f:EnableKeyboard(false) end

    if frame:IsShown() then hold(frame) end
    frame:HookScript('OnShow', hold)
    frame:HookScript('OnHide', release)

    frame:HookScript('OnKeyDown', function(f, key)
        -- The only legal place to call this, and it applies to the key being
        -- handled right now - so the pass-through has to be set on every key,
        -- not just once.
        if key == 'ESCAPE' then
            f:SetPropagateKeyboardInput(false)
            f:Hide()
        else
            f:SetPropagateKeyboardInput(true)
        end
    end)
end

function Helper:CreateFrameEventCallback(event, fn)
    return EventRegistry:RegisterFrameEventAndCallback(event, function(_, ...)
        fn(...)
    end)
end

function Helper:CreateCVARCallback(cvar, fn, notInCombat)
    -- print('CreateCVARCallback', cvar)

    local ownerID = nil;
    local ownerIDLoaded = nil;
    local ownerIDCombat = nil;

    if notInCombat then
        ownerIDLoaded = Helper:CreateFrameEventCallback('VARIABLES_LOADED', function(...)
            -- print('~VARIABLES_LOADED', ...)
            if InCombatLockdown() then return end
            fn();
        end)

        ownerID = Helper:CreateFrameEventCallback('CVAR_UPDATE', function(...)
            -- print('~CVAR_UPDATE', ...)
            if InCombatLockdown() then return end
            local c, value = ...;

            if c == cvar then fn(); end
        end)

        ownerIDCombat = Helper:CreateFrameEventCallback('PLAYER_REGEN_ENABLED', function(...)
            -- print('~PLAYER_REGEN_ENABLED', ...)
            if InCombatLockdown() then return end
            fn();
        end)
    else
        ownerIDLoaded = Helper:CreateFrameEventCallback('VARIABLES_LOADED', function(...)
            -- print('~VARIABLES_LOADED', ...)
            fn();
        end)

        ownerID = Helper:CreateFrameEventCallback('CVAR_UPDATE', function(...)
            -- print('~CVAR_UPDATE', ...)
            local c, value = ...;

            if c == cvar then fn(); end
        end)
    end

    return ownerID, ownerIDLoaded, ownerIDCombat
end

-- function Helper:CreateFrameEventCallback(event, cvar, fn)
--     print('CreateFrameEventCallback', event, cvar)
--     return EventRegistry:RegisterFrameEventAndCallback(event, function(self, c, value)
--         -- print("showed the mount journal")
--         print(event, c, value)
--     end)
-- end


-- Blizzard builds the target/focus aura buttons lazily and BY NAME:
-- TargetFrame.lua:542 does CreateFrame('Button', selfName..'Debuff'..i, ...)
-- the first time a unit actually carries that many auras. Whichever execution
-- happens to be on the stack at that moment owns the resulting global for the
-- rest of the session, and if that execution is ours the global is tainted -
-- so every later TargetFrame:UpdateAuras() taints itself the moment it reads
-- the name back (TargetFrame.lua:539, :585, :742).
--
-- That is not theoretical: a taintLog run over a full addon set put DFUI second
-- only to NovaWorldBuffs, with 23,708 events, all but a few hundred of them
-- TargetFrameDebuffN. The counts fall away by index exactly as lazy creation
-- predicts - Debuff1 constantly, Debuff6 rarely.
--
-- So a refresh driven from our code is only allowed when it cannot create
-- anything: every button it might reach for has to exist already. When it
-- cannot, we do nothing at all. The client refreshes on the next UNIT_AURA
-- regardless, and it does so securely.

-- Highest N for which <name><kind>1 .. <name><kind>N all exist.
local function CountCreatedAuraFrames(name, kind, cap)
    local created = 0
    for i = 1, cap do
        if not _G[name .. kind .. i] then break end
        created = i
    end
    return created
end

local function CountAuras(unit, filterString, cap)
    -- No way to count means no way to prove it is safe.
    if not (AuraUtil and AuraUtil.ForEachAura) then return cap end

    local count = 0
    AuraUtil.ForEachAura(unit, filterString, cap, function()
        count = count + 1
        return count >= cap
    end)
    return count
end

function Helper:CanRefreshUnitAuras(frame)
    if not (frame and frame.GetName and AuraUtil and AuraUtil.CreateFilterString and AuraUtil.AuraFilters) then
        return false
    end

    local name = frame:GetName()
    local unit = frame.unit
    if not (name and unit) then return false end

    -- Nothing on the unit means nothing to create, and nothing to redraw.
    if not UnitExists(unit) then return false end

    local maxDebuffs = frame.maxDebuffs or MAX_TARGET_DEBUFFS or 16
    local maxBuffs = MAX_TARGET_BUFFS or 32

    local harmful = AuraUtil.CreateFilterString(AuraUtil.AuraFilters.Harmful, AuraUtil.AuraFilters.IncludeNameplateOnly)
    local helpful = AuraUtil.CreateFilterString(AuraUtil.AuraFilters.Helpful)

    if CountAuras(unit, harmful, maxDebuffs) > CountCreatedAuraFrames(name, 'Debuff', maxDebuffs) then return false end
    if CountAuras(unit, helpful, maxBuffs) > CountCreatedAuraFrames(name, 'Buff', maxBuffs) then return false end

    return true
end

-- Drives frame:UpdateAuras() only when doing so cannot create a named aura
-- button. Returns whether the refresh actually ran.
function Helper:RefreshUnitAuras(frame)
    if not Helper:CanRefreshUnitAuras(frame) then return false end

    if frame.UpdateAuras then
        frame:UpdateAuras()
    elseif TargetFrame_UpdateAuras then
        TargetFrame_UpdateAuras(frame)
    else
        return false
    end

    return true
end
