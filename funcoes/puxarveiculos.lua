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

-- lista de veículos (rótulo -> Model), aceita carros direto na pasta ou dentro de subpastas
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

-- usado pelo visual para listar os veículos disponíveis
Hub.ListarVeiculos = function()
    local nomes = montarLista()
    return nomes
end

-- b) ação de um clique: só puxa quando o visual setar Estado = true
if Hub.Estado.PuxarVeiculos == true then
    Hub.Estado.PuxarVeiculos = false -- one-shot: volta ao normal

    local selecionado = Hub.Valores.PuxarVeiculosSelecionado
    if not selecionado then return end

    local _, mapa = montarLista()
    local carro = mapa[selecionado]
    if not carro or not carro.Parent then return end

    local seat = acharDriveSeat(carro)
    if not seat then return end

    local distancia = Hub.Valores.PuxarVeiculosValor or 10
    local tempo = 0

    -- reaplica por ~0.6s para vencer a física/replicação do carro
    Hub.Conexoes.PuxarVeiculos = RunService.Heartbeat:Connect(function(dt)
        tempo += dt
        local char = LP.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp or not carro.Parent or not seat.Parent or tempo > 0.6 then
            if Hub.Conexoes.PuxarVeiculos then
                Hub.Conexoes.PuxarVeiculos:Disconnect()
                Hub.Conexoes.PuxarVeiculos = nil
            end
            return
        end

        -- posiciona o DriveSeat na frente do player
        local alvo = hrp.CFrame * CFrame.new(0, 2, -distancia)
        local pivoRelativo = seat.CFrame:ToObjectSpace(carro:GetPivot())
        carro:PivotTo(alvo * pivoRelativo)

        for _, p in ipairs(carro:GetDescendants()) do
            if p:IsA("BasePart") then
                p.AssemblyLinearVelocity = Vector3.zero
                p.AssemblyAngularVelocity = Vector3.zero
            end
        end
    end)
end
-- c) nada a restaurar: a ação já terminou e a conexão é limpa sozinha
