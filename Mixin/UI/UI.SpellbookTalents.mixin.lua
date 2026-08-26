local addonName, addonTable = ...;
local Helper = addonTable.Helper;
---@diagnostic disable: undefined-global
---@class DragonflightUI
---@diagnostic disable-next-line: assign-type-mismatch
local DF = LibStub('AceAddon-3.0'):GetAddon('DragonflightUI')

DragonflightUIMixin = DragonflightUIMixin or {}

local base = 'Interface\\Addons\\DragonflightUI\\Textures\\UI\\'

function DragonflightUIMixin:ChangeTalentsEra()
    local frame = PlayerTalentFrame
    if not frame then return end

    local regions = {frame:GetRegions()}

    for k, child in ipairs(regions) do
        if child:GetObjectType() == 'Texture' then
            local layer, layerNr = child:GetDrawLayer()
            if layer == 'BORDER' then child:Hide() end
            if layer == 'BACKGROUND' then child:Hide() end
        end
    end

    frame:SetSize(646, 468)

    if DF.API.Version.IsTBC then frame:SetHeight(468 + 90) end

    DragonflightUIMixin:AddNineSliceTextures(frame, true)
    DragonflightUIMixin:ButtonFrameTemplateNoPortrait(frame)
    DragonflightUIMixin:FrameBackgroundSolid(frame, true)

    local closeButton = PlayerTalentFrameCloseButton
    if closeButton then
        DragonflightUIMixin:UIPanelCloseButton(closeButton)
        closeButton:ClearAllPoints()
        closeButton:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', 1, 0)
    end

    local blizzClose = _G['PlayerTalentFrameCancelButton']
    if blizzClose then
        blizzClose:ClearAllPoints()
        blizzClose:Hide()
    end

    if PlayerTalentFrameTitleText then
        PlayerTalentFrameTitleText:ClearAllPoints()
        PlayerTalentFrameTitleText:SetPoint('TOP', frame, 'TOP', 0, -5)
        PlayerTalentFrameTitleText:SetPoint('LEFT', frame, 'LEFT', 60, 0)
        PlayerTalentFrameTitleText:SetPoint('RIGHT', frame, 'RIGHT', -60, 0)
    end

    do
        local port = frame:CreateTexture('DragonflightUIPlayerTalentFramePortrait')
        port:SetSize(62, 62)
        port:ClearAllPoints()
        port:SetPoint('TOPLEFT', frame, 'TOPLEFT', -5, 7)
        port:SetParent(frame)
        port:SetTexture('Interface\\Icons\\Ability_Marksmanship')
        SetPortraitToTexture(port, port:GetTexture())
        port:SetDrawLayer('OVERLAY', 6)
        port:Show()

        frame.PortraitFrame = frame:CreateTexture('DragonflightUIPlayerTalentFramePortraitFrame')
        local pp = frame.PortraitFrame
        pp:SetTexture(base .. 'UI-Frame-PortraitMetal-CornerTopLeft')
        pp:SetTexCoord(0.0078125, 0.0078125, 0.0078125, 0.6171875, 0.6171875, 0.0078125, 0.6171875, 0.6171875)
        pp:SetSize(84, 84)
        pp:ClearAllPoints()
        pp:SetPoint('CENTER', port, 'CENTER', 0, 0)
        pp:SetDrawLayer('OVERLAY', 7)
    end

    local scroll = PlayerTalentFrameScrollFrame
    if scroll then
        scroll:ClearAllPoints()
        scroll:Hide()
    end

    local bar = PlayerTalentFramePointsBar
    if bar then
        bar:ClearAllPoints()
        bar:Hide()
    end

    for i = 1, 3 do
        local tab = _G['PlayerTalentFrameTab' .. i]
        if tab then
            tab:ClearAllPoints()
            tab:Hide()
        end
    end

    local inset = CreateFrame('FRAME', 'DragonflightUIPlayerTalentFrameInset', frame, 'InsetFrameTemplate')
    inset:SetPoint('TOPLEFT', frame, 'TOPLEFT', 4, -60)
    inset:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', -6, 26)
    inset:SetFrameLevel(1)
    frame.DFInset = inset

    local DFFrame = CreateFrame('FRAME', 'DragonflightUIPlayerTalentFrame', frame, 'DFPlayerTalentFrameTemplate')
    DFFrame:SetSize(32, 32)
    DFFrame:SetPoint('TOPLEFT', frame, 'TOPLEFT', 0, 0)

    frame:HookScript('OnShow', function()
        frame:SetAttribute("UIPanelLayout-width", frame:GetWidth());
        frame:SetAttribute("UIPanelLayout-" .. "xoffset", 0);
        frame:SetAttribute("UIPanelLayout-" .. "yoffset", 0);
        UpdateUIPanelPositions(frame)
    end)
end

function DragonflightUIMixin:ChangeTalents()
    if DragonflightUITalentsMoPMixin and DragonflightUITalentsMoPMixin.SkinMoPTalentFrame then
        DragonflightUITalentsMoPMixin:SkinMoPTalentFrame(PlayerTalentFrame)
    end
end

function DragonflightUIMixin:ChangeSpellbookEra()
    local frame = SpellBookFrame
    if not frame then return end

    local regions = {frame:GetRegions()}
    local port

    for k, child in ipairs(regions) do
        if child:GetObjectType() == 'Texture' then
            local layer, layerNr = child:GetDrawLayer()
            if layer == 'ARTWORK' then child:Hide() end
            if layer == 'BACKGROUND' then
                if child:GetTexture() == 136830 then
                    port = child
                end
            end
        end
    end

    frame:SetSize(550, 525)

    DragonflightUIMixin:AddNineSliceTextures(frame, true)
    DragonflightUIMixin:ButtonFrameTemplateNoPortrait(frame)
    DragonflightUIMixin:FrameBackgroundSolid(frame, true)

    local closeButton = SpellBookCloseButton
    if closeButton then
        DragonflightUIMixin:UIPanelCloseButton(closeButton)
        closeButton:ClearAllPoints()
        closeButton:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', 1, 0)
    end

    if SpellBookTitleText then
        SpellBookTitleText:ClearAllPoints()
        SpellBookTitleText:SetPoint('TOP', frame, 'TOP', 0, -5)
        SpellBookTitleText:SetPoint('LEFT', frame, 'LEFT', 60, 0)
        SpellBookTitleText:SetPoint('RIGHT', frame, 'RIGHT', -60, 0)
    end

    if port then
        port:SetSize(62, 62)
        port:ClearAllPoints()
        port:SetPoint('TOPLEFT', frame, 'TOPLEFT', -5, 7)
        port:SetDrawLayer('OVERLAY', 6)
        port:SetParent(frame)
        port:Show()

        SetPortraitToTexture(port, port:GetTexture())

        frame.PortraitFrame = frame:CreateTexture('PortraitFrame')
        local pp = frame.PortraitFrame
        pp:SetTexture(base .. 'UI-Frame-PortraitMetal-CornerTopLeft')
        pp:SetTexCoord(0.0078125, 0.0078125, 0.0078125, 0.6171875, 0.6171875, 0.0078125, 0.6171875, 0.6171875)
        pp:SetSize(84, 84)
        pp:ClearAllPoints()
        pp:SetPoint('CENTER', port, 'CENTER', 0, 0)
        pp:SetDrawLayer('OVERLAY', 7)
    end

    if SpellBookSkillLineTab1 then
        SpellBookSkillLineTab1:SetPoint('TOPLEFT', SpellBookSideTabsFrame, 'TOPRIGHT', 0, -36)
    end

    if SpellBookNextPageButton then
        SpellBookNextPageButton:ClearAllPoints()
        SpellBookNextPageButton:SetPoint('BOTTOMRIGHT', SpellBookPageNavigationFrame, 'BOTTOMRIGHT', -31, 26)
    end

    if SpellBookPrevPageButton then
        SpellBookPrevPageButton:ClearAllPoints()
        SpellBookPrevPageButton:SetPoint('BOTTOMRIGHT', SpellBookPageNavigationFrame, 'BOTTOMRIGHT', -66, 26)
    end

    if SpellBookPageText then
        SpellBookPageText:ClearAllPoints()
        SpellBookPageText:SetPoint('BOTTOMRIGHT', SpellBookPageNavigationFrame, 'BOTTOMRIGHT', -110, 38)
    end

    do
        local inset = CreateFrame('FRAME', 'DragonflightUISpellBookInset', frame, 'InsetFrameTemplate')
        inset:SetPoint('TOPLEFT', frame, 'TOPLEFT', 4, -24)
        inset:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', -6, 4)
        inset:SetFrameLevel(1)

        local first = frame:CreateTexture('DragonflightUISpellBookPage1', 'BACKGROUND')
        first:SetTexture(base .. 'Spellbook-Page-1')
        first:SetPoint('TOPLEFT', frame, 'TOPLEFT', 7, -25)

        local second = frame:CreateTexture('DragonflightUISpellBookPage2', 'BACKGROUND')
        second:SetTexture(base .. 'Spellbook-Page-2')
        second:SetPoint('TOPLEFT', first, 'TOPRIGHT', 0, 0)

        local bg = frame:CreateTexture('DragonflightUISpellBookBG', 'BACKGROUND')
        bg:SetTexture(base .. 'UI-Background-RockCata')
        bg:SetPoint('TOPLEFT', frame, 'TOPLEFT', 2, -21)
        bg:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', -2, 2)
        bg:SetDrawLayer('BACKGROUND', -6)
    end

    do
        for i = 1, 12 do
            local btn = _G['SpellButton' .. i]
            if btn then
                btn:ClearAllPoints()

                local modulo = i - math.floor(i / 2) * 2

                if i == 1 then
                    btn:SetPoint('TOPLEFT', SpellBookSpellIconsFrame, 'TOPLEFT', 100, -72)
                elseif modulo == 0 then
                    btn:SetPoint('TOPLEFT', _G['SpellButton' .. (i - 1)], 'TOPLEFT', 225, 0)
                elseif modulo == 1 then
                    btn:SetPoint('TOPLEFT', _G['SpellButton' .. (i - 2)], 'BOTTOMLEFT', 0, -29)
                end

                local first = btn:CreateTexture(nil, 'BACKGROUND')
                first:SetTexture(base .. 'Spellbook-Parts')
                first:SetPoint('TOPLEFT', _G['SpellButton' .. i .. 'Highlight'], 'TOPRIGHT', -4, 0 - 1)
                first:SetSize(167, 39)
                first:SetTexCoord(0.31250000, 0.96484375, 0.37109375, 0.52343750)

                local spellName = _G['SpellButton' .. i .. 'SpellName']
                if spellName then spellName:SetDrawLayer('ARTWORK', 6) end

                local bg = _G['SpellButton' .. i .. 'Background']
                if bg then
                    bg:ClearAllPoints()
                    bg:SetSize(43, 43)
                    bg:SetTexture(base .. 'Spellbook-Parts')
                    bg:SetTexCoord(0.79296875, 0.96093750, 0.00390625, 0.17187500)
                    bg:SetPoint('CENTER', btn, 'CENTER', 0, 0)
                end

                local slotframe = btn:CreateTexture('DragonflightUISpellbookSlotFrame', 'OVERLAY')
                slotframe:SetDrawLayer('OVERLAY', -1)
                slotframe:SetTexture(base .. 'Spellbook-Parts')
                slotframe:SetTexCoord(0.00390625, 0.27734375, 0.44140625, 0.69531250)
                slotframe:SetSize(70, 65)
                slotframe:SetPoint('CENTER', btn, 'CENTER', 1.5, 0)
                btn.DFSlotFrame = slotframe

                btn.ShowSlotFrame = function(show)
                    if show then
                        btn.DFSlotFrame:Show()
                    else
                        btn.DFSlotFrame:Hide()
                    end
                end
            end
        end

        do
            for i = 1, 8 do
                local skill = _G['SpellBookSkillLineTab' .. i]
                if skill then
                    local children = {skill:GetRegions()}
                    for k, child in ipairs(children) do
                        if child:GetObjectType() == 'Texture' then
                            local tex = child:GetTexture()
                            if tex == 136831 then
                                child:SetTexture(base .. 'spellbook-skilllinetab')
                            end
                        end
                    end
                end
            end
        end

        if SpellButton_UpdateButton then
            hooksecurefunc('SpellButton_UpdateButton', function(self)
                local name = self:GetName()
                local spellname = _G[name .. 'SpellName']
                if spellname then
                    spellname:ClearAllPoints()
                    spellname:SetPoint('LEFT', self, 'RIGHT', 8, 4)
                    spellname:SetTextColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b)
                end

                local icon = _G[name .. 'IconTexture']
                if self.ShowSlotFrame then
                    if self.isPassive then
                        self.ShowSlotFrame(false)
                    else
                        self.ShowSlotFrame(icon and icon:IsVisible())
                    end
                end
            end)
        end
    end

    local checkbox = ShowAllSpellRanksCheckBox or ShowAllSpellRanksCheckbox
    if checkbox and _G['SpellButton1'] then
        checkbox:ClearAllPoints()
        checkbox:SetPoint('BOTTOMLEFT', _G['SpellButton1'], 'TOPLEFT', -4, 8)
    end

    for i = 1, 5 do
        local tab = _G['SpellBookFrameTabButton' .. i]
        if tab and i == 1 then
            tab:ClearAllPoints()
            tab:SetPoint('TOPLEFT', frame, 'BOTTOMLEFT', 12, 19)
        end
    end

    UIPanelWindows["SpellBookFrame"] = {
        whileDead = 1,
        height = 424,
        width = SpellBookFrame:GetWidth() + 32,
        bottomClampOverride = 152,
        xoffset = 0,
        yoffset = 0,
        pushable = 3,
        area = "left"
    }
    UpdateUIPanelPositions(SpellBookFrame)
end

function DragonflightUIMixin:SpellbookEraAddTabs()
    local frame = SpellBookFrame
    if not frame then return end

    for i = 1, 5 do
        local tab = _G['SpellBookFrameTabButton' .. i]
        if tab then
            tab:ClearAllPoints()
            tab:Hide()
        end
    end

    local tabFrame = CreateFrame('FRAME', 'DragonflightUISpellbookFrameTabFrame', SpellBookFrame, 'SecureFrameTemplate')
    function tabFrame:OnEvent(event, arg1)
        if event == 'PLAYER_REGEN_ENABLED' then
            if self.ShouldUpdate then self:UpdateTabs() end
        end
    end
    tabFrame:SetScript('OnEvent', tabFrame.OnEvent)
    tabFrame:RegisterEvent('PLAYER_REGEN_ENABLED')

    SpellBookFrame.DFTabFrame = tabFrame
    local numTabs = 3
    tabFrame.numTabs = numTabs
    tabFrame.Tabs = {}

    for i = 1, 3 do
        local tab = CreateFrame('BUTTON', 'DragonflightUISpellBookFrameTabButton' .. i, tabFrame,
                                'DFCharacterFrameTabButtonTemplate', i)
        ---@diagnostic disable-next-line: param-type-mismatch
        tab:SetParent(tabFrame)
        local text = _G[tab:GetName() .. 'Text']
        tinsert(tabFrame.Tabs, i, tab)

        DragonflightUIMixin:CharacterFrameTabButtonTemplate(tab, true, true)

        tab:SetAttribute('type', 'macro')
        tab:RegisterForClicks('LeftButtonUp', 'LeftButtonDown')

        tab:SetScript('PostClick', function(self, button, down)
            DragonflightUICharacterTabMixin:Tab_OnClick(self, tabFrame)
        end)

        if i == 1 then
            tab:ClearAllPoints()
            tab:SetPoint('TOPLEFT', frame, 'BOTTOMLEFT', 12, 1)
            text:SetText(SPELLBOOK)
            tab:SetScript('OnEnter', function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
                GameTooltip:SetText(MicroButtonTooltipText(tab:GetText(), 'TOGGLESPELLBOOK'), 1.0, 1.0, 1.0);
            end)
        elseif i == 2 then
            tab.DFChangePoint = true
            tab:SetPoint('LEFT', _G['DragonflightUISpellBookFrameTabButton' .. (i - 1)], 'RIGHT', 0, 0)
            text:SetText(TRADE_SKILLS)
            tab:SetScript('OnEnter', function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
                GameTooltip:SetText(MicroButtonTooltipText(tab:GetText(),
                                                           'CLICK DragonflightUISpellbookProfessionFrameToggleButton:Keybind'),
                                    1.0, 1.0, 1.0);
            end)
        elseif i == 3 then
            tab.DFChangePoint = true
            tab:SetPoint('LEFT', _G['DragonflightUISpellBookFrameTabButton' .. (i - 1)], 'RIGHT', 0, 0)
            text:SetText(PET)
            tab:SetScript('OnEnter', function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
                GameTooltip:SetText(MicroButtonTooltipText(tab:GetText(), SpellBookFrameTabButton2 and SpellBookFrameTabButton2.binding or ''), 1.0, 1.0,
                                    1.0);
            end)
        end
        DragonflightUIMixin:TabResize(tab)
    end

    function tabFrame:UpdateTabs()
        if InCombatLockdown() then
            self.ShouldUpdate = true
            return
        end
        self.ShouldUpdate = false

        local hasPetSpells, petToken = HasPetSpells();
        local hasPetWithSpellsAndSpellbook = hasPetSpells and PetHasSpellbook()
        local numTabs = hasPetWithSpellsAndSpellbook and 3 or 2

        local tab1 = self.Tabs[1]
        local tab2 = self.Tabs[2]
        local tab3 = self.Tabs[3]

        if numTabs == 2 then
            tab3:Hide()
            tab1:SetAttribute('macrotext', "/click DragonflightUISpellbookProfessionFrameHideButton")
            tab2:SetAttribute('macrotext', "/click DragonflightUISpellbookProfessionFrameShowButton")

            if self.selectedTab == 3 then
                DragonflightUICharacterTabMixin:Tab_OnClick(tab1, self)
            end
        else
            tab3:Show()
            tab1:SetAttribute('macrotext',
                              "/click SpellBookFrameTabButton1\n/click DragonflightUISpellbookProfessionFrameHideButton")
            tab2:SetAttribute('macrotext', "/click DragonflightUISpellbookProfessionFrameShowButton")
            tab3:SetAttribute('macrotext',
                              "/click SpellBookFrameTabButton2\n/click DragonflightUISpellbookProfessionFrameHideButton")
        end
    end

    DragonflightUICharacterTabMixin:Tab_OnClick(_G['DragonflightUISpellBookFrameTabButton1'], tabFrame)
    tabFrame:UpdateTabs()

    if PetFrame then
        PetFrame:HookScript('OnShow', function()
            tabFrame:UpdateTabs()
            C_Timer.After(0, function()
                tabFrame:UpdateTabs()
            end)
        end)
        PetFrame:HookScript('OnHide', function()
            tabFrame:UpdateTabs()
            C_Timer.After(0, function()
                tabFrame:UpdateTabs()
            end)
        end)
    end
end

function DragonflightUIMixin:SpellbookEraProfessions()
    local frame = CreateFrame('FRAME', 'DragonflightUISpellBookProfessionFrame', SpellBookFrame,
                              'DFSpellBookProfessionFrame')
    frame:SetSize(550, 525)
    frame:SetPoint('TOPLEFT', SpellBookFrame, 'TOPLEFT', 0, 0)
    frame:SetFrameLevel(69)
    frame:Hide()
    SpellBookFrame.DFSpellBookProfessionFrame = frame

    frame.buttonShow = CreateFrame("Button", "DragonflightUISpellbookProfessionFrameShowButton", frame,
                                   "SecureHandlerClickTemplate");
    frame.buttonShow:SetAttribute("_onclick", [[      
        local frame = self:GetFrameRef("ProfessionFrame");
        frame:Show();    
        
        local handler = self:GetFrameRef("handler");
        handler:Run(handler:GetAttribute('UpdateToggleButtonMacro'), '')
    ]]);
    frame.buttonShow:SetFrameRef("ProfessionFrame", frame)

    ---@diagnostic disable-next-line: param-type-mismatch
    frame.buttonShow:SetAllPoints(frame);
    frame:SetAttribute("addchild", frame.buttonShow);

    frame.buttonHide = CreateFrame("Button", "DragonflightUISpellbookProfessionFrameHideButton", frame,
                                   "SecureHandlerClickTemplate");
    frame.buttonHide:SetAttribute("_onclick", [[      
        local frame = self:GetFrameRef("ProfessionFrame");
        frame:Hide();   

        local handler = self:GetFrameRef("handler");
        handler:Run(handler:GetAttribute('UpdateToggleButtonMacro'), '')
    ]]);
    frame.buttonHide:SetFrameRef("ProfessionFrame", frame)
    ---@diagnostic disable-next-line: param-type-mismatch
    frame.buttonHide:SetAllPoints(frame);
    frame:SetAttribute("addchild", frame.buttonHide);

    do
        local toggleButton = CreateFrame('BUTTON', 'DragonflightUISpellbookProfessionFrameToggleButton', UIParent,
                                         'SecureActionButtonTemplate')
        toggleButton:SetAttribute('type', 'macro')
        local macroTextDefault = "/click SpellbookMicroButton" .. "\n" ..
                                     "/click DragonflightUISpellbookProfessionFrameShowButton"
        local macroTextDefaultClose = "/click SpellbookMicroButton" .. "\n" ..
                                          "/click DragonflightUISpellbookProfessionFrameHideButton"
        local macroTextOpen = "/click DragonflightUISpellbookProfessionFrameShowButton"
        local macroTextClose = "/click DragonflightUISpellbookProfessionFrameHideButton"
        toggleButton:SetAttribute('macrotext', macroTextDefault)
        toggleButton:SetAttribute('macroTextDefault', macroTextDefault)
        toggleButton:SetAttribute('macroTextDefaultClose', macroTextDefaultClose)
        toggleButton:SetAttribute('macroTextOpen', macroTextOpen)
        toggleButton:SetAttribute('macroTextClose', macroTextClose)

        local tabFrame = SpellBookFrame.DFTabFrame
        toggleButton:SetScript('PostClick', function(self, button, down)
            if frame:IsVisible() then
                DragonflightUICharacterTabMixin:Tab_OnClick(tabFrame.Tabs[2], tabFrame)
            else
                DragonflightUICharacterTabMixin:Tab_OnClick(tabFrame.Tabs[1], tabFrame)
            end
        end)

        local handler = CreateFrame('Frame', 'DragonflightUISpellbookHandler', nil, 'SecureHandlerBaseTemplate');
        handler:SetAttribute('UpdateToggleButtonMacro', [=[
            local state = ...
            local Spellbook = self:GetFrameRef("Spellbook");
            local ProfessionFrame = self:GetFrameRef("ProfessionFrame");
            local ToggleButton = self:GetFrameRef("ToggleButton");

            if Spellbook:IsVisible() then
                 if ProfessionFrame:IsVisible() then
                    ToggleButton:SetAttribute('macrotext', ToggleButton:GetAttribute('macroTextDefaultClose'))
                else
                    ToggleButton:SetAttribute('macrotext', ToggleButton:GetAttribute('macroTextOpen'))
                end 
            else
                ProfessionFrame:Hide()
                ToggleButton:SetAttribute('macrotext', ToggleButton:GetAttribute('macroTextDefault'))
            end 
        ]=])
        handler:SetFrameRef("Spellbook", SpellBookFrame)
        handler:SetFrameRef("ProfessionFrame", frame)
        handler:SetFrameRef("ToggleButton", toggleButton)

        local shower = CreateFrame('FRAME', 'DragonflightUISpellbookFrameShower', SpellBookFrame,
                                   'SecureHandlerShowHideTemplate')
        shower:SetPoint('TOPLEFT')
        shower:SetPoint('BOTTOMRIGHT')
        shower:SetAttribute('_onshow', [[   
            local handler = self:GetFrameRef("handler");
            handler:Run(handler:GetAttribute('UpdateToggleButtonMacro'), '_onshow')
        ]])
        shower:SetAttribute('_onhide', [[   
            local handler = self:GetFrameRef("handler");
            handler:Run(handler:GetAttribute('UpdateToggleButtonMacro'), '_onhide')
        ]])
        shower:SetFrameRef("handler", handler)

        shower:HookScript('OnHide', function()
            DragonflightUICharacterTabMixin:Tab_OnClick(tabFrame.Tabs[1], tabFrame)
        end)

        frame.buttonShow:SetFrameRef("handler", handler)
        frame.buttonHide:SetFrameRef("handler", handler)
    end

    DragonflightUIMixin:AddNineSliceTextures(frame, true)
    DragonflightUIMixin:ButtonFrameTemplateNoPortrait(frame)
    DragonflightUIMixin:FrameBackgroundSolid(frame, true)

    if SpellBookCloseButton then SpellBookCloseButton:SetFrameLevel(80) end

    local titleText = frame:CreateFontString('DragonflightUISpellbookProfessionFrameTitleText', 'ARTWORK',
                                             'GameFontNormal')
    titleText:SetPoint('TOP', frame, 'TOP', 0, -5)
    titleText:SetPoint('LEFT', frame, 'LEFT', 60, 0)
    titleText:SetPoint('RIGHT', frame, 'RIGHT', -60, 0)
    titleText:SetText(TRADE_SKILLS)

    do
        local port = frame:CreateTexture('DragonflightUISpellbookProfessionFramePortrait')
        port:SetSize(62, 62)
        port:ClearAllPoints()
        port:SetPoint('TOPLEFT', frame, 'TOPLEFT', -5, 7)
        ---@diagnostic disable-next-line: param-type-mismatch
        port:SetParent(frame)
        port:SetTexture(136830)
        ---@diagnostic disable-next-line: param-type-mismatch
        SetPortraitToTexture(port, port:GetTexture())
        port:SetDrawLayer('OVERLAY', 6)
        port:Show()

        frame.PortraitFrame = frame:CreateTexture('DragonflightUISpellbookProfessionFramePortraitFrame')
        local pp = frame.PortraitFrame
        pp:SetTexture(base .. 'UI-Frame-PortraitMetal-CornerTopLeft')
        pp:SetTexCoord(0.0078125, 0.0078125, 0.0078125, 0.6171875, 0.6171875, 0.0078125, 0.6171875, 0.6171875)
        pp:SetSize(84, 84)
        pp:ClearAllPoints()
        pp:SetPoint('CENTER', port, 'CENTER', 0, 0)
        pp:SetDrawLayer('OVERLAY', 7)
    end

    do
        local inset = CreateFrame('FRAME', 'DragonflightUISpellBookInset', frame, 'InsetFrameTemplate')
        inset:SetPoint('TOPLEFT', frame, 'TOPLEFT', 4, -24)
        inset:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', -6, 4)
        inset:SetFrameLevel(1)

        local first = frame:CreateTexture('DragonflightUISpellBookPage1', 'BACKGROUND')
        first:SetTexture(base .. 'Professions-Book-Left')
        first:SetPoint('TOPLEFT', frame, 'TOPLEFT', 7, -25)

        local second = frame:CreateTexture('DragonflightUISpellBookPage2', 'BACKGROUND')
        second:SetTexture(base .. 'Professions-Book-Right')
        second:SetPoint('TOPLEFT', first, 'TOPRIGHT', 0, 0)

        local bg = frame:CreateTexture('DragonflightUISpellBookBG', 'BACKGROUND')
        bg:SetTexture(base .. 'UI-Background-RockCata')
        bg:SetPoint('TOPLEFT', frame, 'TOPLEFT', 2, -21)
        bg:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', -2, 2)
        bg:SetDrawLayer('BACKGROUND', -6)
    end

    frame:InitHook()
    frame:Update()

    if SpellBookFrame_Update then
        hooksecurefunc('SpellBookFrame_Update', function()
            frame:Update()
        end)
    end
end
