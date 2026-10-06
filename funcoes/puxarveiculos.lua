-- true se o assento do motorista existe e está livre
local function driveSeatLivre(carro)
    local seat = acharDriveSeat(carro)
    if not seat then return false end
    if not (seat:IsA("Seat") or seat:IsA("VehicleSeat")) then
        return false -- peça comum: não dá pra sentar, então não lista
    end
    return seat.Occupant == nil
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
