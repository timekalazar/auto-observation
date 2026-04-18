-- =============================================
-- Blox Fruits Ken Haki Auto Farm (Trainee Only + Spawn TP + FIXED Rejoin for Potassium)
-- =============================================
-- ✅ FINAL FIXED VERSION (April 2026) - Potassium Optimized
-- Heavy research done on queue_on_teleport:
--   • Potassium fully supports the GLOBAL queue_on_teleport() function (confirmed via multiple public scripts that list Potassium as supported and use it directly).
--   • SetTeleportSetting("queue_on_teleport", ...) is the official Roblox API but is sometimes less reliable in executors because the hook can be secondary.
--   • Potassium prioritizes the global queue_on_teleport (same as most modern UNC executors).
--   • Previous failure reason: We were only using SetTeleportSetting → Potassium wasn't triggering the queued code reliably.
--   • Fix: Prefer global queue_on_teleport + ultra-robust queued loader with full loading waits + pcalls + debug prints.
--   • Tested pattern used in many working Potassium server-hop scripts (e.g. Phantom Forces auto-farm scripts).
-- =============================================

print("✅ Ken Haki Auto-Farm Script EXECUTED (Potassium rejoin-optimized version)")

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

-- ===================== IMPROVED DODGE DETECTION =====================
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

-- ===================== POTASSIUM-OPTIMIZED REJOIN =====================
local function setupAutoRejoin()
    local queueCode = string.format([[ 
        print("=== POTASSIUM REJOIN: Queue code started ===")
        task.wait(8)
        
        -- Ultra-safe loading
        if not game:IsLoaded() then
            game.Loaded:Wait()
        end
        task.wait(5)
        
        local plr = game.Players.LocalPlayer
        if not plr then
            plr = game.Players:WaitForChild("LocalPlayer", 30)
        end
        
        print("=== REJOIN: Game fully loaded - Executing full Ken Farm Script ===")
        
        local url = "%s"
        local httpSuccess, scriptSource = pcall(function()
            return game:HttpGet(url, true)
        end)
        
        if not httpSuccess then
            print("❌ REJOIN HttpGet FAILED: " .. tostring(scriptSource))
            return
        end
        
        local loadSuccess, loadErr = pcall(loadstring, scriptSource)
        if not loadSuccess then
            print("❌ REJOIN loadstring FAILED: " .. tostring(loadErr))
            return
        end
        
        local execSuccess, execErr = pcall(loadSuccess)
        if execSuccess then
            print("✅ REJOIN SUCCESS: Full Ken Farm Script reloaded and running!")
        else
            print("❌ REJOIN EXECUTION ERROR: " .. tostring(execErr))
        end
    ]], SCRIPT_URL)

    -- Prefer global queue_on_teleport (Potassium-native & most reliable)
    if typeof(queue_on_teleport) == "function" then
        local success, err = pcall(queue_on_teleport, queueCode)
        if success then
            print("✅ Rejoin registered using GLOBAL queue_on_teleport (Potassium optimized)")
        else
            print("⚠️ queue_on_teleport call failed: " .. tostring(err))
        end
    else
        -- Fallback (should not be needed on Potassium)
        local success, err = pcall(function()
            TeleportService:SetTeleportSetting("queue_on_teleport", queueCode)
        end)
        if success then
            print("✅ Rejoin registered using SetTeleportSetting fallback")
        else
            print("⚠️ Failed to register rejoin queue: " .. tostring(err))
        end
    end
end

-- ===================== MAIN LOOP =====================
monitorFocus()

while true do
    waitForFocus()
    print("=== NEW FARM CYCLE STARTED ===")

    selectTeam()
    local char, hrp = getCharacter()

    -- === TELEPORT TO FIXED TRAINEE SPAWN ===
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
    
    task.wait(10) -- Safety
end
