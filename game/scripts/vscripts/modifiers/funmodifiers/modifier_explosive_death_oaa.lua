
modifier_explosive_death_oaa = class(ModifierBaseClass)

function modifier_explosive_death_oaa:IsHidden()
  return false
end

function modifier_explosive_death_oaa:IsDebuff()
  return false
end

function modifier_explosive_death_oaa:IsPurgable()
  return false
end

function modifier_explosive_death_oaa:RemoveOnDeath()
  return false
end

function modifier_explosive_death_oaa:OnCreated()
  self.radius = 500
  self.radius_per_lvl = 5
  self.delay = 0.4
  self.base_damage = 150
  self.hp_percent = 10
  self.networth_percent = 1.5
end

function modifier_explosive_death_oaa:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_DEATH,
    MODIFIER_PROPERTY_TOOLTIP,
  }
end

if IsServer() then
  function modifier_explosive_death_oaa:OnDeath(event)
    local parent = self:GetParent()
    local dead = event.unit

    if dead ~= parent then
      return
    end

    -- Dead unit already deleted, don't continue to prevent errors
    if not parent or parent:IsNull() then
      return
    end

    --if parent:IsIllusion() or parent:IsTempestDouble() or parent:IsReincarnating() then
      --return
    --end

    local death_location = parent:GetAbsOrigin()
    local level = parent:GetLevel()
    self.death_location = death_location
    self.level = level
    self.team = parent:GetTeamNumber()
    self.health = parent:GetMaxHealth()
    self.networth = 0
    if parent:IsHero() then
      self.networth = parent:GetNetworth()
    end

    local radius = self.radius + (self.radius_per_lvl * level)
    local delay = self.delay

    -- Warning Sound
    EmitSoundOnLocationWithCaster(death_location, "Hero_Pugna.NetherBlastPreCast", parent)

    -- Warning Particle
    local particle_pre_blast_fx = ParticleManager:CreateParticle("particles/units/heroes/hero_pugna/pugna_netherblast_pre.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
    ParticleManager:SetParticleControl(particle_pre_blast_fx, 0, death_location)
    ParticleManager:SetParticleControl(particle_pre_blast_fx, 1, Vector(radius, delay, 1))
    ParticleManager:ReleaseParticleIndex(particle_pre_blast_fx)

    self:StartIntervalThink(delay)
  end

  function modifier_explosive_death_oaa:OnIntervalThink()
    local parent = self:GetParent()
    local death_location = self.death_location
    local team = self.team
    local level = self.level
    local health = self.health
    local networth = self.networth

    local radius = self.radius + (self.radius_per_lvl * level)
    local base_damage = self.base_damage
    local hp_percent = self.hp_percent
    local networth_percent = self.networth_percent

    -- Explosion sound
    EmitSoundOnLocationWithCaster(death_location, "Hero_Pugna.NetherBlast", parent)

    -- Explosion particle
    local particle_blast_fx = ParticleManager:CreateParticle("particles/units/heroes/hero_pugna/pugna_netherblast.vpcf", PATTACH_ABSORIGIN, parent)
    ParticleManager:SetParticleControl(particle_blast_fx, 0, death_location)
    ParticleManager:SetParticleControl(particle_blast_fx, 1, Vector(radius, 0, 0))
    ParticleManager:ReleaseParticleIndex(particle_blast_fx)

    -- Find all enemies
    local enemies = FindUnitsInRadius(
      team,
      death_location,
      nil,
      radius,
      DOTA_UNIT_TARGET_TEAM_ENEMY,
      bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC),
      DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
      FIND_ANY_ORDER,
      false
    )

    local damage_table = {
      damage = base_damage + hp_percent * health * 0.01 + networth_percent * networth * 0.01,
      damage_type = DAMAGE_TYPE_PURE,
      attacker = parent,
      damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION,
    }

    self:SetStackCount(0-damage_table.damage)

    local knockback_table = {
      should_stun = 0,
      knockback_duration = 0.5,
      duration = 0.5,
      knockback_distance = 200 + (8 * level),
      knockback_height = 20 + (10 * level),
      center_x = death_location.x,
      center_y = death_location.y,
      center_z = death_location.z
    }

    for _, enemy in pairs(enemies) do
      if enemy and not enemy:IsNull() then
        -- Apply knockback
        enemy:AddNewModifier(enemy, nil, "modifier_knockback", knockback_table)
        -- Damage
        damage_table.victim = enemy
        ApplyDamage(damage_table)
      end
    end

    self:StartIntervalThink(-1)
  end
end

function modifier_explosive_death_oaa:OnTooltip()
  return math.abs(self:GetStackCount())
end

function modifier_explosive_death_oaa:GetTexture()
  return "pugna_nether_blast"
end
