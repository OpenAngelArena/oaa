sohei_dash = class(AbilityBaseClass)

--LinkLuaModifier("modifier_sohei_dash_free_turning", "abilities/sohei/sohei_dash.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_sohei_dash_movement", "abilities/sohei/sohei_dash.lua", LUA_MODIFIER_MOTION_HORIZONTAL)
--LinkLuaModifier("modifier_sohei_dash_charges", "abilities/sohei/sohei_dash.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_sohei_dash_slow", "abilities/sohei/sohei_dash.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_sohei_dash_movement_ally", "abilities/sohei/sohei_dash.lua", LUA_MODIFIER_MOTION_HORIZONTAL)


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
  local talent = caster:FindAbilityByName( "special_bonus_sohei_dash_recharge" )

  if talent and talent:GetLevel() > 0 then
    refreshTime = math.max( refreshTime - talent:GetSpecialValueFor( "value" ), 1 )
  end

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

function sohei_dash:OnSpellStart()
  local caster = self:GetCaster()
  local caster_loc = caster:GetAbsOrigin()
  local target_loc = self:GetCursorPosition()
  local max_speed = self:GetSpecialValueFor("dash_speed")
  local width = self:GetSpecialValueFor("dash_width")
  local range = self:GetSpecialValueFor("dash_range")

  -- Bonus range talent
  local talent = caster:FindAbilityByName("special_bonus_sohei_dash_cast_range")
  if talent and talent:GetLevel() > 0 then
    range = range + talent:GetSpecialValueFor("value")
  end

  -- Calculate range with cast range bonuses
  range = range + caster:GetCastRangeBonus()

  -- Calculate direction
  local direction = target_loc - caster_loc
  direction.z = 0.0
  direction = direction:Normalized()

  -- Calculate and cap the distance
  local distance = (target_loc - caster_loc):Length2D()
  if distance > range then
    distance = range
  end

  -- Calculate speed - its based on caster's movement speed
  local move_speed = caster:GetIdealSpeed()
  local speed = move_speed * 7
  -- Cap the Dash speed
  speed = math.min(speed, max_speed)

  -- Calculate duration
  local duration = distance / speed

  caster:RemoveModifierByName("modifier_sohei_dash_movement")
  caster:EmitSound("Sohei.Dash")
  caster:StartGesture(ACT_DOTA_RUN)

  caster:AddNewModifier(caster, self, "modifier_sohei_dash_movement", {
    duration = duration,
    distance = distance,
    speed = speed,
    direction_x = direction.x,
    direction_y = direction.y,
    width = width,
  } )

  if caster:HasShardOAA() then
    ProjectileManager:ProjectileDodge(caster)
  end
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
	local funcs = {
		MODIFIER_PROPERTY_IGNORE_CAST_ANGLE
	}

	return funcs
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
  return false
end

function modifier_sohei_dash_movement:IsStunDebuff()
  return false
end

function modifier_sohei_dash_movement:GetPriority()
  return DOTA_MOTION_CONTROLLER_PRIORITY_HIGHEST
end

function modifier_sohei_dash_movement:CheckState()
  local state = {
    [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
    [MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true
  }

  local caster = self:GetParent()
  if caster:HasShardOAA() then
    state[MODIFIER_STATE_NO_HEALTH_BAR] = true
    state[MODIFIER_STATE_INVULNERABLE] = true
    state[MODIFIER_STATE_MAGIC_IMMUNE] = true
  end

  return state
end

if IsServer() then
  function modifier_sohei_dash_movement:OnCreated(event)
    -- Movement parameters
    local parent = self:GetParent()
    self.start_pos = parent:GetAbsOrigin()
    -- Data sent with AddNewModifier (not available on the client)
    self.direction = Vector(event.direction_x, event.direction_y, 0)
    self.distance = event.distance + 1
    self.speed = event.speed
    self.width = event.width

    if self:ApplyHorizontalMotionController() == false then
      self:Destroy()
      return
    end

    local particleName = "particles/hero/sohei/sohei_trail.vpcf"

    if parent:HasModifier('modifier_arcana_dbz') then
      particleName = "particles/hero/sohei/arcana/dbz/sohei_trail_dbz.vpcf"
    elseif parent:HasModifier('modifier_arcana_pepsi') then
      particleName = "particles/hero/sohei/arcana/pepsi/sohei_trail_pepsi.vpcf"
    end

    local end_pos = self.start_pos + self.direction * self.distance

    -- Trail particle
    local trail_pfx = ParticleManager:CreateParticle( particleName, PATTACH_CUSTOMORIGIN, parent )
    ParticleManager:SetParticleControl(trail_pfx, 0, self.start_pos)
    ParticleManager:SetParticleControl(trail_pfx, 1, end_pos)
    ParticleManager:ReleaseParticleIndex(trail_pfx)
  end

  function modifier_sohei_dash_movement:OnDestroy()
    local parent = self:GetParent()
    local ability = self:GetAbility()
    local parent_origin = parent:GetAbsOrigin()

    parent:FadeGesture(ACT_DOTA_RUN)
    parent:RemoveHorizontalMotionController(self)
    ResolveNPCPositions(parent_origin, 128)
    parent:FaceTowards(parent_origin + 128*self.direction)

    local enemies = FindUnitsInLine(parent:GetTeamNumber(), self.start_pos, parent_origin, nil, self.width, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE)
    local damage_table = {}
    damage_table.attacker = parent
    damage_table.damage_type = ability:GetAbilityDamageType()
    damage_table.ability = ability
    damage_table.damage = ability:GetSpecialValueFor("damage")

    for _,unit in pairs(enemies) do
      if unit and not unit:IsNull() then
        unit:AddNewModifier(parent, ability, "modifier_sohei_dash_slow", { duration = ability:GetSpecialValueFor("slow_duration") })
        damage_table.victim = unit
        ApplyDamage(damage_table)
      end
    end

    -- Dash with Shard heals allies
    if parent:HasShardOAA() then
      local do_sound = false
      local allies = FindUnitsInLine(parent:GetTeamNumber(), self.start_pos, parent_origin, nil, self.width, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NOT_ILLUSIONS)
      for _,ally in pairs(allies) do
        if ally and not ally:IsNull() and ally ~= parent then
          do_sound = true

          -- Relocate the ally to parent's position
          ProjectileManager:ProjectileDodge(ally)
          local ally_loc = ally:GetAbsOrigin()
          local direction = parent_origin - ally_loc
          local distance = direction:Length2D()
          direction.z = 0.0
          direction = direction:Normalized()

          ally:AddNewModifier(parent, ability, "modifier_sohei_dash_movement_ally", {
            duration = distance / self.speed,
            distance = distance,
            speed = self.speed,
            direction_x = direction.x,
            direction_y = direction.y,
            width = self.width,
          } )

          -- Healing
          local base_heal_amount = ability:GetSpecialValueFor("shard_base_heal")
          local hp_as_heal = ability:GetSpecialValueFor("shard_hp_as_heal")
          local heal_amount_based_on_hp = parent:GetHealth() * hp_as_heal/100

          ally:Heal(base_heal_amount+heal_amount_based_on_hp, ability)

          local part = ParticleManager:CreateParticle("particles/units/heroes/hero_omniknight/omniknight_purification.vpcf", PATTACH_ABSORIGIN_FOLLOW, ally)
          ParticleManager:SetParticleControl(part, 0, ally_loc)
          ParticleManager:SetParticleControl(part, 1, Vector(ally:GetModelRadius(), 1, 1 ))
          ParticleManager:ReleaseParticleIndex(part)

          SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, ally, base_heal_amount+heal_amount_based_on_hp, nil)
        end
      end
      if do_sound then
        parent:EmitSound("Sohei.PalmOfLife.Heal")
      end
    end
  end

  function modifier_sohei_dash_movement:UpdateHorizontalMotion(parent, deltaTime)
    local parentOrigin = parent:GetAbsOrigin()

    local tickSpeed = self.speed * deltaTime
    tickSpeed = math.min(tickSpeed, self.distance)
    local tickOrigin = parentOrigin + (tickSpeed * self.direction)

    parent:SetAbsOrigin(tickOrigin)

    self.distance = self.distance - tickSpeed

    GridNav:DestroyTreesAroundPoint(tickOrigin, self.width, false)
  end

  function modifier_sohei_dash_movement:OnHorizontalMotionInterrupted()
    self:Destroy()
  end
end

---------------------------------------------------------------------------------------------------

-- Dash movement modifier on allies
modifier_sohei_dash_movement_ally = class(modifier_sohei_dash_movement)

function modifier_sohei_dash_movement_ally:IsHidden()
  return true
end

function modifier_sohei_dash_movement_ally:CheckState()
  local state = {
    [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
    [MODIFIER_STATE_NO_HEALTH_BAR] = true,
    [MODIFIER_STATE_INVULNERABLE] = true,
    [MODIFIER_STATE_MAGIC_IMMUNE] = true,
  }

  return state
end

function modifier_sohei_dash_movement_ally:OnCreated(event)
  if not IsServer() then
    return
  end
  -- Movement parameters
  local parent = self:GetParent()
  self.start_pos = parent:GetAbsOrigin()
  -- Data sent with AddNewModifier (not available on the client)
  self.direction = Vector(event.direction_x, event.direction_y, 0)
  self.distance = event.distance + 1
  self.speed = event.speed
  self.width = event.width

  if self:ApplyHorizontalMotionController() == false then
    self:Destroy()
    return
  end

  local particleName = "particles/hero/sohei/sohei_trail.vpcf"
  local caster = self:GetCaster()
  if caster:HasModifier('modifier_arcana_dbz') then
    particleName = "particles/hero/sohei/arcana/dbz/sohei_trail_dbz.vpcf"
  elseif caster:HasModifier('modifier_arcana_pepsi') then
    particleName = "particles/hero/sohei/arcana/pepsi/sohei_trail_pepsi.vpcf"
  end

  local end_pos = self.start_pos + self.direction * self.distance

  -- Trail particle
  local trail_pfx = ParticleManager:CreateParticle( particleName, PATTACH_CUSTOMORIGIN, parent )
  ParticleManager:SetParticleControl(trail_pfx, 0, self.start_pos)
  ParticleManager:SetParticleControl(trail_pfx, 1, end_pos)
  ParticleManager:ReleaseParticleIndex(trail_pfx)
end

function modifier_sohei_dash_movement_ally:OnDestroy()
  if not IsServer() then
    return
  end

  local parent = self:GetParent()
  local parent_origin = parent:GetAbsOrigin()

  parent:RemoveHorizontalMotionController(self)
  ResolveNPCPositions(parent_origin, 128)
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

function modifier_sohei_dash_slow:IsStunDebuff()
  return false
end

function modifier_sohei_dash_slow:OnCreated(event)
  local parent = self:GetParent()
  local movement_slow = self:GetAbility():GetSpecialValueFor("move_speed_slow_pct")

  if IsServer() then
    local talent = self:GetCaster():FindAbilityByName("special_bonus_sohei_dash_slow")
    if talent and talent:GetLevel() > 0 then
      movement_slow = movement_slow - talent:GetSpecialValueFor("value")
    end
    -- Slow is reduced with Status Resistance
    self.slow = parent:GetValueChangedByStatusResistance(movement_slow)
  else
    self.slow = movement_slow
  end
end

function modifier_sohei_dash_slow:OnRefresh(event)
  local parent = self:GetParent()
  local movement_slow = self:GetAbility():GetSpecialValueFor("move_speed_slow_pct")

  if IsServer() then
    local talent = self:GetCaster():FindAbilityByName("special_bonus_sohei_dash_slow")
    if talent and talent:GetLevel() > 0 then
      movement_slow = movement_slow - talent:GetSpecialValueFor("value")
    end
    -- Slow is reduced with Status Resistance
    self.slow = parent:GetValueChangedByStatusResistance(movement_slow)
  else
    self.slow = movement_slow
  end
end

function modifier_sohei_dash_slow:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
  }

  return funcs
end

function modifier_sohei_dash_slow:GetModifierMoveSpeedBonus_Percentage()
  return self.slow
end
