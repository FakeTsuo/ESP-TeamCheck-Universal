-- Prison Life Script Ultimate (Delta/KRNL/Synapse)
-- ESP modular, Auto Kill (FUNCIONAL), Auto Arrest, Auto Gun (com touch e remote), interface de botões

-- REMOVE INTERFACE ANTIGA
pcall(function() game:GetService("CoreGui")["PLifeUltimateGUI"]:Destroy() end)

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local RunService = game:GetService("RunService")
local Replicated = game:GetService("ReplicatedStorage")

-- INTERFACE
local gui = Instance.new("ScreenGui", game:GetService("CoreGui"))
gui.Name = "PLifeUltimateGUI"
local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0,230,0,390)
frame.Position = UDim2.new(0,20,0,180)
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
local btnNome      = makeBtn("ESP Nome: ON",10)
local btnCaixa     = makeBtn("ESP Caixa: ON",56)
local btnLinha     = makeBtn("ESP Linha: ON",102)
local btnTeam      = makeBtn("Team Check: ON",148)
local btnAutoKill  = makeBtn("Auto Kill: OFF",194)
local btnAutoArrest= makeBtn("Auto Arrest: OFF",240)
local btnAutoGun   = makeBtn("Auto Gun: OFF",286)

local status = Instance.new("TextLabel", frame)
status.Size = UDim2.new(0,210,0,26)
status.Position = UDim2.new(0,10,0,332)
status.BackgroundTransparency = 1
status.Text = "Status: Ativo"
status.TextColor3 = Color3.new(1,1,1)
status.Font = Enum.Font.SourceSans
status.TextSize = 16

-- ESTADOS
local showNome, showCaixa, showLinha, teamCheck = true, true, true, true
local autoKill, autoArrest, autoGun = false, false, false

-- UTILS
local function getTeamColor(plr)
    if plr.Team and plr.Team.TeamColor then
        local c = plr.Team.TeamColor.Color
        return Color3.new(c.R, c.G, c.B)
    end
    return Color3.new(1,0,0)
end

-- ESP (Drawing API)
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

-- AUTO KILL (FUNCIONAL)
local function getEquippedGun()
    local char = LocalPlayer.Character
    if not char then return nil end
    for _,v in pairs(char:GetChildren()) do
        if v:IsA("Tool") and (v.Name:find("Remington") or v.Name:find("AK") or v.Name:find("M9")) then
            return v
        end
    end
    -- Se não estiver na mão, tenta equipar da backpack
    for _,v in pairs(LocalPlayer.Backpack:GetChildren()) do
        if v:IsA("Tool") and (v.Name:find("Remington") or v.Name:find("AK") or v.Name:find("M9")) then
            LocalPlayer.Character.Humanoid:EquipTool(v)
            wait(0.3)
            return v
        end
    end
    return nil
end

local function killPlayer(target)
    local gun = getEquippedGun()
    if not gun then return end
    local char = target.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") or not char:FindFirstChild("Humanoid") or char.Humanoid.Health <= 0 then
        return
    end
    local part = char.HumanoidRootPart
    for i=1,5 do
        Replicated.Events.HitPart:FireServer(part, part.Position, part, math.random(3000,4000), gun)
    end
end

-- AUTO ARREST
function arrestPlayer(target)
    if LocalPlayer.Team.Name ~= "Guards" then return end
    local char = LocalPlayer.Character
    local h = char and char:FindFirstChild("HumanoidRootPart")
    local th = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
    if not h or not th then return end
    if (h.Position - th.Position).Magnitude > 12 then return end
    Replicated.Events.arrest:FireServer(target.Character.HumanoidRootPart)
end

-- AUTO GUN (MELHORADO: REMOTE + TOUCH)
local autoGunCooldown = false
function autoGun()
    if autoGunCooldown then return end
    autoGunCooldown = true
    local guns = {"Remington 870", "M9", "AK-47"}
    -- 1. Tenta pelo Remote (se aberto)
    local handler = Replicated:FindFirstChild("ItemHandler")
    if handler and handler:IsA("RemoteFunction") then
        for _,gun in ipairs(guns) do
            pcall(function()
                handler:InvokeServer(gun)
                wait(0.1)
            end)
        end
        wait(0.4)
    end
    -- 2. Tenta tocando fisicamente nas armas
    local gunParts = {
        Workspace.Prison_ITEMS.giver:FindFirstChild("Remington 870"),
        Workspace.Prison_ITEMS.giver:FindFirstChild("M9"),
        Workspace.Prison_ITEMS.giver:FindFirstChild("AK-47"),
    }
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        local oldPos = char.HumanoidRootPart.CFrame
        for _,part in ipairs(gunParts) do
            if part and part:FindFirstChild("ITEMPICKUP") then
                char.HumanoidRootPart.CFrame = CFrame.new(part.ITEMPICKUP.Position + Vector3.new(0,2,0))
                wait(0.25)
                firetouchinterest(char.HumanoidRootPart, part.ITEMPICKUP, 0)
                wait(0.15)
                firetouchinterest(char.HumanoidRootPart, part.ITEMPICKUP, 1)
                wait(0.15)
            end
        end
        char.HumanoidRootPart.CFrame = oldPos
    end
    wait(4) -- cooldown para não bugar
    autoGunCooldown = false
end

-- LOOP PRINCIPAL
RunService.RenderStepped:Connect(function()
    local ativo = showNome or showCaixa or showLinha
    status.Text = (ativo or autoKill or autoArrest or autoGun) and "Status: Ativo" or "Status: Desativado"
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
    -- ESP
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

    -- AUTO KILL
    if autoKill then
        local lpChar = LocalPlayer.Character
        if not lpChar or not lpChar:FindFirstChild("HumanoidRootPart") then return end
        for _,plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and plr.Character:FindFirstChild("Humanoid") and plr.Character.Humanoid.Health > 0 then
                if (not teamCheck or plr.Team ~= LocalPlayer.Team) then
                    local dist = (lpChar.HumanoidRootPart.Position - plr.Character.HumanoidRootPart.Position).Magnitude
                    if dist < 80 then
                        killPlayer(plr)
                    end
                end
            end
        end
    end

    -- AUTO ARREST
    if autoArrest and LocalPlayer.Team and LocalPlayer.Team.Name == "Guards" then
        for _,target in ipairs(Players:GetPlayers()) do
            if target ~= LocalPlayer and target.Team and target.Team.Name=="Criminals" and target.Character and target.Character:FindFirstChild("HumanoidRootPart") and target.Character:FindFirstChild("Humanoid") and target.Character.Humanoid.Health > 0 then
                arrestPlayer(target)
            end
        end
    end

    -- AUTO GUN
    if autoGun then
        autoGun()
    end
end)

-- BOTÕES
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
btnAutoKill.MouseButton1Click:Connect(function()
    autoKill = not autoKill
    btnAutoKill.Text = "Auto Kill: " .. (autoKill and "ON" or "OFF")
end)
btnAutoArrest.MouseButton1Click:Connect(function()
    autoArrest = not autoArrest
    btnAutoArrest.Text = "Auto Arrest: " .. (autoArrest and "ON" or "OFF")
end)
btnAutoGun.MouseButton1Click:Connect(function()
    autoGun = not autoGun
    btnAutoGun.Text = "Auto Gun: " .. (autoGun and "ON" or "OFF")
end)

-- Limpa ESP ao sair
Players.PlayerRemoving:Connect(function(plr)
    removeDrawingESP(plr)
end)
