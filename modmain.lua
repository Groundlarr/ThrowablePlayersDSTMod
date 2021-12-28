-- Throwable Players
-- By Skylarr

PrefabFiles = {

	"heldplayer",

}

-- playernetrecipe = AddRecipe("playernet",
-- 	{
-- 		GLOBAL.Ingredient("twigs", 3),
-- 		GLOBAL.Ingredient("silk", 5),
-- 	},
-- 	GLOBAL.RECIPETABS.TOOLS, -- crafting tab
-- 	GLOBAL.TECH.SCIENCE_ONE, -- crafting level
-- 	nil, -- placer
-- 	nil, -- min_spacing
-- 	nil, -- nounlock
-- 	nil, -- numtogive
-- 	nil, -- builder_tag
-- 	"images/inventoryimages/hatbrella.xml", -- atlas
-- 	"hatbrella.tex" -- image
-- )

AddPlayerPostInit(function(inst)
    local function OnWorked(inst, worker)
        -- inst.entity:SetParent(worker.playernetstorage.entity)
        -- inst.parenttask = inst:DoPeriodicTask(0, function(inst)
        --     inst.Physics:Teleport(worker.Transform:GetWorldPosition())
        --     worker.Physics:ClearCollidesWith(GLOBAL.COLLISION.CHARACTERS)
        -- end)

        if inst == worker then
            inst.components.workable:SetWorkLeft(1) 
            return
        end

        if worker:HasTag("player") then

            worker.components.inventory:Equip(GLOBAL.SpawnPrefab("heldplayer"))

            worker:PushEvent("holdingplayer", {heldplayer = inst})

            -- inst.Physics:ClearCollidesWith(GLOBAL.COLLISION.CHARACTERS)
            -- worker.holdtask = worker:DoPeriodicTask(0, inst.Transform:SetPosition(worker.Transform:GetWorldPosition()))
        end
    end

    local function OnThrowPlayer(inst, data)
        if inst.heldplayer and inst.heldplayer.components.complexprojectile and inst.heldplayer.components.workable and not inst.heldplayer:IsInLimbo() and inst.heldplayer:HasTag("heldbyplayer") then
            local throwable = inst.heldplayer

            if inst.holdtask ~= nil then
                inst.holdtask:Cancel()
                inst.holdtask = nil
            end
            throwable.components.complexprojectile:Launch(data.target, inst)
            throwable:DoTaskInTime(1, function(throwable)
                throwable:RemoveTag("heldbyplayer")
                throwable.Physics:CollidesWith(GLOBAL.COLLISION.CHARACTERS)
                throwable.Physics:CollidesWith(GLOBAL.COLLISION.WORLD)
                -- throwable.Physics:ClearCollidesWith(GLOBAL.COLLISION.GROUND)
                throwable.components.workable:SetWorkLeft(1) 

                if inst.heldplayer.components.drownable ~= nil then
                    inst.heldplayer.components.drownable.enabled=true
                end
            end)
            
        end
    end

    local function StopHoldingPlayer(inst)
        
        if inst.holdtask ~= nil then
            inst.holdtask:Cancel()
            inst.holdtask = nil
        end

        if inst.heldplayer:IsValid() then
            inst.heldplayer.Physics:CollidesWith(GLOBAL.COLLISION.CHARACTERS)
            inst.heldplayer.Physics:CollidesWith(GLOBAL.COLLISION.WORLD)
            inst.heldplayer.components.workable:SetWorkLeft(1) 

            if inst.heldplayer.components.drownable ~= nil then
                inst.heldplayer.components.drownable.enabled=true
            end

            inst.heldplayer:RemoveTag("heldbyplayer")
        end
    end

    local function OnPlayerHeld(inst, data)
        inst.heldplayer = data.heldplayer

        if inst.heldplayer then
            inst:ListenForEvent("playerthrown", OnThrowPlayer)

            inst.heldplayer:AddTag("heldbyplayer")

            if inst.heldplayer.components.drownable ~= nil then
                inst.heldplayer.components.drownable.enabled=false
            end

            inst.heldplayer.Physics:ClearCollidesWith(GLOBAL.COLLISION.CHARACTERS)
            inst.heldplayer.Physics:ClearCollidesWith(GLOBAL.COLLISION.WORLD)
            inst.heldplayer.Physics:CollidesWith(GLOBAL.COLLISION.GROUND)

            if inst.holdtask ~= nil then
                inst.holdtask:Cancel()
                inst.holdtask = nil
            end

            inst.heldplayer:ListenForEvent("locmote", function(inst)
                inst:DoTaskInTime(1, inst:PushEvent("stopholding"))
            end)
            
            inst.holdtask = inst:DoPeriodicTask(0, function(inst)
                if inst.heldplayer:IsValid() and not inst.heldplayer:IsInLimbo() and not inst.heldplayer:HasTag("playerghost") then
                    local x, y, z = inst.Transform:GetWorldPosition()
                    inst.heldplayer.Transform:SetPosition(x, y + 1, z)
                else
                    inst:PushEvent("stopholding")
                end
            end)
        end
    end

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(GLOBAL.ACTIONS.NET)
    inst.components.workable:SetWorkLeft(1) 
    inst.components.workable:SetOnFinishCallback(OnWorked)

    inst:AddComponent("complexprojectile")
    inst.components.complexprojectile:SetHorizontalSpeed(18)
    inst.components.complexprojectile:SetGravity(-45)
    -- inst.components.complexprojectile:SetLaunchOffset(GLOBAL.Vector3(.25, 1, 0))

    inst:ListenForEvent("holdingplayer", OnPlayerHeld)

    inst:ListenForEvent("stopholding", StopHoldingPlayer)
end)



AddComponentPostInit("complexprojectile", function(self)
    self.targetpos = nil

    function self:Launch(targetPos, attacker, owningweapon)
        self.targetpos = targetPos
        local pos = self.inst:GetPosition()
        self.owningweapon = owningweapon or self
        self.attacker = attacker
    
        self.inst:ForceFacePoint(targetPos:Get())
    
        local offset = self.launchoffset
        if attacker ~= nil and offset ~= nil then
            local facing_angle = self.inst.Transform:GetRotation() * GLOBAL.DEGREES
            pos.x = pos.x + offset.x * math.cos(facing_angle)
            pos.y = pos.y + offset.y
            pos.z = pos.z - offset.x * math.sin(facing_angle)
            -- print("facing", facing_angle)
            -- print("offset", offset)
            if self.inst.Physics ~= nil then
                self.inst.Physics:Teleport(pos:Get())
            else
                self.inst.Transform:SetPosition(pos:Get())
            end
        end
    
        -- use targetoffset height, otherwise hit when you hit the ground
        targetPos.y = self.targetoffset ~= nil and self.targetoffset.y or 0
    
        self:CalculateTrajectory(pos, targetPos, self.horizontalSpeed)
    
        -- if the attacker is standing on a moving platform, then inherit it's velocity too
        local attacker_platform = attacker ~= nil and attacker:GetCurrentPlatform() or nil
        if attacker_platform ~= nil then
            local vx, vy, vz = attacker_platform.Physics:GetVelocity()
            self.velocity.x = self.velocity.x + vx
            self.velocity.z = self.velocity.z + vz
        end
    
        if self.onlaunchfn ~= nil then
            self.onlaunchfn(self.inst)
        end
    
        self.inst:AddTag("activeprojectile")
        self.inst:StartUpdatingComponent(self)
    end

end)