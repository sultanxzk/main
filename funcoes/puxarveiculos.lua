local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Hub = getgenv().Hub
local LP = Players.LocalPlayer

-- a) desconecta conexão anterior
if Hub.Conexoes.PuxarVeiculos then
    pcall(function() Hub.Conexoes.PuxarVeiculos:Disconnect() end)
    Hub.Conexoes.PuxarVeiculos = nil
end

-- acha o assento do motorista (tenta vários jeitos)
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
        if d:IsA("VehicleSeat") then return d end
    end
    for _, d in ipairs(carro:GetDescendants()) do
        if d:IsA("Seat") then
            local n = d.Name:lower()
            if n:find("drive") or n:find("driver") or n:find("motorista") then
                return d
            end
        end
    end
    for _, d in ipairs(carro:GetDescendants()) do
        if d:IsA("Seat") then return d end
    end
    return nil
end

-- true se alguém está sentado nesse assento
local function assentoOcupado(seat)
    if (seat:IsA("Seat") or seat:IsA("VehicleSeat")) and seat.Occupant ~= nil then
        return true
    end
    if seat:FindFirstChild("SeatWeld") then return true end
    for _, pl in ipairs(Players:GetPlayers()) do
        local c = pl.Character
        local h = c and c:FindFirstChildOfClass("Humanoid")
        if h and h.SeatPart == seat then return true end
    end
    return false
end

-- só esconde o carro se CONFIRMAR que o motorista está ocupado
-- (carro longe, sem assento carregado, aparece na lista)
local function driveSeatLivre(carro)
    local seat = acharDriveSeat(carro)
    if not seat then return true end
    return not assentoOcupado(seat)
end

-- lista de veículos com DriveSeat livre (rótulo -> Model)
local function montarLista()
    local nomes, mapa = {}, {}
    local pasta = Workspace:FindFirstChild("CarrosSpawnados")
    if not pasta then return nomes, mapa end

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

    local contagem, usados = {}, {}
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
            p.AssemblyLinearVelocity = Vector3.zero
            p.AssemblyAngularVelocity = Vector3.zero
        end
    end
end

-- b) ação de um clique
if Hub.Estado.PuxarVeiculos == true then
    Hub.Estado.PuxarVeiculos = false

    local selecionado = Hub.Valores.PuxarVeiculosSelecionado
    if not selecionado then return end

    local _, mapa = montarLista()
    local carro = mapa[selecionado]
    if not carro or not carro.Parent then return end

    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    local distancia = Hub.Valores.PuxarVeiculosValor or 10

    -- posição ORIGINAL do player (destino do carro), guardada agora
    local origem = hrp.CFrame
    local alvo = origem * CFrame.new(0, 2, -distancia)

    local fase = "aproximando"
    local seat, sentavel, destino
    local frames, estavel = 0, 0
    local pediuStream = false

    local function parar()
        if Hub.Conexoes.PuxarVeiculos then
            Hub.Conexoes.PuxarVeiculos:Disconnect()
            Hub.Conexoes.PuxarVeiculos = nil
        end
    end

    Hub.Conexoes.PuxarVeiculos = RunService.Heartbeat:Connect(function()
        frames += 1

        if not carro.Parent or not hrp.Parent or hum.Health <= 0 then
            return parar()
        end

        -- FASE 1: vai até o carro (força o streaming) e acha o assento
        if fase == "aproximando" then
            if frames % 3 == 1 then
                seat = acharDriveSeat(carro)
            end

            if seat and seat.Parent then
                sentavel = seat:IsA("Seat") or seat:IsA("VehicleSeat")
                -- destino do carro: assento ficará em "alvo"
                local pivoRelativo = seat.CFrame:ToObjectSpace(carro:GetPivot())
                destino = alvo * pivoRelativo
                fase = sentavel and "sentando" or "movendo"
                frames, estavel = 0, 0
                return
            end

            local ok, pos = pcall(function() return carro:GetPivot().Position end)
            if ok and pos.Magnitude > 1 then
                hrp.CFrame = CFrame.new(pos + Vector3.new(0, 8, 0))
                if not pediuStream then
                    pediuStream = true
                    task.spawn(function()
                        pcall(function() LP:RequestStreamAroundAsync(pos) end)
                    end)
                end
            end

            if frames > 180 then return parar() end -- carro não carregou
            return
        end

        -- FASE 2: senta no DriveSeat
        if fase == "sentando" then
            if not seat.Parent then fase = "aproximando" frames = 0 return end

            if seat.Occupant and seat.Occupant ~= hum then
                return parar() -- alguém sentou antes
            end

            if hum.SeatPart == seat then
                fase = "movendo"
                frames, estavel = 0, 0
                return
            end

            hrp.CFrame = seat.CFrame * CFrame.new(0, 2, 0)
            pcall(function() seat:Sit(hum) end)

            if frames > 90 then return parar() end -- não conseguiu sentar
            return
        end

        -- FASE 3: puxa o carro até o player
        if fase == "movendo" then
            if frames < 4 then return end -- espera o controle de rede chegar

            -- perdeu o assento no caminho: senta de novo
            if sentavel and hum.SeatPart ~= seat then
                fase = "sentando"
                frames = 0
                return
            end

            local erro = (carro:GetPivot().Position - destino.Position).Magnitude
            if erro > 1 then
                estavel = 0
                carro:PivotTo(destino) -- teleporte; reaplica se o jogo puxar de volta
            else
                estavel += 1
            end
            zerarFisica(carro)

            if estavel >= 15 or frames >= 150 then
                parar()
            end
        end
    end)
end
