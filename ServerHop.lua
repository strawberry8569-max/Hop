local function RunScript()
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
    local CacheFileName = "HopCache_" .. PlaceId .. ".json"

    local function AddRecentServer(id)
        table.insert(RecentServers, 1, id)
        while #RecentServers > 20 do table.remove(RecentServers) end
    end

    AddRecentServer(JobId)

    if getgenv().RecentServers then RecentServers = getgenv().RecentServers end

    local function IsRecent(id)
        for _, v in ipairs(RecentServers) do
            if v == id then return true end
        end
        return false
    end

    local function QueueNextTeleport()
        if queue_on_teleport then
            queue_on_teleport([[
                getgenv().RecentServers = game:GetService("HttpService"):JSONDecode(']].. HttpService:JSONEncode(RecentServers) ..[[')
                loadstring(game:HttpGet("https://raw.githubusercontent.com/strawberry8569-max/Hop/main/ServerHop.lua"))()
            ]])
        end
    end

    LocalPlayer.Idled:Connect(function()
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end)

    -- === СОЗДАНИЕ GUI ===
    local Gui = Instance.new("ScreenGui")
    Gui.Name = "HopGui"
    Gui.ResetOnSpawn = false
    Gui.Parent = game.CoreGui

    -- Основное окно (чуть удлинили для новой кнопки)
    local Main = Instance.new("Frame")
    Main.Parent = Gui
    Main.Size = UDim2.new(0,180,0,325)
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

        local EnterTween = TweenService:Create(Button, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(70,70,70) })
        local LeaveTween = TweenService:Create(Button, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(45,45,45) })

        Button.MouseEnter:Connect(function() EnterTween:Play() end)
        Button.MouseLeave:Connect(function() LeaveTween:Play() end)
        return Button
    end

    local ServerHopButton = CreateButton("🔄 Server Hop", 180)
    local LowPlayerButton = CreateButton("👥 Low Player Hop", 214)
    local RejoinButton = CreateButton("↻ Rejoin", 248)
    local ListButton = CreateButton("📜 Server List", 282)

    -- === ПАНЕЛЬ СО СПИСКОМ СЕРВЕРОВ ===
    local ListFrame = Instance.new("Frame")
    ListFrame.Parent = Main
    ListFrame.Size = UDim2.new(0, 180, 1, 0)
    ListFrame.Position = UDim2.new(0, -190, 0, 0) -- Выезжает слева от основы
    ListFrame.BackgroundColor3 = Color3.fromRGB(28,28,28)
    ListFrame.Visible = false
    ListFrame.ClipsDescendants = true

    local ListCorner = Instance.new("UICorner")
    ListCorner.CornerRadius = UDim.new(0,12)
    ListCorner.Parent = ListFrame

    local ListTitle = Title:Clone()
    ListTitle.Parent = ListFrame
    ListTitle.Text = "Cached Servers"

    local ScrollFrame = Instance.new("ScrollingFrame")
    ScrollFrame.Parent = ListFrame
    ScrollFrame.Size = UDim2.new(1, -10, 1, -35)
    ScrollFrame.Position = UDim2.new(0, 5, 0, 30)
    ScrollFrame.BackgroundTransparency = 1
    ScrollFrame.ScrollBarThickness = 4
    ScrollFrame.BorderSizePixel = 0

    local ListLayout = Instance.new("UIListLayout")
    ListLayout.Parent = ScrollFrame
    ListLayout.Padding = UDim.new(0, 5)
    ListLayout.SortOrder = Enum.SortOrder.LayoutOrder

    -- Драг (перетаскивание окна)
    local Dragging, DragInput, DragStart, StartPos
    Main.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            Dragging, DragStart, StartPos = true, input.Position, Main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then Dragging = false end
            end)
        end
    end)
    Main.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then DragInput = input end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == DragInput and Dragging then
            local Delta = input.Position - DragStart
            Main.Position = UDim2.new(StartPos.X.Scale, StartPos.X.Offset + Delta.X, StartPos.Y.Scale, StartPos.Y.Offset + Delta.Y)
        end
    end)

    -- FPS/Ping каунтер
    local Frames, LastUpdate = 0, tick()
    RunService.RenderStepped:Connect(function()
        if not Main.Visible then return end
        Frames += 1
        if tick() - LastUpdate >= 1 then
            FPS, Frames, LastUpdate = Frames, 0, tick()
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
                    RuntimeLabel.Text = string.format("Runtime: %02d:%02d", math.floor(Runtime/60), Runtime%60)
                    HopsLabel.Text = "Hops: "..HopCount
                    RamLabel.Text = "RAM: "..math.floor(Stats:GetTotalMemoryUsageMb()).." MB"
                    ServerTimeLabel.Text = "Server: "..math.floor(workspace.DistributedGameTime).." s"
                end
            end)
            task.wait(1)
        end
    end)

    -- === ЛОГИКА КЭШИРОВАНИЯ ===
    local function FetchAllServers()
        if not Request then return {} end
        local Servers = {}
        pcall(function()
            local Cursor = ""
            repeat
                local URL = "https://games.roblox.com/v1/games/" .. PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
                if Cursor ~= "" then URL = URL .. "&cursor=" .. Cursor end
                local Response = Request({ Url = URL, Method = "GET" })
                local Data = HttpService:JSONDecode(Response.Body)
                for _, Server in ipairs(Data.data) do table.insert(Servers, Server) end
                Cursor = Data.nextPageCursor or ""
            until Cursor == ""
        end)
        return Servers
    end

    local function GetCachedServers()
        if isfile and readfile and writefile then
            if isfile(CacheFileName) then
                local success, data = pcall(function() return HttpService:JSONDecode(readfile(CacheFileName)) end)
                if success and type(data) == "table" and #data > 0 then return data end
            end
            local newServers = FetchAllServers()
            pcall(function() writefile(CacheFileName, HttpService:JSONEncode(newServers)) end)
            return newServers
        end
        return FetchAllServers()
    end

    local function UpdateCacheFile(serversList)
        if writefile then pcall(function() writefile(CacheFileName, HttpService:JSONEncode(serversList)) end) end
    end

    -- === ЛОГИКА ОТРИСОВКИ СПИСКА ===
    local function PopulateServerList()
        -- Очищаем старые кнопки
        for _, child in ipairs(ScrollFrame:GetChildren()) do
            if child:IsA("TextButton") then child:Destroy() end
        end

        ListTitle.Text = "Loading..."
        local Servers = GetCachedServers()
        ListTitle.Text = "Cached Servers ("..#Servers..")"

        -- Сортируем от меньшего онлайна к большему
        table.sort(Servers, function(a,b) return (a.playing or 0) < (b.playing or 0) end)

        for i, Server in ipairs(Servers) do
            if Server.id ~= JobId and Server.playing < Server.maxPlayers then
                local SBtn = Instance.new("TextButton")
                SBtn.Parent = ScrollFrame
                SBtn.Size = UDim2.new(1, -8, 0, 30)
                SBtn.BackgroundColor3 = Color3.fromRGB(45,45,45)
                SBtn.BorderSizePixel = 0
                SBtn.TextColor3 = Color3.new(1,1,1)
                SBtn.Font = Enum.Font.Gotham
                SBtn.TextSize = 12
                SBtn.Text = "👥 " .. Server.playing .. "/" .. Server.maxPlayers .. " | Join >"

                local SCorner = Instance.new("UICorner")
                SCorner.CornerRadius = UDim.new(0, 6)
                SCorner.Parent = SBtn

                SBtn.MouseButton1Click:Connect(function()
                    SBtn.Text = "Teleporting..."
                    HopCount += 1
                    AddRecentServer(Server.id)
                    getgenv().RecentServers = RecentServers
                    
                    -- Удаляем сервер из кэша, чтобы он не висел в списке вечно
                    table.remove(Servers, i)
                    UpdateCacheFile(Servers)

                    QueueNextTeleport()
                    TeleportService:TeleportToPlaceInstance(PlaceId, Server.id, LocalPlayer)
                end)
            end
        end
        ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, ListLayout.AbsoluteContentSize.Y + 10)
    end

    -- Показать/скрыть список серверов
    ListButton.MouseButton1Click:Connect(function()
        ListFrame.Visible = not ListFrame.Visible
        if ListFrame.Visible then
            task.spawn(PopulateServerList)
        end
    end)

    -- === ОБЫЧНЫЕ КНОПКИ ХОПА (Авто) ===
    local function RandomServerHop()
        ServerHopButton.Text = "⚡ Reading Cache..."
        pcall(function()
            local Servers = GetCachedServers()
            local ValidIndices = {}
            for i, Server in ipairs(Servers) do
                if Server.id ~= JobId and Server.playing < Server.maxPlayers and not IsRecent(Server.id) then
                    table.insert(ValidIndices, i)
                end
            end
            if #ValidIndices > 0 then
                local RandomIdx = ValidIndices[math.random(1, #ValidIndices)]
                local SelectedServer = Servers[RandomIdx]
                table.remove(Servers, RandomIdx)
                UpdateCacheFile(Servers)
                HopCount += 1
                AddRecentServer(SelectedServer.id)
                getgenv().RecentServers = RecentServers
                QueueNextTeleport()
                TeleportService:TeleportToPlaceInstance(PlaceId, SelectedServer.id, LocalPlayer)
            else
                if writefile then pcall(function() writefile(CacheFileName, "[]") end) end
                ServerHopButton.Text = "🔄 Fetching New..."
                task.wait(0.5)
                RandomServerHop()
            end
        end)
    end

    local function LowPlayerHop()
        LowPlayerButton.Text = "⚡ Reading Cache..."
        pcall(function()
            local Servers = GetCachedServers()
            local BestIndex, MinPlayers = -1, math.huge
            for i, Server in ipairs(Servers) do
                if Server.id ~= JobId and Server.playing < Server.maxPlayers and not IsRecent(Server.id) then
                    if Server.playing < MinPlayers then MinPlayers, BestIndex = Server.playing, i end
                end
            end
            if BestIndex ~= -1 then
                local SelectedServer = Servers[BestIndex]
                table.remove(Servers, BestIndex)
                UpdateCacheFile(Servers)
                HopCount += 1
                AddRecentServer(SelectedServer.id)
                getgenv().RecentServers = RecentServers
                QueueNextTeleport()
                TeleportService:TeleportToPlaceInstance(PlaceId, SelectedServer.id, LocalPlayer)
            else
                if writefile then pcall(function() writefile(CacheFileName, "[]") end) end
                LowPlayerButton.Text = "👥 Fetching New..."
                task.wait(0.5)
                LowPlayerHop()
            end
        end)
    end

    local function Rejoin()
        pcall(function()
            QueueNextTeleport()
            TeleportService:TeleportToPlaceInstance(PlaceId, JobId, LocalPlayer)
        end)
    end

    ServerHopButton.MouseButton1Click:Connect(RandomServerHop)
    LowPlayerButton.MouseButton1Click:Connect(LowPlayerHop)
    RejoinButton.MouseButton1Click:Connect(Rejoin)

    -- Свернуть
    local Minimized = false
    Minimize.MouseButton1Click:Connect(function()
        Minimized = not Minimized
        local Elements = { ServerHopButton, LowPlayerButton, RejoinButton, ListButton, FPSLabel, PingLabel, PlayersLabel, RuntimeLabel, HopsLabel, RamLabel, ServerTimeLabel }
        for _, element in ipairs(Elements) do element.Visible = not Minimized end
        if Minimized then ListFrame.Visible = false end -- Скрываем список при сворачивании
        local TargetSize = Minimized and UDim2.new(0,180,0,30) or UDim2.new(0,180,0,325)
        TweenService:Create(Main, TweenInfo.new(0.2), { Size = TargetSize }):Play()
    end)
end

RunScript()
