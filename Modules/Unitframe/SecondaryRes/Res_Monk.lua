local addonName, addonTable = ...;
local DF = addonTable.DF;

addonTable.SecondaryResAdapters = addonTable.SecondaryResAdapters or {}

local Adapter = {}
addonTable.SecondaryResAdapters['MONK'] = Adapter

function Adapter:CreateFrames(parent)
    local bar = _G['MonkHarmonyBar']
    if bar then
        bar:SetParent(parent)
        bar:ClearAllPoints()
        bar:SetPoint('TOP', parent, 'TOP', 0, 18)
    end
end

function Adapter:HideSecondaryRes(hide)
    if _G['MonkHarmonyBar'] then
        _G['MonkHarmonyBar']:SetShown(not hide)
    end

    local spec = C_SpecializationInfo and C_SpecializationInfo.GetSpecialization and C_SpecializationInfo.GetSpecialization()
    if spec == SPEC_MONK_BREWMASTER then
        if _G['MonkStaggerBar'] then _G['MonkStaggerBar']:SetShown(not hide) end
    else
        if _G['MonkStaggerBar'] then _G['MonkStaggerBar']:SetShown(false) end
    end
end

function Adapter:HookSecondaryRes(subModule)
    local bar = _G['MonkHarmonyBar']
    if not bar then return end

    bar:HookScript('OnShow', function(self)
        if not subModule.ModuleRef.db.profile.playerSecondaryRes.activate then
            self:Hide()
        end
    end)
end
