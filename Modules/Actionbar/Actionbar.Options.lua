local addonName, addonTable = ...;
local Helper = addonTable.Helper;
---@diagnostic disable: undefined-global
local DF = LibStub('AceAddon-3.0'):GetAddon('DragonflightUI')
local L = LibStub("AceLocale-3.0"):GetLocale("DragonflightUI")
local Module = DF:GetModule('Actionbar')

local PossessBarFrame = _G['PossessBarFrame'] or CreateFrame('Frame', 'PossessBarFrame', UIParent)

local defaults = {
    profile = {
        vehicleLeave = Module.SubVehicleLeave.Defaults,
        actionbarRange = Module.SubActionbarRange.Defaults,
        scale = 1,
        x = 0,
        y = 0,
        showGryphon = true,
        changeSides = true,
        sideRows = 3,
        sideButtons = 12,
        bagsExpanded = true,
        alwaysShowXP = false,
        alwaysShowRep = false,
        bar1 = {
            scale = 1,
            anchorFrame = 'DragonflightUIRepBar',
            customAnchorFrame = '',
            anchor = 'BOTTOM',
            anchorParent = 'TOP',
            x = 0,
            y = 10,
            orientation = 'horizontal',
            growthDirection = 'up',
            flyoutDirection = 'UP',
            reverse = false,
            buttonScale = 0.8,
            rows = 1,
            buttons = 12,
            padding = 2,
            -- Style
            alwaysShow = true,
            activate = true,
            hideArt = false,
            hideScrolling = false,
            gryphons = 'DEFAULT',
            hideBorder = false,
            borderFill = 0.4,
            hideDivider = true,
            range = true,
            hideMacro = false,
            macroFontSize = 14,
            hideKeybind = false,
            shortenKeybind = false,
            useKeyDown = false,
            keybindFontSize = 16,
            -- mouseover
            useMouseover = false,
            mouseoverModifier = 'NONE',
            useAutoAssist = false,
            focusCast = false,
            selfCast = false,
            -- state
            stateDriver = 'SMART',
            -- Visibility
            alphaNormal = 1.0,
            alphaCombat = 1.0,
            showMouseover = false,
            hideAlways = false,
            hideCombat = false,
            hideOutOfCombat = false,
            hideVehicle = false,
            hidePet = false,
            hideNoPet = false,
            hideStance = false,
            hideStealth = false,
            hideNoStealth = false,
            hideBattlePet = true,
            hideCustom = false,
            hideCustomCond = ''
        },
        bar2 = {
            scale = 1,
            anchorFrame = 'DragonflightUIActionbarFrame1',
            customAnchorFrame = '',
            anchor = 'BOTTOM',
            anchorParent = 'TOP',
            x = 0,
            y = 0,
            orientation = 'horizontal',
            growthDirection = 'up',
            flyoutDirection = 'UP',
            reverse = false,
            buttonScale = 0.8,
            rows = 1,
            buttons = 12,
            padding = 2,
            -- mouseover
            useMouseover = false,
            mouseoverModifier = 'NONE',
            useAutoAssist = false,
            focusCast = false,
            selfCast = false,
            -- Style
            alwaysShow = true,
            activate = true,
            hideArt = true,
            range = true,
            hideMacro = false,
            macroFontSize = 14,
            hideKeybind = false,
            shortenKeybind = false,
            keybindFontSize = 16,
            -- Visibility
            alphaNormal = 1.0,
            alphaCombat = 1.0,
            showMouseover = false,
            hideAlways = false,
            hideCombat = false,
            hideOutOfCombat = false,
            hideVehicle = true,
            hidePet = false,
            hideNoPet = false,
            hideStance = false,
            hideStealth = false,
            hideNoStealth = false,
            hideBattlePet = true,
            hideCustom = false,
            hideCustomCond = ''
        },
        bar3 = {
            scale = 1,
            anchorFrame = 'DragonflightUIActionbarFrame2',
            customAnchorFrame = '',
            anchor = 'BOTTOM',
            anchorParent = 'TOP',
            x = 0,
            y = 0,
            orientation = 'horizontal',
            growthDirection = 'up',
            flyoutDirection = 'UP',
            reverse = false,
            buttonScale = 0.8,
            rows = 1,
            buttons = 12,
            padding = 2,
            -- mouseover
            useMouseover = false,
            mouseoverModifier = 'NONE',
            useAutoAssist = false,
            focusCast = false,
            selfCast = false,
            -- Style
            alwaysShow = true,
            activate = true,
            hideArt = true,
            range = true,
            hideMacro = false,
            macroFontSize = 14,
            hideKeybind = false,
            shortenKeybind = false,
            keybindFontSize = 16,
            -- Visibility
            alphaNormal = 1.0,
            alphaCombat = 1.0,
            showMouseover = false,
            hideAlways = false,
            hideCombat = false,
            hideOutOfCombat = false,
            hideVehicle = true,
            hidePet = false,
            hideNoPet = false,
            hideStance = false,
            hideStealth = false,
            hideNoStealth = false,
            hideBattlePet = true,
            hideCustom = false,
            hideCustomCond = ''
        },
        bar4 = {
            scale = 1,
            anchorFrame = 'DragonflightUIActionbarFrame2',
            customAnchorFrame = '',
            anchor = 'RIGHT',
            anchorParent = 'LEFT',
            x = -64,
            y = 0,
            orientation = 'horizontal',
            flyoutDirection = 'UP',
            growthDirection = 'up',
            reverse = false,
            buttonScale = 0.8,
            rows = 3,
            buttons = 12,
            padding = 2,
            -- mouseover
            useMouseover = false,
            mouseoverModifier = 'NONE',
            useAutoAssist = false,
            focusCast = false,
            selfCast = false,
            -- Style
            alwaysShow = true,
            activate = true,
            hideArt = true,
            range = true,
            hideMacro = false,
            macroFontSize = 14,
            hideKeybind = false,
            shortenKeybind = false,
            keybindFontSize = 16,
            -- Visibility
            alphaNormal = 1.0,
            alphaCombat = 1.0,
            showMouseover = false,
            hideAlways = false,
            hideCombat = false,
            hideOutOfCombat = false,
            hideVehicle = true,
            hidePet = false,
            hideNoPet = false,
            hideStance = false,
            hideStealth = false,
            hideNoStealth = false,
            hideBattlePet = true,
            hideCustom = false,
            hideCustomCond = ''
        },
        bar5 = {
            scale = 1,
            anchorFrame = 'DragonflightUIActionbarFrame2',
            customAnchorFrame = '',
            anchor = 'LEFT',
            anchorParent = 'RIGHT',
            x = 64,
            y = 0,
            orientation = 'horizontal',
            growthDirection = 'up',
            flyoutDirection = 'UP',
            reverse = false,
            buttonScale = 0.8,
            rows = 3,
            buttons = 12,
            padding = 2,
            -- mouseover
            useMouseover = false,
            mouseoverModifier = 'NONE',
            useAutoAssist = false,
            focusCast = false,
            selfCast = false,
            -- Style
            alwaysShow = true,
            activate = true,
            hideArt = true,
            range = true,
            hideMacro = false,
            macroFontSize = 14,
            hideKeybind = false,
            shortenKeybind = false,
            keybindFontSize = 16,
            -- Visibility
            alphaNormal = 1.0,
            alphaCombat = 1.0,
            showMouseover = false,
            hideAlways = false,
            hideCombat = false,
            hideOutOfCombat = false,
            hideVehicle = true,
            hidePet = false,
            hideNoPet = false,
            hideStance = false,
            hideStealth = false,
            hideNoStealth = false,
            hideBattlePet = true,
            hideCustom = false,
            hideCustomCond = ''
        },
        bar6 = {
            scale = 1,
            anchorFrame = 'DragonflightUIActionbarFrame3',
            customAnchorFrame = '',
            anchor = 'BOTTOM',
            anchorParent = 'TOP',
            x = 0,
            y = 0,
            orientation = 'horizontal',
            growthDirection = 'up',
            flyoutDirection = 'UP',
            reverse = false,
            buttonScale = 0.8,
            rows = 1,
            buttons = 12,
            padding = 2,
            -- mouseover
            useMouseover = false,
            mouseoverModifier = 'NONE',
            useAutoAssist = false,
            focusCast = false,
            selfCast = false,
            -- Style
            alwaysShow = true,
            activate = false,
            hideArt = true,
            range = true,
            hideMacro = false,
            macroFontSize = 14,
            hideKeybind = false,
            shortenKeybind = false,
            keybindFontSize = 16,
            -- Visibility
            alphaNormal = 1.0,
            alphaCombat = 1.0,
            showMouseover = false,
            hideAlways = false,
            hideCombat = false,
            hideOutOfCombat = false,
            hideVehicle = true,
            hidePet = false,
            hideNoPet = false,
            hideStance = false,
            hideStealth = false,
            hideNoStealth = false,
            hideBattlePet = true,
            hideCustom = false,
            hideCustomCond = ''
        },
        bar7 = {
            scale = 1,
            anchorFrame = 'DragonflightUIActionbarFrame6',
            customAnchorFrame = '',
            anchor = 'BOTTOM',
            anchorParent = 'TOP',
            x = 0,
            y = 0,
            orientation = 'horizontal',
            growthDirection = 'up',
            flyoutDirection = 'UP',
            reverse = false,
            buttonScale = 0.8,
            rows = 1,
            buttons = 12,
            padding = 2,
            -- mouseover
            useMouseover = false,
            mouseoverModifier = 'NONE',
            useAutoAssist = false,
            focusCast = false,
            selfCast = false,
            -- Style
            alwaysShow = true,
            activate = false,
            hideArt = true,
            range = true,
            hideMacro = false,
            macroFontSize = 14,
            hideKeybind = false,
            shortenKeybind = false,
            keybindFontSize = 16,
            -- Visibility
            alphaNormal = 1.0,
            alphaCombat = 1.0,
            showMouseover = false,
            hideAlways = false,
            hideCombat = false,
            hideOutOfCombat = false,
            hideVehicle = true,
            hidePet = false,
            hideNoPet = false,
            hideStance = false,
            hideStealth = false,
            hideNoStealth = false,
            hideBattlePet = true,
            hideCustom = false,
            hideCustomCond = ''
        },
        bar8 = {
            scale = 1,
            anchorFrame = 'DragonflightUIActionbarFrame7',
            customAnchorFrame = '',
            anchor = 'BOTTOM',
            anchorParent = 'TOP',
            x = 0,
            y = 0,
            orientation = 'horizontal',
            growthDirection = 'up',
            flyoutDirection = 'UP',
            reverse = false,
            buttonScale = 0.8,
            rows = 1,
            buttons = 12,
            padding = 2,
            -- mouseover
            useMouseover = false,
            mouseoverModifier = 'NONE',
            useAutoAssist = false,
            focusCast = false,
            selfCast = false,
            -- Style
            alwaysShow = true,
            activate = false,
            hideArt = true,
            range = true,
            hideMacro = false,
            macroFontSize = 14,
            hideKeybind = false,
            shortenKeybind = false,
            keybindFontSize = 16,
            -- Visibility
            alphaNormal = 1.0,
            alphaCombat = 1.0,
            showMouseover = false,
            hideAlways = false,
            hideCombat = false,
            hideOutOfCombat = false,
            hideVehicle = true,
            hidePet = false,
            hideNoPet = false,
            hideStance = false,
            hideStealth = false,
            hideNoStealth = false,
            hideBattlePet = true,
            hideCustom = false,
            hideCustomCond = ''
        },
        pet = {
            scale = 1,
            anchorFrame = 'DragonflightUIActionbarFrame3',
            customAnchorFrame = '',
            anchor = 'BOTTOMLEFT',
            anchorParent = 'TOPLEFT',
            x = 0,
            y = 0,
            orientation = 'horizontal',
            growthDirection = 'up',
            reverse = false,
            buttonScale = DF.API.Version.IsModern and 0.65 or 0.8,
            rows = 1,
            buttons = 10,
            padding = 2,
            -- Style
            alwaysShow = true,
            activate = true,
            hideMacro = false,
            macroFontSize = 14,
            hideKeybind = false,
            shortenKeybind = false,
            keybindFontSize = 16,
            -- Visibility
            alphaNormal = 1.0,
            alphaCombat = 1.0,
            showMouseover = false,
            hideAlways = false,
            hideCombat = false,
            hideOutOfCombat = false,
            hideVehicle = true,
            hidePet = false,
            hideNoPet = true,
            hideStance = false,
            hideStealth = false,
            hideNoStealth = false,
            hideBattlePet = true,
            hideCustom = false,
            hideCustomCond = ''
        },
        xp = {
            scale = 1,
            anchorFrame = 'UIParent',
            customAnchorFrame = '',
            anchor = 'BOTTOM',
            anchorParent = 'BOTTOM',
            x = 0,
            y = 5,
            width = 466,
            height = 20,
            alwaysShowXP = false,
            showXPPercent = true,
            -- Visibility
            alphaNormal = 1.0,
            alphaCombat = 1.0,
            showMouseover = false,
            hideAlways = false,
            hideCombat = false,
            hideOutOfCombat = false,
            hideVehicle = true,
            hidePet = false,
            hideNoPet = false,
            hideStance = false,
            hideStealth = false,
            hideNoStealth = false,
            hideBattlePet = true,
            hideCustom = false,
            hideCustomCond = ''
        },
        rep = {
            scale = 1,
            anchorFrame = 'DragonflightUIXPBar',
            customAnchorFrame = '',
            anchor = 'BOTTOM',
            anchorParent = 'TOP',
            x = 0,
            y = 0,
            width = 466,
            height = 20,
            alwaysShowRep = false,
            -- Visibility
            alphaNormal = 1.0,
            alphaCombat = 1.0,
            showMouseover = false,
            hideAlways = false,
            hideCombat = false,
            hideOutOfCombat = false,
            hideVehicle = true,
            hidePet = false,
            hideNoPet = false,
            hideStance = false,
            hideStealth = false,
            hideNoStealth = false,
            hideBattlePet = true,
            hideCustom = false,
            hideCustomCond = ''
        },
        stance = {
            scale = 1,
            anchorFrame = 'DragonflightUIActionbarFrame3',
            customAnchorFrame = '',
            anchor = 'BOTTOMLEFT',
            anchorParent = 'TOPLEFT',
            x = 0,
            y = 0,
            orientation = 'horizontal',
            growthDirection = 'up',
            reverse = false,
            buttonScale = 0.8,
            rows = 1,
            buttons = 10,
            padding = 2,
            -- Style
            alwaysShow = false,
            activate = true,
            hideMacro = false,
            macroFontSize = 14,
            hideKeybind = false,
            shortenKeybind = false,
            keybindFontSize = 16,
            -- Visibility
            alphaNormal = 1.0,
            alphaCombat = 1.0,
            showMouseover = false,
            hideAlways = false,
            hideCombat = false,
            hideOutOfCombat = false,
            hideVehicle = true,
            hidePet = false,
            hideNoPet = false,
            hideStance = false,
            hideStealth = false,
            hideNoStealth = false,
            hideBattlePet = true,
            hideCustom = false,
            hideCustomCond = ''
        },
        totem = {
            scale = 1,
            anchorFrame = 'DragonflightUIActionbarFrame3',
            customAnchorFrame = '',
            anchor = 'BOTTOM',
            anchorParent = 'TOP',
            x = 0,
            y = 2,
            -- Visibility
            alphaNormal = 1.0,
            alphaCombat = 1.0,
            showMouseover = false,
            hideAlways = false,
            hideCombat = false,
            hideOutOfCombat = false,
            hideVehicle = true,
            hidePet = false,
            hideNoPet = false,
            hideStance = false,
            hideStealth = false,
            hideNoStealth = false,
            hideBattlePet = false,
            hideCustom = false,
            hideCustomCond = ''
        },
        possess = {
            scale = 1,
            anchorFrame = 'DragonflightUIActionbarFrame3',
            customAnchorFrame = '',
            anchor = 'BOTTOMLEFT',
            anchorParent = 'TOPLEFT',
            x = -4,
            y = 2,
            offset = false,
            -- Visibility
            alphaNormal = 1.0,
            alphaCombat = 1.0,
            hideAlways = false,
            hideCombat = false,
            hideOutOfCombat = false,
            hideVehicle = true,
            hidePet = false,
            hideNoPet = false,
            hideStance = false,
            hideStealth = false,
            hideNoStealth = false,
            hideBattlePet = true,
            hideCustom = false,
            hideCustomCond = ''
        },
        bags = {
            scale = 1,
            anchorFrame = 'UIParent',
            customAnchorFrame = '',
            anchor = 'BOTTOMRIGHT',
            anchorParent = 'BOTTOMRIGHT',
            x = 6,
            y = 50,
            expanded = true,
            hideArrow = false,
            overrideBagAnchor = false,
            offsetX = 5,
            offsetY = 95,
            -- Visibility
            alphaNormal = 1.0,
            alphaCombat = 1.0,
            showMouseover = false,
            hideAlways = false,
            hideCombat = false,
            hideOutOfCombat = false,
            hideVehicle = true,
            hidePet = false,
            hideNoPet = false,
            hideStance = false,
            hideStealth = false,
            hideNoStealth = false,
            hideBattlePet = false,
            hideCustom = false,
            hideCustomCond = ''
        },
        micro = {
            scale = 1,
            anchorFrame = 'UIParent',
            customAnchorFrame = '',
            anchor = 'BOTTOMRIGHT',
            anchorParent = 'BOTTOMRIGHT',
            x = 8,
            y = 0,
            hidden = false,
            -- Visibility
            alphaNormal = 1.0,
            alphaCombat = 1.0,
            showMouseover = false,
            hideAlways = false,
            hideCombat = false,
            hideOutOfCombat = false,
            hideVehicle = false,
            hidePet = false,
            hideNoPet = false,
            hideStance = false,
            hideStealth = false,
            hideNoStealth = false,
            hideBattlePet = false,
            hideCustom = false,
            hideCustomCond = ''
        },
        fps = {
            scale = 1,
            anchorFrame = 'DragonflightUIMicroMenuBar',
            customAnchorFrame = '',
            anchor = 'RIGHT',
            anchorParent = 'LEFT',
            x = -5,
            y = 0,
            hidden = false,
            hideDefaultFPS = true,
            alwaysShowFPS = false,
            showFPS = true,
            showPing = true
        },
        extraActionButton = {
            scale = 1,
            anchorFrame = 'UIParent',
            customAnchorFrame = '',
            anchor = 'BOTTOM',
            anchorParent = 'BOTTOM',
            x = 0,
            y = 320,
            hideBackgroundTexture = false
        }
    }
}

Module.Defaults = defaults
Module:SetDefaults(defaults)

local function getDefaultStr(key, sub)
    return Module:GetDefaultStr(key, sub)
end

local function setDefaultValues()
    Module:SetDefaultValues()
end

local function setDefaultSubValues(sub)
    Module:SetDefaultSubValues(sub)
end

local function getOption(info)
    return Module:GetOption(info)
end

local function setOption(info, value)
    Module:SetOption(info, value)
end

local function setPreset(T, preset, sub)
    for k, v in pairs(preset) do
        T[k] = v;
    end
    Module:ApplySettings(sub)
    Module:RefreshOptionScreens()
end

local frameTable = {
    {value = 'UIParent', text = 'UIParent', tooltip = 'descr', label = 'label'},
    {value = 'DragonflightUIXPBar', text = L["XPBar"], tooltip = 'descr', label = 'label'},
    {value = 'DragonflightUIRepBar', text = L["ReputationBar"], tooltip = 'descr', label = 'label'},
    {value = 'DragonflightUIPetbar', text = L["PetBar"], tooltip = 'descr', label = 'label'},
    {value = 'DragonflightUIStancebar', text = L["StanceBar"], tooltip = 'descr', label = 'label'},
    {value = 'PossessBarFrame', text = L["PossessBar"], tooltip = 'descr', label = 'label'},
    {value = 'DragonflightUIMicroMenuBar', text = L["MicroMenu"], tooltip = 'descr', label = 'label'}
}

for i = 1, 8 do
    table.insert(frameTable, i + 1, {
        value = 'DragonflightUIActionbarFrame' .. i,
        text = L["ActionbarNameFormat"]:format(i),
        tooltip = 'descr',
        label = 'label'
    })
end

local gryphonsTable = {
    {value = 'DEFAULT', text = L["Default"], tooltip = 'descr', label = 'label'},
    {value = 'ALLY', text = L["Alliance"], tooltip = 'descr', label = 'label'},
    {value = 'HORDE', text = L["Horde"], tooltip = 'descr', label = 'label'},
    {value = 'NONE', text = L["None"], tooltip = 'descr', label = 'label'}
}

local stateDriverTable = {
    {value = 'DEFAULT', text = L["ActionbarDriverDefault"], tooltip = 'descr', label = 'label'},
    {value = 'SMART', text = L["ActionbarDriverSmart"], tooltip = 'descr', label = 'label'},
    {value = 'NOPAGING', text = L["ActionbarDriverNoPaging"], tooltip = 'descr', label = 'label'}
}

if DF.Cata then
    table.insert(frameTable,
                 {value = 'MultiCastActionBarFrame', text = L["TotemBar"], tooltip = 'descr', label = 'label'})
end

local function frameTableWithout(without)
    local newTable = {}
    for k, v in ipairs(frameTable) do
        if v.value ~= without then
            table.insert(newTable, v);
        end
    end
    return newTable
end

function AddButtonTable(optionTable, sub)
    local extraOptions = {
        activate = {
            type = 'toggle',
            name = L["ButtonTableActive"],
            desc = L["ButtonTableActiveDesc"] .. getDefaultStr('activate', sub),
            order = -1,
            new = false,
            editmode = true
        },
        headerButtons = {
            type = 'header',
            name = L["ButtonTableButtons"],
            desc = L["ButtonTableButtonsDesc"],
            order = 10,
            isExpanded = true,
            editmode = true
        },
        buttonScale = {
            type = 'range',
            name = L["ButtonTableButtonScale"],
            desc = L["ButtonTableButtonScaleDesc"] .. getDefaultStr('buttonScale', sub),
            min = 0.1,
            max = 3,
            bigStep = 0.05,
            order = 1,
            group = 'headerButtons',
            editmode = true
        },
        orientation = {
            type = 'select',
            name = L["ButtonTableOrientation"],
            desc = L["ButtonTableOrientationDesc"] .. getDefaultStr('orientation', sub),
            dropdownValues = DF.Settings.OrientationTable,
            order = 7,
            group = 'headerButtons',
            editmode = true
        },
        growthDirection = {
            type = 'select',
            name = L["ButtonTableGrowthDirection"],
            desc = L["ButtonTableGrowthDirectionDesc"] .. getDefaultStr('growthDirection', sub),
            dropdownValues = DF.Settings.GrowthDirectionTable,
            order = 7.1,
            group = 'headerButtons',
            new = false,
            editmode = true
        },
        flyoutDirection = {
            type = 'select',
            name = L["ButtonTableFlyoutDirection"],
            desc = L["ButtonTableFlyoutDirectionDesc"] .. getDefaultStr('flyoutDirection', sub),
            dropdownValues = DF.Settings.FlyoutDirectionTable,
            order = 7.2,
            group = 'headerButtons',
            new = false,
            editmode = true
        },
        reverse = {
            type = 'toggle',
            name = L["ButtonTableReverseButtonOrder"],
            desc = L["ButtonTableReverseButtonOrderDesc"] .. getDefaultStr('reverse', sub),
            order = 7.5,
            group = 'headerButtons',
            editmode = true
        },
        rows = {
            type = 'range',
            name = L["ButtonTableNumRows"],
            desc = L["ButtonTableNumRowsDesc"] .. getDefaultStr('rows', sub),
            min = 1,
            max = 12,
            bigStep = 1,
            order = 9,
            group = 'headerButtons',
            editmode = true
        },
        buttons = {
            type = 'range',
            name = L["ButtonTableNumButtons"],
            desc = L["ButtonTableNumButtonsDesc"] .. getDefaultStr('buttons', sub),
            min = 1,
            max = 12,
            bigStep = 1,
            order = 10,
            group = 'headerButtons',
            editmode = true
        },
        padding = {
            type = 'range',
            name = L["ButtonTablePadding"],
            desc = L["ButtonTablePaddingDesc"] .. getDefaultStr('padding', sub),
            min = 0,
            max = 10,
            bigStep = 1,
            order = 11,
            group = 'headerButtons',
            editmode = true
        },
        headerStyling = {
            type = 'header',
            name = L["ButtonTableStyle"],
            desc = L["ButtonTableStyleDesc"],
            order = 20,
            isExpanded = true,
            editmode = true
        },
        alwaysShow = {
            type = 'toggle',
            name = L["ButtonTableAlwaysShowActionbar"],
            desc = L["ButtonTableAlwaysShowActionbarDesc"] .. getDefaultStr('alwaysShow', sub),
            group = 'headerStyling',
            order = 50.1,
            editmode = true
        },
        range = {
            type = 'toggle',
            name = L["MoreOptionsIconRangeColor"],
            desc = L["MoreOptionsIconRangeColorDesc"] .. getDefaultStr('range', sub),
            group = 'headerStyling',
            order = 51.1,
            new = true,
            editmode = true
        },
        hideMacro = {
            type = 'toggle',
            name = L["ButtonTableHideMacroText"],
            desc = L["ButtonTableHideMacroTextDesc"] .. getDefaultStr('hideMacro', sub),
            group = 'headerStyling',
            order = 55,
            editmode = true
        },
        macroFontSize = {
            type = 'range',
            name = L["ButtonTableMacroNameFontSize"],
            desc = L["ButtonTableMacroNameFontSizeDesc"] .. getDefaultStr('macroFontSize', sub),
            min = 6,
            max = 24,
            bigStep = 1,
            group = 'headerStyling',
            order = 55.1,
            new = false,
            editmode = true
        },
        hideKeybind = {
            type = 'toggle',
            name = L["ButtonTableHideKeybindText"],
            desc = L["ButtonTableHideKeybindTextDesc"] .. getDefaultStr('hideKeybind', sub),
            group = 'headerStyling',
            order = 56,
            editmode = true
        },
        shortenKeybind = {
            type = 'toggle',
            name = L["ButtonTableShortenKeybindText"],
            desc = L["ButtonTableShortenKeybindTextDesc"] .. getDefaultStr('shortenKeybind', sub),
            group = 'headerStyling',
            order = 56.05,
            editmode = true,
            new = false
        },
        keybindFontSize = {
            type = 'range',
            name = L["ButtonTableKeybindFontSize"],
            desc = L["ButtonTableKeybindFontSizeDesc"] .. getDefaultStr('keybindFontSize', sub),
            min = 6,
            max = 24,
            bigStep = 1,
            group = 'headerStyling',
            order = 56.1,
            new = false,
            editmode = true
        }
    }

    if DF.API.Version.IsEra or DF.API.Version.IsTBC then extraOptions['flyoutDirection'] = nil; end

    for k, v in pairs(extraOptions) do
        optionTable.args[k] = v
    end
end

local function GetBarOption(n)
    local barname = 'bar' .. n
    local opt = {
        name = L["ActionbarNameFormat"]:format(n),
        desc = L["ActionbarNameFormat"]:format(n),
        advancedName = 'ActionBars',
        sub = barname,
        get = getOption,
        set = setOption,
        type = 'group',
        args = {}
    }
    AddButtonTable(opt, barname)
    DF.Settings:AddPositionTable(Module, opt, barname, 'Action Bar' .. n, getDefaultStr,
                                 frameTableWithout('DragonflightUIActionbarFrame' .. n), function()
        return Module['bar' .. n]
    end)
    opt.args.scale = nil;
    if n == 1 then
        local moreOptions = {
            hideArt = {
                type = 'toggle',
                name = L["MoreOptionsHideBarArt"],
                desc = L["MoreOptionsHideBarArtDesc"] .. getDefaultStr('hideArt', barname),
                group = 'headerButtons',
                order = 51.2,
                editmode = true
            },
            hideScrolling = {
                type = 'toggle',
                name = L["MoreOptionsHideBarScrolling"],
                desc = L["MoreOptionsHideBarScrollingDesc"] .. getDefaultStr('hideScrolling', barname),
                group = 'headerButtons',
                order = 51.3,
                editmode = true
            },
            hideBorder = {
                type = 'toggle',
                name = L["MoreOptionsHideBorder"],
                desc = L["MoreOptionsHideBorderDesc"] .. getDefaultStr('hideBorder', barname),
                group = 'headerButtons',
                order = 51.4,
                editmode = true
            },
            borderFill = {
                type = 'range',
                name = L["MoreOptionsBorderFill"],
                desc = L["MoreOptionsBorderFillDesc"] .. getDefaultStr('borderFill', barname),
                min = 0,
                max = 1,
                bigStep = 0.05,
                group = 'headerButtons',
                order = 51.45,
                editmode = true
            },
            hideDivider = {
                type = 'toggle',
                name = L["MoreOptionsHideDivider"],
                desc = L["MoreOptionsHideDividerDesc"] .. getDefaultStr('hideDivider', barname),
                group = 'headerButtons',
                order = 51.5,
                editmode = true
            },
            gryphons = {
                type = 'select',
                name = L["MoreOptionsGryphons"],
                desc = L["MoreOptionsGryphonsDesc"] .. getDefaultStr('gryphons', barname),
                values = {['DEFAULT'] = 'DEFAULT', ['ALLY'] = 'ALLIANCE', ['HORDE'] = 'HORDE', ['NONE'] = 'NONE'},
                dropdownValues = gryphonsTable,
                group = 'headerButtons',
                order = 51.4,
                editmode = true
            },
            useKeyDown = {
                type = 'toggle',
                name = L["MoreOptionsUseKeyDown"],
                desc = L["MoreOptionsUseKeyDownDesc"] .. getDefaultStr('useKeyDown', barname),
                group = 'headerButtons',
                order = 51.0,
                editmode = true,
                blizzard = true
            },
            stateDriver = {
                type = 'select',
                name = L["ActionbarDriverName"],
                desc = L["ActionbarDriverNameDesc"] .. getDefaultStr('stateDriver', barname),
                dropdownValues = stateDriverTable,
                group = 'headerButtons',
                order = 52.0,
                editmode = true,
                new = false
            }
        }

        for k, v in pairs(moreOptions) do opt.args[k] = v end

        opt.get = function(info)
            local key = info[1]
            local sub = info[2]
            if sub == 'useKeyDown' then
                if GetCVarBool('ActionButtonUseKeyDown') then
                    return true
                else
                    return false
                end
            else
                return getOption(info)
            end
        end

        opt.set = function(info, value)
            local key = info[1]
            local sub = info[2]

            if sub == 'useKeyDown' then
                if value then
                    C_CVar.SetCVar('ActionButtonUseKeyDown', 1)
                else
                    C_CVar.SetCVar('ActionButtonUseKeyDown', 0)
                end
            else
                setOption(info, value)
            end
        end
    else
        local moreOptions = {
            hideArt = {
                type = 'toggle',
                name = L["MoreOptionsHideBarArt"],
                desc = L["MoreOptionsHideBarArtDesc"] .. getDefaultStr('hideArt', barname),
                group = 'headerStyling',
                order = 50.2,
                editmode = true,
                new = true
            }
        }
        for k, v in pairs(moreOptions) do opt.args[k] = v end
    end

    DragonflightUIStateHandlerMixin:AddStateTable(Module, opt, barname, 'Actionbar' .. n, getDefaultStr)
    DragonflightUIActionbarMixin:AddTargetStateTable(Module, opt, getDefaultStr)

    if n == 4 then
        opt.name = L["ActionbarNameFormat"]:format(5)
    elseif n == 5 then
        opt.name = L["ActionbarNameFormat"]:format(4)
    end

    return opt
end

local function GetBarExtraOptions(n)
    local bar = 'bar' .. n;
    local extra = {
        name = bar,
        desc = bar,
        get = getOption,
        set = setOption,
        type = 'group',
        args = {
            resetPosition = {
                type = 'execute',
                name = L["ExtraOptionsPreset"],
                btnName = L["ExtraOptionsResetToDefaultPosition"],
                desc = L["ExtraOptionsPresetDesc"],
                func = function()
                    local dbTable = Module.db.profile[bar]
                    local defaultsTable = defaults.profile[bar]
                    setPreset(dbTable, {
                        scale = defaultsTable.scale,
                        anchor = defaultsTable.anchor,
                        anchorParent = defaultsTable.anchorParent,
                        anchorFrame = defaultsTable.anchorFrame,
                        x = defaultsTable.x,
                        y = defaultsTable.y
                    }, bar)
                end,
                order = 16,
                editmode = true,
                new = false
            }
        }
    }

    if n == 4 then
        local morePresets = {
            sidebarModern = {
                type = 'execute',
                name = L["ExtraOptionsPreset"],
                btnName = L["ExtraOptionsModernLayout"],
                desc = L["ExtraOptionsModernLayoutDesc"],
                func = function()
                    local dbTable = Module.db.profile[bar]
                    local defaultsTable = defaults.profile[bar]
                    setPreset(dbTable, {
                        scale = defaultsTable.scale,
                        anchor = defaultsTable.anchor,
                        anchorParent = defaultsTable.anchorParent,
                        anchorFrame = defaultsTable.anchorFrame,
                        x = defaultsTable.x,
                        y = defaultsTable.y,

                        orientation = defaultsTable.orientation,
                        reverse = defaultsTable.reverse,
                        buttonScale = defaultsTable.buttonScale,
                        rows = defaultsTable.rows,
                        buttons = defaultsTable.buttons,
                        padding = defaultsTable.padding
                    }, bar)
                end,
                order = 20,
                editmode = true,
                new = false
            },
            sidebarClassic = {
                type = 'execute',
                name = L["ExtraOptionsPreset"],
                btnName = L["ExtraOptionsClassicLayout"],
                desc = L["ExtraOptionsClassicLayoutDesc"],
                func = function()
                    local dbTable = Module.db.profile[bar]
                    local defaultsTable = defaults.profile[bar]
                    setPreset(dbTable, {
                        scale = defaultsTable.scale,
                        anchor = 'RIGHT',
                        anchorParent = 'RIGHT',
                        anchorFrame = 'UIParent',
                        x = -38,
                        y = -100,

                        orientation = 'vertical',
                        reverse = false,
                        buttonScale = defaultsTable.buttonScale,
                        rows = 1,
                        buttons = 12,
                        padding = defaultsTable.padding
                    }, bar)
                end,
                order = 21,
                editmode = true,
                new = false
            }
        }
        for k, v in pairs(morePresets) do extra.args[k] = v end

    elseif n == 5 then
        local morePresets = {
            sidebarModern = {
                type = 'execute',
                name = L["ExtraOptionsPreset"],
                btnName = L["ExtraOptionsModernLayout"],
                desc = L["ExtraOptionsModernLayoutDesc"],
                func = function()
                    local dbTable = Module.db.profile[bar]
                    local defaultsTable = defaults.profile[bar]
                    setPreset(dbTable, {
                        scale = defaultsTable.scale,
                        anchor = defaultsTable.anchor,
                        anchorParent = defaultsTable.anchorParent,
                        anchorFrame = defaultsTable.anchorFrame,
                        x = defaultsTable.x,
                        y = defaultsTable.y,

                        orientation = defaultsTable.orientation,
                        reverse = defaultsTable.reverse,
                        buttonScale = defaultsTable.buttonScale,
                        rows = defaultsTable.rows,
                        buttons = defaultsTable.buttons,
                        padding = defaultsTable.padding
                    }, bar)
                end,
                order = 20,
                editmode = true,
                new = false
            },
            sidebarClassic = {
                type = 'execute',
                name = L["ExtraOptionsPreset"],
                btnName = L["ExtraOptionsClassicLayout"],
                desc = L["ExtraOptionsClassicLayoutDesc"],
                func = function()
                    local dbTable = Module.db.profile[bar]
                    local defaultsTable = defaults.profile[bar]
                    setPreset(dbTable, {
                        scale = defaultsTable.scale,
                        anchor = 'RIGHT',
                        anchorParent = 'RIGHT',
                        anchorFrame = 'UIParent',
                        x = 0,
                        y = -100,

                        orientation = 'vertical',
                        reverse = false,
                        buttonScale = defaultsTable.buttonScale,
                        rows = 1,
                        buttons = 12,
                        padding = defaultsTable.padding
                    }, bar)
                end,
                order = 21,
                editmode = true,
                new = false
            }
        }
        for k, v in pairs(morePresets) do extra.args[k] = v end
    end

    return extra;
end

local petOptions = {
    name = L["PetBar"],
    advancedName = 'PetBar',
    sub = 'pet',
    desc = '',
    get = getOption,
    set = setOption,
    type = 'group',
    args = {}
}
AddButtonTable(petOptions, 'pet')
DF.Settings:AddPositionTable(Module, petOptions, 'pet', 'Pet Bar', getDefaultStr,
                             frameTableWithout('DragonflightUIPetbar'))
petOptions.args.scale = nil;
petOptions.args.hideMacro = nil;
petOptions.args.macroFontSize = nil;
petOptions.args.buttons.max = 10;
petOptions.args.flyoutDirection = nil;

DragonflightUIStateHandlerMixin:AddStateTable(Module, petOptions, 'pet', 'PetBar', getDefaultStr)
local optionsPetEdtimode = {
    name = 'pet',
    desc = 'pet',
    get = getOption,
    set = setOption,
    type = 'group',
    args = {
        resetPosition = {
            type = 'execute',
            name = L["ExtraOptionsPreset"],
            btnName = L["ExtraOptionsResetToDefaultPosition"],
            desc = L["ExtraOptionsPresetDesc"],
            func = function()
                local dbTable = Module.db.profile.pet
                local defaultsTable = defaults.profile.pet
                setPreset(dbTable, {
                    scale = defaultsTable.scale,
                    anchor = defaultsTable.anchor,
                    anchorParent = defaultsTable.anchorParent,
                    anchorFrame = defaultsTable.anchorFrame,
                    x = defaultsTable.x,
                    y = defaultsTable.y
                }, 'pet')
            end,
            order = 16,
            editmode = true,
            new = false
        }
    }
}

local xpOptions = {
    name = L["XPOptionsName"],
    desc = L["XPOptionsDesc"],
    advancedName = 'XPBar',
    sub = 'xp',
    get = getOption,
    set = setOption,
    type = 'group',
    args = {
        headerStyling = {
            type = 'header',
            name = L["XPOptionsStyle"],
            desc = L["XPOptionsStyleDesc"],
            order = 20,
            editmode = true,
            isExpanded = true
        },
        width = {
            type = 'range',
            name = L["XPOptionsWidth"],
            desc = L["XPOptionsWidthDesc"] .. getDefaultStr('width', 'xp'),
            min = 1,
            max = 2500,
            bigStep = 1,
            group = 'headerStyling',
            order = 7,
            editmode = true
        },
        height = {
            type = 'range',
            name = L["XPOptionsHeight"],
            desc = L["XPOptionsHeightDesc"] .. getDefaultStr('height', 'xp'),
            min = 1,
            max = 69,
            bigStep = 1,
            group = 'headerStyling',
            order = 8,
            editmode = true
        },
        alwaysShowXP = {
            type = 'toggle',
            name = L["XPOptionsAlwaysShowXPText"],
            desc = L["XPOptionsAlwaysShowXPTextDesc"] .. getDefaultStr('alwaysShowXP', 'xp'),
            group = 'headerStyling',
            order = 12,
            editmode = true
        },
        showXPPercent = {
            type = 'toggle',
            name = L["XPOptionsShowXPPercent"],
            desc = L["XPOptionsShowXPPercentDesc"] .. getDefaultStr('showXPPercent', 'xp'),
            group = 'headerStyling',
            order = 13,
            editmode = true
        }
    }
}

DF.Settings:AddPositionTable(Module, xpOptions, 'xp', 'XP Bar', getDefaultStr,
                             frameTableWithout('DragonflightUIPetbar'), function()
    return Module.xpbar
end)
DragonflightUIStateHandlerMixin:AddStateTable(Module, xpOptions, 'xp', 'XPBar', getDefaultStr)
local optionsXpEdtimode = {
    name = 'xp',
    desc = 'xp',
    get = getOption,
    set = setOption,
    type = 'group',
    args = {
        resetPosition = {
            type = 'execute',
            name = L["ExtraOptionsPreset"],
            btnName = L["ExtraOptionsResetToDefaultPosition"],
            desc = L["ExtraOptionsPresetDesc"],
            func = function()
                local dbTable = Module.db.profile.xp
                local defaultsTable = defaults.profile.xp
                setPreset(dbTable, {
                    scale = defaultsTable.scale,
                    anchor = defaultsTable.anchor,
                    anchorParent = defaultsTable.anchorParent,
                    anchorFrame = defaultsTable.anchorFrame,
                    x = defaultsTable.x,
                    y = defaultsTable.y
                }, 'xp')
            end,
            order = 16,
            editmode = true,
            new = false
        }
    }
}

local repOptions = {
    name = L["RepOptionsName"],
    desc = L["RepOptionsDesc"],
    advancedName = 'RepBar',
    sub = 'rep',
    get = getOption,
    set = setOption,
    type = 'group',
    args = {
        headerStyling = {
            type = 'header',
            name = L["RepOptionsStyle"],
            desc = L["RepOptionsStyleDesc"],
            order = 20,
            editmode = true,
            isExpanded = true
        },
        width = {
            type = 'range',
            name = L["RepOptionsWidth"],
            desc = L["RepOptionsWidthDesc"] .. getDefaultStr('width', 'rep'),
            min = 1,
            max = 2500,
            bigStep = 1,
            group = 'headerStyling',
            order = 7,
            editmode = true
        },
        height = {
            type = 'range',
            name = L["RepOptionsHeight"],
            desc = L["RepOptionsHeightDesc"] .. getDefaultStr('height', 'rep'),
            min = 1,
            max = 69,
            bigStep = 1,
            group = 'headerStyling',
            order = 8,
            editmode = true
        },
        alwaysShowRep = {
            type = 'toggle',
            name = L["RepOptionsAlwaysShowRepText"],
            desc = L["RepOptionsAlwaysShowRepTextDesc"] .. getDefaultStr('alwaysShowRep', 'rep'),
            group = 'headerStyling',
            order = 12,
            editmode = true
        }
    }
}

DF.Settings:AddPositionTable(Module, repOptions, 'rep', 'Reputation Bar', getDefaultStr,
                             frameTableWithout('DragonflightUIRepBar'), function()
    return Module.repbar
end)
DragonflightUIStateHandlerMixin:AddStateTable(Module, repOptions, 'rep', 'RepBar', getDefaultStr)
local optionsRepEdtimode = {
    name = 'rep',
    desc = 'rep',
    get = getOption,
    set = setOption,
    type = 'group',
    args = {
        resetPosition = {
            type = 'execute',
            name = L["ExtraOptionsPreset"],
            btnName = L["ExtraOptionsResetToDefaultPosition"],
            desc = L["ExtraOptionsPresetDesc"],
            func = function()
                local dbTable = Module.db.profile.rep
                local defaultsTable = defaults.profile.rep
                setPreset(dbTable, {
                    scale = defaultsTable.scale,
                    anchor = defaultsTable.anchor,
                    anchorParent = defaultsTable.anchorParent,
                    anchorFrame = defaultsTable.anchorFrame,
                    x = defaultsTable.x,
                    y = defaultsTable.y
                }, 'rep')
            end,
            order = 16,
            editmode = true,
            new = false
        }
    }
}

local stanceOptions = {
    name = L["StanceBar"],
    advancedName = 'StanceBar',
    sub = 'stance',
    desc = 'StanceBar',
    get = getOption,
    set = setOption,
    type = 'group',
    args = {activate = {type = 'toggle', name = 'Active', desc = '' .. getDefaultStr('activate', 'stance'), order = 13}}
}
AddButtonTable(stanceOptions, 'stance')
DF.Settings:AddPositionTable(Module, stanceOptions, 'stance', 'Stance Bar', getDefaultStr,
                             frameTableWithout('DragonflightUIStanceBar'))
stanceOptions.args.scale = nil;
stanceOptions.args.buttons.max = 10;
stanceOptions.args.flyoutDirection = nil;

DragonflightUIStateHandlerMixin:AddStateTable(Module, stanceOptions, 'stance', 'StanceBar', getDefaultStr)
local optionsStanceEdtimode = {
    name = 'stance',
    desc = 'stance',
    get = getOption,
    set = setOption,
    type = 'group',
    args = {
        resetPosition = {
            type = 'execute',
            name = L["ExtraOptionsPreset"],
            btnName = L["ExtraOptionsResetToDefaultPosition"],
            desc = L["ExtraOptionsPresetDesc"],
            func = function()
                local dbTable = Module.db.profile.stance
                local defaultsTable = defaults.profile.stance
                setPreset(dbTable, {
                    scale = defaultsTable.scale,
                    anchor = defaultsTable.anchor,
                    anchorParent = defaultsTable.anchorParent,
                    anchorFrame = defaultsTable.anchorFrame,
                    x = defaultsTable.x,
                    y = defaultsTable.y
                }, 'stance')
            end,
            order = 16,
            editmode = true,
            new = false
        }
    }
}

local totemOptions = {
    name = L["TotemBar"],
    desc = L["TotemBar"],
    advancedName = 'TotemBar',
    sub = 'totem',
    get = getOption,
    set = setOption,
    type = 'group',
    args = {}
}
DF.Settings:AddPositionTable(Module, totemOptions, 'totem', 'Totem Bar', getDefaultStr,
                             frameTableWithout('MultiCastActionBarFrame'))
DragonflightUIStateHandlerMixin:AddStateTable(Module, totemOptions, 'totem', 'TotemBar', getDefaultStr)
local optionsTotemEdtimode = {
    name = 'totem',
    desc = 'totem',
    get = getOption,
    set = setOption,
    type = 'group',
    args = {
        resetPosition = {
            type = 'execute',
            name = L["ExtraOptionsPreset"],
            btnName = L["ExtraOptionsResetToDefaultPosition"],
            desc = L["ExtraOptionsPresetDesc"],
            func = function()
                local dbTable = Module.db.profile.totem
                local defaultsTable = defaults.profile.totem
                setPreset(dbTable, {
                    scale = defaultsTable.scale,
                    anchor = defaultsTable.anchor,
                    anchorParent = defaultsTable.anchorParent,
                    anchorFrame = defaultsTable.anchorFrame,
                    x = defaultsTable.x,
                    y = defaultsTable.y
                }, 'totem')
            end,
            order = 16,
            editmode = true,
            new = false
        }
    }
}

local possessOptions = {
    name = L["PossessBar"],
    desc = L["PossessBar"],
    advancedName = 'PossessBar',
    sub = 'possess',
    get = getOption,
    set = setOption,
    type = 'group',
    args = {
        headerStyling = {type = 'header', name = 'Style', desc = '', order = 20, isExpanded = true},
        offset = {
            type = 'toggle',
            name = 'Auto adjust offset',
            desc = 'Auto add some Y offset depending on the class, e.g. on Paladin to make room for the stance bar' ..
                getDefaultStr('offset', 'possess'),
            group = 'headerStyling',
            order = 11,
            new = false,
            editmode = true
        }
    }
}
DF.Settings:AddPositionTable(Module, possessOptions, 'possess', 'Possess Bar', getDefaultStr,
                             frameTableWithout('PossessBarFrame'))
DragonflightUIStateHandlerMixin:AddStateTable(Module, possessOptions, 'possess', 'PossessBar', getDefaultStr)
local optionsPossessEdtimode = {
    name = 'possess',
    desc = 'possess',
    get = getOption,
    set = setOption,
    type = 'group',
    args = {
        resetPosition = {
            type = 'execute',
            name = L["ExtraOptionsPreset"],
            btnName = L["ExtraOptionsResetToDefaultPosition"],
            desc = L["ExtraOptionsPresetDesc"],
            func = function()
                local dbTable = Module.db.profile.possess
                local defaultsTable = defaults.profile.possess
                setPreset(dbTable, {
                    scale = defaultsTable.scale,
                    anchor = defaultsTable.anchor,
                    anchorParent = defaultsTable.anchorParent,
                    anchorFrame = defaultsTable.anchorFrame,
                    x = defaultsTable.x,
                    y = defaultsTable.y
                }, 'possess')
            end,
            order = 16,
            editmode = true,
            new = false
        }
    }
}

local bagsOptions = {
    name = L["BagsOptionsName"],
    desc = L["BagsOptionsDesc"],
    advancedName = 'Bags',
    sub = 'bags',
    get = getOption,
    set = setOption,
    type = 'group',
    args = {
        headerStyling = {
            type = 'header',
            name = L["BagsOptionsStyle"],
            desc = L["BagsOptionsStyleDesc"],
            order = 20,
            isExpanded = true,
            editmode = true
        },
        expanded = {
            type = 'toggle',
            name = L["BagsOptionsExpanded"],
            desc = L["BagsOptionsExpandedDesc"] .. getDefaultStr('expanded', 'bags'),
            group = 'headerStyling',
            order = 7,
            editmode = true
        },
        hideArrow = {
            type = 'toggle',
            name = L["BagsOptionsHideArrow"],
            desc = L["BagsOptionsHideArrowDesc"] .. getDefaultStr('hideArrow', 'bags'),
            group = 'headerStyling',
            order = 8,
            editmode = true
        },
        overrideBagAnchor = {
            type = 'toggle',
            name = L["BagsOptionsOverrideBagAnchor"],
            desc = L["BagsOptionsOverrideBagAnchorDesc"] .. getDefaultStr('overrideBagAnchor', 'bags'),
            group = 'headerStyling',
            order = 15,
            new = false
        },
        offsetX = {
            type = 'range',
            name = L["BagsOptionsOffsetX"],
            desc = L["BagsOptionsOffsetXDesc"] .. getDefaultStr('offsetX', 'bags'),
            min = -2500,
            max = 2500,
            bigStep = 1,
            group = 'headerStyling',
            order = 16,
            new = false
        },
        offsetY = {
            type = 'range',
            name = L["BagsOptionsOffsetY"],
            desc = L["BagsOptionsOffsetYDesc"] .. getDefaultStr('offsetY', 'bags'),
            min = -2500,
            max = 2500,
            bigStep = 1,
            group = 'headerStyling',
            order = 17,
            new = false
        }
    }
}

-- bag blizzard options
do
    local moreOptions = {
        showFreeBagSlots = {
            type = 'toggle',
            name = DISPLAY_FREE_BAG_SLOTS,
            desc = OPTION_TOOLTIP_DISPLAY_FREE_BAG_SLOTS,
            group = 'headerStyling',
            order = 13,
            blizzard = true
        }
    }

    for k, v in pairs(moreOptions) do bagsOptions.args[k] = v end

    bagsOptions.get = function(info)
        local key = info[1]
        local sub = info[2]

        if sub == 'showFreeBagSlots' then
            return C_CVar.GetCVarBool("displayFreeBagSlots")
        else
            return getOption(info)
        end
    end

    bagsOptions.set = function(info, value)
        local key = info[1]
        local sub = info[2]

        if sub == 'showFreeBagSlots' then
            if value then
                C_CVar.SetCVar("displayFreeBagSlots", 1)
            else
                C_CVar.SetCVar("displayFreeBagSlots", 0)
            end
        else
            setOption(info, value)
        end
    end
end
DF.Settings:AddPositionTable(Module, bagsOptions, 'bags', 'Bags', getDefaultStr, frameTable)
DragonflightUIStateHandlerMixin:AddStateTable(Module, bagsOptions, 'bags', 'Bags', getDefaultStr)
local optionsBagsEdtimode = {
    name = 'bags',
    desc = 'bags',
    get = getOption,
    set = setOption,
    type = 'group',
    args = {
        resetPosition = {
            type = 'execute',
            name = L["ExtraOptionsPreset"],
            btnName = L["ExtraOptionsResetToDefaultPosition"],
            desc = L["ExtraOptionsPresetDesc"],
            func = function()
                local dbTable = Module.db.profile.bags
                local defaultsTable = defaults.profile.bags
                setPreset(dbTable, {
                    scale = defaultsTable.scale,
                    anchor = defaultsTable.anchor,
                    anchorParent = defaultsTable.anchorParent,
                    anchorFrame = defaultsTable.anchorFrame,
                    x = defaultsTable.x,
                    y = defaultsTable.y
                }, 'bags')
            end,
            order = 16,
            editmode = true,
            new = false
        }
    }
}

local microOptions = {
    desc = 'Micromenu',
    name = L["MicroMenu"],
    advancedName = 'MicroMenu',
    sub = 'micro',
    get = getOption,
    set = setOption,
    type = 'group',
    args = {}
}
DF.Settings:AddPositionTable(Module, microOptions, 'micro', 'Micromenu', getDefaultStr, frameTable)
DragonflightUIStateHandlerMixin:AddStateTable(Module, microOptions, 'micro', 'Micromenu', getDefaultStr)
local optionsMicroEditmode = {
    name = 'micro',
    desc = 'micro',
    get = getOption,
    set = setOption,
    type = 'group',
    args = {
        resetPosition = {
            type = 'execute',
            name = L["ExtraOptionsPreset"],
            btnName = L["ExtraOptionsResetToDefaultPosition"],
            desc = L["ExtraOptionsPresetDesc"],
            func = function()
                local dbTable = Module.db.profile.micro
                local defaultsTable = defaults.profile.micro
                setPreset(dbTable, {
                    scale = defaultsTable.scale,
                    anchor = defaultsTable.anchor,
                    anchorParent = defaultsTable.anchorParent,
                    anchorFrame = defaultsTable.anchorFrame,
                    x = defaultsTable.x,
                    y = defaultsTable.y
                }, 'micro')
            end,
            order = 16,
            editmode = true,
            new = false
        }
    }
}

local fpsOptions = {
    name = L["FPSOptionsName"],
    desc = L["FPSOptionsDesc"],
    advancedName = 'FPS',
    sub = 'fps',
    get = getOption,
    set = setOption,
    type = 'group',
    args = {
        headerStyling = {
            type = 'header',
            name = L["FPSOptionsStyle"],
            desc = L["FPSOptionsStyleDesc"],
            order = 20,
            isExpanded = true,
            editmode = true
        },
        hideDefaultFPS = {
            type = 'toggle',
            name = L["FPSOptionsHideDefaultFPS"],
            desc = L["FPSOptionsHideDefaultFPSDesc"] .. getDefaultStr('hideDefaultFPS', 'fps'),
            group = 'headerStyling',
            order = 8,
            editmode = true
        },
        showFPS = {
            type = 'toggle',
            name = L["FPSOptionsShowFPS"],
            desc = L["FPSOptionsShowFPSDesc"] .. getDefaultStr('showFPS', 'fps'),
            group = 'headerStyling',
            order = 10,
            editmode = true
        },
        alwaysShowFPS = {
            type = 'toggle',
            name = L["FPSOptionsAlwaysShowFPS"],
            desc = L["FPSOptionsAlwaysShowFPSDesc"] .. getDefaultStr('alwaysShowFPS', 'fps'),
            group = 'headerStyling',
            order = 9,
            editmode = true
        },
        showPing = {
            type = 'toggle',
            name = L["FPSOptionsShowPing"],
            desc = L["FPSOptionsShowPingDesc"] .. getDefaultStr('showPing', 'fps'),
            group = 'headerStyling',
            order = 11,
            editmode = true
        }
    }
}

DF.Settings:AddPositionTable(Module, fpsOptions, 'fps', 'FPS', getDefaultStr, frameTable)

local optionsFPSEditmode = {
    name = 'fps',
    desc = 'fps',
    get = getOption,
    set = setOption,
    type = 'group',
    args = {
        resetPosition = {
            type = 'execute',
            name = L["ExtraOptionsPreset"],
            btnName = L["ExtraOptionsResetToDefaultPosition"],
            desc = L["ExtraOptionsPresetDesc"],
            func = function()
                local dbTable = Module.db.profile.fps
                local defaultsTable = defaults.profile.fps
                setPreset(dbTable, {
                    scale = defaultsTable.scale,
                    anchor = defaultsTable.anchor,
                    anchorParent = defaultsTable.anchorParent,
                    anchorFrame = defaultsTable.anchorFrame,
                    x = defaultsTable.x,
                    y = defaultsTable.y
                }, 'fps')
            end,
            order = 16,
            editmode = true,
            new = false
        }
    }
}

local extraActionButtonOptions = {
    name = L["ExtraActionButtonOptionsName"],
    desc = L["ExtraActionButtonOptionsNameDesc"],
    advancedName = 'ExtraActionButton',
    sub = 'extraActionButton',
    get = getOption,
    set = setOption,
    type = 'group',
    args = {
        headerStyling = {
            type = 'header',
            name = L["ExtraActionButtonStyle"],
            desc = L["ExtraActionButtonStyleDesc"],
            order = 20,
            isExpanded = true,
            editmode = true
        },
        hideBackgroundTexture = {
            type = 'toggle',
            name = L["ExtraActionButtonHideBackgroundTexture"],
            desc = L["ExtraActionButtonHideBackgroundTextureDesc"] ..
                getDefaultStr('hideBackgroundTexture', 'extraActionButton'),
            group = 'headerStyling',
            order = 8,
            editmode = true
        }
    }
}

DF.Settings:AddPositionTable(Module, extraActionButtonOptions, 'extraActionButton', 'Extra Action Button',
                             getDefaultStr, frameTable)

local extraActionButtonOptionsEditmode = {
    name = 'extraActionButton',
    desc = 'extraActionButton',
    get = getOption,
    set = setOption,
    type = 'group',
    args = {
        resetPosition = {
            type = 'execute',
            name = L["ExtraOptionsPreset"],
            btnName = L["ExtraOptionsResetToDefaultPosition"],
            desc = L["ExtraOptionsPresetDesc"],
            func = function()
                local dbTable = Module.db.profile.extraActionButton
                local defaultsTable = defaults.profile.extraActionButton
                setPreset(dbTable, {
                    scale = defaultsTable.scale,
                    anchor = defaultsTable.anchor,
                    anchorParent = defaultsTable.anchorParent,
                    anchorFrame = defaultsTable.anchorFrame,
                    x = defaultsTable.x,
                    y = defaultsTable.y
                }, 'extraActionButton')
            end,
            order = 16,
            editmode = true,
            new = false
        }
    }
}

function Module:RegisterSettings()
    local moduleName = 'Actionbar'
    local cat = 'actionbar'
    local function register(name, data)
        data.module = moduleName;
        DF.ConfigModule:RegisterSettingsElement(name, cat, data, true)
    end

    for i = 1, 8 do register('actionbar' .. i, {order = i, name = 'Action Bar ' .. i, descr = 'desc', isNew = false}) end

    register('petbar', {order = 9, name = petOptions.name, descr = 'desc', isNew = false})
    register('xpbar', {order = 10, name = xpOptions.name, descr = 'desc', isNew = false})
    register('repbar', {order = 11, name = repOptions.name, descr = 'desc', isNew = false})
    register('possessbar', {order = 12, name = possessOptions.name, descr = 'desc', isNew = false})
    register('stancebar', {order = 13, name = stanceOptions.name, descr = 'desc', isNew = false})

    register('bags', {order = 15, name = bagsOptions.name, descr = 'desc', isNew = false})
    register('micromenu', {order = 16, name = microOptions.name, descr = 'desc', isNew = false})
    register('fps', {order = 17, name = fpsOptions.name, descr = 'desc', isNew = false})

    register('vehicleLeave', {order = 18, name = self.SubVehicleLeave.Options.name, descr = 'desc', isNew = false})
    register('actionbarRange', {order = 8.5, name = self.SubActionbarRange.Options.name, descr = 'desc', isNew = true})

    if DF.Cata then
        register('totembar', {order = 14, name = totemOptions.name, descr = 'desc', isNew = false})
        register('extraactionbutton', {order = 8.5, name = extraActionButtonOptions.name, descr = 'desc', isNew = false})
    end
end

function Module:AddEditMode()
    local EditModeModule = DF:GetModule('Editmode');

    -- bars
    for i = 1, 8 do
        local bar = Module['bar' .. i]

        EditModeModule:AddEditModeToFrame(bar)
        local optionsBar = GetBarOption(i)

        bar.DFEditModeSelection:SetGetLabelTextFunction(function()
            return optionsBar.name
        end)

        local optionsBarExtra = GetBarExtraOptions(i)
        bar.DFEditModeSelection:RegisterOptions({
            options = optionsBar,
            extra = optionsBarExtra,
            default = function()
                setDefaultSubValues('bar' .. i)
            end,
            moduleRef = self
        });
    end

    -- extra action button
    if DF.Cata then
        local f = CreateFrame('FRAME', 'DragonflightUIExtraActionButtonPreview', UIParent)
        f:SetPoint('CENTER', UIParent, 'CENTER', 0, -180)
        f:SetSize(64, 64)
        f:SetClampedToScreen(true)

        Module.ExtraActionButtonPreview = f;

        EditModeModule:AddEditModeToFrame(f)

        f.DFEditModeSelection:SetGetLabelTextFunction(function()
            return extraActionButtonOptions.name
        end)

        f.DFEditModeSelection:RegisterOptions({
            options = extraActionButtonOptions,
            extra = extraActionButtonOptionsEditmode,
            default = function()
                setDefaultSubValues('extraActionButton')
            end,
            moduleRef = self,
            hideFunction = function()
                f:Show()
            end
        });
    end

    -- Pet 
    EditModeModule:AddEditModeToFrame(Module.petbar)

    Module.petbar.DFEditModeSelection:SetGetLabelTextFunction(function()
        return petOptions.name
    end)

    Module.petbar.DFEditModeSelection:RegisterOptions({
        options = petOptions,
        extra = optionsPetEdtimode,
        default = function()
            setDefaultSubValues('pet')
        end,
        moduleRef = self
    });

    -- XP 
    EditModeModule:AddEditModeToFrame(Module.xpbar)

    Module.xpbar.DFEditModeSelection:SetGetLabelTextFunction(function()
        return xpOptions.name
    end)

    Module.xpbar.DFEditModeSelection:RegisterOptions({
        options = xpOptions,
        extra = optionsXpEdtimode,
        default = function()
            setDefaultSubValues('xp')
        end,
        moduleRef = self
    });

    -- Rep 
    EditModeModule:AddEditModeToFrame(Module.repbar)

    Module.repbar.DFEditModeSelection:SetGetLabelTextFunction(function()
        return repOptions.name
    end)

    Module.repbar.DFEditModeSelection:RegisterOptions({
        options = repOptions,
        extra = optionsRepEdtimode,
        default = function()
            setDefaultSubValues('rep')
        end,
        moduleRef = self
    });

    -- Possess 
    EditModeModule:AddEditModeToFrame(PossessBarFrame)

    PossessBarFrame.DFEditModeSelection:SetGetLabelTextFunction(function()
        return possessOptions.name
    end)

    PossessBarFrame.DFEditModeSelection:RegisterOptions({
        options = possessOptions,
        extra = optionsPossessEdtimode,
        default = function()
            setDefaultSubValues('possess')
        end,
        moduleRef = self
    });

    PossessBarFrame.DFEditModeSelection:ClearAllPoints()
    local possessDelta = 4
    PossessBarFrame.DFEditModeSelection:SetPoint('TOPLEFT', _G['PossessButton1'], 'TOPLEFT', -possessDelta, possessDelta)
    PossessBarFrame.DFEditModeSelection:SetPoint('BOTTOMRIGHT', _G['PossessButton2'], 'BOTTOMRIGHT', possessDelta,
                                                 -possessDelta)

    -- Stance 
    EditModeModule:AddEditModeToFrame(Module.stancebar)

    Module.stancebar.DFEditModeSelection:SetGetLabelTextFunction(function()
        return stanceOptions.name
    end)

    Module.stancebar.DFEditModeSelection:RegisterOptions({
        options = stanceOptions,
        extra = optionsStanceEdtimode,
        default = function()
            setDefaultSubValues('stance')
        end,
        moduleRef = self
    });

    -- totem
    if DF.Cata and MultiCastActionBarFrame then
        EditModeModule:AddEditModeToFrame(MultiCastActionBarFrame)

        MultiCastActionBarFrame.DFEditModeSelection:SetGetLabelTextFunction(function()
            return totemOptions.name
        end)

        MultiCastActionBarFrame.DFEditModeSelection:RegisterOptions({
            options = totemOptions,
            extra = optionsTotemEdtimode,
            default = function()
                setDefaultSubValues('totem')
            end,
            moduleRef = self
        });
    end

    -- Bags
    local DFBagBar = _G['DragonflightUIBagBar']
    EditModeModule:AddEditModeToFrame(DFBagBar)

    DFBagBar.DFEditModeSelection:SetGetLabelTextFunction(function()
        return bagsOptions.name
    end)

    DFBagBar.DFEditModeSelection:RegisterOptions({
        options = bagsOptions,
        extra = optionsBagsEdtimode,
        default = function()
            setDefaultSubValues('bags')
            UpdateContainerFrameAnchors()
        end,
        moduleRef = self
    });

    -- Micro 
    EditModeModule:AddEditModeToFrame(Module.MicroFrame)

    Module.MicroFrame.DFEditModeSelection:SetGetLabelTextFunction(function()
        return microOptions.name
    end)

    Module.MicroFrame.DFEditModeSelection:RegisterOptions({
        options = microOptions,
        extra = optionsMicroEditmode,
        default = function()
            setDefaultSubValues('micro')
        end,
        moduleRef = self
    });

    -- fps 
    EditModeModule:AddEditModeToFrame(Module.FPSFrame)

    Module.FPSFrame.DFEditModeSelection:SetGetLabelTextFunction(function()
        return fpsOptions.name
    end)

    Module.FPSFrame.DFEditModeSelection:RegisterOptions({
        options = fpsOptions,
        extra = optionsFPSEditmode,
        default = function()
            setDefaultSubValues('fps')
        end,
        moduleRef = self
    });
end

function Module:RegisterOptionScreens()
    for i = 1, 8 do
        local optionsBar
        local defaultsIndex = i;
        if i == 4 then
            optionsBar = GetBarOption(5)
            defaultsIndex = 5;
        elseif i == 5 then
            optionsBar = GetBarOption(4)
            defaultsIndex = 4;
        else
            optionsBar = GetBarOption(i)
        end
        DF.ConfigModule:RegisterSettingsData('actionbar' .. i, 'actionbar', {
            options = optionsBar,
            default = function()
                setDefaultSubValues('bar' .. defaultsIndex)
            end
        })
    end

    if DF.Cata then
        DF.ConfigModule:RegisterSettingsData('extraactionbutton', 'actionbar', {
            options = extraActionButtonOptions,
            default = function()
                setDefaultSubValues('extraActionButton')
            end
        })
    end

    DF.ConfigModule:RegisterSettingsData('petbar', 'actionbar', {
        options = petOptions,
        default = function()
            setDefaultSubValues('pet')
        end
    })

    DF.ConfigModule:RegisterSettingsData('xpbar', 'actionbar', {
        options = xpOptions,
        default = function()
            setDefaultSubValues('xp')
        end
    })

    DF.ConfigModule:RegisterSettingsData('repbar', 'actionbar', {
        options = repOptions,
        default = function()
            setDefaultSubValues('rep')
        end
    })

    DF.ConfigModule:RegisterSettingsData('possessbar', 'actionbar', {
        options = possessOptions,
        default = function()
            setDefaultSubValues('possess')
        end
    })

    DF.ConfigModule:RegisterSettingsData('stancebar', 'actionbar', {
        options = stanceOptions,
        default = function()
            setDefaultSubValues('stance')
        end
    })
    if DF.Cata then
        DF.ConfigModule:RegisterSettingsData('totembar', 'actionbar', {
            options = totemOptions,
            default = function()
                setDefaultSubValues('totem')
            end
        })
    end

    DF.ConfigModule:RegisterSettingsData('bags', 'actionbar', {
        options = bagsOptions,
        default = function()
            setDefaultSubValues('bags')
            UpdateContainerFrameAnchors()
        end
    })

    DF.ConfigModule:RegisterSettingsData('micromenu', 'actionbar', {
        options = microOptions,
        default = function()
            setDefaultSubValues('micro')
        end
    })

    DF.ConfigModule:RegisterSettingsData('fps', 'actionbar', {
        options = fpsOptions,
        default = function()
            setDefaultSubValues('fps')
        end
    })
end

function Module:RefreshOptionScreens()
    local configFrame = DF.ConfigModule.ConfigFrame

    local refreshCat = function(name)
        configFrame:RefreshCatSub('Actionbar', name)
    end

    for i = 1, 8 do refreshCat('Actionbar' .. i) end
    refreshCat('Petbar')
    refreshCat('XPbar')
    refreshCat('Repbar')
    refreshCat('Stancebar')
    if DF.Cata then refreshCat('Totembar') end
    refreshCat('Bags')
    refreshCat('Micromenu')
    refreshCat('FPS')

    local function refresh(frame)
        local selection = frame and frame.DFEditModeSelection
        if selection then selection:RefreshOptionScreen() end
    end

    for i = 1, 8 do refresh(Module['bar' .. i]) end

    refresh(Module.petbar)
    refresh(Module.xpbar)
    refresh(Module.repbar)
    refresh(PossessBarFrame)
    refresh(Module.stancebar)

    if DF.Cata then
        refresh(MultiCastActionBarFrame)
        refresh(Module.ExtraActionButtonPreview)
    end

    refresh(_G['DragonflightUIBagBar'])
    refresh(Module.MicroFrame)
    refresh(Module.FPSFrame)
    refresh(_G['DragonflightUIVehicleLeaveButton'])
end
