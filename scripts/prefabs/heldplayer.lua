local assets = {

}

local function onequip(inst, owner)
    
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
end
 
local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")

    -- if we get dropped as an "item" rather than a projectile, get removed
    inst:DoTaskInTime(0, function(inst)
        if not inst:HasTag("NOCLICK") then
            inst:DoTaskInTime(0, inst:Remove())
        end
    end)
end
 
local function OnThrown(inst)
    inst:AddTag("NOCLICK")
    inst.persists = false
    
    inst.Physics:SetMass(1)
    inst.Physics:SetCapsule(0.2, 0.2)
    inst.Physics:SetFriction(0)
    inst.Physics:SetDamping(0)
    inst.Physics:SetCollisionGroup(COLLISION.CHARACTERS)
    inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith(COLLISION.WORLD)
    inst.Physics:CollidesWith(COLLISION.OBSTACLES)
    inst.Physics:CollidesWith(COLLISION.ITEMS)

    local owner = inst.components.inventoryitem:GetGrandOwner()
    if owner then
        owner:PushEvent("playerthrown", {target = inst.components.complexprojectile.targetpos, item = inst})
    end
end

local function OnHit(inst)
    inst:DoTaskInTime(0, inst:Remove())
end

local function fn()
    local inst = CreateEntity()
 
    inst.entity:AddTransform()
    inst.entity:AddNetwork()
 
    MakeInventoryPhysics(inst)
 
    inst.entity:SetPristine()
 
    if not TheWorld.ismastersim then
        return inst
    end
 
    inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.cangoincontainer = false
	
    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

	inst:AddComponent("complexprojectile")
    inst.components.complexprojectile:SetHorizontalSpeed(16)
	inst.components.complexprojectile:SetGravity(-50)
	inst.components.complexprojectile:SetLaunchOffset(Vector3(.25, 1, 0))
	inst.components.complexprojectile:SetOnLaunch(OnThrown)
    inst.components.complexprojectile:SetOnHit(OnHit)
	
    return inst
end

return Prefab("heldplayer", fn)