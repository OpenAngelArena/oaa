LinkLuaModifier("modifier_oaa_arcane_orb", "abilities/oaa_arcane_orb.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_oaa_arcane_orb_sound", "abilities/oaa_arcane_orb.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_oaa_arcane_orb_buff_counter", "abilities/oaa_arcane_orb.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_oaa_arcane_orb_buff", "abilities/oaa_arcane_orb.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_oaa_arcane_orb_debuff_counter", "abilities/oaa_arcane_orb.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_oaa_arcane_orb_debuff", "abilities/oaa_arcane_orb.lua", LUA_MODIFIER_MOTION_NONE)

obsidian_destroyer_arcane_orb_oaa = class(AbilityBaseClass)

function obsidian_destroyer_arcane_orb_oaa:GetIntrinsicModifierName()
  return "modifier_oaa_arcane_orb"
end

function obsidian_destroyer_arcane_orb_oaa:GetCastRange(location, target)
  return self:GetCaster():GetAttackRange()
end

--------------------------------------------------------------------------------

modifier_oaa_arcane_orb = class(ModifierBaseClass)

function modifier_oaa_arcane_orb:IsHidden()
  return true
end

function modifier_oaa_arcane_orb:IsPurgable()
  return false
end

function modifier_oaa_arcane_orb:RemoveOnDeath()
  return false
end

function modifier_oaa_arcane_orb:OnCreated()
  if IsServer() then
    if not self.procRecords then
      self.procRecords = {}
    end
    self.parentOriginalProjectile = self:GetParent():GetRangedProjectileName()
    Debug.EnabledModules["abilities:oaa_arcane_orb"] = false
  end
end

modifier_oaa_arcane_orb.OnRefresh = modifier_oaa_arcane_orb.OnCreated

function modifier_oaa_arcane_orb:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_ATTACK_START,
    MODIFIER_EVENT_ON_ATTACK,
    MODIFIER_EVENT_ON_ATTACK_LANDED,
    MODIFIER_EVENT_ON_ATTACK_FAIL
  }
end

function modifier_oaa_arcane_orb:OnAttackStart(keys)
  local parent = self:GetParent()

  if keys.attacker ~= parent then
    return
  end

  local ability = self:GetAbility()
  local target = keys.target
  -- Wrap in function to defer evaluation
  local function autocast()
    return (
      target.GetUnitName and -- Check for existence of GetUnitName method to determine if target is a unit
      ability:GetAutoCastState() and
      not parent:IsSilenced() and
      ability:IsOwnersManaEnough() and
      ability:IsOwnersGoldEnough(parent:GetPlayerOwnerID()) and
      ability:IsCooldownReady() and
      ability:CastFilterResultTarget(target) == UF_SUCCESS
    )
  end

  if parent:GetCurrentActiveAbility() ~= ability and not autocast() then
    return
  end

  -- Add modifier to change attack sound
  parent:AddNewModifier(parent, ability, "modifier_oaa_arcane_orb_sound", {})
  -- Set projectile
  parent:ChangeAttackProjectile()
end

function modifier_oaa_arcane_orb:OnAttack(keys)
  local parent = self:GetParent()

  -- process_procs == true in OnAttack means this is an attack that attack modifiers should not apply to
  if keys.attacker ~= parent or keys.process_procs then
    return
  end

  local ability = self:GetAbility()
  local target = keys.target
  -- Wrap in function to defer evaluation
  local function autocast()
    return (
      target.GetUnitName and -- Check for existence of GetUnitName method to determine if target is a unit
      ability:GetAutoCastState() and
      not parent:IsSilenced() and
      ability:IsOwnersManaEnough() and
      ability:IsOwnersGoldEnough(parent:GetPlayerOwnerID()) and
      ability:IsCooldownReady() and
      ability:CastFilterResultTarget(target) == UF_SUCCESS
    )
  end

  if parent:GetCurrentActiveAbility() ~= ability and not autocast() then
    return
  end

  parent:RemoveModifierByName("modifier_oaa_arcane_orb_sound")
  parent:ChangeAttackProjectile()

  ability:CastAbility()
  -- Enable proc for this attack record number
  self.procRecords[keys.record] = true
end

function modifier_oaa_arcane_orb:OnAttackLanded(keys)
  local parent = self:GetParent()
  local attackRecord = keys.record
  local target = keys.target
  local ability = self:GetAbility()

  if keys.attacker ~= parent or not self.procRecords[attackRecord] or not keys.process_procs then
    return
  end

  local bonusDamage = parent:GetMana() * ability:GetSpecialValueFor("mana_pool_damage_pct") / 100
  self.procRecords[attackRecord] = nil

  if ability:CastFilterResultTarget(target) == UF_SUCCESS then
    local player = parent:GetPlayerOwner()

    -- Bonus damage vs illusions and summons that aren't creep-heroes
    if target:IsIllusion() or (target:IsSummoned() and not target:IsConsideredHero()) then
      bonusDamage = bonusDamage + ability:GetSpecialValueFor("illusion_damage")
    end

    local damageTable = {
      victim = target,
      attacker = parent,
      damage = bonusDamage,
      damage_type = ability:GetAbilityDamageType(),
      ability = ability
    }
    ApplyDamage(damageTable)
    SendOverheadEventMessage(player, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, target, bonusDamage, player)
    target:EmitSound("Hero_ObsidianDestroyer.ArcaneOrb.Impact")

    -- Intelligence steal
    if target:IsRealHero() and not target:IsClone() then
      local intStealDuration = ability:GetSpecialValueFor("int_steal_duration")
      local intStealAmount = ability:GetSpecialValueFor("int_steal")

      if parent:HasLearnedAbility("special_bonus_unique_outworld_devourer") then
        intStealDuration = intStealDuration + parent:FindAbilityByName("special_bonus_unique_outworld_devourer"):GetSpecialValueFor("value")
      end

      target:AddNewModifier(parent, ability, "modifier_oaa_arcane_orb_debuff_counter", {duration = intStealDuration})
      target:AddNewModifier(parent, ability, "modifier_oaa_arcane_orb_debuff", {duration = intStealDuration})
      parent:AddNewModifier(parent, ability, "modifier_oaa_arcane_orb_buff_counter", {duration = intStealDuration})
      parent:AddNewModifier(parent, ability, "modifier_oaa_arcane_orb_buff", {duration = intStealDuration})
    end
  end
end

function modifier_oaa_arcane_orb:OnAttackFail(keys)
  if keys.attacker == self:GetParent() and self.procRecords[keys.record] then
    self.procRecords[keys.record] = nil
  end
end

--------------------------------------------------------------------------------

modifier_oaa_arcane_orb_sound = class(ModifierBaseClass)

function modifier_oaa_arcane_orb_sound:IsPurgable()
  return false
end

function modifier_oaa_arcane_orb_sound:IsHidden()
  return true
end

function modifier_oaa_arcane_orb_sound:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_TRANSLATE_ATTACK_SOUND
  }
end

function modifier_oaa_arcane_orb_sound:GetAttackSound()
  return "Hero_ObsidianDestroyer.ArcaneOrb"
end

--------------------------------------------------------------------------------

modifier_oaa_arcane_orb_buff_counter = class(ModifierBaseClass)

function modifier_oaa_arcane_orb_buff_counter:IsPurgable()
  return false
end

function modifier_oaa_arcane_orb_buff_counter:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_TOOLTIP
  }
end

function modifier_oaa_arcane_orb_buff_counter:OnTooltip()
  return self:GetStackCount()
end

--------------------------------------------------------------------------------

modifier_oaa_arcane_orb_buff = class(ModifierBaseClass)

function modifier_oaa_arcane_orb_buff:IsPurgable()
  return false
end

function modifier_oaa_arcane_orb_buff:IsHidden()
  return true
end

function modifier_oaa_arcane_orb_buff:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_oaa_arcane_orb_buff:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_STATS_INTELLECT_BONUS
  }
end

function modifier_oaa_arcane_orb_buff:OnCreated()
  self.intStealAmount = self:GetAbility():GetSpecialValueFor("int_steal")
  if IsServer() then
    local counterMod = self:GetParent():FindModifierByName("modifier_oaa_arcane_orb_buff_counter")
    if counterMod and not counterMod:IsNull() then
      counterMod:SetStackCount(counterMod:GetStackCount() + self.intStealAmount)
    end
  end
end

if IsServer() then
  function modifier_oaa_arcane_orb_buff:OnDestroy()
    local counterMod = self:GetParent():FindModifierByName("modifier_oaa_arcane_orb_buff_counter")
    if counterMod and not counterMod:IsNull() then
      counterMod:SetStackCount(counterMod:GetStackCount() - self.intStealAmount)
    end
  end
end

function modifier_oaa_arcane_orb_buff:GetModifierBonusStats_Intellect()
  return self.intStealAmount
end

--------------------------------------------------------------------------------

modifier_oaa_arcane_orb_debuff_counter = class(modifier_oaa_arcane_orb_buff_counter)

function modifier_oaa_arcane_orb_debuff_counter:IsDebuff()
  return true
end

--------------------------------------------------------------------------------

modifier_oaa_arcane_orb_debuff = class(ModifierBaseClass)

function modifier_oaa_arcane_orb_debuff:IsPurgable()
  return false
end

function modifier_oaa_arcane_orb_debuff:IsHidden()
  return true
end

function modifier_oaa_arcane_orb_debuff:IsDebuff()
  return true
end

function modifier_oaa_arcane_orb_debuff:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_oaa_arcane_orb_debuff:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_STATS_INTELLECT_BONUS
  }
end

function modifier_oaa_arcane_orb_debuff:OnCreated()
  self.intStealAmount = self:GetAbility():GetSpecialValueFor("int_steal")
  if IsServer() then
    local counterMod = self:GetParent():FindModifierByName("modifier_oaa_arcane_orb_debuff_counter")
    if counterMod and not counterMod:IsNull() then
      counterMod:SetStackCount(counterMod:GetStackCount() + self.intStealAmount)
    end
  end
end

if IsServer() then
  function modifier_oaa_arcane_orb_debuff:OnDestroy()
    local counterMod = self:GetParent():FindModifierByName("modifier_oaa_arcane_orb_debuff_counter")
    if counterMod and not counterMod:IsNull() then
      counterMod:SetStackCount(counterMod:GetStackCount() - self.intStealAmount)
    end
  end
end

function modifier_oaa_arcane_orb_debuff:GetModifierBonusStats_Intellect()
  return - self.intStealAmount
end
