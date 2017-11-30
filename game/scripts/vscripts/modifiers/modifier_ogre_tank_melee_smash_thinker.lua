
modifier_ogre_tank_melee_smash_thinker = class( ModifierBaseClass )

-----------------------------------------------------------------------------

function modifier_ogre_tank_melee_smash_thinker:OnCreated( kv )
	if IsServer() then
		self.impact_radius = self:GetAbility():GetSpecialValueFor( "impact_radius" )
		self.stun_duration = self:GetAbility():GetSpecialValueFor( "stun_duration" )
		self.damage = self:GetAbility():GetSpecialValueFor( "damage" )

		self:StartIntervalThink( 0.01 )
	end
end

-----------------------------------------------------------------------------

function modifier_ogre_tank_melee_smash_thinker:OnIntervalThink()
	if IsServer() then
		if self:GetCaster() == nil or self:GetCaster():IsNull() or self:GetCaster():IsAlive() == false or self:GetCaster():IsStunned() then
			--print( string.format( "Caster is nil, dead, or stunned, removing smash thinker" ) )
			UTIL_Remove( self:GetParent() )
			return -1
		end
	end
end

-----------------------------------------------------------------------------

function modifier_ogre_tank_melee_smash_thinker:OnDestroy()
	if IsServer() then
		if self:GetCaster() ~= nil and self:GetCaster():IsAlive() then
			EmitSoundOnLocationWithCaster( self:GetParent():GetOrigin(), "OgreTank.GroundSmash", self:GetCaster() )
			local smashParticle = ParticleManager:CreateParticle( "particles/test_particle/ogre_melee_smash.vpcf", PATTACH_WORLDORIGIN,  self:GetCaster()  )
			ParticleManager:SetParticleControl( smashParticle, 0, self:GetParent():GetOrigin() )
			ParticleManager:SetParticleControl( smashParticle, 1, Vector( self.impact_radius, self.impact_radius, self.impact_radius ) )
			ParticleManager:ReleaseParticleIndex( smashParticle )

			local enemies = FindUnitsInRadius( self:GetParent():GetTeamNumber(), self:GetParent():GetOrigin(), self:GetParent(), self.impact_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, 0, false )
			local critParticle = ParticleManager:CreateParticle( "particles/units/heroes/hero_phantom_assassin/phantom_assassin_crit_impact.vpcf", PATTACH_CUSTOMORIGIN, nil )
			for _,enemy in pairs( enemies ) do
				if enemy ~= nil and enemy:IsInvulnerable() == false then
					local damageInfo =
					{
						victim = enemy,
						attacker = self:GetCaster(),
						damage = self.damage,
						damage_type = DAMAGE_TYPE_PHYSICAL,
						ability = self,
					}

					ApplyDamage( damageInfo )
					if enemy:IsAlive() == false then
						ParticleManager:SetParticleControlEnt( critParticle, 0, enemy, PATTACH_POINT_FOLLOW, "attach_hitloc", enemy:GetOrigin(), true )
						ParticleManager:SetParticleControl( critParticle, 1, enemy:GetOrigin() )
						ParticleManager:SetParticleControlForward( critParticle, 1, -self:GetCaster():GetForwardVector() )
						ParticleManager:SetParticleControlEnt( critParticle, 10, enemy, PATTACH_ABSORIGIN_FOLLOW, nil, enemy:GetOrigin(), true )

						EmitSoundOn( "Dungeon.BloodSplatterImpact", enemy )
					else
						enemy:AddNewModifier( self:GetCaster(), self:GetAbility(), "modifier_stunned", { duration = self.stun_duration } )
					end
				end
			end
			ParticleManager:ReleaseParticleIndex( critParticle )
		end

		ScreenShake( self:GetParent():GetOrigin(), 10.0, 100.0, 0.5, 1300.0, 0, true )

		UTIL_Remove( self:GetParent() )
	end
end

-----------------------------------------------------------------------------

