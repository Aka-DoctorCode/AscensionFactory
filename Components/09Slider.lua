-------------------------------------------------------------------------------
-- Project: AscensionFactory
-- Author: Aka-DoctorCode
-- File: 09Slider.lua
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
-- 2. SLIDER FACTORY
-- Objective: Creates a versatile slider and scrollbar component supporting both
-- HORIZONTAL and VERTICAL orientations, custom diamond thumb geometry, track fill,
-- mouse dragging, step snapping, and mouse wheel navigation.
-- Variables:
-- options (table): Configuration table (orientation, length, min, max, step, onValueChanged, etc.).
-- slider (table): The created Slider/Frame element.
-- track, border, fill, thumb (tables): Visual textures and interactive handles.
-------------------------------------------------------------------------------
function Context:createSlider(options)
    options = options or {}
    local styles = self.styles
    local parent = options.parent or UIParent

    -- 2.1 MANDATORY VALIDATION (Orientation & Length)
    if not options.orientation then
        error("AscensionFactory: createSlider requires explicit 'orientation' ('HORIZONTAL' or 'VERTICAL')", 2)
    end

    local orientation = string.upper(tostring(options.orientation))
    if orientation ~= "HORIZONTAL" and orientation ~= "VERTICAL" then
        error(string.format("AscensionFactory: Invalid orientation '%s'. Expected 'HORIZONTAL' or 'VERTICAL'", tostring(options.orientation)), 2)
    end

    local length
    local thickness
    local width
    local height
    local isFluid = options.fluidWidth or false

    if orientation == "HORIZONTAL" then
        length = options.length or options.width or (isFluid and 200)
        if not length then
            error("AscensionFactory: createSlider requires explicit 'length' or 'width' for HORIZONTAL orientation (or 'fluidWidth = true')", 2)
        end
        thickness = options.height or options.thickness or 16
        width = length
        height = thickness
    else
        length = options.length or options.height
        if not length then
            error("AscensionFactory: createSlider requires explicit 'length' or 'height' for VERTICAL orientation", 2)
        end
        thickness = options.width or options.thickness or 14
        width = thickness
        height = length
    end

    -- 2.2 BASE FRAME SETUP
    local slider = self:acquireElement("Frame", parent, {
        width = width,
        height = height
    })
    slider:EnableMouse(true)
    slider.fluidWidth = isFluid
    slider.fluidRightOffset = options.fluidRightOffset or options.rightOffset

    if options.name then
        _G[options.name] = slider
    end

    local point = options.point or options.anchorPoint or "TOPLEFT"
    local yOffset = options.yOffset or 0
    local targetParent = options.relativeTo or parent

    if options.point or options.anchorPoint or options.xOffset or options.yOffset then
        slider:ClearAllPoints()
        slider:SetPoint(
            point,
            targetParent,
            options.relativePoint or point,
            options.xOffset or 0,
            yOffset
        )
    end

    if isFluid and orientation == "HORIZONTAL" then
        local rightOffset = options.fluidRightOffset or options.rightOffset or -10
        if string.find(point, "TOP") then
            slider:SetPoint("TOPRIGHT", targetParent, "TOPRIGHT", rightOffset, yOffset)
        elseif string.find(point, "BOTTOM") then
            slider:SetPoint("BOTTOMRIGHT", targetParent, "BOTTOMRIGHT", rightOffset, yOffset)
        else
            slider:SetPoint("RIGHT", targetParent, "RIGHT", rightOffset, yOffset)
        end
    end

    -- 2.3 EXPLICIT TRACK & BORDER TEXTURES
    if not slider.border then
        local border = slider:CreateTexture(nil, "BACKGROUND", nil, -2)
        border:SetAllPoints(slider)
        slider.border = border
    end
    slider.border:SetColorTexture(unpack(options.borderColor or styles.colors.border))
    slider.border:Show()

    if not slider.track then
        local track = slider:CreateTexture(nil, "BACKGROUND", nil, -1)
        slider.track = track
    end
    slider.track:ClearAllPoints()
    slider.track:SetPoint("TOPLEFT", slider, "TOPLEFT", 1, -1)
    slider.track:SetPoint("BOTTOMRIGHT", slider, "BOTTOMRIGHT", -1, 1)
    slider.track:SetColorTexture(unpack(options.trackColor or styles.colors.surfaceDark))
    slider.track:Show()

    -- 2.4 OPTIONAL PROGRESS FILL
    local showFill = options.showFill or options.fill or false
    if not slider.fill then
        local fill = slider:CreateTexture(nil, "BACKGROUND", nil, 0)
        slider.fill = fill
    end
    slider.fill:SetColorTexture(unpack(options.fillColor or styles.colors.primary))
    if not showFill then
        slider.fill:Hide()
    end

    -- 2.5 THUMB SETUP
    local thumbShape = options.thumbShape or "diamond"
    local thumbThickness = options.thumbThickness or (thickness - 2)
    local thumbLength = options.thumbLength or options.thumbSize or (thickness - 2)

    local thumbWidth, thumbHeight
    if orientation == "HORIZONTAL" then
        thumbWidth = thumbLength
        thumbHeight = thumbThickness
    else
        thumbWidth = thumbThickness
        thumbHeight = thumbLength
    end

    local diamondInnerSize = math.max(6, math.floor(math.min(thumbWidth, thumbHeight) * 0.65))

    local thumb = slider.thumb
    if not thumb then
        thumb = self:acquireElement("Button", slider, {
            width = thumbWidth,
            height = thumbHeight
        })
        slider.thumb = thumb
    end
    thumb:SetSize(thumbWidth, thumbHeight)
    thumb:EnableMouse(true)

    if not thumb.diamond then
        local diamond = thumb:CreateTexture(nil, "ARTWORK", nil, 1)
        thumb.diamond = diamond
    end
    thumb.diamond:ClearAllPoints()
    thumb.diamond:SetSize(diamondInnerSize, diamondInnerSize)
    thumb.diamond:SetPoint("CENTER", thumb, "CENTER", 0, 0)
    thumb.diamond:SetRotation(math.rad(45))
    thumb.diamond:SetColorTexture(unpack(styles.colors.white))

    -- 2.5.1 THUMB SHAPE ARCHITECTURE (capsule, bar, diamond)
    local function setupThumbVisuals()
        local currentShape = slider.thumbShape or thumbShape
        local w = slider.thumbWidth or thumbWidth
        local h = slider.thumbHeight or thumbHeight

        if currentShape == "capsule" then
            if not thumb.capsuleTop then
                thumb.capsuleTop = thumb:CreateTexture(nil, "ARTWORK", nil, 1)
                thumb.capsuleMiddle = thumb:CreateTexture(nil, "ARTWORK", nil, 1)
                thumb.capsuleBottom = thumb:CreateTexture(nil, "ARTWORK", nil, 1)
            end

            local hasAtlas = C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo("minimal-scrollbar-small-thumb-top")

            if slider.orientation == "HORIZONTAL" then
                local capSize = math.max(3, math.min(math.floor(w * 0.4), math.floor(h * 0.5)))
                thumb.capsuleTop:ClearAllPoints()
                thumb.capsuleTop:SetPoint("TOPLEFT", thumb, "TOPLEFT", 0, 0)
                thumb.capsuleTop:SetPoint("BOTTOMLEFT", thumb, "BOTTOMLEFT", 0, 0)
                thumb.capsuleTop:SetWidth(capSize)

                thumb.capsuleBottom:ClearAllPoints()
                thumb.capsuleBottom:SetPoint("TOPRIGHT", thumb, "TOPRIGHT", 0, 0)
                thumb.capsuleBottom:SetPoint("BOTTOMRIGHT", thumb, "BOTTOMRIGHT", 0, 0)
                thumb.capsuleBottom:SetWidth(capSize)

                thumb.capsuleMiddle:ClearAllPoints()
                thumb.capsuleMiddle:SetPoint("TOPLEFT", thumb.capsuleTop, "TOPRIGHT", 0, 0)
                thumb.capsuleMiddle:SetPoint("BOTTOMRIGHT", thumb.capsuleBottom, "BOTTOMLEFT", 0, 0)

                thumb.capsuleTop:SetColorTexture(unpack(styles.colors.primary))
                thumb.capsuleMiddle:SetColorTexture(unpack(styles.colors.primary))
                thumb.capsuleBottom:SetColorTexture(unpack(styles.colors.primary))
            else
                local capSize = math.max(3, math.min(math.floor(h * 0.4), math.floor(w * 0.5)))
                thumb.capsuleTop:ClearAllPoints()
                thumb.capsuleTop:SetPoint("TOPLEFT", thumb, "TOPLEFT", 0, 0)
                thumb.capsuleTop:SetPoint("TOPRIGHT", thumb, "TOPRIGHT", 0, 0)
                thumb.capsuleTop:SetHeight(capSize)

                thumb.capsuleBottom:ClearAllPoints()
                thumb.capsuleBottom:SetPoint("BOTTOMLEFT", thumb, "BOTTOMLEFT", 0, 0)
                thumb.capsuleBottom:SetPoint("BOTTOMRIGHT", thumb, "BOTTOMRIGHT", 0, 0)
                thumb.capsuleBottom:SetHeight(capSize)

                thumb.capsuleMiddle:ClearAllPoints()
                thumb.capsuleMiddle:SetPoint("TOPLEFT", thumb.capsuleTop, "BOTTOMLEFT", 0, 0)
                thumb.capsuleMiddle:SetPoint("BOTTOMRIGHT", thumb.capsuleBottom, "TOPRIGHT", 0, 0)

                if hasAtlas then
                    thumb.capsuleTop:SetAtlas("minimal-scrollbar-small-thumb-top")
                    thumb.capsuleMiddle:SetAtlas("minimal-scrollbar-small-thumb-middle")
                    thumb.capsuleBottom:SetAtlas("minimal-scrollbar-small-thumb-bottom")
                else
                    thumb.capsuleTop:SetColorTexture(unpack(styles.colors.primary))
                    thumb.capsuleMiddle:SetColorTexture(unpack(styles.colors.primary))
                    thumb.capsuleBottom:SetColorTexture(unpack(styles.colors.primary))
                end
            end

            thumb.capsuleTop:Show()
            thumb.capsuleMiddle:Show()
            thumb.capsuleBottom:Show()
            if thumb.barTexture then thumb.barTexture:Hide() end
            if thumb.diamond then thumb.diamond:Hide() end
        elseif currentShape == "bar" then
            if not thumb.barTexture then
                thumb.barTexture = thumb:CreateTexture(nil, "ARTWORK", nil, 1)
            end
            thumb.barTexture:ClearAllPoints()
            thumb.barTexture:SetAllPoints(thumb)
            thumb.barTexture:SetColorTexture(unpack(styles.colors.primary))
            thumb.barTexture:Show()

            if thumb.capsuleTop then
                thumb.capsuleTop:Hide()
                thumb.capsuleMiddle:Hide()
                thumb.capsuleBottom:Hide()
            end
            if thumb.diamond then thumb.diamond:Hide() end
        else
            if thumb.capsuleTop then
                thumb.capsuleTop:Hide()
                thumb.capsuleMiddle:Hide()
                thumb.capsuleBottom:Hide()
            end
            if thumb.barTexture then thumb.barTexture:Hide() end
            if thumb.diamond then
                local newInner = math.max(6, math.floor(math.min(w, h) * 0.65))
                thumb.diamond:SetSize(newInner, newInner)
                thumb.diamond:Show()
            end
        end
    end

    local function applyThumbColor(state)
        local currentShape = slider.thumbShape or thumbShape
        local isEnabled = slider.isInteractiveEnabled ~= false
        local color
        if not isEnabled then
            color = styles.colors.surfaceHover
        elseif state == "active" or slider.isDragging then
            color = styles.colors.primaryActive
        elseif state == "hover" then
            color = styles.colors.primaryHover
        else
            color = options.thumbColor or styles.colors.primary
        end

        if currentShape == "capsule" and thumb.capsuleTop then
            local hasAtlas = C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo("minimal-scrollbar-small-thumb-top")
            if hasAtlas and slider.orientation == "VERTICAL" then
                thumb.capsuleTop:SetVertexColor(unpack(color))
                thumb.capsuleMiddle:SetVertexColor(unpack(color))
                thumb.capsuleBottom:SetVertexColor(unpack(color))
            else
                thumb.capsuleTop:SetColorTexture(unpack(color))
                thumb.capsuleMiddle:SetColorTexture(unpack(color))
                thumb.capsuleBottom:SetColorTexture(unpack(color))
            end
        elseif currentShape == "bar" and thumb.barTexture then
            thumb.barTexture:SetColorTexture(unpack(color))
        elseif currentShape == "diamond" and thumb.diamond then
            thumb.diamond:SetColorTexture(unpack(color))
        end
    end

    setupThumbVisuals()
    applyThumbColor("normal")

    -- 2.6 STATE CONFIGURATION
    slider.orientation = orientation
    slider.thumbShape = thumbShape
    slider.thumbWidth = thumbWidth
    slider.thumbHeight = thumbHeight
    slider.thumbThickness = thumbThickness
    slider.thumbSize = (orientation == "HORIZONTAL") and thumbWidth or thumbHeight
    slider.minValue = options.minValue or options.min or 0
    slider.maxValue = options.maxValue or options.max or 100
    slider.step = options.step or options.stepSize or 1
    slider.isDragging = false
    slider.showFill = showFill
    slider.thickness = thickness
    slider.inverted = options.inverted or false

    local currentValue = options.value or options.defaultValue or slider.minValue
    if options.getter then
        currentValue = options.getter() or currentValue
    end

    -- 2.7 THUMB POSITIONING & FILL ENGINE
    local function updateThumbPosition()
        local range = slider.maxValue - slider.minValue
        local pct = 0
        if range > 0 then
            pct = math.max(0, math.min(1, (currentValue - slider.minValue) / range))
        end

        local currentWidth = slider:GetWidth()
        local currentHeight = slider:GetHeight()

        thumb:ClearAllPoints()

        if slider.orientation == "HORIZONTAL" then
            local travelSize = slider.thumbWidth or slider.thumbSize
            local travelDistance = math.max(0, currentWidth - travelSize - 2)
            local xPos = 1 + (pct * travelDistance)
            thumb:SetPoint("LEFT", slider, "LEFT", xPos, 0)

            if slider.showFill and slider.fill:IsShown() then
                slider.fill:ClearAllPoints()
                slider.fill:SetPoint("TOPLEFT", slider, "TOPLEFT", 1, -1)
                slider.fill:SetPoint("BOTTOMLEFT", slider, "BOTTOMLEFT", 1, 1)
                slider.fill:SetWidth(math.max(1, xPos + (travelSize * 0.5)))
            end
        else
            local travelSize = slider.thumbHeight or slider.thumbSize
            local travelDistance = math.max(0, currentHeight - travelSize - 2)
            local effectivePct = slider.inverted and (1 - pct) or pct
            local yPos = -1 - (effectivePct * travelDistance)
            thumb:SetPoint("TOP", slider, "TOP", 0, yPos)

            if slider.showFill and slider.fill:IsShown() then
                slider.fill:ClearAllPoints()
                if slider.inverted then
                    slider.fill:SetPoint("BOTTOMLEFT", slider, "BOTTOMLEFT", 1, 1)
                    slider.fill:SetPoint("BOTTOMRIGHT", slider, "BOTTOMRIGHT", -1, 1)
                    slider.fill:SetHeight(math.max(1, (pct * travelDistance) + (travelSize * 0.5)))
                else
                    slider.fill:SetPoint("TOPLEFT", slider, "TOPLEFT", 1, -1)
                    slider.fill:SetPoint("TOPRIGHT", slider, "TOPRIGHT", -1, -1)
                    slider.fill:SetHeight(math.max(1, -yPos + (travelSize * 0.5)))
                end
            end
        end
    end

    local function applyValue(newValue, isUserInput, isSilent)
        local steppedValue = newValue
        if slider.step and slider.step > 0 then
            steppedValue = math.floor((newValue - slider.minValue) / slider.step + 0.5) * slider.step + slider.minValue
        end
        steppedValue = math.max(slider.minValue, math.min(slider.maxValue, steppedValue))

        local valueChanged = (steppedValue ~= currentValue)
        currentValue = steppedValue

        updateThumbPosition()

        if valueChanged and not isSilent then
            if options.setter then
                options.setter(currentValue)
            end
            if options.onValueChanged then
                options.onValueChanged(slider, currentValue, isUserInput or false)
            end
        end
    end

    -- 2.8 DRAGGING & COORDINATE CONVERSION ENGINE
    local function calculateValueFromCursor()
        local scale = UIParent:GetEffectiveScale()
        local cursorX, cursorY = GetCursorPosition()
        cursorX = cursorX / scale
        cursorY = cursorY / scale

        local range = slider.maxValue - slider.minValue
        if range <= 0 then return slider.minValue end

        local pct = 0
        if slider.orientation == "HORIZONTAL" then
            local left = slider:GetLeft() or 0
            local travelSize = slider.thumbWidth or slider.thumbSize
            local widthAvailable = math.max(1, slider:GetWidth() - travelSize - 2)
            local relativeX = cursorX - left - (travelSize * 0.5) - 1
            pct = math.max(0, math.min(1, relativeX / widthAvailable))
        else
            local top = slider:GetTop() or 0
            local travelSize = slider.thumbHeight or slider.thumbSize
            local heightAvailable = math.max(1, slider:GetHeight() - travelSize - 2)
            local relativeY = top - cursorY - (travelSize * 0.5) - 1
            pct = math.max(0, math.min(1, relativeY / heightAvailable))
            if slider.inverted then
                pct = 1 - pct
            end
        end

        return slider.minValue + (pct * range)
    end

    -- 2.9 INTERACTION SCRIPTS & HOVER (Managed via UX:makeHoverable)
    if lib.UX and lib.UX.makeHoverable then
        lib.UX:makeHoverable(thumb, {
            tooltip = options.tooltip,
            track = thumb.diamond,
            border = slider.border,
            trackColors = {
                normal = styles.colors.white,
                hover = styles.colors.primaryHover,
                active = styles.colors.primaryActive,
                disabled = styles.colors.surfaceHover
            },
            borderColors = {
                normal = options.borderColor or styles.colors.border,
                hover = styles.colors.primaryHover,
                active = styles.colors.primaryActive,
                disabled = styles.colors.border
            },
            onAfterStateChange = function(element, state)
                applyThumbColor(state)
                if slider.isDragging then
                    slider.border:SetColorTexture(unpack(styles.colors.primaryActive))
                end
            end
        })
    end

    local function startDragging()
        slider.isDragging = true
        applyThumbColor("active")
        slider.border:SetColorTexture(unpack(styles.colors.primaryActive))
        if thumb.updateAppearance then
            thumb.updateAppearance("active")
        end

        slider:SetScript("OnUpdate", function()
            local targetValue = calculateValueFromCursor()
            applyValue(targetValue, true, false)
        end)
    end

    local function stopDragging()
        if slider.isDragging then
            slider.isDragging = false
            slider:SetScript("OnUpdate", nil)
            local state = (thumb:IsMouseOver() or slider:IsMouseOver()) and "hover" or "normal"
            applyThumbColor(state)
            slider.border:SetColorTexture(unpack(options.borderColor or styles.colors.border))

            if thumb.updateAppearance then
                thumb.updateAppearance(state)
            end
        end
    end

    thumb:HookScript("OnMouseDown", function(self, buttonName)
        if buttonName == "LeftButton" then
            startDragging()
        end
    end)

    thumb:HookScript("OnMouseUp", function(self, buttonName)
        if buttonName == "LeftButton" then
            stopDragging()
        end
    end)

    slider:HookScript("OnEnter", function()
        if not slider.isDragging and thumb.updateAppearance then
            thumb.updateAppearance("hover")
        end
    end)

    slider:HookScript("OnLeave", function()
        if not slider.isDragging and thumb.updateAppearance then
            thumb.updateAppearance(thumb:IsMouseOver() and "hover" or "normal")
        end
    end)

    slider:HookScript("OnMouseDown", function(self, buttonName)
        if buttonName == "LeftButton" then
            local targetValue = calculateValueFromCursor()
            applyValue(targetValue, true, false)
            startDragging()
        end
    end)

    slider:HookScript("OnMouseUp", function(self, buttonName)
        if buttonName == "LeftButton" then
            stopDragging()
        end
    end)

    slider:HookScript("OnHide", function()
        stopDragging()
    end)

    slider:HookScript("OnSizeChanged", function()
        updateThumbPosition()
    end)

    slider:EnableMouseWheel(true)
    slider:SetScript("OnMouseWheel", function(self, delta)
        local stepAmount = slider.step or 1
        local deltaValue
        if slider.orientation == "HORIZONTAL" then
            local isForward = (delta > 0)
            if slider.inverted then
                isForward = not isForward
            end
            deltaValue = isForward and stepAmount or -stepAmount
        else
            local isIncrease = (delta > 0 and slider.inverted) or (delta < 0 and not slider.inverted)
            deltaValue = isIncrease and stepAmount or -stepAmount
        end
        applyValue(currentValue + deltaValue, true, false)
    end)

    -- 2.10 PUBLIC API METHODS
    function slider:getValue()
        return currentValue
    end
    slider.GetValue = slider.getValue

    function slider:setValue(val, isSilent, isUserInput)
        applyValue(val, isUserInput, isSilent)
    end
    slider.SetValue = slider.setValue

    function slider:setMinMaxValues(minVal, maxVal)
        self.minValue = minVal
        self.maxValue = maxVal
        applyValue(currentValue, false, true)
    end
    slider.SetMinMaxValues = slider.setMinMaxValues

    function slider:getMinMaxValues()
        return self.minValue, self.maxValue
    end
    slider.GetMinMaxValues = slider.getMinMaxValues

    function slider:setStep(newStep)
        self.step = newStep
    end
    slider.SetStep = slider.setStep

    function slider:setThumbSize(newLength, newThickness)
        if newThickness then
            self.thumbThickness = newThickness
        end
        if self.orientation == "HORIZONTAL" then
            self.thumbWidth = newLength
            self.thumbHeight = self.thumbThickness or (self.thickness - 2)
            self.thumbSize = self.thumbWidth
        else
            self.thumbWidth = self.thumbThickness or (self.thickness - 2)
            self.thumbHeight = newLength
            self.thumbSize = self.thumbHeight
        end
        self.thumb:SetSize(self.thumbWidth, self.thumbHeight)

        setupThumbVisuals()
        applyThumbColor((self.thumb:IsMouseOver() or self:IsMouseOver()) and "hover" or "normal")
        updateThumbPosition()
    end
    slider.SetThumbSize = slider.setThumbSize

    function slider:setThumbShape(newShape)
        self.thumbShape = newShape
        setupThumbVisuals()
        applyThumbColor((self.thumb:IsMouseOver() or self:IsMouseOver()) and "hover" or "normal")
        updateThumbPosition()
    end
    slider.SetThumbShape = slider.setThumbShape

    function slider:setFill(enabled)
        self.showFill = enabled
        if enabled then
            self.fill:Show()
        else
            self.fill:Hide()
        end
        updateThumbPosition()
    end
    slider.SetFill = slider.setFill

    function slider:updateThumbPosition()
        updateThumbPosition()
    end
    slider.UpdateThumbPosition = slider.updateThumbPosition

    function slider:setEnabled(enabled)
        self.isInteractiveEnabled = enabled ~= false
        self:EnableMouse(self.isInteractiveEnabled)
        if self.thumb then
            self.thumb:SetEnabled(self.isInteractiveEnabled)
        end
        local styles = self.uiContext and self.uiContext.styles or lib.defaultStyles
        if self.border and styles and styles.colors then
            if not self.isInteractiveEnabled then
                self.border:SetColorTexture(unpack(styles.colors.surfaceLight or { 0.027, 0.039, 0.059, 0.90 }))
            else
                self.border:SetColorTexture(unpack(styles.colors.border or { 0.078, 0.102, 0.141, 1.00 }))
            end
        end
    end
    slider.SetEnabled = slider.setEnabled

    function slider:enable()
        self:setEnabled(true)
    end
    slider.Enable = slider.enable

    function slider:disable()
        self:setEnabled(false)
    end
    slider.Disable = slider.disable

    function slider:isEnabled()
        return self.isInteractiveEnabled ~= false
    end
    slider.IsEnabled = slider.isEnabled

    -- Initial position calculation
    applyValue(currentValue, false, true)

    return slider
end

-------------------------------------------------------------------------------
-- 3. EXTENSION & EXPANSION NOTES
-- Objective: Guidelines for tick marks, value indicator callouts, and dual-handle range sliders.
--
-- How to expand:
-- 1. Value Indicator Tooltip/Callout:
--    Attach a small dynamic label above the diamond thumb displaying the live value while dragging.
-- 2. Stepped Tick Marks:
--    Render subtle vertical tick line textures along the slider track corresponding to discrete step values.
-- 3. Dual-Handle Range Slider:
--    Instantiate two diamond thumbs (minHandle and maxHandle) to allow selecting a range [min, max]
--    with a filled progress zone between both thumbs.
-------------------------------------------------------------------------------
