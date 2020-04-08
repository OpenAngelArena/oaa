item_greater_phase_boots = class(ItemBaseClass)

--LinkLuaModifier("modifier_intrinsic_multiplexer", "modifiers/modifier_intrinsic_multiplexer.lua", LUA_MODIFIER_MOTION_NONE)

--------------------------------------------------------------------------------

function item_greater_phase_boots:GetIntrinsicModifierName()
	return "modifier_item_phase_boots" -- "modifier_intrinsic_multiplexer"
end
-- uncomment this if we plan to add more effects to Phase Boots
--[[
function item_greater_phase_boots:GetIntrinsicModifierNames()
  return {
    "modifier_item_phase_boots",
  }
end
]]

function item_greater_phase_boots:OnSpellStart()
  local caster = self:GetCaster()
  local active_duration = self:GetSpecialValueFor("phase_duration")

  -- play the sound
  caster:EmitSound( "DOTA_Item.PhaseBoots.Activate" )

  -- Disjoint projectiles on cast
	ProjectileManager:ProjectileDodge(caster)

  -- Add the vanilla phase active modifier
  caster:AddNewModifier( caster, self, "modifier_item_phase_boots_active", { duration = active_duration } )

  -- Add the vanilla spider legs modifier (free pathing and cool visual spider effect)
  caster:AddNewModifier( caster, self, "modifier_item_spider_legs_active", { duration = active_duration } )
end

--[[  Old split attack Greater Phase Boots effect - it procced instant attacks to splintered targets
LinkLuaModifier( "modifier_item_greater_phase_boots_splinter_shot", "items/farming/greater_phase_boots.lua", LUA_MODIFIER_MOTION_NONE )

function item_greater_phase_boots:OnProjectileHit(target, location)
  if IsValidEntity(target) then
    local caster = self:GetCaster()
    -- Make the modifier reduce damage for the attack
    self.splinterMod.doReduction = true
    caster:PerformAttack(target, false, false, true, false, false, false, false)

    -- Reset the damage reduction after the attack is done
    self.splinterMod.doReduction = false
  end
end

function modifier_item_greater_phase_boots_splinter_shot:IsHidden()
	return true
end

function modifier_item_greater_phase_boots_splinter_shot:OnAttackLanded(keys)
  local parent = self:GetParent()
  if keys.attacker == parent and keys.process_procs and not self.doReduction then
    local ability = self:GetAbility()

    local units = FindUnitsInRadius(
      parent:GetTeamNumber(),
      keys.target:GetAbsOrigin(),
      nil,
      ability:GetSpecialValueFor("splinter_radius"),
      DOTA_UNIT_TARGET_TEAM_ENEMY,
      DOTA_UNIT_TARGET_BASIC,
      bit.bor(DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE, DOTA_UNIT_TARGET_FLAG_NO_INVIS),
      FIND_ANY_ORDER,
      false
    )
    -- Exclude the original attack target from list of units to splinter to
    table.remove(units, index(keys.target, units))
    -- Take only neutral unit types to avoid targeting summons
    local function IsNeutralUnitType(unit)
      return unit:IsNeutralUnitType()
    end
    local neutralUnits = filter(IsNeutralUnitType, units)
    -- Take the first splinter_number units to split to
    local nUnits = take_n(ability:GetSpecialValueFor("splinter_count"), neutralUnits)

    -- Default to Drow Ranger's projectile
    local projectileName = "particles/units/heroes/hero_drow/drow_base_attack.vpcf"
    local projectileSpeed = ability:GetSpecialValueFor("melee_splinter_speed")

    if parent:IsRangedAttacker() then
      projectileName = parent:GetRangedProjectileName()
      projectileSpeed = parent:GetProjectileSpeed()
    end

    local function CreateSplinterProjectile(target)
      local projectileData = {
        Target = target,
        Ability = ability,
        EffectName = projectileName,
        iMoveSpeed = projectileSpeed,
        vSourceLoc = keys.target:GetAbsOrigin(),
        bDrawsOnMinimap = false,
        bDodgeable = true,
        bIsAttack = true,
        bVisibleToEnemies = true,
        bReplaceExisting = false,
        bProvidesVision = false
      }
      ProjectileManager:CreateTrackingProjectile(projectileData)
    end

    foreach(CreateSplinterProjectile, nUnits)
  end
end

function modifier_item_greater_phase_boots_splinter_shot:GetModifierDamageOutgoing_Percentage( event )
 local spell = self:GetAbility()
 local parent = self:GetParent()

 if self.doReduction then
   return spell:GetSpecialValueFor( "splinter_attack_outgoing" ) - 100
 end

 return 0
end
]]


--[[ Old mini-Shukuchi Greater Phase Boots effect
LinkLuaModifier( "modifier_item_greater_phase_boots_active", "items/farming/greater_phase_boots.lua", LUA_MODIFIER_MOTION_NONE )

modifier_item_greater_phase_boots_active = class(ModifierBaseClass)

--------------------------------------------------------------------------------

function modifier_item_greater_phase_boots_active:IsHidden()
	return false
end

function modifier_item_greater_phase_boots_active:IsDebuff()
	return false
end

function modifier_item_greater_phase_boots_active:IsPurgable()
	return false
end

--------------------------------------------------------------------------------

function modifier_item_greater_phase_boots_active:GetEffectName()
	return "particles/items2_fx/phase_boots.vpcf"
end

--------------------------------------------------------------------------------

function modifier_item_greater_phase_boots_active:OnCreated( event )
	local spell = self:GetAbility()

	self.moveSpd = spell:GetSpecialValueFor( "phase_movement_speed" )
	self.moveSpdRange = spell:GetSpecialValueFor( "phase_movement_speed_range" )
	self.dmgReduction = spell:GetSpecialValueFor( "phase_attack_outgoing" ) - 100

	if IsServer() then
		-- set up the table that stores the targets already hit
		self.hitTargets = {}

		-- start thinking
		-- we call OnIntervalThink to make it so it can go into effect immediately
		-- as StartIntervalThink waits for the interval to pass first
		self:OnIntervalThink()
		self:StartIntervalThink( 1 / 30 )
	end
end

--------------------------------------------------------------------------------

function modifier_item_greater_phase_boots_active:OnRefresh( event )
	local spell = self:GetAbility()

	self.moveSpd = spell:GetSpecialValueFor( "phase_movement_speed" )
	self.moveSpdRange = spell:GetSpecialValueFor( "phase_movement_speed_range" )
	self.dmgReduction = spell:GetSpecialValueFor( "phase_attack_outgoing" ) - 100

	if IsServer() then
		-- clear the tagets hit table on refresh
		self.hitTargets = {}
	end
end

--------------------------------------------------------------------------------

if IsServer() then
	function modifier_item_greater_phase_boots_active:HasHitUnit( target )
		for _, unit in pairs( self.hitTargets ) do
			if unit == target then
				return true
			end
		end

		return false
	end

--------------------------------------------------------------------------------

	function modifier_item_greater_phase_boots_active:OnIntervalThink()
		local parent = self:GetParent()
		local spell = self:GetAbility()

		-- find all enemy creeps in range
		local units = FindUnitsInRadius(
			parent:GetTeamNumber(),
			parent:GetAbsOrigin(),
			nil,
			spell:GetSpecialValueFor( "phase_radius" ),
			DOTA_UNIT_TARGET_TEAM_ENEMY,
			DOTA_UNIT_TARGET_BASIC,
			DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
			FIND_ANY_ORDER,
			false
		)

		-- tell this modifier to reduce the damage of any further attacks
		-- aka, the instant attacks
		self.doReduction = true

		for _, unit in pairs( units ) do
			-- we don't hit units that have already been hit by this cast
			-- or those that are controlled by a player
			if not unit:IsControllableByAnyPlayer() and not self:HasHitUnit( unit ) then
				-- add the unit to the targets hit list
				table.insert( self.hitTargets, unit )

				-- do an instant attack with no projectile that applies procs
				parent:PerformAttack( unit, true, true, true, false, false, false, true )

				-- play the particle
				local part = ParticleManager:CreateParticle( "particles/items/phase_divehit.vpcf", PATTACH_ABSORIGIN, unit )
				ParticleManager:SetParticleControlEnt( part, 1, unit, PATTACH_POINT, "attach_hitloc", unit:GetAbsOrigin(), true )
				ParticleManager:ReleaseParticleIndex( part )
			end
		end

		-- undo the damage reduction, so it doesn't leak into actual attacks
		self.doReduction = false
	end
end

--------------------------------------------------------------------------------

function modifier_item_greater_phase_boots_active:CheckState()
	local state = {
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
	}

	return state
end

--------------------------------------------------------------------------------

function modifier_item_greater_phase_boots_active:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE,
	}

	return funcs
end

--------------------------------------------------------------------------------

function modifier_item_greater_phase_boots_active:GetModifierMoveSpeedBonus_Percentage( event )
	local spell = self:GetAbility()
	local parent = self:GetParent()

	if parent:IsRangedAttacker() then
		return self.moveSpdRange or spell:GetSpecialValueFor( "phase_movement_speed_range" )
	end

	return self.moveSpd or spell:GetSpecialValueFor( "phase_movement_speed" )
end

--------------------------------------------------------------------------------

function modifier_item_greater_phase_boots_active:GetModifierDamageOutgoing_Percentage( event )
	local spell = self:GetAbility()
	local parent = self:GetParent()

	if self.doReduction then
		return self.dmgReduction or spell:GetSpecialValueFor( "phase_attack_outgoing" ) - 100
	end

	return 0
end
]]

item_greater_phase_boots_2 = class(item_greater_phase_boots)
item_greater_phase_boots_3 = class(item_greater_phase_boots)
item_greater_phase_boots_4 = class(item_greater_phase_boots)
item_greater_phase_boots_5 = class(item_greater_phase_boots)
