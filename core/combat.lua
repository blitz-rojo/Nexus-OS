-- ╔══════════════════════════════════════════════════════════╗
-- ║          NEXUS OS v2.0 - COMBAT SYSTEM MODULE           ║
-- ║            Features 56-75: Combat Assist System          ║
-- ╚══════════════════════════════════════════════════════════╝

local CombatSystem = {}
CombatSystem.__index = CombatSystem

-- ============================================
-- SERVICES
-- ============================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera

-- ============================================
-- CONFIGURATION
-- ============================================

local CONFIG = {
    -- Feature Toggles (56-75)
    SilentAim = false,        -- 56
    AimAssist = false,        -- 57
    TriggerBot = false,       -- 58
    FOVCircle = true,         -- 59
    TargetLock = false,       -- 60
    PriorityTarget = false,   -- 61
    Prediction = true,        -- 62
    AutoHeadBody = false,     -- 63
    LegitMode = false,        -- 64
    RageMode = false,         -- 65
    AutoFire = false,         -- 66
    Smoothing = true,         -- 67
    VisibleCheck = true,      -- 68
    IgnoreFriends = true,     -- 69
    KeyActivated = false,     -- 70
    DistanceCheck = true,     -- 71
    AntiDetection = true,     -- 72
    PingBased = false,        -- 73
    MultiHitbox = false,      -- 74
    NPCTarget = false,        -- 75
    
    -- Aim Settings
    FOV = 90,
    Smoothness = 0.1,
    PredictionStrength = 0.135,
    MaxDistance = 1000,
    MinDistance = 10,
    
    -- Target Settings
    TargetPart = "Head",
    AlternativePart = "UpperTorso",
    PriorityRoles = {"Murderer", "Sheriff", "Impostor", "Beast"},
    
    -- Trigger Bot Settings
    TriggerDelay = 0.05,
    TriggerHoldTime = 0.1,
    
    -- Auto Fire Settings
    FireRate = 0.1,
    BurstMode = false,
    BurstCount = 3,
    
    -- Keybinds
    AimKey = Enum.UserInputType.MouseButton2, -- Right click
    LockKey = Enum.KeyCode.Q,
    
    -- Anti-Detection
    Humanized = true,
    RandomOffset = 0.5,
    ShakeAmount = 0.2,
    
    -- Performance
    UpdateRate = 60
}

-- ============================================
-- STATE
-- ============================================

local State = {
    CurrentTarget = nil,
    LockedTarget = nil,
    LastFireTime = 0,
    BurstCounter = 0,
    Connections = {},
    FOVCircle = nil
}

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

-- Get ping compensation
local function GetPing()
    local ping = 0
    pcall(function()
        ping = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()
    end)
    return ping / 1000 -- Convert to seconds
end

-- Check if player is friend
local function IsFriend(player)
    if not CONFIG.IgnoreFriends then return false end
    
    local localPlayer = Players.LocalPlayer
    return localPlayer:IsFriendsWith(player.UserId)
end

-- Check if player is visible
local function IsVisible(targetPart, origin)
    if not CONFIG.VisibleCheck then return true end
    
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    rayParams.FilterDescendantsInstances = {
        Players.LocalPlayer.Character,
        Camera
    }
    
    local direction = (targetPart.Position - origin).Unit * (targetPart.Position - origin).Magnitude
    local ray = Workspace:Raycast(origin, direction, rayParams)
    
    if ray then
        local hitCharacter = ray.Instance:FindFirstAncestorOfClass("Model")
        return hitCharacter == targetPart.Parent
    end
    
    return true
end

-- Check if in FOV
local function IsInFOV(position)
    local screenPos, onScreen = Camera:WorldToViewportPoint(position)
    if not onScreen then return false, 999 end
    
    local centerX = Camera.ViewportSize.X / 2
    local centerY = Camera.ViewportSize.Y / 2
    
    local distanceFromCenter = math.sqrt(
        (screenPos.X - centerX)^2 + 
        (screenPos.Y - centerY)^2
    )
    
    local maxDistance = math.tan(math.rad(CONFIG.FOV / 2)) * Camera.ViewportSize.Y
    
    return distanceFromCenter <= maxDistance, distanceFromCenter
end

-- Get distance between two positions
local function GetDistance(pos1, pos2)
    return (pos1 - pos2).Magnitude
end

-- Check if target is priority
local function IsPriorityTarget(player)
    if not CONFIG.PriorityTarget then return false end
    
    for _, roleName in pairs(CONFIG.PriorityRoles) do
        if player.Name:lower():find(roleName:lower()) then
            return true
        end
        
        local character = player.Character
        if character and character:FindFirstChild("Role") then
            local role = character.Role.Value
            if role:lower():find(roleName:lower()) then
                return true
            end
        end
    end
    
    return false
end

-- Get target part with hitbox expansion
local function GetTargetPart(character)
    local targetPart = character:FindFirstChild(CONFIG.TargetPart)
    
    if not targetPart and CONFIG.MultiHitbox then
        -- Try alternative hitboxes
        local alternatives = {
            CONFIG.AlternativePart,
            "Head",
            "UpperTorso",
            "LowerTorso",
            "HumanoidRootPart"
        }
        
        for _, partName in pairs(alternatives) do
            targetPart = character:FindFirstChild(partName)
            if targetPart then break end
        end
    end
    
    return targetPart
end

-- Calculate prediction
local function PredictPosition(targetPart, velocity)
    if not CONFIG.Prediction then
        return targetPart.Position
    end
    
    local ping = CONFIG.PingBased and GetPing() or 0
    local predictionTime = CONFIG.PredictionStrength + ping
    
    return targetPart.Position + (velocity * predictionTime)
end

-- Add humanization to aim
local function HumanizeAim(targetPosition)
    if not CONFIG.Humanized or CONFIG.RageMode then
        return targetPosition
    end
    
    -- Add small random offset
    local randomX = (math.random() - 0.5) * CONFIG.RandomOffset
    local randomY = (math.random() - 0.5) * CONFIG.RandomOffset
    local randomZ = (math.random() - 0.5) * CONFIG.RandomOffset
    
    return targetPosition + Vector3.new(randomX, randomY, randomZ)
end

-- Add camera shake (anti-detection)
local function AddCameraShake()
    if not CONFIG.AntiDetection or not CONFIG.Humanized then return end
    
    local shake = math.random() * CONFIG.ShakeAmount
    Camera.CFrame = Camera.CFrame * CFrame.Angles(
        math.rad(shake),
        math.rad(shake),
        0
    )
end

-- ============================================
-- FEATURE 59: FOV CIRCLE
-- ============================================

local function CreateFOVCircle()
    if not Drawing then return nil end
    
    local circle = Drawing.new("Circle")
    circle.Visible = CONFIG.FOVCircle
    circle.Color = Color3.fromRGB(255, 255, 255)
    circle.Thickness = 2
    circle.Transparency = 0.5
    circle.NumSides = 64
    circle.Filled = false
    
    return circle
end

local function UpdateFOVCircle()
    if not State.FOVCircle then return end
    
    local centerX = Camera.ViewportSize.X / 2
    local centerY = Camera.ViewportSize.Y / 2
    
    State.FOVCircle.Position = Vector2.new(centerX, centerY)
    State.FOVCircle.Radius = math.tan(math.rad(CONFIG.FOV / 2)) * Camera.ViewportSize.Y
    State.FOVCircle.Visible = CONFIG.FOVCircle
end

-- ============================================
-- FEATURE 60: TARGET ACQUISITION
-- ============================================

local function GetBestTarget()
    local localPlayer = Players.LocalPlayer
    local character = localPlayer.Character
    if not character then return nil end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return nil end
    
    local bestTarget = nil
    local bestScore = math.huge
    
    -- Check locked target first
    if CONFIG.TargetLock and State.LockedTarget then
        local lockedPlayer = State.LockedTarget
        if lockedPlayer.Character and lockedPlayer.Character:FindFirstChild("Humanoid") then
            local humanoid = lockedPlayer.Character.Humanoid
            if humanoid.Health > 0 then
                local targetPart = GetTargetPart(lockedPlayer.Character)
                if targetPart then
                    local inFOV, distance = IsInFOV(targetPart.Position)
                    if inFOV then
                        return lockedPlayer, targetPart
                    end
                end
            end
        end
        
        -- Locked target invalid, clear it
        State.LockedTarget = nil
    end
    
    -- Find best target
    for _, player in pairs(Players:GetPlayers()) do
        if player == localPlayer then continue end
        if IsFriend(player) then continue end
        
        local playerChar = player.Character
        if not playerChar then continue end
        
        local humanoid = playerChar:FindFirstChildOfClass("Humanoid")
        if not humanoid or humanoid.Health <= 0 then continue end
        
        local targetPart = GetTargetPart(playerChar)
        if not targetPart then continue end
        
        -- Distance check
        local distance = GetDistance(rootPart.Position, targetPart.Position)
        if CONFIG.DistanceCheck then
            if distance > CONFIG.MaxDistance or distance < CONFIG.MinDistance then
                continue
            end
        end
        
        -- FOV check
        local inFOV, fovDistance = IsInFOV(targetPart.Position)
        if not inFOV then continue end
        
        -- Visibility check
        if not IsVisible(targetPart, Camera.CFrame.Position) then continue end
        
        -- Calculate score (lower is better)
        local score = fovDistance
        
        -- Prioritize based on role
        if IsPriorityTarget(player) then
            score = score * 0.5 -- Reduce score for priority targets
        end
        
        -- Prefer closer targets in legit mode
        if CONFIG.LegitMode then
            score = score + (distance / 10)
        end
        
        if score < bestScore then
            bestScore = score
            bestTarget = player
        end
    end
    
    if bestTarget then
        local targetPart = GetTargetPart(bestTarget.Character)
        return bestTarget, targetPart
    end
    
    return nil, nil
end

-- ============================================
-- FEATURE 56-57: AIMBOT & AIM ASSIST
-- ============================================

local function AimAt(targetPosition)
    if CONFIG.LegitMode and CONFIG.Smoothing then
        -- Smooth aim
        local currentCFrame = Camera.CFrame
        local targetCFrame = CFrame.new(Camera.CFrame.Position, targetPosition)
        
        local smoothness = CONFIG.RageMode and 1 or CONFIG.Smoothness
        Camera.CFrame = currentCFrame:Lerp(targetCFrame, smoothness)
    else
        -- Instant aim (rage mode or silent aim)
        Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetPosition)
    end
    
    AddCameraShake()
end

local function UpdateAim()
    if not CONFIG.SilentAim and not CONFIG.AimAssist then return end
    
    -- Check if aim key is pressed
    if CONFIG.KeyActivated then
        local aimKeyPressed = false
        
        if CONFIG.AimKey == Enum.UserInputType.MouseButton2 then
            aimKeyPressed = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
        else
            aimKeyPressed = UserInputService:IsKeyDown(CONFIG.AimKey)
        end
        
        if not aimKeyPressed then
            State.CurrentTarget = nil
            return
        end
    end
    
    -- Get target
    local target, targetPart = GetBestTarget()
    if not target or not targetPart then
        State.CurrentTarget = nil
        return
    end
    
    State.CurrentTarget = target
    
    -- Get velocity for prediction
    local velocity = Vector3.zero
    if targetPart.AssemblyLinearVelocity then
        velocity = targetPart.AssemblyLinearVelocity
    end
    
    -- Predict position
    local predictedPosition = PredictPosition(targetPart, velocity)
    
    -- Humanize aim
    local finalPosition = HumanizeAim(predictedPosition)
    
    -- Apply aim
    if CONFIG.SilentAim then
        -- Silent aim (no camera movement, handled by hook)
        -- This would require hooking game functions
        -- For now, we'll use regular aim
        AimAt(finalPosition)
    elseif CONFIG.AimAssist then
        AimAt(finalPosition)
    end
end

-- ============================================
-- FEATURE 58: TRIGGER BOT
-- ============================================

local function UpdateTriggerBot()
    if not CONFIG.TriggerBot then return end
    
    local target, targetPart = GetBestTarget()
    if not target or not targetPart then return end
    
    local mouse = Players.LocalPlayer:GetMouse()
    if not mouse.Target then return end
    
    -- Check if mouse is on target
    local mouseTarget = mouse.Target
    if mouseTarget:IsDescendantOf(target.Character) then
        task.wait(CONFIG.TriggerDelay)
        
        -- Simulate click
        if mouse1click then
            mouse1click()
        elseif mouse1press then
            mouse1press()
            task.wait(CONFIG.TriggerHoldTime)
            mouse1release()
        end
    end
end

-- ============================================
-- FEATURE 66: AUTO FIRE
-- ============================================

local function UpdateAutoFire()
    if not CONFIG.AutoFire then return end
    
    local currentTime = tick()
    if currentTime - State.LastFireTime < CONFIG.FireRate then return end
    
    local target, targetPart = GetBestTarget()
    if not target or not targetPart then return end
    
    -- Burst mode
    if CONFIG.BurstMode then
        if State.BurstCounter < CONFIG.BurstCount then
            if mouse1click then
                mouse1click()
            elseif mouse1press then
                mouse1press()
                task.wait(0.05)
                mouse1release()
            end
            
            State.BurstCounter = State.BurstCounter + 1
            State.LastFireTime = currentTime
        else
            State.BurstCounter = 0
            task.wait(CONFIG.FireRate * 2) -- Delay between bursts
        end
    else
        -- Single fire
        if mouse1click then
            mouse1click()
        elseif mouse1press then
            mouse1press()
            task.wait(0.05)
            mouse1release()
        end
        
        State.LastFireTime = currentTime
    end
end

-- ============================================
-- FEATURE 75: NPC TARGETING
-- ============================================

local function GetNPCTarget()
    if not CONFIG.NPCTarget then return nil end
    
    local bestNPC = nil
    local bestDistance = math.huge
    
    for _, npc in pairs(Workspace:GetDescendants()) do
        if npc:IsA("Model") and npc:FindFirstChild("Humanoid") then
            -- Check if it's not a player
            local isPlayer = Players:GetPlayerFromCharacter(npc)
            if isPlayer then continue end
            
            local humanoid = npc.Humanoid
            if humanoid.Health <= 0 then continue end
            
            local rootPart = npc:FindFirstChild("HumanoidRootPart")
            if not rootPart then continue end
            
            local distance = GetDistance(Camera.CFrame.Position, rootPart.Position)
            if distance < bestDistance then
                bestDistance = distance
                bestNPC = npc
            end
        end
    end
    
    if bestNPC then
        local targetPart = GetTargetPart(bestNPC)
        return bestNPC, targetPart
    end
    
    return nil, nil
end

-- ============================================
-- PUBLIC API
-- ============================================

function CombatSystem:Enable()
    -- Create FOV circle
    State.FOVCircle = CreateFOVCircle()
    
    -- Main update loop
    State.Connections.UpdateLoop = RunService.RenderStepped:Connect(function()
        UpdateFOVCircle()
        UpdateAim()
        UpdateTriggerBot()
        UpdateAutoFire()
        
        if CONFIG.UpdateRate < 60 then
            task.wait(1 / CONFIG.UpdateRate)
        end
    end)
    
    -- Lock key handler
    State.Connections.LockKey = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == CONFIG.LockKey then
            if State.CurrentTarget then
                State.LockedTarget = State.CurrentTarget
                print("🎯 Target locked:", State.LockedTarget.Name)
            else
                State.LockedTarget = nil
                print("🔓 Target unlocked")
            end
        end
    end)
end

function CombatSystem:Disable()
    -- Disconnect all connections
    for _, connection in pairs(State.Connections) do
        if connection then
            connection:Disconnect()
        end
    end
    State.Connections = {}
    
    -- Remove FOV circle
    if State.FOVCircle then
        State.FOVCircle:Remove()
        State.FOVCircle = nil
    end
    
    -- Clear state
    State.CurrentTarget = nil
    State.LockedTarget = nil
end

function CombatSystem:Toggle()
    if next(State.Connections) then
        self:Disable()
    else
        self:Enable()
    end
end

function CombatSystem:SetConfig(key, value)
    if CONFIG[key] ~= nil then
        CONFIG[key] = value
    end
end

function CombatSystem:GetConfig(key)
    return CONFIG[key]
end

function CombatSystem:GetCurrentTarget()
    return State.CurrentTarget
end

function CombatSystem:LockTarget(player)
    State.LockedTarget = player
end

function CombatSystem:UnlockTarget()
    State.LockedTarget = nil
end

-- ============================================
-- INITIALIZATION
-- ============================================

function CombatSystem.new()
    local self = setmetatable({}, CombatSystem)
    return self
end

return CombatSystem