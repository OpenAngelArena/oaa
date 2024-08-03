LinkLuaModifier("modifier_mini_rosh_root_applier", "abilities/neutrals/oaa_mini_rosh_root.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_mini_rosh_root_effect", "abilities/neutrals/oaa_mini_rosh_root.lua", LUA_MODIFIER_MOTION_NONE)

mini_rosh_root = class(AbilityBaseClass)

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
  return {
    MODIFIER_EVENT_ON_ATTACK_LANDED,
  }
end

if IsServer() then
  function modifier_mini_rosh_root_applier:OnAttackLanded(event)
    local parent = self:GetParent()
    local ability = self:GetAbility()
    local attacker = event.attacker
    local target = event.target

    -- Check if attacker exists
    if not attacker or attacker:IsNull() then
      return
    end

    -- Check if attacker has this modifier
    if parent ~= attacker then
      return
    end

    -- No root while broken or illusion
    if parent:PassivesDisabled() or parent:IsIllusion() then
      return
    end

    -- Check if attacked unit exists
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

    -- Check if ability exists
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
      local actual_duration = target:GetValueChangedByStatusResistance(self.duration)
      target:AddNewModifier(attacker, self:GetAbility(), "modifier_mini_rosh_root_effect", {duration = actual_duration})

      -- Sound
      parent:EmitSound("n_creep_TrollWarlord.Ensnare")

      -- Damage table
      local damage_table = {
        attacker = parent,
        victim = target,
        damage = damage,
        damage_type = ability:GetAbilityDamageType(),
        --damage_flags = DOTA_DAMAGE_FLAG_BYPASSES_PHYSICAL_BLOCK,
        ability = ability,
      }

      -- Apply bonus damage
      ApplyDamage(damage_table)

      -- Start cooldown respecting cooldown reductions
      ability:UseResources(false, false, false, true)
    else
      -- Increment number of failures
      self:SetStackCount(prngMult)
    end
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
  local parent = self:GetParent()
  local state = {
    [MODIFIER_STATE_ROOTED] = true,
  }

  -- Reveal the affected unit if not under Shadow Dance or Depth Shroud
  if not parent:HasModifier("modifier_slark_shadow_dance") and not parent:HasModifier("modifier_slark_depth_shroud") then
    state[MODIFIER_STATE_INVISIBLE] = false
  end

  return state
end

