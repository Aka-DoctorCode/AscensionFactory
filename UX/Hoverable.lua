-------------------------------------------------------------------------------
-- Project: AscensionFactory
-- Author: Aka-DoctorCode
-- File: Hoverable.lua
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
-- 2. HOVER AND INTERACTION LOGIC
-- Objective: Standardizes hover, press, release, disable, and tooltip behaviors across all UI elements.
-- Variables:
-- element (table): The UI frame or button to make interactive.
-- config (table, optional): Custom configuration table with colors, tooltip, or onStateChange callback.
-------------------------------------------------------------------------------
--- Configures an element with standard hover, press, disable visual states and optional tooltip.
function UX:makeHoverable(element, config)
    if not element then return end
    element.hoverConfig = config or {}

    local styles = (element.uiContext and element.uiContext.styles) or lib.defaultStyles or lib.DefaultStyles or {}
    local colors = styles.colors or {}

    -- Resolve textures and text elements
    local track = config.track or element.track or element.boxTrack
    local border = config.border or element.border or element.boxBorder
    local label = config.label or element.label or (element.GetFontString and element:GetFontString())

    -- State Color Configuration Registry
    local trackColors = config.trackColors or element.trackColors or {
        normal = colors.surfaceLight,
        hover = colors.surfaceHover,
        active = colors.surfaceDark,
        disabled = colors.background
    }

    local borderColors = config.borderColors or element.borderColors or {
        normal = colors.border or colors.surfaceLight,
        hover = colors.primaryHover,
        active = colors.primaryActive,
        disabled = colors.border or colors.surfaceLight
    }

    local labelColors = config.labelColors or element.labelColors or {
        normal = colors.white,
        hover = colors.primaryHover,
        active = colors.white,
        disabled = colors.surfaceHover
    }

    -- Centralized Render Processing Engine
    local function applyAppearance(stateOverride)
        local isEnabled = not element.IsEnabled or element:IsEnabled()
        local state

        if not isEnabled then
            state = "disabled"
        elseif stateOverride then
            state = stateOverride
        elseif element.IsMouseOver and element:IsMouseOver() then
            state = "hover"
        else
            state = "normal"
        end

        local currentConfig = element.hoverConfig or config
        -- Custom state callback override if provided by component (replaces default coloring)
        if currentConfig.onStateChange then
            currentConfig.onStateChange(element, state)
            return
        end

        -- Default visual state coloring
        if track and trackColors[state] then
            track:SetColorTexture(unpack(trackColors[state]))
        end

        if border and borderColors[state] then
            border:SetColorTexture(unpack(borderColors[state]))
        end

        if label and labelColors[state] then
            label:SetTextColor(unpack(labelColors[state]))
        end

        -- Post-coloring hook for composed components (runs after default coloring)
        if currentConfig.onAfterStateChange then
            currentConfig.onAfterStateChange(element, state)
        end
    end

    element.updateAppearance = applyAppearance
    applyAppearance("normal")

    -- Tooltip Handlers
    local function showTooltip()
        local currentConfig = element.hoverConfig or config
        if not currentConfig.tooltip then return end
        local tooltipData
        if type(currentConfig.tooltip) == "function" then
            tooltipData = currentConfig.tooltip(element)
        else
            tooltipData = currentConfig.tooltip
        end
        if not tooltipData then return end

        local uiContext = element.uiContext or (element.hoverConfig and element.hoverConfig.uiContext) or (config and config.uiContext) or lib.Context
        if uiContext and uiContext.getTooltip then
            local customTooltip = uiContext:getTooltip()
            if customTooltip then
                local title, desc
                if type(tooltipData) == "table" then
                    title = tooltipData.title or tooltipData[1]
                    desc = tooltipData.desc or tooltipData.description or tooltipData[2]
                else
                    desc = tooltipData
                end
                customTooltip:showAt(element, title, desc, currentConfig.tooltipAnchor)
                return
            end
        end

        -- Fallback to standard GameTooltip
        local tooltipText = type(tooltipData) == "string" and tooltipData or tostring(tooltipData)
        if tooltipText and tooltipText ~= "" then
            GameTooltip:SetOwner(element, currentConfig.tooltipAnchor or "ANCHOR_RIGHT")
            GameTooltip:SetText(tooltipText, 1, 1, 1, 1, true)
            GameTooltip:Show()
        end
    end

    local function hideTooltip()
        local uiContext = element.uiContext or (element.hoverConfig and element.hoverConfig.uiContext) or (config and config.uiContext) or lib.Context
        if uiContext and uiContext.getTooltip then
            local customTooltip = uiContext:getTooltip()
            if customTooltip and customTooltip:IsShown() then
                customTooltip:hideTooltip()
            end
        end

        if GameTooltip:GetOwner() == element then
            GameTooltip:Hide()
        end
    end

    -- Hook once per frame instance to avoid closure stacking when frames are recycled
    if not element.isHoverableHooked then
        element.isHoverableHooked = true

        element:HookScript("OnEnter", function(self)
            if self.IsEnabled and not self:IsEnabled() then return end
            if self.updateAppearance then self.updateAppearance("hover") end
            showTooltip()
        end)

        element:HookScript("OnLeave", function(self)
            if self.IsEnabled and not self:IsEnabled() then return end
            if self.updateAppearance then self.updateAppearance("normal") end
            hideTooltip()
        end)

        element:HookScript("OnMouseDown", function(self)
            if self.IsEnabled and not self:IsEnabled() then return end
            if self.updateAppearance then self.updateAppearance("active") end
        end)

        element:HookScript("OnMouseUp", function(self)
            if self.IsEnabled and not self:IsEnabled() then return end
            if self.updateAppearance then
                self.updateAppearance(self:IsMouseOver() and "hover" or "normal")
            end
        end)

        if element.HasScript and element:HasScript("OnEnable") then
            element:HookScript("OnEnable", function(self)
                if self.updateAppearance then
                    self.updateAppearance(self:IsMouseOver() and "hover" or "normal")
                end
            end)
        end

        if element.HasScript and element:HasScript("OnDisable") then
            element:HookScript("OnDisable", function(self)
                if self.updateAppearance then
                    self.updateAppearance("disabled")
                end
                hideTooltip()
            end)
        end
    end

    return element
end

-------------------------------------------------------------------------------
-- 3. EXTENSION & EXPANSION NOTES
-- Objective: Guidelines for adding custom hover animations, sound triggers, and rich tooltips.
--
-- How to expand:
-- 1. Sound Integration:
--    Hook `SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON` or custom audio cues into `OnMouseDown` / `OnEnter`
--    via `config.soundOnEnter` / `config.soundOnClick`.
-- 2. State Callbacks:
--    Use `config.onStateChange(element, state)` to replace default coloring entirely,
--    or `config.onAfterStateChange(element, state)` to update custom sub-layer textures (e.g. checkmarks, icons).
-- 3. Dynamic Tooltips:
--    Pass a function `config.tooltip = function(element) return "..." end` to re-compute
--    tooltip strings dynamically based on current game state upon mouseover.
-------------------------------------------------------------------------------
