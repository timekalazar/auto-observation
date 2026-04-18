-- =============================================
-- Blox Fruits Ken Haki Auto Farm (Trainee Only + Spawn TP + Fixed Rejoin)
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
local SAFETY_LIFT = 60

-- Your Trainee Spawn Area CFrame
local TRAINEE_SPAWN_CFRAME = CFrame.new(-2815.68115, 43.2066383, 2076.00244) * 
                            CFrame.fromOrientation(0, math.rad(13), 0)  -- Cleaned rotation
-- ===================================================

local selectedNPC = nil
local stickConnection = nil
local isPaused = false

-- ===================== FOCUS =====================
local function isWindowActive()
    return (isrbxactive and isrbxactive()) or true
end

local function monitorFocus()
    RunService.Heartbeat:Connect(function()
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

-- ===================== DODGE DETECTION =====================
local function getDodgeCount()
    local main = playerGui:FindFirstChild("Main", true)
    if not main then return 0 end

    local bottom = main:FindFirstChild("BottomHUDList", true)
    if not bottom then return 0 end

    local universal = bottom:FindFirstChild("UniversalContextButtons", true)
    if not universal then return 0 end

    local kenFrame = universal:FindFirstChild("BoundActionKen")
    if not kenFrame then return 0 end

    local label = kenFrame:FindFirstChild("DodgesLeftLabel")
    if not label then return 0 end

    local text = label.Text or ""
    local current = tonumber(text:match("^(%d+)"))
    return current or 0
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
            hrp.CFrame = hrp.CFrame:Lerp(root.CFrame * TELEPORT_OFFSET, STICK_STRENGTH)
        end
    end)
end

local function shortSafetyLift(hrp)
    print("Dodges fully depleted → Short lift before rejoin...")
    local safeCFrame = hrp.CFrame * CFrame.new(0, SAFETY_LIFT, 0)
    local tween = TweenService:Create(hrp, TweenInfo.new(0.7, Enum.EasingStyle.Quad), {CFrame = safeCFrame})
    tween:Play()
    tween.Completed:Wait()
end

local function setupAutoRejoin()
    local scriptUrl = "https://raw.githubusercontent.com/timekalazar/auto-observation/refs/heads/main/script.lua"
    
    local queueCode = string.format([[ 
        task.wait(8)
        print("=== REJOIN: Executing Ken Farm Script ===")
        pcall(function()
            loadstring(game:HttpGet("%s", true))()
        end)
    ]], scriptUrl)

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

    -- === FIRST TELEPORT TO TRAINEE SPAWN AREA ===
    print("Teleporting to Trainee spawn area...")
    hrp.CFrame = TRAINEE_SPAWN_CFRAME

    task.wait(1.2) -- Small wait for enemies to load

    selectedNPC = findClosestTrainee(hrp)
    if not selectedNPC then
        print("Waiting for Trainees to spawn...")
        while not findClosestTrainee(hrp) and not isPaused do RunService.Heartbeat:Wait() end
        selectedNPC = findClosestTrainee(hrp)
    end

    if selectedNPC then
        print("✅ LOCKED ONTO:", selectedNPC.Name)
        hrp.CFrame = selectedNPC.HumanoidRootPart.CFrame * TELEPORT_OFFSET
    end

    startStrongStick(hrp)
    turnOnKen()

    print("Farming Trainees...")

    while getDodgeCount() > 0 do
        waitForFocus()
        if not selectedNPC or not selectedNPC.Parent or selectedNPC.Humanoid.Health <= 0 then
            selectedNPC = findClosestTrainee(hrp)
        end
        RunService.Heartbeat:Wait()
    end

    print("✅ Dodges fully at 0 - Starting rejoin sequence...")

    if stickConnection then
        stickConnection:Disconnect()
        stickConnection = nil
    end

    setupAutoRejoin()
    shortSafetyLift(hrp)
    
    TeleportService:Teleport(game.PlaceId, player)
end
