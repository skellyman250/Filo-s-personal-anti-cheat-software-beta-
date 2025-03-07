local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UIComponents = require(ReplicatedStorage.UIComponents)
local Styles = require(script.Parent.Styles)

local player = Players.LocalPlayer
local OpenUI = ReplicatedStorage:WaitForChild("AntiCheatRemotes"):WaitForChild("OpenAntiCheatUI")
local GetPlayerData = ReplicatedStorage:WaitForChild("AntiCheatRemotes"):WaitForChild("GetPlayerData")

-- Create main UI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AntiCheatUI"
ScreenGui.Parent = player:WaitForChild("PlayerGui")
ScreenGui.Enabled = false

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0.6, 0, 0.7, 0)
MainFrame.Position = UDim2.new(0.2, 0, 0.15, 0)
MainFrame.BackgroundColor3 = Styles.Colors.Background
MainFrame.BackgroundTransparency = 0.1
MainFrame.Parent = ScreenGui

-- Add search bar at the top
local SearchFrame = Instance.new("Frame")
SearchFrame.Size = UDim2.new(1, -20, 0, 30)
SearchFrame.Position = UDim2.new(0, 10, 0, 10)
SearchFrame.BackgroundTransparency = 1
SearchFrame.Parent = MainFrame

local SearchBar = Instance.new("TextBox")
SearchBar.Size = UDim2.new(0.7, 0, 1, 0)
SearchBar.Position = UDim2.new(0, 0, 0, 0)
SearchBar.PlaceholderText = "Search by Ban ID..."
SearchBar.Text = ""
SearchBar.Font = Styles.Fonts.Primary
SearchBar.TextColor3 = Styles.Colors.TextColor
SearchBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
SearchBar.BackgroundTransparency = 0.8
SearchBar.Parent = SearchFrame

local SearchButton = Instance.new("TextButton")
SearchButton.Size = UDim2.new(0.25, 0, 1, 0)
SearchButton.Position = UDim2.new(0.75, 0, 0, 0)
SearchButton.Text = "Search"
SearchButton.Font = Styles.Fonts.Primary
SearchButton.TextColor3 = Styles.Colors.TextColor
SearchButton.BackgroundColor3 = Styles.Colors.RobloxBlue
SearchButton.BackgroundTransparency = 0.2
SearchButton.Parent = SearchFrame

-- Rest of the UI components (adjust positions)
local TabsFrame = Instance.new("Frame")
TabsFrame.Size = UDim2.new(1, 0, 0, 50)
TabsFrame.Position = UDim2.new(0, 0, 0, 45)  -- Adjusted position to account for search bar
TabsFrame.BackgroundTransparency = 1
TabsFrame.Parent = MainFrame

local WarningsTab = UIComponents.createTab("Warnings", Styles.Colors.WarningRed)
WarningsTab.Position = UDim2.new(0, 10, 0, 5)
WarningsTab.Parent = TabsFrame

local KicksTab = UIComponents.createTab("Kicks", Styles.Colors.RobloxBlue)
KicksTab.Position = UDim2.new(0.33, 10, 0, 5)
KicksTab.Parent = TabsFrame

local BansTab = UIComponents.createTab("Bans", Styles.Colors.SafeGreen)
BansTab.Position = UDim2.new(0.66, 10, 0, 5)
BansTab.Parent = TabsFrame

-- Content container
local ContentFrame = Instance.new("ScrollingFrame")
ContentFrame.Size = UDim2.new(1, -20, 1, -60)
ContentFrame.Position = UDim2.new(0, 10, 0, 100)  -- Adjusted position to account for search bar
ContentFrame.BackgroundTransparency = 1
ContentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ContentFrame.ScrollBarThickness = 6
ContentFrame.Parent = MainFrame

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 12)
UICorner.Parent = MainFrame

-- Get player data from server
local function fetchPlayerData()
    local success, data = pcall(function()
        return GetPlayerData:InvokeServer()
    end)

    if success and data then
        return data
    else
        warn("Failed to fetch player data")
        return {}
    end
end

-- Tab switching logic
local function switchTab(tabName)
    ContentFrame:ClearAllChildren()

    local playerData = fetchPlayerData()
    local yOffset = 0

    for _, plr in ipairs(Players:GetPlayers()) do
        local data = playerData[plr.UserId]
        if data then
            -- Filter based on tab
            local shouldShow = false
            if tabName == "Warnings" and data.warnings > 0 then
                shouldShow = true
            elseif tabName == "Kicks" and data.kicks > 0 then
                shouldShow = true
            elseif tabName == "Bans" and data.banned then
                shouldShow = true
            end

            if shouldShow then
                local entry = UIComponents.createPlayerEntry(plr, data)
                entry.Position = UDim2.new(0, 0, 0, yOffset)
                entry.Parent = ContentFrame
                yOffset = yOffset + 70  -- Entry height + padding
            end
        end
    end

    ContentFrame.CanvasSize = UDim2.new(0, 0, 0, yOffset)
end

WarningsTab.MouseButton1Click:Connect(function()
    switchTab("Warnings")
end)

KicksTab.MouseButton1Click:Connect(function()
    switchTab("Kicks")
end)

BansTab.MouseButton1Click:Connect(function()
    switchTab("Bans")
end)

-- Open/Close UI handling
OpenUI.OnClientEvent:Connect(function()
    ScreenGui.Enabled = not ScreenGui.Enabled
    if ScreenGui.Enabled then
        switchTab("Warnings")  -- Refresh data when opening
    end
end)

-- Setup real-time updates
local AntiCheatLogs = ReplicatedStorage:WaitForChild("AntiCheatRemotes"):WaitForChild("LogUpdate")
AntiCheatLogs.OnClientEvent:Connect(function()
    if ScreenGui.Enabled then
        -- Refresh the current tab when new data comes in
        local selectedTab = "Warnings" -- Default to warnings tab
        if KicksTab.BackgroundTransparency < 0.5 then
            selectedTab = "Kicks"
        elseif BansTab.BackgroundTransparency < 0.5 then
            selectedTab = "Bans"
        end
        switchTab(selectedTab)
    end
end)

-- Add search functionality
local function searchByBanId(banId)
    if banId and banId ~= "" then
        local playerData = fetchPlayerData()
        ContentFrame:ClearAllChildren()
        local yOffset = 0

        for _, plr in ipairs(Players:GetPlayers()) do
            local data = playerData[plr.UserId]
            if data and data.banId == banId then
                local entry = UIComponents.createPlayerEntry(plr, data)
                entry.Position = UDim2.new(0, 0, 0, yOffset)
                entry.Parent = ContentFrame
                yOffset = yOffset + 70
                break
            end
        end

        if yOffset == 0 then
            local notFound = Instance.new("TextLabel")
            notFound.Size = UDim2.new(1, 0, 0, 40)
            notFound.Position = UDim2.new(0, 0, 0, 0)
            notFound.Text = "No player found with Ban ID: " .. banId
            notFound.Font = Styles.Fonts.Primary
            notFound.TextColor3 = Styles.Colors.TextColor
            notFound.BackgroundTransparency = 1
            notFound.Parent = ContentFrame
        end

        ContentFrame.CanvasSize = UDim2.new(0, 0, 0, yOffset > 0 and yOffset or 40)
    end
end

SearchButton.MouseButton1Click:Connect(function()
    searchByBanId(SearchBar.Text)
end)

SearchBar.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        searchByBanId(SearchBar.Text)
    end
end)

-- Initial tab
switchTab("Warnings")
