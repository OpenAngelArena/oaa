LinkLuaModifier("modifier_spider_boss_incapacitating_bite", "abilities/boss/spider_boss/spider_boss_incapacitating_bite.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_spider_boss_incapacitating_bite_debuff", "abilities/boss/spider_boss/spider_boss_incapacitating_bite.lua", LUA_MODIFIER_MOTION_NONE)

spider_boss_incapacitating_bite = class(AbilityBaseClass)

function spider_boss_incapacitating_bite:GetIntrinsicModifierName()
  return "modifier_spider_boss_incapacitating_bite"
end

---------------------------------------------------------------------------------------------------

modifier_spider_boss_incapacitating_bite = class(ModifierBaseClass)

function modifier_spider_boss_incapacitating_bite:IsHidden()
  return true
end

function modifier_spider_boss_incapacitating_bite:IsDebuff()
  return false
end

function modifier_spider_boss_incapacitating_bite:IsPurgable()
  return false
end

function modifier_spider_boss_incapacitating_bite:RemoveOnDeath()
  return true
end

function modifier_spider_boss_incapacitating_bite:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_ATTACK_LANDED,
  }
end

if IsServer() then
  function modifier_spider_boss_incapacitating_bite:OnAttackLanded(event)
    local parent = self:GetParent()
    local ability = self:GetAbility()
    local attacker = event.attacker
    local target = event.target

    -- Check if attacker exists
    if not attacker or attacker:IsNull() then
      return
    end

    -- Don't proc on units that dont have this modifier or if broken
    if attacker ~= parent or parent:PassivesDisabled() then
      return
    end

    -- Check if attacked unit exists
    if not target or target:IsNull() then
      return
    end

    -- Don't affect buildings, wards, spell immune units and invulnerable units.
    if target:IsMagicImmune() or target:IsTower() or target:IsBarracks() or target:IsBuilding() or target:IsOther() or target:IsInvulnerable() then
      return
    end

    -- Get duration
    local duration = ability:GetSpecialValueFor("duration")

    -- Apply debuff
    target:AddNewModifier(parent, ability, "modifier_spider_boss_incapacitating_bite_debuff", {duration = duration})
  end
end

---------------------------------------------------------------------------------------------------

modifier_spider_boss_incapacitating_bite_debuff = class(ModifierBaseClass)

function modifier_spider_boss_incapacitating_bite_debuff:IsHidden()
  return false
end

function modifier_spider_boss_incapacitating_bite_debuff:IsDebuff()
  return true
end

function modifier_spider_boss_incapacitating_bite_debuff:IsPurgable()
  return true
end

function modifier_spider_boss_incapacitating_bite_debuff:RemoveOnDeath()
  return true
end

function modifier_spider_boss_incapacitating_bite_debuff:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.movement_slow = ability:GetSpecialValueFor("move_speed_slow")
    self.attack_slow = ability:GetSpecialValueFor("attack_speed_slow")
    self.miss_chance = ability:GetSpecialValueFor("miss_chance")
  end
end

function modifier_spider_boss_incapacitating_bite_debuff:OnRefresh()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.movement_slow = ability:GetSpecialValueFor("move_speed_slow")
    self.attack_slow = ability:GetSpecialValueFor("attack_speed_slow")
    self.miss_chance = ability:GetSpecialValueFor("miss_chance")
  end
end

function modifier_spider_boss_incapacitating_bite_debuff:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
    MODIFIER_PROPERTY_MISS_PERCENTAGE,
  }
end

function modifier_spider_boss_incapacitating_bite_debuff:GetModifierMoveSpeedBonus_Percentage()
  if self.movement_slow or self:GetAbility() then
    return self.movement_slow or self:GetAbility():GetSpecialValueFor("move_speed_slow")
  end

  return -30
end

function modifier_spider_boss_incapacitating_bite_debuff:GetModifierAttackSpeedBonus_Constant()
  if self.attack_slow or self:GetAbility() then
    return self.attack_slow or self:GetAbility():GetSpecialValueFor("attack_speed_slow")
  end

  return -60
end

function modifier_spider_boss_incapacitating_bite_debuff:GetModifierMiss_Percentage()
  if self.miss_chance or self:GetAbility() then
    return self.miss_chance or self:GetAbility():GetSpecialValueFor("miss_chance")
  end

  return 60
end

--function modifier_spider_boss_incapacitating_bite_debuff:GetEffectName()
  --return ""
--end
