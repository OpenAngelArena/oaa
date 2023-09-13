-- Boss Killer

modifier_boss_killer_oaa = class(ModifierBaseClass)

function modifier_boss_killer_oaa:IsHidden()
  return false
end

function modifier_boss_killer_oaa:IsDebuff()
  return false
end

function modifier_boss_killer_oaa:IsPurgable()
  return false
end

function modifier_boss_killer_oaa:RemoveOnDeath()
  return false
end

function modifier_boss_killer_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
    MODIFIER_PROPERTY_TOTAL_CONSTANT_BLOCK,
  }
end

function modifier_boss_killer_oaa:GetModifierTotalDamageOutgoing_Percentage(event)
  if event.target:IsOAABoss() then
    return 85
  end
  return 0
end

if IsServer() then
  function modifier_boss_killer_oaa:GetModifierTotal_ConstantBlock(event)
    local parent = self:GetParent()
    local attacker = event.attacker

    if not attacker or attacker:IsNull() then
      return 0
    end

    if attacker.IsBaseNPC == nil then
      return 0
    end

    if not attacker:IsBaseNPC() then
      return 0
    end

    local dmg_reduction = 50

    -- Block damage from from bosses
    if attacker:IsOAABoss() then
      return event.damage * dmg_reduction / 100
    end

    return 0
  end
end

function modifier_boss_killer_oaa:GetTexture()
  return "lone_druid_spirit_bear_demolish"
end
