LinkLuaModifier( "modifier_item_nether_core", "items/nether_core.lua", LUA_MODIFIER_MOTION_NONE )

item_nether_core_1 = class(ItemBaseClass)
item_nether_core_2 = item_nether_core_1
item_nether_core_3 = item_nether_core_1
item_nether_core_4 = item_nether_core_1
item_nether_core_5 = item_nether_core_1

function item_nether_core_1:GetIntrinsicModifierName()
  return "modifier_item_nether_core"
end

--------------------------------------------------------------------------------

modifier_item_nether_core = class(ModifierBaseClass)

function modifier_item_nether_core:IsHidden()
  return true
end

function modifier_item_nether_core:IsDebuff()
  return false
end

function modifier_item_nether_core:IsPurgable()
  return false
end

function modifier_item_nether_core:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_nether_core:OnCreated()
  self:OnRefresh()
  if IsServer() then
    self:StartIntervalThink(0.3)
  end
end

function modifier_item_nether_core:OnRefresh()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.health = ability:GetSpecialValueFor("bonus_health")
    self.mana = ability:GetSpecialValueFor("bonus_mana")
    self.mana_regen = ability:GetSpecialValueFor("bonus_mana_regen")
    self.ability_cdr = ability:GetSpecialValueFor("ability_cooldown_reduction")
    self.item_cdr = ability:GetSpecialValueFor("item_cooldown_reduction")
    self.debuff_reduction = ability:GetSpecialValueFor("modifier_duration_decrease")
  end

  if IsServer() then
    self:OnIntervalThink()
  end
end

function modifier_item_nether_core:OnIntervalThink()
  if self:IsFirstItemInInventory() then
    self:SetStackCount(2)
  else
    self:SetStackCount(1)
  end
end

function modifier_item_nether_core:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_HEALTH_BONUS, -- GetModifierHealthBonus
    MODIFIER_PROPERTY_MANA_BONUS, -- GetModifierManaBonus
    MODIFIER_PROPERTY_COOLDOWN_PERCENTAGE, -- GetModifierPercentageCooldown
    MODIFIER_PROPERTY_MANA_REGEN_CONSTANT, -- GetModifierConstantManaRegen
    MODIFIER_PROPERTY_STATUS_RESISTANCE_CASTER, -- GetModifierStatusResistanceCaster
  }
end

function modifier_item_nether_core:GetModifierHealthBonus()
  return self.health or self:GetAbility():GetSpecialValueFor("bonus_health")
end

function modifier_item_nether_core:GetModifierManaBonus()
  return self.mana or self:GetAbility():GetSpecialValueFor("bonus_mana")
end

function modifier_item_nether_core:GetModifierPercentageCooldown(keys)
  -- Prevent stacking with Octarine Core and other Nether Cores -> Octarine Core has higher priority
  if self:GetParent():HasModifier("modifier_item_octarine_core") or self:GetStackCount() ~= 2 then
    return 0
  end

  local ability = keys.ability
  if ability and ability:IsItem() then
    return self.item_cdr or self:GetAbility():GetSpecialValueFor("item_cooldown_reduction")
  end

  return self.cdr or self:GetAbility():GetSpecialValueFor("ability_cooldown_reduction")
end

function modifier_item_nether_core:GetModifierConstantManaRegen()
  return self.mana_regen or self:GetAbility():GetSpecialValueFor("bonus_mana_regen")
end

function modifier_item_nether_core:GetModifierStatusResistanceCaster(keys)
  -- Prevent multiple Nether Cores stacking the debuff duration decrease
  if self:GetStackCount() ~= 2 then
    return 0
  end
  local ability = keys.inflictor
  if ability then
    -- Disable debuff duration decrease for items and passive abilities without cooldown
    if ability:IsItem() or (ability:IsPassive() and ability:GetCooldown(-1) == 0) then
      return 0
    end
  end
  return self.debuff_reduction -- positive values reduce debuff durations, negative values improve debuff durations (aka debuff amplification)
end
