item_stoneskin = class(TransformationBaseClass)

LinkLuaModifier("modifier_intrinsic_multiplexer", "modifiers/modifier_intrinsic_multiplexer.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_stoneskin_stacking_stats", "items/transformation/stoneskin.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_stoneskin_aura", "items/transformation/stoneskin.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_stoneskin_aura_effect", "items/transformation/stoneskin.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_stoneskin_stone_armor", "items/transformation/stoneskin.lua", LUA_MODIFIER_MOTION_NONE)

function item_stoneskin:GetIntrinsicModifierName()
  return "modifier_intrinsic_multiplexer"
end

function item_stoneskin:GetIntrinsicModifierNames()
  return {
    "modifier_item_stoneskin_stacking_stats",
    "modifier_item_stoneskin_aura"
  }
end

function item_stoneskin:GetTransformationModifierName()
  return "modifier_item_stoneskin_stone_armor"
end

item_stoneskin_2 = item_stoneskin

------------------------------------------------------------------------

modifier_item_stoneskin_stacking_stats = class(ModifierBaseClass)

function modifier_item_stoneskin_stacking_stats:IsHidden()
  return true
end

function modifier_item_stoneskin_stacking_stats:IsDebuff()
  return false
end

function modifier_item_stoneskin_stacking_stats:IsPurgable()
  return false
end

function modifier_item_stoneskin_stacking_stats:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_stoneskin_stacking_stats:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.int = ability:GetSpecialValueFor("bonus_intellect")
    self.armor = ability:GetSpecialValueFor("bonus_armor")
  end
end

function modifier_item_stoneskin_stacking_stats:OnRefresh()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.int = ability:GetSpecialValueFor("bonus_intellect")
    self.armor = ability:GetSpecialValueFor("bonus_armor")
  end
end

function modifier_item_stoneskin_stacking_stats:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
    MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
  }
end

function modifier_item_stoneskin_stacking_stats:GetModifierPhysicalArmorBonus()
  return self.armor or self:GetAbility():GetSpecialValueFor("bonus_armor")
end

function modifier_item_stoneskin_stacking_stats:GetModifierBonusStats_Intellect()
  return self.int or self:GetAbility():GetSpecialValueFor("bonus_intellect")
end

-- function modifier_item_stoneskin_stacking_stats:OnStackCountChanged(numOldStacks)
--   -- Echo stack count to a property on the item so that it can be checked for
--   -- item icon purposes
--   if IsClient() then
--     local ability = self:GetAbility()
--     ability.stoneskinState = self:GetStackCount()
--   end
-- end

-- function modifier_item_stoneskin_stacking_stats:OnDestroy()
  -- local item = self:GetAbility()
  -- if item and item.mod and not item.mod:IsNull() then
    -- item.mod:Destroy()
    -- item.mod = nil
  -- end
-- end

---------------------------------------------------------------------------------------------------

modifier_item_stoneskin_aura = class(ModifierBaseClass)

function modifier_item_stoneskin_aura:IsHidden()
  return true
end

function modifier_item_stoneskin_aura:IsDebuff()
  return false
end

function modifier_item_stoneskin_aura:IsPurgable()
  return false
end

function modifier_item_stoneskin_aura:IsAura()
  return true
end

function modifier_item_stoneskin_aura:GetModifierAura()
  return "modifier_item_stoneskin_aura_effect"
end

function modifier_item_stoneskin_aura:GetAuraRadius()
  return self:GetAbility():GetSpecialValueFor("aura_radius")
end

function modifier_item_stoneskin_aura:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_item_stoneskin_aura:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC)
end

---------------------------------------------------------------------------------------------------

modifier_item_stoneskin_aura_effect = class(ModifierBaseClass)

function modifier_item_stoneskin_aura_effect:IsHidden()
  return false
end

function modifier_item_stoneskin_aura_effect:IsDebuff()
  return false
end

function modifier_item_stoneskin_aura_effect:IsPurgable()
  return false
end

function modifier_item_stoneskin_aura_effect:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.hp_regen_amp = ability:GetSpecialValueFor("hp_regen_amp")
    self.lifesteal_amp = ability:GetSpecialValueFor("lifesteal_amp")
    self.heal_amp = ability:GetSpecialValueFor("heal_amp")
    self.spell_lifesteal_amp = ability:GetSpecialValueFor("spell_lifesteal_amp")
  end
end

function modifier_item_stoneskin_aura_effect:OnRefresh()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.hp_regen_amp = ability:GetSpecialValueFor("hp_regen_amp")
    self.lifesteal_amp = ability:GetSpecialValueFor("lifesteal_amp")
    self.heal_amp = ability:GetSpecialValueFor("heal_amp")
    self.spell_lifesteal_amp = ability:GetSpecialValueFor("spell_lifesteal_amp")
  end
end

function modifier_item_stoneskin_aura_effect:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE,
    MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_TARGET,
    MODIFIER_PROPERTY_LIFESTEAL_AMPLIFY_PERCENTAGE,
    MODIFIER_PROPERTY_SPELL_LIFESTEAL_AMPLIFY_PERCENTAGE,
  }
end

function modifier_item_stoneskin_aura_effect:GetModifierHPRegenAmplify_Percentage()
  return self.hp_regen_amp or self:GetAbility():GetSpecialValueFor("hp_regen_amp")
end

function modifier_item_stoneskin_aura_effect:GetModifierHealAmplify_PercentageTarget()
  return self.heal_amp or self:GetAbility():GetSpecialValueFor("heal_amp")
end

function modifier_item_stoneskin_aura_effect:GetModifierLifestealRegenAmplify_Percentage()
  return self.lifesteal_amp or self:GetAbility():GetSpecialValueFor("lifesteal_amp")
end

function modifier_item_stoneskin_aura_effect:GetModifierSpellLifestealRegenAmplify_Percentage()
  return self.spell_lifesteal_amp or self:GetAbility():GetSpecialValueFor("spell_lifesteal_amp")
end

function modifier_item_stoneskin_aura_effect:GetTexture()
  return "custom/stoneskin_2"
end

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
  local chance = 50
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
