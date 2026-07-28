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
-- one 32px icon on the 512x512 sheet, as a texcoord TABLE: returning four
-- values here would silently keep only the first, which is exactly how this
-- read 'attempt to index field up (a number value)' and took the whole
-- restyle - and with it the rest of the UI module's setup - down with it
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

-- items the preview cycles through, spread across qualities so the quality
-- borders and name colour can be judged
local PREVIEW_ITEMS = {19019, 19431, 22691, 12640, 13262, 7075, 4306}

-- Sample rollers, so the preview can show the parts of a roll that only exist
-- mid-roll: the count on each button, the tally line, and the tooltip naming
-- who chose what. Those read from C_LootHistory, which has nothing to say
-- about a roll that is not happening, so the preview brings its own group.
-- Spread across classes because the names are class-coloured.
local PREVIEW_ROLLERS = {
    {name = 'Aldwin', class = 'PALADIN'}, {name = 'Brynja', class = 'SHAMAN'},
    {name = 'Corvin', class = 'ROGUE'}, {name = 'Dhalia', class = 'DRUID'},
    {name = 'Ereth', class = 'MAGE'}, {name = 'Faldric', class = 'WARRIOR'},
    {name = 'Gwenna', class = 'PRIEST'}, {name = 'Hakkon', class = 'HUNTER'}
}

-- A different split per roll frame, fixed rather than random: the tooltip is
-- rebuilt on every hover, and a random deal would reshuffle the group under
-- the cursor each time. need/greed/pass/undecided.
local PREVIEW_SPLIT = {{2, 3, 1, 2}, {1, 2, 3, 0}, {3, 1, 2, 1}, {0, 4, 2, 1}}

local function BuildPreviewRolls(index)
    local split = PREVIEW_SPLIT[((index - 1) % #PREVIEW_SPLIT) + 1]
    local rolls = {need = {}, greed = {}, pass = {}, diss = {}, none = {}}
    local order = {rolls.need, rolls.greed, rolls.pass, rolls.none}

    local dealt = 1
    for bucket, count in ipairs(split) do
        for _ = 1, count do
            local roller = PREVIEW_ROLLERS[((dealt - 1) % #PREVIEW_ROLLERS) + 1]
            table.insert(order[bucket], {name = roller.name, class = roller.class, id = dealt})
            dealt = dealt + 1
        end
    end

    return rolls
end

-- A frame with a roll to describe, real or sampled. Declared up here because
-- the display code that asks runs earlier in the file than the roll tables do.
local function HasRollData(f) return (f ~= nil) and (f.rollID ~= nil or f.DFPreviewRolls ~= nil) end

local function ApplyRollButtonArt(btn, key)
    local art = MODERN_ICONS[key]
    if not (btn and art) then return end

    -- The classic pass button is a UIPanelCloseButton; its inherited art has
    -- to go, disabled state included, or it shows through. Clear the texture
    -- object rather than calling SetDisabledTexture(nil): 1.15.9 rejects nil
    -- for the button's asset setters outright ("Usage:
    -- self:SetDisabledTexture(asset)"), and that error aborted the restyle.
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
        previewCount = 3,
        -- tighter than retail's 33 (its reservedSize of 100 on a 67px frame)
        rollSpacing = 15,
        anchorFrame = 'UIParent',
        customAnchorFrame = '',
        anchor = 'BOTTOM',
        anchorParent = 'BOTTOM',
        -- retail's GroupLootContainer is a bottom managed frame (layoutIndex
        -- 3), so it sits bottom-CENTRE above the action bars and stacks
        -- upwards - not off to the right as this defaulted to (x = 425)
        x = 0,
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
            self:ShowPreview()
        end,
        order = 0.6
    }
    rollOptions.args.previewCount = {
        type = 'range',
        name = 'Preview rolls',
        desc = 'How many sample rolls the preview pops, so a whole drop can be judged'
            .. ' rather than a single item.' .. getDefaultStr('previewCount', 'roll'),
        min = 1,
        max = 4,
        bigStep = 1,
        order = 0.65
    }
    rollOptions.args.rollSpacing = {
        type = 'range',
        name = 'Spacing between rolls',
        desc = 'Vertical gap between stacked roll frames when several items drop at once.'
            .. getDefaultStr('rollSpacing', 'roll'),
        min = 0,
        max = 100,
        bigStep = 1,
        order = 0.75,
        editmode = true
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
    if not (topRoll and HasRollData(f)) then return end
    if self.state and not self.state.showTopRoll then
        topRoll:SetText('')
        if rollIcon then rollIcon:Hide() end
        return
    end

    -- A winner is a thing only a real roll has; a preview goes straight to the
    -- tally, which is the state the frame spends its life in anyway.
    if f.rollID and C_LootHistory and C_LootHistory.GetNumItems then
        local itemIdx = FindItemIdxForRoll(f.rollID)
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
                    if ApplyRollTypeIcon(rollIcon, rollType) then
                        rollIcon:Show()
                    else
                        rollIcon:Hide()
                    end
                    return
                end
            end
        end
    end

    -- Until the roll resolves, the only thing here worth saying is how many
    -- people have not answered yet.
    --
    -- This line used to carry a dice/coin/slash tally as well, and it was only
    -- ever standing in: the restyle had silently dropped the counts off the
    -- roll buttons an hour earlier, so the numbers were rebuilt over here where
    -- there was room. With the buttons showing their own counts again that made
    -- the frame state everything twice, in two different notations, on a frame
    -- 67 pixels tall.
    if rollIcon then rollIcon:Hide() end
    local _, _, _, _, tableNone = self:GetRollTables(f)
    if tableNone and #tableNone > 0 then
        topRoll:SetFormattedText('|cff999999%d left|r', #tableNone)
    else
        topRoll:SetText('')
    end
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

    local coloredName = class and DF:GetClassColoredText(name, class) or name
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

-- Vertical space one roll occupies in the stack: its own height plus the
-- configured gap. Retail's reservedSize of 100 on a 67px frame works out to a
-- 33px gap; the default here is tighter at 15.
function SubModuleMixin:GetReservedSize()
    local state = self.state or self.Defaults
    local gap = state.rollSpacing
    if type(gap) ~= 'number' then gap = self.Defaults.rollSpacing end
    return RETAIL.height + math.max(0, math.min(150, gap))
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

    -- Spacing between stacked rolls. Blizzard drives the whole stack off
    -- reservedSize (frame height + gap), so setting it and re-running the
    -- container's own layout applies the change to rolls already on screen.
    f.reservedSize = self:GetReservedSize()
    if GroupLootContainer_Update then pcall(GroupLootContainer_Update, f) end

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
    -- Above the settings window (HIGH + toplevel) but below TOOLTIP: at
    -- TOOLTIP the sample rolls drew over their own button tooltips.
    holder:SetFrameStrata('FULLSCREEN_DIALOG')
    holder:Hide()
    holder.Rolls = {}

    self.SettingsPreview = holder
    return holder
end

-- One sample roll frame, created on demand. Up to four, because that is how
-- many roll frames the game itself keeps.
function SubModuleMixin:GetPreviewRoll(index)
    local holder = self:GetSettingsPreview()
    if holder.Rolls[index] then return holder.Rolls[index] end

    local roll = CreateFrame('Frame', 'DragonflightUIGroupLootSettingsPreviewRoll' .. index, holder,
                             'DFEditModePreviewGroupLootTemplate')
    self:PrepPreviewFrame(roll)

    -- Sample rollers, so this frame answers the same questions a real one
    -- does: the button counts, the tally line, and the hover tooltip all read
    -- from here instead of from C_LootHistory. A different split per frame, so
    -- a four-roll preview does not show the same numbers four times.
    roll.DFPreviewRolls = BuildPreviewRolls(index)

    local ok, err = pcall(self.UpdateGroupLootFrameStyle, self, roll)
    if not ok then geterrorhandler()('DFUI loot roll preview restyle: ' .. tostring(err)) end

    holder.Rolls[index] = roll
    -- the first one keeps the old field name; the winner toast anchors to it
    if index == 1 then holder.FakePreview = roll end
    return roll
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

    -- Clear the borrowed art, then nail it shut: the template's mixin
    -- re-textures and re-shows it from an item-load callback that lands after
    -- any restyle, so hiding it once is not enough. Only our own textures exist
    -- after this point, and they are created later by the styler, so nothing of
    -- ours gets stubbed. FontStrings are skipped, so the item name survives.
    SubModuleMixin.StripBorrowedArt(fake)
    for _, region in ipairs({fake:GetRegions()}) do
        if region.GetObjectType and region:GetObjectType() == 'Texture' then
            region.Show = function() end
            region.SetTexture = function() end
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
    local holder = self:GetSettingsPreview()
    local state = self.state or self.Defaults

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

    -- A whole drop, not a single item: the rolls stack exactly the way
    -- GroupLootContainer_Update stacks the real ones - each frame centred
    -- reservedSize * (i - 0.5) above the container's bottom edge - so the
    -- preview shows what four simultaneous rolls will actually cover.
    local count = math.floor(math.max(1, math.min(4, state.previewCount or 3)))
    local reserved = self:GetReservedSize()
    local first

    for i = 1, 4 do
        local roll = (i <= count) and self:GetPreviewRoll(i) or holder.Rolls[i]
        if roll and i <= count then
            roll:ClearAllPoints()
            roll:SetPoint('CENTER', holder, 'BOTTOM', 0, reserved * (i - 0.5))
            -- a different item per roll, and different each time, so the
            -- quality colouring can be seen doing its job
            SubModuleMixin.SetPreviewItem(roll, PREVIEW_ITEMS[fastrandom(1, #PREVIEW_ITEMS)])
            -- the roll-dependent half of the frame: button counts and the
            -- tally line, both driven by the sample group on the frame
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

-- The preview hides itself after a few seconds. That is long enough to judge
-- where the rolls sit and too short to read a tooltip in, and reading the
-- tooltip is half of what there is to preview - so hovering a sample roll
-- starts the clock over rather than racing it.
function SubModuleMixin:RestartPreviewTimer()
    local holder = self.SettingsPreview
    if not holder then return end

    if self.PreviewTimer then self.PreviewTimer:Cancel() end
    self.PreviewTimer = C_Timer.NewTimer(self.PreviewDuration or 6, function() holder:Hide() end)
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
    -- same sample group the settings preview uses, so the edit mode box shows
    -- the frame with its counts and tally on rather than an empty one
    fakePreview.DFPreviewRolls = BuildPreviewRolls(1)
    -- pcall: this call site is inside Setup, which runs from the UI module's
    -- OnEnable - a throw here used to abort the rest of that setup
    local ok, err = pcall(self.UpdateGroupLootFrameStyle, self, fakePreview)
    if not ok then
        geterrorhandler()('DFUI loot roll preview restyle: ' .. tostring(err))
    end
    SubModuleMixin.SetPreviewItem(fakePreview, PREVIEW_ITEMS[1])
    self:UpdateAllButtons(fakePreview)
    self:UpdateTopRoll(fakePreview)

    fakeRoll.FakePreview = fakePreview
end

-- Restyles the REAL roll frames - destructive, so it only runs once the
-- 'roll' state confirms the feature is enabled (see Update).
function SubModuleMixin:StyleRollFrames()
    -- Space per roll slot: frame height plus the configured gap (retail
    -- reserves 100 for a 67px frame, i.e. a 33px gap).
    if _G['GroupLootContainer'] then _G['GroupLootContainer'].reservedSize = self:GetReservedSize() end

    for i = 1, 4 do
        local f = _G['GroupLootFrame' .. i]
        -- A restyle failure must stay local. When this threw it propagated out
        -- of Setup, aborted the UI module's OnEnable, and left everything it
        -- had not reached yet - the character frame among them - on Blizzard's
        -- default look until a reload.
        local ok, err = pcall(self.UpdateGroupLootFrameStyle, self, f)
        if not ok then
            geterrorhandler()('DFUI loot roll restyle: ' .. tostring(err))
        end
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

local function SetButtonCount(btn, t)
    local fs = btn and btn.DFText
    if not fs then return end
    -- '*' means the roll exists but its numbers have not arrived yet
    fs:SetText(t and tostring(#t) or '*')
end

function SubModuleMixin:UpdateAllButtons(f)
    if not HasRollData(f) then return end

    local tableNeed, tableGreed, tablePass, tableDiss, tableNone, tableData = self:GetRollTables(f)

    SetButtonCount(f.NeedButton, tableNeed)
    SetButtonCount(f.GreedButton, tableGreed)
    -- this one tested tableGreed, so an empty pass list read as '*'
    SetButtonCount(f.PassButton, tablePass)

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

-- Who chose what on this frame's roll. The single place either kind of frame
-- is asked that question: a real roll answers from C_LootHistory, a preview
-- frame from the sample group hung on it. Everything that displays roll
-- membership - the button counts, the tally line, the hover tooltip - goes
-- through here, which is what makes the settings preview show the real thing
-- rather than a mock-up of it.
function SubModuleMixin:GetRollTables(f)
    if not f then return nil end

    local preview = f.DFPreviewRolls
    if preview then return preview.need, preview.greed, preview.pass, preview.diss, preview.none end

    if not (f.rollID and C_LootHistory and C_LootHistory.GetNumItems) then return nil end
    return self:CreateTableForRollID(f.rollID)
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
    local tableNeed, tableGreed, tablePass, tableDiss, tableNone = self:GetRollTables(f:GetParent())
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

    -- Only when somebody actually is: this used to be `showAll or true`, which
    -- put an "Undecided" heading with nothing under it on every tooltip.
    if tableNone and #tableNone > 0 then
        GameTooltip:AddLine('Undecided')
        AddRollLines(tableNone)
    end

    GameTooltip:Show()
end

-- Every texture on the frame that is not one of ours, gone.
--
-- The classic frame brings four: the empty-slot square, the recessed
-- merchant-label plate behind the item name, the gold dragon and the corner.
-- This used to hide them by building their global names - frameName ..
-- 'NameFrame' and so on - which only works while every one of those regions is
-- named exactly that on every flavour and on every frame we style, the preview
-- copies included. A sweep does not have to be right about their names.
--
-- Textures only: the item name and the summary line are FontStrings on this
-- same frame, and they stay.
function SubModuleMixin.StripBorrowedArt(frame)
    if not frame.GetRegions then return end

    -- Built one at a time rather than by iterating a list of the three: the
    -- styler creates them in order, so mid-build the list has a hole in it and
    -- ipairs would stop at the hole and whitelist nothing after it.
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
    SubModuleMixin.StripBorrowedArt(frame)
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

local ROLL_TYPE_LABEL = {[0] = PASS, [1] = NEED, [2] = GREED, [3] = ROLL_DISENCHANT}

-- The count on a roll button and the tooltip naming who chose it.
--
-- Both are DFUI's, not Blizzard's, and both used to be installed by
-- UpdateGroupLootFrameStyleSimple. When the restyle moved to the retail-shaped
-- UpdateGroupLootFrameStyle they were left behind with it: the buttons kept
-- Blizzard's own OnEnter, which names the roll type and stops there, and
-- UpdateAllButtons went on running against DFText fontstrings that no longer
-- existed. Hence "it only shows how many rolled" - the tally line survived
-- because it hangs off the frame, not off the buttons.
function SubModuleMixin:WireRollButton(btn, rollType)
    if not btn then return end
    local module = self

    if not btn.DFText then
        local fontFile = GameFontHighlight:GetFont()
        local text = btn:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
        text:SetFont(fontFile, 13, 'OUTLINE')
        btn.DFText = text
    end
    -- Inside the button's bottom-right corner, not hanging off it. The roll
    -- icons are round in a square button, so the corner is empty art and the
    -- number can sit in it without covering the dice, coin or slash.
    btn.DFText:ClearAllPoints()
    btn.DFText:SetPoint('BOTTOMRIGHT', btn, 'BOTTOMRIGHT', -1, 1)

    -- Scripts survive a restyle, so install them once. Re-running SetScript
    -- would be harmless but the guard keeps a re-style from being able to
    -- stack behaviour on a button.
    if btn.DFTooltipWired then return end
    btn.DFTooltipWired = true

    -- Without this a button that is disabled - already rolled, or not eligible
    -- - stops sending OnEnter, and the names disappear exactly when they are
    -- most worth reading.
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

function SubModuleMixin:UpdateGroupLootFrameStyle(f)
    if not f then return end

    f:SetSize(RETAIL.width, RETAIL.height)
    if f.SetBackdrop then f:SetBackdrop(nil) end

    -- classic art out of the way. Their anchors stay put: the classic pass
    -- button hangs off Corner and the classic timer off SlotTexture, so
    -- clearing their points strands anything still anchored to them.
    SubModuleMixin.StripBorrowedArt(f)

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
            self:WireRollButton(diss, 3)
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
    -- Flush with the item name above it, so the two read as one column. The
    -- old anchor indented it 14px to reserve room for the winner icon, which
    -- put the line under nothing in particular; the icon now hangs in the gap
    -- between the item icon and the name, where there is already space.
    f.DFTopRoll:ClearAllPoints()
    f.DFTopRoll:SetPoint('BOTTOMLEFT', f, 'BOTTOMLEFT', RETAIL.nameX, RETAIL.timerY + RETAIL.timerHeight + 3)
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
