require("modifier_miniboss_good_buff")
modifier_miniboss_good_buff_blue = class(modifier_miniboss_good_buff)

function modifier_miniboss_good_buff_blue:GetTexture()
	return "ancient_apparition_chilling_touch"
end

function modifier_miniboss_good_buff_blue:GetModifierMoveSpeedBonus_Percentage()
	return 10
end

function modifier_miniboss_good_buff_blue:GetModifierPercentageCooldown()
	return 20
end

function modifier_miniboss_good_buff_blue:OnDeath( event )
	if
end
