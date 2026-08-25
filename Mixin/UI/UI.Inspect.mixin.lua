local addonName, addonTable = ...;
local Helper = addonTable.Helper;
---@diagnostic disable: undefined-global
---@class DragonflightUI
---@diagnostic disable-next-line: assign-type-mismatch
local DF = LibStub('AceAddon-3.0'):GetAddon('DragonflightUI')

DragonflightUIMixin = DragonflightUIMixin or {}

local base = 'Interface\\Addons\\DragonflightUI\\Textures\\UI\\'

function DragonflightUIMixin:ChangeInspectFrameEra()
    if not InspectFrame or InspectFrame.DFHooked then return end

    InspectFrame:SetSize(336, 424)

    local frame = InspectFrame
    if true then
        local slice = frame.NineSlice

        slice.TopLeftCorner = _G[frame:GetName() .. 'TopLeftCorner']
        slice.TopLeftCorner:Show()
        slice.TopRightCorner = _G[frame:GetName() .. 'TopRightCorner']

        slice.BottomLeftCorner = _G[frame:GetName() .. 'BtnCornerLeft']
        _G[frame:GetName() .. 'BotLeftCorner']:Hide()
        slice.BottomRightCorner = _G[frame:GetName() .. 'BotRightCorner']
        slice.BottomRightCorner = _G[frame:GetName() .. 'BtnCornerRight']
        _G[frame:GetName() .. 'BotRightCorner']:Hide()

        slice.TopEdge = _G[frame:GetName() .. 'TopBorder']
        slice.BottomEdge = _G[frame:GetName() .. 'BottomBorder']
        _G[frame:GetName() .. 'ButtonBottomBorder']:Hide()

        slice.LeftEdge = _G[frame:GetName() .. 'LeftBorder']
        slice.RightEdge = _G[frame:GetName() .. 'RightBorder']
    end

    DragonflightUIMixin:AddNineSliceTextures(InspectFrame, true)
    DragonflightUIMixin:ButtonFrameTemplateNoPortrait(InspectFrame)

    DragonflightUIMixin:UIPanelCloseButton(InspectFrameCloseButton)
    InspectFrameCloseButton:SetPoint('TOPRIGHT', InspectFrame, 'TOPRIGHT', 1, 0)

    do
        local port = InspectFramePortrait
        port:SetSize(62, 62)
        port:ClearAllPoints()
        port:SetPoint('TOPLEFT', -5, 7)
        port:SetDrawLayer('OVERLAY', 6)

        Helper:AddCircleMask(InspectFrame, InspectFramePortrait)

        InspectFrame.PortraitFrame = InspectFrame:CreateTexture('PortraitFrame')
        local pp = InspectFrame.PortraitFrame
        pp:SetTexture(base .. 'UI-Frame-PortraitMetal-CornerTopLeft')
        pp:SetTexCoord(0.0078125, 0.0078125, 0.0078125, 0.6171875, 0.6171875, 0.0078125, 0.6171875, 0.6171875)
        pp:SetSize(84, 84)
        pp:ClearAllPoints()
        pp:SetPoint('CENTER', port, 'CENTER', 0, 0)
        pp:SetDrawLayer('OVERLAY', 7)

        InspectFramePortraitFrame:Hide()
    end

    DragonflightUIMixin:FrameBackgroundSolid(InspectFrame, true)

    do
        local name = _G['InspectNameFrame']
        name:ClearAllPoints()
        name:SetPoint('TOP', InspectFrame, 'TOP', 0, -5)
        name:SetPoint('LEFT', InspectFrame, 'LEFT', 60, 0)
        name:SetPoint('RIGHT', InspectFrame, 'RIGHT', -60, 0)

        local level = InspectLevelText
        level:ClearAllPoints()
        level:SetPoint('TOP', name, 'BOTTOM', 0, -10)
        level:SetDrawLayer('ARTWORK')
    end

    do
        local model = _G['InspectModelFrame']
        model:ClearAllPoints()
        model:SetPoint('TOPLEFT', InspectPaperDollFrame, 'TOPLEFT', 52, -74 + 10)

        local inset = CreateFrame('Frame', 'DragonflightUICharacterFrameInset', InspectPaperDollFrame,
                                  'InsetFrameTemplate')
        inset:ClearAllPoints()
        inset:SetPoint('TOPLEFT', model, 'TOPLEFT', 0, 0)
        inset:SetPoint('BOTTOMRIGHT', model, 'BOTTOMRIGHT', 0, 8)

        local tl = model:CreateTexture('DragonflightUIInspectModelFrame' .. 'TopLeft', 'BACKGROUND')
        tl:SetSize(212, 245)
        tl:SetPoint('TOPLEFT', 0, 0)
        tl:SetTexCoord(0.171875, 1, 0.0392156862745098, 1)

        local tr = model:CreateTexture('DragonflightUIInspectModelFrame' .. 'TopRight', 'BACKGROUND')
        tr:SetSize(19, 245)
        tr:SetPoint('TOPLEFT', tl, 'TOPRIGHT')
        tr:SetTexCoord(0, 0.296875, 0.0392156862745098, 1)

        local delta = 56

        local bl = model:CreateTexture('DragonflightUIInspectModelFrame' .. 'BotLeft', 'BACKGROUND')
        bl:SetSize(212, 128 - delta)
        bl:SetPoint('TOPLEFT', tl, 'BOTTOMLEFT')
        bl:SetTexCoord(0.171875, 1, 0, 1 - delta / 128)

        local br = model:CreateTexture('DragonflightUIInspectModelFrame' .. 'BotRight', 'BACKGROUND')
        br:SetSize(19, 128 - delta)
        br:SetPoint('TOPLEFT', tl, 'BOTTOMRIGHT')
        br:SetTexCoord(0, 0.296875, 0, 1 - delta / 128)

        local overlay = model:CreateTexture('DragonflightUIInspectModelFrame' .. 'Overlay', 'BORDER')
        overlay:SetPoint('TOPLEFT', tl, 'TOPLEFT', 0, 0)
        overlay:SetPoint('BOTTOMRIGHT', br, 'BOTTOMRIGHT', 0, 0)
        overlay:SetColorTexture(0, 0, 0)

        _G['InspectModelFrameBackgroundOverlay']:Hide()
        _G['InspectModelFrameBackgroundTopLeft']:Hide()
        _G['InspectModelFrameBackgroundTopRight']:Hide()
        _G['InspectModelFrameBackgroundBotLeft']:Hide()
        _G['InspectModelFrameBackgroundBotRight']:Hide()

        local backgroundDesaturate = function(on)
            tl:SetDesaturated(on);
            tr:SetDesaturated(on);
            bl:SetDesaturated(on);
            br:SetDesaturated(on);
        end

        local updateBackground = function(unit)
            local race, fileName = UnitRace(unit);
            if not fileName then return end
            local texture = DressUpTexturePath(fileName);
            tl:SetTexture(texture .. tostring(1));
            tr:SetTexture(texture .. tostring(2));
            bl:SetTexture(texture .. tostring(3));
            br:SetTexture(texture .. tostring(4));

            if (strupper(fileName) == "BLOODELF") then
                overlay:SetAlpha(0.8);
            elseif (strupper(fileName) == "NIGHTELF") then
                overlay:SetAlpha(0.6);
            elseif (strupper(fileName) == "SCOURGE") then
                overlay:SetAlpha(0.3);
            elseif (strupper(fileName) == "TROLL" or strupper(fileName) == "ORC") then
                overlay:SetAlpha(0.6);
            elseif (strupper(fileName) == "WORGEN") then
                overlay:SetAlpha(0.5);
            elseif (strupper(fileName) == "GOBLIN") then
                overlay:SetAlpha(0.6);
            else
                overlay:SetAlpha(0.7);
            end
        end

        InspectFrame:HookScript('OnEvent', function(self, event, unit, ...)
            if event == 'INSPECT_READY' then
                if InspectFrame and InspectFrame.unit then updateBackground(InspectFrame.unit) end
            end
        end)
    end

    -- honor Era
    if InspectHonorFrame then
        local regions = {InspectHonorFrame:GetRegions()}
        for k, child in ipairs(regions) do
            if child:GetObjectType() == 'Texture' then
                local layer, layerNr = child:GetDrawLayer()
                if layer == 'BACKGROUND' then child:Hide() end
            end
        end
        local dx = -2
        local dy = 4

        InspectHonorFrame:SetPoint('TOPLEFT', InspectFrame, 'TOPLEFT', 0 + dx, 0 + dy)
        InspectHonorFrame:SetPoint('BOTTOMRIGHT', InspectFrame, 'BOTTOMRIGHT', 0 + dx, 0 + dy)

        local deltaTitle = 6;

        _G['InspectHonorFrameCurrentPVPTitle']:SetPoint('TOP', InspectHonorFrame, 'TOP', -21.33, -83 + deltaTitle)

        hooksecurefunc('InspectHonorFrame_Update', function()
            InspectHonorFrameCurrentPVPTitle:SetPoint("TOP", "InspectHonorFrame", "TOP",
                                                      -InspectHonorFrameCurrentPVPRank:GetWidth() / 2, -83 + deltaTitle);
        end)
    end

    UIPanelWindows["InspectFrame"] = {
        whileDead = 1,
        height = InspectFrame:GetHeight(),
        width = InspectFrame:GetWidth(),
        bottomClampOverride = 152,
        xoffset = 0,
        yoffset = 0,
        pushable = 3,
        area = "left"
    }

    do
        local firstTab = _G['InspectFrameTab1']
        firstTab:ClearAllPoints()
        firstTab:SetPoint('TOPLEFT', InspectFrame, 'BOTTOMLEFT', 12, 1)

        for i = 1, 4 do
            local tab = _G['InspectFrameTab' .. i]
            if tab then
                DragonflightUIMixin:CharacterFrameTabButtonTemplate(tab)

                if i == 1 then
                    tab.DFFirst = true
                elseif i > 1 then
                    tab.DFChangePoint = true
                end
            end
        end
    end

    InspectFrame.DFHooked = true
end

function DragonflightUIMixin:ChangeInspectFrame()
    if not InspectFrame or InspectFrame.DFHooked then return end
    if DF.API.Version.IsMoP then return end

    do
        local regions = {InspectPaperDollFrame:GetRegions()}

        for k, child in ipairs(regions) do
            if child:GetObjectType() == 'Texture' then
                local layer, layerNr = child:GetDrawLayer()
                if layer == 'BORDER' then child:Hide() end
            end
        end
    end

    -- honor
    if InspectPVPFrame then
        local regions = {InspectPVPFrame:GetRegions()}
        for k, child in ipairs(regions) do
            if child:GetObjectType() == 'Texture' then
                local layer, layerNr = child:GetDrawLayer()
                if layer == 'BACKGROUND' then child:Hide() end
            end
        end
        local dx = -16
        local dy = 12

        InspectPVPFrame:SetPoint('TOPLEFT', InspectFrame, 'TOPLEFT', 0 + dx, 0 + dy)
        InspectPVPFrame:SetPoint('BOTTOMRIGHT', InspectFrame, 'BOTTOMRIGHT', 0 + dx, 0 + dy)
    end

    -- honor Era
    if InspectHonorFrame then
        local regions = {InspectHonorFrame:GetRegions()}
        for k, child in ipairs(regions) do
            if child:GetObjectType() == 'Texture' then
                local layer, layerNr = child:GetDrawLayer()
                if layer == 'BACKGROUND' then child:Hide() end
            end
        end
        local dx = -14
        local dy = 14

        InspectHonorFrame:SetPoint('TOPLEFT', InspectFrame, 'TOPLEFT', 0 + dx, 0 + dy)
        InspectHonorFrame:SetPoint('BOTTOMRIGHT', InspectFrame, 'BOTTOMRIGHT', 0 + dx, 0 + dy)
    end

    -- talent
    if InspectTalentFrame and not DF.API.Version.IsMoP then
        local regions = {InspectTalentFrame:GetRegions()}
        for k, child in ipairs(regions) do
            if child:GetObjectType() == 'Texture' then
                local layer, layerNr = child:GetDrawLayer()
                if layer == 'BORDER' then child:Hide() end
            end
        end
        local dx = -14
        local dy = 12

        InspectTalentFrame:SetPoint('TOPLEFT', InspectFrame, 'TOPLEFT', 0 + dx, 0 + dy)
        InspectTalentFrame:SetPoint('BOTTOMRIGHT', InspectFrame, 'BOTTOMRIGHT', 0 + dx, 0 + dy)

        if InspectTalentFrameCloseButton then InspectTalentFrameCloseButton:Hide() end

        if InspectTalentFramePointsBar then
            local pointsBar = InspectTalentFramePointsBar
            pointsBar:ClearAllPoints()
            pointsBar:SetPoint('BOTTOM', InspectFrame, 'BOTTOM', 0, 4)
        end

        local scroll = InspectTalentFrameScrollFrame
        if scroll then scroll:SetPoint('TOPRIGHT', InspectFrame, 'TOPRIGHT', -32, -66) end

        for i = 1, 28 do
            local talent = _G['InspectTalentFrameTalent' .. i]
            talent:SetScript('OnEnter', function(self)
                local selectedTab = PanelTemplates_GetSelectedTab(InspectTalentFrame) or InspectTalentFrame.talentTree;
                local talentGroup = GetActiveTalentGroup(true, false);
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
                ---@diagnostic disable-next-line: redundant-parameter
                GameTooltip:SetTalent(selectedTab, i, true, false, talentGroup, true)
            end)
        end
    end

    InspectFrame:SetSize(336, 424)

    DragonflightUIMixin:AddNineSliceTextures(InspectFrame, true)
    DragonflightUIMixin:ButtonFrameTemplateNoPortrait(InspectFrame)

    DragonflightUIMixin:UIPanelCloseButton(InspectFrameCloseButton)
    InspectFrameCloseButton:SetPoint('TOPRIGHT', InspectFrame, 'TOPRIGHT', 1, 0)

    do
        local port = InspectFramePortrait
        port:SetSize(62, 62)
        port:ClearAllPoints()
        port:SetPoint('TOPLEFT', -5, 7)
        port:SetDrawLayer('OVERLAY', 6)

        Helper:AddCircleMask(InspectFrame, InspectFramePortrait)

        InspectFrame.PortraitFrame = InspectFrame:CreateTexture('PortraitFrame')
        local pp = InspectFrame.PortraitFrame
        pp:SetTexture(base .. 'UI-Frame-PortraitMetal-CornerTopLeft')
        pp:SetTexCoord(0.0078125, 0.0078125, 0.0078125, 0.6171875, 0.6171875, 0.0078125, 0.6171875, 0.6171875)
        pp:SetSize(84, 84)
        pp:ClearAllPoints()
        pp:SetPoint('CENTER', port, 'CENTER', 0, 0)
        pp:SetDrawLayer('OVERLAY', 7)
    end

    DragonflightUIMixin:FrameBackgroundSolid(InspectFrame, true)

    do
        local name = _G['InspectNameFrame']
        name:ClearAllPoints()
        name:SetPoint('TOP', InspectFrame, 'TOP', 0, -5)
        name:SetPoint('LEFT', InspectFrame, 'LEFT', 60, 0)
        name:SetPoint('RIGHT', InspectFrame, 'RIGHT', -60, 0)

        local level = InspectLevelText
        level:ClearAllPoints()
        level:SetPoint('TOP', name, 'BOTTOM', 0, -10)
        level:SetDrawLayer('ARTWORK')
    end

    do
        local head = _G['InspectHeadSlot']
        head:ClearAllPoints()
        head:SetPoint('TOPLEFT', InspectPaperDollItemsFrame, 'TOPLEFT', 8, -74)
    end

    do
        local model = _G['InspectModelFrame']
        model:ClearAllPoints()
        model:SetPoint('TOPLEFT', InspectPaperDollFrame, 'TOPLEFT', 52, -74)

        local inset = CreateFrame('Frame', 'DragonflightUICharacterFrameInset', InspectPaperDollFrame,
                                  'InsetFrameTemplate')
        inset:ClearAllPoints()
        inset:SetPoint('TOPLEFT', model, 'TOPLEFT', 0, 0)
        inset:SetPoint('BOTTOMRIGHT', model, 'BOTTOMRIGHT', 0, 8)

        local tl = model:CreateTexture('DragonflightUIInspectModelFrame' .. 'TopLeft', 'BACKGROUND')
        tl:SetSize(212, 245)
        tl:SetPoint('TOPLEFT')
        tl:SetTexCoord(0.171875, 1, 0.0392156862745098, 1)

        local tr = model:CreateTexture('DragonflightUIInspectModelFrame' .. 'TopRight', 'BACKGROUND')
        tr:SetSize(19, 245)
        tr:SetPoint('TOPLEFT', tl, 'TOPRIGHT')
        tr:SetTexCoord(0, 0.296875, 0.0392156862745098, 1)

        local delta = 80

        local bl = model:CreateTexture('DragonflightUIInspectModelFrame' .. 'BotLeft', 'BACKGROUND')
        bl:SetSize(212, 128 - delta)
        bl:SetPoint('TOPLEFT', tl, 'BOTTOMLEFT')
        bl:SetTexCoord(0.171875, 1, 0, 1 - delta / 128)

        local br = model:CreateTexture('DragonflightUIInspectModelFrame' .. 'BotRight', 'BACKGROUND')
        br:SetSize(19, 128 - delta)
        br:SetPoint('TOPLEFT', tl, 'BOTTOMRIGHT')
        br:SetTexCoord(0, 0.296875, 0, 1 - delta / 128)

        local overlay = model:CreateTexture('DragonflightUIInspectModelFrame' .. 'Overlay', 'BORDER')
        overlay:SetPoint('TOPLEFT', tl, 'TOPLEFT', 0, 0)
        overlay:SetPoint('BOTTOMRIGHT', br, 'BOTTOMRIGHT', 0, 0)
        overlay:SetColorTexture(0, 0, 0)

        local backgroundDesaturate = function(on)
            tl:SetDesaturated(on);
            tr:SetDesaturated(on);
            bl:SetDesaturated(on);
            br:SetDesaturated(on);
        end

        local updateBackground = function(unit)
            local race, fileName = UnitRace(unit);
            if not fileName then return end
            local texture = DressUpTexturePath(fileName);
            tl:SetTexture(texture .. 1);
            tr:SetTexture(texture .. 2);
            bl:SetTexture(texture .. 3);
            br:SetTexture(texture .. 4);

            if (strupper(fileName) == "BLOODELF") then
                overlay:SetAlpha(0.8);
            elseif (strupper(fileName) == "NIGHTELF") then
                overlay:SetAlpha(0.6);
            elseif (strupper(fileName) == "SCOURGE") then
                overlay:SetAlpha(0.3);
            elseif (strupper(fileName) == "TROLL" or strupper(fileName) == "ORC") then
                overlay:SetAlpha(0.6);
            elseif (strupper(fileName) == "WORGEN") then
                overlay:SetAlpha(0.5);
            elseif (strupper(fileName) == "GOBLIN") then
                overlay:SetAlpha(0.6);
            else
                overlay:SetAlpha(0.7);
            end
        end

        InspectFrame:HookScript('OnEvent', function(self, event, unit, ...)
            if event == 'INSPECT_READY' then
                if InspectFrame and InspectFrame.unit then updateBackground(InspectFrame.unit) end
                backgroundDesaturate(true)
            end
        end)
    end

    do
        local hands = _G['InspectHandsSlot']
        hands:ClearAllPoints()
        hands:SetPoint('TOPRIGHT', InspectPaperDollItemsFrame, 'TOPRIGHT', -8, -74)
    end

    do
        local main = _G['InspectMainHandSlot']
        if not DF.API.Version.IsTBC then
            main:ClearAllPoints()
            local x = (InspectPaperDollItemsFrame:GetWidth() / 2) - 1.5 * main:GetWidth() - 5
            main:SetPoint('BOTTOMLEFT', InspectPaperDollItemsFrame, 'BOTTOMLEFT', x, 16)
        end
    end

    UIPanelWindows["InspectFrame"] = {
        whileDead = 1,
        height = InspectFrame:GetHeight(),
        width = InspectFrame:GetWidth(),
        bottomClampOverride = 152,
        xoffset = 0,
        yoffset = 0,
        pushable = 3,
        area = "left"
    }

    do
        local firstTab = _G['InspectFrameTab1']
        firstTab:ClearAllPoints()
        firstTab:SetPoint('TOPLEFT', InspectFrame, 'BOTTOMLEFT', 12, 1)

        for i = 1, 4 do
            local tab = _G['InspectFrameTab' .. i]
            if tab then
                DragonflightUIMixin:CharacterFrameTabButtonTemplate(tab)

                if i == 1 then
                    tab.DFFirst = true
                elseif i > 1 then
                    tab.DFChangePoint = true
                end
            end
        end
    end

    InspectFrame.DFHooked = true
end
