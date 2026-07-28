local DF = LibStub('AceAddon-3.0'):GetAddon('DragonflightUI')

-- Clique needs mouse motion to reach the unit frame underneath its bars and
-- text, so every region layered over a frame gets SetPropagateMouseMotion.
--
-- Every frame named here belongs to somebody else: Blizzard's unit frames
-- across four flavours, or DFUI's own reskin, and any one of them can be
-- absent on any given client. Unguarded that was fatal rather than untidy -
-- FuncOrWaitframe calls this bare, with no pcall, so a single missing frame
-- threw and every frame after the gap silently never got its propagation, and
-- Clique quietly stopped working on those. Skip what is not there instead.
local function propagate(obj)
    if obj and obj.SetPropagateMouseMotion then obj:SetPropagateMouseMotion(true) end
    return obj
end

local function propagateNamed(name) return propagate(_G[name]) end

-- A bar plus whichever of its text regions this client happens to use. The
-- classic reskin hangs DF-prefixed strings on the bar; the modern template
-- carries its own.
local function propagateBar(bar)
    if not propagate(bar) then return end

    propagate(bar.DFTextString)
    propagate(bar.DFLeftText)
    propagate(bar.DFRightText)
    propagate(bar.TextString)
    propagate(bar.LeftText)
    propagate(bar.RightText)
end

local function propagateMemberFrame(f)
    if not f then return end
    propagateBar(f.HealthBar)
    propagateBar(f.ManaBar)
end

function DF.Compatibility:Clique()
    -- print('DF.Compatibility:Clique()')
    local module = DF.API.Modules:GetModule('Unitframe')

    -- player
    local fixPlayer = function()
        propagateNamed('PlayerFrameHealthBar')
        propagateNamed('PlayerFrameManaBar')

        -- pet
        -- _G['PetName']:SetPropagateMouseMotion(true);
        -- _G['PetFrameMyHealPredictionBar']:SetPropagateMouseMotion(true);
        -- _G['PetFrameOtherHealPredictionBar']:SetPropagateMouseMotion(true);

        propagateNamed('PetFrameHealthBar')
        propagateNamed('PetFrameHealthBarText')
        propagateNamed('PetFrameHealthBarTextLeft')
        propagateNamed('PetFrameHealthBarTextRight')

        propagateNamed('PetFrameManaBar')
        propagateNamed('PetFrameManaBarText')
        propagateNamed('PetFrameManaBarTextLeft')
        propagateNamed('PetFrameManaBarTextRight')
    end
    fixPlayer()

    -- target
    local fixTarget = function()
        -- _G['TargetFrameShower']:SetPropagateMouseMotion(true);

        local textureFrame = propagateNamed('TargetFrameTextureFrame')
        propagateNamed('TargetFrameTextureFrameName')
        propagateNamed('TargetFrameTextureFrameLevelText')
        propagateNamed('TargetFrameTextureFrameUnconsciousText')

        propagateNamed('DragonflightUITargetFrameBackground')
        -- _G['DragonflightUITargetFrameBorder']:SetPropagateMouseMotion(true);

        propagateNamed('TargetFrameHealthBar')
        if textureFrame then
            propagate(textureFrame.HealthBarTextLeft)
            propagate(textureFrame.HealthBarTextRight)
        end

        propagateNamed('TargetFrameManaBar')

        propagateNamed('TargetFrameToTHealthBar')
        propagateNamed('TargetFrameToTManaBar')
    end
    fixTarget()

    C_Timer.After(5, fixTarget)

    -- focus
    local fixFocus = function()
        if not _G['FocusFrame'] then return end
        propagateNamed('FocusFrameHealthBarDummy')
        propagateNamed('FocusFrameManaBarDummy')

        propagateNamed('FocusFrameToTHealthBar')
        propagateNamed('FocusFrameToTManaBar')
    end

    if _G['FocusFrameHealthBarDummy'] and _G['FocusFrameManaBarDummy'] then
        fixFocus();
    elseif module and module.SubFocus and module.SubFocus.ChangeFocusFrame then
        -- DF.API.Modules:HookModuleFunction('Unitframe', 'ChangeFocusFrame', function()
        --     fixFocus();
        -- end)
        hooksecurefunc(module.SubFocus, 'ChangeFocusFrame', function()
            fixFocus();
        end)
    end

    -- party
    --
    -- Which frames exist is decided the same way SubModuleMixin:ChangePartyFrame
    -- decides it (Modules/Unitframe/Party.mixin.lua): classic named frames if
    -- they are there, otherwise the modern pooled ones. This used to branch on
    -- IsTBC, which put Era 1.15.9 down the classic path even though the
    -- Midnight-UI backport pools its party frames - so PartyMemberFrame1HealthBar
    -- was nil and the whole compatibility fix died on the first member.
    local fixParty = function()
        if _G['PartyMemberFrame1'] then
            for i = 1, 4 do
                propagateBar(_G['PartyMemberFrame' .. i .. 'HealthBar'])
                propagateBar(_G['PartyMemberFrame' .. i .. 'ManaBar'])
            end
            return
        end

        -- TBC prepatch names them; the pool is anonymous
        for i = 1, 4 do propagateMemberFrame(PartyFrame and PartyFrame['MemberFrame' .. i]) end

        if PartyFrame and PartyFrame.PartyMemberFramePool then
            for pf in PartyFrame.PartyMemberFramePool:EnumerateActive() do propagateMemberFrame(pf) end
        end
    end

    fixParty()

    -- Pooled frames are handed out and taken back as people join and leave, so
    -- a member who arrives later gets a frame that never had this applied.
    -- Same hook the party reskin uses to restyle them.
    if PartyFrame and PartyFrame.InitializePartyMemberFrames then
        hooksecurefunc(PartyFrame, 'InitializePartyMemberFrames', fixParty)
    end
end
