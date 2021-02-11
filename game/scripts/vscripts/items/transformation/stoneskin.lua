item_stoneskin = class(TransformationBaseClass)

LinkLuaModifier("modifier_item_stoneskin", "items/transformation/stoneskin.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_stoneskin_stone_armor", "items/transformation/stoneskin.lua", LUA_MODIFIER_MOTION_NONE)

function item_stoneskin:GetIntrinsicModifierName()
  return "modifier_item_stoneskin" --"modifier_generic_bonus"
end

function item_stoneskin:GetTransformationModifierName()
  return "modifier_item_stoneskin_stone_armor"
end

item_stoneskin_2 = item_stoneskin

------------------------------------------------------------------------

modifier_item_stoneskin = class(ModifierBaseClass)

function modifier_item_stoneskin:IsHidden()
  return true
end
function modifier_item_stoneskin:IsDebuff()
  return false
end
function modifier_item_stoneskin:IsPurgable()
  return false
end

function modifier_item_stoneskin:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_stoneskin:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.int = ability:GetSpecialValueFor("bonus_intellect")
    self.armor = ability:GetSpecialValueFor("bonus_armor")
    self.hp_regen_amp = ability:GetSpecialValueFor("hp_regen_amp")
    self.lifesteal_amp = ability:GetSpecialValueFor("lifesteal_amp")
    self.heal_amp = ability:GetSpecialValueFor("heal_amp")
    self.spell_lifesteal_amp = ability:GetSpecialValueFor("spell_lifesteal_amp")
  end
end

function modifier_item_stoneskin:OnRefresh()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.int = ability:GetSpecialValueFor("bonus_intellect")
    self.armor = ability:GetSpecialValueFor("bonus_armor")
    self.hp_regen_amp = ability:GetSpecialValueFor("hp_regen_amp")
    self.lifesteal_amp = ability:GetSpecialValueFor("lifesteal_amp")
    self.heal_amp = ability:GetSpecialValueFor("heal_amp")
    self.spell_lifesteal_amp = ability:GetSpecialValueFor("spell_lifesteal_amp")
  end
end

function modifier_item_stoneskin:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
    MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
    MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE,
    MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_TARGET,
    MODIFIER_PROPERTY_LIFESTEAL_AMPLIFY_PERCENTAGE,
    MODIFIER_PROPERTY_SPELL_LIFESTEAL_AMPLIFY_PERCENTAGE,
  }
end

function modifier_item_stoneskin:GetModifierPhysicalArmorBonus()
  return self.armor or self:GetAbility():GetSpecialValueFor("bonus_armor")
end

function modifier_item_stoneskin:GetModifierBonusStats_Intellect()
  return self.int or self:GetAbility():GetSpecialValueFor("bonus_intellect")
end

function modifier_item_stoneskin:GetModifierHPRegenAmplify_Percentage()
  return self.hp_regen_amp or self:GetAbility():GetSpecialValueFor("hp_regen_amp")
end

function modifier_item_stoneskin:GetModifierHealAmplify_PercentageTarget()
  return self.heal_amp or self:GetAbility():GetSpecialValueFor("heal_amp")
end

function modifier_item_stoneskin:GetModifierLifestealRegenAmplify_Percentage()
  return self.lifesteal_amp or self:GetAbility():GetSpecialValueFor("lifesteal_amp")
end

function modifier_item_stoneskin:GetModifierSpellLifestealRegenAmplify_Percentage()
  return self.spell_lifesteal_amp or self:GetAbility():GetSpecialValueFor("spell_lifesteal_amp")
end

-- function modifier_item_stoneskin:OnStackCountChanged(numOldStacks)
--   -- Echo stack count to a property on the item so that it can be checked for
--   -- item icon purposes
--   if IsClient() then
--     local ability = self:GetAbility()
--     ability.stoneskinState = self:GetStackCount()
--   end
-- end

-- function modifier_item_stoneskin:OnDestroy()
  -- local item = self:GetAbility()
  -- if item and item.mod and not item.mod:IsNull() then
    -- item.mod:Destroy()
    -- item.mod = nil
  -- end
-- end

------------------------------------------------------------------------

modifier_item_stoneskin_stone_armor = class(ModifierBaseClass)

function modifier_item_stoneskin_stone_armor:IsHidden()
  return false
end

function modifier_item_stoneskin_stone_armor:IsDebuff()
  return false
end

function modifier_item_stoneskin_stone_armor:IsPurgable()
  return false
end

function modifier_item_stoneskin_stone_armor:OnCreated()
  if IsServer() then
    self:GetParent():EmitSound("Hero_EarthSpirit.Petrify")
  end
end

function modifier_item_stoneskin_stone_armor:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
    MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
    MODIFIER_PROPERTY_AVOID_DAMAGE,
    MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING,
    --MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE
  }
end

function modifier_item_stoneskin_stone_armor:GetModifierPhysicalArmorBonus()
  if not self:GetAbility() then
    if not self:IsNull() then
      self:Destroy()
    end
    return 0
  end
  return self:GetAbility():GetSpecialValueFor("stone_armor")
end

function modifier_item_stoneskin_stone_armor:GetModifierMagicalResistanceBonus()
  if not self:GetAbility() then
    if not self:IsNull() then
      self:Destroy()
    end
    return 0
  end
  return self:GetAbility():GetSpecialValueFor("stone_magic_resist")
end

function modifier_item_stoneskin_stone_armor:GetModifierAvoidDamage(event)
  local parent = self:GetParent()
  local ability = self:GetAbility()
  local chance = 30
  if ability and not ability:IsNull() then
    chance = ability:GetSpecialValueFor("stone_block_chance")
  end
  if event.ranged_attack == true and event.damage_category == DOTA_DAMAGE_CATEGORY_ATTACK and RollPseudoRandomPercentage(chance, DOTA_PSEUDO_RANDOM_CUSTOM_GAME_1, parent) == true then
    return 1
  end

  return 0
end

function modifier_item_stoneskin_stone_armor:GetModifierStatusResistanceStacking()
  if not self:GetAbility() then
    if not self:IsNull() then
      self:Destroy()
    end
    return 0
  end
  return self:GetAbility():GetSpecialValueFor("stone_status_resist")
end

function modifier_item_stoneskin_stone_armor:GetStatusEffectName()
  return "particles/status_fx/status_effect_earth_spirit_petrify.vpcf"
end

function modifier_item_stoneskin_stone_armor:StatusEffectPriority()
  return MODIFIER_PRIORITY_ULTRA
end

-- function modifier_item_stoneskin_stone_armor:GetModifierMoveSpeed_Absolute()
  -- if not self:GetAbility() then
    -- if not self:IsNull() then
      -- self:Destroy()
    -- end
    -- return
  -- end
  -- return self:GetAbility():GetSpecialValueFor("stone_move_speed")
-- end

function modifier_item_stoneskin_stone_armor:GetTexture()
  return "custom/stoneskin_2_active"
end
