modifier_oaa_int_steal = class(ModifierBaseClass)

function modifier_oaa_int_steal:IsPurgable()
  return false
end

function modifier_oaa_int_steal:RemoveOnDeath()
  return false
end

function modifier_oaa_int_steal:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_DEATH
  }
end

function modifier_oaa_int_steal:OnDeath(keys)
  local parent = self:GetParent()
  local ability = self:GetAbility()
  local stealRange = ability:GetLevelSpecialValueFor("steal_range", math.max(1, ability:GetLevel()))
  local stealAmount = ability:GetLevelSpecialValueFor("steal_amount", math.max(1, ability:GetLevel()))
  local filterResult = UnitFilter(
    keys.unit,
    DOTA_UNIT_TARGET_TEAM_ENEMY,
    DOTA_UNIT_TARGET_HERO,
    bit.bor(DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, DOTA_UNIT_TARGET_FLAG_DEAD),
    parent:GetTeamNumber()
  )
  local isWithinRange = #(keys.unit:GetAbsOrigin() - parent:GetAbsOrigin()) <= stealRange

  -- Check for +2 Int Steal Talent
  if parent:HasLearnedAbility("special_bonus_unique_silencer_2") then
    stealAmount = stealAmount + parent:FindAbilityByName("special_bonus_unique_silencer_2"):GetSpecialValueFor("value")
  end

  if filterResult == UF_SUCCESS and (keys.attacker == parent or isWithinRange) and parent:IsRealHero() and parent:IsAlive() and keys.unit:IsRealHero() and not keys.unit:IsClone() then
    local oldIntellect = keys.unit:GetBaseIntellect()
    keys.unit:SetBaseIntellect(math.max(1, oldIntellect - stealAmount))
    keys.unit:CalculateStatBonus()
    local intellectDifference = oldIntellect - keys.unit:GetBaseIntellect()
    parent:ModifyIntellect(intellectDifference)
    self:SetStackCount(self:GetStackCount() + intellectDifference)

    local plusIntParticleName = "particles/units/heroes/hero_silencer/silencer_last_word_steal_count.vpcf"
    local plusIntParticle = ParticleManager:CreateParticle(plusIntParticleName, PATTACH_OVERHEAD_FOLLOW, parent)
    ParticleManager:SetParticleControl(plusIntParticle, 1, Vector(10 + intellectDifference, 0, 0))
    ParticleManager:ReleaseParticleIndex(plusIntParticle)

    local minusIntParticleName = "particles/units/heroes/hero_silencer/silencer_last_word_victim_count.vpcf"
    local minusIntParticle = ParticleManager:CreateParticle(minusIntParticleName, PATTACH_OVERHEAD_FOLLOW, keys.unit)
    ParticleManager:SetParticleControl(minusIntParticle, 1, Vector(10 + intellectDifference, 0, 0))
    ParticleManager:ReleaseParticleIndex(minusIntParticle)
  end
end
