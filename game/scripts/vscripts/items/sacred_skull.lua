LinkLuaModifier("modifier_item_sacred_skull_passives", "items/sacred_skull.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_sacred_skull_armor_reduction_debuff", "items/sacred_skull.lua", LUA_MODIFIER_MOTION_NONE)

item_sacred_skull = class(ItemBaseClass)

function item_sacred_skull:GetIntrinsicModifierName()
  return "modifier_item_sacred_skull_passives"
end

-- function item_sacred_skull:GetHealthCost()
  -- return self:GetCaster():GetMaxHealth() * self:GetSpecialValueFor("health_cost") * 0.01
-- end

item_sacred_skull_2 = item_sacred_skull
item_sacred_skull_3 = item_sacred_skull

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
  if IsServer() then
    self:StartIntervalThink(0.3)
  end
end

function modifier_item_sacred_skull_passives:OnRefresh()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.bonus_health = ability:GetSpecialValueFor("bonus_health")
    self.bonus_armor = ability:GetSpecialValueFor("bonus_armor")
    self.cdr = ability:GetSpecialValueFor("cooldown_reduction")
  end

  if IsServer() then
    self:OnIntervalThink()
  end
end

function modifier_item_sacred_skull_passives:OnIntervalThink()
  if self:IsFirstItemInInventory() then
    self:SetStackCount(2)
  else
    self:SetStackCount(1)
  end
end

function modifier_item_sacred_skull_passives:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_HEALTH_BONUS, -- GetModifierHealthBonus
    MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS, -- GetModifierPhysicalArmorBonus
    MODIFIER_PROPERTY_COOLDOWN_PERCENTAGE, -- GetModifierPercentageCooldown
    MODIFIER_EVENT_ON_TAKEDAMAGE,
  }
end

function modifier_item_sacred_skull_passives:GetModifierHealthBonus()
  return self.bonus_health or self:GetAbility():GetSpecialValueFor("bonus_health")
end

function modifier_item_sacred_skull_passives:GetModifierPhysicalArmorBonus()
  return self.bonus_armor or self:GetAbility():GetSpecialValueFor("bonus_armor")
end

function modifier_item_sacred_skull_passives:GetModifierPercentageCooldown()
  -- Prevent stacking with Octarine Core and other Sacred Skulls
  if self:GetParent():HasModifier("modifier_item_octarine_core") or self:GetStackCount() ~= 2 then
    return 0
  end

  return self.cdr or self:GetAbility():GetSpecialValueFor("cooldown_reduction")
end

if IsServer() then
  function modifier_item_sacred_skull_passives:OnTakeDamage(event)
    if self:GetStackCount() ~= 2 then
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
  return "custom/sacred_skull"
end
