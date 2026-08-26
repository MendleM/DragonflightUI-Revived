local addonName, addonTable = ...;
local Helper = addonTable.Helper;
local DF = LibStub('AceAddon-3.0'):GetAddon('DragonflightUI')

--[[
    DFProfessionMixin has been modularized into domain-specific sub-mixins:
    - Mixin/Profession/ProfessionFrame.Core.mixin.lua       (Frame lifecycle, drag, tabs, favorite DB, hooks)
    - Mixin/Profession/ProfessionFrame.Schematics.mixin.lua (Schematics form, dropdown filters, recipe detail updates)
    - Mixin/Profession/ProfessionFrame.RecipeList.mixin.lua (RecipeList mixin, categories, buttons, collapse states)
]]

DFProfessionMixin = DFProfessionMixin or {}
