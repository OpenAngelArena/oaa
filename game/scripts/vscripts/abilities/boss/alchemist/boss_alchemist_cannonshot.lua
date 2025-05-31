LinkLuaModifier("modifier_generic_projectile", "modifiers/modifier_generic_projectile.lua", LUA_MODIFIER_MOTION_NONE)

------------------------------------------------------------------------------------

boss_alchemist_cannonshot = class(AbilityBaseClass)

function boss_alchemist_cannonshot:Precache(context)
  PrecacheResource("model", "models/heroes/techies/techies_bomb_projectile.vmdl", context)
end

------------------------------------------------------------------------------------

function boss_alchemist_cannonshot:GetCastAnimation()
	return ACT_DOTA_CAST_ABILITY_1
end

------------------------------------------------------------------------------------

function boss_alchemist_cannonshot:OnSpellStart()
  local caster = self:GetCaster()

  if self.target_points then
    caster:EmitSound("hero_ursa.attack")

    for _, target in pairs(self.target_points) do
      if target then
        local indicator = ParticleManager:CreateParticle("particles/ui_mouseactions/wards_area_view.vpcf", PATTACH_CUSTOMORIGIN, caster)
        ParticleManager:SetParticleControl(indicator, 0, target + Vector(0,0,32))
        ParticleManager:SetParticleControl(indicator, 15, Vector(255,55,55))
        ParticleManager:SetParticleControl(indicator, 16, Vector(1,1,1))

        local origin = caster:GetAbsOrigin() + (caster:GetForwardVector() * 30)

        local explosive = CreateUnitByName("npc_dota_boss_spiders_explosive", origin, false, caster, caster, caster:GetTeamNumber())

        local projectileModifier = explosive:AddNewModifier(explosive, self, "modifier_generic_projectile", {})
        local projectileTable = {
          onLandedCallback = function ()
            if indicator then
              ParticleManager:DestroyParticle(indicator, true)
              ParticleManager:ReleaseParticleIndex(indicator)
            end
            self:Explode(explosive)
          end,
          speed = self:GetSpecialValueFor("projectile_speed"),
          origin = origin,
          target = target,
          height = self:GetSpecialValueFor("projectile_height"),
        }
        projectileModifier:InitProjectile(projectileTable)
      end
    end

    self.target_points = nil
  end
end

------------------------------------------------------------------------------------

function boss_alchemist_cannonshot:Explode(explosive)
  local radius = self:GetSpecialValueFor("radius")
  local point = explosive:GetAbsOrigin()

  local units = FindUnitsInRadius(
    explosive:GetTeamNumber(),
    point,
    nil,
    radius,
    DOTA_UNIT_TARGET_TEAM_ENEMY,
    bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC),
    DOTA_UNIT_TARGET_FLAG_NONE,
    FIND_ANY_ORDER,
    false
  )

  local knockbackModifierTable = {
    should_stun = 1,
    knockback_height = 80,
    center_x = point.x,
    center_y = point.y,
    center_z = point.z
  }

  local damageTable = {
    attacker = explosive,
    damage = self:GetSpecialValueFor("damage"),
    damage_type = self:GetAbilityDamageType(),
    ability = self
  }

  for _, v in pairs(units) do
    if v and not v:IsNull() and not v:IsMagicImmune() and not v:IsDebuffImmune() then
      knockbackModifierTable.knockback_distance = radius - (v:GetAbsOrigin() - point):Length2D()
      knockbackModifierTable.knockback_duration = v:GetValueChangedByStatusResistance(1.0)
      knockbackModifierTable.duration = knockbackModifierTable.knockback_duration

      v:AddNewModifier( explosive, self, "modifier_knockback", knockbackModifierTable )

      damageTable.victim = v
      ApplyDamage(damageTable)
    end
  end

  EmitSoundOnLocationWithCaster(point, "Hero_Techies.Suicide", explosive)

  local explosion = ParticleManager:CreateParticle("particles/econ/items/techies/techies_arcana/techies_suicide_arcana.vpcf", PATTACH_CUSTOMORIGIN, self:GetCaster())
  ParticleManager:SetParticleControl(explosion, 0, point)
  ParticleManager:SetParticleControl(explosion, 3, point)
  ParticleManager:ReleaseParticleIndex(explosion)

  if explosive and not explosive:IsNull() then
    explosive:ForceKillOAA(false)
  end
end
