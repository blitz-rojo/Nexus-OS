-- ╔══════════════════════════════════════════════════════════╗
-- ║            NEXUS OS v2.0 - ESP SYSTEM MODULE            ║
-- ║              Features 36-55: Visual ESP System           ║
-- ╚══════════════════════════════════════════════════════════╝

local ESPSystem = {}
ESPSystem.__index = ESPSystem

-- ============================================
-- SERVICES
-- ============================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera

-- ============================================
-- CONFIGURATION
-- ============================================

local CONFIG = {
    -- ESP Settings
    Enabled = false,
    
    -- Feature Toggles (36-55)
    Box = true,              -- 36
    Skeleton = false,        -- 37
    Highlight = true,        -- 38
    TeamCheck = false,       -- 39
    Distance = true,         -- 40
    HealthBar = false,       -- 41
    CustomName = false,      -- 42
    Weapon = false,          -- 43
    ShowInvisible = false,   -- 44
    OffscreenArrow = false,  -- 45
    DynamicColor = true,     -- 46
    PriorityTarget = false,  -- 47
    FOVCheck = false,        -- 48
    Optimized = true,        -- 49
    UseWhitelist = false,    -- 50
    UseBlacklist = false,    -- 51
    TeamESP = false,         -- 52
    ThreatLevel = false,     -- 53
    FadeWithDistance = true, -- 54
    QuickToggle = true,      -- 55
    
    -- Visual Settings
    BoxColor = Color3.fromRGB(255, 0, 0),
    BoxThickness = 2,
    SkeletonColor = Color3.fromRGB(255, 255, 255),
    SkeletonThickness = 1,
    HealthBarColor = Color3.fromRGB(0, 255, 0),
    
    -- Distance Settings
    MaxDistance = 1000,
    MinDistance = 10,
    FadeStart = 500,
    
    -- FOV Settings
    FOV = 90,
    
    -- Lists
    Whitelist = {},
    Blacklist = {},
    PriorityTargets = {"Murderer", "Sheriff", "Impostor", "Beast"},
    
    -- Performance
    UpdateRate = 60, -- FPS
    MaxPlayers = 50
}

-- ============================================
-- ESP INSTANCES
-- ============================================

local ESPInstances = {}
local Connections = {}

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

-- Check if Drawing API is available
local function HasDrawingAPI()
    return Drawing ~= nil and typeof(Drawing) == "table" and Drawing.new ~= nil
end

-- Get player team
local function GetPlayerTeam(player)
    return player.Team
end

-- Check if player is on same team
local function IsSameTeam(player1, player2)
    if not CONFIG.TeamCheck then return false end
    return GetPlayerTeam(player1) == GetPlayerTeam(player2)
end

-- Calculate distance
local function GetDistance(position1, position2)
    return (position1 - position2).Magnitude
end

-- Check if in FOV
local function IsInFOV(position)
    if not CONFIG.FOVCheck then return true end
    
    local screenPos, onScreen = Camera:WorldToViewportPoint(position)
    if not onScreen then return false end
    
    local centerX = Camera.ViewportSize.X / 2
    local centerY = Camera.ViewportSize.Y / 2
    
    local distance = math.sqrt((screenPos.X - centerX)^2 + (screenPos.Y - centerY)^2)
    local maxDistance = math.tan(math.rad(CONFIG.FOV / 2)) * Camera.ViewportSize.Y
    
    return distance <= maxDistance
end

-- Get transparency based on distance
local function GetTransparencyByDistance(distance)
    if not CONFIG.FadeWithDistance then return 1 end
    
    if distance < CONFIG.FadeStart then
        return 1
    else
        local fadeRange = CONFIG.MaxDistance - CONFIG.FadeStart
        local fadeAmount = (distance - CONFIG.FadeStart) / fadeRange
        return 1 - math.clamp(fadeAmount, 0, 0.7)
    end
end

-- Get color by threat level
local function GetThreatColor(player)
    if not CONFIG.ThreatLevel then
        return CONFIG.BoxColor
    end
    
    -- Check if player is priority target
    local character = player.Character
    if character then
        for _, targetName in pairs(CONFIG.PriorityTargets) do
            if player.Name:lower():find(targetName:lower()) or
               (character:FindFirstChild("Role") and 
                character.Role.Value:lower():find(targetName:lower())) then
                return Color3.fromRGB(255, 0, 0) -- Red for threats
            end
        end
    end
    
    return Color3.fromRGB(0, 255, 0) -- Green for safe
end

-- Get dynamic color based on state
local function GetDynamicColor(player, distance)
    if CONFIG.DynamicColor then
        if CONFIG.ThreatLevel then
            return GetThreatColor(player)
        end
        
        -- Color by distance
        if distance < 50 then
            return Color3.fromRGB(255, 0, 0) -- Close: Red
        elseif distance < 200 then
            return Color3.fromRGB(255, 165, 0) -- Medium: Orange
        else
            return Color3.fromRGB(0, 255, 0) -- Far: Green
        end
    end
    
    return CONFIG.BoxColor
end

-- Check lists
local function IsWhitelisted(player)
    return CONFIG.Whitelist[tostring(player.UserId)] ~= nil
end

local function IsBlacklisted(player)
    return CONFIG.Blacklist[tostring(player.UserId)] ~= nil
end

local function ShouldShowPlayer(player)
    if CONFIG.UseWhitelist and not IsWhitelisted(player) then
        return false
    end
    
    if CONFIG.UseBlacklist and IsBlacklisted(player) then
        return false
    end
    
    return true
end

-- ============================================
-- FEATURE 36: ESP BOX
-- ============================================

local function CreateBox()
    if not HasDrawingAPI() then return nil end
    
    local box = {
        TopLeft = Drawing.new("Line"),
        TopRight = Drawing.new("Line"),
        BottomLeft = Drawing.new("Line"),
        BottomRight = Drawing.new("Line"),
        LeftSide = Drawing.new("Line"),
        RightSide = Drawing.new("Line"),
        TopSide = Drawing.new("Line"),
        BottomSide = Drawing.new("Line")
    }
    
    for _, line in pairs(box) do
        line.Visible = false
        line.Color = CONFIG.BoxColor
        line.Thickness = CONFIG.BoxThickness
        line.Transparency = 1
    end
    
    return box
end

local function UpdateBox(box, corners, color, transparency)
    if not box or not corners then return end
    
    -- Top Left
    box.TopLeft.From = corners.TopLeft
    box.TopLeft.To = corners.TopRight
    box.TopLeft.Color = color
    box.TopLeft.Transparency = transparency
    box.TopLeft.Visible = true
    
    -- Top Right
    box.TopRight.From = corners.TopRight
    box.TopRight.To = corners.BottomRight
    box.TopRight.Color = color
    box.TopRight.Transparency = transparency
    box.TopRight.Visible = true
    
    -- Bottom Right
    box.BottomRight.From = corners.BottomRight
    box.BottomRight.To = corners.BottomLeft
    box.BottomRight.Color = color
    box.BottomRight.Transparency = transparency
    box.BottomRight.Visible = true
    
    -- Bottom Left
    box.BottomLeft.From = corners.BottomLeft
    box.BottomLeft.To = corners.TopLeft
    box.BottomLeft.Color = color
    box.BottomLeft.Transparency = transparency
    box.BottomLeft.Visible = true
end

local function HideBox(box)
    if not box then return end
    for _, line in pairs(box) do
        line.Visible = false
    end
end

-- ============================================
-- FEATURE 37: ESP SKELETON
-- ============================================

local function CreateSkeleton()
    if not HasDrawingAPI() then return nil end
    
    local skeleton = {}
    local bones = {
        "Head-UpperTorso",
        "UpperTorso-LeftUpperArm",
        "LeftUpperArm-LeftLowerArm",
        "LeftLowerArm-LeftHand",
        "UpperTorso-RightUpperArm",
        "RightUpperArm-RightLowerArm",
        "RightLowerArm-RightHand",
        "UpperTorso-LowerTorso",
        "LowerTorso-LeftUpperLeg",
        "LeftUpperLeg-LeftLowerLeg",
        "LeftLowerLeg-LeftFoot",
        "LowerTorso-RightUpperLeg",
        "RightUpperLeg-RightLowerLeg",
        "RightLowerLeg-RightFoot"
    }
    
    for _, boneName in pairs(bones) do
        local line = Drawing.new("Line")
        line.Visible = false
        line.Color = CONFIG.SkeletonColor
        line.Thickness = CONFIG.SkeletonThickness
        line.Transparency = 1
        skeleton[boneName] = line
    end
    
    return skeleton
end

local function UpdateSkeleton(skeleton, character, color, transparency)
    if not skeleton or not character then return end
    
    for boneName, line in pairs(skeleton) do
        local parts = string.split(boneName, "-")
        local part1 = character:FindFirstChild(parts[1])
        local part2 = character:FindFirstChild(parts[2])
        
        if part1 and part2 then
            local pos1, onScreen1 = Camera:WorldToViewportPoint(part1.Position)
            local pos2, onScreen2 = Camera:WorldToViewportPoint(part2.Position)
            
            if onScreen1 and onScreen2 then
                line.From = Vector2.new(pos1.X, pos1.Y)
                line.To = Vector2.new(pos2.X, pos2.Y)
                line.Color = color
                line.Transparency = transparency
                line.Visible = true
            else
                line.Visible = false
            end
        else
            line.Visible = false
        end
    end
end

local function HideSkeleton(skeleton)
    if not skeleton then return end
    for _, line in pairs(skeleton) do
        line.Visible = false
    end
end

-- ============================================
-- FEATURE 38: ESP HIGHLIGHT (Fallback)
-- ============================================

local function CreateHighlight(character)
    local highlight = Instance.new("Highlight")
    highlight.Name = "NexusESP_Highlight"
    highlight.FillColor = CONFIG.BoxColor
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = character
    
    return highlight
end

-- ============================================
-- FEATURE 40: ESP DISTANCE
-- ============================================

local function CreateDistanceLabel()
    if not HasDrawingAPI() then return nil end
    
    local text = Drawing.new("Text")
    text.Visible = false
    text.Color = Color3.fromRGB(255, 255, 255)
    text.Size = 14
    text.Center = true
    text.Outline = true
    text.Font = Drawing.Fonts.UI
    
    return text
end

local function UpdateDistanceLabel(text, position, distance, transparency)
    if not text then return end
    
    local screenPos, onScreen = Camera:WorldToViewportPoint(position)
    
    if onScreen then
        text.Position = Vector2.new(screenPos.X, screenPos.Y - 20)
        text.Text = string.format("%.0f studs", distance)
        text.Transparency = transparency
        text.Visible = true
    else
        text.Visible = false
    end
end

-- ============================================
-- FEATURE 41: ESP HEALTH BAR
-- ============================================

local function CreateHealthBar()
    if not HasDrawingAPI() then return nil end
    
    local healthBar = {
        Background = Drawing.new("Square"),
        Foreground = Drawing.new("Square")
    }
    
    healthBar.Background.Visible = false
    healthBar.Background.Color = Color3.fromRGB(0, 0, 0)
    healthBar.Background.Thickness = 1
    healthBar.Background.Filled = true
    
    healthBar.Foreground.Visible = false
    healthBar.Foreground.Color = CONFIG.HealthBarColor
    healthBar.Foreground.Thickness = 1
    healthBar.Foreground.Filled = true
    
    return healthBar
end

local function UpdateHealthBar(healthBar, position, health, maxHealth, transparency)
    if not healthBar then return end
    
    local screenPos, onScreen = Camera:WorldToViewportPoint(position)
    
    if onScreen then
        local barWidth = 50
        local barHeight = 6
        local healthPercentage = health / maxHealth
        
        -- Background
        healthBar.Background.Size = Vector2.new(barWidth, barHeight)
        healthBar.Background.Position = Vector2.new(screenPos.X - barWidth/2, screenPos.Y + 25)
        healthBar.Background.Transparency = transparency * 0.5
        healthBar.Background.Visible = true
        
        -- Foreground
        healthBar.Foreground.Size = Vector2.new(barWidth * healthPercentage, barHeight)
        healthBar.Foreground.Position = Vector2.new(screenPos.X - barWidth/2, screenPos.Y + 25)
        healthBar.Foreground.Transparency = transparency
        healthBar.Foreground.Visible = true
        
        -- Color based on health
        if healthPercentage > 0.5 then
            healthBar.Foreground.Color = Color3.fromRGB(0, 255, 0)
        elseif healthPercentage > 0.25 then
            healthBar.Foreground.Color = Color3.fromRGB(255, 165, 0)
        else
            healthBar.Foreground.Color = Color3.fromRGB(255, 0, 0)
        end
    else
        healthBar.Background.Visible = false
        healthBar.Foreground.Visible = false
    end
end

-- ============================================
-- FEATURE 42: ESP CUSTOM NAME
-- ============================================

local function CreateNameLabel()
    if not HasDrawingAPI() then return nil end
    
    local text = Drawing.new("Text")
    text.Visible = false
    text.Color = Color3.fromRGB(255, 255, 255)
    text.Size = 16
    text.Center = true
    text.Outline = true
    text.Font = Drawing.Fonts.UI
    
    return text
end

local function UpdateNameLabel(text, position, name, transparency)
    if not text then return end
    
    local screenPos, onScreen = Camera:WorldToViewportPoint(position)
    
    if onScreen then
        text.Position = Vector2.new(screenPos.X, screenPos.Y - 35)
        text.Text = name
        text.Transparency = transparency
        text.Visible = true
    else
        text.Visible = false
    end
end

-- ============================================
-- FEATURE 45: OFFSCREEN ARROW
-- ============================================

local function CreateOffscreenArrow()
    if not HasDrawingAPI() then return nil end
    
    local arrow = Drawing.new("Triangle")
    arrow.Visible = false
    arrow.Color = Color3.fromRGB(255, 0, 0)
    arrow.Filled = true
    arrow.Thickness = 1
    
    return arrow
end

local function UpdateOffscreenArrow(arrow, position, color, transparency)
    if not arrow then return end
    
    local screenPos, onScreen = Camera:WorldToViewportPoint(position)
    
    if not onScreen then
        local screenCenter = Camera.ViewportSize / 2
        local direction = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Unit
        
        local arrowPos = screenCenter + (direction * 100)
        local angle = math.atan2(direction.Y, direction.X)
        
        local size = 15
        arrow.PointA = Vector2.new(
            arrowPos.X + math.cos(angle) * size,
            arrowPos.Y + math.sin(angle) * size
        )
        arrow.PointB = Vector2.new(
            arrowPos.X + math.cos(angle + 2.5) * size,
            arrowPos.Y + math.sin(angle + 2.5) * size
        )
        arrow.PointC = Vector2.new(
            arrowPos.X + math.cos(angle - 2.5) * size,
            arrowPos.Y + math.sin(angle - 2.5) * size
        )
        
        arrow.Color = color
        arrow.Transparency = transparency
        arrow.Visible = true
    else
        arrow.Visible = false
    end
end

-- ============================================
-- MAIN ESP SYSTEM
-- ============================================

local function Get2DBox(character)
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    
    -- Calculate bounding box
    local cf = hrp.CFrame
    local size = character:GetExtentsSize()
    
    local corners = {
        TopLeft = cf * CFrame.new(-size.X/2, size.Y/2, 0),
        TopRight = cf * CFrame.new(size.X/2, size.Y/2, 0),
        BottomLeft = cf * CFrame.new(-size.X/2, -size.Y/2, 0),
        BottomRight = cf * CFrame.new(size.X/2, -size.Y/2, 0)
    }
    
    local screenCorners = {}
    local allOnScreen = true
    
    for name, corner in pairs(corners) do
        local screenPos, onScreen = Camera:WorldToViewportPoint(corner.Position)
        screenCorners[name] = Vector2.new(screenPos.X, screenPos.Y)
        if not onScreen then
            allOnScreen = false
        end
    end
    
    return screenCorners, allOnScreen
end

local function CreateESPForPlayer(player)
    if player == Players.LocalPlayer then return end
    if ESPInstances[player] then return end
    
    local esp = {
        Player = player,
        Box = CONFIG.Box and CreateBox() or nil,
        Skeleton = CONFIG.Skeleton and CreateSkeleton() or nil,
        Highlight = nil, -- Criado quando character spawn
        Distance = CONFIG.Distance and CreateDistanceLabel() or nil,
        HealthBar = CONFIG.HealthBar and CreateHealthBar() or nil,
        Name = CONFIG.CustomName and CreateNameLabel() or nil,
        OffscreenArrow = CONFIG.OffscreenArrow and CreateOffscreenArrow() or nil
    }
    
    ESPInstances[player] = esp
    
    -- Handle character spawn
    local function OnCharacterAdded(character)
        task.wait(0.1)
        
        if CONFIG.Highlight and not HasDrawingAPI() then
            esp.Highlight = CreateHighlight(character)
        end
    end
    
    if player.Character then
        OnCharacterAdded(player.Character)
    end
    
    player.CharacterAdded:Connect(OnCharacterAdded)
end

local function RemoveESP(player)
    local esp = ESPInstances[player]
    if not esp then return end
    
    -- Clean up Drawing objects
    if esp.Box then HideBox(esp.Box) end
    if esp.Skeleton then HideSkeleton(esp.Skeleton) end
    if esp.Distance then esp.Distance.Visible = false end
    if esp.HealthBar then
        esp.HealthBar.Background.Visible = false
        esp.HealthBar.Foreground.Visible = false
    end
    if esp.Name then esp.Name.Visible = false end
    if esp.OffscreenArrow then esp.OffscreenArrow.Visible = false end
    
    -- Clean up Instance objects
    if esp.Highlight and esp.Highlight.Parent then
        esp.Highlight:Destroy()
    end
    
    ESPInstances[player] = nil
end

local function UpdateESP()
    if not CONFIG.Enabled then return end
    
    local localPlayer = Players.LocalPlayer
    
    for player, esp in pairs(ESPInstances) do
        if not player or not player.Parent then
            RemoveESP(player)
            continue
        end
        
        -- Check if should show this player
        if not ShouldShowPlayer(player) then
            if esp.Box then HideBox(esp.Box) end
            if esp.Skeleton then HideSkeleton(esp.Skeleton) end
            if esp.Distance then esp.Distance.Visible = false end
            if esp.HealthBar then
                esp.HealthBar.Background.Visible = false
                esp.HealthBar.Foreground.Visible = false
            end
            if esp.Name then esp.Name.Visible = false end
            if esp.OffscreenArrow then esp.OffscreenArrow.Visible = false end
            continue
        end
        
        -- Check team
        if IsSameTeam(localPlayer, player) then
            if esp.Box then HideBox(esp.Box) end
            if esp.Skeleton then HideSkeleton(esp.Skeleton) end
            if esp.Distance then esp.Distance.Visible = false end
            if esp.HealthBar then
                esp.HealthBar.Background.Visible = false
                esp.HealthBar.Foreground.Visible = false
            end
            if esp.Name then esp.Name.Visible = false end
            if esp.OffscreenArrow then esp.OffscreenArrow.Visible = false end
            continue
        end
        
        local character = player.Character
        if not character then continue end
        
        local hrp = character:FindFirstChild("HumanoidRootPart")
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        
        if not hrp or not humanoid or humanoid.Health <= 0 then continue end
        
        -- Calculate distance
        local localHRP = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not localHRP then continue end
        
        local distance = GetDistance(localHRP.Position, hrp.Position)
        
        -- Check distance limits
        if distance > CONFIG.MaxDistance or distance < CONFIG.MinDistance then
            if esp.Box then HideBox(esp.Box) end
            if esp.Skeleton then HideSkeleton(esp.Skeleton) end
            if esp.Distance then esp.Distance.Visible = false end
            if esp.HealthBar then
                esp.HealthBar.Background.Visible = false
                esp.HealthBar.Foreground.Visible = false
            end
            if esp.Name then esp.Name.Visible = false end
            if esp.OffscreenArrow then esp.OffscreenArrow.Visible = false end
            continue
        end
        
        -- Check FOV
        if not IsInFOV(hrp.Position) then
            if esp.Box then HideBox(esp.Box) end
            if esp.Skeleton then HideSkeleton(esp.Skeleton) end
            if esp.Distance then esp.Distance.Visible = false end
            if esp.HealthBar then
                esp.HealthBar.Background.Visible = false
                esp.HealthBar.Foreground.Visible = false
            end
            if esp.Name then esp.Name.Visible = false end
            
            -- Show offscreen arrow
            if esp.OffscreenArrow then
                local color = GetDynamicColor(player, distance)
                local transparency = GetTransparencyByDistance(distance)
                UpdateOffscreenArrow(esp.OffscreenArrow, hrp.Position, color, transparency)
            end
            
            continue
        end
        
        -- Get color and transparency
        local color = GetDynamicColor(player, distance)
        local transparency = GetTransparencyByDistance(distance)
        
        -- Update Box
        if esp.Box and CONFIG.Box then
            local corners, onScreen = Get2DBox(character)
            if corners and onScreen then
                UpdateBox(esp.Box, corners, color, transparency)
            else
                HideBox(esp.Box)
            end
        end
        
        -- Update Skeleton
        if esp.Skeleton and CONFIG.Skeleton then
            UpdateSkeleton(esp.Skeleton, character, color, transparency)
        end
        
        -- Update Distance
        if esp.Distance and CONFIG.Distance then
            UpdateDistanceLabel(esp.Distance, hrp.Position, distance, transparency)
        end
        
        -- Update Health Bar
        if esp.HealthBar and CONFIG.HealthBar then
            UpdateHealthBar(esp.HealthBar, hrp.Position, humanoid.Health, humanoid.MaxHealth, transparency)
        end
        
        -- Update Name
        if esp.Name and CONFIG.CustomName then
            UpdateNameLabel(esp.Name, hrp.Position, player.Name, transparency)
        end
        
        -- Hide offscreen arrow when on screen
        if esp.OffscreenArrow then
            esp.OffscreenArrow.Visible = false
        end
    end
end

-- ============================================
-- PUBLIC API
-- ============================================

function ESPSystem:Enable()
    CONFIG.Enabled = true
    
    -- Create ESP for existing players
    for _, player in pairs(Players:GetPlayers()) do
        CreateESPForPlayer(player)
    end
    
    -- Handle new players
    Connections.PlayerAdded = Players.PlayerAdded:Connect(function(player)
        task.wait(1)
        CreateESPForPlayer(player)
    end)
    
    -- Handle player removal
    Connections.PlayerRemoving = Players.PlayerRemoving:Connect(function(player)
        RemoveESP(player)
    end)
    
    -- Main update loop
    Connections.UpdateLoop = RunService.RenderStepped:Connect(function()
        if CONFIG.Optimized then
            -- Update at configured rate
            task.wait(1 / CONFIG.UpdateRate)
        end
        UpdateESP()
    end)
end

function ESPSystem:Disable()
    CONFIG.Enabled = false
    
    -- Remove all ESP
    for player, _ in pairs(ESPInstances) do
        RemoveESP(player)
    end
    
    -- Disconnect connections
    for _, connection in pairs(Connections) do
        if connection then
            connection:Disconnect()
        end
    end
    Connections = {}
end

function ESPSystem:Toggle()
    if CONFIG.Enabled then
        self:Disable()
    else
        self:Enable()
    end
end

function ESPSystem:SetConfig(key, value)
    if CONFIG[key] ~= nil then
        CONFIG[key] = value
    end
end

function ESPSystem:GetConfig(key)
    return CONFIG[key]
end

function ESPSystem:AddToWhitelist(userId)
    CONFIG.Whitelist[tostring(userId)] = true
end

function ESPSystem:RemoveFromWhitelist(userId)
    CONFIG.Whitelist[tostring(userId)] = nil
end

function ESPSystem:AddToBlacklist(userId)
    CONFIG.Blacklist[tostring(userId)] = true
end

function ESPSystem:RemoveFromBlacklist(userId)
    CONFIG.Blacklist[tostring(userId)] = nil
end

-- ============================================
-- INITIALIZATION
-- ============================================

function ESPSystem.new()
    local self = setmetatable({}, ESPSystem)
    return self
end

return ESPSystem