witch_doctor_death_ward_oaa = class(AbilityBaseClass)

LinkLuaModifier("modifier_death_ward_oaa", "abilities/oaa_witch_doctor_death_ward.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_death_ward_hidden_oaa", "abilities/oaa_witch_doctor_death_ward.lua", LUA_MODIFIER_MOTION_NONE)

function witch_doctor_death_ward_oaa:IsStealable()
  return true
end

function witch_doctor_death_ward_oaa:IsHiddenWhenStolen()
  return false
end

function witch_doctor_death_ward_oaa:OnSpellStart()
  local unit_name = "npc_dota_witch_doctor_death_ward_oaa"
  local point = self:GetCursorPosition()

  if not point then
    return
  end

  local caster = self:GetCaster()

  -- Create Death Ward unit
  local death_ward = CreateUnitByName(unit_name, point, true, caster, caster, caster:GetTeamNumber())
  death_ward:SetOwner(caster)
  death_ward:SetControllableByPlayer(caster:GetPlayerOwnerID(), true)

  -- Sound
  death_ward:EmitSound("Hero_WitchDoctor.Death_WardBuild")

  -- Get Death Ward damage (needed if physical and not a spell damage)
  --local damage = self:GetSpecialValueFor("ward_damage")
  -- Check for bonus damage talent
  --local talent = caster:FindAbilityByName("special_bonus_unique_witch_doctor_5")
  --if talent and talent:GetLevel() > 0 then
    --damage = damage + talent:GetSpecialValueFor("value")
  --end
  -- Set Death Ward damage (needed if physical and not a spell damage)
  --death_ward:SetBaseDamageMax(damage)
  --death_ward:SetBaseDamageMin(damage)

  -- Apply modifiers to Death Ward
  death_ward:AddNewModifier(caster, self, "modifier_death_ward_oaa", {})
  death_ward:AddNewModifier(caster, self, "modifier_phased", {duration = 0.03}) -- unit will insta unstuck after this built-in modifier expires.

  -- Variable needed for later
  self.ward_unit = death_ward
end

function witch_doctor_death_ward_oaa:OnProjectileHit_ExtraData(target, location, data)
  --if not self.ward_unit or self.ward_unit:IsNull() then
    --return
  --end

  -- If target doesn't exist (disjointed), don't continue
  if not target or target:IsNull() then
    return
  end

  -- Get the owner of the Death Ward
  local owner = self:GetCaster() -- self.ward_unit:GetOwner()

  -- If owner doesn't exist, don't continue
  if not owner or owner:IsNull() then
    return
  end

  -- Source of the damage
  local damage_source = owner --self.ward_unit

  -- Damage of the projectile
  local damage = self:GetSpecialValueFor("ward_damage")
  -- Check for bonus damage talent
  local talent = owner:FindAbilityByName("special_bonus_unique_witch_doctor_5")
  if talent and talent:GetLevel() > 0 then
    damage = damage + talent:GetSpecialValueFor("value")
  end

  -- Damage table of the projectile
  local damage_table = {}
  damage_table.attacker = damage_source
  damage_table.damage = damage
  damage_table.damage_type = self:GetAbilityDamageType()
  damage_table.ability = self
  damage_table.victim = target
  damage_table.damage_flags = bit.bor(DOTA_DAMAGE_FLAG_REFLECTION, DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL)

  ApplyDamage(damage_table)

  -- If the owner of the Death Ward doesn't have Aghanim Scepter, don't continue
  if not owner:HasScepter() then
    return
  end

  local projectile_speed = 1000
  if self.ward_unit and not self.ward_unit:IsNull() then
    projectile_speed = self.ward_unit:GetProjectileSpeed()
  end
  
  -- Copy data table into new_data table
  local new_data = {}
  for k, v in pairs(data) do
    new_data[k] = v
  end

  -- Mark the target as hit
  new_data[tostring(target:GetEntityIndex())] = 1

  local bounce_radius = self:GetSpecialValueFor("scepter_bounce_radius")
  local targets_flags = bit.bor(DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, DOTA_UNIT_TARGET_FLAG_NOT_ATTACK_IMMUNE, DOTA_UNIT_TARGET_FLAG_NO_INVIS, DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE)
  -- Find nearest target and fire a projectile from it
  local enemies = FindUnitsInRadius(damage_source:GetTeamNumber(), target:GetAbsOrigin(), nil, bounce_radius, self:GetAbilityTargetTeam(), self:GetAbilityTargetType(), targets_flags, FIND_CLOSEST, false)
  for _, enemy in ipairs(enemies) do
    if enemy ~= target and new_data[tostring(enemy:GetEntityIndex())] ~= 1 then
      local projectile_info = {
        Target = enemy,
        Source = target,
        Ability = self,
        EffectName = "particles/units/heroes/hero_witchdoctor/witchdoctor_ward_attack.vpcf",
        bDodgable = true,
        bProvidesVision = false,
        bVisibleToEnemies = true,
        bReplaceExisting = false,
        iMoveSpeed = projectile_speed,
        bIsAttack = false,
        iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_HITLOCATION,
        ExtraData = new_data,
      }

      ProjectileManager:CreateTrackingProjectile(projectile_info)
      break
    end
  end
end

function witch_doctor_death_ward_oaa:OnUpgrade()
  local caster = self:GetCaster()
  local ability_level = self:GetLevel()
  local shard_ability = caster:FindAbilityByName("witch_doctor_voodoo_switcheroo_oaa")

  -- Check to not enter a level up loop
  if shard_ability and shard_ability:GetLevel() ~= ability_level then
    shard_ability:SetLevel(ability_level)
  end
end

--function witch_doctor_death_ward_oaa:GetCastAnimation()
  --return ACT_DOTA_CAST_ABILITY_4
--end

--function witch_doctor_death_ward_oaa:GetChannelAnimation()
	--return ACT_DOTA_VICTORY
--end

function witch_doctor_death_ward_oaa:OnChannelFinish(interrupted)
  if self.ward_unit and not self.ward_unit:IsNull() then
    self.ward_unit:StopSound("Hero_WitchDoctor.Death_WardBuild")
    self.ward_unit:AddNewModifier(self:GetCaster(), self, "modifier_death_ward_hidden_oaa", {duration = 3})
  end
end

function witch_doctor_death_ward_oaa:ProcsMagicStick()
  return true
end

---------------------------------------------------------------------------------------------------

modifier_death_ward_oaa = class(ModifierBaseClass)

function modifier_death_ward_oaa:IsDebuff()
  return false
end

function modifier_death_ward_oaa:IsHidden()
  return true
end

function modifier_death_ward_oaa:IsPurgable()
  return false
end

function modifier_death_ward_oaa:IsPurgeException()
  return false
end

function modifier_death_ward_oaa:IsStunDebuff()
  return false
end

function modifier_death_ward_oaa:RemoveOnDeath()
  return true
end

function modifier_death_ward_oaa:OnCreated()
  local parent = self:GetParent()
  self.ward_particle = ParticleManager:CreateParticle("particles/units/heroes/hero_witchdoctor/witchdoctor_ward_skull.vpcf", PATTACH_POINT_FOLLOW, parent)
  ParticleManager:SetParticleControlEnt(self.ward_particle, 0, parent, PATTACH_POINT_FOLLOW, "attach_attack1", parent:GetAbsOrigin(), true)
  ParticleManager:SetParticleControl(self.ward_particle, 2, parent:GetAbsOrigin())

  local owner = self:GetCaster()
  local attack_range_bonus = 0
  -- Check for bonus attack range talent
  local talent = owner:FindAbilityByName("special_bonus_unique_witch_doctor_1")
  if talent and talent:GetLevel() > 0 then
    attack_range_bonus = talent:GetSpecialValueFor("value")
  end

  self.attack_range_bonus = attack_range_bonus

  if IsServer() then
    -- Change Acquisition range if there is an attack range bonus
    parent:SetAcquisitionRange(parent:GetAcquisitionRange() + attack_range_bonus)
    -- Change Night Vision
    local night_vision = math.max(800, parent:GetAttackRange() + attack_range_bonus)
    parent:SetNightTimeVisionRange(night_vision)
	
    -- Start attacking AI (which targets are allowed to be attacked)
    self:StartIntervalThink(0)
  end
end

function modifier_death_ward_oaa:OnIntervalThink()
  if not IsServer() then
    return
  end
  local parent = self:GetParent()
  if parent:GetAggroTarget() and parent:GetAggroTarget():IsConsideredHero() then
    return
  end
  local ability = self:GetAbility()
  local targets_flags = bit.bor(DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, DOTA_UNIT_TARGET_FLAG_NOT_ATTACK_IMMUNE, DOTA_UNIT_TARGET_FLAG_NO_INVIS, DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE)
  -- Find nearest target and attack it
  local enemies = FindUnitsInRadius(parent:GetTeamNumber(), parent:GetAbsOrigin(), nil, parent:GetAcquisitionRange(), ability:GetAbilityTargetTeam(), ability:GetAbilityTargetType(), targets_flags, FIND_CLOSEST, false)
  if #enemies > 0 then
    parent:SetAggroTarget(enemies[1])
    --parent:SetForceAttackTarget(enemies[1])
  end
end

function modifier_death_ward_oaa:OnDestroy()
  if self.ward_particle then
    ParticleManager:DestroyParticle(self.ward_particle, true)
    ParticleManager:ReleaseParticleIndex(self.ward_particle)
    self.ward_particle = nil
  end
end

function modifier_death_ward_oaa:DeclareFunctions()
  local funcs ={
    MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
    MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
    MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
    MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
    MODIFIER_PROPERTY_DISABLE_HEALING,
    MODIFIER_EVENT_ON_ATTACK_START,
    MODIFIER_EVENT_ON_ATTACK_LANDED,
  }
  return funcs
end

function modifier_death_ward_oaa:GetAbsoluteNoDamagePhysical()
  return 1
end

function modifier_death_ward_oaa:GetAbsoluteNoDamageMagical()
  return 1
end

function modifier_death_ward_oaa:GetAbsoluteNoDamagePure()
  return 1
end

function modifier_death_ward_oaa:GetModifierAttackRangeBonus()
  return self.attack_range_bonus
end

function modifier_death_ward_oaa:GetDisableHealing()
  return 1
end

function modifier_death_ward_oaa:OnAttackStart(event)
  if not IsServer() then
    return
  end
  local parent = self:GetParent()
  local attacker = event.attacker
  local target = event.target

  if attacker ~= parent then
    return
  end

  if not target or target:IsNull() then
    return
  end

  if not attacker or attacker:IsNull() then
    return
  end

  if target.GetUnitName == nil then
    return
  end

  if not target:IsConsideredHero() then
    attacker:Interrupt()
    attacker:Stop()
    attacker:Hold()
    return
  end
  
  --local chronos = {}
  --local thinkers = Entities:FindAllByClassnameWithin("npc_dota_thinker", parent:GetAbsOrigin(), 500)
  --for _, thinker in pairs(thinkers) do
    --if thinker and thinker:HasModifier("modifier_faceless_void_chronosphere") then
      --table.insert(chronos, thinker)
    --end
  --end
  
  --if #chronos > 0 then
    --return
  --end

  -- Attack Sound
  parent:EmitSound("Hero_WitchDoctor_Ward.Attack")
end

function modifier_death_ward_oaa:OnAttackLanded(event)
  if not IsServer() then
    return
  end

  local parent = self:GetParent()
  local owner = self:GetCaster() --parent:GetOwner()
  local attacker = event.attacker
  local target = event.target

  if attacker ~= parent then
    return
  end

  if not target or target:IsNull() then
    return
  end

  if not attacker or attacker:IsNull() then
    return
  end

	-- Don't trigger when someone attacks items; this also prevents bouncing off items
  if target.GetUnitName == nil then
    return
  end

  if not target:IsConsideredHero() then
    return
  end

  local ability = self:GetAbility()
  if not ability or ability:IsNull() then
    return
  end

  -- Damage of the projectile
  local damage = ability:GetSpecialValueFor("ward_damage")
  -- Check for bonus damage talent
  local talent = owner:FindAbilityByName("special_bonus_unique_witch_doctor_5")
  if talent and talent:GetLevel() > 0 then
    damage = damage + talent:GetSpecialValueFor("value")
  end

  local damage_source = owner --parent

  -- Damage table of the projectile
  local damage_table = {}
  damage_table.attacker = damage_source
  damage_table.damage = damage
  damage_table.damage_type = ability:GetAbilityDamageType()
  damage_table.ability = ability
  damage_table.victim = target
  damage_table.damage_flags = bit.bor(DOTA_DAMAGE_FLAG_REFLECTION, DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL)

  ApplyDamage(damage_table)

  -- Handle Aghanim Scepter bounces

  -- If the owner of the Death Ward doesn't have Aghanim Scepter, don't continue
  if not owner:HasScepter() then
    return
  end

  local data = {}
  -- Mark the target as hit
  data[tostring(target:GetEntityIndex())] = 1

  local bounce_radius = ability:GetSpecialValueFor("scepter_bounce_radius")
  local targets_flags = bit.bor(DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, DOTA_UNIT_TARGET_FLAG_NOT_ATTACK_IMMUNE, DOTA_UNIT_TARGET_FLAG_NO_INVIS, DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE)

  -- Find closest target and fire a projectile from it
  local enemies = FindUnitsInRadius(parent:GetTeamNumber(), target:GetAbsOrigin(), nil, bounce_radius, ability:GetAbilityTargetTeam(), ability:GetAbilityTargetType(), targets_flags, FIND_CLOSEST, false)
  for _, enemy in ipairs(enemies) do
    if enemy ~= target then
      local projectile_info = {
        Target = enemy,
        Source = target,
        Ability = ability,
        EffectName = "particles/units/heroes/hero_witchdoctor/witchdoctor_ward_attack.vpcf",
        bDodgable = true,
        bProvidesVision = false,
        bVisibleToEnemies = true,
        bReplaceExisting = false,
        iMoveSpeed = parent:GetProjectileSpeed(),
        bIsAttack = false,
        iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_HITLOCATION,--DOTA_PROJECTILE_ATTACHMENT_ATTACK_1,
        ExtraData = data,
      }

      ProjectileManager:CreateTrackingProjectile(projectile_info)
      break
    end
  end
end

function modifier_death_ward_oaa:CheckState()
  local owner = self:GetCaster()
  local state = {
    [MODIFIER_STATE_CANNOT_MISS] = owner:HasScepter(),
    [MODIFIER_STATE_INVULNERABLE] = true,
    [MODIFIER_STATE_MAGIC_IMMUNE] = true,
    [MODIFIER_STATE_OUT_OF_GAME] = true,
    [MODIFIER_STATE_NO_HEALTH_BAR] = true,
    [MODIFIER_STATE_ATTACK_IMMUNE] = true,
  }
  return state
end

---------------------------------------------------------------------------------------------------

witch_doctor_voodoo_switcheroo_oaa = class(AbilityBaseClass)

LinkLuaModifier("modifier_voodoo_switcheroo_oaa", "abilities/oaa_witch_doctor_death_ward.lua", LUA_MODIFIER_MOTION_NONE)

function witch_doctor_voodoo_switcheroo_oaa:OnSpellStart()
  local unit_name = "npc_dota_witch_doctor_death_ward_oaa"
  local caster = self:GetCaster()
  local point = caster:GetAbsOrigin()

  -- Disjoint disjointable/dodgeable projectiles
  ProjectileManager:ProjectileDodge(caster)

  -- Hide the caster
  caster:AddNewModifier(caster, self, "modifier_voodoo_switcheroo_oaa", {duration = self:GetSpecialValueFor("duration")})

  -- Create Death Ward unit
  local death_ward = CreateUnitByName(unit_name, point, true, caster, caster, caster:GetTeamNumber())
  death_ward:SetOwner(caster)
  death_ward:SetControllableByPlayer(caster:GetPlayerOwnerID(), true)

  -- Sound
  death_ward:EmitSound("Hero_WitchDoctor.Death_WardBuild")

  -- Get Death Ward damage (needed if physical and not a spell damage)
  --local damage = self:GetSpecialValueFor("ward_damage")
  -- Check for bonus damage talent
  --local talent = caster:FindAbilityByName("special_bonus_unique_witch_doctor_5")
  --if talent and talent:GetLevel() > 0 then
    --damage = damage + talent:GetSpecialValueFor("value")
  --end
  -- Set Death Ward damage (needed if physical and not a spell damage)
  --death_ward:SetBaseDamageMax(damage)
  --death_ward:SetBaseDamageMin(damage)

  -- Apply modifiers to Death Ward
  death_ward:AddNewModifier(caster, self, "modifier_death_ward_oaa", {})
  death_ward:AddNewModifier(caster, self, "modifier_phased", {duration = 0.03}) -- unit will insta unstuck after this built-in modifier expires.

  -- Variable needed for later
  self.ward_unit = death_ward
end

function witch_doctor_voodoo_switcheroo_oaa:OnProjectileHit_ExtraData(target, location, data)
  --if not self.ward_unit or self.ward_unit:IsNull() then
    --return
  --end

  -- If target doesn't exist (disjointed), don't continue
  if not target or target:IsNull() then
    return
  end

  -- Get the owner of the Death Ward
  local owner = self:GetCaster() -- self.ward_unit:GetOwner()

  -- If owner doesn't exist, don't continue
  if not owner or owner:IsNull() then
    return
  end

  -- Source of the damage
  local damage_source = owner --self.ward_unit

  -- Damage of the projectile
  local damage = self:GetSpecialValueFor("ward_damage")
  -- Check for bonus damage talent
  local talent = owner:FindAbilityByName("special_bonus_unique_witch_doctor_5")
  if talent and talent:GetLevel() > 0 then
    damage = damage + talent:GetSpecialValueFor("value")
  end

  -- Damage table of the projectile
  local damage_table = {}
  damage_table.attacker = damage_source
  damage_table.damage = damage
  damage_table.damage_type = self:GetAbilityDamageType()
  damage_table.ability = self
  damage_table.victim = target
  damage_table.damage_flags = bit.bor(DOTA_DAMAGE_FLAG_REFLECTION, DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL)

  ApplyDamage(damage_table)

  -- If the owner of the Death Ward doesn't have Aghanim Scepter, don't continue
  if not owner:HasScepter() then
    return
  end

  local projectile_speed = 1000
  if self.ward_unit and not self.ward_unit:IsNull() then
    projectile_speed = self.ward_unit:GetProjectileSpeed()
  end

  -- Copy data table into new_data table
  local new_data = {}
  for k, v in pairs(data) do
    new_data[k] = v
  end

  -- Mark the target as hit
  new_data[tostring(target:GetEntityIndex())] = 1

  local bounce_radius = self:GetSpecialValueFor("scepter_bounce_radius")
  local targets_flags = bit.bor(DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, DOTA_UNIT_TARGET_FLAG_NOT_ATTACK_IMMUNE, DOTA_UNIT_TARGET_FLAG_NO_INVIS, DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE)
  -- Find nearest target and fire a projectile from it
  local enemies = FindUnitsInRadius(damage_source:GetTeamNumber(), target:GetAbsOrigin(), nil, bounce_radius, self:GetAbilityTargetTeam(), self:GetAbilityTargetType(), targets_flags, FIND_CLOSEST, false)
  for _, enemy in ipairs(enemies) do
    if enemy ~= target and new_data[tostring(enemy:GetEntityIndex())] ~= 1 then
      local projectile_info = {
        Target = enemy,
        Source = target,
        Ability = self,
        EffectName = "particles/units/heroes/hero_witchdoctor/witchdoctor_ward_attack.vpcf",
        bDodgable = true,
        bProvidesVision = false,
        bVisibleToEnemies = true,
        bReplaceExisting = false,
        iMoveSpeed = projectile_speed,
        bIsAttack = false,
        iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_HITLOCATION,
        ExtraData = new_data,
      }

      ProjectileManager:CreateTrackingProjectile(projectile_info)
      break
    end
  end
end

function witch_doctor_voodoo_switcheroo_oaa:OnHeroCalculateStatBonus()
  local caster = self:GetCaster()

  if caster:HasShardOAA() then
    self:SetHidden(false)
    if self:GetLevel() <= 0 then
      self:SetLevel(1)
    end
  else
    self:SetHidden(true)
  end
end

function witch_doctor_voodoo_switcheroo_oaa:IsStealable()
  return true
end

function witch_doctor_voodoo_switcheroo_oaa:IsHiddenWhenStolen()
  return false
end

function witch_doctor_voodoo_switcheroo_oaa:ProcsMagicStick()
  return true
end

---------------------------------------------------------------------------------------------------

modifier_voodoo_switcheroo_oaa = class(ModifierBaseClass)

function modifier_voodoo_switcheroo_oaa:IsDebuff()
  return false
end

function modifier_voodoo_switcheroo_oaa:IsHidden()
  return true
end

function modifier_voodoo_switcheroo_oaa:IsPurgable()
  return true
end

if IsServer() then
  function modifier_voodoo_switcheroo_oaa:OnCreated()
    local parent = self:GetParent()
    -- Hide the parent visually
    parent:AddNoDraw()
  end

  function modifier_voodoo_switcheroo_oaa:OnDestroy()
    local parent = self:GetParent()

    -- Unhide the parent visually
    parent:RemoveNoDraw()

    -- Remove the ward
    local ability = self:GetAbility()
    if ability.ward_unit and not ability.ward_unit:IsNull() then
      ability.ward_unit:StopSound("Hero_WitchDoctor.Death_WardBuild")
      ability.ward_unit:AddNewModifier(parent, ability, "modifier_death_ward_hidden_oaa", {duration = 3})
    end
  end
end

function modifier_voodoo_switcheroo_oaa:DeclareFunctions()
  local funcs ={
    MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
    MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
    MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
  }
  return funcs
end

function modifier_voodoo_switcheroo_oaa:GetAbsoluteNoDamagePhysical()
  return 1
end

function modifier_voodoo_switcheroo_oaa:GetAbsoluteNoDamageMagical()
  return 1
end

function modifier_voodoo_switcheroo_oaa:GetAbsoluteNoDamagePure()
  return 1
end

function modifier_voodoo_switcheroo_oaa:CheckState()
  local state = {
    [MODIFIER_STATE_INVULNERABLE] = true,
    [MODIFIER_STATE_MAGIC_IMMUNE] = true,
    [MODIFIER_STATE_OUT_OF_GAME] = true,
    [MODIFIER_STATE_NO_HEALTH_BAR] = true,
    [MODIFIER_STATE_ATTACK_IMMUNE] = true,
    [MODIFIER_STATE_COMMAND_RESTRICTED] = true,
  }
  return state
end

---------------------------------------------------------------------------------------------------

modifier_death_ward_hidden_oaa = class(ModifierBaseClass)

function modifier_death_ward_hidden_oaa:IsDebuff()
  return false
end

function modifier_death_ward_hidden_oaa:IsHidden()
  return true
end

function modifier_death_ward_hidden_oaa:IsPurgable()
  return false
end

if IsServer() then
  function modifier_death_ward_hidden_oaa:OnCreated()
    local parent = self:GetParent()
    -- Hide the parent visually
    parent:AddNoDraw()
  end

  function modifier_death_ward_hidden_oaa:OnDestroy()
    local parent = self:GetParent()
    parent:ForceKill(false)
  end
end

function modifier_death_ward_hidden_oaa:DeclareFunctions()
  local funcs ={
    MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
    MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
    MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
  }
  return funcs
end

function modifier_death_ward_hidden_oaa:GetAbsoluteNoDamagePhysical()
  return 1
end

function modifier_death_ward_hidden_oaa:GetAbsoluteNoDamageMagical()
  return 1
end

function modifier_death_ward_hidden_oaa:GetAbsoluteNoDamagePure()
  return 1
end

function modifier_death_ward_hidden_oaa:CheckState()
  local state = {
    [MODIFIER_STATE_INVULNERABLE] = true,
    [MODIFIER_STATE_MAGIC_IMMUNE] = true,
    [MODIFIER_STATE_OUT_OF_GAME] = true,
    [MODIFIER_STATE_NO_HEALTH_BAR] = true,
    [MODIFIER_STATE_ATTACK_IMMUNE] = true,
    [MODIFIER_STATE_COMMAND_RESTRICTED] = true,
    [MODIFIER_STATE_DISARMED] = true,
  }
  return state
end