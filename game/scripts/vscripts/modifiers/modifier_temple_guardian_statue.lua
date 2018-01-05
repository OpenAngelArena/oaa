modifier_temple_guardian_statue = class(ModifierBaseClass)

-----------------------------------------------------------------------------

function modifier_temple_guardian_statue:IsHidden()
	return true
end

-------------------------------------------------------------------

function modifier_temple_guardian_statue:OnCreated( kv )
	if IsServer() then
		local vAngles = self:GetParent():GetAnglesAsVector()
		self:GetParent():SetAngles( vAngles.x, vAngles.y - 90.0, vAngles.z )
		self:GetParent():StartGesture( ACT_DOTA_CAST_ABILITY_7 )
	end
end

--------------------------------------------------------------------------------



