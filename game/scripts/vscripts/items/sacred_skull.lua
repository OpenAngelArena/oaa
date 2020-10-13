LinkLuaModifier("modifier_intrinsic_multiplexer", "modifiers/modifier_intrinsic_multiplexer.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_sacred_skull_stacking_stats", "items/sacred_skull.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_sacred_skull_non_stacking_stats", "items/sacred_skull.lua", LUA_MODIFIER_MOTION_NONE)

item_sacred_skull = class(ItemBaseClass)

function item_sacred_skull:GetIntrinsicModifierName()
  return "modifier_intrinsic_multiplexer"
end

function item_sacred_skull:GetIntrinsicModifierNames()
  return {
    "modifier_item_sacred_skull_stacking_stats",
    "modifier_item_sacred_skull_non_stacking_stats"
  }
end

function item_sacred_skull:OnSpellStart()
  local caster = self:GetCaster()

end

-- upgrades
item_sacred_skull_2 = item_sacred_skull
item_sacred_skull_3 = item_sacred_skull
item_sacred_skull_4 = item_sacred_skull

---------------------------------------------------------------------------------------------------
-- Parts of Sacred Skull that should stack with other Sacred Skulls

modifier_item_sacred_skull_stacking_stats = class(ModifierBaseClass)

function modifier_item_sacred_skull_stacking_stats:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.bonus_health = ability:GetSpecialValueFor("bonus_health")
    self.bonus_mana_regen = ability:GetSpecialValueFor("bonus_mana_regen")
    self.bonus_mana = ability:GetSpecialValueFor("bonus_mana")
    self.bonus_hp_regen = ability:GetSpecialValueFor("bonus_health_regen")
    self.bonus_int = ability:GetSpecialValueFor("bonus_intellect")
    self.bonus_magic_resist = ability:GetSpecialValueFor("bonus_magic_resistance")
  end
end

function modifier_item_sacred_skull_stacking_stats:OnRefreshed()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.bonus_health = ability:GetSpecialValueFor("bonus_health")
    self.bonus_mana_regen = ability:GetSpecialValueFor("bonus_mana_regen")
    self.bonus_mana = ability:GetSpecialValueFor("bonus_mana")
    self.bonus_hp_regen = ability:GetSpecialValueFor("bonus_health_regen")
    self.bonus_int = ability:GetSpecialValueFor("bonus_intellect")
    self.bonus_magic_resist = ability:GetSpecialValueFor("bonus_magic_resistance")
  end
end

function modifier_item_sacred_skull_stacking_stats:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_sacred_skull_stacking_stats:IsHidden()
  return true
end

function modifier_item_sacred_skull_stacking_stats:IsDebuff()
  return false
end

function modifier_item_sacred_skull_stacking_stats:IsPurgable()
  return false
end

function modifier_item_sacred_skull_stacking_stats:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_DEATH,
    MODIFIER_PROPERTY_HEALTH_BONUS, -- GetModifierHealthBonus
    MODIFIER_PROPERTY_MANA_BONUS, -- GetModifierManaBonus
    MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT, -- GetModifierConstantHealthRegen
    MODIFIER_PROPERTY_MANA_REGEN_CONSTANT, -- GetModifierConstantManaRegen
    MODIFIER_PROPERTY_STATS_INTELLECT_BONUS, -- GetModifierBonusStats_Intellect
    MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS, -- GetModifierMagicalResistanceBonus
  }
end

function modifier_item_sacred_skull_stacking_stats:GetModifierHealthBonus()
  return self.bonus_health or self:GetAbility():GetSpecialValueFor("bonus_health")
end

function modifier_item_sacred_skull_stacking_stats:GetModifierManaBonus()
  return self.bonus_mana or self:GetAbility():GetSpecialValueFor("bonus_mana")
end

function modifier_item_sacred_skull_stacking_stats:GetModifierConstantHealthRegen()
  return self.bonus_hp_regen or self:GetAbility():GetSpecialValueFor("bonus_health_regen")
end

function modifier_item_sacred_skull_stacking_stats:GetModifierConstantManaRegen()
  return self.bonus_mana_regen or self:GetAbility():GetSpecialValueFor("bonus_mana_regen")
end

function modifier_item_sacred_skull_stacking_stats:GetModifierBonusStats_Intellect()
  return self.bonus_int or self:GetAbility():GetSpecialValueFor("bonus_intellect")
end

function modifier_item_sacred_skull_stacking_stats:GetModifierMagicalResistanceBonus()
  return self.bonus_magic_resist or self:GetAbility():GetSpecialValueFor("bonus_magic_resistance")
end

function modifier_item_sacred_skull_stacking_stats:OnDeath(event)
  local caster = self:GetCaster()
  local dead = event.unit
  local ability = self:GetAbility()

  -- If dead unit is not the caster then dont continue
  if dead ~= caster then
    return
  end

  -- Check if dead unit is nil or its about to be deleted
  if not dead or dead:IsNull() then
    return
  end

  -- Check if caster is a real hero
  if not caster:IsRealHero() or caster:IsTempestDouble() then
    return
  end

  local healAmount = ability:GetSpecialValueFor("death_heal_base") + caster:GetMaxHealth() * 0.5
  local heroes = FindUnitsInRadius(
    caster:GetTeamNumber(),
    caster:GetAbsOrigin(),
    nil,
    ability:GetSpecialValueFor("death_heal_radius"),
    DOTA_UNIT_TARGET_TEAM_FRIENDLY,
    bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC),
    DOTA_UNIT_TARGET_FLAG_NONE,
    FIND_ANY_ORDER,
    false
  )

  heroes = iter(heroes)
  heroes:each(function (hero)
    hero:Heal(healAmount, ability)
  end)
end

-------------------------------------------------------------------------
-- Parts of Sacred Skull that should NOT stack with other Sacred Skulls

modifier_item_sacred_skull_non_stacking_stats = class(ModifierBaseClass)

function modifier_item_sacred_skull_non_stacking_stats:IsHidden()
  return true
end

function modifier_item_sacred_skull_non_stacking_stats:IsDebuff()
  return false
end

function modifier_item_sacred_skull_non_stacking_stats:IsPurgable()
  return false
end

function modifier_item_sacred_skull_non_stacking_stats:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MP_REGEN_AMPLIFY_PERCENTAGE, -- GetModifierMPRegenAmplify_Percentage
    MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,    -- GetModifierSpellAmplify_Percentage
  }
end

-- Doesn't stack with Kaya items and Bloodstone
function modifier_item_sacred_skull_non_stacking_stats:GetModifierMPRegenAmplify_Percentage()
  local parent = self:GetParent()
  if not parent:HasModifier("modifier_item_kaya") and not parent:HasModifier("modifier_item_yasha_and_kaya") and not parent:HasModifier("modifier_item_kaya_and_sange") and not parent:HasModifier("modifier_item_bloodstone_non_stacking_stats") then
    return self:GetAbility():GetSpecialValueFor("mana_regen_multiplier")
  end
  return 0
end

-- Doesn't stack with Kaya items and Bloodstone
function modifier_item_sacred_skull_non_stacking_stats:GetModifierSpellAmplify_Percentage()
  local parent = self:GetParent()
  if not parent:HasModifier("modifier_item_kaya") and not parent:HasModifier("modifier_item_yasha_and_kaya") and not parent:HasModifier("modifier_item_kaya_and_sange") and not parent:HasModifier("modifier_item_bloodstone_non_stacking_stats") then
    return self:GetAbility():GetSpecialValueFor("spell_amp")
  end
  return 0
end
