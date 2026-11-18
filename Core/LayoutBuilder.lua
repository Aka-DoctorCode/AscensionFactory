-------------------------------------------------------------------------------
-- Project: AscensionFactory
-- Author: Aka-DoctorCode
-- File: LayoutBuilder.lua
-------------------------------------------------------------------------------
---@diagnostic disable: undefined-global, undefined-field, inject-field

-------------------------------------------------------------------------------
-- 1. INITIALIZATION
-- Objective: Provide the fluent LayoutBuilder facade (Proposal 1.D + 3.D)
-- mixed into LayoutModel for backward compatibility, plus centralized
-- Context auto-anchoring for { layout = myLayout }.
-------------------------------------------------------------------------------
local MAJOR = "AscensionFactory"
local lib = LibStub:GetLibrary(MAJOR)
if not lib then return end

local Context = lib.Context
local LayoutModel = lib.LayoutModel
if not LayoutModel then return end

lib.LayoutBuilder = lib.LayoutBuilder or {}
local LayoutBuilder = lib.LayoutBuilder
LayoutBuilder.__index = LayoutBuilder

-------------------------------------------------------------------------------
-- 2. BUILDER WRAPPER & ACTIVE TARGET RESOLUTION
-------------------------------------------------------------------------------

--- Creates a standalone LayoutBuilder facade wrapping a Context and LayoutModel.
--- @param uiContext table The active UI Context.
--- @param layout table The underlying pure LayoutModel instance.
--- @return table builder
function LayoutBuilder:new(uiContext, layout)
    local obj = {
        uiContext = uiContext,
        layout = layout,
    }
    return setmetatable(obj, LayoutBuilder)
end

--- Resolves the currently active LayoutModel (column/section sub-layout or self).
--- @return table activeLayout
function LayoutModel:getActiveLayout()
    return self._activeSubLayout or self
end

-- Route addSpace and addIndent to the active sub-layout when inside a column/section
local origAddSpace = LayoutModel.addSpace
function LayoutModel:addSpace(amount)
    local target = self._activeSubLayout or self
    if target ~= self then
        return target:addSpace(amount)
    end
    return origAddSpace(self, amount)
end

local origAddIndent = LayoutModel.addIndent
function LayoutModel:addIndent(amount)
    local target = self._activeSubLayout or self
    if target ~= self then
        return target:addIndent(amount)
    end
    return origAddIndent(self, amount)
end

-- Internal helper to anchor an element into activeLayout with fluid responsive support
local function registerFluidTextResize(activeLayout, elem, rightPad)
    if not elem then return end
    local function applyWidthAndSync(target)
        local currentAvail = activeLayout:getAvailableWidth(rightPad, target)
        if currentAvail <= 0 then return end
        if target._lastFluidWidth and math.abs(currentAvail - target._lastFluidWidth) <= 0.5 then
            return
        end
        target._lastFluidWidth = currentAvail
        if target.SetWidth then
            target:SetWidth(currentAvail)
        end
        if target.updateHeight then
            target:updateHeight()
        else
            local h = (target.GetStringHeight and target:GetStringHeight()) or (target.GetHeight and target:GetHeight()) or 0
            if h > 0 then
                activeLayout:onChildResized(target, h)
            end
        end
    end
    applyWidthAndSync(elem)
    activeLayout:registerResponsiveElement(elem, function(target)
        applyWidthAndSync(target)
    end)
end

-------------------------------------------------------------------------------
-- 3. COMPONENT CONVENIENCE WRAPPERS (PROPOSAL 1.D)
-------------------------------------------------------------------------------

function LayoutModel:header(elementID, text, options)
    if not self.uiContext or not self.uiContext.createHeader then return nil end
    local active = self:getActiveLayout()

    local opts = {
        parent = active.currentParent,
        name = elementID,
        text = text,
    }
    if type(options) == "table" then
        for k, v in pairs(options) do opts[k] = v end
    elseif type(options) == "number" then
        opts.rightOffset = options
    end

    local isFluid = opts.wordWrap or opts.elasticWidth or opts.rightOffset or (active.isResponsive and opts.wordWrap ~= false and not opts.width)
    if isFluid then
        opts.elasticWidth = true
        opts.wordWrap = (opts.wordWrap ~= false)
    end

    opts._autoAnchored = true
    local headerElement = self.uiContext:createHeader(opts)
    active.nextVerticalGap = active.nextVerticalGap or 15
    active:add(headerElement, opts)

    if isFluid and headerElement then
        local rightPad = math.abs(opts.rightOffset or active.defaultVerticalGap or 10)
        registerFluidTextResize(active, headerElement, rightPad)
    end

    return headerElement
end

function LayoutModel:label(elementID, text, options)
    if not self.uiContext or not self.uiContext.createLabel then return nil end
    local active = self:getActiveLayout()

    local opts = {
        parent = active.currentParent,
        name = elementID,
        text = text,
    }
    if type(options) == "table" then
        for k, v in pairs(options) do opts[k] = v end
    elseif type(options) == "number" then
        opts.rightOffset = options
    end

    local isFluid = opts.wordWrap or opts.elasticWidth or opts.rightOffset or (active.isResponsive and opts.wordWrap ~= false and not opts.width)
    if isFluid then
        opts.elasticWidth = true
        opts.wordWrap = (opts.wordWrap ~= false)
    end

    opts._autoAnchored = true
    local labelElement = self.uiContext:createLabel(opts)
    active:add(labelElement, opts)

    if isFluid and labelElement then
        local rightPad = math.abs(opts.rightOffset or active.defaultVerticalGap or 10)
        registerFluidTextResize(active, labelElement, rightPad)
    end

    return labelElement
end

function LayoutModel:paragraph(elementID, textOrOptions, rightOffset)
    if not self.uiContext or not self.uiContext.createParagraph then return nil end
    local active = self:getActiveLayout()

    local opts = {
        parent = active.currentParent,
        name = elementID,
    }
    if type(textOrOptions) == "table" then
        for k, v in pairs(textOrOptions) do opts[k] = v end
    else
        opts.text = textOrOptions
        opts.rightOffset = rightOffset
    end

    opts._autoAnchored = true
    opts.fluidWidth = (not opts.width) and (opts.wordWrap ~= false)
    local paragraphElement = self.uiContext:createParagraph(opts)
    active:add(paragraphElement, opts)

    local rightPad = math.abs(opts.rightOffset or active.defaultVerticalGap or 10)
    registerFluidTextResize(active, paragraphElement, rightPad)

    return paragraphElement
end

function LayoutModel:button(elementID, textOrOptions, tooltip, width, height, onClick)
    if not self.uiContext or not self.uiContext.createButton then return nil end
    local active = self:getActiveLayout()

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

    opts.parent = active.currentParent
    opts.name = elementID
    if opts.tooltip == nil then opts.tooltip = false end

    local isFluid = opts.fluidWidth or opts.fluid or (active.isResponsive and not opts.width and opts.fluidWidth ~= false)
    if isFluid then
        opts.fluidWidth = true
        opts.width = opts.width or active:getAvailableWidth(math.abs(opts.rightOffset or active.defaultVerticalGap or 10))
        if opts.width <= 0 then opts.width = 100 end
    end

    opts._autoAnchored = true
    local buttonElement
    if opts.variant and self.uiContext.createDialogButton then
        buttonElement = self.uiContext:createDialogButton(opts)
    else
        buttonElement = self.uiContext:createButton(opts)
    end
    active.nextVerticalGap = active.nextVerticalGap or 0
    active:add(buttonElement, opts)

    return buttonElement
end

function LayoutModel:toggle(elementID, getterOrOptions, setter, width, height, onClick)
    if not self.uiContext or not self.uiContext.createToggle then return nil end
    local active = self:getActiveLayout()

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

    opts.parent = active.currentParent
    opts.name = elementID
    if opts.tooltip == nil then opts.tooltip = false end

    local isFluid = opts.flexRow or (active.isResponsive and opts.width == nil and opts.flexRow ~= false)
    if isFluid then
        opts.flexRow = true
    end

    opts._autoAnchored = true
    local toggleElement = self.uiContext:createToggle(opts)
    if isFluid and toggleElement then
        toggleElement.fluidWidth = true
        toggleElement.fluidRightOffset = opts.rightOffset or active.defaultVerticalGap or 10
    end
    active:add(toggleElement, opts)

    return toggleElement
end

function LayoutModel:checkbox(elementID, textOrOptions, getter, setter, size, onClick)
    if not self.uiContext or not self.uiContext.createCheckbox then return nil end
    local active = self:getActiveLayout()

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

    opts.parent = active.currentParent
    opts.name = elementID
    if opts.tooltip == nil then opts.tooltip = false end

    local isFluid = opts.flexRow or (active.isResponsive and opts.width == nil and opts.flexRow ~= false)
    if isFluid then
        opts.flexRow = true
    end

    opts._autoAnchored = true
    local checkboxElement = self.uiContext:createCheckbox(opts)
    if isFluid and checkboxElement then
        checkboxElement.fluidWidth = true
        checkboxElement.fluidRightOffset = opts.rightOffset or active.defaultVerticalGap or 10
    end
    active:add(checkboxElement, opts)

    return checkboxElement
end

function LayoutModel:colorPicker(elementID, textOrOptions, tooltip, getter, setter, hasAlpha, options)
    if not self.uiContext or not self.uiContext.createColorPicker then return nil end
    local active = self:getActiveLayout()

    local opts = {}
    if type(textOrOptions) == "table" then
        for k, v in pairs(textOrOptions) do opts[k] = v end
    else
        if tooltip ~= nil and type(tooltip) == "function" then
            options, hasAlpha, setter, getter, tooltip = hasAlpha, setter, getter, tooltip, false
        end
        if options and type(options) == "table" then
            for k, v in pairs(options) do opts[k] = v end
        end
        opts.text = textOrOptions
        if tooltip ~= nil then
            opts.tooltip = tooltip
        elseif opts.tooltip == nil then
            opts.tooltip = false
        end
        opts.getter = getter or opts.getter
        opts.setter = setter or opts.setter
        if hasAlpha ~= nil then
            opts.hasAlpha = hasAlpha
        end
    end

    if opts.tooltip == nil then opts.tooltip = false end
    opts.parent = active.currentParent
    opts.name = elementID

    local isFluid = opts.flexRow or (active.isResponsive and opts.width == nil and opts.flexRow ~= false)
    if isFluid then
        opts.flexRow = true
    end

    opts._autoAnchored = true
    local colorPickerElement = self.uiContext:createColorPicker(opts)
    if isFluid and colorPickerElement then
        colorPickerElement.fluidWidth = true
        colorPickerElement.fluidRightOffset = opts.rightOffset or active.defaultVerticalGap or 10
    end
    active:add(colorPickerElement, opts)

    return colorPickerElement
end

function LayoutModel:slider(elementID, textOrOptions, minValue, maxValue, step, getter, setter, options)
    if not self.uiContext or not self.uiContext.createSlider then return nil end
    local active = self:getActiveLayout()

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

    if opts.tooltip == nil then opts.tooltip = false end
    opts.parent = active.currentParent
    opts.name = elementID
    opts.orientation = opts.orientation or "HORIZONTAL"

    local isFluid = opts.fluidWidth or opts.fluid or (active.isResponsive and not opts.length and not opts.width and opts.fluidWidth ~= false)
    if isFluid then
        opts.fluidWidth = true
        opts.length = opts.length or opts.width or active:getAvailableWidth(math.abs(opts.rightOffset or 16))
        if opts.length <= 0 then opts.length = 200 end
    else
        opts.length = opts.length or opts.width or active.currentWidth or 200
    end

    if opts.text and opts.text ~= "" then
        self:label(elementID .. "_Label", opts.text, { wordWrap = true, elasticWidth = true })
    end

    opts._autoAnchored = true
    local sliderElement = self.uiContext:createSlider(opts)
    if isFluid and sliderElement then
        sliderElement.fluidWidth = true
        sliderElement.fluidRightOffset = opts.rightOffset or 16
    end
    active:add(sliderElement, opts)

    return sliderElement
end

local function attachStepperBelowSlider(active, sliderElement, stepperElement, opts)
    if not stepperElement or not sliderElement then return end
    local stepperGap = (opts and opts.stepperGap) or 4
    stepperElement:ClearAllPoints()
    stepperElement:SetPoint("TOPLEFT", sliderElement, "BOTTOMLEFT", 0, -stepperGap)
    stepperElement:SetPoint("TOPRIGHT", sliderElement, "BOTTOMRIGHT", 0, -stepperGap)

    local sliderH = (sliderElement.GetHeight and sliderElement:GetHeight()) or 16
    local stepperH = (stepperElement.GetHeight and stepperElement:GetHeight()) or 24
    local idx = active.elementIndexMap[sliderElement]
    if idx and active.elements[idx] then
        active.elements[idx].height = sliderH + stepperGap + stepperH
        active.elements[idx].bottomAnchor = stepperElement
    end
    active.lastAddedElement = stepperElement
    active:recalculateAccumulatedHeight()
end

function LayoutModel:sliderWithStepper(elementID, textOrOptions, minValue, maxValue, step, getter, setter, options)
    if not self.uiContext or not self.uiContext.createSliderWithStepper then return nil end
    local active = self:getActiveLayout()

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

    if opts.tooltip == nil then opts.tooltip = false end
    opts.parent = active.currentParent
    opts.name = elementID

    local isFluid = opts.fluidWidth or opts.fluid or (active.isResponsive and not opts.length and not opts.width and opts.fluidWidth ~= false)
    if isFluid then
        opts.fluidWidth = true
        opts.length = opts.length or opts.width or active:getAvailableWidth(math.abs(opts.rightOffset or 16))
        if opts.length <= 0 then opts.length = 200 end
    else
        opts.length = opts.length or opts.width or active.currentWidth or 200
    end

    if opts.text and opts.text ~= "" then
        self:label(elementID .. "_Label", opts.text, { wordWrap = true, elasticWidth = true })
    end

    opts._autoAnchored = true
    local sliderElement, stepperElement = self.uiContext:createSliderWithStepper(opts)
    if isFluid and sliderElement then
        sliderElement.fluidWidth = true
        sliderElement.fluidRightOffset = opts.rightOffset or 16
    end
    active:add(sliderElement, opts)
    attachStepperBelowSlider(active, sliderElement, stepperElement, opts)

    return sliderElement, stepperElement
end

function LayoutModel:stepper(elementID, textOrOptions, minValue, maxValue, step, getter, setter, options)
    if not self.uiContext or not self.uiContext.createStepper then return nil end
    local active = self:getActiveLayout()

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

    opts.parent = active.currentParent
    opts.name = elementID
    if opts.tooltip == nil then opts.tooltip = false end

    local isFluid = opts.fluidWidth or opts.fluid or (active.isResponsive and not opts.width and opts.fluidWidth ~= false)
    if isFluid then
        opts.fluidWidth = true
        opts.width = opts.width or active:getAvailableWidth(math.abs(opts.rightOffset or 16))
        if opts.width <= 0 then opts.width = 160 end
    else
        opts.width = opts.width or active.currentWidth or 160
    end
    opts.height = opts.height or 26

    if opts.text and opts.text ~= "" then
        self:label(elementID .. "_Label", opts.text, { wordWrap = true, elasticWidth = true })
    end

    opts._autoAnchored = true
    local stepperElement = self.uiContext:createStepper(opts)
    if isFluid and stepperElement then
        stepperElement.fluidWidth = true
        stepperElement.fluidRightOffset = opts.rightOffset or 16
    end
    active:add(stepperElement, opts)

    return stepperElement
end

function LayoutModel:inputField(elementID, textOrOptions, width, height, options)
    if not self.uiContext or not self.uiContext.createInputField then return nil end
    local active = self:getActiveLayout()

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

    opts.parent = active.currentParent
    opts.name = elementID
    if opts.tooltip == nil then opts.tooltip = false end

    local isFluid = opts.fluidWidth or opts.fluid or (active.isResponsive and not opts.width and opts.fluidWidth ~= false)
    if isFluid then
        opts.fluidWidth = true
        opts.width = opts.width or active:getAvailableWidth(math.abs(opts.rightOffset or 16))
        if opts.width <= 0 then opts.width = 200 end
    else
        opts.width = opts.width or active.currentWidth or 200
    end
    opts.height = opts.height or 28

    if opts.label and opts.label ~= "" then
        self:label(elementID .. "_Label", opts.label, { wordWrap = true, elasticWidth = true })
    end

    opts._autoAnchored = true
    local inputElement = self.uiContext:createInputField(opts)
    if isFluid and inputElement then
        inputElement.fluidWidth = true
        inputElement.fluidRightOffset = opts.rightOffset or 16
    end
    active:add(inputElement, opts)

    return inputElement
end
LayoutModel.input = LayoutModel.inputField

function LayoutModel:dropdown(elementID, textOrOptions, optionsList, getter, setter, options)
    if not self.uiContext or not self.uiContext.createDropdown then return nil end
    local active = self:getActiveLayout()

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

    opts.parent = active.currentParent
    opts.name = elementID
    if opts.tooltip == nil then opts.tooltip = false end

    local isFluid = opts.fluidWidth or opts.fluid or (active.isResponsive and not opts.width and opts.fluidWidth ~= false)
    if isFluid then
        opts.fluidWidth = true
        opts.width = opts.width or active:getAvailableWidth(math.abs(opts.rightOffset or 16))
        if opts.width <= 0 then opts.width = 160 end
    else
        opts.width = opts.width or active.currentWidth or 160
    end
    opts.height = opts.height or 26

    if opts.text and opts.text ~= "" then
        self:label(elementID .. "_Label", opts.text, { wordWrap = true, elasticWidth = true })
    end

    opts._autoAnchored = true
    local dropdownElement = self.uiContext:createDropdown(opts)
    if isFluid and dropdownElement then
        dropdownElement.fluidWidth = true
        dropdownElement.fluidRightOffset = opts.rightOffset or 16
    end
    active:add(dropdownElement, opts)

    return dropdownElement
end

function LayoutModel:accordion(elementID, textOrOptions, populateFn, options)
    if not self.uiContext or not self.uiContext.createAccordion then return nil end
    local active = self:getActiveLayout()

    local opts = {}
    if type(textOrOptions) == "table" then
        for k, v in pairs(textOrOptions) do opts[k] = v end
    else
        if options and type(options) == "table" then
            for k, v in pairs(options) do opts[k] = v end
        end
        opts.title = textOrOptions
        opts.populate = populateFn or opts.populate
    end

    opts.parent = active.currentParent
    opts.name = elementID
    if opts.tooltip == nil then opts.tooltip = false end

    local isFluid = opts.fluidWidth or opts.fluid or (active.isResponsive and not opts.width and opts.fluidWidth ~= false)
    if isFluid then
        opts.fluidWidth = true
        opts.width = opts.width or active:getAvailableWidth(math.abs(opts.rightOffset or active.defaultVerticalGap or 10))
        if opts.width <= 0 then opts.width = 300 end
    else
        opts.width = opts.width or active.currentWidth or 300
    end

    opts._autoAnchored = true
    local accordionElement = self.uiContext:createAccordion(opts)
    if isFluid and accordionElement then
        accordionElement.fluidWidth = true
        accordionElement.fluidRightOffset = opts.rightOffset or active.defaultVerticalGap or 10
    end
    active:add(accordionElement, opts)

    local userToggle = opts.onToggle
    accordionElement.onToggle = function(isExpanded, acc)
        if userToggle then
            userToggle(isExpanded, acc)
        end
        active:updateScrollRangeIfAvailable()
    end

    return accordionElement
end

-------------------------------------------------------------------------------
-- 4. DECLARATIVE ATOMIC ROW (PROPOSAL 3.D) & LEGACY ADAPTERS
-------------------------------------------------------------------------------

--- Builds an autonomous multi-column row atomically without mutating layout state.
--- @param options table Configuration ({ gap, threshold, bottomPadding, rightOffset, columns = { { width, populate }, ... } }).
--- @return table|nil columnGroup
function LayoutModel:row(options)
    if not self.uiContext or not self.uiContext.createColumnGroup then return nil end
    options = options or {}
    local active = self:getActiveLayout()

    local group = self.uiContext:createColumnGroup({
        name = options.name,
        parent = active.currentParent,
        gap = options.gap or active.defaultVerticalGap,
        threshold = options.threshold or active.responsiveThreshold,
        bottomPadding = options.bottomPadding or 0,
        xOffset = options.xOffset,
        rightOffset = options.rightOffset or 0,
        fluidWidth = (options.fluidWidth ~= false),
        columns = options.columns,
        layout = active,
    })

    return group
end

--- Legacy adapter: begins a column inside an implicit ColumnGroup using an isolated sub-layout.
--- @param xOffsetOrOptions number|table|nil Horizontal indent or column options table.
--- @param width number|nil Column width (proportion <= 1 or pixels > 1).
function LayoutModel:beginColumn(xOffsetOrOptions, width)
    if not self.uiContext or not self.uiContext.createColumnGroup then return end

    if not self._activeColumnGroup then
        self._activeColumnGroup = self.uiContext:createColumnGroup({
            parent = self.currentParent,
            gap = self.defaultVerticalGap,
            threshold = self.responsiveThreshold,
            layout = self,
        })
    end

    local opts = {}
    if type(xOffsetOrOptions) == "table" then
        for k, v in pairs(xOffsetOrOptions) do opts[k] = v end
    else
        opts.xOffset = xOffsetOrOptions
        opts.width = width
    end

    local colLayout, colFrame, colData = self._activeColumnGroup:addColumn(opts)
    self._activeSubLayout = colLayout
    self._activeColData = colData
end

--- Legacy adapter: finalizes the active column sub-layout.
function LayoutModel:endColumn()
    if self._activeSubLayout then
        local h = self._activeSubLayout:recalculateAccumulatedHeight()
        if self._activeColData then
            self._activeColData.height = math.max(10, h or 10)
            self._activeColData.frame:SetHeight(self._activeColData.height)
        end
        self._activeSubLayout = nil
        self._activeColData = nil
    end
    if self._activeColumnGroup then
        self._activeColumnGroup:updateLayout()
    end
end

--- Legacy adapter: finalizes the active ColumnGroup and optionally resizes contentFrame.
--- @param contentFrame table|nil Optional master frame to size.
--- @param bottomPadding number|nil Optional bottom padding.
function LayoutModel:columnsFinalize(contentFrame, bottomPadding)
    if self._activeSubLayout then
        self:endColumn()
    end

    if self._activeColumnGroup then
        self._activeColumnGroup.bottomPadding = bottomPadding or 0
        self._activeColumnGroup:updateLayout()
        self._activeColumnGroup = nil
    end

    local totalH = self:recalculateAccumulatedHeight()
    local pad = bottomPadding or self.defaultVerticalGap or 10
    if contentFrame and contentFrame.SetHeight then
        contentFrame:SetHeight(math.max(10, totalH + pad))
    end
    self:updateScrollRangeIfAvailable()
end

-------------------------------------------------------------------------------
-- 5. SECTION MANAGEMENT (ISOLATED SUB-LAYOUT STACK)
-------------------------------------------------------------------------------

--- Begins a bordered section card using an isolated sub-layout instead of mutating parent state.
--- @param width number|nil Optional fixed width for the section frame.
function LayoutModel:beginSection(width)
    local active = self:getActiveLayout()
    local section = self.uiContext:acquireElement("Frame", active.currentParent, {})
    section:SetHeight(10)

    if width then
        section:SetWidth(width)
    else
        section.fluidWidth = true
        section.fluidRightOffset = 8
    end

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

    active.nextXOffset = active.nextXOffset or 8
    active:add(section)

    local sectionLayout = self.uiContext:createLayoutModel(section, {
        verticalGap = active.defaultVerticalGap,
        responsive = false,
        onContainerResized = function(_, newH)
            local totalH = math.max(20, (newH or 10) + 10)
            section:SetHeight(totalH)
            active:onChildResized(section, totalH)
        end,
    })

    self._sectionStack = self._sectionStack or {}
    table.insert(self._sectionStack, {
        section = section,
        previousSubLayout = self._activeSubLayout,
        sectionLayout = sectionLayout,
    })
    self._activeSubLayout = sectionLayout
end

--- Finalizes the current section card and pops back to the enclosing layout.
function LayoutModel:endSection()
    if not self._sectionStack or #self._sectionStack == 0 then return end
    local entry = table.remove(self._sectionStack)
    local sectionLayout = entry.sectionLayout
    local section = entry.section

    local h = math.max(20, (sectionLayout:recalculateAccumulatedHeight() or 10) + 10)
    section:SetHeight(h)

    self._activeSubLayout = entry.previousSubLayout
    local parentLayout = self:getActiveLayout()
    parentLayout:onChildResized(section, h)
end

-- Forward builder methods onto LayoutBuilder instances
for k, v in pairs(LayoutModel) do
    if type(v) == "function" and not LayoutBuilder[k] then
        LayoutBuilder[k] = function(selfBuilder, ...)
            return v(selfBuilder.layout, ...)
        end
    end
end

-------------------------------------------------------------------------------
-- 6. CENTRALIZED CONTEXT AUTO-ANCHOR INTERCEPTOR (PROPOSAL 1.D)
-------------------------------------------------------------------------------

if Context then
    Context._autoAnchorWrapped = Context._autoAnchorWrapped or {}

    local function wrapFactoryForAutoAnchor(methodName, isSliderWithStepper)
        if Context._autoAnchorWrapped[methodName] then return end
        local origFn = Context[methodName]
        if type(origFn) ~= "function" then return end

        Context._autoAnchorWrapped[methodName] = true
        Context[methodName] = function(ctxSelf, options, ...)
            local r1, r2, r3 = origFn(ctxSelf, options, ...)
            if r1 and type(options) == "table" and options.layout and not options._autoAnchored then
                options._autoAnchored = true
                ctxSelf:registerCreatedElement(r1, options)
                if isSliderWithStepper and r2 then
                    attachStepperBelowSlider(options.layout, r1, r2, options)
                end
            end
            return r1, r2, r3
        end
    end

    local standardFactories = {
        "createHeader",
        "createLabel",
        "createParagraph",
        "createButton",
        "createIconButton",
        "createDialogButton",
        "createDialogButtonGroup",
        "createToggle",
        "createCheckbox",
        "createInputField",
        "createSlider",
        "createStepper",
        "createDropdown",
        "createColorPicker",
        "createAccordion",
        "createColumnGroup",
    }

    for _, fnName in ipairs(standardFactories) do
        wrapFactoryForAutoAnchor(fnName, false)
    end
    wrapFactoryForAutoAnchor("createSliderWithStepper", true)
end
