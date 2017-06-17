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
[   VScript              ]: process_procs: true
[   VScript              ]: order_type: 0
[   VScript              ]: issuer_player_index: 1982289334
[   VScript              ]: fail_type: 0
[   VScript              ]: damage_category: 0
[   VScript              ]: reincarnate: false
[   VScript              ]: distance: 0
[   VScript              ]: gain: 98.332176208496
[   VScript              ]: attacker: table: 0x00636d38
[   VScript              ]: ranged_attack: false
[   VScript              ]: record: 5
[   VScript              ]: activity: -1
[   VScript              ]: do_not_consume: false
[   VScript              ]: damage_type: 4
[   VScript              ]: heart_regen_applied: false
[   VScript              ]: diffusal_applied: false
[   VScript              ]: no_attack_cooldown: false
[   VScript              ]: cost: 0
[   VScript              ]: inflictor: table: 0x004bfe30
[   VScript              ]: damage_flags: 0
[   VScript              ]: original_damage: 650
[   VScript              ]: ignore_invis: false
[   VScript              ]: damage: 650
[   VScript              ]: basher_tested: false
[   VScript              ]: target: table: 0x00524320
]]
--  for k,v in pairs(keys) do
--    print(k .. ': ' .. tostring(v))
--  end
  local parent = self:GetParent()
  local hero = keys.attacker
  local angleCos = 0

  --if hero and hero:IsRealHero and hero:IsRealHero() then
  local attackOrigin = hero:GetAbsOrigin()
  local parentOrigin = parent:GetAbsOrigin()
  local attackDirection = (attackOrigin - parentOrigin):Normalized()
  local parentFacing = (parent:GetForwardVector()):Normalized()
  angleCos = parentFacing:Dot(attackDirection)
  --end
  --DebugPrint(angleCos .. ' : ' .. self:GetAbility():GetSpecialValueFor("sheild_width"))
  if (angleCos > (self:GetAbility():GetSpecialValueFor("sheild_width"))) then
    local target = self:GetParent()
    local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_spectre/spectre_desolate.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
    ParticleManager:SetParticleControl(particle, 0, target:GetAbsOrigin())
    ParticleManager:SetParticleControl(particle, 1, Vector(nil,0,0))
    return 0 - self:GetAbility():GetSpecialValueFor("percent_damage_reduce")
  end

  return 0
end
