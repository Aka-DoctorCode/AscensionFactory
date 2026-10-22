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
            AscensionFactory.UX:makeMovable(paletteFrame)
            AscensionFactory.UX:makeClosableWithEscape(paletteFrame)
        end
    end

    -- Header
    local _, headerY = uiContext:createHeader({
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
        width = 1000,
        height = 500,
        resizable = true,
        minWidth = 400,
        minHeight = 250,
    })
    local header, nextY = uiContext:createHeader({
        parent = frame,
        text = "Ascension Factory",
        xOffset = 10,
        yOffset = -10,
        fontSize = 34,
        spaceBelow = 4,
    })

    -- Attach Tabbed Interface (Sidebar)
    local tabbedInterface = uiContext:createTabbedInterface({
        parent = frame,
        startY = nextY,
        initialIndex = 1,
        tabs = { "Framing", "Text", "Buttons", "Inputs", "Sliders", "Steppers", "Dropdowns", "Scrollable", "Tooltips & Menus", "Toasts", "Color Picker" }
    })

    -- Intro Panel (Framing & Responsive Showcase)
    local introPanel = tabbedInterface.panels[1]
    local introContent = introPanel.scrollChild or introPanel

    local _, nextY = uiContext:createHeader({
        parent = introContent,
        text = "Welcome to Ascension Factory Responsive UI",
        xOffset = 10,
        yOffset = -10,
        elasticWidth = true,
        wordWrap = true
    })
    _, nextY = uiContext:createParagraph({
        parent = introContent,
        text = "AscensionFactory now features intelligent responsive layouts. When this window is shrunk (e.g. from 1000px down to 400px), the sidebar collapses to a compact 40px icon strip, columns auto-stack vertically at 100% width, and form widgets adapt fluidly without clipping.",
        xOffset = 10,
        yOffset = nextY - 10,
        fontSize = 14,
    })

    _, nextY = uiContext:createParagraph({
        parent = introContent,
        text = "Below is an interactive demonstration of responsive TwoColumn layout with fluid inputs, steppers, sliders, dropdowns, and flex rows. Try resizing the window using the corner grip!",
        xOffset = 10,
        yOffset = nextY - 8,
        fontSize = 13
    })

    local leftColumn, rightColumn = uiContext:createTwoColumns({
        parent = introContent,
        yOffset = nextY - 16,
        height = 200,
        stackThreshold = 500,
        backgroundColor = styles.colors.surfaceLight,
        name = "MockUITwoColumn"
    })

    -- Left Column: Fluid Input, Stepper & Flex Toggle
    uiContext:createLabel({
        parent = leftColumn,
        text = "Column A: Fluid Inputs & Flex Toggle",
        xOffset = 10,
        yOffset = 8,
        fontSize = 14
    })

    uiContext:createInputField({
        parent = leftColumn,
        name = "MockUIFluidInput",
        fluidWidth = true,
        height = 26,
        placeholder = "Fluid width text field...",
        xOffset = 10,
        yOffset = -22
    })

    uiContext:createStepper({
        parent = leftColumn,
        name = "MockUIFluidStepper",
        fluidWidth = true,
        height = 26,
        minValue = 0,
        maxValue = 100,
        step = 5,
        value = 40,
        xOffset = 10,
        yOffset = -58
    })

    uiContext:createToggle({
        parent = leftColumn,
        name = "MockUIFlexToggle",
        flexRow = true,
        text = "Adaptive Flex Row Switch",
        height = 22,
        xOffset = 10,
        yOffset = -98,
        getter = function() return true end
    })

    uiContext:createCheckbox({
        parent = leftColumn,
        name = "MockUIFlexCheckbox",
        flexRow = true,
        text = "Auto-Stack Columns (< 500px)",
        checked = true,
        xOffset = 10,
        yOffset = -130
    })

    -- Right Column: Fluid Slider, Dropdown & Adaptive Dialog Buttons
    uiContext:createLabel({
        parent = rightColumn,
        text = "Column B: Fluid Controls & Adaptive Buttons",
        xOffset = 10,
        yOffset = 8,
        fontSize = 14
    })

    uiContext:createSlider({
        parent = rightColumn,
        name = "MockUIFluidSlider",
        orientation = "HORIZONTAL",
        fluidWidth = true,
        height = 16,
        minValue = 0,
        maxValue = 100,
        step = 1,
        value = 75,
        showFill = true,
        xOffset = 10,
        yOffset = -26
    })

    uiContext:createDropdown({
        parent = rightColumn,
        name = "MockUIFluidDropdown",
        fluidWidth = true,
        height = 26,
        options = { "Obsidian Cyberpunk", "Neon Amber", "Matrix Phosphor", "Cobalt Void" },
        xOffset = 10,
        yOffset = -58
    })

    uiContext:createDialogButtonGroup({
        parent = rightColumn,
        name = "MockUIColumnDialogButtons",
        stackThreshold = 380,
        xOffset = 10,
        yOffset = -100,
        buttons = {
            { text = "Confirm", variant = "accept", width = 80 },
            { text = "Reset", variant = "cancel", width = 80 }
        }
    })

    uiContext:createParagraph({
        parent = rightColumn,
        text = "Buttons adapt from horizontal row to 100% stacked vertical when width narrows.",
        xOffset = 10,
        yOffset = -140,
        fontSize = 11
    })

    -- Header Panel
    local headerPanel = tabbedInterface.panels[2].scrollChild or tabbedInterface.panels[2]
        local _, nextY = uiContext:createHeader({
            parent = headerPanel,
            text = "Header Text: Used for section titles.",
            xOffset = 10,
            yOffset = -10
        })
        _, nextY = uiContext:createLabel({
            parent = headerPanel,
            text = "Label Text: Used for standard options.",
            xOffset = 10,
            yOffset = nextY - 10
        })
        _, nextY = uiContext:createParagraph({
            parent = headerPanel,
            text = "Paragraph Text: Used for long descriptions or explanations like this one. It handles wrapping and smaller font size.",
            xOffset = 10,
            yOffset = nextY - 10,
            fontSize = 16
        })

    -- Buttons Panel
    local buttonPanel = tabbedInterface.panels[3].scrollChild or tabbedInterface.panels[3]
        local _, buttonNextY = uiContext:createHeader({
            parent = buttonPanel,
            text = "Button Component",
            xOffset = 10,
            yOffset = -10
        })
        local buttonLeftColumn, buttonRightColumn = uiContext:createTwoColumns({
            parent = buttonPanel,
            yOffset = buttonNextY - 10,
            name = "MockUIButtonTwoColumn"
        })

        local exampleButton = uiContext:createButton({
            parent = buttonLeftColumn,
            name = "MockUIExampleBtn",
            text = "Enabled Button",
            width = 180,
            height = 40,
            xOffset = 30,
            yOffset = 0
        })

        local disabledButton = uiContext:createButton({
            parent = buttonLeftColumn,
            name = "MockUIDisabledBtn",
            text = "Disabled Button",
            width = 180,
            height = 30,
            xOffset = 30,
            yOffset = -50
        })
        disabledButton:Disable()

        local toggleLabel = uiContext:createLabel({
            parent = buttonLeftColumn,
            text = "Toggle Button",
            xOffset = 30,
            yOffset = -95
        })

        local exampleToggle = uiContext:createToggle({
            parent = buttonLeftColumn,
            name = "MockUIExampleToggle",
            width = 50,
            height = 24,
            xOffset = 30,
            yOffset = -120,
            getter = function() return false end,
            setter = function(state) end
        })

        local checkboxLabel = uiContext:createLabel({
            parent = buttonLeftColumn,
            text = "Checkbox Component",
            xOffset = 30,
            yOffset = -160
        })

        local exampleCheckbox = uiContext:createCheckbox({
            parent = buttonLeftColumn,
            name = "MockUIExampleCheckbox",
            text = "Enable Auto Target",
            checked = true,
            xOffset = 30,
            yOffset = -190,
        })

        local disabledCheckbox = uiContext:createCheckbox({
            parent = buttonLeftColumn,
            name = "MockUIDisabledCheckbox",
            text = "Locked Feature",
            checked = true,
            xOffset = 30,
            yOffset = -220,
        })
        disabledCheckbox:Disable()

        local dialogButtonLabel = uiContext:createLabel({
            parent = buttonLeftColumn,
            text = "Dialog Actions",
            xOffset = 30,
            yOffset = -260
        })

        local exampleAccept = uiContext:createDialogButton({
            parent = buttonLeftColumn,
            name = "MockUIAcceptButton",
            variant = "accept",
            xOffset = 30,
            yOffset = -285
        })

        local exampleCancel = uiContext:createDialogButton({
            parent = buttonLeftColumn,
            name = "MockUICancelButton",
            variant = "cancel",
            xOffset = 130,
            yOffset = -285
        })

        local exampleNeutral = uiContext:createDialogButton({
            parent = buttonLeftColumn,
            name = "MockUINeutralButton",
            variant = "neutral",
            text = "Apply",
            xOffset = 30,
            yOffset = -320
        })

        local closeLabel = uiContext:createLabel({
            parent = buttonRightColumn,
            text = "Close",
            xOffset = 30,
            yOffset = 30
        })

        local iconClose = uiContext:createIconButton({
            parent = buttonRightColumn,
            name = "MockUIIconClose",
            iconType = "close",
            size = 30,
            xOffset = 30,
            yOffset = 0
        })

        local plusLabel = uiContext:createLabel({
            parent = buttonRightColumn,
            text = "Plus",
            xOffset = 30,
            yOffset = -50
        })

        local iconPlus = uiContext:createIconButton({
            parent = buttonRightColumn,
            name = "MockUIIconPlus",
            iconType = "plus",
            size = 30,
            xOffset = 30,
            yOffset = -80
        })

        local maximizeLabel = uiContext:createLabel({
            parent = buttonRightColumn,
            text = "Maximize",
            xOffset = 30,
            yOffset = -130
        })

        local iconMaximize = uiContext:createIconButton({
            parent = buttonRightColumn,
            name = "MockUIIconMaximize",
            iconType = "maximize",
            size = 30,
            xOffset = 30,
            yOffset = -160
        })

        local minimizeLabel = uiContext:createLabel({
            parent = buttonRightColumn,
            text = "Minimize",
            xOffset = 130,
            yOffset = 30
        })

        local iconMinimize = uiContext:createIconButton({
            parent = buttonRightColumn,
            name = "MockUIIconMinimize",
            iconType = "minimize",
            size = 30,
            xOffset = 130,
            yOffset = 0
        })

        local minusLabel = uiContext:createLabel({
            parent = buttonRightColumn,
            text = "Minus",
            xOffset = 130,
            yOffset = -50
        })

        local iconMinus = uiContext:createIconButton({
            parent = buttonRightColumn,
            name = "MockUIIconMinus",
            iconType = "minus",
            size = 30,
            xOffset = 130,
            yOffset = -80
        })

        local arrowLabel = uiContext:createLabel({
            parent = buttonRightColumn,
            text = "Arrow",
            xOffset = 130,
            yOffset = -130
        })

        local iconArrowDown = uiContext:createIconButton({
            parent = buttonRightColumn,
            name = "MockUIIconArrowDown",
            iconType = "arrowdown",
            size = 30,
            xOffset = 130,
            yOffset = -160
        })

    -- Inputs Panel
    local inputPanel = tabbedInterface.panels[4].scrollChild or tabbedInterface.panels[4]
        local _, inputNextY = uiContext:createHeader({
            parent = inputPanel,
            text = "Input Field Component",
            xOffset = 10,
            yOffset = -10
        })

        local inputLeftColumn, inputRightColumn = uiContext:createTwoColumns({
            parent = inputPanel,
            yOffset = inputNextY - 10,
            name = "MockUIInputTwoColumn"
        })

        -- Left Column: Single-line and Special Inputs
        local singleLineTitle = uiContext:createLabel({
            parent = inputLeftColumn,
            text = "Single-Line Input (with placeholder)",
            xOffset = 20,
            yOffset = 10
        })

        local exampleInput = uiContext:createInputField({
            parent = inputLeftColumn,
            name = "MockUIStandardInput",
            width = 240,
            height = 26,
            placeholder = "Enter character name...",
            xOffset = 20,
            yOffset = -15
        })

        local clearInputTitle = uiContext:createLabel({
            parent = inputLeftColumn,
            text = "With Clear Button",
            xOffset = 20,
            yOffset = -55
        })

        local clearInput = uiContext:createInputField({
            parent = inputLeftColumn,
            name = "MockUIClearInput",
            width = 240,
            height = 26,
            text = "Pre-filled Search Query",
            showClear = true,
            xOffset = 20,
            yOffset = -80
        })

        local numericTitle = uiContext:createLabel({
            parent = inputLeftColumn,
            text = "Numeric Only Input (Max 4 digits)",
            xOffset = 20,
            yOffset = -120
        })

        local numericInput = uiContext:createInputField({
            parent = inputLeftColumn,
            name = "MockUINumericInput",
            width = 120,
            height = 26,
            numeric = true,
            maxLetters = 4,
            placeholder = "9999",
            xOffset = 20,
            yOffset = -145
        })

        -- Right Column: Multi-Line Text Area
        local multiLineTitle = uiContext:createLabel({
            parent = inputRightColumn,
            text = "Multi-Line Text Area",
            xOffset = 20,
            yOffset = 10
        })

        local exampleTextArea = uiContext:createInputField({
            parent = inputRightColumn,
            name = "MockUITextArea",
            multiLine = true,
            width = 250,
            height = 100,
            showScrollbar = true,
            placeholder = "Type notes or macro commands here...",
            xOffset = 20,
            yOffset = -15
        })

    -- Sliders Panel
    local sliderPanel = tabbedInterface.panels[5].scrollChild or tabbedInterface.panels[5]
        local _, sliderNextY = uiContext:createHeader({
            parent = sliderPanel,
            text = "Slider & Scrollbar Component",
            xOffset = 10,
            yOffset = -10
        })

        local sliderLeftColumn, sliderRightColumn = uiContext:createTwoColumns({
            parent = sliderPanel,
            yOffset = sliderNextY - 10,
            name = "MockUISliderTwoColumn"
        })

        -- Left Column: Horizontal Sliders
        local horizontalTitle = uiContext:createLabel({
            parent = sliderLeftColumn,
            text = "Horizontal Sliders",
            xOffset = 20,
            yOffset = 10
        })

        local slider1ValueLabel = uiContext:createLabel({
            parent = sliderLeftColumn,
            text = "Standard: 50%",
            xOffset = 20,
            yOffset = -20
        })

        local exampleHorizontalSlider = uiContext:createSlider({
            parent = sliderLeftColumn,
            name = "MockUIHorizontalSlider1",
            orientation = "HORIZONTAL",
            length = 260,
            height = 16,
            minValue = 0,
            maxValue = 100,
            step = 1,
            value = 50,
            xOffset = 20,
            yOffset = -45,
            onValueChanged = function(self, val, isUserInput)
                slider1ValueLabel:SetText(string.format("Standard: %d%%", math.floor(val)))
            end
        })

        local slider2ValueLabel = uiContext:createLabel({
            parent = sliderLeftColumn,
            text = "With Progress Fill: 75%",
            xOffset = 20,
            yOffset = -80
        })

        local exampleFilledSlider = uiContext:createSlider({
            parent = sliderLeftColumn,
            name = "MockUIHorizontalSlider2",
            orientation = "HORIZONTAL",
            length = 260,
            height = 16,
            minValue = 0,
            maxValue = 100,
            step = 5,
            value = 75,
            showFill = true,
            xOffset = 20,
            yOffset = -105,
            onValueChanged = function(self, val, isUserInput)
                slider2ValueLabel:SetText(string.format("With Progress Fill: %d%%", math.floor(val)))
            end
        })

        local slider3ValueLabel = uiContext:createLabel({
            parent = sliderLeftColumn,
            text = "Stepped (1-10): Value 4",
            xOffset = 20,
            yOffset = -140
        })

        local exampleSteppedSlider = uiContext:createSlider({
            parent = sliderLeftColumn,
            name = "MockUIHorizontalSlider3",
            orientation = "HORIZONTAL",
            length = 260,
            height = 16,
            minValue = 1,
            maxValue = 10,
            step = 1,
            value = 4,
            showFill = true,
            xOffset = 20,
            yOffset = -165,
            onValueChanged = function(self, val, isUserInput)
                slider3ValueLabel:SetText(string.format("Stepped (1-10): Value %d", math.floor(val)))
            end
        })

        -- Right Column: Vertical Sliders / Scrollbars
        local verticalTitle = uiContext:createLabel({
            parent = sliderRightColumn,
            text = "Vertical Scrollbars",
            xOffset = 30,
            yOffset = 10
        })

        local verticalScrollbarLabel = uiContext:createLabel({
            parent = sliderRightColumn,
            text = "Scrollbar",
            xOffset = 30,
            yOffset = -20
        })

        local exampleVerticalScrollbar = uiContext:createSlider({
            parent = sliderRightColumn,
            name = "MockUIVerticalScrollbar",
            orientation = "VERTICAL",
            length = 200,
            width = 14,
            minValue = 0,
            maxValue = 100,
            step = 5,
            value = 20,
            xOffset = 45,
            yOffset = -45
        })

        local verticalFillLabel = uiContext:createLabel({
            parent = sliderRightColumn,
            text = "Filled Meter",
            xOffset = 130,
            yOffset = -20
        })

        local exampleVerticalFilled = uiContext:createSlider({
            parent = sliderRightColumn,
            name = "MockUIVerticalFilled",
            orientation = "VERTICAL",
            length = 200,
            width = 14,
            minValue = 0,
            maxValue = 100,
            step = 1,
            value = 60,
            showFill = true,
            inverted = true,
            xOffset = 150,
            yOffset = -45
        })

    -- Steppers Panel
    local stepperPanel = tabbedInterface.panels[6].scrollChild or tabbedInterface.panels[6]
        local _, stepperNextY = uiContext:createHeader({
            parent = stepperPanel,
            text = "Stepper Component",
            xOffset = 10,
            yOffset = -10
        })

        local stepperLeftColumn, stepperRightColumn = uiContext:createTwoColumns({
            parent = stepperPanel,
            yOffset = stepperNextY - 10,
            name = "MockUIStepperTwoColumn"
        })

        -- Left Column: Standard Steppers
        local standardStepperTitle = uiContext:createLabel({
            parent = stepperLeftColumn,
            text = "Standard Stepper (0 - 100, Step 1)",
            xOffset = 20,
            yOffset = 10
        })

        local standardStepper = uiContext:createStepper({
            parent = stepperLeftColumn,
            name = "MockUIStandardStepper",
            width = 140,
            height = 26,
            minValue = 0,
            maxValue = 100,
            step = 1,
            value = 10,
            xOffset = 20,
            yOffset = -15
        })

        local clampedStepperTitle = uiContext:createLabel({
            parent = stepperLeftColumn,
            text = "Clamped Low Range (1 - 5)",
            xOffset = 20,
            yOffset = -55
        })

        local clampedStepper = uiContext:createStepper({
            parent = stepperLeftColumn,
            name = "MockUIClampedStepper",
            width = 120,
            height = 26,
            minValue = 1,
            maxValue = 5,
            step = 1,
            value = 1,
            xOffset = 20,
            yOffset = -80
        })

        -- Right Column: Decimal & Negative Steppers
        local decimalStepperTitle = uiContext:createLabel({
            parent = stepperRightColumn,
            text = "Decimal Stepper (0.0 - 10.0, Step 0.5)",
            xOffset = 20,
            yOffset = 10
        })

        local decimalStepper = uiContext:createStepper({
            parent = stepperRightColumn,
            name = "MockUIDecimalStepper",
            width = 140,
            height = 26,
            minValue = 0.0,
            maxValue = 10.0,
            step = 0.5,
            decimals = 1,
            value = 2.5,
            xOffset = 20,
            yOffset = -15
        })

        local negativeStepperTitle = uiContext:createLabel({
            parent = stepperRightColumn,
            text = "Range with Negatives (-50 to +50)",
            xOffset = 20,
            yOffset = -55
        })

        local negativeStepper = uiContext:createStepper({
            parent = stepperRightColumn,
            name = "MockUINegativeStepper",
            width = 140,
            height = 26,
            minValue = -50,
            maxValue = 50,
            step = 10,
            value = 0,
            allowNegative = true,
            xOffset = 20,
            yOffset = -80
        })

    -------------------------------------------------------------------------------
    -- 7. DROPDOWNS PANEL
    -------------------------------------------------------------------------------
    local dropdownPanel = tabbedInterface.panels[7].scrollChild or tabbedInterface.panels[7]
    if dropdownPanel then
        local _, nextDropdownY = uiContext:createHeader({
            parent = dropdownPanel,
            text = "Obsidian Dropdown Menus",
            xOffset = 10,
            yOffset = -10
        })

        _, nextDropdownY = uiContext:createParagraph({
            parent = dropdownPanel,
            text = "Interactive dropdown menus featuring scrollable option lists with 09Slider integration, procedural arrow icons, and automatic outside-click dismissal.",
            xOffset = 10,
            yOffset = nextDropdownY - 10,
            fontSize = 14
        })

        local dropdownLeftCol, dropdownRightCol = uiContext:createTwoColumns({
            parent = dropdownPanel,
            yOffset = nextDropdownY - 20,
            height = 300,
            name = "MockUIDropdownColumns"
        })

        -- Left Column: Simple list with selection callback
        uiContext:createLabel({
            parent = dropdownLeftCol,
            text = "Standard Dropdown (Compact List):",
            xOffset = 20,
            yOffset = 10
        })

        local selectionResultLabel = uiContext:createLabel({
            parent = dropdownLeftCol,
            text = "Selected: Combat",
            xOffset = 20,
            yOffset = -70
        })

        uiContext:createDropdown({
            parent = dropdownLeftCol,
            name = "MockUISimpleDropdown",
            width = 200,
            height = 26,
            options = { "Combat", "Stealth", "Exploration", "Social", "Crafting" },
            defaultValue = "Combat",
            xOffset = 20,
            yOffset = -15,
            onValueChanged = function(dropdown, val)
                selectionResultLabel:SetText("Selected: " .. tostring(val))
            end
        })

        -- Right Column: Long scrollable list (20 items)
        uiContext:createLabel({
            parent = dropdownRightCol,
            text = "Scrollable Dropdown (Many Items):",
            xOffset = 20,
            yOffset = 10
        })

        local longOptions = {}
        for i = 1, 20 do
            table.insert(longOptions, {
                label = string.format("Profile Node #%02d", i),
                value = i
            })
        end

        uiContext:createDropdown({
            parent = dropdownRightCol,
            name = "MockUIScrollableDropdown",
            width = 220,
            height = 26,
            options = longOptions,
            defaultValue = 1,
            maxVisibleItems = 6,
            xOffset = 20,
            yOffset = -15,
            tooltip = {
                title = "Profile Selector",
                desc = "Scroll with mouse wheel to browse all 20 profile entries dynamically."
            }
        })
    end

    -------------------------------------------------------------------------------
    -- 8. SCROLLABLE PANEL
    -------------------------------------------------------------------------------
    local scrollablePanel = tabbedInterface.panels[8]
    if scrollablePanel then
        local _, nextScrollY = uiContext:createHeader({
            parent = scrollablePanel,
            text = "UX Scrollable Viewports",
            xOffset = 10,
            yOffset = -10
        })

        _, nextScrollY = uiContext:createParagraph({
            parent = scrollablePanel,
            text = "Any container can be converted into a scrollable viewport via UX:makeScrollable. It embeds an internal ScrollFrame and automatically hooks the 09Slider vertical bar.",
            xOffset = 10,
            yOffset = nextScrollY - 10,
            fontSize = 14
        })

        local scrollContainer = uiContext:createFrame({
            parent = scrollablePanel,
            width = 750,
            height = 360,
            point = "TOPLEFT",
            xOffset = 10,
            yOffset = nextScrollY - 15,
            borderColor = styles.colors.border,
            backgroundColor = styles.colors.surfaceDark
        })
        scrollContainer:ClearAllPoints()
        scrollContainer:SetPoint("TOPLEFT", scrollablePanel, "TOPLEFT", 10, nextScrollY - 15)
        scrollContainer:SetPoint("BOTTOMRIGHT", scrollablePanel, "BOTTOMRIGHT", -15, 12)

        local scrollFrame, scrollContent, scrollbar = AscensionFactory.UX:makeScrollable(scrollContainer, {
            uiContext = uiContext,
            scrollBarWidth = 12,
            thumbShape = "capsule",
            step = 32,
            bottomPadding = 20
        })

        -- Canvas height is twice the main frame height (500 * 2 = 1000px)
        local totalCanvasHeight = (frame:GetHeight() or 500) * 2
        scrollContent:SetHeight(totalCanvasHeight)

        -- Helper to create clean measurement milestone markers
        local function createMarker(yPos, labelText, descText, accentColor)
            local markerFrame = uiContext:createFrame({
                parent = scrollContent,
                width = 700,
                height = 56,
                point = "TOPLEFT",
                xOffset = 15,
                yOffset = yPos,
                borderColor = accentColor or styles.colors.steelHighlight,
                backgroundColor = styles.colors.panelBackground
            })

            local titleFs = markerFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
            titleFs:SetPoint("TOPLEFT", markerFrame, "TOPLEFT", 12, -10)
            titleFs:SetText(labelText)
            if accentColor then
                titleFs:SetTextColor(unpack(accentColor))
            else
                titleFs:SetTextColor(unpack(styles.colors.white))
            end

            local descFs = markerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            descFs:SetPoint("TOPLEFT", titleFs, "BOTTOMLEFT", 0, -4)
            descFs:SetText(descText)
            descFs:SetTextColor(unpack(styles.colors.white))

            return markerFrame
        end

        -- 1. Top Milestone (0px)
        local topCard = createMarker(
            -15,
            "[ TOP OF CANVAS - 0px ] Initial Scroll Position",
            "Canvas total height: 1000px (2x main frame height). Use Mouse Wheel (or Shift+Wheel for 3x) to scroll down.",
            styles.colors.neonGreen
        )

        local jumpBottomBtn = uiContext:createButton({
            parent = topCard,
            width = 160,
            height = 26,
            text = "Scroll to Bottom >>",
            point = "RIGHT",
            relativeTo = topCard,
            relativePoint = "RIGHT",
            xOffset = -12,
            yOffset = 0,
            onClick = function()
                if scrollbar and scrollbar.setValue then
                    local _, maxVal = scrollbar:getMinMaxValues()
                    scrollbar:setValue(maxVal, false, true)
                end
            end
        })

        -- 2. Intermediate Rulers
        createMarker(-250, "[ 250px MILESTONE ] 25% Scroll Depth", "Capsule thumb tracks progress through empty canvas space.", styles.colors.steelHighlight)

        -- 3. Midpoint Milestone (500px - 1x Main Frame Height)
        createMarker(-500, "[ MIDPOINT - 500px ] Main Frame Height (1x Extent)", "You have scrolled an equivalent of the entire main frame height.", styles.colors.primary)

        -- 4. Intermediate Ruler
        createMarker(-750, "[ 750px MILESTONE ] 75% Scroll Depth", "Approaching the end of the extended canvas container.", styles.colors.steelHighlight)

        -- 5. Bottom Milestone (1000px - 2x Main Frame Height)
        local bottomCard = createMarker(
            -920,
            "[ BOTTOM OF CANVAS - 1000px ] End of Viewport (2x Main Frame Height)",
            "Maximum scroll offset reached. Capsule thumb rests cleanly at the bottom edge of the track.",
            styles.colors.primaryHover
        )

        local jumpTopBtn = uiContext:createButton({
            parent = bottomCard,
            width = 160,
            height = 26,
            text = "<< Scroll to Top",
            point = "RIGHT",
            relativeTo = bottomCard,
            relativePoint = "RIGHT",
            xOffset = -12,
            yOffset = 0,
            onClick = function()
                if scrollbar and scrollbar.setValue then
                    scrollbar:setValue(0, false, true)
                end
            end
        })

        if scrollContainer.updateScrollRange then
            scrollContainer:updateScrollRange()
        end
    end

    -------------------------------------------------------------------------------
    -- 9. TOOLTIPS & CONTEXT MENUS PANEL
    -------------------------------------------------------------------------------
    local tooltipsPanel = tabbedInterface.panels[9].scrollChild or tabbedInterface.panels[9]
    if tooltipsPanel then
        local _, nextTooltipY = uiContext:createHeader({
            parent = tooltipsPanel,
            text = "Obsidian Tooltips & Context Menus",
            xOffset = 10,
            yOffset = -10
        })

        _, nextTooltipY = uiContext:createParagraph({
            parent = tooltipsPanel,
            text = "11Tooltip provides rich cyberpunk tooltips with glowing headers and body text. 13ContextMenu provides right-click menus at cursor coordinates with outside-click dismissal.",
            xOffset = 10,
            yOffset = nextTooltipY - 10,
            fontSize = 14
        })

        local tooltipsLeftCol, tooltipsRightCol = uiContext:createTwoColumns({
            parent = tooltipsPanel,
            yOffset = nextTooltipY - 15,
            height = 320,
            name = "MockUITooltipColumns"
        })

        -- Left Column: Tooltip Triggers
        uiContext:createLabel({
            parent = tooltipsLeftCol,
            text = "Cyberpunk Tooltips (Hover to test):",
            xOffset = 15,
            yOffset = -10
        })

        uiContext:createButton({
            parent = tooltipsLeftCol,
            width = 240,
            height = 32,
            text = "Hover for Rich Tooltip",
            point = "TOPLEFT",
            xOffset = 15,
            yOffset = -38,
            tooltip = {
                title = "Neural Calibration",
                desc = "Synchronizes player telemetry with Ascension Factory modules across game sessions."
            }
        })

        uiContext:createButton({
            parent = tooltipsLeftCol,
            width = 240,
            height = 32,
            text = "Hover for String Tooltip",
            point = "TOPLEFT",
            xOffset = 15,
            yOffset = -80,
            tooltip = "Compact single-string Obsidian tooltip format."
        })

        -- Right Column: Context Menu Demo
        uiContext:createLabel({
            parent = tooltipsRightCol,
            text = "Context Menu (Interactive Demo):",
            xOffset = 15,
            yOffset = -10
        })

        -- Interactive Tactical Node Card
        local contextDemoCard = uiContext:createFrame({
            parent = tooltipsRightCol,
            width = 340,
            height = 135,
            point = "TOPLEFT",
            xOffset = 15,
            yOffset = -38,
            borderColor = styles.colors.primary,
            backgroundColor = styles.colors.surfaceDark
        })
        contextDemoCard:EnableMouse(true)

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

        -- Live Action Feedback
        local feedbackLabel = uiContext:createLabel({
            parent = tooltipsRightCol,
            text = "Last Action: (None yet - open menu and click an option)",
            xOffset = 15,
            yOffset = -188,
            fontSize = 13
        })

        local demoConfig = { locked = false, point = "CENTER", x = 0, y = 0 }

        local function openDemoMenu()
            AscensionFactory.UX:showContextMenu(contextDemoCard, {
                {
                    text = "Calibrate Frequency",
                    onClick = function()
                        feedbackLabel:SetText("Last Action: [ Calibrate Frequency executed ]")
                        feedbackLabel:SetTextColor(unpack(styles.colors.primaryHover))
                    end
                },
                {
                    text = "Purge Node Cache",
                    onClick = function()
                        feedbackLabel:SetText("Last Action: [ Node Cache Purged ]")
                        feedbackLabel:SetTextColor(unpack(styles.colors.primaryHover))
                    end
                },
                { text = "---" },
                {
                    text = "Run Self-Diagnostics",
                    onClick = function()
                        feedbackLabel:SetText("Last Action: [ Diagnostics 100% OK ]")
                        feedbackLabel:SetTextColor(unpack(styles.colors.neonGreen))
                    end
                },
                {
                    text = "Toggle Stealth Shield",
                    onClick = function()
                        feedbackLabel:SetText("Last Action: [ Stealth Shield Toggled ]")
                        feedbackLabel:SetTextColor(unpack(styles.colors.neonGreen))
                    end
                }
            }, demoConfig)
        end

        local menuButton = uiContext:createButton({
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
            end
        })

        contextDemoCard:SetScript("OnMouseUp", function(self, button)
            if button == "RightButton" then
                openDemoMenu()
            end
        end)
    end

    -------------------------------------------------------------------------------
    -- 10. TOAST NOTIFICATIONS PANEL
    -------------------------------------------------------------------------------
    local toastsPanel = tabbedInterface.panels[10].scrollChild or tabbedInterface.panels[10]
    if toastsPanel then
        local _, nextToastY = uiContext:createHeader({
            parent = toastsPanel,
            text = "Toast Notifications & Queue",
            xOffset = 10,
            yOffset = -10
        })

        _, nextToastY = uiContext:createParagraph({
            parent = toastsPanel,
            text = "14Toast provides an Obsidian Cyberpunk HUD notification system with auto-dismiss timers, smooth fade animations, hover-to-pause, and FIFO queueing. Test each variant below:",
            xOffset = 10,
            yOffset = nextToastY - 10,
            fontSize = 14
        })

        local toastsLeftCol, toastsRightCol = uiContext:createTwoColumns({
            parent = toastsPanel,
            yOffset = nextToastY - 15,
            height = 320,
            name = "MockUIToastColumns"
        })

        -- Left Column: Trigger buttons 1, 2, 3
        uiContext:createLabel({
            parent = toastsLeftCol,
            text = "Standard Triggers:",
            xOffset = 15,
            yOffset = -10
        })

        -- 1. Base Toast (Minimalist)
        uiContext:createButton({
            parent = toastsLeftCol,
            width = 240,
            height = 32,
            text = "Trigger Base Toast",
            point = "TOPLEFT",
            xOffset = 15,
            yOffset = -38,
            onClick = function()
                uiContext:showToast({
                    title = "System Notice",
                    message = "This is a clean, minimalist toast notification with multiline text wrapping and a close button.",
                    duration = 4
                })
            end
        })

        -- 2. Vector Icon Toast
        uiContext:createButton({
            parent = toastsLeftCol,
            width = 240,
            height = 32,
            text = "Trigger Vector Icon Toast",
            point = "TOPLEFT",
            xOffset = 15,
            yOffset = -80,
            onClick = function()
                uiContext:showToast({
                    title = "Transfer Complete",
                    message = "All currencies and inventory slots synchronized successfully with account storage.",
                    type = "success",
                    duration = 4
                })
            end
        })

        -- 3. Countdown Progress Bar Toast
        uiContext:createButton({
            parent = toastsLeftCol,
            width = 240,
            height = 32,
            text = "Trigger Progress Bar Toast",
            point = "TOPLEFT",
            xOffset = 15,
            yOffset = -122,
            onClick = function()
                uiContext:showToast({
                    title = "Buff Expiring",
                    message = "Enhancement effect will expire in 5 seconds. Hover over this toast to pause countdown!",
                    type = "warning",
                    showProgress = true,
                    duration = 5
                })
            end
        })

        -- Right Column: Trigger buttons 4, 5 and Manager Info
        uiContext:createLabel({
            parent = toastsRightCol,
            text = "Interactive & Semantic Triggers:",
            xOffset = 15,
            yOffset = -10
        })

        -- 4. Interactive OnClick Callback Toast
        uiContext:createButton({
            parent = toastsRightCol,
            width = 240,
            height = 32,
            text = "Trigger Interactive Toast",
            point = "TOPLEFT",
            xOffset = 15,
            yOffset = -38,
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
                    end
                })
            end
        })

        -- 5. Themed Colored Border Toast
        uiContext:createButton({
            parent = toastsRightCol,
            width = 240,
            height = 32,
            text = "Trigger Themed Border Toast",
            point = "TOPLEFT",
            xOffset = 15,
            yOffset = -80,
            onClick = function()
                uiContext:showToast({
                    title = "Critical Alert",
                    message = "Network packet lost or remote handshake timed out. Check connection settings.",
                    type = "error",
                    borderColor = styles.colors.neonRed,
                    showProgress = true,
                    duration = 5
                })
            end
        })

        -- Informational card explaining Queue & Hover
        uiContext:createParagraph({
            parent = toastsRightCol,
            text = "Tip: Rapidly clicking triggers adds toasts to the FIFO queue. Hovering pauses duration.",
            xOffset = 15,
            yOffset = -130,
            fontSize = 12
        })
    end

    -------------------------------------------------------------------------------
    -- 11. COLOR PICKER PANEL
    -------------------------------------------------------------------------------
    local colorPickerPanel = tabbedInterface.panels[11].scrollChild or tabbedInterface.panels[11]
    if colorPickerPanel then
        local _, nextColorY = uiContext:createHeader({
            parent = colorPickerPanel,
            text = "Obsidian Color Picker & Palettes",
            xOffset = 10,
            yOffset = -10
        })

        _, nextColorY = uiContext:createParagraph({
            parent = colorPickerPanel,
            text = "15ColorPicker provides an interactive Obsidian Cyberpunk modal color dialog with RGBA gradient sliders, interactive Hex input (#RRGGBB), checkerboard transparency, and session history.",
            xOffset = 10,
            yOffset = nextColorY - 10,
            fontSize = 14
        })

        local colorLeftCol, colorRightCol = uiContext:createTwoColumns({
            parent = colorPickerPanel,
            yOffset = nextColorY - 15,
            height = 320,
            name = "MockUIColorPickerColumns"
        })

        -- Left Column: Color Picker Swatches
        uiContext:createLabel({
            parent = colorLeftCol,
            text = "Trigger Swatches (Click to edit):",
            xOffset = 15,
            yOffset = -10
        })

        -- Dynamic demo target box that changes color live
        local demoTargetBox = uiContext:createFrame({
            parent = colorRightCol,
            width = 240,
            height = 140,
            point = "TOPLEFT",
            xOffset = 15,
            yOffset = -40,
            borderColor = styles.colors.primary,
            backgroundColor = { 1, 0.38, 0, 0.8 }
        })

        local demoTargetText = demoTargetBox:CreateFontString(nil, "OVERLAY", styles.fonts.text or "GameFontHighlight")
        demoTargetText:SetPoint("CENTER")
        demoTargetText:SetText("Live Preview Surface\nAdjust color swatches to watch me change!")
        demoTargetText:SetJustifyH("CENTER")

        -- Swatch 1: Solid Color
        uiContext:createColorPicker({
            parent = colorLeftCol,
            point = "TOPLEFT",
            xOffset = 15,
            yOffset = -40,
            width = 230,
            text = "Accent Neon Orange",
            color = { 1.00, 0.38, 0.00, 1.00 },
            onChange = function(color, r, g, b, a)
                if demoTargetBox.border then
                    demoTargetBox.border:SetColorTexture(r, g, b, 1)
                end
            end
        })

        -- Swatch 2: Translucent Color (Alpha demonstration)
        uiContext:createColorPicker({
            parent = colorLeftCol,
            point = "TOPLEFT",
            xOffset = 15,
            yOffset = -80,
            width = 230,
            text = "Translucent Backdrop (Alpha)",
            color = { 0.00, 0.75, 1.00, 0.60 },
            onChange = function(color, r, g, b, a)
                if demoTargetBox.background then
                    demoTargetBox.background:SetColorTexture(r, g, b, a)
                end
            end
        })

        -- Swatch 3: Semantic Success Green
        uiContext:createColorPicker({
            parent = colorLeftCol,
            point = "TOPLEFT",
            xOffset = 15,
            yOffset = -120,
            width = 230,
            text = "Status Neon Green",
            color = { 0.00, 1.00, 0.55, 1.00 },
            onChange = function(color, r, g, b, a)
                if demoTargetText then
                    demoTargetText:SetTextColor(r, g, b, a)
                end
            end
        })

        uiContext:createParagraph({
            parent = colorRightCol,
            text = "Tip: The modal dialog includes Hex typing (#RRGGBB), gradient rails, transparency checkerboards, and automatic recent colors history.",
            xOffset = 15,
            yOffset = -200,
            fontSize = 12
        })
    end

    -- Sidebar Palette
    createPaletteFrame(frame)
    frame:Show()
end

-- Register Blizzard Options redirection panel
if AscensionFactory.Integration and AscensionFactory.Integration.registerBlizzardPanel then
    AscensionFactory.Integration:registerBlizzardPanel("AscensionFactory", "Ascension Factory", function()
        createMockUi()
    end)
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
