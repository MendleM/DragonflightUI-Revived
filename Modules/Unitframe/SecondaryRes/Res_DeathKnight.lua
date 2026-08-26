local addonName, addonTable = ...;
local DF = addonTable.DF;

addonTable.SecondaryResAdapters = addonTable.SecondaryResAdapters or {}

local Adapter = {}
addonTable.SecondaryResAdapters['DEATHKNIGHT'] = Adapter

function Adapter:CreateFrames(parent)
    local runeFrame = _G['RuneFrame']
    if runeFrame then
        runeFrame:SetWidth(123)
        runeFrame:ClearAllPoints()
        runeFrame:SetParent(parent)
        runeFrame:SetPoint('TOP', parent, 'TOP', 0, -6)
    end
end

function Adapter:HideSecondaryRes(hide)
    local runeFrame = _G['RuneFrame']
    if runeFrame then
        runeFrame:SetShown(not hide)
    end
end

function Adapter:HookSecondaryRes(subModule)
    local runeFrame = _G['RuneFrame']
    if not runeFrame then return end

    runeFrame:HookScript('OnShow', function(self)
        if not subModule.ModuleRef.db.profile.playerSecondaryRes.activate then
            self:Hide()
        end
    end)
end
