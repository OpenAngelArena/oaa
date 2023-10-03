-- Moriah's Shield

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
    --MODIFIER_PROPERTY_MANA_BONUS,
    MODIFIER_PROPERTY_TOTAL_CONSTANT_BLOCK,
    MODIFIER_PROPERTY_INCOMING_DAMAGE_CONSTANT,
  }
end

function modifier_hp_mana_switch_oaa:GetModifierSpellsRequireHP()
  return 1
end

--[[
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
]]

if IsServer() then
  function modifier_hp_mana_switch_oaa:GetModifierTotal_ConstantBlock(event)
    -- Do nothing if damage has HP removal flag
    if bit.band(event.damage_flags, DOTA_DAMAGE_FLAG_HPLOSS) == DOTA_DAMAGE_FLAG_HPLOSS then
      return 0
    end

    local parent = self:GetParent()
    local mana = parent:GetMana()
    local block_amount = math.min(event.damage * 0.5, mana)

    parent:ReduceMana(block_amount, nil)

    if block_amount > 0 then
      SendOverheadEventMessage(nil, OVERHEAD_ALERT_BLOCK, parent, block_amount, nil)
    end

    return block_amount
  end
end

function modifier_hp_mana_switch_oaa:GetModifierIncomingDamageConstant(event)
  local parent = self:GetParent()
  if IsClient() then
    local max_mana = parent:GetMaxMana()
    local current_mana = parent:GetMana()
    if event.report_max then
      return max_mana -- max shield hp
    else
      return current_mana -- current shield hp
    end
  else
    return 0
  end
end

function modifier_hp_mana_switch_oaa:GetTexture()
  return "medusa_mana_shield"
end
