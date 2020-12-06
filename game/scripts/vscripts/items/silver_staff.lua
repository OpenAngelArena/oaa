item_silver_staff = class(ItemBaseClass)

LinkLuaModifier("modifier_item_silver_staff_passive", "items/silver_staff.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_silver_staff_debuff", "items/silver_staff.lua", LUA_MODIFIER_MOTION_NONE)

function item_silver_staff:GetIntrinsicModifierName()
  return "modifier_item_silver_staff_passive"
end

function item_silver_staff:OnSpellStart()
  local caster = self:GetCaster()
  local target = self:GetCursorTarget()

  -- Don't do anything if target has Linken's effect
  if target:TriggerSpellAbsorb(self) then
    return
  end

  -- Apply debuff (duration is not affected by status resistance)
  local debuff_duration = self:GetSpecialValueFor("duration")
  --debuff_duration = target:GetValueChangedByStatusResistance(debuff_duration)
  target:AddNewModifier(caster, self, "modifier_item_silver_staff_debuff", {duration = debuff_duration})

  -- Sound
  target:EmitSound("DOTA_Item.SilverEdge.Target")
end

item_silver_staff_2 = item_silver_staff

---------------------------------------------------------------------------------------------------

modifier_item_silver_staff_passive = class(ModifierBaseClass)

function modifier_item_silver_staff_passive:IsHidden()
  return true
end

function modifier_item_silver_staff_passive:IsDebuff()
  return false
end

function modifier_item_silver_staff_passive:IsPurgable()
  return false
end

function modifier_item_silver_staff_passive:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.bonus_health = ability:GetSpecialValueFor("bonus_health")
    self.bonus_mana_regen = ability:GetSpecialValueFor("bonus_mana_regen")
    self.bonus_str = ability:GetSpecialValueFor("bonus_all_stats")
    self.bonus_agi = ability:GetSpecialValueFor("bonus_all_stats")
    self.bonus_int = ability:GetSpecialValueFor("bonus_all_stats")
    self.bonus_armor = ability:GetSpecialValueFor("bonus_armor")
  end
end

function modifier_item_silver_staff_passive:OnRefresh()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.bonus_health = ability:GetSpecialValueFor("bonus_health")
    self.bonus_mana_regen = ability:GetSpecialValueFor("bonus_mana_regen")
    self.bonus_str = ability:GetSpecialValueFor("bonus_all_stats")
    self.bonus_agi = ability:GetSpecialValueFor("bonus_all_stats")
    self.bonus_int = ability:GetSpecialValueFor("bonus_all_stats")
    self.bonus_armor = ability:GetSpecialValueFor("bonus_armor")
  end
end

function modifier_item_silver_staff_passive:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_HEALTH_BONUS,
    MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
    MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
    MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
    MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
    MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
  }
  return funcs
end

function modifier_item_silver_staff_passive:GetModifierBonusStats_Strength()
  return self.bonus_str or self:GetAbility():GetSpecialValueFor("bonus_all_stats")
end

function modifier_item_silver_staff_passive:GetModifierBonusStats_Agility()
  return self.bonus_agi or self:GetAbility():GetSpecialValueFor("bonus_all_stats")
end

function modifier_item_silver_staff_passive:GetModifierBonusStats_Intellect()
  return self.bonus_int or self:GetAbility():GetSpecialValueFor("bonus_all_stats")
end

function modifier_item_silver_staff_passive:GetModifierPhysicalArmorBonus()
  return self.bonus_armor or self:GetAbility():GetSpecialValueFor("bonus_armor")
end

function modifier_item_silver_staff_passive:GetModifierHealthBonus()
  return self.bonus_health or self:GetAbility():GetSpecialValueFor("bonus_health")
end

function modifier_item_silver_staff_passive:GetModifierConstantManaRegen()
  return self.bonus_mana_regen or self:GetAbility():GetSpecialValueFor("bonus_mana_regen")
end

---------------------------------------------------------------------------------------------------

modifier_item_silver_staff_debuff = class(ModifierBaseClass)

function modifier_item_silver_staff_debuff:IsHidden()
  return false
end

function modifier_item_silver_staff_debuff:IsDebuff()
  return true
end

function modifier_item_silver_staff_debuff:IsPurgable()
  return false
end

function modifier_item_silver_staff_debuff:OnCreated()
  if IsServer() then
    local ability = self:GetAbility()
    if ability and not ability:IsNull() then
      self.base_damage = ability:GetSpecialValueFor("base_damage")
      self.percent_damage = ability:GetSpecialValueFor("max_hp_damage")
    end

    -- Initial damage
    local parent = self:GetParent()
    local damage_per_second = self.base_damage + self.percent_damage * parent:GetMaxHealth() * 0.01

    local damage_table = {
      victim = parent,
      attacker = self:GetCaster(),
      damage = damage_per_second,
      damage_type = DAMAGE_TYPE_PURE,
      damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION,
      ability = ability,
    }

    -- Don't do damage to bosses
    if not parent:IsOAABoss() then
      ApplyDamage(damage_table)
    end

    self:StartIntervalThink(1.0)
  end
end

function modifier_item_silver_staff_debuff:OnRefresh()
  if IsServer() then
    local ability = self:GetAbility()
    if ability and not ability:IsNull() then
      self.base_damage = ability:GetSpecialValueFor("base_damage")
      self.percent_damage = ability:GetSpecialValueFor("max_hp_damage")
    end
  end
end

function modifier_item_silver_staff_debuff:CheckState()
  local state = {
    [MODIFIER_STATE_PASSIVES_DISABLED] = true,
  }
  return state
end

function modifier_item_silver_staff_debuff:OnIntervalThink()
  local parent = self:GetParent()
  local caster = self:GetCaster()
  local ability = self:GetAbility()

  -- Don't do damage to bosses
  if parent:IsOAABoss() then
    return
  end

  local base_damage = self.base_damage
  local percent_damage = self.percent_damage
  if ability and not ability:IsNull() then
    base_damage = ability:GetSpecialValueFor("base_damage")
    percent_damage = ability:GetSpecialValueFor("max_hp_damage")
  end
  local damage_per_second = base_damage + percent_damage * parent:GetMaxHealth() * 0.01

  local damage_table = {
    victim = parent,
    attacker = caster,
    damage = damage_per_second,
    damage_type = DAMAGE_TYPE_PURE,
    damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION,
    ability = ability,
  }

  ApplyDamage(damage_table)
end

function modifier_item_silver_staff_debuff:GetEffectName()
  return "particles/items3_fx/silver_edge.vpcf"
end

function modifier_item_silver_staff_debuff:GetEffectAttachType()
  return PATTACH_ABSORIGIN_FOLLOW
end
