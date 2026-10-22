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
    local styles = self.styles
    local parent = options.parent or UIParent

    -- Acquire a FontString element from the pool.
    -- "FontString": The WoW UI object type specifically designed for rendering text.
    -- parent: The frame that this text will attach to.
    -- { ... }: Configuration table for positioning.
    local header = self:acquireElement("FontString", parent, {
        text = options.text
    })

    header:SetTextColor(unpack(styles.colors.primaryHover))
    header:SetShadowColor(unpack(options.shadowColor or styles.colors.surfaceDark))
    header:SetShadowOffset(2, -2)
    local fontSize = options.fontSize or 24
    local defaultFont = (GameFontNormal and GameFontNormal.GetFont and select(1, GameFontNormal:GetFont())) or "Fonts\\FRIZQT__.TTF"
    local fontFile = options.fontFamily or defaultFont
    header:SetFont(fontFile, fontSize)
    local isElastic = options.elasticWidth or options.elastic or (options.wordWrap == true)
    if options.wordWrap ~= nil then
        header:SetWordWrap(options.wordWrap)
    elseif isElastic then
        header:SetWordWrap(true)
    end
    if options.justifyH then
        header:SetJustifyH(options.justifyH)
    end

    local point = options.point or options.anchorPoint or "TOPLEFT"
    local yOffset = options.yOffset or 0
    local targetParent = options.relativeTo or parent

    if options.point or options.anchorPoint or options.xOffset or options.yOffset then
        header:ClearAllPoints()
        header:SetPoint(
            point,
            targetParent,
            options.relativePoint or point,
            options.xOffset or 0,
            yOffset
        )
    end

    if options.width then
        header:SetWidth(options.width)
    elseif options.rightOffset or isElastic then
        local rightOffset = options.rightOffset or (options.xOffset and -options.xOffset) or -10
        if string.find(point, "TOP") then
            header:SetPoint("TOPRIGHT", targetParent, "TOPRIGHT", rightOffset, yOffset)
        elseif string.find(point, "BOTTOM") then
            header:SetPoint("BOTTOMRIGHT", targetParent, "BOTTOMRIGHT", rightOffset, yOffset)
        else
            header:SetPoint("RIGHT", targetParent, "RIGHT", rightOffset, yOffset)
        end
    end

    local textHeight = header:GetStringHeight()
    if not textHeight or textHeight == 0 then
        textHeight = fontSize
    end
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
    local styles = self.styles
    local parent = options.parent or UIParent

    local label = self:acquireElement("FontString", parent, {
        text = options.text
    })

    label:SetTextColor(unpack(styles.colors.white))
    label:SetShadowColor(unpack(options.shadowColor or styles.colors.black))
    label:SetShadowOffset(1, -1)
    local fontSize = options.fontSize or 18
    local defaultFont = (GameFontNormal and GameFontNormal.GetFont and select(1, GameFontNormal:GetFont())) or "Fonts\\FRIZQT__.TTF"
    local fontFile = options.fontFamily or defaultFont
    label:SetFont(fontFile, fontSize)
    local isElastic = options.elasticWidth or options.elastic or (options.wordWrap == true)
    if options.wordWrap ~= nil then
        label:SetWordWrap(options.wordWrap)
    elseif isElastic then
        label:SetWordWrap(true)
    end
    if options.justifyH then
        label:SetJustifyH(options.justifyH)
    end

    local point = options.point or options.anchorPoint or "TOPLEFT"
    local yOffset = options.yOffset or 0
    local targetParent = options.relativeTo or parent

    if options.point or options.anchorPoint or options.xOffset or options.yOffset then
        label:ClearAllPoints()
        label:SetPoint(
            point,
            targetParent,
            options.relativePoint or point,
            options.xOffset or 0,
            yOffset
        )
    end

    if options.width then
        label:SetWidth(options.width)
    elseif options.rightOffset or isElastic then
        local rightOffset = options.rightOffset or (options.xOffset and -options.xOffset) or -10
        if string.find(point, "TOP") then
            label:SetPoint("TOPRIGHT", targetParent, "TOPRIGHT", rightOffset, yOffset)
        elseif string.find(point, "BOTTOM") then
            label:SetPoint("BOTTOMRIGHT", targetParent, "BOTTOMRIGHT", rightOffset, yOffset)
        else
            label:SetPoint("RIGHT", targetParent, "RIGHT", rightOffset, yOffset)
        end
    end

    local textHeight = label:GetStringHeight()
    if not textHeight or textHeight == 0 then
        textHeight = fontSize
    end
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
    local styles = self.styles
    local parent = options.parent or UIParent

    local paragraph = self:acquireElement("FontString", parent, {
        text = options.text
    })

    local fontSize = options.fontSize or 12
    local defaultFont = (GameFontNormal and GameFontNormal.GetFont and select(1, GameFontNormal:GetFont())) or "Fonts\\FRIZQT__.TTF"
    local fontFile = options.fontFamily or defaultFont
    paragraph:SetFont(fontFile, fontSize)
    paragraph:SetTextColor(unpack(styles.colors.white))
    paragraph:SetWordWrap(true)
    paragraph:SetJustifyH(options.justifyH or "LEFT")

    local point = options.point or options.anchorPoint or "TOPLEFT"
    local yOffset = options.yOffset or 0
    local targetParent = options.relativeTo or parent

    if options.point or options.anchorPoint or options.xOffset or options.yOffset then
        paragraph:ClearAllPoints()
        paragraph:SetPoint(
            point,
            targetParent,
            options.relativePoint or point,
            options.xOffset or 0,
            yOffset
        )
    end

    if options.width then
        paragraph:SetWidth(options.width)
    else
        local rightOffset = options.rightOffset or (options.xOffset and -options.xOffset) or -10
        if string.find(point, "TOP") then
            paragraph:SetPoint("TOPRIGHT", targetParent, "TOPRIGHT", rightOffset, yOffset)
        elseif string.find(point, "BOTTOM") then
            paragraph:SetPoint("BOTTOMRIGHT", targetParent, "BOTTOMRIGHT", rightOffset, yOffset)
        else
            paragraph:SetPoint("RIGHT", targetParent, "RIGHT", rightOffset, yOffset)
        end
    end

    local textHeight = paragraph:GetStringHeight()
    if not textHeight or textHeight == 0 then
        textHeight = fontSize
    end
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
