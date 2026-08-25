local addonName, addonTable = ...;
local DF = addonTable.DF;

addonTable.SecondaryResAdapters = addonTable.SecondaryResAdapters or {}

local Adapter = {}
addonTable.SecondaryResAdapters['PRIEST'] = Adapter

function Adapter:CreateFrames(parent)
    local bar = _G['PriestBarFrame']
    if bar then
        bar:ClearAllPoints()
        bar:SetPoint('TOP', parent, 'TOP', 0, 0.5)
    end
end

function Adapter:HideSecondaryRes(hide)
    local bar = _G['PriestBarFrame']
    if not bar then return end

    local spec = C_SpecializationInfo and C_SpecializationInfo.GetSpecialization and C_SpecializationInfo.GetSpecialization()
    if (spec == SPEC_PRIEST_SHADOW) and (bar.hasReqLevel) then
        bar:SetShown(not hide)
    else
        bar:SetShown(false)
    end
end

function Adapter:HookSecondaryRes(subModule)
    local bar = _G['PriestBarFrame']
    if not bar then return end

    bar:HookScript('OnShow', function(self)
        if not subModule.ModuleRef.db.profile.playerSecondaryRes.activate then
            self:Hide()
        end
    end)

    if hooksecurefunc and bar.CheckAndShow then
        hooksecurefunc(bar, 'CheckAndShow', function()
            local spec = C_SpecializationInfo and C_SpecializationInfo.GetSpecialization and C_SpecializationInfo.GetSpecialization();
            if (spec == SPEC_PRIEST_SHADOW) and (bar.hasReqLevel) then
                if not subModule.ModuleRef.db.profile.playerSecondaryRes.activate then
                    bar:Hide()
                end
            end
        end)
    end
end
