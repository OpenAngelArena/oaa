LinkLuaModifier("modifier_boss_slime_split_passive", "abilities/boss/slime/boss_slime_split.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_boss_slime_invulnerable_oaa", "abilities/boss/slime/boss_slime_split.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_boss_slime_dead_tracker", "abilities/boss/slime/boss_slime_split.lua", LUA_MODIFIER_MOTION_NONE)

boss_slime_split = class(AbilityBaseClass)

function boss_slime_split:Precache(context)
  PrecacheResource("model", "models/creeps/darkreef/blob/darkreef_blob_01.vmdl", context)
  PrecacheResource("model", "models/creeps/darkreef/blob/darkreef_blob_02_small.vmdl", context)
end

function boss_slime_split:GetIntrinsicModifierName()
	return "modifier_boss_slime_split_passive"
end

---------------------------------------------------------------------------------------------------

modifier_boss_slime_split_passive = class(ModifierBaseClass)

function modifier_boss_slime_split_passive:IsHidden()
  return true
end

function modifier_boss_slime_split_passive:IsDebuff()
  return false
end

function modifier_boss_slime_split_passive:IsPurgable()
  return false
end

function modifier_boss_slime_split_passive:RemoveOnDeath()
  return false
end

function modifier_boss_slime_split_passive:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MIN_HEALTH, -- GetMinHealth
    MODIFIER_PROPERTY_MODEL_CHANGE, -- GetModifierModelChange
    MODIFIER_PROPERTY_MODEL_SCALE, -- GetModifierModelScale
    MODIFIER_EVENT_ON_TAKEDAMAGE, -- OnTakeDamage
    MODIFIER_EVENT_ON_DEATH, -- OnDeath
  }
end

function modifier_boss_slime_split_passive:GetMinHealth()
  if not self.readyToDie then
    return 1
  end
end

function modifier_boss_slime_split_passive:GetModifierModelChange()
  return "models/creeps/darkreef/blob/darkreef_blob_01.vmdl"
end

function modifier_boss_slime_split_passive:GetModifierModelScale()
  return 150
end

if IsServer() then
  function modifier_boss_slime_split_passive:OnTakeDamage(event)
    local parent = self:GetParent()
    local attacker = event.attacker
    local damaged_unit = event.unit

    -- Check if attacker exists
    if not attacker or attacker:IsNull() then
      return
    end

    -- Check if damaged entity exists
    if not damaged_unit or damaged_unit:IsNull() then
      return
    end

    -- Check if damaged entity is the parent
    if damaged_unit ~= parent then
      return
    end

    if parent:GetHealth() <= 1.0 then
      local shakeAbility = parent:FindAbilityByName("boss_slime_shake")
      if shakeAbility then
        parent:Stop()
        shakeAbility:EndCooldown()
        ExecuteOrderFromTable({
          UnitIndex = parent:entindex(),
          OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
          AbilityIndex = shakeAbility:entindex(),
          Queue = false,
        })
        parent:AddNewModifier(parent, shakeAbility, "modifier_boss_slime_invulnerable_oaa", {})

        self.readyToDie = true

        -- Do stuff after a delay
        self:StartIntervalThink(shakeAbility:GetChannelTime() + 0.1)
      end
    end
	end

  function modifier_boss_slime_split_passive:OnIntervalThink()
    local parent = self:GetParent()

    self:StartIntervalThink(-1)

    -- Somebody killed the boss through invulnerability ...
    if not parent or parent:IsNull() or not parent:IsAlive() then
      return
    end

    -- Remove invulnerability so we can kill it
    parent:RemoveModifierByName("modifier_boss_slime_invulnerable_oaa")

    local event = {
      unit = parent,
    }
    self:OnDeath(event)
  end

  function modifier_boss_slime_split_passive:OnDeath(event)
    local parent = self:GetParent()
    local dead = event.unit

    -- Check if dead unit has this modifier
    if dead ~= parent then
      return
    end

    -- Check if this code was already executed - failsafe if ForceKillOAA triggers OnDeath
    if self.already_happened then
      return
    end

    self.already_happened = true

    local death_location = parent:GetAbsOrigin()
    local name = parent:GetUnitName()
    local spawner = parent.Spawner
    if not spawner or spawner:IsNull() then
      -- this shouldnt happen but putting a failsafe
      print("SPAWNER FOR THE SLIME BOSS DOES NOT EXIST, SEARCHING FOR THE NEAREST SLIME SPAWNER!")
      local friendlies = FindUnitsInRadius(
        parent:GetTeamNumber(),
        death_location,
        nil,
        FIND_UNITS_EVERYWHERE,
        DOTA_UNIT_TARGET_TEAM_FRIENDLY,
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD,
        FIND_CLOSEST,
        false
      )
      for _, friendly in ipairs(friendlies) do
        if friendly and not friendly:IsNull() then
          if friendly:GetUnitName() == "npc_dota_creature_slime_spawner" then
            spawner = friendly
            break
          end
        end
      end
      if not spawner or spawner:IsNull() then
        print("CANNOT FIND THE SLIME SPAWNER, USING BIG SLIME BOSS AS REPLACEMENT!")
        spawner = parent
      else
        print("FOUND THE NEAREST SLIME SPAWNER!")
      end
    end

    -- Hide the unit death animation
    parent:AddNoDraw()

    self:CreateClone(name, death_location + Vector( 100,0,0), spawner)
    self:CreateClone(name, death_location + Vector(-100,0,0), spawner)

    -- Needed if OnDeath is triggered through OnIntervalThink and if ForceKillOAA doesn't trigger it
    if parent and not parent:IsNull() and parent:IsAlive() then
      --parent:Kill(nil, parent) -- crashes
      parent:ForceKillOAA(false) -- sometimes triggers OnDeath, sometimes it does not
    end
  end

  function modifier_boss_slime_split_passive:CreateClone(name, origin, owner)
    local clone = CreateUnitByName(name, origin, true, owner, owner, owner:GetTeamNumber())

    -- Clones should not split into more clones
    clone:RemoveAbility("boss_slime_split")

    -- Assign constants
    clone.BossTier = owner.BossTier or 2
    clone.Spawner = owner

    -- Add the same items as the owner
    for i = DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_6 do
      local item = owner:GetItemInSlot(i)
      if item then
        clone:AddItemByName(item:GetName())
      end
    end

    -- Start tracking clone death, when a clone dies, kill the owner
    clone:AddNewModifier(clone, nil, "modifier_boss_slime_dead_tracker", {})
  end
end

---------------------------------------------------------------------------------------------------

modifier_boss_slime_invulnerable_oaa = class(ModifierBaseClass)

function modifier_boss_slime_invulnerable_oaa:IsHidden()
  return true
end

function modifier_boss_slime_invulnerable_oaa:IsDebuff()
  return false
end

function modifier_boss_slime_invulnerable_oaa:IsPurgable()
  return false
end

function modifier_boss_slime_invulnerable_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
    MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
    MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
  }
end

function modifier_boss_slime_invulnerable_oaa:GetAbsoluteNoDamageMagical()
  return 1
end

function modifier_boss_slime_invulnerable_oaa:GetAbsoluteNoDamagePhysical()
  return 1
end

function modifier_boss_slime_invulnerable_oaa:GetAbsoluteNoDamagePure()
  return 1
end

function modifier_boss_slime_invulnerable_oaa:CheckState()
  return {
    [MODIFIER_STATE_ATTACK_IMMUNE] = true,
    [MODIFIER_STATE_INVULNERABLE] = true,
    [MODIFIER_STATE_MAGIC_IMMUNE] = true,
    [MODIFIER_STATE_NOT_ON_MINIMAP] = true,
    [MODIFIER_STATE_NOT_ON_MINIMAP_FOR_ENEMIES] = true,
    [MODIFIER_STATE_NO_HEALTH_BAR] = true,
    [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
    [MODIFIER_STATE_UNSELECTABLE] = true,
  }
end

---------------------------------------------------------------------------------------------------

modifier_boss_slime_dead_tracker = class(ModifierBaseClass)

function modifier_boss_slime_dead_tracker:IsHidden()
  return true
end

function modifier_boss_slime_dead_tracker:IsDebuff()
  return false
end

function modifier_boss_slime_dead_tracker:IsPurgable()
  return false
end

function modifier_boss_slime_dead_tracker:RemoveOnDeath()
  return false
end

function modifier_boss_slime_dead_tracker:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_DEATH, -- OnDeath
  }
end

if IsServer() then
  function modifier_boss_slime_dead_tracker:OnDeath(event)
    local parent = self:GetParent()
    local dead = event.unit

    -- Check if dead unit has this modifier
    if dead ~= parent then
      return
    end

    local spawner = parent.Spawner

    -- Check if spawner exists
    if not spawner or spawner:IsNull() then
      self:Destroy()
      return
    end

    -- Check if spawner is dead
    if not spawner:IsAlive() then
      self:Destroy()
      return
    end

    local killer = event.attacker
    local killer_team = killer:GetTeamNumber()

    -- Remove invulnerability so we can kill it
    if spawner:HasAbility("boss_out_of_game") then
      spawner:RemoveAbility("boss_out_of_game")
    end

    if killer_team == DOTA_TEAM_NEUTRALS then
      spawner:ForceKillOAA(false)
    else
      spawner:Kill(event.inflictor, killer) -- this will crash if the killer is on the neutral team
    end

    self:Destroy()
  end
end
