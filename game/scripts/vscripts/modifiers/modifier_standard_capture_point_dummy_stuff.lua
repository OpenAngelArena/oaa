modifier_standard_capture_point_dummy_stuff = class(ModifierBaseClass)

function modifier_standard_capture_point_dummy_stuff:IsHidden()
  return true
end

function modifier_standard_capture_point_dummy_stuff:IsDebuff()
  return false
end

function modifier_standard_capture_point_dummy_stuff:IsPurgable()
  return false
end

function modifier_standard_capture_point_dummy_stuff:OnCreated(keys)
  self.radius = CAPTURE_POINT_RADIUS or 300
end

function modifier_standard_capture_point_dummy_stuff:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
    MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
    MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
    MODIFIER_PROPERTY_BONUS_DAY_VISION,
    MODIFIER_PROPERTY_BONUS_NIGHT_VISION,
  }
end

function modifier_standard_capture_point_dummy_stuff:GetAbsoluteNoDamagePhysical()
  return 1
end

function modifier_standard_capture_point_dummy_stuff:GetAbsoluteNoDamageMagical()
  return 1
end

function modifier_standard_capture_point_dummy_stuff:GetAbsoluteNoDamagePure()
  return 1
end

function modifier_standard_capture_point_dummy_stuff:GetBonusDayVision()
  return self.radius
end

function modifier_standard_capture_point_dummy_stuff:GetBonusNightVision()
  return self.radius
end

function modifier_standard_capture_point_dummy_stuff:CheckState()
  local state = {
    [MODIFIER_STATE_UNSELECTABLE] = true,
    [MODIFIER_STATE_NOT_ON_MINIMAP] = true,
    [MODIFIER_STATE_NOT_ON_MINIMAP_FOR_ENEMIES] = true,
    [MODIFIER_STATE_NO_HEALTH_BAR] = true,
    [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
    [MODIFIER_STATE_OUT_OF_GAME] = true,
    [MODIFIER_STATE_NO_TEAM_MOVE_TO] = true,
    [MODIFIER_STATE_NO_TEAM_SELECT] = true,
    [MODIFIER_STATE_COMMAND_RESTRICTED] = true,
    [MODIFIER_STATE_ATTACK_IMMUNE] = true,
    [MODIFIER_STATE_MAGIC_IMMUNE] = true,
    [MODIFIER_STATE_FLYING] = true,
  }
  return state
end

-- TrueSight part:
function modifier_standard_capture_point_dummy_stuff:IsAura()
  return true
end

function modifier_standard_capture_point_dummy_stuff:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_standard_capture_point_dummy_stuff:GetAuraSearchType()
  return DOTA_UNIT_TARGET_HERO
end

function modifier_standard_capture_point_dummy_stuff:GetAuraSearchFlags()
  return bit.bor(DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, DOTA_UNIT_TARGET_FLAG_INVULNERABLE)
end

function modifier_standard_capture_point_dummy_stuff:GetModifierAura()
  return "modifier_truesight"
end

function modifier_standard_capture_point_dummy_stuff:GetAuraRadius()
  return self.radius
end
