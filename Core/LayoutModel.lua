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

function lib.LayoutModel:new(uiContext, parent, options)
    if type(options) == "number" then
        options = { startY = options }
    else
        options = options or {}
    end

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
        defaultVerticalGap = options.verticalGap or 10,
        -- Vertical space for the next element
        nextVerticalGap = nil,
        -- Horizontal indent for the next element
        nextXOffset = nil,
        -- Responsive capability engine
        responsiveElements = {},
        responsiveMode = "normal", -- "normal" | "compact"
        responsiveThreshold = options.threshold or 480,
        isResponsive = false,
        onModeChange = options.onModeChange,
        columnGroup = nil,
        columnContainer = nil,
        tallestColumnBottom = nil,
        isStackedColumns = false
    }
    setmetatable(layoutInstance, lib.LayoutModel)

    -- Auto-enable responsive observation by default unless explicitly disabled
    if options.responsive ~= false and parent and parent.HookScript then
        layoutInstance:enableResponsive(options)
    end

    return layoutInstance
end

-- Resets the layout engine state. Used to recycle a LayoutModel instead of creating a new one (saves memory).
function lib.LayoutModel:reset(parent, options)
    if type(options) == "number" then
        options = { startY = options }
    else
        options = options or {}
    end

    self.parent = parent
    self.currentParent = parent
    self.lastAddedElement = nil
    self.columnCurrentX = 0
    self.currentWidth = nil
    self.defaultVerticalGap = options.verticalGap or 10
    self.nextVerticalGap = nil
    self.nextXOffset = nil
    self.responsiveElements = {}
    self.responsiveMode = "normal"
    self.responsiveThreshold = options.threshold or 480
    self.isResponsive = false
    self.onModeChange = options.onModeChange
    self.columnGroup = nil
    self.columnContainer = nil
    self.tallestColumnBottom = nil
    self.isStackedColumns = false

    -- Auto-enable responsive observation by default unless explicitly disabled
    if options.responsive ~= false and parent and parent.HookScript then
        self:enableResponsive(options)
    end

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
        local avail = self:getAvailableWidth(xOffset + rightPad, element)
        if avail > 0 and element.SetWidth then
            element:SetWidth(avail)
        end
        if element.updateLayout then
            element:updateLayout(avail)
        end
        self:registerResponsiveElement(element, function(elem, mode, w, h)
            local currentAvail = self:getAvailableWidth(xOffset + rightPad, elem)
            if currentAvail > 0 and elem.SetWidth then
                elem:SetWidth(currentAvail)
            end
            if elem.updateLayout then
                elem:updateLayout(currentAvail)
            end
        end)
    end

    -- Track element inside active column if applicable
    if self.currentColData then
        table.insert(self.currentColData.elements, element)
        self.currentColData.lastElement = element
        local h = (element.GetHeight and element:GetHeight()) or 24
        self.currentColData.totalEstimatedHeight = (self.currentColData.totalEstimatedHeight or 0) + h + verticalGap
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
    local function evaluateResponsive(isInitial)
        local width = targetFrame:GetWidth() or 0
        local height = targetFrame:GetHeight() or 0
        local newMode = (width < self.responsiveThreshold) and "compact" or "normal"
        if isInitial or newMode ~= self.responsiveMode or options.alwaysNotify then
            self:notifyResponsive(newMode, width, height)
        end
    end

    targetFrame:HookScript("OnSizeChanged", function(frame, w, h)
        if isDebouncing then return end
        if C_Timer and C_Timer.After then
            isDebouncing = true
            C_Timer.After(0.05, function()
                isDebouncing = false
                evaluateResponsive(false)
            end)
        else
            evaluateResponsive(false)
        end
    end)

    evaluateResponsive(true)
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
    self:updateScrollRangeIfAvailable()
end

--- Recursively attempts to update the scroll range if container is within a scrollable viewport.
function lib.LayoutModel:updateScrollRangeIfAvailable()
    local target = self.currentParent
    if target and target.updateScrollRange then
        target:updateScrollRange()
        return
    end
    target = self.parent
    if target and target.updateScrollRange then
        target:updateScrollRange()
        return
    end
    if target and target.GetParent then
        local p = target:GetParent()
        if p and p.updateScrollRange then
            p:updateScrollRange()
            return
        end
        if p and p.GetParent then
            local pp = p:GetParent()
            if pp and pp.updateScrollRange then
                pp:updateScrollRange()
                return
            end
        end
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
--- @param element table|nil Optional UI element to resolve parent frame container dynamically.
--- @return number availableWidth Remaining width in pixels.
function lib.LayoutModel:getAvailableWidth(padding, element)
    padding = padding or 0
    local w = self.currentWidth
    if not w or w <= 0 then
        if element and element.GetParent and element:GetParent() and element:GetParent().GetWidth then
            w = element:GetParent():GetWidth() or 0
        end
        if not w or w <= 0 then
            if self.currentParent and self.currentParent.GetWidth then
                w = self.currentParent:GetWidth() or 0
            elseif self.parent and self.parent.GetWidth then
                w = self.parent:GetWidth() or 0
            else
                w = 0
            end
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
        local avail = self:getAvailableWidth(rightPad, headerElement)
        if avail > 0 and headerElement.SetWidth then
            headerElement:SetWidth(avail)
        end
        self:registerResponsiveElement(headerElement, function(elem, mode, w, h)
            local currentAvail = self:getAvailableWidth(rightPad, elem)
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
        local avail = self:getAvailableWidth(rightPad, labelElement)
        if avail > 0 and labelElement.SetWidth then
            labelElement:SetWidth(avail)
        end
        self:registerResponsiveElement(labelElement, function(elem, mode, w, h)
            local currentAvail = self:getAvailableWidth(rightPad, elem)
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
    local avail = self:getAvailableWidth(rightPad, paragraphElement)
    if avail > 0 and paragraphElement.SetWidth then
        paragraphElement:SetWidth(avail)
    end
    self:registerResponsiveElement(paragraphElement, function(elem, mode, w, h)
        local currentAvail = self:getAvailableWidth(rightPad, elem)
        if currentAvail > 0 and elem.SetWidth then
            elem:SetWidth(currentAvail)
        end
    end)
    return paragraphElement
end

-- Creates a clickable button.
-- Supports positional signature: (elementID, text, tooltip, width, height, onClick)
-- and options table: (elementID, optionsTable)
function lib.LayoutModel:button(elementID, textOrOptions, tooltip, width, height, onClick)
    if not self.uiContext.createButton then return nil end

    local opts = {}
    if type(textOrOptions) == "table" then
        for k, v in pairs(textOrOptions) do opts[k] = v end
    else
        if tooltip ~= nil and type(tooltip) ~= "string" and type(tooltip) ~= "table" then
            onClick, height, width, tooltip = height, width, tooltip, nil
        end
        opts.text = textOrOptions
        opts.tooltip = tooltip
        opts.width = width
        opts.height = height
        opts.onClick = onClick
    end

    opts.parent = self.currentParent
    opts.name = elementID

    local isFluid = opts.fluidWidth or opts.fluid or (self.isResponsive and not opts.width and opts.fluidWidth ~= false)
    if isFluid then
        opts.fluidWidth = true
        opts.width = opts.width or self:getAvailableWidth(opts.rightOffset or 10)
        if opts.width <= 0 then opts.width = 100 end
    end

    local buttonElement = self.uiContext:createButton(opts)
    self.nextVerticalGap = self.nextVerticalGap or 0
    self:anchorElement(buttonElement)

    if isFluid and buttonElement then
        local rightPad = math.abs(opts.fluidRightOffset or opts.rightOffset or 10)
        self:registerResponsiveElement(buttonElement, function(elem, mode, w, h)
            local currentAvail = self:getAvailableWidth(rightPad, elem)
            if currentAvail > 0 and elem.SetWidth then
                elem:SetWidth(currentAvail)
            end
        end)
    end

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

    local isFluid = opts.flexRow or (self.isResponsive and opts.width == nil and opts.flexRow ~= false)
    if isFluid then
        opts.flexRow = true
    end

    local toggleElement = self.uiContext:createToggle(opts)
    self:anchorElement(toggleElement)

    if isFluid and toggleElement then
        local rightPad = math.abs(opts.rightOffset or 10)
        local avail = self:getAvailableWidth(rightPad, toggleElement)
        if avail > 0 and toggleElement.SetWidth then
            toggleElement:SetWidth(avail)
        end
        self:registerResponsiveElement(toggleElement, function(elem, mode, w, h)
            local currentAvail = self:getAvailableWidth(rightPad, elem)
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

    local isFluid = opts.flexRow or (self.isResponsive and opts.width == nil and opts.flexRow ~= false)
    if isFluid then
        opts.flexRow = true
    end

    local checkboxElement = self.uiContext:createCheckbox(opts)
    self:anchorElement(checkboxElement)

    if isFluid and checkboxElement then
        local rightPad = math.abs(opts.rightOffset or 10)
        local avail = self:getAvailableWidth(rightPad, checkboxElement)
        if avail > 0 and checkboxElement.SetWidth then
            checkboxElement:SetWidth(avail)
        end
        self:registerResponsiveElement(checkboxElement, function(elem, mode, w, h)
            local currentAvail = self:getAvailableWidth(rightPad, elem)
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

    local isFluid = opts.fluidWidth or opts.fluid or (self.isResponsive and not opts.length and not opts.width and opts.fluidWidth ~= false)
    if isFluid then
        opts.fluidWidth = true
        opts.length = opts.length or opts.width or self:getAvailableWidth(opts.rightOffset or 16)
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

    if isFluid and sliderElement then
        local rightPad = math.abs(opts.rightOffset or 16)
        self:registerResponsiveElement(sliderElement, function(elem, mode, w, h)
            local currentAvail = self:getAvailableWidth(rightPad, elem)
            if currentAvail > 0 and elem.SetWidth then
                elem:SetWidth(currentAvail)
            end
        end)
    end

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

    local isFluid = opts.fluidWidth or opts.fluid or (self.isResponsive and not opts.width and opts.fluidWidth ~= false)
    if isFluid then
        opts.fluidWidth = true
        opts.width = opts.width or self:getAvailableWidth(opts.rightOffset or 16)
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

    if isFluid and stepperElement then
        local rightPad = math.abs(opts.rightOffset or 16)
        self:registerResponsiveElement(stepperElement, function(elem, mode, w, h)
            local currentAvail = self:getAvailableWidth(rightPad, elem)
            if currentAvail > 0 and elem.SetWidth then
                elem:SetWidth(currentAvail)
            end
        end)
    end

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

    local isFluid = opts.fluidWidth or opts.fluid or (self.isResponsive and not opts.width and opts.fluidWidth ~= false)
    if isFluid then
        opts.fluidWidth = true
        opts.width = opts.width or self:getAvailableWidth(opts.rightOffset or 16)
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

    if isFluid and inputElement then
        local rightPad = math.abs(opts.rightOffset or 16)
        self:registerResponsiveElement(inputElement, function(elem, mode, w, h)
            local currentAvail = self:getAvailableWidth(rightPad, elem)
            if currentAvail > 0 and elem.SetWidth then
                elem:SetWidth(currentAvail)
            end
        end)
    end

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

    local isFluid = opts.fluidWidth or opts.fluid or (self.isResponsive and not opts.width and opts.fluidWidth ~= false)
    if isFluid then
        opts.fluidWidth = true
        opts.width = opts.width or self:getAvailableWidth(opts.rightOffset or 16)
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

    if isFluid and dropdownElement then
        local rightPad = math.abs(opts.rightOffset or 16)
        self:registerResponsiveElement(dropdownElement, function(elem, mode, w, h)
            local currentAvail = self:getAvailableWidth(rightPad, elem)
            if currentAvail > 0 and elem.SetWidth then
                elem:SetWidth(currentAvail)
            end
        end)
    end

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

--- Begins a columnar layout, allowing side-by-side or adaptively stacked elements.
--- Supports legacy signature: (xOffset, width)
--- or options table: ({ width = 0.5, xOffset = 0, gap = 12, minWidth = 120 })
--- @param xOffsetOrOptions number|table|nil Horizontal indent or options table.
--- @param width number|nil Column width (pixels if > 1, proportion of container if <= 1).
function lib.LayoutModel:beginColumn(xOffsetOrOptions, width)
    -- If this is the start of a column group row, create a transparent container
    if not self.columnGroup then
        local groupContainer = self.uiContext:acquireElement("Frame", self.currentParent, {})
        local oldX, oldY = self.nextXOffset, self.nextVerticalGap
        self.nextXOffset, self.nextVerticalGap = 0, 0
        self:anchorElement(groupContainer)
        self.nextXOffset, self.nextVerticalGap = oldX, oldY

        groupContainer:SetPoint("RIGHT", self.currentParent, "RIGHT", 0, 0)

        self.columnGroup = {
            container = groupContainer,
            columns = {},
            previousParent = self.currentParent,
            finalizePadding = 0
        }
        -- Backward-compatibility alias
        self.columnContainer = groupContainer
        self.previousParentCol = self.currentParent
    end

    local opts = {}
    if type(xOffsetOrOptions) == "table" then
        for k, v in pairs(xOffsetOrOptions) do opts[k] = v end
    else
        opts.xOffset = xOffsetOrOptions
        opts.width = width
    end

    if opts.width and type(opts.width) == "number" and opts.width > 0 and opts.width <= 1 then
        opts.isProportional = true
        opts.proportion = opts.width
    elseif opts.width and type(opts.width) == "number" and opts.width > 1 then
        opts.explicitWidth = opts.width
    end

    -- Create dedicated sub-frame for this column
    local colFrame = self.uiContext:acquireElement("Frame", self.columnGroup.container, {})

    local colData = {
        frame = colFrame,
        opts = opts,
        elements = {},
        totalEstimatedHeight = 0
    }
    table.insert(self.columnGroup.columns, colData)
    self.currentColData = colData

    -- Context Shift: Next elements will be anchored INSIDE this column frame
    self.currentParent = colFrame
    self.lastAddedElement = nil
    self.columnCurrentX = 0
    self.currentWidth = opts.explicitWidth or nil
end

--- Marks the end of a column and sets its bottom anchor to wrap its contents.
function lib.LayoutModel:endColumn()
    if not self.currentColData then return end

    local colData = self.currentColData
    if self.lastAddedElement then
        colData.frame:SetPoint("BOTTOM", self.lastAddedElement, "BOTTOM", 0, 0)
        colData.lastElement = self.lastAddedElement
    else
        colData.frame:SetHeight(1)
    end

    self.currentColData = nil
    self.lastAddedElement = nil
    self.currentWidth = nil
end

--- Applies column positioning and dimensions according to the active responsive mode.
--- @param group table The active column group metadata table.
--- @param mode string Responsive mode ("normal" or "compact").
--- @param totalWidth number|nil Optional container width in pixels.
function lib.LayoutModel:applyColumnLayout(group, mode, totalWidth)
    if not group or not group.container or not group.columns then return end
    local cols = group.columns
    if #cols == 0 then return end

    local container = group.container
    local availW = totalWidth
    if not availW or availW <= 0 then
        availW = (container.GetWidth and container:GetWidth()) or (self.parent and self.parent.GetWidth and self.parent:GetWidth()) or 500
    end
    if availW <= 0 then availW = 500 end

    local isCompact = (mode == "compact") or (availW < self.responsiveThreshold)

    if isCompact then
        -- Compact mode: Stack columns vertically at 100% width
        for i, col in ipairs(cols) do
            col.frame:ClearAllPoints()
            col.frame:SetWidth(availW)
            col.frame:SetPoint("RIGHT", container, "RIGHT", 0, 0)
            if i == 1 then
                col.frame:SetPoint("TOPLEFT", container, "TOPLEFT", 0, 0)
            else
                local prevCol = cols[i - 1]
                local gap = col.opts.gap or 12
                col.frame:SetPoint("TOPLEFT", prevCol.frame, "BOTTOMLEFT", 0, -gap)
            end
            if col.lastElement then
                col.frame:SetPoint("BOTTOM", col.lastElement, "BOTTOM", 0, 0)
            else
                col.frame:SetHeight(1)
            end
        end

        local lastCol = cols[#cols]
        container:SetPoint("BOTTOM", lastCol.frame, "BOTTOM", 0, -(group.finalizePadding or 0))
    else
        -- Normal mode: Side-by-side column positioning
        local defaultColWidth = math.max(10, math.floor(availW / #cols))
        local tallestCol = cols[1]
        local lowestBottom = nil

        for i, col in ipairs(cols) do
            col.frame:ClearAllPoints()

            -- Width calculation
            local colW = defaultColWidth
            if col.opts.isProportional then
                colW = math.max(10, math.floor(availW * col.opts.proportion))
            elseif col.opts.explicitWidth then
                colW = col.opts.explicitWidth
            end
            col.frame:SetWidth(colW)

            -- Horizontal placement
            if col.opts.xOffset then
                col.frame:SetPoint("TOPLEFT", container, "TOPLEFT", col.opts.xOffset, 0)
            else
                if i == 1 then
                    col.frame:SetPoint("TOPLEFT", container, "TOPLEFT", 0, 0)
                else
                    local prevCol = cols[i - 1]
                    local gap = col.opts.gap or 12
                    col.frame:SetPoint("TOPLEFT", prevCol.frame, "TOPRIGHT", gap, 0)
                end
            end

            -- Wrap bottom
            if col.lastElement then
                col.frame:SetPoint("BOTTOM", col.lastElement, "BOTTOM", 0, 0)
            else
                col.frame:SetHeight(1)
            end

            -- Track tallest column
            local b = col.lastElement and col.lastElement.GetBottom and col.lastElement:GetBottom()
            if b then
                if not lowestBottom or b < lowestBottom then
                    lowestBottom = b
                    tallestCol = col
                end
            else
                if (col.totalEstimatedHeight or 0) > (tallestCol.totalEstimatedHeight or 0) then
                    tallestCol = col
                end
            end
        end

        if tallestCol and tallestCol.frame then
            container:SetPoint("BOTTOM", tallestCol.frame, "BOTTOM", 0, -(group.finalizePadding or 0))
            self.tallestColumnBottom = tallestCol.lastElement
        else
            container:SetHeight(10)
        end
    end
end

--- Finalizes the column layout, balances heights, registers responsive behavior,
--- and optionally attaches the master content frame.
--- @param contentFrame table|nil Optional master container frame to stretch height.
--- @param bottomPadding number|nil Additional padding below the columns.
function lib.LayoutModel:columnsFinalize(contentFrame, bottomPadding)
    local group = self.columnGroup
    if not group then
        if contentFrame and self.lastAddedElement then
            contentFrame:SetPoint("BOTTOM", self.lastAddedElement, "BOTTOM", 0, -(bottomPadding or 20))
        end
        return
    end

    group.finalizePadding = bottomPadding or 0

    -- Apply initial column arrangement
    local initialWidth = (group.container.GetWidth and group.container:GetWidth()) or (self.parent and self.parent.GetWidth and self.parent:GetWidth()) or 0
    local initialMode = self.responsiveMode or ((initialWidth < self.responsiveThreshold) and "compact" or "normal")
    self:applyColumnLayout(group, initialMode, initialWidth)

    -- Register container for live responsive adaptation
    local capturedGroup = group
    self:registerResponsiveElement(capturedGroup.container, function(elem, mode, w, h)
        self:applyColumnLayout(capturedGroup, mode, w)
    end)

    -- Restore layout context
    self.currentParent = group.previousParent
    self.lastAddedElement = group.container
    self.columnGroup = nil
    self.currentColData = nil
    self.columnCurrentX = 0
    self.currentWidth = nil
    self.columnContainer = nil

    -- Optionally finalize master content frame
    if contentFrame and self.lastAddedElement then
        contentFrame:SetPoint("BOTTOM", self.lastAddedElement, "BOTTOM", 0, -(bottomPadding or 20))
    end

    self:updateScrollRangeIfAvailable()
end

-------------------------------------------------------------------------------
-- 7. CONTEXT EXTENSION
-- Objective: Attach the LayoutModel class to the UI Context factory, so developers can create a LayoutModel directly from the context.
-- Variables:
-- parent (table): The main frame to attach the layout model to.
-- options (table|nil): Optional responsive configuration table.
-------------------------------------------------------------------------------

if Context then
    --- Creates a specialized layout model cursor within the context.
    --- @param parent table The container frame to manage layout within.
    --- @param options table|nil Optional responsive configuration options.
    --- @return table|nil layoutInstance The new LayoutModel instance.
    function Context:createLayoutModel(parent, options)
        if lib.LayoutModel then
            return lib.LayoutModel:new(self, parent, options)
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
