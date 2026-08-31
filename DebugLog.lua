local addonName, addonTable = ...;
local DF = LibStub('AceAddon-3.0'):GetAddon('DragonflightUI')

-- Shared debug log.
--
-- Two things make bugs in this addon hard to pin down: half of what goes
-- wrong is not a Lua error (taint blocks, a frame that is shown but not
-- visible, a hook that silently never installed), and the person who can
-- reproduce it is usually not the person reading the code. So the log is
-- written to SavedVariables as well as the chat frame: after a /reload or
-- logout, DragonflightUIDebugLog in the account's SavedVariables holds the
-- run, and can be read - or pasted - in full.
--
-- Usage from anywhere in the addon:
--     DF:Log('rollpreview', 'holder %s visible=%s', name, tostring(vis))
--
-- Slash commands:
--     /df log              last 30 entries in chat
--     /df log all          the whole buffer in chat
--     /df log copy [tag]   a window to select all and copy out of, for pasting
--                          into a bug report; takes the same tag filter
--     /df log echo         toggle live echo of every entry to chat
--     /df log clear        empty the buffer
--     /df log frame <name>   a frame's whole visibility chain
--     /df log regions <name> [depth]  every region and child of a frame;
--                          with a depth, recurses into what is visible
--     /df log bars <name>  every status bar under a frame: bar colour, texture
--                          vertex colour, desaturation, alpha, lockColor
--     /df log blockers [name]  every frame taking mouse input over a frame's
--                          rectangle - for "something invisible is eating my
--                          clicks here". Defaults to the target frame's spot,
--                          and works with no target, since a hidden frame keeps
--                          its anchors
--     /df log tot          every term of the client's target-of-target show
--                          condition, plus the frame's own state, and a verdict
--     /df log tot watch    toggle a watcher that logs each time that changes
--     /df log party        every party/raid frame field that is tainted, and
--                          the addon that dirtied it. issecurevariable sees
--                          what taintLog cannot: taintLog records tainted
--                          globals, and these are tainted fields on frames the
--                          client owns. Run it after the party frames have
--                          misbehaved - the taint is sticky, so it is still
--                          there afterwards
--     /df log fonts        every shared font object's height, flags and path,
--                          plus the live text of a bag count, the chat box and a
--                          character tab. For "text sits low in its box in
--                          several addons at once", which is a font report and
--                          not a layout one - font objects are global, so one
--                          addon changing one changes it for everybody. Run it
--                          with the suspect addon on and again with it off, and
--                          diff
--     /df log screen       the display and the UI panel budget computed from it:
--                          UIParent's size in UI units, the panel offset
--                          constants, GetMaxUIPanelsWidth and the two
--                          CanShow...UIPanel tests. For "it only misbehaves on
--                          this monitor" - run it on both and diff
--     /df log watch [name] snapshot the frames that get re-anchored behind our
--                          back - keyring and bag slots, chat, micro menu, the
--                          managed action bars and unit frames, the character
--                          pane itself - plus the friend counts and the screen
--                          metrics above. Run it, reproduce the problem, run
--                          it again: the second run reports only what moved,
--                          names the frame it moved to, and opens the copy
--                          window on it - no reload, no hunting for a file. An
--                          optional name (or 'mouse') adds a frame the list
--                          does not cover
--     /df log watch reset  drop the baseline and start again
--     /df log bagtrace     log every SetPoint, Show and Hide on the bag row,
--                          backpack and keyring included, each with the combat
--                          state and the stack of whoever called it. watch says
--                          what moved; this says who moved it and whether the
--                          client was in a position to refuse us. 'off' stops
--                          it, 'copy' opens the window
--     /df log bagtrace state  the numbers the row is laid out from, without
--                          tracing: Blizzard's bagPadding and expand flags, our
--                          saved collapsed state, and each button's anchor,
--                          visibility and protected status. Run it before and
--                          after whatever breaks and compare the two
--     /df log raidopts     why the raid Edit Mode options are or are not in the
--                          config panel: whether Blizzard_EditMode is loaded,
--                          whether its setting display info exists, which frame
--                          the raid system resolves to, and per setting whether
--                          that frame has it and what value it holds
--     /df log <tag>        only entries carrying that tag, e.g.
--                          /df log error, /df log taint
--
-- frame, regions and bars all take 'mouse' instead of a name, for whatever is
-- under the cursor - handy when the frame's name is what you want to find out.
--
-- There is also a keybinding, under DragonflightUI > Debug: hover whatever looks
-- wrong, press the key, and the frame beneath the cursor is dumped and the copy
-- window opens on it. That exists because 'mouse' resolves when the command
-- runs, and reaching the chat box to type one moves the cursor off the thing
-- being reported.
--
-- The buffer is per session: it is reset on load, so the file on disk always
-- holds the session that just ended. Copy anything worth keeping before a
-- second /reload.
local MAX_ENTRIES = 1000

local log = {}
DragonflightUIDebugLog = log

-- SavedVariables load AFTER this file runs and would re-point the global at
-- the previous session's table; re-assert ours.
local loadFrame = CreateFrame('Frame')
loadFrame:RegisterEvent('ADDON_LOADED')
loadFrame:SetScript('OnEvent', function(self, _, name)
    if name == addonName then
        DragonflightUIDebugLog = log
        self:UnregisterAllEvents()
    end
end)

local echoToChat = false

-- last line written, so an identical one can be counted rather than repeated
local lastKey, lastIndex, lastCount
local PREFIX = '|cff0070ddDFUI log:|r '

-- Errors and taint blocks land here too, tagged 'error' and 'taint'. Taint
-- blocks are the important half: they never reach an error handler and are
-- invisible in combat, so an in-combat failure otherwise leaves no trace at
-- all. Read them back with /df log error or /df log taint.
local captureInstalled = false
local function InstallCapture()
    if captureInstalled then return end
    captureInstalled = true

    local origHandler = geterrorhandler()
    seterrorhandler(function(err)
        DF:Log('error', '%s | %s', tostring(err), tostring(debugstack(2, 12, 0)):gsub('\n', ' | '):sub(1, 900))
        return origHandler(err)
    end)

    local watcher = CreateFrame('Frame')
    watcher:RegisterEvent('ADDON_ACTION_BLOCKED')
    watcher:RegisterEvent('ADDON_ACTION_FORBIDDEN')
    -- Deeper and longer than the error capture on purpose. A taint block names
    -- the addon that tainted the execution, but what actually identifies the
    -- route is the BOTTOM of the stack - the frame where our code entered it -
    -- and twelve frames of Blizzard's scroll and layout machinery is enough to
    -- cut exactly that off. It did: a blocked C_Club.SetAvatarTexture arrived
    -- with everything above it and nothing below. Repeats are collapsed now, so
    -- the extra length costs nothing.
    watcher:SetScript('OnEvent', function(_, event, addon, func)
        DF:Log('taint', '%s: %s -> %s | %s', event, tostring(addon), tostring(func),
               tostring(debugstack(2, 20, 0)):gsub('\n', ' | '):sub(1, 1600))
    end)
end

function DF:Log(tag, msg, ...)
    local text
    if select('#', ...) > 0 then
        local ok, formatted = pcall(string.format, msg, ...)
        text = ok and formatted or (tostring(msg) .. ' <malformed log args>')
    else
        text = tostring(msg)
    end

    -- Collapse a line that repeats. One blocked call inside a list initializer
    -- fires once per row per refresh, so a single misbehaving frame can put
    -- dozens of byte-identical entries in here - and since the buffer is
    -- capped, they push out the ones that were actually wanted. That happened:
    -- a party-frame report came back with the party half nearly buried under
    -- repeats of an unrelated taint. Counting them keeps the evidence and the
    -- frequency, which is more than the copies were telling us anyway.
    local key = tostring(tag) .. '\0' .. text
    if key == lastKey and lastIndex and log[lastIndex] then
        lastCount = lastCount + 1
        log[lastIndex] = string.format('%7.2f [%s] %s  (x%d)', GetTime() % 100000, tostring(tag), text, lastCount)
        if echoToChat then print(PREFIX .. log[lastIndex]) end
        return log[lastIndex]
    end

    local entry = string.format('%7.2f [%s] %s', GetTime() % 100000, tostring(tag), text)

    if #log < MAX_ENTRIES then
        log[#log + 1] = entry
        lastKey, lastIndex, lastCount = key, #log, 1
    elseif not log.truncated then
        log.truncated = true
        log[MAX_ENTRIES] = '... log full, later entries dropped'
        lastKey, lastIndex, lastCount = nil, nil, nil
    end

    if echoToChat then print(PREFIX .. entry) end
    return entry
end

function DF:LogEcho(enabled)
    echoToChat = enabled and true or false
    print(PREFIX .. 'live echo ' .. (echoToChat and 'ON' or 'OFF'))
end

function DF:LogIsEchoing()
    return echoToChat
end

-- Why is this frame not on screen? Answers the whole question in one go: a
-- frame is only drawn when it is shown, every ancestor is shown, and the
-- effective alpha is non-zero - and it is only *seen* when it also sits on
-- screen and above whatever else is there.
function DF:LogFrame(frameOrName, tag)
    tag = tag or 'frame'

    local f = frameOrName
    if type(f) == 'string' then f = _G[f] end
    if type(f) ~= 'table' or not f.GetObjectType then
        DF:Log(tag, 'no such frame: %s', tostring(frameOrName))
        return
    end

    local name = (f.GetName and f:GetName()) or '<anonymous>'
    DF:Log(tag, '--- %s (%s) ---', name, f:GetObjectType())
    DF:Log(tag, 'shown=%s visible=%s alpha=%.2f effectiveAlpha=%.2f strata=%s level=%s', tostring(f:IsShown()),
           tostring(f:IsVisible()), f:GetAlpha() or -1, (f.GetEffectiveAlpha and f:GetEffectiveAlpha()) or -1,
           tostring(f.GetFrameStrata and f:GetFrameStrata()), tostring(f.GetFrameLevel and f:GetFrameLevel()))

    local w, h = f:GetWidth(), f:GetHeight()
    local left, bottom = f:GetLeft(), f:GetBottom()
    DF:Log(tag, 'size=%.0fx%.0f scale=%.2f effectiveScale=%.2f pos=%s,%s points=%d', w or -1, h or -1,
           (f.GetScale and f:GetScale()) or -1, (f.GetEffectiveScale and f:GetEffectiveScale()) or -1,
           left and string.format('%.0f', left) or 'nil', bottom and string.format('%.0f', bottom) or 'nil',
           (f.GetNumPoints and f:GetNumPoints()) or 0)

    for i = 1, ((f.GetNumPoints and f:GetNumPoints()) or 0) do
        local point, relativeTo, relativePoint, x, y = f:GetPoint(i)
        DF:Log(tag, 'point %d: %s -> %s %s (%.0f,%.0f)', i, tostring(point),
               (relativeTo and relativeTo.GetName and (relativeTo:GetName() or '<anonymous>')) or tostring(relativeTo),
               tostring(relativePoint), x or 0, y or 0)
    end

    -- On screen at all? A frame parked past the edge looks exactly like a
    -- frame that never showed.
    if left and bottom and w and h then
        local screenW, screenH = UIParent:GetWidth(), UIParent:GetHeight()
        local scale = (f.GetEffectiveScale and f:GetEffectiveScale()) or 1
        local uiScale = UIParent:GetEffectiveScale()
        local sLeft, sBottom = left * scale / uiScale, bottom * scale / uiScale
        local sRight, sTop = sLeft + w * scale / uiScale, sBottom + h * scale / uiScale
        local onScreen = sRight > 0 and sLeft < screenW and sTop > 0 and sBottom < screenH
        DF:Log(tag, 'screen rect %.0f,%.0f to %.0f,%.0f (screen %.0fx%.0f) onScreen=%s', sLeft, sBottom, sRight, sTop,
               screenW, screenH, tostring(onScreen))
    end

    -- Walk up: one hidden ancestor is enough to hide everything below it.
    local parent = f:GetParent()
    local depth = 0
    while parent and depth < 12 do
        depth = depth + 1
        DF:Log(tag, 'parent %d: %s shown=%s alpha=%.2f strata=%s', depth,
               (parent.GetName and (parent:GetName() or '<anonymous>')) or '?', tostring(parent:IsShown()),
               parent:GetAlpha() or -1, tostring(parent.GetFrameStrata and parent:GetFrameStrata()))
        parent = parent.GetParent and parent:GetParent()
    end
end

-- What is this frame actually made of? Lists every region and child with its
-- art, geometry and anchors - the fastest way to find the piece that is
-- stranded, unstyled, or wearing the wrong texture.
function DF:LogRegions(frameOrName, tag, maxDepth)
    tag = tag or 'regions'
    maxDepth = tonumber(maxDepth) or 0

    local f = frameOrName
    if type(f) == 'string' then f = _G[f] end
    if type(f) ~= 'table' or not f.GetObjectType then
        DF:Log(tag, 'no such frame: %s', tostring(frameOrName))
        return
    end

    local function describe(kind, index, obj, prefix)
        local objName = (obj.GetName and obj:GetName()) or '<anonymous>'
        local art = ''
        if obj.GetAtlas and obj:GetAtlas() then
            art = ' atlas=' .. obj:GetAtlas()
        elseif obj.GetTexture then
            local tex = obj:GetTexture()
            if tex then art = ' texture=' .. tostring(tex) end
        end

        local left, bottom = obj:GetLeft(), obj:GetBottom()
        DF:Log(tag, '%s%s %d: %s (%s) shown=%s %.0fx%.0f at %s,%s points=%d%s', prefix, kind, index, objName,
               obj:GetObjectType(), tostring(obj:IsShown()), obj:GetWidth() or -1, obj:GetHeight() or -1,
               left and string.format('%.0f', left) or 'UNANCHORED', bottom and string.format('%.0f', bottom) or '?',
               (obj.GetNumPoints and obj:GetNumPoints()) or 0, art)
    end

    -- Recursing lists only what is actually drawn: hunting for the one stray
    -- rectangle in a frame tree means looking for something VISIBLE, and the
    -- hidden half of the tree is noise that buries it.
    local function walk(frame, depth, prefix)
        DF:Log(tag, '%s=== %s: %d regions, %d children ===', prefix, (frame:GetName() or '<anonymous>'),
               select('#', frame:GetRegions()), select('#', frame:GetChildren()))

        for i, region in ipairs({frame:GetRegions()}) do
            if depth == 0 or region:IsShown() then describe('region', i, region, prefix) end
        end

        for i, child in ipairs({frame:GetChildren()}) do
            if depth == 0 or child:IsShown() then describe('child', i, child, prefix) end
        end

        if depth >= maxDepth then return end
        for _, child in ipairs({frame:GetChildren()}) do
            if child:IsShown() and child.GetRegions then walk(child, depth + 1, prefix .. '  ') end
        end
    end

    walk(f, 0, '')
end

-- Resolves a name, or 'mouse' for whatever is under the cursor - the quickest
-- way to point the log at a frame whose name you do not know.
local function ResolveFrame(nameOrMouse)
    if type(nameOrMouse) ~= 'string' then return nameOrMouse end

    if nameOrMouse:lower() ~= 'mouse' then return _G[nameOrMouse] end

    local focus
    if GetMouseFoci then
        local foci = GetMouseFoci()
        focus = foci and foci[1]
    elseif GetMouseFocus then
        focus = GetMouseFocus()
    end
    return focus
end

-- Why does this bar look wrong? A status bar's colour comes from three places
-- that can each mute it - the bar colour, the texture's own vertex colour, and
-- desaturation - on top of the alpha chain. Dumps all of them for every bar
-- under a frame.
function DF:LogBars(frameOrName, tag, maxDepth)
    tag = tag or 'bars'
    maxDepth = tonumber(maxDepth) or 3

    local f = ResolveFrame(frameOrName)
    if type(f) ~= 'table' or not f.GetObjectType then
        DF:Log(tag, 'no such frame: %s', tostring(frameOrName))
        return
    end

    DF:Log(tag, '=== bars under %s ===', (f.GetName and f:GetName()) or '<anonymous>')

    local function describe(bar, prefix)
        local tex = bar:GetStatusBarTexture()
        local r, g, b, a = bar:GetStatusBarColor()
        local tr, tg, tb, ta = 1, 1, 1, 1
        if tex and tex.GetVertexColor then tr, tg, tb, ta = tex:GetVertexColor() end

        DF:Log(tag, '%s%s: barColor=%.2f/%.2f/%.2f/%.2f texVertex=%.2f/%.2f/%.2f/%.2f', prefix,
               (bar.GetName and bar:GetName()) or '<anonymous>', r or -1, g or -1, b or -1, a or -1, tr, tg, tb, ta)
        DF:Log(tag, '%s  desaturated=%s/%s alpha=%.2f effAlpha=%.2f lockColor=%s shown=%s', prefix,
               tostring(tex and tex.IsDesaturated and tex:IsDesaturated()),
               tostring(bar.IsStatusBarDesaturated and bar:IsStatusBarDesaturated()), bar:GetAlpha() or -1,
               (bar.GetEffectiveAlpha and bar:GetEffectiveAlpha()) or -1, tostring(bar.lockColor),
               tostring(bar:IsShown()))
        DF:Log(tag, '%s  texture=%s', prefix, tostring(tex and tex.GetTexture and tex:GetTexture()))
    end

    local function walk(frame, depth, prefix)
        if frame:GetObjectType() == 'StatusBar' then describe(frame, prefix) end
        if depth >= maxDepth then return end

        for _, child in ipairs({frame:GetChildren()}) do
            if child.GetObjectType then walk(child, depth + 1, prefix .. '  ') end
        end
    end

    walk(f, 0, '')

    -- the unit behind it, so a deliberately dimmed offline member is not
    -- mistaken for a styling bug
    local unit = f.unit or f.unitToken
    if unit and UnitExists(unit) then
        DF:Log(tag, 'unit=%s name=%s connected=%s dead=%s', unit, tostring(UnitName(unit)),
               tostring(UnitIsConnected(unit)), tostring(UnitIsDeadOrGhost(unit)))
    end
end

-- A frame's rectangle in UIParent coordinates, or nil if it has no position.
-- Frames keep their anchors while hidden, so this answers "where would it be"
-- as well as "where is it" - which is the whole point when the complaint is
-- about the empty space a hidden frame leaves behind.
local function ScreenRect(f)
    if not (f and f.GetLeft) then return nil end
    local left, bottom, w, h = f:GetLeft(), f:GetBottom(), f:GetWidth(), f:GetHeight()
    if not (left and bottom and w and h) then return nil end
    local k = ((f.GetEffectiveScale and f:GetEffectiveScale()) or 1) / UIParent:GetEffectiveScale()
    return left * k, bottom * k, (left + w) * k, (bottom + h) * k
end

-- What is eating the mouse over this rectangle?
--
-- "There is an invisible frame here" is not something hovering can answer: the
-- capture keybinding returns whatever the client decides is under the cursor,
-- which is the blocker only when the blocker also happens to be the top hit.
-- This asks the opposite question - of every frame in the UI, which ones are
-- drawn, take mouse input, and overlap this spot - and reports them in the
-- order the client would consider them.
--
-- A frame only steals a right-click-drag from the camera if it takes CLICKS.
-- Motion-only frames (tooltips, hover regions) are listed but marked, because
-- they are innocent of this particular crime.
function DF:LogBlockers(frameOrName, tag)
    tag = tag or 'blockers'

    local anchorFrame = ResolveFrame(frameOrName)
    if type(anchorFrame) ~= 'table' or not anchorFrame.GetObjectType then
        anchorFrame = TargetFrame
    end
    if not anchorFrame then
        DF:Log(tag, 'no frame to measure against')
        return
    end

    local aLeft, aBottom, aRight, aTop = ScreenRect(anchorFrame)
    if not aLeft then
        -- an unanchored holder still tells us nothing; fall back to the one
        -- frame that always keeps its points
        anchorFrame = _G['DragonflightUITargetFrame'] or anchorFrame
        aLeft, aBottom, aRight, aTop = ScreenRect(anchorFrame)
    end
    if not aLeft then
        DF:Log(tag, '%s has no position to test', (anchorFrame:GetName() or '<anonymous>'))
        return
    end

    DF:Log(tag, '=== frames taking mouse input over %s (%.0f,%.0f to %.0f,%.0f) ===',
           (anchorFrame:GetName() or '<anonymous>'), aLeft, aBottom, aRight, aTop)
    DF:Log(tag, 'anchor shown=%s visible=%s  target exists=%s', tostring(anchorFrame:IsShown()),
           tostring(anchorFrame:IsVisible()), tostring(UnitExists('target')))

    local found = {}
    local frame = EnumerateFrames()
    while frame do
        if frame ~= UIParent and frame ~= WorldFrame and frame.IsVisible and frame:IsVisible() and frame.IsMouseEnabled and
            frame:IsMouseEnabled() then
            local ok, l, b, r, t = pcall(ScreenRect, frame)
            if ok and l and l < aRight and r > aLeft and b < aTop and t > aBottom then
                found[#found + 1] = frame
            end
        end
        frame = EnumerateFrames(frame)
    end

    if #found == 0 then
        DF:Log(tag, 'nothing mouse-enabled overlaps it - the block is not a frame of ours')
        return
    end

    for i, f in ipairs(found) do
        if i > 40 then
            DF:Log(tag, '... %d more, listing stopped', #found - 40)
            break
        end

        -- IsMouseClickEnabled is the modern split; on clients without it,
        -- IsMouseEnabled covered both and the frame takes clicks.
        local takesClicks = (f.IsMouseClickEnabled and f:IsMouseClickEnabled()) or (not f.IsMouseClickEnabled)
        local propagates = f.GetPropagateMouseClicks and f:GetPropagateMouseClicks()
        local l, b, r, t = ScreenRect(f)

        DF:Log(tag, '%s%s (%s) strata=%s level=%s clicks=%s propagates=%s alpha=%.2f rect %.0f,%.0f to %.0f,%.0f',
               (takesClicks and not propagates) and '|cffff2020BLOCKS|r ' or '', (f:GetName() or '<anonymous>'),
               f:GetObjectType(), tostring(f:GetFrameStrata()), tostring(f:GetFrameLevel()), tostring(takesClicks),
               tostring(propagates), (f.GetEffectiveAlpha and f:GetEffectiveAlpha()) or -1, l, b, r, t)

        local parent = f:GetParent()
        DF:Log(tag, '    parent=%s', (parent and parent.GetName and (parent:GetName() or '<anonymous>')) or 'none')
    end
end

-- Every term of the client's own target-of-target show condition, plus what
-- the frame is actually doing.
--
-- Blizzard's TargetOfTargetMixin:Update shows the frame when the CVar is on,
-- the target exists, the target's target exists, the target is not the player,
-- and the target is alive - and TargetFrameMixin:OnUpdate re-runs that check
-- every frame, so a missing ToT means either one of those terms is false or
-- something is hiding, unanchoring or blanking the frame after the fact. This
-- prints both halves so the answer is in the paste rather than in a guess.
function DF:LogToT(tag)
    tag = tag or 'tot'

    local tot = (TargetFrame and TargetFrame.totFrame) or _G['TargetFrameToT']
    if not tot then
        DF:Log(tag, 'no ToT frame exists at all (TargetFrame.totFrame is nil)')
        return
    end

    local cvar
    if CVarCallbackRegistry and CVarCallbackRegistry.GetCVarValueBool then
        cvar = CVarCallbackRegistry:GetCVarValueBool('showTargetOfTarget')
    else
        cvar = GetCVarBool('showTargetOfTarget')
    end
    -- the cached read above is what the client actually tests; the raw one
    -- catches a cache that has gone stale behind it
    local rawCVar = GetCVar('showTargetOfTarget')

    local unit = tot.unit or 'targettarget'
    local targetExists = UnitExists('target') and true or false
    local totExists = UnitExists(unit) and true or false
    local targetIsPlayer = (PlayerFrame and PlayerFrame.unit and UnitIsUnit(PlayerFrame.unit, 'target')) and true or false
    local alive = (UnitHealth('target') or 0) > 0

    local expected = (cvar and targetExists and totExists and not targetIsPlayer and alive) and true or false

    DF:Log(tag, '=== target-of-target ===')
    DF:Log(tag, 'cvar=%s (raw "%s")  targetExists=%s  totExists=%s (unit=%s, name=%s)  targetIsSelf=%s  targetAlive=%s',
           tostring(cvar), tostring(rawCVar), tostring(targetExists), tostring(totExists), tostring(unit),
           tostring(UnitName(unit)), tostring(targetIsPlayer), tostring(alive))
    DF:Log(tag, 'client should show it: %s   frame shown=%s visible=%s', tostring(expected), tostring(tot:IsShown()),
           tostring(tot:IsVisible()))

    -- is the safety net still installed? TargetFrameMixin:OnUpdate is what
    -- re-shows the ToT every frame; if something replaced that script rather
    -- than hooking it, nothing self-heals
    DF:Log(tag, 'TargetFrame OnUpdate installed=%s   ToT OnUpdate installed=%s',
           tostring((TargetFrame and TargetFrame:GetScript('OnUpdate')) ~= nil),
           tostring(tot:GetScript('OnUpdate') ~= nil))

    DF:LogFrame(tot, tag)

    if not expected then
        DF:Log(tag, 'VERDICT: the client is deliberately hiding it - see which term above is false')
    elseif not tot:IsShown() then
        DF:Log(tag, 'VERDICT: should be shown and is not. Something hid it, or Update() is erroring - check /df log error')
    elseif not tot:IsVisible() then
        DF:Log(tag, 'VERDICT: shown, but an ancestor is hidden - see the parent chain above')
    elseif tot:GetNumPoints() == 0 then
        DF:Log(tag, 'VERDICT: shown and visible but has NO anchor points - a SetPoint was refused, so it draws nowhere')
    elseif ((tot.GetEffectiveAlpha and tot:GetEffectiveAlpha()) or 1) < 0.05 then
        DF:Log(tag, 'VERDICT: shown and visible but transparent')
    else
        DF:Log(tag, 'VERDICT: the frame is up and drawable - if it is not on screen, check the screen rect above')
    end
end

-- Arms a watcher that logs the moment any of those terms - or the frame's own
-- state - changes. The reporter plays until it breaks; the transition that
-- broke it is the last line.
local totWatcher, totLast
function DF:LogToTWatch(on)
    if not on then
        if totWatcher then
            totWatcher:Cancel()
            totWatcher = nil
        end
        totLast = nil
        print(PREFIX .. 'ToT watch OFF')
        return
    end

    if totWatcher then return end
    totLast = nil

    totWatcher = C_Timer.NewTicker(0.2, function()
        local tot = (TargetFrame and TargetFrame.totFrame) or _G['TargetFrameToT']
        if not tot then return end

        local cvar = (CVarCallbackRegistry and CVarCallbackRegistry.GetCVarValueBool) and
                         CVarCallbackRegistry:GetCVarValueBool('showTargetOfTarget') or GetCVarBool('showTargetOfTarget')
        local unit = tot.unit or 'targettarget'
        local expected = (cvar and UnitExists('target') and UnitExists(unit) and
                             not (PlayerFrame and PlayerFrame.unit and UnitIsUnit(PlayerFrame.unit, 'target')) and
                             (UnitHealth('target') or 0) > 0) and true or false

        local key = string.format('%s|%s|%s|%d|%.2f', tostring(expected), tostring(tot:IsShown()),
                                  tostring(tot:IsVisible()), tot:GetNumPoints(),
                                  (tot.GetEffectiveAlpha and tot:GetEffectiveAlpha()) or 1)

        if key ~= totLast then
            totLast = key
            DF:Log('totwatch', 'expected=%s shown=%s visible=%s points=%d alpha=%.2f | target=%s totUnit=%s',
                   tostring(expected), tostring(tot:IsShown()), tostring(tot:IsVisible()), tot:GetNumPoints(),
                   (tot.GetEffectiveAlpha and tot:GetEffectiveAlpha()) or 1, tostring(UnitName('target')),
                   tostring(UnitName(unit)))
        end
    end)

    print(PREFIX .. 'ToT watch ON - play until it breaks, then /df log copy totwatch')
end

-- /df log watch - snapshot now, reproduce, snapshot again, read what moved.
--
-- Three open reports all come down to "something re-anchored my frame and I do
-- not know what": the keyring landing over a bag slot after opening and closing
-- the bags, the chat window jumping after the settings window has been open,
-- and a friends count reading 0. Asking each reporter to describe positions
-- does not answer any of them, and asking for a separate dump per report is
-- three round trips. This takes one.
--
-- The frames are grouped by the report they belong to, so a dump stays readable
-- when only one of them is interesting.
local WATCH_GROUPS = {
    {
        label = 'keyring',
        frames = {'KeyRingButton', 'MainMenuBarBackpackButton', 'CharacterBag0Slot', 'CharacterBag1Slot',
                  'CharacterBag2Slot', 'CharacterBag3Slot', 'DragonflightUIBagBar'}
    }, {
        label = 'chat',
        frames = {'ChatFrame1', 'ChatFrame1Tab', 'ChatFrame1EditBox', 'GeneralDockManager',
                  'DragonflightUIChatFrame'}
    }, {label = 'micromenu', frames = {'MicroMenuContainer', 'MicroMenu', 'SocialsMicroButton', 'QuickJoinToastButton'}},
    -- Opening a UI panel runs the whole panel manager, and Classic's
    -- UIParentPanelManagerOverrides re-anchors these five by name on every run
    -- (its gate is IsShown() and IsInDefaultPosition()). Anything an addon has
    -- hung off them travels with them, which is what "everything shifted and
    -- came back when I closed it" looks like from the outside.
    {
        label = 'bars',
        frames = {'MainMenuBar', 'MultiBarBottomLeft', 'MultiBarBottomRight', 'MultiBarLeft', 'MultiBarRight',
                  'StanceBar', 'PetActionBar', 'PossessActionBar', 'MainMenuBarVehicleLeaveButton',
                  'MainStatusTrackingBarContainer', 'SecondaryStatusTrackingBarContainer',
                  'UIParentBottomManagedFrameContainer', 'UIParentRightManagedFrameContainer'}
    }, {
        label = 'units',
        frames = {'PlayerFrame', 'TargetFrame', 'TargetFrameToT', 'PetFrame', 'FocusFrame', 'BuffFrame',
                  'DebuffFrame', 'MinimapCluster', 'Minimap'}
    }, {
        -- The panel itself and the pieces DFUI adds to it: a shift that lives
        -- inside the window is a different bug from a shift of the window.
        label = 'panel',
        frames = {'UIParent', 'CharacterFrame', 'PaperDollFrame', 'CharacterFrameInset',
                  'DragonflightUICharacterFrameInset', 'DragonflightUICharacterFrameInsetRight',
                  'CharacterModelFrame', 'PaperDollItemsFrame', 'CharacterFrameTab1', 'CharacterFrameTab2',
                  'DressUpFrame', 'DressUpModel', 'AuctionFrame'}
    }
}

-- Everything about a frame that a re-anchor would change. Points are the point
-- of it: "who moved it" is answered by relativeTo changing, not by the pixels.
local function SnapshotFrame(f)
    if type(f) ~= 'table' or not f.GetObjectType then return nil end

    local snap = {
        shown = tostring(f:IsShown()),
        visible = tostring(f:IsVisible()),
        alpha = string.format('%.2f', f:GetAlpha() or -1),
        scale = string.format('%.2f', (f.GetScale and f:GetScale()) or -1),
        strata = tostring(f.GetFrameStrata and f:GetFrameStrata()),
        level = tostring(f.GetFrameLevel and f:GetFrameLevel()),
        parent = (f.GetParent and f:GetParent() and f:GetParent().GetName and (f:GetParent():GetName() or '<anon>')) or
            'nil',
        size = string.format('%.0fx%.0f', f:GetWidth() or -1, f:GetHeight() or -1),
        points = {}
    }

    -- Positions in UIParent's coordinates, not the frame's own. GetLeft returns
    -- a number in the frame's own space, so two frames at different effective
    -- scales report positions that cannot be compared with each other - a bag
    -- slot at "1216" and the button it is anchored to at "839" look like a bug
    -- and are not one. Scaling both to UIParent makes the numbers mean the same
    -- thing, and makes a scale change show up as the shift it actually is.
    local left, bottom = f:GetLeft(), f:GetBottom()
    local k = ((f.GetEffectiveScale and f:GetEffectiveScale()) or 1) / UIParent:GetEffectiveScale()
    snap.pos = (left and bottom) and string.format('%.0f,%.0f', left * k, bottom * k) or 'unplaced'

    for i = 1, ((f.GetNumPoints and f:GetNumPoints()) or 0) do
        local point, relativeTo, relativePoint, x, y = f:GetPoint(i)
        snap.points[i] = string.format('%s -> %s %s (%.0f,%.0f)', tostring(point),
                                       (relativeTo and relativeTo.GetName and (relativeTo:GetName() or '<anon>')) or
                                           tostring(relativeTo), tostring(relativePoint), x or 0, y or 0)
    end

    return snap
end

local function DiffSnapshots(tag, name, before, after)
    if not before and not after then return false end

    if not before then
        DF:Log(tag, '%s: APPEARED', name)
        return true
    end
    if not after then
        DF:Log(tag, '%s: GONE', name)
        return true
    end

    local changed = false
    for _, key in ipairs({'shown', 'visible', 'alpha', 'scale', 'strata', 'level', 'parent', 'size', 'pos'}) do
        if before[key] ~= after[key] then
            DF:Log(tag, '%s: %s %s => %s', name, key, tostring(before[key]), tostring(after[key]))
            changed = true
        end
    end

    local most = math.max(#before.points, #after.points)
    for i = 1, most do
        if before.points[i] ~= after.points[i] then
            DF:Log(tag, '%s: point%d %s => %s', name, i, tostring(before.points[i]) or 'none',
                   tostring(after.points[i]) or 'none')
            changed = true
        end
    end

    return changed
end

-- The friends count, from the API rather than from the screen. Answers the one
-- question the screenshot cannot: whether the client itself thinks 0, or
-- whether something is failing to draw a number it does have.
local function LogFriendFacts(tag)
    local parts = {}

    if C_FriendList and C_FriendList.GetNumFriends then
        parts[#parts + 1] = 'friends=' .. tostring(C_FriendList.GetNumFriends())
    end
    if C_FriendList and C_FriendList.GetNumOnlineFriends then
        parts[#parts + 1] = 'online=' .. tostring(C_FriendList.GetNumOnlineFriends())
    end
    if BNGetNumFriends then
        local total, numOnline = BNGetNumFriends()
        parts[#parts + 1] = 'bnet=' .. tostring(total) .. '/' .. tostring(numOnline) .. ' online'
    end
    if C_Club and C_Club.GetSubscribedClubs then
        local ok, clubs = pcall(C_Club.GetSubscribedClubs)
        if ok and clubs then parts[#parts + 1] = 'clubs=' .. tostring(#clubs) end
    end

    DF:Log(tag, 'friend counts: %s', (#parts > 0 and table.concat(parts, ' ')) or 'no API available')
end

-- /df log fonts - the shared font objects, and the live text that uses them.
--
-- "Text sits low inside its box, in frames belonging to addons that have
-- nothing to do with each other" is not a layout report, it is a font report.
-- Every one of those fontstrings is anchored to a point and grows from it, so
-- if the height behind the font object changes, text overflows its container
-- and appears to have moved - in every addon at once, without anything being
-- re-anchored. That is the one mechanism that explains a symptom crossing addon
-- boundaries while a full frame-position sweep reports nothing moved.
--
-- Font objects are global and shared, so whoever changes one changes it for
-- everybody. Run this with the suspect addon on and again with it off: any line
-- that differs names the culprit's effect directly.
--
-- The live fontstrings at the end are the three the reports actually name - a
-- bag stack count, the chat edit box, a character tab. A fontstring can carry
-- its own font instead of a font object's, so the object being clean does not
-- prove the text is.
function DF:LogFonts(tag)
    tag = tag or 'fonts'

    local function describeFont(label, obj)
        if type(obj) ~= 'table' or not obj.GetFont then
            DF:Log(tag, '%s: absent', label)
            return
        end

        local ok, path, height, flags = pcall(obj.GetFont, obj)
        if not ok then
            DF:Log(tag, '%s: GetFont failed', label)
            return
        end

        local extra = {}
        if obj.GetSpacing then
            local okS, spacing = pcall(obj.GetSpacing, obj)
            if okS and spacing and spacing ~= 0 then extra[#extra + 1] = 'spacing=' .. tostring(spacing) end
        end
        if obj.GetShadowOffset then
            local okO, sx, sy = pcall(obj.GetShadowOffset, obj)
            if okO and sx and (sx ~= 0 or sy ~= 0) then
                extra[#extra + 1] = string.format('shadow=%.1f,%.1f', sx, sy or 0)
            end
        end
        if obj.GetJustifyV then
            local okJ, jv = pcall(obj.GetJustifyV, obj)
            if okJ and jv then extra[#extra + 1] = 'justifyV=' .. tostring(jv) end
        end

        -- The path is the long half and the least interesting when it has not
        -- changed, so it goes last.
        DF:Log(tag, '%s: height=%s flags=%s %s | %s', label, tostring(height), tostring(flags),
               table.concat(extra, ' '), tostring(path))
    end

    -- The globals that carry a font path around as a plain string. An addon
    -- reassigning one of these changes every later SetFont that reads it.
    for _, name in ipairs({'STANDARD_TEXT_FONT', 'UNIT_NAME_FONT', 'DAMAGE_TEXT_FONT', 'NAMEPLATE_FONT'}) do
        DF:Log(tag, 'global %s = %s', name, tostring(_G[name]))
    end

    -- Chosen for what the reports name: tab labels and most panel text are the
    -- GameFont family, item stack counts are NumberFont, the chat box is
    -- ChatFontNormal.
    for _, name in ipairs({'GameFontNormal', 'GameFontNormalSmall', 'GameFontNormalLarge', 'GameFontHighlight',
                           'GameFontHighlightSmall', 'NumberFontNormal', 'NumberFontNormalSmall',
                           'NumberFontNormalLarge', 'NumberFontNormalYellow', 'ChatFontNormal', 'QuestFont',
                           'SystemFont_Shadow_Med1', 'GameTooltipText', 'ItemTextFontNormal'}) do
        describeFont('object ' .. name, _G[name])
    end

    -- And the live text, which is what is actually on screen.
    local live = {
        {'bag slot count', ContainerFrame1 and _G['ContainerFrame1Item1'] and _G['ContainerFrame1Item1'].Count},
        {'chat edit box', _G['ChatFrame1EditBox']},
        {'character tab 1', _G['CharacterFrameTab1'] and (_G['CharacterFrameTab1'].Text or _G['CharacterFrameTab1Text'])},
        {'action button 1 count', _G['ActionButton1'] and _G['ActionButton1'].Count}
    }
    for _, entry in ipairs(live) do
        local label, obj = entry[1], entry[2]
        if obj then
            describeFont('live ' .. label, obj)
            if obj.GetNumPoints then
                for i = 1, (obj:GetNumPoints() or 0) do
                    local point, relativeTo, relativePoint, x, y = obj:GetPoint(i)
                    DF:Log(tag, '   %s point%d: %s -> %s %s (%.1f,%.1f)', label, i, tostring(point),
                           (relativeTo and relativeTo.GetName and (relativeTo:GetName() or '<anon>')) or
                               tostring(relativeTo), tostring(relativePoint), x or 0, y or 0)
                end
            end
            if obj.GetHeight then
                DF:Log(tag, '   %s box: %.1fx%.1f', label, obj:GetWidth() or -1, obj:GetHeight() or -1)
            end
        else
            DF:Log(tag, 'live %s: not present (open it first)', label)
        end
    end
end

-- /df log screen - the numbers the UI panel layout is computed from.
--
-- "It only does this on my laptop" is a claim about one thing: the size of
-- UIParent in UI units. The client's panel budget is a set of fixed constants
-- (LEFT_OFFSET, DEFAULT_FRAME_WIDTH, RIGHT_OFFSET_BUFFER) measured against
-- UIParent:GetRight(), and that is the only term in the whole calculation that
-- changes with the display. A 16:10 laptop panel is ~180 UI units narrower than
-- a 16:9 monitor at the same height, so a panel arrangement that fits on one
-- can fail CanShowRightUIPanel/CanShowCenterUIPanel on the other - and a panel
-- that cannot be shown where it belongs makes the manager close or re-place
-- other panels instead, on every open and again on every close.
--
-- So this dumps both halves: what the display is, and what the panel manager
-- currently thinks it can afford. Run it on both machines and diff.
function DF:LogScreen(tag)
    tag = tag or 'screen'

    local function num(v) return type(v) == 'number' and string.format('%.1f', v) or tostring(v) end

    -- Blizzard's own GetUIPanelAttribute is a local in
    -- Blizzard_UIParentPanelManager and cannot be called from here. This is the
    -- reading half of it: the live attribute if the frame has been defined,
    -- otherwise the UIPanelWindows entry it would have been defined from. The
    -- writing half is deliberately not reproduced - stamping UIPanelLayout
    -- attributes onto a Blizzard panel from addon code is how that panel's
    -- placement ends up tainted.
    local function panelAttr(frame, name)
        local live = frame:GetAttribute('UIPanelLayout-' .. name)
        if live ~= nil then return live end
        local entry = UIPanelWindows and frame.GetName and frame:GetName() and UIPanelWindows[frame:GetName()]
        return entry and entry[name]
    end

    local w, h = GetScreenWidth(), GetScreenHeight()
    DF:Log(tag, 'screen: %s x %s UI units (aspect %.3f)', num(w), num(h), (h and h ~= 0) and (w / h) or 0)

    if GetPhysicalScreenSize then
        local pw, ph = GetPhysicalScreenSize()
        DF:Log(tag, 'physical: %s x %s px', num(pw), num(ph))
    end

    DF:Log(tag, 'UIParent: size %sx%s scale %.4f effective %.4f right %s top %s', num(UIParent:GetWidth()),
           num(UIParent:GetHeight()), UIParent:GetScale(), UIParent:GetEffectiveScale(), num(UIParent:GetRight()),
           num(UIParent:GetTop()))

    if GetCVar then
        DF:Log(tag, 'cvars: uiScale=%s useUiScale=%s gxMaximize=%s gxWindow=%s', tostring(GetCVar('uiScale')),
               tostring(GetCVar('useUiScale')), tostring(GetCVar('gxMaximize')), tostring(GetCVar('gxWindow')))
    end

    -- The constants, read from UIParent rather than hardcoded here: they are
    -- per-flavour XML attributes and this addon runs on several.
    local attrs = {}
    for _, key in ipairs({'TOP_OFFSET', 'LEFT_OFFSET', 'CENTER_OFFSET', 'RIGHT_OFFSET', 'RIGHT_OFFSET_BUFFER',
                          'DEFAULT_FRAME_WIDTH', 'PANEl_SPACING_X'}) do
        attrs[#attrs + 1] = key .. '=' .. tostring(UIParent:GetAttribute(key))
    end
    DF:Log(tag, 'panel budget: %s', table.concat(attrs, ' '))

    local maxWidth = GetMaxUIPanelsWidth and GetMaxUIPanelsWidth()
    DF:Log(tag, 'GetMaxUIPanelsWidth: %s (UIParent right %s minus buffer)', num(maxWidth), num(UIParent:GetRight()))

    -- What is open, and how wide the manager thinks each one is. GetUIPanelWidth
    -- reads the UIPanelLayout-width attribute in preference to the real width,
    -- so a window that resizes itself - the character pane does, per tab - is
    -- budgeted at whatever it last declared, not at what it looks like.
    for _, key in ipairs({'left', 'center', 'right', 'doublewide', 'fullscreen'}) do
        local frame = GetUIPanel and GetUIPanel(key)
        if frame then
            local name = (frame.GetName and frame:GetName()) or '<anon>'
            DF:Log(tag, 'panel %s: %s real %s wide, declared %s, scale %.2f, xoffset %s, area %s', key, name,
                   num(frame:GetWidth()), tostring(panelAttr(frame, 'width')), frame:GetScale(),
                   tostring(panelAttr(frame, 'xoffset')), tostring(panelAttr(frame, 'area')))
        else
            DF:Log(tag, 'panel %s: -', key)
        end
    end

    -- The two tests that decide whether the manager places a panel or starts
    -- evicting other ones. Asked about a default-width panel, because that is
    -- the question the manager asks when it has no frame yet.
    if CanShowCenterUIPanel then
        DF:Log(tag, 'CanShowCenterUIPanel(default): %s', tostring(CanShowCenterUIPanel(nil)))
    end
    if CanShowRightUIPanel then
        DF:Log(tag, 'CanShowRightUIPanel(default): %s', tostring(CanShowRightUIPanel(nil)))
    end
end

local watchBaseline

function DF:LogWatch(extraName)
    local tag = 'watch'
    local taking = {}
    local seenName = {}

    for _, group in ipairs(WATCH_GROUPS) do
        for _, name in ipairs(group.frames) do
            if not seenName[name] then
                seenName[name] = true
                taking[#taking + 1] = {label = group.label, name = name}
            end
        end
    end

    -- Then every named frame parented to UIParent, whoever created it.
    --
    -- A named list only finds what it was told to look for, and "my whole UI
    -- shifts, in several addons at once, and shifts back" is a report about
    -- frames this addon has never heard of. Sweeping UIParent's children costs
    -- nothing to snapshot and catches all of them; they are marked quiet so the
    -- baseline stays readable, and they only ever appear in the diff - which is
    -- the half that answers the question.
    --
    -- Forbidden frames are skipped rather than guarded: touching one from addon
    -- code raises, and the panel manager's own delegate is exactly such a frame.
    local swept = 0
    for _, child in ipairs({UIParent:GetChildren()}) do
        local ok, forbidden = pcall(function() return child.IsForbidden and child:IsForbidden() end)
        if ok and not forbidden then
            local name = child.GetName and child:GetName()
            if name and not seenName[name] then
                seenName[name] = true
                taking[#taking + 1] = {label = 'sweep', name = name, frame = child, quiet = true}
                swept = swept + 1
            end
        end
    end

    -- An extra frame for whatever the report is about that this list does not
    -- already cover - '/df log watch mouse' while hovering it.
    if extraName and extraName ~= '' then
        local resolved = ResolveFrame(extraName)
        local resolvedName = (type(resolved) == 'table' and resolved.GetName and resolved:GetName()) or extraName
        taking[#taking + 1] = {label = 'extra', name = resolvedName, frame = resolved}
    end

    local snapshot = {}
    for _, entry in ipairs(taking) do
        local f = entry.frame or _G[entry.name]
        snapshot[entry.label .. '/' .. entry.name] = SnapshotFrame(f)
    end

    LogFriendFacts(tag)

    -- Under the same tag, so the copy window carries it: half of what moves a
    -- frame behind our back is the panel manager, and what the panel manager
    -- does depends entirely on how wide this display is.
    DF:LogScreen(tag)

    if not watchBaseline then
        watchBaseline = snapshot

        local present, absent = 0, {}
        for _, entry in ipairs(taking) do
            local key = entry.label .. '/' .. entry.name
            if snapshot[key] then
                present = present + 1
                if not entry.quiet then
                    DF:Log(tag, 'baseline %s: %s | %s | shown=%s parent=%s', key, snapshot[key].pos,
                           snapshot[key].size, snapshot[key].shown, snapshot[key].parent)
                    for i, p in ipairs(snapshot[key].points) do DF:Log(tag, '   point%d %s', i, p) end
                end
            elseif not entry.quiet then
                absent[#absent + 1] = entry.name
            end
        end

        DF:Log(tag, 'baseline taken: %d frames (%d swept from UIParent), %d absent (%s)', present, swept, #absent,
               (#absent > 0 and table.concat(absent, ', ')) or 'none')
        -- No window on this run: there is nothing to report yet, and popping one
        -- up before the problem has been reproduced invites sending it early.
        print(PREFIX .. 'baseline taken. Now reproduce the problem, then run /df log watch again.')
        return
    end

    local changed = 0
    for key, after in pairs(snapshot) do
        if DiffSnapshots(tag, key, watchBaseline[key], after) then changed = changed + 1 end
    end
    for key, before in pairs(watchBaseline) do
        if snapshot[key] == nil and before ~= nil then
            DF:Log(tag, '%s: GONE', key)
            changed = changed + 1
        end
    end

    DF:Log(tag, '=== %d frame(s) changed since the baseline ===', changed)
    watchBaseline = snapshot

    -- Open the copy window rather than asking for the SavedVariables file. The
    -- log is only written on /reload or logout, so the old instructions were
    -- "reproduce it, reload, go and find a file" - three chances to lose the
    -- capture, and a reload is itself a layout application, which is one of the
    -- things being investigated. Selecting text out of a window is one step and
    -- disturbs nothing.
    --
    -- Filtered to the watch tag, which includes the baseline: the anchors a
    -- frame started with are half of what makes the diff mean anything. If that
    -- overruns the window's limit it keeps the tail, so the diff survives and
    -- the baseline is what gets dropped - the right way round.
    print(PREFIX .. changed .. ' frame(s) changed - copy the window and paste it into the report.')
    DF:LogCopy(tag)
end

-- Start over without a reload, for a reporter who wants a second attempt at the
-- same thing.
function DF:LogWatchReset()
    watchBaseline = nil
    print(PREFIX .. 'watch baseline cleared - the next /df log watch takes a fresh one.')
end

local function Matching(filter)
    local matching = {}
    for _, entry in ipairs(log) do
        if not filter or entry:lower():find(filter:lower(), 1, true) then matching[#matching + 1] = entry end
    end
    return matching
end

-- A window to copy the log out of, because the alternative is talking someone
-- through finding a file inside their WoW install. Select all, copy, paste it
-- into a bug report.
local copyFrame

local function CreateCopyWindow()
    if copyFrame then return copyFrame end

    local f = CreateFrame('Frame', 'DragonflightUILogCopyFrame', UIParent, 'BackdropTemplate')
    f:SetSize(700, 500)
    f:SetPoint('CENTER')
    f:SetFrameStrata('DIALOG')
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag('LeftButton')
    f:SetScript('OnDragStart', f.StartMoving)
    f:SetScript('OnDragStop', f.StopMovingOrSizing)
    f:SetClampedToScreen(true)
    f:Hide()

    f:SetBackdrop({
        bgFile = 'Interface\\DialogFrame\\UI-DialogBox-Background-Dark',
        edgeFile = 'Interface\\DialogFrame\\UI-DialogBox-Border',
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = {left = 11, right = 12, top = 12, bottom = 11}
    })

    local title = f:CreateFontString(nil, 'OVERLAY', 'GameFontNormalLarge')
    title:SetPoint('TOP', f, 'TOP', 0, -18)
    title:SetText('DragonflightUI debug log')

    local hint = f:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
    hint:SetPoint('TOP', title, 'BOTTOM', 0, -4)
    hint:SetText('|cffffd100Ctrl+A|r to select all, |cffffd100Ctrl+C|r to copy, then paste it into your bug report.')

    local close = CreateFrame('Button', nil, f, 'UIPanelButtonTemplate')
    close:SetSize(140, 24)
    close:SetPoint('BOTTOM', f, 'BOTTOM', 0, 16)
    close:SetText(CLOSE or 'Close')
    close:SetScript('OnClick', function() f:Hide() end)

    local scroll = CreateFrame('ScrollFrame', 'DragonflightUILogCopyScroll', f, 'UIPanelScrollFrameTemplate')
    scroll:SetPoint('TOPLEFT', f, 'TOPLEFT', 20, -60)
    scroll:SetPoint('BOTTOMRIGHT', f, 'BOTTOMRIGHT', -34, 48)

    -- A multiline EditBox as the scroll child sizes its own height to the text,
    -- which is what makes this scroll without measuring anything.
    local edit = CreateFrame('EditBox', nil, scroll)
    edit:SetMultiLine(true)
    edit:SetFontObject(ChatFontNormal)
    edit:SetWidth(640)
    edit:SetAutoFocus(false)
    edit:SetMaxLetters(0)
    edit:SetScript('OnEscapePressed', function() f:Hide() end)
    scroll:SetScrollChild(edit)
    f.EditBox = edit

    -- Escape closes it, without the UISpecialFrames name lookup that taints
    -- whoever owns the global. See Helper:CloseWithEscape.
    addonTable.Helper:CloseWithEscape(f)

    copyFrame = f
    return f
end

-- Hard cap on what goes in the box. The buffer holds up to a thousand entries
-- with stack traces attached, and handing all of that to an EditBox at once can
-- lock the client up for a while. The tail is the interesting end.
local COPY_CHAR_LIMIT = 60000

-- Capture whatever is under the cursor, then open the copy window on it.
--
-- Bound to a key rather than driven by a slash command on purpose: 'mouse'
-- resolves at the moment the command runs, and typing into chat puts the cursor
-- over the chat box rather than the thing that looks wrong. A key press does not
-- move the mouse, so a reporter can hover the bug and hit one key.
--
-- Global because keybinding scripts are evaluated as their own chunk and cannot
-- see our locals.
function DragonflightUI_CaptureFrameUnderCursor()
    local focus
    if GetMouseFoci then
        local foci = GetMouseFoci()
        focus = foci and foci[1]
    elseif GetMouseFocus then
        focus = GetMouseFocus()
    end

    if not focus or focus == WorldFrame then
        print(PREFIX .. 'nothing under the cursor - hover the frame that looks wrong and press the key again.')
        return
    end

    local name = (focus.GetName and focus:GetName()) or '<anonymous>'
    DF:Log('capture', '=== captured %s under cursor ===', name)
    DF:LogFrame(focus, 'capture')
    DF:LogRegions(focus, 'capture', 2)

    -- and its parent, since the thing that looks wrong is often the container
    -- rather than the piece the cursor happened to land on
    local parent = focus.GetParent and focus:GetParent()
    if parent and parent ~= UIParent then
        DF:Log('capture', '=== parent: %s ===', (parent.GetName and parent:GetName()) or '<anonymous>')
        DF:LogRegions(parent, 'capture', 1)
    end

    DF:LogCopy('capture')
end

function DF:LogCopy(filter)
    if filter == '' then filter = nil end

    local matching = Matching(filter)
    if #matching == 0 then
        print(PREFIX .. 'no entries' .. (filter and (' matching "' .. filter .. '"') or '') .. ' to copy.')
        return
    end

    local header = string.format('DragonflightUI %s | %s | %d entries%s', DF:GetVersion(),
                                 (GetBuildInfo and select(1, GetBuildInfo())) or '?', #matching,
                                 filter and (' matching "' .. filter .. '"') or '')

    local text = header .. '\n\n' .. table.concat(matching, '\n')
    if #text > COPY_CHAR_LIMIT then
        text = '... earlier entries dropped, log too long to copy in one go ...\n\n' ..
                   text:sub(#text - COPY_CHAR_LIMIT)
    end

    local f = CreateCopyWindow()
    f.EditBox:SetText(text)
    f.EditBox:HighlightText()
    f.EditBox:SetFocus()
    f:Show()
end

function DF:LogDump(filter, limit)
    local matching = Matching(filter)

    if #matching == 0 then
        print(PREFIX .. 'no entries' .. (filter and (' matching "' .. filter .. '"') or ''))
        return
    end

    local first = 1
    if limit and #matching > limit then first = #matching - limit + 1 end

    print(PREFIX .. string.format('%d entries%s, showing %d-%d:', #matching,
                                  filter and (' matching "' .. filter .. '"') or '', first, #matching))
    for i = first, #matching do print(matching[i]) end
    print(PREFIX .. 'also written to SavedVariables (DragonflightUIDebugLog) on /reload or logout.')
end

function DF:LogClear()
    for i = #log, 1, -1 do log[i] = nil end
    log.truncated = nil
    lastKey, lastIndex, lastCount = nil, nil, nil
    print(PREFIX .. 'cleared')
end

-- Party frames refusing Show/Hide/SetAttribute/SetSize when a group member logs
-- in or out, in combat, with DragonflightUI named as the taint source. taintLog
-- cannot answer this one: it records tainted GLOBALS, and these are tainted
-- FIELDS on frames the client owns, so the blocked stack comes back pure
-- Blizzard with nothing naming the origin.
--
-- issecurevariable can see what taintLog cannot. Its second return is the addon
-- that dirtied the field, so walking the party frames and their interesting
-- fields turns "something tainted this" into a name and a key.
local PARTY_TAINT_FIELDS = {
    'unit', 'isLootObject', 'displayedUnit', 'inVehicle', 'optionTable', 'layoutIndex', 'maxBuffs', 'maxDebuffs',
    'showBuffs', 'showDebuffs', 'shouldShow'
}

-- Fields on a frame object, whether or not it has a name in _G.
--
-- The pooled party member frames are anonymous, so the by-name walk below
-- reported them "absent" and checked nothing - which is how a report of every
-- named frame coming back clean sat next to a log full of blocked actions on
-- those very frames. A frame with no global name is the normal case here, not
-- the exception.
--
-- The methods matter as much as the data. hooksecurefunc(frame, 'Method', fn)
-- writes an insecure function into the frame's own table, and Blizzard reads
-- that field every time it calls the method - so a hooked method is a taint
-- seed that looks like nothing at all in a data-only dump.
local PARTY_TAINT_METHODS = {'UpdateOnlineStatus', 'UpdateMember', 'UpdateArt', 'UpdatePet', 'Show', 'Hide',
                             'SetShown', 'SetPoint', 'SetAttribute'}

local function LogFrameFieldTaint(tag, label, frame)
    local dirty = 0

    for _, key in ipairs(PARTY_TAINT_FIELDS) do
        if rawget(frame, key) ~= nil then
            local fieldOk, fieldWho = issecurevariable(frame, key)
            if not fieldOk then
                dirty = dirty + 1
                DF:Log(tag, '%s.%s insecure, tainted by %s', label, key, tostring(fieldWho or '?'))
            end
        end
    end

    -- rawget on purpose: an inherited method lives on the mixin and is not this
    -- frame's problem. One written onto the frame itself is exactly the hook.
    for _, key in ipairs(PARTY_TAINT_METHODS) do
        if rawget(frame, key) ~= nil then
            local fieldOk, fieldWho = issecurevariable(frame, key)
            dirty = dirty + 1
            DF:Log(tag, '%s:%s() overwritten on the frame%s', label, key,
                   fieldOk and ' (secure)' or (' - INSECURE, tainted by ' .. tostring(fieldWho or '?')))
        end
    end

    return dirty
end

local function LogFrameTaint(tag, name)
    local frame = _G[name]
    if not frame then
        DF:Log(tag, '%s absent', name)
        return
    end

    -- The frame's own entry in _G: dirty here means something replaced or
    -- created the global itself, which is the worst case.
    local ok, who = issecurevariable(name)
    if not ok then DF:Log(tag, '%s GLOBAL insecure, tainted by %s', name, tostring(who or '?')) end

    local dirty = LogFrameFieldTaint(tag, name, frame)

    if dirty == 0 and ok then DF:Log(tag, '%s clean', name) end
end

-- /df log seed - catches the exact moment a party member's .unit goes insecure.
--
-- Everything else has been deduction, and four deductions in a row have been
-- wrong. The control settled what it is NOT: PlayerFrame is reparented onto an
-- insecure holder of ours too and is fine, so neither the holder nor the
-- reparent breaks anything. The one thing party has that player does not is a
-- tainted .unit.
--
-- .unit is written by UnitFrame_SetUnit. So hook that, check the field straight
-- afterwards, and the first time it comes back insecure, record the stack. The
-- stack at that instant contains whatever put this addon on it - which is the
-- one fact nobody has been able to read off a blocked-action dump, because by
-- then the damage is long done and the stack is pure Blizzard.
--
-- Armed at load, not from a command: the taint happens while the party frames
-- are being built, which is long before anyone can type. It costs an early
-- return per call on a party unit and stops working entirely once it has fired.
--
-- Read it back with /df log seed.
local seedArmed, seedFound = false, false

-- The candidate seeds, and this is the whole list.
--
-- The watcher reports the FIRST insecure .unit it sees. In the log from
-- 2026-08-22 that was PartyMemberFrame.lua:26, reached through UpdateArt at 194
-- - but UpdateMember calls UnitFrame_SetUnit itself at 168 and 169, earlier in
-- the very same pass, and .unit was still clean there. So the execution is
-- tainted somewhere between line 169 and line 194, and every global the
-- functions in between read is a suspect:
--
--   UpdatePet, UpdatePvPStatus, UpdateAuras, UpdateReadyCheck,
--   UpdateOnlineStatus, UpdateNotPresentIcon, UpdateArt
--
-- Read straight off Blizzard's own source for 1.15.9.
local SEED_CANDIDATES = {
    'PartyFrame', 'PartyMemberFrameMixin', 'PartyMemberAuraMixin', 'PartyUtil', 'EditModeManagerFrame',
    'VoiceActivityManager', 'CVarCallbackRegistry', 'UnitFrame_Update', 'UnitFrame_SetUnit', 'UnitFrame_OnEvent',
    'ReadyCheck_Confirm', 'ReadyCheck_Start', 'GetReadyCheckStatus', 'PARTY_IN_PUBLIC_GROUP_MESSAGE',
    'UnitFactionGroup', 'UnitIsPVPFreeForAll', 'UnitIsPVP', 'UnitInOtherParty', 'UnitPhaseReason', 'UnitIsConnected',
    'UnitExists', 'UnitName', 'UnitGUID', 'UnitIsGroupLeader', 'C_PartyInfo', 'PartyMemberBuffTooltip'
}

-- Walk an object's fields and name every one this addon owns.
--
-- The global sweep came back with nothing: 270 globals are dirtied by us, and
-- cross-referencing all of them against Blizzard's own party source found not
-- one that the party path reads. So the taint arrives on a FIELD, which is what
-- issecurevariable's two-argument form is for, and which taintLog cannot see at
-- all - worth knowing before anyone spends an 85MB log on it.
--
-- The prime suspect is frame.OnEvent. UnitFrame.lua:904 caches the original
-- handler onto the frame with
--   unitFrame.OnEvent = unitFrame:GetScript("OnEvent") or false
-- and UnitFrameThreatIndicator_OnEvent reads it back on every single event at
-- line 911 - which is the exact top of the captured stack. Whoever is on the
-- stack when that cache is written owns the field for the session, and then
-- every event on that frame starts tainted. Same shape as the two seeds already
-- found and fixed: a value Blizzard creates lazily, inside our execution.
local function LogInsecureFields(label, obj)
    if type(obj) ~= 'table' then return end

    local hits = 0
    for key in pairs(obj) do
        if type(key) == 'string' then
            local safe, blame = issecurevariable(obj, key)
            if not safe then
                hits = hits + 1
                DF:Log('seed', 'FIELD %s.%s insecure, tainted by %s', label, key, tostring(blame or '?'))
            end
        end
    end

    if hits == 0 then DF:Log('seed', 'FIELD %s: every field secure', label) end
end

local function LogSeedCandidates()
    local hits = 0

    for _, name in ipairs(SEED_CANDIDATES) do
        local safe, blame = issecurevariable(name)
        if not safe then
            hits = hits + 1
            DF:Log('seed', 'CANDIDATE %s is INSECURE, tainted by %s', name, tostring(blame or '?'))
        end
    end

    if hits == 0 then
        DF:Log('seed', 'none of the %d globals on that path are insecure - the seed is a field, not a global',
               #SEED_CANDIDATES)
    end
end

local function ArmSeedWatcher()
    if seedArmed or not UnitFrame_SetUnit then return end
    seedArmed = true

    hooksecurefunc('UnitFrame_SetUnit', function(frame, unit)
        if seedFound or not frame or not unit then return end
        if type(unit) ~= 'string' or not unit:find('party', 1, true) then return end

        local ok, who = issecurevariable(frame, 'unit')
        if ok then return end

        seedFound = true
        DF:Log('seed', 'FIRST INSECURE .unit on %s (unit=%s), tainted by %s', (frame.GetName and frame:GetName()) or
                   '<pooled>', tostring(unit), tostring(who or '?'))
        DF:Log('seed', 'stack: %s', tostring(debugstack(2, 30, 0)):gsub('\n', ' | '):sub(1, 3000))

        -- Ask the question at the only moment it can be answered. The stack is
        -- pure Blizzard, so the execution arrived tainted, and in this engine
        -- that means Blizzard read a variable we had dirtied. Name it now,
        -- while the evidence is still on the stack, rather than after the fact.
        LogSeedCandidates()

        -- The fields, which is where the evidence now points. The member frame
        -- itself, its pet frame (UpdatePet is on the tainted stretch), and the
        -- container above it.
        LogInsecureFields('member', frame)
        LogInsecureFields('member.PetFrame', frame.PetFrame)
        LogInsecureFields('parent', frame.GetParent and frame:GetParent())
        LogInsecureFields('PartyFrame', _G['PartyFrame'])

        -- Named outright, because it is the suspect and it may not survive a
        -- pairs() walk if Blizzard cached it as false.
        local okEvent, blameEvent = issecurevariable(frame, 'OnEvent')
        DF:Log('seed', 'frame.OnEvent secure=%s blame=%s value=%s', tostring(okEvent), tostring(blameEvent or '-'),
               type(rawget(frame, 'OnEvent')))

        DF:LogTaintedGlobals('seed')

        -- Captured, not announced. This watcher is armed on every load, so the print
        -- that used to sit here greeted every player who joined a group with a line
        -- about taint seeds - a diagnostic aimed at whoever is debugging this addon,
        -- shown to everyone else. The report is in the buffer and in SavedVariables
        -- either way; /df log seed prints it on request.
    end)
end

-- /df log globals - every global this addon has dirtied.
--
-- The seed watcher proved the party taint arrives from OUTSIDE our code: the
-- stack at the moment .unit goes insecure is pure Blizzard, from UIParent's
-- event handler down through UpdateRaidAndPartyFrames. So the execution was
-- already tainted on entry, and in WoW that only happens one way - Blizzard
-- read a variable we had dirtied.
--
-- taintLog reports exactly that and needs a CVar, a reload and an 85MB file.
-- issecurevariable(name) answers the same question for one global, so asking it
-- about all of them gives the write-side list directly, in game, on demand.
--
-- Everything blamed on DragonflightUI is a candidate seed. The one to look for
-- is a name Blizzard's party path would read - anything CompactRaidFrame*,
-- since UpdateRaidAndPartyFrames lives in RaidFrame.lua and this addon calls
-- CompactRaidFrameManager_SetSetting from its edit mode.
function DF:LogTaintedGlobals(tag)
    tag = tag or 'globals'

    if InCombatLockdown() then
        DF:Log(tag, 'skipped: in combat (this walks every global, so it waits)')
        return
    end

    local scanned, dirty, ours = 0, 0, 0
    local mine = {}

    for name in pairs(_G) do
        if type(name) == 'string' then
            scanned = scanned + 1
            local ok, who = issecurevariable(name)
            if not ok then
                dirty = dirty + 1
                if who == addonName then
                    ours = ours + 1
                    mine[#mine + 1] = name
                end
            end
        end
    end

    table.sort(mine)

    -- Ours first and in full: this is the list that matters. Blizzard-owned
    -- names in it are the seeds; DragonflightUI* names are just our own frames
    -- and are expected.
    local blizz = {}
    for _, name in ipairs(mine) do
        if not name:find('DragonflightUI', 1, true) and not name:find('^DF') then blizz[#blizz + 1] = name end
    end

    DF:Log(tag, 'scanned %d globals: %d tainted overall, %d by %s, %d of those NOT ours', scanned, dirty, ours,
           addonName, #blizz)

    if #blizz == 0 then
        DF:Log(tag, 'no Blizzard-owned global is dirtied by this addon')
    else
        for _, name in ipairs(blizz) do DF:Log(tag, 'SEED: %s tainted by %s', name, addonName) end
    end

    -- Our own, collapsed to a count - they are expected and would bury the rest.
    DF:Log(tag, '(%d of ours, e.g. %s)', ours - #blizz, mine[1] or '-')
end

-- /df log party - names whoever tainted the party frames. Run it once the
-- frames have misbehaved; the taint is sticky, so it is still there afterwards.
function DF:LogPartyTaint(tag)
    tag = tag or 'party'

    DF:Log(tag, 'combat=%s group=%d raidstyle=%s', tostring(InCombatLockdown()), GetNumGroupMembers and
               GetNumGroupMembers() or -1, tostring(EditModeManagerFrame and EditModeManagerFrame.UseRaidStylePartyFrames
                                                        and EditModeManagerFrame:UseRaidStylePartyFrames()))

    -- The parent chain, which is the half a taint dump does not show.
    --
    -- PartyFrame is protected and we reparent it onto a holder of our own. That
    -- holder has to be protected too: hanging a protected frame off an
    -- unprotected one is what makes the client refuse its own Show/Hide and
    -- SetAttribute on the pooled members. So report what the parent actually is,
    -- not just whether anything is tainted - "parent protected=false" is the
    -- whole bug in one line, and it is invisible to issecurevariable.
    if PartyFrame then
        local parent = PartyFrame:GetParent()
        local parentName = (parent and parent.GetName and (parent:GetName() or '<anon>')) or 'none'
        local parentProtected = parent and parent.IsProtected and parent:IsProtected()

        DF:Log(tag, 'PartyFrame: parent=%s parent protected=%s, self protected=%s, shown=%s', parentName,
               tostring(parentProtected), tostring(PartyFrame.IsProtected and PartyFrame:IsProtected()),
               tostring(PartyFrame:IsShown()))
    end

    -- The pooled members, which have no global names to walk.
    if PartyFrame and PartyFrame.PartyMemberFramePool then
        local n = 0
        for pf in PartyFrame.PartyMemberFramePool:EnumerateActive() do
            n = n + 1
            DF:Log(tag, 'pooled member %d: unit=%s shown=%s protected=%s parent=%s', n, tostring(pf.unit),
                   tostring(pf:IsShown()), tostring(pf.IsProtected and pf:IsProtected()),
                   (pf:GetParent() and pf:GetParent():GetName()) or '<anon>')

            -- These have no name in _G, so the by-name walk below never sees
            -- them. This is where the taint on the party-style frames lives.
            if LogFrameFieldTaint(tag, 'pooled member ' .. n, pf) == 0 then
                DF:Log(tag, 'pooled member %d clean', n)
            end
        end
        DF:Log(tag, 'pooled members active: %d (group has %d)', n, GetNumGroupMembers and GetNumGroupMembers() or -1)
    end

    LogFrameTaint(tag, 'PartyFrame')
    LogFrameTaint(tag, 'CompactPartyFrame')
    LogFrameTaint(tag, 'DragonflightUIPartyMoveFrame')

    -- The control.
    --
    -- Every theory so far has blamed something about the party holder - the
    -- template it inherits, whether XML or Lua created it - and each one was
    -- answered by a report saying the taint was still there. The way to stop
    -- guessing is to compare against a unit frame that WORKS.
    --
    -- PlayerFrame and TargetFrame are reparented onto holders of ours in
    -- exactly the same way, and nobody reports them breaking. So: is their
    -- holder's global insecure too? Is their own .unit tainted too? If yes to
    -- both, then neither an insecure holder nor a tainted .unit is what breaks
    -- the party frames, and the difference is somewhere else entirely - which
    -- kills three theories at once and is worth far more than another guess.
    for _, name in ipairs({'DragonflightUIPlayerFrame', 'DragonflightUITargetFrame'}) do
        local ok, who = issecurevariable(name)
        DF:Log(tag, 'control %s GLOBAL: %s%s', name, ok and 'secure' or 'INSECURE',
               ok and '' or (', tainted by ' .. tostring(who or '?')))
    end

    for _, name in ipairs({'PlayerFrame', 'TargetFrame'}) do
        local frame = _G[name]
        if frame then
            DF:Log(tag, 'control %s: parent=%s', name,
                   (frame:GetParent() and frame:GetParent():GetName()) or '<anon>')
            if LogFrameFieldTaint(tag, 'control ' .. name, frame) == 0 then
                DF:Log(tag, 'control %s clean', name)
            end
        end
    end

    for i = 1, 5 do
        LogFrameTaint(tag, 'CompactPartyFrameMember' .. i)
        LogFrameTaint(tag, 'PartyMemberFrame' .. i)
    end

    -- The shared seed, and the reason to look here at all.
    --
    -- Blocked actions turn up on BOTH party systems - PartyFrame and
    -- CompactPartyFrame - with stacks that are pure Blizzard and name no addon
    -- file. Whatever taints them is therefore upstream of both, and the one term
    -- both ShouldShow paths run through is
    -- EditModeManagerFrame:UseRaidStylePartyFrames(), which reads the Edit Mode
    -- layout.
    --
    -- The original note here blamed LibEditModeOverride. That was wrong - the
    -- library was loaded but never called. The real seed was this addon
    -- REPLACING UseRaidStylePartyFrames outright, so that Blizzard's own
    -- ShouldShow ran our function and picked up the taint from it. That
    -- assignment is gone, along with every write to Blizzard's layout.
    --
    -- taintLog cannot see any of this: it records tainted globals, and these are
    -- fields. That is why this was once "ruled out" and should not have been.
    if EditModeManagerFrame then
        for _, key in ipairs({'accountSettings', 'layoutInfo', 'activeLayout', 'savedLayouts', 'registeredSystemFrames'}) do
            if rawget(EditModeManagerFrame, key) ~= nil then
                local ok, who = issecurevariable(EditModeManagerFrame, key)
                DF:Log(tag, 'EditModeManagerFrame.%s: %s%s', key, ok and 'clean' or 'INSECURE',
                       ok and '' or (', tainted by ' .. tostring(who or '?')))
            end
        end

        -- The call itself, which is what ShouldShow actually asks.
        if EditModeManagerFrame.UseRaidStylePartyFrames then
            local ok, value = pcall(EditModeManagerFrame.UseRaidStylePartyFrames, EditModeManagerFrame)
            DF:Log(tag, 'UseRaidStylePartyFrames() -> %s (call ok=%s)', tostring(value), tostring(ok))
        end
    end
end

-- /df log bagtrace - name whoever re-anchors the bag row.
--
-- /df log watch proves WHAT happens: all five buttons, the four bag slots and the
-- keyring, end up with a uniform -5 offset, and bag 0 loses the -12 gap it needs
-- for the expand arrow. It cannot say WHO does it. Three fixes aimed at guessed
-- callers - BagsBar:Layout, ignoreFramePositionManager and
-- UIParent_ManageFramePositions - all failed, so stop guessing and hook the write
-- itself. Whoever sets the offset gets named, with its stack.
-- Anchoring was only half of it. Collapsing the row is Show and Hide on the same
-- buttons, and both those and SetPoint are refused mid-fight, so a trace that shows
-- position writes alone cannot explain a row that came back in the wrong state. Every
-- entry therefore carries the combat state, visibility changes are traced next to
-- position changes, and 'state' prints everything the layout is computed from -
-- Blizzard's padding and expand flags, our own saved state, and whether the client
-- considers these buttons protected at all.
local bagTraceOn = false
local bagTraceHooked = false

-- Separate budgets per kind, so a burst of Hide calls cannot crowd out the SetPoint
-- calls that name the culprit.
local BAG_TRACE_MAX_PER_KIND = 14
local bagTraceHits = {}

local BAG_TRACE_BUTTONS = {
    'MainMenuBarBackpackButton', 'CharacterBag0Slot', 'CharacterBag1Slot', 'CharacterBag2Slot', 'CharacterBag3Slot',
    'KeyRingButton'
}

local function BagTraceName(rel)
    if type(rel) == 'string' then return rel end
    if type(rel) == 'table' and rel.GetName then return rel:GetName() or '<anon>' end
    return '-'
end

local function BagTraceCombat()
    -- Both halves, because they disagree and the disagreement is the whole point:
    -- PLAYER_REGEN_ENABLED clears the lockdown while the server-side flag lingers.
    return string.format('lock=%s unit=%s', tostring(InCombatLockdown()),
                         tostring(UnitAffectingCombat('player')))
end

local function BagTracePoint(f)
    if not (f and f.GetNumPoints) or f:GetNumPoints() == 0 then return 'unplaced' end

    local point, relativeTo, relativePoint, x, y = f:GetPoint(1)
    return string.format('%s -> %s %s (%.0f,%.0f)', tostring(point), BagTraceName(relativeTo), tostring(relativePoint),
                         x or 0, y or 0)
end

-- Everything the bag row layout is derived from, in one place.
function DF:LogBagRowState(tag)
    tag = tag or 'bagtrace'

    DF:Log(tag, 'STATE combat %s', BagTraceCombat())

    local bar = _G['BagsBar']
    if bar then
        -- bagPadding is the -5. hideExpandToggle decides whether the chain starts at
        -- the backpack or at Blizzard's own toggle.
        DF:Log(tag, 'BagsBar: bagPadding=%s hideExpandToggle=%s isHorizontal=%s direction=%s shown=%s',
               tostring(bar.bagPadding), tostring(bar.hideExpandToggle), tostring(bar.isHorizontal),
               tostring(bar.direction), tostring(bar:IsShown()))
    else
        DF:Log(tag, 'BagsBar: absent')
    end

    local mgr = _G['MainMenuBarBagManager']
    if mgr then
        -- expandBarAuto starting out nil is what makes the first cursor change count
        -- as a change: nil ~= false.
        DF:Log(tag, 'MainMenuBarBagManager: expandBar=%s expandBarAuto=%s shouldExpand=%s cvar expandBagBar=%s',
               tostring(mgr.expandBar), tostring(mgr.expandBarAuto),
               tostring(mgr.ShouldBarExpand and mgr:ShouldBarExpand()),
               tostring(GetCVarBool and GetCVarBool('expandBagBar')))
    else
        DF:Log(tag, 'MainMenuBarBagManager: absent')
    end

    local ok, mod = pcall(function() return DF:GetModule('Actionbar') end)
    local bags = ok and mod and mod.db and mod.db.profile and mod.db.profile.bags
    if bags then
        DF:Log(tag, 'DFUI bags: expanded=%s scale=%s hooked=%s', tostring(bags.expanded), tostring(bags.scale),
               tostring(mod.BagBarLayoutHooked))
    else
        DF:Log(tag, 'DFUI bags: profile not reachable yet')
    end

    for _, name in ipairs(BAG_TRACE_BUTTONS) do
        local btn = _G[name]
        if btn then
            -- IsProtected answers whether the combat guard is actually required on
            -- these buttons, rather than us assuming it is.
            local protected, explicit = btn:IsProtected()

            -- Size matters as much as the anchor here. Blizzard's Layout calls
            -- KeyringMixin:UpdateOrientation, which resets the keyring to the
            -- dimensions captured before we restyled it, and a frame narrower than its
            -- own artwork looks like a spacing bug rather than a sizing one.
            DF:Log(tag, '%s: shown=%s %.0fx%.0f scale=%.2f protected=%s(explicit=%s) %s', name,
                   tostring(btn:IsShown()), btn:GetWidth() or 0, btn:GetHeight() or 0,
                   (btn.GetScale and btn:GetScale()) or 1, tostring(protected), tostring(explicit), BagTracePoint(btn))
        else
            DF:Log(tag, '%s: absent', name)
        end
    end
end

local function BagTraceRecord(kind, description)
    if not bagTraceOn then return end

    local hits = (bagTraceHits[kind] or 0)
    if hits >= BAG_TRACE_MAX_PER_KIND then return end
    bagTraceHits[kind] = hits + 1

    DF:Log('bagtrace', '%s [%s]', description, BagTraceCombat())
    DF:Log('bagtrace', '  stack: %s', tostring(debugstack(3, 12, 0)):gsub('\n', ' | '):sub(1, 1200))

    if bagTraceHits[kind] >= BAG_TRACE_MAX_PER_KIND then
        DF:Log('bagtrace', '%s: hit the cap of %d - no more of this kind will be logged.', kind,
               BAG_TRACE_MAX_PER_KIND)
    end
end

local function BagTracePointHook(self, point, rel, relPoint, x, y)
    BagTraceRecord('point', string.format('%s:SetPoint(%s -> %s %s, %s, %s)', (self.GetName and self:GetName()) or
                                              '<anon>', tostring(point), BagTraceName(rel), tostring(relPoint),
                                          tostring(x), tostring(y)))
end

local function BagTraceShowHook(self)
    BagTraceRecord('visibility', string.format('%s:Show()', (self.GetName and self:GetName()) or '<anon>'))
end

local function BagTraceHideHook(self)
    BagTraceRecord('visibility', string.format('%s:Hide()', (self.GetName and self:GetName()) or '<anon>'))
end

function DF:LogBagTrace(on)
    if on and not bagTraceHooked then
        local found = 0
        for _, name in ipairs(BAG_TRACE_BUTTONS) do
            local btn = _G[name]
            if btn and btn.SetPoint then
                found = found + 1
                hooksecurefunc(btn, 'SetPoint', BagTracePointHook)
                if btn.Show then hooksecurefunc(btn, 'Show', BagTraceShowHook) end
                if btn.Hide then hooksecurefunc(btn, 'Hide', BagTraceHideHook) end
            end
        end

        if found == 0 then
            print(PREFIX .. 'no bag buttons exist yet - nothing to trace.')
            return
        end

        -- The hooks stay for the session; the flag is what turns logging on and
        -- off. Re-hooking on every toggle would stack duplicates.
        bagTraceHooked = true
        print(PREFIX .. ('bag trace hooked %d button(s).'):format(found))
    end

    bagTraceOn = on and true or false

    if bagTraceOn then
        table.wipe(bagTraceHits)
        -- A baseline, so the trace that follows can be read against a known state
        -- instead of guessed at.
        DF:LogBagRowState('bagtrace')
        print(PREFIX .. 'bag trace ON - reproduce it, then |cffffff78/df log bagtrace copy|r')
    else
        local total = 0
        for _, n in pairs(bagTraceHits) do total = total + n end
        print(PREFIX .. ('bag trace OFF - %d call(s) captured.'):format(total))
    end
end

-- /df log raidopts - why the raid Edit Mode options are or are not there.
--
-- The options are built once, from Blizzard's own EditModeSettingDisplayInfoManager,
-- and four things have to be true for a single entry to appear. When the panel comes
-- up empty there is no way to tell which one failed, so each is reported separately
-- here, along with what the raid system frame says about every setting Blizzard
-- describes.
--
-- Run it after login. If the data is all present now but the panel is still empty,
-- the answer is timing: the options table was built before Blizzard_EditMode loaded.
function DF:LogRaidOptions(tag)
    tag = tag or 'raidopts'

    local loaded = (C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded('Blizzard_EditMode')) or
                       (IsAddOnLoaded and IsAddOnLoaded('Blizzard_EditMode'))
    DF:Log(tag, 'Blizzard_EditMode loaded=%s', tostring(loaded))

    local mgr = _G['EditModeSettingDisplayInfoManager']
    DF:Log(tag, 'EditModeSettingDisplayInfoManager=%s systemSettingDisplayInfo=%s GetSettingDisplayInfo=%s',
           tostring(mgr ~= nil), tostring(mgr and mgr.systemSettingDisplayInfo ~= nil),
           tostring(mgr and mgr.GetSettingDisplayInfo ~= nil))

    local types = Enum and Enum.EditModeSettingDisplayType
    if types then
        local names = {}
        for k, v in pairs(types) do table.insert(names, k .. '=' .. tostring(v)) end
        table.sort(names)
        DF:Log(tag, 'EditModeSettingDisplayType: %s', table.concat(names, ' '))
    else
        DF:Log(tag, 'EditModeSettingDisplayType: ABSENT - every entry is skipped')
    end

    DF:Log(tag, 'helper hooks: SetRaidEditModeSetting=%s GetRaidSystemFrameForOptions=%s',
           tostring(addonTable and addonTable.SetRaidEditModeSetting ~= nil),
           tostring(addonTable and addonTable.GetRaidSystemFrameForOptions ~= nil))

    local raidFrame = addonTable and addonTable.GetRaidSystemFrameForOptions and
                          addonTable:GetRaidSystemFrameForOptions()
    DF:Log(tag, 'raid system frame=%s HasSetting=%s GetSettingValue=%s',
           (raidFrame and ((raidFrame.GetName and raidFrame:GetName()) or '<anon>')) or 'nil',
           tostring(raidFrame and raidFrame.HasSetting ~= nil), tostring(raidFrame and raidFrame.GetSettingValue ~= nil))

    -- What the raid system says about each setting Blizzard describes. This is the
    -- list the options are built from, so an entry missing here explains an entry
    -- missing there.
    local displayInfo = mgr and mgr.systemSettingDisplayInfo and Enum and Enum.EditModeSystem and
                            mgr.systemSettingDisplayInfo[Enum.EditModeSystem.UnitFrame]

    if not displayInfo then
        DF:Log(tag, 'no unit frame display info - nothing can be built')
    else
        DF:Log(tag, 'unit frame display info entries: %d', #displayInfo)

        for _, info in ipairs(displayInfo) do
            local has, val = 'n/a', 'n/a'
            if raidFrame and raidFrame.HasSetting and info.setting ~= nil then
                local ok, res = pcall(raidFrame.HasSetting, raidFrame, info.setting)
                has = ok and tostring(res) or ('ERR ' .. tostring(res))

                if ok and res and raidFrame.GetSettingValue then
                    local okv, v = pcall(raidFrame.GetSettingValue, raidFrame, info.setting)
                    val = okv and tostring(v) or ('ERR ' .. tostring(v))
                end
            end

            DF:Log(tag, '  setting=%s type=%s hasSetting=%s stored=%s name=%s', tostring(info.setting),
                   tostring(info.type), has, val, tostring(info.name))
        end
    end

    -- And whether anything actually landed in the options table. Reported by the
    -- builder itself: reaching the table from here needs the submodule instance, which
    -- is not the mixin stored in SubModuleMixins, so the earlier attempt to walk to it
    -- always came up empty and said nothing useful.
    DF:Log(tag, 'blizzRaid* option entries built: %s',
           tostring((addonTable and addonTable.RaidEditModeOptionCount) or 'builder never ran'))

    -- Whether the edit mode selection was ever created, and which half of the gate in
    -- SubModuleMixin:Setup stopped it if not.
    local diag = addonTable and addonTable.RaidInitDiag
    if diag then
        DF:Log(tag, 'raid edit mode init: ran=%s HasLoadedCUFProfiles=%s(%s) CompactUnitFrameProfiles=%s variablesLoaded=%s',
               tostring(diag.initRan), tostring(diag.hasLoadedCUFProfiles), tostring(diag.hasLoadedCUFProfilesFn),
               tostring(diag.profilesTable), tostring(diag.variablesLoaded))
    else
        DF:Log(tag, 'raid edit mode init: Setup never reached this point')
    end

    -- The holder the selection and the raid container hang off.
    local holder = _G['DragonflightUIRaidMoveFrame']
    if holder then
        DF:Log(tag, 'DragonflightUIRaidMoveFrame: shown=%s visible=%s %.0fx%.0f points=%d selection=%s',
               tostring(holder:IsShown()), tostring(holder:IsVisible()), holder:GetWidth() or 0,
               holder:GetHeight() or 0, holder:GetNumPoints(), tostring(holder.DFEditModeSelection ~= nil))

        local secure, blame = issecurevariable('DragonflightUIRaidMoveFrame')
        DF:Log(tag, 'DragonflightUIRaidMoveFrame global secure=%s blame=%s', tostring(secure), tostring(blame or '-'))
    else
        DF:Log(tag, 'DragonflightUIRaidMoveFrame: ABSENT - Load.xml did not create it')
    end

    local container = _G['CompactRaidFrameContainer']
    if container then
        local parentName = (container:GetParent() and container:GetParent().GetName and container:GetParent():GetName()) or
                               '<anon>'
        DF:Log(tag, 'CompactRaidFrameContainer: shown=%s visible=%s parent=%s points=%d', tostring(container:IsShown()),
               tostring(container:IsVisible()), parentName, container:GetNumPoints())
    end
end

-- Returns true when the input was a log command and has been handled.
function DF:HandleLogCommand(rest)
    rest = rest or ''
    local sub, arg = rest:match('^(%S*)%s*(.-)$')
    sub = (sub or ''):lower()

    if sub == '' then
        DF:LogDump(nil, 30)
    elseif sub == 'all' then
        DF:LogDump(nil, nil)
    elseif sub == 'clear' then
        DF:LogClear()
    elseif sub == 'echo' then
        DF:LogEcho(not DF:LogIsEchoing())
    elseif sub == 'copy' then
        DF:LogCopy(arg)
    elseif sub == 'frame' then
        if arg == '' then
            print(PREFIX .. 'usage: /df log frame <FrameName|mouse>')
        else
            DF:LogFrame(ResolveFrame(arg) or arg, 'framedump')
            DF:LogDump('framedump', 40)
        end
    elseif sub == 'bars' then
        local frameName, depth = arg:match('^(%S+)%s*(%S*)$')
        if not frameName or frameName == '' then
            print(PREFIX .. 'usage: /df log bars <FrameName|mouse> [depth]')
        else
            DF:LogBars(frameName, 'bardump', depth)
            DF:LogDump('bardump', 60)
        end
    elseif sub == 'regions' then
        local frameName, depth = arg:match('^(%S+)%s*(%S*)$')
        if not frameName or frameName == '' then
            print(PREFIX .. 'usage: /df log regions <FrameName|mouse> [depth]')
        else
            DF:LogRegions(ResolveFrame(frameName) or frameName, 'regiondump', depth)
            DF:LogDump('regiondump', 80)
        end
    elseif sub == 'watch' then
        if arg:lower() == 'reset' then
            DF:LogWatchReset()
        else
            DF:LogWatch(arg)
        end
    elseif sub == 'screen' then
        DF:LogScreen('screen')
        DF:LogDump('screen', 40)
    elseif sub == 'fonts' then
        DF:LogFonts('fonts')
        DF:LogCopy('fonts')
    elseif sub == 'blockers' then
        DF:LogBlockers(arg ~= '' and arg or nil, 'blockers')
        DF:LogDump('blockers', 60)
    elseif sub == 'tot' then
        if arg:lower() == 'watch' then
            DF:LogToTWatch(not totWatcher)
        else
            DF:LogToT('totdump')
            DF:LogDump('totdump', 40)
        end
    elseif sub == 'bagtrace' then
        local a = arg:lower()
        if a == 'off' then
            DF:LogBagTrace(false)
        elseif a == 'copy' then
            DF:LogCopy('bagtrace')
        elseif a == 'state' then
            -- Just the numbers, no tracing: run it before and after the thing that
            -- breaks and compare.
            DF:LogBagRowState('bagstate')
            DF:LogDump('bagstate', 20)
        else
            DF:LogBagTrace(true)
        end
    elseif sub == 'raidopts' then
        DF:LogRaidOptions('raidopts')
        DF:LogCopy('raidopts')
    elseif sub == 'globals' then
        DF:LogTaintedGlobals('globals')
        DF:LogCopy('globals')
    elseif sub == 'seed' then
        if seedFound then
            DF:LogCopy('seed')
        else
            print(PREFIX .. 'no party taint seed captured yet' ..
                      (seedArmed and ' - the watcher is armed; group up and it will fire.' or
                          ' - the watcher never armed (UnitFrame_SetUnit missing).'))
        end
    elseif sub == 'party' then
        DF:LogPartyTaint('party')
        -- Copy window rather than a chat dump: this one is read by somebody
        -- other than the player running it, and 80 lines of chat cannot be
        -- pasted anywhere useful.
        DF:LogCopy('party')
    else
        DF:LogDump(rest, 60)
    end
    return true
end

InstallCapture()

-- Blizzard_UnitFrame may not have loaded when this file runs, so arm now if the
-- function is already there, and again when it arrives.
ArmSeedWatcher()
do
    local armFrame = CreateFrame('Frame')
    armFrame:RegisterEvent('ADDON_LOADED')
    armFrame:RegisterEvent('PLAYER_LOGIN')
    armFrame:SetScript('OnEvent', function(self)
        ArmSeedWatcher()
        if seedArmed then self:UnregisterAllEvents() end
    end)
end
