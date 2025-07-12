--// ESP Simples com botões separados para Nome, Caixa, Linha (Tracer) e Team Check

-- Interface
local ScreenGui = Instance.new("ScreenGui")
local Frame = Instance.new("Frame")
local ESPNameBtn = Instance.new("TextButton")
local ESPBoxBtn = Instance.new("TextButton")
local ESPLineBtn = Instance.new("TextButton")
local TeamCheckBtn = Instance.new("TextButton")
local StatusLabel = Instance.new("TextLabel")

ScreenGui.Parent = game.CoreGui
ScreenGui.Name = "SimpleESP_GUI"
Frame.Parent = ScreenGui
Frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
Frame.Position = UDim2.new(0, 20, 0, 200)
Frame.Size = UDim2.new(0, 220, 0, 200)
Frame.Active = true
Frame.Draggable = true

ESPNameBtn.Parent = Frame
ESPNameBtn.Position = UDim2.new(0,10,0,10)
ESPNameBtn.Size = UDim2.new(0,200,0,30)
ESPNameBtn.Text = "ESP Nome: ON"
ESPNameBtn.BackgroundColor3 = Color3.fromRGB(60,100,180)
ESPNameBtn.TextColor3 = Color3.new(1,1,1)
ESPNameBtn.Font = Enum.Font.SourceSansBold
ESPNameBtn.TextSize = 16

ESPBoxBtn.Parent = Frame
ESPBoxBtn.Position = UDim2.new(0,10,0,50)
ESPBoxBtn.Size = UDim2.new(0,200,0,30)
ESPBoxBtn.Text = "ESP Caixa: ON"
ESPBoxBtn.BackgroundColor3 = Color3.fromRGB(60,180,60)
ESPBoxBtn.TextColor3 = Color3.new(1,1,1)
ESPBoxBtn.Font = Enum.Font.SourceSansBold
ESPBoxBtn.TextSize = 16

ESPLineBtn.Parent = Frame
ESPLineBtn.Position = UDim2.new(0,10,0,90)
ESPLineBtn.Size = UDim2.new(0,200,0,30)
ESPLineBtn.Text = "ESP Linha: ON"
ESPLineBtn.BackgroundColor3 = Color3.fromRGB(180,120,40)
ESPLineBtn.TextColor3 = Color3.new(1,1,1)
ESPLineBtn.Font = Enum.Font.SourceSansBold
ESPLineBtn.TextSize = 16

TeamCheckBtn.Parent = Frame
TeamCheckBtn.Position = UDim2.new(0,10,0,130)
TeamCheckBtn.Size = UDim2.new(0,200,0,30)
TeamCheckBtn.Text = "Team Check: ON"
TeamCheckBtn.BackgroundColor3 = Color3.fromRGB(120,60,120)
TeamCheckBtn.TextColor3 = Color3.new(1,1,1)
TeamCheckBtn.Font = Enum.Font.SourceSansBold
TeamCheckBtn.TextSize = 16

StatusLabel.Parent = Frame
StatusLabel.Position = UDim2.new(0,10,0,170)
StatusLabel.Size = UDim2.new(0,200,0,20)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "ESP Ativo"
StatusLabel.TextColor3 = Color3.new(1,1,1)
StatusLabel.Font = Enum.Font.SourceSans
StatusLabel.TextSize = 14

-- Estados dos ESPs
local ESP_Name = true
local ESP_Box = true
local ESP_Line = true
local TeamCheck = true

-- Variáveis úteis
local lp = game.Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Cor por time
local function getTeamColor(plr)
    if plr.Team and plr.Team.TeamColor then
        local c = plr.Team.TeamColor.Color
        return Color3.new(c.R, c.G, c.B)
    end
    return Color3.new(1,0,0)
end

-- Drawing API
local Drawing = Drawing or getgenv().Drawing

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
                local color = getTeamColor(plr)

                -- Caixa
                if ESP_Box and onscreen1 and onscreen2 then
                    local boxHeight = math.abs(head2D.Y - leg2D.Y)
                    local boxWidth = boxHeight/2
                    obj.Box.Position = Vector2.new(pos.X - boxWidth/2, head2D.Y)
                    obj.Box.Size = Vector2.new(boxWidth, boxHeight)
                    obj.Box.Color = color
                    obj.Box.Visible = true
                else
                    obj.Box.Visible = false
                end

                -- Linha (Tracer)
                if ESP_Line then
                    local screenSize = camera.ViewportSize
                    obj.Tracer.From = Vector2.new(screenSize.X/2, screenSize.Y-10)
                    obj.Tracer.To = pos
                    obj.Tracer.Color = color
                    obj.Tracer.Visible = true
                else
                    obj.Tracer.Visible = false
                end

                -- Nome
                if ESP_Name then
                    obj.Name.Position = Vector2.new(pos.X, pos.Y - 30)
                    obj.Name.Color = color
                    obj.Name.Visible = true
                else
                    obj.Name.Visible = false
                end
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

-- Botões
ESPNameBtn.MouseButton1Click:Connect(function()
    ESP_Name = not ESP_Name
    ESPNameBtn.Text = "ESP Nome: " .. (ESP_Name and "ON" or "OFF")
end)
ESPBoxBtn.MouseButton1Click:Connect(function()
    ESP_Box = not ESP_Box
    ESPBoxBtn.Text = "ESP Caixa: " .. (ESP_Box and "ON" or "OFF")
end)
ESPLineBtn.MouseButton1Click:Connect(function()
    ESP_Line = not ESP_Line
    ESPLineBtn.Text = "ESP Linha: " .. (ESP_Line and "ON" or "OFF")
end)
TeamCheckBtn.MouseButton1Click:Connect(function()
    TeamCheck = not TeamCheck
    TeamCheckBtn.Text = "Team Check: " .. (TeamCheck and "ON" or "OFF")
    CreateESP()
end)

-- Atualização automática
game.Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function()
        CreateESP()
    end)
end)
game.Players.PlayerRemoving:Connect(function()
    CreateESP()
end)
lp:GetPropertyChangedSignal("Team"):Connect(function()
    CreateESP()
end)

game:GetService("RunService").RenderStepped:Connect(function()
    if ESP_Name or ESP_Box or ESP_Line then
        if #table.getn(ESP_Objects) ~= #table.getn(game.Players:GetPlayers())-1 then
            CreateESP()
        end
        UpdateESP()
        StatusLabel.Text = "ESP Ativo"
    else
        ClearESP()
        StatusLabel.Text = "ESP Desativado"
    end
end)
