-------------------------------------------------------------------------------
-- Project: AscensionFactory
-- Author: Aka-DoctorCode
-- File: 15ColorPicker.lua
-------------------------------------------------------------------------------
---@diagnostic disable: undefined-global, undefined-field, inject-field

-------------------------------------------------------------------------------
-- 1. INITIALIZATION & NAMESPACE REGISTRATION
-- Objective: Register the ColorPicker component and modal dialog in AscensionFactory.
-------------------------------------------------------------------------------
local MAJOR = "AscensionFactory"
local lib = LibStub:GetLibrary(MAJOR)
if not lib then return end

local Context = lib.Context
if not Context then return end

-- Session-persistent recent colors history across all addons
lib.recentColors = lib.recentColors or {
    { 1.00, 0.38, 0.00, 1.00 }, -- Ascension Neon Orange
    { 0.00, 1.00, 0.55, 1.00 }, -- Neon Green
    { 1.00, 0.20, 0.20, 1.00 }, -- Neon Red
    { 0.00, 0.75, 1.00, 1.00 }, -- Electric Cyan
    { 0.70, 0.25, 1.00, 1.00 }, -- Neon Violet
    { 1.00, 0.85, 0.10, 1.00 }, -- Cyber Gold
    { 1.00, 1.00, 1.00, 1.00 }, -- Pure White
    { 0.50, 0.50, 0.50, 0.50 }, -- Translucent Gray
}

-------------------------------------------------------------------------------
-- 2. HELPER UTILITIES: COLOR PARSING, HEX CONVERSION & CHECKERBOARD
-------------------------------------------------------------------------------

--- Converts RGBA numbers (0.0 to 1.0) into a 6-character Hex string (e.g. "FF6000").
local function rgbToHex(r, g, b)
    r = math.floor(math.max(0, math.min(1, r)) * 255 + 0.5)
    g = math.floor(math.max(0, math.min(1, g)) * 255 + 0.5)
    b = math.floor(math.max(0, math.min(1, b)) * 255 + 0.5)
    return string.format("%02X%02X%02X", r, g, b)
end

--- Parses a hex string (e.g. "#FF6000" or "FF6000") into normalized RGB (0.0 to 1.0).
local function hexToRgb(hex)
    if not hex or type(hex) ~= "string" then return nil end
    hex = hex:gsub("#", ""):gsub("%s+", "")
    if #hex ~= 6 then return nil end

    local r = tonumber(hex:sub(1, 2), 16)
    local g = tonumber(hex:sub(3, 4), 16)
    local b = tonumber(hex:sub(5, 6), 16)
    if not r or not g or not b then return nil end

    return r / 255, g / 255, b / 255
end

--- Normalizes various color input formats (table {r,g,b,a} or {1,2,3,4}).
local function normalizeColor(input)
    if type(input) == "table" then
        local r = input.r or input[1] or 1
        local g = input.g or input[2] or 1
        local b = input.b or input[3] or 1
        local a = input.a or input[4]
        if a == nil then a = 1 end
        return r, g, b, a
    end
    return 1, 1, 1, 1
end

--- Applies a lightweight procedural checkerboard grid on the BACKGROUND layer of a frame.
local function applyCheckerboard(frame, width, height, tileSize)
    if not frame or type(frame.CreateTexture) ~= "function" then
        return
    end
    tileSize = tileSize or 5
    local cols = math.ceil(width / tileSize)
    local rows = math.ceil(height / tileSize)
    local darkTile = { 0.14, 0.16, 0.20, 1 }
    local lightTile = { 0.28, 0.30, 0.35, 1 }

    for r = 0, rows - 1 do
        for c = 0, cols - 1 do
            local tile = frame:CreateTexture(nil, "BACKGROUND", nil, -5)
            local w = math.min(tileSize, width - (c * tileSize))
            local h = math.min(tileSize, height - (r * tileSize))
            if w > 0 and h > 0 then
                tile:SetSize(w, h)
                tile:SetPoint("TOPLEFT", frame, "TOPLEFT", c * tileSize, -r * tileSize)
                local isDark = ((r + c) % 2 == 0)
                tile:SetColorTexture(unpack(isDark and darkTile or lightTile))
            end
        end
    end
end

-------------------------------------------------------------------------------
-- 3. COLOR PICKER MODAL DIALOG
-- Objective: Sleek, compact Obsidian Cyberpunk modal dialog for selecting RGBA colors.
-------------------------------------------------------------------------------

--- Retrieves or creates the shared singleton Color Picker modal dialog.
--- @return table dialog The ColorPicker modal dialog frame.
function Context:getOrCreateColorPickerDialog()
    if self.colorPickerDialog then
        return self.colorPickerDialog
    end
    if lib.colorPickerDialog then
        return lib.colorPickerDialog
    end

    local styles = self.styles or lib.DefaultStyles
    local dialogWidth = 280
    local dialogHeight = 220

    -- 3.1 BASE MODAL FRAME CONTAINER (Reusing 01Frame.lua)
    local dialog = self:createFrame({
        parent = _G.UIParent,
        width = dialogWidth,
        height = dialogHeight,
        strata = "FULLSCREEN_DIALOG",
        frameLevel = 1000,
        clamped = true,
        showCloseButton = false,
        movable = true,
        closableWithEscape = false,
        borderColor = styles.colors.border,
        backgroundColor = styles.colors.background,
        borderInset = 2
    })
    dialog:SetPoint("CENTER", _G.UIParent, "CENTER", 0, 0)
    dialog:EnableMouse(true)
    dialog:Hide()

    -- Register with UISpecialFrames so Escape key dismisses it cleanly
    if not tContains(_G.UISpecialFrames, dialog:GetName()) then
        table.insert(_G.UISpecialFrames, dialog:GetName() or "AscensionFactoryColorPickerDialog")
    end

    -- Draggable functionality
    if lib.UX and lib.UX.makeDraggable then
        lib.UX:makeDraggable(dialog)
    end

    -- Header Title
    local title = dialog:CreateFontString(nil, "ARTWORK", styles.fonts.label or "GameFontNormal")
    title:SetPoint("TOPLEFT", dialog, "TOPLEFT", 12, -10)
    title:SetText("COLOR PICKER")
    title:SetTextColor(unpack(styles.colors.primary))
    dialog.title = title

    -- Close Button (X)
    local closeButton = self:createIconButton({
        parent = dialog,
        iconType = "close",
        size = 18,
        point = "TOPRIGHT",
        relativeTo = dialog,
        relativePoint = "TOPRIGHT",
        xOffset = -6,
        yOffset = -6,
        onClick = function()
            dialog:cancelAndClose()
        end
    })
    dialog.closeButton = closeButton

    -- 3.2 PREVIEWS SECTION: "Current" vs "New" & Inline Hex InputField (Compact Row)
    local previewSectionY = -32

    -- CURRENT COLOR BOX (Clickable to Revert)
    local currentContainer = CreateFrame("Button", nil, dialog)
    currentContainer:SetSize(40, 22)
    currentContainer:SetPoint("TOPLEFT", dialog, "TOPLEFT", 12, previewSectionY)
    
    local curBorder = currentContainer:CreateTexture(nil, "BORDER", nil, 1)
    curBorder:SetAllPoints()
    curBorder:SetColorTexture(unpack(styles.colors.border))
    currentContainer.border = curBorder

    applyCheckerboard(currentContainer, 38, 20, 5)

    local curColorTex = currentContainer:CreateTexture(nil, "ARTWORK", nil, 1)
    curColorTex:SetPoint("TOPLEFT", currentContainer, "TOPLEFT", 1, -1)
    curColorTex:SetPoint("BOTTOMRIGHT", currentContainer, "BOTTOMRIGHT", -1, 1)
    curColorTex:SetColorTexture(1, 1, 1, 1)
    dialog.currentBoxColor = curColorTex

    -- Tooltip on Current explaining click to revert
    currentContainer:SetScript("OnEnter", function()
        curBorder:SetColorTexture(unpack(styles.colors.primaryHover or { 1, 0.5, 0, 1 }))
        if lib.UX and lib.UX.showTooltip then
            lib.UX:showTooltip(currentContainer, {
                title = "Original Color",
                desc = "Click to restore original starting color."
            })
        end
    end)
    currentContainer:SetScript("OnLeave", function()
        curBorder:SetColorTexture(unpack(styles.colors.border))
        if lib.UX and lib.UX.hideTooltip then
            lib.UX:hideTooltip()
        end
    end)
    currentContainer:SetScript("OnClick", function()
        if dialog.originalColor then
            dialog:loadColor(unpack(dialog.originalColor))
        end
    end)

    -- Arrow separator
    local arrowText = dialog:CreateFontString(nil, "ARTWORK", styles.fonts.text or "GameFontHighlight")
    arrowText:SetPoint("LEFT", currentContainer, "RIGHT", 6, 0)
    arrowText:SetText("→")
    arrowText:SetTextColor(unpack(styles.colors.steelHighlight or { 0.5, 0.5, 0.5, 1 }))

    -- NEW COLOR BOX
    local newContainer = CreateFrame("Frame", nil, dialog)
    newContainer:SetSize(40, 22)
    newContainer:SetPoint("LEFT", arrowText, "RIGHT", 6, 0)

    local newBorder = newContainer:CreateTexture(nil, "BORDER", nil, 1)
    newBorder:SetAllPoints()
    newBorder:SetColorTexture(unpack(styles.colors.primary))
    dialog.newBoxBorder = newBorder

    applyCheckerboard(newContainer, 38, 20, 5)

    local newColorTex = newContainer:CreateTexture(nil, "ARTWORK", nil, 1)
    newColorTex:SetPoint("TOPLEFT", newContainer, "TOPLEFT", 1, -1)
    newColorTex:SetPoint("BOTTOMRIGHT", newContainer, "BOTTOMRIGHT", -1, 1)
    newColorTex:SetColorTexture(1, 1, 1, 1)
    dialog.newBoxColor = newColorTex

    -- INLINE HEX INPUT FIELD
    local hexLabel = dialog:CreateFontString(nil, "ARTWORK", styles.fonts.text or "GameFontNormalSmall")
    hexLabel:SetPoint("LEFT", newContainer, "RIGHT", 12, 0)
    hexLabel:SetText("HEX #")
    hexLabel:SetTextColor(unpack(styles.colors.primaryHover or styles.colors.primary))

    local hexInput = self:createInputField({
        parent = dialog,
        width = 82,
        height = 22,
        placeholder = "RRGGBB",
        point = "LEFT",
        relativeTo = hexLabel,
        relativePoint = "RIGHT",
        xOffset = 4,
        yOffset = 0
    })
    dialog.hexInput = hexInput

    -- 3.3 RGBA CHANNEL SLIDERS SETUP (Compact Inline Rows)
    dialog.sliders = {}
    local channels = {
        { key = "r", label = "R", color = { 1.0, 0.30, 0.30 }, max = 255 },
        { key = "g", label = "G", color = { 0.30, 1.0, 0.40 }, max = 255 },
        { key = "b", label = "B", color = { 0.35, 0.60, 1.0 }, max = 255 },
        { key = "a", label = "A", color = { 0.90, 0.90, 0.90 }, max = 100 }
    }

    local slidersStartY = -64
    local sliderSpacingY = 20
    local sliderLength = 196

    -- Synchronizes dialog state, preview boxes, hex text, and live target
    local function updateDialogState(sourceKey)
        local rVal = dialog.sliders.r.value / 255
        local gVal = dialog.sliders.g.value / 255
        local bVal = dialog.sliders.b.value / 255
        local aVal = dialog.sliders.a.value / 100

        dialog.workingColor = { rVal, gVal, bVal, aVal }
        dialog.newBoxColor:SetColorTexture(rVal, gVal, bVal, aVal)

        -- Update Hex input if not currently typing in it
        if sourceKey ~= "hex" and dialog.hexInput and dialog.hexInput.editBox then
            if not dialog.hexInput.editBox:HasFocus() then
                local hexCode = rgbToHex(rVal, gVal, bVal)
                dialog.hexInput:setText(hexCode)
            end
        end

        -- Update slider track gradients to reflect color progression
        if dialog.sliders.r and dialog.sliders.r.slider.fill then
            dialog.sliders.r.slider.fill:SetGradient("HORIZONTAL", CreateColor(0, gVal, bVal, 1), CreateColor(1, gVal, bVal, 1))
        end
        if dialog.sliders.g and dialog.sliders.g.slider.fill then
            dialog.sliders.g.slider.fill:SetGradient("HORIZONTAL", CreateColor(rVal, 0, bVal, 1), CreateColor(rVal, 1, bVal, 1))
        end
        if dialog.sliders.b and dialog.sliders.b.slider.fill then
            dialog.sliders.b.slider.fill:SetGradient("HORIZONTAL", CreateColor(rVal, gVal, 0, 1), CreateColor(rVal, gVal, 1, 1))
        end
        if dialog.sliders.a and dialog.sliders.a.slider.fill then
            dialog.sliders.a.slider.fill:SetGradient("HORIZONTAL", CreateColor(rVal, gVal, bVal, 0), CreateColor(rVal, gVal, bVal, 1))
        end

        -- Live preview on active consuming target
        if dialog.activeTarget and dialog.activeTarget.applyWorkingColor then
            dialog.activeTarget:applyWorkingColor(rVal, gVal, bVal, aVal)
        end
    end

    -- Hook Hex input text changed for two-way synchronization
    if hexInput.editBox then
        hexInput.editBox:HookScript("OnTextChanged", function(editBox, isUserInput)
            if not isUserInput then return end
            local text = editBox:GetText()
            local r, g, b = hexToRgb(text)
            if r and g and b then
                dialog.sliders.r.slider:setValue(math.floor(r * 255 + 0.5), true, false)
                dialog.sliders.g.slider:setValue(math.floor(g * 255 + 0.5), true, false)
                dialog.sliders.b.slider:setValue(math.floor(b * 255 + 0.5), true, false)
                dialog.sliders.r.value = math.floor(r * 255 + 0.5)
                dialog.sliders.g.value = math.floor(g * 255 + 0.5)
                dialog.sliders.b.value = math.floor(b * 255 + 0.5)
                dialog.sliders.r.valLabel:SetText(tostring(dialog.sliders.r.value))
                dialog.sliders.g.valLabel:SetText(tostring(dialog.sliders.g.value))
                dialog.sliders.b.valLabel:SetText(tostring(dialog.sliders.b.value))
                updateDialogState("hex")
            end
        end)
    end

    for idx, ch in ipairs(channels) do
        local rowY = slidersStartY - ((idx - 1) * sliderSpacingY)

        local channelLabel = dialog:CreateFontString(nil, "ARTWORK", styles.fonts.label or "GameFontNormalSmall")
        channelLabel:SetPoint("TOPLEFT", dialog, "TOPLEFT", 12, rowY)
        channelLabel:SetText(ch.label)
        channelLabel:SetTextColor(unpack(ch.color))
        channelLabel:SetWidth(14)
        channelLabel:SetJustifyH("LEFT")

        local valLabel = dialog:CreateFontString(nil, "ARTWORK", styles.fonts.text or "GameFontHighlightSmall")
        valLabel:SetPoint("TOPRIGHT", dialog, "TOPRIGHT", -12, rowY)
        valLabel:SetText(tostring(ch.max))
        valLabel:SetTextColor(unpack(styles.colors.white))
        valLabel:SetWidth(36)
        valLabel:SetJustifyH("RIGHT")

        local slider = self:createSlider({
            parent = dialog,
            orientation = "HORIZONTAL",
            length = sliderLength,
            height = 10,
            minValue = 0,
            maxValue = ch.max,
            step = 1,
            value = ch.max,
            thumbShape = "capsule",
            point = "LEFT",
            relativeTo = channelLabel,
            relativePoint = "RIGHT",
            xOffset = 4,
            yOffset = 0,
            onValueChanged = function(_, val, isUserInput)
                dialog.sliders[ch.key].value = val
                if ch.key == "a" then
                    valLabel:SetText(math.floor(val) .. "%")
                else
                    valLabel:SetText(tostring(math.floor(val)))
                end
                updateDialogState(ch.key)
            end
        })

        dialog.sliders[ch.key] = {
            slider = slider,
            valLabel = valLabel,
            max = ch.max,
            value = ch.max
        }
    end

    -- 3.4 RECENT COLORS HISTORY ROW (8 Slots)
    local recentHeader = dialog:CreateFontString(nil, "ARTWORK", styles.fonts.text or "GameFontHighlightSmall")
    recentHeader:SetPoint("TOPLEFT", dialog, "TOPLEFT", 12, -145)
    recentHeader:SetText("RECENT")
    recentHeader:SetTextColor(unpack(styles.colors.steelHighlight or { 0.6, 0.6, 0.6, 1 }))

    dialog.recentSwatches = {}
    local slotWidth = 28
    local slotHeight = 14
    local slotSpacing = 4

    for i = 1, 8 do
        local slotBtn = CreateFrame("Button", nil, dialog)
        slotBtn:SetSize(slotWidth, slotHeight)
        slotBtn:SetPoint("TOPLEFT", dialog, "TOPLEFT", 12 + ((i - 1) * (slotWidth + slotSpacing)), -160)

        local slotBorder = slotBtn:CreateTexture(nil, "BORDER", nil, 1)
        slotBorder:SetAllPoints()
        slotBorder:SetColorTexture(unpack(styles.colors.border))
        slotBtn.border = slotBorder

        applyCheckerboard(slotBtn, slotWidth - 2, slotHeight - 2, 4)

        local slotColorTex = slotBtn:CreateTexture(nil, "ARTWORK", nil, 1)
        slotColorTex:SetPoint("TOPLEFT", slotBtn, "TOPLEFT", 1, -1)
        slotColorTex:SetPoint("BOTTOMRIGHT", slotBtn, "BOTTOMRIGHT", -1, 1)
        slotBtn.colorTex = slotColorTex

        slotBtn:SetScript("OnEnter", function()
            slotBorder:SetColorTexture(unpack(styles.colors.primaryHover or { 1, 0.5, 0, 1 }))
        end)
        slotBtn:SetScript("OnLeave", function()
            slotBorder:SetColorTexture(unpack(styles.colors.border))
        end)
        slotBtn:SetScript("OnClick", function()
            if slotBtn.colorData then
                dialog:loadColor(unpack(slotBtn.colorData))
            end
        end)

        dialog.recentSwatches[i] = slotBtn
    end

    --- Refreshes the recent swatches row from lib.recentColors
    local function refreshRecentSwatches()
        for i, slotBtn in ipairs(dialog.recentSwatches) do
            local color = lib.recentColors[i]
            if color then
                slotBtn.colorData = color
                slotBtn.colorTex:SetColorTexture(unpack(color))
                slotBtn:Show()
            else
                slotBtn.colorData = nil
                slotBtn:Hide()
            end
        end
    end

    --- Adds a newly committed color to lib.recentColors history (FIFO, up to 8 slots)
    local function recordRecentColor(r, g, b, a)
        for idx, col in ipairs(lib.recentColors) do
            if math.abs(col[1] - r) < 0.01 and math.abs(col[2] - g) < 0.01 and math.abs(col[3] - b) < 0.01 and math.abs(col[4] - a) < 0.01 then
                table.remove(lib.recentColors, idx)
                break
            end
        end
        table.insert(lib.recentColors, 1, { r, g, b, a })
        while #lib.recentColors > 8 do
            table.remove(lib.recentColors)
        end
        refreshRecentSwatches()
    end

    -- 3.5 ACTION BUTTONS: ACCEPT AND CANCEL (Reusing 05Button.lua)
    local acceptButton = self:createButton({
        parent = dialog,
        text = "Accept",
        width = 124,
        height = 22,
        point = "BOTTOMLEFT",
        relativeTo = dialog,
        relativePoint = "BOTTOMLEFT",
        xOffset = 12,
        yOffset = 10,
        borderColors = {
            normal = styles.colors.neonGreen or { 0, 1, 0.5, 1 },
            hover = styles.colors.primaryHover,
            active = styles.colors.neonGreen,
            disabled = styles.colors.surfaceLight
        },
        onClick = function()
            dialog:acceptAndClose()
        end
    })
    dialog.acceptButton = acceptButton

    local cancelButton = self:createButton({
        parent = dialog,
        text = "Cancel",
        width = 124,
        height = 22,
        point = "BOTTOMRIGHT",
        relativeTo = dialog,
        relativePoint = "BOTTOMRIGHT",
        xOffset = -12,
        yOffset = 10,
        borderColors = {
            normal = styles.colors.border,
            hover = styles.colors.neonRed or { 1, 0.2, 0.2, 1 },
            active = styles.colors.neonRed,
            disabled = styles.colors.surfaceLight
        },
        onClick = function()
            dialog:cancelAndClose()
        end
    })
    dialog.cancelButton = cancelButton

    -- 3.6 DIALOG CONTROLLER METHODS
    function dialog:loadColor(r, g, b, a)
        a = a or 1
        local r255 = math.floor(r * 255 + 0.5)
        local g255 = math.floor(g * 255 + 0.5)
        local b255 = math.floor(b * 255 + 0.5)
        local a100 = math.floor(a * 100 + 0.5)

        self.sliders.r.slider:setValue(r255, true, false)
        self.sliders.g.slider:setValue(g255, true, false)
        self.sliders.b.slider:setValue(b255, true, false)
        self.sliders.a.slider:setValue(a100, true, false)

        self.sliders.r.value = r255
        self.sliders.g.value = g255
        self.sliders.b.value = b255
        self.sliders.a.value = a100

        self.sliders.r.valLabel:SetText(tostring(r255))
        self.sliders.g.valLabel:SetText(tostring(g255))
        self.sliders.b.valLabel:SetText(tostring(b255))
        self.sliders.a.valLabel:SetText(a100 .. "%")

        updateDialogState("load")
    end

    function dialog:openForTarget(target)
        self.activeTarget = target
        local r, g, b, a = target:getColor()
        self.originalColor = { r, g, b, a }

        self.currentBoxColor:SetColorTexture(r, g, b, a)
        refreshRecentSwatches()
        self:loadColor(r, g, b, a)
        self:Show()
    end

    function dialog:acceptAndClose()
        if self.activeTarget and self.workingColor then
            local c = self.workingColor
            recordRecentColor(c[1], c[2], c[3], c[4])
            self.activeTarget:commitColor(c[1], c[2], c[3], c[4])
        end
        self:Hide()
        self.activeTarget = nil
    end

    function dialog:cancelAndClose()
        if self.activeTarget and self.originalColor then
            local o = self.originalColor
            self.activeTarget:commitColor(o[1], o[2], o[3], o[4])
        end
        self:Hide()
        self.activeTarget = nil
    end

    lib.colorPickerDialog = dialog
    self.colorPickerDialog = dialog
    return dialog
end

-------------------------------------------------------------------------------
-- 4. COLOR PICKER SWATCH COMPONENT FACTORY
-- Objective: Builds the UI trigger widget with checkerboard swatch, label, and modal linkage.
-------------------------------------------------------------------------------

--- Creates an Obsidian Cyberpunk color picker trigger swatch button.
--- @param options table|nil Configuration table for initial color, label text, and callbacks.
--- @return table colorPicker The configured color picker trigger button widget.
function Context:createColorPicker(options)
    options = options or {}
    local uiContext = self
    local styles = self.styles or lib.DefaultStyles
    local text = options.text or ""
    local hasAlpha = options.hasAlpha ~= false

    -- 4.1 INHERIT BASE BUTTON
    local btnOptions = {}
    for k, v in pairs(options) do
        btnOptions[k] = v
    end
    btnOptions.borderColors = btnOptions.borderColors or {
        normal = styles.colors.border,
        hover = styles.colors.primaryHover,
        active = styles.colors.primaryActive,
        disabled = styles.colors.surfaceLight
    }

    local colorPicker = self:createButton(btnOptions)
    local buttonHeight = colorPicker:GetHeight() or 26
    local swatchSize = options.swatchSize or options.boxSize or (buttonHeight - 4)

    -- Initial color resolution
    local curR, curG, curB, curA = 1, 1, 1, 1
    if options.getter then
        curR, curG, curB, curA = normalizeColor(options.getter())
    elseif options.color then
        curR, curG, curB, curA = normalizeColor(options.color)
    end
    colorPicker.currentColor = { curR, curG, curB, curA }

    -- 4.2 SWATCH CONTAINER WITH CHECKERBOARD UNDERLAY
    local swatchWrap = CreateFrame("Frame", nil, colorPicker)
    swatchWrap:SetSize(swatchSize, swatchSize)
    swatchWrap:SetPoint("LEFT", colorPicker, "LEFT", 4, 0)
    
    local swatchBorder = swatchWrap:CreateTexture(nil, "BORDER", nil, 1)
    swatchBorder:SetAllPoints()
    swatchBorder:SetColorTexture(unpack(styles.colors.border))
    colorPicker.swatchBorder = swatchBorder

    applyCheckerboard(swatchWrap, swatchSize - 2, swatchSize - 2, 4)

    local swatchColorTex = swatchWrap:CreateTexture(nil, "ARTWORK", nil, 1)
    swatchColorTex:SetPoint("TOPLEFT", swatchWrap, "TOPLEFT", 1, -1)
    swatchColorTex:SetPoint("BOTTOMRIGHT", swatchWrap, "BOTTOMRIGHT", -1, 1)
    colorPicker.swatchColor = swatchColorTex

    local function updateVisuals()
        local c = colorPicker.currentColor
        swatchColorTex:SetColorTexture(c[1], c[2], c[3], c[4])
    end
    updateVisuals()

    -- 4.3 TEXT LABEL ADJUSTMENT
    local label = colorPicker:GetFontString()
    if label then
        colorPicker.label = label
        label:ClearAllPoints()
        label:SetJustifyH("LEFT")
        label:SetWidth(0)
        if text ~= "" then
            label:SetPoint("LEFT", swatchWrap, "RIGHT", 8, 0)
            label:Show()
            local labelWidth = label:GetStringWidth() or 0
            if not options.width then
                colorPicker:SetWidth(swatchSize + 16 + labelWidth)
            end
        else
            label:Hide()
            if not options.width then
                colorPicker:SetWidth(swatchSize + 8)
            end
        end
    end

    -- 4.4 INTERACTIVITY & BROADCASTING
    function colorPicker:applyWorkingColor(r, g, b, a)
        self.currentColor = { r, g, b, a }
        updateVisuals()
        if type(options.onChange) == "function" then
            options.onChange(self.currentColor, r, g, b, a)
        end
    end

    function colorPicker:commitColor(r, g, b, a)
        self.currentColor = { r, g, b, a }
        updateVisuals()
        if type(options.setter) == "function" then
            options.setter(self.currentColor, r, g, b, a)
        end
        if type(options.onChange) == "function" then
            options.onChange(self.currentColor, r, g, b, a)
        end
    end

    local function openDialog()
        if not colorPicker:IsEnabled() then return end
        local dialog = uiContext:getOrCreateColorPickerDialog()
        dialog:openForTarget(colorPicker)
    end

    colorPicker:SetScript("OnClick", function(self, buttonName, down)
        if options.onClick then
            options.onClick(self, self.currentColor, buttonName, down)
        end
        openDialog()
    end)

    -- 4.5 EXTERNAL API METHODS
    function colorPicker:getColor()
        local c = self.currentColor
        return c[1], c[2], c[3], c[4], c
    end
    colorPicker.GetColor = colorPicker.getColor

    function colorPicker:setColor(firstArg, g, b, a)
        local nr, ng, nb, na
        if type(firstArg) == "table" then
            nr, ng, nb, na = normalizeColor(firstArg)
        else
            nr = firstArg or 1
            ng = g or 1
            nb = b or 1
            na = a
            if na == nil then na = 1 end
        end
        self:commitColor(nr, ng, nb, na)
    end
    colorPicker.SetColor = colorPicker.setColor

    function colorPicker:setText(newText)
        if self.label then
            self.label:SetText(newText)
            self.label:SetWidth(0)
            local labelWidth = self.label:GetStringWidth() or 0
            if not options.width then
                self:SetWidth(swatchSize + 16 + labelWidth)
            end
        end
    end
    colorPicker.SetText = colorPicker.setText

    function colorPicker:openColorPicker()
        openDialog()
    end
    colorPicker.OpenColorPicker = colorPicker.openColorPicker

    return colorPicker
end

-- Global library aliases for immediate access
lib.createColorPicker = function(options)
    local defaultCtx = lib:createContext()
    return defaultCtx:createColorPicker(options)
end

lib.openColorPicker = function(target)
    local defaultCtx = lib:createContext()
    local dialog = defaultCtx:getOrCreateColorPickerDialog()
    dialog:openForTarget(target)
    return dialog
end
