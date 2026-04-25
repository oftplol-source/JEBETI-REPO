-- Jebe.lua v2.0.0 - Complete Criminality Script
-- Automatic folder system, 50+ features, zero setup required

local Library = {}

-- Wait for game to load
repeat task.wait() until game:IsLoaded()

-- Get services safely
local success, UserInputService = pcall(function() return game:GetService("UserInputService") end)
if not success then error("Failed to get UserInputService") end

local success, TweenService = pcall(function() return game:GetService("TweenService") end)
if not success then error("Failed to get TweenService") end

local success, RunService = pcall(function() return game:GetService("RunService") end)
if not success then error("Failed to get RunService") end

-- Wait for LocalPlayer to exist
local Players = game:GetService("Players")
repeat task.wait() until Players.LocalPlayer
local LocalPlayer = Players.LocalPlayer

-- Wait for character
repeat task.wait() until LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

local Mouse = LocalPlayer:GetMouse()

local CoreGui = (gethui and gethui()) or game:GetService("CoreGui")

local Colors = {
    Main = Color3.fromRGB(12, 12, 12),
    Accent = Color3.fromRGB(255, 255, 255),
    Border = Color3.fromRGB(40, 40, 40),
    Text = Color3.fromRGB(230, 230, 230),
    DarkText = Color3.fromRGB(150, 150, 150),
    Element = Color3.fromRGB(18, 18, 18),
    GroupBorder = Color3.fromRGB(30, 30, 30)
}

local RainbowAccent = false
local AccentElements = {} -- Store all elements that use accent color
local ToggleBoxes = {} -- Store toggle boxes with their state
local Logs = false -- Controls all print/warn output

local function UpdateAccentColor(newColor)
    Colors.Accent = newColor
    
    -- Update all tracked accent elements
    for _, element in ipairs(AccentElements) do
        if element and element.Parent then
            if element:IsA("TextLabel") or element:IsA("TextButton") then
                element.TextColor3 = newColor
            else
                element.BackgroundColor3 = newColor
            end
        end
    end
    
    -- Update toggle boxes (only enabled ones)
    for _, data in ipairs(ToggleBoxes) do
        if data.box and data.box.Parent and data.getState() then
            data.box.BackgroundColor3 = newColor
        end
    end
    
    -- Update ESP colors (only if ESP table exists)
    if ESP then
        ESP.BoxColor = newColor
    end
    
    -- Update notification accent line
    local notifGui = CoreGui:FindFirstChild("JebeNotificationsGui")
    if notifGui and notifGui:FindFirstChild("Holder") then
        for _, container in ipairs(notifGui.Holder:GetChildren()) do
            if container:IsA("Frame") then
                local notify = container:FindFirstChild("Notify")
                if notify then
                    local accentLine = notify:FindFirstChild("Frame")
                    if accentLine then
                        accentLine.BackgroundColor3 = newColor
                    end
                end
            end
        end
    end
end

-- Rainbow accent loop
local RainbowRunning = true
task.spawn(function()
    local hue = 0
    while RainbowRunning do
        if RainbowAccent then
            hue = (hue + 0.5) % 360
            local newColor = Color3.fromHSV(hue / 360, 1, 1)
            UpdateAccentColor(newColor)
        end
        task.wait(0.03)
    end
end)

local Font = Enum.Font.Ubuntu
local TextSize = 13
local CurrentFont = "Ubuntu"

-- Hitsound & Killsound System
local SoundSystem = {
    Hitsound = {
        Enabled = false,
        Volume = 0.5,
        Cooldown = 0.1,
        LastPlayed = 0,
        CurrentSound = "None",
        SoundObject = nil
    },
    Killsound = {
        Enabled = false,
        Volume = 0.5,
        CurrentSound = "None",
        SoundObject = nil
    }
}

-- Config System
local ConfigSystem = {
    CurrentConfig = "default"
}

-- Initialize main tables BEFORE config functions to prevent nil errors
local ESP = {
    Enabled = false,
    Boxes = false,
    Names = false,
    Distances = false,
    HealthBars = false,
    Images = false,
    ImageTransparency = 0,
    TeamCheck = false,
    BoxColor = Color3.fromRGB(255, 255, 255),
    NameColor = Color3.fromRGB(255, 255, 255),
    DistColor = Color3.fromRGB(255, 255, 255),
    HealthLowColor = Color3.fromRGB(255, 100, 100),
    HealthFullColor = Color3.fromRGB(100, 255, 100),
    Players = {},
    allDrawingObjects = {}
}

local WorldESP = {
    Enabled = false,
    Dealers = false,
    RebelDealer = false,
    Airdrops = false,
    RareCrates = false,
    CopeCoins = false,
    MysteryBoxes = false,
    Names = false,
    Distances = false,
    DealerColor = Color3.fromRGB(100, 200, 255),
    RebelColor = Color3.fromRGB(0, 255, 0),
    AirdropColor = Color3.fromRGB(150, 30, 255),
    RareCrateColor = Color3.fromRGB(255, 0, 0),
    CopeCoinColor = Color3.fromRGB(150, 255, 0),
    MysteryBoxColor = Color3.fromRGB(255, 255, 0),
    Objects = {},
    SpecificDealers = {}
}

local SilentAim = {
    Enabled = false,
    FOV = 100,
    TargetPart = "Head",
    HitChance = 100,
    UseHitChance = false,
    Wallbang = false,
    CheckTeam = false,
    DrawCircle = false,
    CircleColor = Color3.fromRGB(255, 255, 255),
    CurrentTarget = nil,
    Task = nil,
    VisualizeConnection = nil
}

local MeleeAura = {
    Enabled = false,
    Distance = 15,
    ShowAnimation = true,
    CheckTeam = false,
    CurrentTarget = nil
}

local Aimbot = {
    Enabled = false,
    FOV = 100,
    Smoothing = 0.5,
    TargetPart = "Head",
    CheckWalls = false,
    CheckTeam = false,
    DrawCircle = false,
    CurrentTarget = nil
}

local CharacterMods = {
    WalkspeedEnabled = false,
    WalkspeedValue = 35,
    NoclipEnabled = false,
    InfiniteStaminaEnabled = false,
    NoJumpCooldown = false,
    NoFallDamage = false,
    NoRagdoll = false
}

local GunMods = {
    Enabled = false,
    NoRecoil = false,
    NoSpread = false,
    FastEquip = false,
    FireRateMultiplier = 1,
    AutomaticAll = false
}

local AutoPickup = {
    Enabled = false,
    PickupCash = false,
    PickupPiles = false,
    LastPickup = 0,
    Cooldown = 5.1
}

local HitboxExpander = {
    Enabled = false,
    Size = 10,
    Transparency = 0.5
}

local FOVChanger = {
    Enabled = false,
    FOV = 90
}

local ExtendedZoom = {
    Enabled = false,
    MaxDistance = 50
}

local Fullbright = {
    Enabled = false
}

-- Placeholder for image file selection
local SelectedImageFile = "image.png"

local function GetDefaultConfig()
    return {
        -- Silent Aim
        SilentAim_Enabled = false,
        SilentAim_FOV = 100,
        SilentAim_TargetPart = "Head",
        SilentAim_HitChance = 100,
        SilentAim_UseHitChance = false,
        SilentAim_Wallbang = false,
        SilentAim_CheckTeam = false,
        SilentAim_DrawCircle = false,
        
        -- ESP
        ESP_Enabled = false,
        ESP_Boxes = false,
        ESP_Names = false,
        ESP_Distances = false,
        ESP_HealthBars = false,
        ESP_Images = false,
        ESP_ImageTransparency = 0,
        ESP_TeamCheck = false,
        
        -- World ESP
        WorldESP_Enabled = false,
        WorldESP_Dealers = false,
        WorldESP_RebelDealer = false,
        WorldESP_Airdrops = false,
        WorldESP_RareCrates = false,
        WorldESP_CopeCoins = false,
        WorldESP_MysteryBoxes = false,
        WorldESP_Names = false,
        WorldESP_Distances = false,
        
        -- Sounds
        Hitsound_Enabled = false,
        Hitsound_Volume = 0.5,
        Hitsound_Cooldown = 0.1,
        Hitsound_CurrentSound = "None",
        Killsound_Enabled = false,
        Killsound_Volume = 0.5,
        Killsound_CurrentSound = "None",
        
        -- UI
        RainbowAccent = false,
        Logs = false,
        CurrentFont = "Ubuntu",
        SelectedImageFile = "image.png"
    }
end

local function SaveConfig(configName)
    if not writefile then
        Library:Notify("writefile not supported", 3)
        return
    end
    
    local config = {
        -- Silent Aim
        SilentAim_Enabled = SilentAim.Enabled,
        SilentAim_FOV = SilentAim.FOV,
        SilentAim_TargetPart = SilentAim.TargetPart,
        SilentAim_HitChance = SilentAim.HitChance,
        SilentAim_UseHitChance = SilentAim.UseHitChance,
        SilentAim_Wallbang = SilentAim.Wallbang,
        SilentAim_CheckTeam = SilentAim.CheckTeam,
        SilentAim_DrawCircle = SilentAim.DrawCircle,
        
        -- ESP
        ESP_Enabled = ESP.Enabled,
        ESP_Boxes = ESP.Boxes,
        ESP_Names = ESP.Names,
        ESP_Distances = ESP.Distances,
        ESP_HealthBars = ESP.HealthBars,
        ESP_Images = ESP.Images,
        ESP_ImageTransparency = ESP.ImageTransparency,
        ESP_TeamCheck = ESP.TeamCheck,
        
        -- World ESP
        WorldESP_Enabled = WorldESP.Enabled,
        WorldESP_Dealers = WorldESP.Dealers,
        WorldESP_RebelDealer = WorldESP.RebelDealer,
        WorldESP_Airdrops = WorldESP.Airdrops,
        WorldESP_RareCrates = WorldESP.RareCrates,
        WorldESP_CopeCoins = WorldESP.CopeCoins,
        WorldESP_MysteryBoxes = WorldESP.MysteryBoxes,
        WorldESP_Names = WorldESP.Names,
        WorldESP_Distances = WorldESP.Distances,
        
        -- Sounds
        Hitsound_Enabled = SoundSystem.Hitsound.Enabled,
        Hitsound_Volume = SoundSystem.Hitsound.Volume,
        Hitsound_Cooldown = SoundSystem.Hitsound.Cooldown,
        Hitsound_CurrentSound = SoundSystem.Hitsound.CurrentSound,
        Killsound_Enabled = SoundSystem.Killsound.Enabled,
        Killsound_Volume = SoundSystem.Killsound.Volume,
        Killsound_CurrentSound = SoundSystem.Killsound.CurrentSound,
        
        -- UI
        RainbowAccent = RainbowAccent,
        Logs = Logs,
        CurrentFont = CurrentFont,
        SelectedImageFile = SelectedImageFile
    }
    
    local success, encoded = pcall(function()
        return game:GetService("HttpService"):JSONEncode(config)
    end)
    
    if success then
        writefile("Jebe/Configs/" .. configName .. ".json", encoded)
        Library:Notify("saved config: " .. configName, 3)
        if Logs then print("Jebe: Saved config " .. configName) end
    else
        Library:Notify("failed to save config", 3)
        if Logs then warn("Jebe: Failed to encode config") end
    end
end

local function LoadConfig(configName)
    if not readfile or not isfile then
        Library:Notify("readfile not supported", 3)
        return
    end
    
    local path = "Jebe/Configs/" .. configName .. ".json"
    if not isfile(path) then
        Library:Notify("config not found: " .. configName, 3)
        return
    end
    
    local success, content = pcall(function()
        return readfile(path)
    end)
    
    if not success then
        Library:Notify("failed to read config", 3)
        return
    end
    
    local decoded
    success, decoded = pcall(function()
        return game:GetService("HttpService"):JSONDecode(content)
    end)
    
    if not success or type(decoded) ~= "table" then
        Library:Notify("failed to decode config", 3)
        return
    end
    
    -- Apply config
    -- Silent Aim
    SilentAim.Enabled = decoded.SilentAim_Enabled or false
    SilentAim.FOV = decoded.SilentAim_FOV or 100
    SilentAim.TargetPart = decoded.SilentAim_TargetPart or "Head"
    SilentAim.HitChance = decoded.SilentAim_HitChance or 100
    SilentAim.UseHitChance = decoded.SilentAim_UseHitChance or false
    SilentAim.Wallbang = decoded.SilentAim_Wallbang or false
    SilentAim.CheckTeam = decoded.SilentAim_CheckTeam or false
    SilentAim.DrawCircle = decoded.SilentAim_DrawCircle or false
    
    -- ESP
    ESP.Enabled = decoded.ESP_Enabled or false
    ESP.Boxes = decoded.ESP_Boxes or false
    ESP.Names = decoded.ESP_Names or false
    ESP.Distances = decoded.ESP_Distances or false
    ESP.HealthBars = decoded.ESP_HealthBars or false
    ESP.Images = decoded.ESP_Images or false
    ESP.ImageTransparency = decoded.ESP_ImageTransparency or 0
    ESP.TeamCheck = decoded.ESP_TeamCheck or false
    
    -- World ESP
    WorldESP.Enabled = decoded.WorldESP_Enabled or false
    WorldESP.Dealers = decoded.WorldESP_Dealers or false
    WorldESP.RebelDealer = decoded.WorldESP_RebelDealer or false
    WorldESP.Airdrops = decoded.WorldESP_Airdrops or false
    WorldESP.RareCrates = decoded.WorldESP_RareCrates or false
    WorldESP.CopeCoins = decoded.WorldESP_CopeCoins or false
    WorldESP.MysteryBoxes = decoded.WorldESP_MysteryBoxes or false
    WorldESP.Names = decoded.WorldESP_Names or false
    WorldESP.Distances = decoded.WorldESP_Distances or false
    
    -- Sounds
    SoundSystem.Hitsound.Enabled = decoded.Hitsound_Enabled or false
    SoundSystem.Hitsound.Volume = decoded.Hitsound_Volume or 0.5
    SoundSystem.Hitsound.Cooldown = decoded.Hitsound_Cooldown or 0.1
    SoundSystem.Hitsound.CurrentSound = decoded.Hitsound_CurrentSound or "None"
    SoundSystem.Killsound.Enabled = decoded.Killsound_Enabled or false
    SoundSystem.Killsound.Volume = decoded.Killsound_Volume or 0.5
    SoundSystem.Killsound.CurrentSound = decoded.Killsound_CurrentSound or "None"
    
    -- UI
    RainbowAccent = decoded.RainbowAccent or false
    Logs = decoded.Logs or false
    CurrentFont = decoded.CurrentFont or "Ubuntu"
    SelectedImageFile = decoded.SelectedImageFile or "image.png"
    
    -- Load sounds
    if SoundSystem.Hitsound.CurrentSound ~= "None" then
        LoadHitsound(SoundSystem.Hitsound.CurrentSound)
    end
    if SoundSystem.Killsound.CurrentSound ~= "None" then
        LoadKillsound(SoundSystem.Killsound.CurrentSound)
    end
    
    Library:Notify("loaded config: " .. configName, 3)
    if Logs then print("Jebe: Loaded config " .. configName) end
end

local function DeleteConfig(configName)
    if not delfile or not isfile then
        Library:Notify("delfile not supported", 3)
        return
    end
    
    local path = "Jebe/Configs/" .. configName .. ".json"
    if not isfile(path) then
        Library:Notify("config not found: " .. configName, 3)
        return
    end
    
    delfile(path)
    Library:Notify("deleted config: " .. configName, 3)
    if Logs then print("Jebe: Deleted config " .. configName) end
end

local function GetConfigList()
    local configs = {}
    if listfiles then
        local files = listfiles("Jebe/Configs")
        for _, file in ipairs(files) do
            local fileName = file:match("Jebe[\\/]Configs[\\/](.+)%.json$")
            if fileName then
                table.insert(configs, fileName)
            end
        end
    end
    table.sort(configs)
    return configs
end

local function ResetToDefault()
    local default = GetDefaultConfig()
    
    -- Silent Aim
    SilentAim.Enabled = default.SilentAim_Enabled
    SilentAim.FOV = default.SilentAim_FOV
    SilentAim.TargetPart = default.SilentAim_TargetPart
    SilentAim.HitChance = default.SilentAim_HitChance
    SilentAim.UseHitChance = default.SilentAim_UseHitChance
    SilentAim.Wallbang = default.SilentAim_Wallbang
    SilentAim.CheckTeam = default.SilentAim_CheckTeam
    SilentAim.DrawCircle = default.SilentAim_DrawCircle
    
    -- ESP
    ESP.Enabled = default.ESP_Enabled
    ESP.Boxes = default.ESP_Boxes
    ESP.Names = default.ESP_Names
    ESP.Distances = default.ESP_Distances
    ESP.HealthBars = default.ESP_HealthBars
    ESP.Images = default.ESP_Images
    ESP.ImageTransparency = default.ESP_ImageTransparency
    ESP.TeamCheck = default.ESP_TeamCheck
    
    -- World ESP
    WorldESP.Enabled = default.WorldESP_Enabled
    WorldESP.Dealers = default.WorldESP_Dealers
    WorldESP.RebelDealer = default.WorldESP_RebelDealer
    WorldESP.Airdrops = default.WorldESP_Airdrops
    WorldESP.RareCrates = default.WorldESP_RareCrates
    WorldESP.CopeCoins = default.WorldESP_CopeCoins
    WorldESP.MysteryBoxes = default.WorldESP_MysteryBoxes
    WorldESP.Names = default.WorldESP_Names
    WorldESP.Distances = default.WorldESP_Distances
    
    -- Sounds
    SoundSystem.Hitsound.Enabled = default.Hitsound_Enabled
    SoundSystem.Hitsound.Volume = default.Hitsound_Volume
    SoundSystem.Hitsound.Cooldown = default.Hitsound_Cooldown
    SoundSystem.Hitsound.CurrentSound = default.Hitsound_CurrentSound
    SoundSystem.Killsound.Enabled = default.Killsound_Enabled
    SoundSystem.Killsound.Volume = default.Killsound_Volume
    SoundSystem.Killsound.CurrentSound = default.Killsound_CurrentSound
    
    -- UI
    RainbowAccent = default.RainbowAccent
    Logs = default.Logs
    CurrentFont = default.CurrentFont
    SelectedImageFile = default.SelectedImageFile
    
    Library:Notify("reset to default config", 3)
    if Logs then print("Jebe: Reset to default config") end
end

local function GetAllFonts()
    return {
        "Ubuntu", "SourceSans", "SourceSansBold", "SourceSansItalic", "SourceSansLight",
        "SourceSansSemibold", "Gotham", "GothamBold", "GothamBlack", "GothamMedium",
        "Roboto", "RobotoMono", "RobotoCondensed", "Arcade", "Fantasy", "Antique",
        "Arial", "ArialBold", "Code", "Highway", "SciFi", "Cartoon", "Bodoni",
        "Garamond", "Jura", "Merriweather", "Michroma", "Nunito", "Oswald", "PatrickHand"
    }
end

local function LoadSoundAsset(path)
    if isfile and isfile(path) then
        if getcustomasset then
            return getcustomasset(path)
        end
    end
    return nil
end

local function ScanSoundFiles(folder)
    local sounds = {"None"}
    if listfiles then
        local files = listfiles("Jebe/Sounds/" .. folder)
        for _, file in ipairs(files) do
            local fileName = file:match("Jebe[\\/]Sounds[\\/]" .. folder .. "[\\/](.+)$") or file:match("([^\\/]+)$")
            if fileName and (fileName:lower():match("%.mp3$") or fileName:lower():match("%.ogg$") or fileName:lower():match("%.wav$")) then
                table.insert(sounds, fileName)
            end
        end
    end
    table.sort(sounds)
    return sounds
end

local function PlayHitsound()
    if not SoundSystem.Hitsound.Enabled then return end
    if SoundSystem.Hitsound.CurrentSound == "None" then return end
    
    local now = tick()
    if now - SoundSystem.Hitsound.LastPlayed < SoundSystem.Hitsound.Cooldown then return end
    
    if SoundSystem.Hitsound.SoundObject then
        SoundSystem.Hitsound.SoundObject.Volume = SoundSystem.Hitsound.Volume
        SoundSystem.Hitsound.SoundObject:Play()
        SoundSystem.Hitsound.LastPlayed = now
    end
end

local function PlayKillsound()
    if not SoundSystem.Killsound.Enabled then return end
    if SoundSystem.Killsound.CurrentSound == "None" then return end
    
    if SoundSystem.Killsound.SoundObject then
        SoundSystem.Killsound.SoundObject.Volume = SoundSystem.Killsound.Volume
        SoundSystem.Killsound.SoundObject:Play()
    end
end

local function LoadHitsound(soundName)
    if SoundSystem.Hitsound.SoundObject then
        SoundSystem.Hitsound.SoundObject:Destroy()
        SoundSystem.Hitsound.SoundObject = nil
    end
    
    if soundName == "None" then return end
    
    local soundAsset = LoadSoundAsset("Jebe/Sounds/Hitsounds/" .. soundName)
    if soundAsset then
        local sound = Instance.new("Sound")
        sound.SoundId = soundAsset
        sound.Volume = SoundSystem.Hitsound.Volume
        sound.Parent = game:GetService("SoundService")
        SoundSystem.Hitsound.SoundObject = sound
        if Logs then print("Jebe: Loaded hitsound " .. soundName) end
    else
        if Logs then warn("Jebe: Failed to load hitsound " .. soundName) end
    end
end

local function LoadKillsound(soundName)
    if SoundSystem.Killsound.SoundObject then
        SoundSystem.Killsound.SoundObject:Destroy()
        SoundSystem.Killsound.SoundObject = nil
    end
    
    if soundName == "None" then return end
    
    local soundAsset = LoadSoundAsset("Jebe/Sounds/Killsounds/" .. soundName)
    if soundAsset then
        local sound = Instance.new("Sound")
        sound.SoundId = soundAsset
        sound.Volume = SoundSystem.Killsound.Volume
        sound.Parent = game:GetService("SoundService")
        SoundSystem.Killsound.SoundObject = sound
        if Logs then print("Jebe: Loaded killsound " .. soundName) end
    else
        if Logs then warn("Jebe: Failed to load killsound " .. soundName) end
    end
end

-- ESP system already initialized at top of script

local DealerConfigs = {
    Armory = {
        {CFrame = CFrame.new(-4770.10547, 3.61220169, -423.312195, -1, 0, 0, 0, 1, 0, 0, 0, -1), Name = "Armory1"},
        {CFrame = CFrame.new(-4208.00977, 3.9639554, -186.739517, 0, 0, -1, 0, 1, 0, 1, 0, 0), Name = "Armory2"}
    },
    Normal = {
        {CFrame = CFrame.new(-4604.64502, -32.7113342, -698.740417, 0, 0, -1, 0, 1, 0, 1, 0, 0), Name = "Dealer1"},
        {CFrame = CFrame.new(-4978.23926, 3.38852358, -35.3433456, 0, 0, 1, 0, 1, -0, -1, 0, 0), Name = "Dealer2"},
        {CFrame = CFrame.new(-4460.354, 3.38851929, -535.605164, 0, 0, -1, 0, 1, 0, 1, 0, 0), Name = "Dealer3"},
        {CFrame = CFrame.new(-4203.6709, 3.62495112, -552.636108, -1, 0, 0, 0, 1, 0, 0, 0, -1), Name = "Dealer4"},
        {CFrame = CFrame.new(-4816.15039, 3.38848877, -711.441406, 0, 0, 1, 0, 1, -0, -1, 0, 0), Name = "Dealer5"},
        {CFrame = CFrame.new(-3893.95044, 3.48849487, -165.34137, 0, 0, -1, 0, 1, 0, 1, 0, 0), Name = "Dealer6"},
        {CFrame = CFrame.new(-4264.10791, 3.49859619, 95.2240372, 0, 0, 1, 0, 1, -0, -1, 0, 0), Name = "Dealer7"},
        {CFrame = CFrame.new(-4488.21387, 3.48855591, -1152.18933, 0, 0, -1, 0, 1, 0, 1, 0, 0), Name = "Dealer8"},
        {CFrame = CFrame.new(-4517.01562, 3.48858643, -82.6485367, 0, 0, -1, 0, 1, 0, 1, 0, 0), Name = "Dealer9"},
        {CFrame = CFrame.new(-4122.08252, -93.6874847, -701.489319, 1, 0, 0, 0, 1, 0, 0, 0, 1), Name = "Dealer10"},
        {CFrame = CFrame.new(-4144.57812, -89.2114258, 25.7110004, 0, 0, 1, 0, 1, -0, -1, 0, 0), Name = "Dealer11"}
    }
}

local function GetDealerInfo(model)
    local pivot = model:GetPivot()
    for cat, list in pairs(DealerConfigs) do
        for _, data in ipairs(list) do
            if (data.CFrame.Position - pivot.Position).Magnitude < 0.5 then
                return data.Name, cat
            end
        end
    end
    return nil
end

-- Folder Management System
local FolderStructure = {
    "Jebe",
    "Jebe/Configs",
    "Jebe/Fonts",
    "Jebe/Images",
    "Jebe/Sounds",
    "Jebe/Sounds/Hitsounds",
    "Jebe/Sounds/Killsounds"
}

local function EnsureFoldersExist()
    if not makefolder or not isfolder then
        if Logs then warn("Jebe: Folder functions not supported by executor") end
        return false
    end
    
    local allCreated = true
    for _, folderPath in ipairs(FolderStructure) do
        if not isfolder(folderPath) then
            local success, err = pcall(function()
                makefolder(folderPath)
            end)
            
            if success then
                if Logs then print("Jebe: Created folder: " .. folderPath) end
            else
                if Logs then warn("Jebe: Failed to create folder: " .. folderPath .. " - " .. tostring(err)) end
                allCreated = false
            end
        else
            if Logs then print("Jebe: Folder exists: " .. folderPath) end
        end
    end
    
    return allCreated
end

-- Create/verify folders on every execution
local foldersReady = EnsureFoldersExist()

if foldersReady then
    if Logs then print("Jebe: All folders verified/created successfully") end
else
    if Logs then warn("Jebe: Some folders could not be created - some features may not work") end
end

local function LoadAsset(path)
    if isfile and isfile(path) then
        if getcustomasset then
            return getcustomasset(path)
        end
    end
    return nil
end

local Connections = {}
local CustomImage = LoadAsset("Jebe/Images/image.png")

-- Create a dedicated ScreenGui for ESP images
local ESPImageGui = Instance.new("ScreenGui")
ESPImageGui.Name = "JebeESPImages"
ESPImageGui.Parent = CoreGui
ESPImageGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ESPImageGui.IgnoreGuiInset = true
ESPImageGui.ResetOnSpawn = false

if CustomImage then
    if Logs then print("Jebe: image.png found and loaded!") end
    if Logs then print("Asset ID:", CustomImage) end
else
    if Logs then warn("Jebe: image.png NOT found at 'Jebe/image.png' or getcustomasset missing.") end
end

-- VaderHaxx ESP Default Properties (EXACT COPY)
local ESPDefaultProperties = {
    outlineBox = {
        Visible = false,
        Transparency = 0.7,
        Color = Color3.fromRGB(10, 10, 10),
        Thickness = 3,
        Filled = false
    },
    box = {
        Visible = false,
        Transparency = 1,
        Color = Color3.fromRGB(255, 255, 255),
        Thickness = 1,
        Filled = false
    },
    boxFilled = {
        Visible = false,
        Transparency = 0.1,
        Color = Color3.fromRGB(255, 255, 255),
        Filled = true
    },
    healthBarBack = {
        Visible = false,
        Transparency = 0.7,
        Color = Color3.fromRGB(10, 10, 10),
        Thickness = 1,
        Filled = true
    },
    healthBarOutline = {
        Visible = false,
        Transparency = 0.7,
        Color = Color3.fromRGB(10, 10, 10),
        Filled = false,
        Thickness = 1,
    },
    healthBar = {
        Visible = false,
        Transparency = 1,
        Color = Color3.fromRGB(0, 255, 0),
        Thickness = 1,
        Filled = true
    },
    mainText = {
        Visible = false,
        Size = 13,
        Font = Drawing.Fonts.System,
        Color = Color3.fromRGB(255, 255, 255),
        Transparency = 1,
        Center = true,
        Outline = true
    }
}

-- Create drawing object helper for ESP
local function CreateESPDrawing(type, prop)
    local obj = Drawing.new(type)
    if prop then
        for index, value in pairs(prop) do
            obj[index] = value
        end
    end
    obj.ZIndex = -1
    table.insert(ESP.allDrawingObjects, obj)
    return obj
end

-- Get VaderHaxx bounding box (EXACT COPY from VaderHaxx getBoundingBox function)
local function GetVaderBoundingBox(character)
    if not character or not character:FindFirstChild("HumanoidRootPart") or not character:FindFirstChild("Head") then
        return nil
    end
    
    local rootPart = character.HumanoidRootPart
    local head = character.Head
    local leftLeg = character:FindFirstChild("Left Leg") or character:FindFirstChild("LeftLowerLeg")
    local rightLeg = character:FindFirstChild("Right Leg") or character:FindFirstChild("RightLowerLeg")
    
    -- VaderHaxx method - calculate top and bottom points
    local rootCf = rootPart.CFrame
    local headCf = head.CFrame
    
    -- real (from VaderHaxx)
    local cfupvec = rootCf.Position + rootCf.UpVector * 2
    local upvec = rootCf.Position + Vector3.new(0, cfupvec.Y - rootCf.Position.Y, 0) + workspace.CurrentCamera.CFrame.UpVector * 0.55

    local cfdownvec = rootCf.Position - rootCf.UpVector * 3
    cfdownvec = rootCf.Position + Vector3.new(0, cfdownvec.Y - rootCf.Position.Y, 0)

    -- For standard Roblox, calculate leg position
    local legdown
    if leftLeg and rightLeg then
        local llegCf = leftLeg.CFrame
        local rlegCf = rightLeg.CFrame
        legdown = (rlegCf.Position - rlegCf.UpVector + llegCf.Position - llegCf.UpVector) / 2
    else
        -- Fallback for R15 or missing legs
        legdown = rootCf.Position - Vector3.new(0, rootPart.Size.Y/2 + 2.5, 0)
    end
    
    local bovec = (legdown.Y < cfdownvec.Y and cfdownvec - Vector3.new(0, cfdownvec.Y, 0) + Vector3.new(0, legdown.Y, 0) or cfdownvec) - workspace.CurrentCamera.CFrame.UpVector * 0.64

    local top, topOnScreen = workspace.CurrentCamera:WorldToViewportPoint(upvec)
    local bottom, bottomOnScreen = workspace.CurrentCamera:WorldToViewportPoint(bovec)
    
    if not topOnScreen or not bottomOnScreen then
        return nil
    end

    local center = (Vector2.new(top.X, top.Y) + Vector2.new(bottom.X, bottom.Y)) / 2
    local height = math.abs(top.Y - bottom.Y)
    local width = height / 1.64 -- VaderHaxx ratio
    local size = Vector2.new(math.floor(width), math.floor(height))
    local pos = Vector2.new(math.floor(center.X - size.X / 2), math.floor(center.Y - size.Y / 2))

    return {
        Min = pos,
        Max = pos + size,
        Width = size.X,
        Height = size.Y
    }
end

-- Initialize VaderHaxx ESP objects for a player
local function InitializeVaderESPObjects()
    local objects = {}
    
    -- Box ESP 
    -- shoutout kombton ayweii and rvvz
    objects.outlineBox = {
        object = CreateESPDrawing("Square", ESPDefaultProperties.outlineBox),
        originalTransparency = ESPDefaultProperties.outlineBox.Transparency
    }
    objects.box = {
        object = CreateESPDrawing("Square", ESPDefaultProperties.box),
        originalTransparency = ESPDefaultProperties.box.Transparency
    }
    
    -- Health bar
    objects.healthBarBack = {
        object = CreateESPDrawing("Square", ESPDefaultProperties.healthBarBack),
        originalTransparency = ESPDefaultProperties.healthBarBack.Transparency
    }
    objects.healthBarOutline = {
        object = CreateESPDrawing("Square", ESPDefaultProperties.healthBarOutline),
        originalTransparency = ESPDefaultProperties.healthBarOutline.Transparency
    }
    objects.healthBar = {
        object = CreateESPDrawing("Square", ESPDefaultProperties.healthBar),
        originalTransparency = ESPDefaultProperties.healthBar.Transparency
    }
    
    -- Text objects
    objects.nameText = {
        object = CreateESPDrawing("Text", ESPDefaultProperties.mainText),
        originalTransparency = ESPDefaultProperties.mainText.Transparency
    }
    objects.distanceText = {
        object = CreateESPDrawing("Text", ESPDefaultProperties.mainText),
        originalTransparency = ESPDefaultProperties.mainText.Transparency
    }
    
    return objects
end

local function AddPlayerESP(player)
    if player == LocalPlayer then return end
    
    local objects = InitializeVaderESPObjects()
    
    -- Add image GUI for box-scaled ESP
    local imageGui = Instance.new("ImageLabel")
    imageGui.Name = "ESP_Image_" .. player.Name
    imageGui.BackgroundTransparency = 1
    imageGui.BorderSizePixel = 0
    imageGui.Visible = false
    imageGui.Image = CustomImage or ""
    imageGui.ScaleType = Enum.ScaleType.Stretch
    imageGui.ZIndex = 1
    imageGui.Parent = ESPImageGui
    
    objects.ImageGui = imageGui
    ESP.Players[player] = objects
    
    if Logs then print("Jebe: Created ImageGui for " .. player.Name) end
end

local function RemovePlayerESP(player)
    if ESP.Players[player] then
        -- Remove VaderHaxx ESP objects
        for key, container in pairs(ESP.Players[player]) do
            if key == "ImageGui" then
                -- ImageGui is a BillboardGui instance
                if container and container.Destroy then
                    pcall(function() container:Destroy() end)
                end
            elseif container and container.object then
                -- Drawing objects wrapped in containers
                pcall(function() container.object:Remove() end)
            end
        end
        ESP.Players[player] = nil
    end
end

local function CreateDraw(type, properties)
    local draw = Drawing.new(type)
    for prop, val in pairs(properties) do
        draw[prop] = val
    end
    return draw
end

local function CreateWorldDrawings(obj)
    local drawings = {
        Box = {
            outlineBox = CreateDraw("Square", {Thickness = 3, Color = Color3.fromRGB(10, 10, 10), Transparency = 0.7, Filled = false, Visible = false}),
            box = CreateDraw("Square", {Thickness = 1, Color = Color3.new(1,1,1), Transparency = 1, Filled = false, Visible = false})
        },
        Name = CreateDraw("Text", {Size = 13, Center = true, Outline = true, Color = Color3.new(1,1,1), Visible = false}),
        Dist = CreateDraw("Text", {Size = 13, Center = true, Outline = true, Color = Color3.new(1,1,1), Visible = false})
    }
    WorldESP.Objects[obj] = drawings
    return drawings
end

local function RemoveWorldDrawings(obj)
    if WorldESP.Objects[obj] then
        WorldESP.Objects[obj].Box.outlineBox:Remove()
        WorldESP.Objects[obj].Box.box:Remove()
        WorldESP.Objects[obj].Name:Remove()
        WorldESP.Objects[obj].Dist:Remove()
        WorldESP.Objects[obj] = nil
    end
end

local function ProcessObject(obj, text, color, categoryEnabled)
    if not obj then return end
    local drawings = WorldESP.Objects[obj] or CreateWorldDrawings(obj)
    
    -- If category is disabled or WorldESP is disabled, hide everything
    if not WorldESP.Enabled or not categoryEnabled then
        drawings.Box.box.Visible = false
        drawings.Box.outlineBox.Visible = false
        drawings.Name.Visible = false
        drawings.Dist.Visible = false
        return
    end
    
    local cf, size
    if obj:IsA("Model") then
        cf, size = obj:GetBoundingBox()
    else
        cf, size = obj.CFrame, obj.Size
    end
    
    local _, onScreen = workspace.CurrentCamera:WorldToViewportPoint(cf.Position)
    
    if onScreen then
        -- Use VaderHaxx bounding box method for world objects
        local parts = {}
        if obj:IsA("Model") then
            for _, part in pairs(obj:GetChildren()) do
                if part:IsA("BasePart") then
                    table.insert(parts, part)
                end
            end
        else
            table.insert(parts, obj)
        end
        
        if #parts > 0 then
            local minX, minY = math.huge, math.huge
            local maxX, maxY = -math.huge, -math.huge
            local anyOnScreen = false
            
            for _, part in pairs(parts) do
                local partCf = part.CFrame
                local partSize = part.Size
                local corners = {
                    partCf * CFrame.new(-partSize.X/2, -partSize.Y/2, -partSize.Z/2),
                    partCf * CFrame.new(partSize.X/2, -partSize.Y/2, -partSize.Z/2),
                    partCf * CFrame.new(-partSize.X/2, partSize.Y/2, -partSize.Z/2),
                    partCf * CFrame.new(partSize.X/2, partSize.Y/2, -partSize.Z/2),
                    partCf * CFrame.new(-partSize.X/2, -partSize.Y/2, partSize.Z/2),
                    partCf * CFrame.new(partSize.X/2, -partSize.Y/2, partSize.Z/2),
                    partCf * CFrame.new(-partSize.X/2, partSize.Y/2, partSize.Z/2),
                    partCf * CFrame.new(partSize.X/2, partSize.Y/2, partSize.Z/2)
                }
                
                for _, corner in pairs(corners) do
                    local screenPoint, cornerOnScreen = workspace.CurrentCamera:WorldToViewportPoint(corner.Position)
                    if cornerOnScreen then
                        anyOnScreen = true
                        minX = math.min(minX, screenPoint.X)
                        minY = math.min(minY, screenPoint.Y)
                        maxX = math.max(maxX, screenPoint.X)
                        maxY = math.max(maxY, screenPoint.Y)
                    end
                end
            end
            
            if anyOnScreen and minX ~= math.huge then
                local padding = 5
                minX = minX - padding
                minY = minY - padding
                maxX = maxX + padding
                maxY = maxY + padding
                
                local width = maxX - minX
                local height = maxY - minY
                
                -- VaderHaxx style box
                drawings.Box.box.Position = Vector2.new(math.floor(minX), math.floor(minY))
                drawings.Box.box.Size = Vector2.new(math.floor(width), math.floor(height))
                drawings.Box.box.Color = color
                drawings.Box.box.Visible = true
                
                drawings.Box.outlineBox.Position = Vector2.new(math.floor(minX), math.floor(minY))
                drawings.Box.outlineBox.Size = Vector2.new(math.floor(width), math.floor(height))
                drawings.Box.outlineBox.Visible = true
                
                if WorldESP.Names then
                    drawings.Name.Text = text:lower()
                    drawings.Name.Position = Vector2.new(minX + width/2, minY - 15)
                    drawings.Name.Visible = true
                    drawings.Name.Color = color
                else
                    drawings.Name.Visible = false
                end
                
                if WorldESP.Distances then
                    local dist = math.floor((workspace.CurrentCamera.CFrame.Position - cf.Position).Magnitude)
                    drawings.Dist.Text = tostring(dist) .. "m"
                    drawings.Dist.Position = Vector2.new(minX + width/2, maxY + 2)
                    drawings.Dist.Visible = true
                    drawings.Dist.Color = color
                else
                    drawings.Dist.Visible = false
                end
            else
                drawings.Box.box.Visible = false
                drawings.Box.outlineBox.Visible = false
                drawings.Name.Visible = false
                drawings.Dist.Visible = false
            end
        end
    else
        drawings.Box.box.Visible = false
        drawings.Box.outlineBox.Visible = false
        drawings.Name.Visible = false
        drawings.Dist.Visible = false
    end
end

-- Initialize ESP for existing players
for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
    if player ~= LocalPlayer then
        AddPlayerESP(player)
    end
end

for _, player in ipairs(game:GetService("Players"):GetPlayers()) do AddPlayerESP(player) end
table.insert(Connections, game:GetService("Players").PlayerAdded:Connect(AddPlayerESP))
table.insert(Connections, game:GetService("Players").PlayerRemoving:Connect(RemovePlayerESP))

table.insert(Connections, RunService.RenderStepped:Connect(function()
    -- VaderHaxx Player ESP Rendering
    for player, objects in pairs(ESP.Players) do
        local shouldRender = true
        
        -- First check: if ESP is disabled, hide everything immediately
        if not ESP.Enabled then
            for key, container in pairs(objects) do
                if key == "ImageGui" then
                    -- ImageGui is an ImageLabel instance
                    if container then
                        container.Visible = false
                    end
                elseif container and container.object then
                    container.object.Visible = false
                end
            end
            shouldRender = false
        end
        
        if shouldRender then
            local character = player.Character
            local humanoid = character and character:FindFirstChild("Humanoid")
            
            if character and humanoid and humanoid.Health > 0 then
                local shouldSkip = false
                
                if ESP.TeamCheck and player.Team == LocalPlayer.Team then
                    -- Hide all objects for teammates
                    for key, container in pairs(objects) do
                        if key == "ImageGui" then
                            if container then
                                container.Visible = false
                            end
                        elseif container and container.object then
                            container.object.Visible = false
                        end
                    end
                    shouldSkip = true
                end
                
                if not shouldSkip then
                -- Get VaderHaxx bounding box
                local bounds = GetVaderBoundingBox(character)
                if not bounds then
                    -- Hide all objects if no bounds (off-screen or invalid)
                    for key, container in pairs(objects) do
                        if key == "ImageGui" then
                            if container then
                                container.Visible = false
                            end
                        elseif container and container.object then
                            container.object.Visible = false
                        end
                    end
                    shouldSkip = true
                end
                
                if not shouldSkip then
                    local health = humanoid.Health
                    local maxHealth = humanoid.MaxHealth
                    local healthPercentage = health / maxHealth
                    
                    -- Box ESP (EXACT VaderHaxx style)
                    if ESP.Boxes then
                        local box = objects.box.object
                        local boxOutline = objects.outlineBox.object
                        
                        -- VaderHaxx method: set visible false first, then configure, then set visible true
                        box.Visible = false
                        boxOutline.Visible = false

                        box.Position = bounds.Min
                        box.Size = Vector2.new(bounds.Width, bounds.Height)  -- EXACT VaderHaxx method

                        boxOutline.Position = box.Position
                        boxOutline.Size = box.Size

                        box.Color = ESP.BoxColor

                        box.Visible = true
                        boxOutline.Visible = true
                    else
                        objects.box.object.Visible = false
                        objects.outlineBox.object.Visible = false
                    end
                    
                    -- Health Bar (EXACT VaderHaxx style)
                    if ESP.HealthBars then
                        local healthBar = objects.healthBar.object
                        local healthBarBack = objects.healthBarBack.object
                        local healthBarOutline = objects.healthBarOutline.object
                        
                        local hpMax = ESP.HealthFullColor
                        local hpLow = ESP.HealthLowColor
                        
                        local fullSize = bounds.Height
                        local chunk = fullSize * healthPercentage
                        
                        -- EXACT VaderHaxx positioning with newVec2 equivalent
                        healthBar.Size = Vector2.new(2, chunk)
                        healthBar.Position = bounds.Min + Vector2.new(-4 - 2, fullSize - chunk)
                        healthBarBack.Size = Vector2.new(2 + 2, fullSize + 2)
                        healthBarBack.Position = bounds.Min + Vector2.new(-4 - 2 - 1, -1)

                        healthBarOutline.Size = healthBarBack.Size
                        healthBarOutline.Position = healthBarBack.Position

                        healthBar.Color = hpLow:Lerp(hpMax, healthPercentage)
                        
                        healthBar.Visible = true
                        healthBarBack.Visible = true
                        healthBarOutline.Visible = true
                    else
                        objects.healthBar.object.Visible = false
                        objects.healthBarBack.object.Visible = false
                        objects.healthBarOutline.object.Visible = false
                    end
                    
                    -- Name ESP (EXACT VaderHaxx style)
                    if ESP.Names then
                        local nameTag = objects.nameText.object
                        local textShading = 0.96 -- VaderHaxx exact value
                        
                        nameTag.Color = ESP.NameColor
                        nameTag.OutlineColor = Color3.new(
                            math.clamp(nameTag.Color.R - textShading, 0, 1),
                            math.clamp(nameTag.Color.G - textShading, 0, 1),
                            math.clamp(nameTag.Color.B - textShading, 0, 1)
                        )
                        nameTag.Text = player.Name:lower() -- VaderHaxx uses lowercase
                        -- EXACT VaderHaxx positioning: bounds.Min + newVec2(math.floor(bounds.Width / 2), -2 - nameTag.TextBounds.y)
                        nameTag.Position = bounds.Min + Vector2.new(math.floor(bounds.Width / 2), -2 - nameTag.TextBounds.Y)
                        nameTag.Size = 13 -- VaderHaxx mainTextSize
                        nameTag.Font = Drawing.Fonts.System -- VaderHaxx mainTextFont
                        nameTag.Visible = true
                    else
                        objects.nameText.object.Visible = false
                    end
                    
                    -- Distance ESP (EXACT VaderHaxx style - bottom of box)
                    if ESP.Distances then
                        local distanceTag = objects.distanceText.object
                        local textShading = 0.96 -- VaderHaxx exact value
                        
                        local dist = math.floor((workspace.CurrentCamera.CFrame.Position - character.HumanoidRootPart.Position).Magnitude)
                        distanceTag.Text = tostring(dist) .. "m"
                        -- EXACT VaderHaxx positioning for distance at bottom
                        distanceTag.Position = bounds.Min + Vector2.new(math.floor(bounds.Width / 2), bounds.Height + 2)
                        distanceTag.Size = 13 -- VaderHaxx mainTextSize
                        distanceTag.Font = Drawing.Fonts.System -- VaderHaxx mainTextFont
                        distanceTag.Color = ESP.DistColor
                        distanceTag.OutlineColor = Color3.new(
                            math.clamp(distanceTag.Color.R - textShading, 0, 1),
                            math.clamp(distanceTag.Color.G - textShading, 0, 1),
                            math.clamp(distanceTag.Color.B - textShading, 0, 1)
                        )
                        distanceTag.Visible = true
                    else
                        objects.distanceText.object.Visible = false
                    end
                    
                    -- Image ESP (scales with box)
                    if ESP.Images and objects.ImageGui then
                        -- Position and size to match the box bounds
                        objects.ImageGui.Position = UDim2.new(0, bounds.Min.X, 0, bounds.Min.Y)
                        objects.ImageGui.Size = UDim2.new(0, bounds.Width, 0, bounds.Height)
                        objects.ImageGui.Image = CustomImage or ""
                        objects.ImageGui.ImageTransparency = ESP.ImageTransparency
                        objects.ImageGui.Visible = true
                    elseif objects.ImageGui then
                        objects.ImageGui.Visible = false
                    end
                end
            end
        else
            -- Hide all objects when character is invalid or ESP disabled
            for key, container in pairs(objects) do
                if key == "ImageGui" then
                    if container then
                        container.Visible = false
                    end
                elseif container and container.object then
                    container.object.Visible = false
                end
            end
        end
        end
    end

    -- World ESP Updates
    if WorldESP.Enabled then
        for obj, _ in pairs(WorldESP.Objects) do
            if not obj.Parent then RemoveWorldDrawings(obj) end
        end

        local piles = workspace:FindFirstChild("Filter") and workspace.Filter:FindFirstChild("SpawnedPiles")
        if piles then
            for _, v in ipairs(piles:GetChildren()) do
                local mp = v:FindFirstChildOfClass("MeshPart")
                if mp and mp.TextureID == "rbxassetid://11157915894" then
                    ProcessObject(v, "rare crate", WorldESP.RareCrateColor, WorldESP.RareCrates)
                elseif mp and mp.TextureID == "rbxassetid://11157926942" then
                    ProcessObject(v, "airdrop", WorldESP.AirdropColor, WorldESP.Airdrops)
                end
            end
        end

        local shopz = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Shopz")
        if shopz then
            for _, v in ipairs(shopz:GetChildren()) do
                if v.Name == "RebelDealer" then
                    ProcessObject(v, "rebel dealer", WorldESP.RebelColor, WorldESP.RebelDealer)
                else
                    local name, cat = GetDealerInfo(v)
                    if name then
                        local enabled = WorldESP.Dealers and (WorldESP.SpecificDealers[name] ~= false)
                        ProcessObject(v, name, WorldESP.DealerColor, enabled)
                    else
                        if v.Name == "ArmoryDealer" then ProcessObject(v, "armory dealer", WorldESP.DealerColor, WorldESP.Dealers)
                        elseif v.Name == "Dealer" then ProcessObject(v, "dealer", WorldESP.DealerColor, WorldESP.Dealers) end
                    end
                end
                
                if WorldESP.CopeCoins then
                    local s = v:FindFirstChild("CurrentStocks")
                    local c = s and s:FindFirstChild("_CopeCoin26")
                    if c and c.Value == 1 then
                        ProcessObject(v, "COPE COIN", WorldESP.CopeCoinColor, true)
                    end
                end
            end
        end

        if WorldESP.MysteryBoxes then
            local mystery = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("MysteryBoxes")
            if mystery then
                for _, v in ipairs(mystery:GetChildren()) do
                    if v.Name == "MysteryBox" then
                        ProcessObject(v, "mystery box", WorldESP.MysteryBoxColor, true)
                    end
                end
            end
        end
    else
        for obj, _ in pairs(WorldESP.Objects) do
            RemoveWorldDrawings(obj)
        end
    end
end))

function Library:Notify(Text, Duration)
    Duration = Duration or 3
    
    local SG = CoreGui:FindFirstChild("JebeNotificationsGui")
    if not SG then
        SG = Instance.new("ScreenGui")
        SG.Name = "JebeNotificationsGui"
        SG.Parent = CoreGui
        SG.DisplayOrder = 999
    end
    
    local Holder = SG:FindFirstChild("Holder")
    if not Holder then
        Holder = Instance.new("Frame")
        Holder.Name = "Holder"
        Holder.Parent = SG
        Holder.BackgroundTransparency = 1
        Holder.Position = UDim2.new(1, -220, 0, 20)
        Holder.Size = UDim2.new(0, 200, 1, -40)
        
        local Layout = Instance.new("UIListLayout")
        Layout.Parent = Holder
        Layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
        Layout.VerticalAlignment = Enum.VerticalAlignment.Top
        Layout.SortOrder = Enum.SortOrder.LayoutOrder
        Layout.Padding = UDim.new(0, 5)
    end
    
    local Container = Instance.new("Frame")
    Container.Name = "NotifyContainer"
    Container.Parent = Holder
    Container.BackgroundTransparency = 1
    Container.Size = UDim2.new(1, 0, 0, 30)
    Container.ClipsDescendants = false
    
    local NotifyFrame = Instance.new("Frame")
    NotifyFrame.Name = "Notify"
    NotifyFrame.Parent = Container
    NotifyFrame.BackgroundColor3 = Colors.Main
    NotifyFrame.BorderSizePixel = 0
    NotifyFrame.Size = UDim2.new(1, 0, 1, 0)
    NotifyFrame.Position = UDim2.new(0, 0, 0, 0)
    
    local AccentLine = Instance.new("Frame")
    AccentLine.Parent = NotifyFrame
    AccentLine.BackgroundColor3 = Colors.Accent
    AccentLine.BorderSizePixel = 0
    AccentLine.Size = UDim2.new(0, 2, 1, 0)
    table.insert(AccentElements, AccentLine)
    
    local Label = Instance.new("TextLabel")
    Label.Parent = NotifyFrame
    Label.BackgroundTransparency = 1
    Label.Position = UDim2.new(0, 10, 0, 0)
    Label.Size = UDim2.new(1, -15, 1, 0)
    Label.Font = Font
    Label.Text = Text:lower()
    Label.TextColor3 = Colors.Text
    Label.TextSize = 12
    Label.TextXAlignment = Enum.TextXAlignment.Left

    local Sound = SG:FindFirstChild("NotifySound")
    if not Sound then
        Sound = Instance.new("Sound")
        Sound.Name = "NotifySound"
        Sound.SoundId = "rbxassetid://130840811"
        Sound.Volume = 0.5
        Sound.Parent = SG
    end
    Sound:Play()
    Label.TextColor3 = Colors.Text
    Label.TextSize = 12
    Label.TextXAlignment = Enum.TextXAlignment.Left
    
    local Stroke = Instance.new("UIStroke")
    Stroke.Parent = NotifyFrame
    Stroke.Color = Colors.Border
    Stroke.Thickness = 1
    
    task.delay(Duration, function()
        Container:Destroy()
    end)
end

function Library:CreateWindow(Title)
    local Window = {
        CurrentTab = nil,
        Tabs = {}
    }

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "JebeMenu"
    ScreenGui.Parent = CoreGui
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    Window.ScreenGui = ScreenGui

    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Parent = ScreenGui
    MainFrame.BackgroundColor3 = Colors.Main
    MainFrame.BorderSizePixel = 0
    MainFrame.Position = UDim2.new(0.5, -300, 0.5, -240)
    MainFrame.Size = UDim2.new(0, 600, 0, 480)

    Window.MainFrame = MainFrame

    local Stroke = Instance.new("UIStroke")
    Stroke.Parent = MainFrame
    Stroke.Color = Colors.Border
    Stroke.Thickness = 1
    Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    local Header = Instance.new("Frame")
    Header.Name = "Header"
    Header.Parent = MainFrame
    Header.BackgroundColor3 = Colors.Main
    Header.BorderSizePixel = 0
    Header.Size = UDim2.new(1, 0, 0, 35)

    -- Dragging (only on header)
    local dragging, dragInput, dragStart, startPos
    Header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    Header.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    -- Logo text on the left
    local LogoText = Instance.new("TextLabel")
    LogoText.Name = "Logo"
    LogoText.Parent = Header
    LogoText.BackgroundTransparency = 1
    LogoText.Position = UDim2.new(0, 15, 0, 0)
    LogoText.Size = UDim2.new(0, 150, 1, 0)
    LogoText.Font = Font
    LogoText.Text = "Jebe.lua"
    LogoText.TextColor3 = Colors.Accent
    LogoText.TextSize = 14
    LogoText.TextXAlignment = Enum.TextXAlignment.Left
    table.insert(AccentElements, LogoText)

    local TabContainer = Instance.new("Frame")
    TabContainer.Name = "TabContainer"
    TabContainer.Parent = Header
    TabContainer.BackgroundTransparency = 1
    TabContainer.Position = UDim2.new(0, 150, 0, 0)
    TabContainer.Size = UDim2.new(1, -150, 1, 0)

    local TabList = Instance.new("UIListLayout")
    TabList.Parent = TabContainer
    TabList.FillDirection = Enum.FillDirection.Horizontal
    TabList.HorizontalAlignment = Enum.HorizontalAlignment.Center
    TabList.SortOrder = Enum.SortOrder.LayoutOrder
    TabList.Padding = UDim.new(0, 20)

    local Line = Instance.new("Frame")
    Line.Name = "Line"
    Line.Parent = Header
    Line.BackgroundColor3 = Colors.Border
    Line.BorderSizePixel = 0
    Line.Position = UDim2.new(0, 0, 1, 0)
    Line.Size = UDim2.new(1, 0, 0, 1)

    local Content = Instance.new("Frame")
    Content.Name = "Content"
    Content.Parent = MainFrame
    Content.BackgroundTransparency = 1
    Content.Position = UDim2.new(0, 0, 0, 36)
    Content.Size = UDim2.new(1, 0, 1, -36)
    Content.ClipsDescendants = true

    -- Stock Display Panel (right side)
    local StockPanel = Instance.new("Frame")
    StockPanel.Name = "StockPanel"
    StockPanel.Parent = MainFrame
    StockPanel.BackgroundColor3 = Colors.Main
    StockPanel.BorderSizePixel = 0
    StockPanel.Position = UDim2.new(1, 10, 0, 36)
    StockPanel.Size = UDim2.new(0, 250, 1, -36)
    StockPanel.Visible = false

    local StockStroke = Instance.new("UIStroke")
    StockStroke.Parent = StockPanel
    StockStroke.Color = Colors.Border
    StockStroke.Thickness = 1

    local StockTitle = Instance.new("TextLabel")
    StockTitle.Name = "Title"
    StockTitle.Parent = StockPanel
    StockTitle.BackgroundTransparency = 1
    StockTitle.Position = UDim2.new(0, 10, 0, 10)
    StockTitle.Size = UDim2.new(1, -40, 0, 20)
    StockTitle.Font = Font
    StockTitle.Text = "dealer stock"
    StockTitle.TextColor3 = Colors.Accent
    StockTitle.TextSize = 14
    StockTitle.TextXAlignment = Enum.TextXAlignment.Left

    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Name = "CloseBtn"
    CloseBtn.Parent = StockPanel
    CloseBtn.BackgroundTransparency = 1
    CloseBtn.Position = UDim2.new(1, -30, 0, 10)
    CloseBtn.Size = UDim2.new(0, 20, 0, 20)
    CloseBtn.Font = Font
    CloseBtn.Text = "x"
    CloseBtn.TextColor3 = Colors.Text
    CloseBtn.TextSize = 16
    CloseBtn.AutoButtonColor = false

    CloseBtn.MouseButton1Click:Connect(function()
        StockPanel.Visible = false
    end)

    CloseBtn.MouseEnter:Connect(function()
        CloseBtn.TextColor3 = Colors.Accent
    end)

    CloseBtn.MouseLeave:Connect(function()
        CloseBtn.TextColor3 = Colors.Text
    end)

    local StockScroll = Instance.new("ScrollingFrame")
    StockScroll.Name = "StockScroll"
    StockScroll.Parent = StockPanel
    StockScroll.BackgroundTransparency = 1
    StockScroll.Position = UDim2.new(0, 10, 0, 35)
    StockScroll.Size = UDim2.new(1, -20, 1, -45)
    StockScroll.ScrollBarThickness = 4
    StockScroll.ScrollBarImageColor3 = Colors.Accent
    StockScroll.BorderSizePixel = 0
    StockScroll.CanvasSize = UDim2.new(0, 0, 0, 0)

    local StockLayout = Instance.new("UIListLayout")
    StockLayout.Parent = StockScroll
    StockLayout.SortOrder = Enum.SortOrder.Name
    StockLayout.Padding = UDim.new(0, 3)

    StockLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        StockScroll.CanvasSize = UDim2.new(0, 0, 0, StockLayout.AbsoluteContentSize.Y)
    end)

    Window.StockPanel = StockPanel
    Window.StockScroll = StockScroll
    Window.StockTitle = StockTitle

    function Window:CreateTab(Name)
        local Tab = {
            Groups = {}
        }

        local TabButton = Instance.new("TextButton")
        TabButton.Name = Name .. "Tab"
        TabButton.Parent = TabContainer
        TabButton.BackgroundTransparency = 1
        TabButton.BorderSizePixel = 0
        TabButton.Size = UDim2.new(0, 0, 1, 0)
        TabButton.AutomaticSize = Enum.AutomaticSize.X
        TabButton.Font = Font
        TabButton.Text = Name:lower()
        TabButton.TextColor3 = Colors.DarkText
        TabButton.TextSize = TextSize
        TabButton.AutoButtonColor = false

        local Underline = Instance.new("Frame")
        Underline.Name = "Underline"
        Underline.Parent = TabButton
        Underline.BackgroundColor3 = Colors.Accent
        Underline.BorderSizePixel = 0
        Underline.Position = UDim2.new(0, 0, 1, -1)
        Underline.Size = UDim2.new(1, 0, 0, 1)
        Underline.Visible = false
        table.insert(AccentElements, Underline)

        local Page = Instance.new("ScrollingFrame")
        Page.Name = Name .. "Page"
        Page.Parent = Content
        Page.BackgroundTransparency = 1
        Page.BorderSizePixel = 0
        Page.Size = UDim2.new(1, 0, 1, 0)
        Page.ScrollBarThickness = 0
        Page.ClipsDescendants = false
        Page.Visible = false
        Page.CanvasSize = UDim2.new(0, 0, 0, 0)

        Tab.Page = Page

        local PagePadding = Instance.new("UIPadding")
        PagePadding.Parent = Page
        PagePadding.PaddingTop = UDim.new(0, 30)
        PagePadding.PaddingLeft = UDim.new(0, 20)
        PagePadding.PaddingRight = UDim.new(0, 20)

        -- Track groupbox positions for each side
        Tab.LeftY = 0
        Tab.RightY = 0

        local function Select()
            if Window.CurrentTab then
                Window.CurrentTab.Page.Visible = false
                Window.CurrentTab.Button.TextColor3 = Colors.DarkText
                Window.CurrentTab.Button.Underline.Visible = false
            end
            Page.Visible = true
            TabButton.TextColor3 = Colors.Text
            Underline.Visible = true
            Window.CurrentTab = {Page = Page, Button = TabButton}
        end

        TabButton.MouseButton1Click:Connect(Select)

        if not Window.CurrentTab then Select() end

        function Tab:CreateGroupbox(Label, Side)
            local Groupbox = {}
            Side = Side or "left"
            local fullWidth = Side == "full"
            
            local Container = Instance.new("Frame")
            Container.Name = Label .. "Group"
            Container.Parent = Page
            Container.BackgroundColor3 = Colors.Main
            Container.BorderSizePixel = 0
            Container.AutomaticSize = Enum.AutomaticSize.Y
            Container.ClipsDescendants = false
            Container.Size = fullWidth and UDim2.new(1, 0, 0, 100) or UDim2.new(0.5, -10, 0, 100)
            
            if fullWidth then
                Container.Position = UDim2.new(0, 0, 0, Tab.LeftY)
            elseif Side == "left" then
                Container.Position = UDim2.new(0, 0, 0, Tab.LeftY)
            else
                Container.Position = UDim2.new(0.5, 10, 0, Tab.RightY)
            end

            local GroupStroke = Instance.new("UIStroke")
            GroupStroke.Parent = Container
            GroupStroke.Color = Colors.GroupBorder
            GroupStroke.Thickness = 1
            GroupStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

            local GroupLabel = Instance.new("TextLabel")
            GroupLabel.Name = "Title"
            GroupLabel.Parent = Container
            GroupLabel.BackgroundColor3 = Colors.Main
            GroupLabel.BorderSizePixel = 0
            GroupLabel.Position = UDim2.new(0, 10, 0, -8)
            GroupLabel.Size = UDim2.new(0, 0, 0, 14)
            GroupLabel.AutomaticSize = Enum.AutomaticSize.X
            GroupLabel.Font = Font
            GroupLabel.Text = " " .. Label:lower() .. " "
            GroupLabel.TextColor3 = Colors.Text
            GroupLabel.TextSize = 12

            local ElementList = Instance.new("Frame")
            ElementList.Name = "ElementList"
            ElementList.Parent = Container
            ElementList.BackgroundTransparency = 1
            ElementList.Position = UDim2.new(0, 12, 0, 12)
            ElementList.Size = UDim2.new(1, -24, 1, -24)

            local Layout = Instance.new("UIListLayout")
            Layout.Parent = ElementList
            Layout.SortOrder = Enum.SortOrder.LayoutOrder
            Layout.Padding = UDim.new(0, 10)

            Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                local newWidth = fullWidth and UDim2.new(1, 0, 0, Layout.AbsoluteContentSize.Y + 24)
                    or UDim2.new(0.5, -10, 0, Layout.AbsoluteContentSize.Y + 24)
                Container.Size = newWidth
                
                -- Update Y position for next groupbox on this side
                --i have no clue how this works
                if Side == "left" or fullWidth then
                    Tab.LeftY = Container.Position.Y.Offset + Container.AbsoluteSize.Y + 30
                else
                    Tab.RightY = Container.Position.Y.Offset + Container.AbsoluteSize.Y + 30
                end
                
                -- Update canvas size based on tallest column
                local maxY = math.max(Tab.LeftY, Tab.RightY)
                Page.CanvasSize = UDim2.new(0, 0, 0, maxY + 40)
            end)

            -- Expose internals for custom content
            Groupbox.ElementList = ElementList
            Groupbox.Container = Container

            function Groupbox:CreateToggle(Text, Default, Callback)
                local Toggled = Default or false
                
                local ToggleBtn = Instance.new("TextButton")
                ToggleBtn.Name = Text .. "Toggle"
                ToggleBtn.Parent = ElementList
                ToggleBtn.BackgroundTransparency = 1
                ToggleBtn.Size = UDim2.new(1, 0, 0, 16)
                ToggleBtn.Text = ""
                ToggleBtn.AutoButtonColor = false

                local Box = Instance.new("Frame")
                Box.Name = "Box"
                Box.Parent = ToggleBtn
                Box.BackgroundColor3 = Toggled and Colors.Accent or Colors.Element
                Box.BorderSizePixel = 0
                Box.Size = UDim2.new(0, 8, 0, 8)
                Box.Position = UDim2.new(0, 0, 0.5, -4)

                local BoxStroke = Instance.new("UIStroke")
                BoxStroke.Parent = Box
                BoxStroke.Color = Colors.GroupBorder
                BoxStroke.Thickness = 1
                BoxStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

                local Label = Instance.new("TextLabel")
                Label.Name = "Label"
                Label.Parent = ToggleBtn
                Label.BackgroundTransparency = 1
                Label.Position = UDim2.new(0, 15, 0, 0)
                Label.Size = UDim2.new(1, -15, 1, 0)
                Label.Font = Font
                Label.Text = Text:lower()
                Label.TextColor3 = Toggled and Colors.Text or Colors.DarkText
                Label.TextSize = 12
                Label.TextXAlignment = Enum.TextXAlignment.Left

                -- Register toggle box for accent color updates
                table.insert(ToggleBoxes, {
                    box = Box,
                    getState = function() return Toggled end
                })

                ToggleBtn.MouseButton1Click:Connect(function()
                    Toggled = not Toggled
                    Box.BackgroundColor3 = Toggled and Colors.Accent or Colors.Element
                    Label.TextColor3 = Toggled and Colors.Text or Colors.DarkText
                    Callback(Toggled)
                end)

                return {
                    Set = function(self, Val)
                        Toggled = Val
                        Box.BackgroundColor3 = Toggled and Colors.Accent or Colors.Element
                        Label.TextColor3 = Toggled and Colors.Text or Colors.DarkText
                        Callback(Toggled)
                    end
                }
            end

            function Groupbox:CreateSlider(Text, Min, Max, Default, Decimals, Callback)
                local Value = Default or Min
                local Decimals = Decimals or 1
                
                local SliderFrame = Instance.new("Frame")
                SliderFrame.Name = Text .. "Slider"
                SliderFrame.Parent = ElementList
                SliderFrame.BackgroundTransparency = 1
                SliderFrame.Size = UDim2.new(1, 0, 0, 32)

                local Label = Instance.new("TextLabel")
                Label.Name = "Label"
                Label.Parent = SliderFrame
                Label.BackgroundTransparency = 1
                Label.Size = UDim2.new(1, 0, 0, 14)
                Label.Font = Font
                Label.Text = Text:lower()
                Label.TextColor3 = Colors.Text
                Label.TextSize = 12
                Label.TextXAlignment = Enum.TextXAlignment.Left

                local Minus = Instance.new("TextButton")
                Minus.Name = "Minus"
                Minus.Parent = SliderFrame
                Minus.BackgroundTransparency = 1
                Minus.Position = UDim2.new(0, 0, 0, 18)
                Minus.Size = UDim2.new(0, 10, 0, 10)
                Minus.Font = Font
                Minus.Text = "-"
                Minus.TextColor3 = Colors.DarkText
                Minus.TextSize = 14

                local SliderBG = Instance.new("Frame")
                SliderBG.Name = "BG"
                SliderBG.Parent = SliderFrame
                SliderBG.BackgroundColor3 = Colors.Element
                SliderBG.BorderSizePixel = 0
                SliderBG.Position = UDim2.new(0, 15, 0, 21)
                SliderBG.Size = UDim2.new(1, -55, 0, 4)

                local SliderStroke = Instance.new("UIStroke")
                SliderStroke.Parent = SliderBG
                SliderStroke.Color = Colors.GroupBorder
                SliderStroke.Thickness = 1

                local SliderFill = Instance.new("Frame")
                SliderFill.Name = "Fill"
                SliderFill.Parent = SliderBG
                SliderFill.BackgroundColor3 = Colors.Accent
                SliderFill.BorderSizePixel = 0
                SliderFill.Size = UDim2.new((Value - Min) / (Max - Min), 0, 1, 0)

                local ValLabel = Instance.new("TextLabel")
                ValLabel.Name = "Value"
                ValLabel.Parent = SliderFrame
                ValLabel.BackgroundTransparency = 1
                ValLabel.Position = UDim2.new(1, -35, 0, 18)
                ValLabel.Size = UDim2.new(0, 25, 0, 10)
                ValLabel.Font = Font
                ValLabel.Text = string.format("%." .. Decimals .. "f", Value)
                ValLabel.TextColor3 = Colors.Text
                ValLabel.TextSize = 11

                local Plus = Instance.new("TextButton")
                Plus.Name = "Plus"
                Plus.Parent = SliderFrame
                Plus.BackgroundTransparency = 1
                Plus.Position = UDim2.new(1, -10, 0, 18)
                Plus.Size = UDim2.new(0, 10, 0, 10)
                Plus.Font = Font
                Plus.Text = "+"
                Plus.TextColor3 = Colors.DarkText
                Plus.TextSize = 14

                local function Update(Input)
                    local Perc = math.clamp((Input.Position.X - SliderBG.AbsolutePosition.X) / SliderBG.AbsoluteSize.X, 0, 1)
                    Value = Min + (Max - Min) * Perc
                    Value = math.floor(Value * (10 ^ Decimals)) / (10 ^ Decimals)
                    
                    SliderFill.Size = UDim2.new(Perc, 0, 1, 0)
                    ValLabel.Text = string.format("%." .. Decimals .. "f", Value)
                    Callback(Value)
                end

                local Sliding = false
                SliderBG.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        Sliding = true
                        Update(input)
                    end
                end)
                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then Sliding = false end
                end)
                UserInputService.InputChanged:Connect(function(input)
                    if Sliding and input.UserInputType == Enum.UserInputType.MouseMovement then Update(input) end
                end)

                Minus.MouseButton1Click:Connect(function()
                    Value = math.clamp(Value - (1 / (10 ^ Decimals)), Min, Max)
                    SliderFill.Size = UDim2.new((Value - Min) / (Max - Min), 0, 1, 0)
                    ValLabel.Text = string.format("%." .. Decimals .. "f", Value)
                    Callback(Value)
                end)
                Plus.MouseButton1Click:Connect(function()
                    Value = math.clamp(Value + (1 / (10 ^ Decimals)), Min, Max)
                    SliderFill.Size = UDim2.new((Value - Min) / (Max - Min), 0, 1, 0)
                    ValLabel.Text = string.format("%." .. Decimals .. "f", Value)
                    Callback(Value)
                end)

                return {
                    Set = function(self, Val)
                        Value = Val
                        SliderFill.Size = UDim2.new((Value - Min) / (Max - Min), 0, 1, 0)
                        ValLabel.Text = string.format("%." .. Decimals .. "f", Value)
                        Callback(Value)
                    end
                }
            end

            function Groupbox:CreateDropdown(Text, Options, Default, Callback)
                local Selected = Default or Options[1]
                local Open = false
                
                local DropFrame = Instance.new("Frame")
                DropFrame.Name = Text .. "Dropdown"
                DropFrame.Parent = ElementList
                DropFrame.BackgroundTransparency = 1
                DropFrame.Size = UDim2.new(1, 0, 0, 36)
                DropFrame.ZIndex = 5

                local Label = Instance.new("TextLabel")
                Label.Name = "Label"
                Label.Parent = DropFrame
                Label.BackgroundTransparency = 1
                Label.Size = UDim2.new(1, 0, 0, 14)
                Label.Font = Font
                Label.Text = Text:lower()
                Label.TextColor3 = Colors.Text
                Label.TextSize = 12
                Label.TextXAlignment = Enum.TextXAlignment.Left

                local Button = Instance.new("TextButton")
                Button.Name = "Button"
                Button.Parent = DropFrame
                Button.BackgroundColor3 = Colors.Element
                Button.BorderSizePixel = 0
                Button.Position = UDim2.new(0, 0, 0, 18)
                Button.Size = UDim2.new(1, 0, 0, 18)
                Button.Font = Font
                Button.Text = "  " .. Selected:lower()
                Button.TextColor3 = Colors.DarkText
                Button.TextSize = 12
                Button.TextXAlignment = Enum.TextXAlignment.Left
                Button.AutoButtonColor = false

                local BtnStroke = Instance.new("UIStroke")
                BtnStroke.Parent = Button
                BtnStroke.Color = Colors.GroupBorder
                BtnStroke.Thickness = 1

                local Arrow = Instance.new("TextLabel")
                Arrow.Name = "Arrow"
                Arrow.Parent = Button
                Arrow.BackgroundTransparency = 1
                Arrow.Position = UDim2.new(1, -15, 0, 0)
                Arrow.Size = UDim2.new(0, 15, 1, 0)
                Arrow.Font = Font
                Arrow.Text = "▼"
                Arrow.TextColor3 = Colors.DarkText
                Arrow.TextSize = 8

                local List = Instance.new("Frame")
                List.Name = "List"
                List.Parent = DropFrame
                List.BackgroundColor3 = Colors.Element
                List.BorderSizePixel = 0
                List.Position = UDim2.new(0, 0, 0, 38)
                List.Size = UDim2.new(1, 0, 0, 0)
                List.Visible = false
                List.ZIndex = 10

                local ListStroke = Instance.new("UIStroke")
                ListStroke.Parent = List
                ListStroke.Color = Colors.GroupBorder
                ListStroke.Thickness = 1

                local ListLayout = Instance.new("UIListLayout")
                ListLayout.Parent = List
                ListLayout.SortOrder = Enum.SortOrder.LayoutOrder

                local function RebuildOptions(NewOptions)
                    -- Clear existing options
                    for _, child in ipairs(List:GetChildren()) do
                        if child:IsA("TextButton") then
                            child:Destroy()
                        end
                    end
                    
                    -- Create new options
                    for _, v in ipairs(NewOptions) do
                        local Opt = Instance.new("TextButton")
                        Opt.Name = v .. "Opt"
                        Opt.Parent = List
                        Opt.BackgroundTransparency = 1
                        Opt.Size = UDim2.new(1, 0, 0, 18)
                        Opt.Font = Font
                        Opt.Text = "  " .. v:lower()
                        Opt.TextColor3 = Colors.DarkText
                        Opt.TextSize = 12
                        Opt.TextXAlignment = Enum.TextXAlignment.Left
                        Opt.ZIndex = 11

                        Opt.MouseButton1Click:Connect(function()
                            Selected = v
                            Button.Text = "  " .. v:lower()
                            Open = false
                            List.Visible = false
                            Callback(v)
                        end)
                    end
                end

                -- Initial build
                RebuildOptions(Options)

                Button.MouseButton1Click:Connect(function()
                    Open = not Open
                    List.Visible = Open
                    local optCount = 0
                    for _, child in ipairs(List:GetChildren()) do
                        if child:IsA("TextButton") then optCount = optCount + 1 end
                    end
                    List.Size = UDim2.new(1, 0, 0, Open and optCount * 18 or 0)
                end)

                return {
                    Set = function(self, Val)
                        Selected = Val
                        Button.Text = "  " .. Val:lower()
                        Callback(Val)
                    end,
                    Refresh = function(self, NewOptions)
                        RebuildOptions(NewOptions)
                    end
                }
            end

            function Groupbox:CreateKeybind(Text, Default, Callback)
                local Key = Default or Enum.KeyCode.Delete
                local Binding = false
                
                local BindFrame = Instance.new("Frame")
                BindFrame.Name = Text .. "Bind"
                BindFrame.Parent = ElementList
                BindFrame.BackgroundTransparency = 1
                BindFrame.Size = UDim2.new(1, 0, 0, 20)

                local Label = Instance.new("TextLabel")
                Label.Name = "Label"
                Label.Parent = BindFrame
                Label.BackgroundTransparency = 1
                Label.Size = UDim2.new(1, -60, 1, 0)
                Label.Font = Font
                Label.Text = Text:lower()
                Label.TextColor3 = Colors.Text
                Label.TextSize = 12
                Label.TextXAlignment = Enum.TextXAlignment.Left

                local Button = Instance.new("TextButton")
                Button.Name = "Button"
                Button.Parent = BindFrame
                Button.BackgroundColor3 = Colors.Element
                Button.BorderSizePixel = 0
                Button.Position = UDim2.new(1, -55, 0.5, -9)
                Button.Size = UDim2.new(0, 55, 0, 18)
                Button.Font = Font
                Button.Text = Key.Name:lower()
                Button.TextColor3 = Colors.DarkText
                Button.TextSize = 11
                Button.AutoButtonColor = false

                local BtnStroke = Instance.new("UIStroke")
                BtnStroke.Parent = Button
                BtnStroke.Color = Colors.GroupBorder
                BtnStroke.Thickness = 1

                Button.MouseButton1Click:Connect(function()
                    Binding = true
                    Button.Text = "..."
                end)

                UserInputService.InputBegan:Connect(function(input)
                    if Binding then
                        if input.UserInputType == Enum.UserInputType.Keyboard then
                            Key = input.KeyCode
                            Button.Text = Key.Name:lower()
                            Binding = false
                            Callback(Key)
                        end
                    elseif input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Key then
                        Callback(Key)
                    end
                end)

                return {
                    Set = function(self, Val)
                        Key = Val
                        Button.Text = Key.Name:lower()
                    end
                }
            end

            function Groupbox:CreateColorpicker(Text, Default, Callback)
                local Color = Default or Color3.fromRGB(255, 255, 255)
                local Open = false
                
                local ColorFrame = Instance.new("Frame")
                ColorFrame.Name = Text .. "Color"
                ColorFrame.Parent = ElementList
                ColorFrame.BackgroundTransparency = 1
                ColorFrame.Size = UDim2.new(1, 0, 0, 20)

                local Label = Instance.new("TextLabel")
                Label.Name = "Label"
                Label.Parent = ColorFrame
                Label.BackgroundTransparency = 1
                Label.Size = UDim2.new(1, -30, 1, 0)
                Label.Font = Font
                Label.Text = Text:lower()
                Label.TextColor3 = Colors.Text
                Label.TextSize = 12
                Label.TextXAlignment = Enum.TextXAlignment.Left

                local PickerBtn = Instance.new("TextButton")
                PickerBtn.Name = "Picker"
                PickerBtn.Parent = ColorFrame
                PickerBtn.BackgroundColor3 = Color
                PickerBtn.BorderSizePixel = 0
                PickerBtn.Position = UDim2.new(1, -25, 0.5, -7)
                PickerBtn.Size = UDim2.new(0, 20, 0, 14)
                PickerBtn.Text = ""
                PickerBtn.AutoButtonColor = false

                local BtnStroke = Instance.new("UIStroke")
                BtnStroke.Parent = PickerBtn
                BtnStroke.Color = Colors.GroupBorder
                BtnStroke.Thickness = 1

                local Popup = Instance.new("Frame")
                Popup.Name = "Popup"
                Popup.Parent = Window.ScreenGui
                Popup.BackgroundColor3 = Colors.Element
                Popup.BorderSizePixel = 0
                Popup.Size = UDim2.new(0, 120, 0, 40)
                Popup.Visible = false
                Popup.ZIndex = 100

                local PopupStroke = Instance.new("UIStroke")
                PopupStroke.Parent = Popup
                PopupStroke.Color = Colors.GroupBorder
                PopupStroke.Thickness = 1

                local function UpdatePopupPos()
                    local pos = ColorFrame.AbsolutePosition
                    Popup.Position = UDim2.new(0, pos.X + ColorFrame.AbsoluteSize.X + 5, 0, pos.Y)
                end

                ColorFrame:GetPropertyChangedSignal("AbsolutePosition"):Connect(UpdatePopupPos)
                Window.MainFrame:GetPropertyChangedSignal("Visible"):Connect(function()
                    if not Window.MainFrame.Visible then Popup.Visible = false end
                end)

                local HueSlider = Instance.new("Frame")
                HueSlider.Name = "Hue"
                HueSlider.Parent = Popup
                HueSlider.Position = UDim2.new(0, 5, 0, 5)
                HueSlider.Size = UDim2.new(1, -10, 0, 10)
                HueSlider.BorderSizePixel = 0
                
                local HueGrad = Instance.new("UIGradient")
                HueGrad.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 1, 1)),
                    ColorSequenceKeypoint.new(0.16, Color3.fromHSV(0.16, 1, 1)),
                    ColorSequenceKeypoint.new(0.33, Color3.fromHSV(0.33, 1, 1)),
                    ColorSequenceKeypoint.new(0.5, Color3.fromHSV(0.5, 1, 1)),
                    ColorSequenceKeypoint.new(0.66, Color3.fromHSV(0.66, 1, 1)),
                    ColorSequenceKeypoint.new(0.83, Color3.fromHSV(0.83, 1, 1)),
                    ColorSequenceKeypoint.new(1, Color3.fromHSV(1, 1, 1))
                })
                HueGrad.Parent = HueSlider

                local HuePicker = Instance.new("Frame")
                HuePicker.Name = "Picker"
                HuePicker.Parent = HueSlider
                HuePicker.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                HuePicker.BorderSizePixel = 1
                HuePicker.BorderColor3 = Color3.fromRGB(0, 0, 0)
                HuePicker.Size = UDim2.new(0, 2, 1, 2)
                HuePicker.Position = UDim2.new(0, 0, 0, -1)

                local SatSlider = Instance.new("Frame")
                SatSlider.Name = "Sat"
                SatSlider.Parent = Popup
                SatSlider.Position = UDim2.new(0, 5, 0, 22)
                SatSlider.Size = UDim2.new(1, -10, 0, 10)
                SatSlider.BorderSizePixel = 0
                
                local SatGrad = Instance.new("UIGradient")
                SatGrad.Parent = SatSlider

                local SatPicker = Instance.new("Frame")
                SatPicker.Name = "Picker"
                SatPicker.Parent = SatSlider
                SatPicker.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                SatPicker.BorderSizePixel = 1
                SatPicker.BorderColor3 = Color3.fromRGB(0, 0, 0)
                SatPicker.Size = UDim2.new(0, 2, 1, 2)
                SatPicker.Position = UDim2.new(1, -1, 0, -1)

                local curH, curS, curV = Color3.toHSV(Color)

                local function Update()
                    Color = Color3.fromHSV(curH, curS, curV)
                    PickerBtn.BackgroundColor3 = Color
                    SatGrad.Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, Color3.fromHSV(curH, 0, 1)),
                        ColorSequenceKeypoint.new(1, Color3.fromHSV(curH, 1, 1))
                    })
                    Callback(Color)
                end

                local hDragging = false
                HueSlider.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        hDragging = true
                        local percent = math.clamp((input.Position.X - HueSlider.AbsolutePosition.X) / HueSlider.AbsoluteSize.X, 0, 1)
                        curH = percent
                        HuePicker.Position = UDim2.new(percent, -1, 0, -1)
                        Update()
                    end
                end)

                local sDragging = false
                SatSlider.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        sDragging = true
                        local percent = math.clamp((input.Position.X - SatSlider.AbsolutePosition.X) / SatSlider.AbsoluteSize.X, 0, 1)
                        curS = percent
                        SatPicker.Position = UDim2.new(percent, -1, 0, -1)
                        Update()
                    end
                end)

                UserInputService.InputChanged:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseMovement then
                        if hDragging then
                            local percent = math.clamp((input.Position.X - HueSlider.AbsolutePosition.X) / HueSlider.AbsoluteSize.X, 0, 1)
                            curH = percent
                            HuePicker.Position = UDim2.new(percent, -1, 0, -1)
                            Update()
                        elseif sDragging then
                            local percent = math.clamp((input.Position.X - SatSlider.AbsolutePosition.X) / SatSlider.AbsoluteSize.X, 0, 1)
                            curS = percent
                            SatPicker.Position = UDim2.new(percent, -1, 0, -1)
                            Update()
                        end
                    end
                end)

                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        hDragging = false
                        sDragging = false
                    end
                end)

                Update() -- Initial sync

                PickerBtn.MouseButton1Click:Connect(function()
                    Open = not Open
                    UpdatePopupPos()
                    Popup.Visible = Open
                end)

                return {
                    Set = function(self, Val)
                        Color = Val
                        PickerBtn.BackgroundColor3 = Val
                        Callback(Val)
                    end
                }
            end

            function Groupbox:CreateButton(Text, Callback)
                local ButtonFrame = Instance.new("TextButton")
                ButtonFrame.Name = Text .. "Button"
                ButtonFrame.Parent = ElementList
                ButtonFrame.BackgroundColor3 = Colors.Element
                ButtonFrame.BorderSizePixel = 0
                ButtonFrame.Size = UDim2.new(1, 0, 0, 20)
                ButtonFrame.Font = Font
                ButtonFrame.Text = Text:lower()
                ButtonFrame.TextColor3 = Colors.Text
                ButtonFrame.TextSize = 12
                ButtonFrame.AutoButtonColor = false

                local BtnStroke = Instance.new("UIStroke")
                BtnStroke.Parent = ButtonFrame
                BtnStroke.Color = Colors.GroupBorder
                BtnStroke.Thickness = 1

                ButtonFrame.MouseButton1Click:Connect(function()
                    Callback()
                end)

                ButtonFrame.MouseEnter:Connect(function()
                    ButtonFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
                end)
                ButtonFrame.MouseLeave:Connect(function()
                    ButtonFrame.BackgroundColor3 = Colors.Element
                end)

                return ButtonFrame
            end

            function Groupbox:CreateTextbox(Text, Default, Callback)
                local Value = Default or ""
                
                local TextboxFrame = Instance.new("Frame")
                TextboxFrame.Name = Text .. "Textbox"
                TextboxFrame.Parent = ElementList
                TextboxFrame.BackgroundTransparency = 1
                TextboxFrame.Size = UDim2.new(1, 0, 0, 36)

                local Label = Instance.new("TextLabel")
                Label.Name = "Label"
                Label.Parent = TextboxFrame
                Label.BackgroundTransparency = 1
                Label.Size = UDim2.new(1, 0, 0, 14)
                Label.Font = Font
                Label.Text = Text:lower()
                Label.TextColor3 = Colors.Text
                Label.TextSize = 12
                Label.TextXAlignment = Enum.TextXAlignment.Left

                local Box = Instance.new("TextBox")
                Box.Name = "Box"
                Box.Parent = TextboxFrame
                Box.BackgroundColor3 = Colors.Element
                Box.BorderSizePixel = 0
                Box.Position = UDim2.new(0, 0, 0, 18)
                Box.Size = UDim2.new(1, 0, 0, 18)
                Box.Font = Font
                Box.Text = Value
                Box.TextColor3 = Colors.Text
                Box.TextSize = 12
                Box.TextXAlignment = Enum.TextXAlignment.Left
                Box.PlaceholderText = "enter text..."
                Box.PlaceholderColor3 = Colors.DarkText
                Box.ClearTextOnFocus = false

                local BoxPadding = Instance.new("UIPadding")
                BoxPadding.Parent = Box
                BoxPadding.PaddingLeft = UDim.new(0, 5)

                local BoxStroke = Instance.new("UIStroke")
                BoxStroke.Parent = Box
                BoxStroke.Color = Colors.GroupBorder
                BoxStroke.Thickness = 1

                Box.FocusLost:Connect(function(enterPressed)
                    Value = Box.Text
                    Callback(Value)
                end)

                return {
                    Set = function(self, Val)
                        Value = Val
                        Box.Text = Val
                    end
                }
            end

            return Groupbox
        end

        return Tab
    end

    return Window
end

-- Replicate exact UI
local Win = Library:CreateWindow("Neverlose Replication")
local Legit = Win:CreateTab("legit")
local Rage = Win:CreateTab("rage")
local Players = Win:CreateTab("players")
local Visuals = Win:CreateTab("visuals")
local Dealers = Win:CreateTab("dealers")
local Misc = Win:CreateTab("misc")
local Config = Win:CreateTab("config")

-- Players Tab - Player List

-- Spectate system
local SpectateTarget = nil
local SpectateCharConn = nil
local SpectateCamConn = nil

local function StopSpectate()
    if SpectateCharConn then SpectateCharConn:Disconnect() SpectateCharConn = nil end
    if SpectateCamConn then SpectateCamConn:Disconnect() SpectateCamConn = nil end
    workspace.CurrentCamera.CameraSubject = LocalPlayer.Character
    SpectateTarget = nil
end

local function StartSpectate(player)
    -- Stop any existing spectate first
    StopSpectate()
    
    SpectateTarget = player
    
    if player.Character then
        workspace.CurrentCamera.CameraSubject = player.Character
    end
    
    -- Re-attach camera if target respawns
    SpectateCharConn = player.CharacterAdded:Connect(function(char)
        repeat task.wait() until char:FindFirstChild("HumanoidRootPart")
        if SpectateTarget == player then
            workspace.CurrentCamera.CameraSubject = char
        end
    end)
    
    -- Re-attach if something else steals the camera subject
    SpectateCamConn = workspace.CurrentCamera:GetPropertyChangedSignal("CameraSubject"):Connect(function()
        if SpectateTarget == player and player.Character then
            workspace.CurrentCamera.CameraSubject = player.Character
        end
    end)
end

-- Clean up spectate if target leaves
table.insert(Connections, game:GetService("Players").PlayerRemoving:Connect(function(player)
    if SpectateTarget == player then
        StopSpectate()
        Library:Notify("spectate ended: " .. player.Name .. " left", 3)
    end
end))
local PlayerListGroup = Players:CreateGroupbox("player list", "full")

-- Add a label that will show player count

-- Store player list data
local PlayerListData = {}

local function GetPlayerLevel(player)
    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats then
        local level = leaderstats:FindFirstChild("Level") or leaderstats:FindFirstChild("level")
        if level and (level:IsA("IntValue") or level:IsA("NumberValue")) then
            return tostring(math.floor(level.Value))
        end
    end
    return "?"
end

local function GetPlayerBackpack(player)
    local backpack = player:FindFirstChild("Backpack")
    local character = player.Character
    local items = {}
    
    if backpack then
        for _, tool in ipairs(backpack:GetChildren()) do
            if tool:IsA("Tool") then
                table.insert(items, tool.Name)
            end
        end
    end
    
    if character then
        for _, tool in ipairs(character:GetChildren()) do
            if tool:IsA("Tool") then
                table.insert(items, "[" .. tool.Name .. "]")
            end
        end
    end
    
    return #items > 0 and table.concat(items, ", ") or "none"
end

local function GetPlayerHealth(player)
    local character = player.Character
    if character then
        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid then
            return string.format("%d/%d", math.floor(humanoid.Health), math.floor(humanoid.MaxHealth))
        end
    end
    return "?"
end

-- Create player info display using buttons (they look like labels but are clickable)
local function GetPlayerLevelNum(player)
    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats then
        local level = leaderstats:FindFirstChild("Level") or leaderstats:FindFirstChild("level")
        if level and (level:IsA("IntValue") or level:IsA("NumberValue")) then
            return tonumber(level.Value) or 0
        end
    end
    return 0
end

local function UpdatePlayerListDisplay()
    for player, data in pairs(PlayerListData) do
        if data.button and data.button.Parent then
            local displayName = player.DisplayName
            local username = player.Name
            local level = GetPlayerLevel(player)
            local health = GetPlayerHealth(player)
            local backpack = GetPlayerBackpack(player)
            
            local text = string.format("%s (@%s) | lvl: %s | hp: %s", 
                displayName:lower(), username:lower(), level, health)
            
            data.label.Text = text
            data.backpackLabel.Text = "items: " .. backpack:lower()
            
            -- Keep sorted by level high to low
            data.button.LayoutOrder = -GetPlayerLevelNum(player)
        end
    end
end

-- Initialize player list

local function CreatePlayerEntry(player)
    local playerLabel = Instance.new("TextLabel")
    playerLabel.Name = player.Name
    playerLabel.BackgroundColor3 = Colors.Element
    playerLabel.BorderSizePixel = 0
    playerLabel.Size = UDim2.new(1, 0, 0, 40)
    playerLabel.Font = Font
    playerLabel.TextColor3 = Colors.Text
    playerLabel.TextSize = 11
    playerLabel.TextXAlignment = Enum.TextXAlignment.Left
    playerLabel.TextYAlignment = Enum.TextYAlignment.Top
    playerLabel.Text = ""
    playerLabel.LayoutOrder = -GetPlayerLevelNum(player)
    playerLabel.Parent = PlayerListGroup.ElementList

    local labelStroke = Instance.new("UIStroke")
    labelStroke.Parent = playerLabel
    labelStroke.Color = Colors.GroupBorder
    labelStroke.Thickness = 1

    local padding = Instance.new("UIPadding")
    padding.Parent = playerLabel
    padding.PaddingLeft = UDim.new(0, 5)
    padding.PaddingTop = UDim.new(0, 3)

    local backpackLabel = Instance.new("TextLabel")
    backpackLabel.Name = "Backpack"
    backpackLabel.Parent = playerLabel
    backpackLabel.BackgroundTransparency = 1
    backpackLabel.Position = UDim2.new(0, 5, 0, 18)
    backpackLabel.Size = UDim2.new(1, -80, 0, 15)
    backpackLabel.Font = Font
    backpackLabel.TextColor3 = Colors.DarkText
    backpackLabel.TextSize = 10
    backpackLabel.TextXAlignment = Enum.TextXAlignment.Left
    backpackLabel.TextTruncate = Enum.TextTruncate.AtEnd

    -- Spectate button
    local SpectateBtn = Instance.new("TextButton")
    SpectateBtn.Name = "SpectateBtn"
    SpectateBtn.Parent = playerLabel
    SpectateBtn.BackgroundColor3 = Colors.Element
    SpectateBtn.BorderSizePixel = 0
    SpectateBtn.Position = UDim2.new(1, -68, 0.5, -9)
    SpectateBtn.Size = UDim2.new(0, 60, 0, 18)
    SpectateBtn.Font = Font
    SpectateBtn.Text = "spectate"
    SpectateBtn.TextColor3 = Colors.DarkText
    SpectateBtn.TextSize = 10
    SpectateBtn.AutoButtonColor = false

    local SpectateBtnStroke = Instance.new("UIStroke")
    SpectateBtnStroke.Parent = SpectateBtn
    SpectateBtnStroke.Color = Colors.GroupBorder
    SpectateBtnStroke.Thickness = 1

    SpectateBtn.MouseButton1Click:Connect(function()
        if SpectateTarget == player then
            -- Currently spectating this player, stop
            StopSpectate()
            SpectateBtn.Text = "spectate"
            SpectateBtn.TextColor3 = Colors.DarkText
            SpectateBtnStroke.Color = Colors.GroupBorder
        else
            -- Stop spectating previous target's button if any
            if SpectateTarget and PlayerListData[SpectateTarget] then
                local oldBtn = PlayerListData[SpectateTarget].spectateBtn
                if oldBtn then
                    oldBtn.Text = "spectate"
                    oldBtn.TextColor3 = Colors.DarkText
                    PlayerListData[SpectateTarget].spectateBtnStroke.Color = Colors.GroupBorder
                end
            end
            -- Start spectating this player
            StartSpectate(player)
            SpectateBtn.Text = "unspectate"
            SpectateBtn.TextColor3 = Colors.Accent
            SpectateBtnStroke.Color = Colors.GroupBorder
        end
    end)

    SpectateBtn.MouseEnter:Connect(function()
        if SpectateTarget ~= player then
            SpectateBtn.TextColor3 = Colors.Text
        end
    end)
    SpectateBtn.MouseLeave:Connect(function()
        if SpectateTarget ~= player then
            SpectateBtn.TextColor3 = Colors.DarkText
        end
    end)

    PlayerListData[player] = {
        button = playerLabel,
        label = playerLabel,
        backpackLabel = backpackLabel,
        spectateBtn = SpectateBtn,
        spectateBtnStroke = SpectateBtnStroke
    }
end

for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
    if player ~= LocalPlayer then
        CreatePlayerEntry(player)
    end
end

-- Connect player events
table.insert(Connections, game:GetService("Players").PlayerAdded:Connect(function(player)
    if player ~= LocalPlayer then
        task.wait(0.5) -- Wait for player to load
        CreatePlayerEntry(player)
    end
end))

table.insert(Connections, game:GetService("Players").PlayerRemoving:Connect(function(player)
    if PlayerListData[player] then
        if PlayerListData[player].button then
            PlayerListData[player].button:Destroy()
        end
        PlayerListData[player] = nil
    end
end))

-- Update player list every second
local lastPlayerListUpdate = 0
table.insert(Connections, RunService.Heartbeat:Connect(function()
    local now = tick()
    if now - lastPlayerListUpdate >= 1 then
        lastPlayerListUpdate = now
        UpdatePlayerListDisplay()
    end
end))

-- Create restock timer display at the top of the left column
local RestockFrame = Instance.new("Frame")
RestockFrame.Name = "RestockTimer"
RestockFrame.Parent = Dealers.Page
RestockFrame.BackgroundColor3 = Colors.Element
RestockFrame.BorderSizePixel = 0
RestockFrame.Position = UDim2.new(0, 0, 0, 0)
RestockFrame.Size = UDim2.new(0.5, -10, 0, 30)

local RestockStroke = Instance.new("UIStroke")
RestockStroke.Parent = RestockFrame
RestockStroke.Color = Colors.GroupBorder
RestockStroke.Thickness = 1

local RestockLabel = Instance.new("TextLabel")
RestockLabel.Name = "Label"
RestockLabel.Parent = RestockFrame
RestockLabel.BackgroundTransparency = 1
RestockLabel.Size = UDim2.new(1, 0, 1, 0)
RestockLabel.Font = Font
RestockLabel.Text = "restock: --:--"
RestockLabel.TextColor3 = Colors.Text
RestockLabel.TextSize = 13
RestockLabel.TextXAlignment = Enum.TextXAlignment.Center

-- Update restock timer
local function UpdateRestockTimer()
    local shopz = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Shopz")
    if shopz then
        local dealer = shopz:FindFirstChildOfClass("Model")
        if dealer then
            local restockTime = dealer:FindFirstChild("RestockTime")
            if restockTime and (restockTime:IsA("IntValue") or restockTime:IsA("NumberValue") or restockTime:IsA("IntConstrainedValue")) then
                local seconds = restockTime.Value
                if seconds > 0 then
                    local minutes = math.floor(seconds / 60)
                    local secs = seconds % 60
                    RestockLabel.Text = string.format("restock: %02d:%02d", minutes, secs)
                    RestockLabel.TextColor3 = Colors.Text
                else
                    RestockLabel.Text = "restock: ready"
                    RestockLabel.TextColor3 = Colors.Accent
                end
            else
                RestockLabel.Text = "restock: --:--"
                RestockLabel.TextColor3 = Colors.DarkText
            end
        end
    end
end

-- Update timer every frame
table.insert(Connections, RunService.Heartbeat:Connect(function()
    UpdateRestockTimer()
end))

-- Update LeftY to start below the timer
Dealers.LeftY = 30 + 30

local ArmoryGroup = Dealers:CreateGroupbox("armory dealers", "left")
local NormalGroup = Dealers:CreateGroupbox("normal dealers", "right")

local DealerStockLabels = {}

local function GetDealerStock(dealerModel)
    local stocks = dealerModel:FindFirstChild("CurrentStocks")
    if not stocks then return {} end
    
    local inStock = {}
    for _, item in ipairs(stocks:GetChildren()) do
        if item:IsA("IntConstrainedValue") or item:IsA("IntValue") or item:IsA("NumberValue") then
            local value = item.Value
            local itemName = item.Name:gsub("^_", ""):lower()
            table.insert(inStock, {name = itemName, count = value})
        end
    end
    
    -- Sort by name
    table.sort(inStock, function(a, b) return a.name < b.name end)
    
    return inStock
end

local function FindDealerModel(dealerName)
    local shopz = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Shopz")
    if not shopz then return nil end
    
    for _, dealer in ipairs(shopz:GetChildren()) do
        local name, cat = GetDealerInfo(dealer)
        if name == dealerName then
            return dealer
        end
    end
    return nil
end

local function CreateDealerToggleWithStock(groupbox, dealerData)
    WorldESP.SpecificDealers[dealerData.Name] = true
    
    local toggle = groupbox:CreateToggle(dealerData.Name, true, function(state)
        WorldESP.SpecificDealers[dealerData.Name] = state
    end)
    
    local stockLabel = groupbox:CreateButton("view stock", function()
        local dealer = FindDealerModel(dealerData.Name)
        if dealer then
            local stock = GetDealerStock(dealer)
            
            -- Clear previous stock display
            for _, child in ipairs(Win.StockScroll:GetChildren()) do
                if child:IsA("TextLabel") then
                    child:Destroy()
                end
            end
            
            -- Update title
            Win.StockTitle.Text = dealerData.Name .. " stock"
            
            -- Show panel
            Win.StockPanel.Visible = true
            
            local hasStock = false
            for _, item in ipairs(stock) do
                if item.count > 0 then
                    hasStock = true
                    local ItemLabel = Instance.new("TextLabel")
                    ItemLabel.Parent = Win.StockScroll
                    ItemLabel.BackgroundTransparency = 1
                    ItemLabel.Size = UDim2.new(1, 0, 0, 18)
                    ItemLabel.Font = Font
                    ItemLabel.TextSize = 12
                    ItemLabel.TextXAlignment = Enum.TextXAlignment.Left
                    ItemLabel.Text = item.name .. " x" .. tostring(item.count)
                    ItemLabel.TextColor3 = Colors.Text
                end
            end
            
            if not hasStock then
                local NoStock = Instance.new("TextLabel")
                NoStock.Parent = Win.StockScroll
                NoStock.BackgroundTransparency = 1
                NoStock.Size = UDim2.new(1, 0, 0, 18)
                NoStock.Font = Font
                NoStock.Text = "no items found"
                NoStock.TextColor3 = Colors.DarkText
                NoStock.TextSize = 12
                NoStock.TextXAlignment = Enum.TextXAlignment.Left
            end
        else
            Win.StockTitle.Text = "dealer not found"
            Win.StockPanel.Visible = true
            
            for _, child in ipairs(Win.StockScroll:GetChildren()) do
                if child:IsA("TextLabel") then
                    child:Destroy()
                end
            end
        end
    end)
    
    DealerStockLabels[dealerData.Name] = stockLabel
end

for _, data in ipairs(DealerConfigs.Armory) do
    CreateDealerToggleWithStock(ArmoryGroup, data)
end

for _, data in ipairs(DealerConfigs.Normal) do
    CreateDealerToggleWithStock(NormalGroup, data)
end

-- Silent Aim Configuration already initialized at top of script

-- Valid target parts
local ValidSilentTargetParts = {"Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg"}

-- Create FOV Circle
local SilentAimCircle = Drawing.new("Circle")
SilentAimCircle.Thickness = 2
SilentAimCircle.NumSides = 50
SilentAimCircle.Radius = SilentAim.FOV
SilentAimCircle.Filled = false
SilentAimCircle.Visible = false
SilentAimCircle.ZIndex = 999
SilentAimCircle.Transparency = 1
SilentAimCircle.Color = SilentAim.CircleColor

-- Update circle position
local function UpdateSilentAimCircle()
    if SilentAim.Enabled and SilentAim.DrawCircle then
        local mousePos = UserInputService:GetMouseLocation()
        SilentAimCircle.Position = Vector2.new(mousePos.X, mousePos.Y)
        SilentAimCircle.Radius = SilentAim.FOV
        SilentAimCircle.Color = SilentAim.CircleColor
        SilentAimCircle.Visible = true
    else
        SilentAimCircle.Visible = false
    end
end

-- Get closest target function
local function GetSilentAimTarget()
    if not SilentAim.Enabled then return nil end
    
    local closestPlayer = nil
    local minDistance = SilentAim.FOV
    local mousePos = UserInputService:GetMouseLocation()
    local camera = workspace.CurrentCamera
    
    for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
        if player == LocalPlayer then continue end
        if not player.Character then continue end
        if player.Character:FindFirstChildOfClass("ForceField") then continue end
        
        local humanoid = player.Character:FindFirstChild("Humanoid")
        if not humanoid or humanoid.Health <= 0 then continue end
        
        -- Team check
        if SilentAim.CheckTeam and player.Team == LocalPlayer.Team then continue end
        
        -- Get target part
        local targetPart = nil
        if SilentAim.TargetPart == "Closest" then
            local minPartDistance = math.huge
            for _, partName in ipairs(ValidSilentTargetParts) do
                local part = player.Character:FindFirstChild(partName)
                if part then
                    local screenPos, onScreen = camera:WorldToViewportPoint(part.Position)
                    if onScreen then
                        local dist = (Vector2.new(mousePos.X, mousePos.Y) - Vector2.new(screenPos.X, screenPos.Y)).Magnitude
                        if dist < minPartDistance then
                            minPartDistance = dist
                            targetPart = part
                        end
                    end
                end
            end
        elseif SilentAim.TargetPart == "Random" then
            local partName = ValidSilentTargetParts[math.random(1, #ValidSilentTargetParts)]
            targetPart = player.Character:FindFirstChild(partName)
        else
            targetPart = player.Character:FindFirstChild(SilentAim.TargetPart)
        end
        
        if not targetPart then continue end
        
        -- Wallbang check - only check walls if wallbang is disabled
        if not SilentAim.Wallbang then
            local rayParams = RaycastParams.new()
            rayParams.FilterDescendantsInstances = {camera, LocalPlayer.Character, player.Character}
            rayParams.FilterType = Enum.RaycastFilterType.Blacklist
            
            local origin = camera.CFrame.Position
            local direction = (targetPart.Position - origin).Unit * (targetPart.Position - origin).Magnitude
            local rayResult = workspace:Raycast(origin, direction, rayParams)
            
            if rayResult then continue end
        end
        
        -- Check if on screen and within FOV
        local screenPos, onScreen = camera:WorldToViewportPoint(targetPart.Position)
        if onScreen then
            local distance = (Vector2.new(mousePos.X, mousePos.Y) - Vector2.new(screenPos.X, screenPos.Y)).Magnitude
            if distance < minDistance then
                closestPlayer = player
                minDistance = distance
            end
        end
    end
    
    -- Hit chance check
    if closestPlayer and SilentAim.UseHitChance then
        if math.random(1, 100) > SilentAim.HitChance then
            return nil
        end
    end
    
    return closestPlayer
end

-- Silent Aim Main Logic
local function EnableSilentAim()
    if SilentAim.Task then return end
    
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local VisualizeEvent = ReplicatedStorage:WaitForChild("Events2"):WaitForChild("Visualize")
    local DamageEvent = ReplicatedStorage:WaitForChild("Events"):WaitForChild("ZFKLF__H")
    
    -- Target tracking task
    SilentAim.Task = task.spawn(function()
        while SilentAim.Enabled do
            local nextTarget = GetSilentAimTarget()
            SilentAim.CurrentTarget = nextTarget
            task.wait(0.1)
        end
    end)
    
    -- Hook into shot visualization
    SilentAim.VisualizeConnection = VisualizeEvent.Event:Connect(function(_, ShotCode, _, Gun, _, StartPos, BulletsPerShot)
        if not (SilentAim.Enabled and Gun and SilentAim.CurrentTarget and SilentAim.CurrentTarget.Character) then return end
        if SilentAim.CurrentTarget.Character:FindFirstChildOfClass("ForceField") then return end
        
        local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
        if not tool or Gun ~= tool then return end
        
        -- Determine hit part
        local HitPart
        local targetPartSetting = SilentAim.TargetPart
        
        if targetPartSetting == "Closest" then
            local minDist = math.huge
            local mousePos = UserInputService:GetMouseLocation()
            for _, partName in ipairs(ValidSilentTargetParts) do
                local part = SilentAim.CurrentTarget.Character:FindFirstChild(partName)
                if part then
                    local screenPos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(part.Position)
                    if onScreen then
                        local dist = (Vector2.new(mousePos.X, mousePos.Y) - Vector2.new(screenPos.X, screenPos.Y)).Magnitude
                        if dist < minDist then
                            minDist = dist
                            HitPart = part
                        end
                    end
                end
            end
        elseif targetPartSetting == "Random" then
            local partName = ValidSilentTargetParts[math.random(1, #ValidSilentTargetParts)]
            HitPart = SilentAim.CurrentTarget.Character:FindFirstChild(partName)
        else
            HitPart = SilentAim.CurrentTarget.Character:FindFirstChild(targetPartSetting)
        end
        
        if not HitPart then return end
        
        local HitPos = HitPart.Position
        local bulletCount = math.clamp(#BulletsPerShot, 1, 100)
        local lookVector = CFrame.new(StartPos, HitPos).LookVector
        local Bullets = table.create(bulletCount, lookVector)
        
        task.wait() -- Frame buffer
        
        -- Fire damage events
        for i = 1, bulletCount do
            DamageEvent:FireServer("🧈", Gun, ShotCode, i, HitPart, HitPos, Bullets[i])
        end
        
        -- Play hitsound
        PlayHitsound()
        
        -- Play hitmarker sound
        if Gun:FindFirstChild("Hitmarker") then
            Gun.Hitmarker:Fire(HitPart)
        end
    end)
end

local function DisableSilentAim()
    if SilentAim.Task then
        task.cancel(SilentAim.Task)
        SilentAim.Task = nil
    end
    
    if SilentAim.VisualizeConnection then
        SilentAim.VisualizeConnection:Disconnect()
        SilentAim.VisualizeConnection = nil
    end
    
    SilentAim.CurrentTarget = nil
end

-- Update circle every frame
table.insert(Connections, RunService.RenderStepped:Connect(function()
    UpdateSilentAimCircle()
end))

-- Melee Aura System already initialized at top of script

local function GetMeleeTarget()
    if not MeleeAura.Enabled then return nil end
    
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return nil end
    local hrp = char.HumanoidRootPart
    
    local closestPlayer = nil
    local closestDist = MeleeAura.Distance
    
    for _, player in pairs(game:GetService("Players"):GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local targetHRP = player.Character:FindFirstChild("HumanoidRootPart")
            local targetHum = player.Character:FindFirstChildOfClass("Humanoid")
            
            if targetHRP and targetHum and targetHum.Health > 0 then
                -- Team check
                if MeleeAura.CheckTeam and player.Team == LocalPlayer.Team then
                    goto continue
                end
                
                -- ForceField check
                if player.Character:FindFirstChildOfClass("ForceField") then
                    goto continue
                end
                
                local dist = (hrp.Position - targetHRP.Position).Magnitude
                if dist < closestDist then
                    closestDist = dist
                    closestPlayer = player
                end
            end
            ::continue::
        end
    end
    
    return closestPlayer
end

-- Melee Aura loop
local LastMeleeAttack = 0
local MeleeAttackCooldown = 0.35

table.insert(Connections, RunService.Heartbeat:Connect(function()
    if not MeleeAura.Enabled then return end
    
    local char = LocalPlayer.Character
    if not char then return end
    
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then return end
    
    -- Check if it's a melee weapon (no Config means it's melee in Criminality)
    local config = tool:FindFirstChild("Config")
    if config then return end -- Skip guns
    
    local target = GetMeleeTarget()
    MeleeAura.CurrentTarget = target
    
    if target and target.Character then
        local now = tick()
        if now - LastMeleeAttack < MeleeAttackCooldown then return end
        
        -- Fire melee attack
        local remote1 = game:GetService("ReplicatedStorage"):FindFirstChild("Events") and game:GetService("ReplicatedStorage").Events:FindFirstChild("XMHH.2")
        local remote2 = game:GetService("ReplicatedStorage"):FindFirstChild("Events") and game:GetService("ReplicatedStorage").Events:FindFirstChild("XMHH2.2")
        
        if remote1 and remote2 then
            local result = remote1:InvokeServer("🍞", tick(), tool, "43TRFWX", "Normal", tick(), true)
            
            -- Play animation
            if MeleeAura.ShowAnimation then
                local animFolder = tool:FindFirstChild("AnimsFolder")
                if animFolder then
                    local anim = animFolder:FindFirstChild("Slash1")
                    if anim then
                        local humanoid = char:FindFirstChildOfClass("Humanoid")
                        if humanoid then
                            local animator = humanoid:FindFirstChild("Animator")
                            if animator then
                                local track = animator:LoadAnimation(anim)
                                track:Play(0.1, 1, 1.3)
                            end
                        end
                    end
                end
            end
            
            task.wait(0.3)
            
            -- Hit target
            local handle = tool:FindFirstChild("WeaponHandle") or tool:FindFirstChild("Handle")
            if handle then
                local targetPart = target.Character:FindFirstChild("Head") or target.Character:FindFirstChild("Torso") or target.Character:FindFirstChild("HumanoidRootPart")
                if targetPart then
                    local arg2 = {
                        "🍞",
                        tick(),
                        tool,
                        "2389ZFX34",
                        result,
                        true,
                        handle,
                        targetPart,
                        target.Character,
                        char.HumanoidRootPart.Position,
                        targetPart.Position
                    }
                    remote2:FireServer(unpack(arg2))
                    LastMeleeAttack = now
                    PlayHitsound()
                end
            end
        end
    end
end))

-- Aimbot System already initialized at top of script

local AimbotCircle = Drawing.new("Circle")
AimbotCircle.Thickness = 2
AimbotCircle.NumSides = 64
AimbotCircle.Radius = 100
AimbotCircle.Filled = false
AimbotCircle.Visible = false
AimbotCircle.ZIndex = 999
AimbotCircle.Transparency = 1
AimbotCircle.Color = Color3.fromRGB(255, 255, 255)

local function UpdateAimbotCircle()
    if Aimbot.Enabled and Aimbot.DrawCircle then
        local mousePos = UserInputService:GetMouseLocation()
        AimbotCircle.Position = Vector2.new(mousePos.X, mousePos.Y)
        AimbotCircle.Radius = Aimbot.FOV
        AimbotCircle.Visible = true
    else
        AimbotCircle.Visible = false
    end
end

local function GetAimbotTarget()
    if not Aimbot.Enabled then return nil end
    
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return nil end
    
    local closestPlayer = nil
    local closestDist = Aimbot.FOV
    local mousePos = UserInputService:GetMouseLocation()
    
    for _, player in pairs(game:GetService("Players"):GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local targetPart = player.Character:FindFirstChild(Aimbot.TargetPart)
            local targetHum = player.Character:FindFirstChildOfClass("Humanoid")
            
            if targetPart and targetHum and targetHum.Health > 0 then
                -- Team check
                if Aimbot.CheckTeam and player.Team == LocalPlayer.Team then
                    goto continue
                end
                
                -- ForceField check
                if player.Character:FindFirstChildOfClass("ForceField") then
                    goto continue
                end
                
                -- Wall check
                if Aimbot.CheckWalls then
                    local ray = Ray.new(workspace.CurrentCamera.CFrame.Position, (targetPart.Position - workspace.CurrentCamera.CFrame.Position).Unit * 1000)
                    local hit, pos = workspace:FindPartOnRayWithIgnoreList(ray, {char, player.Character})
                    if hit then
                        goto continue
                    end
                end
                
                local screenPos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(targetPart.Position)
                if onScreen then
                    local dist = (Vector2.new(mousePos.X, mousePos.Y) - Vector2.new(screenPos.X, screenPos.Y)).Magnitude
                    if dist < closestDist then
                        closestDist = dist
                        closestPlayer = player
                    end
                end
            end
            ::continue::
        end
    end
    
    return closestPlayer
end

-- Aimbot loop
local AimbotActive = false

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        AimbotActive = true
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        AimbotActive = false
        Aimbot.CurrentTarget = nil
    end
end)

table.insert(Connections, RunService.RenderStepped:Connect(function()
    UpdateAimbotCircle()
    
    if not Aimbot.Enabled or not AimbotActive then return end
    
    local target = GetAimbotTarget()
    Aimbot.CurrentTarget = target
    
    if target and target.Character then
        local targetPart = target.Character:FindFirstChild(Aimbot.TargetPart)
        if targetPart then
            local targetPos = targetPart.Position
            local camera = workspace.CurrentCamera
            local currentCFrame = camera.CFrame
            local targetCFrame = CFrame.new(currentCFrame.Position, targetPos)
            
            -- Apply smoothing
            local newCFrame = currentCFrame:Lerp(targetCFrame, Aimbot.Smoothing)
            camera.CFrame = newCFrame
        end
    end
end))

-- Killsound detection - monitor when players die
for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
    if player ~= LocalPlayer then
        local function OnCharacterAdded(character)
            local humanoid = character:WaitForChild("Humanoid", 5)
            if humanoid then
                humanoid.Died:Connect(function()
                    -- Check if we recently hit this player (within last 5 seconds)
                    if SilentAim.CurrentTarget == player then
                        PlayKillsound()
                    end
                end)
            end
        end
        
        if player.Character then
            OnCharacterAdded(player.Character)
        end
        player.CharacterAdded:Connect(OnCharacterAdded)
    end
end

table.insert(Connections, game:GetService("Players").PlayerAdded:Connect(function(player)
    if player ~= LocalPlayer then
        local function OnCharacterAdded(character)
            local humanoid = character:WaitForChild("Humanoid", 5)
            if humanoid then
                humanoid.Died:Connect(function()
                    if SilentAim.CurrentTarget == player then
                        PlayKillsound()
                    end
                end)
            end
        end
        
        if player.Character then
            OnCharacterAdded(player.Character)
        end
        player.CharacterAdded:Connect(OnCharacterAdded)
    end
end))

local Group = Legit:CreateGroupbox("per weapon configuration")
Group:CreateToggle("enable", true, function() end)
Group:CreateToggle("enable slider animations", false, function() end)
Group:CreateSlider("field of view", 0, 20, 7.0, 1, function() end)
Group:CreateDropdown("target selection", {"distance", "fov", "health"}, "distance", function() end)
Group:CreateDropdown("hitscan", {"-", "head", "body", "all"}, "-", function() end)

-- Melee Aura UI
local MeleeAuraGroup = Legit:CreateGroupbox("melee aura", "left")

MeleeAuraGroup:CreateToggle("enabled", false, function(state)
    MeleeAura.Enabled = state
end)

MeleeAuraGroup:CreateSlider("distance", 5, 30, 15, 0, function(value)
    MeleeAura.Distance = value
end)

MeleeAuraGroup:CreateToggle("show animation", true, function(state)
    MeleeAura.ShowAnimation = state
end)

MeleeAuraGroup:CreateToggle("team check", false, function(state)
    MeleeAura.CheckTeam = state
end)

-- Aimbot UI
local AimbotGroup = Legit:CreateGroupbox("aimbot", "left")

AimbotGroup:CreateToggle("enabled", false, function(state)
    Aimbot.Enabled = state
end)

AimbotGroup:CreateToggle("draw fov circle", false, function(state)
    Aimbot.DrawCircle = state
end)

AimbotGroup:CreateSlider("field of view", 10, 300, 100, 0, function(value)
    Aimbot.FOV = value
end)

AimbotGroup:CreateSlider("smoothing", 0.1, 1, 0.5, 2, function(value)
    Aimbot.Smoothing = value
end)

AimbotGroup:CreateDropdown("target part", {"Head", "Torso", "HumanoidRootPart"}, "Head", function(value)
    Aimbot.TargetPart = value
end)

AimbotGroup:CreateToggle("check walls", false, function(state)
    Aimbot.CheckWalls = state
end)

AimbotGroup:CreateToggle("team check", false, function(state)
    Aimbot.CheckTeam = state
end)

-- Silent Aim UI
local SilentAimGroup = Legit:CreateGroupbox("silent aim", "right")

SilentAimGroup:CreateToggle("enabled", false, function(state)
    SilentAim.Enabled = state
    if state then
        EnableSilentAim()
    else
        DisableSilentAim()
    end
end)

SilentAimGroup:CreateToggle("draw fov circle", false, function(state)
    SilentAim.DrawCircle = state
end)

SilentAimGroup:CreateSlider("field of view", 10, 300, 100, 0, function(value)
    SilentAim.FOV = value
end)

SilentAimGroup:CreateToggle("use hit chance", false, function(state)
    SilentAim.UseHitChance = state
end)

SilentAimGroup:CreateSlider("hit chance %", 0, 100, 100, 0, function(value)
    SilentAim.HitChance = value
end)

SilentAimGroup:CreateToggle("wallbang", false, function(state)
    SilentAim.Wallbang = state
end)

SilentAimGroup:CreateToggle("team check", false, function(state)
    SilentAim.CheckTeam = state
end)

SilentAimGroup:CreateDropdown("target part", {"Closest", "Random", "Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg"}, "Head", function(value)
    SilentAim.TargetPart = value
end)

local ConfigGroup = Config:CreateGroupbox("menu settings", "left")

-- Folder Management Section
ConfigGroup:CreateButton("verify folders", function()
    local result = EnsureFoldersExist()
    if result then
        Library:Notify("all folders verified successfully", 3)
    else
        Library:Notify("some folders failed - check console", 4)
    end
end)

ConfigGroup:CreateButton("open workspace folder", function()
    if Logs then
        print("Jebe: Workspace folder location:")
        print("  Look for 'workspace' or 'bin/workspace' in your executor folder")
        print("  Then navigate to: workspace/Jebe/")
        print("")
        print("Folder structure:")
        for _, folder in ipairs(FolderStructure) do
            print("  - " .. folder)
        end
    end
    Library:Notify("check console for folder location", 4)
end)

ConfigGroup:CreateToggle("logs", false, function(state)
    Logs = state
end)

ConfigGroup:CreateToggle("rainbow accent", false, function(state)
    RainbowAccent = state
end)

ConfigGroup:CreateColorpicker("accent color", Color3.fromRGB(255, 255, 255), function(color)
    if not RainbowAccent then
        UpdateAccentColor(color)
    end
end)

ConfigGroup:CreateDropdown("font", GetAllFonts(), "Ubuntu", function(fontName)
    CurrentFont = fontName
    local fontEnum = Enum.Font[fontName]
    if fontEnum then
        Font = fontEnum
        -- Update all UI text elements
        for _, element in ipairs(Win.MainFrame:GetDescendants()) do
            if element:IsA("TextLabel") or element:IsA("TextButton") or element:IsA("TextBox") then
                element.Font = fontEnum
            end
        end
        -- Update ESP text
        for _, drawings in pairs(ESP.Players) do
            if drawings.nameText and drawings.nameText.object then
                drawings.nameText.object.Font = Drawing.Fonts.System
            end
            if drawings.distanceText and drawings.distanceText.object then
                drawings.distanceText.object.Font = Drawing.Fonts.System
            end
        end
        Library:Notify("font changed to: " .. fontName, 3)
    end
end)

ConfigGroup:CreateKeybind("menu toggle", Enum.KeyCode.Delete, function(key)
    Win.MainFrame.Visible = not Win.MainFrame.Visible
end)

ConfigGroup:CreateButton("unload", function()
    -- Stop rainbow loop
    RainbowRunning = false
    
    -- Stop freecam if running
    if fcRunning then
        StopFreecam()
    end
    
    -- Disconnect all connections
    for _, conn in ipairs(Connections) do
        if conn then conn:Disconnect() end
    end
    
    -- Clean up player ESP
    for player, _ in pairs(ESP.Players) do
        RemovePlayerESP(player)
    end
    
    -- Clean up world ESP
    for obj, _ in pairs(WorldESP.Objects) do
        RemoveWorldDrawings(obj)
    end
    
    -- Clean up sounds
    if SoundSystem.Hitsound.SoundObject then
        SoundSystem.Hitsound.SoundObject:Destroy()
    end
    if SoundSystem.Killsound.SoundObject then
        SoundSystem.Killsound.SoundObject:Destroy()
    end
    
    -- Destroy UI
    if Win.MainFrame then Win.MainFrame:Destroy() end
    if ESPImageGui then ESPImageGui:Destroy() end
    
    Library:Notify("unloaded Jebe", 3)
end)

-- Config Management
local ConfigManageGroup = Config:CreateGroupbox("config management", "right")

-- Display folder status
local folderStatusText = foldersReady and "✓ folders ready" or "⚠ folders incomplete"
ConfigManageGroup:CreateButton(folderStatusText, function()
    local status = {}
    if isfolder then
        for _, folder in ipairs(FolderStructure) do
            local exists = isfolder(folder)
            table.insert(status, (exists and "✓" or "✗") .. " " .. folder)
        end
        
        if Logs then
            print("Jebe: Folder Status:")
            for _, line in ipairs(status) do
                print("  " .. line)
            end
        end
        
        Library:Notify("folder status printed to console", 3)
    else
        Library:Notify("isfolder not supported", 3)
    end
end)

local ConfigNameInput = ""
ConfigManageGroup:CreateTextbox("config name", "default", function(text)
    ConfigNameInput = text
end)

ConfigManageGroup:CreateButton("save config", function()
    if ConfigNameInput == "" then
        Library:Notify("enter a config name", 3)
        return
    end
    SaveConfig(ConfigNameInput)
end)

ConfigManageGroup:CreateButton("load config", function()
    if ConfigNameInput == "" then
        Library:Notify("enter a config name", 3)
        return
    end
    LoadConfig(ConfigNameInput)
end)

ConfigManageGroup:CreateButton("delete config", function()
    if ConfigNameInput == "" then
        Library:Notify("enter a config name", 3)
        return
    end
    DeleteConfig(ConfigNameInput)
end)

ConfigManageGroup:CreateButton("reset to default", function()
    ResetToDefault()
end)

ConfigManageGroup:CreateButton("refresh config list", function()
    local configs = GetConfigList()
    Library:Notify("found " .. #configs .. " configs", 3)
    for _, cfg in ipairs(configs) do
        if Logs then print("Config: " .. cfg) end
    end
end)

-- Sounds
local SoundsGroup = Config:CreateGroupbox("sounds", "left")

SoundsGroup:CreateToggle("hitsound enabled", false, function(state)
    SoundSystem.Hitsound.Enabled = state
end)

SoundsGroup:CreateDropdown("hitsound", ScanSoundFiles("Hitsounds"), "None", function(soundName)
    SoundSystem.Hitsound.CurrentSound = soundName
    LoadHitsound(soundName)
end)

SoundsGroup:CreateSlider("hitsound volume", 0, 1, 0.5, 2, function(value)
    SoundSystem.Hitsound.Volume = value
    if SoundSystem.Hitsound.SoundObject then
        SoundSystem.Hitsound.SoundObject.Volume = value
    end
end)

SoundsGroup:CreateSlider("hitsound cooldown", 0, 3, 0.1, 2, function(value)
    SoundSystem.Hitsound.Cooldown = value
end)

SoundsGroup:CreateToggle("killsound enabled", false, function(state)
    SoundSystem.Killsound.Enabled = state
end)

SoundsGroup:CreateDropdown("killsound", ScanSoundFiles("Killsounds"), "None", function(soundName)
    SoundSystem.Killsound.CurrentSound = soundName
    LoadKillsound(soundName)
end)

SoundsGroup:CreateSlider("killsound volume", 0, 1, 0.5, 2, function(value)
    SoundSystem.Killsound.Volume = value
    if SoundSystem.Killsound.SoundObject then
        SoundSystem.Killsound.SoundObject.Volume = value
    end
end)
    for obj, _ in pairs(WorldESP.Objects) do
        RemoveWorldDrawings(obj)
    end
    
    -- Clean up all ESP drawing objects
    for _, obj in pairs(ESP.allDrawingObjects) do
        if obj then
            pcall(function() obj:Remove() end)
        end
    end
    
    -- Destroy ESP image GUI
    if ESPImageGui then
        ESPImageGui:Destroy()
    end
    
    -- Destroy notification GUI
    local notifGui = CoreGui:FindFirstChild("JebeNotificationsGui")
    if notifGui then
        notifGui:Destroy()
    end
    
    -- Destroy main GUI
    Win.ScreenGui:Destroy()
    
    if Logs then print("Jebe unloaded successfully!") end
end)

ConfigGroup:CreateButton("reload image", function()
    CustomImage = LoadAsset("Jebe/image.png")
    if CustomImage then
        if Logs then print("Jebe: image.png reloaded!") end
    else
        if Logs then warn("Jebe: image.png reload failed.") end
    end
    for _, drawings in pairs(ESP.Players) do
        if drawings.ImageGui then
            drawings.ImageGui.Image = CustomImage or ""
        end
    end
end)

-- Image selector dropdown
local ImageFiles = {}
local SelectedImageFile = "image.png"
local ImageDropdown = nil

local function ScanImageFiles()
    ImageFiles = {}
    if listfiles then
        local files = listfiles("Jebe/Images")
        for _, file in ipairs(files) do
            local fileName = file:match("Jebe[\\/]Images[\\/](.+)$") or file:match("([^\\/]+)$")
            if fileName and fileName:lower():match("%.png$") then
                table.insert(ImageFiles, fileName)
            end
        end
    end
    
    if #ImageFiles == 0 then
        table.insert(ImageFiles, "image.png")
    end
    
    table.sort(ImageFiles)
    return ImageFiles
end

-- Initial scan
ScanImageFiles()

ImageDropdown = ConfigGroup:CreateDropdown("select image", ImageFiles, SelectedImageFile, function(selected)
    SelectedImageFile = selected
    CustomImage = LoadAsset("Jebe/Images/" .. selected)
    if CustomImage then
        if Logs then print("Jebe: Loaded " .. selected) end
        Library:Notify("loaded: " .. selected, 3)
    else
        if Logs then warn("Jebe: Failed to load " .. selected) end
        Library:Notify("failed to load: " .. selected, 3)
    end
    
    -- Update all player images
    for _, drawings in pairs(ESP.Players) do
        if drawings.ImageGui then
            drawings.ImageGui.Image = CustomImage or ""
        end
    end
end)

ConfigGroup:CreateButton("refresh images", function()
    local newFiles = ScanImageFiles()
    
    -- Update dropdown with new files
    ImageDropdown:Refresh(newFiles)
    
    Library:Notify("found " .. #newFiles .. " image(s)", 3)
    if Logs then print("Jebe: Found images:", table.concat(newFiles, ", ")) end
end)

ConfigGroup:CreateButton("test notify", function()
    Library:Notify("test notification!", 5)
end)

ConfigGroup:CreateButton("test mystery box", function()
    Library:Notify("mystery box spawned!", 5)
end)

ConfigGroup:CreateButton("test airdrop", function()
    Library:Notify("airdrop spawned!", 5)
end)

ConfigGroup:CreateButton("test cope coin", function()
    Library:Notify("cope coin in stock!", 5)
end)

ConfigGroup:CreateButton("test rebel dealer", function()
    Library:Notify("rebel dealer spawned!", 5)
end)

local VisualsGroup = Visuals:CreateGroupbox("player esp", "left")

VisualsGroup:CreateToggle("enabled", false, function(state)
    ESP.Enabled = state
end)

VisualsGroup:CreateToggle("boxes", false, function(state)
    ESP.Boxes = state
end)

VisualsGroup:CreateToggle("health bars", false, function(state)
    ESP.HealthBars = state
end)

VisualsGroup:CreateToggle("names", false, function(state)
    ESP.Names = state
end)

VisualsGroup:CreateToggle("distances", false, function(state)
    ESP.Distances = state
end)

VisualsGroup:CreateToggle("image esp", false, function(state)
    ESP.Images = state
end)

VisualsGroup:CreateSlider("image transparency", 0, 1, 0, 2, function(value)
    ESP.ImageTransparency = value
end)

VisualsGroup:CreateToggle("team check", false, function(state)
    ESP.TeamCheck = state
end)

VisualsGroup:CreateColorpicker("box color", Color3.fromRGB(255, 255, 255), function(color)
    ESP.BoxColor = color
end)

VisualsGroup:CreateColorpicker("name color", Color3.fromRGB(255, 255, 255), function(color)
    ESP.NameColor = color
end)

VisualsGroup:CreateColorpicker("distance color", Color3.fromRGB(255, 255, 255), function(color)
    ESP.DistColor = color
end)

VisualsGroup:CreateColorpicker("health low color", Color3.fromRGB(255, 100, 100), function(color)
    ESP.HealthLowColor = color
end)

VisualsGroup:CreateColorpicker("health full color", Color3.fromRGB(100, 255, 100), function(color)
    ESP.HealthFullColor = color
end)

local WorldGroup = Visuals:CreateGroupbox("world esp", "right")

WorldGroup:CreateToggle("enabled", false, function(state)
    WorldESP.Enabled = state
end)

WorldGroup:CreateToggle("dealers", false, function(state)
    WorldESP.Dealers = state
end)

WorldGroup:CreateColorpicker("dealer color", Color3.fromRGB(100, 200, 255), function(color)
    WorldESP.DealerColor = color
end)

WorldGroup:CreateToggle("rebel dealer", false, function(state)
    WorldESP.RebelDealer = state
end)

WorldGroup:CreateColorpicker("rebel dealer color", Color3.fromRGB(0, 255, 0), function(color)
    WorldESP.RebelColor = color
end)

WorldGroup:CreateToggle("airdrops", false, function(state)
    WorldESP.Airdrops = state
end)

WorldGroup:CreateColorpicker("airdrop color", Color3.fromRGB(150, 30, 255), function(color)
    WorldESP.AirdropColor = color
end)

WorldGroup:CreateToggle("rare crates", false, function(state)
    WorldESP.RareCrates = state
end)

WorldGroup:CreateColorpicker("rare crate color", Color3.fromRGB(255, 0, 0), function(color)
    WorldESP.RareCrateColor = color
end)

WorldGroup:CreateToggle("cope coins", false, function(state)
    WorldESP.CopeCoins = state
end)

WorldGroup:CreateColorpicker("cope coin color", Color3.fromRGB(150, 255, 0), function(color)
    WorldESP.CopeCoinColor = color
end)

WorldGroup:CreateToggle("mystery boxes", false, function(state)
    WorldESP.MysteryBoxes = state
end)

WorldGroup:CreateColorpicker("mystery box color", Color3.fromRGB(255, 255, 0), function(color)
    WorldESP.MysteryBoxColor = color
end)

WorldGroup:CreateToggle("names", false, function(state)
    WorldESP.Names = state
end)

WorldGroup:CreateToggle("distances", false, function(state)
    WorldESP.Distances = state
end)

local MiscGroup = Misc:CreateGroupbox("miscellaneous", "left")

-- Freecam System
local fcRunning = false
local cameraPos = Vector3.new()
local cameraRot = Vector2.new()
local cameraFov = 70

local Spring = {} do
	Spring.__index = Spring

	function Spring.new(freq, pos)
		local self = setmetatable({}, Spring)
		self.f = freq
		self.p = pos
		self.v = pos*0
		return self
	end

	function Spring:Update(dt, goal)
		local f = self.f*2*math.pi
		local p0 = self.p
		local v0 = self.v

		local offset = goal - p0
		local decay = math.exp(-f*dt)

		local p1 = goal + (v0*dt - offset*(f*dt + 1))*decay
		local v1 = (f*dt*(offset*f - v0) + v0)*decay

		self.p = p1
		self.v = v1

		return p1
	end

	function Spring:Reset(pos)
		self.p = pos
		self.v = pos*0
	end
end

local velSpring = Spring.new(5, Vector3.new())
local panSpring = Spring.new(5, Vector2.new())

local Input = {} do
	local keyboard = {
		W = 0, A = 0, S = 0, D = 0, E = 0, Q = 0,
		Up = 0, Down = 0, LeftShift = 0,
	}

	local mouse = {
		Delta = Vector2.new(),
	}

	local NAV_KEYBOARD_SPEED = Vector3.new(1, 1, 1)
	local PAN_MOUSE_SPEED = Vector2.new(1, 1)*(math.pi/64)
	local NAV_ADJ_SPEED = 0.75
	local NAV_SHIFT_MUL = 0.25
	local navSpeed = 1
	local INPUT_PRIORITY = Enum.ContextActionPriority.High.Value
	local ContextActionService = game:GetService("ContextActionService")

	function Input.Vel(dt)
		navSpeed = math.clamp(navSpeed + dt*(keyboard.Up - keyboard.Down)*NAV_ADJ_SPEED, 0.01, 4)

		local kKeyboard = Vector3.new(
			keyboard.D - keyboard.A,
			keyboard.E - keyboard.Q,
			keyboard.S - keyboard.W
		)*NAV_KEYBOARD_SPEED

		local shift = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
		return (kKeyboard)*(navSpeed*(shift and NAV_SHIFT_MUL or 1))
	end

	function Input.Pan(dt)
		local kMouse = mouse.Delta*PAN_MOUSE_SPEED
		mouse.Delta = Vector2.new()
		return kMouse
	end

	local function Keypress(action, state, input)
		keyboard[input.KeyCode.Name] = state == Enum.UserInputState.Begin and 1 or 0
		return Enum.ContextActionResult.Sink
	end

	local function MousePan(action, state, input)
		local delta = input.Delta
		mouse.Delta = Vector2.new(-delta.y, -delta.x)
		return Enum.ContextActionResult.Sink
	end

	local function Zero(t)
		for k, v in pairs(t) do
			t[k] = v*0
		end
	end

	function Input.StartCapture()
		ContextActionService:BindActionAtPriority("FreecamKeyboard",Keypress,false,INPUT_PRIORITY,
			Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D,
			Enum.KeyCode.E, Enum.KeyCode.Q, Enum.KeyCode.Up, Enum.KeyCode.Down
		)
		ContextActionService:BindActionAtPriority("FreecamMousePan",MousePan,false,INPUT_PRIORITY,Enum.UserInputType.MouseMovement)
	end

	function Input.StopCapture()
		navSpeed = 1
		Zero(keyboard)
		Zero(mouse)
		ContextActionService:UnbindAction("FreecamKeyboard")
		ContextActionService:UnbindAction("FreecamMousePan")
	end

	function Input.SetSpeed(speed)
		NAV_KEYBOARD_SPEED = Vector3.new(speed, speed, speed)
	end
end

local function GetFocusDistance(cameraFrame)
	local znear = 0.1
	local viewport = workspace.CurrentCamera.ViewportSize
	local projy = 2*math.tan(cameraFov/2)
	local projx = viewport.x/viewport.y*projy
	local fx = cameraFrame.rightVector
	local fy = cameraFrame.upVector
	local fz = cameraFrame.lookVector

	local minVect = Vector3.new()
	local minDist = 512

	for x = 0, 1, 0.5 do
		for y = 0, 1, 0.5 do
			local cx = (x - 0.5)*projx
			local cy = (y - 0.5)*projy
			local offset = fx*cx - fy*cy + fz
			local origin = cameraFrame.p + offset*znear
			local _, hit = workspace:FindPartOnRay(Ray.new(origin, offset.unit*minDist))
			local dist = (hit - origin).magnitude
			if minDist > dist then
				minDist = dist
				minVect = offset.unit
			end
		end
	end

	return fz:Dot(minVect)*minDist
end

local function StepFreecam(dt)
	local vel = velSpring:Update(dt, Input.Vel(dt))
	local pan = panSpring:Update(dt, Input.Pan(dt))

	local zoomFactor = math.sqrt(math.tan(math.rad(70/2))/math.tan(math.rad(cameraFov/2)))

	cameraRot = cameraRot + pan*Vector2.new(0.75, 1)*8*(dt/zoomFactor)
	cameraRot = Vector2.new(math.clamp(cameraRot.x, -math.rad(90), math.rad(90)), cameraRot.y%(2*math.pi))

	local cameraCFrame = CFrame.new(cameraPos)*CFrame.fromOrientation(cameraRot.x, cameraRot.y, 0)*CFrame.new(vel*Vector3.new(1, 1, 1)*64*dt)
	cameraPos = cameraCFrame.p

	workspace.CurrentCamera.CFrame = cameraCFrame
	workspace.CurrentCamera.Focus = cameraCFrame*CFrame.new(0, 0, -GetFocusDistance(cameraCFrame))
	workspace.CurrentCamera.FieldOfView = cameraFov
end

local PlayerState = {} do
	local mouseBehavior, mouseIconEnabled, cameraType, cameraFocus, cameraCFrame, cameraFieldOfView

	function PlayerState.Push()
		cameraFieldOfView = workspace.CurrentCamera.FieldOfView
		workspace.CurrentCamera.FieldOfView = 70

		cameraType = workspace.CurrentCamera.CameraType
		workspace.CurrentCamera.CameraType = Enum.CameraType.Custom

		cameraCFrame = workspace.CurrentCamera.CFrame
		cameraFocus = workspace.CurrentCamera.Focus

		mouseIconEnabled = UserInputService.MouseIconEnabled
		UserInputService.MouseIconEnabled = true

		mouseBehavior = UserInputService.MouseBehavior
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	end

	function PlayerState.Pop()
		workspace.CurrentCamera.FieldOfView = cameraFieldOfView or 70
		workspace.CurrentCamera.CameraType = cameraType or Enum.CameraType.Custom
		
		if cameraCFrame then
			workspace.CurrentCamera.CFrame = cameraCFrame
		end
		if cameraFocus then
			workspace.CurrentCamera.Focus = cameraFocus
		end
		
		if mouseIconEnabled ~= nil then
			UserInputService.MouseIconEnabled = mouseIconEnabled
		end
		if mouseBehavior then
			UserInputService.MouseBehavior = mouseBehavior
		end
		
		-- Clear saved values
		cameraFieldOfView = nil
		cameraType = nil
		cameraCFrame = nil
		cameraFocus = nil
		mouseIconEnabled = nil
		mouseBehavior = nil
	end
end

local function StartFreecam(pos)
	if fcRunning then
		return
	end
	local cameraCFrame = workspace.CurrentCamera.CFrame
	if pos then
		cameraCFrame = pos
	end
	cameraRot = Vector2.new()
	cameraPos = cameraCFrame.p
	cameraFov = workspace.CurrentCamera.FieldOfView

	velSpring:Reset(Vector3.new())
	panSpring:Reset(Vector2.new())

	PlayerState.Push()
	RunService:BindToRenderStep("Freecam", Enum.RenderPriority.Camera.Value, StepFreecam)
	Input.StartCapture()
	fcRunning = true
	Library:Notify("freecam enabled", 2)
end

local function StopFreecam()
	if not fcRunning then return end
	
	fcRunning = false
	Input.StopCapture()
	RunService:UnbindFromRenderStep("Freecam")
	
	-- Small delay to ensure everything is unbound
	task.wait(0.1)
	
	PlayerState.Pop()
	
	-- Force reset camera
	if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
		workspace.CurrentCamera.CameraSubject = LocalPlayer.Character.Humanoid
	end
	
	Library:Notify("freecam disabled", 2)
end

local FreecamGroup = Misc:CreateGroupbox("freecam", "right")

FreecamGroup:CreateKeybind("freecam toggle", Enum.KeyCode.KeypadMultiply, function(key)
	if fcRunning then
		StopFreecam()
	else
		StartFreecam()
	end
end)

FreecamGroup:CreateKeybind("freecam teleport", Enum.KeyCode.KeypadMinus, function(key)
	if fcRunning and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
		LocalPlayer.Character.HumanoidRootPart.CFrame = workspace.CurrentCamera.CFrame
		StopFreecam()
		Library:Notify("teleported to freecam position", 2)
	end
end)

FreecamGroup:CreateSlider("freecam speed", 0.1, 5, 1, 1, function(value)
	Input.SetSpeed(value)
end)

local MiscGroup = Misc:CreateGroupbox("miscellaneous", "left")
MiscGroup:CreateButton("rejoin", function()
    game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
end)

MiscGroup:CreateButton("no arms", function()
    local char = LocalPlayer.Character
    if not char then return end
    for _, v in pairs(char:GetChildren()) do
        if v:IsA("BasePart") then
            if v.Name == "RightUpperArm" or v.Name == "LeftUpperArm" -- R15
            or v.Name == "Right Arm" or v.Name == "Left Arm" then    -- R6
                v:Destroy()
            end
        end
    end
    Library:Notify("arms removed", 2)
end)

MiscGroup:CreateButton("no legs", function()
    local char = LocalPlayer.Character
    if not char then return end
    for _, v in pairs(char:GetChildren()) do
        if v:IsA("BasePart") then
            if v.Name == "RightUpperLeg" or v.Name == "LeftUpperLeg" -- R15
            or v.Name == "Right Leg" or v.Name == "Left Leg" then    -- R6
                v:Destroy()
            end
        end
    end
    Library:Notify("legs removed", 2)
end)

MiscGroup:CreateButton("dex", function()
    local success, result = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/infyiff/backup/main/dex.lua"))
    end)
    if success and result then
        result()
    else
        Library:Notify("failed to load dex", 3)
    end
end)

MiscGroup:CreateButton("jerk tool", function()
    local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildWhichIsA("Humanoid")
    local backpack = LocalPlayer:FindFirstChildWhichIsA("Backpack")
    if not humanoid or not backpack then return end

    local tool = Instance.new("Tool")
    tool.Name = "Jerk Off"
    tool.ToolTip = "in the stripped club. straight up \"jorking it\" . and by \"it\" , haha, well. let's justr say. My peanits."
    tool.RequiresHandle = false
    tool.Parent = backpack

    local jorkin = false
    local track = nil

    local function stopTomfoolery()
        jorkin = false
        if track then
            track:Stop()
            track = nil
        end
    end

    tool.Equipped:Connect(function() jorkin = true end)
    tool.Unequipped:Connect(stopTomfoolery)
    humanoid.Died:Connect(stopTomfoolery)

    task.spawn(function()
        while tool and tool.Parent do
            task.wait()
            if not jorkin then continue end

            local isR15 = humanoid.RigType == Enum.HumanoidRigType.R15
            if not track then
                local anim = Instance.new("Animation")
                anim.AnimationId = not isR15 and "rbxassetid://72042024" or "rbxassetid://698251653"
                track = humanoid:LoadAnimation(anim)
            end

            track:Play()
            track:AdjustSpeed(isR15 and 0.7 or 0.65)
            track.TimePosition = 0.6
            task.wait(0.1)
            while track and track.TimePosition < (not isR15 and 0.65 or 0.7) do task.wait(0.1) end
            if track then
                track:Stop()
                track = nil
            end
        end
    end)
end)

-- Notifications
task.spawn(function()
    local mysteryFolder = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("MysteryBoxes")
    if mysteryFolder then
        table.insert(Connections, mysteryFolder.ChildAdded:Connect(function(child)
            if child.Name == "MysteryBox" then
                Library:Notify("mystery box spawned!", 5)
            end
        end))
    end

    local planeFolder = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("SpawnedSupplyPlanes")
    if planeFolder then
        table.insert(Connections, planeFolder.ChildAdded:Connect(function()
            Library:Notify("airdrop spawned!", 5)
        end))
    end

    local shopz = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Shopz")
    if shopz then
        local function checkCope(dealer)
            if dealer.Name == "RebelDealer" then
                Library:Notify("rebel dealer spawned!", 5)
            end
            local stocks = dealer:WaitForChild("CurrentStocks", 3)
            if stocks then
                local coin = stocks:WaitForChild("_CopeCoin26", 3)
                if coin then
                    table.insert(Connections, coin.Changed:Connect(function(val)
                        if val == 1 then Library:Notify("cope coin in stock!", 5) end
                    end))
                end
            end
        end
        for _, dealer in pairs(shopz:GetChildren()) do checkCope(dealer) end
        table.insert(Connections, shopz.ChildAdded:Connect(checkCope))
    end
end)

-- Character Modifications already initialized at top of script

local CharacterGroup = Misc:CreateGroupbox("character", "right")

CharacterGroup:CreateToggle("walkspeed", false, function(state)
    CharacterMods.WalkspeedEnabled = state
end)

CharacterGroup:CreateSlider("speed", 16, 100, 35, 0, function(value)
    CharacterMods.WalkspeedValue = value
end)

CharacterGroup:CreateToggle("noclip", false, function(state)
    CharacterMods.NoclipEnabled = state
end)

CharacterGroup:CreateToggle("infinite stamina", false, function(state)
    CharacterMods.InfiniteStaminaEnabled = state
end)

CharacterGroup:CreateToggle("no jump cooldown", false, function(state)
    CharacterMods.NoJumpCooldown = state
end)

CharacterGroup:CreateToggle("no fall damage", false, function(state)
    CharacterMods.NoFallDamage = state
end)

CharacterGroup:CreateToggle("no ragdoll", false, function(state)
    CharacterMods.NoRagdoll = state
end)

-- Character mods loop
table.insert(Connections, RunService.Heartbeat:Connect(function()
    local char = LocalPlayer.Character
    if not char then return end
    
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    
    -- Walkspeed
    if CharacterMods.WalkspeedEnabled then
        humanoid.WalkSpeed = CharacterMods.WalkspeedValue
    end
    
    -- Noclip
    if CharacterMods.NoclipEnabled then
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end
    
    -- Infinite Stamina (Criminality specific)
    if CharacterMods.InfiniteStaminaEnabled then
        local stamina = char:FindFirstChild("Stamina")
        if stamina and stamina:IsA("NumberValue") then
            stamina.Value = 100
        end
    end
end))

-- Gun Modifications already initialized at top of script

local GunModsGroup = Misc:CreateGroupbox("gun mods", "left")

GunModsGroup:CreateToggle("enabled", false, function(state)
    GunMods.Enabled = state
end)

GunModsGroup:CreateToggle("no recoil", false, function(state)
    GunMods.NoRecoil = state
end)

GunModsGroup:CreateToggle("no spread", false, function(state)
    GunMods.NoSpread = state
end)

GunModsGroup:CreateToggle("fast equip", false, function(state)
    GunMods.FastEquip = state
end)

GunModsGroup:CreateToggle("automatic all", false, function(state)
    GunMods.AutomaticAll = state
end)

GunModsGroup:CreateSlider("firerate multiplier", 1, 5, 1, 1, function(value)
    GunMods.FireRateMultiplier = value
end)

-- Gun mods implementation (hook into gun config)
local FakeConfig = {}
local RealConfig = game:GetService("ReplicatedStorage"):FindFirstChild("Modules") and game:GetService("ReplicatedStorage").Modules:FindFirstChild("Config")

if RealConfig then
    function FakeConfig.GetConfig(NIL, Tool)
        local GunSettings = {}
        
        for Setting, Value in pairs(require(Tool:WaitForChild("Config"))) do
            if GunMods.Enabled then
                if Setting == "Recoil" and GunMods.NoRecoil then
                    Value = 0
                end
                if Setting == "Spread" and GunMods.NoSpread then
                    Value = 0
                end
                if Setting == "EquipTime" and GunMods.FastEquip then
                    Value = 0.1
                end
                if Setting == "FireRate" then
                    Value = Value * GunMods.FireRateMultiplier
                end
                if Setting == "Auto" and GunMods.AutomaticAll then
                    Value = true
                end
            end
            
            GunSettings[Setting] = Value
        end
        
        return GunSettings
    end
    
    local OldRequire
    OldRequire = hookfunction(require, function(module, ...)
        if module == RealConfig then
            return FakeConfig
        end
        return OldRequire(module, ...)
    end)
end

-- Auto Pickup already initialized at top of script

local AutoPickupGroup = Misc:CreateGroupbox("auto pickup", "right")

AutoPickupGroup:CreateToggle("enabled", false, function(state)
    AutoPickup.Enabled = state
end)

AutoPickupGroup:CreateToggle("cash", false, function(state)
    AutoPickup.PickupCash = state
end)

AutoPickupGroup:CreateToggle("piles", false, function(state)
    AutoPickup.PickupPiles = state
end)

-- Auto pickup loop
local PilePickup = game:GetService("ReplicatedStorage"):FindFirstChild("Events") and game:GetService("ReplicatedStorage").Events:FindFirstChild("PIC_PU")
local CashPickup = game:GetService("ReplicatedStorage"):FindFirstChild("Events") and game:GetService("ReplicatedStorage").Events:FindFirstChild("CZDPZUS")

if PilePickup and CashPickup then
    table.insert(Connections, RunService.Heartbeat:Connect(function()
        if not AutoPickup.Enabled then return end
        if tick() - AutoPickup.LastPickup < AutoPickup.Cooldown then return end
        
        local char = LocalPlayer.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then return end
        local hrp = char.HumanoidRootPart
        
        local found = false
        
        -- Pickup piles
        if AutoPickup.PickupPiles then
            local piles = workspace:FindFirstChild("Filter") and workspace.Filter:FindFirstChild("SpawnedPiles")
            if piles then
                for _, pile in pairs(piles:GetChildren()) do
                    local mainPart = pile:FindFirstChild("MeshPart")
                    if mainPart then
                        local dist = (hrp.Position - mainPart.Position).Magnitude
                        if dist < 7 then
                            PilePickup:FireServer(mainPart)
                            found = true
                            break
                        end
                    end
                end
            end
        end
        
        -- Pickup cash
        if AutoPickup.PickupCash and not found then
            local cash = workspace:FindFirstChild("Filter") and workspace.Filter:FindFirstChild("SpawnedBread")
            if cash then
                for _, money in pairs(cash:GetChildren()) do
                    local dist = (hrp.Position - money.Position).Magnitude
                    if dist < 7 then
                        CashPickup:FireServer(money)
                        found = true
                        break
                    end
                end
            end
        end
        
        if found then
            AutoPickup.LastPickup = tick()
        end
    end))
end

-- Hitbox Expander already initialized at top of script

local HitboxGroup = Misc:CreateGroupbox("hitbox expander", "left")

HitboxGroup:CreateToggle("enabled", false, function(state)
    HitboxExpander.Enabled = state
end)

HitboxGroup:CreateSlider("size", 1, 20, 10, 0, function(value)
    HitboxExpander.Size = value
end)

HitboxGroup:CreateSlider("transparency", 0, 1, 0.5, 2, function(value)
    HitboxExpander.Transparency = value
end)

-- Hitbox expander loop
table.insert(Connections, RunService.Heartbeat:Connect(function()
    if not HitboxExpander.Enabled then return end
    
    for _, player in pairs(game:GetService("Players"):GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.Size = Vector3.new(HitboxExpander.Size, HitboxExpander.Size, HitboxExpander.Size)
                hrp.Transparency = HitboxExpander.Transparency
                hrp.CanCollide = false
            end
        end
    end
end))

-- FOV Changer already initialized at top of script

local FOVGroup = Misc:CreateGroupbox("fov changer", "right")

FOVGroup:CreateToggle("enabled", false, function(state)
    FOVChanger.Enabled = state
    if not state then
        workspace.CurrentCamera.FieldOfView = 70
    end
end)

FOVGroup:CreateSlider("field of view", 30, 120, 90, 0, function(value)
    FOVChanger.FOV = value
end)

-- FOV changer loop
table.insert(Connections, RunService.RenderStepped:Connect(function()
    if FOVChanger.Enabled then
        workspace.CurrentCamera.FieldOfView = FOVChanger.FOV
    end
end))

-- Extended Zoom already initialized at top of script

local ZoomGroup = Misc:CreateGroupbox("extended zoom", "left")

ZoomGroup:CreateToggle("enabled", false, function(state)
    ExtendedZoom.Enabled = state
    if state then
        LocalPlayer.CameraMaxZoomDistance = ExtendedZoom.MaxDistance
    else
        LocalPlayer.CameraMaxZoomDistance = 8
    end
end)

ZoomGroup:CreateSlider("max distance", 8, 200, 50, 0, function(value)
    ExtendedZoom.MaxDistance = value
    if ExtendedZoom.Enabled then
        LocalPlayer.CameraMaxZoomDistance = value
    end
end)

-- Fullbright already initialized at top of script

local LightingGroup = Misc:CreateGroupbox("lighting", "right")

LightingGroup:CreateToggle("fullbright", false, function(state)
    Fullbright.Enabled = state
    if state then
        game:GetService("Lighting").Brightness = 2
        game:GetService("Lighting").ClockTime = 14
        game:GetService("Lighting").FogEnd = 100000
        game:GetService("Lighting").GlobalShadows = false
        game:GetService("Lighting").OutdoorAmbient = Color3.fromRGB(128, 128, 128)
    else
        game:GetService("Lighting").Brightness = 1
        game:GetService("Lighting").ClockTime = 12
        game:GetService("Lighting").FogEnd = 100000
        game:GetService("Lighting").GlobalShadows = true
        game:GetService("Lighting").OutdoorAmbient = Color3.fromRGB(70, 70, 70)
    end
end)

LightingGroup:CreateToggle("no fog", false, function(state)
    if state then
        game:GetService("Lighting").FogEnd = 100000
    else
        game:GetService("Lighting").FogEnd = 500
    end
end)

-- Cleanup on script unload
local function Cleanup()
    for _, conn in pairs(Connections) do
        if conn and conn.Disconnect then
            pcall(function() conn:Disconnect() end)
        end
    end
    
    -- Remove all ESP drawings
    for _, obj in pairs(ESP.allDrawingObjects) do
        pcall(function() obj:Remove() end)
    end
    
    -- Remove all world ESP drawings
    for obj, _ in pairs(WorldESP.Objects) do
        RemoveWorldDrawings(obj)
    end
    
    -- Remove player ESP
    for player, _ in pairs(ESP.Players) do
        RemovePlayerESP(player)
    end
    
    -- Stop freecam if running
    if fcRunning then
        StopFreecam()
    end
    
    -- Reset camera
    workspace.CurrentCamera.FieldOfView = 70
    LocalPlayer.CameraMaxZoomDistance = 8
    
    -- Reset lighting
    game:GetService("Lighting").Brightness = 1
    game:GetService("Lighting").ClockTime = 12
    game:GetService("Lighting").FogEnd = 100000
    game:GetService("Lighting").GlobalShadows = true
    
    if Logs then print("Jebe: Cleaned up successfully") end
end

-- Register cleanup
if syn and syn.on_script_unload then
    syn.on_script_unload(Cleanup)
end

-- Startup notification with folder info
task.spawn(function()
    task.wait(1) -- Wait for UI to load
    
    Library:Notify("jebe.lua loaded successfully", 3)
    
    if foldersReady then
        task.wait(3)
        Library:Notify("folders ready in workspace/Jebe/", 4)
    else
        task.wait(3)
        Library:Notify("warning: some folders failed to create", 5)
    end
    
    if Logs then 
        print("Jebe: Script loaded for Criminality")
        print("Jebe: Folder structure:")
        for _, folder in ipairs(FolderStructure) do
            print("  - " .. folder)
        end
    end
end)

return Library

