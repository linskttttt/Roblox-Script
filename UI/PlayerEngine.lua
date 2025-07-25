local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local CollectionService = game:GetService("CollectionService")
local LocalPlayer = Players.LocalPlayer

local PlayerEngine = {}
PlayerEngine.__index = PlayerEngine

function PlayerEngine.new(opts)
    opts = opts or {}
    local self = setmetatable({}, PlayerEngine)
    self.UpdateRate = opts.updateRate or 0.1
    self.Debug = opts.debug or false
    self.leadTime = opts.leadTime or 0
    self.teamCheckFn = opts.teamCheckFn
    self.tagWhitelist = opts.tagWhitelist or {}
    self.tagBlacklist = opts.tagBlacklist or {}
    self.OnUpdate = Instance.new("BindableEvent")
    self.OnEnterScreen = Instance.new("BindableEvent")
    self.OnExitScreen = Instance.new("BindableEvent")
    self.OnVisible = Instance.new("BindableEvent")
    self.OnHidden = Instance.new("BindableEvent")
    self._players = {}
    self._cache = {}
    setmetatable(self._cache, { __mode = "k" })
    self._running = false
    self._acc = 0
    self._scratchAll = {}
    self._scratchFiltered = {}
    self._visParams = RaycastParams.new()
    self._visParams.FilterType = Enum.RaycastFilterType.Blacklist
    self._visParams.IgnoreWater = true
    self._visParams.FilterDescendantsInstances = {}
    Players.PlayerAdded:Connect(function(plr) self:_track(plr) end)
    Players.PlayerRemoving:Connect(function(plr) self:_untrack(plr) end)
    for _,plr in ipairs(Players:GetPlayers()) do self:_track(plr) end
    return self
end

function PlayerEngine:_track(plr)
    table.insert(self._players, plr)
    plr.CharacterAdded:Connect(function(char)
        local root = char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart
        if root then
            self._cache[plr] = {
                root = root,
                lastPos = root.Position,
                pos = root.Position,
                vel = Vector3.new(),
                screenPos = Vector2.new(),
                onScreen = false,
                visible = false,
                inFrustum = false,
                ally = (self.teamCheckFn and self.teamCheckFn(plr)) or (plr.Team == LocalPlayer.Team)
            }
        end
    end)
    plr.CharacterRemoving:Connect(function() self._cache[plr] = nil end)
end

function PlayerEngine:_untrack(plr)
    for i,p in ipairs(self._players) do
        if p == plr then table.remove(self._players, i); break end
    end
    self._cache[plr] = nil
end

function PlayerEngine:Start()
    if self._running then return end
    self._running = true
    self._connection = RunService.Heartbeat:Connect(function(dt)
        local ok, err = pcall(function() self:_update(dt) end)
        if not ok then warn("PlayerEngine error:", err) end
    end)
end

function PlayerEngine:Stop()
    if self._connection then
        self._connection:Disconnect()
        self._connection = nil
    end
    self._running = false
end

function PlayerEngine:_update(dt)
    self._acc = self._acc + dt
    if self._acc < self.UpdateRate then return end
    local tickDt = self._acc
    self._acc = 0
    local camCF = Camera.CFrame
    local camPos = camCF.Position
    local forward = camCF.LookVector
    self._visParams.FilterDescendantsInstances[1] = LocalPlayer.Character or {}
    local origins, directions, idxMap = {}, {}, {}
    local count = 0
    for _,plr in ipairs(self._players) do
        local d = self._cache[plr]
        local root = d and d.root
        if root and root.Parent then
            local newPos = root.Position
            d.vel = (newPos - d.lastPos) / tickDt
            d.lastPos = newPos
            d.pos = newPos
            d.predictedPos = newPos + d.vel * self.leadTime
            local sx, sy, ons = Camera:WorldToViewportPoint(d.predictedPos)
            d.screenPos = Vector2.new(sx, sy)
            d.onScreen = ons
            local cframe, size = root.Parent:GetBoundingBox()
            local half = size * 0.5
            d.inFrustum = false
            for xi = -1, 1, 2 do for yi = -1, 1, 2 do for zi = -1, 1, 2 do
                local corner = cframe.Position + Vector3.new(half.X*xi, half.Y*yi, half.Z*zi)
                local _,_,onc = Camera:WorldToViewportPoint(corner)
                if onc then d.inFrustum = true; break end
            end end end
            count = count + 1
            origins[count] = camPos
            directions[count] = d.predictedPos - camPos
            idxMap[count] = {plr = plr, d = d}
        else
            self._cache[plr] = nil
        end
    end
    if count > 0 then
        local results = Workspace:BatchRaycast(origins, directions, self._visParams)
        for i = 1, count do
            local entry = idxMap[i]
            entry.d.visible = not results[i]
            entry.d.ally = (self.teamCheckFn and self.teamCheckFn(entry.plr)) or (entry.plr.Team == LocalPlayer.Team)
        end
    end
    self.OnUpdate:Fire()
    for plr,d in pairs(self._cache) do
        local prevOn = d._prevOnScreen
        if d.onScreen and not prevOn then self.OnEnterScreen:Fire(plr, d) end
        if not d.onScreen and prevOn then self.OnExitScreen:Fire(plr, d) end
        local prevVis = d._prevVisible
        if d.visible and not prevVis then self.OnVisible:Fire(plr, d) end
        if not d.visible and prevVis then self.OnHidden:Fire(plr, d) end
        d._prevOnScreen = d.onScreen
        d._prevVisible = d.visible
    end
    if self.Debug then
        for plr,d in pairs(self._cache) do
            print(plr.Name, d.pos, d.vel, d.visible, d.onScreen)
        end
    end
end

function PlayerEngine:GetAll()
    for i = #self._scratchAll, 1, -1 do self._scratchAll[i] = nil end
    for plr,d in pairs(self._cache) do
        table.insert(self._scratchAll, {player = plr, data = d})
    end
    return self._scratchAll
end

function PlayerEngine:GetFiltered(opts)
    opts = opts or {}
    for i = #self._scratchFiltered, 1, -1 do self._scratchFiltered[i] = nil end
    local camCF = Camera.CFrame
    local camPos = camCF.Position
    local forward = camCF.LookVector
    local maxD2 = (opts.maxDist or math.huge) ^ 2
    local fovC = opts.fovCos or -1
    for plr,d in pairs(self._cache) do
        if plr ~= LocalPlayer then
            local v = d.pos - camPos
            if v:Dot(v) <= maxD2 and forward:Dot(v.Unit) >= fovC then
                if not opts.teamCheck or ((self.teamCheckFn and self.teamCheckFn(plr)) or d.ally) then
                    if not opts.wallCheck or d.visible then
                        if not opts.onScreen or d.onScreen then
                            if not opts.frustumCulling or d.inFrustum then
                                local pass = true
                                if #self.tagWhitelist > 0 then
                                    pass = false
                                    for _,tag in ipairs(self.tagWhitelist) do
                                        if CollectionService:HasTag(d.root.Parent, tag) then pass = true; break end
                                    end
                                end
                                for _,tag in ipairs(self.tagBlacklist) do
                                    if CollectionService:HasTag(d.root.Parent, tag) then pass = false; break end
                                end
                                if pass then
                                    table.insert(self._scratchFiltered, {player = plr, data = d})
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return self._scratchFiltered
end

function PlayerEngine:GetClosest(opts, chooseFn)
    local list = self:GetFiltered(opts)
    if #list > 0 then
        chooseFn(list)
        return list[1]
    end
end

function PlayerEngine:GetAllies()
    return self:GetFiltered({teamCheck = true})
end

function PlayerEngine:GetEnemies()
    return self:GetFiltered({teamCheck = false})
end

function PlayerEngine:GetByRole(roleName)
    local res = {}
    for _,entry in ipairs(self:GetAll()) do
        if entry.player.Team and entry.player.Team.Name == roleName then
            table.insert(res, entry)
        end
    end
    return res
end

return PlayerEngine
