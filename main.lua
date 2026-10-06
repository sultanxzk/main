-- main.lua | Injetor: é o único arquivo que você executa no executor
local USUARIO = "SEU_USUARIO"
local REPO    = "meu-script-hub"
local BRANCH  = "main"

local BASE = ("https://raw.githubusercontent.com/%s/%s/%s/"):format(USUARIO, REPO, BRANCH)

-- Evita carregar duas vezes: limpa a instância anterior
if getgenv().Hub and getgenv().Hub.Desligar then
    pcall(getgenv().Hub.Desligar)
end

-- Estado global compartilhado entre visual.lua e funcoes/
getgenv().Hub = {
    Base     = BASE,
    Estado   = {},   -- ex: Hub.Estado.Speed = true/false
    Valores  = {},   -- ex: Hub.Valores.SpeedValor = 50
    Conexoes = {},   -- conexões ativas (RunService etc.)
}

local Hub = getgenv().Hub

-- Desliga tudo e limpa conexões
function Hub.Desligar()
    for nome in pairs(Hub.Estado) do
        Hub.Estado[nome] = false
    end
    for nome, conn in pairs(Hub.Conexoes) do
        pcall(function() conn:Disconnect() end)
        Hub.Conexoes[nome] = nil
    end
end

-- Executa um arquivo da pasta funcoes/
function Hub.Executar(nome)
    local ok, err = pcall(function()
        loadstring(game:HttpGet(Hub.Base .. "funcoes/" .. nome .. ".lua"))()
    end)
    if not ok then
        warn("[Hub] Erro em funcoes/" .. nome .. ".lua: " .. tostring(err))
    end
end

-- Carrega a interface
local ok, err = pcall(function()
    loadstring(game:HttpGet(BASE .. "visual.lua"))()
end)
if not ok then
    warn("[Hub] Erro ao carregar visual.lua: " .. tostring(err))
end
