faceless_void_time_lock_oaa = class( AbilityBaseClass )

LinkLuaModifier("modifier_faceless_void_time_lock_oaa", "abilities/oaa_time_lock.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_time_lock_time_frozen", "abilities/oaa_time_lock.lua", LUA_MODIFIER_MOTION_NONE)

--------------------------------------------------------------------------------

function faceless_void_time_lock_oaa:GetIntrinsicModifierName()
  return "modifier_faceless_void_time_lock_oaa"
end

function faceless_void_time_lock_oaa:ShouldUseResources()
  return true
end

--------------------------------------------------------------------------------

modifier_faceless_void_time_lock_oaa = class( ModifierBaseClass )

--------------------------------------------------------------------------------

function modifier_faceless_void_time_lock_oaa:IsHidden()
  return true
end

function modifier_faceless_void_time_lock_oaa:IsDebuff()
  return false
end

function modifier_faceless_void_time_lock_oaa:IsPurgable()
  return false
end

function modifier_faceless_void_time_lock_oaa:RemoveOnDeath()
  return false
end

--------------------------------------------------------------------------------

function modifier_faceless_void_time_lock_oaa:DeclareFunctions()
  local funcs = {
  --MODIFIER_PROPERTY_PROCATTACK_BONUS_DAMAGE_MAGICAL, -- old time lock
  MODIFIER_EVENT_ON_ATTACK_LANDED,
}

return funcs
end

--------------------------------------------------------------------------------

if IsServer() then
  -- we're putting the stuff in this function because it's only run on a successful attack
  -- and it runs before OnAttackLanded, so we need to determine if a bash happens before then
  --[[
  function modifier_faceless_void_time_lock_oaa:GetModifierProcAttack_BonusDamage_Magical( event )
    local parent = self:GetParent()

    -- no bash while broken or illusion
    if parent:PassivesDisabled() or parent:IsIllusion() then
      return 0
    end

    local target = event.target

    -- can't bash towers or wards, but can bash allies
    if UnitFilter( target, DOTA_UNIT_TARGET_TEAM_BOTH, bit.bor( DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC ), DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, parent:GetTeamNumber() ) ~= UF_SUCCESS then
      return 0
    end

    local spell = self:GetAbility()

    -- don't bash while on cooldown
    if not spell:IsCooldownReady() then
      return 0
    end

    local chance = spell:GetSpecialValueFor( "chance_pct" ) / 100

    -- we're using the modifier's stack to store the amount of prng failures
    -- this could be something else but since this modifier is hidden anyway ...
    local prngMult = self:GetStackCount() + 1

    -- compared prng to slightly less prng
    if RandomFloat( 0.0, 1.0 ) <= ( PrdCFinder:GetCForP(chance) * prngMult ) then
      -- reset failure count
      self:SetStackCount( 0 )

      local duration = spell:GetSpecialValueFor( "duration" )

      -- creeps have a different duration
      if not target:IsHero() then
        duration = spell:GetSpecialValueFor( "duration_creep" )
      end

      -- apply the stun modifier
      duration = target:GetValueChangedByStatusResistance(duration)
      target:AddNewModifier( parent, spell, "modifier_faceless_void_timelock_freeze", { duration = duration } )
      target:EmitSound( "Hero_FacelessVoid.TimeLockImpact" )

      -- use cooldown ( and mana, if necessary )
      spell:UseResources( true, true, true )

      -- do another atttack that cannot miss after cd is started to prevent self-proccing
      parent:PerformAttack(target, true, true, true, false, false, false, true)

      -- because talents are dumb we need to manually get its value
      local damageTalent = 0

      local dtalent = parent:FindAbilityByName( "special_bonus_unique_faceless_void_3" )

      -- we also have to manually check if it's been skilled or not
      if dtalent and dtalent:GetLevel() > 0 then
        damageTalent = dtalent:GetSpecialValueFor( "value" )
      end

      -- apply the proc damage
      return spell:GetSpecialValueFor( "bonus_damage" ) + damageTalent

    else
      -- increment failure count
      self:SetStackCount( prngMult )

      return 0
    end
  end
  ]]
  -- New Time Lock - code inspired by Time Lock in dota imba
  -- Wiki: The chance for proc will not increase by an event in which an activation cannot occur.
  function modifier_faceless_void_time_lock_oaa:OnAttackLanded(event)
    local parent = self:GetParent()
    local ability = self:GetAbility()
    local target = event.target

    if parent ~= event.attacker then
      return
    end

    -- No bash while broken or illusion
    if parent:PassivesDisabled() or parent:IsIllusion() then
      return
    end

    -- To prevent crashes:
    if not target then
      return
    end

    if target:IsNull() then
      return
    end

    -- Don't affect buildings, wards and invulnerable units.
    if target:IsTower() or target:IsBarracks() or target:IsBuilding() or target:IsOther() or target:IsInvulnerable() then
      return
    end

    -- Don't bash while on cooldown
    if not ability:IsCooldownReady() then
      return
    end

    local chance = ability:GetSpecialValueFor("chance_pct")/100

    -- Get number of failures
    local prngMult = self:GetStackCount() + 1

    -- compared prng to slightly less prng
    if RandomFloat(0.0, 1.0) <= (PrdCFinder:GetCForP(chance) * prngMult) then
      -- Reset failure count
      self:SetStackCount(0)

      -- Calculate duration
      local duration = ability:GetSpecialValueFor("duration")

      -- Creeps have a different duration
      if not target:IsHero() then
        duration = ability:GetSpecialValueFor("duration_creep")
      end

      -- Duration with status resistance in mind
      duration = target:GetValueChangedByStatusResistance(duration)

      -- Apply built-in stun modifier
      target:AddNewModifier(parent, ability, "modifier_faceless_void_timelock_freeze", {duration = duration})

      -- Custom Scepter debuff
      if parent:HasScepter() then
        target:AddNewModifier(parent, ability, "modifier_time_lock_time_frozen", {duration = duration})
      end

      -- Sound of Time Lock stun
      target:EmitSound("Hero_FacelessVoid.TimeLockImpact")

      -- Start cooldown respecting cooldown reductions
      ability:UseResources(true, true, true)

      -- Calculate bonus damage
      local bonus_damage = ability:GetSpecialValueFor("bonus_damage")
      local talent = parent:FindAbilityByName("special_bonus_unique_faceless_void_3")

      if talent and talent:GetLevel() > 0 then
        bonus_damage = bonus_damage + talent:GetSpecialValueFor("value")
      end

      -- Damage table
      local damage_table = {}
      damage_table.attacker = parent
      damage_table.damage_type = ability:GetAbilityDamageType()
      damage_table.ability = ability
      damage_table.damage = bonus_damage
      damage_table.victim = target

      -- Apply bonus damage
      ApplyDamage(damage_table)

      -- Prepare for the second attack
      local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_faceless_void/faceless_void_time_lock_bash.vpcf", PATTACH_CUSTOMORIGIN, nil)
      ParticleManager:SetParticleControl(particle, 0, target:GetAbsOrigin() )
      ParticleManager:SetParticleControl(particle, 1, target:GetAbsOrigin() )
      ParticleManager:SetParticleControlEnt(particle, 2, parent, PATTACH_CUSTOMORIGIN, "attach_hitloc", target:GetAbsOrigin(), true)
      ParticleManager:ReleaseParticleIndex(particle)

      -- Second attack
      -- Delay is hard-coded in normal dota to 0.33 seconds as per the particle constraints
      local delay = ability:GetSpecialValueFor("second_attack_delay") or 0.33
      Timers:CreateTimer(delay, function()
        if target:IsAlive() then
          -- Perform the second attack (can trigger attack modifiers)
          if parent:HasScepter() then
            parent:PerformAttack(target, false, true, true, false, false, false, true)
          else
            parent:PerformAttack(target, false, true, true, false, false, false, false)
          end
          -- Emit sound again
          target:EmitSound("Hero_FacelessVoid.TimeLockImpact")
        end
      end)
    else
      -- Increment number of failures
      self:SetStackCount(prngMult)
    end
  end
end

--------------------------------------------------------------------------------

modifier_time_lock_time_frozen = class(ModifierBaseClass)

function modifier_time_lock_time_frozen:IsHidden()
	return true
end

function modifier_time_lock_time_frozen:IsDebuff()
	return true
end

function modifier_time_lock_time_frozen:IsStunDebuff()
  return true
end

function modifier_time_lock_time_frozen:IsPurgable()
	return true
end

function modifier_time_lock_time_frozen:CheckState()
	local state = {
		[MODIFIER_STATE_EVADE_DISABLED] = true,
	}

	return state
end

function modifier_time_lock_time_frozen:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_DISABLE_HEALING,
  }
  return funcs
end

function modifier_time_lock_time_frozen:GetDisableHealing()
  return 1
end

if IsServer() then
  function modifier_time_lock_time_frozen:OnCreated()
    local parent = self:GetParent()
    self:CooldownFreeze(parent)
    self:StartIntervalThink(0.1)
  end

  function modifier_time_lock_time_frozen:OnIntervalThink()
    local parent = self:GetParent()
    self:CooldownFreeze(parent)
  end
end

function modifier_time_lock_time_frozen:CooldownFreeze(target)
	-- Adds 0.1 second to the current cooldown to every spell off cooldown
	for i = 0, target:GetAbilityCount()-1 do
		local target_ability = target:GetAbilityByIndex(i)
		if target_ability then
			local cd = target_ability:GetCooldownTimeRemaining()
			if cd > 0 then
				target_ability:StartCooldown(cd + 0.1)
			end
		end
	end
end
