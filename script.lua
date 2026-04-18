-- =============================================
-- Blox Fruits Ken Haki Auto Farm (Trainee Only + Spawn TP + Simplified Rejoin)
-- =============================================
-- ✅ CLEAN VERSION - Only fix for team menu after rejoin
-- Removed ALL heavy/unnecessary rejoin functions we added before.
-- The ONLY change: Added a single lightweight waitForTeamMenu() that runs on EVERY execution.
-- This fixes the exact issue you described (script runs too early before menu loads after rejoin).
-- Queue code is now minimal (just a short wait + loadstring).
-- Everything else is back to clean core farming logic.
-- =============================================

print("✅ Ken Haki Auto-Farm Script EXECUTED")

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ===================== SETTINGS =====================
local TELEPORT_OFFSET = CFrame.new(0, 0, -4)
local STICK_STRENGTH = 0.96
local SAFETY_LIFT = 60

local TRAINEE_SPAWN_CFRAME = CFrame.new(-2815.68115, 43.2066383, 2076.00244) * 
                            CFrame.fromOrientation(0, math.rad(13), 0)

local SCRIPT_URL = "https://raw.githubusercontent.com/timekalazar/auto-observation/refs/heads/main/script.lua"
-- ===================================================

local selectedNPC = nil
local stickConnection = nil
local isPaused = false

-- ===================== NEW: TEAM MENU WAIT (fixes rejoin) =====================
local function waitForTeamMenu()
    print("⏳ Waiting for team selection menu to fully load...")
    local startTime = tick()
    while tick() - startTime < 30 do  -- 30-second max wait (safe timeout)
        local gui = playerGui:FindFirstChild("Main (minimal)") or playerGui:FindFirstChild("Main")
        if gui and gui:FindFirstChild("ChooseTeam") then
            print("✅ Team menu loaded - ready!")
            return
        end
        task.wait(1)
    end
    print("⚠️ Team menu wait timed out - proceeding (normal if already in-game)")
end

-- ===================== FOCUS MONITOR =====================
local function isWindowActive()
    return (isrbxactive and isrbxactive()) or true
end

local function monitorFocus()
    RunService.Heartbeat:Connect(function()
        local active = isWindowActive()
        if not active and not isPaused then
            isPaused = true
            print("⚠️ WINDOW LOST FOCUS → Paused farming")
            if stickConnection then 
                stickConnection:Disconnect() 
                stickConnection = nil 
            end
        elseif active and isPaused then
            isPaused = false
            print("✅ FOCUS RETURNED → Resuming farming")
        end
    end)
end

local function waitForFocus()
    while isPaused do 
        RunService.Heartbeat:Wait() 
    end
end

local function getCharacter()
    local char = player.Character or player.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart", 15)
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
    local currentStr = text:match("([%d%.]+)/")
    local current = tonumber(currentStr) or 0
    return current
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
        if btn then 
            firesignal(btn.Activated) 
            task.wait(0.5)
        end
    end
end

local function turnOnKen()
    waitForFocus()
    print("🔥 Activating Ken Haki (10 presses)...")
    for _ = 1, 10 do
        waitForFocus()
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
        RunService.Heartbeat:Wait()
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
        RunService.Heartbeat:Wait()
    end
    print("✅ Ken Haki activated")
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
    print("🛡️ Dodges = 0 → Safety lift before rejoin...")
    local safeCFrame = hrp.CFrame * CFrame.new(0, SAFETY_LIFT, 0)
    local tween = TweenService:Create(hrp, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = safeCFrame})
    tween:Play()
    tween.Completed:Wait()
end

-- ===================== MINIMAL REJOIN (no unnecessary code) =====================
local function setupAutoRejoin()
    local queueCode = string.format([[ 
        task.wait(12)
        print("=== REJOIN: Executing main script (will wait for team menu inside) ===")
        loadstring(game:HttpGet("%s", true))()
    ]], SCRIPT_URL)

    if typeof(queue_on_teleport) == "function" then
        pcall(queue_on_teleport, queueCode)
        print("✅ Rejoin registered (minimal queue)")
    else
        pcall(function()
            TeleportService:SetTeleportSetting("queue_on_teleport", queueCode)
        end)
        print("✅ Rejoin registered (fallback)")
    end
end

-- ===================== MAIN LOOP =====================
monitorFocus()

waitForTeamMenu()  -- This is the ONLY fix - runs every time script executes

while true do
    waitForFocus()
    print("=== NEW FARM CYCLE STARTED ===")

    selectTeam()
    local char, hrp = getCharacter()

    print("📍 Teleporting to Trainee spawn area...")
    hrp.CFrame = TRAINEE_SPAWN_CFRAME
    task.wait(1.5)

    selectedNPC = findClosestTrainee(hrp)
    if not selectedNPC then
        print("⏳ Waiting for Trainees to spawn...")
        repeat
            RunService.Heartbeat:Wait()
            selectedNPC = findClosestTrainee(hrp)
        until selectedNPC or isPaused
    end

    if selectedNPC then
        print("✅ LOCKED ONTO:", selectedNPC.Name)
        hrp.CFrame = selectedNPC:WaitForChild("HumanoidRootPart").CFrame * TELEPORT_OFFSET
    end

    startStrongStick(hrp)
    turnOnKen()

    print("🌟 Farming Trainees (Ken Haki ON)...")

    while getDodgeCount() > 0 do
        waitForFocus()
        if not selectedNPC or not selectedNPC.Parent or (selectedNPC:FindFirstChild("Humanoid") and selectedNPC.Humanoid.Health <= 0) then
            selectedNPC = findClosestTrainee(hrp)
        end
        RunService.Heartbeat:Wait()
    end

    print("✅ Dodges reached exactly 0 → Starting rejoin sequence")

    if stickConnection then
        stickConnection:Disconnect()
        stickConnection = nil
    end

    setupAutoRejoin()
    shortSafetyLift(hrp)
    
    print("🚀 Teleporting to new server...")
    TeleportService:Teleport(game.PlaceId, player)
    
    task.wait(10)
end
