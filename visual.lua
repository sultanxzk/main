-- visual.lua | Apenas interface. Callbacks só disparam os arquivos de funcoes/
local Hub = getgenv().Hub

local MacLib = loadstring(game:HttpGet(
    "https://github.com/biggaboy212/Maclib/releases/latest/download/maclib.lua"
))()

local Window = MacLib:Window({
    Title    = "Meu Script Hub",
    Subtitle = "v1.0",
    Size     = UDim2.fromOffset(700, 480),
    Keybind  = Enum.KeyCode.RightControl, -- mostra/esconde o menu
    AcrylicBlur = true,
})

-- As abas ficam dentro de um TabGroup
local Grupo = Window:TabGroup()

-- ===== ABA: MOVIMENTO =====
local TabMov = Grupo:Tab({ Name = "Movimento", Image = "rbxassetid://18821914323" })
local SecMov = TabMov:Section({ Side = "Left" })

SecMov:Toggle({
    Name     = "Speed Hack",
    Default  = false,
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
local TabJog = Grupo:Tab({ Name = "Jogador", Image = "rbxassetid://18821914323" })
local SecJog = TabJog:Section({ Side = "Left" })

SecJog:Button({
    Name     = "Exemplo de botão",
    Callback = function()
        Hub.Executar("NomeDaFuncao") -- troque pelo nome do seu .lua
    end,
})

-- ===== ABA: CONFIG =====
local TabCfg = Grupo:Tab({ Name = "Config", Image = "rbxassetid://18821914323" })
local SecCfg = TabCfg:Section({ Side = "Left" })

SecCfg:Button({
    Name     = "Desligar todas as funções",
    Callback = function()
        Hub.Desligar()
    end,
})

-- Salvamento de configs (usa as flags "SpeedToggle" e "SpeedSlider")
pcall(function()
    MacLib:SetFolder("MeuScriptHub")
    TabCfg:InsertConfigSection("Right")
end)

-- Abre já na primeira aba
TabMov:Select()

pcall(function() MacLib:LoadAutoLoadConfig() end)
