electrician_cleansing_shock = class( AbilityBaseClass )

LinkLuaModifier( "modifier_electrician_cleansing_shock_ally", "abilities/electrician/electrician_cleansing_shock.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_electrician_cleansing_shock_enemy", "abilities/electrician/electrician_cleansing_shock.lua", LUA_MODIFIER_MOTION_HORIZONTAL )

--------------------------------------------------------------------------------

-- CastFilterResultTarget runs on client side first
function electrician_cleansing_shock:CastFilterResultTarget(target)
  local default_result = self.BaseClass.CastFilterResultTarget(self, target)

  if default_result == UF_FAIL_MAGIC_IMMUNE_ENEMY then
    local caster = self:GetCaster()
    -- Talent that allows to target Spell Immune units
    if caster:HasTalent("special_bonus_electrician_shock_spell_immunity") then
      return UF_SUCCESS
    end
  end

  return default_result
end

function electrician_cleansing_shock:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	-- clean up the hit list
	self.hitTargets = {}

	-- talent integration
	local talent = self:GetCaster():FindAbilityByName( "special_bonus_electrician_shock_autoself" )

	if talent and talent:GetLevel() > 0 then
		self:ApplyEffect( caster )
	end

	-- do the visual effect for the initial target
	self:ApplyLaser( caster, "attach_attack1", target, "attach_hitloc" )

	-- cast sound
	caster:EmitSound( "Hero_Tinker.Laser" )
  -- cast animation
  caster:StartGesture( ACT_DOTA_CAST_ABILITY_1 )

	-- trigger and get blocked by linkens
	if not target:TriggerSpellAbsorb( self ) then
		-- set up abilityspecial
		local targets = 1
		local bounceRange = self:GetSpecialValueFor( "bounce_range_scepter" )

		-- if caster has scepter, add number of bounces to hit count
		if caster:HasScepter() then
			targets = targets + self:GetSpecialValueFor( "bounces_scepter" )
		end

		-- until we run out of bounces ...
		while targets > 0 do
			-- apply the effect to the current target
			self:ApplyEffect( target )

			-- lower target count
			targets = targets - 1

			-- break instantly if we're out of new targets
			-- ( we do it this way because we want to apply visuals and sounds
			-- regardless of linken's )
			if targets <= 0 then
				break
			end

			-- quick tracking thing for laser
			local targetOld = target

			-- find a new target
			target = self:FindBounceTarget( target:GetAbsOrigin(), bounceRange )

			-- if we can't, cancel now
			if not target then
				return
			end

			-- do laser
			self:ApplyLaser( targetOld, "attach_hitloc", target, "attach_hitloc" )
		end
	end
end

--------------------------------------------------------------------------------

-- helper function for applying the purge and move speed change
function electrician_cleansing_shock:ApplyEffect( target )
  local caster = self:GetCaster()
  local duration = self:GetSpecialValueFor( "duration" )

  if target:GetTeamNumber() ~= caster:GetTeamNumber() then
    target:Purge( true, false, false, false, false )
    duration = target:GetValueChangedByStatusResistance( duration )
    target:AddNewModifier( caster, self, "modifier_electrician_cleansing_shock_enemy", { duration = duration } )
  else
    target:Purge( false, true, false, false, false )
    target:AddNewModifier( caster, self, "modifier_electrician_cleansing_shock_ally", { duration = duration } )
  end

  -- particle
  local part = ParticleManager:CreateParticle( "particles/units/heroes/hero_zuus/zuus_static_field.vpcf", PATTACH_ABSORIGIN_FOLLOW, target )
  ParticleManager:ReleaseParticleIndex( part )

  -- sound
  target:EmitSound( "Hero_Tinker.LaserImpact" )

  -- add unit to hitlist
  table.insert( self.hitTargets, target )
end

--------------------------------------------------------------------------------

-- helper for laser effect
function electrician_cleansing_shock:ApplyLaser( source, sourceLoc, target, targetLoc )
	local part = ParticleManager:CreateParticle( "particles/units/heroes/hero_tinker/tinker_laser.vpcf", PATTACH_POINT_FOLLOW, target )
	ParticleManager:SetParticleControlEnt( part, 9, source, PATTACH_POINT_FOLLOW, sourceLoc, source:GetAbsOrigin(), true )
	ParticleManager:SetParticleControlEnt( part, 1, target, PATTACH_POINT_FOLLOW, targetLoc, target:GetAbsOrigin(), true )
	ParticleManager:ReleaseParticleIndex( part )
end

--------------------------------------------------------------------------------

-- helper for finding a new target
function electrician_cleansing_shock:FindBounceTarget( origin, radius )
	local casterTeam = self:GetCaster():GetTeamNumber()

	-- helperception
	local function FindInTable( t, target )
		for k, v in pairs( t ) do
			if v == target then
				return k
			end
		end

		return nil
	end

	-- first, we check for heroes, then creeps
	for targetType = DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP do
		-- find all candidates
		local units = FindUnitsInRadius(
			casterTeam,
			origin,
			nil,
			radius,
			self:GetAbilityTargetTeam(),
			targetType,
			self:GetAbilityTargetFlags(),
			FIND_CLOSEST,
			false
		)

		-- iterate through them
		for _, unit in pairs( units ) do
			-- don't repeat hits
			if not FindInTable( self.hitTargets, unit ) then
				return unit
			end
		end
	end

	return nil
end

--------------------------------------------------------------------------------

modifier_electrician_cleansing_shock_ally = class( ModifierBaseClass )

--------------------------------------------------------------------------------

function modifier_electrician_cleansing_shock_ally:IsDebuff()
	return false
end

function modifier_electrician_cleansing_shock_ally:IsHidden()
	return false
end

function modifier_electrician_cleansing_shock_ally:IsPurgable()
	return true
end

--------------------------------------------------------------------------------

function modifier_electrician_cleansing_shock_ally:OnCreated( event )
	local spell = self:GetAbility()
	local interval = spell:GetSpecialValueFor( "speed_update_interval" )
	self.moveSpeed = spell:GetSpecialValueFor( "move_speed_bonus" )
	self.intervalChange = self.moveSpeed / ( self:GetDuration() / interval )

	self:StartIntervalThink( interval )
end

--------------------------------------------------------------------------------

function modifier_electrician_cleansing_shock_ally:OnRefresh( event )
	local spell = self:GetAbility()
	local interval = spell:GetSpecialValueFor( "speed_update_interval" )
	self.moveSpeed = spell:GetSpecialValueFor( "move_speed_bonus" )
	self.intervalChange = self.moveSpeed / ( self:GetDuration() / interval )

	self:StartIntervalThink( interval )
end

--------------------------------------------------------------------------------

function modifier_electrician_cleansing_shock_ally:OnIntervalThink()
	self.moveSpeed = self.moveSpeed - self.intervalChange
end

--------------------------------------------------------------------------------

function modifier_electrician_cleansing_shock_ally:DeclareFunctions()
	local func = {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	}

	return func
end

--------------------------------------------------------------------------------

function modifier_electrician_cleansing_shock_ally:GetModifierMoveSpeedBonus_Percentage( event )
	return self.moveSpeed
end

--------------------------------------------------------------------------------

modifier_electrician_cleansing_shock_enemy = class( ModifierBaseClass )

--------------------------------------------------------------------------------

function modifier_electrician_cleansing_shock_enemy:IsDebuff()
	return true
end

function modifier_electrician_cleansing_shock_enemy:IsHidden()
	return false
end

function modifier_electrician_cleansing_shock_enemy:IsPurgable()
	return true
end

--------------------------------------------------------------------------------

function modifier_electrician_cleansing_shock_enemy:OnCreated( event )
	local spell = self:GetAbility()
	local interval = spell:GetSpecialValueFor( "speed_update_interval" )
	self.moveSpeed = spell:GetSpecialValueFor( "move_speed_bonus" )
	self.intervalChange = self.moveSpeed / ( self:GetDuration() / interval )

	self:StartIntervalThink( interval )
end

--------------------------------------------------------------------------------

function modifier_electrician_cleansing_shock_enemy:OnRefresh( event )
	local spell = self:GetAbility()
	local interval = spell:GetSpecialValueFor( "speed_update_interval" )
	self.moveSpeed = spell:GetSpecialValueFor( "slow" )
	self.intervalChange = self.moveSpeed / ( self:GetDuration() / interval )

	self:StartIntervalThink( interval )
end

--------------------------------------------------------------------------------

function modifier_electrician_cleansing_shock_enemy:OnIntervalThink()
	self.moveSpeed = self.moveSpeed - self.intervalChange
end

--------------------------------------------------------------------------------

function modifier_electrician_cleansing_shock_enemy:DeclareFunctions()
	local func = {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	}

	return func
end

--------------------------------------------------------------------------------

function modifier_electrician_cleansing_shock_enemy:GetModifierMoveSpeedBonus_Percentage( event )
	return -self.moveSpeed
end
