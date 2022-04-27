modifier_generic_vision_dummy_stuff = class(ModifierBaseClass)

function modifier_generic_vision_dummy_stuff:IsHidden()
  return true
end

function modifier_generic_vision_dummy_stuff:IsDebuff()
  return false
end

function modifier_generic_vision_dummy_stuff:IsPurgable()
  return false
end

function modifier_generic_vision_dummy_stuff:OnCreated(event)
  self.radius = 800
  self.unobstructed = true
  self.truesight = false
end

function modifier_generic_vision_dummy_stuff:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_BONUS_DAY_VISION,
    MODIFIER_PROPERTY_BONUS_NIGHT_VISION,
  }
end

function modifier_generic_vision_dummy_stuff:GetBonusDayVision()
  return self.radius
end

function modifier_generic_vision_dummy_stuff:GetBonusNightVision()
  return self.radius
end

function modifier_generic_vision_dummy_stuff:CheckState()
  local state = {
    [MODIFIER_STATE_FORCED_FLYING_VISION] = self.unobstructed,
  }
  return state
end

-- TrueSight part:
function modifier_generic_vision_dummy_stuff:IsAura()
  return self.truesight
end

function modifier_generic_vision_dummy_stuff:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_generic_vision_dummy_stuff:GetAuraSearchType()
  return DOTA_UNIT_TARGET_HERO
end

function modifier_generic_vision_dummy_stuff:GetAuraSearchFlags()
  return bit.bor(DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, DOTA_UNIT_TARGET_FLAG_INVULNERABLE)
end

function modifier_generic_vision_dummy_stuff:GetModifierAura()
  return "modifier_truesight"
end

function modifier_generic_vision_dummy_stuff:GetAuraRadius()
  return self.radius
end
