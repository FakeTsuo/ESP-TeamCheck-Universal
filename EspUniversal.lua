-- ESP Simples com Team Check para Roblox
-- Este script deve ser executado em LocalScript

-- Configurações
local boxWidth, boxHeight = 50, 80
local enemyColor = Color3.new(1, 0, 0) -- vermelho

-- Função para desenhar caixa
function drawBox(x, y, w, h, color)
    local box = Drawing.new("Square")
    box.Size = Vector2.new(w, h)
    box.Position = Vector2.new(x, y)
    box.Color = color
    box.Thickness = 2
    box.Filled = false
    box.Transparency = 1
    return box
end

-- Função principal do ESP
function drawESP()
    -- Limpar antigas caixas
    for _, drawing in pairs(game:GetService("CoreGui"):GetChildren()) do
        if drawing.Name == "ESPBox" then
            drawing:Destroy()
        end
    end

    local camera = workspace.CurrentCamera
    local localPlayer = game.Players.LocalPlayer
    local localTeam = localPlayer.Team

    for _, player in ipairs(game.Players:GetPlayers()) do
        if player ~= localPlayer and player.Team ~= localTeam and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local pos3d = player.Character.HumanoidRootPart.Position
            local pos2d, onScreen = camera:WorldToViewportPoint(pos3d)
            if onScreen then
                local box = drawBox(
                    pos2d.X - boxWidth/2,
                    pos2d.Y - boxHeight,
                    boxWidth,
                    boxHeight,
                    enemyColor
                )
                box.Name = "ESPBox"
                box.ZIndex = 2
                box.Parent = game:GetService("CoreGui")
            end
        end
    end
end

-- Atualizar ESP a cada frame
game:GetService("RunService").RenderStepped:Connect(function()
    drawESP()
end)
