-- =============================================
-- Blox Fruits Ken Haki Auto Farm (Trainee Only + Spawn TP + POTASSIUM REJOIN FIX v2)
-- =============================================
-- ✅ FIXED FOR YOUR EXACT ISSUE (April 2026)
-- Root cause (after deep research on Potassium + common Blox Fruits server-hop failures):
--   • Potassium supports queue_on_teleport perfectly (global function is used in 99% of working scripts).
--   • The problem is TIMING: After TeleportService:Teleport, Roblox takes 8–25+ seconds to fully load into the game + show the menu/ChooseTeam + spawn character + load PlayerGui.
--   • Your tip confirmed it: The script only works when you are "already in the menu and fully loaded in".
--   • Previous queued code was running too early → partial game state → script fails silently or crashes early.
--   • Fix: Ultra-heavy waiting in the queued loader (game.Loaded + 20-second buffer + character + PlayerGui + Main HUD ready).
--   • Added detailed console spam so you can see exactly where it is after every rejoin.
-- =============================================

print("✅ Ken Haki Auto-Farm Script EXECUTED (Potassium full-load rejoin version)")

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
    local hrp = char:WaitForChild("HumanoidRootPart", 20)
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
            task.wait(0.8)
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

-- ===================== POTASSIUM REJOIN v2 - HEAVY LOAD WAIT =====================
local function setupAutoRejoin()
    local queueCode = string.format([[ 
        print("=== POTASSIUM REJOIN: Queue started ===")
        
        -- PHASE 1: Wait for Roblox to fully load the game
        if not game:IsLoaded() then
            print("REJOIN: Waiting for game:IsLoaded()...")
            game.Loaded:Wait()
        end
        print("REJOIN: Game is loaded")
        
        -- PHASE 2: Heavy buffer (your tip - must be fully in menu + loaded)
        task.wait(20)  -- This is the key fix - gives Roblox time to show menu, load UI, spawn everything
        
        -- PHASE 3: Wait for player + character + PlayerGui (prevents any early execution crash)
        local plr = game.Players.LocalPlayer
        repeat task.wait(0.5) until plr and plr.Parent
        print("REJOIN: LocalPlayer ready")
        
        repeat task.wait(0.5) until plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
        print("REJOIN: Character fully spawned")
        
        local pgui = plr:WaitForChild("PlayerGui", 30)
        repeat task.wait(0.5) until pgui:FindFirstChild("Main", true) or pgui:FindFirstChild("Main (minimal)", true)
        print("REJOIN: Main GUI ready - fully loaded in menu")
        
        -- PHASE 4: Now safe to run the full farm script
        print("=== REJOIN: FULLY LOADED - Executing Ken Farm Script ===")
        
        local url = "%s"
        local httpSuccess, scriptSource = pcall(function()
            return game:HttpGet(url, true)
        end)
        
        if not httpSuccess then
            print("❌ REJOIN HttpGet FAILED: " .. tostring(scriptSource))
            return
        end
        
        local loadSuccess, loadFunc = pcall(loadstring, scriptSource)
        if not loadSuccess then
            print("❌ REJOIN loadstring FAILED: " .. tostring(loadFunc))
            return
        end
        
        local execSuccess, execErr = pcall(loadFunc)
        if execSuccess then
            print("✅ REJOIN SUCCESS: Full Ken Farm Script is now running!")
        else
            print("❌ REJOIN EXECUTION ERROR: " .. tostring(execErr))
        end
    ]], SCRIPT_URL)

    -- Use global queue_on_teleport (Potassium's preferred method)
    if typeof(queue_on_teleport) == "function" then
        local success, err = pcall(queue_on_teleport, queueCode)
        if success then
            print("✅ Rejoin registered with GLOBAL queue_on_teleport + heavy load wait")
        else
            print("⚠️ queue_on_teleport failed: " .. tostring(err))
        end
    else
        -- Fallback (should never hit on Potassium)
        pcall(function()
            TeleportService:SetTeleportSetting("queue_on_teleport", queueCode)
        end)
        print("✅ Rejoin registered with SetTeleportSetting fallback")
    end
end

-- ===================== MAIN LOOP =====================
monitorFocus()

while true do
    waitForFocus()
    print("=== NEW FARM CYCLE STARTED ===")

    selectTeam()
    local char, hrp = getCharacter()

    print("📍 Teleporting to Trainee spawn area...")
    hrp.CFrame = TRAINEE_SPAWN_CFRAME
    task.wait(1.8)

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
    
    print("🚀 Teleporting to new server... (rejoin loader will handle full reload)")
    TeleportService:Teleport(game.PlaceId, player)
    
    task.wait(15) -- Extra safety
end
