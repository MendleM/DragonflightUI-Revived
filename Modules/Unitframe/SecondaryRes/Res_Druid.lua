local addonName, addonTable = ...;
local DF = addonTable.DF;

addonTable.SecondaryResAdapters = addonTable.SecondaryResAdapters or {}

local Adapter = {}
addonTable.SecondaryResAdapters['DRUID'] = Adapter

function Adapter:CreateFrames(parent)
    local bar = _G['EclipseBarFrame']
    if bar then
        bar:SetParent(parent)
        bar:ClearAllPoints()
        bar:SetPoint('TOP', parent, 'TOP', 0, -1)
    end
end

function Adapter:HideSecondaryRes(hide)
    local bar = _G['EclipseBarFrame']
    if not bar then return end

    if hide then
        bar:Hide()
    else
        if bar.UpdateShown then
            bar:UpdateShown()
        elseif EclipseBar_UpdateShown then
            EclipseBar_UpdateShown(bar)
        end
    end
end

function Adapter:HookSecondaryRes(subModule)
    local bar = _G['EclipseBarFrame']
    if not bar then return end

    bar:HookScript('OnShow', function(self)
        if not subModule.ModuleRef.db.profile.playerSecondaryRes.activate then
            self:Hide()
        end
    end)
end
