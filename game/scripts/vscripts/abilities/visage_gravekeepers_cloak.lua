LinkLuaModifier("modifier_visage_gravekeepers_cloak_oaa", "abilities/visage_gravekeepers_cloak.lua", LUA_MODIFIER_MOTION_NONE) --- PETH WEFY INPARFANT
LinkLuaModifier("modifier_visage_gravekeepers_cloak_oaa_aura", "abilities/visage_gravekeepers_cloak.lua", LUA_MODIFIER_MOTION_NONE) --- PETH WEFY INPARFANT

visage_gravekeepers_cloak_oaa = class(AbilityBaseClass)

function visage_gravekeepers_cloak_oaa:GetIntrinsicModifierName()
  return "modifier_visage_gravekeepers_cloak_oaa"
end

function visage_gravekeepers_cloak_oaa:OnHeroCalculateStatBonus()
  local caster = self:GetCaster()

  if caster:HasShardOAA() and caster:IsRealHero() and not self.added_stone_form then
    local summon_familiars_ability = caster:FindAbilityByName("visage_summon_familiars_oaa")
    if not summon_familiars_ability then
      return
    end
    local ability_level = summon_familiars_ability:GetLevel()

    local stone_form_ability = caster:FindAbilityByName("visage_summon_familiars_stone_form")
    if stone_form_ability then
      --stone_form_ability:SetHidden(true)
      self.added_stone_form = true
      if ability_level ~= 0 then
        stone_form_ability:SetLevel(ability_level)
      end
    end
  end
end

function visage_gravekeepers_cloak_oaa:GetBehavior()
  if self:GetCaster():HasShardOAA() then
    return DOTA_ABILITY_BEHAVIOR_NO_TARGET + DOTA_ABILITY_BEHAVIOR_IMMEDIATE
  end
  return DOTA_ABILITY_BEHAVIOR_PASSIVE
end

function visage_gravekeepers_cloak_oaa:GetManaCost(level)
  if self:GetCaster():HasShardOAA() then
    return self:GetSpecialValueFor("shard_manacost")
  end

  return 0
end

function visage_gravekeepers_cloak_oaa:GetCooldown(level)
  if self:GetCaster():HasShardOAA() then
    return self:GetSpecialValueFor("shard_cooldown")
  end

  return 0
end

function visage_gravekeepers_cloak_oaa:OnUpgrade()
  local caster = self:GetCaster()
  local mod = caster:FindModifierByName("modifier_visage_gravekeepers_cloak_oaa")
  local max_layers = self:GetSpecialValueFor("max_layers")
  if mod then
    mod:SetStackCount(max_layers)
  end
end

function visage_gravekeepers_cloak_oaa:OnSpellStart()
  local caster = self:GetCaster()
  local stone_form_ability = caster:FindAbilityByName("visage_summon_familiars_stone_form")

  if not stone_form_ability then
    self:RefundManaCost()
    self:EndCooldown()
    return
  end

  if stone_form_ability:GetLevel() == 0 then
    self:RefundManaCost()
    self:EndCooldown()
    return
  end

  --[[ -- this doesn't work for hidden abilities
  ExecuteOrderFromTable({
    UnitIndex = caster:entindex(),
    OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
    AbilityIndex = stone_form_ability:entindex(),
    Queue = false,
  })
  ]]
  stone_form_ability:OnSpellStart()
end

function visage_gravekeepers_cloak_oaa:IsStealable()
  return false
end

function visage_gravekeepers_cloak_oaa:ProcMagicStick()
  if self:GetCaster():HasShardOAA() then
    return true
  end

  return false
end

---------------------------------------------------------------

modifier_visage_gravekeepers_cloak_oaa = class(ModifierBaseClass)

function modifier_visage_gravekeepers_cloak_oaa:IsHidden()
  return false
end

function modifier_visage_gravekeepers_cloak_oaa:IsDebuff()
  return false
end

function modifier_visage_gravekeepers_cloak_oaa:IsPurgable()
  return false
end

function modifier_visage_gravekeepers_cloak_oaa:RemoveOnDeath()
  return false
end

function modifier_visage_gravekeepers_cloak_oaa:OnCreated()
  local caster = self:GetCaster()
  if IsServer() then
    local ability = self:GetAbility()
    local max_layers = ability:GetSpecialValueFor("max_layers")
    self:SetStackCount(max_layers)
  end

  -- Talent that increases armor of Visage
  self.armor = 0
  local talent2 = caster:FindAbilityByName("special_bonus_unique_visage_5")
  if talent2 and talent2:GetLevel() > 0 then
    self.armor = talent2:GetSpecialValueFor("value")
  end
end

modifier_visage_gravekeepers_cloak_oaa.OnRefresh = modifier_visage_gravekeepers_cloak_oaa.OnCreated

function modifier_visage_gravekeepers_cloak_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_TOTAL_CONSTANT_BLOCK,
    MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
  }
end

if IsServer() then
  function modifier_visage_gravekeepers_cloak_oaa:DecreaseStacks()
    local stackCount = self:GetStackCount()
    self:SetStackCount(math.max(0, stackCount - 1))
  end

  function modifier_visage_gravekeepers_cloak_oaa:IncreaseStacks()
    local ability = self:GetAbility()
    local stackCount = self:GetStackCount()
    local max_layers = ability:GetSpecialValueFor("max_layers")

    if stackCount < max_layers then
      self:SetStackCount(stackCount + 1)
    end
  end

  function modifier_visage_gravekeepers_cloak_oaa:GetModifierTotal_ConstantBlock(keys)
    local ability = self:GetAbility()
    local parent = self:GetParent()

    if parent:PassivesDisabled() or (not ability) or ability:IsNull() then
      return 0
    end

    -- Don't interact with damage that has HP removal flag
    if bit.band(keys.damage_flags, DOTA_DAMAGE_FLAG_HPLOSS) == DOTA_DAMAGE_FLAG_HPLOSS then
      return 0
    end

    local stackCount = self:GetStackCount()

    local damage_reduction_per_layer = ability:GetSpecialValueFor("damage_reduction")
    local max_damage_reduction = ability:GetSpecialValueFor("max_damage_reduction")
    local damageThreshold = ability:GetSpecialValueFor("minimum_damage")
    local recovery_time = ability:GetSpecialValueFor("recovery_time")

    local damageReduction = math.min(max_damage_reduction, damage_reduction_per_layer * stackCount)

    -- Does not interact at all with damage instances lower than the threshold.
    if keys.damage <= damageThreshold then
      return 0
    end

    if keys.attacker:GetTeam() ~= parent:GetTeam() and keys.attacker:GetTeam() ~= DOTA_TEAM_NEUTRALS then
      self:DecreaseStacks()
      local mod = self
      Timers:CreateTimer(recovery_time, function()
        if mod then
          mod:IncreaseStacks()
        end
      end)
    end

    local block_amount = keys.damage * damageReduction / 100

    if block_amount > 0 then
      -- Visual effect (TODO: add vanilla visual effect)
      SendOverheadEventMessage(nil, OVERHEAD_ALERT_BLOCK, parent, block_amount, nil)
    end

    return block_amount
  end
end

function modifier_visage_gravekeepers_cloak_oaa:GetModifierPhysicalArmorBonus()
  if not self:GetParent():PassivesDisabled() then
    return self.armor
  end
  return 0
end

--------------------------------------------------------------------------
-- aura stuff

function modifier_visage_gravekeepers_cloak_oaa:IsAura()
  if self:GetParent():PassivesDisabled() then
    return false
  end
  return true
end

function modifier_visage_gravekeepers_cloak_oaa:GetAuraSearchType()
  return DOTA_UNIT_TARGET_ALL
end

function modifier_visage_gravekeepers_cloak_oaa:GetAuraSearchFlags()
  return DOTA_UNIT_TARGET_FLAG_PLAYER_CONTROLLED
end

function modifier_visage_gravekeepers_cloak_oaa:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_visage_gravekeepers_cloak_oaa:GetAuraRadius()
  return self:GetAbility():GetSpecialValueFor("radius")
end

function modifier_visage_gravekeepers_cloak_oaa:GetModifierAura()
  return "modifier_visage_gravekeepers_cloak_oaa_aura"
end

function modifier_visage_gravekeepers_cloak_oaa:GetAuraEntityReject(entity)
  return string.sub(entity:GetUnitName(), 0, 24) ~= "npc_dota_visage_familiar"
end

---------------------------------------------------------------------------------------------------

modifier_visage_gravekeepers_cloak_oaa_aura = class(ModifierBaseClass)

function modifier_visage_gravekeepers_cloak_oaa_aura:IsHidden()
  return false
end

function modifier_visage_gravekeepers_cloak_oaa_aura:IsDebuff()
  return false
end

function modifier_visage_gravekeepers_cloak_oaa_aura:IsPurgable()
  return false
end

function modifier_visage_gravekeepers_cloak_oaa_aura:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_TOTAL_CONSTANT_BLOCK
  }
end

if IsServer() then
  function modifier_visage_gravekeepers_cloak_oaa_aura:GetModifierTotal_ConstantBlock(keys)
    local caster = self:GetCaster()
    local ability = self:GetAbility()

    -- Ignore damage that has HP removal flag
    if bit.band(keys.damage_flags, DOTA_DAMAGE_FLAG_HPLOSS) == DOTA_DAMAGE_FLAG_HPLOSS then
      return 0
    end

    local mod = caster:FindModifierByName("modifier_visage_gravekeepers_cloak_oaa")
    if mod and ability then
      local stackCount = mod:GetStackCount()
      local damage_reduction_per_layer = ability:GetSpecialValueFor("damage_reduction")
      local max_damage_reduction = ability:GetSpecialValueFor("max_damage_reduction")
      local damageReduction = math.min(max_damage_reduction, damage_reduction_per_layer * stackCount)

      local block_amount = keys.damage * damageReduction / 100

      if block_amount > 0 then
        -- Visual effect (TODO: add unique visual effect)
        SendOverheadEventMessage(nil, OVERHEAD_ALERT_BLOCK, self:GetParent(), block_amount, nil)
      end

      return block_amount
    end

    return 0
  end
end
