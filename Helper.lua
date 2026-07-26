local addonName, addonTable = ...;
local DF = LibStub('AceAddon-3.0'):GetAddon('DragonflightUI')
local L = LibStub("AceLocale-3.0"):GetLocale("DragonflightUI")

local Helper = {};
addonTable.Helper = Helper;

-- era-1159 diagnostics: persist phase timings so slow spots can be read from
-- disk after logout ("script ran too long" hides the real sink - the error
-- surfaces wherever the shared load-time budget happens to expire, not where
-- the time went). Wiped at the start of every session: the file always holds
-- the LAST session.
local perfLog = { boot = true }
DragonflightUIPerfLog = perfLog
-- SavedVariables load AFTER this file runs and would re-point the global at
-- last session's table; re-assert ours so the file on disk is always the
-- most recent session.
local perfFrame = CreateFrame('Frame')
perfFrame:RegisterEvent('ADDON_LOADED')
perfFrame:SetScript('OnEvent', function(self, _, name)
    if name == addonName then
        DragonflightUIPerfLog = perfLog
        self:UnregisterAllEvents()
    end
end)

-- make globally available
_G['DragonflightUI_Helper'] = Helper;

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
    C_Timer.After(1, Helper.ReapplyAfterCombat)
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
end

function Helper:QueueOutOfCombat(label, fn)
    loadedInCombat = true

    if not pendingOutOfCombat[label] then table.insert(pendingOrder, label) end
    pendingOutOfCombat[label] = fn

    if #perfLog < 400 then perfLog[#perfLog + 1] = 'deferred ' .. label .. ' to end of combat' end

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

