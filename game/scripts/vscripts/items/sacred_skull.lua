LinkLuaModifier("modifier_item_sacred_skull_passives", "items/sacred_skull.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_sacred_skull_active", "items/sacred_skull.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_sacred_skull_armor_reduction_debuff", "items/sacred_skull.lua", LUA_MODIFIER_MOTION_NONE)

item_sacred_skull = class(ItemBaseClass)

function item_sacred_skull:GetIntrinsicModifierName()
  return "modifier_item_sacred_skull_passives"
end

function item_sacred_skull:GetHealthCost()
  return self:GetCaster():GetMaxHealth() * self:GetSpecialValueFor("health_cost") * 0.01
end

function item_sacred_skull:OnSpellStart()
  local caster = self:GetCaster()

  -- Add the buff
  caster:AddNewModifier(caster, self, "modifier_item_sacred_skull_active", {duration = self:GetSpecialValueFor("active_duration")})

  -- Sound
  caster:EmitSound("DOTA_Item.SoulRing.Activate")

  -- Fix mana
  caster:CalculateStatBonus(true)

  -- Grant mana
  local mana = self:GetSpecialValueFor("min_mana_gain") + self:GetHealthCost()
  caster:GiveMana(mana)
end

item_sacred_skull_2 = item_sacred_skull
item_sacred_skull_3 = item_sacred_skull
item_sacred_skull_4 = item_sacred_skull
item_sacred_skull_5 = item_sacred_skull

---------------------------------------------------------------------------------------------------

modifier_item_sacred_skull_passives = class(ModifierBaseClass)

function modifier_item_sacred_skull_passives:IsHidden()
  return true
end

function modifier_item_sacred_skull_passives:IsDebuff()
  return false
end

function modifier_item_sacred_skull_passives:IsPurgable()
  return false
end

function modifier_item_sacred_skull_passives:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_sacred_skull_passives:OnCreated()
  self:OnRefresh()
end

function modifier_item_sacred_skull_passives:OnRefresh()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.bonus_health = ability:GetSpecialValueFor("bonus_health")
    self.bonus_mana = ability:GetSpecialValueFor("bonus_mana")
    self.bonus_str = ability:GetSpecialValueFor("bonus_strength")
    self.bonus_armor = ability:GetSpecialValueFor("bonus_armor")
  end
end

function modifier_item_sacred_skull_passives:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_HEALTH_BONUS, -- GetModifierHealthBonus
    MODIFIER_PROPERTY_MANA_BONUS, -- GetModifierManaBonus
    MODIFIER_PROPERTY_STATS_STRENGTH_BONUS, -- GetModifierBonusStats_Strength
    MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS, -- GetModifierPhysicalArmorBonus
    MODIFIER_EVENT_ON_TAKEDAMAGE,
  }
end

function modifier_item_sacred_skull_passives:GetModifierHealthBonus()
  return self.bonus_health or self:GetAbility():GetSpecialValueFor("bonus_health")
end

function modifier_item_sacred_skull_passives:GetModifierManaBonus()
  return self.bonus_mana or self:GetAbility():GetSpecialValueFor("bonus_mana")
end

function modifier_item_sacred_skull_passives:GetModifierBonusStats_Strength()
  return self.bonus_str or self:GetAbility():GetSpecialValueFor("bonus_strength")
end

function modifier_item_sacred_skull_passives:GetModifierPhysicalArmorBonus()
  return self.bonus_armor or self:GetAbility():GetSpecialValueFor("bonus_armor")
end

if IsServer() then
  function modifier_item_sacred_skull_passives:OnTakeDamage(event)
    if not self:IsFirstItemInInventory() then
      return
    end

    local parent = self:GetParent()
    local attacker = event.attacker
    local damaged_unit = event.unit
    local inflictor = event.inflictor

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

    -- Ignore self damage and allies
    if damaged_unit == attacker or damaged_unit:GetTeamNumber() == attacker:GetTeamNumber() then
      return
    end

    -- Check if attacker is dead
    if not attacker:IsAlive() then
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

    local ability = self:GetAbility()
    if not ability or ability:IsNull() then
      return
    end

    -- Check if inflictor exists (if it doesn't, it's not a spell) and damage category
    if not inflictor or event.damage_category ~= DOTA_DAMAGE_CATEGORY_SPELL then
      return
    end

    -- If inflictor is an item (radiance e.g.), don't continue
    if inflictor and inflictor:IsItem() then
      return
    end

    -- Check damage if 0 or negative
    if event.damage <= 0 then
      return
    end

    -- Apply Armor Reduction debuff
    damaged_unit:AddNewModifier(parent, ability, "modifier_item_sacred_skull_armor_reduction_debuff", {duration = ability:GetSpecialValueFor("armor_reduction_duration")})
  end
end

---------------------------------------------------------------------------------------------------

modifier_item_sacred_skull_active = class(ModifierBaseClass)

function modifier_item_sacred_skull_active:IsHidden()
  return false
end

function modifier_item_sacred_skull_active:IsDebuff()
  return false
end

function modifier_item_sacred_skull_active:IsPurgable()
  return false
end

function modifier_item_sacred_skull_active:OnCreated(event)
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.spell_amp = ability:GetSpecialValueFor("spell_amp")
    self.bonus_mana = ability:GetSpecialValueFor("min_mana_gain") + ability:GetHealthCost()
  end
end

function modifier_item_sacred_skull_active:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MANA_BONUS, -- GetModifierManaBonus
    MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE, -- GetModifierSpellAmplify_Percentage
    MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE, -- GetModifierTotalDamageOutgoing_Percentage
  }
end

function modifier_item_sacred_skull_active:GetModifierManaBonus()
  return self.bonus_mana
end

function modifier_item_sacred_skull_active:GetModifierSpellAmplify_Percentage()
  return self.spell_amp
end

if IsServer() then
  function modifier_item_sacred_skull_active:GetModifierTotalDamageOutgoing_Percentage(event)
    if event.damage_type ~= DAMAGE_TYPE_PHYSICAL and event.damage_category == DOTA_DAMAGE_CATEGORY_SPELL then
      local damage_table = {
        attacker = self:GetParent(),
        victim = event.target,
        damage = math.max(event.damage, event.original_damage),
        damage_type = DAMAGE_TYPE_PHYSICAL,
        damage_flags = bit.bor(event.damage_flags, DOTA_DAMAGE_FLAG_BYPASSES_BLOCK),
        ability = event.inflictor or self:GetAbility(),
      }
      ApplyDamage(damage_table)
      return -200
    end
    return 0
  end
end

function modifier_item_sacred_skull_active:GetTexture()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    local baseIconName = ability.BaseClass.GetAbilityTextureName(ability)
    return baseIconName
  end
end

---------------------------------------------------------------------------------------------------

modifier_item_sacred_skull_armor_reduction_debuff = class(ModifierBaseClass)

function modifier_item_sacred_skull_armor_reduction_debuff:IsHidden()
  return false
end

function modifier_item_sacred_skull_armor_reduction_debuff:IsDebuff()
  return true
end

function modifier_item_sacred_skull_armor_reduction_debuff:IsPurgable()
  return true
end

function modifier_item_sacred_skull_armor_reduction_debuff:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.armor_reduction = ability:GetSpecialValueFor("passive_armor_reduction")
  end
end

function modifier_item_sacred_skull_armor_reduction_debuff:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
  }
end

function modifier_item_sacred_skull_armor_reduction_debuff:GetModifierPhysicalArmorBonus()
  return 0 - math.abs(self.armor_reduction)
end

function modifier_item_sacred_skull_armor_reduction_debuff:GetTexture()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    local baseIconName = ability.BaseClass.GetAbilityTextureName(ability)
    return baseIconName
  end
end
