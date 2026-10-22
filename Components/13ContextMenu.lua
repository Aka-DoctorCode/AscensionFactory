-------------------------------------------------------------------------------
-- Project: AscensionFactory
-- Author: Aka-DoctorCode
-- File: ContextMenu.lua
-------------------------------------------------------------------------------
---@diagnostic disable: undefined-global, undefined-field, inject-field

-------------------------------------------------------------------------------
-- 1. INITIALIZATION & NAMESPACE REGISTRATION
-- Objective: Register ContextMenu component in Context and UX namespaces.
-- Variables:
-- MAJOR (string): Namespace identifier for addon library.
-- lib (table): Resolved library instance.
-- Context (table): Object factory table.
-- UX (table): User experience helper table.
-------------------------------------------------------------------------------
local MAJOR = "AscensionFactory"
local lib = LibStub:GetLibrary(MAJOR)
if not lib then return end

local Context = lib.Context
if not Context then return end

local UX = lib.UX or {}
lib.UX = UX

-------------------------------------------------------------------------------
-- 2. CONTEXT MENU FACTORY
-- Objective: Obsidian Cyberpunk styled pop-up context menu for right-click interactions.
-- Variables:
-- options (table): Configuration table (items, minWidth, itemHeight, parent).
-- menu (table): Pop-up frame container.
-------------------------------------------------------------------------------

--- Creates an Obsidian Cyberpunk context menu instance.
--- @param options table Configuration parameters (items array, parent, etc.).
--- @return table menu The created context menu frame.
function Context:createContextMenu(options)
    options = options or {}
    local styles = self.styles
    local ux = lib.UX
    local items = options.items or {}
    local itemHeight = options.itemHeight or 22
    local minWidth = options.minWidth or 130
    local separatorHeight = 8

    -- Calculate total dimensions
    local totalHeight = 8
    local maxWidth = minWidth
    for _, item in ipairs(items) do
        if item.text == "---" then
            totalHeight = totalHeight + separatorHeight
        else
            totalHeight = totalHeight + itemHeight
            if item.text then
                local estWidth = (#item.text * 8) + 32
                if estWidth > maxWidth then
                    maxWidth = math.ceil(estWidth)
                end
            end
        end
    end

    -- 2.1 BASE FRAME (REUSING 01FRAME.LUA)
    local menu = self:createFrame({
        parent = options.parent or _G.UIParent,
        width = maxWidth,
        height = math.max(20, totalHeight),
        strata = "TOOLTIP",
        clamped = true,
        showCloseButton = false,
        movable = false,
        closableWithEscape = false,
        borderColor = styles.colors.border,
        backgroundColor = styles.colors.background,
        borderInset = 1
    })
    menu:SetFrameLevel(700)
    menu:Hide()

    -- Auto-dismiss on click outside
    if ux and ux.registerClickOutside then
        ux:registerClickOutside(menu, function()
            menu:Hide()
        end)
    end

    -- 2.2 POPULATE ITEMS
    local currentY = -4
    for _, item in ipairs(items) do
        if item.text == "---" then
            -- Separator line
            local line = menu:CreateTexture(nil, "ARTWORK")
            line:SetHeight(1)
            line:SetPoint("TOPLEFT", menu, "TOPLEFT", 6, currentY - 4)
            line:SetPoint("TOPRIGHT", menu, "TOPRIGHT", -6, currentY - 4)
            line:SetColorTexture(unpack(styles.colors.border or { 0.078, 0.102, 0.141, 1.0 }))
            currentY = currentY - separatorHeight
        else
            local btn = self:createButton({
                parent = menu,
                width = maxWidth - 10,
                height = itemHeight,
                text = item.text,
                point = "TOPLEFT",
                relativeTo = menu,
                relativePoint = "TOPLEFT",
                xOffset = 5,
                yOffset = currentY,
                tooltip = item.tooltip,
                trackColors = {
                    normal = { 0, 0, 0, 0 },
                    hover = styles.colors.surfaceHover or { 0.055, 0.075, 0.110, 0.95 },
                    active = styles.colors.primaryActive or { 0.700, 0.220, 0.000, 1.00 },
                    disabled = { 0, 0, 0, 0 }
                },
                borderColors = {
                    normal = { 0, 0, 0, 0 },
                    hover = styles.colors.primary or { 1.0, 0.38, 0.0, 1.0 },
                    active = styles.colors.primaryActive or { 0.700, 0.220, 0.000, 1.00 },
                    disabled = { 0, 0, 0, 0 }
                },
                onClick = function()
                    menu:Hide()
                    local callback = item.func or item.onClick
                    if callback then
                        callback()
                    end
                end
            })

            local btnLabel = btn.label or (btn.GetFontString and btn:GetFontString())
            if btnLabel then
                btnLabel:ClearAllPoints()
                btnLabel:SetPoint("LEFT", btn, "LEFT", 8, 0)
                btnLabel:SetJustifyH("LEFT")
                if item.color then
                    btnLabel:SetTextColor(unpack(item.color))
                end
            end

            currentY = currentY - itemHeight
        end
    end

    return menu
end

Context.CreateContextMenu = Context.createContextMenu

-------------------------------------------------------------------------------
-- 3. UX HELPERS & SHORTCUT API
-- Objective: Quick-display context menus at mouse cursor with standard action helpers.
-------------------------------------------------------------------------------

--- Displays a context menu at the current cursor position.
--- @param parent table The parent frame requesting the menu.
--- @param items table Array of item tables ({ text = "...", func = function() end }).
--- @param config table|nil Optional persistence config (locked, point, x, y) for auto-adding Lock/Reset actions.
--- @return table menu The active context menu frame.
function UX:showContextMenu(parent, items, config)
    local menuItems = {}

    -- 1. Add user-provided items
    if items then
        for _, it in ipairs(items) do
            table.insert(menuItems, it)
        end
    end

    -- 2. Add standard actions if config table is passed
    if config then
        if #menuItems > 0 then
            table.insert(menuItems, { text = "---" })
        end

        UX:addLockButton(menuItems, parent, config)
        UX:addResetPositionButton(menuItems, parent, config)
    end

    -- Close previous active menu if still shown
    if UX.activeContextMenu and UX.activeContextMenu.Hide then
        UX.activeContextMenu:Hide()
    end

    local uiContext = (parent and parent.uiContext) or lib.Context or lib:createContext()
    local menu = uiContext:createContextMenu({
        parent = _G.UIParent,
        items = menuItems
    })

    UX.activeContextMenu = menu

    -- Position at mouse cursor
    local cursorX, cursorY = GetCursorPosition()
    local scale = _G.UIParent:GetEffectiveScale()
    local posX = (cursorX / scale) + 4
    local posY = (cursorY / scale) - 4

    menu:ClearAllPoints()
    menu:SetPoint("TOPLEFT", _G.UIParent, "BOTTOMLEFT", posX, posY)
    menu:Show()

    return menu
end

--- Adds a Lock/Unlock Position toggle item to a context menu items table.
--- @param items table The menu items array.
--- @param targetFrame table The frame being locked or unlocked.
--- @param config table Table with a `.locked` boolean property.
function UX:addLockButton(items, targetFrame, config)
    table.insert(items, {
        text = config.locked and "Unlock Position" or "Lock Position",
        func = function()
            config.locked = not config.locked
            if targetFrame and targetFrame.SetMovable then
                targetFrame:SetMovable(not config.locked)
                if targetFrame.EnableMouse then
                    targetFrame:EnableMouse(not config.locked)
                end
            end
        end
    })
end

--- Adds a Reset Position action item to a context menu items table.
--- @param items table The menu items array.
--- @param targetFrame table The frame to reset.
--- @param config table Table with coordinates (.point, .x, .y).
function UX:addResetPositionButton(items, targetFrame, config)
    table.insert(items, {
        text = "Reset Position",
        func = function()
            config.point = "CENTER"
            config.relativePoint = "CENTER"
            config.x = 0
            config.y = 0
            if targetFrame then
                targetFrame:ClearAllPoints()
                targetFrame:SetPoint("CENTER", _G.UIParent, "CENTER", 0, 0)
            end
        end
    })
end

--- Adds an Options button to a context menu items table.
--- @param items table The menu items array.
--- @param onClick function Callback function to open addon options.
function UX:addOptionsButton(items, onClick)
    table.insert(items, {
        text = "Options",
        func = onClick
    })
end

UX.ShowContextMenu = UX.showContextMenu
UX.AddLockButton = UX.addLockButton
UX.AddResetPositionButton = UX.addResetPositionButton
UX.AddOptionsButton = UX.addOptionsButton

-------------------------------------------------------------------------------
-- 4. EXTENSION & EXPANSION NOTES
-- Objective: Guidelines for sub-menus, icons on items, and radio/checkbox menu options.
--
-- How to expand:
-- 1. Context Sub-Menus:
--    Add a `.submenu` property to an item to open a secondary cascading menu on hover.
-- 2. Toggle Checkmarks:
--    Add `.checked` property to render a vector checkmark alongside the item text.
-------------------------------------------------------------------------------
