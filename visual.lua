-- visual.lua | Apenas interface. Callbacks só disparam os arquivos de funcoes/
local Hub = getgenv().Hub

local MacLib = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Enow-Development/maclib-extended/refs/heads/main/maclib.lua"
))()

local ICONE = "rbxassetid://10734950309"

local Window = MacLib:Window({
    Title    = "Meu Script Hub",
    Subtitle = "v1.0",
})

-- ===== ABA: MOVIMENTO =====
local TabMov = Window:Tab({ Name = "Movimento", Icon = ICONE })
local SecMov = TabMov:Section({ Side = "Left" })

SecMov:Toggle({
    Name     = "Speed Hack",
    Default  = false,
    Flag     = "SpeedToggle",
    Callback = function(v)
        Hub.Estado.Speed = v
        Hub.Executar("speed")
    end,
})

SecMov:Slider({
    Name     = "Velocidade",
    Min      = 16,
    Max      = 200,
    Default  = 50,
    Flag     = "SpeedSlider",
    Callback = function(v)
        Hub.Valores.SpeedValor = v
    end,
})

-- ===== ABA: JOGADOR (exemplo) =====
local TabJog = Window:Tab({ Name = "Jogador", Icon = ICONE })
local SecJog = TabJog:Section({ Side = "Left" })

SecJog:Button({
    Name     = "Exemplo de botão",
    Callback = function()
        Hub.Executar("NomeDaFuncao") -- troque pelo nome do seu .lua
    end,
})

-- ===== ABA: CONFIG =====
local TabCfg = Window:Tab({ Name = "Config", Icon = ICONE })
local SecCfg = TabCfg:Section({ Side = "Left" })

SecCfg:Button({
    Name     = "Desligar todas as funções",
    Callback = function()
        Hub.Desligar()
    end,
})

TabCfg:InsertConfigSection("Right") -- salvar/carregar configs (usa as Flags)
