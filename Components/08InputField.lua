-------------------------------------------------------------------------------
-- Project: AscensionFactory
-- Author: Aka-DoctorCode
-- File: 08InputField.lua
-------------------------------------------------------------------------------
---@diagnostic disable: undefined-global, undefined-field, inject-field

-------------------------------------------------------------------------------
-- 1. INITIALIZATION
-- Objective: Import the core AscensionFactory library and Context.
-- This ensures the UI elements can be built upon the existing framework.
-- Variables:
-- MAJOR (string): The namespace identifier for the addon library.
-- lib (table): The resolved library instance.
-- Context (table): The object factory table where creation methods are attached.
-------------------------------------------------------------------------------
local MAJOR = "AscensionFactory"
local lib = LibStub:GetLibrary(MAJOR)
if not lib then return end

local Context = lib.Context
if not Context then return end

-------------------------------------------------------------------------------
-- 2. INPUT FIELD FACTORY
-- Objective: Creates a unified text input component supporting single-line entries,
-- multi-line text areas, numeric mode, placeholder ghost text, focus glow, and
-- optional clear button or vertical scrollbar.
-- Variables:
-- options (table): Configuration table (width, height, multiLine, placeholder, numeric, etc.).
-- container (table): The outer Frame containing border, track, editBox, placeholder, and controls.
-- editBox (table): The native WoW EditBox widget capturing keystrokes.
-------------------------------------------------------------------------------
function Context:createInputField(options)
    options = options or {}
    local styles = self.styles
    local parent = options.parent or UIParent

    -- 2.1 MANDATORY VALIDATION (Explicit sizing or fluid width)
    if not options.width and not options.fluidWidth then
        error("AscensionFactory: createInputField requires explicit 'width' (or 'fluidWidth = true')", 2)
    end
    if not options.height then
        error("AscensionFactory: createInputField requires explicit 'height'", 2)
    end

    local isFluid = options.fluidWidth or false
    local width = options.width or 200
    local height = options.height
    local isMultiLine = options.multiLine or false
    local showClear = (not isMultiLine) and (options.showClear or options.clearButton or false)
    local showScrollbar = isMultiLine and (options.showScrollbar or false)

    -- 2.2 BASE CONTAINER FRAME SETUP
    local container = self:acquireElement("Frame", parent, {
        width = width,
        height = height
    })
    container:EnableMouse(true)
    container:SetClipsChildren(true)
    container.fluidWidth = isFluid
    container.fluidRightOffset = options.fluidRightOffset or options.rightOffset

    if options.name then
        _G[options.name] = container
    end

    local point = options.point or options.anchorPoint or "TOPLEFT"
    local yOffset = options.yOffset or 0
    local targetParent = options.relativeTo or parent

    if options.point or options.anchorPoint or options.xOffset or options.yOffset then
        container:ClearAllPoints()
        container:SetPoint(
            point,
            targetParent,
            options.relativePoint or point,
            options.xOffset or 0,
            yOffset
        )
    end

    if isFluid then
        local rightOffset = options.fluidRightOffset or options.rightOffset or -10
        if string.find(point, "TOP") then
            container:SetPoint("TOPRIGHT", targetParent, "TOPRIGHT", rightOffset, yOffset)
        elseif string.find(point, "BOTTOM") then
            container:SetPoint("BOTTOMRIGHT", targetParent, "BOTTOMRIGHT", rightOffset, yOffset)
        else
            container:SetPoint("RIGHT", targetParent, "RIGHT", rightOffset, yOffset)
        end
    end

    -- 2.3 CONTAINER BORDER & TRACK TEXTURES
    if not container.border then
        local border = container:CreateTexture(nil, "BACKGROUND", nil, -2)
        border:SetAllPoints(container)
        container.border = border
    end
    container.border:SetColorTexture(unpack(options.borderColor or styles.colors.border))
    container.border:Show()

    if not container.track then
        local track = container:CreateTexture(nil, "BACKGROUND", nil, -1)
        container.track = track
    end
    container.track:ClearAllPoints()
    container.track:SetPoint("TOPLEFT", container, "TOPLEFT", 1, -1)
    container.track:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", -1, 1)
    container.track:SetColorTexture(unpack(options.trackColor or styles.colors.surfaceDark))
    container.track:Show()

    -- 2.4 EDITBOX & SCROLLFRAME SETUP
    local rightPadding = showClear and -26 or (showScrollbar and -18 or -8)
    local topPadding = isMultiLine and -6 or 0
    local bottomPadding = isMultiLine and 6 or 0

    local scrollFrame = container.scrollFrame
    local editBox = container.editBox

    if isMultiLine then
        if not scrollFrame then
            scrollFrame = self:acquireElement("ScrollFrame", container, {})
            container.scrollFrame = scrollFrame
        end
        scrollFrame:ClearAllPoints()
        scrollFrame:SetPoint("TOPLEFT", container, "TOPLEFT", 8, topPadding)
        scrollFrame:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", rightPadding, bottomPadding)
        scrollFrame:SetClipsChildren(true)
        scrollFrame:Show()

        if not editBox then
            editBox = self:acquireElement("EditBox", scrollFrame, {})
            container.editBox = editBox
        else
            editBox:SetParent(scrollFrame)
        end

        local editBoxWidth = math.max(10, width - 16 + (rightPadding + 8))
        editBox:ClearAllPoints()
        editBox:SetPoint("TOPLEFT", scrollFrame, "TOPLEFT", 0, 0)
        editBox:SetWidth(editBoxWidth)
        editBox:SetHeight(math.max(10, height - 12))
        editBox:SetMultiLine(true)
        scrollFrame:SetScrollChild(editBox)

        if isFluid and container.HookScript then
            container:HookScript("OnSizeChanged", function(self, newWidth, newHeight)
                if self.editBox and newWidth and newWidth > 0 then
                    local dynamicBoxWidth = math.max(10, newWidth - 16 + (rightPadding + 8))
                    self.editBox:SetWidth(dynamicBoxWidth)
                end
            end)
        end
    else
        if scrollFrame then
            scrollFrame:Hide()
        end

        if not editBox then
            editBox = self:acquireElement("EditBox", container, {})
            container.editBox = editBox
        else
            editBox:SetParent(container)
        end

        editBox:ClearAllPoints()
        editBox:SetPoint("LEFT", container, "LEFT", 8, 0)
        editBox:SetPoint("RIGHT", container, "RIGHT", rightPadding, 0)
        editBox:SetHeight(height - 4)
        editBox:SetMultiLine(false)
    end

    editBox:SetFontObject(options.font or styles.fonts.text or "GameFontHighlight")
    editBox:SetTextColor(unpack(styles.colors.white))
    editBox:SetAutoFocus(options.autoFocus or false)
    editBox:SetCountInvisibleLetters(false)

    if options.maxLetters or options.maxLength then
        editBox:SetMaxLetters(options.maxLetters or options.maxLength)
    else
        editBox:SetMaxLetters(0)
    end

    if options.numeric then
        editBox:SetNumeric(true)
    else
        editBox:SetNumeric(false)
    end

    if options.password then
        editBox:SetPassword(true)
    end

    -- 2.5 PLACEHOLDER GHOST TEXT
    local placeholder = container.placeholder
    if not placeholder then
        placeholder = container:CreateFontString(nil, "ARTWORK")
        container.placeholder = placeholder
    end
    placeholder:SetFontObject(options.font or styles.fonts.text or "GameFontHighlight")
    placeholder:SetTextColor(unpack(styles.colors.surfaceHover))
    placeholder:ClearAllPoints()
    if isMultiLine then
        placeholder:SetPoint("TOPLEFT", container, "TOPLEFT", 8, -6)
        placeholder:SetPoint("RIGHT", container, "RIGHT", rightPadding, 0)
        placeholder:SetJustifyH("LEFT")
        placeholder:SetJustifyV("TOP")
    else
        placeholder:SetPoint("LEFT", container, "LEFT", 8, 0)
        placeholder:SetJustifyH("LEFT")
        placeholder:SetJustifyV("MIDDLE")
    end
    local placeholderText = options.placeholder or ""
    placeholder:SetText(placeholderText)

    local function updatePlaceholderVisibility()
        local currentText = editBox:GetText()
        if currentText == "" and placeholderText ~= "" and not editBox:HasFocus() then
            placeholder:Show()
        else
            placeholder:Hide()
        end
    end

    -- 2.6 OPTIONAL CLEAR BUTTON (Single-line only)
    local clearButton = container.clearButton
    if showClear then
        if not clearButton then
            clearButton = self:createIconButton({
                parent = container,
                iconType = "close",
                size = 18,
                point = "RIGHT",
                relativeTo = container,
                relativePoint = "RIGHT",
                xOffset = -4,
                yOffset = 0,
                onClick = function()
                    editBox:SetText("")
                    editBox:SetFocus()
                    if options.setter then
                        options.setter("")
                    end
                    if options.onTextChanged then
                        options.onTextChanged(container, "", true)
                    end
                end
            })
            container.clearButton = clearButton
        end
    elseif clearButton then
        clearButton:Hide()
    end

    local function updateClearButtonVisibility()
        if showClear and clearButton then
            if editBox:GetText() ~= "" then
                clearButton:Show()
            else
                clearButton:Hide()
            end
        end
    end

    -- 2.7 OPTIONAL MULTI-LINE SCROLLBAR & SCROLL ENGINE
    local function updateScrollRange()
        if isMultiLine and container.scrollFrame then
            local maxScroll = math.max(0, container.scrollFrame:GetVerticalScrollRange())
            if container.scrollbar then
                container.scrollbar:setMinMaxValues(0, math.max(1, maxScroll))
                container.scrollbar:setValue(container.scrollFrame:GetVerticalScroll(), true, false)
            end
        end
    end

    local function handleMouseWheel(delta)
        if isMultiLine and container.scrollFrame then
            local current = container.scrollFrame:GetVerticalScroll()
            local maxScroll = container.scrollFrame:GetVerticalScrollRange()
            local step = 20
            local newScroll = math.max(0, math.min(maxScroll, current - (delta * step)))
            container.scrollFrame:SetVerticalScroll(newScroll)
            updateScrollRange()
        end
    end

    if isMultiLine then
        container:EnableMouseWheel(true)
        container:SetScript("OnMouseWheel", function(self, delta)
            handleMouseWheel(delta)
        end)
        editBox:EnableMouseWheel(true)
        editBox:SetScript("OnMouseWheel", function(self, delta)
            handleMouseWheel(delta)
        end)
    end

    if showScrollbar and self.createSlider then
        local scrollbar = container.scrollbar
        if not scrollbar then
            scrollbar = self:createSlider({
                parent = container,
                orientation = "VERTICAL",
                length = height - 4,
                width = 12,
                point = "RIGHT",
                relativeTo = container,
                relativePoint = "RIGHT",
                xOffset = -2,
                yOffset = 0,
                minValue = 0,
                maxValue = 1,
                step = 1,
                onValueChanged = function(s, val, isUserInput)
                    if isUserInput and container.scrollFrame then
                        container.scrollFrame:SetVerticalScroll(val)
                    end
                end
            })
            container.scrollbar = scrollbar
        end
        scrollbar:Show()
    elseif container.scrollbar then
        container.scrollbar:Hide()
    end

    -- 2.8 FOCUS GLOW & INTERACTION SCRIPTS (Managed via UX:makeHoverable)
    local isFocused = false

    if lib.UX and lib.UX.makeHoverable then
        lib.UX:makeHoverable(container, {
            tooltip = options.tooltip,
            border = container.border,
            borderColors = {
                normal = options.borderColor or styles.colors.border,
                hover = styles.colors.primaryHover,
                active = styles.colors.primary,
                disabled = styles.colors.border or styles.colors.surfaceLight
            },
            onAfterStateChange = function(element, state)
                if isFocused then
                    container.border:SetColorTexture(unpack(styles.colors.primary))
                end
            end
        })
    end

    container:HookScript("OnMouseDown", function()
        editBox:SetFocus()
    end)

    if isMultiLine and container.scrollFrame then
        container.scrollFrame:HookScript("OnMouseDown", function()
            editBox:SetFocus()
        end)
    end

    editBox:HookScript("OnEnter", function()
        if container.updateAppearance then
            container.updateAppearance("hover")
        end
    end)

    editBox:HookScript("OnLeave", function()
        if container.updateAppearance then
            container.updateAppearance(container:IsMouseOver() and "hover" or "normal")
        end
    end)

    editBox:SetScript("OnEditFocusGained", function(self)
        isFocused = true
        placeholder:Hide()
        if container.updateAppearance then
            container.updateAppearance("active")
        end
        if options.onFocusGained then
            options.onFocusGained(container)
        end
    end)

    editBox:SetScript("OnEditFocusLost", function(self)
        isFocused = false
        updatePlaceholderVisibility()
        if container.updateAppearance then
            container.updateAppearance((container:IsMouseOver() or editBox:IsMouseOver()) and "hover" or "normal")
        end
        if options.onFocusLost then
            options.onFocusLost(container)
        end
    end)

    editBox:SetScript("OnCursorChanged", function(self, x, y, w, h)
        if isMultiLine and container.scrollFrame then
            local cursorOffset = -y
            local currentScroll = container.scrollFrame:GetVerticalScroll()
            local frameHeight = container.scrollFrame:GetHeight()
            if frameHeight and frameHeight > 0 then
                if cursorOffset < currentScroll then
                    container.scrollFrame:SetVerticalScroll(cursorOffset)
                elseif (cursorOffset + (h or 14)) > (currentScroll + frameHeight) then
                    container.scrollFrame:SetVerticalScroll(cursorOffset + (h or 14) - frameHeight)
                end
            end
            updateScrollRange()
        end
    end)

    editBox:SetScript("OnTextChanged", function(self, isUserInput)
        local text = self:GetText()
        updatePlaceholderVisibility()
        updateClearButtonVisibility()
        updateScrollRange()

        if isUserInput then
            if options.setter then
                options.setter(text)
            end
            if options.onTextChanged then
                options.onTextChanged(container, text, true)
            end
        end
    end)

    editBox:SetScript("OnEnterPressed", function(self)
        if not isMultiLine then
            self:ClearFocus()
            if options.onEnterPressed then
                options.onEnterPressed(container, self:GetText())
            end
        else
            self:Insert("\n")
        end
    end)

    editBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
        if options.onEscapePressed then
            options.onEscapePressed(container)
        end
    end)

    -- Initial text population
    local initialText = options.text or ""
    if options.getter then
        initialText = options.getter() or initialText
    end
    editBox:SetText(initialText)
    updatePlaceholderVisibility()
    updateClearButtonVisibility()

    -- 2.9 PUBLIC API METHODS
    function container:getText()
        return self.editBox:GetText()
    end
    container.GetText = container.getText

    function container:setText(newText)
        self.editBox:SetText(newText or "")
        updatePlaceholderVisibility()
        updateClearButtonVisibility()
    end
    container.SetText = container.setText

    function container:clear()
        self.editBox:SetText("")
        updatePlaceholderVisibility()
        updateClearButtonVisibility()
    end
    container.Clear = container.clear

    function container:setPlaceholder(newPlaceholder)
        placeholderText = newPlaceholder or ""
        self.placeholder:SetText(placeholderText)
        updatePlaceholderVisibility()
    end
    container.SetPlaceholder = container.setPlaceholder

    function container:setNumeric(isNumeric)
        self.editBox:SetNumeric(isNumeric)
    end
    container.SetNumeric = container.setNumeric

    function container:setMaxLetters(maxLetters)
        self.editBox:SetMaxLetters(maxLetters or 0)
    end
    container.SetMaxLetters = container.setMaxLetters

    function container:setFocus()
        self.editBox:SetFocus()
    end
    container.SetFocus = container.setFocus

    function container:clearFocus()
        self.editBox:ClearFocus()
    end
    container.ClearFocus = container.clearFocus

    function container:getEditBox()
        return self.editBox
    end
    container.GetEditBox = container.getEditBox

    function container:setEnabled(enabled)
        self.editBox:SetEnabled(enabled)
        if enabled then
            self.editBox:SetTextColor(unpack(styles.colors.white))
            self.track:SetColorTexture(unpack(styles.colors.surfaceDark))
        else
            self.editBox:SetTextColor(unpack(styles.colors.surfaceHover))
            self.track:SetColorTexture(unpack(styles.colors.background))
        end
    end
    container.SetEnabled = container.setEnabled

    return container
end

-------------------------------------------------------------------------------
-- 3. EXTENSION & EXPANSION NOTES
-- Objective: Guidelines for autocomplete dropdowns, validation regex patterns, and copy-paste buttons.
--
-- How to expand:
-- 1. Validation & Error Glow:
--    Add `container:setValidationError(hasError)` to glow the border in `neonRed` when regex validation fails.
-- 2. Autocomplete Suggestions:
--    Attach a popup scroll list below the input field hooked to `OnTextChanged` to suggest character names,
--    commands, or search items.
-- 3. Copy-to-Clipboard Button:
--    Add an optional icon button on the right side to highlight all text (`editBox:HighlightText()`)
--    for quick copying to system clipboard.
-------------------------------------------------------------------------------
