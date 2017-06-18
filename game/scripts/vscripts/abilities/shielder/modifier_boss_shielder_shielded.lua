LinkLuaModifier("modifier_boss_shielder_shield", "abilities/shielder/boss_shielder_shield.lua", LUA_MODIFIER_MOTION_NONE) --- BATHS HEAVY IMPORTED

modifier_boss_shielder_shielded_buff = class({})

function modifier_boss_shielder_shielded_buff:DeclareFunctions()
  return
  {
    MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE
  }
end

function modifier_boss_shielder_shielded_buff:OnCreated()
  local caster = self:GetCaster()
  local particle = ParticleManager:CreateParticle("particles/shielder/hex_shield_1.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
  ParticleManager:SetParticleControl(particle, 0, caster:GetAbsOrigin())
  ParticleManager:SetParticleControl(particle, 1, caster:GetAbsOrigin())
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

    if not bit.band(kv.damage_flags, DOTA_DAMAGE_FLAG_REFLECTION) == DOTA_DAMAGE_FLAG_REFLECTION then
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

    return 0 - ability:GetSpecialValueFor("damage_reduction_pct")
  end

  return 0
end
