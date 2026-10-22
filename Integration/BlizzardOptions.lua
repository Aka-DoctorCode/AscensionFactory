-------------------------------------------------------------------------------
-- Project: AscensionFactory
-- Author: Aka-DoctorCode
-- File: BlizzardOptions.lua
-------------------------------------------------------------------------------
---@diagnostic disable: undefined-global, undefined-field, inject-field

-------------------------------------------------------------------------------
-- 1. INITIALIZATION & NAMESPACE REGISTRATION
-- Objective: Initialize Integration namespace and link to global AscensionFactory library.
-- Variables:
-- MAJOR (string): Namespace identifier for addon library.
-- lib (table): Global AscensionFactory library object.
-- Integration (table): Namespace table for external game integrations.
-------------------------------------------------------------------------------
local MAJOR = "AscensionFactory"
local lib = LibStub:GetLibrary(MAJOR)
if not lib then return end

local Integration = lib.Integration or {}
lib.Integration = Integration

-------------------------------------------------------------------------------
-- 2. BLIZZARD OPTIONS INTEGRATION
-- Objective: Registers a stub category in WoW's native Interface Options menu
-- that redirects players to the custom high-performance Ascension Factory window.
-- Variables:
-- addonName (string): Global identifier for the addon.
-- displayName (string|nil): User-facing title in the Settings category list.
-- openConfigCallback (function): Invoked when clicking 'OPEN SETTINGS'.
-------------------------------------------------------------------------------

--- Registers a stub panel in the standard Blizzard Interface Options / Settings menu.
--- @param addonName string Unique addon identifier.
--- @param displayName string|nil Human-readable title displayed in the Blizzard options tree.
--- @param openConfigCallback function Callback to open the addon's custom Factory window.
--- @return table blizzardPanel The registered Blizzard frame.
function Integration:registerBlizzardPanel(addonName, displayName, openConfigCallback)
    if not addonName then return nil end

    local panelName = addonName .. "_BlizPanel"
    local blizzardPanel = CreateFrame("Frame", panelName, _G.UIParent)
    blizzardPanel.name = displayName or addonName
    blizzardPanel:Hide()

    local uiContext = lib.Context or lib:createContext()
    local styles = uiContext and uiContext.styles or lib.defaultStyles

    -- Build stub canvas once
    local function buildBlizUI()
        if blizzardPanel.isInitialized then return end
        blizzardPanel.isInitialized = true

        -- Section Title
        local title = blizzardPanel:CreateFontString(nil, "OVERLAY", styles.fonts.header or "GameFontHighlightHuge")
        title:SetPoint("TOPLEFT", 16, -16)
        title:SetText(blizzardPanel.name)
        local primary = styles.colors.primary or { 1.0, 0.38, 0.0, 1.0 }
        title:SetTextColor(unpack(primary))

        -- Explanatory Redirect Description
        local desc = blizzardPanel:CreateFontString(nil, "OVERLAY", styles.fonts.label or "GameFontNormal")
        desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -12)
        desc:SetPoint("RIGHT", blizzardPanel, "RIGHT", -16, 0)
        desc:SetJustifyH("LEFT")
        desc:SetSpacing(4)
        local white = styles.colors.white or { 0.92, 0.97, 1.0, 1.0 }
        desc:SetTextColor(unpack(white))
        desc:SetText("All configuration options have been moved to a specialized high-performance Obsidian Cyberpunk interface for an enhanced user experience.")

        -- Action Button (Open Settings)
        local openBtn
        if uiContext and uiContext.createDialogButton then
            openBtn = uiContext:createDialogButton({
                parent = blizzardPanel,
                variant = "accept",
                text = "OPEN SETTINGS",
                width = 240,
                height = 36,
                point = "CENTER",
                relativeTo = blizzardPanel,
                relativePoint = "CENTER",
                xOffset = 0,
                yOffset = 0,
                onClick = function()
                    local settingsPanel = _G["SettingsPanel"]
                    if settingsPanel and settingsPanel:IsShown() and type(settingsPanel.Close) == "function" then
                        settingsPanel:Close()
                    elseif _G["InterfaceOptionsFrame"] and _G["InterfaceOptionsFrame"]:IsShown() then
                        _G["InterfaceOptionsFrame"]:Hide()
                    end

                    if openConfigCallback then
                        openConfigCallback()
                    end
                end
            })
        else
            openBtn = CreateFrame("Button", nil, blizzardPanel, "UIPanelButtonTemplate")
            openBtn:SetSize(240, 36)
            openBtn:SetPoint("CENTER", blizzardPanel, "CENTER", 0, 0)
            openBtn:SetText("OPEN SETTINGS")
            openBtn:SetScript("OnClick", function()
                local settingsPanel = _G["SettingsPanel"]
                if settingsPanel and settingsPanel:IsShown() and type(settingsPanel.Close) == "function" then
                    settingsPanel:Close()
                end
                if openConfigCallback then openConfigCallback() end
            end)
        end
    end

    blizzardPanel:HookScript("OnShow", buildBlizUI)

    -- Register with WoW modern settings API (Dragonflight / The War Within) or fallback to legacy
    if _G.Settings and type(_G.Settings.RegisterCanvasLayoutCategory) == "function" then
        local category = _G.Settings.RegisterCanvasLayoutCategory(blizzardPanel, blizzardPanel.name)
        _G.Settings.RegisterAddOnCategory(category)
        blizzardPanel.settingsCategory = category
    elseif _G.InterfaceOptions_AddCategory then
        _G.InterfaceOptions_AddCategory(blizzardPanel)
    end

    return blizzardPanel
end

Integration.RegisterBlizzardPanel = Integration.registerBlizzardPanel

-------------------------------------------------------------------------------
-- 3. EXTENSION & EXPANSION NOTES
-- Objective: Guidelines for sub-category registration and direct slash command integration.
--
-- How to expand:
-- 1. Sub-Categories:
--    Use `Settings.RegisterCanvasLayoutSubcategory(category, subPanel, subPanel.name)`
--    to nest multiple module redirect panels under a master addon category.
-------------------------------------------------------------------------------
