LinkLuaModifier("modifier_boss_charger_super_armor", "abilities/boss/charger/boss_charger_super_armor.lua", LUA_MODIFIER_MOTION_NONE)

boss_charger_super_armor = class(AbilityBaseClass)

function boss_charger_super_armor:GetIntrinsicModifierName()
  return "modifier_boss_charger_super_armor"
end

--------------------------------------------------------------------------------

modifier_boss_charger_super_armor = class(ModifierBaseClass)

function modifier_boss_charger_super_armor:IsHidden()
  return self:GetParent():HasModifier("modifier_boss_charger_pillar_debuff")
end

function modifier_boss_charger_super_armor:IsDebuff()
  return false
end

function modifier_boss_charger_super_armor:IsPurgable()
  return false
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
    MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
    MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
    --MODIFIER_PROPERTY_TOTAL_CONSTANT_BLOCK,
  }
end

--[[
if IsServer() then
  function modifier_boss_charger_super_armor:GetModifierTotal_ConstantBlock(event)
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
end
]]

function modifier_boss_charger_super_armor:GetModifierPhysicalArmorBonus()
  local parent = self:GetParent()
  if not parent:HasModifier("modifier_boss_charger_pillar_debuff") then
    return self:GetAbility():GetSpecialValueFor("bonus_armor")
  end
  return 0
end

function modifier_boss_charger_super_armor:GetModifierMagicalResistanceBonus()
  local parent = self:GetParent()
  if not parent:HasModifier("modifier_boss_charger_pillar_debuff") then
    return self:GetAbility():GetSpecialValueFor("bonus_magic_resistance")
  end
  return 0
end

function modifier_boss_charger_super_armor:CheckState()
  local parent = self:GetParent()
  local state = {
    [MODIFIER_STATE_FROZEN] = false,
    [MODIFIER_STATE_FEARED] = false,
    [MODIFIER_STATE_CANNOT_BE_MOTION_CONTROLLED] = true, -- does not work for some forced movement spells (e.g. CK Reality Rift)
    [MODIFIER_STATE_ROOTED] = false,
    [MODIFIER_STATE_TETHERED] = false,
    [MODIFIER_STATE_UNSLOWABLE] = true,
    --[MODIFIER_STATE_STUNNED] = false, -- cannot be used because Charger needs to be stunned when hitting a tower
    --[MODIFIER_STATE_DEBUFF_IMMUNE] = true, -- cannot be used because Charger needs to be stunned when hitting a tower
    --[MODIFIER_STATE_MAGIC_IMMUNE] = true, -- cannot be used because we want to allow using most spells and items on Charger
  }

  if not parent:HasModifier("modifier_boss_charger_pillar_debuff") then
    state[MODIFIER_STATE_HEXED] = false
    state[MODIFIER_STATE_SILENCED] = false
  end

  return state
end

function modifier_boss_charger_super_armor:GetPriority()
  return MODIFIER_PRIORITY_SUPER_ULTRA + 10000
end
