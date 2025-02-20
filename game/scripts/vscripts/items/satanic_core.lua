LinkLuaModifier( "modifier_item_satanic_core", "items/satanic_core.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_satanic_core_unholy", "items/satanic_core.lua", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------

item_satanic_core_1 = class(ItemBaseClass)

function item_satanic_core_1:GetIntrinsicModifierName()
  return "modifier_intrinsic_multiplexer"
end

function item_satanic_core_1:GetIntrinsicModifierNames()
  return {
    "modifier_item_bloodstone",
    "modifier_item_satanic_core",
    "modifier_item_spell_lifesteal_oaa",
  }
end

function item_satanic_core_1:OnSpellStart()
  local hCaster = self:GetCaster()
  local unholy_duration = self:GetSpecialValueFor("duration")

  hCaster:EmitSound( "DOTA_Item.Satanic.Activate" )
  hCaster:AddNewModifier( hCaster, self, "modifier_satanic_core_unholy", { duration = unholy_duration } )
end

item_satanic_core_2 = item_satanic_core_1
item_satanic_core_3 = item_satanic_core_1
item_satanic_core_4 = item_satanic_core_1
item_satanic_core_5 = item_satanic_core_1

---------------------------------------------------------------------------------------------------

item_bloodstone_1 = class(ItemBaseClass)

function item_bloodstone_1:GetIntrinsicModifierName()
  return "modifier_intrinsic_multiplexer"
end

function item_bloodstone_1:GetIntrinsicModifierNames()
  return {
    "modifier_item_bloodstone",
    "modifier_item_spell_lifesteal_oaa",
  }
end

function item_bloodstone_1:OnSpellStart()
  local caster = self:GetCaster()

  -- Basic Dispel (for the caster)
  caster:Purge(false, true, false, false, false)

  local duration = self:GetSpecialValueFor("buff_duration")

  -- Sound
  caster:EmitSound("DOTA_Item.Bloodstone.Cast")

  -- Blood Pact
  if not caster:HasModifier("modifier_item_bloodstone_drained") then
    caster:AddNewModifier(caster, self, "modifier_item_bloodstone_active", {duration = duration})
  end

  -- Drained
  caster:AddNewModifier(caster, self, "modifier_item_bloodstone_drained", {duration = 40})
end

item_bloodstone_2 = item_bloodstone_1
item_bloodstone_3 = item_bloodstone_1
item_bloodstone_4 = item_bloodstone_1
item_bloodstone_5 = item_bloodstone_1

---------------------------------------------------------------------------------------------------

modifier_item_satanic_core = class(ModifierBaseClass)

function modifier_item_satanic_core:IsHidden()
  return true
end

function modifier_item_satanic_core:IsDebuff()
  return false
end

function modifier_item_satanic_core:IsPurgable()
  return false
end

function modifier_item_satanic_core:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_satanic_core:OnCreated()
  self:OnRefresh()
  if IsServer() then
    self:StartIntervalThink(0.1)
  end
end

function modifier_item_satanic_core:OnRefresh()
  local ability = self:GetAbility()
  if not ability or ability:IsNull() then
    return
  end

  self.bonus_to_primary_stat = ability:GetSpecialValueFor("primary_attribute_bonus")
  self.bonus_stat_for_universal = math.ceil(self.bonus_to_primary_stat/3)
  --self.bonus_hp = ability:GetSpecialValueFor("bonus_health")
  --self.bonus_mana = ability:GetSpecialValueFor("bonus_mana")
  --self.bonus_status_resist = ability:GetSpecialValueFor("bonus_status_resist")
  --self.hp_regen_amp = ability:GetSpecialValueFor("hp_regen_amp")
  --self.bonus_aoe = ability:GetSpecialValueFor("bonus_aoe")
  --self.bonus_mana_regen = ability:GetSpecialValueFor("bonus_mp_regen")
end

if IsServer() then
  function modifier_item_satanic_core:OnIntervalThink()
    -- if self:IsFirstItemInInventory() then
      -- self:SetStackCount(2)
    -- else
      -- self:SetStackCount(1)
    -- end
    local parent = self:GetParent()

    if not parent or parent:IsNull() then
      self:StartIntervalThink(-1)
      return
    end

    local attribute = parent:GetPrimaryAttribute()
    self:SetStackCount(attribute)
    -- We can stop the interval if dynamic changing of the primary attribute doesn't exist
    -- Morphling ultimate changes primary attribute ...
    self:StartIntervalThink(-1)
  end
end

function modifier_item_satanic_core:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_STATS_STRENGTH_BONUS, -- GetModifierBonusStats_Strength
    MODIFIER_PROPERTY_STATS_AGILITY_BONUS, -- GetModifierBonusStats_Agility
    MODIFIER_PROPERTY_STATS_INTELLECT_BONUS, -- GetModifierBonusStats_Intellect
    --MODIFIER_PROPERTY_HEALTH_BONUS, -- GetModifierHealthBonus
    --MODIFIER_PROPERTY_MANA_BONUS, -- GetModifierManaBonus
    --MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING, -- GetModifierStatusResistanceStacking
    --MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE, -- GetModifierHPRegenAmplify_Percentage
    --MODIFIER_PROPERTY_LIFESTEAL_AMPLIFY_PERCENTAGE, -- GetModifierLifestealRegenAmplify_Percentage
    --MODIFIER_PROPERTY_AOE_BONUS_CONSTANT, -- GetModifierAoEBonusConstant
    --MODIFIER_PROPERTY_MANA_REGEN_CONSTANT, -- GetModifierConstantManaRegen
  }
end

function modifier_item_satanic_core:GetModifierBonusStats_Strength()
  local attribute = self:GetStackCount()
  if attribute == DOTA_ATTRIBUTE_STRENGTH then
    return self.bonus_to_primary_stat
  elseif attribute == DOTA_ATTRIBUTE_ALL then
    return self.bonus_stat_for_universal
  end
  return 0
end

function modifier_item_satanic_core:GetModifierBonusStats_Agility()
  local attribute = self:GetStackCount()
  if attribute == DOTA_ATTRIBUTE_AGILITY then
    return self.bonus_to_primary_stat
  elseif attribute == DOTA_ATTRIBUTE_ALL then
    return self.bonus_stat_for_universal
  end
  return 0
end

function modifier_item_satanic_core:GetModifierBonusStats_Intellect()
  local attribute = self:GetStackCount()
  if attribute == DOTA_ATTRIBUTE_INTELLECT then
    return self.bonus_to_primary_stat
  elseif attribute == DOTA_ATTRIBUTE_ALL then
    return self.bonus_stat_for_universal
  end
  return 0
end

-- function modifier_item_satanic_core:GetModifierHealthBonus()
  -- return self.bonus_hp or self:GetAbility():GetSpecialValueFor("bonus_health")
-- end

-- function modifier_item_satanic_core:GetModifierManaBonus()
  -- return self.bonus_mana or self:GetAbility():GetSpecialValueFor("bonus_mana")
-- end

-- function modifier_item_satanic_core:GetModifierStatusResistanceStacking()
  -- local parent = self:GetParent()
  -- Prevent stacking with Sange items and with itself
  -- if self:GetStackCount() ~= 2 or parent:HasModifier("modifier_item_sange") or parent:HasModifier("modifier_item_sange_and_yasha") or parent:HasModifier("modifier_item_kaya_and_sange") or parent:HasModifier("item_heavens_halberd") then
    -- return 0
  -- end
  -- return self.bonus_status_resist or self:GetAbility():GetSpecialValueFor("bonus_status_resist")
-- end

-- function modifier_item_satanic_core:GetModifierHPRegenAmplify_Percentage()
  -- local parent = self:GetParent()
  -- Prevent stacking with Sange items and with itself
  -- if self:GetStackCount() ~= 2 or parent:HasModifier("modifier_item_sange") or parent:HasModifier("modifier_item_sange_and_yasha") or parent:HasModifier("modifier_item_kaya_and_sange") or parent:HasModifier("item_heavens_halberd") then
    -- return 0
  -- end
  -- return self.hp_regen_amp or self:GetAbility():GetSpecialValueFor("hp_regen_amp")
-- end

-- function modifier_item_satanic_core:GetModifierLifestealRegenAmplify_Percentage()
  -- local parent = self:GetParent()
  -- Prevent stacking with Sange items and with itself
  -- if self:GetStackCount() ~= 2 or parent:HasModifier("modifier_item_sange") or parent:HasModifier("modifier_item_sange_and_yasha") or parent:HasModifier("modifier_item_kaya_and_sange") or parent:HasModifier("item_heavens_halberd") then
    -- return 0
  -- end
  -- return self.hp_regen_amp or self:GetAbility():GetSpecialValueFor("hp_regen_amp")
-- end

-- Doesn't work, Thanks Valve
-- function modifier_item_satanic_core:GetModifierAoEBonusConstant(event)
  -- local parent = self:GetParent()
  -- Prevent stacking with Bloodstone and with itself
  -- if self:GetStackCount() ~= 2 or parent:HasModifier("modifier_item_bloodstone") then
    -- return 0
  -- end
  -- return self.bonus_aoe or self:GetAbility():GetSpecialValueFor("bonus_aoe")
-- end

-- function modifier_item_satanic_core:GetModifierConstantManaRegen()
  -- return self.bonus_mana_regen or self:GetAbility():GetSpecialValueFor("bonus_mp_regen")
-- end

---------------------------------------------------------------------------------------------------

modifier_satanic_core_unholy = class(ModifierBaseClass)

function modifier_satanic_core_unholy:IsHidden()
  return false
end

function modifier_satanic_core_unholy:IsDebuff()
  return false
end

function modifier_satanic_core_unholy:IsPurgable()
  return false
end

function modifier_satanic_core_unholy:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.hero_lifesteal_tooltip = ability:GetSpecialValueFor("unholy_hero_spell_lifesteal")
    self.creep_lifesteal_tooltip = ability:GetSpecialValueFor("unholy_creep_spell_lifesteal")
    self.dmg_to_mana = ability:GetSpecialValueFor("unholy_damage_dealt_to_mana")
  end
end

modifier_satanic_core_unholy.OnRefresh = modifier_satanic_core_unholy.OnCreated

function modifier_satanic_core_unholy:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_TOOLTIP,
    MODIFIER_PROPERTY_TOOLTIP2,
    --MODIFIER_EVENT_ON_TAKEDAMAGE,
  }
end

function modifier_satanic_core_unholy:OnTooltip()
  return self.hero_lifesteal_tooltip
end

function modifier_satanic_core_unholy:OnTooltip2()
  return self.creep_lifesteal_tooltip
end

if IsServer() then
  function modifier_satanic_core_unholy:OnTakeDamage(event)
    local parent = self:GetParent()
    local attacker = event.attacker
    local damaged_unit = event.unit
    local inflictor = event.inflictor
    local flags = event.damage_flags
    local damage = event.damage -- damage after reductions

    -- Check if attacker exists
    if not attacker or attacker:IsNull() then
      return
    end

    -- Check if attacker has this modifier
    if attacker ~= parent then
      return
    end

    -- Check if damaged entity exists
    if not damaged_unit or damaged_unit:IsNull() then
      return
    end

    -- Ignore self damage
    if damaged_unit == attacker then
      return
    end

    -- Check if entity is an item, rune or something weird
    if damaged_unit.GetUnitName == nil then
      return
    end

    -- Don't affect buildings, wards and invulnerable units.
    if damaged_unit:IsTower() or damaged_unit:IsBarracks() or damaged_unit:IsBuilding() or damaged_unit:IsOther() or damaged_unit:IsInvulnerable() then
      return
    end

    -- If there is no inflictor, damage is not dealt by a spell or item
    if not inflictor or inflictor:IsNull() then
      return
    end

    -- Ignore damage that has the no-reflect flag
    if bit.band(flags, DOTA_DAMAGE_FLAG_REFLECTION) > 0 then
      return
    end

    -- Ignore damage that has the no-spell-lifesteal flag
    if bit.band(flags, DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL) > 0 then
      return
    end

    -- Ignore damage that has the no-spell-amplification flag
    if bit.band(flags, DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION) > 0 then
      return
    end

    -- Don't give mana while dead
    if not attacker:IsAlive() then
      return
    end

    -- Check if damage is negative or 0
    if damage <= 0 then
      return
    end

    -- Give mana to the parent, mana amount is equal to damage dealt times the multiplier
    if self.dmg_to_mana >= 0 then
      parent:GiveMana(damage * self.dmg_to_mana)
    end
  end
end

function modifier_satanic_core_unholy:GetEffectName()
  return "particles/items2_fx/satanic_buff.vpcf"
end

function modifier_satanic_core_unholy:GetEffectAttachType()
  return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_satanic_core_unholy:GetStatusEffectName()
  return "particles/status_fx/status_effect_life_stealer_rage.vpcf"
end

function modifier_satanic_core_unholy:StatusEffectPriority()
  return MODIFIER_PRIORITY_SUPER_ULTRA
end

function modifier_satanic_core_unholy:GetTexture()
  return "custom/satanic_core"
end
