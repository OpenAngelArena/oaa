LinkLuaModifier( "modifier_lycan_boss_shapeshift_transform", "abilities/boss/lycan_boss/modifier_lycan_boss_shapeshift_transform", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_lycan_boss_shapeshift", "abilities/boss/lycan_boss/modifier_lycan_boss_shapeshift", LUA_MODIFIER_MOTION_NONE )

lycan_boss_shapeshift_tier5 = class(AbilityBaseClass)

--------------------------------------------------------------------------------

function lycan_boss_shapeshift_tier5:OnAbilityPhaseStart()
	if IsServer() then
		self:GetCaster():EmitSound("lycan_lycan_ability_shapeshift_06")
	end
	return true
end

--------------------------------------------------------------------------------

function lycan_boss_shapeshift_tier5:OnSpellStart()
  self:GetCaster():AddNewModifier( self:GetCaster(), self, "modifier_lycan_boss_shapeshift_transform", { duration = self:GetSpecialValueFor( "transformation_time" ) } )
end
