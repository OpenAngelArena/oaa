abyssal_underlord_dark_rift_oaa = class(AbilityBaseClass)

LinkLuaModifier("modifier_underlord_dark_rift_oaa_stun", "abilities/oaa_dark_rift.lua", LUA_MODIFIER_MOTION_NONE)

--------------------------------------------------------------------------------

function abyssal_underlord_dark_rift_oaa:GetAOERadius()
  return self:GetSpecialValueFor("radius")
end

function abyssal_underlord_dark_rift_oaa:GetCastAnimation()
 return ACT_DOTA_CAST_ABILITY_4
end

function abyssal_underlord_dark_rift_oaa:GetAssociatedSecondaryAbilities()
	return "abyssal_underlord_cancel_dark_rift_oaa"
end

function abyssal_underlord_dark_rift_oaa:OnUpgrade()
  local abilityLevel = self:GetLevel()
  local sub_ability = self:GetCaster():FindAbilityByName("abyssal_underlord_cancel_dark_rift_oaa")

	-- Check to not enter a level up loop
  if sub_ability and sub_ability:GetLevel() ~= abilityLevel then
		sub_ability:SetLevel(abilityLevel)
	end
end

function abyssal_underlord_dark_rift_oaa:OnSpellStart()
  local caster = self:GetCaster()
  local originCaster = caster:GetAbsOrigin()
  local pos = self:GetCursorPosition()
  local minRange = self:GetSpecialValueFor("minimum_range")
  local vectorTarget = pos - originCaster

  -- if the target point is too close, push it out to minimum range
  if vectorTarget:Length2D() < minRange then
    pos = originCaster + ( vectorTarget:Normalized() * minRange )
  end

  local radius = self:GetSpecialValueFor( "radius" )
  self.originSecond = GetGroundPosition( Vector(pos.x, pos.y, 0), caster)

  -- create portal particle on caster location
  local partPortal1 = ParticleManager:CreateParticle( "particles/units/heroes/heroes_underlord/abyssal_underlord_dark_rift_portal.vpcf", PATTACH_WORLDORIGIN, caster )
  ParticleManager:SetParticleControl( partPortal1, 0, originCaster )
  ParticleManager:SetParticleControl( partPortal1, 2, originCaster )
  ParticleManager:SetParticleControl( partPortal1, 1, Vector( radius, 1, 1 ) )

  -- create portal particle on destination
  local partPortal2 = ParticleManager:CreateParticle( "particles/units/heroes/heroes_underlord/abyssal_underlord_dark_rift_portal.vpcf", PATTACH_WORLDORIGIN, caster )
  ParticleManager:SetParticleControl( partPortal2, 0, self.originSecond )
  ParticleManager:SetParticleControl( partPortal2, 2, self.originSecond )
  ParticleManager:SetParticleControl( partPortal2, 1, Vector( radius, 1, 1 ) )

  -- play cast sounds
  caster:EmitSound( "Hero_AbyssalUnderlord.DarkRift.Cast" )
  EmitSoundOnLocationWithCaster( self.originSecond, "Hero_AbyssalUnderlord.DarkRift.Cast", caster )

  -- Store the location of the caster on the caster itself for the sub ability
  caster.original_cast_location = originCaster

  -- Store particles on ability and caster itself
  self.partPortal1 = partPortal1
  self.partPortal2 = partPortal2
  caster.partPortal1 = partPortal1
  caster.partPortal2 = partPortal2
end

function abyssal_underlord_dark_rift_oaa:OnChannelFinish(bInterrupted)
  local caster = self:GetCaster()

  -- Stop and remove stuff if interrupted and don't continue
  if bInterrupted then
    -- Stop sound
    caster:StopSound( "Hero_AbyssalUnderlord.DarkRift.Cast" )

    -- Remove particles
    if self.partPortal1 then
      ParticleManager:DestroyParticle( self.partPortal1, false )
		  ParticleManager:ReleaseParticleIndex( self.partPortal1 )
      caster.partPortal1 = nil
    end
    if self.partPortal2 then
      ParticleManager:DestroyParticle( self.partPortal2, false )
      ParticleManager:ReleaseParticleIndex( self.partPortal2 )
      caster.partPortal2 = nil
    end

    caster.original_cast_location = nil

    return
  end

  local originParent = caster:GetAbsOrigin()
  local radius = self:GetSpecialValueFor("radius")

  -- destroy all trees in portals
  GridNav:DestroyTreesAroundPoint( originParent, radius, true )
  GridNav:DestroyTreesAroundPoint( self.originSecond, radius, true )

  -- play teleportation sounds
  caster:EmitSound("Hero_AbyssalUnderlord.DarkRift.Aftershock")
  EmitSoundOnLocationWithCaster( self.originSecond, "Hero_AbyssalUnderlord.DarkRift.Aftershock", caster )

  -- emit warp particles
  local part = ParticleManager:CreateParticle( "particles/units/heroes/heroes_underlord/abbysal_underlord_darkrift_warp.vpcf", PATTACH_WORLDORIGIN, caster )
  ParticleManager:SetParticleControl( part, 1, Vector( radius, 1, 1 ) )
  ParticleManager:SetParticleControl( part, 2, originParent )

  local part2 = ParticleManager:CreateParticle( "particles/units/heroes/heroes_underlord/abbysal_underlord_darkrift_warp.vpcf", PATTACH_WORLDORIGIN, caster )
  ParticleManager:SetParticleControl( part2, 1, Vector( radius, 1, 1 ) )
  ParticleManager:SetParticleControl( part2, 2, self.originSecond )

  local targetTeam = self:GetAbilityTargetTeam()
  local targetType = self:GetAbilityTargetType()
  local targetFlags = self:GetAbilityTargetFlags()

  local units_in_portal = FindUnitsInRadius(caster:GetTeamNumber(), self.originSecond, nil, radius, targetTeam, targetType, targetFlags, FIND_ANY_ORDER, false)

  -- Original stun duration
  local duration = self:GetSpecialValueFor("stun_duration")

  -- Teleport the caster
  caster:SetAbsOrigin(self.originSecond)
  FindClearSpaceForUnit(caster, self.originSecond, true)

  -- Disjoint disjointable/dodgeable projectiles
	ProjectileManager:ProjectileDodge(caster)

  -- Teleportation particle
  local part3 = ParticleManager:CreateParticle( "particles/units/heroes/heroes_underlord/abbysal_underlord_darkrift_ambient_end.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster )
	ParticleManager:SetParticleControl( part3, 2, originParent )
	ParticleManager:SetParticleControl( part3, 5, originParent )

  local damageTable = {}
  damageTable.attacker = caster
  damageTable.damage = self:GetSpecialValueFor("damage")
  damageTable.damage_type = self:GetAbilityDamageType()
  damageTable.ability = self

  -- Find all enemies and apply effects of the spell: stun them and damage them
  for _, unit in pairs(units_in_portal) do
    -- Status Resistance Fix
    duration = unit:GetValueChangedByStatusResistance(duration)
    unit:AddNewModifier(caster, self, "modifier_underlord_dark_rift_oaa_stun", {duration = duration} )
    -- Apply damage
    damageTable.victim = unit
    ApplyDamage(damageTable)
  end

  -- Particles releasing
  ParticleManager:ReleaseParticleIndex(part)
  ParticleManager:ReleaseParticleIndex(part2)
  ParticleManager:ReleaseParticleIndex(part3)
end

---------------------------------------------------------------------------------------------------

modifier_underlord_dark_rift_oaa_stun = class(ModifierBaseClass)


function modifier_underlord_dark_rift_oaa_stun:IsHidden()
	return false
end

function modifier_underlord_dark_rift_oaa_stun:IsDebuff()
	return true
end

function modifier_underlord_dark_rift_oaa_stun:IsPurgable()
	return true
end

function modifier_underlord_dark_rift_oaa_stun:IsStunDebuff()
  return true
end
