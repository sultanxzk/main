-- true se algum assento do carro tiver alguém sentado
local function temOcupante(carro)
    for _, d in ipairs(carro:GetDescendants()) do
        if (d:IsA("VehicleSeat") or d:IsA("Seat")) and d.Occupant ~= nil then
            return true
        end
    end
    return false
end

-- lista de veículos VAZIOS (rótulo -> Model)
local function montarLista()
    local nomes, mapa = {}, {}
    local pasta = Workspace:FindFirstChild("CarrosSpawnados")
    if not pasta then return nomes, mapa end

    local modelos = {}
    local function adicionar(m)
        if m:IsA("Model") and not temOcupante(m) then
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

    -- numeração só entre os carros que sobraram após o filtro
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
