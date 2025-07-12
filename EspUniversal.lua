--// Simples ESP com Interface e Team Check para Prison Life
--// Autorizado apenas para testes

-- Interface básica
local ScreenGui = Instance.new("ScreenGui")
local Frame = Instance.new("Frame")
local ESPButton = Instance.new("TextButton")
local TeamCheckButton = Instance.new("TextButton")
local StatusLabel = Instance.new("TextLabel")

ScreenGui.Parent = game.CoreGui
ScreenGui.Name = "SimpleESP_GUI"
Frame.Parent = ScreenGui
Frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
Frame.Position = UDim2.new(0, 20, 0, 200)
Frame.Size = UDim2.new(0, 200, 0, 130)
Frame.Active = true
Frame.Draggable = true

ESPButton.Parent = Frame
ESPButton.Position = UDim2.new(0,10,0,10)
ESPButton.Size = UDim2.new(0,180,0,40)
ESPButton.Text = "Ativar ESP"
ESPButton.BackgroundColor3 = Color3.fromRGB(60,140,60)
ESPButton.TextColor3 = Color3.new(1,1,1)
ESPButton.Font = Enum.Font.SourceSansBold
ESPButton.TextSize = 20

TeamCheckButton.Parent = Frame
TeamCheckButton.Position = UDim2.new(0,10,0,60)
TeamCheckButton.Size = UDim2.new(0,180,0,30)
TeamCheckButton.Text = "Team Check: ON"
TeamCheckButton.BackgroundColor3 = Color3.fromRGB(60,60,120)
TeamCheckButton.TextColor3 = Color3.new(1,1,1)
TeamCheckButton.Font = Enum.Font.SourceSansBold
TeamCheckButton.TextSize = 16

StatusLabel.Parent = Frame
StatusLabel.Position = UDim2.new(0,10,0,100)
StatusLabel.Size = UDim2.new(0,180,0,20)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Status: ESP Desativado"
StatusLabel.TextColor3 = Color3.new(1,1,1)
StatusLabel.Font = Enum.Font.SourceSans
StatusLabel.TextSize = 14

local ESP_Active = false
local TeamCheck = true

-- Função para criar/destruir ESP
local ESP_Objects = {}

function ClearESP()
    for _, obj in pairs(ESP_Objects) do
        if obj and obj.Parent then
            obj:Destroy()
        end
    end
    ESP_Objects = {}
end

function CreateESP()
    ClearESP()
    for _, plr in pairs(game.Players:GetPlayers()) do
        if plr ~= game.Players.LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            if TeamCheck and (plr.Team == game.Players.LocalPlayer.Team) then
                continue
            end
            local Billboard = Instance.new("BillboardGui", game.CoreGui)
            Billboard.Adornee = plr.Character.HumanoidRootPart
            Billboard.Size = UDim2.new(0,100,0,30)
            Billboard.AlwaysOnTop = true
            Billboard.Name = "ESP_Billboard_"..plr.Name

            local NameLabel = Instance.new("TextLabel", Billboard)
            NameLabel.Size = UDim2.new(1,0,1,0)
            NameLabel.BackgroundTransparency = 1
            NameLabel.Text = plr.Name
            NameLabel.TextColor3 = Color3.new(1,0,0)
            NameLabel.TextStrokeTransparency = 0
            NameLabel.Font = Enum.Font.SourceSansBold
            NameLabel.TextSize = 16

            table.insert(ESP_Objects, Billboard)
        end
    end
end

function UpdateESP()
    ClearESP()
    if ESP_Active then
        CreateESP()
    end
end

-- Botão para ativar/desativar ESP
ESPButton.MouseButton1Click:Connect(function()
    ESP_Active = not ESP_Active
    ESPButton.Text = ESP_Active and "Desativar ESP" or "Ativar ESP"
    StatusLabel.Text = ESP_Active and "Status: ESP Ativado" or "Status: ESP Desativado"
    UpdateESP()
end)

-- Botão para ativar/desativar Team Check
TeamCheckButton.MouseButton1Click:Connect(function()
    TeamCheck = not TeamCheck
    TeamCheckButton.Text = "Team Check: "..(TeamCheck and "ON" or "OFF")
    UpdateESP()
end)

-- Atualiza ESP em mudanças de players/char
game.Players.PlayerAdded:Connect(UpdateESP)
game.Players.PlayerRemoving:Connect(UpdateESP)
game.Players.LocalPlayer:GetPropertyChangedSignal("Team"):Connect(UpdateESP)
game.Players.PlayerAdded:Connect(function(plr)
    plr:GetPropertyChangedSignal("Team"):Connect(UpdateESP)
end)
game:GetService("RunService").RenderStepped:Connect(function()
    if ESP_Active then
        UpdateESP()
    end
end)

-- Limpeza ao fechar
ScreenGui.Parent = game.CoreGui
