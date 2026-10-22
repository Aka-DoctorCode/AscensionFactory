-------------------------------------------------------------------------------
-- Project: AscensionFactory
-- Author: Aka-DoctorCode
-- File: Button.lua
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
-- 2. BUTTON FACTORY
-- Objective: Creates a fully interactive, styled standard button element.
-- Integrates explicit textures, a text label, and multiple interaction states (hover, active, disabled).
-- Variables:
-- options (table): Configuration table including width, height, text, and click callbacks.
-- button (table): The allocated Button frame instance.
-- updateAppearance (function): Centralized engine that changes texture colors based on the interaction state.
-------------------------------------------------------------------------------
function Context:createButton(options)
    local styles = self.styles
    local parent = options.parent or UIParent
    local width = options.width or 60
    local height = options.height or 25
    
    -- 2.1 BASE FRAME SETUP
    -- Acquire base "Button" frame from pool. The WoW Button object can receive click and mouseover events.
    local button = self:acquireElement("Button", parent, {
        width = width,
        height = height
    })

    -- Register the element in global space if a name is specified.
    -- By setting _G[name], the frame is globally accessible via that variable.
    if options.name then
        _G[options.name] = button
    end

    if options.point or options.anchorPoint or options.xOffset or options.yOffset then
        button:ClearAllPoints()
        button:SetPoint(
            options.point or options.anchorPoint or "TOPLEFT",
            options.relativeTo or parent,
            options.relativePoint or options.point or options.anchorPoint or "TOPLEFT",
            options.xOffset or 0,
            options.yOffset or 0
        )
    end
    
    -- 2.2 EXPLICIT LAYER TEXTURE CREATION
    -- Create the outer border texture dynamically on background layer -2.
    if not button.border then
        local border = button:CreateTexture(nil, "BACKGROUND", nil, -2)
        border:SetAllPoints(button)
        button.border = border
    end
    button.border:Show()

    -- Create the inner track texture dynamically on background layer -1
    if not button.track then
        local track = button:CreateTexture(nil, "BACKGROUND", nil, -1)
        button.track = track
    end
    button.track:ClearAllPoints()
    button.track:SetPoint("TOPLEFT", button, "TOPLEFT", 2, -2)
    button.track:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)
    button.track:Show()

    -- State Color Configuration Registry
    button.trackColors = options.trackColors or {
        normal = styles.colors.surfaceLight,
        hover = styles.colors.surfaceHover,
        active = styles.colors.surfaceDark,
        disabled = styles.colors.background
    }
    button.borderColors = options.borderColors or {
        normal = styles.colors.border,
        hover = styles.colors.primaryHover,
        active = styles.colors.primaryActive,
        disabled = styles.colors.surfaceLight
    }
    button.labelColors = options.labelColors or {
        normal = styles.colors.white,
        hover = styles.colors.primaryHover,
        active = styles.colors.white,
        disabled = styles.colors.surfaceHover
    }

    -- 2.3 TEXT LABEL SETUP
    local buttonText = self:createLabel({
        parent = button,
        text = options.text or ""
    })
    buttonText:SetPoint("CENTER", button, "CENTER", 0, 0)
    buttonText:SetWidth(width - 10)
    buttonText:SetWordWrap(false)
    button:SetFontString(buttonText)

    -- 2.4 INTERACTIVE HOVER SETUP
    if lib.UX and lib.UX.makeHoverable then
        lib.UX:makeHoverable(button, {
            tooltip = options.tooltip,
            track = button.track,
            border = button.border,
            label = buttonText,
            trackColors = button.trackColors,
            borderColors = button.borderColors,
            labelColors = button.labelColors,
            onStateChange = options.onStateChange,
            onAfterStateChange = options.onAfterStateChange
        })
    end
    
    -- 2.6 CLICK EVENT REGISTRATION
    -- Setup accepted click inputs (e.g. LeftButtonUp, RightButtonUp) and route to user callback.
    -- RegisterForClicks tells the WoW UI engine which mouse events to capture for this frame.
    button:RegisterForClicks(unpack(options.clickTypes or { "AnyUp" }))

    -- If a custom onClick function was provided, bind it to the "OnClick" script handler.
    if type(options.onClick) == "function" then
        button:SetScript("OnClick", options.onClick)
    end

    -- 2.7 INSTANCE PROPERTIES & ALIASES
    button.label = buttonText
    button.setText = function(self, text) self:SetText(text) end
    button.getText = function(self) return self:GetText() end
    
    return button
end

-------------------------------------------------------------------------------
-- 3. ICON BUTTON FACTORY
-- Objective: Creates a specialized square button with a centered geometric icon.
-- Uses the base button logic but overlays dynamically drawn textures for the icon.
-- Variables:
-- options (table): Inherits button options but forces square dimensions and adds `iconType`.
-- iconType (string): Determines the shape (e.g., "close", "minus", "plus").
-- color (table): RGBA color values for the icon drawing.
-------------------------------------------------------------------------------
function Context:createIconButton(options)
    local size = options.size or 24
    options.width = size
    options.height = size
    options.text = ""

    -- 3.1 BASE BUTTON INHERITANCE
    local button = self:createButton(options)
    local iconType = options.iconType or "close"
    local color = options.iconColor or self.styles.colors.white

    -- 3.2 ICON RENDERING
    if iconType == "minus" then
        local minusLine = self:acquireElement("Texture", button, { drawLayer = "ARTWORK" })
        minusLine:SetSize(size * 0.5, 3)
        minusLine:SetPoint("CENTER")
        minusLine:SetColorTexture(unpack(color))
    elseif iconType == "plus" then
        local horizontalLine = self:acquireElement("Texture", button, { drawLayer = "ARTWORK" })
        horizontalLine:SetSize(size * 0.5, 3)
        horizontalLine:SetPoint("CENTER")
        horizontalLine:SetColorTexture(unpack(color))

        local verticalLine = self:acquireElement("Texture", button, { drawLayer = "ARTWORK" })
        verticalLine:SetSize(3, size * 0.5)
        verticalLine:SetPoint("CENTER")
        verticalLine:SetColorTexture(unpack(color))
    elseif iconType == "minimize" then
        local minimizeLine = self:acquireElement("Texture", button, { drawLayer = "ARTWORK" })
        minimizeLine:SetSize(size * 0.5, 3)
        minimizeLine:SetPoint("BOTTOM", 0, size * 0.25)
        minimizeLine:SetColorTexture(unpack(color))
    elseif iconType == "maximize" then
        local iconSize = size * 0.5
        local lineThickness = 3
        local topLine = self:acquireElement("Texture", button, { drawLayer = "ARTWORK" })
        topLine:SetSize(iconSize, lineThickness)
        topLine:SetPoint("TOP", 0, -size * 0.25)
        topLine:SetColorTexture(unpack(color))
        
        local bottomLine = self:acquireElement("Texture", button, { drawLayer = "ARTWORK" })
        bottomLine:SetSize(iconSize, lineThickness)
        bottomLine:SetPoint("BOTTOM", 0, size * 0.25)
        bottomLine:SetColorTexture(unpack(color))
        
        local leftLine = self:acquireElement("Texture", button, { drawLayer = "ARTWORK" })
        leftLine:SetSize(lineThickness, iconSize)
        leftLine:SetPoint("LEFT", size * 0.25, 0)
        leftLine:SetColorTexture(unpack(color))
        
        local rightLine = self:acquireElement("Texture", button, { drawLayer = "ARTWORK" })
        rightLine:SetSize(lineThickness, iconSize)
        rightLine:SetPoint("RIGHT", -size * 0.25, 0)
        rightLine:SetColorTexture(unpack(color))
    elseif iconType == "arrowdown" or iconType == "arrowup" or iconType == "arrowleft" or iconType == "arrowright" then
        local arrowTexture = self:acquireElement("Texture", button, { drawLayer = "ARTWORK" })
        arrowTexture:SetSize(size * 0.75, size * 0.75)
        arrowTexture:SetPoint("CENTER")
        arrowTexture:SetTexture("Interface\\ChatFrame\\ChatFrameExpandArrow")
        arrowTexture:SetDesaturated(true)
        if iconType == "arrowdown" then
            arrowTexture:SetRotation(math.rad(-90))
        elseif iconType == "arrowup" then
            arrowTexture:SetRotation(math.rad(90))
        elseif iconType == "arrowleft" then
            arrowTexture:SetRotation(math.rad(180))
        else -- arrowright
            arrowTexture:SetRotation(0)
        end
        arrowTexture:SetVertexColor(unpack(color or self.styles.colors.white))
        button.iconTexture = arrowTexture

        function button:setIconRotation(angleDegrees)
            if self.iconTexture and self.iconTexture.SetRotation then
                self.iconTexture:SetRotation(math.rad(angleDegrees))
            end
        end
    elseif iconType == "close" then
        local diagonalLineOne = self:acquireElement("Texture", button, { drawLayer = "ARTWORK" })
        diagonalLineOne:SetSize(size * 0.5, 3)
        diagonalLineOne:SetPoint("CENTER")
        diagonalLineOne:SetColorTexture(unpack(color))
        diagonalLineOne:SetRotation(math.rad(45))

        local diagonalLineTwo = self:acquireElement("Texture", button, { drawLayer = "ARTWORK" })
        diagonalLineTwo:SetSize(3, size * 0.5)
        diagonalLineTwo:SetPoint("CENTER")
        diagonalLineTwo:SetColorTexture(unpack(color))
        diagonalLineTwo:SetRotation(math.rad(45))
        
        local redNormal = self.styles.colors.neonRed
        local redHover = self.styles.colors.redHover
        local redActive = self.styles.colors.redActive
        
        -- Override theme settings directly with dedicated red pattern
        button.trackColors.normal = redNormal
        button.borderColors.normal = redNormal
        button.trackColors.hover = redHover
        button.borderColors.hover = redHover
        button.trackColors.active = redActive
        button.borderColors.active = redActive
        
        button.updateAppearance()
    end

    return button
end

-------------------------------------------------------------------------------
-- 4. DIALOG BUTTON FACTORY
-- Objective: Creates action/dialog buttons (Accept, Cancel, etc.) with pre-configured
-- semantic color themes and automatic width adjustment for label text.
-- Variables:
-- options (table): Standard button options plus optional `variant` ("accept" | "cancel" | "neutral").
-- variant (string): Semantic style selector.
-- button (table): Allocated and styled Button instance.
-------------------------------------------------------------------------------
function Context:createDialogButton(options)
    local styles = self.styles
    local variant = (options.variant or options.buttonType or "neutral"):lower()
    
    local defaultText = ""
    local customBorderColors = nil
    local customLabelColors = nil

    if variant == "accept" or variant == "confirm" or variant == "success" then
        defaultText = "Accept"
        customBorderColors = {
            normal = styles.colors.neonGreen,
            hover = styles.colors.greenHover,
            active = styles.colors.greenActive,
            disabled = styles.colors.surfaceLight
        }
        customLabelColors = {
            normal = styles.colors.white,
            hover = styles.colors.greenHover,
            active = styles.colors.white,
            disabled = styles.colors.surfaceHover
        }
    elseif variant == "cancel" or variant == "decline" or variant == "danger" then
        defaultText = "Cancel"
        customBorderColors = {
            normal = styles.colors.neonRed,
            hover = styles.colors.redHover,
            active = styles.colors.redActive,
            disabled = styles.colors.surfaceLight
        }
        customLabelColors = {
            normal = styles.colors.white,
            hover = styles.colors.redHover,
            active = styles.colors.white,
            disabled = styles.colors.surfaceHover
        }
    else
        -- Free-text / neutral variant using standard base button colors
        defaultText = options.text or "Button"
        customBorderColors = {
            normal = styles.colors.border,
            hover = styles.colors.primaryHover,
            active = styles.colors.primaryActive,
            disabled = styles.colors.surfaceLight
        }
        customLabelColors = {
            normal = styles.colors.white,
            hover = styles.colors.primaryHover,
            active = styles.colors.white,
            disabled = styles.colors.surfaceHover
        }
    end

    local text = options.text or defaultText
    local width = options.width or 90
    local height = options.height or 26

    local buttonOptions = {}
    for key, value in pairs(options) do
        buttonOptions[key] = value
    end

    buttonOptions.text = text
    buttonOptions.width = width
    buttonOptions.height = height
    if customBorderColors and not options.borderColors then
        buttonOptions.borderColors = customBorderColors
    end
    if customLabelColors and not options.labelColors then
        buttonOptions.labelColors = customLabelColors
    end

    local button = self:createButton(buttonOptions)

    if options.fluidWidth then
        button.fluidWidth = true
        local point = options.point or options.anchorPoint or "TOPLEFT"
        local yOffset = options.yOffset or 0
        local rightOffset = options.fluidRightOffset or options.rightOffset or -10
        local targetParent = options.relativeTo or parent
        if string.find(point, "TOP") then
            button:SetPoint("TOPRIGHT", targetParent, "TOPRIGHT", rightOffset, yOffset)
        elseif string.find(point, "BOTTOM") then
            button:SetPoint("BOTTOMRIGHT", targetParent, "BOTTOMRIGHT", rightOffset, yOffset)
        else
            button:SetPoint("RIGHT", targetParent, "RIGHT", rightOffset, yOffset)
        end
    end

    -- Auto-expand button width if text exceeds default padding (unless width was explicitly specified)
    local fontString = button:GetFontString()
    if fontString and not options.width and not options.fluidWidth then
        local textWidth = fontString:GetStringWidth() or 0
        if textWidth > (width - 16) then
            button:SetWidth(textWidth + 24)
            fontString:SetWidth(textWidth + 10)
        end
    end

    return button
end

-------------------------------------------------------------------------------
-- 4.1 ADAPTIVE DIALOG BUTTON GROUP FACTORY
-- Objective: Creates a responsive group of semantic dialog buttons ("Accept", "Cancel", etc.).
-- In standard/wide layouts, buttons sit side-by-side horizontally. In compact/narrow layouts
-- (parent width < stackThreshold, default 400px), buttons stack vertically at 100% width.
-- Variables:
-- options (table): Configuration table (parent, buttons, stackThreshold, gap, etc.).
-- group (table): The container Frame holding the buttons.
-------------------------------------------------------------------------------

--- Creates an adaptive responsive group of dialog action buttons.
--- @param options table Configuration parameters (parent, buttons, stackThreshold, gap, etc.).
--- @return table group Container frame containing the dialog buttons and layout controllers.
function Context:createDialogButtonGroup(options)
    options = options or {}
    local parent = options.parent or UIParent
    local buttonsConfig = options.buttons or {}
    local threshold = options.stackThreshold or options.threshold or 400
    local gap = options.gap or 8
    local buttonHeight = options.buttonHeight or options.height or 26
    local buttonWidth = options.buttonWidth or options.width or 90
    local isResponsive = (options.responsive ~= false)

    local group = self:acquireElement("Frame", parent, {
        height = buttonHeight
    })
    group:EnableMouse(false)

    if options.name then
        _G[options.name] = group
    end

    local basePoint = options.point or options.anchorPoint or "BOTTOMRIGHT"
    local baseRelTo = options.relativeTo or parent
    local baseRelPoint = options.relativePoint or basePoint
    local baseX = options.xOffset or 0
    local baseY = options.yOffset or 0

    group:ClearAllPoints()
    group:SetPoint(basePoint, baseRelTo, baseRelPoint, baseX, baseY)

    local createdButtons = {}
    for _, btnCfg in ipairs(buttonsConfig) do
        local btnOptions = {}
        for k, v in pairs(btnCfg) do btnOptions[k] = v end
        btnOptions.parent = group
        btnOptions.height = buttonHeight
        btnOptions.width = btnCfg.width or buttonWidth
        local btn = self:createDialogButton(btnOptions)
        btn.targetWidth = btnCfg.width or buttonWidth
        table.insert(createdButtons, btn)
    end

    local isStacked = false

    local function updateLayout(width)
        width = width or (parent and parent.GetWidth and parent:GetWidth()) or (group:GetWidth()) or 0
        local shouldStack = isResponsive and (width > 0 and width < threshold)

        if shouldStack then
            isStacked = true
            group.mode = "vertical"
            local currentY = 0
            for _, btn in ipairs(createdButtons) do
                btn:ClearAllPoints()
                btn:SetPoint("TOPLEFT", group, "TOPLEFT", 0, currentY)
                btn:SetPoint("TOPRIGHT", group, "TOPRIGHT", 0, currentY)
                btn:SetHeight(buttonHeight)
                currentY = currentY - buttonHeight - gap
            end
            local totalHeight = math.max(buttonHeight, math.abs(currentY) - gap)
            group:SetHeight(totalHeight)
            if not options.width then
                group:ClearAllPoints()
                local leftPad = math.abs(options.xOffset or 10)
                local rightPad = -(math.abs(options.fluidRightOffset or options.rightOffset or options.xOffset or 10))
                if string.find(basePoint, "TOP") then
                    group:SetPoint("TOPLEFT", baseRelTo, "TOPLEFT", leftPad, baseY)
                    group:SetPoint("TOPRIGHT", baseRelTo, "TOPRIGHT", rightPad, baseY)
                elseif string.find(basePoint, "BOTTOM") then
                    group:SetPoint("BOTTOMLEFT", baseRelTo, "BOTTOMLEFT", leftPad, baseY)
                    group:SetPoint("BOTTOMRIGHT", baseRelTo, "BOTTOMRIGHT", rightPad, baseY)
                else
                    group:SetPoint("TOPLEFT", baseRelTo, "TOPLEFT", leftPad, baseY)
                    group:SetPoint("TOPRIGHT", baseRelTo, "TOPRIGHT", rightPad, baseY)
                end
            end
        else
            isStacked = false
            group.mode = "horizontal"
            local currentX = 0
            for _, btn in ipairs(createdButtons) do
                btn:ClearAllPoints()
                btn:SetPoint("LEFT", group, "LEFT", currentX, 0)
                btn:SetSize(btn.targetWidth or buttonWidth, buttonHeight)
                currentX = currentX + (btn.targetWidth or buttonWidth) + gap
            end
            local totalWidth = math.max(1, currentX - gap)
            group:SetWidth(totalWidth)
            group:SetHeight(buttonHeight)
            if not options.width then
                group:ClearAllPoints()
                group:SetPoint(basePoint, baseRelTo, baseRelPoint, baseX, baseY)
            end
        end

        if options.onLayoutChange then
            options.onLayoutChange(group, group.mode, width)
        end
    end

    -- Initial layout pass
    updateLayout(parent and parent.GetWidth and parent:GetWidth() or 0)

    -- Auto-subscribe to parent OnSizeChanged
    if isResponsive and parent and parent.HookScript then
        parent:HookScript("OnSizeChanged", function(self, w, h)
            updateLayout(w or (self and self:GetWidth()) or 0)
        end)
    end

    group.buttons = createdButtons
    group.updateLayout = updateLayout
    group.isStacked = function() return isStacked end

    return group
end

Context.createDialogButtons = Context.createDialogButtonGroup

-------------------------------------------------------------------------------
-- 5. EXTENSION & EXPANSION NOTES
-- Objective: Guidelines for adding custom button variants, additional icon shapes, and button sound effects.
--
-- How to expand:
-- 1. Additional Icon Shapes:
--    Add cases to `createIconButton` for new geometric icons (e.g. "gear", "refresh", "info", "check", "chevron")
--    by drawing dynamic texture primitives or using WoW atlas textures.
-- 2. Button Variant Palettes:
--    Add new semantic variants to `createDialogButton` (e.g. `variant = "warning"`, `variant = "info"`)
--    with dedicated neon color configurations.
-- 3. Toggle Button States:
--    Extend `createButton` with a sticky active state (`button.isActive`) that keeps hover/active colors locked
--    until untoggled.
-------------------------------------------------------------------------------
