local addonName, addonTable = ...;
local DF = addonTable.DF;
local L = addonTable.L;
local Helper = addonTable.Helper;

local subModuleName = 'GroupLootContainer';
local SubModuleMixin = {};
addonTable.SubModuleMixins[subModuleName] = SubModuleMixin;

-- Retail's group loot roll frame, reproduced on the classic one.
--
-- Every number below comes from Blizzard's own GroupLootFrameTemplate in
-- retail (Blizzard_UIPanels_Game/Mainline/GroupLootFrame.xml): a 277x67
-- frame on the LootToast panel with a 286x76 border tinted by item quality,
-- a 34px icon at 10,-13 inside a 42px quality border, the item name at
-- 60,-15 in GameFontNormal tinted by quality, 32px roll buttons anchored
-- from the top right, and a 190x8 timer along the bottom over black.
--
-- None of that art needs shipping: 1.15.9 has the LootToast sheet and the
-- loottoast-itemborder atlas members already (its own alert frames use
-- them), so this is retail's actual art rather than an imitation of it. The
-- classic frame's own regions - the empty slot, the label plate, the gold
-- dragon, the corner, the chunky timer border - are cleared out of the way.
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
    nameY = -15,
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
    -- retail reserves this much vertical space per roll in the container
    reservedSize = 100
}

-- retail's per-quality icon border; the classic client ships the same atlas
-- members, and falls back to the gold one desaturated for junk/common
local function QualityBorderAtlas(quality)
    local byQuality = _G['LOOT_BORDER_BY_QUALITY']
    local atlas = byQuality and quality and byQuality[quality]
    if atlas then return atlas, false end
    return 'loottoast-itemborder-gold', true
end

local function QualityColor(quality)
    return quality and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality]
end

-- Retail draws the roll buttons from the lootroll atlas. Where the client
-- knows those atlas members natively we use them (correct resolution, no
-- shipped art); otherwise we fall back to the sheet we ship, addressed by
-- the same texel coordinates the atlas uses.
local ROLL_ART = 'Interface\\Addons\\DragonflightUI\\Textures\\uilootroll'
local function coords(l, t) return l / 512, (l + 32) / 512, t / 512, (t + 32) / 512 end
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

-- items the preview cycles through, spread across qualities so the quality
-- borders and name colour can be judged
local PREVIEW_ITEMS = {19019, 19431, 22691, 12640, 13262, 7075, 4306}

local function ApplyRollButtonArt(btn, key)
    local art = MODERN_ICONS[key]
    if not (btn and art) then return end

    -- the classic pass button is a UIPanelCloseButton; its inherited art has
    -- to go, disabled state included, or it shows through
    if btn.SetDisabledTexture then btn:SetDisabledTexture(nil) end

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


function SubModuleMixin:Init()
    self.ModuleRef = DF:GetModule('UI')

    self:SetDefaults()
    self:SetupOptions()
end

function SubModuleMixin:SetDefaults()
    local defaults = {
        enabled = true,
        scale = 1,
        showTopRoll = true,
        showWinnerToast = true,
        showItemName = true,
        anchorFrame = 'UIParent',
        customAnchorFrame = '',
        anchor = 'BOTTOM',
        anchorParent = 'BOTTOM',
        x = 425, -- 0
        y = 200 -- 152 = default blizz
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
        {value = 'Minimap', text = 'Minimap', tooltip = 'descr', label = 'label'}
    }

    local rollOptions = {
        name = L["GroupLootContainerName"],
        desc = L["GroupLootContainerDesc"],
        advancedName = 'GroupLootContainer',
        sub = 'roll',
        get = getOption,
        set = setOption,
        type = 'group',
        args = {}
    }
    DF.Settings:AddPositionTable(Module, rollOptions, 'roll', 'GroupLootContainer', getDefaultStr, frameTable)
    -- DragonflightUIStateHandlerMixin:AddStateTable(Module, rollOptions, 'possess', 'PossessBar', getDefaultStr)
    rollOptions.args.enabled = {
        type = 'toggle',
        name = 'Enable Dragonflight loot rolls',
        desc = 'Restyle and reposition the group loot roll frames.'
            .. ' Turning this OFF requires a /reload to restore the classic look.'
            .. getDefaultStr('enabled', 'roll'),
        order = 0.5
    }
    rollOptions.args.preview = {
        type = 'execute',
        name = 'Preview',
        btnName = 'Show',
        desc = 'Show a sample loot roll where yours will appear, for a few seconds.',
        func = function()
            -- logged on the button side as well as inside ShowPreview: a
            -- missing entry here means the click never reached the option
            DF:Log('rollpreview', 'Show button clicked')
            local ok, err = pcall(function() self:ShowPreview() end)
            if not ok then DF:Log('rollpreview', 'ShowPreview ERROR: %s', tostring(err)) end
        end,
        order = 0.6
    }
    rollOptions.args.scale = {
        type = 'range',
        name = 'Scale',
        desc = 'Size of the loot roll frames.' .. getDefaultStr('scale', 'roll'),
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
            .. ' in the corner of each roll frame.' .. getDefaultStr('showTopRoll', 'roll'),
        order = 0.8
    }
    rollOptions.args.showWinnerToast = {
        type = 'toggle',
        name = 'Announce the winner',
        desc = 'Show a short panel naming the winner, their roll and the item once a roll resolves.'
            .. getDefaultStr('showWinnerToast', 'roll'),
        order = 0.9
    }
    rollOptions.args.showItemName = {
        type = 'toggle',
        name = 'Show item name',
        desc = 'Show the item name on the roll frame.' .. getDefaultStr('showItemName', 'roll'),
        order = 1.0
    }
    local rollOptionsEditmode = {
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
                    local dbTable = Module.db.profile.roll
                    local defaultsTable = self.Defaults
                    -- {scale = 1.0, anchor = 'TOPLEFT', anchorParent = 'TOPLEFT', x = -19, y = -4}
                    setPreset(dbTable, {
                        scale = defaultsTable.scale,
                        anchor = defaultsTable.anchor,
                        anchorParent = defaultsTable.anchorParent,
                        anchorFrame = defaultsTable.anchorFrame,
                        x = defaultsTable.x,
                        y = defaultsTable.y
                    }, 'roll')
                end,
                order = 16,
                editmode = true,
                new = false
            }
        }
    }

    self.Options = rollOptions;
    self.OptionsEditmode = rollOptionsEditmode;
end

function SubModuleMixin:Setup()
    local function setDefaultSubValues(sub)
        self.ModuleRef:SetDefaultSubValues(sub)
    end

    DF.ConfigModule:RegisterSettingsData('roll', 'misc', {
        options = self.Options,
        default = function()
            setDefaultSubValues('roll')
        end
    })

    self:CreateRollPreview()

    self:SetScript('OnEvent', self.OnEvent);
    self:RegisterEvent('PLAYER_ENTERING_WORLD')
    self:RegisterEvent('START_LOOT_ROLL')
    self:RegisterEvent('LOOT_HISTORY_ROLL_CHANGED')
    self:RegisterEvent('LOOT_HISTORY_ROLL_COMPLETE')
    self:RegisterEvent('LOOT_ROLLS_COMPLETE')

    -- editmode 
    local EditModeModule = DF:GetModule('Editmode');

    local fakeRoll = self.PreviewRoll

    EditModeModule:AddEditModeToFrame(fakeRoll)

    fakeRoll.DFEditModeSelection:SetGetLabelTextFunction(function()
        return self.Options.name
    end)

    fakeRoll.DFEditModeSelection:RegisterOptions({
        options = self.Options,
        extra = self.OptionsEditmode,
        default = function()
            setDefaultSubValues('roll')
        end,
        moduleRef = self.ModuleRef,
        -- fakeRoll only holds the dummy roll shown while positioning; the real
        -- rolls live on GroupLootContainer, which is anchored to it but not
        -- parented to it.
        previewOnly = true,
        showFunction = function()
            --
            fakeRoll.FakePreview:Show()
        end,
        hideFunction = function()
            --
            fakeRoll.FakePreview:Hide()
        end
    });
end

-- Roll-type icons for the leading-roll line and the winner toast. Retail's
-- lootroll atlas (shipped as uilootroll) instead of the classic dice/coin.
local ROLL_ART_PATH = 'Interface\\Addons\\DragonflightUI\\Textures\\uilootroll'
local ROLL_TYPE_ICON = {
    [1] = ROLL_ART_PATH, -- need
    [2] = ROLL_ART_PATH, -- greed
    [3] = ROLL_ART_PATH -- disenchant
}
-- 32px 'up' state per roll type, as texcoords on the 512x512 sheet
local ROLL_TYPE_COORDS = {
    [1] = {65 / 512, 97 / 512, 237 / 512, 269 / 512}, -- need
    [2] = {1 / 512, 33 / 512, 431 / 512, 463 / 512}, -- greed
    [3] = {1 / 512, 33 / 512, 329 / 512, 361 / 512} -- disenchant
}

-- Inline form for chat-style strings: an atlas sheet needs explicit texel
-- coords (|Tpath:h:w:xOff:yOff:sheetW:sheetH:l:r:t:b|t) or the whole
-- 512x512 sheet gets squashed into the icon.
local ROLL_TYPE_INLINE = {
    [1] = '|T' .. ROLL_ART_PATH .. ':11:11:0:0:512:512:65:97:237:269|t',
    [2] = '|T' .. ROLL_ART_PATH .. ':11:11:0:0:512:512:1:33:431:463|t',
    [3] = '|T' .. ROLL_ART_PATH .. ':11:11:0:0:512:512:1:33:329:361|t'
}

local function ApplyRollTypeIcon(texture, rollType)
    local path = ROLL_TYPE_ICON[rollType]
    if not (texture and path) then return false end
    texture:SetTexture(path)
    local c = ROLL_TYPE_COORDS[rollType]
    if c then texture:SetTexCoord(c[1], c[2], c[3], c[4]) end
    return true
end

local function FindItemIdxForRoll(rollID)
    if not (rollID and C_LootHistory and C_LootHistory.GetNumItems) then return nil end
    for i = 1, C_LootHistory.GetNumItems() do
        if C_LootHistory.GetItem(i) == rollID then return i end
    end
    return nil
end

-- Corner display. Roll numbers reveal INCREMENTALLY while the roll runs,
-- so a self-computed "leader" regularly disagrees with the server's final
-- winner. Only the server's winnerIdx is authoritative: show it once the
-- roll is done; until then show the live choice tally.
function SubModuleMixin:UpdateTopRoll(f)
    local topRoll, rollIcon = f.DFTopRoll, f.DFTopRollIcon
    if not (topRoll and f.rollID and C_LootHistory and C_LootHistory.GetNumItems) then return end
    if self.state and not self.state.showTopRoll then
        topRoll:SetText('')
        if rollIcon then rollIcon:Hide() end
        return
    end

    local itemIdx = FindItemIdxForRoll(f.rollID)
    if itemIdx then
        local _, _, _, isDone, winnerIdx = C_LootHistory.GetItem(itemIdx)
        if isDone and winnerIdx then
            local name, class, rollType, roll = C_LootHistory.GetPlayerInfo(itemIdx, winnerIdx)
            if name then
                local color = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
                if color and color.colorStr then name = '|c' .. color.colorStr .. name .. '|r' end
                if roll then
                    topRoll:SetFormattedText('%s (%d)', name, roll)
                else
                    topRoll:SetText(name)
                end
                if ApplyRollTypeIcon(rollIcon, rollType) then
                    rollIcon:Show()
                else
                    rollIcon:Hide()
                end
                return
            end
        end
    end

    -- live tally of choices + players still deciding
    rollIcon:Hide()
    local tableNeed, tableGreed, tablePass, tableDiss, tableNone = self:CreateTableForRollID(f.rollID)
    local parts = {}
    local function addPart(icon, t)
        if t and #t > 0 then parts[#parts + 1] = ('|T%s:11:11|t%d'):format(icon, #t) end
    end
    addPart('Interface\\Buttons\\UI-GroupLoot-Dice-Up', tableNeed)
    addPart('Interface\\Buttons\\UI-GroupLoot-Coin-Up', tableGreed)
    addPart('Interface\\Buttons\\UI-GroupLoot-Pass-Up', tablePass)
    if tableNone and #tableNone > 0 then
        parts[#parts + 1] = ('|cff999999%d left|r'):format(#tableNone)
    end
    topRoll:SetText(table.concat(parts, '  '))
end

-- Winner toast: the roll frame disappears exactly when the result exists,
-- so announce the resolution in a short-lived DF panel where the rolls
-- stack. Queued per rollID: simultaneous completions display one after
-- another instead of overwriting, and the history index is resolved at
-- display time (indices shift as the history grows).
function SubModuleMixin:QueueWinnerToast(rollID)
    if self.state and not self.state.showWinnerToast then return end
    self.ToastQueue = self.ToastQueue or {}
    table.insert(self.ToastQueue, rollID)
    self:DrainToastQueue()
end

function SubModuleMixin:DrainToastQueue()
    if self.ToastBusy then return end
    local rollID = self.ToastQueue and table.remove(self.ToastQueue, 1)
    if not rollID then return end
    self.ToastBusy = true
    C_Timer.After(4.5, function()
        self.ToastBusy = false
        self:DrainToastQueue()
    end)
    local itemIdx = FindItemIdxForRoll(rollID)
    if itemIdx then self:ShowWinnerToast(itemIdx) end
end

function SubModuleMixin:ShowWinnerToast(itemIdx)
    local rollID, itemLink, numPlayers, isDone, winnerIdx = C_LootHistory.GetItem(itemIdx)
    if not (isDone and winnerIdx) then return end
    local name, class, rollType, roll = C_LootHistory.GetPlayerInfo(itemIdx, winnerIdx)
    if not name then return end

    local toast = self.WinnerToast
    if not toast then
        toast = CreateFrame('Frame', 'DragonflightUILootWinnerToast', UIParent, 'BackdropTemplate')
        toast:SetSize(272, 30)
        toast:SetFrameStrata('DIALOG')
        SubModuleMixin.ApplyDFBackdrop(toast)
        local text = toast:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
        text:SetPoint('CENTER')
        text:SetWidth(260)
        toast.Text = text
        toast:Hide()
        self.WinnerToast = toast
    end
    toast:ClearAllPoints()
    toast:SetPoint('BOTTOM', self.PreviewRoll, 'BOTTOM', 0, -34)

    local color = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
    local coloredName = (color and color.colorStr) and ('|c' .. color.colorStr .. name .. '|r') or name
    local typeTag = ROLL_TYPE_INLINE[rollType] and (' ' .. ROLL_TYPE_INLINE[rollType]) or ''
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

-- Toast every completed roll exactly once. Called from the loot events AND
-- retried after roll frames hide: the history entry can finalize a moment
-- after the completion event, and a single missed tick used to mean no
-- winner was ever shown.
function SubModuleMixin:ScanForCompletedRolls()
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

function SubModuleMixin:OnEvent(event, ...)
    -- print(event, ...)
    if event == 'PLAYER_ENTERING_WORLD' and self.ToastedRolls then
        -- rollIDs can restart across sessions/instances; a stale dedupe
        -- entry would silently suppress a legitimate toast
        wipe(self.ToastedRolls)
    end
    if not (self.state and self.state.enabled and self.Styled) then return end

    if event == 'LOOT_HISTORY_ROLL_COMPLETE' or event == 'LOOT_ROLLS_COMPLETE' then
        self:ScanForCompletedRolls()
    end

    for i = 1, 4 do
        local f = _G['GroupLootFrame' .. i];
        self:UpdateAllButtons(f);
        -- rollID may land after OnShow; re-tint the quality border once
        -- the roll data is definitely there.
        if f and f:IsShown() then
            SubModuleMixin.ApplyDFBackdrop(f)
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

function SubModuleMixin:UpdateState(state)
    self.state = state;
    self:Update();
end

function SubModuleMixin:Update()
    local state = self.state;
    if not state then return end

    if not state.enabled then
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
    if DF.Settings.ValidateFrame(state.customAnchorFrame) then
        parent = _G[state.customAnchorFrame]
    else
        parent = _G[state.anchorFrame]
    end

    local preview = self.PreviewRoll;
    preview:ClearAllPoints()
    preview:SetPoint(state.anchor, parent, state.anchorParent, state.x, state.y)
    local scale = state.scale or 1
    preview:SetScale(scale)

    local f = _G['GroupLootContainer']
    f.ignoreFramePositionManager = true;
    f:SetScale(scale)
    f:ClearAllPoints()
    f:SetPoint('BOTTOM', preview, 'BOTTOM', 0, 0)

    -- toggled pieces on the live frames
    for i = 1, 4 do
        local roll = _G['GroupLootFrame' .. i]
        if roll then
            if roll.DFTopRoll and not state.showTopRoll then
                roll.DFTopRoll:SetText('')
                if roll.DFTopRollIcon then roll.DFTopRollIcon:Hide() end
            end
            if roll.Name then roll.Name:SetShown(state.showItemName ~= false) end
        end
    end
    if not state.showWinnerToast and self.WinnerToast then self.WinnerToast:Hide() end
end

-- The settings-page preview owns its own frame instead of borrowing the
-- edit-mode one. PreviewRoll belongs to the edit-mode selection: it is
-- anchored only by Update() (which returns early while the feature is off),
-- and the selection's OnEditMode handler hides it on every broadcast. Sharing
-- it made a button press depend on state the button does not control.
function SubModuleMixin:GetSettingsPreview()
    if self.SettingsPreview then return self.SettingsPreview end

    local holder = CreateFrame('Frame', 'DragonflightUIGroupLootSettingsPreview', UIParent)
    holder:SetSize(RETAIL.borderWidth, RETAIL.borderHeight)
    -- the settings window is HIGH + toplevel, so anything below TOOLTIP can
    -- end up behind it depending on where the rolls are configured to sit
    holder:SetFrameStrata('TOOLTIP')
    holder:Hide()

    local fake = CreateFrame('Frame', 'DragonflightUIGroupLootSettingsPreviewRoll', holder,
                             'DFEditModePreviewGroupLootTemplate')
    fake:SetPoint('CENTER')
    DF:Log('rollpreview', 'created preview frames, template applied=%s', tostring(fake.IconFrame ~= nil))

    self:PrepPreviewFrame(fake)

    local ok, err = pcall(function() self:UpdateGroupLootFrameStyle(fake) end)
    if not ok then DF:Log('rollpreview', 'style ERROR: %s', tostring(err)) end

    holder.FakePreview = fake
    self.SettingsPreview = holder
    return holder
end

-- The preview template comes with a mixin that picks a random item AND
-- re-applies the classic gold dialog backdrop, gold dragon and corner from an
-- item-load callback. That callback lands after our restyle and undoes it,
-- which is why the preview came out looking like a classic roll wearing half
-- of ours. Take the item handling over and shut the classic art out for good:
-- these frames are ours, and nothing else draws them.
function SubModuleMixin:PrepPreviewFrame(fake)
    if not fake or fake.DFPreviewPrepared then return end
    fake.DFPreviewPrepared = true

    if fake.SetBackdrop then
        fake:SetBackdrop(nil)
        fake.SetBackdrop = function() end
    end

    local name = fake.GetName and fake:GetName()
    if name then
        for _, suffix in ipairs({'Corner', 'Decoration', 'SlotTexture', 'NameFrame'}) do
            local region = _G[name .. suffix]
            if region then
                region:SetTexture('')
                region:Hide()
                -- the same callback re-textures and re-shows these
                region.Show = function() end
                region.SetTexture = function() end
            end
        end
    end

    -- no random re-roll on show; we choose what the preview displays
    fake:SetScript('OnShow', nil)
    fake.SetNewItem = function(frame, id) SubModuleMixin.SetPreviewItem(frame, id) end
    -- the template's OnUpdate animates the timer bar and needs this seeded
    fake.TimerValue = fake.TimerValue or 0
end

-- Fills a preview frame the way retail fills a real roll: icon, name in the
-- item's quality colour, quality-tinted borders.
function SubModuleMixin.SetPreviewItem(fake, itemID)
    local item = Item:CreateFromItemID(itemID or 19019)

    item:ContinueOnItemLoad(function()
        local quality = item:GetItemQuality()
        fake.DFPreviewQuality = quality

        if fake.Name then fake.Name:SetText(item:GetItemName()) end
        if fake.IconFrame then
            if fake.IconFrame.Icon then fake.IconFrame.Icon:SetTexture(item:GetItemIcon()) end
            if fake.IconFrame.Count then fake.IconFrame.Count:Hide() end
        end

        SubModuleMixin.ApplyQuality(fake, quality)
    end)
end

-- Shows a sample roll where the real ones will appear, so the settings page
-- can be judged without waiting for a group loot roll.
function SubModuleMixin:ShowPreview(seconds)
    DF:Log('rollpreview', 'ShowPreview() entered')

    local holder = self:GetSettingsPreview()
    local fake = holder.FakePreview
    local state = self.state or self.Defaults
    DF:Log('rollpreview', 'state source=%s anchor=%s/%s frame=%s x=%s y=%s scale=%s',
           self.state and 'profile' or 'defaults', tostring(state.anchor), tostring(state.anchorParent),
           tostring(state.anchorFrame), tostring(state.x), tostring(state.y), tostring(state.scale))

    local parent
    if DF.Settings.ValidateFrame(state.customAnchorFrame) then
        parent = _G[state.customAnchorFrame]
    else
        parent = _G[state.anchorFrame]
    end
    if not parent then parent = UIParent end

    holder:ClearAllPoints()
    holder:SetPoint(state.anchor or 'BOTTOM', parent, state.anchorParent or 'BOTTOM', state.x or 0, state.y or 200)
    holder:SetScale(state.scale or 1)
    holder:SetAlpha(1)
    holder:Show()

    -- a fresh item each time, so the quality art can be seen doing its job
    SubModuleMixin.SetPreviewItem(fake, PREVIEW_ITEMS[fastrandom(1, #PREVIEW_ITEMS)])

    fake:SetAlpha(1)
    fake:Show()

    -- Say where it went. A preview that lands off-screen or behind another
    -- frame is indistinguishable from a button that does nothing.
    DF:Print(('loot roll preview: %s at %d,%d (%dx%d) - /df log rollpreview for details'):format(
                 fake:IsVisible() and 'shown' or 'NOT VISIBLE', (holder:GetLeft() or -1), (holder:GetBottom() or -1),
                 (fake:GetWidth() or 0), (fake:GetHeight() or 0)))

    DF:LogFrame(holder, 'rollpreview')
    DF:LogFrame(fake, 'rollpreview')

    if self.PreviewTimer then self.PreviewTimer:Cancel() end
    self.PreviewTimer = C_Timer.NewTimer(seconds or 6, function()
        DF:Log('rollpreview', 'preview timer expired, hiding (still visible=%s)', tostring(fake:IsVisible()))
        holder:Hide()
    end)
end

function SubModuleMixin:CreateRollPreview()
    local fakeRoll = CreateFrame('Frame', 'DragonflightUIEditModeGroupLootContainerPreview', UIParent)
    -- match the frame it stands in for, so the edit-mode box is the real size
    fakeRoll:SetSize(RETAIL.borderWidth, RETAIL.borderHeight)
    self.PreviewRoll = fakeRoll

    local fakePreview = CreateFrame('Frame', 'DragonflightUIEditModeGroupLootContainerFakeLootPreview', fakeRoll,
                                    'DFEditModePreviewGroupLootTemplate')
    fakePreview:SetPoint('CENTER')
    self:PrepPreviewFrame(fakePreview)
    self:UpdateGroupLootFrameStyle(fakePreview)
    SubModuleMixin.SetPreviewItem(fakePreview, PREVIEW_ITEMS[1])

    fakeRoll.FakePreview = fakePreview
end

-- Restyles the REAL roll frames - destructive, so it only runs once the
-- 'roll' state confirms the feature is enabled (see Update).
function SubModuleMixin:StyleRollFrames()
    -- Space per roll slot. Retail reserves 100 for a 67px frame, and the
    -- frames are now retail-sized, so keep its spacing too.
    if _G['GroupLootContainer'] then _G['GroupLootContainer'].reservedSize = RETAIL.reservedSize end

    for i = 1, 4 do
        local f = _G['GroupLootFrame' .. i]
        self:UpdateGroupLootFrameStyle(f);
        -- Blizzard's GroupLootFrame_OnShow re-applies the classic dialog
        -- backdrop on every popup; ours must win each time.
        f:HookScript('OnShow', SubModuleMixin.ApplyDFBackdrop)
        f:SetScript('OnEnter', function()
        end)
    end

    -- local tester = CreateFrame('Frame', 'tester', UIParent, 'DFEditModePreviewGroupLootTemplate')
    -- tester:SetPoint('CENTER', 400, 0)
    -- tester:Show()
    -- self:UpdateGroupLootFrameStyleSimple(tester)

    -- local norm = CreateFrame('Frame', 'normal', UIParent, 'DFEditModePreviewGroupLootTemplate')
    -- norm:SetPoint('BOTTOMLEFT', tester, 'TOPLEFT', 0, 10)
    -- norm:Show()
end

-- function SubModuleMixin:HookGroupLootFrame(f)
--     if not f then return end
--     -- print('HookGroupLootFrame', f:GetName())

--     local fontFile, height, flags = GameFontRedLarge:GetFont()
--     local newFontSize = 18;

--     local need = f.NeedButton
--     do
--         need:SetMotionScriptsWhileDisabled(true)
--         need:SetScript('OnEnter', function()
--             GameTooltip:SetOwner(need, "ANCHOR_RIGHT");
--             GameTooltip:SetText(need.tooltipText);
--             if (not need:IsEnabled()) then
--                 GameTooltip:AddLine(need.reason, RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b, true);
--                 GameTooltip:Show();
--             end
--             self:AddTooltipLines(need, 1, false)
--         end)

--         local text = need:CreateFontString(nil, 'OVERLAY', "GameFontRedLarge")
--         text:SetPoint('CENTER', need, 'CENTER', 0, 0)
--         text:SetFont(fontFile, newFontSize, flags)
--         need.DFText = text;
--     end

--     local greed = f.GreedButton
--     do
--         greed:SetMotionScriptsWhileDisabled(true)
--         greed:SetScript('OnEnter', function()
--             GameTooltip:SetOwner(greed, "ANCHOR_RIGHT");
--             GameTooltip:SetText(greed.tooltipText);
--             if (not greed:IsEnabled()) then
--                 GameTooltip:AddLine(greed.reason, RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b, true);
--                 GameTooltip:Show();
--             end
--             self:AddTooltipLines(greed, 2, false)
--         end)

--         local text = greed:CreateFontString(nil, 'OVERLAY', "GameFontRedLarge")
--         text:SetPoint('CENTER', greed, 'CENTER', 0, 2)
--         text:SetFont(fontFile, newFontSize, flags)
--         greed.DFText = text;
--     end
-- end

function SubModuleMixin:UpdateAllButtons(f)
    if not f then return end
    local rollID = f.rollID
    if not rollID then return end

    local tableNeed, tableGreed, tablePass, tableDiss, tableNone, tableData = self:CreateTableForRollID(rollID)

    local needText = f.NeedButton.DFText
    if needText then
        if tableNeed then
            needText:SetText(tostring(#tableNeed))
        else
            needText:SetText('*')
        end
    end

    local greedText = f.GreedButton.DFText
    if greedText then
        if tableGreed then
            greedText:SetText(tostring(#tableGreed))
        else
            greedText:SetText('*')
        end
    end

    local passText = f.PassButton.DFText
    if passText then
        if tableGreed then
            passText:SetText(tostring(#tablePass))
        else
            passText:SetText('*')
        end
    end

    if tableData then
        local link = tableData[2]
        local quality
        if link then quality = select(3, C_Item.GetItemInfo(link)) end
        -- retail signals quality with the loottoast border and the name
        -- colour, not with our icon overlay
        SubModuleMixin.ApplyQuality(f, quality)
    end
end

-- rollType    number - (0:pass, 1:need, 2:greed, 3:disenchant)

function SubModuleMixin:CreateTableForRollID(rollID)
    local numPlayers;
    local itemIDx = 1;
    local tableData = {}
    while true do
        -- rollID, itemLink, numPlayers, isDone, winnerIdx, isMasterLoot = C_LootHistory.GetItem(itemIdx)
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
        --
        local name, class, rollType, roll, isWinner, isMe = C_LootHistory.GetPlayerInfo(itemIDx, i)
        local data = {name = name, class = class, id = i};
        -- print(name, class, rollType)

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

    -- TODO: SORT

    return tableNeed, tableGreed, tablePass, tableDiss, tableNone, tableData;
end

local function AddRollLines(t)
    if #t < 1 then return end
    for k, v in ipairs(t) do
        --
        local str = DF:GetClassColoredText(v.name, v.class) or '???'
        GameTooltip:AddLine(string.format(' %s', str))
    end
end

function SubModuleMixin:AddTooltipLines(f, btnType, showAll)
    local rollID = f:GetParent().rollID
    if not rollID then return end

    local tableNeed, tableGreed, tablePass, tableDiss, tableNone = self:CreateTableForRollID(rollID)
    if not tableNeed then return end

    GameTooltip:AddLine('    ')

    if #tableNeed ~= 0 and (showAll or btnType == 1) then
        --
        GameTooltip:AddLine(NEED)
        AddRollLines(tableNeed)
    end

    if #tableGreed ~= 0 and (showAll or btnType == 2) then
        --
        GameTooltip:AddLine(GREED)
        AddRollLines(tableGreed)
    end

    if #tableDiss ~= 0 and (showAll or btnType == 3) then
        --
        GameTooltip:AddLine(ROLL_DISENCHANT)
        AddRollLines(tableDiss)
    end

    if #tablePass ~= 0 and (showAll or btnType == 0) then
        --
        GameTooltip:AddLine(PASS)
        AddRollLines(tablePass)
    end

    if showAll or true then
        --
        GameTooltip:AddLine('Undecided')
        AddRollLines(tableNone)
    end

    GameTooltip:Show()
end

-- era-1159: Blizzard's GroupLootFrame_OnShow re-applies the classic
-- dialog-box backdrop (gold for rare+) on EVERY popup, which kept the
-- rolls looking classic no matter the restyle. Swap it for the DF dark
-- panel and keep the quality signal on the border color.
-- The item-dependent half of the retail look: quality tints the frame
-- border, the icon border and the name, exactly as GroupLootFrame_OnShow
-- does. Blizzard re-applies the classic dialog backdrop on every popup, so
-- this runs from an OnShow hook as well as from the restyle.
function SubModuleMixin.ApplyDFBackdrop(frame)
    if frame.SetBackdrop then frame:SetBackdrop(nil) end

    local quality
    if frame.rollID and GetLootRollItemInfo then
        local _, _, _, q = GetLootRollItemInfo(frame.rollID)
        quality = q
    end
    quality = quality or frame.DFPreviewQuality

    SubModuleMixin.ApplyQuality(frame, quality)

    -- Blizzard's OnShow re-shows the gold dragon Decoration for BoP items
    -- and re-textures the Corner on every popup - keep them gone.
    local frameName = frame.GetName and frame:GetName()
    if frameName then
        for _, suffix in ipairs({'Corner', 'Decoration', 'SlotTexture', 'NameFrame'}) do
            local region = _G[frameName .. suffix]
            if region then
                if region.SetTexture then region:SetTexture('') end
                region:Hide()
            end
        end
    end
end

function SubModuleMixin.ApplyQuality(frame, quality)
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

function SubModuleMixin:UpdateGroupLootFrameStyle(f)
    if not f then return end

    f:SetSize(RETAIL.width, RETAIL.height)
    if f.SetBackdrop then f:SetBackdrop(nil) end

    -- classic art out of the way
    do
        local name = f.GetName and f:GetName()
        if name then
            for _, suffix in ipairs({'SlotTexture', 'NameFrame', 'Corner', 'Decoration'}) do
                local region = _G[name .. suffix]
                if region then
                    if region.SetTexture then region:SetTexture('') end
                    region:ClearAllPoints()
                    region:Hide()
                end
            end
        end
    end

    -- panel + quality-tinted border
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

    -- icon: square, no mask, inside retail's quality border
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
            -- an earlier build rounded the icon with a mask; retail's is square
            if iconFrame.DFMask and icon.RemoveMaskTexture then
                icon:RemoveMaskTexture(iconFrame.DFMask)
                iconFrame.DFMask:Hide()
            end
        end

        -- our own quality overlay is replaced by retail's border art
        if iconFrame.DFQuality then iconFrame.DFQuality:Hide() end

        if not iconFrame.DFQualityBorder then
            local border = iconFrame:CreateTexture(nil, 'OVERLAY')
            border:SetPoint('CENTER')
            iconFrame.DFQualityBorder = border
        end
        iconFrame.DFQualityBorder:SetSize(RETAIL.iconBorderSize, RETAIL.iconBorderSize)
        iconFrame.DFQualityBorder:Show()
    end

    -- name
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

    -- roll buttons, retail sizes and anchors
    do
        local size = RETAIL.buttonSize

        local need = f.NeedButton
        if need then
            need:SetSize(size, size)
            need:ClearAllPoints()
            need:SetPoint('TOPRIGHT', f, 'TOPRIGHT', RETAIL.needX, RETAIL.needY)
            ApplyRollButtonArt(need, 'need')
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
        end

        -- classic has no disenchant roll; era's frames carry the button on
        -- flavours that do
        local diss = f.DisenchantButton
        if diss then
            diss:SetSize(size, size)
            if greed then
                diss:ClearAllPoints()
                diss:SetPoint('CENTER', greed, 'CENTER', 0, 0)
            end
            ApplyRollButtonArt(diss, 'disenchant')
        end
    end

    -- timer: thin yellow bar over black along the bottom
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

        -- the classic bar ships border art anchored WIDER than the bar (that
        -- is what stuck out past the fill); strip everything but fill + track
        local fill = timer:GetStatusBarTexture()
        -- the classic template pushes the fill down to BACKGROUND, where it
        -- can end up under our own track
        if fill then fill:SetDrawLayer('ARTWORK') end
        for _, region in ipairs({timer:GetRegions()}) do
            if region ~= fill and region ~= bg and region.SetTexture then
                region:SetTexture(nil)
                region:Hide()
            end
        end
        if timer.DFBorder then timer.DFBorder:Hide() end

        -- retail keeps the timer a level below the frame it belongs to
        local level = f:GetFrameLevel() or 1
        if level > 0 then timer:SetFrameLevel(level - 1) end
    end

    -- DFUI extra: who is currently winning. Retail has nothing here, so it
    -- goes under the name where there is room, not over the buttons.
    if not f.DFTopRoll then
        local topRoll = f:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
        topRoll:SetJustifyH('LEFT')
        f.DFTopRoll = topRoll

        local rollIcon = f:CreateTexture(nil, 'OVERLAY')
        rollIcon:SetSize(11, 11)
        f.DFTopRollIcon = rollIcon
    end
    f.DFTopRoll:ClearAllPoints()
    f.DFTopRoll:SetPoint('BOTTOMLEFT', f, 'BOTTOMLEFT', RETAIL.nameX + 14, RETAIL.timerY + RETAIL.timerHeight + 3)
    f.DFTopRollIcon:ClearAllPoints()
    f.DFTopRollIcon:SetPoint('RIGHT', f.DFTopRoll, 'LEFT', -2, 0)
    f.DFTopRoll:SetText('')
    f.DFTopRollIcon:Hide()

    SubModuleMixin.ApplyDFBackdrop(f)

    -- Refresh cycle for LIVE frames only: at setup time these are hidden,
    -- and an unconditional Hide/Show popped four empty roll frames on login.
    if f:IsShown() then
        f:Hide()
        f:Show()
    end
end

function SubModuleMixin:UpdateGroupLootFrameStyleSimple(f)
    f:SetWidth(243) -- 243
    f:SetHeight(84) -- 84

    -- art
    do
        local corner = _G[f:GetName() .. "Corner"]
        corner:Hide()

        local decoration = _G[f:GetName() .. "Decoration"]
        local slotTexture = _G[f:GetName() .. "SlotTexture"]

        local iconSize = 38;
        local iconFrame = f.IconFrame
        iconFrame:SetSize(iconSize, iconSize)
        iconFrame:ClearAllPoints()
        iconFrame:SetPoint('CENTER', slotTexture, 'CENTER', 0, 0)

        local icon = iconFrame.Icon
        icon:SetSize(iconSize, iconSize)
        icon:ClearAllPoints()
        icon:SetPoint('CENTER', iconFrame, 'CENTER', 0, 0)

        local mask = iconFrame:CreateMaskTexture('DragonflightUIIconMask')
        iconFrame.Mask = mask
        mask:SetAllPoints(icon)
        mask:SetTexture('Interface\\Addons\\DragonflightUI\\Textures\\maskNew')
        mask:SetSize(45, 45)
        icon:AddMaskTexture(mask)

        local iconOverlay = DragonflightUIItemColorMixin:AddOverlayToFrame(iconFrame)
        iconOverlay:SetPoint('TOPLEFT', icon, 'TOPLEFT', 0, 0)
        iconOverlay:SetPoint('BOTTOMRIGHT', icon, 'BOTTOMRIGHT', 0, 0)

        DragonflightUIItemColorMixin:UpdateOverlayQuality(iconFrame, 4)
    end

    -- buttons
    do
        local btnSize = 28; -- 32
        local padding = 2;

        local fontFile, height, flags = GameFontHighlight:GetFont()
        local newFontSize = 14;

        local texCoords = {
            [0] = {1.05, -0.1, 1.05, -0.1}, -- pass
            [1] = {0.05, 1.05, -0.05, .95}, -- need
            [2] = {0.05, 1.0, -0.025, 0.85} -- greed
        }

        local function updateTexCoords(btn, rollType)
            local left, right, top, bottom = unpack(texCoords[rollType])

            btn:GetNormalTexture():SetTexCoord(left, right, top, bottom)
            btn:GetHighlightTexture():SetTexCoord(left, right, top, bottom)
            btn:GetPushedTexture():SetTexCoord(left, right, top, bottom)
        end

        local pass = f.PassButton;
        local need = f.NeedButton;
        local greed = f.GreedButton

        -- pass
        do
            pass:SetSize(btnSize, btnSize)
            pass:ClearAllPoints()
            -- pass:SetPoint('RIGHT', f, 'RIGHT', -14, 0)
            pass:SetPoint('TOPRIGHT', f, 'TOPRIGHT', -14, -14)
            pass:SetNormalTexture('Interface\\Buttons\\UI-GroupLoot-Pass-Up')
            pass:SetHighlightTexture('Interface\\Buttons\\UI-GroupLoot-Pass-Highlight')
            pass:SetPushedTexture('Interface\\Buttons\\UI-GroupLoot-Pass-Down')
            updateTexCoords(pass, 0)

            local text = pass:CreateFontString(nil, 'ARTWORK', 'GameFontHighlight')
            text:SetFont(fontFile, newFontSize, 'OUTLINE')
            text:SetPoint('BOTTOMRIGHT', pass, 'BOTTOMRIGHT', 2, -2)
            text:SetText('11')
            pass.DFText = text;

            pass:SetMotionScriptsWhileDisabled(true)
            pass:SetScript('OnEnter', function()
                GameTooltip:SetOwner(pass, "ANCHOR_RIGHT");
                GameTooltip:SetText(PASS);
                -- if (not pass:IsEnabled()) then
                --     GameTooltip:AddLine(pass.reason, RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b, true);
                --     GameTooltip:Show();
                -- end
                self:AddTooltipLines(pass, 0, false)
            end)
        end

        -- greed
        do
            greed:SetSize(btnSize, btnSize)
            greed:ClearAllPoints()
            -- greed:SetPoint('RIGHT', pass, 'LEFT', -padding, 0)
            greed:SetPoint('TOP', need, 'BOTTOM', 0, -padding)
            updateTexCoords(greed, 2)

            local text = greed:CreateFontString(nil, 'ARTWORK', 'GameFontHighlight')
            text:SetFont(fontFile, newFontSize, 'OUTLINE')
            text:SetPoint('BOTTOMRIGHT', greed, 'BOTTOMRIGHT', 2, -2)
            text:SetText('11')
            greed.DFText = text;

            greed:SetMotionScriptsWhileDisabled(true)
            greed:SetScript('OnEnter', function()
                GameTooltip:SetOwner(greed, "ANCHOR_RIGHT");
                GameTooltip:SetText(GREED);
                if (not greed:IsEnabled()) then
                    GameTooltip:AddLine(greed.reason, RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b, true);
                    GameTooltip:Show();
                end
                self:AddTooltipLines(greed, 2, false)
            end)
        end

        -- need
        do
            need:SetSize(btnSize, btnSize)
            need:ClearAllPoints()
            -- need:SetPoint('RIGHT', greed, 'LEFT', -padding, 0)
            need:SetPoint('RIGHT', pass, 'LEFT', -padding, 0)
            updateTexCoords(need, 1)

            local text = need:CreateFontString(nil, 'ARTWORK', 'GameFontHighlight')
            text:SetFont(fontFile, newFontSize, 'OUTLINE')
            text:SetPoint('BOTTOMRIGHT', need, 'BOTTOMRIGHT', 2, -2)
            text:SetText('11')
            need.DFText = text;

            need:SetMotionScriptsWhileDisabled(true)
            need:SetScript('OnEnter', function()
                GameTooltip:SetOwner(need, "ANCHOR_RIGHT");
                GameTooltip:SetText(NEED);
                if (not need:IsEnabled()) then
                    GameTooltip:AddLine(need.reason, RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b, true);
                    GameTooltip:Show();
                end
                self:AddTooltipLines(need, 1, false)
            end)
        end
    end

end
