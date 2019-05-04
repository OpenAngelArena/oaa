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
	if  not self:GetParent():FindModifierByName("modifier_miniboss_red")
	and not self:GetParent():FindModifierByName("modifier_miniboss_blue") then
		self:StartIntervalThink(0.2)
	end
end

function modifier_miniboss_base:OnIntervalThink()
	if not IsServer() then return end
	local red = GameRules:GetGameModeEntity()["modifier_miniboss_red"]
	local blue = GameRules:GetGameModeEntity()["modifier_miniboss_blue"]
	local newmod = false
	if (not blue) and (not red) then
		if RollPercentage(50)	then newmod = "modifier_miniboss_red"
								else newmod = "modifier_miniboss_blue" end
	elseif not red then newmod = "modifier_miniboss_red"
	elseif not blue then newmod = "modifier_miniboss_blue"
	end
	if newmod then
		GameRules:GetGameModeEntity()[newmod] = self:GetParent():AddNewModifier(self:GetParent(), nil, newmod, {})
		GameRules:GetGameModeEntity()[newmod].original = true
		self:StartIntervalThink(-1)
	end
end

function modifier_miniboss_base:OnDeath( event )
	if (not IsServer()) or (event.unit~=self:GetParent()) then return end
	if self.original then GameRules:GetGameModeEntity()[self:GetName()] = nil end
	if (self:GetName()=="modifier_miniboss_base")
	or (not event.attacker:IsRealHero()) then return end
	print("hero killed buff")
	event.attacker:AddNewModifier(self:GetParent(), nil, self:GetName(), { duration = 120 })
end
