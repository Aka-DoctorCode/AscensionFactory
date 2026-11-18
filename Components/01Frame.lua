-------------------------------------------------------------------------------
-- Project: AscensionFactory
-- Author: Aka-DoctorCode
-- File: MainFrame.lua
-------------------------------------------------------------------------------
---@diagnostic disable: undefined-global, undefined-field, inject-field

-------------------------------------------------------------------------------
-- 1. INITIALIZATION
-- Objective: Import the core AscensionFactory library and Context. This ensures the UI elements can be built upon the existing framework.
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
-- 2. FRAME FACTORIES
-- Objective: Provide flexible factory methods to create UI frames and application windows.
-- Context:createFrame creates a versatile Obsidian Cyberpunk styled container.
-- Context:createMainFrame builds upon createFrame with top-level window defaults.
-- Variables:
-- options (table): Layout and configuration parameters.
-- styles (table): Theme colors and textures.
-- ux (table): User experience helpers (moving, closing).
-- frame (table): Newly allocated or acquired UI frame element.
-------------------------------------------------------------------------------

--- Creates a versatile Obsidian Cyberpunk styled container frame.
--- @param options table Configuration table (requires options.name, options.width, options.height).
--- @return table frame The styled frame instance.
function Context:createFrame(options)
    assert(type(options) == "table", "options table required for createFrame")
    assert(options.name, "options.name is required for createFrame")
    assert(options.parent, "options.parent is required for createFrame")
    assert(type(options.width) == "number", "options.width is required and must be a number")
    assert(type(options.height) == "number", "options.height is required and must be a number")
    if options.movable then
        assert(type(options.savePosition) == "boolean", "options.savePosition (true or false) is required when options.movable is true")
    end
    if options.resizable then
        assert(type(options.saveSize) == "boolean", "options.saveSize (true or false) is required when options.resizable is true")
    end

    local styles = self.styles
    local ux = lib.UX
    local parent = options.parent

    local point = options.point or options.anchor or "CENTER"
    local relativePoint = options.relativePoint or point or "CENTER"

    -- Request a base 'Frame' element from the FrameworkPool
    local frame = self:acquireElement("Frame", parent, {
        anchorPoint = point,
        width = options.width,
        height = options.height
    })

    -- Global namespace registration
    _G[options.name] = frame
    frame.globalName = options.name

    -- Sizing
    frame:SetSize(options.width, options.height)

    -- Anchoring
    frame:ClearAllPoints()
    frame:SetPoint(
        point,
        options.relativeTo or parent,
        relativePoint,
        options.xOffset or 0,
        options.yOffset or 0
    )

    -- Strata & Clamping
    local targetStrata = options.strata or (parent and parent.GetFrameStrata and parent:GetFrameStrata()) or "HIGH"
    frame:SetFrameStrata(targetStrata)
    if parent and parent.GetFrameLevel and not options.frameLevel then
        frame:SetFrameLevel(math.max(1, parent:GetFrameLevel() + 1))
    elseif options.frameLevel then
        frame:SetFrameLevel(options.frameLevel)
    end
    frame:SetClampedToScreen(options.clamped ~= false)

    -- Border Texture
    local showBorder = options.showBorder ~= false
    if showBorder then
        if not frame.border then
            local border = frame:CreateTexture(nil, "BACKGROUND", nil, -2)
            border:SetAllPoints(frame)
            frame.border = border
        end
        frame.border:Show()
        local borderColor = options.borderColor or styles.colors.border
        frame.border:SetColorTexture(unpack(borderColor))
    elseif frame.border then
        frame.border:Hide()
    end

    -- Inner Background Texture
    local showBackground = options.showBackground ~= false
    local borderInset = options.borderInset or (showBorder and 1 or 0)
    if showBackground then
        if not frame.background then
            local background = frame:CreateTexture(nil, "BACKGROUND", nil, -1)
            frame.background = background
        end
        frame.background:ClearAllPoints()
        frame.background:SetPoint("TOPLEFT", frame, "TOPLEFT", borderInset, -borderInset)
        frame.background:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -borderInset, borderInset)
        frame.background:Show()
        local bgColor = options.backgroundColor or styles.colors.background
        frame.background:SetColorTexture(unpack(bgColor))
    elseif frame.background then
        frame.background:Hide()
    end

    -- Optional Close Button
    if options.showCloseButton and self.createIconButton then
        local closeButton = self:createIconButton({
            parent = frame,
            name = options.name and (options.name .. "CloseButton"),
            iconType = "close",
            size = options.closeButtonSize or 24,
            tooltip = false,
            point = "TOPRIGHT",
            relativeTo = frame,
            relativePoint = "TOPRIGHT",
            xOffset = options.closeButtonXOffset or -8,
            yOffset = options.closeButtonYOffset or -8,
            onClick = function()
                if options.onClose then
                    options.onClose(frame)
                else
                    frame:Hide()
                end
            end
        })
        frame.closeButton = closeButton
    end

    -- Optional UX interactions & PositionManager integration
    local pm = lib.PositionManager
    if pm and not options.movable and options.savePosition and (options.positionTable or options.positionKey) then
        local storageTable = pm:resolveStorageTable(frame, options)
        frame.positionStorage = storageTable
        if storageTable and storageTable.point then
            pm:applySavedPosition(frame, storageTable, options.relativeTo or parent)
        end
    end
    if ux then
        if options.movable then
            ux:makeMovable(frame, options)
        end
        if options.closableWithEscape then
            ux:makeClosableWithEscape(frame, options)
        end
        if options.resizable then
            ux:makeResizable(frame, options)
        end
    end

    return frame
end

--- Creates the primary application window with main window defaults.
--- @param options table Configuration table (requires options.name, options.width, options.height, options.minWidth, options.minHeight).
--- @return table frame The primary application window frame.
function Context:createMainFrame(options)
    assert(type(options) == "table", "options table required for main frame")
    assert(options.name, "options.name required for main frame")
    assert(type(options.width) == "number", "options.width is required and must be a number for main frame")
    assert(type(options.height) == "number", "options.height is required and must be a number for main frame")
    assert(type(options.minWidth) == "number", "options.minWidth is required and must be a number for main frame")
    assert(type(options.minHeight) == "number", "options.minHeight is required and must be a number for main frame")

    local frameOptions = {}
    for k, v in pairs(options) do
        frameOptions[k] = v
    end

    frameOptions.width = options.width
    frameOptions.height = options.height
    frameOptions.minWidth = options.minWidth
    frameOptions.minHeight = options.minHeight
    frameOptions.anchor = options.anchor or options.point or "CENTER"
    frameOptions.relativePoint = options.relativePoint or frameOptions.anchor
    frameOptions.strata = options.strata or "HIGH"
    frameOptions.borderInset = options.borderInset or 2

    if frameOptions.showCloseButton == nil then
        frameOptions.showCloseButton = true
    end
    if frameOptions.movable == nil then
        frameOptions.movable = true
    end
    if frameOptions.closableWithEscape == nil then
        frameOptions.closableWithEscape = true
    end
    if frameOptions.resizable == nil then
        frameOptions.resizable = true
    end
    if frameOptions.movable then
        assert(type(frameOptions.savePosition) == "boolean", "options.savePosition (true or false) is required for createMainFrame when movable is true")
    end
    if frameOptions.resizable then
        assert(type(frameOptions.saveSize) == "boolean", "options.saveSize (true or false) is required for createMainFrame when resizable is true")
    end

    return self:createFrame(frameOptions)
end

-------------------------------------------------------------------------------
-- 3. EXTENSION & EXPANSION NOTES
-- Objective: Guidelines for custom window titles, status bars, and window minimization.
--
-- How to expand:
-- 1. Integrated Title Bar:
--    Attach an icon button for minimize/maximize alongside the close button, and anchor a header label
--    at `TOPLEFT` with `options.title` to form a full titlebar.
-- 2. Bottom Status Bar:
--    Add `options.showStatusBar` to anchor a bottom sub-frame with version number and status indicator icons.
-- 3. Resizable Frames:
--    Pass `options.resizable = true` to automatically invoke `ux:makeResizable(frame, minW, minH)`.
-------------------------------------------------------------------------------

