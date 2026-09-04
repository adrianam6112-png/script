--[[
    Aimbot Multifuncional by ale (z8km) - Versión 4.0
    Basado en el concepto de Exunys pero implementado desde cero.
    Características: FOV, suavizado, wallcheck, teamcheck, triggerbot, tracer, etc.
]]

-- ===================== CONFIGURACIÓN INICIAL =====================
local CONFIG = {
    MASTER_KEY = "ale2026",              -- Cambia esta clave
    DISCORD_LINK = "https://discord.gg/tu-invite", -- Enlace a tu Discord
    GUI_TITLE = "Aimbot by ale (z8km)",
    LOCK_PART = "Head",                  -- "Head" o "HumanoidRootPart"
    DEFAULT_FOV = 45,                    -- Grados
    DEFAULT_SMOOTH = 0.25,               -- 0-1, más bajo = más suave
}
-- =================================================================

local player = game.Players.LocalPlayer
local camera = workspace.CurrentCamera
local runService = game:GetService("RunService")
local userInputService = game:GetService("UserInputService")
local guiService = game:GetService("GuiService")
local players = game:GetService("Players")
local tweenService = game:GetService("TweenService")

-- Variables globales
local aimbotActive = false
local isAuthenticated = false
local renderConnection = nil
local currentFOV = CONFIG.DEFAULT_FOV
local currentSmooth = CONFIG.DEFAULT_SMOOTH
local currentLockPart = CONFIG.LOCK_PART
local lockedTarget = nil

-- Configuraciones adicionales (con valores por defecto)
local settings = {
    teamCheck = false,
    aliveCheck = true,
    wallCheck = false,
    triggerbot = false,
    triggerbotDelay = 0,
    triggerbotTeamCheck = false,
    tracerEnabled = true,
    tracerPosition = 3, -- 1=abajo, 2=centro, 3=mouse
    tracerColor = Color3.fromRGB(150, 150, 255),
    fovEnabled = true,
    fovVisible = true,
    fovRadius = currentFOV,
    fovColor = Color3.fromRGB(255, 255, 255),
    fovLockedColor = Color3.fromRGB(255, 150, 150),
    lockMode = 1, -- 1=CFrame, 2=mousemoverel
    sensitivity = 0, -- tiempo de animación
}

-- ===================== CREACIÓN DE LA GUI =====================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AimbotGUI"
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Ventana principal (se muestra solo tras verificar)
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 500, 0, 400)
mainFrame.Position = UDim2.new(0.5, -250, 0.5, -200)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
mainFrame.BackgroundTransparency = 0.95
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Visible = false
mainFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = mainFrame

-- Título con firma
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 40)
title.Text = CONFIG.GUI_TITLE
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.Parent = mainFrame

-- Botón Discord (abre enlace)
local discordBtn = Instance.new("TextButton")
discordBtn.Size = UDim2.new(0, 120, 0, 30)
discordBtn.Position = UDim2.new(1, -130, 0, 5)
discordBtn.Text = "💬 Discord"
discordBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
discordBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
discordBtn.Font = Enum.Font.GothamBold
discordBtn.TextSize = 14
local cornerDiscord = Instance.new("UICorner")
cornerDiscord.CornerRadius = UDim.new(0, 4)
cornerDiscord.Parent = discordBtn
discordBtn.Parent = mainFrame

-- Panel de pestañas (simulado con botones)
local tabFrame = Instance.new("Frame")
tabFrame.Size = UDim2.new(1, 0, 0, 35)
tabFrame.Position = UDim2.new(0, 0, 0, 40)
tabFrame.BackgroundTransparency = 1
tabFrame.Parent = mainFrame

local tabs = {"Aimbot", "FOV", "Tracer", "Triggerbot"}
local tabButtons = {}
for i, name in ipairs(tabs) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.25, -2, 1, -2)
    btn.Position = UDim2.new((i-1)*0.25, 0, 0, 0)
    btn.Text = name
    btn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    btn.TextColor3 = Color3.fromRGB(200, 200, 200)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 4)
    c.Parent = btn
    btn.Parent = tabFrame
    tabButtons[name] = btn
end

-- Contenedor de contenido (se actualiza al cambiar pestaña)
local contentFrame = Instance.new("Frame")
contentFrame.Size = UDim2.new(1, -10, 1, -85)
contentFrame.Position = UDim2.new(0, 5, 0, 80)
contentFrame.BackgroundTransparency = 1
contentFrame.Parent = mainFrame

-- ============= CONTENIDO DE CADA PESTAÑA =============
local function createAimbotTab()
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 1, 0)
    f.BackgroundTransparency = 1
    f.Parent = contentFrame

    local function addLabel(text, y)
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(0.3, 0, 0, 25)
        lbl.Position = UDim2.new(0.05, 0, 0, y)
        lbl.Text = text
        lbl.TextColor3 = Color3.fromRGB(220, 220, 220)
        lbl.BackgroundTransparency = 1
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 14
        lbl.TextXAlignment = Enum.TextXAlignment.Right
        lbl.Parent = f
        return lbl
    end

    local function addToggle(label, default, y, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.15, 0, 0, 25)
        btn.Position = UDim2.new(0.4, 0, 0, y)
        btn.Text = default and "✅" or "❌"
        btn.BackgroundColor3 = default and Color3.fromRGB(40, 180, 40) or Color3.fromRGB(180, 40, 40)
        btn.TextColor3 = Color3.fromRGB(255,255,255)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 16
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 4)
        c.Parent = btn
        btn.Parent = f
        local state = default
        btn.MouseButton1Click:Connect(function()
            state = not state
            btn.Text = state and "✅" or "❌"
            btn.BackgroundColor3 = state and Color3.fromRGB(40, 180, 40) or Color3.fromRGB(180, 40, 40)
            callback(state)
        end)
        return btn
    end

    local function addSlider(label, min, max, default, y, callback)
        local box = Instance.new("TextBox")
        box.Size = UDim2.new(0.15, 0, 0, 25)
        box.Position = UDim2.new(0.4, 0, 0, y)
        box.Text = tostring(default)
        box.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
        box.TextColor3 = Color3.fromRGB(255,255,255)
        box.Font = Enum.Font.Gotham
        box.TextSize = 14
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 4)
        c.Parent = box
        box.Parent = f
        box.FocusLost:Connect(function()
            local val = tonumber(box.Text)
            if val and val >= min and val <= max then
                callback(val)
            else
                box.Text = tostring(default)
            end
        end)
        return box
    end

    local function addDropdown(label, options, default, y, callback)
        local drop = Instance.new("TextButton")
        drop.Size = UDim2.new(0.2, 0, 0, 25)
        drop.Position = UDim2.new(0.4, 0, 0, y)
        drop.Text = default
        drop.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
        drop.TextColor3 = Color3.fromRGB(255,255,255)
        drop.Font = Enum.Font.Gotham
        drop.TextSize = 14
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 4)
        c.Parent = drop
        drop.Parent = f
        local current = default
        drop.MouseButton1Click:Connect(function()
            -- ciclo simple
            local idx = table.find(options, current)
            idx = idx and (idx % #options) + 1 or 1
            current = options[idx]
            drop.Text = current
            callback(current)
        end)
        return drop
    end

    -- Aimbot: Enable (global)
    addLabel("Activar Aimbot", 10)
    local enableBtn = addToggle("", false, 10, function(state)
        aimbotActive = state
        if state then
            print("🎯 Aimbot ACTIVADO")
            startAimbotLoop()
        else
            print("💤 Aimbot DESACTIVADO")
            if renderConnection then renderConnection:Disconnect(); renderConnection = nil end
            lockedTarget = nil
        end
    end)

    addLabel("Parte del cuerpo", 45)
    local partDropdown = addDropdown("", {"Head", "HumanoidRootPart"}, currentLockPart, 45, function(val)
        currentLockPart = val
    end)

    addLabel("Suavizado (0-1)", 80)
    local smoothBox = addSlider("", 0, 1, currentSmooth, 80, function(val)
        currentSmooth = val
    end)

    addLabel("Sensibilidad (tiempo)", 115)
    local sensBox = addSlider("", 0, 2, settings.sensitivity, 115, function(val)
        settings.sensitivity = val
    end)

    addLabel("TeamCheck", 150)
    addToggle("", settings.teamCheck, 150, function(state) settings.teamCheck = state end)

    addLabel("AliveCheck", 185)
    addToggle("", settings.aliveCheck, 185, function(state) settings.aliveCheck = state end)

    addLabel("WallCheck", 220)
    addToggle("", settings.wallCheck, 220, function(state) settings.wallCheck = state end)

    addLabel("Modo de bloqueo", 255)
    local modeDropdown = addDropdown("", {"CFrame", "MouseMoveRel"}, settings.lockMode == 1 and "CFrame" or "MouseMoveRel", 255, function(val)
        settings.lockMode = val == "CFrame" and 1 or 2
    end)

    return f
end

local function createFOVTab()
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 1, 0)
    f.BackgroundTransparency = 1
    f.Parent = contentFrame
    f.Visible = false

    local function addLabel(text, y)
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(0.3, 0, 0, 25)
        lbl.Position = UDim2.new(0.05, 0, 0, y)
        lbl.Text = text
        lbl.TextColor3 = Color3.fromRGB(220, 220, 220)
        lbl.BackgroundTransparency = 1
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 14
        lbl.TextXAlignment = Enum.TextXAlignment.Right
        lbl.Parent = f
        return lbl
    end

    local function addToggle(label, default, y, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.15, 0, 0, 25)
        btn.Position = UDim2.new(0.4, 0, 0, y)
        btn.Text = default and "✅" or "❌"
        btn.BackgroundColor3 = default and Color3.fromRGB(40, 180, 40) or Color3.fromRGB(180, 40, 40)
        btn.TextColor3 = Color3.fromRGB(255,255,255)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 16
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 4)
        c.Parent = btn
        btn.Parent = f
        local state = default
        btn.MouseButton1Click:Connect(function()
            state = not state
            btn.Text = state and "✅" or "❌"
            btn.BackgroundColor3 = state and Color3.fromRGB(40, 180, 40) or Color3.fromRGB(180, 40, 40)
            callback(state)
        end)
        return btn
    end

    local function addSlider(label, min, max, default, y, callback)
        local box = Instance.new("TextBox")
        box.Size = UDim2.new(0.15, 0, 0, 25)
        box.Position = UDim2.new(0.4, 0, 0, y)
        box.Text = tostring(default)
        box.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
        box.TextColor3 = Color3.fromRGB(255,255,255)
        box.Font = Enum.Font.Gotham
        box.TextSize = 14
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 4)
        c.Parent = box
        box.Parent = f
        box.FocusLost:Connect(function()
            local val = tonumber(box.Text)
            if val and val >= min and val <= max then
                callback(val)
            else
                box.Text = tostring(default)
            end
        end)
        return box
    end

    addLabel("FOV activo", 10)
    addToggle("", settings.fovEnabled, 10, function(state) settings.fovEnabled = state end)

    addLabel("FOV visible", 45)
    addToggle("", settings.fovVisible, 45, function(state) settings.fovVisible = state end)

    addLabel("Radio FOV", 80)
    local fovSlider = addSlider("", 0, 180, currentFOV, 80, function(val)
        currentFOV = val
        settings.fovRadius = val
    end)

    -- Color (se puede añadir selector de color simple)
    addLabel("Color (RGB)", 115)
    local rBox = addSlider("R", 0, 255, 255, 115, function(val) settings.fovColor = Color3.fromRGB(val, settings.fovColor.G*255, settings.fovColor.B*255) end)
    rBox.Position = UDim2.new(0.4, 0, 0, 115)
    local gBox = addSlider("G", 0, 255, 255, 115, function(val) settings.fovColor = Color3.fromRGB(settings.fovColor.R*255, val, settings.fovColor.B*255) end)
    gBox.Position = UDim2.new(0.55, 0, 0, 115)
    local bBox = addSlider("B", 0, 255, 255, 115, function(val) settings.fovColor = Color3.fromRGB(settings.fovColor.R*255, settings.fovColor.G*255, val) end)
    bBox.Position = UDim2.new(0.7, 0, 0, 115)

    addLabel("Color bloqueado", 150)
    local rLock = addSlider("R", 0, 255, 255, 150, function(val) settings.fovLockedColor = Color3.fromRGB(val, settings.fovLockedColor.G*255, settings.fovLockedColor.B*255) end)
    rLock.Position = UDim2.new(0.4, 0, 0, 150)
    local gLock = addSlider("G", 0, 255, 150, 150, function(val) settings.fovLockedColor = Color3.fromRGB(settings.fovLockedColor.R*255, val, settings.fovLockedColor.B*255) end)
    gLock.Position = UDim2.new(0.55, 0, 0, 150)
    local bLock = addSlider("B", 0, 255, 150, 150, function(val) settings.fovLockedColor = Color3.fromRGB(settings.fovLockedColor.R*255, settings.fovLockedColor.G*255, val) end)
    bLock.Position = UDim2.new(0.7, 0, 0, 150)

    return f
end

local function createTracerTab()
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 1, 0)
    f.BackgroundTransparency = 1
    f.Parent = contentFrame
    f.Visible = false

    local function addLabel(text, y)
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(0.3, 0, 0, 25)
        lbl.Position = UDim2.new(0.05, 0, 0, y)
        lbl.Text = text
        lbl.TextColor3 = Color3.fromRGB(220, 220, 220)
        lbl.BackgroundTransparency = 1
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 14
        lbl.TextXAlignment = Enum.TextXAlignment.Right
        lbl.Parent = f
        return lbl
    end

    local function addToggle(label, default, y, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.15, 0, 0, 25)
        btn.Position = UDim2.new(0.4, 0, 0, y)
        btn.Text = default and "✅" or "❌"
        btn.BackgroundColor3 = default and Color3.fromRGB(40, 180, 40) or Color3.fromRGB(180, 40, 40)
        btn.TextColor3 = Color3.fromRGB(255,255,255)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 16
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 4)
        c.Parent = btn
        btn.Parent = f
        local state = default
        btn.MouseButton1Click:Connect(function()
            state = not state
            btn.Text = state and "✅" or "❌"
            btn.BackgroundColor3 = state and Color3.fromRGB(40, 180, 40) or Color3.fromRGB(180, 40, 40)
            callback(state)
        end)
        return btn
    end

    local function addDropdown(label, options, default, y, callback)
        local drop = Instance.new("TextButton")
        drop.Size = UDim2.new(0.2, 0, 0, 25)
        drop.Position = UDim2.new(0.4, 0, 0, y)
        drop.Text = default
        drop.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
        drop.TextColor3 = Color3.fromRGB(255,255,255)
        drop.Font = Enum.Font.Gotham
        drop.TextSize = 14
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 4)
        c.Parent = drop
        drop.Parent = f
        local current = default
        drop.MouseButton1Click:Connect(function()
            local idx = table.find(options, current)
            idx = idx and (idx % #options) + 1 or 1
            current = options[idx]
            drop.Text = current
            callback(current)
        end)
        return drop
    end

    addLabel("Tracer activo", 10)
    addToggle("", settings.tracerEnabled, 10, function(state) settings.tracerEnabled = state end)

    addLabel("Posición", 45)
    addDropdown("", {"Abajo", "Centro", "Mouse"}, "Mouse", 45, function(val)
        local posMap = {Abajo=1, Centro=2, Mouse=3}
        settings.tracerPosition = posMap[val] or 3
    end)

    -- Color
    addLabel("Color (RGB)", 80)
    local rBox = addSlider("R", 0, 255, 150, 80, function(val) settings.tracerColor = Color3.fromRGB(val, settings.tracerColor.G*255, settings.tracerColor.B*255) end)
    rBox.Position = UDim2.new(0.4, 0, 0, 80)
    local gBox = addSlider("G", 0, 255, 150, 80, function(val) settings.tracerColor = Color3.fromRGB(settings.tracerColor.R*255, val, settings.tracerColor.B*255) end)
    gBox.Position = UDim2.new(0.55, 0, 0, 80)
    local bBox = addSlider("B", 0, 255, 255, 80, function(val) settings.tracerColor = Color3.fromRGB(settings.tracerColor.R*255, settings.tracerColor.G*255, val) end)
    bBox.Position = UDim2.new(0.7, 0, 0, 80)

    return f
end

local function createTriggerbotTab()
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 1, 0)
    f.BackgroundTransparency = 1
    f.Parent = contentFrame
    f.Visible = false

    local function addLabel(text, y)
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(0.3, 0, 0, 25)
        lbl.Position = UDim2.new(0.05, 0, 0, y)
        lbl.Text = text
        lbl.TextColor3 = Color3.fromRGB(220, 220, 220)
        lbl.BackgroundTransparency = 1
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 14
        lbl.TextXAlignment = Enum.TextXAlignment.Right
        lbl.Parent = f
        return lbl
    end

    local function addToggle(label, default, y, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.15, 0, 0, 25)
        btn.Position = UDim2.new(0.4, 0, 0, y)
        btn.Text = default and "✅" or "❌"
        btn.BackgroundColor3 = default and Color3.fromRGB(40, 180, 40) or Color3.fromRGB(180, 40, 40)
        btn.TextColor3 = Color3.fromRGB(255,255,255)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 16
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 4)
        c.Parent = btn
        btn.Parent = f
        local state = default
        btn.MouseButton1Click:Connect(function()
            state = not state
            btn.Text = state and "✅" or "❌"
            btn.BackgroundColor3 = state and Color3.fromRGB(40, 180, 40) or Color3.fromRGB(180, 40, 40)
            callback(state)
        end)
        return btn
    end

    local function addSlider(label, min, max, default, y, callback)
        local box = Instance.new("TextBox")
        box.Size = UDim2.new(0.15, 0, 0, 25)
        box.Position = UDim2.new(0.4, 0, 0, y)
        box.Text = tostring(default)
        box.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
        box.TextColor3 = Color3.fromRGB(255,255,255)
        box.Font = Enum.Font.Gotham
        box.TextSize = 14
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 4)
        c.Parent = box
        box.Parent = f
        box.FocusLost:Connect(function()
            local val = tonumber(box.Text)
            if val and val >= min and val <= max then
                callback(val)
            else
                box.Text = tostring(default)
            end
        end)
        return box
    end

    addLabel("Triggerbot activo", 10)
    addToggle("", settings.triggerbot, 10, function(state) settings.triggerbot = state end)

    addLabel("TeamCheck", 45)
    addToggle("", settings.triggerbotTeamCheck, 45, function(state) settings.triggerbotTeamCheck = state end)

    addLabel("Delay (segundos)", 80)
    addSlider("", 0, 1, settings.triggerbotDelay, 80, function(val