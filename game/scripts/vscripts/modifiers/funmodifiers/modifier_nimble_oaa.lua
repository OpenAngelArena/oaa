modifier_nimble_oaa = class(ModifierBaseClass)

function modifier_nimble_oaa:IsHidden()
  return false
end

function modifier_nimble_oaa:IsDebuff()
  return false
end

function modifier_nimble_oaa:IsPurgable()
  return false
end

function modifier_nimble_oaa:RemoveOnDeath()
  return false
end

function modifier_nimble_oaa:OnCreated()
  self.bonus_agi_per_lvl = 2
  self.bonus_ms_per_agi = 0.08
  self.bonus_evasion_per_agi = 0.05
end

function modifier_nimble_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
    MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    MODIFIER_PROPERTY_EVASION_CONSTANT,
    MODIFIER_PROPERTY_IGNORE_MOVESPEED_LIMIT,
    MODIFIER_PROPERTY_IGNORE_ATTACKSPEED_LIMIT,
  }
end

function modifier_nimble_oaa:GetModifierBonusStats_Agility()
  local parent = self:GetParent()
  return self.bonus_agi_per_lvl * parent:GetLevel()
end

function modifier_nimble_oaa:GetModifierMoveSpeedBonus_Percentage()
  local parent = self:GetParent()
  return self.bonus_ms_per_agi * parent:GetAgility()
end

function modifier_nimble_oaa:GetModifierEvasion_Constant()
  local parent = self:GetParent()
  return self.bonus_evasion_per_agi * parent:GetAgility()
end

function modifier_nimble_oaa:GetModifierIgnoreMovespeedLimit()
  return 1
end

-- Maybe Valve will change this some day into GetModifierIgnoreAttackspeedLimit ...
function modifier_nimble_oaa:GetModifierAttackSpeed_Limit()
  return 1
end

function modifier_nimble_oaa:GetTexture()
  return "item_blade_of_alacrity"
end
