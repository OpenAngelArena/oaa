
modifier_legion_commander_duel_damage_oaa_ardm = modifier_legion_commander_duel_damage_oaa_ardm or class({})

function modifier_legion_commander_duel_damage_oaa_ardm:IsHidden()
  return false -- needs tooltip
end

function modifier_legion_commander_duel_damage_oaa_ardm:IsDebuff()
  return false
end
function modifier_legion_commander_duel_damage_oaa_ardm:IsPurgable()
  return false
end

function modifier_legion_commander_duel_damage_oaa_ardm:RemoveOnDeath()
  return false
end

function modifier_legion_commander_duel_damage_oaa_ardm:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE
  }
end

function modifier_legion_commander_duel_damage_oaa_ardm:GetModifierPreAttack_BonusDamage()
  return self:GetStackCount()
end

function modifier_legion_commander_duel_damage_oaa_ardm:GetTexture()
  return "legion_commander_duel"
end
