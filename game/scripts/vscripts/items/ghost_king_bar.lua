item_ghost_king_bar = class(ItemBaseClass)

LinkLuaModifier("modifier_item_ghost_king_bar_passive", "items/ghost_king_bar.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_ghost_king_bar_active", "items/ghost_king_bar.lua", LUA_MODIFIER_MOTION_NONE)

function item_ghost_king_bar:GetIntrinsicModifierName()
  return "modifier_item_ghost_king_bar_passive"
end

function item_ghost_king_bar:OnSpellStart()
  local caster = self:GetCaster()

  -- Apply Basic Dispel (its before applying actual effect on purpose!)
  caster:Purge(false, true, false, false, false)

  -- Apply Ghost King Bar buff to caster (but only if he doesnt have spell immunity)
  if not caster:IsMagicImmune() then
    caster:AddNewModifier(caster, self, "modifier_item_ghost_king_bar_active", {duration = self:GetSpecialValueFor("duration")})
  end

  -- Emit Activation sound
  caster:EmitSound("DOTA_Item.GhostScepter.Activate")
end

item_ghost_king_bar_2 = item_ghost_king_bar
item_ghost_king_bar_3 = item_ghost_king_bar

---------------------------------------------------------------------------------------------------

modifier_item_ghost_king_bar_passive = class(ModifierBaseClass)

function modifier_item_ghost_king_bar_passive:IsHidden()
  return true
end

function modifier_item_ghost_king_bar_passive:IsDebuff()
  return false
end

function modifier_item_ghost_king_bar_passive:IsPurgable()
  return false
end

function modifier_item_ghost_king_bar_passive:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_ghost_king_bar_passive:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.str = ability:GetSpecialValueFor("bonus_strength")
    self.agi = ability:GetSpecialValueFor("bonus_agility")
    self.int = ability:GetSpecialValueFor("bonus_intellect")
  end
end

function modifier_item_ghost_king_bar_passive:OnRefresh()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.str = ability:GetSpecialValueFor("bonus_strength")
    self.agi = ability:GetSpecialValueFor("bonus_agility")
    self.int = ability:GetSpecialValueFor("bonus_intellect")
  end
end

function modifier_item_ghost_king_bar_passive:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
    MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
    MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
  }

  return funcs
end

function modifier_item_ghost_king_bar_passive:GetModifierBonusStats_Strength()
  return self.str or self:GetAbility():GetSpecialValueFor("bonus_strength")
end

function modifier_item_ghost_king_bar_passive:GetModifierBonusStats_Agility()
  return self.agi or self:GetAbility():GetSpecialValueFor("bonus_agility")
end

function modifier_item_ghost_king_bar_passive:GetModifierBonusStats_Intellect()
  return self.int or self:GetAbility():GetSpecialValueFor("bonus_intellect")
end

---------------------------------------------------------------------------------------------------

modifier_item_ghost_king_bar_active = class(ModifierBaseClass)

function modifier_item_ghost_king_bar_active:IsHidden()
  return false
end

function modifier_item_ghost_king_bar_active:IsDebuff()
  return false
end

function modifier_item_ghost_king_bar_active:IsPurgable()
  return false
end

function modifier_item_ghost_king_bar_active:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.extra_spell_damage_percent = ability:GetSpecialValueFor("ethereal_damage_bonus")
    self.heal_amp = ability:GetSpecialValueFor("active_heal_amp")
    self.spell_lifesteal_amp = ability:GetSpecialValueFor("active_spell_lifesteal_amp")
  end

  self:StartIntervalThink(FrameTime())
end

function modifier_item_ghost_king_bar_active:OnRefresh()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.extra_spell_damage_percent = ability:GetSpecialValueFor("ethereal_damage_bonus")
    self.heal_amp = ability:GetSpecialValueFor("active_heal_amp")
    self.spell_lifesteal_amp = ability:GetSpecialValueFor("active_spell_lifesteal_amp")
  end
end

function modifier_item_ghost_king_bar_active:OnIntervalThink()
  local parent = self:GetParent()
  -- To prevent invicibility:
  if parent:IsMagicImmune() then
    self:Destroy()
  end
end

function modifier_item_ghost_king_bar_active:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_MAGICAL_RESISTANCE_DECREPIFY_UNIQUE,
    MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
    MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_SOURCE,
    MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_TARGET,
    MODIFIER_PROPERTY_SPELL_LIFESTEAL_AMPLIFY_PERCENTAGE,
  }

  return funcs
end

function modifier_item_ghost_king_bar_active:GetModifierMagicalResistanceDecrepifyUnique()
  return self.extra_spell_damage_percent or self:GetAbility():GetSpecialValueFor("ethereal_damage_bonus")
end

function modifier_item_ghost_king_bar_active:GetAbsoluteNoDamagePhysical()
  return 1
end

function modifier_item_ghost_king_bar_active:GetModifierHealAmplify_PercentageSource()
  return self.heal_amp or self:GetAbility():GetSpecialValueFor("active_heal_amp")
end

function modifier_item_ghost_king_bar_active:GetModifierHealAmplify_PercentageTarget()
  return self.heal_amp or self:GetAbility():GetSpecialValueFor("active_heal_amp")
end

function modifier_item_ghost_king_bar_active:GetModifierSpellLifestealRegenAmplify_Percentage()
  return self.spell_lifesteal_amp or self:GetAbility():GetSpecialValueFor("active_spell_lifesteal_amp")
end

function modifier_item_ghost_king_bar_active:CheckState()
  local state = {
    [MODIFIER_STATE_ATTACK_IMMUNE] = true,
    [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
    [MODIFIER_STATE_DISARMED] = true
  }

  return state
end

function modifier_item_ghost_king_bar_active:GetStatusEffectName()
  return "particles/status_fx/status_effect_ghost.vpcf"
end

function modifier_item_ghost_king_bar_active:StatusEffectPriority()
  return MODIFIER_PRIORITY_SUPER_ULTRA
end

function modifier_item_ghost_king_bar_active:GetTexture()
  return "custom/ghoststaff_5"
end
