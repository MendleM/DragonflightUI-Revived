local addonName, addonTable = ...;
local DF = addonTable.DF;
local L = addonTable.L;
local Helper = addonTable.Helper;

local subModuleName = 'PlayerFrameSecondaryRes';
local SubModuleMixin = {};
addonTable.SubModuleMixins[subModuleName] = SubModuleMixin;

function SubModuleMixin:Init()
    self.ModuleRef = DF:GetModule('Unitframe')
    local _, class = UnitClass('player')
    self.Class = class
    self.Adapter = addonTable.SecondaryResAdapters and addonTable.SecondaryResAdapters[class]
    self:SetDefaults()
    self:SetupOptions()
end

function SubModuleMixin:SetDefaults()
    local defaults = {
        activate = true,
        scale = 1.0,
        anchorFrame = 'PlayerFrame',
        customAnchorFrame = '',
        anchor = 'TOPRIGHT',
        anchorParent = 'BOTTOMRIGHT',
        x = -7,
        y = 35
    };
    self.Defaults = defaults;
end

function SubModuleMixin:SetupOptions()
    local Module = self.ModuleRef;
    local function getDefaultStr(key, sub, extra)
        local value = self.Defaults[key]
        local defaultFormat = L["SettingsDefaultStringFormat"]
        return string.format(defaultFormat, (extra or '') .. tostring(value))
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
        {value = 'PlayerFrame', text = 'PlayerFrame', tooltip = 'descr', label = 'label'},
        {value = 'TargetFrame', text = 'TargetFrame', tooltip = 'descr', label = 'label'},
        {value = 'CompactRaidFrameManager', text = 'CompactRaidFrameManager', tooltip = 'descr', label = 'label'}
    }
    if DF.Wrath then
        table.insert(frameTable, {value = 'FocusFrame', text = 'FocusFrame', tooltip = 'descr', label = 'label'})
    end

    local optionsPlayer = {
        name = L["PlayerSecondaryResName"],
        desc = L["PlayerSecondaryResNameDesc"],
        advancedName = 'PlayerSecondaryRes',
        sub = "playerSecondaryRes",
        get = getOption,
        set = setOption,
        type = 'group',
        args = {
            activate = {
                type = 'toggle',
                name = L["ButtonTableActive"],
                desc = L["ButtonTableActiveDesc"] .. getDefaultStr('activate', 'playerSecondaryRes'),
                order = -1,
                new = false,
                editmode = true
            }
        }
    }

    DF.Settings:AddPositionTable(Module, optionsPlayer, 'playerSecondaryRes', 'playerSecondaryRes', getDefaultStr,
                                 frameTable)

    local optionsPlayerEditmode = {
        name = 'Player',
        desc = 'PlayerframeDesc',
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
                    local dbTable = Module.db.profile.playerSecondaryRes
                    local defaultsTable = self.Defaults
                    setPreset(dbTable, {
                        scale = defaultsTable.scale,
                        anchor = defaultsTable.anchor,
                        anchorParent = defaultsTable.anchorParent,
                        anchorFrame = defaultsTable.anchorFrame,
                        x = defaultsTable.x,
                        y = defaultsTable.y
                    })
                end,
                order = 16,
                editmode = true,
                new = false
            }
        }
    }

    self.Options = optionsPlayer;
    self.OptionsEditmode = optionsPlayerEditmode;
end

function SubModuleMixin:Setup()
    local function setDefaultSubValues(sub)
        self.ModuleRef:SetDefaultSubValues(sub)
    end

    DF.ConfigModule:RegisterSettingsData('playerSecondaryRes', 'unitframes', {
        options = self.Options,
        default = function()
            setDefaultSubValues('playerSecondaryRes')
        end
    })

    self:CreateSecondaryResFrame()
    self:HookSecondaryRes()

    self:SetScript('OnEvent', self.OnEvent);
    self:RegisterEvent('PLAYER_SPECIALIZATION_CHANGED')

    local EditModeModule = DF:GetModule('Editmode');
    local fakeWidget = self.PreviewFrame

    EditModeModule:AddEditModeToFrame(fakeWidget)

    fakeWidget.DFEditModeSelection:SetGetLabelTextFunction(function()
        return self.Options.name
    end)

    fakeWidget.DFEditModeSelection:RegisterOptions({
        options = self.Options,
        extra = self.OptionsEditmode,
        default = function()
            setDefaultSubValues('playerSecondaryRes')
        end,
        moduleRef = self.ModuleRef,
        showFunction = function()
        end,
        hideFunction = function()
            fakeWidget:Show()
        end
    });
end

function SubModuleMixin:OnEvent(event, ...)
    if event == 'PLAYER_SPECIALIZATION_CHANGED' then
        self:Update();
    end
end

function SubModuleMixin:UpdateState(state)
    self.state = state;
    self:Update();
end

function SubModuleMixin:Update()
    local state = self.state;
    if not state then return end

    local f = self.PreviewFrame
    if not f then return end

    local parent;
    if DF.Settings.ValidateFrame(state.customAnchorFrame) then
        parent = _G[state.customAnchorFrame]
    else
        parent = _G[state.anchorFrame]
    end

    if parent == PlayerFrame then
        f:SetParent(parent)
        f:SetScale(state.scale)

        if _G['PriestBarFrame'] then
            _G['PriestBarFrame']:SetIgnoreParentScale(false)
            _G['PriestBarFrame']:SetScale(1.0)
        end
    else
        f:SetParent(UIParent)
        f:SetScale(state.scale)

        if _G['PriestBarFrame'] then
            _G['PriestBarFrame']:SetIgnoreParentScale(true)
            _G['PriestBarFrame']:SetScale(UIParent:GetEffectiveScale() * state.scale)
        end
    end

    f:ClearAllPoints()
    f:SetPoint(state.anchor, parent, state.anchorParent, state.x, state.y)

    self:HideSecondaryRes(not state.activate)
end

function SubModuleMixin:CreateSecondaryResFrame()
    local fakeWidget = CreateFrame('Frame', 'DragonflightUIPlayerSecondaryRessourceFrame', UIParent)
    fakeWidget:SetSize(125, 40)
    fakeWidget.unit = 'player'
    self.PreviewFrame = fakeWidget

    if self.Adapter and self.Adapter.CreateFrames then
        self.Adapter:CreateFrames(self.PreviewFrame)
    end
end

function SubModuleMixin:HideSecondaryRes(hide)
    if self.Adapter and self.Adapter.HideSecondaryRes then
        self.Adapter:HideSecondaryRes(hide)
    end
end

function SubModuleMixin:HookSecondaryRes()
    if self.Adapter and self.Adapter.HookSecondaryRes then
        self.Adapter:HookSecondaryRes(self)
    end
end
