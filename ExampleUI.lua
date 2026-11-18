-------------------------------------------------------------------------------
-- Project: AscensionFactory
-- Author: Aka-DoctorCode
-- File: ExampleUI.lua
-------------------------------------------------------------------------------
---@diagnostic disable: undefined-global, undefined-field, inject-field

local addonName, addonTable = ...
local AscensionFactory = LibStub:GetLibrary("AscensionFactory")
if not AscensionFactory then return end

-------------------------------------------------------------------------------
-- CONTEXT INITIALIZATION
-------------------------------------------------------------------------------

local uiContext = AscensionFactory:createContext()
local styles = uiContext.styles

do
    local rawCreateIconBtn = uiContext.createIconButton
    local rawCreateBtn = uiContext.createButton
    local rawCreateInput = uiContext.createInputField
    local rawCreateSlider = uiContext.createSlider

    uiContext.createIconButton = function(self, opts)
        if type(opts) == "table" and opts.tooltip == nil then opts.tooltip = "" end
        return rawCreateIconBtn(self, opts)
    end
    uiContext.createButton = function(self, opts)
        if type(opts) == "table" and opts.tooltip == nil then opts.tooltip = "" end
        return rawCreateBtn(self, opts)
    end
    uiContext.createInputField = function(self, opts)
        if type(opts) == "table" and opts.tooltip == nil then opts.tooltip = "" end
        return rawCreateInput(self, opts)
    end
    uiContext.createSlider = function(self, opts)
        if type(opts) == "table" and opts.tooltip == nil then opts.tooltip = "" end
        return rawCreateSlider(self, opts)
    end
end

-------------------------------------------------------------------------------
-- PALETTE MENU LOGIC
-------------------------------------------------------------------------------
--- Creates a visual palette viewer showing all defined theme colors.
local function createPaletteFrame(parent)
    if _G["AscensionFactoryPaletteFrame"] then
        _G["AscensionFactoryPaletteFrame"]:Hide()
    end

    local frameHeight = parent and parent:GetHeight() or 500
    local frameWidth = 220

    local paletteFrame = uiContext:createFrame({
        name = "AscensionFactoryPaletteFrame",
        parent = parent or UIParent,
        width = frameWidth,
        height = frameHeight,
        borderColor = styles.colors.border,
        backgroundColor = styles.colors.background
    })
    _G["AscensionFactoryPaletteFrame"] = paletteFrame
    paletteFrame.globalName = "AscensionFactoryPaletteFrame"
    paletteFrame:SetFrameStrata("TOOLTIP")

    if parent then
        -- Integrated: Anchor to the main frame with identical height bounds
        paletteFrame:ClearAllPoints()
        paletteFrame:SetPoint("TOPRIGHT", parent, "TOPLEFT", -5, 0)
        paletteFrame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMLEFT", -5, 0)
        paletteFrame:SetWidth(frameWidth)
    else
        -- Standalone: Anchor to center and enable UX behaviors
        paletteFrame:ClearAllPoints()
        paletteFrame:SetPoint("CENTER")
        paletteFrame:SetSize(frameWidth, frameHeight)
        if AscensionFactory.UX then
            AscensionFactory.UX:makeMovable(paletteFrame, { savePosition = true })
            AscensionFactory.UX:makeClosableWithEscape(paletteFrame)
        end
    end

    -- Header
    local _, headerY = uiContext:createHeader({
            name = "AscensionExample_Header_1",
            wordWrap = true,
        parent = paletteFrame,
        text = "Global Palette",
        xOffset = 12,
        yOffset = -12,
        fontSize = 18
    })

    -- Scrollable Container filling the palette frame
    local scrollContainer = CreateFrame("Frame", nil, paletteFrame)
    scrollContainer:SetPoint("TOPLEFT", paletteFrame, "TOPLEFT", 6, headerY - 6)
    scrollContainer:SetPoint("BOTTOMRIGHT", paletteFrame, "BOTTOMRIGHT", -6, 8)

    local _, scrollContent, scrollbar = AscensionFactory.UX:makeScrollable(scrollContainer, {
        uiContext = uiContext,
        scrollBarWidth = 10,
        scrollBarGap = 2,
        thumbShape = "capsule",
        step = 28,
        bottomPadding = 12
    })

    local currentY = -6
    local colorKeys = {}
    if styles and styles.colors then
        for key in pairs(styles.colors) do
            table.insert(colorKeys, key)
        end
        table.sort(colorKeys)
    end

    for _, key in ipairs(colorKeys) do
        local color = styles.colors[key]
        if color then
            local row = CreateFrame("Frame", nil, scrollContent)
            row:SetSize(frameWidth - 30, 24)
            row:SetPoint("TOPLEFT", scrollContent, "TOPLEFT", 4, currentY)

            -- Visual Swatch with border
            local colorSwatch = CreateFrame("Frame", nil, row)
            colorSwatch:SetSize(18, 18)
            colorSwatch:SetPoint("LEFT", row, "LEFT", 2, 0)

            local swatchBorder = colorSwatch:CreateTexture(nil, "BACKGROUND")
            swatchBorder:SetAllPoints()
            swatchBorder:SetColorTexture(unpack(styles.colors.border))

            local swatchTexture = colorSwatch:CreateTexture(nil, "ARTWORK")
            swatchTexture:SetPoint("TOPLEFT", colorSwatch, "TOPLEFT", 1, -1)
            swatchTexture:SetPoint("BOTTOMRIGHT", colorSwatch, "BOTTOMRIGHT", -1, 1)
            swatchTexture:SetColorTexture(unpack(color))

            local colorLabel = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            colorLabel:SetPoint("LEFT", colorSwatch, "RIGHT", 8, 0)
            colorLabel:SetPoint("RIGHT", row, "RIGHT", -2, 0)
            colorLabel:SetJustifyH("LEFT")
            colorLabel:SetText(key)

            currentY = currentY - 26
        end
    end

    scrollContent:SetHeight(math.abs(currentY) + 12)
    if scrollContainer.updateScrollRange then
        scrollContainer:updateScrollRange()
    end

    return paletteFrame
end

-------------------------------------------------------------------------------
-- MAIN GALLERY CREATION
-------------------------------------------------------------------------------
--- Orchestrates the creation of the entire UI component gallery.
local function createMockUi()
    local frame = uiContext:createMainFrame({
        name = "AscensionFactoryMockFrame",
        parent = UIParent,
        width = 1000,
        height = 500,
        resizable = true,
        savePosition = true,
        saveSize = true,
        minWidth = 400,
        minHeight = 200,
    })
    local header, nextY = uiContext:createHeader({
            name = "AscensionExample_Header_2",
            wordWrap = true,
        parent = frame,
        text = "Ascension Factory",
        xOffset = 10,
        yOffset = -10,
        fontSize = 34,
        spaceBelow = 4,
    })

    -- Attach Tabbed Interface (Sidebar)
    local tabbedInterface = uiContext:createTabbedInterface({
        name = "AscensionExampleTabbedInterface",
        parent = frame,
        startY = nextY,
        initialIndex = 1,
        sidebarWidth = 160,
        tabs = { "Framing", "Text", "Buttons", "Inputs", "Sliders", "Steppers", "Dropdowns", "Scrollable", "Tooltips & Menus", "Toasts", "Color Picker" }
    })

    -- Intro Panel
    local introPanel = tabbedInterface.panels[1]
    local introLayout = uiContext:createLayoutModel(introPanel, { verticalGap = 10 })
    introLayout:header("AscensionExample_Header_3", "Welcome to the Ascension Factory UI", {
        wordWrap = true,
        xOffset = 10,
        rightOffset = -10,
    })
    introLayout:paragraph("AscensionExample_Paragraph_1", {
        text = "The main window enclosing this interface is an example of the Frame builder from 01Frame.lua. The sidebar navigation on the left, along with the dynamic panels you are currently viewing, demonstrates the TabbedInterface builder from 02TabbedInterface.lua.",
        xOffset = 10,
        rightOffset = -10,
        fontSize = 24,
    })
    introLayout:paragraph("AscensionExample_Paragraph_2", {
        text = "Below is an example of the TwoColumnInterface component, which splits the layout evenly.",
        xOffset = 10,
        rightOffset = -10,
        fontSize = 16,
    })
    introLayout:row({
        name = "MockUITwoColumn",
        gap = 10,
        xOffset = 10,
        rightOffset = -10,
        threshold = 420,
        columns = {
            {
                backgroundColor = styles.colors.surfaceLight,
                populate = function(col)
                    col:paragraph("AscensionExample_Paragraph_3", {
                        text = "This is the left column. It takes up half the width minus a small gap.",
                        xOffset = 10,
                        rightOffset = -10,
                        fontSize = 16,
                    })
                end,
            },
            {
                backgroundColor = styles.colors.surfaceLight,
                populate = function(col)
                    col:paragraph("AscensionExample_Paragraph_4", {
                        text = "This is the right column. It sits exactly 10 pixels away from the left column.",
                        xOffset = 10,
                        rightOffset = -10,
                        fontSize = 16,
                    })
                end,
            },
        },
    })

    -- Header Panel
    local headerPanel = tabbedInterface.panels[2]
    local headerLayout = uiContext:createLayoutModel(headerPanel, { verticalGap = 10 })
    headerLayout:header("AscensionExample_Header_4", "Header Text: Used for section titles.", {
        wordWrap = true,
        xOffset = 10,
        rightOffset = -10,
    })
    headerLayout:label("AscensionExample_Label_1", "Label Text: Used for standard options.", {
        wordWrap = true,
        xOffset = 10,
        rightOffset = -10,
    })
    headerLayout:paragraph("AscensionExample_Paragraph_5", {
        text = "Paragraph Text: Used for long descriptions or explanations like this one. It handles wrapping and smaller font size.",
        xOffset = 10,
        rightOffset = -10,
        fontSize = 16,
    })

    -- Buttons Panel
    local buttonPanel = tabbedInterface.panels[3]
    local buttonLayout = uiContext:createLayoutModel(buttonPanel, { verticalGap = 10 })
    buttonLayout:header("AscensionExample_Header_5", "Button Component", {
        wordWrap = true,
        xOffset = 10,
        rightOffset = -10,
    })
    buttonLayout:row({
        name = "MockUIButtonTwoColumn",
        gap = 10,
        xOffset = 10,
        rightOffset = -10,
        threshold = 420,
        columns = {
            {
                populate = function(col)
                    col:button("MockUIExampleBtn", { text = "Enabled Button", width = 180, height = 40, tooltip = "" })
                    local disabledButton = col:button("MockUIDisabledBtn", { text = "Disabled Button", width = 180, height = 30, tooltip = "" })
                    disabledButton:Disable()

                    col:label("AscensionExample_Label_2", "Toggle Button", { wordWrap = true, elasticWidth = true })
                    col:toggle("MockUIExampleToggle", {
                        tooltip = "",
                        width = 50,
                        height = 24,
                        getter = function() return false end,
                        setter = function(state) end,
                    })

                    col:label("AscensionExample_Label_3", "Checkbox Component", { wordWrap = true, elasticWidth = true })
                    col:checkbox("MockUIExampleCheckbox", { text = "Enable Auto Target", width = 180, height = 25, checked = true, tooltip = "" })
                    local disabledCheckbox = col:checkbox("MockUIDisabledCheckbox", { text = "Locked Feature", width = 180, height = 25, checked = true, tooltip = "" })
                    disabledCheckbox:Disable()

                    col:label("AscensionExample_Label_4", "Dialog Actions", { wordWrap = true, elasticWidth = true })
                    col:add(uiContext:createDialogButton({
                        tooltip = "",
                        parent = col.currentParent,
                        name = "MockUIAcceptButton",
                        variant = "accept",
                    }))
                    col:add(uiContext:createDialogButton({
                        tooltip = "",
                        parent = col.currentParent,
                        name = "MockUICancelButton",
                        variant = "cancel",
                    }))
                    col:add(uiContext:createDialogButton({
                        tooltip = "",
                        parent = col.currentParent,
                        name = "MockUINeutralButton",
                        variant = "neutral",
                        text = "Apply",
                    }))
                end,
            },
            {
                populate = function(col)
                    local icons = {
                        { "AscensionExample_Label_5", "Close", "MockUIIconClose", "close" },
                        { "AscensionExample_Label_8", "Minimize", "MockUIIconMinimize", "minimize" },
                        { "AscensionExample_Label_6", "Plus", "MockUIIconPlus", "plus" },
                        { "AscensionExample_Label_9", "Minus", "MockUIIconMinus", "minus" },
                        { "AscensionExample_Label_7", "Maximize", "MockUIIconMaximize", "maximize" },
                        { "AscensionExample_Label_10", "Arrow", "MockUIIconArrowDown", "arrowdown" },
                    }
                    for _, info in ipairs(icons) do
                        col:label(info[1], info[2], { wordWrap = true, elasticWidth = true })
                        col:add(uiContext:createIconButton({
                            tooltip = "",
                            parent = col.currentParent,
                            name = info[3],
                            iconType = info[4],
                            size = 30,
                        }))
                    end
                end,
            },
        },
    })

    -- Inputs Panel
    local inputPanel = tabbedInterface.panels[4]
    local inputLayout = uiContext:createLayoutModel(inputPanel, { verticalGap = 10 })
    inputLayout:header("AscensionExample_Header_6", "Input Field Component", {
        wordWrap = true,
        xOffset = 10,
        rightOffset = -10,
    })
    inputLayout:row({
        name = "MockUIInputTwoColumn",
        gap = 10,
        xOffset = 10,
        rightOffset = -10,
        threshold = 420,
        columns = {
            {
                populate = function(col)
                    col:label("AscensionExample_Label_11", "Single-Line Input (with placeholder)", { wordWrap = true, elasticWidth = true })
                    col:inputField("MockUIStandardInput", { width = 240, height = 26, placeholder = "Enter character name...", tooltip = "" })

                    col:label("AscensionExample_Label_12", "With Clear Button", { wordWrap = true, elasticWidth = true })
                    col:inputField("MockUIClearInput", { width = 240, height = 26, text = "Pre-filled Search Query", showClear = true, tooltip = "" })

                    col:label("AscensionExample_Label_13", "Numeric Only Input (Max 4 digits)", { wordWrap = true, elasticWidth = true })
                    col:inputField("MockUINumericInput", { width = 120, height = 26, numeric = true, maxLetters = 4, placeholder = "9999", tooltip = "" })
                end,
            },
            {
                populate = function(col)
                    col:label("AscensionExample_Label_14", "Multi-Line Text Area", { wordWrap = true, elasticWidth = true })
                    col:inputField("MockUITextArea", {
                        multiLine = true,
                        width = 250,
                        height = 100,
                        showScrollbar = true,
                        placeholder = "Type notes or macro commands here...",
                        tooltip = "",
                    })
                end,
            },
        },
    })

    -- Sliders Panel
    local sliderPanel = tabbedInterface.panels[5]
    local sliderLayout = uiContext:createLayoutModel(sliderPanel, { verticalGap = 10 })
    sliderLayout:header("AscensionExample_Header_7", "Slider & Scrollbar Component", {
        wordWrap = true,
        xOffset = 10,
        rightOffset = -10,
    })
    sliderLayout:row({
        name = "MockUISliderTwoColumn",
        gap = 10,
        xOffset = 10,
        rightOffset = -10,
        threshold = 420,
        columns = {
            {
                populate = function(col)
                    col:label("AscensionExample_Label_15", "Horizontal Sliders", { wordWrap = true, elasticWidth = true })

                    local slider1ValueLabel = col:label("AscensionExample_Label_16", "Standard: 50%", { wordWrap = true, elasticWidth = true })
                    col:slider("MockUIHorizontalSlider1", {
                        tooltip = "",
                        orientation = "HORIZONTAL",
                        length = 260,
                        height = 16,
                        minValue = 0,
                        maxValue = 100,
                        step = 1,
                        value = 50,
                        onValueChanged = function(self, val)
                            slider1ValueLabel:SetText(string.format("Standard: %d%%", math.floor(val)))
                        end,
                    })

                    local slider2ValueLabel = col:label("AscensionExample_Label_17", "With Progress Fill: 75%", { wordWrap = true, elasticWidth = true })
                    col:slider("MockUIHorizontalSlider2", {
                        tooltip = "",
                        orientation = "HORIZONTAL",
                        length = 260,
                        height = 16,
                        minValue = 0,
                        maxValue = 100,
                        step = 5,
                        value = 75,
                        showFill = true,
                        onValueChanged = function(self, val)
                            slider2ValueLabel:SetText(string.format("With Progress Fill: %d%%", math.floor(val)))
                        end,
                    })

                    local slider3ValueLabel = col:label("AscensionExample_Label_18", "Stepped (1-10): Value 4", { wordWrap = true, elasticWidth = true })
                    col:slider("MockUIHorizontalSlider3", {
                        tooltip = "",
                        orientation = "HORIZONTAL",
                        length = 260,
                        height = 16,
                        minValue = 1,
                        maxValue = 10,
                        step = 1,
                        value = 4,
                        showFill = true,
                        onValueChanged = function(self, val)
                            slider3ValueLabel:SetText(string.format("Stepped (1-10): Value %d", math.floor(val)))
                        end,
                    })

                    local slider4ValueLabel = col:label("AscensionExample_Label_18b", "Composite Slider + Stepper: 50", { wordWrap = true, elasticWidth = true })
                    col:sliderWithStepper("MockUIHorizontalSliderWithStepper", {
                        tooltip = "",
                        length = 260,
                        height = 14,
                        minValue = 0,
                        maxValue = 100,
                        step = 1,
                        value = 50,
                        showFill = true,
                        onValueChanged = function(self, val)
                            slider4ValueLabel:SetText(string.format("Composite Slider + Stepper: %d", math.floor(val)))
                        end,
                    })
                end,
            },
            {
                populate = function(col)
                    col:label("AscensionExample_Label_19", "Vertical Scrollbars", { wordWrap = true, elasticWidth = true })
                    col:row({
                        gap = 10,
                        threshold = 180,
                        columns = {
                            {
                                populate = function(subCol)
                                    subCol:label("AscensionExample_Label_20", "Scrollbar", { wordWrap = true, elasticWidth = true })
                                    subCol:slider("MockUIVerticalScrollbar", {
                                        tooltip = "",
                                        orientation = "VERTICAL",
                                        length = 200,
                                        width = 14,
                                        minValue = 0,
                                        maxValue = 100,
                                        step = 5,
                                        value = 20,
                                    })
                                end,
                            },
                            {
                                populate = function(subCol)
                                    subCol:label("AscensionExample_Label_21", "Filled Meter", { wordWrap = true, elasticWidth = true })
                                    subCol:slider("MockUIVerticalFilled", {
                                        tooltip = "",
                                        orientation = "VERTICAL",
                                        length = 200,
                                        width = 14,
                                        minValue = 0,
                                        maxValue = 100,
                                        step = 1,
                                        value = 60,
                                        showFill = true,
                                        inverted = true,
                                    })
                                end,
                            },
                        },
                    })
                end,
            },
        },
    })

    -- Steppers Panel
    local stepperPanel = tabbedInterface.panels[6]
    local stepperLayout = uiContext:createLayoutModel(stepperPanel, { verticalGap = 10 })
    stepperLayout:header("AscensionExample_Header_8", "Stepper Component", {
        wordWrap = true,
        xOffset = 10,
        rightOffset = -10,
    })
    stepperLayout:row({
        name = "MockUIStepperTwoColumn",
        gap = 10,
        xOffset = 10,
        rightOffset = -10,
        threshold = 420,
        columns = {
            {
                populate = function(col)
                    col:label("AscensionExample_Label_22", "Standard Stepper (0 - 100, Step 1)", { wordWrap = true, elasticWidth = true })
                    col:stepper("MockUIStandardStepper", { tooltip = "", width = 140, height = 26, minValue = 0, maxValue = 100, step = 1, value = 10 })

                    col:label("AscensionExample_Label_23", "Clamped Low Range (1 - 5)", { wordWrap = true, elasticWidth = true })
                    col:stepper("MockUIClampedStepper", { tooltip = "", width = 120, height = 26, minValue = 1, maxValue = 5, step = 1, value = 1 })
                end,
            },
            {
                populate = function(col)
                    col:label("AscensionExample_Label_24", "Decimal Stepper (0.0 - 10.0, Step 0.5)", { wordWrap = true, elasticWidth = true })
                    col:stepper("MockUIDecimalStepper", { tooltip = "", width = 140, height = 26, minValue = 0.0, maxValue = 10.0, step = 0.5, decimals = 1, value = 2.5 })

                    col:label("AscensionExample_Label_25", "Range with Negatives (-50 to +50)", { wordWrap = true, elasticWidth = true })
                    col:stepper("MockUINegativeStepper", { tooltip = "", width = 140, height = 26, minValue = -50, maxValue = 50, step = 10, value = 0, allowNegative = true })
                end,
            },
        },
    })

    -------------------------------------------------------------------------------
    -- 7. DROPDOWNS PANEL
    -------------------------------------------------------------------------------
    local dropdownPanel = tabbedInterface.panels[7]
    if dropdownPanel then
        local dropdownLayout = uiContext:createLayoutModel(dropdownPanel, { verticalGap = 10 })
        dropdownLayout:header("AscensionExample_Header_9", "Obsidian Dropdown Menus", {
            wordWrap = true,
            xOffset = 10,
            rightOffset = -10,
        })
        dropdownLayout:paragraph("AscensionExample_Paragraph_6", {
            text = "Interactive dropdown menus featuring scrollable option lists with 09Slider integration, procedural arrow icons, and automatic outside-click dismissal.",
            xOffset = 10,
            rightOffset = -10,
            fontSize = 14,
        })
        dropdownLayout:row({
            name = "MockUIDropdownColumns",
            gap = 10,
            xOffset = 10,
            rightOffset = -10,
            threshold = 420,
            columns = {
                {
                    populate = function(col)
                        col:label("AscensionExample_Label_26", "Standard Dropdown (Compact List):", { wordWrap = true, elasticWidth = true })
                        local selectionResultLabel
                        col:dropdown("MockUISimpleDropdown", {
                            tooltip = "",
                            width = 200,
                            height = 26,
                            options = { "Combat", "Stealth", "Exploration", "Social", "Crafting" },
                            defaultValue = "Combat",
                            onValueChanged = function(dropdown, val)
                                if selectionResultLabel then
                                    selectionResultLabel:SetText("Selected: " .. tostring(val))
                                end
                            end,
                        })
                        selectionResultLabel = col:label("AscensionExample_Label_27", "Selected: Combat", { wordWrap = true, elasticWidth = true })
                    end,
                },
                {
                    populate = function(col)
                        col:label("AscensionExample_Label_28", "Scrollable Dropdown (Many Items):", { wordWrap = true, elasticWidth = true })
                        local longOptions = {}
                        for i = 1, 20 do
                            table.insert(longOptions, {
                                label = string.format("Profile Node #%02d", i),
                                value = i,
                                tooltip = "",
                            })
                        end
                        col:dropdown("MockUIScrollableDropdown", {
                            width = 220,
                            height = 26,
                            options = longOptions,
                            defaultValue = 1,
                            maxVisibleItems = 6,
                            tooltip = {
                                title = "Profile Selector",
                                desc = "Scroll with mouse wheel to browse all 20 profile entries dynamically.",
                            },
                        })
                    end,
                },
            },
        })
    end

    -------------------------------------------------------------------------------
    -- 8. SCROLLABLE PANEL
    -------------------------------------------------------------------------------
    local scrollablePanel = tabbedInterface.panels[8]
    if scrollablePanel then
        local scrollOuterLayout = uiContext:createLayoutModel(scrollablePanel, { verticalGap = 10 })
        scrollOuterLayout:header("AscensionExample_Header_10", "UX Scrollable Viewports", {
            wordWrap = true,
            xOffset = 10,
            rightOffset = -10,
        })

        local scrollPara = scrollOuterLayout:paragraph("AscensionExample_Paragraph_7", {
            text = "Any container can be converted into a scrollable viewport via LayoutModel ({ scrollable = true }). It embeds UX:makeScrollable and automatically recalculates canvas height and scroll range as elements stack or resize.",
            xOffset = 10,
            rightOffset = -10,
            fontSize = 14,
        })

        local scrollContainer = uiContext:createFrame({
            name = "AscensionFactoryMockScrollContainer",
            parent = scrollablePanel,
            width = 750,
            height = 360,
            point = "TOPLEFT",
            xOffset = 10,
            yOffset = -15,
            borderColor = styles.colors.border,
            backgroundColor = styles.colors.surfaceDark,
        })
        scrollContainer:ClearAllPoints()
        scrollContainer:SetPoint("TOPLEFT", scrollPara, "BOTTOMLEFT", 0, -15)
        scrollContainer:SetPoint("BOTTOMRIGHT", scrollablePanel, "BOTTOMRIGHT", -15, 12)

        local scrollInnerLayout = uiContext:createLayoutModel(scrollContainer, {
            scrollable = true,
            verticalGap = 8,
            scrollStep = 32,
            bottomPadding = 16,
        })

        local milestoneUpdaters = {}

        local function addMilestoneCard(idSuffix, titleText, descText, accentColor)
            scrollInnerLayout:beginSection()
            local titleLbl = scrollInnerLayout:label("AscensionFactoryMockScrollTitle_" .. idSuffix, titleText, {
                wordWrap = true,
                elasticWidth = true,
                fontSize = 15,
            })
            if titleLbl and accentColor then
                titleLbl:SetTextColor(unpack(accentColor))
            end
            local descPara = scrollInnerLayout:paragraph("AscensionFactoryMockScrollDesc_" .. idSuffix, {
                text = descText,
                fontSize = 12,
            })
            scrollInnerLayout:endSection()

            local cardSection = scrollInnerLayout.lastAddedElement
            if cardSection then
                local function syncCardLayout(sec)
                    local secW = (sec and sec.GetWidth and sec:GetWidth()) or 0
                    if secW <= 0 then
                        secW = scrollInnerLayout:getAvailableWidth(16, sec)
                    end
                    local availW = math.max(100, secW - 16)

                    if titleLbl then
                        titleLbl:SetWidth(availW)
                        if titleLbl.updateHeight then titleLbl:updateHeight() end
                    end
                    if descPara then
                        descPara:SetWidth(availW)
                        if descPara.updateHeight then descPara:updateHeight() end
                    end

                    local titleH = (titleLbl and ((titleLbl.GetStringHeight and titleLbl:GetStringHeight()) or titleLbl:GetHeight())) or 0
                    local descH = (descPara and ((descPara.GetStringHeight and descPara:GetStringHeight()) or descPara:GetHeight())) or 0
                    local totalH = math.max(20, math.ceil(10 + titleH + 8 + descH + 10))
                    sec:SetHeight(totalH)
                    scrollInnerLayout:onChildResized(sec, totalH)
                end

                scrollInnerLayout:registerResponsiveElement(cardSection, syncCardLayout)
                table.insert(milestoneUpdaters, function()
                    syncCardLayout(cardSection)
                end)
                syncCardLayout(cardSection)
            end
        end

        scrollablePanel:HookScript("OnShow", function()
            if C_Timer and C_Timer.After then
                C_Timer.After(0, function()
                    for _, updateFn in ipairs(milestoneUpdaters) do
                        updateFn()
                    end
                    scrollInnerLayout:updateScrollRangeIfAvailable()
                end)
            end
        end)

        -- 1. Top Milestone
        addMilestoneCard(
            "Top",
            "[ TOP OF CANVAS ] Initial Scroll Position",
            "Canvas height is calculated dynamically by LayoutModel ({ scrollable = true }). Use Mouse Wheel (or Shift+Wheel for 3x) to scroll down.",
            styles.colors.neonGreen
        )

        scrollInnerLayout:addSpace(140)

        -- 2. Quarter Milestone
        addMilestoneCard(
            "Quarter",
            "[ 25% MILESTONE ] Quarter Scroll Depth",
            "Section cards and spacing are stacked automatically with beginSection() and addSpace() — no manual yOffset or SetHeight needed.",
            styles.colors.steelHighlight
        )

        scrollInnerLayout:addSpace(140)

        -- 3. Midpoint Milestone
        addMilestoneCard(
            "Midpoint",
            "[ MIDPOINT ] Center of Scrollable Canvas",
            "LayoutModel tracks accumulated content height and updates UX:makeScrollable whenever elements are added or resized.",
            styles.colors.primary
        )

        scrollInnerLayout:addSpace(140)

        -- 4. Three-Quarter Milestone
        addMilestoneCard(
            "ThreeQuarter",
            "[ 75% MILESTONE ] Three-Quarter Depth",
            "Approaching the end of the dynamically measured scrollable container.",
            styles.colors.steelHighlight
        )

        scrollInnerLayout:addSpace(140)

        -- 5. Bottom Milestone
        addMilestoneCard(
            "Bottom",
            "[ BOTTOM OF CANVAS ] End of Viewport",
            "Maximum scroll offset reached. Capsule thumb rests cleanly at the bottom edge of the track.",
            styles.colors.primaryHover
        )

        scrollInnerLayout:updateScrollRangeIfAvailable()
    end

    -------------------------------------------------------------------------------
    -- 9. TOOLTIPS & CONTEXT MENUS PANEL
    -------------------------------------------------------------------------------
    local tooltipsPanel = tabbedInterface.panels[9]
    if tooltipsPanel then
        local tooltipsLayout = uiContext:createLayoutModel(tooltipsPanel, { verticalGap = 10 })
        tooltipsLayout:header("AscensionExample_Header_11", "Obsidian Tooltips & Context Menus", {
            wordWrap = true,
            xOffset = 10,
            rightOffset = -10,
        })
        tooltipsLayout:paragraph("AscensionExample_Paragraph_8", {
            text = "11Tooltip provides rich cyberpunk tooltips with glowing headers and body text. 13ContextMenu provides right-click menus at cursor coordinates with outside-click dismissal.",
            xOffset = 10,
            rightOffset = -10,
            fontSize = 14,
        })
        tooltipsLayout:row({
            name = "MockUITooltipColumns",
            gap = 10,
            xOffset = 10,
            rightOffset = -10,
            threshold = 420,
            columns = {
                {
                    populate = function(col)
                        col:label("AscensionExample_Label_29", "Cyberpunk Tooltips (Hover to test):", { wordWrap = true, elasticWidth = true })
                        col:button("AscensionFactoryMockRichTooltipBtn", {
                            width = 240,
                            height = 32,
                            text = "Hover for Rich Tooltip",
                            tooltip = {
                                title = "Neural Calibration",
                                desc = "Synchronizes player telemetry with Ascension Factory modules across game sessions.",
                            },
                        })
                        col:button("AscensionFactoryMockSimpleTooltipBtn", {
                            width = 240,
                            height = 32,
                            text = "Hover for String Tooltip",
                            tooltip = "Compact single-string Obsidian tooltip format.",
                        })
                    end,
                },
                {
                    populate = function(col)
                        col:label("AscensionExample_Label_30", "Context Menu (Interactive Demo):", { wordWrap = true, elasticWidth = true })

                        local contextDemoCard = uiContext:createFrame({
                            name = "AscensionFactoryMockContextDemoCard",
                            parent = col.currentParent,
                            width = 340,
                            height = 135,
                            borderColor = styles.colors.primary,
                            backgroundColor = styles.colors.surfaceDark,
                        })
                        contextDemoCard.uiContext = uiContext
                        contextDemoCard.fluidWidth = true
                        contextDemoCard.fluidRightOffset = 10
                        contextDemoCard:EnableMouse(true)
                        col:add(contextDemoCard)

                        local statusDot = contextDemoCard:CreateTexture(nil, "OVERLAY")
                        statusDot:SetSize(8, 8)
                        statusDot:SetPoint("TOPLEFT", contextDemoCard, "TOPLEFT", 14, -14)
                        statusDot:SetColorTexture(unpack(styles.colors.neonGreen))

                        local cardTitle = contextDemoCard:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
                        cardTitle:SetPoint("LEFT", statusDot, "RIGHT", 8, 0)
                        cardTitle:SetText("Tactical Node #04 [ONLINE]")
                        cardTitle:SetTextColor(unpack(styles.colors.white))

                        local cardDesc = contextDemoCard:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                        cardDesc:SetPoint("TOPLEFT", contextDemoCard, "TOPLEFT", 14, -36)
                        cardDesc:SetPoint("RIGHT", contextDemoCard, "RIGHT", -14, 0)
                        cardDesc:SetJustifyH("LEFT")
                        cardDesc:SetText("Right-click anywhere on this card or click the button below to trigger the context menu.")
                        cardDesc:SetTextColor(unpack(styles.colors.white))

                        local feedbackLabel = col:label("AscensionExample_Label_31", "Last Action: (None yet - open menu and click an option)", {
                            wordWrap = true,
                            elasticWidth = true,
                            fontSize = 13,
                        })

                        local demoConfig = { locked = false, point = "CENTER", x = 0, y = 0 }
                        local function openDemoMenu()
                            AscensionFactory.UX:showContextMenu(contextDemoCard, {
                                {
                                    text = "Calibrate Frequency",
                                    tooltip = "",
                                    onClick = function()
                                        feedbackLabel:SetText("Last Action: [ Calibrate Frequency executed ]")
                                        feedbackLabel:SetTextColor(unpack(styles.colors.primaryHover))
                                    end,
                                },
                                {
                                    text = "Purge Node Cache",
                                    tooltip = "",
                                    onClick = function()
                                        feedbackLabel:SetText("Last Action: [ Node Cache Purged ]")
                                        feedbackLabel:SetTextColor(unpack(styles.colors.primaryHover))
                                    end,
                                },
                                { text = "---" },
                                {
                                    text = "Run Self-Diagnostics",
                                    tooltip = "",
                                    onClick = function()
                                        feedbackLabel:SetText("Last Action: [ Diagnostics 100% OK ]")
                                        feedbackLabel:SetTextColor(unpack(styles.colors.neonGreen))
                                    end,
                                },
                                {
                                    text = "Toggle Stealth Shield",
                                    tooltip = "",
                                    onClick = function()
                                        feedbackLabel:SetText("Last Action: [ Stealth Shield Toggled ]")
                                        feedbackLabel:SetTextColor(unpack(styles.colors.neonGreen))
                                    end,
                                },
                            }, demoConfig)
                        end

                        uiContext:createButton({
                            name = "AscensionFactoryMockOpenContextMenuBtn",
                            parent = contextDemoCard,
                            width = 175,
                            height = 26,
                            text = "Open Context Menu ▾",
                            point = "BOTTOMLEFT",
                            relativeTo = contextDemoCard,
                            relativePoint = "BOTTOMLEFT",
                            xOffset = 14,
                            yOffset = 12,
                            onClick = function()
                                openDemoMenu()
                            end,
                            tooltip = "",
                        })

                        contextDemoCard:SetScript("OnMouseUp", function(self, button)
                            if button == "RightButton" then
                                openDemoMenu()
                            end
                        end)
                    end,
                },
            },
        })
    end

    -------------------------------------------------------------------------------
    -- 10. TOAST NOTIFICATIONS PANEL
    -------------------------------------------------------------------------------
    local toastsPanel = tabbedInterface.panels[10]
    if toastsPanel then
        local toastsLayout = uiContext:createLayoutModel(toastsPanel, { verticalGap = 10 })
        toastsLayout:header("AscensionExample_Header_12", "Toast Notifications & Queue", {
            wordWrap = true,
            xOffset = 10,
            rightOffset = -10,
        })
        toastsLayout:paragraph("AscensionExample_Paragraph_9", {
            text = "14Toast provides an Obsidian Cyberpunk HUD notification system with auto-dismiss timers, smooth fade animations, hover-to-pause, and FIFO queueing. Test each variant below to see when and why to use it:",
            xOffset = 10,
            rightOffset = -10,
            fontSize = 14,
        })
        toastsLayout:row({
            name = "MockUIToastColumns",
            gap = 10,
            xOffset = 10,
            rightOffset = -10,
            threshold = 420,
            columns = {
                {
                    populate = function(col)
                        col:label("AscensionExample_Label_32", "Standard Triggers (Passive):", { wordWrap = true, elasticWidth = true })
                        col:paragraph("AscensionExample_ToastColDesc_Standard", {
                            text = "Read-only notifications. Hovering pauses the timer and X closes them, but clicking the toast body does nothing.",
                            rightOffset = -10,
                            fontSize = 12,
                        })
                        col:button("AscensionFactoryMockTriggerBaseToastBtn", {
                            width = 240,
                            height = 32,
                            text = "Trigger Base Toast (Default)",
                            tooltip = "Default toast (no type). Best for neutral system notices or background updates.",
                            onClick = function()
                                uiContext:showToast({
                                    title = "System Notice",
                                    message = "This is a clean, minimalist toast notification with multiline text wrapping and a close button.",
                                    duration = 4,
                                })
                            end,
                        })
                        col:paragraph("AscensionExample_ToastDesc_Base", {
                            text = "|cffB0B8C4Base / Default:|r Use for neutral system messages, general announcements, or passive status updates with no urgency.",
                            rightOffset = -10,
                            fontSize = 12,
                        })

                        col:button("AscensionFactoryMockTriggerVectorToastBtn", {
                            width = 240,
                            height = 32,
                            text = "Trigger Success Toast (Vector)",
                            tooltip = "type = 'success'. Shows a green checkmark for completed actions.",
                            onClick = function()
                                uiContext:showToast({
                                    title = "Transfer Complete",
                                    message = "All currencies and inventory slots synchronized successfully with account storage.",
                                    type = "success",
                                    duration = 4,
                                })
                            end,
                        })
                        col:paragraph("AscensionExample_ToastDesc_Success", {
                            text = "|cff00FF88Success:|r Use to confirm completed actions—saved profiles, synced data, exports, or successful operations.",
                            rightOffset = -10,
                            fontSize = 12,
                        })

                        col:button("AscensionFactoryMockTriggerProgressToastBtn", {
                            width = 240,
                            height = 32,
                            text = "Trigger Warning Toast (Progress)",
                            tooltip = "type = 'warning' + showProgress = true. Highlights timed cautions or expiring states.",
                            onClick = function()
                                uiContext:showToast({
                                    title = "Buff Expiring",
                                    message = "Enhancement effect will expire in 5 seconds. Hover over this toast to pause countdown!",
                                    type = "warning",
                                    showProgress = true,
                                    duration = 5,
                                })
                            end,
                        })
                        col:paragraph("AscensionExample_ToastDesc_Warning", {
                            text = "|cffFFCC00Warning (+ Progress Bar):|r Use for non-critical cautions, soft limits, or expiring buffs/timers where a visual countdown helps.",
                            rightOffset = -10,
                            fontSize = 12,
                        })
                    end,
                },
                {
                    populate = function(col)
                        col:label("AscensionExample_Label_33", "Interactive & Semantic Triggers:", { wordWrap = true, elasticWidth = true })
                        col:paragraph("AscensionExample_ToastColDesc_Interactive", {
                            text = "Actionable or custom-themed toasts. Passing |cffFFFFFFonClick|r makes the entire toast clickable to trigger a response directly.",
                            rightOffset = -10,
                            fontSize = 12,
                        })
                        col:button("AscensionFactoryMockTriggerInteractiveToastBtn", {
                            width = 240,
                            height = 32,
                            text = "Trigger Info Toast (Interactive)",
                            tooltip = "type = 'info' + onClick. Ideal for clickable invites, prompts, or actionable notices.",
                            onClick = function()
                                uiContext:showToast({
                                    title = "Guild Invitation",
                                    message = "Click anywhere on this toast to accept the incoming invitation directly.",
                                    type = "info",
                                    showProgress = true,
                                    duration = 6,
                                    onClick = function(t)
                                        print("|cffFF6000[AscensionFactory]|r Interactive Toast clicked! Invitation accepted.")
                                        t:Dismiss()
                                    end,
                                })
                            end,
                        })
                        col:paragraph("AscensionExample_ToastDesc_Info", {
                            text = "|cff00D4FFInfo (+ Interactive onClick):|r Use for helpful context, incoming invites, or actionable prompts the user can click to respond.",
                            rightOffset = -10,
                            fontSize = 12,
                        })

                        col:button("AscensionFactoryMockTriggerThemedToastBtn", {
                            width = 240,
                            height = 32,
                            text = "Trigger Error Toast (Themed)",
                            tooltip = "type = 'error' + borderColor. Alerts the user to failures, timeouts, or blocked actions.",
                            onClick = function()
                                uiContext:showToast({
                                    title = "Critical Alert",
                                    message = "Network packet lost or remote handshake timed out. Check connection settings.",
                                    type = "error",
                                    borderColor = styles.colors.neonRed,
                                    showProgress = true,
                                    duration = 5,
                                })
                            end,
                        })
                        col:paragraph("AscensionExample_ToastDesc_Error", {
                            text = "|cffFF3355Error:|r Use for critical failures, connection drops, invalid inputs, or blocked actions that need immediate attention.",
                            rightOffset = -10,
                            fontSize = 12,
                        })

                        col:paragraph("AscensionExample_Paragraph_10", {
                            text = "|cffFF8800Queue Tip:|r Rapidly clicking triggers adds toasts to the FIFO queue (max 4 visible). Hovering over any toast pauses its countdown.",
                            rightOffset = -10,
                            fontSize = 12,
                        })
                    end,
                },
            },
        })

        toastsLayout:addSpace(6)
        toastsLayout:header("AscensionExample_ToastGuide_Header", "Quick Guide: Choosing the Right Toast Type", {
            wordWrap = true,
            xOffset = 10,
            rightOffset = -10,
            fontSize = 16,
        })
        toastsLayout:paragraph("AscensionExample_ToastGuide_Body", {
            text = "|cffFFFFFFStandard vs. Interactive:|r\n• |cffB0B8C4Standard (Passive):|r Display-only alerts—hover pauses, X closes, clicking the body has no action.\n• |cff00D4FFInteractive (onClick):|r Enables left-click on the toast body to run a callback (e.g. accept invite, open panel).\n\n|cffFFFFFFChoosing the Right Type:|r\n• |cffB0B8C4Default (no type):|r Neutral info or background events (e.g. 'Settings loaded').\n• |cff00D4FFinfo:|r Helpful notices, invites, or clickable actions with |cffFFFFFFonClick|r.\n• |cff00FF88success:|r Positive confirmation after saving, syncing, or completing a task.\n• |cffFFCC00warning:|r Heads-up before something expires or hits a limit (great with |cffFFFFFFshowProgress = true|r).\n• |cffFF3355error:|r Failed operations, timeouts, or errors that block progress.",
            xOffset = 10,
            rightOffset = -10,
            fontSize = 12,
        })
    end

    -------------------------------------------------------------------------------
    -- 11. COLOR PICKER PANEL
    -------------------------------------------------------------------------------
    local colorPickerPanel = tabbedInterface.panels[11]
    if colorPickerPanel then
        local colorLayout = uiContext:createLayoutModel(colorPickerPanel, { verticalGap = 10 })
        colorLayout:header("AscensionExample_Header_13", "Obsidian Color Picker & Palettes", {
            wordWrap = true,
            xOffset = 10,
            rightOffset = -10,
        })
        colorLayout:paragraph("AscensionExample_Paragraph_11", {
            text = "15ColorPicker provides an interactive Obsidian Cyberpunk modal color dialog with RGBA gradient sliders, interactive Hex input (#RRGGBB), checkerboard transparency, and session history.",
            xOffset = 10,
            rightOffset = -10,
            fontSize = 14,
        })

        local demoTargetBox, demoTargetText
        colorLayout:row({
            name = "MockUIColorPickerColumns",
            gap = 10,
            xOffset = 10,
            rightOffset = -10,
            threshold = 420,
            columns = {
                {
                    populate = function(col)
                        col:label("AscensionExample_Label_34", "Trigger Swatches (Click to edit):", { wordWrap = true, elasticWidth = true })
                        col:add(uiContext:createColorPicker({
                            tooltip = "",
                            name = "AscensionExample_ColorPicker_1",
                            parent = col.currentParent,
                            text = "Accent Neon Orange",
                            color = { 1.00, 0.38, 0.00, 1.00 },
                            onChange = function(color, r, g, b, a)
                                if demoTargetBox and demoTargetBox.border then
                                    demoTargetBox.border:SetColorTexture(r, g, b, 1)
                                end
                            end,
                        }))
                        col:add(uiContext:createColorPicker({
                            tooltip = "",
                            name = "AscensionExample_ColorPicker_2",
                            parent = col.currentParent,
                            text = "Translucent Backdrop (Alpha)",
                            color = { 0.00, 0.75, 1.00, 0.60 },
                            onChange = function(color, r, g, b, a)
                                if demoTargetBox and demoTargetBox.background then
                                    demoTargetBox.background:SetColorTexture(r, g, b, a)
                                end
                            end,
                        }))
                        col:add(uiContext:createColorPicker({
                            tooltip = "",
                            name = "AscensionExample_ColorPicker_3",
                            parent = col.currentParent,
                            text = "Status Neon Green",
                            color = { 0.00, 1.00, 0.55, 1.00 },
                            onChange = function(color, r, g, b, a)
                                if demoTargetText then
                                    demoTargetText:SetTextColor(r, g, b, a)
                                end
                            end,
                        }))
                    end,
                },
                {
                    populate = function(col)
                        demoTargetBox = uiContext:createFrame({
                            name = "AscensionFactoryMockDemoTargetBox",
                            parent = col.currentParent,
                            width = 240,
                            height = 140,
                            borderColor = styles.colors.primary,
                            backgroundColor = { 1, 0.38, 0, 0.8 },
                        })
                        demoTargetBox.fluidWidth = true
                        demoTargetBox.fluidRightOffset = 10
                        col:add(demoTargetBox)

                        demoTargetText = demoTargetBox:CreateFontString(nil, "OVERLAY", styles.fonts.text or "GameFontHighlight")
                        demoTargetText:SetPoint("CENTER")
                        demoTargetText:SetText("Live Preview Surface\nAdjust color swatches to watch me change!")
                        demoTargetText:SetJustifyH("CENTER")

                        col:paragraph("AscensionExample_Paragraph_12", {
                            text = "Tip: The modal dialog includes Hex typing (#RRGGBB), gradient rails, transparency checkerboards, and automatic recent colors history.",
                            rightOffset = -10,
                            fontSize = 12,
                        })
                    end,
                },
            },
        })
    end

    -- Sidebar Palette
    createPaletteFrame(frame)
    frame:Show()
end

-- Register Blizzard Options redirection panel
if AscensionFactory.Integration and AscensionFactory.Integration.registerBlizzardPanel then
    local blizPanel = AscensionFactory.Integration:registerBlizzardPanel("AscensionFactory", "Ascension Factory", function()
        createMockUi()
    end)
    if blizPanel and AscensionFactory.Context then
        AscensionFactory.Context.styles = AscensionFactory.Context.styles or styles
        local origOnShow = blizPanel:GetScript("OnShow")
        blizPanel:SetScript("OnShow", function(self, ...)
            local prevCreateDialog = AscensionFactory.Context.createDialogButton
            local prevCreateBtn = AscensionFactory.Context.createButton
            AscensionFactory.Context.createDialogButton = function(ctx, opts)
                if type(opts) == "table" and opts.tooltip == nil then opts.tooltip = "" end
                return prevCreateDialog(ctx, opts)
            end
            AscensionFactory.Context.createButton = function(ctx, opts)
                if type(opts) == "table" and opts.tooltip == nil then opts.tooltip = "" end
                return prevCreateBtn(ctx, opts)
            end
            if origOnShow then origOnShow(self, ...) end
            AscensionFactory.Context.createDialogButton = prevCreateDialog
            AscensionFactory.Context.createButton = prevCreateBtn
        end)
    end
end

-------------------------------------------------------------------------------
-- SLASH COMMANDS
-------------------------------------------------------------------------------

SLASH_MOCKUI1 = "/afui"
SlashCmdList["MOCKUI"] = function()
    if AscensionFactoryMockFrame and AscensionFactoryMockFrame:IsShown() then
        AscensionFactoryMockFrame:Hide()
    else
        createMockUi()
    end
end

-- /palette: Opens the standalone color palette
SLASH_ASPALETTE1 = "/afp"
SlashCmdList["ASPALETTE"] = function()
    if AscensionFactoryPaletteFrame and AscensionFactoryPaletteFrame:GetParent() == UIParent then
        AscensionFactoryPaletteFrame:SetShown(not AscensionFactoryPaletteFrame:IsShown())
    else
        if AscensionFactoryPaletteFrame then AscensionFactoryPaletteFrame:Hide() end
        local p = createPaletteFrame(nil)
        p:Show()
    end
end

-------------------------------------------------------------------------------
-- 5. EXTENSION & EXPANSION NOTES
-- Objective: Guidelines for adapting the gallery testbed into production addon interfaces.
--
-- How to expand:
-- 1. Adding New Component Gallery Tabs:
--    Add a new tab name to `tabs = { ... }` in `createMockUi()` and bind its corresponding content panel
--    to demonstrate new widgets as they are developed.
-- 2. Live Theme Customizer:
--    Add interactive color pickers into `createPaletteFrame` allowing real-time modification
--    of `uiContext.styles.colors` with instant visual re-rendering.
-- 3. Slash Command Registration:
--    Use `SLASH_<NAME>1 = "/cmd"` and `SlashCmdList["<NAME>"]` pattern for opening/toggling addon panels.
-------------------------------------------------------------------------------
