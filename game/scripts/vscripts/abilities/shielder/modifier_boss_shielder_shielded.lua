modifier_boss_shielder_shielded_buff = class(ModifierBaseClass)

function modifier_boss_shielder_shielded_buff:DeclareFunctions()
  return
  {
    MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
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

function modifier_boss_shielder_shielded_buff:OnDeath(keys)
  if keys.unit == self:GetParent() then
    foreach(partial(self.DestroyParticle, self), range(3))
  end
end

function modifier_boss_shielder_shielded_buff:IsHidden()
  return true
end

function modifier_boss_shielder_shielded_buff:IsPurgable()
  return false
end

function modifier_boss_shielder_shielded_buff:GetModifierIncomingDamage_Percentage(keys)
 --[[
process_procs: true
order_type: 0
issuer_player_index: 1982289334
fail_type: 0
damage_category: 0
reincarnate: false
distance: 0
gain: 98.332176208496
attacker: hScript
ranged_attack: false
record: 5
activity: -1
do_not_consume: false
damage_type: 4
heart_regen_applied: false
diffusal_applied: false
no_attack_cooldown: false
cost: 0
inflictor: hScript
damage_flags: 0
original_damage: 650
ignore_invis: false
damage: 650
basher_tested: false
target: hScript
]]
--  for k,v in pairs(keys) do
--    print(k .. ': ' .. tostring(v))
--  end
  local parent = self:GetParent()
  local attacker = keys.attacker
  local damage = keys.damage
  local damage_type = keys.damage_type
  local damage_flags = keys.damage_flags
  local ability = self:GetAbility()

  --if hero and hero:IsRealHero and hero:IsRealHero() then
  local attackOrigin = attacker:GetAbsOrigin()
  local parentOrigin = parent:GetAbsOrigin()
  local attackDirection = (attackOrigin - parentOrigin):Normalized()
  local parentFacing = (parent:GetForwardVector()):Normalized()
  local angleCos = parentFacing:Dot(attackDirection)
  --end
  --DebugPrint(angleCos .. ' : ' .. self:GetAbility():GetSpecialValueFor("sheild_width"))
  if (angleCos > (self:GetAbility():GetSpecialValueFor("shield_width"))) then
    -- Return Damage

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
