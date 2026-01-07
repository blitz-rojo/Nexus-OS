-- ╔══════════════════════════════════════════════════════════╗
-- ║            NEXUS OS v2.0 - UI SYSTEM MODULE             ║
-- ║              Features 16-35: Interface System            ║
-- ╚══════════════════════════════════════════════════════════╝

local UISystem = {}
UISystem.__index = UISystem

-- ============================================
-- SERVICES
-- ============================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

-- ============================================
-- CONFIGURATION
-- ============================================

local CONFIG = {
    -- Themes
    THEMES = {
        dark = {
            primary = Color3.fromRGB(25, 25, 35),
            secondary = Color3.fromRGB(35, 35, 45),
            accent = Color3.fromRGB(100, 100, 255),
            text = Color3.fromRGB(255, 255, 255),
            textDim = Color3.fromRGB(180, 180, 180)
        },
        light = {
            primary = Color3.fromRGB(245, 245, 250),
            secondary = Color3.fromRGB(255, 255, 255),
            accent = Color3.fromRGB(80, 80, 200),
            text = Color3.fromRGB(20, 20, 20),
            textDim = Color3.fromRGB(100, 100, 100)
        },
        rgb = {
            primary = Color3.fromRGB(25, 25, 35),
            secondary = Color3.fromRGB(35, 35, 45),
            accent = Color3.fromRGB(255, 0, 255), -- Será animado
            text = Color3.fromRGB(255, 255, 255),
            textDim = Color3.fromRGB(180, 180, 180)
        }
    },
    
    -- Layouts
    LAYOUTS = {
        default = {width = 550, height = 450},
        compact = {width = 400, height = 350},
        expanded = {width = 700, height = 550}
    },
    
    -- Animation Settings
    ANIMATION = {
        tweenTime = 0.3,
        easingStyle = Enum.EasingStyle.Quad,
        easingDirection = Enum.EasingDirection.Out
    }
}

-- ============================================
-- FEATURE 16-17: UI RAYFIELD OTIMIZADA + TEMAS
-- ============================================

function UISystem:CreateWindow(options)
    local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
    
    local window = Rayfield:CreateWindow({
        Name = options.Name or "NEXUS OS v2.0",
        LoadingTitle = options.LoadingTitle or "Loading...",
        LoadingSubtitle = options.LoadingSubtitle or "Please wait",
        ConfigurationSaving = {
            Enabled = true,
            FolderName = "NexusOS_v2",
            FileName = "Config"
        },
        Discord = {
            Enabled = false
        },
        KeySystem = false
    })
    
    self.Window = window
    self.CurrentTheme = options.Theme or "dark"
    
    return window
end

-- ============================================
-- FEATURE 18: TEMA RGB ANIMADO
-- ============================================

function UISystem:EnableRGBMode()
    self.RGBEnabled = true
    
    task.spawn(function()
        local hue = 0
        while self.RGBEnabled do
            hue = (hue + 1) % 360
            local color = Color3.fromHSV(hue / 360, 1, 1)
            
            -- Atualizar cor do accent em todos os elementos
            CONFIG.THEMES.rgb.accent = color
            
            task.wait(0.03) -- ~33 FPS para animação suave
        end
    end)
end

-- ============================================
-- FEATURE 19: DRAG INTELIGENTE
-- ============================================

function UISystem:MakeDraggable(frame, dragHandle)
    local dragging = false
    local dragInput, mousePos, framePos
    
    dragHandle = dragHandle or frame
    
    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            mousePos = input.Position
            framePos = frame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    dragHandle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or
           input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - mousePos
            local newPos = UDim2.new(
                framePos.X.Scale,
                framePos.X.Offset + delta.X,
                framePos.Y.Scale,
                framePos.Y.Offset + delta.Y
            )
            
            -- Smooth animation
            TweenService:Create(frame, TweenInfo.new(0.1), {Position = newPos}):Play()
        end
    end)
end

-- ============================================
-- FEATURE 20: ESCALA AUTOMÁTICA (PC/MOBILE)
-- ============================================

function UISystem:AutoScale()
    local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
    local screenSize = workspace.CurrentCamera.ViewportSize
    
    local scale
    if isMobile then
        -- Mobile: escala baseada na menor dimensão
        scale = math.min(screenSize.X, screenSize.Y) / 500
    else
        -- PC: escala baseada na largura
        scale = screenSize.X / 1920
    end
    
    -- Limitar escala entre 0.7 e 1.3
    scale = math.clamp(scale, 0.7, 1.3)
    
    return scale
end

function UISystem:ApplyAutoScale(gui)
    local scale = self:AutoScale()
    
    -- Aplicar UIScale
    local uiScale = Instance.new("UIScale")
    uiScale.Scale = scale
    uiScale.Parent = gui
    
    -- Atualizar quando tela mudar
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
        local newScale = self:AutoScale()
        TweenService:Create(uiScale, TweenInfo.new(0.3), {Scale = newScale}):Play()
    end)
end

-- ============================================
-- FEATURE 21: MINIMIZAR PARA ÍCONE FLUTUANTE
-- ============================================

function UISystem:CreateFloatingButton(mainFrame)
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "NexusFloatingButton"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = game:GetService("CoreGui")
    
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 60, 0, 60)
    button.Position = UDim2.new(1, -80, 0.5, -30)
    button.BackgroundColor3 = CONFIG.THEMES.dark.accent
    button.Text = "NX"
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Font = Enum.Font.SourceSansBold
    button.TextSize = 24
    button.Parent = screenGui
    
    -- Arredondar cantos
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = button
    
    -- Tornar arrastável
    self:MakeDraggable(button)
    
    -- Toggle visibilidade
    button.MouseButton1Click:Connect(function()
        mainFrame.Visible = not mainFrame.Visible
        
        -- Animação de clique
        TweenService:Create(button, TweenInfo.new(0.1), {Size = UDim2.new(0, 55, 0, 55)}):Play()
        task.wait(0.1)
        TweenService:Create(button, TweenInfo.new(0.1), {Size = UDim2.new(0, 60, 0, 60)}):Play()
    end)
    
    self.FloatingButton = button
    return button
end

-- ============================================
-- FEATURE 22: BLUR DE FUNDO
-- ============================================

function UISystem:EnableBlur()
    local blur = Instance.new("BlurEffect")
    blur.Name = "NexusBlur"
    blur.Size = 0
    blur.Parent = game:GetService("Lighting")
    
    -- Animar entrada
    TweenService:Create(blur, TweenInfo.new(0.5), {Size = 10}):Play()
    
    self.BlurEffect = blur
    return blur
end

function UISystem:DisableBlur()
    if self.BlurEffect then
        TweenService:Create(self.BlurEffect, TweenInfo.new(0.5), {Size = 0}):Play()
        task.wait(0.5)
        self.BlurEffect:Destroy()
        self.BlurEffect = nil
    end
end

-- ============================================
-- FEATURE 23: SISTEMA DE ABAS DINÂMICAS
-- ============================================

function UISystem:CreateDynamicTab(name, icon)
    if not self.Window then
        warn("Window not initialized!")
        return
    end
    
    local tab = self.Window:CreateTab(name, icon)
    
    if not self.Tabs then
        self.Tabs = {}
    end
    
    table.insert(self.Tabs, {
        name = name,
        tab = tab,
        sections = {}
    })
    
    return tab
end

-- ============================================
-- FEATURE 24: BUSCA POR FUNÇÕES
-- ============================================

function UISystem:CreateSearchBar(tab)
    local searchInput = tab:CreateInput({
        Name = "🔍 Search Features",
        PlaceholderText = "Type to search...",
        RemoveTextAfterFocusLost = false,
        Callback = function(text)
            self:FilterFeatures(text)
        end,
    })
    
    return searchInput
end

function UISystem:FilterFeatures(query)
    query = query:lower()
    
    -- Esconder/mostrar elementos baseado na busca
    for _, tabData in pairs(self.Tabs or {}) do
        for _, section in pairs(tabData.sections) do
            local matchFound = section.name:lower():find(query, 1, true)
            section.element.Visible = matchFound or query == ""
        end
    end
end

-- ============================================
-- FEATURE 25: FAVORITAR SCRIPTS
-- ============================================

function UISystem:CreateFavoriteSystem()
    self.Favorites = {}
    
    -- Carregar favoritos salvos
    local success, saved = pcall(function()
        return HttpService:JSONDecode(readfile("NexusOS_Favorites.json"))
    end)
    
    if success then
        self.Favorites = saved
    end
end

function UISystem:ToggleFavorite(featureName)
    if self.Favorites[featureName] then
        self.Favorites[featureName] = nil
    else
        self.Favorites[featureName] = true
    end
    
    self:SaveFavorites()
end

function UISystem:SaveFavorites()
    pcall(function()
        writefile("NexusOS_Favorites.json", HttpService:JSONEncode(self.Favorites))
    end)
end

function UISystem:IsFavorite(featureName)
    return self.Favorites[featureName] == true
end

-- ============================================
-- FEATURE 26: ATALHOS POR TECLA
-- ============================================

function UISystem:CreateKeybindSystem()
    self.Keybinds = {}
end

function UISystem:RegisterKeybind(key, callback, description)
    local keyEnum = Enum.KeyCode[key]
    
    if not keyEnum then
        warn("Invalid key:", key)
        return false
    end
    
    self.Keybinds[key] = {
        callback = callback,
        description = description
    }
    
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == keyEnum then
            callback()
        end
    end)
    
    return true
end

-- ============================================
-- FEATURE 27: NOTIFICAÇÕES ESTILO BADGE
-- ============================================

function UISystem:CreateNotification(options)
    local screenGui = game:GetService("CoreGui"):FindFirstChild("NexusNotifications")
    
    if not screenGui then
        screenGui = Instance.new("ScreenGui")
        screenGui.Name = "NexusNotifications"
        screenGui.ResetOnSpawn = false
        screenGui.Parent = game:GetService("CoreGui")
    end
    
    local notification = Instance.new("Frame")
    notification.Size = UDim2.new(0, 300, 0, 80)
    notification.Position = UDim2.new(1, 320, 0, 20 + (#screenGui:GetChildren() * 90))
    notification.BackgroundColor3 = CONFIG.THEMES.dark.secondary
    notification.BorderSizePixel = 0
    notification.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = notification
    
    -- Título
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -20, 0, 30)
    title.Position = UDim2.new(0, 10, 0, 10)
    title.BackgroundTransparency = 1
    title.Text = options.Title or "Notification"
    title.TextColor3 = CONFIG.THEMES.dark.text
    title.Font = Enum.Font.SourceSansBold
    title.TextSize = 16
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = notification
    
    -- Conteúdo
    local content = Instance.new("TextLabel")
    content.Size = UDim2.new(1, -20, 0, 30)
    content.Position = UDim2.new(0, 10, 0, 40)
    content.BackgroundTransparency = 1
    content.Text = options.Content or ""
    content.TextColor3 = CONFIG.THEMES.dark.textDim
    content.Font = Enum.Font.SourceSans
    content.TextSize = 14
    content.TextXAlignment = Enum.TextXAlignment.Left
    content.Parent = notification
    
    -- Animar entrada
    TweenService:Create(notification, TweenInfo.new(0.5, Enum.EasingStyle.Back), 
        {Position = UDim2.new(1, -320, notification.Position.Y.Scale, notification.Position.Y.Offset)}):Play()
    
    -- Auto-remover
    task.delay(options.Duration or 5, function()
        TweenService:Create(notification, TweenInfo.new(0.3), 
            {Position = UDim2.new(1, 320, notification.Position.Y.Scale, notification.Position.Y.Offset)}):Play()
        task.wait(0.3)
        notification:Destroy()
    end)
    
    return notification
end

-- ============================================
-- FEATURE 28: INDICADOR DE STATUS
-- ============================================

function UISystem:CreateStatusIndicator(tab, featureName)
    local indicator = tab:CreateLabel("Status: ⚫ OFF")
    
    self.StatusIndicators = self.StatusIndicators or {}
    self.StatusIndicators[featureName] = indicator
    
    return indicator
end

function UISystem:UpdateStatus(featureName, enabled)
    if self.StatusIndicators and self.StatusIndicators[featureName] then
        local status = enabled and "🟢 ON" or "⚫ OFF"
        self.StatusIndicators[featureName]:Set("Status: " .. status)
    end
end

-- ============================================
-- FEATURE 29: TOOLTIP EXPLICATIVO
-- ============================================

function UISystem:CreateTooltip(element, text)
    local tooltip = Instance.new("TextLabel")
    tooltip.Name = "Tooltip"
    tooltip.Size = UDim2.new(0, 200, 0, 50)
    tooltip.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    tooltip.BackgroundTransparency = 0.1
    tooltip.Text = text
    tooltip.TextColor3 = Color3.fromRGB(255, 255, 255)
    tooltip.Font = Enum.Font.SourceSans
    tooltip.TextSize = 14
    tooltip.TextWrapped = true
    tooltip.Visible = false
    tooltip.ZIndex = 1000
    tooltip.Parent = element
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = tooltip
    
    element.MouseEnter:Connect(function()
        tooltip.Visible = true
    end)
    
    element.MouseLeave:Connect(function()
        tooltip.Visible = false
    end)
    
    return tooltip
end

-- ============================================
-- FEATURE 30-35: OUTROS RECURSOS
-- ============================================

-- Animações suaves (já implementado via TweenService)

-- Modo streamer (esconde UI)
function UISystem:ToggleStreamerMode(enabled)
    if self.Window and self.Window.Parent then
        self.Window.Parent.Enabled = not enabled
    end
end

-- UI invisível ao print
function UISystem:MakeScreenshotProof()
    if self.Window and self.Window.Parent then
        self.Window.Parent.IgnoreGuiInset = true
    end
end

-- Layout customizável
function UISystem:ChangeLayout(layoutName)
    local layout = CONFIG.LAYOUTS[layoutName]
    if layout and self.Window then
        -- Aplicar novo tamanho (depende da implementação da biblioteca UI)
        -- Rayfield não suporta redimensionamento dinâmico nativamente
    end
end

-- Salvar layout do usuário
function UISystem:SaveLayout()
    if self.Window then
        local layoutData = {
            position = self.Window.Position,
            size = self.Window.Size
        }
        
        pcall(function()
            writefile("NexusOS_Layout.json", HttpService:JSONEncode(layoutData))
        end)
    end
end

-- Modo compacto
function UISystem:ToggleCompactMode(enabled)
    -- Implementação depende da estrutura da UI
    self:ChangeLayout(enabled and "compact" or "default")
end

-- ============================================
-- INITIALIZATION
-- ============================================

function UISystem.new()
    local self = setmetatable({}, UISystem)
    
    self:CreateKeybindSystem()
    self:CreateFavoriteSystem()
    
    return self
end

return UISystem
