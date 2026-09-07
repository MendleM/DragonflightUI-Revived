local addonName, addonTable = ...;
local DF = addonTable.DF;
local L = addonTable.L;
local Helper = addonTable.Helper;

local subModuleName = 'TotemFrame';
local SubModuleMixin = {};
addonTable.SubModuleMixins[subModuleName] = SubModuleMixin;

-- TotemFrame.leftPadding is Blizzard's, and Blizzard reads it back, so it is never
-- written here.
--
-- Blizzard sets it in TotemFrame.xml as a KeyValue - leftPadding = 38 - which means the
-- XML parser wrote it, and the value is secure. Writing over it from addon code makes it
-- insecure, and Blizzard reads it back on every layout pass:
--
--     LayoutMixin:Layout()               LayoutFrame.lua:253
--       CalculateFrameSize()                          :257
--         GetPadding()                                :241
--           return (self.leftPadding or 0)            :209
--
-- and TotemFrameMixin:Update calls self:Layout() unconditionally at TotemFrame.lua:53.
-- From there Blizzard's own execution picks up our taint on every totem update, and
-- everything it writes after that read comes out insecure too. What it cost was
-- PlayerFrame.unit, written at UnitFrame.lua:178 by way of PlayerFrame.lua:193.
--
-- That variable is read by TargetOfTargetMixin:Update at TargetFrame.lua:947 - two lines
-- before the protected self:Show() at 949, fourteen before self:Hide() at 961. So
-- target-of-target and target-of-focus had both calls refused for the rest of the
-- session once combat started. Same files in 1.15.9, 2.5.6 and 5.5.4, byte for byte.
--
-- How this was pinned down, because none of it was apparent from reading the source:
--
--   Bisect. On 83493a8 issecurevariable(PlayerFrame, "unit") returns true and the frames
--   work; on 05ecd95 - the first code commit of PR #55 - it returns false with
--   DragonflightUI as the blame, and the frames are blocked. No pet, no totems placed.
--
--   Then a temporary switch turned each of that commit's three mechanisms off in turn.
--   Every one of them still read insecure, and only all three together read clean. The
--   reason is that leftPadding had two writers: the explicit assignments, and a
--   hooksecurefunc on TotemFrame's Update that put the field back to 0 whenever it found
--   38 there. Removing either left the other. Removing both, while still calling
--   Layout() ourselves, read clean and the frames stayed up in combat - so the field
--   write was the whole cause, and driving Layout() from here is harmless.
--
-- The blank offset those writes were meant to remove is real: 38 units of padding inside
-- the frame, which made sense while it hung in Blizzard's container below the player
-- frame and not after this module reparents it onto its own baseFrame. It is compensated
-- on our side now, by offsetting the anchor by Blizzard's own value. Reading a secure
-- value taints nothing, and the field stays Blizzard's.
local function PadOffset(totemFrame)
    return -(totemFrame.leftPadding or 0)
end

function SubModuleMixin:Init()
    self.ModuleRef = DF:GetModule('Unitframe')
    self:SetDefaults()
    self:SetupOptions()
    -- self:SetScript('OnEvent', self.OnEvent);
end
-- ]:SetPoint('TOPLEFT', PlayerFrame, 'BOTTOMLEFT', 99 + 3, 38 - 3)
function SubModuleMixin:SetDefaults()
    local defaults = {
        activate = true,
        scale = 1.0,
        anchorFrame = 'PlayerFrame',
        customAnchorFrame = '',
        anchor = 'TOPLEFT',
        anchorParent = 'BOTTOMLEFT',
        x = 99 + 3,
        y = 38 - 3
    };
    self.Defaults = defaults;
end

function SubModuleMixin:SetupOptions()
    local Module = self.ModuleRef;
    local function getDefaultStr(key, sub, extra)
        -- return Module:GetDefaultStr(key, sub)
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
            --
            T[k] = v;
        end
        Module:ApplySettings(sub)
        Module:RefreshOptionScreens()
    end

    local frameTable = {
        {value = 'UIParent', text = 'UIParent', tooltip = 'descr', label = 'label'},
        {value = 'PlayerFrame', text = 'PlayerFrame', tooltip = 'descr', label = 'label'}
    }

    local options = {
        name = L["PlayerTotemFrameName"],
        desc = L["PlayerTotemFrameNameDesc"],
        advancedName = 'PlayerTotemFrame',
        sub = 'playerTotemFrame',
        get = getOption,
        set = setOption,
        type = 'group',
        args = {
            activate = {
                type = 'toggle',
                name = L["ButtonTableActive"],
                desc = L["ButtonTableActiveDesc"] .. getDefaultStr('activate', 'playerTotemFrame'),
                order = -1,
                new = false,
                editmode = true
            }
        }
    }
    DF.Settings:AddPositionTable(Module, options, 'playerTotemFrame', 'playerTotemFrame', getDefaultStr, frameTable)

    local optionsEditmode = {
        name = L["PlayerTotemFrameName"],
        desc = L["PlayerTotemFrameNameDesc"],
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
                    local dbTable = Module.db.profile.playerTotemFrame
                    local defaultsTable = self.Defaults
                    -- {scale = 1.0, anchor = 'TOPLEFT', anchorParent = 'TOPLEFT', x = -19, y = -4}
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

    self.Options = options;
    self.OptionsEditmode = optionsEditmode;
end

function SubModuleMixin:Setup()
    if not _G['TotemFrame'] then return end
    local function setDefaultSubValues(sub)
        self.ModuleRef:SetDefaultSubValues(sub)
    end

    DF.ConfigModule:RegisterSettingsData('playerTotemFrame', 'unitframes', {
        options = self.Options,
        default = function()
            setDefaultSubValues('playerTotemFrame')
        end
    })
    --
    self:CreateBase()
    self:SkinTotems()

    -- 
    local f = self.BaseFrame

    -- state
    -- Mixin(f, DragonflightUIStateHandlerMixin)
    -- f:InitStateHandler()
    -- editmode

    local EditModeModule = DF:GetModule('Editmode');
    EditModeModule:AddEditModeToFrame(f)

    f.DFEditModeSelection:SetGetLabelTextFunction(function()
        return self.Options.name
    end)

    f.DFEditModeSelection:RegisterOptions({
        options = self.Options,
        extra = self.OptionsEditmode,
        default = function()
            setDefaultSubValues(self.Options.sub)
        end,
        moduleRef = self.ModuleRef,
        showFunction = function()
            f:Show()
        end,
        hideFunction = function()
            local totemFrame = _G['TotemFrame']
            if self.state and self.state.activate == false then
                f:Hide()
                if totemFrame then totemFrame:Hide() end
            else
                f:Show()
                if totemFrame then
                    totemFrame:Show()
                    if _G['TotemFrame_Update'] then
                        _G['TotemFrame_Update']()
                    elseif totemFrame.Update then
                        totemFrame:Update()
                    end
                end
            end
        end
    });
end

function SubModuleMixin:OnEvent(event, ...)
end

function SubModuleMixin:UpdateState(state)
    self.state = state;
    self:Update();
end

function SubModuleMixin:Update()
    local state = self.state;
    if not state then return end
    if not _G['TotemFrame'] then return end

    local parent;
    if DF.Settings.ValidateFrame(state.customAnchorFrame) then
        parent = _G[state.customAnchorFrame]
    else
        parent = _G[state.anchorFrame]
    end

    local f = self.BaseFrame
    if not f then return end

    local totemFrame = _G['TotemFrame']
    if state.activate == false then
        f:Hide()
        if totemFrame then totemFrame:Hide() end
    else
        f:Show()
        if totemFrame then
            totemFrame:Show()
            if _G['TotemFrame_Update'] then
                _G['TotemFrame_Update']()
            elseif totemFrame.Update then
                totemFrame:Update()
            end
            if totemFrame.Layout then
                totemFrame:Layout()
            end
        end
    end

    -- f:SetScale(state.scale)
    f:ClearAllPoints()
    f:SetPoint(state.anchor, parent, state.anchorParent, state.x, state.y)

    if parent == PlayerFrame then
        f:SetParent(parent)
        f:SetScale(state.scale)
    else
        f:SetParent(UIParent)
        -- f:SetScale(PlayerFrame:GetScale() * state.scale)
        f:SetScale(state.scale)
    end
end

function SubModuleMixin:CreateBase()
    local baseFrame = CreateFrame('Frame', 'DragonflightUIPlayerTotemFrame', UIParent);
    baseFrame:SetSize(128, 53);
    -- baseFrame:SetPoint('CENTER', UIParent, 'CENTER', 0, 0);
    baseFrame:SetClampedToScreen(true)
    -- baseFrame:Hide()
    self.BaseFrame = baseFrame;

    local totemFrame = _G['TotemFrame']
    if totemFrame then
        -- Detach from Blizzard's UIParentManagedFrameContainer:
        -- Blizzard's RemoveManagedFrame (UIParent.lua:214) checks `if not frame.IsInDefaultPosition then frame:ClearAllPoints() end`.
        -- Setting IsInDefaultPosition prevents Blizzard from wiping anchor points when totems expire.
        totemFrame.IsInDefaultPosition = function() return false end
        totemFrame.ignoreFramePositionManager = true
        totemFrame.ignoreInLayout = true

        if totemFrame.layoutParent and totemFrame.layoutParent.showingFrames then
            totemFrame.layoutParent.showingFrames[totemFrame] = nil
        end

        totemFrame:ClearAllPoints()
        totemFrame:SetPoint('TOPLEFT', baseFrame, 'TOPLEFT', PadOffset(totemFrame), 0)
        totemFrame:SetParent(baseFrame)

        hooksecurefunc(totemFrame, 'SetPoint', function(self)
            if self.DFSettingPoint then return end
            self.DFSettingPoint = true
            self:ClearAllPoints()
            self:SetPoint('TOPLEFT', baseFrame, 'TOPLEFT', PadOffset(self), 0)
            self.DFSettingPoint = nil
        end)

        totemFrame:HookScript('OnShow', function(self)
            if self:GetNumPoints() == 0 and baseFrame then
                self:SetPoint('TOPLEFT', baseFrame, 'TOPLEFT', PadOffset(self), 0)
            end
        end)
    end
end

local base = 'Interface\\Addons\\DragonflightUI\\Textures\\'

function SubModuleMixin:SkinTotems()
    for i = 1, 4 do
        local totem = _G['TotemFrameTotem' .. i];
        if not totem then return end

        local bg = _G['TotemFrameTotem' .. i .. 'Background'];
        if bg then
            bg:SetSize(31, 31)
            bg:SetTexture(base .. 'ui-minimap-background')
            bg:ClearAllPoints()
            bg:SetPoint("CENTER", totem, "CENTER")
        end

        local icon = totem.icon
        -- print(icon:GetSize())

        local children = {totem:GetChildren()}
        for j, child in ipairs(children) do
            -- print(j, child, child:GetObjectType())
            --            
            if child:GetObjectType() == 'Frame' and child ~= icon then
                --
                -- print('!')
                local childRegions = {child:GetRegions()}

                for k, v in ipairs(childRegions) do
                    if v:GetObjectType() == 'Texture' then
                        -- 
                        if v:GetDrawLayer() == 'OVERLAY' then
                            --
                            -- print(k, v, v:GetTexture())

                            v:SetSize(31, 31)
                            v:SetTexture(base .. 'minimap-trackingborder')
                            v:SetVertexColor(0.4, 0.4, 0.4) -- TODO
                            v:SetTexCoord(0 / 64, 38 / 64, 0 / 64, 38 / 64)
                            v:ClearAllPoints()
                            v:SetPoint("CENTER", totem, "CENTER")

                            if not totem.DFMask then
                                totem.DFMask = totem:CreateMaskTexture()
                                totem.DFMask:SetTexture(base .. 'tempportraitalphamask')
                                local delta = 0;
                                totem.DFMask:SetPoint('TOPLEFT', totem.icon, 'TOPLEFT', delta, -delta)
                                totem.DFMask:SetPoint('BOTTOMRIGHT', totem.icon, 'BOTTOMRIGHT', -delta, delta)
                                totem.icon.texture:AddMaskTexture(totem.DFMask)

                                totem.icon.cooldown:SetUseCircularEdge(true)
                            end
                        end
                    end
                end

            end
        end
    end
end
