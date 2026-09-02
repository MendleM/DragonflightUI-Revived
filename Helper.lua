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
-- The leftover layout, which is the one thing here that cannot be cleaned up in
-- code - so the player gets told instead.
--
-- A version of this addon up to and including cda4133 did this on every login:
--
--   LibEditModeOverride:AddLayout(Enum.EditModeLayoutType.Character, 'DragonflightUI_Layout')
--   LibEditModeOverride:SetActiveLayout('DragonflightUI_Layout')
--
-- It created a character-specific layout in Blizzard's Edit Mode and made it the
-- active one. That code is long gone, but the layout is not: Edit Mode layouts
-- live on Blizzard's server, so it survives uninstalling the addon, wiping WTF
-- and reinstalling the game. SanitizeLegacyEditModeAnchors above cleans the
-- dangling anchors inside it, which is what caused the visible damage, but the
-- layout itself stays.
--
-- Deleting it from here is not safe. Blizzard's DeleteLayout indexes
-- self.layoutInfo.layouts, which is presets .. saved, while C_EditMode.GetLayouts()
-- returns the saved ones only - two different index spaces for the same data. Get
-- that wrong and you delete somebody else's layout, on the server, permanently.
-- Blizzard's own dropdown computes the index correctly, so the player is the safer
-- tool here.
local LEGACY_LAYOUT_NAME = 'DragonflightUI_Layout'
local MANAGED_LAYOUT_NAME = 'DFUI_Revived_Layout'

-- Say it once per character, then keep quiet.
--
-- The messages about a layout being added, renamed or deleted are tied to something having
-- happened, so they cannot repeat. The ones about something NOT working are not: a spent
-- attempt on a preset, a switch that will not take, a full layout list. Those conditions
-- persist, and printing them on every login is exactly the noise people complain about.
--
-- Recorded per character because that is the scope of the thing being described - which
-- layout is active, and whether this character has used its attempt.
local function TellOnce(key, message)
    local charDB = DF.db and DF.db.char
    if not charDB then return end

    charDB.editModeLayoutNotices = charDB.editModeLayoutNotices or {}

    if charDB.editModeLayoutNotices[key] then
        DF:Debug(DF, 'editmode layout (already told): ' .. message)

        return
    end

    charDB.editModeLayoutNotices[key] = true
    DF:Print(message)
end

-- Rename the leftover layout rather than asking anyone to delete it.
--
-- Its name was never the harmful part - the anchorInfo pointing at this addon's frames
-- was, and SanitizeLegacyEditModeAnchors above resets exactly those. Once that has run
-- what remains is an ordinary working layout with an awkward name. And a layout that can
-- hold settings is precisely what EnsureSaveableEditModeLayout further down needs, so it
-- gets a clearer name and is then reused - instead of a popup walking people through
-- deleting it so this addon can add a near-identical one straight after.
--
-- Written through the plain table and C_EditMode.SaveLayouts, the same way the anchor
-- migration writes, and matched by NAME rather than index. Blizzard's RenameLayout wants
-- an index into EditModeManagerFrame.layoutInfo.layouts, which is presets .. saved,
-- while C_EditMode.GetLayouts() returns the saved ones alone - confusing those two
-- spaces is what corrupts somebody's layouts on the server for good.
-- Has every DragonflightUI anchor been cleared out of this character's layouts?
--
-- The gate on reusing the old layout. Until this is true it may still carry anchors
-- pointing at our frames, which is the very thing that made it look broken with the
-- addon off - so it stays untouched and unused until the repair has finished.
local function AnchorMigrationDone()
    local db = DF.db and DF.db.char

    return db ~= nil and (db.editModeAnchorMigration or 0) >= ANCHOR_MIGRATION_VERSION
end

-- Keep and rename it where it is needed, delete it where it is not.
--
-- Needed means the active layout is a preset, which cannot store the setting - then this
-- leftover is the layout that can, and EnsureSaveableEditModeLayout below activates it
-- instead of adding another one. Not needed means the player is already working on a
-- layout of their own, so the setting has a home and this one is pure clutter in the
-- dropdown - which is what the old delete-it-yourself popup was about.
--
-- The layout the player is currently on is never deleted, whatever else is true.
--
-- Deleting goes through Blizzard's DeleteLayout, which needs an index into
-- EditModeManagerFrame.layoutInfo.layouts - presets .. saved. That index is found by
-- NAME in that very table, never guessed and never taken from C_EditMode.GetLayouts(),
-- which returns the saved ones alone. Confusing those two spaces is what deletes
-- somebody else's layout on the server for good. Blizzard's own DeleteLayout also
-- refuses to touch a preset, which is a second net under the first.
local function HandleLegacyLayout()
    if not AnchorMigrationDone() then return end

    local info = EditModeManagerFrame and EditModeManagerFrame.layoutInfo
    if not (info and info.layouts) then return end

    local presetType = Enum.EditModeLayoutType and Enum.EditModeLayoutType.Preset
    if not presetType then return end

    local legacyIndex, nameTaken
    for index, layout in ipairs(info.layouts) do
        if layout.layoutName == LEGACY_LAYOUT_NAME then
            legacyIndex = index
        elseif layout.layoutName == MANAGED_LAYOUT_NAME then
            nameTaken = true
        end
    end

    if not legacyIndex then return end

    -- One question decides it: is a layout needed at all?
    --
    -- The active layout being a preset is what makes one necessary, because a preset
    -- cannot keep the setting. Then this is the layout that can, so it is kept and
    -- renamed - whatever else the player happens to own. Sitting on a layout of their own
    -- means the setting already has a home and this one has no job left, so it goes.
    --
    -- Read off layoutInfo directly rather than through IsActiveLayoutPreset, which is
    -- declared further down the file and would not be in scope here.
    local activeLayout = info.activeLayout and info.layouts[info.activeLayout]
    local activeIsPreset = activeLayout ~= nil and activeLayout.layoutType == presetType
    local isActive = info.activeLayout == legacyIndex

    if not isActive and not activeIsPreset and EditModeManagerFrame.DeleteLayout then
        if pcall(EditModeManagerFrame.DeleteLayout, EditModeManagerFrame, legacyIndex) then
            DF:Print('Removed the leftover Edit Mode layout |cff8080ff' .. LEGACY_LAYOUT_NAME ..
                         '|r. You are on a layout of your own, so it had no purpose any more.')
        end

        return
    end

    -- Kept, so give it a name that says where it came from. Skipped when something
    -- already holds that name, because two identically named layouts in the dropdown
    -- cannot be told apart.
    if nameTaken then return end
    if not (C_EditMode and C_EditMode.GetLayouts and C_EditMode.SaveLayouts) then return end

    -- Renamed on the plain table, the same way the anchor migration writes, rather than
    -- through Blizzard's RenameLayout - that one drags PrepareSystemsForSave across every
    -- registered system behind it. Matching by name means the narrower index space of
    -- C_EditMode.GetLayouts() does not matter here.
    local ok, savedLayouts = pcall(C_EditMode.GetLayouts)
    if not (ok and savedLayouts and savedLayouts.layouts) then return end

    for _, layout in ipairs(savedLayouts.layouts) do
        if layout.layoutName == LEGACY_LAYOUT_NAME then
            layout.layoutName = MANAGED_LAYOUT_NAME

            if pcall(C_EditMode.SaveLayouts, savedLayouts) then
                DF:Print('Renamed the leftover Edit Mode layout |cff8080ff' .. LEGACY_LAYOUT_NAME ..
                             '|r to |cffffff78' .. MANAGED_LAYOUT_NAME ..
                             '|r. Nothing about your interface changes - DragonflightUI keeps Blizzard settings ' ..
                             'in it now instead of re-applying them every login.')
            end

            return
        end
    end
end

local legacyEditModeWatcher = CreateFrame('Frame')
legacyEditModeWatcher:SetScript('OnEvent', function(self)
    -- SaveLayouts drags the whole layout-apply chain behind it, and that ends in
    -- SetPoint on the action bars and unit frames, which the client refuses in
    -- combat. RunOutOfCombat queues by label, so a fight only delays it.
    Helper:DeferOutOfCombat('editmode legacy cleanup', function()
        local anchorsSettled = addonTable:SanitizeLegacyEditModeAnchors()

        -- After the anchors, because those are what made the old layout unusable and this
        -- decides whether to keep it. Idempotent once it has run.
        HandleLegacyLayout()

        -- The raid-style layout check rides along here because it waits on the same
        -- thing: layoutInfo being loaded. By the time this fires it always is, so a
        -- write that arrives after this watcher has gone can answer for itself.
        local layoutSettled = addonTable:EvaluateEditModeLayoutForRaidStyle()

        if anchorsSettled and layoutSettled then self:UnregisterAllEvents() end
    end)
end)
-- Not every flavour has this event, and RegisterEvent throws on an unknown one.
pcall(legacyEditModeWatcher.RegisterEvent, legacyEditModeWatcher, 'EDIT_MODE_LAYOUTS_UPDATED')

-- Does Blizzard already hold this value?
--
-- Extracted so the writer below and the preset notice share one answer. A mismatch is
-- exactly the condition that runs Blizzard's applier from our execution, and for
-- UseRaidStylePartyFrames that applier calls CompactPartyFrame:RefreshMembers()
-- directly - which is where the compact party frames pick up our taint.
local function BlizzardHoldsSettingValue(systemFrame, setting, val)
    if not (systemFrame and systemFrame.GetSettingValue) then return false end

    local ok, current = pcall(systemFrame.GetSettingValue, systemFrame, setting)
    if not (ok and current ~= nil) then return false end

    local a, b = tonumber(current), tonumber(val)
    if a and b and a == b then return true end

    return current == val
end

-- Is the active Edit Mode layout one of Blizzard's presets?
--
-- Presets are read-only. C_EditMode.SaveLayouts on one opens the "name your new
-- layout" dialog instead of saving, so a setting written into a preset never
-- persists - and a setting that never persists has to be re-applied every session.
local function IsActiveLayoutPreset()
    if not (EditModeManagerFrame and EditModeManagerFrame.IsActiveLayoutPreset) then return false end

    local ok, isPreset = pcall(EditModeManagerFrame.IsActiveLayoutPreset, EditModeManagerFrame)

    return ok and isPreset == true
end

-- Give the player a layout that can actually keep the raid-style party setting.
--
-- A preset cannot hold it, so this addon ends up re-applying it every single login,
-- and Blizzard's applier for that setting reaches straight into the compact frames:
--
--   EditModeUnitFrameSystemMixin:UpdateSystemSettingUseRaidStylePartyFrames()
--     CompactPartyFrame:RefreshMembers()
--       CompactUnitFrame_SetUpFrame(...)   -- writes optionTable on every member
--
-- Run from our execution those fields come out insecure, and the first update that
-- wants to hide an unused member is refused - a group member levelling up mid-fight is
-- how it shows. /df log seed traced exactly that: FIRST INSECURE .optionTable on
-- CompactPartyFrameMember1, through UpdateSystemSettingUseRaidStylePartyFrames, from
-- Party.mixin.lua Setup(), on a plain reload in no group.
--
-- Blizzard runs the very same applier without tainting anything, at login, for whatever
-- the active layout holds. So the answer is not to outwit the applier but to stop being
-- the one who calls it - which means the value needs a layout that keeps it.
--
-- Blizzard's own copy-layout button does this, and this uses the same entry point:
--
--   EditModeManagerFrameMixin:MakeNewLayout(newLayoutInfo, layoutType, layoutName, isImported)
--     works out the index itself from highestLayoutIndexByType
--     table.insert(self.layoutInfo.layouts, newLayoutIndex, newLayoutInfo)
--     self:SaveLayouts()
--     C_EditMode.OnLayoutAdded(newLayoutIndex, activateNewLayout, isImported)
--
-- Blizzard computing that index is the point. layoutInfo.layouts is presets .. saved
-- while C_EditMode.GetLayouts() returns the saved ones only, and mixing the two spaces
-- up deletes one of the player's layouts on the server for good. Handing the whole job
-- to MakeNewLayout means no index of ours is ever involved. It also activates the new
-- layout for us, through OnLayoutAdded.
--
-- The layout is a plain copy of whatever was active, so nothing visibly changes. Above
-- all it carries none of our anchors: the old DragonflightUI_Layout wrote anchorInfo
-- pointing at this addon's frames, which left the interface looking broken whenever the
-- addon was off and could not be cleaned up afterwards - issue #27. A copy of a preset
-- plus one setting Blizzard offers itself is an ordinary layout, with or without us.


-- Put one system setting into one layout table.
--
-- Pulled out to file level so the layout writer below and the new-layout copy above can
-- share it. Operates on a plain layout table and nothing else - never on
-- EditModeManagerFrame.layoutInfo, which holds the presets too.
--
-- The value has to be the RAW form, the one C_EditMode.SaveLayouts stores, not the
-- display form the sliders show. For a boolean like UseRaidStylePartyFrames the two are
-- the same 0 or 1; for anything scaled they are not, and conflating them is what broke
-- the sliders once already.
local function SetLayoutSystemSetting(layout, system, systemIndex, setting, value)
    if not (layout and system and setting ~= nil and value ~= nil) then return end

    layout.systems = layout.systems or {}

    local foundSys = false
    for _, sys in ipairs(layout.systems) do
        if sys.system == system and (not systemIndex or sys.systemIndex == systemIndex) then
            foundSys = true
            sys.settings = sys.settings or {}

            local foundSetting = false
            for _, s in ipairs(sys.settings) do
                if s.setting == setting then
                    s.value = value
                    foundSetting = true
                end
            end

            if not foundSetting then table.insert(sys.settings, {setting = setting, value = value}) end
        end
    end

    if not foundSys then
        -- The 3 fallback is the party unit frame index, kept from the original writer so
        -- behaviour does not shift for callers that pass no index.
        table.insert(layout.systems, {
            system = system,
            systemIndex = systemIndex or 3,
            settings = {{setting = setting, value = value}},
            isInDefaultPosition = true
        })
    end
end

-- layoutInfo.layouts is the index space SelectLayout and activeLayout speak - presets
-- first, saved layouts after. Deliberately not C_EditMode.GetLayouts(), which returns
-- the saved ones alone and is therefore off by the number of presets.
--
-- The legacy name counts too, and has to. C_EditMode.SaveLayouts only refreshes
-- layoutInfo once EDIT_MODE_LAYOUTS_UPDATED comes back, so right after the rename this
-- table can still hold the old name - and looking for the new one alone would conclude
-- there is no layout and add a second, near-identical one. Only accepted once the anchor
-- repair is done, because that is what makes the old layout safe to sit on.
local function FindManagedLayoutIndex()
    local info = EditModeManagerFrame and EditModeManagerFrame.layoutInfo
    if not (info and info.layouts) then return nil end

    local legacyCounts = AnchorMigrationDone()

    for index, layout in ipairs(info.layouts) do
        if layout.layoutName == MANAGED_LAYOUT_NAME then return index end
        if legacyCounts and layout.layoutName == LEGACY_LAYOUT_NAME then return index end
    end

    return nil
end

-- Wait for the layout switch to land, then ask for a reload. Never perform one.
--
-- Two earlier attempts at doing it automatically both failed, and the second one failed
-- badly. Waiting for EDIT_MODE_LAYOUTS_UPDATED did not work because SaveLayouts fires that
-- event immediately while the activation is still a round trip, so the handler saw a preset
-- and bowed out. Polling and then calling ReloadUI did work - until it ran during combat:
--
--   ADDON_ACTION_BLOCKED: DragonflightUI tried to call the protected function 'reload()'
--
-- reload() out of a C_Timer callback is always insecure execution, and the client refuses
-- it in combat. Guarding on IsCombatLocked() would not settle it either, because the timer
-- can fire in the gap between the guard and the call. So this addon does not reload the UI
-- at all any more: it says the layout is ready and leaves that one keystroke to the player.
-- Nothing is lost by waiting - the layout is saved and active, and the next reload or login
-- picks it up whenever it happens.
local RELOAD_POLL_SECONDS = 0.5
local RELOAD_POLL_ATTEMPTS = 20

-- Make a layout the active one, and say so when it does not work.
--
-- EditModeManagerFrameMixin:SelectLayout wraps the real call in UI housekeeping:
--
--   self:ClearSelectedSystem();
--   C_EditMode.SetActiveLayout(layoutIndex);
--   self:NotifyChatOfLayoutChange();
--
-- ClearSelectedSystem touches parts of a manager frame this addon never opens, and if it
-- throws, SetActiveLayout on the line below it never runs - the layout is saved and
-- nothing switches, with no error to show for it. So the mixin is tried first, because it
-- keeps Blizzard's own bookkeeping in step, and C_EditMode.SetActiveLayout is the fallback
-- when it fails. That is the call that actually changes the layout.
local function ActivateLayout(index)
    if not index then return false, 'no layout index' end

    if EditModeManagerFrame and EditModeManagerFrame.SelectLayout then
        local ok, err = pcall(EditModeManagerFrame.SelectLayout, EditModeManagerFrame, index)
        if ok then return true end

        DF:Debug(DF, 'editmode layout: SelectLayout failed (' .. tostring(err) .. '), using SetActiveLayout')
    end

    if C_EditMode and C_EditMode.SetActiveLayout then
        local ok, err = pcall(C_EditMode.SetActiveLayout, index)
        if ok then return true end

        return false, tostring(err)
    end

    return false, 'no way to set the active layout on this client'
end

local function AskForReloadOnceLayoutIsActive()
    if not (C_Timer and C_Timer.NewTicker) then return end

    local attempts = 0
    local ticker

    ticker = C_Timer.NewTicker(RELOAD_POLL_SECONDS, function()
        attempts = attempts + 1

        if not IsActiveLayoutPreset() then
            ticker:Cancel()
            TellOnce('layoutReady', 'The |cffffff78' .. MANAGED_LAYOUT_NAME ..
                         '|r Edit Mode layout is active and holds the raid-style party frame setting. Type ' ..
                         '|cffffff78/reload|r when it suits you and the game takes over applying it.')

            return
        end

        if attempts >= RELOAD_POLL_ATTEMPTS then
            ticker:Cancel()
            TellOnce('switchTimedOut',
                     'The |cffffff78' .. MANAGED_LAYOUT_NAME ..
                         '|r Edit Mode layout is saved but the game has not switched to it. Select it in ' ..
                         'Blizzard\'s Edit Mode, or type |cffffff78/reload|r, and it will take effect.')
        end
    end)
end

-- pending, when given, is the setting that triggered this: {systemIndex, setting, value}.
-- It goes into the new layout before Blizzard stores it, so the very first login on that
-- layout already agrees with our profile and no applier of ours ever has to run.
--
-- Returns true when there is nothing left to do.
function addonTable:EnsureSaveableEditModeLayout(pending)
    if not IsActiveLayoutPreset() then return true end

    -- Before looking for our layout, in case it is the old one under its old name. This
    -- can run ahead of the watcher when layoutInfo was already loaded at our setup, and
    -- without it that character would get a fresh copy while the renamed one sat unused.
    HandleLegacyLayout()

    -- One attempt per character, and the flag goes down only immediately before the call
    -- that changes something - never up here.
    --
    -- Setting it on the way in burns the single attempt on every early return below, and
    -- several of those are conditions that say nothing about whether it would work:
    -- layoutInfo not loaded yet, an Enum missing on this flavour, a pcall that threw. That
    -- is how this ended up reporting "already tried" on a character that had no layout.
    --
    -- What it does have to cover is the reload: once SelectLayout or MakeNewLayout has run
    -- we reload, and if the layout did not come back - no free slot, server refused - a
    -- second attempt would reload again at the next login, and again, forever.
    local charDB = DF.db and DF.db.char

    local function MarkAttempted()
        if charDB then charDB.raidStyleLayoutAttempted = true end
    end

    -- The layout already exists - this character made it before, or another one did, or the
    -- switch to it did not land last time. Select it and stop.
    --
    -- Deliberately ahead of the attempt flag. That flag exists to stop a second ADD, which
    -- is the part that eats a layout slot and cannot be undone; selecting costs nothing and
    -- has to stay possible, otherwise a spent attempt would leave the layout sitting there
    -- unused forever. Nor can this loop: the reload below waits for the switch to actually
    -- land, and once it has, the preset check at the top of this function ends it.
    local existing = FindManagedLayoutIndex()
    if existing then
        local ok, err = ActivateLayout(existing)
        if ok then
            -- Told once as well: when the switch lands there is no preset active next login
            -- and this is never reached again, but if it never lands this would otherwise
            -- announce itself on every single login.
            TellOnce('switching', 'Switching to the |cffffff78' .. MANAGED_LAYOUT_NAME ..
                         '|r Edit Mode layout, which can store the raid-style party frame setting.')
            AskForReloadOnceLayoutIsActive()
        else
            TellOnce('selectFailed',
                     'Could not switch to the |cffffff78' .. MANAGED_LAYOUT_NAME .. '|r Edit Mode layout: ' ..
                         tostring(err))
        end

        return true
    end

    if charDB and charDB.raidStyleLayoutAttempted then
        TellOnce('presetFallback',
                 'Your active Edit Mode layout is a preset and cannot store the raid-style party frame setting, so ' ..
                     'DragonflightUI has to re-apply it every login. Switching to a layout of your own in ' ..
                     'Blizzard\'s Edit Mode avoids that, and |cffffff78/df layoutretry|r tries again.')

        return true
    end

    -- MakeNewLayout indexes self.highestLayoutIndexByType to work out where the new layout
    -- goes, and that field is built in exactly one place:
    --
    --   EditModeManagerFrameMixin:CreateLayoutTbls()
    --       self.highestLayoutIndexByType = {};
    --
    -- which runs when Blizzard builds its layout dropdown - so only once its Edit Mode has
    -- been opened. This addon never opens it, so in a normal session the field is nil and
    -- MakeNewLayout dies on it: "attempt to index field 'highestLayoutIndexByType'".
    --
    -- CreateLayoutTbls is a plain pass over layoutInfo.layouts with no UI side effects, so
    -- Blizzard gets asked to do its own bookkeeping rather than us inventing that field.
    -- Ahead of AreLayoutsFullyMaxed as well, which counts from the same data.
    if not EditModeManagerFrame.highestLayoutIndexByType then
        if EditModeManagerFrame.CreateLayoutTbls then
            pcall(EditModeManagerFrame.CreateLayoutTbls, EditModeManagerFrame)
        end

        -- Still nothing, so MakeNewLayout would only throw again. Leave the attempt
        -- unspent: a later login, with Blizzard's Edit Mode further along, can retry.
        if not EditModeManagerFrame.highestLayoutIndexByType then
            -- Debug only: the player cannot act on this, and the attempt is left unspent so
            -- a later login tries again. Printing it would be noise about our own timing.
            DF:Debug(DF, 'editmode layout: highestLayoutIndexByType still missing after CreateLayoutTbls')

            return true
        end
    end

    if EditModeManagerFrame.AreLayoutsFullyMaxed then
        local ok, maxed = pcall(EditModeManagerFrame.AreLayoutsFullyMaxed, EditModeManagerFrame)
        if ok and maxed then
            TellOnce('layoutsMaxed',
                     'All Edit Mode layout slots are full, so DragonflightUI cannot add one for the raid-style ' ..
                         'party frames. Free a slot, or switch to a layout of your own - either lets Blizzard keep ' ..
                         'the setting instead of this addon re-applying it every login.')

            return true
        end
    end

    -- Every abort from here down says what happened. They used to be silent, which left
    -- "nothing happened and no message" as the only symptom of a fix that never ran.
    if C_EditMode and C_EditMode.IsValidLayoutName then
        local ok, valid = pcall(C_EditMode.IsValidLayoutName, MANAGED_LAYOUT_NAME)
        if ok and not valid then
            TellOnce('nameRejected',
                     'The game rejected |cffffff78' .. MANAGED_LAYOUT_NAME ..
                         '|r as an Edit Mode layout name, so the raid-style party setting cannot be stored.')

            return true
        end
    end

    local layoutType = Enum.EditModeLayoutType and Enum.EditModeLayoutType.Account
    if not (layoutType and EditModeManagerFrame.MakeNewLayout and EditModeManagerFrame.GetActiveLayoutInfo) then
        DF:Debug(DF, 'editmode layout: MakeNewLayout/GetActiveLayoutInfo/LayoutType.Account not available')

        return true
    end

    local gotActive, active = pcall(EditModeManagerFrame.GetActiveLayoutInfo, EditModeManagerFrame)
    if not (gotActive and active) then
        DF:Debug(DF, 'editmode layout: GetActiveLayoutInfo gave nothing to copy')

        return true
    end

    -- CopyTable, because MakeNewLayout writes layoutType and layoutName straight onto what
    -- it is handed - and what it is handed here would otherwise be the live preset.
    local newLayout = CopyTable(active)

    -- The setting goes in before Blizzard ever sees the layout. Without this the copy
    -- carries the preset's value, so the next login finds a mismatch again and runs
    -- Blizzard's applier from our execution one last time - one avoidable taint.
    if pending and Enum.EditModeSystem then
        SetLayoutSystemSetting(newLayout, Enum.EditModeSystem.UnitFrame, pending.systemIndex, pending.setting,
                               pending.value)
    end

    MarkAttempted()

    local isImported = false
    local made, err = pcall(EditModeManagerFrame.MakeNewLayout, EditModeManagerFrame, newLayout, layoutType,
                            MANAGED_LAYOUT_NAME, isImported)
    if not made then
        DF:Print('Could not add the |cffffff78' .. MANAGED_LAYOUT_NAME .. '|r Edit Mode layout: ' .. tostring(err) ..
                     '. |cffffff78/df layoutretry|r tries again.')

        return true
    end

    DF:Print('Added an Edit Mode layout called |cffffff78' .. MANAGED_LAYOUT_NAME ..
                 '|r - a copy of the preset you were on - so the raid-style party frame setting can be stored ' ..
                 'instead of re-applied every login. Nothing about your interface changes.')

    -- MakeNewLayout asks the client to activate it, but only when nothing else is pending:
    --
    --   local activateNewLayout = not EditModeUnsavedChangesDialog:HasPendingSelectedLayout();
    --   C_EditMode.OnLayoutAdded(newLayoutIndex, activateNewLayout, isLayoutImported);
    --
    -- So it is a request, not a guarantee. table.insert has already put the layout into
    -- layoutInfo.layouts by now, so its index can be looked up and the switch made
    -- explicitly. Selecting an already-active layout is a no-op in SelectLayout.
    local added = FindManagedLayoutIndex()
    local activated, activateErr = ActivateLayout(added)
    if not activated then
        DF:Print('The layout is saved, but switching to it failed: ' .. tostring(activateErr) ..
                     '. Select |cffffff78' .. MANAGED_LAYOUT_NAME .. '|r in Blizzard\'s Edit Mode to finish.')

        return true
    end

    AskForReloadOnceLayoutIsActive()

    return true
end

-- Set when a raid-style write went through that the active layout may not be able to
-- keep, before the question could be answered.
--
-- At login our Setup can run before Blizzard has its layoutInfo, and asking then
-- answers "not a preset" for every layout - which would skip this silently. So the
-- write records that it happened and the answer is picked up once the layouts land, on
-- the same event the legacy-layout watcher already waits for.
-- Hand the one attempt back, for /df layoutretry.
--
-- The attempt is spent whether or not a layout appeared, because that is what keeps a
-- failed one from reloading the game on a loop. When it did fail there has to be a way
-- back in that does not involve editing SavedVariables with the game shut down.
function addonTable:ResetEditModeLayoutAttempt()
    local charDB = DF.db and DF.db.char
    if not charDB then return false end

    charDB.raidStyleLayoutAttempted = false

    -- The told-once record goes too, otherwise a retry that runs into the same wall would
    -- fail in silence.
    charDB.editModeLayoutNotices = nil

    return true
end

-- Holds the setting itself, not just a yes, so a layout created later can be born with
-- the right value in it.
local pendingLayoutSetting = nil

-- Returns true when there is nothing left to do.
function addonTable:EvaluateEditModeLayoutForRaidStyle()
    if not pendingLayoutSetting then return true end

    -- No layouts yet, so any answer would be a guess. Leave the payload in place.
    if not (EditModeManagerFrame and EditModeManagerFrame.layoutInfo) then return false end

    local pending = pendingLayoutSetting
    pendingLayoutSetting = nil

    return addonTable:EnsureSaveableEditModeLayout(pending)
end

-- Write one Edit Mode unit frame setting, and have Blizzard apply it.
--
-- Generalised out of the party raid-style sync below, because the raid frame
-- settings need the same two steps for the same reason. Every applier in
-- EditModeUnitFrameSystemMixin reads its own value back out of the layout:
--
--   UpdateSystemSettingFrameWidth -> UpdateCompactRaidFrameContainerSetting
--     -> CompactUnitFrame_UpdateAllFromEditMode -> GetSettingValue(...)
--       -> GetRegisteredSystemFrame(...) -> systemFrame:GetSettingValue(...)
--
-- There is no route that applies these to the frames directly, which is why the
-- block of raid options in Raid.mixin.lua sat commented out for so long. So the
-- value goes to the registered system frame through Blizzard's own setter, and to
-- the layout so it survives a reload.
--
-- SETTINGS VALUES ONLY. anchorInfo is never written here and must not be - an
-- anchor pointing at a DragonflightUI frame is what used to leave the interface
-- broken with this addon disabled. A setting value is self-contained and still
-- means something without this addon, which is the line we drew.
--
-- systemFrame is the frame Blizzard registered for that system, and it is what
-- OnSystemSettingChange needs: PartyFrame for the party system, CompactRaidFrame-
-- Container for the raid one.
function addonTable:SyncUnitFrameEditModeSetting(systemIndex, setting, value, systemFrame, label, layoutOnly)
    if not (Enum and Enum.EditModeSystem and Enum.EditModeUnitFrameSetting) then return end
    if setting == nil or value == nil then return end

    local targetSystem = Enum.EditModeSystem.UnitFrame
    if not targetSystem then return end

    local val = value
    if type(val) == 'boolean' then val = val and 1 or 0 end

    local targetSystemIndex = systemIndex
    local targetSetting = setting

    -- Nothing to do when Blizzard already holds this value, and doing it anyway is
    -- actively harmful.
    --
    -- OnSystemSettingChange below runs Blizzard's own applier from our execution, and for
    -- UseRaidStylePartyFrames that travels down
    -- UpdateSystemSettingUseRaidStylePartyFrames -> UpdateRaidAndPartyFrames - which is
    -- where Blizzard builds the compact party frames and writes optionTable and
    -- isLootObject on each of them. A field written while our execution is live stays
    -- tainted and is blamed on us.
    --
    -- CompactUnitFrame_UpdateAll reads optionTable on its first line, at 433, and calls
    -- CompactUnitFrame_UpdateVisible at 438 - so every update of an unused compact party
    -- frame is tainted before it reaches the frame:Hide() the client refuses in combat.
    -- That is the ADDON_ACTION_BLOCKED on CompactPartyFramePet1:Hide(), and the single
    -- stale "offline" member it leaves standing instead of the real group.
    --
    -- The value is persisted in the layout, so Blizzard applies it itself at login, from
    -- its own secure execution. Re-applying it from ours is what re-seeded that taint every
    -- session: /df log party reported those fields dirty after a plain reload, in no group,
    -- with the setting never touched. Only a real change goes through the applier now.
    if BlizzardHoldsSettingValue(systemFrame, targetSetting, val) then return end

    -- PartyFrame.system / PartyFrame.systemIndex are NOT written here any more,
    -- and must not be. They were the party taint seed.
    --
    -- Blizzard identifies a registered Edit Mode system by exactly these two
    -- fields, and it reads them inside secureexecuterange:
    --
    --   local function findSystem(index, systemFrame)
    --       if not foundSystem and systemFrame.system == system and systemFrame.systemIndex == systemIndex then
    --   secureexecuterange(self.registeredSystemFrames, findSystem);
    --
    -- That runs on every GetSettingValueBool, so on every
    -- UseRaidStylePartyFrames() - which both party ShouldShow paths ask. Writing
    -- the fields from addon code made them insecure for the session, and the taint
    -- then travelled down UpdateRaidAndPartyFrames -> UpdatePartyFrames ->
    -- UpdateMember into member.unit, member.buffs and member.debuffs, which is
    -- where the blocked actions on the party frames came from.
    --
    -- /df log seed proved it: "the seed is a field, not a global", followed by
    -- PartyFrame.system and PartyFrame.systemIndex insecure, tainted by
    -- DragonflightUI.
    --
    -- They were only ever set so that the old SetBlizzEditmodeFrameSetting could
    -- find its layout entry through frame.system. That function is gone, and
    -- nothing in this addon reads either field - the sys.system reads above are on
    -- plain layout tables, not on the frame. Blizzard sets both itself when it
    -- registers PartyFrame as a system.

    -- Takes the value as an argument rather than closing over it, because the layout needs
    -- the RAW form while the setter above needs the display form. Two different numbers
    -- for the same change; conflating them is what broke the sliders.
    local function EnsureSettingInLayout(layout, val)
        SetLayoutSystemSetting(layout, targetSystem, targetSystemIndex, targetSetting, val)
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
    -- Order matters, and so does which form of the value goes where.
    --
    -- The value handed in is the DISPLAY value, the number a slider shows. Blizzard's
    -- setter takes that form and converts it itself:
    --
    --   EditModeSystemMixin:UpdateSystemSettingValue(setting, newValue)
    --     local rawNewValue = self:ConvertSettingDisplayValueToRawValue(setting, newValue)
    --     settingInfo.value = rawNewValue
    --
    -- The LAYOUT stores the raw form. Writing the display value there is what made
    -- sliders come back at their maximum after a reload: frame width 98 was saved as 98,
    -- read back as raw on the next login and converted to 98 + 72 = 170, which clamps to
    -- the maximum of 144. Every reload pushed it further out.
    --
    -- So Blizzard's setter runs first and the raw value is then read back off the system
    -- frame through GetSettingValue(setting, useRawValue), rather than converted here.
    -- No arithmetic of ours to get wrong, and it stays correct for the settings that have
    -- no conversion at all.
    local function WriteLayout()
        if not (C_EditMode and C_EditMode.GetLayouts and C_EditMode.SaveLayouts) then return end

        local rawVal = val
        if systemFrame and systemFrame.GetSettingValue then
            local gotRaw, raw = pcall(systemFrame.GetSettingValue, systemFrame, targetSetting, true)
            if gotRaw and raw ~= nil then rawVal = raw end
        end

        local ok, layoutInfo = pcall(C_EditMode.GetLayouts)
        if ok and layoutInfo and layoutInfo.layouts then
            for _, layout in ipairs(layoutInfo.layouts) do
                EnsureSettingInLayout(layout, rawVal)
            end
            pcall(C_EditMode.SaveLayouts, layoutInfo)
        end
    end

    -- layoutOnly: store the value and let the game apply it at the next load, instead of
    -- running Blizzard's applier now.
    --
    -- For UseRaidStylePartyFrames the applier cannot be run safely from here at all, and
    -- this is the measured reason. Flipping the switch produced this, from /df log seed:
    --
    --   FIRST INSECURE .unit on <pooled> (unit=party2), tainted by DragonflightUI
    --     UnitFrame_SetUnit <- PartyMemberFrame:UpdateMember <- PartyFrame:UpdatePartyFrames
    --     <- RaidFrame:UpdateRaidAndPartyFrames
    --     <- UpdateSystemSettingUseRaidStylePartyFrames
    --     <- OnSystemSettingChange <- SyncUnitFrameEditModeSetting <- SetRaidStylePartyFrames
    --
    -- That one applier touches BOTH party displays: UpdateRaidAndPartyFrames walks the
    -- PartyMemberFrames and writes member.unit, and CompactPartyFrame:RefreshMembers writes
    -- optionTable on every compact frame. Called from our execution, every one of those
    -- fields stays insecure for the rest of the session - and the next group event to read
    -- them, an invite or a level-up, has its SetAttribute, Hide and SetShown refused.
    --
    -- Ten seconds passed between the seed and the first blocked call in that log, which is
    -- why this looked so erratic all along: the damage is done when the switch is flipped,
    -- it only becomes visible later. With one addon and no flip, nothing happened at all.
    --
    -- The layout is where the value belongs anyway. Blizzard applies it from there at login,
    -- out of its own execution, and taints nothing.
    if layoutOnly then
        WriteLayout()
    elseif EditModeManagerFrame and EditModeManagerFrame.OnSystemSettingChange and systemFrame then
        Helper:DeferOutOfCombat(label or 'unit frame edit mode setting', function()
            local ok, err = pcall(EditModeManagerFrame.OnSystemSettingChange, EditModeManagerFrame, systemFrame,
                                  targetSetting, val)
            if not ok then geterrorhandler()('DFUI OnSystemSettingChange: ' .. tostring(err)) end

            -- Inside the same block, so the raw read always happens after Blizzard has
            -- converted and stored it - including when this was deferred out of combat.
            WriteLayout()
        end)
    else
        WriteLayout()
    end
end

-- The party raid-style switch, on top of the general writer above.
--
-- This is the setting Blizzard consults on both party visibility paths -
-- UpdateRaidAndPartyFrames, CompactPartyFrame:ShouldShow and
-- CompactRaidFrameManager all ask UseRaidStylePartyFrames() - so it decides which
-- party system is live and nothing this addon does can substitute for it.
function addonTable:SyncRaidStylePartyFrameToBlizzard(enabled)
    if not (Enum and Enum.EditModeUnitFrameSetting) then return end

    local systemIndex = Enum.EditModeUnitFrameSystemIndices and Enum.EditModeUnitFrameSystemIndices.Party
    local setting = Enum.EditModeUnitFrameSetting.UseRaidStylePartyFrames
    local val = enabled and 1 or 0
    local partyFrame = _G['PartyFrame']

    -- A preset cannot hold this value, so the write below - and the taint Blizzard's
    -- applier leaves on the compact party frames - would come back every single session.
    -- EnsureSaveableEditModeLayout gives the value somewhere to live instead.
    --
    -- Both conditions matter, and the second one is checked in there. No mismatch means
    -- the writer returns early and nothing is tainted, preset or not; a layout of the
    -- player's own keeps the value, so a mismatch is a one-off. Only the two together
    -- repeat forever.
    if not BlizzardHoldsSettingValue(partyFrame, setting, val) then
        -- Raw and display form are the same 0/1 for this boolean, so val can go straight
        -- into a layout. That is not true of scaled settings - see SetLayoutSystemSetting.
        pendingLayoutSetting = {systemIndex = systemIndex, setting = setting, value = val}
        Helper:DeferOutOfCombat('party raid style layout check',
                              function() addonTable:EvaluateEditModeLayoutForRaidStyle() end)
    end

    -- layoutOnly. This is the one setting whose applier cannot be run from addon code
    -- without breaking the party frames for the rest of the session - the long comment in
    -- SyncUnitFrameEditModeSetting has the traced stack. It takes effect on the next load.
    local layoutOnly = true
    addonTable:SyncUnitFrameEditModeSetting(systemIndex, setting, val, partyFrame, 'party raid style setting',
                                            layoutOnly)
end


-- Which frame did Blizzard register for the raid unit frame system?
--
-- OnSystemSettingChange needs it, and it is not the same object as the party one.
-- Asked rather than assumed, because the answer differs by flavour and a wrong
-- guess here silently does nothing.
local function GetRaidSystemFrame()
    if not (Enum and Enum.EditModeSystem and Enum.EditModeUnitFrameSystemIndices) then return nil end

    if EditModeManagerFrame and EditModeManagerFrame.GetRegisteredSystemFrame then
        local ok, frame = pcall(EditModeManagerFrame.GetRegisteredSystemFrame, EditModeManagerFrame,
                                Enum.EditModeSystem.UnitFrame, Enum.EditModeUnitFrameSystemIndices.Raid)
        if ok and frame then return frame end
    end

    return _G['CompactRaidFrameContainer']
end

-- The registered raid system frame, for the options builder.
--
-- Exposed because the options are built from Blizzard's own display info and have to
-- ask HasSetting per entry: whatever the raid system actually supports on this
-- flavour is what gets offered, rather than a hardcoded list.
function addonTable:GetRaidSystemFrameForOptions()
    return GetRaidSystemFrame()
end

-- Establish what the raid container needs before it will lay anything out.
--
-- Only Blizzard's Edit Mode ever does this, and this addon locks that Edit Mode out:
--
--   EditModeUnitFrameSystemMixin:UpdateSystemSettingRaidGroupDisplayType()
--     CompactRaidFrameContainer:SetGroupMode(UseCombinedGroups() and "flush" or "discrete")
--   EditModeUnitFrameSystemMixin:UpdateSystemSettingSortPlayersBy()
--     CompactRaidFrameContainer:SetFlowSortFunction(sortFunc)
--
-- CompactRaidFrameContainerMixin:ReadyToUpdate returns false with no group mode, and
-- again with mode "flush" and no sort function, so LayoutFrames is skipped and TryUpdate
-- does nothing whatsoever. The result is a container that is shown, on screen, roughly
-- one member wide and empty, with no error to show for it - a raid with no frames.
--
-- The manager sets the two filter functions itself in its OnLoad, so those are not
-- missing; only the group mode and the sort function come from the appliers.
--
-- Calling Blizzard's own appliers is the same approach Focus.mixin takes with
-- FocusFrame:SetSmallSize: run the applier, write nothing extra to the layout. Both read
-- their values back through GetSettingValue, which is already fed by
-- SyncUnitFrameEditModeSetting.
function addonTable:ApplyRaidFlowPrereqs()
    local frame = GetRaidSystemFrame()
    if not frame then return false, 'no registered raid system frame' end

    -- Ask for each applier only when its own prerequisite is actually missing.
    --
    -- UpdateSystemSettingRaidGroupDisplayType ends in CompactRaidFrameContainer:SetGroupMode,
    -- and that calls TryUpdate, whose first line refreshes the compact PARTY frames -
    -- CompactUnitFrame_SetUpFrame writes optionTable on each of them, from our execution.
    -- CompactUnitFrame_UpdateAll reads that field before the frame:Hide() the client refuses
    -- in combat, so calling this when the group mode is already set breaks somebody else's
    -- frames for nothing. /df log seed named this exact stack.
    --
    -- The sort function is harmless by comparison: for the raid system the applier writes
    -- flowSortFunc on the container, and only the party system's variant goes through
    -- CompactPartyFrame:SetFlowSortFunction, which is the one that refreshes members.
    local container = _G['CompactRaidFrameContainer']
    local haveMode = (container and container.GetGroupMode and container:GetGroupMode()) and true or false
    local haveSort = (container and container.flowSortFunc) and true or false

    if haveMode and haveSort then return true end

    local ok, err = pcall(function()
        if not haveMode and frame.UpdateSystemSettingRaidGroupDisplayType then
            frame:UpdateSystemSettingRaidGroupDisplayType()
        end
        if not haveSort and frame.UpdateSystemSettingSortPlayersBy then
            frame:UpdateSystemSettingSortPlayersBy()
        end
    end)
    if not ok then return false, err end

    return true
end

-- Which frame did Blizzard register for the party unit frame system?
--
-- Asked rather than assumed, the same way the raid one is, and for the same reason: a
-- wrong guess here writes a setting nothing ever reads.
local function GetPartySystemFrame()
    if not (Enum and Enum.EditModeSystem and Enum.EditModeUnitFrameSystemIndices) then return nil end

    if EditModeManagerFrame and EditModeManagerFrame.GetRegisteredSystemFrame then
        local ok, frame = pcall(EditModeManagerFrame.GetRegisteredSystemFrame, EditModeManagerFrame,
                                Enum.EditModeSystem.UnitFrame, Enum.EditModeUnitFrameSystemIndices.Party)
        if ok and frame then return frame end
    end

    return _G['PartyFrame']
end

-- Mirror one raid frame setting onto the party system, for raid-style party frames.
--
-- Raid and party are separate Edit Mode systems and Blizzard keeps their settings apart,
-- so the raid page cannot reach the party frames by itself. It does not need to, because
-- every compact unit frame reads its own system's value:
--
--   local frameWidth = EditModeManagerFrame:GetRaidFrameWidth(frame.groupType, NATIVE_UNIT_FRAME_WIDTH)
--     -> GetSettingValue(Enum.EditModeSystem.UnitFrame, systemIndex, ...FrameWidth)
--
-- and groupType is that system index. Writing the same number to the party system is all
-- "show party as raid" needs to follow the raid page.
--
-- Only where the party system admits to having the setting. The raid-only layout ones -
-- raid size, group split, row size - are not in that set, and are skipped rather than
-- forced onto a system that would ignore them anyway.
function addonTable:MirrorRaidSettingToParty(setting, value)
    if setting == nil or value == nil then return false end
    if not (Enum and Enum.EditModeUnitFrameSystemIndices) then return false end

    -- Every mirrored setting but one is safe, and the exception is worth naming.
    --
    -- The appliers this reaches on the party system end in PartyFrame:UpdatePaddingAndLayout
    -- (EditModeSystemTemplates.lua:1442) or a plain SetAlpha - frame width, height, border,
    -- template, icon size, opacity all go through
    -- UpdateCompactRaidFrameContainerSetting, whose party branch never calls TryUpdate.
    --
    -- SortPlayersBy is the exception. Its party branch is
    --
    --   CompactPartyFrame:SetFlowSortFunction(sortFunc)   -- :1507
    --
    -- and CompactPartyFrameMixin:SetFlowSortFunction calls self:RefreshMembers() on its
    -- second line, which writes optionTable on every compact party member from our
    -- execution. That field is read on the first line of CompactUnitFrame_UpdateAll, before
    -- the frame:Hide() the client refuses in combat - the one seed that breaks the party
    -- frames outright. A sort order is not worth that, so it is skipped.
    if Enum.EditModeUnitFrameSetting and setting == Enum.EditModeUnitFrameSetting.SortPlayersBy then
        return false
    end

    local frame = GetPartySystemFrame()
    if not (frame and frame.HasSetting) then return false end

    local hasIt, has = pcall(frame.HasSetting, frame, setting)
    if not (hasIt and has) then return false end

    addonTable:SyncUnitFrameEditModeSetting(Enum.EditModeUnitFrameSystemIndices.Party, setting, value, frame,
                                            'party frame setting ' .. tostring(setting))
    return true
end

-- Exposed so the diagnostics can report which settings the party system actually shares
-- with the raid one, rather than leaving the intersection to guesswork.
function addonTable:GetPartySystemFrameForOptions()
    return GetPartySystemFrame()
end

-- One raid frame Edit Mode setting, by setting id.
--
-- Ids rather than Enum key names, because the caller now walks Blizzard's display
-- info table, which already carries the id in entry.setting. Values are the STORED
-- form; sliders are converted by the caller through Blizzard's own ConvertValue.
function addonTable:SetRaidEditModeSettingBySetting(setting, value)
    if not (Enum and Enum.EditModeUnitFrameSystemIndices) then return false end
    if setting == nil then return false end

    addonTable:SyncUnitFrameEditModeSetting(Enum.EditModeUnitFrameSystemIndices.Raid, setting, value,
                                            GetRaidSystemFrame(), 'raid frame setting ' .. tostring(setting))
    return true
end

-- The stored value Blizzard currently holds, or nil when the system has no such
-- setting.
--
-- Read from the registered system frame, the same source Blizzard's own appliers use,
-- so the options show what is actually in effect rather than a copy that can drift.
-- Reading a Blizzard table does not taint it.
function addonTable:GetRaidEditModeSettingBySetting(setting)
    if setting == nil then return nil end

    local frame = GetRaidSystemFrame()
    if not (frame and frame.GetSettingValue and frame.HasSetting) then return nil end

    local hasIt, has = pcall(frame.HasSetting, frame, setting)
    if not (hasIt and has) then return nil end

    local ok, val = pcall(frame.GetSettingValue, frame, setting)
    if not ok then return nil end

    return val
end

-- Kept for the options layer's existence check, which asks for this by name before
-- building anything.
function addonTable:SetRaidEditModeSetting(settingKey, value)
    if not (Enum and Enum.EditModeUnitFrameSetting) then return false end

    return addonTable:SetRaidEditModeSettingBySetting(Enum.EditModeUnitFrameSetting[settingKey], value)
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

-- The quiet queue, for work that is routine rather than setup.
--
-- RunOutOfCombat below does three things at once: it defers the work, it tells the player
-- the UI is half-built, and when combat drops it follows the whole queue with
-- DF:RefreshConfig() - which re-applies settings across every module in the addon.
--
-- That is right for what it was written for, a reload in the middle of a fight. It is
-- wrong for anything routine, and routine callers were using it: RaidFlowWatcher on every
-- GROUP_ROSTER_UPDATE, the vehicle button on every vehicle enter and exit, the minimap on
-- a CVar change. In a raid that means "combat ended - finishing setup (RaidFlowWatcher)"
-- after every pull, each one dragging a full RefreshConfig behind it - the lag spike and
-- the chat spam people reported.
--
-- So this queue defers and nothing else: no loadedInCombat, no chat line, no on-screen
-- notice, no RefreshConfig. It runs on the same PLAYER_REGEN_ENABLED gate, just before
-- the loud one.
local pendingQuiet = {}
local pendingQuietOrder = {}

local function DrainQuietQueue()
    if #pendingQuietOrder == 0 then return end

    for _, label in ipairs(pendingQuietOrder) do
        local fn = pendingQuiet[label]
        pendingQuiet[label] = nil

        if fn then
            local ok, err = pcall(fn)
            if not ok then geterrorhandler()('DFUI deferred (' .. label .. '): ' .. tostring(err)) end
        end
    end

    table.wipe(pendingQuietOrder)
end

local function DrainOutOfCombatQueue()
    DrainQuietQueue()

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

local function EnsureCombatGate()
    if combatGate then return end

    combatGate = CreateFrame('Frame')
    combatGate:RegisterEvent('PLAYER_REGEN_ENABLED')
    combatGate:SetScript('OnEvent', function()
        -- PLAYER_REGEN_ENABLED fires as lockdown lifts; the next frame is
        -- safely out of it
        C_Timer.After(0, DrainOutOfCombatQueue)
    end)
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

    EnsureCombatGate()
end

-- Did this session start (or reload) mid-combat? Anything that wants to explain
-- itself to the player can ask.
function Helper:LoadedInCombat()
    return loadedInCombat
end

-- Run now when it is safe, otherwise once combat drops - quietly.
--
-- For work that happens over and over in normal play: roster updates, vehicle seats, a
-- CVar flipping, a setting being written. It defers and that is all. Nothing is said to
-- the player, because nothing is wrong, and no RefreshConfig follows it, because one
-- deferred call does not mean the whole interface needs rebuilding.
--
-- Use RunOutOfCombat instead when a module could not finish setting itself up at all -
-- that is a half-built UI, and it is worth both the explanation and the re-apply.
function Helper:DeferOutOfCombat(label, fn)
    if not Helper:IsCombatLocked() then
        fn()

        return
    end

    if not pendingQuiet[label] then table.insert(pendingQuietOrder, label) end
    pendingQuiet[label] = fn

    if #perfLog < 400 then perfLog[#perfLog + 1] = 'deferred ' .. label .. ' quietly to end of combat' end

    EnsureCombatGate()
end

-- Run now when it is safe, otherwise once combat drops.
--
-- The loud one: it marks the session as having loaded in combat, tells the player, and has
-- DF:RefreshConfig() run once the queue is done. Reserved for module setup that the client
-- refused outright - see DeferOutOfCombat for everything routine.
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
