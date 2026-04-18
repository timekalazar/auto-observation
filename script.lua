-- =============================================
-- Blox Fruits Ken Haki Auto Farm (Trainee Only + Strong Stick + Reliable Rejoin)
-- =============================================

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ===================== SETTINGS =====================
local TELEPORT_OFFSET = CFrame.new(0, 0, -4.5)
local STICK_STRENGTH = 0.96
local SAFETY_HEIGHT = 350
-- ===================================================

local selectedNPC = nil
local stickConnection = nil
local isPaused = false
local focusConnection = nil

-- ===================== FOCUS =====================
local function isWindowActive()
    return (isrbxactive and isrbxactive()) or true
end

local function monitorFocus()
    if focusConnection then focusConnection:Disconnect() end
    focusConnection = RunService.Heartbeat:Connect(function()
        local active = isWindowActive()
        if not active and not isPaused then
            isPaused = true
            print("⚠️ WINDOW LOST FOCUS → Paused")
            if stickConnection then stickConnection:Disconnect() end
        elseif active and isPaused then
            isPaused = false
            print("✅ FOCUS RETURNED → Resuming")
        end
    end)
end

local function waitForFocus()
    while isPaused do RunService.Heartbeat:Wait() end
end

local function getCharacter()
    local char = player.Character or player.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart", 10)
    return char, hrp
end

-- ===================== IMPROVED DODGE COUNTER =====================
local function getDodgeCount()
    -- Try multiple possible paths
    local main = playerGui:FindFirstChild("Main", true) or playerGui:FindFirstChild("Main (minimal)", true)
    if not main then return 0 end
    
    local label = main:FindFirstChild("DodgesLeftLabel", true)
    if not label or not label.Text then return 0 end
    
    local text = label.Text
    
    -- Handle formats like "3/3", "0/3", "12/12", etc.
    local current = tonumber(text:match("^(%d+)"))   -- First number
    local max     = tonumber(text:match("/(%d+)$"))  -- Number after /
    
    if current then
        return current
    end
    
    return 0
end

-- ===================== TARGETING =====================
local function isTrainee(enemy)
    return enemy and enemy.Name and enemy.Name:lower():find("trainee") ~= nil
end

local function findClosestTrainee(hrp)
    local closest, dist = nil, math.huge
    for _, enemy in ipairs(workspace.Enemies:GetChildren()) do
        if isTrainee(enemy) then
            local root = enemy:FindFirstChild("HumanoidRootPart")
            local hum = enemy:FindFirstChild("Humanoid")
            if root and hum and hum.Health > 0 then
                local d = (root.Position - hrp.Position).Magnitude
                if d < dist then
                    dist = d
                    closest = enemy
                end
            end
        end
    end
    return closest
end

local function selectTeam()
    waitForFocus()
    local gui = playerGui:FindFirstChild("Main (minimal)") or playerGui:FindFirstChild("Main")
    if gui and gui:FindFirstChild("ChooseTeam") then
        local btn = gui.ChooseTeam.Container.Marines.Frame:FindFirstChild("TextButton")
        if btn then firesignal(btn.Activated) end
    end
end

local function turnOnKen()
    waitForFocus()
    print("Activating Ken Haki...")
    for _ = 1, 10 do
        waitForFocus()
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
        RunService.Heartbeat:Wait()
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
        RunService.Heartbeat:Wait()
    end
    print("Ken Haki activation complete")
end

local function startStrongStick(hrp)
    if stickConnection then stickConnection:Disconnect() end
    stickConnection = RunService.Heartbeat:Connect(function()
        if isPaused or not selectedNPC then return end
        local root = selectedNPC:FindFirstChild("HumanoidRootPart")
        local hum = selectedNPC:FindFirstChild("Humanoid")
        if root and hum and hum.Health > 0 then
            local targetCFrame = root.CFrame * TELEPORT_OFFSET
            hrp.CFrame = hrp.CFrame:Lerp(targetCFrame, STICK_STRENGTH)
        end
    end)
end

local function tweenToSafety(hrp)
    print("Dodges depleted → Moving to safe height...")
    local safePos = Vector3.new(hrp.Position.X, SAFETY_HEIGHT, hrp.Position.Z)
    local tween = TweenService:Create(hrp, TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), 
                {CFrame = CFrame.new(safePos)})
    tween:Play()
    tween.Completed:Wait()
    print("✅ Safe height reached → Rejoining")
end

-- ===================== REJOIN =====================
local function setupAutoRejoin()
    local scriptUrl = "https://raw.githubusercontent.com/timekalazar/auto-observation/refs/heads/main/script.lua"
    
    local queueCode = [[
        task.wait(8)
        pcall(function()
            loadstring(game:HttpGet("]] .. scriptUrl .. [[", true))()
        end)
    ]]
    
    TeleportService:SetTeleportSetting("queue_on_teleport", queueCode)
    print("✅ Rejoin queue registered")
end

-- ===================== MAIN LOOP =====================
monitorFocus()

while true do
    waitForFocus()
    print("=== NEW CYCLE STARTED ===")

    selectTeam()
    local char, hrp = getCharacter()

    selectedNPC = findClosestTrainee(hrp)
    if not selectedNPC then
        print("Waiting for Trainee...")
        while not findClosestTrainee(hrp) and not isPaused do RunService.Heartbeat:Wait() end
        selectedNPC = findClosestTrainee(hrp)
    end

    if selectedNPC then
        print("✅ LOCKED ONTO:", selectedNPC.Name)
        hrp.CFrame = selectedNPC.HumanoidRootPart.CFrame * TELEPORT_OFFSET
    end

    startStrongStick(hrp)
    turnOnKen()

    print("Farming... (Waiting for dodges to reach 0)")

    -- Main farming loop
    while true do
        waitForFocus()
        local dodges = getDodgeCount()
        print("Current dodges:", dodges)   -- Debug print so you can see what it detects
        
        if dodges <= 0 then
            break
        end

        if not selectedNPC or not selectedNPC.Parent or selectedNPC.Humanoid.Health <= 0 then
            selectedNPC = findClosestTrainee(hrp)
        end
        RunService.Heartbeat:Wait()
    end

    -- ==================== REJOIN SEQUENCE ====================
    print("Dodges reached 0 → Starting safe exit...")

    if stickConnection then
        stickConnection:Disconnect()
        stickConnection = nil
    end

    setupAutoRejoin()
    tweenToSafety(hrp)     -- Go high up safely
    
    TeleportService:Teleport(game.PlaceId, player)
end
