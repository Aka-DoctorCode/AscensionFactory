-------------------------------------------------------------------------------
-- Project: AscensionFactory
-- Author: Aka-DoctorCode
-- File: 16Accordion.lua
-------------------------------------------------------------------------------
---@diagnostic disable: undefined-global, undefined-field, inject-field

-------------------------------------------------------------------------------
-- 1. INITIALIZATION & NAMESPACE REGISTRATION
-- Objective: Register the Accordion component in the AscensionFactory Context.
-------------------------------------------------------------------------------
local MAJOR = "AscensionFactory"
local lib = LibStub:GetLibrary(MAJOR)
if not lib then return end

local Context = lib.Context
if not Context then return end

-------------------------------------------------------------------------------
-- 2. ACCORDION COMPONENT CONSTRUCTOR
-- Objective: Create an expandable card container with a header button,
-- chevron indicator, and isolated content container with internal LayoutModel.
-------------------------------------------------------------------------------

--- Creates an expandable Accordion Card component.
--- @param options table Options table:
---   name: string (Required) Unique identifier
---   parent: table (Required) Parent frame
---   title: string|nil Accordion header title
---   subtitle: string|nil Optional subtitle or status text on the right
---   expanded: boolean|nil Initial expansion state (default: false)
---   width: number|nil Width in pixels (or dynamic if fluidWidth)
---   fluidWidth: boolean|nil If true, stretches with parent width (default: true)
---   rightOffset: number|nil Right padding offset for fluidWidth (default: -10)
---   headerHeight: number|nil Height of the header bar (default: 28)
---   contentPadding: number|nil Inner padding of the content frame (default: 10)
---   onToggle: function(isExpanded, accordion)|nil Callback when state changes
---   populate: function(contentLayout, contentFrame, accordion)|nil Builder function
---   group: table|nil Accordion group coordinator for singleExpand
--- @return table accordion Frame instance
function Context:createAccordion(options)
    assert(type(options) == "table", "options table required for createAccordion")
    assert(options.parent, "options.parent is required for createAccordion")
    assert(options.name, "options.name is required for createAccordion")

    local styles = self.styles
    local parent = options.parent
    local isFluid = (options.fluidWidth ~= false)
    local width = options.width or (isFluid and (parent:GetWidth() > 20 and parent:GetWidth() - 20 or 300) or 300)
    local headerHeight = options.headerHeight or 28
    local contentPadding = options.contentPadding or 10
    local titleText = options.title or options.text or ""
    local initialExpanded = options.expanded or options.initialExpanded or false

    -- 2.1 ROOT WRAPPER FRAME
    local accordion = self:acquireElement("Frame", parent, {
        name = options.name,
    })
    accordion:SetWidth(width)
    accordion:SetHeight(headerHeight)
    accordion.isFluidWidth = isFluid
    accordion.rightOffset = options.rightOffset or -10
    accordion.isExpandedState = initialExpanded

    -- Outer border / Card frame setup
    if not accordion.border then
        local border = accordion:CreateTexture(nil, "BACKGROUND", nil, -2)
        border:SetAllPoints(accordion)
        accordion.border = border
    end
    accordion.border:SetColorTexture(unpack(styles.colors.border))

    -- Background for entire card
    if not accordion.background then
        local bg = accordion:CreateTexture(nil, "BACKGROUND", nil, -1)
        bg:SetPoint("TOPLEFT", accordion, "TOPLEFT", 1, -1)
        bg:SetPoint("BOTTOMRIGHT", accordion, "BOTTOMRIGHT", -1, 1)
        accordion.background = bg
    end
    accordion.background:SetColorTexture(unpack(styles.colors.surfaceDark))

    -- 2.2 CARD HEADER BAR
    local header = self:createButton({
        name = options.name .. "_Header",
        parent = accordion,
        width = width,
        height = headerHeight,
        text = "",
        tooltip = options.tooltip or false,
    })
    header:ClearAllPoints()
    header:SetPoint("TOPLEFT", accordion, "TOPLEFT", 0, 0)
    header:SetPoint("TOPRIGHT", accordion, "TOPRIGHT", 0, 0)
    header:SetHeight(headerHeight)

    -- Header background (distinguished from content area)
    if header.background then
        header.background:SetColorTexture(unpack(styles.colors.surfaceLight))
    end

    -- Rotating chevron arrow icon
    local arrow = self:createIconButton({
        name = options.name .. "_Arrow",
        parent = header,
        iconType = "arrowright",
        size = 18,
        tooltip = false,
        point = "LEFT",
        relativeTo = header,
        relativePoint = "LEFT",
        xOffset = 6,
        yOffset = 0,
    })
    arrow:EnableMouse(false)

    -- Title label
    local titleLabel = self:createLabel({
        name = options.name .. "_Title",
        parent = header,
        text = titleText,
        fontSize = options.titleFontSize or 15,
        point = "LEFT",
        relativeTo = arrow,
        relativePoint = "RIGHT",
        xOffset = 6,
        yOffset = 0,
        wordWrap = false,
    })

    -- Optional subtitle / status indicator on the right
    local subtitleLabel = nil
    if options.subtitle then
        subtitleLabel = self:createLabel({
            name = options.name .. "_Subtitle",
            parent = header,
            text = options.subtitle,
            fontSize = 12,
            point = "RIGHT",
            relativeTo = header,
            relativePoint = "RIGHT",
            xOffset = -10,
            yOffset = 0,
            wordWrap = false,
        })
        if subtitleLabel and subtitleLabel.SetTextColor then
            subtitleLabel:SetTextColor(unpack(styles.colors.muted or { 0.7, 0.7, 0.7, 1 }))
        end
    end

    -- Bottom border separating header from content when expanded
    local headerDivider = header:CreateTexture(nil, "OVERLAY", nil, 1)
    headerDivider:SetHeight(1)
    headerDivider:SetPoint("BOTTOMLEFT", header, "BOTTOMLEFT", 0, 0)
    headerDivider:SetPoint("BOTTOMRIGHT", header, "BOTTOMRIGHT", 0, 0)
    headerDivider:SetColorTexture(unpack(styles.colors.border))
    headerDivider:Hide()

    -- 2.3 CONTENT CONTAINER & INTERNAL LAYOUT
    local contentFrame = self:acquireElement("Frame", accordion, {
        name = options.name .. "_Content",
    })
    contentFrame:ClearAllPoints()
    contentFrame:SetPoint("TOPLEFT", header, "BOTTOMLEFT", contentPadding, -contentPadding)
    contentFrame:SetPoint("TOPRIGHT", header, "BOTTOMRIGHT", -contentPadding, -contentPadding)
    contentFrame:SetHeight(1)
    contentFrame:Hide()

    local defaultGap = (self.getDefaultGap and self:getDefaultGap()) or 10
    local contentLayout = self:createLayoutModel(contentFrame, {
        threshold = options.threshold or 420,
        verticalGap = options.verticalGap or defaultGap,
        bottomPadding = options.bottomPadding or contentPadding,
        responsive = true,
        onContainerResized = function()
            if accordion.isExpandedState and accordion.updateHeight then
                accordion:updateHeight()
            end
        end,
    })

    -- Link references on accordion instance
    accordion.header = header
    accordion.arrow = arrow
    accordion.titleLabel = titleLabel
    accordion.subtitleLabel = subtitleLabel
    accordion.headerDivider = headerDivider
    accordion.content = contentFrame
    accordion.contentFrame = contentFrame
    accordion.contentLayout = contentLayout
    accordion.contentPadding = contentPadding
    accordion.headerHeight = headerHeight
    accordion.onToggle = options.onToggle
    accordion.group = options.group

    -- 2.4 STATE MANAGEMENT & NOTIFICATIONS
    local function updateArrow(isExp)
        if arrow.setIconRotation then
            arrow:setIconRotation(isExp and -90 or 0)
        end
    end
    updateArrow(initialExpanded)

    --- Updates the total height of the card frame to fit header + content (Trifasic Pipeline 2.D)
    function accordion:updateHeight()
        if not self.isExpandedState then
            self:SetHeight(self.headerHeight)
            if self._parentLayout and self._parentLayout.onChildResized then
                self._parentLayout:onChildResized(self, self.headerHeight)
            end
            return self.headerHeight
        end

        local calculatedHeight = math.max(10, (contentLayout.accumulatedHeight or 10) + self.contentPadding)
        contentFrame:SetHeight(calculatedHeight)

        local totalH = self.headerHeight + calculatedHeight + self.contentPadding
        self:SetHeight(totalH)

        if self._parentLayout and self._parentLayout.onChildResized then
            self._parentLayout:onChildResized(self, totalH)
        end

        return totalH
    end

    --- Expands or collapses the accordion
    --- @param isExpanded boolean
    --- @param skipCallback boolean|nil
    function accordion:setExpanded(isExpanded, skipCallback)
        self.isExpandedState = isExpanded and true or false
        updateArrow(self.isExpandedState)

        if self.isExpandedState then
            -- If coordinating through a group with singleExpand, collapse siblings
            if self.group and self.group.singleExpand and self.group.accordions then
                for _, other in ipairs(self.group.accordions) do
                    if other ~= self and other.isExpanded and other:isExpanded() then
                        other:setExpanded(false, false)
                    end
                end
            end

            headerDivider:Show()
            contentFrame:Show()
            self:updateHeight()

            -- Responsive update inside content layout
            local availW = self:GetWidth() - (self.contentPadding * 2)
            if availW > 0 and contentLayout.notifyResponsive then
                contentLayout:notifyResponsive((availW < (options.threshold or 420)) and "compact" or "normal", availW, self:GetHeight())
            end
        else
            headerDivider:Hide()
            contentFrame:Hide()
            self:SetHeight(self.headerHeight)
            if self._parentLayout and self._parentLayout.onChildResized then
                self._parentLayout:onChildResized(self, self.headerHeight)
            end
        end

        -- Propagate scroll range to parent scrollable container if available
        if contentLayout.updateScrollRangeIfAvailable then
            contentLayout:updateScrollRangeIfAvailable()
        end

        if not skipCallback and self.onToggle then
            self.onToggle(self.isExpandedState, self)
        end
    end

    function accordion:isExpanded()
        return self.isExpandedState
    end

    function accordion:toggle()
        self:setExpanded(not self.isExpandedState)
    end

    function accordion:setTitle(text)
        if titleLabel and titleLabel.SetText then
            titleLabel:SetText(text or "")
        end
    end

    function accordion:setSubtitle(text)
        if subtitleLabel and subtitleLabel.SetText then
            subtitleLabel:SetText(text or "")
        end
    end

    function accordion:getLayout()
        return contentLayout
    end

    function accordion:getContent()
        return contentFrame
    end

    -- Hook toggle on header click
    header:SetScript("OnClick", function()
        accordion:toggle()
    end)

    -- Register in group if specified
    if options.group then
        options.group.accordions = options.group.accordions or {}
        table.insert(options.group.accordions, accordion)
    end

    -- Run populate callback if provided
    if type(options.populate) == "function" then
        options.populate(contentLayout, contentFrame, accordion)
        if contentLayout.recalculateAccumulatedHeight then
            contentLayout:recalculateAccumulatedHeight()
        end
    end

    -- Apply initial state
    accordion:setExpanded(initialExpanded, true)

    return accordion
end

Context.CreateAccordion = Context.createAccordion

-------------------------------------------------------------------------------
-- 3. EXTENSION & EXPANSION NOTES
-- Objective: Support nested accordions, badge icons, and group coordination.
-------------------------------------------------------------------------------
