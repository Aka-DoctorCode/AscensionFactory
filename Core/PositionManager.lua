-------------------------------------------------------------------------------
-- Project: AscensionFactory
-- Author: Aka-DoctorCode
-- File: PositionManager.lua
-------------------------------------------------------------------------------
---@diagnostic disable: undefined-global, undefined-field, inject-field

-------------------------------------------------------------------------------
-- 1. INITIALIZATION
-- Objective: Initialize Core PositionManager namespace and link to AscensionFactory.
-- Variables:
-- MAJOR: Namespace identifier for addon library.
-- lib: Global AscensionFactory library object.
-- PositionManager: Dedicated persistence and geometry manager table.
-------------------------------------------------------------------------------
local MAJOR = "AscensionFactory"
local lib = LibStub:GetLibrary(MAJOR)
if not lib then return end

local PositionManager = lib.PositionManager or {}
lib.PositionManager = PositionManager
local Context = lib.Context

-------------------------------------------------------------------------------
-- 2. POSITION & GEOMETRY PERSISTENCE ENGINE
-- Objective: Exclusively manage persistence and geometry (coordinates & dimensions)
-- in SavedVariables (default: _G.AscensionUIPositions) for any frame, whether moved
-- by mouse dragging, resized, or positioned via sliders/code.
-------------------------------------------------------------------------------

--- Initializes or retrieves a persistent position/geometry storage table in the global
--- AscensionUIPositions registry (or a custom SavedVariables table name).
--- @param moduleKey string Unique identifier for the frame/module entry.
--- @param defaultTable table|nil Default coordinates/dimensions (e.g. { point = "CENTER", relativePoint = "CENTER", x = 0, y = 0, width = nil, height = nil }).
--- @param storageTableName string|nil Optional global SavedVariables table name (defaults to "AscensionUIPositions").
--- @return table positionTable The initialized or existing persistent position table.
function PositionManager:initPositionStorage(moduleKey, defaultTable, storageTableName)
    assert(moduleKey and type(moduleKey) == "string" and moduleKey ~= "", "PositionManager:initPositionStorage requires a valid string 'moduleKey'")
    local globalKey = storageTableName or "AscensionUIPositions"
    _G[globalKey] = _G[globalKey] or {}

    local defaults = defaultTable or { point = "CENTER", relativePoint = "CENTER", x = 0, y = 0 }
    if not _G[globalKey][moduleKey] then
        _G[globalKey][moduleKey] = {
            point = defaults.point or "CENTER",
            relativePoint = defaults.relativePoint or defaults.point or "CENTER",
            x = defaults.x or 0,
            y = defaults.y or 0
        }
        for k, v in pairs(defaults) do
            if _G[globalKey][moduleKey][k] == nil then
                _G[globalKey][moduleKey][k] = v
            end
        end
    else
        local entry = _G[globalKey][moduleKey]
        if entry.point == nil then entry.point = defaults.point or "CENTER" end
        if entry.relativePoint == nil then entry.relativePoint = defaults.relativePoint or entry.point or "CENTER" end
        if entry.x == nil then entry.x = defaults.x or 0 end
        if entry.y == nil then entry.y = defaults.y or 0 end
        for k, v in pairs(defaults) do
            if entry[k] == nil then
                entry[k] = v
            end
        end
    end

    return _G[globalKey][moduleKey]
end
PositionManager.InitPositionStorage = PositionManager.initPositionStorage

--- Updates a position table with a frame's current screen anchor coordinates.
--- @param frame table The WoW Frame whose anchor coordinates should be captured.
--- @param positionTable table The target persistence table to update in-place.
function PositionManager:updatePositionFromFrame(frame, positionTable)
    if not frame or not positionTable or type(frame.GetPoint) ~= "function" then return end
    local point, _, relPoint, x, y = frame:GetPoint()
    if point then
        positionTable.point = point
        positionTable.relativePoint = relPoint or point
        positionTable.x = x or 0
        positionTable.y = y or 0
    end
end
PositionManager.UpdatePositionFromFrame = PositionManager.updatePositionFromFrame

--- Applies a saved position table to a frame.
--- @param frame table The WoW Frame to position.
--- @param positionTable table Table containing point, relativePoint, x, y.
--- @param relativeTo table|nil Optional target anchor frame (defaults to _G.UIParent).
function PositionManager:applySavedPosition(frame, positionTable, relativeTo)
    if not frame or not positionTable or not positionTable.point then return end
    frame:ClearAllPoints()
    frame:SetPoint(
        positionTable.point,
        relativeTo or _G.UIParent,
        positionTable.relativePoint or positionTable.point,
        positionTable.x or 0,
        positionTable.y or 0
    )
end
PositionManager.ApplySavedPosition = PositionManager.applySavedPosition

--- Updates a position/geometry table with a frame's current width and height.
--- @param frame table The WoW Frame whose dimensions should be captured.
--- @param positionTable table The target persistence table to update in-place.
function PositionManager:updateSizeFromFrame(frame, positionTable)
    if not frame or not positionTable then return end
    if type(frame.GetWidth) == "function" and type(frame.GetHeight) == "function" then
        local w, h = frame:GetWidth(), frame:GetHeight()
        if w and w > 0 then positionTable.width = w end
        if h and h > 0 then positionTable.height = h end
    end
end
PositionManager.UpdateSizeFromFrame = PositionManager.updateSizeFromFrame

--- Applies saved width and height from a position/geometry table to a frame.
--- @param frame table The WoW Frame to resize.
--- @param positionTable table Table containing width and/or height.
function PositionManager:applySavedSize(frame, positionTable)
    if not frame or not positionTable then return end
    if positionTable.width and positionTable.height and type(frame.SetSize) == "function" then
        frame:SetSize(positionTable.width, positionTable.height)
    else
        if positionTable.width and type(frame.SetWidth) == "function" then
            frame:SetWidth(positionTable.width)
        end
        if positionTable.height and type(frame.SetHeight) == "function" then
            frame:SetHeight(positionTable.height)
        end
    end
end
PositionManager.ApplySavedSize = PositionManager.applySavedSize

--- Resets a position table to default coordinates (or "CENTER", 0, 0) and applies them to the frame.
--- @param frame table|nil Optional WoW Frame to reposition immediately.
--- @param positionTable table The persistence table to reset.
--- @param defaultTable table|nil Optional default coordinates to restore.
--- @param relativeTo table|nil Optional target anchor frame (defaults to _G.UIParent).
function PositionManager:resetPosition(frame, positionTable, defaultTable, relativeTo)
    if not positionTable then return end
    local defaults = defaultTable or { point = "CENTER", relativePoint = "CENTER", x = 0, y = 0 }
    positionTable.point = defaults.point or "CENTER"
    positionTable.relativePoint = defaults.relativePoint or positionTable.point or "CENTER"
    positionTable.x = defaults.x or 0
    positionTable.y = defaults.y or 0
    if frame then
        self:applySavedPosition(frame, positionTable, relativeTo)
    end
end
PositionManager.ResetPosition = PositionManager.resetPosition

--- Resolves or initializes the persistence table for a given frame and configuration table.
--- @param frame table|nil The WoW Frame being configured.
--- @param config table Configuration table containing positionTable, positionKey, or name.
--- @return table|nil positionTable The resolved persistence table.
function PositionManager:resolveStorageTable(frame, config)
    if type(config) ~= "table" then return nil end
    if type(config.positionTable) == "table" then
        return config.positionTable
    end
    local key = config.positionKey or config.moduleKey or config.name or (frame and (frame.globalName or (frame.GetName and frame:GetName())))
    if key and type(key) == "string" and key ~= "" then
        local defaultPoint = config.point or config.anchor or "CENTER"
        local defaultRelPoint = config.relativePoint or defaultPoint or "CENTER"
        local defaultX = config.xOffset or config.x or 0
        local defaultY = config.yOffset or config.y or 0
        return self:initPositionStorage(key, {
            point = defaultPoint,
            relativePoint = defaultRelPoint,
            x = defaultX,
            y = defaultY,
            width = config.width,
            height = config.height
        }, config.storageTableName)
    end
    return config
end

-------------------------------------------------------------------------------
-- 3. LIBRARY & CONTEXT ALIASES
-------------------------------------------------------------------------------
function lib:initPositionStorage(moduleKey, defaultTable, storageTableName)
    return PositionManager:initPositionStorage(moduleKey, defaultTable, storageTableName)
end
lib.InitPositionStorage = lib.initPositionStorage

function lib:updatePositionFromFrame(frame, positionTable)
    return PositionManager:updatePositionFromFrame(frame, positionTable)
end
lib.UpdatePositionFromFrame = lib.updatePositionFromFrame

function lib:applySavedPosition(frame, positionTable, relativeTo)
    return PositionManager:applySavedPosition(frame, positionTable, relativeTo)
end
lib.ApplySavedPosition = lib.applySavedPosition

function lib:updateSizeFromFrame(frame, positionTable)
    return PositionManager:updateSizeFromFrame(frame, positionTable)
end
lib.UpdateSizeFromFrame = lib.updateSizeFromFrame

function lib:applySavedSize(frame, positionTable)
    return PositionManager:applySavedSize(frame, positionTable)
end
lib.ApplySavedSize = lib.applySavedSize

function lib:resetPosition(frame, positionTable, defaultTable, relativeTo)
    return PositionManager:resetPosition(frame, positionTable, defaultTable, relativeTo)
end
lib.ResetPosition = lib.resetPosition

if Context then
    function Context:initPositionStorage(moduleKey, defaultTable, storageTableName)
        return PositionManager:initPositionStorage(moduleKey, defaultTable, storageTableName)
    end
    Context.InitPositionStorage = Context.initPositionStorage

    function Context:updatePositionFromFrame(frame, positionTable)
        return PositionManager:updatePositionFromFrame(frame, positionTable)
    end
    Context.UpdatePositionFromFrame = Context.updatePositionFromFrame

    function Context:applySavedPosition(frame, positionTable, relativeTo)
        return PositionManager:applySavedPosition(frame, positionTable, relativeTo)
    end
    Context.ApplySavedPosition = Context.applySavedPosition

    function Context:updateSizeFromFrame(frame, positionTable)
        return PositionManager:updateSizeFromFrame(frame, positionTable)
    end
    Context.UpdateSizeFromFrame = Context.updateSizeFromFrame

    function Context:applySavedSize(frame, positionTable)
        return PositionManager:applySavedSize(frame, positionTable)
    end
    Context.ApplySavedSize = Context.applySavedSize

    function Context:resetPosition(frame, positionTable, defaultTable, relativeTo)
        return PositionManager:resetPosition(frame, positionTable, defaultTable, relativeTo)
    end
    Context.ResetPosition = Context.resetPosition
end

