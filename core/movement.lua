-- ╔══════════════════════════════════════════════════════════╗
-- ║         NEXUS OS v2.0 - MOVEMENT SYSTEM MODULE          ║
-- ║           Features 76-95: Movement & Physics             ║
-- ╚══════════════════════════════════════════════════════════╝

local MovementSystem = {}
MovementSystem.__index = MovementSystem

-- ============================================
-- SERVICES
-- ============================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

-- ============================================
-- CONFIGURATION
-- ============================================

local CONFIG = {
    -- Feature Toggles (76-95)
    SpeedHack = false,          -- 76
    JumpPower = false,          -- 77
    FlyMode = false,            -- 78
    FlyCollision = false,       -- 79
    Noclip = false,             -- 80
    SafeTeleport = false,       -- 81
    Dash = false,               -- 82
    BunnyHop = false,           -- 83
    ShiftLock = false,          -- 84
    CameraLock = false,         -- 85
    AntiFallDamage = false,     -- 86
    WallClimb = false,          -- 87
    WallWalk = false,           -- 88
    GravityControl = false,     -- 89
    AirControl = false,         -- 90
    AutoSprint = false,         -- 91
    AutoDodge = false,          -- 92
    HumanizedMovement = false,  -- 93
    FreezePosition = false,     -- 94
    Rollback = false,           -- 95
    
    -- Movement Values
    WalkSpeed = 16,
    JumpHeight = 50,
    FlySpeed = 50,
    DashPower = 100,
    Gravity = 196.2,
    
    -- Advanced Settings
    Smoothness = 0.1,
    SafeTeleportDelay = 0.5,
    MaxTeleportDistance = 500,
    RollbackHistory = 10,
    
    -- Keybinds
    FlyKey = Enum.KeyCode.Space,
    DashKey = Enum.KeyCode.LeftShift,
    NoclipKey = Enum.KeyCode.N,
    FreezeKey = Enum.KeyCode.F,
    RollbackKey = Enum.KeyCode.R
}

-- ============================================
-- STATE
-- ============================================

local State = {
    Connections = {},
    BodyVelocity = nil,
    BodyGyro = nil,
    OriginalGravity = Workspace.Gravity,
    PositionHistory = {},
    FrozenPosition = nil,
    LastDashTime = 0,
    WallStickEnabled = false
}

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

local function GetCharacter()
    return Players.LocalPlayer.Character
end

local function GetHumanoid()
    local character = GetCharacter()
    return character and character:FindFirstChildOfClass("Humanoid")
end

local function GetRootPart()
    local character = GetCharacter()
    return character and character:FindFirstChild("HumanoidRootPart")
end

local function SavePosition()
    local rootPart = GetRootPart()
    if not rootPart then return end
    
    table.insert(State.PositionHistory, 1, {
        Position = rootPart.Position,
        CFrame = rootPart.CFrame,
        Time = tick()
    })
    
    -- Keep only last N positions
    if #State.PositionHistory > CONFIG.RollbackHistory then
        table.remove(State.PositionHistory)
    end
end

local function IsGrounded()
    local humanoid = GetHumanoid()
    if not humanoid then return false end
    
    return humanoid.FloorMaterial ~= Enum.Material.Air
end

local function GetMovementDirection()
    local direction = Vector3.zero
    
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then
        direction = direction + Vector3.new(0, 0, -1)
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then
        direction = direction + Vector3.new(0, 0, 1)
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then
        direction = direction + Vector3.new(-1, 0, 0)
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then
        direction = direction + Vector3.new(1, 0, 0)
    end
    
    return direction
end

-- ============================================
-- FEATURE 76: SPEED HACK
-- ============================================

function MovementSystem:EnableSpeed()
    CONFIG.SpeedHack = true
    
    State.Connections.Speed = RunService.Heartbeat:Connect(function()
        if not CONFIG.SpeedHack then return end
        
        local humanoid = GetHumanoid()
        if humanoid then
            if CONFIG.HumanizedMovement then
                -- Smooth speed change
                local target = CONFIG.WalkSpeed
                local current = humanoid.WalkSpeed
                humanoid.WalkSpeed = current + (target - current) * CONFIG.Smoothness
            else
                humanoid.WalkSpeed = CONFIG.WalkSpeed
            end
        end
    end)
end

-- ============================================
-- FEATURE 77: JUMP POWER
-- ============================================

function MovementSystem:EnableJumpPower()
    CONFIG.JumpPower = true
    
    State.Connections.Jump = RunService.Heartbeat:Connect(function()
        if not CONFIG.JumpPower then return end
        
        local humanoid = GetHumanoid()
        if humanoid then
            humanoid.JumpPower = CONFIG.JumpHeight
        end
    end)
end

-- ============================================
-- FEATURE 78-79: FLY MODE
-- ============================================

function MovementSystem:EnableFly()
    CONFIG.FlyMode = true
    
    local rootPart = GetRootPart()
    if not rootPart then return end
    
    -- Create BodyVelocity
    if not State.BodyVelocity then
        State.BodyVelocity = Instance.new("BodyVelocity")
        State.BodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        State.BodyVelocity.Velocity = Vector3.zero
        State.BodyVelocity.Parent = rootPart
    end
    
    -- Create BodyGyro for stability
    if not State.BodyGyro then
        State.BodyGyro = Instance.new("BodyGyro")
        State.BodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        State.BodyGyro.P = 9000
        State.BodyGyro.D = 500
        State.BodyGyro.Parent = rootPart
    end
    
    State.Connections.Fly = RunService.Heartbeat:Connect(function()
        if not CONFIG.FlyMode then return end
        
        rootPart = GetRootPart()
        if not rootPart then return end
        
        local camera = Workspace.CurrentCamera
        if not camera then return end
        
        -- Calculate direction
        local direction = GetMovementDirection()
        
        -- Add vertical movement
        if UserInputService:IsKeyDown(CONFIG.FlyKey) then
            direction = direction + Vector3.new(0, 1, 0)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
            direction = direction + Vector3.new(0, -1, 0)
        end
        
        -- Apply camera rotation
        local cameraCFrame = camera.CFrame
        direction = (cameraCFrame.LookVector * direction.Z) + 
                   (cameraCFrame.RightVector * direction.X) + 
                   (Vector3.new(0, 1, 0) * direction.Y)
        
        -- Update velocity
        if direction.Magnitude > 0 then
            State.BodyVelocity.Velocity = direction.Unit * CONFIG.FlySpeed
        else
            State.BodyVelocity.Velocity = Vector3.zero
        end
        
        -- Update gyro
        State.BodyGyro.CFrame = cameraCFrame
        
        -- Handle collision
        if not CONFIG.FlyCollision then
            -- Noclip while flying
            local character = GetCharacter()
            if character then
                for _, part in pairs(character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end
    end)
end

function MovementSystem:DisableFly()
    CONFIG.FlyMode = false
    
    if State.BodyVelocity then
        State.BodyVelocity:Destroy()
        State.BodyVelocity = nil
    end
    
    if State.BodyGyro then
        State.BodyGyro:Destroy()
        State.BodyGyro = nil
    end
    
    -- Restore collision
    local character = GetCharacter()
    if character then
        for _, part in pairs(character:GetDescendants()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                part.CanCollide = true
            end
        end
    end
end

-- ============================================
-- FEATURE 80: NOCLIP
-- ============================================

function MovementSystem:EnableNoclip()
    CONFIG.Noclip = true
    
    State.Connections.Noclip = RunService.Stepped:Connect(function()
        if not CONFIG.Noclip then return end
        
        local character = GetCharacter()
        if not character then return end
        
        for _, part in pairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end)
end

function MovementSystem:DisableNoclip()
    CONFIG.Noclip = false
    
    local character = GetCharacter()
    if character then
        for _, part in pairs(character:GetDescendants()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                part.CanCollide = true
            end
        end
    end
end

-- ============================================
-- FEATURE 81: SAFE TELEPORT
-- ============================================

function MovementSystem:SafeTeleport(targetPosition)
    if not CONFIG.SafeTeleport then
        -- Instant teleport
        local rootPart = GetRootPart()
        if rootPart then
            rootPart.CFrame = CFrame.new(targetPosition)
        end
        return
    end
    
    local rootPart = GetRootPart()
    if not rootPart then return end
    
    local startPosition = rootPart.Position
    local distance = (targetPosition - startPosition).Magnitude
    
    -- Check max distance
    if distance > CONFIG.MaxTeleportDistance then
        warn("⚠️ Teleport distance too large!")
        return
    end
    
    -- Smooth teleport
    local steps = math.floor(distance / 10)
    for i = 1, steps do
        local alpha = i / steps
        local intermediatePos = startPosition:Lerp(targetPosition, alpha)
        rootPart.CFrame = CFrame.new(intermediatePos)
        task.wait(CONFIG.SafeTeleportDelay / steps)
    end
end

-- ============================================
-- FEATURE 82: DASH
-- ============================================

function MovementSystem:EnableDash()
    CONFIG.Dash = true
    
    State.Connections.Dash = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if not CONFIG.Dash then return end
        
        if input.KeyCode == CONFIG.DashKey then
            local currentTime = tick()
            if currentTime - State.LastDashTime < 1 then return end
            
            local rootPart = GetRootPart()
            if not rootPart then return end
            
            local camera = Workspace.CurrentCamera
            local direction = GetMovementDirection()
            
            if direction.Magnitude > 0 then
                local cameraCFrame = camera.CFrame
                local dashDirection = (cameraCFrame.LookVector * direction.Z) + 
                                    (cameraCFrame.RightVector * direction.X)
                
                -- Apply dash impulse
                local dashVelocity = Instance.new("BodyVelocity")
                dashVelocity.MaxForce = Vector3.new(9e9, 0, 9e9)
                dashVelocity.Velocity = dashDirection.Unit * CONFIG.DashPower
                dashVelocity.Parent = rootPart
                
                task.delay(0.2, function()
                    dashVelocity:Destroy()
                end)
                
                State.LastDashTime = currentTime
            end
        end
    end)
end

-- ============================================
-- FEATURE 83: BUNNY HOP
-- ============================================

function MovementSystem:EnableBunnyHop()
    CONFIG.BunnyHop = true
    
    State.Connections.BunnyHop = RunService.Heartbeat:Connect(function()
        if not CONFIG.BunnyHop then return end
        
        local humanoid = GetHumanoid()
        if not humanoid then return end
        
        if IsGrounded() then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            task.wait(0.1)
        end
    end)
end

-- ============================================
-- FEATURE 86: ANTI-FALL DAMAGE
-- ============================================

function MovementSystem:EnableAntiFallDamage()
    CONFIG.AntiFallDamage = true
    
    State.Connections.AntiFall = RunService.Heartbeat:Connect(function()
        if not CONFIG.AntiFallDamage then return end
        
        local humanoid = GetHumanoid()
        if humanoid then
            local state = humanoid:GetState()
            if state == Enum.HumanoidStateType.Freefall then
                humanoid:ChangeState(Enum.HumanoidStateType.Flying)
            end
        end
    end)
end

-- ============================================
-- FEATURE 87-88: WALL CLIMB & WALL WALK
-- ============================================

function MovementSystem:EnableWallClimb()
    CONFIG.WallClimb = true
    
    State.Connections.WallClimb = RunService.Heartbeat:Connect(function()
        if not CONFIG.WallClimb then return end
        
        local rootPart = GetRootPart()
        local humanoid = GetHumanoid()
        if not rootPart or not humanoid then return end
        
        -- Check if against wall
        local direction = GetMovementDirection()
        if direction.Z == -1 then -- Moving forward
            local camera = Workspace.CurrentCamera
            local forwardDirection = camera.CFrame.LookVector
            
            local rayParams = RaycastParams.new()
            rayParams.FilterType = Enum.RaycastFilterType.Blacklist
            rayParams.FilterDescendantsInstances = {GetCharacter()}
            
            local ray = Workspace:Raycast(
                rootPart.Position,
                forwardDirection * 3,
                rayParams
            )
            
            if ray then
                -- Climbing
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                    rootPart.Velocity = Vector3.new(
                        rootPart.Velocity.X,
                        CONFIG.WalkSpeed,
                        rootPart.Velocity.Z
                    )
                end
                
                -- Wall walk
                if CONFIG.WallWalk then
                    State.WallStickEnabled = true
                    rootPart.CFrame = rootPart.CFrame * CFrame.new(0, 0, -0.1)
                end
            else
                State.WallStickEnabled = false
            end
        end
    end)
end

-- ============================================
-- FEATURE 89: GRAVITY CONTROL
-- ============================================

function MovementSystem:SetGravity(multiplier)
    CONFIG.GravityControl = true
    Workspace.Gravity = State.OriginalGravity * multiplier
end

function MovementSystem:ResetGravity()
    CONFIG.GravityControl = false
    Workspace.Gravity = State.OriginalGravity
end

-- ============================================
-- FEATURE 90: AIR CONTROL
-- ============================================

function MovementSystem:EnableAirControl()
    CONFIG.AirControl = true
    
    State.Connections.AirControl = RunService.Heartbeat:Connect(function()
        if not CONFIG.AirControl then return end
        
        local humanoid = GetHumanoid()
        local rootPart = GetRootPart()
        if not humanoid or not rootPart then return end
        
        if not IsGrounded() then
            local direction = GetMovementDirection()
            if direction.Magnitude > 0 then
                local camera = Workspace.CurrentCamera
                local moveDirection = (camera.CFrame.LookVector * direction.Z) + 
                                    (camera.CFrame.RightVector * direction.X)
                
                rootPart.Velocity = Vector3.new(
                    moveDirection.X * CONFIG.WalkSpeed * 0.5,
                    rootPart.Velocity.Y,
                    moveDirection.Z * CONFIG.WalkSpeed * 0.5
                )
            end
        end
    end)
end

-- ============================================
-- FEATURE 91: AUTO SPRINT
-- ============================================

function MovementSystem:EnableAutoSprint()
    CONFIG.AutoSprint = true
    CONFIG.WalkSpeed = 24 -- Sprint speed
    self:EnableSpeed()
end

-- ============================================
-- FEATURE 94: FREEZE POSITION
-- ============================================

function MovementSystem:FreezePosition()
    local rootPart = GetRootPart()
    if not rootPart then return end
    
    CONFIG.FreezePosition = true
    State.FrozenPosition = rootPart.CFrame
    
    State.Connections.Freeze = RunService.Heartbeat:Connect(function()
        if not CONFIG.FreezePosition then return end
        
        rootPart = GetRootPart()
        if rootPart and State.FrozenPosition then
            rootPart.CFrame = State.FrozenPosition
            rootPart.Velocity = Vector3.zero
        end
    end)
end

function MovementSystem:UnfreezePosition()
    CONFIG.FreezePosition = false
    State.FrozenPosition = nil
end

-- ============================================
-- FEATURE 95: ROLLBACK POSITION
-- ============================================

function MovementSystem:Rollback(steps)
    steps = steps or 1
    
    if #State.PositionHistory < steps then
        warn("⚠️ Not enough history to rollback!")
        return
    end
    
    local targetHistory = State.PositionHistory[steps]
    if not targetHistory then return end
    
    local rootPart = GetRootPart()
    if rootPart then
        rootPart.CFrame = targetHistory.CFrame
        print(string.format("⏪ Rolled back %d steps", steps))
    end
end

-- Position history tracker
function MovementSystem:StartPositionTracking()
    State.Connections.PositionTracker = RunService.Heartbeat:Connect(function()
        SavePosition()
        task.wait(0.5) -- Save every 0.5 seconds
    end)
end

-- ============================================
-- PUBLIC API
-- ============================================

function MovementSystem:Enable()
    self:StartPositionTracking()
    
    -- Keybind handlers
    State.Connections.Keybinds = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == CONFIG.NoclipKey then
            if CONFIG.Noclip then
                self:DisableNoclip()
            else
                self:EnableNoclip()
            end
        end
        
        if input.KeyCode == CONFIG.FreezeKey then
            if CONFIG.FreezePosition then
                self:UnfreezePosition()
            else
                self:FreezePosition()
            end
        end
        
        if input.KeyCode == CONFIG.RollbackKey then
            self:Rollback(5)
        end
    end)
end

function MovementSystem:Disable()
    -- Disable all features
    self:DisableFly()
    self:DisableNoclip()
    self:ResetGravity()
    self:UnfreezePosition()
    
    CONFIG.SpeedHack = false
    CONFIG.JumpPower = false
    CONFIG.BunnyHop = false
    CONFIG.WallClimb = false
    CONFIG.AirControl = false
    
    -- Disconnect all connections
    for _, connection in pairs(State.Connections) do
        if connection then
            connection:Disconnect()
        end
    end
    State.Connections = {}
    
    -- Reset humanoid
    local humanoid = GetHumanoid()
    if humanoid then
        humanoid.WalkSpeed = 16
        humanoid.JumpPower = 50
    end
end

function MovementSystem:SetConfig(key, value)
    if CONFIG[key] ~= nil then
        CONFIG[key] = value
    end
end

function MovementSystem:GetConfig(key)
    return CONFIG[key]
end

-- ============================================
-- INITIALIZATION
-- ============================================

function MovementSystem.new()
    local self = setmetatable({}, MovementSystem)
    return self
end

return MovementSystem