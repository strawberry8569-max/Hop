local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local Stats = game:GetService("Stats")

local LocalPlayer = Players.LocalPlayer
local PlaceId = game.PlaceId
local JobId = game.JobId

local Request = request or http_request or (syn and syn.request)

if not Request then
    warn("HTTP request function not found")
end

local StartTime = tick()
local HopCount = 0
local RecentServers = {}

local function AddRecentServer(id)
    table.insert(RecentServers, 1, id)
    while #RecentServers > 20 do
        table.remove(RecentServers)
    end
end

AddRecentServer(JobId)

if getgenv().RecentServers then
    RecentServers = getgenv().RecentServers
end

local function IsRecent(id)
    for _, v in ipairs(RecentServers) do
        if v == id then
            return true
        end
    end
    return false
end

LocalPlayer.Idled:Connect(function()
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end)

local Gui = Instance.new("ScreenGui")
Gui.Name = "HopGui"
Gui.ResetOnSpawn = false
Gui.Parent = game.CoreGui

local Main = Instance.new("Frame")
Main.Parent = Gui
Main.Size = UDim2.new(0,180,0,290)
Main.Position = UDim2.new(1,-210,0,40)
Main.BackgroundColor3 = Color3.fromRGB(28,28,28)
Main.BorderSizePixel = 0

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0,12)
MainCorner.Parent = Main

local Title = Instance.new("TextLabel")
Title.Parent = Main
Title.Size = UDim2.new(1,0,0,25)
Title.BackgroundTransparency = 1
Title.Text = "Server Tools"
Title.TextColor3 = Color3.new(1,1,1)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 15

local Minimize = Instance.new("TextButton")
Minimize.Parent = Main
Minimize.Size = UDim2.new(0,20,0,20)
Minimize.Position = UDim2.new(1,-25,0,3)
Minimize.Text = "-"
Minimize.Font = Enum.Font.GothamBold
Minimize.TextSize = 15
Minimize.TextColor3 = Color3.new(1,1,1)
Minimize.BackgroundColor3 = Color3.fromRGB(50,50,50)

local MinCorner = Instance.new("UICorner")
MinCorner.Parent = Minimize

local FPSLabel = Instance.new("TextLabel")
FPSLabel.Parent = Main
FPSLabel.Position = UDim2.new(0,10,0,30)
FPSLabel.Size = UDim2.new(1,-20,0,18)
FPSLabel.BackgroundTransparency = 1
FPSLabel.TextColor3 = Color3.new(1,1,1)
FPSLabel.Font = Enum.Font.Gotham
FPSLabel.TextSize = 13
FPSLabel.TextXAlignment = Enum.TextXAlignment.Left

local PingLabel = FPSLabel:Clone()
PingLabel.Parent = Main
PingLabel.Position = UDim2.new(0,10,0,50)

local PlayersLabel = FPSLabel:Clone()
PlayersLabel.Parent = Main
PlayersLabel.Position = UDim2.new(0,10,0,70)

local RuntimeLabel = FPSLabel:Clone()
RuntimeLabel.Parent = Main
RuntimeLabel.Position = UDim2.new(0,10,0,90)

local HopsLabel = FPSLabel:Clone()
HopsLabel.Parent = Main
HopsLabel.Position = UDim2.new(0,10,0,110)

local RamLabel = FPSLabel:Clone()
RamLabel.Parent = Main
RamLabel.Position = UDim2.new(0,10,0,130)

local ServerTimeLabel = FPSLabel:Clone()
ServerTimeLabel.Parent = Main
ServerTimeLabel.Position = UDim2.new(0,10,0,150)

local function CreateButton(text,y)
    local Button = Instance.new("TextButton")
    Button.Parent = Main
    Button.Size = UDim2.new(1,-20,0,28)
    Button.Position = UDim2.new(0,10,0,y)
    Button.BackgroundColor3 = Color3.fromRGB(45,45,45)
    Button.BorderSizePixel = 0
    Button.TextColor3 = Color3.new(1,1,1)
    Button.Font = Enum.Font.GothamBold
    Button.TextSize = 13
    Button.Text = text

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0,10)
    Corner.Parent = Button

    local EnterTween = TweenService:Create(
        Button,
        TweenInfo.new(0.15),
        { BackgroundColor3 = Color3.fromRGB(70,70,70) }
    )

    local LeaveTween = TweenService:Create(
        Button,
        TweenInfo.new(0.15),
        { BackgroundColor3 = Color3.fromRGB(45,45,45) }
    )

    Button.MouseEnter:Connect(function() EnterTween:Play() end)
    Button.MouseLeave:Connect(function() LeaveTween:Play() end)

    return Button
end

local ServerHopButton = CreateButton("🔄 Server Hop",180)
local LowPlayerButton = CreateButton("👥 Low Player Hop",214)
local RejoinButton = CreateButton("↻ Rejoin",248)

local Dragging = false
local DragInput
local DragStart
local StartPos

Main.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        Dragging = true
        DragStart = input.Position
        StartPos = Main.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                Dragging = false
            end
        end)
    end
end)

Main.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        DragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == DragInput and Dragging then
        local Delta = input.Position - DragStart
        Main.Position = UDim2.new(
            StartPos.X.Scale,
            StartPos.X.Offset + Delta.X,
            StartPos.Y.Scale,
            StartPos.Y.Offset + Delta.Y
        )
    end
end)

local FPS = 0
local Frames = 0
local LastUpdate = tick()

RunService.RenderStepped:Connect(function()
    if not Main.Visible then return end
    Frames += 1
    if tick() - LastUpdate >= 1 then
        FPS = Frames
        Frames = 0
        LastUpdate = tick()
    end
end)

task.spawn(function()
    while true do
        pcall(function()
            if Main.Visible then
                local Ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())

                FPSLabel.Text = "FPS: "..FPS
                PingLabel.Text = "Ping: "..Ping.." ms"
                PlayersLabel.Text = "Players: "..#Players:GetPlayers()

                local Runtime = math.floor(tick() - StartTime)
                local Minutes = math.floor(Runtime / 60)
                local Seconds = Runtime % 60

                RuntimeLabel.Text = string.format("Runtime: %02d:%02d", Minutes, Seconds)
                HopsLabel.Text = "Hops: "..HopCount
                RamLabel.Text = "RAM: "..math.floor(Stats:GetTotalMemoryUsageMb()).." MB"
                ServerTimeLabel.Text = "Server: "..math.floor(workspace.DistributedGameTime).." s"
            end
        end)
        task.wait(1)
    end
end)

local function GetServers()
    if not Request then return {} end
    local Servers = {}
    pcall(function()
        local Cursor = ""
        repeat
            local URL = "https://games.roblox.com/v1/games/" .. PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
            if Cursor ~= "" then
                URL = URL .. "&cursor=" .. Cursor
            end

            local Response = Request({ Url = URL, Method = "GET" })
            local Data = HttpService:JSONDecode(Response.Body)

            for _, Server in ipairs(Data.data) do
                table.insert(Servers, Server)
            end
            Cursor = Data.nextPageCursor or ""
        until Cursor == ""
    end)
    return Servers
end

local function RandomServerHop()
    pcall(function()
        local Servers = GetServers()
        local ValidServers = {}

        for _, Server in ipairs(Servers) do
            if Server.id ~= JobId and Server.playing < Server.maxPlayers and not IsRecent(Server.id) then
                table.insert(ValidServers, Server)
            end
        end

        if #ValidServers > 0 then
            local Selected = ValidServers[math.random(1,#ValidServers)]
            HopCount += 1
            AddRecentServer(Selected.id)
            getgenv().RecentServers = RecentServers

            if queue_on_teleport then
                queue_on_teleport([[getgenv().RecentServers = ]].. HttpService:JSONEncode(RecentServers))
            end

            TeleportService:TeleportToPlaceInstance(PlaceId, Selected.id, LocalPlayer)
        else
            warn("No valid server found")
        end
    end)
end

local function LowPlayerHop()
    pcall(function()
        local Servers = GetServers()
        table.sort(Servers, function(a,b) return a.playing < b.playing end)

        for _, Server in ipairs(Servers) do
            if Server.id ~= JobId and Server.playing < Server.maxPlayers and not IsRecent(Server.id) then
                HopCount += 1
                AddRecentServer(Server.id)
                getgenv().RecentServers = RecentServers

                if queue_on_teleport then
                    queue_on_teleport([[getgenv().RecentServers = ]].. HttpService:JSONEncode(RecentServers))
                end

                TeleportService:TeleportToPlaceInstance(PlaceId, Server.id, LocalPlayer)
                break
            end
        end
    end)
end

local function Rejoin()
    pcall(function()
        TeleportService:TeleportToPlaceInstance(PlaceId, JobId, LocalPlayer)
    end)
end

ServerHopButton.MouseButton1Click:Connect(RandomServerHop)
LowPlayerButton.MouseButton1Click:Connect(LowPlayerHop)
RejoinButton.MouseButton1Click:Connect(Rejoin)

local Hidden = false
local SavedPosition = Main.Position

local function ToggleGui()
    pcall(function()
        if Hidden then
            Main.Visible = true
            local ShowTween = TweenService:Create(Main, TweenInfo.new(0.2, Enum.EasingStyle.Quad), { Position = SavedPosition })
            ShowTween:Play()
            Hidden = false
        else
            SavedPosition = Main.Position
            local HideTween = TweenService:Create(Main, TweenInfo.new(0.2, Enum.EasingStyle.Quad), { Position = UDim2.new(SavedPosition.X.Scale, SavedPosition.X.Offset + 220, SavedPosition.Y.Scale, SavedPosition.Y.Offset) })
            HideTween:Play()
            Hidden = true
            task.delay(0.2, function()
                if Hidden then Main.Visible = false end
            end)
        end
    end)
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    pcall(function()
        if input.KeyCode == Enum.KeyCode.H then ToggleGui()
        elseif input.KeyCode == Enum.KeyCode.J then RandomServerHop()
        elseif input.KeyCode == Enum.KeyCode.K then LowPlayerHop()
        elseif input.KeyCode == Enum.KeyCode.L then Rejoin()
        end
    end)
end)

local function UpdatePlayers()
    pcall(function()
        if Main.Visible then
            PlayersLabel.Text = "Players: "..#Players:GetPlayers()
        end
    end)
end
Players.PlayerAdded:Connect(UpdatePlayers)
Players.PlayerRemoving:Connect(UpdatePlayers)

math.randomseed(os.time())

TeleportService.TeleportInitFailed:Connect(function()
    task.wait(2)
    pcall(RandomServerHop)
end)

print("Server Tools Loaded")

local Minimized = false

Minimize.MouseButton1Click:Connect(function()
    Minimized = not Minimized
    
    local Elements = { ServerHopButton, LowPlayerButton, RejoinButton, FPSLabel, PingLabel, PlayersLabel, RuntimeLabel, HopsLabel, RamLabel, ServerTimeLabel }
    for _, element in ipairs(Elements) do
        element.Visible = not Minimized
    end

    local TargetSize = Minimized and UDim2.new(0,180,0,30) or UDim2.new(0,180,0,290)
    TweenService:Create(Main, TweenInfo.new(0.2), { Size = TargetSize }):Play()
end)
