LinkLuaModifier("modifier_item_craggy_coat_passive", "items/neutral/craggy_coat.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_craggy_coat_active", "items/neutral/craggy_coat.lua", LUA_MODIFIER_MOTION_NONE)

item_craggy_coat_oaa = class(ItemBaseClass)

function item_craggy_coat_oaa:GetIntrinsicModifierName()
  return "modifier_item_craggy_coat_passive"
end

function item_craggy_coat_oaa:OnSpellStart()
  local caster = self:GetCaster()

  -- Apply the buff
  caster:AddNewModifier(caster, self, "modifier_item_craggy_coat_active", {duration = self:GetSpecialValueFor("duration")})
end

---------------------------------------------------------------------------------------------------

modifier_item_craggy_coat_passive = class(ModifierBaseClass)

function modifier_item_craggy_coat_passive:IsHidden()
  return true
end

function modifier_item_craggy_coat_passive:IsDebuff()
  return false
end

function modifier_item_craggy_coat_passive:IsPurgable()
  return false
end

function modifier_item_craggy_coat_passive:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.strength = ability:GetSpecialValueFor("bonus_strength")
    self.armor = ability:GetSpecialValueFor("bonus_armor")
  end
end

function modifier_item_craggy_coat_passive:OnRefresh()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.strength = ability:GetSpecialValueFor("bonus_strength")
    self.armor = ability:GetSpecialValueFor("bonus_armor")
  end
end

function modifier_item_craggy_coat_passive:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
    MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
  }
end

function modifier_item_craggy_coat_passive:GetModifierBonusStats_Strength()
  return self.strength or self:GetAbility():GetSpecialValueFor("bonus_strength")
end

function modifier_item_craggy_coat_passive:GetModifierPhysicalArmorBonus()
  return self.armor or self:GetAbility():GetSpecialValueFor("bonus_armor")
end

---------------------------------------------------------------------------------------------------

modifier_item_craggy_coat_active = class(ModifierBaseClass)

function modifier_item_craggy_coat_active:IsHidden()
  return false
end

function modifier_item_craggy_coat_active:IsDebuff()
  return false
end

function modifier_item_craggy_coat_active:IsPurgable()
  return true
end

function modifier_item_craggy_coat_active:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
    MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
    MODIFIER_EVENT_ON_TAKEDAMAGE,
  }
end

function modifier_item_craggy_coat_active:GetAbsoluteNoDamageMagical()
  return 1
end

function modifier_item_craggy_coat_active:GetAbsoluteNoDamagePure()
  return 1
end

if IsServer() then
  function modifier_item_craggy_coat_active:OnTakeDamage(event)
    local parent = self:GetParent()
    local attacker = event.attacker
    local damaged_unit = event.unit

    -- Check if attacker exists
    if not attacker or attacker:IsNull() then
      return
    end

    -- Check if damaged entity exists
    if not damaged_unit or damaged_unit:IsNull() then
      return
    end

    -- Check if damaged entity has this modifier
    if damaged_unit ~= parent then
      return
    end

    local damage = event.original_damage
    local damage_type = event.damage_type

    -- Check if damage is somehow 0 or negative
    if damage <= 0 then
      return
    end

    if damage_type == DAMAGE_TYPE_PHYSICAL then
      return
    end

    local damage_table = {
      victim = parent,
      attacker = attacker,
      damage = damage,
      damage_type = DAMAGE_TYPE_PHYSICAL,
      damage_flags = event.damage_flags,
      ability = event.inflictor,
    }

    ApplyDamage(damage_table)
  end
end
