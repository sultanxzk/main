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

-- lista de veículos (rótulo -> Model)
local function montarLista()
    local pasta = Workspace:FindFirstChild("CarrosSpawnados")
    local nomes, mapa, contagem = {}, {}, {}
    if not pasta then return nomes, mapa end

    local modelos = {}
    for _, v in ipairs(pasta:GetChildren()) do
        if v:IsA("Model") then
            table.insert(modelos, v)
            contagem[v.Name] = (contagem[v.Name] or 0) + 1
        end
    end

    local usados = {}
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

-- b) ligar
if Hub.Estado.PuxarVeiculos == true then
    Hub.Conexoes.PuxarVeiculos = RunService.Heartbeat:Connect(function()
        local char = LP.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum then return end

        local selecionado = Hub.Valores.PuxarVeiculosSelecionado
        if not selecionado then return end

        local _, mapa = montarLista()
        local carro = mapa[selecionado]
        if not carro or not carro.Parent then return end

        -- não puxa se o player já estiver sentado nesse carro
        local assento = hum.SeatPart
        if assento and assento:IsDescendantOf(carro) then return end

        local distancia = Hub.Valores.PuxarVeiculosValor or 15
        carro:PivotTo(hrp.CFrame * CFrame.new(0, 2, -distancia))

        local base = carro.PrimaryPart or carro:FindFirstChildWhichIsA("BasePart", true)
        if base then
            base.AssemblyLinearVelocity = Vector3.zero
            base.AssemblyAngularVelocity = Vector3.zero
        end
    end)
end
-- c) desligado: conexão já foi desfeita acima, nada a restaurar
