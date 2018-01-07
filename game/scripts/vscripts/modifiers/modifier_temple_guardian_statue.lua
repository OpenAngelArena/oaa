modifier_temple_guardian_statue = class(ModifierBaseClass)

-----------------------------------------------------------------------------

function modifier_temple_guardian_statue:IsHidden()
	return true
end

-------------------------------------------------------------------

function modifier_temple_guardian_statue:OnCreated( kv )
	if IsServer() then
		self:GetParent():SetAngles( 0, - 90.0, 0 )
		self:GetParent():StartGesture( ACT_DOTA_CAST_ABILITY_7 )
	end
end

--------------------------------------------------------------------------------



