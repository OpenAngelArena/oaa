beastmaster_hawk_dive_oaa = class(AbilityBaseClass)

LinkLuaModifier( "modifier_hawk_dive_stun", "abilities/oaa_beastmaster_hawk_dive.lua", LUA_MODIFIER_MOTION_NONE )

function beastmaster_hawk_dive_oaa:OnSpellStart()
  local caster = self:GetCaster()
  local target = self:GetCursorTarget()

  -- Check if target and caster entities exist
  if not target or not caster then
    return
  end

  -- Check if target has spell block
  if target:TriggerSpellAbsorb(self) then
    return
  end

  local damage = self:GetSpecialValueFor("damage")
  local duration = self:GetSpecialValueFor("stun_duration")

  local damage_table = {}
  damage_table.victim = target
  damage_table.attacker = caster
  damage_table.damage = damage
  damage_table.damage_type = self:GetAbilityDamageType()
  damage_table.ability = self

  ApplyDamage(damage_table)

  target:AddNewModifier(caster, self, "modifier_hawk_dive_stun", {duration = duration})

  if caster and caster:IsAlive() then
    caster:Kill(self, caster)
  end
end

---------------------------------------------------------------------------------------------------

modifier_hawk_dive_stun = class(ModifierBaseClass)

function modifier_hawk_dive_stun:IsHidden()
  return true
end

function modifier_hawk_dive_stun:IsDebuff()
  return true
end

function modifier_hawk_dive_stun:IsStunDebuff()
  return true
end

function modifier_hawk_dive_stun:IsPurgable()
  return true
end

function modifier_hawk_dive_stun:GetEffectName()
  return "particles/generic_gameplay/generic_stunned.vpcf"
end

function modifier_hawk_dive_stun:GetEffectAttachType()
  return PATTACH_OVERHEAD_FOLLOW
end

function modifier_hawk_dive_stun:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
  }

  return funcs
end

function modifier_hawk_dive_stun:GetOverrideAnimation()
  return ACT_DOTA_DISABLED
end

function modifier_hawk_dive_stun:CheckState()
  local state = {
    [MODIFIER_STATE_STUNNED] = true,
  }
  return state
end
