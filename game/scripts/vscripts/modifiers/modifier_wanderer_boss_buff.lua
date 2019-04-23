
LinkLuaModifier("modifier_wanderer_boss_buff", "modifiers/modifier_wanderer_boss_buff.lua", LUA_MODIFIER_MOTION_NONE)

modifier_wanderer_boss_buff = class(ModifierBaseClass)

function modifier_wanderer_boss_buff:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE
  }
end

function modifier_wanderer_boss_buff:GetModifierMoveSpeed_Absolute()
  return 350
end

function modifier_wanderer_boss_buff:IsHidden()
  return true
end
