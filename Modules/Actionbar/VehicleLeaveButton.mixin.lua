local addonName, addonTable = ...;
local DF = addonTable.DF;
local L = addonTable.L;
local Helper = addonTable.Helper;

local subModuleName = 'VehicleLeaveButton';
local SubModuleMixin = {};
addonTable.SubModuleMixins[subModuleName] = SubModuleMixin;

function SubModuleMixin:Init()
    self.ModuleRef = DF:GetModule('Actionbar')
    self:SetDefaults()
    self:SetupOptions()
end

function SubModuleMixin:SetDefaults()
    local defaults = {
        enabled = true,
        scale = 1.0,
        override = false,
        -- Left edge of the action bars, above the top one. The default stack is
        -- RepBar -> bar1 -> bar2 -> bar3, each anchored BOTTOM to the previous
        -- TOP, so bar 3 is the top of the column; BOTTOMLEFT to its TOPLEFT
        -- lines the button up with the first button of every row below it.
        --
        -- Static, like every other default anchor in this module - if bar 3 is
        -- turned off the button sits where bar 3 would have been, and the
        -- anchor is a setting you can change.
        anchorFrame = 'DragonflightUIActionbarFrame3',
        customAnchorFrame = '',
        anchor = 'BOTTOMLEFT',
        anchorParent = 'TOPLEFT',
        x = 0,
        y = 6,
        -- Appearance
        showFrame = true,
        showGlow = true,
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

    local optionsPet = {
        name = L["VehicleLeaveButton"],
        desc = L["VehicleLeaveButtonDesc"],
        advancedName = 'VehicleLeave',
        sub = 'vehicleLeave',
        get = getOption,
        set = setOption,
        type = 'group',
        args = {}
    }

    DF.Settings:AddPositionTable(Module, optionsPet, 'vehicleLeave', 'Vehicle Leave Button', getDefaultStr, frameTable)

    -- The state table below is commented out, and with it went every way of
    -- turning this button off: hideAlways, hideCombat and the rest are in the
    -- defaults but nothing ever draws them, and UpdateStateHandler is commented
    -- out in Update too. So there was no toggle at all. This is that toggle -
    -- one checkbox, not the whole conditional-visibility machinery.
    optionsPet.args.enabled = {
        type = 'toggle',
        name = 'Enable Request Stop button',
        desc = 'Show the button that leaves a vehicle or asks a flight to land early.'
            .. ' Turning this OFF hides it entirely; a /reload restores the default look.'
            .. getDefaultStr('enabled', 'vehicleLeave'),
        order = 0.5
    }

    -- The real button only exists while you are on a taxi or in a vehicle, so
    -- without this the only way to see a position or size change was to go and
    -- catch a flight. Shows the button where it will appear, lit, for a few
    -- seconds.
    optionsPet.args.preview = {
        type = 'execute',
        name = 'Preview',
        btnName = 'Show',
        desc = 'Show the button where it will appear, for a few seconds.'
            .. ' It only exists on a taxi or in a vehicle, so this is the way to place it.',
        func = function() self:ShowPreview() end,
        order = 0.6
    }

    optionsPet.args.showFrame = {
        type = 'toggle',
        name = 'Button frame',
        desc = 'Draw the action-button border around it, the same one the action and pet bars use.'
            .. getDefaultStr('showFrame', 'vehicleLeave'),
        order = 0.7
    }

    optionsPet.args.showGlow = {
        type = 'toggle',
        name = 'Glow when active',
        desc = 'Light the button with the corner glow an autocasting pet ability gets, while it can be clicked.'
            .. getDefaultStr('showGlow', 'vehicleLeave'),
        order = 0.8
    }

    -- DragonflightUIStateHandlerMixin:AddStateTable(Module, optionsPet, 'vehicleLeave', 'Vehicle Leave Button',
    --                                               getDefaultStr)
    local optionsPetEditmode = {
        name = 'Pet',
        desc = 'Pet',
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
                    local dbTable = Module.db.profile.vehicleLeave
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

    self.Options = optionsPet;
    self.OptionsEditmode = optionsPetEditmode;
end

function SubModuleMixin:Setup()
    local function setDefaultSubValues(sub)
        self.ModuleRef:SetDefaultSubValues(sub)
    end

    DF.ConfigModule:RegisterSettingsData('vehicleLeave', 'actionbar', {
        options = self.Options,
        default = function()
            setDefaultSubValues('vehicleLeave')
        end
    })

    --

    self:CreateVehicleLeaveButton()

    self:SetScript('OnEvent', self.OnEvent);
    self:RegisterEvent("PLAYER_ENTERING_WORLD");
    self:RegisterEvent("UPDATE_BONUS_ACTIONBAR");
    self:RegisterEvent("UPDATE_MULTI_CAST_ACTIONBAR");
    self:RegisterEvent("UNIT_ENTERED_VEHICLE");
    self:RegisterEvent("UNIT_EXITED_VEHICLE");
    self:RegisterEvent("VEHICLE_UPDATE");

    local f = _G['DragonflightUIVehicleLeaveButton']
    f:SetParent(UIParent)
    f:SetScale(1.0)
    f:SetClampedToScreen(true)
    f:SetMovable(true)

    -- editmode
    local EditModeModule = DF:GetModule('Editmode');

    EditModeModule:AddEditModeToFrame(f)

    f.DFEditModeSelection:SetGetLabelTextFunction(function()
        return self.Options.name
    end)

    f.DFEditModeSelection:RegisterOptions({
        options = self.Options,
        extra = self.OptionsEditmode,
        default = function()
            setDefaultSubValues(self.Options.sub)
        end,
        moduleRef = self.ModuleRef,
        showFunction = function()
            --
            SubModuleMixin.SetPreviewShown(f, true, self.state)
        end,
        hideFunction = function()
            --
            -- fakeWidget:Show()
            SubModuleMixin.SetPreviewShown(f, false)
        end
    });
end

-- Turned off in the settings. Kept as one question because the event handler
-- and the position update both have to respect it, and they run independently.
function SubModuleMixin:IsDisabled()
    return self.state ~= nil and self.state.enabled == false
end

function SubModuleMixin:OnEvent(event, ...)
    -- print('event', event, ...)
    if self:IsDisabled() then
        self:SetActiveGlow(MainMenuBarVehicleLeaveButton, false)
        MainMenuBarVehicleLeaveButton:Hide()
        return
    end

    if ((CanExitVehicle() or UnitOnTaxi("player")) and ActionBarController_GetCurrentActionBarState() ==
        LE_ACTIONBAR_STATE_MAIN) then
        --
        MainMenuBarVehicleLeaveButton:Show();
        MainMenuBarVehicleLeaveButton:Enable();
        self:SetActiveGlow(MainMenuBarVehicleLeaveButton, true)
    else
        MainMenuBarVehicleLeaveButton:SetHighlightTexture([[Interface\Buttons\ButtonHilight-Square]], "ADD");
        MainMenuBarVehicleLeaveButton:UnlockHighlight();
        self:SetActiveGlow(MainMenuBarVehicleLeaveButton, false)
        MainMenuBarVehicleLeaveButton:Hide();
    end
end

function SubModuleMixin:UpdateState(state)
    self.state = state;
    self:Update();
end

-- Names the settings offered that no frame ever answered to. The anchor
-- dropdown listed 'DragonflightUIPetBar' while the bar creates itself as
-- 'DragonflightUIPetbar', so choosing Pet Bar resolved to nil - and SetPoint
-- with a nil relativeTo quietly falls back to the frame's parent instead of
-- erroring, which is why it read as the setting doing nothing at all. Anybody
-- who picked Pet Bar meant the pet bar.
local FRAME_ALIASES = {DragonflightUIPetBar = 'DragonflightUIPetbar'}

-- Only customAnchorFrame was ever validated; anchorFrame was indexed raw out of
-- _G and handed straight to SetPoint. One missing or renamed frame was enough
-- to silently park the button on UIParent with nothing said about it.
function SubModuleMixin:ResolveAnchorFrame(state)
    if DF.Settings.ValidateFrame(state.customAnchorFrame) then return _G[state.customAnchorFrame] end

    local name = state.anchorFrame
    name = FRAME_ALIASES[name] or name

    local frame = name and _G[name]
    if frame and frame.SetPoint then return frame end

    if DF.Log then
        DF:Log('vehicleleave', 'anchor frame %s does not exist - falling back to UIParent',
               tostring(state.anchorFrame))
    end
    return UIParent
end

-- The stand-in artwork: arrow, frame, glow. Shown in edit mode and by the
-- Preview button, since the real one only exists on a taxi or in a vehicle.
-- The frame and the glow follow their own settings, or a preview would show a
-- button you have not configured.
function SubModuleMixin.SetPreviewShown(f, shown, state)
    if not f then return end

    local on = shown and true or false
    local wantFrame = on and (state == nil or state.showFrame ~= false)
    local wantGlow = on and (state == nil or state.showGlow ~= false)

    if f.FakePreview then f.FakePreview:SetShown(on) end
    if f.FakePreviewFrame then f.FakePreviewFrame:SetShown(wantFrame) end
    if f.FakePreviewGlow then f.FakePreviewGlow:SetShown(wantGlow) end
end

-- Shows the button where it will appear, for a few seconds.
--
-- Deliberately ignores the enable toggle: you may be looking at it precisely to
-- decide whether to turn it on. Putting things back is just re-applying the
-- settings, so there is no saved state to restore and nothing to leak if the
-- player reloads mid-preview.
function SubModuleMixin:ShowPreview(seconds)
    local f = _G['DragonflightUIVehicleLeaveButton']
    if not f then return end

    self:Update()
    f:Show()
    SubModuleMixin.SetPreviewShown(f, true, self.state)

    if self.PreviewTimer then self.PreviewTimer:Cancel() end
    self.PreviewTimer = C_Timer.NewTimer(seconds or 6, function()
        SubModuleMixin.SetPreviewShown(f, false)
        self:Update()
    end)
end

-- An action bar frame is the button grid plus `padding` on every side - the
-- first button sits at dx = padding (Mixin/Actionbar.mixin.lua, the layout
-- loop), so the frame's left edge is that far outside the buttons you can see.
-- Anchoring to the frame therefore lands a few pixels left of the bar, which
-- reads as not-quite-aligned rather than as a deliberate offset.
--
-- Read the padding off the bar rather than hard-coding the default of 3, so
-- the button stays flush when a bar's padding is changed. Only for left-edge
-- anchors: a RIGHT anchor wants the far side of the grid, not this.
function SubModuleMixin:LeftInset(parent, anchorParent)
    if not (parent and anchorParent and anchorParent:find('LEFT')) then return 0 end
    local barState = parent.state
    return (barState and barState.padding) or 0
end

function SubModuleMixin:Update()
    local state = self.state;
    if not state then return end

    local f = _G['DragonflightUIVehicleLeaveButton']
    local btn = _G['MainMenuBarVehicleLeaveButton']

    -- Position and artwork first, and unconditionally: the preview shows the
    -- button where it would go even while it is switched off, because deciding
    -- whether to switch it on is one of the reasons to look at it.
    local parent = self:ResolveAnchorFrame(state)

    -- f:SetParent(parent)
    f:SetScale(state.scale)

    f:ClearAllPoints()
    f:SetPoint(state.anchor, parent, state.anchorParent, state.x + self:LeftInset(parent, state.anchorParent), state.y)
    -- f:SetUserPlaced(true)

    btn:SetScale(state.scale)
    if btn.DFButtonFrame then btn.DFButtonFrame:SetShown(state.showFrame ~= false) end

    -- Hiding the holder is not enough on its own: the real button was never
    -- reparented to it (SetParent is commented out in CreateVehicleLeaveButton
    -- and the anchor alone does not make it a child), so it has to be hidden
    -- in its own right.
    if self:IsDisabled() then
        f:Hide()
        Helper:RunOutOfCombat('VehicleLeaveDisable', function() btn:Hide() end)
        return
    end

    f:Show()

    -- Toggling back on should not wait for the next vehicle event to take
    -- effect. Out of combat only: showing and enabling this button is a
    -- protected call, and a settings change is not worth an error over.
    Helper:RunOutOfCombat('VehicleLeaveRefresh', function() self:OnEvent('DFUI_SETTINGS_CHANGED') end)

    -- f:UpdateStateHandler(state)
end

-- The arrow art is 32px square, and the button is sized to it.
local BUTTON_SIZE = 32

-- DFUI's action-button frame, the one every action button and every pet button
-- already wears: same sheet, same texel coordinates, taken from
-- DragonflightUIActionbarMixin:ReplaceNormalTexture2 and the pet bar path in
-- Mixin/Actionbar.mixin.lua. Those draw it at 46x45 over a 45px button, so it
-- overhangs the right edge by a pixel; keep the proportion rather than the
-- pixels, or a 32px button gets a border built for a bigger one.
--
-- OVERLAY sublevel 1 is where the pet bar puts it, over the icon rather than
-- under it.
local FRAME_ART = 'Interface\\Addons\\DragonflightUI\\Textures\\uiactionbar2x'
local FRAME_COORD = {0.701171875, 0.880859375, 0.31689453125, 0.36083984375}
local FRAME_REF_BUTTON, FRAME_REF_WIDTH, FRAME_REF_HEIGHT = 45, 46, 45

function SubModuleMixin.ApplyButtonFrame(owner, size)
    if not (owner and owner.CreateTexture) then return end

    local border = owner.DFButtonFrame
    if not border then
        border = owner:CreateTexture(nil, 'OVERLAY')
        owner.DFButtonFrame = border
    end

    local ratio = size / FRAME_REF_BUTTON
    border:SetTexture(FRAME_ART)
    border:SetTexCoord(unpack(FRAME_COORD))
    border:SetSize(FRAME_REF_WIDTH * ratio, FRAME_REF_HEIGHT * ratio)
    border:ClearAllPoints()
    border:SetPoint('TOPLEFT')
    border:SetDrawLayer('OVERLAY', 1)

    return border
end

-- The pet bar's "this is live" look, borrowed rather than reinvented: the same
-- corner art DFUI already puts on a pet ability that is set to autocast
-- (Mixin/Actionbar.mixin.lua, the AutoCastable texture). An active Request Stop
-- then reads the way an active pet ability reads, instead of introducing a
-- third vocabulary for the same idea.
--
-- Sublevel 2, so it sits over the button frame at sublevel 1.
local ACTIVE_ART = 'Interface\\Addons\\DragonflightUI\\Textures\\UIActionbarPetCorner2x'
local ACTIVE_COORD = {0, 68 / 128, 0, 68 / 128}

function SubModuleMixin.ApplyActiveGlow(btn)
    if not (btn and btn.CreateTexture) then return end

    local glow = btn.DFActiveGlow
    if not glow then
        glow = btn:CreateTexture(nil, 'OVERLAY')
        btn.DFActiveGlow = glow
    end

    glow:SetTexture(ACTIVE_ART)
    glow:SetTexCoord(unpack(ACTIVE_COORD))
    glow:ClearAllPoints()
    glow:SetPoint('TOPLEFT', -1, 1)
    glow:SetPoint('BOTTOMRIGHT')
    glow:SetDrawLayer('OVERLAY', 2)
    glow:Hide()

    return glow
end

-- Lit while the button can actually be clicked, dark the rest of the time -
-- and never, if the setting is off. A method rather than a plain function so
-- it can see that setting: the event handler is the only caller that knows
-- whether the button is active, and the settings are the only thing that knows
-- whether the glow is wanted at all.
function SubModuleMixin:SetActiveGlow(btn, active)
    local glow = btn and btn.DFActiveGlow
    if not glow then return end

    local wanted = (self.state == nil) or (self.state.showGlow ~= false)
    if active and wanted then glow:Show() else glow:Hide() end
end

function SubModuleMixin:CreateVehicleLeaveButton()
    local f = _G['DragonflightUIVehicleLeaveButton']
    -- local fakeWidget = CreateFrame('Frame', 'DragonflightUIVehicleLeaveButtonPreview', f)
    -- fakeWidget:SetParent(UIParent)
    -- fakeWidget:SetSize(32, 32)
    local fakeWidget = f;

    local tex = 'Interface\\Addons\\DragonflightUI\\Textures\\UI-Vehicles-Button-Exit-Up'
    local fakeArrow = fakeWidget:CreateTexture('DragonflightUIFakeVehicleLeaveButton', "ARTWORK")
    -- fakeArrow:SetTexture('Interface\\Vehicles\\UI-Vehicles-Button-Exit-U')
    fakeArrow:SetTexture(tex)
    fakeArrow:SetTexCoord(0.140625, 0.859375, 0.140625, 0.859375)
    fakeArrow:SetSize(32, 32)
    fakeArrow:SetPoint('CENTER', fakeWidget, 'CENTER', 0, 0)
    fakeArrow:Hide()
    fakeWidget.FakePreview = fakeArrow;

    -- The edit-mode preview stands in for the button while the real one is
    -- hidden, so it wears the same frame. Centred on the arrow rather than on
    -- the holder's TOPLEFT: the arrow is centred in a holder that is not
    -- necessarily the button's size.
    local fakeFrame = SubModuleMixin.ApplyButtonFrame(fakeWidget, BUTTON_SIZE)
    if fakeFrame then
        fakeFrame:ClearAllPoints()
        fakeFrame:SetPoint('CENTER', fakeArrow, 'CENTER', 0, 0)
        fakeFrame:Hide()
    end
    fakeWidget.FakePreviewFrame = fakeFrame;

    -- ...and the glow, so a preview shows the button in the state you actually
    -- see it in: lit. A preview of the dark version would be a preview of
    -- nothing worth looking at.
    local fakeGlow = SubModuleMixin.ApplyActiveGlow(fakeWidget)
    if fakeGlow then
        fakeGlow:ClearAllPoints()
        fakeGlow:SetPoint('TOPLEFT', fakeArrow, 'TOPLEFT', -1, 1)
        fakeGlow:SetPoint('BOTTOMRIGHT', fakeArrow, 'BOTTOMRIGHT', 0, 0)
        fakeGlow:Hide()
    end
    fakeWidget.FakePreviewGlow = fakeGlow;

    local btn = _G['MainMenuBarVehicleLeaveButton'];
    if DF.API.Version.IsTBC then
        addonTable:OverrideBlizzEditmode(btn, 'CENTER', f, 'CENTER', 0, 0)
    else
        btn:UnregisterAllEvents()
        -- btn:SetParent(f)
        btn:ClearAllPoints()
        btn:SetPoint('CENTER', f, 'CENTER', 0, 0)
        -- btn:Show()

        -- era-1159: the plain SetPoint above is not enough. The Classic
        -- panel manager (UIParentManageFramePositions) re-anchors this
        -- button to UIParent/BOTTOM whenever the bars update - which is
        -- exactly when a taxi shows it - because IsInDefaultPosition()
        -- still reports true. Move its EditMode layout anchor as well
        -- (the same trick ForceMoveBlizzEditModeGhosts uses for the
        -- parked bars, and the TBC branch below already does): the
        -- manager then skips the button and the dock anchor sticks.
        -- SaveOnly, never ApplyChanges: ApplyChanges works by Show/Hiding
        -- EditModeManagerFrame, which re-applies the whole Blizzard layout
        -- mid-chain - it stomped the unitframe positions set moments
        -- earlier, fired DFUI's EditMode enter/exit hooks against
        -- half-built bars, and left the reskinned editmode panels stuck
        -- open on screen. The saved anchor is applied by the next natural
        -- layout application (and by InitEditmodeOverride's own early
        -- ApplyChanges on every following login).
        local lib = addonTable.LibEditModeOverride
        if lib then
            lib:ReanchorFrame(btn, 'CENTER', f, 'CENTER', 0, 0)
            lib:SaveOnly()
        end

        -- era-1159: dress the real button in the retail round exit-arrow
        -- art (shipped by DFUI but previously used only for the edit-mode
        -- preview); the classic wooden square reads nothing like retail.
        btn:SetSize(32, 32)
        for _, region in ipairs({btn:GetRegions()}) do
            if region:GetObjectType() == 'Texture' then region:SetTexture(nil) end
        end
        local coord = {0.140625, 0.859375, 0.140625, 0.859375}
        btn:SetNormalTexture(tex)
        btn:GetNormalTexture():SetTexCoord(unpack(coord))
        btn:SetPushedTexture(tex)
        local pushed = btn:GetPushedTexture()
        pushed:SetTexCoord(unpack(coord))
        pushed:SetVertexColor(0.6, 0.6, 0.6)
        btn:SetHighlightTexture(tex, 'ADD')
        btn:GetHighlightTexture():SetTexCoord(unpack(coord))
        btn:GetHighlightTexture():SetAlpha(0.35)

        -- The loop above clears every texture the button owns and only normal,
        -- pushed and highlight were put back, so a disabled button had nothing
        -- of its own left to draw. It still needs one, or the two states render
        -- identically - but it is the plain arrow now, not a greyed one: the
        -- difference between usable and not is carried by the active glow
        -- below, not by dimming the icon.
        --
        -- Pass the path, never nil: 1.15.9 rejects nil on these setters
        -- outright ("Usage: self:SetDisabledTexture(asset)") and the error
        -- aborts the rest of the restyle.
        btn:SetDisabledTexture(tex)
        local disabled = btn:GetDisabledTexture()
        if disabled then disabled:SetTexCoord(unpack(coord)) end

        SubModuleMixin.ApplyButtonFrame(btn, BUTTON_SIZE)
        SubModuleMixin.ApplyActiveGlow(btn)
    end
end
