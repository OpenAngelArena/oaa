
tinkerer_smart_missiles = class({})

function tinkerer_smart_missiles:GetCastRange(location,target)
  local caster = self:GetCaster()
  if not caster then return 0 end

  local range = self:GetSpecialValueFor("cast_range")

  local talent =
  if talent and talent:GetLevel() > 0 then
    range = range + talent:GetSpecialValueFor("value")
  end

  return range
end

function tinkerer_smart_missiles:OnSpellStart()
  local caster = self:GetCaster()
  local target = self:GetCursorPosition()
  local caster_loc = caster:GetAbsOrigin()

  if not target then
    return
  end

  local direction = (target - caster_loc):Normalized()

  -- Self cast
  if target == caster_loc then
    direction = -caster:GetForwardVector()
  end

  --self.rocket_max_range_damage_percent = self:GetSpecialValueFor("rocket_max_range_damage_percent")
  --self.rocket_add_damage_range = self:GetSpecialValueFor("rocket_add_damage_range")
  --self.rocket_damage = self:GetSpecialValueFor("rocket_damage")
  local rocket_aoe = self:GetSpecialValueFor("rocket_aoe")
  local rocket_speed = self:GetSpecialValueFor("rocket_speed")
  --self.stun_duration = self:GetSpecialValueFor("stun_duration")
  --self.rocket_explode_vision = self:GetSpecialValueFor("rocket_explode_vision")

	local projectile_table = {
		Ability = self,
		EffectName = ".vpcf",
		vSpawnOrigin = caster_loc,
		fDistance = ,
		fStartRadius = self.rocket_aoe,
		fEndRadius = self.rocket_aoe,
		Source = caster,
		bHasFrontalCone = false,
		bReplaceExisting = false,
		iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
		iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		vVelocity = direction * self.rocket_speed * Vector(1, 1, 0),
		fExpireTime = GameRules:GetGameTime() + 10.0,
		bProvidesVision = true,
		iVisionRadius = self.rocket_aoe,
		iVisionTeamNumber = self.caster:GetTeamNumber(),
    ExtraData = {
        ox = tostring(self.caster:GetAbsOrigin().x),
        oy = tostring(self.caster:GetAbsOrigin().y),
        oz = tostring(self.caster:GetAbsOrigin().z)
    }
	}

	ProjectileManager:CreateLinearProjectile(projectile_table)

  caster:EmitSound("Hero_Tinker.Heat-Seeking_Missile")
end

function tinkerer_smart_missiles:OnProjectileHit_ExtraData(target,location,extradata)
  if not target then return false end

  local caster = self:GetCaster()
  local rocket_max_range_damage_percent = self:GetSpecialValueFor("rocket_max_range_damage_percent")
  local rocket_add_damage_range = self:GetSpecialValueFor("rocket_add_damage_range")
  local rocket_damage = self:GetSpecialValueFor("rocket_damage")
  local stun_duration = self:GetSpecialValueFor("stun_duration")
  local rocket_explode_vision = self:GetSpecialValueFor("rocket_explode_vision")

  local origin_position = Vector(tonumber(extradata.ox),tonumber(extradata.oy),tonumber(extradata.oz))

  local diff_distance = (location - origin_position)*Vector(1,1,0)
  diff_distance = diff_distance:Length2D()

  local is_additional_damage = math.max(0,diff_distance - rocket_add_damage_range)

  if is_additional_damage > 0 then
      if target:GetName() == "npc_dota_roshan" then
          is_additional_damage = 0
      else
          is_additional_damage = 1
      end
  end

  local new_damage = rocket_damage + (target:GetMaxHealth()*is_additional_damage*rocket_max_range_damage_percent*0.01)

  local explode_particle = ParticleManager:CreateParticle(".vpcf", PATTACH_ABSORIGIN, target)
  ParticleManager:SetParticleControl(explode_particle, 3, target:GetAbsOrigin())
  ParticleManager:ReleaseParticleIndex(explode_particle)

  AddFOWViewer(caster:GetTeamNumber(),location,rocket_explode_vision,1.5,false)

  EmitSoundOnLocationWithCaster(location,"Hero_Tinker.Heat-Seeking_Missile.Impact",caster)

  target:AddNewModifier(caster,self,"modifier_stunned", {duration = stun_duration})

  local damageTable = {
    victim = target,
    damage = new_damage,
    damage_type = DAMAGE_TYPE_MAGICAL,
    attacker = caster,
    ability = self
  }

  ApplyDamage(damageTable)


  local talent =
  if not talent or talent:GetLevel() <= 0 then
    return true
  end

  local explode_radius = talent:GetSpecialValueFor("explode_radius")
  local enemies = FindUnitsInRadius(
    caster:GetTeamNumber(),
    target:GetAbsOrigin(),
    nil,
    explode_radius,
    DOTA_UNIT_TARGET_TEAM_ENEMY,
    DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
    DOTA_UNIT_TARGET_FLAG_NONE,
    FIND_ANY_ORDER,
    false
  )

  for _, enemy in pairs(enemies) do
    if enemy and not enemy:IsNull() and enemy ~= target then
      enemy:AddNewModifier(self.caster,self,"modifier_stunned", {duration = self.stun_duration})

      damageTable.victim = enemy
      ApplyDamage(damageTable)
    end
  end

  return true
end
