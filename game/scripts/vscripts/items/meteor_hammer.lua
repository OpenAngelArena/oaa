LinkLuaModifier("modifier_generic_bonus", "modifiers/modifier_generic_bonus.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_meteor_hammer_thinker", "items/meteor_hammer.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier("modifier_item_meteor_hammer_damage_over_time", "items/meteor_hammer.lua", LUA_MODIFIER_MOTION_NONE)

item_meteor_hammer_1 = class(ItemBaseClass)
item_meteor_hammer_2 = item_meteor_hammer_1
item_meteor_hammer_3 = item_meteor_hammer_1
item_meteor_hammer_4 = item_meteor_hammer_1
item_meteor_hammer_5 = item_meteor_hammer_1

function item_meteor_hammer_1:GetAOERadius()
  return self:GetSpecialValueFor("impact_radius")
end

function item_meteor_hammer_1:OnSpellStart()
  local caster = self:GetCaster()
  local target_location = self:GetCursorPosition()
  local vision_duration = math.max(self:GetChannelTime() + self:GetSpecialValueFor("land_time") + self:GetSpecialValueFor("stun_duration"), 3.8)
  local radius = self:GetSpecialValueFor("impact_radius")

  caster:EmitSound("DOTA_Item.MeteorHammer.Channel")

  caster:StartGesture(ACT_DOTA_TELEPORT)

  self:CreateVisibilityNode(target_location, radius, vision_duration)

  --Particle that surrounds caster
  self.channel_particle_caster = ParticleManager:CreateParticle("particles/items4_fx/meteor_hammer_cast.vpcf", PATTACH_ABSORIGIN, caster)
  --Particle that surrounds meteor_hammer's aoe.
  self.channel_particle = ParticleManager:CreateParticleForTeam("particles/items4_fx/meteor_hammer_aoe.vpcf", PATTACH_CUSTOMORIGIN, caster, caster:GetTeam())
  ParticleManager:SetParticleControl(self.channel_particle, 0, target_location)
  ParticleManager:SetParticleControl(self.channel_particle, 1, Vector(radius, 0, 0))
end

function item_meteor_hammer_1:OnChannelFinish(bInterrupted)
  local caster = self:GetCaster()

  caster:FadeGesture(ACT_DOTA_TELEPORT)

  if not bInterrupted then
    caster:EmitSound("DOTA_Item.MeteorHammer.Cast")
    CreateModifierThinker(caster, self, "modifier_item_meteor_hammer_thinker", {}, self:GetCursorPosition(), caster:GetTeamNumber(), false)
  else
    caster:StopSound("DOTA_Item.MeteorHammer.Channel")
    ParticleManager:DestroyParticle(self.channel_particle_caster, true)
    ParticleManager:DestroyParticle(self.channel_particle, true)
  end

  ParticleManager:ReleaseParticleIndex(self.channel_particle_caster)
  ParticleManager:ReleaseParticleIndex(self.channel_particle)
end

function item_meteor_hammer_1:GetIntrinsicModifierName()
  return "modifier_generic_bonus"
end
-----------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------

modifier_item_meteor_hammer_thinker = class(ModifierBaseClass)

function modifier_item_meteor_hammer_thinker:OnCreated()
  if IsServer() then
    local ability = self:GetAbility()
    local parent = self:GetParent()
    -- item info from kv
    self.impact_radius = ability:GetSpecialValueFor("impact_radius")
    self.impact_damage = ability:GetSpecialValueFor("impact_damage")
    self.impact_damage_bosses = ability:GetSpecialValueFor("impact_damage_boss")

    self.land_time = ability:GetSpecialValueFor("land_time")
    self.burn_duration = ability:GetSpecialValueFor("burn_duration")
    self.stun_duration = ability:GetSpecialValueFor("stun_duration")
    --landtime should not be a negative number
    self:StartIntervalThink(self.land_time)

    local impact_particle = ParticleManager:CreateParticle("particles/items4_fx/meteor_hammer_spell.vpcf", PATTACH_WORLDORIGIN, nil)

    --Controls the metoer position to origin
    ParticleManager:SetParticleControl(impact_particle, 0, parent:GetOrigin() + Vector(0, 0, 1000))
    ParticleManager:SetParticleControl(impact_particle, 1, parent:GetOrigin())
    --Fade time of cetain particles
    ParticleManager:SetParticleControl(impact_particle, 2, Vector(self.land_time, 0, 0))
    ParticleManager:ReleaseParticleIndex(impact_particle)
  end
end

function modifier_item_meteor_hammer_thinker:OnIntervalThink()
 local parent = self:GetParent()
 local caster = self:GetCaster()

  parent:EmitSound("DOTA_Item.MeteorHammer.Impact")

  if IsServer() then
    GridNav:DestroyTreesAroundPoint(parent:GetOrigin(), self.impact_radius, true)

    local ability = self:GetAbility()
    local enemies = FindUnitsInRadius(caster:GetTeamNumber(), parent:GetOrigin(), caster, self.impact_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)

    if enemies then
      for _, enemy in pairs(enemies) do
        -- Debuffs first, then damage
        -- Apply damage-over-time debuff (duration is not affected by status resistance)
        enemy:AddNewModifier(caster, ability, "modifier_item_meteor_hammer_damage_over_time", {duration = self.burn_duration})
        -- Apply stun debuff (duration is affected by status resistance)
        local stun_duration = enemy:GetValueChangedByStatusResistance(self.stun_duration)
        enemy:AddNewModifier(caster, ability, "modifier_stunned", {duration = stun_duration})

        local damage_table = {
          victim = enemy,
          attacker = caster,
          damage = self.impact_damage,
          damage_type = DAMAGE_TYPE_MAGICAL,
          ability = ability,
        }
        -- Is the enemy a boss?
        if enemy:IsOAABoss() then
          damage_table.damage = self.impact_damage_bosses
        end

        ApplyDamage(damage_table)
      end-- end of for enemy pairs
    end-- end of if enemies statemnt

    self:StartIntervalThink(-1)
  end-- end of if server

  UTIL_Remove(self:GetParent())
end-- end of function

function modifier_item_meteor_hammer_thinker:IsPurgable()
  return false
end

function modifier_item_meteor_hammer_thinker:IsHidden()
  return true
end

-----------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------
modifier_item_meteor_hammer_damage_over_time = class(ModifierBaseClass)

function modifier_item_meteor_hammer_damage_over_time:OnCreated(params)
  if IsServer() then
    local enemy = self:GetParent()
    local caster = self:GetCaster()
    local ability = self:GetAbility()

    self.burn_dps = ability:GetSpecialValueFor("burn_dps")
    self.burn_dps_boss = ability:GetSpecialValueFor("burn_dps_boss")
    self.burn_interval = ability:GetSpecialValueFor("burn_interval")

    local damage_table = {
      victim = enemy,
      attacker = caster,
      damage = self.burn_dps * self.burn_interval,
      damage_type = DAMAGE_TYPE_MAGICAL,
      ability = ability,
    }

    if enemy:IsOAABoss() then
      damage_table.damage = self.burn_dps_boss * self.burn_interval
    end

    ApplyDamage(damage_table)

    self:StartIntervalThink(self.burn_interval)
  end
end

function modifier_item_meteor_hammer_damage_over_time:OnIntervalThink()
  if IsServer() then
    local enemy = self:GetParent()
    local caster = self:GetCaster()
    local ability = self:GetAbility()

    local damage_table = {
      victim = enemy,
      attacker = caster,
      damage = self.burn_dps * self.burn_interval,
      damage_type = DAMAGE_TYPE_MAGICAL,
      ability = ability,
    }

    if enemy:IsOAABoss() then
      damage_table.damage = self.burn_dps_boss * self.burn_interval
    end

    ApplyDamage(damage_table)
  end
end

function modifier_item_meteor_hammer_damage_over_time:GetEffectName()
  return "particles/items4_fx/meteor_hammer_spell_debuff.vpcf"
end

function modifier_item_meteor_hammer_damage_over_time:IsDebuff()
  return true
end

function modifier_item_meteor_hammer_damage_over_time:IsPurgable()
  return not self:GetParent():IsOAABoss()
end
