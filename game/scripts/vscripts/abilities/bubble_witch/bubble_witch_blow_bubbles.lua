bubble_witch_blow_bubbles = bubble_witch_blow_bubbles or class({})

LinkLuaModifier("modifier_bubble_witch_blow_bubbles_caster", "abilities/bubble_witch/bubble_witch_blow_bubbles.lua", LUA_MODIFIER_MOTION_NONE) -- needs tooltip
LinkLuaModifier("modifier_bubble_witch_blow_bubbles_ally", "abilities/bubble_witch/bubble_witch_blow_bubbles.lua", LUA_MODIFIER_MOTION_NONE) -- needs tooltip
LinkLuaModifier("modifier_bubble_witch_blow_bubbles_enemy", "abilities/bubble_witch/bubble_witch_blow_bubbles.lua", LUA_MODIFIER_MOTION_NONE) -- needs tooltip

function bubble_witch_blow_bubbles:OnSpellStart()
  local caster = self:GetCaster()
  local target_loc =  self:GetCursorPosition()

  -- Remove previous instance
  caster:RemoveModifierByName("modifier_bubble_witch_blow_bubbles_caster")

  -- Change facing if directional casting doesn't work
  caster:FaceTowards(target_loc)

  -- New buff instance
  caster:AddNewModifier(caster, self, "modifier_bubble_witch_blow_bubbles_caster", {duration = self:GetSpecialValueFor("duration")})

  -- Sound
  caster:EmitSound("Bubble_Witch.Blow_Bubbles.Cast")
  caster:EmitSound("Bubble_Witch.Blow_Bubbles.Loop")
end

---------------------------------------------------------------------------------------------------

modifier_bubble_witch_blow_bubbles_caster = modifier_bubble_witch_blow_bubbles_caster or class({})

function modifier_bubble_witch_blow_bubbles_caster:IsHidden()
  return false
end

function modifier_bubble_witch_blow_bubbles_caster:IsDebuff()
  return false
end

function modifier_bubble_witch_blow_bubbles_caster:IsPurgable()
  return false
end

function  modifier_bubble_witch_blow_bubbles_caster:FindUnitsinTrapezoid(team_number, vDirection, start_position, start_radius, end_radius, distance, cache_unit, target_team, target_type, target_flags, order, cache)
	if cache == nil then
		cache = false
	end
	if not order then
		order = FIND_ANY_ORDER
	end
	if not target_flags then
		target_flags = DOTA_UNIT_TARGET_FLAG_NONE
	end
	local circle = FindUnitsInRadius(team_number, start_position, cache_unit, distance+end_radius, target_team, target_type, target_flags, order, cache)
	local direction = vDirection
	direction.z = 0.0
	direction = direction:Normalized()
	local perpendicular_direction = Vector(direction.y, -direction.x, 0.0)
	local end_position = start_position + direction*distance

	-- Trapezoid vertexes
	local vertex1 = start_position - perpendicular_direction*start_radius
	local vertex2 = start_position + perpendicular_direction*start_radius
	local vertex3 = end_position - perpendicular_direction*end_radius
	local vertex4 = end_position + perpendicular_direction*end_radius

	-- Trapezoid sides (vectors)
	local vector1 = vertex2 - vertex1	-- vector12
	local vector2 = vertex4 - vertex2	-- vector24
	local vector3 = vertex3 - vertex4	-- vector43
	local vector4 = vertex1 - vertex3	-- vector31

	local unit_table = {}
	for _, unit in pairs(circle) do
		if unit then
			local unit_location = unit:GetAbsOrigin()
			local vector1p = unit_location - vertex1
			local vector2p = unit_location - vertex2
			local vector3p = unit_location - vertex3
			local vector4p = unit_location - vertex4
			local cross1 = vector1.x * vector1p.y - vector1.y * vector1p.x
			local cross2 = vector2.x * vector2p.y - vector2.y * vector2p.x
			local cross3 = vector3.x * vector4p.y - vector3.y * vector4p.x
			local cross4 = vector4.x * vector3p.y - vector4.y * vector3p.x
			if (cross1 > 0 and cross2 > 0 and cross3 > 0 and cross4 > 0) or (cross1 < 0 and cross2 < 0 and cross3 < 0 and cross4 < 0) then
				table.insert(unit_table, unit) -- unit is inside
			end
			if unit_location == vertex1 or unit_location == vertex2 or unit_location == vertex3 or unit_location == vertex4 then
				table.insert(unit_table, unit) -- unit is on the vertex
			end
			if cross1 == 0 or cross2 == 0 or cross3 == 0 or cross4 == 0 then
				table.insert(unit_table, unit) -- unit is on the edge
			end
		end
	end
	return unit_table
end

function modifier_bubble_witch_blow_bubbles_caster:OnCreated()
  if IsServer() then
    self:OnIntervalThink()
    self:StartIntervalThink(1)
  end
end

function modifier_bubble_witch_blow_bubbles_caster:OnIntervalThink()
  local parent = self:GetParent()
  local ability = self:GetAbility()
  local parent_team = parent:GetTeamNumber()
  local parent_loc = parent:GetAbsOrigin()

  local projectile_name = "particles/units/heroes/hero_puck/puck_illusory_orb_linear_projectile.vpcf"
  local distance = ability:GetSpecialValueFor("cone_distance") + parent:GetCastRangeBonus()
  local start_radius = ability:GetSpecialValueFor("cone_starting_width")
  local end_radius = ability:GetSpecialValueFor("cone_ending_width")
  local extend_duration = ability:GetSpecialValueFor("extend_duration_per_hit")
  local speed = distance
  local direction = parent:GetForwardVector()
  direction.z = 0
  direction = direction:Normalized()

  local perpendicular_direction = Vector(direction.y, -direction.x, 0.0)
  local start_position = parent_loc
  local end_position = start_position + direction*distance

  -- Outward vertexes
  local vertex3 = end_position - perpendicular_direction*end_radius
  local vertex4 = end_position + perpendicular_direction*end_radius

  -- Directions, distances, speeds
  local direction2 = vertex3 - start_position
  local direction3 = vertex4 - start_position
  local distance2 = direction2:Length2D()
  local distance3 = direction3:Length2D()
  local speed2 = distance2
  local speed3 = distance3
  direction2.z = 0
  direction2 = direction2:Normalized()
  direction3.z = 0
  direction3 = direction3:Normalized()

  local info = {
    Source = parent,
    Ability = ability,
    vSpawnOrigin = parent_loc,
    bDeleteOnHit = false,
    --iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_BOTH,
    --iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
    --iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
    EffectName = projectile_name,
    fDistance = distance,
    fStartRadius = start_radius,
    fEndRadius = 1,
    vVelocity = direction * speed,
  }
  local info2 = {
    Source = parent,
    Ability = ability,
    vSpawnOrigin = parent_loc,
    bDeleteOnHit = false,
    --iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_BOTH,
    --iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
    --iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
    EffectName = projectile_name,
    fDistance = distance2,
    fStartRadius = 1,
    fEndRadius = 1,
    vVelocity = direction2 * speed2,
  }
  local info3 = {
    Source = parent,
    Ability = ability,
    vSpawnOrigin = parent_loc,
    bDeleteOnHit = false,
    --iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_BOTH,
    --iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
    --iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
    EffectName = projectile_name,
    fDistance = distance3,
    fStartRadius = 1,
    fEndRadius = 1,
    vVelocity = direction3 * speed3,
  }

  ProjectileManager:CreateLinearProjectile(info)
  ProjectileManager:CreateLinearProjectile(info2)
  ProjectileManager:CreateLinearProjectile(info3)

  local units_in_cone = self:FindUnitsinTrapezoid(
    parent_team,
    direction,
    parent_loc,
    start_radius,
    end_radius,
    distance,
    nil,
    DOTA_UNIT_TARGET_TEAM_BOTH,
    DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
    DOTA_UNIT_TARGET_FLAG_NONE,
    FIND_ANY_ORDER,
    false
  )

  local damage_table = {
    attacker = parent,
    damage = ability:GetSpecialValueFor("dps"),
    damage_type = ability:GetAbilityDamageType(),
    ability = ability,
  }
  for _, unit in pairs(units_in_cone) do
    if unit and not unit:IsNull() and unit ~= parent then
      if unit:GetTeamNumber() == parent_team then
        -- Ally
        unit:AddNewModifier(parent, ability, "modifier_bubble_witch_blow_bubbles_ally", {duration = ability:GetSpecialValueFor("buff_duration")})
        local magic_bubble_buff = unit:FindModifierByNameAndCaster("modifier_bubble_witch_magic_bubble_buff", parent)
        if magic_bubble_buff then
          local remain = magic_bubble_buff:GetRemainingTime()
          magic_bubble_buff:SetDuration(remain + extend_duration, true)
        end
      else
        -- Enemy
        unit:AddNewModifier(parent, ability, "modifier_bubble_witch_blow_bubbles_enemy", {duration = ability:GetSpecialValueFor("debuff_duration")})
        local cavitation_debuff = unit:FindModifierByNameAndCaster("modifier_bubble_witch_cavitation_debuff", parent)
        if cavitation_debuff then
          local remain = cavitation_debuff:GetRemainingTime()
          cavitation_debuff:SetDuration(remain + extend_duration, true)
        end
        damage_table.victim = unit
        ApplyDamage(damage_table)
      end
    end
  end
end

function modifier_bubble_witch_blow_bubbles_caster:OnDestroy()
  if IsServer() then
    self:GetParent():StopSound("Bubble_Witch.Blow_Bubbles.Loop")
  end
end

function modifier_bubble_witch_blow_bubbles_caster:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_IGNORE_CAST_ANGLE,
    MODIFIER_PROPERTY_DISABLE_TURNING,
  }
end

function modifier_bubble_witch_blow_bubbles_caster:GetModifierIgnoreCastAngle()
  return 1
end


function modifier_bubble_witch_blow_bubbles_caster:GetModifierDisableTurning()
  return 1
end

-- function modifier_bubble_witch_blow_bubbles_caster:GetEffectName()
  -- return
-- end

-- function modifier_bubble_witch_blow_bubbles_caster:GetEffectAttachType()
  -- return PATTACH_ABSORIGIN_FOLLOW
-- end

---------------------------------------------------------------------------------------------------

modifier_bubble_witch_blow_bubbles_ally = modifier_bubble_witch_blow_bubbles_ally or class({})

function modifier_bubble_witch_blow_bubbles_ally:IsHidden()
  return false
end

function modifier_bubble_witch_blow_bubbles_ally:IsDebuff()
  return false
end

function modifier_bubble_witch_blow_bubbles_ally:IsPurgable()
  return true
end

function modifier_bubble_witch_blow_bubbles_ally:OnCreated()
  local ability = self:GetAbility()
  local parent = self:GetParent()
  if ability and not ability:IsNull() then
    self.move_speed_bonus_per_stack = ability:GetSpecialValueFor("move_speed_increase_per_second")
    self.shield_increase_per_stack = ability:GetSpecialValueFor("shield_per_second")
    self.multiplier = ability:GetSpecialValueFor("shield_multiplier_in_bubble_of_protection")
    self.max_shield_hp = self.shield_increase_per_stack * (ability:GetSpecialValueFor("duration") + 1) * self.multiplier
  end

  if IsServer() then
    self:SetStackCount(1)
    self.current_shield = self.shield_increase_per_stack
    if parent:HasModifier("modifier_bubble_witch_bubble_of_protection_buff") then
      self.current_shield = self.shield_increase_per_stack * self.multiplier
    end
    self:SetHasCustomTransmitterData(true)
  end
end

function modifier_bubble_witch_blow_bubbles_ally:OnRefresh()
  local ability = self:GetAbility()
  local parent = self:GetParent()
  if ability and not ability:IsNull() then
    self.move_speed_bonus_per_stack = ability:GetSpecialValueFor("move_speed_increase_per_second")
    self.shield_increase_per_stack = ability:GetSpecialValueFor("shield_per_second")
    self.multiplier = ability:GetSpecialValueFor("shield_multiplier_in_bubble_of_protection")
    self.max_shield_hp = self.shield_increase_per_stack * (ability:GetSpecialValueFor("duration") + 1) * self.multiplier
  end

  if IsServer() then
    self:IncrementStackCount()
    if parent:HasModifier("modifier_bubble_witch_bubble_of_protection_buff") then
      self.current_shield = self.current_shield + self.shield_increase_per_stack * self.multiplier
    else
      self.current_shield = math.max(self.current_shield + self.shield_increase_per_stack, self.shield_increase_per_stack * self:GetStackCount())
    end
    self:SendBuffRefreshToClients()
  end
end

if IsServer() then
  function modifier_bubble_witch_blow_bubbles_ally:OnDestroy()
    local parent = self:GetParent()
    local caster = self:GetCaster()

    if not caster or caster:IsNull() then
      return
    end

    local innate = caster:FindAbilityByName("bubble_witch_innate")
    if not innate or innate:IsNull() then
      return
    end

    -- If owner is affected by break, do nothing
    if caster:PassivesDisabled() then
      return
    end

    if not parent or parent:IsNull() then
      return
    end

    if parent:IsAlive() then
      parent:AddNewModifier(caster, innate, "modifier_bubble_witch_innate_buff_oaa", {duration = 0.1})
    end
  end
end

-- server-only function that is called whenever SetHasCustomTransmitterData(true) or SendBuffRefreshToClients() is called
function modifier_bubble_witch_blow_bubbles_ally:AddCustomTransmitterData()
  return {
    current_shield = self.current_shield,
  }
end

-- client-only function that is called with the table returned by AddCustomTransmitterData()
function modifier_bubble_witch_blow_bubbles_ally:HandleCustomTransmitterData(data)
  self.current_shield = data.current_shield
end

function modifier_bubble_witch_blow_bubbles_ally:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    MODIFIER_PROPERTY_INCOMING_DAMAGE_CONSTANT,
  }
end

function modifier_bubble_witch_blow_bubbles_ally:GetModifierMoveSpeedBonus_Percentage()
  return math.abs(self:GetStackCount() * self.move_speed_bonus_per_stack)
end

function modifier_bubble_witch_blow_bubbles_ally:GetModifierIncomingDamageConstant(event)
  if IsClient() then
    if event.report_max then
      return self.max_shield_hp
    else
      return self.current_shield -- current shield hp
    end
  else
    local parent = self:GetParent()
    local damage = event.damage
    local barrier_hp = math.abs(self.current_shield)

    -- Don't block more than remaining hp
    local block_amount = math.min(damage, barrier_hp)

    -- Reduce barrier hp (using negative stacks to not show them on the buff)
    self.current_shield = barrier_hp - block_amount

    self:SendBuffRefreshToClients()

    if block_amount > 0 then
      -- Visual effect
      SendOverheadEventMessage(nil, OVERHEAD_ALERT_BLOCK, parent, block_amount, nil)
    end

    -- Remove the barrier if hp is reduced to nothing
    if self.current_shield <= 0 then
      self:Destroy()
    end

    return -block_amount
  end
end

function modifier_bubble_witch_blow_bubbles_ally:GetEffectName()
  return "particles/generic_gameplay/rune_shield_bubble.vpcf"
end

function modifier_bubble_witch_blow_bubbles_ally:GetEffectAttachType()
  return PATTACH_ABSORIGIN_FOLLOW
end

---------------------------------------------------------------------------------------------------

modifier_bubble_witch_blow_bubbles_enemy = modifier_bubble_witch_blow_bubbles_enemy or class({})

function modifier_bubble_witch_blow_bubbles_enemy:IsHidden()
  return false
end

function modifier_bubble_witch_blow_bubbles_enemy:IsDebuff()
  return true
end

function modifier_bubble_witch_blow_bubbles_enemy:IsPurgable()
  return true
end

function modifier_bubble_witch_blow_bubbles_enemy:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.move_speed_slow_per_stack = ability:GetSpecialValueFor("move_speed_slow_per_second")
  end

  if IsServer() then
    self:SetStackCount(1)
  end
end

function modifier_bubble_witch_blow_bubbles_enemy:OnRefresh()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.move_speed_slow_per_stack = ability:GetSpecialValueFor("move_speed_slow_per_second")
  end

  if IsServer() then
    self:IncrementStackCount()
  end
end

function modifier_bubble_witch_blow_bubbles_enemy:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
  }
end

function modifier_bubble_witch_blow_bubbles_enemy:GetModifierMoveSpeedBonus_Percentage()
  return 0 - math.abs(self:GetStackCount() * self.move_speed_slow_per_stack)
end

-- function modifier_bubble_witch_blow_bubbles_enemy:GetEffectName()
  -- return
-- end

-- function modifier_bubble_witch_blow_bubbles_enemy:GetEffectAttachType()
  -- return PATTACH_ABSORIGIN_FOLLOW
-- end
