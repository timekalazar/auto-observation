-- =============================================
-- Blox Fruits Ken Haki Auto Farm (Silent + Max Efficiency)
-- =============================================

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")
local VirtualInput = game:GetService("VirtualInputManager")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ===================== SETTINGS =====================
local TELEPORT_OFFSET = CFrame.new(0, 0, -4.2)
local GLUE_STRENGTH = 0.88
-- ===================================================

local selectedNPC = nil
local stickConnection = nil

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

local function waitForFocus()
    waitUntil(function() return isWindowActive() end, 20)
end

local function waitForGui()
    waitUntil(function()
        return playerGui:FindFirstChild("Main (minimal)") or playerGui:FindFirstChild("Main")
    end, 25)
end

local function selectTeam()
    waitForFocus()
    waitForGui()
    
    for i = 1, 8 do
        if not isWindowActive() then waitForFocus() end
        
        local gui = playerGui:FindFirstChild("Main (minimal)")
        if gui and gui:FindFirstChild("ChooseTeam") then
            local btn = gui.ChooseTeam.Container.Marines.Frame:FindFirstChild("TextButton")
            if btn then
                firesignal(btn.Activated)
                waitUntil(function() return not gui:FindFirstChild("ChooseTeam") end, 6)
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
    return char, char:WaitForChild("HumanoidRootPart", 10)
end

local function turnOnKen()
    VirtualInput:SendKeyEvent(true, Enum.KeyCode.E, false, game)
    RunService.Heartbeat:Wait()
    VirtualInput:SendKeyEvent(false, Enum.KeyCode.E, false, game)
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
        if selectedNPC and selectedNPC:FindFirstChild("HumanoidRootPart") and selectedNPC.Humanoid.Health > 0 then
            local targetCFrame = selectedNPC.HumanoidRootPart.CFrame * TELEPORT_OFFSET
            hrp.CFrame = hrp.CFrame:Lerp(targetCFrame, GLUE_STRENGTH)
        end
    end)
end

local function setupAutoRejoin()
    local scriptUrl = "https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/kenfarm.lua"   -- ← REPLACE WITH YOUR RAW LINK
    local queueCode = [[task.wait(4); loadstring(game:HttpGet("]] .. scriptUrl .. [[", true))()]]
    TeleportService:SetTeleportSetting("queue_on_teleport", queueCode)
end

-- ===================== MAIN CYCLE =====================
while true do
    selectTeam()
    local char, hrp = getCharacter()
    
    selectedNPC = findClosestEnemy(hrp)
    if not selectedNPC then
        waitUntil(function() return findClosestEnemy(hrp) ~= nil end, 10)
        selectedNPC = findClosestEnemy(hrp)
    end

    if selectedNPC then
        hrp.CFrame = selectedNPC.HumanoidRootPart.CFrame * TELEPORT_OFFSET
    end

    turnOnKen()
    startGluedFollow(hrp)

    while getDodgeCount() > 0 do
        if not selectedNPC or not selectedNPC.Parent or selectedNPC.Humanoid.Health <= 0 then
            selectedNPC = findClosestEnemy(hrp)
        end
        RunService.Heartbeat:Wait()
    end

    if stickConnection then stickConnection:Disconnect() end
    setupAutoRejoin()
    task.wait(0.8)
    TeleportService:Teleport(game.PlaceId, player)
    
    task.wait(15)
end
