-- ╔══════════════════════════════════════════════════════════╗
-- ║          NEXUS OS v2.0 - SECURITY CORE MODULE          ║
-- ║              Features 1-15: System Protection            ║
-- ╚══════════════════════════════════════════════════════════╝

local SecurityCore = {}
SecurityCore.__index = SecurityCore

-- ============================================
-- SERVICES
-- ============================================

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")

-- ============================================
-- CONFIGURATION
-- ============================================

local CONFIG = {
    -- API Endpoints (substitua pelos seus)
    API_BASE = "https://seu-servidor.com/api",
    KEY_ENDPOINT = "/verify-key",
    HWID_ENDPOINT = "/verify-hwid",
    WHITELIST_ENDPOINT = "/whitelist",
    LOG_ENDPOINT = "/log",
    UPDATE_ENDPOINT = "/version",
    
    -- Fallback Server
    FALLBACK_API = "https://backup-servidor.com/api",
    
    -- Version Control
    CURRENT_VERSION = "2.0.0",
    MIN_VERSION = "2.0.0",
    
    -- Security
    ANTI_TAMPER_HASH = "NEXUS_HASH_2024",
    ENCRYPTION_KEY = "NX_KEY_SECURE",
    
    -- License Types
    LICENSE_TYPES = {
        ["24h"] = 86400,      -- 24 horas em segundos
        ["7d"] = 604800,      -- 7 dias
        ["30d"] = 2592000,    -- 30 dias
        ["lifetime"] = -1      -- Vitalício
    }
}

-- ============================================
-- FEATURE 1: KEY SYSTEM AVANÇADO
-- ============================================

function SecurityCore:VerifyKey(key)
    local success, result = pcall(function()
        local url = CONFIG.API_BASE .. CONFIG.KEY_ENDPOINT
        
        local data = {
            key = key,
            timestamp = os.time(),
            checksum = self:GenerateChecksum(key)
        }
        
        local response = self:SecureRequest(url, data)
        
        if response and response.valid then
            return {
                success = true,
                license_type = response.license_type,
                expires_at = response.expires_at,
                user_id = response.user_id,
                hwid = response.hwid
            }
        end
        
        return {success = false, reason = "Invalid key"}
    end)
    
    if not success then
        return self:FallbackKeyCheck(key)
    end
    
    return result
end

-- ============================================
-- FEATURE 2: VERIFICAÇÃO HWID
-- ============================================

function SecurityCore:GetHWID()
    -- Método multi-layer para HWID único
    local hwid_parts = {}
    
    -- Layer 1: Executor fingerprint
    if gethwid then
        table.insert(hwid_parts, gethwid())
    end
    
    -- Layer 2: Device-specific data
    if syn and syn.request then
        table.insert(hwid_parts, tostring(syn.request))
    end
    
    -- Layer 3: Player-specific data
    local player = Players.LocalPlayer
    table.insert(hwid_parts, tostring(player.UserId))
    
    -- Layer 4: Executor-specific identifiers
    if identifyexecutor then
        table.insert(hwid_parts, identifyexecutor())
    end
    
    -- Combinar tudo em hash único
    local combined = table.concat(hwid_parts, "|")
    return self:Hash(combined)
end

function SecurityCore:VerifyHWID(key, hwid)
    local success, result = pcall(function()
        local url = CONFIG.API_BASE .. CONFIG.HWID_ENDPOINT
        
        local data = {
            key = key,
            hwid = hwid,
            timestamp = os.time()
        }
        
        local response = self:SecureRequest(url, data)
        
        return response and response.valid
    end)
    
    return success and result
end

-- ============================================
-- FEATURE 3: ANTI-TAMPER
-- ============================================

function SecurityCore:InitAntiTamper()
    local originalScript = game:GetService("CoreGui"):GetFullName()
    local checksum = self:CalculateScriptChecksum()
    
    -- Verificação contínua
    task.spawn(function()
        while task.wait(5) do
            local currentChecksum = self:CalculateScriptChecksum()
            
            if currentChecksum ~= checksum then
                self:TriggerTamperAlert()
                self:EmergencyShutdown()
                break
            end
        end
    end)
end

function SecurityCore:CalculateScriptChecksum()
    -- Gerar hash do ambiente atual
    local env_data = {
        getgenv and getgenv() or {},
        _G,
        shared
    }
    
    return self:Hash(HttpService:JSONEncode(env_data))
end

function SecurityCore:TriggerTamperAlert()
    warn("⚠️ NEXUS OS: Tamper detected! Script will shutdown.")
    
    -- Log remoto
    self:SendLog({
        event = "tamper_detected",
        user_id = Players.LocalPlayer.UserId,
        timestamp = os.time()
    })
end

-- ============================================
-- FEATURE 4: AUTO UPDATE
-- ============================================

function SecurityCore:CheckForUpdates()
    local success, updateData = pcall(function()
        local url = CONFIG.API_BASE .. CONFIG.UPDATE_ENDPOINT
        local response = self:SecureRequest(url, {version = CONFIG.CURRENT_VERSION})
        
        if response and response.latest_version then
            return {
                available = response.latest_version ~= CONFIG.CURRENT_VERSION,
                version = response.latest_version,
                url = response.download_url,
                changelog = response.changelog,
                force = response.force_update
            }
        end
        
        return {available = false}
    end)
    
    if success and updateData.available then
        if updateData.force then
            self:ForceUpdate(updateData.url)
        else
            return updateData
        end
    end
    
    return nil
end

function SecurityCore:ForceUpdate(url)
    warn("🔄 NEXUS OS: Updating to latest version...")
    
    local success, newScript = pcall(function()
        return game:HttpGet(url)
    end)
    
    if success and newScript then
        -- Descarregar versão atual
        self:Unload()
        
        -- Carregar nova versão
        loadstring(newScript)()
    else
        warn("❌ Update failed. Please reinstall manually.")
    end
end

-- ============================================
-- FEATURE 5: SISTEMA DE LICENÇA POR TEMPO
-- ============================================

function SecurityCore:ValidateLicense(licenseData)
    local licenseType = licenseData.license_type
    local expiresAt = licenseData.expires_at
    
    -- Lifetime license
    if CONFIG.LICENSE_TYPES[licenseType] == -1 then
        return {valid = true, remaining = -1}
    end
    
    -- Timed license
    local currentTime = os.time()
    local remaining = expiresAt - currentTime
    
    if remaining > 0 then
        return {
            valid = true,
            remaining = remaining,
            expires_at = expiresAt,
            days_left = math.floor(remaining / 86400),
            hours_left = math.floor((remaining % 86400) / 3600)
        }
    end
    
    return {valid = false, reason = "License expired"}
end

-- ============================================
-- FEATURE 6: ANTI-DEBUG
-- ============================================

function SecurityCore:InitAntiDebug()
    -- Detectar tentativas de debugging
    local debugDetected = false
    
    -- Check 1: Debugger hooks
    if debug and debug.getinfo then
        local info = debug.getinfo(1)
        if info.what == "C" then
            debugDetected = true
        end
    end
    
    -- Check 2: Performance anomalies
    local startTime = tick()
    for i = 1, 1000 do end
    local endTime = tick()
    
    if (endTime - startTime) > 0.1 then
        debugDetected = true
    end
    
    -- Check 3: Unusual function calls
    if getfenv and getfenv(0) then
        local env = getfenv(0)
        if env.debug or env.require then
            debugDetected = true
        end
    end
    
    if debugDetected then
        self:EmergencyShutdown()
        return false
    end
    
    return true
end

-- ============================================
-- FEATURE 7: LOADER CRIPTOGRAFADO
-- ============================================

function SecurityCore:DecryptScript(encryptedData)
    -- Implementação de descriptografia simples
    -- Em produção, use algoritmos mais robustos (AES, RSA)
    
    local key = CONFIG.ENCRYPTION_KEY
    local decrypted = ""
    
    for i = 1, #encryptedData do
        local charCode = string.byte(encryptedData, i)
        local keyChar = string.byte(key, ((i - 1) % #key) + 1)
        decrypted = decrypted .. string.char(bit32.bxor(charCode, keyChar))
    end
    
    return decrypted
end

function SecurityCore:LoadEncryptedScript(url)
    local success, encrypted = pcall(function()
        return game:HttpGet(url)
    end)
    
    if success then
        local decrypted = self:DecryptScript(encrypted)
        return loadstring(decrypted)
    end
    
    return nil
end

-- ============================================
-- FEATURE 8: FALLBACK SERVER
-- ============================================

function SecurityCore:SecureRequest(url, data, useFallback)
    local endpoint = useFallback and CONFIG.FALLBACK_API or CONFIG.API_BASE
    local fullUrl = endpoint .. url:gsub(CONFIG.API_BASE, "")
    
    local success, response = pcall(function()
        if syn and syn.request then
            local result = syn.request({
                Url = fullUrl,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json",
                    ["X-Auth-Token"] = self:GenerateAuthToken()
                },
                Body = HttpService:JSONEncode(data)
            })
            
            return HttpService:JSONDecode(result.Body)
        else
            -- Fallback para HttpService
            return {success = false, reason = "No HTTP method available"}
        end
    end)
    
    if not success and not useFallback then
        warn("⚠️ Primary server failed, trying fallback...")
        return self:SecureRequest(url, data, true)
    end
    
    return response
end

-- ============================================
-- FEATURE 9: WHITELIST DINÂMICA
-- ============================================

SecurityCore.Whitelist = {}

function SecurityCore:LoadWhitelist()
    local success, whitelist = pcall(function()
        local url = CONFIG.API_BASE .. CONFIG.WHITELIST_ENDPOINT
        local response = self:SecureRequest(url, {action = "fetch"})
        return response and response.users or {}
    end)
    
    if success then
        self.Whitelist = whitelist
        return true
    end
    
    return false
end

function SecurityCore:IsWhitelisted(userId)
    return self.Whitelist[tostring(userId)] ~= nil
end

function SecurityCore:RefreshWhitelist()
    -- Atualização automática a cada 60 segundos
    task.spawn(function()
        while task.wait(60) do
            self:LoadWhitelist()
        end
    end)
end

-- ============================================
-- FEATURE 10: BLACKLIST AUTOMÁTICA
-- ============================================

SecurityCore.Blacklist = {}

function SecurityCore:AddToBlacklist(userId, reason)
    self.Blacklist[tostring(userId)] = {
        reason = reason,
        timestamp = os.time()
    }
    
    -- Sync com servidor
    self:SendLog({
        event = "blacklist_add",
        user_id = userId,
        reason = reason
    })
end

function SecurityCore:IsBlacklisted(userId)
    return self.Blacklist[tostring(userId)] ~= nil
end

-- ============================================
-- FEATURE 11: SISTEMA DE LOGS REMOTO
-- ============================================

function SecurityCore:SendLog(logData)
    pcall(function()
        local url = CONFIG.API_BASE .. CONFIG.LOG_ENDPOINT
        
        local fullLog = {
            timestamp = os.time(),
            game_id = game.PlaceId,
            user_id = Players.LocalPlayer.UserId,
            executor = identifyexecutor and identifyexecutor() or "Unknown",
            data = logData
        }
        
        self:SecureRequest(url, fullLog)
    end)
end

-- ============================================
-- FEATURE 12-13: MODO LITE / PRO
-- ============================================

function SecurityCore:GetUserMode(licenseData)
    local licenseType = licenseData.license_type
    
    if licenseType == "lifetime" or licenseType == "30d" then
        return "pro"
    else
        return "lite"
    end
end

function SecurityCore:IsProMode(userMode)
    return userMode == "pro"
end

-- ============================================
-- FEATURE 14: DETECÇÃO DE EXECUTOR
-- ============================================

function SecurityCore:DetectExecutor()
    local executors = {
        Synapse = syn and syn.request,
        ScriptWare = SCRIPT_WARE_VERSION,
        KRNL = KRNL_LOADED,
        Fluxus = FLUXUS_LOADED or Fluxus,
        Hydrogen = HYDROGEN_LOADED,
        Arceus = ARCEUS_LOADED,
        Solara = SOLARA_LOADED,
        Nihon = NIHON_LOADED
    }
    
    for name, detected in pairs(executors) do
        if detected then
            return name
        end
    end
    
    return "Unknown"
end

function SecurityCore:GetExecutorCapabilities(executor)
    local capabilities = {
        Synapse = {drawing = true, websocket = true, http = true},
        ScriptWare = {drawing = true, websocket = true, http = true},
        KRNL = {drawing = true, websocket = false, http = true},
        Fluxus = {drawing = true, websocket = false, http = true},
        Hydrogen = {drawing = false, websocket = false, http = true},
        Unknown = {drawing = false, websocket = false, http = true}
    }
    
    return capabilities[executor] or capabilities.Unknown
end

-- ============================================
-- FEATURE 15: PROTEÇÃO CONTRA HOOK EXTERNO
-- ============================================

function SecurityCore:InitAntiHook()
    -- Proteger funções críticas
    local protectedFunctions = {
        "game.HttpGet",
        "loadstring",
        "getgenv",
        "setmetatable"
    }
    
    for _, funcName in pairs(protectedFunctions) do
        local original = getfenv()[funcName]
        
        if original then
            -- Verificar se foi hooked
            local info = debug.getinfo(original)
            if info and info.what == "C" then
                -- Função original, tudo bem
            else
                warn("⚠️ Potential hook detected on:", funcName)
                self:TriggerTamperAlert()
            end
        end
    end
end

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

function SecurityCore:Hash(data)
    -- Hash simples (use SHA256 em produção)
    local hash = 0
    for i = 1, #data do
        hash = ((hash * 31) + string.byte(data, i)) % 2^32
    end
    return tostring(hash)
end

function SecurityCore:GenerateChecksum(data)
    return self:Hash(data .. CONFIG.ANTI_TAMPER_HASH)
end

function SecurityCore:GenerateAuthToken()
    local player = Players.LocalPlayer
    local timestamp = os.time()
    local data = string.format("%s|%d|%s", player.UserId, timestamp, CONFIG.ENCRYPTION_KEY)
    return self:Hash(data)
end

function SecurityCore:EmergencyShutdown()
    warn("🚨 NEXUS OS: Emergency shutdown initiated")
    
    -- Limpar ambiente
    if getgenv then
        getgenv().NexusOS = nil
    end
    
    _G.NexusOS = nil
    shared.NexusOS = nil
    
    -- Fechar UI se existir
    pcall(function()
        game:GetService("CoreGui"):FindFirstChild("NexusOS"):Destroy()
    end)
end

function SecurityCore:Unload()
    self:EmergencyShutdown()
end

-- ============================================
-- INITIALIZATION
-- ============================================

function SecurityCore.new()
    local self = setmetatable({}, SecurityCore)
    
    -- Inicializar proteções
    self:InitAntiTamper()
    self:InitAntiDebug()
    self:InitAntiHook()
    self:LoadWhitelist()
    self:RefreshWhitelist()
    
    return self
end

-- ============================================
-- EXEMPLO DE USO
-- ============================================

--[[
local Security = SecurityCore.new()

-- Verificar key
local keyResult = Security:VerifyKey("USER_KEY_HERE")
if not keyResult.success then
    return warn("Invalid key!")
end

-- Verificar HWID
local hwid = Security:GetHWID()
if not Security:VerifyHWID(keyResult.user_id, hwid) then
    return warn("HWID mismatch!")
end

-- Validar licença
local licenseCheck = Security:ValidateLicense(keyResult)
if not licenseCheck.valid then
    return warn("License expired!")
end

-- Verificar updates
local update = Security:CheckForUpdates()
if update then
    print("Update available:", update.version)
end

-- Detectar executor
local executor = Security:DetectExecutor()
print("Running on:", executor)

-- Obter modo do usuário
local userMode = Security:GetUserMode(keyResult)
print("User mode:", userMode)
]]

return SecurityCore
