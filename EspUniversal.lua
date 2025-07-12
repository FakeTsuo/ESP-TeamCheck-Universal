--// ESP Simples com TeamCheck, Nome, Caixa e Tracer (não preenchida)
--// Interface simples já incluída

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

-- Funções auxiliares
local lp = game.Players.LocalPlayer
local camera = workspace.CurrentCamera

local function getTeamColor(plr)
    if plr.Team and plr.Team.TeamColor then
        local c = plr.Team.TeamColor.Color
        return Color3.new(c.R, c.G, c.B)
    end
    -- fallback: vermelho
    return Color3.new(1,0,0)
end

-- Desenho ESP
local Drawing = Drawing or getgenv().Drawing -- para exploits que suportam Drawing API

local ESP_Objects = {}

function ClearESP()
    for _, obj in pairs(ESP_Objects) do
        for _,v in pairs(obj) do
            if v and v.Remove then v:Remove()
            elseif v and v.Destroy then v:Destroy()
            end
        end
    end
    ESP_Objects = {}
end

function WorldToViewport(pos)
    local p, onscreen = camera:WorldToViewportPoint(pos)
    return Vector2.new(p.X, p.Y), onscreen, p
end

function CreateESP()
    ClearESP()
    for _, plr in pairs(game.Players:GetPlayers()) do
        if plr ~= lp and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and plr.Character:FindFirstChild("Humanoid") and plr.Character.Humanoid.Health > 0 then
            if TeamCheck and (plr.Team == lp.Team) then
                continue
            end
            local color = getTeamColor(plr)

            local box = Drawing.new("Square")
            box.Thickness = 2
            box.Filled = false
            box.Color = color
            box.Visible = false

            local tracer = Drawing.new("Line")
            tracer.Thickness = 2
            tracer.Color = color
            tracer.Visible = false

            local name = Drawing.new("Text")
            name.Text = plr.Name
            name.Size = 16
            name.Center = true
            name.Outline = true
            name.Color = color
            name.Visible = false

            ESP_Objects[plr] = {Box=box, Tracer=tracer, Name=name, Player=plr}
        end
    end
end

function UpdateESP()
    if not ESP_Active then
        ClearESP()
        return
    end

    for _, obj in pairs(ESP_Objects) do
        local plr = obj.Player
        local char = plr.Character
        if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
            if TeamCheck and (plr.Team == lp.Team) then
                obj.Box.Visible = false
                obj.Tracer.Visible = false
                obj.Name.Visible = false
                continue
            end
            local hrp = char.HumanoidRootPart
            local pos, onscreen, _ = WorldToViewport(hrp.Position)
            if onscreen then
                -- Caixa: calcular altura e largura baseado no HRP e a cabeça/pé
                local head = char:FindFirstChild("Head")
                local leg
                for _,p in pairs(char:GetChildren()) do
                    if p:IsA("BasePart") and (not leg or p.Position.Y < leg.Position.Y) then
                        leg = p
                    end
                end
                local headPos = head and head.Position or hrp.Position + Vector3.new(0,2,0)
                local legPos = leg and leg.Position or hrp.Position - Vector3.new(0,2,0)
                local head2D, onscreen1 = WorldToViewport(headPos)
                local leg2D, onscreen2 = WorldToViewport(legPos)
                if onscreen1 and onscreen2 then
                    local boxHeight = math.abs(head2D.Y - leg2D.Y)
                    local boxWidth = boxHeight/2
                    obj.Box.Position = Vector2.new(pos.X - boxWidth/2, head2D.Y)
                    obj.Box.Size = Vector2.new(boxWidth, boxHeight)
                    obj.Box.Color = getTeamColor(plr)
                    obj.Box.Visible = true
                else
                    obj.Box.Visible = false
                end

                -- Tracer: do centro da base da tela até HRP
                local screenSize = camera.ViewportSize
                obj.Tracer.From = Vector2.new(screenSize.X/2, screenSize.Y-10)
                obj.Tracer.To = pos
                obj.Tracer.Color = getTeamColor(plr)
                obj.Tracer.Visible = true

                -- Nome
                obj.Name.Position = Vector2.new(pos.X, pos.Y - 30)
                obj.Name.Color = getTeamColor(plr)
                obj.Name.Visible = true
            else
                obj.Box.Visible = false
                obj.Tracer.Visible = false
                obj.Name.Visible = false
            end
        else
            obj.Box.Visible = false
            obj.Tracer.Visible = false
            obj.Name.Visible = false
        end
    end
end

-- Botão para ativar/desativar ESP
ESPButton.MouseButton1Click:Connect(function()
    ESP_Active = not ESP_Active
    ESPButton.Text = ESP_Active and "Desativar ESP" or "Ativar ESP"
    StatusLabel.Text = ESP_Active and "Status: ESP Ativado" or "Status: ESP Desativado"
    if ESP_Active then
        CreateESP()
    else
        ClearESP()
    end
end)

-- Botão para ativar/desativar Team Check
TeamCheckButton.MouseButton1Click:Connect(function()
    TeamCheck = not TeamCheck
    TeamCheckButton.Text = "Team Check: "..(TeamCheck and "ON" or "OFF")
    if ESP_Active then
        CreateESP()
    end
end)

-- Atualiza ESP em mudanças de players/char
game.Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function()
        if ESP_Active then CreateESP() end
    end)
end)
game.Players.PlayerRemoving:Connect(function()
    if ESP_Active then CreateESP() end
end)
lp:GetPropertyChangedSignal("Team"):Connect(function()
    if ESP_Active then CreateESP() end
end)
game:GetService("RunService").RenderStepped:Connect(function()
    if ESP_Active then
        UpdateESP()
    end
end)
