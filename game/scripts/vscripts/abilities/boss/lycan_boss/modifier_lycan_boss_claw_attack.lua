modifier_lycan_boss_claw_attack = class (ModifierBaseClass)

--------------------------------------------------------------------------------

function modifier_lycan_boss_claw_attack:IsHidden()
	return true
end

--------------------------------------------------------------------------------

function modifier_lycan_boss_claw_attack:IsPurgable()
	return false
end

--------------------------------------------------------------------------------

function modifier_lycan_boss_claw_attack:OnCreated( kv )
	if IsServer() then
		self.damage_radius = self:GetAbility():GetSpecialValueFor( "damage_radius" )
		self.damage = self:GetAbility():GetSpecialValueFor( "damage" )
		self.hHitTargets = {}
		self.flBeginAttackTime = GameRules:GetGameTime() + kv["initial_delay"]
		self.bPlayedSound = false
		self.bInit = false
		self.bShapeshift = self:GetCaster():FindModifierByName( "modifier_lycan_boss_shapeshift" ) ~= nil

		self:StartIntervalThink( 0.01 )
	end
end

--------------------------------------------------------------------------------

function modifier_lycan_boss_claw_attack:OnIntervalThink()
  if IsServer() then
    local parent = self:GetParent()
		if self.bInit == false then
			self.szSequenceName = parent:GetSequence()
			self.attachAttack1 = nil
			self.attachAttack2 = nil
			self.vLocation1 = nil
			self.vLocation2 = nil
			local szParticleName = "particles/test_particle/generic_attack_crit_blur.vpcf"
			if self.bShapeshift then
				szParticleName = "particles/test_particle/generic_attack_crit_blur_shapeshift.vpcf"
			end
			if self.szSequenceName == "attack_anim" or self.szSequenceName == "attack_alt2_anim" or self.szSequenceName == "attack3_anim" or self.szSequenceName == "attack2_alt_anim"  then
				self.attachAttack1 = parent:ScriptLookupAttachment( "attach_attack1" )

				local nFXIndex = ParticleManager:CreateParticle( szParticleName, PATTACH_CUSTOMORIGIN, parent )
				ParticleManager:SetParticleControlEnt( nFXIndex, 0, parent, PATTACH_POINT_FOLLOW, "attach_attack1", parent:GetOrigin(), true )
				ParticleManager:ReleaseParticleIndex( nFXIndex )
			end
			if self.szSequenceName == "attack_alt1_anim" or self.szSequenceName == "attack_alt2_anim" or self.szSequenceName == "attack3_anim" or self.szSequenceName == "attack_alt_anim"  then
				self.attachAttack2 = parent:ScriptLookupAttachment( "attach_attack2" )
				local nFXIndex2 = ParticleManager:CreateParticle( szParticleName, PATTACH_CUSTOMORIGIN, parent )
				ParticleManager:SetParticleControlEnt( nFXIndex2, 0, parent, PATTACH_POINT_FOLLOW, "attach_attack2", parent:GetOrigin(), true )
				ParticleManager:ReleaseParticleIndex( nFXIndex2 )
			end
			self.bInit = true
		end

		if GameRules:GetGameTime() < self.flBeginAttackTime then
			return
		end

		if self.bPlayedSound == false then
			parent:EmitSound("Roshan.PreAttack")
			self.bPlayedSound = true
		end

		local vForward = parent:GetForwardVector()
		parent:SetOrigin( parent:GetOrigin() + vForward * 10 )
		if self.attachAttack1 then
			self.vLocation1 = parent:GetAttachmentOrigin( self.attachAttack1 )
			--DebugDrawCircle( self.vLocation1, Vector( 0, 255, 0 ), 255, self.damage_radius, false, 1.0 )
			local enemies1 = FindUnitsInRadius( parent:GetTeamNumber(), self.vLocation1, self:GetCaster(), self.damage_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, 0, false )
			if #enemies1 > 0 then
				for _,enemy in pairs( enemies1 ) do
					if enemy and enemy:IsInvulnerable() == false and self:HasHitTarget( enemy ) == false then
						self:TryToHitTarget( enemy )
					end
				end
			end
		end

		if self.attachAttack2 then
			self.vLocation2 = parent:GetAttachmentOrigin( self.attachAttack2 )
			--DebugDrawCircle( self.vLocation2, Vector( 0, 0, 255 ), 255, self.damage_radius, false, 1.0 )
			local enemies2 = FindUnitsInRadius( parent:GetTeamNumber(), self.vLocation2, self:GetCaster(), self.damage_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, 0, false )
			if #enemies2 > 0 then
				for _,enemy in pairs( enemies2 ) do
					if enemy and enemy:IsInvulnerable() == false and self:HasHitTarget( enemy ) == false then
						self:TryToHitTarget( enemy )
					end
				end
			end
		end

		--DebugDrawCircle( self.vLocation2, Vector( 0, 0, 255 ), 255, self.damage_radius, false, 1.0 )
		local enemies3 = FindUnitsInRadius( parent:GetTeamNumber(), parent:GetOrigin(), self:GetCaster(), self.damage_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, 0, false )
		if #enemies3 > 0 then
			for _,enemy in pairs( enemies3 ) do
				if enemy and enemy:IsInvulnerable() == false and self:HasHitTarget( enemy ) == false then
					self:TryToHitTarget( enemy )
				end
			end
		end
	end
end

--------------------------------------------------------------------------------

function modifier_lycan_boss_claw_attack:DeclareFunctions()
	local funcs =
	{
		MODIFIER_PROPERTY_DISABLE_TURNING,
	}
	return funcs
end

--------------------------------------------------------------------------------

function modifier_lycan_boss_claw_attack:GetModifierDisableTurning( params )
	return 1
end

--------------------------------------------------------------------------------

function modifier_lycan_boss_claw_attack:TryToHitTarget( enemy )
  local parent = self:GetParent() -- parent is the same as the caster in this case
  local ability = self:GetAbility()
  local vToTarget = enemy:GetOrigin() - parent:GetOrigin()
  vToTarget = vToTarget:Normalized()
  local flDirectionDot = DotProduct( vToTarget, parent:GetForwardVector() )
  local flAngle = 180 * math.acos( flDirectionDot ) / math.pi
  if flAngle < 90 then
    self:AddHitTarget( enemy )
    -- Hit sound
    enemy:EmitSound("Roshan.Attack.Post")
    -- Damage table
    local damageInfo =
    {
      victim = enemy,
      attacker = parent,
      damage = self.damage,
      damage_type = DAMAGE_TYPE_PHYSICAL,
      ability = ability,
    }

    ApplyDamage( damageInfo )

    -- Stun only alive and non-spell-immune units
    if enemy:IsAlive() and not enemy:IsMagicImmune() then
      enemy:AddNewModifier(parent, ability, "modifier_stunned", {duration = ability:GetSpecialValueFor("stun_duration")})
    end
  end
end

--------------------------------------------------------------------------------

function modifier_lycan_boss_claw_attack:HasHitTarget( hTarget )
  for _, target in pairs( self.hHitTargets ) do
    if target == hTarget then
      return true
    end
  end

  return false
end

--------------------------------------------------------------------------------

function modifier_lycan_boss_claw_attack:AddHitTarget( hTarget )
	table.insert( self.hHitTargets, hTarget )
end

--------------------------------------------------------------------------------

function modifier_lycan_boss_claw_attack:OnDestroy()
	if IsServer() then
		FindClearSpaceForUnit( self:GetParent(), self:GetParent():GetOrigin(), false )
	end
end
