LinkLuaModifier("modifier_mirana_arrow_stun_oaa", "abilities/oaa_mirana_arrow.lua", LUA_MODIFIER_MOTION_NONE)

mirana_arrow_oaa = class( AbilityBaseClass )

--------------------------------------------------------------------------------

-- client side function
function mirana_arrow_oaa:CastFilterResultTarget (unit)
  if unit == self:GetCaster() then
    return UF_SUCCESS
  end
  return UF_FAIL_INVALID_LOCATION
end

if IsServer() then
  -- There are so many values passed (in arrow_data) to make sure we have values from time the arrow was sent and not on hit (may get level-up in meantime)
  function mirana_arrow_oaa:SendArrow(caster, position, direction, arrow_data)
    local pid = self.next_projectile_id or 0
    if self.next_projectile_id then
      self.next_projectile_id = self.next_projectile_id + 1
    else
      self.next_projectile_id = 1
    end

    local spawn_origin = position + (direction * arrow_data.arrow_start_distance)
    if self:IsStolen() then
      spawn_origin = position
    end

    local info =
    {
      Ability = self,
      EffectName = "particles/units/heroes/hero_mirana/mirana_spell_arrow.vpcf",
      vSpawnOrigin = spawn_origin,
      fDistance = arrow_data.arrow_range + caster:GetCastRangeBonus(),
      fStartRadius = arrow_data.arrow_width,
      fEndRadius = arrow_data.arrow_width,
      Source = caster,
      bHasFrontalCone = false,
      bReplaceExisting = false,
      iUnitTargetTeam = self:GetAbilityTargetTeam(),
      iUnitTargetType = self:GetAbilityTargetType(),
      iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, --DOTA_UNIT_TARGET_FLAG_NONE
      bDeleteOnHit = true,
      vVelocity = direction * arrow_data.arrow_speed,
      bProvidesVision = true,
      iVisionRadius = arrow_data.arrow_vision,
      iVisionTeamNumber = caster:GetTeamNumber(),
      ExtraData = {
        pid = pid,
        arrow_min_stun = arrow_data.arrow_min_stun,
        arrow_max_stun = arrow_data.arrow_max_stun,
        arrow_max_stunrange = arrow_data.arrow_max_stunrange,
        arrow_bonus_damage = arrow_data.arrow_bonus_damage,
        arrow_base_damage = arrow_data.arrow_base_damage,
        arrow_damage_type = arrow_data.arrow_damage_type,
        arrow_vision = arrow_data.arrow_vision,
        arrow_vision_duration = arrow_data.arrow_vision_duration,
        multishot_arrow = arrow_data.multishot_arrow
      },
    }
    ProjectileManager:CreateLinearProjectile(info)

    if not self.arrow_start_position then
      self.arrow_start_position = {}
    end
    self.arrow_start_position[pid] = position

    if not self.arrow_hit_count then
      self.arrow_hit_count = {}
    end
    self.arrow_hit_count[pid] = arrow_data.arrow_pierce_count
  end

  function mirana_arrow_oaa:OnProjectileHit_ExtraData(target, location, data)
    local caster = self:GetCaster()
    local pid = data.pid

    -- Target must exist and arrow still has hit count
    if target == nil or not self.arrow_hit_count[pid] or self.arrow_hit_count[pid] < 0 then
      self.arrow_start_position[pid] = nil
      self.arrow_hit_count[pid] = nil
      return true -- End the arrow
    end

    -- Check if target is already affected by "STUNNED" from this ability (and caster) to prevent being hit by multiple arrows
    local stunned_modifier = target:FindModifierByNameAndCaster("modifier_mirana_arrow_stun_oaa", caster)
    if not stunned_modifier or (stunned_modifier and data.multishot_arrow == 0) then
      -- Decrease the hit counter
      self.arrow_hit_count[pid] = self.arrow_hit_count[pid] - 1
      -- Kill non-ancient creeps instantly (doesn't matter if they are spell-immune)
      if target:IsCreep() and (not target:IsConsideredHero()) and (not target:IsAncient()) then
        target:Kill(self, caster)
      elseif not target:IsMagicImmune() then
        -- Traveled distance limited to arrow_max_stunrange
        local arrow_traveled_distance = math.min( (self.arrow_start_position[pid] - target:GetAbsOrigin()):Length2D(), data.arrow_max_stunrange)

        -- Multiplier from 0.0 to 1.0 for Arrow's stun duration (and damage based on distance)
        local dist_mult = arrow_traveled_distance / data.arrow_max_stunrange

        -- Stun duration from arrow_min_stun to arrow_max_stun based on stun_mult
        local stun_duration = (data.arrow_max_stun - data.arrow_min_stun) * dist_mult + data.arrow_min_stun

        -- Status resistance fix
        stun_duration = target:GetValueChangedByStatusResistance(stun_duration)

        -- Apply Stun before damage (Applying stun after damage is bad)
        target:AddNewModifier(caster, self, "modifier_mirana_arrow_stun_oaa", {duration = stun_duration})

        -- Damage arrow_base_damage with damage based on traveled distance
        local damage = data.arrow_bonus_damage * dist_mult + data.arrow_base_damage

        -- Damage table
        local damage_table = {}
        damage_table.victim = target
        damage_table.attacker = caster
        damage_table.damage = damage
        damage_table.ability = self
        damage_table.damage_type = data.arrow_damage_type

        ApplyDamage(damage_table)

        local starfall_ability = caster:FindAbilityByName("mirana_starfall")
        if caster:HasScepter() and starfall_ability and starfall_ability:GetLevel() > 0 then
          -- Hard-coded secondary star: starts 0.8 seconds after primary star, takes 0.57 seconds to fall
          local particle_delay = 0.8
          local damage_delay = particle_delay + 0.57
          local star_damage = starfall_ability:GetLevelSpecialValueFor("damage", starfall_ability:GetLevel()-1)
          local secondary_star_damage_reduction = starfall_ability:GetSpecialValueFor("secondary_starfall_damage_percent")
          -- Check for Starfall bonus damage talent
          -- local starfall_damage_talent = caster:FindAbilityByName("special_bonus_unique_mirana_7")
          -- if starfall_damage_talent and starfall_damage_talent:GetLevel() > 0 then
            -- star_damage = star_damage + 250
          -- end
          damage_table.damage = star_damage*secondary_star_damage_reduction*0.01
          damage_table.ability = starfall_ability
          damage_table.damage_type = DAMAGE_TYPE_MAGICAL

          Timers:CreateTimer(particle_delay, function()
            if target and not target:IsNull() and target:IsAlive() and not target:IsMagicImmune() and not target:IsInvulnerable() then
              -- Particle -- "particles/econ/items/mirana/mirana_starstorm_bow/mirana_starstorm_starfall_attack.vpcf"
              local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_mirana/mirana_starfall_attack.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
              ParticleManager:SetParticleControl(particle, 0, target:GetAbsOrigin())
              ParticleManager:SetParticleControl(particle, 1, target:GetAbsOrigin())
              ParticleManager:SetParticleControl(particle, 3, target:GetAbsOrigin())
              ParticleManager:ReleaseParticleIndex(particle)
            end
          end)

          Timers:CreateTimer(damage_delay, function()
            if target and not target:IsNull() and target:IsAlive() and not target:IsMagicImmune() and not target:IsInvulnerable() then
              -- Sound on hit unit
              target:EmitSound("Hero_Mirana.Starstorm.Impact") -- Ability.StarfallImpact

              -- Damage
              ApplyDamage(damage_table)
            end
          end)
        end
      end
    end

    -- Add vision
    AddFOWViewer(caster:GetTeamNumber(), target:GetAbsOrigin(), data.arrow_vision, data.arrow_vision_duration, false)

    -- Add hit sound
    target:EmitSound("Hero_Mirana.ArrowImpact")

    if self.arrow_hit_count[pid] < 0 then
      self.arrow_start_position[pid] = nil
      self.arrow_hit_count[pid] = nil
      return true -- End arrow
    else
      return false -- Do not end
    end
  end

  function mirana_arrow_oaa:OnProjectileThink_ExtraData(location, data)
    local caster = self:GetCaster()
    -- If caster doesn't have scepter don't do anything
    if not caster:HasScepter() then
      return
    end

    if not location then
      return
    end

    local starfall_ability = caster:FindAbilityByName("mirana_starfall")

    -- Rubick stole Arrow but he doesn't have Starfall - sorry Rubick
    if not starfall_ability then
      return
    end

    -- Rubick stole Arrow while Starfall is in use - edge case
    if starfall_ability:IsNull() then
      return
    end

    if starfall_ability:GetLevel() > 0 then
      local damage = starfall_ability:GetLevelSpecialValueFor("damage", starfall_ability:GetLevel()-1)
      local radius = starfall_ability:GetSpecialValueFor("starfall_radius") or data.arrow_vision

      -- Check for Starfall bonus damage talent
      -- local starfall_damage_talent = caster:FindAbilityByName("special_bonus_unique_mirana_7")
      -- if starfall_damage_talent and starfall_damage_talent:GetLevel() > 0 then
        -- damage = damage + 250
      -- end

      local candidates = FindUnitsInRadius(
        caster:GetTeamNumber(),
        location,
        nil,
        radius,
        DOTA_UNIT_TARGET_TEAM_ENEMY,
        bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC),
        DOTA_UNIT_TARGET_FLAG_NO_INVIS,
        FIND_CLOSEST,
        false
      )

      -- No targets around, don't continue
      if #candidates <= 0 then
        return
      end

      -- Damage table constants
      local damage_table = {}
      damage_table.attacker = caster
      damage_table.damage = damage
      damage_table.ability = starfall_ability
      damage_table.damage_type = DAMAGE_TYPE_MAGICAL

      -- Loop through candidates and damage units that are not hit already
      for _, unit in pairs(candidates) do
        if unit and not self.starfall_hit[unit:entindex()] then
          self.starfall_hit[unit:entindex()] = true

          -- Reveal the unit
          AddFOWViewer(caster:GetTeamNumber(), unit:GetAbsOrigin(), data.arrow_vision, data.arrow_vision_duration, false)

          -- Particle on hit unit -- "particles/econ/items/mirana/mirana_starstorm_bow/mirana_starstorm_starfall_attack.vpcf"
          local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_mirana/mirana_starfall_attack.vpcf", PATTACH_ABSORIGIN_FOLLOW, unit)
          ParticleManager:SetParticleControl(particle, 0, unit:GetAbsOrigin())
          ParticleManager:SetParticleControl(particle, 1, unit:GetAbsOrigin())
          ParticleManager:SetParticleControl(particle, 3, unit:GetAbsOrigin())
          ParticleManager:ReleaseParticleIndex(particle)

          -- Delay is hard-coded in normal dota to 0.57 seconds
          local delay = 0.57
          Timers:CreateTimer(delay, function()
            if unit and not unit:IsNull() and unit:IsAlive() and not unit:IsMagicImmune() and not unit:IsInvulnerable() then
              -- Sound on hit unit
              unit:EmitSound("Hero_Mirana.Starstorm.Impact") -- Ability.StarfallImpact

              -- Do damage
              damage_table.victim = unit
              ApplyDamage(damage_table)
            end
          end)
        end
      end
    end
  end

  function mirana_arrow_oaa:OnSpellStart()
    local caster = self:GetCaster()
    local position = caster:GetAbsOrigin()
    local direction = caster:GetForwardVector()

    local cursor_position = self:GetCursorPosition()
    local target = self:GetCursorTarget()

    local target_position
    if target then
      if target == caster then
        -- Reverse cast direction for doubletap cast (self cast)
        direction = direction * -1
      else
        target_position = target:GetAbsOrigin()
      end
    elseif cursor_position then
      if cursor_position == position then
        -- Reverse cast direction for self point cast
        direction = direction * -1
      else
        target_position = cursor_position
      end
    else
      return
    end

    if self:IsStolen() and target_position then
      -- Stolen Arrow direction is sometimes messed up, so we calculate it just in case
      direction = (target_position - position):Normalized()
    end
    -- Maximum arrow range
    local arrow_range = self:GetSpecialValueFor("arrow_range")
    -- Global cast range talent
    local talent1 = caster:FindAbilityByName("special_bonus_mirana_arrow_global")
    if talent1 and talent1:GetLevel() > 0 then
      arrow_range = talent1:GetSpecialValueFor("projectile_range")
    end

    local arrow_data = {
      arrow_start_distance = self:GetSpecialValueFor( "arrow_start_distance" ), -- Arrow start distance from caster
      arrow_speed = self:GetSpecialValueFor( "arrow_speed" ), -- Arrow travel speed
      arrow_width = self:GetSpecialValueFor( "arrow_width" ), -- Arrow width
      arrow_range = arrow_range, -- Maximum arrow range
      arrow_min_stun = self:GetSpecialValueFor( "arrow_min_stun" ), -- Minimum stun duration
      arrow_max_stun = self:GetSpecialValueFor( "arrow_max_stun" ), -- Maximum stun duration
      arrow_max_stunrange = self:GetSpecialValueFor( "arrow_max_stunrange" ), -- Range for maximum stun
      arrow_bonus_damage = self:GetSpecialValueFor( "arrow_bonus_damage" ), -- Maximum bonus damage
      arrow_base_damage = self:GetAbilityDamage(), -- Base damage
      arrow_damage_type = self:GetAbilityDamageType(),
      arrow_vision = self:GetSpecialValueFor( "arrow_vision" ), -- Arrow vision radius
      arrow_vision_duration = self:GetSpecialValueFor( "arrow_vision_duration" ), -- Vision duration after hit
      arrow_pierce_count = self:GetSpecialValueFor("arrow_pierce_count"), -- Pierce targets count
      multishot_arrow = 0 -- 0 for false, 1 for true
    }

    if caster:HasScepter() then
      self.starfall_hit = {}
    end

    -- Arrow cast sound
    caster:EmitSound("Hero_Mirana.ArrowCast")

    -- Send arrow
    self:SendArrow(caster, position, direction, arrow_data)

    -- Multishot arrows talent
    local talent2 = caster:FindAbilityByName("special_bonus_unique_mirana_2")
    if talent2 and talent2:GetLevel() > 0 then
      local arrow_multishot_angle = self:GetSpecialValueFor("arrow_multishot_angle")
      local talent_arrow_count = talent2:GetSpecialValueFor("value")

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

        -- Mark this arrow as a multishot arrow
        arrow_data.multishot_arrow = 1

        -- Send arrow
        self:SendArrow(caster, position, direction_multishot, arrow_data)
      end
    end
  end
end

--------------------------------------------------------------------------------

function mirana_arrow_oaa:GetCooldown( level )
  local base_cd = self.BaseClass.GetCooldown( self, level )

  -- Talent that reduces cooldown
  local talent = self:GetCaster():FindAbilityByName("special_bonus_unique_mirana_3")
  if talent and talent:GetLevel() > 0 then
    return base_cd - math.abs(talent:GetSpecialValueFor("value"))
  end

  return base_cd
end

--------------------------------------------------------------------------------

function mirana_arrow_oaa:GetCastRange(location, target)
  -- Talent that gives global range
  local talent = self:GetCaster():FindAbilityByName("special_bonus_mirana_arrow_global")
  if talent and talent:GetLevel() > 0 then
    return talent:GetSpecialValueFor("cast_range")
  end

  return self.BaseClass.GetCastRange( self, location, target )
end

---------------------------------------------------------------------------------------------------

modifier_mirana_arrow_stun_oaa = class(ModifierBaseClass)

function modifier_mirana_arrow_stun_oaa:IsHidden()
  return false
end

function modifier_mirana_arrow_stun_oaa:IsDebuff()
  return true
end

function modifier_mirana_arrow_stun_oaa:IsStunDebuff()
  return true
end

function modifier_mirana_arrow_stun_oaa:IsPurgable()
  return true
end

function modifier_mirana_arrow_stun_oaa:GetEffectName()
  return "particles/generic_gameplay/generic_stunned.vpcf"
end

function modifier_mirana_arrow_stun_oaa:GetEffectAttachType()
  return PATTACH_OVERHEAD_FOLLOW
end

function modifier_mirana_arrow_stun_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
  }
end

function modifier_mirana_arrow_stun_oaa:GetOverrideAnimation()
  return ACT_DOTA_DISABLED
end

function modifier_mirana_arrow_stun_oaa:CheckState()
  return {
    [MODIFIER_STATE_STUNNED] = true,
  }
end
