local addonName, addonTable = ...;
local DF = addonTable.DF;
local L = addonTable.L;
local Helper = addonTable.Helper;

local RangeCheck = LibStub("LibRangeCheck-3.0")

local subModuleName = 'FocusTarget';
local SubModuleMixin = {};
addonTable.SubModuleMixins[subModuleName] = SubModuleMixin;

function SubModuleMixin:Init()
    self.ModuleRef = DF:GetModule('Unitframe')
    self:SetDefaults()
    self:SetupOptions()

    local f = _G['DragonflightUIFocusToTFrame']
    if f then
        f:SetSize(120, 49)
        f:SetParent(UIParent)
        f:SetScale(1.0)
        f:SetClampedToScreen(true)
        f:SetMovable(true)
        f:EnableMouse(false)
        f:Hide()
    end
end

function SubModuleMixin:SetDefaults()
    local defaults = {
        classcolor = false,
        gradient = false,
        reactioncolor = false,
        classicon = false,
        fadeOut = false,
        fadeOutDistance = 40,
        -- breakUpLargeNumbers = true,   
        -- hideNameBackground = false,
        scale = 1.0,
        override = false,
        anchorFrame = 'FocusFrame',
        customAnchorFrame = '',
        anchor = 'BOTTOMRIGHT',
        anchorParent = 'BOTTOMRIGHT',
        x = -35 + 27,
        y = -15,
        customHealthBarTexture = 'Default',
        customPowerBarTexture = 'Default'
    };
    self.Defaults = defaults;
end

function SubModuleMixin:SetupOptions()
    local Module = self.ModuleRef;
    local function getDefaultStr(key, sub, extra)
        -- return Module:GetDefaultStr(key, sub)
        local value = self.Defaults[key]
        local defaultFormat = L["SettingsDefaultStringFormat"]
        return string.format(defaultFormat, (extra or '') .. tostring(value))
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

    local function setPreset(T, preset, sub)
        for k, v in pairs(preset) do
            --
            T[k] = v;
        end
        Module:ApplySettings(sub)
        Module:RefreshOptionScreens()
    end

    local frameTable = {
        {value = 'UIParent', text = 'UIParent', tooltip = 'descr', label = 'label'},
        {value = 'PlayerFrame', text = 'PlayerFrame', tooltip = 'descr', label = 'label'},
        {value = 'TargetFrame', text = 'TargetFrame', tooltip = 'descr', label = 'label'},
        {value = 'CompactRaidFrameManager', text = 'CompactRaidFrameManager', tooltip = 'descr', label = 'label'}
    }

    if DF.Wrath then
        table.insert(frameTable, {value = 'FocusFrame', text = 'FocusFrame', tooltip = 'descr', label = 'label'})
    end

    local function frameTableWithout(without)
        local newTable = {}

        for k, v in ipairs(frameTable) do
            --
            if v.value ~= without then
                --      
                table.insert(newTable, v);
            end
        end

        return newTable
    end

    local optionsFocusTarget = {
        name = L["FocusFrameToTName"],
        advancedName = 'FocusTargetFrame',
        sub = 'focusTarget',
        get = getOption,
        set = setOption,
        type = 'group',
        args = {
            headerStyling = {
                type = 'header',
                name = L["FocusFrameStyle"],
                desc = '',
                order = 20,
                isExpanded = true,
                editmode = true
            },
            classcolor = {
                type = 'toggle',
                name = L["FocusFrameClassColor"],
                desc = L["FocusFrameClassColorDesc"] .. getDefaultStr('classcolor', 'focusTarget'),
                group = 'headerStyling',
                order = 2,
                editmode = true
            },
            gradient = {
                type = 'toggle',
                name = L["PlayerFrameGradientColor"],
                desc = L["PlayerFrameGradientColorDesc"] .. getDefaultStr('gradient', 'focusTarget'),
                group = 'headerStyling',
                order = 2.1,
                new = true,
                editmode = true
            },
            reactioncolor = {
                type = 'toggle',
                name = L["TargetFrameReactionColor"],
                desc = L["TargetFrameReactionColorDesc"] .. getDefaultStr('reactioncolor', 'focusTarget'),
                group = 'headerStyling',
                order = 3,
                new = false,
                editmode = true
            },
            classicon = {
                type = 'toggle',
                name = L["TargetFrameClassIcon"],
                desc = L["TargetFrameClassIconDesc"] .. getDefaultStr('classicon', 'focusTarget'),
                group = 'headerStyling',
                order = 1,
                disabled = true,
                new = false,
                editmode = true
            },
            fadeOut = {
                type = 'toggle',
                name = L["TargetFrameFadeOut"],
                desc = L["TargetFrameFadeOutDesc"] .. getDefaultStr('fadeOut', 'focusTarget'),
                group = 'headerStyling',
                order = 9.5,
                new = false,
                editmode = true
            },
            fadeOutDistance = {
                type = 'range',
                name = L["TargetFrameFadeOutDistance"],
                desc = L["TargetFrameFadeOutDistanceDesc"] .. getDefaultStr('fadeOutDistance', 'focusTarget'),
                min = 0,
                max = 50,
                bigStep = 1,
                order = 9.6,
                group = 'headerStyling',
                new = false,
                editmode = true
            },
            customHealthBarTexture = {
                type = 'select',
                name = L["PlayerFrameCustomHealthbarTexture"],
                desc = L["PlayerFrameCustomHealthbarTextureDesc"] ..
                    getDefaultStr('customHealthBarTexture', 'focusTarget'),
                dropdownValuesFunc = Helper:CreateSharedMediaStatusBarGenerator(function(name)
                    return getOption({'focusTarget', 'customHealthBarTexture'}) == name;
                end, function(name)
                    setOption({'focusTarget', 'customHealthBarTexture'}, name)
                end),
                group = 'headerStyling',
                order = 4,
                new = true
            },
            customPowerBarTexture = {
                type = 'select',
                name = L["PlayerFrameCustomPowerbarTexture"],
                desc = L["PlayerFrameCustomPowerbarTextureDesc"] ..
                    getDefaultStr('customPowerBarTexture', 'focusTarget'),
                dropdownValuesFunc = Helper:CreateSharedMediaStatusBarGenerator(function(name)
                    return getOption({'focusTarget', 'customPowerBarTexture'}) == name;
                end, function(name)
                    setOption({'focusTarget', 'customPowerBarTexture'}, name)
                end),
                group = 'headerStyling',
                order = 5,
                new = true
            }
        }
    }
    DF.Settings:AddPositionTable(Module, optionsFocusTarget, 'focusTarget', 'FocusTarget', getDefaultStr, frameTable)
    local optionsFocusTargetEditmode = {
        name = 'FocusTarget',
        desc = 'Targetframedesc',
        get = getOption,
        set = setOption,
        type = 'group',
        args = {
            resetPosition = {
                type = 'execute',
                name = L["ExtraOptionsPreset"],
                btnName = L["ExtraOptionsResetToDefaultPosition"],
                desc = L["ExtraOptionsPresetDesc"],
                func = function()
                    local dbTable = Module.db.profile.focusTarget
                    local defaultsTable = self.Defaults
                    -- {scale = 1.0, anchor = 'TOPLEFT', anchorParent = 'TOPLEFT', x = -19, y = -4}
                    setPreset(dbTable, {
                        scale = defaultsTable.scale,
                        anchor = defaultsTable.anchor,
                        anchorParent = defaultsTable.anchorParent,
                        anchorFrame = defaultsTable.anchorFrame,
                        x = defaultsTable.x,
                        y = defaultsTable.y
                    })
                end,
                order = 16,
                editmode = true,
                new = false
            }
        }
    }

    self.Options = optionsFocusTarget;
    self.OptionsEditmode = optionsFocusTargetEditmode;
end

function SubModuleMixin:Setup()
    local function setDefaultSubValues(sub)
        self.ModuleRef:SetDefaultSubValues(sub)
    end

    DF.ConfigModule:RegisterSettingsData('focusTarget', 'unitframes', {
        options = self.Options,
        default = function()
            setDefaultSubValues('focusTarget')
        end
    })

    --
    self:ChangeFocusToT()
    self:ReApplyFocusToT()

    _G['FocusFrameToTManaBar'].DFUpdateFunc = function()
        self:ReApplyFocusToT()
    end

    -- FocusFrameMixin:SetSmallSize is the one thing that re-anchors and rescales
    -- this frame behind our back:
    --
    --   FocusFrameToT:SetScale(SMALL_FOCUS_UPSCALE);
    --   FocusFrameToT:SetPoint("BOTTOMRIGHT", -13, -17);
    --
    -- No relativeTo means FocusFrame, and SetPoint adds a point rather than
    -- replacing ours, so the frame ends up holding our holder point and a
    -- parent-relative one at once. FocusFrame is an Edit Mode system on both TBC
    -- Anniversary and MoP while our holder is not, so the client refuses the
    -- second point - that is the "anchor family connection" error the layout
    -- update logs. Target frame has no equivalent of SetSmallSize, which is why
    -- only the focus one ever reported it.
    --
    -- Collapse it back to our single point. The scale write lands just before
    -- the point write, so this is also the right place to restore ours.
    if not FocusFrameToT.DFPointHooked then
        FocusFrameToT.DFPointHooked = true

        hooksecurefunc(FocusFrameToT, 'SetPoint', function(frame, _, relativeTo)
            local holder = _G['DragonflightUIFocusToTFrame']
            if frame.DFSettingPoint or not holder or relativeTo == holder then return end
            if InCombatLockdown() then return end

            frame.DFSettingPoint = true

            frame:ClearAllPoints()
            frame:SetPoint('CENTER', holder, 'CENTER', 0, 0)

            local state = self.ModuleRef.db.profile.focusTarget
            if state and state.scale then frame:SetScale(state.scale) end

            frame.DFSettingPoint = false
        end)
    end

    local f = _G['DragonflightUIFocusToTFrame']
    f:SetSize(120, 49)
    f:SetParent(UIParent)
    f:SetScale(1.0)
    f:SetClampedToScreen(true)
    f:SetMovable(true)

    -- Only positions things; never take mouse input, or it swallows clicks
    -- over the frame's spot while the frame is hidden. See Target.mixin.lua.
    f:EnableMouse(false)

    if DF.API.Version.IsTBC then
        --
        -- addonTable:OverrideBlizzEditmode(FocusFrameToT, 'CENTER', f, 'CENTER', 0, 0)
    end

    -- editmode
    local EditModeModule = DF:GetModule('Editmode');
    local fakeFocus = _G['DragonflightUIEditModeFocusFramePreview']
    local fakeFocusTarget = CreateFrame('Frame', 'DragonflightUIEditModeFocusTargetOfTargetFramePreview', f,
                                        'DFEditModePreviewTargetOfTargetTemplate')
    fakeFocusTarget:OnLoad()
    fakeFocusTarget:SetParent(f)
    fakeFocusTarget:SetPoint('CENTER', f, 'CENTER', 0, 0)
    self.PreviewFocusTarget = fakeFocusTarget;

    EditModeModule:AddEditModeToFrame(f)

    f.DFEditModeSelection:SetGetLabelTextFunction(function()
        return self.Options.name
    end)

    f.DFEditModeSelection:RegisterOptions({
        options = self.Options,
        extra = self.OptionsEditmode,
        default = function()
            setDefaultSubValues('focusTarget')
        end,
        moduleRef = self.ModuleRef,
        showFunction = function()
            --         
            fakeFocusTarget:Show()
        end,
        hideFunction = function()
            --
            fakeFocusTarget:Hide()
        end
    });
end

function SubModuleMixin:OnEvent(event, ...)
end

function SubModuleMixin:UpdateState(state)
    self.state = state;
    self:Update();
end

function SubModuleMixin:Update()
    local state = self.state;
    if not state then return end

    local f_orig = FocusFrameToT
    local f = _G['DragonflightUIFocusToTFrame']

    if not f or not f_orig or not self.PreviewFocusTarget then return end

    local parent;
    if DF.Settings.ValidateFrame(state.customAnchorFrame) then
        parent = _G[state.customAnchorFrame]
    else
        parent = _G[state.anchorFrame]
    end

    f:SetScale(state.scale)
    f:ClearAllPoints()
    f:SetPoint(state.anchor, parent, state.anchorParent, state.x, state.y)
    -- f:SetUserPlaced(true)

    -- Anchor only. Never reparent this frame.
    --
    -- Blizzard's TargetOfTargetMixin reads its own parent on every update:
    --
    --   local parent = self:GetParent();
    --   if ( ... UnitExists(parent.unit) and ( not UnitIsUnit(PlayerFrame.unit,
    --        parent.unit) ) and ( UnitHealth(parent.unit) > 0 ) ) then ... else
    --        self:Hide() end
    --
    -- Reparenting onto our holder made parent.unit nil, so that condition was
    -- false on every single frame and the client hid the frame itself. The
    -- template starts hidden, so it never appeared at all - "Target of Focus
    -- not working, completely hidden" on MoP and "Focus target does not show
    -- up" on TBC, with no error to go with it.
    --
    -- The parent contract is wider than just unit: OnShow and OnHide call
    -- parent:UpdateAuras(), which the holder has no method for, and Update sets
    -- parent.haveToT and calls parent.spellbar:AdjustPosition() so FocusFrame
    -- knows to move its cast bar. A holder cannot stand in for that - haveToT
    -- is read back off FocusFrame further down the same file.
    --
    -- Target-of-target has always anchored without reparenting, on these same
    -- clients, and has none of this. This frame now does the same.
    f_orig:ClearAllPoints()
    f_orig:SetPoint('CENTER', f, 'CENTER', 0, 0)

    -- Scale the frame itself, the way target-of-target does. The holder is not
    -- its parent, so scaling the holder alone would never reach it.
    f_orig:SetScale(state.scale)

    f:SetIgnoreParentAlpha(state.fadeOut and true or false)

    self:ReApplyFocusToT()
    UnitFramePortrait_Update(FocusFrameToT)

    self.PreviewFocusTarget:UpdateState(state);
end

function SubModuleMixin:ChangeFocusToT()
    FocusFrameToT:ClearAllPoints()
    FocusFrameToT:SetPoint('BOTTOMRIGHT', FocusFrame, 'BOTTOMRIGHT', -35 + 27, -10 - 5)
    FocusFrameToT:SetSize(93 + 27, 45)

    FocusFrameToT.Portrait = FocusFrameToTPortrait;
    FocusFrameToT.Name = FocusFrameToTTextureFrameName;

    self.ModuleRef.SubTargetOfTarget:ChangeToTFrame(self, FocusFrameToT)

    FocusFrameToTTextureFrameTexture:SetTexture('')

    FocusFrameToTBackground:Hide()

    FocusFrameToTTextureFrameDeadText:ClearAllPoints()
    FocusFrameToTTextureFrameDeadText:SetPoint('CENTER', FocusFrameToTHealthBar, 'CENTER', 0, 0)

    FocusFrameToTTextureFrameUnconsciousText:ClearAllPoints()
    FocusFrameToTTextureFrameUnconsciousText:SetPoint('CENTER', FocusFrameToTHealthBar, 'CENTER', 0, 0)

    if not FocusFrameToT.DFRangeHooked then
        FocusFrameToT.DFRangeHooked = true;

        local state = self.ModuleRef.db.profile.focusTarget

        if not RangeCheck then return end
        local function updateRange()
            local minRange, maxRange = RangeCheck:GetRange('focusTarget')
            -- print(minRange, maxRange, '--', state.fadeOutDistance)

            if not state.fadeOut then
                FocusFrameToT:SetAlpha(1);
                return;
            end

            if minRange and minRange >= state.fadeOutDistance then
                FocusFrameToT:SetAlpha(0.55);
                -- print('>>0.55')
                -- elseif maxRange and maxRange >= 40 then
                --     TargetFrame:SetAlpha(0.55);
            else
                FocusFrameToT:SetAlpha(1);
                -- print('>>1.0')
            end
        end

        FocusFrameToT:HookScript('OnUpdate', updateRange)
        FocusFrameToT:HookScript('OnEvent', updateRange)
    end
end

function SubModuleMixin:ReApplyFocusToT()
    self.ModuleRef.SubTargetOfTarget:UpdateToTHealthBarTexture(FocusFrameToTHealthBar,
                                                               self.ModuleRef.db.profile.focusTarget, 'focusTarget')
    self.ModuleRef.SubTargetOfTarget:UpdateToTPowerBarTexture(FocusFrameToTManaBar,
                                                              self.ModuleRef.db.profile.focusTarget, 'focusTarget')
end
