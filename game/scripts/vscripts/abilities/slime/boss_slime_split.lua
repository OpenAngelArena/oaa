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

function modifier_boss_slime_split_passive:GetModifierModelChange( params )
	return "models/creeps/darkreef/blob/darkreef_blob_01.vmdl"
end

------------------------------------------------------------------------------------

function modifier_boss_slime_split_passive:DeclareFunctions()
	local funcs =
	{
		MODIFIER_PROPERTY_MODEL_CHANGE,
		MODIFIER_PROPERTY_MIN_HEALTH,
		MODIFIER_EVENT_ON_DEATH,
		MODIFIER_PROPERTY_MODEL_SCALE,
		MODIFIER_EVENT_ON_TAKEDAMAGE
	}

	return funcs
end

------------------------------------------------------------------------------------

function modifier_boss_slime_split_passive:GetPriority()
  return MODIFIER_PRIORITY_SUPER_ULTRA
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

function modifier_boss_slime_split_passive:GetModifierModelScale( params )
	return 150.0
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
							caster:Kill(nil, caster)
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
			caster:SetClones(
        self:CreateClone(caster:GetAbsOrigin() + Vector( 100,0,0)),
        self:CreateClone(caster:GetAbsOrigin() + Vector(-100,0,0)))
			caster:AddNoDraw()
		end
	end
end

------------------------------------------------------------------------------------

function modifier_boss_slime_split_passive:CreateClone(origin)
  local caster = self:GetParent()
  local unitName = caster:GetUnitName()
  local clone = CreateUnitByName(unitName, origin, true, caster, caster, caster:GetTeamNumber())
  clone:RemoveAbility("boss_slime_split")
  for i = DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_6 do
    local item = caster:GetItemInSlot(i)
    if item then
      clone:AddItem(CreateItem(item:GetName(), clone, clone))
    end
  end
  return clone
end
