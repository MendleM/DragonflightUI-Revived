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

-- Set true to force the window open on every login regardless of what has been
-- seen, which is how the layout gets looked at without faking a version bump.
-- Off for release: once per version, until dismissed.
local ALWAYS_SHOW = false

local WIDTH, HEIGHT = 780, 660
local PAD = 26
local ICON = 'Interface\\Icons\\INV_Misc_Head_Dragon_01'

local COL_GOLD = {1, 0.82, 0}
-- Warm rather than pure gold for the release name, and a heading gold a shade
-- down from it: two golds a step apart read as a hierarchy, where gold against
-- bright blue read as two unrelated things shouting.
local COL_TITLE = {1, 0.91, 0.66}
local COL_HEAD = {0.97, 0.80, 0.38}
local COL_WHITE = {0.87, 0.87, 0.89}
local COL_GREY = {0.55, 0.55, 0.58}

-- One spacing scale, used everywhere. The old layout mixed 18/10/6/2/8 by feel,
-- which is what made it look busy: nothing lined up with anything else.
local SP = {tight = 3, item = 4, block = 10, section = 16, release = 26}

-- Plain ASCII, deliberately. This started as Interface\Scenarios\ScenarioIcon-
-- Dash, which draws nothing on Classic Era: Scenarios are a later asset folder
-- and nothing in the classic UI references it, so the bullets were invisible.
-- A dot at the weight of the surrounding text rather than a bright gold dash.
-- The bullet is punctuation; it should not be the first thing the eye lands on
-- in a list of twenty.
local BULLET = '|cff7a6c48\226\128\162|r  '

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

-- A section heading, marked with a short gold tick in the margin instead of a
-- rule underneath it.
--
-- The old layout drew a full-width line under every heading. With seven sections
-- that is seven horizontal bars competing with the one that actually divides the
-- releases, and the page reads as a stack of boxes. A 2px tick in the margin
-- says "new section" just as clearly and leaves the page quiet.
local function AddHeading(content, y, text, width)
    local newY, fs = AddText(content, y, text, 'GameFontNormal', 12, COL_HEAD, width)

    local tick = content:CreateTexture(nil, 'ARTWORK')
    tick:SetColorTexture(COL_GOLD[1], COL_GOLD[2], COL_GOLD[3], 0.65)
    tick:SetPoint('TOPLEFT', content, 'TOPLEFT', 0, -y - 2)
    tick:SetSize(2, math.max(fs:GetStringHeight() - 2, 8))

    return newY
end

local function BuildBody(content, width)
    local y = 0

    for index, release in ipairs(DF.ChangelogData or {}) do
        if index > 1 then y = y + SP.release end

        -- The release name at large rather than huge, and in mixed case. Shouted
        -- capitals at GameFontNormalHuge took three lines for a title of five
        -- words and set the visual weight of the whole page.
        y = AddText(content, y, release.title, 'GameFontNormalLarge', 0, COL_TITLE, width)

        local meta = release.version
        if release.date then meta = meta .. '  \194\183  ' .. release.date end
        y = AddText(content, y, meta, 'GameFontHighlightSmall', 0, COL_GREY, width) + SP.tight

        -- The only rule on the page, and it belongs to the release.
        y = AddRule(content, y, 0, width, 0.40) + SP.block

        if release.intro then y = AddText(content, y, release.intro, 'GameFontHighlight', 0, COL_WHITE, width) end

        for _, section in ipairs(release.sections or {}) do
            y = y + SP.section

            local heading = section.title
            if section.new then heading = heading .. '  |cff4ce066NEW|r' end
            y = AddHeading(content, y, heading, width) + SP.item

            for _, item in ipairs(section.items or {}) do
                y = AddText(content, y, BULLET .. item, 'GameFontHighlight', 14, COL_WHITE, width) + SP.tight
            end
        end
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
    -- A slimmer band. At 96 tall behind a 64px icon and a Huge title this was a
    -- seventh of the window before a word of the notes, which is the same fault
    -- the body had: everything competing to be the loudest thing on screen.
    band:SetHeight(64)

    local icon = f:CreateTexture(nil, 'ARTWORK')
    icon:SetSize(38, 38)
    icon:SetPoint('LEFT', band, 'LEFT', PAD - 14, 0)
    icon:SetTexture(ICON)
    -- trim the icon's built-in border so it sits flush
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local iconRing = f:CreateTexture(nil, 'OVERLAY')
    iconRing:SetPoint('TOPLEFT', icon, 'TOPLEFT', -1, 1)
    iconRing:SetPoint('BOTTOMRIGHT', icon, 'BOTTOMRIGHT', 1, -1)
    iconRing:SetColorTexture(1, 0.82, 0, 0.22)

    -- Title and version on one line: the version is a detail about the title,
    -- not a second heading, and stacking them made two lines of shouting.
    local title = f:CreateFontString(nil, 'OVERLAY', 'GameFontNormalLarge')
    title:SetPoint('LEFT', icon, 'RIGHT', 14, 7)
    title:SetTextColor(1, 0.82, 0)
    title:SetText("What's New")

    local product = f:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
    product:SetPoint('TOPLEFT', title, 'BOTTOMLEFT', 1, -3)
    product:SetTextColor(0.55, 0.55, 0.58)
    product:SetText('DragonflightUI ' .. DF:GetVersion())

    local credits = f:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
    credits:SetPoint('TOPLEFT', product, 'BOTTOMLEFT', 0, -4)
    credits:SetTextColor(0.62, 0.62, 0.62)
    credits:SetText('Maintained by MendleM  -  originally by Karl-Heinz Schneider')

    local headRule = f:CreateTexture(nil, 'OVERLAY')
    -- A hairline, not a 2px gold bar. This is the edge between chrome and
    -- content; it needs to be crisp, not loud.
    headRule:SetColorTexture(1, 0.82, 0, 0.35)
    headRule:SetHeight(1)
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
    scroll:SetPoint('TOPLEFT', f, 'TOPLEFT', PAD, -96)
    scroll:SetPoint('BOTTOMRIGHT', f, 'BOTTOMRIGHT', -(PAD + 16), 78)

    local content = CreateFrame('Frame', nil, scroll)
    content:SetSize(WIDTH - (PAD * 2) - 20, 1)
    scroll:SetScrollChild(content)

    f.Content = content
    f.ContentWidth = WIDTH - (PAD * 2) - 20

    -- Escape closes it, like any other dialog - but handled here rather than
    -- through UISpecialFrames, which is read by name out of _G and taints
    -- whoever owns the global. See Helper:CloseWithEscape.
    addonTable.Helper:CloseWithEscape(f)

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

-- The notes decide when the notes open.
--
-- This used to compare against DF:GetVersion(), the TOC's idea of the version,
-- which meant a release had to remember to change two files in step: bump the
-- TOC and add the entry describing it. Forget the bump and the window never
-- opens for the notes you just wrote, silently and with nothing to notice - the
-- writing is the visible half of the job and the trigger is not.
--
-- Keying off the entry being displayed removes the coupling: adding notes is
-- what makes them appear, because it is the same fact.
function Changelog:NotesVersion()
    local newest = DF.ChangelogData and DF.ChangelogData[1]
    return (newest and newest.version) or DF:GetVersion()
end

-- Remember the notes that have been read, so they do not open again.
function Changelog:MarkSeen()
    if not (DF.db and DF.db.global) then return end
    DF.db.global.lastSeenVersion = self:NotesVersion()
end

function Changelog:HasUnseen()
    if not (DF.db and DF.db.global) then return false end
    return DF.db.global.lastSeenVersion ~= self:NotesVersion()
end

-- The two are still meant to agree, and a release where they do not is a
-- packaging slip worth catching. It no longer breaks anything, so this belongs
-- in the log rather than in anyone's chat frame: read it back with /df log
-- version before tagging.
function Changelog:CheckVersionAgreement()
    local toc = DF:GetVersion()
    local notes = self:NotesVersion()

    if toc and notes and toc ~= notes then
        DF:Log('version', 'TOC version is %s but the newest notes describe %s - one of them is stale', tostring(toc),
               tostring(notes))
    end
end

-- Opened after login when the running version is not the one last read.
--
-- An empty record counts as unseen, and deliberately so. Everyone updating to
-- the build that introduced this has no record at all, and skipping them as
-- though they were a fresh install would mean the notes never appeared for the
-- people they were written for.
function Changelog:ShowIfUnseen()
    self:CheckVersionAgreement()

    if not (ALWAYS_SHOW or self:HasUnseen()) then return end

    self:Show()
end
