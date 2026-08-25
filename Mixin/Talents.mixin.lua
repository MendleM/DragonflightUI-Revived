local addonName, addonTable = ...;
local Helper = addonTable.Helper;
local DF = LibStub('AceAddon-3.0'):GetAddon('DragonflightUI')

--[[
    Talent mixins have been modularized into domain-specific sub-mixins:
    - Mixin/Talents/Talents_ClassicTree.mixin.lua (Classic 3-tree panel mixin, branch calculations, arrows, role icons)
    - Mixin/Talents/Talents_MoPMatrix.mixin.lua   (MoP 6x3 matrix grid and specialization selection frame styling)
    - Mixin/Talents/Talents_Core.mixin.lua        (Master frame mixin, spec switching, dual spec tabs, preview buttons)
]]

DragonflightUITalentsPanelMixin = DragonflightUITalentsPanelMixin or {}
DragonflightUITalentsFrameMixin = DragonflightUITalentsFrameMixin or {}
DragonflightUITalentsMoPMixin = DragonflightUITalentsMoPMixin or {}
DragonflightUIPlayerSpecMixin = DragonflightUIPlayerSpecMixin or {}
DragonflightUIPlayerSpecActivateMixin = DragonflightUIPlayerSpecActivateMixin or {}
DragonflightUIPlayerSpecPreviewLearnMixin = DragonflightUIPlayerSpecPreviewLearnMixin or {}
DragonflightUIPlayerSpecPreviewResetMixin = DragonflightUIPlayerSpecPreviewResetMixin or {}
