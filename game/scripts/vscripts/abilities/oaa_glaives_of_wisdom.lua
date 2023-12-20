LinkLuaModifier("modifier_oaa_glaives_of_wisdom", "abilities/oaa_glaives_of_wisdom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_oaa_glaives_of_wisdom_fx", "abilities/oaa_glaives_of_wisdom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_oaa_int_steal", "abilities/oaa_glaives_of_wisdom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_oaa_glaives_buff_counter", "abilities/oaa_glaives_of_wisdom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_oaa_glaives_buff", "abilities/oaa_glaives_of_wisdom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_oaa_glaives_debuff_counter", "abilities/oaa_glaives_of_wisdom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_oaa_glaives_debuff", "abilities/oaa_glaives_of_wisdom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_oaa_glaives_shard_silence", "abilities/oaa_glaives_of_wisdom.lua", LUA_MODIFIER_MOTION_NONE)

silencer_glaives_of_wisdom_oaa = class(AbilityBaseClass)

function silencer_glaives_of_wisdom_oaa:GetIntrinsicModifierName()
  return "modifier_oaa_glaives_of_wisdom"
end

function silencer_glaives_of_wisdom_oaa:CastFilterResultTarget(target)
  local defaultResult = self.BaseClass.CastFilterResultTarget(self, target)
  local caster = self:GetCaster()

  -- Talent that allows Glaives of Wisdom to pierce spell immunity
  local pierce_bkb = false
  local talent = caster:FindAbilityByName("special_bonus_unique_silencer_3_oaa")
  if talent and talent:GetLevel() > 0 then
    pierce_bkb = true
  end

  if pierce_bkb and defaultResult == UF_FAIL_MAGIC_IMMUNE_ENEMY then
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

function silencer_glaives_of_wisdom_oaa:OnProjectileHit_ExtraData(target, location, data)
  -- Source of the damage
  local caster = self:GetCaster()

  -- If the caster doesn't have talent, don't continue
  local talent1 = caster:FindAbilityByName("special_bonus_unique_silencer_glaives_bounces")
  if not talent1 then
    return
  elseif talent1:GetLevel() <= 0 then
    return
  end

  -- If there is no target or data, don't continue
  if not target or not data then
    return
  end

  -- Get damage reduction
  local bounce_damage_reduction = self:GetSpecialValueFor("bounce_damage_reduction")

  -- Physical damage of the bounced projectile
  local bounce_damage = data.physical_damage * bounce_damage_reduction * 0.01

  -- Spell damage of the bounced projectile
  local glaives_damage = data.spell_damage * bounce_damage_reduction * 0.01

  -- Number of bounces left (Data of the current projectile is read-only !!!)
  local bounces_left = data.bounces_left

  -- Talent that allows Glaives of Wisdom to pierce spell immunity
  local pierce_bkb = false
  local talent2 = caster:FindAbilityByName("special_bonus_unique_silencer_3_oaa")
  if talent2 and talent2:GetLevel() > 0 then
    pierce_bkb = true
  end

  -- Intelligence steal if the target is a real hero (and not a meepo clone or arc warden tempest double) and not spell immune
  if target:IsRealHero() and not target:IsClone() and not target:IsTempestDouble() then
    if pierce_bkb or not target:IsMagicImmune() then
      local intStealDuration = self:GetSpecialValueFor("int_steal_duration")
      local intStealAmount = self:GetSpecialValueFor("int_steal")

      -- Shard increase for temporary INT steal
      if caster:HasShardOAA() then
        intStealAmount = intStealAmount + self:GetSpecialValueFor("shard_int_steal_amount_bonus")
      end

      if intStealAmount ~= 0 and intStealDuration ~= 0 then
        target:AddNewModifier(caster, self, "modifier_oaa_glaives_debuff_counter", {duration = intStealDuration})
        target:AddNewModifier(caster, self, "modifier_oaa_glaives_debuff", {duration = intStealDuration})
        caster:AddNewModifier(caster, self, "modifier_oaa_glaives_buff_counter", {duration = intStealDuration})
        caster:AddNewModifier(caster, self, "modifier_oaa_glaives_buff", {duration = intStealDuration})
      end
    end
  end

  -- Damage table of the bounced projectile (physical part)
  local damage_table_1 = {
    attacker = caster,
    victim = target,
    damage = bounce_damage,
    damage_type = DAMAGE_TYPE_PHYSICAL,
  }

  -- Damage table of the bounced projectile (Glaives of Wisdom spell damage)
  local damage_table_2 = {
    attacker = caster,
    victim = target,
    damage = glaives_damage,
    damage_type = self:GetAbilityDamageType(),
    ability = self,
  }

  -- Sound
  target:EmitSound("Hero_Silencer.GlaivesOfWisdom.Damage")

  -- Create more bounces if there are more left
  if bounces_left > 0 then
    -- Data of the current projectile is read-only !!!

    local bounce_radius = self:GetSpecialValueFor("bounce_range")
    local target_flags = DOTA_UNIT_TARGET_FLAG_NO_INVIS

    -- Talent that allows Glaives of Wisdom to pierce spell immunity
    if pierce_bkb then
      target_flags = bit.bor(target_flags, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES)
    end

    -- Find enemies near the target's hit location
    local enemies = FindUnitsInRadius(
      caster:GetTeamNumber(),
      target:GetAbsOrigin(),
      nil,
      bounce_radius,
      DOTA_UNIT_TARGET_TEAM_ENEMY,
      bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC),
      target_flags,
      FIND_CLOSEST,
      false
    )

    if #enemies > 0 then
      for _, enemy in ipairs(enemies) do
        if enemy and enemy ~= target and not enemy:IsAttackImmune() then
          local projectile_info = {
            Target = enemy,
            Source = target,
            Ability = self,
            EffectName = "particles/units/heroes/hero_silencer/silencer_glaives_of_wisdom.vpcf",
            bDodgable = true,
            bProvidesVision = false,
            bVisibleToEnemies = true,
            bReplaceExisting = false,
            iMoveSpeed = caster:GetProjectileSpeed(),
            bIsAttack = false,
            iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_HITLOCATION,--DOTA_PROJECTILE_ATTACHMENT_ATTACK_1,
            ExtraData = {
              bounces_left = bounces_left - 1,
              physical_damage = bounce_damage,
              spell_damage = glaives_damage
            }
          }

          -- Create glaive bounce
          ProjectileManager:CreateTrackingProjectile(projectile_info)

          break
        end
      end
    end
	end

  ApplyDamage(damage_table_1)

  -- Check if attacker and victim survived previous damage instance
  if caster and not caster:IsNull() and target and not target:IsNull() and target:IsAlive() then
    -- Overhead particle message
    SendOverheadEventMessage(caster:GetPlayerOwner(), OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, target, glaives_damage, caster:GetPlayerOwner())
    -- Do Glaives of Wisdom damage
    ApplyDamage(damage_table_2)
  end
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

if IsServer() then
  function modifier_oaa_glaives_of_wisdom:OnAttackStart(event)
    -- OnAttackStart event is triggering before OnAttack event
    -- Only AttackStart is early enough to override the projectile
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

    if ability:IsOwnersManaEnough() and ability:IsCooldownReady() and (not parent:IsSilenced()) and (ability:CastFilterResultTarget(target) == UF_SUCCESS) then
      if ability:GetAutoCastState() == true or parent:GetCurrentActiveAbility() == ability then
        -- The Attack while Autocast is ON or manually casted (current active ability)

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

    if ability:IsOwnersManaEnough() and ability:IsCooldownReady() and (not parent:IsSilenced()) and (ability:CastFilterResultTarget(target) == UF_SUCCESS) then
      if ability:GetAutoCastState() == true or parent:GetCurrentActiveAbility() == ability then
        --The Attack while Autocast is ON or or manually casted (current active ability)

        -- Enable proc for this attack record number (event.record is the same for OnAttackLanded)
        self.procRecords[event.record] = true

        -- Use mana and trigger cd while respecting reductions
        -- Using attack modifier abilities doesn't actually fire any cast events so we need to use resources here
        ability:UseResources(true, false, false, true)

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

    if self.procRecords[event.record] and ability:CastFilterResultTarget(target) == UF_SUCCESS then
      local bonusDamagePct = ability:GetSpecialValueFor("intellect_damage_pct") / 100
      local player = parent:GetPlayerOwner()

      -- Talent that increases Glaives of Wisdom damage (done through kv)
      --local talent = parent:FindAbilityByName("special_bonus_unique_silencer_3")
      --if talent and talent:GetLevel() > 0 then
        --bonusDamagePct = bonusDamagePct + 10
      --end

      -- Talent that allows Glaives of Wisdom to pierce spell immunity
      local pierce_bkb = false
      local talent2 = parent:FindAbilityByName("special_bonus_unique_silencer_3_oaa")
      if talent2 and talent2:GetLevel() > 0 then
        pierce_bkb = true
      end

      --if parent:HasScepter() and target:IsSilenced() then
        --bonusDamagePct = bonusDamagePct * ability:GetSpecialValueFor("scepter_damage_multiplier")
      --end

      if parent:HasShardOAA() then
        if not self.number_of_attacks then
          self.number_of_attacks = 0
        else
          self.number_of_attacks = self.number_of_attacks + 1
        end

        local number = ability:GetSpecialValueFor("shard_attacks_for_silence")
        if self.number_of_attacks > 0 and (self.number_of_attacks % number == 0) then
          target:AddNewModifier(parent, ability, "modifier_oaa_glaives_shard_silence", {duration = ability:GetSpecialValueFor("shard_silence_duration")})
        end
      end

      -- Intelligence steal if the target is a real hero (and not a meepo clone or arc warden tempest double)
      if target:IsRealHero() and not target:IsClone() and not target:IsTempestDouble() then
        if pierce_bkb or not target:IsMagicImmune() then
          local intStealDuration = ability:GetSpecialValueFor("int_steal_duration")
          local intStealAmount = ability:GetSpecialValueFor("int_steal")

          -- Shard increase for temporary INT steal
          if parent:HasShardOAA() then
            intStealAmount = intStealAmount + ability:GetSpecialValueFor("shard_int_steal_amount_bonus")
          end

          if intStealAmount ~= 0 and intStealDuration ~= 0 then
            target:AddNewModifier(parent, ability, "modifier_oaa_glaives_debuff_counter", {duration = intStealDuration})
            target:AddNewModifier(parent, ability, "modifier_oaa_glaives_debuff", {duration = intStealDuration})
            parent:AddNewModifier(parent, ability, "modifier_oaa_glaives_buff_counter", {duration = intStealDuration})
            parent:AddNewModifier(parent, ability, "modifier_oaa_glaives_buff", {duration = intStealDuration})
          end
        end
      end

      local bonusDamage = parent:GetIntellect() * bonusDamagePct

      local damageTable = {
        attacker = parent,
        victim = target,
        damage = bonusDamage,
        damage_type = ability:GetAbilityDamageType(),
        ability = ability,
      }

      --if parent:HasScepter() and target:IsMagicImmune() then
        --damageTable.damage_type = DAMAGE_TYPE_PHYSICAL
        --damageTable.damage_flags = DOTA_DAMAGE_FLAG_BYPASSES_BLOCK
      --end

      -- Sound
      target:EmitSound("Hero_Silencer.GlaivesOfWisdom.Damage")

      local talent3 = parent:FindAbilityByName("special_bonus_unique_silencer_glaives_bounces")
      if talent3 and talent3:GetLevel() > 0 then
        local bounce_radius = ability:GetSpecialValueFor("bounce_range")
        local number_of_bounces = ability:GetSpecialValueFor("bounce_count")
        local target_flags = DOTA_UNIT_TARGET_FLAG_NO_INVIS

        if pierce_bkb then
          target_flags = bit.bor(target_flags, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES)
        end

        -- Find enemies near the target's hit location
        local enemies = FindUnitsInRadius(
          parent:GetTeamNumber(),
          target:GetAbsOrigin(),
          nil,
          bounce_radius,
          DOTA_UNIT_TARGET_TEAM_ENEMY,
          bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC),
          target_flags,
          FIND_CLOSEST,
          false
        )

        if #enemies > 0 and number_of_bounces > 0 then
          for _, enemy in ipairs(enemies) do
            if enemy and enemy ~= target and not enemy:IsAttackImmune() then
              local projectile_info = {
                Target = enemy,
                Source = target,
                Ability = ability,
                EffectName = "particles/units/heroes/hero_silencer/silencer_glaives_of_wisdom.vpcf",
                bDodgable = true,
                bProvidesVision = false,
                bVisibleToEnemies = true,
                bReplaceExisting = false,
                iMoveSpeed = parent:GetProjectileSpeed(),
                bIsAttack = false,
                iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_HITLOCATION,--DOTA_PROJECTILE_ATTACHMENT_ATTACK_1,
                ExtraData = {
                  bounces_left = number_of_bounces - 1,
                  physical_damage = event.damage,
                  spell_damage = bonusDamage
                }
              }

              -- Create glaive bounce
              ProjectileManager:CreateTrackingProjectile(projectile_info)

              break
            end
          end
        end
      end

      -- Overhead particle message
      SendOverheadEventMessage(player, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, target, bonusDamage, player)

      -- Do Glaives of Wisdom damage
      ApplyDamage(damageTable)

      self.procRecords[event.record] = nil
    end
  end

  function modifier_oaa_glaives_of_wisdom:OnAttackFail(event)
    local parent = self:GetParent()

    if event.attacker == parent and self.procRecords[event.record] then
      self.procRecords[event.record] = nil
    end
  end
end

--------------------------------------------------------------------------------

modifier_oaa_glaives_of_wisdom_fx = class(ModifierBaseClass)

function modifier_oaa_glaives_of_wisdom_fx:IsHidden()
  return true
end

function modifier_oaa_glaives_of_wisdom_fx:IsDebuff()
  return false
end

function modifier_oaa_glaives_of_wisdom_fx:IsPurgable()
  return false
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
    MODIFIER_EVENT_ON_DEATH,
  }
end

if IsServer() then
  function modifier_oaa_int_steal:OnDeath(keys)
    local parent = self:GetParent()
    local ability = self:GetAbility()
    local stealRange = ability:GetSpecialValueFor("permanent_int_steal_range")
    local stealAmount = ability:GetSpecialValueFor("permanent_int_steal_amount")
    local unit = keys.unit
    local filterResult = UnitFilter(
      unit,
      DOTA_UNIT_TARGET_TEAM_ENEMY,
      DOTA_UNIT_TARGET_HERO,
      bit.bor(DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, DOTA_UNIT_TARGET_FLAG_DEAD),
      parent:GetTeamNumber()
    )
    if HeroSelection.is10v10 then
      stealRange = 450
    end
    local isWithinRange = #(unit:GetAbsOrigin() - parent:GetAbsOrigin()) <= stealRange

    -- Shard increase for permanent INT steal
    if parent:HasShardOAA() then
      stealAmount = stealAmount + ability:GetSpecialValueFor("shard_int_steal_amount_bonus")
    end

    if filterResult == UF_SUCCESS and (keys.attacker == parent or isWithinRange) and parent:IsRealHero() and parent:IsAlive() and unit:IsRealHero() and not unit:IsClone() and not unit:IsTempestDouble() then
      local oldIntellect = unit:GetBaseIntellect()
      unit:SetBaseIntellect(math.max(1, oldIntellect - stealAmount))
      unit:CalculateStatBonus(true)
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
  local ability = self:GetAbility()
  local intStealAmount = ability:GetSpecialValueFor("int_steal")
  -- Shard increase for temporary INT steal
  if self:GetCaster():HasShardOAA() then
    intStealAmount = intStealAmount + ability:GetSpecialValueFor("shard_int_steal_amount_bonus")
  end
  self.intStealAmount = intStealAmount
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
  local ability = self:GetAbility()
  local intStealAmount = ability:GetSpecialValueFor("int_steal")
  -- Shard increase for temporary INT steal
  if self:GetCaster():HasShardOAA() then
    intStealAmount = intStealAmount + ability:GetSpecialValueFor("shard_int_steal_amount_bonus")
  end
  self.intStealAmount = intStealAmount
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

---------------------------------------------------------------------------------------------------

modifier_oaa_glaives_shard_silence = class(ModifierBaseClass)

function modifier_oaa_glaives_shard_silence:IsHidden()
	return true
end

function modifier_oaa_glaives_shard_silence:IsDebuff()
	return true
end

function modifier_oaa_glaives_shard_silence:IsPurgable()
	return true
end

function modifier_oaa_glaives_shard_silence:GetEffectName()
	return "particles/generic_gameplay/generic_silenced.vpcf"
end

function modifier_oaa_glaives_shard_silence:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW
end

function modifier_oaa_glaives_shard_silence:CheckState()
  return {
    [MODIFIER_STATE_SILENCED] = true,
  }
end
