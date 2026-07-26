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

local function getOption(info)
    return Module:GetOption(info)
end

local function setOption(info, value)
    Module:SetOption(info, value)
end

local styleValues = {
    THIN = 'Dragonflight (thin bar, name above)',
    MODERN = 'Midnight (thick bar, name inside)',
    CLASSIC = 'Classic (border ring, level box)',
    BLIZZARD = "Don't manage (use Blizzard's setting)"
}

local options = {
    name = 'Nameplates',
    desc = 'Nameplates',
    get = getOption,
    set = setOption,
    type = 'group',
    args = {
        style = {
            type = 'select',
            name = 'Nameplate style',
            desc = 'Which nameplate look to enforce.'
                .. " Pick \"Don't manage\" to leave the style entirely to Blizzard's own settings"
                .. ' - useful if you change it there and want it to stick across reloads.'
                .. getDefaultStr('style'),
            values = styleValues,
            order = 1
        },
        styleTexture = {
            type = 'toggle',
            name = 'DragonflightUI plate styling',
            desc = 'Apply the DragonflightUI health bar texture, outlined names and enemy level text.'
                .. ' Turn this off for untouched, native plates (needs a /reload to fully restore).'
                .. getDefaultStr('styleTexture'),
            order = 2
        },
        classColors = {
            type = 'toggle',
            name = 'Class-colored enemy plates',
            desc = 'Color enemy player health bars by class.' .. getDefaultStr('classColors'),
            order = 3
        }
    }
}

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

local function StylePlate(unit)
    if not (Module.db and Module.db.profile.styleTexture) then return end
    if not (C_NamePlate and C_NamePlate.GetNamePlateForUnit) then return end
    local plate = C_NamePlate.GetNamePlateForUnit(unit)
    if not plate then return end
    if plate.IsForbidden and plate:IsForbidden() then return end

    local uf = plate.UnitFrame
    if not uf or (uf.IsForbidden and uf:IsForbidden()) then return end

    local container = uf.HealthBarsContainer
    local healthBar = container and container.healthBar
    if healthBar and not healthBar.DFStyled then
        healthBar.DFStyled = true
        healthBar:SetStatusBarTexture(BAR_TEXTURE)
        local bg = (container and container.background) or healthBar.background
        if bg and bg.SetColorTexture then bg:SetColorTexture(0, 0, 0, 0.55) end
    end

    if uf.name and not uf.DFNameStyled then
        uf.DFNameStyled = true
        local path = uf.name:GetFont()
        if path then uf.name:SetFont(path, 10, 'OUTLINE') end
        uf.name:SetShadowOffset(0, 0)
    end

    -- Enemy level, top-right in line with the name. Plates are pooled, so
    -- the FontString is created once but refreshed for every new unit.
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
                local color = GetQuestDifficultyColor and GetQuestDifficultyColor(level)
                    or { r = 1, g = 0.82, b = 0 }
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
    if wanted ~= nil then C_CVar.SetCVar('nameplateStyle', wanted) end
end

function Module:ApplySettings(sub, key)
    self:ApplyStyleCVar()

    if self.db.profile.classColors and C_CVar and C_CVar.SetCVar then
        C_CVar.SetCVar('nameplateShowClassColor', 1)
    end

    if C_NamePlate and C_NamePlate.GetNamePlates then
        for _, plate in ipairs(C_NamePlate.GetNamePlates()) do
            if plate.namePlateUnitToken then StylePlate(plate.namePlateUnitToken) end
        end
    end
end

function Module:OnEnable()
    DF:Debug(self, 'Module ' .. mName .. ' OnEnable()')
    self:SetWasEnabled(true)

    -- Midnight-backport CVars, new to Era in 1.15.9: class-colored enemy
    -- health bars. Re-asserted at enable while the option is on.
    if self.db.profile.classColors and C_CVar and C_CVar.SetCVar then
        C_CVar.SetCVar('nameplateShowClassColor', 1)
    end

    self:ApplyStyleCVar()

    local frame = CreateFrame('Frame')
    self.Frame = frame
    frame:RegisterEvent('NAME_PLATE_UNIT_ADDED')
    frame:SetScript('OnEvent', function(_, _, unit)
        StylePlate(unit)
    end)

    -- Style anything already on screen (enable happens post-login).
    if C_NamePlate and C_NamePlate.GetNamePlates then
        for _, plate in ipairs(C_NamePlate.GetNamePlates()) do
            if plate.namePlateUnitToken then StylePlate(plate.namePlateUnitToken) end
        end
    end

    DF.ConfigModule:RegisterSettingsData('nameplates', 'misc',
                                         {name = 'Nameplates', options = options, default = setDefaultValues})

    self:SecureHook(DF, 'RefreshConfig', function()
        Module:ApplySettings()
        Module:RefreshOptionScreens()
    end)
end

function Module:OnDisable()
end
