local Players = game:GetService("Players")
local UIComponents = {}

function UIComponents.createTab(name, color)
    local tab = Instance.new("TextButton")
    tab.Size = UDim2.new(0.33, 0, 0, 40)
    tab.BackgroundColor3 = color
    tab.BackgroundTransparency = 0.5
    tab.Text = name
    tab.Font = Enum.Font.GothamBold
    tab.TextColor3 = Color3.fromRGB(44, 44, 44)
    tab.TextSize = 14

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = tab

    return tab
end

function UIComponents.createPlayerEntry(player, data)
    local entry = Instance.new("Frame")
    entry.Size = UDim2.new(1, 0, 0, 60)
    entry.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    entry.BackgroundTransparency = 0.9

    local avatar = Instance.new("ImageLabel")
    avatar.Size = UDim2.new(0, 40, 0, 40)
    avatar.Position = UDim2.new(0, 10, 0, 10)
    avatar.Image = Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
    avatar.Parent = entry

    local name = Instance.new("TextLabel")
    name.Size = UDim2.new(0.4, 0, 0, 20)
    name.Position = UDim2.new(0, 60, 0, 10)
    name.Text = player.DisplayName
    name.Font = Enum.Font.Gotham
    name.TextColor3 = Color3.fromRGB(44, 44, 44)
    name.TextSize = 14
    name.Parent = entry

    -- Add status information
    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(0.3, 0, 0, 20)
    status.Position = UDim2.new(0.5, 0, 0, 10)
    status.Text = string.format("Warnings: %d | Kicks: %d", data.warnings or 0, data.kicks or 0)
    status.Font = Enum.Font.Gotham
    status.TextColor3 = Color3.fromRGB(44, 44, 44)
    status.TextSize = 12
    status.Parent = entry

    -- Add timestamp if available
    if data.history and #data.history > 0 then
        local lastEvent = data.history[#data.history]
        local timestamp = Instance.new("TextLabel")
        timestamp.Size = UDim2.new(0.2, 0, 0, 20)
        timestamp.Position = UDim2.new(0.8, 0, 0, 10)
        timestamp.Text = os.date("%Y-%m-%d", lastEvent.timestamp)
        timestamp.Font = Enum.Font.Gotham
        timestamp.TextColor3 = Color3.fromRGB(100, 100, 100)
        timestamp.TextSize = 12
        timestamp.Parent = entry

        -- Add detailed incident info
        local incidentInfo = Instance.new("TextLabel")
        incidentInfo.Size = UDim2.new(0.8, 0, 0, 20)
        incidentInfo.Position = UDim2.new(0, 60, 0, 35)
        incidentInfo.Text = string.format(
            "Last Incident: %s | Server: %s%s",
            os.date("%Y-%m-%d %H:%M:%S", lastEvent.timestamp),
            lastEvent.serverJobId or "Unknown",
            data.banId and string.format(" | Ban ID: %s", data.banId) or ""
        )
        incidentInfo.Font = Enum.Font.Gotham
        incidentInfo.TextColor3 = Color3.fromRGB(100, 100, 100)
        incidentInfo.TextSize = 11
        incidentInfo.Parent = entry
    end

    return entry
end

return UIComponents
