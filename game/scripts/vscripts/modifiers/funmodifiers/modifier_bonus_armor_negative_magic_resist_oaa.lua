-- Guardian's Weakness

modifier_bonus_armor_negative_magic_resist_oaa = class(ModifierBaseClass)

function modifier_bonus_armor_negative_magic_resist_oaa:IsHidden()
  return false
end

function modifier_bonus_armor_negative_magic_resist_oaa:IsDebuff()
  return false
end

function modifier_bonus_armor_negative_magic_resist_oaa:IsPurgable()
  return false
end

function modifier_bonus_armor_negative_magic_resist_oaa:RemoveOnDeath()
  local parent = self:GetParent()
  if parent:IsRealHero() and not parent:IsOAABoss() then
    return false
  end
  return true
end

function modifier_bonus_armor_negative_magic_resist_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
    MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
  }
end

function modifier_bonus_armor_negative_magic_resist_oaa:GetModifierPhysicalArmorBonus()
  return 200
end

function modifier_bonus_armor_negative_magic_resist_oaa:GetModifierMagicalResistanceBonus()
  return -200
end

function modifier_bonus_armor_negative_magic_resist_oaa:GetEffectName()
  return "particles/units/heroes/hero_omniknight/omniknight_guardian_angel_omni.vpcf"
end

function modifier_bonus_armor_negative_magic_resist_oaa:GetEffectAttachType()
  return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_bonus_armor_negative_magic_resist_oaa:GetStatusEffectName()
  return "particles/status_fx/status_effect_ghost.vpcf"
end

function modifier_bonus_armor_negative_magic_resist_oaa:StatusEffectPriority()
  return MODIFIER_PRIORITY_SUPER_ULTRA
end

function modifier_bonus_armor_negative_magic_resist_oaa:GetTexture()
  return "omniknight_guardian_angel" --"bane_enfeeble"
end
