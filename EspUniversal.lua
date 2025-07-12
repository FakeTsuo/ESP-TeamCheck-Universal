-- PRISON LIFE ULTIMATE (Delta) - ESP + Auto + Speed + Fly + Teleport
-- by Copilot

-- Remove interface antiga
pcall(function() game:GetService("CoreGui")["SimpleESP_GUI"]:Destroy() end)

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local Replicated = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")

-- Interface
local gui = Instance.new("ScreenGui", game:GetService("CoreGui"))
gui.Name = "SimpleESP_GUI"
local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0,260,0,430)
frame.Position = UDim2.new(0,20,0,150)
frame.BackgroundColor3 = Color3.fromRGB(40,40,40)
frame.Active = true
frame.Draggable = true

local function makeBtn(txt, y)
    local b = Instance.new("TextButton", frame)
    b.Size = UDim2.new(0,230,0,36)
    b.Position = UDim2.new(0,15,0,y)
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
local btnAutoKill = makeBtn("Auto Kill: OFF",194)
local btnAutoArrest = makeBtn("Auto Arrest: OFF", 240)
local btnAutoGun = makeBtn("Auto Gun: OFF", 286)
local btnSpeed = makeBtn("Speed: OFF", 332)
local btnFly = makeBtn("Fly: OFF", 378)
local btnTeleport = makeBtn("Teleport: Click to Mark", 424)

-- Estados
local showNome, showCaixa, showLinha, teamCheck = true, true, true, true
local autoKill, autoArrest, autoGun = false, false, false
local speedActive, flyActive = false, false
local walkSpeed = 35 -- ajuste aqui
local flySpeed = 3
local teleportPos = nil

-- Utils
local function getTeamColor(plr)
    if plr.Team and plr.Team.TeamColor then
        local c = plr.Team.TeamColor.Color
        return Color3.new(c.R, c.G, c.B)
    end
    return Color3.new(1,0,0)
end

-- ESP
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

-- Função de pegar armas automaticamente
function takeGuns()
    local guns = {"Remington 870","AK-47","M9"}
    for _,gun in ipairs(guns) do
        Replicated.ItemHandler:InvokeServer(gun)
    end
end

-- Função de auto kill
function killPlayer(target)
    local gun
    for _,i in ipairs(LocalPlayer.Backpack:GetChildren()) do
        if i.Name:find("Remington") or i.Name:find("AK") or i.Name:find("M9") then
            gun = i; break
        end
    end
    if not gun then return end
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    -- Equip
    local tool = char:FindFirstChild(gun.Name) or gun
    if tool.Parent ~= char then
        LocalPlayer.Character.Humanoid:EquipTool(tool)
    end
    -- Atira no HumanoidRootPart do alvo
    local hrp = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    for i=1,2 do
        Replicated.Events.HitPart:FireServer(hrp, hrp.Position, hrp, math.random(3000,4000), tool)
    end
end

-- Função de auto arrest
function arrestPlayer(target)
    if LocalPlayer.Team.Name ~= "Guards" then return end
    local char = LocalPlayer.Character
    local h = char and char:FindFirstChild("HumanoidRootPart")
    local th = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
    if not h or not th then return end
    if (h.Position - th.Position).Magnitude > 12 then return end
    Replicated.Events.arrest:FireServer(target.Character.HumanoidRootPart)
end

-- Speed
function setSpeed(state)
    speedActive = state
    if state then
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
            LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = walkSpeed
        end
    else
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
            LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = 16
        end
    end
end

-- Fly (simples, estilo noclip/fly, segura espaço para subir, shift para descer)
local flyConn
function setFly(state)
    flyActive = state
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    if state then
        local bp = Instance.new("BodyPosition", char.HumanoidRootPart)
        bp.Name = "DeltaFly"
        bp.MaxForce = Vector3.new(1e6,1e6,1e6)
        bp.D = 20
        bp.P = 10000
        flyConn = RunService.RenderStepped:Connect(function()
            local direction = Vector3.new()
            if UIS:IsKeyDown(Enum.KeyCode.W) then direction = direction + (Camera.CFrame.LookVector * flySpeed) end
            if UIS:IsKeyDown(Enum.KeyCode.S) then direction = direction - (Camera.CFrame.LookVector * flySpeed) end
            if UIS:IsKeyDown(Enum.KeyCode.A) then direction = direction - (Camera.CFrame.RightVector * flySpeed) end
            if UIS:IsKeyDown(Enum.KeyCode.D) then direction = direction + (Camera.CFrame.RightVector * flySpeed) end
            if UIS:IsKeyDown(Enum.KeyCode.Space) then direction = direction + Vector3.new(0,flySpeed,0) end
            if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then direction = direction - Vector3.new(0,flySpeed,0) end
            bp.Position = char.HumanoidRootPart.Position + direction
            char.HumanoidRootPart.Velocity = Vector3.new()
        end)
        char.Humanoid.PlatformStand = true
    else
        if char:FindFirstChild("DeltaFly") then char.DeltaFly:Destroy() end
        if flyConn then pcall(function() flyConn:Disconnect() end) flyConn = nil end
        if char:FindFirstChildOfClass("Humanoid") then char:FindFirstChildOfClass("Humanoid").PlatformStand = false end
    end
end

-- Teleport (marca posição ao clicar botão, teleporta ao clicar de novo)
function setTeleport()
    if not teleportPos then
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            teleportPos = LocalPlayer.Character.HumanoidRootPart.Position
            btnTeleport.Text = "Teleport: Clique para teleportar"
        end
    else
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(teleportPos)
        end
        teleportPos = nil
        btnTeleport.Text = "Teleport: Click to Mark"
    end
end

-- LOOP PRINCIPAL
RunService.RenderStepped:Connect(function()
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
        local show = char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0
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
        if not show or not isEnemy then
            objs.Box.Visible = false
            objs.Line.Visible = false
            objs.Text.Visible = false
        end
    end

    -- AUTO KILL
    if autoKill then
        for _,target in ipairs(Players:GetPlayers()) do
            if target ~= LocalPlayer and target.Character and target.Character:FindFirstChild("HumanoidRootPart") and target.Team ~= LocalPlayer.Team and target.Character:FindFirstChild("Humanoid") and target.Character.Humanoid.Health > 0 then
                local dist = (LocalPlayer.Character.HumanoidRootPart.Position - target.Character.HumanoidRootPart.Position).Magnitude
                if dist < 80 then
                    killPlayer(target)
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
        takeGuns()
    end

    -- SPEED
    if speedActive and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        if LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed ~= walkSpeed then
            LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = walkSpeed
        end
    elseif not speedActive and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        if LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed ~= 16 then
            LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = 16
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
btnSpeed.MouseButton1Click:Connect(function()
    speedActive = not speedActive
    btnSpeed.Text = "Speed: " .. (speedActive and "ON" or "OFF")
    setSpeed(speedActive)
end)
btnFly.MouseButton1Click:Connect(function()
    flyActive = not flyActive
    btnFly.Text = "Fly: " .. (flyActive and "ON" or "OFF")
    setFly(flyActive)
end)
btnTeleport.MouseButton1Click:Connect(function()
    setTeleport()
end)

Players.PlayerRemoving:Connect(function(plr)
    removeDrawingESP(plr)
end)

-- Hotkey para ativar/desativar fly (F)
UIS.InputBegan:Connect(function(input, gp)
    if input.KeyCode == Enum.KeyCode.F and not gp then
        flyActive = not flyActive
        btnFly.Text = "Fly: " .. (flyActive and "ON" or "OFF")
        setFly(flyActive)
    end
end)
