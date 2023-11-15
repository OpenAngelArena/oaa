item_black_king_bar_1 = class(ItemBaseClass)

LinkLuaModifier( "modifier_item_black_king_bar_oaa", "items/black_king_bar.lua", LUA_MODIFIER_MOTION_NONE )

function item_black_king_bar_1:GetIntrinsicModifierName()
	return "modifier_item_black_king_bar_oaa"
end

function item_black_king_bar_1:OnSpellStart()
  local caster = self:GetCaster()

  -- Basic Dispel
  caster:Purge( false, true, false, false, false )

  -- Remove debuffs that are removed only with BKB/Spell Immunity/Debuff Immunity
  caster:RemoveModifierByName("modifier_slark_pounce_leash")
  caster:RemoveModifierByName("modifier_invoker_deafening_blast_disarm")

	-- Apply spell immunity buff
  caster:AddNewModifier(caster, self, "modifier_black_king_bar_immune", {duration = self:GetSpecialValueFor("duration")})

  -- Sound
  caster:EmitSound( "DOTA_Item.BlackKingBar.Activate" )
end

item_black_king_bar_2 = item_black_king_bar_1
item_black_king_bar_3 = item_black_king_bar_1
item_black_king_bar_4 = item_black_king_bar_1
item_black_king_bar_5 = item_black_king_bar_1

---------------------------------------------------------------------------------------------------

modifier_item_black_king_bar_oaa = class(ModifierBaseClass)

function modifier_item_black_king_bar_oaa:IsHidden()
	return true
end

function modifier_item_black_king_bar_oaa:IsDebuff()
	return false
end

function modifier_item_black_king_bar_oaa:IsPurgable()
	return false
end

function modifier_item_black_king_bar_oaa:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_black_king_bar_oaa:OnCreated()
	local spell = self:GetAbility()
  if spell and not spell:IsNull() then
	  self.str = spell:GetSpecialValueFor( "bonus_strength" )
	  self.damage = spell:GetSpecialValueFor( "bonus_damage" )
  end
end

modifier_item_black_king_bar_oaa.OnRefresh = modifier_item_black_king_bar_oaa.OnCreated

function modifier_item_black_king_bar_oaa:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
	}
end

function modifier_item_black_king_bar_oaa:GetModifierPreAttack_BonusDamage()
	return self.damage or self:GetAbility():GetSpecialValueFor("bonus_damage")
end

function modifier_item_black_king_bar_oaa:GetModifierBonusStats_Strength()
	return self.str or self:GetAbility():GetSpecialValueFor("bonus_strength")
end
