local addonName, addonTable = ...;
local DF = LibStub('AceAddon-3.0'):GetAddon('DragonflightUI')

-- Movable Blizzard windows.
--
-- The character pane, trade window and friends are UI panels: Blizzard's panel
-- manager places them in a left/center/right slot on every show, pushes them
-- around each other, and closes one to make room for the next. A position we
-- set is simply overwritten the next time the window opens.
--
-- So take them out of that layout. Each window's 'area' attribute is what the
-- panel manager keys off (Blizzard_UIParentPanelManager: GetUIPanelAttribute
-- reads it, ShowUIPanel places the frame by it), and clearing it leaves the
-- frame to be shown wherever it stands. Escape-to-close comes from the panel
-- system too, so a detached window gets its own Escape handler to keep it.
--
-- The UIPanelWindows[name] entry is deliberately left alone. Blizzard code
-- indexes it directly - PVPFrameBase does `UIPanelWindows["CharacterFrame"].width
-- = ...` when the arena team details open - and SetUIPanelAttribute itself
-- early-returns without it. Only the attribute is cleared, never the table.
--
-- The visible trade-off, and the reason the option says so: detached windows no
-- longer rearrange each other, and several can be open at once.
local Module = DF:GetModule('UI')

local MovableWindows = {}
addonTable.MovableWindows = MovableWindows

-- One table drives all of it. `addon` marks a window that lives in a
-- load-on-demand Blizzard addon and therefore does not exist at login.
local WINDOWS = {
    {key = 'character', frame = 'CharacterFrame'},
    {key = 'trade', frame = 'TradeFrame'},
    {key = 'inspect', frame = 'InspectFrame', addon = 'Blizzard_InspectUI'},
    {key = 'questlog', frame = 'QuestLogFrame'},
    {key = 'spellbook', frame = 'SpellBookFrame'},
    {key = 'talents', frame = 'PlayerTalentFrame', addon = 'Blizzard_TalentUI'}
}

-- Height of the title strip a drag starts from. Everything below it belongs to
-- the window: gear slots, trade slots, quest rows, spell buttons, the character
-- model.
local DRAG_STRIP_HEIGHT = 28

-- Width left alone at the right end of the strip, so the close button stays
-- clickable. CharacterFrame's own HitRectInsets reserve 30px there for the same
-- reason; a few more is cheap.
local GRIP_RIGHT_INSET = 34

-- Per-frame bookkeeping, outside the frames themselves. `showHooked` is
-- separate from `detached` because HookScript cannot be undone: the hook goes on
-- once per frame for the session and stands down on the detached[] check, so
-- toggling the option off and on again does not stack duplicates.
local detached = {}
local dragInstalled = {}
local grips = {}
local showHooked = {}
local waiting = {}

local function GetPositions()
    local db = Module.db and Module.db.profile
    if not db then return nil end
    db.movableWindowPositions = db.movableWindowPositions or {}
    return db.movableWindowPositions
end

local function IsEnabled()
    local db = Module.db and Module.db.profile
    return (db and db.movable and db.movable.enabled) and true or false
end

-- Re-apply a saved position. A window with nothing saved is left exactly where
-- it would have been, so turning the option on changes nothing until you
-- actually move something.
--
-- One point, never two: a frame held by opposing anchors ignores SetSize on
-- that axis, and these windows resize themselves - the character pane is
-- widened and narrowed per tab by ChangeCharacterFrameEra's DFUpdateFrameWidth.
local function ApplySaved(entry, frame)
    local positions = GetPositions()
    local saved = positions and positions[entry.key]
    if not saved then return end

    -- The anchor frame may not exist this session (another addon's frame, a
    -- window that moved); UIParent always does.
    local relativeTo = (saved.relativeTo and _G[saved.relativeTo]) or UIParent

    frame:ClearAllPoints()
    frame:SetPoint(saved.point, relativeTo, saved.relativePoint, saved.x, saved.y)
end

-- Store what the engine itself left behind. StopMovingOrSizing folds the drag
-- into the existing anchor's offsets, so replaying GetPoint verbatim round-trips
-- exactly - no scale conversion, which is the part that goes wrong when the
-- window and UIParent are at different effective scales.
local function SavePosition(entry, frame)
    local positions = GetPositions()
    if not positions then return end

    local point, relativeTo, relativePoint, x, y = frame:GetPoint(1)
    if not point then return end

    positions[entry.key] = {
        point = point,
        relativeTo = (relativeTo and relativeTo.GetName and relativeTo:GetName()) or nil,
        relativePoint = relativePoint or point,
        x = x or 0,
        y = y or 0
    }
end

local Detach

-- A grip of our own over the title strip, rather than dragging the window
-- itself.
--
-- The window is not a usable drag surface. CharacterFrame declares no
-- enableMouse at all, so it never receives OnDragStart; and even with mouse
-- enabled it would not help, because PaperDollFrame is parented to it with
-- setAllPoints and enableMouse and therefore covers the whole window and takes
-- the input. Reputation and Skills do the same on their tabs. A small frame of
-- our own, above them and mouse-enabled, is the one thing that works the same
-- way for all six windows whatever they happen to be covered by.
local function InstallDrag(entry, frame)
    -- remember what the window shipped as, so Restore can put it back
    if not dragInstalled[entry.key] then
        dragInstalled[entry.key] = {frame = frame, movable = frame:IsMovable() and true or false}
    end

    frame:SetMovable(true)
    frame:SetClampedToScreen(true)

    local grip = grips[entry.key]
    if not grip then
        grip = CreateFrame('Frame', nil, frame)
        grip:SetPoint('TOPLEFT', frame, 'TOPLEFT', 0, 0)
        grip:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', -GRIP_RIGHT_INSET, 0)
        grip:SetHeight(DRAG_STRIP_HEIGHT)
        -- above whatever covers the window (PaperDollFrame and friends share the
        -- parent's level), while the right inset keeps the close button clear
        grip:SetFrameLevel(frame:GetFrameLevel() + 4)
        grip:EnableMouse(true)
        grip:RegisterForDrag('LeftButton')
        grips[entry.key] = grip

        grip:SetScript('OnDragStart', function()
            if not IsEnabled() then return end
            frame:StartMoving()
            grip.moving = true
        end)

        grip:SetScript('OnDragStop', function()
            if not grip.moving then return end
            grip.moving = nil
            frame:StopMovingOrSizing()

            -- The window leaves the panel layout here, at the first drag, and
            -- not before. Detaching up front looked equivalent and is not: a
            -- window that has never been moved has no position of its own to
            -- fall back on, and lands on its raw XML anchor - CharacterFrame's
            -- is TOPLEFT 0,-104, flush against the left edge of the screen. The
            -- panel manager is what normally places it, so leave it in charge
            -- until the player expresses an opinion.
            Detach(entry)
            SavePosition(entry, frame)
        end)
    end

    grip:Show()
end

-- Take one window out of the panel layout. Called at the first drag, or at
-- setup for a window that already carries a saved position. The original area
-- is kept so Restore can hand the window back.
function Detach(entry)
    if detached[entry.key] then return end

    local frame = _G[entry.frame]
    if not frame or not frame.SetMovable then return end

    -- A window with no panel registration is already free of the layout - it
    -- only needs the drag half. SetUIPanelAttribute early-returns without the
    -- table entry anyway, so guard on it rather than skipping the window.
    local panelInfo = UIPanelWindows and UIPanelWindows[entry.frame]

    detached[entry.key] = {frame = frame, panel = panelInfo ~= nil, area = panelInfo and panelInfo.area}

    if panelInfo then
        -- ShowUIPanel and HideUIPanel both bail to a plain Show/Hide when the
        -- area attribute is gone (UIParentPanelManager: ShowUIPanel line 841,
        -- HideUIPanel line 862), which is what frees the window from being
        -- placed, pushed, and closed to make room for the next panel.
        if SetUIPanelAttribute then SetUIPanelAttribute(frame, 'area', nil) end

        -- Escape used to close it because the panel manager owned it. Handled
        -- directly rather than by adding the name to UISpecialFrames: that list
        -- is walked with _G[name], which taints whoever owns the global, and a
        -- detached window would have put us in it for every window detached.
        -- See Helper:CloseWithEscape.
        addonTable.Helper:CloseWithEscape(frame)
    end
end

-- Make a window draggable without changing where it opens. Nothing here takes
-- it out of the panel layout: a window the player has never moved keeps
-- Blizzard's placement, which is the only sensible default it has.
local function Setup(entry)
    local frame = _G[entry.frame]
    if not frame or not frame.SetMovable then return end

    InstallDrag(entry, frame)

    if not showHooked[entry.key] then
        showHooked[entry.key] = true
        frame:HookScript('OnShow', function(self)
            if IsEnabled() and detached[entry.key] then ApplySaved(entry, self) end
        end)
    end

    -- Already moved in an earlier session: free it before its first show, or
    -- the panel manager places it and our OnShow then yanks it across.
    local positions = GetPositions()
    if positions and positions[entry.key] then
        Detach(entry)
        ApplySaved(entry, frame)
    end
end

-- Undo both halves: the drag, and the detach if it happened. Setup and Detach
-- are separate states now - a window can be draggable without having been
-- moved - so this has to unwind whichever of them are in effect, not just the
-- detach.
local function Restore(entry)
    local record = detached[entry.key]
    if record then
        detached[entry.key] = nil

        if record.panel then
            if SetUIPanelAttribute then SetUIPanelAttribute(record.frame, 'area', record.area) end

            -- Nothing to take back out of UISpecialFrames - we no longer put
            -- anything in it. The Escape handler stays installed and is
            -- harmless once the panel manager owns the window again: both
            -- routes end in the same Hide.
        end
        -- The panel manager re-places it on the next show, so nothing to
        -- reposition here.
    end

    local dragState = dragInstalled[entry.key]
    if dragState then
        dragInstalled[entry.key] = nil

        -- The grip is kept, just hidden: it is ours, nothing else looks at it,
        -- and rebuilding one per toggle would leak a frame each time.
        local grip = grips[entry.key]
        if grip then
            grip.moving = nil
            grip:Hide()
        end

        -- back to whatever the window shipped as: CharacterFrame's own XML
        -- declares movable="true", so do not flatly clear it
        dragState.frame:SetMovable(dragState.movable)
    end
end

-- Called on every ApplySettings, so the option toggles live in both directions.
function MovableWindows:Update()
    local enabled = IsEnabled()

    for _, entry in ipairs(WINDOWS) do
        local run = enabled and Setup or Restore

        if enabled and entry.addon and not DF:IsAddOnLoaded(entry.addon) then
            -- Load-on-demand: the frame does not exist until its addon loads.
            -- Wait for it exactly once - FuncOrWaitframe creates a frame per
            -- call, and Update runs on every ApplySettings, so an addon the
            -- player never opens would otherwise leak one per settings change.
            if not waiting[entry.key] then
                waiting[entry.key] = true
                Module:FuncOrWaitframe(entry.addon, function()
                    waiting[entry.key] = nil
                    if IsEnabled() then Setup(entry) end
                end)
            end
        else
            local ok, err = pcall(run, entry)
            if not ok then
                geterrorhandler()('DFUI MovableWindows (' .. entry.frame .. '): ' .. tostring(err))
            end
        end
    end
end

-- Clear every saved position and give the windows back to the panel manager.
function MovableWindows:ResetPositions()
    local positions = GetPositions()
    if positions then table.wipe(positions) end

    for _, entry in ipairs(WINDOWS) do
        local record = detached[entry.key]
        Restore(entry)

        -- A window that was detached is holding a point we set. Drop it and let
        -- the panel manager place it again; re-showing an open one is what makes
        -- the reset visible immediately rather than on its next open.
        if record then
            local frame = record.frame
            frame:ClearAllPoints()
            if frame:IsShown() and ShowUIPanel then
                frame:Hide()
                ShowUIPanel(frame)
            end
        end
    end

    -- re-arm dragging if the option is still on
    MovableWindows:Update()
end
