modifier_suppress_cleave_oaa = class(ModifierBaseClass)

function modifier_suppress_cleave_oaa:IsHidden()
  return true
end

function modifier_suppress_cleave_oaa:IsDebuff()
  return false
end

function modifier_suppress_cleave_oaa:IsPurgable()
  return false
end

function modifier_suppress_cleave_oaa:RemoveOnDeath()
  return true
end

function modifier_suppress_cleave_oaa:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_suppress_cleave_oaa:DeclareFunctions()
  return {
    --MODIFIER_PROPERTY_SUPPRESS_CLEAVE, -- does not work
    MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
  }
end

-- function modifier_suppress_cleave_oaa:GetSuppressCleave()
  -- return 1
-- end

function modifier_suppress_cleave_oaa:GetModifierTotalDamageOutgoing_Percentage(params)
  local inflictor = params.inflictor
  local dmg_flags = params.damage_flags

  -- Vanilla cleaves should have an inflictor
  if not inflictor or inflictor:IsNull() then
    return 0
  end

  -- Vanilla cleaves are physical dmg
  if params.damage_type ~= DAMAGE_TYPE_PHYSICAL then
    return 0
  end

  -- Vanilla cleaves are 'spell' dmg
  if params.damage_category ~= DOTA_DAMAGE_CATEGORY_SPELL then
    return 0
  end

  -- Vanilla cleaves only have 1 dmg flag (dmg_flags = 1024) but we should try to make it future-proof
  if bit.band(dmg_flags, DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION) > 0 then
    return -100
  end
end
