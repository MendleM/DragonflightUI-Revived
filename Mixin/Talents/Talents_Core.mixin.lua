local addonName, addonTable = ...;
local Helper = addonTable.Helper;
---@diagnostic disable: undefined-global
local DF = LibStub('AceAddon-3.0'):GetAddon('DragonflightUI')

local activeSpec = 1
local selectedSpec = 1
local frameRef = nil

DragonflightUITalentsFrameMixin = {}

function DragonflightUITalentsFrameMixin:GetActiveSpec()
    return activeSpec
end

function DragonflightUITalentsFrameMixin:GetSelectedSpec()
    return selectedSpec
end

function DragonflightUITalentsFrameMixin:SetSelectedSpec(spec)
    selectedSpec = spec
end

function DragonflightUITalentsFrameMixin:OnLoad()
    frameRef = self

    local headerText = PlayerTalentFrame:CreateFontString('DragonflightUIPlayerTalentFrameHeaderText', 'OVERLAY',
                                                          'GameFontHighlight')
    headerText:SetPoint('TOP', PlayerTalentFrame, 'TOP', 0, -36)

    if PlayerTalentFrameTitleText then PlayerTalentFrameTitleText:ClearAllPoints() end
    local titleText = PlayerTalentFrame:CreateFontString('DragonflightUIPlayerTalentFrameTitleText', 'OVERLAY',
                                                         'GameFontNormal')
    titleText:SetPoint('TOP', PlayerTalentFrame, 'TOP', 0, -5)
    titleText:SetPoint('LEFT', PlayerTalentFrame, 'LEFT', 60, 0)
    titleText:SetPoint('RIGHT', PlayerTalentFrame, 'RIGHT', -60, 0)
    titleText:SetText(TALENTS)

    PlayerTalentFrame.UpdateDFHeaderText = function()
        local unspentTalentPoints = DragonflightUITalentsPanelMixin:GetUnspetTalentPoints(selectedSpec)

        if unspentTalentPoints > 0 then
            headerText:SetFormattedText(PLAYER_UNSPENT_TALENT_POINTS, unspentTalentPoints);
            headerText:Show()
        elseif GetNextTalentLevel and GetNextTalentLevel() then
            headerText:SetFormattedText(NEXT_TALENT_LEVEL, GetNextTalentLevel());
            headerText:Show()
        else
            headerText:Hide()
        end

        if activeSpec == selectedSpec then
            if selectedSpec == 1 then
                titleText:SetText(TALENT_SPEC_PRIMARY_ACTIVE)
            else
                titleText:SetText(TALENT_SPEC_SECONDARY_ACTIVE)
            end
        else
            if selectedSpec == 1 then
                titleText:SetText(TALENT_SPEC_PRIMARY)
            else
                titleText:SetText(TALENT_SPEC_SECONDARY)
            end
        end
    end

    PlayerTalentFrame.DFPanels = {}
    self.Panels = {}

    for i = 1, 3 do
        local panel = CreateFrame('FRAME', 'DragonflightUIPlayerTalentFramePanel' .. i, PlayerTalentFrame,
                                  'DFPlayerTalentFramePanelTemplate')
        panel:Init(i)

        if DF.API.Version.IsTBC then
            panel:SetHeight(376 + 90)

            local bgTop = panel.BgTopLeft;
            local bgBottom = panel.BgBottomLeft;

            if bgTop and bgBottom then
                local totalH = bgTop:GetHeight() + bgBottom:GetHeight()
                if totalH > 0 then
                    bgTop:SetHeight(bgTop:GetHeight() + 90 * (bgTop:GetHeight() / totalH))
                    bgBottom:SetHeight(bgBottom:GetHeight() + 90 * (bgBottom:GetHeight() / totalH))
                end
            end
        end

        PlayerTalentFrame.DFPanels[i] = panel
        self.Panels[i] = panel

        if i == 1 then
            panel:SetPoint('BOTTOMLEFT', PlayerTalentFrame.DFInset, 'BOTTOMLEFT', 5, 3)
        else
            panel:SetPoint('TOPLEFT', PlayerTalentFrame.DFPanels[i - 1], 'TOPRIGHT', 1, 0)
        end
    end

    do
        local check = CreateFrame('CHECKBUTTON', 'DragonflightUIPlayerTalentFrameCheckbox', PlayerTalentFrame,
                                  'DFPlayerTalentFrameCheckboxTemplate')
        check:SetSize(23, 22)
        check:SetPoint('BOTTOMLEFT', PlayerTalentFrame, 'BOTTOMLEFT', 5, 3)

        self.Checkbox = check

        check:SetScript('OnClick', function(button, buttonName, down)
            self:ToggleCVar()
        end)

        check:SetScript('OnEnter', function(self)
            GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
            GameTooltip_AddNormalLine(GameTooltip, PREVIEW_TALENT_CHANGES)
            GameTooltip_AddHighlightLine(GameTooltip, OPTION_PREVIEW_TALENT_CHANGES_DESCRIPTION)
            GameTooltip:Show()
        end)

        local checkText = PlayerTalentFrame:CreateFontString('DragonflightUIPlayerTalentFrameCheckboxDescription',
                                                             'OVERLAY', 'GameFontHighlight')
        checkText:SetPoint('LEFT', check, 'RIGHT', 4, 0)
        checkText:SetText(PREVIEW_TALENT_CHANGES)
    end

    do
        if PlayerTalentFramePreviewBar then PlayerTalentFramePreviewBar:ClearAllPoints() end

        local reset = CreateFrame('BUTTON', 'DragonflightUIPlayerTalentFrameResetButton', PlayerTalentFrame,
                                  'DFPlayerTalentFrameResetButton')
        reset:SetPoint('BOTTOMRIGHT', PlayerTalentFrame, 'BOTTOMRIGHT', -5, 4)
        self.ResetButton = reset

        local learn = CreateFrame('BUTTON', 'DragonflightUIPlayerTalentFrameLearnButton', PlayerTalentFrame,
                                  'DFPlayerTalentFrameLearnButton')
        learn:SetPoint('RIGHT', reset, 'LEFT', 0, 0)
        self.LearnButton = learn
    end

    do
        if PlayerSpecTab1 then
            PlayerSpecTab1:ClearAllPoints()
            PlayerSpecTab1:SetPoint('TOPLEFT', PlayerTalentFrame, 'TOPRIGHT', 0, -36)
            PlayerSpecTab1:SetAlpha(0)
            PlayerSpecTab1:EnableMouse(false)
        end

        if PlayerSpecTab2 then
            local tab1 = PlayerSpecTab1 or PlayerTalentFrame
            PlayerSpecTab2:ClearAllPoints()
            PlayerSpecTab2:SetPoint('TOPLEFT', tab1, 'BOTTOMLEFT', 0, -22)
            PlayerSpecTab2:SetAlpha(0)
            PlayerSpecTab2:EnableMouse(false)
        end

        local newTab1 = CreateFrame('CHECKBUTTON', 'DragonflightUIPlayerTalentFrameSpecButton' .. 1, PlayerTalentFrame,
                                     'DFPlayerSpecTabTemplate')
        newTab1:SetPoint('TOPLEFT', PlayerTalentFrame, 'TOPRIGHT', 0, -36)
        newTab1.specIndex = 1

        local newTab2 = CreateFrame('CHECKBUTTON', 'DragonflightUIPlayerTalentFrameSpecButton' .. 2, PlayerTalentFrame,
                                     'DFPlayerSpecTabTemplate')
        newTab2:SetPoint('TOPLEFT', newTab1, 'BOTTOMLEFT', 0, -22)
        newTab2.specIndex = 2
    end

    do
        if PlayerTalentFrameActivateButton then
            PlayerTalentFrameActivateButton:ClearAllPoints()
            PlayerTalentFrameActivateButton:Hide()
        end

        local activate = CreateFrame('BUTTON', 'DragonflightUIPlayerTalentFrameActivateButton', PlayerTalentFrame,
                                     'DFPlayerTalentFrameActivateButton')
        activate:SetPoint('TOPRIGHT', PlayerTalentFrame, 'TOPRIGHT', -10, -30)
    end

    if _G['PlayerTalentFrameStatusFrame'] then
        _G['PlayerTalentFrameStatusFrame']:ClearAllPoints();
        _G['PlayerTalentFrameStatusFrame']:Hide();
    end

    self:RegisterEvent("PREVIEW_TALENT_POINTS_CHANGED");
    self:RegisterEvent("UNIT_LEVEL");
    self:RegisterEvent("PLAYER_TALENT_UPDATE");
    self:RegisterEvent("PREVIEW_TALENT_PRIMARY_TREE_CHANGED");
    self:RegisterEvent("CVAR_UPDATE")

    self:Refresh()

    PlayerTalentFrame:HookScript('OnShow', function()
        self:RefreshSpecTabs()
    end)

    if GetActiveTalentGroup then
        activeSpec = GetActiveTalentGroup()
    end
    selectedSpec = activeSpec

    if ToggleTalentFrame then
        hooksecurefunc('ToggleTalentFrame', function()
            self:Refresh()
        end)
    end
end

function DragonflightUITalentsFrameMixin:OnShow()
    self:Refresh()
end

function DragonflightUITalentsFrameMixin:OnEvent(event, ...)
    self:Refresh()
end

function DragonflightUITalentsFrameMixin:Refresh()
    if GetActiveTalentGroup then
        activeSpec = GetActiveTalentGroup()
    end

    for k, panel in ipairs(self.Panels) do panel:Refresh() end

    if PlayerTalentFrame and PlayerTalentFrame.UpdateDFHeaderText then
        PlayerTalentFrame.UpdateDFHeaderText()
    end
    self:RefreshCheckbox()
    self:RefreshSpecTabs()
    self:UpdateControls()
end

function DragonflightUITalentsFrameMixin:RefreshSpecTabs()
    local tab1 = _G['DragonflightUIPlayerTalentFrameSpecButton1']
    if tab1 and tab1.Update then tab1:Update() end

    local tab2 = _G['DragonflightUIPlayerTalentFrameSpecButton2']
    if tab2 and tab2.Update then tab2:Update() end
end

function DragonflightUITalentsFrameMixin:RefreshCheckbox()
    local check = self.Checkbox
    if not check then return end

    local preCVAR = C_CVar.GetCVarBool("previewTalentsOption")
    if preCVAR then
        check:SetChecked(true)
    else
        check:SetChecked(false)
    end
end

function DragonflightUITalentsFrameMixin:ToggleCVar()
    local preCVAR = C_CVar.GetCVarBool("previewTalentsOption")
    if preCVAR then
        C_CVar.SetCVar('previewTalentsOption', 0)
    else
        C_CVar.SetCVar('previewTalentsOption', 1)
    end
end

function DragonflightUITalentsFrameMixin:UpdateControls()
    local isActiveSpec = selectedSpec == activeSpec
    local activate = _G['DragonflightUIPlayerTalentFrameActivateButton']

    if activate then
        if isActiveSpec then
            activate:Hide()
        else
            activate:Show()
        end
    end

    local preview = GetCVarBool("previewTalentsOption");
    local learn = self.LearnButton
    local reset = self.ResetButton

    if learn and reset then
        if preview then
            learn:Show()
            reset:Show()

            local talentPoints = GetUnspentTalentPoints and GetUnspentTalentPoints(false, false, selectedSpec) or 0;
            local spent = GetGroupPreviewTalentPointsSpent and GetGroupPreviewTalentPointsSpent(false, selectedSpec) or 0;
            if (talentPoints > 0 and spent > 0) then
                learn:Enable();
                reset:Enable();
            else
                learn:Disable();
                reset:Disable();
            end
        else
            learn:Hide()
            reset:Hide()
        end
    end
end

DragonflightUIPlayerSpecMixin = {}

function DragonflightUIPlayerSpecMixin:OnLoad()
    local normalTexture = self:GetNormalTexture();
    if normalTexture then
        normalTexture:SetTexture('Interface\\Icons\\Ability_Marksmanship')
    end
end

function DragonflightUIPlayerSpecMixin:OnClick()
    PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB);
    local specIndex = self.specIndex;
    selectedSpec = specIndex

    if frameRef and frameRef.Refresh then
        frameRef:Refresh()
    end
    self:OnEnter()
end

function DragonflightUIPlayerSpecMixin:OnEnter()
    local specIndex = self.specIndex;

    GameTooltip:ClearLines()
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
    if specIndex == 1 then
        GameTooltip:AddLine(TALENT_SPEC_PRIMARY);
    else
        GameTooltip:AddLine(TALENT_SPEC_SECONDARY);

        if GetNumTalentGroups and GetNumTalentGroups() < 2 then
            GameTooltip_AddErrorLine(GameTooltip, 'Dual Talent Specialization not yet learned.')
            GameTooltip:Show()
            return
        end
    end

    if activeSpec == specIndex then
        GameTooltip:AddLine(TALENT_ACTIVE_SPEC_STATUS, GREEN_FONT_COLOR.r, GREEN_FONT_COLOR.g, GREEN_FONT_COLOR.b);
    end

    for i = 1, 3 do
        local id, name, description, iconTexture, pointsSpent, background, previewPointsSpent, isUnlocked =
            GetTalentTabInfo(i, false, false, specIndex)
        pointsSpent = pointsSpent or 0
        previewPointsSpent = previewPointsSpent or 0
        if name then
            GameTooltip:AddDoubleLine(name, pointsSpent + previewPointsSpent, HIGHLIGHT_FONT_COLOR.r,
                                      HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b, HIGHLIGHT_FONT_COLOR.r,
                                      HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)
        end
    end
    GameTooltip:Show()
end

function DragonflightUIPlayerSpecMixin:OnLeave()
    GameTooltip:Hide()
end

function DragonflightUIPlayerSpecMixin:Update()
    local specIndex = self.specIndex;

    if selectedSpec == specIndex then
        self:SetChecked(true)
    else
        self:SetChecked(false)
    end

    self:UpdateIcon()
end

function DragonflightUIPlayerSpecMixin:UpdateIcon()
    local normalTexture = self:GetNormalTexture();
    if not normalTexture then return end

    local specIndex = self.specIndex;
    local t = {}
    local icons = {}

    for i = 1, 3 do
        local id, name, description, iconTexture, pointsSpent, background, previewPointsSpent, isUnlocked =
            GetTalentTabInfo(i, false, false, specIndex)
        pointsSpent = pointsSpent or 0
        previewPointsSpent = previewPointsSpent or 0
        local totalPoints = pointsSpent + previewPointsSpent
        t[i] = totalPoints
        icons[i] = iconTexture
    end

    if (t[1] or 0) > (t[2] or 0) and (t[1] or 0) > (t[3] or 0) then
        normalTexture:SetTexture(icons[1])
    elseif (t[2] or 0) > (t[1] or 0) and (t[2] or 0) > (t[3] or 0) then
        normalTexture:SetTexture(icons[2])
    elseif (t[3] or 0) > (t[1] or 0) and (t[3] or 0) > (t[2] or 0) then
        normalTexture:SetTexture(icons[3])
    else
        normalTexture:SetTexture('Interface\\Icons\\Ability_Marksmanship')
    end
end

DragonflightUIPlayerSpecActivateMixin = {}

function DragonflightUIPlayerSpecActivateMixin:OnLoad()
    self:SetWidth(self:GetTextWidth() + 40);
end

function DragonflightUIPlayerSpecActivateMixin:OnClick()
    if selectedSpec then
        if SetActiveTalentGroup then
            SetActiveTalentGroup(selectedSpec)
        elseif C_SpecializationInfo and C_SpecializationInfo.SetActiveSpecGroup then
            C_SpecializationInfo.SetActiveSpecGroup(selectedSpec)
        end
    end
end

function DragonflightUIPlayerSpecActivateMixin:OnShow()
    self:RegisterEvent("CURRENT_SPELL_CAST_CHANGED");
    self:Update()
end

function DragonflightUIPlayerSpecActivateMixin:OnHide()
    self:UnregisterEvent("CURRENT_SPELL_CAST_CHANGED");
end

function DragonflightUIPlayerSpecActivateMixin:OnEvent(event, ...)
    self:Update()
end

function DragonflightUIPlayerSpecActivateMixin:Update()
    if selectedSpec and self:IsShown() then
        if TALENT_ACTIVATION_SPELLS and TALENT_ACTIVATION_SPELLS[selectedSpec] and
            IsCurrentSpell(TALENT_ACTIVATION_SPELLS[selectedSpec]) then
            self:Disable()
        else
            self:Enable()
        end
    end
end

DragonflightUIPlayerSpecPreviewLearnMixin = {}

function DragonflightUIPlayerSpecPreviewLearnMixin:OnEnter()
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
    GameTooltip:SetText(TALENT_TOOLTIP_LEARNTALENTGROUP);
end

function DragonflightUIPlayerSpecPreviewLearnMixin:OnLeave()
    GameTooltip:Hide()
end

function DragonflightUIPlayerSpecPreviewLearnMixin:OnClick()
    if UnitIsDeadOrGhost("player") then
        UIErrorsFrame:AddMessage(ERR_PLAYER_DEAD, 1.0, 0.1, 0.1, 1.0);
    else
        StaticPopup_Show("CONFIRM_LEARN_PREVIEW_TALENTS");
    end
end

DragonflightUIPlayerSpecPreviewResetMixin = {}

function DragonflightUIPlayerSpecPreviewResetMixin:OnEnter()
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
    GameTooltip:SetText(TALENT_TOOLTIP_RESETTALENTGROUP);
end

function DragonflightUIPlayerSpecPreviewResetMixin:OnLeave()
    GameTooltip:Hide()
end

function DragonflightUIPlayerSpecPreviewResetMixin:OnClick()
    if ResetGroupPreviewTalentPoints then
        ResetGroupPreviewTalentPoints(false, selectedSpec)
    end
end
