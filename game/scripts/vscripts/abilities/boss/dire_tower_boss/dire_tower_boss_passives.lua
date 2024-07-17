dire_tower_boss_passives = class(AbilityBaseClass)

LinkLuaModifier("modifier_dire_tower_boss_passives", "abilities/boss/dire_tower_boss/dire_tower_boss_passives.lua", LUA_MODIFIER_MOTION_NONE)

function dire_tower_boss_passives:GetIntrinsicModifierName()
  return "modifier_dire_tower_boss_passives"
end

function dire_tower_boss_passives:IsStealable()
  return false
end

function dire_tower_boss_passives:ProcMagicStick()
  return false
end

---------------------------------------------------------------------------------------------------

modifier_dire_tower_boss_passives = class(ModifierBaseClass)

function modifier_dire_tower_boss_passives:IsHidden()
  return true
end

function modifier_dire_tower_boss_passives:IsDebuff()
  return false
end

function modifier_dire_tower_boss_passives:IsPurgable()
  return false
end

function modifier_dire_tower_boss_passives:GetPriority()
  return MODIFIER_PRIORITY_SUPER_ULTRA + 20000
end

function modifier_dire_tower_boss_passives:CheckState()
  return {
    [MODIFIER_STATE_ROOTED] = true,
    [MODIFIER_STATE_FROZEN] = true,
    [MODIFIER_STATE_CANNOT_BE_MOTION_CONTROLLED] = true,
  }
end
