LinkLuaModifier("modifier_alchemist_goblins_greed_oaa", "abilities/oaa_alchemist_greevils_greed.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_alchemist_gold_corrosion_oaa_debuff", "abilities/oaa_alchemist_greevils_greed.lua", LUA_MODIFIER_MOTION_NONE)

alchemist_goblins_greed_oaa = class(AbilityBaseClass)

function alchemist_goblins_greed_oaa:GetIntrinsicModifierName()
  return "modifier_alchemist_goblins_greed_oaa"
end

function alchemist_goblins_greed_oaa:OnUpgrade()
  local caster = self:GetCaster()
  local ability_level = self:GetLevel()
  local vanilla_ability = caster:FindAbilityByName("alchemist_goblins_greed")

	-- Check to not enter a level up loop
  if vanilla_ability and vanilla_ability:GetLevel() ~= ability_level then
    vanilla_ability:SetLevel(ability_level)
  end
end

function alchemist_goblins_greed_oaa:IsStealable()
  return false
end

---------------------------------------------------------------------------------------------------

modifier_alchemist_goblins_greed_oaa = class(ModifierBaseClass)

function modifier_alchemist_goblins_greed_oaa:IsHidden()
  return true
end

function modifier_alchemist_goblins_greed_oaa:IsDebuff()
  return false
end

function modifier_alchemist_goblins_greed_oaa:IsPurgable()
  return false
end

function modifier_alchemist_goblins_greed_oaa:RemoveOnDeath()
  return false
end

function modifier_alchemist_goblins_greed_oaa:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_ATTACK_LANDED,
  }
end

if IsServer() then
  function modifier_alchemist_goblins_greed_oaa:OnAttackLanded(event)
    local parent = self:GetParent()
    local ability = self:GetAbility()
    local target = event.target

    -- Doesn't work on units that dont have this modifier, doesn't work on illusions or if broken
    if parent ~= event.attacker or parent:IsIllusion() or parent:PassivesDisabled() then
      return
    end

    -- To prevent crashes:
    if not target then
      return
    end

    if target:IsNull() then
      return
    end

    -- Doesn't work on allies, towers, or wards
    if UnitFilter(target, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, parent:GetTeamNumber()) ~= UF_SUCCESS then
      return
    end

    -- Don't continue if entity doesn't have this method
    if target.GetMaximumGoldBounty == nil then
      return
    end

    -- Doesn't work on units without a bounty
    if not target:IsRealHero() and target:GetMaximumGoldBounty() == 0 then
      return
    end

    -- Get duration
    local duration = ability:GetSpecialValueFor("armor_reduction_duration")

    target:AddNewModifier(parent, ability, "modifier_alchemist_gold_corrosion_oaa_debuff", {duration = duration})
  end
end

---------------------------------------------------------------------------------------------------

modifier_alchemist_gold_corrosion_oaa_debuff = class(ModifierBaseClass)

function modifier_alchemist_gold_corrosion_oaa_debuff:IsHidden()
  return false
end

function modifier_alchemist_gold_corrosion_oaa_debuff:IsDebuff()
  return true
end

function modifier_alchemist_gold_corrosion_oaa_debuff:IsPurgable()
  return true
end

function modifier_alchemist_gold_corrosion_oaa_debuff:OnCreated()
  if not IsServer() then
    return
  end

  local parent = self:GetParent()
  local parent_worth = 0
  if parent:IsRealHero() then
    parent_worth = parent:GetNetworth()
  else
    parent_worth = parent:GetMaximumGoldBounty()
  end
  local caster = self:GetCaster()
  local caster_worth = 0
  if caster:IsRealHero() then
    caster_worth = caster:GetNetworth()
  else
    return
  end
  -- Apply more stacks if parent has more networth than the caster
  if caster_worth >= parent_worth then
    self:SetStackCount(1)
  else
    local multiplier = self:GetAbility():GetSpecialValueFor("multiplier")
    self:SetStackCount(math.ceil(multiplier))
  end
end

function modifier_alchemist_gold_corrosion_oaa_debuff:OnRefresh()
  if not IsServer() then
    return
  end

  local parent = self:GetParent()
  local parent_worth = 0
  if parent:IsRealHero() then
    parent_worth = parent:GetNetworth()
  else
    parent_worth = parent:GetMaximumGoldBounty()
  end
  local caster = self:GetCaster()
  local caster_worth = 0
  if caster:IsRealHero() then
    caster_worth = caster:GetNetworth()
  else
    return
  end
  -- Apply more stacks if parent has more networth than the caster
  if caster_worth >= parent_worth then
    self:IncrementStackCount()
  else
    local multiplier = self:GetAbility():GetSpecialValueFor("multiplier")
    local old_stacks = self:GetStackCount()
    self:SetStackCount(math.ceil(old_stacks + multiplier))
  end
end

function modifier_alchemist_gold_corrosion_oaa_debuff:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS
  }
  return funcs
end

function modifier_alchemist_gold_corrosion_oaa_debuff:GetModifierPhysicalArmorBonus()
  local ability = self:GetAbility()
  local armor_per_stack = ability:GetSpecialValueFor("armor_reduction_per_hit")
  local armor_cap = ability:GetSpecialValueFor("armor_reduction_cap")
  local stacks = self:GetStackCount()

  -- Talent that increases armor reduction per hit
  local talent = self:GetCaster():FindAbilityByName("special_bonus_unique_alchemist_2_oaa")
  if talent and talent:GetLevel() > 0 then
    armor_per_stack = armor_per_stack + talent:GetSpecialValueFor("value")
  end

  return math.max(0 - armor_per_stack * stacks, armor_cap)
end

function modifier_alchemist_gold_corrosion_oaa_debuff:GetStatusEffectName()
  -- It looks ugly on creeps
  if self:GetParent():IsHero() then
    return "particles/econ/items/effigies/status_fx_effigies/status_effect_effigy_gold_lvl2.vpcf"
  end

  return ""
end

function modifier_alchemist_gold_corrosion_oaa_debuff:StatusEffectPriority()
  return 12
end
