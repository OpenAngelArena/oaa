LinkLuaModifier("modifier_tormentor_unyielding_shield_oaa", "abilities/boss/tormentor_boss/tormentor_unyielding_shield.lua", LUA_MODIFIER_MOTION_NONE)

tormentor_boss_unyielding_shield_oaa = class(AbilityBaseClass)

function tormentor_boss_unyielding_shield_oaa:GetIntrinsicModifierName()
	return "modifier_tormentor_unyielding_shield_oaa"
end

function tormentor_boss_unyielding_shield_oaa:IsStealable()
  return false
end

function tormentor_boss_unyielding_shield_oaa:ProcMagicStick()
  return false
end

---------------------------------------------------------------------------------------------------

modifier_tormentor_unyielding_shield_oaa = class(ModifierBaseClass)

function modifier_tormentor_unyielding_shield_oaa:IsHidden() -- needs tooltip
	return false
end

function modifier_tormentor_unyielding_shield_oaa:IsDebuff()
	return false
end

function modifier_tormentor_unyielding_shield_oaa:IsPurgable()
	return false
end

function modifier_tormentor_unyielding_shield_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_INCOMING_DAMAGE_CONSTANT,
    MODIFIER_PROPERTY_TOOLTIP,
    MODIFIER_PROPERTY_TOOLTIP2,
  }
end

function modifier_tormentor_unyielding_shield_oaa:OnCreated()
	if not IsServer() then return end

	local parent = self:GetParent()
	local ability = self:GetAbility()

	parent:EmitSound("Miniboss.Tormenter.Spawn")

	-- This delay is required because the tormentor team is not set yet when the modifier is created
	GameRules:GetGameModeEntity():SetContextThink(DoUniqueString("delay"), function()
		self.maxShield = ability:GetSpecialValueFor("damage_absorb")
		self.currentShield = self.maxShield
		self.regenPerSecond = ability:GetSpecialValueFor("regen_per_second")
		self.regenPerSecondThink = self.regenPerSecond * FrameTime()

		self:SetHasCustomTransmitterData(true)
		self:StartIntervalThink(FrameTime())
	end, FrameTime())
end

function modifier_tormentor_unyielding_shield_oaa:OnRefresh()
	self:OnCreated()

	-- Tell the client that we need to get the properties again
	if IsServer() then self:SendBuffRefreshToClients() end
end

function modifier_tormentor_unyielding_shield_oaa:AddCustomTransmitterData()
	return {
		currentShield = self.currentShield,
		maxShield = self.maxShield,
		regenPerSecond = self.regenPerSecond, -- sent to client only because of MODIFIER_PROPERTY_TOOLTIP2
	}
end

function modifier_tormentor_unyielding_shield_oaa:HandleCustomTransmitterData(data)
	self.currentShield = data.currentShield
	self.maxShield = data.maxShield
	self.regenPerSecond = data.regenPerSecond
end

function modifier_tormentor_unyielding_shield_oaa:OnIntervalThink()
	self.currentShield = math.min(self.currentShield + self.regenPerSecondThink, self.maxShield)
	self:SendBuffRefreshToClients()
end

function modifier_tormentor_unyielding_shield_oaa:GetModifierIncomingDamageConstant(event)
	-- Return the max health on the client if it's a max report, otherwise return the current health
	if IsClient() then
		if event.report_max then
			return self.maxShield
		else
			return self.currentShield
		end
	else
		local damage = event.damage

		-- Don't do anything if damage is 0 or somehow negative
		if damage <= 0 then
			return 0
		end

		-- Don't react to damage with HP removal flag
		if bit.band(event.damage_flags, DOTA_DAMAGE_FLAG_HPLOSS) == DOTA_DAMAGE_FLAG_HPLOSS then
			return 0
		end

		-- Don't block more than remaining hp
		local barrier_hp = self.currentShield
		local block_amount = math.min(damage, barrier_hp)

		-- Reduce barrier hp
		self.currentShield = self.currentShield - block_amount

		if block_amount > 0 then
			-- Visual effect
			local parent = self:GetParent()
			SendOverheadEventMessage(nil, OVERHEAD_ALERT_BLOCK, parent, block_amount, nil)
		end

		-- Tell the client that we need to update the health property
		self:SendBuffRefreshToClients()

		-- EmitSoundOnClient("Miniboss.Tormenter.Target", event.attacker)
		event.attacker:EmitSound("Miniboss.Tormenter.Target")

		return -block_amount
	end
end

function modifier_tormentor_unyielding_shield_oaa:OnTooltip()
	return self.maxShield
end

function modifier_tormentor_unyielding_shield_oaa:OnTooltip2()
	return self.regenPerSecond
end

function modifier_tormentor_unyielding_shield_oaa:GetPriority()
  return MODIFIER_PRIORITY_SUPER_ULTRA + 20000 -- it needs to be higher priority than boss properties
end

function modifier_tormentor_unyielding_shield_oaa:CheckState()
  return {
    [MODIFIER_STATE_ROOTED] = true, -- to prevent tormentor from moving
    [MODIFIER_STATE_CANNOT_BE_MOTION_CONTROLLED] = true, -- to prevent the tormentor from being pushed or knocked back
  }
end
