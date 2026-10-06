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
    -- 1) qualquer peça chamada DriveSeat / Driver
    for _, d in ipairs(carro:GetDescendants()) do
        if d:IsA("BasePart") then
            local n = d.Name:lower()
            if n == "driveseat" or n == "driverseat" or n == "driver" then
                return d
            end
        end
    end
    -- 2) VehicleSeat
    for _, d in ipairs(carro:GetDescendants()) do
        if d:IsA("VehicleSeat") then return d end
    end
    -- 3) Seat com nome parecido com motorista
    for _, d in ipairs(carro:GetDescendants()) do
        if d:IsA("Seat") then
            local n = d.Name:lower()
            if n:find("drive") or n:find("driver") or n:find("motorista") then
                return d
            end
        end
    end
    -- 4) primeiro Seat qualquer
    for _, d in ipairs(carro:GetDescendants()) do
        if d:IsA("Seat") then return d end
    end
    return nil
end

-- true se alguém está sentado nesse assento (funciona até com Part comum)
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
local function driveSeatLivre(carro)
    local seat = acharDriveSeat(carro)
    if not seat then return true end -- não achou assento: lista mesmo assim
    return not assentoOcupado(seat)
end

-- lista de veículos com DriveSeat LIVRE (rótulo -> Model)
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

    -- numeração só entre os carros que passaram no filtro
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

-- usado pelo visual para listar os veículos disponíveis
Hub.ListarVeiculos = function()
    local nomes = montarLista()
    return nomes
end

-- zera toda a física do carro
local function zerarFisica(carro)
    for _, p in ipairs(carro:GetDescendants()) do
        if p:IsA("BasePart") then
            p.AssemblyLinearVelocity = Vector3.zero
            p.AssemblyAngularVelocity = Vector3.zero
        end
    end
end

-- b) ação de um clique: só puxa quando o visual setar Estado = true
if Hub.Estado.PuxarVeiculos == true then
    Hub.Estado.PuxarVeiculos = false -- one-shot

    local selecionado = Hub.Valores.PuxarVeiculosSelecionado
    if not selecionado then return end

    local _, mapa = montarLista()
    local carro = mapa[selecionado]
    if not carro or not carro.Parent then return end

    local seat = acharDriveSeat(carro)
    local sentavel = seat and (seat:IsA("Seat") or seat:IsA("VehicleSeat"))

    -- referência de posição: o assento, ou o corpo do carro se não houver
    local ref = seat or carro.PrimaryPart or carro:FindFirstChildWhichIsA("BasePart", true)
    if not ref then return end

    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    local distancia = Hub.Valores.PuxarVeiculosValor or 10

    -- destino calculado UMA vez, antes de qualquer teleporte
    local alvo = hrp.CFrame * CFrame.new(0, 2, -distancia)
    local pivoRelativo = ref.CFrame:ToObjectSpace(carro:GetPivot())
    local destino = alvo * pivoRelativo

    local estado = sentavel and "sentando" or "movendo"
    local frames = 0

    local function parar()
        if Hub.Conexoes.PuxarVeiculos then
            Hub.Conexoes.PuxarVeiculos:Disconnect()
            Hub.Conexoes.PuxarVeiculos = nil
        end
    end

    Hub.Conexoes.PuxarVeiculos = RunService.Heartbeat:Connect(function()
        frames += 1

        if not carro.Parent or not ref.Parent or not hrp.Parent or hum.Health <= 0 then
            return parar()
        end

        if estado == "sentando" then
            -- alguém sentou antes de você: cancela
            if seat.Occupant and seat.Occupant ~= hum then
                return parar()
            end

            -- já sentado: move o carro (o player vai junto pela solda)
            if hum.SeatPart == seat then
                estado = "movendo"
                frames = 0
                carro:PivotTo(destino)
                zerarFisica(carro)
                return
            end

            -- leva o player até o banco e força o sit
            hrp.CFrame = seat.CFrame * CFrame.new(0, 2, 0)
            pcall(function() seat:Sit(hum) end)

            if frames > 60 then return parar() end -- não conseguiu sentar

        else -- movendo
            local erro = (carro:GetPivot().Position - destino.Position).Magnitude
            if erro > 1 then
                carro:PivotTo(destino) -- a replicação puxou de volta: reaplica
            end
            zerarFisica(carro)

            if (erro <= 1 and frames >= 10) or frames >= 60 then
                parar()
            end
        end
    end)
end
-- c) nada a restaurar: a conexão é limpa sozinha
