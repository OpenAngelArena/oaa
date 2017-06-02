LinkLuaModifier( "modifier_creep_assist_gold_aura", "items/farming/modifier_creep_assist_gold.lua", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------

modifier_creep_assist_gold = class({})

function modifier_creep_assist_gold:IsHidden()
  return true
end

function modifier_creep_assist_gold:IsPurgable()
  return false
end

--------------------------------------------------------------------------
-- aura stuff

function modifier_creep_assist_gold:IsAura()
  return true
end

function modifier_creep_assist_gold:GetAuraDuration()
  return self:GetAbility():GetSpecialValueFor("assist_stickiness")
end

function modifier_creep_assist_gold:GetAuraSearchType()
  return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
end

function modifier_creep_assist_gold:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_creep_assist_gold:GetAuraRadius()
  return self:GetAbility():GetSpecialValueFor("assist_radius")
end

function modifier_creep_assist_gold:GetModifierAura()
  return "modifier_creep_assist_gold_aura"
end

function modifier_creep_assist_gold:GetAuraEntityReject(entity)
  if entity:IsRealHero() then
    return false
  end
  return true
end

--------------------------------------------------------------------------

modifier_creep_assist_gold_aura = class({})

function modifier_creep_assist_gold_aura:IsHidden()
  return true
end

function modifier_creep_assist_gold_aura:IsPurgable()
  return false
end

function modifier_creep_assist_gold_aura:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_creep_assist_gold_aura:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_DEATH
  }
end

function modifier_creep_assist_gold_aura:OnDeath(keys)
  if keys.attacker ~= self:GetParent() or self:GetParent() == self:GetCaster()  then
    return
  end
  --[[
[   VScript              ]: process_procs: false
[   VScript              ]: order_type: 0
[   VScript              ]: issuer_player_index: 1
[   VScript              ]: fail_type: 32767
[   VScript              ]: damage_category: 0
[   VScript              ]: reincarnate: false
[   VScript              ]: damage: 0
[   VScript              ]: ignore_invis: false
[   VScript              ]: attacker: table: 0x006bc3d0
[   VScript              ]: ranged_attack: false
[   VScript              ]: record: 72
[   VScript              ]: unit: table: 0x00635458
[   VScript              ]: do_not_consume: false
[   VScript              ]: damage_type: 1053999872
[   VScript              ]: activity: -1
[   VScript              ]: heart_regen_applied: false
[   VScript              ]: diffusal_applied: false
[   VScript              ]: no_attack_cooldown: false
[   VScript              ]: damage_flags: 0
[   VScript              ]: original_damage: 0
[   VScript              ]: gain: 0
[   VScript              ]: cost: 0
[   VScript              ]: basher_tested: false
[   VScript              ]: distance: 0
  int ModifyGold(int playerID, int goldAmmt, bool reliable, int nReason)
]]
  local bounty = keys.unit:GetGoldBounty() * self:GetAbility():GetSpecialValueFor("assist_percent") / 100
  local caster = self:GetCaster() -- caster is hero with boots,

  PlayerResource:ModifyGold(caster:GetPlayerID(), bounty, true, DOTA_ModifyGold_SharedGold)
end
