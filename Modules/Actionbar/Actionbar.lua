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

function Module:OnInitialize()
    DF:Debug(self, 'Module ' .. mName .. ' OnInitialize()')
    self.db = DF.db:RegisterNamespace(mName, Module.Defaults)

    hooksecurefunc(DF:GetModule('Config'), 'AddConfigFrame', function()
        Module:RegisterSettings()
    end)

    self:SetEnabledState(DF.ConfigModule:GetModuleEnabled(mName))
end

function Module:OnEnable()
    DF:Debug(self, 'Module ' .. mName .. ' OnEnable()')
    self:SetWasEnabled(true)

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
    for _, step in ipairs(self:GetSetupActionbarSteps()) do
        steps[#steps + 1] = step
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
