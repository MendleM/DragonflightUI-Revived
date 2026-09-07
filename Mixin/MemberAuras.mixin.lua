local addonName, addonTable = ...;
local DF = addonTable.DF;

-- Our own buff row for the frames that use Blizzard's PartyMemberAuraMixin - the pet
-- frame and the pooled party member frames.
--
-- Why not Blizzard's own row. UpdateMemberAuras draws buffs INSTEAD of debuffs when
-- the frame carries showBuffs, and nothing in Blizzard's UI ever sets that field: it
-- appears exactly once across all 63 files of Blizzard_UnitFrame, as a read at
-- PartyMemberFrame.lua:84, identical in 1.15.9, 2.5.6 and 5.5.4. So a value there is
-- always an addon's, and Blizzard reading it hands that addon's taint to whatever
-- execution happens to be on the stack. Setting it is what blocked target-of-target
-- in combat - the full stack is written out in Pet.mixin.lua. Driving UpdateAuras()
-- ourselves has the same problem one level down: ParseAllAuras then creates
-- self.buffs and self.debuffs inside our execution, and Blizzard reads those back on
-- every later pass at lines 73, 76 and 86.
--
-- So this draws its own row and leaves every field of Blizzard's alone. Buffs and
-- debuffs end up side by side rather than one replacing the other, which is what
-- setting showBuffs never gave us.
--
-- Three rules keep it clean:
--
--   The container is parented to UIParent, not to the unit frame. Protection is
--   inherited by children, so icons parented under PetFrame would be protected too
--   and our Show/Hide on them would be refused mid-combat - exactly the class of bug
--   this is replacing. Parented to UIParent they are ours to move and hide whenever
--   we like; the row is only anchored to the unit frame.
--
--   The auras are read with AuraUtil.ForEachAura rather than off Blizzard's parsed
--   frame.buffs. A read cannot taint anything, but reading their table would tie us
--   to Blizzard's event order: both handlers listen to UNIT_AURA and nothing says
--   ours runs second, so frame.buffs would lag an event behind. Parsing is a C call.
--
--   It is driven by our own event frame, not by a hook on the unit frame's methods -
--   the same reasoning the party module already documents for UpdateOnlineStatus.
--   The only thing hooked is OnShow/OnHide via HookScript, which writes a script and
--   not a Lua field, because a container parented to UIParent does not disappear on
--   its own when the pet is dismissed.

local ICON_SIZE = 15
local ICON_SPACING = 2
local MAX_ICONS = 4

-- Weak keys: a released pooled member frame must not be held alive by this.
local rows = setmetatable({}, {__mode = 'k'})
local providers = {}
local templateUsable

local function HelpfulFilter()
    if AuraUtil and AuraUtil.CreateFilterString and AuraUtil.AuraFilters then
        local ok, filter = pcall(AuraUtil.CreateFilterString, AuraUtil.AuraFilters.Helpful)
        if ok and filter then return filter end
    end
    return 'HELPFUL'
end

-- The same gate Blizzard's ProcessAura puts helpful auras through
-- (AuraUtil.lua:231), so the row shows what showBuffs used to show and not every
-- raid buff in the zone.
local function ShouldShowBuff(aura)
    if aura.isNameplateOnly then return false end
    if AuraUtil and AuraUtil.ShouldDisplayBuff then
        local ok, show = pcall(AuraUtil.ShouldDisplayBuff, aura.sourceUnit, aura.spellId, aura.canApplyAura)
        if ok then return show and true or false end
    end
    return true
end

-- Anonymous frames only. A named global created inside our execution stays tainted
-- for the session, and Blizzard's aura code looks frames up by name.
local function NewAuraButton(parent)
    if templateUsable == false then return nil end

    local ok, button = pcall(CreateFrame, 'BUTTON', nil, parent, 'PartyAuraFrameTemplate')
    templateUsable = (ok and type(button) == 'table' and button.Setup ~= nil) or false
    if not templateUsable then return nil end

    return button
end

local function GetRow(frame)
    local row = rows[frame]
    if row then return row end
    if type(frame) ~= 'table' or not frame.GetFrameStrata then return nil end

    local container = CreateFrame('Frame', nil, UIParent)
    container:SetSize(ICON_SIZE, ICON_SIZE)
    container:Hide()

    row = {container = container, buttons = {}}
    rows[frame] = row

    -- The container lives on UIParent, so it has to be told when its unit frame goes
    -- away. HookScript installs a script and not a field, so nothing lands on the
    -- protected frame's table for Blizzard to read back.
    if frame.HookScript then
        frame:HookScript('OnHide', function() container:Hide() end)
        frame:HookScript('OnShow', function() addonTable:RefreshMemberBuffRows() end)
    end

    return row
end

function addonTable:UpdateMemberBuffRow(frame, unit, opts)
    local row = GetRow(frame)
    if not row then return end

    local container = row.container
    opts = opts or {}

    if not (opts.enabled and unit and UnitExists(unit) and frame:IsShown()) then
        container:Hide()
        return
    end

    if not (AuraUtil and AuraUtil.ForEachAura) then
        container:Hide()
        return
    end

    local size = opts.size or ICON_SIZE
    local spacing = opts.spacing or ICON_SPACING
    local maxIcons = opts.maxBuffs or MAX_ICONS

    container:ClearAllPoints()
    container:SetPoint(opts.point or 'TOPLEFT', frame, opts.relativePoint or 'BOTTOMLEFT', opts.x or 48, opts.y or -1)
    container:SetFrameStrata(frame:GetFrameStrata())
    container:SetFrameLevel((frame:GetFrameLevel() or 1) + 5)
    container:SetScale(opts.scale or 1)

    local shown = 0
    AuraUtil.ForEachAura(unit, HelpfulFilter(), nil, function(aura)
        if not (aura and aura.icon and ShouldShowBuff(aura)) then return false end

        local button = row.buttons[shown + 1]
        if not button then
            button = NewAuraButton(container)
            if not button then return true end
            row.buttons[shown + 1] = button
        end

        shown = shown + 1
        button:ClearAllPoints()
        button:SetSize(size, size)
        button:SetPoint('LEFT', container, 'LEFT', (shown - 1) * (size + spacing), 0)
        button:Setup(unit, aura, true)

        return shown >= maxIcons
    end, true)

    for i = shown + 1, #row.buttons do row.buttons[i]:Hide() end

    if shown == 0 then
        container:Hide()
        return
    end

    container:SetSize(shown * size + (shown - 1) * spacing, size)
    container:Show()
end

-- A provider hands over the (frame, unit, opts) triples it wants decorated. Pooled
-- frames come and go, so the list is asked for on every refresh rather than stored.
function addonTable:AddMemberBuffRowProvider(name, iterate)
    if not name or type(iterate) ~= 'function' then return end

    providers[name] = iterate
    addonTable:EnsureMemberBuffRowDriver()
end

function addonTable:RefreshMemberBuffRows(onlyUnit)
    for name, iterate in pairs(providers) do
        local ok, err = pcall(iterate, function(frame, unit, opts)
            if not frame then return end
            if onlyUnit and not (unit and UnitIsUnit(unit, onlyUnit)) then return end
            addonTable:UpdateMemberBuffRow(frame, unit, opts)
        end)
        if not ok and DF and DF.Log then DF:Log('memberauras', 'provider %s failed: %s', name, tostring(err)) end
    end
end

local driver
function addonTable:EnsureMemberBuffRowDriver()
    if driver then return end

    driver = CreateFrame('Frame')
    driver:RegisterEvent('UNIT_AURA')
    driver:RegisterEvent('PLAYER_ENTERING_WORLD')
    driver:RegisterEvent('GROUP_ROSTER_UPDATE')
    driver:RegisterEvent('UNIT_PET')
    driver:SetScript('OnEvent', function(_, event, arg1)
        -- UNIT_AURA is the hot one and carries the unit, so only that row is redrawn.
        -- The rest are structural and redraw everything.
        addonTable:RefreshMemberBuffRows(event == 'UNIT_AURA' and arg1 or nil)
    end)
end
