local addonName, addonTable = ...;
local Helper = addonTable.Helper;
local DF = LibStub('AceAddon-3.0'):GetAddon('DragonflightUI')
local L = LibStub("AceLocale-3.0"):GetLocale("DragonflightUI")
local LibTradeSkillRecipes = LibStub("LibTradeSkillRecipes-1", true)

local base = 'Interface\\Addons\\DragonflightUI\\Textures\\UI\\'

DFProfessionMixin = DFProfessionMixin or {}

local professionDataTable = {}
do
    professionDataTable[129] = {tex = 'professionbackgroundart', bar = 'professionsfxalchemy', icon = 135966} -- first aid
    professionDataTable[164] = {
        tex = 'ProfessionBackgroundArtBlacksmithing',
        bar = 'professionsfxblacksmithing',
        icon = 136241
    }
    professionDataTable[165] = {
        tex = 'ProfessionBackgroundArtLeatherworking',
        bar = 'professionsfxleatherworking',
        icon = 133611
    }
    professionDataTable[171] = {tex = 'ProfessionBackgroundArtAlchemy', bar = 'professionsfxalchemy', icon = 136240}
    professionDataTable[182] = {tex = 'ProfessionBackgroundArtHerbalism', bar = '', icon = 136246} -- herb
    professionDataTable[185] = {tex = 'ProfessionBackgroundArtCooking', bar = 'professionsfxcooking', icon = 133971}
    professionDataTable[186] = {tex = 'ProfessionBackgroundArtMining', bar = 'professionsfxmining', icon = 136248}
    professionDataTable[197] = {tex = 'ProfessionBackgroundArtTailoring', bar = 'professionsfxtailoring', icon = 136249}
    professionDataTable[202] = {
        tex = 'ProfessionBackgroundArtEngineering',
        bar = 'professionsfxengineering',
        icon = 136243
    }
    professionDataTable[333] = {
        tex = 'ProfessionBackgroundArtEnchanting',
        bar = 'professionsfxenchanting',
        icon = 136244
    }
    professionDataTable[356] = {tex = 'ProfessionBackgroundArtFishing', bar = '', icon = 136245} -- fishing
    professionDataTable[393] = {tex = 'ProfessionBackgroundArtSkinning', bar = 'professionsfxskinning', icon = 134366} -- skinning
    professionDataTable[755] = {
        tex = 'ProfessionBackgroundArtJewelcrafting',
        bar = 'professionsfxjewelcrafting',
        icon = 134071
    }
    professionDataTable[773] = {
        tex = 'ProfessionBackgroundArtInscription',
        bar = 'professionsfxinscription',
        icon = 237171
    }
    professionDataTable[794] = {
        tex = 'ProfessionBackgroundArtLeatherworking',
        bar = 'professionsfxleatherworking',
        icon = 441139
    } -- archeology
    professionDataTable[666] = {tex = 'ProfessionBackgroundArtAlchemy', bar = 'professionsfxalchemy', icon = 136242} -- poison
    professionDataTable[667] = {tex = 'professionbackgroundart', bar = 'professionsfxskinning', icon = 132162} -- beast training
    professionDataTable[668] = {tex = 'professionbackgroundart', bar = 'professionsfxskinning', icon = 237523} -- runeforging
    DFProfessionMixin.ProfessionDataTable = professionDataTable
end

if not PROFESSION_RANKS then
    PROFESSION_RANKS = {};
    PROFESSION_RANKS[1] = {75, APPRENTICE};
    PROFESSION_RANKS[2] = {150, JOURNEYMAN};
    PROFESSION_RANKS[3] = {225, EXPERT};
    PROFESSION_RANKS[4] = {300, ARTISAN};
    PROFESSION_RANKS[5] = {375, MASTER};
    PROFESSION_RANKS[6] = {450, GRAND_MASTER};
    PROFESSION_RANKS[7] = {525, ILLUSTRIOUS};
end

local primary = {164, 165, 171, 182, 186, 197, 202, 333, 393, 755, 773}
local ignoredPrimary = {182, 393}
local profs = {
    primary = {},
    ignoredPrimary = {},
    poison = 666,
    fishing = 356,
    cooking = 185,
    firstaid = 129,
    beast = 667,
    runeforging = 668
}
for k, v in ipairs(primary) do profs.primary[v] = true end
for k, v in ipairs(ignoredPrimary) do profs.ignoredPrimary[v] = true end

function DFProfessionMixin:OnLoad()
    self:SetupFavoriteDatabase()

    self.minimized = false
    self.ProfessionTable = {}
    self.SelectedProfession = ''
    self.SelectedSkillID = ''

    local tt = CreateFrame("GameTooltip", "DragonflightUIScanningTooltip", nil, "GameTooltipTemplate")
    tt:SetOwner(WorldFrame, "ANCHOR_NONE");
    self.ScanningTooltip = tt

    self:SetupFrameStyle()
    self:SetupSchematics()
    if DF.API.Version.IsMoP then
        self:SetupDropdownMists()
    else
        self:SetupDropdown()
    end
    self:SetupTabs()
    self:SetupFavorite()
    self:Minimize(self.minimized)

    self:Refresh(true)
    self:Show()

    if SpellBookFrame_Update then
        hooksecurefunc('SpellBookFrame_Update', function()
            self:Refresh(true)
        end)
    end

    self:RegisterEvent('PLAYER_REGEN_ENABLED')

    self:RegisterEvent("TRADE_SKILL_SHOW");
    self:RegisterEvent("TRADE_SKILL_CLOSE");
    self:RegisterEvent("TRADE_SKILL_UPDATE");
    self:RegisterEvent("TRADE_SKILL_FILTER_UPDATE");

    self:RegisterEvent("CRAFT_SHOW");
    self:RegisterEvent("CRAFT_CLOSE");
    self:RegisterEvent("CRAFT_UPDATE");
    self:RegisterEvent("SPELLS_CHANGED");
    self:RegisterEvent("UNIT_PET_TRAINING_POINTS");

    self.RecipeList:RegisterCallback('OnRecipeSelected', function(recipeList, id)
        self:UpdateRecipe(id)
    end, self)

    self.MinimizeButton:SetOnMaximizedCallback(function(btn)
        self:Minimize(false)
    end)
    self.MinimizeButton:SetOnMinimizedCallback(function(btn)
        self:Minimize(true)
    end)

    self.ClosePanelButton:HookScript("OnClick", function(btn)
        CloseTradeSkill()
        CloseCraft()
    end);

    self.RecipeList.ResetButton:SetScript('OnClick', function(btn)
        self:ResetFilter()
    end)

    self:AddBlizzMoveSupport();
    self:SuppressBlizzardFrames()
    self:Hide()
end

function DFProfessionMixin:SuppressBlizzardFrames()
    local frame = _G['TradeSkillFrame']
    if frame and frame.SetAlpha then
        frame:SetAlpha(0)
        if frame.EnableMouse then frame:EnableMouse(false) end
    end
    local cFrame = _G['CraftFrame']
    if cFrame and cFrame.SetAlpha then
        cFrame:SetAlpha(0)
        if cFrame.EnableMouse then cFrame:EnableMouse(false) end
    end
end

function DFProfessionMixin:OnShow()
end

function DFProfessionMixin:OnHide()
end

function DFProfessionMixin:ShouldShow(should)
    if should then
        self:Show()
        self:SuppressBlizzardFrames()

        if self.TradeSkillOpen then
            self:ClearAllPoints()
            self:SetPoint('TOPLEFT', TradeSkillFrame, 'TOPLEFT', 12, -12)

            if TradeSkillFrame then TradeSkillFrame:SetFrameStrata('BACKGROUND') end
            self:SetFrameStrata('MEDIUM')

            self:UpdateUIPanelWindows(not self.minimized)
        elseif self.CraftOpen then
            self:ClearAllPoints()
            self:SetPoint('TOPLEFT', CraftFrame, 'TOPLEFT', 12, -12)

            if CraftFrame then CraftFrame:SetFrameStrata('BACKGROUND') end
            self:SetFrameStrata('MEDIUM')

            self:UpdateUIPanelWindows(not self.minimized)
        end
    else
        self:Hide()
    end
end

function DFProfessionMixin:OnEvent(event, arg1, ...)
    if event == 'TRADE_SKILL_SHOW' then
        self.TradeSkillOpen = true;
        self.CraftOpen = false;
        CloseCraft()
        self:ShouldShow(true)
        self:Refresh(true)
    elseif event == 'CRAFT_SHOW' then
        self.TradeSkillOpen = false;
        self.CraftOpen = true;
        CloseTradeSkill()
        self:ShouldShow(true)
        self:Refresh(true)
    elseif event == 'TRADE_SKILL_CLOSE' then
        self.TradeSkillOpen = false;
        if not self.CraftOpen then self:ShouldShow(false) end
    elseif event == 'CRAFT_CLOSE' then
        self.CraftOpen = false;
        if not self.TradeSkillOpen then self:ShouldShow(false) end
    elseif event == 'TRADE_SKILL_UPDATE' or event == 'TRADE_SKILL_FILTER_UPDATE' or event == 'CRAFT_UPDATE' then
        if self:IsShown() then self:Refresh(false) end
    elseif event == 'PLAYER_REGEN_ENABLED' then
        if self.ShouldUpdate then self:UpdateTabs() end
    elseif event == 'UNIT_PET_TRAINING_POINTS' then
        self:UpdateTrainingPoints()
    elseif event == 'SPELLS_CHANGED' then
        self:Refresh(true)
    end
end

local frameWidth = 942 - 164
local frameWidthSmall = 404 - 50

function DFProfessionMixin:Minimize(mini)
    self.minimized = mini

    if mini then
        self:SetWidth(frameWidthSmall)
        self:UpdateUIPanelWindows(false)

        self.RecipeList:Hide()
        self.RecipeList:SetWidth(0.1)

        self.RankFrame:Hide()

        self.SchematicForm.NineSlice:Hide()
        self.SchematicForm.BackgroundNineSlice:Hide()
        self.SchematicForm.Background:Hide()
        self.SchematicForm.MinimalBackground:Show()

        self.CreateButton:ClearAllPoints()
        self.CreateButton:SetPoint('BOTTOMRIGHT', self, 'BOTTOMRIGHT', -9, 13 - 6)
    else
        self:SetWidth(frameWidth)
        self:SetHeight(525)

        self:UpdateUIPanelWindows(true)

        self.RecipeList:Show()
        self.RecipeList:SetWidth(274)

        self.RankFrame:Show()

        self.SchematicForm.NineSlice:Show()
        self.SchematicForm.BackgroundNineSlice:Show()
        self.SchematicForm.Background:Show()
        self.SchematicForm.MinimalBackground:Hide()

        self.CreateButton:ClearAllPoints()
        self.CreateButton:SetPoint('BOTTOMRIGHT', self, 'BOTTOMRIGHT', -9, 7)
    end
end

function DFProfessionMixin:UpdateUIPanelWindows(big)
    local width = big and frameWidth or frameWidthSmall

    if TradeSkillFrame then
        TradeSkillFrame:SetAttribute("UIPanelLayout-area", "left")
        TradeSkillFrame:SetAttribute("UIPanelLayout-pushable", 3)
        TradeSkillFrame:SetAttribute("UIPanelLayout-width", width)
        if UIPanelWindows and UIPanelWindows["TradeSkillFrame"] then
            UIPanelWindows["TradeSkillFrame"].area = "left"
            UIPanelWindows["TradeSkillFrame"].pushable = 3
            UIPanelWindows["TradeSkillFrame"].width = width
        end
        UpdateUIPanelPositions(TradeSkillFrame)
    end

    if CraftFrame then
        CraftFrame:SetAttribute("UIPanelLayout-area", "left")
        CraftFrame:SetAttribute("UIPanelLayout-pushable", 3)
        CraftFrame:SetAttribute("UIPanelLayout-width", width)
        if UIPanelWindows and UIPanelWindows["CraftFrame"] then
            UIPanelWindows["CraftFrame"].area = "left"
            UIPanelWindows["CraftFrame"].pushable = 3
            UIPanelWindows["CraftFrame"].width = width
        end
        UpdateUIPanelPositions(CraftFrame)
    end
end

function DFProfessionMixin:SetupFrameStyle()
    DragonflightUIMixin:ButtonFrameTemplateNoPortrait(self)
    DragonflightUIMixin:MaximizeMinimizeButtonFrameTemplate(self.MinimizeButton)
    self.MinimizeButton:ClearAllPoints()
    self.MinimizeButton:SetPoint('RIGHT', self.ClosePanelButton, 'LEFT', 0, 0)

    self:SetFrameStrata('MEDIUM')

    do
        local icon = self:CreateTexture('DragonflightUIProfessionIcon')
        icon:SetSize(62, 62)
        icon:SetPoint('TOPLEFT', self, 'TOPLEFT', -5, 7)
        icon:SetDrawLayer('OVERLAY', 6)
        self.Icon = icon

        Helper:AddCircleMask(self, self.Icon)
        if _G['CraftFramePortrait'] then _G['CraftFramePortrait']:Hide() end

        if _G['TradeSkillFramePortrait'] then
            _G['TradeSkillFramePortrait']:Hide()
            _G['TradeSkillFramePortrait']:SetAlpha(0)
            hooksecurefunc(_G['TradeSkillFramePortrait'], 'Show', function()
                _G['TradeSkillFramePortrait']:Hide()
            end)
        end

        local pp = self:CreateTexture('DragonflightUIProfessionIconFrame')
        pp:SetTexture(base .. 'UI-Frame-PortraitMetal-CornerTopLeft')
        pp:SetTexCoord(0.0078125, 0.0078125, 0.0078125, 0.6171875, 0.6171875, 0.0078125, 0.6171875, 0.6171875)
        pp:SetSize(84, 84)
        pp:SetPoint('CENTER', icon, 'CENTER', 0, 0)
        pp:SetDrawLayer('OVERLAY', 7)
        self.PortraitFrame = pp
    end

    do
        local top = self.Bg.TopSection
        top:SetTexture(base .. 'ui-background-rock')
        top:ClearAllPoints()
        top:SetPoint('TOPLEFT', self.Bg, 'TOPLEFT', 0, 0)
        top:SetPoint('BOTTOMRIGHT', self.Bg.BottomRight, 'BOTTOMRIGHT', 0, 0)
        top:SetDrawLayer('BACKGROUND', 2)

        local bg = _G[self:GetName() .. 'Bg']
        if bg then bg:Hide() end

        self.Bg:SetPoint('BOTTOMRIGHT', self, 'BOTTOMRIGHT', 0, 3)

        local newBG = self:CreateTexture('DragonflightUIRecipeListBG')
        newBG:SetTexture(base .. 'professions')
        newBG:SetTexCoord(0.000488281, 0.131348, 0.0771484, 0.635742)
        newBG:SetSize(268, 572)
        newBG:ClearAllPoints()
        newBG:SetPoint('TOPLEFT', self.RecipeList, 'TOPLEFT', 0, 0)
        newBG:SetPoint('BOTTOMRIGHT', self.RecipeList, 'BOTTOMRIGHT', 0, 0)

        self.NineSlice.Text:SetText('tmp')

        local titleFrame = CreateFrame('Frame', 'DragonflightUITitleFrame')
        titleFrame:SetPoint('TOP', self.NineSlice, 'TOP', 0, -2)
        titleFrame:SetPoint('LEFT', self.NineSlice, 'LEFT', 60, 0)
        titleFrame:SetPoint('RIGHT', self.NineSlice, 'RIGHT', -60, 0)
        titleFrame:SetHeight(self.NineSlice.Text:GetHeight())

        self.NineSlice.Text:ClearAllPoints()
        self.NineSlice.Text:SetPoint('CENTER', titleFrame, 'CENTER', 0, 0)

        local linkButton = self.LinkButton
        linkButton:ClearAllPoints()
        linkButton:SetPoint('LEFT', self.NineSlice.Text, 'RIGHT', 5, 0)
    end

    do
        local rankFrame = CreateFrame('Frame', 'DragonflightUIProfessionRankFrame', self)
        rankFrame:SetSize(453, 18)
        rankFrame:SetPoint('TOPLEFT', self, 'TOPLEFT', 280, -40)

        local rankFrameBG = rankFrame:CreateTexture('DragonflightUIProfessionRankFrameBackground')
        rankFrameBG:SetDrawLayer('BACKGROUND', 1)
        rankFrameBG:SetTexture(base .. 'professions')
        rankFrameBG:SetTexCoord(0.29834, 0.518555, 0.750977, 0.779297)
        rankFrameBG:SetSize(451, 29)
        rankFrameBG:SetPoint('TOPLEFT', rankFrame, 'TOPLEFT', 0, 0)

        local rankFrameBar = CreateFrame('Statusbar', 'DragonflightUIProfessionRankFrameBar', rankFrame)
        rankFrameBar:SetSize(441, 18)
        rankFrameBar:SetPoint('TOPLEFT', rankFrame, 'TOPLEFT', 5, -3)
        rankFrameBar:SetMinMaxValues(0, 100);
        rankFrameBar:SetValue(69);
        rankFrameBar:SetStatusBarTexture(base .. 'professionsfxalchemy')

        local rankFrameMask = rankFrame:CreateMaskTexture('DragonflightUIProfessionRankFrameMask')
        rankFrameMask:SetPoint('TOPLEFT', rankFrameBar, 'TOPLEFT', 0, 0)
        rankFrameMask:SetPoint('BOTTOMRIGHT', rankFrameBar, 'BOTTOMRIGHT', 0, 0)
        rankFrameMask:SetTexture(base .. 'profbarmask', "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
        rankFrameBar:GetStatusBarTexture():AddMaskTexture(rankFrameMask)

        local rankFrameBorder = rankFrame:CreateTexture('DragonflightUIProfessionRankFrameBorder')
        rankFrameBorder:SetDrawLayer('OVERLAY', 1)
        rankFrameBorder:SetTexture(base .. 'professions')
        rankFrameBorder:SetTexCoord(0.663574, 0.883789, 0.129883, 0.158203)
        rankFrameBorder:SetSize(451, 29)
        rankFrameBorder:SetPoint('TOPLEFT', rankFrame, 'TOPLEFT', 0, 0)

        -- The rank text belongs on the bar, not on rankFrame.
        --
        -- rankFrameBar is a child FRAME, so everything it draws sits above every
        -- draw layer of rankFrame - OVERLAY included. A FontString created on
        -- rankFrame therefore ended up behind the bar's fill texture, which is
        -- opaque, and the skill number was invisible: a fully drawn bar with no
        -- text on it. That was issue #29. On the bar itself, OVERLAY is above the
        -- fill.
        --
        -- The name argument is nil rather than '' as well - a font string needs no
        -- global, and '' put an entry under the empty-string key into _G.
        local rankFrameText = rankFrameBar:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
        rankFrameText:SetPoint('CENTER', rankFrameBar, 'CENTER', 0, 0)

        -- Blank until UpdateRankFrame runs. It used to read '69/100', which was a
        -- placeholder next to the bar's own SetValue(69) and was harmless only for
        -- as long as nobody could see it.
        rankFrameText:SetText('')

        function rankFrame:UpdateRankFrame(value, minValue, maxValue)
            rankFrameBar:SetMinMaxValues(minValue, maxValue)
            rankFrameBar:SetValue(value)
            rankFrameText:SetText(value .. '/' .. maxValue)
        end

        self.RankFrame = rankFrame
        self.RankFrameBar = rankFrameBar
        self.RankFrameText = rankFrameText
    end

    do
        local create = CreateFrame('Button', 'DragonflightUIProfessionCreateButton', self, 'UIPanelButtonTemplate')
        create:SetSize(80, 22)
        create:SetText(CREATE)
        create:SetFrameLevel(10)
        self.CreateButton = create

        local createAll =
            CreateFrame('Button', 'DragonflightUIProfessionCreateAllButton', self, 'UIPanelButtonTemplate')
        createAll:SetSize(80, 22)
        createAll:SetText(CREATE_ALL)
        createAll:SetPoint('RIGHT', create, 'LEFT', -86, 0)
        self.CreateAllButton = createAll

        local cancel = CreateFrame('Button', 'DragonflightUIProfessionCancelButton', self, 'UIPanelButtonTemplate')
        cancel:SetSize(80, 22)
        cancel:SetText(EXIT)
        self.CancelButton = cancel

        local decrement = CreateFrame('Button', 'DragonflightUIProfessionDecrementButton', self)
        decrement:SetSize(23, 22)
        decrement:SetNormalTexture('Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up')
        decrement:SetPushedTexture('Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Down')
        decrement:SetDisabledTexture('Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Disabled')
        decrement:SetHighlightTexture('Interface\\Buttons\\UI-Common-MouseHilight', 'ADD')
        decrement:SetPoint('LEFT', createAll, 'RIGHT', 3, 0)
        self.DecrementButton = decrement;

        local increment = CreateFrame('Button', 'DragonflightUIProfessionIncrementButton', self)
        increment:SetSize(23, 22)
        increment:SetNormalTexture('Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up')
        increment:SetPushedTexture('Interface\\Buttons\\UI-SpellbookIcon-NextPage-Down')
        increment:SetDisabledTexture('Interface\\Buttons\\UI-SpellbookIcon-NextPage-Disabled')
        increment:SetHighlightTexture('Interface\\Buttons\\UI-Common-MouseHilight', 'ADD')
        increment:SetPoint('RIGHT', create, 'LEFT', -3, 0)
        self.Incrementbutton = increment;

        local editbox = self.InputBox
        editbox:SetPoint('LEFT', decrement, 'RIGHT', 4, 0)

        local function incrementClicked()
            if editbox:GetNumber() < 100 then editbox:SetNumber(editbox:GetNumber() + 1) end
        end

        increment:SetScript('OnClick', function()
            incrementClicked()
            editbox:ClearFocus()
        end)

        local function decrementClicked()
            if editbox:GetNumber() > 0 then editbox:SetNumber(editbox:GetNumber() - 1) end
        end

        decrement:SetScript('OnClick', function()
            decrementClicked()
            editbox:ClearFocus()
        end)
    end

    if DF.Era or DF.API.Version.IsTBC then
        local trainingFrame = CreateFrame('Frame', 'DragonflightUIProfessionTrainingPointFrame', self)
        trainingFrame:SetSize(120, 18)
        trainingFrame:SetPoint('RIGHT', CraftCreateButton, 'LEFT', -12, 0)
        self.TrainingFrame = trainingFrame

        local trainingLabel = trainingFrame:CreateFontString(nil, 'ARTWORK', 'GameFontNormalSmall')
        trainingLabel:SetPoint('LEFT', trainingFrame, 'LEFT', 10, 0)
        trainingLabel:SetText(TRAINING_POINTS)
        self.TrainingFrameLabel = trainingLabel

        local trainingText = trainingFrame:CreateFontString(nil, 'ARTWORK', 'GameFontHighlightSmall')
        trainingText:SetPoint('LEFT', trainingLabel, 'RIGHT', 6, 0)
        trainingText:SetText('69 TP')
        self.TrainingFrameText = trainingText

        local newW = trainingLabel:GetUnboundedStringWidth() + trainingText:GetUnboundedStringWidth() + 10 + 6
        trainingFrame:SetWidth(newW)
        trainingFrame:Hide()
    end

    if _G['TradeSkillHighlightFrame'] then _G['TradeSkillHighlightFrame']:SetAlpha(0) end
end

function DFProfessionMixin:UpdateTrainingPoints()
    if not self.TrainingFrame then return end

    if self.TradeSkillOpen then
        self.TrainingFrame:Hide()
    elseif self.CraftOpen then
        if self.SelectedProfession == 'beast' then
            self.TrainingFrame:Show()
            local totalPoints, spent = GetPetTrainingPoints();
            totalPoints = totalPoints or 0
            spent = spent or 0
            self.TrainingFrameLabel:Show();
            self.TrainingFrameText:Show();
            self.TrainingFrameText:SetText(totalPoints - spent);
            local newW = (self.TrainingFrameLabel:GetUnboundedStringWidth() or 40) +
                             (self.TrainingFrameText:GetUnboundedStringWidth() or 20) + 16
            self.TrainingFrame:SetWidth(newW)
        else
            self.TrainingFrame:Hide()
        end
    else
        self.TrainingFrame:Hide()
    end
end

function DFProfessionMixin:AddBlizzMoveSupport()
    DF.Compatibility:FuncOrWaitframe('BlizzMove', function()
        if not BlizzMoveAPI or not BlizzMoveAPI.RegisterAddOnFrames then return end

        local data = {['DragonflightUI'] = {['DragonflightUIProfessionFrame'] = {}}}
        BlizzMoveAPI:RegisterAddOnFrames(data)
    end)
end

function DFProfessionMixin:SetupTabs()
    local tabFrame = CreateFrame('FRAME', 'DragonflightUIProfessionFrameTabFrame', self)

    self.DFTabFrame = tabFrame
    local numTabs = 8
    tabFrame.numTabs = numTabs
    tabFrame.Tabs = {}

    for i = 1, numTabs do
        local tab = CreateFrame('BUTTON', 'DragonflightUIProfessionFrameTabButton' .. i, tabFrame,
                                'DFProfessionTabTemplate', i)
        tab:SetParent(tabFrame)
        local text = _G[tab:GetName() .. 'Text']
        tab.Text = text;
        function tab:SetText(str)
            text:SetText(str)
        end
        tinsert(tabFrame.Tabs, i, tab)

        DragonflightUIMixin:CharacterFrameTabButtonTemplate(tab, true, true)
        tab:SetAttribute('type', 'macro')

        if i == 1 then
            tab:ClearAllPoints()
            tab:SetPoint('TOPLEFT', self, 'BOTTOMLEFT', 12, 2)
            text:SetText('*Prof1*')
            tab:SetScript('OnEnter', function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
                GameTooltip:SetText('1', 1.0, 1.0, 1.0);
            end)
        else
            tab.DFChangePoint = true
            tab:ClearAllPoints()
            tab:SetPoint('LEFT', tabFrame.Tabs[i - 1], 'RIGHT', 0, 0)
            text:SetText('*Prof' .. i .. '*')
            tab:SetScript('OnEnter', function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
                GameTooltip:SetText(i, 1.0, 1.0, 1.0);
            end)
        end

        local function onClick()
            local profIndex = ''
            if i == 1 then
                profIndex = 'primary1'
            elseif i == 2 then
                profIndex = 'primary2'
            elseif i == 3 then
                profIndex = 'cooking'
            elseif i == 4 then
                profIndex = 'firstaid'
            elseif i == 5 then
                profIndex = 'poison'
            elseif i == 6 then
                profIndex = 'beast'
            elseif i == 7 then
                profIndex = 'runeforging'
            end

            local prof = self.ProfessionTable[profIndex]
            if not prof then return end
            if tabFrame.selectedTab == i then return end

            local spellToCast = prof.nameLoc

            if spellToCast == 'Costura' then
                spellToCast = 'Sastrería'
            elseif spellToCast == 'Marroquinería' then
                spellToCast = 'Peletería'
            elseif spellToCast == 'Minería' then
                spellToCast = 'Fundiendo'
                if DF.API.Version.IsTBC or DF.API.Version.IsMoP then spellToCast = 'Fundición' end
                if DF.API.Version.IsClassic then spellToCast = 'Fundición' end
            elseif spellToCast == 'Secourisme' then
                spellToCast = 'Premiers soins'
            end

            if spellToCast == DragonflightUILocalizationData.DF_CHARACTER_PROFESSIONMINING then
                spellToCast = DragonflightUILocalizationData.DF_PROFESSIONS_SMELTING
            end

            if prof.skillID == 182 or prof.skillID == 393 then return end
            CastSpellByName(spellToCast)
        end

        tab:SetScript('OnClick', onClick)
        tab.DFOnClick = onClick

        DragonflightUIMixin:TabResize(tab)
    end
end

function DFProfessionMixin:UpdateTabs()
    local tabFrame = self.DFTabFrame;
    if InCombatLockdown() then return end

    local function setupTooltip(tab, prof)
        tab:SetScript('OnEnter', function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
            GameTooltip:SetText(prof.nameLoc, 1.0, 1.0, 1.0);
            GameTooltip:AddDoubleLine(' ')
            GameTooltip:AddDoubleLine('Skill: ', '|cFFFFFFFF' .. prof.skill .. '/' .. prof.maxSkill .. '|r')
            GameTooltip:Show()
        end)
    end

    local tabs = tabFrame.Tabs;
    local tab;

    local prof1 = self.ProfessionTable['primary1'];
    tab = tabs[1]
    if prof1 then
        tab:Enable()
        tab:Show()
        tab:SetText(prof1.nameLoc)
        setupTooltip(tab, prof1)
        tab.isDisabled = (prof1.skillID == 182 or prof1.skillID == 393)
        if self.SelectedProfession == 'primary1' then DragonflightUICharacterTabMixin:Tab_OnClick(tab, tabFrame) end
    else
        tab:Hide()
        tab:SetText('***')
    end

    local prof2 = self.ProfessionTable['primary2'];
    tab = tabs[2]
    if prof2 then
        tab:Enable()
        tab:Show()
        tab:SetText(prof2.nameLoc)
        setupTooltip(tab, prof2)
        tab.isDisabled = (prof2.skillID == 182 or prof2.skillID == 393)
        if self.SelectedProfession == 'primary2' then DragonflightUICharacterTabMixin:Tab_OnClick(tab, tabFrame) end
    else
        tab:Hide()
        tab:SetText('***')
    end

    local prof3 = self.ProfessionTable['cooking'];
    tab = tabs[3]
    if prof3 then
        tab:Enable()
        tab:Show()
        tab:SetText(prof3.nameLoc)
        setupTooltip(tab, prof3)
        if self.SelectedProfession == 'cooking' then DragonflightUICharacterTabMixin:Tab_OnClick(tab, tabFrame) end
    else
        tab:Hide()
        tab:SetText('***')
    end

    local prof4 = self.ProfessionTable['firstaid'];
    tab = tabs[4]
    if prof4 then
        tab:Enable()
        tab:Show()
        tab:SetText(prof4.nameLoc)
        setupTooltip(tab, prof4)
        if self.SelectedProfession == 'firstaid' then DragonflightUICharacterTabMixin:Tab_OnClick(tab, tabFrame) end
    else
        tab:Hide()
        tab:SetText('***')
    end

    local prof5 = self.ProfessionTable['poison'];
    tab = tabs[5]
    if prof5 then
        tab:Enable()
        tab:Show()
        tab:SetText(prof5.nameLoc)
        setupTooltip(tab, prof5)
        if self.SelectedProfession == 'poison' then DragonflightUICharacterTabMixin:Tab_OnClick(tab, tabFrame) end
    else
        tab:Hide()
        tab:SetText('***')
    end

    local prof6 = self.ProfessionTable['beast'];
    tab = tabs[6]
    if prof6 then
        tab:Enable()
        tab:Show()
        tab:SetText(prof6.nameLoc)
        setupTooltip(tab, prof6)
        if self.SelectedProfession == 'beast' then DragonflightUICharacterTabMixin:Tab_OnClick(tab, tabFrame) end
    else
        tab:Hide()
        tab:SetText('***')
    end

    local prof7 = self.ProfessionTable['runeforging'];
    tab = tabs[7]
    if prof7 then
        tab:Enable()
        tab:Show()
        tab:SetText(prof7.nameLoc)
        setupTooltip(tab, prof7)
        if self.SelectedProfession == 'runeforging' then
            DragonflightUICharacterTabMixin:Tab_OnClick(tab, tabFrame)
        end
    else
        tab:Hide()
        tab:SetText('***')
    end

    local prof8 = nil;
    tab = tabs[8]
    if prof8 then
        tab:Enable()
        tab:Show()
        tab:SetText(prof8.nameLoc)
        setupTooltip(tab, prof8)
        if self.SelectedProfession == 'beast' then DragonflightUICharacterTabMixin:Tab_OnClick(tab, tabFrame) end
    else
        tab:Hide()
        tab:SetText('***')
    end

    local tmp;
    for k, v in ipairs(tabs) do
        if v:IsShown() then
            v:ClearAllPoints()
            if tmp then
                v:SetPoint('LEFT', tmp, 'RIGHT', 4, 0)
            else
                v:SetPoint('TOPLEFT', self, 'BOTTOMLEFT', 12, 3)
            end
            DragonflightUIMixin:ResizeTab(v, nil, nil, 64)
            tmp = v
        else
            v:SetWidth(0.01)
        end
    end
end

function DFProfessionMixin:UpdateProfessionData()
    local skillTable = {}
    if DF.Cata then
        local prof1, prof2, archaeology, fishing, cooking, firstaid = GetProfessions()

        if prof1 then
            local name, icon, skillLevel, maxSkillLevel, numAbilities, spelloffset, skillLine, skillModifier,
                  specializationIndex, specializationOffset = GetProfessionInfo(prof1)
            skillTable['primary1'] = {
                nameLoc = name,
                icon = icon,
                skillID = skillLine,
                skill = skillLevel,
                maxSkill = maxSkillLevel,
                profData = professionDataTable[skillLine]
            }
        end

        if prof2 then
            local name, icon, skillLevel, maxSkillLevel, numAbilities, spelloffset, skillLine, skillModifier,
                  specializationIndex, specializationOffset = GetProfessionInfo(prof2)
            skillTable['primary2'] = {
                nameLoc = name,
                icon = icon,
                skillID = skillLine,
                skill = skillLevel,
                maxSkill = maxSkillLevel,
                profData = professionDataTable[skillLine]
            }
        end

        if cooking then
            local name, icon, skillLevel, maxSkillLevel, numAbilities, spelloffset, skillLine, skillModifier,
                  specializationIndex, specializationOffset = GetProfessionInfo(cooking)
            skillTable['cooking'] = {
                nameLoc = name,
                icon = icon,
                skillID = skillLine,
                skill = skillLevel,
                maxSkill = maxSkillLevel,
                profData = professionDataTable[skillLine]
            }
        end

        if firstaid then
            local name, icon, skillLevel, maxSkillLevel, numAbilities, spelloffset, skillLine, skillModifier,
                  specializationIndex, specializationOffset = GetProfessionInfo(firstaid)
            skillTable['firstaid'] = {
                nameLoc = name,
                icon = icon,
                skillID = skillLine,
                skill = skillLevel,
                maxSkill = maxSkillLevel,
                profData = professionDataTable[skillLine]
            }
        end

        for i = 1, GetNumSpellTabs() do
            local name, texture, offset, numSpells = GetSpellTabInfo(i)
            for j = 1, numSpells do
                local spellIndex = offset + j
                local spellName, spellSubName = GetSpellBookItemName(spellIndex, BOOKTYPE_SPELL)
                local skillID = DragonflightUILocalizationData:GetSkillIDFromProfessionName(spellName)

                if skillID == profs.runeforging then
                    local icon = GetSpellBookItemTexture(spellIndex, BOOKTYPE_SPELL)
                    skillTable['runeforging'] = {
                        nameLoc = spellName,
                        icon = icon or (professionDataTable[skillID] and professionDataTable[skillID].icon),
                        skillID = skillID,
                        skill = 1,
                        maxSkill = 1,
                        profData = professionDataTable[skillID]
                    }
                elseif skillID == profs.beast then
                    local icon = GetSpellBookItemTexture(spellIndex, BOOKTYPE_SPELL)
                    skillTable['beast'] = {
                        nameLoc = spellName,
                        icon = icon or (professionDataTable[skillID] and professionDataTable[skillID].icon),
                        skillID = skillID,
                        skill = 1,
                        maxSkill = 1,
                        profData = professionDataTable[skillID]
                    }
                elseif skillID == profs.poison then
                    local icon = GetSpellBookItemTexture(spellIndex, BOOKTYPE_SPELL)
                    skillTable['poison'] = {
                        nameLoc = spellName,
                        icon = icon or (professionDataTable[skillID] and professionDataTable[skillID].icon),
                        skillID = skillID,
                        skill = 1,
                        maxSkill = 1,
                        profData = professionDataTable[skillID]
                    }
                end
            end
        end
    else
        local numSkills = GetNumSkillLines();
        local currentHeader = nil;

        for i = 1, numSkills do
            local skillName, header, isExpanded, skillRank, numTempPoints, skillModifier, skillMaxRank, isAbandonable,
                  stepCost, rankCost, minLevel, skillCostType, skillDescription = GetSkillLineInfo(i);

            if header then
                currentHeader = skillName;
            else
                local skillID = DragonflightUILocalizationData:GetSkillIDFromProfessionName(skillName)

                if skillID then
                    local profDataTable = professionDataTable[skillID]

                    if profs.primary[skillID] then
                        local profIndex = 'primary1'
                        if skillTable['primary1'] then profIndex = 'primary2'; end

                        skillTable[profIndex] = {
                            nameLoc = skillName,
                            icon = profDataTable.icon,
                            skillID = skillID,
                            skill = skillRank,
                            maxSkill = skillMaxRank,
                            profData = profDataTable
                        }
                    elseif skillID == profs.cooking then
                        skillTable['cooking'] = {
                            nameLoc = skillName,
                            icon = profDataTable.icon,
                            skillID = skillID,
                            skill = skillRank,
                            maxSkill = skillMaxRank,
                            profData = profDataTable
                        }
                    elseif skillID == profs.firstaid then
                        skillTable['firstaid'] = {
                            nameLoc = skillName,
                            icon = profDataTable.icon,
                            skillID = skillID,
                            skill = skillRank,
                            maxSkill = skillMaxRank,
                            profData = profDataTable
                        }
                    elseif skillID == profs.poison then
                        skillTable['poison'] = {
                            nameLoc = skillName,
                            icon = profDataTable.icon,
                            skillID = skillID,
                            skill = skillRank,
                            maxSkill = skillMaxRank,
                            profData = profDataTable
                        }
                    elseif skillID == profs.beast then
                        skillTable['beast'] = {
                            nameLoc = skillName,
                            icon = profDataTable.icon,
                            skillID = skillID,
                            skill = skillRank,
                            maxSkill = skillMaxRank,
                            profData = profDataTable
                        }
                    elseif skillID == profs.runeforging then
                        skillTable['runeforging'] = {
                            nameLoc = skillName,
                            icon = profDataTable.icon,
                            skillID = skillID,
                            skill = skillRank,
                            maxSkill = skillMaxRank,
                            profData = profDataTable
                        }
                    end
                end
            end
        end

        for i = 1, GetNumSpellTabs() do
            local name, texture, offset, numSpells = GetSpellTabInfo(i)
            for j = 1, numSpells do
                local spellIndex = offset + j
                local spellName, spellSubName = GetSpellBookItemName(spellIndex, BOOKTYPE_SPELL)
                if spellName then
                    local skillID = DragonflightUILocalizationData:GetSkillIDFromProfessionName(spellName)

                    if skillID == profs.runeforging then
                        local icon = GetSpellBookItemTexture(spellIndex, BOOKTYPE_SPELL)
                        skillTable['runeforging'] = {
                            nameLoc = spellName,
                            icon = icon or (professionDataTable[skillID] and professionDataTable[skillID].icon),
                            skillID = skillID,
                            skill = 1,
                            maxSkill = 1,
                            profData = professionDataTable[skillID]
                        }
                    elseif skillID == profs.beast then
                        local icon = GetSpellBookItemTexture(spellIndex, BOOKTYPE_SPELL)
                        skillTable['beast'] = {
                            nameLoc = spellName,
                            icon = icon or (professionDataTable[skillID] and professionDataTable[skillID].icon),
                            skillID = skillID,
                            skill = 1,
                            maxSkill = 1,
                            profData = professionDataTable[skillID]
                        }
                    elseif skillID == profs.poison then
                        local icon = GetSpellBookItemTexture(spellIndex, BOOKTYPE_SPELL)
                        skillTable['poison'] = {
                            nameLoc = spellName,
                            icon = icon or (professionDataTable[skillID] and professionDataTable[skillID].icon),
                            skillID = skillID,
                            skill = 1,
                            maxSkill = 1,
                            profData = professionDataTable[skillID]
                        }
                    end
                end
            end
        end
    end

    if self.CraftOpen then
        local craftLine = GetCraftDisplaySkillLine()
        if not craftLine or craftLine == DragonflightUILocalizationData.DF_PROFESSIONS_BEAST then
            if not skillTable['beast'] then
                local beastLoc = DragonflightUILocalizationData.DF_PROFESSIONS_BEAST
                local profData = professionDataTable[profs.beast] or professionDataTable[667]
                skillTable['beast'] = {
                    nameLoc = beastLoc,
                    icon = profData and profData.icon or 132162,
                    skillID = profs.beast or 667,
                    skill = 1,
                    maxSkill = 1,
                    profData = profData
                }
            end
        end
    end

    self.ProfessionTable = skillTable
end

function DFProfessionMixin:SetupFavorite()
    local fav = self.FavoriteButton
    fav:SetPoint('LEFT', self.SchematicForm.SkillName, 'RIGHT', 4, 1)

    fav:GetNormalTexture():SetTexture(base .. 'auctionhouse')
    fav:GetNormalTexture():SetTexCoord(0.94043, 0.979492, 0.169922, 0.240234)

    fav:GetHighlightTexture():SetTexture(base .. 'auctionhouse')
    fav:GetHighlightTexture():SetTexCoord(0.94043, 0.979492, 0.169922, 0.240234)

    function fav:SetIsFavorite(isFavorite)
        if isFavorite then
            fav:GetNormalTexture():SetTexCoord(0.94043, 0.979492, 0.0957031, 0.166016)
            fav:GetHighlightTexture():SetTexCoord(0.94043, 0.979492, 0.0957031, 0.166016)
            fav:GetHighlightTexture():SetAlpha(0.2)
        else
            fav:GetNormalTexture():SetTexCoord(0.94043, 0.979492, 0.169922, 0.240234)
            fav:GetHighlightTexture():SetTexCoord(0.94043, 0.979492, 0.169922, 0.240234)
            fav:GetHighlightTexture():SetAlpha(0.4)
        end
        fav.IsFavorite = isFavorite
        fav:SetChecked(isFavorite)
    end

    local frame = self;

    function fav:UpdateFavoriteState()
        if frame.TradeSkillOpen then
            local index = frame.RecipeList.selectedSkill
            local skillName, skillType, numAvailable, isExpanded, altVerb, numSkillUps = GetTradeSkillInfo(index)
            fav:SetIsFavorite(frame:IsRecipeFavorite(skillName))
        elseif frame.CraftOpen then
            local craftIndex = GetCraftSelectionIndex();
            local skillName, craftSubSpellName, skillType, numAvailable, isExpanded, trainingPointCost, requiredLevel =
                GetCraftInfo(craftIndex)
            fav:SetIsFavorite(frame:IsRecipeFavorite(skillName))
        else
            fav:SetIsFavorite(false)
        end
    end
    fav:UpdateFavoriteState()

    local function SetFavoriteTooltip(button)
        GameTooltip:SetOwner(button, "ANCHOR_RIGHT");
        GameTooltip_AddHighlightLine(GameTooltip, button:GetChecked() and BATTLE_PET_UNFAVORITE or BATTLE_PET_FAVORITE);
        GameTooltip:Show();
    end

    fav:SetScript('OnClick', function(button, buttonName, down)
        local checked = button:GetChecked();
        do
            local info;
            if self.TradeSkillOpen then
                local index = self.RecipeList.selectedSkill
                local skillName, skillType, numAvailable, isExpanded, altVerb, numSkillUps = GetTradeSkillInfo(index)
                info = skillName
            elseif self.CraftOpen then
                local craftIndex = GetCraftSelectionIndex();
                local skillName, craftSubSpellName, skillType, numAvailable, isExpanded, trainingPointCost,
                      requiredLevel = GetCraftInfo(craftIndex)
                info = skillName
            else
                return;
            end

            frame:SetRecipeFavorite(info, checked)
            frame:Refresh(false)
        end
        button:SetIsFavorite(checked)
        SetFavoriteTooltip(button)
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
    end)

    fav:SetScript("OnEnter", function(button)
        SetFavoriteTooltip(button);
    end);

    fav:SetScript("OnLeave", GameTooltip_Hide);
end

function DFProfessionMixin:SetupFavoriteDatabase()
    self.db = DF.db:RegisterNamespace('RecipeFavorite', {profile = {favorite = {}}})
end

function DFProfessionMixin:SetRecipeFavorite(info, checked)
    local db = self.db.profile
    if checked then
        db.favorite[info] = true
    else
        db.favorite[info] = nil
    end
end

function DFProfessionMixin:IsRecipeFavorite(info)
    local db = self.db.profile
    if db.favorite[info] then
        return true
    else
        return false
    end
end
