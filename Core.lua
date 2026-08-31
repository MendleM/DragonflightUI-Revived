local addonName, addonTable = ...;
---@class DragonflightUI : AceAddon-3.0, AceConsole-3.0, AceComm-3.0, AceHook-3.0
---@diagnostic disable-next-line: assign-type-mismatch
local DF = LibStub('AceAddon-3.0'):NewAddon('DragonflightUI', 'AceConsole-3.0', 'AceComm-3.0', 'AceHook-3.0',
                                            'AceSerializer-3.0')
local L = LibStub("AceLocale-3.0"):NewLocale("DragonflightUI", "enUS", true)

addonTable.DF = DF;
addonTable.L = LibStub("AceLocale-3.0"):GetLocale("DragonflightUI");
addonTable.SubModuleMixins = {}

-- global, not profile: "have I already seen the notes for this version" is a
-- fact about the installation, not about a layout the player can switch between
--
-- char, not global, for the edit mode anchor migration: C_EditMode.GetLayouts()
-- only returns the layouts that apply to the character you are on, so a
-- character-scoped layout with a stale anchor cannot be seen until that
-- character logs in. See Helper.lua:SanitizeLegacyEditModeAnchors.
local defaults = {
    profile = {bestnumber = 42},
    global = {lastSeenVersion = '', editModeLayoutNoticeDismissed = false},
    char = {editModeAnchorMigration = 0}
}

-- Lua errors and taint blocks are captured into the debug log; see DebugLog.lua.

---@type API
local t = DF.API;

function DF:OnInitialize()
    -- Called when the addon is loaded
    self.db = LibStub('AceDB-3.0'):New('DragonflightUIDB', defaults, true)
    local db = self.db.profile
    self:SetupOptions()
    self:RegisterSlashCommands()
    self:InitVersionCheck()
end

function DF:OnEnable()
    -- Called when the addon is enabled
    -- self:Print('DragonflightUI enabled!')
    self:ShowStartMessage()

    -- era-1159 note: module-level enable staggering was tried here and
    -- REVERTED: modules enabled after PLAYER_ENTERING_WORLD miss the login
    -- events their setup depends on (classic unitframes/minimap), and
    -- reordering broke the Editmode-before-Actionbar dependency. The only
    -- genuinely heavy module is Actionbar, which slices its own setup into
    -- per-frame steps internally (Helper:RunSteps); everything else fits the
    -- login watchdog slice comfortably (~300ms total).
end

function DF:OnDisable()
    -- Called when the addon is disabled
end

function DF:EnableModule(name, force)
    force = force and true or false;
    -- DF:GetModule(k, true)
    -- EnableModuleIfNotAlreadyEnabled
    local module = self:GetModule(name)
    local wasAlready = module:GetWasEnabled()
    DF:Debug(module, string.format('DF:EnableModule(%s,%s,%s)', name, tostring(force), tostring(wasAlready)))

    if wasAlready then
        if force then return module:Enable() end
    else
        return module:Enable()
    end
end

local name, realm = UnitName('player')
local showDebug = (name == 'Zimtdev') or (name == 'Zimtdevtwo')
DF.ShowDebug = showDebug;
function DF:Debug(m, ...)
    if showDebug then m:Print(...) end
end

function DF:Dump(value)
    if showDebug then DevTools_Dump(value) end
end

-- One version field, written out in full in the TOC.
--
-- It used to be "@project-version@", a token the release packager substitutes,
-- backed by a literal X-DFUI-Version for the builds it never reached. Nothing
-- runs that packager here - builds are packaged and uploaded by hand - so the
-- token was never substituted for anybody, and the shadow field was carrying
-- the whole job while the real one reported "@project-version@" to the addon
-- list. Two fields, one of them always wrong.
--
-- So: the TOC says the version, and this reads it. Bumping a release means
-- editing Version and Title in the TOC and adding the ChangelogData entry;
-- Changelog:CheckVersionAgreement logs it at login if those disagree.
function DF:GetVersion()
    local version = C_AddOns.GetAddOnMetadata('DragonflightUI', 'Version')

    if not version or version == '' then return 'unknown' end

    return version
end

function DF:ShowStartMessage()
    self:Print(DF:GetVersion() .. " loaded! Type '/dragonflight' or '/df' to open the options menu.")
end

-- Vanilla gave shamans the paladin's pink, to the third decimal:
-- Blizzard_SharedXML/Vanilla/ClassColors.lua has both at 0.96, 0.55, 0.73. It
-- was never ambiguous at the time, because shamans were Horde and paladins
-- Alliance and the two could not see each other. TBC is where shaman becomes
-- blue. On Era they are still indistinguishable, which reads as a bug.
--
-- The obvious fix - write RAID_CLASS_COLORS.SHAMAN - is the one to avoid.
-- Blizzard_UnitFrame/Shared/CompactUnitFrame.lua reads that table on every
-- health update, and the raid frames it drives do protected work, so tainting
-- it risks blocking them in combat. That is the exact failure we have spent
-- this week fixing in other people's addons. So the swap happens here instead,
-- in the one function every colour DFUI draws already comes through.
local SHAMAN_BLUE_R, SHAMAN_BLUE_G, SHAMAN_BLUE_B = 0.0, 0.44, 0.87 -- TBC's own values
local SHAMAN_BLUE_HEX = (CreateColor and CreateColor(SHAMAN_BLUE_R, SHAMAN_BLUE_G, SHAMAN_BLUE_B):GenerateHexColor()) or
                            'ff0070dd'

-- BLIZZ:
local function GetClassColor(classFilename)
    local classColors = CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS

    -- Only ever override the client's own table. Somebody running a class
    -- colour addon has said what they want their colours to be, and it is not
    -- our place to argue with it.
    if DF.BlueShamans and classFilename == 'SHAMAN' and not CUSTOM_CLASS_COLORS then
        return SHAMAN_BLUE_R, SHAMAN_BLUE_G, SHAMAN_BLUE_B, SHAMAN_BLUE_HEX
    end

    local color = classColors[classFilename];
    if color then return color.r, color.g, color.b, color.colorStr; end

    return 1, 1, 1, "ffffffff";
end

-- True when the client cannot tell the two apart, which is what makes the
-- option worth offering. Feature-detected rather than keyed to a flavour, so it
-- stays right if Blizzard ever changes the Era table.
function DF:ShamanSharesPaladinColor()
    local colors = RAID_CLASS_COLORS
    local shaman, paladin = colors and colors.SHAMAN, colors and colors.PALADIN
    if not (shaman and paladin) then return false end
    return math.abs(shaman.r - paladin.r) < 0.01 and math.abs(shaman.g - paladin.g) < 0.01 and
               math.abs(shaman.b - paladin.b) < 0.01
end

function DF:GetClassColor(class, alpha)
    local r, g, b, hex = GetClassColor(class)
    if alpha then
        return r, g, b, alpha, hex
    else
        return r, g, b, 1, hex
    end
end

-- TODO
function DF:GetUnitSelectionColor(unit)
    local red, green, blue, alpha = UnitSelectionColor(unit)
    return red, green, blue, alpha;
end

function DF:GetClassColoredText(str, class)
    if not str then return '' end
    local r, g, b, a, hex = DF:GetClassColor(class)
    return "|r|c" .. hex .. str .. "|r"
end

function DF:CreateFrameFromMixinAndInit(mixinTable)
    local f = CreateFrame('Frame');
    Mixin(f, mixinTable);
    f:Init();
    return f;
end
