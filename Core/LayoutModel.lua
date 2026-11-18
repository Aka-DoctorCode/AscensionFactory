-------------------------------------------------------------------------------
-- Project: AscensionFactory
-- Author: Aka-DoctorCode
-- File: LayoutModel.lua
-------------------------------------------------------------------------------
---@diagnostic disable: undefined-global, undefined-field, inject-field

-------------------------------------------------------------------------------
-- 1. INITIALIZATION
-- Objective: Initialize the LayoutModel namespace and link it to AscensionFactory.
-- LayoutModel is a pure relative anchoring and trifasic sizing engine.
-------------------------------------------------------------------------------
local MAJOR = "AscensionFactory"
local lib = LibStub:GetLibrary(MAJOR)
if not lib then return end
local Context = lib.Context

lib.LayoutModel = lib.LayoutModel or {}
lib.LayoutModel.__index = lib.LayoutModel

-------------------------------------------------------------------------------
-- 2. CONSTRUCTOR & LIFECYCLE
-------------------------------------------------------------------------------

local function resolveDefaultGap(uiContext, options)
    if options and (options.verticalGap or options.gap) then
        return options.verticalGap or options.gap
    end
    if uiContext and uiContext.getDefaultGap then
        return uiContext:getDefaultGap()
    end
    return 10
end

local function resolveTargetContainer(parent)
    if not parent then return nil end
    if parent.getContent then
        return parent:getContent()
    elseif parent.scrollChild then
        return parent.scrollChild
    elseif parent.content then
        return parent.content
    end
    return parent
end

--- Creates a new pure LayoutModel instance for relative stacking and sizing.
--- @param uiContext table|nil The active UI Context.
--- @param parent table|nil The parent container frame.
--- @param options table|number|nil Optional config table or startY number.
--- @return table layoutInstance
function lib.LayoutModel:new(uiContext, parent, options)
    if type(options) == "number" then
        options = { startY = options }
    else
        options = options or {}
    end

    local resolvedContext = uiContext or self.uiContext
    local defaultGap = resolveDefaultGap(resolvedContext, options)

    local layoutInstance = {
        uiContext = resolvedContext,
        parent = parent,
        currentParent = parent,
        scrollChild = nil,
        scrollFrame = nil,
        scrollbar = nil,
        defaultVerticalGap = defaultGap,
        bottomPadding = options.bottomPadding or defaultGap,
        startY = options.startY,
        nextVerticalGap = options.startY and math.abs(options.startY) or nil,
        nextXOffset = nil,
        lastAddedElement = nil,
        lastElementXOffset = 0,
        currentWidth = nil,
        elements = {},
        elementIndexMap = {},
        accumulatedHeight = 0,
        isUpdatingSize = false,
        onContainerResized = options.onContainerResized,
        parentLayout = options.parentLayout,
        ownerWidget = options.ownerWidget,
        responsiveMode = "normal",
        responsiveThreshold = options.threshold or 480,
        isResponsive = false,
        responsiveCoordinator = nil,
        responsiveElements = {},
    }
    setmetatable(layoutInstance, lib.LayoutModel)

    -- Delegate scrollable container setup exclusively to UX/Scrollable.lua if requested
    if (options.scrollable or options.autoScroll) and parent and not parent.updateScrollRange and lib.UX and lib.UX.makeScrollable then
        local scrollFrame, scrollChild, scrollbar = lib.UX:makeScrollable(parent, {
            uiContext = layoutInstance.uiContext,
            step = options.scrollStep or 30,
            thumbShape = "capsule",
            bottomPadding = layoutInstance.bottomPadding,
        })
        layoutInstance.currentParent = scrollChild
        layoutInstance.scrollChild = scrollChild
        layoutInstance.scrollFrame = scrollFrame
        layoutInstance.scrollbar = scrollbar
    elseif parent then
        layoutInstance.currentParent = resolveTargetContainer(parent)
        layoutInstance.scrollChild = parent.scrollChild or parent.content or nil
        layoutInstance.scrollFrame = parent.scrollFrame or nil
        layoutInstance.scrollbar = parent.scrollbar or nil
    end

    -- Delegate responsive observation exclusively to UX/Responsive.lua unless disabled
    if options.responsive ~= false and parent and parent.HookScript then
        layoutInstance:enableResponsive(options)
    end

    return layoutInstance
end

--- Resets the LayoutModel cursor and tracking state for reuse.
--- @param parent table|nil Optional new parent container.
--- @param options table|number|nil Optional new configuration.
--- @return table self
function lib.LayoutModel:reset(parent, options)
    if type(options) == "number" then
        options = { startY = options }
    else
        options = options or {}
    end

    local defaultGap = resolveDefaultGap(self.uiContext, options)

    self.parent = parent
    self.currentParent = resolveTargetContainer(parent)
    self.scrollChild = (parent and (parent.scrollChild or parent.content)) or nil
    self.scrollFrame = (parent and parent.scrollFrame) or nil
    self.scrollbar = (parent and parent.scrollbar) or nil
    self.defaultVerticalGap = defaultGap
    self.bottomPadding = options.bottomPadding or defaultGap
    self.startY = options.startY
    self.nextVerticalGap = options.startY and math.abs(options.startY) or nil
    self.nextXOffset = nil
    self.lastAddedElement = nil
    self.lastElementXOffset = 0
    self.currentWidth = nil
    self.elements = {}
    self.elementIndexMap = {}
    self.accumulatedHeight = 0
    self.isUpdatingSize = false
    self.onContainerResized = options.onContainerResized or self.onContainerResized
    self.parentLayout = options.parentLayout or self.parentLayout
    self.ownerWidget = options.ownerWidget or self.ownerWidget
    self.responsiveMode = "normal"
    self.responsiveThreshold = options.threshold or 480
    self.isResponsive = false
    self.responsiveElements = {}
    self._activeSubLayout = nil
    self._activeColData = nil
    self._activeColumnGroup = nil
    self._sectionStack = nil

    if options.responsive ~= false and parent and parent.HookScript then
        self:enableResponsive(options)
    end

    return self
end

-------------------------------------------------------------------------------
-- 3. ANCHOR ENGINE & TRIFASIC SIZING PIPELINE (2.D)
-------------------------------------------------------------------------------

--- Sets a one-time vertical gap (in pixels) before the next element placed.
--- @param amount number Vertical spacing in pixels.
function lib.LayoutModel:addSpace(amount)
    self.nextVerticalGap = amount
end

--- Sets a one-time horizontal indent (in pixels) for the next element placed.
--- @param amount number Horizontal offset in pixels.
function lib.LayoutModel:addIndent(amount)
    self.nextXOffset = amount
end

--- Computes the usable width inside the current active container frame.
--- @param padding number|nil Optional padding to subtract.
--- @param element table|nil Optional UI element for parent resolution.
--- @return number availableWidth
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

--- Anchors a UI element vertically below the previous element and updates the
--- trifasic height pipeline (Phase 1 math accumulation + Phase 2 deferred text check).
--- @param element table The UI frame or region to anchor.
--- @param options table|nil Optional overrides (xOffset, gap, fluidWidth, rightOffset, defaultHeight).
--- @return table|nil element
function lib.LayoutModel:add(element, options)
    if type(element) ~= "table" or not element.SetPoint then return nil end

    -- Prevent double-anchoring the exact same widget in the same layout
    if self.elementIndexMap[element] then
        return element
    end
    element._managedByLayout = true

    local xOffset = (options and options.xOffset) or self.nextXOffset or 0
    local verticalGap = (options and options.gap) or self.nextVerticalGap or self.defaultVerticalGap

    -- Consume one-time cursor overrides
    self.nextXOffset = nil
    self.nextVerticalGap = nil

    -- Native WoW relative anchoring (TOPLEFT -> BOTTOMLEFT)
    element:ClearAllPoints()
    if not self.lastAddedElement then
        element:SetPoint("TOPLEFT", self.currentParent, "TOPLEFT", xOffset, -verticalGap)
        self.lastElementXOffset = xOffset
    else
        local prevX = self.lastElementXOffset or 0
        local deltaX = xOffset - prevX
        element:SetPoint("TOPLEFT", self.lastAddedElement, "BOTTOMLEFT", deltaX, -verticalGap)
        self.lastElementXOffset = xOffset
    end

    -- Fluid width handling & responsive subscription
    local isFontString = element.GetStringHeight and (element.elementType == "FontString" or not element.GetChildren)
    local isFluid = element.fluidWidth or (options and (options.fluidWidth or (isFontString and (options.elasticWidth or options.rightOffset) and not options.width)))
    local storedRightPad = nil
    if isFluid then
        local rightPad = math.abs((options and options.rightOffset) or element.fluidRightOffset or self.defaultVerticalGap)
        storedRightPad = rightPad
        if isFontString and self.currentParent then
            element:SetPoint("RIGHT", self.currentParent, "RIGHT", -rightPad, 0)
        end
        local avail = self:getAvailableWidth(xOffset + rightPad, element)
        if avail > 0 and element.SetWidth then
            element:SetWidth(avail)
        end
        if element.updateLayout then
            element:updateLayout(avail)
        end
        self:registerResponsiveElement(element, function(elem)
            local currentAvail = self:getAvailableWidth(xOffset + rightPad, elem)
            if currentAvail > 0 and elem.SetWidth then
                elem:SetWidth(currentAvail)
            end
            if elem.updateLayout then
                elem:updateLayout(currentAvail)
            elseif elem.updateHeight then
                elem:updateHeight()
            end
        end)
    elseif element.clampToContainer and element.SetWidth and element.GetWidth then
        local baseWidth = element._baseWidth or element:GetWidth()
        if baseWidth and baseWidth > 0 then
            element._baseWidth = baseWidth
            local rightPad = math.abs((options and options.rightOffset) or element.fluidRightOffset or self.defaultVerticalGap)
            local avail = self:getAvailableWidth(xOffset + rightPad, element)
            if avail > 0 then
                element:SetWidth(math.min(baseWidth, avail))
            end
            self:registerResponsiveElement(element, function(elem)
                local currentAvail = self:getAvailableWidth(xOffset + rightPad, elem)
                if currentAvail > 0 and elem.SetWidth then
                    elem:SetWidth(math.min(baseWidth, currentAvail))
                end
            end)
        end
    end

    -- Phase 1 (Pattern C): Synchronous mathematical height tracking
    local elemH = (element.GetHeight and element:GetHeight()) or 0
    if (not elemH or elemH <= 0) and isFontString then
        elemH = element:GetStringHeight() or 0
    end
    if not elemH or elemH <= 0 then
        elemH = (options and options.defaultHeight) or 24
    end

    local idx = #self.elements + 1
    local entry = {
        element = element,
        xOffset = xOffset,
        gap = verticalGap,
        height = elemH,
        rightPad = storedRightPad,
        isFontString = isFontString and true or false,
    }
    self.elements[idx] = entry
    self.elementIndexMap[element] = idx
    self.lastAddedElement = element
    element._parentLayout = self

    self:recalculateAccumulatedHeight()

    -- Phase 2 (Pattern B): Deferred font-wrap height check for elastic FontStrings
    -- Keep SetHeight(0) intact so WoW never truncates wrapped text; only update layout math.
    if isFontString and C_Timer and C_Timer.After then
        local capturedLayout = self
        local capturedElem = element
        local capturedEntry = entry
        C_Timer.After(0, function()
            if not capturedElem.GetStringHeight then return end
            local realH = capturedElem:GetStringHeight()
            if realH and realH > 0 and math.abs(realH - capturedEntry.height) > 0.5 then
                capturedLayout:onChildResized(capturedElem, realH)
            end
        end)
    end

    return element
end

lib.LayoutModel.anchorElement = lib.LayoutModel.add
lib.LayoutModel.anchor = lib.LayoutModel.add

--- Recomputes total mathematical height of all tracked children + gaps (Phase 1)
--- and propagates to host container / Scrollable / onContainerResized.
--- @return number totalHeight
function lib.LayoutModel:recalculateAccumulatedHeight()
    local total = 0
    for _, item in ipairs(self.elements) do
        total = total + (item.gap or 0) + (item.height or 0)
    end
    self.accumulatedHeight = math.max(10, total)

    if self.currentParent then
        if self.currentParent.onContentResized then
            self.currentParent:onContentResized(self.accumulatedHeight)
        elseif self.currentParent == self.scrollChild and self.currentParent.SetHeight then
            self.currentParent.layoutAccumulatedHeight = self.accumulatedHeight
            self.currentParent:SetHeight(self.accumulatedHeight + self.bottomPadding)
            self:updateScrollRangeIfAvailable()
        end
    end

    if self.onContainerResized and not self.isUpdatingSize then
        self.isUpdatingSize = true
        self.onContainerResized(self, self.accumulatedHeight)
        self.isUpdatingSize = false
    end

    return self.accumulatedHeight
end

--- Phase 3 (Pattern A): Called by child widgets (e.g. Accordion, ColumnGroup, wrapped text)
--- when their height changes. Updates subsequent sibling anchors and bubbles upward.
--- @param childElement table The resized child widget.
--- @param newHeight number|nil Updated height in pixels.
function lib.LayoutModel:onChildResized(childElement, newHeight)
    if self.isUpdatingSize then return end

    local idx = childElement and self.elementIndexMap[childElement]
    local resolvedH = newHeight
    if (not resolvedH or resolvedH <= 0) and childElement then
        local isFS = childElement.GetStringHeight and (childElement.elementType == "FontString" or not childElement.GetChildren)
        resolvedH = (isFS and childElement:GetStringHeight()) or (childElement.GetHeight and childElement:GetHeight()) or 0
        if (not resolvedH or resolvedH <= 0) and isFS then
            resolvedH = (childElement.GetHeight and childElement:GetHeight()) or 0
        end
    end
    resolvedH = resolvedH or 0

    if idx then
        local entry = self.elements[idx]
        local clampedH = math.max(0, resolvedH)
        if entry.height and math.abs(clampedH - entry.height) <= 0.5 then
            return
        end
        entry.height = clampedH

        local nextEntry = self.elements[idx + 1]
        if nextEntry and nextEntry.element and nextEntry.element.SetPoint then
            local deltaX = (nextEntry.xOffset or 0) - (entry.xOffset or 0)
            local anchorTarget = entry.bottomAnchor or childElement
            nextEntry.element:ClearAllPoints()
            nextEntry.element:SetPoint("TOPLEFT", anchorTarget, "BOTTOMLEFT", deltaX, -(nextEntry.gap or self.defaultVerticalGap))
            if nextEntry.isFontString and nextEntry.rightPad and self.currentParent then
                nextEntry.element:SetPoint("RIGHT", self.currentParent, "RIGHT", -nextEntry.rightPad, 0)
            end
        end
    end

    self:recalculateAccumulatedHeight()
    self:updateScrollRangeIfAvailable()
end

-------------------------------------------------------------------------------
-- 4. DELEGATION BRIDGES (RESPONSIVE & SCROLLABLE)
-------------------------------------------------------------------------------

--- Delegates responsive container observation to UX/Responsive.lua.
--- @param options table|nil Responsive options (threshold, frame, onModeChange, debounce).
function lib.LayoutModel:enableResponsive(options)
    options = options or {}
    self.isResponsive = true
    self.responsiveThreshold = options.threshold or 480
    local targetFrame = options.frame or self.parent

    if lib.UX and lib.UX.makeResponsive and targetFrame then
        self.responsiveCoordinator = lib.UX:makeResponsive(targetFrame, {
            threshold = self.responsiveThreshold,
            debounce = options.debounce or 0.05,
            alwaysNotify = options.alwaysNotify,
            onModeChange = function(_, newMode, width, height)
                self.responsiveMode = newMode
                if options.onModeChange then
                    options.onModeChange(self, newMode, width, height)
                end
                self:updateScrollRangeIfAvailable()
            end,
        })
        if self.responsiveCoordinator then
            self.responsiveMode = self.responsiveCoordinator:getMode()
        end
    end
end

--- Registers an element with the active responsive coordinator.
--- @param element table The UI element to update on resize.
--- @param callback function Callback(element, mode, width, height).
function lib.LayoutModel:registerResponsiveElement(element, callback)
    if not element or not callback then return end
    if self.responsiveCoordinator then
        self.responsiveCoordinator:registerSubscriber(element, callback)
    else
        self.responsiveElements = self.responsiveElements or {}
        table.insert(self.responsiveElements, {
            element = element,
            callback = callback,
        })
        local w = (self.parent and self.parent.GetWidth and self.parent:GetWidth()) or 0
        local h = (self.parent and self.parent.GetHeight and self.parent:GetHeight()) or 0
        callback(element, self.responsiveMode or "normal", w, h)
    end
end

--- Notifies responsive subscribers of a mode or size transition.
--- @param newMode string "normal" or "compact"
--- @param width number Width in pixels
--- @param height number Height in pixels
function lib.LayoutModel:notifyResponsive(newMode, width, height)
    self.responsiveMode = newMode
    if self.responsiveCoordinator then
        self.responsiveCoordinator:notify(newMode, width, height)
    elseif self.responsiveElements then
        for _, item in ipairs(self.responsiveElements) do
            if item.callback and item.element then
                item.callback(item.element, newMode, width, height)
            end
        end
        self:updateScrollRangeIfAvailable()
    end
end

--- Requests scroll range recalculation if hosted inside a UX:makeScrollable container.
function lib.LayoutModel:updateScrollRangeIfAvailable()
    if self.currentParent and self.currentParent.updateScrollRange then
        self.currentParent:updateScrollRange()
        return
    end
    if self.parent and self.parent.updateScrollRange then
        self.parent:updateScrollRange()
        return
    end
end

-------------------------------------------------------------------------------
-- 5. CONTEXT EXTENSION
-------------------------------------------------------------------------------

if Context then
    --- Creates a LayoutModel instance bound to this UI Context.
    --- @param parent table The container frame.
    --- @param options table|number|nil Optional configuration table or startY.
    --- @return table|nil layoutInstance
    function Context:createLayoutModel(parent, options)
        if lib.LayoutModel then
            return lib.LayoutModel:new(self, parent, options)
        end
    end
end
