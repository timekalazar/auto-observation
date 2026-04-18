-- =============================================
-- Blox Fruits Ken Haki Auto Farm (Trainee Only + Smooth Tween + Fully Reliable)
-- Rewritten from scratch - No timing reliance where possible
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
local TWEEN_SPEED = 0.32          -- Lower = tighter stick (0.25-0.40 recommended)
local REJOIN_DELAY = 8.5          -- Only used for rejoin queue (unavoidable)
-- ===================================================

local selectedNPC = nil
local currentTween = nil
local isPaused = false
local focusConnection = nil

-- ===================== FOCUS MONITOR (Core Requirement) =====================
local function isWindowActive()
    return (isrbxactive and isrbxactive()) or true
end

local function monitorFocus()
    if focusConnection then focusConnection:Disconnect() end
    
    focusConnection = RunService.Heartbeat:Connect(function()
        local active = isWindowActive()
        
        if not active and not isPaused then
            isPaused = true
            print("⚠️  WINDOW LOST FOCUS → Script paused")
            if currentTween then currentTween:Cancel() end
        elseif active and isPaused then
            isPaused = false
            print("✅ FOCUS RETURNED → Script resuming")
        end
    end)
end

-- ===================== UTILITY =====================
local function waitForFocus()
    while isPaused do
        RunService.Heartbeat:Wait()
    end
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
        if label then
            return tonumber(label.Text:match("%d+")) or 0
        end
    end
    return 0
end

-- ===================== TRAINEE-ONLY TARGETING =====================
local function isTrainee(enemy)
    if not enemy or not enemy.Name then return false end
    return enemy.Name:lower():find("trainee") ~= nil
end

local function findClosestTrainee(hrp)
    local closest, shortest = nil, math.huge
    for _, enemy in ipairs(workspace.Enemies:GetChildren()) do
        if isTrainee(enemy) then
            local root = enemy:FindFirstChild("HumanoidRootPart")
            local hum = enemy:FindFirstChild("Humanoid")
            if root and hum and hum.Health > 0 then
                local distance = (root.Position - hrp.Position).Magnitude
                if distance < shortest then
                    shortest = distance
                    closest = enemy
                end
            end
        end
    end
    return closest
end

-- ===================== SELECT TEAM =====================
local function selectTeam()
    waitForFocus()
    local gui = playerGui:FindFirstChild("Main (minimal)") or playerGui:FindFirstChild("Main")
    if not gui or not gui:FindFirstChild("ChooseTeam") then return end

    local btn = gui.ChooseTeam.Container.Marines.Frame:FindFirstChild("TextButton")
    if btn then
        firesignal(btn.Activated)
        waitUntil(function() return not gui:FindFirstChild("ChooseTeam") end)
    end
end

-- ===================== TOGGLE KEN HAKI (Reliable) =====================
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
    print("Ken Haki activation complete")
end

-- ===================== SMOOTH TWEEN FOLLOW (No wild movement) =====================
local function startSmoothFollow(hrp)
    if currentTween then currentTween:Cancel() end

    spawn(function()
        while selectedNPC and getDodgeCount() > 0 and not isPaused do
            waitForFocus()
            
            local root = selectedNPC:FindFirstChild("HumanoidRootPart")
            local hum = selectedNPC:FindFirstChild("Humanoid")
            
            if root and hum and hum.Health > 0 then
                local targetCFrame = root.CFrame * TELEPORT_OFFSET
                currentTween = TweenService:Create(
                    hrp,
                    TweenInfo.new(TWEEN_SPEED, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
                    {CFrame = targetCFrame}
                )
                currentTween:Play()
                currentTween.Completed:Wait()
            else
                break
            end
            RunService.Heartbeat:Wait()
        end
    end)
end

-- ===================== REJOIN SYSTEM =====================
local function setupAutoRejoin()
    local scriptUrl = "https://raw.githubusercontent.com/timekalazar/auto-observation/refs/heads/main/script.lua"
    
    local queueCode = [[
        task.wait(]] .. REJOIN_DELAY .. [[)
        print("=== Auto Rejoin: Loading Ken Haki Farm Script ===")
        local success, err = pcall(function()
            loadstring(game:HttpGet("]] .. scriptUrl .. [[", true))()
        end)
        if success then
            print("✅ Script successfully loaded after rejoin")
        else
            warn("Rejoin load failed: " .. tostring(err))
        end
    ]]
    
    TeleportService:SetTeleportSetting("queue_on_teleport", queueCode)
    print("Rejoin queue successfully set")
end

-- ===================== START FOCUS MONITOR =====================
monitorFocus()

-- ===================== MAIN LOOP (Exact order you requested) =====================
while true do
    waitForFocus()
    
    print("=== NEW CYCLE STARTED ===")
    
    -- 1. Select team
    selectTeam()
    
    -- 2. Get character
    local char, hrp = getCharacter()
    
    -- 3. Find & lock closest Trainee
    selectedNPC = findClosestTrainee(hrp)
    if not selectedNPC then
        print("No Trainees found - waiting for one...")
        waitUntil(function() return findClosestTrainee(hrp) ~= nil end)
        selectedNPC = findClosestTrainee(hrp)
    end
    
    if selectedNPC then
        print("✅ LOCKED ONTO TRAINEE:", selectedNPC.Name)
        
        -- 4. Instant teleport to enemy
        hrp.CFrame = selectedNPC.HumanoidRootPart.CFrame * TELEPORT_OFFSET
    end
    
    -- 5. Start smooth stick
    startSmoothFollow(hrp)
    
    -- 6. Toggle Ken Haki
    turnOnKen()
    
    print("Farming Trainees - Ken Haki active")
    
    -- 7. Wait for dodges to deplete (condition-based, no timing)
    while getDodgeCount() > 0 do
        waitForFocus()
        
        -- Switch target only if current Trainee dies
        if not selectedNPC or not selectedNPC.Parent or 
           not selectedNPC:FindFirstChild("Humanoid") or selectedNPC.Humanoid.Health <= 0 then
            
            selectedNPC = findClosestTrainee(hrp)
            if selectedNPC then
                print("Switched to new Trainee:", selectedNPC.Name)
                if currentTween then currentTween:Cancel() end
                startSmoothFollow(hrp)
            end
        end
        
        RunService.Heartbeat:Wait()
    end
    
    -- 8. Cleanup & Rejoin
    print("Dodges depleted → Rejoining server...")
    if currentTween then 
        currentTween:Cancel() 
        currentTween = nil 
    end
    
    setupAutoRejoin()
    
    task.wait(1.2) -- Minimal safe delay before teleport
    TeleportService:Teleport(game.PlaceId, player)
end
