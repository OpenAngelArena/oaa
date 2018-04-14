LinkLuaModifier("modifier_boss_carapace_crystals_passive", "abilities/carapace/boss_carapace_crystals.lua", LUA_MODIFIER_MOTION_NONE)

--------------------------------------------------------------------------------

boss_carapace_crystals = class(AbilityBaseClass)

--------------------------------------------------------------------------------

if IsServer() then
	function boss_carapace_crystals:GetIntrinsicModifierName()
		if self:GetLevel() > 0 then
			return "modifier_boss_carapace_crystals_passive"
		end
	end
end

--------------------------------------------------------------------------------

modifier_boss_carapace_crystals_passive = class(ModifierBaseClass)

------------------------------------------------------------------------------------

function modifier_boss_carapace_crystals_passive:IsHidden()
	return true
end

------------------------------------------------------------------------------------

function modifier_boss_carapace_crystals_passive:IsPurgable()
	return false
end

------------------------------------------------------------------------------------

function modifier_boss_carapace_crystals_passive:RemoveOnDeath()
	return true
end

------------------------------------------------------------------------------------

function modifier_boss_carapace_crystals_passive:OnDeath()
	for k,v in pairs(self.crystals) do
		if v.particle then
			ParticleManager:DestroyParticle(v.particle, true)
		end
	end
	return true
end

------------------------------------------------------------------------------------

if IsServer() then
	function modifier_boss_carapace_crystals_passive:OnCreated()
		local caster = self:GetCaster()
		local ability = self:GetAbility()

		local additional = ability:GetSpecialValueFor("additional")
		local initial = ability:GetSpecialValueFor("initial")
		local total = math.ceil(100 / additional) + initial - 1
		self.angle =  math.ceil(360 / total)
		self.count = 0

		self.crystals = {}
		for i=1,total do
			self.crystals[i] = {}
		end

		local initialKeys = self:GetRandomElements(self.crystals, 2, nil, true)
		for k,v in pairs(initialKeys) do
			self:CreateCrystal(v)
		end

		self:StartIntervalThink(0.03)
	end
end

------------------------------------------------------------------------------------

if IsServer() then
	function modifier_boss_carapace_crystals_passive:CreateCrystal(key)
		local caster = self:GetCaster()

		local thresholdMin = self:GetAbility():GetSpecialValueFor("threshold_min")
		local thresholdMax = self:GetAbility():GetSpecialValueFor("threshold_max")

		local angle = self.angle * key

		self.crystals[key].threshold = RandomInt(thresholdMin, thresholdMax)
		self.crystals[key].taken = 0
		self.crystals[key].particle = ParticleManager:CreateParticle("particles/units/heroes/hero_crystalmaiden/maiden_base_attack_trail_c.vpcf", PATTACH_CUSTOMORIGIN, caster)
		ParticleManager:SetParticleControl(self.crystals[key].particle, 3, self:GetCrystalPosition(angle))

		self.count = self.count + 1

		-- print(key, position, caster:GetAbsOrigin())
	end
end

------------------------------------------------------------------------------------

if IsServer() then
	function modifier_boss_carapace_crystals_passive:OnIntervalThink()
		local caster = self:GetCaster()

		for k,v in pairs(self.crystals) do
			if v.particle then
				local angle = self.angle * k
				ParticleManager:SetParticleControl(v.particle, 3, self:GetCrystalPosition(angle))
			end
		end
	end
end

------------------------------------------------------------------------------------

if IsServer() then
	function modifier_boss_carapace_crystals_passive:GetCrystalPosition(angle)
		local caster = self:GetCaster()
		local ability = self:GetAbility()

		local position = RotatePosition(caster:GetAbsOrigin(), QAngle(0,angle + caster:GetAngles().y,0), caster:GetAbsOrigin() + Vector(ability:GetSpecialValueFor("crystal_distance"),0,0))
		
		return position + Vector(0,0,64)
	end
end

------------------------------------------------------------------------------------

function modifier_boss_carapace_crystals_passive:DeclareFunctions()
	local funcs =
	{
		MODIFIER_EVENT_ON_TAKEDAMAGE,
		MODIFIER_EVENT_ON_DEATH
	}

	return funcs
end

------------------------------------------------------------------------------------

if IsServer() then
	local function AngleOfPoint( pt )
		local x, y = pt.x, pt.y
		local radian = math.atan2(y,x)
		local angle = radian*180/math.pi
		if angle < 0 then angle = 360 + angle end
		return angle
	end

	local function AngleBetweenPoints( a, b )
		local x, y = b.x - a.x, b.y - a.y
		return AngleOfPoint( { x=x, y=y } )
	end

	local function IsAngleBetween(target, angle1, angle2) 
		local rAngle = ((angle2 - angle1) % 360 + 360) % 360
		if rAngle >= 180 then
			local temp = angle1
			angle1 = angle2
			angle2 = temp
		end

		if angle1 <= angle2 then
			return target >= angle1 and target <= angle2
		else
			return target >= angle1 or target <= angle2
		end
	end

	local function Repeat(t, length)
		return t - math.floor(t / length) * length
	end

	local function FindUnitsInCone(position, coneDirection, coneLength, coneWidth, teamNumber, teamFilter, typeFilter, flagFilter, order)
		local units = FindUnitsInRadius(teamNumber, position, nil, coneLength, teamFilter, typeFilter, flagFilter, order, false)

		coneDirection = coneDirection:Normalized()

		local output = {}
		local cone = math.cos(coneWidth/2)

		for _, unit in pairs(units) do
			local direction = (unit:GetAbsOrigin() - position):Normalized()
			if direction:Dot(coneDirection) >= cone then
				table.insert(output, unit)
			end
		end

		return output
	end

	function modifier_boss_carapace_crystals_passive:OnTakeDamage(keys)
		local caster = self:GetCaster()
		local attacker = keys.attacker
		local damage = keys.damage
		local ability = self:GetAbility()

		local initial = ability:GetSpecialValueFor("initial")
		local additional = ability:GetSpecialValueFor("additional")

		if self.count - initial < additional - math.ceil((caster:GetHealth() / caster:GetMaxHealth()) * additional) then
			local function CheckCrystal(k)
				return self.crystals[k] and self.crystals[k].particle == nil
			end

			local newCrystals = self:GetRandomElements(self.crystals, 1, CheckCrystal, true)
			for k,v in pairs(newCrystals) do
				self:CreateCrystal(v)
			end
		end

		if self.skip then
			self.skip = false
			return
		end

		local result_angle = AngleBetweenPoints( caster:GetAbsOrigin(), attacker:GetAbsOrigin() )

		for k,v in pairs(self.crystals) do
			local angle = Repeat((k * self.angle) + caster:GetAngles().y, 360)
			local min = angle - (self.angle / 2)
			local max = angle + (self.angle / 2)
			if not v.full and v.particle and IsAngleBetween(result_angle, min, max) then
				self.crystals[k].taken = self.crystals[k].taken + keys.damage

				self.skip = true
				local damageTable = {
					victim = caster,
					attacker = attacker,
					damage = damage * ((ability:GetSpecialValueFor("damage_amplification") / 100) + 1),
					damage_type = keys.damage_type,
					ability = ability
				}
				ApplyDamage(damageTable)

				if self.crystals[k].taken >= self.crystals[k].threshold then
					self.crystals[k].full = true
					ParticleManager:DestroyParticle(self.crystals[k].particle, true)

					self.crystals[k].particle = ParticleManager:CreateParticle("particles/units/heroes/hero_crystalmaiden/maiden_base_attack_trail.vpcf", PATTACH_CUSTOMORIGIN, caster)
					ParticleManager:SetParticleControl(self.crystals[k].particle, 3, self:GetCrystalPosition(self.angle * k))

					local distance = ability:GetSpecialValueFor("crystal_distance")
					local range = ability:GetSpecialValueFor("range")
					local width = range * (self.angle / distance)		

					-- TODO: Replace with proper indicator
					Timers:CreateTimer(function (  )
						if not IsValidEntity(caster) or not caster:IsAlive() then return nil end

						if not self.crystals[k].particle then return nil end

						local crystalPosition = self:GetCrystalPosition(self.angle * k)
						local direction = ((crystalPosition - caster:GetAbsOrigin()) * Vector(1,1,0)):Normalized()
						DebugDrawLine(caster:GetAbsOrigin(), caster:GetAbsOrigin() + (direction * range), 255, 0, 0, false, 0.03)
						return 0.03
					end)

					Timers:CreateTimer(2.0, function ()
						if not IsValidEntity(caster) or not caster:IsAlive() then return nil end

						ParticleManager:DestroyParticle(self.crystals[k].particle, true)
						self.crystals[k].particle = nil
						
						local explosion = ParticleManager:CreateParticle("particles/econ/items/crystal_maiden/crystal_maiden_cowl_of_ice/maiden_crystal_nova_cowlofice.vpcf", PATTACH_CUSTOMORIGIN, caster)
						ParticleManager:SetParticleControl(explosion, 0, self:GetCrystalPosition(self.angle * k))
						ParticleManager:ReleaseParticleIndex(explosion)

						caster:EmitSound("Hero_Crystal.CrystalNova")

						local crystalPosition = self:GetCrystalPosition(self.angle * k)
						local direction = ((crystalPosition - caster:GetAbsOrigin()) * Vector(1,1,0)):Normalized()

						-- TODO: Proper area particle
						local info = {
							EffectName = "particles/units/heroes/hero_nyx_assassin/nyx_assassin_impale.vpcf",
							Ability = ability,
							vSpawnOrigin = caster:GetAbsOrigin(),
							fStartRadius = width,
							fEndRadius = width,
							vVelocity = 1500 * direction,
							fDistance = range,
							Source = caster,
							iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
							iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP,
						}

						ProjectileManager:CreateLinearProjectile( info )

						local units = FindUnitsInCone(
							caster:GetAbsOrigin(),
							direction,
							range,
							width,
							caster:GetTeamNumber(),
							DOTA_UNIT_TARGET_TEAM_ENEMY,
							DOTA_UNIT_TARGET_ALL,
							DOTA_UNIT_TARGET_FLAG_NONE,
							FIND_CLOSEST)

						for k,v in pairs(units) do
							local explosion = ParticleManager:CreateParticle("particles/econ/items/crystal_maiden/crystal_maiden_cowl_of_ice/maiden_crystal_nova_cowlofice.vpcf", PATTACH_CUSTOMORIGIN, caster)
							ParticleManager:SetParticleControl(explosion, 0, v:GetAbsOrigin())
							ParticleManager:ReleaseParticleIndex(explosion)

							local damageTable = {
								victim = v,
								attacker = caster,
								damage = ability:GetSpecialValueFor("damage"),
								damage_type = ability:GetAbilityDamageType(),
								ability = ability
							}
							ApplyDamage(damageTable)
						end
					end)
				end
			end
		end
	end
end

------------------------------------------------------------------------------------

function modifier_boss_carapace_crystals_passive:GetRandomElements(list, count, checker, return_key)
	local newTable = {}

	for k,v in pairs(list) do
		local skip = false
		if checker then
			if return_key then
				skip = not checker(k)
			else
				skip = not checker(v)
			end
		end
		if not skip then
			newTable[k] = v
		end
	end

	function TableCount( t )
		local n = 0
		for _ in pairs( t ) do
			n = n + 1
		end
		return n
	end

	local tableLength = TableCount(newTable)
	local seeds = {}

	local function Check(number)
		for k,v in pairs(seeds) do
			if v == number then
				return false
			end
		end
		return true
	end

	for i=1,count do
		local newSeed
		repeat
			newSeed = math.random(1, tableLength)
		until
			Check(newSeed)
		table.insert(seeds, newSeed)
	end

	local i = 1
	local returnTable = {}
	local counter = 0

	for k,v in pairs(newTable) do
		if not Check(i) then
			if return_key then
				table.insert(returnTable, k)
			else
				table.insert(returnTable, v)
			end
			counter = counter + 1
			if counter == count then
				break  
			end
		end
		i = i + 1
	end

	return returnTable
end