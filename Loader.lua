-- NEXUS OS LOADER v1.0
-- Universal Loader for GitHub-hosted script

local REPO_URL = "https://raw.githubusercontent.com/SEU_USUARIO_AQUI/Nexus-OS/main/NexusOS.lua"

-- Function to safely load the script
local function LoadNexusOS()
    local success, result = pcall(function()
        return game:HttpGet(REPO_URL)
    end)
    
    if not success then
        warn("❌ Failed to fetch Nexus OS from GitHub")
        warn("Error:", result)
        return false
    end
    
    -- Execute the script
    local loadSuccess, loadError = pcall(function()
        loadstring(result)()
    end)
    
    if not loadSuccess then
        warn("❌ Failed to execute Nexus OS")
        warn("Error:", loadError)
        return false
    end
    
    print("✅ Nexus OS loaded successfully!")
    return true
end

-- Show loading message
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("🌟 NEXUS OS LOADER")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("⏳ Fetching latest version...")

-- Load the script
if LoadNexusOS() then
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
else
    warn("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    warn("⚠️ Check your internet connection")
    warn("⚠️ Or contact support")
end
