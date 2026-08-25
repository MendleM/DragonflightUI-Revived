local addonName, addonTable = ...;
local Helper = addonTable.Helper;
---@diagnostic disable: undefined-global
local DF = LibStub('AceAddon-3.0'):GetAddon('DragonflightUI')

DragonflightUITalentsPanelMixin = {}

local base = 'Interface\\Addons\\DragonflightUI\\Textures\\UI\\'

TALENT_TOOLTIP_RESETTALENTGROUP = "Click to reset your preview talent points."
TALENT_TOOLTIP_LEARNTALENTGROUP = "Click to finalize your preview talent points."

local TALENT_INFO = {
    ["default"] = {
        [1] = {color = {r = 1.0, g = 0.72, b = 0.1}},
        [2] = {color = {r = 1.0, g = 0.0, b = 0.0}},
        [3] = {color = {r = 0.3, g = 0.5, b = 1.0}}
    },

    ["DEATHKNIGHT"] = {
        [1] = {
            -- Blood
            color = {r = 1.0, g = 0.0, b = 0.0}
        },
        [2] = {
            -- Frost
            color = {r = 0.3, g = 0.5, b = 1.0}
        },
        [3] = {
            -- Unholy
            color = {r = 0.2, g = 0.8, b = 0.2}
        }
    },

    ["DRUID"] = {
        [1] = {
            -- Balance
            color = {r = 0.8, g = 0.3, b = 0.8}
        },
        [2] = {
            -- Feral
            color = {r = 1.0, g = 0.0, b = 0.0}
        },
        [3] = {
            -- Restoration
            color = {r = 0.4, g = 0.8, b = 0.2}
        }
    },

    ["HUNTER"] = {
        [1] = {
            -- Beast Mastery
            color = {r = 1.0, g = 0.0, b = 0.3}
        },
        [2] = {
            -- Marksmanship
            color = {r = 0.3, g = 0.6, b = 1.0}
        },
        [3] = {
            -- Survival
            color = {r = 1.0, g = 0.6, b = 0.0}
        }
    },

    ["MAGE"] = {
        [1] = {
            -- Arcane
            color = {r = 0.7, g = 0.2, b = 1.0}
        },
        [2] = {
            -- Fire
            color = {r = 1.0, g = 0.5, b = 0.0}
        },
        [3] = {
            -- Frost
            color = {r = 0.3, g = 0.6, b = 1.0}
        }
    },

    ["PALADIN"] = {
        [1] = {
            -- Holy
            color = {r = 1.0, g = 0.5, b = 0.0}
        },
        [2] = {
            -- Protection
            color = {r = 0.3, g = 0.5, b = 1.0}
        },
        [3] = {
            -- Retribution
            color = {r = 1.0, g = 0.0, b = 0.0}
        }
    },

    ["PRIEST"] = {
        [1] = {
            -- Discipline
            color = {r = 1.0, g = 0.5, b = 0.0}
        },
        [2] = {
            -- Holy
            color = {r = 0.6, g = 0.6, b = 1.0}
        },
        [3] = {
            -- Shadow
            color = {r = 0.7, g = 0.4, b = 0.8}
        }
    },

    ["ROGUE"] = {
        [1] = {
            -- Assassination
            color = {r = 0.5, g = 0.8, b = 0.5}
        },
        [2] = {
            -- Combat
            color = {r = 1.0, g = 0.5, b = 0.0}
        },
        [3] = {
            -- Subtlety
            color = {r = 0.3, g = 0.5, b = 1.0}
        }
    },

    ["SHAMAN"] = {
        [1] = {
            -- Elemental
            color = {r = 0.8, g = 0.2, b = 0.8}
        },
        [2] = {
            -- Enhancement
            color = {r = 0.3, g = 0.5, b = 1.0}
        },
        [3] = {
            -- Restoration
            color = {r = 0.2, g = 0.8, b = 0.4}
        }
    },

    ["WARLOCK"] = {
        [1] = {
            -- Affliction
            color = {r = 0.0, g = 1.0, b = 0.6}
        },
        [2] = {
            -- Demonology
            color = {r = 1.0, g = 0.0, b = 0.0}
        },
        [3] = {
            -- Destruction
            color = {r = 1.0, g = 0.5, b = 0.0}
        }
    },

    ["WARRIOR"] = {
        [1] = {
            -- Arms
            color = {r = 1.0, g = 0.72, b = 0.1}
        },
        [2] = {
            -- Fury
            color = {r = 1.0, g = 0.0, b = 0.0}
        },
        [3] = {
            -- Protection
            color = {r = 0.3, g = 0.5, b = 1.0}
        }
    },

    ["PET_409"] = {
        -- Tenacity
        [1] = {color = {r = 1.0, g = 0.1, b = 1.0}}
    },

    ["PET_410"] = {
        -- Ferocity
        [1] = {color = {r = 1.0, g = 0.0, b = 0.0}}
    },

    ["PET_411"] = {
        -- Cunning
        [1] = {color = {r = 0.0, g = 0.6, b = 1.0}}
    }
};

local TALENT_BRANCH_TEXTURECOORDS = {
    up = {[1] = {0.12890625, 0.25390625, 0, 0.484375}, [-1] = {0.12890625, 0.25390625, 0.515625, 1.0}},
    down = {[1] = {0, 0.125, 0, 0.484375}, [-1] = {0, 0.125, 0.515625, 1.0}},
    left = {[1] = {0.2578125, 0.3828125, 0, 0.5}, [-1] = {0.2578125, 0.3828125, 0.5, 1.0}},
    right = {[1] = {0.2578125, 0.3828125, 0, 0.5}, [-1] = {0.2578125, 0.3828125, 0.5, 1.0}},
    topright = {[1] = {0.515625, 0.640625, 0, 0.5}, [-1] = {0.515625, 0.640625, 0.5, 1.0}},
    topleft = {[1] = {0.640625, 0.515625, 0, 0.5}, [-1] = {0.640625, 0.515625, 0.5, 1.0}},
    bottomright = {[1] = {0.38671875, 0.51171875, 0, 0.5}, [-1] = {0.38671875, 0.51171875, 0.5, 1.0}},
    bottomleft = {[1] = {0.51171875, 0.38671875, 0, 0.5}, [-1] = {0.51171875, 0.38671875, 0.5, 1.0}},
    tdown = {[1] = {0.64453125, 0.76953125, 0, 0.5}, [-1] = {0.64453125, 0.76953125, 0.5, 1.0}},
    tup = {[1] = {0.7734375, 0.8984375, 0, 0.5}, [-1] = {0.7734375, 0.8984375, 0.5, 1.0}}
};

local TALENT_ARROW_TEXTURECOORDS = {
    top = {[1] = {0, 0.5, 0, 0.5}, [-1] = {0, 0.5, 0.5, 1.0}},
    right = {[1] = {1.0, 0.5, 0, 0.5}, [-1] = {1.0, 0.5, 0.5, 1.0}},
    left = {[1] = {0.5, 1.0, 0, 0.5}, [-1] = {0.5, 1.0, 0.5, 1.0}}
};

local talentRows = 7;
if DF.API.Version.IsTBC then
    talentRows = 9;
elseif DF.API.Version.IsWotlk then
    talentRows = 11;
end

function DragonflightUITalentsPanelMixin:GetTalentRows()
    return talentRows
end

function DragonflightUITalentsPanelMixin:OnLoad()
    self.TALENT_BRANCH_ARRAY = {};
    self.BUTTON_ARRAY = {}
    for i = 1, talentRows do
        self.TALENT_BRANCH_ARRAY[i] = {};
        self.BUTTON_ARRAY[i] = {};
        for j = 1, 4 do
            self.TALENT_BRANCH_ARRAY[i][j] = {
                id = nil,
                up = 0,
                left = 0,
                right = 0,
                down = 0,
                leftArrow = 0,
                rightArrow = 0,
                topArrow = 0
            };
            self.BUTTON_ARRAY[i][j] = nil
        end
    end

    self.ArrowIndex = 1
    self.BranchIndex = 1
end

function DragonflightUITalentsPanelMixin:OnShow()
end

function DragonflightUITalentsPanelMixin:OnHide()
end

function DragonflightUITalentsPanelMixin:OnEvent()
end

function DragonflightUITalentsPanelMixin:Init(id)
    self.ID = id
    local panel = self:GetName()

    for i = 1, 28 do
        local buttonName = panel .. 'Talent' .. i
        local button = _G[buttonName]

        if button then
            button.panelID = id
            button:SetID(i)
            button.talentID = i

            local anchorFrame = CreateFrame('FRAME', nil, self)
            anchorFrame:SetSize(30, 30)
            anchorFrame:SetPoint('CENTER', self, 'CENTER', 0, 0)

            button:ClearAllPoints()
            button:SetPoint('CENTER', anchorFrame, 'CENTER', 0, 0)

            button.anchorFrame = anchorFrame

            local function setupTooltip()
                local talentInfoQuery = {};
                talentInfoQuery.specializationIndex = id;
                talentInfoQuery.talentIndex = i;
                talentInfoQuery.isInspect = false;
                talentInfoQuery.isPet = false;
                talentInfoQuery.groupIndex = DragonflightUITalentsFrameMixin:GetSelectedSpec();

                local talentInfo = C_SpecializationInfo and C_SpecializationInfo.GetTalentInfo and
                                       C_SpecializationInfo.GetTalentInfo(talentInfoQuery);
                if talentInfo then
                    GameTooltip:SetTalent(talentInfo.talentID, talentInfoQuery.isInspect, talentInfoQuery.isPet,
                                          talentInfoQuery.groupIndex);
                end
            end

            button:SetScript('OnEnter', function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
                setupTooltip()

                C_Timer.After(0, function()
                    if (GameTooltip:IsOwned(self)) then setupTooltip() end
                end)

                C_Timer.After(1, function()
                    if (GameTooltip:IsOwned(self)) then setupTooltip() end
                end)
            end)

            button:SetScript('OnEvent', function(self, event, ...)
                if (GameTooltip:IsOwned(self)) then GameTooltip:SetTalent(id, i) end
            end)

            button:SetScript('OnClick', function(self, btn)
                DragonflightUITalentsPanelMixin:ButtonOnClick(self, btn)
            end)

            button:RegisterEvent("PREVIEW_TALENT_POINTS_CHANGED");
            button:RegisterEvent("PLAYER_TALENT_UPDATE");
            button:RegisterEvent("PET_TALENT_UPDATE");
        end
    end

    self.RoleIcon = _G[panel .. 'RoleIcon']
    self.RoleIcon2 = _G[panel .. 'RoleIcon2']
    DragonflightUITalentsPanelMixin:UpdateRoleIcon(self, id)
end

function DragonflightUITalentsPanelMixin:ButtonOnClick(self, button)
    local panelID = self.panelID
    local talentID = self.talentID
    local selectedSpec = DragonflightUITalentsFrameMixin:GetSelectedSpec()

    if (IsModifiedClick("CHATLINK")) then
        local link = GetTalentLink(panelID, talentID)
        if link then ChatEdit_InsertLink(link) end
    else
        if button == 'LeftButton' then
            if (GetCVarBool("previewTalentsOption")) then
                AddPreviewTalentPoints(panelID, talentID, 1, false, selectedSpec)
            else
                ---@diagnostic disable-next-line: redundant-parameter
                LearnTalent(panelID, talentID)
            end
        elseif button == 'RightButton' then
            if (GetCVarBool("previewTalentsOption")) then
                AddPreviewTalentPoints(panelID, talentID, -1, false, selectedSpec)
            end
        end
        if PlayerTalentFrame.UpdateDFHeaderText then
            PlayerTalentFrame.UpdateDFHeaderText()
        end
    end
end

function DragonflightUITalentsPanelMixin:GetUnspetTalentPoints(spec)
    local level = UnitLevel('player')
    local maxPoints = level - 9

    for i = 1, 3 do
        local id, name, description, iconTexture, pointsSpent, background, previewPointsSpent, isUnlocked =
            GetTalentTabInfo(i, false, false, spec)
        if pointsSpent and previewPointsSpent then
            maxPoints = maxPoints - pointsSpent - previewPointsSpent
        end
    end
    return maxPoints
end

function DragonflightUITalentsPanelMixin:Refresh()
    local panelID = self.ID
    local panel = self:GetName()
    local preview = GetCVarBool("previewTalentsOption");
    local selectedSpec = DragonflightUITalentsFrameMixin:GetSelectedSpec()
    local activeSpec = DragonflightUITalentsFrameMixin:GetActiveSpec()

    local id, name, description, iconTexture, pointsSpent, background, previewPointsSpent, isUnlocked =
        GetTalentTabInfo(panelID, false, false, selectedSpec)
    pointsSpent = pointsSpent or 0
    previewPointsSpent = previewPointsSpent or 0
    local tabPointsSpent = pointsSpent + previewPointsSpent

    local isActiveTalentGroup = selectedSpec == activeSpec

    -- header
    do
        local headerName = _G[panel .. 'Name']
        if headerName and name then headerName:SetText(name) end

        local headerIcon = _G[panel .. 'HeaderIconIcon']
        if headerIcon and iconTexture then headerIcon:SetTexture(iconTexture) end

        local headerPointsSpent = _G[panel .. 'HeaderIconPointsSpent']
        if headerPointsSpent then headerPointsSpent:SetText(pointsSpent + previewPointsSpent) end
    end

    -- header color
    do
        local talentInfo;
        local classDisplayName, class = UnitClass("player");
        talentInfo = TALENT_INFO[class] or TALENT_INFO["default"];

        local color = talentInfo and talentInfo[panelID] and talentInfo[panelID].color;
        if (color) then
            if _G[panel .. 'HeaderBackground'] then
                _G[panel .. 'HeaderBackground']:SetVertexColor(color.r, color.g, color.b);
            end
            if (_G[panel .. 'Summary']) then
                _G[panel .. 'SummaryBorder']:SetVertexColor(color.r, color.g, color.b);
                _G[panel .. 'SummaryIconGlow']:SetVertexColor(color.r, color.g, color.b);
            end
        else
            if _G[panel .. 'HeaderBackground'] then
                _G[panel .. 'HeaderBackground']:SetVertexColor(1, 1, 1);
            end
        end
    end

    -- background
    do
        local bg = _G[panel .. 'BackgroundTopLeft']
        if bg and background then
            bg:SetTexture(background)
            bg:Show()

            local bgBase = "Interface\\TalentFrame\\" .. background .. "-";

            local backgroundPiece = _G[panel .. "BackgroundTopLeft"];
            if backgroundPiece then
                backgroundPiece:SetTexture(bgBase .. "TopLeft");
                SetDesaturation(backgroundPiece, not isActiveTalentGroup);
            end
            backgroundPiece = _G[panel .. "BackgroundTopRight"];
            if backgroundPiece then
                backgroundPiece:SetTexture(bgBase .. "TopRight");
                SetDesaturation(backgroundPiece, not isActiveTalentGroup);
            end
            backgroundPiece = _G[panel .. "BackgroundBottomLeft"];
            if backgroundPiece then
                backgroundPiece:SetTexture(bgBase .. "BottomLeft");
                SetDesaturation(backgroundPiece, not isActiveTalentGroup);
            end
            backgroundPiece = _G[panel .. "BackgroundBottomRight"];
            if backgroundPiece then
                backgroundPiece:SetTexture(bgBase .. "BottomRight");
                SetDesaturation(backgroundPiece, not isActiveTalentGroup);
            end
        end
    end

    -- talents
    do
        local numTalents = GetNumTalents(panelID);
        local unspentTalentPoints = DragonflightUITalentsPanelMixin:GetUnspetTalentPoints(selectedSpec)

        self:ResetBranches()
        for i = 1, 28 do
            local buttonName = panel .. 'Talent' .. i
            local button = _G[buttonName]
            local forceDesaturated, tierUnlocked;
            if button and i <= numTalents then
                local name, iconPath, tier, column, currentRank, maxRank, meetsPrereq, previewRank, meetsPreviewPrereq,
                      isExceptional, goldBorder = GetTalentInfo(panelID, i, false, false, selectedSpec);

                if name then
                    local displayRank;
                    if (preview) then
                        displayRank = previewRank;
                    else
                        displayRank = currentRank;
                    end

                    _G[buttonName .. 'Rank']:SetText(displayRank)

                    self.BUTTON_ARRAY[tier][column] = button
                    self.TALENT_BRANCH_ARRAY[tier][column].id = i

                    -- position
                    do
                        local offsetX = 20
                        local offsetY = -52
                        local size = 46

                        local x = ((column - 1) * size) + offsetX
                        local y = -((tier - 1) * size) + offsetY

                        local anchor = button.anchorFrame
                        if anchor then
                            anchor:ClearAllPoints()
                            anchor:SetPoint('TOPLEFT', self, 'TOPLEFT', x, y)
                        end

                        button:SetScale(30 / 37)
                    end

                    if (unspentTalentPoints <= 0 or not isActiveTalentGroup) and displayRank == 0 then
                        forceDesaturated = 1;
                    else
                        forceDesaturated = nil;
                    end

                    local tierUnlocked;
                    if (((tier - 1) * (PLAYER_TALENTS_PER_TIER or 5) <= tabPointsSpent)) then
                        tierUnlocked = 1;
                    else
                        tierUnlocked = nil;
                    end

                    SetItemButtonTexture(button, iconPath);

                    local prereqsSet = self:SetPrereqs(tier, column, forceDesaturated, tierUnlocked, preview,
                                                       GetTalentPrereqs(panelID, i, false, false, selectedSpec))
                    if (prereqsSet and ((preview and meetsPreviewPrereq) or (not preview and meetsPrereq))) then
                        SetItemButtonDesaturated(button, nil);

                        if (displayRank < maxRank) then
                            _G[buttonName .. "Slot"]:SetVertexColor(0.1, 1.0, 0.1);
                            _G[buttonName .. "Rank"]:SetTextColor(GREEN_FONT_COLOR.r, GREEN_FONT_COLOR.g,
                                                                  GREEN_FONT_COLOR.b);
                        else
                            _G[buttonName .. "Slot"]:SetVertexColor(1.0, 0.82, 0);
                            _G[buttonName .. "Rank"]:SetTextColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g,
                                                                  NORMAL_FONT_COLOR.b);
                        end
                        _G[buttonName .. "RankBorder"]:Show();
                        _G[buttonName .. "Rank"]:Show();
                    else
                        SetItemButtonDesaturated(button, 1, 0.65, 0.65, 0.65);
                        _G[buttonName .. "Slot"]:SetVertexColor(0.5, 0.5, 0.5);
                        if (displayRank == 0) then
                            _G[buttonName .. "RankBorder"]:Hide();
                            _G[buttonName .. "Rank"]:Hide();
                        else
                            _G[buttonName .. "RankBorder"]:SetVertexColor(0.5, 0.5, 0.5);
                            _G[buttonName .. "Rank"]:SetTextColor(GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g,
                                                                  GRAY_FONT_COLOR.b);
                        end
                    end

                    button:Show()
                else
                    button:Hide()
                end
            elseif button then
                button:Hide()
            end
        end

        self.ArrowIndex = 1
        self.BranchIndex = 1

        local node;
        local xOffset, yOffset;
        local talentButtonSize = 30
        local initialOffsetX = 20
        local initialOffsetY = 52
        local buttonSpacingX = 46
        local buttonSpacingY = 46

        for i = 1, talentRows do
            for j = 1, 4 do
                node = self.TALENT_BRANCH_ARRAY[i][j];

                xOffset = ((j - 1) * buttonSpacingX) + initialOffsetX + (self.branchOffsetX or 0);
                yOffset = -((i - 1) * buttonSpacingY) - initialOffsetY + (self.branchOffsetY or 0);

                if (node.down ~= 0) then
                    self:SetBranchTexture(i, j, TALENT_BRANCH_TEXTURECOORDS["down"][node.down], xOffset,
                                          yOffset - talentButtonSize, talentButtonSize,
                                          buttonSpacingY - talentButtonSize);
                end
                if (node.right ~= 0) then
                    self:SetBranchTexture(i, j, TALENT_BRANCH_TEXTURECOORDS["right"][node.right],
                                          xOffset + talentButtonSize, yOffset, buttonSpacingX - talentButtonSize,
                                          talentButtonSize);
                end

                if (node.id) then
                    local arrowInsetX, arrowInsetY = (self.arrowInsetX or 0), (self.arrowInsetY or 0);
                    if (node.goldBorder) then
                        arrowInsetX = arrowInsetX - TALENT_GOLD_BORDER_WIDTH;
                        arrowInsetY = arrowInsetY - TALENT_GOLD_BORDER_WIDTH;
                    end

                    if (node.rightArrow ~= 0) then
                        self:SetArrowTexture(i, j, TALENT_ARROW_TEXTURECOORDS["right"][node.rightArrow],
                                             xOffset + talentButtonSize / 2 - arrowInsetX, yOffset);
                    end
                    if (node.leftArrow ~= 0) then
                        self:SetArrowTexture(i, j, TALENT_ARROW_TEXTURECOORDS["left"][node.leftArrow],
                                             xOffset - talentButtonSize / 2 + arrowInsetX, yOffset);
                    end
                    if (node.topArrow ~= 0) then
                        self:SetArrowTexture(i, j, TALENT_ARROW_TEXTURECOORDS["top"][node.topArrow], xOffset,
                                             yOffset + talentButtonSize / 2 - arrowInsetY);
                    end
                else
                    if (node.up ~= 0 and node.left ~= 0 and node.right ~= 0) then
                        self:SetBranchTexture(i, j, TALENT_BRANCH_TEXTURECOORDS["tup"][node.up], xOffset, yOffset);
                    elseif (node.down ~= 0 and node.left ~= 0 and node.right ~= 0) then
                        self:SetBranchTexture(i, j, TALENT_BRANCH_TEXTURECOORDS["tdown"][node.down], xOffset, yOffset);
                    elseif (node.left ~= 0 and node.down ~= 0) then
                        self:SetBranchTexture(i, j, TALENT_BRANCH_TEXTURECOORDS["topright"][node.left], xOffset, yOffset);
                    elseif (node.left ~= 0 and node.up ~= 0) then
                        self:SetBranchTexture(i, j, TALENT_BRANCH_TEXTURECOORDS["bottomright"][node.left], xOffset,
                                              yOffset);
                    elseif (node.left ~= 0 and node.right ~= 0) then
                        self:SetBranchTexture(i, j, TALENT_BRANCH_TEXTURECOORDS["right"][node.right],
                                              xOffset + talentButtonSize, yOffset);
                    elseif (node.right ~= 0 and node.down ~= 0) then
                        self:SetBranchTexture(i, j, TALENT_BRANCH_TEXTURECOORDS["topleft"][node.right], xOffset, yOffset);
                    elseif (node.right ~= 0 and node.up ~= 0) then
                        self:SetBranchTexture(i, j, TALENT_BRANCH_TEXTURECOORDS["bottomleft"][node.right], xOffset,
                                              yOffset);
                    elseif (node.up ~= 0 and node.down ~= 0) then
                        self:SetBranchTexture(i, j, TALENT_BRANCH_TEXTURECOORDS["up"][node.up], xOffset, yOffset);
                    end
                end
            end
        end

        for i = self.BranchIndex, 30 do
            if _G[panel .. "Branch" .. i] then _G[panel .. "Branch" .. i]:Hide(); end
        end
        for i = self.ArrowIndex, 30 do
            if _G[panel .. "Arrow" .. i] then _G[panel .. "Arrow" .. i]:Hide(); end
        end
    end
end

function DragonflightUITalentsPanelMixin:SetArrowTexture(tier, column, texCoords, xOffset, yOffset)
    local arrowTexture = self:GetArrow()
    if arrowTexture then
        arrowTexture:SetTexCoord(texCoords[1], texCoords[2], texCoords[3], texCoords[4]);
        arrowTexture:SetPoint("TOPLEFT", arrowTexture:GetParent(), "TOPLEFT", xOffset, yOffset);
        arrowTexture:Show()
    end
end

function DragonflightUITalentsPanelMixin:SetBranchTexture(tier, column, texCoords, xOffset, yOffset, xSize, ySize)
    local branchTexture = self:GetBranch()
    if branchTexture then
        branchTexture:SetTexCoord(texCoords[1], texCoords[2], texCoords[3], texCoords[4]);
        branchTexture:SetPoint("TOPLEFT", branchTexture:GetParent(), "TOPLEFT", xOffset, yOffset);
        branchTexture:SetWidth(xSize or 30);
        branchTexture:SetHeight(ySize or 30);
        branchTexture:Show()
    end
end

function DragonflightUITalentsPanelMixin:SetPrereqs(buttonTier, buttonColumn, forceDesaturated, tierUnlocked, preview, ...)
    local requirementsMet = tierUnlocked and not forceDesaturated;
    for i = 1, select("#", ...), 4 do
        local tier, column, isLearnable, isPreviewLearnable = select(i, ...);
        if (forceDesaturated or (preview and not isPreviewLearnable) or (not preview and not isLearnable)) then
            requirementsMet = nil;
        end
        self:DrawLines(buttonTier, buttonColumn, tier, column, requirementsMet)
    end
    return requirementsMet;
end

function DragonflightUITalentsPanelMixin:ResetBranches()
    for i = 1, talentRows do
        if self.TALENT_BRANCH_ARRAY[i] then
            for j = 1, 4 do
                self.TALENT_BRANCH_ARRAY[i][j].id = nil;
                self.TALENT_BRANCH_ARRAY[i][j].up = 0;
                self.TALENT_BRANCH_ARRAY[i][j].down = 0;
                self.TALENT_BRANCH_ARRAY[i][j].left = 0;
                self.TALENT_BRANCH_ARRAY[i][j].right = 0;
                self.TALENT_BRANCH_ARRAY[i][j].rightArrow = 0;
                self.TALENT_BRANCH_ARRAY[i][j].leftArrow = 0;
                self.TALENT_BRANCH_ARRAY[i][j].topArrow = 0;

                self.BUTTON_ARRAY[i][j] = nil
            end
        end
    end

    local panel = self:GetName()
    for i = 1, 30 do
        if _G[panel .. 'Arrow' .. i] then _G[panel .. 'Arrow' .. i]:Hide() end
        if _G[panel .. 'Branch' .. i] then _G[panel .. 'Branch' .. i]:Hide() end
    end

    self.ArrowIndex = 1
    self.BranchIndex = 1
end

function DragonflightUITalentsPanelMixin:GetArrow()
    local arrowIndex = self.ArrowIndex
    self.ArrowIndex = arrowIndex + 1

    local arrow = _G[self:GetName() .. 'Arrow' .. arrowIndex]
    return arrow
end

function DragonflightUITalentsPanelMixin:GetBranch()
    local branchIndex = self.BranchIndex
    self.BranchIndex = branchIndex + 1

    local branch = _G[self:GetName() .. 'Branch' .. branchIndex]
    return branch
end

function DragonflightUITalentsPanelMixin:DrawLines(buttonTier, buttonColumn, tier, column, requirementsMet)
    if (requirementsMet) then
        requirementsMet = 1;
    else
        requirementsMet = -1;
    end

    if (buttonColumn == column) then
        if ((buttonTier - tier) > 1) then
            for i = tier + 1, buttonTier - 1 do
                if (self.TALENT_BRANCH_ARRAY[i][buttonColumn].id) then
                    return;
                end
            end
        end

        for i = tier, buttonTier - 1 do
            self.TALENT_BRANCH_ARRAY[i][buttonColumn].down = requirementsMet;
            if ((i + 1) <= (buttonTier - 1)) then
                self.TALENT_BRANCH_ARRAY[i + 1][buttonColumn].up = requirementsMet;
            end
        end

        self.TALENT_BRANCH_ARRAY[buttonTier][buttonColumn].topArrow = requirementsMet;
        return;
    end

    if (buttonTier == tier) then
        local left = min(buttonColumn, column);
        local right = max(buttonColumn, column);

        if ((right - left) > 1) then
            for i = left + 1, right - 1 do
                if (self.TALENT_BRANCH_ARRAY[tier][i].id) then
                    return;
                end
            end
        end

        for i = left, right - 1 do
            self.TALENT_BRANCH_ARRAY[tier][i].right = requirementsMet;
            self.TALENT_BRANCH_ARRAY[tier][i + 1].left = requirementsMet;
        end

        if (buttonColumn < column) then
            self.TALENT_BRANCH_ARRAY[buttonTier][buttonColumn].rightArrow = requirementsMet;
        else
            self.TALENT_BRANCH_ARRAY[buttonTier][buttonColumn].leftArrow = requirementsMet;
        end
        return;
    end

    local left = min(buttonColumn, column);
    local right = max(buttonColumn, column);
    if (left == column) then
        left = left + 1;
    else
        right = right - 1;
    end

    local blocked = nil;
    for i = left, right do
        if (self.TALENT_BRANCH_ARRAY[tier][i].id) then
            blocked = 1;
        end
    end
    left = min(buttonColumn, column);
    right = max(buttonColumn, column);
    if (not blocked) then
        self.TALENT_BRANCH_ARRAY[tier][buttonColumn].down = requirementsMet;
        self.TALENT_BRANCH_ARRAY[buttonTier][buttonColumn].up = requirementsMet;

        for i = tier, buttonTier - 1 do
            self.TALENT_BRANCH_ARRAY[i][buttonColumn].down = requirementsMet;
            self.TALENT_BRANCH_ARRAY[i + 1][buttonColumn].up = requirementsMet;
        end

        for i = left, right - 1 do
            self.TALENT_BRANCH_ARRAY[tier][i].right = requirementsMet;
            self.TALENT_BRANCH_ARRAY[tier][i + 1].left = requirementsMet;
        end
        self.TALENT_BRANCH_ARRAY[buttonTier][buttonColumn].topArrow = requirementsMet;
        return;
    end

    if (left == buttonColumn) then
        left = left + 1;
    else
        right = right - 1;
    end

    for i = left, right do
        if (self.TALENT_BRANCH_ARRAY[buttonTier][i].id) then
            return;
        end
    end

    left = min(buttonColumn, column);
    right = max(buttonColumn, column);

    for i = tier, buttonTier - 1 do
        self.TALENT_BRANCH_ARRAY[i][column].up = requirementsMet;
        self.TALENT_BRANCH_ARRAY[i + 1][column].down = requirementsMet;
    end

    if (buttonColumn < column) then
        self.TALENT_BRANCH_ARRAY[buttonTier][buttonColumn].rightArrow = requirementsMet;
    else
        self.TALENT_BRANCH_ARRAY[buttonTier][buttonColumn].leftArrow = requirementsMet;
    end
end

local PlayerClassRoleTable = {
    {{'DAMAGER'}, {'DAMAGER'}, {'TANK'}}, -- Warrior
    {{'HEALER'}, {'TANK'}, {'DAMAGER'}}, -- Paladin 
    {{'DAMAGER'}, {'DAMAGER'}, {'DAMAGER'}}, -- Hunter 
    {{'DAMAGER'}, {'DAMAGER'}, {'DAMAGER'}}, -- Rogue 
    {{'HEALER'}, {'HEALER'}, {'DAMAGER'}}, -- Priest  
    {{'TANK'}, {'DAMAGER'}, {'DAMAGER'}}, -- DeathKnight 
    {{'DAMAGER'}, {'DAMAGER'}, {'HEALER'}}, -- Shaman 
    {{'DAMAGER'}, {'DAMAGER'}, {'DAMAGER'}}, -- Mage 
    {{'DAMAGER'}, {'DAMAGER'}, {'DAMAGER'}}, -- Warlock 
    {{'DAMAGER'}, {'DAMAGER'}, {'DAMAGER'}}, -- Monk 
    {{'DAMAGER'}, {'DAMAGER', 'TANK'}, {'HEALER'}}, -- Druid 
    {{'DAMAGER'}, {'DAMAGER'}, {'DAMAGER'}} -- Demon Hunter 
}
if DF.API.Version.IsSoD then
    PlayerClassRoleTable[8][1] = {'DAMAGER', 'HEALER'} -- mage heal
    PlayerClassRoleTable[7][2] = {'DAMAGER', 'TANK'} -- shaman tank
end

DragonflightUITalentsPanelMixin.PlayerClassRoleTable = PlayerClassRoleTable;

function DragonflightUITalentsPanelMixin:GetPlayerRole(panelID)
    local localizedClass, englishClass, classIndex = UnitClass('player');
    if PlayerClassRoleTable[classIndex] and PlayerClassRoleTable[classIndex][panelID] then
        local roleData = PlayerClassRoleTable[classIndex][panelID]
        return roleData[1], roleData[2]
    end
    return nil, nil
end

function DragonflightUITalentsPanelMixin:UpdateRoleIcon(self, panelID)
    local role1, role2 = DragonflightUITalentsPanelMixin:GetPlayerRole(panelID)

    if (role2) then role1, role2 = role2, role1; end

    if self.RoleIcon and self.RoleIcon.Icon then
        if (role1 == "TANK" or role1 == "HEALER" or role1 == "DAMAGER") then
            self.RoleIcon.Icon:SetTexCoord(GetTexCoordsForRoleSmall(role1));
            self.RoleIcon:Show();
            self.RoleIcon.role = role1;
        else
            self.RoleIcon:Hide();
        end
    end

    if self.RoleIcon2 and self.RoleIcon2.Icon then
        if (role2 == "TANK" or role2 == "HEALER" or role2 == "DAMAGER") then
            self.RoleIcon2.Icon:SetTexCoord(GetTexCoordsForRoleSmall(role2));
            self.RoleIcon2:Show();
            self.RoleIcon2.role = role2;
        else
            self.RoleIcon2:Hide();
        end
    end
end
