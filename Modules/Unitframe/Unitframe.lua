local addonName, addonTable = ...;
local Helper = addonTable.Helper;
---@diagnostic disable: undefined-global
local DF = LibStub('AceAddon-3.0'):GetAddon('DragonflightUI')
local L = LibStub("AceLocale-3.0"):GetLocale("DragonflightUI")

local mName = 'Unitframe'
local Module = DF:NewModule(mName, 'AceConsole-3.0', 'AceHook-3.0')

Mixin(Module, DragonflightUIModulesMixin)

-- TODOTBC
local TextStatusBar_UpdateTextString_orig = TextStatusBar_UpdateTextString;
local function TextStatusBar_UpdateTextString(f)
    if TextStatusBar_UpdateTextString_orig then
        TextStatusBar_UpdateTextString_orig(f)
    elseif f.UpdateTextString then
        f:UpdateTextString()
    end
end

Module.SubAltPower = DF:CreateFrameFromMixinAndInit(addonTable.SubModuleMixins['AltPower'])
Module.SubFocus = DF:CreateFrameFromMixinAndInit(addonTable.SubModuleMixins['Focus'])
Module.SubFocusTarget = DF:CreateFrameFromMixinAndInit(addonTable.SubModuleMixins['FocusTarget'])
Module.SubParty = DF:CreateFrameFromMixinAndInit(addonTable.SubModuleMixins['Party'])
Module.SubPet = DF:CreateFrameFromMixinAndInit(addonTable.SubModuleMixins['PetFrame'])
Module.SubPlayer = DF:CreateFrameFromMixinAndInit(addonTable.SubModuleMixins['PlayerFrame'])
Module.SubPlayerSecondaryRes = DF:CreateFrameFromMixinAndInit(addonTable.SubModuleMixins['PlayerFrameSecondaryRes'])
Module.SubPlayerTotemFrame = DF:CreateFrameFromMixinAndInit(addonTable.SubModuleMixins['TotemFrame'])
Module.SubRaid = DF:CreateFrameFromMixinAndInit(addonTable.SubModuleMixins['RaidFrame'])
Module.SubTarget = DF:CreateFrameFromMixinAndInit(addonTable.SubModuleMixins['Target'])
Module.SubTargetOfTarget = DF:CreateFrameFromMixinAndInit(addonTable.SubModuleMixins['TargetOfTarget'])

-- local db, getOptions

Module.famous = {['Norbert'] = true}

local defaults = {
    profile = {
        altpower = Module.SubAltPower.Defaults,
        focus = Module.SubFocus.Defaults,
        focusTarget = Module.SubFocusTarget.Defaults,
        party = Module.SubParty.Defaults,
        pet = Module.SubPet.Defaults,
        player = Module.SubPlayer.Defaults,
        playerSecondaryRes = Module.SubPlayerSecondaryRes.Defaults,
        playerTotemFrame = Module.SubPlayerTotemFrame.Defaults,
        raid = Module.SubRaid.Defaults,
        target = Module.SubTarget.Defaults,
        tot = Module.SubTargetOfTarget.Defaults
    }
}
Module:SetDefaults(defaults)

local localSettings = {
    scale = 1,
    focus = {scale = 1.0, anchor = 'TOPLEFT', anchorParent = 'TOPLEFT', x = 250, y = -170},
    player = {scale = 1.0, anchor = 'TOPLEFT', anchorParent = 'TOPLEFT', x = -19, y = -4},
    target = {scale = 1.0, anchor = 'TOPLEFT', anchorParent = 'TOPLEFT', x = 250, y = -4},
    pet = {scale = 1.0, anchor = 'TOPLEFT', anchorParent = 'TOPLEFT', x = 100, y = -70}
}

function Module:PrePositionHolderFrames()
    if not self.db or not self.db.profile then return end

    local mapping = {
        {name = 'DragonflightUIPlayerFrame', sub = 'player', defAnchor = 'TOPLEFT', defParent = 'TOPLEFT', defX = -19, defY = -4, sizeW = 232, sizeH = 100},
        {name = 'DragonflightUITargetFrame', sub = 'target', defAnchor = 'TOPLEFT', defParent = 'TOPLEFT', defX = 250, defY = -4, sizeW = 232, sizeH = 100},
        {name = 'DragonflightUIPetFrame', sub = 'pet', defAnchor = 'TOPRIGHT', defParent = 'BOTTOMRIGHT', defX = -3, defY = 28, sizeW = 120, sizeH = 49},
        {name = 'DragonflightUIFocusFrame', sub = 'focus', defAnchor = 'TOPLEFT', defParent = 'TOPLEFT', defX = 250, defY = -170, sizeW = 232, sizeH = 100},
        {name = 'DragonflightUITargetToTFrame', sub = 'tot', defAnchor = 'BOTTOMRIGHT', defParent = 'BOTTOMRIGHT', defX = -8, defY = -15, sizeW = 120, sizeH = 49},
        {name = 'DragonflightUIFocusToTFrame', sub = 'focustot', defAnchor = 'BOTTOMRIGHT', defParent = 'BOTTOMRIGHT', defX = -8, defY = -15, sizeW = 120, sizeH = 49},
        {name = 'DragonflightUIPartyMoveFrame', sub = 'party', defAnchor = 'TOPLEFT', defParent = 'TOPRIGHT', defX = 0, defY = 0, sizeW = 120, sizeH = 242}
    }

    for _, entry in ipairs(mapping) do
        local f = _G[entry.name]
        local subData = self.db.profile[entry.sub]
        if f and subData then
            f:Show()
            f:SetSize(entry.sizeW, entry.sizeH)
            f:SetParent(UIParent)
            f:SetScale(subData.scale or 1.0)
            f:SetMovable(true)
            f:EnableMouse(false)

            local parent
            if subData.customAnchorFrame and _G[subData.customAnchorFrame] then
                parent = _G[subData.customAnchorFrame]
            elseif subData.anchorFrame and _G[subData.anchorFrame] then
                parent = _G[subData.anchorFrame]
            else
                parent = UIParent
            end

            f:ClearAllPoints()
            f:SetPoint(subData.anchor or entry.defAnchor, parent, subData.anchorParent or entry.defParent, subData.x or entry.defX, subData.y or entry.defY)
        end
    end
end

function Module:OnInitialize()
    DF:Debug(self, 'Module ' .. mName .. ' OnInitialize()')
    self.db = DF.db:RegisterNamespace(mName, defaults)
    -- db = self.db.profile
    hooksecurefunc(DF:GetModule('Config'), 'AddConfigFrame', function()
        Module:RegisterSettings()
    end)

    self:SetEnabledState(DF.ConfigModule:GetModuleEnabled(mName))
    self:PrePositionHolderFrames()
end

function Module:OnEnable()
    DF:Debug(self, 'Module ' .. mName .. ' OnEnable()')
    self:SetWasEnabled(true)
    self:PrePositionHolderFrames()

    -- Setup submodules structures and apply visual styling immediately (textures, masks, colors)
    self:EnableAddonSpecific()
    Module.SubmodulesReady = true
    Module:ApplySettings()

    -- Unit frames secure parenting and points are protected; a combat reload must defer their
    -- secure setup until lockdown drops (see Helper:RunOutOfCombat).
    Helper:RunOutOfCombat('unit frames', function() Module:EnableOutOfCombat() end)
end

function Module:EnableOutOfCombat()
    -- Blizzard re-applies the EditMode layout on every PLAYER_ENTERING_WORLD
    -- (login, instance transitions), which resets player/target to the
    -- layout's positions - DFUI's custom positions are not stored there.
    -- Re-place our frames shortly after, once the layout application and
    -- any loading-screen churn are done.
    if not self.DFPEWReapply then
        local pew = CreateFrame('Frame')
        pew:RegisterEvent('PLAYER_ENTERING_WORLD')
        -- Also after combat: a mid-combat login reports no lockdown during
        -- load, so the enable-time SetPoints get silently blocked - the
        -- first regen re-places everything.
        pew:RegisterEvent('PLAYER_REGEN_ENABLED')
        pew:SetScript('OnEvent', function()
            C_Timer.After(0.7, function()
                if not Helper:IsCombatLocked() then Module:ApplySettings() end
            end)
        end)
        self.DFPEWReapply = pew
    end

    self:EnableAddonSpecific()

    -- The submodules are built; settings may now be applied to them. Set before
    -- the ApplySettings below, which is the first legitimate application.
    Module.SubmodulesReady = true

    Module:ApplySettings()
    Module:SaveLocalSettings()

    if not self.HooksInstalled then
        self.HooksInstalled = true
        hooksecurefunc('UIParent_UpdateTopFramePositions', function()
            Module:SaveLocalSettings()
        end)

        self:SecureHook(DF, 'RefreshConfig', function()
            -- print('RefreshConfig', mName)      
            Module:ApplySettings()
            Module:RefreshOptionScreens()
        end)
    end

    Module:FixBlizzardBug()
end

function Module:OnDisable()
end

function Module:RegisterSettings()
    local moduleName = 'Unitframe'
    local cat = 'unitframes'
    local function register(name, data)
        data.module = moduleName;
        DF.ConfigModule:RegisterSettingsElement(name, cat, data, true)
    end

    register('party', {order = 0, name = self.SubParty.Options.name, descr = 'Partyss', isNew = false})
    register('pet', {order = 0, name = self.SubPet.Options.name, descr = 'Petss', isNew = false})
    register('player', {order = 0, name = self.SubPlayer.Options.name, descr = 'players', isNew = false})
    register('playerSecondaryRes',
             {order = 0, name = self.SubPlayerSecondaryRes.Options.name, descr = 'players', isNew = false})
    register('playerTotemFrame',
             {order = 0, name = self.SubPlayerTotemFrame.Options.name, descr = 'players', isNew = true})
    register('raid', {order = 0, name = self.SubRaid.Options.name, descr = 'Raidss', isNew = false})
    register('target', {order = 0, name = self.SubTarget.Options.name, descr = 'Targetss', isNew = false})
    register('targetoftarget',
             {order = 0, name = self.SubTargetOfTarget.Options.name, descr = 'Targetss', isNew = false})

    if DF.Caps.HasFocus then
        register('focus', {order = 0, name = self.SubFocus.Options.name, descr = 'Focusss', isNew = false})
        register('focusTarget', {order = 0, name = self.SubFocusTarget.Options.name, descr = 'Focusss', isNew = false})
    end
    if DF.Caps.HasAltPower then
        register('altpower', {order = 0, name = self.SubAltPower.Options.name, descr = 'Focusss', isNew = false})
    end
end

function Module:RefreshOptionScreens()
    local configFrame = DF.ConfigModule.ConfigFrame

    local refreshCat = function(name)
        configFrame:RefreshCatSub('Unitframes', name)
    end

    refreshCat('Party')
    refreshCat('Pet')
    refreshCat('Player')
    refreshCat('playerSecondaryRes')
    refreshCat('Raid')
    refreshCat('Target')
    refreshCat('TargetOfTarget')

    if DF.Caps.HasFocus and _G['DragonflightUIFocusFrame'] then
        refreshCat('Focus')
        refreshCat('focusTarget')

        _G['DragonflightUIFocusFrame'].DFEditModeSelection:RefreshOptionScreen();
        _G['DragonflightUIFocusToTFrame'].DFEditModeSelection:RefreshOptionScreen();
    end
    if self.SubParty.PreviewParty then self.SubParty.PreviewParty.DFEditModeSelection:RefreshOptionScreen(); end
    _G['DragonflightUIPlayerFrame'].DFEditModeSelection:RefreshOptionScreen();
    _G['DragonflightUIPetFrame'].DFEditModeSelection:RefreshOptionScreen();
    -- self.SubRaid.PreviewRaid.DFEditModeSelection:RefreshOptionScreen();
    _G['DragonflightUITargetFrame'].DFEditModeSelection:RefreshOptionScreen();
    _G['DragonflightUITargetToTFrame'].DFEditModeSelection:RefreshOptionScreen();
    if DF.Cata then self.SubAltPower.PowerBarAltPreview.DFEditModeSelection:RefreshOptionScreen(); end
end

function Module:SaveLocalSettings()
    -- playerframe
    do
        local scale = PlayerFrame:GetScale()
        local point, relativeTo, relativePoint, xOfs, yOfs = PlayerFrame:GetPoint(1)
        -- print('PlayerFrame', point, relativePoint, xOfs, yOfs)

        local obj = localSettings.player
        obj.scale = scale
        obj.anchor = point
        obj.anchorParent = relativePoint
        obj.x = xOfs
        obj.y = yOfs
    end
    -- targetframe
    do
        local scale = TargetFrame:GetScale()
        local point, relativeTo, relativePoint, xOfs, yOfs = TargetFrame:GetPoint(1)
        -- print('TargetFrame', point, relativePoint, xOfs, yOfs)

        local obj = localSettings.target
        obj.scale = scale
        obj.anchor = point
        obj.anchorParent = relativePoint
        obj.x = xOfs
        obj.y = yOfs
    end
    --[[    -- petframe
    do
        local scale = PetFrame:GetScale()
        local point, relativeTo, relativePoint, xOfs, yOfs = PetFrame:GetPoint(1)
        -- print('TargetFrame', point, relativePoint, xOfs, yOfs)

        local obj = localSettings.pet
        obj.scale = scale
        obj.anchor = point
        obj.anchorParent = relativePoint
        obj.x = xOfs
        obj.y = yOfs
    end ]]
    -- focusframe
    if DF.Wrath then
        do
            local scale = FocusFrame:GetScale()
            local point, relativeTo, relativePoint, xOfs, yOfs = FocusFrame:GetPoint(1)
            -- print('FocusFrame', point, relativePoint, xOfs, yOfs)

            local obj = localSettings.focus
            obj.scale = scale
            obj.anchor = point
            obj.anchorParent = relativePoint
            obj.x = xOfs
            obj.y = yOfs
        end
    end

    -- DevTools_Dump({localSettings})
end

function Module:ApplySettings(sub, key)
    Helper:Benchmark(string.format('ApplySettings(%s,%s)', tostring(sub), tostring(key)), function()
        Module:ApplySettingsInternal(sub, key)
    end, 0, self)
end

-- One submodule's error used to abort every submodule after it in this list -
-- a broken party frame took the player, target and raid frames with it. Isolate
-- each, and report rather than swallow.
local function updateSub(name, sub, state)
    if not sub then return end

    local ok, err = pcall(sub.UpdateState, sub, state)
    if not ok then geterrorhandler()('DFUI Unitframe ' .. name .. ': ' .. tostring(err)) end
end

function Module:ApplySettingsInternal(sub, key)
    -- Nothing below can run before EnableAddonSpecific has built the
    -- submodules. The frames exist from XML, but SetMovable lives in each
    -- submodule's Setup, and SetUserPlaced on a frame that is not movable
    -- throws "Frame is not movable or resizable"; PlayerSecondaryRes has no
    -- preview frame at all until Setup creates it.
    --
    -- Callers do arrive early, and it is not a caller bug: unit frame setup is
    -- deferred out of combat (see OnEnable), and other modules enable before
    -- this one, so Utility's blue-shamans hook reaches ApplySettings while the
    -- frames are still raw. That produced one error per frame, on every login,
    -- for anyone whose module enable order or combat state got there first.
    --
    -- EnableOutOfCombat applies settings itself the moment setup finishes, so
    -- an early call has nothing to do rather than something to fail at.
    if not Module.SubmodulesReady then return end

    local db = Module.db.profile

    updateSub('party', self.SubParty, db.party)
    updateSub('player', self.SubPlayer, db.player)
    updateSub('playerSecondaryRes', self.SubPlayerSecondaryRes, db.playerSecondaryRes)
    if DF.Caps.HasTotemBar then updateSub('playerTotemFrame', self.SubPlayerTotemFrame, db.playerTotemFrame) end
    updateSub('pet', self.SubPet, db.pet)
    updateSub('target', self.SubTarget, db.target)
    updateSub('tot', self.SubTargetOfTarget, db.tot)
    updateSub('raid', self.SubRaid, db.raid)

    if DF.Caps.HasFocus then
        updateSub('focus', self.SubFocus, db.focus)
        updateSub('focusTarget', self.SubFocusTarget, db.focusTarget)
    end
    if DF.Caps.HasAltPower then updateSub('altpower', self.SubAltPower, db.altpower) end
end

function Module:FixBlizzardBug()
    if SetTextStatusBarText then
        SetTextStatusBarText(PlayerFrameManaBar, PlayerFrameManaBarText)
        SetTextStatusBarText(PlayerFrameHealthBar, PlayerFrameHealthBarText)
    end
    TextStatusBar_UpdateTextString(PlayerFrameHealthBar)
    TextStatusBar_UpdateTextString(PlayerFrameManaBar)
end

function Module:HookDrag()
    local DragStopPlayerFrame = function(_)
        self:SaveLocalSettings()

        for k, v in pairs(localSettings.player) do self.db.profile.player[k] = v end
        self.db.profile.player.anchorFrame = 'UIParent'
        self:RefreshOptionScreens()
    end
    PlayerFrame:HookScript('OnDragStop', DragStopPlayerFrame)
    if PlayerFrame_ResetUserPlacedPosition then
        hooksecurefunc('PlayerFrame_ResetUserPlacedPosition', DragStopPlayerFrame)
    end

    local DragStopTargetFrame = function(_)
        self:SaveLocalSettings()

        for k, v in pairs(localSettings.target) do self.db.profile.target[k] = v end
        self.db.profile.target.anchorFrame = 'UIParent'
        self:RefreshOptionScreens()
    end
    TargetFrame:HookScript('OnDragStop', DragStopTargetFrame)
    if TargetFrame_ResetUserPlacedPosition then
        hooksecurefunc('TargetFrame_ResetUserPlacedPosition', DragStopTargetFrame)
    end

    if DF.Wrath then
        local DragStopFocusFrame = function(_)
            self:SaveLocalSettings()

            for k, v in pairs(localSettings.focus) do self.db.profile.focus[k] = v end
            self.db.profile.focus.anchorFrame = 'UIParent'
            self:RefreshOptionScreens()
        end
        FocusFrame:HookScript('OnDragStop', DragStopFocusFrame)
        -- hooksecurefunc('FocusFrame_ResetUserPlacedPosition', DragStopFocusFrame)
    end
end

function Module:HookClassIcon()
    local base = 'Interface\\Addons\\DragonflightUI\\Textures\\UI\\'

    self:Unhook('UnitFramePortrait_Update')
    self:SecureHook('UnitFramePortrait_Update', function(portraitFrame)
        -- print('UnitFramePortrait_Update', portraitFrame:GetName(), portraitFrame.unit)
        if not portraitFrame.portrait then return end

        local icon = nil;
        local unit = portraitFrame.unit;
        local disableMasking = false;

        if unit == "player" then
            icon = self.db.profile.player.classicon
            disableMasking = true
        elseif unit == "target" then
            icon = self.db.profile.target.classicon
            disableMasking = true
        elseif unit == "focus" then
            icon = self.db.profile.focus.classicon
            disableMasking = true
        elseif unit == "targettarget" then
            icon = self.db.profile.tot.classicon
            disableMasking = true
        elseif unit == "focustarget" then
            icon = self.db.profile.focusTarget.classicon
            disableMasking = true
        end

        if (not icon) or unit == "pet" or (not UnitIsPlayer(unit)) then
            portraitFrame.portrait:SetTexCoord(0, 0, 0, 1, 1, 0, 1, 1)
            SetPortraitTexture(portraitFrame.portrait, unit, disableMasking)
            -- if portraitFrame.portrait.fixClassSize then portraitFrame.portrait:fixClassSize(false) end
            return
        end

        -- improved icons
        local class = select(2, UnitClass(unit));
        if class then
            if class == 'MONK' then
                local tex = base .. 'classicon-monk';
                portraitFrame.portrait:SetTexCoord(0, 0, 0, 1, 1, 0, 1, 1);
                portraitFrame.portrait:SetTexture(tex);
                return;
            else
                local classIconAtlas = GetClassAtlas(class);
                if (classIconAtlas) then
                    portraitFrame.portrait:SetAtlas(classIconAtlas);
                    return;
                end
            end
        end

        -- local texCoords = CLASS_ICON_TCOORDS[select(2, UnitClass(unit))]
        -- texCoords = CLASS_ICON_TCOORDS['WARRIOR']

        -- if texCoords then
        --     portraitFrame.portrait:SetTexture("Interface\\TargetingFrame\\UI-Classes-Circles")
        --     portraitFrame.portrait:SetTexCoord(unpack(texCoords))
        --     if portraitFrame.portrait.fixClassSize then portraitFrame.portrait:fixClassSize(true) end
        -- end
    end)
end

function Module:AddPortraitMasks()
    local playerMaskTexture = 'Interface\\Addons\\DragonflightUI\\Textures\\uiunitframeplayerportraitmask'
    local circularMaskTexture = 'Interface\\Addons\\DragonflightUI\\Textures\\tempportraitalphamask'

    do
        local mask = PlayerFrame:CreateMaskTexture()
        mask:SetPoint('CENTER', PlayerPortrait, 'CENTER', 1, -1)
        mask:SetTexture(playerMaskTexture, 'CLAMPTOBLACKADDITIVE', 'CLAMPTOBLACKADDITIVE')
        PlayerPortrait:AddMaskTexture(mask)
    end

    local function addMask(f, port, maskTexture)
        Helper:AddCircleMask(f, port, maskTexture)
    end

    addMask(TargetFrame, TargetFramePortrait)
    addMask(self.SubTarget.PreviewTarget, self.SubTarget.PreviewTarget.TargetFramePortrait)
    addMask(TargetFrameToT, TargetFrameToTPortrait)
    addMask(self.SubTargetOfTarget.PreviewTargetOfTarget,
            self.SubTargetOfTarget.PreviewTargetOfTarget.TargetFramePortrait)

    addMask(PetFrame, PetPortrait)

    if DF.Caps.HasFocus and FocusFrame then
        addMask(FocusFrame, FocusFramePortrait)
        if self.SubFocus.PreviewFocus then addMask(self.SubFocus.PreviewFocus, self.SubFocus.PreviewFocus.TargetFramePortrait) end
        if FocusFrameToT then addMask(FocusFrameToT, FocusFrameToTPortrait) end
        if self.SubFocusTarget.PreviewFocusTarget then addMask(self.SubFocusTarget.PreviewFocusTarget, self.SubFocusTarget.PreviewFocusTarget.TargetFramePortrait) end
    end

    -- fix portraits
    addMask(CharacterFrame, CharacterFramePortrait)
    addMask(PlayerTalentFrame, PlayerTalentFramePortrait)
    addMask(TradeFrame, TradeFramePlayerPortrait)
    addMask(TradeFrame, TradeFrameRecipientPortrait)
    addMask(DressUpFrame, DressUpFramePortrait)
end

function Module:HookEnergyBar()
    hooksecurefunc("UnitFrameManaBar_UpdateType", function(manaBar, dontcall)
        if manaBar.DFUpdateFunc and type(manaBar.DFUpdateFunc) == 'function' and not dontcall then
            manaBar.DFUpdateFunc()
        end
    end)
end

function Module:ChangeFonts()
    local newFont = 'Fonts\\FRIZQT__.ttf'

    local locale = GetLocale()
    if locale == "ruRU" then
        newFont = "Fonts\\FRIZQT___CYR.TTF"
    elseif locale == "koKR" then
        newFont = "Fonts\\2002.TTF"
    elseif locale == "zhCN" then
        newFont = "Fonts\\ARKai_T.TTF"
    elseif locale == "zhTW" then
        newFont = "Fonts\\blei00d.TTF"
    end

    local changeFont = function(f, newsize)
        if not f then return end
        local path, size, flags = f:GetFont()
        f:SetFont(newFont, newsize, flags)
    end

    local std = 11

    changeFont(PlayerFrameHealthBarText, std)
    changeFont(PlayerFrameHealthBarTextLeft, std)
    changeFont(PlayerFrameHealthBarTextRight, std)
    changeFont(PlayerFrameManaBarText, std)
    changeFont(PlayerFrameManaBarTextLeft, std)
    changeFont(PlayerFrameManaBarTextRight, std)

    changeFont(PetFrameHealthBarText, std)
    changeFont(PetFrameHealthBarTextLeft, std)
    changeFont(PetFrameHealthBarTextRight, std)
    changeFont(PetFrameManaBarText, std)
    changeFont(PetFrameManaBarTextLeft, std)
    changeFont(PetFrameManaBarTextRight, std)

    if TargetFrameTextureFrame then
        changeFont(TargetFrameTextureFrame.HealthBarText, std)
        changeFont(TargetFrameTextureFrame.HealthBarTextLeft, std)
        changeFont(TargetFrameTextureFrame.HealthBarTextRight, std)
        changeFont(TargetFrameTextureFrame.ManaBarText, std)
        changeFont(TargetFrameTextureFrame.ManaBarTextLeft, std)
        changeFont(TargetFrameTextureFrame.ManaBarTextRight, std)
    end

    if DF.Caps.HasFocus and FocusFrameTextureFrame then
        changeFont(FocusFrameTextureFrame.HealthBarText, std)
        changeFont(FocusFrameTextureFrame.HealthBarTextLeft, std)
        changeFont(FocusFrameTextureFrame.HealthBarTextRight, std)
        changeFont(FocusFrameTextureFrame.ManaBarText, std)
        changeFont(FocusFrameTextureFrame.ManaBarTextLeft, std)
        changeFont(FocusFrameTextureFrame.ManaBarTextRight, std)
    end
end

function Module:AddRoleSelectDropdownOption()
    -- 
    local PlayerClassRoleTable = DragonflightUITalentsPanelMixin.PlayerClassRoleTable
    local function canUnitClassBeRole(unit, role)
        local _, _, classID = UnitClass(unit)

        local classTable = PlayerClassRoleTable[classID]
        if not classTable then return false; end

        -- DevTools_Dump(classTable)

        for _, v in ipairs(classTable) do
            --
            for _, v2 in ipairs(v) do
                --
                -- print(k2, v2)
                if v2 == role then return true; end
            end
        end

        return false;
    end

    local function incombatWarning()
        Module:Print("Can't set role in combat through addon code, sorry.")
    end

    local function addMenu(ownerRegion, rootDescription, contextData)
        -- print('addMenu', ownerRegion, rootDescription, contextData)
        local unit = contextData.unit;
        if not unit then return end

        if not UnitIsPlayer(unit) then return end
        -- if not IsInGroup() and not IsInRaid() then return end;

        local submenu;
        if false then
            -- local menuButton = MenuUtil.CreateButton('testbutton')
            rootDescription:CreateDivider()
            rootDescription:CreateTitle("DragonflightUI")

            submenu = rootDescription:CreateButton('Select Role')
        else
            local tit = MenuUtil.CreateTitle('DragonflightUI')
            rootDescription:Insert(tit, 2)

            ---@diagnostic disable-next-line: missing-parameter
            submenu = MenuUtil.CreateButton('Select Role')
            rootDescription:Insert(submenu, 3)

            local div = MenuUtil.CreateDivider()
            rootDescription:Insert(div, 4)
        end

        local isLeader = UnitIsGroupLeader('player');
        local hasAssist = UnitIsGroupAssistant('player');

        if isLeader or hasAssist or UnitIsUnit(unit, 'player') then
            submenu:SetEnabled(true);
        else
            submenu:SetEnabled(false);
        end

        local tank = submenu:CreateRadio(
                         '|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES:16:16:0:0:64:64:0:19:22:41|t ' .. 'Tank',
                         function()
                return UnitGroupRolesAssigned(unit) == 'TANK'
            end, function()
                if InCombatLockdown() then
                    incombatWarning();
                    return;
                end
                UnitSetRole(unit, 'TANK')
            end)
        if not canUnitClassBeRole(unit, 'TANK') then tank:SetEnabled(false) end

        local heal = submenu:CreateRadio(
                         '|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES:16:16:0:0:64:64:20:39:1:20|t ' .. 'Healer',
                         function()
                return UnitGroupRolesAssigned(unit) == 'HEALER'
            end, function()
                if InCombatLockdown() then
                    incombatWarning();
                    return;
                end
                UnitSetRole(unit, 'HEALER')
            end)
        if not canUnitClassBeRole(unit, 'HEALER') then heal:SetEnabled(false) end

        local dd = submenu:CreateRadio(
                       '|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES:16:16:0:0:64:64:20:39:22:41|t ' .. 'Damage',
                       function()
                return UnitGroupRolesAssigned(unit) == 'DAMAGER'
            end, function()
                if InCombatLockdown() then
                    incombatWarning();
                    return;
                end
                UnitSetRole(unit, 'DAMAGER')
            end)
        -- if not canUnitClassBeRole(unit, 'DAMAGER') then dd:SetEnabled(false) end

        local noRole = submenu:CreateRadio('No Role', function()
            return UnitGroupRolesAssigned(unit) == 'NONE'
        end, function()
            if InCombatLockdown() then
                incombatWarning();
                return;
            end
            UnitSetRole(unit, 'NONE')
        end)
    end

    local t = {
        'MENU_UNIT_SELF', 'MENU_UNIT_PLAYER', 'MENU_UNIT_TARGET', 'MENU_UNIT_FOCUS', 'MENU_UNIT_PARTY',
        'MENU_UNIT_RAID', 'MENU_UNIT_RAID_PLAYER'
    }
    for k, v in ipairs(t) do
        --
        Menu.ModifyMenu(v, addMenu)
    end

end

function Module:TakePicture()
    if not Module.PictureTakerFrame then
        local pt = CreateFrame('FRAME', 'DragonflightUIPictureTakerFrame', UIParent);
        local size = 256
        local border = 0;
        pt:SetSize(size + 2 * border, size + 2 * border);
        pt:SetPoint('CENTER', UIParent, 'CENTER', 0, 0)

        local tex = pt:CreateTexture(nil, 'BACKGROUND');
        tex:SetColorTexture(0, 0, 0, 1)
        tex:SetPoint('TOPLEFT')
        tex:SetPoint('BOTTOMRIGHT')

        local port = pt:CreateTexture(nil, 'OVERLAY')
        port:SetPoint('TOPLEFT', tex, 'TOPLEFT', border, -border)
        port:SetPoint('BOTTOMRIGHT', tex, 'BOTTOMRIGHT', -border, border)
        pt.Portrait = port;

        local circularMaskTexture = 'Interface\\Addons\\DragonflightUI\\Textures\\tempportraitalphamask'
        local mask = pt:CreateMaskTexture()
        mask:SetAllPoints(port)
        mask:SetTexture(circularMaskTexture, 'CLAMPTOBLACKADDITIVE', 'CLAMPTOBLACKADDITIVE')
        port:AddMaskTexture(mask)

        pt:Hide()
        Module.PictureTakerFrame = pt;

        function Module.PictureTakerFrame:Update()
            -- print('update....')
            SetPortraitTexture(pt.Portrait, 'target')
        end
    end

    if Module.PictureTakerFrame:IsVisible() then
        Module.PictureTakerFrame:Hide()
    else
        Module.PictureTakerFrame:Show()
        Module.PictureTakerFrame:Update()
    end
end
Module:RegisterChatCommand('cheeese', 'TakePicture')

function Module:SetupSubmodules()
    if self.SubmodulesSetupDone then return end
    self.SubmodulesSetupDone = true

    if DF.Caps.HasFocus then
        self.SubFocus:Setup()
        self.SubFocusTarget:Setup()
    end

    if DF.Caps.HasAltPower then
        self.SubAltPower:Setup()
    end

    self.SubParty:Setup()
    self.SubPlayer:Setup()
    self.SubPlayerSecondaryRes:Setup()
    if DF.Caps.HasTotemBar then
        self.SubPlayerTotemFrame:Setup()
    end

    self.SubPet:Setup()
    self.SubTarget:Setup()
    self.SubTargetOfTarget:Setup()
    self.SubRaid:Setup()

    self:HookEnergyBar()
    self:ChangeFonts()
    self:HookDrag()
    self:AddPortraitMasks()
    self:HookClassIcon()

    if Menu and Menu.ModifyMenu then
        self:AddRoleSelectDropdownOption()
    end

    if DF.Caps.HasEditMode and DF.Caps.HasFocus then
        local EditModeModule = DF:GetModule('Editmode')
        if EditModeModule and EditModeModule.ShowEditmodeWarning then
            EditModeModule:ShowEditmodeWarning(3, 0, 'Target and Focus')
        end
    end
end

function Module:Era()
    self:SetupSubmodules()
end

function Module:TBC()
    self:SetupSubmodules()
end

function Module:Wrath()
    self:SetupSubmodules()
end

function Module:Cata()
    self:SetupSubmodules()
end

function Module:Mists()
    self:SetupSubmodules()
end
