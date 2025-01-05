LinkLuaModifier("modifier_beastmaster_boar_poison_oaa_applier", "abilities/oaa_beastmaster_boar_poison.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_beastmaster_boar_poison_oaa_effect", "abilities/oaa_beastmaster_boar_poison.lua", LUA_MODIFIER_MOTION_NONE)

beastmaster_boar_poison_oaa = class(AbilityBaseClass)

function beastmaster_boar_poison_oaa:GetIntrinsicModifierName()
  return "modifier_beastmaster_boar_poison_oaa_applier"
end

--------------------------------------------------------------------------------

modifier_beastmaster_boar_poison_oaa_applier = class(ModifierBaseClass)

function modifier_beastmaster_boar_poison_oaa_applier:IsHidden()
  return true
end

function modifier_beastmaster_boar_poison_oaa_applier:IsDebuff()
  return false
end

function modifier_beastmaster_boar_poison_oaa_applier:IsPurgable()
  return false
end

function modifier_beastmaster_boar_poison_oaa_applier:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.debuff_duration = ability:GetSpecialValueFor("duration")
  else
    self.debuff_duration = 3
  end
end

modifier_beastmaster_boar_poison_oaa_applier.OnRefresh = modifier_beastmaster_boar_poison_oaa_applier.OnCreated

function modifier_beastmaster_boar_poison_oaa_applier:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_ATTACK_LANDED,
  }
end

if IsServer() then
  function modifier_beastmaster_boar_poison_oaa_applier:OnAttackLanded(event)
    local parent = self:GetParent()
    local attacker = event.attacker
    local target = event.target

    -- Check if attacker exists
    if not attacker or attacker:IsNull() then
      return
    end

    -- Check if attacker has this modifier
    if attacker ~= parent then
      return
    end

    -- Check if attacked unit exists
    if not target or target:IsNull() then
      return
    end

    -- Don't continue if the attacked entity doesn't have IsMagicImmune method -> attacked entity is something weird
    if target.IsMagicImmune == nil then
      return
    end

    -- Don't proc if affected by break or on spell immune units
    if not parent:PassivesDisabled() and not target:IsMagicImmune() then
      target:AddNewModifier(parent, self:GetAbility(), "modifier_beastmaster_boar_poison_oaa_effect", {duration = self.debuff_duration})
    end
  end
end

--------------------------------------------------------------------------------

modifier_beastmaster_boar_poison_oaa_effect = class(ModifierBaseClass)

function modifier_beastmaster_boar_poison_oaa_effect:IsHidden()
  return false
end

function modifier_beastmaster_boar_poison_oaa_effect:IsDebuff()
  return true
end

function modifier_beastmaster_boar_poison_oaa_effect:IsPurgable()
  return true
end

function modifier_beastmaster_boar_poison_oaa_effect:OnCreated()
  local ability = self:GetAbility()
  local move_slow = 10
  local attack_slow = 10

  if ability and not ability:IsNull() then
    move_slow = ability:GetSpecialValueFor("movement_speed")
    attack_slow = ability:GetSpecialValueFor("attack_speed")
  end

  -- Move Speed Slow is reduced with Slow Resistance
  self.move_slow = move_slow --parent:GetValueChangedBySlowResistance(move_slow)
  self.attack_slow = attack_slow
end

modifier_beastmaster_boar_poison_oaa_effect.OnRefresh = modifier_beastmaster_boar_poison_oaa_effect.OnCreated

-- function modifier_beastmaster_boar_poison_oaa_effect:GetEffectName()
  -- return ""
-- end

function modifier_beastmaster_boar_poison_oaa_effect:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
  }
end

function modifier_beastmaster_boar_poison_oaa_effect:GetModifierMoveSpeedBonus_Percentage()
  return 0 - math.abs(self.move_slow)
end

function modifier_beastmaster_boar_poison_oaa_effect:GetModifierAttackSpeedBonus_Constant()
  return 0 - math.abs(self.attack_slow)
end
