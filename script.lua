-- =============================================
-- Blox Fruits Ken Haki Auto Farm (Silent + Focus Monitor + Sticky Target)
-- =============================================

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ===================== SETTINGS =====================
local TELEPORT_OFFSET = CFrame.new(0, 0, -4.2)
local GLUE_STRENGTH = 0.92          -- Higher = smoother & stronger stick
local REJOIN_DELAY = 7
-- ===================================================

local selectedNPC = nil
local stickConnection = nil
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
            if stickConnection then stickConnection:Disconnect() end
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

local function findClosestEnemy(hrp)
    local closest, dist = nil, math.huge
    for _, enemy in ipairs(workspace.Enemies:GetChildren()) do
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
    return closest
end

local function startGluedFollow(hrp)
    if stickConnection then stickConnection:Disconnect() end
    
    stickConnection = RunService.Heartbeat:Connect(function()
        if isPaused or not selectedNPC then return end
        local root = selectedNPC:FindFirstChild("HumanoidRootPart")
        local hum = selectedNPC:FindFirstChild("Humanoid")
        if root and hum and hum.Health > 0 then
            local targetCFrame = root.CFrame * TELEPORT_OFFSET
            hrp.CFrame = hrp.CFrame:Lerp(targetCFrame, GLUE_STRENGTH)
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

-- ===================== START FOCUS MONITOR =====================
monitorFocus()

-- ===================== MAIN FARM LOOP =====================
while true do
    if isPaused then
        repeat RunService.Heartbeat:Wait() until not isPaused
    end
    
    print("Starting new farm cycle...")
    
    selectTeam()
    local char, hrp = getCharacter()
    
    -- === SELECT AND LOCK TARGET ===
    selectedNPC = findClosestEnemy(hrp)
    if not selectedNPC then
        waitUntil(function() 
            if isPaused then return false end
            return findClosestEnemy(hrp) ~= nil 
        end, 15)
        selectedNPC = findClosestEnemy(hrp)
    end
    
    if selectedNPC then
        print("Locked onto enemy:", selectedNPC.Name)
        hrp.CFrame = selectedNPC.HumanoidRootPart.CFrame * TELEPORT_OFFSET
    end
    
    turnOnKen()
    startGluedFollow(hrp)
    
    print("✅ Ken Haki Activated - Sticking to target")
    
    -- Farm until dodges run out
    while getDodgeCount() > 0 do
        if isPaused then
            if stickConnection then stickConnection:Disconnect() end
            repeat RunService.Heartbeat:Wait() until not isPaused
            startGluedFollow(hrp)
        end
        
        -- Only change target if current one died
        if not selectedNPC or not selectedNPC.Parent or 
           not selectedNPC:FindFirstChild("Humanoid") or 
           selectedNPC.Humanoid.Health <= 0 then
            
            selectedNPC = findClosestEnemy(hrp)
            if selectedNPC then
                print("Current target died, locked onto new enemy:", selectedNPC.Name)
            end
        end
        
        RunService.Heartbeat:Wait()
    end
    
    print("Dodges depleted - Rejoining server...")
    
    if stickConnection then
        stickConnection:Disconnect()
        stickConnection = nil
    end
    
    setupAutoRejoin()
    task.wait(1.8)
    TeleportService:Teleport(game.PlaceId, player)
    task.wait(5)
end
