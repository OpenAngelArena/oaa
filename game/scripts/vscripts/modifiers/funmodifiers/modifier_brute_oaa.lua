
modifier_brute_oaa = class(ModifierBaseClass)

function modifier_brute_oaa:IsHidden()
  return false
end

function modifier_brute_oaa:IsDebuff()
  return false
end

function modifier_brute_oaa:IsPurgable()
  return false
end

function modifier_brute_oaa:RemoveOnDeath()
  return false
end

function modifier_brute_oaa:OnCreated()
  self.bonus_str_per_lvl = 2
  self.bonus_dmg_per_hp = 0.05
end

function modifier_brute_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
    MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
  }
end

function modifier_brute_oaa:GetModifierBonusStats_Strength()
  local parent = self:GetParent()
  return self.bonus_str_per_lvl * parent:GetLevel()
end

function modifier_brute_oaa:GetModifierPreAttack_BonusDamage()
  local parent = self:GetParent()
  return self.bonus_dmg_per_hp * parent:GetMaxHealth()
end

function modifier_brute_oaa:GetTexture()
  return "item_ogre_axe"
end
