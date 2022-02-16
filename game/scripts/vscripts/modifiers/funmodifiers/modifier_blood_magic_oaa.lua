modifier_blood_magic_oaa = class(ModifierBaseClass)

function modifier_blood_magic_oaa:IsHidden()
  return false
end

function modifier_blood_magic_oaa:IsDebuff()
  return false
end

function modifier_blood_magic_oaa:IsPurgable()
  return false
end

function modifier_blood_magic_oaa:RemoveOnDeath()
  return false
end

function modifier_blood_magic_oaa:OnCreated()
  local parent = self:GetParent()
  self.bonus_hp = parent:GetMaxMana()
  self.bonus_hp_regen = parent:GetManaRegen()
  if IsServer() and parent:IsHero() then
    parent:CalculateStatBonus(true)
  end
  self:StartIntervalThink(0.5)
end

function modifier_blood_magic_oaa:OnRefresh()
  local parent = self:GetParent()
  self.bonus_hp = parent:GetMaxMana()
  self.bonus_hp_regen = parent:GetManaRegen()
  if IsServer() and parent:IsHero() then
    parent:CalculateStatBonus(true)
  end
end

function modifier_blood_magic_oaa:OnIntervalThink()
  local parent = self:GetParent()
  self.bonus_hp = self.bonus_hp + parent:GetMaxMana()
  self.bonus_hp_regen = parent:GetManaRegen()
  if IsServer() and parent:IsHero() then
    parent:CalculateStatBonus(true)
  end
end

function modifier_blood_magic_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_HEALTH_BONUS,
    MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
    MODIFIER_PROPERTY_MANA_BONUS,
    MODIFIER_PROPERTY_SPELLS_REQUIRE_HP,
  }
end

function modifier_blood_magic_oaa:GetModifierHealthBonus()
  if self.bonus_hp then
    return self.bonus_hp
  end

  return 0
end

function modifier_blood_magic_oaa:GetModifierConstantHealthRegen()
  if self.bonus_hp_regen then
    return self.bonus_hp_regen
  end

  return 0
end

function modifier_blood_magic_oaa:GetModifierManaBonus()
  if self.bonus_hp then
    return -self.bonus_hp
  end

  return 0
end

function modifier_blood_magic_oaa:GetModifierSpellsRequireHP()
  return 1
end

function modifier_blood_magic_oaa:GetTexture()
  return "custom/blood_magic"
end
