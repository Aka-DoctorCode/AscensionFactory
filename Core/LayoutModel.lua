-------------------------------------------------------------------------------
-- Project: AscensionFactory
-- Author: Aka-DoctorCode
-- File: LayoutModel.lua
-------------------------------------------------------------------------------
---@diagnostic disable: undefined-global, undefined-field, inject-field

-------------------------------------------------------------------------------
-- 1. INITIALIZATION
-- Objective: Initialize the LayoutModel namespace and link it to the global AscensionFactory library.
-- Variables:
-- MAJOR: The namespace identifier for the addon library.
-------------------------------------------------------------------------------
local MAJOR = "AscensionFactory"
local lib = LibStub:GetLibrary(MAJOR)
if not lib then return end
local Context = lib.Context

-- Acts as a class blueprint to store our LayoutModel functions.
lib.LayoutModel = lib.LayoutModel or {}
-- Setup Lua OOP inheritance. __index to itself means any new table created from this blueprint will automatically have access to all its functions.
lib.LayoutModel.__index = lib.LayoutModel

-------------------------------------------------------------------------------
-- 2. CONSTRUCTOR & CORE ANCHORING
-- Objective: Initializes a new LayoutModel instance to handle UI element positioning automatically.
-- Variables:
-- uiContext: The UI framework context containing styles and element factories.
-- parent: The main WoW UI frame that all layout elements will be attached to.
-------------------------------------------------------------------------------

function lib.LayoutModel:new(uiContext, parent)
    local layoutInstance = {
        uiContext = uiContext or self.uiContext,
        parent = parent,
        -- Tracks the active container frame
        currentParent = parent,
        -- The reference element for vertical stacking
        lastAddedElement = nil,
        -- Horizontal indent for columns
        columnCurrentX = 0,
        -- Forced width state for elements
        currentWidth = nil,
        -- Engine default layout settings
        defaultVerticalGap = 10,
        -- Vertical space for the next element
        nextVerticalGap = nil,
        -- Horizontal indent for the next element
        nextXOffset = nil,
        -- Responsive capability engine
        responsiveElements = {},
        responsiveMode = "normal", -- "normal" | "compact"
        responsiveThreshold = 480,
        isResponsive = false,
        onModeChange = nil
    }
    return setmetatable(layoutInstance, lib.LayoutModel)
end

-- Resets the layout engine state. Used to recycle a LayoutModel instead of creating a new one (saves memory).
function lib.LayoutModel:reset(parent)
    self.parent = parent
    self.currentParent = parent
    self.lastAddedElement = nil
    self.columnCurrentX = 0
    self.currentWidth = nil
    self.nextVerticalGap = nil
    self.nextXOffset = nil
    self.responsiveElements = {}
    self.responsiveMode = "normal"
    self.responsiveThreshold = 480
    self.isResponsive = false
    self.onModeChange = nil
    return self
end

-------------------------------------------------------------------------------
-- 3. ANCHOR ENGINE
-- Objective: Dynamically anchor elements to the previously created widget.
-- Variables
-- amount: The vertical space in pixels
-- element: The UI elements being placed on screen
-------------------------------------------------------------------------------

-- Adds vertical space before the next element is placed.
function lib.LayoutModel:addSpace(amount)
    self.nextVerticalGap = amount
end

-- Adds a one-time horizontal indent for the next element placed.
function lib.LayoutModel:addIndent(amount)
    self.nextXOffset = amount
end

-- Anchors a newly created element vertically below the previous one.
function lib.LayoutModel:anchorElement(element)
    -- Prevent nil errors if factory failed
    if type(element) ~= "table" or not element.SetPoint then return end
    
    local xOffset = self.nextXOffset or self.columnCurrentX or 0
    local verticalGap = self.nextVerticalGap or self.defaultVerticalGap
    
    -- Reset overrides so they only affect this one element.
    self.nextXOffset = nil
    self.nextVerticalGap = nil

    -- Clear any factory-default anchors
    element:ClearAllPoints()

    if not self.lastAddedElement then
        -- If no previous element exists, this is the first item in the container.
        -- Anchor it directly to the top-left corner of the container frame.
        element:SetPoint("TOPLEFT", self.currentParent, "TOPLEFT", xOffset, -verticalGap)
    else
        -- Standard vertical stacking below the previous element
        element:SetPoint("TOPLEFT", self.lastAddedElement, "BOTTOMLEFT", xOffset, -verticalGap)
    end

    -- If element is marked for fluid width, adapt its width dynamically to available space
    if element.fluidWidth then
        local rightPad = math.abs(element.fluidRightOffset or 10)
        local avail = self:getAvailableWidth(xOffset + rightPad)
        if avail > 0 and element.SetWidth then
            element:SetWidth(avail)
        end
        if element.updateLayout then
            element:updateLayout(avail)
        end
        self:registerResponsiveElement(element, function(elem, mode, w, h)
            local currentAvail = self:getAvailableWidth(xOffset + rightPad)
            if currentAvail > 0 and elem.SetWidth then
                elem:SetWidth(currentAvail)
            end
            if elem.updateLayout then
                elem:updateLayout(currentAvail)
            end
        end)
    end

    -- Update tracker for the next element
    self.lastAddedElement = element
end

-------------------------------------------------------------------------------
-- 3.1 RESPONSIVE CAPABILITY ENGINE
-- Objective: Dynamically observe container size changes, manage breakpoints,
-- and propagate responsive layout modes (normal vs compact) to registered elements.
-------------------------------------------------------------------------------

--- Enables responsive observation on the layout container frame.
--- @param options table|nil Configuration table (threshold, frame, onModeChange, alwaysNotify).
function lib.LayoutModel:enableResponsive(options)
    options = options or {}
    self.isResponsive = true
    self.responsiveThreshold = options.threshold or 480
    self.onModeChange = options.onModeChange
    local targetFrame = options.frame or self.parent

    if not targetFrame or not targetFrame.HookScript then return end

    local isDebouncing = false
    local function evaluateResponsive()
        local width = targetFrame:GetWidth() or 0
        local height = targetFrame:GetHeight() or 0
        local newMode = (width < self.responsiveThreshold) and "compact" or "normal"
        if newMode ~= self.responsiveMode or options.alwaysNotify then
            self:notifyResponsive(newMode, width, height)
        end
    end

    targetFrame:HookScript("OnSizeChanged", function(frame, w, h)
        if isDebouncing then return end
        if C_Timer and C_Timer.After then
            isDebouncing = true
            C_Timer.After(0.05, function()
                isDebouncing = false
                evaluateResponsive()
            end)
        else
            evaluateResponsive()
        end
    end)

    evaluateResponsive()
end

--- Broadcasts a responsive mode transition to all registered responsive elements.
--- @param newMode string The new responsive mode ("normal" or "compact").
--- @param width number Container width in pixels.
--- @param height number Container height in pixels.
function lib.LayoutModel:notifyResponsive(newMode, width, height)
    self.responsiveMode = newMode
    if self.responsiveElements then
        for _, item in ipairs(self.responsiveElements) do
            if item.callback and item.element then
                item.callback(item.element, newMode, width, height)
            end
        end
    end
    if self.onModeChange then
        self.onModeChange(self, newMode, width, height)
    end
end

--- Registers an element with an update callback to receive responsive mode notifications.
--- @param element table The UI frame or element being observed.
--- @param callback function Callback invoked as callback(element, mode, width, height).
function lib.LayoutModel:registerResponsiveElement(element, callback)
    if not self.responsiveElements then
        self.responsiveElements = {}
    end
    table.insert(self.responsiveElements, {
        element = element,
        callback = callback
    })
    if callback and element then
        local w = (self.parent and self.parent.GetWidth and self.parent:GetWidth()) or 0
        local h = (self.parent and self.parent.GetHeight and self.parent:GetHeight()) or 0
        callback(element, self.responsiveMode or "normal", w, h)
    end
end

--- Computes the usable width inside the current active container frame.
--- @param padding number|nil Optional inner margin to subtract.
--- @return number availableWidth Remaining width in pixels.
function lib.LayoutModel:getAvailableWidth(padding)
    padding = padding or 0
    local w = self.currentWidth
    if not w or w <= 0 then
        if self.currentParent and self.currentParent.GetWidth then
            w = self.currentParent:GetWidth() or 0
        elseif self.parent and self.parent.GetWidth then
            w = self.parent:GetWidth() or 0
        else
            w = 0
        end
    end
    return math.max(0, w - padding)
end

-------------------------------------------------------------------------------
-- 4. COMPONENT WRAPPERS
-- Objective: Instantiate elements and process them through the Anchor Engine.
-- Variables:
-- elementID: Unique identifier for the UI element.
-- text: Text string displayed by the element.
-- rightOffset: Distance from the right edge to force wrapping
-- elementID: Unique identifier string
-- tooltip: Hover information text
-- width: Button width in pixels
-- height: Button height in pixels
-- onClick: Callback function executed when clicked
-- getter: Function returning current state
-- setter: Function called with the new state when toggled
-------------------------------------------------------------------------------

-- Creates a header element to categorize sections.
function lib.LayoutModel:header(elementID, text, options)
    if not self.uiContext.createHeader then return nil end

    local opts = {
        parent = self.currentParent,
        name = elementID,
        text = text
    }
    if type(options) == "table" then
        for k, v in pairs(options) do opts[k] = v end
    elseif type(options) == "number" then
        opts.rightOffset = options
    end

    local headerElement = self.uiContext:createHeader(opts)
    -- standard visual breathing room unless overridden
    self.nextVerticalGap = self.nextVerticalGap or 15
    self:anchorElement(headerElement)
    if opts.wordWrap or opts.elasticWidth or opts.rightOffset then
        local rightPad = math.abs(opts.rightOffset or 10)
        local avail = self:getAvailableWidth(rightPad)
        if avail > 0 and headerElement.SetWidth then
            headerElement:SetWidth(avail)
        end
        self:registerResponsiveElement(headerElement, function(elem, mode, w, h)
            local currentAvail = self:getAvailableWidth(rightPad)
            if currentAvail > 0 and elem.SetWidth then
                elem:SetWidth(currentAvail)
            end
        end)
    end
    return headerElement
end

-- Creates a standard text label.
function lib.LayoutModel:label(elementID, text, options)
    if not self.uiContext.createLabel then return nil end

    local opts = {
        parent = self.currentParent,
        name = elementID,
        text = text
    }
    if type(options) == "table" then
        for k, v in pairs(options) do opts[k] = v end
    elseif type(options) == "number" then
        opts.rightOffset = options
    end

    local labelElement = self.uiContext:createLabel(opts)
    self:anchorElement(labelElement)
    if opts.wordWrap or opts.elasticWidth or opts.rightOffset then
        local rightPad = math.abs(opts.rightOffset or 10)
        local avail = self:getAvailableWidth(rightPad)
        if avail > 0 and labelElement.SetWidth then
            labelElement:SetWidth(avail)
        end
        self:registerResponsiveElement(labelElement, function(elem, mode, w, h)
            local currentAvail = self:getAvailableWidth(rightPad)
            if currentAvail > 0 and elem.SetWidth then
                elem:SetWidth(currentAvail)
            end
        end)
    end
    return labelElement
end

-- Creates a multi-line paragraph that wraps text.
function lib.LayoutModel:paragraph(elementID, text, rightOffset)
    if not self.uiContext.createParagraph then return nil end

    local paragraphElement = self.uiContext:createParagraph({
        parent = self.currentParent,
        name = elementID,
        text = text,
        rightOffset = rightOffset
    })

    self:anchorElement(paragraphElement)
    local rightPad = math.abs(rightOffset or 10)
    local avail = self:getAvailableWidth(rightPad)
    if avail > 0 and paragraphElement.SetWidth then
        paragraphElement:SetWidth(avail)
    end
    self:registerResponsiveElement(paragraphElement, function(elem, mode, w, h)
        local currentAvail = self:getAvailableWidth(rightPad)
        if currentAvail > 0 and elem.SetWidth then
            elem:SetWidth(currentAvail)
        end
    end)
    return paragraphElement
end

-- Creates a clickable button.
function lib.LayoutModel:button(elementID, text, tooltip, width, height, onClick)
    if tooltip ~= nil and type(tooltip) ~= "string" then
        onClick, height, width, tooltip = height, width, tooltip, nil
    end

    if not self.uiContext.createButton then return nil end

    local buttonElement = self.uiContext:createButton({
        parent = self.currentParent,
        name = elementID,
        text = text,
        tooltip = tooltip,
        width = width,
        height = height,
        onClick = onClick
    })

    self.nextVerticalGap = self.nextVerticalGap or 0
    self:anchorElement(buttonElement)
    return buttonElement
end

-- Creates a toggle switch.
function lib.LayoutModel:toggle(elementID, getterOrOptions, setter, width, height, onClick)
    if not self.uiContext.createToggle then return nil end

    local opts = {}
    if type(getterOrOptions) == "table" then
        for k, v in pairs(getterOrOptions) do opts[k] = v end
    else
        opts.getter = getterOrOptions
        opts.setter = setter
        opts.width = width
        opts.height = height
        opts.onClick = onClick
    end

    opts.parent = self.currentParent
    opts.name = elementID

    local toggleElement = self.uiContext:createToggle(opts)
    self:anchorElement(toggleElement)
    if opts.flexRow and toggleElement then
        local rightPad = math.abs(opts.rightOffset or 10)
        local avail = self:getAvailableWidth(rightPad)
        if avail > 0 and toggleElement.SetWidth then
            toggleElement:SetWidth(avail)
        end
        self:registerResponsiveElement(toggleElement, function(elem, mode, w, h)
            local currentAvail = self:getAvailableWidth(rightPad)
            if currentAvail > 0 and elem.SetWidth then
                elem:SetWidth(currentAvail)
            end
        end)
    end
    return toggleElement
end

-- Creates a checkbox element.
function lib.LayoutModel:checkbox(elementID, textOrOptions, getter, setter, size, onClick)
    if not self.uiContext.createCheckbox then return nil end

    local opts = {}
    if type(textOrOptions) == "table" then
        for k, v in pairs(textOrOptions) do opts[k] = v end
    else
        opts.text = textOrOptions
        opts.getter = getter
        opts.setter = setter
        opts.size = size
        opts.onClick = onClick
    end

    opts.parent = self.currentParent
    opts.name = elementID

    local checkboxElement = self.uiContext:createCheckbox(opts)
    self:anchorElement(checkboxElement)
    if opts.flexRow and checkboxElement then
        local rightPad = math.abs(opts.rightOffset or 10)
        local avail = self:getAvailableWidth(rightPad)
        if avail > 0 and checkboxElement.SetWidth then
            checkboxElement:SetWidth(avail)
        end
        self:registerResponsiveElement(checkboxElement, function(elem, mode, w, h)
            local currentAvail = self:getAvailableWidth(rightPad)
            if currentAvail > 0 and elem.SetWidth then
                elem:SetWidth(currentAvail)
            end
        end)
    end
    return checkboxElement
end

-- Creates a precision slider element.
-- Hybrid signature: (elementID, textOrOptions, min, max, step, getter, setter, options) or (elementID, optionsTable)
function lib.LayoutModel:slider(elementID, textOrOptions, minValue, maxValue, step, getter, setter, options)
    if not self.uiContext.createSlider then return nil end

    local opts = {}
    if type(textOrOptions) == "table" then
        for k, v in pairs(textOrOptions) do opts[k] = v end
    else
        if options and type(options) == "table" then
            for k, v in pairs(options) do opts[k] = v end
        end
        opts.text = textOrOptions
        opts.minValue = minValue
        opts.maxValue = maxValue
        opts.step = step
        opts.getter = getter
        opts.setter = setter
    end

    opts.parent = self.currentParent
    opts.name = elementID
    opts.orientation = opts.orientation or "HORIZONTAL"

    if opts.fluidWidth then
        opts.fluidWidth = true
        opts.length = opts.length or opts.width or self:getAvailableWidth(16)
        if opts.length <= 0 then opts.length = 200 end
    else
        opts.length = opts.length or opts.width or self.currentWidth or 200
    end

    -- Add label if text is provided
    if opts.text and opts.text ~= "" then
        self:label(elementID .. "_Label", opts.text)
    end

    local sliderElement = self.uiContext:createSlider(opts)
    self:anchorElement(sliderElement)
    return sliderElement
end

-- Creates a numeric stepper element.
-- Hybrid signature: (elementID, textOrOptions, min, max, step, getter, setter, options) or (elementID, optionsTable)
function lib.LayoutModel:stepper(elementID, textOrOptions, minValue, maxValue, step, getter, setter, options)
    if not self.uiContext.createStepper then return nil end

    local opts = {}
    if type(textOrOptions) == "table" then
        for k, v in pairs(textOrOptions) do opts[k] = v end
    else
        if options and type(options) == "table" then
            for k, v in pairs(options) do opts[k] = v end
        end
        opts.text = textOrOptions
        opts.minValue = minValue
        opts.maxValue = maxValue
        opts.step = step
        opts.getter = getter
        opts.setter = setter
    end

    opts.parent = self.currentParent
    opts.name = elementID

    if opts.fluidWidth then
        opts.fluidWidth = true
        opts.width = opts.width or self:getAvailableWidth(16)
        if opts.width <= 0 then opts.width = 160 end
    else
        opts.width = opts.width or self.currentWidth or 160
    end
    opts.height = opts.height or 26

    -- Add label if text is provided
    if opts.text and opts.text ~= "" then
        self:label(elementID .. "_Label", opts.text)
    end

    local stepperElement = self.uiContext:createStepper(opts)
    self:anchorElement(stepperElement)
    return stepperElement
end

-- Creates a text input field element.
-- Hybrid signature: (elementID, textOrOptions, width, height, options) or (elementID, optionsTable)
function lib.LayoutModel:inputField(elementID, textOrOptions, width, height, options)
    if not self.uiContext.createInputField then return nil end

    local opts = {}
    if type(textOrOptions) == "table" then
        for k, v in pairs(textOrOptions) do opts[k] = v end
    else
        if options and type(options) == "table" then
            for k, v in pairs(options) do opts[k] = v end
        end
        opts.text = textOrOptions
        opts.width = width or opts.width
        opts.height = height or opts.height
    end

    opts.parent = self.currentParent
    opts.name = elementID

    if opts.fluidWidth then
        opts.fluidWidth = true
        opts.width = opts.width or self:getAvailableWidth(16)
        if opts.width <= 0 then opts.width = 200 end
    else
        opts.width = opts.width or self.currentWidth or 200
    end
    opts.height = opts.height or 28

    -- Add label if label text is provided
    if opts.label and opts.label ~= "" then
        self:label(elementID .. "_Label", opts.label)
    end

    local inputElement = self.uiContext:createInputField(opts)
    self:anchorElement(inputElement)
    return inputElement
end
lib.LayoutModel.input = lib.LayoutModel.inputField

-- Creates a dropdown menu selector element.
-- Hybrid signature: (elementID, textOrOptions, optionsList, getter, setter, options) or (elementID, optionsTable)
function lib.LayoutModel:dropdown(elementID, textOrOptions, optionsList, getter, setter, options)
    if not self.uiContext.createDropdown then return nil end

    local opts = {}
    if type(textOrOptions) == "table" then
        for k, v in pairs(textOrOptions) do opts[k] = v end
    else
        if options and type(options) == "table" then
            for k, v in pairs(options) do opts[k] = v end
        end
        opts.text = textOrOptions
        opts.options = optionsList or opts.options
        opts.getter = getter or opts.getter
        opts.setter = setter or opts.setter
    end

    opts.parent = self.currentParent
    opts.name = elementID

    if opts.fluidWidth then
        opts.fluidWidth = true
        opts.width = opts.width or self:getAvailableWidth(16)
        if opts.width <= 0 then opts.width = 160 end
    else
        opts.width = opts.width or self.currentWidth or 160
    end
    opts.height = opts.height or 26

    -- Add label if text is provided
    if opts.text and opts.text ~= "" then
        self:label(elementID .. "_Label", opts.text)
    end

    local dropdownElement = self.uiContext:createDropdown(opts)
    self:anchorElement(dropdownElement)
    return dropdownElement
end

-------------------------------------------------------------------------------
-- 5. SECTION MANAGEMENT
-- Objective: Group elements dynamically using BOTTOM-anchoring for auto-resizing.
-- width: Optional explicit width for the section box.
-- section: The dynamically created Frame serving as the group container.
-------------------------------------------------------------------------------

-- Begins a new layout section with its own backdrop and relative positioning.
function lib.LayoutModel:beginSection(width)
    local section = self.uiContext:acquireElement("Frame", self.currentParent, {})
    
    -- default indent for sections
    self.nextXOffset = self.nextXOffset or 8
    self:anchorElement(section)

    if width then
        section:SetWidth(width)
    else
        section:SetPoint("RIGHT", self.currentParent, "RIGHT", -8, 0)
    end

    -- Setup Background and Border
    if not section.border then
        local border = section:CreateTexture(nil, "BACKGROUND", nil, -2)
        border:SetAllPoints(section)
        section.border = border
    end

    if self.uiContext.styles.colors.surfaceLight then
        section.border:SetColorTexture(unpack(self.uiContext.styles.colors.surfaceLight))
    end

    if not section.background then
        local background = section:CreateTexture(nil, "BACKGROUND", nil, -1)
        background:SetPoint("TOPLEFT", section, "TOPLEFT", 1, -1)
        background:SetPoint("BOTTOMRIGHT", section, "BOTTOMRIGHT", -1, 1)
        section.background = background
    end

    if self.uiContext.styles.colors.surfaceDark then
        section.background:SetColorTexture(unpack(self.uiContext.styles.colors.surfaceDark))
    end

    -- Context Shift: Next elements will be anchored INSIDE this section
    self.previousParent = self.currentParent
    self.currentParent = section
    -- Reset cursor for the inside of the section
    self.lastAddedElement = nil
end

-- Finalizes the current section, automatically stretching its height to wrap contents.
function lib.LayoutModel:endSection()
    local section = self.currentParent
    if not section then return end

    -- Dynamic Height: Stretch the section's bottom to wrap around the last added element
    if self.lastAddedElement then
        section:SetPoint("BOTTOM", self.lastAddedElement, "BOTTOM", 0, -10)
    else
        section:SetHeight(20) -- Fallback for an empty section
    end

    -- Context Pop: Return to the parent layout flow
    self.currentParent = self.previousParent
    self.lastAddedElement = section
end

-------------------------------------------------------------------------------
-- 6. COLUMN MANAGEMENT
-- Objective: Use invisible containers to auto-calculate the tallest column.
-- Variables:
-- xOffset: The horizontal coordinate indent for the current column.
-- width: The total width allocated for the current column.
-- contentFrame: The master container frame whose height is updated.
-- bottomPadding: Extra space to add at the bottom of the content frame.
-------------------------------------------------------------------------------

-- Begins a columnar layout, allowing side-by-side elements.
function lib.LayoutModel:beginColumn(xOffset, width)
    -- If this is the start of a column row, create a transparent container
    if not self.columnContainer then
        self.columnContainer = self.uiContext:acquireElement("Frame", self.currentParent, {})
        -- We temporarily disable nextXOffset/nextVerticalGap for this structural frame
        local oldX, oldY = self.nextXOffset, self.nextVerticalGap
        self.nextXOffset, self.nextVerticalGap = 0, 0
        self:anchorElement(self.columnContainer)
        self.nextXOffset, self.nextVerticalGap = oldX, oldY

        self.columnContainer:SetPoint("RIGHT", self.currentParent, "RIGHT", 0, 0)

        self.previousParentCol = self.currentParent
        self.currentParent = self.columnContainer
    end

    -- Reset vertical anchor for the new column
    self.lastAddedElement = nil
    self.columnCurrentX = xOffset or 0
    self.currentWidth = width
end

-- Marks the end of a column and updates the tallest column tracker.
function lib.LayoutModel:endColumn()
    -- Track the absolute lowest point reached by any column in this row
    if self.lastAddedElement then
        if not self.tallestColumnBottom or self.lastAddedElement:GetBottom() < self.tallestColumnBottom:GetBottom() then
            self.tallestColumnBottom = self.lastAddedElement
        end
    end
end

-- Finalizes the column layout and updates the parent container's height.
function lib.LayoutModel:columnsFinalize(contentFrame, bottomPadding)
    if self.columnContainer then
        -- Snap the container's bottom to the tallest column automatically
        if self.tallestColumnBottom then
            self.columnContainer:SetPoint("BOTTOM", self.tallestColumnBottom, "BOTTOM", 0, -(bottomPadding or 0))
        else
            self.columnContainer:SetHeight(10)
        end

        -- Restore original context
        self.currentParent = self.previousParentCol
        self.lastAddedElement = self.columnContainer

        -- State cleanup
        self.columnContainer = nil
        self.tallestColumnBottom = nil
        self.columnCurrentX = 0
        self.currentWidth = nil
    end

    -- Optionally finalize the master content frame if provided
    if contentFrame and self.lastAddedElement then
        contentFrame:SetPoint("BOTTOM", self.lastAddedElement, "BOTTOM", 0, -(bottomPadding or 20))
    end
end

-------------------------------------------------------------------------------
-- 7. CONTEXT EXTENSION
-- Objective: Attach the LayoutModel class to the UI Context factory, so developers can create a LayoutModel directly from the context.
-- Variables:
-- parent (table): The main frame to attach the layout model to.
-------------------------------------------------------------------------------

if Context then
    --- Creates a specialized layout model cursor within the context.
    --- @param parent table The container frame to manage layout within.
    --- @return table|nil layoutInstance The new LayoutModel instance.
    function Context:createLayoutModel(parent)
        if lib.LayoutModel then
            return lib.LayoutModel:new(self, parent)
        end
    end
end

-------------------------------------------------------------------------------
-- 8. EXTENSION & EXPANSION NOTES
-- Objective: Guidelines for adding new component wrappers, grid systems, and auto-scrolling containers.
--
-- How to expand:
-- 1. Adding New Component Wrappers:
--    Implement new wrapper methods on `lib.LayoutModel` (e.g. `layout:slider(...)`, `layout:stepper(...)`, `layout:inputField(...)`)
--    that call `self.uiContext:create<Widget>()` and route the returned element through `self:anchorElement(element)`.
-- 2. Grid Layout Engines:
--    Implement `layout:beginGrid(columns, cellWidth, cellHeight, gapX, gapY)` to arrange items in a matrix
--    by computing row and column coordinate offsets mathematically.
-- 3. Scrollable Content Sizing:
--    Use `layout:columnsFinalize(scrollChild, bottomPadding)` to automatically anchor the bottom of a ScrollChild
--    frame to the lowest element placed in the layout flow, allowing the scroll range to match content height dynamically.
-------------------------------------------------------------------------------
