LinkLuaModifier("modifier_clinkz_strafe_oaa", "abilities/oaa_clinkz_strafe.lua", LUA_MODIFIER_MOTION_NONE)

clinkz_strafe_oaa = class( AbilityBaseClass )

--------------------------------------------------------------------------------

function clinkz_strafe_oaa:OnHeroCalculateStatBonus()
  local caster = self:GetCaster()

  if caster:HasShardOAA() then
    self:SetHidden(false)
    if self:GetLevel() <= 0 then
      self:SetLevel(1)
    end
  else
    self:SetHidden(true)
    --self:SetLevel(0)
  end
end

function clinkz_strafe_oaa:OnSpellStart()
  local caster = self:GetCaster()
  local duration = self:GetSpecialValueFor("duration")

  caster:AddNewModifier(caster, self, "modifier_clinkz_strafe_oaa", { duration = duration } )

  caster:EmitSound("Hero_Clinkz.Strafe")
end

function clinkz_strafe_oaa:IsStealable()
  return true
end

---------------------------------------------------------------------------------------------------

modifier_clinkz_strafe_oaa = class(ModifierBaseClass)

function modifier_clinkz_strafe_oaa:IsHidden()
  return false
end

function modifier_clinkz_strafe_oaa:IsPurgable()
  return true
end

function modifier_clinkz_strafe_oaa:IsDebuff()
  return false
end

function modifier_clinkz_strafe_oaa:OnCreated(event)
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.bonus_evasion = ability:GetSpecialValueFor("bonus_evasion")
    self.bonus_attack_speed = ability:GetSpecialValueFor("bonus_attack_speed") --or ability:GetSpecialValueFor("attack_speed_bonus_pct")
  else
    self.bonus_evasion = 25
    self.bonus_attack_speed = 200
  end
end

function modifier_clinkz_strafe_oaa:OnRefresh(event)
  self:OnCreated(event)
end

function modifier_clinkz_strafe_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
    MODIFIER_PROPERTY_EVASION_CONSTANT,
  }
end

function modifier_clinkz_strafe_oaa:GetModifierAttackSpeedBonus_Constant()
  return self.bonus_attack_speed or self:GetAbility():GetSpecialValueFor("bonus_attack_speed")
end

function modifier_clinkz_strafe_oaa:GetModifierEvasion_Constant()
  return self.bonus_evasion or self:GetAbility():GetSpecialValueFor("bonus_evasion")
end

function modifier_clinkz_strafe_oaa:GetEffectName()
  return "particles/units/heroes/hero_clinkz/clinkz_strafe_fire.vpcf"
end

function modifier_clinkz_strafe_oaa:GetEffectAttachType()
  return PATTACH_ABSORIGIN_FOLLOW
end
