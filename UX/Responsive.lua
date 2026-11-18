-------------------------------------------------------------------------------
-- Project: AscensionFactory
-- Author: Aka-DoctorCode
-- File: Responsive.lua
-------------------------------------------------------------------------------
---@diagnostic disable: undefined-global, undefined-field, inject-field

-------------------------------------------------------------------------------
-- 1. INITIALIZATION & NAMESPACE REGISTRATION
-- Objective: Initialize UX namespace and register the independent Responsive coordinator.
-------------------------------------------------------------------------------
local MAJOR = "AscensionFactory"
local lib = LibStub:GetLibrary(MAJOR)
if not lib then return end

local UX = lib.UX or {}
lib.UX = UX
local Context = lib.Context

-------------------------------------------------------------------------------
-- 2. RESPONSIVE COORDINATOR FACTORY
-- Objective: Observe container size changes with debouncing, evaluate breakpoints
-- ("normal" vs "compact"), and notify subscribed elements independently of LayoutModel.
-------------------------------------------------------------------------------

--- Attaches a debounced responsive breakpoint coordinator to a container frame.
--- @param containerFrame table The WoW Frame to observe for size changes.
--- @param options table|nil Configuration table (threshold, debounce, onModeChange, alwaysNotify).
--- @return table|nil coordinator The responsive coordinator object.
function UX:makeResponsive(containerFrame, options)
    if not containerFrame then return nil end
    options = options or {}

    local threshold = options.threshold or 480
    local debounce = options.debounce or 0.05

    local coordinator = containerFrame.responsiveCoordinator
    if coordinator and not coordinator.isDestroyed then
        if options.threshold then coordinator.threshold = options.threshold end
        if options.debounce then coordinator.debounce = options.debounce end
        if options.onModeChange then coordinator.onModeChange = options.onModeChange end
        if options.alwaysNotify ~= nil then coordinator.alwaysNotify = options.alwaysNotify end
        coordinator:evaluate(true)
        return coordinator
    end

    coordinator = {
        frame = containerFrame,
        threshold = threshold,
        debounce = debounce,
        mode = "normal",
        subscribers = {},
        onModeChange = options.onModeChange,
        alwaysNotify = options.alwaysNotify,
        isDestroyed = false,
        lastWidth = 0,
        lastHeight = 0,
    }
    containerFrame.responsiveCoordinator = coordinator

    --- Registers a subscriber callback or element/callback pair.
    --- @param elementOrCallback table|function Element table or callback(mode, width, height).
    --- @param callback function|nil Callback(element, mode, width, height) when element is passed.
    function coordinator:registerSubscriber(elementOrCallback, callback)
        if self.isDestroyed then return end
        local elem, fn
        if type(elementOrCallback) == "function" then
            fn = elementOrCallback
        else
            elem = elementOrCallback
            fn = callback
        end
        if type(fn) ~= "function" then return end

        -- Avoid duplicate registrations for the same element/callback pair
        for _, sub in ipairs(self.subscribers) do
            if sub.element == elem and sub.callback == fn then
                local w = (self.frame.GetWidth and self.frame:GetWidth()) or 0
                local h = (self.frame.GetHeight and self.frame:GetHeight()) or 0
                if elem then
                    fn(elem, self.mode, w, h)
                else
                    fn(self.mode, w, h)
                end
                return
            end
        end

        table.insert(self.subscribers, {
            element = elem,
            callback = fn,
        })

        local w = (self.frame.GetWidth and self.frame:GetWidth()) or 0
        local h = (self.frame.GetHeight and self.frame:GetHeight()) or 0
        if elem then
            fn(elem, self.mode, w, h)
        else
            fn(self.mode, w, h)
        end
    end

    --- Unregisters a subscriber by element or callback reference.
    --- @param target table|function The element or callback function to remove.
    function coordinator:unregisterSubscriber(target)
        if not target or not self.subscribers then return end
        for i = #self.subscribers, 1, -1 do
            local sub = self.subscribers[i]
            if sub.element == target or sub.callback == target then
                table.remove(self.subscribers, i)
            end
        end
    end

    --- Returns the active responsive mode ("normal" or "compact").
    --- @return string mode
    function coordinator:getMode()
        return self.mode
    end

    --- Broadcasts a mode/size update to all registered subscribers.
    --- @param newMode string "normal" or "compact"
    --- @param width number Container width in pixels
    --- @param height number Container height in pixels
    function coordinator:notify(newMode, width, height)
        if self.isDestroyed then return end
        self.mode = newMode
        for _, sub in ipairs(self.subscribers) do
            if sub.callback then
                if sub.element then
                    sub.callback(sub.element, newMode, width, height)
                else
                    sub.callback(newMode, width, height)
                end
            end
        end
        if self.onModeChange then
            self.onModeChange(self, newMode, width, height)
        end
    end

    --- Evaluates the current container dimensions against the breakpoint threshold.
    --- @param isInitial boolean|nil Force evaluation on initial attachment.
    function coordinator:evaluate(isInitial)
        if self.isDestroyed or not self.frame then return end
        local width = (self.frame.GetWidth and self.frame:GetWidth()) or 0
        local height = (self.frame.GetHeight and self.frame:GetHeight()) or 0
        local newMode = (width > 0 and width < self.threshold) and "compact" or "normal"
        local sizeChanged = math.abs(width - self.lastWidth) > 0.5 or math.abs(height - self.lastHeight) > 0.5

        if isInitial or newMode ~= self.mode or sizeChanged or self.alwaysNotify then
            self.lastWidth = width
            self.lastHeight = height
            self:notify(newMode, width, height)
        end
    end

    --- Tears down the coordinator and clears all subscribers.
    function coordinator:destroy()
        self.isDestroyed = true
        self.subscribers = {}
        if self.frame and self.frame.responsiveCoordinator == self then
            self.frame.responsiveCoordinator = nil
        end
    end

    if containerFrame.HookScript and not containerFrame._hasResponsiveHook then
        containerFrame._hasResponsiveHook = true
        local isDebouncing = false
        containerFrame:HookScript("OnSizeChanged", function(frame)
            local active = frame.responsiveCoordinator
            if not active or active.isDestroyed then return end
            if isDebouncing then return end

            if C_Timer and C_Timer.After and active.debounce and active.debounce > 0 then
                isDebouncing = true
                C_Timer.After(active.debounce, function()
                    isDebouncing = false
                    if frame.responsiveCoordinator and not frame.responsiveCoordinator.isDestroyed then
                        frame.responsiveCoordinator:evaluate(false)
                    end
                end)
            else
                active:evaluate(false)
            end
        end)
    end

    coordinator:evaluate(true)
    return coordinator
end

UX.MakeResponsive = UX.makeResponsive

if Context then
    --- Attaches a responsive breakpoint coordinator to a frame via Context.
    --- @param frame table Container frame to observe.
    --- @param options table|nil Responsive options (threshold, debounce, onModeChange).
    --- @return table|nil coordinator
    function Context:makeResponsive(frame, options)
        return UX:makeResponsive(frame, options)
    end
end
