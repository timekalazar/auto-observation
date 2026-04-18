-- =============================================
-- Blox Fruits Ken Haki Auto Farm (Trainee Only + Smooth Tween + Reliable Rejoin)
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
local TWEEN_SPEED = 0.32          -- Smooth but tight follow
local REJOIN_DELAY = 8.5          -- Increased for better re-execution reliability
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
            print("⚠️ Window lost focus - Pausing")
            if currentTween then currentTween:Cancel() end
        elseif active and isPaused then
            isPaused = false
            print("✅ Focus regained - Resuming")
        end
    end)
end

-- ===================== UTILITY =====================
local function waitUntil(condition, timeout)
    timeout = timeout or 30
    local start = tick()
    while not condition() and (tick() - start) < timeout do
        RunService.Heartbeat:Wait()
    end
end

local function waitForGui()
    waitUntil(function()
        return playerGui:FindFirstChild("Main (minimal)") or playerGui:FindFirstChild("Main")
    end, 25)
end

local function selectTeam()
    waitForGui()
    for _ = 1, 12 do
        if isPaused then repeat RunService.Heartbeat:Wait() until not isPaused end
        local gui = playerGui:FindFirstChild("Main (minimal)") or playerGui:FindFirstChild("Main")
        if gui and gui:FindFirstChild("ChooseTeam") then
            local btn = gui.ChooseTeam.Container.Marines.Frame:FindFirstChild("TextButton")
            if btn then
                firesignal(btn.Activated)
                waitUntil(function() return not gui:FindFirstChild("ChooseTeam") end, 8)
                return
            end
        else
            return
        end
        RunService.Heartbeat:Wait()
    end
end

local function getCharacter()
    local char = player.Character or player.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart", 8)
    return char, hrp
end

local function turnOnKen()
    print("Attempting to turn ON Ken Haki...")
    for i = 1, 6 do  -- More attempts + small delay
        if isPaused then repeat RunService.Heartbeat:Wait() until not isPaused end
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
        RunService.Heartbeat:Wait()
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
        task.wait(0.15)
    end
    task.wait(0.4)
    print("Ken Haki activation sequence finished")
end

local function getDodgeCount()
    local main = playerGui:FindFirstChild("Main", true)
    if main then
        local label = main:FindFirstChild("DodgesLeftLabel", true)
        if label then
            return tonumber(label.Text:match("%d+")) or 0
        end
    end
    return 0
end

-- ===================== TRAINEE-ONLY TARGETING =====================
local function isTrainee(enemy)
    if not enemy or not enemy.Name then return false end
    local name = enemy.Name:lower()
    return name:find("trainee")
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

-- ===================== SMOOTH TWEEN FOLLOW =====================
local function startTweenFollow(hrp)
    if currentTween then currentTween:Cancel() end

    spawn(function()
        while selectedNPC and getDodgeCount() > 0 and not isPaused do
            local root = selectedNPC:FindFirstChild("HumanoidRootPart")
            local hum = selectedNPC:FindFirstChild("Humanoid")
            if root and hum and hum.Health > 0 then
                local targetCFrame = root.CFrame * TELEPORT_OFFSET
                currentTween = TweenService:Create(hrp, TweenInfo.new(TWEEN_SPEED, Enum.EasingStyle.Linear), {CFrame = targetCFrame})
                currentTween:Play()
                currentTween.Completed:Wait()
            else
                break
            end
            RunService.Heartbeat:Wait()
        end
    end)
end

-- ===================== REJOIN (YOUR LINK) =====================
local function setupAutoRejoin()
    local scriptUrl = "https://raw.githubusercontent.com/timekalazar/auto-observation/refs/heads/main/script.lua"
    
    local queueCode = [[
        task.wait(]] .. REJOIN_DELAY .. [[)
        print("=== Auto Rejoin: Loading your Ken Farm script ===")
        local success, err = pcall(function()
            loadstring(game:HttpGet("]] .. scriptUrl .. [[", true))()
        end)
        if not success then
            warn("Rejoin load failed: " .. tostring(err))
        else
            print("✅ Script successfully queued and loaded")
        end
    ]]
    
    TeleportService:SetTeleportSetting("queue_on_teleport", queueCode)
    print("Rejoin queue has been set with your link")
end

-- ===================== START =====================
monitorFocus()

while true do
    if isPaused then repeat RunService.Heartbeat:Wait() until not isPaused end
    
    print("Starting new farm cycle... (Trainee Only)")
    
    selectTeam()
    local char, hrp = getCharacter()
    
    selectedNPC = findClosestTrainee(hrp)
    if not selectedNPC then
        print("No Trainees found - waiting...")
        waitUntil(function() 
            if isPaused then return false end
            return findClosestTrainee(hrp) ~= nil 
        end, 25)
        selectedNPC = findClosestTrainee(hrp)
    end
    
    if selectedNPC then
        print("✅ LOCKED onto Trainee →", selectedNPC.Name)
        hrp.CFrame = selectedNPC.HumanoidRootPart.CFrame * TELEPORT_OFFSET
    end
    
    turnOnKen()
    startTweenFollow(hrp)
    
    print("Farming Trainees with smooth tween...")

    while getDodgeCount() > 0 do
        if isPaused then
            if currentTween then currentTween:Cancel() end
            repeat RunService.Heartbeat:Wait() until not isPaused
            startTweenFollow(hrp)
        end
        
        if not selectedNPC or not selectedNPC.Parent or 
           not selectedNPC:FindFirstChild("Humanoid") or selectedNPC.Humanoid.Health <= 0 then
            selectedNPC = findClosestTrainee(hrp)
            if selectedNPC then
                print("Switched to new Trainee →", selectedNPC.Name)
                if currentTween then currentTween:Cancel() end
                startTweenFollow(hrp)
            end
        end
        RunService.Heartbeat:Wait()
    end
    
    print("Dodges depleted → Preparing rejoin...")
    
    if currentTween then currentTween:Cancel() end
    setupAutoRejoin()
    
    task.wait(1.5)
    TeleportService:Teleport(game.PlaceId, player)
    task.wait(4)  -- Reduced from 5
end
