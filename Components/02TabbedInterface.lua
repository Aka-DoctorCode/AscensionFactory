-------------------------------------------------------------------------------
-- Project: AscensionFactory
-- Author: Aka-DoctorCode
-- File: TabbedInterface.lua
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
-- 2. TABBED INTERFACE FACTORY
-- Objective: Creates a complex UI structure with a vertical sidebar for navigation and multiple content panels.
-- Variables:
-- options (table): Configuration table (parent, startY, initialIndex, tabs array).
-- parent (table): The parent frame anchoring the tabbed interface.
-- startY (number): Initial Y offset for positioning the sidebar.
-- initialIndex (number): The tab index to select by default.
-- tabs (table): Array tracking created tab button frames.
-- panels (table): Array tracking created content panel frames.
-- activeTab (number): State variable holding the currently selected tab index.
-------------------------------------------------------------------------------
function Context:createTabbedInterface(options)
    assert(type(options) == "table", "options table required for createTabbedInterface")
    assert(options.parent, "options.parent is required for createTabbedInterface")
    assert(options.name, "options.name is required for createTabbedInterface")
    assert(type(options.startY) == "number", "options.startY is required and must be a number")
    assert(type(options.tabs) == "table", "options.tabs is required and must be a table")
    assert(type(options.sidebarWidth) == "number", "options.sidebarWidth is required and must be a number")

    local styles = self.styles
    local parent = options.parent
    local startY = options.startY
    local initialIndex = options.initialIndex
    local tabs = {}
    local panels = {}
    local activeTab = initialIndex

    local sidebarWidth = options.sidebarWidth
    local autoScroll = (options.autoScroll ~= false)
    local contentPaddingLeft = options.contentPaddingLeft or options.contentPadding or 4

    -------------------------------------------------------------------------------
    -- 2.1. TAB SELECTION LOGIC
    -- Objective: Switches the active view to the specified tab index.
    -- Updates the visual states of the tab buttons (active color, accent) and toggles panel visibility.
    -------------------------------------------------------------------------------
    local function selectTab(index)
        activeTab = index
        -- Loop through all tabs to update their visual states (color and accent)
        for tabIndex, tab in ipairs(tabs) do
            if tabIndex == index then
                if styles.colors.primaryActive then tab.background:SetColorTexture(unpack(styles.colors.primaryActive)) end
                tab.accent:Show()
            else
                tab.background:SetColorTexture(0, 0, 0, 0) -- #00000000
                if tab.accent then tab.accent:Hide() end
            end
        end
        -- Loop through all panels to show only the selected one and hide the rest
        for tabIndex, panel in ipairs(panels) do
            if tabIndex == index then
                panel:Show()
                if C_Timer and C_Timer.After then
                    C_Timer.After(0.01, function()
                        if panel.updateScrollRange then panel:updateScrollRange() end
                        if panel.updateLayout then panel.updateLayout(panel) end
                    end)
                else
                    if panel.updateScrollRange then panel:updateScrollRange() end
                    if panel.updateLayout then panel.updateLayout(panel) end
                end
            else
                panel:Hide()
            end
        end

        if options.onTabSelected then
            options.onTabSelected(index, tabs[index], panels[index])
        end
    end

    -------------------------------------------------------------------------------
    -- 2.2 SIDEBAR CONTAINER
    -- Objective: Creates the vertical sidebar container frame for tab navigation.
    -------------------------------------------------------------------------------
    local sidebar = self:acquireElement("Frame", parent, {
        name = options.name and (options.name .. "Sidebar") or nil
    })
    _G[options.name] = sidebar
    sidebar:SetWidth(sidebarWidth)
    sidebar:SetClipsChildren(true)
    
    sidebar:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, startY)
    sidebar:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 10, 8)    
    
    -- Create outer border texture for the sidebar
    if not sidebar.border then
        local border = sidebar:CreateTexture(nil, "BACKGROUND", nil, -2)
        border:SetAllPoints(sidebar)
        sidebar.border = border
    end
    sidebar.border:SetColorTexture(unpack(styles.colors.border))

    -- Create inner background texture for the sidebar
    if not sidebar.background then
        local background = sidebar:CreateTexture(nil, "BACKGROUND", nil, -1)
        background:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 1, -1)
        background:SetPoint("BOTTOMRIGHT", sidebar, "BOTTOMRIGHT", -1, 1)
        sidebar.background = background
    end
    sidebar.background:SetColorTexture(unpack(styles.colors.surfaceLight))

    -------------------------------------------------------------------------------
    -- 2.3 SIDEBAR SCROLL & TAB BUTTON FACTORY
    -------------------------------------------------------------------------------
    local sidebarContent = sidebar
    if lib.UX and lib.UX.makeScrollable then
        local _, sbScrollChild = lib.UX:makeScrollable(sidebar, {
            uiContext = self,
            step = options.scrollStep or 30,
            thumbShape = "capsule",
            scrollBarWidth = 8,
            scrollBarGap = 2,
            bottomPadding = 8,
            autoHideScrollBar = true,
            contentPaddingLeft = 0
        })
        if sbScrollChild then
            sidebarContent = sbScrollChild
        end
    end

    local layout = self:createLayoutModel(sidebarContent)

    local function sidebarButton(btnOptions)
        local button = self:acquireElement("Button", sidebarContent, {})
        button:SetHeight(22)
        button:SetWidth(sidebarWidth)

        layout:anchorElement(button)

        if not button.background then
            local background = button:CreateTexture(nil, "BACKGROUND", nil, -1)
            background:SetAllPoints(button)
            button.background = background
        end
        button.background:SetColorTexture(0, 0, 0, 0)

        -- Standard full text label
        local tabLabel = self:createLabel({
            name = (options.name or "TabbedInterface") .. "TabLabel" .. btnOptions.index,
            parent = button,
            text = btnOptions.text
        })
        tabLabel:ClearAllPoints()
        tabLabel:SetPoint("LEFT", button, "LEFT", 10, 0)
        tabLabel:SetPoint("RIGHT", button, "RIGHT", -6, 0)
        tabLabel:SetWordWrap(true)
        tabLabel:SetHeight(0)
        button.tabLabel = tabLabel
        button.tabName = btnOptions.text

        local function syncSidebarButtonHeight(btn)
            if not btn.tabLabel then return end
            local textH = (btn.tabLabel.GetStringHeight and btn.tabLabel:GetStringHeight()) or 0
            local targetH = math.max(22, math.ceil(textH + 8))
            local curH = (btn.GetHeight and btn:GetHeight()) or 0
            if math.abs(curH - targetH) > 0.5 then
                btn:SetHeight(targetH)
                if layout and layout.onChildResized then
                    layout:onChildResized(btn, targetH)
                end
            end
        end

        syncSidebarButtonHeight(button)
        if C_Timer and C_Timer.After then
            C_Timer.After(0, function()
                syncSidebarButtonHeight(button)
            end)
        end
        if button.HookScript and not button._hasSidebarSizeHook then
            button._hasSidebarSizeHook = true
            button:HookScript("OnSizeChanged", function(self)
                syncSidebarButtonHeight(self)
            end)
        end

        -- Active 8px accent bar on left edge
        local accent = self:acquireElement("Texture", button, { drawLayer = "OVERLAY" })
        accent:SetWidth(8)
        accent:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
        accent:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 0, 0)
        accent:SetColorTexture(unpack(styles.colors.primary))
        accent:Hide()
        button.accent = accent

        button:SetScript("OnClick", btnOptions.onClick)

        if lib.UX and lib.UX.makeHoverable then
            lib.UX:makeHoverable(button, {
                onStateChange = function(self, state)
                    if activeTab ~= btnOptions.index then
                        if state == "hover" then
                            button.background:SetColorTexture(unpack(styles.colors.primaryHover))
                        else
                            button.background:SetColorTexture(0, 0, 0, 0)
                        end
                    end
                end
            })
        end

        return button
    end

    -------------------------------------------------------------------------------
    -- 2.5 PANELS & TABS GENERATION (WITH AUTO-SCROLL)
    -------------------------------------------------------------------------------
    for tabIndex, tabName in ipairs(options.tabs) do
        local panel = self:acquireElement("Frame", parent, {})
        panel:SetPoint("TOPLEFT", sidebar, "TOPRIGHT", 10, 0)
        panel:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -10, 8)
        
        if not panel.background then
            local background = panel:CreateTexture(nil, "BACKGROUND", nil, -1)
            background:SetAllPoints(panel)
            panel.background = background
        end
        panel.background:SetColorTexture(unpack(styles.colors.panelBackground))
        panel:Hide()

        -- Auto-Scroll integration per panel
        if autoScroll and lib.UX and lib.UX.makeScrollable then
            local scrollFrame, scrollChild, scrollbar = lib.UX:makeScrollable(panel, {
                uiContext = self,
                step = options.scrollStep or 30,
                thumbShape = "capsule",
                bottomPadding = 20,
                contentPaddingLeft = contentPaddingLeft
            })
            panel.scrollFrame = scrollFrame
            panel.scrollChild = scrollChild
            panel.content = scrollChild
            panel.contentChild = scrollChild
            panel.scrollbar = scrollbar
            panel.isScrollablePanel = true
            panel.getScrollChild = function(self) return self.scrollChild or self end
            panel.getContent = function(self) return self.scrollChild or self end
            panel.GetContent = panel.getContent
        end

        panels[tabIndex] = panel

        local tabButton = sidebarButton({
            text = tabName,
            index = tabIndex,
            onClick = function()
                selectTab(tabIndex)
            end
        })
        tabs[tabIndex] = tabButton
    end

    -- Update sidebar scroll range after all tab buttons are created
    if sidebar.updateScrollRange then
        sidebar:updateScrollRange()
    end

    -- Initial tab activation
    if initialIndex then
        selectTab(initialIndex)
    end

    return {
        sidebar = sidebar,
        tabs = tabs,
        panels = panels,
        selectTab = selectTab,
        getActiveTab = function() return activeTab end,
        getContent = function(tabIndex)
            local p = panels[tabIndex or activeTab]
            return p and (p.scrollChild or p)
        end
    }
end

-------------------------------------------------------------------------------
-- 3. EXTENSION & EXPANSION NOTES
-- Objective: Guidelines for top horizontal tabs, badge notification counts, and lazy-loading panels.
--
-- How to expand:
-- 1. Horizontal Tab Bar Orientation:
--    Add `options.orientation = "TOP"` support by anchoring tab buttons horizontally along the top edge
--    of the container using `SetPoint("LEFT", prevButton, "RIGHT", gap, 0)`.
-- 2. Notification Badges:
--    Attach small numeric bubble indicators (e.g. unread count or alert indicator) onto individual tab buttons.
-- 3. Lazy Panel Initializer:
--    Support passing functions in `options.tabs = { { name = "General", render = function(panel) ... end } }`
--    to only construct child widgets when a tab is clicked for the first time.
-------------------------------------------------------------------------------
