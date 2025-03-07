local DataStoreService = game:GetService("DataStoreService")
local AntiCheatStore = DataStoreService:GetDataStore("AntiCheatData")
local MessagingService = game:GetService("MessagingService")

local DataManager = {}

-- Generate a random 9-digit ban ID
local function generateBanId()
    return string.format("%09d", math.random(100000000, 999999999))
end

-- Real-time log update across servers
local function broadcastLogUpdate(userId, actionType, details)
    local success, err = pcall(function()
        MessagingService:PublishAsync("AntiCheatLogs", {
            userId = userId,
            actionType = actionType,
            details = details,
            timestamp = os.time(),
            serverId = game.JobId
        })
    end)
    if not success then
        warn("[DataManager] Failed to broadcast log update:", err)
    end
end

function DataManager:InitializePlayer(player)
    print("[DataManager] Initializing data for player:", player.Name)
    local success, data = pcall(function()
        return AntiCheatStore:GetAsync(player.UserId) or {
            warnings = 0,
            kicks = 0,
            banned = false,
            banReason = "",
            banId = "",
            history = {}
        }
    end)

    if not success then
        warn("[DataManager] Failed to load data for player:", player.Name, "Error:", data)
        return {
            warnings = 0,
            kicks = 0,
            banned = false,
            banReason = "",
            banId = "",
            history = {}
        }
    end

    print("[DataManager] Successfully loaded data for player:", player.Name)
    return data
end

function DataManager:GetPlayerByBanId(banId)
    local success, pages = pcall(function()
        return AntiCheatStore:GetSortedAsync("banId", false)
    end)

    if success then
        while true do
            local entries = pages:GetCurrentPage()
            for _, entry in ipairs(entries) do
                local data = entry.value
                if data.banId == banId then
                    return data
                end
            end
            if pages.IsFinished then
                break
            end
            pages:AdvanceToNextPageAsync()
        end
    end
    return nil
end

function DataManager:SavePlayerData(player, data)
    if not data then
        warn("[DataManager] Attempted to save nil data for player:", player.Name)
        return
    end

    print("[DataManager] Saving data for player:", player.Name)
    local success, err = pcall(function()
        AntiCheatStore:SetAsync(player.UserId, data)
    end)

    if not success then
        warn("[DataManager] Failed to save data for player:", player.Name, "Error:", err)
    else
        print("[DataManager] Successfully saved data for player:", player.Name)
    end
end

function DataManager:GetPlayerData(player)
    return self:InitializePlayer(player)
end

function DataManager:LogWarning(player, pattern)
    print("[DataManager] Logging warning for player:", player.Name)
    local data = self:GetPlayerData(player)
    data.warnings = data.warnings + 1

    local logEntry = {
        type = "warning",
        timestamp = os.time(),
        reason = string.format("Suspicious pattern detected: %s", pattern),
        warning_number = data.warnings,
        serverJobId = game.JobId
    }

    data.history[#data.history + 1] = logEntry
    self:SavePlayerData(player, data)

    -- Broadcast warning to all servers
    broadcastLogUpdate(player.UserId, "warning", logEntry)

    return data.warnings
end

function DataManager:LogKick(player)
    print("[DataManager] Logging kick for player:", player.Name)
    local data = self:GetPlayerData(player)
    data.kicks = data.kicks + 1

    local logEntry = {
        type = "kick",
        timestamp = os.time(),
        reason = "Multiple warnings",
        serverJobId = game.JobId
    }

    data.history[#data.history + 1] = logEntry
    self:SavePlayerData(player, data)

    -- Broadcast kick to all servers
    broadcastLogUpdate(player.UserId, "kick", logEntry)
end

function DataManager:BanPlayer(player)
    print("[DataManager] Banning player:", player.Name)
    local data = self:GetPlayerData(player)
    local banId = generateBanId()
    data.banned = true
    data.banId = banId
    data.banReason = "Multiple violations"

    local logEntry = {
        type = "ban",
        timestamp = os.time(),
        reason = "Multiple violations",
        banId = banId,
        serverJobId = game.JobId
    }

    data.history[#data.history + 1] = logEntry
    self:SavePlayerData(player, data)

    -- Broadcast ban to all servers
    broadcastLogUpdate(player.UserId, "ban", logEntry)

    return banId
end

function DataManager:GetKickCount(player)
    local data = self:GetPlayerData(player)
    return data.kicks
end

local function clearPlayerData(player)
    print("[DataManager] Clearing data for player:", player.Name)
    local data = {
        warnings = 0,
        kicks = 0,
        banned = false,
        banReason = "",
        banId = "",
        history = {}
    }
    self:SavePlayerData(player, data)

    -- Broadcast clear to all servers
    broadcastLogUpdate(player.UserId, "clear", {
        timestamp = os.time(),
        serverJobId = game.JobId
    })

    return data
end

-- Add the function to the DataManager table
DataManager.clearPlayerData = clearPlayerData

return DataManager
