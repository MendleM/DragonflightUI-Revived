local addonName, addonTable = ...;
local DF = LibStub('AceAddon-3.0'):GetAddon('DragonflightUI')

-- The on-screen answer to "why does my UI look like this?".
--
-- A /reload in combat cannot finish: the client refuses to let any addon move
-- or re-anchor protected frames mid-fight (see Helper:RunOutOfCombat). A line in
-- the chat frame is easy to miss in the middle of a pull, and without it the
-- half-built UI looks like the addon broke - so say it on screen, keep it there
-- for as long as it is true, and clear it the moment the setup finishes.
local LoadingState = {}
addonTable.LoadingState = LoadingState

local PANEL_WIDTH, PANEL_HEIGHT = 420, 74
local GOLD = '|cffffd100'

local function CreatePanel()
    if LoadingState.Panel then return LoadingState.Panel end

    -- No secure templates anywhere in here: this frame has to be creatable and
    -- showable while the player is in combat, which is the whole point of it.
    local panel = CreateFrame('Frame', 'DragonflightUILoadingState', UIParent, 'BackdropTemplate')
    panel:SetSize(PANEL_WIDTH, PANEL_HEIGHT)
    panel:SetPoint('TOP', UIParent, 'TOP', 0, -180)
    panel:SetFrameStrata('HIGH')
    panel:EnableMouse(true)
    panel:SetBackdrop({
        bgFile = 'Interface\\DialogFrame\\UI-DialogBox-Background-Dark',
        edgeFile = 'Interface\\Tooltips\\UI-Tooltip-Border',
        tile = true,
        tileSize = 32,
        edgeSize = 12,
        insets = {left = 3, right = 3, top = 3, bottom = 3}
    })
    panel:SetBackdropBorderColor(1, 0.82, 0, 0.9)
    panel:Hide()

    local title = panel:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
    title:SetPoint('TOPLEFT', panel, 'TOPLEFT', 14, -11)
    title:SetText('DragonflightUI')
    panel.Title = title

    local status = panel:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
    status:SetPoint('TOPLEFT', title, 'BOTTOMLEFT', 0, -4)
    status:SetPoint('RIGHT', panel, 'RIGHT', -14, 0)
    status:SetJustifyH('LEFT')
    status:SetWordWrap(true)
    panel.Status = status

    -- A progress strip rather than a spinner: no artwork to ship, and it reads
    -- as "waiting on something" without implying a percentage we do not know.
    local track = panel:CreateTexture(nil, 'ARTWORK')
    track:SetColorTexture(0, 0, 0, 0.6)
    track:SetPoint('BOTTOMLEFT', panel, 'BOTTOMLEFT', 14, 10)
    track:SetPoint('BOTTOMRIGHT', panel, 'BOTTOMRIGHT', -14, 10)
    track:SetHeight(3)
    panel.Track = track

    local fill = panel:CreateTexture(nil, 'OVERLAY')
    fill:SetColorTexture(1, 0.82, 0, 0.9)
    fill:SetHeight(3)
    fill:SetPoint('LEFT', track, 'LEFT', 0, 0)
    fill:SetWidth(60)
    panel.Fill = fill

    -- clicking it gets rid of it; the work carries on regardless
    panel:SetScript('OnMouseUp', function()
        LoadingState:Hide()
    end)

    panel:SetScript('OnEnter', function(self)
        GameTooltip:SetOwner(self, 'ANCHOR_BOTTOM')
        GameTooltip:AddLine('DragonflightUI setup')
        GameTooltip:AddLine(
            'The game does not allow addons to move action bars, unit frames or'
                .. ' other protected frames while you are in combat, so the rest of the'
                .. ' interface is applied as soon as the fight ends.', 1, 1, 1, true)
        GameTooltip:AddLine(' ')
        GameTooltip:AddLine('Click to dismiss.', 0.6, 0.6, 0.6)
        GameTooltip:Show()
    end)
    panel:SetScript('OnLeave', GameTooltip_Hide)

    LoadingState.Panel = panel
    return panel
end

-- The strip slides while there is something to wait for, and only then: an
-- animation that never stops reads as a hang.
local function SetAnimating(panel, animating)
    if not animating then
        panel:SetScript('OnUpdate', nil)
        panel.Fill:ClearAllPoints()
        panel.Fill:SetPoint('LEFT', panel.Track, 'LEFT', 0, 0)
        panel.Fill:SetWidth(panel.Track:GetWidth() or PANEL_WIDTH)
        return
    end

    panel.Elapsed = 0
    panel:SetScript('OnUpdate', function(self, elapsed)
        self.Elapsed = (self.Elapsed or 0) + elapsed

        local trackWidth = self.Track:GetWidth() or (PANEL_WIDTH - 28)
        local fillWidth = 60
        local travel = math.max(1, trackWidth - fillWidth)
        -- back and forth, two seconds each way
        local progress = math.abs(((self.Elapsed / 2) % 2) - 1)

        self.Fill:ClearAllPoints()
        self.Fill:SetWidth(fillWidth)
        self.Fill:SetPoint('LEFT', self.Track, 'LEFT', progress * travel, 0)
    end)
end

function LoadingState:ShowWaiting(labels)
    -- Disabled: UI is now fully aligned and functional during in-combat reloads
end

function LoadingState:ShowFinishing(labels)
end

function LoadingState:Complete()
end

function LoadingState:Hide()
    local panel = self.Panel
    if not panel then return end

    SetAnimating(panel, false)
    panel:Hide()
    panel:SetAlpha(1)
    GameTooltip_Hide()
end
