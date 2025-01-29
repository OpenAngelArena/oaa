LinkLuaModifier("modifier_ghost_curse_oaa_debuff", "abilities/neutrals/oaa_ghost_curse.lua", LUA_MODIFIER_MOTION_NONE)

ghost_curse_oaa = class(AbilityBaseClass)

function ghost_curse_oaa:OnSpellStart()
  local caster = self:GetCaster()
  local target = self:GetCursorTarget()

  if not target then
    return
  end

  -- Don't do anything if target has Linken's effect or it's spell-immune
  if target:TriggerSpellAbsorb(self) or target:IsMagicImmune() then
    return
  end

  caster:AddNewModifier(target, self, "modifier_ghost_curse_oaa_debuff", {duration = self:GetSpecialValueFor("duration")})
end

-----------------------------------------------------------------------------------------------------------------------------------------------------

modifier_ghost_curse_oaa_debuff = class({})

function modifier_ghost_curse_oaa_debuff:IsHidden()
  return false
end

function modifier_ghost_curse_oaa_debuff:IsDebuff()
  return true
end

function modifier_ghost_curse_oaa_debuff:IsPurgable()
  return true
end

function modifier_ghost_curse_oaa_debuff:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MISS_PERCENTAGE,
  }
end

function modifier_ghost_curse_oaa_debuff:GetModifierMiss_Percentage()
  local ability = self:GetAbility()
  if ability then
    return ability:GetSpecialValueFor("miss_chance")
  end
end

function modifier_ghost_curse_oaa_debuff:GetEffectName()
  return "particles/econ/items/templar_assassin/templar_assassin_focal/templar_meld_focal_overhead.vpcf"
end

function modifier_ghost_curse_oaa_debuff:GetEffectAttachType()
  return PATTACH_OVERHEAD_FOLLOW
end


