furion_wrath_of_nature_oaa = class(AbilityBaseClass)

LinkLuaModifier("modifier_furion_wrath_of_nature_thinker_oaa", "abilities/furion_wrath_of_nature_oaa.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_treant_bonus_oaa", "modifiers/modifier_treant_bonus_oaa", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_furion_wrath_of_nature_scepter_debuff", "abilities/furion_wrath_of_nature_oaa.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_furion_wrath_of_nature_hit_debuff", "abilities/furion_wrath_of_nature_oaa.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_furion_wrath_of_nature_kill_damage_counter", "abilities/furion_wrath_of_nature_oaa.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_furion_wrath_of_nature_kill_damage_buff", "abilities/furion_wrath_of_nature_oaa.lua", LUA_MODIFIER_MOTION_NONE)

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
    -- If target doesn't have Spell Block then
    if not target:TriggerSpellAbsorb(self) then
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
  return "furion_force_of_nature"
end

-- This would be needed if furion_force_of_nature was a vanilla ability
-- OAA has a custom furion_force_of_nature with the same ability name so we can deal with spell steal mechanics there
--[[
function furion_wrath_of_nature_oaa:OnStolen(hSourceAbility)
  local caster = self:GetCaster()
  local force_of_nature_ability = caster:FindAbilityByName("furion_force_of_nature")

  if force_of_nature_ability and not caster:FindAbilityByName("morphling_replicate") then
    force_of_nature_ability:SetHidden(true)
    force_of_nature_ability:SetStolen(true)
  end
end
]]

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

function modifier_furion_wrath_of_nature_thinker_oaa:OnIntervalThink()
  if IsServer() then
    local parent = self:GetParent()
    local new_target = self:GetNextTarget()
    if not new_target then
      --print("Wrath of Nature thinker couldn't find new target, destroying!")
      self:Destroy()
      return
    end

    -- Bounce Particle
    self:CreateBounceFX(new_target)
    -- Move the thinker to the new target for easier searching
    parent:SetOrigin(new_target:GetAbsOrigin())
    -- Damage and scepter effect
	  self:HitTarget(new_target)

    if #self.targets_hit >= self.max_targets then
      --print("Wrath of Nature thinker reached max number of targets, destroying!")
      self:Destroy()
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

  if #enemies ~= 0 then
    for i=1, #enemies do
      if enemies[i] then
        -- Remove couriers and units that cannot be seen by caster's team (invisible but not revealed)
        if enemies[i]:IsCourier() or not caster:CanEntityBeSeenByMyTeam(enemies[i]) then
          table.remove(enemies, i)
        end
      end
    end
  end

  local nearest_enemy
  local flClosestDist = 0.0
  if #enemies > 0 then
    for _,enemy in pairs(enemies) do
      if enemy then
        local bHitByWrath = false
        if self.targets_hit then
          for _,hHitEnemy in ipairs(self.targets_hit) do
            if enemy == hHitEnemy then
              bHitByWrath = true
            end
          end
        end

        if bHitByWrath == false then
          local vToTarget = enemy:GetOrigin() - parent:GetOrigin()
          local flDistToTarget = vToTarget:Length()

          if nearest_enemy == nil or flDistToTarget < flClosestDist then
            nearest_enemy = enemy
            flClosestDist = flDistToTarget
          end
        end
      end
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
  if bHasScepter then
    local force_of_nature_ability = caster:FindAbilityByName("furion_force_of_nature")
    if force_of_nature_ability and force_of_nature_ability:GetLevel() > 0 then
      hTarget:AddNewModifier(caster, force_of_nature_ability, "modifier_furion_wrath_of_nature_scepter_debuff", {duration = self.scepter_debuff_duration})
    end
  end

  -- Apply a modifier to the unit that will trigger on unit death and give dmg to the caster
  hTarget:AddNewModifier(caster, ability, "modifier_furion_wrath_of_nature_hit_debuff", {duration = 0.3})

  -- Calculate damage
  local nTargetsHit = 0
  if self.targets_hit then
    nTargetsHit = #self.targets_hit
  end
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

  -- Apply damage
  ApplyDamage(damage_table)

  -- Sounds
  if hTarget:IsHero() then
    hTarget:EmitSound("Hero_Furion.WrathOfNature_Damage")
  else
    hTarget:EmitSound("Hero_Furion.WrathOfNature_Damage.Creep")
  end

  -- Add hTarget to the already hit table
  table.insert(self.targets_hit, hTarget)

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

  local nFXIndexHit = ParticleManager:CreateParticle( "particles/units/heroes/hero_furion/furion_wrath_of_nature.vpcf", PATTACH_CUSTOMORIGIN, nil );
  ParticleManager:SetParticleControl( nFXIndexHit, 0, vTarget1 );
  ParticleManager:SetParticleControl( nFXIndexHit, 1, vTarget2 );
  ParticleManager:SetParticleControl( nFXIndexHit, 2, vTarget3 );
  ParticleManager:SetParticleControl( nFXIndexHit, 3, vTarget4 );
  ParticleManager:SetParticleControlOrientation( nFXIndexHit, 0, Vector( 0, 0, 1), Vector( 0, 1, 0), Vector( 1, 0, 0 ) );
  ParticleManager:SetParticleControlOrientation( nFXIndexHit, 1, Vector( 0, 0, 1), Vector( 0, 1, 0), Vector( 1, 0, 0 ) );
  ParticleManager:SetParticleControlOrientation( nFXIndexHit, 2, Vector( 0, 0, 1), Vector( 0, 1, 0), Vector( 1, 0, 0 ) );
  ParticleManager:SetParticleControlEnt( nFXIndexHit, 4, self.target, PATTACH_ABSORIGIN_FOLLOW, nil, self:GetCaster():GetOrigin(), false );
  ParticleManager:ReleaseParticleIndex( nFXIndexHit );
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
  return true
end

function modifier_furion_wrath_of_nature_scepter_debuff:DeclareFunctions()
  local funcs = {
    MODIFIER_EVENT_ON_DEATH,
  }
  return funcs
end

function modifier_furion_wrath_of_nature_scepter_debuff:OnDeath(event)
  if IsServer() then
    local parent = self:GetParent()
    if event.unit == parent then
      local caster = self:GetCaster()
      if not caster then
        return
      end
      local force_of_nature_ability = caster:FindAbilityByName("furion_force_of_nature")

      -- Rubick stole Wrath of Nature but he doesn't have Force of Nature for some reason
      if not force_of_nature_ability then
        return
      end

      -- Rubick stole something else while debuff still existed
      if force_of_nature_ability:IsNull() then
        return
      end
      local level = force_of_nature_ability:GetLevel()
      local treantName = "npc_dota_furion_treant_" .. level
      if parent:IsHero() then
        treantName = "npc_dota_furion_treant_large_" .. level
      end

      -- Check whether the caster has learnt the 2x Treant health/damage talent
      local has_talent = caster:HasLearnedAbility("special_bonus_unique_furion")

      local treant = CreateUnitByName(treantName, parent:GetAbsOrigin(), true, caster, caster:GetOwner(), caster:GetTeamNumber())
      if treant then
        treant:SetControllableByPlayer(caster:GetPlayerID(), false)
        treant:SetOwner(caster)
        if has_talent then
          treant:AddNewModifier(caster, force_of_nature_ability, "modifier_treant_bonus_oaa", {})
        end

        treant:AddNewModifier(caster, force_of_nature_ability, "modifier_kill", {duration = force_of_nature_ability:GetSpecialValueFor("duration")})
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
  local funcs = {
    MODIFIER_EVENT_ON_DEATH,
  }
  return funcs
end

function modifier_furion_wrath_of_nature_hit_debuff:OnDeath(event)
  if IsServer() then
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
