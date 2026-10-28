-------------------------------------------------------------------------------
-- Project: AscensionFactory
-- Author: Aka-DoctorCode
-- File: Resizable.lua
-------------------------------------------------------------------------------
---@diagnostic disable: undefined-global, undefined-field, inject-field

-------------------------------------------------------------------------------
-- 1. INITIALIZATION
-- Objective: Initialize UX namespace and link to global AscensionFactory library.
-- Variables:
-- MAJOR: Namespace identifier for addon library.
-- lib: Global AscensionFactory library object.
-- UX: Namespace table for UX helper functions.
-------------------------------------------------------------------------------
local MAJOR = "AscensionFactory"
local lib = LibStub:GetLibrary(MAJOR)
if not lib then return end

local UX = lib.UX or {}
lib.UX = UX

-------------------------------------------------------------------------------
-- 2. RESIZE LOGIC
-- Objective: Configure frame to be resizable and add metallic corner bracket handle at bottom-right.
-- Variables:
-- frame: Frame UI object made resizable.
-- minWidth: Minimum allowable width or configuration options table.
-- minHeight: Minimum allowable height when resizing.
-- maxWidth: Maximum allowable width when resizing.
-- maxHeight: Maximum allowable height when resizing.
-------------------------------------------------------------------------------
--- Configures a frame to be resizable and adds a metallic corner bracket handle at the bottom-right.
--- Supports both positional arguments: `UX:makeResizable(frame, minWidth, minHeight, maxWidth, maxHeight)`
--- and options table: `UX:makeResizable(frame, options)`.
--- @param frame table UI frame object to make resizable.
--- @param minWidth number|table Either minimum width, or a table with options.
--- @param minHeight number|nil Minimum height if minWidth is a number.
--- @param maxWidth number|nil Maximum allowable width when resizing.
--- @param maxHeight number|nil Maximum allowable height when resizing.
function UX:makeResizable(frame, minWidth, minHeight, maxWidth, maxHeight)
    if not frame then return end

    local minW, minH, maxW, maxH
    local onResizeStop, onSizeChanged
    local gripSize = 24
    local gripThickness = 8

    if type(minWidth) == "table" then
        local opts = minWidth
        minW = opts.minWidth or opts.minW or 0
        minH = opts.minHeight or opts.minH or 0
        maxW = opts.maxWidth or opts.maxW or 0
        maxH = opts.maxHeight or opts.maxH or 0
        onResizeStop = opts.onResizeStop
        onSizeChanged = opts.onSizeChanged
        gripSize = opts.gripSize or 24
        gripThickness = opts.gripThickness or 8
    else
        minW = minWidth or 0
        minH = minHeight or 0
        maxW = maxWidth or 0
        maxH = maxHeight or 0
    end

    -- Configure Resize Properties
    frame:SetResizable(true)
    if (minW and minW > 0) or (minH and minH > 0) or (maxW and maxW > 0) or (maxH and maxH > 0) then
        frame:SetResizeBounds(minW or 0, minH or 0, maxW or 0, maxH or 0)
    end

    -- Hook OnSizeChanged if callback is provided
    if onSizeChanged then
        frame._afOnSizeChanged = onSizeChanged
        if not frame._afSizeHooked then
            frame._afSizeHooked = true
            frame:HookScript("OnSizeChanged", function(self, w, h)
                if self._afOnSizeChanged then
                    self._afOnSizeChanged(self, w, h)
                end
            end)
        end
    end

    -- Resolve metallic theme palette
    local styles = (frame.uiContext and frame.uiContext.styles) or lib.defaultStyles
    local colors = (styles and styles.colors) or lib.defaultStyles.colors
    local steelBase = colors.steelBase or { 0.180, 0.220, 0.275, 1.00 }
    local steelHover = colors.steelHover or { 0.353, 0.420, 0.510, 1.00 }
    local steelActive = colors.steelActive or { 0.541, 0.608, 0.702, 1.00 }

    -- Create Grabber Handle Button
    local resizeBtn = frame.resizeBtn
    if not resizeBtn then
        if frame.uiContext and frame.uiContext.acquireElement then
            resizeBtn = frame.uiContext:acquireElement("Button", frame, { width = gripSize, height = gripSize })
        else
            resizeBtn = CreateFrame("Button", nil, frame)
            resizeBtn:SetSize(gripSize, gripSize)
        end
        frame.resizeBtn = resizeBtn
    end

    resizeBtn:ClearAllPoints()
    resizeBtn:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    resizeBtn:SetSize(gripSize, gripSize)
    if frame.GetFrameLevel then
        resizeBtn:SetFrameLevel(frame:GetFrameLevel() + 10)
    end
    resizeBtn:Show()

    -- Clear standard textures
    resizeBtn:SetNormalTexture("")
    resizeBtn:SetHighlightTexture("")
    resizeBtn:SetPushedTexture("")

    -- Create Metallic Corner Bracket ("L" shape: horizontal and vertical bars)
    local flatTexture = (styles and styles.textures and styles.textures.flat) or "Interface\\Buttons\\WHITE8X8"

    if not resizeBtn.hBar then
        local hBar = resizeBtn:CreateTexture(nil, "OVERLAY")
        hBar:SetTexture(flatTexture)
        resizeBtn.hBar = hBar
    end
    resizeBtn.hBar:ClearAllPoints()
    resizeBtn.hBar:SetPoint("BOTTOMRIGHT", resizeBtn, "BOTTOMRIGHT", 0, 0)
    resizeBtn.hBar:SetSize(gripSize, gripThickness)
    resizeBtn.hBar:Show()

    if not resizeBtn.vBar then
        local vBar = resizeBtn:CreateTexture(nil, "OVERLAY")
        vBar:SetTexture(flatTexture)
        resizeBtn.vBar = vBar
    end
    resizeBtn.vBar:ClearAllPoints()
    resizeBtn.vBar:SetPoint("BOTTOMRIGHT", resizeBtn, "BOTTOMRIGHT", 0, 0)
    resizeBtn.vBar:SetSize(gripThickness, gripSize)
    resizeBtn.vBar:Show()

    local function setBracketColor(c)
        resizeBtn.hBar:SetColorTexture(c[1], c[2], c[3], c[4] or 1)
        resizeBtn.vBar:SetColorTexture(c[1], c[2], c[3], c[4] or 1)
    end

    -- Initial normal appearance
    setBracketColor(steelBase)

    local isResizing = false

    -- Handle Interactive States
    resizeBtn:SetScript("OnEnter", function(self)
        if not isResizing then
            setBracketColor(steelHover)
        end
    end)

    resizeBtn:SetScript("OnLeave", function(self)
        if not isResizing then
            setBracketColor(steelBase)
        end
    end)

    resizeBtn:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            isResizing = true
            setBracketColor(steelActive)
            frame:StartSizing("BOTTOMRIGHT")
        end
    end)

    resizeBtn:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" then
            isResizing = false
            frame:StopMovingOrSizing()
            if self:IsMouseOver() then
                setBracketColor(steelHover)
            else
                setBracketColor(steelBase)
            end
            if onResizeStop then
                onResizeStop(frame, frame:GetWidth(), frame:GetHeight())
            end
        end
    end)

    frame.resizeBtn = resizeBtn
end

-------------------------------------------------------------------------------
-- 3. EXTENSION & EXPANSION NOTES
-- Objective: Guidelines for custom resize handles, aspect ratio locking, and on-resize relayout callbacks.
--
-- How to expand:
-- 1. Resize Callbacks:
--    Hook `frame:HookScript("OnSizeChanged", function(self, w, h) ... end)` to dynamically recalculate
--    child column widths or scroll area bounds during user resizing.
-- 2. Four-Corner / Edge Handles:
--    Add optional side/corner handles (`"TOPRIGHT"`, `"BOTTOMLEFT"`, `"RIGHT"`, `"BOTTOM"`) by creating
--    additional grabber buttons calling `frame:StartSizing("<Point>")`.
-- 3. Dimension Persistence:
--    Store final `frame:GetSize()` values into `config.width` and `config.height` inside `OnMouseUp`
--    for automatic restoration across reload.
-------------------------------------------------------------------------------
