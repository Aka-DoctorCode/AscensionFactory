-------------------------------------------------------------------------------
-- Project: AscensionFactory
-- Author: Aka-DoctorCode
-- File: TwoColumnInterface.lua
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
-- 2. TWO COLUMN FACTORY
-- Objective: Creates a side-by-side split layout container for organizing UI elements.
-- Divides the parent width equally into a left and right frame.
-- Variables:
-- leftColumn (table): The created left-side frame container.
-- rightColumn (table): The created right-side frame container.
-- setBackground (function): Helper to optionally assign colored backgrounds to each column.
-------------------------------------------------------------------------------
function Context:createTwoColumns(options)
    options = options or {}
    local parent = options.parent or UIParent
    local yOffset = options.yOffset or 0
    local name = options.name or "TwoColumnLayout"
    local height = options.height
    local threshold = options.stackThreshold or options.threshold or 480
    local isResponsive = (options.responsive ~= false)
    local gap = options.gap or 10
    local halfGap = math.floor(gap / 2)

    -- Create the left side container frame and optionally name it.
    -- "Frame" is the basic empty UI container in WoW.
    -- parent: the frame this column belongs to.
    local leftColumn = self:acquireElement("Frame", parent, {})
    if name then _G[name .. "Left"] = leftColumn end
    
    -- Create the right side container frame and optionally name it.
    local rightColumn = self:acquireElement("Frame", parent, {})
    if name then _G[name .. "Right"] = rightColumn end

    -- Helper utility to conditionally create an inner background texture layer.
    local function setBackground(frame, color)
        -- Acquire a "Texture" object directly, rendering on the "BACKGROUND" layer.
        local background = self:acquireElement("Texture", frame, { drawLayer = "BACKGROUND" })
        background:SetAllPoints() -- Fill the column's entire area.
        if color then
            background:SetColorTexture(unpack(color))
        else
            background:SetColorTexture(0, 0, 0, 0)
        end
        frame.background = background
    end

    setBackground(leftColumn, options.leftBackgroundColor or options.backgroundColor)
    setBackground(rightColumn, options.rightBackgroundColor or options.backgroundColor)

    local isStacked = false

    local function getColumnContentHeight(frame)
        local top = frame:GetTop()
        local maxBottom = 0
        if top and frame.GetChildren then
            for _, child in ipairs({ frame:GetChildren() }) do
                if child:IsShown() and child.GetBottom then
                    local bottom = child:GetBottom()
                    if bottom then
                        local diff = top - bottom
                        if diff > maxBottom then
                            maxBottom = diff
                        end
                    end
                end
            end
        end
        return maxBottom
    end

    local function updateLayout(width)
        width = width or (parent and parent.GetWidth and parent:GetWidth()) or 0
        local shouldStack = isResponsive and (width > 0 and width < threshold)
        local wasStacked = isStacked

        leftColumn:ClearAllPoints()
        rightColumn:ClearAllPoints()

        if shouldStack then
            isStacked = true
            -- Stacked Mode (100% width, vertically stacked)
            leftColumn:SetPoint("TOPLEFT", parent, "TOPLEFT", 5, yOffset)
            leftColumn:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -5, yOffset)

            if height then
                leftColumn:SetHeight(height)
                rightColumn:SetHeight(height)
                rightColumn:SetPoint("TOPLEFT", leftColumn, "BOTTOMLEFT", 0, -gap)
                rightColumn:SetPoint("TOPRIGHT", leftColumn, "BOTTOMRIGHT", 0, -gap)
            else
                local defaultH = options.stackedColumnHeight or math.max(200, math.floor(((parent and parent.GetHeight and parent:GetHeight()) or 400) * 0.5))
                local leftContentH = getColumnContentHeight(leftColumn)
                local rightContentH = getColumnContentHeight(rightColumn)
                local leftH = (leftContentH > 0) and (leftContentH + 10) or defaultH
                local rightH = (rightContentH > 0) and (rightContentH + 10) or defaultH
                leftColumn:SetHeight(leftH)
                rightColumn:SetHeight(rightH)
                rightColumn:SetPoint("TOPLEFT", leftColumn, "BOTTOMLEFT", 0, -gap)
                rightColumn:SetPoint("TOPRIGHT", leftColumn, "BOTTOMRIGHT", 0, -gap)
            end
        else
            isStacked = false
            -- Horizontal Mode (50% / 50% split)
            leftColumn:SetPoint("TOPLEFT", parent, "TOPLEFT", 5, yOffset)
            leftColumn:SetPoint("TOPRIGHT", parent, "TOP", -halfGap, yOffset)

            rightColumn:SetPoint("TOPLEFT", parent, "TOP", halfGap, yOffset)
            rightColumn:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -5, yOffset)

            if height then
                leftColumn:SetHeight(height)
                rightColumn:SetHeight(height)
            else
                leftColumn:SetPoint("BOTTOM", parent, "BOTTOM", 0, 0)
                rightColumn:SetPoint("BOTTOM", parent, "BOTTOM", 0, 0)
            end
        end

        leftColumn.mode = isStacked and "stacked" or "horizontal"
        rightColumn.mode = leftColumn.mode

        if options.onLayoutChange then
            options.onLayoutChange(leftColumn, rightColumn, leftColumn.mode, width)
        end

        -- Notify parent / scroll container to recalculate scroll range when mode changes
        if isStacked ~= wasStacked then
            if parent then
                if parent.updateScrollRange then
                    parent:updateScrollRange()
                elseif parent.GetParent and parent:GetParent() and parent:GetParent().updateScrollRange then
                    parent:GetParent():updateScrollRange()
                end
            end
        end
    end

    -- Initial layout pass
    updateLayout(parent and parent.GetWidth and parent:GetWidth() or 0)

    -- Auto-subscribe to parent OnSizeChanged & OnShow
    if isResponsive and parent and parent.HookScript then
        parent:HookScript("OnSizeChanged", function(self, w, h)
            updateLayout(w or (self and self:GetWidth()) or 0)
        end)
        parent:HookScript("OnShow", function(self)
            updateLayout((self and self:GetWidth()) or 0)
        end)
    end

    -- Auto-subscribe to LayoutModel if passed
    local layoutModel = options.layout or options.layoutModel
    if isResponsive and layoutModel and layoutModel.registerResponsiveElement then
        layoutModel:registerResponsiveElement(leftColumn, function(elem, mode, w, h)
            updateLayout(w)
        end)
    end

    leftColumn.updateLayout = updateLayout
    rightColumn.updateLayout = updateLayout
    leftColumn.isStacked = function() return isStacked end
    rightColumn.isStacked = function() return isStacked end
    leftColumn.otherColumn = rightColumn
    rightColumn.otherColumn = leftColumn
    leftColumn.parentFrame = parent
    rightColumn.parentFrame = parent

    return leftColumn, rightColumn
end

-------------------------------------------------------------------------------
-- 3. EXTENSION & EXPANSION NOTES
-- Objective: Guidelines for custom split ratios (e.g. 1/3 and 2/3), vertical dividers, and multi-column grids.
--
-- How to expand:
-- 1. Asymmetrical Split Ratios:
--    Support `options.ratio = 0.33` (33% / 67% split) by computing explicit widths from `parent:GetWidth()`
--    instead of anchoring strictly to `TOP` center.
-- 2. Center Divider Line:
--    Add optional center separator texture (`options.showDivider = true`) between the two columns
--    using `surfaceLight` or `steelHighlight` color.
-- 3. Multi-Column Generalization:
--    Create `Context:createColumns(options)` supporting N columns dynamically computed from an array of width weights.
-------------------------------------------------------------------------------
