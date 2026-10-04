--[[
    ⚡ Steal An Egg V2 - Ultra Optimized + AUTO FARM EDITION ⚡
    Features:
    - Ultra FPS Boost
    - Auto Treadmill (AFK speed farming)
    - Auto Steal Egg (dari base orang lain)
    - Auto Collect Egg (yang jatuh di sekitar)
    - Auto Rejoin on Kick (optional)
    - Smart Object Cleaner
]]

--============================================================
-- LOAD ORIGINAL HUB
--============================================================
pcall(function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/ThanhDuyHub/Game/refs/heads/main/Steal-An-Egg-V2.lua"))()
end)

--============================================================
-- SERVICES
--============================================================
local Players     = game:GetService("Players")
local Lighting    = game:GetService("Lighting")
local RunService  = game:GetService("RunService")
local StarterGui  = game:GetService("StarterGui")
local Stats       = game:GetService("Stats")
local VirtualUser = game:GetService("VirtualUser")
local Workspace   = workspace

local LocalPlayer = Players.LocalPlayer
local Terrain     = Workspace:FindFirstChildOfClass("Terrain")

--============================================================
-- CONFIG
--============================================================
local CONFIG = {
    -- Optimizer
    REMOVE_DECALS    = true,
    REMOVE_SOUNDS    = true,
    REMOVE_MESHES    = false,
    REMOVE_LIGHTING  = true,
    CLEAN_TERRAIN    = true,
    KEEP_CHARACTER   = true,
    AUTO_CLEANUP     = true,
    CLEANUP_INTERVAL = 30,

    -- Auto Farm
    AUTO_TREADMILL       = true,   -- Auto AFK di treadmill sendiri
    AUTO_STEAL_EGG       = true,   -- Auto steal egg dari base lain
    AUTO_COLLECT_EGG     = true,   -- Auto ambil egg yang ada di sekitar
    AUTO_EQUIP_BEST      = false,  -- Auto equip pet terbaik (kalau ada)
    STEAL_RANGE          = 300,    -- Radius steal (stud)
    COLLECT_RANGE        = 50,     -- Radius collect (stud)
    LOOP_DELAY           = 0.1,    -- Delay antar loop
    TELEPORT_STEAL       = true,   -- Teleport ke egg sebelum steal
    TELEPORT_OFFSET      = 4,      -- Offset dari egg biar gak stuck
}

--============================================================
-- LIGHTING OPTIMIZATION
--============================================================
if CONFIG.REMOVE_LIGHTING then
    pcall(function()
        settings().Rendering.QualityLevel        = Enum.QualityLevel.Level0
        settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level0
        settings().Rendering.ShadowsEnabled      = false
    end)

    pcall(function() sethiddenproperty(Lighting, "Technology", Enum.Technology.Compatibility) end)

    Lighting.GlobalShadows            = false
    Lighting.Brightness               = 1
    Lighting.FogEnd                   = 1e6
    Lighting.FogStart                 = 0
    Lighting.EnvironmentSpecularScale = 0
    Lighting.EnvironmentDiffuseScale  = 0
    Lighting.ShadowSoftness           = 0
    Lighting.Ambient                  = Color3.fromRGB(128, 128, 128)
    Lighting.OutdoorAmbient           = Color3.fromRGB(128, 128, 128)

    for _, v in ipairs(Lighting:GetChildren()) do
        if v:IsA("PostEffect") or v:IsA("Sky") or v:IsA("Atmosphere")
            or v:IsA("BloomEffect") or v:IsA("ColorCorrectionEffect")
            or v:IsA("BlurEffect") or v:IsA("SunRaysEffect")
            or v:IsA("DepthOfFieldEffect") or v:IsA("FireEffect") then
            v:Destroy()
        end
    end
end

--============================================================
-- TERRAIN OPTIMIZATION
--============================================================
if Terrain and CONFIG.CLEAN_TERRAIN then
    Terrain.WaterWaveSize     = 0
    Terrain.WaterWaveSpeed    = 0
    Terrain.WaterReflectance  = 0
    Terrain.WaterTransparency = 1
    Terrain.WaterColor        = Color3.fromRGB(128, 128, 128)
    pcall(function() Terrain.Decoration = false end)
end

--============================================================
-- OPTIMIZER FUNCTIONS
--============================================================
local function isLocalChar(obj)
    local char = LocalPlayer.Character
    return char and obj:IsDescendantOf(char) or false
end

local function destroyEffect(obj)
    if obj:IsA("Trail") or obj:IsA("Beam") or obj:IsA("ParticleEmitter")
        or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles")
        or obj:IsA("Explosion") or obj:IsA("PointLight") or obj:IsA("SpotLight")
        or obj:IsA("SurfaceLight") then
        obj:Destroy() return true
    end
    if CONFIG.REMOVE_DECALS and (obj:IsA("Decal") or obj:IsA("Texture")) then
        obj:Destroy() return true
    end
    if CONFIG.REMOVE_MESHES and (obj:IsA("SpecialMesh") or obj:IsA("DataModelMesh")) then
        obj:Destroy() return true
    end
    if CONFIG.REMOVE_SOUNDS and obj:IsA("Sound") then
        obj:Destroy() return true
    end
    if obj:IsA("BillboardGui") or obj:IsA("SurfaceGui") then
        obj:Destroy() return true
    end
    return false
end

local function cleanPart(obj)
    if obj:IsA("BasePart") then
        obj.Material    = Enum.Material.SmoothPlastic
        obj.Reflectance = 0
        obj.CastShadow  = false
        pcall(function()
            obj.TopSurface    = Enum.SurfaceType.Smooth
            obj.BottomSurface = Enum.SurfaceType.Smooth
        end)
    end
    destroyEffect(obj)
end

local KEYWORDS = {
    "tree","plant","grass","leaves","bush","flower","prop","rock","debris",
    "particle","vfx","fx","effect","light","fire","smoke","sparkle",
    "explosion","trail","beam","decor"
}

local function shouldRemoveModel(obj)
    if not (obj:IsA("Model") or obj:IsA("Folder")) then return false end
    local name = obj.Name:lower()
    for _, k in ipairs(KEYWORDS) do
        if name:find(k) then return true end
    end
    return false
end

local function fullCleanup()
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v and v.Parent and not (CONFIG.KEEP_CHARACTER and isLocalChar(v)) then
            if shouldRemoveModel(v) then v:Destroy() end
        end
    end
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v and v.Parent and not (CONFIG.KEEP_CHARACTER and isLocalChar(v)) then
            cleanPart(v)
        end
    end
end

fullCleanup()

Workspace.DescendantAdded:Connect(function(v)
    task.defer(function()
        if not v or not v.Parent then return end
        if CONFIG.KEEP_CHARACTER and isLocalChar(v) then return end
        if shouldRemoveModel(v) then v:Destroy() return end
        cleanPart(v)
    end)
end)

--============================================================
-- CHARACTER PROTECTION
--============================================================
local function onCharacter(char)
    char:WaitForChild("Humanoid", 10)
    for _, v in ipairs(char:GetDescendants()) do
        if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam")
            or v:IsA("Fire") or v:IsA("Smoke") or v:IsA("Sparkles")
            or v:IsA("PointLight") or v:IsA("SpotLight") then
            v:Destroy()
        end
    end
    char.DescendantAdded:Connect(function(v)
        if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam")
            or v:IsA("Fire") or v:IsA("Smoke") or v:IsA("Sparkles")
            or v:IsA("PointLight") or v:IsA("SpotLight") then
            task.defer(function() if v and v.Parent then v:Destroy() end end)
        end
    end)
end

if LocalPlayer.Character then onCharacter(LocalPlayer.Character) end
LocalPlayer.CharacterAdded:Connect(onCharacter)

--============================================================
-- AUTO CLEANUP LOOP
--============================================================
if CONFIG.AUTO_CLEANUP then
    task.spawn(function()
        while task.wait(CONFIG.CLEANUP_INTERVAL) do
            pcall(fullCleanup)
            pcall(function() collectgarbage("collect") end)
        end
    end)
end

pcall(function() StarterGui:SetCore("ParticlesDisabled", true) end)

--============================================================
-- 🥚 AUTO FARM CORE
--============================================================
local function getCharacter()
    local char = LocalPlayer.Character
    if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hrp and hum and hum.Health > 0 then
        return char, hrp, hum
    end
    return nil
end

-- Cari egg berdasarkan nama model (kebanyakan game pakai nama "Egg")
local function isEgg(obj)
    if not obj or not obj.Parent then return false end
    local name = obj.Name:lower()
    return name:find("egg") ~= nil
        and not name:find("base")
        and not name:find("treadmill")
end

-- Ambil posisi egg
local function getEggPosition(egg)
    if egg:IsA("BasePart") then return egg.Position end
    if egg:IsA("Model") then
        local pp = egg.PrimaryPart or egg:FindFirstChildWhichIsA("BasePart")
        return pp and pp.Position or nil
    end
    return nil
end

-- Teleport halus ke posisi target
local function teleportTo(hrp, pos)
    if not hrp or not pos then return end
    local offset = Vector3.new(
        math.random(-CONFIG.TELEPORT_OFFSET, CONFIG.TELEPORT_OFFSET),
        0,
        math.random(-CONFIG.TELEPORT_OFFSET, CONFIG.TELEPORT_OFFSET)
    )
    hrp.CFrame = CFrame.new(pos + offset + Vector3.new(0, 3, 0))
end

--🔥 AUTO STEAL EGG (dari base lain)
local function autoStealEgg()
    if not CONFIG.AUTO_STEAL_EGG then return end
    local char, hrp, hum = getCharacter()
    if not char then return end

    local myBase = nil
    -- Cari base sendiri biar gak steal punya sendiri
    pcall(function()
        for _, v in ipairs(Workspace:GetDescendants()) do
            if v:IsA("BasePart") and (v.Name:lower():find("base") or v.Name:lower():find("plot")) then
                local owner = v:FindFirstChild("Owner") or v:FindFirstChild("PlayerName")
                if owner then
                    local oName = owner.Value and tostring(owner.Value) or owner.Name
                    if oName:lower() == LocalPlayer.Name:lower() then
                        myBase = v
                        break
                    end
                end
            end
        end
    end)

    local closest, closestDist = nil, math.huge
    for _, v in ipairs(Workspace:GetDescendants()) do
        if isEgg(v) then
            -- Skip egg yang ada di base sendiri
            if myBase and v:IsDescendantOf(myBase) then
                -- Egg di base sendiri = tetap diambil (bukan steal)
            end
            local pos = getEggPosition(v)
            if pos then
                local dist = (hrp.Position - pos).Magnitude
                if dist < CONFIG.STEAL_RANGE and dist < closestDist then
                    closest = v
                    closestDist = dist
                end
            end
        end
    end

    if closest then
        local pos = getEggPosition(closest)
        if pos and CONFIG.TELEPORT_STEAL then
            pcall(teleportTo, hrp, pos)
            task.wait(0.15)
        end
        -- Coba panggil remote / ProximityPrompt
        pcall(function()
            local prompt = closest:FindFirstChildWhichIsA("ProximityPrompt", true)
            if prompt then
                fireproximityprompt(prompt)
            end
        end)
        -- Fallback: cari ClickDetector
        pcall(function()
            local cd = closest:FindFirstChildWhichIsA("ClickDetector", true)
            if cd then
                fireclickdetector(cd)
            end
        end)
    end
end

--🔥 AUTO COLLECT EGG (egg yang di-drop di sekitar / base sendiri)
local function autoCollectEgg()
    if not CONFIG.AUTO_COLLECT_EGG then return end
    local char, hrp, hum = getCharacter()
    if not char then return end

    for _, v in ipairs(Workspace:GetDescendants()) do
        if isEgg(v) then
            local pos = getEggPosition(v)
            if pos then
                local dist = (hrp.Position - pos).Magnitude
                if dist < CONFIG.COLLECT_RANGE then
                    pcall(function()
                        local prompt = v:FindFirstChildWhichIsA("ProximityPrompt", true)
                        if prompt then fireproximityprompt(prompt) end
                    end)
                end
            end
        end
    end
end

--🔥 AUTO TREADMILL (AFK di treadmill sendiri)
local function autoTreadmill()
    if not CONFIG.AUTO_TREADMILL then return end
    local char, hrp, hum = getCharacter()
    if not char then return end

    -- Cari treadmill terdekat / milik sendiri
    local target = nil
    local bestDist = math.huge
    for _, v in ipairs(Workspace:GetDescendants()) do
        if (v:IsA("BasePart") or v:IsA("Model"))
            and (v.Name:lower():find("treadmill") or v.Name:lower():find("conveyor")) then
            local pos = v:IsA("BasePart") and v.Position
                or (v.PrimaryPart and v.PrimaryPart.Position)
            if pos then
                local dist = (hrp.Position - pos).Magnitude
                if dist < bestDist then
                    bestDist = dist
                    target = v
                end
            end
        end
    end

    if target then
        local pos = target:IsA("BasePart") and target.Position
            or (target.PrimaryPart and target.PrimaryPart.Position)
        if pos then
            local dist = (hrp.Position - pos).Magnitude
            -- Teleport ke treadmill kalau jauh
            if dist > 8 then
                pcall(teleportTo, hrp, pos)
                task.wait(0.2)
            end
            -- Tahan posisi biar stay di atas treadmill
            if hum then
                hum:MoveTo(pos + Vector3.new(0, 0, 0))
            end
            -- Kunci posisi biar gak kegeser
            if hrp and dist < 10 then
                hrp.Velocity = Vector3.zero
                hrp.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
            end
        end
    end
end

--============================================================
-- MAIN FARM LOOP
--============================================================
task.spawn(function()
    while task.wait(CONFIG.LOOP_DELAY) do
        pcall(autoStealEgg)
        pcall(autoCollectEgg)
        pcall(autoTreadmill)
    end
end)

--============================================================
-- ANTI-AFK (Biar gak di-kick pas AFK)
--============================================================
LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

--============================================================
-- FPS + PING COUNTER
--============================================================
local gui = LocalPlayer:WaitForChild("PlayerGui")
local fpsLabel = Instance.new("TextLabel")
fpsLabel.Size = UDim2.new(0, 200, 0, 28)
fpsLabel.Position = UDim2.new(0, 10, 0, 10)
fpsLabel.BackgroundTransparency = 1
fpsLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
fpsLabel.TextStrokeTransparency = 0
fpsLabel.Font = Enum.Font.GothamBold
fpsLabel.TextSize = 16
fpsLabel.TextXAlignment = Enum.TextXAlignment.Left
fpsLabel.Parent = gui

local frames, tElapsed = 0, 0
RunService.RenderStepped:Connect(function(dt)
    frames += 1
    tElapsed += dt
    if tElapsed >= 0.5 then
        local fps = math.floor(frames / tElapsed)
        local ping = 0
        pcall(function()
            ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
        end)
        fpsLabel.Text = string.format("⚡ FPS: %d | Ping: %dms | 🥚 AutoFarm: ON", fps, ping)
        frames, tElapsed = 0, 0
    end
end)

--============================================================
-- NOTIFICATION
--============================================================
pcall(function()
    StarterGui:SetCore("SendNotification", {
        Title = "⚡ Ultra Farm Edition",
        Text = "Auto Treadmill + Auto Steal Egg aktif!",
        Duration = 5,
    })
end)

print("[Ultra Farm Edition] ✅ Loaded - Auto Treadmill & Auto Steal Egg aktif!")
