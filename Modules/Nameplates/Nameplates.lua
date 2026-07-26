-- era-1159: Dragonflight-styled nameplates for the modern (1.15.9+)
-- nameplate system. New module - upstream DFUI has none.
local addonName, addonTable = ...;
local DF = addonTable.DF;
local L = addonTable.L;
local mName = 'Nameplates'
local Module = DF:NewModule(mName, 'AceConsole-3.0', 'AceHook-3.0')

Mixin(Module, DragonflightUIModulesMixin)

-- style: which nameplate look DFUI enforces at load.
--   'THIN'    - the Dragonflight-style plate (thin bar, name above)
--   'MODERN'  - Midnight's chunky plate (20px bar, name inside)
--   'CLASSIC' - the classic Era look (border ring + level box)
--   'BLIZZARD'- do not touch the CVar at all; whatever you set in
--               Blizzard's options sticks across reloads
local defaults = {profile = {classColors = true, modernStyle = true, style = 'THIN', styleTexture = true}}
Module:SetDefaults(defaults)

local function getDefaultStr(key, sub)
    return Module:GetDefaultStr(key, sub)
end

local function setDefaultValues()
    Module:SetDefaultValues()
end

-- Most of this page is the client's own nameplate CVars, read and written
-- directly.
--
-- Keeping a second copy in the profile is how these drifted apart: the profile
-- said one thing and the client another, the page only ever wrote its copy one
-- way (class colours, for instance, were switched ON but never off), and
-- nothing you changed showed up until a reload. Reading the CVar means the page
-- always shows what the game is actually doing, and writing it means the change
-- lands immediately - Blizzard's nameplate driver watches these CVars and
-- rebuilds the plates itself.
local CVAR_TOGGLES = {
    classColors = 'nameplateShowClassColor',
    friendlyClassColors = 'nameplateShowFriendlyClassColor',
    showEnemies = 'nameplateShowEnemies',
    showFriends = 'nameplateShowFriends',
    showFriendlyNpcs = 'nameplateShowFriendlyNpcs',
    friendlyNameOnly = 'nameplateShowOnlyNameForFriendlyPlayerUnits',
    forceShowNames = 'nameplateForceShowUnitName'
}

-- select-type options backed by a CVar holding an enum value
local CVAR_ENUMS = {
    size = {
        cvar = 'nameplateSize',
        enum = 'NamePlateSize',
        order = {'Small', 'Medium', 'Large', 'ExtraLarge', 'Huge'},
        labels = {
            Small = 'Small',
            Medium = 'Medium (default)',
            Large = 'Large',
            ExtraLarge = 'Extra large',
            Huge = 'Huge'
        }
    }
}

local function CVarExists(name)
    return name and GetCVar and GetCVar(name) ~= nil
end

local function ReadToggle(cvar)
    local value = GetCVar(cvar)
    return value == '1' or value == 1
end

local function WriteCVar(cvar, value)
    if not (C_CVar and C_CVar.SetCVar) then return end

    -- some nameplate CVars are refused in combat; say so instead of failing mute
    local ok = pcall(C_CVar.SetCVar, cvar, value)
    if not ok then
        Module:Print(('%s cannot be changed right now%s.'):format(cvar,
                                                                 InCombatLockdown() and ' (not while in combat)' or ''))
    end
    return ok
end

local function ReadEnumCVar(info)
    local current = tonumber(GetCVar(info.cvar))
    local enum = Enum and Enum[info.enum]
    if not (enum and current) then return nil end

    for _, name in ipairs(info.order) do if enum[name] == current then return name end end
    return nil
end

local function WriteEnumCVar(info, name)
    local enum = Enum and Enum[info.enum]
    local value = enum and enum[name]
    if value ~= nil then WriteCVar(info.cvar, value) end
end

local function getOption(info)
    local key = info[1]

    local toggle = CVAR_TOGGLES[key]
    if toggle then return ReadToggle(toggle) end

    local enumInfo = CVAR_ENUMS[key]
    if enumInfo then return ReadEnumCVar(enumInfo) end

    return Module:GetOption(info)
end

local function setOption(info, value)
    local key = info[1]

    local toggle = CVAR_TOGGLES[key]
    if toggle then
        WriteCVar(toggle, value and 1 or 0)
        Module:RefreshOptionScreens()
        return
    end

    local enumInfo = CVAR_ENUMS[key]
    if enumInfo then
        WriteEnumCVar(enumInfo, value)
        Module:RefreshOptionScreens()
        return
    end

    Module:SetOption(info, value)
end

-- The dropdown renderer reads dropdownValues: an ARRAY of {value, text}. The
-- style option used to pass a map under 'values', so no menu was built at all
-- and the style could not be changed from this page.
local styleValues = {
    {value = 'THIN', text = 'Dragonflight (thin bar, name above)'},
    {value = 'MODERN', text = 'Midnight (thick bar, name inside)'},
    {value = 'CLASSIC', text = 'Classic (border ring, level box)'},
    {value = 'BLIZZARD', text = "Don't manage (use Blizzard's setting)"}
}

local options = {
    name = 'Nameplates',
    desc = 'Nameplates',
    get = getOption,
    set = setOption,
    type = 'group',
    args = {
        headerStyle = {type = 'header', name = 'Style', desc = '', order = 0, isExpanded = true},
        style = {
            type = 'select',
            name = 'Nameplate style',
            desc = 'Which nameplate look to enforce.'
                .. " Pick \"Don't manage\" to leave the style entirely to Blizzard's own settings"
                .. ' - useful if you change it there and want it to stick across reloads.'
                .. getDefaultStr('style'),
            dropdownValues = styleValues,
            order = 1,
            group = 'headerStyle'
        },
        styleTexture = {
            type = 'toggle',
            name = 'DragonflightUI plate styling',
            desc = 'Apply the DragonflightUI health bar texture, outlined names and enemy level text.'
                .. ' Turning this off restores the native look on the plates currently up.'
                .. getDefaultStr('styleTexture'),
            order = 2,
            group = 'headerStyle'
        },
        headerVisibility = {type = 'header', name = 'Visibility', desc = '', order = 20, isExpanded = true}
    }
}

-- Only offer what this client actually has: these CVars come and go between
-- flavours, and an option that writes a CVar the client does not know is worse
-- than no option.
do
    local args = options.args

    local function addToggle(key, name, desc, order, group)
        if not CVarExists(CVAR_TOGGLES[key]) then return end
        args[key] = {type = 'toggle', name = name, desc = desc, order = order, group = group, blizzard = true}
    end

    if CVarExists('nameplateSize') and Enum and Enum.NamePlateSize then
        local info = CVAR_ENUMS.size
        local values = {}
        for _, key in ipairs(info.order) do
            if Enum.NamePlateSize[key] ~= nil then
                table.insert(values, {value = key, text = info.labels[key] or key})
            end
        end
        args.size = {
            type = 'select',
            name = 'Plate size',
            desc = "Scale of the whole plate - Blizzard's own nameplate size setting.",
            dropdownValues = values,
            order = 3,
            group = 'headerStyle',
            blizzard = true
        }
    end

    addToggle('classColors', 'Class-colored enemy plates', 'Color enemy player health bars by class.', 4, 'headerStyle')
    addToggle('friendlyClassColors', 'Class-colored friendly plates', 'Color friendly player health bars by class.', 5,
              'headerStyle')

    addToggle('showEnemies', 'Show enemy nameplates', 'Show nameplates for hostile units.', 21, 'headerVisibility')
    addToggle('showFriends', 'Show friendly nameplates', 'Show nameplates for friendly players.', 22, 'headerVisibility')
    addToggle('showFriendlyNpcs', 'Show friendly NPC nameplates', 'Show nameplates for friendly NPCs.', 23,
              'headerVisibility')
    addToggle('friendlyNameOnly', 'Friendly plates: name only',
              'Show only the name for friendly players, without a health bar.', 24, 'headerVisibility')
    addToggle('forceShowNames', 'Always show names', 'Keep unit names visible without a nameplate.', 25,
              'headerVisibility')
end

function Module:OnInitialize()
    DF:Debug(self, 'Module ' .. mName .. ' OnInitialize()')
    self.db = DF.db:RegisterNamespace(mName, defaults)

    hooksecurefunc(DF:GetModule('Config'), 'AddConfigFrame', function()
        Module:RegisterSettings()
    end)

    self:SetEnabledState(DF.ConfigModule:GetModuleEnabled(mName))

    DF:RegisterModuleOptions(mName, options)
end

function Module:RegisterSettings()
    local function register(name, data)
        data.module = mName
        DF.ConfigModule:RegisterSettingsElement(name, 'misc', data, true)
    end

    register('nameplates', {order = 2, name = 'Nameplates', descr = 'Nameplates', isNew = true})
end

function Module:RefreshOptionScreens()
    local configFrame = DF.ConfigModule.ConfigFrame
    if configFrame then configFrame:RefreshCatSub('Misc', 'Nameplates') end
end

local BAR_TEXTURE =
    'Interface\\Addons\\DragonflightUI\\Textures\\UI-HUD-UnitFrame-Player-PortraitOff-Bar-Health-Status32'

-- force: re-apply even where our own marker says the plate was already done.
-- Blizzard rebuilds plate contents on style and size changes, which throws our
-- texture and font away while the marker stays behind - so a style change used
-- to leave the plates half native until a reload.
local function StylePlate(unit, force)
    if not (Module.db and C_NamePlate and C_NamePlate.GetNamePlateForUnit) then return end

    local plate = C_NamePlate.GetNamePlateForUnit(unit)
    if not plate then return end
    if plate.IsForbidden and plate:IsForbidden() then return end

    local uf = plate.UnitFrame
    if not uf or (uf.IsForbidden and uf:IsForbidden()) then return end

    local container = uf.HealthBarsContainer
    local healthBar = container and container.healthBar
    local styling = Module.db.profile.styleTexture

    if not styling then
        -- Put back what we changed rather than asking for a /reload. The bar
        -- background tint is left to Blizzard: it re-applies its own on the
        -- next unit that takes this pooled plate.
        if healthBar and healthBar.DFStyled then
            if healthBar.DFOriginalTexture then healthBar:SetStatusBarTexture(healthBar.DFOriginalTexture) end
            healthBar.DFStyled = nil
        end
        if uf.name and uf.DFNameStyled then
            local file, size, flags = uf.name:GetFont()
            if file and uf.DFOriginalNameSize then uf.name:SetFont(file, uf.DFOriginalNameSize, uf.DFOriginalNameFlags) end
            uf.DFNameStyled = nil
        end
        if uf.DFLevelText then uf.DFLevelText:Hide() end
        return
    end

    if healthBar and (force or not healthBar.DFStyled) then
        healthBar.DFStyled = true
        local current = healthBar:GetStatusBarTexture()
        healthBar.DFOriginalTexture = healthBar.DFOriginalTexture or (current and current.GetTexture and
                                          current:GetTexture())
        healthBar:SetStatusBarTexture(BAR_TEXTURE)
        local bg = (container and container.background) or healthBar.background
        if bg and bg.SetColorTexture then bg:SetColorTexture(0, 0, 0, 0.55) end
    end

    if uf.name and (force or not uf.DFNameStyled) then
        uf.DFNameStyled = true
        local file, size, flags = uf.name:GetFont()
        if file then
            uf.DFOriginalNameSize = uf.DFOriginalNameSize or size
            uf.DFOriginalNameFlags = uf.DFOriginalNameFlags or flags
            uf.name:SetFont(file, 10, 'OUTLINE')
        end
        uf.name:SetShadowOffset(0, 0)
    end

    -- Enemy level, top-right in line with the name. Plates are pooled, so the
    -- FontString is created once but refreshed for every new unit.
    if uf.name then
        local levelText = uf.DFLevelText
        if not levelText then
            levelText = uf:CreateFontString(nil, 'OVERLAY')
            local path = uf.name:GetFont()
            if path then levelText:SetFont(path, 10, 'OUTLINE') end
            levelText:SetShadowOffset(0, 0)
            -- Right-aligned to the plate itself (the healthbar edge), on the
            -- name's line - anchoring off the centered name text pushed the
            -- level past the plate's end for long names.
            local levelAnchor = (container and container.healthBar) or uf
            levelText:SetPoint('BOTTOMRIGHT', levelAnchor, 'TOPRIGHT', 0, 2)
            uf.DFLevelText = levelText
        end
        if UnitCanAttack('player', unit) then
            local level = UnitLevel(unit)
            if level and level > 0 then
                local color = GetQuestDifficultyColor and GetQuestDifficultyColor(level) or {r = 1, g = 0.82, b = 0}
                levelText:SetText(level)
                levelText:SetTextColor(color.r, color.g, color.b)
            else
                levelText:SetText('??')
                levelText:SetTextColor(1, 0.1, 0.1)
            end
            levelText:Show()
        else
            levelText:Hide()
        end
    end
end

function Module:RestyleAll(force)
    if not (C_NamePlate and C_NamePlate.GetNamePlates) then return end

    for _, plate in ipairs(C_NamePlate.GetNamePlates()) do
        if plate.namePlateUnitToken then
            local ok, err = pcall(StylePlate, plate.namePlateUnitToken, force)
            if not ok and not self.StyleErrorReported then
                self.StyleErrorReported = true
                geterrorhandler()('DFUI Nameplates: ' .. tostring(err))
            end
        end
    end
end

-- Era 1.15.9 defaults nameplateStyle to the classic look (border ring +
-- level box). Careful with the enum: 'Modern' is MIDNIGHT's chunky plate
-- (20px bar, name inside) - the style everyone calls the Dragonflight
-- plate (thin bar, name above) is 'Thin'.
--
-- We only write the CVar for an explicit DFUI choice. On 'BLIZZARD' we
-- keep our hands off it entirely, so a style picked in Blizzard's options
-- survives a reload instead of being forced back every load.
function Module:ApplyStyleCVar()
    if not (C_CVar and C_CVar.SetCVar and Enum and Enum.NamePlateStyle) then return end

    local profile = self.db and self.db.profile
    if not profile then return end

    -- migrate the old boolean toggle onto the style setting, once
    if profile.style == nil then profile.style = profile.modernStyle and 'THIN' or 'BLIZZARD' end
    if profile.style == 'BLIZZARD' then return end

    local wanted = Enum.NamePlateStyle[({THIN = 'Thin', MODERN = 'Modern', CLASSIC = 'Classic'})[profile.style]
                       or 'Thin']
    if wanted ~= nil then WriteCVar('nameplateStyle', wanted) end
end

function Module:ApplySettings(sub, key)
    self:ApplyStyleCVar()
    -- force: the styling toggle and the style itself both change what the
    -- plates should look like right now
    self:RestyleAll(true)
end

function Module:OnEnable()
    DF:Debug(self, 'Module ' .. mName .. ' OnEnable()')
    self:SetWasEnabled(true)

    self:ApplyStyleCVar()

    -- The class-colour option used to live in the profile, defaulting to on,
    -- and was pushed into the CVar at every load. It is the CVar's own setting
    -- now, so hand the old preference over once and then leave it alone.
    local profile = self.db.profile
    if not profile.classColorsMigrated then
        profile.classColorsMigrated = true
        if CVarExists(CVAR_TOGGLES.classColors) then
            WriteCVar(CVAR_TOGGLES.classColors, profile.classColors and 1 or 0)
        end
    end

    local frame = CreateFrame('Frame')
    self.Frame = frame
    frame:RegisterEvent('NAME_PLATE_UNIT_ADDED')
    frame:SetScript('OnEvent', function(_, _, unit)
        StylePlate(unit)
    end)

    -- Blizzard's driver rebuilds every plate when a nameplate CVar it watches
    -- changes - style and size among them - and that rebuild replaces our
    -- texture and font. Re-apply after it, on the next frame so the rebuild is
    -- finished, and force past our own per-plate markers.
    if NamePlateDriverFrame and NamePlateDriverFrame.UpdateNamePlateOptions then
        hooksecurefunc(NamePlateDriverFrame, 'UpdateNamePlateOptions', function()
            C_Timer.After(0, function() Module:RestyleAll(true) end)
        end)
    end

    -- Style anything already on screen (enable happens post-login).
    self:RestyleAll(true)

    DF.ConfigModule:RegisterSettingsData('nameplates', 'misc',
                                         {name = 'Nameplates', options = options, default = setDefaultValues})

    self:SecureHook(DF, 'RefreshConfig', function()
        Module:ApplySettings()
        Module:RefreshOptionScreens()
    end)
end

function Module:OnDisable()
end
