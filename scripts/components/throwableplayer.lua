local ThrowablePlayer = Class(function(self, inst)
    self.inst = inst
    self.owner = nil

    -- config
    self.stuck_time = 4

    -- status
    self.isholding = false
    self.iscaught = false

    -- storage
    self.catcher = nil
    self.target = nil

    self.inst:AddTag("throwableplayer")
end)

-- ---------------- --
-- Target Functions --
-- ---------------- --

function ThrowablePlayer:GetCaught(catcher)
    if catcher == nil then return end

    self.iscaught = true

    self.catcher = catcher
    self.inst:AddTag("heldbyplayer")

    -- effects when caught
    if self.inst.AnimState then
        self.inst.AnimState:SetHaunted(true)
    end

    if self.inst.components.drownable ~= nil then
        self.inst.components.drownable.enabled=false
    end

    -- ewecus effect
    self.inst.components.pinnable:SetDefaultWearOffTime(self.stuck_time)
    self.inst.components.pinnable:Stick()
    

    local function OnUnpin(inst)
        if self.inst:HasTag("heldbyplayer") then
            -- Let the catcher component know we escaped
            self.catcher.components.throwableplayer:TargetEscaped()

            self:GetDropped()
            self.inst:RemoveEventCallback("onunpin", OnUnpin)
        end
    end

    self.inst:ListenForEvent("onunpin", OnUnpin)

    self.inst.Physics:ClearCollidesWith(COLLISION.CHARACTERS)
    self.inst.Physics:ClearCollidesWith(COLLISION.WORLD)
    self.inst.Physics:CollidesWith(COLLISION.GROUND)
    
    self.inst:StartUpdatingComponent(self)
end

function ThrowablePlayer:GetReleased()
    self.inst:StopUpdatingComponent(self)

    self.iscaught = false

    self.catcher = nil
    self.inst:RemoveTag("heldbyplayer")

    -- Revert effects
    if self.inst.AnimState then
        self.inst.AnimState:SetHaunted(false)
    end

    self.inst:DoTaskInTime(2, function(inst)
        if self.inst.components.drownable ~= nil then
            self.inst.components.drownable.enabled=true
        end
    end)

    -- we'll do the fx on landing instead
    -- self.inst.components.pinnable:Unstick()
    self.inst.components.pinnable:SetDefaultWearOffTime(TUNING.PINNABLE_WEAR_OFF_TIME)

    self.inst.Physics:CollidesWith(COLLISION.CHARACTERS)
    -- self.inst.Physics:CollidesWith(COLLISION.WORLD)


    local function OnUnpin(inst)
        self.inst.Physics:CollidesWith(COLLISION.WORLD)
        self.inst:RemoveEventCallback("onunpin", OnUnpin)
    end
    
    self.inst:DoTaskInTime(1, function()
        self.inst.Physics:CollidesWith(COLLISION.WORLD)
    end)

    self.inst:ListenForEvent("onunpin", OnUnpin)
end

function ThrowablePlayer:GetThrown(targetpos)
    self:GetReleased()
    self.inst.components.complexprojectile:Launch(targetpos)
end

function ThrowablePlayer:GetDropped()
    local pos = self.inst:GetPosition()
    local newpos = Vector3(pos.x, 0, pos.z)
    self:GetThrown(newpos)
end

function ThrowablePlayer:OnUpdate(dt)
    local x, y, z = self.catcher.Transform:GetWorldPosition()
    self.inst.Transform:SetPosition(x, y + 2, z)
end

-- ----------------- --
-- Catcher Functions --
-- ----------------- --

function ThrowablePlayer:Catch(target)
    if target == nil or not target:IsValid() then return end
    -- we might already have another player
    if self.target ~= nil then
        self:Release()
    end

    self.target = target
    self.inst:AddTag("holdingplayer")
    self.hand = SpawnPrefab("handheldplayer")
    self.inst.components.inventory:Equip(self.hand)

    self.target.components.throwableplayer:GetCaught(self.inst)
end

function ThrowablePlayer:Release()
    if self.target == nil or not self.target:IsValid() then return end

    self.target.components.throwableplayer:GetDropped()

    if self.hand then
        self.inst.components.inventory:RemoveItem(self.hand)
    end
    self.target = nil
    self.inst:RemoveTag("holdingplayer")
end

function ThrowablePlayer:Throw(targetpos)
    if self.target == nil or not self.target:IsValid() then return end

    self.target.components.throwableplayer:GetReleased()
    print(targetpos)
    self.target.components.complexprojectile:Launch(targetpos)

    if self.hand then
        self.inst.components.inventory:RemoveItem(self.hand)
    end
    self.target = nil
    self.inst:RemoveTag("holdingplayer")
end

function ThrowablePlayer:TargetEscaped()
    if self.hand then
        self.inst.components.inventory:RemoveItem(self.hand)
    end
    self.target = nil
    self.inst:RemoveTag("holdingplayer")
end

-- ---- --
-- Misc --
-- ---- --

function ThrowablePlayer:OnRemoveFromEntity()
    self.inst:RemoveTag("throwableplayer")
end

function ThrowablePlayer:GetDebugString()
	return "Nothing. For now."
end

return ThrowablePlayer
