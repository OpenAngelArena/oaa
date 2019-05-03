modifier_miniboss_base = class(ModifierBaseClass)


function modifier_miniboss_base:IsHidden()		return false end

function modifier_miniboss_base:RemoveOnDeath()	return true end

function modifier_miniboss_base:GetTexture() return "death_prophet_carrion_swarm" end

function modifier_miniboss_base:DeclareFunctions()
	local funcs = {
			MODIFIER_EVENT_ON_DEATH, -- OnDeath 
			MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, -- GetModifierMoveSpeedBonus_Percentage 
			MODIFIER_PROPERTY_COOLDOWN_PERCENTAGE, -- GetModifierPercentageCooldown
			MODIFIER_EVENT_ON_TAKEDAMAGE, -- OnTakeDamage 
			MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT, -- GetModifierConstantHealthRegen  
			MODIFIER_EVENT_ON_ATTACK_LANDED, -- OnAttackLanded 
	}
	return funcs
end

function modifier_miniboss_base:OnCreated( event )
	if not IsServer() then return end
end

function modifier_miniboss_base:OnDeath( event )
	if (event.unit~=self:GetParent())
	or (not event.attacker:IsRealHero()) then return end
	print("hero killed buff")
	event.attacker:AddNewModifier(self:GetParent(), nil, self:GetName(), { duration = 120 })
end
