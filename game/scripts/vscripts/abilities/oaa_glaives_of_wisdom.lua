LinkLuaModifier("modifier_oaa_glaives_of_wisdom", "abilities/oaa_glaives_of_wisdom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_oaa_glaives_of_wisdom_fx", "abilities/oaa_glaives_of_wisdom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_oaa_int_steal", "abilities/oaa_glaives_of_wisdom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_oaa_glaives_buff_counter", "abilities/oaa_glaives_of_wisdom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_oaa_glaives_buff", "abilities/oaa_glaives_of_wisdom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_oaa_glaives_debuff_counter", "abilities/oaa_glaives_of_wisdom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_oaa_glaives_debuff", "abilities/oaa_glaives_of_wisdom.lua", LUA_MODIFIER_MOTION_NONE)

silencer_glaives_of_wisdom_oaa = class(AbilityBaseClass)

function silencer_glaives_of_wisdom_oaa:GetIntrinsicModifierName()
  return "modifier_oaa_glaives_of_wisdom"
end

function silencer_glaives_of_wisdom_oaa:CastFilterResultTarget(target)
  local defaultResult = self.BaseClass.CastFilterResultTarget(self, target)
  local caster = self:GetCaster()
  if caster:HasScepter() and defaultResult == UF_FAIL_MAGIC_IMMUNE_ENEMY then
    return UF_SUCCESS
  end

  return defaultResult
end

function silencer_glaives_of_wisdom_oaa:GetCastRange(location, target)
  return self:GetCaster():GetAttackRange()
end

function silencer_glaives_of_wisdom_oaa:ShouldUseResources()
  return true
end

--------------------------------------------------------------------------------

modifier_oaa_glaives_of_wisdom = class(ModifierBaseClass)

function modifier_oaa_glaives_of_wisdom:IsHidden()
  return true
end

function modifier_oaa_glaives_of_wisdom:IsDebuff()
  return false
end

function modifier_oaa_glaives_of_wisdom:IsPurgable()
  return false
end

function modifier_oaa_glaives_of_wisdom:RemoveOnDeath()
  return false
end

function modifier_oaa_glaives_of_wisdom:OnCreated()
  if not IsServer() then
    return
  end
  if not self.procRecords then
    self.procRecords = {}
  end

  local parent = self:GetParent()
  local ability = self:GetAbility()
  -- Add Silencer's permanent int steal custom modifier
  if not parent:HasModifier("modifier_oaa_int_steal") then
    parent:AddNewModifier(parent, ability, "modifier_oaa_int_steal", {})
  end
end

modifier_oaa_glaives_of_wisdom.OnRefresh = modifier_oaa_glaives_of_wisdom.OnCreated

function modifier_oaa_glaives_of_wisdom:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_ATTACK_START,
    MODIFIER_EVENT_ON_ATTACK,
    MODIFIER_EVENT_ON_ATTACK_LANDED,
    MODIFIER_EVENT_ON_ATTACK_FAIL,
    MODIFIER_EVENT_ON_ATTACK_FINISHED
  }
end

function modifier_oaa_glaives_of_wisdom:OnAttackStart(event)
  -- OnAttackStart event is triggering before OnAttack event
  -- Only AttackStart is early enough to override the projectile
  local parent = self:GetParent()
  local ability = self:GetAbility()

  if event.attacker ~= parent then
    return
  end

  if parent:IsIllusion() then
    return
  end

  local target = event.target
  if not target then
    return
  end

  -- Check if the target is going to be deleted soon by C++ garbage collector, if true don't continue
  if target:IsNull() then
    return
  end

  -- Check for existence of GetUnitName method to determine if target is a unit or an item
  -- items don't have that method -> nil; if the target is an item, don't continue
  if target.GetUnitName == nil then
    return
  end

  if ability:IsOwnersManaEnough() and ability:IsCooldownReady() and (not parent:IsSilenced()) and (ability:CastFilterResultTarget(target) == UF_SUCCESS) then
    if ability:GetAutoCastState() == true or parent:GetCurrentActiveAbility() == ability then
      --The Attack while Autocast is ON or manually casted (current active ability)

      -- Add modifier to change attack sound
      parent:AddNewModifier(parent, ability, "modifier_oaa_glaives_of_wisdom_fx", {})

      -- Change Attack Projectile
      parent:ChangeAttackProjectile()
    end
  end
end

function modifier_oaa_glaives_of_wisdom:OnAttack(event)
  local parent = self:GetParent()
  local ability = self:GetAbility()

  if event.attacker ~= parent then
    return
  end

  local target = event.target
  if not target then
    return
  end

  -- Check if the target is going to be deleted soon by C++ garbage collector, if true don't continue
  if target:IsNull() then
    return
  end

  -- Check for existence of GetUnitName method to determine if target is a unit or an item
  -- items don't have that method -> nil; if the target is an item, don't continue
  if target.GetUnitName == nil then
    return
  end

  if ability:IsOwnersManaEnough() and ability:IsCooldownReady() and (not parent:IsSilenced()) and (ability:CastFilterResultTarget(target) == UF_SUCCESS) then
    if ability:GetAutoCastState() == true or parent:GetCurrentActiveAbility() == ability then
      --The Attack while Autocast is ON or or manually casted (current active ability)
      -- Enable proc for this attack record number (event.record is the same for OnAttackLanded)
      self.procRecords[event.record] = true

      -- Use mana and trigger cd while respecting reductions
      -- Using attack modifier abilities doesn't actually fire any cast events so we need to use resources here
      ability:UseResources(true, false, true)

      -- Changing projectile back is too early during OnAttack,
      -- Changing projectile back is done by removing modifier_oaa_glaives_of_wisdom_fx from the parent
      -- it should be done during OnAttackFinished;
    end
  end
end

function modifier_oaa_glaives_of_wisdom:OnAttackFinished(event)
  local parent = self:GetParent()
  if event.attacker == parent then
    -- Remove modifier on every finished attack even if its a normal attack
    parent:RemoveModifierByName("modifier_oaa_glaives_of_wisdom_fx")

    -- Change the projectile (if a parent doesn't have modifier_oaa_glaives_of_wisdom_fx)
    parent:ChangeAttackProjectile()
  end
end

function modifier_oaa_glaives_of_wisdom:OnAttackLanded(event)
  local parent = self:GetParent()
  local ability = self:GetAbility()
  local target = event.target

  if event.attacker ~= parent then
    return
  end

  if parent:IsIllusion() then
    return
  end

  -- if target is nothing (nil), don't continue
  if not target then
    return
  end

  -- Check if the target is going to be deleted soon by C++ garbage collector, if true don't continue
  if target:IsNull() then
    return
  end

  if self.procRecords[event.record] and ability:CastFilterResultTarget(target) == UF_SUCCESS then

    local bonusDamagePct = ability:GetSpecialValueFor("intellect_damage_pct") / 100
    local player = parent:GetPlayerOwner()

    -- Bonus Glaives of Wisdom damage Talent
    if parent:HasLearnedAbility("special_bonus_unique_silencer_3") then
      bonusDamagePct = bonusDamagePct + parent:FindAbilityByName("special_bonus_unique_silencer_3"):GetSpecialValueFor("value") / 100
    end

    --if parent:HasScepter() and target:IsSilenced() then
      --bonusDamagePct = bonusDamagePct * ability:GetSpecialValueFor("scepter_damage_multiplier")
    --end

    -- Intelligence steal if the target is a real hero (and not a meepo clone or arc warden tempest double) and not spell immune
    if target:IsRealHero() and (not target:IsClone()) and (not target:IsTempestDouble()) and (not target:IsMagicImmune()) then
      local intStealDuration = ability:GetSpecialValueFor("int_steal_duration")
      local intStealAmount = ability:GetSpecialValueFor("int_steal")

      if intStealAmount ~= 0 and intStealDuration ~= 0 then
        target:AddNewModifier(parent, ability, "modifier_oaa_glaives_debuff_counter", {duration = intStealDuration})
        target:AddNewModifier(parent, ability, "modifier_oaa_glaives_debuff", {duration = intStealDuration})
        parent:AddNewModifier(parent, ability, "modifier_oaa_glaives_buff_counter", {duration = intStealDuration})
        parent:AddNewModifier(parent, ability, "modifier_oaa_glaives_buff", {duration = intStealDuration})
      end
    end

    local bonusDamage = parent:GetIntellect() * bonusDamagePct

    local damageTable = {}
    damageTable.victim = target
    damageTable.attacker = parent
    damageTable.damage = bonusDamage
    damageTable.damage_type = ability:GetAbilityDamageType()
    damageTable.ability = ability

    --if parent:HasScepter() and target:IsMagicImmune() then
      --damageTable.damage_type = DAMAGE_TYPE_PHYSICAL
      --damageTable.damage_flags = DOTA_DAMAGE_FLAG_BYPASSES_BLOCK
    --end

    ApplyDamage(damageTable)
    SendOverheadEventMessage(player, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, target, bonusDamage, player)
    target:EmitSound("Hero_Silencer.GlaivesOfWisdom.Damage")
    self.procRecords[event.record] = nil
  end
end

function modifier_oaa_glaives_of_wisdom:OnAttackFail(event)
  local parent = self:GetParent()

  if event.attacker == parent and self.procRecords[event.record] then
    self.procRecords[event.record] = nil
  end
end

--------------------------------------------------------------------------------

modifier_oaa_glaives_of_wisdom_fx = class(ModifierBaseClass)

function modifier_oaa_glaives_of_wisdom_fx:IsPurgable()
  return false
end

function modifier_oaa_glaives_of_wisdom_fx:IsHidden()
  return true
end

function modifier_oaa_glaives_of_wisdom_fx:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_TRANSLATE_ATTACK_SOUND
  }
end

function modifier_oaa_glaives_of_wisdom_fx:GetAttackSound()
  return "Hero_Silencer.GlaivesOfWisdom"
end

---------------------------------------------------------------------------------------------------

modifier_oaa_int_steal = class(ModifierBaseClass)

function modifier_oaa_int_steal:IsPurgable()
  return false
end

function modifier_oaa_int_steal:RemoveOnDeath()
  return false
end

function modifier_oaa_int_steal:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_DEATH
  }
end

if IsServer() then
  function modifier_oaa_int_steal:OnDeath(keys)
    local parent = self:GetParent()
    local ability = self:GetAbility()
    local stealRange = ability:GetLevelSpecialValueFor("steal_range", math.max(1, ability:GetLevel()))
    local stealAmount = ability:GetLevelSpecialValueFor("steal_amount", math.max(1, ability:GetLevel()))
    local unit = keys.unit
    local filterResult = UnitFilter(
      unit,
      DOTA_UNIT_TARGET_TEAM_ENEMY,
      DOTA_UNIT_TARGET_HERO,
      bit.bor(DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, DOTA_UNIT_TARGET_FLAG_DEAD),
      parent:GetTeamNumber()
    )
    local isWithinRange = #(unit:GetAbsOrigin() - parent:GetAbsOrigin()) <= stealRange

    -- Check for +2 Int Steal Talent
    if parent:HasLearnedAbility("special_bonus_unique_silencer_2") then
      stealAmount = stealAmount + parent:FindAbilityByName("special_bonus_unique_silencer_2"):GetSpecialValueFor("value")
    end

    if filterResult == UF_SUCCESS and (keys.attacker == parent or isWithinRange) and parent:IsRealHero() and parent:IsAlive() and unit:IsRealHero() and not unit:IsClone() and not unit:IsTempestDouble() then
      local oldIntellect = unit:GetBaseIntellect()
      unit:SetBaseIntellect(math.max(1, oldIntellect - stealAmount))
      unit:CalculateStatBonus()
      local intellectDifference = oldIntellect - unit:GetBaseIntellect()
      parent:ModifyIntellect(intellectDifference)
      self:SetStackCount(self:GetStackCount() + intellectDifference)

      local plusIntParticleName = "particles/units/heroes/hero_silencer/silencer_last_word_steal_count.vpcf"
      local plusIntParticle = ParticleManager:CreateParticle(plusIntParticleName, PATTACH_OVERHEAD_FOLLOW, parent)
      ParticleManager:SetParticleControl(plusIntParticle, 1, Vector(10 + intellectDifference, 0, 0))
      ParticleManager:ReleaseParticleIndex(plusIntParticle)

      local minusIntParticleName = "particles/units/heroes/hero_silencer/silencer_last_word_victim_count.vpcf"
      local minusIntParticle = ParticleManager:CreateParticle(minusIntParticleName, PATTACH_OVERHEAD_FOLLOW, unit)
      ParticleManager:SetParticleControl(minusIntParticle, 1, Vector(10 + intellectDifference, 0, 0))
      ParticleManager:ReleaseParticleIndex(minusIntParticle)
    end
  end
end

---------------------------------------------------------------------------------------------------

modifier_oaa_glaives_buff_counter = class(ModifierBaseClass)

function modifier_oaa_glaives_buff_counter:IsPurgable()
  return false
end

function modifier_oaa_glaives_buff_counter:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_TOOLTIP
  }
end

function modifier_oaa_glaives_buff_counter:OnTooltip()
  return self:GetStackCount()
end

---------------------------------------------------------------------------------------------------

modifier_oaa_glaives_buff = class(ModifierBaseClass)

function modifier_oaa_glaives_buff:IsPurgable()
  return false
end

function modifier_oaa_glaives_buff:IsHidden()
  return true
end

function modifier_oaa_glaives_buff:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_oaa_glaives_buff:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_STATS_INTELLECT_BONUS
  }
end

function modifier_oaa_glaives_buff:OnCreated()
  self.intStealAmount = self:GetAbility():GetSpecialValueFor("int_steal")
  if IsServer() then
    local counterMod = self:GetParent():FindModifierByName("modifier_oaa_glaives_buff_counter")
    if counterMod and not counterMod:IsNull() then
      counterMod:SetStackCount(counterMod:GetStackCount() + self.intStealAmount)
    end
  end
end

if IsServer() then
  function modifier_oaa_glaives_buff:OnDestroy()
    local counterMod = self:GetParent():FindModifierByName("modifier_oaa_glaives_buff_counter")
    if counterMod and not counterMod:IsNull() then
      counterMod:SetStackCount(counterMod:GetStackCount() - self.intStealAmount)
    end
  end
end

function modifier_oaa_glaives_buff:GetModifierBonusStats_Intellect()
  return self.intStealAmount
end

---------------------------------------------------------------------------------------------------

modifier_oaa_glaives_debuff_counter = class(modifier_oaa_glaives_buff_counter)

function modifier_oaa_glaives_debuff_counter:IsDebuff()
  return true
end

---------------------------------------------------------------------------------------------------

modifier_oaa_glaives_debuff = class(ModifierBaseClass)

function modifier_oaa_glaives_debuff:IsPurgable()
  return false
end

function modifier_oaa_glaives_debuff:IsHidden()
  return true
end

function modifier_oaa_glaives_debuff:IsDebuff()
  return true
end

function modifier_oaa_glaives_debuff:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_oaa_glaives_debuff:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_STATS_INTELLECT_BONUS
  }
end

function modifier_oaa_glaives_debuff:OnCreated()
  self.intStealAmount = self:GetAbility():GetSpecialValueFor("int_steal")
  if IsServer() then
    local counterMod = self:GetParent():FindModifierByName("modifier_oaa_glaives_debuff_counter")
    if counterMod and not counterMod:IsNull() then
      counterMod:SetStackCount(counterMod:GetStackCount() + self.intStealAmount)
    end
  end
end

if IsServer() then
  function modifier_oaa_glaives_debuff:OnDestroy()
    local counterMod = self:GetParent():FindModifierByName("modifier_oaa_glaives_debuff_counter")
    if counterMod and not counterMod:IsNull() then
      counterMod:SetStackCount(counterMod:GetStackCount() - self.intStealAmount)
    end
  end
end

function modifier_oaa_glaives_debuff:GetModifierBonusStats_Intellect()
  return -self.intStealAmount
end
