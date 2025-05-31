LinkLuaModifier("modifier_morphling_innate_oaa", "abilities/oaa_morphling_innate.lua", LUA_MODIFIER_MOTION_NONE)

morphling_innate_oaa = class(AbilityBaseClass)

function morphling_innate_oaa:GetIntrinsicModifierName()
  return "modifier_morphling_innate_oaa"
end

---------------------------------------------------------------------------------------------------

modifier_morphling_innate_oaa = class(ModifierBaseClass)

function modifier_morphling_innate_oaa:IsHidden()
  return true
end

function modifier_morphling_innate_oaa:IsDebuff()
  return false
end

function modifier_morphling_innate_oaa:IsPurgable()
  return false
end

function modifier_morphling_innate_oaa:RemoveOnDeath()
  return false
end

function modifier_morphling_innate_oaa:OnCreated()
  self:OnRefresh()
  if IsServer() then
    self:StartIntervalThink(0.1)
  end
end

function modifier_morphling_innate_oaa:OnRefresh()
  local ability = self:GetAbility()
  if not ability or ability:IsNull() then
    return
  end

  self.bonus_to_primary_stat = ability:GetSpecialValueFor("bonus_primary_stat_per_level")
  self.bonus_to_secondary_stats = ability:GetSpecialValueFor("bonus_morphed_secondary_stats_per_level")
end

if IsServer() then
  function modifier_morphling_innate_oaa:OnIntervalThink()
    local parent = self:GetParent()

    if not parent or parent:IsNull() then
      self:StartIntervalThink(-1)
      return
    end

    -- Ignore Meepo clones
    if parent:IsClone() then
      self:StartIntervalThink(-1) -- dynamic clones still don't exist, so we can stop thinking
      self:SetStackCount(DOTA_ATTRIBUTE_MAX+1) -- don't grant STR, AGI or INT to clones
      return
    end

    local attribute = parent:GetPrimaryAttribute()
    if self:GetStackCount() ~= attribute then
      self:SetStackCount(attribute)
    end
  end
end

function modifier_morphling_innate_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
    MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
    MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
  }
end

function modifier_morphling_innate_oaa:GetModifierBonusStats_Strength()
  local parent = self:GetParent()
  local lvl = parent:GetLevel()
  local attribute = self:GetStackCount()
  if attribute == DOTA_ATTRIBUTE_STRENGTH or attribute == DOTA_ATTRIBUTE_ALL then
    return math.ceil(self.bonus_to_primary_stat * lvl)
  elseif attribute == DOTA_ATTRIBUTE_MAX+1 then
    return 0
  elseif parent:HasModifier("modifier_morphling_replicate") then
    return math.floor(self.bonus_to_secondary_stats * lvl)
  end
  return 0
end

function modifier_morphling_innate_oaa:GetModifierBonusStats_Agility()
  local parent = self:GetParent()
  local lvl = parent:GetLevel()
  local attribute = self:GetStackCount()
  if attribute == DOTA_ATTRIBUTE_AGILITY or attribute == DOTA_ATTRIBUTE_ALL then
    return math.ceil(self.bonus_to_primary_stat * lvl)
  elseif attribute == DOTA_ATTRIBUTE_MAX+1 then
    return 0
  elseif parent:HasModifier("modifier_morphling_replicate") then
    return math.floor(self.bonus_to_secondary_stats * lvl)
  end
  return 0
end

function modifier_morphling_innate_oaa:GetModifierBonusStats_Intellect()
  local parent = self:GetParent()
  local lvl = parent:GetLevel()
  local attribute = self:GetStackCount()
  if attribute == DOTA_ATTRIBUTE_INTELLECT or attribute == DOTA_ATTRIBUTE_ALL then
    return math.ceil(self.bonus_to_primary_stat * lvl)
  elseif attribute == DOTA_ATTRIBUTE_MAX+1 then
    return 0
  elseif parent:HasModifier("modifier_morphling_replicate") then
    return math.floor(self.bonus_to_secondary_stats * lvl)
  end
  return 0
end

