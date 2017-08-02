abyssal_underlord_cancel_dark_rift_oaa = class( AbilityBaseClass )

--------------------------------------------------------------------------------

function abyssal_underlord_cancel_dark_rift_oaa:IsStealable()
	return false
end

--------------------------------------------------------------------------------

function abyssal_underlord_cancel_dark_rift_oaa:ProcsMagicStick()
	return false
end

--------------------------------------------------------------------------------

function abyssal_underlord_cancel_dark_rift_oaa:OnSpellStart()
	local caster = self:GetCaster()

	-- play modified gesture
	caster:StartGesture( ACT_DOTA_OVERRIDE_ABILITY_4 )

	-- remove the oldest timer modifier
	caster:RemoveModifierByName( "modifier_abyssal_underlord_dark_rift_oaa_timer" )
end