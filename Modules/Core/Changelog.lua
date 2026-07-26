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

local WIDTH, HEIGHT = 560, 520
local GOLD = '|cffffd100'
local WHITE = '|cffffffff'
local GREY = '|cff9d9d9d'
local BLUE = '|cff0070dd'

-- Blizzard's bullet, so it sits on the text baseline the way the game's own
-- lists do.
local BULLET = '|TInterface\\Scenarios\\ScenarioIcon-Dash:12:12:0:0|t '

local function BuildText()
    local out = {}

    for _, release in ipairs(DF.ChangelogData or {}) do
        out[#out + 1] = GOLD .. release.title .. '|r  ' .. GREY .. release.version .. '|r'
        if release.date then out[#out + 1] = GREY .. release.date .. '|r' end
        if release.intro then out[#out + 1] = '\n' .. WHITE .. release.intro .. '|r' end
        out[#out + 1] = ' '

        for _, section in ipairs(release.sections or {}) do
            local heading = BLUE .. section.title .. '|r'
            if section.new then heading = heading .. '  ' .. GOLD .. '(new)|r' end
            out[#out + 1] = heading

            for _, item in ipairs(section.items or {}) do
                out[#out + 1] = BULLET .. WHITE .. item .. '|r'
            end

            out[#out + 1] = ' '
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

    local title = f:CreateFontString(nil, 'OVERLAY', 'GameFontNormalLarge')
    title:SetPoint('TOP', f, 'TOP', 0, -18)
    title:SetText("What's New in DragonflightUI")

    local subtitle = f:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
    subtitle:SetPoint('TOP', title, 'BOTTOM', 0, -4)
    subtitle:SetText(GREY .. 'By Karl-Heinz Schneider  -  maintained by MendleM|r')

    local divider = f:CreateTexture(nil, 'ARTWORK')
    divider:SetColorTexture(1, 0.82, 0, 0.35)
    divider:SetHeight(1)
    divider:SetPoint('TOPLEFT', f, 'TOPLEFT', 20, -62)
    divider:SetPoint('TOPRIGHT', f, 'TOPRIGHT', -20, -62)

    local close = CreateFrame('Button', nil, f, 'UIPanelButtonTemplate')
    close:SetSize(120, 22)
    close:SetPoint('BOTTOM', f, 'BOTTOM', 0, 16)
    close:SetText(CLOSE or 'Close')
    close:SetScript('OnClick', function() Changelog:Hide() end)

    local scroll = CreateFrame('ScrollFrame', 'DragonflightUIWhatsNewScroll', f, 'UIPanelScrollFrameTemplate')
    scroll:SetPoint('TOPLEFT', f, 'TOPLEFT', 20, -72)
    scroll:SetPoint('BOTTOMRIGHT', f, 'BOTTOMRIGHT', -34, 48)

    local content = CreateFrame('Frame', nil, scroll)
    content:SetSize(WIDTH - 70, 1)
    scroll:SetScrollChild(content)

    local body = content:CreateFontString(nil, 'ARTWORK', 'GameFontHighlight')
    body:SetPoint('TOPLEFT', content, 'TOPLEFT', 0, 0)
    body:SetWidth(WIDTH - 70)
    body:SetJustifyH('LEFT')
    body:SetJustifyV('TOP')
    body:SetSpacing(3)
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
    if not self:HasUnseen() then return end

    self:Show()
end
