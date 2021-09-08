mini_rosh_root = class(AbilityBaseClass)

LinkLuaModifier("modifier_mini_rosh_root_applier", "abilities/neutrals/oaa_mini_rosh_root.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_mini_rosh_root_effect", "abilities/neutrals/oaa_mini_rosh_root.lua", LUA_MODIFIER_MOTION_NONE)

function mini_rosh_root:GetIntrinsicModifierName()
  return "modifier_mini_rosh_root_applier"
end

function mini_rosh_root:ShouldUseResources()
  return true
end

--------------------------------------------------------------------------------

modifier_mini_rosh_root_applier = class(ModifierBaseClass)

function modifier_mini_rosh_root_applier:IsHidden()
  return true
end

function modifier_mini_rosh_root_applier:IsDebuff()
  return false
end

function modifier_mini_rosh_root_applier:IsPurgable()
  return false
end

function modifier_mini_rosh_root_applier:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.chance = ability:GetSpecialValueFor("root_chance")
    self.damage = ability:GetSpecialValueFor("bonus_damage")
    self.duration = ability:GetSpecialValueFor("root_duration")
  else
    self.chance = 25
    self.damage = 50
    self.duration = 1.65
  end
end

modifier_mini_rosh_root_applier.OnRefresh = modifier_mini_rosh_root_applier.OnCreated

function modifier_mini_rosh_root_applier:DeclareFunctions()
  local funcs = {
    MODIFIER_EVENT_ON_ATTACK_LANDED,
  }
  return funcs
end

function modifier_mini_rosh_root_applier:OnAttackLanded(event)
  if not IsServer() then
    return
  end

  local ability = self:GetAbility()
  local attacker = event.attacker
  local target = event.target
  local parent = self:GetParent()

  if not attacker or attacker:IsNull() then
    return
  end

  if parent ~= attacker then
    return
  end

  -- No root while broken or illusion
  if parent:PassivesDisabled() or parent:IsIllusion() then
    return
  end

  -- To prevent crashes:
  if not target or target:IsNull() then
    return
  end

  -- Check for existence of GetUnitName method to determine if target is a unit or an item (or rune)
  -- items don't have that method -> nil; if the target is an item, don't continue
  if target.GetUnitName == nil then
    return
  end

  -- Don't affect buildings, wards and invulnerable units.
  if target:IsTower() or target:IsBarracks() or target:IsBuilding() or target:IsOther() or target:IsInvulnerable() then
    return
  end
  
  if not ability or ability:IsNull() then
    return
  end

  -- Don't root while on cooldown
  if not ability:IsCooldownReady() then
    return
  end

  local chance = self.chance / 100
  local damage = self.damage

  -- Get number of failures
  local prngMult = self:GetStackCount() + 1

  if RandomFloat(0.0, 1.0) <= (PrdCFinder:GetCForP(chance) * prngMult) then
    -- Reset failure count
    self:SetStackCount(0)

    -- Apply root
    target:AddNewModifier(attacker, self:GetAbility(), "modifier_mini_rosh_root_effect", {duration = self.duration})

    -- Sound
    parent:EmitSound("n_creep_TrollWarlord.Ensnare")

    -- Damage table
    local damage_table = {}
    damage_table.attacker = parent
    damage_table.damage_type = ability:GetAbilityDamageType()
    damage_table.ability = ability
    damage_table.damage = damage
    damage_table.victim = target

    -- Apply bonus damage
    ApplyDamage(damage_table)
	
	-- Start cooldown respecting cooldown reductions
    ability:UseResources(true, true, true)
  else
    -- Increment number of failures
    self:SetStackCount(prngMult)
  end
end

--------------------------------------------------------------------------------

modifier_mini_rosh_root_effect = class(ModifierBaseClass)

function modifier_mini_rosh_root_effect:IsHidden()
  return false
end

function modifier_mini_rosh_root_effect:IsDebuff()
  return true
end

function modifier_mini_rosh_root_effect:IsPurgable()
  return true
end

function modifier_mini_rosh_root_effect:GetEffectName()
  return "particles/neutral_fx/dark_troll_ensnare.vpcf"
end

function modifier_mini_rosh_root_effect:CheckState()
  local state = {
    [MODIFIER_STATE_ROOTED] = true,
  }
  return state
end

