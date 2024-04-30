-- Throwable Players
-- By Skylarr

PrefabFiles = {
    "handheldplayer"
}

-- hook into complexprojectile to get targetpos

AddComponentPostInit("complexprojectile", function(self)
    local launch_old = self.Launch

    self.Launch = function(self, targetPos, attacker, owningweapon)
        self.currentTargetPos = targetPos

        return launch_old(self, targetPos, attacker, owningweapon)
    end
end)

AddPlayerPostInit(function(inst)
    -- this is terrible, i know it's terrible, but it's also easy
    inst:AddComponent("complexprojectile")
    inst.components.complexprojectile:SetHorizontalSpeed(28)
    inst.components.complexprojectile:SetGravity(-40)
    inst.components.complexprojectile.usehigharc = false
    inst.components.complexprojectile:SetOnHit(function(inst)
        inst.components.pinnable:Unstick()
    end)

    inst:AddComponent("throwableplayer")
end)


-- Pickup Action

local PICKUP_PLAYER = AddAction("PICKUP_PLAYER", "Pick Up", function(act)
    if act.doer.components.throwableplayer and math.sqrt(act.doer:GetDistanceSqToInst(act.target) or 0) < 2 then
        act.doer.components.throwableplayer:Catch(act.target)
        act.doer.SoundEmitter:PlaySound("dontstarve/wilson/dig")
        return true
    end
end)

-- shouldn't override much
PICKUP_PLAYER.priority = 1.1
PICKUP_PLAYER.distance = 1

AddComponentAction("SCENE", "throwableplayer", function(inst, doer, actions, right)
    if inst:HasTag("player") 
    and not inst:HasTag("heldbyplayer") 
    and doer ~= inst then
        table.insert(actions, GLOBAL.ACTIONS.PICKUP_PLAYER)
        return true
    end
end)

AddStategraphActionHandler("wilson", GLOBAL.ActionHandler(GLOBAL.ACTIONS.PICKUP_PLAYER,
function(inst)
	return "dolongestaction"
end))


-- Throw Action

local THROW_PLAYER = AddAction("THROW_PLAYER", "Throw", function(act)
    if act.doer.components.throwableplayer then
        act.doer.components.throwableplayer:Throw(act.pos:GetPosition())
        return true
    end
end)

-- priority 10 to ensure it's always possible
THROW_PLAYER.priority = 10
THROW_PLAYER.distance = 30

AddComponentAction("POINT", "equippable", function(inst, doer, pos, actions, right, target)
    if inst:HasTag("handheldplayer") and doer:HasTag("holdingplayer") then
        table.insert(actions, GLOBAL.ACTIONS.THROW_PLAYER)
        return true
    end
end)

AddStategraphActionHandler("wilson", GLOBAL.ActionHandler(GLOBAL.ACTIONS.THROW_PLAYER,
function(inst)
	return "throw"
end))