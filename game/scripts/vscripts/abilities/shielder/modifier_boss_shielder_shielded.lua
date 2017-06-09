LinkLuaModifier("modifier_boss_shielder_shield", "abilities/shielder/boss_shielder_shield.lua", LUA_MODIFIER_MOTION_NONE) --- BATHS HEAVY IMPORTED

modifier_boss_shielder_shielded_buff = class(ModifierBaseClass)

function modifier_boss_shielder_shielded_buff:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE
  }
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
attacker: table: 0x00636d38
ranged_attack: false
record: 5
activity: -1
do_not_consume: false
damage_type: 4
heart_regen_applied: false
diffusal_applied: false
no_attack_cooldown: false
cost: 0
inflictor: table: 0x004bfe30
damage_flags: 0
original_damage: 650
ignore_invis: false
damage: 650
basher_tested: false
target: table: 0x00524320
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
    local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_spectre/spectre_desolate.vpcf", PATTACH_POINT_FOLLOW, target)
    ParticleManager:SetParticleControl(particle, 0, target:GetAbsOrigin())
    ParticleManager:SetParticleControl(particle, 1, Vector(nil,0,0))
    return 0 - self:GetAbility():GetSpecialValueFor("percent_damage_reduce")
  end

  return 0
end
