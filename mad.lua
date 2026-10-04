--[[
    ⚡ Steal An Egg - Delta Edition ⚡
    Ringan, kompatibel Delta, tanpa HTTP bertumpuk
]]

print("=== LOADING ===")

-- SERVICES
local Players     = game:GetService("Players")
local RunService  = game:GetService("RunService")
local StarterGui  = game:GetService("StarterGui")
local VirtualUser = game:GetService("VirtualUser")

local LP = Players.LocalPlayer
print("Player: " .. LP.Name)

-- CONFIG
local CFG = {
    AUTO_TREADMILL   = true,
    AUTO_STEAL_EGG   = true,
    AUTO_COLLECT_EGG = true,
    ANTI_AFK         = true,
    STEAL_RANGE      = 300,
    COLLECT_RANGE    = 60,
    LOOP_DELAY       = 0.2,
}

-- HELPER
local function getChar()
    local char = LP.Character
    if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hrp and hum and hum.Health > 0 then return char, hrp, hum end
    return nil
end

local function isEgg(obj)
    if not obj or not obj.Parent then return false end
    local n = obj.Name:lower()
    return n:find("egg") and not n:find("base") and not n:find("treadmill")
end

local function getPos(obj)
    if obj:IsA("BasePart") then return obj.Position end
    if obj:IsA("Model") then
        local pp = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
        return pp and pp.Position
    end
    return nil
end

local function tp(hrp, pos)
    if not hrp or not pos then return end
    hrp.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
end

-- AUTO STEAL EGG
local function stealEgg()
    if not CFG.AUTO_STEAL_EGG then return end
    local char, hrp = getChar()
    if not char then return end

    local closest, minD = nil, math.huge
    for _, v in ipairs(workspace:GetDescendants()) do
        if isEgg(v) then
            local pos = getPos(v)
            if pos then
                local d = (hrp.Position - pos).Magnitude
                if d < CFG.STEAL_RANGE and d < minD then
                    closest = v; minD = d
                end
            end
        end
    end

    if closest then
        local pos = getPos(closest)
        if pos and minD > 10 then
            pcall(tp, hrp, pos)
            task.wait(0.15)
        end
        pcall(function()
            local p = closest:FindFirstChildWhichIsA("ProximityPrompt", true)
            if p then fireproximityprompt(p) end
        end)
        pcall(function()
            local c = closest:FindFirstChildWhichIsA("ClickDetector", true)
            if c then fireclickdetector(c) end
        end)
    end
end

-- AUTO COLLECT EGG
local function collectEgg()
    if not CFG.AUTO_COLLECT_EGG then return end
    local char, hrp = getChar()
    if not char then return end

    for _, v in ipairs(workspace:GetDescendants()) do
        if isEgg(v) then
            local pos = getPos(v)
            if pos and (hrp.Position - pos).Magnitude < CFG.COLLECT_RANGE then
                pcall(function()
                    local p = v:FindFirstChildWhichIsA("ProximityPrompt", true)
                    if p then fireproximityprompt(p) end
                end)
            end
        end
    end
end

-- AUTO TREADMILL
local function treadmill()
    if not CFG.AUTO_TREADMILL then return end
    local char, hrp, hum = getChar()
    if not char then return end

    local target, minD = nil, math.huge
    for _, v in ipairs(workspace:GetDescendants()) do
        if (v:IsA("BasePart") or v:IsA("Model"))
            and (v.Name:lower():find("treadmill") or v.Name:lower():find("conveyor")) then
            local pos = getPos(v)
            if pos then
                local d = (hrp.Position - pos).Magnitude
                if d < minD then target = v; minD = d end
            end
        end
    end

    if target then
        local pos = getPos(target)
        if pos then
            if minD > 8 then
                pcall(tp, hrp, pos)
                task.wait(0.2)
            end
            if hrp and minD < 12 then
                hrp.Velocity = Vector3.zero
                hrp.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
            end
        end
    end
end

-- ANTI AFK
if CFG.ANTI_AFK then
    LP.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end

-- MAIN LOOP
task.spawn(function()
    while task.wait(CFG.LOOP_DELAY) do
        pcall(stealEgg)
        pcall(collectEgg)
        pcall(treadmill)
    end
end)

-- FPS LABEL
local gui = LP:WaitForChild("PlayerGui")
local lbl = Instance.new("TextLabel")
lbl.Size = UDim2.new(0, 220, 0, 26)
lbl.Position = UDim2.new(0, 10, 0, 10)
lbl.BackgroundTransparency = 1
lbl.TextColor3 = Color3.fromRGB(0, 255, 100)
lbl.TextStrokeTransparency = 0
lbl.Font = Enum.Font.GothamBold
lbl.TextSize = 15
lbl.TextXAlignment = Enum.TextXAlignment.Left
lbl.Text = "⚡ Loading..."
lbl.Parent = gui

local f, t = 0, 0
RunService.RenderStepped:Connect(function(dt)
    f += 1; t += dt
    if t >= 0.5 then
        lbl.Text = string.format("⚡ FPS: %d | AutoFarm: ON", math.floor(f/t))
        f, t = 0, 0
    end
end)

-- NOTIF
pcall(function()
    StarterGui:SetCore("SendNotification", {
        Title = "⚡ Ultra Farm",
        Text = "Loaded! Auto steal + treadmill aktif",
        Duration = 5,
    })
end)

print("=== LOADED ===")
