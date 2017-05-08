LinkLuaModifier("modifier_boss_shielder_shield", "abilities/shielder/boss_shielder_shield.lua", LUA_MODIFIER_MOTION_NONE) --- BATHS HEAVY IMPORTED

modifier_boss_shielder_shielded_buff = class({})

function modifier_boss_shielder_shielded_buff:DeclareFunctions()
  return
  {
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
    local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_spectre/spectre_desolate.vpcf", PATTACH_POINT_FOLLOW, target)
    ParticleManager:SetParticleControl(particle, 0, target:GetAbsOrigin())
    ParticleManager:SetParticleControl(particle, 1, Vector(nil,0,0))
    return 0 - self:GetAbility():GetSpecialValueFor("percent_damage_reduce")
  end

  return 0
end
