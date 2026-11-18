-------------------------------------------------------------------------------
-- Project: AscensionFactory
-- Author: Aka-DoctorCode
-- File: Text.lua
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

--- Configures a FontString for elastic non-truncating height (`SetHeight(0)`)
--- while keeping its parent LayoutModel synchronized via `GetStringHeight()`.
--- @param element table The FontString instance.
local function attachAutoHeight(element)
    element:SetHeight(0)

    local function syncHeight(target)
        local layout = target._parentLayout
        if not layout or not layout.onChildResized then return end
        local h = target.GetStringHeight and target:GetStringHeight()
        if not h or h <= 0 then return end
        local idx = layout.elementIndexMap and layout.elementIndexMap[target]
        local prevH = idx and layout.elements[idx] and layout.elements[idx].height
        if not prevH or math.abs(h - prevH) > 0.5 then
            layout:onChildResized(target, h)
        end
    end

    element.updateHeight = function(self)
        self:SetHeight(0)
        syncHeight(self)
        if C_Timer and C_Timer.After and not self._pendingHeightTimer then
            self._pendingHeightTimer = true
            local captured = self
            C_Timer.After(0, function()
                captured._pendingHeightTimer = nil
                syncHeight(captured)
            end)
        end
    end
    element.updateLayout = element.updateHeight

    if not element._autoHeightSetTextHooked and element.SetText then
        element._autoHeightSetTextHooked = true
        local origSetText = element.SetText
        element._origSetText = origSetText
        element.SetText = function(self, ...)
            origSetText(self, ...)
            if self.updateHeight then
                self:updateHeight()
            end
        end
    end
end

-------------------------------------------------------------------------------
-- 2. HEADER FACTORY
-- Objective: Creates a stylized section header text element.
-- It acquires a FontString from the pool and sets custom fonts, shadows, and colors.
-- Variables:
-- options (table): Configuration table (text, anchors, offsets, colors, font details).
-- parent (table): The parent frame this header is attached to.
-- header (table): The allocated FontString UI element.
-- nextY (number): The calculated Y offset for the next element below this header.
-------------------------------------------------------------------------------
function Context:createHeader(options)
    assert(type(options) == "table", "options table required for createHeader")
    assert(options.parent, "options.parent is required for createHeader")
    assert(options.name, "options.name is required for createHeader")
    local styles = self.styles
    local rawParent = options.parent
    local parent = rawParent
    if parent and parent.getContent then
        parent = parent:getContent()
    elseif parent and parent.scrollChild then
        parent = parent.scrollChild
    elseif parent and parent.content then
        parent = parent.content
    end

    -- Acquire a FontString element from the pool.
    -- "FontString": The WoW UI object type specifically designed for rendering text.
    -- parent: The frame that this text will attach to.
    -- { ... }: Configuration table for positioning.
    local header = self:acquireElement("FontString", parent, {
        text = options.text
    })
    _G[options.name] = header

    header:SetTextColor(unpack(styles.colors.primaryHover))
    header:SetShadowColor(unpack(options.shadowColor or styles.colors.surfaceDark))
    header:SetShadowOffset(2, -2)
    local fontSize = options.fontSize or 24
    local defaultFont = (GameFontNormal and GameFontNormal.GetFont and select(1, GameFontNormal:GetFont())) or "Fonts\\FRIZQT__.TTF"
    local fontFile = options.fontFamily or defaultFont
    header:SetFont(fontFile, fontSize)
    header:SetWordWrap(options.wordWrap ~= false)
    if options.justifyH then
        header:SetJustifyH(options.justifyH)
    end

    local point = options.point or options.anchorPoint or "TOPLEFT"
    local yOffset = options.yOffset or 0
    local targetParent = options.relativeTo or parent
    local xOffset = options.xOffset or 0

    if options.point or options.anchorPoint or options.xOffset or options.yOffset or options.relativeTo then
        header:ClearAllPoints()
        header:SetPoint(
            point,
            targetParent,
            options.relativePoint or point or "TOPLEFT",
            xOffset,
            yOffset
        )
    end

    if options.width then
        header:SetWidth(options.width)
    elseif options.rightOffset or options.elasticWidth ~= false then
        local rightOffset = options.rightOffset or (xOffset ~= 0 and -math.abs(xOffset)) or -10
        header:SetPoint("RIGHT", parent, "RIGHT", rightOffset, 0)
    end

    local textHeight = header:GetStringHeight()
    if not textHeight or textHeight <= 0 then
        textHeight = fontSize
    end
    attachAutoHeight(header)

    local spaceBelow = options.spaceBelow or 0
    local nextY = yOffset - textHeight - spaceBelow

    return header, nextY
end

-------------------------------------------------------------------------------
-- 3. LABEL FACTORY
-- Objective: Creates a standard single-line text label for UI forms and descriptions.
-- It applies standard shadow styling and a base font size.
-- Variables:
-- options (table): Configuration table containing anchor data, text string, and optional styles.
-- parent (table): The container frame anchoring the label.
-- label (table): The created FontString instance.
-- nextY (number): The calculated Y coordinate for positioning the next element in layout flow.
-------------------------------------------------------------------------------
function Context:createLabel(options)
    assert(type(options) == "table", "options table required for createLabel")
    assert(options.parent, "options.parent is required for createLabel")
    assert(options.name, "options.name is required for createLabel")
    local styles = self.styles
    local rawParent = options.parent
    local parent = rawParent
    if parent and parent.getContent then
        parent = parent:getContent()
    elseif parent and parent.scrollChild then
        parent = parent.scrollChild
    elseif parent and parent.content then
        parent = parent.content
    end

    local label = self:acquireElement("FontString", parent, {
        text = options.text
    })
    _G[options.name] = label

    label:SetTextColor(unpack(styles.colors.white))
    label:SetShadowColor(unpack(options.shadowColor or styles.colors.black))
    label:SetShadowOffset(1, -1)
    local fontSize = options.fontSize or 18
    local defaultFont = (GameFontNormal and GameFontNormal.GetFont and select(1, GameFontNormal:GetFont())) or "Fonts\\FRIZQT__.TTF"
    local fontFile = options.fontFamily or defaultFont
    label:SetFont(fontFile, fontSize)
    label:SetWordWrap(options.wordWrap ~= false)
    if options.justifyH then
        label:SetJustifyH(options.justifyH)
    end

    local point = options.point or options.anchorPoint or "TOPLEFT"
    local yOffset = options.yOffset or 0
    local targetParent = options.relativeTo or parent
    local xOffset = options.xOffset or 0

    if options.point or options.anchorPoint or options.xOffset or options.yOffset or options.relativeTo then
        label:ClearAllPoints()
        label:SetPoint(
            point,
            targetParent,
            options.relativePoint or point or "TOPLEFT",
            xOffset,
            yOffset
        )
    end

    if options.width then
        label:SetWidth(options.width)
    elseif options.rightOffset or options.elasticWidth ~= false then
        local rightOffset = options.rightOffset or (xOffset ~= 0 and -math.abs(xOffset)) or -10
        label:SetPoint("RIGHT", parent, "RIGHT", rightOffset, 0)
    end

    local textHeight = label:GetStringHeight()
    if not textHeight or textHeight <= 0 then
        textHeight = fontSize
    end
    attachAutoHeight(label)

    local spaceBelow = options.spaceBelow or 0
    local nextY = yOffset - textHeight - spaceBelow

    return label, nextY
end

-------------------------------------------------------------------------------
-- 4. PARAGRAPH FACTORY
-- Objective: Creates a multi-line text block that automatically wraps words to fit.
-- Useful for long descriptions, tooltips, or instructions inside panels.
-- Variables:
-- options (table): Configuration table including a rightOffset to constrain wrap width.
-- parent (table): The container frame anchoring the text.
-- paragraph (table): The created FontString instance with SetWordWrap enabled.
-- nextY (number): Calculated Y offset after computing the total wrapped text height.
-------------------------------------------------------------------------------
function Context:createParagraph(options)
    assert(type(options) == "table", "options table required for createParagraph")
    assert(options.parent, "options.parent is required for createParagraph")
    assert(options.name, "options.name is required for createParagraph")
    local styles = self.styles
    local rawParent = options.parent
    local parent = rawParent
    if parent and parent.getContent then
        parent = parent:getContent()
    elseif parent and parent.scrollChild then
        parent = parent.scrollChild
    elseif parent and parent.content then
        parent = parent.content
    end

    local paragraph = self:acquireElement("FontString", parent, {
        text = options.text
    })
    _G[options.name] = paragraph

    local fontSize = options.fontSize or 12
    local defaultFont = (GameFontNormal and GameFontNormal.GetFont and select(1, GameFontNormal:GetFont())) or "Fonts\\FRIZQT__.TTF"
    local fontFile = options.fontFamily or defaultFont
    paragraph:SetFont(fontFile, fontSize)
    paragraph:SetTextColor(unpack(styles.colors.white))
    paragraph:SetWordWrap(options.wordWrap ~= false)
    paragraph:SetJustifyH(options.justifyH or "LEFT")

    local point = options.point or options.anchorPoint or "TOPLEFT"
    local yOffset = options.yOffset or 0
    local targetParent = options.relativeTo or parent
    local xOffset = options.xOffset or 0

    if options.point or options.anchorPoint or options.xOffset or options.yOffset or options.relativeTo then
        paragraph:ClearAllPoints()
        paragraph:SetPoint(
            point,
            targetParent,
            options.relativePoint or point or "TOPLEFT",
            xOffset,
            yOffset
        )
    end

    if options.width then
        paragraph:SetWidth(options.width)
    elseif options.rightOffset or options.elasticWidth ~= false then
        local rightOffset = options.rightOffset or (xOffset ~= 0 and -math.abs(xOffset)) or -10
        paragraph:SetPoint("RIGHT", parent, "RIGHT", rightOffset, 0)
    end

    local textHeight = paragraph:GetStringHeight()
    if not textHeight or textHeight <= 0 then
        textHeight = fontSize
    end
    attachAutoHeight(paragraph)

    local spaceBelow = options.spaceBelow or 0
    local nextY = yOffset - textHeight - spaceBelow

    return paragraph, nextY
end

-------------------------------------------------------------------------------
-- 5. EXTENSION & EXPANSION NOTES
-- Objective: Guidelines for custom font string styling, inline hyperlinks, and formatted text markup.
--
-- How to expand:
-- 1. Hyperlink Support:
--    Hook `SetHyperlinksEnabled(true)` and `OnHyperlinkClick` on paragraphs to support clickable item/spell links.
-- 2. Formatted Key-Value Pairs:
--    Add `Context:createKeyValueText(options)` displaying a dimmed label on left and bright value on right.
-- 3. Dynamic Font Switching:
--    Add support for custom TrueType font paths via `options.fontFamily` or SharedMedia font lookups.
-------------------------------------------------------------------------------
