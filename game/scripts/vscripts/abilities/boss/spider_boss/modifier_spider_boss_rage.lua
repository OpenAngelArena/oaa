
modifier_spider_boss_rage = class( ModifierBaseClass )

function modifier_spider_boss_rage:IsHidden()
  return false
end

function modifier_spider_boss_rage:IsDebuff()
  return false
end

function modifier_spider_boss_rage:IsPurgable()
  return false
end

function modifier_spider_boss_rage:RemoveOnDeath()
  return true
end

function modifier_spider_boss_rage:OnCreated( kv )
  local parent = self:GetParent()
  local ability = self:GetAbility()

  self.bonus_movespeed_pct = ability:GetSpecialValueFor( "bonus_movespeed_pct" )
  self.lifesteal_pct = ability:GetSpecialValueFor( "lifesteal_pct" )
  self.bat = ability:GetSpecialValueFor( "base_attack_time" )

  if IsServer() then
    parent.enraged = true

    local nFXIndex = ParticleManager:CreateParticle( "particles/units/heroes/hero_broodmother/broodmother_hunger_buff.vpcf", PATTACH_CUSTOMORIGIN, parent )
    ParticleManager:SetParticleControlEnt( nFXIndex, 0, parent, PATTACH_POINT_FOLLOW, "attach_thorax", parent:GetAbsOrigin(), true )
    self:AddParticle( nFXIndex, false, false, -1, false, false  )

    parent:EmitSound("Dungeon.SpiderBoss.Rage")
  end
end

--------------------------------------------------------------------------------

function modifier_spider_boss_rage:OnDestroy()
  if not IsServer() then
    return
  end
  local parent = self:GetParent()
  parent:StopSound("Dungeon.SpiderBoss.Rage")
  parent.enraged = false
end

--------------------------------------------------------------------------------

function modifier_spider_boss_rage:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_ATTACKSPEED_REDUCTION_PERCENTAGE,
    MODIFIER_PROPERTY_BASE_ATTACK_TIME_CONSTANT,
    MODIFIER_PROPERTY_MODEL_SCALE,
    MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    MODIFIER_PROPERTY_PROCATTACK_FEEDBACK,
    MODIFIER_PROPERTY_TOOLTIP,
  }
end

function modifier_spider_boss_rage:GetModifierMoveSpeedBonus_Percentage()
	return self.bonus_movespeed_pct
end

function modifier_spider_boss_rage:GetModifierAttackSpeedReductionPercentage()
  return 0
end

function modifier_spider_boss_rage:GetModifierBaseAttackTimeConstant()
  return self.bat
end

function modifier_spider_boss_rage:GetModifierModelScale()
  return 25
end

if IsServer() then
  function modifier_spider_boss_rage:GetModifierProcAttack_Feedback(event)
    local parent = self:GetParent()
    local attacker = event.attacker
    local target = event.target

    -- Check if attacker exists
    if not attacker or attacker:IsNull() then
      return
    end

    -- Check if attacker has this modifier
    if attacker ~= parent then
      return
    end

    -- Check if attacked entity exists
    if not target or target:IsNull() then
      return
    end

    -- Check if attacked entity is an item, rune or something weird
    if target.GetUnitName == nil then
      return
    end

    local damage = event.damage
    if damage <= 0 or event.damage_category ~= DOTA_DAMAGE_CATEGORY_ATTACK then
      return
    end

    local ufResult = UnitFilter(
      target,
      DOTA_UNIT_TARGET_TEAM_ENEMY,
      bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO),
      bit.bor(DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, DOTA_UNIT_TARGET_FLAG_DEAD),
      parent:GetTeamNumber()
    )

		if ufResult == UF_SUCCESS then
      -- Calculate Lifesteal, max amount is target's current hp)
      local amount = math.min(damage * self.lifesteal_pct / 100, target:GetHealth())
      -- Apply Lifesteal
      parent:HealWithParams(amount, self:GetAbility(), true, true, parent, false)
      -- Lifesteal particle
      local particle = ParticleManager:CreateParticle("particles/generic_gameplay/generic_lifesteal.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
      ParticleManager:ReleaseParticleIndex(particle)
    end
  end
end

function modifier_spider_boss_rage:OnTooltip()
	return self.lifesteal_pct
end

