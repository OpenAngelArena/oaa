
modifier_generic_bonus = class({})

--[[

  "04"
  {
    "var_type"        "FIELD_INTEGER"
    "bonus_health"        "4000"
  }
  "05"
  {
    "var_type"        "FIELD_INTEGER"
    "bonus_armor"     "20"
  }
  "06"
  {
    "var_type"        "FIELD_INTEGER"
    "magic_resistance"    "20"
  }
]]

function modifier_generic_bonus:OnCreated()
  self:Setup()
end
function modifier_generic_bonus:OnRefresh()
  self:Setup()
end

function modifier_generic_bonus:Setup()
  local attributesToCheck = {
    'bonus_health',
    'bonus_armor',
    'magic_resistance',
  }

  local ability = self:GetAbility()

  for i,name in ipairs(attributesToCheck) do
    local value = ability:GetSpecialValueFor(name)
    if value ~= nil then
      self[name] = value
    end
  end
end

function modifier_generic_bonus:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_HEALTH_BONUS,
    MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
    MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS
  }
end

function modifier_generic_bonus:GetModifierHealthBonus()
  return self.bonus_health or 0
end

function modifier_generic_bonus:GetModifierPhysicalArmorBonus()
  return self.bonus_armor or 0
end

function modifier_generic_bonus:GetModifierMagicalResistanceBonus()
  return self.magic_resistance or 0
end

function modifier_generic_bonus:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_generic_bonus:IsHidden()
  return true
end
function modifier_generic_bonus:IsDebuff()
  return false
end
function modifier_generic_bonus:IsPurgable()
  return false
end
