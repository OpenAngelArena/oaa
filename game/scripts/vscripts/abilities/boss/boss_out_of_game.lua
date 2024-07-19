LinkLuaModifier("modifier_out_of_game_oaa", "abilities/boss/boss_out_of_game.lua", LUA_MODIFIER_MOTION_NONE)

boss_out_of_game = class(AbilityBaseClass)

function boss_out_of_game:GetIntrinsicModifierName()
  return "modifier_out_of_game_oaa"
end

-----------------------------------------------------------------------------------------

modifier_out_of_game_oaa = class(ModifierBaseClass)

function modifier_out_of_game_oaa:IsHidden()
  return true
end

function modifier_out_of_game_oaa:IsDebuff()
  return false
end

function modifier_out_of_game_oaa:IsPurgable()
  return false
end

function modifier_out_of_game_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
    MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
    MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
  }
end

function modifier_out_of_game_oaa:GetAbsoluteNoDamageMagical()
  return 1
end

function modifier_out_of_game_oaa:GetAbsoluteNoDamagePhysical()
  return 1
end

function modifier_out_of_game_oaa:GetAbsoluteNoDamagePure()
  return 1
end

function modifier_out_of_game_oaa:CheckState()
  return {
    [MODIFIER_STATE_ATTACK_IMMUNE] = true,
    [MODIFIER_STATE_COMMAND_RESTRICTED] = true,
    [MODIFIER_STATE_INVULNERABLE] = true,
    [MODIFIER_STATE_MAGIC_IMMUNE] = true,
    [MODIFIER_STATE_NOT_ON_MINIMAP] = true,
    [MODIFIER_STATE_NOT_ON_MINIMAP_FOR_ENEMIES] = true,
    [MODIFIER_STATE_NO_HEALTH_BAR] = true,
    [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
    [MODIFIER_STATE_OUT_OF_GAME] = true,
    [MODIFIER_STATE_UNSELECTABLE] = true,
  }
end
