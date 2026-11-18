-------------------------------------------------------------------------------
-- Project: AscensionFactory
-- Author: Aka-DoctorCode
-- File: 03ColumnGroup.lua
-------------------------------------------------------------------------------
---@diagnostic disable: undefined-global, undefined-field, inject-field

-------------------------------------------------------------------------------
-- 1. INITIALIZATION & NAMESPACE REGISTRATION
-- Objective: Register the autonomous ColumnGroup structural component (Proposal 3.D).
-------------------------------------------------------------------------------
local MAJOR = "AscensionFactory"
local lib = LibStub:GetLibrary(MAJOR)
if not lib then return end

local Context = lib.Context
if not Context then return end

local columnGroupCounter = 0

-------------------------------------------------------------------------------
-- 2. COLUMNGROUP COMPONENT CONSTRUCTOR
-- Objective: Create a self-contained responsive N-column container that applies
-- the trifasic sizing pipeline (2.D) and notifies its parent layout on resize.
-------------------------------------------------------------------------------

--- Creates an autonomous multi-column structural container.
--- @param options table Configuration options:
---   parent: table (Required) Parent frame
---   name: string|nil Optional global identifier
---   gap: number|nil Horizontal/stacking gap between columns (default: Context:getDefaultGap() = 10)
---   threshold / stackThreshold: number|nil Breakpoint width for vertical stacking (default: 480)
---   bottomPadding: number|nil Bottom padding below tallest column (default: 0)
---   rightOffset: number|nil Right offset for fluidWidth (default: 0)
---   fluidWidth: boolean|nil Stretch width to parent container (default: true)
---   columns: table|nil Optional array of column definitions { width, gap, xOffset, populate/build }
---   layout: table|nil Optional LayoutModel to auto-anchor into
--- @return table groupFrame
function Context:createColumnGroup(options)
    assert(type(options) == "table", "options table required for createColumnGroup")
    assert(options.parent, "options.parent is required for createColumnGroup")

    local parent = options.parent
    if parent.getContent then
        parent = parent:getContent()
    elseif parent.scrollChild then
        parent = parent.scrollChild
    elseif parent.content then
        parent = parent.content
    end

    if not options.name then
        columnGroupCounter = columnGroupCounter + 1
        options.name = "AF_ColumnGroup_" .. tostring(columnGroupCounter)
    end

    local defaultGap = (self.getDefaultGap and self:getDefaultGap()) or 10
    local gap = options.gap or defaultGap
    local threshold = options.threshold or options.stackThreshold or 480
    local bottomPadding = options.bottomPadding or 0

    -- 2.1 ROOT CONTAINER ACQUISITION (Non-collapsing 10px base height - Phase 1)
    local groupFrame = self:acquireElement("Frame", parent, {
        name = options.name,
    })
    _G[options.name] = groupFrame
    groupFrame:SetHeight(10)
    groupFrame.fluidWidth = (options.fluidWidth ~= false)
    groupFrame.fluidRightOffset = options.rightOffset or 0
    groupFrame.columns = {}
    groupFrame.gap = gap
    groupFrame.threshold = threshold
    groupFrame.bottomPadding = bottomPadding
    groupFrame.responsiveMode = "normal"
    groupFrame.uiContext = self
    groupFrame._isUpdatingColumnLayout = false

    local initW = (parent.GetWidth and parent:GetWidth()) or 0
    if initW > 0 then
        groupFrame:SetWidth(math.max(10, initW - math.abs(groupFrame.fluidRightOffset)))
    end

    --- Adds a column to the group with its own isolated LayoutModel.
    --- @param colOpts table|nil Column configuration ({ width, gap, xOffset, verticalGap, populate, build }).
    --- @return table colLayout, table colFrame, table colData
    function groupFrame:addColumn(colOpts)
        colOpts = colOpts or {}

        if colOpts.width and type(colOpts.width) == "number" and colOpts.width > 0 and colOpts.width <= 1 then
            colOpts.proportion = colOpts.width
        elseif colOpts.width and type(colOpts.width) == "number" and colOpts.width > 1 then
            colOpts.explicitWidth = colOpts.width
        end

        local colFrame = self.uiContext:acquireElement("Frame", self, {})
        colFrame:SetHeight(10)

        if colOpts.backgroundColor then
            local bg = colFrame.background or self.uiContext:acquireElement("Texture", colFrame, { drawLayer = "BACKGROUND" })
            bg:SetAllPoints(colFrame)
            bg:SetColorTexture(unpack(colOpts.backgroundColor))
            colFrame.background = bg
        end

        local colData = {
            frame = colFrame,
            opts = colOpts,
            height = 10,
        }

        local colLayout = self.uiContext:createLayoutModel(colFrame, {
            verticalGap = colOpts.verticalGap or defaultGap,
            responsive = false,
            onContainerResized = function(_, newColH)
                local safeH = math.max(10, newColH or 10)
                colData.height = safeH
                colFrame:SetHeight(safeH)
                if not self._isUpdatingColumnLayout then
                    self:updateLayout()
                end
            end,
        })
        colData.layout = colLayout
        table.insert(self.columns, colData)

        -- Set provisional width before populating so fluid/wrapped children can measure
        local availW = (self.GetWidth and self:GetWidth()) or (parent.GetWidth and parent:GetWidth()) or 500
        if availW <= 0 then availW = 500 end
        local provisionalW = availW
        if colOpts.proportion then
            provisionalW = math.max(10, math.floor(availW * colOpts.proportion))
        elseif colOpts.explicitWidth then
            provisionalW = colOpts.explicitWidth
        elseif #self.columns > 0 then
            provisionalW = math.max(10, math.floor(availW / math.max(2, #self.columns)))
        end
        colFrame:SetWidth(provisionalW)
        colLayout.currentWidth = provisionalW

        local builderFn = colOpts.populate or colOpts.build or colOpts.render
        if type(builderFn) == "function" then
            builderFn(colLayout, colFrame, self)
            local h = math.max(10, colLayout.accumulatedHeight or 10)
            colData.height = h
            colFrame:SetHeight(h)
        end

        self:updateLayout()
        return colLayout, colFrame, colData
    end

    --- Arranges columns side-by-side ("normal") or stacked ("compact") and emits
    --- Phase 3 resize notifications to the parent LayoutModel.
    --- @param modeOrWidth string|number|nil Responsive mode or available width.
    --- @param maybeWidth number|nil Available width when mode is first argument.
    function groupFrame:updateLayout(modeOrWidth, maybeWidth)
        if self._isUpdatingColumnLayout then return end
        if not self.columns or #self.columns == 0 then return end

        local mode, availWidth
        if type(modeOrWidth) == "number" then
            availWidth = modeOrWidth
        else
            mode = modeOrWidth
            availWidth = maybeWidth
        end

        local availW = availWidth
        if not availW or availW <= 0 then
            availW = (self.GetWidth and self:GetWidth()) or (parent.GetWidth and parent:GetWidth()) or 500
        end
        if availW <= 0 then availW = 500 end

        local isCompact = (mode == "compact") or (availW < self.threshold)
        self.responsiveMode = isCompact and "compact" or "normal"

        self._isUpdatingColumnLayout = true
        if isCompact then
            local totalH = 0
            for i, col in ipairs(self.columns) do
                local cGap = (i > 1) and (col.opts.gap or self.gap) or 0
                col.frame:ClearAllPoints()
                col.frame:SetWidth(availW)
                col.layout.currentWidth = availW
                if col.layout.notifyResponsive and (not col._lastNotifiedWidth or math.abs(availW - col._lastNotifiedWidth) > 0.5) then
                    col._lastNotifiedWidth = availW
                    col.layout:notifyResponsive("compact", availW, col.height)
                end
                col.frame:SetPoint("RIGHT", self, "RIGHT", 0, 0)
                if i == 1 then
                    col.frame:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 0)
                else
                    col.frame:SetPoint("TOPLEFT", self.columns[i - 1].frame, "BOTTOMLEFT", 0, -cGap)
                end
                local h = math.max(10, col.layout.accumulatedHeight or col.height or 10)
                col.frame:SetHeight(h)
                col.height = h
                totalH = totalH + h + cGap
            end
            self:SetHeight(math.max(10, totalH + (self.bottomPadding or 0)))
        else
            local numCols = #self.columns
            local defaultColW = math.max(10, math.floor((availW - (self.gap * (numCols - 1))) / numCols))
            local maxH = 10
            for i, col in ipairs(self.columns) do
                col.frame:ClearAllPoints()
                local colW = defaultColW
                if col.opts.proportion then
                    colW = math.max(10, math.floor(availW * col.opts.proportion))
                elseif col.opts.explicitWidth then
                    colW = col.opts.explicitWidth
                end
                col.frame:SetWidth(colW)
                col.layout.currentWidth = colW
                if col.layout.notifyResponsive and (not col._lastNotifiedWidth or math.abs(colW - col._lastNotifiedWidth) > 0.5) then
                    col._lastNotifiedWidth = colW
                    col.layout:notifyResponsive("normal", colW, col.height)
                end

                if col.opts.xOffset and i == 1 then
                    col.frame:SetPoint("TOPLEFT", self, "TOPLEFT", col.opts.xOffset, 0)
                elseif i == 1 then
                    col.frame:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 0)
                else
                    local cGap = col.opts.gap or self.gap
                    col.frame:SetPoint("TOPLEFT", self.columns[i - 1].frame, "TOPRIGHT", cGap, 0)
                end

                local h = math.max(10, col.layout.accumulatedHeight or col.height or 10)
                col.frame:SetHeight(h)
                col.height = h
                if h > maxH then
                    maxH = h
                end
            end
            self:SetHeight(math.max(10, maxH + (self.bottomPadding or 0)))
        end
        self._isUpdatingColumnLayout = false

        -- Phase 3 (Pattern A): Bubble updated height to parent LayoutModel
        local finalGroupH = self:GetHeight()
        if self._parentLayout and self._parentLayout.onChildResized and (not self._lastReportedHeight or math.abs(finalGroupH - self._lastReportedHeight) > 0.5) then
            self._lastReportedHeight = finalGroupH
            self._parentLayout:onChildResized(self, finalGroupH)
        end
    end

    if type(options.columns) == "table" then
        for _, colDef in ipairs(options.columns) do
            groupFrame:addColumn(colDef)
        end
    end

    -- Standalone responsive subscription if not managed by a layout
    if not options.layout and options.responsive ~= false and lib.UX and lib.UX.makeResponsive then
        local coord = lib.UX:makeResponsive(parent, { threshold = threshold })
        if coord then
            coord:registerSubscriber(groupFrame, function(elem, mode, w)
                elem:updateLayout(mode, w)
            end)
        end
    end

    -- Auto-anchor into parent layout if options.layout was passed (1.D)
    if options.layout and self.registerCreatedElement then
        self:registerCreatedElement(groupFrame, options)
        options._autoAnchored = true
    end

    return groupFrame
end

Context.CreateColumnGroup = Context.createColumnGroup
