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
--
-- There is also a keybinding, under DragonflightUI > Debug: hover whatever looks
-- wrong, press the key, and the frame beneath the cursor is dumped and the copy
-- window opens on it. That exists because 'mouse' below resolves when the
-- command runs, and reaching the chat box to type one moves the cursor off the
-- thing being reported.
--     /df log echo         toggle live echo of every entry to chat
--     /df log clear        empty the buffer
--     /df log frame <name>   a frame's whole visibility chain
--     /df log regions <name> [depth]  every region and child of a frame;
--                          with a depth, recurses into what is visible
--     /df log bars <name>  every status bar under a frame: bar colour, texture
--                          vertex colour, desaturation, alpha, lockColor
--     /df log <tag>        only entries carrying that tag, e.g.
--                          /df log error, /df log taint
--
-- frame, regions and bars all take 'mouse' instead of a name, for whatever is
-- under the cursor - handy when the frame's name is what you want to find out.
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
    watcher:SetScript('OnEvent', function(_, event, addon, func)
        DF:Log('taint', '%s: %s -> %s | %s', event, tostring(addon), tostring(func),
               tostring(debugstack(2, 12, 0)):gsub('\n', ' | '):sub(1, 900))
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

    local entry = string.format('%7.2f [%s] %s', GetTime() % 100000, tostring(tag), text)

    if #log < MAX_ENTRIES then
        log[#log + 1] = entry
    elseif not log.truncated then
        log.truncated = true
        log[MAX_ENTRIES] = '... log full, later entries dropped'
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

    if UISpecialFrames then table.insert(UISpecialFrames, 'DragonflightUILogCopyFrame') end

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
    print(PREFIX .. 'cleared')
end

-- TEMP: live tuner for the target frame's combat glow.
--
-- Which texture is actually on screen depends on the flavour. On Wrath DFUI
-- swaps in its own DragonflightUITargetFrameFlash; on TBC the branch is skipped
-- entirely and Blizzard's own flash - an anonymous texture, file id 137016 -
-- stays put, drawn for Blizzard's frame rather than ours. So find whichever one
-- is there and let it be dragged into place by hand instead of guessing offsets
-- one commit at a time.
local tuner

local function FindTargetFlash()
    local mine = _G['DragonflightUITargetFrameFlash']
    if mine then return mine, 'DragonflightUITargetFrameFlash' end

    if not TargetFrame then return nil end
    for _, region in ipairs({TargetFrame:GetRegions()}) do
        if region:GetObjectType() == 'Texture' and region:GetTexture() == 137016 then
            return region, "Blizzard's own flash (137016)"
        end
    end
end

local function TunerSlider(parent, label, low, high, step, y, onChange)
    local s = CreateFrame('Slider', 'DragonflightUIFlashTune' .. label:gsub('%s', ''), parent,
                          'OptionsSliderTemplate')
    s:SetWidth(240)
    s:SetPoint('TOPLEFT', parent, 'TOPLEFT', 24, y)
    s:SetMinMaxValues(low, high)
    s:SetValueStep(step)
    s:SetObeyStepOnDrag(true)

    local name = s:GetName()
    _G[name .. 'Low']:SetText(tostring(low))
    _G[name .. 'High']:SetText(tostring(high))
    _G[name .. 'Text']:SetText(label)

    s:SetScript('OnValueChanged', function(self, value)
        _G[name .. 'Text']:SetText(string.format('%s: %.1f', label, value))
        onChange(value)
    end)

    return s
end

function DF:FlashTune()
    local flash, which = FindTargetFlash()
    if not flash then
        print(PREFIX .. 'no target flash texture found - target something first, then try again.')
        return
    end

    if not tuner then
        local f = CreateFrame('Frame', 'DragonflightUIFlashTuneFrame', UIParent, 'BackdropTemplate')
        f:SetSize(300, 420)
        f:SetPoint('CENTER', UIParent, 'CENTER', 300, 0)
        f:SetFrameStrata('DIALOG')
        f:EnableMouse(true)
        f:SetMovable(true)
        f:RegisterForDrag('LeftButton')
        f:SetScript('OnDragStart', f.StartMoving)
        f:SetScript('OnDragStop', f.StopMovingOrSizing)
        f:SetClampedToScreen(true)
        f:SetBackdrop({
            bgFile = 'Interface\\DialogFrame\\UI-DialogBox-Background-Dark',
            edgeFile = 'Interface\\DialogFrame\\UI-DialogBox-Border',
            tile = true,
            tileSize = 32,
            edgeSize = 32,
            insets = {left = 11, right = 12, top = 12, bottom = 11}
        })

        local title = f:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
        title:SetPoint('TOP', f, 'TOP', 0, -16)
        title:SetText('Target flash tuner')

        f.Which = f:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
        f.Which:SetPoint('TOP', title, 'BOTTOM', 0, -4)
        f.Which:SetWidth(260)

        f.Values = {x = 0, y = 0, w = 0, h = 0, r = 1, b = 1}

        local function apply()
            local t, v = f.Flash, f.Values
            if not t then return end
            t:ClearAllPoints()
            t:SetPoint('CENTER', TargetFrame, 'CENTER', v.x, v.y)
            t:SetSize(v.w, v.h)
            t:SetTexCoord(0, v.r, 0, v.b)
            t:Show()
            t:SetAlpha(1)

            f.Out:SetText(string.format(
                              'SetPoint(CENTER, %.0f, %.0f)  SetSize(%.0f, %.0f)\nSetTexCoord(0, %.4f, 0, %.4f)', v.x,
                              v.y, v.w, v.h, v.r, v.b))
        end
        f.Apply = apply

        TunerSlider(f, 'X offset', -120, 120, 1, -70, function(v) f.Values.x = v; apply() end)
        TunerSlider(f, 'Y offset', -120, 120, 1, -120, function(v) f.Values.y = v; apply() end)
        TunerSlider(f, 'Width', 40, 400, 1, -170, function(v) f.Values.w = v; apply() end)
        TunerSlider(f, 'Height', 20, 200, 1, -220, function(v) f.Values.h = v; apply() end)
        TunerSlider(f, 'TexCoord right', 0.2, 1, 0.002, -270, function(v) f.Values.r = v; apply() end)
        TunerSlider(f, 'TexCoord bottom', 0.2, 1, 0.002, -320, function(v) f.Values.b = v; apply() end)

        f.Out = CreateFrame('EditBox', nil, f)
        f.Out:SetMultiLine(true)
        f.Out:SetFontObject(GameFontHighlightSmall)
        f.Out:SetPoint('BOTTOMLEFT', f, 'BOTTOMLEFT', 20, 46)
        f.Out:SetPoint('BOTTOMRIGHT', f, 'BOTTOMRIGHT', -20, 46)
        f.Out:SetHeight(34)
        f.Out:SetAutoFocus(false)

        local close = CreateFrame('Button', nil, f, 'UIPanelButtonTemplate')
        close:SetSize(120, 22)
        close:SetPoint('BOTTOM', f, 'BOTTOM', 0, 16)
        close:SetText(CLOSE or 'Close')
        close:SetScript('OnClick', function() f:Hide() end)

        tuner = f
    end

    -- Seed the sliders from wherever the texture currently sits, so tuning
    -- starts from what is on screen rather than snapping somewhere else.
    tuner.Flash = flash
    tuner.Which:SetText('|cff9d9d9d' .. which .. '|r')

    local w, h = flash:GetWidth(), flash:GetHeight()
    local _, _, _, x, y = flash:GetPoint(1)

    -- GetTexCoord hands back the four corners: upper-left, lower-left,
    -- upper-right, lower-right. The right edge and the bottom edge are the two
    -- worth a slider.
    local right, bottom = 1, 1
    if flash.GetTexCoord then
        local _, _, _, lly, urx = flash:GetTexCoord()
        right = urx or 1
        bottom = lly or 1
    end

    tuner.Values.x = x or 0
    tuner.Values.y = y or 0
    tuner.Values.w = (w and w > 0) and w or 192
    tuner.Values.h = (h and h > 0) and h or 67
    tuner.Values.r = right
    tuner.Values.b = bottom

    for _, key in ipairs({'Xoffset', 'Yoffset', 'Width', 'Height', 'TexCoordright', 'TexCoordbottom'}) do
        local slider = _G['DragonflightUIFlashTune' .. key]
        if slider then
            local v = tuner.Values
            slider:SetValue(({
                Xoffset = v.x,
                Yoffset = v.y,
                Width = v.w,
                Height = v.h,
                TexCoordright = v.r,
                TexCoordbottom = v.b
            })[key])
        end
    end

    tuner:Show()
    tuner.Apply()
    print(PREFIX .. 'tuning ' .. which .. '. Drag the sliders, then send me the line at the bottom.')
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
    else
        DF:LogDump(rest, 60)
    end
    return true
end

InstallCapture()
