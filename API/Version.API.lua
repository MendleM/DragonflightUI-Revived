local addonName, addonTable = ...
local DF = LibStub('AceAddon-3.0'):GetAddon('DragonflightUI')

--- Game version and capability API (HAL)
--- @class VersionAPI
local Version = {}
DF.API.Version = Version

-- 1. Interface & Build Info
local interfaceVersion = select(4, GetBuildInfo())
Version.InterfaceVersion = interfaceVersion
DF.InterfaceVersion = interfaceVersion

-- 2. Expansion Detection (Universal & Safe)
Version.IsClassic = (WOW_PROJECT_ID == WOW_PROJECT_CLASSIC) or (interfaceVersion < 20000)
Version.IsTBC = (WOW_PROJECT_ID == (WOW_PROJECT_BURNING_CRUSADE_CLASSIC or 5)) or (interfaceVersion >= 20000 and interfaceVersion < 30000)
Version.IsWotlk = (WOW_PROJECT_ID == (WOW_PROJECT_WRATH_CLASSIC or 11)) or (interfaceVersion >= 30000 and interfaceVersion < 40000)
Version.IsCata = (WOW_PROJECT_ID == (WOW_PROJECT_CATACLYSM_CLASSIC or 14)) or (interfaceVersion >= 40000 and interfaceVersion < 50000)
Version.IsMoP = (WOW_PROJECT_ID == (WOW_PROJECT_MISTS_CLASSIC or 15)) or (interfaceVersion >= 50000 and interfaceVersion < 60000)

-- Season of Discovery
local hasSeason = C_Seasons and C_Seasons.HasActiveSeason and C_Seasons.HasActiveSeason()
Version.SeasonID = hasSeason and C_Seasons.GetActiveSeason and C_Seasons.GetActiveSeason() or 0
Version.IsSoD = Version.IsClassic and (Version.SeasonID == (Enum and Enum.SeasonID and Enum.SeasonID.SeasonOfDiscovery or 1))

-- Modern Engine Detection
Version.IsModern = (EditModeManagerFrame ~= nil) or (StatusTrackingBarManager ~= nil)
DF.IsModern = Version.IsModern

--- Capabilities table for modern engine features (HAL)
DF.Caps = {
    HasEditMode = (EditModeManagerFrame ~= nil),
    HasNativeMultiBars = (_G['MultiBar5'] ~= nil),
    HasPooledParty = (_G['PartyMemberFrame1'] == nil and _G['PartyFrame'] ~= nil),
    HasModernStatusBars = (TextStatusBarMixin ~= nil),
    HasContainerMixin = (ContainerFrameMixin ~= nil),
    HasFocus = not Version.IsClassic,
    HasAltPower = Version.IsCata or Version.IsMoP or (interfaceVersion >= 40000),
    HasTotemBar = (_G['TotemFrame'] ~= nil) or (_G['MultiCastActionBarFrame'] ~= nil) or (GetTotemInfo ~= nil),
}
Version.Caps = DF.Caps

-- 3. Unified Top-Level Aliases (100% Backward Compatibility)
DF.Era = Version.IsClassic
DF.TBC = Version.IsTBC
DF.Wrath = Version.IsWotlk
DF.Cata = Version.IsCata
DF.MoP = Version.IsMoP

-- Auto-mirror all Caps to Version table
for k, v in pairs(DF.Caps) do
    Version[k] = v
end
