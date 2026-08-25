local addonName, addonTable = ...;
local Helper = addonTable.Helper;
local DF = LibStub('AceAddon-3.0'):GetAddon('DragonflightUI')
local L = LibStub("AceLocale-3.0"):GetLocale("DragonflightUI")

local base = 'Interface\\Addons\\DragonflightUI\\Textures\\UI\\'
local CreateColor = DFCreateColor;

local DFFilter = DFProfessionMixin.DFFilter or {}

DFProfessionFrameRecipeListMixin = CreateFromMixins(CallbackRegistryMixin);
DFProfessionFrameRecipeListMixin:GenerateCallbackEvents({"OnRecipeSelected"});

function DFProfessionFrameRecipeListMixin:OnLoad()
    CallbackRegistryMixin.OnLoad(self);

    self:SetupCollapsedDatabase()

    self.selectedSkill = 2
    self.selectedSkillTable = {}
    self.DataProvider = CreateTreeDataProvider()

    local indent = 10;
    local padLeft = 0;
    local pad = 5;
    local spacing = 1;
    local view = CreateScrollBoxListTreeListView(indent, pad, pad, padLeft, pad, spacing);
    self.View = view

    view:SetElementFactory(function(factory, node)
        local elementData = node:GetData();
        if elementData.categoryInfo then
            local function Initializer(button, node)
                button:Init(node, self);

                button:SetScript("OnClick", function(button, buttonName)
                    node:ToggleCollapsed();
                    button:SetCollapseState(node:IsCollapsed());
                    self:SetCategoryCollapsed(elementData.collapsedKey, node:IsCollapsed())
                    PlaySound(SOUNDKIT.IG_MAINMENU_OPTION)
                end);
            end
            factory("DFProfessionFrameRecipeCategoryTemplate", Initializer);
        elseif elementData.recipeInfo then
            local function Initializer(button, node)
                button:Init(node, false);

                if elementData.id == self.selectedSkill then self.selectionBehavior:Select(button) end
                local selected = self.selectionBehavior:IsElementDataSelected(node);
                button:SetSelected(selected);

                button:SetScript("OnClick", function(button, buttonName, down)
                    if buttonName == "LeftButton" then
                        if IsModifiedClick() then
                            if elementData.isTradeskill then
                                HandleModifiedItemClick(GetTradeSkillRecipeLink(elementData.id));
                            elseif elementData.isCraft then
                                HandleModifiedItemClick(GetCraftRecipeLink(elementData.id));
                            end
                        else
                            self.selectionBehavior:Select(button);
                        end
                    elseif buttonName == "RightButton" then
                    end

                    PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
                end);

            end
            factory("DFProfessionFrameRecipeTemplate", Initializer);
        elseif elementData.isDivider then
            factory("ProfessionsRecipeListDividerTemplate");
        else
            factory("Frame");
        end
    end);

    view:SetDataProvider(self.DataProvider)

    view:SetElementExtentCalculator(function(dataIndex, node)
        local elementData = node:GetData();
        local baseElementHeight = 20;
        local categoryPadding = 5;

        if elementData.recipeInfo then return baseElementHeight; end
        if elementData.categoryInfo then return baseElementHeight + categoryPadding; end
        if elementData.dividerHeight then return elementData.dividerHeight; end
        if elementData.topPadding then return 1; end
        if elementData.bottomPadding then return 10; end
    end);

    ScrollUtil.InitScrollBoxListWithScrollBar(self.ScrollBox, self.ScrollBar, view);

    local function OnSelectionChanged(o, elementData, selected)
        local button = self.ScrollBox:FindFrame(elementData);
        if button then button:SetSelected(selected); end

        if selected then
            local data = elementData:GetData();
            local newRecipeID = data.id
            local changed = data.id ~= self.selectedSkill
            if changed then
                self.selectedSkill = newRecipeID

                if self:GetParent().CraftOpen then CraftFrame_SetSelection(newRecipeID) end
                if self:GetParent().TradeSkillOpen then TradeSkillFrame_SetSelection(newRecipeID) end
                self:SelectRecipe(newRecipeID, false)
            end
        end
    end

    self.selectionBehavior = ScrollUtil.AddSelectionBehavior(self.ScrollBox);
    self.selectionBehavior:RegisterCallback(SelectionBehaviorMixin.Event.OnSelectionChanged, OnSelectionChanged, self);
end

function DFProfessionFrameRecipeListMixin:OnEvent(event, ...)
end

function DFProfessionFrameRecipeListMixin:OnShow()
end

function DFProfessionFrameRecipeListMixin:SelectRecipe(id, scrollToRecipe)
    local elementData = self.selectionBehavior:SelectElementDataByPredicate(function(node)
        local data = node:GetData();
        return data.recipeInfo and data.id == id
    end);

    if scrollToRecipe and elementData then
        self.ScrollBox:ScrollToElementData(elementData);
    end

    self:TriggerEvent('OnRecipeSelected', id)

    return elementData;
end

function DFProfessionFrameRecipeListMixin:ClearList()
    local dataProvider = CreateTreeDataProvider();
    self.ScrollBox:SetDataProvider(dataProvider);
end

function DFProfessionFrameRecipeListMixin:SetupCollapsedDatabase()
    self.db = {profile = {collapsed = {}}};
end

function DFProfessionFrameRecipeListMixin:SetCategoryCollapsed(info, collapsed)
    local db = self.db.profile
    if collapsed then
        db.collapsed[info] = true
    else
        db.collapsed[info] = nil
    end
end

function DFProfessionFrameRecipeListMixin:IsCategoryCollapsed(info)
    local db = self.db.profile
    if db.collapsed[info] then
        return true
    else
        return false
    end
end

function DFProfessionFrameRecipeListMixin:UpdateRecipeListTradeskill()
    local dataProvider = CreateTreeDataProvider();

    local parent = self:GetParent();
    local prof = parent.ProfessionTable[parent.SelectedProfession];
    if not prof then return end
    local nameLoc = prof.nameLoc;

    local filterTable = DFProfessionMixin.DFFilter or DFFilter
    local numSkills = GetNumTradeSkills()
    local headerID = 0
    local subHeader = nil;
    local subHeaderNodesTable = {}

    local headerCache = {}
    local subHeaderCache = {}

    do
        local data = {
            id = 0,
            collapsedKey = nameLoc .. '-' .. 'fav',
            categoryInfo = {name = L["ProfessionFavorites"], isExpanded = true}
        }
        headerCache[0] = dataProvider:Insert(data)
    end

    local skillName, skillType, numAvailable, isExpanded, altVerb, numSkillUps, indentLevel, showProgressBar,
          currentRank, maxRank, startingRank;

    for i = 1, numSkills do
        skillName, skillType, numAvailable, isExpanded, altVerb, numSkillUps, indentLevel, showProgressBar, currentRank, maxRank, startingRank =
            GetTradeSkillInfo(i);

        if skillType == 'header' then
            local data = {
                id = i,
                collapsedKey = nameLoc .. '-' .. (skillName or ''),
                skillType = skillType,
                categoryInfo = {name = skillName, isExpanded = isExpanded == 1}
            }
            headerCache[i] = dataProvider:Insert(data)
            headerID = i
            subHeader = nil;
        elseif skillType == 'subheader' then
            local data = {
                id = i,
                collapsedKey = nameLoc .. '-' .. (skillName or ''),
                skillType = skillType,
                categoryInfo = {
                    name = skillName,
                    isExpanded = isExpanded == 1,
                    showProgressBar = showProgressBar,
                    currentRank = currentRank,
                    maxRank = maxRank,
                    startingRank = startingRank
                }
            }
            local foundNode = headerCache[headerID];
            if foundNode then
                local newNode = foundNode:Insert(data);
                table.insert(subHeaderNodesTable, newNode)
                subHeaderCache[i] = newNode;
                subHeader = i
            end
        else
            local isFavorite = parent:IsRecipeFavorite(skillName)

            local data = {
                id = i,
                skillType = skillType,
                isFavorite = isFavorite,
                isTradeskill = true,
                recipeInfo = {
                    name = skillName,
                    skillType = skillType,
                    numAvailable = numAvailable,
                    isExpanded = isExpanded,
                    altVerb = altVerb,
                    numSkillUps = numSkillUps,
                    numSkills = numSkills
                }
            }
            if skillType == 'easy' and numSkillUps == 0 then data.recipeInfo.numSkillUps = 1; end

            if not DF.API.Version.IsClassic then
                local expansion = parent:GetRecipeExpansion(i);
                data.expansion = expansion;
            end

            local filtered = true

            for k, filter in pairs(filterTable) do
                if filter.enabled then
                    if not filter.func(data, self.SearchBox) then
                        filtered = false
                    end
                end
            end

            if filtered then
                local foundNode;
                if data.isFavorite then
                    foundNode = headerCache[0];
                elseif subHeader then
                    foundNode = subHeaderCache[subHeader];
                else
                    foundNode = headerCache[headerID];
                end

                if foundNode then
                    local newNode = foundNode:Insert(data);
                end
            end
        end
    end

    local nodes = dataProvider:GetChildrenNodes()
    local nodesToRemove = {}

    for k, sub in ipairs(subHeaderNodesTable) do
        local childNodes = sub:GetNodes();
        local numChildNodes = #childNodes
        if numChildNodes < 1 then
            local p = sub.parent
            if p then p:Remove(sub) end
        end
    end

    for k, node in ipairs(nodes) do
        local childNodes = node:GetNodes();
        local numChildNodes = #childNodes
        if numChildNodes < 1 then
            table.insert(nodesToRemove, node)
        end
    end

    for k, node in ipairs(nodesToRemove) do
        dataProvider:Remove(node)
    end

    self.ScrollBox:SetDataProvider(dataProvider);

    for k, node in ipairs(headerCache) do
        local elementData = node:GetData();
        local collapsed = self:IsCategoryCollapsed(elementData.collapsedKey)
        if not collapsed then
            node:SetCollapsed(false, false, false)
        else
            node:SetCollapsed(true, false, false)
        end
    end
end

function DFProfessionFrameRecipeListMixin:UpdateRecipeListCraft()
    local dataProvider = CreateTreeDataProvider();

    local parent = self:GetParent();
    local prof = parent.ProfessionTable[parent.SelectedProfession];
    if not prof then return end
    local nameLoc = prof.nameLoc;

    local filterTable = DFProfessionMixin.DFFilter or DFFilter
    local numSkills = GetNumCrafts()
    local headerID = 0

    do
        local data = {
            id = 0,
            collapsedKey = nameLoc .. '-' .. 'fav',
            categoryInfo = {name = 'Favorites', isExpanded = true}
        }
        dataProvider:Insert(data)
    end

    do
        local data = {
            id = 0.5,
            collapsedKey = nameLoc .. '-' .. 'recipes',
            categoryInfo = {name = 'Recipes', isExpanded = true}
        }
        dataProvider:Insert(data)
        headerID = 0.5
    end

    for i = 1, numSkills do
        local skillName, craftSubSpellName, skillType, numAvailable, isExpanded, trainingPointCost, requiredLevel =
            GetCraftInfo(i)

        if skillType == "none" then
            skillType = "easy"
        elseif skillType == "used" then
            skillType = "trivial"
        end

        local isFavorite = parent:IsRecipeFavorite(skillName)

        local data = {
            id = i,
            isFavorite = isFavorite,
            isCraft = true,
            recipeInfo = {
                name = skillName,
                craftSubSpellName = craftSubSpellName,
                skillType = skillType,
                numAvailable = numAvailable,
                isExpanded = isExpanded,
                trainingPointCost = trainingPointCost,
                requiredLevel = requiredLevel
            }
        }

        if not DF.API.Version.IsClassic then
            local expansion = parent:GetRecipeExpansion(i);
            data.expansion = expansion;
        end

        local filtered = true

        for k, filter in pairs(filterTable) do
            if filter.enabled then
                if not filter.func(data, self.SearchBox) then
                    filtered = false
                end
            end
        end

        if filtered then
            dataProvider:InsertInParentByPredicate(data, function(node)
                local nodeData = node:GetData()
                if data.isFavorite then
                    return nodeData.id == 0
                else
                    return nodeData.id == headerID
                end
            end)
        end
    end

    local nodes = dataProvider:GetChildrenNodes()
    local nodesToRemove = {}

    for k, child in ipairs(nodes) do
        local numChildNodes = #child:GetNodes()
        if numChildNodes < 1 then
            table.insert(nodesToRemove, child)
        end
    end

    for k, node in ipairs(nodesToRemove) do
        dataProvider:Remove(node)
    end

    self.ScrollBox:SetDataProvider(dataProvider);
end

------------------------------

DFProfessionFrameRecipeCategoryMixin = {}

function DFProfessionFrameRecipeCategoryMixin:OnEnter()
    self.Label:SetFontObject(GameFontHighlight_NoShadow);
end

function DFProfessionFrameRecipeCategoryMixin:OnLeave()
    self.Label:SetFontObject(GameFontNormal_NoShadow);
end

function DFProfessionFrameRecipeCategoryMixin:Init(node, ref)
    local elementData = node:GetData();
    local categoryInfo = elementData.categoryInfo;
    self.Label:SetText(categoryInfo.name);

    if categoryInfo.showProgressBar then
        local str = string.format('[%d/%d]', categoryInfo.currentRank, categoryInfo.maxRank)
        self.LabelRight:SetText(str);
    else
        self.LabelRight:SetText('');
    end

    local collapsed = ref:IsCategoryCollapsed(elementData.collapsedKey)
    if not collapsed then
        node:SetCollapsed(false, false, false)
    else
        node:SetCollapsed(true, false, false)
    end

    self:SetCollapseState(node:IsCollapsed());
end

function DFProfessionFrameRecipeCategoryMixin:SetCollapseState(collapsed)
    if collapsed then
        self.CollapseIcon:SetTexCoord(0.302246, 0.312988, 0.0537109, 0.0693359)
        self.CollapseIconAlphaAdd:SetTexCoord(0.302246, 0.312988, 0.0537109, 0.0693359)
    else
        self.CollapseIcon:SetTexCoord(0.270508, 0.28125, 0.0537109, 0.0693359)
        self.CollapseIconAlphaAdd:SetTexCoord(0.270508, 0.28125, 0.0537109, 0.0693359)
    end
end

------------------------------

DFProfessionFrameRecipeMixin = {}

function DFProfessionFrameRecipeMixin:OnLoad()
    local function OnLeave()
        self:OnLeave();
        GameTooltip_Hide();
    end

    self.LockedIcon:SetScript("OnLeave", OnLeave);
    self.SkillUps:SetScript("OnLeave", OnLeave);
end

local PROFESSION_RECIPE_COLOR = CreateColor(0.88627457618713, 0.86274516582489, 0.83921575546265, 1)

function DFProfessionFrameRecipeMixin:GetLabelColor()
    return PROFESSION_RECIPE_COLOR
end

local PROFESSIONS_SKILL_UP_EASY = "Low chance of gaining skill"
local PROFESSIONS_SKILL_UP_MEDIUM = "High chance of gaining skill"
local PROFESSIONS_SKILL_UP_OPTIMAL = "Guaranteed chance of gaining %d skill ups"
local PROFESSIONS_SKILL_UP_OPTIMAL_SINGLE = "Guaranteed chance of gaining skill"

local DifficultyColors = {
    ['optimal'] = DIFFICULT_DIFFICULTY_COLOR,
    ['medium'] = FAIR_DIFFICULTY_COLOR,
    ['easy'] = EASY_DIFFICULTY_COLOR
};

function DFProfessionFrameRecipeMixin:Init(node, hideCraftableCount)
    local elementData = node:GetData();
    local recipeInfo = elementData.recipeInfo

    if recipeInfo.craftSubSpellName then
        self.Label:SetText(recipeInfo.name .. ' (' .. recipeInfo.craftSubSpellName .. ')');
    else
        self.Label:SetText(recipeInfo.name);
    end
    self:SetLabelFontColors(self:GetLabelColor());

    local tooltipSkillUpString = nil;
    local icon = self.SkillUps.Icon
    icon:Show()

    local skillType = recipeInfo.skillType

    if skillType == 'trivial' then
        icon:Hide()
    elseif skillType == 'easy' then
        icon:SetTexCoord(0.255859, 0.262207, 0.0537109, 0.0683594)
        tooltipSkillUpString = PROFESSIONS_SKILL_UP_EASY
    elseif skillType == 'medium' then
        icon:SetTexCoord(0.294922, 0.30127, 0.0537109, 0.0683594)
        tooltipSkillUpString = PROFESSIONS_SKILL_UP_MEDIUM
    elseif skillType == 'optimal' then
        icon:SetTexCoord(0.263184, 0.269531, 0.0537109, 0.0683594)
        if recipeInfo.numSkillUps and recipeInfo.numSkillUps > 1 then
            tooltipSkillUpString = PROFESSIONS_SKILL_UP_OPTIMAL
        else
            tooltipSkillUpString = PROFESSIONS_SKILL_UP_OPTIMAL_SINGLE
        end
    elseif skillType == 'difficult' then
        icon:Hide()
    end

    self.SkillUps:Hide();
    if tooltipSkillUpString then
        local isDifficultyOptimal = skillType == 'optimal'
        local numSkillUps = recipeInfo.numSkillUps and recipeInfo.numSkillUps or 1;
        local hasMultipleSkillUps = numSkillUps > 1;
        local hasSkillUps = numSkillUps > 0;
        local showText = hasMultipleSkillUps and isDifficultyOptimal;
        self.SkillUps.Text:SetText('');
        self.SkillUps.Text:SetShown(showText);

        if hasSkillUps then
            if showText then
                self.SkillUps.Text:SetText(numSkillUps);
                self.SkillUps.Text:SetVertexColor(DifficultyColors[recipeInfo.skillType]:GetRGB());
            end

            self.SkillUps:SetScript("OnEnter", function()
                self:OnEnter();
                GameTooltip:SetOwner(self.SkillUps, "ANCHOR_RIGHT");
                GameTooltip_AddNormalLine(GameTooltip, tooltipSkillUpString:format(numSkillUps));
                GameTooltip:Show();
            end);
        else
            self.SkillUps:SetScript("OnEnter", nil);
        end
        self.SkillUps:Show();
    end

    local count = recipeInfo.numAvailable
    local hasCount = count > 0;
    if hasCount then
        self.Count:SetFormattedText(" [%d] ", count);
        self.Count:Show();
    else
        self.Count:Hide();
    end

    local padding = 10;
    local countWidth = hasCount and self.Count:GetStringWidth() or 0;
    local width = self:GetWidth() - (countWidth + padding + self.SkillUps:GetWidth());
    self.Label:SetWidth(self:GetWidth());

    if recipeInfo.trainingPointCost and recipeInfo.trainingPointCost > 0 then
        width = width - 10;
        self.Count:SetFormattedText(" - %d TP", recipeInfo.trainingPointCost)
        self.Count:Show()
    end
    self.Label:SetWidth(math.min(width, self.Label:GetStringWidth()));
end

function DFProfessionFrameRecipeMixin:SetLabelFontColors(color)
    self.Label:SetVertexColor(color:GetRGB());
    self.Count:SetVertexColor(color:GetRGB());
end

function DFProfessionFrameRecipeMixin:OnEnter()
    self:SetLabelFontColors(HIGHLIGHT_FONT_COLOR);
    local elementData = self:GetElementData();
    local recipeID = elementData.data.recipeInfo.recipeID;
    local name = elementData.data.recipeInfo.name;
    local iconID = elementData.data.recipeInfo.icon;

    if self.Label:IsTruncated() then
        GameTooltip:SetOwner(self.Label, "ANCHOR_RIGHT");
        local wrap = false;
        GameTooltip_AddHighlightLine(GameTooltip, name, wrap);
        GameTooltip:Show();
    end
end

function DFProfessionFrameRecipeMixin:OnLeave()
    self:SetLabelFontColors(self:GetLabelColor());
    GameTooltip:Hide();
end

function DFProfessionFrameRecipeMixin:SetSelected(selected)
    self.SelectedOverlay:SetShown(selected);
    self.HighlightOverlay:SetShown(not selected);
end
