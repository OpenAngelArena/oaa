sohei_momentum = class( AbilityBaseClass )

LinkLuaModifier("modifier_sohei_momentum_passive", "abilities/sohei/sohei_momentum.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_sohei_momentum_knockback", "abilities/sohei/sohei_momentum.lua", LUA_MODIFIER_MOTION_HORIZONTAL)
LinkLuaModifier("modifier_sohei_momentum_slow", "abilities/sohei/sohei_momentum.lua", LUA_MODIFIER_MOTION_NONE)

--------------------------------------------------------------------------------

function sohei_momentum:GetAbilityTextureName()
  local baseName = self.BaseClass.GetAbilityTextureName( self )

  if self:GetSpecialValueFor( "trigger_distance" ) <= 0 then
    return baseName
  end

  if self.intrMod and not self.intrMod:IsNull() and not self.intrMod:IsMomentumReady() then
    return baseName .. "_inactive"
  end

  -- When toggled off, there is no modifier, => make icon inactive
  if not self:GetCaster():HasModifier("modifier_sohei_momentum_passive") then
    return baseName .. "_inactive"
  end

	return baseName
end

-- Uncomment if the ability is passive
--function sohei_momentum:GetIntrinsicModifierName()
	--return "modifier_sohei_momentum_passive"
--end

function sohei_momentum:IsHiddenWhenStolen( arg )
  return true
end

function sohei_momentum:IsStealable()
  return false
end

-- Remove if the ability is passive
function sohei_momentum:OnToggle()
  local caster = self:GetCaster()
  if not self:GetToggleState() then
    caster:RemoveModifierByName("modifier_sohei_momentum_passive")
	else
		caster:AddNewModifier(caster, self, "modifier_sohei_momentum_passive", {})
	end
end

-- Remove if the ability is passive
function sohei_momentum:OnUpgrade()
  if self:GetLevel() == 1 then
    -- Toggle on when the ability is leveled-up for the first time
		if not self:GetToggleState() then
			self:ToggleAbility()
		end
	end
end

-- Remove if the ability is passive
function sohei_momentum:OnOwnerSpawned()
  if self:GetLevel() >= 1 then
    if not self:GetToggleState() then
      self:ToggleAbility()
    end
  end
end

--------------------------------------------------------------------------------

-- Momentum's passive modifier
modifier_sohei_momentum_passive = class( ModifierBaseClass )

--------------------------------------------------------------------------------

function modifier_sohei_momentum_passive:IsHidden()
  return true
end

function modifier_sohei_momentum_passive:IsPurgable()
  return false
end

function modifier_sohei_momentum_passive:IsDebuff()
  return false
end

-- Uncomment if the ability is passive
--function modifier_sohei_momentum_passive:GetAttributes()
	--return MODIFIER_ATTRIBUTE_PERMANENT
--end

--------------------------------------------------------------------------------

function modifier_sohei_momentum_passive:IsMomentumReady()
  -- special case flurry of blows to always have momentum ready
  if self:GetParent():HasModifier( "modifier_sohei_flurry_self" ) then
    return true
  end

  local distanceFull = self:GetAbility():GetSpecialValueFor( "trigger_distance" )

  return self:GetStackCount() >= distanceFull
end

--------------------------------------------------------------------------------

function modifier_sohei_momentum_passive:OnCreated( event )
  self:GetAbility().intrMod = self

  self.parentOrigin = self:GetParent():GetAbsOrigin()
  self.attackPrimed = false -- necessary for cases when sohei starts an attack while moving
  -- i.e. force staff
  -- and gets charged before the attack finishes, causing an attack with knockback but no crit

  self:StartIntervalThink( 1 / 30 )
end

--------------------------------------------------------------------------------

if IsServer() then
  function modifier_sohei_momentum_passive:OnIntervalThink()
    -- Update position
    local parent = self:GetParent()
    local spell = self:GetAbility()
    local oldOrigin = self.parentOrigin
    self.parentOrigin = parent:GetAbsOrigin()

    if not self:IsMomentumReady() then
      if spell:IsCooldownReady() and not parent:PassivesDisabled() and not spell:IsHidden() then
        self:SetStackCount( self:GetStackCount() + ( self.parentOrigin - oldOrigin ):Length2D() )
        if self:IsMomentumReady() then
          local dbzArcana = parent:FindModifierByName( 'modifier_arcana_dbz' )
          local pepsiArcana = parent:FindModifierByName( 'modifier_arcana_pepsi' )

          if dbzArcana then
            ParticleManager:SetParticleControl( dbzArcana.Glow, 2, Vector(30,0,0) )
          elseif pepsiArcana then
            ParticleManager:SetParticleControl( pepsiArcana.Glow, 2, Vector(100,0,0) )
          end
        end
      end
    end
  end
end

--------------------------------------------------------------------------------

function modifier_sohei_momentum_passive:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE,
    MODIFIER_EVENT_ON_ATTACK_LANDED,
  }

  return funcs
end

--------------------------------------------------------------------------------

if IsServer() then
  function modifier_sohei_momentum_passive:GetModifierPreAttack_CriticalStrike( event )
    local parent = self:GetParent()
    local spell = self:GetAbility()
    if self:IsMomentumReady() and ( ( spell:IsCooldownReady() and not parent:PassivesDisabled() and not spell:IsHidden() ) or parent:HasModifier( "modifier_sohei_flurry_self" ) ) then

      -- make sure the target is valid
      local ufResult = UnitFilter(
        event.target,
        spell:GetAbilityTargetTeam(),
        spell:GetAbilityTargetType(),
        spell:GetAbilityTargetFlags(),
        self:GetParent():GetTeamNumber()
      )

      if ufResult ~= UF_SUCCESS then
        return 0
      end

      self.attackPrimed = true

      return spell:GetSpecialValueFor( "crit_damage" )
    end

    self.attackPrimed = false
    return 0
  end

--------------------------------------------------------------------------------

  function modifier_sohei_momentum_passive:OnAttackLanded( event )
    if event.attacker == self:GetParent() and self.attackPrimed == true then
      local attacker = self:GetParent()
      local target = event.target
      local spell = self:GetAbility()

      -- Consume the buff
      if not attacker:HasModifier( "modifier_sohei_flurry_self" ) then
        self:SetStackCount( 0 )
        local dbzArcana = attacker:FindModifierByName( 'modifier_arcana_dbz' )
        local pepsiArcana = attacker:FindModifierByName( 'modifier_arcana_pepsi' )
        if dbzArcana then
          ParticleManager:SetParticleControl( dbzArcana.Glow, 2, Vector(0,0,0) )
        elseif pepsiArcana then
          ParticleManager:SetParticleControl( pepsiArcana.Glow, 2, Vector(0,0,0) )
        end
      end

      -- Knock the enemy back
			local distance = spell:GetSpecialValueFor( "knockback_distance" )
			local speed = spell:GetSpecialValueFor( "knockback_speed" )
			local duration = distance / speed
			local collision_radius = spell:GetSpecialValueFor( "collision_radius" )
			target:RemoveModifierByName( "modifier_sohei_momentum_knockback" )
			target:AddNewModifier( attacker, spell, "modifier_sohei_momentum_knockback", {
				duration = duration,
				distance = distance,
				speed = speed,
				collision_radius = collision_radius
			} )

			-- Play the impact sound
      target:EmitSound( "Sohei.Momentum" )

      local particleName = "particles/hero/sohei/momentum.vpcf"

      if target:HasModifier('modifier_arcana_dbz') then
        particleName = "particles/hero/sohei/arcana/dbz/sohei_momentum_dbz.vpcf"
      elseif target:HasModifier('modifier_arcana_pepsi') then
        particleName = "particles/hero/sohei/arcana/dbz/sohei_momentum_pepsi.vpcf"
      end

      -- Play the impact particle
      local momentum_pfx = ParticleManager:CreateParticle( particleName, PATTACH_ABSORIGIN_FOLLOW, target )
      ParticleManager:SetParticleControl( momentum_pfx, 0, target:GetAbsOrigin() )
      ParticleManager:ReleaseParticleIndex( momentum_pfx )

      -- Reduce guard cd if they skilled the talent
      local guard = attacker:FindAbilityByName( "sohei_guard" )
      local talent = attacker:FindAbilityByName( "special_bonus_sohei_momentum_guard_cooldown" )

      if talent and talent:GetLevel() > 0 then
        local cooldown_reduction = talent:GetSpecialValueFor( "value" )

        if not guard:IsCooldownReady() then
          local newCooldown = guard:GetCooldownTimeRemaining() - cooldown_reduction
          guard:EndCooldown()
          guard:StartCooldown( newCooldown )
        end
      end

      -- start momentum cooldown if not used during flurry
      if not self:GetParent():HasModifier( "modifier_sohei_flurry_self" ) then
        spell:UseResources( true, true, true )
      end
    end
  end
end

--------------------------------------------------------------------------------

-- Momentum's knockback modifier
modifier_sohei_momentum_knockback = class( ModifierBaseClass )

--------------------------------------------------------------------------------

function modifier_sohei_momentum_knockback:IsDebuff()
  return true
end

function modifier_sohei_momentum_knockback:IsHidden()
  return true
end

function modifier_sohei_momentum_knockback:IsPurgable()
  return false
end

function modifier_sohei_momentum_knockback:IsStunDebuff()
  return false
end

function modifier_sohei_momentum_knockback:GetPriority()
  return DOTA_MOTION_CONTROLLER_PRIORITY_MEDIUM
end

--------------------------------------------------------------------------------

function modifier_sohei_momentum_knockback:GetEffectName()
  if self:GetCaster():HasModifier('modifier_arcana_dbz') then
    return "particles/hero/sohei/arcana/dbz/sohei_knockback_dbz.vpcf"
  end
  return "particles/hero/sohei/knockback.vpcf"
end

--------------------------------------------------------------------------------

function modifier_sohei_momentum_knockback:GetEffectAttachType()
  return PATTACH_ABSORIGIN_FOLLOW
end

--------------------------------------------------------------------------------

function modifier_sohei_momentum_knockback:CheckState()
  local state = {
    [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
  }

  return state
end

--------------------------------------------------------------------------------

function modifier_sohei_momentum_knockback:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
    MODIFIER_PROPERTY_OVERRIDE_ANIMATION_RATE,
  }

  return funcs
end

--------------------------------------------------------------------------------

function modifier_sohei_momentum_knockback:GetOverrideAnimation( event )
  return ACT_DOTA_FLAIL
end

--------------------------------------------------------------------------------

if IsServer() then
  function modifier_sohei_momentum_knockback:OnCreated( event )
    local unit = self:GetParent()
    local caster = self:GetCaster()

    local difference = unit:GetAbsOrigin() - caster:GetAbsOrigin()

    -- Movement parameters
    self.direction = difference:Normalized()
    self.distance = event.distance + 1
    self.speed = event.speed
    self.collision_radius = event.collision_radius

    if self:ApplyHorizontalMotionController() == false then
      self:Destroy()
      return
    end
  end

--------------------------------------------------------------------------------

  function modifier_sohei_momentum_knockback:OnDestroy()
    local parent = self:GetParent()

    parent:RemoveHorizontalMotionController( self )
    ResolveNPCPositions( parent:GetAbsOrigin(), 128 )
  end

--------------------------------------------------------------------------------

  function modifier_sohei_momentum_knockback:UpdateHorizontalMotion( parent, deltaTime )
    local caster = self:GetCaster()
    local parentOrigin = parent:GetAbsOrigin()

    local tickSpeed = self.speed * deltaTime
    tickSpeed = math.min( tickSpeed, self.distance )
    local tickOrigin = parentOrigin + ( tickSpeed * self.direction )

    self.distance = self.distance - tickSpeed

    -- If there is at least one target to attack, hit it
    local targets = FindUnitsInRadius(
      caster:GetTeamNumber(),
      tickOrigin,
      nil,
      self.collision_radius,
      DOTA_UNIT_TARGET_TEAM_ENEMY,
      DOTA_UNIT_TARGET_HERO,
      bit.bor( DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, DOTA_UNIT_TARGET_FLAG_NO_INVIS, DOTA_UNIT_TARGET_FLAG_NOT_ATTACK_IMMUNE ),
      FIND_CLOSEST,
      false
    )

    local nonHeroTarget = targets[1]
    if nonHeroTarget == parent then
      nonHeroTarget = targets[2]
    end

    local spell = self:GetAbility()

    if nonHeroTarget then
      self:SlowAndStun( parent, caster, spell )
      self:SlowAndStun( nonHeroTarget, caster, spell )
      self:Destroy()
    -- why do these mean two different things
    elseif not GridNav:IsTraversable( tickOrigin ) or GridNav:IsBlocked( tickOrigin ) then
      self:SlowAndStun( parent, caster, spell )
      GridNav:DestroyTreesAroundPoint( tickOrigin, self.collision_radius, false )
      self:Destroy()
    else
      -- if we check for collision after moving the unit, the unit will
      -- bounce around a bit due to resolving npc positions upon destruction
      -- so let's only move the unit if the move wouldn't hit anyone
      parent:SetAbsOrigin( tickOrigin )
    end
  end

--------------------------------------------------------------------------------

  function modifier_sohei_momentum_knockback:SlowAndStun( unit, caster, ability )
    unit:AddNewModifier( caster, ability, "modifier_sohei_momentum_slow", { duration = ability:GetSpecialValueFor( "slow_duration" ) } )

    local talent = caster:FindAbilityByName( "special_bonus_sohei_stun" )

    if talent and talent:GetLevel() > 0 then
      local stunDuration = talent:GetSpecialValueFor( "value" )
      stunDuration = unit:GetValueChangedByStatusResistance( stunDuration )

      unit:AddNewModifier( caster, ability, "modifier_stunned", { duration = stunDuration } )
    end
  end
end

--------------------------------------------------------------------------------

-- Momentum's knockback modifier
modifier_sohei_momentum_slow = class( ModifierBaseClass )

--------------------------------------------------------------------------------

function modifier_sohei_momentum_slow:IsDebuff()
  return true
end

function modifier_sohei_momentum_slow:IsHidden()
  return false
end

function modifier_sohei_momentum_slow:IsPurgable()
  return false
end

function modifier_sohei_momentum_slow:IsStunDebuff()
  return false
end

--------------------------------------------------------------------------------

function modifier_sohei_momentum_slow:OnCreated( event )
  local parent = self:GetParent()
  local movement_slow = self:GetAbility():GetSpecialValueFor( "movement_slow" )
  if IsServer() then
    self.slow = parent:GetValueChangedByStatusResistance( movement_slow )
  else
    self.slow = movement_slow
  end
end

--------------------------------------------------------------------------------

function modifier_sohei_momentum_slow:OnRefresh( event )
  local parent = self:GetParent()
  local movement_slow = self:GetAbility():GetSpecialValueFor( "movement_slow" )
  if IsServer() then
    self.slow = parent:GetValueChangedByStatusResistance( movement_slow )
  else
    self.slow = movement_slow
  end
end

--------------------------------------------------------------------------------

-- slows don't show correctly if they're in an IsServer() block govs
function modifier_sohei_momentum_slow:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
  }

  return funcs
end

--------------------------------------------------------------------------------

function modifier_sohei_momentum_slow:GetModifierMoveSpeedBonus_Percentage()
  return self.slow
end
