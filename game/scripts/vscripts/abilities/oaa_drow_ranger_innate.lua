-- Precision Aura

LinkLuaModifier("modifier_drow_ranger_innate_oaa", "abilities/oaa_drow_ranger_innate.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_drow_ranger_innate_oaa_aura_effect", "abilities/oaa_drow_ranger_innate.lua", LUA_MODIFIER_MOTION_NONE)

drow_ranger_innate_oaa = class(AbilityBaseClass)

function drow_ranger_innate_oaa:GetIntrinsicModifierName()
  return "modifier_drow_ranger_innate_oaa"
end

---------------------------------------------------------------------------------------------------

modifier_drow_ranger_innate_oaa = class(ModifierBaseClass)

function modifier_drow_ranger_innate_oaa:IsHidden()
  return true
end

function modifier_drow_ranger_innate_oaa:IsDebuff()
  return false
end

function modifier_drow_ranger_innate_oaa:IsPurgable()
  return false
end

function modifier_drow_ranger_innate_oaa:RemoveOnDeath()
  return false
end

function modifier_drow_ranger_innate_oaa:IsAura()
  local parent = self:GetParent()
  if parent:PassivesDisabled() or parent:IsIllusion() then
    return false
  end
  return true
end

function modifier_drow_ranger_innate_oaa:AllowIllusionDuplicate()
	return false -- probably does nothing
end

function modifier_drow_ranger_innate_oaa:GetModifierAura()
	return "modifier_drow_ranger_innate_oaa_aura_effect"
end

function modifier_drow_ranger_innate_oaa:GetAuraRadius()
  return self:GetAbility():GetSpecialValueFor("radius")
end

function modifier_drow_ranger_innate_oaa:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_drow_ranger_innate_oaa:GetAuraSearchType()
  return DOTA_UNIT_TARGET_HERO
end

function modifier_drow_ranger_innate_oaa:GetAuraSearchFlags()
  return DOTA_UNIT_TARGET_FLAG_RANGED_ONLY
end

---------------------------------------------------------------------------------------------------

modifier_drow_ranger_innate_oaa_aura_effect = class(ModifierBaseClass)

function modifier_drow_ranger_innate_oaa_aura_effect:IsHidden() -- needs tooltip
  return false
end

function modifier_drow_ranger_innate_oaa_aura_effect:IsDebuff()
  return false
end

function modifier_drow_ranger_innate_oaa_aura_effect:IsPurgable()
  return false
end

function modifier_drow_ranger_innate_oaa_aura_effect:OnCreated()
  self.lock = false

	self:StartIntervalThink(0.1)
end

function modifier_drow_ranger_innate_oaa_aura_effect:OnRefresh()
  self:OnIntervalThink()
end

function modifier_drow_ranger_innate_oaa_aura_effect:OnIntervalThink()
  local parent = self:GetParent()
  local caster = self:GetCaster()
  local ability = self:GetAbility()

  -- Check if needed parameters exist
  if not ability or ability:IsNull() or not caster or caster:IsNull() then
    return
  end

  if parent ~= caster then
    -- Parent is an ally of the aura owner,
    -- stuff is easier

    -- Get caster's (aura owner's) agility
    local agility = caster:GetAgility()

    -- Get caster's (aura owner's) level
    local lvl = caster:GetLevel()

    -- Get multiplier
    local mult = ability:GetSpecialValueFor("trueshot_agi_bonus_allies")

    -- Calculate bonus agility for the parent
    self.agi = math.ceil(lvl * agility * mult / 100)
  else
    -- Parent is the caster (aura owner)
    -- We need to avoid recursion

    -- Get caster's (aura owner's) level
    local lvl = caster:GetLevel()

    -- Get multiplier
    local mult = ability:GetSpecialValueFor("trueshot_agi_bonus_self")

    -- Calculate agility multiplier
    self.agi_mult = lvl * mult / 100
  end
end

function modifier_drow_ranger_innate_oaa_aura_effect:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
    MODIFIER_PROPERTY_TOOLTIP,
  }
end

function modifier_drow_ranger_innate_oaa_aura_effect:GetModifierBonusStats_Agility()
  local parent = self:GetParent()
  local caster = self:GetCaster()
  if parent ~= caster then
    return self.agi
  else
    if self.lock then
      return 0
    else
      -- To avoid recursion we lock right before getting AGI to get the unmodified value
      self.lock = true
      local agility = caster:GetAgility()
      self.lock = false
      self.agi = math.ceil(self.agi_mult * agility)
      return self.agi
    end
  end
end

function modifier_drow_ranger_innate_oaa_aura_effect:OnTooltip()
	local caster = self:GetCaster()
  if not caster or caster:IsNull() or caster:PassivesDisabled() then
		return 0
	end
	return self.agi
end
