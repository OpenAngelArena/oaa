boss_spiders_spider_cold_combustion = class( AbilityBaseClass )

LinkLuaModifier( "modifier_boss_spiders_spider_cold_combustion", "abilities/spiders/boss_spiders_spider_cold_combustion.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_felfrost", "modifiers/modifier_felfrost.lua", LUA_MODIFIER_MOTION_NONE )

local function Boom(parent, spell)
    local damage = spell:GetSpecialValueFor( "damage" )
    local radius = spell:GetSpecialValueFor( "radius" )
    local damageType = spell:GetAbilityDamageType()
    local originParent = parent:GetAbsOrigin()

    -- grab all enemies in radius
    local units = FindUnitsInRadius(
      parent:GetTeamNumber(),
      originParent,
      nil,
      radius,
      DOTA_UNIT_TARGET_TEAM_ENEMY,
      bit.bor( DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP ),
      DOTA_UNIT_TARGET_FLAG_NONE,
      FIND_ANY_ORDER,
      false
    )

    -- iterate through 'em
    for _, unit in pairs( units ) do
      -- deal damage
      ApplyDamage( {
        victim = unit,
        attacker = parent,
        damage = damage,
        damage_type = damageType,
        damage_flags = DOTA_DAMAGE_FLAG_NONE,
        ability = spell,
      } )

      -- apply felfrost and increase its stack count
      local mod = unit:AddNewModifier( parent, spell, "modifier_felfrost", {} )

      if mod then
        mod:IncrementStackCount()
      end
    end

    -- play sound effect
    parent:EmitSound( "Hero_Crystal.CrystalNova" )

    -- set up particle
    local part = ParticleManager:CreateParticle( "particles/units/heroes/hero_crystalmaiden/maiden_crystal_nova.vpcf", PATTACH_WORLDORIGIN, nil )
    ParticleManager:SetParticleControl( part, 0, originParent )
    ParticleManager:SetParticleControl( part, 1, Vector( radius, 1, radius ) )
    ParticleManager:ReleaseParticleIndex( part )

    if parent:IsAlive() then
      parent:ForceKill(false)
    end
  end
--------------------------------------------------------------------------------

function boss_spiders_spider_cold_combustion:OnSpellStart()
  Boom(self:GetCaster(), self)
end

function boss_spiders_spider_cold_combustion:GetIntrinsicModifierName()
	return "modifier_boss_spiders_spider_cold_combustion"
end

--------------------------------------------------------------------------------

modifier_boss_spiders_spider_cold_combustion = class( ModifierBaseClass )

--------------------------------------------------------------------------------

function modifier_boss_spiders_spider_cold_combustion:IsHidden()
	return true
end

function modifier_boss_spiders_spider_cold_combustion:IsDebuff()
	return false
end

function modifier_boss_spiders_spider_cold_combustion:IsPurgable()
	return false
end

function modifier_boss_spiders_spider_cold_combustion:GetAttributes()
	return bit.bor( MODIFIER_ATTRIBUTE_PERMANENT, MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE )
end

--------------------------------------------------------------------------------

if IsServer() then
	function modifier_boss_spiders_spider_cold_combustion:DeclareFunctions()
		local funcs = {
			MODIFIER_EVENT_ON_DEATH,
		}

		return funcs
	end

--------------------------------------------------------------------------------

  function modifier_boss_spiders_spider_cold_combustion:OnDeath( event )
    local parent = self:GetParent()

    if event.unit == parent then
      local spell = self:GetAbility()
      Boom(parent, spell)
    end
  end
end
