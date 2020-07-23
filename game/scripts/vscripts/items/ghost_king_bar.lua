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

  -- Apply Ghost King Bar debuff to caster
	caster:AddNewModifier(caster, self, "modifier_item_ghost_king_bar_active", {duration = self:GetSpecialValueFor("duration")})

  -- Emit Activation sound
	caster:EmitSound("DOTA_Item.GhostScepter.Activate")
end

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
	return true
end

function modifier_item_ghost_king_bar_active:IsPurgable()
	return true
end

function modifier_item_ghost_king_bar_active:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.extra_spell_damage_percent = ability:GetSpecialValueFor("ethereal_damage_bonus")
  end

	self:StartIntervalThink(FrameTime())
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
  }

  return funcs
end

function modifier_item_ghost_king_bar_active:GetModifierMagicalResistanceDecrepifyUnique()
  return self.extra_spell_damage_percent or self:GetAbility():GetSpecialValueFor("ethereal_damage_bonus")
end

function modifier_item_ghost_king_bar_active:GetAbsoluteNoDamagePhysical()
  return 1
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

---------------------------------------------------------------------------------------------------

item_ghost_king_bar_2 = item_ghost_king_bar
item_ghost_king_bar_3 = item_ghost_king_bar
