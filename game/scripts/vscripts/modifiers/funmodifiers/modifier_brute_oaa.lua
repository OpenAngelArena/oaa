
modifier_brute_oaa = class(ModifierBaseClass)

function modifier_brute_oaa:IsHidden()
  return false
end

function modifier_brute_oaa:IsDebuff()
  return false
end

function modifier_brute_oaa:IsPurgable()
  return false
end

function modifier_brute_oaa:RemoveOnDeath()
  return false
end

function modifier_brute_oaa:OnCreated()
  self.bonus_str_per_lvl = 1
  self.bonus_dmg_per_hp = 0.08

  if not IsServer() then
    return
  end

  -- local parent = self:GetParent()

  -- -- Check if parent has the stuff
  -- if parent.GetPrimaryAttribute == nil then
    -- return
  -- end

  -- local primary_attribute = parent:GetPrimaryAttribute()
  -- local new_primary_attribute
  -- if primary_attribute == DOTA_ATTRIBUTE_STRENGTH then
    -- if RandomInt(0, 1) == 0 then
      -- new_primary_attribute = DOTA_ATTRIBUTE_AGILITY
    -- else
      -- new_primary_attribute = DOTA_ATTRIBUTE_INTELLECT
    -- end
  -- else
    -- new_primary_attribute = DOTA_ATTRIBUTE_STRENGTH
  -- end

  -- -- Change Primary attribute
  -- parent:SetPrimaryAttribute(new_primary_attribute)
end

function modifier_brute_oaa:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
    MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
  }

  return funcs
end

function modifier_brute_oaa:GetModifierBonusStats_Strength()
  local parent = self:GetParent()
  return self.bonus_str_per_lvl * parent:GetLevel()
end

function modifier_brute_oaa:GetModifierPreAttack_BonusDamage()
  local parent = self:GetParent()
  return self.bonus_dmg_per_hp * parent:GetMaxHealth()
end

function modifier_brute_oaa:GetTexture()
  return "item_ogre_axe"
end
