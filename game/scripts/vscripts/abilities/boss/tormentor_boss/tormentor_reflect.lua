LinkLuaModifier("modifier_tormentor_reflect_oaa", "abilities/boss/tormentor_boss/tormentor_reflect.lua", LUA_MODIFIER_MOTION_NONE)

tormentor_boss_reflect_oaa = class(AbilityBaseClass)

function tormentor_boss_reflect_oaa:Precache(context)
  PrecacheResource("particle", "particles/neutral_fx/miniboss_shield.vpcf", context)
  PrecacheResource("particle", "particles/neutral_fx/miniboss_damage_reflect.vpcf", context)
  PrecacheResource("particle", "particles/neutral_fx/miniboss_damage_impact.vpcf", context)
  PrecacheResource("particle", "particles/neutral_fx/miniboss_death.vpcf", context)
  PrecacheResource("particle", "particles/neutral_fx/miniboss_shield_dire.vpcf", context)
  PrecacheResource("particle", "particles/neutral_fx/miniboss_damage_reflect_dire.vpcf", context)
  PrecacheResource("particle", "particles/neutral_fx/miniboss_dire_damage_impact.vpcf", context)
  PrecacheResource("particle", "particles/neutral_fx/miniboss_death_dire.vpcf", context)
end

function tormentor_boss_reflect_oaa:GetIntrinsicModifierName()
  return "modifier_tormentor_reflect_oaa"
end

function tormentor_boss_reflect_oaa:IsStealable()
  return false
end

function tormentor_boss_reflect_oaa:ProcMagicStick()
  return false
end

---------------------------------------------------------------------------------------------------

modifier_tormentor_reflect_oaa = class({})

function modifier_tormentor_reflect_oaa:IsHidden() -- needs tooltip
  return false
end

function modifier_tormentor_reflect_oaa:IsDebuff()
  return false
end

function modifier_tormentor_reflect_oaa:IsPurgable()
  return false
end

function modifier_tormentor_reflect_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_TOOLTIP,
    MODIFIER_EVENT_ON_TAKEDAMAGE,
    MODIFIER_EVENT_ON_DEATH,
  }
end

function modifier_tormentor_reflect_oaa:OnCreated()
  if not IsServer() then return end

  self.parent = self:GetParent()
  self.ability = self:GetAbility()

  self.radius = self.ability:GetSpecialValueFor("radius")
  self.illusion_damage_pct = self.ability:GetSpecialValueFor("illusion_damage_pct")
  self.reflection = self.ability:GetSpecialValueFor("passive_reflection_pct")

  self.pfx_name = {}
  self.pfx_name[DOTA_TEAM_GOODGUYS] = {
    shield = "particles/neutral_fx/miniboss_shield.vpcf",
    reflect = "particles/neutral_fx/miniboss_damage_reflect.vpcf",
    impact = "particles/neutral_fx/miniboss_damage_impact.vpcf",
    death = "particles/neutral_fx/miniboss_death.vpcf",
  }

  self.pfx_name[DOTA_TEAM_BADGUYS] = {
    shield = "particles/neutral_fx/miniboss_shield_dire.vpcf",
    reflect = "particles/neutral_fx/miniboss_damage_reflect_dire.vpcf",
    impact = "particles/neutral_fx/miniboss_dire_damage_impact.vpcf",
    death = "particles/neutral_fx/miniboss_death_dire.vpcf",
  }

  -- This delay is required because the tormentor team is not set yet when the modifier is created
  self:StartIntervalThink(1)

  -- Needs a transmitter just because of the tooltip
  self:SetHasCustomTransmitterData(true)
end

function modifier_tormentor_reflect_oaa:OnIntervalThink()
  if not IsServer() then return end

  local parent = self:GetParent()
  if parent and not parent:IsNull() then
    local team = parent.tormentorTeam
    if team and self.pfx_name[team] then
      local particle_name = self.pfx_name[team].shield
      self.shield_pfx = ParticleManager:CreateParticle(particle_name, PATTACH_CENTER_FOLLOW, parent)
      self:StartIntervalThink(-1)
    end
  else
    self:StartIntervalThink(-1)
  end
end

-- server-only function that is called whenever SetHasCustomTransmitterData(true) or SendBuffRefreshToClients() is called
function modifier_tormentor_reflect_oaa:AddCustomTransmitterData()
  return {
    reflection = self.reflection,
  }
end

-- client-only function that is called with the table returned by AddCustomTransmitterData()
function modifier_tormentor_reflect_oaa:HandleCustomTransmitterData(data)
  self.reflection = data.reflection
end

if IsServer() then
  function modifier_tormentor_reflect_oaa:OnTakeDamage(event)
    local damage = event.original_damage
    local damageType = event.damage_type
    local damageFlags = event.damage_flags
    local attacker = event.attacker

    -- Check if attacker exists
    if not attacker or attacker:IsNull() then
      return
    end

    -- Check if damaged unit has this modifier
    if event.unit ~= self.parent then return end

    -- Ignore self damage
    if attacker == self.parent then
      return
    end

    -- Ignore damage that has the no-reflect flag
    if bit.band(damageFlags, DOTA_DAMAGE_FLAG_REFLECTION) > 0 then
      return
    end

    -- Ignore damage that has the no-spell-lifesteal flag
    if bit.band(damageFlags, DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL) > 0 then
      return
    end

    -- Ignore damage that has the no-spell-amplification flag
    if bit.band(damageFlags, DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION) > 0 then
      return
    end

    local enemies = FindUnitsInRadius(
      self.parent:GetTeamNumber(),
      self.parent:GetAbsOrigin(),
      nil,
      self.radius,
      DOTA_UNIT_TARGET_TEAM_ENEMY,
      DOTA_UNIT_TARGET_HERO,
      DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
      FIND_ANY_ORDER,
      false
    )

    -- Parts of damage table that are always the same
    local damageTable = {
      attacker = self.parent,
      damage_type = damageType,
      ability = self.ability,
      damage_flags = DOTA_DAMAGE_FLAG_REFLECTION,
    }

    if #enemies == 0 then
      -- Always affect the attacker, doesn't matter where it is even if there are no enemies around
      damageTable.victim = attacker
      damageTable.damage = damage * self.reflection / 100

      ApplyDamage(damageTable)

      local pfx = ParticleManager:CreateParticle(self.pfx_name[self.parent.tormentorTeam].reflect, PATTACH_ABSORIGIN_FOLLOW, self.parent)
      ParticleManager:SetParticleControl(pfx, 0, self.parent:GetAbsOrigin())
      ParticleManager:SetParticleControlEnt(pfx, 1, attacker, PATTACH_POINT_FOLLOW, "attach_hitloc", attacker:GetAbsOrigin(), true)
      -- ParticleManager:SetParticleControl(pfx, 1, attacker:GetAbsOrigin())
      ParticleManager:ReleaseParticleIndex(pfx)

      -- EmitSoundOnClient("Miniboss.Tormenter.Reflect", attacker)
      attacker:EmitSound("Miniboss.Tormenter.Reflect")
      return
    end

    -- Count non-illusion enemies
    local number_of_valid_enemies = 0
    for _, enemy in pairs(enemies) do
      if enemy and not enemy:IsNull() and IsValidEntity(enemy) and enemy:IsAlive() and not enemy:IsIllusion() then
        number_of_valid_enemies = number_of_valid_enemies + 1
      end
    end

    -- When attacker is damaging Tormentor from far away and only ilussions are around
    -- to prevent division by 0
    if number_of_valid_enemies == 0 then
      number_of_valid_enemies = 1
    end

    -- Distribute the damage among the present units
    local reflectedDamage = (damage * self.reflection / 100) / number_of_valid_enemies
    for _, enemy in pairs(enemies) do
      if enemy and not enemy:IsNull() and IsValidEntity(enemy) and enemy:IsAlive() and enemy ~= attacker then
        damageTable.victim = enemy
        damageTable.damage = reflectedDamage

        if enemy:IsIllusion() then
          damageTable.damage = reflectedDamage * self.illusion_damage_pct / 100
        end

        ApplyDamage(damageTable)

        local pfx = ParticleManager:CreateParticle(self.pfx_name[self.parent.tormentorTeam].reflect, PATTACH_ABSORIGIN_FOLLOW, self.parent)
        ParticleManager:SetParticleControl(pfx, 0, self.parent:GetAbsOrigin())
        ParticleManager:SetParticleControlEnt(pfx, 1, enemy, PATTACH_POINT_FOLLOW, "attach_hitloc", enemy:GetAbsOrigin(), true)
        -- ParticleManager:SetParticleControl(pfx, 1, enemy:GetAbsOrigin())
        ParticleManager:ReleaseParticleIndex(pfx)

        -- EmitSoundOnClient("Miniboss.Tormenter.Reflect", enemy)
        enemy:EmitSound("Miniboss.Tormenter.Reflect")
      end
    end

    -- Always affect the attacker, doesn't matter where it is
    damageTable.victim = attacker
    damageTable.damage = reflectedDamage

    if attacker:IsIllusion() then
      damageTable.damage = reflectedDamage * self.illusion_damage_pct / 100
    end

    ApplyDamage(damageTable)

    local pfx = ParticleManager:CreateParticle(self.pfx_name[self.parent.tormentorTeam].reflect, PATTACH_ABSORIGIN_FOLLOW, self.parent)
    ParticleManager:SetParticleControl(pfx, 0, self.parent:GetAbsOrigin())
    ParticleManager:SetParticleControlEnt(pfx, 1, attacker, PATTACH_POINT_FOLLOW, "attach_hitloc", attacker:GetAbsOrigin(), true)
    -- ParticleManager:SetParticleControl(pfx, 1, attacker:GetAbsOrigin())
    ParticleManager:ReleaseParticleIndex(pfx)

    -- EmitSoundOnClient("Miniboss.Tormenter.Reflect", attacker)
    attacker:EmitSound("Miniboss.Tormenter.Reflect")
  end

  function modifier_tormentor_reflect_oaa:OnDeath(event)
    local unit = event.unit

    if unit ~= self.parent then return end

    if self.shield_pfx then
      ParticleManager:DestroyParticle(self.shield_pfx, true)
      ParticleManager:ReleaseParticleIndex(self.shield_pfx)
    end

    local pfx = ParticleManager:CreateParticle(self.pfx_name[self.parent.tormentorTeam].death, PATTACH_ABSORIGIN_FOLLOW, self.parent)
    ParticleManager:SetParticleControl(pfx, 0, self.parent:GetAbsOrigin())
    ParticleManager:ReleaseParticleIndex(pfx)
  end
end

function modifier_tormentor_reflect_oaa:OnTooltip()
  return self.reflection
end
