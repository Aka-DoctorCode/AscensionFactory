-------------------------------------------------------------------------------
-- Project: AscensionFactory
-- Author: Aka-DoctorCode
-- File: Core.lua
-------------------------------------------------------------------------------
---@diagnostic disable: undefined-global, undefined-field, inject-field

-------------------------------------------------------------------------------
-- 1. INITIALIZATION & NAMESPACE REGISTRATION
-- Objective: Register AscensionFactory with LibStub and establish the shared Context prototype.
-- Variables:
-- MAJOR (string): Identifier for global library registration.
-- MINOR (number): Incremental version number for LibStub upgrade resolution.
-- lib (table): Shared library instance maintained by LibStub.
-- Context (table): Prototype table containing element factory methods and lifecycle management.
-------------------------------------------------------------------------------

local MAJOR, MINOR = "AscensionFactory", 1
local lib = LibStub:NewLibrary(MAJOR, MINOR)
if not lib then return end

local Context = lib.Context or {}
if not lib.Context then lib.Context = Context end

-------------------------------------------------------------------------------
-- 2. CONTEXT OBJECT & FACTORY BLUEPRINT
-- Objective: Establish object-oriented metatable linking for Context instances.
-- Each consumer addon creates its own Context instance with its own styles and pools.
-------------------------------------------------------------------------------
-- Setup Lua OOP inheritance. __index to itself means any new table created from this blueprint will automatically have access to all its functions.
Context.__index = Context

--- Creates an isolated UI context instance for constructing and managing interface elements.
--- @param customStyles table|nil Optional custom style tokens overriding default theme.
--- @return table uiContext The newly allocated Context instance.
function lib:createContext(customStyles, addonName)
    if not addonName and debugstack then
        local stack = debugstack(2, 5, 0) or ""
        for folder in stack:gmatch("Interface[/\\]AddOns[/\\]([^/\\]+)[/\\]") do
            if folder ~= MAJOR then
                addonName = folder
                break
            end
        end
    end

    local uiContext = setmetatable({
        styles = customStyles or lib.defaultStyles or lib.DefaultStyles,
        addonName = addonName,
        layoutModel = nil,
        pools = nil
    }, Context)

    if lib.LayoutModel then
        uiContext.layoutModel = lib.LayoutModel:new(uiContext)
    end

    return uiContext
end

lib.CreateContext = lib.createContext

--- Returns the universal default layout gap (10px unless customized in styles).
--- @return number gap Default spacing in pixels.
function Context:getDefaultGap()
    if self.styles and self.styles.spacing and self.styles.spacing.gap then
        return self.styles.spacing.gap
    end
    if self.styles and self.styles.defaultGap then
        return self.styles.defaultGap
    end
    return 10
end

--- Centralized post-creation hook (Proposal 1.D): if `options.layout` is provided,
--- automatically anchors the created widget into that layout.
--- @param widget table The created UI element.
--- @param options table|nil Creation options table.
--- @return table widget
function Context:registerCreatedElement(widget, options)
    if widget and type(options) == "table" and options.layout then
        local targetLayout = options.layout
        if type(targetLayout.add) == "function" then
            targetLayout:add(widget, options)
        elseif type(targetLayout.anchorElement) == "function" then
            targetLayout:anchorElement(widget, options)
        end
    end
    return widget
end

-------------------------------------------------------------------------------
-- 3. EXTENSION & EXPANSION NOTES
-- Objective: Guidelines for extending the core library lifecycle and context factory.
--
-- How to expand:
-- 1. Custom Theme Injection:
--    Pass a custom table matching the `defaultStyles` schema into `createContext(customStyles)`
--    to theme an addon independently without mutating global defaults.
-- 2. Global Plugin Methods:
--    Attach new factory methods directly to `Context` (e.g. `function Context:createCustomWidget(options)`)
--    in external files or plugins; all context instances immediately inherit them via `__index`.
-- 3. Context Lifecycle Hooks:
--    Additional context-level teardown (e.g. `uiContext:destroy()`) can be registered to clear
--    allocated pools and disconnect registered layout models.
-------------------------------------------------------------------------------
