modifier_temple_guardian_hammer_throw = class(ModifierBaseClass)

-------------------------------------------------------------------

function modifier_temple_guardian_hammer_throw:IsHidden()
	return true
end

-------------------------------------------------------------------

function modifier_temple_guardian_hammer_throw:IsPurgable()
	return false
end

-------------------------------------------------------------------

function modifier_temple_guardian_hammer_throw:RemoveOnDeath()
	return false
end

-------------------------------------------------------------------

function modifier_temple_guardian_hammer_throw:OnCreated( kv )
  if IsServer() then
    local caster = self:GetCaster()
		self.hammer_damage = self:GetAbility():GetSpecialValueFor( "hammer_damage" )
		self.throw_duration = self:GetAbility():GetSpecialValueFor( "throw_duration" )
		self.stun_duration = self:GetAbility():GetSpecialValueFor( "stun_duration" )
		self.radius = self:GetAbility():GetSpecialValueFor( "radius" )

		self.hHitEntities = {}

		self.hHammer = CreateUnitByName( "npc_dota_beastmaster_axe", self:GetParent():GetOrigin(), false, nil, nil, self:GetParent():GetTeamNumber() )
		if self.hHammer == nil then
			self:Destroy()
			return
		end

		self.hHammer:AddEffects( EF_NODRAW )
		self.hHammer:AddNewModifier( caster, self:GetAbility(), "modifier_beastmaster_axe_invulnerable", kv )

		self.vSourceLoc = caster:GetOrigin()
		self.vSourceLoc.z = self.vSourceLoc.z + 180
		self.vTargetLoc = Vector( kv["x"], kv["y"], self.vSourceLoc.z )
		self.vToTarget = self.vTargetLoc - self.vSourceLoc
		self.vDir = self.vToTarget:Normalized()
		self.flDist = self.vToTarget:Length2D()

		self.flDieTime = GameRules:GetGameTime() + self.throw_duration
		self.bReturning = false

		self.nFXIndex = ParticleManager:CreateParticle( "particles/test_particle/omniknight_wildaxe.vpcf", PATTACH_CUSTOMORIGIN, nil )
		ParticleManager:SetParticleControlEnt( self.nFXIndex, 0, self.hHammer, PATTACH_ABSORIGIN_FOLLOW, nil, self.hHammer:GetOrigin(), true )

		caster:EmitSound("TempleGuardian.HammerThrow")

		self:StartIntervalThink( 0.05 )
	end
end

-------------------------------------------------------------------

function modifier_temple_guardian_hammer_throw:OnIntervalThink()
  local caster = self:GetCaster()
  local flPct = ( self.flDieTime - GameRules:GetGameTime() ) / self.throw_duration
  local t = 1.0 - flPct

  local vPos = self.vSourceLoc + ( self.vDir * self.flDist * t * 2 )
  if self.bReturning == true then
    vPos = self.vTargetLoc - ( self.vDir * self.flDist * ( t - 0.5 ) * 2 )
  end

  if FrameTime() > 0.0 then
    local vVel = vPos - self.hHammer:GetOrigin() / FrameTime()
    self.hHammer:SetVelocity( vVel )
  end

  self.hHammer:SetOrigin( vPos )

  local enemies = FindUnitsInRadius(
    self:GetParent():GetTeamNumber(),
    self.hHammer:GetOrigin(),
    nil,
    self.radius,
    DOTA_UNIT_TARGET_TEAM_ENEMY,
    DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
    DOTA_UNIT_TARGET_FLAG_NONE,
    FIND_ANY_ORDER,
    false
  )

  local damageTable = {
    attacker = caster,
    damage = self.hammer_damage,
    damage_type = DAMAGE_TYPE_PURE,
    ability = self:GetAbility(),
  }

  for _, enemy in pairs( enemies ) do
    if enemy and not enemy:IsNull() and not self:HasHitTarget( enemy ) then
      self:AddHitTarget( enemy )

      enemy:EmitSound("TempleGuardian.HammerThrow.Damage")

      if not enemy:IsMagicImmune() and not enemy:IsDebuffImmune() then
        local actual_duration = enemy:GetValueChangedByStatusResistance(self.stun_duration)
        enemy:AddNewModifier(caster, self:GetAbility(), "modifier_stunned", {duration = actual_duration})

        local nFXIndex = ParticleManager:CreateParticle( "particles/units/heroes/hero_beastmaster/beastmaster_wildaxes_hit.vpcf", PATTACH_CUSTOMORIGIN, nil )
        ParticleManager:SetParticleControlEnt( nFXIndex, 0, enemy, PATTACH_POINT_FOLLOW, "attach_hitloc", enemy:GetOrigin(), true )
        ParticleManager:ReleaseParticleIndex( nFXIndex )

        damageTable.victim = enemy
        ApplyDamage( damageTable )
      end
    end
  end

  if t >= 0.5 then
    self.bReturning = true
  end

  if t >= 0.95 then
    self:Destroy()
  end
end

-------------------------------------------------------------------

function modifier_temple_guardian_hammer_throw:OnDestroy()
	if IsServer() then
		UTIL_Remove( self.hHammer )
		ParticleManager:DestroyParticle( self.nFXIndex, true )
	end
end

-------------------------------------------------------------------

function modifier_temple_guardian_hammer_throw:HasHitTarget( enemy )
	if IsServer() then
		for _,hitEnemy in pairs( self.hHitEntities ) do
			if hitEnemy == enemy then
				return true
			end
		end
		return false
	end
end

-------------------------------------------------------------------

function modifier_temple_guardian_hammer_throw:AddHitTarget( enemy )
	if IsServer() then
		table.insert( self.hHitEntities, enemy )
	end
end

-------------------------------------------------------------------
