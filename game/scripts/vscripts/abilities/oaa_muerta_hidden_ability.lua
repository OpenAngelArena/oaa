muerta_hidden_ability_oaa = class(AbilityBaseClass)

LinkLuaModifier("modifier_muerta_pierce_the_veil_penalty_oaa", "abilities/oaa_muerta_hidden_ability.lua", LUA_MODIFIER_MOTION_NONE)

function muerta_hidden_ability_oaa:Spawn()
  if IsServer() then
    self:SetLevel(1)
  end
end

function muerta_hidden_ability_oaa:GetIntrinsicModifierName()
  return "modifier_muerta_pierce_the_veil_penalty_oaa"
end

function muerta_hidden_ability_oaa:IsStealable()
  return false
end

function muerta_hidden_ability_oaa:ProcMagicStick()
  return false
end

---------------------------------------------------------------------------------------------------

modifier_muerta_pierce_the_veil_penalty_oaa = class({})

function modifier_muerta_pierce_the_veil_penalty_oaa:IsHidden()
  return true
end

function modifier_muerta_pierce_the_veil_penalty_oaa:IsDebuff()
  return false
end

function modifier_muerta_pierce_the_veil_penalty_oaa:IsPurgable()
  return false
end

function modifier_muerta_pierce_the_veil_penalty_oaa:RemoveOnDeath()
  return false
end

function modifier_muerta_pierce_the_veil_penalty_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE,
  }
end

function modifier_muerta_pierce_the_veil_penalty_oaa:GetModifierDamageOutgoing_Percentage()
  if self:GetParent():HasModifier("modifier_muerta_pierce_the_veil_buff") then
    return 0 - self:GetAbility():GetSpecialValueFor("damage_penalty")
  end
end
