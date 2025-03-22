
modifier_outworld_attack_oaa = class(ModifierBaseClass)

function modifier_outworld_attack_oaa:IsHidden()
  return false
end

function modifier_outworld_attack_oaa:IsDebuff()
  return false
end

function modifier_outworld_attack_oaa:IsPurgable()
  return false
end

function modifier_outworld_attack_oaa:RemoveOnDeath()
  return false
end

function modifier_outworld_attack_oaa:OnCreated()
  self.bonus_dmg_per_current_mana = 15
end

function modifier_outworld_attack_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
  }
end

function modifier_outworld_attack_oaa:GetModifierPreAttack_BonusDamage()
  local parent = self:GetParent()
  return self.bonus_dmg_per_current_mana * parent:GetMana() * 0.01
end

function modifier_outworld_attack_oaa:GetTexture()
  return "obsidian_destroyer_arcane_orb"
end
