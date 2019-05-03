require("modifiers/modifier_miniboss_base")
modifier_miniboss_red = class(modifier_miniboss_base)

function modifier_miniboss_red:GetTexture() return "ursa_enrage" end

function modifier_miniboss_red:OnCreated()
	if not IsServer() then return end
	self.outofcombat = false
	self:StartIntervalThink(3)
end

function modifier_miniboss_red:GetModifierConstantHealthRegen()
	return self.outofcombat and self:GetParent():GetMaxHealth()*0.02 or 0
end

function modifier_miniboss_red:OnAttackLanded( event )
	local target = event.target
	local attacker = event.attacker
	if attacker==self:GetParent() then
		target:AddNewModifier(attacker, nil, "modifier_miniboss_red_slow", { duration = 2.05 })
	end
end

function modifier_miniboss_red:OnTakeDamage( event )
	local target = event.unit
	local attacker = event.attacker
	if attacker==self:GetParent() or target==self:GetParent() then
		self:OnCreated()
	end
end

function modifier_miniboss_red:OnIntervalThink()
	self.outofcombat = true
end

LinkLuaModifier( "modifier_miniboss_red_slow", "modifiers/modifier_miniboss_red.lua", LUA_MODIFIER_MOTION_NONE )
------------------------------------------------------------------------
modifier_miniboss_red_slow = class(ModifierBaseClass)
------------------------------------------------------------------------

function modifier_miniboss_red_slow:GetTexture() return "silencer_glaives_of_wisdom" end

function modifier_miniboss_red_slow:DeclareFunctions()
	return {	MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, -- GetModifierMoveSpeedBonus_Percentage
	}
end

function modifier_miniboss_red_slow:GetModifierMoveSpeedBonus_Percentage() return -15 end

function modifier_miniboss_red_slow:OnCreated()
	if not IsServer() then return end
	self:StartIntervalThink(1)
end

function modifier_miniboss_red_slow:OnIntervalThink()
	local damage = ApplyDamage({
				victim = self:GetParent(),
				attacker = self:GetCaster(),
				damage = self:GetParent():GetMaxHealth()*0.02,
				damage_type = DAMAGE_TYPE_PURE,
				ability = nil,
			})
	SendOverheadEventMessage( nil, OVERHEAD_ALERT_DAMAGE, self:GetParent(), damage, nil )
end
