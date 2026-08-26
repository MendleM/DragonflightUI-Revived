local addonName, addonTable = ...;
local DF = addonTable.DF;

addonTable.SecondaryResAdapters = addonTable.SecondaryResAdapters or {}

local Adapter = {}
addonTable.SecondaryResAdapters['PALADIN'] = Adapter

function Adapter:CreateFrames(parent)
    local bar = _G['PaladinPowerBar']
    if bar then
        bar:SetParent(parent)
        bar:ClearAllPoints()
        bar:SetPoint('TOP', parent, 'TOP', 0, 5)
    end
end

function Adapter:HideSecondaryRes(hide)
    local bar = _G['PaladinPowerBar']
    if bar then
        if UnitLevel("player") >= (PALADINPOWERBAR_SHOW_LEVEL or 9) then
            bar:SetShown(not hide);
        else
            bar:SetShown(false);
        end
    end
end

function Adapter:HookSecondaryRes(subModule)
    local bar = _G['PaladinPowerBar']
    if not bar then return end

    bar:HookScript('OnShow', function(self)
        if not subModule.ModuleRef.db.profile.playerSecondaryRes.activate then
            self:Hide()
        end
    end)
end
