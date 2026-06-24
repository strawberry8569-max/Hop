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

local StartTime = tick()
local HopCount = 0
local RecentServers = {}

-- === СПИСОК РЕДКИХ ПЕТОВ ===
local WantedPets = {
    Unicorn = true,
    Raccoon = true,
    Dragonfly = true,
    Bee = true,
    Bear = true
}

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

-- === СОЗДАНИЕ GUI (Размеры подстроены под блок петов) ===
local Gui = Instance.new("ScreenGui")
Gui.Name = "HopGui"
Gui.ResetOnSpawn = false
Gui.Parent = game.CoreGui

local Main = Instance.new("Frame")
Main.Parent = Gui
Main.Size = UDim2.new(0,200,0,450)
Main.Position = UDim2.new(1,-230,0,40)
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

local PingLabel = FPSLabel:Clone() PingLabel.Parent = Main PingLabel.Position = UDim2.new(0,10,0,50)
local PlayersLabel = FPSLabel:Clone() PlayersLabel.Parent = Main PlayersLabel.Position = UDim2.new(0,10,0,70)
local RuntimeLabel = FPSLabel:Clone() RuntimeLabel.Parent = Main RuntimeLabel.Position = UDim2.new(0,10,0,90)
local HopsLabel = FPSLabel:Clone() HopsLabel.Parent = Main HopsLabel.Position = UDim2.new(0,10,0,110)
local RamLabel = FPSLabel:Clone() RamLabel.Parent = Main RamLabel.Position = UDim2.new(0,10,0,130)
local ServerTimeLabel = FPSLabel:Clone() ServerTimeLabel.Parent = Main ServerTimeLabel.Position = UDim2.new(0,10,0,150)

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

local ServerHopButton = CreateButton("🔄 Server Hop",180)
local LowPlayerButton = CreateButton("👥 Low Player Hop",214)
local RejoinButton = CreateButton("↻ Rejoin",248)

-- === ВСТРОЕННЫЙ БЛОК ПЕТОВ ИЗ КОДА ===
local PetsHeader = Instance.new("TextLabel")
PetsHeader.Parent = Main
PetsHeader.Position = UDim2.new(0, 10, 0, 285)
PetsHeader.Size = UDim2.new(1, -20, 0, 20)
PetsHeader.BackgroundTransparency = 1
PetsHeader.Text = "Pets:"
PetsHeader.TextColor3 = Color3.fromRGB(150, 200, 150)
PetsHeader.Font = Enum.Font.GothamBold
PetsHeader.TextSize = 14
PetsHeader.TextXAlignment = Enum.TextXAlignment.Left

local PetScrollFrame = Instance.new("ScrollingFrame")
PetScrollFrame.Parent = Main
PetScrollFrame.Position = UDim2.new(0, 10, 0, 310)
PetScrollFrame.Size = UDim2.new(1, -20, 0, 130)
PetScrollFrame.BackgroundTransparency = 1
PetScrollFrame.ScrollBarThickness = 2
PetScrollFrame.BorderSizePixel = 0

local PetListLayout = Instance.new("UIListLayout")
PetListLayout.Parent = PetScrollFrame
PetListLayout.Padding = UDim.new(0, 4)
PetListLayout.SortOrder = Enum.SortOrder.LayoutOrder

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

local FPS, Frames, LastUpdate = 0, 0, tick()
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

-- === СТАБИЛЬНЫЙ ПАРСИНГ СЕРВЕРОВ ЧЕРЕЗ HttpGet ===
local function GetServers()
    local Servers = {}
    local success, res = pcall(function()
        return game:HttpGet("https://games.roblox.com/v1/games/" .. PlaceId .. "/servers/Public?sortOrder=Asc&limit=100")
    end)
    
    if success and res then
        pcall(function()
            local Data = HttpService:JSONDecode(res)
            if Data and Data.data then
                for _, Server in ipairs(Data.data) do
                    table.insert(Servers, Server)
                end
            end
        end)
    end
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

        if #ValidServers == 0 then
            -- Если все серверы помечены как недавние, сбрасываем кэш кроме текущего
            RecentServers = { JobId }
            for _, Server in ipairs(Servers) do
                if Server.id ~= JobId and Server.playing < Server.maxPlayers then
                    table.insert(ValidServers, Server)
                end
            end
        end

        if #ValidServers > 0 then
            local Selected = ValidServers[math.random(1,#ValidServers)]
            HopCount += 1
            AddRecentServer(Selected.id)
            getgenv().RecentServers = RecentServers

            if queue_on_teleport then
                -- Исправлен синтаксис передачи данных в следующий мир (без ошибок '[' )
                queue_on_teleport([[getgenv().RecentServers = game:GetService("HttpService"):JSONDecode(']] .. HttpService:JSONEncode(RecentServers) .. [[')]])
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

        local TargetServer = nil
        for _, Server in ipairs(Servers) do
            if Server.id ~= JobId and Server.playing < Server.maxPlayers and not IsRecent(Server.id) then
                TargetServer = Server
                break
            end
        end

        if not TargetServer then
            RecentServers = { JobId }
            for _, Server in ipairs(Servers) do
                if Server.id ~= JobId and Server.playing < Server.maxPlayers then
                    TargetServer = Server
                    break
                end
            end
        end

        if TargetServer then
            HopCount += 1
            AddRecentServer(TargetServer.id)
            getgenv().RecentServers = RecentServers

            if queue_on_teleport then
                queue_on_teleport([[getgenv().RecentServers = game:GetService("HttpService"):JSONDecode(']] .. HttpService:JSONEncode(RecentServers) .. [[')]])
            end
            TeleportService:TeleportToPlaceInstance(PlaceId, TargetServer.id, LocalPlayer)
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

local Hidden, SavedPosition = false, Main.Position
local function ToggleGui()
    pcall(function()
        if Hidden then
            Main.Visible = true
            TweenService:Create(Main, TweenInfo.new(0.2, Enum.EasingStyle.Quad), { Position = SavedPosition }):Play()
            Hidden = false
        else
            SavedPosition = Main.Position
            local HideTween = TweenService:Create(Main, TweenInfo.new(0.2, Enum.EasingStyle.Quad), { Position = UDim2.new(SavedPosition.X.Scale, SavedPosition.X.Offset + 240, SavedPosition.Y.Scale, SavedPosition.Y.Offset) })
            HideTween:Play()
            Hidden = true
            task.delay(0.2, function() if Hidden then Main.Visible = false end end)
        end
    end)
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.H then ToggleGui()
    elseif input.KeyCode == Enum.KeyCode.J then RandomServerHop()
    elseif input.KeyCode == Enum.KeyCode.K then LowPlayerHop()
    elseif input.KeyCode == Enum.KeyCode.L then Rejoin()
    end
end)

TeleportService.TeleportInitFailed:Connect(function()
    task.wait(2)
    pcall(RandomServerHop)
end)

-- === ИСПРАВЛЕННАЯ ЛОГИКА ПУТИ И СКАНИРОВАНИЯ ПЕТОВ ===
local function PopulatePetList()
    for _, child in ipairs(PetScrollFrame:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    -- Исправленный путь: workspace.Map.WildPetSpawns
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
                ItemFrame.Size = UDim2.new(1, -4, 0, 24)
                ItemFrame.BackgroundTransparency = 1

                local NameLabel = Instance.new("TextLabel")
                NameLabel.Parent = ItemFrame
                NameLabel.Size = UDim2.new(1, -45, 1, 0)
                NameLabel.BackgroundTransparency = 1
                NameLabel.Text = "🐾 " .. matchedName
                NameLabel.TextColor3 = Color3.new(1, 1, 1)
                NameLabel.Font = Enum.Font.Gotham
                NameLabel.TextSize = 12
                NameLabel.TextXAlignment = Enum.TextXAlignment.Left

                local TPBtn = Instance.new("TextButton")
                TPBtn.Parent = ItemFrame
                TPBtn.Size = UDim2.new(0, 40, 1, 0)
                TPBtn.Position = UDim2.new(1, -40, 0, 0)
                TPBtn.BackgroundColor3 = Color3.fromRGB(55, 75, 55)
                TPBtn.BorderSizePixel = 0
                TPBtn.TextColor3 = Color3.new(1, 1, 1)
                TPBtn.Font = Enum.Font.GothamBold
                TPBtn.TextSize = 11
                TPBtn.Text = "TP"

                local TPCorner = Instance.new("UICorner")
                TPCorner.CornerRadius = UDim.new(0, 4)
                TPCorner.Parent = TPBtn

                TPBtn.MouseButton1Click:Connect(function()
                    local Character = LocalPlayer.Character
                    local Root = Character and Character:FindFirstChild("HumanoidRootPart")
                    -- Ищет Torso или любой BasePart внутри модели пета
                    local PetPart = petModel:FindFirstChildWhichIsA("BasePart", true) or petModel.PrimaryPart

                    if Root and PetPart then
                        Root.CFrame = PetPart.CFrame + Vector3.new(0, 3, 0)
                        TPBtn.Text = "✨"
                        task.wait(0.5)
                        TPBtn.Text = "TP"
                    else
                        TPBtn.Text = "❌"
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
        EmptyLabel.Text = "No rare pets found"
        EmptyLabel.TextColor3 = Color3.fromRGB(120, 120, 120)
        EmptyLabel.Font = Enum.Font.Gotham
        EmptyLabel.TextSize = 12
        EmptyLabel.TextXAlignment = Enum.TextXAlignment.Left
    end

    PetScrollFrame.CanvasSize = UDim2.new(0, 0, 0, PetListLayout.AbsoluteContentSize.Y + 5)
end

-- Динамическое обновление списка при изменении в папочке Map.WildPetSpawns
task.spawn(function()
    local MapFolder = workspace:WaitForChild("Map", 10)
    local WildPetSpawns = MapFolder and MapFolder:WaitForChild("WildPetSpawns", 10)
    if WildPetSpawns then
        WildPetSpawns.ChildAdded:Connect(function() task.wait(0.2) PopulatePetList() end)
        WildPetSpawns.ChildRemoved:Connect(function() task.wait(0.2) PopulatePetList() end)
    end
end)

-- Мгновенный первый запуск проверки при инжекте
PopulatePetList()

local Minimized = false
Minimize.MouseButton1Click:Connect(function()
    Minimized = not Minimized
    local Elements = { ServerHopButton, LowPlayerButton, RejoinButton, FPSLabel, PingLabel, PlayersLabel, RuntimeLabel, HopsLabel, RamLabel, ServerTimeLabel, PetsHeader, PetScrollFrame }
    for _, element in ipairs(Elements) do element.Visible = not Minimized end
    local TargetSize = Minimized and UDim2.new(0,200,0,30) or UDim2.new(0,200,0,450)
    TweenService:Create(Main, TweenInfo.new(0.2), { Size = TargetSize }):Play()
end)

print("Server Tools Loaded Successfully!")
