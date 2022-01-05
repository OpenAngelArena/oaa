modifier_oaa_thinker = class(ModifierBaseClass)

function modifier_oaa_thinker:IsHidden()
  return true
end

function modifier_oaa_thinker:IsDebuff()
  return false
end

function modifier_oaa_thinker:IsPurgable()
  return false
end

function modifier_oaa_thinker:OnCreated(keys)
  if IsServer() then
    --print("caster: "..tostring(self:GetCaster()))
    --print("ability: "..tostring(self:GetAbility()))
    --print("thinker: "..tostring(self:GetParent()))
    --print("location: "..tostring(self:GetParent():GetAbsOrigin()))
  end
end

function modifier_oaa_thinker:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
    MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
    MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
  }
end

function modifier_oaa_thinker:GetAbsoluteNoDamagePhysical()
  return 1
end

function modifier_oaa_thinker:GetAbsoluteNoDamageMagical()
  return 1
end

function modifier_oaa_thinker:GetAbsoluteNoDamagePure()
  return 1
end

function modifier_oaa_thinker:CheckState()
  local state = {
    [MODIFIER_STATE_UNSELECTABLE] = true,
    [MODIFIER_STATE_NOT_ON_MINIMAP] = true,
    [MODIFIER_STATE_NOT_ON_MINIMAP_FOR_ENEMIES] = true,
    [MODIFIER_STATE_NO_HEALTH_BAR] = true,
    [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
    [MODIFIER_STATE_OUT_OF_GAME] = true,
    [MODIFIER_STATE_NO_TEAM_MOVE_TO] = true,
    [MODIFIER_STATE_NO_TEAM_SELECT] = true,
    [MODIFIER_STATE_COMMAND_RESTRICTED] = true,
    [MODIFIER_STATE_ATTACK_IMMUNE] = true,
    [MODIFIER_STATE_MAGIC_IMMUNE] = true,
  }
  return state
end
