modifier_miniboss_good_buff = class({})
print("inclued")

function modifier_miniboss_good_buff:IsHidden()		return false end

function modifier_miniboss_good_buff:RemoveOnDeath()	return true end

function modifier_miniboss_good_buff:GetTexture()
	return "ursa_enrage"
end

function modifier_miniboss_good_buff:DeclareFunctions()
	local funcs = {
			MODIFIER_EVENT_ON_DEATH, -- OnDeath 
			MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, -- GetModifierMoveSpeedBonus_Percentage 
			MODIFIER_PROPERTY_COOLDOWN_PERCENTAGE, -- GetModifierPercentageCooldown
			MODIFIER_EVENT_ON_TAKEDAMAGE, -- OnTakeDamage 
			MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE, -- GetModifierHealthRegenPercentage 
	}
	return funcs
end

function modifier_miniboss_good_buff:OnCreated( event )
	if not IsServer() then return end
end

function modifier_miniboss_good_buff:OnDeath( event )
	if (event.unit~=self:GetParent())
	or (not event.attacker:IsRealHero()) then return end
	print("hero killed buff")
	event.attacker:AddNewModifier(self:GetParent(), nil, self:GetName(), { duration = 120 })
end
