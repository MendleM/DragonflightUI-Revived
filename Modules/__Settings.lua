local DF = LibStub('AceAddon-3.0'):GetAddon('DragonflightUI')
local L = LibStub("AceLocale-3.0"):GetLocale("DragonflightUI")

DF.Settings = DF.Settings or {}

DF.Settings.DropdownAnchorTable = {
    {value = 'CENTER', text = 'CENTER', tooltip = 'descr', label = 'label'},
    {value = 'TOP', text = 'TOP', tooltip = 'descr', label = 'label'},
    {value = 'RIGHT', text = 'RIGHT', tooltip = 'descr', label = 'label'},
    {value = 'BOTTOM', text = 'BOTTOM', tooltip = 'descr', label = 'label'},
    {value = 'LEFT', text = 'LEFT', tooltip = 'descr', label = 'label'},
    {value = 'TOPRIGHT', text = 'TOPRIGHT', tooltip = 'descr', label = 'label'},
    {value = 'TOPLEFT', text = 'TOPLEFT', tooltip = 'descr', label = 'label'},
    {value = 'BOTTOMLEFT', text = 'BOTTOMLEFT', tooltip = 'descr', label = 'label'},
    {value = 'BOTTOMRIGHT', text = 'BOTTOMRIGHT', tooltip = 'descr', label = 'label'}
}

DF.Settings.DropdownCrossAnchorTable = {
    {value = 'TOP', text = 'TOP', tooltip = 'descr', label = 'label'},
    {value = 'RIGHT', text = 'RIGHT', tooltip = 'descr', label = 'label'},
    {value = 'BOTTOM', text = 'BOTTOM', tooltip = 'descr', label = 'label'},
    {value = 'LEFT', text = 'LEFT', tooltip = 'descr', label = 'label'}
}

DF.Settings.DropdownTopBottomAnchorTable = {
    {value = 'TOP', text = 'TOP', tooltip = 'descr', label = 'label'},
    {value = 'BOTTOM', text = 'BOTTOM', tooltip = 'descr', label = 'label'}
}

DF.Settings.OrientationTable = {
    {value = 'horizontal', text = 'Horizontal', tooltip = 'descr', label = 'label'},
    {value = 'vertical', text = 'Vertical', tooltip = 'descr', label = 'label'}
}

DF.Settings.FlyoutDirectionTable = {
    {value = 'UP', text = 'Up', tooltip = 'descr', label = 'label'},
    {value = 'RIGHT', text = 'Right', tooltip = 'descr', label = 'label'},
    {value = 'DOWN', text = 'Down', tooltip = 'descr', label = 'label'},
    {value = 'LEFT', text = 'Left', tooltip = 'descr', label = 'label'}
}

DF.Settings.GrowthDirectionTable = {
    {value = 'up', text = 'Up', tooltip = 'descr', label = 'label'},
    {value = 'down', text = 'Down', tooltip = 'descr', label = 'label'}
}

DF.Settings.ModifierTable = {
    {value = 'NONE', text = NONE_KEY, tooltip = 'descr', label = 'label'},
    {value = 'ALT', text = ALT_KEY, tooltip = 'descr', label = 'label'},
    {value = 'CTRL', text = CTRL_KEY, tooltip = 'descr', label = 'label'},
    {value = 'SHIFT', text = SHIFT_KEY, tooltip = 'descr', label = 'label'}
}

DF.Settings.ModifierTableWithoutNone = {
    {value = 'ALT', text = ALT_KEY, tooltip = 'descr', label = 'label'},
    {value = 'CTRL', text = CTRL_KEY, tooltip = 'descr', label = 'label'},
    {value = 'SHIFT', text = SHIFT_KEY, tooltip = 'descr', label = 'label'}
}

DF.Settings.ValidateFrame = function(t)
    if not t or t == '' then return false end
    local f = _G[t];

    if f and f.SetPoint then
        return true
    else
        return false
    end
    -- local result, target = SecureCmdOptionParse(t)
    -- if result ~= 'show' and result ~= 'hide' and result ~= '' then
    --     Module:Print('|cFFFF0000Error: Custom Condition for ' .. displayName .. ' does not return ' ..
    --                      [['show' or 'hide'!|r]])
    --     return
    -- end

    -- -- valid
    -- Module:Print('Set Custom Condition for ' .. displayName .. ': \'' .. t .. '\'')
    -- Module:Print('Current Value: ' .. result)

    -- -- valid, reset
    -- return true, true;
end

-- Stand a frame on its own without moving it.
--
-- Several elements are anchored to each other by default - the main action bar
-- sits on the reputation bar, which sits on the XP bar - so dragging one takes
-- the others with it. The Anchor Frame dropdown could always break that chain,
-- but switching it to UIParent made the frame jump, because the saved x/y were
-- measured from the old parent. Nobody wants to detach and then hunt for their
-- bar.
--
-- So let the engine do the conversion. StartMoving followed immediately by
-- StopMovingOrSizing - with no cursor movement in between - leaves the frame
-- exactly where it was, re-anchored against the screen with the offsets worked
-- out for us. Read that back and store it. No scale arithmetic, which is the
-- part that goes wrong when a frame carries its own scale.
-- Which frame belongs to which (module, sub), so the Stand On Its Own checkbox
-- can find it. Registered by AddPositionTable, and only where the caller can
-- supply one.
DF.Settings.StandaloneFrames = DF.Settings.StandaloneFrames or {}

function DF.Settings:RegisterStandaloneFrame(Module, sub, frameGetter)
    self.StandaloneFrames[Module] = self.StandaloneFrames[Module] or {}
    self.StandaloneFrames[Module][sub] = frameGetter
end

-- The checkbox was set. On means stand alone, off means go back to what it was
-- attached to.
function DF.Settings:OnStandaloneChanged(Module, sub, value)
    local byModule = self.StandaloneFrames[Module]
    local frameGetter = byModule and byModule[sub]
    if not frameGetter then return end

    if value then
        self:DetachFrame(Module, sub, frameGetter)
    else
        self:ReattachFrame(Module, sub, frameGetter)
    end
end

-- Put it back on whatever it was attached to before it was detached, at the
-- offsets it had then, so ticking and unticking round-trips exactly. With
-- nothing remembered - a fresh profile, or something detached in an older
-- session - fall back to how the element shipped.
function DF.Settings:ReattachFrame(Module, sub, frameGetter)
    local db = Module.db and Module.db.profile and Module.db.profile[sub]
    if not db then return end

    local saved = db.DFAttachedTo
    local source = saved or (Module.defaults and Module.defaults.profile and Module.defaults.profile[sub])
    if not source then return end

    db.anchorFrame = source.anchorFrame
    db.customAnchorFrame = source.customAnchorFrame or ''
    db.anchor = source.anchor
    db.anchorParent = source.anchorParent
    db.x = source.x
    db.y = source.y
    db.DFAttachedTo = nil

    Module:ApplySettings(sub)
    if Module.RefreshOptionScreens then Module:RefreshOptionScreens() end
end

function DF.Settings:DetachFrame(Module, sub, frameGetter)
    local frame = frameGetter and frameGetter()
    if not frame then return end

    local db = Module.db and Module.db.profile and Module.db.profile[sub]
    if not db then return end

    -- Moving a secure frame is protected work, and these include action bars.
    if InCombatLockdown() then
        print('|cffFF0000DragonflightUI:|r cannot detach a frame during combat - try again afterwards.')
        return
    end

    local wasMovable = frame:IsMovable()
    frame:SetMovable(true)
    frame:StartMoving()
    frame:StopMovingOrSizing()
    frame:SetMovable(wasMovable)

    local point, _, relativePoint, x, y = frame:GetPoint(1)
    if not point then return end

    -- Remember what it was on, so unticking can put it back exactly.
    db.DFAttachedTo = {
        anchorFrame = db.anchorFrame,
        customAnchorFrame = db.customAnchorFrame,
        anchor = db.anchor,
        anchorParent = db.anchorParent,
        x = db.x,
        y = db.y
    }

    db.anchorFrame = 'UIParent'
    db.customAnchorFrame = ''
    db.anchor = point
    db.anchorParent = relativePoint or point
    db.x = x or 0
    db.y = y or 0

    Module:ApplySettings(sub)
    -- not every module defines one
    if Module.RefreshOptionScreens then Module:RefreshOptionScreens() end
end

function DF.Settings:AddPositionTable(Module, optionTable, sub, displayName, getDefaultStr, frameTable, frameGetter)
    local extraOptions = {
        headerPosition = {
            type = 'header',
            name = L["PositionTableHeader"],
            desc = L["PositionTableHeaderDesc"],
            order = 0,
            isExpanded = true,
            editmode = true
        },
        scale = {
            type = 'range',
            name = L["PositionTableScale"],
            desc = L["PositionTableScaleDesc"] .. getDefaultStr('scale', sub),
            min = 0.1,
            max = 5,
            bigStep = 0.05,
            order = 1,
            group = 'headerPosition',
            editmode = true
        },
        anchor = {
            type = 'select',
            name = L["PositionTableAnchor"],
            desc = L["PositionTableAnchorDesc"] .. getDefaultStr('anchor', sub),
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
            group = 'headerPosition',
            editmode = true
        },
        anchorParent = {
            type = 'select',
            name = L["PositionTableAnchorParent"],
            desc = L["PositionTableAnchorParentDesc"] .. getDefaultStr('anchorParent', sub),
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
            group = 'headerPosition',
            editmode = true
        },
        anchorFrame = {
            type = 'select',
            name = L["PositionTableAnchorFrame"],
            desc = L["PositionTableAnchorFrameDesc"] .. getDefaultStr('anchorFrame', sub),
            values = frameTable,
            dropdownValues = frameTable,
            order = 4,
            group = 'headerPosition',
            editmode = true
        },
        customAnchorFrame = {
            type = 'editbox',
            name = L["PositionTableCustomAnchorFrame"],
            desc = L["PositionTableCustomAnchorFrameDesc"] .. getDefaultStr('customAnchorFrame', sub),
            Validate = DF.Settings.ValidateFrame,
            order = 4.5,
            group = 'headerPosition',
            editmode = true
        },
        x = {
            type = 'range',
            name = L["PositionTableX"],
            desc = L["PositionTableXDesc"] .. getDefaultStr('x', sub),
            min = -2500,
            max = 2500,
            bigStep = 1,
            order = 5,
            group = 'headerPosition',
            editmode = true
        },
        y = {
            type = 'range',
            name = L["PositionTableY"],
            desc = L["PositionTableYDesc"] .. getDefaultStr('y', sub),
            min = -2500,
            max = 2500,
            bigStep = 1,
            order = 6,
            group = 'headerPosition',
            editmode = true
        }
    }

    -- Only offered where the caller can hand us the frame. It is a getter
    -- rather than the frame itself because these tables are built at file
    -- scope, long before the frames exist.
    if frameGetter then
        DF.Settings:RegisterStandaloneFrame(Module, sub, frameGetter)

        -- Seed the default so the page's Defaults button clears the tick along
        -- with the anchor it resets. SetDefaultSubValues copies the defaults
        -- over the profile, so without an entry here the box would stay ticked
        -- while the anchor underneath it went back to attached. Every caller
        -- runs SetDefaults before building its option tables.
        local moduleDefaults = Module.defaults and Module.defaults.profile and Module.defaults.profile[sub]
        if moduleDefaults and moduleDefaults.standalone == nil then moduleDefaults.standalone = false end

        -- First thing in the Position group, because it decides whether any of
        -- the settings under it are about another frame or about the screen.
        extraOptions.standalone = {
            type = 'toggle',
            name = L["PositionTableStandalone"],
            desc = L["PositionTableStandaloneDesc"] .. getDefaultStr('standalone', sub),
            order = 0.5,
            group = 'headerPosition',
            editmode = true
        }
    end

    for k, v in pairs(extraOptions) do
        --
        optionTable.args[k] = v
    end
end
