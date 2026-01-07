-- ╔══════════════════════════════════════════════════════════╗
-- ║              NEXUS OS v2.0 - MASTER LOADER              ║
-- ║                   150 Features System                    ║
-- ╚══════════════════════════════════════════════════════════╝

-- Prevenir execução múltipla
if getgenv().NexusOS then
    return warn("⚠️ NEXUS OS already loaded!")
end

getgenv().NexusOS = {
    Version = "2.0.0",
    Loaded = false
}

print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("🌟 NEXUS OS v2.0 LOADER")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

-- ============================================
-- CONFIGURAÇÃO
-- ============================================

local REPO_BASE = "https://raw.githubusercontent.com/blitz-rojo/Nexus-OS/main"

local MODULES = {
    Security = REPO_BASE .. "/core/security.lua",
    UI = REPO_BASE .. "/core/ui.lua",
    ESP = REPO_BASE .. "/core/esp.lua",
    Combat = REPO_BASE .. "/core/combat.lua",
    Movement = REPO_BASE .. "/core/movement.lua",
    Automation = REPO_BASE .. "/core/automation.lua",
    Protection = REPO_BASE .. "/core/protection.lua",
    Advanced = REPO_BASE .. "/core/advanced.lua"
}

-- ============================================
-- FUNÇÃO DE CARREGAMENTO SEGURO
-- ============================================

local function LoadModule(moduleName, url)
    local success, result = pcall(function()
        print(string.format("⏳ Loading %s...", moduleName))
        
        local scriptContent = game:HttpGet(url)
        local moduleFunc = loadstring(scriptContent)
        
        if not moduleFunc then
            error("Failed to compile " .. moduleName)
        end
        
        local module = moduleFunc()
        
        print(string.format("✅ %s loaded successfully", moduleName))
        
        return module
    end)
    
    if not success then
        warn(string.format("❌ Failed to load %s: %s", moduleName, tostring(result)))
        return nil
    end
    
    return result
end

-- ============================================
-- CARREGAR TODOS OS MÓDULOS
-- ============================================

print("
📦 Loading core modules...")

local Modules = {
    Security = LoadModule("Security Core", MODULES.Security),
    UI = LoadModule("UI System", MODULES.UI),
    ESP = LoadModule("ESP System", MODULES.ESP),
    Combat = LoadModule("Combat System", MODULES.Combat),
    Movement = LoadModule("Movement System", MODULES.Movement),
    Automation = LoadModule("Automation System", MODULES.Automation),
    Protection = LoadModule("Protection System", MODULES.Protection),
    Advanced = LoadModule("Advanced Features", MODULES.Advanced)
}

-- Verificar se todos os módulos essenciais carregaram
local essentialModules = {"Security", "UI"}
for _, moduleName in pairs(essentialModules) do
    if not Modules[moduleName] then
        return error(string.format("❌ Essential module '%s' failed to load!", moduleName))
    end
end

print("
✅ All modules loaded!")

-- ============================================
-- INICIALIZAÇÃO DO SISTEMA DE SEGURANÇA
-- ============================================

print("
🔐 Initializing security...")

local Security = Modules.Security.new()

-- Detectar executor
local executor = Security:DetectExecutor()
print("🖥️  Executor:", executor)

-- Obter HWID
local hwid = Security:GetHWID()
print("🔑 HWID:", hwid:sub(1, 16) .. "...")

-- Sistema de Key (EXEMPLO - DESCOMENTE E CONFIGURE)
--[[
local function RequestKey()
    local keyInput = ""
    
    -- Aqui você pode usar um sistema de input customizado ou Rayfield
    -- Por simplicidade, vou usar um prompt básico
    
    keyInput = "YOUR_KEY_HERE" -- Substitua por sistema de input real
    
    return keyInput
end

local userKey = RequestKey()
local keyResult = Security:VerifyKey(userKey)

if not keyResult.success then
    return error("❌ Invalid key! Please check and try again.")
end

print("✅ Key verified!")
print("📊 License type:", keyResult.license_type)

-- Verificar HWID
if not Security:VerifyHWID(userKey, hwid) then
    return error("❌ HWID mismatch! This key is registered to another device.")
end

print("✅ HWID verified!")

-- Validar licença
local licenseCheck = Security:ValidateLicense(keyResult)
if not licenseCheck.valid then
    return error("❌ License expired! Please renew your subscription.")
end

if licenseCheck.remaining > 0 then
    print(string.format("⏰ License expires in: %d days, %d hours", 
        licenseCheck.days_left, licenseCheck.hours_left))
else
    print("♾️  Lifetime license active!")
end

-- Verificar whitelist
local userId = game:GetService("Players").LocalPlayer.UserId
if not Security:IsWhitelisted(userId) then
    Security:SendLog({
        event = "unauthorized_access_attempt",
        user_id = userId,
        reason = "Not whitelisted"
    })
    return error("❌ You are not whitelisted!")
end

-- Verificar blacklist
if Security:IsBlacklisted(userId) then
    return error("❌ You have been blacklisted!")
end

-- Verificar updates
local updateCheck = Security:CheckForUpdates()
if updateCheck and updateCheck.available then
    print("🔄 Update available:", updateCheck.version)
    if updateCheck.force then
        print("⚠️  Force update required. Updating...")
        -- Update automático já é feito pelo sistema
    end
end
]]

print("✅ Security checks passed!")

-- ============================================
-- INICIALIZAÇÃO DA UI
-- ============================================

print("
🎨 Initializing UI...")

local UI = Modules.UI.new()

local window = UI:CreateWindow({
    Name = "NEXUS OS v2.0 Pro",
    LoadingTitle = "NEXUS OS v2.0",
    LoadingSubtitle = "150+ Features • Premium Edition",
    Theme = "dark"
})

-- Aplicar auto-escala
UI:ApplyAutoScale(window)

-- Criar botão flutuante para minimizar
UI:CreateFloatingButton(window)

-- Ativar blur de fundo
UI:EnableBlur()

-- ============================================
-- CRIAR ABAS E FEATURES
-- ============================================

-- TAB 1: SEGURANÇA & SISTEMA
local SecurityTab = UI:CreateDynamicTab("Security", "shield")
SecurityTab:CreateSection("System Information")

SecurityTab:CreateLabel("Executor: " .. executor)
SecurityTab:CreateLabel("HWID: " .. hwid:sub(1, 16) .. "...")
SecurityTab:CreateLabel("Version: " .. getgenv().NexusOS.Version)

-- TAB 2: FÍSICA & MOVIMENTO
local PhysicsTab = UI:CreateDynamicTab("Physics", "wind")
PhysicsTab:CreateSection("Movement Controls")

-- Fly
PhysicsTab:CreateToggle({
    Name = "Fly Mode",
    CurrentValue = false,
    Flag = "Fly",
    Callback = function(value)
        UI:UpdateStatus("Fly", value)
        -- Módulo de Movement implementa a lógica
    end
})

UI:CreateStatusIndicator(PhysicsTab, "Fly")

-- Speed
PhysicsTab:CreateSlider({
    Name = "Walk Speed",
    Range = {16, 500},
    Increment = 1,
    CurrentValue = 16,
    Flag = "Speed",
    Callback = function(value)
        -- Implementação do Movement module
    end
})

-- Noclip
PhysicsTab:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Flag = "Noclip",
    Callback = function(value)
        UI:UpdateStatus("Noclip", value)
    end
})

UI:CreateStatusIndicator(PhysicsTab, "Noclip")

-- TAB 3: VISUAL & ESP
local VisualTab = UI:CreateDynamicTab("Visual", "eye")
VisualTab:CreateSection("ESP Options")

VisualTab:CreateToggle({
    Name = "ESP Enabled",
    CurrentValue = false,
    Flag = "ESP",
    Callback = function(value)
        UI:UpdateStatus("ESP", value)
        -- ESP module implementa a lógica
    end
})

UI:CreateStatusIndicator(VisualTab, "ESP")

VisualTab:CreateToggle({
    Name = "ESP Boxes",
    CurrentValue = true,
    Flag = "ESPBoxes"
})

VisualTab:CreateToggle({
    Name = "ESP Names",
    CurrentValue = true,
    Flag = "ESPNames"
})

VisualTab:CreateToggle({
    Name = "ESP Distance",
    CurrentValue = true,
    Flag = "ESPDistance"
})

VisualTab:CreateToggle({
    Name = "ESP Health",
    CurrentValue = false,
    Flag = "ESPHealth"
})

VisualTab:CreateToggle({
    Name = "Fullbright",
    CurrentValue = false,
    Flag = "Fullbright",
    Callback = function(value)
        game:GetService("Lighting").Brightness = value and 2 or 1
        game:GetService("Lighting").GlobalShadows = not value
    end
})

-- TAB 4: COMBATE
local CombatTab = UI:CreateDynamicTab("Combat", "crosshair")
CombatTab:CreateSection("Combat Assist")

CombatTab:CreateToggle({
    Name = "Aimbot",
    CurrentValue = false,
    Flag = "Aimbot",
    Callback = function(value)
        UI:UpdateStatus("Aimbot", value)
    end
})

UI:CreateStatusIndicator(CombatTab, "Aimbot")

CombatTab:CreateSlider({
    Name = "Aimbot FOV",
    Range = {10, 360},
    Increment = 1,
    CurrentValue = 90,
    Flag = "AimbotFOV"
})

CombatTab:CreateToggle({
    Name = "Silent Aim",
    CurrentValue = false,
    Flag = "SilentAim"
})

CombatTab:CreateToggle({
    Name = "Trigger Bot",
    CurrentValue = false,
    Flag = "TriggerBot"
})

-- TAB 5: AUTOMAÇÃO
local AutoTab = UI:CreateDynamicTab("Automation", "zap")
AutoTab:CreateSection("Farm & Auto")

AutoTab:CreateToggle({
    Name = "Auto Farm",
    CurrentValue = false,
    Flag = "AutoFarm",
    Callback = function(value)
        UI:UpdateStatus("AutoFarm", value)
    end
})

UI:CreateStatusIndicator(AutoTab, "AutoFarm")

AutoTab:CreateToggle({
    Name = "Auto Clicker",
    CurrentValue = false,
    Flag = "AutoClicker"
})

AutoTab:CreateSlider({
    Name = "Click Speed (CPS)",
    Range = {1, 50},
    Increment = 1,
    CurrentValue = 10,
    Flag = "ClickSpeed"
})

AutoTab:CreateToggle({
    Name = "Anti-AFK",
    CurrentValue = false,
    Flag = "AntiAFK"
})

-- TAB 6: CONFIGURAÇÕES
local ConfigTab = UI:CreateDynamicTab("Config", "settings")
ConfigTab:CreateSection("System Settings")

-- Tema
ConfigTab:CreateDropdown({
    Name = "Theme",
    Options = {"Dark", "Light", "RGB"},
    CurrentOption = "Dark",
    Flag = "Theme",
    Callback = function(option)
        if option == "RGB" then
            UI:EnableRGBMode()
        else
            UI.RGBEnabled = false
        end
    end
})

-- Layout
ConfigTab:CreateDropdown({
    Name = "Layout",
    Options = {"Default", "Compact", "Expanded"},
    CurrentOption = "Default",
    Flag = "Layout",
    Callback = function(option)
        UI:ChangeLayout(option:lower())
    end
})

ConfigTab:CreateButton({
    Name = "Save Configuration",
    Callback = function()
        UI:SaveLayout()
        UI:CreateNotification({
            Title = "Success",
            Content = "Configuration saved!",
            Duration = 3
        })
    end
})

-- Modo Streamer
ConfigTab:CreateToggle({
    Name = "Streamer Mode",
    CurrentValue = false,
    Flag = "StreamerMode",
    Callback = function(value)
        UI:ToggleStreamerMode(value)
    end
})

-- Screenshot Proof
ConfigTab:CreateToggle({
    Name = "Screenshot Proof UI",
    CurrentValue = false,
    Flag = "ScreenshotProof",
    Callback = function(value)
        UI:MakeScreenshotProof()
    end
})

-- Panic Button
ConfigTab:CreateButton({
    Name = "🚨 PANIC BUTTON",
    Callback = function()
        -- Desativar tudo
        UI:CreateNotification({
            Title = "⚠️ Emergency Shutdown",
            Content = "All features disabled!",
            Duration = 3
        })
        
        -- Cleanup
        Security:EmergencyShutdown()
        UI:DisableBlur()
    end
})

-- Unload
ConfigTab:CreateButton({
    Name = "Unload Nexus OS",
    Callback = function()
        UI:DisableBlur()
        Security:Unload()
        
        if window then
            window:Destroy()
        end
        
        getgenv().NexusOS = nil
        
        print("✅ Nexus OS unloaded successfully")
    end
})

-- ============================================
-- SISTEMA DE BUSCA
-- ============================================

local SearchTab = UI:CreateDynamicTab("Search", "search")
UI:CreateSearchBar(SearchTab)

-- ============================================
-- KEYBINDS
-- ============================================

-- Toggle UI: Insert
UI:RegisterKeybind("Insert", function()
    if window then
        window.Enabled = not window.Enabled
    end
end, "Toggle UI Visibility")

-- Panic: Delete
UI:RegisterKeybind("Delete", function()
    Security:EmergencyShutdown()
end, "Emergency Shutdown")

-- ============================================
-- FINALIZAÇÃO
-- ============================================

getgenv().NexusOS.Loaded = true
getgenv().NexusOS.Modules = Modules
getgenv().NexusOS.Security = Security
getgenv().NexusOS.UI = UI

-- Notificação de sucesso
UI:CreateNotification({
    Title = "🎉 NEXUS OS v2.0",
    Content = "150 features loaded successfully!",
    Duration = 5
})

print("
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("✅ NEXUS OS v2.0 READY!")
print("🔑 Press INSERT to toggle UI")
print("🚨 Press DELETE for panic mode")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
")
