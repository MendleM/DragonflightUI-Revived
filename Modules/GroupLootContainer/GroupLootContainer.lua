local addonName, addonTable = ...;
local DF = addonTable.DF;
local L = addonTable.L;
local Helper = addonTable.Helper;

local mName = 'GroupLoot'
local Module = DF:NewModule(mName, 'AceConsole-3.0', 'AceHook-3.0')

Mixin(Module, DragonflightUIModulesMixin)

-- =========================================================================
-- Defaults
-- =========================================================================
local defaults = {
    profile = {
        scale = 1,
        general = {
            enabled = true,
            scale = 1,
            showTopRoll = true,
            showWinnerToast = true,
            showItemName = true,
            previewCount = 3,
            rollSpacing = 15,
            anchorFrame = 'UIParent',
            customAnchorFrame = '',
            anchor = 'BOTTOM',
            anchorParent = 'BOTTOM',
            x = 0,
            y = 300
        }
    }
}

-- =========================================================================
-- Helper closures
-- =========================================================================
local function getDefaultStr(key, sub, extra)
    local value = defaults.profile
    if sub and type(value) == 'table' then value = value[sub] end
    if type(value) == 'table' then value = value[key] end
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

-- =========================================================================
-- Options
-- =========================================================================
local frameTable = {
    {value = 'UIParent', text = 'UIParent', tooltip = 'descr', label = 'label'},
    {value = 'Minimap', text = 'Minimap', tooltip = 'descr', label = 'label'},
    {value = 'DragonflightUIMultiactionBar8VisParent', text = 'Action Bar 8', tooltip = 'descr', label = 'label'}
}

local rollOptions = {
    name = L["GroupLootContainerName"],
    desc = L["GroupLootContainerDesc"],
    advancedName = 'GroupLootContainer',
    sub = 'general',
    get = getOption,
    set = setOption,
    type = 'group',
    args = {}
}

-- Position table is added in OnInitialize after the DB is registered
-- (AddPositionTable reads Module.defaults which requires SetDefaults to have run).

rollOptions.args.enabled = {
    type = 'toggle',
    name = 'Enable Dragonflight loot rolls',
    desc = 'Restyle and reposition the group loot roll frames.'
        .. ' Turning this OFF requires a /reload to restore the classic look.'
        .. getDefaultStr('enabled', 'general'),
    order = 0.5
}
rollOptions.args.preview = {
    type = 'execute',
    name = 'Preview',
    btnName = 'Show',
    desc = 'Show a sample loot roll where yours will appear, for a few seconds.',
    func = function()
        Module:ShowPreview()
    end,
    order = 0.6
}
rollOptions.args.previewCount = {
    type = 'range',
    name = 'Preview rolls',
    desc = 'How many sample rolls the preview pops, so a whole drop can be judged'
        .. ' rather than a single item.' .. getDefaultStr('previewCount', 'general'),
    min = 1,
    max = 4,
    bigStep = 1,
    order = 0.65
}
rollOptions.args.rollSpacing = {
    type = 'range',
    name = 'Spacing between rolls',
    desc = 'Vertical gap between stacked roll frames when several items drop at once.'
        .. getDefaultStr('rollSpacing', 'general'),
    min = 0,
    max = 100,
    bigStep = 1,
    order = 0.75,
    editmode = true
}
rollOptions.args.scale = {
    type = 'range',
    name = 'Scale',
    desc = 'Size of the loot roll frames.' .. getDefaultStr('scale', 'general'),
    min = 0.5,
    max = 2,
    bigStep = 0.05,
    order = 0.7,
    editmode = true
}
rollOptions.args.showTopRoll = {
    type = 'toggle',
    name = 'Show current leading roll',
    desc = 'Show who is currently winning (or the live tally of choices while rolling)'
        .. ' in the corner of each roll frame.' .. getDefaultStr('showTopRoll', 'general'),
    order = 0.8
}
rollOptions.args.showWinnerToast = {
    type = 'toggle',
    name = 'Announce the winner',
    desc = 'Show a short panel naming the winner, their roll and the item once a roll resolves.'
        .. getDefaultStr('showWinnerToast', 'general'),
    order = 0.9
}
rollOptions.args.showItemName = {
    type = 'toggle',
    name = 'Show item name',
    desc = 'Show the item name on the roll frame.' .. getDefaultStr('showItemName', 'general'),
    order = 1.0
}

local rollOptionsEditmode = {
    name = 'general',
    desc = 'general',
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
                local dbTable = Module.db.profile.general
                local defaultsTable = defaults.profile.general
                setPreset(dbTable, {
                    scale = defaultsTable.scale,
                    anchor = defaultsTable.anchor,
                    anchorParent = defaultsTable.anchorParent,
                    anchorFrame = defaultsTable.anchorFrame,
                    x = defaultsTable.x,
                    y = defaultsTable.y
                }, 'general')
            end,
            order = 16,
            editmode = true,
            new = false
        }
    }
}

-- =========================================================================
-- Event handling: dedicated frame since the module is not a Frame
-- =========================================================================
local eventFrame = CreateFrame('Frame')
eventFrame:SetScript('OnEvent', function(_, event, ...)
    Module:OnEvent(event, ...)
end)

-- =========================================================================
-- Lifecycle
-- =========================================================================
function Module:OnInitialize()
    DF:Debug(self, 'Module ' .. mName .. ' OnInitialize()')

    self:SetDefaults(defaults)
    self.db = DF.db:RegisterNamespace(mName, defaults)

    self:MigrateSavedVariables()

    hooksecurefunc(DF:GetModule('Config'), 'AddConfigFrame', function()
        Module:RegisterSettings()
    end)

    self:SetEnabledState(DF.ConfigModule:GetModuleEnabled(mName))

    DF.Settings:AddPositionTable(Module, rollOptions, 'general', 'GroupLootContainer', getDefaultStr, frameTable)

    DF:RegisterModuleOptions(mName, rollOptions)
end

function Module:OnEnable()
    DF:Debug(self, 'Module ' .. mName .. ' OnEnable()')
    self:SetWasEnabled(true)

    self:EnableAddonSpecific()

    self:InitGroupLoot()

    Module:AddEditMode()
    Module:ApplySettings()
    Module:RegisterOptionScreens()

    self:SecureHook(DF, 'RefreshConfig', function()
        Module:ApplySettings()
        Module:RefreshOptionScreens()
    end)
end

function Module:OnDisable()
end

-- =========================================================================
-- Saved Variables Migration
-- =========================================================================
function Module:MigrateSavedVariables()
    local ok, uiNs = pcall(DF.db.GetNamespace, DF.db, 'UI')
    if not ok or not uiNs then return end

    local oldRoll = uiNs.profile and uiNs.profile.roll
    if not oldRoll or type(oldRoll) ~= 'table' then return end

    local cur = self.db.profile.general
    if cur and cur.enabled ~= defaults.profile.general.enabled then return end

    for k, v in pairs(oldRoll) do
        cur[k] = v
    end
end

-- =========================================================================
-- Settings registration
-- =========================================================================
function Module:RegisterSettings()
    local moduleName = mName
    local cat = 'misc'
    local function register(name, data)
        data.module = moduleName;
        DF.ConfigModule:RegisterSettingsElement(name, cat, data, true)
    end

    register('roll', {order = 18, name = rollOptions.name, descr = 'desc', isNew = true})
end

function Module:RegisterOptionScreens()
    DF.ConfigModule:RegisterSettingsData('roll', 'misc', {
        options = rollOptions,
        default = function()
            setDefaultSubValues('general')
        end
    })
end

function Module:RefreshOptionScreens()
    local configFrame = DF.ConfigModule.ConfigFrame
    configFrame:RefreshCatSub('Misc', 'roll')

    self.PreviewRoll.DFEditModeSelection:RefreshOptionScreen();
end

-- =========================================================================
-- ApplySettings
-- =========================================================================
function Module:ApplySettings(sub, key)
    Helper:Benchmark(string.format('ApplySettings(%s,%s)', tostring(sub), tostring(key)), function()
        Module:ApplySettingsInternal(sub, key)
    end, 0, self)
end

function Module:ApplySettingsInternal(sub, key)
    self:UpdateState(self.db.profile)
end

-- =========================================================================
-- Edit Mode
-- =========================================================================
function Module:AddEditMode()
    local EditModeModule = DF:GetModule('Editmode');

    local RETAIL = {
        borderWidth = 286,
        borderHeight = 76
    }

    local fakeRoll = self.PreviewRoll

    EditModeModule:AddEditModeToFrame(fakeRoll)

    fakeRoll.DFEditModeSelection:SetGetLabelTextFunction(function()
        return rollOptions.name
    end)

    fakeRoll.DFEditModeSelection:RegisterOptions({
        options = rollOptions,
        extra = rollOptionsEditmode,
        default = function()
            setDefaultSubValues('general')
        end,
        moduleRef = self,
        previewOnly = true,
        showFunction = function()
            fakeRoll.FakePreview:Show()
        end,
        hideFunction = function()
            fakeRoll.FakePreview:Hide()
        end
    });
end

-- =========================================================================
-- Group Loot Container: event handling, roll frames, preview, winner toast
-- =========================================================================

-- All of the following is the core logic previously in SubModuleMixin,
-- adapted to work with self.db.profile.general instead of the UI module's
-- db.profile.roll.

function Module:CreateRollPreview()
    local RETAIL = {borderWidth = 286, borderHeight = 76}

    local fakeRoll = CreateFrame('Frame', 'DragonflightUIEditModeGroupLootContainerPreview', UIParent)
    fakeRoll:SetSize(RETAIL.borderWidth, RETAIL.borderHeight)
    self.PreviewRoll = fakeRoll

    local fakePreview = CreateFrame('Frame', 'DragonflightUIEditModeGroupLootContainerFakeLootPreview', fakeRoll,
                                    'DFEditModePreviewGroupLootTemplate')
    fakePreview:SetPoint('CENTER')
    self:PrepPreviewFrame(fakePreview)
    fakePreview.DFPreviewRolls = self:BuildPreviewRolls(1)
    local ok, err = pcall(self.UpdateGroupLootFrameStyle, self, fakePreview)
    if not ok then
        geterrorhandler()('DFUI loot roll preview restyle: ' .. tostring(err))
    end
    self.SetPreviewItem(fakePreview, self.PREVIEW_ITEMS[1])
    self:UpdateAllButtons(fakePreview)
    self:UpdateTopRoll(fakePreview)

    fakeRoll.FakePreview = fakePreview
end

function Module:InitGroupLoot()
    self:CreateRollPreview()

    eventFrame:RegisterEvent('PLAYER_ENTERING_WORLD')
    eventFrame:RegisterEvent('START_LOOT_ROLL')
    eventFrame:RegisterEvent('LOOT_HISTORY_ROLL_CHANGED')
    eventFrame:RegisterEvent('LOOT_HISTORY_ROLL_COMPLETE')
    eventFrame:RegisterEvent('LOOT_ROLLS_COMPLETE')
end

function Module:OnEvent(event, ...)
    if event == 'PLAYER_ENTERING_WORLD' and self.ToastedRolls then
        wipe(self.ToastedRolls)
    end
    if not (self.state and self.state.general and self.state.general.enabled and self.Styled) then return end

    if event == 'LOOT_HISTORY_ROLL_COMPLETE' or event == 'LOOT_ROLLS_COMPLETE' then
        self:ScanForCompletedRolls()
    end

    for i = 1, 4 do
        local f = _G['GroupLootFrame' .. i];
        self:UpdateAllButtons(f);
        if f and f:IsShown() then
            self.ApplyDFBackdrop(f)
            self:UpdateTopRoll(f)
        end
        if f and not f.DFHideHooked then
            f.DFHideHooked = true
            f:HookScript('OnHide', function()
                for _, delay in ipairs({0.3, 1.0, 2.5}) do
                    C_Timer.After(delay, function() self:ScanForCompletedRolls() end)
                end
            end)
        end
    end
end

function Module:UpdateState(state)
    self.state = state;
    self:Update();
end

function Module:GetReservedSize()
    local state = self.state or defaults.profile
    local general = state.general or defaults.profile.general
    local gap = general.rollSpacing
    if type(gap) ~= 'number' then gap = defaults.profile.general.rollSpacing end
    local RETAIL_HEIGHT = 67
    return RETAIL_HEIGHT + math.max(0, math.min(150, gap))
end

function Module:Update()
    local state = self.state;
    if not state then return end

    local general = state.general or state

    if not general.enabled then
        if self.Styled and not self.DisabledNotePrinted then
            self.DisabledNotePrinted = true
            DF:Print('Dragonflight loot rolls disabled - /reload to restore the classic frames.')
        end
        return
    end
    self.DisabledNotePrinted = nil
    if not self.Styled then
        self.Styled = true
        self:StyleRollFrames()
    end

    local parent;
    if DF.Settings.ValidateFrame(general.customAnchorFrame) then
        parent = _G[general.customAnchorFrame]
    else
        parent = _G[general.anchorFrame]
    end

    local preview = self.PreviewRoll;
    preview:ClearAllPoints()
    preview:SetPoint(general.anchor, parent, general.anchorParent, general.x, general.y)
    local scale = general.scale or 1
    preview:SetScale(scale)

    local f = _G['GroupLootContainer']
    f.ignoreFramePositionManager = true;
    f:SetScale(scale)
    f:ClearAllPoints()
    f:SetPoint('BOTTOM', preview, 'BOTTOM', 0, 0)

    f.reservedSize = self:GetReservedSize()
    if GroupLootContainer_Update then pcall(GroupLootContainer_Update, f) end

    for i = 1, 4 do
        local roll = _G['GroupLootFrame' .. i]
        if roll then
            if roll.DFTopRoll and not general.showTopRoll then
                roll.DFTopRoll:SetText('')
                if roll.DFTopRollIcon then roll.DFTopRollIcon:Hide() end
            end
            if roll.Name then roll.Name:SetShown(general.showItemName ~= false) end
        end
    end
    if not general.showWinnerToast and self.WinnerToast then self.WinnerToast:Hide() end
end

-- =========================================================================
-- Preview, Buttons, TopRoll, WinnerToast, Styling
-- (All SubModuleMixin logic, adapted for self.state.general)
-- =========================================================================

-- Preview items and rollers (same as mixin)
Module.PREVIEW_ITEMS = {19019, 19431, 22691, 12640, 13262, 7075, 4306}

Module.PREVIEW_ROLLERS = {
    {name = 'Aldwin', class = 'PALADIN'}, {name = 'Brynja', class = 'SHAMAN'},
    {name = 'Corvin', class = 'ROGUE'}, {name = 'Dhalia', class = 'DRUID'},
    {name = 'Ereth', class = 'MAGE'}, {name = 'Faldric', class = 'WARRIOR'},
    {name = 'Gwenna', class = 'PRIEST'}, {name = 'Hakkon', class = 'HUNTER'}
}

Module.PREVIEW_SPLIT = {{2, 3, 1, 2}, {1, 2, 3, 0}, {3, 1, 2, 1}, {0, 4, 2, 1}}

function Module:BuildPreviewRolls(index)
    local split = self.PREVIEW_SPLIT[((index - 1) % #self.PREVIEW_SPLIT) + 1]
    local rolls = {need = {}, greed = {}, pass = {}, diss = {}, none = {}}
    local order = {rolls.need, rolls.greed, rolls.pass, rolls.none}

    local dealt = 1
    for bucket, count in ipairs(split) do
        for _ = 1, count do
            local roller = self.PREVIEW_ROLLERS[((dealt - 1) % #self.PREVIEW_ROLLERS) + 1]
            table.insert(order[bucket], {name = roller.name, class = roller.class, id = dealt})
            dealt = dealt + 1
        end
    end

    return rolls
end

local function HasRollData(f) return (f ~= nil) and (f.rollID ~= nil or f.DFPreviewRolls ~= nil) end

function Module:GetSettingsPreview()
    if self.SettingsPreview then return self.SettingsPreview end

    local RETAIL = {borderWidth = 286, borderHeight = 76}
    local holder = CreateFrame('Frame', 'DragonflightUIGroupLootSettingsPreview', UIParent)
    holder:SetSize(RETAIL.borderWidth, RETAIL.borderHeight)
    holder:SetFrameStrata('FULLSCREEN_DIALOG')
    holder:Hide()
    holder.Rolls = {}

    self.SettingsPreview = holder
    return holder
end

function Module:GetPreviewRoll(index)
    local holder = self:GetSettingsPreview()
    if holder.Rolls[index] then return holder.Rolls[index] end

    local roll = CreateFrame('Frame', 'DragonflightUIGroupLootSettingsPreviewRoll' .. index, holder,
                             'DFEditModePreviewGroupLootTemplate')
    self:PrepPreviewFrame(roll)

    roll.DFPreviewRolls = self:BuildPreviewRolls(index)

    local ok, err = pcall(self.UpdateGroupLootFrameStyle, self, roll)
    if not ok then geterrorhandler()('DFUI loot roll preview restyle: ' .. tostring(err)) end

    holder.Rolls[index] = roll
    if index == 1 then holder.FakePreview = roll end
    return roll
end

function Module:PrepPreviewFrame(fake)
    if not fake or fake.DFPreviewPrepared then return end
    fake.DFPreviewPrepared = true

    if fake.SetBackdrop then
        fake:SetBackdrop(nil)
        fake.SetBackdrop = function() end
    end

    self.StripBorrowedArt(fake)
    for _, region in ipairs({fake:GetRegions()}) do
        if region.GetObjectType and region:GetObjectType() == 'Texture' then
            region.Show = function() end
            region.SetTexture = function() end
        end
    end

    fake:SetScript('OnShow', nil)
    fake.SetNewItem = function(frame, id) self.SetPreviewItem(frame, id) end
    fake.TimerValue = fake.TimerValue or 0
end

function Module.SetPreviewItem(fake, itemID)
    local item = Item:CreateFromItemID(itemID or 19019)

    item:ContinueOnItemLoad(function()
        local quality = item:GetItemQuality()
        fake.DFPreviewQuality = quality

        if fake.Name then fake.Name:SetText(item:GetItemName()) end
        if fake.IconFrame then
            if fake.IconFrame.Icon then fake.IconFrame.Icon:SetTexture(item:GetItemIcon()) end
            if fake.IconFrame.Count then fake.IconFrame.Count:Hide() end
        end

        Module.ApplyQuality(fake, quality)
    end)
end

function Module:ShowPreview(seconds)
    local holder = self:GetSettingsPreview()
    local state = self.db.profile
    local general = state.general

    local parent
    if DF.Settings.ValidateFrame(general.customAnchorFrame) then
        parent = _G[general.customAnchorFrame]
    else
        parent = _G[general.anchorFrame]
    end
    if not parent then parent = UIParent end

    holder:ClearAllPoints()
    holder:SetPoint(general.anchor or 'BOTTOM', parent, general.anchorParent or 'BOTTOM', general.x or 0, general.y or 200)
    holder:SetScale(general.scale or 1)
    holder:SetAlpha(1)
    holder:Show()

    local count = math.floor(math.max(1, math.min(4, general.previewCount or 3)))
    local reserved = self:GetReservedSize()
    local first

    for i = 1, 4 do
        local roll = (i <= count) and self:GetPreviewRoll(i) or holder.Rolls[i]
        if roll and i <= count then
            roll:ClearAllPoints()
            roll:SetPoint('CENTER', holder, 'BOTTOM', 0, reserved * (i - 0.5))
            self.SetPreviewItem(roll, self.PREVIEW_ITEMS[fastrandom(1, #self.PREVIEW_ITEMS)])
            self:UpdateAllButtons(roll)
            self:UpdateTopRoll(roll)
            roll:SetAlpha(1)
            roll:Show()
            first = first or roll
        elseif roll then
            roll:Hide()
        end
    end

    self.PreviewDuration = seconds or 6
    self:RestartPreviewTimer()
end

function Module:RestartPreviewTimer()
    local holder = self.SettingsPreview
    if not holder then return end

    if self.PreviewTimer then self.PreviewTimer:Cancel() end
    self.PreviewTimer = C_Timer.NewTimer(self.PreviewDuration or 6, function() holder:Hide() end)
end

function Module:UpdateTopRoll(f)
    local topRoll, rollIcon = f.DFTopRoll, f.DFTopRollIcon
    if not (topRoll and HasRollData(f)) then return end
    local state = self.state or defaults.profile.general
    local general = state.general or state
    if general and not general.showTopRoll then
        topRoll:SetText('')
        if rollIcon then rollIcon:Hide() end
        return
    end

    if f.rollID and C_LootHistory and C_LootHistory.GetNumItems then
        local itemIdx = self.FindItemIdxForRoll(f.rollID)
        if itemIdx then
            local _, _, _, isDone, winnerIdx = C_LootHistory.GetItem(itemIdx)
            if isDone and winnerIdx then
                local name, class, rollType, roll = C_LootHistory.GetPlayerInfo(itemIdx, winnerIdx)
                if name then
                    if class then name = DF:GetClassColoredText(name, class) end
                    if roll then
                        topRoll:SetFormattedText('%s (%d)', name, roll)
                    else
                        topRoll:SetText(name)
                    end
                    if self.ApplyRollTypeIcon(rollIcon, rollType) then
                        rollIcon:Show()
                    else
                        rollIcon:Hide()
                    end
                    return
                end
            end
        end
    end

    if rollIcon then rollIcon:Hide() end
    local _, _, _, _, tableNone = self:GetRollTables(f)
    if tableNone and #tableNone > 0 then
        topRoll:SetFormattedText('|cff999999%d left|r', #tableNone)
    else
        topRoll:SetText('')
    end
end

function Module:QueueWinnerToast(rollID)
    local state = self.state or defaults.profile.general
    local general = state.general or state
    if general and not general.showWinnerToast then return end
    self.ToastQueue = self.ToastQueue or {}
    table.insert(self.ToastQueue, rollID)
    self:DrainToastQueue()
end

function Module:DrainToastQueue()
    if self.ToastBusy then return end
    local rollID = self.ToastQueue and table.remove(self.ToastQueue, 1)
    if not rollID then return end
    self.ToastBusy = true
    C_Timer.After(4.5, function()
        self.ToastBusy = false
        self:DrainToastQueue()
    end)
    local itemIdx = self.FindItemIdxForRoll(rollID)
    if itemIdx then self:ShowWinnerToast(itemIdx) end
end

function Module:ShowWinnerToast(itemIdx)
    local rollID, itemLink, numPlayers, isDone, winnerIdx = C_LootHistory.GetItem(itemIdx)
    if not (isDone and winnerIdx) then return end
    local name, class, rollType, roll = C_LootHistory.GetPlayerInfo(itemIdx, winnerIdx)
    if not name then return end

    local toast = self.WinnerToast
    if not toast then
        toast = CreateFrame('Frame', 'DragonflightUILootWinnerToast', UIParent, 'BackdropTemplate')
        toast:SetSize(272, 30)
        toast:SetFrameStrata('DIALOG')
        self.ApplyDFBackdrop(toast)
        local text = toast:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
        text:SetPoint('CENTER')
        text:SetWidth(260)
        toast.Text = text
        toast:Hide()
        self.WinnerToast = toast
    end
    toast:ClearAllPoints()
    toast:SetPoint('BOTTOM', self.PreviewRoll, 'BOTTOM', 0, -34)

    local coloredName = class and DF:GetClassColoredText(name, class) or name
    local typeTag = self.ROLL_TYPE_INLINE[rollType] and (' ' .. self.ROLL_TYPE_INLINE[rollType]) or ''
    local rollTag = roll and (' (' .. roll .. ')') or ''
    toast.Text:SetFormattedText('%s%s%s  %s', coloredName, typeTag, rollTag, itemLink or '')
    toast:SetAlpha(1)
    toast:Show()

    if self.WinnerToastTimer then self.WinnerToastTimer:Cancel() end
    self.WinnerToastTimer = C_Timer.NewTimer(4, function()
        if UIFrameFadeOut then
            UIFrameFadeOut(toast, 0.5, 1, 0)
            C_Timer.After(0.5, function() toast:Hide() end)
        else
            toast:Hide()
        end
    end)
end

function Module:ScanForCompletedRolls()
    if not (C_LootHistory and C_LootHistory.GetNumItems) then return end
    self.ToastedRolls = self.ToastedRolls or {}
    for i = 1, C_LootHistory.GetNumItems() do
        local rollID, _, _, isDone, winnerIdx = C_LootHistory.GetItem(i)
        if rollID and isDone and winnerIdx and not self.ToastedRolls[rollID] then
            self.ToastedRolls[rollID] = true
            self:QueueWinnerToast(rollID)
        end
    end
end

-- Roll type icons for leading-roll and winner toast
local ROLL_ART_PATH = 'Interface\\Addons\\DragonflightUI\\Textures\\uilootroll'
Module.ROLL_TYPE_ICON = {
    [1] = ROLL_ART_PATH,
    [2] = ROLL_ART_PATH,
    [3] = ROLL_ART_PATH
}
Module.ROLL_TYPE_COORDS = {
    [1] = {65 / 512, 97 / 512, 237 / 512, 269 / 512},
    [2] = {1 / 512, 33 / 512, 431 / 512, 463 / 512},
    [3] = {1 / 512, 33 / 512, 329 / 512, 361 / 512}
}
Module.ROLL_TYPE_INLINE = {
    [1] = '|T' .. ROLL_ART_PATH .. ':11:11:0:0:512:512:65:97:237:269|t',
    [2] = '|T' .. ROLL_ART_PATH .. ':11:11:0:0:512:512:1:33:431:463|t',
    [3] = '|T' .. ROLL_ART_PATH .. ':11:11:0:0:512:512:1:33:329:361|t'
}

function Module.ApplyRollTypeIcon(texture, rollType)
    local path = Module.ROLL_TYPE_ICON[rollType]
    if not (texture and path) then return false end
    texture:SetTexture(path)
    local c = Module.ROLL_TYPE_COORDS[rollType]
    if c then texture:SetTexCoord(c[1], c[2], c[3], c[4]) end
    return true
end

function Module.FindItemIdxForRoll(rollID)
    if not (rollID and C_LootHistory and C_LootHistory.GetNumItems) then return nil end
    for i = 1, C_LootHistory.GetNumItems() do
        if C_LootHistory.GetItem(i) == rollID then return i end
    end
    return nil
end

-- =========================================================================
-- Button and Roll Tables
-- =========================================================================

local function SetButtonCount(btn, t)
    local fs = btn and btn.DFText
    if not fs then return end
    fs:SetText(t and tostring(#t) or '*')
end

function Module:UpdateAllButtons(f)
    if not HasRollData(f) then return end

    local tableNeed, tableGreed, tablePass, tableDiss, tableNone, tableData = self:GetRollTables(f)

    SetButtonCount(f.NeedButton, tableNeed)
    SetButtonCount(f.GreedButton, tableGreed)
    SetButtonCount(f.PassButton, tablePass)

    if tableData then
        local link = tableData[2]
        local quality
        if link then quality = select(3, C_Item.GetItemInfo(link)) end
        self.ApplyQuality(f, quality)
    end
end

function Module:CreateTableForRollID(rollID)
    local numPlayers;
    local itemIDx = 1;
    local tableData = {}
    while true do
        local rID, _, num, _, _, _ = C_LootHistory.GetItem(itemIDx)
        if not rID then
            return nil;
        elseif rID == rollID then
            numPlayers = num;
            tableData = {C_LootHistory.GetItem(itemIDx)}
            break
        end
        itemIDx = itemIDx + 1;
    end

    local tableNeed = {}
    local tableGreed = {}
    local tablePass = {}
    local tableDiss = {}
    local tableNone = {}

    for i = 1, numPlayers do
        local name, class, rollType, roll, isWinner, isMe = C_LootHistory.GetPlayerInfo(itemIDx, i)
        local data = {name = name, class = class, id = i};

        if rollType ~= nil then
            if rollType == 0 then
                table.insert(tablePass, data)
            elseif rollType == 1 then
                table.insert(tableNeed, data)
            elseif rollType == 2 then
                table.insert(tableGreed, data)
            elseif rollType == 3 then
                table.insert(tableDiss, data)
            end
        else
            table.insert(tableNone, data)
        end
    end

    return tableNeed, tableGreed, tablePass, tableDiss, tableNone, tableData;
end

function Module:GetRollTables(f)
    if not f then return nil end

    local preview = f.DFPreviewRolls
    if preview then return preview.need, preview.greed, preview.pass, preview.diss, preview.none end

    if not (f.rollID and C_LootHistory and C_LootHistory.GetNumItems) then return nil end
    return self:CreateTableForRollID(f.rollID)
end

local function AddRollLines(t)
    if #t < 1 then return end
    for k, v in ipairs(t) do
        local str = DF:GetClassColoredText(v.name, v.class) or '???'
        GameTooltip:AddLine(string.format(' %s', str))
    end
end

local ROLL_TYPE_LABEL = {[0] = PASS, [1] = NEED, [2] = GREED, [3] = ROLL_DISENCHANT}

function Module:AddTooltipLines(f, btnType, showAll)
    local tableNeed, tableGreed, tablePass, tableDiss, tableNone = self:GetRollTables(f:GetParent())
    if not tableNeed then return end

    GameTooltip:AddLine('    ')

    if #tableNeed ~= 0 and (showAll or btnType == 1) then
        GameTooltip:AddLine(NEED)
        AddRollLines(tableNeed)
    end

    if #tableGreed ~= 0 and (showAll or btnType == 2) then
        GameTooltip:AddLine(GREED)
        AddRollLines(tableGreed)
    end

    if #tableDiss ~= 0 and (showAll or btnType == 3) then
        GameTooltip:AddLine(ROLL_DISENCHANT)
        AddRollLines(tableDiss)
    end

    if #tablePass ~= 0 and (showAll or btnType == 0) then
        GameTooltip:AddLine(PASS)
        AddRollLines(tablePass)
    end

    if tableNone and #tableNone > 0 then
        GameTooltip:AddLine('Undecided')
        AddRollLines(tableNone)
    end

    GameTooltip:Show()
end

function Module:WireRollButton(btn, rollType)
    if not btn then return end
    local module = self

    if not btn.DFText then
        local fontFile = GameFontHighlight:GetFont()
        local text = btn:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
        text:SetFont(fontFile, 13, 'OUTLINE')
        btn.DFText = text
    end
    btn.DFText:ClearAllPoints()
    btn.DFText:SetPoint('BOTTOMRIGHT', btn, 'BOTTOMRIGHT', -1, 1)

    if btn.DFTooltipWired then return end
    btn.DFTooltipWired = true

    if btn.SetMotionScriptsWhileDisabled then btn:SetMotionScriptsWhileDisabled(true) end

    btn:SetScript('OnEnter', function(button)
        GameTooltip:SetOwner(button, 'ANCHOR_RIGHT')
        GameTooltip:SetText(ROLL_TYPE_LABEL[rollType] or '')
        if button.IsEnabled and not button:IsEnabled() and button.reason then
            GameTooltip:AddLine(button.reason, RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b, true)
        end
        module:AddTooltipLines(button, rollType, false)
        GameTooltip:Show()

        local parent = button.GetParent and button:GetParent()
        if parent and parent.DFPreviewRolls then module:RestartPreviewTimer() end
    end)
    btn:SetScript('OnLeave', function() GameTooltip:Hide() end)
end

-- =========================================================================
-- Styling
-- =========================================================================

local LOOT_TOAST = 'Interface\\LootFrame\\LootToast'
local RETAIL = {
    width = 277,
    height = 67,
    bgCoords = {0.28222656, 0.55273438, 0.30859375, 0.57031250},
    borderCoords = {0.00097656, 0.28027344, 0.43750000, 0.73437500},
    borderWidth = 286,
    borderHeight = 76,
    iconSize = 34,
    iconX = 10,
    iconY = -13,
    iconBorderSize = 42,
    nameWidth = 125,
    nameHeight = 30,
    nameX = 60,
    nameY = -9,
    buttonSize = 32,
    needX = -44,
    needY = -6,
    passX = 6,
    passY = 2,
    greedY = 5,
    timerWidth = 190,
    timerHeight = 8,
    timerX = 3,
    timerY = 2,
    reservedSize = 100
}

local ROLL_ART = 'Interface\\Addons\\DragonflightUI\\Textures\\uilootroll'
local function coords(l, t) return {l / 512, (l + 32) / 512, t / 512, (t + 32) / 512} end
local MODERN_ICONS = {
    need = {
        atlas = 'lootroll-toast-icon-need',
        up = coords(65, 237),
        down = coords(1, 465),
        highlight = coords(65, 203)
    },
    greed = {
        atlas = 'lootroll-toast-icon-greed',
        up = coords(1, 431),
        down = coords(1, 363),
        highlight = coords(1, 397)
    },
    pass = {
        atlas = 'lootroll-toast-icon-pass',
        up = coords(65, 339),
        down = coords(65, 271),
        highlight = coords(65, 305)
    },
    disenchant = {
        atlas = 'lootroll-toast-icon-disenchant',
        up = coords(1, 329),
        down = coords(1, 261),
        highlight = coords(1, 295)
    }
}

local function AtlasExists(name)
    return C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(name) ~= nil
end

local function QualityBorderAtlas(quality)
    local byQuality = _G['LOOT_BORDER_BY_QUALITY']
    local atlas = byQuality and quality and byQuality[quality]
    if atlas then return atlas, false end
    return 'loottoast-itemborder-gold', true
end

local function QualityColor(quality)
    return quality and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality]
end

local function ApplyRollButtonArt(btn, key)
    local art = MODERN_ICONS[key]
    if not (btn and art) then return end

    local disabled = btn.GetDisabledTexture and btn:GetDisabledTexture()
    if disabled then
        disabled:SetTexture(nil)
        disabled:Hide()
    end

    local useAtlas = art.atlas and btn.SetNormalAtlas and AtlasExists(art.atlas .. '-up')

    if useAtlas then
        btn:SetNormalAtlas(art.atlas .. '-up')
        btn:SetPushedAtlas(art.atlas .. '-down')
        btn:SetHighlightAtlas(art.atlas .. '-highlight')
    else
        btn:SetNormalTexture(ROLL_ART)
        btn:SetPushedTexture(ROLL_ART)
        btn:SetHighlightTexture(ROLL_ART)

        local normal, pushed, highlight = btn:GetNormalTexture(), btn:GetPushedTexture(), btn:GetHighlightTexture()
        if normal then normal:SetTexCoord(art.up[1], art.up[2], art.up[3], art.up[4]) end
        if pushed then pushed:SetTexCoord(art.down[1], art.down[2], art.down[3], art.down[4]) end
        if highlight then highlight:SetTexCoord(art.highlight[1], art.highlight[2], art.highlight[3], art.highlight[4]) end
    end

    local highlight = btn:GetHighlightTexture()
    if highlight then highlight:SetBlendMode('ADD') end

    for _, tex in ipairs({btn:GetNormalTexture(), btn:GetPushedTexture(), btn:GetHighlightTexture()}) do
        if tex then
            tex:ClearAllPoints()
            tex:SetAllPoints(btn)
        end
    end
end

function Module.StripBorrowedArt(frame)
    if not frame.GetRegions then return end

    local ours = {}
    if frame.DFRetailBackground then ours[frame.DFRetailBackground] = true end
    if frame.DFRetailBorder then ours[frame.DFRetailBorder] = true end
    if frame.DFTopRollIcon then ours[frame.DFTopRollIcon] = true end

    for _, region in ipairs({frame:GetRegions()}) do
        if region and not ours[region] and region.GetObjectType and region:GetObjectType() == 'Texture' then
            if region.SetTexture then region:SetTexture('') end
            region:Hide()
        end
    end
end

function Module.ApplyDFBackdrop(frame)
    if frame.SetBackdrop then frame:SetBackdrop(nil) end

    local quality
    if frame.rollID and GetLootRollItemInfo then
        local _, _, _, q = GetLootRollItemInfo(frame.rollID)
        quality = q
    end
    quality = quality or frame.DFPreviewQuality

    Module.ApplyQuality(frame, quality)

    Module.StripBorrowedArt(frame)
end

function Module.ApplyQuality(frame, quality)
    local color = QualityColor(quality)

    if frame.DFRetailBorder then
        if color then
            frame.DFRetailBorder:SetVertexColor(color.r, color.g, color.b)
        else
            frame.DFRetailBorder:SetVertexColor(1, 1, 1)
        end
    end

    local iconFrame = frame.IconFrame
    if iconFrame and iconFrame.DFQualityBorder then
        local atlas, desaturate = QualityBorderAtlas(quality)
        iconFrame.DFQualityBorder:SetAtlas(atlas)
        iconFrame.DFQualityBorder:SetDesaturated(desaturate)
        iconFrame.DFQualityBorder:SetSize(RETAIL.iconBorderSize, RETAIL.iconBorderSize)
    end

    if frame.Name and color then frame.Name:SetVertexColor(color.r, color.g, color.b) end
end

function Module:StyleRollFrames()
    if _G['GroupLootContainer'] then _G['GroupLootContainer'].reservedSize = self:GetReservedSize() end

    for i = 1, 4 do
        local f = _G['GroupLootFrame' .. i]
        local ok, err = pcall(self.UpdateGroupLootFrameStyle, self, f)
        if not ok then
            geterrorhandler()('DFUI loot roll restyle: ' .. tostring(err))
        end
        f:HookScript('OnShow', Module.ApplyDFBackdrop)
        f:SetScript('OnEnter', function()
        end)
    end
end

function Module:UpdateGroupLootFrameStyle(f)
    if not f then return end

    f:SetSize(RETAIL.width, RETAIL.height)
    if f.SetBackdrop then f:SetBackdrop(nil) end

    Module.StripBorrowedArt(f)

    if not f.DFRetailBackground then
        local bg = f:CreateTexture(nil, 'BACKGROUND')
        f.DFRetailBackground = bg
    end
    f.DFRetailBackground:SetTexture(LOOT_TOAST)
    f.DFRetailBackground:SetTexCoord(unpack(RETAIL.bgCoords))
    f.DFRetailBackground:ClearAllPoints()
    f.DFRetailBackground:SetAllPoints(f)
    f.DFRetailBackground:Show()

    if not f.DFRetailBorder then
        local border = f:CreateTexture(nil, 'BORDER')
        f.DFRetailBorder = border
    end
    f.DFRetailBorder:SetTexture(LOOT_TOAST)
    f.DFRetailBorder:SetTexCoord(unpack(RETAIL.borderCoords))
    f.DFRetailBorder:SetSize(RETAIL.borderWidth, RETAIL.borderHeight)
    f.DFRetailBorder:ClearAllPoints()
    f.DFRetailBorder:SetPoint('CENTER')
    f.DFRetailBorder:Show()

    local iconFrame = f.IconFrame
    if iconFrame then
        iconFrame:SetSize(RETAIL.iconSize, RETAIL.iconSize)
        iconFrame:ClearAllPoints()
        iconFrame:SetPoint('TOPLEFT', f, 'TOPLEFT', RETAIL.iconX, RETAIL.iconY)

        local icon = iconFrame.Icon
        if icon then
            icon:SetSize(RETAIL.iconSize, RETAIL.iconSize)
            icon:ClearAllPoints()
            icon:SetPoint('TOPLEFT')
            if iconFrame.DFMask and icon.RemoveMaskTexture then
                icon:RemoveMaskTexture(iconFrame.DFMask)
                iconFrame.DFMask:Hide()
            end
        end

        if iconFrame.DFQuality then iconFrame.DFQuality:Hide() end

        if not iconFrame.DFQualityBorder then
            local border = iconFrame:CreateTexture(nil, 'OVERLAY')
            border:SetPoint('CENTER')
            iconFrame.DFQualityBorder = border
        end
        iconFrame.DFQualityBorder:SetSize(RETAIL.iconBorderSize, RETAIL.iconBorderSize)
        iconFrame.DFQualityBorder:Show()
    end

    local name = f.Name
    if name then
        name:SetSize(RETAIL.nameWidth, RETAIL.nameHeight)
        name:ClearAllPoints()
        name:SetPoint('TOPLEFT', f, 'TOPLEFT', RETAIL.nameX, RETAIL.nameY)
        if GameFontNormal then name:SetFontObject(GameFontNormal) end
        name:SetJustifyH('LEFT')
        name:SetJustifyV('MIDDLE')
        name:SetWordWrap(false)
        name:SetMaxLines(1)
    end

    do
        local size = RETAIL.buttonSize

        local need = f.NeedButton
        if need then
            need:SetSize(size, size)
            need:ClearAllPoints()
            need:SetPoint('TOPRIGHT', f, 'TOPRIGHT', RETAIL.needX, RETAIL.needY)
            ApplyRollButtonArt(need, 'need')
            self:WireRollButton(need, 1)
        end

        local pass = f.PassButton
        if pass then
            pass:SetSize(size, size)
            pass:ClearAllPoints()
            if need then
                pass:SetPoint('LEFT', need, 'RIGHT', RETAIL.passX, RETAIL.passY)
            else
                pass:SetPoint('TOPRIGHT', f, 'TOPRIGHT', -6, -6)
            end
            ApplyRollButtonArt(pass, 'pass')
            self:WireRollButton(pass, 0)
        end

        local greed = f.GreedButton
        if greed then
            greed:SetSize(size, size)
            greed:ClearAllPoints()
            if need then
                greed:SetPoint('TOP', need, 'BOTTOM', 0, RETAIL.greedY)
            else
                greed:SetPoint('BOTTOMRIGHT', f, 'BOTTOMRIGHT', RETAIL.needX, 6)
            end
            ApplyRollButtonArt(greed, 'greed')
            self:WireRollButton(greed, 2)
        end

        local diss = f.DisenchantButton
        if diss then
            diss:SetSize(size, size)
            if greed then
                diss:ClearAllPoints()
                diss:SetPoint('CENTER', greed, 'CENTER', 0, 0)
            end
            ApplyRollButtonArt(diss, 'disenchant')
            self:WireRollButton(diss, 3)
        end
    end

    local timer = f.Timer
    if timer then
        timer:ClearAllPoints()
        timer:SetPoint('BOTTOMLEFT', f, 'BOTTOMLEFT', RETAIL.timerX, RETAIL.timerY)
        timer:SetSize(RETAIL.timerWidth, RETAIL.timerHeight)
        timer:SetStatusBarTexture('Interface\\PaperDollInfoFrame\\UI-Character-Skills-Bar')
        timer:SetStatusBarColor(1, 1, 0)

        local bg = timer.Background
        if not bg then
            bg = timer:CreateTexture(nil, 'BACKGROUND')
            timer.Background = bg
        end
        bg:SetTexture(nil)
        bg:SetColorTexture(0, 0, 0, 1)
        bg:ClearAllPoints()
        bg:SetAllPoints(timer)

        local fill = timer:GetStatusBarTexture()
        if fill then fill:SetDrawLayer('ARTWORK') end
        for _, region in ipairs({timer:GetRegions()}) do
            if region ~= fill and region ~= bg and region.SetTexture then
                region:SetTexture(nil)
                region:Hide()
            end
        end
        if timer.DFBorder then timer.DFBorder:Hide() end

        local level = f:GetFrameLevel() or 1
        if level > 0 then timer:SetFrameLevel(level - 1) end
    end

    if not f.DFTopRoll then
        local topRoll = f:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
        topRoll:SetJustifyH('LEFT')
        f.DFTopRoll = topRoll

        local rollIcon = f:CreateTexture(nil, 'OVERLAY')
        rollIcon:SetSize(11, 11)
        f.DFTopRollIcon = rollIcon
    end
    f.DFTopRoll:ClearAllPoints()
    f.DFTopRoll:SetPoint('BOTTOMLEFT', f, 'BOTTOMLEFT', RETAIL.nameX, RETAIL.timerY + RETAIL.timerHeight + 16)
    f.DFTopRollIcon:ClearAllPoints()
    f.DFTopRollIcon:SetPoint('RIGHT', f.DFTopRoll, 'LEFT', -2, 0)
    f.DFTopRoll:SetText('')
    f.DFTopRollIcon:Hide()

    Module.ApplyDFBackdrop(f)

    if f:IsShown() then
        f:Hide()
        f:Show()
    end
end

function Module:SetupOptions()
    -- Options are built at file scope and position table added in OnInitialize.
    -- This stub satisfies any code path that calls self:SetupOptions().
end
