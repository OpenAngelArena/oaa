modifier_boss_shielder_shielded_buff = class(ModifierBaseClass)

function modifier_boss_shielder_shielded_buff:IsHidden()
  return true
end

function modifier_boss_shielder_shielded_buff:IsDebuff()
  return false
end

function modifier_boss_shielder_shielded_buff:IsPurgable()
  return false
end

function modifier_boss_shielder_shielded_buff:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_TOTAL_CONSTANT_BLOCK,
    --MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
    MODIFIER_EVENT_ON_DEATH
  }
end

function modifier_boss_shielder_shielded_buff:CreateParticle(level)
  local particleIndexKey = "particlePhase" .. level
  if not self[particleIndexKey] then
    local caster = self:GetCaster()
    local particleName = "particles/shielder/hex_shield_" .. level .. ".vpcf"
    self[particleIndexKey] = ParticleManager:CreateParticle(particleName, PATTACH_ABSORIGIN_FOLLOW, caster)
  end
end

function modifier_boss_shielder_shielded_buff:DestroyParticle(level)
  local particleIndexKey = "particlePhase" .. level
  if self[particleIndexKey] then
    ParticleManager:DestroyParticle(self[particleIndexKey], false)
    ParticleManager:ReleaseParticleIndex(self[particleIndexKey])
    self[particleIndexKey] = nil
  end
end

function modifier_boss_shielder_shielded_buff:OnCreated()
  if IsServer() then
    self:GetAbility().intrinsicMod = self
    self:CreateParticle(1)
  end
end

function modifier_boss_shielder_shielded_buff:OnRefresh()
  if IsServer() then
    self:GetAbility().intrinsicMod = self
  end
end

function modifier_boss_shielder_shielded_buff:OnPhaseChanged(level)
  local levelsToCreate, levelsToDestroy = span(partial(op.ge, level), range(3))
  foreach(partial(self.DestroyParticle, self), levelsToDestroy)
  foreach(partial(self.CreateParticle, self), levelsToCreate)
end

if IsServer() then
  function modifier_boss_shielder_shielded_buff:OnDeath(keys)
    if keys.unit == self:GetParent() then
      foreach(partial(self.DestroyParticle, self), range(3))
    end
  end
end

function modifier_boss_shielder_shielded_buff:GetModifierTotal_ConstantBlock(keys)
  local parent = self:GetParent()
  local ability = self:GetAbility()

  local attacker = keys.attacker
  local damage = keys.damage
  local damage_type = keys.damage_type
  local damage_flags = keys.damage_flags

  if attacker == parent then -- boss degen
    return 0
  end

  if parent:PassivesDisabled() or parent:IsIllusion() then
    return 0
  end

  if keys.inflictor then
    local damaging_ability = keys.inflictor
    -- Prevent Shielder returning damage to another Shielder
    if damaging_ability:GetAbilityName() == ability:GetAbilityName() then
      return 0
    end
  end

  local attackOrigin = attacker:GetAbsOrigin()
  local parentOrigin = parent:GetAbsOrigin()
  local attackDirection = (attackOrigin - parentOrigin):Normalized()
  local parentFacing = (parent:GetForwardVector()):Normalized()
  local angleCos = parentFacing:Dot(attackDirection)

  if angleCos > ability:GetSpecialValueFor("shield_width") then
    -- Return Damage
    local damage_return = damage * (ability:GetSpecialValueFor("damage_return_pct")) / 100
    local damage_return_flags = bit.bor(damage_flags, DOTA_DAMAGE_FLAG_REFLECTION)
    if not attacker:IsMagicImmune() and not attacker:IsDebuffImmune() and not Duels:IsActive() then
      ApplyDamage({
        victim = attacker,
        attacker = parent,
        damage = damage_return,
        damage_type = damage_type,
        damage_flags = damage_return_flags,
        ability = ability
      })
    end

    local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_spectre/spectre_desolate.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
    ParticleManager:SetParticleControl(particle, 0, parent:GetAbsOrigin())
    --ParticleManager:SetParticleControlEnt(particle, 0, parent, PATTACH_POINT_FOLLOW, "attach_hitloc", Vector(0,0,0), true)
    --ParticleManager:SetParticleControl(particle, 4, parent:GetOrigin() )
    --ParticleManager:SetParticleControlForward(particle, 0, (parent:GetOrigin()-attacker:GetOrigin()):Normalized())
    ParticleManager:ReleaseParticleIndex(particle)

    parent:EmitSound("Hero_Mars.Shield.Block")

    return damage * (ability:GetSpecialValueFor("damage_reduction_pct")) / 100
  end

  return 0
end

--[[
function modifier_boss_shielder_shielded_buff:GetModifierIncomingDamage_Percentage(keys)
  local parent = self:GetParent()
  local attacker = keys.attacker
  local damage = keys.damage
  local damage_type = keys.damage_type
  local damage_flags = keys.damage_flags
  local ability = self:GetAbility()

  local attackOrigin = attacker:GetAbsOrigin()
  local parentOrigin = parent:GetAbsOrigin()
  local attackDirection = (attackOrigin - parentOrigin):Normalized()
  local parentFacing = (parent:GetForwardVector()):Normalized()
  local angleCos = parentFacing:Dot(attackDirection)

  if (angleCos > (ability:GetSpecialValueFor("shield_width"))) then
    if not bit.band(damage_flags, DOTA_DAMAGE_FLAG_REFLECTION) == DOTA_DAMAGE_FLAG_REFLECTION then
      local damage_return = damage * (ability:GetSpecialValueFor("damage_return_pct"))
      damage_flags = bit.bor(damage_flags, DOTA_DAMAGE_FLAG_REFLECTION)
      ApplyDamage({
        victim = attacker,
        attacker = parent,
        damage = damage_return,
        damage_type = damage_type,
        damage_flags = damage_flags,
        ability = ability
      })
    end

    local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_spectre/spectre_desolate.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
    ParticleManager:SetParticleControl(particle, 0, parent:GetAbsOrigin())
    ParticleManager:SetParticleControl(particle, 1, Vector(nil, 0, 0))
    ParticleManager:ReleaseParticleIndex(particle)

    return 0 - ability:GetSpecialValueFor("damage_reduction_pct")
  end

  return 0
end
]]
