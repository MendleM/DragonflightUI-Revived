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
local defaults = {
    profile = {
        classColors = true,
        modernStyle = true,
        style = 'THIN',
        styleTexture = true,
        showAllDebuffs = false,
        maxDebuffs = 8,
        otherDebuffScale = 100
    }
}
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
            Small = L["NameplatesSizeSmall"],
            Medium = L["NameplatesSizeMedium"],
            Large = L["NameplatesSizeLarge"],
            ExtraLarge = L["NameplatesSizeExtraLarge"],
            Huge = L["NameplatesSizeHuge"]
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
    {value = 'THIN', text = L["NameplatesStyleThin"]},
    {value = 'MODERN', text = L["NameplatesStyleModern"]},
    {value = 'CLASSIC', text = L["NameplatesStyleClassic"]},
    {value = 'BLIZZARD', text = L["NameplatesStyleBlizzard"]}
}

local options = {
    name = L["ModuleNameplates"],
    desc = L["ModuleNameplates"],
    get = getOption,
    set = setOption,
    type = 'group',
    args = {
        headerStyle = {type = 'header', name = L["NameplatesHeaderStyle"], desc = '', order = 0, isExpanded = true},
        style = {
            type = 'select',
            name = L["NameplatesOptionStyle"],
            desc = L["NameplatesOptionStyleDesc"] .. getDefaultStr('style'),
            dropdownValues = styleValues,
            order = 1,
            group = 'headerStyle'
        },
        styleTexture = {
            type = 'toggle',
            name = L["NameplatesOptionStyleTexture"],
            desc = L["NameplatesOptionStyleTextureDesc"] .. getDefaultStr('styleTexture'),
            order = 2,
            group = 'headerStyle'
        },
        headerVisibility = {type = 'header', name = L["NameplatesHeaderVisibility"], desc = '', order = 20, isExpanded = true}
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
            name = L["NameplatesOptionSize"],
            desc = L["NameplatesOptionSizeDesc"],
            dropdownValues = values,
            order = 3,
            group = 'headerStyle',
            blizzard = true
        }
    end

    addToggle('classColors', L["NameplatesOptionClassColors"], L["NameplatesOptionClassColorsDesc"], 4, 'headerStyle')
    addToggle('friendlyClassColors', L["NameplatesOptionFriendlyClassColors"], L["NameplatesOptionFriendlyClassColorsDesc"], 5,
              'headerStyle')

    addToggle('showEnemies', L["NameplatesOptionShowEnemies"], L["NameplatesOptionShowEnemiesDesc"], 21, 'headerVisibility')
    addToggle('showFriends', L["NameplatesOptionShowFriends"], L["NameplatesOptionShowFriendsDesc"], 22, 'headerVisibility')
    addToggle('showFriendlyNpcs', L["NameplatesOptionShowFriendlyNpcs"], L["NameplatesOptionShowFriendlyNpcsDesc"], 23,
              'headerVisibility')
    addToggle('friendlyNameOnly', L["NameplatesOptionFriendlyNameOnly"],
              L["NameplatesOptionFriendlyNameOnlyDesc"], 24, 'headerVisibility')
    addToggle('forceShowNames', L["NameplatesOptionForceShowNames"], L["NameplatesOptionForceShowNamesDesc"], 25,
              'headerVisibility')

    -- only clients with Blizzard's nameplate auras and the aura API have anything to extend
    if NamePlateAurasMixin and C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
        args.headerAuras = {type = 'header', name = L["NameplatesHeaderAuras"], desc = '', order = 30, isExpanded = true}
        args.showAllDebuffs = {
            type = 'toggle',
            name = L["NameplatesOptionShowAllDebuffs"],
            desc = L["NameplatesOptionShowAllDebuffsDesc"] .. getDefaultStr('showAllDebuffs'),
            order = 31,
            group = 'headerAuras',
            new = true
        }
        args.maxDebuffs = {
            type = 'range',
            name = L["NameplatesOptionMaxDebuffs"],
            desc = L["NameplatesOptionMaxDebuffsDesc"] .. getDefaultStr('maxDebuffs'),
            min = 1,
            max = 16,
            step = 1,
            bigStep = 1,
            order = 32,
            group = 'headerAuras',
            new = true
        }
        args.otherDebuffScale = {
            type = 'range',
            name = L["NameplatesOptionOtherDebuffScale"],
            desc = L["NameplatesOptionOtherDebuffScaleDesc"] .. getDefaultStr('otherDebuffScale'),
            min = 50,
            max = 100,
            step = 5,
            bigStep = 5,
            order = 33,
            group = 'headerAuras',
            new = true
        }
    end
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

    register('nameplates', {order = 2, name = L["ModuleNameplates"], descr = 'Nameplates', isNew = true})
end

function Module:RefreshOptionScreens()
    local configFrame = DF.ConfigModule.ConfigFrame
    if configFrame then configFrame:RefreshCatSub('Misc', 'Nameplates') end
end

local BAR_TEXTURE =
    'Interface\\Addons\\DragonflightUI\\Textures\\UI-HUD-UnitFrame-Player-PortraitOff-Bar-Health-Status32'

-- Does the plate style in force draw a level of its own? Blizzard's rule is
-- exactly one line - ShouldShowLevel(style) is ShouldUseClassicHealthBar(style),
-- "Classic health bar border has a space for level" - so only the classic style
-- does, and only there is our own level text a duplicate.
--
-- This asks the STYLE, not the plate. Reading the plate's LevelFrame was the
-- first attempt and it suppressed our level everywhere: that frame's shown
-- state is not a reliable answer at the moment we run, and one stale plate is
-- enough to get it wrong.
local function StyleDrawsOwnLevel()
    local classic = Enum and Enum.NamePlateStyle and Enum.NamePlateStyle.Classic
    if classic == nil then return false end

    local style = Module.db and Module.db.profile and Module.db.profile.style

    -- on "don't manage" the answer lives in the CVar, not in our profile
    if style == nil or style == 'BLIZZARD' then return tonumber(GetCVar('nameplateStyle')) == classic end

    return style == 'CLASSIC'
end

-- Enemy level, top-right in line with the name - but only on the styles that
-- have no level of their own. The classic plate draws a level box at the end of
-- its health bar, and ours came out as a second copy of the same number sitting
-- on top of the unit's name.
local function UpdateLevelText(uf, unit)
    if not (uf and uf.name and unit) then return end

    local styling = Module.db and Module.db.profile.styleTexture

    if not styling or StyleDrawsOwnLevel() then
        if uf.DFLevelText then uf.DFLevelText:Hide() end
        return
    end

    local levelText = uf.DFLevelText
    if not levelText then
        levelText = uf:CreateFontString(nil, 'OVERLAY')
        local path = uf.name:GetFont()
        if path then levelText:SetFont(path, 10, 'OUTLINE') end
        levelText:SetShadowOffset(0, 0)
        -- Right-aligned to the plate itself (the healthbar edge), on the name's
        -- line - anchoring off the centered name text pushed the level past the
        -- plate's end for long names.
        local container = uf.HealthBarsContainer
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

    UpdateLevelText(uf, unit)
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

-- Blizzard's AurasFrame only lists the player's own debuffs on enemies, and we cannot widen that without tainting its
-- layout. So Blizzard keeps its list untouched and we add a row of our own frames above it for everyone else's.
local OTHER_DEBUFF_SIZE = 25 -- NamePlateConstants.AURA_ITEM_HEIGHT
local OTHER_DEBUFF_SPACING = 2
local OTHER_DEBUFF_ALPHA = 0.6
local OTHER_DEBUFFS_PER_ROW = 8
local MAX_OTHER_DEBUFFS = 16
local MAX_AURA_SCAN = 40

local function CreateOtherDebuffButton(parent)
    local button = CreateFrame('Frame', nil, parent)

    button.icon = button:CreateTexture(nil, 'ARTWORK')
    button.icon:SetAllPoints()
    button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    button.border = button:CreateTexture(nil, 'OVERLAY')
    button.border:SetTexture('Interface\\Buttons\\UI-Debuff-Overlays')
    button.border:SetTexCoord(0.296875, 0.5703125, 0, 0.515625)
    button.border:SetPoint('TOPLEFT', -1, 1)
    button.border:SetPoint('BOTTOMRIGHT', 1, -1)

    button.cooldown = CreateFrame('Cooldown', nil, button, 'CooldownFrameTemplate')
    button.cooldown:SetAllPoints()
    button.cooldown:SetReverse(true)

    button.count = button:CreateFontString(nil, 'OVERLAY', 'NumberFontNormalSmall')
    button.count:SetPoint('BOTTOMRIGHT', 3, -2)

    return button
end

-- the plate's AurasFrame is the parent so our row follows its visibility (name-only plates, simplified plates)
local function GetOtherDebuffContainer(auras)
    local container = auras.DFOtherDebuffs
    if container then return container end

    container = CreateFrame('Frame', nil, auras)
    container:SetSize(1, 1)
    container:SetPoint('BOTTOMLEFT', auras.DebuffListFrame, 'TOPLEFT', 0, OTHER_DEBUFF_SPACING)
    container.buttons = {}
    auras.DFOtherDebuffs = container
    return container
end

local function IsOwnAura(aura)
    return aura.sourceUnit and UnitIsUnit('player', aura.sourceUnit)
end

-- Blizzard already lists a debuff when it is the player's own and flagged for nameplates (or the CVar lifts the flag
-- requirement), or crowd control on an NPC
local function BlizzardListsAura(aura, isPlayerUnit)
    if IsOwnAura(aura) and (aura.nameplateShowPersonal or ReadToggle('nameplateShowAllPersonalAuras')) then
        return true
    end
    return not isPlayerUnit and aura.spellId and C_Spell and C_Spell.IsSpellCrowdControl and
               C_Spell.IsSpellCrowdControl(aura.spellId)
end

local function SetupOtherDebuffButton(button, aura, size)
    button:SetSize(size, size)
    button.icon:SetTexture(aura.icon)

    -- other players' debuffs are dimmed so the player's own stand out and a lapsed one is easy to spot
    button:SetAlpha(IsOwnAura(aura) and 1 or OTHER_DEBUFF_ALPHA)

    local color = DebuffTypeColor and DebuffTypeColor[aura.dispelName or 'none']
    if color then button.border:SetVertexColor(color.r, color.g, color.b) end

    if aura.applications and aura.applications > 1 then
        button.count:SetText(aura.applications)
        button.count:Show()
    else
        button.count:Hide()
    end

    if aura.duration and aura.duration > 0 then
        button.cooldown:SetCooldown(aura.expirationTime - aura.duration, aura.duration)
        button.cooldown:SetHideCountdownNumbers(aura.duration > 60)
        button.cooldown:Show()
    else
        button.cooldown:Hide()
    end

    button:Show()
end

local function UpdateOtherDebuffs(plate, eventUnit)
    local uf = plate and plate.UnitFrame
    if not uf or (uf.IsForbidden and uf:IsForbidden()) then return end

    local auras = uf.AurasFrame
    if not auras then return end

    -- the event's token first: the plate's own fields may not be filled yet when we run
    local unit = eventUnit or auras.unitToken or plate.namePlateUnitToken
    local profile = Module.db and Module.db.profile
    local wanted = profile and profile.showAllDebuffs and unit and UnitCanAttack('player', unit)

    local container = auras.DFOtherDebuffs
    if not wanted and not container then return end
    container = container or GetOtherDebuffContainer(auras)

    local count = 0
    if wanted then
        local limit = math.min(profile.maxDebuffs or 8, MAX_OTHER_DEBUFFS)
        local size = OTHER_DEBUFF_SIZE * (auras.auraItemScale or 1) * math.min(profile.otherDebuffScale or 100, 100) / 100
        local isPlayerUnit = UnitIsPlayer(unit)

        for index = 1, MAX_AURA_SCAN do
            local aura = C_UnitAuras.GetAuraDataByIndex(unit, index, 'HARMFUL')
            if not aura then break end

            if not BlizzardListsAura(aura, isPlayerUnit) then
                count = count + 1
                local button = container.buttons[count] or CreateOtherDebuffButton(container)
                container.buttons[count] = button
                SetupOtherDebuffButton(button, aura, size)
                if count >= limit then break end
            end
        end

        -- left-aligned like Blizzard's own list, rows stack upwards
        local step = size + OTHER_DEBUFF_SPACING
        for i = 1, count do
            local row = math.floor((i - 1) / OTHER_DEBUFFS_PER_ROW)
            local col = (i - 1) % OTHER_DEBUFFS_PER_ROW
            local button = container.buttons[i]
            button:ClearAllPoints()
            button:SetPoint('BOTTOMLEFT', container, 'BOTTOMLEFT', col * step, row * step)
        end
    end

    for i = count + 1, #container.buttons do container.buttons[i]:Hide() end
end

function Module:UpdateAllOtherDebuffs()
    if not (C_NamePlate and C_NamePlate.GetNamePlates) then return end

    for _, plate in ipairs(C_NamePlate.GetNamePlates()) do UpdateOtherDebuffs(plate) end
end

function Module:ApplySettings(sub, key)
    self:ApplyStyleCVar()
    self:UpdateAllOtherDebuffs()
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
    frame:RegisterEvent('NAME_PLATE_UNIT_REMOVED')
    frame:RegisterEvent('UNIT_AURA')
    frame:SetScript('OnEvent', function(_, event, unit)
        if event == 'UNIT_AURA' then
            -- fires for every unit; only nameplate tokens matter
            if not (unit and unit:find('^nameplate')) then return end
        elseif event == 'NAME_PLATE_UNIT_ADDED' then
            StylePlate(unit)
        end

        local plate = C_NamePlate.GetNamePlateForUnit(unit)
        if event == 'NAME_PLATE_UNIT_REMOVED' then
            -- the pooled plate keeps its row until it is reused
            local auras = plate and plate.UnitFrame and plate.UnitFrame.AurasFrame
            local container = auras and auras.DFOtherDebuffs
            if container then
                for _, button in ipairs(container.buttons) do button:Hide() end
            end
        else
            UpdateOtherDebuffs(plate, unit)
        end
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

    -- Blizzard's own level call, hooked so our level text reconciles with
    -- theirs the moment they touch it - whichever side changed the style, and
    -- whether or not the plate is rebuilt. Without this, switching to the
    -- classic style left our level next to the name on every plate already on
    -- screen: it only corrected itself when the unit went out of range and its
    -- plate was recycled.
    if CompactUnitFrame_UpdateLevel then
        hooksecurefunc('CompactUnitFrame_UpdateLevel', function(frame)
            -- This hooks a global, so it fires for whatever anyone hands that
            -- global - not only for Blizzard's own frames. Reaching up to the
            -- plate with frame:GetParent() threw "calling 'GetParent' on bad
            -- self" for two reporters, once 266 times in a session, and the
            -- old guard could not catch it: frame.GetParent resolves through
            -- the metatable on anything frame-shaped, so it says nothing about
            -- whether the call will work.
            --
            -- Blizzard's own body reads frame.unit on its first line, and
            -- CompactUnitFrame_SetUnit writes both fields before calling us, so
            -- take the unit from there instead. A field read cannot bad-self,
            -- whatever turns up.
            if type(frame) ~= 'table' then return end
            local unit = frame.displayedUnit or frame.unit

            -- CompactUnitFrame is shared with the raid and party frames; only a
            -- nameplate's unit is a nameplate token.
            if type(unit) == 'string' and unit:sub(1, 9) == 'nameplate' then
                UpdateLevelText(frame, unit)
            end
        end)
    end

    -- Style anything already on screen (enable happens post-login).
    self:RestyleAll(true)
    self:UpdateAllOtherDebuffs()

    DF.ConfigModule:RegisterSettingsData('nameplates', 'misc',
                                         {name = L["ModuleNameplates"], options = options, default = setDefaultValues})

    self:SecureHook(DF, 'RefreshConfig', function()
        Module:ApplySettings()
        Module:RefreshOptionScreens()
    end)
end

function Module:OnDisable()
end
