
modifier_moonshard_consumed_oaa_ardm = modifier_moonshard_consumed_oaa_ardm or class({})

function modifier_moonshard_consumed_oaa_ardm:IsHidden()
  if self:GetParent():HasModifier("modifier_item_moon_shard_consumed") then
    return true
  end
  return false -- needs tooltip
end

function modifier_moonshard_consumed_oaa_ardm:IsDebuff()
  return false
end

function modifier_moonshard_consumed_oaa_ardm:IsPurgable()
  return false
end

function modifier_moonshard_consumed_oaa_ardm:RemoveOnDeath()
  return false
end

function modifier_moonshard_consumed_oaa_ardm:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
    MODIFIER_PROPERTY_BONUS_NIGHT_VISION,
  }
end

function modifier_moonshard_consumed_oaa_ardm:GetModifierAttackSpeedBonus_Constant()
  if self:GetParent():HasModifier("modifier_item_moon_shard_consumed") then
    return 0
  end
  return 70
end

function modifier_moonshard_consumed_oaa_ardm:GetBonusNightVision()
  if self:GetParent():HasModifier("modifier_item_moon_shard_consumed") then
    return 0
  end
  return 200
end

function modifier_moonshard_consumed_oaa_ardm:GetTexture()
  return "item_moon_shard"
end
