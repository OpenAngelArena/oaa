LinkLuaModifier("modifier_roshan_bash_oaa", "modifiers/funmodifiers/modifier_roshan_power_oaa.lua", LUA_MODIFIER_MOTION_NONE)

modifier_roshan_power_oaa = class(ModifierBaseClass)

function modifier_roshan_power_oaa:IsHidden()
  return false
end

function modifier_roshan_power_oaa:IsDebuff()
  return false
end

function modifier_roshan_power_oaa:IsPurgable()
  return false
end

function modifier_roshan_power_oaa:RemoveOnDeath()
  return false
end

function modifier_roshan_power_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MOVESPEED_BASE_OVERRIDE,
    MODIFIER_PROPERTY_MODEL_CHANGE,
    MODIFIER_PROPERTY_PROCATTACK_BONUS_DAMAGE_MAGICAL,
  }
end

function modifier_roshan_power_oaa:GetModifierMoveSpeedOverride()
  return 270
end

function modifier_roshan_power_oaa:GetModifierModelChange()
  return "models/creeps/roshan/roshan.vmdl"
end

if IsServer() then
  function modifier_roshan_power_oaa:GetModifierProcAttack_BonusDamage_Magical(event)
    local parent = self:GetParent()

    if parent:IsIllusion() then
      return 0
    end

    local target = event.target

    -- can't bash towers or wards, but can bash allies
    if UnitFilter(target, DOTA_UNIT_TARGET_TEAM_BOTH, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, parent:GetTeamNumber()) ~= UF_SUCCESS then
      return 0
    end

    local chance = 15

    if RandomInt(1, 100) <= chance then
      local duration = 1.65
      local damage = 50

      duration = target:GetValueChangedByStatusResistance(duration)

      target:AddNewModifier(parent, nil, "modifier_roshan_bash_oaa", {duration = duration})

      target:EmitSound("Roshan.Bash")

      return damage
    end
    return 0
  end
end

function modifier_roshan_power_oaa:GetTexture()
  return "roshan_bash"
end

---------------------------------------------------------------------------------------------------

modifier_roshan_bash_oaa = class(ModifierBaseClass)

function modifier_roshan_bash_oaa:IsHidden()
  return false
end

function modifier_roshan_bash_oaa:IsDebuff()
  return true
end

function modifier_roshan_bash_oaa:IsStunDebuff()
  return true
end

function modifier_roshan_bash_oaa:IsPurgable()
  return true
end

function modifier_roshan_bash_oaa:GetEffectName()
  return "particles/generic_gameplay/generic_stunned.vpcf"
end

function modifier_roshan_bash_oaa:GetEffectAttachType()
  return PATTACH_OVERHEAD_FOLLOW
end

function modifier_roshan_bash_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
  }
end

function modifier_roshan_bash_oaa:GetOverrideAnimation()
  return ACT_DOTA_DISABLED
end

function modifier_roshan_bash_oaa:CheckState()
  return {
    [MODIFIER_STATE_STUNNED] = true,
  }
end

function modifier_roshan_bash_oaa:GetTexture()
  return "roshan_bash"
end
