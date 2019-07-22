item_trumps_fists = class(ItemBaseClass)

LinkLuaModifier( "modifier_item_trumps_fists_passive", "items/trumps_fists.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_item_trumps_fists_frostbite", "items/trumps_fists.lua", LUA_MODIFIER_MOTION_NONE )

function item_trumps_fists:GetIntrinsicModifierName()
  return "modifier_item_trumps_fists_passive"
end

item_trumps_fists_2 = item_trumps_fists

--------------------------------------------------------------------------------

modifier_item_trumps_fists_passive = class(ModifierBaseClass)

function modifier_item_trumps_fists_passive:IsHidden()
  return true
end

function modifier_item_trumps_fists_passive:IsPurgable()
  return false
end

function modifier_item_trumps_fists_passive:OnCreated(kv)
  self.bonus_all_stats = self:GetAbility():GetSpecialValueFor( "bonus_all_stats" )
  self.bonus_damage = self:GetAbility():GetSpecialValueFor( "bonus_damage" )
  self.bonus_health = self:GetAbility():GetSpecialValueFor( "bonus_health" )
  self.bonus_mana = self:GetAbility():GetSpecialValueFor( "bonus_mana" )
  self.heal_prevent_duration = self:GetAbility():GetSpecialValueFor( "heal_prevent_duration" )

  if IsServer() then
    self:GetCaster():ChangeAttackProjectile()
  end
end

function modifier_item_trumps_fists_passive:OnDestroy()
  if IsServer() then
    self:GetCaster():ChangeAttackProjectile()
  end
end

function modifier_item_trumps_fists_passive:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
    MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
    MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
    MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
    MODIFIER_PROPERTY_HEALTH_BONUS,
    MODIFIER_PROPERTY_MANA_BONUS,
    MODIFIER_EVENT_ON_ATTACK_LANDED,
  }
  return funcs
end

function modifier_item_trumps_fists_passive:GetModifierBonusStats_Strength()
  return self.bonus_all_stats
end

function modifier_item_trumps_fists_passive:GetModifierBonusStats_Agility()
  return self.bonus_all_stats
end

function modifier_item_trumps_fists_passive:GetModifierBonusStats_Intellect()
  return self.bonus_all_stats
end

function modifier_item_trumps_fists_passive:GetModifierPreAttack_BonusDamage()
  return self.bonus_damage
end

function modifier_item_trumps_fists_passive:GetModifierHealthBonus()
  return self.bonus_health
end

function modifier_item_trumps_fists_passive:GetModifierManaBonus()
  return self.bonus_mana
end

function modifier_item_trumps_fists_passive:OnAttackLanded( kv )
  if IsServer() then
    local attacker = kv.attacker
    local target = kv.target
    if attacker == self:GetParent() and not attacker:IsIllusion() and not target:IsMagicImmune() then
      local debuff_duration = target:GetValueChangedByStatusResistance(self.heal_prevent_duration)
      target:AddNewModifier( self:GetCaster(), self:GetAbility(), "modifier_item_trumps_fists_frostbite", { duration = debuff_duration } )
    end
  end
end

--------------------------------------------------------------------------------

modifier_item_trumps_fists_frostbite = class(ModifierBaseClass)

function modifier_item_trumps_fists_frostbite:OnCreated()
  if IsServer() then
    self.heal_prevent_percent = self:GetAbility():GetSpecialValueFor( "heal_prevent_percent" )
    self.totalDuration = self:GetDuration() or self:GetAbility():GetSpecialValueFor( "heal_prevent_duration" )
    self.health_fraction = 0
  end
end

function modifier_item_trumps_fists_frostbite:IsDebuff()
  return true
end

function modifier_item_trumps_fists_frostbite:DeclareFunctions()
  local funcs = {
    MODIFIER_EVENT_ON_HEALTH_GAINED
  }
  return funcs
end

function modifier_item_trumps_fists_frostbite:OnHealthGained( kv )
  if IsServer() then
    -- Check that event is being called for the unit that self is attached to
    if kv.unit == self:GetParent() and kv.gain > 0 then
      local healPercent = self.heal_prevent_percent / 100 * (self:GetRemainingTime() / self.totalDuration)
      local desiredHP = kv.unit:GetHealth() + kv.gain * healPercent + self.health_fraction
      desiredHP = math.max(desiredHP, 1)
      -- Keep record of fractions of health since Dota doesn't (mainly to make passive health regen sort of work)
      self.health_fraction = desiredHP % 1

      DebugPrint(desiredHP)
      kv.unit:SetHealth( desiredHP )
    end
  end
end
