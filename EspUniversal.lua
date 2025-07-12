-- ESP completo para Prison Life com botões separados e TeamCheck
-- Por: Copilot

--== INTERFACE ==--
local CoreGui = game:GetService("CoreGui")
if CoreGui:FindFirstChild("SimpleESP_GUI") then
    CoreGui.SimpleESP_GUI:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SimpleESP_GUI"
ScreenGui.Parent = CoreGui

local Frame = Instance.new("Frame")
Frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
Frame.Position = UDim2.new(0, 20, 0, 200)
Frame.Size = UDim2.new(0, 220, 0, 210)
Frame.Active = true
Frame.Draggable = true
Frame.Parent = ScreenGui

local function makeBtn(text, y)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0,200,0,32)
    btn.Position = UDim2.new(0,10,0,y)
    btn.BackgroundColor3 = Color3.fromRGB(40,40,40)
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 16
    btn.Text = text
    btn.Parent = Frame
    return btn
end

local ESPNameBtn = makeBtn("ESP Nome: ON",10)
local ESPBoxBtn  = makeBtn("ESP Caixa: ON",50)
local ESPLineBtn = makeBtn("ESP Linha: ON",90)
local TeamCheckBtn = makeBtn("Team Check: ON",130)

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Position = UDim2.new(0,10,0,175)
StatusLabel.Size = UDim2.new(0,200,0,30)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Status: Ativo"
StatusLabel.TextColor3 = Color3.new(1,1,1)
StatusLabel.Font = Enum.Font.SourceSans
StatusLabel.TextSize = 16
StatusLabel.Parent = Frame

--== ESTADOS ==--
local ESP_Name = true
local ESP_Box = true
local ESP_Line = true
local TeamCheck = true

--== UTILS ESP ==--
local lp = game.Players.LocalPlayer
local camera = workspace.CurrentCamera

local function getTeamColor(plr)
    if plr.Team and plr.Team.TeamColor then
        local c = plr.Team.TeamColor.Color
        return Color3.new(c.R, c.G, c.B)
    end
    return Color3.new(1,0,0)
end

local Drawing = Drawing or getgenv().Drawing
local ESP_Objects = {}

function ClearESP()
    for plr,obj in pairs(ESP_Objects) do
        for _,v in pairs(obj) do
            if typeof(v)=="Instance" and v.Destroy then v:Destroy()
            elseif typeof(v)=="table" and v.Remove then v:Remove()
            end
        end
        ESP_Objects[plr]=nil
    end
end

function WorldToViewport(pos)
    local p, on = camera:WorldToViewportPoint(pos)
    return Vector2.new(p.X, p.Y), on
end

function CreateESP()
    ClearESP()
    for _, plr in ipairs(game.Players:GetPlayers()) do
        if plr ~= lp then
            local obj = {}
            obj.Box = Drawing.new("Square")
            obj.Box.Thickness = 2
            obj.Box.Filled = false
            obj.Box.Visible = false

            obj.Tracer = Drawing.new("Line")
            obj.Tracer.Thickness = 2
            obj.Tracer.Visible = false

            obj.Name = Drawing.new("Text")
            obj.Name.Size = 16
            obj.Name.Center = true
            obj.Name.Outline = true
            obj.Name.Visible = false
            obj.Player = plr
            ESP_Objects[plr]=obj
        end
    end
end

function UpdateESP()
    for plr,obj in pairs(ESP_Objects) do
        local char = plr.Character
        if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
            if TeamCheck and (plr.Team == lp.Team) then
                obj.Box.Visible = false
                obj.Tracer.Visible = false
                obj.Name.Visible = false
                continue
            end
            local hrp = char.HumanoidRootPart
            local pos, on = WorldToViewport(hrp.Position)
            if on then
                local color = getTeamColor(plr)
                -- Head/Feet
                local head = char:FindFirstChild("Head")
                local lowest = hrp.Position
                for _,p in pairs(char:GetChildren()) do
                    if p:IsA("BasePart") and p.Position.Y < lowest.Y then
                        lowest = p.Position
                    end
                end
                local headPos = head and head.Position or (hrp.Position + Vector3.new(0,2,0))
                local footPos = lowest
                local head2D,on1 = WorldToViewport(headPos)
                local foot2D,on2 = WorldToViewport(footPos)
                -- Caixa
                if ESP_Box and on1 and on2 then
                    local h = math.abs(head2D.Y-foot2D.Y)
                    local w = h/2
                    obj.Box.Position = Vector2.new(pos.X-w/2,head2D.Y)
                    obj.Box.Size = Vector2.new(w,h)
                    obj.Box.Color = color
                    obj.Box.Visible = true
                else
                    obj.Box.Visible = false
                end
                -- Linha (tracer)
                if ESP_Line then
                    local scr = camera.ViewportSize
                    obj.Tracer.From = Vector2.new(scr.X/2, scr.Y-10)
                    obj.Tracer.To = pos
                    obj.Tracer.Color = color
                    obj.Tracer.Visible = true
                else
                    obj.Tracer.Visible = false
                end
                -- Nome
                if ESP_Name then
                    obj.Name.Text = plr.Name
                    obj.Name.Position = Vector2.new(pos.X, pos.Y-30)
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

--== BOTÕES ==--
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
end)

--== AUTO ATUALIZAÇÃO ==--
local function refresh()
    CreateESP()
end
game.Players.PlayerAdded:Connect(refresh)
game.Players.PlayerRemoving:Connect(refresh)
for _,plr in ipairs(game.Players:GetPlayers()) do
    plr.CharacterAdded:Connect(refresh)
    plr:GetPropertyChangedSignal("Team"):Connect(refresh)
end
lp:GetPropertyChangedSignal("Team"):Connect(refresh)

--== LOOP PRINCIPAL ==--
CreateESP()
game:GetService("RunService").RenderStepped:Connect(function()
    UpdateESP()
    local ativo = ESP_Name or ESP_Box or ESP_Line
    StatusLabel.Text = ativo and "Status: Ativo" or "Status: Desativado"
    if not ativo then ClearESP() end
end)
