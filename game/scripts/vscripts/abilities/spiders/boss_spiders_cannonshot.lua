LinkLuaModifier("modifier_generic_projectile", "modifiers/modifier_generic_projectile.lua", LUA_MODIFIER_MOTION_NONE)

------------------------------------------------------------------------------------

boss_spiders_cannonshot = class(AbilityBaseClass)

------------------------------------------------------------------------------------

function boss_spiders_cannonshot:GetCastAnimation()
	return ACT_DOTA_CAST_ABILITY_4
end

------------------------------------------------------------------------------------

function boss_spiders_cannonshot:OnSpellStart(keys)
	local caster = self:GetCaster()

	if self.target_points then
		caster:EmitSound("hero_ursa.attack")

		for k,target in pairs(self.target_points) do
			local indicator = ParticleManager:CreateParticle("particles/ui_mouseactions/wards_area_view.vpcf", PATTACH_CUSTOMORIGIN, caster)
			ParticleManager:SetParticleControl(indicator, 0, target + Vector(0,0,32))
			ParticleManager:SetParticleControl(indicator, 15, Vector(255,55,55))
			ParticleManager:SetParticleControl(indicator, 16, Vector(1,1,1))

			local origin = caster:GetAbsOrigin() + (caster:GetForwardVector() * 30)

			local explosive = CreateUnitByName("npc_dota_boss_spiders_explosive", origin, false, caster, caster, caster:GetTeamNumber())

			local projectileModifier = explosive:AddNewModifier(explosive, self, "modifier_generic_projectile", {})
			local projectileTable = {
				onLandedCallback = function ()
					ParticleManager:DestroyParticle(indicator, true)
					self:Explode(explosive)
				end,
				speed = self:GetSpecialValueFor("projectile_speed"),
				origin = origin,
				target = target,
				height = self:GetSpecialValueFor("projectile_height"),
			}
			projectileModifier:InitProjectile(projectileTable)
		end

		self.target_points = nil
	end
end

------------------------------------------------------------------------------------

function boss_spiders_cannonshot:Explode(explosive)
	local radius = 240

	local units = FindUnitsInRadius(
		explosive:GetTeamNumber(),
		explosive:GetAbsOrigin(),
		nil,
		radius,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_ALL,
		DOTA_UNIT_TARGET_FLAG_NONE,
		FIND_CLOSEST,
		false
	)

	for k,v in pairs(units) do
		local point = explosive:GetAbsOrigin()
		local knockbackModifierTable = {
			should_stun = 1,
			knockback_duration = 1.0,
			duration = 1.0,
			knockback_distance = radius - (v:GetAbsOrigin() - point):Length2D(),
			knockback_height = 80,
			center_x = point.x,
			center_y = point.y,
			center_z = point.z
		}
		v:AddNewModifier( explosive, self, "modifier_knockback", knockbackModifierTable )

		local damageTable = {
			victim = v,
			attacker = explosive,
			damage = self:GetSpecialValueFor("damage"),
			damage_type = self:GetAbilityDamageType(),
			ability = self
		}
		ApplyDamage(damageTable)
	end

	EmitSoundOnLocationWithCaster(explosive:GetAbsOrigin(), "Hero_Techies.Suicide", explosive)

	local explosion = ParticleManager:CreateParticle("particles/econ/items/techies/techies_arcana/techies_suicide_arcana.vpcf", PATTACH_CUSTOMORIGIN, self:GetCaster())
	ParticleManager:SetParticleControl(explosion, 0, explosive:GetAbsOrigin())
	ParticleManager:SetParticleControl(explosion, 3, explosive:GetAbsOrigin())
	ParticleManager:ReleaseParticleIndex(explosion)

	UTIL_Remove(explosive)
end
