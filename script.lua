-- =============================================
-- Blox Fruits Ken Haki Auto Farm (Trainee Only + Smooth Tween + Focus Monitor)
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
local TWEEN_SPEED = 0.35          -- Lower = smoother but slower stick (0.25 ~ 0.45 recommended)
local REJOIN_DELAY = 7
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
        local currentlyActive = isWindowActive()
        if not currentlyActive and not isPaused then
            isPaused = true
            print("⚠️ Window lost focus - Pausing script")
            if currentTween then currentTween:Cancel() end
        elseif currentlyActive and isPaused then
            isPaused = false
            print("✅ Window regained focus - Resuming script")
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
                return true
            end
        else
            return true
        end
        RunService.Heartbeat:Wait()
    end
    return false
end

local function getCharacter()
    local char = player.Character or player.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart", 8)
    return char, hrp
end

local function turnOnKen()
    for _ = 1, 3 do
        if isPaused then repeat RunService.Heartbeat:Wait() until not isPaused end
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
        RunService.Heartbeat:Wait()
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
        RunService.Heartbeat:Wait()
    end
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

-- ===================== TARGETING (TRAINEES ONLY) =====================
local function isTrainee(enemy)
    if not enemy or not enemy.Name then return false end
    return enemy.Name:lower():find("trainee")
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

    local tweenInfo = TweenInfo.new(TWEEN_SPEED, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0, false, 0)

    spawn(function()
        while selectedNPC and getDodgeCount() > 0 and not isPaused do
            local root = selectedNPC:FindFirstChild("HumanoidRootPart")
            local hum = selectedNPC:FindFirstChild("Humanoid")
            
            if root and hum and hum.Health > 0 then
                local targetCFrame = root.CFrame * TELEPORT_OFFSET
                
                currentTween = TweenService:Create(hrp, tweenInfo, {CFrame = targetCFrame})
                currentTween:Play()
                currentTween.Completed:Wait()
            else
                break
            end
            RunService.Heartbeat:Wait()
        end
    end)
end

-- ===================== REJOIN =====================
local function setupAutoRejoin()
    local scriptUrl = "https://raw.githubusercontent.com/timekalazar/auto-observation/refs/heads/main/script.lua"
    
    local queueCode = [[
        task.wait(]] .. REJOIN_DELAY .. [[)
        print("=== Auto Rejoin: Loading Ken Haki Farm Script ===")
        pcall(function()
            loadstring(game:HttpGet("]] .. scriptUrl .. [[", true))()
        end)
    ]]
    
    TeleportService:SetTeleportSetting("queue_on_teleport", queueCode)
end

-- ===================== START =====================
monitorFocus()

while true do
    if isPaused then
        repeat RunService.Heartbeat:Wait() until not isPaused
    end
    
    print("Starting new farm cycle... (Trainee Only + Tween)")
    
    selectTeam()
    local char, hrp = getCharacter()
    
    selectedNPC = findClosestTrainee(hrp)
    if not selectedNPC then
        print("Waiting for Trainees...")
        waitUntil(function() 
            if isPaused then return false end
            return findClosestTrainee(hrp) ~= nil 
        end, 20)
        selectedNPC = findClosestTrainee(hrp)
    end
    
    if selectedNPC then
        print("✅ Locked onto Trainee:", selectedNPC.Name)
        hrp.CFrame = selectedNPC.HumanoidRootPart.CFrame * TELEPORT_OFFSET
    end
    
    turnOnKen()
    startTweenFollow(hrp)
    
    print("Ken Haki Activated - Smooth Tween Farming")
    
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
                print("Switched to new Trainee:", selectedNPC.Name)
                if currentTween then currentTween:Cancel() end
                startTweenFollow(hrp)
            end
        end
        RunService.Heartbeat:Wait()
    end
    
    print("Dodges depleted - Rejoining...")
    
    if currentTween then currentTween:Cancel() end
    setupAutoRejoin()
    task.wait(1.8)
    TeleportService:Teleport(game.PlaceId, player)
    task.wait(5)
end
