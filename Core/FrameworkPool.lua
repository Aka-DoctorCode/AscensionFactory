-------------------------------------------------------------------------------
-- Project: AscensionFactory
-- Author: Aka-DoctorCode
-- File: FrameworkPool.lua
-------------------------------------------------------------------------------
---@diagnostic disable: undefined-global, undefined-field, inject-field

-------------------------------------------------------------------------------
-- 1. INITIALIZATION
-- Objective: Initialize the FrameworkPool and link it to the global AscensionFactory library.
-- Variables:
-- MAJOR: The namespace identifier for the addon library.
-------------------------------------------------------------------------------
local MAJOR = "AscensionFactory"
local lib = LibStub:GetLibrary(MAJOR)
if not lib then return end

local Context = lib.Context
if not Context then return end

-------------------------------------------------------------------------------
-- 2. SPECIFIC ELEMENT RESETTERS
-- Objective: Defines cleanup functions for different UI elements before returning them to their respective pools. This prevents memory leaks and visual bugs.
-- Variables:
-- pool: The pool object managing the element.
-- button, statusBar, frame, texture, fontString: The UI element being reset.
-------------------------------------------------------------------------------

-- Helper to hide all attached regions (textures, fontstrings) on a frame before returning to pool.
local function hideAllRegions(frame)
    if frame.GetRegions then
        local regions = { frame:GetRegions() }
        for _, region in ipairs(regions) do
            region:Hide()
        end
    end
end

-- Cleans up a standard button before returning it to the pool.
local function resetButton(pool, button)
    button:Hide()
    button:ClearAllPoints()
    button:SetScript("OnClick", nil)
    button:SetEnabled(true)
    hideAllRegions(button)
    
    button.trackColors = nil
    button.borderColors = nil
    button.labelColors = nil
    button.hoverConfig = nil
    button.updateAppearance = nil
    button.onClickCallback = nil
    button.uiContext = nil
    button.elementType = nil
end

-- Cleans up a standard status bar before returning it to the pool.
local function resetStatusBar(pool, statusBar)
    statusBar:Hide()
    statusBar:ClearAllPoints()
    statusBar:SetMinMaxValues(0, 1)
    statusBar:SetValue(0)
    statusBar:SetStatusBarColor(1, 1, 1, 1) -- #FFFFFF
    statusBar:SetScript("OnValueChanged", nil)
    statusBar.uiContext = nil
    statusBar.elementType = nil
end

-- Cleans up a generic panel frame before returning it to the pool.
local function resetFrame(pool, frame)
    frame:Hide()
    frame:ClearAllPoints()
    frame:SetScript("OnUpdate", nil)
    frame:SetScript("OnEvent", nil)
    frame:UnregisterAllEvents()
    hideAllRegions(frame)
    frame.onUpdateCallback = nil
    frame.onEventCallback = nil
    frame.hoverConfig = nil
    frame.updateAppearance = nil
    frame.uiContext = nil
    frame.elementType = nil
end

-- Cleans up a CheckButton.
local function resetCheckButton(pool, button)
    button:Hide()
    button:ClearAllPoints()
    button:SetChecked(false)
    button:SetScript("OnClick", nil)
    button:SetEnabled(true)
    hideAllRegions(button)
    button.onClickCallback = nil
    button.hoverConfig = nil
    button.updateAppearance = nil
    button.uiContext = nil
    button.elementType = nil
end

-- Cleans up an EditBox.
local function resetEditBox(pool, editBox)
    editBox:Hide()
    editBox:ClearAllPoints()
    editBox:SetText("")
    editBox:ClearFocus()
    editBox:SetScript("OnTextChanged", nil)
    editBox:SetScript("OnEnterPressed", nil)
    editBox:SetScript("OnEscapePressed", nil)
    editBox.onTextChangedCallback = nil
    editBox.onEnterPressedCallback = nil
    editBox.onEscapePressedCallback = nil
    editBox.uiContext = nil
    editBox.elementType = nil
end

-- Cleans up a ScrollFrame.
local function resetScrollFrame(pool, scrollFrame)
    scrollFrame:Hide()
    scrollFrame:ClearAllPoints()
    local scrollChild = scrollFrame:GetScrollChild()
    if scrollChild then
        scrollChild:Hide()
        scrollChild:ClearAllPoints()
    end
    scrollFrame.uiContext = nil
    scrollFrame.elementType = nil
end

-- Cleans up a Slider.
local function resetSlider(pool, slider)
    slider:Hide()
    slider:ClearAllPoints()
    slider:SetMinMaxValues(0, 1)
    slider:SetValue(0)
    slider:SetScript("OnValueChanged", nil)
    slider.onValueChangedCallback = nil
    slider.uiContext = nil
    slider.elementType = nil
end

-- Cleans up a Model.
local function resetModel(pool, model)
    model:Hide()
    model:ClearAllPoints()
    model:ClearModel()
    model.uiContext = nil
    model.elementType = nil
end

-- Cleans up a pooled texture layer.
local function resetTexture(pool, texture)
    texture:Hide()
    texture:ClearAllPoints()
    texture:SetTexture(nil)
    texture:SetAtlas(nil)
    texture:SetVertexColor(1, 1, 1, 1) -- #FFFFFF
    texture:SetAlpha(1.00)
    texture:SetRotation(0)
    texture.uiContext = nil
    texture.elementType = nil
end

-- Cleans up a pooled FontString layer.
local function resetFontString(pool, fontString)
    fontString:Hide()
    fontString:ClearAllPoints()
    fontString:SetText("")
    fontString:SetTextColor(1, 1, 1, 1) -- #FFFFFF
    fontString:SetAlpha(1.00)
    fontString:SetFontObject("GameFontNormal")
    fontString:SetShadowOffset(0, 0)
    fontString:SetWordWrap(false)
    fontString:SetJustifyH("LEFT")
    fontString:SetWidth(0)
    fontString.uiContext = nil
    fontString.elementType = nil
end

-------------------------------------------------------------------------------
-- 2. REGISTRY INITIALIZATION
-- Objective: Lazy-initializes the multi-pool system registry within the framework context to manage UI elements.
-- Variables:
-- parentFrame: The default parent frame for all pooled elements.
-------------------------------------------------------------------------------

-- Lazy-initializes the multi-pool system registry within the framework context.
function Context:initializeFrameworkPools(parentFrame)
    if self.pools then return end
    
    self.pools = {
        Button = CreateFramePool("Button", parentFrame, nil, resetButton),
        StatusBar = CreateFramePool("StatusBar", parentFrame, "BackdropTemplate", resetStatusBar),
        Frame = CreateFramePool("Frame", parentFrame, "BackdropTemplate", resetFrame),
        CheckButton = CreateFramePool("CheckButton", parentFrame, nil, resetCheckButton),
        EditBox = CreateFramePool("EditBox", parentFrame, nil, resetEditBox),
        ScrollFrame = CreateFramePool("ScrollFrame", parentFrame, nil, resetScrollFrame),
        Slider = CreateFramePool("Slider", parentFrame, nil, resetSlider),
        Model = CreateFramePool("Model", parentFrame, nil, resetModel),
        Texture = CreateTexturePool(parentFrame, "BACKGROUND", 0, nil, resetTexture),
        FontString = CreateFontStringPool(parentFrame, "ARTWORK", 0, "GameFontNormal", resetFontString)
    }
end

-------------------------------------------------------------------------------
-- 3. UNIFIED ACQUISITION GATEWAY
-- Objective: Dynamically acquires a recycled or brand-new UI element of the specified type, and configures it.
-- Variables:
-- elementType: String identifier for the WoW UI object instance ("Button", "StatusBar", etc).
-- parent: The parent frame mapping containment hierarchies.
-- options: Structural layout and initialization configurations.
-------------------------------------------------------------------------------

-- Dynamically acquires a recycled or brand-new UI element of the specified type.
function Context:acquireElement(elementType, parent, options)
    if not self.pools then
        self:initializeFrameworkPools(parent or UIParent)
    end
    
    local pool = self.pools[elementType]
    if not pool then return end
    
    -- Acquire element from the respective type-safe hotel.
    local element, isNew = pool:Acquire()
    element.uiContext = self
    element.elementType = elementType
    
    -- Dynamically enforce parenthood update if needed.
    if element.SetParent and parent and element:GetParent() ~= parent then
        element:SetParent(parent)
    end
    
    -- 1. Type-Specific Initialization (Only executed upon fresh memory instantiation)
    if isNew then
        if elementType == "StatusBar" then
            local background = element:CreateTexture(nil, "BACKGROUND")
            background:SetAllPoints()
            local bgColor = options.bgColor or lib.DefaultStyles.colors.white
            background:SetColorTexture(unpack(bgColor))
            element.background = background
            local fill = element:CreateStatusBarTexture()
            local fillColor = options.fillColor or options.color or lib.DefaultStyles.colors.background
            fill:SetColorTexture(unpack(fillColor))
            element:SetStatusBarTexture(fill)
        end
    end
    
    -- 2. Generic Layout Configuration
    if options.width and options.height then
        element:SetSize(options.width, options.height)
    end
    
    if options.anchorPoint then
        element:ClearAllPoints()
        -- SetPoint args:
        -- 1: options.anchorPoint (this element's anchor point)
        -- 2: options.relativeTo or parent or UIParent (target frame)
        -- 3: options.relativePoint or options.anchorPoint (target's anchor point)
        -- 4: options.xOffset or 0 (X offset)
        -- 5: options.yOffset or 0 (Y offset)
        element:SetPoint(
            options.anchorPoint,
            options.relativeTo or parent or UIParent,
            options.relativePoint or options.anchorPoint,
            options.xOffset or 0,
            options.yOffset or 0
        )
    end
    
    -- 3. Dynamic Configuration Applications
    if elementType == "Button" then
        if options.text then
            local fontString = element:GetFontString() or element:CreateFontString(nil, "ARTWORK")
            fontString:SetFontObject(options.font or lib.DefaultStyles.fonts.label)
            fontString:SetText(options.text)
            element:SetFontString(fontString)
        end
        if options.onClick then
            element.onClickCallback = options.onClick
            element:SetScript("OnClick", function(self, ...)
                if self.onClickCallback then
                    self.onClickCallback(self, ...)
                end
            end)
        end
    elseif elementType == "StatusBar" then
        if options.minValue and options.maxValue then
            element:SetMinMaxValues(options.minValue, options.maxValue)
        end
        if options.value then
            element:SetValue(options.value)
        end
        if options.onValueChanged then
            element.onValueChangedCallback = options.onValueChanged
            element:SetScript("OnValueChanged", function(self, ...)
                if self.onValueChangedCallback then
                    self.onValueChangedCallback(self, ...)
                end
            end)
        end
        local bgColor = options.bgColor or lib.DefaultStyles.colors.white
        if element.background then
            element.background:SetColorTexture(unpack(bgColor))
        end
        local fillColor = options.fillColor or options.color or lib.DefaultStyles.colors.background
        element:GetStatusBarTexture():SetColorTexture(unpack(fillColor))
    elseif elementType == "Texture" then
        if options.texturePath then
            element:SetTexture(options.texturePath)
        elseif options.atlasName then
            element:SetAtlas(options.atlasName)
        elseif options.color then
            element:SetColorTexture(unpack(options.color))
        end
        if options.drawLayer then
            element:SetDrawLayer(options.drawLayer)
        end
    elseif elementType == "FontString" then
        if options.text then
            element:SetText(options.text)
        end
        if options.color then
            element:SetTextColor(unpack(options.color))
        end
    elseif elementType == "Frame" then
        if options.onUpdate then
            element.onUpdateCallback = options.onUpdate
            element:SetScript("OnUpdate", function(self, ...)
                if self.onUpdateCallback then
                    self.onUpdateCallback(self, ...)
                end
            end)
        end
        if options.onEvent then
            element.onEventCallback = options.onEvent
            element:SetScript("OnEvent", function(self, ...)
                if self.onEventCallback then
                    self.onEventCallback(self, ...)
                end
            end)
        end
    elseif elementType == "CheckButton" then
        if options.checked ~= nil then
            element:SetChecked(options.checked)
        end
        if options.onClick then
            element.onClickCallback = options.onClick
            element:SetScript("OnClick", function(self, ...)
                if self.onClickCallback then
                    self.onClickCallback(self, ...)
                end
            end)
        end
        if options.text then
            local textString = element.Text or _G[element:GetName().."Text"]
            if textString and textString.SetText then
                textString:SetText(options.text)
            end
        end
    elseif elementType == "EditBox" then
        if options.text then
            element:SetText(options.text)
        end
        if options.onTextChanged then
            element.onTextChangedCallback = options.onTextChanged
            element:SetScript("OnTextChanged", function(self, ...)
                if self.onTextChangedCallback then
                    self.onTextChangedCallback(self, ...)
                end
            end)
        end
        if options.onEnterPressed then
            element.onEnterPressedCallback = options.onEnterPressed
            element:SetScript("OnEnterPressed", function(self, ...)
                if self.onEnterPressedCallback then
                    self.onEnterPressedCallback(self, ...)
                end
            end)
        end
        if options.onEscapePressed then
            element.onEscapePressedCallback = options.onEscapePressed
            element:SetScript("OnEscapePressed", function(self, ...)
                if self.onEscapePressedCallback then
                    self.onEscapePressedCallback(self, ...)
                end
            end)
        end
    elseif elementType == "ScrollFrame" then
        if options.scrollChild then
            element:SetScrollChild(options.scrollChild)
        end
    elseif elementType == "Slider" then
        if options.minVal and options.maxVal then
            element:SetMinMaxValues(options.minVal, options.maxVal)
        end
        if options.value then
            element:SetValue(options.value)
        end
        if options.valueStep then
            element:SetValueStep(options.valueStep)
        end
        if options.onValueChanged then
            element.onValueChangedCallback = options.onValueChanged
            element:SetScript("OnValueChanged", function(self, ...)
                if self.onValueChangedCallback then
                    self.onValueChangedCallback(self, ...)
                end
            end)
        end
    elseif elementType == "Model" then
        if options.modelPath then
            element:SetModel(options.modelPath)
        elseif options.modelFileID then
            element:SetModelFileID(options.modelFileID)
        end
    end
    
    element:Show()
    return element
end

-------------------------------------------------------------------------------
-- 4. UNIFIED RELEASE GATEWAY
-- Objective: Releases active elements back into their respective pools for future reuse.
-- Variables:
-- elementType: String identifier of the pool.
-- element: The specific UI frame or layer to return.
-------------------------------------------------------------------------------

-- Instantly releases a single active element back to its type-safe pool.
function Context:releaseElement(elementType, element)
    if self.pools and self.pools[elementType] then
        self.pools[elementType]:Release(element)
    end
end

-- Instantly releases a single element and all its children/regions back to their pools.
function Context:releaseElementAndChildren(element)
    if not element then return end

    -- Release all child frames first
    if element.GetChildren then
        local children = { element:GetChildren() }
        for _, child in ipairs(children) do
            self:releaseElementAndChildren(child)
        end
    end

    -- Release all child regions (textures, fontstrings, etc.)
    if element.GetRegions then
        local regions = { element:GetRegions() }
        for _, region in ipairs(regions) do
            if region.elementType then
                self:releaseElement(region.elementType, region)
            end
        end
    end

    -- Finally, release the element itself
    if element.elementType then
        self:releaseElement(element.elementType, element)
    end
end

-- Instantly releases all managed resources back into their active pools.
-- Call this during global frame hides, tab changes, or component cleanups.
function Context:releaseAllElements()
    if not self.pools then return end
    for _, pool in pairs(self.pools) do
        pool:ReleaseAll()
    end
end

--- Hides and clears anchors for all children and regions of an arbitrary frame.
--- Also releases any pooled elements attached to the frame.
--- Useful for recycling dynamic panels or clearing content before a redraw.
--- @param contentFrame table The frame container to clean.
function Context:cleanupContent(contentFrame)
    if not contentFrame then return end

    -- Release or hide child frames
    if contentFrame.GetChildren then
        local children = { contentFrame:GetChildren() }
        for _, child in ipairs(children) do
            if child.elementType and self.releaseElement then
                self:releaseElement(child.elementType, child)
            elseif child.Hide then
                child:Hide()
                child:ClearAllPoints()
            end
        end
    end

    -- Release or hide regions (textures, fontstrings)
    if contentFrame.GetRegions then
        local regions = { contentFrame:GetRegions() }
        for _, region in ipairs(regions) do
            if region.elementType and self.releaseElement then
                self:releaseElement(region.elementType, region)
            elseif region.Hide then
                region:Hide()
                region:ClearAllPoints()
            end
        end
    end
end

-- Backward compatibility aliases
Context.AcquireElement = Context.acquireElement
Context.ReleaseElement = Context.releaseElement
Context.ReleaseElementAndChildren = Context.releaseElementAndChildren
Context.InitializeFrameworkPools = Context.initializeFrameworkPools
Context.ReleaseAllElements = Context.releaseAllElements
Context.CleanupContent = Context.cleanupContent

-------------------------------------------------------------------------------
-- 5. EXTENSION & EXPANSION NOTES
-- Objective: Guidelines for adding custom frame pools, specialized resetters, and memory debugging.
--
-- How to expand:
-- 1. Register Custom Frame Pools:
--    Add new object pools inside `initializeFrameworkPools` (e.g. `ColorSelect`, `MovieFrame`, `Cooldown`)
--    using `CreateFramePool("<Type>", parentFrame, template, customResetFunction)`.
-- 2. Custom Reset Logic:
--    Ensure all state mutations, script bindings (`SetScript`), child references, and
--    custom member variables attached during component lifecycle are cleared in the reset function
--    to prevent cross-contamination when widgets are recycled.
-- 3. Memory Debugging:
--    Track pool growth by querying `pool:GetNumActive()` and `pool:EnumerateActive()`
--    to ensure frames are properly recycled without leaking memory during tab switches or frame closures.
-------------------------------------------------------------------------------