local assets=
{ 

}

local prefabs = 
{

}

local function OnEquip(inst, owner)
	local target = owner:HasTag("holdingplayer") and owner.components.throwableplayer.target and owner.components.throwableplayer.target.prefab
	local atlas, image = GetCharacterAvatarTextureLocation(target or "wilson")
	inst.components.inventoryitem.atlasname = atlas
	-- GetCharacterAvatarTextureLocation returns the image with the .tex, we need to remove it or the image will not load correctly.
	inst.components.inventoryitem.imagename = string.gsub(image, ".tex", "") 

	inst.components.named:SetName("Throwable " ..  (target and string.gsub(target, "^%l", string.upper) or "Friend"))
end
 
local function OnUnequip(inst, owner)
	inst:DoTaskInTime(0, function()
		if owner:HasTag("holdingplayer") then 
			owner.components.throwableplayer:Release()
		end
		inst:Remove()
	end)
end

local function fn() 
    local inst = CreateEntity()

	-- Client and Server

	-- Add internal components
	inst.entity:AddTransform() -- position
	inst.entity:AddAnimState() -- sprite and animation
	-- inst.entity:AddSoundEmitter() -- sounds
    inst.entity:AddNetwork() -- networked from server to client

	-- Setup AnimState
	inst.AnimState:SetBank("spear")
    inst.AnimState:SetBuild("swap_spear")
    inst.AnimState:PlayAnimation("idle")

	-- standardcomponents.lua functions
    MakeInventoryPhysics(inst) -- Sets physics properties of an item when it's outside the inventory.

	-- Component Tags
	inst:AddTag("inspectable")

	-- Custom Tags
	inst:AddTag("handheldplayer")

	-- Set pristine
	inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

	-- Server only
	
	-- Hauntable mode
	MakeHauntableLaunch(inst)
 
	-- Server components

	-- Makes the item, well, an item
	inst:AddComponent("inventoryitem")

	-- Allows inspecting of the item
	inst:AddComponent("inspectable")

	inst:AddComponent("named")
	
	inst:AddComponent("equippable")
	inst.components.equippable.equipslot = EQUIPSLOTS.HANDS
    inst.components.equippable:SetOnEquip( OnEquip )
    inst.components.equippable:SetOnUnequip( OnUnequip )

    return inst
end

return Prefab("handheldplayer", fn, assets, prefabs)