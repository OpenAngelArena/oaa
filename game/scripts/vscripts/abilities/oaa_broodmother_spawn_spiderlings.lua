LinkLuaModifier("modifier_broodmother_spawn_spiderlings_oaa", "abilities/oaa_broodmother_spawn_spiderlings.lua", LUA_MODIFIER_MOTION_NONE)

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

  if not self.spider_counter_oaa then
    self.spider_counter_oaa = 0
  end
end

function modifier_broodmother_spawn_spiderlings_oaa:OnRefresh()
  self:OnCreated()
end

function modifier_broodmother_spawn_spiderlings_oaa:DeclareFunctions()
  local funcs = {
    MODIFIER_EVENT_ON_DEATH,
  }
  return funcs
end

function modifier_broodmother_spawn_spiderlings_oaa:OnDeath(event)
  if not IsServer() then
    return
  end

  local killer = event.attacker
  local dead = event.unit

  if killer ~= self:GetParent() then
    return
  end

  if not killer or killer:IsNull() or killer:IsIllusion() then
    return
  end

  local ability = self:GetAbility()
  if not ability or ability:IsNull() then
    return
  end

  -- Check for existence of GetUnitName method to determine if dead unit isn't something weird (an item, rune etc.)
  if dead.GetUnitName == nil then
    return
  end

  -- KV variables
  local base_hp = ability:GetSpecialValueFor("spiderling_base_hp")
  local hp_per_level = ability:GetSpecialValueFor("spiderling_hp_per_level")
  local base_armor = ability:GetSpecialValueFor("spiderling_base_armor")
  local armor_per_level = ability:GetSpecialValueFor("spiderling_armor_per_level")
  local base_speed = ability:GetSpecialValueFor("spiderling_speed")
  local base_damage = ability:GetSpecialValueFor("spiderling_base_attack_damage")
  local damage_per_level = ability:GetSpecialValueFor("spiderling_attack_damage_per_level")
  local summon_duration = ability:GetSpecialValueFor("spiderling_duration")
  local summon_count = ability:GetSpecialValueFor("spiderling_spawn_count")
  local max_count = ability:GetSpecialValueFor("spiderling_max_count")

  -- Don't continue if we already reached the max amount of spiders
  if self.spider_counter_oaa >= max_count then
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
  local hp_talent = killer:FindAbilityByName("special_bonus_unique_broodmother_2")
  local dmg_talent = killer:FindAbilityByName("special_bonus_unique_broodmother_4")

  if hp_talent and hp_talent:GetLevel() > 0 then
    base_hp = base_hp + hp_talent:GetSpecialValueFor("value")
  end

  if dmg_talent and dmg_talent:GetLevel() > 0 then
    base_damage = base_damage + dmg_talent:GetSpecialValueFor("value")
  end

  local level = killer:GetLevel()
  local playerID = killer:GetPlayerID()

  -- Calculate stats
  local summon_hp = base_hp + level * hp_per_level
  local summon_armor = base_armor + level * armor_per_level
  local summon_damage = base_damage + level * damage_per_level

  for i = 1, summon_count do
    local summon = self:SpawnUnit(unit_name, killer, playerID, summon_position, false)

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

    -- Movement speed
    summon:SetBaseMoveSpeed(base_speed)

    -- Increment the counter
    self.spider_counter_oaa = self.spider_counter_oaa + 1

    -- Break the for loop if we reached the maximum
    if self.spider_counter_oaa >= max_count then
      break
    end
  end

  -- Spawn sound
  killer:EmitSound("Hero_Broodmother.SpawnSpiderlings")
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
