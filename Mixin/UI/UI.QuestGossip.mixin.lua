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

function DragonflightUIMixin:ChangeLootFrame()
    local frame = LootFrame
    DragonflightUIMixin:PortraitFrameTemplate(frame)

    local regions = {frame:GetRegions()}

    for k, child in ipairs(regions) do
        if child:GetObjectType() == 'FontString' and child:GetText() == ITEMS then
            child:Hide()
        end
    end

    local header = frame:CreateFontString('DFLootFrameTitle', 'OVERLAY', 'GameFontNormal')
    header:SetText(ITEMS)
    header:SetPoint('TOP', frame, 'TOP', 12, -5)
    frame.DFHeader = header

    local topleft = _G[frame:GetName() .. 'TopLeftCornerDF']
    if topleft then topleft:SetDrawLayer('OVERLAY', -2) end

    local port = _G['LootFramePortrait']
    if port then port:SetDrawLayer('OVERLAY', 7) end
end

function DragonflightUIMixin:ChangeQuestFrame()
    local frame = QuestFrame
    local detail = QuestFrameDetailPanel
    local reward = QuestFrameRewardPanel
    local progress = QuestFrameProgressPanel
    local greeting = QuestFrameGreetingPanel

    local regions = {detail:GetRegions()}

    for k, child in ipairs(regions) do
        if child:GetObjectType() == 'Texture' then
            local tex = child:GetTexture()
            if tex == 136785 or tex == 136791 or tex == 136792 or tex == 136793 or tex == 136794 then
                child:Hide()
            end
        end
    end

    local regionsReward = {reward:GetRegions()}
    for k, child in ipairs(regionsReward) do
        if child:GetObjectType() == 'Texture' then child:Hide() end
    end

    local regionsProgress = {progress:GetRegions()}
    for k, child in ipairs(regionsProgress) do
        if child:GetObjectType() == 'Texture' then child:Hide() end
    end

    local regionsGreeting = {greeting:GetRegions()}
    for k, child in ipairs(regionsGreeting) do
        if child:GetObjectType() == 'Texture' then child:Hide() end
    end

    frame:SetSize(338, 496)
    detail:SetSize(338, 496)
    reward:SetSize(338, 496)
    progress:SetSize(338, 496)
    greeting:SetSize(338, 496)

    if DF.API.Version.IsTBC then
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

        if _G['QuestFramePortraitFrame'] then _G['QuestFramePortraitFrame']:Hide() end
    end

    DragonflightUIMixin:AddNineSliceTextures(frame, true)
    DragonflightUIMixin:ButtonFrameTemplateNoPortrait(frame)

    if DF.API.Version.IsMoP then
        DragonflightUIMixin:FrameBackgroundSolidMoP(frame, true)
    else
        DragonflightUIMixin:FrameBackgroundSolid(frame, true)
    end

    local header = QuestNpcNameFrame
    header:ClearAllPoints()
    header:SetPoint('TOP', QuestFrame, 'TOP', 0, -5)
    header:SetPoint('LEFT', QuestFrame, 'LEFT', 60, 0)
    header:SetPoint('RIGHT', QuestFrame, 'RIGHT', -60, 0)

    local closeButton = QuestFrameCloseButton
    DragonflightUIMixin:UIPanelCloseButton(closeButton)
    closeButton:SetPoint('TOPRIGHT', QuestFrame, 'TOPRIGHT', 1, 0)

    local decline = QuestFrameDeclineButton
    if decline then decline:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', -6, 4) end

    local cancel = QuestFrameCancelButton
    if cancel then cancel:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', -6, 4) end

    local accept = QuestFrameAcceptButton
    if accept then accept:SetPoint('BOTTOMLEFT', frame, 'BOTTOMLEFT', 6, 4) end

    local complete = QuestFrameCompleteQuestButton
    if complete then complete:SetPoint('BOTTOMLEFT', frame, 'BOTTOMLEFT', 6, 4) end

    local gb = QuestFrameGoodbyeButton
    if gb then gb:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', -6, 4) end

    local greetGb = QuestFrameGreetingGoodbyeButton
    if greetGb then greetGb:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', -6, 4) end

    local completeP = QuestFrameCompleteButton
    if completeP then completeP:SetPoint('BOTTOMLEFT', frame, 'BOTTOMLEFT', 6, 4) end

    if DF.API.Version.IsTBC then
        detail:ClearAllPoints()
        detail:SetPoint('TOPLEFT')

        local detailBG = _G['QuestFrameDetailPanelBg']
        if detailBG then detailBG:Hide() end

        local scroll = QuestDetailScrollFrame
        if scroll then scroll:ClearAllPoints() end
    end

    do
        local scroll = QuestDetailScrollFrame
        scroll:SetSize(300, 403)
        scroll:SetPoint('TOPLEFT', detail, 'TOPLEFT', 8, -65)

        local deltaX = 4
        local deltaY = 20
        local bar = QuestDetailScrollFrameScrollBar
        bar:SetPoint('TOPLEFT', scroll, 'TOPRIGHT', 6 - 5 + deltaX, -3 - deltaY)
        bar:SetPoint('BOTTOMLEFT', scroll, 'BOTTOMRIGHT', 6 - 5 + deltaX, 3 + deltaY)

        if QuestDetailScrollFrameTop then QuestDetailScrollFrameTop:Hide() end
        if QuestDetailScrollFrameMiddle then QuestDetailScrollFrameMiddle:Hide() end
        if QuestDetailScrollFrameBottom then QuestDetailScrollFrameBottom:Hide() end
    end

    do
        local scroll = QuestRewardScrollFrame
        scroll:SetSize(300, 403)
        scroll:SetPoint('TOPLEFT', reward, 'TOPLEFT', 8, -65)

        if DF.API.Version.IsTBC then
            reward:ClearAllPoints()
            reward:SetPoint('TOPLEFT')
        end
    end

    do
        local scroll = QuestProgressScrollFrame
        scroll:SetSize(300, 403)
        scroll:SetPoint('TOPLEFT', progress, 'TOPLEFT', 8, -65)

        if DF.API.Version.IsTBC then
            progress:ClearAllPoints()
            progress:SetPoint('TOPLEFT')
        end
    end

    do
        local scroll = QuestGreetingScrollFrame
        scroll:SetSize(300, 403)
        scroll:SetPoint('TOPLEFT', greeting, 'TOPLEFT', 8, -65)
    end

    do
        local tex = base .. 'questbackgroundparchment'
        local bg = frame:CreateTexture('DFQuestBackground')
        bg:SetTexture(tex)
        bg:SetTexCoord(0.0009765625, 0.29296875, 0.0009765625, 0.3984375)
        bg:SetSize(299, 407)
        bg:SetDrawLayer('BACKGROUND', 0)
        bg:SetPoint('TOPLEFT', detail, 'TOPLEFT', 7, -62)
    end

    do
        local port = QuestFramePortrait
        port:SetSize(62, 62)
        port:ClearAllPoints()
        port:SetPoint('TOPLEFT', frame, 'TOPLEFT', -5, 7)
        port:SetDrawLayer('OVERLAY', 6)
        port:SetParent(frame)

        frame.PortraitFrame = frame:CreateTexture('PortraitFrame')
        local pp = frame.PortraitFrame
        pp:SetTexture(base .. 'UI-Frame-PortraitMetal-CornerTopLeft')
        pp:SetTexCoord(0.0078125, 0.0078125, 0.0078125, 0.6171875, 0.6171875, 0.0078125, 0.6171875, 0.6171875)
        pp:SetSize(84, 84)
        pp:ClearAllPoints()
        pp:SetPoint('CENTER', port, 'CENTER', 0, 0)
        pp:SetDrawLayer('OVERLAY', 7)
    end

    ShowUIPanel(frame)
    frame:SetAttribute("UIPanelLayout-" .. "xoffset", 0);
    frame:SetAttribute("UIPanelLayout-" .. "yoffset", 0);
    HideUIPanel(frame)
end

function DragonflightUIMixin:ShowQuestXP()
    if not QuestLogFrame.DFQuestXP then
        local str = QuestLogDetailScrollChildFrame:CreateFontString('DragonflightUIQuestXPText', 'OVERLAY', 'QuestFont')
        str:SetText(REWARD_ITEMS)

        local strXP = QuestLogDetailScrollChildFrame:CreateFontString('DragonflightUIQuestXPText2', 'OVERLAY',
                                                                      'QuestFont')
        strXP:SetText(FormatLargeNumber(9999999) .. ' XP')
        strXP:SetPoint('LEFT', str, 'RIGHT', 15, 0)

        QuestLogFrame.DFQuestXP = str
        QuestLogFrame.DFQuestXP2 = strXP
    end

    local function hookFunc(questLogIndex)
        local point, relativeToOrig, relativePoint, xOfs, yOfs = QuestLogSpacerFrame:GetPoint(1)

        local relativeTo = relativeToOrig
        local str = QuestLogFrame.DFQuestXP
        local strXP = QuestLogFrame.DFQuestXP2
        local rewardText = _G['QuestLogRewardTitleText']

        local receiveText = _G['QuestLogItemReceiveText']
        local chooseText = _G['QuestLogItemChooseText']

        str:ClearAllPoints()

        if receiveText:IsVisible() then
            str:SetPoint('LEFT', receiveText, 'LEFT', 0, 0)
        elseif chooseText:IsVisible() then
            str:SetPoint('LEFT', chooseText, 'LEFT', 0, 0)
        else
            str:SetPoint('LEFT', rewardText, 'LEFT', 3, 0)
        end

        local material = QuestFrame_GetMaterial();
        QuestFrame_SetTextColor(str, material);

        if rewardText:IsShown() then
            str:SetText(REWARD_ITEMS)
            str:SetPoint('TOP', relativeTo, 'BOTTOM', 0, -5)
            QuestFrame_SetAsLastShown(str, nil)
        else
            rewardText:Show();
            QuestFrame_SetTitleTextColor(rewardText, material);
            QuestFrame_SetAsLastShown(rewardText, nil);

            str:SetText(REWARD_ITEMS_ONLY)
            str:SetPoint('TOP', rewardText, 'BOTTOM', 0, -5)
            QuestFrame_SetAsLastShown(str, nil)
        end

        local xp = GetQuestLogRewardXP()
        local xpText = FormatLargeNumber(xp) .. ' XP';
        strXP:SetText(xpText)

        if QuestLogFrame.DFCompletedQuestsFrame then QuestLogFrame.DFCompletedQuestsFrame:Update() end
    end

    hooksecurefunc('QuestFrameItems_Update', hookFunc)
end

function DragonflightUIMixin:GetCompletedQuestsAndXP()
    local numEntries, numQuests = GetNumQuestLogEntries();
    local returnTable = {}
    returnTable.completedQuests = {};
    returnTable.numQuests = numQuests;
    returnTable.numCompletedQuests = 0;
    returnTable.numQuestXP = 0;

    if DF.API.Version.IsCata or DF.API.Version.IsMoP then
        local currentSelection = GetQuestLogSelection()
        for i = 1, numEntries do
            local title, level, suggestedGroup, isHeader, isCollapsed, isComplete, frequency, questID, startEvent,
                  displayQuestID, isOnMap, hasLocalPOI, isTask, isBounty, isStory, isHidden, isScaling =
                GetQuestLogTitle(i);

            if isComplete then
                SelectQuestLogEntry(i)

                local questXP, questLevel = GetQuestLogRewardXP();
                returnTable.numCompletedQuests = returnTable.numCompletedQuests + 1;
                returnTable.numQuestXP = returnTable.numQuestXP + questXP;

                local info = {title = title, questID = questID, questXP = questXP, questLevel = questLevel};
                table.insert(returnTable.completedQuests, info);
            end
        end

        SelectQuestLogEntry(currentSelection)
        return returnTable;
    end
    for i = 1, numEntries do
        local title, level, suggestedGroup, isHeader, isCollapsed, isComplete, frequency, questID, startEvent,
              displayQuestID, isOnMap, hasLocalPOI, isTask, isBounty, isStory, isHidden, isScaling = GetQuestLogTitle(i);
        if isComplete then
            ---@diagnostic disable-next-line: redundant-parameter
            local questXP, questLevel = GetQuestLogRewardXP(questID);
            returnTable.numCompletedQuests = returnTable.numCompletedQuests + 1;
            returnTable.numQuestXP = returnTable.numQuestXP + questXP;

            local info = {title = title, questID = questID, questXP = questXP, questLevel = questLevel};
            table.insert(returnTable.completedQuests, info);
        end
    end

    return returnTable;
end

function DragonflightUIMixin:ChangeGossipFrame()
    local frame = GossipFrame
    local greeting = frame.GreetingPanel

    local regions = {greeting:GetRegions()}

    for k, child in ipairs(regions) do
        if child:GetObjectType() == 'Texture' then
            local tex = child:GetTexture()
            if tex == 136785 or tex == 136791 or tex == 136792 or tex == 136793 or tex == 136794 then
                child:Hide()
            end
        end
    end

    frame:SetSize(338, 496)
    greeting:SetSize(338, 496)

    if DF.API.Version.IsMoP or eraFix then
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

        if _G['GossipFramePortraitFrame'] then _G['GossipFramePortraitFrame']:Hide() end
    end

    DragonflightUIMixin:AddNineSliceTextures(frame, true)
    DragonflightUIMixin:ButtonFrameTemplateNoPortrait(frame)
    DragonflightUIMixin:FrameBackgroundSolid(frame, true)

    local header = frame.TitleContainer
    header:ClearAllPoints()
    header:SetPoint('TOP', GossipFrame, 'TOP', 0, -5)
    header:SetPoint('LEFT', GossipFrame, 'LEFT', 60, 0)
    header:SetPoint('RIGHT', GossipFrame, 'RIGHT', -60, 0)

    local closeButton = frame.CloseButton
    DragonflightUIMixin:UIPanelCloseButton(closeButton)
    closeButton:SetPoint('TOPRIGHT', GossipFrame, 'TOPRIGHT', 1, 0)

    local gbButton = greeting.GoodbyeButton
    if gbButton then gbButton:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', -6, 4) end

    do
        local scroll = greeting.ScrollBox
        if scroll then
            scroll:SetSize(300, 403)
            if DF.API.Version.IsMoP or eraFix then
                scroll:SetPoint('TOPLEFT', frame, 'TOPLEFT', 8, -65)
            else
                scroll:SetPoint('TOPLEFT', greeting, 'TOPLEFT', 8, -65)
            end

            local bar = greeting.ScrollBar
            if bar then
                bar:SetPoint('TOPLEFT', scroll, 'TOPRIGHT', 6 - 5, -3)
                bar:SetPoint('BOTTOMLEFT', scroll, 'BOTTOMRIGHT', 6 - 5, 3)
            end
        end
    end

    do
        local tex = base .. 'questbackgroundparchment'
        local anchorFrame;

        if DF.API.Version.IsMoP or DF.API.Version.IsClassic or DF.API.Version.IsTBC then
            anchorFrame = frame;
            local r = {frame:GetRegions()}
            for k, child in ipairs(r) do
                if child:GetObjectType() == 'Texture' then
                    local w, h = child:GetSize()
                    local layer = child:GetDrawLayer()
                    if layer == 'BACKGROUND' and w == 512 and h == 512 then
                        child:Hide()
                    end
                end
            end
        else
            anchorFrame = greeting;
        end

        local bg = frame:CreateTexture('DFQuestBackground')
        bg:SetPoint('TOPLEFT', anchorFrame, 'TOPLEFT', 7, -62)
        bg:SetTexture(tex)
        bg:SetTexCoord(0.0009765625, 0.29296875, 0.0009765625, 0.3984375)
        bg:SetSize(299, 407)
        bg:SetDrawLayer('BACKGROUND', 0)
    end

    do
        local port = GossipFramePortrait
        port:SetSize(62, 62)
        port:ClearAllPoints()
        port:SetPoint('TOPLEFT', frame, 'TOPLEFT', -5, 7)
        port:SetDrawLayer('OVERLAY', 6)
        port:SetParent(frame)

        frame.PortraitFrame = frame:CreateTexture('PortraitFrame')
        local pp = frame.PortraitFrame
        pp:SetTexture(base .. 'UI-Frame-PortraitMetal-CornerTopLeft')
        pp:SetTexCoord(0.0078125, 0.0078125, 0.0078125, 0.6171875, 0.6171875, 0.0078125, 0.6171875, 0.6171875)
        pp:SetSize(84, 84)
        pp:ClearAllPoints()
        pp:SetPoint('CENTER', port, 'CENTER', 0, 0)
        pp:SetDrawLayer('OVERLAY', 7)
    end

    ShowUIPanel(frame)
    frame:SetAttribute("UIPanelLayout-" .. "xoffset", 0);
    frame:SetAttribute("UIPanelLayout-" .. "yoffset", 0);
    HideUIPanel(frame)
end

function DragonflightUIMixin:ChangeQuestLogFrameEra()
    local frame = QuestLogFrame
    local regions = {frame:GetRegions()}
    local port

    for k, child in ipairs(regions) do
        if child:GetObjectType() == 'Texture' then
            local tex = child:GetTexture()
            if tex == 136797 then
                port = child
            else
                child:Hide()
            end
        end
    end

    do
        local left = frame:CreateTexture('DragonflightUIQuestLogDualPane-Left')
        left:SetSize(512, 445)
        left:SetTexture(base .. 'UI-QuestLogDualPane-Left')
        left:SetTexCoord(0, 0, 0, 0.86914002895355, 1, 0, 1, 0.86914002895355)
        left:SetPoint('TOPLEFT', frame, 'TOPLEFT', 0, 0)

        local right = frame:CreateTexture('DragonflightUIQuestLogDualPane-Right')
        right:SetSize(170, 445)
        right:SetTexture(base .. 'ui-questlogdualpane-right')
        right:SetTexCoord(0, 0, 0, 0.86914002895355, 0.6640625, 0, 0.6640625, 0.86914002895355)
        right:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', 0, 0)
    end

    frame:SetSize(682, 447)

    DragonflightUIMixin:AddNineSliceTextures(frame, true)
    DragonflightUIMixin:ButtonFrameTemplateNoPortrait(frame)
    DragonflightUIMixin:FrameBackgroundSolid(frame, true)

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

    QuestLogTitleText:ClearAllPoints()
    QuestLogTitleText:SetPoint('TOP', QuestLogFrame, 'TOP', 0, -5)
    QuestLogTitleText:SetPoint('LEFT', QuestLogFrame, 'LEFT', 60, 0)
    QuestLogTitleText:SetPoint('RIGHT', QuestLogFrame, 'RIGHT', -60, 0)

    local closeButton = QuestLogFrameCloseButton
    DragonflightUIMixin:UIPanelCloseButton(closeButton)
    closeButton:ClearAllPoints()
    closeButton:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', 1, 0)

    local exit = QuestFrameExitButton
    if exit then
        exit:ClearAllPoints()
        exit:SetSize(80, 22)
        exit:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', -7, 14)
        exit:SetText(CLOSE)
    end

    QuestLogDetailScrollFrame:ClearAllPoints()
    QuestLogDetailScrollFrame:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -32, -77)
    QuestLogDetailScrollFrame:SetSize(298, 333)

    QuestLogDetailScrollFrameScrollBar:SetPoint('TOPLEFT', QuestLogDetailScrollFrame, 'TOPRIGHT', 6, -13)

    QuestLogListScrollFrame:ClearAllPoints()
    QuestLogListScrollFrame:SetPoint('TOPLEFT', frame, 'TOPLEFT', 19, -75)
    QuestLogListScrollFrame:SetSize(305, 335)

    QuestLogListScrollFrameScrollBar:SetPoint('TOPLEFT', QuestLogListScrollFrame, 'TOPRIGHT', 2, -14.5)
    QuestLogListScrollFrameScrollBar:SetPoint('BOTTOMLEFT', QuestLogListScrollFrame, 'BOTTOMRIGHT', 2, 15.25)

    local QUESTS_DISPLAYED_old = QUESTS_DISPLAYED or 6
    QUESTS_DISPLAYED = 22
    for i = QUESTS_DISPLAYED_old + 1, QUESTS_DISPLAYED do
        local btn = CreateFrame('BUTTON', 'QuestLogTitle' .. i, frame, 'QuestLogTitleButtonTemplate')
        btn:ClearAllPoints()
        btn:SetPoint('TOPLEFT', _G['QuestLogTitle' .. (i - 1)], 'BOTTOMLEFT', 0, 1)
        btn:SetID(i)
        btn:Hide()
    end

    local panel = CreateFrame('FRAME', 'DragonflightUIQuestLogControlPanel', frame)
    panel:SetPoint('BOTTOMLEFT', frame, 'BOTTOMLEFT', 18, 11)
    panel:SetSize(307, 26)

    QuestLogFrameAbandonButton:ClearAllPoints()
    QuestLogFrameAbandonButton:SetPoint('LEFT', panel, 'LEFT', 0, 1)
    QuestLogFrameAbandonButton:SetSize(110, 21)
    QuestLogFrameAbandonButton:SetText(ABANDON_QUEST_ABBREV)

    local track = CreateFrame('BUTTON', 'DragonflightUIQuestLogFrameTrackButton', frame, 'UIPanelButtonTemplate')
    track:SetPoint('RIGHT', panel, 'RIGHT', -3, 1)
    track:SetSize(100, 21)
    track:SetText(TRACK_QUEST_ABBREV)
    track:SetEnabled(true)
    track:SetScript('OnEnter', function(self)
        GameTooltip_AddNewbieTip(self, TRACK_QUEST, 1.0, 1.0, 1.0, NEWBIE_TOOLTIP_TRACKQUEST, 1);
    end)
    track:SetScript('OnLeave', function(self)
        GameTooltip:Hide()
    end)
    local DF_QuestLogTitleButton_OnClick = function(self)
        local questIndex = GetQuestLogSelection()
        if (IsQuestWatched(questIndex)) then
            local questID = GetQuestIDFromLogIndex(questIndex);
            for index, value in ipairs(QUEST_WATCH_LIST) do
                if (value.id == questID) then tremove(QUEST_WATCH_LIST, index); end
            end
            RemoveQuestWatch(questIndex);
            QuestWatch_Update();
        else
            if (GetNumQuestLeaderBoards(questIndex) == 0) then
                UIErrorsFrame:AddMessage(QUEST_WATCH_NO_OBJECTIVES, 1.0, 0.1, 0.1, 1.0);
                return;
            end
            if (GetNumQuestWatches() >= MAX_WATCHABLE_QUESTS) then
                UIErrorsFrame:AddMessage(format(QUEST_WATCH_TOO_MANY, MAX_WATCHABLE_QUESTS), 1.0, 0.1, 0.1, 1.0);
                return;
            end
            AutoQuestWatch_Insert(questIndex, QUEST_WATCH_NO_EXPIRE);
            QuestWatch_Update();
        end
        QuestLog_SetSelection(questIndex)
        QuestLog_Update();
    end
    track:SetScript('OnClick', function(self)
        DF_QuestLogTitleButton_OnClick()
    end)

    QuestFramePushQuestButton:ClearAllPoints()
    QuestFramePushQuestButton:SetPoint('LEFT', QuestLogFrameAbandonButton, 'RIGHT', 0, 0)
    QuestFramePushQuestButton:SetPoint('RIGHT', track, 'LEFT', 0, 0)
    QuestFramePushQuestButton:SetWidth(1)
    QuestFramePushQuestButton:SetText(SHARE_QUEST_ABBREV)

    if QuestLogTrack then QuestLogTrack:Hide() end

    do
        EmptyQuestLogFrame:ClearAllPoints()
        EmptyQuestLogFrame:SetPoint('TOPLEFT', frame, 'TOPLEFT', 19, -73)
        EmptyQuestLogFrame:SetSize(302, 356)

        hooksecurefunc(EmptyQuestLogFrame, "Show", function()
            EmptyQuestLogFrame:ClearAllPoints()
            EmptyQuestLogFrame:SetPoint('TOPLEFT', frame, 'TOPLEFT', 19, -73)
            EmptyQuestLogFrame:SetSize(302, 356)
        end)

        QuestLogNoQuestsText:ClearAllPoints()
        QuestLogNoQuestsText:SetPoint('CENTER', EmptyQuestLogFrame, 'CENTER', -6, 16)

        local regionsE = {EmptyQuestLogFrame:GetRegions()}
        for k, child in ipairs(regionsE) do
            if child:GetObjectType() == 'Texture' then child:Hide() end
        end

        local tl = EmptyQuestLogFrame:CreateTexture(nil, 'BACKGROUND')
        tl:SetSize(256, 256)
        tl:SetPoint('TOPLEFT', EmptyQuestLogFrame, 'TOPLEFT', 0, 0)
        tl:SetTexture(base .. 'UI-QuestLog-Empty-TopLeft')
        tl:SetTexCoord(0, 1.0, 0, 1.0)

        local bl = EmptyQuestLogFrame:CreateTexture(nil, 'BACKGROUND')
        bl:SetSize(256, 106)
        bl:SetPoint('TOPRIGHT', tl, 'BOTTOMRIGHT', 0, 0)
        bl:SetPoint('BOTTOMLEFT', EmptyQuestLogFrame, 'BOTTOMLEFT', 0, 0)
        bl:SetTexture(base .. 'UI-QuestLog-Empty-BotLeft')
        bl:SetTexCoord(0, 1.0, 0, 0.828125)

        local tr = EmptyQuestLogFrame:CreateTexture(nil, 'BACKGROUND')
        tr:SetSize(46, 256)
        tr:SetPoint('TOPRIGHT', EmptyQuestLogFrame, 'TOPRIGHT', 0, 0)
        tr:SetPoint('BOTTOMLEFT', tl, 'BOTTOMRIGHT', 0, 0)
        tr:SetTexture(base .. 'UI-QuestLog-Empty-TopRight')
        tr:SetTexCoord(0, 0.71875, 0, 1.0)

        local br = EmptyQuestLogFrame:CreateTexture(nil, 'BACKGROUND')
        br:SetSize(46, 256)
        br:SetPoint('BOTTOMRIGHT', EmptyQuestLogFrame, 'BOTTOMRIGHT', 0, 0)
        br:SetPoint('TOPLEFT', tl, 'BOTTOMRIGHT', 0, 0)
        br:SetTexture(base .. 'UI-QuestLog-Empty-BotRight')
        br:SetTexCoord(0, 0.71875, 0, 0.828125)
    end

    do
        local count = CreateFrame('FRAME', 'DragonflightUIQuestLogCount', frame, 'DFQuestLogCount')
        count:SetSize(82.8, 20)
        count:SetPoint("TOPLEFT", frame, "TOPLEFT", 80, -41);

        local hPadding = 15;
        local width = QuestLogQuestCount:GetWidth();
        count:SetWidth(width + hPadding);

        QuestLogQuestCount:ClearAllPoints()
        QuestLogQuestCount:SetParent(count)
        QuestLogQuestCount:SetPoint('TOPRIGHT', _G['DragonflightUIQuestLogCountTopRight'], 'BOTTOMLEFT', 1, 3)
        if DF.API.Version.IsTBC then
            hooksecurefunc('QuestLogUpdateQuestCount', function()
                if QuestLogCount then QuestLogCount:Hide() end
            end)
        end
    end

    do
        local count = CreateFrame('FRAME', 'DragonflightUIQuestCompletedQuestsFrame', frame, 'DFQuestLogCount')
        count:SetSize(180, 20)
        count:SetPoint("LEFT", _G['DragonflightUIQuestLogCount'], "RIGHT", 6, 0);

        local textOne = count:CreateFontString('DragonflightUICompletedQuests', 'OVERLAY', 'GameFontNormalSmall')
        textOne:SetPoint('TOPLEFT', _G['DragonflightUIQuestCompletedQuestsFrameTopLeft'], 'BOTTOMRIGHT', 1, 3)

        frame.DFCompletedQuestsFrame = count;

        count.Update = function()
            local questXPInfo = DragonflightUIMixin:GetCompletedQuestsAndXP();

            local first = 'Completed: ' .. '|cffffffff' .. tostring(questXPInfo.numCompletedQuests) .. '/' ..
                              tostring(questXPInfo.numQuests) .. '|r';
            local second = 'XP: ' .. '|cffffffff' .. FormatLargeNumber(tostring(questXPInfo.numQuestXP)) .. '|r'
            textOne:SetText(first .. '   ' .. second);

            local hPadding = 15;
            local width = textOne:GetWidth();
            count:SetWidth(width + hPadding);
        end

        count.Update()
    end

    QuestLogExpandButtonFrame:ClearAllPoints()
    QuestLogExpandButtonFrame:SetPoint('TOPLEFT', frame, 'TOPLEFT', 70 - 47, -48)

    do
        local map = CreateFrame('BUTTON', 'DragonflightUIQuestLogFrameShowMapButton', frame)
        map:SetScript('OnClick', ToggleWorldMap)
        map:SetSize(48, 32)
        map:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', -25, -38)

        map:SetNormalTexture('Interface\\QuestFrame\\UI-QuestMap_Button')
        map:GetNormalTexture():SetTexCoord(0.125, 0.875, 0, 0.5)
        map:SetPushedTexture('Interface\\QuestFrame\\UI-QuestMap_Button')
        map:GetPushedTexture():SetTexCoord(0.125, 0.875, 0.5, 1.0)
        map:SetHighlightTexture('Interface\\Buttons\\ButtonHilight-Square')
        local high = map:GetHighlightTexture()
        high:SetSize(38, 25)
        high:ClearAllPoints()
        high:SetPoint('RIGHT', -7, 0)

        local text = map:CreateFontString('DragonflightUIQuestLogFrameShowMapButtonText', 'ARTWORK', 'GameFontNormal')
        text:SetText(SHOW_MAP)
        text:SetPoint('RIGHT', map, 'LEFT', 0, 0)
    end

    UIPanelWindows["QuestLogFrame"] = {
        area = "doublewide",
        pushable = 0,
        xoffset = 0,
        yoffset = 0,
        bottomClampOverride = 140 + 12,
        whileDead = 1,
        width = frame:GetWidth(),
        height = frame:GetHeight()
    };
end

function DragonflightUIMixin:ChangeQuestLogFrameCata()
    local frame = QuestLogFrame

    local regions = {frame:GetRegions()}
    local port

    for k, child in ipairs(regions) do
        if child:GetObjectType() == 'Texture' then
            local tex = child:GetTexture()
            if tex == 136797 then
                port = child
            elseif tex == 309665 then
                child:SetTexture(base .. 'UI-QuestLogDualPane-Left')
            elseif tex == 309666 then
                child:SetTexture(base .. 'ui-questlogdualpane-right')
            end
        end
    end

    if DF.API.Version.IsMoP then
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

        local br = _G['EmptyQuestLogFrameBackgroundBottomRight']
        if br and _G['EmptyQuestLogFrameBackgroundTopLeft'] then
            br:ClearAllPoints()
            br:SetPoint('TOPLEFT', _G['EmptyQuestLogFrameBackgroundTopLeft'], 'BOTTOMRIGHT', 0, 0)
        end
    end
    DragonflightUIMixin:AddNineSliceTextures(frame, true)
    DragonflightUIMixin:ButtonFrameTemplateNoPortrait(frame)

    QuestLogTitleText:ClearAllPoints()
    QuestLogTitleText:SetPoint('TOP', QuestLogFrame, 'TOP', 0, -5)
    QuestLogTitleText:SetPoint('LEFT', QuestLogFrame, 'LEFT', 60, 0)
    QuestLogTitleText:SetPoint('RIGHT', QuestLogFrame, 'RIGHT', -60, 0)
    DragonflightUIMixin:UIPanelCloseButton(QuestLogFrameCloseButton)
    QuestLogFrameCloseButton:SetPoint('TOPRIGHT', QuestLogFrame, 'TOPRIGHT', 1, 0)

    if port then
        port:SetSize(62, 62)
        port:ClearAllPoints()
        port:SetPoint('TOPLEFT', -5, 7)
        port:SetDrawLayer('OVERLAY', 6)

        local pp = frame.PortraitFrame
        if pp then
            pp:SetTexture(base .. 'UI-Frame-PortraitMetal-CornerTopLeft')
            pp:SetTexCoord(0.0078125, 0.0078125, 0.0078125, 0.6171875, 0.6171875, 0.0078125, 0.6171875, 0.6171875)
            pp:SetSize(84, 84)
            pp:ClearAllPoints()
            pp:SetPoint('CENTER', port, 'CENTER', 0, 0)
            pp:SetDrawLayer('OVERLAY', 7)
        end
    end

    if DF.API.Version.IsMoP then
        DragonflightUIMixin:FrameBackgroundSolidMoP(frame, true)
    else
        DragonflightUIMixin:FrameBackgroundSolid(frame, true)
    end

    do
        local count = CreateFrame('FRAME', 'DragonflightUIQuestCompletedQuestsFrame', frame, 'DFQuestLogCount')
        count:SetSize(180, 20)
        if QuestLogCount then count:SetPoint("LEFT", QuestLogCount, "RIGHT", 6, 0) end

        local textOne = count:CreateFontString('DragonflightUICompletedQuests', 'OVERLAY', 'GameFontNormalSmall')
        textOne:SetPoint('TOPLEFT', _G['DragonflightUIQuestCompletedQuestsFrameTopLeft'], 'BOTTOMRIGHT', 1, 3)

        frame.DFCompletedQuestsFrame = count;

        count.Update = function()
            local questXPInfo = DragonflightUIMixin:GetCompletedQuestsAndXP();

            local first = 'Completed: ' .. '|cffffffff' .. tostring(questXPInfo.numCompletedQuests) .. '/' ..
                              tostring(questXPInfo.numQuests) .. '|r';
            local second = 'XP: ' .. '|cffffffff' .. FormatLargeNumber(tostring(questXPInfo.numQuestXP)) .. '|r'
            textOne:SetText(first .. '   ' .. second);

            local hPadding = 15;
            local width = textOne:GetWidth();
            count:SetWidth(width + hPadding);
        end

        count.Update()

        hooksecurefunc('QuestLog_Update', function()
            count.Update()
        end)

        if _G['QuestLogCount'] then _G['QuestLogCount']:SetSize(82.8, 20) end
    end

    ShowUIPanel(frame)
    QuestLogFrame:SetAttribute("UIPanelLayout-" .. "xoffset", 0);
    QuestLogFrame:SetAttribute("UIPanelLayout-" .. "yoffset", 0);
    HideUIPanel(frame)
end

function DragonflightUIMixin:AddQuestLevel()
    local questInfo = function(id)
        local title, level, suggestedGroup, isHeader = GetQuestLogTitle(id)
        if not title or not level then return nil, nil, nil, nil, nil end

        local suffix = ''
        if suggestedGroup then
            if suggestedGroup == GROUP or suggestedGroup == ELITE then
                suffix = '+'
            elseif suggestedGroup == LFG_TYPE_DUNGEON then
                suffix = 'D'
            elseif suggestedGroup == RAID then
                suffix = 'R'
            elseif suggestedGroup == PVP then
                suffix = 'P'
            end
        end

        return title, level, suggestedGroup, isHeader, suffix
    end

    hooksecurefunc('QuestLog_UpdateQuestDetails', function()
        local id = GetQuestLogSelection()
        if not id then return end

        local title, level, suggestedGroup, isHeader, suffix = questInfo(id)
        if not title or not level then return end

        local questLogTitle = QuestLogQuestTitle or QuestInfoTitleHeader
        if questLogTitle then
            questLogTitle:SetText('[' .. level .. suffix .. '] ' .. title)
        end
    end)

    if DF.API.Version.IsMoP then
        hooksecurefunc('QuestLogTitleButton_Resize', function(questLogTitle)
            local questNormalText = questLogTitle.normalText;
            local questIndex = questLogTitle:GetID()

            local title, level, suggestedGroup, isHeader, suffix = questInfo(questIndex)

            if title and level and not isHeader then
                local padding = (level > 0 and level < 10) and '0' or ''
                local questLogText = ' [' .. padding .. level .. suffix .. '] ' .. title

                local normal = questLogTitle.normalText
                normal:SetText(questLogText)
            end

            questNormalText:SetWidth(0);
            questLogTitle:SetText(questLogTitle:GetText());

            local questTitleTag = questLogTitle.tag;
            local questCheck = questLogTitle.check;

            local rightEdge;
            if (questTitleTag and questTitleTag:IsShown()) then
                if (questCheck and questCheck:IsShown()) then
                    rightEdge = questLogTitle:GetLeft() + questLogTitle:GetWidth() - questTitleTag:GetWidth() - 4 -
                                    questCheck:GetWidth() - 2;
                else
                    rightEdge = questLogTitle:GetLeft() + questLogTitle:GetWidth() - questTitleTag:GetWidth() - 4;
                end
            else
                if (questCheck and questCheck:IsShown()) then
                    rightEdge = questLogTitle:GetLeft() + questLogTitle:GetWidth() - questCheck:GetWidth() - 2;
                else
                    rightEdge = questLogTitle:GetLeft() + questLogTitle:GetWidth();
                end
            end
            local questNormalTextWidth = questNormalText:GetWidth() - max(questNormalText:GetRight() - (rightEdge or 0), 0);
            questNormalText:SetWidth(questNormalTextWidth);
        end)
    elseif DF.Cata then
        hooksecurefunc('QuestLogTitleButton_Resize', function(btn)
            local questIndex = btn:GetID()
            local title, level, suggestedGroup, isHeader, suffix = questInfo(questIndex)

            if title and level and not isHeader then
                local padding = (level > 0 and level < 10) and '0' or ''
                local questLogText = ' [' .. padding .. level .. suffix .. '] ' .. title

                local normal = btn.normalText
                if normal then normal:SetText(questLogText) end
            end
        end)
    elseif DF.Era then
        hooksecurefunc('QuestLog_Update', function()
            local numEntries, numQuests = GetNumQuestLogEntries();
            if numEntries == 0 then return end

            local offset = FauxScrollFrame_GetOffset(QuestLogListScrollFrame)

            for i = 1, QUESTS_DISPLAYED do
                local questIndex = i + offset

                if questIndex <= numEntries then
                    local logTitle = _G['QuestLogTitle' .. i]
                    local title, level, suggestedGroup, isHeader, suffix = questInfo(questIndex)

                    if title and level and not isHeader and logTitle then
                        local padding = (level > 0 and level < 10) and '0' or ''
                        local questLogText = ' [' .. padding .. level .. suffix .. '] ' .. title
                        logTitle:SetText(questLogText)
                        if QuestLogDummyText then QuestLogDummyText:SetText(questLogText) end

                        local normal = _G['QuestLogTitle' .. i .. 'NormalText']
                        local check = _G['QuestLogTitle' .. i .. 'Check']

                        if normal and check then
                            local textW = normal:GetWrappedWidth()
                            local dx = textW + 2
                            check:ClearAllPoints()
                            check:SetPoint('LEFT', normal, 'LEFT', dx, 0)
                        end
                    end
                end
            end
        end)
    end
end
