electrician_cleansing_shock = class( AbilityBaseClass )

LinkLuaModifier( "modifier_electrician_cleansing_shock_ally", "abilities/electrician/electrician_cleansing_shock.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_electrician_cleansing_shock_enemy", "abilities/electrician/electrician_cleansing_shock.lua", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------

-- CastFilterResultTarget is not called on a Server at all?
function electrician_cleansing_shock:CastFilterResultTarget(target)
  local default_result = self.BaseClass.CastFilterResultTarget(self, target)

  if default_result == UF_FAIL_MAGIC_IMMUNE_ENEMY then
    local caster = self:GetCaster()
    -- Talent that allows to target Spell Immune units
    local talent = caster:FindAbilityByName("special_bonus_electrician_cleansing_shock_pierce")
    if talent and talent:GetLevel() > 0 then
      return UF_SUCCESS
    end
  end

  return default_result
end

function electrician_cleansing_shock:GetManaCost(level)
	local caster = self:GetCaster()
  local base_mana_cost = self.BaseClass.GetManaCost(self, level)
  if caster:HasScepter() then
    return self:GetSpecialValueFor("mana_cost_scepter")
  end

  return base_mana_cost
end

function electrician_cleansing_shock:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	-- clean up the hit list
	self.hitTargets = {}

	if caster:HasScepter() then
		self:ApplyEffect( caster )
	end

	-- do the visual effect for the initial target
	self:ApplyLaser( caster, "attach_attack1", target, "attach_hitloc" )

	-- cast sound
	caster:EmitSound( "Hero_Tinker.Laser" )

	-- trigger and get blocked by linkens
	if not target:TriggerSpellAbsorb( self ) then
		-- set up abilityspecial
		local targets = self:GetSpecialValueFor( "bounces" ) + 1
		local bounceRange = self:GetSpecialValueFor( "bounce_range" )

		-- if caster has scepter, check number of bounces
		if caster:HasScepter() then
			targets = self:GetSpecialValueFor( "bounces_scepter" ) + 1
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
    -- Check if the enemy target is spell-immune
    if target:IsMagicImmune() then
      -- Check for talent that allows targetting spell immune
      if not caster:HasLearnedAbility("special_bonus_electrician_cleansing_shock_pierce") then
        return
      end
    end

    -- Basic Dispel (for enemies)
    target:Purge( true, false, false, false, false )

    -- Slow debuff
    target:AddNewModifier( caster, self, "modifier_electrician_cleansing_shock_enemy", { duration = duration } )

    -- Check for mini-stun talent
    local talent = caster:FindAbilityByName("special_bonus_electrician_cleansing_shock_stun")
    if talent and talent:GetLevel() > 0 then
      target:AddNewModifier(caster, self, "modifier_stunned", {duration = 0.1})
    end

    -- Check for current hp damage talent
    local talent2 = caster:FindAbilityByName("special_bonus_unique_electrician_9")
    if talent2 and talent2:GetLevel() > 0 then
      local damage_table = {
        attacker = caster,
        victim = target,
        damage_type = DAMAGE_TYPE_MAGICAL,
        ability = self,
        damage = target:GetHealth() * talent2:GetSpecialValueFor("value") * 0.01
      }

      ApplyDamage(damage_table)
    end

    -- Deal extra damage to summons, illusions and dominated units if caster has aghanim scepter
    if caster:HasScepter() and (target:IsSummoned() or target:IsDominated() or target:IsIllusion()) and not target:IsStrongIllusionOAA() then
      local summon_damage = self:GetSpecialValueFor("summon_illusion_damage_scepter")
      local damage_table = {
        attacker = caster,
        victim = target,
        damage_type = DAMAGE_TYPE_MAGICAL,
        ability = self,
        damage = summon_damage
      }

      ApplyDamage(damage_table)
    end
  else
    -- Basic Dispel (for allies)
    target:Purge( false, true, false, false, false )

    -- Movement speed buff
    target:AddNewModifier( caster, self, "modifier_electrician_cleansing_shock_ally", { duration = duration } )
  end

  if not target:IsNull() then
    -- particle
    local part = ParticleManager:CreateParticle( "particles/units/heroes/hero_zuus/zuus_static_field.vpcf", PATTACH_ABSORIGIN_FOLLOW, target )
    ParticleManager:ReleaseParticleIndex( part )

    -- sound
    target:EmitSound( "Hero_Tinker.LaserImpact" )

    -- add unit to hitlist
    table.insert( self.hitTargets, target )
  end
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
  local caster = self:GetCaster()
  local casterTeam = caster:GetTeamNumber()

	-- helperception
	local function FindInTable( t, target )
		for k, v in pairs( t ) do
			if v == target then
				return k
			end
		end

		return nil
	end

  local targetFlags = DOTA_UNIT_TARGET_FLAG_NONE
  -- Check for talent that allows targetting spell immune
  local talent = caster:FindAbilityByName("special_bonus_electrician_cleansing_shock_pierce")
  if talent and talent:GetLevel() > 0 then
    targetFlags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
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
			targetFlags,
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

---------------------------------------------------------------------------------------------------

modifier_electrician_cleansing_shock_ally = class(ModifierBaseClass)

function modifier_electrician_cleansing_shock_ally:IsDebuff()
	return false
end

function modifier_electrician_cleansing_shock_ally:IsHidden()
	return false
end

function modifier_electrician_cleansing_shock_ally:IsPurgable()
	return true
end

function modifier_electrician_cleansing_shock_ally:OnCreated()
  local spell = self:GetAbility()
  local interval = spell:GetSpecialValueFor("speed_update_interval")
  self.moveSpeed = spell:GetSpecialValueFor("move_speed_bonus")
  self.attackSpeed = spell:GetSpecialValueFor("attack_speed_bonus")

  local duration = self:GetDuration()
  self.moveSpeedChange = self.moveSpeed / ( duration / interval )
  self.attackSpeedChange = self.attackSpeed / ( duration / interval )

	self:StartIntervalThink(interval)
end

function modifier_electrician_cleansing_shock_ally:OnRefresh()
  self:OnCreated()
end

function modifier_electrician_cleansing_shock_ally:OnIntervalThink()
  self.moveSpeed = self.moveSpeed - self.moveSpeedChange
  self.attackSpeed = self.attackSpeed - self.attackSpeedChange
end

function modifier_electrician_cleansing_shock_ally:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
  }
end

function modifier_electrician_cleansing_shock_ally:GetModifierMoveSpeedBonus_Percentage()
  return math.max(0, self.moveSpeed)
end

function modifier_electrician_cleansing_shock_ally:GetModifierAttackSpeedBonus_Constant()
  return math.max(0, self.attackSpeed)
end

---------------------------------------------------------------------------------------------------

modifier_electrician_cleansing_shock_enemy = class(ModifierBaseClass)

function modifier_electrician_cleansing_shock_enemy:IsDebuff()
	return true
end

function modifier_electrician_cleansing_shock_enemy:IsHidden()
	return false
end

function modifier_electrician_cleansing_shock_enemy:IsPurgable()
	return true
end

function modifier_electrician_cleansing_shock_enemy:OnCreated()
  local parent = self:GetParent()
  local spell = self:GetAbility()
  local interval = spell:GetSpecialValueFor("speed_update_interval")
  local move_slow = spell:GetSpecialValueFor("move_slow")
  local attack_slow = spell:GetSpecialValueFor("attack_slow")

  if IsServer() then
    self.moveSpeed = parent:GetValueChangedByStatusResistance(move_slow)
    self.attackSpeed = parent:GetValueChangedByStatusResistance(attack_slow)
  else
    self.moveSpeed = move_slow
    self.attackSpeed = attack_slow
  end

  local duration = self:GetDuration()
  self.moveSpeedChange = self.moveSpeed / ( duration / interval )
  self.attackSpeedChange = self.attackSpeed / ( duration / interval )

	self:StartIntervalThink(interval)
end

function modifier_electrician_cleansing_shock_enemy:OnRefresh()
  self:OnCreated()
end

function modifier_electrician_cleansing_shock_enemy:OnIntervalThink()
  self.moveSpeed = self.moveSpeed - self.moveSpeedChange
  self.attackSpeed = self.attackSpeed - self.attackSpeedChange
end

function modifier_electrician_cleansing_shock_enemy:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
  }
end

function modifier_electrician_cleansing_shock_enemy:GetModifierMoveSpeedBonus_Percentage()
	return math.min(0, 0 - math.abs(self.moveSpeed))
end

function modifier_electrician_cleansing_shock_enemy:GetModifierAttackSpeedBonus_Constant()
  return math.min(0, 0 - math.abs(self.attackSpeed))
end
