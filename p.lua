--[[
    ⚡ Steal An Egg V2 - Ultra Farm Edition v2 FINAL ⚡
    Features:
    - Ultra FPS Boost + Smart Object Cleaner
    - Auto Treadmill + Auto Steal Egg + Auto Collect Egg
    - Anti-Kick + Auto Rejoin
    - Anti-AFK 3 Lapis
    - Stealth Mode
    - Toggle GUI (Draggable + Minimize + Close)
    - Auto Go To Base Sendiri
    - Server Hop
    - Config Save/Load
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
local Players         = game:GetService("Players")
local Lighting        = game:GetService("Lighting")
local RunService      = game:GetService("RunService")
local StarterGui      = game:GetService("StarterGui")
local Stats           = game:GetService("Stats")
local VirtualUser     = game:GetService("VirtualUser")
local TeleportService = game:GetService("TeleportService")
local HttpService     = game:GetService("HttpService")
local UserInput       = game:GetService("UserInputService")
local Workspace       = workspace

local LocalPlayer = Players.LocalPlayer
local Terrain     = Workspace:FindFirstChildOfClass("Terrain")

--============================================================
-- CONFIG DEFAULT
--============================================================
local DEFAULT_CONFIG = {
    REMOVE_DECALS    = true,
    REMOVE_SOUNDS    = true,
    REMOVE_MESHES    = false,
    REMOVE_LIGHTING  = true,
    CLEAN_TERRAIN    = true,
    KEEP_CHARACTER   = true,
    AUTO_CLEANUP     = true,
    CLEANUP_INTERVAL = 30,

    AUTO_TREADMILL   = true,
    AUTO_STEAL_EGG   = true,
    AUTO_COLLECT_EGG = true,
    STEAL_RANGE      = 300,
    COLLECT_RANGE    = 50,
    LOOP_DELAY       = 0.1,
    TELEPORT_STEAL   = true,
    TELEPORT_OFFSET  = 4,

    ANTI_KICK        = true,
    ANTI_AFK         = true,
    STEALTH_MODE     = false,
    STEALTH_DELAY    = 0.5,

    AUTO_GO_BASE     = true,
    SERVER_HOP       = false,
    SAVE_CONFIG      = true,
}

--============================================================
-- CONFIG SAVE / LOAD
--============================================================
local CONFIG_FILE = "SAE_UltraFarm_Config.json"
local CONFIG = {}

local function deepCopy(t)
    local copy = {}
    for k, v in pairs(t) do copy[k] = v end
    return copy
end

local function saveConfig()
    if not CONFIG.SAVE_CONFIG then return end
    pcall(function()
        if writefile then
            writefile(CONFIG_FILE, HttpService:JSONEncode(CONFIG))
        end
    end)
end

local function loadConfig()
    local loaded = nil
    pcall(function()
        if isfile and isfile(CONFIG_FILE) then
            loaded = HttpService:JSONDecode(readfile(CONFIG_FILE))
        end
    end)
    if loaded then
        CONFIG = deepCopy(DEFAULT_CONFIG)
        for k, v in pairs(loaded) do
            if CONFIG[k] ~= nil then CONFIG[k] = v end
        end
    else
        CONFIG = deepCopy(DEFAULT_CONFIG)
    end
end

loadConfig()

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
-- AUTO FARM CORE
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

local function isEgg(obj)
    if not obj or not obj.Parent then return false end
    local name = obj.Name:lower()
    return name:find("egg") ~= nil
        and not name:find("base")
        and not name:find("treadmill")
end

local function getEggPosition(egg)
    if egg:IsA("BasePart") then return egg.Position end
    if egg:IsA("Model") then
        local pp = egg.PrimaryPart or egg:FindFirstChildWhichIsA("BasePart")
        return pp and pp.Position or nil
    end
    return nil
end

-- STEALTH TELEPORT
local function teleportTo(hrp, pos)
    if not hrp or not pos then return end
    local offset = Vector3.new(
        math.random(-CONFIG.TELEPORT_OFFSET, CONFIG.TELEPORT_OFFSET),
        0,
        math.random(-CONFIG.TELEPORT_OFFSET, CONFIG.TELEPORT_OFFSET)
    )
    local target = pos + offset + Vector3.new(0, 3, 0)
    if CONFIG.STEALTH_MODE then
        local start = hrp.Position
        local steps = 5
        for i = 1, steps do
            local alpha = i / steps
            hrp.CFrame = CFrame.new(start:Lerp(target, alpha))
            task.wait(CONFIG.STEALTH_DELAY / steps)
        end
    else
        hrp.CFrame = CFrame.new(target)
    end
end

-- AUTO STEAL EGG
local cachedMyBase = nil
local function getMyBase()
    if cachedMyBase and cachedMyBase.Parent then return cachedMyBase end
    local found = nil
    pcall(function()
        for _, v in ipairs(Workspace:GetDescendants()) do
            if v:IsA("BasePart") and (v.Name:lower():find("base") or v.Name:lower():find("plot")) then
                local owner = v:FindFirstChild("Owner") or v:FindFirstChild("PlayerName")
                if owner then
                    local oName = owner.Value and tostring(owner.Value) or owner.Name
                    if oName:lower() == LocalPlayer.Name:lower() then
                        found = v
                        break
                    end
                end
            end
        end
    end)
    cachedMyBase = found
    return found
end

local function autoStealEgg()
    if not CONFIG.AUTO_STEAL_EGG then return end
    local char, hrp, hum = getCharacter()
    if not char then return end

    local myBase = getMyBase()
    local closest, closestDist = nil, math.huge

    for _, v in ipairs(Workspace:GetDescendants()) do
        if isEgg(v) then
            if not (myBase and v:IsDescendantOf(myBase)) then
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
    end

    if closest then
        local pos = getEggPosition(closest)
        if pos and CONFIG.TELEPORT_STEAL then
            pcall(teleportTo, hrp, pos)
            task.wait(CONFIG.STEALTH_MODE and 0.3 or 0.15)
        end
        pcall(function()
            local prompt = closest:FindFirstChildWhichIsA("ProximityPrompt", true)
            if prompt then fireproximityprompt(prompt) end
        end)
        pcall(function()
            local cd = closest:FindFirstChildWhichIsA("ClickDetector", true)
            if cd then fireclickdetector(cd) end
        end)
    end
end

-- AUTO COLLECT EGG
local function autoCollectEgg()
    if not CONFIG.AUTO_COLLECT_EGG then return end
    local char, hrp, hum = getCharacter()
    if not char then return end

    for _, v in ipairs(Workspace:GetDescendants()) do
        if isEgg(v) then
            local pos = getEggPosition(v)
            if pos and (hrp.Position - pos).Magnitude < CONFIG.COLLECT_RANGE then
                pcall(function()
                    local prompt = v:FindFirstChildWhichIsA("ProximityPrompt", true)
                    if prompt then fireproximityprompt(prompt) end
                end)
            end
        end
    end
end

-- AUTO TREADMILL
local function autoTreadmill()
    if not CONFIG.AUTO_TREADMILL then return end
    local char, hrp, hum = getCharacter()
    if not char then return end

    local target, bestDist = nil, math.huge
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
            if bestDist > 8 then
                pcall(teleportTo, hrp, pos)
                task.wait(CONFIG.STEALTH_MODE and 0.4 or 0.2)
            end
            if hrp and bestDist < 10 then
                hrp.Velocity = Vector3.zero
                hrp.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
            end
        end
    end
end

-- AUTO GO TO BASE
local function autoGoToBase()
    if not CONFIG.AUTO_GO_BASE then return end
    local char, hrp, hum = getCharacter()
    if not char then return end
    local base = getMyBase()
    if base then
        local pos = base:IsA("BasePart") and base.Position
            or (base.PrimaryPart and base.PrimaryPart.Position)
        if pos then
            local dist = (hrp.Position - pos).Magnitude
            if dist > 500 then
                pcall(teleportTo, hrp, pos)
                task.wait(0.3)
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
        pcall(autoGoToBase)
    end
end)

--============================================================
-- SAFETY 1: ANTI-KICK + AUTO REJOIN
--============================================================
if CONFIG.ANTI_KICK then
    local lastServer = game.JobId
    local lastPlace  = game.PlaceId

    task.spawn(function()
        while task.wait(5) do
            lastServer = game.JobId
            lastPlace  = game.PlaceId
        end
    end)

    LocalPlayer.OnTeleport:Connect(function(state)
        if state == Enum.TeleportState.Started then
            pcall(saveConfig)
        end
    end)

    pcall(function()
        game:GetService("CoreGui").ChildAdded:Connect(function(g)
            if g.Name == "RobloxPromptGui" then
                local prompt = g:FindFirstChild("promptOverlay")
                if prompt then
                    prompt.DescendantAdded:Connect(function(d)
                        if d.Name == "ErrorMessage" then
                            task.wait(3)
                            pcall(function()
                                TeleportService:TeleportToPlaceInstance(lastPlace, lastServer, LocalPlayer)
                            end)
                        end
                    end)
                end
            end
        end)
    end)
end

--============================================================
-- SAFETY 2: ANTI-AFK 3 LAPIS
--============================================================
if CONFIG.ANTI_AFK then
    LocalPlayer.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)

    task.spawn(function()
        while task.wait(30) do
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new(0, 0))
            end)
        end
    end)

    task.spawn(function()
        while task.wait(60) do
            pcall(function()
                local mouse = LocalPlayer:GetMouse()
                if mouse then
                    mouse.X = mouse.X + math.random(-5, 5)
                    mouse.Y = mouse.Y + math.random(-5, 5)
                end
            end)
        end
    end)
end

--============================================================
-- UTILITY: SERVER HOP
--============================================================
local function serverHop()
    pcall(function()
        local api = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
        local data = HttpService:JSONDecode(game:HttpGet(api))
        for _, srv in ipairs(data.data) do
            if srv.playing < srv.maxPlayers and srv.id ~= game.JobId then
                pcall(saveConfig)
                TeleportService:TeleportToPlaceInstance(game.PlaceId, srv.id, LocalPlayer)
                return
            end
        end
    end)
end

if CONFIG.SERVER_HOP then
    task.spawn(function()
        while task.wait(60) do
            pcall(function()
                local ping = Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
                if ping > 500 then
                    serverHop()
                end
            end)
        end
    end)
end

--============================================================
-- FPS + PING COUNTER
--============================================================
local gui = LocalPlayer:WaitForChild("PlayerGui")
local fpsLabel = Instance.new("TextLabel")
fpsLabel.Size = UDim2.new(0, 260, 0, 28)
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
        local mode = CONFIG.STEALTH_MODE and "STEALTH" or "NORMAL"
        fpsLabel.Text = string.format("⚡ FPS: %d | Ping: %dms | Mode: %s", fps, ping, mode)
        frames, tElapsed = 0, 0
    en
