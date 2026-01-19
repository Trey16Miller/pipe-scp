AddCSLuaFile("autorun/pipe_scp_cl.lua")

PipeSCP = PipeSCP or {}
PipeSCP.RefreshWindow = 5
PipeSCP.DamageTick = 0.5
PipeSCP.DamagePerTick = 6
PipeSCP.GraceAfterMiss = 0

util.AddNetworkString("PipeSCP_Notify")
util.AddNetworkString("PipeSCP_Talk")

local function Notify(ply, msg)
    net.Start("PipeSCP_Notify")
    net.WriteString(msg or "")
    net.Send(ply)
end

local function Talk(ply, msg)
    if not IsValid(ply) then return end
    msg = tostring(msg or "")
    if msg == "" then return end
    net.Start("PipeSCP_Talk")
    net.WriteString(msg)
    net.Send(ply)
end

local function SetActive(ply, on)
    ply:SetNWBool("PipeSCP_On", on and true or false)
    if on then
        ply:SetNWFloat("PipeSCP_LastMetal", CurTime())
        ply:SetNWFloat("PipeSCP_Window", PipeSCP.RefreshWindow)
    else
        ply:SetNWFloat("PipeSCP_Window", 0)
    end
end

local function IsMetal(ent)
    if not IsValid(ent) then return false end
    if ent:IsPlayer() or ent:IsNPC() then return false end

    local phys = ent:GetPhysicsObject()
    if IsValid(phys) then
        local mat = tostring(phys:GetMaterial() or ""):lower()
        if mat:find("metal", 1, true) then return true end
        if mat:find("chain", 1, true) then return true end
        if mat:find("iron", 1, true) then return true end
        if mat:find("steel", 1, true) then return true end
        if mat:find("pipe", 1, true) then return true end
        if mat:find("canister", 1, true) then return true end
    end

    local mdl = tostring(ent:GetModel() or ""):lower()
    if mdl:find("metal", 1, true) then return true end
    if mdl:find("pipe", 1, true) then return true end
    if mdl:find("canister", 1, true) then return true end

    return false
end

function PipeSCP.Start(ply)
    if not IsValid(ply) or not ply:IsPlayer() or not ply:Alive() then return end
    SetActive(ply, true)
    Notify(ply, "Pipe SCP active. Press E on metal or you will die.")
    Talk(ply, "It hurts... I need metal... I need to eat metal...")
end

local function Stop(ply)
    if not IsValid(ply) then return end
    SetActive(ply, false)
end

hook.Add("PlayerDeath", "PipeSCP_StopOnDeath", function(ply)
    Stop(ply)
end)

hook.Add("PlayerSpawn", "PipeSCP_StopOnSpawn", function(ply)
    timer.Simple(0, function()
        if IsValid(ply) then Stop(ply) end
    end)
end)

hook.Add("KeyPress", "PipeSCP_UseMetalRefresh", function(ply, key)
    if key ~= IN_USE then return end
    if not IsValid(ply) or not ply:IsPlayer() or not ply:Alive() then return end
    if not ply:GetNWBool("PipeSCP_On", false) then return end

    local tr = util.TraceLine({
        start = ply:GetShootPos(),
        endpos = ply:GetShootPos() + ply:GetAimVector() * 90,
        filter = ply,
        mask = MASK_SHOT
    })

    local ent = tr.Entity
    if not IsValid(ent) then return end
    if not IsMetal(ent) then return end

    ply:SetNWFloat("PipeSCP_LastMetal", CurTime())

    local r = math.random(1, 5)
    if r == 1 then Talk(ply, "Yes... more metal... I need more...") end
    if r == 2 then Talk(ply, "I can feel it... keep feeding it metal...") end
    if r == 3 then Talk(ply, "I hate this... but I need to eat metal...") end
    if r == 4 then Talk(ply, "Metal... now... please... metal...") end
    if r == 5 then Talk(ply, "That helped... for now...") end
end)

local nextTalk = {}

local function DoTalkLoop(ply, left, starving)
    local now = CurTime()
    nextTalk[ply] = nextTalk[ply] or 0
    if now < nextTalk[ply] then return end

    local delay = math.Rand(2.2, 4.0)

    if starving then
        delay = math.Rand(1.2, 2.0)
        local r = math.random(1, 6)
        if r == 1 then Talk(ply, "It burns... I NEED METAL RIGHT NOW!") end
        if r == 2 then Talk(ply, "I'm dying... feed me metal... FEED ME METAL!") end
        if r == 3 then Talk(ply, "My body hurts... I need to consume metal!") end
        if r == 4 then Talk(ply, "METAL... METAL... I NEED METAL!") end
        if r == 5 then Talk(ply, "Everything hurts... metal is the only fix!") end
        if r == 6 then Talk(ply, "No more time... I HAVE TO EAT METAL!") end
    else
        if left <= 1.5 then
            delay = math.Rand(1.3, 2.1)
            Talk(ply, "I'm running out... I need metal... hurry...")
        elseif left <= 3.0 then
            Talk(ply, "It's coming back... I need to eat metal...")
        else
            local r = math.random(1, 5)
            if r == 1 then Talk(ply, "I need to consume metal...") end
            if r == 2 then Talk(ply, "The pipe wants metal... it always wants metal...") end
            if r == 3 then Talk(ply, "I can't stop thinking about eating metal...") end
            if r == 4 then Talk(ply, "Find metal... touch metal... now...") end
            if r == 5 then Talk(ply, "Why does it hurt so much...") end
        end
    end

    nextTalk[ply] = now + delay
end

timer.Create("PipeSCP_DamageLoop", PipeSCP.DamageTick, 0, function()
    local now = CurTime()
    for _, ply in ipairs(player.GetAll()) do
        if not IsValid(ply) or not ply:Alive() then continue end
        if not ply:GetNWBool("PipeSCP_On", false) then continue end

        local last = ply:GetNWFloat("PipeSCP_LastMetal", now)
        local window = ply:GetNWFloat("PipeSCP_Window", PipeSCP.RefreshWindow)
        local dt = now - last
        local left = math.max(0, window - dt)
        local starving = dt > (window + PipeSCP.GraceAfterMiss)

        DoTalkLoop(ply, left, starving)

        if starving then
            ply:TakeDamage(PipeSCP.DamagePerTick, game.GetWorld(), game.GetWorld())
        end
    end
end)
