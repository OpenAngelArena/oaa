LinkLuaModifier("modifier_giant_wolf_cripple_oaa_applier", "abilities/neutrals/oaa_giant_wolf_cripple.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_giant_wolf_cripple_oaa_effect", "abilities/neutrals/oaa_giant_wolf_cripple.lua", LUA_MODIFIER_MOTION_NONE)

giant_wolf_cripple_oaa = class(AbilityBaseClass)

function giant_wolf_cripple_oaa:GetIntrinsicModifierName()
  return "modifier_giant_wolf_cripple_oaa_applier"
end

--------------------------------------------------------------------------------

modifier_giant_wolf_cripple_oaa_applier = class({})

function modifier_giant_wolf_cripple_oaa_applier:IsHidden()
  return true
end

function modifier_giant_wolf_cripple_oaa_applier:IsDebuff()
  return false
end

function modifier_giant_wolf_cripple_oaa_applier:IsPurgable()
  return false
end

function modifier_giant_wolf_cripple_oaa_applier:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.duration = ability:GetSpecialValueFor("duration")
    self.chance = ability:GetSpecialValueFor("chance")
  else
    self.duration = 4
    self.chance = 25
  end
end

modifier_giant_wolf_cripple_oaa_applier.OnRefresh = modifier_giant_wolf_cripple_oaa_applier.OnCreated

function modifier_giant_wolf_cripple_oaa_applier:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_PROCATTACK_FEEDBACK,
  }
end

if IsServer() then
  function modifier_giant_wolf_cripple_oaa_applier:GetModifierProcAttack_Feedback(event)
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

    -- Don't proc when broken or on spell immune units
    if parent:PassivesDisabled() or target:IsMagicImmune() then
      return
    end

    local chance = self.chance / 100

    -- Get number of failures
    local prngMult = self:GetStackCount() + 1

    -- compared prng to slightly less prng
    if RandomFloat(0.0, 1.0) <= (PrdCFinder:GetCForP(chance) * prngMult) then
      -- Reset failure count
      self:SetStackCount(0)

      -- Apply the debuff
      target:AddNewModifier(parent, self:GetAbility(), "modifier_giant_wolf_cripple_oaa_effect", {duration = self.duration})
    else
      -- Increment number of failures
      self:SetStackCount(prngMult)
    end
  end
end

--------------------------------------------------------------------------------

modifier_giant_wolf_cripple_oaa_effect = class({})

function modifier_giant_wolf_cripple_oaa_effect:IsHidden()
  return false
end

function modifier_giant_wolf_cripple_oaa_effect:IsDebuff()
  return true
end

function modifier_giant_wolf_cripple_oaa_effect:IsPurgable()
  return true
end

function modifier_giant_wolf_cripple_oaa_effect:OnCreated()
  local ability = self:GetAbility()
  if ability then
    self.ms_slow = ability:GetSpecialValueFor("ms_slow") --parent:GetValueChangedBySlowResistance(ms_slow)
    self.as_slow = ability:GetSpecialValueFor("as_slow")
  else
    self.ms_slow = -15
    self.as_slow = -30
  end
end

-- function modifier_giant_wolf_cripple_oaa_effect:GetEffectName()
  -- return ""
-- end

function modifier_giant_wolf_cripple_oaa_effect:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
  }
end

function modifier_giant_wolf_cripple_oaa_effect:GetModifierMoveSpeedBonus_Percentage()
  return 0 - math.abs(self.ms_slow)
end

function modifier_giant_wolf_cripple_oaa_effect:GetModifierAttackSpeedBonus_Constant()
  return 0 - math.abs(self.as_slow)
end
