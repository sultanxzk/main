local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Hub = getgenv().Hub
local LP = Players.LocalPlayer

local ZERO = Vector3.new(0, 0, 0)

-- a) desconecta conexão anterior
if Hub.Conexoes.PuxarVeiculos then
    pcall(function()
        Hub.Conexoes.PuxarVeiculos:Disconnect()
    end)
    Hub.Conexoes.PuxarVeiculos = nil
end

-- acha o assento do motorista
local function acharDriveSeat(carro)
    for _, d in ipairs(carro:GetDescendants()) do
        if d:IsA("BasePart") then
            local n = d.Name:lower()
            if n == "driveseat" or n == "driverseat" or n == "driver" then
                return d
            end
        end
    end
    for _, d in ipairs(carro:GetDescendants()) do
        if d:IsA("VehicleSeat") then
            return d
        end
    end
    for _, d in ipairs(carro:GetDescendants()) do
        if d:IsA("Seat") then
            local n = d.Name:lower()
            if n:find("drive") or n:find("motorista") then
                return d
            end
        end
    end
    for _, d in ipairs(carro:GetDescendants()) do
        if d:IsA("Seat") then
            return d
        end
    end
    return nil
end

-- true se alguém está sentado nesse assento
local function assentoOcupado(seat)
    if (seat:IsA("Seat") or seat:IsA("VehicleSeat")) and seat.Occupant ~= nil then
        return true
    end
    if seat:FindFirstChild("SeatWeld") then
        return true
    end
    for _, pl in ipairs(Players:GetPlayers()) do
        local c = pl.Character
        local h = c and c:FindFirstChildOfClass("Humanoid")
        if h and h.SeatPart == seat then
            return true
        end
    end
    return false
end

-- só esconde o carro se CONFIRMAR que o motorista está ocupado
local function driveSeatLivre(carro)
    local seat = acharDriveSeat(carro)
    if not seat then
        return true
    end
    return not assentoOcupado(seat)
end

-- lista de veículos com DriveSeat livre (rótulo -> Model)
local function montarLista()
    local nomes = {}
    local mapa = {}
    local pasta = Workspace:FindFirstChild("CarrosSpawnados")
    if not pasta then
        return nomes, mapa
    end

    local modelos = {}
    local function adicionar(m)
        if m:IsA("Model") and driveSeatLivre(m) then
            table.insert(modelos, m)
        end
    end

    for _, v in ipairs(pasta:GetChildren()) do
        if v:IsA("Model") then
            adicionar(v)
        elseif v:IsA("Folder") then
            for _, sub in ipairs(v:GetChildren()) do
                adicionar(sub)
            end
        end
    end

    local contagem = {}
    local usados = {}
    for _, m in ipairs(modelos) do
        contagem[m.Name] = (contagem[m.Name] or 0) + 1
    end
    for _, m in ipairs(modelos) do
        local rotulo = m.Name
        if contagem[m.Name] > 1 then
            usados[m.Name] = (usados[m.Name] or 0) + 1
            rotulo = m.Name .. " #" .. usados[m.Name]
        end
        table.insert(nomes, rotulo)
        mapa[rotulo] = m
    end
    return nomes, mapa
end

Hub.ListarVeiculos = function()
    local nomes = montarLista()
    return nomes
end

local function zerarFisica(carro)
    for _, p in ipairs(carro:GetDescendants()) do
        if p:IsA("BasePart") then
            p.AssemblyLinearVelocity = ZERO
            p.AssemblyAngularVelocity = ZERO
        end
    end
end

-- b) ação de um clique
local function puxar()
    local selecionado = Hub.Valores.PuxarVeiculosSelecionado
    if not selecionado then
        return
    end

    local _, mapa = montarLista()
    local carro = mapa[selecionado]
    if not carro or not carro.Parent then
        return
    end

    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then
        return
    end

    local distancia = Hub.Valores.PuxarVeiculosValor or 10

    -- posição ORIGINAL do player = destino do carro
    local origem = hrp.CFrame
    local alvo = origem * CFrame.new(0, 2, -distancia)

    local fase = "aproximando"
    local seat = nil
    local sentavel = false
    local destino = nil
    local frames = 0
    local estavel = 0
    local pediuStream = false

    local function parar()
        if Hub.Conexoes.PuxarVeiculos then
            Hub.Conexoes.PuxarVeiculos:Disconnect()
            Hub.Conexoes.PuxarVeiculos = nil
        end
    end

    local function passo()
        frames = frames + 1

        if not carro.Parent or not hrp.Parent or hum.Health <= 0 then
            parar()
            return
        end

        if fase == "aproximando" then
            if frames % 3 == 1 then
                seat = acharDriveSeat(carro)
            end

            if seat and seat.Parent then
                sentavel = seat:IsA("Seat") or seat:IsA("VehicleSeat")
                local pivoRelativo = seat.CFrame:ToObjectSpace(carro:GetPivot())
                destino = alvo * pivoRelativo
                if sentavel then
                    fase = "sentando"
                else
                    fase = "movendo"
                end
                frames = 0
                estavel = 0
                return
            end

            local ok, pos = pcall(function()
                return carro:GetPivot().Position
            end)
            if ok and pos.Magnitude > 1 then
                hrp.CFrame = CFrame.new(pos + Vector3.new(0, 8, 0))
                if not pediuStream then
                    pediuStream = true
                    task.spawn(function()
                        pcall(function()
                            LP:RequestStreamAroundAsync(pos)
                        end)
                    end)
                end
            end

            if frames > 180 then
                parar()
            end
            return
        end

        if fase == "sentando" then
            if not seat.Parent then
                fase = "aproximando"
                frames = 0
                return
            end

            if seat.Occupant and seat.Occupant ~= hum then
                parar()
                return
            end

            if hum.SeatPart == seat then
                fase = "movendo"
                frames = 0
                estavel = 0
                return
            end

            hrp.CFrame = seat.CFrame * CFrame.new(0, 2, 0)
            pcall(function()
                seat:Sit(hum)
            end)

            if frames > 90 then
                parar()
            end
            return
        end

        if fase == "movendo" then
            if frames < 4 then
                return
            end

            if sentavel and hum.SeatPart ~= seat then
                fase = "sentando"
                frames = 0
                return
            end

            local erro = (carro:GetPivot().Position - destino.Position).Magnitude
            if erro > 1 then
                estavel = 0
                carro:PivotTo(destino)
            else
                estavel = estavel + 1
            end
            zerarFisica(carro)

            if estavel >= 15 or frames >= 150 then
                parar()
            end
        end
    end

    Hub.Conexoes.PuxarVeiculos = RunService.Heartbeat:Connect(passo)
end

if Hub.Estado.PuxarVeiculos == true then
    Hub.Estado.PuxarVeiculos = false -- one-shot
    puxar()
end
