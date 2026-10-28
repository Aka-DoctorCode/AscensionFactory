-------------------------------------------------------------------------------
-- Project: AscensionFactory
-- Author: Aka-DoctorCode
-- File: Tooltip.lua
-------------------------------------------------------------------------------
---@diagnostic disable: undefined-global, undefined-field, inject-field

-------------------------------------------------------------------------------
-- 1. INITIALIZATION & NAMESPACE REGISTRATION
-- Objective: Register the Tooltip component and attach constructor methods to Context.
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
-- 2. TOOLTIP COMPONENT FACTORY
-- Objective: Custom styled Obsidian Cyberpunk tooltip element.
-- Variables:
-- options (table): Configuration table for initial sizing and styling.
-- tooltip (table): Frame object configured with borders, title, and body text.
-------------------------------------------------------------------------------

--- Creates an isolated Obsidian Cyberpunk styled tooltip instance.
--- @param options table|nil Configuration options.
--- @return table tooltip The configured tooltip frame.
function Context:createTooltip(options)
    options = options or {}
    local styles = self.styles
    local maxWidth = options.maxWidth or 280
    local minWidth = options.minWidth or 160
    local padding = options.padding or 12

    -- 2.1 BASE FRAME (REUSING 01FRAME.LUA)
    local tooltip = self:createFrame({
        parent = options.parent or _G.UIParent,
        width = minWidth,
        height = 60,
        strata = "TOOLTIP",
        clamped = true,
        showCloseButton = false,
        movable = false,
        closableWithEscape = false,
        borderColor = options.borderColor or styles.colors.border,
        backgroundColor = options.backgroundColor or styles.colors.background,
        borderInset = 1
    })
    tooltip:SetFrameLevel(options.frameLevel or 500)
    tooltip:Hide()

    -- 2.2 TITLE FONTSTRING
    local title = tooltip:CreateFontString(nil, "OVERLAY", styles.fonts.label or "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", tooltip, "TOPLEFT", padding, -padding)
    title:SetPoint("RIGHT", tooltip, "RIGHT", -padding, 0)
    title:SetJustifyH("LEFT")
    local primary = styles.colors.primary or { 1.0, 0.38, 0.0, 1.0 }
    title:SetTextColor(unpack(primary))
    tooltip.title = title

    -- 2.3 DESCRIPTION FONTSTRING
    local desc = tooltip:CreateFontString(nil, "OVERLAY", styles.fonts.text or "GameFontHighlight")
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
    desc:SetWidth(maxWidth - (padding * 2))
    desc:SetJustifyH("LEFT")
    desc:SetSpacing(3)
    local textColor = styles.colors.white or { 0.92, 0.97, 1.0, 1.0 }
    desc:SetTextColor(unpack(textColor))
    tooltip.desc = desc

    -- 2.4 METHODS
    --- Displays the tooltip relative to a target UI element.
    --- @param targetElement table Frame to anchor the tooltip to.
    --- @param titleText string|nil Header title string.
    --- @param descText string Body text or description.
    --- @param anchorPoint string|nil Optional anchor position (e.g. "ANCHOR_RIGHT", "TOPRIGHT").
    function tooltip:showAt(targetElement, titleText, descText, anchorPoint)
        if not targetElement then return end

        if not descText or descText == "" then
            descText = titleText
            titleText = nil
        end

        if not descText or descText == "" then return end

        -- Type defense to guarantee string arguments for WoW FontString:SetText C API
        if titleText and type(titleText) ~= "string" then
            titleText = tostring(titleText)
        end
        if type(descText) ~= "string" then
            descText = tostring(descText)
        end

        -- Set text content
        if titleText and titleText ~= "" then
            self.title:SetText(titleText)
            self.title:Show()
            self.desc:ClearAllPoints()
            self.desc:SetPoint("TOPLEFT", self.title, "BOTTOMLEFT", 0, -6)
        else
            self.title:SetText("")
            self.title:Hide()
            self.desc:ClearAllPoints()
            self.desc:SetPoint("TOPLEFT", self, "TOPLEFT", padding, -padding)
        end

        self.desc:SetText(descText)

        -- Calculate dimensions dynamically
        local calculatedWidth = math.max(
            minWidth,
            math.min(maxWidth, (self.title:IsShown() and self.title:GetStringWidth() or 0) + (padding * 2)),
            self.desc:GetStringWidth() + (padding * 2)
        )
        self.desc:SetWidth(calculatedWidth - (padding * 2))

        local totalHeight = padding * 2 + self.desc:GetHeight()
        if self.title:IsShown() then
            totalHeight = totalHeight + self.title:GetHeight() + 6
        end

        self:SetSize(calculatedWidth, totalHeight)

        -- Anchoring relative to target
        self:ClearAllPoints()
        anchorPoint = anchorPoint or "ANCHOR_RIGHT"

        if anchorPoint == "ANCHOR_RIGHT" or anchorPoint == "TOPRIGHT" then
            self:SetPoint("BOTTOMLEFT", targetElement, "TOPRIGHT", 6, 0)
        elseif anchorPoint == "ANCHOR_LEFT" or anchorPoint == "TOPLEFT" then
            self:SetPoint("BOTTOMRIGHT", targetElement, "TOPLEFT", -6, 0)
        elseif anchorPoint == "ANCHOR_TOP" then
            self:SetPoint("BOTTOM", targetElement, "TOP", 0, 6)
        elseif anchorPoint == "ANCHOR_BOTTOM" then
            self:SetPoint("TOP", targetElement, "BOTTOM", 0, -6)
        elseif anchorPoint == "CURSOR" then
            local x, y = GetCursorPosition()
            local scale = _G.UIParent:GetEffectiveScale()
            self:SetPoint("BOTTOMLEFT", _G.UIParent, "BOTTOMLEFT", (x / scale) + 12, (y / scale) - 12)
        else
            self:SetPoint("BOTTOMLEFT", targetElement, anchorPoint, 6, 0)
        end

        self:Show()
    end

    --- Hides the tooltip.
    function tooltip:hideTooltip()
        self:Hide()
    end

    --- Attaches hover listeners directly to a frame.
    --- @param frame table Target UI widget.
    --- @param titleText string|nil Title text string.
    --- @param descText string Body description string.
    --- @param anchorPoint string|nil Anchor point.
    function tooltip:attachTo(frame, titleText, descText, anchorPoint)
        if not frame then return end

        frame:HookScript("OnEnter", function(selfTarget)
            tooltip:showAt(selfTarget, titleText, descText, anchorPoint)
        end)

        frame:HookScript("OnLeave", function()
            tooltip:hideTooltip()
        end)
    end

    return tooltip
end

--- Retrieves or creates the shared singleton custom tooltip instance for this context.
--- @return table tooltip The shared singleton tooltip frame.
function Context:getTooltip()
    if not self.sharedTooltip then
        self.sharedTooltip = self:createTooltip()
    end
    return self.sharedTooltip
end

Context.CreateTooltip = Context.createTooltip
Context.GetTooltip = Context.getTooltip

-------------------------------------------------------------------------------
-- 3. EXTENSION & EXPANSION NOTES
-- Objective: Guidelines for rich tags, item comparisons, and custom swatch previews.
--
-- How to expand:
-- 1. Keybind Badges:
--    Add an optional badge fontstring anchored at `TOPRIGHT` to display shortcuts (e.g. `[Ctrl+Click]`).
-- 2. Item Icon Previews:
--    Add an optional square texture thumbnail to render item or spell icons in the tooltip header.
-------------------------------------------------------------------------------
