item_black_king_bar_1 = class(ItemBaseClass)

LinkLuaModifier( "modifier_item_black_king_bar_oaa", "items/black_king_bar.lua", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------

function item_black_king_bar_1:GetIntrinsicModifierName()
	return "modifier_item_black_king_bar_oaa"
end

--------------------------------------------------------------------------------

function item_black_king_bar_1:OnSpellStart()
	local caster = self:GetCaster()

	caster:AddNewModifier( caster, self, "modifier_black_king_bar_immune", {
		duration = self:GetSpecialValueFor( "duration" ),
	} )
	caster:EmitSound( "DOTA_Item.BlackKingBar.Activate" )

	-- wow bkb is a basic item without the decay
end

--------------------------------------------------------------------------------

-- we're using our own modifier for stats since the normal bkb one seems to have weird quirks
modifier_item_black_king_bar_oaa = class(ModifierBaseClass)

--------------------------------------------------------------------------------

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

--------------------------------------------------------------------------------

function modifier_item_black_king_bar_oaa:OnCreated( event )
	local spell = self:GetAbility()

	self.str = spell:GetSpecialValueFor( "bonus_strength" )
	self.damage = spell:GetSpecialValueFor( "bonus_damage" )
end

--------------------------------------------------------------------------------

function modifier_item_black_king_bar_oaa:OnRefresh( event )
	local spell = self:GetAbility()

	self.str = spell:GetSpecialValueFor( "bonus_strength" )
	self.damage = spell:GetSpecialValueFor( "bonus_damage" )
end

--------------------------------------------------------------------------------

function modifier_item_black_king_bar_oaa:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
	}

	return funcs
end

--------------------------------------------------------------------------------

function modifier_item_black_king_bar_oaa:GetModifierPreAttack_BonusDamage( event )
	return self.damage
end

--------------------------------------------------------------------------------

function modifier_item_black_king_bar_oaa:GetModifierBonusStats_Strength( event )
	return self.str
end

--------------------------------------------------------------------------------

item_black_king_bar_2 = item_black_king_bar_1
item_black_king_bar_3 = item_black_king_bar_1
item_black_king_bar_4 = item_black_king_bar_1
item_black_king_bar_5 = item_black_king_bar_1
