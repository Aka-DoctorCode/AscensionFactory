-------------------------------------------------------------------------------
-- Project: AscensionFactory
-- Author: Aka-DoctorCode
-- File: Draggable.lua
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
-- 2. MOVEMENT LOGIC
-- Objective: Enable frame to be moved by clicking and dragging with left mouse button.
-- Variables:
-- frame: Frame UI object made movable.
-- config: Optional persistence configuration table containing coordinates.
-------------------------------------------------------------------------------
--- Enables a frame to be moved by clicking and dragging with the left mouse button.
function UX:makeMovable(frame, config)
    if not frame then return end
    
    -- Setup Interaction
    -- SetMovable(true) tells the WoW client that this frame's position can be changed dynamically.
    frame:SetMovable(true)
    -- EnableMouse(true) allows the frame to intercept mouse clicks and movements instead of passing them through to the world.
    frame:EnableMouse(true)
    -- SetClampedToScreen(true) prevents the user from dragging the frame entirely off the monitor.
    frame:SetClampedToScreen(true)
    -- RegisterForDrag("LeftButton") tells the engine to fire drag events when the Left Mouse Button is held down.
    frame:RegisterForDrag("LeftButton")
    
    -- Drag Event Handlers
    -- SetScript args:
    -- 1: "OnDragStart" (event script handler name)
    -- 2: function (callback)
    frame:SetScript("OnDragStart", function(self)
        -- StartMoving() natively attaches the frame to the mouse cursor.
        self:StartMoving()
    end)
    
    -- SetScript args:
    -- 1: "OnDragStop" (event script handler name)
    -- 2: function (callback)
    frame:SetScript("OnDragStop", function(self)
        -- StopMovingOrSizing() detaches the frame from the cursor and drops it in place.
        self:StopMovingOrSizing()
        
        -- Save coordinates if persistent config is provided.
        if config then
            -- GetPoint() returns the anchoring details (point, relativeFrame, relativePoint, xOffset, yOffset).
            local point, _, relPoint, x, y = self:GetPoint()
            config.point = point
            config.relativePoint = relPoint
            config.x = x
            config.y = y
        end
    end)

    -- Load saved position if available.
    -- If the user dragged this window before, restore those exact coordinates upon opening.
    if config and config.point then
        frame:ClearAllPoints() -- Remove old positioning.
        -- SetPoint args:
        -- 1: config.point (this frame's anchor)
        -- 2: _G.UIParent (target frame)
        -- 3: config.relativePoint or config.point (target's anchor)
        -- 4: config.x or 0 (X offset)
        -- 5: config.y or 0 (Y offset)
        frame:SetPoint(config.point, _G.UIParent, config.relativePoint or config.point, config.x or 0, config.y or 0)
    end
end

-------------------------------------------------------------------------------
-- 3. EXTENSION & EXPANSION NOTES
-- Objective: Guidelines for persistent position storage, title bar drag handles, and screen clamping.
--
-- How to expand:
-- 1. SavedVariables Integration:
--    Pass an entry from your addon's SavedVariables table as `config` (e.g. `MyAddonDB.windowPosition`)
--    to automatically persist and restore the frame's position across game sessions and reloads.
-- 2. Title Bar Handle Restriction:
--    Restrict dragging to a top header bar rather than the entire frame body by calling `makeMovable`
--    on a child title bar frame and proxying the `StartMoving()` / `StopMovingOrSizing()` calls to the parent window.
-- 3. Snap-to-Grid / Edge Snapping:
--    Hook `OnDragStop` to calculate proximity to screen edges or adjacent addon windows and snap
--    the frame coordinates to the nearest alignment threshold.
-------------------------------------------------------------------------------
