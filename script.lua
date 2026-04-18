-- =============================================
-- Blox Fruits Ken Haki Auto Farm (Trainee Only + Strong Stick + Accurate Dodge Detection)
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
local SAFETY_LIFT = 80   -- Small lift just for clean rejoin timing (not too high)
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
    return char, char:WaitForChild("HumanoidRootPart", 10)
end

-- ===================== ACCURATE DODGE DETECTION =====================
local function getDodgeCount()
    local main = playerGui:FindFirstChild("Main", true)
    if not main then return 0 end

    local bottomHUD = main:FindFirstChild("BottomHUDList", true)
    if not bottomHUD then return 0 end

    local universal = bottomHUD:FindFirstChild("UniversalContextButtons", true)
    if not universal then return 0 end

    local kenFrame = universal:FindFirstChild("BoundActionKen")
    if not kenFrame then return 0 end

    local label = kenFrame:FindFirstChild("DodgesLeftLabel")
    if not label then return 0 end   -- Label gone = fully depleted

    local text = label.Text or ""
    local current = tonumber(text:match("^(%d+)"))   -- Gets first number (e.g. 0 from "0/4")

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

-- ===================== SHORT SAFETY LIFT =====================
local function shortSafetyLift(hrp)
    print("Dodges fully depleted → Short lift before rejoin...")
    local safeCFrame = hrp.CFrame * CFrame.new(0, SAFETY_LIFT, 0)
    local tween = TweenService:Create(hrp, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = safeCFrame})
    tween:Play()
    tween.Completed:Wait()
    print("✅ Lift complete → Rejoining server")
end

local function setupAutoRejoin()
    local scriptUrl = "https://raw.githubusercontent.com/timekalazar/auto-observation/refs/heads/main/script.lua"
    
    local queueCode = string.format([[ 
        task.wait(8)
        pcall(function()
            loadstring(game:HttpGet("%s", true))()
        end)
    ]], scriptUrl)

    TeleportService:SetTeleportSetting("queue_on_teleport", queueCode)
    print("✅ Rejoin queue set")
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

    print("Farming...")

    -- Only exit when dodges are fully 0
    while getDodgeCount() > 0 do
        waitForFocus()
        if not selectedNPC or not selectedNPC.Parent or selectedNPC.Humanoid.Health <= 0 then
            selectedNPC = findClosestTrainee(hrp)
        end
        RunService.Heartbeat:Wait()
    end

    print("✅ Dodges fully depleted (0) - Starting rejoin...")

    if stickConnection then
        stickConnection:Disconnect()
        stickConnection = nil
    end

    setupAutoRejoin()
    shortSafetyLift(hrp)      -- Short lift for clean timing
    
    TeleportService:Teleport(game.PlaceId, player)
end
