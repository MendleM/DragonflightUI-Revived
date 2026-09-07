local addonName, addonTable = ...;
local DF = addonTable.DF;
local L = addonTable.L;
local Helper = addonTable.Helper;

local subModuleName = 'TotemFrame';
local SubModuleMixin = {};
addonTable.SubModuleMixins[subModuleName] = SubModuleMixin;

-- TEMPORARY. Bisects this file against the target-of-target combat block.
--
-- What is established: on 83493a8 (before PR #55) PlayerFrame.unit reads secure and
-- target-of-target works; on 05ecd95 (the leftPadding commit, first code change of
-- PR #55) PlayerFrame.unit reads insecure, TotemFrame.leftPadding reads insecure and
-- target-of-target is blocked in combat - with no pet and no totems placed. So the
-- seed is in this file, and it is in that commit's 14 lines.
--
-- What is NOT established is which of the three things that commit does builds the
-- bridge to PlayerFrame.unit. Reading Blizzard's source got as far as the write site
-- (UnitFrame.lua:178, reached from PlayerFrame.lua:193) but cannot name the read that
-- tainted the execution, and the guessed chain ran through PetFrameMixin:OnShow -
-- which never fires on a character with no pet. So it gets measured instead.
--
-- Switch with /df log totemprobe <n>, then /reload, then
-- /dump issecurevariable(PlayerFrame, "unit"). The variant that reports true is the
-- culprit.
--
--   0  everything on, current behaviour
--   1  no totemFrame:Layout() from our execution          (05ecd95)
--   2  no hooksecurefunc(totemFrame, 'Update', ...)       (05ecd95)
--   3  no totemFrame.leftPadding = 0                      (05ecd95)
--   4  none of 93fb3f3's writes: IsInDefaultPosition, ignoreInLayout,
--      showingFrames[totemFrame], the OnShow hook
--   5  all of the above plus ignoreFramePositionManager and the SetPoint hook
--      (both from PR #54). The control: if PlayerFrame.unit is still insecure at 5,
--      this file is not the source and the search starts over somewhere else.
--
-- Delete this and every Probe() call once the answer is in.
local function Probe(n)
    local v = tonumber(_G['DragonflightUITotemProbe'])
    if not v or v == 0 then return false end
    if v == 5 then return true end
    return v == n
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
            if not Probe(3) then totemFrame.leftPadding = 0 end
            totemFrame:Show()
            if _G['TotemFrame_Update'] then
                _G['TotemFrame_Update']()
            elseif totemFrame.Update then
                totemFrame:Update()
            end
            if not Probe(1) and totemFrame.Layout then
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
        if not Probe(4) then
            totemFrame.IsInDefaultPosition = function() return false end
            totemFrame.ignoreInLayout = true

            if totemFrame.layoutParent and totemFrame.layoutParent.showingFrames then
                totemFrame.layoutParent.showingFrames[totemFrame] = nil
            end
        end

        if not Probe(5) then totemFrame.ignoreFramePositionManager = true end
        if not Probe(3) then totemFrame.leftPadding = 0 end

        totemFrame:ClearAllPoints()
        totemFrame:SetPoint('TOPLEFT', baseFrame, 'TOPLEFT', 0, 0)
        totemFrame:SetParent(baseFrame)

        if not Probe(5) then
            hooksecurefunc(totemFrame, 'SetPoint', function(self)
                if self.DFSettingPoint then return end
                self.DFSettingPoint = true
                self:ClearAllPoints()
                self:SetPoint('TOPLEFT', baseFrame, 'TOPLEFT', 0, 0)
                self.DFSettingPoint = nil
            end)
        end

        if not Probe(4) then
            totemFrame:HookScript('OnShow', function(self)
                if self:GetNumPoints() == 0 and baseFrame then
                    self:SetPoint('TOPLEFT', baseFrame, 'TOPLEFT', 0, 0)
                end
            end)
        end

        if not Probe(2) and totemFrame.Update then
            hooksecurefunc(totemFrame, 'Update', function(self)
                if self.leftPadding and self.leftPadding ~= 0 then
                    self.leftPadding = 0
                    if self.Layout then self:Layout() end
                end
            end)
        end
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
