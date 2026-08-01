local DF = LibStub('AceAddon-3.0'):GetAddon('DragonflightUI')
DragonflightUIStateHandlerMixin = {}

-- Whether a restricted snippet is allowed to show or hide this frame.
--
-- "Invalid frame handle" names the wrong thing. RestrictedFrames.lua:84 is
--
--   if (frame and (isProtected or (IsProtected(frame) or not InCombatLockdown())))
--       then return frame end
--   error("Invalid frame handle")
--
-- so the handle resolved perfectly well: the frame simply is not protected, and
-- we are in combat, and the restricted environment will not hand an unprotected
-- frame to a snippet mid-fight. A plain CreateFrame('FRAME', ...) - the XP bar,
-- the pet bar, the buff frame - registered as a HideFrame therefore throws once
-- per state change for as long as the fight lasts, which is where 418 of them
-- came from.
--
-- Guarding with `if f then` cannot help, and neither can pcall: the handle is
-- truthy and the throw happens inside the restricted call.
--
-- Show and Hide only NEED to be secure for protected frames. For anything else
-- they are ordinary calls that work in combat, from anywhere - so those go out
-- of the snippet, exactly as the alpha path already does.
local function CanSnippetTouch(frame)
    if not (frame and frame.IsProtected) then return false end
    return frame:IsProtected() and true or false
end

function DragonflightUIStateHandlerMixin:InitStateHandler(extraX, extraY)
    local handler = CreateFrame('FRAME', self:GetName() .. 'Handler', nil, 'SecureHandlerStateTemplate')
    self.DFStateHandler = handler

    handler:SetAttribute('forceShow', false)
    handler:SetAttribute('_onstate-vis', [[
        -- if not newstate then return end     
        local shower = self:GetFrameRef("Shower")
        if not shower then return end  
        -- print(shower:GetName(),'NewState',newstate)
        local shouldShow = true

        if newstate == "show" then
            shouldShow = true
        elseif newstate == "hide" then
           shouldShow = false         
        else 
           shouldShow = true
        end  

        if shouldShow then
            self:SetAttribute('forceShow', false)
            shower:UnregisterAutoHide()  
        else
            local forceShow = self:GetAttribute('forceShow')     

            if forceShow then  
                shouldShow = true    
                shower:RegisterAutoHide(0.1)
            else
                -- TODO unnecessary?
                shower:UnregisterAutoHide()  
            end
        end

        if shouldShow then 
            shower:Show();
        else
            shower:Hide();
        end
    ]])

    ----------
    extraX = extraX or 2
    extraY = extraY or 2
    ----------
    local shower = CreateFrame('FRAME', self:GetName() .. 'Shower', nil, 'SecureHandlerShowHideTemplate')
    shower:SetPoint('TOPLEFT', self, 'TOPLEFT', -extraX, extraY)
    shower:SetPoint('BOTTOMRIGHT', self, 'BOTTOMRIGHT', extraX, -extraY)

    shower:SetFrameRef('MainHandler', handler)

    self.DFShower = shower

    handler:SetFrameRef('Shower', shower)

    -- Index 1 is this frame, and it splits the same way as any other: the
    -- action bars are SecureFrameTemplate and stay in the snippet, the XP bar,
    -- the pet bar and the buff frame are plain frames and must not.
    self:SetHideFrame(self, 1)

    -- The insecure half follows the shower, which is what the snippet drives.
    shower:HookScript('OnShow', function() self:ApplyStateShown(true) end)
    shower:HookScript('OnHide', function() self:ApplyStateShown(false) end)

    shower:SetAttribute('_onshow', [[   
        local frameRef = self:GetFrameRef("MainHandler")

        local unitRef = frameRef:GetAttribute('UnitRef')
        local editModeActive = frameRef:GetAttribute('EditModeActive')

        if (unitRef and not UnitExists(unitRef)) and not editModeActive then
            return
        end

        for i=1,13 do
            local f = frameRef:GetFrameRef('HideFrame'..i)
            if f then f:Show() end
        end    
    ]])

    shower:SetAttribute('_onhide', [[     
         local frameRef = self:GetFrameRef("MainHandler")

        for i=1,13 do
            local f = frameRef:GetFrameRef('HideFrame'..i)
            if f then f:Hide() end
        end      
    ]])

    ----------
    local handlerTwo = CreateFrame('FRAME', self:GetName() .. 'HandlerOnEnterLeave', nil,
                                   'SecureHandlerEnterLeaveTemplate')
    handlerTwo:SetPoint('TOPLEFT', self, 'TOPLEFT', -extraX, extraY)
    handlerTwo:SetPoint('BOTTOMRIGHT', self, 'BOTTOMRIGHT', extraX, -extraY)
    handlerTwo:SetFrameLevel(math.max(self:GetFrameLevel() - 1, 0))
    handlerTwo:SetFrameStrata(self:GetFrameStrata())

    handlerTwo:SetFrameRef('MainHandler', handler)
    handlerTwo:SetFrameRef('Shower', shower)

    self.DFMouseHandler = handlerTwo

    handler:SetFrameRef('HandlerTwo', handlerTwo)
    shower:SetFrameRef('HandlerTwo', handlerTwo)

    handlerTwo:SetAttribute('_onenter', [[ 
        local frameRef = self:GetFrameRef("MainHandler")
        frameRef:SetAttribute('forceShow', true)

        local oldState = frameRef:GetAttribute('state-vis')
        frameRef:SetAttribute('state-vis', oldState)      
    ]])
    handlerTwo:SetAttribute('_onleave', [[]])

    --
    local handlerAlpha = CreateFrame('FRAME', self:GetName() .. 'HandlerAlpha', nil, 'SecureHandlerStateTemplate')
    self.DFAlphaHandler = handlerAlpha;

    -- Alpha is applied from ordinary code, not a restricted snippet.
    --
    -- This used to be an _onstate-alpha snippet that resolved frame handles -
    -- the frame itself, the main handler, and HideFrame1..13 - which is up to
    -- fifteen dereferences every time the driver fires. The driver is
    -- '[combat]combat;[nocombat]normal', registered for every frame with a
    -- state handler, so it fires on entering combat, always. Any of those
    -- handles that will not resolve throws "Invalid frame handle" out of
    -- RestrictedFrames, the snippet dies, and the alpha is never applied.
    -- ('if not frameRef then return end' does not help: it catches a ref that
    -- was never set, not a handle that fails to resolve when used.)
    --
    -- None of this needed to be secure. SetAlpha is not a protected call - it
    -- works on any frame, in combat, from anywhere. The snippet bought nothing
    -- and cost an error per frame per pull.
    handlerAlpha:HookScript('OnAttributeChanged', function(_, name, value)
        if name ~= 'state-alpha' then return end
        self:ApplyStateAlpha(value)
    end)
end

function DragonflightUIStateHandlerMixin:ApplyStateAlpha(newstate)
    local newAlpha = 1.0

    if newstate == 'combat' then
        newAlpha = self:GetAttribute('alphaCombat') or 0.5
    elseif newstate == 'normal' then
        newAlpha = self:GetAttribute('alphaNormal') or 0.8
    end

    self:SetAlpha(newAlpha)

    -- the frames this one speaks for: Blizzard's containers are anchored to
    -- ours rather than parented, so they need the alpha applied to them too
    if self.DFHideFrames then
        for _, f in pairs(self.DFHideFrames) do f:SetAlpha(newAlpha) end
    end
end

function DragonflightUIStateHandlerMixin:SetHideFrame(frame, index)
    if not frame then return end

    -- Every managed frame, for the alpha path, which is not secure work.
    self.DFHideFrames = self.DFHideFrames or {}
    self.DFHideFrames[index] = frame

    -- Showing and hiding splits by whether the snippet is allowed to: a
    -- protected frame keeps the secure ref, because in combat only the snippet
    -- can move it. An unprotected one is handled from ordinary code, because
    -- the snippet would throw on it and does not need to be involved.
    if CanSnippetTouch(frame) then
        self.DFStateHandler:SetFrameRef('HideFrame' .. index, frame)
    else
        self.DFInsecureHideFrames = self.DFInsecureHideFrames or {}
        self.DFInsecureHideFrames[index] = frame
    end
end

-- The insecure half of show/hide, driven by the shower's own visibility so the
-- two halves always agree.
function DragonflightUIStateHandlerMixin:ApplyStateShown(shown)
    if not self.DFInsecureHideFrames then return end

    for _, f in pairs(self.DFInsecureHideFrames) do
        -- Re-checked rather than trusted from registration time: a frame that
        -- has become protected since is the snippet's to move, and ours to
        -- leave alone in combat.
        if f and not (InCombatLockdown() and CanSnippetTouch(f)) then f:SetShown(shown) end
    end
end

function DragonflightUIStateHandlerMixin:SetUnit(unit)
    self.DFStateHandler:SetAttribute('UnitRef', unit)
end

local visConditionalTable = {}
do
    visConditionalTable['hideAlways'] = 'hide'
    visConditionalTable['hideCombat'] = '[combat]hide'
    visConditionalTable['hideOutOfCombat'] = '[nocombat]hide'
    visConditionalTable['hidePet'] = '[pet]hide'
    visConditionalTable['hideVehicle'] = '[vehicleui]hide'
    visConditionalTable['hideNoPet'] = '[nopet]hide'
    visConditionalTable['hideStance'] = ''
    visConditionalTable['hideStealth'] = '[stealth]hide'
    visConditionalTable['hideNoStealth'] = '[nostealth]hide'
    visConditionalTable['hideBattlePet'] = '[petbattle]hide'
end

function DragonflightUIStateHandlerMixin:UpdateStateHandler(state, activateOverride)
    local handler = self.DFStateHandler
    -- handler:SetAttribute('EditModeActive', state.EditModeActive)
    handler:SetAttribute('EditModeActive', false)

    local driverTable = {}

    if state.EditModeActive then table.insert(driverTable, 'show') end
    if activateOverride ~= nil then
        if not activateOverride then table.insert(driverTable, 'hide') end
    else
        if state.activate ~= nil and not state.activate then table.insert(driverTable, 'hide') end
    end

    if state.hideCustom then
        table.insert(driverTable, state.hideCustomCond)
    else
        for k, v in pairs(visConditionalTable) do
            if state[k] then
                if k == 'hideStance' then
                    for i = 1, 6 do table.insert(driverTable, ('[stance:%d]hide'):format(i)) end
                else
                    table.insert(driverTable, visConditionalTable[k])
                end
            end
        end
        table.insert(driverTable, 'show')
    end

    local driver = table.concat(driverTable, ';')
    local result, target = SecureCmdOptionParse(driver)

    -- print(self:GetName(), result)
    local same = false;
    if result == 'show' and self:IsVisible() then
        same = true;
    elseif result == 'hide' and not self:IsVisible() then
        same = true;
    end

    if driver == self.DriverCache and same then
        self:UpdateAlphaHandler(state)
        return;
    end
    self.DriverCache = driver;
    UnregisterStateDriver(handler, 'vis')

    -- DevTools_Dump(driver)
    if #driverTable > 1 or state.hideCustom then
        --
        -- print(self:GetName(), driver)
        -- print('result:', result)
    end
    RegisterStateDriver(handler, 'vis', driver)
    handler:SetAttribute('state-vis', 'hide')
    handler:SetAttribute('state-vis', 'show')
    handler:SetAttribute('state-vis', result)

    local mouseHandler = self.DFMouseHandler
    if state.showMouseover and not state.EditModeActive and not (state.activate ~= nil and not state.activate) then
        mouseHandler:Show()
    else
        mouseHandler:Hide()
    end

    self:UpdateAlphaHandler(state)
end

function DragonflightUIStateHandlerMixin:UpdateAlphaHandler(state)
    -- 
    local handler = self.DFAlphaHandler
    self:SetAttribute('alphaNormal', state.alphaNormal)
    self:SetAttribute('alphaCombat', state.alphaCombat)
    -- print(self:GetName(), state.alphaNormal, state.alphaCombat)

    local driverTable = {}

    if state.EditModeActive then table.insert(driverTable, 'fullAlpha') end

    table.insert(driverTable, '[combat]combat')
    table.insert(driverTable, '[nocombat]normal')

    table.insert(driverTable, 'fullAlpha') -- fallback

    local driver = table.concat(driverTable, ';')
    local result, target = SecureCmdOptionParse(driver)

    if driver == self.AlphaDriverCache then
        handler:SetAttribute('state-alpha', 'update')
        handler:SetAttribute('state-alpha', result)
        return;
    end
    self.AlphaDriverCache = driver;

    UnregisterStateDriver(handler, 'alpha')
    RegisterStateDriver(handler, 'alpha', driver)
    handler:SetAttribute('state-alpha', 'fullAlpha')
    handler:SetAttribute('state-alpha', result)
end

function DragonflightUIStateHandlerMixin:AddStateTable(Module, optionTable, sub, displayName, getDefaultStr)
    local popupName = sub and (sub .. "CustomVisCondition") or (displayName .. "CustomVisCondition")

    local macroOptions = [[
        This option evaluates macro conditionals, which have to return '|cff8080ffshow|r' or '|cff8080ffhide|r', e.g.:

        1) |cff8080ff[@target,exists]show; hide|r
        2) |cff8080ff[@target,exists,help,raid] show; hide|r
        3) |cff8080ff[swimming] hide; show|r

        For more Infos see:
            |cff8080ff https://warcraft.wiki.gg/wiki/Macro_conditionals|r
        ]]

    local Validate = function(t)
        local result, target = SecureCmdOptionParse(t)
        if result ~= 'show' and result ~= 'hide' and result ~= '' then
            Module:Print('|cFFFF0000Error: Custom Condition for ' .. displayName .. ' does not return ' ..
                             [['show' or 'hide'!|r]])
            return
        end

        -- valid
        Module:Print('Set Custom Condition for ' .. displayName .. ': \'' .. t .. '\'')
        Module:Print('Current Value: ' .. result)

        -- valid, reset
        return true, true;
    end

    StaticPopupDialogs[popupName] = {
        text = 'Set Custom Condition for ' .. displayName .. '\n\n' .. macroOptions,
        button1 = ACCEPT,
        button2 = CANCEL,
        OnShow = function(self, data)
            self.editBox = self.editBox or self.EditBox
            local db = Module.db.profile
            local dbSub = sub and db[sub] or db

            self.editBox:SetText(dbSub.hideCustomCond)
        end,
        OnAccept = function(self, data, data2)
            local text = self.editBox:GetText()
            local result, target = SecureCmdOptionParse(text)
            if result ~= 'show' and result ~= 'hide' and result ~= '' then
                Module:Print('|cFFFF0000Error: Custom Condition for ' .. displayName .. ' does not return ' ..
                                 [['show' or 'hide'!|r]])
                return
            end
            -- do whatever you want with it      
            if sub then
                Module:SetOption({sub, 'hideCustomCond'}, text)
            else
                Module:SetOption({'hideCustomCond'}, text)
            end
            Module:Print('Set Custom Condition for ' .. displayName .. ': \'' .. text .. '\'')
            Module:Print('Current Value: ' .. result)
        end,
        hasEditBox = true,
        editBoxWidth = 666
    }

    local function cond(str)
        return 'macro condition: ' .. '|cff8080ff' .. str .. '|r'
    end

    local extraOptions = {
        headerVis = {type = 'header', name = 'Visibility', desc = '', order = 100, isExpanded = true, editmode = true},
        alphaNormal = {
            type = 'range',
            name = 'Alpha',
            desc = 'Frame alpha while non-combat.' .. getDefaultStr('alphaNormal', sub),
            min = 0.1,
            max = 1,
            bigStep = 0.01,
            order = 70,
            group = 'headerVis',
            new = true,
            editmode = true
        },
        alphaCombat = {
            type = 'range',
            name = 'Alpha (In Combat)',
            desc = 'Frame alpha while in combat.' .. getDefaultStr('alphaCombat', sub),
            min = 0.1,
            max = 1,
            bigStep = 0.01,
            order = 70.5,
            group = 'headerVis',
            new = true,
            editmode = true
        },
        showMouseover = {
            type = 'toggle',
            name = 'Show On Mouseover',
            desc = 'This (temporarily) overrides the hide conditions below when mouseover.' ..
                getDefaultStr('showMouseover', sub),
            order = 100.5,
            group = 'headerVis',
            new = false,
            editmode = true
        },
        hideAlways = {
            type = 'toggle',
            name = 'Always Hide',
            desc = '' .. cond('hide') .. getDefaultStr('hideAlways', sub),
            order = 101,
            group = 'headerVis',
            new = false,
            editmode = true
        },
        hideCombat = {
            type = 'toggle',
            name = 'Hide In Combat',
            desc = '' .. cond('[combat]hide; show') .. getDefaultStr('hideCombat', sub),
            order = 102,
            group = 'headerVis',
            new = false,
            editmode = true
        },
        hideOutOfCombat = {
            type = 'toggle',
            name = 'Hide Out Of Combat',
            desc = '' .. cond('[nocombat]hide; show') .. getDefaultStr('hideOutOfCombat', sub),
            order = 103,
            group = 'headerVis',
            new = false,
            editmode = true
        },
        hideVehicle = {
            type = 'toggle',
            name = 'Hide With VehicleUI',
            desc = '' .. cond('[vehicleui]hide; show') .. getDefaultStr('hideVehicle', sub),
            order = 103.5,
            group = 'headerVis',
            new = false,
            editmode = true
        },
        hidePet = {
            type = 'toggle',
            name = 'Hide With Pet',
            desc = '' .. cond('[pet]hide; show') .. getDefaultStr('hidePet', sub),
            order = 104,
            group = 'headerVis',
            new = false,
            editmode = true
        },
        hideNoPet = {
            type = 'toggle',
            name = 'Hide Without Pet',
            desc = '' .. cond('[nopet]hide; show') .. getDefaultStr('hideNoPet', sub),
            order = 105,
            group = 'headerVis',
            new = false,
            editmode = true
        },
        hideStance = {
            type = 'toggle',
            name = 'Hide Without Stance/Form',
            desc = '' .. cond('[stance:X]hide; show') .. ' (X=1..6)' .. getDefaultStr('hideStance', sub),
            order = 106,
            group = 'headerVis',
            new = false,
            editmode = true
        },
        hideStealth = {
            type = 'toggle',
            name = 'Hide In Stealth',
            desc = '' .. cond('[stealth]hide; show') .. getDefaultStr('hideStealth', sub),
            order = 107,
            group = 'headerVis',
            new = false,
            editmode = true
        },
        hideNoStealth = {
            type = 'toggle',
            name = 'Hide Outside Stealth',
            desc = '' .. cond('[nostealth]hide; show') .. getDefaultStr('hideNoStealth', sub),
            order = 108,
            group = 'headerVis',
            new = false,
            editmode = true
        },
        hideBattlePet = {
            type = 'toggle',
            name = 'Hide In Pet Battle',
            desc = '' .. cond('[petbattle]hide; show') .. getDefaultStr('hideBattlePet', sub),
            order = 108.5,
            group = 'headerVis',
            new = false,
            editmode = true
        },
        hideCustom = {
            type = 'toggle',
            name = 'Use Custom Condition',
            desc = 'Same syntax as macro conditionals\n|cFFFF0000Note: This will disable all of the above settings!|r' ..
                getDefaultStr('hideCustom', sub),
            order = 109,
            group = 'headerVis',
            new = false,
            editmode = true
        },
        hideCustomCond = {
            type = 'editbox',
            name = 'Set Custom Condition',
            desc = "Uses macro conditional syntax, but instead of the spell name the |cff8080ff'return'|r should be |cff8080ffshow|r to show the frame, or |cff8080ffhide|r to hide it." ..
                '\n\nExample: \n|cff8080ff[combat]show;[@target,exists]show;hide|r ' ..
                '\n(This shows the frame in combat, or if you have a target)',
            Validate = Validate,
            order = 109.5,
            group = 'headerVis',
            editmode = true
        }
    }
    for k, v in pairs(extraOptions) do
        --
        optionTable.args[k] = v
    end
end
