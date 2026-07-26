local addonName, addonTable = ...;
local DF = LibStub('AceAddon-3.0'):GetAddon('DragonflightUI')

-- The What's New window.
--
-- Opens by itself once after an update and stays until dismissed, then never
-- again for that version. Openable any time from Settings > General > What's
-- New.
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

local WIDTH, HEIGHT = 760, 640
local GOLD = '|cffffd100'
local WHITE = '|cffffffff'
local GREY = '|cff9d9d9d'
local BLUE = '|cff3fc7ff'
local GREEN = '|cff40dd60'

-- Plain ASCII, deliberately. This started as Interface\Scenarios\ScenarioIcon-
-- Dash, which draws nothing on Classic Era: Scenarios are a later asset folder
-- and nothing in the classic UI references it, so the bullets were invisible. A
-- dash renders in every font on every flavour.
local BULLET = GOLD .. '-|r  '

-- A rule drawn with the tooltip border texture, which exists everywhere.
local function AddRule(parent, anchorTo, offsetY)
    local rule = parent:CreateTexture(nil, 'ARTWORK')
    rule:SetColorTexture(1, 0.82, 0, 0.5)
    rule:SetHeight(1)
    rule:SetPoint('TOPLEFT', anchorTo, 'BOTTOMLEFT', 0, offsetY)
    rule:SetPoint('TOPRIGHT', anchorTo, 'BOTTOMRIGHT', 0, offsetY)
    return rule
end

local function BuildText()
    local out = {}

    for index, release in ipairs(DF.ChangelogData or {}) do
        if index > 1 then out[#out + 1] = ' ' end

        -- Release banner: title big and gold, version and date beneath it.
        out[#out + 1] = GOLD .. string.upper(release.title) .. '|r'
        out[#out + 1] = GREY .. release.version .. (release.date and ('   |   ' .. release.date) or '') .. '|r'

        if release.intro then
            out[#out + 1] = ' '
            out[#out + 1] = WHITE .. release.intro .. '|r'
        end

        for _, section in ipairs(release.sections or {}) do
            out[#out + 1] = ' '

            local heading = BLUE .. section.title .. '|r'
            if section.new then heading = heading .. '   ' .. GREEN .. '[NEW]|r' end
            out[#out + 1] = heading

            for _, item in ipairs(section.items or {}) do
                out[#out + 1] = BULLET .. WHITE .. item .. '|r'
            end
        end

        out[#out + 1] = ' '
    end

    return table.concat(out, '\n')
end

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

    -- A dark band behind the header, so the title reads as a banner rather than
    -- text floating at the top of a box.
    local band = f:CreateTexture(nil, 'BORDER')
    band:SetColorTexture(0, 0, 0, 0.45)
    band:SetPoint('TOPLEFT', f, 'TOPLEFT', 14, -14)
    band:SetPoint('TOPRIGHT', f, 'TOPRIGHT', -14, -14)
    band:SetHeight(92)

    local title = f:CreateFontString(nil, 'OVERLAY', 'GameFontNormalHuge')
    title:SetPoint('TOP', f, 'TOP', 0, -28)
    title:SetText(GOLD .. "What's New|r")

    local product = f:CreateFontString(nil, 'OVERLAY', 'GameFontNormalLarge')
    product:SetPoint('TOP', title, 'BOTTOM', 0, -6)
    product:SetText('DragonflightUI ' .. GREY .. DF:GetVersion() .. '|r')

    local subtitle = f:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
    subtitle:SetPoint('TOP', product, 'BOTTOM', 0, -6)
    subtitle:SetText(GREY .. 'Maintained by MendleM  -  originally by Karl-Heinz Schneider|r')

    AddRule(f, band, -2)

    local close = CreateFrame('Button', nil, f, 'UIPanelButtonTemplate')
    close:SetSize(160, 26)
    close:SetPoint('BOTTOM', f, 'BOTTOM', 0, 18)
    close:SetText(CLOSE or 'Close')
    close:SetScript('OnClick', function() Changelog:Hide() end)

    local footer = f:CreateFontString(nil, 'OVERLAY', 'GameFontDisableSmall')
    footer:SetPoint('BOTTOM', close, 'TOP', 0, 8)
    footer:SetText('Reopen any time from Settings > General > What\'s New')

    local scroll = CreateFrame('ScrollFrame', 'DragonflightUIWhatsNewScroll', f, 'UIPanelScrollFrameTemplate')
    scroll:SetPoint('TOPLEFT', f, 'TOPLEFT', 24, -118)
    scroll:SetPoint('BOTTOMRIGHT', f, 'BOTTOMRIGHT', -38, 74)

    local content = CreateFrame('Frame', nil, scroll)
    content:SetSize(WIDTH - 80, 1)
    scroll:SetScrollChild(content)

    local body = content:CreateFontString(nil, 'ARTWORK', 'GameFontHighlight')
    body:SetPoint('TOPLEFT', content, 'TOPLEFT', 0, 0)
    body:SetWidth(WIDTH - 80)
    body:SetJustifyH('LEFT')
    body:SetJustifyV('TOP')
    body:SetSpacing(3)
    -- wrapped bullet text lines up under itself rather than under the dash
    if body.SetIndentedWordWrap then body:SetIndentedWordWrap(true) end
    f.Body = body
    f.Content = content

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

    f.Body:SetText(BuildText())
    -- the scroll child has to be as tall as the text, or there is nothing to
    -- scroll through
    f.Content:SetHeight(math.max(f.Body:GetStringHeight() + 8, 1))

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
