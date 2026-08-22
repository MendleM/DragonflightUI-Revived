local addonName, addonTable = ...;
local Helper = addonTable.Helper;
local DF = LibStub('AceAddon-3.0'):GetAddon('DragonflightUI')
local mName = 'Chat'
local Module = DF:NewModule(mName, 'AceConsole-3.0', 'AceHook-3.0')

Mixin(Module, DragonflightUIModulesMixin)

local defaults = {
    profile = {
        scale = 1,
        anchorFrame = 'UIParent',
        customAnchorFrame = '',
        anchor = 'BOTTOMLEFT',
        anchorParent = 'BOTTOMLEFT',
        x = 42,
        y = 35,
        sizeX = 460,
        sizeY = 207,
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
        hideCustom = false,
        hideCustomCond = ''
    }
}
Module:SetDefaults(defaults)

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

local frameTable = {{value = 'UIParent', text = 'UIParent', tooltip = 'descr', label = 'label'}}

local options = {
    type = 'group',
    name = 'DragonflightUI - ' .. mName,
    get = getOption,
    set = setOption,
    args = {
        scale = {
            type = 'range',
            name = 'Scale',
            desc = '' .. getDefaultStr('scale'),
            min = 0.2,
            max = 5,
            bigStep = 0.1,
            order = 1,
            disabled = true,
            editmode = true
        },
        anchorFrame = {
            type = 'select',
            name = 'Anchorframe',
            desc = 'Anchor' .. getDefaultStr('anchorFrame'),
            dropdownValues = frameTable,
            values = frameTable,
            order = 4,
            editmode = true
        },
        anchor = {
            type = 'select',
            name = 'Anchor',
            desc = 'Anchor' .. getDefaultStr('anchor'),
            values = {
                ['TOP'] = 'TOP',
                ['RIGHT'] = 'RIGHT',
                ['BOTTOM'] = 'BOTTOM',
                ['LEFT'] = 'LEFT',
                ['TOPRIGHT'] = 'TOPRIGHT',
                ['TOPLEFT'] = 'TOPLEFT',
                ['BOTTOMLEFT'] = 'BOTTOMLEFT',
                ['BOTTOMRIGHT'] = 'BOTTOMRIGHT',
                ['CENTER'] = 'CENTER'
            },
            dropdownValues = DF.Settings.DropdownAnchorTable,
            order = 2,
            editmode = true
        },
        anchorParent = {
            type = 'select',
            name = 'AnchorParent',
            desc = 'AnchorParent' .. getDefaultStr('anchorParent'),
            values = {
                ['TOP'] = 'TOP',
                ['RIGHT'] = 'RIGHT',
                ['BOTTOM'] = 'BOTTOM',
                ['LEFT'] = 'LEFT',
                ['TOPRIGHT'] = 'TOPRIGHT',
                ['TOPLEFT'] = 'TOPLEFT',
                ['BOTTOMLEFT'] = 'BOTTOMLEFT',
                ['BOTTOMRIGHT'] = 'BOTTOMRIGHT',
                ['CENTER'] = 'CENTER'
            },
            dropdownValues = DF.Settings.DropdownAnchorTable,
            order = 3,
            editmode = true
        },
        x = {
            type = 'range',
            name = 'X',
            desc = 'X relative to BOTTOM LEFT' .. getDefaultStr('x'),
            min = 0,
            max = 3500,
            bigStep = 1,
            order = 5,
            editmode = true
        },
        y = {
            type = 'range',
            name = 'Y',
            desc = 'Y relative to BOTTOM LEFT' .. getDefaultStr('y'),
            min = 0,
            max = 3500,
            bigStep = 1,
            order = 6,
            editmode = true
        },
        sizeX = {
            type = 'range',
            name = 'Size X',
            desc = 'Size X' .. getDefaultStr('sizeX'),
            min = 0,
            max = 1000,
            bigStep = 1,
            order = 10,
            editmode = true
        },
        sizeY = {
            type = 'range',
            name = 'Size Y',
            desc = 'Size Y' .. getDefaultStr('sizeY'),
            min = 0,
            max = 1000,
            bigStep = 1,
            order = 11,
            editmode = true
        }
    }
}
-- DragonflightUIStateHandlerMixin:AddStateTable(Module, options, nil, 'Chat', getDefaultStr, setOption)

function Module:OnInitialize()
    DF:Debug(self, 'Module ' .. mName .. ' OnInitialize()')
    self.db = DF.db:RegisterNamespace(mName, defaults)
    hooksecurefunc(DF:GetModule('Config'), 'AddConfigFrame', function()
        Module:RegisterSettings()
    end)

    self:SetEnabledState(DF.ConfigModule:GetModuleEnabled(mName))

    DF:RegisterModuleOptions(mName, options)
end

function Module:OnEnable()
    DF:Debug(self, 'Module ' .. mName .. ' OnEnable()')
    self:SetWasEnabled(true)

    self:EnableAddonSpecific()

    -- Module.AddStateUpdater()
    -- The registration below was written but never called, which is why the
    -- chat window could not be selected or moved in DFUI's edit mode.
    if ChatFrame1 then
        local ok, err = pcall(function() Module:AddEditMode() end)
        if not ok then geterrorhandler()('DFUI Chat:AddEditMode: ' .. tostring(err)) end
    end

    Module:ApplySettings()
    DF.ConfigModule:RegisterSettingsData('chat', 'misc', {name = 'Chat', options = options, default = setDefaultValues})

    self:SecureHook(DF, 'RefreshConfig', function()
        -- print('RefreshConfig', mName)
        Module:ApplySettings()
        Module:RefreshOptionScreens()
    end)

    -- Selecting another tab re-runs the dock layout, which is where a broken
    -- mirror shows up. FCF_SelectDockFrame calls FCF_DockUpdate itself, so
    -- hooking the one entry point is enough; coalesce to one pass per frame.
    local dockFixPending
    if FCF_DockUpdate then
        self:SecureHook('FCF_DockUpdate', function()
            if dockFixPending then return end
            dockFixPending = true
            C_Timer.After(0, function()
                dockFixPending = false
                Module.FixDockedFrames()
            end)
        end)
    end

    -- Leaving the dock does NOT go through FCF_DockUpdate (FCF_UnDockFrame
    -- calls FCFDock_RemoveChatFrame and stops), and undocking happens by
    -- dragging the tab - so the window is already under the cursor and on its
    -- way somewhere by the time any later pass would run. Restore its clamping
    -- at the one choke point every frame leaves the dock through.
    if FCFDock_RemoveChatFrame then
        self:SecureHook('FCFDock_RemoveChatFrame', function(_, chatFrame)
            Module.SetDockClamping(chatFrame, false)
        end)
    end
end

function Module:OnDisable()
end

function Module:RegisterSettings()
    local moduleName = 'Chat'
    local cat = 'misc'
    local function register(name, data)
        data.module = moduleName;
        DF.ConfigModule:RegisterSettingsElement(name, cat, data, true)
    end

    register('chat', {order = 1, name = 'Chat', descr = 'Chatss', isNew = false})
end

function Module:RefreshOptionScreens()
    -- print('Module:RefreshOptionScreens()')

    local configFrame = DF.ConfigModule.ConfigFrame

    local refreshCat = function(name)
        configFrame:RefreshCatSub('Misc', name)
    end

    refreshCat('Chat')
    if ChatFrame1 and ChatFrame1.DFEditModeSelection then
        ChatFrame1.DFEditModeSelection:RefreshOptionScreen();
    end
end

function Module:ApplySettings(sub, key)
    Helper:Benchmark(string.format('ApplySettings(%s,%s)', tostring(sub), tostring(key)), function()
        Module:ApplySettingsInternal(sub, key)
    end, 0, self)
end

function Module:ApplySettingsInternal(sub, key)
    local db = Module.db.profile

    local parent;
    if DF.Settings.ValidateFrame(db.customAnchorFrame) then
        parent = _G[db.customAnchorFrame]
    else
        parent = _G[db.anchorFrame]
    end
    if not parent then parent = UIParent end

    -- ChatFrame1 is a Blizzard edit-mode system on 1.15.9+ (it inherits
    -- EditModeChatFrameSystemTemplate), so every layout application runs
    -- ApplySystemAnchor on it: ClearAllPoints followed by the layout's own
    -- anchor. Without clearing first we simply ADD a point to whatever
    -- Blizzard left behind, and a chat frame held by two anchors ignores
    -- SetSize on that axis - which is how it ends up stretched and offset
    -- instead of moved.
    ChatFrame1:ClearAllPoints()
    ChatFrame1:SetPoint(db.anchor, parent, db.anchorParent, db.x, db.y)
    ChatFrame1:SetSize(db.sizeX, db.sizeY)
    ChatFrame1:SetUserPlaced(true)

    Module.FixDockedFrames()

    -- ChatFrame1:UpdateStateHandler(db)
end

-- Docked chat windows are not positioned individually: FCFDock_AddChatFrame
-- anchors them with SetAllPoints(dock.primary) once, when they dock, and
-- Blizzard never re-establishes that (FCFDock_AddChatFrame returns early for
-- an already-docked frame). Two things then go wrong once the chat is not in
-- its stock place:
--   * anything that clears a docked frame's points - an undock/redock, a
--     FCF_RestorePositionAndDimensions while the saved dock info is stale -
--     leaves that tab stranded at its own saved position for the session.
--   * only ChatFrame1 gets edit-mode clamp insets. Its siblings keep the
--     stock ones from FloatingChatFrame_UpdateBackgroundAnchors, whose
--     bottom inset of -50 forces them to stay 50px above the screen edge.
--     Mirroring a primary placed lower than that, they clamp themselves
--     upwards, so every tab past the first renders shifted up - the chat
--     background and edit box included.
-- The mirror makes their own clamping pointless anyway (the primary is
-- clamped for them), so drop it and re-assert the mirror.

-- Which frames we switched clamping off for, and what it was set to before.
--
-- Dropping it is only right for as long as the frame is docked: a docked tab
-- is positioned entirely by the primary, but an undocked one moves on its own
-- again and without clamping it can be dragged past the screen edge and lost
-- for the session. Blizzard does not put it back - FCF_UnDockFrame never
-- touches clampedToScreen - so that is ours to undo. Remember the previous
-- value rather than assuming the XML default of true: another addon may have
-- had its own opinion about a frame first, and restoring is not the same as
-- overruling.
local priorClamp = setmetatable({}, {__mode = 'k'})

function Module.SetDockClamping(chatFrame, docked)
    if not (chatFrame and chatFrame.SetClampedToScreen) then return end

    if docked then
        if priorClamp[chatFrame] == nil then
            -- IsClampedToScreen is not exercised anywhere in the 1.15.9 UI
            -- source; if it is missing, the template default (true) stands.
            priorClamp[chatFrame] = (chatFrame.IsClampedToScreen == nil) or chatFrame:IsClampedToScreen()
            chatFrame:SetClampedToScreen(false)
        end
    elseif priorClamp[chatFrame] ~= nil then
        chatFrame:SetClampedToScreen(priorClamp[chatFrame])
        priorClamp[chatFrame] = nil
    end
end

-- The combat log needs a strip of its own above the mirror.
--
-- Its quick button bar ("My actions", "What happened to me?") is anchored to
-- the log's own top edge, which is where the dock keeps its tabs - so Blizzard
-- wraps FCF_DockUpdate to call Blizzard_CombatLog_AdjustCombatLogHeight, which
-- pushes the docked log's TOPLEFT down by the bar's height and leaves the tab
-- row clear. Re-anchoring the mirror above discards that: SetAllPoints pins the
-- log flush against the primary again. Blizzard's adjustment runs inside
-- FCF_DockUpdate and ours a frame later, so ours is the one that sticks, and
-- the bar sits on top of the tabs. Blizzard's function is a local, so redo what
-- it does - keeping its anchor, offsetting only the height.
local function ReserveCombatLogQuickButtons(dock)
    local log = COMBATLOG
    if not (log and log.isDocked and log ~= dock.primary and log.CombatLogQuickButtonFrame) then return end

    local height = log.CombatLogQuickButtonFrame:GetHeight()
    if not height or height <= 0 then return end

    for i = 1, log:GetNumPoints() do
        local point, relativeTo, relativePoint, x = log:GetPoint(i)
        if point == 'TOPLEFT' then
            log:SetPoint('TOPLEFT', relativeTo, relativePoint, x, -height)
            return
        end
    end
end

function Module.FixDockedFrames()
    local dock = GENERAL_CHAT_DOCK
    if not (dock and dock.primary and FCFDock_GetChatFrames) then return end

    for _, chatFrame in ipairs(FCFDock_GetChatFrames(dock)) do
        Module.SetDockClamping(chatFrame, chatFrame ~= dock.primary)
    end

    -- Anything that left the dock without passing through the
    -- FCFDock_RemoveChatFrame hook in OnEnable - a frame docked at login and
    -- undocked from saved settings, or one promoted to primary - is caught
    -- here on the next pass.
    for chatFrame in pairs(priorClamp) do
        if chatFrame == dock.primary or not chatFrame.isDocked then
            Module.SetDockClamping(chatFrame, false)
        end
    end

    if FCFDock_ForceReanchoring then FCFDock_ForceReanchoring(dock) end

    ReserveCombatLogQuickButtons(dock)
end

local frame = CreateFrame('FRAME', 'DragonflightUIChatFrame', UIParent)

function Module.AddStateUpdater()
    Mixin(ChatFrame1, DragonflightUIStateHandlerMixin)
    ChatFrame1:InitStateHandler()
    -- Minimap:SetHideFrame(frame.CalendarButton, 2)
end

function Module:AddEditMode()
    local EditModeModule = DF:GetModule('Editmode');
    EditModeModule:AddEditModeToFrame(ChatFrame1)

    ChatFrame1.DFEditModeSelection:SetGetLabelTextFunction(function()
        return 'Chat'
    end)

    ChatFrame1.DFEditModeSelection:RegisterOptions({
        name = 'Chat',
        options = options,
        default = setDefaultValues,
        moduleRef = self
    });
end

function Module.ChangeSizeAndPosition()
    ChatFrame1:SetPoint('BOTTOMLEFT', UIParent, 'BOTTOMLEFT', 42, 35)
    ChatFrame1:SetSize(420 + 40, 200 + 7)
end

function frame:OnEvent(event, arg1)
    -- print('event', event)
    if event == 'PLAYER_ENTERING_WORLD' then
        -- Module.ChangeSizeAndPosition()
        Module:ApplySettings()
    elseif event == 'UPDATE_FLOATING_CHAT_WINDOWS' or event == 'UPDATE_CHAT_WINDOWS' then
        -- Blizzard rebuilds every window from its saved settings here, size
        -- and dock included; our position has to be the last word.
        Module:ApplySettings()
    elseif event == 'DISPLAY_SIZE_CHANGED' or event == 'UI_SCALE_CHANGED' then
        -- Going windowed, resizing the window, or any UI scale change re-lays
        -- the chat frame out from Blizzard's saved position, and ours was not
        -- being re-applied afterwards. tando_san: "when in windowed mode or
        -- when zoning the chat window does not honor the anchor settings".
        Module:ApplySettings()
    end
end
frame:SetScript('OnEvent', frame.OnEvent)

function Module:Era()
    Module:Wrath()
end

function Module:TBC()
    -- This was empty, so on TBC nothing ever re-applied the anchor: the
    -- settings were written once at load and the first thing to move the frame
    -- afterwards kept it. Every other flavour has registered these all along,
    -- which is why the report is TBC-specific.
    Module:Wrath()
end

function Module:Wrath()
    frame:RegisterEvent('PLAYER_ENTERING_WORLD')
    frame:RegisterEvent('UPDATE_FLOATING_CHAT_WINDOWS')
    frame:RegisterEvent('UPDATE_CHAT_WINDOWS')
    frame:RegisterEvent('DISPLAY_SIZE_CHANGED')
    frame:RegisterEvent('UI_SCALE_CHANGED')
end

function Module:Cata()
    Module:Wrath()
end

function Module:Mists()
    Module:Wrath()
end
