-- Abyssal Force

LinkLuaModifier("modifier_underlord_innate_oaa", "abilities/oaa_underlord_innate.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_underlord_permanent_dmg_increase_oaa", "abilities/oaa_underlord_innate.lua", LUA_MODIFIER_MOTION_NONE) -- needs tooltip
LinkLuaModifier("modifier_underlord_raid_boss_buff_oaa", "abilities/oaa_underlord_innate.lua", LUA_MODIFIER_MOTION_NONE) -- needs tooltip

abyssal_underlord_innate_oaa = class(AbilityBaseClass)

function abyssal_underlord_innate_oaa:Spawn()
  if IsServer() then
    local caster = self:GetCaster()
    if not caster:HasModifier("modifier_underlord_permanent_dmg_increase_oaa") then
      caster:AddNewModifier(caster, self, "modifier_underlord_permanent_dmg_increase_oaa", {})
    end
    --self:SetLevel(1)
  end
end

function abyssal_underlord_innate_oaa:GetIntrinsicModifierName()
  return "modifier_underlord_innate_oaa"
end

---------------------------------------------------------------------------------------------------

modifier_underlord_innate_oaa = class(ModifierBaseClass)

function modifier_underlord_innate_oaa:IsHidden()
  return true
end

function modifier_underlord_innate_oaa:IsDebuff()
  return false
end

function modifier_underlord_innate_oaa:IsPurgable()
  return false
end

function modifier_underlord_innate_oaa:RemoveOnDeath()
  return false
end

function modifier_underlord_innate_oaa:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_DEATH,
    MODIFIER_EVENT_ON_TELEPORTED,
  }
end

if IsServer() then
  function modifier_underlord_innate_oaa:OnDeath(event)
    local caster = self:GetCaster()
    local ability = self:GetAbility()
    local dead = event.unit

    local gain_per_kill = ability:GetSpecialValueFor("damage_gain_per_hero_death")
    local gain_range = ability:GetSpecialValueFor("damage_gain_range")

    if not caster:IsRealHero() or caster:PassivesDisabled() or not caster:IsAlive() then
      return
    end

    local dmg_gain_mod = caster:FindModifierByName("modifier_underlord_permanent_dmg_increase_oaa")
    if not dmg_gain_mod or dmg_gain_mod:IsNull() then
      return
    end

    local current_stacks = dmg_gain_mod:GetStackCount()

    -- Someone other than the caster died
    if caster ~= dead then
      -- Dead unit is not on caster's team
      if caster:GetTeamNumber() ~= dead:GetTeamNumber() then
        -- Dead unit is an actually dead real enemy hero unit or a boss
        if (dead:IsRealHero() and (not dead:IsTempestDouble()) and (not dead:IsReincarnating()) and (not dead:IsClone()) and (not dead:IsSpiritBearOAA())) or dead:IsOAABoss() then
          local casterToDeadVector = dead:GetAbsOrigin() - caster:GetAbsOrigin()
          local isDeadInChargeRange = casterToDeadVector:Length2D() <= gain_range

          -- Stack gain - only if caster is near the dead unit
          if isDeadInChargeRange then
            dmg_gain_mod:SetStackCount(current_stacks + gain_per_kill)
          end
        end
      end
    end
  end

  function modifier_underlord_innate_oaa:OnTeleported(event)
    local caster = self:GetCaster()
    local ability = self:GetAbility()
    local unit = event.unit

    if not unit or unit:IsNull() or not ability or ability:IsNull() then
      return
    end

    if not caster:IsRealHero() or caster:PassivesDisabled() or not caster:IsAlive() then
      return
    end

    -- Affect only allies and self
    if unit:GetTeamNumber() ~= caster:GetTeamNumber() then
      return
    end

    -- Buff Amp
    local real_buff_duration = GetValueChangedByBuffAmplification(ability:GetSpecialValueFor("buff_duration"), unit, caster)

    -- Apply the buff
    unit:AddNewModifier(caster, ability, "modifier_underlord_raid_boss_buff_oaa", {duration = real_buff_duration})
  end
end

---------------------------------------------------------------------------------------------------

modifier_underlord_raid_boss_buff_oaa = class(ModifierBaseClass)

function modifier_underlord_raid_boss_buff_oaa:IsHidden()
  return false
end

function modifier_underlord_raid_boss_buff_oaa:IsDebuff()
  return false
end

function modifier_underlord_raid_boss_buff_oaa:IsPurgable()
  return true
end

function modifier_underlord_raid_boss_buff_oaa:OnCreated()
  local parent = self:GetParent()
  if not parent or parent:IsNull() then
    return
  end
  self.dmg_reduction = 0
  self.move_speed = 10
  local hp_to_shield = 17
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.dmg_reduction = ability:GetSpecialValueFor("damage_reduction")
    self.move_speed = ability:GetSpecialValueFor("bonus_ms")
    hp_to_shield = ability:GetSpecialValueFor("barrier_max_health_pct")
  end

  if parent.GetMaxHealth == nil then
    return
  end

  self.max_shield_hp = math.ceil((hp_to_shield / 100) * parent:GetMaxHealth())

  if IsServer() then
    self:SetStackCount(0 - self.max_shield_hp)
  end
end

modifier_underlord_raid_boss_buff_oaa.OnRefresh = modifier_underlord_raid_boss_buff_oaa.OnCreated

function modifier_underlord_raid_boss_buff_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
    MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    MODIFIER_PROPERTY_INCOMING_PHYSICAL_DAMAGE_CONSTANT,
  }
end

function modifier_underlord_raid_boss_buff_oaa:GetModifierIncomingDamage_Percentage()
  return 0 - math.abs(self.dmg_reduction)
end

function modifier_underlord_raid_boss_buff_oaa:GetModifierMoveSpeedBonus_Percentage()
  return self.move_speed
end

function modifier_underlord_raid_boss_buff_oaa:GetModifierIncomingPhysicalDamageConstant(event)
  if IsClient() then
    if event.report_max then
      return self.max_shield_hp
    else
      return math.abs(self:GetStackCount()) -- current shield hp
    end
  else
    local parent = self:GetParent()
    local damage = event.damage
    local barrier_hp = math.abs(self:GetStackCount())

    -- Don't block more than remaining hp
    local block_amount = math.min(damage, barrier_hp)

    -- Reduce barrier hp (using negative stacks to not show them on the buff)
    self:SetStackCount(block_amount - barrier_hp)

    if block_amount > 0 then
      -- Visual effect
      SendOverheadEventMessage(nil, OVERHEAD_ALERT_BLOCK, parent, block_amount, nil)
    end

    -- Remove the barrier if hp is reduced to nothing
    if self:GetStackCount() >= 0 then
      self:Destroy()
    end

    return -block_amount
  end
end

---------------------------------------------------------------------------------------------------

modifier_underlord_permanent_dmg_increase_oaa = class(ModifierBaseClass)

function modifier_underlord_permanent_dmg_increase_oaa:IsHidden()
  return false
end

function modifier_underlord_permanent_dmg_increase_oaa:IsDebuff()
  return false
end

function modifier_underlord_permanent_dmg_increase_oaa:IsPurgable()
  return false
end

function modifier_underlord_permanent_dmg_increase_oaa:RemoveOnDeath()
  return false
end

function modifier_underlord_permanent_dmg_increase_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
  }
end

function modifier_underlord_permanent_dmg_increase_oaa:GetModifierPreAttack_BonusDamage()
  return self:GetStackCount()
end
