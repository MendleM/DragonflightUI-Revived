local addonName, addonTable = ...;
local Helper = addonTable.Helper;
---@diagnostic disable: undefined-global
---@class DragonflightUI
---@diagnostic disable-next-line: assign-type-mismatch
local DF = LibStub('AceAddon-3.0'):GetAddon('DragonflightUI')

local eraFix = true;
eraFix = DF.API.Version.IsClassic and (DF.API.Version.InterfaceVersion >= 11508) or DF.API.Version.IsTBC

DragonflightUIMixin = DragonflightUIMixin or {}

local base = 'Interface\\Addons\\DragonflightUI\\Textures\\UI\\'

function DragonflightUIMixin:CreateProfessionFrame()
    local frame = CreateFrame('FRAME', 'DragonflightUIProfessionFrame', UIParent,
                              'DragonflightUIProfessionFrameTemplate')
    return frame
end

function DragonflightUIMixin:CreateProfessionCraftFrame()
    local frame = CreateFrame('FRAME', 'DragonflightUIProfessionCraftFrame', UIParent,
                              'DragonflightUIProfessionCraftFrameTemplate')
    return frame
end

function DragonflightUIMixin:ChangeTradeskillFrameCata(frame)
    local regions = {frame:GetRegions()}
    for k, child in ipairs(regions) do
        if child:GetObjectType() == 'Texture' then
            local tex = child:GetTexture()
            if tex == 136797 then
                -- port
            elseif tex == 309665 then
                -- left
            elseif tex == 309666 then
                -- right
            end
        end
    end
end

function DragonflightUIMixin:ChangeTrainerFrame()
    if DF:IsAddOnLoaded('Leatrix_Plus') then
        if ClassTrainerFrame and ClassTrainerFrame:GetWidth() > 400 then
            DF:Print(
                "Leatrix_Plus detected with 'Interface -> Enhance trainers' activated - please deactivate or you might encounter bugs.")
        end
    end

    local frame = ClassTrainerFrame
    if not frame then return end

    local regions = {frame:GetRegions()}

    for k, child in ipairs(regions) do
        if child:GetObjectType() == 'Texture' then
            local layer, layerNr = child:GetDrawLayer()
            if layer == 'ARTWORK' then child:Hide() end
            if layer == 'BORDER' then child:Hide() end
        end
    end

    local frameW = 4 + 11 + 296 + 32 + 296 + 24 + 4 + 6
    local frameH = 520 + 16
    frame:SetSize(frameW, frameH)

    DragonflightUIMixin:AddNineSliceTextures(frame, true)
    DragonflightUIMixin:ButtonFrameTemplateNoPortrait(frame)
    DragonflightUIMixin:FrameBackgroundSolid(frame, true)

    if ClassTrainerFrameCloseButton then
        DragonflightUIMixin:UIPanelCloseButton(ClassTrainerFrameCloseButton)
        ClassTrainerFrameCloseButton:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', 1, 0)
    end

    local filterDropdown = ClassTrainerFrameFilterDropDown or (ClassTrainerFrame and ClassTrainerFrame.FilterDropdown)
    if filterDropdown and ClassTrainerFrameCloseButton then
        filterDropdown:SetPoint('TOPRIGHT', ClassTrainerFrameCloseButton, 'BOTTOMRIGHT', -4, -4)
    end

    if ClassTrainerNameText then
        ClassTrainerNameText:ClearAllPoints()
        ClassTrainerNameText:SetPoint('TOP', frame, 'TOP', 0, -5)
        ClassTrainerNameText:SetPoint('LEFT', frame, 'LEFT', 60, 0)
        ClassTrainerNameText:SetPoint('RIGHT', frame, 'RIGHT', -60, 0)
        ClassTrainerNameText:SetDrawLayer('OVERLAY', 7)
    end

    if ClassTrainerGreetingText then
        ClassTrainerGreetingText:ClearAllPoints()
        ClassTrainerGreetingText:SetPoint('TOPLEFT', frame, 'TOPLEFT', 62, -32)
        ClassTrainerGreetingText:SetDrawLayer('ARTWORK')
    end

    local closeButton = ClassTrainerCancelButton
    if closeButton then
        closeButton:ClearAllPoints()
        closeButton:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', -9, 7)
        closeButton:SetText(CLOSE)
    end

    local trainButton = ClassTrainerTrainButton
    if trainButton and closeButton then
        trainButton:ClearAllPoints()
        trainButton:SetPoint('RIGHT', closeButton, 'LEFT', 0, 0)
    end

    local icon = ClassTrainerSkillIcon
    if icon and ClassTrainerDetailScrollChildFrame then
        icon:SetPoint('TOPLEFT', ClassTrainerDetailScrollChildFrame, 'TOPLEFT', 12, -4)
    end

    local skillName = ClassTrainerSkillName
    if skillName and icon then
        skillName:SetPoint('TOPLEFT', icon, 'TOPRIGHT', 10, 0)
    end

    do
        local newMoney = CreateFrame('FRAME', 'DFTrainerMoneyFrame', frame)
        newMoney:SetSize(178 - 2 * 8, 17)
        if ClassTrainerFrameFilterDropDown then
            newMoney:SetPoint('RIGHT', ClassTrainerFrameFilterDropDown, 'LEFT', 0, 0)
        end

        local border = CreateFrame('FRAME', 'DFMoneyBorder', newMoney, 'ContainerMoneyFrameBorderTemplate')
        border:SetParent(newMoney)
        border:SetAllPoints()

        local money = ClassTrainerMoneyFrame
        if money then
            money:ClearAllPoints()
            money:SetPoint('RIGHT', newMoney, 'RIGHT', 0, 0)
        end
    end

    do
        local port = ClassTrainerFramePortrait
        if port then
            port:SetSize(62, 62)
            port:ClearAllPoints()
            port:SetPoint('TOPLEFT', -5, 7)
            port:SetDrawLayer('OVERLAY', 6)

            frame.PortraitFrame = frame:CreateTexture('DFPortraitFrame')
            local pp = frame.PortraitFrame
            pp:SetTexture(base .. 'UI-Frame-PortraitMetal-CornerTopLeft')
            pp:SetTexCoord(0.0078125, 0.0078125, 0.0078125, 0.6171875, 0.6171875, 0.0078125, 0.6171875, 0.6171875)
            pp:SetSize(84, 84)
            pp:ClearAllPoints()
            pp:SetPoint('CENTER', port, 'CENTER', 0, 0)
            pp:SetDrawLayer('OVERLAY', 7)
        end
    end

    do
        local inset = CreateFrame('Frame', 'DFTrainerInsetLeft', frame, 'InsetFrameTemplate')
        inset:SetPoint('TOPLEFT', 6, -70 + 6)
        inset:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMLEFT', 6 + 296 + 32 + 4, 6)
        frame.InsetLeft = inset

        local newBG = inset:CreateTexture('DragonflightUITrainerFrameInsetLeftBG')
        newBG:SetTexture(base .. 'professions')
        newBG:SetTexCoord(0.000488281, 0.131348, 0.0771484, 0.635742)
        newBG:SetSize(268, 572)
        newBG:ClearAllPoints()
        newBG:SetPoint('TOPLEFT', inset, 'TOPLEFT', 0, 0)
        newBG:SetPoint('BOTTOMRIGHT', inset, 'BOTTOMRIGHT', 0, 0)
        newBG:SetDrawLayer('BACKGROUND', -4)

        local oldBG = _G[inset:GetName() .. 'Bg']
        if oldBG then oldBG:Hide() end
    end

    do
        local inset = CreateFrame('Frame', 'DFTrainerInsetRight', frame, 'InsetFrameTemplate')
        inset:ClearAllPoints()
        inset:SetPoint('TOPLEFT', frame.InsetLeft, 'TOPRIGHT', 2, 0)
        inset:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', -6, 32)
        frame.InsetRight = inset

        local newBG = inset:CreateTexture('DragonflightUITrainerFrameInsetRightBG')
        newBG:SetTexture(base .. 'professionsminimizedview')
        newBG:SetTexCoord(0.00195312, 0.787109, 0.000976562, 0.576172 - 24 / 589)
        newBG:SetSize(402, 589)
        newBG:ClearAllPoints()
        newBG:SetPoint('TOPLEFT', inset, 'TOPLEFT', 0, 0)
        newBG:SetPoint('BOTTOMRIGHT', inset, 'BOTTOMRIGHT', 0, 0)
        newBG:SetDrawLayer('BACKGROUND', -4)

        local oldBG = _G[inset:GetName() .. 'Bg']
        if oldBG then oldBG:Hide() end
    end

    if frame.Bg then frame.Bg:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', -2, 2) end

    do
        local padding = 4
        local expand = ClassTrainerExpandButtonFrame
        if expand then
            expand:ClearAllPoints()
            expand:SetPoint('TOPLEFT', frame, 'TOPLEFT', padding, -70)

            local expandRegions = {expand:GetRegions()}
            for k, child in ipairs(expandRegions) do
                if child:GetObjectType() == 'Texture' then child:Hide() end
            end
        end

        local skill1 = ClassTrainerSkill1
        if skill1 then
            skill1:ClearAllPoints()
            skill1:SetPoint('TOPLEFT', frame, 'TOPLEFT', padding + 7, -100)
        end

        local oldTrainerSkillsDisplayed = CLASS_TRAINER_SKILLS_DISPLAYED or 11
        local newTrainerSkillsDisplayed = 25

        local deltaY = -1
        CLASS_TRAINER_SKILL_HEIGHT = 16 - deltaY

        local scroll = ClassTrainerListScrollFrame
        local scrollH = newTrainerSkillsDisplayed * (16 - deltaY)
        if scroll then
            scroll:ClearAllPoints()
            scroll:SetPoint("TOPLEFT", frame, "TOPLEFT", padding + 7, -70)
            scroll:SetSize(295, scrollH)

            local scrollRegions = {scroll:GetRegions()}
            for k, child in ipairs(scrollRegions) do
                if child:GetObjectType() == 'Texture' then child:Hide() end
            end
        end
        if ClassTrainerListScrollFrameScrollBar and scroll then
            ClassTrainerListScrollFrameScrollBar:SetPoint('TOPLEFT', scroll, 'TOPRIGHT', 6 + 4, -16)
            ClassTrainerListScrollFrameScrollBar:SetPoint('BOTTOMLEFT', scroll, 'BOTTOMRIGHT', 6 + 4, 16 - 30)
        end

        for i = 2, (CLASS_TRAINER_SKILLS_DISPLAYED or 11) do
            if _G["ClassTrainerSkill" .. i] and _G["ClassTrainerSkill" .. (i - 1)] then
                _G["ClassTrainerSkill" .. i]:ClearAllPoints()
                _G["ClassTrainerSkill" .. i]:SetPoint("TOPLEFT", _G["ClassTrainerSkill" .. (i - 1)], "BOTTOMLEFT", 0, deltaY)
            end
        end

        CLASS_TRAINER_SKILLS_DISPLAYED = newTrainerSkillsDisplayed

        for i = oldTrainerSkillsDisplayed + 1, newTrainerSkillsDisplayed do
            local btn = CreateFrame("Button", "ClassTrainerSkill" .. i, frame, "ClassTrainerSkillButtonTemplate")
            btn:SetID(i)
            btn:ClearAllPoints()
            if _G["ClassTrainerSkill" .. (i - 1)] then
                btn:SetPoint("TOPLEFT", _G["ClassTrainerSkill" .. (i - 1)], "BOTTOMLEFT", 0, deltaY)
            end
            btn:Hide()
        end

        local detail = ClassTrainerDetailScrollFrame
        if detail and scroll then
            detail:ClearAllPoints()
            detail:SetPoint("TOPLEFT", scroll, "TOPRIGHT", 32 + 6, 0)
            detail:SetSize(296, scrollH)
        end

        hooksecurefunc("ClassTrainer_SetToTradeSkillTrainer", function()
            CLASS_TRAINER_SKILLS_DISPLAYED = newTrainerSkillsDisplayed
            if ClassTrainerListScrollFrame then ClassTrainerListScrollFrame:SetHeight(scrollH) end
            if ClassTrainerDetailScrollFrame then ClassTrainerDetailScrollFrame:SetHeight(scrollH) end
        end)

        hooksecurefunc("ClassTrainer_SetToClassTrainer", function()
            CLASS_TRAINER_SKILLS_DISPLAYED = newTrainerSkillsDisplayed - 1
            if ClassTrainerListScrollFrame then ClassTrainerListScrollFrame:SetHeight(scrollH) end
            if ClassTrainerDetailScrollFrame then ClassTrainerDetailScrollFrame:SetHeight(scrollH) end
        end)
    end

    do
        local trainAll = CreateFrame('BUTTON', 'DragonflightUITrainerFrameTrainAllButton', frame,
                                     'UIPanelButtonTemplate')
        trainAll:SetSize(80, 22)
        trainAll:SetText('Train All')
        if trainButton then trainAll:SetPoint('RIGHT', trainButton, 'LEFT', -82, 0) end

        trainAll:SetScript('OnEnter', function(btn)
            local count = 0
            local cost = 0
            local numTrainerSkills = GetNumTrainerServices()

            for i = 1, numTrainerSkills do
                local name, rank, category, expanded = GetTrainerServiceInfo(i);
                if category and category == 'available' then
                    local moneyCost, talentCost, professionCost = GetTrainerServiceCost(i);
                    count = count + 1
                    cost = cost + (moneyCost or 0)
                end
            end

            if count > 0 then
                local coinString = C_CurrencyInfo.GetCoinTextureString(cost)
                GameTooltip:SetOwner(btn, 'ANCHOR_TOP', 0, 4)
                GameTooltip:ClearLines()
                GameTooltip:AddLine('Train ' .. count .. ' skill(s) for ' .. coinString)
                GameTooltip:Show()
            end
        end)

        trainAll:SetScript('OnClick', function(btn)
            local num = GetNumTrainerServices()
            for i = 1, num do
                local name, rank, category, expanded = GetTrainerServiceInfo(i);
                if category and category == 'available' then
                    BuyTrainerService(i)
                end
            end
        end)

        local skillsToBuy = function()
            local num = GetNumTrainerServices()
            for i = 1, num do
                local name, rank, category, expanded = GetTrainerServiceInfo(i);
                if category and category == 'available' then
                    return true
                end
            end
            return false
        end

        hooksecurefunc('ClassTrainerFrame_Update', function()
            local shouldShow = skillsToBuy()
            trainAll:SetEnabled(shouldShow)
            if trainAll:IsMouseOver() and shouldShow then
                local func = trainAll:GetScript("OnEnter")
                if func then func(trainAll) end
            end
        end)
    end

    ClassTrainerFrame:HookScript('OnShow', function()
        ClassTrainerFrame:SetAttribute("UIPanelLayout-width", ClassTrainerFrame:GetWidth());
        ClassTrainerFrame:SetAttribute("UIPanelLayout-" .. "xoffset", 0);
        ClassTrainerFrame:SetAttribute("UIPanelLayout-" .. "yoffset", 0);
        UpdateUIPanelPositions(ClassTrainerFrame)
    end)
end

function DragonflightUIMixin:ChangeDressupFrame()
    local frame = DressUpFrame
    if not frame then return end

    local regions = {frame:GetRegions()}

    for k, child in ipairs(regions) do
        if child:GetObjectType() == 'Texture' then
            local layer, layerNr = child:GetDrawLayer()
            if layer == 'ARTWORK' then child:Hide() end
        end
    end

    frame:SetSize(354, 447 + 6)

    if eraFix then
        frame:SetSize(354 - 20 - 2, 447 + 6 - 28 - 1)

        local slice = frame.NineSlice
        if slice then
            slice.TopLeftCorner = _G[frame:GetName() .. 'TopLeftCorner']
            if slice.TopLeftCorner then slice.TopLeftCorner:Show() end
            slice.TopRightCorner = _G[frame:GetName() .. 'TopRightCorner']

            slice.BottomLeftCorner = _G[frame:GetName() .. 'BtnCornerLeft']
            if _G[frame:GetName() .. 'BotLeftCorner'] then _G[frame:GetName() .. 'BotLeftCorner']:Hide() end
            slice.BottomRightCorner = _G[frame:GetName() .. 'BtnCornerRight']
            if _G[frame:GetName() .. 'BotRightCorner'] then _G[frame:GetName() .. 'BotRightCorner']:Hide() end

            slice.TopEdge = _G[frame:GetName() .. 'TopBorder']
            slice.BottomEdge = _G[frame:GetName() .. 'BottomBorder']
            if _G[frame:GetName() .. 'ButtonBottomBorder'] then _G[frame:GetName() .. 'ButtonBottomBorder']:Hide() end

            slice.LeftEdge = _G[frame:GetName() .. 'LeftBorder']
            slice.RightEdge = _G[frame:GetName() .. 'RightBorder']
        end
    end

    DragonflightUIMixin:AddNineSliceTextures(frame, true)
    DragonflightUIMixin:ButtonFrameTemplateNoPortrait(frame)

    if DressUpFrameCloseButton then
        DragonflightUIMixin:UIPanelCloseButton(DressUpFrameCloseButton)
        DressUpFrameCloseButton:SetPoint('TOPRIGHT', DressUpFrame, 'TOPRIGHT', 1, 0)
    end

    if DressUpFrameCancelButton then
        DressUpFrameCancelButton:ClearAllPoints()
        DressUpFrameCancelButton:SetPoint('BOTTOMRIGHT', DressUpFrame, 'BOTTOMRIGHT', -7, 5)
    end

    local container = DressUpFrame.TitleContainer;
    if container then
        local newTitle = container:CreateFontString('DFDressUpFrameTitleText', 'OVERLAY', 'GameFontHighlight')
        newTitle:SetText(DRESSUP_FRAME)
        newTitle:SetHeight(14)
        newTitle:SetPoint('TOP', DressUpFrame, 'TOP', 0, -4)
        newTitle:SetPoint('LEFT', DressUpFrame, 'LEFT', 60, 0)
        newTitle:SetPoint('RIGHT', DressUpFrame, 'RIGHT', -30, 0)

        if DressUpFrameDescriptionText then
            DressUpFrameDescriptionText:ClearAllPoints()
            DressUpFrameDescriptionText:SetPoint('TOP', newTitle, 'BOTTOM', 6, -6)
        end
    end

    if DressUpModelFrame then
        DressUpModelFrame:ClearAllPoints()
        DressUpModelFrame:SetPoint('TOPLEFT', DressUpFrame, 'TOPLEFT', 19, -75)
        DressUpModelFrame:SetHeight(351 - 18)

        if eraFix then
            DressUpModelFrame:SetPoint('TOPLEFT', DressUpFrame, 'TOPLEFT', 19 - 10 - 2, -75 + 10 + 1)
        end
    end

    if DressUpFrameBackgroundTopLeft and DressUpModelFrame then
        DressUpFrameBackgroundTopLeft:SetPoint('TOPLEFT', DressUpFrame, 'TOPLEFT', 19, -75)
        if eraFix then
            DressUpFrameBackgroundTopLeft:ClearAllPoints()
            DressUpFrameBackgroundTopLeft:SetPoint('TOPLEFT', DressUpModelFrame, 'TOPLEFT', 0, 0)
        end
    end

    local rotateBtn = DressUpModelFrameRotateRightButton
    if rotateBtn and DressUpModelFrame then
        rotateBtn:ClearAllPoints()
        rotateBtn:SetPoint('TOPLEFT', DressUpModelFrame, 'TOPLEFT', 0, -4)
    end

    do
        local port = DressUpFramePortrait
        if port then
            port:SetSize(62, 62)
            port:ClearAllPoints()
            port:SetPoint('TOPLEFT', -5, 7)
            port:SetDrawLayer('OVERLAY', 6)

            local pp = frame.PortraitFrame or frame:CreateTexture('PortraitFrame')
            frame.PortraitFrame = pp
            pp:SetTexture(base .. 'UI-Frame-PortraitMetal-CornerTopLeft')
            pp:SetTexCoord(0.0078125, 0.0078125, 0.0078125, 0.6171875, 0.6171875, 0.0078125, 0.6171875, 0.6171875)
            pp:SetSize(84, 84)
            pp:ClearAllPoints()
            pp:SetPoint('CENTER', port, 'CENTER', 0, 0)
            pp:SetDrawLayer('OVERLAY', 7)
        end
    end

    DragonflightUIMixin:FrameBackgroundSolid(frame, true)

    ShowUIPanel(frame)
    DressUpFrame:SetAttribute("UIPanelLayout-" .. "xoffset", 0);
    DressUpFrame:SetAttribute("UIPanelLayout-" .. "yoffset", 0);
    HideUIPanel(frame)
end

function DragonflightUIMixin:EnhanceDressupFrame()
    if not DressUpModelFrame then return end

    DressUpModelFrame:EnableMouseWheel(true)
    DressUpModelFrame:HookScript('OnMouseWheel', Model_OnMouseWheel)
    DressUpModelFrame:HookScript('OnMouseDown', function(self, button)
        if button == 'RightButton' then Model_StartPanning(self) end
    end)
    DressUpModelFrame:HookScript('OnMouseUp', function(self, button)
        Model_StopPanning(self)
    end)

    if DressUpFrameResetButton then
        DressUpFrameResetButton:HookScript('OnClick', function()
            DressUpModelFrame:SetRotation(0)
            DressUpModelFrame:SetPosition(0, 0, 0)
            DressUpModelFrame:SetPortraitZoom(0)
            DressUpModelFrame:RefreshCamera()
        end)
    end
end

function DragonflightUIMixin:ChangeTaxiFrame()
    local frame = TaxiFrame
    if not frame then return end

    local regions = {frame:GetRegions()}
    for k, child in ipairs(regions) do
        if child:GetObjectType() == 'Texture' then
            child:Hide()
        end
    end

    frame:SetSize(332, 424)

    DragonflightUIMixin:AddNineSliceTextures(frame, true)
    DragonflightUIMixin:ButtonFrameTemplateNoPortrait(frame)
    DragonflightUIMixin:FrameBackgroundSolid(frame, true)

    local header = TaxiMerchant
    if header then
        header:ClearAllPoints()
        header:SetPoint('TOP', frame, 'TOP', 0, -5)
        header:SetPoint('LEFT', frame, 'LEFT', 60, 0)
        header:SetPoint('RIGHT', frame, 'RIGHT', -60, 0)
    end

    local closeButton = TaxiCloseButton
    if closeButton then
        DragonflightUIMixin:UIPanelCloseButton(closeButton)
        closeButton:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', 1, 0)
    end

    do
        local map = TaxiRouteMap
        if map then
            map:ClearAllPoints()
            map:SetPoint('TOPLEFT', frame, 'TOPLEFT', 8, -62)
        end

        local taxi = TaxiMap
        if taxi then
            taxi:Show()
            taxi:ClearAllPoints()
            taxi:SetPoint('TOPLEFT', frame, 'TOPLEFT', 8, -62)
        end
    end

    do
        local port = TaxiPortrait
        if port then
            port:SetSize(62, 62)
            port:ClearAllPoints()
            port:SetPoint('TOPLEFT', frame, 'TOPLEFT', -5, 7)
            port:SetDrawLayer('OVERLAY', 6)
            port:SetParent(frame)
            port:Show()

            frame.PortraitFrame = frame:CreateTexture('PortraitFrame')
            local pp = frame.PortraitFrame
            pp:SetTexture(base .. 'UI-Frame-PortraitMetal-CornerTopLeft')
            pp:SetTexCoord(0.0078125, 0.0078125, 0.0078125, 0.6171875, 0.6171875, 0.0078125, 0.6171875, 0.6171875)
            pp:SetSize(84, 84)
            pp:ClearAllPoints()
            pp:SetPoint('CENTER', port, 'CENTER', 0, 0)
            pp:SetDrawLayer('OVERLAY', 7)
        end
    end
end

function DragonflightUIMixin:ImproveTaxiFrame()
    if not TaxiFrame then return end

    do
        local minmax =
            CreateFrame('Button', 'DFTaxiFrameMinMaxButton', TaxiFrame, 'MaximizeMinimizeButtonFrameTemplate')
        minmax:SetSize(32, 32)
        if TaxiCloseButton then minmax:SetPoint('RIGHT', TaxiCloseButton, 'LEFT', 0, 0) end
        DragonflightUIMixin:MaximizeMinimizeButtonFrameTemplate(minmax)
        minmax:Hide()
    end

    local scale = 1.3
    local padding = 8
    local deltaY = 62

    TAXI_MAP_WIDTH = 316 * scale
    TAXI_MAP_HEIGHT = 352 * scale
    if TaxiMap then
        TaxiMap:SetWidth(TAXI_MAP_WIDTH)
        TaxiMap:SetHeight(TAXI_MAP_HEIGHT)
    end
    if TaxiRouteMap then
        TaxiRouteMap:SetWidth(TAXI_MAP_WIDTH)
        TaxiRouteMap:SetHeight(TAXI_MAP_HEIGHT)
    end

    TaxiFrame:SetWidth(TAXI_MAP_WIDTH + 2 * padding)
    TaxiFrame:SetHeight(TAXI_MAP_HEIGHT + deltaY + padding)

    TaxiFrame:HookScript('OnShow', function()
        TaxiFrame:SetAttribute("UIPanelLayout-width", TaxiFrame:GetWidth());
        TaxiFrame:SetAttribute("UIPanelLayout-" .. "xoffset", 0);
        TaxiFrame:SetAttribute("UIPanelLayout-" .. "yoffset", 0);
        UpdateUIPanelPositions(TaxiFrame)
    end)
end

function DragonflightUIMixin:ChangeTaxiFrameMists()
    local frame = TaxiFrame
    if not frame then return end

    local regions = {frame:GetRegions()}

    for k, child in ipairs(regions) do
        if child:GetObjectType() == 'Texture' then
            local drawlayer, level = child:GetDrawLayer()
            if drawlayer == 'OVERLAY' then
                child:Hide()
            end
            if level and level < 0 then child:Hide() end
        end
    end

    if frame.BottomBorder then frame.BottomBorder:Hide() end
    if frame.RightBorder then frame.RightBorder:Hide() end
    if frame.LeftBorder then frame.LeftBorder:Hide() end
    if frame.BotLeftCorner then frame.BotLeftCorner:Hide() end
    if frame.BotRightCorner then frame.BotRightCorner:Hide() end

    DragonflightUIMixin:AddNineSliceTextures(frame, true)
    DragonflightUIMixin:ButtonFrameTemplateNoPortrait(frame)
    DragonflightUIMixin:FrameBackgroundSolid(frame, true)

    local closeButton = frame.CloseButton
    if closeButton then
        DragonflightUIMixin:UIPanelCloseButton(closeButton)
        closeButton:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', 1, 0)
    end

    if frame.Bg then frame.Bg:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', -3 + 1, 3) end
    if frame.InsetBg then frame.InsetBg:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', -6 + 2, 4) end
end

function DragonflightUIMixin:ChangeTradeFrame()
    local frame = TradeFrame
    if not frame then return end

    DragonflightUIMixin:PortraitFrameTemplate(frame)

    if TradeFramePlayerPortrait then TradeFramePlayerPortrait:SetDrawLayer('OVERLAY', 6) end

    do
        local port = TradeFrameRecipientPortrait
        if port then
            port:SetSize(62, 62)
            port:ClearAllPoints()
            port:SetPoint('TOPLEFT', frame, 'TOPRIGHT', -180, 7)
            port:SetDrawLayer('OVERLAY', 6)

            local pp = _G['TradeRecipientPortraitFrame']
            if pp then
                pp:SetTexture(base .. 'UI-Frame-PortraitMetal-CornerTopLeft')
                pp:SetSize(84, 84)
                pp:ClearAllPoints()
                pp:SetPoint('CENTER', port, 'CENTER', 0, 0)
                pp:SetDrawLayer('OVERLAY', 7)
            end
        end
    end

    do
        if TradeFramePlayerNameText then
            TradeFramePlayerNameText:SetDrawLayer('OVERLAY', 1)
            TradeFramePlayerNameText:ClearAllPoints()
            TradeFramePlayerNameText:SetPoint('TOPLEFT', frame, 'TOPLEFT', 65 - 6, -5)
            TradeFramePlayerNameText:SetSize(100, 12)
        end

        if TradeFrameRecipientNameText then
            TradeFrameRecipientNameText:SetDrawLayer('OVERLAY', 1)
            TradeFrameRecipientNameText:ClearAllPoints()
            TradeFrameRecipientNameText:SetPoint('TOPLEFT', frame, 'TOPLEFT', 230, -5)
            TradeFrameRecipientNameText:SetSize(80 + 8, 12)
        end
    end

    do
        local tex = base .. 'UIFrameMetalVertical2x'
        local left = _G['TradeRecipientLeftBorder']
        if left and _G['TradeRecipientPortraitFrame'] and _G['TradeRecipientBotLeftCorner'] then
            left:SetTexture(tex)
            left:SetTexCoord(0.00195312, 0.294922, 0, 1)
            left:SetSize(75, 16)
            left:SetPoint('TOPLEFT', _G['TradeRecipientPortraitFrame'], 'BOTTOMLEFT', 8, 0 + 20)
            left:SetPoint('BOTTOMLEFT', _G['TradeRecipientBotLeftCorner'], 'TOPLEFT', 0, 0 - 20)
        end
    end

    do
        local tex = base .. 'uiframemetal2x'
        local bottom = _G['TradeRecipientBotLeftCorner']
        if bottom then
            bottom:SetTexture(tex)
            bottom:SetTexCoord(0.298828, 0.423828, 0.298828, 0.423828)
            bottom:SetSize(32, 32)
            bottom:SetPoint('BOTTOMLEFT', TradeFrame, 'BOTTOMRIGHT', -178 - 5, -3)
        end
    end

    do
        local recipBG = _G['TradeRecipientBG']
        if recipBG then
            recipBG:SetPoint('BOTTOMRIGHT', TradeFrame, 'BOTTOMRIGHT', -2, 2)
        end
    end
end

function DragonflightUIMixin:ChangeLFGListingFrameEra()
    local frame = LFGListingFrame
    local parentFrame = LFGParentFrame
    if not frame then return end

    DragonflightUIMixin:AddNineSliceTextures(frame, true)
    DragonflightUIMixin:ButtonFrameTemplateNoPortrait(frame)
    DragonflightUIMixin:FrameBackgroundSolid(frame, true)

    frame:SetSize(338 - 2, 424)
    if parentFrame then parentFrame:SetSize(338 - 2, 424) end

    if _G['LFGListingFrameFrameBackgroundTop'] then _G['LFGListingFrameFrameBackgroundTop']:Hide() end
    if _G['LFGListingFrameFrameBackgroundBottom'] then _G['LFGListingFrameFrameBackgroundBottom']:Hide() end

    do
        local port = _G['LFGParentFramePortrait']
        if port then
            port:SetSize(62, 62)
            port:ClearAllPoints()
            port:SetPoint('TOPLEFT', -5, 7)

            frame.PortraitFrame = frame:CreateTexture('PortraitFrame')
            local pp = frame.PortraitFrame
            pp:SetTexture(base .. 'UI-Frame-PortraitMetal-CornerTopLeft')
            pp:SetTexCoord(0.0078125, 0.0078125, 0.0078125, 0.6171875, 0.6171875, 0.0078125, 0.6171875, 0.6171875)
            pp:SetSize(84, 84)
            pp:ClearAllPoints()
            pp:SetPoint('CENTER', port, 'CENTER', 0, 0)
            pp:SetDrawLayer('OVERLAY', 7)

            local icon = _G['LFGParentFramePortraitIcon']
            if icon then icon:SetDrawLayer('OVERLAY', 7) end

            local text = _G['LFGParentFramePortraitTexture']
            if text then text:SetDrawLayer('OVERLAY', 7) end
        end
    end
end

function DragonflightUIMixin:ChangeTBCPVPFrame()
    local frame = _G['PVPFrame']
    if not frame then return end

    local regions = {frame:GetRegions()}
    for k, child in ipairs(regions) do
        if child:GetObjectType() == 'Texture' then
            child:Hide()
        end
    end

    local frameBG = _G['PVPFrameBackground']
    if frameBG then
        frameBG:Show()
        frameBG:SetPoint('TOPLEFT', frame, 'TOPLEFT', 14 - 14, -36 + 14)
        frameBG:SetSize(512 - 5, 512)
    end

    local seasonStatsBtn = _G['PVPFrameToggleButton']
    if seasonStatsBtn then
        seasonStatsBtn:ClearAllPoints()
        seasonStatsBtn:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', -10, 6)
    end
end

function DragonflightUIMixin:ChangeWrathPVPFrame()
    local frame = _G['PVPFrame']
    if not frame then return end

    local regions = {frame:GetRegions()}
    for k, child in ipairs(regions) do
        if child:GetObjectType() == 'Texture' then
            local layer, layerNr = child:GetDrawLayer()
            if layer == 'ARTWORK' then child:Hide() end
        end
    end

    frame.PortraitFrame = frame:CreateTexture('PortraitFrame')
end
