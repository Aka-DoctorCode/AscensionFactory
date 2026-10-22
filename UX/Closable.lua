-------------------------------------------------------------------------------
-- Project: AscensionFactory
-- Author: Aka-DoctorCode
-- File: Closable.lua
-------------------------------------------------------------------------------
---@diagnostic disable: undefined-global, undefined-field, inject-field

-------------------------------------------------------------------------------
-- 1. INITIALIZATION
-- Objective: Initialize UX namespace and link to global AscensionFactory library.
-- Variables:
-- MAJOR: Namespace identifier for addon library.
-- lib: Global AscensionFactory library object.
-- UX: Namespace table for UX helper functions.
-------------------------------------------------------------------------------
local MAJOR = "AscensionFactory"
local lib = LibStub:GetLibrary(MAJOR)
if not lib then return end

local UX = lib.UX or {}
lib.UX = UX

-------------------------------------------------------------------------------
-- 2. ESCAPE KEY LOGIC
-- Objective: Configure frame to hide when user press Escape key.
-- Variables:
-- frame: Frame UI object configured as closable.
-------------------------------------------------------------------------------
--- Configures a frame to be hidable when user presses Escape key, with optional pool release on hide.
function UX:makeClosableWithEscape(frame, config)
    if not frame then return end
    config = config or {}
    
    if not frame.isClosableHooked then
        frame.isClosableHooked = true
        
        local name = frame:GetName()
        if name and UISpecialFrames then
            _G[name] = frame
            tinsert(UISpecialFrames, name)
        else
            frame:HookScript("OnShow", function(self)
                if self.SetKeyboardEnabled then
                    self:SetKeyboardEnabled(true)
                elseif self.EnableKeyboard then
                    self:EnableKeyboard(true)
                end
                if self.SetPropagateKeyboardInput then
                    self:SetPropagateKeyboardInput(true)
                end
            end)

            if frame.SetKeyboardEnabled then
                frame:SetKeyboardEnabled(true)
            elseif frame.EnableKeyboard then
                frame:EnableKeyboard(true)
            end
            if frame.SetPropagateKeyboardInput then
                frame:SetPropagateKeyboardInput(true)
            end
            
            frame:SetScript("OnKeyDown", function(self, key)
                if key == "ESCAPE" then
                    if self.SetPropagateKeyboardInput then self:SetPropagateKeyboardInput(false) end
                    self:Hide()
                else
                    if self.SetPropagateKeyboardInput then self:SetPropagateKeyboardInput(true) end
                end
            end)
        end

        frame:HookScript("OnHide", function(self)
            local shouldRelease = config.autoReleaseOnHide or config.releaseOnHide or self.autoReleaseOnHide or self.releaseOnHide
            if not shouldRelease then return end
            if self.isReleasing then return end
            self.isReleasing = true
            
            if self.globalName then
                _G[self.globalName] = nil
                self.globalName = nil
            end
            
            if self.uiContext and self.uiContext.releaseElementAndChildren then
                self.uiContext:releaseElementAndChildren(self)
            end
            
            self.isReleasing = nil
        end)
    end
end

-------------------------------------------------------------------------------
-- 3. EXTENSION & EXPANSION NOTES
-- Objective: Guidelines for custom escape behaviors, close confirmation dialogs, and lifecycle management.
--
-- How to expand:
-- 1. Close Confirmation Dialogs:
--    Intercept the escape press before calling `self:Hide()` by adding a `config.onCloseRequest`
--    callback that prompts the user with a dialog button confirmation before closing.
-- 2. Lifecycle Cleanup:
--    Set `config.releaseOnHide = true` or `frame.releaseOnHide = true` on ephemeral popup frames
--    to automatically return the frame and all child regions to the memory pool upon closing.
-- 3. Keyboard Input Propagation:
--    Toggle `frame:SetPropagateKeyboardInput(true)` to pass non-escape keys through to the game engine
--    allowing character movement while the UI window is open.
-------------------------------------------------------------------------------
