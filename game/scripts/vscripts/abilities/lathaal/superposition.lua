LinkLuaModifier("modifier_superposition","scripts/vscripts/abilities/lathaal/superposition.lua",LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_superposition_tracker","scripts/vscripts/abilities/lathaal/superposition.lua",LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_superposition_illusion","scripts/vscripts/abilities/lathaal/modifiers/modifier_superposition_illusion.lua",LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_superposition_trail","scripts/vscripts/abilities/lathaal/superposition.lua",LUA_MODIFIER_MOTION_NONE)

lathaal_superposition = class({})

function lathaal_superposition:GetIntrinsicModifierName()
	return "modifier_superposition_tracker"
end

function lathaal_superposition:OnUpgrade()
	if not IsServer() then return end

	local modifier = self:GetCaster():FindModifierByName("modifier_superposition")
	if not modifier then 
		-- self:UseResources(false, false, true)
		-- local duration = self:GetCooldownTimeRemaining()
		-- self:EndCooldown()
		modifier = self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_superposition", {Duration = -1})
		modifier:SetStackCount(self:GetSpecialValueFor("charges"))
	end
end


function lathaal_superposition:OnSpellStart()
	if IsServer() then
		local caster = self:GetCaster()
		if not caster:IsRealHero() then return end

		caster:SetCursorTargetingNothing(true)
		caster:SetCursorCastTarget(nil)

		local point = caster:GetCursorPosition()
		local origin = caster:GetAbsOrigin()

		if self.sIllusion == nil or self.sIllusion:IsNull() then
			self:CreateSuperpositionIllusion()
		end

		self:ReleaseSuperpositionIllusion(keys)

		-- Trail effect visibly to your team
		local trail = caster:AddNewModifier(caster, self, "modifier_superposition_trail", {Duration = 0.5})
		local particle = ParticleManager:CreateParticleForTeam("particles/hero/lathaal/super_position_base.vpcf", PATTACH_POINT_FOLLOW, caster, caster:GetTeamNumber())
		trail:AddParticle(particle, false, false, 1, true, false)

		if point then 
			local distance = (point - origin):Length2D()
			--castrange calc needed
			distance = math.min(distance, self:GetCastRange(point, caster))
			local blinkPoint = origin + (point - origin):Normalized() * distance

			ProjectileManager:ProjectileDodge(caster)
			caster:SetAbsOrigin(blinkPoint)
		end

		-- Sound audible to your team
		EmitSoundOnLocationForAllies(caster:GetAbsOrigin(), "Hero_Lathaal.Superposition", caster)

		local modifier = caster:FindModifierByName("modifier_superposition")
		if modifier and not self:IsCooldownReady() then

			modifier:DecrementStackCount()
			-- modifier.cooldown = self:GetCooldownTimeRemaining()

			if modifier:GetStackCount() <= 0 then
				local cooldown = modifier:GetRemainingTime()
				self:EndCooldown()

				if cooldown > 0 then
					self:StartCooldown(cooldown)
				end
			else
				self:EndCooldown()
			end

			if modifier:GetDuration() < 0 then
				local charges = modifier:GetStackCount()
				modifier:Destroy()
				local duration = self:GetCooldownTimeRemaining()
				self:EndCooldown()
				local newModifier = self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_superposition", {Duration = duration})
				newModifier:SetStackCount(charges)
			end
		end
	end
end

function lathaal_superposition:CreateSuperpositionIllusion()
	if not IsServer() then return end

	self.sIllusion = nil

	local caster = self:GetCaster()
	local illusion = CreateUnitByName(caster:GetUnitName(), caster:GetAbsOrigin(), false, caster, caster:GetPlayerOwner(), caster:GetTeam())
	illusion:SetPlayerID(caster:GetPlayerID())
    illusion:AddNewModifier(caster,self,"modifier_superposition_illusion",{})
    -- illusion:SetOwner(caster)
    -- illusion:AddNewModifier(caster,self,"modifier_illusion", {incoming_damage = 100, outgoing_damage = 50})

 	-- illusion:SetPlayerID(caster:GetPlayerID())
    -- illusion:SetControllableByPlayer(caster:GetPlayerID(), true)
    illusion:SetAbsOrigin(caster:GetAbsOrigin())
	illusion:SetForwardVector(caster:GetForwardVector())

    -- Level Up the unit to the casters level
    local casterLevel = caster:GetLevel()
    for i = 0,casterLevel-1 do
        illusion:HeroLevelUp(false)
    end

    

    --if caster:HasTalent("special_bonus_unique_lathaal_3") then
    	--caster:AddNewModifier(caster, self, "modifier_invisible", {Duration = caster:GetTalentValue("special_bonus_unique_lathaal_3")})
    --end

    Timers:CreateTimer(0.1, function() FindClearSpaceForUnit(illusion, illusion:GetAbsOrigin(), true) end)


    illusion:MakeIllusion()
    illusion:AddNoDraw()

    self.sIllusion = illusion

end

function lathaal_superposition:UpdateSuperpositionStats()
	if not IsServer() then return end

	local caster = self:GetCaster()
	local illusion = self.sIllusion

end

function lathaal_superposition:ReleaseSuperpositionIllusion(keys)
	local caster = self:GetCaster()
	local illusion = self.sIllusion

	caster:AddNewModifier(caster,self,"modifier_phased",{duration = 0.03})

	--HeroSelection:CustomHeroAttachments(illusion)
	
	illusion:AddNewModifier(caster,self,"modifier_illusion", {
		duration = self:GetSpecialValueFor("duration"), 
		outgoing_damage = -100 + self:GetSpecialValueFor("outgoing_damage"), 
		incoming_damage = self:GetSpecialValueFor("incoming_damage")
	})

	-- print(illusion)
	illusion:RemoveNoDraw()
	illusion:RemoveModifierByName("modifier_superposition_illusion")
	for i = 1, caster:GetLevel() do
		illusion:HeroLevelUp(false)
	end
	illusion:SetControllableByPlayer(caster:GetPlayerID(), true)
	illusion:SetForwardVector(caster:GetForwardVector())
	illusion:SetAbsOrigin(caster:GetAbsOrigin())


	

	local units = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, 2000, DOTA_UNIT_TARGET_TEAM_ENEMY, 
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP + DOTA_UNIT_TARGET_BUILDING, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false)

	-- print(#units)
	for k, unit in pairs(units) do
		-- print(unit:GetCursorCastTarget())
		if unit:GetCursorCastTarget() == caster then
			unit:SetCursorCastTarget(illusion)
		end
		if unit:GetAggroTarget() == caster then

			unit:Stop()
			Timers:CreateTimer(0.03, function() 
				unit:SetAggroTarget(illusion)
				unit:SetAttacking(illusion)
			end)
		end
	end
	-- if illusion:IsChanneling() then
	-- 	illusion:AddNewModifier(caster,self,"modifier_disarmed", {duration = 100})
	-- end
	-- Timers:CreateTimer(0.1, function()
	-- end)

	-- Set the skill points to 0 and learn the skills of the caster
    illusion:SetAbilityPoints(0)
    for abilitySlot=0,15 do
        local ability = caster:GetAbilityByIndex(abilitySlot)
        if ability ~= nil then
            local abilityLevel = ability:GetLevel()
            local abilityName = ability:GetAbilityName()
            local illusionAbility = illusion:FindAbilityByName(abilityName)
            if illusionAbility ~= nil then
                illusionAbility:SetLevel(abilityLevel)
            end
        end
    end

	--Remove TP item
	local item = illusion:GetItemInSlot(0)
	if item then illusion:RemoveItem(item) end

	--Recreate the items of the caster
    for itemSlot=0,5 do
        local item = caster:GetItemInSlot(itemSlot)
        if item ~= nil then
            local itemName = item:GetName()
            local newItem = CreateItem(itemName, nil, nil)
            illusion:AddItem(newItem)
        end
    end

	-- print(self.sChannelData)
	local manaToSet = caster:GetMana()
	if self.sChannelData and self.sChannelData.ability then

    	local channelData = self.sChannelData

    	local channelAbility = channelData.ability
    	local channelPosition = channelData.position
    	local channelTarget = channelData.target

		local illusionAbility = illusion:FindAbilityByName(channelAbility:GetName())
		if not illusionAbility then 
			illusionAbility = illusion:FindItemInInventory(channelAbility:GetAbilityName())
			local channelTime = channelAbility:GetChannelStartTime()
			if channelTime == 0 then illusionAbility = nil end
		end

		if illusionAbility then
			illusionAbility:EndCooldown()
			illusionAbility:SetOverrideCastPoint(0.0)
			illusionAbility:SetLevel(channelAbility:GetLevel())

			manaToSet = manaToSet + illusionAbility:GetManaCost(-1)
			
	    	if channelData.target then
	    		illusion:CastAbilityOnTarget(channelData.target, illusionAbility, caster:GetPlayerID())
	    	else
	    		illusion:CastAbilityOnPosition(channelData.position, illusionAbility, caster:GetPlayerID())
	    	end
	    end
	end


	if self.sOrder then
		self.sOrder.UnitIndex = illusion:entindex()
		ExecuteOrderFromTable(self.sOrder)
	end

	if caster:IsChanneling() then 
		caster:InterruptChannel()
		caster:Interrupt()
		caster:Hold() 
	end


	illusion:SetHealth((caster:GetHealth() / caster:GetMaxHealth()) * illusion:GetMaxHealth())
	illusion:SetMana(manaToSet)
	self.sChannelData = {}

	self:CreateSuperpositionIllusion()
end

----------------------------------------------------------------

if IsServer() then
    normal_orders = {
        [DOTA_UNIT_ORDER_MOVE_TO_POSITION] = true,
        [DOTA_UNIT_ORDER_MOVE_TO_TARGET] = true,
        [DOTA_UNIT_ORDER_ATTACK_MOVE] = true,
        [DOTA_UNIT_ORDER_ATTACK_TARGET] = true,
        [DOTA_UNIT_ORDER_HOLD_POSITION] = true,
    }
    cast_orders = {
    	[DOTA_UNIT_ORDER_CAST_POSITION] = true,
    	[DOTA_UNIT_ORDER_CAST_TARGET] = true,
    	[DOTA_UNIT_ORDER_CAST_NO_TARGET] = true
	}
end

----------------------------------------------------------------

modifier_superposition_tracker = class({})

function modifier_superposition_tracker:IsHidden()
	return true
end

function modifier_superposition_tracker:IsPurgable()
	return false
end

function modifier_superposition_tracker:IsPermanent()
	return true
end

function modifier_superposition_tracker:OnCreated()
	self.charges = 3
	self.duration = 35
	if not IsServer() then return end

	self:StartIntervalThink(1.0)
end

function modifier_superposition_tracker:OnIntervalThink()
	if not IsServer() then return end

	local caster = self:GetCaster()
	local modifier = caster:FindModifierByName("modifier_superposition")
	if modifier then 
		self.charges = modifier:GetStackCount()
		self.duration = modifier:GetRemainingTime()
	else
		modifier = caster:AddNewModifier(caster, self:GetAbility(), "modifier_superposition", {Duration = self.duration})
		if modifier then modifier:SetStackCount(self.charges) end
	end
end

modifier_superposition = class({})

function modifier_superposition:IsHidden()
	return false
end

function modifier_superposition:IsPurgable()
	return false
end

function modifier_superposition:IsPermanent()
	return true
end

function modifier_superposition:GetPriority()
	return MODIFIER_PRIORITY_SUPER_ULTRA
end

function modifier_superposition:OnCreated()
	if not IsServer() then return end

	Timers:CreateTimer(0.03, function() 
		if self:GetCaster():IsRealHero() and not self:GetCaster():HasModifier("modifier_superposition_illusion") then
			-- self.replenishTime = 0
			-- self:SetStackCount(1)
			-- self.cooldown = self:GetAbility():GetCooldown(-1)
			self:StartIntervalThink(2)

			local ability = self:GetAbility()
			ability:UseResources(false, false, true)
			local cooldown = ability:GetCooldownTimeRemaining()
			--print(cooldown)
			self.cooldown = cooldown
			ability:EndCooldown()
		end
	end)
end

function modifier_superposition:OnDestroy()
	if not IsServer() then return end

	local caster = self:GetCaster()
	local ability = self:GetAbility()

	local charges = self:GetStackCount() + 1
	local maxCharges = self:GetAbility():GetSpecialValueFor("charges")
	if caster:HasScepter() then maxCharges = maxCharges + 1 end

	self.fullyCharged = charges >= maxCharges

	if not self.fullyCharged then 
		ability:UseResources(false, false, true)
		local duration = ability:GetCooldownTimeRemaining()
		ability:EndCooldown()
		local modifier = caster:AddNewModifier(caster, ability, "modifier_superposition", {duration = duration})
		if modifier then modifier:SetStackCount(charges) end
	else
		local modifier = caster:AddNewModifier(caster, ability, "modifier_superposition", {duration = -1})
		if modifier then modifier:SetStackCount(maxCharges) end
	end


end

function modifier_superposition:OnIntervalThink()
	if not IsServer() then return end
	local caster = self:GetCaster()

	local maxCharges = self:GetAbility():GetSpecialValueFor("charges")
	if caster:HasScepter() then maxCharges = maxCharges + 1 end

	self.fullyCharged = self:GetStackCount() == maxCharges

	if not self.fullyCharged and self:GetDuration() < 0 then 
		self:SetStackCount(maxCharges)
	end

	-- if not self.fullyCharged then
	-- 	self.replenishTime = self.replenishTime + 0.1
	-- else
	-- 	self.replenishTime = 0
	-- end
	-- --print(self.fullyCharged)
	-- -- print(self.cooldown)

	-- if self.replenishTime > self.cooldown then
	-- 	self:IncrementStackCount()
	-- 	self:SetStackCount(self:GetStackCount())
	-- 	self.replenishTime = 0
	-- end
end


function modifier_superposition:DeclareFunctions()
	local funcs = {
		MODIFIER_EVENT_ON_ABILITY_EXECUTED,
		MODIFIER_EVENT_ON_ORDER,
		-- MODIFIER_EVENT_ON_UNIT_MOVED,
		MODIFIER_EVENT_ON_STATE_CHANGED	
	}
	return funcs
end

-- function modifier_superposition:OnUnitMoved(event)
-- 	if not IsServer() then return end

-- 	if event.unit == self:GetCaster() and self:GetCaster():IsRealHero() and not self:GetCaster():HasModifier("modifier_superposition_illusion") then
-- 		local ability = self:GetAbility()
-- 		if ability.sOrder then 
-- 			local order = ability.sOrder
-- 			if order.OrderType == DOTA_UNIT_ORDER_CAST_POSITION then
-- 				ability.sOrder.OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION
-- 				ability.sOrder.AbilityIndex = nil
-- 				print("order changed")
-- 			elseif order.OrderType == DOTA_UNIT_ORDER_CAST_TARGET then
-- 				ability.sOrder.OrderType = DOTA_UNIT_ORDER_MOVE_TO_TARGET
-- 				ability.sOrder.AbilityIndex = nil
-- 				print("order changed")
-- 			end
-- 		end
-- 	end
-- end

function modifier_superposition:OnAbilityExecuted(event)
	if not IsServer() then return end


	if event.unit == self:GetCaster() and self:GetCaster():IsRealHero() and not self:GetCaster():HasModifier("modifier_superposition_illusion") then
		-- self:GetAbility():UpdateSuperpositionStats()

		local caster = self:GetCaster()
		local illusion = self:GetAbility().sIllusion

		local ability = event.ability

		if ability:GetAbilityName() == "item_refresher" or ability:GetAbilityName() == "item_refresher_shard" then
			local charges = self:GetAbility():GetSpecialValueFor("charges")
			if caster:HasScepter() then charges = charges + 1 end
			self:SetStackCount(charges)
			self:SetDuration(-1, true)
		end
		-- Does not trigger on superposition or item casts
		if not ability or ability:GetName() == "lathaal_superposition" then return end
		-- if not caster:IsChanneling() then return end

		illusion:SetAbsOrigin(caster:GetAbsOrigin())
		-- ability:SetOverrideCastPoint(0.0)


		self:GetAbility().sChannelData = {}

		self:GetAbility().sChannelData.ability = ability

		if event.target then
			self:GetAbility().sChannelData.target = event.target
		else
			self:GetAbility().sChannelData.position = caster:GetCursorPosition()
		end

		-- print(self:GetAbility().sChannelData)
		illusion:SetForwardVector(caster:GetForwardVector())
		illusion:SetAbsOrigin(caster:GetAbsOrigin())
		illusion:Stop()

		Timers:CreateTimer(0.03, function () 
			if not caster:IsChanneling() then
				self:GetAbility().sChannelData = {}
			end
		end)

		self:GetAbility().sOrder = nil

		-- if event.target then
		-- 	-- illusion:SetCursorCastTarget(event.target)
		-- 	illusion:CastAbilityOnTarget(event.target,ability,illusion:GetPlayerID())
		-- 	-- local order = {
		-- 	-- 	UnitIndex = illusion:entindex(),
		--  --        OrderType = DOTA_UNIT_ORDER_CAST_TARGET,
		--  --        Queue = 0,
		--  --        AbilityIndex = ability:entindex(),
		--  --        TargetIndex = event.target:entindex()
		-- 	-- }
		-- 	-- ExecuteOrderFromTable(order)
		-- else
		-- 	illusion:CastAbilityOnPosition(caster:GetCursorPosition(), ability,illusion:GetPlayerID())
		-- 	-- illusion:CastAbilityOnPosition(event.new_pos,ability,illusion:GetPlayerID())
		-- end
	end
end

function modifier_superposition:OnOrder(event)
	if not IsServer() then return end

	local caster = self:GetCaster()

	if event.unit == caster and caster:IsRealHero() and not caster:HasModifier("modifier_superposition_illusion") then
		-- Execute identical orders
		local ability = self:GetAbility()
		if not ability.sIllusion then
			ability:CreateSuperpositionIllusion()
		end

		local illusion = ability.sIllusion

		if not illusion:IsNull() and normal_orders[event.order_type] then
			illusion:SetAbsOrigin(caster:GetAbsOrigin())
			local order = {
				UnitIndex = illusion:entindex(),
		        OrderType = event.order_type,
		        Queue = 0
			}
			

			if event.target then
				order.TargetIndex = event.target:entindex()
			elseif event.new_pos then
				order.Position = event.new_pos
			else
				order.Position = caster:GetCursorPosition()
			end

			ability.sOrder = order

			-- for k,v in pairs(order) do 
			-- 	print(k,v)
			-- end
			if event.order_type == DOTA_UNIT_ORDER_ATTACK_TARGET then
				order.OrderType = DOTA_UNIT_ORDER_MOVE_TO_TARGET
			end
			ExecuteOrderFromTable(order)

			order.OrderType = event.order_type

			ability.sChannelData = {}

		elseif not cast_orders[event.order_type] then
			ability.sChannelData = {}
			-- illusion:Hold()
		end
	end
end


function modifier_superposition:OnStateChanged(event)
	if not IsServer() then return end

	if event.unit == self:GetCaster() and self:GetCaster():IsRealHero() then
		if self:GetCaster():IsStunned() or self:GetCaster():IsSilenced() then
			self:GetAbility().sChannelData = {}
		end
	end
end

modifier_superposition_trail = class({})


function modifier_superposition_trail:IsHidden()
	return true
end