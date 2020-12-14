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
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.bonus_all_stats = ability:GetSpecialValueFor( "bonus_all_stats" )
    self.bonus_damage = ability:GetSpecialValueFor( "bonus_damage" )
    self.bonus_health = ability:GetSpecialValueFor( "bonus_health" )
    self.bonus_mana = ability:GetSpecialValueFor( "bonus_mana" )
    self.heal_prevent_duration = ability:GetSpecialValueFor( "heal_prevent_duration" )
  end

  if IsServer() then
    self:GetCaster():ChangeAttackProjectile()
  end
end

modifier_item_trumps_fists_passive.OnRefresh = modifier_item_trumps_fists_passive.OnCreated

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
    if attacker == self:GetParent() and not attacker:IsIllusion() then
      --local debuff_duration = target:GetValueChangedByStatusResistance(self.heal_prevent_duration)
      target:AddNewModifier( self:GetCaster(), self:GetAbility(), "modifier_item_trumps_fists_frostbite", { duration = self.heal_prevent_duration } )
    end
  end
end

--------------------------------------------------------------------------------

modifier_item_trumps_fists_frostbite = class(ModifierBaseClass)

function modifier_item_trumps_fists_frostbite:OnCreated()
  if IsServer() then
    self.heal_prevent_percent = self:GetAbility():GetSpecialValueFor( "heal_prevent_percent" )
    --self.totalDuration = self:GetDuration() or self:GetAbility():GetSpecialValueFor( "heal_prevent_duration" )
    --self.health_fraction = 0
  end
end

function modifier_item_trumps_fists_frostbite:IsDebuff()
  return true
end

function modifier_item_trumps_fists_frostbite:IsPurgable()
  return false
end

function modifier_item_trumps_fists_frostbite:DeclareFunctions()
  local funcs = {
    --MODIFIER_PROPERTY_DISABLE_HEALING,
    MODIFIER_EVENT_ON_HEALTH_GAINED,
  }
  return funcs
end

--function modifier_item_trumps_fists_frostbite:GetDisableHealing()
  --return 1
--end
-- Old heal prevention that decays over time
--[[
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
]]

-- Deals damage every time a unit gains hp; damage is equal to percent of gained hp;
function modifier_item_trumps_fists_frostbite:OnHealthGained( kv )
  if IsServer() then
    local unit = kv.unit
    local caster = self:GetCaster()
    if unit == self:GetParent() and kv.gain and not unit:FindModifierByNameAndCaster("modifier_batrider_sticky_napalm", caster) then
      if kv.gain > 0 then
        local heal_to_damage = self.heal_prevent_percent / 100
        local damage = kv.gain * heal_to_damage
        local damage_table = {
          victim = unit,
          attacker = caster,
          damage = damage,
          damage_type = DAMAGE_TYPE_PURE,
          ability = self:GetAbility()
        }
        ApplyDamage(damage_table)
      end
    end
  end
end
