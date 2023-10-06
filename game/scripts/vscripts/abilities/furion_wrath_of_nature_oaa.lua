furion_wrath_of_nature_oaa = class(AbilityBaseClass)

LinkLuaModifier("modifier_furion_wrath_of_nature_thinker_oaa", "abilities/furion_wrath_of_nature_oaa.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_furion_wrath_of_nature_scepter_debuff", "abilities/furion_wrath_of_nature_oaa.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_furion_wrath_of_nature_hit_debuff", "abilities/furion_wrath_of_nature_oaa.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_furion_wrath_of_nature_kill_damage_counter", "abilities/furion_wrath_of_nature_oaa.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_furion_wrath_of_nature_kill_damage_buff", "abilities/furion_wrath_of_nature_oaa.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_furion_wrath_of_nature_scepter_root_oaa", "abilities/furion_wrath_of_nature_oaa.lua", LUA_MODIFIER_MOTION_NONE)

function furion_wrath_of_nature_oaa:OnAbilityPhaseStart()
  local caster = self:GetCaster()
  local nFXIndex = ParticleManager:CreateParticle("particles/units/heroes/hero_furion/furion_wrath_of_nature_cast.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
  ParticleManager:SetParticleControlEnt(nFXIndex, 1, caster, PATTACH_POINT_FOLLOW, "attach_attack1", caster:GetOrigin(), false)
  ParticleManager:ReleaseParticleIndex(nFXIndex)

  return true
end

function furion_wrath_of_nature_oaa:OnSpellStart()
  local target = self:GetCursorTarget()
  local cursor_position = self:GetCursorPosition()
  local caster = self:GetCaster()

  if target then
    -- If target doesn't have Spell Block and not spell-immune then
    if not target:TriggerSpellAbsorb(self) and not target:IsMagicImmune() then
      CreateModifierThinker(caster, self, "modifier_furion_wrath_of_nature_thinker_oaa", {}, target:GetAbsOrigin(), caster:GetTeamNumber(), false)
    end
  elseif cursor_position then
    CreateModifierThinker(caster, self, "modifier_furion_wrath_of_nature_thinker_oaa", {}, cursor_position, caster:GetTeamNumber(), false)
  else
    return
  end

  -- Emit Sound no matter what
  caster:EmitSound("Hero_Furion.WrathOfNature_Cast")
end

function furion_wrath_of_nature_oaa:GetAssociatedSecondaryAbilities()
  return "furion_force_of_nature_oaa"
end

---------------------------------------------------------------------------------------------------

modifier_furion_wrath_of_nature_thinker_oaa = class(ModifierBaseClass)

function modifier_furion_wrath_of_nature_thinker_oaa:IsHidden()
  return true
end

function modifier_furion_wrath_of_nature_thinker_oaa:IsDebuff()
  return false
end

function modifier_furion_wrath_of_nature_thinker_oaa:IsPurgable()
  return false
end

function modifier_furion_wrath_of_nature_thinker_oaa:OnCreated()
  local ability = self:GetAbility()
  if not ability then
    return
  end
  self.damage = ability:GetSpecialValueFor("damage")
  self.max_targets = ability:GetSpecialValueFor("max_targets")
  self.damage_percent_add = ability:GetSpecialValueFor("damage_percent_add")
  self.jump_delay = ability:GetSpecialValueFor("jump_delay")
  self.damage_scepter = ability:GetSpecialValueFor("damage_scepter")
  self.scepter_debuff_duration = ability:GetSpecialValueFor("scepter_buffer")
  self.min_duration = ability:GetSpecialValueFor("scepter_min_root_duration")
  self.max_duration = ability:GetSpecialValueFor("scepter_max_root_duration")

  if IsServer() then
    -- Create a table for storing already hit units
    self.targets_hit = {}
    local target = ability:GetCursorTarget()

    if not target then
      local vPos = self:GetParent():GetAbsOrigin()
      local nFXIndexStart = ParticleManager:CreateParticle("particles/units/heroes/hero_furion/furion_wrath_of_nature_start.vpcf", PATTACH_CUSTOMORIGIN, nil)
      ParticleManager:SetParticleControl(nFXIndexStart, 0, vPos)
      ParticleManager:ReleaseParticleIndex(nFXIndexStart)

      -- Find new target
      target = self:GetNextTarget()
      if not target then
        --print("Wrath of Nature thinker couldn't find a target right at the start, destroying!")
        self:Destroy()
        return
      end
    end

    -- This is important for bounce particle for some reason
    self.target = target
    -- Bounce Particle
    self:CreateBounceFX(target)
    -- Damage and scepter effect
    self:HitTarget(target)

    -- Start thinking every jump_delay seconds (thinking includes searching for new target)
    self:StartIntervalThink(self.jump_delay)
  end
end

local function TableCountNonNil(t)
  local count = 0
  for _, v in pairs(t) do
    if v ~= nil then
      count = count + 1
    end
  end
  return count
end

if IsServer() then
  function modifier_furion_wrath_of_nature_thinker_oaa:OnIntervalThink()
    local parent = self:GetParent()
    if not parent or parent:IsNull() or not parent:IsAlive() then
      --print("Wrath of Nature thinker doesn't exist, stop thinking!")
      self:StartIntervalThink(-1)
      return
    end

    local new_target = self:GetNextTarget()
    if not new_target then
      --print("Wrath of Nature thinker couldn't find new target, stop thinking and destroy!")
      self:StartIntervalThink(-1)
      self:Destroy()
      return
    end

    -- Bounce Particle
    self:CreateBounceFX(new_target)
    -- Move the thinker to the new target for easier searching
    parent:SetAbsOrigin(new_target:GetAbsOrigin())
    -- Damage and scepter effect
    self:HitTarget(new_target)

    if TableCountNonNil(self.targets_hit) >= self.max_targets then
      --print("Wrath of Nature thinker reached max number of targets, stop thinking!")
      self:StartIntervalThink(-1)
      -- OAA special - Hit heroes every time for min damage (and min root duration with scepter)
      -- if they were not hit already with bounces
      self:HitUnhitHeroes()
    end
  end

  function modifier_furion_wrath_of_nature_thinker_oaa:OnDestroy()
    local parent = self:GetParent()

    -- Kill the thinker entity if it exists
    if parent and not parent:IsNull() then
      parent:ForceKillOAA(false)
    end
  end
end

function modifier_furion_wrath_of_nature_thinker_oaa:GetNextTarget()
  local caster = self:GetCaster()
  local parent = self:GetParent()
  local enemies = FindUnitsInRadius(
    caster:GetTeamNumber(),
    parent:GetAbsOrigin(),
    nil,
    FIND_UNITS_EVERYWHERE,
    DOTA_UNIT_TARGET_TEAM_ENEMY,
    bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC),
    DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE,
    FIND_CLOSEST,
    false
  )

  local nearest_enemy
  for _, enemy in ipairs(enemies) do
    if not enemy:IsCourier() and caster:CanEntityBeSeenByMyTeam(enemy) and self.targets_hit[tostring(enemy:GetEntityIndex())] ~= 1 then
      nearest_enemy = enemy
      break
    end
  end

  return nearest_enemy
end

function modifier_furion_wrath_of_nature_thinker_oaa:HitTarget(hTarget)
  if not hTarget then
    return
  end

  local caster = self:GetCaster()
  local ability = self:GetAbility() or caster:FindAbilityByName("furion_wrath_of_nature_oaa")
  local bHasScepter = caster:HasScepter()

  -- Apply a scepter debuff before applying damage
  if bHasScepter and hTarget:IsRealHero() then
    local force_of_nature_ability = caster:FindAbilityByName("furion_force_of_nature_oaa")
    if force_of_nature_ability and force_of_nature_ability:GetLevel() > 0 then
      hTarget:AddNewModifier(caster, force_of_nature_ability, "modifier_furion_wrath_of_nature_scepter_debuff", {duration = self.scepter_debuff_duration})
    end
  end

  -- Apply a modifier to the unit that will trigger on unit death and give dmg to the caster
  hTarget:AddNewModifier(caster, ability, "modifier_furion_wrath_of_nature_hit_debuff", {duration = 0.3})

  -- Calculate damage
  local nTargetsHit = TableCountNonNil(self.targets_hit)
  local flDamagePct = math.pow(1.0+(self.damage_percent_add/100.0), nTargetsHit)
  local flDamage = self.damage
  if bHasScepter then
    flDamage = self.damage_scepter
  end

  flDamage = flDamage*flDamagePct

  local damage_table = {
    victim = hTarget,
    attacker = caster,
    damage = flDamage,
    damage_type = DAMAGE_TYPE_MAGICAL,
    ability = ability
  }

  -- Scepter root effect
  if bHasScepter then
    local min_duration = self.min_duration or 1.6
    local max_duration = self.max_duration or 3.4
    local number_of_bounces = self.max_targets or 18
    local increase_per_bounce = (max_duration - min_duration) / number_of_bounces
    local root_duration = math.min(min_duration + increase_per_bounce * nTargetsHit, max_duration)
    local actual_duration = hTarget:GetValueChangedByStatusResistance(root_duration)
    --print("[WRATH OF NATURE OAA] Root duration is: "..actual_duration)

    -- Apply root
    hTarget:AddNewModifier(caster, ability, "modifier_furion_wrath_of_nature_scepter_root_oaa", {duration = actual_duration})
  end

  -- Sounds
  if hTarget:IsHero() then
    hTarget:EmitSound("Hero_Furion.WrathOfNature_Damage")
  else
    hTarget:EmitSound("Hero_Furion.WrathOfNature_Damage.Creep")
  end

  -- Add hTarget to the already hit table
  self.targets_hit[tostring(hTarget:GetEntityIndex())] = 1

  -- Apply damage
  ApplyDamage(damage_table)
end

function modifier_furion_wrath_of_nature_thinker_oaa:CreateBounceFX(hTarget)
  --FX
  local vTarget1 = self:GetParent():GetOrigin()

  local vTarget2 = hTarget:GetOrigin() - vTarget1
  local flDistance = math.min( vTarget2:Length() / 2, 256.0 )
  vTarget2 = vTarget2:Normalized() * flDistance

  local vTarget3 = vTarget1 - hTarget:GetOrigin()
  vTarget3 = vTarget3:Normalized() * flDistance

  vTarget2 = vTarget2 + vTarget1
  vTarget3 = vTarget3 + hTarget:GetOrigin()

  local vTarget4 = hTarget:GetOrigin()

  vTarget2.z = vTarget2.z + math.max( flDistance, 128 )
  vTarget3.z = vTarget3.z + math.max( flDistance, 128 )
  vTarget4.z = vTarget4.z + 100

  local nFXIndexHit = ParticleManager:CreateParticle( "particles/units/heroes/hero_furion/furion_wrath_of_nature.vpcf", PATTACH_CUSTOMORIGIN, nil )
  ParticleManager:SetParticleControl( nFXIndexHit, 0, vTarget1 )
  ParticleManager:SetParticleControl( nFXIndexHit, 1, vTarget2 )
  ParticleManager:SetParticleControl( nFXIndexHit, 2, vTarget3 )
  ParticleManager:SetParticleControl( nFXIndexHit, 3, vTarget4 )
  ParticleManager:SetParticleControlOrientation( nFXIndexHit, 0, Vector( 0, 0, 1), Vector( 0, 1, 0), Vector( 1, 0, 0 ) )
  ParticleManager:SetParticleControlOrientation( nFXIndexHit, 1, Vector( 0, 0, 1), Vector( 0, 1, 0), Vector( 1, 0, 0 ) )
  ParticleManager:SetParticleControlOrientation( nFXIndexHit, 2, Vector( 0, 0, 1), Vector( 0, 1, 0), Vector( 1, 0, 0 ) )
  ParticleManager:SetParticleControlEnt( nFXIndexHit, 4, self.target, PATTACH_ABSORIGIN_FOLLOW, nil, self:GetCaster():GetOrigin(), false )
  ParticleManager:ReleaseParticleIndex( nFXIndexHit )
end

-- OAA special Hit heroes every time for min damage (and min root duration with scepter)
-- if they were not hit already with bounces
function modifier_furion_wrath_of_nature_thinker_oaa:HitUnhitHeroes()
  local caster = self:GetCaster()
  local enemy_heroes = FindUnitsInRadius(
    caster:GetTeamNumber(),
    Vector(0, 0, 0),
    nil,
    FIND_UNITS_EVERYWHERE,
    DOTA_UNIT_TARGET_TEAM_ENEMY,
    DOTA_UNIT_TARGET_HERO,
    DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE,
    FIND_ANY_ORDER,
    false
  )

  local ability = self:GetAbility() or caster:FindAbilityByName("furion_wrath_of_nature_oaa")
  local force_of_nature_ability = caster:FindAbilityByName("furion_force_of_nature_oaa")
  local bHasScepter = caster:HasScepter()

  local damage_table = {
    attacker = caster,
    damage = self.damage,
    damage_type = DAMAGE_TYPE_MAGICAL,
    ability = ability
  }

  if bHasScepter then
    damage_table.damage = self.damage_scepter
  end

  for _, enemy in pairs(enemy_heroes) do
    -- Check if the enemy hero exists, if it is visible and not already hit
    if enemy and not enemy:IsNull() and caster:CanEntityBeSeenByMyTeam(enemy) and self.targets_hit[tostring(enemy:GetEntityIndex())] ~= 1 and not enemy:IsOAABoss() then
      -- Apply a scepter debuffs before applying damage
      if bHasScepter then
        if force_of_nature_ability and force_of_nature_ability:GetLevel() > 0 then
          enemy:AddNewModifier(caster, force_of_nature_ability, "modifier_furion_wrath_of_nature_scepter_debuff", {duration = self.scepter_debuff_duration})
        end
        local actual_root_duration = enemy:GetValueChangedByStatusResistance(self.min_duration)
        -- Apply root
        enemy:AddNewModifier(caster, ability, "modifier_furion_wrath_of_nature_scepter_root_oaa", {duration = actual_root_duration})
      end

      -- Apply a modifier that will trigger on death and give dmg to the caster
      enemy:AddNewModifier(caster, ability, "modifier_furion_wrath_of_nature_hit_debuff", {duration = 0.3})

      -- Sound
      enemy:EmitSound("Hero_Furion.WrathOfNature_Damage")

      -- Add enemy to the already hit table (not needed but just in case)
      self.targets_hit[tostring(enemy:GetEntityIndex())] = 1

      -- Apply damage
      damage_table.victim = enemy
      ApplyDamage(damage_table)
    end
  end

  self:Destroy()
end

---------------------------------------------------------------------------------------------------

modifier_furion_wrath_of_nature_scepter_debuff = class(ModifierBaseClass)

function modifier_furion_wrath_of_nature_scepter_debuff:IsHidden()
  return true
end

function modifier_furion_wrath_of_nature_scepter_debuff:IsDebuff()
  return true
end

function modifier_furion_wrath_of_nature_scepter_debuff:IsPurgable()
  return false
end

function modifier_furion_wrath_of_nature_scepter_debuff:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_DEATH,
  }
end

if IsServer() then
  function modifier_furion_wrath_of_nature_scepter_debuff:OnDeath(event)
    local parent = self:GetParent()
    if event.unit == parent then
      local caster = self:GetCaster()
      if not caster then
        return
      end
      local force_of_nature_ability = caster:FindAbilityByName("furion_force_of_nature_oaa")

      -- Rubick stole Wrath of Nature but he doesn't have Force of Nature for some reason
      if not force_of_nature_ability then
        return
      end

      -- Rubick stole something else while debuff still existed
      if force_of_nature_ability:IsNull() then
        return
      end
      local level = force_of_nature_ability:GetLevel()

      -- Treant stats
      local treant_hp = force_of_nature_ability:GetLevelSpecialValueFor("treant_health", level-1)
      local treant_armor = force_of_nature_ability:GetLevelSpecialValueFor("treant_armor", level-1)
      local treant_dmg = force_of_nature_ability:GetLevelSpecialValueFor("treant_damage", level-1)
      local treant_speed = force_of_nature_ability:GetLevelSpecialValueFor("treant_move_speed", level-1)
      local treant_duration = force_of_nature_ability:GetSpecialValueFor("duration")

      local treantName = "npc_dota_furion_treant_" .. level
      if parent:IsRealHero() then
        treantName = "npc_dota_furion_treant_large_" .. level
        treant_hp = force_of_nature_ability:GetLevelSpecialValueFor("treant_large_health", level-1)
        treant_dmg = force_of_nature_ability:GetLevelSpecialValueFor("treant_large_damage", level-1)
      end

      -- Talent that increases health and damage of treants with a multiplier
      local talent1 = caster:FindAbilityByName("special_bonus_unique_furion_1_oaa")
      if talent1 and talent1:GetLevel() > 0 then
        treant_hp = treant_hp * talent1:GetSpecialValueFor("value")
        treant_dmg = treant_dmg * talent1:GetSpecialValueFor("value")
      end

      local treant = CreateUnitByName(treantName, parent:GetAbsOrigin(), true, caster, caster:GetOwner(), caster:GetTeamNumber())
      if treant then
        treant:SetControllableByPlayer(caster:GetPlayerID(), false)
        treant:SetOwner(caster)
        treant:AddNewModifier(caster, force_of_nature_ability, "modifier_kill", {duration = treant_duration})
        treant:AddNewModifier(caster, force_of_nature_ability, "modifier_generic_dead_tracker_oaa", {duration = treant_duration + MANUAL_GARBAGE_CLEANING_TIME})

        -- Fix stats of treants
        -- HP
        treant:SetBaseMaxHealth(treant_hp)
        treant:SetMaxHealth(treant_hp)
        treant:SetHealth(treant_hp)

        -- DAMAGE
        treant:SetBaseDamageMin(treant_dmg)
        treant:SetBaseDamageMax(treant_dmg)

        -- ARMOR
        treant:SetPhysicalArmorBaseValue(treant_armor)

        -- Movement speed
        treant:SetBaseMoveSpeed(treant_speed)

        EmitSoundOnLocationWithCaster(parent:GetAbsOrigin(), "Hero_Furion.ForceOfNature", caster)
      end
    end
  end
end

---------------------------------------------------------------------------------------------------

modifier_furion_wrath_of_nature_hit_debuff = class(ModifierBaseClass)

function modifier_furion_wrath_of_nature_hit_debuff:IsHidden()
  return true
end

function modifier_furion_wrath_of_nature_hit_debuff:IsDebuff()
  return true
end

function modifier_furion_wrath_of_nature_hit_debuff:IsPurgable()
  return false
end

function modifier_furion_wrath_of_nature_hit_debuff:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_DEATH,
  }
end

if IsServer() then
  function modifier_furion_wrath_of_nature_hit_debuff:OnDeath(event)
    local parent = self:GetParent()
    if event.unit == parent then
      local caster = self:GetCaster()
      if not caster then
        return
      end
      local ability = self:GetAbility() or caster:FindAbilityByName("furion_wrath_of_nature_oaa")
      if not ability or ability:IsNull() then
        return
      end

      local kill_damage_duration = ability:GetSpecialValueFor("kill_damage_duration")
      if kill_damage_duration ~= 0 then
        caster:AddNewModifier(caster, ability, "modifier_furion_wrath_of_nature_kill_damage_counter", {duration = kill_damage_duration})
        caster:AddNewModifier(caster, ability, "modifier_furion_wrath_of_nature_kill_damage_buff", {duration = kill_damage_duration})
      end
    end
  end
end

---------------------------------------------------------------------------------------------------

modifier_furion_wrath_of_nature_kill_damage_counter = class(ModifierBaseClass)

function modifier_furion_wrath_of_nature_kill_damage_counter:IsHidden() -- needs tooltip
  return false
end

function modifier_furion_wrath_of_nature_kill_damage_counter:IsDebuff()
  return false
end

function modifier_furion_wrath_of_nature_kill_damage_counter:IsPurgable()
  return false
end

function modifier_furion_wrath_of_nature_kill_damage_counter:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_TOOLTIP
  }
end

function modifier_furion_wrath_of_nature_kill_damage_counter:OnTooltip()
  local dmg_increase = self:GetAbility():GetSpecialValueFor("kill_damage")
  return dmg_increase * self:GetStackCount()
end

---------------------------------------------------------------------------------------------------

modifier_furion_wrath_of_nature_kill_damage_buff = class(ModifierBaseClass)

function modifier_furion_wrath_of_nature_kill_damage_buff:IsPurgable()
  return false
end

function modifier_furion_wrath_of_nature_kill_damage_buff:IsHidden()
  return true
end

function modifier_furion_wrath_of_nature_kill_damage_buff:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_furion_wrath_of_nature_kill_damage_buff:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
  }
end

function modifier_furion_wrath_of_nature_kill_damage_buff:OnCreated()
  if IsServer() then
    local counterMod = self:GetParent():FindModifierByName("modifier_furion_wrath_of_nature_kill_damage_counter")
    if counterMod and not counterMod:IsNull() then
      counterMod:SetStackCount(counterMod:GetStackCount() + 1)
    end
  end
end

if IsServer() then
  function modifier_furion_wrath_of_nature_kill_damage_buff:OnDestroy()
    local counterMod = self:GetParent():FindModifierByName("modifier_furion_wrath_of_nature_kill_damage_counter")
    if counterMod and not counterMod:IsNull() then
      counterMod:SetStackCount(counterMod:GetStackCount() - 1)
    end
  end
end

function modifier_furion_wrath_of_nature_kill_damage_buff:GetModifierPreAttack_BonusDamage()
  return self:GetAbility():GetSpecialValueFor("kill_damage")
end

---------------------------------------------------------------------------------------------------

modifier_furion_wrath_of_nature_scepter_root_oaa = class(ModifierBaseClass)

function modifier_furion_wrath_of_nature_scepter_root_oaa:IsHidden() -- needs tooltip
  return false
end

function modifier_furion_wrath_of_nature_scepter_root_oaa:IsDebuff()
  return true
end

function modifier_furion_wrath_of_nature_scepter_root_oaa:IsPurgable()
  return true
end

function modifier_furion_wrath_of_nature_scepter_root_oaa:OnCreated()
  if not IsServer() then
    return
  end

  self:GetParent():EmitSound("Hero_Treant.Overgrowth.Target")
end

function modifier_furion_wrath_of_nature_scepter_root_oaa:CheckState()
  return {
    [MODIFIER_STATE_ROOTED] = true,
  }
end

function modifier_furion_wrath_of_nature_scepter_root_oaa:GetEffectName()
  return "particles/units/heroes/hero_treant/treant_overgrowth_vines_mid.vpcf"
end

function modifier_furion_wrath_of_nature_scepter_root_oaa:GetEffectAttachType()
  return PATTACH_ABSORIGIN_FOLLOW
end
