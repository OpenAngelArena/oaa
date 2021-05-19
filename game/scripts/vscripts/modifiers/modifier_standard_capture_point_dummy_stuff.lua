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
  return 300
end

function modifier_standard_capture_point_dummy_stuff:GetBonusNightVision()
  return 300
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