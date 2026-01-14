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
    self.cdr = ability:GetSpecialValueFor("cooldown_reduction")
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
  }
end

function modifier_item_nether_core:GetModifierHealthBonus()
  return self.health or self:GetAbility():GetSpecialValueFor("bonus_health")
end

function modifier_item_nether_core:GetModifierManaBonus()
  return self.mana or self:GetAbility():GetSpecialValueFor("bonus_mana")
end

function modifier_item_nether_core:GetModifierPercentageCooldown()
  -- Prevent stacking with Octarine Core and other Nether Cores
  if self:GetParent():HasModifier("modifier_item_octarine_core") or self:GetStackCount() ~= 2 then
    return 0
  end

  return self.cdr or self:GetAbility():GetSpecialValueFor("cooldown_reduction")
end

function modifier_item_nether_core:GetModifierConstantManaRegen()
  return self.mana_regen or self:GetAbility():GetSpecialValueFor("bonus_mana_regen")
end
