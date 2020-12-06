wanderer_aoe_cleanse = class(AbilityBaseClass)

function wanderer_aoe_cleanse:Precache(context)
  PrecacheResource("particle", "particles/darkmoon_creep_warning.vpcf", context)
  PrecacheResource("particle", "particles/test_particle/ogre_melee_smash.vpcf", context)
  PrecacheResource("soundfile", "soundevents/bosses/game_sounds_dungeon_enemies.vsndevts", context)
end

function wanderer_aoe_cleanse:OnAbilityPhaseStart()
  if IsServer() then
    local caster = self:GetCaster()
    self.nPreviewFX = ParticleManager:CreateParticle("particles/darkmoon_creep_warning.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
    ParticleManager:SetParticleControlEnt(self.nPreviewFX, 0, caster, PATTACH_ABSORIGIN_FOLLOW, nil, caster:GetOrigin(), true)
    ParticleManager:SetParticleControl(self.nPreviewFX, 1, Vector(self:GetSpecialValueFor("radius"), self:GetSpecialValueFor("radius"), 175))
    ParticleManager:SetParticleControl(self.nPreviewFX, 15, Vector(255, 140, 0))
  end
  return true
end

function wanderer_aoe_cleanse:OnAbilityPhaseInterrupted()
  if IsServer() then
    if self.nPreviewFX then
      ParticleManager:DestroyParticle(self.nPreviewFX, true)
      ParticleManager:ReleaseParticleIndex(self.nPreviewFX)
      self.nPreviewFX = nil
    end
  end
end

function wanderer_aoe_cleanse:OnSpellStart()
  -- Remove ability phase (cast) particle
  if self.nPreviewFX then
    ParticleManager:DestroyParticle(self.nPreviewFX, true)
    ParticleManager:ReleaseParticleIndex(self.nPreviewFX)
    self.nPreviewFX = nil
  end

  local caster = self:GetCaster()
  local radius = self:GetSpecialValueFor("radius")
  local damage = self:GetSpecialValueFor("damage")

  local caster_location = caster:GetAbsOrigin()

  local knockback_table = {
    should_stun = 1,
    knockback_duration = 1.0,
    duration = 1.0,
    knockback_distance = radius,
    knockback_height = 100,
    center_x = caster_location.x,
    center_y = caster_location.y,
    center_z = caster_location.z
  }

  -- Find enemies in a radius
  local enemies = FindUnitsInRadius(
    caster:GetTeamNumber(),
    caster_location,
    nil,
    radius,
    DOTA_UNIT_TARGET_TEAM_ENEMY,
    bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC),
    DOTA_UNIT_TARGET_FLAG_NONE,
    FIND_ANY_ORDER,
    false
  )

  -- Find wards in a double radius
  local wards = FindUnitsInRadius(
    caster:GetTeamNumber(),
    caster_location,
    nil,
    2*radius,
    DOTA_UNIT_TARGET_TEAM_ENEMY,
    DOTA_UNIT_TARGET_OTHER,
    DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
    FIND_ANY_ORDER,
    false
  )

  for _, enemy in pairs(enemies) do
    if enemy and not enemy:IsNull() and not enemy:IsMagicImmune() and not enemy:IsInvulnerable() then
      -- Purge - Offensive Basic Dispel - removes buffs
      enemy:Purge(true, false, false, false, false)
      -- Apply knockback
      enemy:AddNewModifier(caster, self, "modifier_knockback", knockback_table)
      -- Apply Damage
      local damage_table = {}
      damage_table.victim = enemy
      damage_table.attacker = caster
      damage_table.damage = damage
      damage_table.damage_type = DAMAGE_TYPE_PHYSICAL
      damage_table.damage_flags = DOTA_DAMAGE_FLAG_BYPASSES_BLOCK
      damage_table.ability = self
      ApplyDamage(damage_table)
    end
  end

  -- Kill wards
  for _, ward in pairs(wards) do
    if ward and not ward:IsNull() then
      if ward.HasModifier and ward.IsInvulnerable then
        if not ward:HasModifier("modifier_item_buff_ward") and not ward:IsInvulnerable() then
          ward:Kill(self, caster)
        end
      end
    end
  end

  -- Destroy Trees
  GridNav:DestroyTreesAroundPoint(caster_location, radius, true)

  -- Sound
  EmitSoundOnLocationWithCaster(caster_location, "OgreTank.GroundSmash", caster)

  -- Particle
  local smashParticle = ParticleManager:CreateParticle("particles/test_particle/ogre_melee_smash.vpcf", PATTACH_WORLDORIGIN, caster)
  ParticleManager:SetParticleControl(smashParticle, 0, caster_location)
  ParticleManager:SetParticleControl(smashParticle, 1, Vector(radius, radius, radius))
  ParticleManager:ReleaseParticleIndex(smashParticle)
end
