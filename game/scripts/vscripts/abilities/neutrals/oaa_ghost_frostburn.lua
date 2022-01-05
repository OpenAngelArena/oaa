ghost_frostburn_oaa = class(AbilityBaseClass)

LinkLuaModifier("modifier_frostburn_oaa_applier", "abilities/neutrals/oaa_ghost_frostburn.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier("modifier_frostburn_oaa_effect", "abilities/neutrals/oaa_ghost_frostburn.lua", LUA_MODIFIER_MOTION_NONE )

function ghost_frostburn_oaa:GetIntrinsicModifierName()
  return "modifier_frostburn_oaa_applier"
end

--------------------------------------------------------------------------------

modifier_frostburn_oaa_applier = class(ModifierBaseClass)

function modifier_frostburn_oaa_applier:IsHidden()
  return true
end

function modifier_frostburn_oaa_applier:IsDebuff()
  return false
end

function modifier_frostburn_oaa_applier:IsPurgable()
  return false
end

function modifier_frostburn_oaa_applier:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.heal_prevent_duration = ability:GetSpecialValueFor("heal_prevent_duration")
  else
    self.heal_prevent_duration = 5
  end
end

modifier_frostburn_oaa_applier.OnRefresh = modifier_frostburn_oaa_applier.OnCreated

function modifier_frostburn_oaa_applier:DeclareFunctions()
  local funcs = {
    MODIFIER_EVENT_ON_ATTACK_LANDED,
  }
  return funcs
end

function modifier_frostburn_oaa_applier:OnAttackLanded(event)
  if IsServer() then
    local attacker = event.attacker
    local target = event.target
    local parent = self:GetParent()
    if not parent or parent:IsNull() then
      return
    end
    if attacker == self:GetParent() and not attacker:IsIllusion() and not attacker:PassivesDisabled() and not target:IsMagicImmune() then
      target:AddNewModifier(attacker, self:GetAbility(), "modifier_frostburn_oaa_effect", {duration = self.heal_prevent_duration})
    end
  end
end

--------------------------------------------------------------------------------

modifier_frostburn_oaa_effect = class(ModifierBaseClass)

function modifier_frostburn_oaa_effect:IsHidden()
  return false
end

function modifier_frostburn_oaa_effect:IsDebuff()
  return true
end

function modifier_frostburn_oaa_effect:IsPurgable()
  return true
end

function modifier_frostburn_oaa_effect:OnCreated()
  local ability = self:GetAbility()
  if ability then
    self.heal_prevent_percent = ability:GetSpecialValueFor("heal_prevent_percent")
    self.attack_slow = ability:GetSpecialValueFor("attack_speed_slow")
  else
    self.heal_prevent_percent = -25
    self.attack_slow = -25
  end
  --self.duration = self:GetDuration()
  --self.health_fraction = 0
end

function modifier_frostburn_oaa_effect:OnRefresh()
  local ability = self:GetAbility()
  if ability then
    self.heal_prevent_percent = ability:GetSpecialValueFor("heal_prevent_percent")
    self.attack_slow = ability:GetSpecialValueFor("attack_speed_slow")
  else
    self.heal_prevent_percent = -25
    self.attack_slow = -25
  end
end

function modifier_frostburn_oaa_effect:GetEffectName()
  return "particles/ghost_frostbite.vpcf"--"particles/items4_fx/spirit_vessel_damage.vpcf"
end

function modifier_frostburn_oaa_effect:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_TARGET,
    MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE,
    MODIFIER_PROPERTY_LIFESTEAL_AMPLIFY_PERCENTAGE,
    MODIFIER_PROPERTY_SPELL_LIFESTEAL_AMPLIFY_PERCENTAGE,
    MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
    --MODIFIER_EVENT_ON_HEALTH_GAINED
  }
  return funcs
end

function modifier_frostburn_oaa_effect:GetModifierHealAmplify_PercentageTarget()
  return self.heal_prevent_percent
end

function modifier_frostburn_oaa_effect:GetModifierHPRegenAmplify_Percentage()
  return self.heal_prevent_percent
end

function modifier_frostburn_oaa_effect:GetModifierLifestealRegenAmplify_Percentage()
  return self.heal_prevent_percent
end

function modifier_frostburn_oaa_effect:GetModifierSpellLifestealRegenAmplify_Percentage()
  return self.heal_prevent_percent
end

function modifier_frostburn_oaa_effect:GetModifierAttackSpeedBonus_Constant()
  return self.attack_slow
end

--[[
function modifier_frostburn_oaa_effect:OnHealthGained(event)
  if IsServer() then
    -- Check that event is being called for the unit that self is attached to
    local parent = self:GetParent()
    -- Covfefe (Blade of Judecca) debuff has more priority
    if event.unit == parent and event.gain > 0 and not parent:HasModifier("modifier_item_trumps_fists_frostbite") then
      local heal_percent = self.heal_prevent_percent / 100 * (self:GetRemainingTime() / self.duration)
      local desiredHP = parent:GetHealth() + event.gain * heal_percent + self.health_fraction
      desiredHP = math.max(desiredHP, 1)
      -- Keep record of fractions of health since Dota doesn't (mainly to make passive health regen sort of work)
      self.health_fraction = desiredHP % 1

      parent:SetHealth(desiredHP)
    end
  end
end
]]
