LinkLuaModifier("modifier_item_reduction_orb_passive", "items/reduction_orb.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_reduction_orb_active", "items/reduction_orb.lua", LUA_MODIFIER_MOTION_NONE)

item_reduction_orb_1 = class(ItemBaseClass)

function item_reduction_orb_1:GetIntrinsicModifierName()
  return "modifier_item_reduction_orb_passive"
end

function item_reduction_orb_1:OnSpellStart()
  local caster = self:GetCaster()

  -- Apply modifier with damage reduction and converts damage-to-heal
  caster:AddNewModifier(caster, self, "modifier_item_reduction_orb_active", { duration = self:GetSpecialValueFor("duration") })
end

---------------------------------------------------------------------------------------------------

modifier_item_reduction_orb_passive = class(ModifierBaseClass)

function modifier_item_reduction_orb_passive:IsHidden()
  return true
end

function modifier_item_reduction_orb_passive:IsDebuff()
  return false
end

function modifier_item_reduction_orb_passive:IsPurgable()
  return false
end

function modifier_item_reduction_orb_passive:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_reduction_orb_passive:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.bonus_health = ability:GetSpecialValueFor("bonus_health")
    self.bonus_armor = ability:GetSpecialValueFor("bonus_armor")
    self.magic_resistance = ability:GetSpecialValueFor("bonus_magic_resistance")
  end
end

modifier_item_reduction_orb_passive.OnRefresh = modifier_item_reduction_orb_passive.OnCreated

function modifier_item_reduction_orb_passive:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_HEALTH_BONUS,
    MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
    MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
  }
end

function modifier_item_reduction_orb_passive:GetModifierHealthBonus()
  return self.bonus_health or self:GetAbility():GetSpecialValueFor("bonus_health")
end

function modifier_item_reduction_orb_passive:GetModifierPhysicalArmorBonus()
  return self.bonus_armor or self:GetAbility():GetSpecialValueFor("bonus_armor")
end

function modifier_item_reduction_orb_passive:GetModifierMagicalResistanceBonus()
  return self.magic_resistance or self:GetAbility():GetSpecialValueFor("bonus_magic_resistance")
end

---------------------------------------------------------------------------------------------------

modifier_item_reduction_orb_active = class(ModifierBaseClass)

function modifier_item_reduction_orb_active:IsHidden()
  return false
end

function modifier_item_reduction_orb_active:IsDebuff()
  return false
end

function modifier_item_reduction_orb_active:IsPurgable()
  return false
end

function modifier_item_reduction_orb_active:OnCreated()
  self.damageheal = 25
  self.damageReduction = 100
  self.endHeal = 0
  self:OnRefresh()
end

function modifier_item_reduction_orb_active:OnRefresh()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.damageheal = ability:GetSpecialValueFor("damage_as_healing")
    self.damageReduction = ability:GetSpecialValueFor("damage_reduction")
  end
end

function modifier_item_reduction_orb_active:OnDestroy()
  if IsServer() then
    local parent = self:GetParent()
    --local ability = self:GetAbility()
    local amountToHeal = self.endHeal

    --parent:Heal(amountToHeal, ability)
    parent:SetHealth(parent:GetHealth() + amountToHeal)
    SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, parent, amountToHeal, nil)
  end
end

function modifier_item_reduction_orb_active:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
    --MODIFIER_PROPERTY_TOTAL_CONSTANT_BLOCK,
    MODIFIER_PROPERTY_MODEL_SCALE
  }
end

function modifier_item_reduction_orb_active:GetModifierIncomingDamage_Percentage(event)
  if not IsServer() then
    return
  end

  local damage_before = event.original_damage
  if damage_before > 0 then
    self.endHeal = self.endHeal + damage_before * self.damageheal / 100
  end

  return 0 - self.damageReduction
end

--[[
function modifier_item_reduction_orb_active:GetModifierTotal_ConstantBlock(event)
  if not IsServer() then
    return
  end

  local parent = self:GetParent()
  local damage_before = event.original_damage
  local damage_after = event.damage

  if damage_before > 0 then
    self.endHeal = self.endHeal + damage_before * self.damageheal / 100
  end

  local block_amount = damage_after * self.damageReduction / 100

  if block_amount > 0 then
    -- Visual effect
    SendOverheadEventMessage(nil, OVERHEAD_ALERT_BLOCK, parent, block_amount, nil)
  end

  return block_amount
end
]]

function modifier_item_reduction_orb_active:GetModifierModelScale()
  return -30
end

function modifier_item_reduction_orb_active:GetStatusEffectName()
  return "particles/status_fx/status_effect_glow_white_over_time.vpcf"
end

function modifier_item_reduction_orb_active:StatusEffectPriority()
  return MODIFIER_PRIORITY_SUPER_ULTRA + 10000
end

function modifier_item_reduction_orb_active:GetTexture()
  return "custom/reduction_orb"
end
