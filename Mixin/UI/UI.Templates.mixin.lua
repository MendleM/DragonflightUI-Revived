local addonName, addonTable = ...;
local Helper = addonTable.Helper;
---@diagnostic disable: undefined-global
---@class DragonflightUI
---@diagnostic disable-next-line: assign-type-mismatch
local DF = LibStub('AceAddon-3.0'):GetAddon('DragonflightUI')

DragonflightUIMixin = DragonflightUIMixin or {}

local base = 'Interface\\Addons\\DragonflightUI\\Textures\\UI\\'

function DragonflightUIMixin:UIPanelCloseButton(btn)
    local tex = base .. 'redbutton2x'

    btn:SetSize(24, 24)

    local normal = btn:GetNormalTexture()
    if normal then
        normal:SetTexture(tex)
        normal:SetTexCoord(0.152344, 0.292969, 0.0078125, 0.304688)
    end

    local disabled = btn:GetDisabledTexture()
    if disabled then
        disabled:SetTexture(tex)
        disabled:SetTexCoord(0.152344, 0.292969, 0.320312, 0.617188)
    end

    local pushed = btn:GetPushedTexture()
    if pushed then
        pushed:SetTexture(tex)
        pushed:SetTexCoord(0.152344, 0.292969, 0.632812, 0.929688)
    end

    local highlight = btn:GetHighlightTexture()
    if highlight then
        highlight:SetTexture(tex)
        highlight:SetTexCoord(0.449219, 0.589844, 0.0078125, 0.304688)
    end
end

function DragonflightUIMixin:MaximizeMinimizeButtonFrameTemplate(btn)
    local tex = base .. 'redbutton2x'

    btn:SetSize(24, 24)
    do
        local ref = btn.MaximizeButton
        if ref then
            local normal = ref:GetNormalTexture()
            if normal then
                normal:SetTexture(tex)
                normal:SetTexCoord(0.300781, 0.441406, 0.0078125, 0.304688)
            end

            local disabled = ref:GetDisabledTexture()
            if disabled then
                disabled:SetTexture(tex)
                disabled:SetTexCoord(0.300781, 0.441406, 0.320312, 0.617188)
            end

            local pushed = ref:GetPushedTexture()
            if pushed then
                pushed:SetTexture(tex)
                pushed:SetTexCoord(0.300781, 0.441406, 0.632812, 0.929688)
            end

            local highlight = ref:GetHighlightTexture()
            if highlight then
                highlight:SetTexture(tex)
                highlight:SetTexCoord(0.449219, 0.589844, 0.0078125, 0.304688)
            end
        end
    end

    do
        local ref = btn.MinimizeButton
        if ref then
            local normal = ref:GetNormalTexture()
            if normal then
                normal:SetTexture(tex)
                normal:SetTexCoord(0.00390625, 0.144531, 0.0078125, 0.304688)
            end

            local disabled = ref:GetDisabledTexture()
            if disabled then
                disabled:SetTexture(tex)
                disabled:SetTexCoord(0.00390625, 0.144531, 0.320312, 0.617188)
            end

            local pushed = ref:GetPushedTexture()
            if pushed then
                pushed:SetTexture(tex)
                pushed:SetTexCoord(0.00390625, 0.144531, 0.632812, 0.929688)
            end

            local highlight = ref:GetHighlightTexture()
            if highlight then
                highlight:SetTexture(tex)
                highlight:SetTexCoord(0.449219, 0.589844, 0.0078125, 0.304688)
            end
        end
    end
end

function DragonflightUIMixin:AddNineSliceTextures(frame, portrait)
    if frame.NineSlice then return end

    frame.NineSlice = {}
    local slice = frame.NineSlice

    slice.TopLeftCorner = frame:CreateTexture(nil)
    slice.TopRightCorner = frame:CreateTexture(nil)
    slice.BottomLeftCorner = frame:CreateTexture(nil)
    slice.BottomRightCorner = frame:CreateTexture(nil)

    slice.TopEdge = frame:CreateTexture(nil)
    slice.BottomEdge = frame:CreateTexture(nil)

    slice.LeftEdge = frame:CreateTexture(nil)
    slice.RightEdge = frame:CreateTexture(nil)

    frame.Bg = CreateFrame('FRAME', nil, frame, 'FlatPanelBackgroundTemplate')
    frame.Bg:SetPoint('TOPLEFT', frame, 'TOPLEFT', 7, -18)
    frame.Bg:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', -3, 3)
    frame.Bg:SetFrameLevel(0)

    if portrait then frame.PortraitFrame = frame:CreateTexture('PortraitFrame') end
end

function DragonflightUIMixin:FrameBackgroundSolid(frame, streak)
    if not frame or not frame.Bg then return end
    local top = frame.Bg.TopSection
    if not top then return end

    top:SetTexture(base .. 'ui-background-rock')
    top:ClearAllPoints()
    top:SetPoint('TOPLEFT', frame.Bg, 'TOPLEFT', 0, 0)
    top:SetPoint('BOTTOMRIGHT', frame.Bg.BottomRight, 'BOTTOMRIGHT', 0, 0)
    top:SetDrawLayer('BACKGROUND', 2)

    if streak then
        local TopTileStreak = _G[frame:GetName() .. 'TopTileStreaks'] or frame:CreateTexture()
        TopTileStreak:ClearAllPoints()
        TopTileStreak:SetSize(256, 43)
        TopTileStreak:SetTexture(base .. 'uiframehorizontal')
        TopTileStreak:SetTexCoord(0, 1, 0.0078125, 0.34375)
        TopTileStreak:SetPoint('TOPLEFT', 6, -21)
        TopTileStreak:SetPoint('TOPRIGHT', -2, -21)
    end
end

function DragonflightUIMixin:FrameBackgroundSolidMoP(frame, streak)
    if not frame then return end
    local bg = _G[frame:GetName() .. 'Bg']
    if not bg then return end

    bg:SetTexture(base .. 'ui-background-rock')
    bg:SetDrawLayer('BACKGROUND', -2)

    if streak then
        local TopTileStreak = _G[frame:GetName() .. 'TopTileStreaks'] or frame:CreateTexture()
        TopTileStreak:SetSize(256, 43)
        TopTileStreak:SetTexture(base .. 'uiframehorizontal')
        TopTileStreak:SetTexCoord(0, 1, 0.0078125, 0.34375)
        TopTileStreak:SetPoint('TOPLEFT', 6, -21)
        TopTileStreak:SetPoint('TOPRIGHT', -2, -21)
    end
end

function DragonflightUIMixin:ButtonFrameTemplateNoPortrait(frame)
    local slice = frame.NineSlice
    if not slice then return end

    if slice.TopLeftCorner then
        local tex = base .. 'uiframemetal2x'

        local tlc = slice.TopLeftCorner
        tlc:ClearAllPoints()
        tlc:SetTexture(tex)
        tlc:SetTexCoord(0.00195312, 0.294922, 0.00195312, 0.294922)
        tlc:SetSize(75, 74)
        tlc:SetPoint('TOPLEFT', -12, 16)

        local trc = slice.TopRightCorner
        trc:ClearAllPoints()
        trc:SetTexture(tex)
        trc:SetTexCoord(0.298828, 0.591797, 0.00195312, 0.294922)
        trc:SetSize(75, 74)
        trc:SetPoint('TOPRIGHT', 4, 16)

        local blc = slice.BottomLeftCorner
        blc:ClearAllPoints()
        blc:SetTexture(tex)
        blc:SetTexCoord(0.298828, 0.423828, 0.298828, 0.423828)
        blc:SetSize(32, 32)
        blc:SetPoint('BOTTOMLEFT', -12, -3)

        local brc = slice.BottomRightCorner
        brc:ClearAllPoints()
        brc:SetTexture(tex)
        brc:SetTexCoord(0.427734, 0.552734, 0.298828, 0.423828)
        brc:SetSize(32, 32)
        brc:SetPoint('BOTTOMRIGHT', 4, -3)
    end

    if slice.TopEdge then
        local tex = base .. 'UIFrameMetalHorizontal2x'

        local te = slice.TopEdge
        te:ClearAllPoints()
        te:SetTexture(tex)
        te:SetTexCoord(0, 1, 0.00390625, 0.589844)
        te:SetSize(32, 74)
        te:SetPoint('TOPLEFT', slice.TopLeftCorner, 'TOPRIGHT', 0, 0)
        te:SetPoint('TOPRIGHT', slice.TopRightCorner, 'TOPLEFT', 0, 0)

        local be = slice.BottomEdge
        be:ClearAllPoints()
        be:SetTexture(tex)
        be:SetTexCoord(0, 0.5, 0.597656, 0.847656)
        be:SetSize(16, 32)
        be:SetPoint('TOPLEFT', slice.BottomLeftCorner, 'TOPRIGHT', 0, 0)
        be:SetPoint('TOPRIGHT', slice.BottomRightCorner, 'TOPLEFT', 0, 0)
    end

    if slice.LeftEdge then
        local tex = base .. 'UIFrameMetalVertical2x'

        local le = slice.LeftEdge
        le:SetTexture(tex)
        le:SetTexCoord(0.00195312, 0.294922, 0, 1)
        le:SetSize(75, 16)
        le:SetPoint('TOPLEFT', slice.TopLeftCorner, 'BOTTOMLEFT', 0, 0)
        le:SetPoint('BOTTOMLEFT', slice.BottomLeftCorner, 'TOPLEFT', 0, 0)

        local re = slice.RightEdge
        re:SetTexture(tex)
        re:SetTexCoord(0.298828, 0.591797, 0, 1)
        re:SetSize(75, 16)
        re:SetPoint('TOPRIGHT', slice.TopRightCorner, 'BOTTOMRIGHT', 0, 0)
        re:SetPoint('BOTTOMRIGHT', slice.BottomRightCorner, 'TOPRIGHT', 0, 0)
    end

    local bg = frame.Bg
    if bg then bg:SetPoint('TOPLEFT', frame, 'TOPLEFT', 3, -18) end

    local closeBtn = frame.ClosePanelButton
    if closeBtn then
        DragonflightUIMixin:UIPanelCloseButton(closeBtn)
        closeBtn:SetPoint('TOPRIGHT', 1, 0)
    end
end

function DragonflightUIMixin:PortraitFrameTemplate(frame)
    local name = frame:GetName()
    if not name then return end

    do
        local tex = base .. 'uiframemetal2x'
        local port = _G[name .. 'Portrait']
        if port then
            port:SetSize(62, 62)
            port:ClearAllPoints()
            port:SetPoint('TOPLEFT', -5, 7)
            port:SetDrawLayer('OVERLAY', 6)

            local pp = _G[name .. 'PortraitFrame'] or frame.PortraitFrame
            if pp then
                pp:SetTexture(tex)
                pp:SetTexture(base .. 'UI-Frame-PortraitMetal-CornerTopLeft')
                pp:SetSize(84, 84)
                pp:ClearAllPoints()
                pp:SetPoint('CENTER', port, 'CENTER', 0, 0)
                pp:SetDrawLayer('OVERLAY', 7)
            end

            local icon = _G[name .. 'Icon']
            if icon then
                icon:SetSize(62, 62)
                icon:ClearAllPoints()
                icon:SetPoint('TOPLEFT', -5, 7)
                icon:SetDrawLayer('OVERLAY', 6)
            end
        end
    end

    do
        local tex = base .. 'uiframemetal2x'

        local tlc = _G[name .. 'TopLeftCorner']
        if tlc then
            tlc:SetTexture(tex)
            tlc:SetTexCoord(0.00195312, 0.294922, 0.00195312, 0.294922)
            tlc:SetSize(75, 74)
            tlc:SetPoint('TOPLEFT', -12, 16)
        end

        local tlcDF = frame:CreateTexture(name .. 'TopLeftCornerDF', 'OVERLAY')
        tlcDF:SetTexture(tex)
        tlcDF:SetTexCoord(0.00195312, 0.294922, 0.00195312, 0.294922)
        tlcDF:SetSize(75, 74)
        tlcDF:SetPoint('TOPLEFT', -13, 16)
        tlcDF:SetDrawLayer('ARTWORK', 0)

        local trc = _G[name .. 'TopRightCorner'] or frame.TopRightCorner
        if trc then
            trc:SetTexture(tex)
            trc:SetTexCoord(0.298828, 0.591797, 0.00195312, 0.294922)
            trc:SetSize(75, 74)
            trc:SetPoint('TOPRIGHT', 4, 16)
        end

        local blc = _G[name .. 'BotLeftCorner'] or frame.BotLeftCorner
        if blc then
            blc:SetTexture(tex)
            blc:SetTexCoord(0.298828, 0.423828, 0.298828, 0.423828)
            blc:SetSize(32, 32)
            blc:SetPoint('BOTTOMLEFT', -13, -3)
        end

        local brc = _G[name .. 'BotRightCorner'] or frame.BotRightCorner
        if brc then
            brc:SetTexture(tex)
            brc:SetTexCoord(0.427734, 0.552734, 0.298828, 0.423828)
            brc:SetSize(32, 32)
            brc:SetPoint('BOTTOMRIGHT', 4, -3)
        end

        local brcFake = _G[name .. 'BtnCornerRight']
        if brcFake then brcFake:SetAlpha(0) end

        local blcFake = _G[name .. 'BtnCornerLeft']
        if blcFake then blcFake:SetAlpha(0) end
    end

    do
        local tex = base .. 'UIFrameMetalHorizontal2x'

        local te = _G[name .. 'TopBorder'] or frame.TopBorder
        if te and _G[name .. 'TopLeftCornerDF'] and _G[name .. 'TopRightCorner'] then
            te:SetTexture(tex)
            te:SetTexCoord(0, 1, 0.00390625, 0.589844)
            te:SetSize(32, 74)
            te:ClearAllPoints()
            te:SetPoint('TOPLEFT', _G[name .. 'TopLeftCornerDF'], 'TOPRIGHT', 0, 0)
            te:SetPoint('TOPRIGHT', _G[name .. 'TopRightCorner'], 'TOPLEFT', 0, 0)
        end

        local be = _G[name .. 'BottomBorder'] or frame.BottomBorder
        if be then
            be:SetTexture(tex)
            be:SetTexCoord(0, 0.5, 0.597656, 0.847656)
            be:SetSize(16, 32)
        end

        local beFake = _G[name .. 'ButtonBottomBorder']
        if beFake then beFake:SetAlpha(0) end
    end

    do
        local tex = base .. 'UIFrameMetalVertical2x'

        local le = _G[name .. 'LeftBorder'] or frame.LeftBorder
        local tlc = _G[name .. 'TopLeftCornerDF']
        if le and tlc then
            le:SetTexture(tex)
            le:SetTexCoord(0.00195312, 0.294922, 0, 1)
            le:SetSize(75, 16)
            le:SetPoint('TOPLEFT', tlc, 'BOTTOMLEFT', 0, 0)
        end

        local re = _G[name .. 'RightBorder'] or frame.RightBorder
        if re and _G[name .. 'TopRightCorner'] and _G[name .. 'BotRightCorner'] then
            re:SetTexture(tex)
            re:SetTexCoord(0.298828, 0.591797, 0, 1)
            re:SetSize(75, 16)
            re:SetPoint('TOPRIGHT', _G[name .. 'TopRightCorner'], 'BOTTOMRIGHT', 0, 0)
            re:SetPoint('BOTTOMRIGHT', _G[name .. 'BotRightCorner'], 'TOPRIGHT', 0, 0)
        end
    end

    local closeBtn = _G[name .. 'CloseButton']
    if closeBtn then
        DragonflightUIMixin:UIPanelCloseButton(closeBtn)
        closeBtn:SetPoint('TOPRIGHT', 1, 0)
    end

    for i = 1, 5 do
        local tab = _G[name .. 'TabButton' .. i]
        if tab then
            DragonflightUIMixin:CharacterFrameTabButtonTemplate(tab)
            if i == 1 then
                tab.DFFirst = true
                tab.DFFirstOffsetY = 2;
            elseif i > 1 then
                tab.DFChangePoint = true
            end
        end
    end

    for i = 1, 5 do
        local tab = _G[name .. 'Tab' .. i]
        if tab and name ~= 'MacroFrame' then
            DragonflightUIMixin:CharacterFrameTabButtonTemplate(tab)
            if i == 1 then
                tab.DFFirst = true
            elseif i > 1 then
                tab.DFChangePoint = true
            end
        end
    end

    if name == 'SpellBookFrame' then
        local setTabWidths = function()
            for i = 1, 5 do
                local tab = _G['SpellBookFrameTabButton' .. i]
                if tab then
                    local text = _G['SpellBookFrameTabButton' .. i .. 'Text']
                    if text then
                        tab.DFTabWidth = math.max(text:GetWrappedWidth() + 16, 78)
                        tab:SetWidth(tab.DFTabWidth)
                    end
                end
            end
        end

        if SpellBookFrame_Update then
            hooksecurefunc('SpellBookFrame_Update', function()
                setTabWidths()
            end)
        end

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

        hooksecurefunc('ToggleSpellBook', function(panel)
            if panel == 'spell' and _G[name .. 'TabButton1'] then
                _G[name .. 'TabButton1']:Disable()
            elseif panel == 'professions' and _G[name .. 'TabButton2'] then
                _G[name .. 'TabButton2']:Disable()
            elseif panel == 'pet' and _G[name .. 'TabButton3'] then
                _G[name .. 'TabButton3']:Disable()
            end
        end)
    elseif name == 'CharacterFrame' then
        for i = 1, 5 do
            local tab = _G[name .. 'Tab' .. i]
            if tab then
                tab.DFFirst = nil
                tab.DFChangePoint = nil
            end
        end

        local updateTabs = function()
            local lastElem = nil
            for i = 1, 5 do
                local tab = _G[name .. 'Tab' .. i]
                if tab and (tab:IsShown()) then
                    local text = _G[name .. 'Tab' .. i .. 'Text']
                    if text then
                        tab:SetWidth(math.max(text:GetWrappedWidth() + 16, 78))
                    end
                    tab:ClearAllPoints();
                    if lastElem then
                        tab:SetPoint('TOPLEFT', lastElem, 'TOPRIGHT', 4, 0)
                    else
                        tab:SetPoint('TOPLEFT', CharacterFrame, 'BOTTOMLEFT', 12, 1)
                    end
                    lastElem = tab
                end
            end
        end
        hooksecurefunc('ToggleCharacter', function(panel)
            updateTabs()
        end)
        if _G[name .. 'Tab' .. 2] then
            _G[name .. 'Tab' .. 2]:HookScript('OnShow', updateTabs)
            _G[name .. 'Tab' .. 2]:HookScript('OnHide', updateTabs)
        end
    elseif name == 'PlayerTalentFrame' then
        for i = 1, 5 do
            local tab = _G[name .. 'Tab' .. i]
            if tab then
                if i == 1 then
                    tab.DFFirst = true
                elseif i > 1 then
                    tab.DFChangePoint = false
                end
                DragonflightUIMixin:TabResize(tab)
            end
        end
        hooksecurefunc('PlayerTalentFrame_UpdateTabs', function()
            local lastElem = nil
            for i = 1, (NUM_TALENT_FRAME_TABS or 3) do
                local tab = _G["PlayerTalentFrameTab" .. i];
                if tab and (tab:IsShown()) then
                    DragonflightUIMixin:ResizeTab(tab, nil, nil, 70)
                    tab:ClearAllPoints();
                    if lastElem then
                        tab:SetPoint('TOPLEFT', lastElem, 'TOPRIGHT', 4, 0)
                    else
                        tab:SetPoint('TOPLEFT', PlayerTalentFrame, 'BOTTOMLEFT', 12, 2)
                    end
                    lastElem = tab
                end
            end
        end)
    elseif name == 'CollectionsJournal' then
        for i = 1, 5 do
            local tab = _G[name .. 'Tab' .. i]
            if tab then
                DragonflightUIMixin:TabResize(tab)
            end
        end
    elseif name == 'CommunitiesFrame' then
        local bg = _G['CommunitiesFrameBg']
        if bg then
            bg:SetTexture(base .. 'ui-background-rock')
            bg:ClearAllPoints()
            bg:SetPoint('TOPLEFT', CommunitiesFrame, 'TOPLEFT', 3, -18)
            bg:SetPoint('BOTTOMRIGHT', CommunitiesFrame, 'BOTTOMRIGHT', 0, 3)
        end

        local fixTop = function()
            local te = _G[name .. 'TopBorder']
            if te and _G[name .. 'TopLeftCornerDF'] and _G[name .. 'TopRightCorner'] then
                te:ClearAllPoints()
                te:SetPoint('TOPLEFT', _G[name .. 'TopLeftCornerDF'], 'TOPRIGHT', 0, 0)
                te:SetPoint('TOPRIGHT', _G[name .. 'TopRightCorner'], 'TOPLEFT', 0, 0)
            end
        end
        frame:HookScript('OnShow', function()
            fixTop()
        end)

        local minBtn = frame.MaximizeMinimizeFrame
        if minBtn then DragonflightUIMixin:MaximizeMinimizeButtonFrameTemplate(minBtn) end
        frame:HookScript('OnSizeChanged', fixTop)
    elseif name == 'EncounterJournal' then
        local dung = _G[name .. 'DungeonTab']
        if dung then
            dung:ClearAllPoints()
            dung:SetAlpha(0)

            local newDung = CreateFrame('BUTTON', 'DragonflightUIEncounterJournalDungeonTab', frame, 'DFDungeonTab')
            newDung:Show()
            newDung:SetPoint('TOPLEFT', frame, 'BOTTOMLEFT', 12, 1)
            newDung:GetFontString():SetText(DUNGEONS)
            DragonflightUIMixin:CharacterFrameTabButtonTemplate(newDung, true)
        end

        local raid = _G[name .. 'RaidTab']
        if raid and _G['DragonflightUIEncounterJournalDungeonTab'] then
            raid:ClearAllPoints()
            raid:SetAlpha(0)
            raid:EnableMouse(false)

            local newRaid = CreateFrame('BUTTON', 'DragonflightUIEncounterJournalRaidTab', frame, 'DFRaidTab')
            newRaid:Show()
            newRaid:SetPoint('TOPLEFT', _G['DragonflightUIEncounterJournalDungeonTab'], 'TOPRIGHT', 4, 0)
            newRaid:GetFontString():SetText(RAIDS)
            DragonflightUIMixin:CharacterFrameTabButtonTemplate(newRaid, true)
        end
    elseif name == 'MacroFrame' then
        local children = {frame:GetRegions()}
        for k, child in ipairs(children) do
            if child:GetObjectType() == 'Texture' then
                local tex = child:GetTexture()
                if tex == 136377 then
                    child:SetSize(62, 62)
                    child:ClearAllPoints()
                    child:SetPoint('TOPLEFT', -5, 7)
                    child:SetDrawLayer('OVERLAY', 6)
                    SetPortraitToTexture(child, child:GetTexture())
                end
            end
        end
    elseif name == 'FriendsFrame' then
        if DF.Era then
            for i = 1, 5 do
                local tab = _G[name .. 'Tab' .. i]
                if tab then
                    tab.DFFirstOffsetX = 4
                    tab.DFTabWidth = 62.8

                    if i == 1 then
                        tab:ClearAllPoints()
                        tab:SetPoint('TOPLEFT', FriendsFrame, 'BOTTOMLEFT', 6, -1)
                    end

                    if i == 4 then
                        local text = _G['FriendsFrameTab' .. i .. 'Text']
                        if text and text:GetWrappedWidth() > 24 then
                            tab.DFTabWidth = math.min(text:GetWrappedWidth() + 16, 84)
                        end
                    end

                    if i == 5 then
                        local tabHigh = _G[name .. 'Tab' .. i .. 'HighlightTexture']
                        if tabHigh then tabHigh:Hide() end
                    end
                end
            end

            hooksecurefunc('FriendsFrame_Update', function()
                if FriendsFrame and FriendsFrame.TitleText then FriendsFrame.TitleText:Hide() end
            end)

            local originalGuild = _G[name .. 'Tab' .. 3];
            if originalGuild then
                local newGuildBtn = CreateFrame('Button', 'DragonflightUIFixedGuildButton', FriendsFrame,
                                                'DFGuildTab, SecureActionButtonTemplate')

                DragonflightUIMixin:CharacterFrameTabButtonTemplate(newGuildBtn, true, true)
                newGuildBtn.DFFirstOffsetX = 4
                newGuildBtn.DFTabWidth = 62.8
                DragonflightUIMixin:TabResize(newGuildBtn)

                local dx = newGuildBtn.DFFirstOffsetX + 2 * newGuildBtn.DFTabWidth + 2 * 4

                newGuildBtn:ClearAllPoints()
                newGuildBtn:SetPoint('TOPLEFT', FriendsFrame, 'BOTTOMLEFT', dx, 1)
                DragonflightUIMixin:TabResize(originalGuild)

                if _G[newGuildBtn:GetName() .. 'LeftDisabled'] then _G[newGuildBtn:GetName() .. 'LeftDisabled']:Hide() end
                if _G[newGuildBtn:GetName() .. 'RightDisabled'] then _G[newGuildBtn:GetName() .. 'RightDisabled']:Hide() end
                if _G[newGuildBtn:GetName() .. 'MiddleDisabled'] then _G[newGuildBtn:GetName() .. 'MiddleDisabled']:Hide() end

                newGuildBtn:SetText(originalGuild:GetText())
                newGuildBtn:SetAttribute("type", "macro");
                newGuildBtn:SetAttribute("macrotext", "/click GuildMicroButton");

                originalGuild.DFNewGuildButton = newGuildBtn

                if Settings and Settings.GetValue then
                    hooksecurefunc('FriendsFrame_UpdateGuildTabVisibility', function()
                        if InCombatLockdown() then return end
                        local classicUI = Settings.GetValue('useClassicGuildUI')
                        if classicUI and newGuildBtn:IsVisible() then
                            newGuildBtn:Hide()
                        elseif not classicUI and not newGuildBtn:IsVisible() then
                            newGuildBtn:Show()
                        end
                    end)
                    newGuildBtn:SetShown(not Settings.GetValue('useClassicGuildUI'))
                    newGuildBtn:SetScript('OnEvent', function(self, event, cvarName, value)
                        if InCombatLockdown() then return end
                        if event == "CVAR_UPDATE" then
                            if cvarName == "useClassicGuildUI" then
                                if value == "1" then
                                    newGuildBtn:Hide()
                                else
                                    newGuildBtn:Show()
                                end
                            end
                        end
                    end)
                    newGuildBtn:RegisterEvent("CVAR_UPDATE")
                end
            end
        else
            for i = 1, 5 do
                local tab = _G[name .. 'Tab' .. i]
                if tab then
                    if i == 1 then
                        tab:ClearAllPoints()
                        tab:SetPoint('TOPLEFT', FriendsFrame, 'BOTTOMLEFT', 6, -1)
                    end
                end
            end
            if DF.API.Version.IsMoP then
                hooksecurefunc('FriendsFrame_UpdateGuildTabVisibility', function()
                    if InCombatLockdown() then return end

                    for i = 1, 5 do
                        local tab = _G[name .. 'Tab' .. i]
                        if tab then
                            DragonflightUIMixin:TabResize(tab)
                        end
                    end
                    local raidTab = _G["FriendsFrameTab" .. (FRIEND_TAB_RAID or 4)];
                    if raidTab and _G["FriendsFrameTab" .. (FRIEND_TAB_WHO or 2)] then
                        raidTab:SetPoint('TOPLEFT', _G["FriendsFrameTab" .. (FRIEND_TAB_WHO or 2)], 'TOPRIGHT', 4, 0)
                    end
                end)
            end
        end

        local bg = _G['FriendsFrameBg']
        if bg then
            bg:SetTexture(base .. 'ui-background-rock')
            bg:ClearAllPoints()
            bg:SetPoint('TOPLEFT', FriendsFrame, 'TOPLEFT', 3, -18)
            bg:SetPoint('BOTTOMRIGHT', FriendsFrame, 'BOTTOMRIGHT', 0, 3)
        end

        hooksecurefunc('FriendsFrame_Update', function()
            if FriendsFrame and FriendsFrame.TitleText then FriendsFrame.TitleText:Hide() end
        end)

        local conv = RaidFrameConvertToRaidButton
        if conv then
            conv:SetHeight(22)
            conv:SetPoint('BOTTOMRIGHT', RaidFrame, 'BOTTOMRIGHT', -6, 4)

            local btnText = _G[conv:GetName() .. 'Text'];
            if btnText then
                local fontName, fontHeight, fontFlags = btnText:GetFont()
                btnText:SetFont(fontName, 12, fontFlags)
            end
        end
    elseif name == 'MailFrame' then
        for i = 1, 5 do
            local tab = _G[name .. 'Tab' .. i]
            if tab then
                if i == 1 then
                    tab.DFFirst = true
                    tab.DFFirstOffsetY = 2;
                    tab.DFTabMaxWidth = 200;
                else
                    tab.DFChangePoint = true;
                    tab.DFTabMaxWidth = 200;
                end
                DragonflightUIMixin:TabResize(tab)
            end
        end

        local children = {frame:GetRegions()}
        for k, child in ipairs(children) do
            if child:GetObjectType() == 'Texture' then
                local tex = child:GetTexture()
                if tex == 136382 then
                    child:SetSize(62, 62)
                    child:ClearAllPoints()
                    child:SetPoint('TOPLEFT', -5, 7)
                    child:SetDrawLayer('OVERLAY', 6)
                    SetPortraitToTexture(child, child:GetTexture())
                end
            end
        end
    elseif name == 'PVEFrame' then
        for i = 1, 5 do
            local tab = _G[name .. 'Tab' .. i]
            if tab then
                if i == 1 then
                    tab.DFFirst = true
                    tab.DFFirstOffsetY = 2;
                    tab.DFTabMaxWidth = 200;
                else
                    tab.DFChangePoint = true;
                    tab.DFTabMaxWidth = 200;
                end
                DragonflightUIMixin:TabResize(tab)
            end
        end
    end
end

function DragonflightUIMixin:TabResize(btn)
    self:ResizeTab(btn, btn.DFPadding, btn.DFTabWidth, btn.DFTabMinWidth or 64, btn.DFTabMaxWidth or 140)

    if btn.DFFirst then
        local point, relativeTo, relativePoint, xOfs, yOfs = btn:GetPoint(1)
        if relativeTo then
            btn:SetPoint('TOPLEFT', relativeTo, 'BOTTOMLEFT', btn.DFFirstOffsetX or 6, btn.DFFirstOffsetY or 1)
        end
    elseif btn.DFChangePoint then
        local point, relativeTo, relativePoint, xOfs, yOfs = btn:GetPoint(1)
        if relativeTo then
            btn:ClearAllPoints()
            btn:SetPoint('TOPLEFT', relativeTo, 'TOPRIGHT', 4, 0)
        end
    end
end

function DragonflightUIMixin:CharacterFrameTabButtonTemplate(frame, hideDisabled, dontResize)
    local name = frame:GetName()
    if not name then return false end

    local tex = base .. 'uiframetabs'
    frame:SetSize(10, 32)

    if not dontResize then
        frame:HookScript('OnEvent', function()
            DragonflightUIMixin:TabResize(frame)
        end)

        frame:HookScript('OnShow', function()
            DragonflightUIMixin:TabResize(frame)
        end)
        DragonflightUIMixin:TabResize(frame)
    end

    do
        local left = _G[name .. 'Left']
        if left then
            left:ClearAllPoints()
            left:SetSize(35, 36)
            left:SetTexture(tex)
            left:SetTexCoord(0.015625, 0.5625, 0.816406, 0.957031)
            left:SetPoint('TOPLEFT', -3, 0)
        end

        local right = _G[name .. 'Right']
        if right then
            right:ClearAllPoints()
            right:SetSize(37, 36)
            right:SetTexture(tex)
            right:SetTexCoord(0.015625, 0.59375, 0.667969, 0.808594)
            right:SetPoint('TOPRIGHT', 7, 0)
        end

        local middle = _G[name .. 'Middle']
        if middle and left and right then
            middle:ClearAllPoints()
            middle:SetSize(1, 36)
            middle:SetTexture(tex)
            middle:SetTexCoord(0, 0.015625, 0.175781, 0.316406)
            middle:SetPoint('TOPLEFT', left, 'TOPRIGHT', 0, 0)
            middle:SetPoint('TOPRIGHT', right, 'TOPLEFT', 0, 0)
        end

        local function centreText(artHeight)
            local text = frame.Text or _G[name .. 'Text']
            if not text then return end
            text:ClearAllPoints()
            text:SetPoint('CENTER', frame, 'TOP', 0, -artHeight / 2)
        end

        function frame:SetNormal(normal, keepSize)
            if normal then
                if not keepSize then frame:SetHeight(32) end
                if left then
                    left:SetSize(35, 36)
                    left:SetTexCoord(0.015625, 0.5625, 0.816406, 0.957031)
                end
                if right then
                    right:SetSize(37, 36)
                    right:SetTexCoord(0.015625, 0.59375, 0.667969, 0.808594)
                end
                if middle then
                    middle:SetSize(1, 36)
                    middle:SetTexCoord(0, 0.015625, 0.175781, 0.316406)
                end
                centreText(36)
            else
                if not keepSize then frame:SetHeight(42) end
                if left then
                    left:SetSize(35, 42)
                    left:SetTexCoord(0.015625, 0.5625, 0.496094, 0.660156)
                end
                if right then
                    right:SetSize(37, 42)
                    right:SetTexCoord(0.015625, 0.59375, 0.324219, 0.488281)
                end
                if middle then
                    middle:SetSize(1, 42)
                    middle:SetTexCoord(0, 0.015625, 0.00390625, 0.167969)
                end
                centreText(42)
            end
        end

        centreText(frame:IsEnabled() and 36 or 42)

        frame:HookScript('OnEnable', function()
            frame:SetNormal(true)
        end)

        frame:HookScript('OnDisable', function()
            frame:SetNormal(false)
        end)
    end

    do
        local left = _G[name .. 'LeftDisabled']
        if left then
            left:ClearAllPoints()
            left:SetSize(35, 42)
            left:SetTexture(tex)
            left:SetTexCoord(0.015625, 0.5625, 0.496094, 0.660156)
            left:SetPoint('TOPLEFT', -1, 0)
        end

        local right = _G[name .. 'RightDisabled']
        if right then
            right:ClearAllPoints()
            right:SetSize(37, 42)
            right:SetTexture(tex)
            right:SetTexCoord(0.015625, 0.59375, 0.324219, 0.488281)
            right:SetPoint('TOPRIGHT', 8, 0)
        end

        local middle = _G[name .. 'MiddleDisabled']
        if middle and left and right then
            middle:ClearAllPoints()
            middle:SetSize(1, 42)
            middle:SetTexture(tex)
            middle:SetTexCoord(0, 0.015625, 0.00390625, 0.167969)
            middle:SetPoint('TOPLEFT', left, 'TOPRIGHT', 0, 0)
            middle:SetPoint('TOPRIGHT', right, 'TOPLEFT', 0, 0)
        end

        if hideDisabled then
            if left then left:Hide() end
            if right then right:Hide() end
            if middle then middle:Hide() end
        end
    end

    do
        local highlight = frame:GetHighlightTexture()
        if highlight then highlight:SetTexture() end

        local left = frame:CreateTexture('DragonflightUIHighlight' .. 'Left', 'HIGHLIGHT')
        left:SetTexture(tex)
        left:SetTexCoord(0.015625, 0.5625, 0.816406, 0.957031)
        left:SetSize(35, 36)
        left:SetPoint('TOPLEFT', -3, 0)
        left:SetBlendMode('ADD')
        left:SetAlpha(0.4)

        local right = frame:CreateTexture('DragonflightUIHighlight' .. 'Right', 'HIGHLIGHT')
        right:SetTexture(tex)
        right:SetTexCoord(0.015625, 0.59375, 0.667969, 0.808594)
        right:SetSize(37, 36)
        right:SetPoint('TOPRIGHT', 7, 0)
        right:SetBlendMode('ADD')
        right:SetAlpha(0.4)

        local middle = frame:CreateTexture('DragonflightUIHighlight' .. 'Middle', 'HIGHLIGHT')
        middle:SetTexture(tex)
        middle:SetTexCoord(0, 0.015625, 0.175781, 0.316406)
        middle:SetSize(1, 36)
        middle:SetPoint('TOPLEFT', left, 'TOPRIGHT', 0, 0)
        middle:SetPoint('TOPRIGHT', right, 'TOPLEFT', 0, 0)
        middle:SetBlendMode('ADD')
        middle:SetAlpha(0.4)

        function frame:DFHighlight(big)
            if big then
                left:SetHeight(42)
                right:SetHeight(42)
                middle:SetHeight(42)
            else
                left:SetHeight(36)
                right:SetHeight(36)
                middle:SetHeight(36)
            end
        end
    end
end

function DragonflightUIMixin:BottomEncounterTierTabTemplate(frame)
    local tex = base .. 'uiframetabs'
    frame:SetSize(80, 36)
    do
        local left = frame.left
        if left then
            left:ClearAllPoints()
            left:SetSize(35, 36)
            left:SetTexture(tex)
            left:SetTexCoord(0.015625, 0.5625, 0.816406, 0.957031)
            left:SetPoint('TOPLEFT', -3, 0)
        end

        local right = frame.right
        if right then
            right:ClearAllPoints()
            right:SetSize(37, 36)
            right:SetTexture(tex)
            right:SetTexCoord(0.015625, 0.59375, 0.667969, 0.808594)
            right:SetPoint('TOPRIGHT', 7, 0)
        end

        local middle = frame.mid
        if middle and left and right then
            middle:ClearAllPoints()
            middle:SetSize(1, 36)
            middle:SetTexture(tex)
            middle:SetTexCoord(0, 0.015625, 0.175781, 0.316406)
            middle:SetPoint('TOPLEFT', left, 'TOPRIGHT', 0, 0)
            middle:SetPoint('TOPRIGHT', right, 'TOPLEFT', 0, 0)
        end

        local setNormal = function(normal, keepSize)
            if normal then
                frame:SetHeight(32)
                if left then
                    left:SetSize(35, 36)
                    left:SetTexCoord(0.015625, 0.5625, 0.816406, 0.957031)
                end
                if right then
                    right:SetSize(37, 36)
                    right:SetTexCoord(0.015625, 0.59375, 0.667969, 0.808594)
                end
                if middle then
                    middle:SetSize(1, 36)
                    middle:SetTexCoord(0, 0.015625, 0.175781, 0.316406)
                end
            else
                frame:SetHeight(42)
                if left then
                    left:SetSize(35, 42)
                    left:SetTexCoord(0.015625, 0.5625, 0.496094, 0.660156)
                end
                if right then
                    right:SetSize(37, 42)
                    right:SetTexCoord(0.015625, 0.59375, 0.324219, 0.488281)
                end
                if middle then
                    middle:SetSize(1, 42)
                    middle:SetTexCoord(0, 0.015625, 0.00390625, 0.167969)
                end
            end
        end

        frame:HookScript('OnEnable', function()
            setNormal(true)
        end)

        frame:HookScript('OnDisable', function()
            setNormal(false)
        end)
    end

    do
        local left = frame.leftSelect
        if left then
            left:ClearAllPoints()
            left:SetSize(35, 42)
            left:SetTexture(tex)
            left:SetTexCoord(0.015625, 0.5625, 0.496094, 0.660156)
            left:SetPoint('TOPLEFT', -1, 0)
        end

        local right = frame.rightSelect
        if right then
            right:ClearAllPoints()
            right:SetSize(37, 42)
            right:SetTexture(tex)
            right:SetTexCoord(0.015625, 0.59375, 0.324219, 0.488281)
            right:SetPoint('TOPRIGHT', 8, 0)
        end

        local middle = frame.midSelect
        if middle and left and right then
            middle:ClearAllPoints()
            middle:SetSize(1, 42)
            middle:SetTexture(tex)
            middle:SetTexCoord(0, 0.015625, 0.00390625, 0.167969)
            middle:SetPoint('TOPLEFT', left, 'TOPRIGHT', 0, 0)
            middle:SetPoint('TOPRIGHT', right, 'TOPLEFT', 0, 0)
        end
    end

    do
        local left = frame.leftHighlight
        if left then
            left:SetTexture(tex)
            left:SetTexCoord(0.015625, 0.5625, 0.816406, 0.957031)
            left:SetSize(35, 36)
            left:ClearAllPoints()
            left:SetPoint('TOPLEFT', -3, 0)
            left:SetBlendMode('ADD')
            left:SetAlpha(0.4)
        end

        local right = frame.rightHighlight
        if right then
            right:SetTexture(tex)
            right:SetTexCoord(0.015625, 0.59375, 0.667969, 0.808594)
            right:SetSize(37, 36)
            right:ClearAllPoints()
            right:SetPoint('TOPRIGHT', 7, 0)
            right:SetBlendMode('ADD')
            right:SetAlpha(0.4)
        end

        local middle = frame.midHighlight
        if middle and left and right then
            middle:SetTexture(tex)
            middle:SetTexCoord(0, 0.015625, 0.175781, 0.316406)
            middle:SetSize(1, 36)
            middle:ClearAllPoints()
            middle:SetPoint('TOPLEFT', left, 'TOPRIGHT', 0, 0)
            middle:SetPoint('TOPRIGHT', right, 'TOPLEFT', 0, 0)
            middle:SetBlendMode('ADD')
            middle:SetAlpha(0.4)
        end
    end
end

function DragonflightUIMixin:AddIconBorder(btn, helpful)
    if btn.DFIconBorder then return end
    btn.DFIconBorder = btn:CreateTexture('DragonflightUIIconBorder')
    local border = btn.DFIconBorder;
    border:ClearAllPoints()
    border:SetPoint('TOPLEFT', btn, 'TOPLEFT', 0, 0.25)
    border:SetPoint('BOTTOMRIGHT', btn, 'BOTTOMRIGHT', 1.75, -0.75)
    border:SetTexture('Interface\\Addons\\DragonflightUI\\Textures\\uiactionbar2x')
    border:SetTexCoord(0.701171875, 0.880859375, 0.31689453125, 0.36083984375)
    border:SetDrawLayer('OVERLAY')

    if not helpful then
        border:SetTexture('Interface\\Addons\\DragonflightUI\\Textures\\iconborderWhite')
        border:SetTexCoord(0, 92 / 128, 0, 90 / 128)
    end

    local mask = btn:CreateMaskTexture('DragonflightUIIconMask')
    local delta = 1.25
    mask:SetPoint('TOPLEFT', btn, 'TOPLEFT', -delta, delta)
    mask:SetPoint('BOTTOMRIGHT', btn, 'BOTTOMRIGHT', delta, -delta)
    mask:SetTexture('Interface\\Addons\\DragonflightUI\\Textures\\maskNew')
    if _G[btn:GetName() .. 'Icon'] then _G[btn:GetName() .. 'Icon']:AddMaskTexture(mask) end
end

ContainerFrameCurrencyBorderMixin = {};

function ContainerFrameCurrencyBorderMixin:OnLoad()
    self:SetupPiece(self.Left, self.leftEdge);
    self:SetupPiece(self.Right, self.rightEdge);
    self:SetupPiece(self.Middle, self.centerEdge);
end

local commoncoinboxTexture = base .. 'commoncoinbox'
local commoncurrencyboxTexture = base .. 'commoncurrencybox'
local currencyBorderAtlas = {
    ["common-coinbox-left"] = {commoncoinboxTexture, 16, 34, 0.03125, 0.53125, 0.289062, 0.554688, false, false, "1x"},
    ["common-coinbox-right"] = {commoncoinboxTexture, 16, 34, 0.03125, 0.53125, 0.570312, 0.835938, false, false, "1x"},
    ["_common-coinbox-center"] = {commoncoinboxTexture, 16, 34, 0, 0.5, 0.0078125, 0.273438, true, false, "1x"},
    ["common-currencybox-left"] = {
        commoncurrencyboxTexture, 16, 34, 0.03125, 0.53125, 0.289062, 0.554688, false, false, "1x"
    },
    ["common-currencybox-right"] = {
        commoncurrencyboxTexture, 16, 34, 0.03125, 0.53125, 0.570312, 0.835938, false, false, "1x"
    },
    ["_common-currencybox-center"] = {commoncurrencyboxTexture, 16, 34, 0, 0.5, 0.0078125, 0.273438, true, false, "1x"}
}

function ContainerFrameCurrencyBorderMixin:SetupPiece(piece, atlas)
    if not piece or not atlas then return end
    if piece.SetTexelSnappingBias then piece:SetTexelSnappingBias(0) end

    local data = currencyBorderAtlas[atlas]
    if data then
        piece:SetTexture(data[1])
        piece:SetTexCoord(data[4], data[5], data[6], data[7])
    end
end
