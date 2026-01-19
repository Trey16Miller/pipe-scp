net.Receive("PipeSCP_Notify", function()
    local msg = net.ReadString()
    if msg and msg ~= "" then
        chat.AddText(Color(180, 255, 180), "[Pipe SCP] ", color_white, msg)
        surface.PlaySound("buttons/button15.wav")
    end
end)

net.Receive("PipeSCP_Talk", function()
    local msg = net.ReadString()
    if msg and msg ~= "" then
        chat.AddText(Color(120, 255, 120), "[You] ", color_white, msg)
    end
end)

hook.Add("HUDPaint", "PipeSCP_HUD", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    if not ply:GetNWBool("PipeSCP_On", false) then return end

    local last = ply:GetNWFloat("PipeSCP_LastMetal", CurTime())
    local window = ply:GetNWFloat("PipeSCP_Window", 5)
    local left = math.max(0, window - (CurTime() - last))

    local w, h = 280, 58
    local x, y = 20, 20

    draw.RoundedBox(8, x, y, w, h, Color(0, 0, 0, 170))
    draw.SimpleText("PIPE SCP", "Trebuchet18", x + 10, y + 6, color_white)

    local txt = string.format("Press E on METAL in: %.1fs", left)
    local col = left <= 1.5 and Color(255, 160, 160) or Color(200, 200, 200)
    draw.SimpleText(txt, "Trebuchet18", x + 10, y + 30, col)
end)
