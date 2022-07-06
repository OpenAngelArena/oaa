modifier_hp_mana_switch_oaa = class(ModifierBaseClass)

function modifier_hp_mana_switch_oaa:IsHidden()
  return false
end

function modifier_hp_mana_switch_oaa:IsDebuff()
  return true
end

function modifier_hp_mana_switch_oaa:IsPurgable()
  return false
end

function modifier_hp_mana_switch_oaa:RemoveOnDeath()
  return false
end

function modifier_hp_mana_switch_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_SPELLS_REQUIRE_HP,
    --MODIFIER_PROPERTY_MIN_HEALTH,
    MODIFIER_PROPERTY_MANA_BONUS,
    MODIFIER_EVENT_ON_TAKEDAMAGE,
  }
end

function modifier_hp_mana_switch_oaa:GetModifierSpellsRequireHP()
  return 1
end

function modifier_hp_mana_switch_oaa:GetModifierManaBonus()
  if self:GetParent():GetPrimaryAttribute() ~= DOTA_ATTRIBUTE_INTELLECT then
    return 500
  end
end

function modifier_hp_mana_switch_oaa:GetMinHealth()
  if self:GetParent():GetMana() > 1 then
    return 1
  else
    return 0
  end
end

if IsServer() then
  function modifier_hp_mana_switch_oaa:OnTakeDamage(event)
    local parent = self:GetParent()
    local attacker = event.attacker
    local damaged_unit = event.unit
    local dmg_flags = event.damage_flags
    local damage = event.damage

    -- Check if attacker exists
    if not attacker or attacker:IsNull() then
      return
    end

    -- Check if damaged entity exists
    if not damaged_unit or damaged_unit:IsNull() then
      return
    end

    -- Check if damaged entity has this modifier
    if damaged_unit ~= parent then
      return
    end

    -- Ignore self damage
    --if attacker == parent then
      --return
    --end

    -- Ignore damage with no-reflect flag
    --if bit.band(dmg_flags, DOTA_DAMAGE_FLAG_REFLECTION) > 0 then
      --return
    --end

    -- Ignore damage with HP removal flag
    if bit.band(dmg_flags, DOTA_DAMAGE_FLAG_HPLOSS) > 0 then
      return
    end

    -- Ignore damage with no-spell-amplification flag
    --if bit.band(dmg_flags, DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION) > 0 then
      --return
    --end

    -- Ignore 0 or negative damage
    if damage <= 0 then
      return
    end

    local mana = parent:GetMana()
    if damage >= mana then
      parent:Kill(nil, attacker)
    else
      parent:ReduceMana(damage)
      parent:Heal(damage, nil)
    end
  end
end

function modifier_hp_mana_switch_oaa:GetTexture()
  return "custom/blood_magic"
end
