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

-- acha o assento do motorista
local function acharDriveSeat(carro)
    local seat = carro:FindFirstChild("DriveSeat", true)
    if seat and seat:IsA("BasePart") then return seat end
    for _, d in ipairs(carro:GetDescendants()) do
        if d:IsA("VehicleSeat") then return d end
    end
    for _, d in ipairs(carro:GetDescendants()) do
        if d:IsA("Seat") then return d end
    end
    return nil
end

-- lista de veículos (rótulo -> Model)
local function montarLista()
    local nomes, mapa = {}, {}
    local pasta = Workspace:FindFirstChild("CarrosSpawnados")
    if not pasta then return nomes, mapa end

    local modelos = {}
    for _, v in ipairs(pasta:GetChildren()) do
        if v:IsA("Model") then
            table.insert(modelos, v)
        elseif v:IsA("Folder") then
            for _, sub in ipairs(v:GetChildren()) do
                if sub:IsA("Model") then table.insert(modelos, sub) end
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

-- zera toda a física do carro
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

    local seat = acharDriveSeat(carro)
    if not seat then return end

    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local distancia = Hub.Valores.PuxarVeiculosValor or 10

    -- destino calculado UMA vez (não segue o player depois)
    local alvo = hrp.CFrame * CFrame.new(0, 2, -distancia)
    local pivoRelativo = seat.CFrame:ToObjectSpace(carro:GetPivot())
    local destino = alvo * pivoRelativo

    -- tenta pegar o controle de rede do carro
    pcall(function()
        if seat:IsA("BasePart") then
            seat:SetNetworkOwner(LP)
        end
    end)

    -- teleporte instantâneo
    carro:PivotTo(destino)
    zerarFisica(carro)

    -- reforço curto: só alguns frames, e para assim que estabilizar
    local frames = 0
    Hub.Conexoes.PuxarVeiculos = RunService.Heartbeat:Connect(function()
        frames += 1

        if not carro.Parent or not seat.Parent then
            Hub.Conexoes.PuxarVeiculos:Disconnect()
            Hub.Conexoes.PuxarVeiculos = nil
            return
        end

        local erro = (carro:GetPivot().Position - destino.Position).Magnitude

        if erro > 1 then
            -- a replicação puxou o carro de volta: reaplica
            carro:PivotTo(destino)
        end
        zerarFisica(carro)

        -- encerra após ~8 frames estáveis ou limite de segurança
        if (erro <= 1 and frames >= 8) or frames >= 40 then
            Hub.Conexoes.PuxarVeiculos:Disconnect()
            Hub.Conexoes.PuxarVeiculos = nil
        end
    end)
end
