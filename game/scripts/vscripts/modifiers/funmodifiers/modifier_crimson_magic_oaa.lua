modifier_crimson_magic_oaa = class(ModifierBaseClass)

function modifier_crimson_magic_oaa:IsHidden()
  return false
end

function modifier_crimson_magic_oaa:IsDebuff()
  return false
end

function modifier_crimson_magic_oaa:IsPurgable()
  return false
end

function modifier_crimson_magic_oaa:RemoveOnDeath()
  return false
end

function modifier_crimson_magic_oaa:OnCreated()
  self.bonus_spell_amp_per_health = 0.008
end

function modifier_crimson_magic_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
  }
end

function modifier_crimson_magic_oaa:GetModifierSpellAmplify_Percentage()
  local parent = self:GetParent()
  return self.bonus_spell_amp_per_health * parent:GetMaxHealth()
end

function modifier_crimson_magic_oaa:GetTexture()
  return "item_vitality_booster"
end
