local addonName, addonTable = ...;
local Helper = addonTable.Helper;
local DF = LibStub('AceAddon-3.0'):GetAddon('DragonflightUI')
local L = LibStub("AceLocale-3.0"):GetLocale("DragonflightUI")
local LibTradeSkillRecipes = LibStub("LibTradeSkillRecipes-1")

local base = 'Interface\\Addons\\DragonflightUI\\Textures\\UI\\'
local MAX_TRADE_SKILL_REAGENTS = 8

DFProfessionMixin = DFProfessionMixin or {}

-- Filter
local DFFilter = {}
DFProfessionMixin.DFFilter = DFFilter

do
    local DFFilter_HasSkillUp = function(elementData)
        local skillType = elementData.recipeInfo.skillType
        local filter = DFFilter['DFFilter_HasSkillUp'].filter

        if filter[skillType] then
            return true
        else
            return false
        end
    end

    DFFilter['DFFilter_HasSkillUp'] = {
        name = 'DFFilter_HasSkillUp',
        filterDefault = {trivial = true, easy = true, medium = true, optimal = true, difficult = true},
        filter = {},
        func = DFFilter_HasSkillUp,
        enabled = false
    }
    DFFilter['DFFilter_HasSkillUp'].filter = DFFilter['DFFilter_HasSkillUp'].filterDefault
end

do
    local DFFilter_HaveMaterials = function(elementData)
        return elementData.recipeInfo.numAvailable > 0
    end

    DFFilter['DFFilter_HaveMaterials'] = {
        name = 'DFFilter_HaveMaterials',
        func = DFFilter_HaveMaterials,
        enabled = false
    }
end

do
    local match = function(str, text)
        return strfind(strupper(str), strupper(text))
    end

    local DFFilter_Searchbox = function(elementData, searchBoxRef)
        local searchText = strupper(searchBoxRef:GetText())

        if searchText == '' then return true end
        if string.find(searchText, "%%") then return false end

        local id = elementData.id
        local info = elementData.recipeInfo

        if match(info.name, searchText) then return true end

        local numReagents = GetTradeSkillNumReagents(id);

        for i = 1, numReagents do
            local reagentName, reagentTexture, reagentCount, playerReagentCount = GetTradeSkillReagentInfo(id, i);
            if reagentName and match(reagentName, searchText) then return true end
        end

        return false
    end

    DFFilter['DFFilter_Searchbox'] = {name = 'DFFilter_Searchbox', func = DFFilter_Searchbox, enabled = true}
end

if not DF.API.Version.IsClassic then
    local DFFilter_Expansion = function(elementData)
        local expansion = elementData.expansion
        local filter = DFFilter['DFFilter_Expansion'].filter

        if expansion == -1 then return true; end

        if filter[expansion] then
            return true
        else
            return false
        end
    end

    DFFilter['DFFilter_Expansion'] = {
        name = 'DFFilter_Expansion',
        filterDefault = {[0] = true, [1] = true, [2] = true, [3] = true, [4] = true, [5] = true},
        filter = {},
        func = DFFilter_Expansion,
        enabled = true
    }
    DFFilter['DFFilter_Expansion'].filter = DFFilter['DFFilter_Expansion'].filterDefault
end

function DFProfessionMixin:SetupSchematics()
    local frame = self.SchematicForm

    local icon = CreateFrame('Button', 'DragonflightUIProfessionSkillIcon', frame)
    icon:SetSize(37, 37)
    icon:SetPoint('TOPLEFT', frame, 'TOPLEFT', 28 - 400 + 400, -28)
    frame.SkillIcon = icon

    icon.hasItem = 1;
    icon:SetScript('OnLeave', function()
        GameTooltip:Hide();
        ResetCursor();
    end)

    local iconOverlay = DragonflightUIItemColorMixin:AddOverlayToFrame(icon)
    iconOverlay:SetPoint('TOPLEFT', icon, 'TOPLEFT', 0, 0)
    iconOverlay:SetPoint('BOTTOMRIGHT', icon, 'BOTTOMRIGHT', 0, 0)

    local iconCount = icon:CreateFontString('DragonflightUIProfession' .. 'IconCount', 'OVERLAY', 'NumberFontNormal')
    iconCount:SetText('*1*')
    iconCount:SetJustifyH('RIGHT')
    iconCount:SetPoint('BOTTOMRIGHT', icon, 'BOTTOMRIGHT', -5, 2)
    frame.SkillIconCount = iconCount

    local name = frame:CreateFontString('DragonflightUIProfession' .. 'SkillName', 'BACKGROUND', 'GameFontNormal')
    name:SetSize(244, 10)
    name:SetText('Skill Name')
    name:SetJustifyH('LEFT')
    name:SetPoint('TOPLEFT', icon, 'TOPRIGHT', 14, 0)
    frame.SkillName = name

    if not DF.API.Version.IsClassic then
        local expansion = frame:CreateFontString('DragonflightUIProfession' .. 'ExpansionName', 'BACKGROUND',
                                                 'GameFontNormalSmall')
        expansion:SetSize(244, 14)
        expansion:SetText('')
        expansion:SetJustifyH('LEFT')
        expansion:SetPoint('BOTTOMLEFT', frame, 'BOTTOMLEFT', 7, 4)
        frame.ExpansionName = expansion
    end

    local req = frame:CreateFontString('DragonflightUIProfession' .. 'RequirementLabel', 'BACKGROUND',
                                       'GameFontHighlightSmall')
    req:SetPoint('TOPLEFT', name, 'BOTTOMLEFT', 0, -4)
    req:SetText(REQUIRES_LABEL)
    frame.RequirementLabel = req

    local reqText = frame:CreateFontString('DragonflightUIProfession' .. 'RequirementText', 'BACKGROUND',
                                           'GameFontHighlightSmall')
    reqText:SetJustifyH("LEFT");
    reqText:SetPoint('TOPLEFT', req, 'TOPRIGHT', 4, 0)
    reqText:SetPoint('RIGHT', frame, 'RIGHT', -28, 0)
    frame.RequirementText = reqText

    local cost = frame:CreateFontString('DragonflightUIProfession' .. 'CostLabel', 'BACKGROUND',
                                        'GameFontHighlightSmall')
    cost:SetPoint('TOPLEFT', req, 'BOTTOMLEFT', 0, -4)
    cost:SetText(COSTS_LABEL)
    frame.CostLabel = cost

    local costText = frame:CreateFontString('DragonflightUIProfession' .. 'CostText', 'BACKGROUND',
                                            'GameFontHighlightSmall')
    costText:SetSize(250, 9.9)
    costText:SetJustifyH("LEFT");
    costText:SetPoint('LEFT', cost, 'RIGHT', 4, 0)
    frame.CostText = costText

    local cooldown = frame:CreateFontString('DragonflightUIProfession' .. 'SkillCooldown', 'BACKGROUND',
                                            'GameFontRedSmall')
    cooldown:SetPoint('TOPLEFT', req, 'BOTTOMLEFT', 0, 0)
    frame.SkillCooldown = cooldown

    local descr = frame:CreateFontString('DragonflightUIProfession' .. 'SkillDescription', 'BACKGROUND',
                                         'GameFontHighlightSmall')
    descr:SetPoint('TOPLEFT', icon, 'BOTTOMLEFT', -1, -12)
    descr:SetPoint('RIGHT', frame, 'RIGHT', -28, 0)
    descr:SetText('*descr*')
    descr:SetJustifyH('LEFT')
    frame.SkillDescription = descr

    local extra = CreateFrame("Frame", 'DragonflightUIProfessionFrameExtraDataFrame', self)
    extra:SetPoint('TOPLEFT', icon, 'BOTTOMLEFT', -1, -12)
    extra:SetPoint('RIGHT', frame, 'RIGHT', -28, 0)
    extra:SetHeight(1)
    frame.ExtraDataFrame = extra

    local reagentLabel = frame:CreateFontString('DragonflightUIProfession' .. 'ReagentLabel', 'BACKGROUND',
                                                'GameFontNormalSmall')
    reagentLabel:SetPoint('TOPLEFT', extra, 'BOTTOMLEFT', -1, 0)
    reagentLabel:SetText(SPELL_REAGENTS)
    frame.RegentLabel = reagentLabel

    frame.ReagentTable = {}
    for i = 1, MAX_TRADE_SKILL_REAGENTS do
        local reagent = CreateFrame('BUTTON', 'DragonflightUIProfession' .. 'Reagent' .. i, frame, 'QuestItemTemplate',
                                    i)
        if i <= 6 then
            reagent:SetPoint('TOPLEFT', reagentLabel, 'TOPLEFT', 1, -23 - (i - 1) * 45)
        else
            reagent:SetPoint('TOPLEFT', frame.ReagentTable[i - 2], 'TOPRIGHT', 6, 0)
        end
        reagent:SetSize(180, 50)
        frame.ReagentTable[i] = reagent

        local reagentIcon = _G[reagent:GetName() .. 'IconTexture']
        reagentIcon:ClearAllPoints()
        reagentIcon:SetPoint('LEFT', reagent, 'LEFT', 0, 0)

        local overlay = DragonflightUIItemColorMixin:AddOverlayToFrame(reagent)
        overlay:SetPoint('TOPLEFT', reagentIcon, 'TOPLEFT', 0, 0)
        overlay:SetPoint('BOTTOMRIGHT', reagentIcon, 'BOTTOMRIGHT', 0, 0)

        local reagentCountText = _G[reagent:GetName() .. "Count"];
        reagentCountText:Hide()

        local reagentNameText = _G[reagent:GetName() .. 'Name']
        reagentNameText:ClearAllPoints()
        reagentNameText:SetPoint('LEFT', reagent, 'LEFT', 46, 0)
        reagentNameText:SetSize(142, 36)
        reagentNameText:SetJustifyH("LEFT");
        reagentNameText:SetText('*Reagent' .. i .. '*')

        local reagentNameFrame = _G[reagent:GetName() .. 'NameFrame']
        reagentNameFrame:Hide()

        reagent.hasItem = 1;
        reagent:SetScript('OnLeave', function()
            GameTooltip:Hide();
            ResetCursor();
        end)
    end
end

function DFProfessionMixin:SetupDropdown()
    local drop = self.RecipeList.FilterButton
    drop.Text:SetPoint('TOP', drop, 'TOP', 0, 0)

    local generator = function(dropdown, rootDescription)
        rootDescription:SetTag("MENU_PROFESSIONS_FILTER");

        do
            local function IsSelected()
                return DFFilter['DFFilter_HasSkillUp'].enabled;
            end

            local function SetChecked(checked)
                if checked then
                    DFFilter['DFFilter_HasSkillUp'].enabled = true
                    DFFilter['DFFilter_HasSkillUp'].filter = {easy = true, medium = true, optimal = true}
                else
                    DFFilter['DFFilter_HasSkillUp'].enabled = false
                    DFFilter['DFFilter_HasSkillUp'].filter = DFFilter['DFFilter_HasSkillUp'].filterDefault
                end
            end

            rootDescription:CreateCheckbox(L["ProfessionFrameHasSkillUp"], IsSelected, function()
                SetChecked(not DFFilter['DFFilter_HasSkillUp'].enabled)
                self:UpdateRecipeList()
                self:CheckFilter()
            end);
        end

        do
            local function IsSelected()
                return DFFilter['DFFilter_HaveMaterials'].enabled;
            end

            local function SetChecked(checked)
                if checked then
                    DFFilter['DFFilter_HaveMaterials'].enabled = true
                else
                    DFFilter['DFFilter_HaveMaterials'].enabled = false
                end
            end

            rootDescription:CreateCheckbox(L["ProfessionFrameHasMaterials"], IsSelected, function()
                SetChecked(not DFFilter['DFFilter_HaveMaterials'].enabled)
                self:UpdateRecipeList()
                self:CheckFilter()
            end);
        end

        rootDescription:CreateDivider();

        do
            local subClasses;
            local IsSelected;
            local SetSelected;

            if self.TradeSkillOpen then
                subClasses = {GetTradeSkillSubClasses()}
                local dropDown = TradeSkillSubClassDropDown or TradeSkillSubClassDropdown

                function IsSelected(k)
                    local allCheckedSub = GetTradeSkillSubClassFilter(0);
                    if k == 0 then
                        local selectedIDSub = UIDropDownMenu_GetSelectedID(dropDown) or 1;
                        return allCheckedSub and (selectedIDSub == nil or selectedIDSub == 1)
                    else
                        return GetTradeSkillSubClassFilter(k);
                    end
                end

                function SetSelected(k)
                    local cur = IsSelected(k)
                    if k == 0 then
                        SetTradeSkillSubClassFilter(0, 1, 1);
                        UIDropDownMenu_SetSelectedID(dropDown, 1);
                    else
                        if cur then
                            SetTradeSkillSubClassFilter(k, 0, 1);
                        else
                            SetTradeSkillSubClassFilter(k, 1, 1);
                        end
                    end
                end
            elseif self.CraftOpen then
                --
            end

            if subClasses and #subClasses > 1 then
                local subclassMenu = rootDescription:CreateButton(TRADESKILL_FILTER_SUBCLASS);
                for k, v in ipairs(subClasses) do
                    subclassMenu:CreateCheckbox(v, function()
                        return IsSelected(k)
                    end, function()
                        SetSelected(k)
                        self:UpdateRecipeList()
                        self:CheckFilter()
                    end);
                end
            end
        end

        do
            local invSlots;
            local IsSelected;
            local SetSelected;

            if self.TradeSkillOpen then
                invSlots = {GetTradeSkillInvSlots()}
                local dropDown = TradeSkillInvSlotDropDown or TradeSkillInvSlotDropdown

                function IsSelected(k)
                    local allCheckedInv = GetTradeSkillInvSlotFilter(0);
                    if k == 0 then
                        local selectedIDInv = UIDropDownMenu_GetSelectedID(dropDown) or 1;
                        return allCheckedInv and (selectedIDInv == nil or selectedIDInv == 1)
                    else
                        return GetTradeSkillInvSlotFilter(k);
                    end
                end

                function SetSelected(k)
                    local cur = IsSelected(k)
                    if k == 0 then
                        SetTradeSkillInvSlotFilter(0, 1, 1);
                        UIDropDownMenu_SetSelectedID(dropDown, 1);
                    else
                        if cur then
                            SetTradeSkillInvSlotFilter(k, 0, 1);
                        else
                            SetTradeSkillInvSlotFilter(k, 1, 1);
                        end
                    end
                end
            elseif self.CraftOpen then
                --
            end

            if invSlots and #invSlots > 1 then
                local invSlotsMenu = rootDescription:CreateButton(TRADESKILL_FILTER_SLOT);
                for k, v in ipairs(invSlots) do
                    invSlotsMenu:CreateCheckbox(v, function()
                        return IsSelected(k)
                    end, function()
                        SetSelected(k)
                        self:UpdateRecipeList()
                        self:CheckFilter()
                    end);
                end
            end
        end

        if not DF.API.Version.IsClassic then
            self:SetupDropdownExpansions(rootDescription)
        end
    end

    drop:SetupMenu(generator)
end

function DFProfessionMixin:SetupDropdownMists()
    local drop = self.RecipeList.FilterButton
    drop.Text:SetPoint('TOP', drop, 'TOP', 0, 0)

    local generator = function(dropdown, rootDescription)
        rootDescription:SetTag("MENU_PROFESSIONS_FILTER");

        do
            local function IsSelected()
                return DFFilter['DFFilter_HasSkillUp'].enabled;
            end

            local function SetChecked(checked)
                if checked then
                    DFFilter['DFFilter_HasSkillUp'].enabled = true
                    DFFilter['DFFilter_HasSkillUp'].filter = {easy = true, medium = true, optimal = true}
                else
                    DFFilter['DFFilter_HasSkillUp'].enabled = false
                    DFFilter['DFFilter_HasSkillUp'].filter = DFFilter['DFFilter_HasSkillUp'].filterDefault
                end
            end

            rootDescription:CreateCheckbox(L["ProfessionFrameHasSkillUp"], IsSelected, function()
                SetChecked(not DFFilter['DFFilter_HasSkillUp'].enabled)
                self:UpdateRecipeList()
                self:CheckFilter()
            end);
        end

        do
            local function IsSelected()
                return DFFilter['DFFilter_HaveMaterials'].enabled;
            end

            local function SetChecked(checked)
                if checked then
                    DFFilter['DFFilter_HaveMaterials'].enabled = true
                else
                    DFFilter['DFFilter_HaveMaterials'].enabled = false
                end
            end

            rootDescription:CreateCheckbox(L["ProfessionFrameHasMaterials"], IsSelected, function()
                SetChecked(not DFFilter['DFFilter_HaveMaterials'].enabled)
                self:UpdateRecipeList()
                self:CheckFilter()
            end);
        end

        rootDescription:CreateDivider();

        do
            local subClasses;
            local IsSelected;
            local SetSelected;

            if self.TradeSkillOpen then
                subClasses = {GetTradeSkillSubClasses()}

                function IsSelected(k)
                    local allCheckedSub = GetTradeSkillSubClassFilter(0);
                    if k == 0 then
                        return allCheckedSub
                    else
                        return GetTradeSkillSubClassFilter(k);
                    end
                end

                function SetSelected(k)
                    local cur = IsSelected(k)
                    if k == 0 then
                        SetTradeSkillSubClassFilter(0, 1, 1);
                    else
                        if cur then
                            SetTradeSkillSubClassFilter(k, 0, 1);
                        else
                            SetTradeSkillSubClassFilter(k, 1, 1);
                        end
                    end
                end
            elseif self.CraftOpen then
                --
            end

            if subClasses and #subClasses > 1 then
                local subclassMenu = rootDescription:CreateButton(TRADESKILL_FILTER_SUBCLASS);
                for k, v in ipairs(subClasses) do
                    subclassMenu:CreateCheckbox(v, function()
                        return IsSelected(k)
                    end, function()
                        SetSelected(k)
                        self:UpdateRecipeList()
                        self:CheckFilter()
                    end);
                end
            end
        end

        do
            local invSlots;
            local IsSelected;
            local SetSelected;

            if self.TradeSkillOpen then
                invSlots = {GetTradeSkillInvSlots()}

                function IsSelected(k)
                    local allCheckedInv = GetTradeSkillInvSlotFilter(0);
                    if k == 0 then
                        return allCheckedInv
                    else
                        return GetTradeSkillInvSlotFilter(k);
                    end
                end

                function SetSelected(k)
                    local cur = IsSelected(k)
                    if k == 0 then
                        SetTradeSkillInvSlotFilter(0, 1, 1);
                    else
                        if cur then
                            SetTradeSkillInvSlotFilter(k, 0, 1);
                        else
                            SetTradeSkillInvSlotFilter(k, 1, 1);
                        end
                    end
                end
            elseif self.CraftOpen then
                --
            end

            if invSlots and #invSlots > 1 then
                local invSlotsMenu = rootDescription:CreateButton(TRADESKILL_FILTER_SLOT);
                for k, v in ipairs(invSlots) do
                    invSlotsMenu:CreateCheckbox(v, function()
                        return IsSelected(k)
                    end, function()
                        SetSelected(k)
                        self:UpdateRecipeList()
                        self:CheckFilter()
                    end);
                end
            end
        end

        if not DF.API.Version.IsClassic then
            self:SetupDropdownExpansions(rootDescription)
        end
    end

    drop:SetupMenu(generator)
end

function DFProfessionMixin:SetupDropdownExpansions(rootDescription)
    rootDescription:CreateDivider();
    rootDescription:CreateTitle(EXPANSION_FILTER_TEXT);

    local maxExp = 0;
    if DF.API.Version.IsTBC then
        maxExp = 1;
    elseif DF.API.Version.IsWotlk then
        maxExp = 2;
    elseif DF.API.Version.IsCata then
        maxExp = 3;
    elseif DF.API.Version.IsMoP then
        maxExp = 4;
    end

    for i = 0, maxExp do
        local function IsSelected()
            return (DFFilter['DFFilter_Expansion'].filter)[i];
        end

        local function SetChecked(checked)
            (DFFilter['DFFilter_Expansion'].filter)[i] = checked;
        end

        rootDescription:CreateCheckbox(_G["EXPANSION_NAME" .. i], IsSelected, function()
            SetChecked(not (DFFilter['DFFilter_Expansion'].filter)[i])
            self:UpdateRecipeList()
            self:CheckFilter()
        end);
    end
end

function DFProfessionMixin:Refresh(force)
    self:UpdateProfessionData()
    self:SetCurrentProfession()

    if InCombatLockdown() then
        self.ShouldUpdate = true
    else
        self.ShouldUpdate = false
        self:UpdateTabs()
    end

    if not self.SelectedProfession then
        return
    end

    self:UpdateHeader()
    self:UpdateRecipeList()
    self:CheckFilter()
end

function DFProfessionMixin:SetCurrentProfession()
    local nameLoc;

    if self.TradeSkillOpen then
        nameLoc, _, _ = GetTradeSkillLine();
    elseif self.CraftOpen then
        nameLoc, _, _ = GetCraftDisplaySkillLine();

        if not nameLoc then
            nameLoc = DragonflightUILocalizationData.DF_PROFESSIONS_BEAST
        end
    end

    if nameLoc == 'Runenschmieden' then nameLoc = 'Runen schmieden'; end

    for k, v in pairs(self.ProfessionTable) do
        if v.nameLoc == nameLoc then
            self.SelectedProfession = k;
            return k
        end
    end

    local isLink, playerName = IsTradeSkillLinked()
    if (DF.Cata or DF.API.Version.IsWotlk) and isLink and playerName and playerName ~= '' then
        local tradeskillName, currentLevel, maxLevel, skillLineModifier = GetTradeSkillLine()
        local skillID = DragonflightUILocalizationData:GetSkillIDFromProfessionName(tradeskillName)

        if skillID then
            local profDataTable = self.ProfessionDataTable[skillID]

            self.ProfessionTable['linked'] = {
                nameLoc = tradeskillName,
                icon = profDataTable.icon,
                skillID = skillID,
                skill = currentLevel,
                maxSkill = maxLevel,
                profData = profDataTable
            }

            self.SelectedProfession = 'linked'
            return 'linked'
        end
    end

    self.ProfessionTable['linked'] = nil;
    self.SelectedProfession = nil;
    return nil;
end

function DFProfessionMixin:UpdateHeader()
    local prof = self.ProfessionTable[self.SelectedProfession]
    if not prof or not prof.profData then return end

    self.Icon:SetTexture(prof.profData.icon)
    self.Icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    local isLink, playerName = IsTradeSkillLinked()
    if isLink then
        self.NineSlice.Text:SetText(prof.nameLoc .. ' (' .. (playerName or '') .. ')')
        self.LinkButton:Hide()
    else
        self.NineSlice.Text:SetText(prof.nameLoc)

        if DF.Era or DF.API.Version.IsTBC then
            self.LinkButton:Hide()
        else
            self.LinkButton:Show()
        end
    end

    self.SchematicForm.Background:SetTexture(base .. prof.profData.tex)

    local newStatusTexture = base .. prof.profData.bar
    if newStatusTexture ~= self.RankFrame.DFStatusTexture then
        self.RankFrameBar:SetStatusBarTexture(base .. prof.profData.bar)
        self.RankFrame.DFStatusTexture = base .. prof.profData.bar
    end

    self.RankFrame:UpdateRankFrame(prof.skill, 0, prof.maxSkill)
end

function DFProfessionMixin:GetRecipeQuality(index)
    if not index or index == 0 then return 1 end

    local tooltip = self.ScanningTooltip

    if self.TradeSkillOpen then
        tooltip:SetTradeSkillItem(index)
    elseif self.CraftOpen then
        tooltip:SetCraftSpell(index)
    else
        return 1
    end

    local name, link = tooltip:GetItem()
    if not link then return 1 end

    local itemString = string.match(link, "item[%-?%d:]+")
    if not itemString then return 1; end

    local _, itemIdStr = strsplit(":", itemString)
    local itemId = tonumber(itemIdStr)
    if not itemId or itemId == "" then return 1; end

    local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc,
          itemTexture, itemSellPrice, classID, subclassID, bindType, expansionID, setID, isCraftingReagent =
        C_Item.GetItemInfo(link)
    if not itemLevel or not itemId then return 1 end

    return itemRarity, itemId
end

function DFProfessionMixin:IsRecipeSpell(index)
    if not index or index == 0 then return 1 end

    local tooltip = self.ScanningTooltip

    if self.TradeSkillOpen then
        tooltip:SetTradeSkillItem(index)
        local _, spellID = tooltip:GetSpell()
        return spellID ~= nil
    else
        return false
    end
end

function DFProfessionMixin:GetRecipeExpansion(index)
    if not index or index == 0 then return -1 end

    if self.TradeSkillOpen then
        local numSkills = GetNumTradeSkills()
        if index > numSkills then return -1; end

        local info;
        do
            local itemLink = GetTradeSkillItemLink(index);
            if itemLink then
                local itemID = tonumber(itemLink:match("item:(%d+)")) or nil;
                if not itemID then return -1 end
                info = LibTradeSkillRecipes:GetInfoByItemId(itemID)
            else
                local tooltip = self.ScanningTooltip
                local retOK, ret1 = pcall(function()
                    tooltip:SetTradeSkillItem(index)
                end);
                if not retOK then return -1 end
                local _, spellID = tooltip:GetSpell()
                if spellID then
                    info = LibTradeSkillRecipes:GetInfoBySpellId(spellID)
                end
            end
        end

        if not info then return -1 end

        local expansion;
        if info[1] then
            expansion = info[1].expansionId;
        elseif info.expansionId then
            expansion = info.expansionId;
        end

        if type(expansion) ~= 'number' then expansion = -1 end
        return expansion
    elseif self.CraftOpen then
        local tooltip = self.ScanningTooltip
        tooltip:SetCraftSpell(index)

        local _, spellID = tooltip:GetSpell()
        if spellID then
            local info = LibTradeSkillRecipes:GetInfoBySpellId(spellID)
            if info and info[1] then
                local expansion = info[1].expansionId;
                if type(expansion) ~= 'number' then expansion = -1 end
                return expansion;
            end
        end
    end

    return -1;
end

function DFProfessionMixin:UpdateRecipe(id)
    local frame = self.SchematicForm

    if self.TradeSkillOpen then
        local skillName, skillType, numAvailable, isExpanded, altVerb, numSkillUps, indentLevel, showProgressBar,
              currentRank, maxRank, startingRank = GetTradeSkillInfo(id)

        frame.SkillName:SetText(skillName)
        frame.SkillName:SetWidth(frame.SkillName:GetUnboundedStringWidth())

        if not DF.API.Version.IsClassic then
            local expansion = self:GetRecipeExpansion(id);
            if expansion == -1 then
                frame.ExpansionName:Hide()
            else
                frame.ExpansionName:Show()
                local txt = string.format(L["ProfessionExpansionFormat"], _G["EXPANSION_NAME" .. expansion])
                frame.ExpansionName:SetText(txt)
            end
        end

        local quality = self:GetRecipeQuality(id)
        local r, g, b;
        if quality == 1 then
            if self:IsRecipeSpell(id) then
                r, g, b = GameFontNormal:GetTextColor()
            else
                r, g, b = C_Item.GetItemQualityColor(quality)
            end
        else
            r, g, b = C_Item.GetItemQualityColor(quality)
        end
        frame.SkillName:SetTextColor(r, g, b)

        DragonflightUIItemColorMixin:UpdateOverlayQuality(frame.SkillIcon, quality)

        if (GetTradeSkillCooldown(id)) then
            frame.SkillCooldown:SetText(COOLDOWN_REMAINING .. " " .. SecondsToTime(GetTradeSkillCooldown(id)));
        else
            frame.SkillCooldown:SetText("");
        end

        local icon = GetTradeSkillIcon(id);
        if (icon) then
            frame.SkillIcon:SetNormalTexture(icon);
        else
            frame.SkillIcon:ClearNormalTexture();
        end

        local minMade, maxMade = GetTradeSkillNumMade(id);
        if (maxMade and maxMade > 1) then
            if (minMade == maxMade) then
                frame.SkillIconCount:SetText(minMade);
            else
                frame.SkillIconCount:SetText(minMade .. "-" .. maxMade);
            end
            if (frame.SkillIconCount:GetWidth() > 39) then
                frame.SkillIconCount:SetText("~" .. floor((minMade + maxMade) / 2));
            end
        else
            frame.SkillIconCount:SetText("");
        end

        local creatable = true;
        local numReagents = GetTradeSkillNumReagents(id);

        if (numReagents and numReagents > 0) then
            frame.RegentLabel:Show();
        else
            frame.RegentLabel:Hide();
        end

        for i = 1, (numReagents or 0) do
            local reagentName, reagentTexture, reagentCount, playerReagentCount = GetTradeSkillReagentInfo(id, i);

            local reagent = frame.ReagentTable[i]
            local name = _G[reagent:GetName() .. 'Name']
            local count = _G[reagent:GetName() .. "Count"];

            if (not reagentName or not reagentTexture) then
                reagent:Hide();
            else
                reagent:Show();
                SetItemButtonTexture(reagent, reagentTexture);
                name:SetText(reagentName);
                if (playerReagentCount < reagentCount) then
                    SetItemButtonTextureVertexColor(reagent, 0.5, 0.5, 0.5);
                    name:SetTextColor(GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b);
                    creatable = false;
                else
                    SetItemButtonTextureVertexColor(reagent, 1.0, 1.0, 1.0);
                    name:SetTextColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
                end
                if (playerReagentCount >= 100) then playerReagentCount = "*"; end
                count:SetText(playerReagentCount .. " /" .. reagentCount);

                local newText = playerReagentCount .. "/" .. reagentCount .. ' ' .. reagentName
                name:SetText(newText)

                local link = GetTradeSkillReagentItemLink(id, i)
                if link then
                    local quality, _, _, _, _, _, _, _, _, classId = select(3, C_Item.GetItemInfo(link));
                    if (classId == 12) then quality = 0; end
                    DragonflightUIItemColorMixin:UpdateOverlayQuality(reagent, quality)
                end

                local function UpdateTooltip(self)
                    GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT");
                    GameTooltip:SetTradeSkillItem(id, i);
                    CursorUpdate(self);
                end
                reagent:SetScript('OnEnter', UpdateTooltip)

                local function OnClick(self)
                    HandleModifiedItemClick(GetTradeSkillReagentItemLink(id, i));
                end
                reagent:SetScript('OnClick', OnClick)
            end
        end

        for i = (numReagents or 0) + 1, MAX_TRADE_SKILL_REAGENTS do
            local reagent = frame.ReagentTable[i]
            reagent:SetScript('OnEnter', nil)
            reagent:SetScript('OnClick', nil)
            reagent:Hide()
        end

        local spellFocus = BuildColoredListString(GetTradeSkillTools(id));
        if (spellFocus) then
            frame.RequirementLabel:Show();
            frame.RequirementText:SetText(spellFocus);
        else
            frame.RequirementLabel:Hide();
            frame.RequirementText:SetText("");
        end
        frame.CostLabel:Hide()
        frame.CostText:SetText('')

        self.CreateButton:SetText(altVerb or CREATE_PROFESSION);

        if (creatable) then
            self.CreateButton:Enable();
            self.CreateAllButton:Enable();
        else
            self.CreateButton:Disable();
            self.CreateAllButton:Disable();
        end
        self.CreateButton:Show();

        self.InputBox:SetNumber(GetTradeskillRepeatCount() or 1);

        if (altVerb) then
            self.CreateAllButton:Hide();
            self.DecrementButton:Hide();
            self.InputBox:Hide();
            self.Incrementbutton:Hide();
        else
            self.CreateAllButton:Show();
            self.DecrementButton:Show();
            self.InputBox:Show();
            self.Incrementbutton:Show();
        end

        if (GetTradeSkillDescription(id)) then
            frame.SkillDescription:SetText(GetTradeSkillDescription(id))
            frame.ExtraDataFrame:SetPoint("TOPLEFT", frame.SkillDescription, "BOTTOMLEFT", 0, -10);
        else
            frame.SkillDescription:SetText(" ");
            frame.ExtraDataFrame:SetPoint("TOPLEFT", frame.SkillDescription, "TOPLEFT", 0, 0);
        end

        frame.SkillDescription:Show();

        local function UpdateTooltip(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT");
            GameTooltip:SetTradeSkillItem(id);
            CursorUpdate(self);
        end
        frame.SkillIcon:SetScript('OnEnter', UpdateTooltip)

        frame.SkillIcon:SetScript('OnClick', function(self)
            HandleModifiedItemClick(GetTradeSkillItemLink(id));
        end)

        self.CreateButton:SetScript('OnClick', function()
            DoTradeSkill(id, self.InputBox:GetNumber());
            self.InputBox:ClearFocus();
        end)

        self.CreateAllButton:SetScript('OnClick', function()
            local _, _, numAvailable, _, _, _ = GetTradeSkillInfo(id);
            self.InputBox:SetNumber(numAvailable);
            DoTradeSkill(id, numAvailable);
            self.InputBox:ClearFocus();
        end)
    elseif self.CraftOpen then
        local craftName, craftSubSpellName, craftType, numAvailable, isExpanded, trainingPointCost, requiredLevel =
            GetCraftInfo(id);

        if craftSubSpellName then
            frame.SkillName:SetText(craftName .. ' (' .. craftSubSpellName .. ')')
        else
            frame.SkillName:SetText(craftName)
        end
        frame.SkillName:SetWidth(frame.SkillName:GetUnboundedStringWidth())

        local quality = self:GetRecipeQuality(id)
        local r, g, b, hex = C_Item.GetItemQualityColor(quality)
        frame.SkillName:SetTextColor(r, g, b)

        DragonflightUIItemColorMixin:UpdateOverlayQuality(frame.SkillIcon, quality)

        if (GetCraftCooldown(id)) then
            frame.SkillCooldown:SetText(COOLDOWN_REMAINING .. " " .. SecondsToTime(GetCraftCooldown(id)));
        else
            frame.SkillCooldown:SetText("");
        end

        local icon = GetCraftIcon(id);
        if (icon) then
            frame.SkillIcon:SetNormalTexture(icon);
        else
            frame.SkillIcon:ClearNormalTexture();
        end

        local minMade, maxMade = GetCraftNumMade(id);
        if (maxMade and maxMade > 1) then
            if (minMade == maxMade) then
                frame.SkillIconCount:SetText(minMade);
            else
                frame.SkillIconCount:SetText(minMade .. "-" .. maxMade);
            end
            if (frame.SkillIconCount:GetWidth() > 39) then
                frame.SkillIconCount:SetText("~" .. floor((minMade + maxMade) / 2));
            end
        else
            frame.SkillIconCount:SetText("");
        end

        local creatable = true;
        local numReagents = GetCraftNumReagents(id);

        if (numReagents and numReagents > 0) then
            frame.RegentLabel:Show();
        else
            frame.RegentLabel:Hide();
        end

        for i = 1, (numReagents or 0) do
            local reagentName, reagentTexture, reagentCount, playerReagentCount = GetCraftReagentInfo(id, i);

            local reagent = frame.ReagentTable[i]
            local name = _G[reagent:GetName() .. 'Name']
            local count = _G[reagent:GetName() .. "Count"];

            if (not reagentName or not reagentTexture) then
                reagent:Hide();
            else
                reagent:Show();
                SetItemButtonTexture(reagent, reagentTexture);
                name:SetText(reagentName);
                if (playerReagentCount < reagentCount) then
                    SetItemButtonTextureVertexColor(reagent, 0.5, 0.5, 0.5);
                    name:SetTextColor(GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b);
                    creatable = false;
                else
                    SetItemButtonTextureVertexColor(reagent, 1.0, 1.0, 1.0);
                    name:SetTextColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
                end
                if (playerReagentCount >= 100) then playerReagentCount = "*"; end
                count:SetText(playerReagentCount .. " /" .. reagentCount);

                local newText = playerReagentCount .. "/" .. reagentCount .. ' ' .. reagentName
                name:SetText(newText)

                local link = GetCraftReagentItemLink(id, i)
                if link then
                    local quality, _, _, _, _, _, _, _, _, classId = select(3, C_Item.GetItemInfo(link));
                    if (classId == 12) then quality = 0; end
                    DragonflightUIItemColorMixin:UpdateOverlayQuality(reagent, quality)
                end

                local function UpdateTooltip(self)
                    GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT");
                    GameTooltip:SetCraftItem(id, self:GetID());
                    CursorUpdate(self);
                end
                reagent:SetScript('OnEnter', UpdateTooltip)

                local function OnClick(self)
                    HandleModifiedItemClick(GetCraftReagentItemLink(id, self:GetID()));
                end
                reagent:SetScript('OnClick', OnClick)
            end
        end

        for i = (numReagents or 0) + 1, MAX_TRADE_SKILL_REAGENTS do
            local reagent = frame.ReagentTable[i]
            reagent:Hide()
        end

        local spellFocus = BuildColoredListString(GetCraftSpellFocus(id));
        if (spellFocus) then
            frame.RequirementLabel:Show();
            frame.RequirementText:SetText(spellFocus);
        elseif requiredLevel and requiredLevel > 0 then
            frame.RequirementLabel:Show();
            if (UnitLevel("pet") >= requiredLevel) then
                frame.RequirementText:SetText(format(TRAINER_REQ_LEVEL, requiredLevel));
            else
                frame.RequirementText:SetText(format(TRAINER_REQ_LEVEL, requiredLevel));
            end
        else
            frame.RequirementLabel:Hide();
            frame.RequirementText:SetText("");
        end

        if (trainingPointCost and trainingPointCost > 0) then
            local totalPoints, spent = GetPetTrainingPoints();
            local usablePoints = totalPoints - spent;
            if (usablePoints >= trainingPointCost) then
                frame.CostText:SetText(trainingPointCost .. " " .. TRAINING_POINTS_LABEL);
            else
                frame.CostText:SetText(RED_FONT_COLOR_CODE .. trainingPointCost .. FONT_COLOR_CODE_CLOSE .. " " ..
                                           TRAINING_POINTS_LABEL);
            end

            frame.CostLabel:Show()
            frame.CostText:Show();
        else
            frame.CostText:Hide();
        end

        self.CreateButton:SetText(getglobal(GetCraftButtonToken()));

        if (craftType == "used") then creatable = false; end

        if (creatable) then
            self.CreateButton:Enable();
        else
            self.CreateButton:Disable();
        end

        self.CreateAllButton:Hide();
        self.DecrementButton:Hide();
        self.InputBox:Hide();
        self.Incrementbutton:Hide();

        self.CreateButton:Hide();
        if CraftCreateButton then
            CraftCreateButton:SetParent(self)
            CraftCreateButton:ClearAllPoints()
            CraftCreateButton:SetPoint('BOTTOMRIGHT', self, 'BOTTOMRIGHT', -9, 7)
            CraftCreateButton:SetFrameLevel(8)
        end

        if (GetCraftDescription(id)) then
            frame.SkillDescription:SetText(GetCraftDescription(id))
            frame.ExtraDataFrame:SetPoint("TOPLEFT", frame.SkillDescription, "BOTTOMLEFT", 0, -10);
        else
            frame.SkillDescription:SetText(" ");
            frame.ExtraDataFrame:SetPoint("TOPLEFT", frame.SkillDescription, "TOPLEFT", 0, 0);
        end

        frame.SkillDescription:Show();

        local function UpdateTooltip(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT");
            GameTooltip:SetCraftSpell(id);
            CursorUpdate(self);
        end
        frame.SkillIcon:SetScript('OnEnter', UpdateTooltip)

        frame.SkillIcon:SetScript('OnClick', function(self)
            HandleModifiedItemClick(GetCraftItemLink(id));
        end)

        self.CreateButton:SetScript('OnClick', function()
            DoCraft(id);
        end)
    end
    self:UpdateTrainingPoints()
    self.FavoriteButton:UpdateFavoriteState()
end

function DFProfessionMixin:ResetFilter()
    DFFilter['DFFilter_HasSkillUp'].enabled = false
    DFFilter['DFFilter_HaveMaterials'].enabled = false

    if DFFilter['DFFilter_Expansion'] then
        local filter = DFFilter['DFFilter_Expansion'].filter;
        local filterDefault = DFFilter['DFFilter_Expansion'].filterDefault;
        for k, v in pairs(filterDefault) do
            filter[k] = true;
        end
    end

    SetTradeSkillSubClassFilter(0, true, 1)
    SetTradeSkillInvSlotFilter(0, true, 1)

    self:UpdateRecipeList()
    self:CheckFilter()
end

function DFProfessionMixin:AreFilterDefault()
    local allCheckedSub = GetTradeSkillSubClassFilter(0);
    if not allCheckedSub then return false end
    local allCheckedInv = GetTradeSkillInvSlotFilter(0);
    if not allCheckedInv then return false end

    if DFFilter['DFFilter_HasSkillUp'].enabled then return false end
    if DFFilter['DFFilter_HaveMaterials'].enabled then return false end

    if DFFilter['DFFilter_Expansion'] then
        for k, v in pairs(DFFilter['DFFilter_Expansion'].filter) do
            if v == false then
                return false;
            end
        end
    end

    return true
end

function DFProfessionMixin:CheckFilter()
    local def = self:AreFilterDefault()
    self.RecipeList.ResetButton:SetShown(not def)
end

function DFProfessionMixin:UpdateRecipeList()
    local selectedKey = self.ProfessionTable[self.SelectedProfession]
    local recipeList = self.RecipeList

    if self.TradeSkillOpen then
        local numSkills = GetNumTradeSkills()
        local index = recipeList.selectedSkill
        index = GetTradeSkillSelectionIndex()
        do
            local skillName, skillType, numAvailable, isExpanded, altVerb, numSkillUps = GetTradeSkillInfo(index);
            if skillType == 'header' then index = GetFirstTradeSkill() end
        end
        if index > numSkills then
            index = GetFirstTradeSkill()
            TradeSkillFrame_SetSelection(index)
        end
        local changed = recipeList.selectedSkill ~= index
        recipeList.selectedSkill = index

        local oldScroll = recipeList.ScrollBox:GetScrollPercentage()

        recipeList:UpdateRecipeListTradeskill()

        recipeList:SelectRecipe(index, true)
        self.FavoriteButton:UpdateFavoriteState()

        if (not changed) and (not force) then
            recipeList.ScrollBox:SetScrollPercentage(oldScroll, ScrollBoxConstants.NoScrollInterpolation)
        end
    elseif self.CraftOpen then
        local numSkills = GetNumCrafts()
        local index = recipeList.selectedSkill
        index = GetCraftSelectionIndex()
        if index > numSkills then index = 2 end
        local changed = recipeList.selectedSkill ~= index
        recipeList.selectedSkill = index

        local oldScroll = recipeList.ScrollBox:GetScrollPercentage()

        recipeList:UpdateRecipeListCraft()

        recipeList:SelectRecipe(index, true)
        self.FavoriteButton:UpdateFavoriteState()

        if (not changed) and (not force) then
            recipeList.ScrollBox:SetScrollPercentage(oldScroll, ScrollBoxConstants.NoScrollInterpolation)
        end
    else
        recipeList:ClearList()
    end
end

DFProfessionFrameSearchBoxMixin = {}

function DFProfessionFrameSearchBoxMixin:OnLoad()
end

function DFProfessionFrameSearchBoxMixin:OnHide()
    self.clearButton:Click();
    SearchBoxTemplate_OnTextChanged(self);
end

function DFProfessionFrameSearchBoxMixin:OnTextChanged()
    SearchBoxTemplate_OnTextChanged(self);
    self:GetParent():GetParent():OnEvent('TRADE_SKILL_FILTER_UPDATE')
end

function DFProfessionFrameSearchBoxMixin:OnChar()
    local MIN_REPEAT_CHARACTERS = 4;
    local searchString = self:GetText();
    if (string.len(searchString) >= MIN_REPEAT_CHARACTERS) then
        local repeatChar = true;
        for i = 1, MIN_REPEAT_CHARACTERS - 1, 1 do
            if (string.sub(searchString, (0 - i), (0 - i)) ~= string.sub(searchString, (-1 - i), (-1 - i))) then
                repeatChar = false;
                break
            end
        end
        if (repeatChar) then self:ClearFocus(); end
    end
end

DFProfessionFrameRecipeSchematicFormMixin = {}

function DFProfessionFrameRecipeSchematicFormMixin:OnLoad()
end

function DFProfessionFrameRecipeSchematicFormMixin:OnShow()
end

function DFProfessionFrameRecipeSchematicFormMixin:OnHide()
end

function DFProfessionFrameRecipeSchematicFormMixin:OnEvent()
end
