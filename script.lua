-- =============================================
-- Blox Fruits Ken Haki Auto Farm (Trainee Only + Strong Stick + Safe Tween Rejoin)
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
local SAFETY_HEIGHT = 300   -- High up in the air (safe zone)
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

local function getDodgeCount()
    local main = playerGui:FindFirstChild("Main", true)
    if main then
        local label = main:FindFirstChild("DodgesLeftLabel", true)
        return tonumber(label and label.Text:match("%d+")) or 0
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

-- ===================== STRONG STICK =====================
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

-- ===================== SAFE TWEEN TO HEIGHT =====================
local function tweenToSafety(hrp)
    print("Dodges depleted → Moving to safe height before rejoin...")
    
    local safeCFrame = CFrame.new(hrp.Position.X, SAFETY_HEIGHT, hrp.Position.Z) * CFrame.Angles(0, math.rad(90), 0)
    
    local tween = TweenService:Create(hrp, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = safeCFrame})
    tween:Play()
    tween.Completed:Wait()
    
    print("✅ Reached safe height. Rejoining now...")
end

-- ===================== REJOIN =====================
local function setupAutoRejoin()
    local scriptUrl = "https://raw.githubusercontent.com/timekalazar/auto-observation/refs/heads/main/script.lua"
    
    local queueCode = [[
        task.wait(8)
        print("=== REJOIN: Loading Ken Haki Farm Script ===")
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
    print("=== NEW FARM CYCLE STARTED ===")

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

    print("Farming Trainees...")

    while getDodgeCount() > 0 do
        waitForFocus()
        if not selectedNPC or not selectedNPC.Parent or selectedNPC.Humanoid.Health <= 0 then
            selectedNPC = findClosestTrainee(hrp)
        end
        RunService.Heartbeat:Wait()
    end

    -- ==================== SAFE EXIT & REJOIN ====================
    if stickConnection then
        stickConnection:Disconnect()
        stickConnection = nil
    end

    setupAutoRejoin()
    tweenToSafety(hrp)          -- Smoothly go high up first
    
    TeleportService:Teleport(game.PlaceId, player)
end
