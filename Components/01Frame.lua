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
--- @param options table|nil Optional configuration table.
--- @return table frame The styled frame instance.
function Context:createFrame(options)
    options = options or {}
    local styles = self.styles
    local ux = lib.UX
    local parent = options.parent or _G.UIParent

    -- Request a base 'Frame' element from the FrameworkPool
    local frame = self:acquireElement("Frame", parent, {
        anchorPoint = options.anchor or options.point or "CENTER",
        width = options.width,
        height = options.height
    })

    -- Global namespace registration if name was provided
    if options.name then
        _G[options.name] = frame
        frame.globalName = options.name
    end

    -- Sizing
    frame:SetSize(options.width or 300, options.height or 200)

    -- Anchoring
    frame:ClearAllPoints()
    if options.point then
        frame:SetPoint(
            options.point,
            options.relativeTo or parent,
            options.relativePoint or options.point,
            options.xOffset or 0,
            options.yOffset or 0
        )
    else
        frame:SetPoint(options.anchor or "CENTER")
    end

    -- Strata & Clamping
    local targetStrata = options.strata or (parent and parent.GetFrameStrata and parent:GetFrameStrata()) or "MEDIUM"
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

    -- Optional UX interactions
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
--- @param options table Configuration table (requires options.name).
--- @return table frame The primary application window frame.
function Context:createMainFrame(options)
    options = options or {}
    assert(options.name, "options.name required for main frame")

    local frameOptions = {}
    for k, v in pairs(options) do
        frameOptions[k] = v
    end

    frameOptions.width = options.width or 860
    frameOptions.height = options.height or 500
    frameOptions.anchor = options.anchor or "CENTER"
    frameOptions.strata = options.strata or "DIALOG"
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

