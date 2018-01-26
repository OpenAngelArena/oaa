LinkLuaModifier("modifier_boss_charger_super_armor", "abilities/charger/boss_charger_super_armor.lua", LUA_MODIFIER_MOTION_NONE)

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
  end
end

function modifier_boss_charger_super_armor:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_TOTAL_CONSTANT_BLOCK
  }
end

function modifier_boss_charger_super_armor:GetModifierTotal_ConstantBlock(keys)
  if self:GetParent():HasModifier("modifier_boss_charger_pillar_debuff") then
    return
  end
  local damageReduction = self:GetAbility():GetSpecialValueFor("percent_damage_reduce")
  return math.floor(keys.damage * damageReduction / 100)
end
