LinkLuaModifier("modifier_broodmother_spawn_spiderlings_oaa", "abilities/oaa_broodmother_spawn_spiderlings.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_broodmother_giant_spiderling_passive", "abilities/oaa_broodmother_spawn_spiderlings.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_spider_dead_tracker_oaa", "abilities/oaa_broodmother_spawn_spiderlings.lua", LUA_MODIFIER_MOTION_NONE)

broodmother_spawn_spiderlings_oaa = class(AbilityBaseClass)

function broodmother_spawn_spiderlings_oaa:Spawn()
  if IsServer() then
    self:SetLevel(1)
  end
end

function broodmother_spawn_spiderlings_oaa:GetIntrinsicModifierName()
  return "modifier_broodmother_spawn_spiderlings_oaa"
end

function broodmother_spawn_spiderlings_oaa:IsStealable()
  return false
end

function broodmother_spawn_spiderlings_oaa:ProcMagicStick()
  return false
end

---------------------------------------------------------------------------------------------------

modifier_broodmother_spawn_spiderlings_oaa = class(ModifierBaseClass)

function modifier_broodmother_spawn_spiderlings_oaa:IsHidden()
  return true
end

function modifier_broodmother_spawn_spiderlings_oaa:IsPurgable()
  return false
end

function modifier_broodmother_spawn_spiderlings_oaa:RemoveOnDeath()
  return false
end

function modifier_broodmother_spawn_spiderlings_oaa:OnCreated()
  local parent = self:GetParent()

  if parent:IsIllusion() then
    return
  end

  if not parent.spider_counter_oaa then
    parent.spider_counter_oaa = 0
  end
end

function modifier_broodmother_spawn_spiderlings_oaa:OnRefresh()
  self:OnCreated()
end

function modifier_broodmother_spawn_spiderlings_oaa:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_DEATH,
  }
end

if IsServer() then
  function modifier_broodmother_spawn_spiderlings_oaa:OnDeath(event)
    local parent = self:GetParent()
    local killer = event.attacker
    local dead = event.unit

    if parent:IsIllusion() then
      return
    end

    -- Check for existence of GetUnitName method to determine if dead unit isn't something weird (an item, rune etc.)
    if dead.GetUnitName == nil then
      return
    end

    -- Decrement spider counter when a spider (belonging to parent) dies
    if UnitVarToPlayerID(dead) == UnitVarToPlayerID(parent) and (dead:GetUnitName() == "npc_dota_broodmother_spiderling" or dead:GetUnitName() == "npc_dota_broodmother_giant_spiderling") then
      if parent.spider_counter_oaa > 0 then
        parent.spider_counter_oaa = parent.spider_counter_oaa - 1
      end
    end

    -- modifier_kill makes the spiders kill themselves when it expires (dead = killer)
    -- Don't create more spiders if spiders expire or if the dead unit is the parent (broodmother suicided somehow)
    if dead == killer or dead == parent then
      return
    end

    -- Don't continue if the killer doesn't exist
    if not killer or killer:IsNull() then
      return
    end

    -- Don't continue if the killer doesn't belong to the parent
    if UnitVarToPlayerID(killer) ~= UnitVarToPlayerID(parent) then
      return
    end

    -- Don't continue if the ability doesn't exist
    local ability = self:GetAbility()
    if not ability or ability:IsNull() then
      return
    end

    -- KV variables
    local base_hp = ability:GetSpecialValueFor("spiderling_base_hp")
    local hp_per_level = ability:GetSpecialValueFor("spiderling_hp_per_level")
    local base_armor = ability:GetSpecialValueFor("spiderling_base_armor")
    local armor_per_level = ability:GetSpecialValueFor("spiderling_armor_per_level")
    local magic_resist_per_level = ability:GetSpecialValueFor("spiderling_magic_resist_per_level")
    local base_speed = ability:GetSpecialValueFor("spiderling_speed")
    local base_damage = ability:GetSpecialValueFor("spiderling_base_attack_damage")
    local damage_per_level = ability:GetSpecialValueFor("spiderling_attack_damage_per_level")
    local summon_duration = ability:GetSpecialValueFor("spiderling_duration")
    local summon_count = ability:GetSpecialValueFor("spiderling_spawn_count")
    local max_count = ability:GetSpecialValueFor("spiderling_max_count")
    local spawn_radius = ability:GetSpecialValueFor("spiderling_spawn_radius")

    if HeroSelection.is10v10 then
      max_count = 7
    end

    -- Spiderlings can spawn spiderlings only if near Broodmother, otherwise don't continue
    if killer ~= parent and (killer:GetAbsOrigin() - parent:GetAbsOrigin()):Length2D() > spawn_radius then
      return
    end

    -- Don't continue if we already reached the max amount of spiders
    if parent.spider_counter_oaa >= max_count then
      return
    end

    local unit_name = "npc_dota_broodmother_spiderling"
    local spawn_giant_spiders = false

    -- Check if dead unit is a hero or a boss
    if dead:IsRealHero() or dead:IsOAABoss() then
      spawn_giant_spiders = true
    end

    local summon_position = dead:GetAbsOrigin() or killer:GetAbsOrigin()

    -- Spawn Particle
    local pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_broodmother/broodmother_spiderlings_spawn.vpcf", PATTACH_ABSORIGIN, dead)
    ParticleManager:SetParticleControl(pfx, 0, summon_position)
    ParticleManager:ReleaseParticleIndex(pfx)

    if spawn_giant_spiders == true then
      base_hp = ability:GetSpecialValueFor("giant_spiderling_base_hp")
      base_damage = ability:GetSpecialValueFor("giant_spiderling_base_attack_damage")
      summon_count = ability:GetSpecialValueFor("giant_spiderling_spawn_count")
      unit_name = "npc_dota_broodmother_giant_spiderling"
    end

    -- Talents for spider stats
    local hp_talent = parent:FindAbilityByName("special_bonus_unique_broodmother_2_oaa")
    local dmg_talent = parent:FindAbilityByName("special_bonus_unique_broodmother_4_oaa")

    if hp_talent and hp_talent:GetLevel() > 0 then
      --base_hp = base_hp + hp_talent:GetSpecialValueFor("value")
      hp_per_level = hp_per_level + hp_talent:GetSpecialValueFor("value")
    end

    if dmg_talent and dmg_talent:GetLevel() > 0 then
      --base_damage = base_damage + dmg_talent:GetSpecialValueFor("value")
      damage_per_level = damage_per_level + dmg_talent:GetSpecialValueFor("value")
    end

    local level = parent:GetLevel()
    local playerID = parent:GetPlayerID()

    -- Calculate stats
    local summon_hp = base_hp + (level - 1) * hp_per_level
    local summon_armor = base_armor + (level - 1) * armor_per_level
    local summon_magic_resist = 20 + (level - 1) * magic_resist_per_level
    local summon_damage = math.ceil(base_damage + (level - 1) * damage_per_level)

    for i = 1, summon_count do
      local summon = self:SpawnUnit(unit_name, parent, playerID, summon_position, false)

      -- Level up spider abilities
      local spider_ability1 = summon:FindAbilityByName("broodmother_poison_sting")
      if spider_ability1 then
        spider_ability1:SetLevel(1)
      end
      local spider_ability2 = summon:FindAbilityByName("broodmother_spawn_spiderite")
      if spider_ability2 then
        spider_ability2:SetLevel(1)
      end

      if spawn_giant_spiders == true then
        -- Add modifier to giant spiders
        summon:AddNewModifier(parent, ability, "modifier_broodmother_giant_spiderling_passive", {})
      end

      -- Add duration to spiders
      summon:AddNewModifier(parent, ability, "modifier_kill", {duration = summon_duration})
      -- modifier_kill when killing the unit no longer triggers OnDeath event, thanks Valve
      summon:AddNewModifier(parent, ability, "modifier_spider_dead_tracker_oaa", {duration = summon_duration + MANUAL_GARBAGE_CLEANING_TIME})
      -- 6 is poison sting duration on creeps

      -- Fix stats of summons
      -- HP
      summon:SetBaseMaxHealth(summon_hp)
      summon:SetMaxHealth(summon_hp)
      summon:SetHealth(summon_hp)

      -- DAMAGE
      summon:SetBaseDamageMin(summon_damage)
      summon:SetBaseDamageMax(summon_damage)

      -- ARMOR
      summon:SetPhysicalArmorBaseValue(summon_armor)

      -- MAGIC RESIST
      summon:SetBaseMagicalResistanceValue(summon_magic_resist)

      -- Movement speed
      summon:SetBaseMoveSpeed(base_speed)

      -- Increment the counter
      parent.spider_counter_oaa = parent.spider_counter_oaa + 1

      -- Break the for loop if we reached the maximum
      if parent.spider_counter_oaa >= max_count then
        break
      end
    end

    -- Spawn sound
    killer:EmitSound("Hero_Broodmother.SpawnSpiderlings")
  end
end

function modifier_broodmother_spawn_spiderlings_oaa:SpawnUnit(unitName, caster, playerID, spawnPosition, bRandomPosition)
  local position = spawnPosition

  if bRandomPosition then
    position = position + RandomVector(1):Normalized() * RandomFloat(50, 100)
  end

  local npcCreep = CreateUnitByName(unitName, position, true, caster, caster:GetOwner(), caster:GetTeam())
  FindClearSpaceForUnit(npcCreep, position, true)
  npcCreep:SetControllableByPlayer(playerID, false)
  npcCreep:SetOwner(caster)
  npcCreep:SetForwardVector(caster:GetForwardVector())

  return npcCreep
end

---------------------------------------------------------------------------------------------------

modifier_broodmother_giant_spiderling_passive = class(ModifierBaseClass)

function modifier_broodmother_giant_spiderling_passive:IsHidden()
  return true
end

function modifier_broodmother_giant_spiderling_passive:IsDebuff()
  return false
end

function modifier_broodmother_giant_spiderling_passive:IsPurgable()
  return false
end

function modifier_broodmother_giant_spiderling_passive:OnCreated()
  self.bonus_ms = 18
  self.bonus_hp_regen = 3
  --self.hp_percent_low = 1
  --self.hp_percent_high = 100

  if not IsServer() then
    return
  end

  local caster = self:GetCaster()
  local ability = caster:FindAbilityByName("broodmother_spin_web")
  if ability and not ability:IsNull() then
    local ability_level = ability:GetLevel()
    if ability_level > 0 then
      self.bonus_ms = ability:GetLevelSpecialValueFor("bonus_movespeed", ability_level-1)
      --self.bonus_hp_regen = ability:GetLevelSpecialValueFor("heath_regen", ability_level-1)
    end
  end

  self:StartIntervalThink(0)
end

function modifier_broodmother_giant_spiderling_passive:OnRefresh()
  if not IsServer() then
    return
  end
  local caster = self:GetCaster()
  local ability = caster:FindAbilityByName("broodmother_spin_web")
  if not ability or ability:IsNull() then
    return
  end

  local ability_level = ability:GetLevel()
  if ability_level > 0 then
    self.bonus_ms = ability:GetLevelSpecialValueFor("bonus_movespeed", ability_level-1)
    --self.bonus_hp_regen = ability:GetLevelSpecialValueFor("heath_regen", ability_level-1)
  end
end


function modifier_broodmother_giant_spiderling_passive:OnIntervalThink()
  if not IsServer() then
    return
  end
  local caster = self:GetCaster()
  local ability = caster:FindAbilityByName("broodmother_spin_web")
  if not ability or ability:IsNull() or ability:GetLevel() <= 0 then
    return
  end

  local parent = self:GetParent()
  local web_radius = ability:GetSpecialValueFor("radius")
  local origin = parent:GetAbsOrigin()
  --local hp_percent = (parent:GetHealth() / parent:GetMaxHealth()) * 100

  --local multiplier = (hp_percent - self.hp_percent_low)/(self.hp_percent_high - self.hp_percent_low)
  local webs = Entities:FindAllByClassnameWithin("npc_dota_broodmother_web", origin, web_radius)
  local condition = (#webs > 0) --and (multiplier > 0)
  -- If parent is near a web, apply web buffs
  if condition then
    self:SetStackCount(1)
  else
    self:SetStackCount(2)
  end
end

function modifier_broodmother_giant_spiderling_passive:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    --MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
    --MODIFIER_PROPERTY_IGNORE_MOVESPEED_LIMIT,
  }
end

function modifier_broodmother_giant_spiderling_passive:GetModifierMoveSpeedBonus_Percentage()
  if self:GetStackCount() == 1 then
    --local multiplier = 1
    --if self.hp_percent_high and self.hp_percent_low and (self.hp_percent_high - self.hp_percent_low > 0) then
      --multiplier = math.min(((self:GetParent():GetHealthPercent() - self.hp_percent_low) / (self.hp_percent_high - self.hp_percent_low)) + 0.5, 1)
    --end
    return self.bonus_ms --* multiplier
  end

  return 0
end

-- function modifier_broodmother_giant_spiderling_passive:GetModifierConstantHealthRegen()
	-- if self:GetStackCount() == 1 then
    -- return self.bonus_hp_regen
  -- end

  -- return 0
-- end

-- function modifier_broodmother_giant_spiderling_passive:GetModifierIgnoreMovespeedLimit()
  -- if self:GetStackCount() == 1 then
    -- return 1
  -- end
-- end

function modifier_broodmother_giant_spiderling_passive:CheckState()
  if self:GetStackCount() == 1 then
    return {
      [MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
      [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
    }
  else
    return {}
  end
end

---------------------------------------------------------------------------------------------------

modifier_spider_dead_tracker_oaa = class({})

function modifier_spider_dead_tracker_oaa:IsHidden()
  return true
end

function modifier_spider_dead_tracker_oaa:IsPurgable()
  return false
end

function modifier_spider_dead_tracker_oaa:RemoveOnDeath()
  return false
end

function modifier_spider_dead_tracker_oaa:OnCreated()
  if not IsServer() then
    return
  end
  local caster = self:GetCaster()
  if not caster or caster:IsNull() then
    self:Destroy()
    return
  end
  if not caster.spider_counter_oaa then
    self:Destroy()
    return
  end
  self:StartIntervalThink(self:GetRemainingTime()-6)
end

function modifier_spider_dead_tracker_oaa:OnIntervalThink()
  if not IsServer() then
    return
  end
  local caster = self:GetCaster()
  if not caster or caster:IsNull() then
    self:StartIntervalThink(-1)
    self:Destroy()
    return
  end
  if not caster.spider_counter_oaa then
    self:StartIntervalThink(-1)
    self:Destroy()
    return
  end
end

function modifier_spider_dead_tracker_oaa:OnDestroy()
  if not IsServer() then
    return
  end
  local caster = self:GetCaster()
  if not caster or caster:IsNull() then
    return
  end
  if not caster.spider_counter_oaa then
    return
  end
  local parent = self:GetParent()
  if parent and not parent:IsNull() then
    parent:RemoveSelf()
    caster.spider_counter_oaa = caster.spider_counter_oaa - 1
  end
end
