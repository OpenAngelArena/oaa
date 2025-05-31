LinkLuaModifier("modifier_frostburn_oaa_applier", "abilities/neutrals/oaa_ghost_frostburn.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_frostburn_oaa_effect", "abilities/neutrals/oaa_ghost_frostburn.lua", LUA_MODIFIER_MOTION_NONE)

ghost_frostburn_oaa = class(AbilityBaseClass)

function ghost_frostburn_oaa:GetIntrinsicModifierName()
  return "modifier_frostburn_oaa_applier"
end

--------------------------------------------------------------------------------

modifier_frostburn_oaa_applier = class({})

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
  return {
    MODIFIER_PROPERTY_PROCATTACK_FEEDBACK,
  }
end

if IsServer() then
  function modifier_frostburn_oaa_applier:GetModifierProcAttack_Feedback(event)
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

    -- Do nothing if attacker is an illusion, dead or affected by break
    if parent:PassivesDisabled() or parent:IsIllusion() or not parent:IsAlive() then
      return
    end

    -- Don't continue if the attacked entity doesn't have IsMagicImmune method -> attacked entity is something weird
    if target.IsMagicImmune == nil then
      return
    end

    -- Don't affect buildings, wards, spell immune units and invulnerable units.
    if target:IsMagicImmune() or target:IsTower() or target:IsBarracks() or target:IsBuilding() or target:IsOther() or target:IsInvulnerable() then
      return
    end

    target:AddNewModifier(parent, self:GetAbility(), "modifier_frostburn_oaa_effect", {duration = self.heal_prevent_duration})
    target:ApplyNonStackableBuff(parent, self:GetAbility(), "modifier_item_enhancement_crude", self.heal_prevent_duration)
  end
end

--------------------------------------------------------------------------------

modifier_frostburn_oaa_effect = class({})

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

function modifier_frostburn_oaa_effect:GetEffectName()
  return "particles/ghost_frostbite.vpcf"--"particles/items4_fx/spirit_vessel_damage.vpcf"
end

function modifier_frostburn_oaa_effect:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_TARGET,
    --MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE,
    --MODIFIER_PROPERTY_LIFESTEAL_AMPLIFY_PERCENTAGE,
    --MODIFIER_PROPERTY_SPELL_LIFESTEAL_AMPLIFY_PERCENTAGE,
    MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
    --MODIFIER_EVENT_ON_HEALTH_GAINED
  }
end

function modifier_frostburn_oaa_effect:GetModifierHealAmplify_PercentageTarget()
  return 0 - math.abs(self.heal_prevent_percent)
end

function modifier_frostburn_oaa_effect:GetModifierHPRegenAmplify_Percentage()
  return 0 - math.abs(self.heal_prevent_percent)
end

-- Doesn't work, Thanks Valve!
-- function modifier_frostburn_oaa_effect:GetModifierLifestealRegenAmplify_Percentage()
  -- return 0 - math.abs(self.heal_prevent_percent)
-- end

-- Doesn't work, Thanks Valve!
-- function modifier_frostburn_oaa_effect:GetModifierSpellLifestealRegenAmplify_Percentage()
  -- return 0 - math.abs(self.heal_prevent_percent)
-- end

function modifier_frostburn_oaa_effect:GetModifierAttackSpeedBonus_Constant()
  return 0 - math.abs(self.attack_slow)
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
