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
-- Objective: Configure frame to be resizable, add metallic corner bracket handle at bottom-right,
-- and delegate dimension persistence (width, height) to Core/PositionManager.lua when configured.
-- Variables:
-- frame: Frame UI object made resizable.
-- options: Mandatory configuration table requiring explicit `saveSize` (boolean).
-------------------------------------------------------------------------------
--- Configures a frame to be resizable and adds a metallic corner bracket handle at the bottom-right.
--- Requires `options` table with an explicit boolean `options.saveSize` (`true` or `false`).
--- @param frame table UI frame object to make resizable.
--- @param minWidth number|table Configuration table with `saveSize = true|false`, minWidth, minHeight, etc.
--- @param minHeight number|nil Minimum height if positional arguments are used.
--- @param maxWidth number|nil Maximum allowable width when resizing.
--- @param maxHeight number|nil Maximum allowable height when resizing.
--- @param saveSize boolean|nil Explicit boolean if positional arguments are used.
function UX:makeResizable(frame, minWidth, minHeight, maxWidth, maxHeight, saveSize)
    assert(frame, "UX:makeResizable requires a valid 'frame'")

    local minW, minH, maxW, maxH
    local onResizeStop, onSizeChanged
    local gripSize = 24
    local gripThickness = 8
    local opts

    if type(minWidth) == "table" then
        opts = minWidth
        assert(type(opts.saveSize) == "boolean", "UX:makeResizable requires explicit boolean 'options.saveSize' (true or false)")
        minW = opts.minWidth or opts.minW or 0
        minH = opts.minHeight or opts.minH or 0
        maxW = opts.maxWidth or opts.maxW or 0
        maxH = opts.maxHeight or opts.maxH or 0
        onResizeStop = opts.onResizeStop
        onSizeChanged = opts.onSizeChanged
        gripSize = opts.gripSize or 24
        gripThickness = opts.gripThickness or 8
    else
        assert(type(saveSize) == "boolean", "UX:makeResizable requires explicit boolean 'saveSize' (true or false)")
        opts = {
            saveSize = saveSize,
            minWidth = minWidth,
            minHeight = minHeight,
            maxWidth = maxWidth,
            maxHeight = maxHeight
        }
        minW = minWidth or 0
        minH = minHeight or 0
        maxW = maxWidth or 0
        maxH = maxHeight or 0
    end

    local pm = lib.PositionManager
    local storageTable = nil
    if opts.saveSize and pm then
        storageTable = frame.positionStorage or pm:resolveStorageTable(frame, opts)
        frame.positionStorage = storageTable
    end

    -- Configure Resize Properties
    frame:SetResizable(true)
    local function getEffectiveBounds()
        local fScale = frame:GetEffectiveScale() or 1
        local pScale = (UIParent and UIParent:GetEffectiveScale()) or fScale
        local scaleRatio = (fScale > 0) and (pScale / fScale) or 1
        local rawScreenW = (UIParent and UIParent:GetWidth()) or GetScreenWidth()
        local rawScreenH = (UIParent and UIParent:GetHeight()) or GetScreenHeight()
        local screenW = rawScreenW * scaleRatio
        local screenH = rawScreenH * scaleRatio
        local effectiveMaxW = (maxW and maxW > 0) and math.min(maxW, screenW) or screenW
        local effectiveMaxH = (maxH and maxH > 0) and math.min(maxH, screenH) or screenH
        return minW or 0, minH or 0, effectiveMaxW, effectiveMaxH, scaleRatio, screenW, screenH
    end

    local function applyResizeBounds()
        local bMinW, bMinH, bMaxW, bMaxH = getEffectiveBounds()
        frame:SetResizeBounds(bMinW, bMinH, bMaxW, bMaxH)
    end
    applyResizeBounds()

    -- Restore saved dimensions if enabled in PositionManager
    if opts.saveSize and pm and storageTable then
        pm:applySavedSize(frame, storageTable)
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
    local startCursorX, startCursorY = 0, 0
    local startW, startH = 0, 0
    local activeMinW, activeMinH, activeMaxW, activeMaxH = 0, 0, 0, 0
    local lastW, lastH = nil, nil

    local function finishResize(triggerCallbacks)
        if not isResizing then return end
        isResizing = false
        resizeBtn:SetScript("OnUpdate", nil)
        if resizeBtn:IsMouseOver() then
            setBracketColor(steelHover)
        else
            setBracketColor(steelBase)
        end
        if opts.saveSize and pm and storageTable then
            pm:updateSizeFromFrame(frame, storageTable)
        end
        if opts.savePosition and pm and storageTable then
            pm:updatePositionFromFrame(frame, storageTable)
        end
        if triggerCallbacks and onResizeStop then
            onResizeStop(frame, frame:GetWidth(), frame:GetHeight())
        end
    end

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
        if button ~= "LeftButton" then return end
        if storageTable and storageTable.locked then return end

        local bMinW, bMinH, bMaxW, bMaxH, scaleRatio, screenW, screenH = getEffectiveBounds()
        frame:SetResizeBounds(bMinW, bMinH, bMaxW, bMaxH)

        local left, top = frame:GetLeft(), frame:GetTop()
        local w, h = frame:GetSize()
        if not w or w <= 0 or not h or h <= 0 then return end

        if left and top and UIParent then
            local uiLeft = (UIParent:GetLeft() or 0) * scaleRatio
            local uiTop = (UIParent:GetTop() or (GetScreenHeight() * scaleRatio)) * scaleRatio
            frame:ClearAllPoints()
            frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", left - uiLeft, top - uiTop)
            frame:SetSize(w, h)
            if frame.GetClampedToScreen and frame:GetClampedToScreen() then
                local availW = (uiLeft + screenW) - left
                local availH = top - (uiTop - screenH)
                if availW > 0 then bMaxW = math.min(bMaxW, availW) end
                if availH > 0 then bMaxH = math.min(bMaxH, availH) end
            end
        end

        local fScale = frame:GetEffectiveScale() or 1
        local cx, cy = GetCursorPosition()
        startCursorX = cx / fScale
        startCursorY = cy / fScale
        startW, startH = w, h
        activeMinW, activeMinH = bMinW, bMinH
        activeMaxW, activeMaxH = math.max(bMinW, bMaxW), math.max(bMinH, bMaxH)
        lastW, lastH = w, h

        isResizing = true
        setBracketColor(steelActive)
        self:SetScript("OnUpdate", function()
            if not isResizing then return end
            local curScale = frame:GetEffectiveScale() or 1
            local curX, curY = GetCursorPosition()
            curX = curX / curScale
            curY = curY / curScale
            local dx = curX - startCursorX
            local dy = startCursorY - curY
            local newW = math.max(activeMinW, math.min(activeMaxW, startW + dx))
            local newH = math.max(activeMinH, math.min(activeMaxH, startH + dy))
            if newW ~= lastW or newH ~= lastH then
                lastW, lastH = newW, newH
                frame:SetSize(newW, newH)
            end
        end)
    end)

    resizeBtn:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" then
            finishResize(true)
        end
    end)

    resizeBtn:SetScript("OnHide", function()
        finishResize(false)
    end)

    frame.resizeBtn = resizeBtn
end
UX.MakeResizable = UX.makeResizable

-------------------------------------------------------------------------------
-- 3. EXTENSION & EXPANSION NOTES
-- Objective: Guidelines for custom resize handles, aspect ratio locking, and on-resize relayout callbacks.
--
-- How to expand:
-- 1. Dimension Persistence:
--    Pass `saveSize = true` in `options` to automatically store and restore `width` and `height`
--    in `Core/PositionManager.lua` (`_G.AscensionUIPositions[name]`).
-------------------------------------------------------------------------------
