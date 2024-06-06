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
    MODIFIER_PROPERTY_SPELLS_REQUIRE_HP, -- doesnt work properly, thx Valve
    MODIFIER_EVENT_ON_ABILITY_EXECUTED, -- reinventing Health Cost
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
  -- On Client: it shows mana cost x this number as health cost
  -- On Server: it doesnt spend health for most spells, but at least it turns mana cost per second into health per second x this number for some spells
  return 2.25
end

-- Reinventing Amplified Health Cost that is not affected by magic resist
if IsServer() then
  function modifier_blood_magic_oaa:OnAbilityExecuted(event)
    local parent = self:GetParent()

    local cast_ability = event.ability
    local caster = event.unit

    -- Check if caster has this modifier
    if caster ~= parent then
      return
    end

    if not cast_ability then
      return
    end

    local mana_cost = cast_ability:GetManaCost(-1)
    local self_damage = mana_cost * 2.25
    local damage_table = {
      attacker = parent,
      victim = parent,
      damage = self_damage,
      damage_type = DAMAGE_TYPE_PURE,
      damage_flags = DOTA_DAMAGE_FLAG_HPLOSS + DOTA_DAMAGE_FLAG_REFLECTION + DOTA_DAMAGE_FLAG_NON_LETHAL + DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION + DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL + DOTA_DAMAGE_FLAG_NO_DAMAGE_MULTIPLIERS,
      ability = cast_ability
    }
    ApplyDamage(damage_table)
  end
end

function modifier_blood_magic_oaa:GetTexture()
  return "custom/blood_magic"
end
