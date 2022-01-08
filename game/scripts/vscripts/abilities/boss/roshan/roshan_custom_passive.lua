LinkLuaModifier("modifier_roshan_custom_passive", "abilities/boss/roshan/roshan_custom_passive.lua", LUA_MODIFIER_MOTION_NONE)

roshan_custom_passive = class(AbilityBaseClass)

function roshan_custom_passive:GetIntrinsicModifierName()
  return "modifier_roshan_custom_passive"
end

---------------------------------------------------------------------------------------------------

modifier_roshan_custom_passive = class(ModifierBaseClass)

function modifier_roshan_custom_passive:IsHidden()
  return true
end

function modifier_roshan_custom_passive:IsDebuff()
  return false
end

function modifier_roshan_custom_passive:IsPurgable()
  return false
end

function modifier_roshan_custom_passive:DeclareFunctions()
  return {
    
  }
end
