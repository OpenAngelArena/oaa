---------------------------------------------------------------------------------------------------

modifier_bristleback_seeing_red_oaa = modifier_bristleback_seeing_red_oaa or class({})

function modifier_bristleback_seeing_red_oaa:IsHidden()
  return true
end

function modifier_bristleback_seeing_red_oaa:IsDebuff()
  return false
end

function modifier_bristleback_seeing_red_oaa:IsPurgable()
  return false
end

function modifier_bristleback_seeing_red_oaa:OnCreated()
  self.angle = 135

  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.angle = (360 - ability:GetSpecialValueFor("active_view_angle_restriction")) / 2
  end
end

modifier_bristleback_seeing_red_oaa.OnRefresh = modifier_bristleback_seeing_red_oaa.OnCreated

function modifier_bristleback_seeing_red_oaa:IsAura()
  return true
end

function modifier_bristleback_seeing_red_oaa:GetModifierAura()
  return "modifier_provides_vision_oaa"
end

function modifier_bristleback_seeing_red_oaa:GetAuraRadius()
  local parent = self:GetParent()
  return parent:GetCurrentVisionRange()
end

function modifier_bristleback_seeing_red_oaa:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_bristleback_seeing_red_oaa:GetAuraSearchType()
  return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
end

function modifier_bristleback_seeing_red_oaa:GetAuraSearchFlags()
  return DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE
end

function modifier_bristleback_seeing_red_oaa:GetAuraEntityReject(hEntity)
  local parent = self:GetParent()

  if parent.GetAnglesAsVector == nil then
    return false
  end

  -- The y value of the angles vector contains the angle we actually want: where units are directionally facing in the world.
  local victim_angle = parent:GetAnglesAsVector().y
  local origin_difference = parent:GetAbsOrigin() - hEntity:GetAbsOrigin()
  -- Get the radian of the origin difference between the hEntity and Bristleback. We use this to figure out at what angle the hEntity is at relative to Bristleback.
  local origin_difference_radian = math.atan2(origin_difference.y, origin_difference.x)
  -- Convert the radian to degrees.
  origin_difference_radian = origin_difference_radian * 180
  local entity_angle = origin_difference_radian / math.pi
  -- turn negative angles into positive ones and make the math simpler.
  entity_angle = entity_angle + 180.0
  -- Finally, get the angle at which Bristleback is facing the hEntity.
  local result_angle = entity_angle - victim_angle
  result_angle = math.abs(result_angle)

  return result_angle >= (180 - (self.angle / 2)) and result_angle <= (180 + (self.angle / 2))
end
