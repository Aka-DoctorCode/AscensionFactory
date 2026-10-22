-------------------------------------------------------------------------------
-- Project: AscensionFactory
-- Author: Aka-DoctorCode
-- File: 14Toast.lua
-------------------------------------------------------------------------------
---@diagnostic disable: undefined-global, undefined-field, inject-field

-------------------------------------------------------------------------------
-- 1. INITIALIZATION & NAMESPACE REGISTRATION
-- Objective: Register the Toast component and ToastManager in AscensionFactory.
-------------------------------------------------------------------------------
local MAJOR = "AscensionFactory"
local lib = LibStub:GetLibrary(MAJOR)
if not lib then return end

local Context = lib.Context
if not Context then return end

-------------------------------------------------------------------------------
-- 2. HELPER FUNCTIONS & VARIANT THEMES
-------------------------------------------------------------------------------

--- Resolves semantic border color based on toast type or explicit options.
local function resolveBorderColor(styles, toastType, explicitColor)
    if explicitColor then
        return explicitColor
    end
    if toastType == "success" then
        return styles.colors.neonGreen
    elseif toastType == "error" then
        return styles.colors.neonRed
    elseif toastType == "warning" then
        return styles.colors.yellow or { 1, 0.8, 0, 1 }
    elseif toastType == "info" then
        return styles.colors.primary
    end
    return styles.colors.border
end

--- Resolves semantic icon vector or texture configuration.
local function createStatusIcon(self, parent, toastType, customIcon, size, color)
    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(size, size)

    if customIcon then
        local texture = container:CreateTexture(nil, "ARTWORK")
        texture:SetAllPoints()
        if type(customIcon) == "string" and customIcon:find("\\") then
            texture:SetTexture(customIcon)
        elseif type(customIcon) == "string" and C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(customIcon) then
            texture:SetAtlas(customIcon)
        else
            texture:SetTexture(customIcon)
        end
        return container
    end

    if toastType == "success" then
        -- Vector Checkmark
        local legShort = container:CreateTexture(nil, "ARTWORK")
        legShort:SetSize(3, size * 0.35)
        legShort:SetPoint("BOTTOMLEFT", container, "BOTTOMLEFT", size * 0.15, size * 0.3)
        legShort:SetColorTexture(unpack(color))
        legShort:SetRotation(math.rad(-45))

        local legLong = container:CreateTexture(nil, "ARTWORK")
        legLong:SetSize(3, size * 0.7)
        legLong:SetPoint("BOTTOMLEFT", container, "BOTTOMLEFT", size * 0.35, size * 0.25)
        legLong:SetColorTexture(unpack(color))
        legLong:SetRotation(math.rad(45))
    elseif toastType == "error" then
        -- Vector X
        local line1 = container:CreateTexture(nil, "ARTWORK")
        line1:SetSize(size * 0.6, 3)
        line1:SetPoint("CENTER")
        line1:SetColorTexture(unpack(color))
        line1:SetRotation(math.rad(45))

        local line2 = container:CreateTexture(nil, "ARTWORK")
        line2:SetSize(3, size * 0.6)
        line2:SetPoint("CENTER")
        line2:SetColorTexture(unpack(color))
        line2:SetRotation(math.rad(45))
    elseif toastType == "warning" then
        -- Exclamation mark (!)
        local dot = container:CreateTexture(nil, "ARTWORK")
        dot:SetSize(3, 3)
        dot:SetPoint("BOTTOM", container, "BOTTOM", 0, size * 0.2)
        dot:SetColorTexture(unpack(color))

        local bar = container:CreateTexture(nil, "ARTWORK")
        bar:SetSize(3, size * 0.45)
        bar:SetPoint("TOP", container, "TOP", 0, -size * 0.15)
        bar:SetColorTexture(unpack(color))
    elseif toastType == "info" then
        -- Info symbol (i)
        local dot = container:CreateTexture(nil, "ARTWORK")
        dot:SetSize(3, 3)
        dot:SetPoint("TOP", container, "TOP", 0, -size * 0.2)
        dot:SetColorTexture(unpack(color))

        local bar = container:CreateTexture(nil, "ARTWORK")
        bar:SetSize(3, size * 0.4)
        bar:SetPoint("BOTTOM", container, "BOTTOM", 0, size * 0.2)
        bar:SetColorTexture(unpack(color))
    end

    return container
end

-------------------------------------------------------------------------------
-- 3. TOAST COMPONENT FACTORY
-- Objective: Builds an isolated Obsidian Cyberpunk notification toast widget.
-------------------------------------------------------------------------------

--- Creates an Obsidian Cyberpunk notification toast frame.
--- @param options table|nil Configuration table for title, message, layout, and styling.
--- @return table toast The configured toast frame.
function Context:createToast(options)
    options = options or {}
    local styles = self.styles
    local width = options.width or 280
    local minHeight = options.minHeight or 54
    local padding = options.padding or 12
    local duration = options.duration or 4
    local toastType = options.type
    local borderColor = resolveBorderColor(styles, toastType, options.borderColor)

    -- 3.1 BASE FRAME CONTAINER (Obsidian Cyberpunk styling)
    local toast = self:createFrame({
        parent = options.parent or _G.UIParent,
        width = width,
        height = minHeight,
        strata = options.strata or "TOOLTIP",
        frameLevel = options.frameLevel or 800,
        clamped = true,
        showCloseButton = false,
        movable = false,
        closableWithEscape = false,
        borderColor = borderColor,
        backgroundColor = options.backgroundColor or styles.colors.background,
        borderInset = 1
    })

    toast.duration = duration
    toast.elapsed = 0
    toast.isPaused = false
    toast.isDismissing = false
    toast.onDismiss = options.onDismiss

    -- 3.2 CLOSE BUTTON
    local closeBtn = self:createIconButton({
        parent = toast,
        size = 18,
        iconType = "close",
        point = "TOPRIGHT",
        relativeTo = toast,
        relativePoint = "TOPRIGHT",
        xOffset = -6,
        yOffset = -6,
        onClick = function()
            toast:Dismiss()
        end
    })
    toast.closeButton = closeBtn

    -- 3.3 OPTIONAL STATUS / VECTOR ICON
    local iconOffset = padding
    if toastType or options.icon then
        local iconSize = options.iconSize or 20
        local iconFrame = createStatusIcon(self, toast, toastType, options.icon, iconSize, borderColor)
        iconFrame:SetPoint("TOPLEFT", toast, "TOPLEFT", padding, -padding - 2)
        toast.iconFrame = iconFrame
        iconOffset = padding + iconSize + 8
    end

    -- 3.4 TITLE FONTSTRING
    local titleText = options.title or "Notification"
    local title = toast:CreateFontString(nil, "OVERLAY", styles.fonts.label or "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", toast, "TOPLEFT", iconOffset, -padding)
    title:SetPoint("TOPRIGHT", closeBtn, "TOPLEFT", -6, 0)
    title:SetJustifyH("LEFT")
    title:SetWordWrap(false)
    title:SetText(titleText)
    if options.titleColor then
        title:SetTextColor(unpack(options.titleColor))
    else
        title:SetTextColor(unpack(styles.colors.white))
    end
    toast.titleLabel = title

    -- 3.5 MESSAGE FONTSTRING (Multiline)
    local messageText = options.message or ""
    local message = toast:CreateFontString(nil, "OVERLAY", styles.fonts.text or "GameFontHighlightSmall")
    message:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
    message:SetPoint("TOPRIGHT", closeBtn, "TOPLEFT", -6, -16)
    message:SetJustifyH("LEFT")
    message:SetWordWrap(true)
    message:SetText(messageText)
    if options.messageColor then
        message:SetTextColor(unpack(options.messageColor))
    else
        message:SetTextColor(unpack(styles.colors.surfaceHover or { 0.8, 0.8, 0.8, 1 }))
    end
    toast.messageLabel = message

    -- 3.6 DYNAMIC HEIGHT ADJUSTMENT
    local totalTextHeight = title:GetStringHeight() + 4 + message:GetStringHeight()
    local calculatedHeight = math.max(minHeight, totalTextHeight + (padding * 2))
    if options.showProgress then
        calculatedHeight = calculatedHeight + 4
    end
    toast:SetHeight(calculatedHeight)

    -- 3.7 OPTIONAL PROGRESS BAR (COUNTDOWN)
    if options.showProgress then
        local pBar = CreateFrame("StatusBar", nil, toast)
        pBar:SetHeight(3)
        pBar:SetPoint("BOTTOMLEFT", toast, "BOTTOMLEFT", 2, 2)
        pBar:SetPoint("BOTTOMRIGHT", toast, "BOTTOMRIGHT", -2, 2)
        
        local pBg = pBar:CreateTexture(nil, "BACKGROUND")
        pBg:SetAllPoints()
        pBg:SetColorTexture(unpack(styles.colors.surfaceDark or { 0.1, 0.1, 0.1, 0.8 }))
        
        local pFill = pBar:CreateTexture(nil, "ARTWORK")
        pFill:SetColorTexture(unpack(borderColor))
        pBar:SetStatusBarTexture(pFill)
        pBar:SetMinMaxValues(0, duration)
        pBar:SetValue(duration)
        toast.progressBar = pBar
    end

    -- 3.8 OPTIONAL ONCLICK CALLBACK / INTERACTIVITY
    if type(options.onClick) == "function" then
        toast:EnableMouse(true)
        toast:SetScript("OnMouseUp", function(_, button)
            if button == "LeftButton" and not toast.isDismissing then
                options.onClick(toast)
            end
        end)
    end

    -- 3.9 ANIMATIONS (NATIVE ANIMATION GROUP)
    local animGroup = toast:CreateAnimationGroup()
    if animGroup.SetToFinalAlpha then
        animGroup:SetToFinalAlpha(true)
    end
    local fadeIn = animGroup:CreateAnimation("Alpha")
    fadeIn:SetFromAlpha(0)
    fadeIn:SetToAlpha(1)
    fadeIn:SetDuration(0.2)
    fadeIn:SetOrder(1)
    animGroup:SetScript("OnFinished", function()
        toast:SetAlpha(1)
    end)
    toast.animFadeIn = animGroup

    local animFadeOutGroup = toast:CreateAnimationGroup()
    if animFadeOutGroup.SetToFinalAlpha then
        animFadeOutGroup:SetToFinalAlpha(true)
    end
    local fadeOut = animFadeOutGroup:CreateAnimation("Alpha")
    fadeOut:SetFromAlpha(1)
    fadeOut:SetToAlpha(0)
    fadeOut:SetDuration(0.25)
    fadeOut:SetOrder(1)
    animFadeOutGroup:SetScript("OnFinished", function()
        toast:Hide()
        toast:SetAlpha(1)
        toast.isDismissing = false
        if type(toast.onDismiss) == "function" then
            toast.onDismiss(toast)
        end
    end)
    toast.animFadeOut = animFadeOutGroup

    -- 3.10 LIFECYCLE SCRIPTS: HOVER PAUSE & AUTO-DISMISS
    toast:HookScript("OnEnter", function()
        toast.isPaused = true
    end)

    toast:HookScript("OnLeave", function()
        toast.isPaused = false
    end)

    toast:SetScript("OnUpdate", function(_, dt)
        if toast.isDismissing or toast.isPaused then return end

        toast.elapsed = toast.elapsed + dt
        local remaining = math.max(0, toast.duration - toast.elapsed)

        if toast.progressBar then
            toast.progressBar:SetValue(remaining)
        end

        if toast.elapsed >= toast.duration then
            toast:Dismiss()
        end
    end)

    -- 3.11 DISMISS METHOD
    function toast:Dismiss()
        if self.isDismissing then return end
        self.isDismissing = true
        if self.animFadeIn and self.animFadeIn:IsPlaying() then
            self.animFadeIn:Stop()
        end
        self.animFadeOut:Play()
    end

    -- Display with fade-in
    toast:SetAlpha(0)
    toast:Show()
    animGroup:Play()

    return toast
end

-------------------------------------------------------------------------------
-- 4. CONTEXT TOAST MANAGER & QUEUE SYSTEM
-- Objective: Manages automated positioning, stacking, and FIFO queueing.
-------------------------------------------------------------------------------

--- Initializes or retrieves the toast manager state for a context instance.
local function getToastManager(context)
    if not context.toastManager then
        context.toastManager = {
            config = {
                anchor = "TOPRIGHT",
                relativeTo = _G.UIParent,
                xOffset = -20,
                yOffset = -80,
                direction = "DOWN", -- "DOWN" or "UP"
                spacing = 10,
                maxVisible = 4,
                defaultDuration = 4,
            },
            activeToasts = {},
            queue = {}
        }
    end
    return context.toastManager
end

--- Re-anchors all currently active toasts according to the stacking configuration.
local function restackToasts(context)
    local mgr = getToastManager(context)
    local cfg = mgr.config
    local directionMult = (cfg.direction == "UP") and 1 or -1
    local currentY = cfg.yOffset

    for i, activeToast in ipairs(mgr.activeToasts) do
        activeToast:ClearAllPoints()
        activeToast:SetPoint(cfg.anchor, cfg.relativeTo, cfg.anchor, cfg.xOffset, currentY)
        currentY = currentY + ((activeToast:GetHeight() + cfg.spacing) * directionMult)
    end
end

--- Pops the next toast from the queue if slots are available.
local function processQueue(context)
    local mgr = getToastManager(context)
    if #mgr.activeToasts >= mgr.config.maxVisible then
        return
    end

    if #mgr.queue > 0 then
        local nextToastOptions = table.remove(mgr.queue, 1)
        context:showToast(nextToastOptions, true)
    end
end

--- Configures the toast manager layout and stacking rules.
--- @param config table Configuration table overriding anchor, xOffset, yOffset, direction, maxVisible, etc.
function Context:configureToasts(config)
    local mgr = getToastManager(self)
    if not config then return end
    for k, v in pairs(config) do
        mgr.config[k] = v
    end
    restackToasts(self)
end

--- Dispatches a toast notification, queuing it if the maxVisible limit is reached.
--- @param options table Configuration table for the toast.
--- @param fromQueue boolean|nil Internal flag indicating call from queue.
--- @return table|nil toast The active toast frame, or nil if queued.
function Context:showToast(options, fromQueue)
    options = options or {}
    local mgr = getToastManager(self)
    local cfg = mgr.config

    if not fromQueue and #mgr.activeToasts >= cfg.maxVisible then
        table.insert(mgr.queue, options)
        return nil
    end

    -- Inherit context default duration if not specified
    if not options.duration then
        options.duration = cfg.defaultDuration
    end

    local originalOnDismiss = options.onDismiss
    options.onDismiss = function(t)
        for i, active in ipairs(mgr.activeToasts) do
            if active == t then
                table.remove(mgr.activeToasts, i)
                break
            end
        end

        restackToasts(self)

        if type(originalOnDismiss) == "function" then
            originalOnDismiss(t)
        end

        processQueue(self)
    end

    local toast = self:createToast(options)
    table.insert(mgr.activeToasts, toast)
    restackToasts(self)

    return toast
end

-- Global library aliases for immediate access
lib.createToast = function(options)
    local defaultCtx = lib:createContext()
    return defaultCtx:createToast(options)
end

lib.showToast = function(options)
    local defaultCtx = lib:createContext()
    return defaultCtx:showToast(options)
end
