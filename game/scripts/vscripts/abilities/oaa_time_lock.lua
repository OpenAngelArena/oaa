faceless_void_time_lock_oaa = class( AbilityBaseClass )

LinkLuaModifier("modifier_faceless_void_time_lock_oaa", "abilities/oaa_time_lock.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_faceless_void_time_walk_scepter_proc_oaa", "abilities/oaa_time_lock.lua", LUA_MODIFIER_MOTION_NONE)
--LinkLuaModifier("modifier_faceless_void_chronosphere_scepter_oaa", "abilities/oaa_time_lock.lua", LUA_MODIFIER_MOTION_NONE)

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
  return {
    --MODIFIER_PROPERTY_PROCATTACK_BONUS_DAMAGE_MAGICAL, -- old time lock
    MODIFIER_EVENT_ON_ATTACK_LANDED,
    MODIFIER_EVENT_ON_MODIFIER_ADDED,
  }
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

      -- go on cooldown
      spell:UseResources( false, false, false, true )

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
    local attacker = event.attacker
    local target = event.target

    -- Check if attacker exists
    if not attacker or attacker:IsNull() then
      return
    end

    -- Check if attacker has this modifier
    if attacker ~= parent then
      return
    end

    -- No bash while broken or illusion
    if parent:PassivesDisabled() or parent:IsIllusion() then
      return
    end

    -- Check if attacked unit exists
    if not target or target:IsNull() then
      return
    end

    -- Check for existence of GetUnitName method to determine if target is a unit or an item (or rune)
    -- items don't have that method -> nil; if the target is an item, don't continue
    if target.GetUnitName == nil then
      return
    end

    -- Don't affect buildings, wards and invulnerable units.
    if target:IsTower() or target:IsBarracks() or target:IsBuilding() or target:IsOther() or target:IsInvulnerable() then
      return
    end

    -- Don't trigger when attacking allies or self
    if target == parent or target:GetTeamNumber() == parent:GetTeamNumber() then
      return
    end

    -- Don't bash while on cooldown
    if not ability:IsCooldownReady() then
      return
    end

    local chance = ability:GetSpecialValueFor("chance_pct") / 100

    -- Get number of failures
    local prngMult = self:GetStackCount() + 1

    -- compared prng to slightly less prng
    if RandomFloat(0.0, 1.0) <= (PrdCFinder:GetCForP(chance) * prngMult) then
      -- Reset failure count
      self:SetStackCount(0)

      self:ApplyTimeLock(ability, target)
    else
      -- Increment number of failures
      self:SetStackCount(prngMult)
    end
  end

  function modifier_faceless_void_time_lock_oaa:ApplyTimeLock(ability, target)
    if not ability then
      ability = self:GetAbility()
    end
    if not target then
      return
    end
    local parent = self:GetParent()
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

    -- Sound of Time Lock stun
    target:EmitSound("Hero_FacelessVoid.TimeLockImpact")

    -- Start cooldown respecting cooldown reductions
    ability:UseResources(false, false, false, true)

    -- Calculate bonus damage
    local min_damage = ability:GetSpecialValueFor("min_damage")
    local max_damage = ability:GetSpecialValueFor("max_damage")

    -- Bonus damage talent
    local talent = parent:FindAbilityByName("special_bonus_unique_faceless_void_3_oaa")
    if talent and talent:GetLevel() > 0 then
      min_damage = min_damage + talent:GetSpecialValueFor("value")
      max_damage = max_damage + talent:GetSpecialValueFor("value2")
    end

    local bonus_damage = min_damage

    -- Imitate multiple proccing without instant attack on each proc
    -- We use true random to simplify the code and to make it more fair and balanced
    local chance = ability:GetSpecialValueFor("chance_pct")
    if RandomInt(0, 100) <= chance then
      bonus_damage = (min_damage + max_damage) / 2
      if RandomInt(0, 100) <= chance then
        bonus_damage = max_damage
      end
    end

    -- Damage table
    local damage_table = {
      attacker = parent,
      victim = target,
      damage = bonus_damage,
      damage_type = ability:GetAbilityDamageType(),
      ability = ability,
    }

    -- Apply bonus damage
    ApplyDamage(damage_table)

    -- Prepare for the second attack
    local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_faceless_void/faceless_void_time_lock_bash.vpcf", PATTACH_CUSTOMORIGIN, nil)
    ParticleManager:SetParticleControl(particle, 0, target:GetAbsOrigin() )
    ParticleManager:SetParticleControl(particle, 1, target:GetAbsOrigin() )
    ParticleManager:SetParticleControlEnt(particle, 2, parent, PATTACH_CUSTOMORIGIN, "attach_hitloc", target:GetAbsOrigin(), true)
    ParticleManager:ReleaseParticleIndex(particle)

    -- Second attack
    local delay = ability:GetSpecialValueFor("second_attack_delay") or 0.4
    Timers:CreateTimer(delay, function()
      if target:IsAlive() and not target:IsNull() then -- and target:HasModifier("modifier_faceless_void_time_lock_oaa")
        -- Perform the second attack (can trigger attack modifiers)
        parent:PerformAttack(target, false, true, true, false, false, false, false)
        -- Emit sound again
        target:EmitSound("Hero_FacelessVoid.TimeLockImpact")
      end
    end)
  end

  -- Scepter effects: Time Walk applies AoE Time Lock
  function modifier_faceless_void_time_lock_oaa:OnModifierAdded(event)
    local parent = self:GetParent()

    -- Check if parent has Aghanim Scepter
    if not parent:HasScepter() then
      return
    end

    -- Unit that gained a modifier
    local unit = event.unit

    if parent == unit and not parent:HasModifier("modifier_faceless_void_time_walk_scepter_proc_oaa") then
      local time_walk_modifier = parent:FindModifierByName("modifier_faceless_void_time_walk")
      if not time_walk_modifier then
        return
      end
      local remaining_duration = time_walk_modifier:GetRemainingTime()
      parent:AddNewModifier(parent, nil, "modifier_faceless_void_time_walk_scepter_proc_oaa", {duration = remaining_duration})
    end

    --[[
    -- If the unit is not actually a unit but its an entity that can gain modifiers
    if unit.HasModifier == nil then
      return
    end

    -- If the unit is the same team as parent don't continue
    if unit:GetTeamNumber() == parent:GetTeamNumber() then
      return
    end

    -- Apply scepter debuff with first tick of Chronosphere
    if unit:HasModifier("modifier_faceless_void_chronosphere_freeze") and not unit:HasModifier("modifier_faceless_void_chronosphere_scepter_oaa") then
      local chrono_ability = parent:FindAbilityByName("faceless_void_chronosphere")
      if not chrono_ability then
        return
      end
      local chrono_duration = chrono_ability:GetLevelSpecialValueFor("duration", chrono_ability:GetLevel()-1)
      unit:AddNewModifier(parent, nil, "modifier_faceless_void_chronosphere_scepter_oaa", {duration = chrono_duration})
    end
    ]]
  end
end

---------------------------------------------------------------------------------------------------

modifier_faceless_void_time_walk_scepter_proc_oaa = class(ModifierBaseClass)

function modifier_faceless_void_time_walk_scepter_proc_oaa:IsHidden()
  return true
end

function modifier_faceless_void_time_walk_scepter_proc_oaa:IsDebuff()
  return false
end

function modifier_faceless_void_time_walk_scepter_proc_oaa:IsPurgable()
  return false
end

function modifier_faceless_void_time_walk_scepter_proc_oaa:OnDestroy()
  local parent = self:GetParent()

  if not IsServer() then
    return
  end

  -- Get Time Lock ability and modifier
  local time_lock_ability = parent:FindAbilityByName("faceless_void_time_lock_oaa")
  local time_lock_modifier = parent:FindModifierByName("modifier_faceless_void_time_lock_oaa")

  -- Check if Time Lock exists
  -- It doesnt exist in some edge cases: maybe when Morphling is morphed into Faceless Void
  -- and morphs back into Morphling after using Time Walk
  if not time_lock_ability or not time_lock_modifier then
    return
  end

  -- Get Time Walk ability
  local time_walk_ability = parent:FindAbilityByName("faceless_void_time_walk")

  -- Check if Time Walk exists
  -- This shouldn't be possible but checking just in case dota is weird
  if not time_walk_ability then
    return
  end

  -- Get cast position
  local cast_position = parent:GetAbsOrigin()
  --print("Cast Position is: "..tostring(cast_position))

  -- Get radius
  local radius = time_walk_ability:GetSpecialValueFor("radius_scepter")

  -- Find enemies in radius (ignore spell immune enemies on purpose)
  local enemies = FindUnitsInRadius(
    parent:GetTeamNumber(),
    cast_position,
    nil,
    radius,
    DOTA_UNIT_TARGET_TEAM_ENEMY,
    bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC),
    DOTA_UNIT_TARGET_FLAG_NONE,
    FIND_ANY_ORDER,
    false
  )

  for _, enemy in pairs(enemies) do
    if enemy and not enemy:IsNull() and not enemy:IsMagicImmune() and not enemy:IsAttackImmune() and not enemy:IsInvulnerable() and not parent:IsDisarmed() then
      time_lock_modifier:ApplyTimeLock(time_lock_ability, enemy)
    end
  end
end

---------------------------------------------------------------------------------------------------
--[[ -- modifier that disables evasion, disables healing and "freezes" ability cooldowns
modifier_faceless_void_chronosphere_scepter_oaa = class(ModifierBaseClass)

function modifier_faceless_void_chronosphere_scepter_oaa:IsHidden()
  return true
end

function modifier_faceless_void_chronosphere_scepter_oaa:IsDebuff()
  return true
end

function modifier_faceless_void_chronosphere_scepter_oaa:IsStunDebuff()
  return true
end

function modifier_faceless_void_chronosphere_scepter_oaa:IsPurgable()
  return true
end

function modifier_faceless_void_chronosphere_scepter_oaa:CheckState()
  return {
    [MODIFIER_STATE_EVADE_DISABLED] = true,
  }
end

function modifier_faceless_void_chronosphere_scepter_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_DISABLE_HEALING,
  }
end

function modifier_faceless_void_chronosphere_scepter_oaa:GetDisableHealing()
  return 1
end

if IsServer() then
  function modifier_faceless_void_chronosphere_scepter_oaa:OnCreated()
    local parent = self:GetParent()
    self:CooldownFreeze(parent)
    self:StartIntervalThink(0.1)
  end

  function modifier_faceless_void_chronosphere_scepter_oaa:OnIntervalThink()
    local parent = self:GetParent()
    self:CooldownFreeze(parent)
    -- Remove this debuff if parent is not affected by Chronosphere anymore
    if not parent:HasModifier("modifier_faceless_void_chronosphere_freeze") then
      self:Destroy()
    end
  end
end

function modifier_faceless_void_chronosphere_scepter_oaa:CooldownFreeze(target)
  -- Adds 0.1 second to the current cooldown to every spell off cooldown
  for i = 0, target:GetAbilityCount() - 1 do
    local target_ability = target:GetAbilityByIndex(i)
    if target_ability then
      local cd = target_ability:GetCooldownTimeRemaining()
        if cd > 0 then
          target_ability:StartCooldown(cd + 0.1)
        end
    end
  end
end
]]
