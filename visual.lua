-- visual.lua | Apenas interface. Callbacks só disparam os arquivos de funcoes/
local Hub = getgenv().Hub

-- Carrega a MacLib com checagem de erro clara
local URL_LIB = "https://github.com/biggaboy212/Maclib/releases/latest/download/maclib.txt"
local okHttp, codigo = pcall(game.HttpGet, game, URL_LIB)
assert(okHttp and type(codigo) == "string", "Falha ao baixar a MacLib: " .. tostring(codigo))

local fn, errCompilar = loadstring(codigo)
assert(fn, "MacLib baixada mas inválida: " .. tostring(errCompilar))

local MacLib = fn()

local Window = MacLib:Window({
    Title        = "Meu Script Hub",
    Subtitle     = "v1.0",
    Size         = UDim2.fromOffset(700, 480),
    DragStyle    = 2,
    DisabledWindowControls = {},
    ShowUserInfo = true,
    Keybind      = Enum.KeyCode.RightControl, -- mostra/esconde o menu
    AcrylicBlur  = true,
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

-- ===== ABA: VEÍCULOS =====
local TabVeic = Grupo:Tab({ Name = "Veículos", Image = "rbxassetid://18821914323" })
local SecVeic = TabVeic:Section({ Side = "Left" })

-- Carrega a função uma vez (Estado ainda desligado) para expor Hub.ListarVeiculos
Hub.Executar("puxarveiculos")

local DropVeiculos = SecVeic:Dropdown({
    Name     = "Veículo",
    Search   = true,
    Multi    = false,
    Required = false,
    Options  = Hub.ListarVeiculos and Hub.ListarVeiculos() or {},
    Default  = nil,
    Callback = function(v)
        Hub.Valores.PuxarVeiculosSelecionado = v
    end,
}, "PuxarVeiculosDropdown")

SecVeic:Button({
    Name     = "Atualizar lista",
    Callback = function()
        DropVeiculos:ClearOptions()
        DropVeiculos:InsertOptions(Hub.ListarVeiculos())
    end,
}, "PuxarVeiculosAtualizar")

SecVeic:Toggle({
    Name     = "Puxar Veículo",
    Default  = false,
    Callback = function(v)
        Hub.Estado.PuxarVeiculos = v
        Hub.Executar("puxarveiculos")
    end,
}, "PuxarVeiculosToggle")

SecVeic:Slider({
    Name          = "Distância",
    Default       = 15,
    Minimum       = 5,
    Maximum       = 100,
    DisplayMethod = "Round",
    Precision     = 0,
    Callback = function(v)
        Hub.Valores.PuxarVeiculosValor = v
    end,
}, "PuxarVeiculosSlider")

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

-- Salvamento de configs (usa as flags "SpeedToggle", "SpeedSlider" e as de veículos)
pcall(function()
    MacLib:SetFolder("MeuScriptHub")
    TabCfg:InsertConfigSection("Right")
end)

-- Abre já na primeira aba
TabMov:Select()

pcall(function() MacLib:LoadAutoLoadConfig() end)
