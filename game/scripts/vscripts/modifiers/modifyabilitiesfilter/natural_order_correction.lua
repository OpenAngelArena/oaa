---------------------------------------------------------------------------------------------------

modifier_elder_titan_natural_order_correction_oaa = modifier_elder_titan_natural_order_correction_oaa or class({})

function modifier_elder_titan_natural_order_correction_oaa:IsHidden()
  return true
end

function modifier_elder_titan_natural_order_correction_oaa:IsDebuff()
  return true
end

function modifier_elder_titan_natural_order_correction_oaa:IsPurgable()
  return false
end

function modifier_elder_titan_natural_order_correction_oaa:OnCreated()
  if IsServer() then
    self:SetStackCount(1)
    self:StartIntervalThink(0)
  end
end

function modifier_elder_titan_natural_order_correction_oaa:OnIntervalThink()
  local parent = self:GetParent()
  -- Remove this debuff if parent is not affected by Natural Order or if spell-immune
  if not parent:HasModifier("modifier_elder_titan_natural_order_magic_resistance") or parent:IsMagicImmune() then
    self:StartIntervalThink(-1)
    self:Destroy()
    return
  end

  local ability = self:GetAbility()
  if not ability or ability:IsNull() then
    return
  end

  local base_magic_resist = parent:GetBaseMagicalResistanceValue()
  local ability_level = ability:GetLevel()
  -- Natural Order works correctly for the first 4 levels:
  if ability_level < 5 then
    self:StartIntervalThink(-1)
    self:Destroy()
    return
  end

  local magic_resist_reduction = ability:GetLevelSpecialValueFor("magic_resistance_pct", ability_level - 1)
  -- Natural Order works correctly if reduction is 100% or below
  if magic_resist_reduction <= 100 then
    self:StartIntervalThink(-1)
    self:Destroy()
    return
  end

  local magic_resist = math.ceil(math.abs(base_magic_resist * (1 - math.abs(magic_resist_reduction) / 100)))
  -- Something is seriously wrong with stacking negative magic resistance and I don't know what
  -- The UI sometimes doesn't show the correct values, let's hope that the damage amplification is correct

  -- Don't set stack count if already set to the same number
  if self:GetStackCount() ~= magic_resist then
    self:SetStackCount(magic_resist)
  end
end

function modifier_elder_titan_natural_order_correction_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
  }
end

function modifier_elder_titan_natural_order_correction_oaa:GetModifierMagicalResistanceBonus()
  return 0 - self:GetStackCount()
end
