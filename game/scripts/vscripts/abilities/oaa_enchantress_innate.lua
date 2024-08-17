-- Forest Warden

LinkLuaModifier("modifier_enchantress_innate_oaa", "abilities/oaa_enchantress_innate.lua", LUA_MODIFIER_MOTION_NONE)

enchantress_innate_oaa = class(AbilityBaseClass)

function enchantress_innate_oaa:GetIntrinsicModifierName()
  return "modifier_enchantress_innate_oaa"
end

---------------------------------------------------------------------------------------------------

modifier_enchantress_innate_oaa = class(ModifierBaseClass)

function modifier_enchantress_innate_oaa:IsHidden()
  return true
end

function modifier_enchantress_innate_oaa:IsDebuff()
  return false
end

function modifier_enchantress_innate_oaa:IsPurgable()
  return false
end

function modifier_enchantress_innate_oaa:RemoveOnDeath()
  return false
end

function modifier_enchantress_innate_oaa:OnCreated()
  local ability = self:GetAbility()
  self.dmg_amp = ability:GetSpecialValueFor("bonus_dmg_amp_near_neutrals")
  self.radius = ability:GetSpecialValueFor("radius")

  if IsServer() then
    self:StartIntervalThink(0.1)
  end
end

function modifier_enchantress_innate_oaa:OnIntervalThink()
  local parent = self:GetParent()

  if parent:PassivesDisabled() then
    self:SetStackCount(0)
    return
  end

  local enemies = FindUnitsInRadius(
    parent:GetTeamNumber(),
    parent:GetAbsOrigin(),
    nil,
    self.radius,
    DOTA_UNIT_TARGET_TEAM_ENEMY,
    bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC),
    DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
    FIND_ANY_ORDER,
    false
  )

  local near_neutrals = false
  for _, enemy in pairs(enemies) do
    if enemy and not enemy:IsNull() and enemy.HasModifier then
      if enemy:GetTeamNumber() == DOTA_TEAM_NEUTRALS and not enemy:HasModifier("modifier_oaa_thinker") then
        near_neutrals = true
        break
      end
    end
  end

  if near_neutrals then
    self:SetStackCount(-1)
  else
    self:SetStackCount(0)
  end
end

function modifier_enchantress_innate_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
  }
end

function modifier_enchantress_innate_oaa:GetModifierTotalDamageOutgoing_Percentage()
  if self:GetStackCount() == -1 then
    return self.dmg_amp
  end
  return 0
end
