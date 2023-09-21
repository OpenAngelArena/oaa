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
  return {
    MODIFIER_EVENT_ON_ATTACK_LANDED,
  }
end

if IsServer() then
  function modifier_boss_frostbite_applier:OnAttackLanded(event)
    local parent = self:GetParent()
    local attacker = event.attacker
    local target = event.target

    -- Check if attacker exists
    if not attacker or attacker:IsNull() then
      return
    end

    if attacker ~= parent then
      return
    end

    -- Check if attacked unit exists
    if not target or target:IsNull() then
      return
    end

    if parent:PassivesDisabled() or parent:IsIllusion() or not parent:IsAlive() then
      return
    end

    -- Don't affect buildings, wards, spell immune units and invulnerable units.
    if target:IsMagicImmune() or target:IsTower() or target:IsBarracks() or target:IsBuilding() or target:IsOther() or target:IsInvulnerable() then
      return
    end

    target:AddNewModifier(parent, self:GetAbility(), "modifier_boss_frostbite_effect", {duration = self.heal_prevent_duration})
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
    self.heal_prevent_percent = -60
  end
end

function modifier_boss_frostbite_effect:OnRefresh()
  local ability = self:GetAbility()
  if ability then
    self.heal_prevent_percent = ability:GetSpecialValueFor("heal_prevent_percent")
  else
    self.heal_prevent_percent = -60
  end
end

function modifier_boss_frostbite_effect:GetEffectName()
  return "particles/ghost_frostbite.vpcf"--"particles/items4_fx/spirit_vessel_damage.vpcf"
end

function modifier_boss_frostbite_effect:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_TARGET,
    MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE,
    MODIFIER_PROPERTY_LIFESTEAL_AMPLIFY_PERCENTAGE,
    MODIFIER_PROPERTY_SPELL_LIFESTEAL_AMPLIFY_PERCENTAGE,
  }
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
