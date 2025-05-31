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

function obsidian_destroyer_arcane_orb_oaa:GetManaCost(nLevel)
  local caster = self:GetCaster() or self:GetOwner()
  local mana_cost_percentage = self:GetSpecialValueFor("mana_cost_percentage")
  local caster_current_mana = caster:GetMana()

  return caster_current_mana*mana_cost_percentage/100
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

function modifier_oaa_arcane_orb:OnCreated()
  if not IsServer() then
    return
  end
  if not self.procRecords then
    self.procRecords = {}
  end
end

modifier_oaa_arcane_orb.OnRefresh = modifier_oaa_arcane_orb.OnCreated

function modifier_oaa_arcane_orb:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_ATTACK_START,
    MODIFIER_EVENT_ON_ATTACK,
    MODIFIER_EVENT_ON_ATTACK_LANDED,
    MODIFIER_EVENT_ON_ATTACK_FAIL,
    MODIFIER_EVENT_ON_ATTACK_FINISHED
  }
end

if IsServer() then
  function modifier_oaa_arcane_orb:OnAttackStart(event)
    -- OnAttackStart event is triggering before OnAttack event
    local parent = self:GetParent()
    local ability = self:GetAbility()
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

    if parent:IsIllusion() then
      return
    end

    -- Check if attacked unit exists
    if not target or target:IsNull() then
      return
    end

    -- Check for existence of GetUnitName method to determine if target is a unit or an item
    -- items don't have that method -> nil; if the target is an item, don't continue
    if target.GetUnitName == nil then
      return
    end

    if ability:IsOwnersManaEnough() and ability:IsCooldownReady() and (not parent:IsSilenced()) and (not target:IsMagicImmune()) then
      if ability:GetAutoCastState() == true or parent:GetCurrentActiveAbility() == ability then
        --The Attack while Autocast is ON or manually casted (current active ability)

        -- Add modifier to change attack sound
        parent:AddNewModifier(parent, ability, "modifier_oaa_arcane_orb_sound", {})

        -- Change Attack Projectile
        parent:ChangeAttackProjectile()
      end
    end
  end

  function modifier_oaa_arcane_orb:OnAttack(event)
    local parent = self:GetParent()
    local ability = self:GetAbility()
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

    if parent:IsIllusion() then
      return
    end

    -- Check if attacked unit exists
    if not target or target:IsNull() then
      return
    end

    -- Check for existence of GetUnitName method to determine if target is a unit or an item
    -- items don't have that method -> nil; if the target is an item, don't continue
    if target.GetUnitName == nil then
      return
    end

    if ability:IsOwnersManaEnough() and ability:IsCooldownReady() and (not parent:IsSilenced()) and (not target:IsMagicImmune()) then
      if ability:GetAutoCastState() == true or parent:GetCurrentActiveAbility() == ability then
        --The Attack while Autocast is ON or or manually casted (current active ability)

        -- Enable proc for this attack record number (event.record is the same for OnAttackLanded)
        self.procRecords[event.record] = true

        -- Using attack modifier abilities doesn't actually fire any cast events so we need to do it manually
        -- Using CastAbility (ability needs to have OnSpellStart()) to trigger Essence Flux
        ability:CastAbility()

        -- Changing projectile back is too early during OnAttack,
        -- Changing projectile back is done by removing modifier_oaa_arcane_orb_sound from the parent
        -- it should be done during OnAttackFinished;
      end
    end
  end

  function modifier_oaa_arcane_orb:OnAttackFinished(event)
    local parent = self:GetParent()
    if event.attacker == parent then
      -- Remove modifier on every finished attack even if its a normal attack
      parent:RemoveModifierByName("modifier_oaa_arcane_orb_sound")

      -- Change the projectile (if a parent doesn't have modifier_oaa_arcane_orb_sound)
      parent:ChangeAttackProjectile()
    end
  end

  function modifier_oaa_arcane_orb:OnAttackLanded(event)
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

    if parent:IsIllusion() then
      return
    end

    -- Check if attacked unit exists
    if not target or target:IsNull() then
      return
    end

    -- Check if attacked entity is an item, rune or something weird
    if target.GetUnitName == nil then
      return
    end

    if self.procRecords[event.record] and not target:IsMagicImmune() then
      self:ArcaneOrbEffect(event)
    end
  end

  function modifier_oaa_arcane_orb:OnAttackFail(event)
    local parent = self:GetParent()

    if event.attacker == parent and self.procRecords[event.record] then
      self.procRecords[event.record] = nil
    end
  end

  function modifier_oaa_arcane_orb:ArcaneOrbEffect(event)
    if event then
      local attacker = event.attacker or self:GetParent()
      local target = event.target
      local ability = self:GetAbility()

      -- Don't affect buildings, wards, spell immune units and invulnerable units.
      if target:IsTower() or target:IsBarracks() or target:IsBuilding() or target:IsOther() or target:IsMagicImmune() or target:IsInvulnerable() then
        return
      end

      local mana_pool_damage_pct = ability:GetSpecialValueFor("mana_pool_damage_pct")

      -- Talent that increases mana pool damage percent - done through kv
      --if attacker:HasLearnedAbility("special_bonus_unique_outworld_devourer") then
        --mana_pool_damage_pct = mana_pool_damage_pct + 2
      --end

      -- Intelligence steal if the target is a real hero (and not a meepo clone or arc warden tempest double) - UNUSED
      if target:IsRealHero() and (not target:IsClone()) and (not target:IsTempestDouble()) then
        local intStealDuration = ability:GetSpecialValueFor("int_steal_duration")
        local intStealAmount = ability:GetSpecialValueFor("int_steal")

        if intStealAmount ~= 0 and intStealDuration ~= 0 then
          target:AddNewModifier(attacker, ability, "modifier_oaa_arcane_orb_debuff_counter", {duration = intStealDuration})
          target:AddNewModifier(attacker, ability, "modifier_oaa_arcane_orb_debuff", {duration = intStealDuration})
          attacker:AddNewModifier(attacker, ability, "modifier_oaa_arcane_orb_buff_counter", {duration = intStealDuration})
          attacker:AddNewModifier(attacker, ability, "modifier_oaa_arcane_orb_buff", {duration = intStealDuration})
        end
      end

      -- Mana increase if the target is a hero, an illusion or tempest double - UNUSED
      if target:IsRealHero() or target:IsIllusion() then
        local manaIncreaseAmount = ability:GetSpecialValueFor("max_mana_increase")
        local manaIncreaseDuration = ability:GetSpecialValueFor("bonus_mana_duration")

        if manaIncreaseAmount ~= 0 and manaIncreaseDuration ~= 0 then
          attacker:AddNewModifier(attacker, ability, "modifier_oaa_arcane_orb_mana_buff_counter", {duration = manaIncreaseDuration})
          attacker:AddNewModifier(attacker, ability, "modifier_oaa_arcane_orb_mana_buff", {duration = manaIncreaseDuration})
        end
      end

      local bonus_damage = attacker:GetMana() * mana_pool_damage_pct * 0.01
      local point = target:GetAbsOrigin() -- store the location before we apply damage to the target

      -- Primary damage table
      local damage_table_1 = {
        attacker = attacker,
        victim = target,
        damage = bonus_damage,
        damage_type = ability:GetAbilityDamageType(),
        ability = ability,
      }

      -- Splash damage table
      local damage_table_2 = {
        attacker = attacker,
        damage_type = ability:GetAbilityDamageType(),
        ability = ability,
      }

      target:EmitSound("Hero_ObsidianDestroyer.ArcaneOrb.Impact")

      -- Splash damage around the target (after dealing damage to the attacked target)
      local radius = ability:GetSpecialValueFor("radius")
      local splash_pct = ability:GetSpecialValueFor("splash_damage_percent")
      if radius ~= 0 and splash_pct ~= 0 then
        local target_team = DOTA_UNIT_TARGET_TEAM_ENEMY
        local target_type = bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO)
        local target_flags = DOTA_UNIT_TARGET_FLAG_NONE
        local splash_damage = bonus_damage * splash_pct * 0.01
        damage_table_2.damage = splash_damage

        local enemies = FindUnitsInRadius(attacker:GetTeamNumber(), point, nil, radius, target_team, target_type, target_flags, FIND_ANY_ORDER, false)
        for _, enemy in pairs(enemies) do
          if enemy and not enemy:IsNull() and enemy ~= target then
            damage_table_2.victim = enemy

            ApplyDamage(damage_table_2)
          end
        end
      end

      -- Overhead particle message
      SendOverheadEventMessage(nil, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, target, bonus_damage, nil)

      -- Apply bonus damage to the attacked target
      ApplyDamage(damage_table_1)

      self.procRecords[event.record] = nil
    end
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
