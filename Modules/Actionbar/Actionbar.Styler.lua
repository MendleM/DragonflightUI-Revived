local addonName, addonTable = ...;
local Helper = addonTable.Helper;
---@diagnostic disable: undefined-global
local DF = LibStub('AceAddon-3.0'):GetAddon('DragonflightUI')
local L = LibStub("AceLocale-3.0"):GetLocale("DragonflightUI")
local Module = DF:GetModule('Actionbar')

local atlasActionbar = {
    ['UI-HUD-ActionBar-Gryphon-Left'] = {200, 188, 0.001953125, 0.697265625, 0.10205078125, 0.26513671875, false, false},
    ['UI-HUD-ActionBar-Gryphon-Right'] = {
        200, 188, 0.001953125, 0.697265625, 0.26611328125, 0.42919921875, false, false
    },
    ['UI-HUD-ActionBar-IconFrame-Slot'] = {
        128, 124, 0.701171875, 0.951171875, 0.10205078125, 0.16259765625, false, false
    },
    ['UI-HUD-ActionBar-Wyvern-Left'] = {200, 188, 0.001953125, 0.697265625, 0.43017578125, 0.59326171875, false, false},
    ['UI-HUD-ActionBar-Wyvern-Right'] = {200, 188, 0.001953125, 0.697265625, 0.59423828125, 0.75732421875, false, false}
}

function Module.CreateFrameFromAtlas(atlas, name, textureRef, frameName)
    local data = atlas[name]

    local f = CreateFrame('Frame', frameName, UIParent)
    f:SetSize(data[1], data[2])
    f:SetPoint('CENTER', UIParent, 'CENTER')

    f.texture = f:CreateTexture()
    f.texture:SetTexture(textureRef)
    f.texture:SetSize(data[1], data[2])
    f.texture:SetTexCoord(data[3], data[4], data[5], data[6])
    f.texture:SetPoint('CENTER')
    return f
end

function Module.ChangeGryphon()
    local textures = {
        MainMenuBarLeftEndCap, MainMenuBarRightEndCap,
        MainMenuBarTexture0, MainMenuBarTexture1, MainMenuBarTexture2, MainMenuBarTexture3,
        MainMenuMaxLevelBar0, MainMenuMaxLevelBar1, MainMenuMaxLevelBar2, MainMenuMaxLevelBar3
    }
    for _, tex in ipairs(textures) do
        if tex then
            tex:Hide()
            if not tex.DFHooked then
                tex.DFHooked = true
                hooksecurefunc(tex, 'Show', function(self) self:Hide() end)
            end
        end
    end
end

function Module.DrawActionbarDeco()
    local textureRef = 'Interface\\Addons\\DragonflightUI\\Textures\\uiactionbar2x'
    for i = 1, 12 do
        local deco = Module.CreateFrameFromAtlas(atlasActionbar, 'UI-HUD-ActionBar-IconFrame-Slot', textureRef,
                                                 'ActionbarDeco' .. i)
        deco:SetScale(0.3)
        deco:SetPoint('CENTER', _G['ActionButton' .. i], 'CENTER', 0, 0)
        deco:SetFrameStrata('LOW')
        _G['ActionButton' .. i].decoDF = deco
    end
end

function Module.SetButtonFromAtlas(frame, atlas, textureRef, pre, name)
    local key = pre .. name

    local up = atlas[key .. '-Up']
    frame:SetSize(up[1], up[2])
    frame:SetScale(0.7)
    frame:SetHitRectInsets(0, 0, 0, 0)

    frame:SetNormalTexture(textureRef)
    frame:GetNormalTexture():SetTexCoord(up[3], up[4], up[5], up[6])

    local disabled = atlas[key .. '-Disabled']
    frame:SetDisabledTexture(textureRef)
    frame:GetDisabledTexture():SetTexCoord(disabled[3], disabled[4], disabled[5], disabled[6])

    local down = atlas[key .. '-Down']
    frame:SetPushedTexture(textureRef)
    frame:GetPushedTexture():SetTexCoord(down[3], down[4], down[5], down[6])

    local mouseover = atlas[key .. '-Mouseover']
    frame:SetHighlightTexture(textureRef)
    frame:GetHighlightTexture():SetTexCoord(mouseover[3], mouseover[4], mouseover[5], mouseover[6])

    return frame
end

function Module.HookAlwaysShowActionbar()
    local updateGrids = function()
        if Module.bar2 then Module.bar2:UpdateGrid(Module.db.profile.bar2.alwaysShow) end
        if Module.bar3 then Module.bar3:UpdateGrid(Module.db.profile.bar3.alwaysShow) end
    end
    hooksecurefunc('MultiActionBar_UpdateGridVisibility', function()
    end)
    hooksecurefunc('MultiActionBar_ShowAllGrids', function()
        updateGrids()
        C_Timer.After(2, updateGrids)
    end)
    hooksecurefunc('MultiActionBar_HideAllGrids', function()
        updateGrids()
        C_Timer.After(2, updateGrids)
    end)
end

function Module:RemoveActionbarAnimations()
    local function remove(bar)
        if not bar then return end
        local group = bar.slideOut;
        if not group then return end

        for i, anim in ipairs({group:GetAnimations()}) do
            if anim:GetObjectType() == "Translation" then
                anim:SetOffset(0, 0)
                anim:SetDuration(0.0001)
            end
        end
    end
    remove(_G['MainMenuBar'])
    remove(_G['MultiBarRight'])
    remove(_G['MultiBarLeft'])
end

function Module.ChangeButtonSpacing()
    local spacing = 3
    local buttonTable = {'MultiBarBottomRightButton', 'MultiBarBottomLeftButton', 'ActionButton'}
    for k, v in pairs(buttonTable) do
        for i = 2, 12 do
            local btn = _G[v .. i]
            local prev = _G[v .. (i - 1)]
            if btn and prev then
                btn:SetPoint('LEFT', prev, 'RIGHT', spacing, 0)
            end
        end
    end
end

function Module.GetBagSlots(id)
    if not GetContainerNumSlots then
        local slots = C_Container.GetContainerNumSlots(id)
        return slots
    else
        local slots = GetContainerNumSlots(id)
        return slots
    end
end

function Module.ChangeBackpack()
    local bagAtlas = 'Interface\\Addons\\DragonflightUI\\Textures\\bagslots2x'
    local f = _G['DragonflightUIBagBar']
    if f then
        f:Show()
        f:SetSize(200, 37)
        f:SetParent(UIParent)
        f:SetScale(1.0)
        f:SetClampedToScreen(true)
        f:SetMovable(true)
    end

    -- MainMenuBarBackpackButton
    if MainMenuBarBackpackButton then
        local texture = 'Interface\\Addons\\DragonflightUI\\Textures\\bigbag'
        local highlight = 'Interface\\Addons\\DragonflightUI\\Textures\\bigbagHighlight'

        if f then
            MainMenuBarBackpackButton:SetParent(f)
            MainMenuBarBackpackButton:ClearAllPoints()
            MainMenuBarBackpackButton:SetPoint('RIGHT', f, 'RIGHT', 0, 0)
        end
        MainMenuBarBackpackButton:SetScale(1.5)
        MainMenuBarBackpackButton:Show()

        SetItemButtonTexture(MainMenuBarBackpackButton, texture)
        MainMenuBarBackpackButton:SetHighlightTexture(highlight)
        MainMenuBarBackpackButton:SetPushedTexture(highlight)
        MainMenuBarBackpackButton:SetCheckedTexture(highlight)

        if MainMenuBarBackpackButtonNormalTexture then
            MainMenuBarBackpackButtonNormalTexture:Hide()
            MainMenuBarBackpackButtonNormalTexture:SetTexture()
        end

        if DF.MoP and MainMenuBarBackpackButtonCount then
            MainMenuBarBackpackButtonCount:ClearAllPoints()
            MainMenuBarBackpackButtonCount:SetPoint('BOTTOMRIGHT', MainMenuBarBackpackButton, 'BOTTOMRIGHT', -6, 6)

            local fontFile, fontHeight, flags = MainMenuBarBackpackButtonCount:GetFont()
            if fontFile then
                MainMenuBarBackpackButtonCount:SetFont(fontFile, 12, flags)
            end

            if not Module.MoPBackpackCountHooked then
                Module.MoPBackpackCountHooked = true
                hooksecurefunc(MainMenuBarBackpackButtonCount, 'SetPoint', function(self)
                    if self.DF_SettingPoint then return end
                    self.DF_SettingPoint = true
                    self:ClearAllPoints()
                    self:SetPoint('BOTTOMRIGHT', MainMenuBarBackpackButton, 'BOTTOMRIGHT', -6, 6)
                    self.DF_SettingPoint = false
                end)
            end
        end
        if not MainMenuBarBackpackButton.Border then
            local cutout = 'Interface\\Addons\\DragonflightUI\\Textures\\bagslotCutout'

            local border = MainMenuBarBackpackButton:CreateTexture('DragonflightUIBigBagBorder', 'OVERLAY')
            border:SetTexture(cutout)
            border:SetPoint('TOPLEFT', MainMenuBarBackpackButton, 'TOPLEFT', 0, 0)
            border:SetPoint('BOTTOMRIGHT', MainMenuBarBackpackButton, 'BOTTOMRIGHT', 0, 0)

            MainMenuBarBackpackButton.Border = border
        end
    end

    -- bags
    do
        Module.AnchorBagSlots()

        for i = 0, 3 do
            local slot = _G['CharacterBag' .. i .. 'Slot']
            slot:SetScale(1)
            slot:SetSize(30, 30)

            local size = 30.5

            local normal = slot:GetNormalTexture()
            normal:SetTexture(bagAtlas)
            normal:SetTexCoord(0.576172, 0.695312, 0.5, 0.976562)
            normal:SetSize(size, size)
            normal:SetPoint('CENTER', 2, -1)
            normal:SetDrawLayer('BORDER', 0)

            local highlight = slot:GetHighlightTexture()
            highlight:SetTexture(bagAtlas)
            highlight:SetTexCoord(0.699219, 0.818359, 0.0078125, 0.484375)
            highlight:SetSize(size, size)
            highlight:ClearAllPoints()
            highlight:SetPoint('CENTER', 2, -1)

            local checked = slot:GetCheckedTexture()
            checked:SetTexture(bagAtlas)
            checked:SetTexCoord(0.699219, 0.818359, 0.0078125, 0.484375)
            checked:SetSize(size, size)
            checked:ClearAllPoints()
            checked:SetPoint('CENTER', 2, -1)

            local pushed = slot:GetPushedTexture()
            pushed:SetTexture(bagAtlas)
            pushed:SetTexCoord(0.576172, 0.695312, 0.5, 0.976562)
            pushed:SetSize(size, size)
            pushed:ClearAllPoints()
            pushed:SetPoint('CENTER', 2, -1)
            pushed:SetDrawLayer('BORDER', 0)

            local iconTexture = _G['CharacterBag' .. i .. 'SlotIconTexture']
            iconTexture:ClearAllPoints()
            iconTexture:SetPoint('CENTER', 0, 0)

            local bagmask = 'Interface\\Addons\\DragonflightUI\\Textures\\bagmask'
            iconTexture:SetMask(bagmask)
            iconTexture:SetSize(30, 30)
            iconTexture:SetDrawLayer('BORDER', 2)

            if not slot.Border then
                local border = slot:CreateTexture('DragonflightUIBagBorder')
                border:SetTexture(bagAtlas)
                border:SetTexCoord(0.576172, 0.695312, 0.0078125, 0.484375)
                border:SetSize(size, size)
                border:SetPoint('CENTER', 2, -1)

                slot.Border = border
            end
        end
    end

    -- keyring
    local hasKeyring = not (DF.Cata or DF.MoP) and KeyRingButton
    if hasKeyring then
        KeyRingButton:SetSize(30, 30)
        KeyRingButton:SetScale(1)
        Module.AnchorBagSlots()

        local size = 30.5

        local normal = KeyRingButton:GetNormalTexture()
        normal:SetTexture(bagAtlas)
        normal:SetTexCoord(0.822266, 0.941406, 0.0078125, 0.484375)
        normal:SetSize(size, size)
        normal:ClearAllPoints()
        normal:SetPoint('CENTER', 2, -1)
        normal:SetDrawLayer('BORDER', 0)

        local highlight = KeyRingButton:GetHighlightTexture()
        highlight:SetTexture(bagAtlas)
        highlight:SetTexCoord(0.699219, 0.818359, 0.0078125, 0.484375)
        highlight:SetSize(size, size)
        highlight:ClearAllPoints()
        highlight:SetPoint('CENTER', 2, -1)

        local pushed = KeyRingButton:GetPushedTexture()
        pushed:SetTexture(bagAtlas)
        pushed:SetTexCoord(0.699219, 0.818359, 0.0078125, 0.484375)
        pushed:SetSize(size, size)
        pushed:ClearAllPoints()
        pushed:SetPoint('CENTER', 2, -1)

        if not KeyRingButton.Icon then
            local icon = KeyRingButton:CreateTexture('DragonflightUIKeyRingIconTexture')
            icon:SetTexture('Interface\\Addons\\DragonflightUI\\Textures\\KeyRing-Bag-Icon')
            KeyRingButton.Icon = icon

            local delta = 6
            icon:SetSize(size - delta, size - delta)
            icon:SetPoint('CENTER', 0, 0)
            icon:SetDrawLayer('BORDER', 2)

            local bagmask = KeyRingButton:CreateMaskTexture('DragonflightUIKeyRingButtonMask')
            KeyRingButton.Mask = bagmask
            bagmask:SetAllPoints(icon)
            bagmask:SetTexture('Interface\\Addons\\DragonflightUI\\Textures\\bagmask')
            bagmask:SetSize(size - delta, size - delta)

            icon:AddMaskTexture(bagmask)
        end

        if not KeyRingButton.Border then
            local border = KeyRingButton:CreateTexture('DragonflightUIKeyRingBorder')
            border:SetTexture(bagAtlas)
            border:SetTexCoord(0.699219, 0.818359, 0.5, 0.976562)
            border:SetSize(size, size)
            border:SetPoint('CENTER', 2, -1)

            KeyRingButton.Border = border
        end
    elseif KeyRingButton then
        KeyRingButton:Hide()
    end

    local f = _G['DragonflightUIBagBar']
    f:SetSize(200, 37)
    f:SetParent(UIParent)
    f:SetScale(1.0)
    f:SetClampedToScreen(true)
    f:SetMovable(true)

    if _G['BagsBar'] then
        if not InCombatLockdown() then
            _G['BagsBar']:ClearAllPoints()
            _G['BagsBar']:SetPoint('RIGHT', f, 'RIGHT', 0, 0)
        end
    end

    -- Outside the BagsBar check on purpose: the hook inside goes on
    -- MainMenuBarBagManager, not on BagsBar, and it used to be skipped entirely on
    -- flavours where BagsBar does not exist.
    Module.HookBagBarLayout()
end

function Module.AnchorBagSlots()
    if not (MainMenuBarBackpackButton and _G['CharacterBag0Slot']) then return end
    if Helper:IsCombatLocked() then return end

    -- The backpack goes back onto our own holder first.
    --
    -- /df log watch showed Blizzard's bag bar layout claiming it: the button ends
    -- up anchored to BagsBar RIGHT even though UpdateBagState anchors it to
    -- DragonflightUIBagBar. Everything below hangs off the backpack, so if it is
    -- left where Blizzard put it the whole row follows.
    local holder = _G['DragonflightUIBagBar']
    if holder then
        MainMenuBarBackpackButton:ClearAllPoints()
        MainMenuBarBackpackButton:SetPoint('RIGHT', holder, 'RIGHT', 0, 0)
    end

    _G['CharacterBag0Slot']:ClearAllPoints()
    _G['CharacterBag0Slot']:SetPoint('RIGHT', MainMenuBarBackpackButton, 'LEFT', -12, 0)

    for i = 1, 3 do
        local slot = _G['CharacterBag' .. i .. 'Slot']
        local previous = _G['CharacterBag' .. (i - 1) .. 'Slot']
        if slot and previous then
            local gap = 0
            slot:ClearAllPoints()
            slot:SetPoint('RIGHT', previous, 'LEFT', -gap, 0)
        end
    end

    local hasKeyring = not (DF.Cata or DF.MoP) and KeyRingButton
    if hasKeyring and _G['CharacterBag3Slot'] then
        KeyRingButton:ClearAllPoints()
        KeyRingButton:SetPoint('RIGHT', _G['CharacterBag3Slot'], 'LEFT', 0, 0)
    elseif KeyRingButton then
        KeyRingButton:Hide()
    end
end

-- Re-assert our bag row after Blizzard has laid its own out.
--
-- BagsBarMixin:Layout re-anchors the whole row off self.bagPadding, which is 5, so
-- every button ends up at -5 and bag 0 loses the -12 gap it needs for the expand
-- arrow. /df log watch caught it exactly:
--
--   CharacterBag0Slot: RIGHT -> MainMenuBarBackpackButton LEFT (-12,0) => (-5,0)
--   CharacterBag1Slot: RIGHT -> CharacterBag0Slot LEFT (-0,0) => (-5,0)
--   KeyRingButton:     RIGHT -> CharacterBag3Slot LEFT (0,0) => (-5,0)
--
-- Hooking BagsBar.Layout does not work, and that is worth writing down because it
-- cost three attempts. BagsBarMixin:OnLoad registers the callback like this:
--
--   EventRegistry:RegisterCallback("MainMenuBarManager.OnExpandChanged", self.Layout, self)
--
-- The registry stores the function VALUE at load time. hooksecurefunc replaces the
-- table field BagsBar.Layout, so the registry keeps calling the original and the
-- hook never fires. Same for the VARIABLES_LOADED pass, which goes through
-- GenerateClosure(self.Layout, self) and captures it too.
--
-- What does work is MainMenuBarBagManager:OnExpandBarChanged. It is invoked as
-- self:OnExpandBarChanged(), a live table lookup, so a hook on it fires - and it
-- fires after TriggerEvent has returned, meaning after Layout has already run. No
-- timer needed, so the row never draws in the wrong place.
--
-- Both SetExpandBar and SetExpandBarAuto funnel through it, which covers the
-- trigger the report described: OnCursorChanged calls SetExpandBarAuto on every
-- CURSOR_CHANGED. Hovering an NPC is not a "relevant cursor type", so it passes
-- false, and on the first hover after login the previous value is nil. nil ~= false
-- counts as a change, so the row gets laid out again for no visible reason.
--
-- Verified byte-identical in classic_era, classic_anniversary and classic.
local function ReanchorBagRow()
    -- Moving these buttons is protected, so AnchorBagSlots no-ops in combat and the
    -- PLAYER_REGEN_ENABLED handler below picks the work up when the fight ends.
    --
    -- Deliberately not Helper:RunOutOfCombat: that queues into the post-combat
    -- RefreshConfig pass and announces itself in chat, which is a lot of machinery
    -- for six SetPoint calls that nothing else depends on.
    Module.AnchorBagSlots()
end

function Module.HookBagBarLayout()
    if Module.BagBarLayoutHooked then return end

    local mgr = _G['MainMenuBarBagManager']
    if not (mgr and mgr.OnExpandBarChanged) then return end

    Module.BagBarLayoutHooked = true
    hooksecurefunc(mgr, 'OnExpandBarChanged', ReanchorBagRow)

    -- Blizzard lays the row out from a second place, and the hook above cannot see
    -- it either. BagsBarMixin:OnLoad does this:
    --
    --   EventUtil.ContinueOnVariablesLoaded(GenerateClosure(self.Layout, self))
    --
    -- so Layout runs once at VARIABLES_LOADED without going through
    -- OnExpandBarChanged, and it lands after our styling pass. That is why the row
    -- came up spread out after a reload and only snapped into place on the first
    -- cursor change, when the hook above finally fired.
    --
    -- PLAYER_ENTERING_WORLD is always after VARIABLES_LOADED, so re-anchoring there
    -- closes the gap. Every PEW rather than just the first: it costs six SetPoints
    -- and it also covers zoning, and the one-frame delay keeps us behind anything
    -- else still running in the same batch.
    --
    -- PLAYER_REGEN_ENABLED is the other half of the combat guard in AnchorBagSlots:
    -- anything Blizzard re-anchored mid-fight, which we had to let stand, gets put
    -- back the moment the fight ends.
    local watcher = CreateFrame('Frame')
    watcher:RegisterEvent('PLAYER_ENTERING_WORLD')
    watcher:RegisterEvent('PLAYER_REGEN_ENABLED')
    watcher:SetScript('OnEvent', function() C_Timer.After(0, ReanchorBagRow) end)
end

function Module.UpdateBagSlotIcons()
    for i = 0, 3 do
        local slot = _G['CharacterBag' .. i .. 'Slot']
        local iconTexture = _G['CharacterBag' .. i .. 'SlotIconTexture']
        if slot and iconTexture then
            local slots = Module.GetBagSlots(i + 1)
            if slots == 0 then
                iconTexture:SetDrawLayer('BORDER', -1)
            else
                iconTexture:SetDrawLayer('BORDER', 2)
            end
        end
    end
end

function Module.HookBags()
    local UpdateContainerFrameAnchorsModified = function()
        if not ContainerFrame1 then return end
        local CONTAINER_OFFSET_X_DF = ContainerFrame1.CONTAINER_OFFSET_X_DF or 0
        local CONTAINER_OFFSET_Y_DF = ContainerFrame1.CONTAINER_OFFSET_Y_DF or 92

        local db = Module.db.profile
        if db.bags.overrideBagAnchor then
            CONTAINER_OFFSET_X_DF = db.bags.offsetX
            CONTAINER_OFFSET_Y_DF = db.bags.offsetY
        end

        local VISIBLE_CONTAINER_SPACING_DF = ContainerFrame1.VISIBLE_CONTAINER_SPACING_DF or 3
        local CONTAINER_SPACING_DF = ContainerFrame1.CONTAINER_SPACING_DF or 0

        if not Module.db.profile.changeSides then
            CONTAINER_OFFSET_X_DF = CONTAINER_OFFSET_X
        end

        local frame, xOffset, yOffset, screenHeight, freeScreenHeight, leftMostPoint, column
        local screenWidth = GetScreenWidth()
        local containerScale = 1
        local leftLimit = 0
        if (BankFrame and BankFrame:IsShown()) then leftLimit = BankFrame:GetRight() - 25 end

        while (containerScale > CONTAINER_SCALE) do
            screenHeight = GetScreenHeight() / containerScale
            xOffset = CONTAINER_OFFSET_X_DF / containerScale
            yOffset = CONTAINER_OFFSET_Y_DF / containerScale
            freeScreenHeight = screenHeight - yOffset
            leftMostPoint = screenWidth - xOffset
            column = 1
            local frameHeight
            if ContainerFrame1.bags then
                for index, frameName in ipairs(ContainerFrame1.bags) do
                    local cf = _G[frameName]
                    if cf then
                        frameHeight = cf:GetHeight()
                        if (freeScreenHeight < frameHeight) then
                            column = column + 1
                            leftMostPoint = screenWidth - (column * CONTAINER_WIDTH * containerScale) - xOffset
                            freeScreenHeight = screenHeight - yOffset
                        end
                        freeScreenHeight = freeScreenHeight - frameHeight - VISIBLE_CONTAINER_SPACING_DF
                    end
                end
            end
            if (leftMostPoint < leftLimit) then
                containerScale = containerScale - 0.01
            else
                break
            end
        end

        if (containerScale < CONTAINER_SCALE) then containerScale = CONTAINER_SCALE end

        screenHeight = GetScreenHeight() / containerScale
        xOffset = CONTAINER_OFFSET_X_DF / containerScale
        yOffset = CONTAINER_OFFSET_Y_DF / containerScale
        freeScreenHeight = screenHeight - yOffset
        column = 0
        if ContainerFrame1.bags then
            for index, frameName in ipairs(ContainerFrame1.bags) do
                frame = _G[frameName]
                if frame then
                    frame:SetScale(containerScale)
                    if (index == 1) then
                        frame:SetPoint('BOTTOMRIGHT', frame:GetParent(), 'BOTTOMRIGHT', -xOffset, yOffset)
                    elseif (freeScreenHeight < frame:GetHeight()) then
                        column = column + 1
                        freeScreenHeight = screenHeight - yOffset
                        frame:SetPoint('BOTTOMRIGHT', frame:GetParent(), 'BOTTOMRIGHT', -(column * CONTAINER_WIDTH) - xOffset,
                                       yOffset)
                    else
                        local prevBag = _G[ContainerFrame1.bags[index - 1]]
                        if prevBag then
                            frame:SetPoint('BOTTOMRIGHT', prevBag, 'TOPRIGHT', 0, CONTAINER_SPACING_DF)
                        end
                    end
                    freeScreenHeight = freeScreenHeight - frame:GetHeight() - VISIBLE_CONTAINER_SPACING_DF
                end
            end
        end
    end

    hooksecurefunc('UpdateContainerFrameAnchors', UpdateContainerFrameAnchorsModified)
end

local frameBagToggle = CreateFrame('Button', 'DragonflightUIBagToggleFrame', MainMenuBarBackpackButton)
Module.FrameBagToggle = frameBagToggle

function Module.CreateBagExpandButton()
    local point, relativePoint = 'RIGHT', 'LEFT'
    local base = 'Interface\\Addons\\DragonflightUI\\Textures\\bagslots2x'

    local f = Module.FrameBagToggle
    f:SetSize(16, 30)
    f:SetScale(0.5 / 1.5)
    f:ClearAllPoints()
    f:SetPoint(point, MainMenuBarBackpackButton, relativePoint)

    f:SetNormalTexture(base)
    f:SetPushedTexture(base)
    f:SetHighlightTexture(base)
    f:GetNormalTexture():SetTexCoord(0.951171875, 0.982421875, 0.015625, 0.25)
    f:GetHighlightTexture():SetTexCoord(0.951171875, 0.982421875, 0.015625, 0.25)
    f:GetPushedTexture():SetTexCoord(0.951171875, 0.982421875, 0.015625, 0.25)

    f:SetScript('OnClick', function()
        local bags = Module.db.profile.bags
        bags.expanded = not bags.expanded
        Module.BagBarExpandToggled(bags.expanded)
        Module:RefreshOptionScreens()
    end)
    f:RegisterEvent('BAG_UPDATE_DELAYED')
    f:RegisterEvent('PLAYER_ENTERING_WORLD')
    f:RegisterUnitEvent('UNIT_ENTERED_VEHICLE', 'player')
    f:RegisterUnitEvent('UNIT_EXITED_VEHICLE', 'player')
end

function frameBagToggle:OnEvent(event, arg1)
    if event == 'BAG_UPDATE_DELAYED' then
        Module.RefreshBagBarToggle()
        Module.UpdateBagSlotIcons()
    elseif event == 'PLAYER_ENTERING_WORLD' then
        Module.UpdateBagSlotIcons()
    end
end
frameBagToggle:SetScript('OnEvent', frameBagToggle.OnEvent)

function Module.BagBarExpandToggled(expanded)
    local rotation
    if (expanded) then
        rotation = math.pi
    else
        rotation = 0
    end

    local f = Module.FrameBagToggle
    if f and f:GetNormalTexture() then
        f:GetNormalTexture():SetRotation(rotation)
        f:GetPushedTexture():SetRotation(rotation)
        f:GetHighlightTexture():SetRotation(rotation)
    end

    local hasKeyring = not (DF.Cata or DF.MoP) and KeyRingButton

    for i = 0, 3 do
        local bag = _G['CharacterBag' .. i .. 'Slot']
        if bag then
            if (expanded) then
                bag:Show()
                if hasKeyring then KeyRingButton:Show() end
            else
                bag:Hide()
                if hasKeyring then KeyRingButton:Hide() end
            end
        end
    end

    if not hasKeyring and KeyRingButton then
        KeyRingButton:Hide()
    end

    -- Re-anchor, because this function only changed visibility.
    --
    -- Blizzard's BagsBarMixin:Layout skips hidden buttons - "if bagButton:IsShown()
    -- and bagButton ~= MainMenuBarBackpackButton" - and rebuilds the chain from the
    -- visible ones alone. If it runs while the row is collapsed, the buttons that
    -- were hidden keep stale anchors, and showing them again puts the keyring in the
    -- middle of the row with the toggle arrow sitting on top of the first bag.
    --
    -- Collapsing and expanding is our own toggle, not Blizzard's, so nothing here
    -- goes through OnExpandBarChanged and the hook on it never fires. This is the
    -- one path that has to re-anchor by itself.
    ReanchorBagRow()
end

function Module.RefreshBagBarToggle()
    if Module.db and Module.db.profile and Module.db.profile.bags then
        Module.BagBarExpandToggled(Module.db.profile.bags.expanded)
    end
end

function Module.ChangeFramerate()
    if Module.FPSFrame then return end

    local fps = CreateFrame('Frame', 'DragonflightUIFPSTextFrame', UIParent, 'DragonflightUIFPSTemplate')
    fps:SetSize(65, 26)
    if CharacterMicroButton then
        fps:SetPoint('RIGHT', CharacterMicroButton, 'LEFT', -10, 0)
    else
        fps:SetPoint('BOTTOMRIGHT', UIParent, 'BOTTOMRIGHT', -250, 0)
    end

    Module.FPSFrame = fps
end
