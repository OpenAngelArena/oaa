sohei_dash = class(AbilityBaseClass)

--LinkLuaModifier("modifier_sohei_dash_free_turning", "abilities/sohei/sohei_dash.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_sohei_dash_movement", "abilities/sohei/sohei_dash.lua", LUA_MODIFIER_MOTION_HORIZONTAL)
--LinkLuaModifier("modifier_sohei_dash_charges", "abilities/sohei/sohei_dash.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_sohei_dash_slow", "abilities/sohei/sohei_dash.lua", LUA_MODIFIER_MOTION_NONE)

---------------------------------------------------------------------------------------------------

--function sohei_dash:GetIntrinsicModifierName()
  --return "modifier_sohei_dash_free_turning"
--end

-- Custom charge system, uses Dash charges modifier
--[[
function sohei_dash:OnUpgrade()
  local caster = self:GetCaster()
  local modifier_charges = caster:FindModifierByName( "modifier_sohei_dash_charges" )
  local chargesMax = self:GetSpecialValueFor( "max_charges" )

  if caster:HasScepter() then
    chargesMax = self:GetSpecialValueFor( "scepter_max_charges" )
  end

  if not modifier_charges then
    modifier_charges = caster:AddNewModifier( caster, self, "modifier_sohei_dash_charges", {} )
    modifier_charges:SetStackCount( chargesMax )
  elseif modifier_charges:GetStackCount() < chargesMax then
    -- Reset the cooldown on the modifier
    modifier_charges:SetDuration( self:GetChargeRefreshTime(), true )
    modifier_charges:StartIntervalThink( 0.1 )
    if modifier_charges:GetStackCount() < 1 then
      self:StartCooldown( modifier_charges:GetRemainingTime() )
    end
  end
end

function sohei_dash:GetChargeRefreshTime()
  -- Reduce the charge recovery time if the appropriate talent is learned
  local caster = self:GetCaster()
  local refreshTime = self:GetSpecialValueFor( "charge_restore_time" )

  -- cdr stuff
  local cdr = caster:GetCooldownReduction()
  refreshTime = cdr*refreshTime

  return refreshTime
end

function sohei_dash:RefreshCharges()
  local caster = self:GetCaster()
  local modifier_charges = caster:FindModifierByName( "modifier_sohei_dash_charges" )

  if modifier_charges and not modifier_charges:IsNull() then
    local max_charges = self:GetSpecialValueFor( "max_charges" )
    if caster:HasScepter() then
      max_charges = self:GetSpecialValueFor( "scepter_max_charges" )
    end
    modifier_charges:SetStackCount( max_charges )
  end
end

function sohei_dash:OnUnStolen()
  local caster = self:GetCaster()
  local modifier_charges = caster:FindModifierByName("modifier_sohei_dash_charges")
  if modifier_charges then
    caster:RemoveModifierByName("modifier_sohei_dash_charges")
  end
end
]]

if IsClient() then
  function sohei_dash:GetCastRange(location, target)
    return self:GetSpecialValueFor("dash_range")
  end
end

function sohei_dash:CastFilterResultLocation(location)
  local caster = self:GetCaster()

  if caster:HasModifier("modifier_item_nullifier_mute") or caster:HasModifier("modifier_shadow_demon_purge_slow") then
    return UF_FAIL_CUSTOM
  end

  return UF_SUCCESS
end

function sohei_dash:GetCustomCastErrorLocation(location)
  local caster = self:GetCaster()

  if caster:HasModifier("modifier_item_nullifier_mute") or caster:HasModifier("modifier_shadow_demon_purge_slow") then
    return "#oaa_hud_error_cast_while_nullified"
  end
end

function sohei_dash:OnSpellStart()
  local caster = self:GetCaster()
  local target_loc = self:GetCursorPosition()
  local caster_loc = caster:GetAbsOrigin()

  local width = self:GetSpecialValueFor("dash_width")
  local max_speed = self:GetSpecialValueFor("dash_speed")
  local move_speed_multiplier = self:GetSpecialValueFor("move_speed_multiplier")
  local range = self:GetSpecialValueFor("dash_range")

  -- Calculate range with cast range bonuses
  range = range + caster:GetCastRangeBonus()

  -- Calculate direction
  local direction = target_loc - caster_loc

  -- Calculate and cap the distance
  local distance = direction:Length2D()
  if distance > range then
    distance = range
  end

  -- Calculate speed - it's based on caster's movement speed
  local speed = math.min(caster:GetIdealSpeed() * move_speed_multiplier, max_speed)

  -- Normalize direction
  direction.z = 0
  direction = direction:Normalized()

  -- Interrupt existing motion controllers (it should also interrupt existing instances of Dash)
  if caster:IsCurrentlyHorizontalMotionControlled() then
    caster:InterruptMotionControllers(false)
  end

  -- Dash sound
  caster:EmitSound("Sohei.Dash")

  -- Apply motion controller
  caster:AddNewModifier(caster, self, "modifier_sohei_dash_movement", {
    distance = distance,
    speed = speed,
    direction_x = direction.x,
    direction_y = direction.y,
    width = width,
  })
end
--[[
function sohei_dash:OnSpellStart()
  local caster = self:GetCaster()
  local modifier_charges = caster:FindModifierByName( "modifier_sohei_dash_charges" )
  local dashDistance = self:GetVectorTargetRange()
  local dashSpeed = self:GetSpecialValueFor( "dash_speed" )

  -- since changing stack count deals with cooldown anyway
  -- let's remove the default one
  self:EndCooldown()

  if modifier_charges and not modifier_charges:IsNull() then
    -- Perform the dash if there is at least one charge remaining
    local currentStackCount = modifier_charges:GetStackCount()
    if currentStackCount >= 1 then
      if currentStackCount > 1 then
        -- enable short cooldown if has enough charges for the next dash
        local shortCD = dashDistance / dashSpeed
        if self:GetCooldownTimeRemaining() < shortCD then
          --self:EndCooldown()
          self:StartCooldown(shortCD)
        end
      else
        -- if does not have charges for the next dash, set the cd to the remaining time of the modifier
        self:StartCooldown( modifier_charges:GetRemainingTime() )
      end
      modifier_charges:SetStackCount( currentStackCount - 1 )
    else
      -- should not enter here, but if it does :
      -- set the cd to the remain time of the modifier
      self:StartCooldown( modifier_charges:GetRemainingTime() )
      -- and return without performing the spell action (this will still consume resources)
      return
    end
  else
    caster:AddNewModifier( caster, self, "modifier_sohei_dash_charges", { duration = self:GetChargeRefreshTime() } )

    --self:EndCooldown()
    self:StartCooldown( self:GetChargeRefreshTime() )
  end

  -- i commented on this in guard but
  -- faking not casting is really just not a great solution
  -- especially if something breaks due to dev fault and suddenly a bread and butter ability isn't
  -- usable
  -- so let's instead give the player some let in this regard and let 'em dash anyway

  self:PerformDash()

  -- cd refund for momentum
  local cdRefund = self:GetSpecialValueFor( "momentum_cd_refund" )

  if cdRefund > 0 then
    local momentum = caster:FindAbilityByName( "sohei_momentum" )

    if momentum and not momentum:IsCooldownReady() then
      local momentumCooldown = momentum:GetCooldownTimeRemaining()
      local refundCooldown = momentumCooldown * ( cdRefund / 100.0 )

      momentum:EndCooldown()
      momentum:StartCooldown( momentumCooldown - refundCooldown )
    end
  end
end
]]

---------------------------------------------------------------------------------------------------

-- Dash free turning (ignoring cast angle) modifier - problem with it is that it applies to every ability and item, we don't want that
--[[
modifier_sohei_dash_free_turning = class( ModifierBaseClass )


function modifier_sohei_dash_free_turning:IsDebuff()
	return false
end

function modifier_sohei_dash_free_turning:IsHidden()
	return true
end

function modifier_sohei_dash_free_turning:IsPurgable()
	return false
end

function modifier_sohei_dash_free_turning:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT
end

function modifier_sohei_dash_free_turning:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_IGNORE_CAST_ANGLE
  }
end

function modifier_sohei_dash_free_turning:GetModifierIgnoreCastAngle()
	return 1
end
]]
---------------------------------------------------------------------------------------------------

-- Dash charges modifier
--[[
modifier_sohei_dash_charges = class( ModifierBaseClass )

function modifier_sohei_dash_charges:IsDebuff()
  return false
end

function modifier_sohei_dash_charges:IsHidden()
  return false
end

function modifier_sohei_dash_charges:IsPurgable()
  return false
end

function modifier_sohei_dash_charges:RemoveOnDeath()
  return false
end

function modifier_sohei_dash_charges:DestroyOnExpire()
  return false
end

function modifier_sohei_dash_charges:GetAttributes()
  return MODIFIER_ATTRIBUTE_PERMANENT
end

if IsServer() then
  function modifier_sohei_dash_charges:OnCreated()
    self:StartIntervalThink( 0.1 )
  end

  function modifier_sohei_dash_charges:OnRefresh()
    self:StartIntervalThink( 0.1 )
  end

  function modifier_sohei_dash_charges:OnIntervalThink()
    if self:GetRemainingTime() <= 0 then
      self:OnExpire()
    end
  end

  function modifier_sohei_dash_charges:OnExpire()
    -- used to handle all charge-gaining logic here
    -- but that doesn't work with RefreshCharges also adding
    -- charges, so sayonara old chap
    self:SetDuration( -1, true )
    self:SetStackCount( self:GetStackCount() + 1 )
  end

  function modifier_sohei_dash_charges:OnStackCountChanged( oldCount )
    local parent = self:GetParent()
    local spell = self:GetAbility()
    local newCount = self:GetStackCount()
    local maxCount = spell:GetSpecialValueFor( "max_charges" )

    if parent:HasScepter() then
      maxCount = spell:GetSpecialValueFor( "scepter_max_charges" )
    end

    if newCount >= maxCount then
      -- we want to make sure that the thinking stops at max
      -- charges, and not just in OnExpire as charges can be added
      -- through Refresher items and such
      self:SetDuration( -1, true )
      self:StartIntervalThink( -1 )
    else
      -- we're just starting the thinking again
      -- so we don't bother doing anything if that's already happening
      -- ( otherwise, we'll end up restarting the recharge time )
      if self:GetDuration() <= 0 and newCount < maxCount then
        local duration = spell:GetChargeRefreshTime()

        self:SetDuration( duration, true )
        self:StartIntervalThink( 0.1 )
        -- we can probably now tell StartIntervalThink to only think every duration
        -- seconds now, but I'd rather not go about extensively testing that for now
      end

      -- also do cooldown if the count is dead
      -- rip Dracula
      if newCount <= 0 then
        local remainingTime = self:GetRemainingTime()

        if remainingTime > spell:GetCooldownTimeRemaining() then
          spell:EndCooldown()
          spell:StartCooldown( remainingTime )
        end

        -- Palm of Life sharing cooldown with Dash
        local spellPalm = self:GetParent():FindAbilityByName( "sohei_palm_of_life" )
        if spellPalm and not spellPalm:IsStolen() and remainingTime > spellPalm:GetCooldownTimeRemaining() then
          spellPalm:EndCooldown()
          spellPalm:StartCooldown( remainingTime )
        end
      end
    end
  end
end
]]
---------------------------------------------------------------------------------------------------

-- Dash movement modifier
modifier_sohei_dash_movement = class(ModifierBaseClass)

function modifier_sohei_dash_movement:IsDebuff()
  return false
end

function modifier_sohei_dash_movement:IsHidden()
  return true
end

function modifier_sohei_dash_movement:IsPurgable()
  return true
end

function modifier_sohei_dash_movement:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
  }
end

function modifier_sohei_dash_movement:GetOverrideAnimation()
  return ACT_DOTA_RUN
end

function modifier_sohei_dash_movement:GetPriority()
  return DOTA_MOTION_CONTROLLER_PRIORITY_HIGHEST
end

function modifier_sohei_dash_movement:CheckState()
  local state = {
    [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
    [MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true
  }

  -- local caster = self:GetCaster()
  -- if condition then
    -- state[MODIFIER_STATE_NO_HEALTH_BAR] = true
    -- state[MODIFIER_STATE_INVULNERABLE] = true
    -- state[MODIFIER_STATE_MAGIC_IMMUNE] = true
  -- end

  return state
end

if IsServer() then
  function modifier_sohei_dash_movement:OnCreated(event)
    local parent = self:GetParent()
    local caster = self:GetCaster()

    -- Data sent with AddNewModifier (not available on the client)
    self.direction = Vector(event.direction_x, event.direction_y, 0)
    self.distance = event.distance + 1
    self.speed = event.speed
    self.width = event.width

    -- if condition then
      -- ProjectileManager:ProjectileDodge(parent)
    -- end

    if self:ApplyHorizontalMotionController() == false then
      self:Destroy()
      return
    end

    local particleName = "particles/hero/sohei/sohei_trail.vpcf"
    if caster:HasModifier("modifier_arcana_dbz") then
      particleName = "particles/hero/sohei/arcana/dbz/sohei_trail_dbz.vpcf"
    elseif caster:HasModifier("modifier_arcana_pepsi") then
      particleName = "particles/hero/sohei/arcana/pepsi/sohei_trail_pepsi.vpcf"
    end

    self.start_pos = parent:GetAbsOrigin()
    local end_pos = self.start_pos + self.direction * self.distance

    -- Trail particle
    local trail_pfx = ParticleManager:CreateParticle(particleName, PATTACH_CUSTOMORIGIN, caster)
    ParticleManager:SetParticleControl(trail_pfx, 0, self.start_pos)
    ParticleManager:SetParticleControl(trail_pfx, 1, end_pos)
    ParticleManager:ReleaseParticleIndex(trail_pfx)
  end

  function modifier_sohei_dash_movement:OnDestroy()
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local ability = self:GetAbility()
    local parent_origin = parent:GetAbsOrigin()
    local caster_team = caster:GetTeamNumber()

    parent:RemoveHorizontalMotionController(self)

    -- Unstuck the parent
    FindClearSpaceForUnit(parent, parent_origin, false)
    ResolveNPCPositions(parent_origin, 128)

    -- Change facing of the parent
    parent:FaceTowards(parent_origin + 128*self.direction)

    local damage = ability:GetSpecialValueFor("damage")

    local damage_table = {
      attacker = caster,
      damage = damage,
      damage_type = ability:GetAbilityDamageType(),
      ability = ability,
    }

    -- Damage enemies in a line
    local enemies = FindUnitsInLine(caster_team, self.start_pos, parent_origin, nil, self.width, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE)
    for _, enemy in pairs(enemies) do
      if enemy and not enemy:IsNull() then
        -- Apply debuff first
        enemy:AddNewModifier(caster, ability, "modifier_sohei_dash_slow", {duration = ability:GetSpecialValueFor("slow_duration")})
        -- Damage
        damage_table.victim = enemy
        ApplyDamage(damage_table)
      end
    end

    -- Heal allies in a line
    local heal_amount = damage * ability:GetSpecialValueFor("heal_ratio")
    if heal_amount > 0 then
      local do_sound = false
      local allies = FindUnitsInLine(caster_team, self.start_pos, parent_origin, nil, self.width, DOTA_UNIT_TARGET_TEAM_FRIENDLY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE)
      for _, ally in pairs(allies) do
        if ally and not ally:IsNull() and ally ~= caster then
          do_sound = true

          -- Healing
          ally:Heal(heal_amount, ability)

          local part = ParticleManager:CreateParticle("particles/units/heroes/hero_omniknight/omniknight_purification.vpcf", PATTACH_ABSORIGIN_FOLLOW, ally)
          ParticleManager:SetParticleControl(part, 0, ally:GetAbsOrigin())
          ParticleManager:SetParticleControl(part, 1, Vector(ally:GetModelRadius(), 1, 1))
          ParticleManager:ReleaseParticleIndex(part)

          SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, ally, heal_amount, nil)
        end
      end
      if do_sound then
        if parent and not parent:IsNull() then
          parent:EmitSound("Sohei.PalmOfLife.Heal")
        else
          caster:EmitSound("Sohei.PalmOfLife.Heal")
        end
      end
    end
    local proc_attacks = ability:GetSpecialValueFor("procs_attacks")
    if proc_attacks > 0 then
      -- Check if its a stolen spell (by Rubick) so we use actual projectile
      local bUseProjectile = false
      if ability and ability:IsStolen() then
        bUseProjectile = true
      end
      -- Attack remaining enemies
      for _, enemy in pairs(enemies) do
        if enemy and not enemy:IsNull() then
          if enemy:IsAlive() then
            -- Instant attack
            caster:PerformAttack(enemy, true, true, true, false, bUseProjectile, false, true)
          end
        end
      end
    end
  end

  function modifier_sohei_dash_movement:UpdateHorizontalMotion(parent, deltaTime)
    if not parent or parent:IsNull() or not parent:IsAlive() then
      return
    end

    -- Check if rooted or leashed
    local isRootedOrLeashed = parent:IsRooted() or parent:IsLeashedOAA()
    -- Check if affected by continous dispel
    local isNullified = parent:HasModifier("modifier_item_nullifier_mute")

    if isRootedOrLeashed or isNullified then
      self:Destroy()
      return
    end

    local parentOrigin = parent:GetAbsOrigin()

    local tickTraveled = deltaTime * self.speed
    tickTraveled = math.min(tickTraveled, self.distance)
    if tickTraveled <= 0 then
      self:Destroy()
    end
    local tickOrigin = parentOrigin + tickTraveled * self.direction
    tickOrigin = Vector(tickOrigin.x, tickOrigin.y, GetGroundHeight(tickOrigin, parent))

    parent:SetAbsOrigin(tickOrigin)

    self.distance = self.distance - tickTraveled

    GridNav:DestroyTreesAroundPoint(tickOrigin, self.width, false)
  end

  function modifier_sohei_dash_movement:OnHorizontalMotionInterrupted()
    self:Destroy()
  end
end

---------------------------------------------------------------------------------------------------

-- Dash slow debuff
modifier_sohei_dash_slow = class(ModifierBaseClass)

function modifier_sohei_dash_slow:IsDebuff()
  return true
end

function modifier_sohei_dash_slow:IsHidden()
  return false
end

function modifier_sohei_dash_slow:IsPurgable()
  return true
end

function modifier_sohei_dash_slow:OnCreated()
  local ability = self:GetAbility()
  local movement_slow = ability:GetSpecialValueFor("move_speed_slow_pct")
  local attack_slow = ability:GetSpecialValueFor("attack_speed_slow")

  self.attack_speed = attack_slow
  -- Move Speed Slow is reduced with Slow Resistance
  self.slow = movement_slow --parent:GetValueChangedBySlowResistance(movement_slow)
end

function modifier_sohei_dash_slow:OnRefresh()
  self:OnCreated()
end

function modifier_sohei_dash_slow:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
  }
end

function modifier_sohei_dash_slow:GetModifierMoveSpeedBonus_Percentage()
  return 0 - math.abs(self.slow)
end

function modifier_sohei_dash_slow:GetModifierAttackSpeedBonus_Constant()
  return 0 - math.abs(self.attack_speed)
end
