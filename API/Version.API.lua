local DF = LibStub('AceAddon-3.0'):GetAddon('DragonflightUI')
local L = LibStub("AceLocale-3.0"):GetLocale("DragonflightUI")

-- compat @TODO
DF.InterfaceVersion = select(4, GetBuildInfo())
DF.Cata = (DF.InterfaceVersion >= 40000)
DF.Wrath = (DF.InterfaceVersion >= 30400) and (DF.InterfaceVersion < 40000)
DF.Era = DF.InterfaceVersion <= 20000
DF.EraLater = DF.Era and DF.InterfaceVersion >= 11503

---@type API
local API = DF.API;

--- Game version table
--- @class VersionAPI
local Version = {}
API.Version = Version

--- WoW Interface Version, e.g. 11509
---@type number
Version.InterfaceVersion = select(4, GetBuildInfo())

--- Addon is running on Classic "Vanilla" client, e.g. Era and SoD etc
---@type boolean
Version.IsClassic = (WOW_PROJECT_ID == WOW_PROJECT_CLASSIC) and (DF.InterfaceVersion < 20000)

--- Addon is running on Classic Season of Discovery client
---@type boolean
Version.IsSoD = Version.IsClassic and C_Seasons.HasActiveSeason() and
                    (C_Seasons.GetActiveSeason() == Enum.SeasonID.SeasonOfDiscovery)

--- current Season ID, or 0 if no Season
--- 
--- https://warcraft.wiki.gg/wiki/API_C_Seasons.GetActiveSeason
---@type Enum.SeasonID
Version.SeasonID = 0;
if C_Seasons.HasActiveSeason() then Version.SeasonID = C_Seasons.GetActiveSeason() end

--- Addon is running on Classic TBC client
---@type boolean
Version.IsTBC = (DF.InterfaceVersion >= 20505) and (DF.InterfaceVersion < 30000)

--- Addon is running on Classic Wotlk client
---@type boolean
Version.IsWotlk = WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC

--- Addon is running on Classic Cataclysm client
---@type boolean
Version.IsCata = WOW_PROJECT_ID == WOW_PROJECT_CATACLYSM_CLASSIC

--- Addon is running on Classic MoP client
---@type boolean
Version.IsMoP = WOW_PROJECT_ID == WOW_PROJECT_MISTS_CLASSIC

--- Client carries the Midnight-era ("modern") UI backport: Blizzard Edit
--- Mode, retail-style action bars, TextStatusBarMixin, pooled party frames.
--- True on TBC 2.5.6+, MoP 5.5.4+ and Classic Era 1.15.9+. Feature-detected
--- (not version-mapped) so it stays correct as Blizzard rolls the backport
--- to more flavors.
---@type boolean
Version.IsModern = (EditModeManagerFrame ~= nil) or (StatusTrackingBarManager ~= nil) or true
DF.IsModern = Version.IsModern

--- Capabilities table for modern engine features (HAL)
DF.Caps = {
    HasEditMode = (EditModeManagerFrame ~= nil),
    HasNativeMultiBars = (_G['MultiBar5'] ~= nil),
    HasPooledParty = (_G['PartyMemberFrame1'] == nil and _G['PartyFrame'] ~= nil),
    HasModernStatusBars = (TextStatusBarMixin ~= nil),
    HasContainerMixin = (ContainerFrameMixin ~= nil),
    HasFocus = (FocusFrame ~= nil) or (WOW_PROJECT_ID ~= WOW_PROJECT_CLASSIC),
    HasAltPower = (_G['PlayerPowerBarAlt'] ~= nil) or (WOW_PROJECT_ID == WOW_PROJECT_CATACLYSM_CLASSIC) or
        (WOW_PROJECT_ID == WOW_PROJECT_MISTS_CLASSIC),
    HasTotemBar = (_G['TotemFrame'] ~= nil),
}

Version.Caps = DF.Caps
Version.HasNativeMultiBars = DF.Caps.HasNativeMultiBars
Version.HasPooledParty = DF.Caps.HasPooledParty
Version.HasEditMode = DF.Caps.HasEditMode
Version.HasModernStatusBars = DF.Caps.HasModernStatusBars
Version.HasFocus = DF.Caps.HasFocus
Version.HasAltPower = DF.Caps.HasAltPower
Version.HasTotemBar = DF.Caps.HasTotemBar

-- DevTools_Dump(API.Version)


