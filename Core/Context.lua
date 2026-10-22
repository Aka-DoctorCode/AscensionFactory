-------------------------------------------------------------------------------
-- Project: AscensionFactory
-- Author: Aka-DoctorCode
-- File: Context.lua
-------------------------------------------------------------------------------
---@diagnostic disable: undefined-global, undefined-field, inject-field

-------------------------------------------------------------------------------
-- 1. INITIALIZATION & NAMESPACE RESOLUTION
-- Objective: Retrieve library instance and establish global default styling tokens.
-- Variables:
-- MAJOR (string): Namespace identifier for AscensionFactory.
-- lib (table): Shared library instance.
-------------------------------------------------------------------------------
local MAJOR = "AscensionFactory"
local lib = LibStub:GetLibrary(MAJOR)
if not lib then return end

-------------------------------------------------------------------------------
-- 2. DEFAULT STYLE TOKENS (Obsidian Cyberpunk Palette)
-- Objective: Central registry for default rendering tokens (RGBA colors, font objects, textures).
-- Variables:
-- defaultStyles (table): Master design system configuration.
-------------------------------------------------------------------------------
lib.defaultStyles = lib.defaultStyles or lib.DefaultStyles or {
    colors = {
        -- Deep Obsidian Metallic Backgrounds
        background      = { 0.008, 0.012, 0.020, 0.96 }, -- #020305F5
        panelBackground = { 0.016, 0.024, 0.039, 0.60 }, -- #04060A99
        surfaceDark     = { 0.012, 0.020, 0.031, 0.90 }, -- #030508E6
        surfaceLight    = { 0.027, 0.039, 0.059, 0.90 }, -- #070A0FE6
        surfaceHover    = { 0.055, 0.075, 0.110, 0.95 }, -- #0E131CF2
        border          = { 0.078, 0.102, 0.141, 1.00 }, -- #141A24FF
        steelHighlight  = { 0.122, 0.153, 0.208, 1.00 }, -- #1F2735FF

        -- Metallic Hardware & Grip Accents
        steelBase       = { 0.180, 0.220, 0.275, 1.00 }, -- #2E3846FF (Muted steel grip in rest)
        steelHover      = { 0.353, 0.420, 0.510, 1.00 }, -- #5A6B82FF (Luminous titanium highlight)
        steelActive     = { 0.541, 0.608, 0.702, 1.00 }, -- #8A9BB3FF (Polished chrome active)

        -- Neon Orange Primary Accents (Laser Glow)
        primary         = { 1.000, 0.380, 0.000, 1.00 }, -- #FF6100FF
        primaryHover    = { 1.000, 0.540, 0.050, 1.00 }, -- #FF8A0DFF
        primaryActive   = { 0.700, 0.220, 0.000, 1.00 }, -- #B33800FF

        -- Hyper-Saturated Cyberpunk Neon Tokens (Pure Laser Glow)
        -- neonCyan        = {0.000, 0.968, 1.000, 1.00}, -- #00F7FFFF
        -- neonGold        = {1.000, 0.918, 0.000, 1.00}, -- #FFEA00FF
        neonRed         = { 1.000, 0.000, 0.150, 1.00 }, -- #FF0026FF (Pure Laser Red)
        neonGreen       = { 0.000, 1.000, 0.400, 1.00 }, -- #00FF66FF
        -- neonPurple      = {0.690, 0.000, 1.000, 1.00}, -- #B000FFFF

        -- Standard / Semantic Colors
        greenHover      = { 0.200, 1.000, 0.550, 1.00 }, -- #33FF8CFF (Electric Mint Green)
        greenActive     = { 0.000, 0.650, 0.250, 1.00 }, -- #00A640FF (Deep Emerald Green)
        redHover        = { 1.000, 0.180, 0.180, 1.00 }, -- #FF2E2EFF (Electric Scarlet Red)
        redActive       = { 0.600, 0.000, 0.100, 1.00 }, -- #99001AFF (Deep Crimson)
        black           = { 0.020, 0.027, 0.039, 1.00 }, -- #05070AFF
        white           = { 0.922, 0.973, 1.000, 1.00 }, -- #EBF8FFFF
    },
    fonts = {
        header = "GameFontHighlightHuge",
        label  = "GameFontHighlightLarge",
        text   = "GameFontNormal",
    },
    textures = {
        background = "Interface\\ChatFrame\\ChatFrameBackground",
        flat       = "Interface\\Buttons\\WHITE8X8",
        edge       = "Interface\\Tooltips\\UI-Tooltip-Border",
        arrow      = "Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up",
        spark      = "Interface\\CastingBar\\UI-CastingBar-Spark",
    }
}
lib.DefaultStyles = lib.defaultStyles

-------------------------------------------------------------------------------
-- 3. EXTENSION & EXPANSION NOTES
-- Objective: Guidelines for custom theming, palette overrides, and LibSharedMedia integration.
--
-- How to expand:
-- 1. Theme Presets:
--    Add preset palette tables (e.g. `lib.cyanNeonTheme`, `lib.emeraldTheme`) containing
--    matching keys for `colors`, `fonts`, and `textures`.
-- 2. Dynamic Runtime Theming:
--    Modify `uiContext.styles.colors.primary` at runtime and call `:updateAppearance()`
--    on active widgets to dynamically re-skin UI without reload.
-- 3. LibSharedMedia (LSM) Integration:
--    Map `fonts` and `textures` keys to `LibStub("LibSharedMedia-3.0"):Fetch("font", name)`
--    to support user-selected fonts and bar textures.
-------------------------------------------------------------------------------
