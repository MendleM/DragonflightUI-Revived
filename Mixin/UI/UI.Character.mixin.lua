local addonName, addonTable = ...;
local Helper = addonTable.Helper;
---@diagnostic disable: undefined-global
---@class DragonflightUI
---@diagnostic disable-next-line: assign-type-mismatch
local DF = LibStub('AceAddon-3.0'):GetAddon('DragonflightUI')

DragonflightUIMixin = DragonflightUIMixin or {}

local base = 'Interface\\Addons\\DragonflightUI\\Textures\\UI\\'

function DragonflightUIMixin:ChangeCharacterFrameEra()
    local frameTable = {PaperDollFrame, ReputationFrame, SkillFrame}
    if DF.Wrath and not DF.Cata then
        table.insert(frameTable, TokenFrame)
    end

    for i, f in ipairs(frameTable) do
        local regions = {f:GetRegions()}

        for k, child in ipairs(regions) do
            if child:GetObjectType() == 'Texture' then
                local layer, layerNr = child:GetDrawLayer()
                if layer == 'BORDER' then child:Hide() end
                if DF.Wrath and not DF.Cata then
                    if f == TokenFrame and layer == 'ARTWORK' then child:Hide() end
                end
            end
        end
    end

    -- honor
    if HonorFrame then
        local regions = {HonorFrame:GetRegions()}
        for k, child in ipairs(regions) do
            if child:GetObjectType() == 'Texture' then
                local layer, layerNr = child:GetDrawLayer()
                if layer == 'BACKGROUND' then child:Hide() end
            end
        end
        local dx = -14
        local dy = 12

        HonorFrame:SetPoint('TOPLEFT', CharacterFrame, 'TOPLEFT', 0 + dx, 0 + dy)
        HonorFrame:SetPoint('BOTTOMRIGHT', CharacterFrame, 'BOTTOMRIGHT', 0 + dx, 0 + dy)

        local honorLevel = HonorLevelText
        honorLevel:ClearAllPoints()
        honorLevel:SetPoint('TOP', header, 'BOTTOM', 0, -10)
        honorLevel:SetDrawLayer('ARTWORK')
    end

    local frame = CharacterFrame
    frame:SetSize(338 - 2, 424)

    DragonflightUIMixin:AddNineSliceTextures(frame, true)
    DragonflightUIMixin:ButtonFrameTemplateNoPortrait(frame)
    DragonflightUIMixin:FrameBackgroundSolid(frame, true)

    local header = CharacterNameFrame
    header:ClearAllPoints()
    header:SetPoint('TOP', frame, 'TOP', 0, -5)
    header:SetPoint('LEFT', frame, 'LEFT', 60, 0)
    header:SetPoint('RIGHT', frame, 'RIGHT', -60, 0)

    local level = CharacterLevelText
    level:ClearAllPoints()
    level:SetPoint('TOP', header, 'BOTTOM', 0, -10)
    level:SetDrawLayer('ARTWORK')

    local closeButton = CharacterFrameCloseButton
    DragonflightUIMixin:UIPanelCloseButton(closeButton)
    closeButton:ClearAllPoints()
    closeButton:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', 1, 0)

    -- Portrait
    do
        local port = CharacterFramePortrait
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

    -- Background
    local inset = CreateFrame('Frame', 'DragonflightUICharacterFrameInset', frame, 'InsetFrameTemplate')
    inset:ClearAllPoints()
    inset:SetPoint('TOPLEFT', frame, 'TOPLEFT', 4, -60)
    inset:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMLEFT', 332, 4)
    frame.DFInset = inset

    frame.DFPaperDollArt = {}

    if PaperDollFrame then
        local function setPaperDollArtShown(shown)
            for _, piece in ipairs(frame.DFPaperDollArt) do piece:SetShown(shown) end
        end

        PaperDollFrame:HookScript('OnShow', function()
            setPaperDollArtShown(true)
            if frame.DFUpdateFrameWidth then frame:DFUpdateFrameWidth(frame.Expanded) end
        end)

        PaperDollFrame:HookScript('OnHide', function()
            setPaperDollArtShown(false)
            if frame.DFUpdateFrameWidth then frame:DFUpdateFrameWidth(false) end
        end)

        C_Timer.After(0, function() setPaperDollArtShown(PaperDollFrame:IsShown()) end)
    end

    -- Item Slots
    local head = CharacterHeadSlot
    head:SetPoint('TOPLEFT', inset, 'TOPLEFT', 4, -2)

    local hand = CharacterHandsSlot
    hand:ClearAllPoints()
    hand:SetPoint('TOPRIGHT', inset, 'TOPRIGHT', -4, -2)

    do
        local bg = inset:CreateTexture('DragonflightUICharacterPanelBackground', 'BACKGROUND', nil, 7)
        bg:SetTexture('Interface\\Addons\\DragonflightUI\\Textures\\uicharacterpanel2x')
        bg:SetTexCoord(1 / 1024, 451 / 1024, 1 / 512, 421 / 512)
        bg:SetAllPoints(inset)
        frame.DFPanelBackground = bg
        table.insert(frame.DFPaperDollArt, bg)
    end

    do
        local PARTS = 'Interface\\Addons\\DragonflightUI\\Textures\\charpaperdollparts'
        local PIECES = {
            left = {49, 44, 0.20703125, 0.39843750, 0.59375000, 0.93750000, 'TOPLEFT', -4, 0},
            right = {50, 44, 0.00390625, 0.19921875, 0.59375000, 0.93750000, 'TOPRIGHT', 4, 0},
            bottom = {42, 53, 0.67187500, 0.83593750, 0.00781250, 0.42187500, 'TOPLEFT', -4, 8}
        }
        local SLOTS = {
            Head = 'left', Neck = 'left', Shoulder = 'left', Back = 'left', Chest = 'left', Shirt = 'left',
            Tabard = 'left', Wrist = 'left', Hands = 'right', Waist = 'right', Legs = 'right', Feet = 'right',
            Finger0 = 'right', Finger1 = 'right', Trinket0 = 'right', Trinket1 = 'right', MainHand = 'bottom',
            SecondaryHand = 'bottom', Ranged = 'bottom'
        }
        for slotName, side in pairs(SLOTS) do
            local btn = _G['Character' .. slotName .. 'Slot']
            if btn and not btn.DFSlotFrame then
                local p = PIECES[side]
                local t = btn:CreateTexture(nil, 'BACKGROUND', nil, -1)
                t:SetTexture(PARTS)
                t:SetSize(p[1], p[2])
                t:SetTexCoord(p[3], p[4], p[5], p[6])
                t:SetPoint(p[7], btn, p[7], p[8], p[9])
                btn.DFSlotFrame = t

                local normal = btn:GetNormalTexture()
                if normal then normal:SetTexture(nil) end

                local pushed = btn:GetPushedTexture()
                if pushed then
                    pushed:SetTexture('Interface\\Buttons\\UI-Quickslot-Depress')
                    pushed:ClearAllPoints()
                    pushed:SetAllPoints(btn)
                end

                local high = btn:GetHighlightTexture()
                if high then
                    high:SetTexture('Interface\\Buttons\\ButtonHilight-Square')
                    high:SetBlendMode('ADD')
                    high:ClearAllPoints()
                    high:SetAllPoints(btn)
                end

                if side == 'bottom' then btn:SetFrameLevel(7) end

                if slotName == 'MainHand' then
                    local cap = btn:CreateTexture(nil, 'BACKGROUND', nil, -1)
                    cap:SetTexture(PARTS)
                    cap:SetSize(6, 54)
                    cap:SetTexCoord(0.70703125, 0.73046875, 0.4375, 0.859375)
                    cap:SetPoint('TOPRIGHT', t, 'TOPLEFT', 0, 0)
                elseif slotName == 'Ranged' then
                    local cap = btn:CreateTexture(nil, 'BACKGROUND', nil, -1)
                    cap:SetTexture(PARTS)
                    cap:SetSize(7, 54)
                    cap:SetTexCoord(0.671875, 0.69921875, 0.4375, 0.859375)
                    cap:SetPoint('TOPLEFT', t, 'TOPRIGHT', 0, 0)
                end
            end
        end

        local ammo = _G['CharacterAmmoSlot']
        if ammo then
            ammo:ClearAllPoints()
            ammo:SetPoint('LEFT', CharacterRangedSlot, 'RIGHT', 29.5, 0)
            for _, region in ipairs({ammo:GetRegions()}) do
                if region:GetObjectType() == 'Texture' and region:GetDrawLayer() == 'OVERLAY' then
                    local w, h = region:GetSize()
                    if math.abs(w - 23) < 1 and math.abs(h - 41) < 1 then
                        region:ClearAllPoints()
                        region:SetPoint('CENTER', ammo, 'CENTER', -28.5, 0)
                    end
                end
            end
        end
    end

    do
        local PARTS = 'Interface\\Addons\\DragonflightUI\\Textures\\charpaperdollparts'
        local HORIZ = 'Interface\\Addons\\DragonflightUI\\Textures\\charpaperdollhorizontal'
        local VERT = 'Interface\\Addons\\DragonflightUI\\Textures\\charpaperdollvertical'

        local function corner(l, r, t, b, point, x, y)
            local tex = inset:CreateTexture(nil, 'OVERLAY')
            tex:SetTexture(PARTS)
            tex:SetSize(7, 7)
            tex:SetTexCoord(l, r, t, b)
            tex:SetPoint(point, inset, point, x, y)
            return tex
        end
        local tl = corner(0.40625, 0.43359375, 0.8046875, 0.859375, 'TOPLEFT', 46, -4)
        local tr = corner(0.40625, 0.43359375, 0.734375, 0.7890625, 'TOPRIGHT', -47, -4)
        local bl = corner(0.40625, 0.43359375, 0.6640625, 0.71875, 'BOTTOMLEFT', 46, 31)
        local br = corner(0.40625, 0.43359375, 0.59375, 0.6484375, 'BOTTOMRIGHT', -47, 31)

        local left = inset:CreateTexture(nil, 'OVERLAY')
        left:SetTexture(VERT, 'CLAMP', 'REPEAT')
        if left.SetVertTile then left:SetVertTile(true) end
        left:SetWidth(5)
        left:SetTexCoord(0.0625, 0.375, 0, 1)
        left:SetPoint('TOPLEFT', tl, 'BOTTOMLEFT', -1, 0)
        left:SetPoint('BOTTOMLEFT', bl, 'TOPLEFT', -1, 0)

        local right = inset:CreateTexture(nil, 'OVERLAY')
        right:SetTexture(VERT, 'CLAMP', 'REPEAT')
        if right.SetVertTile then right:SetVertTile(true) end
        right:SetWidth(5)
        right:SetTexCoord(0.5, 0.8125, 0, 1)
        right:SetPoint('TOPRIGHT', tr, 'BOTTOMRIGHT', 1, 0)
        right:SetPoint('BOTTOMRIGHT', br, 'TOPRIGHT', 1, 0)

        local top = inset:CreateTexture(nil, 'OVERLAY')
        top:SetTexture(HORIZ, 'REPEAT', 'CLAMP')
        if top.SetHorizTile then top:SetHorizTile(true) end
        top:SetHeight(5)
        top:SetTexCoord(0, 1, 0.5, 0.8125)
        top:SetPoint('TOPLEFT', tl, 'TOPRIGHT', 0, 1)
        top:SetPoint('TOPRIGHT', tr, 'TOPLEFT', 0, 1)

        local bottom = inset:CreateTexture(nil, 'OVERLAY')
        bottom:SetTexture(HORIZ, 'REPEAT', 'CLAMP')
        if bottom.SetHorizTile then bottom:SetHorizTile(true) end
        bottom:SetHeight(5)
        bottom:SetTexCoord(0, 1, 0.0625, 0.375)
        bottom:SetPoint('BOTTOMLEFT', bl, 'BOTTOMRIGHT', 0, -1)
        bottom:SetPoint('BOTTOMRIGHT', br, 'BOTTOMLEFT', 0, -1)

        local bottom2 = inset:CreateTexture(nil, 'OVERLAY')
        bottom2:SetTexture(HORIZ, 'REPEAT', 'CLAMP')
        if bottom2.SetHorizTile then bottom2:SetHorizTile(true) end
        bottom2:SetHeight(5)
        bottom2:SetTexCoord(0, 1, 0.0625, 0.375)
        bottom2:SetPoint('BOTTOMLEFT', inset, 'BOTTOMLEFT', 0, 27)
        bottom2:SetPoint('BOTTOMRIGHT', inset, 'BOTTOMRIGHT', 0, 27)

        for _, piece in ipairs({tl, tr, bl, br, left, right, top, bottom, bottom2}) do
            table.insert(frame.DFPaperDollArt, piece)
        end
    end

    if DF.API.Version.IsWotlk then
        local equipManagerBtn = GearManagerToggleButton
        if equipManagerBtn then equipManagerBtn:ClearAllPoints() end

        local modelRotateRightBtn = CharacterModelFrameRotateRightButton
        if modelRotateRightBtn then
            modelRotateRightBtn:ClearAllPoints()
            modelRotateRightBtn:SetPoint("TOPLEFT", inset, "TOPLEFT", 40 + 10, -7)
        end

        local modelRotateLeftBtn = CharacterModelFrameRotateLeftButton
        if modelRotateLeftBtn then
            modelRotateLeftBtn:ClearAllPoints()
            modelRotateLeftBtn:SetPoint("TOPLEFT", inset, "TOPLEFT", 70 + 10, -7)
        end

        local magicRes = MagicResFrame1
        if magicRes then
            magicRes:ClearAllPoints()
            magicRes:SetPoint("TOPRIGHT", inset, "TOPRIGHT", -45, -10)
        end
    end

    -- Model
    local model = CharacterModelFrame
    model:SetPoint('TOPLEFT', PaperDollFrame, 'TOPLEFT', 52, -66)
    model:SetHeight(224 - 12)

    model:EnableMouseWheel(true)
    model:HookScript('OnMouseWheel', Model_OnMouseWheel)

    local res = CharacterResistanceFrame
    res:SetPoint('TOPRIGHT', PaperDollFrame, 'TOPLEFT', 297 - 10 + 2, -77 + 10 + 2)

    -- Attributes
    local att = CharacterAttributesFrame
    local attX = (inset:GetWidth() - att:GetWidth()) / 2
    att:SetPoint('TOPLEFT', PaperDollFrame, 'TOPLEFT', attX + 4, -291 + 12)

    local main = CharacterMainHandSlot
    main:ClearAllPoints()

    DragonflightUIMixin.WeaponRowAmmoX = 80
    DragonflightUIMixin.WeaponRowNoAmmoX = 108.5
    local function positionWeaponRow()
        local hasAmmo = _G['CharacterAmmoSlot'] and _G['CharacterAmmoSlot']:IsShown()
        main:ClearAllPoints()
        main:SetPoint('BOTTOMLEFT', PaperDollItemsFrame, 'BOTTOMLEFT',
                      hasAmmo and DragonflightUIMixin.WeaponRowAmmoX or DragonflightUIMixin.WeaponRowNoAmmoX, 16)
    end
    DragonflightUIMixin.PositionWeaponRow = positionWeaponRow
    if _G['CharacterAmmoSlot'] then
        _G['CharacterAmmoSlot']:HookScript('OnShow', positionWeaponRow)
        _G['CharacterAmmoSlot']:HookScript('OnHide', positionWeaponRow)
    end
    positionWeaponRow()

    -- tabs
    do
        for i = 1, 5 do
            local tab = _G['CharacterFrameTab' .. i]
            if tab then
                DragonflightUIMixin:CharacterFrameTabButtonTemplate(tab)
                tab.DFFirst = nil
                tab.DFChangePoint = nil
                tab.DFTabWidth = 62
            end
        end

        local updateTabs = function()
            local lastElem = nil
            local width = 79
            if _G['CharacterFrameTab2'] and _G['CharacterFrameTab2']:IsShown() then width = 62.4 end
            for i = 1, 5 do
                local tab = _G['CharacterFrameTab' .. i]
                if tab and (tab:IsShown()) then
                    tab:SetWidth(width)
                    tab:ClearAllPoints();
                    if lastElem then
                        tab:SetPoint('TOPLEFT', lastElem, 'TOPRIGHT', 4, 0)
                    else
                        tab:SetPoint('TOPLEFT', CharacterFrame, 'BOTTOMLEFT', 6, 1)
                    end
                    lastElem = tab
                end
            end
        end
        hooksecurefunc('ToggleCharacter', function(panel)
            updateTabs()
        end)
        if _G['CharacterFrameTab2'] then
            _G['CharacterFrameTab2']:HookScript('OnShow', updateTabs)
            _G['CharacterFrameTab2']:HookScript('OnHide', updateTabs)
        end
    end

    local PANEL_DEFAULT_WIDTH = frame:GetWidth();
    local CHARACTERFRAME_EXPANDED_WIDTH = 540;

    function frame:DFUpdateFrameWidth(expanded)
        local frameW = expanded and CHARACTERFRAME_EXPANDED_WIDTH or PANEL_DEFAULT_WIDTH;
        frame:SetWidth(frameW)
        frame:SetAttribute("UIPanelLayout-width", frameW);
        frame:SetAttribute("UIPanelLayout-" .. "xoffset", 0);
        frame:SetAttribute("UIPanelLayout-" .. "yoffset", 0);
        UpdateUIPanelPositions(frame)
    end

    frame:HookScript('OnShow', function()
        frame:DFUpdateFrameWidth(frame.Expanded)
    end)

    -- add characterstats panel + equipment manager
    if not DF.Cata and not DF.API.Version.IsMoP then
        local btn = CreateFrame('Button', 'DragonflightUICharacterFrameExpandButton', PaperDollFrame,
                                'DFCharacterFrameExpandButton')
        btn:SetPoint('BOTTOMRIGHT', CharacterFrame.DFInset, 'BOTTOMRIGHT', -2, -1)
        CharacterFrame.DFExpandButton = btn;

        local insetRight = CreateFrame('Frame', 'DragonflightUICharacterFrameInsetRight', PaperDollFrame,
                                       'InsetFrameTemplate')
        insetRight:ClearAllPoints()
        insetRight:SetPoint('TOPLEFT', CharacterFrame.DFInset, 'TOPRIGHT', 1, 0)
        insetRight:SetPoint('BOTTOMRIGHT', CharacterFrame, 'BOTTOMRIGHT', -4, 4)
        CharacterFrame.DFInsetRight = insetRight

        local statsTemplate
        if DF.API.Version.IsClassic then
            statsTemplate = 'DFCharacterStatsPanelEra';
        elseif DF.API.Version.IsTBC then
            statsTemplate = 'DFCharacterStatsPanelTbc';
        elseif DF.API.Version.IsWotlk then
            statsTemplate = 'DFCharacterStatsPanelWrath';
        end

        if statsTemplate then
            local p = CreateFrame('Frame', 'DragonflightUICharacterStatsPanel', insetRight, statsTemplate)
            p:SetSize(100, 100)
            p:SetPoint('TOPLEFT', insetRight, 'TOPLEFT', 3, -3)
            p:SetPoint('BOTTOMRIGHT', insetRight, 'BOTTOMRIGHT', -3, 2);
            p:Hide()
        end

        local titlePanel = CreateFrame('Frame', 'DragonflightUICharacterTitlePanel', insetRight)
        titlePanel:SetSize(100, 100)
        titlePanel:SetPoint('TOPLEFT', insetRight, 'TOPLEFT', 3, -3)
        titlePanel:SetPoint('BOTTOMRIGHT', insetRight, 'BOTTOMRIGHT', -3, 2);
        titlePanel:Hide()

        local equipmentPanel = CreateFrame('Frame', 'DragonflightUICharacterEquipmentManagerPanel', insetRight,
                                           'DFEquipmentManagerPanel')
        equipmentPanel:SetSize(100, 100)
        equipmentPanel:SetPoint('TOPLEFT', insetRight, 'TOPLEFT', 3, -3)
        equipmentPanel:SetPoint('BOTTOMRIGHT', insetRight, 'BOTTOMRIGHT', -3, 2);
        equipmentPanel:Hide()

        local sidebar = CreateFrame('Frame', 'DragonflightUICharacterFrameSidebar', insetRight,
                                    'DragonflightUISidebarTemplate')
        sidebar:SetPoint('BOTTOMRIGHT', insetRight, 'TOPRIGHT', -6, -1)
        sidebar:SetSize(168, 35)
        sidebar:SetSidebar(1)

        CharacterFrame:Expand()

        hooksecurefunc('ToggleCharacter', function(tab)
            if tab == 'PaperDollFrame' and frame.Expanded then
                frame:DFUpdateFrameWidth(true)
            else
                frame:DFUpdateFrameWidth(false)
            end
        end)

        local res = CharacterResistanceFrame
        res:ClearAllPoints()
        res:Hide()

        local att = CharacterAttributesFrame
        att:ClearAllPoints()
        att:Hide()

        model:SetPoint('TOPLEFT', PaperDollFrame, 'TOPLEFT', 52, -66)
        model:SetHeight(320 - 2)

        do
            local inset = CreateFrame('Frame', 'DragonflightUICharacterModelFrameInset', model, 'InsetFrameTemplate')
            inset:ClearAllPoints()
            inset:SetPoint('TOPLEFT', model, 'TOPLEFT', -0, 0)
            inset:SetPoint('BOTTOMRIGHT', model, 'BOTTOMRIGHT', 0, -0)
            inset:SetFrameLevel(3)

            _G[inset:GetName() .. 'Bg']:Hide()

            local tl = model:CreateTexture('DragonflightUIInspectModelFrame' .. 'TopLeft', 'BACKGROUND')
            tl:SetSize(212, 245)
            tl:SetPoint('TOPLEFT')
            tl:SetTexCoord(0.171875, 1, 0.0392156862745098, 1)

            local tr = model:CreateTexture('DragonflightUIInspectModelFrame' .. 'TopRight', 'BACKGROUND')
            tr:SetSize(19, 245)
            tr:SetPoint('TOPLEFT', tl, 'TOPRIGHT')
            tr:SetTexCoord(0, 0.296875, 0.0392156862745098, 1)

            local delta = 55

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

            backgroundDesaturate(true)
            updateBackground('player')
        end
    end

    -- rep
    do
        if DF.Wrath then
            local regions = {ReputationFrame:GetRegions()}
            for k, child in ipairs(regions) do
                if child:GetObjectType() == 'Texture' then
                    local layer, layerNr = child:GetDrawLayer()
                    if layer == 'BACKGROUND' then child:Hide() end
                end
            end
        end

        local rep = ReputationFrame

        local factionLabel = ReputationFrameFactionLabel
        factionLabel:SetPoint('TOPLEFT', rep, 'TOPLEFT', 70, -42)

        local standingLabel = ReputationFrameStandingLabel
        standingLabel:SetPoint('TOPLEFT', rep, 'TOPLEFT', 215, -42)

        local scroll = ReputationListScrollFrame
        scroll:ClearAllPoints()
        scroll:SetPoint('TOPLEFT', inset, 'TOPLEFT', 0, 0)
        scroll:SetWidth(300)

        local function UpdateRepulationBarsPos()
            local first = ReputationBar1
            if first then
                first:ClearAllPoints()
                first:SetPoint('TOPRIGHT', inset, 'TOPRIGHT', -50, -10)
            end
        end

        if DF.Wrath and not DF.Cata then
            scroll:HookScript("OnShow", UpdateRepulationBarsPos)
            scroll:HookScript("OnHide", UpdateRepulationBarsPos)
        else
            UpdateRepulationBarsPos()
        end

        local detail = ReputationDetailFrame
        detail:SetPoint('TOPLEFT', rep, 'TOPRIGHT', 0, -13)

        local btn = ReputationDetailCloseButton
        DragonflightUIMixin:UIPanelCloseButton(btn)
        btn:SetPoint('TOPRIGHT', detail, 'TOPRIGHT', -5, -6)
    end

    -- pet
    do
        local regions = {PetPaperDollFrame:GetRegions()}
        for k, child in ipairs(regions) do
            if child:GetObjectType() == 'Texture' then
                local layer, layerNr = child:GetDrawLayer()
                if layer == 'BORDER' then child:Hide() end
                if DF.Wrath and not DF.Cata then if layer == 'BACKGROUND' then child:Hide() end end
            end
        end

        local model = PetModelFrame
        model:SetPoint('TOPLEFT', PetPaperDollFrame, 'TOPLEFT', 9, -66)

        local rotateleft = PetModelFrameRotateLeftButton
        if rotateleft then
            rotateleft:ClearAllPoints()
            rotateleft:SetPoint('TOPLEFT', model, 'TOPLEFT', 0, 0)
        end

        local rotate = PetModelFrameRotateRightButton
        if rotate then
            rotate:ClearAllPoints()
            rotate:SetPoint('TOPLEFT', rotateleft or model, 'TOPRIGHT', 0, 0)
        end

        local res = PetResistanceFrame
        if res then
            res:ClearAllPoints()
            res:SetPoint('TOPRIGHT', model, 'TOPRIGHT', 0, 0)
        end

        local att = PetAttributesFrame
        if att then
            local attX = (inset:GetWidth() - att:GetWidth()) / 2
            att:SetPoint('TOPLEFT', PetPaperDollFrame, 'TOPLEFT', attX + 4, -300 + 10)
        end

        local expBar = PetPaperDollFrameExpBar
        if expBar then
            expBar:ClearAllPoints()
            expBar:SetPoint('BOTTOM', PetPaperDollFrame, 'BOTTOM', 0, 36)
        end

        local close = PetPaperDollCloseButton
        if close then
            close:ClearAllPoints()
            close:SetPoint('BOTTOMRIGHT', PetPaperDollFrame, 'BOTTOMRIGHT', -9, 7)
            close:Hide()
        end

        local newMoney = CreateFrame('FRAME', 'DFPetTrainingPointsFrame', PetPaperDollFrame)
        newMoney:SetHeight(22)
        newMoney:SetPoint('BOTTOMLEFT', PetPaperDollFrame, 'BOTTOMLEFT', 9, 7)
        if close then newMoney:SetPoint('RIGHT', close, 'LEFT', 0, 0) end

        local border = CreateFrame('FRAME', 'DFMoneyBorder', newMoney, 'ContainerMoneyFrameBorderTemplate')
        border:SetParent(newMoney)
        border:SetAllPoints()

        local trainingFrame = CreateFrame('FRAME', 'DFPetTrainingPointsFrameS', PetPaperDollFrame)
        trainingFrame:SetHeight(22)
        trainingFrame:SetWidth(newMoney:GetWidth())
        trainingFrame:SetPoint('CENTER', newMoney, 'CENTER', 0, 0)
        trainingFrame:SetFrameLevel(10)

        if PetTrainingPointText then
            local trainPoint = PetTrainingPointText
            trainPoint:ClearAllPoints()
            trainPoint:SetPoint('RIGHT', trainingFrame, 'RIGHT', -16, 0)
            trainPoint:SetDrawLayer('OVERLAY', 5)
            trainPoint:SetParent(trainingFrame)

            PetTrainingPointLabel:SetDrawLayer('OVERLAY', 5)
            PetTrainingPointLabel:SetParent(trainingFrame)
        end

        local nameFrame = CreateFrame('FRAME', 'DragonflightUIPetNameFrame', PetPaperDollFrame)
        nameFrame:SetPoint('TOP', PetPaperDollFrame, 'TOP', 0, -5)
        nameFrame:SetPoint('LEFT', PetPaperDollFrame, 'LEFT', 60, 0)
        nameFrame:SetPoint('RIGHT', PetPaperDollFrame, 'RIGHT', -60, 0)
        nameFrame:SetHeight(12)

        local headerPet = PetNameText
        if headerPet then
            headerPet:ClearAllPoints()
            headerPet:SetPoint('CENTER', nameFrame, 'CENTER', 0, 0)
            headerPet:SetDrawLayer('ARTWORK')
        end

        local levelPet = PetLevelText
        if levelPet then
            levelPet:ClearAllPoints()
            levelPet:SetPoint('TOP', nameFrame, 'BOTTOM', 0, -10)
            levelPet:SetDrawLayer('ARTWORK')
        end

        if PetLoyaltyText then
            local loyal = PetLoyaltyText
            loyal:ClearAllPoints()
            loyal:SetPoint('TOP', levelPet, 'BOTTOM', 0, -1)
            loyal:SetDrawLayer('ARTWORK')
        end
    end

    -- skills
    do
        local skills = SkillFrame

        local scroll = SkillListScrollFrame
        if scroll then
            scroll:ClearAllPoints()
            scroll:SetPoint('TOPLEFT', inset, 'TOPLEFT', 0, 0)
            scroll:SetWidth(300)
        end

        local first = SkillTypeLabel1
        if first and skills then
            first:SetPoint('LEFT', skills, 'TOPLEFT', 22 - 16, -86)
        end

        local expand = SkillFrameExpandButtonFrame
        if expand and skills then
            expand:SetPoint('TOPLEFT', skills, 'TOPLEFT', 70 - 10, -49 + 14)
        end

        for i = 1, 15 do
            local sr = _G['SkillRankFrame' .. i]
            local border = _G['SkillRankFrame' .. i .. 'Border']
            if sr then
                sr:SetWidth(271 - 11)
                border:SetWidth(281 - 11)
            end
        end

        local cancel = SkillFrameCancelButton
        if cancel and skills then
            cancel:ClearAllPoints()
            cancel:SetPoint('BOTTOMRIGHT', skills, 'BOTTOMRIGHT', -9 - 26, 7)
            cancel:Hide()
        end

        local dividerLeft = SkillFrameHorizontalBarLeft
        if dividerLeft and skills then
            dividerLeft:SetPoint('TOPLEFT', skills, 'TOPLEFT', 15 - 10, -290)
            dividerLeft:SetWidth(256 - 6)
        end

        local detail = SkillDetailScrollFrame
        if detail and scroll then
            detail:SetPoint('TOPLEFT', scroll, 'BOTTOMLEFT', 0, -8 - 10)
            detail:SetWidth(300)
        end
    end

    -- token
    do
        if DF.Wrath and not DF.Cata then
            local token = TokenFrame

            local container = TokenFrameContainer
            if container and token then
                container:ClearAllPoints()
                container:SetPoint('TOPLEFT', token, 'TOPLEFT', 12, -63)
            end

            local pop = TokenFramePopup
            if pop and token then
                pop:ClearAllPoints()
                pop:SetPoint('TOPLEFT', token, 'TOPRIGHT', 0, 0)
            end

            local money = TokenFrameMoneyFrame
            if money and token then
                money:ClearAllPoints()
                money:SetPoint('BOTTOMRIGHT', token, 'BOTTOMRIGHT', 6, 6)
            end

            local cancel = TokenFrameCancelButton
            if cancel and token then
                cancel:ClearAllPoints()
                cancel:SetPoint('BOTTOMRIGHT', token, 'BOTTOMRIGHT', -9 - 26, 7)
                cancel:Hide()
            end

            if token then
                local children = {token:GetChildren()}
                for i, child in ipairs(children) do
                    local name = child:GetName()
                    if not name then child:Hide() end
                end
            end
        end
    end
end

function DragonflightUIMixin:ChangeCharacterFrameCata()
    DragonflightUIMixin:PortraitFrameTemplate(CharacterFrame)

    CharacterFrameBg:SetTexture(base .. 'ui-background-rock')
    CharacterFrameBg:ClearAllPoints()
    CharacterFrameBg:SetPoint('TOPLEFT', CharacterFrame, 'TOPLEFT', 3, -18)
    CharacterFrameBg:SetPoint('BOTTOMRIGHT', CharacterFrame, 'BOTTOMRIGHT', 0, 3)

    if DF.API.Version.IsCata then
        local main = _G['CharacterMainHandSlot']
        if main then
            main:ClearAllPoints()
            local x = (328 / 2) + 4 - 1.5 * main:GetWidth() - 5
            main:SetPoint('BOTTOMLEFT', PaperDollItemsFrame, 'BOTTOMLEFT', x, 16)
        end
    end
end
