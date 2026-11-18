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
-- Objective: Enable frame to be moved by clicking and dragging with left mouse button,
-- and delegate coordinate persistence to Core/PositionManager.lua when configured.
-- Variables:
-- frame: Frame UI object made movable.
-- config: Mandatory configuration table requiring explicit `savePosition` (boolean).
-------------------------------------------------------------------------------
--- Enables a frame to be moved by clicking and dragging with the left mouse button.
--- Requires `config` table with an explicit boolean `config.savePosition` (`true` or `false`).
--- @param frame table UI frame object to make movable.
--- @param config table Configuration table (`savePosition = true|false`, optional `positionTable`, `positionKey`, `storageTableName`).
function UX:makeMovable(frame, config)
    assert(frame, "UX:makeMovable requires a valid 'frame'")
    assert(type(config) == "table", "UX:makeMovable requires a 'config' table (with explicit boolean 'savePosition')")
    assert(type(config.savePosition) == "boolean", "UX:makeMovable requires explicit boolean 'config.savePosition' (true or false)")

    local pm = lib.PositionManager
    local storageTable = nil

    if config.savePosition and pm then
        storageTable = pm:resolveStorageTable(frame, config)
        frame.positionStorage = storageTable
    end

    -- Setup Interaction
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetClampedToScreen(true)
    frame:RegisterForDrag("LeftButton")

    -- Drag Event Handlers
    frame:SetScript("OnDragStart", function(self)
        if storageTable and storageTable.locked then return end
        if self:IsMovable() then
            self:StartMoving()
        end
    end)

    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()

        -- Delegate coordinate saving to Core/PositionManager.lua if enabled
        if config.savePosition and pm and storageTable then
            pm:updatePositionFromFrame(self, storageTable)
        end
    end)

    -- Delegate initial saved position restoration to Core/PositionManager.lua if enabled
    if config.savePosition and pm and storageTable and storageTable.point then
        pm:applySavedPosition(frame, storageTable, config.relativeTo or _G.UIParent)
    end
end
UX.MakeMovable = UX.makeMovable
UX.makeDraggable = UX.makeMovable
UX.MakeDraggable = UX.makeMovable

-------------------------------------------------------------------------------
-- 3. EXTENSION & EXPANSION NOTES
-- Objective: Guidelines for persistent position storage, title bar drag handles, and screen clamping.
--
-- How to expand:
-- 1. PositionManager Delegation:
--    Pass `{ savePosition = true, positionKey = "MyWindow" }` (or `positionTable = myTable`)
--    to persist coordinates via `Core/PositionManager.lua`, or `{ savePosition = false }` for session-only dragging.
-- 2. Title Bar Handle Restriction:
--    Restrict dragging to a top header bar rather than the entire frame body by calling `makeMovable`
--    on a child title bar frame and proxying the `StartMoving()` / `StopMovingOrSizing()` calls to the parent window.
-------------------------------------------------------------------------------
