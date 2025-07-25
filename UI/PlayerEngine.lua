-- PlayerEngine.lua (Fixed Version)
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local Workspace         = game:GetService("Workspace")
local Camera            = Workspace.CurrentCamera
local CollectionService = game:GetService("CollectionService")
local LocalPlayer       = Players.LocalPlayer

local PlayerEngine = {}
PlayerEngine.__index = PlayerEngine

function PlayerEngine.new(opts)
    opts = opts or {}
    local self = setmetatable({}, PlayerEngine)

    self.UpdateRate       = opts.updateRate   or 0.1
    self.Debug            = opts.debug        or false
    self.leadTime         = opts.leadTime     or 0
    self.teamCheckFn      = opts.teamCheckFn
    self.tagWhitelist     = opts.tagWhitelist or {}
    self.tagBlacklist     = opts.tagBlacklist or {}

    self.OnUpdate      = Instance.new("BindableEvent")
    self.OnEnterScreen = Instance.new("BindableEvent")
    self.OnExitScreen  = Instance.new("BindableEvent")
    self.OnVisible     = Instance.new("BindableEvent")
    self.OnHidden      = Instance.new("BindableEvent")

    self._players         = {}
    self._cache           = setmetatable({}, { __mode = "k" })
    self._running         = false
    self._acc             = 0
    self._scratchAll      = {}
    self._scratchFiltered = {}

    self._visParams                = RaycastParams.new()
    self._visParams.FilterType     = Enum.RaycastFilterType.Blacklist
    self._visParams.IgnoreWater    = true
    self._visParams.FilterDescendantsInstances = {}

    Players.PlayerAdded:Connect(function(plr) self:_track(plr) end)
    Players.PlayerRemoving:Connect(function(plr) self:_untrack(plr) end)
    for _,plr in ipairs(Players:GetPlayers()) do
        self:_track(plr)
    end

    return self
end

function PlayerEngine:_track(plr)
    if plr == LocalPlayer then return end -- Don't track local player
    
    table.insert(self._players, plr)
    
    local function onChar(char)
        if not char then return end
        
        -- Wait for character to fully load
        local root = char:WaitForChild("HumanoidRootPart", 10)
        if not root then 
            warn("PlayerEngine: No HumanoidRootPart found for", plr.Name)
            return 
        end
        
        -- Initialize player data
        self._cache[plr] = {
            root      = root,
            lastPos   = root.Position,
            pos       = root.Position,
            vel       = Vector3.new(0, 0, 0),
            screenPos = Vector2.new(0, 0),
            onScreen  = false,
            visible   = true,
            inFrustum = false,
            ally      = false,
            _prevOnScreen = false,
            _prevVisible = true,
        }
        
        -- Update ally status
        self:_updateAllyStatus(plr)
    end
    
    -- Connect character events
    plr.CharacterAdded:Connect(onChar)
    plr.CharacterRemoving:Connect(function() 
        self._cache[plr] = nil 
    end)
    
    -- Handle existing character
    if plr.Character then 
        onChar(plr.Character) 
    end
end

function PlayerEngine:_updateAllyStatus(plr)
    local data = self._cache[plr]
    if not data then return end
    
    if self.teamCheckFn then
        data.ally = self.teamCheckFn(plr)
    else
        data.ally = (plr.Team == LocalPlayer.Team)
    end
end

function PlayerEngine:_untrack(plr)
    for i = #self._players, 1, -1 do
        if self._players[i] == plr then
            table.remove(self._players, i)
            break
        end
    end
    self._cache[plr] = nil
end

function PlayerEngine:Start()
    if self._running then return end
    self._running = true
    self._connection = RunService.Heartbeat:Connect(function(dt)
        local success, err = pcall(function() 
            self:_update(dt) 
        end)
        if not success then 
            warn("PlayerEngine error:", err) 
        end
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

    -- Validate camera
    if not Camera or not Camera.CFrame then
        return
    end

    local camCF   = Camera.CFrame
    local camPos  = camCF.Position
    local forward = camCF.LookVector
    
    -- Update filter for visibility checks
    self._visParams.FilterDescendantsInstances = {LocalPlayer.Character or workspace}

    -- Update each tracked player
    for _, plr in ipairs(self._players) do
        local data = self._cache[plr]
        if data and data.root and data.root.Parent then
            -- Update position and velocity
            local newPos = data.root.Position
            if tickDt > 0 then
                data.vel = (newPos - data.lastPos) / tickDt
            end
            data.lastPos = newPos
            data.pos = newPos
            
            -- Calculate predicted position
            data.predictedPos = newPos + (data.vel * self.leadTime)
            
            -- Convert to screen space
            local screenPos, onScreen = Camera:WorldToViewportPoint(data.predictedPos)
            if screenPos then
                data.screenPos = Vector2.new(screenPos.X, screenPos.Y)
                data.onScreen = onScreen and screenPos.Z > 0
            else
                data.screenPos = Vector2.new(0, 0)
                data.onScreen = false
            end

            -- Update frustum culling
            data.inFrustum = data.onScreen
            if data.root.Parent then
                local success, cframe, size = pcall(function()
                    return data.root.Parent:GetBoundingBox()
                end)
                
                if success and cframe and size then
                    local halfSize = size * 0.5
                    data.inFrustum = false
                    
                    -- Check bounding box corners
                    for x = -1, 1, 2 do
                        for y = -1, 1, 2 do
                            for z = -1, 1, 2 do
                                local corner = cframe.Position + Vector3.new(
                                    halfSize.X * x,
                                    halfSize.Y * y, 
                                    halfSize.Z * z
                                )
                                local _, visible = Camera:WorldToViewportPoint(corner)
                                if visible then
                                    data.inFrustum = true
                                    break
                                end
                            end
                            if data.inFrustum then break end
                        end
                        if data.inFrustum then break end
                    end
                end
            end

            -- Line of sight check
            local direction = data.predictedPos - camPos
            local hit = Workspace:Raycast(camPos, direction, self._visParams)
            data.visible = (hit == nil)
            
            -- Update ally status
            self:_updateAllyStatus(plr)
            
        else
            -- Clean up invalid data
            self._cache[plr] = nil
        end
    end

    -- Fire update event
    self.OnUpdate:Fire()

    -- Fire fine-grained events
    for plr, data in pairs(self._cache) do
        if data._prevOnScreen ~= nil then
            if data.onScreen and not data._prevOnScreen then 
                self.OnEnterScreen:Fire(plr, data)
            elseif not data.onScreen and data._prevOnScreen then 
                self.OnExitScreen:Fire(plr, data) 
            end
        end

        if data._prevVisible ~= nil then
            if data.visible and not data._prevVisible then 
                self.OnVisible:Fire(plr, data)
            elseif not data.visible and data._prevVisible then 
                self.OnHidden:Fire(plr, data) 
            end
        end

        data._prevOnScreen = data.onScreen
        data._prevVisible = data.visible
    end

    -- Debug output
    if self.Debug then
        for plr, data in pairs(self._cache) do
            print(string.format("%s: pos=%s, vel=%s, visible=%s, onScreen=%s, screenPos=%s", 
                plr.Name, 
                tostring(data.pos), 
                tostring(data.vel), 
                tostring(data.visible), 
                tostring(data.onScreen),
                tostring(data.screenPos)
            ))
        end
    end
end

function PlayerEngine:GetAll()
    -- Clear scratch table
    for i = #self._scratchAll, 1, -1 do 
        self._scratchAll[i] = nil 
    end
    
    -- Fill with current data
    for plr, data in pairs(self._cache) do
        table.insert(self._scratchAll, {player = plr, data = data})
    end
    
    return self._scratchAll
end

function PlayerEngine:GetFiltered(opts)
    opts = opts or {}
    
    -- Clear scratch table
    for i = #self._scratchFiltered, 1, -1 do 
        self._scratchFiltered[i] = nil 
    end

    -- Validate camera
    if not Camera or not Camera.CFrame then
        return self._scratchFiltered
    end

    local camPos = Camera.CFrame.Position
    local forward = Camera.CFrame.LookVector
    local maxDist = opts.maxDist or math.huge
    local maxDistSq = maxDist * maxDist
    local fovCos = opts.fovCos or -1

    for plr, data in pairs(self._cache) do
        if plr ~= LocalPlayer and data and data.root and data.root.Parent then
            -- Distance check
            local toPlayer = data.pos - camPos
            local distanceSq = toPlayer:Dot(toPlayer)
            
            if distanceSq <= maxDistSq then
                -- FOV check
                if distanceSq > 0 then
                    local dot = forward:Dot(toPlayer.Unit)
                    if dot >= fovCos then
                        -- Team check
                        local passTeamCheck = true
                        if opts.teamCheck ~= nil then
                            if opts.teamCheck then
                                passTeamCheck = data.ally
                            else
                                passTeamCheck = not data.ally
                            end
                        end
                        
                        if passTeamCheck then
                            -- Wall check
                            if not opts.wallCheck or data.visible then
                                -- Screen check
                                if not opts.onScreen or data.onScreen then
                                    -- Frustum check
                                    if not opts.frustumCulling or data.inFrustum then
                                        -- Tag checks
                                        local passTagCheck = true
                                        
                                        if #self.tagWhitelist > 0 then
                                            passTagCheck = false
                                            for _, tag in ipairs(self.tagWhitelist) do
                                                if CollectionService:HasTag(data.root.Parent, tag) then
                                                    passTagCheck = true
                                                    break
                                                end
                                            end
                                        end
                                        
                                        if passTagCheck then
                                            for _, tag in ipairs(self.tagBlacklist) do
                                                if CollectionService:HasTag(data.root.Parent, tag) then
                                                    passTagCheck = false
                                                    break
                                                end
                                            end
                                        end
                                        
                                        if passTagCheck then
                                            table.insert(self._scratchFiltered, {
                                                player = plr, 
                                                data = data
                                            })
                                        end
                                    end
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
        if chooseFn then chooseFn(list) end
        return list[1] 
    end
    return nil
end

function PlayerEngine:GetAllies()   
    return self:GetFiltered({teamCheck = true}) 
end

function PlayerEngine:GetEnemies()  
    return self:GetFiltered({teamCheck = false}) 
end

function PlayerEngine:GetByRole(roleName)  
    local result = {}
    for _, entry in ipairs(self:GetAll()) do
        if entry.player.Team and entry.player.Team.Name == roleName then
            table.insert(result, entry)
        end
    end
    return result
end

return PlayerEngine
