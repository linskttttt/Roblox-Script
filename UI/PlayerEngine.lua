-- PlayerEngine.lua
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace  = game:GetService("Workspace")
local Camera     = Workspace.CurrentCamera
local LocalPlayer= Players.LocalPlayer

local PlayerEngine = {}
PlayerEngine._players   = {}       -- tracked players list
PlayerEngine._cache     = {}       -- [player] = data
PlayerEngine.OnUpdate   = Instance.new("BindableEvent")
PlayerEngine.UpdateRate = 0.1      -- seconds between ticks

-- scratch tables to avoid GC
local scratchAll      = {}
local scratchFiltered = {}

-- prebuilt RaycastParams
local visParams = RaycastParams.new()
visParams.FilterType = Enum.RaycastFilterType.Blacklist
visParams.IgnoreWater = true

-- track new players/characters
local function track(plr)
    PlayerEngine._players[#PlayerEngine._players+1] = plr
    plr.CharacterAdded:Connect(function(char)
        local root = char:WaitForChild("HumanoidRootPart",1) or char.PrimaryPart
        PlayerEngine._cache[plr] = {
            root      = root,
            lastPos   = root.Position,
            pos       = root.Position,
            vel       = Vector3.new(),
            screenPos = Vector2.new(),
            onScreen  = false,
            visible   = false,
            ally      = (plr.Team == LocalPlayer.Team)
        }
    end)
    plr.CharacterRemoving:Connect(function() PlayerEngine._cache[plr] = nil end)
end

Players.PlayerAdded:Connect(track)
Players.PlayerRemoving:Connect(function(plr)
    for i,p in ipairs(PlayerEngine._players) do
        if p == plr then table.remove(PlayerEngine._players,i); break end
    end
    PlayerEngine._cache[plr] = nil
end)
for _,plr in ipairs(Players:GetPlayers()) do track(plr) end

-- main update loop
do
    local acc, camPos, forward = 0
    RunService.Heartbeat:Connect(function(dt)
        acc += dt
        if acc < PlayerEngine.UpdateRate then return end
        local tickDt = acc
        acc = 0

        camPos  = Camera.CFrame.Position
        forward = Camera.CFrame.LookVector
        visParams.FilterDescendantsInstances = { LocalPlayer.Character or {} }

        for _,plr in ipairs(PlayerEngine._players) do
            local d = PlayerEngine._cache[plr]
            local root = d and d.root
            if root and root.Parent then
                local newPos = root.Position
                d.vel       = (newPos - d.lastPos)/tickDt
                d.lastPos   = newPos
                d.pos       = newPos

                local sx,sy,ons = Camera:WorldToViewportPoint(newPos)
                d.screenPos = Vector2.new(sx,sy)
                d.onScreen  = ons

                local ray = Workspace:Raycast(camPos, newPos-camPos, visParams)
                d.visible   = not ray
                d.ally      = (plr.Team == LocalPlayer.Team)
            else
                PlayerEngine._cache[plr] = nil
            end
        end

        PlayerEngine.OnUpdate:Fire()
    end)
end

-- API
function PlayerEngine:GetAll()
    scratchAll = {}
    for plr,d in pairs(self._cache) do
        scratchAll[#scratchAll+1] = {player=plr,data=d}
    end
    return scratchAll
end

function PlayerEngine:GetFiltered(opts)
    scratchFiltered = {}
    local maxD2 = (opts.maxDist or 1e9)^2
    local fovC  = opts.fovCos or -1
    local camPos = Camera.CFrame.Position
    local forward= Camera.CFrame.LookVector

    for plr,d in pairs(self._cache) do
        if plr~=LocalPlayer then
            local v = d.pos - camPos
            local dist2 = v.Magnitude*v.Magnitude
            if dist2<=maxD2
            and forward:Dot(v.Unit)>=fovC
            and (not opts.teamCheck or not d.ally)
            and (not opts.wallCheck or d.visible)
            and (not opts.onScreen  or d.onScreen)
            then
                scratchFiltered[#scratchFiltered+1] = {player=plr,data=d}
            end
        end
    end

    return scratchFiltered
end

function PlayerEngine:GetClosest(opts, chooseFn)
    local list = self:GetFiltered(opts)
    if #list==0 then return end
    chooseFn(list)
    return list[1]
end

function PlayerEngine:Start() end  -- no-op; engine starts on require

return PlayerEngine
