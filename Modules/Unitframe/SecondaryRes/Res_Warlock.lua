local addonName, addonTable = ...;
local DF = addonTable.DF;

addonTable.SecondaryResAdapters = addonTable.SecondaryResAdapters or {}

local Adapter = {}
addonTable.SecondaryResAdapters['WARLOCK'] = Adapter

function Adapter:CreateFrames(parent)
    if _G['WarlockPowerFrame'] then
        _G['WarlockPowerFrame']:SetParent(parent)
        _G['WarlockPowerFrame']:ClearAllPoints()
        _G['WarlockPowerFrame']:SetPoint('TOP', parent, 'TOP', 0, -7)
    end

    if _G['ShardBarFrame'] then
        _G['ShardBarFrame']:SetParent(parent)
        _G['ShardBarFrame']:ClearAllPoints()
        _G['ShardBarFrame']:SetPoint('TOP', parent, 'TOP', 0, _G['WarlockPowerFrame'] and -2 or -9)
    end

    if _G['BurningEmbersBarFrame'] then
        _G['BurningEmbersBarFrame']:SetParent(parent)
        _G['BurningEmbersBarFrame']:ClearAllPoints()
        _G['BurningEmbersBarFrame']:SetPoint('TOP', parent, 'TOP', 0, -0.5)
    end
end

function Adapter:HideSecondaryRes(hide)
    if not (C_SpecializationInfo and C_SpecializationInfo.GetSpecialization) then
        if UnitLevel("player") >= (SHARDBAR_SHOW_LEVEL or 10) then
            if _G['ShardBarFrame'] then _G['ShardBarFrame']:SetShown(not hide) end
        end
    else
        local spec = C_SpecializationInfo.GetSpecialization()

        if spec == SPEC_WARLOCK_AFFLICTION then
            if IsPlayerSpell(WARLOCK_SOULBURN) then
                if _G['ShardBarFrame'] then _G['ShardBarFrame']:SetShown(not hide) end
            else
                if _G['ShardBarFrame'] then _G['ShardBarFrame']:SetShown(false) end
            end
            if _G['BurningEmbersBarFrame'] then _G['BurningEmbersBarFrame']:SetShown(false) end
            if _G['DemonicFuryBarFrame'] then _G['DemonicFuryBarFrame']:SetShown(false) end
        elseif spec == SPEC_WARLOCK_DESTRUCTION then
            if IsPlayerSpell(WARLOCK_BURNING_EMBERS) then
                if _G['BurningEmbersBarFrame'] then _G['BurningEmbersBarFrame']:SetShown(not hide) end
            else
                if _G['BurningEmbersBarFrame'] then _G['BurningEmbersBarFrame']:SetShown(false) end
            end
            if _G['ShardBarFrame'] then _G['ShardBarFrame']:SetShown(false) end
            if _G['DemonicFuryBarFrame'] then _G['DemonicFuryBarFrame']:SetShown(false) end
        elseif spec == SPEC_WARLOCK_DEMONOLOGY then
            if _G['ShardBarFrame'] then _G['ShardBarFrame']:SetShown(false) end
            if _G['BurningEmbersBarFrame'] then _G['BurningEmbersBarFrame']:SetShown(false) end
            if _G['DemonicFuryBarFrame'] then _G['DemonicFuryBarFrame']:SetShown(not hide) end
        else
            if _G['ShardBarFrame'] then _G['ShardBarFrame']:SetShown(false) end
            if _G['BurningEmbersBarFrame'] then _G['BurningEmbersBarFrame']:SetShown(false) end
            if _G['DemonicFuryBarFrame'] then _G['DemonicFuryBarFrame']:SetShown(false) end
        end
    end
end

function Adapter:HookSecondaryRes(subModule)
    if _G['BurningEmbersBarFrame'] or _G['DemonicFuryBarFrame'] then
        subModule:RegisterEvent('PLAYER_SPECIALIZATION_CHANGED')

        local t = {_G['ShardBarFrame'], _G['BurningEmbersBarFrame'], _G['DemonicFuryBarFrame']}
        for k, v in ipairs(t) do
            if v then
                v:HookScript('OnShow', function()
                    if not subModule.ModuleRef.db.profile.playerSecondaryRes.activate then
                        v:Hide()
                    end
                end)
            end
        end
    elseif _G['ShardBarFrame'] then
        _G['ShardBarFrame']:HookScript('OnShow', function(self)
            if not subModule.ModuleRef.db.profile.playerSecondaryRes.activate then
                self:Hide()
            end
        end)
    end
end
