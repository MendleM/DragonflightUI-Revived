local addonName, addonTable = ...;
local Helper = addonTable.Helper;
---@diagnostic disable: undefined-global
local DF = LibStub('AceAddon-3.0'):GetAddon('DragonflightUI')
local L = LibStub("AceLocale-3.0"):GetLocale("DragonflightUI")
local mName = 'Actionbar'
local Module = DF:NewModule(mName, 'AceConsole-3.0', 'AceHook-3.0')

Mixin(Module, DragonflightUIModulesMixin)

Module.SubVehicleLeave = DF:CreateFrameFromMixinAndInit(addonTable.SubModuleMixins['VehicleLeaveButton'])
Module.SubActionbarRange = DF:CreateFrameFromMixinAndInit(addonTable.SubModuleMixins['ActionbarRange'])

function Module:PrePositionActionbarHolders()
    if not self.db or not self.db.profile then return end

    for i = 1, 8 do
        local bar = _G['DragonflightUIActionbarFrame' .. i]
        local db = self.db.profile['bar' .. i]
        if bar and db then
            bar:SetScale(db.scale or 1.0)
            local parent = (db.customAnchorFrame and _G[db.customAnchorFrame]) or (db.anchorFrame and _G[db.anchorFrame]) or UIParent
            bar:ClearAllPoints()
            bar:SetPoint(db.anchor or 'BOTTOM', parent, db.anchorParent or 'BOTTOM', db.x or 0, db.y or 0)
        end
    end

    local petBar = _G['DragonflightUIPetbar']
    local petDb = self.db.profile.pet
    if petBar and petDb then
        petBar:SetScale(petDb.scale or 1.0)
        local parent = (petDb.customAnchorFrame and _G[petDb.customAnchorFrame]) or (petDb.anchorFrame and _G[petDb.anchorFrame]) or UIParent
        petBar:ClearAllPoints()
        petBar:SetPoint(petDb.anchor or 'BOTTOM', parent, petDb.anchorParent or 'BOTTOM', petDb.x or 0, petDb.y or 0)
    end

    local stanceBar = _G['DragonflightUIStancebar']
    local stanceDb = self.db.profile.stance
    if stanceBar and stanceDb then
        stanceBar:SetScale(stanceDb.scale or 1.0)
        local parent = (stanceDb.customAnchorFrame and _G[stanceDb.customAnchorFrame]) or (stanceDb.anchorFrame and _G[stanceDb.anchorFrame]) or UIParent
        stanceBar:ClearAllPoints()
        stanceBar:SetPoint(stanceDb.anchor or 'BOTTOM', parent, stanceDb.anchorParent or 'BOTTOM', stanceDb.x or 0, stanceDb.y or 0)
    end
    local microFrame = _G['DragonflightUIMicroMenuBar']
    local microDb = self.db.profile.micromenu
    if microFrame and microDb then
        microFrame:Show()
        microFrame:SetScale(microDb.scale or 1.0)
        local parent = (microDb.customAnchorFrame and _G[microDb.customAnchorFrame]) or (microDb.anchorFrame and _G[microDb.anchorFrame]) or UIParent
        microFrame:ClearAllPoints()
        microFrame:SetPoint(microDb.anchor or 'BOTTOMRIGHT', parent, microDb.anchorParent or 'BOTTOMRIGHT', microDb.x or 0, microDb.y or 0)
    end

    local bagFrame = _G['DragonflightUIBagBar']
    local bagDb = self.db.profile.bags
    if bagFrame and bagDb then
        bagFrame:Show()
        bagFrame:SetScale(bagDb.scale or 1.0)
        local parent = (bagDb.customAnchorFrame and _G[bagDb.customAnchorFrame]) or (bagDb.anchorFrame and _G[bagDb.anchorFrame]) or UIParent
        bagFrame:ClearAllPoints()
        bagFrame:SetPoint(bagDb.anchor or 'BOTTOMRIGHT', parent, bagDb.anchorParent or 'BOTTOMRIGHT', bagDb.x or 0, bagDb.y or 0)
    end
end

function Module:OnInitialize()
    DF:Debug(self, 'Module ' .. mName .. ' OnInitialize()')
    self.db = DF.db:RegisterNamespace(mName, Module.Defaults)

    hooksecurefunc(DF:GetModule('Config'), 'AddConfigFrame', function()
        Module:RegisterSettings()
    end)

    self:SetEnabledState(DF.ConfigModule:GetModuleEnabled(mName))
    self:PrePositionActionbarHolders()
    Module:HideBlizzardDefaultBars()
end

function Module:OnEnable()
    DF:Debug(self, 'Module ' .. mName .. ' OnEnable()')
    self:SetWasEnabled(true)

    Module:HideBlizzardDefaultBars()
    Module.ChangeGryphon()
    Module.ChangeActionbar()

    if not self.ActionbarSetupDone then
        self.ActionbarSetupDone = true
        self:SetupActionbarFrames()
    end

    -- Early setup of MicroMenu, Bags, and XP/Rep so they appear in position even during in-combat reloads
    Module.ChangeMicroMenu()
    Module.ChangeBackpack()
    Module.ChangeFramerate()
    Module.CreateBagExpandButton()
    Module.RefreshBagBarToggle()
    Module.HookBags()
    Module.CreateNewXPBar()
    Module.CreateNewRepBar()

    self:PrePositionActionbarHolders()
    Module:ApplySettings('ALL')

    Helper:RunOutOfCombat('action bars', function() Module:EnableOutOfCombat() end)
end

function Module:EnableOutOfCombat()
    C_CVar.SetCVar("alwaysShowActionBars", 1)

    Module.Temp = {}

    local steps = {}
    local add = function(label, fn) steps[#steps + 1] = {label, fn} end

    add('ChangeActionbar', Module.ChangeActionbar)
    add('NewBars', function()
        Module.CreateNewXPBar()
        Module.CreateNewRepBar()
        Module:RemoveActionbarAnimations()
    end)
    add('PetHookAndGryphon', function()
        Module.HookPetBar()
        if Module.Frame then
            Module.Frame:RegisterEvent('PLAYER_REGEN_ENABLED')
            Module.Frame:RegisterEvent('PLAYER_ENTERING_WORLD')
        end
        Module.ChangeGryphon()
    end)
    add('ChangeMicroMenu', Module.ChangeMicroMenu)
    add('ChangeBackpack', Module.ChangeBackpack)
    add('BagsAndFPS', function()
        Module.ChangeFramerate()
        Module.CreateBagExpandButton()
        Module.RefreshBagBarToggle()
        Module.HookBags()
    end)
    add('SubModules', function()
        self.SubVehicleLeave:Setup()
        self.SubActionbarRange:Setup()
    end)
    if not self.ActionbarSetupDone then
        self.ActionbarSetupDone = true
        for _, step in ipairs(self:GetSetupActionbarSteps()) do
            steps[#steps + 1] = step
        end
    end
    add('AddStateUpdater', Module.AddStateUpdater)
    add('AddEditMode', function() self:AddEditMode() end)
    add('RegisterOptionScreens', function() self:RegisterOptionScreens() end)
    add('ApplySettingsALL', function() Module:ApplySettings('ALL') end)
    add('UnitframeReapply', function()
        local uf = DF:GetModule('Unitframe', true)
        if uf and uf.GetWasEnabled and uf:GetWasEnabled() then
            uf:ApplySettings()
        end
    end)
    add('DarkmodeReapply', function()
        local dm = DF:GetModule('Darkmode', true)
        if dm and dm.GetWasEnabled and dm:GetWasEnabled() then
            dm:ApplySettings()
        end
    end)
    add('RefreshConfigHook', function()
        self:SecureHook(DF, 'RefreshConfig', function()
            Module:ApplySettings('ALL')
            Module:RefreshOptionScreens()
        end)
    end)
    Helper:RunSteps(steps, self, 'Actionbar')
end

function Module:OnDisable()
end

function Module:ApplySettings(sub, key)
    Helper:Benchmark(string.format('ApplySettings(%s,%s)', tostring(sub), tostring(key)), function()
        Module:ApplySettingsInternal(sub, key)
    end, 0, self)
end

function Module:ApplySettingsInternal(sub, key)
    local db = Module.db.profile

    if addonTable.RefreshActionbarPageArrows then
        C_Timer.After(0, addonTable.RefreshActionbarPageArrows)
    end

    if not sub or sub == 'ALL' then
        for i = 1, 8 do
            if Module['bar' .. i] then Module['bar' .. i]:SetState(db['bar' .. i]) end
        end

        if Module.petbar then Module.petbar:SetState(db.pet) end
        if Module.xpbar then Module.xpbar:SetState(db.xp) end
        if Module.repbar then Module.repbar:SetState(db.rep) end
        if Module.stancebar then Module.stancebar:SetState(db.stance) end

        if DF.Cata then
            Module.UpdateTotemState(db.totem)
            Module:UpdateExtraButtonState(db.extraActionButton)
        end

        Module.UpdateBagState(db.bags)
        if Module.MicroFrame and Module.MicroFrame.UpdateState then
            Module.MicroFrame:UpdateState(db.micro)
        end
        if Module.FPSFrame and Module.FPSFrame.SetState then
            Module.FPSFrame:SetState(db.fps)
        end

        Module.UpdatePossesbarState(db.possess)

        self.SubVehicleLeave:UpdateState(db.vehicleLeave)
        self.SubActionbarRange:UpdateState(db.actionbarRange)
    elseif sub == 'bar1' or sub == 'bar2' or sub == 'bar3' or sub == 'bar4' or
           sub == 'bar5' or sub == 'bar6' or sub == 'bar7' or sub == 'bar8' then
        if Module[sub] then Module[sub]:SetState(db[sub], key) end
    elseif sub == 'extraActionButton' then
        if DF.Cata then Module:UpdateExtraButtonState(db.extraActionButton) end
    elseif sub == 'pet' then
        if Module.petbar then Module.petbar:SetState(db.pet) end
    elseif sub == 'xp' then
        if Module.xpbar then Module.xpbar:SetState(db.xp) end
    elseif sub == 'rep' then
        if Module.repbar then Module.repbar:SetState(db.rep) end
    elseif sub == 'stance' then
        if Module.stancebar then Module.stancebar:SetState(db.stance) end
    elseif sub == 'possess' then
        Module.UpdatePossesbarState(db.possess)
    elseif sub == 'totem' then
        if DF.Cata then Module.UpdateTotemState(db.totem) end
    elseif sub == 'bags' then
        Module.UpdateBagState(db.bags)
    elseif sub == 'micro' then
        if Module.MicroFrame and Module.MicroFrame.UpdateState then
            Module.MicroFrame:UpdateState(db.micro)
        end
    elseif sub == 'fps' then
        if Module.FPSFrame and Module.FPSFrame.SetState then
            Module.FPSFrame:SetState(db.fps)
        end
    elseif sub == 'vehicleLeave' then
        self.SubVehicleLeave:UpdateState(db.vehicleLeave)
    elseif sub == 'actionbarRange' then
        self.SubActionbarRange:UpdateState(db.actionbarRange)
    end
end

function Module:Era()
    -- Managed by EnableOutOfCombat
end

function Module:TBC()
    -- Managed by EnableOutOfCombat
end

function Module:Wrath()
    -- Managed by EnableOutOfCombat
end

function Module:Cata()
    -- Managed by EnableOutOfCombat
end

function Module:Mists()
    -- Managed by EnableOutOfCombat
end
