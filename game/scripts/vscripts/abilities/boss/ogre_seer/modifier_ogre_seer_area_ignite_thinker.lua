
modifier_ogre_seer_area_ignite_thinker = class( ModifierBaseClass )

----------------------------------------------------------------------------------------

function modifier_ogre_seer_area_ignite_thinker:OnCreated( kv )
	if IsServer() then
		self.radius = self:GetAbility():GetSpecialValueFor( "radius" )
		self.area_duration = self:GetAbility():GetSpecialValueFor( "area_duration" )
		self.duration = self:GetAbility():GetSpecialValueFor( "duration" )
		self.bImpact = false
	end
end

----------------------------------------------------------------------------------------

function modifier_ogre_seer_area_ignite_thinker:OnImpact()
  if IsServer() then
    local parent = self:GetParent()
		local nFXIndex = ParticleManager:CreateParticle( "particles/neutral_fx/black_dragon_fireball.vpcf", PATTACH_WORLDORIGIN, nil )
		ParticleManager:SetParticleControl( nFXIndex, 0, parent:GetOrigin() )
		ParticleManager:SetParticleControl( nFXIndex, 1, parent:GetOrigin() )
		ParticleManager:SetParticleControl( nFXIndex, 2, Vector( self.area_duration, 0, 0 ) )
		ParticleManager:ReleaseParticleIndex( nFXIndex )

		parent:EmitSound("OgreMagi.Ignite.Target")

		self:SetDuration( self.area_duration, true )
		self.bImpact = true

		self:StartIntervalThink( 0.5 )
	end
end

----------------------------------------------------------------------------------------

function modifier_ogre_seer_area_ignite_thinker:OnIntervalThink()
	if IsServer() then
		if self.bImpact == false then
			self:OnImpact()
			return
		end

    local parent = self:GetParent()
		local enemies = FindUnitsInRadius(
      parent:GetTeamNumber(),
      parent:GetOrigin(),
      nil,
      self.radius,
      DOTA_UNIT_TARGET_TEAM_ENEMY,
      bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC),
      DOTA_UNIT_TARGET_FLAG_NONE,
      FIND_ANY_ORDER,
      false
    )
		for _, enemy in pairs( enemies ) do
			if enemy and not enemy:IsNull() and not enemy:IsMagicImmune() and not enemy:IsDebuffImmune() then
				enemy:AddNewModifier( parent, self:GetAbility(), "modifier_ogre_seer_ignite_debuff", { duration = self.duration } )
			end
		end
	end
end

----------------------------------------------------------------------------------------

modifier_ogre_seer_ignite_debuff = class(ModifierBaseClass)

function modifier_ogre_seer_ignite_debuff:IsHidden()
  return true
end

function modifier_ogre_seer_ignite_debuff:IsPurgable()
  return true
end

function modifier_ogre_seer_ignite_debuff:IsDebuff()
  return true
end

function modifier_ogre_seer_ignite_debuff:DestroyOnExpire()
  return true
end

function modifier_ogre_seer_ignite_debuff:OnCreated()
  local damage_per_second = 400
  local interval = 0.2
  local damage_type = DAMAGE_TYPE_MAGICAL
  local slow = -30
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    damage_per_second = ability:GetSpecialValueFor("burn_damage")
    interval = ability:GetSpecialValueFor("damage_interval")
    slow = ability:GetSpecialValueFor("slow_movement_speed_pct")
    if IsServer() then
      damage_type = ability:GetAbilityDamageType()
    end
  end
  self.damage_per_interval = damage_per_second*interval
  self.slow = slow
  self.damage_type = damage_type
  if IsServer() then
    self:OnIntervalThink()
    self:StartIntervalThink(interval)
  end
end

function modifier_ogre_seer_ignite_debuff:OnIntervalThink()
  local parent = self:GetParent()
  local ability = self:GetAbility()
  local caster = self:GetCaster()
  if caster and not caster:IsNull() then
    -- Creating the damage table
    local damage_table = {
      attacker = caster,
      victim = parent,
      damage = self.damage_per_interval,
      damage_type = self.damage_type,
      ability = ability,
    }

    -- Apply damage on interval
    ApplyDamage(damage_table)
  end
end

function modifier_ogre_seer_ignite_debuff:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
  }
end

function modifier_ogre_seer_ignite_debuff:GetModifierMoveSpeedBonus_Percentage()
  return 0 - math.abs(self.slow)
end

function modifier_ogre_seer_ignite_debuff:GetTexture()
  return "ogre_magi_ignite"
end

function modifier_ogre_seer_ignite_debuff:GetEffectName()
  return "particles/units/heroes/hero_ogre_magi/ogre_magi_ignite_debuff.vpcf"
end
