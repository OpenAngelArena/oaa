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
  self.bonus_hp = parent:GetMaxMana() - 75
  self.bonus_hp_regen = parent:GetManaRegen()
  self.bonus_mana = 0 - self.bonus_hp
  if IsServer() and parent:IsHero() then
    parent:CalculateStatBonus(true)
    self:StartIntervalThink(0.5)
  end
end

function modifier_blood_magic_oaa:OnIntervalThink()
  local parent = self:GetParent()
  self.bonus_hp = math.max(self.bonus_hp + parent:GetMaxMana(), 0) - 75
  self.bonus_hp_regen = math.max(parent:GetManaRegen(), 0)
  self.bonus_mana = 0 - self.bonus_hp
  if IsServer() and parent:IsHero() then
    parent:CalculateStatBonus(true)
  end
end

function modifier_blood_magic_oaa:OnDestroy()
  local parent = self:GetParent()
  if IsServer() and parent and parent:IsHero() then
    parent:CalculateStatBonus(true)
    parent:GiveMana(self.bonus_hp + 75)
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

function modifier_blood_magic_oaa:GetModifierConstantHealthRegen()
  if self.bonus_hp_regen then
    return self.bonus_hp_regen
  end

  return 0
end

if IsServer() then
  function modifier_blood_magic_oaa:GetModifierHealthBonus()
    return self.bonus_hp
  end
  function modifier_blood_magic_oaa:GetModifierManaBonus()
    return self.bonus_mana
  end
end

function modifier_blood_magic_oaa:GetModifierSpellsRequireHP()
  return 2.25
end

function modifier_blood_magic_oaa:GetTexture()
  return "custom/blood_magic"
end
