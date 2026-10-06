-- funcoes/speed.lua | Lógica pura, sem UI
local Hub = getgenv().Hub
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local VELOCIDADE_PADRAO = 16

-- Sempre limpa a conexão anterior (o arquivo roda a cada toggle)
if Hub.Conexoes.Speed then
    Hub.Conexoes.Speed:Disconnect()
    Hub.Conexoes.Speed = nil
end

local function getHumanoid()
    local char = LocalPlayer.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

if Hub.Estado.Speed then
    Hub.Conexoes.Speed = RunService.Heartbeat:Connect(function()
        local hum = getHumanoid()
        if hum then
            hum.WalkSpeed = Hub.Valores.SpeedValor or 50
        end
    end)
else
    local hum = getHumanoid()
    if hum then
        hum.WalkSpeed = VELOCIDADE_PADRAO
    end
end
