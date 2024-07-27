LinkLuaModifier( "modifier_dire_tower_boss_glyph", "abilities/boss/dire_tower_boss/dire_tower_boss_glyph.lua", LUA_MODIFIER_MOTION_NONE )

dire_tower_boss_glyph = class(AbilityBaseClass)

-- function dire_tower_boss_glyph:Precache(context)
  -- PrecacheResource("particle", "particles/items_fx/backdoor_protection_tube.vpcf", context)
  -- PrecacheResource("particle", "particles/items_fx/glyph.vpcf", context)
-- end

function dire_tower_boss_glyph:OnSpellStart()
  local caster = self:GetCaster()

  -- Buff
  caster:AddNewModifier( caster, self, "modifier_dire_tower_boss_glyph", { duration = self:GetSpecialValueFor( "glyph_duration" ) } )

  -- Sound
  caster:EmitSound("Dire_Tower_Boss.Glyph.Cast")
end

---------------------------------------------------------------------------------------------------

modifier_dire_tower_boss_glyph = class(ModifierBaseClass)

function modifier_dire_tower_boss_glyph:IsPurgable()
  return false
end

function modifier_dire_tower_boss_glyph:IsHidden() -- needs tooltip
  return false
end

function modifier_dire_tower_boss_glyph:OnCreated()
  local ability = self:GetAbility()
  if IsServer() then
    self.count = ability:GetSpecialValueFor("splitshot_units")
    self.bonus_range = ability:GetSpecialValueFor("splitshot_bonus_range")
  end
  self.attack_speed = ability:GetSpecialValueFor("bonus_attack_speed")

  if IsServer() then
    local parent = self:GetParent()
    local particle = ParticleManager:CreateParticle("particles/items_fx/glyph.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
    ParticleManager:SetParticleControl(particle, 0, parent:GetAbsOrigin())
    ParticleManager:SetParticleControl(particle, 1, Vector(150,1,1))
    self:AddParticle(particle, false, false, -1, false, false)
  end
end

function modifier_dire_tower_boss_glyph:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
    MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
    MODIFIER_EVENT_ON_ATTACK,
    MODIFIER_EVENT_ON_TAKEDAMAGE,
  }
end

function modifier_dire_tower_boss_glyph:GetModifierIncomingDamage_Percentage()
  return -200
end

function modifier_dire_tower_boss_glyph:GetModifierAttackSpeedBonus_Constant()
  return self.attack_speed
end

if IsServer() then
  function modifier_dire_tower_boss_glyph:OnAttack(event)
    local parent = self:GetParent()
    local attacker = event.attacker

    -- Check if attacker exists
    if not attacker or attacker:IsNull() then
      return
    end

    -- Check if attacker has this modifier
    if attacker ~= parent then
      return
    end

    -- Prevent looping
    if event.no_attack_cooldown then
      return
    end

    self:SplitShot(event.target)
  end

  function modifier_dire_tower_boss_glyph:SplitShot(target)
    local parent = self:GetParent()
    local radius = parent:GetAttackRange() + self.bonus_range
    local enemies = FindUnitsInRadius(
      parent:GetTeamNumber(),
      parent:GetOrigin(),
      nil,
      radius,
      DOTA_UNIT_TARGET_TEAM_ENEMY,
      DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
      DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
      FIND_ANY_ORDER,
      false
    )

    local useCastAttackOrb = true
    local processProcs = true
    local skipCooldown = true
    local ignoreInvis = true
    local useProjectile = true
    local fakeAttack = false
    local neverMiss = false

    local count = 0
    for _, enemy in pairs(enemies) do
      if enemy and enemy ~= target then

        parent:PerformAttack(enemy, useCastAttackOrb, processProcs, skipCooldown, ignoreInvis, useProjectile, fakeAttack, neverMiss)

        count = count + 1
        if count >= self.count then break end
      end
    end
  end

  function modifier_dire_tower_boss_glyph:OnTakeDamage(event)
    local parent = self:GetParent()
    local attacker = event.attacker
    local victim = event.unit
    local inflictor = event.inflictor

    if not attacker or attacker:IsNull() or not victim or victim:IsNull() then
      return
    end

    -- Check if damaged entity is not this boss
    if victim ~= parent then
      return
    end

    -- Check if it's self damage
    if attacker == victim then
      return
    end

    -- Check if it's accidental damage
    if parent:CheckForAccidentalDamage(inflictor) then
      return
    end

    local particle_cast = "particles/items_fx/backdoor_protection_tube.vpcf"
    local direction = (parent:GetOrigin()-attacker:GetOrigin()):Normalized()
    local size = 150

    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, parent)
    ParticleManager:SetParticleControl( effect_cast, 1, Vector( size, 0, 0 ) )
    ParticleManager:SetParticleControlForward( effect_cast, 2, direction )
    ParticleManager:ReleaseParticleIndex( effect_cast )

    parent:EmitSound("Dire_Tower_Boss.Glyph.Protected")
  end
end
