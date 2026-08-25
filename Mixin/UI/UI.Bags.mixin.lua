local addonName, addonTable = ...;
local Helper = addonTable.Helper;
---@diagnostic disable: undefined-global
---@class DragonflightUI
---@diagnostic disable-next-line: assign-type-mismatch
local DF = LibStub('AceAddon-3.0'):GetAddon('DragonflightUI')

DragonflightUIMixin = DragonflightUIMixin or {}

local base = 'Interface\\Addons\\DragonflightUI\\Textures\\UI\\'

function DragonflightUIMixin:ChangeBag(frame)
    local name = frame:GetName()

    do
        local alpha = 0
        local top = _G[name .. 'BackgroundTop']
        top:SetAlpha(alpha)

        local mid1 = _G[name .. 'BackgroundMiddle1']
        mid1:SetAlpha(alpha)

        local mid2 = _G[name .. 'BackgroundMiddle2']
        mid2:SetAlpha(alpha)

        local bottom = _G[name .. 'BackgroundBottom']
        bottom:SetAlpha(alpha)
    end

    local port = _G[name .. 'Portrait']
    port:ClearAllPoints()
    port:SetAlpha(1)
    port:SetSize(36, 36)
    port:SetPoint('TOPLEFT', frame, 'TOPLEFT', -4, 1)
    port:SetDrawLayer('OVERLAY', 5)

    local newPort = frame:CreateTexture('DFPortrait')
    newPort:SetTexture(133633)
    newPort:SetSize(36, 36)
    newPort:SetPoint('TOPLEFT', frame, 'TOPLEFT', -4, 1)
    newPort:SetDrawLayer('OVERLAY', 6)
    newPort:Hide()
    SetPortraitToTexture(newPort, newPort:GetTexture())

    frame.DFPortrait = newPort

    local portBtn = _G[name .. 'PortraitButton']
    portBtn:ClearAllPoints()
    portBtn:SetSize(36, 36)
    portBtn:SetPoint('TOPLEFT', frame, 'TOPLEFT', -4, 1)

    frame.ClosePanelButton = _G[name .. 'CloseButton']
    DragonflightUIMixin:AddNineSliceTextures(frame, true)
    DragonflightUIMixin:ButtonFrameTemplateNoPortrait(frame)

    frame.Bg:SetPoint('TOPLEFT', frame, 'TOPLEFT', 2, -20)
    frame.Bg:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', -2, 3)

    local pp = frame:CreateTexture('DFPortraitBorder')
    pp:SetTexture(base .. 'ui-frame-portraitmetal-cornertopleftsmall')
    pp:SetSize(75, 76)
    pp:SetTexCoord(0, 150 / 256, 0, 150 / 256)
    pp:ClearAllPoints()
    pp:SetPoint('TOPLEFT', frame, 'TOPLEFT', -13, 16)
    pp:SetDrawLayer('OVERLAY', 7)

    frame.TitleContainer = CreateFrame('FRAME', nil, frame)
    frame.TitleContainer:SetSize(0, 20)
    frame.TitleContainer:SetPoint('TOPLEFT', 35, -1)
    frame.TitleContainer:SetPoint('TOPRIGHT', -24, -1)

    local title = _G[name .. 'Name']
    title:ClearAllPoints()
    title:SetPoint('TOP', frame.TitleContainer, 'TOP', 0, -5)
    title:SetPoint('RIGHT', frame.TitleContainer, 'RIGHT', 0, 0)
    title:SetPoint('LEFT', frame.TitleContainer, 'LEFT', 0, 0)
    title:SetFontObject("GameFontNormal")

    do
        local moneyFrame = _G[frame:GetName() .. 'MoneyFrame']
        moneyFrame:ClearAllPoints()
        moneyFrame:SetPoint('BOTTOMLEFT', frame, 'BOTTOMLEFT', 8, 8)
        moneyFrame:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', -8, 8)
        MoneyFrame_SetMaxDisplayWidth(moneyFrame, 178 - 2 * 8)
        moneyFrame:SetHeight(17)

        local border = CreateFrame('FRAME', nil, moneyFrame, 'ContainerMoneyFrameBorderTemplate')
        border:SetParent(moneyFrame)
        border:SetAllPoints()
        moneyFrame.border = border
    end

    do
        local CONTAINER_WIDTH = 178;
        frame:SetWidth(CONTAINER_WIDTH)
    end
end

function DragonflightUIMixin:ChangeBagButton(btn)
    local bg = btn:CreateTexture('DragonflightUIBg')
    bg:SetTexture(base .. 'BagsItemSlot2x')
    bg:SetSize(37, 37)
    bg:SetPoint('CENTER', 0, 0)
    bg:SetDrawLayer('BACKGROUND', 3)

    local normal = btn:GetNormalTexture()
    normal:SetTexture(base .. 'BagsItemSlot2x')
    normal:SetSize(37, 37)
    normal:SetPoint('CENTER', 0, 0)
    normal:SetDrawLayer('BACKGROUND', 3)

    local pushed = btn:GetPushedTexture()
    pushed:SetTexture(base .. 'ui-quickslot-depress')
    pushed:SetSize(37, 37)
    pushed:SetPoint('CENTER', 0, 0)

    local high = btn:GetHighlightTexture()
    high:SetTexture(base .. 'buttonhilight-square')
    high:SetSize(37, 37)
    high:SetPoint('CENTER', 0, 0)

    local iconBorder = btn.IconBorder
    iconBorder:Hide()

    local border = btn:CreateTexture('DragonflightUIBorder')
    border:SetTexture(base .. 'ui-quickslot2')
    border:SetSize(64, 64)
    border:SetPoint('CENTER', 0, -1)
    border:SetDrawLayer('BACKGROUND', 4)
end

function DragonflightUIMixin:ChangeBackpackTokenFrame()
    local frame = BackpackTokenFrame

    local regions = {frame:GetRegions()}

    for k, child in ipairs(regions) do
        if child:GetObjectType() == 'Texture' then child:SetTexture('') end
    end

    frame:SetHeight(17)

    local border = CreateFrame('FRAME', nil, frame, 'ContainerTokenFrameBorderTemplate')
    border:SetParent(frame)
    border:SetAllPoints()
    frame.border = border

    local other;
    for i = 1, 3 do
        local token = _G['BackpackTokenFrameToken' .. i]
        token:ClearAllPoints()

        if other then
            token:SetPoint('LEFT', other, 'RIGHT', 0, 0)
        else
            token:SetPoint('LEFT', frame, 'LEFT', 6.5, -1)
        end
        other = token
    end
end

function DragonflightUIMixin:CreateSearchBox()
    local frame = CreateFrame('EditBox', 'DragonflightUIBackpackSearchBox', ContainerFrame1, 'BagSearchBoxTemplate')
    frame:SetSize(115, 20)
    frame:SetMaxLetters(15)
    return frame
end

function DragonflightUIMixin:CreateBankSearchBox()
    local frame = CreateFrame('EditBox', 'DragonflightUIBankkSearchBox', BankFrame, 'BagSearchBoxTemplate')
    frame:SetSize(110, 20)
    frame:SetMaxLetters(15)
    frame:SetPoint('TOPRIGHT', BankFrame, 'TOPRIGHT', -48, -33)
    return frame
end

local DragonglightUIGuildBankSearchMixin = {}

function DragonglightUIGuildBankSearchMixin:UpdateFiltered()
    if not GuildBankFrame:IsVisible() then return end

    local id = self:GetID();
    local activeTab = GetCurrentGuildBankTab()

    local itemButton;
    local buttonID;
    local texture, itemCount, locked, isFiltered, quality;
    local hasItem = false
    local items = 0

    if id == activeTab then
        for c = 1, 7 do
            local column = GuildBankFrame['Column' .. c]
            for i = 1, 14 do
                itemButton = column['Button' .. i]
                buttonID = (c - 1) * 14 + i
                texture, itemCount, locked, isFiltered, quality = GetGuildBankItemInfo(id, buttonID)
                if not texture then
                    itemButton.searchOverlay:Hide();
                elseif (isFiltered) then
                    itemButton.searchOverlay:Show();
                else
                    hasItem = true
                    items = items + 1
                    itemButton.searchOverlay:Hide();
                end
            end
        end
    else
        for c = 1, 7 do
            for i = 1, 14 do
                buttonID = (c - 1) * 14 + i
                texture, itemCount, locked, isFiltered, quality = GetGuildBankItemInfo(id, buttonID)
                if not texture then
                elseif (isFiltered) then
                else
                    hasItem = true
                    items = items + 1
                end
            end
        end
    end

    if hasItem then
        self.SearchOverlay:Hide()
    else
        self.SearchOverlay:Show()
    end
end

function DragonflightUIMixin:AddGuildbankSearch()
    if GuildBankFrame.DFGuildbankSearch then return end
    GuildBankFrame.DFGuildbankSearch = true

    local frame = CreateFrame('EditBox', 'DragonflightUIGuildBankkSearchBox', GuildBankFrame, 'BagSearchBoxTemplate')
    frame:SetSize(110, 20)
    frame:SetMaxLetters(15)
    frame:SetPoint('TOPRIGHT', GuildBankFrame, 'TOPRIGHT', -48, -40)

    for i = 1, MAX_GUILDBANK_TABS do
        local tab = _G['GuildBankTab' .. i]
        tab.Button:SetID(i)
        Mixin(tab.Button, DragonglightUIGuildBankSearchMixin)
        hooksecurefunc(tab, 'OnClick', function()
            tab.Button:UpdateFiltered()
        end)
    end
end
