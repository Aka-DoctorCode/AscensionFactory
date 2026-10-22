-------------------------------------------------------------------------------
-- Project: AscensionFactory
-- Author: Aka-DoctorCode
-- File: Dropdown.lua
-------------------------------------------------------------------------------
---@diagnostic disable: undefined-global, undefined-field, inject-field

-------------------------------------------------------------------------------
-- 1. INITIALIZATION & NAMESPACE REGISTRATION
-- Objective: Register Dropdown component and attach factory constructor to Context.
-- Variables:
-- MAJOR (string): Namespace identifier for addon library.
-- lib (table): Resolved library instance.
-- Context (table): Object factory table.
-------------------------------------------------------------------------------
local MAJOR = "AscensionFactory"
local lib = LibStub:GetLibrary(MAJOR)
if not lib then return end

local Context = lib.Context
if not Context then return end

-------------------------------------------------------------------------------
-- 2. DROPDOWN COMPONENT FACTORY
-- Objective: Obsidian Cyberpunk styled dropdown menu with scrollable options list.
-- Variables:
-- options (table): Configuration options (parent, options, getter, setter, placeholder, etc.).
-- dropdown (table): Trigger button and master container for selection.
-------------------------------------------------------------------------------

--- Creates an Obsidian Cyberpunk styled dropdown menu component.
--- @param options table Configuration parameters.
--- @return table dropdown The interactive dropdown widget.
function Context:createDropdown(options)
    options = options or {}
    local styles = self.styles
    local ux = lib.UX
    local parent = options.parent or _G.UIParent

    local width = options.width or 160
    local height = options.height or 26
    local itemHeight = options.itemHeight or 24
    local maxVisibleItems = options.maxVisibleItems or 6
    local placeholder = options.placeholder or "Select..."
    local rawOptionsList = options.options or {}

    -- 2.1 NORMALIZE OPTIONS DATA
    local function normalizeItem(item)
        if type(item) == "table" then
            return {
                label = tostring(item.label or item.text or item.name or item.value or ""),
                value = item.value ~= nil and item.value or item.label or item.text,
                tooltip = item.tooltip
            }
        else
            return {
                label = tostring(item),
                value = item,
                tooltip = nil
            }
        end
    end

    local normalizedOptions = {}
    for _, item in ipairs(rawOptionsList) do
        table.insert(normalizedOptions, normalizeItem(item))
    end

    local isFluid = options.fluidWidth or false

    -- 2.2 TRIGGER BUTTON (REUSING 05BUTTON.LUA)
    local dropdown = self:createButton({
        parent = parent,
        name = options.name,
        width = width,
        height = height,
        text = "",
        point = options.point or options.anchorPoint,
        relativeTo = options.relativeTo or parent,
        relativePoint = options.relativePoint or options.point,
        xOffset = options.xOffset or 0,
        yOffset = options.yOffset or 0,
        tooltip = options.tooltip
    })
    dropdown.uiContext = self
    dropdown.fluidWidth = isFluid

    if isFluid then
        local point = options.point or options.anchorPoint or "TOPLEFT"
        local yOffset = options.yOffset or 0
        local targetParent = options.relativeTo or parent
        local rightOffset = options.fluidRightOffset or options.rightOffset or -10
        if string.find(point, "TOP") then
            dropdown:SetPoint("TOPRIGHT", targetParent, "TOPRIGHT", rightOffset, yOffset)
        elseif string.find(point, "BOTTOM") then
            dropdown:SetPoint("BOTTOMRIGHT", targetParent, "BOTTOMRIGHT", rightOffset, yOffset)
        else
            dropdown:SetPoint("RIGHT", targetParent, "RIGHT", rightOffset, yOffset)
        end
    end

    -- Left-align text inside trigger button
    local triggerLabel = dropdown.label or (dropdown.GetFontString and dropdown:GetFontString())
    if triggerLabel then
        triggerLabel:ClearAllPoints()
        triggerLabel:SetPoint("LEFT", dropdown, "LEFT", 10, 0)
        triggerLabel:SetPoint("RIGHT", dropdown, "RIGHT", -26, 0)
        triggerLabel:SetJustifyH("LEFT")
    end

    -- Arrow Icon Indicator (Right-aligned)
    local arrowIcon
    if self.createIconButton then
        arrowIcon = self:createIconButton({
            parent = dropdown,
            size = height - 6,
            iconType = "arrowdown",
            point = "RIGHT",
            relativeTo = dropdown,
            relativePoint = "RIGHT",
            xOffset = -4,
            yOffset = 0,
            iconColor = styles.colors.primary or { 1.0, 0.38, 0.0, 1.0 },
            onClick = function()
                dropdown:toggle()
            end
        })
        dropdown.arrowIcon = arrowIcon
    end

    -- 2.3 POPUP LIST FRAME (REUSING 01FRAME.LUA)
    local listFrame = self:createFrame({
        parent = _G.UIParent,
        width = width,
        height = 100,
        strata = "TOOLTIP",
        clamped = true,
        showCloseButton = false,
        movable = false,
        closableWithEscape = false,
        borderColor = styles.colors.primary or styles.colors.border,
        backgroundColor = styles.colors.background,
        borderInset = 1
    })
    listFrame:SetFrameLevel(600)
    listFrame:Hide()
    dropdown.listFrame = listFrame

    -- Click outside detection
    if ux and ux.registerClickOutside then
        ux:registerClickOutside(listFrame, function()
            dropdown:close()
        end)
    end

    -- 2.4 SCROLLABLE ITEMS CONTAINER (REUSING UX:MAKESCROLLABLE & 09SLIDER)
    local scrollFrame, contentChild, scrollbar = ux:makeScrollable(listFrame, {
        uiContext = self,
        scrollBarWidth = 10,
        scrollBarGap = 2,
        step = itemHeight,
        autoHideScrollBar = true
    })
    dropdown.scrollFrame = scrollFrame
    dropdown.contentChild = contentChild
    dropdown.scrollbar = scrollbar

    -- 2.5 POPULATE AND REBUILD ITEMS
    local itemButtons = {}

    local function rebuildItems()
        -- Clean up existing buttons
        for _, btn in ipairs(itemButtons) do
            btn:Hide()
            btn:ClearAllPoints()
        end
        wipe(itemButtons)

        local currentDropWidth = math.max(60, (dropdown:GetWidth() > 0 and dropdown:GetWidth()) or width)
        local totalCount = #normalizedOptions
        local visibleCount = math.min(totalCount, maxVisibleItems)
        local totalListHeight = math.max(itemHeight + 8, (visibleCount * itemHeight) + 8)

        listFrame:SetSize(currentDropWidth, totalListHeight)

        local currentY = -4
        for i, opt in ipairs(normalizedOptions) do
            local itemBtn = self:createButton({
                parent = contentChild,
                width = currentDropWidth - (totalCount > maxVisibleItems and 18 or 10),
                height = itemHeight,
                text = opt.label,
                point = "TOPLEFT",
                relativeTo = contentChild,
                relativePoint = "TOPLEFT",
                xOffset = 5,
                yOffset = currentY,
                tooltip = opt.tooltip,
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
                    dropdown:setValue(opt.value, false)
                    dropdown:close()
                end
            })

            local itemLabel = itemBtn.label or (itemBtn.GetFontString and itemBtn:GetFontString())
            if itemLabel then
                itemLabel:ClearAllPoints()
                itemLabel:SetPoint("LEFT", itemBtn, "LEFT", 8, 0)
                itemLabel:SetJustifyH("LEFT")
            end

            table.insert(itemButtons, itemBtn)
            currentY = currentY - itemHeight
        end

        contentChild:SetHeight(math.abs(currentY) + 4)
        if listFrame.updateScrollRange then
            listFrame:updateScrollRange()
        end
    end

    -- 2.6 STATE MANAGEMENT
    local currentValue = nil

    local function updateTriggerText()
        local labelText = placeholder
        for _, opt in ipairs(normalizedOptions) do
            if opt.value == currentValue then
                labelText = opt.label
                break
            end
        end

        if dropdown.SetText then
            dropdown:SetText(labelText)
        end
        local lbl = dropdown.label or (dropdown.GetFontString and dropdown:GetFontString())
        if lbl and lbl.SetText then
            lbl:SetText(labelText)
        end
    end

    -- 2.7 PUBLIC METHODS
    function dropdown:open()
        if not self:IsEnabled() then return end

        listFrame:ClearAllPoints()
        listFrame:SetPoint("TOPLEFT", dropdown, "BOTTOMLEFT", 0, -2)
        listFrame:Show()
        rebuildItems()

        if self.arrowIcon and self.arrowIcon.setNormalColor then
            self.arrowIcon:setNormalColor(styles.colors.primaryHover or { 1, 0.54, 0.05, 1 })
        end
    end

    function dropdown:close()
        listFrame:Hide()
        if self.arrowIcon and self.arrowIcon.setNormalColor then
            self.arrowIcon:setNormalColor(styles.colors.primary or { 1, 0.38, 0, 1 })
        end
    end

    function dropdown:toggle()
        if listFrame:IsShown() then
            self:close()
        else
            self:open()
        end
    end

    function dropdown:getValue()
        return currentValue
    end

    function dropdown:setValue(val, isSilent)
        currentValue = val
        updateTriggerText()

        if not isSilent then
            if options.setter then
                options.setter(val)
            end
            if options.onValueChanged then
                local selectedItem
                for _, opt in ipairs(normalizedOptions) do
                    if opt.value == val then
                        selectedItem = opt
                        break
                    end
                end
                options.onValueChanged(dropdown, val, selectedItem)
            end
        end
    end

    function dropdown:setOptions(newList)
        rawOptionsList = newList or {}
        wipe(normalizedOptions)
        for _, item in ipairs(rawOptionsList) do
            table.insert(normalizedOptions, normalizeItem(item))
        end
        updateTriggerText()
        if listFrame:IsShown() then
            rebuildItems()
        end
    end

    -- Set trigger click
    dropdown:SetScript("OnClick", function()
        dropdown:toggle()
    end)

    dropdown:HookScript("OnSizeChanged", function(self, newW, newH)
        if listFrame and listFrame:IsShown() and newW and newW > 0 then
            rebuildItems()
        end
    end)

    -- Initial value resolution
    if options.getter then
        dropdown:setValue(options.getter(), true)
    elseif options.value ~= nil or options.defaultValue ~= nil then
        dropdown:setValue(options.value or options.defaultValue, true)
    else
        updateTriggerText()
    end

    -- API Aliases
    dropdown.GetValue = dropdown.getValue
    dropdown.SetValue = dropdown.setValue
    dropdown.SetOptions = dropdown.setOptions
    dropdown.Open = dropdown.open
    dropdown.Close = dropdown.close
    dropdown.Toggle = dropdown.toggle

    return dropdown
end

Context.CreateDropdown = Context.createDropdown

-------------------------------------------------------------------------------
-- 3. EXTENSION & EXPANSION NOTES
-- Objective: Guidelines for searchable dropdowns, multi-select checkboxes, and section dividers.
--
-- How to expand:
-- 1. Search Filter:
--    Add an `InputField` at the top of `listFrame` to filter `normalizedOptions` dynamically on text entry.
-- 2. Multi-Select Mode:
--    Add `multiSelect = true` option to render checkboxes on each option and return a table of values.
-------------------------------------------------------------------------------
