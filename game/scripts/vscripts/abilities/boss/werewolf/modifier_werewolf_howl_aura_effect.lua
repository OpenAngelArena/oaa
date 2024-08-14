modifier_werewolf_howl_aura_effect = class(ModifierBaseClass)

function modifier_werewolf_howl_aura_effect:IsHidden()
  return false
end

function modifier_werewolf_howl_aura_effect:IsDebuff()
  return false
end

function modifier_werewolf_howl_aura_effect:IsPurgable()
  return false
end

----------------------------------------

function modifier_werewolf_howl_aura_effect:OnCreated( kv )
	if self:GetAbility() then
		self.bonus_damage = self:GetAbility():GetSpecialValueFor( "bonus_damage" )
		self.bonus_move_speed = self:GetAbility():GetSpecialValueFor( "bonus_move_speed" )
	end
end

----------------------------------------

function modifier_werewolf_howl_aura_effect:GetEffectName()
	return "particles/units/heroes/hero_lycan/lycan_howl_buff.vpcf"
end

----------------------------------------

function modifier_werewolf_howl_aura_effect:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
	}
end

----------------------------------------

function modifier_werewolf_howl_aura_effect:GetModifierMoveSpeedBonus_Constant()
	return self.bonus_move_speed
end

----------------------------------------

function modifier_werewolf_howl_aura_effect:GetModifierPreAttack_BonusDamage()
	return self.bonus_damage
end
