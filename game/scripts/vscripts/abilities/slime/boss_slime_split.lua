LinkLuaModifier("modifier_boss_slime_split_passive", "abilities/slime/boss_slime_split.lua", LUA_MODIFIER_MOTION_NONE)

--------------------------------------------------------------------------------

boss_slime_split = class(AbilityBaseClass)

--------------------------------------------------------------------------------

function boss_slime_split:GetIntrinsicModifierName()
	return "modifier_boss_slime_split_passive"
end

------------------------------------------------------------------------------------

modifier_boss_slime_split_passive = class(ModifierBaseClass)

------------------------------------------------------------------------------------

function modifier_boss_slime_split_passive:DeclareFunctions()
	local funcs =
	{
		MODIFIER_PROPERTY_MIN_HEALTH,
		MODIFIER_EVENT_ON_DEATH,
		MODIFIER_PROPERTY_MODEL_SCALE,
		MODIFIER_EVENT_ON_TAKEDAMAGE
	}

	return funcs
end

------------------------------------------------------------------------------------

function modifier_boss_slime_split_passive:RemoveOnDeath()
	return true
end

------------------------------------------------------------------------------------

function modifier_boss_slime_split_passive:GetMinHealth()
	if self.readyToDie then return nil end
	return 1.0
end

------------------------------------------------------------------------------------

function modifier_boss_slime_split_passive:GetModifierModelScale()
	return 2.0
end

------------------------------------------------------------------------------------

function modifier_boss_slime_split_passive:OnTakeDamage(keys)
	if IsServer() then
		local caster = self:GetParent()
		if keys.unit:entindex() == caster:entindex() then
			if caster:GetHealth() == 1.0 then
				local shakeAbility = caster:FindAbilityByName("boss_slime_shake")
				if shakeAbility then
					caster:Stop()
					shakeAbility:EndCooldown()
					ExecuteOrderFromTable({
						UnitIndex = caster:entindex(),
						OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
						AbilityIndex = shakeAbility:entindex(),
					})
					caster:AddNewModifier(caster, shakeAbility, "modifier_invulnerable", {})
					Timers:CreateTimer(shakeAbility:GetChannelTime(), function ()
						self.readyToDie = true
						caster:RemoveModifierByName("modifier_invulnerable")
						Timers:CreateTimer(function()
							caster:Kill()
						end)
					end)
				end
			end
		end
	end
end

------------------------------------------------------------------------------------

function modifier_boss_slime_split_passive:OnDeath(keys)
	if IsServer() then
		local caster = self:GetParent()
		if keys.unit:entindex() == caster:entindex() then
			local unitName = caster:GetUnitName()

			local function CreateClone(origin)
				local clone = CreateUnitByName(unitName, origin, true, nil, nil, caster:GetTeamNumber())
				clone:RemoveAbility("boss_slime_split")
				for i=0,5 do
					local item = caster:GetItemInSlot(i)
					if item then
						clone:AddItem(CreateItem(item:GetName(), clone, clone))
					end
				end
				return clone
			end
			caster:SetClones(CreateClone(caster:GetAbsOrigin() + Vector(100,0,0)),
				CreateClone(caster:GetAbsOrigin() + Vector(-100,0,0)))
			caster:AddNoDraw()
		end
	end
end