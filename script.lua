-- =============================================
-- Blox Fruits Ken Haki Auto Farm (Silent + Improved Potassium Rejoin)
-- Rewritten & Optimized by Grok
-- =============================================

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ===================== SETTINGS =====================
local TELEPORT_OFFSET = CFrame.new(0, 0, -4.2)   -- Position behind the enemy
local GLUE_STRENGTH = 0.85                       -- How strongly it follows (0.7 ~ 0.95 recommended)
local REJOIN_DELAY = 7                            -- Seconds to wait after rejoin before running script
-- ===================================================

local selectedNPC = nil
local stickConnection = nil

-- ===================== UTILITY FUNCTIONS =====================
local function isWindowActive()
    return (isrbxactive and isrbxactive()) or true
end

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
    for _ = 1, 10 do
        local gui = playerGui:FindFirstChild("Main (minimal)") or playerGui:FindFirstChild("Main")
        if gui and gui:FindFirstChild("ChooseTeam") then
            local marinesBtn = gui.ChooseTeam.Container.Marines.Frame:FindFirstChild("TextButton")
            if marinesBtn then
                firesignal(marinesBtn.Activated)
                waitUntil(function() return not gui:FindFirstChild("ChooseTeam") end, 10)
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
            local distance = (root.Position - hrp.Position).Magnitude
            if distance < dist then
                dist = distance
                closest = enemy
            end
        end
    end
    return closest
end

local function startGluedFollow(hrp)
    if stickConnection then stickConnection:Disconnect() end
    
    stickConnection = RunService.Heartbeat:Connect(function()
        if selectedNPC and selectedNPC:FindFirstChild("HumanoidRootPart") and selectedNPC.Humanoid.Health > 0 then
            local targetCFrame = selectedNPC.HumanoidRootPart.CFrame * TELEPORT_OFFSET
            hrp.CFrame = hrp.CFrame:Lerp(targetCFrame, GLUE_STRENGTH)
        end
    end)
end

-- ===================== REJOIN SYSTEM =====================
local function setupAutoRejoin()
    -- CHANGE THIS TO YOUR ACTUAL RAW GITHUB LINK
    local scriptUrl = "https://raw.githubusercontent.com/timekalazar/auto-observation/refs/heads/main/script.lua"
    
    local queueCode = [[
        task.wait(]] .. REJOIN_DELAY .. [[)
        print("=== Auto Rejoin: Loading Ken Haki Farm Script ===")
        local success, err = pcall(function()
            loadstring(game:HttpGet("]] .. scriptUrl .. [[", true))()
        end)
        if not success then
            warn("Failed to load Ken Farm script: " .. tostring(err))
        end
    ]]

    TeleportService:SetTeleportSetting("queue_on_teleport", queueCode)
end

-- ===================== MAIN FARM LOOP =====================
while true do
    print("Starting new farm cycle...")
    
    selectTeam()
    local char, hrp = getCharacter()
    
    -- Find target
    selectedNPC = findClosestEnemy(hrp)
    if not selectedNPC then
        waitUntil(function() return findClosestEnemy(hrp) ~= nil end, 15)
        selectedNPC = findClosestEnemy(hrp)
    end
    
    if selectedNPC and selectedNPC:FindFirstChild("HumanoidRootPart") then
        hrp.CFrame = selectedNPC.HumanoidRootPart.CFrame * TELEPORT_OFFSET
    end
    
    turnOnKen()
    startGluedFollow(hrp)
    
    print("Ken Haki Activated - Farming...")
    
    -- Farm until dodges run out
    while getDodgeCount() > 0 do
        if not selectedNPC or not selectedNPC.Parent or selectedNPC.Humanoid.Health <= 0 then
            selectedNPC = findClosestEnemy(hrp)
        end
        RunService.Heartbeat:Wait()
    end
    
    print("Dodges depleted - Preparing to rejoin...")
    
    -- Cleanup
    if stickConnection then
        stickConnection:Disconnect()
        stickConnection = nil
    end
    
    -- Setup rejoin
    setupAutoRejoin()
    
    task.wait(1.8)
    print("Teleporting to new server...")
    TeleportService:Teleport(game.PlaceId, player)
    
    task.wait(5) -- Safety wait
end
