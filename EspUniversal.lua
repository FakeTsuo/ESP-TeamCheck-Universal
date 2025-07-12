-- ESP para Prison Life (Delta, KRNL, Synapse) - Botões para Nome, Caixa, Linha e Team Check

-- Remove interface antiga
pcall(function() game:GetService("CoreGui")["SimpleESP_GUI"]:Destroy() end)

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")

-- Interface
local gui = Instance.new("ScreenGui", game:GetService("CoreGui"))
gui.Name = "SimpleESP_GUI"

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0,230,0,240)
frame.Position = UDim2.new(0,20,0,200)
frame.BackgroundColor3 = Color3.fromRGB(40,40,40)
frame.Active = true
frame.Draggable = true

local function makeBtn(txt, y)
    local b = Instance.new("TextButton")
    b.Parent = frame
    b.Size = UDim2.new(0,210,0,36)
    b.Position = UDim2.new(0,10,0,y)
    b.BackgroundColor3 = Color3.fromRGB(35,35,35)
    b.TextColor3 = Color3.new(1,1,1)
    b.Font = Enum.Font.SourceSansBold
    b.TextSize = 16
    b.Text = txt
    return b
end
local btnNome = makeBtn("ESP Nome: ON",10)
local btnCaixa = makeBtn("ESP Caixa: ON",56)
local btnLinha = makeBtn("ESP Linha: ON",102)
local btnTeam = makeBtn("Team Check: ON",148)

local status = Instance.new("TextLabel", frame)
status.Size = UDim2.new(0,210,0,26)
status.Position = UDim2.new(0,10,0,192)
status.BackgroundTransparency = 1
status.Text = "Status: Ativo"
status.TextColor3 = Color3.new(1,1,1)
status.Font = Enum.Font.SourceSans
status.TextSize = 16

-- Estados
local showNome, showCaixa, showLinha, teamCheck = true, true, true, true

-- Team color
local function getTeamColor(plr)
    if plr.Team and plr.Team.TeamColor then
        local c = plr.Team.TeamColor.Color
        return Color3.new(c.R, c.G, c.B)
    end
    return Color3.new(1,0,0)
end

-- Drawing para Delta (e Synapse/KRNL)
local ESPObjects = {}

function clearESP()
    for _,objs in pairs(ESPObjects) do
        for _,v in pairs(objs) do
            if typeof(v)=="table" and v.Remove then v:Remove()
            elseif typeof(v)=="table" and v.Destroy then v:Destroy()
        end end
    end
    ESPObjects = {}
end

function makeDrawingESP(plr)
    if ESPObjects[plr] then return end
    local box = Drawing.new("Square")
    box.Thickness = 2
    box.Filled = false
    box.Visible = false
    local line = Drawing.new("Line")
    line.Thickness = 2
    line.Visible = false
    local txt = Drawing.new("Text")
    txt.Size = 16
    txt.Center = true
    txt.Outline = true
    txt.Visible = false
    ESPObjects[plr] = {Box=box, Line=line, Text=txt, Player=plr}
end

function removeDrawingESP(plr)
    if ESPObjects[plr] then
        for _,v in pairs(ESPObjects[plr]) do
            if typeof(v)=="table" and v.Remove then v:Remove()
            elseif typeof(v)=="table" and v.Destroy then v:Destroy()
        end end
        ESPObjects[plr] = nil
    end
end

RunService.RenderStepped:Connect(function()
    local ativo = showNome or showCaixa or showLinha
    status.Text = ativo and "Status: Ativo" or "Status: Desativado"
    -- Remove quem saiu
    for plr,_ in pairs(ESPObjects) do
        if not Players:FindFirstChild(plr.Name) then
            removeDrawingESP(plr)
        end
    end
    -- Adiciona/inicializa para jogadores válidos
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            makeDrawingESP(plr)
        end
    end
    -- Atualiza cada
    for plr,objs in pairs(ESPObjects) do
        local char = plr.Character
        local show = ativo and char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0
        local isEnemy = not teamCheck or (plr.Team ~= LocalPlayer.Team)
        local color = getTeamColor(plr)
        -- Nome
        objs.Text.Visible = false
        if show and showNome and isEnemy then
            local pos,onscreen = Camera:WorldToViewportPoint(char.HumanoidRootPart.Position)
            if onscreen then
                objs.Text.Text = plr.Name
                objs.Text.Position = Vector2.new(pos.X, pos.Y-30)
                objs.Text.Color = color
                objs.Text.Visible = true
            end
        end
        -- Caixa
        objs.Box.Visible = false
        if show and showCaixa and isEnemy then
            local hrp = char.HumanoidRootPart
            local head = char:FindFirstChild("Head")
            local feetY = hrp.Position.Y
            for _,part in ipairs(char:GetChildren()) do
                if part:IsA("BasePart") and part.Position.Y < feetY then
                    feetY = part.Position.Y
                end
            end
            local headPos = head and head.Position or (hrp.Position + Vector3.new(0,2,0))
            local feetPos = Vector3.new(hrp.Position.X, feetY, hrp.Position.Z)
            local head2d,oh = Camera:WorldToViewportPoint(headPos)
            local feet2d,of = Camera:WorldToViewportPoint(feetPos)
            if oh and of then
                local h = math.abs(head2d.Y-feet2d.Y)
                local w = h/2
                objs.Box.Position = Vector2.new(head2d.X-w/2, head2d.Y)
                objs.Box.Size = Vector2.new(w,h)
                objs.Box.Color = color
                objs.Box.Visible = true
            end
        end
        -- Linha (Tracer)
        objs.Line.Visible = false
        if show and showLinha and isEnemy then
            local pos,onscreen = Camera:WorldToViewportPoint(char.HumanoidRootPart.Position)
            if onscreen then
                local scr = Camera.ViewportSize
                objs.Line.From = Vector2.new(scr.X/2, scr.Y-10)
                objs.Line.To = Vector2.new(pos.X,pos.Y)
                objs.Line.Color = color
                objs.Line.Visible = true
            end
        end
        if not show or not isEnemy or not ativo then
            objs.Box.Visible = false
            objs.Line.Visible = false
            objs.Text.Visible = false
        end
    end
end)

-- Botões
btnNome.MouseButton1Click:Connect(function()
    showNome = not showNome
    btnNome.Text = "ESP Nome: " .. (showNome and "ON" or "OFF")
end)
btnCaixa.MouseButton1Click:Connect(function()
    showCaixa = not showCaixa
    btnCaixa.Text = "ESP Caixa: " .. (showCaixa and "ON" or "OFF")
end)
btnLinha.MouseButton1Click:Connect(function()
    showLinha = not showLinha
    btnLinha.Text = "ESP Linha: " .. (showLinha and "ON" or "OFF")
end)
btnTeam.MouseButton1Click:Connect(function()
    teamCheck = not teamCheck
    btnTeam.Text = "Team Check: " .. (teamCheck and "ON" or "OFF")
end)

-- Limpa ESP ao sair
Players.PlayerRemoving:Connect(function(plr)
    removeDrawingESP(plr)
end)
