local assets = {

}

local prefabs = {
} 

local holder = nil 

local function onequip(inst, owner)
    
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
    holder = owner
end
 
local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")

    inst:DoTaskInTime(0, function(inst)
        if not inst:HasTag("NOCLICK") then
            owner:PushEvent("stopholding")
            inst:Remove()
        end
    end)
end
 
local function onthrown(inst)
    inst:AddTag("NOCLICK")
    inst.persists = false
    
    -- inst.AnimState:PlayAnimation("spin_loop", true)

    inst.entity:AddDynamicShadow()
    inst.DynamicShadow:SetSize(1, 1)
    
    inst.Physics:SetMass(1)
    inst.Physics:SetCapsule(0.2, 0.2)
    inst.Physics:SetFriction(0)
    inst.Physics:SetDamping(0)
    inst.Physics:SetCollisionGroup(COLLISION.CHARACTERS)
    inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith(COLLISION.WORLD)
    inst.Physics:CollidesWith(COLLISION.OBSTACLES)
    inst.Physics:CollidesWith(COLLISION.ITEMS)

    if holder then
        holder:PushEvent("playerthrown", {target = inst.components.complexprojectile.targetpos, item = inst})
    end
end

local function OnHit(inst)
    inst:DoTaskInTime(1, inst:Remove())
end

local function common_fn(bank, build, anim, tag, isinventoryitem)
    local inst = CreateEntity()
 
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()
 
    if isinventoryitem then
        MakeInventoryPhysics(inst)
    else
        inst.entity:AddPhysics()
        inst.Physics:SetMass(1)
        inst.Physics:SetCapsule(0.2, 0.2)
        inst.Physics:SetFriction(0)
        inst.Physics:SetDamping(0)
        inst.Physics:SetCollisionGroup(COLLISION.CHARACTERS)
        inst.Physics:ClearCollisionMask()
        inst.Physics:CollidesWith(COLLISION.WORLD)
    end
 
    if tag ~= nil then
        inst:AddTag(tag)
    end
 
    inst.entity:SetPristine()
 
    if not TheWorld.ismastersim then
        return inst
    end
 
    inst:AddComponent("locomotor")
 
	inst:AddComponent("complexprojectile")
 
    return inst
end

local function fn()
    local inst = common_fn("kidpotion", "kidpotion", "idle", "projectile", true)

    if not TheWorld.ismastersim then
        return inst
    end
 
    inst:AddComponent("inspectable")
 
    inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.cangoincontainer = false
	
	inst.components.complexprojectile:SetHorizontalSpeed(16)
	inst.components.complexprojectile:SetGravity(-50)
	inst.components.complexprojectile:SetLaunchOffset(Vector3(.25, 1, 0))
	inst.components.complexprojectile:SetOnLaunch(onthrown)
    inst.components.complexprojectile:SetOnHit(OnHit)
	
    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)
	
    return inst
end

STRINGS.NAMES.HELDPLAYER = "Held Player"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.HELDPLAYER = "Caught ya!"

return Prefab("heldplayer", fn, assets, prefabs)