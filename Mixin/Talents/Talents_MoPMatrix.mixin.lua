local addonName, addonTable = ...;
local Helper = addonTable.Helper;
---@diagnostic disable: undefined-global
local DF = LibStub('AceAddon-3.0'):GetAddon('DragonflightUI')

DragonflightUITalentsMoPMixin = {}

local base = 'Interface\\Addons\\DragonflightUI\\Textures\\UI\\'

function DragonflightUITalentsMoPMixin:SkinMoPTalentFrame(frame)
    if not frame then return end

    if DragonflightUIMixin and DragonflightUIMixin.AddNineSliceTextures then
        DragonflightUIMixin:AddNineSliceTextures(frame, true)
        DragonflightUIMixin:ButtonFrameTemplateNoPortrait(frame)
        DragonflightUIMixin:FrameBackgroundSolid(frame, true)
    end

    local closeButton = _G[frame:GetName() .. 'CloseButton'] or PlayerTalentFrameCloseButton
    if closeButton and DragonflightUIMixin and DragonflightUIMixin.UIPanelCloseButton then
        DragonflightUIMixin:UIPanelCloseButton(closeButton)
        closeButton:ClearAllPoints()
        closeButton:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', 1, 0)
    end

    -- Skin MoP Matrix Talents if present
    local talentFrame = _G['PlayerTalentFrameTalents']
    if talentFrame then
        for tier = 1, 6 do
            local row = _G['PlayerTalentFrameTalentsTier' .. tier]
            if row then
                for col = 1, 3 do
                    local btn = _G['PlayerTalentFrameTalentsTier' .. tier .. 'Talent' .. col]
                    if btn and not btn.DFSkinned then
                        btn.DFSkinned = true
                        if btn.icon and btn.icon.SetTexCoord then
                            btn.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                        end
                    end
                end
            end
        end
    end

    -- Skin MoP Specialization Frame if present
    local specFrame = _G['PlayerTalentFrameSpecialization']
    if specFrame then
        for specIndex = 1, 4 do
            local specBtn = _G['PlayerTalentFrameSpecializationSpecButton' .. specIndex]
            if specBtn and not specBtn.DFSkinned then
                specBtn.DFSkinned = true
                if specBtn.specIcon and specBtn.specIcon.SetTexCoord then
                    specBtn.specIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                end
            end
        end
    end

    -- Skin MoP Pet Specialization Frame if present
    local petSpecFrame = _G['PlayerTalentFramePetSpecialization']
    if petSpecFrame then
        for specIndex = 1, 3 do
            local specBtn = _G['PlayerTalentFramePetSpecializationSpecButton' .. specIndex]
            if specBtn and not specBtn.DFSkinned then
                specBtn.DFSkinned = true
                if specBtn.specIcon and specBtn.specIcon.SetTexCoord then
                    specBtn.specIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                end
            end
        end
    end
end
