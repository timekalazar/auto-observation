-- =============================================
-- Blox Fruits Ken Haki Auto Farm (Trainee Only + Smooth + FIXED REJOIN)
-- =============================================

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ===================== SETTINGS =====================
local TELEPORT_OFFSET = CFrame.new(0, 0, -4.2)
local TWEEN_SPEED = 0.32
local REJOIN_DELAY = 9   -- Increased for stability
-- ===================================================

local selectedNPC = nil
local currentTween = nil
local isPaused = false
local focusConnection = nil

-- ===================== FOCUS MONITOR =====================
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
            if currentTween then currentTween:Cancel() end
        elseif active and isPaused then
            isPaused = false
            print("✅ FOCUS RETURNED → Resuming")
        end
    end)
end

local function waitForFocus()
    while isPaused do RunService.Heartbeat:Wait() end
end

local function waitUntil(condition)
    while not condition() and not isPaused do
        RunService.Heartbeat:Wait()
    end
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

-- ===================== TRAINEE TARGETING =====================
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
    for _ = 1, 8 do
        waitForFocus()
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
        RunService.Heartbeat:Wait()
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
        RunService.Heartbeat:Wait()
    end
end

local function startSmoothFollow(hrp)
    if currentTween then currentTween:Cancel() end

    spawn(function()
        while selectedNPC and getDodgeCount() > 0 and not isPaused do
            waitForFocus()
            local root = selectedNPC:FindFirstChild("HumanoidRootPart")
            local hum = selectedNPC:FindFirstChild("Humanoid")
            if root and hum and hum.Health > 0 then
                local target = root.CFrame * TELEPORT_OFFSET
                currentTween = TweenService:Create(hrp, TweenInfo.new(TWEEN_SPEED, Enum.EasingStyle.Linear), {CFrame = target})
                currentTween:Play()
                currentTween.Completed:Wait()
            else
                break
            end
        end
    end)
end

-- ===================== IMPROVED REJOIN SYSTEM =====================
local function setupAutoRejoin()
    local scriptUrl = "https://raw.githubusercontent.com/timekalazar/auto-observation/refs/heads/main/script.lua"
    
    local queueCode = [[
        task.wait(]] .. REJOIN_DELAY .. [[)
        print("=== Auto Rejoin Triggered - Loading Script ===")
        local success, err = pcall(function()
            loadstring(game:HttpGet("]] .. scriptUrl .. [[", true))()
        end)
        if success then
            print("✅ Ken Haki Farm Script Loaded Successfully After Rejoin")
        else
            warn("❌ Failed to load script: " .. tostring(err))
        end
    ]]

    TeleportService:SetTeleportSetting("queue_on_teleport", queueCode)
    print("✅ Rejoin queue has been SET with your script link")
end

-- ===================== MAIN LOOP =====================
monitorFocus()

while true do
    waitForFocus()
    print("=== NEW FARM CYCLE ===")

    selectTeam()
    local char, hrp = getCharacter()

    selectedNPC = findClosestTrainee(hrp)
    if not selectedNPC then
        print("Waiting for Trainee...")
        waitUntil(function() return findClosestTrainee(hrp) ~= nil end)
        selectedNPC = findClosestTrainee(hrp)
    end

    if selectedNPC then
        print("✅ Locked onto:", selectedNPC.Name)
        hrp.CFrame = selectedNPC.HumanoidRootPart.CFrame * TELEPORT_OFFSET
    end

    startSmoothFollow(hrp)
    turnOnKen()

    print("Farming... Waiting for dodges to run out")

    while getDodgeCount() > 0 do
        waitForFocus()
        if not selectedNPC or not selectedNPC.Parent or selectedNPC.Humanoid.Health <= 0 then
            selectedNPC = findClosestTrainee(hrp)
            if selectedNPC then
                print("Switched to new Trainee:", selectedNPC.Name)
                if currentTween then currentTween:Cancel() end
                startSmoothFollow(hrp)
            end
        end
        RunService.Heartbeat:Wait()
    end

    -- ==================== REJOIN SECTION ====================
    print("Dodges depleted → Preparing to rejoin...")

    if currentTween then 
        currentTween:Cancel() 
        currentTween = nil 
    end

    setupAutoRejoin()
    
    task.wait(2)                    -- Give time for queue to register
    TeleportService:Teleport(game.PlaceId, player)
    
    task.wait(3)
    -- Fallback if teleport fails
    game:Shutdown()
end
