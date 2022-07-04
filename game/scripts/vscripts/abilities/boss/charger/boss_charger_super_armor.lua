LinkLuaModifier("modifier_boss_charger_super_armor", "abilities/boss/charger/boss_charger_super_armor.lua", LUA_MODIFIER_MOTION_NONE)

boss_charger_super_armor = class(AbilityBaseClass)

function boss_charger_super_armor:GetIntrinsicModifierName()
  return "modifier_boss_charger_super_armor"
end

--------------------------------------------------------------------------------

modifier_boss_charger_super_armor = class(ModifierBaseClass)

function modifier_boss_charger_super_armor:IsPurgable()
  return false
end

function modifier_boss_charger_super_armor:IsHidden()
  return self:GetParent():HasModifier("modifier_boss_charger_pillar_debuff")
end

if IsServer() then
  function modifier_boss_charger_super_armor:OnCreated(keys)
    local ability = self:GetAbility()
    local parent = self:GetParent()
    ability.shieldParticleName = "particles/charger/charger_super_armor_shield.vpcf"
    ability.shieldParticle = ParticleManager:CreateParticle(ability.shieldParticleName, PATTACH_OVERHEAD_FOLLOW, parent)
    -- shieldParticle is released and destroyed when modifier_boss_charger_pillar_debuff is created
  end
end

function modifier_boss_charger_super_armor:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_TOTAL_CONSTANT_BLOCK
  }
end

function modifier_boss_charger_super_armor:GetModifierTotal_ConstantBlock(event)
  if not IsServer() then
    return
  end

  local parent = self:GetParent()

  if parent:HasModifier("modifier_boss_charger_pillar_debuff") then
    return 0
  end

  local tier = parent.BossTier or 2
  local aggro_factor = BOSS_AGRO_FACTOR or 15
  local current_hp_pct = parent:GetHealth() / parent:GetMaxHealth()
  local aggro_hp_pct = math.min(1 - ((tier * aggro_factor) / parent:GetMaxHealth()), 99/100)

  if current_hp_pct >= aggro_hp_pct then
    return 0
  end

  local damageReduction = self:GetAbility():GetSpecialValueFor("percent_damage_reduce")
  local blockAmount = event.damage * damageReduction / 100

  if blockAmount > 0 then
    -- Visual effect (TODO: add unique visual effect)
    SendOverheadEventMessage(nil, OVERHEAD_ALERT_BLOCK, parent, blockAmount, nil)
  end

  return blockAmount
end

function modifier_boss_charger_super_armor:GetPriority()
  return MODIFIER_PRIORITY_SUPER_ULTRA + 10000
end

function modifier_boss_charger_super_armor:CheckState()
  local parent = self:GetParent()
  local state = {
    [MODIFIER_STATE_FROZEN] = false,
    [MODIFIER_STATE_FEARED] = false,
    [MODIFIER_STATE_CANNOT_BE_MOTION_CONTROLLED] = true,
  }

  if not parent:HasModifier("modifier_boss_charger_pillar_debuff") then
    state[MODIFIER_STATE_HEXED] = false
    state[MODIFIER_STATE_SILENCED] = false
  end

  return state
end
