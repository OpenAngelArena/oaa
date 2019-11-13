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
  self.heal_prevent_duration = self:GetAbility():GetSpecialValueFor("heal_prevent_duration")
end

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
    if attacker == self:GetParent() and not attacker:IsIllusion() and not attacker:PassivesDisabled() and not target:IsMagicImmune() then
      local debuff_duration = target:GetValueChangedByStatusResistance(self.heal_prevent_duration)
      target:AddNewModifier(attacker, self:GetAbility(), "modifier_frostburn_oaa_effect", {duration = debuff_duration})
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
  return false
end

function modifier_frostburn_oaa_effect:OnCreated()
  if IsServer() then
    local ability = self:GetAbility()
    if ability then
      self.heal_prevent_percent = ability:GetSpecialValueFor("heal_prevent_percent")
    else
      self.heal_prevent_percent = 40
    end
    self.duration = self:GetDuration()
    self.health_fraction = 0
  end
end

function modifier_frostburn_oaa_effect:DeclareFunctions()
  local funcs = {
    MODIFIER_EVENT_ON_HEALTH_GAINED
  }
  return funcs
end

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
