mirana_arrow_oaa = class( AbilityBaseClass )

--------------------------------------------------------------------------------

if IsServer() then

  -- There are so many values passed to make sure we have values from time the arrow was sent and not on hit (may get level-up in meantime)
  function mirana_arrow_oaa:SendArrow(caster, position, direction, arrow_speed, arrow_width, arrow_range, arrow_data)
    local info =
    {
      Ability = self,
      EffectName = "particles/units/heroes/hero_mirana/mirana_spell_arrow.vpcf",
      vSpawnOrigin = caster:GetAbsOrigin() + (caster:GetForwardVector() * arrow_width),
      fDistance = arrow_range,
      fStartRadius = arrow_width,
      fEndRadius = arrow_width,
      Source = caster,
      bHasFrontalCone = false,
      bReplaceExisting = false,
      iUnitTargetTeam = self:GetAbilityTargetTeam(),
      iUnitTargetType = self:GetAbilityTargetType(),
      iUnitTargetFlags = self:GetAbilityTargetFlags(),
      bDeleteOnHit = true,
      vVelocity = direction * arrow_speed,
      bProvidesVision = true,
      iVisionRadius = arrow_data.arrow_vision,
      iVisionTeamNumber = caster:GetTeamNumber(),
      ExtraData = {
        arrow_min_stun = arrow_data.arrow_min_stun,
        arrow_max_stun = arrow_data.arrow_max_stun,
        arrow_max_stunrange = arrow_data.arrow_max_stunrange,
        arrow_bonus_damage = arrow_data.arrow_bonus_damage,
        arrow_base_damage = arrow_data.arrow_base_damage,
        arrow_damage_type = arrow_data.arrow_damage_type,
        arrow_vision = arrow_data.arrow_vision
      },
    }
    self.arrow_start_position = position
    return ProjectileManager:CreateLinearProjectile(info)
  end

  function mirana_arrow_oaa:OnProjectileHit_ExtraData(target, location, data)
    local caster = self:GetCaster()

    -- Target must exist and not be immune (to magic or in general)
    if target == nil or target:IsMagicImmune() or target:IsInvulnerable() then
      return false
    end

    -- Check if target is already affected by "STUNNED" from this ability (and caster) to prevent being hit by multiple arrows
    local stunned_modifier = FindModifierByNameAndCaster("modifier_stunned", caster)
    if stunned_modifier ~= nil then
      return false
    end

    -- Traveled distance limited to arrow_max_stunrange
    local arrow_traveled_distance = math.min( ( self.arrow_start_position - target:GetAbsOrigin() ):Length(), data.arrow_max_stunrange )
    -- Multiplier from 0.0 to 1.0 for Arrow's stun duration (and damage based on distance)
    local dist_mult = arrow_traveled_distance / data.arrow_max_stunrange

    -- Stun duration from arrow_min_stun to arrow_max_stun based on stun_mult
    local stun_duration = (data.arrow_max_stun - data.arrow_min_stun) * dist_mult + data.arrow_min_stun
    -- Stun
    target:AddNewModifier(caster, self, "modifier_stunned", {
      duration=stun_duration
    })

    -- Damage arrow_base_damage with damage based on traveled distance
    local damage = data.arrow_bonus_damage * dist_mult + data.arrow_base_damage

    -- Damage
    local damageTable = {
      victim = target,
      attacker = caster,
      damage = damage,
      damage_type = data.arrow_damage_type,
      --damage_flags = DOTA_DAMAGE_FLAG_NONE, --Optional.
      ability = self, --Optional.
    }
    ApplyDamage(damageTable)
      -- Add vision
  AddFOWViewer(caster:GetTeamNumber(), target:GetAbsOrigin(), data.arrow_vision, stun_duration, false)

    return true
  end

  function mirana_arrow_oaa:OnSpellStart()
    local caster = self:GetCaster()
    local position = caster:GetAbsOrigin()
    local direction = self:GetForwardVector()

    local arrow_speed = self:GetSpecialValueFor( "arrow_speed" ) -- Arrow travel speed
    local arrow_width = self:GetSpecialValueFor( "arrow_width" ) -- Arrow width
    local arrow_range = self:GetSpecialValueFor( "arrow_range" ) -- Maximum arrow range

    -- Global cast range applies to global range for the arrow too
    if caster:HasTalent("special_bonus_mirana_arrow_global") then
      arrow_range = caster:FindTalentValue("special_bonus_mirana_arrow_global", "projectile_range")
    end

    local arrow_data = {
      arrow_vision = self:GetSpecialValueFor( "arrow_vision" ),
      arrow_min_stun = self:GetSpecialValueFor( "arrow_min_stun" ), -- Minimum stun duration
      arrow_max_stun = self:GetSpecialValueFor( "arrow_max_stun" ), -- Maximum stun duration
      arrow_max_stunrange = self:GetSpecialValueFor( "arrow_max_stunrange" ), -- Range for maximum stun
      arrow_bonus_damage = self:GetSpecialValueFor( "arrow_bonus_damage" ), -- Maximum bonus damage
      arrow_base_damage = self:GetAbilityDamage(), -- Base damage
      arrow_damage_type = self:GetAbilityDamageType()
    }

    -- Send arrow
    self:SendArrow(caster, position, direction, arrow_speed, arrow_width, arrow_range, arrow_data)

    -- Send multishot arrows
    if caster:HasTalent("special_bonus_unique_mirana_2") then
      local arrow_multishot_angle = self:GetSpecialValueFor( "arrow_multishot_angle" )
      local talent_arrow_count = caster:FindTalentValue("special_bonus_unique_mirana_2")

      -- Send amount of additional arrows specified by the talent
      for i = 0, talent_arrow_count-1 do
        -- Angle multiplier to switch sides between right and left
        local angle_mult = 1;
        if i % 2 == 1 then
          angle_mult = -1
        end

        -- Arrows with indices 0,1 have same angle (also applies for 2,3 or 4,5...)
        local angle = ( math.floor(i / 2) + 1 ) * arrow_multishot_angle * angle_mult

        -- Rotate forward vector
        local direction_multishot = RotatePosition(Vector(0,0,0), QAngle(0, angle, 0), direction):Normalized()

        -- Send arrow
        self:SendArrow(caster, position, direction_multishot, arrow_speed, arrow_width, arrow_range, arrow_data)

      end
    end

  end

end

--------------------------------------------------------------------------------

function mirana_arrow_oaa:GetCooldown( level )
  local caster = self:GetCaster()

  local talent_cooldown_reduction = caster:FindTalentValue("special_bonus_unique_mirana_3")
  return self.BaseClass.GetCooldown( self, level ) - talent_cooldown_reduction
end

--------------------------------------------------------------------------------

-- Because we do not have the ability to retrieve it otherwise
--[[
function mirana_arrow_oaa:GetCastRangeIncrease()
local cast_range_increase = 0

-- Bonuses from items
for i = 0,5 do
  for item_name, item_bonus in pairs(CAST_RANGE_BONUSES_FROM_ITEMS) do
  if self:GetItemInSlot(i) and self:GetItemInSlot(i):GetName() == item_name then
    cast_range_increase = math.max(cast_range_increase, item_bonus)
  end
  end
end

-- Bonuses from talents
for _, cast_range_value in pairs(CAST_RANGE_TALENT_VALUES) do
  if self:FindAbilityByName("special_bonus_cast_range_"..cast_range_value) and self:FindAbilityByName("special_bonus_cast_range_"..cast_range_value):GetLevel() > 0 then
  cast_range_increase = cast_range_increase + cast_range_value
  end
end

return cast_range_increase
end
  ]]

function mirana_arrow_oaa:GetCastRange(location, target)
  local caster = self:GetCaster()

  if caster:HasTalent("special_bonus_mirana_arrow_global") then
    return caster:FindTalentValue("special_bonus_mirana_arrow_global", "cast_range")
  end

  return self.BaseClass.GetCastRange( self, location, target ) --+ self:GetCastRangeIncrease()
end
