-- PlayerEngine.lua
local Players     = game:GetService("Players")
local RunService  = game:GetService("RunService")
local Workspace   = game:GetService("Workspace")
local Camera      = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local PlayerEngine = {}
PlayerEngine._players   = {}       -- list of tracked players
PlayerEngine._cache     = {}       -- [player] = data
PlayerEngine.OnUpdate   = Instance.new("BindableEvent")
PlayerEngine.UpdateRate = 0.1      -- seconds

-- pre-allocate some scratch tables to reuse
local scratchFiltered = {}
local scratchAll      = {}

-- pre-build a RaycastParams for visibility checks
local visParams = RaycastParams.new()
visParams.FilterDescendantsInstances = { LocalPlayer.Character or {} }
visParams.FilterType = Enum.RaycastFilterType.Blacklist
visParams.IgnoreWater = true

-- ---- INTERNAL SETUP: track players & characters ----

-- when a new player joins, insert into our list
local function onPlayerAdded(plr)
    table.insert(PlayerEngine._players, plr)
    -- if their character already exists, hook it
    if plr.Character then
        PlayerEngine:_trackCharacter(plr, plr.Character)
    end
    plr.CharacterAdded:Connect(function(char)
        PlayerEngine:_trackCharacter(plr, char)
    end)
    plr.CharacterRemoving:Connect(function(char)
        PlayerEngine:_untrackCharacter(plr)
    end)
end

function PlayerEngine:_trackCharacter(plr, char)
    -- create or reset cache entry
    local data = PlayerEngine._cache[plr]
    if not data then
        data = {}
        PlayerEngine._cache[plr] = data
    end
    data.root        = char:WaitForChild("HumanoidRootPart", 1) or char.PrimaryPart
    data.lastPos     = data.root.Position
    data.pos         = data.lastPos
    data.vel         = Vector3.new()
    data.screenPos   = Vector2.new()
    data.onScreen    = false
    data.visible     = false
    data.ally        = (plr.Team == LocalPlayer.Team)
end

function PlayerEngine:_untrackCharacter(plr)
    PlayerEngine._cache[plr] = nil
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(function(plr)
    -- remove from list
    for i, v in ipairs(PlayerEngine._players) do
        if v == plr then
            table.remove(PlayerEngine._players, i)
            break
        end
    end
    PlayerEngine._cache[plr] = nil
end)

-- initialize existing players
for _, plr in ipairs(Players:GetPlayers()) do
    onPlayerAdded(plr)
end

-- ---- CORE UPDATER ----

do
    local accumulator = 0
    local camC0, camPos, forward
    RunService.Heartbeat:Connect(function(dt)
        accumulator = accumulator + dt
        if accumulator < PlayerEngine.UpdateRate then return end
        local tickDt = accumulator
        accumulator = 0

        camC0    = Camera.CFrame
        camPos   = camC0.Position
        forward  = camC0.LookVector

        -- update visibility filter list
        visParams.FilterDescendantsInstances[1] = LocalPlayer.Character or {}

        -- update each tracked player's data
        for _, plr in ipairs(PlayerEngine._players) do
            local data = PlayerEngine._cache[plr]
            local root = data and data.root
            if root and root.Parent then
                local newPos = root.Position
                data.vel     = (newPos - data.lastPos) / tickDt
                data.lastPos = newPos
                data.pos     = newPos

                -- screen projection (only if needed downstream)
                local sx, sy, onscr = Camera:WorldToViewportPoint(newPos)
                data.screenPos = Vector2.new(sx, sy)
                data.onScreen  = onscr

                -- visibility raycast
                local rayResult = Workspace:Raycast(
                    camPos,
                    (newPos - camPos),
                    visParams
                )
                data.visible = (rayResult == nil)

                data.ally = (plr.Team == LocalPlayer.Team)
            else
                PlayerEngine._cache[plr] = nil
            end
        end

        PlayerEngine.OnUpdate:Fire()
    end)
end

-- ---- PUBLIC API ----

-- get raw list (reused table!)
function PlayerEngine:GetAll()
    scratchAll = {}
    for plr, data in pairs(self._cache) do
        scratchAll[#scratchAll+1] = { player = plr, data = data }
    end
    return scratchAll
end

-- filter once into scratchFiltered, then return it
-- opts = { maxDist, fovCos, teamCheck, wallCheck, onScreen }
function PlayerEngine:GetFiltered(opts)
    scratchFiltered = {}
    local maxD2 = (opts.maxDist or 1e9)^2
    local fovC  = opts.fovCos or -1

    for plr, data in pairs(self._cache) do
        if plr ~= LocalPlayer then
            local toCam = data.pos - Camera.CFrame.Position
            local dist2 = toCam.Magnitude * toCam.Magnitude
            if dist2 <= maxD2
            and (forward:Dot(toCam.Unit) >= fovC)
            and (not opts.teamCheck   or not data.ally)
            and (not opts.wallCheck   or data.visible)
            and (not opts.onScreen    or data.onScreen)
            then
                scratchFiltered[#scratchFiltered+1] = { player=plr, data=data }
            end
        end
    end

    return scratchFiltered
end

-- pick the “best” by passing in a sorting function
-- chooseFn(list) sorts or rearranges the list in place
function PlayerEngine:GetClosest(opts, chooseFn)
    local list = self:GetFiltered(opts)
    if #list == 0 then
        return nil
    end
    chooseFn(list)
    return list[1]
end

return PlayerEngine
