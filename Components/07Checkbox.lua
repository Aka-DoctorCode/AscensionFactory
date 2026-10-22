-------------------------------------------------------------------------------
-- Project: AscensionFactory
-- Author: Aka-DoctorCode
-- File: Checkbox.lua
-------------------------------------------------------------------------------
---@diagnostic disable: undefined-global, undefined-field, inject-field

-------------------------------------------------------------------------------
-- 1. INITIALIZATION
-- Objective: Import core AscensionFactory library and Context.
-- Variables:
-- MAJOR (string): Namespace identifier for addon library.
-- lib (table): Resolved library instance.
-- Context (table): Object factory table where creation methods attach.
-------------------------------------------------------------------------------
local MAJOR = "AscensionFactory"
local lib = LibStub:GetLibrary(MAJOR)
if not lib then return end

local Context = lib.Context
if not Context then return end

-------------------------------------------------------------------------------
-- 2. CHECKBOX FACTORY
-- Objective: Creates custom stylized checkbox with interactive label and vector checkmark.
-- Variables:
-- options (table): Configuration table (text, checked, getter, setter, onClick, size).
-- checkbox (table): Interactive Button frame acting as checkbox row.
-- box (table): Visual square container holding border and background textures.
-- checkmark (table): Group containing vector line textures.
-- label (table): Text FontString element placed next to box.
-- updateAppearance (function): Centralized visual state updater.
-------------------------------------------------------------------------------
function Context:createCheckbox(options)
    local styles = self.styles
    local text = options.text or ""

    -- Checkmark state management closure
    local checkbox
    local function updateCheckmarkVisibility()
        if not checkbox then return end
        local enabled = checkbox:IsEnabled()
        if checkbox.isChecked then
            checkbox.checkShortLeg:Show()
            checkbox.checkLongLeg:Show()
            local checkColor = enabled and styles.colors.white or styles.colors.surfaceHover
            checkbox.checkShortLeg:SetColorTexture(unpack(checkColor))
            checkbox.checkLongLeg:SetColorTexture(unpack(checkColor))
            checkbox.borderColors.normal = styles.colors.primary
        else
            checkbox.checkShortLeg:Hide()
            checkbox.checkLongLeg:Hide()
            checkbox.borderColors.normal = styles.colors.border
        end
    end

    -- 1. BASE BUTTON INHERITANCE
    local buttonOptions = {}
    for key, value in pairs(options) do
        buttonOptions[key] = value
    end
    buttonOptions.borderColors = buttonOptions.borderColors or {
        normal = styles.colors.border,
        hover = styles.colors.primaryHover,
        active = styles.colors.primaryActive,
        disabled = styles.colors.surfaceLight
    }
    buttonOptions.onAfterStateChange = function(element, state)
        updateCheckmarkVisibility()
    end

    checkbox = self:createButton(buttonOptions)

    local buttonHeight = checkbox:GetHeight()
    local boxSize = options.boxSize or options.size or buttonHeight

    -- State initialization
    checkbox.isChecked = false
    if options.getter then
        checkbox.isChecked = options.getter()
    elseif options.checked ~= nil then
        checkbox.isChecked = options.checked
    end
    if checkbox.isChecked then
        checkbox.borderColors.normal = styles.colors.primary
    end

    local isFlexRow = options.flexRow or false
    checkbox.isFlexRow = isFlexRow

    -- 2. BOX GEOMETRY RE-ANCHORING
    local point = options.point or options.anchorPoint or "TOPLEFT"
    local yOffset = options.yOffset or 0
    local targetParent = options.relativeTo or parent or UIParent
    local rightOffset = options.fluidRightOffset or options.rightOffset or -10

    local boxBorder = checkbox.border
    boxBorder:ClearAllPoints()
    if isFlexRow then
        if string.find(point, "TOP") then
            checkbox:SetPoint("TOPRIGHT", targetParent, "TOPRIGHT", rightOffset, yOffset)
        elseif string.find(point, "BOTTOM") then
            checkbox:SetPoint("BOTTOMRIGHT", targetParent, "BOTTOMRIGHT", rightOffset, yOffset)
        else
            checkbox:SetPoint("RIGHT", targetParent, "RIGHT", rightOffset, yOffset)
        end
        boxBorder:SetPoint("RIGHT", checkbox, "RIGHT", 0, 0)
    else
        boxBorder:SetPoint("LEFT", checkbox, "LEFT", 0, 0)
    end
    boxBorder:SetSize(boxSize, boxSize)
    boxBorder:Show()
    checkbox.boxBorder = boxBorder

    local boxTrack = checkbox.track
    boxTrack:ClearAllPoints()
    boxTrack:SetPoint("TOPLEFT", boxBorder, "TOPLEFT", 1, -1)
    boxTrack:SetSize(boxSize - 2, boxSize - 2)
    boxTrack:Show()
    checkbox.boxTrack = boxTrack

    -- 3. LABEL POSITIONING
    local label = checkbox:GetFontString()
    if label then
        checkbox.label = label
        label:ClearAllPoints()
        label:SetJustifyH("LEFT")
        if isFlexRow then
            label:SetPoint("LEFT", checkbox, "LEFT", 0, 0)
            label:SetPoint("RIGHT", boxBorder, "LEFT", -8, 0)
            label:SetWordWrap(true)
            if text ~= "" then
                label:Show()
            else
                label:Hide()
            end
        else
            label:SetWidth(0)
            if text ~= "" then
                label:SetPoint("LEFT", checkbox.boxBorder, "RIGHT", 8, 0)
                label:Show()
                local labelWidth = label:GetStringWidth() or 0
                if not options.width then
                    checkbox:SetWidth(boxSize + 8 + labelWidth)
                end
            else
                label:Hide()
                if not options.width then
                    checkbox:SetWidth(boxSize)
                end
            end
        end
    end

    -- 4. GEOMETRIC VECTOR CHECKMARK
    local thickness = math.max(2, math.floor(boxSize * 0.12))
    local sqrt2over2 = 0.7071067811865476 -- math.sqrt(2) / 2

    local shortLength = math.floor(boxSize * 0.35)
    local longLength = math.floor(boxSize * 0.60)

    -- Symmetrically centered vertex (equal left-right and top-bottom margins)
    local vertexX = (boxSize * 0.50) + (shortLength - longLength) * 0.5 * sqrt2over2
    local vertexY = -(boxSize * 0.50) - (longLength * 0.5 * sqrt2over2)

    -- Short leg: descends from upper-left to vertex at -45 deg
    local shortCenterX = vertexX + (shortLength * 0.5) * (-sqrt2over2)
    local shortCenterY = vertexY + (shortLength * 0.5) * (sqrt2over2)

    if not checkbox.checkShortLeg then
        checkbox.checkShortLeg = checkbox:CreateTexture(nil, "ARTWORK")
    end
    checkbox.checkShortLeg:ClearAllPoints()
    checkbox.checkShortLeg:SetSize(shortLength, thickness)
    checkbox.checkShortLeg:SetPoint("CENTER", checkbox.boxBorder, "TOPLEFT", shortCenterX, shortCenterY)
    checkbox.checkShortLeg:SetRotation(math.rad(-45))

    -- Long leg: ascends from vertex to upper-right at +45 deg
    local longCenterX = vertexX + (longLength * 0.5) * (sqrt2over2)
    local longCenterY = vertexY + (longLength * 0.5) * (sqrt2over2)

    if not checkbox.checkLongLeg then
        checkbox.checkLongLeg = checkbox:CreateTexture(nil, "ARTWORK")
    end
    checkbox.checkLongLeg:ClearAllPoints()
    checkbox.checkLongLeg:SetSize(longLength, thickness)
    checkbox.checkLongLeg:SetPoint("CENTER", checkbox.boxBorder, "TOPLEFT", longCenterX, longCenterY)
    checkbox.checkLongLeg:SetRotation(math.rad(45))

    -- Apply initial checkmark state
    updateCheckmarkVisibility()

    -- 5. CLICK TOGGLE LOGIC
    checkbox:SetScript("OnClick", function(self, buttonName, down)
        self.isChecked = not self.isChecked

        if options.setter then
            options.setter(self.isChecked)
        end

        if options.onClick then
            options.onClick(self, self.isChecked, buttonName, down)
        end

        updateCheckmarkVisibility()
        if self.updateAppearance then
            self.updateAppearance(self:IsMouseOver() and "hover" or "normal")
        end
    end)

    -- 6. EXTERNAL CONTROL METHODS
    function checkbox:getChecked()
        return self.isChecked
    end
    checkbox.GetChecked = checkbox.getChecked

    function checkbox:setChecked(isChecked)
        self.isChecked = not not isChecked
        if options.setter then
            options.setter(self.isChecked)
        end
        updateCheckmarkVisibility()
        if self.updateAppearance then
            self.updateAppearance()
        end
    end
    checkbox.SetChecked = checkbox.setChecked

    function checkbox:setText(newText)
        if self.label then
            self.label:SetText(newText)
            if not self.isFlexRow then
                self.label:SetWidth(0)
                local labelWidth = self.label:GetStringWidth() or 0
                if not options.width then
                    self:SetWidth(boxSize + 8 + labelWidth)
                end
            end
        end
    end
    checkbox.SetText = checkbox.setText

    function checkbox:setFlexRow(enabled)
        self.isFlexRow = not not enabled
        if self.isFlexRow then
            self:ClearAllPoints()
            local basePoint = options.point or options.anchorPoint or "TOPLEFT"
            local baseY = options.yOffset or 0
            local baseX = options.xOffset or 0
            local tgt = options.relativeTo or parent or UIParent
            local rOfs = options.fluidRightOffset or options.rightOffset or -10
            self:SetPoint(basePoint, tgt, options.relativePoint or basePoint, baseX, baseY)
            if string.find(basePoint, "TOP") then
                self:SetPoint("TOPRIGHT", tgt, "TOPRIGHT", rOfs, baseY)
            elseif string.find(basePoint, "BOTTOM") then
                self:SetPoint("BOTTOMRIGHT", tgt, "BOTTOMRIGHT", rOfs, baseY)
            else
                self:SetPoint("RIGHT", tgt, "RIGHT", rOfs, baseY)
            end
            self.boxBorder:ClearAllPoints()
            self.boxBorder:SetPoint("RIGHT", self, "RIGHT", 0, 0)
            if self.label then
                self.label:ClearAllPoints()
                self.label:SetPoint("LEFT", self, "LEFT", 0, 0)
                self.label:SetPoint("RIGHT", self.boxBorder, "LEFT", -8, 0)
                self.label:SetWordWrap(true)
            end
        end
    end

    return checkbox
end

-------------------------------------------------------------------------------
-- 7. EXTENSION & EXPANSION NOTES
-- Objective: Guidelines for radio button groups, indeterminate check states, and custom check icons.
--
-- How to expand:
-- 1. Radio Button Grouping:
--    Add `options.isRadio = true` to render circular borders and solid circular/diamond center dots,
--    linking multiple radio buttons together so checking one unchecks the others in the group.
-- 2. Indeterminate / Partial Check State:
--    Add support for a third "dash" icon state for parent checkboxes that control multi-item groups.
-- 3. Sound Effects:
--    Hook `PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)` / `OFF` inside `OnClick`.
-------------------------------------------------------------------------------
