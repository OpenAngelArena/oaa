boss_regen = class( AbilityBaseClass )

LinkLuaModifier( "modifier_boss_regen", "abilities/boss_regen.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_boss_regen_degen", "abilities/boss_regen.lua", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------

function boss_regen:GetIntrinsicModifierName()
	return "modifier_boss_regen"
end

--------------------------------------------------------------------------------

modifier_boss_regen = class( ModifierBaseClass )

--------------------------------------------------------------------------------

function modifier_boss_regen:IsHidden()
	return true
end

function modifier_boss_regen:IsDebuff()
	return false
end

function modifier_boss_regen:IsPurgable()
	return false
end

function modifier_boss_regen:RemoveOnDeath()
	return false
end

--------------------------------------------------------------------------------

function modifier_boss_regen:OnCreated( event )
	local spell = self:GetAbility()

	spell.paused = false
	self:StartIntervalThink( spell:GetSpecialValueFor( "regen_interval" ) )
end


function modifier_boss_regen:OnRefresh( event )
	self:OnCreated( event )
end

--------------------------------------------------------------------------------

if IsServer() then
	function modifier_boss_regen:OnIntervalThink()
		local parent = self:GetParent()
		local spell = self:GetAbility()
		local interval = spell:GetSpecialValueFor( "regen_interval" )

		local duelPauses = spell:GetSpecialValueFor( "pauses_during_duel" ) > 0

		if duelPauses then
			if Duels:IsActive() then
				if not spell.paused then
					-- why does the cool stuff never work
					--spell:SetFrozenCooldown( true )
					spell.paused = true
					spell.pausedCD = spell:GetCooldownTimeRemaining()
				end

				if spell.pausedCD and spell.pausedCD > 0 then
					spell:EndCooldown()
					spell:StartCooldown( spell.pausedCD + interval )
				end

				return
			else
				if spell.paused then
					--spell:SetFrozenCooldown( false )
					spell.paused = false
				end
			end
		end

		if not spell:IsCooldownReady() then
			return
		end

		local regen = ( spell:GetSpecialValueFor( "health_regen_rate" ) / 100 ) * interval
		local oldHealth = parent:GetHealth()
		parent:Heal( parent:GetMaxHealth() * regen, parent )
		local realHeal = parent:GetHealth() - oldHealth

		if realHeal > 0 then
			SendOverheadEventMessage( nil, OVERHEAD_ALERT_HEAL, parent, realHeal, nil )
		end
	end
end

--------------------------------------------------------------------------------

function modifier_boss_regen:DeclareFunctions()
	local funcs = {
		MODIFIER_EVENT_ON_TAKEDAMAGE,
	}

	return funcs
end

--------------------------------------------------------------------------------

if IsServer() then
	function modifier_boss_regen:OnTakeDamage( event )
		local parent = self:GetParent()

		if event.unit ~= parent then
			return
		end

		-- don't count self-damage
		if event.attacker == parent then
			return
		end

		if event.damage <= 0 then
			return
		end

		local spell = self:GetAbility()

		parent:AddNewModifier( parent, spell, "modifier_boss_regen_degen", {
			duration = spell:GetSpecialValueFor( "degen_duration" ),
		} )

		spell:EndCooldown()
		spell:UseResources( false, false, true )
	end
end

--------------------------------------------------------------------------------

modifier_boss_regen_degen = class( ModifierBaseClass )

--------------------------------------------------------------------------------

function modifier_boss_regen_degen:IsHidden()
	return false
end

function modifier_boss_regen_degen:IsDebuff()
	return true
end

function modifier_boss_regen_degen:IsPurgable()
	return false
end

function modifier_boss_regen_degen:RemoveOnDeath()
	return true
end

--------------------------------------------------------------------------------

function modifier_boss_regen_degen:OnCreated( event )
	local spell = self:GetAbility()

	self:StartIntervalThink( spell:GetSpecialValueFor( "degen_interval" ) )
end


function modifier_boss_regen_degen:OnRefresh( event )
	--self:OnCreated( event )
end

--------------------------------------------------------------------------------

if IsServer() then
	function modifier_boss_regen_degen:OnIntervalThink()
		local parent = self:GetParent()
		local spell = self:GetAbility()
		local interval = spell:GetSpecialValueFor( "degen_interval" )

		if spell.paused then
			self:SetDuration( self:GetRemainingTime() + interval, true )
			return
		end

		-- can't regen and degen at the same time
		-- assume the spell refreshed somehow through a boss ability
		if spell:IsCooldownReady() then
			self:Destroy()
			return
		end

		local degen = ( spell:GetSpecialValueFor( "health_degen_rate" ) / 100 ) * interval
		local damage = ApplyDamage( {
			victim = parent,
			attacker = parent,
			damage = parent:GetMaxHealth() * degen,
			damage_type = DAMAGE_TYPE_PURE,
			damage_flags = bit.bor( DOTA_DAMAGE_FLAG_BYPASSES_BLOCK, DOTA_DAMAGE_FLAG_HPLOSS, DOTA_DAMAGE_FLAG_NON_LETHAL, DOTA_DAMAGE_FLAG_NO_DAMAGE_MULTIPLIERS, DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION ),
			ability = spell,
		} )

		if damage > 0 then
			SendOverheadEventMessage( nil, OVERHEAD_ALERT_DAMAGE, parent, damage, nil )
		end
	end
end

--------------------------------------------------------------------------------

function modifier_boss_regen_degen:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_TOOLTIP,
	}

	return funcs
end

--------------------------------------------------------------------------------

function modifier_boss_regen_degen:OnTooltip( event )
	local spell = self:GetAbility()

	return spell:GetSpecialValueFor( "health_degen_rate" )
end
