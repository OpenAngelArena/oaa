LinkLuaModifier("modifier_oaa_arcane_orb", "abilities/oaa_arcane_orb.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_oaa_arcane_orb_sound", "abilities/oaa_arcane_orb.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_oaa_arcane_orb_buff_counter", "abilities/oaa_arcane_orb.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_oaa_arcane_orb_buff", "abilities/oaa_arcane_orb.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_oaa_arcane_orb_debuff_counter", "abilities/oaa_arcane_orb.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_oaa_arcane_orb_debuff", "abilities/oaa_arcane_orb.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_oaa_arcane_orb_mana_buff_counter", "abilities/oaa_arcane_orb.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_oaa_arcane_orb_mana_buff", "abilities/oaa_arcane_orb.lua", LUA_MODIFIER_MOTION_NONE)

obsidian_destroyer_arcane_orb_oaa = class(AbilityBaseClass)

function obsidian_destroyer_arcane_orb_oaa:GetIntrinsicModifierName()
  return "modifier_oaa_arcane_orb"
end

function obsidian_destroyer_arcane_orb_oaa:GetCastRange(location, target)
  return self:GetCaster():GetAttackRange()
end

function obsidian_destroyer_arcane_orb_oaa:IsStealable()
	return false
end

function obsidian_destroyer_arcane_orb_oaa:ShouldUseResources()
	return true
end

function obsidian_destroyer_arcane_orb_oaa:OnSpellStart()

end

--------------------------------------------------------------------------------

modifier_oaa_arcane_orb = class(ModifierBaseClass)

function modifier_oaa_arcane_orb:IsHidden()
  return true
end

function modifier_oaa_arcane_orb:IsDebuff()
	return false
end

function modifier_oaa_arcane_orb:IsPurgable()
  return false
end

function modifier_oaa_arcane_orb:RemoveOnDeath()
  return false
end

function modifier_oaa_arcane_orb:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_ATTACK_START,
    MODIFIER_EVENT_ON_ATTACK,
    MODIFIER_EVENT_ON_ATTACK_LANDED,
    MODIFIER_EVENT_ON_ATTACK_FINISHED
  }
end

function modifier_oaa_arcane_orb:OnAttack(event)
  local parent = self:GetParent()
  local ability = self:GetAbility()

  if event.attacker ~= parent then
    return
  end

  if parent:GetCurrentActiveAbility() ~= ability then
    return
  end

  -- To prevent crashes:
  local target
  if event.target == nil then
    return
  else
    target = event.target
  end

  if target:IsNull() then
    return
  end

  -- Check for existence of GetUnitName method to determine if target is a unit or an item
  -- items don't have that method -> nil; if the target is an item, don't continue
  if target.GetUnitName == nil then
    return
  end

  -- This happens only when Arcane Orb is cast manually.
  self.manual_cast = true

  -- This is here just in case if the changing projectile fails during OnAttackStart when manually casting
  if ability:IsOwnersManaEnough() and ability:IsCooldownReady() and (not parent:IsSilenced()) and (not target:IsMagicImmune()) then
    parent:SetRangedProjectileName("particles/units/heroes/hero_obsidian_destroyer/obsidian_destroyer_arcane_orb.vpcf")
  end
end

function modifier_oaa_arcane_orb:OnAttackStart(event)
  -- OnAttackStart event is triggering before OnAttack event
  local parent = self:GetParent()
  local ability = self:GetAbility()

  if event.attacker ~= parent then
    return
  end

  if parent:IsIllusion() then
	return
  end

  -- To prevent crashes:
  local target
  if event.target == nil then
    return
  else
    target = event.target
  end

  if target:IsNull() then
    return
  end

  -- Check for existence of GetUnitName method to determine if target is a unit or an item
  -- items don't have that method -> nil; if the target is an item, don't continue
  if target.GetUnitName == nil then
    return
  end

  if ability:IsOwnersManaEnough() and ability:IsCooldownReady() and (not parent:IsSilenced()) and (not target:IsMagicImmune()) then
    if ability:GetAutoCastState() == true then
      --The Attack while Autocast is ON
      parent:AddNewModifier(parent, ability, "modifier_oaa_arcane_orb_sound", {})
	  -- Change Attack Projectile
      parent:SetRangedProjectileName("particles/units/heroes/hero_obsidian_destroyer/obsidian_destroyer_arcane_orb.vpcf")
    else
      --The Attack while Autocast is OFF
      if parent:GetCurrentActiveAbility() == ability then
        -- Arcane Orb Manual Cast
        parent:AddNewModifier(parent, ability, "modifier_oaa_arcane_orb_sound", {})
        parent:SetRangedProjectileName("particles/units/heroes/hero_obsidian_destroyer/obsidian_destroyer_arcane_orb.vpcf")
      end
    end
  end
end

function modifier_oaa_arcane_orb:OnAttackFinished(event)
  local parent = self:GetParent()
  if event.attacker == parent then
    -- This happens even during a normal attack
    parent:RemoveModifierByName("modifier_oaa_arcane_orb_sound")

    -- Change the projectile (if a parent doesn't have modifier_oaa_arcane_orb_sound)
    parent:ChangeAttackProjectile()
  end
end

function modifier_oaa_arcane_orb:OnAttackLanded(event)
  local parent = self:GetParent()
  local ability = self:GetAbility()
  local target = event.target

  if event.attacker ~= parent then
    return
  end

  -- To prevent crashes:
  if target == nil then
    return
  end

  if target:IsNull() then
    return
  end

  if ability:IsOwnersManaEnough() and ability:IsCooldownReady() and (not parent:IsSilenced()) and (not target:IsMagicImmune()) then
    if ability:GetAutoCastState() == true then
      -- The Attack while Autocast is ON
      self:ArcaneOrbEffect(event)
    else
      -- The Attack while Autocast is OFF
      if self.manual_cast then
        self:ArcaneOrbEffect(event)
      end
    end
  end
end

function modifier_oaa_arcane_orb:ArcaneOrbEffect(event)
  if IsServer() and event then
    local attacker = event.attacker or self:GetParent()
    local target = event.target
    local ability = self:GetAbility()

    if attacker:IsIllusion() then
      return
    end

    -- to prevent crashes:
    if target:IsNull() then
      return
    end

    -- Don't affect buildings, wards, spell immune units and invulnerable units.
    if target:IsTower() or target:IsBarracks() or target:IsBuilding() or target:IsOther() or target:IsMagicImmune() or target:IsInvulnerable() then
      return
    end

    local mana_pool_damage_pct = ability:GetSpecialValueFor("mana_pool_damage_pct")

    -- Talent that increases mana pool damage percent
    if attacker:HasLearnedAbility("special_bonus_unique_outworld_devourer") then
      mana_pool_damage_pct = mana_pool_damage_pct + attacker:FindAbilityByName("special_bonus_unique_outworld_devourer"):GetSpecialValueFor("value")
    end

    local bonusDamage = attacker:GetMana() * mana_pool_damage_pct/100
    local player = attacker:GetPlayerOwner()
    local point = target:GetAbsOrigin()

    local damage_table = {}
    damage_table.attacker = attacker
    damage_table.damage_type = ability:GetAbilityDamageType()
    damage_table.ability = ability
    damage_table.damage = bonusDamage
    damage_table.victim = target

    -- Apply bonus damage to the attacked target
    ApplyDamage(damage_table)
    SendOverheadEventMessage(player, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, target, bonusDamage, player)
    target:EmitSound("Hero_ObsidianDestroyer.ArcaneOrb.Impact")

    -- Intelligence steal if the target is a real hero (and not a meepo clone or arc warden tempest double)
    if target:IsRealHero() and (not target:IsClone()) and (not target:IsTempestDouble()) then
      local intStealDuration = ability:GetSpecialValueFor("int_steal_duration")
      local intStealAmount = ability:GetSpecialValueFor("int_steal")

      if intStealAmount ~= 0 and intStealDuration ~= 0 then
        -- Talent that increases int steal duration
        if attacker:HasLearnedAbility("special_bonus_unique_outworld_devourer") then
          intStealDuration = intStealDuration + attacker:FindAbilityByName("special_bonus_unique_outworld_devourer"):GetSpecialValueFor("value")
        end

        target:AddNewModifier(attacker, ability, "modifier_oaa_arcane_orb_debuff_counter", {duration = intStealDuration})
        target:AddNewModifier(attacker, ability, "modifier_oaa_arcane_orb_debuff", {duration = intStealDuration})
        attacker:AddNewModifier(attacker, ability, "modifier_oaa_arcane_orb_buff_counter", {duration = intStealDuration})
        attacker:AddNewModifier(attacker, ability, "modifier_oaa_arcane_orb_buff", {duration = intStealDuration})
      end
    end

    -- Mana increase if the target is a hero, an illusion or tempest double
    if target:IsRealHero() or target:IsIllusion() then
      local manaIncreaseAmount = ability:GetSpecialValueFor("max_mana_increase")
      local manaIncreaseDuration = ability:GetSpecialValueFor("bonus_mana_duration")

      if manaIncreaseAmount ~= 0 and manaIncreaseDuration ~= 0 then
        attacker:AddNewModifier(attacker, ability, "modifier_oaa_arcane_orb_mana_buff_counter", {duration = manaIncreaseDuration})
        attacker:AddNewModifier(attacker, ability, "modifier_oaa_arcane_orb_mana_buff", {duration = manaIncreaseDuration})
      end
    end

    -- Splash damage around the target
    local radius = ability:GetSpecialValueFor("radius")
    if radius ~= 0 then
      local target_team = DOTA_UNIT_TARGET_TEAM_ENEMY
      local target_type = bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO)
      local target_flags = DOTA_UNIT_TARGET_FLAG_NONE

      local enemies = FindUnitsInRadius(attacker:GetTeamNumber(), point, nil, radius, target_team, target_type, target_flags, FIND_ANY_ORDER, false)
      for _, enemy in ipairs(enemies) do
        if enemy ~= target then
          damage_table.victim = enemy
          ApplyDamage(damage_table)
          SendOverheadEventMessage(player, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, enemy, bonusDamage, player)
        end
      end
    end

    -- Use mana and trigger cd while respecting reductions
    --ability:UseResources(true, false, true)
    ability:CastAbility()

    self.manual_cast = nil
  end
end
--------------------------------------------------------------------------------

modifier_oaa_arcane_orb_sound = class(ModifierBaseClass)

function modifier_oaa_arcane_orb_sound:IsHidden()
  return true
end

function modifier_oaa_arcane_orb_sound:IsDebuff()
  return false
end

function modifier_oaa_arcane_orb_sound:IsPurgable()
  return false
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
  return -self.intStealAmount
end

-------------------------------------------------------------------------------------------------------------

modifier_oaa_arcane_orb_mana_buff_counter = class(ModifierBaseClass)

function modifier_oaa_arcane_orb_mana_buff_counter:IsPurgable()
  return false
end

function modifier_oaa_arcane_orb_mana_buff_counter:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_TOOLTIP
  }
end

function modifier_oaa_arcane_orb_mana_buff_counter:OnTooltip()
  local mana_increase = self:GetAbility():GetSpecialValueFor("max_mana_increase")
  return mana_increase * self:GetStackCount()
end

--------------------------------------------------------------------------------

modifier_oaa_arcane_orb_mana_buff = class(ModifierBaseClass)

function modifier_oaa_arcane_orb_mana_buff:IsPurgable()
  return false
end

function modifier_oaa_arcane_orb_mana_buff:IsHidden()
  return true
end

function modifier_oaa_arcane_orb_mana_buff:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_oaa_arcane_orb_mana_buff:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MANA_BONUS
  }
end

function modifier_oaa_arcane_orb_mana_buff:OnCreated()
  if IsServer() then
    local counterMod = self:GetParent():FindModifierByName("modifier_oaa_arcane_orb_mana_buff_counter")
    if counterMod and not counterMod:IsNull() then
      counterMod:SetStackCount(counterMod:GetStackCount() + 1)
    end
  end
end

if IsServer() then
  function modifier_oaa_arcane_orb_mana_buff:OnDestroy()
    local counterMod = self:GetParent():FindModifierByName("modifier_oaa_arcane_orb_mana_buff_counter")
    if counterMod and not counterMod:IsNull() then
      counterMod:SetStackCount(counterMod:GetStackCount() - 1)
    end
  end
end

function modifier_oaa_arcane_orb_mana_buff:GetModifierManaBonus()
  return self:GetAbility():GetSpecialValueFor("max_mana_increase")
end
