-------------------------------------------------------------------------------
-- Project: AscensionFactory
-- Author: Aka-DoctorCode
-- File: ClickOutside.lua
-------------------------------------------------------------------------------
---@diagnostic disable: undefined-global, undefined-field, inject-field

-------------------------------------------------------------------------------
-- 1. INITIALIZATION
-- Objective: Initialize UX namespace and link to global AscensionFactory library.
-- Variables:
-- MAJOR (string): Namespace identifier for addon library.
-- lib (table): Global AscensionFactory library object.
-- UX (table): Namespace table for UX helper functions.
-------------------------------------------------------------------------------
local MAJOR = "AscensionFactory"
local lib = LibStub:GetLibrary(MAJOR)
if not lib then return end

local UX = lib.UX or {}
lib.UX = UX

-------------------------------------------------------------------------------
-- 2. CLICK OUTSIDE LOGIC
-- Objective: Automatically dismiss popups, dropdowns, and context menus when clicking outside.
-- Variables:
-- frame (table): Frame UI object monitored for outside clicks.
-- callback (function): Invoked when a click outside the frame occurs.
-------------------------------------------------------------------------------

--- Helper to retrieve or create the persistent global click outside blocker button.
local function getGlobalBlocker()
    local blockerName = "AscensionFactoryClickOutsideBlocker"
    local blocker = _G[blockerName]
    if not blocker then
        blocker = CreateFrame("Button", blockerName, _G.UIParent)
        blocker:SetAllPoints(_G.UIParent)
        blocker:SetFrameStrata("FULLSCREEN_DIALOG")
        blocker:SetFrameLevel(100)
        blocker:EnableMouse(true)
        blocker:RegisterForClicks("AnyUp", "AnyDown")
        blocker:Hide()

        blocker.activeTargets = {}

        blocker:SetScript("OnClick", function(self)
            self:Hide()
            local topTarget = table.remove(self.activeTargets)
            if topTarget and topTarget.callback then
                topTarget.callback()
            end
        end)
    end
    return blocker
end

--- Registers a frame to trigger a callback when the user clicks outside its bounds.
--- Uses a transparent modal blocker button positioned behind the target frame.
--- @param frame table The frame to watch for outside clicks.
--- @param callback function The dismissal callback function.
function UX:registerClickOutside(frame, callback)
    if not frame then return end

    local blocker = getGlobalBlocker()

    if not frame.isClickOutsideHooked then
        frame.isClickOutsideHooked = true

        frame:HookScript("OnShow", function(self)
            local frameStrata = self:GetFrameStrata()
            local frameLevel = self:GetFrameLevel()

            blocker:SetFrameStrata(frameStrata)
            blocker:SetFrameLevel(math.max(0, frameLevel - 1))

            -- Track this frame as the active target
            table.insert(blocker.activeTargets, {
                frame = self,
                callback = callback
            })

            blocker:Show()
        end)

        frame:HookScript("OnHide", function(self)
            -- Remove this frame from the active target stack
            for i = #blocker.activeTargets, 1, -1 do
                if blocker.activeTargets[i].frame == self then
                    table.remove(blocker.activeTargets, i)
                    break
                end
            end

            -- If no more monitored frames are shown, hide the blocker
            if #blocker.activeTargets == 0 then
                blocker:Hide()
            else
                -- Sync blocker with the next active target below
                local nextTarget = blocker.activeTargets[#blocker.activeTargets]
                if nextTarget and nextTarget.frame and nextTarget.frame:IsShown() then
                    blocker:SetFrameStrata(nextTarget.frame:GetFrameStrata())
                    blocker:SetFrameLevel(math.max(0, nextTarget.frame:GetFrameLevel() - 1))
                else
                    blocker:Hide()
                end
            end
        end)
    end
end

UX.RegisterClickOutside = UX.registerClickOutside

-------------------------------------------------------------------------------
-- 3. EXTENSION & EXPANSION NOTES
-- Objective: Guidelines for hierarchical dropdowns, excluded sub-frames, and sound effects.
--
-- How to expand:
-- 1. Excluded Sub-Frames / Whitelist:
--    Attach an `excludedFrames` list to avoid closing when clicking the trigger button itself.
-- 2. Multi-tier Menus:
--    The LIFO stack (`activeTargets`) handles closing nested child sub-menus first before closing parent menus.
-------------------------------------------------------------------------------
