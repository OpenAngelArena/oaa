kobold_foreman_warcry_oaa = class(AbilityBaseClass)

LinkLuaModifier("modifier_kobold_foreman_warcry_oaa_buff", "abilities/neutrals/oaa_kobold_foreman_warcry.lua", LUA_MODIFIER_MOTION_NONE)

function kobold_foreman_warcry_oaa:OnSpellStart()
  local caster = self:GetCaster()
  local radius = self:GetSpecialValueFor("radius")
  local duration = self:GetSpecialValueFor("buff_duration")

  local allies = FindUnitsInRadius(
    caster:GetTeamNumber(),
    caster:GetOrigin(),
    nil,
    radius,
    DOTA_UNIT_TARGET_TEAM_FRIENDLY,
    bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC),
    bit.bor(DOTA_UNIT_TARGET_FLAG_INVULNERABLE, DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD),
    FIND_ANY_ORDER,
    false
  )

  for _,ally in pairs(allies) do
    -- Apply a buff
    if ally then
      ally:AddNewModifier(caster, self, "modifier_kobold_foreman_warcry_oaa_buff", { duration = duration } )
    end
  end
end

--------------------------------------------------------------------------------

modifier_kobold_foreman_warcry_oaa_buff = class(ModifierBaseClass)

function modifier_kobold_foreman_warcry_oaa_buff:IsHidden()
  return false
end

function modifier_kobold_foreman_warcry_oaa_buff:IsDebuff()
  return false
end

function modifier_kobold_foreman_warcry_oaa_buff:IsPurgable()
  return true
end

function modifier_kobold_foreman_warcry_oaa_buff:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
    MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
  }
  return funcs
end

function modifier_kobold_foreman_warcry_oaa_buff:GetModifierPreAttack_BonusDamage()
  return self:GetAbility():GetSpecialValueFor("bonus_attack_damage")
end

function modifier_kobold_foreman_warcry_oaa_buff:GetModifierAttackSpeedBonus_Constant()
  return self:GetAbility():GetSpecialValueFor("bonus_attack_speed")
end

function modifier_kobold_foreman_warcry_oaa_buff:GetEffectName()
  return "particles/units/heroes/hero_lycan/lycan_howl_buff.vpcf"
end

function modifier_kobold_foreman_warcry_oaa_buff:GetEffectAttachType()
  return PATTACH_OVERHEAD_FOLLOW
end
