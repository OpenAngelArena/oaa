modifier_lycan_boss_shapeshift_transform = class(ModifierBaseClass)

--------------------------------------------------------------------------------

function modifier_lycan_boss_shapeshift_transform:OnCreated( kv )
  if IsServer() then
    local parent = self:GetParent()
		parent:StartGesture( ACT_DOTA_OVERRIDE_ABILITY_4 )
		parent:EmitSound("LycanBoss.Shapeshift.Cast")

		local nFXIndex = ParticleManager:CreateParticle( "particles/units/heroes/hero_lycan/lycan_shapeshift_cast.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent )
		ParticleManager:SetParticleControlEnt( nFXIndex, 1, parent, PATTACH_POINT_FOLLOW, "attach_hitloc", parent:GetOrigin(), true )
		ParticleManager:ReleaseParticleIndex( nFXIndex )
	end
end

--------------------------------------------------------------------------------

function modifier_lycan_boss_shapeshift_transform:OnDestroy()
	if IsServer() then
		if self:GetParent():IsAlive() == false then
			return
		end
		self:GetParent():AddNewModifier( self:GetCaster(), self:GetAbility(), "modifier_lycan_boss_shapeshift", { duration = self:GetAbility():GetSpecialValueFor( "duration" ) } )
	end
end

--------------------------------------------------------------------------------

function modifier_lycan_boss_shapeshift_transform:CheckState()
	local state =
	{
		[MODIFIER_STATE_STUNNED] = true,
	}
	return state
end
