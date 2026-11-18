-------------------------------------------------------------------------------
-- Project: AscensionFactory
-- Author: Aka-DoctorCode
-- File: Scrollable.lua
-------------------------------------------------------------------------------
---@diagnostic disable: undefined-global, undefined-field, inject-field

-------------------------------------------------------------------------------
-- 1. INITIALIZATION
-- Objective: Initialize UX namespace and link to global AscensionFactory library.
-- Variables:
-- MAJOR (string): Namespace identifier for addon library.
-- lib (table): Global AscensionFactory library object.
-- UX (table): Namespace table for UX helper functions.
-------------------------------------------------------------------------------
local MAJOR = "AscensionFactory"
local lib = LibStub:GetLibrary(MAJOR)
if not lib then return end

local UX = lib.UX or {}
lib.UX = UX

-------------------------------------------------------------------------------
-- 2. SCROLLABLE CAPABILITY FACTORY
-- Objective: Make any container frame scrollable with an internal ScrollFrame,
-- an expandable content container, and a vertical scrollbar reusing 09Slider.
-- Variables:
-- container (table): Frame to make scrollable.
-- options (table): Configuration (scrollBarWidth, scrollBarGap, step, autoHideScrollBar).
-- scrollFrame (table): Native ScrollFrame managing the viewport.
-- contentChild (table): Container holding scrollable child elements.
-- scrollbar (table): 09Slider vertical instance acting as scrollbar.
-------------------------------------------------------------------------------

--- Converts any frame into a scrollable viewport container with an integrated 09Slider scrollbar.
--- @param container table The host frame to make scrollable.
--- @param options table|nil Optional layout and interaction settings.
--- @return table scrollFrame Native scroll viewport.
--- @return table contentChild Expandable child container for content widgets.
--- @return table scrollbar Vertical 09Slider instance.
function UX:makeScrollable(container, options)
    if not container then return nil, nil, nil end
    options = options or {}

    local uiContext = options.uiContext or container.uiContext or lib.Context
    if not uiContext or not uiContext.createSlider then
        error("AscensionFactory: UX:makeScrollable requires an active UI Context with createSlider", 2)
    end

    local scrollBarWidth = options.scrollBarWidth or 12
    local scrollBarGap = options.scrollBarGap or 4
    local stepSize = options.step or options.stepSize or 32
    local bottomPadding = options.bottomPadding or 16
    local autoHideScrollBar = options.autoHideScrollBar ~= false
    local contentPaddingLeft = options.contentPaddingLeft or 0

    -- 2.1 SCROLLFRAME (VIEWPORT)
    local scrollFrame = CreateFrame("ScrollFrame", nil, container)
    scrollFrame:SetPoint("TOPLEFT", container, "TOPLEFT", contentPaddingLeft, 0)
    scrollFrame:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", -(scrollBarWidth + scrollBarGap), 0)
    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetClipsChildren(true)

    -- 2.2 CONTENT CHILD
    local contentChild = CreateFrame("Frame", nil, scrollFrame)
    local initW = math.max(10, scrollFrame:GetWidth())
    contentChild:SetSize(initW, 1)
    scrollFrame:SetScrollChild(contentChild)

    -- 2.3 VERTICAL SCROLLBAR (09SLIDER REUSE)
    local initialLength = math.max(20, container:GetHeight())
    local scrollbar = uiContext:createSlider({
        name = (container:GetName() or "ScrollContainer") .. "ScrollBar",
        parent = container,
        orientation = "VERTICAL",
        tooltip = false,
        length = initialLength,
        thickness = scrollBarWidth,
        thumbShape = options.thumbShape or "capsule",
        thumbThickness = scrollBarWidth - 2,
        minValue = 0,
        maxValue = 100,
        step = 1,
        showFill = false,
        point = "TOPRIGHT",
        relativeTo = container,
        relativePoint = "TOPRIGHT",
        xOffset = 0,
        yOffset = 0,
        onValueChanged = function(slider, value, isUserInput)
            scrollFrame:SetVerticalScroll(value)
        end
    })
    scrollbar:ClearAllPoints()
    scrollbar:SetPoint("TOPRIGHT", container, "TOPRIGHT", 0, 0)
    scrollbar:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", 0, 0)

    -- 2.4 DYNAMIC RANGE CALCULATION
    local function calculateContentHeight()
        if contentChild.layoutAccumulatedHeight and contentChild.layoutAccumulatedHeight > 0 then
            return contentChild.layoutAccumulatedHeight + bottomPadding
        end

        local maxBottom = 0
        local top = contentChild:GetTop()

        -- Measure lowest descendant position recursively relative to content top
        if top then
            local function measureFrame(frame)
                if not frame or not frame.IsShown or not frame:IsShown() then return end
                if frame ~= contentChild and frame.GetBottom then
                    local b = frame:GetBottom()
                    if b and b > 0 then
                        local diff = top - b
                        if diff > maxBottom then
                            maxBottom = diff
                        end
                    end
                end
                if frame.GetChildren then
                    for _, child in ipairs({ frame:GetChildren() }) do
                        measureFrame(child)
                    end
                end
            end
            measureFrame(contentChild)
        end

        if maxBottom > 0 then
            return maxBottom + bottomPadding
        end

        -- Fallback when frame is not yet fully laid out or off-screen
        local explicitH = contentChild:GetHeight() or 0
        return explicitH
    end

    local function updateScrollRange()
        local viewHeight = scrollFrame:GetHeight() or 0
        if viewHeight <= 0 then
            viewHeight = container:GetHeight() or 0
        end
        if viewHeight <= 0 then return end

        local contentHeight = calculateContentHeight()
        local maxScroll = math.max(0, contentHeight - viewHeight)

        if scrollbar.setMinMaxValues then
            scrollbar:setMinMaxValues(0, maxScroll)
        elseif scrollbar.SetMinMaxValues then
            scrollbar:SetMinMaxValues(0, maxScroll)
        end

        -- Adjust thumb size proportionally to viewport ratio
        if contentHeight > 0 and viewHeight > 0 and scrollbar.setThumbSize then
            local ratio = math.min(1, viewHeight / contentHeight)
            local thumbSize = math.max(20, math.floor(viewHeight * ratio))
            scrollbar:setThumbSize(thumbSize, scrollBarWidth - 2)
        end

        if maxScroll <= 0 then
            if autoHideScrollBar then
                scrollbar:Hide()
            else
                scrollbar:Show()
                if scrollbar.disable then
                    scrollbar:disable()
                elseif scrollbar.setEnabled then
                    scrollbar:setEnabled(false)
                elseif scrollbar.SetEnabled then
                    scrollbar:SetEnabled(false)
                end
            end
            if scrollbar.setValue then
                scrollbar:setValue(0, true)
            elseif scrollbar.SetValue then
                scrollbar:SetValue(0, true)
            end
            scrollFrame:SetVerticalScroll(0)
        else
            scrollbar:Show()
            if scrollbar.enable then
                scrollbar:enable()
            elseif scrollbar.setEnabled then
                scrollbar:setEnabled(true)
            elseif scrollbar.SetEnabled then
                scrollbar:SetEnabled(true)
            end
            -- Clamp current scroll
            local current = (scrollbar.getValue and scrollbar:getValue()) or (scrollbar.GetValue and scrollbar:GetValue()) or 0
            if current > maxScroll then
                if scrollbar.setValue then
                    scrollbar:setValue(maxScroll, false)
                elseif scrollbar.SetValue then
                    scrollbar:SetValue(maxScroll, false)
                end
            end
        end
    end

    -- 2.5 EVENT HANDLERS
    scrollFrame:SetScript("OnSizeChanged", function(self, w, h)
        if w and w > 0 then
            contentChild:SetWidth(w)
        end
        updateScrollRange()
    end)

    container:SetScript("OnSizeChanged", function(self, w, h)
        updateScrollRange()
    end)

    local function onMouseWheel(delta)
        if not scrollbar or not scrollbar.getValue or not scrollbar.getMinMaxValues then return end
        local minVal, maxVal = scrollbar:getMinMaxValues()
        if maxVal <= 0 then return end
        local multiplier = (IsShiftKeyDown and IsShiftKeyDown()) and 3 or 1
        local current = scrollbar:getValue()
        local target = current - (delta * stepSize * multiplier)
        target = math.max(minVal, math.min(maxVal, target))
        scrollbar:setValue(target, false, true)
    end

    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        onMouseWheel(delta)
    end)
    container:EnableMouseWheel(true)
    container:SetScript("OnMouseWheel", function(self, delta)
        onMouseWheel(delta)
    end)

    local function scrollToTop()
        if scrollbar.setValue then
            scrollbar:setValue(0, false, true)
        elseif scrollbar.SetValue then
            scrollbar:SetValue(0)
        end
        scrollFrame:SetVerticalScroll(0)
    end

    local function scrollToBottom()
        updateScrollRange()
        local _, maxVal = 0, 0
        if scrollbar.getMinMaxValues then
            _, maxVal = scrollbar:getMinMaxValues()
        elseif scrollbar.GetMinMaxValues then
            _, maxVal = scrollbar:GetMinMaxValues()
        end
        maxVal = maxVal or 0
        if scrollbar.setValue then
            scrollbar:setValue(maxVal, false, true)
        elseif scrollbar.SetValue then
            scrollbar:SetValue(maxVal)
        end
        scrollFrame:SetVerticalScroll(maxVal)
    end

    local function onContentResized(selfOrHeight, maybeHeight)
        local newHeight = (type(selfOrHeight) == "number") and selfOrHeight or maybeHeight
        if type(newHeight) ~= "number" then return end
        contentChild.layoutAccumulatedHeight = newHeight
        contentChild:SetHeight(math.max(10, newHeight + bottomPadding))
        updateScrollRange()
    end

    -- Attach references and API to container, scrollFrame, and contentChild
    container.scrollFrame = scrollFrame
    container.content = contentChild
    container.contentChild = contentChild
    container.scrollbar = scrollbar
    container.updateScrollRange = updateScrollRange
    container.scrollToTop = scrollToTop
    container.scrollToBottom = scrollToBottom
    container.onContentResized = onContentResized

    scrollFrame.updateScrollRange = updateScrollRange
    contentChild.updateScrollRange = updateScrollRange
    contentChild.onContentResized = onContentResized

    -- Initial layout update on show
    container:HookScript("OnShow", function()
        updateScrollRange()
    end)

    return scrollFrame, contentChild, scrollbar
end

UX.MakeScrollable = UX.makeScrollable

-------------------------------------------------------------------------------
-- 3. EXTENSION & EXPANSION NOTES
-- Objective: Guidelines for horizontal scrolling, smooth easing animations, and pool recycling.
--
-- How to expand:
-- 1. Horizontal Scrolling:
--    Add `orientation = "HORIZONTAL"` in `options` to position a horizontal `09Slider` at the bottom
--    and connect `scrollFrame:SetHorizontalScroll(value)`.
-- 2. Smooth Scrolling:
--    Animate value transitions using a frame `OnUpdate` ticker instead of instant snapping.
-------------------------------------------------------------------------------
