-------------------------------------------------------------------------------
-- Project: AscensionFactory
-- Author: Aka-DoctorCode
-- File: 10Stepper.lua
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
-- 2. STEPPER FACTORY
-- Objective: Creates a numeric stepper component with joined seamless borders,
-- minus icon button on left, centered input field in middle, plus icon button on right,
-- hold-to-repeat incrementing, direct numeric entry, and mouse wheel navigation.
-- Variables:
-- options (table): Configuration table (width, height, min, max, step, decimals, onValueChanged, etc.).
-- stepper (table): The outer Frame container holding the stepper controls.
-- minusButton, plusButton, inputField (tables): The composited sub-components.
-------------------------------------------------------------------------------
function Context:createStepper(options)
    options = options or {}
    local styles = self.styles
    local parent = options.parent or UIParent

    -- 2.1 MANDATORY VALIDATION (Explicit sizing or fluid width)
    local isFluid = options.fluidWidth or false
    if not options.width and not isFluid then
        error("AscensionFactory: createStepper requires explicit 'width' (or 'fluidWidth = true')", 2)
    end
    if not options.height then
        error("AscensionFactory: createStepper requires explicit 'height'", 2)
    end

    local height = options.height
    local buttonSize = height
    local width = options.width or (isFluid and 160)

    if not isFluid and width < (buttonSize * 2 + 10) then
        error(string.format("AscensionFactory: Stepper width (%d) too small for height (%d). Minimum width is %d", width, height, buttonSize * 2 + 10), 2)
    end

    -- 2.2 BASE CONTAINER FRAME SETUP
    local stepper = self:acquireElement("Frame", parent, {
        width = width,
        height = height
    })
    stepper:EnableMouse(true)
    stepper.fluidWidth = isFluid
    stepper.fluidRightOffset = options.fluidRightOffset or options.rightOffset

    if options.name then
        _G[options.name] = stepper
    end

    local point = options.point or options.anchorPoint or "TOPLEFT"
    local yOffset = options.yOffset or 0
    local targetParent = options.relativeTo or parent

    if options.point or options.anchorPoint or options.xOffset or options.yOffset then
        stepper:ClearAllPoints()
        stepper:SetPoint(
            point,
            targetParent,
            options.relativePoint or point,
            options.xOffset or 0,
            yOffset
        )
    end

    if isFluid then
        local rightOffset = options.fluidRightOffset or options.rightOffset or -10
        if string.find(point, "TOP") then
            stepper:SetPoint("TOPRIGHT", targetParent, "TOPRIGHT", rightOffset, yOffset)
        elseif string.find(point, "BOTTOM") then
            stepper:SetPoint("BOTTOMRIGHT", targetParent, "BOTTOMRIGHT", rightOffset, yOffset)
        else
            stepper:SetPoint("RIGHT", targetParent, "RIGHT", rightOffset, yOffset)
        end
    end

    -- 2.3 STATE CONFIGURATION
    stepper.minValue = options.minValue or options.min or 0
    stepper.maxValue = options.maxValue or options.max or 100
    stepper.step = options.step or options.stepSize or 1
    stepper.decimals = options.decimals or (options.step and string.find(tostring(options.step), "%.") and #tostring(options.step):match("%.(%d+)") or 0)
    stepper.isEnabled = true

    local currentValue = options.value or options.defaultValue or stepper.minValue
    if options.getter then
        currentValue = options.getter() or currentValue
    end

    local function formatValue(val)
        if stepper.decimals and stepper.decimals > 0 then
            return string.format("%." .. stepper.decimals .. "f", val)
        else
            return string.format("%d", math.floor(val + 0.5))
        end
    end

    -- 2.4 SUB-COMPONENTS COMPOSITION (Seamless Joined Layout)
    local inputWidth = options.inputWidth or math.max(40, math.floor((width - (buttonSize * 2) + 2) * 2 / 5))

    -- Left: Minus Button
    local minusButton = self:createIconButton({
        parent = stepper,
        name = options.name and (options.name .. "MinusBtn") or nil,
        iconType = "minus",
        size = buttonSize,
        point = "LEFT",
        relativeTo = stepper,
        relativePoint = "LEFT",
        xOffset = 0,
        yOffset = 0
    })
    stepper.minusButton = minusButton

    -- Middle: Centered InputField (overlaps 1px on left and right for seamless joined border)
    local inputField = self:createInputField({
        parent = stepper,
        name = options.name and (options.name .. "InputField") or nil,
        width = isFluid and 50 or inputWidth,
        height = height,
        text = formatValue(currentValue),
        numeric = not (options.allowNegative or stepper.minValue < 0),
        point = "LEFT",
        relativeTo = minusButton,
        relativePoint = "RIGHT",
        xOffset = -1,
        yOffset = 0
    })
    stepper.inputField = inputField

    local editBox = inputField:GetEditBox()
    if editBox then
        editBox:SetJustifyH("CENTER")
    end

    -- Right: Plus Button
    local plusButton = self:createIconButton({
        parent = stepper,
        name = options.name and (options.name .. "PlusBtn") or nil,
        iconType = "plus",
        size = buttonSize,
        point = isFluid and "RIGHT" or "LEFT",
        relativeTo = isFluid and stepper or inputField,
        relativePoint = isFluid and "RIGHT" or "RIGHT",
        xOffset = isFluid and 0 or -1,
        yOffset = 0
    })
    stepper.plusButton = plusButton

    if isFluid then
        inputField:ClearAllPoints()
        inputField:SetPoint("LEFT", minusButton, "RIGHT", -1, 0)
        inputField:SetPoint("RIGHT", plusButton, "LEFT", 1, 0)
    else
        local actualWidth = (buttonSize * 2) + inputWidth - 2
        stepper:SetWidth(actualWidth)
    end

    -- 2.5 VALUE SYNC & REPEAT TICKER ENGINE
    local repeatTimer = false

    local function stopRepeatTicker()
        if repeatTimer then
            stepper:SetScript("OnUpdate", nil)
            repeatTimer = false
        end
    end

    local function updateButtonStates()
        if not stepper.isEnabled then
            minusButton:Disable()
            plusButton:Disable()
            return
        end

        if currentValue <= stepper.minValue then
            minusButton:Disable()
        else
            minusButton:Enable()
        end

        if currentValue >= stepper.maxValue then
            plusButton:Disable()
        else
            plusButton:Enable()
        end
    end

    local function applyValue(newValue, isUserInput, isSilent)
        local clampedValue = math.max(stepper.minValue, math.min(stepper.maxValue, newValue))

        if stepper.step and stepper.step > 0 then
            local stepsFromMin = math.floor(((clampedValue - stepper.minValue) / stepper.step) + 0.5)
            clampedValue = stepper.minValue + (stepsFromMin * stepper.step)
        end
        clampedValue = math.max(stepper.minValue, math.min(stepper.maxValue, clampedValue))

        local valueChanged = (clampedValue ~= currentValue)
        currentValue = clampedValue

        inputField:SetText(formatValue(currentValue))
        updateButtonStates()

        if valueChanged and not isSilent then
            if options.setter then
                options.setter(currentValue)
            end
            if options.onValueChanged then
                options.onValueChanged(stepper, currentValue, isUserInput or false)
            end
        end
    end

    local function startRepeatTicker(stepMultiplier)
        stopRepeatTicker()
        repeatTimer = true
        local startTime = GetTime()
        local nextTick = startTime + 0.40 -- Initial delay before repeat starts

        stepper:SetScript("OnUpdate", function()
            local now = GetTime()
            if now >= nextTick then
                if (stepMultiplier > 0 and currentValue >= stepper.maxValue)
                or (stepMultiplier < 0 and currentValue <= stepper.minValue) then
                    stopRepeatTicker()
                    return
                end
                applyValue(currentValue + (stepper.step * stepMultiplier), true, false)
                nextTick = now + 0.08 -- Fast repeat tick rate
            end
        end)
    end

    -- 2.6 BUTTON INTERACTION BINDINGS
    minusButton:HookScript("OnMouseDown", function(self, buttonName)
        if buttonName == "LeftButton" and stepper.isEnabled and currentValue > stepper.minValue then
            applyValue(currentValue - stepper.step, true, false)
            startRepeatTicker(-1)
        end
    end)

    minusButton:HookScript("OnMouseUp", function()
        stopRepeatTicker()
    end)

    minusButton:HookScript("OnLeave", function()
        stopRepeatTicker()
    end)

    minusButton:HookScript("OnHide", function()
        stopRepeatTicker()
    end)

    plusButton:HookScript("OnMouseDown", function(self, buttonName)
        if buttonName == "LeftButton" and stepper.isEnabled and currentValue < stepper.maxValue then
            applyValue(currentValue + stepper.step, true, false)
            startRepeatTicker(1)
        end
    end)

    plusButton:HookScript("OnMouseUp", function()
        stopRepeatTicker()
    end)

    plusButton:HookScript("OnLeave", function()
        stopRepeatTicker()
    end)

    plusButton:HookScript("OnHide", function()
        stopRepeatTicker()
    end)

    stepper:SetScript("OnHide", function()
        stopRepeatTicker()
    end)

    -- 2.7 INPUT FIELD INTERACTION BINDINGS
    if editBox then
        editBox:SetScript("OnEnterPressed", function(self)
            self:ClearFocus()
            local parsedNum = tonumber(self:GetText())
            if parsedNum then
                applyValue(parsedNum, true, false)
            else
                self:SetText(formatValue(currentValue))
            end
        end)

        editBox:SetScript("OnEditFocusLost", function(self)
            local parsedNum = tonumber(self:GetText())
            if parsedNum then
                applyValue(parsedNum, true, false)
            else
                self:SetText(formatValue(currentValue))
            end
        end)

        editBox:SetScript("OnEscapePressed", function(self)
            self:ClearFocus()
            self:SetText(formatValue(currentValue))
        end)
    end

    -- 2.8 MOUSE WHEEL SCROLLING
    local function onMouseWheel(delta)
        if not stepper.isEnabled then return end
        local stepMultiplier = (delta > 0) and 1 or -1
        applyValue(currentValue + (stepper.step * stepMultiplier), true, false)
    end

    stepper:EnableMouseWheel(true)
    stepper:SetScript("OnMouseWheel", function(self, delta)
        onMouseWheel(delta)
    end)

    if editBox then
        editBox:EnableMouseWheel(true)
        editBox:SetScript("OnMouseWheel", function(self, delta)
            onMouseWheel(delta)
        end)
    end

    -- Initial state synchronization
    applyValue(currentValue, false, true)

    -- 2.9 PUBLIC API METHODS
    function stepper:getValue()
        return currentValue
    end
    stepper.GetValue = stepper.getValue

    function stepper:setValue(val, isSilent, isUserInput)
        applyValue(tonumber(val) or self.minValue, isUserInput or false, isSilent or false)
    end
    stepper.SetValue = stepper.setValue

    function stepper:setMinMaxValues(minVal, maxVal)
        self.minValue = minVal
        self.maxValue = maxVal
        applyValue(currentValue, false, true)
    end
    stepper.SetMinMaxValues = stepper.setMinMaxValues

    function stepper:getMinMaxValues()
        return self.minValue, self.maxValue
    end
    stepper.GetMinMaxValues = stepper.getMinMaxValues

    function stepper:setStep(newStep)
        self.step = newStep
        applyValue(currentValue, false, true)
    end
    stepper.SetStep = stepper.setStep

    function stepper:setEnabled(enabled)
        self.isEnabled = enabled
        self.inputField:SetEnabled(enabled)
        updateButtonStates()
    end
    stepper.SetEnabled = stepper.setEnabled

    function stepper:getInputField()
        return self.inputField
    end
    stepper.GetInputField = stepper.getInputField

    function stepper:getMinusButton()
        return self.minusButton
    end
    stepper.GetMinusButton = stepper.getMinusButton

    function stepper:getPlusButton()
        return self.plusButton
    end
    stepper.GetPlusButton = stepper.getPlusButton

    return stepper
end

-------------------------------------------------------------------------------
-- 3. EXTENSION & EXPANSION NOTES
-- Objective: Guidelines for custom unit suffixes (e.g. "ms", "%", "px"), multiplier accelerators, and custom bounds.
--
-- How to expand:
-- 1. Unit Suffixes:
--    Add `options.suffix = "%"` or `options.unit = "px"` to automatically append and strip unit labels in the input field.
-- 2. Shift/Ctrl Accelerators:
--    Hook `IsShiftKeyDown()` / `IsControlKeyDown()` during button clicks or mouse wheel spins
--    to multiply step increments (e.g. 10x with Shift, 100x with Ctrl).
-- 3. Custom Value Formatters:
--    Accept a custom formatting callback `options.formatValue = function(val) return ... end`
--    for displaying custom representations (e.g. time durations "01:30" or currency gold/silver).
-------------------------------------------------------------------------------
