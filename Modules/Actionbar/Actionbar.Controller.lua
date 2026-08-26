local addonName, addonTable = ...;
local Helper = addonTable.Helper;
---@diagnostic disable: undefined-global
local DF = LibStub('AceAddon-3.0'):GetAddon('DragonflightUI')
local L = LibStub("AceLocale-3.0"):GetLocale("DragonflightUI")
local Module = DF:GetModule('Actionbar')

local PossessBarFrame = _G['PossessBarFrame'] or CreateFrame('Frame', 'PossessBarFrame', UIParent)

-- Runs the builder synchronously - used by non-modern flavors.
function Module:SetupActionbarFrames()
    for _, step in ipairs(self:GetSetupActionbarSteps()) do step[2]() end
end

function Module:GetSetupActionbarSteps()
    local steps = {}
    local handler
    local createStuff = function(n, base)
        local bar = CreateFrame('FRAME', 'DragonflightUIActionbarFrame' .. n, UIParent,
                                'DragonflightUIActionbarFrameTemplate')
        local buttons = {}
        for i = 1, 12 do
            local name = base .. i
            local btn = _G[name]
            buttons[i] = btn
        end
        bar:Init()
        bar:SetButtons(buttons, n)
        Module['bar' .. n] = bar
    end

    steps[#steps + 1] = {'HookGrid', function()
        DragonflightUIActionbarMixin:HookGrid()
    end}

    steps[#steps + 1] = {'MainBar', function()
        createStuff(1, 'ActionButton')
        Module.bar1:SetupMainBar()
        Module.bar1:AddPagingStateDriver()
    end}
    steps[#steps + 1] = {'Bar2', function() createStuff(2, 'MultiBarBottomLeftButton') end}
    steps[#steps + 1] = {'Bar3', function() createStuff(3, 'MultiBarBottomRightButton') end}
    steps[#steps + 1] = {'Bar4', function() createStuff(4, 'MultiBarLeftButton') end}
    steps[#steps + 1] = {'Bar5', function() createStuff(5, 'MultiBarRightButton') end}

    for i = 1, 5 do
        steps[#steps + 1] = {'StyleBar' .. i, function()
            local bar = Module['bar' .. i]
            if bar then
                bar:StyleButtons()
                bar:HookQuickbindMode()
                bar:ReplaceNormalTexture2()
            end
        end}
    end

    steps[#steps + 1] = {'SecureHandler', function()
        handler = CreateFrame('Frame', 'DragonflightUIActionBarHandler', nil, 'SecureHandlerBaseTemplate');
        handler:SetAttribute("ActionButtonUseKeyDown", GetCVarBool('ActionButtonUseKeyDown'));

        handler:SetScript("OnEvent", function(f, event, ...)
            f[event](f, ...)
        end)
        handler:RegisterEvent('VARIABLES_LOADED');
        handler:RegisterEvent('CVAR_UPDATE');
        handler:RegisterEvent('PLAYER_REGEN_ENABLED');

        handler.dirtyTable = {};
        function handler:TrySetAttribute(key, value)
            if InCombatLockdown() then
                self.dirtyTable[key] = value;
                return;
            end

            self:SetAttribute(key, value);
        end

        function handler:PLAYER_REGEN_ENABLED()
            for k, v in pairs(self.dirtyTable) do
                self:SetAttribute(k, v);
                self.dirtyTable[k] = nil;
            end
        end

        function handler:VARIABLES_LOADED()
            self:TrySetAttribute('ActionButtonUseKeyDown', GetCVarBool('ActionButtonUseKeyDown'))
        end

        function handler:CVAR_UPDATE(cvar)
            if cvar == 'ActionButtonUseKeyDown' then
                self:TrySetAttribute(cvar, GetCVarBool(cvar))
            end
        end
    end}

    local extraBases = {[6] = 'MultiBar5Button', [7] = 'MultiBar6Button', [8] = 'MultiBar7Button'}
    for n = 6, 8 do
        steps[#steps + 1] = {'ExtraBar' .. n, function()
            createStuff(n, extraBases[n])
        end}
    end

    steps[#steps + 1] = {'ExtraBarsFinish', function()
        for i = 6, 8 do
            local bar = Module['bar' .. i]
            if bar then
                bar:StyleButtons()
                bar:HookQuickbindMode()
                bar:ReplaceNormalTexture2()
            end
        end

        DragonFlightUIQuickKeybindMixin:HookExtraButtonsTBC()

        local actionbarToBlizzEditmodeFrame = {}
        actionbarToBlizzEditmodeFrame[1] = _G['MainActionBar']
        actionbarToBlizzEditmodeFrame[2] = _G['MultiBarBottomLeft']
        actionbarToBlizzEditmodeFrame[3] = _G['MultiBarBottomRight']
        actionbarToBlizzEditmodeFrame[4] = _G['MultiBarLeft']
        actionbarToBlizzEditmodeFrame[5] = _G['MultiBarRight']
        actionbarToBlizzEditmodeFrame[6] = _G['MultiBar5']
        actionbarToBlizzEditmodeFrame[7] = _G['MultiBar6']
        actionbarToBlizzEditmodeFrame[8] = _G['MultiBar7']

        for i = 1, 8 do
            local bar = Module['bar' .. i]
            if bar then
                bar.BlizzEditmodeFrame = actionbarToBlizzEditmodeFrame[i];
            end
        end
    end}

    steps[#steps + 1] = {'MigrateKeybinds', function()
        DragonflightUIActionbarMixin:MigrateOldKeybinds()
        DragonflightUIActionbarMixin:MigrateOldKeybindsTBC()

        if ActionButton_UpdateHotkeys then
            hooksecurefunc('ActionButton_UpdateHotkeys', function(self, actionButtonType)
                if self.DragonflightFixHotkey then self:DragonflightFixHotkey() end
            end)
        end
    end}

    for i = 1, 8 do
        steps[#steps + 1] = {'Deco' .. i, function()
            local bar = Module['bar' .. i]
            if bar then
                bar:AddDecoNew(i)
                bar:AddTargetStateDriver()
            end
        end}
    end

    steps[#steps + 1] = {'PetBar', function()
        local bar = CreateFrame('FRAME', 'DragonflightUIPetbar', UIParent, 'DragonflightUIPetbarFrameTemplate')
        local buttons = {}

        for i = 1, 10 do
            local btn = _G['PetActionButton' .. i]
            buttons[i] = btn
        end

        bar:Init()
        bar:SetButtons(buttons, 69)
        bar:StyleButtons()
        bar:StylePetButton()
        Module['petbar'] = bar
    end}

    steps[#steps + 1] = {'StanceBar', function()
        local bar = CreateFrame('FRAME', 'DragonflightUIStancebar', UIParent, 'DragonflightUIStancebarFrameTemplate')
        local buttons = {}

        for i = 1, 10 do
            local btn = _G['StanceButton' .. i]
            buttons[i] = btn
        end

        bar:Init()
        bar:SetButtons(buttons, 420)
        bar:StyleButtons()
        Module['stancebar'] = bar
    end}

    steps[#steps + 1] = {'SlotFilter', function() Module.InstallSlotChangedFilter() end}

    return steps
end

function Module.InstallSlotChangedFilter()
    local bef = _G['ActionBarButtonEventsFrame']
    if not bef or not bef.frames or Module.SlotFilterInstalled then return end
    Module.SlotFilterInstalled = true

    bef:UnregisterEvent('ACTIONBAR_SLOT_CHANGED')

    local function actionTexture(slot)
        if C_ActionBar and C_ActionBar.GetActionTexture then return C_ActionBar.GetActionTexture(slot) end
        return GetActionTexture(slot)
    end

    local function hasAction(slot)
        if C_ActionBar and C_ActionBar.HasAction then return C_ActionBar.HasAction(slot) end
        return HasAction(slot)
    end

    local function isEquipped(slot)
        if C_ActionBar and C_ActionBar.IsEquippedAction then return C_ActionBar.IsEquippedAction(slot) end
        return IsEquippedAction(slot)
    end

    local function actionText(slot)
        if C_ActionBar and C_ActionBar.UsesActionText then
            return C_ActionBar.UsesActionText(slot) and C_ActionBar.GetActionText(slot) or ''
        end
        return GetActionText(slot) or ''
    end

    local function signature(slot)
        local actionType, id, subType = GetActionInfo(slot)
        return (actionType or '') .. ':' .. tostring(id or 0) .. ':' .. tostring(subType or '')
    end

    local function refresh(btn, deep)
        local action = btn.action
        if not action then return end

        local icon = btn.icon
        local texture = actionTexture(action)
        if texture then
            if icon then
                icon:SetTexture(texture)
                icon:Show()
            end
            if btn.UpdateCount then btn:UpdateCount() end
        else
            if icon then icon:Hide() end
            if btn.Count then btn.Count:SetText('') end
            if btn.cooldown and ClearActionButtonCooldowns then
                ClearActionButtonCooldowns(btn.cooldown, btn.chargeCooldown, btn.lossOfControlCooldown)
            end
        end

        if btn.UpdateUsable then btn:UpdateUsable() end

        local border = btn.Border
        if border then
            if isEquipped(action) then
                border:SetVertexColor(0, 1.0, 0, 0.5)
                border:Show()
            else
                border:Hide()
            end
        end

        if btn.Name then btn.Name:SetText(actionText(action)) end

        if deep then
            local aef = _G['ActionBarActionEventsFrame']
            if aef then
                if hasAction(action) and not btn.eventsRegistered then
                    aef:RegisterFrame(btn)
                    btn.eventsRegistered = true
                elseif not hasAction(action) and btn.eventsRegistered then
                    aef:UnregisterFrame(btn)
                    btn.eventsRegistered = nil
                end
            end

            if btn.UpdateState then btn:UpdateState() end
            if btn.UpdateFlash then btn:UpdateFlash() end
            if btn.UpdateProfessionQuality then btn:UpdateProfessionQuality() end
            if btn.UpdateTypeOverlay then btn:UpdateTypeOverlay() end
            if btn.UpdateFlyout then btn:UpdateFlyout() end
            if ActionButton_UpdateCooldown then ActionButton_UpdateCooldown(btn) end
        end

        if GameTooltip:GetOwner() == btn and btn.SetTooltip then btn:SetTooltip() end
    end

    local function dispatch(slot, deep)
        for _, btn in pairs(bef.frames) do
            if (slot == 0 or btn.action == slot) and btn.IsVisible and btn:IsVisible() then
                local ok, err = pcall(refresh, btn, deep)
                if not ok and not Module.SlotFilterErrorReported then
                    Module.SlotFilterErrorReported = true
                    geterrorhandler()('DFUI slot filter: ' .. tostring(err))
                end
            end
        end
    end

    local lastSignature = {}

    local filter = CreateFrame('Frame')
    filter:RegisterEvent('ACTIONBAR_SLOT_CHANGED')
    filter:SetScript('OnEvent', function(_, _, slot)
        if not slot or slot == 0 then
            wipe(lastSignature)
            dispatch(0, true)
            return
        end

        local sig = signature(slot)
        local deep = lastSignature[slot] ~= sig
        lastSignature[slot] = sig
        dispatch(slot, deep)
    end)
end

function Module.AddStateUpdater()
    local DFBagBar = _G['DragonflightUIBagBar']
    Mixin(DFBagBar, DragonflightUIStateHandlerMixin)
    DFBagBar:InitStateHandler()

    local microFrame = Module.MicroFrame
    Mixin(microFrame, DragonflightUIStateHandlerMixin)
    microFrame:InitStateHandler()

    if MicroMenuContainer and microFrame.SetHideFrame then
        microFrame:SetHideFrame(MicroMenuContainer, 2)
    end
    if _G['BagsBar'] and DFBagBar.SetHideFrame then DFBagBar:SetHideFrame(_G['BagsBar'], 2) end
end

local frame = CreateFrame('FRAME', 'DragonflightUIActionbarFrame', UIParent)
frame:SetFrameStrata('HIGH')
Module.Frame = frame

function Module.ChangeActionbar()
    if ActionButton1 then ActionButton1.ignoreFramePositionManager = true end
    if MultiBarBottomLeft then MultiBarBottomLeft.ignoreFramePositionManager = true end
    if MultiBarBottomRight then MultiBarBottomRight.ignoreFramePositionManager = true end
    if MultiBarLeft then MultiBarLeft.ignoreFramePositionManager = true end
    if MultiBarRight then MultiBarRight.ignoreFramePositionManager = true end

    if StanceButton1 then
        StanceButton1:ClearAllPoints()
        if MultiBarBottomLeft then
            StanceButton1:SetPoint('LEFT', MultiBarBottomLeft, 'LEFT', 1, 77)
        end
        StanceButton1.ignoreFramePositionManager = true
    end

    if DF.API.Version.IsModern then
        if _G['StatusTrackingBarManager'] then _G['StatusTrackingBarManager']:Hide() end

        local stancebar = _G['StanceBar'];
        if stancebar then
            local t = {'BackgroundArtLeft', 'BackgroundArtMiddle', 'BackgroundArtRight'}
            for k, v in ipairs(t) do
                if stancebar[v] then
                    stancebar[v]:Hide()
                    stancebar[v]:ClearAllPoints()
                    stancebar[v]:SetTexture('')
                end
            end
        end

        local mab = _G['MainActionBar']
        if mab then
            mab:UnregisterAllEvents()
            mab:ClearAllPoints()
            mab:Show()
        end

        Module:ForceMoveBlizzEditModeGhosts()
    else
        if StanceBarLeft then
            StanceBarLeft:Hide()
            StanceBarMiddle:Hide()
            StanceBarRight:Hide()

            hooksecurefunc(StanceBarRight, 'Show', function()
                StanceBarLeft:Hide()
                StanceBarMiddle:Hide()
                StanceBarRight:Hide()
            end)
        end

        if MainMenuBar then MainMenuBar:SetSize(1, 1) end

        if MainMenuExpBar then
            MainMenuExpBar:Hide()
            hooksecurefunc(MainMenuExpBar, 'Show', function()
                MainMenuExpBar:Hide()
            end)
        end
        if StatusTrackingBarManager then StatusTrackingBarManager:Hide() end
        if ReputationWatchBar then
            ReputationWatchBar:Hide()
            hooksecurefunc(ReputationWatchBar, 'Show', function()
                ReputationWatchBar:Hide()
            end)
        end
        if MainMenuBarMaxLevelBar then
            MainMenuBarMaxLevelBar:Hide()
            hooksecurefunc(MainMenuBarMaxLevelBar, 'Show', function()
                MainMenuBarMaxLevelBar:Hide()
            end)
        end
    end
end

function Module.CreateNewXPBar()
    local newF = CreateFrame('Frame', 'DragonflightUIXPBar', UIParent, 'DragonflightUIXPBarTemplate')
    Module.xpbar = newF
end

function Module.CreateNewRepBar()
    local newRep = CreateFrame('Frame', 'DragonflightUIRepBar', UIParent, 'DragonflightUIRepBarTemplate')
    Module.repbar = newRep
end

function Module.GetPetbarOffset()
    local localizedClass, englishClass, classIndex = UnitClass('player')
    if (classIndex == 1 or classIndex == 2 or classIndex == 5 or classIndex == 6 or classIndex == 7 or classIndex == 11) then
        return 34
    else
        return 0
    end
end

function Module.HookPetBar()
    if PetActionBarFrame then
        PetActionBarFrame:ClearAllPoints()
        PetActionBarFrame:SetPoint('CENTER', UIParent, 'CENTER', 0, 0)
        PetActionBarFrame.ignoreFramePositionManager = true
    end

    if SlidingActionBarTexture0 then SlidingActionBarTexture0:SetTexture('') end
    if SlidingActionBarTexture1 then SlidingActionBarTexture1:SetTexture('') end

    for i = 1, 10 do
        local pBtn = _G['PetActionButton' .. i]
        if pBtn then
            pBtn:SetSize(30, 30)
            local normalTexture2 = _G['PetActionButton' .. i .. 'NormalTexture2'];
            if normalTexture2 then normalTexture2:SetSize(50, 50) end
        end
    end

    local spacing = 7
    for i = 2, 10 do
        local btn = _G['PetActionButton' .. i]
        local prev = _G['PetActionButton' .. (i - 1)]
        if btn and prev then
            btn:SetPoint('LEFT', prev, 'RIGHT', spacing, 0)
        end
    end
end

function Module:ForceMoveBlizzEditModeGhosts()
    if not addonTable.OverrideBlizzEditmode then return end
    local t = {_G['MainActionBar'], _G['StanceBar'], _G['PetActionBar'], _G['PossessActionBar']}

    local lib = addonTable.LibEditModeOverride
    if lib then
        if addonTable.RefreshBlizzEditmodeLayouts then addonTable:RefreshBlizzEditmodeLayouts() end

        for k, v in ipairs(t) do
            if v then
                v:SetClampedToScreen(false)
                lib:ReanchorFrame(v, 'BOTTOM', UIParent, 'TOP', 0, 0 + 500)
            end
        end
        lib:SaveOnly()

        if not addonTable.BlizzEditmodeApplyAllowed and not InCombatLockdown() then
            for k, v in ipairs(t) do
                if v then
                    v:ClearAllPoints()
                    v:SetPoint('BOTTOM', UIParent, 'TOP', 0, 0 + 500)
                end
            end
        end

        for k, v in ipairs(t) do if v and v.SetScale then v:SetScale(1) end end

        if addonTable.ScheduleBlizzEditmodeApply then addonTable:ScheduleBlizzEditmodeApply() end
    else
        for k, v in ipairs(t) do
            if v then
                v:SetClampedToScreen(false)
                addonTable:OverrideBlizzEditmode(v, 'BOTTOM', UIParent, 'TOP', 0, 0 + 500)
            end
        end
    end
end

function Module.MoveTotem()
    if not MultiCastActionBarFrame then return end
    MultiCastActionBarFrame.ignoreFramePositionManager = true
    Module.Temp.TotemFixing = nil
    hooksecurefunc(MultiCastActionBarFrame, 'SetPoint', function()
        if Module.Temp.TotemFixing or InCombatLockdown() then return end
        Module.Temp.TotemFixing = true

        local db = Module.db.profile
        Module.UpdateTotemState(db.totem)

        Module.Temp.TotemFixing = nil
    end)
end

function Module.UpdatePossesbarState(state)
    if not state then return end
    PossessBarFrame.ignoreFramePositionManager = true

    local offset = (GetNumShapeshiftForms() > 0) and _G['DragonflightUIStancebar'] and _G['DragonflightUIStancebar']:GetHeight() or 0
    local offset = state.offset and offset or 0

    PossessBarFrame:ClearAllPoints()
    local parent = _G[state.anchorFrame] or UIParent
    PossessBarFrame:SetPoint(state.anchor, parent, state.anchorParent, state.x, state.y + offset)
    PossessBarFrame:SetScale(state.scale)
end

function frame:OnEvent(event, arg1)
    if event == 'PLAYER_REGEN_ENABLED' then
        if frame.ShouldUpdate then
            local db = Module.db.profile
            local state = db.micro
            if Module.MicroFrame and Module.MicroFrame.UpdateStateHandler then
                Module.MicroFrame:UpdateStateHandler(state)
            end
            frame.ShouldUpdate = false
        end
    end
end
frame:SetScript('OnEvent', frame.OnEvent)
frame:RegisterEvent('PLAYER_REGEN_ENABLED')
frame:RegisterEvent('SETTINGS_LOADED')

function Module.ChangeMicroMenu()
    local microFrame = _G['DragonflightUIMicroMenuBar']
    if not microFrame then return end
    microFrame:SetSize(100, 100)
    microFrame:SetParent(UIParent)
    microFrame:SetClampedToScreen(true)
    microFrame:SetMovable(true)
    microFrame:OnLoad()
    Module.MicroFrame = microFrame

    if DF.API.Version.IsModern and MicroMenuContainer and addonTable.OverrideBlizzEditmode then
        addonTable:OverrideBlizzEditmode(MicroMenuContainer, 'TOPLEFT', microFrame, 'TOPLEFT', 0, 0)
    end
end

function Module.UpdateTotemState(state)
    if not MultiCastActionBarFrame or not state then return end
    Module.Temp.TotemFixing = true

    local parent = _G[state.anchorFrame] or UIParent
    MultiCastActionBarFrame:ClearAllPoints()
    MultiCastActionBarFrame:SetPoint(state.anchor, parent, state.anchorParent, state.x, state.y)
    MultiCastActionBarFrame:SetScale(state.scale)

    Module.Temp.TotemFixing = nil
end

function Module:UpdateExtraButtonState(state)
    if not state or not Module.ExtraActionButtonPreview then return end
    local parent = _G[state.anchorFrame] or UIParent

    Module.ExtraActionButtonPreview:ClearAllPoints()
    Module.ExtraActionButtonPreview:SetPoint(state.anchor, parent, state.anchorParent, state.x, state.y)
    Module.ExtraActionButtonPreview:SetScale(state.scale)

    local btn = _G['ExtraActionButton1']
    if btn then
        btn:ClearAllPoints()
        btn:SetPoint(state.anchor, parent, state.anchorParent, state.x, state.y)
        btn:SetScale(state.scale)

        if btn.style then
            if state.hideBackgroundTexture then
                btn.style:SetAlpha(0);
            else
                btn.style:SetAlpha(1.0);
            end
        end
    end
end

function Module.UpdateBagState(state)
    if not state then return end

    local f = _G['DragonflightUIBagBar']
    if not f then return end

    if DF.API.Version.IsTBC then state.customAnchorFrame = ''; end

    local parent;
    if DF.Settings.ValidateFrame(state.customAnchorFrame) then
        parent = _G[state.customAnchorFrame]
    else
        parent = _G[state.anchorFrame]
    end
    if not parent then parent = UIParent end

    f:SetScale(state.scale)
    f:ClearAllPoints()
    f:SetPoint(state.anchor, parent, state.anchorParent, state.x, state.y)

    if MainMenuBarBackpackButton then
        MainMenuBarBackpackButton:SetParent(f)
        MainMenuBarBackpackButton:SetScale(1.5)
    end

    if _G['BagsBar'] then
        local b = _G['BagsBar']
        local point, relativeTo, relativePoint, xOfs, yOfs = b:GetPoint(1)
        if not (relativeTo == f) then addonTable:OverrideBlizzEditmode(b, 'RIGHT', f, 'RIGHT', 0, 0) end
    else
        if MainMenuBarBackpackButton then
            MainMenuBarBackpackButton:ClearAllPoints()
            MainMenuBarBackpackButton:SetPoint('RIGHT', f, 'RIGHT', 0, 0)
        end
    end

    for i = 0, 3 do
        local slot = _G['CharacterBag' .. i .. 'Slot']
        if slot then slot:SetScale(state.scale) end
    end

    local toggle = Module.FrameBagToggle
    if toggle and CharacterBag0Slot and MainMenuBarBackpackButton then
        if state.hideArrow then
            toggle:Hide()
            CharacterBag0Slot:SetPoint('RIGHT', MainMenuBarBackpackButton, 'LEFT', 0, 0)
        else
            toggle:Show()
            CharacterBag0Slot:SetPoint('RIGHT', MainMenuBarBackpackButton, 'LEFT', -12, 0)
        end
    end

    Module.BagBarExpandToggled(state.expanded)

    if state.overrideBagAnchor and ContainerFrame1 and ContainerFrame1:IsVisible() then
        UpdateContainerFrameAnchors()
    end

    if f.UpdateStateHandler then f:UpdateStateHandler(state) end
end
