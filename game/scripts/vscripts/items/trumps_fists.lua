item_trumps_fists = class({})

LinkLuaModifier( "modifier_item_trumps_fists_passive", "items/trumps_fists.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_item_trumps_fists_frostbite", "items/trumps_fists.lua", LUA_MODIFIER_MOTION_NONE )

function item_trumps_fists:GetIntrinsicModifierName()
  return "modifier_item_trumps_fists_passive"
end

--------------------------------------------------------------------------------

item_trumps_fists_2 = class({})

function item_trumps_fists_2:GetIntrinsicModifierName()
  return "modifier_item_trumps_fists_passive"
end

--------------------------------------------------------------------------------

modifier_item_trumps_fists_passive = class({})

function modifier_item_trumps_fists_passive:IsHidden()
  return true
end

function modifier_item_trumps_fists_passive:IsPurgable()
  return false
end

function modifier_item_trumps_fists_passive:OnCreated()
  self.bonus_all_stats = self:GetAbility():GetSpecialValueFor( "bonus_all_stats" )
  self.bonus_damage = self:GetAbility():GetSpecialValueFor( "bonus_damage" )
  self.bonus_health = self:GetAbility():GetSpecialValueFor( "bonus_health" )
  self.bonus_mana = self:GetAbility():GetSpecialValueFor( "bonus_mana" )

  self.heal_prevent_duration = self:GetAbility():GetSpecialValueFor( "heal_prevent_duration" )
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
    if kv.attacker == self:GetParent() and not kv.attacker:IsIllusion() then
      kv.target:AddNewModifier( self:GetCaster(), self:GetAbility(), "modifier_item_trumps_fists_frostbite", { duration = self.heal_prevent_duration } )
    end
  end
end

--------------------------------------------------------------------------------

modifier_item_trumps_fists_frostbite = class({})

function modifier_item_trumps_fists_frostbite:OnCreated()
  if IsServer() then
    self.heal_prevent_percent = self:GetAbility():GetSpecialValueFor( "heal_prevent_percent" )
    self.passive_heal_reduction = self:GetParent():GetHealthRegen() * self.heal_prevent_percent / 100
    self:StartIntervalThink(0.1)
  end
end

function modifier_item_trumps_fists_frostbite:IsDebuff()
  return true
end

function modifier_item_trumps_fists_frostbite:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
    MODIFIER_EVENT_ON_HEALTH_GAINED
  }
  return funcs
end

function modifier_item_trumps_fists_frostbite:OnIntervalThink()
  -- Update passive health regen reduction
  self.passive_heal_reduction = (self:GetParent():GetHealthRegen() - self.passive_heal_reduction) * self.heal_prevent_percent / 100
end

function modifier_item_trumps_fists_frostbite:GetModifierConstantHealthRegen()
  return self.passive_heal_reduction
end

function modifier_item_trumps_fists_frostbite:OnHealthGained( kv )
  if IsServer() then
    -- Check that event is being called for the unit that self is attached to
    -- and that the healing is not passive regen
    if kv.unit == self:GetParent() and not kv.process_procs then
      local desiredHP = kv.unit:GetHealth() + kv.gain * self.heal_prevent_percent / 100
      desiredHP = math.max(desiredHP, 1)

      kv.unit:SetHealth( desiredHP )
    end
  end
end
