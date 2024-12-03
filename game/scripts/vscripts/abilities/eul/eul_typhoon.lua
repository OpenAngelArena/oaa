
eul_typhoon_oaa = class(AbilityBaseClass)

function eul_typhoon_oaa:GetCastRange(location, target)
  return self:GetSpecialValueFor("radius")
end

function eul_typhoon_oaa:GetAOERadius()
  return self:GetSpecialValueFor("radius")
end

---------------------------------------------------------------------------------------------------

modifier_eul_typhoon_debuff = class(ModifierBaseClass)

function modifier_eul_typhoon_debuff:GetEffectName()
  return "particles/units/heroes/hero_windrunner/windrunner_windrun_slow.vpcf"
end

function modifier_eul_typhoon_debuff:GetEffectAttachType()
  return PATTACH_ABSORIGIN_FOLLOW
end
