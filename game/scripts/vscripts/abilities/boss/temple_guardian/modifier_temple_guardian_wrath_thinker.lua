modifier_temple_guardian_wrath_thinker = class(ModifierBaseClass)

-----------------------------------------------------------------------------

function modifier_temple_guardian_wrath_thinker:OnCreated( kv )
	if IsServer() then
		self.delay = self:GetAbility():GetSpecialValueFor( "delay" )
		self.radius = self:GetAbility():GetSpecialValueFor( "radius" )
		self.blast_damage = self:GetAbility():GetSpecialValueFor( "blast_damage" )

		self:StartIntervalThink( self.delay )

		local nFXIndex = ParticleManager:CreateParticle( "particles/test_particle/dungeon_generic_blast_pre.vpcf", PATTACH_CUSTOMORIGIN, nil )
		ParticleManager:SetParticleControl( nFXIndex, 0, self:GetParent():GetOrigin() )
		ParticleManager:SetParticleControl( nFXIndex, 1, Vector( self.radius, self.delay, 1.0 ) )
		ParticleManager:SetParticleControl( nFXIndex, 15, Vector( 175, 238, 238 ) )
		ParticleManager:SetParticleControl( nFXIndex, 16, Vector( 1, 0, 0 ) )
		ParticleManager:ReleaseParticleIndex( nFXIndex )
	end
end

-----------------------------------------------------------------------------

function modifier_temple_guardian_wrath_thinker:OnIntervalThink()
  if IsServer() then
    local parent = self:GetParent()
    local nFXIndex = ParticleManager:CreateParticle( "particles/test_particle/dungeon_generic_blast.vpcf", PATTACH_CUSTOMORIGIN, nil )
    ParticleManager:SetParticleControl( nFXIndex, 0, parent:GetOrigin() )
    ParticleManager:SetParticleControl( nFXIndex, 1, Vector ( self.radius, self.radius, self.radius ) )
    ParticleManager:SetParticleControl( nFXIndex, 15, Vector( 175, 238, 238 ) )
    ParticleManager:SetParticleControl( nFXIndex, 16, Vector( 1, 0, 0 ) )
    ParticleManager:ReleaseParticleIndex( nFXIndex )

    parent:EmitSound("TempleGuardian.Wrath.Explosion")

    local enemies = FindUnitsInRadius(
      parent:GetTeamNumber(),
      parent:GetOrigin(),
      nil,
      self.radius,
      DOTA_UNIT_TARGET_TEAM_ENEMY,
      bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC),
      DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
      FIND_CLOSEST,
      false
    )
    local damageInfo = {
      attacker = self:GetCaster(),
      damage = self.blast_damage,
      damage_type = DAMAGE_TYPE_PURE,
      ability = self:GetAbility(),
    }
    for _, enemy in pairs( enemies ) do
      if enemy and not enemy:IsNull() and not enemy:IsInvulnerable() and not enemy:IsMagicImmune() then
        damageInfo.victim = enemy
        ApplyDamage( damageInfo )
      end
    end

    if parent and not parent:IsNull() then
      -- Instead of UTIL_Remove:
      self:StartIntervalThink(-1)
      parent:AddNoDraw()
      parent:ForceKillOAA(false)
    end
  end
end
