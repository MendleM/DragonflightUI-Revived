local addonName, addonTable = ...;
local Helper = addonTable.Helper;
local DF = LibStub('AceAddon-3.0'):GetAddon('DragonflightUI')
local L = LibStub("AceLocale-3.0"):GetLocale("DragonflightUI")
local mName = 'Darkmode'
local Module = DF:NewModule(mName, 'AceConsole-3.0', 'AceHook-3.0')

Mixin(Module, DragonflightUIModulesMixin)

local CreateColor = DFCreateColor
local CreateColorFromRGBHexString = DFCreateColorFromRGBHexString

local defaults = {
    profile = {
        scale = 1,
        general = {
            -- Unitframes
            unitframeDesaturate = true,
            -- unitframeHealthDesaturate = true,
            unitframeColor = CreateColor(77 / 255, 77 / 255, 77 / 255):GenerateHexColorNoAlpha(),
            -- Minimap
            minimapDesaturate = true,
            minimapColor = CreateColor(0.4, 0.4, 0.4):GenerateHexColorNoAlpha(),
            -- ui
            uiDesaturate = true,
            uiColor = CreateColor(0.4, 0.4, 0.4):GenerateHexColorNoAlpha(),
            -- Actionbar
            actionbarDesaturate = true,
            actionbarColor = CreateColor(0.4, 0.4, 0.4):GenerateHexColorNoAlpha(),
            -- Buffs
            buffDesaturate = true,
            buffColor = CreateColor(0.4, 0.4, 0.4):GenerateHexColorNoAlpha(),
            -- Castbar
            castbarDesaturate = true,
            castbarColor = CreateColor(0.4, 0.4, 0.4):GenerateHexColorNoAlpha(),
            -- Flyout
            flyoutDesaturate = true,
            flyoutColor = CreateColor(0.4, 0.4, 0.4):GenerateHexColorNoAlpha()
        }
    }
}
Module:SetDefaults(defaults)

local function getDefaultStr(key, sub, extra)
    return Module:GetDefaultStr(key, sub, extra)
end

local function setDefaultValues()
    Module:SetDefaultValues()
end

local function setDefaultSubValues(sub)
    Module:SetDefaultSubValues(sub)
end

local function getOption(info)
    return Module:GetOption(info)
end

local function setOption(info, value)
    Module:SetOption(info, value)
end

local generalOptions = {
    type = 'group',
    name = 'Darkmode',
    get = getOption,
    set = setOption,
    sortComparator = DFSettingsListMixin.AlphaSortComparator,
    args = {
        -- scale = {
        --     type = 'range',
        --     name = 'Scale',
        --     desc = '' .. getDefaultStr('scale', 'minimap'),
        --     min = 0.1,
        --     max = 5,
        --     bigStep = 0.1,
        --     order = 1
        -- }   
        headerUnitframes = {
            type = 'header',
            name = L["UnitFramesName"],
            desc = '...',
            order = 100,
            isExpanded = true,
            sortComparator = DFSettingsListMixin.AlphaSortComparator
        },
        unitframeDesaturate = {
            type = 'toggle',
            name = 'Desaturate',
            desc = '' .. getDefaultStr('unitframeDesaturate', 'general'),
            group = 'headerUnitframes',
            order = 100.5
        },
        -- unitframeHealthDesaturate = {
        --     type = 'toggle',
        --     name = 'Desaturate Healthbar',
        --     desc = '' .. getDefaultStr('unitframeHealthDesaturate', 'general'),
        --     order = 100.6
        -- },

        unitframeColor = {
            type = 'color',
            name = L["DarkmodeColor"],
            desc = '' .. getDefaultStr('unitframeColor', 'general', '#'),
            group = 'headerUnitframes',
            order = 105
        },
        headerMinimap = {
            type = 'header',
            name = L["MinimapName"],
            desc = '...',
            order = 200,
            isExpanded = true,
            sortComparator = DFSettingsListMixin.AlphaSortComparator
        },
        minimapDesaturate = {
            type = 'toggle',
            name = L["DarkmodeDesaturate"],
            desc = '' .. getDefaultStr('minimapDesaturate', 'general'),
            group = 'headerMinimap',
            order = 200.5
        },
        minimapColor = {
            type = 'color',
            name = L["DarkmodeColor"],
            desc = '' .. getDefaultStr('minimapColor', 'general', '#'),
            group = 'headerMinimap',
            order = 201
        },
        headerUI = {
            type = 'header',
            name = L["UIName"],
            desc = '...',
            order = 200,
            isExpanded = true,
            sortComparator = DFSettingsListMixin.AlphaSortComparator
        },
        uiDesaturate = {
            type = 'toggle',
            name = L["DarkmodeDesaturate"],
            desc = '' .. getDefaultStr('minimapuiDesaturateDesaturate', 'general'),
            group = 'headerUI',
            order = 200.5
        },
        uiColor = {
            type = 'color',
            name = L["DarkmodeColor"],
            desc = '' .. getDefaultStr('uiColor', 'general', '#'),
            group = 'headerUI',
            order = 201
        },
        headerActionbar = {
            type = 'header',
            name = L["ActionbarName"],
            desc = '...',
            order = 300,
            isExpanded = true,
            sortComparator = DFSettingsListMixin.AlphaSortComparator
        },
        actionbarDesaturate = {
            type = 'toggle',
            name = L["DarkmodeDesaturate"],
            desc = '' .. getDefaultStr('actionbarDesaturate', 'general'),
            group = 'headerActionbar',
            order = 300.5
        },
        actionbarColor = {
            type = 'color',
            name = L["DarkmodeColor"],
            desc = '' .. getDefaultStr('actionbarColor', 'general', '#'),
            group = 'headerActionbar',
            order = 301
        },
        headerBuff = {
            type = 'header',
            name = L["BuffsOptionsName"],
            desc = '...',
            order = 400,
            isExpanded = true,
            sortComparator = DFSettingsListMixin.AlphaSortComparator
        },
        buffDesaturate = {
            type = 'toggle',
            name = L["DarkmodeDesaturate"],
            desc = '' .. getDefaultStr('buffDesaturate', 'general'),
            group = 'headerBuff',
            order = 400.5
        },
        buffColor = {
            type = 'color',
            name = L["DarkmodeColor"],
            desc = '' .. getDefaultStr('buffColor', 'general', '#'),
            group = 'headerBuff',
            order = 401
        },
        headerCastbar = {
            type = 'header',
            name = L["CastbarName"],
            desc = '...',
            order = 500,
            isExpanded = true,
            sortComparator = DFSettingsListMixin.AlphaSortComparator
        },
        castbarDesaturate = {
            type = 'toggle',
            name = L["DarkmodeDesaturate"],
            desc = '' .. getDefaultStr('castbarDesaturate', 'general'),
            group = 'headerCastbar',
            order = 500.1
        },
        castbarColor = {
            type = 'color',
            name = L["DarkmodeColor"],
            desc = '' .. getDefaultStr('castbarColor', 'general', '#'),
            group = 'headerCastbar',
            order = 501
        },
        headerFlyout = {
            type = 'header',
            name = L["FlyoutHeader"],
            desc = '...',
            order = 600,
            isExpanded = true,
            sortComparator = DFSettingsListMixin.AlphaSortComparator
        },
        flyoutDesaturate = {
            type = 'toggle',
            name = L["DarkmodeDesaturate"],
            desc = '' .. getDefaultStr('flyoutDesaturate', 'general'),
            group = 'headerFlyout',
            order = 600.1
        },
        flyoutColor = {
            type = 'color',
            name = L["DarkmodeColor"],
            desc = '' .. getDefaultStr('flyoutColor', 'general', '#'),
            group = 'headerFlyout',
            order = 600.2
        }
    }
}

function Module:OnInitialize()
    DF:Debug(self, 'Module ' .. mName .. ' OnInitialize()')
    self.db = DF.db:RegisterNamespace(mName, defaults)
    hooksecurefunc(DF:GetModule('Config'), 'AddConfigFrame', function()
        Module:RegisterSettings()
    end)

    self:SetEnabledState(DF.ConfigModule:GetModuleEnabled(mName))

    DF:RegisterModuleOptions(mName, generalOptions)
end

function Module:OnEnable()
    DF:Debug(self, 'Module ' .. mName .. ' OnEnable()')
    self:SetWasEnabled(true)

    self:EnableAddonSpecific()

    Module:ApplySettings()
    Module:RegisterOptionScreens()

    -- TODO: hack, bar 2-5 gets overriden
    C_Timer.After(0, function()
        local state = self:GetState()
        Module:UpdateActionbar(state)
    end)

    if not self:IsHooked(DF, 'RefreshConfig') then
        self:SecureHook(DF, 'RefreshConfig', function()
            Module:ApplySettings()
            Module:RefreshOptionScreens()
        end)
    end
end

function Module:OnDisable()
    DF:Debug(self, 'Module ' .. mName .. ' OnDisable()')
    self:SetWasEnabled(false)
    Module:ApplySettings()
end

function Module:RegisterSettings()
    local moduleName = 'Darkmode'
    local cat = 'misc'
    local function register(name, data)
        data.module = moduleName;
        DF.ConfigModule:RegisterSettingsElement(name, cat, data, true)
    end

    register('darkmode', {order = 0, name = 'Dark Mode', descr = 'Darkmodess', isNew = false})
end

function Module:RegisterOptionScreens()
    DF.ConfigModule:RegisterSettingsData('darkmode', 'misc', {
        name = 'Darkmode',
        sub = 'general',
        options = generalOptions,
        sortComparator = generalOptions.sortComparator,
        default = function()
            setDefaultSubValues('general')
        end
    })
end

function Module:RefreshOptionScreens()
    -- print('Module:RefreshOptionScreens()')

    local configFrame = DF.ConfigModule.ConfigFrame
    local cat = 'Misc'
    configFrame:RefreshCatSub(cat, 'Darkmode')
end

function Module:ApplySettings(sub, key)
    Helper:Benchmark(string.format('ApplySettings(%s,%s)', tostring(sub), tostring(key)), function()
        Module:ApplySettingsInternal(sub, key)
    end, 0, self)
end

local defaultState = setmetatable({}, {
    __index = function(_, k)
        return k:find('Color') and 'ffffff' or false
    end
})

function Module:GetState()
    local isEnabled = DF.ConfigModule:GetModuleEnabled(mName)
    if isEnabled == nil then isEnabled = self:IsEnabled() end
    return isEnabled and self.db.profile.general or defaultState
end

function Module:ApplySettingsInternal(sub, key)
    local isEnabled = DF.ConfigModule:GetModuleEnabled(mName)
    if isEnabled == nil then isEnabled = self:IsEnabled() end
    DF:Debug(self, 'ApplySettingsInternal', isEnabled and 'ENABLED' or 'DISABLED')
    local state = self:GetState()

    Module:UpdateMinimap(state)
    Module:UpdateUnitframe(state)
    Module:UpdateActionbar(state)
    Module:UpdateFlyout(state)
    Module:UpdateBuff(state)
    Module:UpdateCastbar(state)
    Module:UpdateUI(state)
end

function Module:UpdateMinimapButton(btn)
    local border = btn.DFTrackingBorder
    if not border then return end

    local state = self:GetState()
    local c = CreateColorFromRGBHexString(state.minimapColor)

    border:SetDesaturated(state.minimapDesaturate)
    border:SetVertexColor(c:GetRGB())
end

function Module:UpdateMinimap(state)
    local moduleName = 'Minimap'
    local minimapModule = DF:GetModule(moduleName)

    if not DF.ConfigModule:GetModuleEnabled(moduleName) then
        -- default
        -- minimapBorderTex:SetDesaturated(false)
        -- minimapBorderTex:SetVertexColor(1.0, 1.0, 1.0)
        return
    end

    -- local minimapBorderTex = minimapModule.Frame.minimap
    local minimapBorderTex = minimapModule.SubMinimap.MinimapBorder
    if not minimapBorderTex then return end -- TODO: HACK

    local c = CreateColorFromRGBHexString(state.minimapColor)

    -- minimapBorderTex:SetDesaturated(true)
    -- minimapBorderTex:SetVertexColor(0.4, 0.4, 0.4)  

    minimapBorderTex:SetDesaturated(state.minimapDesaturate)
    minimapBorderTex:SetVertexColor(c:GetRGB())

    minimapModule.SubMinimap.MinimapBorderSquare:SetDesaturated(state.minimapDesaturate)
    minimapModule.SubMinimap.MinimapBorderSquare:SetVertexColor(c:GetRGB())

    MinimapCompassTexture:SetDesaturated(state.minimapDesaturate)
    MinimapCompassTexture:SetVertexColor(c:GetRGB())

    MinimapZoomIn:GetNormalTexture():SetDesaturated(state.minimapDesaturate)
    MinimapZoomIn:GetNormalTexture():SetVertexColor(c:GetRGB())
    MinimapZoomIn:GetDisabledTexture():SetDesaturated(state.minimapDesaturate)
    MinimapZoomIn:GetDisabledTexture():SetVertexColor(c:GetRGB())

    MinimapZoomOut:GetNormalTexture():SetDesaturated(state.minimapDesaturate)
    MinimapZoomOut:GetNormalTexture():SetVertexColor(c:GetRGB())
    MinimapZoomOut:GetDisabledTexture():SetDesaturated(state.minimapDesaturate)
    MinimapZoomOut:GetDisabledTexture():SetVertexColor(c:GetRGB())

    -- TODO: minimap buttons

    -- if dark then
    --     minimapBorderTex:SetDesaturated(true)
    --     minimapBorderTex:SetVertexColor(0.4, 0.4, 0.4)
    -- else
    --     minimapBorderTex:SetDesaturated(false)
    --     minimapBorderTex:SetVertexColor(1.0, 1.0, 1.0)
    -- end

    local libIcon = LibStub("LibDBIcon-1.0")

    if not libIcon then return end

    local f = minimapModule.SubMinimap;
    if not f.DarkmodeButtonHooked then
        f.DarkmodeButtonHooked = true

        hooksecurefunc(f, 'UpdateButton', function(_, btn)
            Module:UpdateMinimapButton(btn)
        end)
    end

    local buttons = libIcon:GetButtonList()

    for k, v in ipairs(buttons) do
        local btn = libIcon:GetMinimapButton(v)

        if btn then
            --
            Module:UpdateMinimapButton(btn)
        end
    end

    if _G['MiniMapBattlefieldFrame'] then Module:UpdateMinimapButton(_G['MiniMapBattlefieldFrame']) end

    if DF.Era then
        -- if _G['LFGMinimapFrameBorder'] then
        --     _G['LFGMinimapFrameBorder']:SetDesaturated(state.minimapDesaturate)
        --     _G['LFGMinimapFrameBorder']:SetVertexColor(c:GetRGB())
        -- else
        --     if not f.DarkModeLFGHooked then
        --         f.DarkModeLFGHooked = true

        --         hooksecurefunc(minimapModule, 'ChangeLFGEra', function()
        --             --
        --             local db = Module.db.profile
        --             local state = db.general
        --             if _G['LFGMinimapFrameBorder'] then
        --                 _G['LFGMinimapFrameBorder']:SetDesaturated(state.minimapDesaturate)
        --                 _G['LFGMinimapFrameBorder']:SetVertexColor(c:GetRGB())
        --             end
        --         end)
        --     end
        -- end

        if _G['MiniMapTrackingBorder'] then
            _G['MiniMapTrackingBorder']:SetDesaturated(state.minimapDesaturate)
            _G['MiniMapTrackingBorder']:SetVertexColor(c:GetRGB())
        end
    end
end

function Module:UpdateUI(state)
    local moduleName = 'UI'
    local uiModule = DF:GetModule(moduleName)

    if not DF.ConfigModule:GetModuleEnabled(moduleName) then return end
end

function Module:UpdateUnitframe(state)
    local moduleName = 'Unitframe'
    if not DF.ConfigModule:GetModuleEnabled(moduleName) then return end

    local unitModule = DF:GetModule(moduleName)
    local f = unitModule
    local c = CreateColorFromRGBHexString(state.unitframeColor)

    -- player
    if unitModule.SubPlayer then
        if not f.DarkmodePlayerStatusHooked then
            f.DarkmodePlayerStatusHooked = true
            hooksecurefunc(unitModule.SubPlayer, 'UpdatePlayerStatus', function()
                self:UpdatePlayerFrame(self:GetState())
            end)
        end
        self:UpdatePlayerFrame(state)
    end

    -- target
    if unitModule.SubTarget then
        if not f.DarkmodeTargetHooked then
            f.DarkmodeTargetHooked = true
            hooksecurefunc(unitModule.SubTarget, 'ChangeTargetFrame', function()
                self:UpdateTargetFrame(self:GetState())
            end)
        end
        self:UpdateTargetFrame(state)
    end

    -- pet
    self:UpdatePetFrame(state)

    -- party
    self:UpdatePartyFrame(state)

    -- focus
    if DF.Caps.HasFocus and unitModule.SubFocus then
        if not f.DarkmodeFocusHooked then
            f.DarkmodeFocusHooked = true
            hooksecurefunc(unitModule.SubFocus, 'ChangeFocusFrame', function()
                self:UpdateFocusFrame(self:GetState())
            end)
        end
        self:UpdateFocusFrame(state)
    end

    -- boss
    local bossModule = DF:GetModule('Bossframe', true)
    if bossModule then
        if not bossModule.DarkmodeBossHooked then
            bossModule.DarkmodeBossHooked = true;
            hooksecurefunc(bossModule, 'CreateBossFrames', function()
                self:UpdateBossFrame(self:GetState())
            end)
        end
        self:UpdateBossFrame(state)
    end
end

function Module:UpdatePlayerFrame(state)
    local unitModule = DF:GetModule('Unitframe')
    local f = unitModule.SubPlayer
    local c = CreateColorFromRGBHexString(state.unitframeColor)
    local isEnabled = self:IsEnabled()

    if not f.PlayerFrameDeco then return end

    local playerFrameBackground = f.PlayerFrameBackground
    local playerFrameDeco = f.PlayerFrameDeco
    local playerFramePortaitExtra = f.PlayerPortraitExtra

    playerFrameBackground:SetDesaturated(state.unitframeDesaturate)
    playerFrameBackground:SetVertexColor(c:GetRGB())

    playerFrameDeco:SetDesaturated(state.unitframeDesaturate)
    playerFrameDeco:SetVertexColor(c:GetRGB())

    local extraColor = isEnabled and 0.6 or 1.0
    playerFramePortaitExtra:SetVertexColor(extraColor, extraColor, extraColor)

    -- PlayerFrameHealthBar:GetStatusBarTexture():SetDesaturated(state.unitframeHealthDesaturate)

    local altPowerBorder = _G['PlayerFrameAlternateManaBarBorder']
    local altPowerBorderLeft = _G['PlayerFrameAlternateManaBarLeftBorder']
    local altPowerBorderRight = _G['PlayerFrameAlternateManaBarRightBorder']

    if altPowerBorder and altPowerBorderLeft and altPowerBorderRight then
        altPowerBorder:SetVertexColor(c:GetRGB())
        altPowerBorderLeft:SetVertexColor(c:GetRGB())
        altPowerBorderRight:SetVertexColor(c:GetRGB())
    end

    local altPowerBorderDF = _G['DragonflightUIAlternatePowerBarBorder']
    if altPowerBorderDF then altPowerBorderDF:SetVertexColor(c:GetRGB()) end
end

function Module:UpdatePetFrame(state)
    local unitModule = DF:GetModule('Unitframe')
    local f = unitModule.SubPet
    local c = CreateColorFromRGBHexString(state.unitframeColor)

    if not f.PetFrameBackground then return end

    local petBackground = f.PetFrameBackground

    petBackground:SetDesaturated(state.unitframeDesaturate)
    petBackground:SetVertexColor(c:GetRGB())
end

function Module:UpdateTargetFrame(state)
    local unitModule = DF:GetModule('Unitframe')
    local f = unitModule.SubTarget
    local c = CreateColorFromRGBHexString(state.unitframeColor)
    local isEnabled = self:IsEnabled()

    if not f or not f.TargetFrameBackground then return end

    local TargetFrameBackground = f.TargetFrameBackground
    local targetPortExtra = f.PortraitExtra

    TargetFrameBackground:SetDesaturated(state.unitframeDesaturate)
    TargetFrameBackground:SetVertexColor(c:GetRGB())

    -- Target-of-target is built later than the target frame, and on a reload in
    -- combat later still - the setup chain defers what it cannot do while the
    -- player is in combat. Darkmode can arrive before the background texture
    -- exists, which is what threw "attempt to index local
    -- 'TargetFrameToTBackground' (a nil value)". Skip just this piece rather
    -- than returning: the target frame below still wants darkening, and
    -- ChangeTargetFrame calls us again on the next target change.
    local tot = unitModule.SubTargetOfTarget
    local TargetFrameToTBackground = tot and tot.TargetFrameToTBackground
    if TargetFrameToTBackground then
        TargetFrameToTBackground:SetDesaturated(state.unitframeDesaturate)
        TargetFrameToTBackground:SetVertexColor(c:GetRGB())
    end

    local extraColor = isEnabled and 0.6 or 1.0
    targetPortExtra:SetVertexColor(extraColor, extraColor, extraColor)

    -- editmode
    local e = f.PreviewTarget
    if e and e.TargetFrameBackground then
        e.TargetFrameBackground:SetDesaturated(state.unitframeDesaturate)
        e.TargetFrameBackground:SetVertexColor(c:GetRGB())
        if e.PortraitExtra then
            e.PortraitExtra:SetVertexColor(extraColor, extraColor, extraColor)
        end
    end
end

function Module:UpdatePartyFrame(state)
    local unitModule = DF:GetModule('Unitframe')
    local f = unitModule.SubParty
    local c = CreateColorFromRGBHexString(state.unitframeColor)

    -- Modern pooled party frames (Era 1.15.9+, TBC 2.5.6+, MoP 5.5.4+).
    --
    -- This is why the party border stayed golden while every other unit frame
    -- went dark: the loop below walks PartyMemberFrame1..4, and on these clients
    -- those globals do not exist - the frames come out of
    -- PartyFrame.PartyMemberFramePool. The loop found nothing and failed quietly.
    -- Version.API knows this as DF.Caps.HasPooledParty.
    --
    -- The border texture is not on the frame either, so Party.mixin hands out an
    -- iterator rather than the table it keeps them in.
    if f and f.ForEachPartyBorder then
        f.ForEachPartyBorder(function(border)
            border:SetDesaturated(state.unitframeDesaturate)
            border:SetVertexColor(c:GetRGB())
        end)
    end

    -- Older clients, where the four member frames are real globals.
    for i = 1, 4 do
        local pf = _G['PartyMemberFrame' .. i]

        if pf and pf.PartyFrameBorder then
            pf.PartyFrameBorder:SetDesaturated(state.unitframeDesaturate)
            pf.PartyFrameBorder:SetVertexColor(c:GetRGB())
        end
    end

    -- editmode
    local e = f.PreviewParty
    if e and e.PartyFrames then
        for k, v in ipairs(e.PartyFrames) do
            --
            v.TargetFrameBorder:SetDesaturated(state.unitframeDesaturate)
            v.TargetFrameBorder:SetVertexColor(c:GetRGB())
        end
    end
end

function Module:UpdateFocusFrame(state)
    local unitModule = DF:GetModule('Unitframe')
    local f = unitModule.SubFocus

    if not f or not f.TargetFrameBackground then return end

    local focusBackground = f.TargetFrameBackground
    local focusPortExtra = f.PortraitExtra
    local isEnabled = self:IsEnabled()

    local c = CreateColorFromRGBHexString(state.unitframeColor)

    focusBackground:SetDesaturated(state.unitframeDesaturate)
    focusBackground:SetVertexColor(c:GetRGB())

    local tot = unitModule.SubFocusTarget
    local FocusFrameToTBackground = tot and tot.FocusFrameToTBackground
    if FocusFrameToTBackground then
        FocusFrameToTBackground:SetDesaturated(state.unitframeDesaturate)
        FocusFrameToTBackground:SetVertexColor(c:GetRGB())
    end

    local extraColor = isEnabled and 0.6 or 1.0
    if focusPortExtra then
        focusPortExtra:SetVertexColor(extraColor, extraColor, extraColor)
    end

    -- editmode
    local e = f.PreviewFocus
    if e and e.TargetFrameBackground then
        e.TargetFrameBackground:SetDesaturated(state.unitframeDesaturate)
        e.TargetFrameBackground:SetVertexColor(c:GetRGB())
    end
end

function Module:UpdateBossFrame(state)
    local bossModule = DF:GetModule('Bossframe')
    local c = CreateColorFromRGBHexString(state.unitframeColor)
    local isEnabled = self:IsEnabled()
    local extraColor = isEnabled and 0.6 or 1.0

    -- Module['BossFrame' .. id]
    for i = 1, 4 do
        local f = bossModule['BossFrame' .. i];
        if f then
            --
            local TargetFrameBackground = f.TargetFrameBackground
            local targetPortExtra = f.PortraitExtra

            TargetFrameBackground:SetDesaturated(state.unitframeDesaturate)
            TargetFrameBackground:SetVertexColor(c:GetRGB())

            targetPortExtra:SetVertexColor(extraColor, extraColor, extraColor)

            local tot = f.ToTFrame
            local TargetFrameToTBackground = tot.TargetFrameBackground
            TargetFrameToTBackground:SetDesaturated(state.unitframeDesaturate)
            TargetFrameToTBackground:SetVertexColor(c:GetRGB())
        end
    end

    for i = 1, 4 do
        local f = bossModule['FakeBoss' .. i];
        if f then
            --
            local TargetFrameBackground = f.TargetFrameBackground
            local targetPortExtra = f.PortraitExtra

            TargetFrameBackground:SetDesaturated(state.unitframeDesaturate)
            TargetFrameBackground:SetVertexColor(c:GetRGB())

            targetPortExtra:SetVertexColor(extraColor, extraColor, extraColor)

            local tot = f.ToTFrame
            local TargetFrameToTBackground = tot.TargetFrameBackground
            TargetFrameToTBackground:SetDesaturated(state.unitframeDesaturate)
            TargetFrameToTBackground:SetVertexColor(c:GetRGB())
        end
    end
end

function Module:UpdateActionbar(state)
    local moduleName = 'Actionbar'
    if not DF.ConfigModule:GetModuleEnabled(moduleName) then return end

    local unitModule = DF:GetModule(moduleName)
    local f = unitModule.Frame
    local c = CreateColorFromRGBHexString(state.actionbarColor)

    do
        local mainbar = unitModule.bar1
        if not mainbar then return end

        local gryphonLeft = mainbar.gryphonLeft.texture
        local gryphonRight = mainbar.gryphonRight.texture
        local borderArt = mainbar.BorderArt

        local t = {gryphonLeft, gryphonRight, borderArt}

        for k, v in ipairs(t) do
            v:SetDesaturated(state.actionbarDesaturate)
            v:SetVertexColor(c:GetRGB())
        end
    end

    local barTable = {}
    for i = 1, 8 do
        local bar = unitModule['bar' .. i]
        if bar then table.insert(barTable, bar) end
    end
    if unitModule['petbar'] then table.insert(barTable, unitModule['petbar']) end
    if unitModule['stancebar'] then table.insert(barTable, unitModule['stancebar']) end

    for k, bar in ipairs(barTable) do
        if not bar.DFDarkmodeUpdateBarButtons then
            bar.DFDarkmodeUpdateBarButtons = function()
                local s = Module:GetState()
                local c = CreateColorFromRGBHexString(s.actionbarColor)

                local buttonTable = bar.buttonTable
                local btnCount = #buttonTable

                for j = 1, btnCount do
                    local btn = buttonTable[j]
                    local normalTex = btn.DFNormalTexture or btn:GetNormalTexture()
                    if normalTex then
                        normalTex:SetDesaturated(s.actionbarDesaturate)
                        normalTex:SetVertexColor(c:GetRGB())
                    end
                end
            end

            hooksecurefunc(bar, 'Update', function()
                bar.DFDarkmodeUpdateBarButtons()
            end)
        end

        bar.DFDarkmodeUpdateBarButtons()
    end

    if not Module.DFActionbarGridHooked then
        Module.DFActionbarGridHooked = true
    end

    if true then
        if MainMenuBarBackpackButton and MainMenuBarBackpackButton.Border then
            MainMenuBarBackpackButton.Border:SetDesaturated(state.actionbarDesaturate)
            MainMenuBarBackpackButton.Border:SetVertexColor(c:GetRGB())
        end

        for i = 0, 3 do
            local slot = _G['CharacterBag' .. i .. 'Slot']
            if slot and slot.Border then
                slot.Border:SetDesaturated(state.actionbarDesaturate)
                slot.Border:SetVertexColor(c:GetRGB())
            end
        end

        if not (DF.Cata or DF.MoP) and KeyRingButton and KeyRingButton.Border then
            KeyRingButton.Border:SetDesaturated(state.actionbarDesaturate)
            KeyRingButton.Border:SetVertexColor(c:GetRGB())
        end
    end

    -- XP/Repbar   
    local XPBar = unitModule.xpbar
    if XPBar and XPBar.Border then
        XPBar.Border:SetDesaturated(state.actionbarDesaturate)
        XPBar.Border:SetVertexColor(c:GetRGB())
    end
    local RepBar = unitModule.repbar
    if RepBar and RepBar.Border then
        RepBar.Border:SetDesaturated(state.actionbarDesaturate)
        RepBar.Border:SetVertexColor(c:GetRGB())
    end
end

function Module:UpdateFlyout(state)
    local moduleName = 'Flyout'
    if not DF.ConfigModule:GetModuleEnabled(moduleName) then return end

    local unitModule = DF:GetModule(moduleName)

    for i = 1, unitModule.NumCustomButtons do
        local f = unitModule['Custom' .. i .. 'Button']

        if f then
            if not f.DFDarkmodeUpdateBarButtons then
                f.DFDarkmodeUpdateBarButtons = function()
                    local s = Module:GetState()
                    local c = CreateColorFromRGBHexString(s.flyoutColor)

                    local normalTex = f.DFNormalTexture or f:GetNormalTexture()
                    if normalTex then
                        normalTex:SetDesaturated(s.flyoutDesaturate)
                        normalTex:SetVertexColor(c:GetRGB())
                    end

                    local buttonTable = f.buttonTable
                    local btnCount = #buttonTable

                    for j = 1, btnCount do
                        local btn = buttonTable[j]
                        local btnTex = btn.DFNormalTexture or btn:GetNormalTexture()
                        if btnTex then
                            btnTex:SetDesaturated(s.flyoutDesaturate)
                            btnTex:SetVertexColor(c:GetRGB())
                        end
                    end
                end

                hooksecurefunc(f, 'Update', function()
                    f.DFDarkmodeUpdateBarButtons()
                end)

            end
            f.DFDarkmodeUpdateBarButtons()
        end

    end
end

function Module:UpdateBuff(state)
    local unitModule = DF:GetModule('Buffs')
    local f = unitModule.SubBuff

    if not unitModule:IsEnabled() then return end
    local c = CreateColorFromRGBHexString(state.buffColor)

    -- update defaults
    f.BuffVertexColorR = c.r;
    f.BuffVertexColorG = c.g;
    f.BuffVertexColorB = c.b;

    local buffHeader = f.NewBuffs.Header;

    buffHeader.BuffVertexColorR = c.r;
    buffHeader.BuffVertexColorG = c.g;
    buffHeader.BuffVertexColorB = c.b;
    buffHeader.BuffDesaturate = state.buffDesaturate;

    local buff;
    -- player
    -- for i = 1, 32 do
    --     --
    --     buff = _G['BuffButton' .. i]
    --     if buff and buff.DFIconBorder then
    --         --
    --         buff.DFIconBorder:SetDesaturated(state.buffDesaturate)
    --         buff.DFIconBorder:SetVertexColor(c:GetRGB())
    --     end
    -- end
    for _, frame in buffHeader:ActiveChildren() do frame:UpdateStyle() end
    -- target 
    for i = 1, MAX_TARGET_BUFFS do
        --   
        buff = _G['TargetFrameBuff' .. i];
        if buff and buff.DFIconBorder then
            --
            buff.DFIconBorder:SetDesaturated(state.buffDesaturate)
            buff.DFIconBorder:SetVertexColor(c:GetRGB())
        end
    end
    -- focus 
    if DF.Wrath then
        for i = 1, MAX_TARGET_BUFFS do
            --   
            buff = _G['FocusFrameBuff' .. i];
            if buff and buff.DFIconBorder then
                --
                buff.DFIconBorder:SetDesaturated(state.buffDesaturate)
                buff.DFIconBorder:SetVertexColor(c:GetRGB())
            end
        end
    end
end

function Module:UpdateCastbar(state)
    local unitModule = DF:GetModule('Castbar')
    local f = unitModule.Frame
    local c = CreateColorFromRGBHexString(state.castbarColor)

    if not unitModule:IsEnabled() then return end

    local player = unitModule.PlayerCastbar
    local target = unitModule.TargetCastbar
    local focus = unitModule.FocusCastbar

    local frameTable = {player, target, focus}

    for k, v in pairs(frameTable) do
        v.Background:SetDesaturated(state.castbarDesaturate)
        v.Background:SetVertexColor(c:GetRGB())

        v.Border:SetDesaturated(state.castbarDesaturate)
        v.Border:SetVertexColor(c:GetRGB())

        v.BorderShield:SetDesaturated(state.castbarDesaturate)
        v.BorderShield:SetVertexColor(c:GetRGB())

        v.Icon.Border:SetDesaturated(state.castbarDesaturate)
        v.Icon.Border:SetVertexColor(c:GetRGB())
    end
end

function Module:HookOnEnable()
    local config = DF:GetModule('Config')
    local modules = config.db.profile.modules

    for k, v in pairs(modules) do
        --
        -- print(k, v)
        if not v then
            --
            local m = DF:GetModule(k, true)
            if m then
                hooksecurefunc(m, 'OnEnable', function()
                    --
                    -- print('enabless!', m)
                    Module:ApplySettings()
                end)
            end
        end
    end

end

local frame = CreateFrame('FRAME')

function frame:OnEvent(event, arg1, arg2, arg3)
end
frame:SetScript('OnEvent', frame.OnEvent)

function Module:Era()
    Module:HookOnEnable()
end

function Module:TBC()
end

function Module:Wrath()
    Module:HookOnEnable()
end

function Module:Cata()
    Module:HookOnEnable()
end

function Module:Mists()
    Module:HookOnEnable()
end
