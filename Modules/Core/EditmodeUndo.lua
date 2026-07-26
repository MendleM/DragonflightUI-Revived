local addonName, addonTable = ...;
local DF = LibStub('AceAddon-3.0'):GetAddon('DragonflightUI')

-- Undo and redo for edit mode.
--
-- Two things change a setting, and they do not share a path. Anything on a
-- settings page goes through DragonflightUIModulesMixin:SetOption, while an
-- edit-mode drag writes anchor/anchorFrame/anchorParent/x/y straight onto the
-- module's profile table in OnDragStop. Both call Capture below, so both are
-- undone the same way.
--
-- What gets stored is a copy of the affected profile sub-table before and after
-- the change, rather than a description of the change itself. A drag, a slider,
-- a dropdown and the Detach button all move different numbers of fields, and
-- with whole-table snapshots none of that needs a case of its own.
local Undo = {}
addonTable.EditmodeUndo = Undo

local MAX_STEPS = 50

local undoStack = {}
local redoStack = {}

-- Only while edit mode is open, and never while we are the ones writing.
local recording = false
local applying = false

local function CopyTable(t)
    if type(t) ~= 'table' then return t end

    local out = {}
    for k, v in pairs(t) do out[k] = (type(v) == 'table') and CopyTable(v) or v end
    return out
end

-- Restore in place, never by replacing the table. Modules hold onto their
-- profile sub-table - frames keep it as self.state - so swapping the table for
-- a new one would leave them reading a copy nothing else writes to.
local function RestoreInto(target, saved)
    if type(target) ~= 'table' or type(saved) ~= 'table' then return end

    for k in pairs(target) do
        if saved[k] == nil then target[k] = nil end
    end
    for k, v in pairs(saved) do target[k] = (type(v) == 'table') and CopyTable(v) or v end
end

local function Describe(step)
    if step.label and step.label ~= '' then return step.label end

    local name = (step.module and step.module.GetName and step.module:GetName()) or '?'
    return name .. (step.key and (' - ' .. tostring(step.key)) or '')
end

-- A toast rather than a chat line. Undo is a rapid, repeated action and the
-- interesting part is which frame just moved back - that belongs on screen, next
-- to the thing that moved, not scrolling past in chat behind a combat log.
local toast
local function ShowToast(action, what)
    if not toast then
        toast = CreateFrame('Frame', 'DragonflightUIUndoToast', UIParent, 'BackdropTemplate')
        toast:SetSize(320, 46)
        toast:SetPoint('TOP', UIParent, 'TOP', 0, -260)
        toast:SetFrameStrata('TOOLTIP')
        toast:SetBackdrop({
            bgFile = 'Interface\\DialogFrame\\UI-DialogBox-Background-Dark',
            edgeFile = 'Interface\\Tooltips\\UI-Tooltip-Border',
            tile = true,
            tileSize = 32,
            edgeSize = 12,
            insets = {left = 3, right = 3, top = 3, bottom = 3}
        })
        toast:SetBackdropBorderColor(1, 0.82, 0, 0.9)
        toast:Hide()

        local title = toast:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
        title:SetPoint('TOPLEFT', toast, 'TOPLEFT', 12, -9)
        toast.Title = title

        local detail = toast:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
        detail:SetPoint('TOPLEFT', title, 'BOTTOMLEFT', 0, -3)
        detail:SetPoint('RIGHT', toast, 'RIGHT', -12, 0)
        detail:SetJustifyH('LEFT')
        detail:SetWordWrap(false)
        toast.Detail = detail
    end

    toast.Title:SetText('|cffffd100' .. action .. '|r')
    toast.Detail:SetText(what or '')

    -- Restart cleanly: undo is usually pressed several times in a row, and a
    -- fade already in flight would otherwise carry on from wherever it had got
    -- to and blink the new message straight back out.
    UIFrameFadeRemoveFrame(toast)
    toast:SetAlpha(1)
    toast:Show()

    if toast.Timer then toast.Timer:Cancel() end
    toast.Timer = C_Timer.NewTimer(1.6, function()
        if toast:IsShown() then UIFrameFadeOut(toast, 0.6, toast:GetAlpha(), 0) end
    end)
end

-- Run `mutate`, recording what it did to profile[key] so it can be taken back.
-- Callers that are not recording (edit mode closed) just get the mutation.
function Undo:Capture(module, key, mutate, label)
    if not (recording and not applying and module and module.db and key) then
        mutate()
        return
    end

    local target = module.db.profile[key]
    if type(target) ~= 'table' then
        -- a scalar directly on the profile; snapshot the value itself
        local before = module.db.profile[key]
        mutate()
        self:Push({
            module = module,
            key = key,
            label = label,
            scalar = true,
            before = before,
            after = module.db.profile[key]
        })
        return
    end

    local before = CopyTable(target)
    mutate()
    self:Push({module = module, key = key, label = label, before = before, after = CopyTable(target)})
end

function Undo:Push(step)
    -- A fresh change ends whatever redo history was hanging around, the same as
    -- typing after undoing in any other editor.
    wipe(redoStack)

    undoStack[#undoStack + 1] = step
    while #undoStack > MAX_STEPS do table.remove(undoStack, 1) end
end

local function Apply(step, saved)
    applying = true

    if step.scalar then
        step.module.db.profile[step.key] = saved
    else
        RestoreInto(step.module.db.profile[step.key], saved)
    end

    local ok, err = pcall(function()
        step.module:ApplySettings(step.key)
        if step.module.RefreshOptionScreens then step.module:RefreshOptionScreens() end
    end)

    applying = false

    if not ok then geterrorhandler()('DFUI edit mode undo: ' .. tostring(err)) end
end

-- Undo and redo both move settings, which moves protected frames.
local function BlockedByCombat()
    if not InCombatLockdown() then return false end
    ShowToast('Not in combat', 'The game will not let frames be moved mid-fight.')
    return true
end

function Undo:Undo()
    if BlockedByCombat() then return end

    local step = table.remove(undoStack)
    if not step then
        ShowToast('Nothing to undo', '')
        return
    end

    Apply(step, step.before)
    redoStack[#redoStack + 1] = step
    ShowToast('Undone', Describe(step))
end

function Undo:Redo()
    if BlockedByCombat() then return end

    local step = table.remove(redoStack)
    if not step then
        ShowToast('Nothing to redo', '')
        return
    end

    Apply(step, step.after)
    undoStack[#undoStack + 1] = step
    ShowToast('Redone', Describe(step))
end

-- Ctrl+Z / Cmd+Z, Ctrl+Y and Ctrl+Shift+Z, live only while the edit mode panel
-- is up.
--
-- Keyboard input is propagated by default and only swallowed for the keys we
-- actually act on, so typing in chat, the settings search box and everything
-- else carries on working. The flag persists once set, hence resetting it at
-- the top of every keypress rather than only when we handle one.
local function InstallKeys(frame)
    if frame.DFUndoKeysInstalled then return end
    frame.DFUndoKeysInstalled = true

    frame:EnableKeyboard(true)
    frame:SetPropagateKeyboardInput(true)

    frame:SetScript('OnKeyDown', function(self, key)
        self:SetPropagateKeyboardInput(true)

        -- someone is typing
        if ChatEdit_GetActiveWindow and ChatEdit_GetActiveWindow() then return end
        -- Cmd on a Mac. Guarded: IsMetaKeyDown is not present on every flavour,
        -- and an unguarded call here would error on every keypress.
        if not (IsControlKeyDown() or (IsMetaKeyDown and IsMetaKeyDown())) then return end

        if key == 'Z' then
            self:SetPropagateKeyboardInput(false)
            if IsShiftKeyDown() then Undo:Redo() else Undo:Undo() end
        elseif key == 'Y' then
            self:SetPropagateKeyboardInput(false)
            Undo:Redo()
        end
    end)
end

-- Called by the edit mode module as the mode opens and closes. The history is
-- the session's, not the profile's: closing edit mode ends it.
function Undo:SetActive(active)
    recording = active and true or false

    if not active then
        wipe(undoStack)
        wipe(redoStack)
    end

    local module = DF:GetModule('Editmode', true)
    local frame = module and module.EditModeFrame
    if not frame then return end

    if active then
        InstallKeys(frame)
    elseif frame.DFUndoKeysInstalled then
        frame:SetPropagateKeyboardInput(true)
    end
end
