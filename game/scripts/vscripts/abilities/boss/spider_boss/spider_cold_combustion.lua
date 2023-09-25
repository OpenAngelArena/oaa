LinkLuaModifier( "modifier_spider_cold_combustion", "abilities/boss/spider_boss/spider_cold_combustion.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_felfrost", "abilities/boss/spider_boss/modifier_felfrost.lua", LUA_MODIFIER_MOTION_NONE )

spider_cold_combustion = class( AbilityBaseClass )

function spider_cold_combustion:OnSpellStart()
  self:Boom(self:GetCaster())
end

function spider_cold_combustion:GetIntrinsicModifierName()
	return "modifier_spider_cold_combustion"
end

function spider_cold_combustion:Boom(parent)
  if parent and not parent:IsNull() then
    local damage = self:GetSpecialValueFor( "damage" )
    local radius = self:GetSpecialValueFor( "radius" )
    local damageType = self:GetAbilityDamageType()
    local originParent = parent:GetAbsOrigin()

    -- grab all enemies in radius
    local units = FindUnitsInRadius(
      parent:GetTeamNumber(),
      originParent,
      nil,
      radius,
      DOTA_UNIT_TARGET_TEAM_ENEMY,
      bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC),
      DOTA_UNIT_TARGET_FLAG_NONE,
      FIND_ANY_ORDER,
      false
    )

    -- iterate through 'em
    for _, unit in pairs( units ) do
      -- apply felfrost and increase its stack count
      local mod = unit:AddNewModifier( parent, self, "modifier_felfrost", {} )

      if mod then
        mod:IncrementStackCount()
      end

      -- deal damage
      ApplyDamage( {
        victim = unit,
        attacker = parent,
        damage = damage,
        damage_type = damageType,
        damage_flags = DOTA_DAMAGE_FLAG_NONE,
        ability = self,
      } )
    end

    -- play sound effect
    parent:EmitSound( "Hero_Crystal.CrystalNova" )

    -- set up particle
    local part = ParticleManager:CreateParticle( "particles/units/heroes/hero_crystalmaiden/maiden_crystal_nova.vpcf", PATTACH_WORLDORIGIN, nil )
    ParticleManager:SetParticleControl( part, 0, originParent )
    ParticleManager:SetParticleControl( part, 1, Vector( radius, 1, radius ) )
    ParticleManager:ReleaseParticleIndex( part )

    if parent:IsAlive() then
      parent:ForceKillOAA(false)
    end
  end
end

--------------------------------------------------------------------------------

modifier_spider_cold_combustion = class( ModifierBaseClass )

--------------------------------------------------------------------------------

function modifier_spider_cold_combustion:IsHidden()
	return true
end

function modifier_spider_cold_combustion:IsDebuff()
	return false
end

function modifier_spider_cold_combustion:IsPurgable()
	return false
end

function modifier_spider_cold_combustion:GetAttributes()
	return bit.bor( MODIFIER_ATTRIBUTE_PERMANENT, MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE )
end

--------------------------------------------------------------------------------

if IsServer() then
	function modifier_spider_cold_combustion:DeclareFunctions()
		return {
			MODIFIER_EVENT_ON_DEATH,
		}
	end

--------------------------------------------------------------------------------

  function modifier_spider_cold_combustion:OnDeath( event )
    local parent = self:GetParent()

    if event.unit == parent then
      local spell = self:GetAbility()
      if spell and not spell:IsNull() then
        spell:Boom(parent)
      end
    end
  end
end
