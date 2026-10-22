-------------------------------------------------------------------------------
-- Project: AscensionFactory
-- Author: Aka-DoctorCode
-- File: Toggle.lua
-------------------------------------------------------------------------------
---@diagnostic disable: undefined-global, undefined-field, inject-field

-------------------------------------------------------------------------------
-- 1. INITIALIZATION
-- Objective: Import the core AscensionFactory library and Context.
-- This ensures the UI elements can be built upon the existing framework.
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
-- 2. TOGGLE FACTORY
-- Objective: Creates a binary toggle switch component (on/off).
-- Includes a sliding thumb animation and distinct color states.
-- Variables:
-- options (table): Configuration table (getter, setter, onClick callbacks).
-- toggle (table): The created Button element behaving as a toggle.
-- track, border, thumb (tables): Explicit texture layers forming the component visuals.
-- updateAppearance (function): Logic dictating thumb position and color changes.
-------------------------------------------------------------------------------
function Context:createToggle(options)
    local styles = self.styles
    local parent = options.parent or UIParent
    local height = options.height or 24
    local width = options.width or 52
    local padding = options.padding or 2
    
    -- Base mechanical interaction layer acquisition.
    -- Pulls a standard "Button" from pool. A button is used because it natively 
    -- captures OnClick, OnEnter, OnLeave mouse events from the WoW engine.
    local toggle = self:acquireElement("Button", parent, {
        width = width,
        height = height
    })
    
    if options.name then
        _G[options.name] = toggle
    end

    local point = options.point or options.anchorPoint or "TOPLEFT"
    local yOffset = options.yOffset or 0
    local xOffset = options.xOffset or 0
    local targetParent = options.relativeTo or parent

    if options.point or options.anchorPoint or options.xOffset or options.yOffset then
        toggle:ClearAllPoints()
        toggle:SetPoint(
            point,
            targetParent,
            options.relativePoint or point,
            xOffset,
            yOffset
        )
    end

    -- Maintain internal toggled state.
    -- If a getter function is provided in options, execute it to determine initial state.
    toggle.isOn = false
    if options.getter then
        toggle.isOn = options.getter()
    end
    
    -- Layer -2: Outer Framing Border Box explicitly created.
    if not toggle.border then
        local border = toggle:CreateTexture(nil, "BACKGROUND", nil, -2)
        toggle.border = border
    end
    
    -- Layer -1: Inner Track Background Surface Layer
    if not toggle.track then
        local track = toggle:CreateTexture(nil, "BACKGROUND", nil, -1)
        toggle.track = track
    end

    local isFlexRow = options.flexRow or (options.text ~= nil and options.text ~= "") or (options.label ~= nil and options.label ~= "")
    toggle.isFlexRow = isFlexRow

    if isFlexRow then
        local rightOffset = options.fluidRightOffset or options.rightOffset or -10
        if string.find(point, "TOP") then
            toggle:SetPoint("TOPRIGHT", targetParent, "TOPRIGHT", rightOffset, yOffset)
        elseif string.find(point, "BOTTOM") then
            toggle:SetPoint("BOTTOMRIGHT", targetParent, "BOTTOMRIGHT", rightOffset, yOffset)
        else
            toggle:SetPoint("RIGHT", targetParent, "RIGHT", rightOffset, yOffset)
        end

        -- Switch is right-aligned inside toggle row
        toggle.border:ClearAllPoints()
        toggle.border:SetPoint("RIGHT", toggle, "RIGHT", 0, 0)
        toggle.border:SetSize(width, height)

        toggle.track:ClearAllPoints()
        toggle.track:SetPoint("TOPLEFT", toggle.border, "TOPLEFT", 1, -1)
        toggle.track:SetPoint("BOTTOMRIGHT", toggle.border, "BOTTOMRIGHT", -1, 1)

        -- Text label is left-aligned and flexes up to the switch with automatic word wrap
        local labelText = options.text or options.label or ""
        local label = self:createLabel({
            parent = toggle,
            text = labelText
        })
        label:ClearAllPoints()
        label:SetPoint("LEFT", toggle, "LEFT", 0, 0)
        label:SetPoint("RIGHT", toggle.border, "LEFT", -8, 0)
        label:SetWordWrap(true)
        label:SetJustifyH("LEFT")
        toggle.label = label
    else
        toggle.border:ClearAllPoints()
        toggle.border:SetPoint("TOPLEFT", toggle, "TOPLEFT", -1, 1)
        toggle.border:SetPoint("BOTTOMRIGHT", toggle, "BOTTOMRIGHT", 1, -1)

        toggle.track:ClearAllPoints()
        toggle.track:SetAllPoints()
    end
    
    -- Layer 1: Solid Sliding Thumb Block
    if not toggle.thumb then
        local thumbSize = height - (padding * 2)
        local thumb = toggle:CreateTexture(nil, "ARTWORK")
        thumb:SetSize(thumbSize, thumbSize)
        toggle.thumb = thumb
    end

    -- Centralized visual state manager dictating colors and thumb animation.
    -- Called whenever the mouse interacts with the toggle or its state changes.
    local function updateAppearance(stateOverride)
        toggle.thumb:ClearAllPoints() -- Remove existing anchors before moving it.
        
        -- Animation/position logic: move thumb right if ON, left if OFF.
        local thumbAnchor = isFlexRow and toggle.border or toggle
        if toggle.isOn then
            toggle.thumb:SetPoint("RIGHT", thumbAnchor, "RIGHT", -padding, 0)
        else
            toggle.thumb:SetPoint("LEFT", thumbAnchor, "LEFT", padding, 0)
        end

        if not toggle:IsEnabled() then
            toggle.track:SetColorTexture(unpack(styles.colors.background))
            toggle.border:SetColorTexture(unpack(styles.colors.surfaceLight))
            toggle.thumb:SetColorTexture(unpack(styles.colors.surfaceHover))
            return
        end

        local state = stateOverride or (toggle:IsMouseOver() and "hover" or "normal")

        if not toggle.isOn then
            if state == "hover" then
                toggle.track:SetColorTexture(unpack(styles.colors.surfaceHover))
                toggle.border:SetColorTexture(unpack(styles.colors.steelHighlight))
                toggle.thumb:SetColorTexture(unpack(styles.colors.white))
            elseif state == "active" then
                toggle.track:SetColorTexture(unpack(styles.colors.surfaceDark))
                toggle.border:SetColorTexture(unpack(styles.colors.primaryActive))
                toggle.thumb:SetColorTexture(unpack(styles.colors.white))
            else
                toggle.track:SetColorTexture(unpack(styles.colors.background))
                toggle.border:SetColorTexture(unpack(styles.colors.surfaceLight))
                toggle.thumb:SetColorTexture(unpack(styles.colors.surfaceHover))
            end
        else
            if state == "hover" then
                toggle.track:SetColorTexture(unpack(styles.colors.surfaceHover))
                toggle.border:SetColorTexture(unpack(styles.colors.primaryHover))
                toggle.thumb:SetColorTexture(unpack(styles.colors.white))
            elseif state == "active" then
                toggle.track:SetColorTexture(unpack(styles.colors.surfaceDark))
                toggle.border:SetColorTexture(unpack(styles.colors.primaryActive))
                toggle.thumb:SetColorTexture(unpack(styles.colors.white))
            else
                toggle.track:SetColorTexture(unpack(styles.colors.surfaceLight))
                toggle.border:SetColorTexture(unpack(styles.colors.primary))
                toggle.thumb:SetColorTexture(unpack(styles.colors.white))
            end
        end
    end
    
    updateAppearance()
    
    -- Interactive Hover Setup
    if lib.UX and lib.UX.makeHoverable then
        lib.UX:makeHoverable(toggle, {
            tooltip = options.tooltip,
            onStateChange = function(self, state)
                updateAppearance(state)
            end
        })
    end
    
    -- Execute toggle state swap on click.
    -- When the button registers a click, flip the boolean `isOn` state.
    toggle:SetScript("OnClick", function(self)
        self.isOn = not self.isOn
        
        if options.setter then
            options.setter(self.isOn)
        end
        
        if self:IsMouseOver() then
            updateAppearance("hover")
        else
            updateAppearance("normal")
        end
        
        if options.onClick then
            options.onClick(self, self.isOn)
        end
    end)
    
    if not toggle.setState then
        toggle.setState = function(self, state)
            self.isOn = not not state
            updateAppearance()
        end
    end

    function toggle:setText(newText)
        if self.label and self.label.SetText then
            self.label:SetText(newText)
        end
    end
    toggle.SetText = toggle.setText

    function toggle:setFlexRow(enabled)
        self.isFlexRow = not not enabled
        updateAppearance()
    end

    if options.scripts then
        for scriptName, scriptFunction in pairs(options.scripts) do
            if toggle:HasScript(scriptName) then
                toggle:HookScript(scriptName, scriptFunction)
            else
                toggle:SetScript(scriptName, scriptFunction)
            end
        end
    end
    
    return toggle
end

-------------------------------------------------------------------------------
-- 3. EXTENSION & EXPANSION NOTES
-- Objective: Guidelines for toggle slide animations, side text labels, and tri-state switches.
--
-- How to expand:
-- 1. Smooth Slide Animation:
--    Add an `OnUpdate` interpolation ticker or Blizzard AnimationGroup to animate the thumb position
--    smoothly from left to right on state change.
-- 2. Integrated Inline Label:
--    Support `options.text` to anchor an adjacent label on the left or right of the toggle track automatically.
-- 3. Tri-State Mode:
--    Add support for intermediate/indeterminate states (OFF / AUTO / ON) by anchoring the thumb to center position.
-------------------------------------------------------------------------------
