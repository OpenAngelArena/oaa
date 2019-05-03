miniboss_apply_buff = class(AbilityBaseClass)

LinkLuaModifier( "modifier_miniboss_base", "abilites/miniboss_apply_buff.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_miniboss_blue", "modifiers/modifier_miniboss_blue.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_miniboss_red", "modifiers/modifier_miniboss_red.lua", LUA_MODIFIER_MOTION_NONE )

function miniboss_apply_buff:GetIntrinsicModifierName()
	return "modifier_miniboss_base"
end

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
	local dragons = Entities:FindAllByName("npc_dota_miniboss_dragon")
	local usedBuffs = {}
	for e,dragon in pairs(dragons) do
		if dragon:FindModifierByName("modifier_miniboss_red") then
			usedBuffs.red=true end
		if dragon:FindModifierByName("modifier_miniboss_blue") then
			usedBuffs.blue=true end
	end
	if not usedBuffs.red then
		self:GetParent():AddNewModifier(self:GetParent(), nil, "modifier_miniboss_red", {})
		self:Destroy()
	elseif not usedBuffs.blue then
		self:GetParent():AddNewModifier(self:GetParent(), nil, "modifier_miniboss_blue", {})
		self:Destroy()
	end
end

function modifier_miniboss_base:OnDeath( event )
	if (event.unit~=self:GetParent())
	or (not event.attacker:IsRealHero()) then return end
	print("hero killed buff")
	event.attacker:AddNewModifier(self:GetParent(), nil, self:GetName(), { duration = 120 })
end
