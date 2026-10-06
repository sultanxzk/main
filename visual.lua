-- visual.lua | Apenas interface. Callbacks só disparam os arquivos de funcoes/
local Hub = getgenv().Hub

local MacLib = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Enow-Development/maclib-extended/refs/heads/main/maclib.lua"
))()

local Window = MacLib:Window({
    Title    = "Meu Script Hub",
    Subtitle = "v1.0",
})

-- Grupo de abas (obrigatório para aparecerem na barra lateral)
local Grupo = Window:TabGroup()

-- ===== ABA: MOVIMENTO =====
local TabMov = Grupo:Tab({ Name = "Movimento" })
local SecMov = TabMov:Section({ Side = "Left" })

SecMov:Toggle({
    Name    = "Speed Hack",
    Default = false,
    Callback = function(v)
        Hub.Estado.Speed = v
        Hub.Executar("speed")
    end,
}, "SpeedToggle")

SecMov:Slider({
    Name          = "Velocidade",
    Default       = 50,
    Minimum       = 16,
    Maximum       = 200,
    DisplayMethod = "Round",
    Precision     = 0,
    Callback = function(v)
        Hub.Valores.SpeedValor = v
    end,
}, "SpeedSlider")

-- ===== ABA: JOGADOR (exemplo) =====
local TabJog = Grupo:Tab({ Name = "Jogador" })
local SecJog = TabJog:Section({ Side = "Left" })

SecJog:Button({
    Name = "Exemplo de botão",
    Callback = function()
        Hub.Executar("NomeDaFuncao") -- troque pelo nome do seu .lua
    end,
})

-- ===== ABA: CONFIG =====
local TabCfg = Grupo:Tab({ Name = "Config" })
local SecCfg = TabCfg:Section({ Side = "Left" })

SecCfg:Button({
    Name = "Descarregar Hub",
    Callback = function()
        Hub.Desligar()
        Window:Unload()
    end,
})

-- Abre já na primeira aba
TabMov:Select()
