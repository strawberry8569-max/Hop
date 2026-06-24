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

    -- Универсальный запрос
    local Request = (typeof(request) == "function" and request) or 
                    (typeof(http_request) == "function" and http_request) or 
                    (syn and syn.request) or nil

    local StartTime = tick()
    local HopCount = 0
    local RecentServers = {}
    local CacheFileName = "HopCache_" .. PlaceId .. ".json"

    -- === СПИСОК РЕДКИХ ПЕТОВ ===
    local WantedPets = {
        Unicorn = true,
        Raccoon = true,
        Dragonfly = true,
        Bee = true,
        Bear = true
    }

    -- === АВТОМАТИЧЕСКИЙ АНТИ-ЛАГ (Очистка Gardens) ===
    task.spawn(function()
        local function SetupAntiLag()
            local gardens = workspace:WaitForChild("Gardens", 10)
            if not gardens then return end

            local function CleanPlot(plot)
                -- Удаляем всё, что уже успело загрузиться внутри Plot
                for _, item in ipairs(plot:GetChildren()) do
                    pcall(function() item:Destroy() end)
                end
                
                -- Уничтожаем всё новое, что игра попытается туда загрузить
                plot.ChildAdded:Connect(function(item)
                    pcall(function() item:Destroy() end)
                end)
            end

            -- Обрабатываем текущие плоты
            for _, plot in ipairs(gardens:GetChildren()) do
                CleanPlot(plot)
            end

            -- Если игра динамически создает новые папки Plot
            gardens.ChildAdded:Connect(function(plot)
                task.wait()
                CleanPlot(plot)
            end)
        end

        pcall(SetupAntiLag)
    end)

    -- === ЛОГИКА СЕРВЕРОВ ===
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
            local data = HttpService:JSONEncode(RecentServers)
            queue_on_teleport([[
                getgenv().RecentServers = game:GetService("HttpService"):JSONDecode(']].. data ..[[')
            ]])
        end
    end

    -- Анти-АФК
    LocalPlayer.Idled:Connect(function()
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end)

    -- === СОЗДАНИЕ GUI ===
    local Gui = Instance.new("ScreenGui")
    Gui.Name = "ServerToolsGui"
    Gui.ResetOnSpawn = false
    if game.CoreGui:FindFirstChild(Gui.Name) then game.CoreGui[Gui.Name]:Destroy() end
    Gui.Parent = game.CoreGui

    local Main = Instance.new("Frame")
    Main.Parent = Gui
    Main.Size = UDim2.new(0, 200, 0, 480)
    Main.Position = UDim2.new(1, -220, 0, 40)
    Main.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    Main.BorderSizePixel = 0
    Main.ClipsDescendants = true
    Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)

    -- ШАПКА
    local TopBar = Instance.new("Frame")
    TopBar.Parent = Main
    TopBar.Size = UDim2.new(1, 0, 0, 30)
    TopBar.BackgroundTransparency = 1

    local Title = Instance.new("TextLabel")
    Title.Parent = TopBar
    Title.Size = UDim2.new(1, -30, 1, 0)
    Title.Position = UDim2.new(0, 10, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "Server Tools"
    Title.TextColor3 = Color3.new(1, 1, 1)
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 14
    Title.TextXAlignment = Enum.TextXAlignment.Left

    local Minimize = Instance.new("TextButton")
    Minimize.Parent = TopBar
    Minimize.Size = UDim2.new(0, 20, 0, 20)
    Minimize.Position = UDim2.new(1, -25, 0, 5)
    Minimize.Text = "-"
    Minimize.Font = Enum.Font.GothamBold
    Minimize.TextSize = 15
    Minimize.TextColor3 = Color3.new(1, 1, 1)
    Minimize.BackgroundColor3 = Color3.fromRGB(55, 55, 60)
    Instance.new("UICorner", Minimize).CornerRadius = UDim.new(0, 6)

    -- КОНТЕЙНЕР ДЛЯ СКРЫТИЯ
    local Content = Instance.new("Frame")
    Content.Parent = Main
    Content.Size = UDim2.new(1, 0, 1, -30)
    Content.Position = UDim2.new(0, 0, 0, 30)
    Content.BackgroundTransparency = 1

    -- СТАТИСТИКА
    local FPSLabel = Instance.new("TextLabel")
    FPSLabel.Parent = Content
    FPSLabel.Position = UDim2.new(0, 10, 0, 0)
    FPSLabel.Size = UDim2.new(1, -20, 0, 18)
    FPSLabel.BackgroundTransparency = 1
    FPSLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    FPSLabel.Font = Enum.Font.Gotham
    FPSLabel.TextSize = 12
    FPSLabel.TextXAlignment = Enum.TextXAlignment.Left

    local PingLabel = FPSLabel:Clone() PingLabel.Parent = Content PingLabel.Position = UDim2.new(0,10,0,20)
    local PlayersLabel = FPSLabel:Clone() PlayersLabel.Parent = Content PlayersLabel.Position = UDim2.new(0,10,0,40)
    local RuntimeLabel = FPSLabel:Clone() RuntimeLabel.Parent = Content RuntimeLabel.Position = UDim2.new(0,10,0,60)
    local HopsLabel = FPSLabel:Clone() HopsLabel.Parent = Content HopsLabel.Position = UDim2.new(0,10,0,80)
    local RamLabel = FPSLabel:Clone() RamLabel.Parent = Content RamLabel.Position = UDim2.new(0,10,0,100)
    local ServerTimeLabel = FPSLabel:Clone() ServerTimeLabel.Parent = Content ServerTimeLabel.Position = UDim2.new(0,10,0,120)

    -- КНОПКИ
    local function CreateButton(text, yPos)
        local Button = Instance.new("TextButton")
        Button.Parent = Content
        Button.Size = UDim2.new(1, -20, 0, 28)
        Button.Position = UDim2.new(0, 10, 0, yPos)
        Button.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
        Button.BorderSizePixel = 0
        Button.TextColor3 = Color3.new(1, 1, 1)
        Button.Font = Enum.Font.GothamBold
        Button.TextSize = 12
        Button.Text = text
        Instance.new("UICorner", Button).CornerRadius = UDim.new(0, 8)

        Button.MouseEnter:Connect(function() TweenService:Create(Button, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(70, 70, 75)}):Play() end)
        Button.MouseLeave:Connect(function() TweenService:Create(Button, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(50, 50, 55)}):Play() end)
        return Button
    end

    local ServerHopButton = CreateButton("🔄 Server Hop", 145)
    local LowPlayerButton = CreateButton("👥 Low Player Hop", 178)
    local RejoinButton = CreateButton("↻ Rejoin", 211)
    local ListButton = CreateButton("📜 Server List", 244)

    -- РАЗДЕЛ ПЕТОВ
    local PetsHeader = Instance.new("TextLabel")
    PetsHeader.Parent = Content
    PetsHeader.Position = UDim2.new(0, 10, 0, 280)
    PetsHeader.Size = UDim2.new(1, -20, 0, 20)
    PetsHeader.BackgroundTransparency = 1
    PetsHeader.Text = "🐾 Rare Pets:"
    PetsHeader.TextColor3 = Color3.fromRGB(150, 220, 150)
    PetsHeader.Font = Enum.Font.GothamBold
    PetsHeader.TextSize = 13
    PetsHeader.TextXAlignment = Enum.TextXAlignment.Left

    local PetScrollFrame = Instance.new("ScrollingFrame")
    PetScrollFrame.Parent = Content
    PetScrollFrame.Position = UDim2.new(0, 10, 0, 305)
    PetScrollFrame.Size = UDim2.new(1, -20, 1, -315)
    PetScrollFrame.BackgroundTransparency = 1
    PetScrollFrame.ScrollBarThickness = 3
    PetScrollFrame.BorderSizePixel = 0
    local PetListLayout = Instance.new("UIListLayout")
    PetListLayout.Parent = PetScrollFrame
    PetListLayout.Padding = UDim.new(0, 4)
    PetListLayout.SortOrder = Enum.SortOrder.LayoutOrder

    -- БОКОВАЯ ПАНЕЛЬ СЕРВЕРОВ
    local ListFrame = Instance.new("Frame")
    ListFrame.Parent = Main
    ListFrame.Size = UDim2.new(0, 190, 1, 0)
    ListFrame.Position = UDim2.new(0, -200, 0, 0)
    ListFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    ListFrame.Visible = false
    Instance.new("UICorner", ListFrame).CornerRadius = UDim.new(0, 10)

    local ListTitle = Instance.new("TextLabel")
    ListTitle.Parent = ListFrame
    ListTitle.Size = UDim2.new(1, 0, 0, 30)
    ListTitle.BackgroundTransparency = 1
    ListTitle.Text = "Cached Servers"
    ListTitle.TextColor3 = Color3.new(1, 1, 1)
    ListTitle.Font = Enum.Font.GothamBold
    ListTitle.TextSize = 13

    local ServerScroll = Instance.new("ScrollingFrame")
    ServerScroll.Parent = ListFrame
    ServerScroll.Size = UDim2.new(1, -10, 1, -40)
    ServerScroll.Position = UDim2.new(0, 5, 0, 35)
    ServerScroll.BackgroundTransparency = 1
    ServerScroll.ScrollBarThickness = 3
    ServerScroll.BorderSizePixel = 0
    local ServerListLayout = Instance.new("UIListLayout")
    ServerListLayout.Parent = ServerScroll
    ServerListLayout.Padding = UDim.new(0, 4)

    -- DRAG (Перетаскивание)
    local Dragging, DragInput, DragStart, StartPos
    TopBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            Dragging, DragStart, StartPos = true, input.Position, Main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then Dragging = false end
            end)
        end
    end)
    TopBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then DragInput = input end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == DragInput and Dragging then
            local Delta = input.Position - DragStart
            Main.Position = UDim2.new(StartPos.X.Scale, StartPos.X.Offset + Delta.X, StartPos.Y.Scale, StartPos.Y.Offset + Delta.Y)
        end
    end)

    -- ОБНОВЛЕНИЕ СТАТИСТИКИ
    local Frames, LastUpdate = 0, tick()
    RunService.RenderStepped:Connect(function()
        Frames += 1
        if tick() - LastUpdate >= 1 then
            if Main.Visible then FPSLabel.Text = "FPS: " .. Frames end
            Frames, LastUpdate = 0, tick()
        end
    end)

    task.spawn(function()
        while true do
            pcall(function()
                if Main.Visible and Content.Visible then
                    local Ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
                    PingLabel.Text = "Ping: " .. Ping .. " ms"
                    PlayersLabel.Text = "Players: " .. #Players:GetPlayers()
                    local Runtime = math.floor(tick() - StartTime)
                    RuntimeLabel.Text = string.format("Runtime: %02d:%02d", math.floor(Runtime/60), Runtime%60)
                    HopsLabel.Text = "Hops: " .. HopCount
                    RamLabel.Text = "RAM: " .. math.floor(Stats:GetTotalMemoryUsageMb()) .. " MB"
                    ServerTimeLabel.Text = "Server: " .. math.floor(workspace.DistributedGameTime) .. " s"
                end
            end)
            task.wait(1)
        end
    end)

    -- РАДАР ПЕТОВ
    local function PopulatePetList()
        for _, child in ipairs(PetScrollFrame:GetChildren()) do
            if child:IsA("Frame") then child:Destroy() end
        end

        local MapFolder = workspace:FindFirstChild("Map")
        local WildPetSpawns = MapFolder and MapFolder:FindFirstChild("WildPetSpawns")
        local FoundAny = false

        if WildPetSpawns then
            for _, petModel in ipairs(WildPetSpawns:GetChildren()) do
                local petNameLower = petModel.Name:lower()
                local matchedName = nil
                
                for wantedName in pairs(WantedPets) do
                    if petNameLower:find(wantedName:lower()) then
                        matchedName = wantedName
                        break
                    end
                end

                if matchedName then
                    FoundAny = true
                    
                    local ItemFrame = Instance.new("Frame")
                    ItemFrame.Parent = PetScrollFrame
                    ItemFrame.Size = UDim2.new(1, -4, 0, 26)
                    ItemFrame.BackgroundTransparency = 1

                    local NameLabel = Instance.new("TextLabel")
                    NameLabel.Parent = ItemFrame
                    NameLabel.Size = UDim2.new(1, -45, 1, 0)
                    NameLabel.BackgroundTransparency = 1
                    NameLabel.Text = matchedName
                    NameLabel.TextColor3 = Color3.new(1, 1, 1)
                    NameLabel.Font = Enum.Font.Gotham
                    NameLabel.TextSize = 12
                    NameLabel.TextXAlignment = Enum.TextXAlignment.Left

                    local TPBtn = Instance.new("TextButton")
                    TPBtn.Parent = ItemFrame
                    TPBtn.Size = UDim2.new(0, 40, 0, 22)
                    TPBtn.Position = UDim2.new(1, -40, 0, 2)
                    TPBtn.BackgroundColor3 = Color3.fromRGB(60, 100, 60)
                    TPBtn.BorderSizePixel = 0
                    TPBtn.TextColor3 = Color3.new(1, 1, 1)
                    TPBtn.Font = Enum.Font.GothamBold
                    TPBtn.TextSize = 11
                    TPBtn.Text = "TP"
                    Instance.new("UICorner", TPBtn).CornerRadius = UDim.new(0, 6)

                    TPBtn.MouseButton1Click:Connect(function()
                        local Character = LocalPlayer.Character
                        local Root = Character and Character:FindFirstChild("HumanoidRootPart")
                        local PetPart = petModel:FindFirstChildWhichIsA("BasePart", true) or petModel.PrimaryPart

                        if Root and PetPart then
                            Root.CFrame = PetPart.CFrame + Vector3.new(0, 3, 0)
                            TPBtn.Text = "✨"
                            task.wait(0.5)
                            TPBtn.Text = "TP"
                        end
                    end)
                end
            end
        end

        if not FoundAny then
            local EmptyLabel = Instance.new("TextLabel")
            EmptyLabel.Parent = PetScrollFrame
            EmptyLabel.Size = UDim2.new(1, 0, 0, 20)
            EmptyLabel.BackgroundTransparency = 1
            EmptyLabel.Text = "No rare pets found..."
            EmptyLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
            EmptyLabel.Font = Enum.Font.Gotham
            EmptyLabel.TextSize = 11
            EmptyLabel.TextXAlignment = Enum.TextXAlignment.Left
        end

        PetScrollFrame.CanvasSize = UDim2.new(0, 0, 0, PetListLayout.AbsoluteContentSize.Y + 5)
    end

    task.spawn(function()
        local MapFolder = workspace:WaitForChild("Map", 10)
        local WildPetSpawns = MapFolder and MapFolder:WaitForChild("WildPetSpawns", 10)
        if WildPetSpawns then
            WildPetSpawns.ChildAdded:Connect(function() task.wait(0.3) PopulatePetList() end)
            WildPetSpawns.ChildRemoved:Connect(function() task.wait(0.3) PopulatePetList() end)
        end
    end)
    PopulatePetList()

    -- СИСТЕМА КЭШИРОВАНИЯ СЕРВЕРОВ
    local function FetchAllServers()
        local Servers = {}
        if Request then
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
        else
            pcall(function()
                local res = game:HttpGet("https://games.roblox.com/v1/games/" .. PlaceId .. "/servers/Public?sortOrder=Asc&limit=100")
                local Data = HttpService:JSONDecode(res)
                for _, Server in ipairs(Data.data) do table.insert(Servers, Server) end
            end)
        end
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

    local function PopulateServerList()
        for _, child in ipairs(ServerScroll:GetChildren()) do
            if child:IsA("TextButton") then child:Destroy() end
        end

        ListTitle.Text = "Loading..."
        local Servers = GetCachedServers()
        ListTitle.Text = "Servers ("..#Servers..")"

        table.sort(Servers, function(a,b) return (a.playing or 0) < (b.playing or 0) end)

        for i, Server in ipairs(Servers) do
            if Server.id ~= JobId and Server.playing < Server.maxPlayers then
                local SBtn = Instance.new("TextButton")
                SBtn.Parent = ServerScroll
                SBtn.Size = UDim2.new(1, -8, 0, 26)
                SBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
                SBtn.BorderSizePixel = 0
                SBtn.TextColor3 = Color3.new(1,1,1)
                SBtn.Font = Enum.Font.Gotham
                SBtn.TextSize = 11
                SBtn.Text = "👥 " .. Server.playing .. "/" .. Server.maxPlayers .. " | Join >"
                Instance.new("UICorner", SBtn).CornerRadius = UDim.new(0, 6)

                SBtn.MouseButton1Click:Connect(function()
                    SBtn.Text = "Teleporting..."
                    HopCount += 1
                    AddRecentServer(Server.id)
                    table.remove(Servers, i)
                    UpdateCacheFile(Servers)
                    QueueNextTeleport()
                    TeleportService:TeleportToPlaceInstance(PlaceId, Server.id, LocalPlayer)
                end)
            end
        end
        ServerScroll.CanvasSize = UDim2.new(0, 0, 0, ServerListLayout.AbsoluteContentSize.Y + 10)
    end

    ListButton.MouseButton1Click:Connect(function()
        ListFrame.Visible = not ListFrame.Visible
        if ListFrame.Visible then task.spawn(PopulateServerList) end
    end)

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

    -- СВОРАЧИВАНИЕ GUI
    local Minimized = false
    Minimize.MouseButton1Click:Connect(function()
        Minimized = not Minimized
        Content.Visible = not Minimized
        if Minimized then ListFrame.Visible = false end
        local TargetSize = Minimized and UDim2.new(0, 200, 0, 30) or UDim2.new(0, 200, 0, 480)
        TweenService:Create(Main, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = TargetSize }):Play()
    end)
    
    print("Server Tools & Anti-Lag Loaded Successfully!")
end

RunScript()
