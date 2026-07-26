local addonName, addonTable = ...;
local DF = LibStub('AceAddon-3.0'):GetAddon('DragonflightUI')

-- The What's New window.
--
-- Opens by itself once after an update and stays until dismissed, then never
-- again for that version. Openable any time from Settings > General > What's
-- New, or /df whatsnew.
--
-- "Seen" is stored globally rather than per profile: it is a fact about the
-- installation, not about a layout the player can switch between, and switching
-- profile should not make the notes reappear.
local Changelog = {}
DF.Changelog = Changelog

-- TEMP: always open on login, whatever has been seen, so the window can be
-- looked at without faking a version bump. Set back to false to restore
-- "once per version, until dismissed".
local ALWAYS_SHOW = true

local WIDTH, HEIGHT = 780, 660
local PAD = 26
local ICON = 'Interface\\Icons\\INV_Misc_Head_Dragon_01'

local COL_GOLD = {1, 0.82, 0}
local COL_WHITE = {0.95, 0.95, 0.95}
local COL_GREY = {0.62, 0.62, 0.62}
local COL_BLUE = {0.35, 0.80, 1}
local COL_GREEN = {0.30, 0.88, 0.45}

-- Plain ASCII, deliberately. This started as Interface\Scenarios\ScenarioIcon-
-- Dash, which draws nothing on Classic Era: Scenarios are a later asset folder
-- and nothing in the classic UI references it, so the bullets were invisible.
local BULLET = '|cffffd100-|r  '

-- ---------------------------------------------------------------------------
-- Layout helpers. The body is built from real widgets rather than one long
-- string, so sections can carry rules, badges and hanging indents instead of
-- arriving as a wall of text.
-- ---------------------------------------------------------------------------

local function AddText(content, y, text, font, indent, colour, width)
    local fs = content:CreateFontString(nil, 'ARTWORK', font)
    fs:SetPoint('TOPLEFT', content, 'TOPLEFT', indent, -y)
    fs:SetWidth(width - indent)
    fs:SetJustifyH('LEFT')
    fs:SetJustifyV('TOP')
    fs:SetSpacing(2)
    -- wrapped bullet text lines up under itself, not under the dash
    if fs.SetIndentedWordWrap then fs:SetIndentedWordWrap(true) end
    if colour then fs:SetTextColor(colour[1], colour[2], colour[3]) end
    fs:SetText(text)

    return y + fs:GetStringHeight() + 4, fs
end

local function AddRule(content, y, indent, width, alpha)
    local tex = content:CreateTexture(nil, 'ARTWORK')
    tex:SetColorTexture(1, 0.82, 0, alpha or 0.35)
    tex:SetHeight(1)
    tex:SetPoint('TOPLEFT', content, 'TOPLEFT', indent, -y)
    tex:SetWidth(width - indent)

    return y + 1
end

local function BuildBody(content, width)
    local y = 0

    for index, release in ipairs(DF.ChangelogData or {}) do
        if index > 1 then y = y + 18 end

        -- Release banner
        y = AddText(content, y, string.upper(release.title), 'GameFontNormalHuge', 0, COL_GOLD, width)

        local meta = release.version
        if release.date then meta = meta .. '   |   ' .. release.date end
        y = AddText(content, y, meta, 'GameFontHighlightSmall', 0, COL_GREY, width)

        y = y + 6
        y = AddRule(content, y, 0, width, 0.5)
        y = y + 10

        if release.intro then
            y = AddText(content, y, release.intro, 'GameFontHighlight', 0, COL_WHITE, width)
            y = y + 6
        end

        for _, section in ipairs(release.sections or {}) do
            y = y + 10

            local heading = section.title
            if section.new then heading = heading .. '   |cff4ce066[NEW]|r' end
            y = AddText(content, y, heading, 'GameFontNormalLarge', 0, COL_BLUE, width)

            y = y + 2
            y = AddRule(content, y, 0, width, 0.18)
            y = y + 6

            for _, item in ipairs(section.items or {}) do
                y = AddText(content, y, BULLET .. item, 'GameFontHighlight', 12, COL_WHITE, width)
            end
        end

        y = y + 8
    end

    return y
end

-- ---------------------------------------------------------------------------

local function CreateWindow()
    if Changelog.Frame then return Changelog.Frame end

    local f = CreateFrame('Frame', 'DragonflightUIWhatsNewFrame', UIParent, 'BackdropTemplate')
    f:SetSize(WIDTH, HEIGHT)
    f:SetPoint('CENTER')
    f:SetFrameStrata('DIALOG')
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag('LeftButton')
    f:SetScript('OnDragStart', f.StartMoving)
    f:SetScript('OnDragStop', f.StopMovingOrSizing)
    f:SetClampedToScreen(true)
    f:Hide()

    f:SetBackdrop({
        bgFile = 'Interface\\DialogFrame\\UI-DialogBox-Background-Dark',
        edgeFile = 'Interface\\DialogFrame\\UI-DialogBox-Border',
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = {left = 11, right = 12, top = 12, bottom = 11}
    })

    -- Header band, so the title reads as a banner rather than text floating at
    -- the top of a box.
    local band = f:CreateTexture(nil, 'BORDER')
    band:SetColorTexture(0, 0, 0, 0.55)
    band:SetPoint('TOPLEFT', f, 'TOPLEFT', 14, -14)
    band:SetPoint('TOPRIGHT', f, 'TOPRIGHT', -14, -14)
    band:SetHeight(96)

    local icon = f:CreateTexture(nil, 'ARTWORK')
    icon:SetSize(64, 64)
    icon:SetPoint('TOPLEFT', f, 'TOPLEFT', PAD, -30)
    icon:SetTexture(ICON)
    -- trim the icon's built-in border so it sits flush
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local iconRing = f:CreateTexture(nil, 'OVERLAY')
    iconRing:SetPoint('TOPLEFT', icon, 'TOPLEFT', -3, 3)
    iconRing:SetPoint('BOTTOMRIGHT', icon, 'BOTTOMRIGHT', 3, -3)
    iconRing:SetColorTexture(1, 0.82, 0, 0.25)

    local title = f:CreateFontString(nil, 'OVERLAY', 'GameFontNormalHuge')
    title:SetPoint('TOPLEFT', icon, 'TOPRIGHT', 16, -2)
    title:SetTextColor(1, 0.82, 0)
    title:SetText("What's New")

    local product = f:CreateFontString(nil, 'OVERLAY', 'GameFontNormalLarge')
    product:SetPoint('TOPLEFT', title, 'BOTTOMLEFT', 0, -4)
    product:SetText('DragonflightUI |cff9d9d9d' .. DF:GetVersion() .. '|r')

    local credits = f:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
    credits:SetPoint('TOPLEFT', product, 'BOTTOMLEFT', 0, -4)
    credits:SetTextColor(0.62, 0.62, 0.62)
    credits:SetText('Maintained by MendleM  -  originally by Karl-Heinz Schneider')

    local headRule = f:CreateTexture(nil, 'OVERLAY')
    headRule:SetColorTexture(1, 0.82, 0, 0.6)
    headRule:SetHeight(2)
    headRule:SetPoint('TOPLEFT', band, 'BOTTOMLEFT', 0, -1)
    headRule:SetPoint('TOPRIGHT', band, 'BOTTOMRIGHT', 0, -1)

    local close = CreateFrame('Button', nil, f, 'UIPanelButtonTemplate')
    close:SetSize(170, 28)
    close:SetPoint('BOTTOM', f, 'BOTTOM', 0, 20)
    close:SetText(CLOSE or 'Close')
    close:SetScript('OnClick', function() Changelog:Hide() end)

    local footer = f:CreateFontString(nil, 'OVERLAY', 'GameFontDisableSmall')
    footer:SetPoint('BOTTOM', close, 'TOP', 0, 8)
    footer:SetText("Reopen any time from Settings > General > What's New, or /df whatsnew")

    local scroll = CreateFrame('ScrollFrame', 'DragonflightUIWhatsNewScroll', f, 'UIPanelScrollFrameTemplate')
    scroll:SetPoint('TOPLEFT', f, 'TOPLEFT', PAD, -124)
    scroll:SetPoint('BOTTOMRIGHT', f, 'BOTTOMRIGHT', -(PAD + 16), 78)

    local content = CreateFrame('Frame', nil, scroll)
    content:SetSize(WIDTH - (PAD * 2) - 20, 1)
    scroll:SetScrollChild(content)

    f.Content = content
    f.ContentWidth = WIDTH - (PAD * 2) - 20

    -- Escape closes it, like any other dialog.
    if UISpecialFrames then table.insert(UISpecialFrames, 'DragonflightUIWhatsNewFrame') end

    -- Mark it read however it was closed. Escape and the close button take
    -- different routes, and only this one catches both - otherwise dismissing
    -- with Escape would bring it back at the next login.
    f:SetScript('OnHide', function() Changelog:MarkSeen() end)

    Changelog.Frame = f
    return f
end

function Changelog:Show()
    local f = CreateWindow()

    -- Built once. The notes do not change within a session, and rebuilding
    -- would mean tearing down every FontString first.
    if not f.Built then
        f.Built = true
        local height = BuildBody(f.Content, f.ContentWidth)
        f.Content:SetHeight(math.max(height, 1))
    end

    f:Show()
end

function Changelog:Hide()
    -- OnHide does the marking, so Escape and this take the same route.
    if self.Frame then self.Frame:Hide() end
end

-- Remember the version whose notes have been read, so they do not open again.
function Changelog:MarkSeen()
    if not (DF.db and DF.db.global) then return end
    DF.db.global.lastSeenVersion = DF:GetVersion()
end

function Changelog:HasUnseen()
    if not (DF.db and DF.db.global) then return false end
    return DF.db.global.lastSeenVersion ~= DF:GetVersion()
end

-- Opened after login when the running version is not the one last read.
--
-- An empty record counts as unseen, and deliberately so. Everyone updating to
-- the build that introduced this has no record at all, and skipping them as
-- though they were a fresh install would mean the notes never appeared for the
-- people they were written for.
function Changelog:ShowIfUnseen()
    if not (ALWAYS_SHOW or self:HasUnseen()) then return end

    self:Show()
end
