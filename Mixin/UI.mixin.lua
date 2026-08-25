local addonName, addonTable = ...;
local Helper = addonTable.Helper;
---@diagnostic disable: undefined-global
---@class DragonflightUI
---@diagnostic disable-next-line: assign-type-mismatch
local DF = LibStub('AceAddon-3.0'):GetAddon('DragonflightUI')

--[[
    DragonflightUIMixin has been modularized into domain-specific sub-mixins:
    - Mixin/UI/UI.Templates.mixin.lua       (NineSlice, Buttons, Tab/Frame Background templates)
    - Mixin/UI/UI.Bags.mixin.lua            (Container, Bank, TokenFrame, GuildBank Search)
    - Mixin/UI/UI.Inspect.mixin.lua         (InspectFrame Era/TBC/Wrath & Cata/MoP)
    - Mixin/UI/UI.Character.mixin.lua       (CharacterFrame Era/TBC/Wrath & Cata/MoP, Stats, Slots, Model)
    - Mixin/UI/UI.QuestGossip.mixin.lua     (QuestFrame, QuestLog, Gossip, QuestXP, Level)
    - Mixin/UI/UI.SpellbookTalents.mixin.lua (SpellBook, Talents, Tabs, Professions Book)
    - Mixin/UI/UI.MiscFrames.mixin.lua      (Trainer, Dressup, Taxi, Trade, TBC/Wrath PVP, LFG)
]]

DragonflightUIMixin = DragonflightUIMixin or {}
