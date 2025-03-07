local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MessagingService = game:GetService("MessagingService")
local DataManager = require(script.Parent.DataManager)

-- Remote events for client-server communication
local RemoteEvents = Instance.new("Folder")
RemoteEvents.Name = "AntiCheatRemotes"
RemoteEvents.Parent = ReplicatedStorage

local WarnPlayer = Instance.new("RemoteEvent")
WarnPlayer.Name = "WarnPlayer"
WarnPlayer.Parent = RemoteEvents

local OpenUI = Instance.new("RemoteEvent")
OpenUI.Name = "OpenAntiCheatUI"
OpenUI.Parent = RemoteEvents

-- Add RemoteFunction for fetching player data
local GetPlayerData = Instance.new("RemoteFunction")
GetPlayerData.Name = "GetPlayerData"
GetPlayerData.Parent = RemoteEvents

-- Add RemoteEvent for real-time log updates
local LogUpdate = Instance.new("RemoteEvent")
LogUpdate.Name = "LogUpdate"
LogUpdate.Parent = RemoteEvents

-- Anti-cheat detection patterns
local SUSPICIOUS_PATTERNS = {
    "require%(game", -- Attempting to require game services
    "getfenv", -- Environment manipulation
    "setfenv", -- Environment manipulation
    "loadstring", -- Dynamic code execution
    "HttpGet", -- External code loading
}

-- Warning management
local function checkForSuspiciousCode(player, code)
    for _, pattern in ipairs(SUSPICIOUS_PATTERNS) do
        if string.find(code, pattern) then
            print("[AntiCheat] Suspicious pattern detected:", pattern, "for player:", player.Name)
            return true, pattern
        end
    end
    return false, nil
end

local function handleWarning(player, pattern)
    local warningCount = DataManager:LogWarning(player, pattern)

    print("[AntiCheat] Warning issued to player:", player.Name, "Warning count:", warningCount)

    -- Send warning to player with consistent branding
    WarnPlayer:FireClient(player, string.format(
        "[Filo's AutoMod System] Warning %d/3\n" ..
        "Suspicious activity detected using pattern: %s\n" .. --Added pattern to warning message
        "Please stop using cheats.\n" ..
        "Next warning may result in a kick or ban.",
        warningCount, pattern
    ))

    if warningCount >= 3 then
        print("[AntiCheat] Player reached warning limit:", player.Name)
        -- Log kick
        DataManager:LogKick(player)
        -- Reset warnings -  This line was missing playerData declaration
        local playerData = DataManager:GetPlayerData(player)
        playerData.warnings = 0
        -- Check if player should be banned
        if DataManager:GetKickCount(player) >= 3 then
            print("[AntiCheat] Banning player due to multiple violations:", player.Name)
            local banId = DataManager:BanPlayer(player)
            player:Kick(string.format(
                "You have been BANNED by [Filo's AutoMod System]\n" ..
                "If this was a mistake, please report it in tickets with your Ban ID: %s",
                banId
            ))
        else
            player:Kick(
                "You have been KICKED by [Filo's AutoMod System]\n" ..
                "Don't worry if this is a mistake, you can join back - but without cheats next time!\n" ..
                "Note: Next violation will result in a permanent ban."
            )
        end
    end

    DataManager:SavePlayerData(player, playerData)
end

-- Admin command handling
local ADMIN_COMMANDS = {
    ["/anticheat"] = function(player)
        print("[AntiCheat] Admin UI opened by:", player.Name)
        OpenUI:FireClient(player)
    end,
    ["!openautomod"] = function(player)
        print("[AntiCheat] Admin UI opened by:", player.Name)
        OpenUI:FireClient(player)
    end,
    ["!AOM"] = function(player)
        print("[AntiCheat] Admin UI opened by:", player.Name)
        OpenUI:FireClient(player)
    end,
    ["!OAM"] = function(player)
        print("[AntiCheat] Admin UI opened by:", player.Name)
        OpenUI:FireClient(player)
    end,
    ["/anticheat lookup"] = function(player, banId)
        if banId then
            local data = DataManager:GetPlayerByBanId(banId)
            if data then
                return string.format(
                    "[Filo's AutoMod System] Ban Info:\n" ..
                    "Ban ID: %s\n" ..
                    "Reason: %s\n" ..
                    "Timestamp: %s",
                    data.banId,
                    data.banReason,
                    os.date("%Y-%m-%d %H:%M:%S", data.history[#data.history].timestamp)
                )
            end
            return "[Filo's AutoMod System] Ban ID not found."
        end
        return "[Filo's AutoMod System] Please provide a Ban ID."
    end,
    ["!lookup"] = function(player, banId)
        return ADMIN_COMMANDS["/anticheat lookup"](player, banId)
    end,
    ["!LU"] = function(player, banId)
        return ADMIN_COMMANDS["/anticheat lookup"](player, banId)
    end,
    ["/anticheat clear"] = function(player, targetUsername)
        if not targetUsername then
            return "[Filo's AutoMod System] Please provide a player username."
        end

        local targetPlayer = Players:FindFirstChild(targetUsername)
        if targetPlayer then
            DataManager:clearPlayerData(targetPlayer)
            return string.format("[Filo's AutoMod System] Cleared all logs for player: %s", targetUsername)
        end
        return string.format("[Filo's AutoMod System] Player not found: %s", targetUsername)
    end,
    ["!clear"] = function(player, targetUsername)
        return ADMIN_COMMANDS["/anticheat clear"](player, targetUsername)
    end,
    ["!CL"] = function(player, targetUsername)
        return ADMIN_COMMANDS["/anticheat clear"](player, targetUsername)
    end,
    ["/anticheat help"] = function()
        return [[
[Filo's AutoMod System] Available Commands:

Open AutoMod UI:
- !OAM (Open Auto Mod)
- !AOM (Auto Open Mod)
- !openautomod
- /anticheat

Look up banned player:
- !LU <banId> (Look Up)
- !lookup <banId>
- /anticheat lookup <banId>

Clear player logs:
- !CL <username> (Clear)
- !clear <username>
- /anticheat clear <username>

Show this help:
- !H (Help)
- !help
- /anticheat help

Note: All commands require admin permissions (Group rank 254+)
]]
    end,
    ["!help"] = function()
        return ADMIN_COMMANDS["/anticheat help"]()
    end,
    ["!H"] = function()
        return ADMIN_COMMANDS["/anticheat help"]()
    end
}

-- Command handling
local function handleCommand(player, message)
    if player:GetRankInGroup(game.CreatorId) >= 254 then
        local command = message:match("^(/[%w%s]+)")
        local args = message:sub(#(command or "") + 2)

        if command then
            local handler = ADMIN_COMMANDS[command]
            if handler then
                local response = handler(player, args)
                if response then
                    -- You can integrate this with your existing admin system's chat output
                    print("[AntiCheat] Command response:", response)
                end
            end
        end
    end
end

-- Handle data requests from client
GetPlayerData.OnServerInvoke = function(requestingPlayer)
    -- Only allow high-ranked players to access the data
    if requestingPlayer:GetRankInGroup(game.CreatorId) >= 254 then
        print("[AntiCheat] Admin data requested by:", requestingPlayer.Name)
        local allData = {}
        for _, player in ipairs(Players:GetPlayers()) do
            allData[player.UserId] = DataManager:GetPlayerData(player)
        end
        return allData
    end
    print("[AntiCheat] Unauthorized data request from:", requestingPlayer.Name)
    return nil
end

-- Player management
Players.PlayerAdded:Connect(function(player)
    print("[AntiCheat] Player joined:", player.Name)
    local data = DataManager:InitializePlayer(player)
    print("[AntiCheat] Player data initialized:", player.Name, "Warnings:", data.warnings, "Kicks:", data.kicks)

    player.Chatted:Connect(function(message)
        handleCommand(player, message)
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    print("[AntiCheat] Player leaving:", player.Name)
    local data = DataManager:GetPlayerData(player)
    DataManager:SavePlayerData(player, data)
    print("[AntiCheat] Player data saved:", player.Name)
end)

-- Set up messaging service for cross-server updates
MessagingService:SubscribeAsync("AntiCheatLogs", function(message)
    local data = message.Data
    -- Notify all admin clients about the update
    for _, adminPlayer in ipairs(Players:GetPlayers()) do
        if adminPlayer:GetRankInGroup(game.CreatorId) >= 254 then
            LogUpdate:FireClient(adminPlayer)
        end
    end
end)

-- Anti-cheat monitoring
game:GetService("RunService").Heartbeat:Connect(function()
    for _, player in ipairs(Players:GetPlayers()) do
        -- Basic script injection detection
        local character = player.Character
        if character then
            for _, descendant in ipairs(character:GetDescendants()) do
                if descendant:IsA("LocalScript") or descendant:IsA("ModuleScript") then
                    local isSuspicious, pattern = checkForSuspiciousCode(player, descendant.Source)
                    if isSuspicious then
                        handleWarning(player, pattern)
                    end
                end
            end
        end
    end
end)
