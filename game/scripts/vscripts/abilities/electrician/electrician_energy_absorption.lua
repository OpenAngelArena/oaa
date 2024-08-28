electrician_energy_absorption = class(AbilityBaseClass)

LinkLuaModifier("modifier_electrician_energy_absorption", "abilities/electrician/electrician_energy_absorption.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_electrician_energy_absorption_debuff", "abilities/electrician/electrician_energy_absorption.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_electrician_bonus_mana_count", "abilities/electrician/electrician_energy_absorption.lua", LUA_MODIFIER_MOTION_NONE)

--------------------------------------------------------------------------------

-- function electrician_energy_absorption:GetCooldown(level)
--   local caster = self:GetCaster()
--   local base_cd = self.BaseClass.GetCooldown(self, level)

--   local talent = caster:FindAbilityByName("special_bonus_electrician_energy_absorption_cooldown")
--   if talent and talent:GetLevel() > 0 then
--     return base_cd - math.abs(talent:GetSpecialValueFor("value"))
--   end

--   return base_cd
-- end

function electrician_energy_absorption:OnSpellStart()
	local caster = self:GetCaster()
	local casterOrigin = caster:GetAbsOrigin()
	local radius = self:GetSpecialValueFor("radius")

	-- grab all enemes around the caster
	local units = FindUnitsInRadius(
		caster:GetTeamNumber(),
		casterOrigin,
		nil,
		radius,
		self:GetAbilityTargetTeam(),
		self:GetAbilityTargetType(),
		DOTA_UNIT_TARGET_FLAG_NONE,
		FIND_ANY_ORDER,
		false
	)

  -- make the aoe particle, it's dumbshit as of this comment's writing because
  -- i don't need an excuse i'm not doing aesthetics
  local part = ParticleManager:CreateParticle( "particles/econ/generic/generic_aoe_explosion_sphere_1/generic_aoe_explosion_sphere_1.vpcf", PATTACH_ABSORIGIN, caster )
  ParticleManager:SetParticleControl( part, 1, Vector( radius, radius, radius ) )
  ParticleManager:SetParticleControl( part, 2, Vector( 1, 1, 1 ) )
  ParticleManager:ReleaseParticleIndex( part )

  -- play sound
  caster:EmitSound( "Hero_StormSpirit.StaticRemnantPlant" )

	-- don't bother with anything after this if we didnt' hit a single enemy
  if #units > 0 then
    -- grab abilityspecials
    local damage = self:GetSpecialValueFor("damage")
    local damageType = self:GetAbilityDamageType()
    local mana_absorb_base = self:GetSpecialValueFor("mana_absorb_base")
    local mana_absorb_percent = self:GetSpecialValueFor("mana_absorb_percentage")
    local speed_absorb_creeps = self:GetSpecialValueFor("speed_absorb_non_heroes")
    local speed_absorb_heroes = self:GetSpecialValueFor("speed_absorb_heroes")
    local duration = self:GetSpecialValueFor("duration")
    local illusion_multiplier = self:GetSpecialValueFor("illusion_dmg_multiplier")

    -- set up the amount of mana restored by this cast
    local mana_absorbed = 0
    local speed_absorbed = 0

    local damage_table = {
      attacker = caster,
      damage = damage,
      damage_type = damageType,
      damage_flags = DOTA_DAMAGE_FLAG_NONE,
      ability = self,
    }

    -- iterate through each unit struck
    for _, target in pairs( units ) do
      if target and not target:IsNull() then
        -- Get mana values of the target
        local target_current_mana = target:GetMana()
        local mana_to_remove = mana_absorb_base + target_current_mana*mana_absorb_percent*0.01

        -- Check if target has less mana
        if target_current_mana < mana_to_remove then
          mana_to_remove = target_current_mana
        end

        -- Reduce/removed mana of the target (only if not an illusion)
        -- Don't remove mana from illusions to prevent weird interactions
        if not target:IsIllusion() then
          target:ReduceMana(mana_to_remove, self)
          mana_absorbed = mana_absorbed + mana_to_remove
        end

        -- Double damage against illusions
        if target:IsIllusion() and not target:IsStrongIllusionOAA() then
          damage_table.damage = damage * illusion_multiplier
        end

        if target:IsRealHero() or target:IsOAABoss() then
          speed_absorbed = speed_absorbed + speed_absorb_heroes
        else
          speed_absorbed = speed_absorbed + speed_absorb_creeps
        end

        -- for the mana burn number; restricting to heroes as to
        -- reduce spam, can't ignore illusions tho because
        -- that'd make it too obvious
        if target:IsHero() then
          mana_to_remove = math.floor(mana_to_remove)
          local numLength = tostring(mana_to_remove):len() + 1

          -- Mana burn particle
          local partNum = ParticleManager:CreateParticle("particles/units/heroes/hero_nyx_assassin/nyx_assassin_mana_burn_msg.vpcf", PATTACH_OVERHEAD_FOLLOW, target)
          ParticleManager:SetParticleControl(partNum, 1, Vector( 1, mana_to_remove, 0 ))
          ParticleManager:SetParticleControl(partNum, 2, Vector( 1, numLength, 0 ))
          ParticleManager:ReleaseParticleIndex(partNum)
        end

        -- create a projectile that's just for visual effect
        -- would like to just have a particle here that hits the caster
        -- after like ~0.25 seconds
        -- ProjectileManager:CreateTrackingProjectile( {
          -- Ability = self,
          -- Target = caster,
          -- Source = target,
          -- EffectName = "particles/units/heroes/hero_zuus/zuus_base_attack.vpcf",
          -- iMoveSpeed = caster:GetRangeToUnit( target ) / 0.25,
          -- iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_HITLOCATION,
          -- bDodgeable = false,
          -- flExpireTime = GameRules:GetGameTime() + 10,
        -- } )

        -- Add a speed debuff
        local speed_debuff = target:FindModifierByNameAndCaster("modifier_electrician_energy_absorption_debuff", caster)
        if speed_debuff then
          speed_debuff:SetDuration(duration, true)
          speed_debuff:SetStackCount(speed_debuff:GetStackCount() + 1)
        else
          speed_debuff = target:AddNewModifier(caster, self, "modifier_electrician_energy_absorption_debuff", {duration = duration})
          if speed_debuff then
            speed_debuff:SetStackCount(1)
          end
        end

        -- play hit sound
        target:EmitSound( "Hero_StormSpirit.Attack" )

        -- deal damage
        damage_table.victim = target
        ApplyDamage(damage_table)
      end
    end

    -- Check how much mana does the caster have, add excess mana modifier if needed
    local missing_mana = caster:GetMaxMana() - caster:GetMana()
    if missing_mana < mana_absorbed then
      local modifier = caster:FindModifierByName("modifier_electrician_bonus_mana_count")
      if modifier then
        modifier:SetDuration(duration, true)
        modifier:SetStackCount(math.min(modifier:GetStackCount() + mana_absorbed - missing_mana, self:GetSpecialValueFor("bonus_mana_cap")))
      else
        modifier = caster:AddNewModifier(caster, self, "modifier_electrician_bonus_mana_count", {duration = duration})
        if modifier then
          modifier:SetStackCount(math.min(mana_absorbed - missing_mana, self:GetSpecialValueFor("bonus_mana_cap")))
        end
      end
      caster:CalculateStatBonus(true)
    end

    -- Grant mana to the caster (equal to absorbed mana)
    caster:GiveMana(mana_absorbed)

    -- Overhead message
    SendOverheadEventMessage(caster:GetPlayerOwner(), OVERHEAD_ALERT_MANA_ADD, caster, mana_absorbed, nil)

    -- give the speed modifier
    local speed_modifier = caster:FindModifierByName("modifier_electrician_energy_absorption")
    if speed_modifier then
      speed_modifier:SetDuration(duration, true)
      speed_modifier:SetStackCount(speed_modifier:GetStackCount() + speed_absorbed)
    else
      speed_modifier = caster:AddNewModifier(caster, self, "modifier_electrician_energy_absorption", {duration = duration})
      if speed_modifier then
        speed_modifier:SetStackCount(speed_absorbed)
      end
    end
  end
end

---------------------------------------------------------------------------------------------------

modifier_electrician_energy_absorption = class(ModifierBaseClass)

function modifier_electrician_energy_absorption:IsDebuff()
  return false
end

function modifier_electrician_energy_absorption:IsHidden()
  return false
end

function modifier_electrician_energy_absorption:IsPurgable()
  return true
end

function modifier_electrician_energy_absorption:OnCreated(event)
  local parent = self:GetParent()
  self.partShell = ParticleManager:CreateParticle("particles/hero/electrician/electrician_energy_absorbtion.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
  ParticleManager:SetParticleControlEnt(self.partShell, 1, parent, PATTACH_ABSORIGIN_FOLLOW, nil, parent:GetAbsOrigin(), true)
end

function modifier_electrician_energy_absorption:OnRefresh(event)
  -- destroy the shield particles
  if self.partShell then
    ParticleManager:DestroyParticle(self.partShell, false)
    ParticleManager:ReleaseParticleIndex(self.partShell)
  end

  self:OnCreated(event)
end

function modifier_electrician_energy_absorption:OnDestroy()
  -- destroy the shield particles
  if self.partShell then
    ParticleManager:DestroyParticle(self.partShell, false)
    ParticleManager:ReleaseParticleIndex(self.partShell)
  end
end

function modifier_electrician_energy_absorption:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT,
    MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
  }
end

function modifier_electrician_energy_absorption:GetModifierMoveSpeedBonus_Constant()
  return self:GetStackCount()
end

function modifier_electrician_energy_absorption:GetModifierAttackSpeedBonus_Constant()
  return self:GetStackCount()
end

---------------------------------------------------------------------------------------------------

modifier_electrician_energy_absorption_debuff = class(ModifierBaseClass)

function modifier_electrician_energy_absorption_debuff:IsDebuff()
  return true
end

function modifier_electrician_energy_absorption_debuff:IsHidden()
  return false
end

function modifier_electrician_energy_absorption_debuff:IsPurgable()
  return true
end

function modifier_electrician_energy_absorption_debuff:OnCreated(event)
  local parent = self:GetParent()
  self.partShell = ParticleManager:CreateParticle("particles/hero/electrician/electrician_energy_absorbtion.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
  ParticleManager:SetParticleControlEnt(self.partShell, 1, parent, PATTACH_ABSORIGIN_FOLLOW, nil, parent:GetAbsOrigin(), true)

  local ability = self:GetAbility()
  local speed_absorb_creeps = 5
  local speed_absorb_heroes = 10
  if ability and not ability:IsNull() then
    speed_absorb_creeps = ability:GetSpecialValueFor("speed_absorb_non_heroes")
    speed_absorb_heroes = ability:GetSpecialValueFor("speed_absorb_heroes")
  end

  local stack_count = self:GetStackCount()
  if parent:IsRealHero() or parent:IsOAABoss() then
    self.speed = -speed_absorb_heroes * stack_count
  else
    self.speed = -speed_absorb_creeps * stack_count
  end
end

function modifier_electrician_energy_absorption_debuff:OnRefresh(event)
  -- destroy the shield particles
  if self.partShell then
    ParticleManager:DestroyParticle(self.partShell, false)
    ParticleManager:ReleaseParticleIndex(self.partShell)
  end

  self:OnCreated(event)
end

function modifier_electrician_energy_absorption_debuff:OnDestroy()
  -- destroy the shield particles
  if self.partShell then
    ParticleManager:DestroyParticle(self.partShell, false)
    ParticleManager:ReleaseParticleIndex(self.partShell)
  end
end

function modifier_electrician_energy_absorption_debuff:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT,
    MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
  }
end

function modifier_electrician_energy_absorption_debuff:GetModifierMoveSpeedBonus_Constant()
  return self.speed
end

function modifier_electrician_energy_absorption_debuff:GetModifierAttackSpeedBonus_Constant()
  return self.speed
end

---------------------------------------------------------------------------------------------------

modifier_electrician_bonus_mana_count = class(ModifierBaseClass)

function modifier_electrician_bonus_mana_count:IsHidden()
  return false
end

function modifier_electrician_bonus_mana_count:IsDebuff()
  return false
end

function modifier_electrician_bonus_mana_count:IsPurgable()
  return false
end

function modifier_electrician_bonus_mana_count:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_EXTRA_MANA_BONUS,
    MODIFIER_EVENT_ON_SPENT_MANA
  }
end

function modifier_electrician_bonus_mana_count:GetModifierExtraManaBonus()
  return self:GetStackCount()
end

function modifier_electrician_bonus_mana_count:OnSpentMana(event)
  if IsServer() then
    if event.unit == self:GetParent() then
      local restore_amount = event.cost
      if restore_amount > self:GetStackCount() then
        self:Destroy()
      else
        self:SetStackCount(self:GetStackCount() - restore_amount)
      end
    end
  end
end
