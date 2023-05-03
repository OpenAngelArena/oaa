LinkLuaModifier("modifier_nevermore_dark_lord_oaa", "abilities/oaa_nevermore_dark_lord.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_nevermore_dark_lord_oaa_armor_debuff", "abilities/oaa_nevermore_dark_lord.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_nevermore_dark_lord_oaa_kill_stack", "abilities/oaa_nevermore_dark_lord.lua", LUA_MODIFIER_MOTION_NONE)

nevermore_dark_lord_oaa = class(AbilityBaseClass)

function nevermore_dark_lord_oaa:GetIntrinsicModifierName()
  return "modifier_nevermore_dark_lord_oaa"
end

---------------------------------------------------------------------------------------------------

modifier_nevermore_dark_lord_oaa = class(ModifierBaseClass)

function modifier_nevermore_dark_lord_oaa:IsHidden()
  return true
end

function modifier_nevermore_dark_lord_oaa:IsPurgable()
  return false
end

function modifier_nevermore_dark_lord_oaa:RemoveOnDeath()
  return false
end

function modifier_nevermore_dark_lord_oaa:IsAura()
  if self:GetParent():PassivesDisabled() then
    return false
  end
  return true
end

function modifier_nevermore_dark_lord_oaa:GetModifierAura()
  return "modifier_nevermore_dark_lord_oaa_armor_debuff"
end

function modifier_nevermore_dark_lord_oaa:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_nevermore_dark_lord_oaa:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC)
end

function modifier_nevermore_dark_lord_oaa:GetAuraSearchFlags()
  return DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
end

function modifier_nevermore_dark_lord_oaa:GetAuraRadius()
  return self:GetAbility():GetSpecialValueFor("aura_radius")
end

function modifier_nevermore_dark_lord_oaa:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_DEATH,
  }
end

if IsServer() then
  function modifier_nevermore_dark_lord_oaa:OnDeath(event)
    local parent = self:GetParent()
    local dead = event.unit
    local ability = self:GetAbility()

    -- Don't continue for illusions
    if not parent or parent:IsNull() or not parent:IsRealHero() then
      return
    end

    if parent ~= dead then
      -- Dead unit is not on parent's team
      if parent:GetTeamNumber() ~= dead:GetTeamNumber() then
        -- Dead unit is an actually dead real enemy hero unit or a boss
        if (dead:IsRealHero() and not dead:IsTempestDouble() and not dead:IsReincarnating() and not dead:IsClone()) or dead:IsOAABoss() then
          local parentToDeadVector = dead:GetAbsOrigin() - parent:GetAbsOrigin()
          local isDeadInRange = parentToDeadVector:Length2D() <= ability:GetSpecialValueFor("aura_radius")

          -- Stack gain - only if parent is near the dead unit
          if isDeadInRange then
            parent:AddNewModifier(parent, ability, "modifier_nevermore_dark_lord_oaa_kill_stack", {duration = ability:GetSpecialValueFor("kill_buff_duration")})
          end
        end
      end
    end
  end
end

---------------------------------------------------------------------------------------------------

modifier_nevermore_dark_lord_oaa_armor_debuff = class(ModifierBaseClass)

function modifier_nevermore_dark_lord_oaa_armor_debuff:IsHidden()
  return true
end

function modifier_nevermore_dark_lord_oaa_armor_debuff:IsDebuff()
  return true
end

function modifier_nevermore_dark_lord_oaa_armor_debuff:IsPurgable()
  return false
end

function modifier_nevermore_dark_lord_oaa_armor_debuff:OnCreated()
  local ability = self:GetAbility()
  local caster = self:GetCaster()
  if not ability or ability:IsNull() then
    return
  end

  local armor_reduction = ability:GetSpecialValueFor("armor_reduction")

  -- Talent that improves armor reduction
  local talent = caster:FindAbilityByName("special_bonus_unique_nevermore_1_oaa")
  if talent and talent:GetLevel() > 0 then
    armor_reduction = math.abs(armor_reduction) + math.abs(talent:GetSpecialValueFor("value"))
  end

  self.armor_reduction = armor_reduction
  self.armor_reduction_per_stack = ability:GetSpecialValueFor("bonus_armor_per_stack")

  --self.magic_resistance = 0
  --if caster:HasShardOAA() then
    --self.magic_resistance = -14
  --end
end

modifier_nevermore_dark_lord_oaa_armor_debuff.OnRefresh = modifier_nevermore_dark_lord_oaa_armor_debuff.OnCreated

function modifier_nevermore_dark_lord_oaa_armor_debuff:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
    --MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
  }
end

function modifier_nevermore_dark_lord_oaa_armor_debuff:GetModifierPhysicalArmorBonus()
  local base_armor_reduction = 0 - math.abs(self.armor_reduction)
  local caster = self:GetCaster()
  if not caster or caster:IsNull() then
    return base_armor_reduction
  end
  local stack_buff = caster:HasModifier("modifier_nevermore_dark_lord_oaa_kill_stack")
  if not stack_buff then
    return base_armor_reduction
  end
  local additional_armor_reduction = caster:GetModifierStackCount("modifier_nevermore_dark_lord_oaa_kill_stack", caster) * self.armor_reduction_per_stack
  return base_armor_reduction - math.abs(additional_armor_reduction)
end

-- function modifier_nevermore_dark_lord_oaa_armor_debuff:GetModifierMagicalResistanceBonus()
  -- return self.magic_resistance
-- end

---------------------------------------------------------------------------------------------------

modifier_nevermore_dark_lord_oaa_kill_stack = class(ModifierBaseClass)

function modifier_nevermore_dark_lord_oaa_kill_stack:IsHidden()
  return false
end

function modifier_nevermore_dark_lord_oaa_kill_stack:IsDebuff()
  return false
end

function modifier_nevermore_dark_lord_oaa_kill_stack:IsPurgable()
  return false
end

function modifier_nevermore_dark_lord_oaa_kill_stack:OnCreated()
  if IsServer() then
    self:SetStackCount(1)
  end
end

function modifier_nevermore_dark_lord_oaa_kill_stack:OnRefresh()
  if IsServer() then
    self:IncrementStackCount()
  end
end
