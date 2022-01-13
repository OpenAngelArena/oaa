LinkLuaModifier("modifier_boss_frostbite_applier", "abilities/boss/boss_frostbite.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_boss_frostbite_effect", "abilities/boss/boss_frostbite.lua", LUA_MODIFIER_MOTION_NONE)

boss_frostbite = class(AbilityBaseClass)

function boss_frostbite:Precache(context)
  PrecacheResource("particle", "particles/ghost_frostbite_ground_elec.vpcf", context)
  PrecacheResource("particle", "particles/ghost_frostbite_ring.vpcf", context)
  PrecacheResource("particle", "particles/ghost_frostbite_ring_base.vpcf", context)
  PrecacheResource("particle", "particles/ghost_frostbite_ring_detail.vpcf", context)
  PrecacheResource("particle", "particles/ghost_frostbite.vpcf", context)
end

function boss_frostbite:GetIntrinsicModifierName()
  return "modifier_boss_frostbite_applier"
end

--------------------------------------------------------------------------------

modifier_boss_frostbite_applier = class(ModifierBaseClass)

function modifier_boss_frostbite_applier:IsHidden()
  return true
end

function modifier_boss_frostbite_applier:IsDebuff()
  return false
end

function modifier_boss_frostbite_applier:IsPurgable()
  return false
end

function modifier_boss_frostbite_applier:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.heal_prevent_duration = ability:GetSpecialValueFor("heal_prevent_duration")
  else
    self.heal_prevent_duration = 5
  end
end

modifier_boss_frostbite_applier.OnRefresh = modifier_boss_frostbite_applier.OnCreated

function modifier_boss_frostbite_applier:DeclareFunctions()
  local funcs = {
    MODIFIER_EVENT_ON_ATTACK_LANDED,
  }
  return funcs
end

function modifier_boss_frostbite_applier:OnAttackLanded(event)
  if IsServer() then
    local attacker = event.attacker
    local target = event.target
    local parent = self:GetParent()
    if not parent or parent:IsNull() then
      return
    end
    if attacker == self:GetParent() and not attacker:IsIllusion() and not attacker:PassivesDisabled() and not target:IsMagicImmune() then
      target:AddNewModifier(attacker, self:GetAbility(), "modifier_boss_frostbite_effect", {duration = self.heal_prevent_duration})
    end
  end
end

--------------------------------------------------------------------------------

modifier_boss_frostbite_effect = class(ModifierBaseClass)

function modifier_boss_frostbite_effect:IsHidden()
  return false
end

function modifier_boss_frostbite_effect:IsDebuff()
  return true
end

function modifier_boss_frostbite_effect:IsPurgable()
  return true
end

function modifier_boss_frostbite_effect:OnCreated()
  local ability = self:GetAbility()
  if ability then
    self.heal_prevent_percent = ability:GetSpecialValueFor("heal_prevent_percent")
  else
    self.heal_prevent_percent = -40
  end
end

function modifier_boss_frostbite_effect:OnRefresh()
  local ability = self:GetAbility()
  if ability then
    self.heal_prevent_percent = ability:GetSpecialValueFor("heal_prevent_percent")
  else
    self.heal_prevent_percent = -40
  end
end

function modifier_boss_frostbite_effect:GetEffectName()
  return "particles/ghost_frostbite.vpcf"--"particles/items4_fx/spirit_vessel_damage.vpcf"
end

function modifier_boss_frostbite_effect:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_TARGET,
    MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE,
    MODIFIER_PROPERTY_LIFESTEAL_AMPLIFY_PERCENTAGE,
    MODIFIER_PROPERTY_SPELL_LIFESTEAL_AMPLIFY_PERCENTAGE,
  }
  return funcs
end

function modifier_boss_frostbite_effect:GetModifierHealAmplify_PercentageTarget()
  return self.heal_prevent_percent
end

function modifier_boss_frostbite_effect:GetModifierHPRegenAmplify_Percentage()
  return self.heal_prevent_percent
end

function modifier_boss_frostbite_effect:GetModifierLifestealRegenAmplify_Percentage()
  return self.heal_prevent_percent
end

function modifier_boss_frostbite_effect:GetModifierSpellLifestealRegenAmplify_Percentage()
  return self.heal_prevent_percent
end
