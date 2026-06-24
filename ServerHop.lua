local function RunScript()
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local Stats = game:GetService("Stats")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local PlaceId = game.PlaceId
local JobId = game.JobId

-- Универсальный HTTP запрос
local Request = (typeof(request) == "function" and request) or 
                (typeof(http_request) == "function" and http_request) or 
                (syn and syn.request) or nil

local RecentServers = getgenv().RecentServers or {}
local CacheFileName = "HopCache_" .. PlaceId .. ".json"
local SettingsFolder = "PetFinderSettings"
local SettingsFile = SettingsFolder .. "/Config.json"

local Settings = { AutoHop = false }
local FoundRarePet = false 
local RandomServerHop 

-- === СОХРАНЕНИЕ И ЗАГРУЗКА НАСТРОЕК ===
local function SaveSettings()
    if writefile then
        pcall(function()
            if isfolder and not isfolder(SettingsFolder) then makefolder(SettingsFolder) end
            writefile(SettingsFile, HttpService:JSONEncode(Settings))
        end)
    end
end

local function LoadSettings()
    if isfile and isfile(SettingsFile) then
        local success, result = pcall(function() return HttpService:JSONDecode(readfile(SettingsFile)) end)
        if success and type(result) == "table" then
            if result.AutoHop ~= nil then Settings.AutoHop = result.AutoHop end
        end
    end
end
LoadSettings()

-- === СПИСОК РЕДКИХ ПЕТОВ ===
local WantedPets = {
    Unicorn = true,
    Raccoon = true,
    Dragonfly = true,
    Bee = true,
    Bear = true,
    -- Owl = true
}

local Tracers = {} 

-- === АВТОМАТИЧЕСКИЙ АНТИ-ЛАГ (Очистка Gardens) ===
task.spawn(function()
    local function SetupAntiLag()
        local gardens = workspace:WaitForChild("Gardens", 10)
        if not gardens then return end
        local function CleanPlot(plot)
            for _, item in ipairs(plot:GetChildren()) do pcall(function() item:Destroy() end) end
            plot.ChildAdded:Connect(function(item) pcall(function() item:Destroy() end) end)
        end
        for _, plot in ipairs(gardens:GetChildren()) do CleanPlot(plot) end
        gardens.ChildAdded:Connect(function(plot) task.wait() CleanPlot(plot) end)
    end
    pcall(SetupAntiLag)
end)

-- === ЛОГИКА СЕРВЕРОВ ===
local function AddRecentServer(id)
    table.insert(RecentServers, 1, id)
    while #RecentServers > 20 do table.remove(RecentServers) end
end
AddRecentServer(JobId)

local function IsRecent(id)
    for _, v in ipairs(RecentServers) do if v == id then return true end end
    return false
end

local function QueueNextTeleport()
    if queue_on_teleport then
        local data = HttpService:JSONEncode(RecentServers)
        queue_on_teleport([[ getgenv().RecentServers = game:GetService("HttpService"):JSONDecode(']].. data ..[[') ]])
    end
end

-- Anti-AFK
LocalPlayer.Idled:Connect(function()
    pcall(function() VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new()) end)
end)

-- === СОЗДАНИЕ GUI ===
local Gui = Instance.new("ScreenGui")
Gui.Name = "ServerToolsGui"
Gui.ResetOnSpawn = false
if CoreGui:FindFirstChild(Gui.Name) then CoreGui[Gui.Name]:Destroy() end
Gui.Parent = CoreGui

local Main = Instance.new("Frame")
Main.Parent = Gui
Main.Size = UDim2.new(0, 200, 0, 430)
Main.Position = UDim2.new(1, -220, 0, 40)
Main.BackgroundColor3 = Color3.fromRGB(30, 30, 35, 255)
Main.BorderSizePixel = 0
Main.ClipsDescendants = true
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)

local TopBar = Instance.new("Frame")
TopBar.Parent = Main
TopBar.Size = UDim2.new(1, 0, 0, 30)
TopBar.BackgroundTransparency = 1

local Title = Instance.new("TextLabel")
Title.Parent = TopBar
Title.Size = UDim2.new(1, -30, 1, 0)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "Pet Finder"
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

-- Контейнер с автоматической сортировкой
local Content = Instance.new("Frame")
Content.Parent = Main
Content.Size = UDim2.new(1, 0, 1, -30)
Content.Position = UDim2.new(0, 0, 0, 30)
Content.BackgroundTransparency = 1

local ContentLayout = Instance.new("UIListLayout")
ContentLayout.Parent = Content
ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
ContentLayout.Padding = UDim.new(0, 5)
ContentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

-- === БЛОК СТАТИСТИКИ (FPS, PING, PLAYERS) ===
local StatsFrame = Instance.new("Frame")
StatsFrame.Parent = Content
StatsFrame.Size = UDim2.new(1, -20, 0, 55)
StatsFrame.BackgroundTransparency = 1
StatsFrame.LayoutOrder = 1

local FPSLabel = Instance.new("TextLabel", StatsFrame)
FPSLabel.Size = UDim2.new(1, 0, 0, 15)
FPSLabel.Position = UDim2.new(0, 0, 0, 0)
FPSLabel.BackgroundTransparency = 1
FPSLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
FPSLabel.Font = Enum.Font.Gotham
FPSLabel.TextSize = 12
FPSLabel.TextXAlignment = Enum.TextXAlignment.Left

local PingLabel = FPSLabel:Clone()
PingLabel.Parent = StatsFrame
PingLabel.Position = UDim2.new(0, 0, 0, 18)

local PlayersLabel = FPSLabel:Clone()
PlayersLabel.Parent = StatsFrame
PlayersLabel.Position = UDim2.new(0, 0, 0, 36)

-- === ЗАГОЛОВОК ПЕТОВ ===
local PetsHeader = Instance.new("TextLabel")
PetsHeader.Parent = Content
PetsHeader.Size = UDim2.new(1, -20, 0, 20)
PetsHeader.BackgroundTransparency = 1
PetsHeader.Text = "🐾 Rare Pets:"
PetsHeader.TextColor3 = Color3.fromRGB(150, 220, 150)
PetsHeader.Font = Enum.Font.GothamBold
PetsHeader.TextSize = 13
PetsHeader.TextXAlignment = Enum.TextXAlignment.Left
PetsHeader.LayoutOrder = 2

-- === СПИСОК ПЕТОВ ===
local PetScrollFrame = Instance.new("ScrollingFrame")
PetScrollFrame.Parent = Content
PetScrollFrame.Size = UDim2.new(1, -20, 0, 100)
PetScrollFrame.BackgroundTransparency = 1
PetScrollFrame.ScrollBarThickness = 3
PetScrollFrame.BorderSizePixel = 0
PetScrollFrame.LayoutOrder = 3

local PetListLayout = Instance.new("UIListLayout")
PetListLayout.Parent = PetScrollFrame
PetListLayout.Padding = UDim.new(0, 4)

-- === КНОПКИ ===
local function CreateButton(text, order)
    local Button = Instance.new("TextButton")
    Button.Parent = Content
    Button.Size = UDim2.new(1, -20, 0, 28)
    Button.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
    Button.BorderSizePixel = 0
    Button.TextColor3 = Color3.new(1, 1, 1)
    Button.Font = Enum.Font.GothamBold
    Button.TextSize = 12
    Button.Text = text
    Button.LayoutOrder = order
    Instance.new("UICorner", Button).CornerRadius = UDim.new(0, 8)
    Button.MouseEnter:Connect(function() TweenService:Create(Button, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(70, 70, 75)}):Play() end)
    Button.MouseLeave:Connect(function() 
        if Button.Name ~= "ActiveAutoHop" then
            TweenService:Create(Button, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(50, 50, 55)}):Play() 
        end
    end)
    return Button
end

local AutoHopBtn = CreateButton("🚀 Auto Hop: OFF", 4)
local ServerHopButton = CreateButton("🔄 Server Hop", 5)
local LowPlayerButton = CreateButton("👥 Low Player Hop", 6)
local RejoinButton = CreateButton("↻ Rejoin", 7)
local ListButton = CreateButton("📜 Server List", 8)

local function UpdateAutoHopVisual()
    AutoHopBtn.Text = Settings.AutoHop and "🚀 Auto Hop: ON" or "🚀 Auto Hop: OFF"
    AutoHopBtn.BackgroundColor3 = Settings.AutoHop and Color3.fromRGB(60, 140, 60) or Color3.fromRGB(50, 50, 55)
    AutoHopBtn.Name = Settings.AutoHop and "ActiveAutoHop" or "AutoHop"
end
UpdateAutoHopVisual()

AutoHopBtn.MouseButton1Click:Connect(function()
    Settings.AutoHop = not Settings.AutoHop
    UpdateAutoHopVisual()
    SaveSettings()
end)

-- === ЛИСТ КЕШИРОВАННЫХ СЕРВЕРОВ ===
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

-- Перемещение окна
local Dragging, DragInput, DragStart, StartPos
TopBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        Dragging, DragStart, StartPos = true, input.Position, Main.Position
        input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then Dragging = false end end)
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

-- === ОБНОВЛЕНИЕ ESP ЛИНИЙ И FPS/PING ===
local Frames, LastUpdate = 0, tick()
RunService.RenderStepped:Connect(function()
    Frames += 1
    if tick() - LastUpdate >= 1 then
        if Main.Visible then FPSLabel.Text = "FPS: " .. Frames end
        Frames, LastUpdate = 0, tick()
    end

    if Drawing then
        for pet, line in pairs(Tracers) do
            if pet and pet.Parent and (pet:FindFirstChildWhichIsA("BasePart", true) or pet.PrimaryPart) then
                local part = pet:FindFirstChildWhichIsA("BasePart", true) or pet.PrimaryPart
                local vector, onScreen = Camera:WorldToViewportPoint(part.Position)
                if onScreen then
                    line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                    line.To = Vector2.new(vector.X, vector.Y)
                    line.Visible = true
                else
                    line.Visible = false
                end
            else
                line.Visible = false
                line:Remove()
                Tracers[pet] = nil
            end
        end
    end
end)

task.spawn(function()
    while true do
        pcall(function()
            if Main.Visible and Content.Visible then
                local Ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
                PingLabel.Text = "Ping: " .. Ping .. " ms"
                PlayersLabel.Text = "Players: " .. #Players:GetPlayers() .. " / " .. Players.MaxPlayers
            end
        end)
        task.wait(1)
    end
end)

-- === РАДАР ПЕТОВ (БЕЗ ТП) ===
local function PopulatePetList()
    for _, child in ipairs(PetScrollFrame:GetChildren()) do
        if child:IsA("TextLabel") then child:Destroy() end
    end

    local MapFolder = workspace:FindFirstChild("Map")
    local WildPetSpawns = MapFolder and MapFolder:FindFirstChild("WildPetSpawns")
    local HasPets = false

    if WildPetSpawns then
        for _, petModel in ipairs(WildPetSpawns:GetChildren()) do
            local petNameLower = petModel.Name:lower()
            local matchedName = nil
            
            for wantedName in pairs(WantedPets) do
                if petNameLower:find("wildpet_" .. wantedName:lower() .. "_") then
                    matchedName = wantedName
                    break
                end
            end

            if matchedName then
                HasPets = true
                if not Tracers[petModel] and Drawing then
                    local line = Drawing.new("Line")
                    line.Visible = false
                    line.Color = Color3.fromRGB(100, 255, 100)
                    line.Thickness = 1.5
                    line.Transparency = 1
                    Tracers[petModel] = line
                end

                -- Просто отображаем имя пета (без кнопки)
                local NameLabel = Instance.new("TextLabel")
                NameLabel.Parent = PetScrollFrame
                NameLabel.Size = UDim2.new(1, 0, 0, 20)
                NameLabel.BackgroundTransparency = 1
                NameLabel.Text = "• " .. matchedName
                NameLabel.TextColor3 = Color3.new(1, 1, 1)
                NameLabel.Font = Enum.Font.Gotham
                NameLabel.TextSize = 13
                NameLabel.TextXAlignment = Enum.TextXAlignment.Left
            end
        end
    end

    FoundRarePet = HasPets

    if not HasPets then
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
        WildPetSpawns.ChildRemoved:Connect(function(child) 
            if Tracers[child] then Tracers[child]:Remove(); Tracers[child] = nil end
            task.wait(0.3) 
            PopulatePetList() 
        end)
    end
end)
PopulatePetList()

-- === СИСТЕМА КЭШИРОВАНИЯ СЕРВЕРОВ И ХОПОВ ===
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

local HopDebounce = false
RandomServerHop = function()
    if HopDebounce then return end
    HopDebounce = true
    ServerHopButton.Text = "⚡ Hopping..."
    pcall(function()
        local Servers = GetCachedServers()
        local ValidIndices = {}
        for i, Server in ipairs(Servers) do
            if Server.id ~= JobId
and Server.playing < (Server.maxPlayers - 2)
and not IsRecent(Server.id) then
                table.insert(ValidIndices, i)
            end
        end
        if #ValidIndices > 0 then
            local RandomIdx = ValidIndices[math.random(1, #ValidIndices)]
            local SelectedServer = Servers[RandomIdx]
            table.remove(Servers, RandomIdx)
            UpdateCacheFile(Servers)
            AddRecentServer(SelectedServer.id)
            QueueNextTeleport()
            TeleportService:TeleportToPlaceInstance(PlaceId, SelectedServer.id, LocalPlayer)
        else
            if writefile then pcall(function() writefile(CacheFileName, "[]") end) end
            ServerHopButton.Text = "🔄 Fetching New..."
            task.wait(0.5)
            HopDebounce = false
            RandomServerHop()
            return
        end
    end)
    
    -- Тайм-аут на случай если роблокс просто завис и ничего не делает
    task.delay(10, function() HopDebounce = false; ServerHopButton.Text = "🔄 Server Hop" end)
end

local function LowPlayerHop()
    if HopDebounce then return end
    HopDebounce = true
    LowPlayerButton.Text = "⚡ Hopping..."
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
            AddRecentServer(SelectedServer.id)
            QueueNextTeleport()
            TeleportService:TeleportToPlaceInstance(PlaceId, SelectedServer.id, LocalPlayer)
        else
            if writefile then pcall(function() writefile(CacheFileName, "[]") end) end
            LowPlayerButton.Text = "👥 Fetching New..."
            task.wait(0.5)
            HopDebounce = false
            LowPlayerHop()
            return
        end
    end)
    task.delay(10, function() HopDebounce = false; LowPlayerButton.Text = "👥 Low Player Hop" end)
end

ServerHopButton.MouseButton1Click:Connect(RandomServerHop)
LowPlayerButton.MouseButton1Click:Connect(LowPlayerHop)
RejoinButton.MouseButton1Click:Connect(function() QueueNextTeleport(); TeleportService:TeleportToPlaceInstance(PlaceId, JobId, LocalPlayer) end)

ListButton.MouseButton1Click:Connect(function() ListFrame.Visible = not ListFrame.Visible end)

-- === МОЩНЫЙ ОБРАБОТЧИК ОШИБОК 771/772 (АВТОМАТИЧЕСКИЙ ПРОПУСК) ===
task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
            local prompt = CoreGui:FindFirstChild("RobloxPromptGui")
            if prompt then
                local overlay = prompt:FindFirstChild("promptOverlay")
                if overlay then
                    local errorPrompt = overlay:FindFirstChild("ErrorPrompt")
                    -- Если мы видим ошибку (как на твоем скрине)
                    if errorPrompt and errorPrompt.Visible then
                            errorPrompt.Visible = false -- Прячем это окно
                        HopDebounce = false         -- Сбрасываем блокировку хопа
                    end
                end
            end
        end)
    end
end)

-- Дублирующий обработчик на случай сбоя API телепорта
TeleportService.TeleportInitFailed:Connect(function()
    warn("Teleport failed")
    task.wait(5)
    HopDebounce = false
end)

-- === ЛОГИКА АВТОХОПА (ЖДЕТ 5 СЕК) ===
task.spawn(function()
    if not game:IsLoaded() then game.Loaded:Wait() end
    task.wait(9) -- Ждем 5 секунд после прогрузки
    
    if Settings.AutoHop and not FoundRarePet then
        AutoHopBtn.Text = "⏳ Hopping..."
        RandomServerHop()
    end
end)

-- СВОРАЧИВАНИЕ GUI
local Minimized = false
Minimize.MouseButton1Click:Connect(function()
    Minimized = not Minimized
    Content.Visible = not Minimized
    if Minimized then ListFrame.Visible = false end
    local TargetSize = Minimized and UDim2.new(0, 200, 0, 30) or UDim2.new(0, 200, 0, 430)
    TweenService:Create(Main, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = TargetSize }):Play()
end)

print("UI Fixed, Anti-Error Loop Active, TP Removed!")

end

RunScript()
