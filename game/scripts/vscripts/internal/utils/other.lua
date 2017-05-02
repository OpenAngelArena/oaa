

-- Colors
COLOR_NONE = '\x06'
COLOR_GRAY = '\x06'
COLOR_GREY = '\x06'
COLOR_GREEN = '\x0C'
COLOR_DPURPLE = '\x0D'
COLOR_SPINK = '\x0E'
COLOR_DYELLOW = '\x10'
COLOR_PINK = '\x11'
COLOR_RED = '\x12'
COLOR_LGREEN = '\x15'
COLOR_BLUE = '\x16'
COLOR_DGREEN = '\x18'
COLOR_SBLUE = '\x19'
COLOR_PURPLE = '\x1A'
COLOR_ORANGE = '\x1B'
COLOR_LRED = '\x1C'
COLOR_GOLD = '\x1D'

-----------------------------------------------------------------------------------------------

function GetAllPlayers(bOnlyWithHeroes)
	local Players = {}
	for playerID = 0, DOTA_MAX_TEAM_PLAYERS-1  do
		if PlayerResource:IsValidPlayerID(playerID) then
			local player = PlayerResource:GetPlayer(playerID)
			if player and ((bOnlyWithHeroes and player:GetAssignedHero()) or not bOnlyWithHeroes) then
				table.insert(Players, player)
			end
		end
	end
	return Players
end

function CreateTeamNotificationSettings(iTeam, bSecVar)
	local textColor = ColorTableToCss(TEAM_COLORS[iTeam])
	local text = TEAM_NAMES[iTeam]
	if bSecVar then
		text = TEAM_NAMES2[iTeam]
	end
	local output = {text=text, continue=true, style={color=textColor}}
	return output
end

function CreateItemNotificationSettings(sItemName)
	return {text= "#DOTA_Tooltip_ability_" .. sItemName, duration=7.0, continue=true, style={color="orange"}}
end

function GetDOTATimeInMinutesFull()
	return math.floor(GameRules:GetDOTATime(false, false)/60)
end

function CreatePortal(vLocation, vTarget, iRadius, sParticle, sDisabledParticle, bEnabled, fOptionalActOnTeleport, sOptionalName)
	local unit = CreateUnitByName("npc_dummy_unit", vLocation, false, nil, nil, DOTA_TEAM_NEUTRALS)
	unit.Teleport_Radius = iRadius
	unit.Teleport_Target = vTarget
	unit.Teleport_ParticleName = sParticle
	unit.Teleport_DisabledParticleName = sDisabledParticle
	unit.Teleport_ActionOnTeleport = fOptionalActOnTeleport
	unit.Teleport_Name = sOptionalName
	unit.Teleport_Enabled = not bEnabled
	unit:AddAbility("teleport_passive")
	if bEnabled then
		unit:EnablePortal()
	else
		unit:DisablePortal()
	end
	return unit
end

function CreateLoopedPortal(point1, point2, iRadius, sParticle, sDisabledParticle, bEnabled, fOptionalActOnTeleport, sOptionalName)
	for i = 1, 2 do
		local point
		local target
		if i == 1 then
			point = point1
			target = point2
		else
			point = point2
			target = point1
		end
		local unit = CreateUnitByName("npc_dummy_unit", point, false, nil, nil, DOTA_TEAM_NEUTRALS)
		unit.Teleport_Radius = iRadius
		unit.Teleport_Target = target
		unit.Teleport_ParticleName = sParticle
		unit.Teleport_DisabledParticleName = sDisabledParticle
		unit.Teleport_ActionOnTeleport = fOptionalActOnTeleport
		unit.Teleport_Name = sOptionalName
		unit.Teleport_Enabled = not bEnabled
		unit.Teleport_Looped = true
		unit:AddAbility("teleport_passive")
		if bEnabled then
			unit:EnablePortal()
		else
			unit:DisablePortal()
		end
	end
	return unit
end

function CreateGoldNotificationSettings(amount)
	return {text=amount, duration=flDuration, continue=true, style={color="gold"}}, {text="#notifications_gold", continue=true, style={color="gold"}}
end

function GetEnemiesIds(heroteam)
	local enemies = {}
	for _,playerID in ipairs(GetAllPlayers(false)) do
		if PlayerResource:GetTeam(playerID:GetPlayerID()) ~= heroteam then
			table.insert(enemies, playerID)
		end
	end
	return enemies
end

function GenerateAttackProjectile(unit, optAbility)
	local projectile_info = {}
	projectile_info = {
		EffectName = unit:GetKeyValue("ProjectileModel"),
		Ability = optAbility,
		vSpawnOrigin = unit:GetAbsOrigin(),
		Source = unit,
		bHasFrontalCone = false,
		iMoveSpeed = unit:GetKeyValue("ProjectileSpeed") or 99999,
		bReplaceExisting = false,
		bProvidesVision = false
	}
	return projectile_info
end

function IsRangedUnit(unit)
	return unit:IsRangedAttacker() or unit:HasModifier("modifier_terrorblade_metamorphosis_transform_aura_applier")
end

function TrueKill(killer, ability, target)
	target.IsMarkedForTrueKill = true
	target:Kill(ability, killer)
	if IsValidEntity(target) and target:IsAlive() then
		RemoveDeathPreventingModifiers(target)
		target:Kill(ability, killer)
	end
	target.IsMarkedForTrueKill = false
end

function CDOTA_BaseNPC:TrueKill(ability, killer)
	TrueKill(killer, ability, self)
end

function FindFountain(team)
	return Entities:FindByName(nil, "npc_arena_fountain_" .. team)
end

function HasDamageFlag(damage_flags, flag)
	return bit.band(damage_flags, flag) == flag
end

function DrugEffectStrangeMove(target, amplitude)
	if not target:IsStunned() then
		FindClearSpaceForUnit(target, target:GetAbsOrigin() + Vector(RandomInt(-amplitude, amplitude), RandomInt(-amplitude, amplitude), 0), false)
	end
end

function DrugEffectRandomParticles(target, duration)
	--TODO Different particles
	for _,v in ipairs(FindUnitsInRadius(target:GetTeamNumber(), target:GetAbsOrigin(), nil, 1000, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_NO_INVIS + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)) do
		local particle = ParticleManager:CreateParticleForPlayer("particles/dark_smoke_test.vpcf", PATTACH_ABSORIGIN, v, target:GetPlayerOwner())
		Timers:CreateTimer(duration, function()
			ParticleManager:DestroyParticle(particle, false)
		end)
	end
end

function GetDrugDummyAbility(itemName)
	local abilityName = string.gsub(itemName, "item_", "dummy_drug_")
	local ability = DRUG_DUMMY:AddAbility(abilityName)
	return ability
end

function GetLevelValue(value, level)
	local split = {}
	for i in string.gmatch(value, "%S+") do
		table.insert(split, i)
	end
	if i[level+1] then
		return split[level+1]
	end
end

function PreformAbilityPrecastActions(unit, ability)
	if ability:IsCooldownReady() and ability:IsOwnersManaEnough() then
		ability:PayManaCost()
		ability:AutoStartCooldown()
		--ability:UseResources(true, true, true) -- not works with items?
		return true
	end
	return false
end

function ReplaceAbilities(unit, oldAbility, newAbility, keepLevel, keepCooldown)
	local ability = unit:FindAbilityByName(oldAbility)
	local level = ability:GetLevel()
	local cooldown = ability:GetCooldownTimeRemaining()
	unit:RemoveAbility(oldAbility)
	local new_ability = unit:AddAbility(newAbility)
	if keepLevel then
		new_ability:SetLevel(level)
	end
	if keepCooldown then
		new_ability:StartCooldown(cooldown)
	end
	return new_ability
end

function PreformMulticast(caster, ability_cast, multicast, multicast_delay, target)
	if ability_cast:IsMulticastable() then
		local prt = ParticleManager:CreateParticle('particles/units/heroes/hero_ogre_magi/ogre_magi_multicast.vpcf', PATTACH_OVERHEAD_FOLLOW, caster)
		ParticleManager:SetParticleControl(prt, 1, Vector(multicast, 0, 0))
		prt = ParticleManager:CreateParticle('particles/units/heroes/hero_ogre_magi/ogre_magi_multicast_b.vpcf', PATTACH_OVERHEAD_FOLLOW, caster:GetCursorCastTarget() or caster)
		prt = ParticleManager:CreateParticle('particles/units/heroes/hero_ogre_magi/ogre_magi_multicast_b.vpcf', PATTACH_OVERHEAD_FOLLOW, caster)
		prt = ParticleManager:CreateParticle('particles/units/heroes/hero_ogre_magi/ogre_magi_multicast_c.vpcf', PATTACH_OVERHEAD_FOLLOW, caster:GetCursorCastTarget() or caster)
		ParticleManager:SetParticleControl(prt, 1, Vector(multicast, 0, 0))
		CastMulticastedSpell(caster, ability_cast, target, multicast-1, multicast_delay)
	end
end

function CastMulticastedSpell(caster, ability, target, multicasts, delay)
	if multicasts >= 1 then
		Timers:CreateTimer(delay, function()
			CastAdditionalAbility(caster, ability, target)
			caster:EmitSound('Hero_OgreMagi.Fireblast.x'.. multicasts)
			if multicasts >= 2 then
				CastMulticastedSpell(caster, ability, target, multicasts - 1, delay)
			end
		end)
	end
end

function CastAdditionalAbility(caster, ability, target)
	local skill = ability
	local unit = caster
	local channelled = false
	if ability:HasBehavior(DOTA_ABILITY_BEHAVIOR_CHANNELLED) then
		local dummy = CreateUnitByName("npc_dummy_unit", caster:GetAbsOrigin(), true, caster, caster, caster:GetTeamNumber())
		--TODO сделать чтобы дамаг от скилла умножался от инты.
		for i = 0, DOTA_ITEM_SLOT_9 do
			local citem = caster:GetItemInSlot(i)
			if citem then
				dummy:AddItem(CopyItem(citem))
			end
		end
		if caster:HasScepter() then dummy:AddNewModifier(caster, nil, "modifier_item_ultimate_scepter", {}) end
		dummy:SetControllableByPlayer(caster:GetPlayerID(), true)
		dummy:SetOwner(caster)
		dummy:SetAbsOrigin(caster:GetAbsOrigin())
		dummy.GetStrength = function()
			return caster:GetStrength()
		end
		dummy.GetAgility = function()
			return caster:GetAgility()
		end
		dummy.GetIntellect = function()
			return caster:GetIntellect()
		end
		skill = dummy:AddAbility(ability:GetName())
		unit = dummy
		skill:SetLevel(ability:GetLevel())
		channelled = true
	end
	if skill:HasBehavior(DOTA_ABILITY_BEHAVIOR_UNIT_TARGET) then
		if target and type(target) == "table" then
			unit:SetCursorCastTarget(target)
		end
	elseif skill:HasBehavior(DOTA_ABILITY_BEHAVIOR_POINT) then
		if target and target.x and target.y and target.z then
			unit:SetCursorPosition(target)
		end
	end
	skill:OnSpellStart()
	if channelled then
		Timers:CreateTimer(0.03, function()
			if not caster:IsChanneling() then
				skill:EndChannel(true)
				skill:OnChannelFinish(true)
				Timers:CreateTimer(0.03, function()
					if skill then UTIL_Remove(skill) end
					if unit then UTIL_Remove(unit) end
				end)
			else
				return 0.03
			end
		end)
	end
end

function IsHeroInAbilityPhase(unit)
	for i = 0, unit:GetAbilityCount()-1 do
		local ability = unit:GetAbilityByIndex(i)
		if ability and ability.IsInAbilityPhase and ability:IsInAbilityPhase() then
			return true
		end
	end
	for i = 0, 5 do
		local item = unit:GetItemInSlot(i)
		if item and item.IsInAbilityPhase and item:IsInAbilityPhase() then
			return true
		end
	end
	return false
end

function GetAllAbilitiesCooldowns(unit)
	local cooldowns = {}
	for i = 0, unit:GetAbilityCount()-1 do
		local ability = unit:GetAbilityByIndex(i)
		if ability then
			table.insert(cooldowns, ability:GetReducedCooldown())
		end
	end
	return cooldowns
end

function RefreshAbilities(unit, tExceptions)
	for i = 0, unit:GetAbilityCount()-1 do
		local ability = unit:GetAbilityByIndex(i)
		if ability and (not tExceptions or not tExceptions[ability:GetAbilityName()]) then
			ability:EndCooldown()
		end
	end
end

function RefreshItems(unit, tExceptions)
	for i = DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_9 do
		local item = unit:GetItemInSlot(i)
		if item and (not tExceptions or not tExceptions[item:GetAbilityName()]) then
			item:EndCooldown()
		end
	end
end

--illusion_incoming_damage = tooltip - 100
--illusion_outgoing_damage = tooltip - 100
function CreateIllusion(unit, ability, illusion_origin, illusion_incoming_damage, illusion_outgoing_damage, illusion_duration)
	local unitname = GetFullHeroName(unit)
	local illusion = CreateUnitByName(unit:GetUnitName(), illusion_origin, true, unit, unit:GetPlayerOwner(), unit:GetTeamNumber())
	FindClearSpaceForUnit(illusion, illusion_origin, true)
	illusion:SetModelScale(unit:GetModelScale())
	illusion:SetControllableByPlayer(unit:GetPlayerID(), true)

	local caster_level = unit:GetLevel()
	for i = 1, caster_level - 1 do
		illusion:HeroLevelUp(false)
	end

	illusion:SetAbilityPoints(0)
	for ability_slot = 0, unit:GetAbilityCount()-1 do
		local i_ability = illusion:GetAbilityByIndex(ability_slot)
		if i_ability then
			illusion:RemoveAbility(i_ability:GetAbilityName())
		end

		local individual_ability = unit:GetAbilityByIndex(ability_slot)
		if individual_ability then
			local illusion_ability = illusion:AddAbility(individual_ability:GetName())
			illusion_ability:SetLevel(individual_ability:GetLevel())
		end
	end
	for item_slot = 0, 5 do
		local item = unit:GetItemInSlot(item_slot)
		if item then
			local illusion_item = illusion:AddItem(CreateItem(item:GetName(), illusion, illusion))
			illusion_item:SetCurrentCharges(item:GetCurrentCharges())
		end
	end
	illusion:SetHealth(unit:GetHealth())
	illusion:SetMana(unit:GetMana())
	illusion:AddNewModifier(unit, ability, "modifier_illusion", {duration = illusion_duration, outgoing_damage = illusion_outgoing_damage, incoming_damage = illusion_incoming_damage})
	illusion:MakeIllusion()
	if unit.Additional_str then
		illusion:ModifyStrength(unit.Additional_str)
	end
	if unit.Additional_agi then
		illusion:ModifyAgility(unit.Additional_agi)
	end
	if unit.Additional_int then
		illusion:ModifyIntellect(unit.Additional_int)
	end
	if unit.Additional_attackspeed then
		if not illusion:HasModifier("modifier_item_shard_attackspeed_stack") then
			illusion:AddNewModifier(caster, nil, "modifier_item_shard_attackspeed_stack", {})
		end
		local mod = illusion:FindModifierByName("modifier_item_shard_attackspeed_stack")
		if mod then
			mod:SetStackCount(unit.Additional_attackspeed)
		end
	end
	illusion.UnitName = unit.UnitName
	illusion:SetNetworkableEntityInfo("unit_name", GetFullHeroName(illusion))
	if NPC_HEROES_CUSTOM[unitname] then
		TransformUnitClass(illusion, NPC_HEROES_CUSTOM[unitname], true)
	end
	--[[illusion.CustomGain_Strength = unit.CustomGain_Strength
	illusion.CustomGain_Intelligence = unit.CustomGain_Intelligence
	illusion.CustomGain_Agility = unit.CustomGain_Agility
	illusion:SetNetworkableEntityInfo("AttributeStrengthGain", unit.CustomGain_Strength)
	illusion:SetNetworkableEntityInfo("AttributeIntelligenceGain", unit.CustomGain_Intelligence)
	illusion:SetNetworkableEntityInfo("AttributeAgilityGain", unit.CustomGain_Agility)]]
	if unit:GetModelName() ~= illusion:GetModelName() then
		illusion.ModelOverride = unit:GetModelName()
		illusion:SetModel(illusion.ModelOverride)
		illusion:SetOriginalModel(illusion.ModelOverride)
	end

	return illusion
end

function PerformGlobalAttack(unit, hTarget, bUseCastAttackOrb, bProcessProcs, bSkipCooldown, bIgnoreInvis, bUseProjectile, bFakeAttack, bNeverMiss, AttackFuncs)
	local abs = unit:GetAbsOrigin()
	unit:SetAbsOrigin(hTarget:GetAbsOrigin())
	SafePerformAttack(unit, hTarget, bUseCastAttackOrb, bProcessProcs, bSkipCooldown, bIgnoreInvis, bUseProjectile, bFakeAttack, bNeverMiss, AttackFuncs)
	unit:SetAbsOrigin(abs)
end

function SafePerformAttack(unit, hTarget, bUseCastAttackOrb, bProcessProcs, bSkipCooldown, bIgnoreInvis, bUseProjectile, bFakeAttack, bNeverMiss, AttackFuncs)
	--bNoSplashesMelee, bNoSplashesRanged, bNoDoubleAttackMelee, bNoDoubleAttackRanged
	if AttackFuncs then
		if not unit.AttackFuncs then unit.AttackFuncs = {} end
		table.merge(unit.AttackFuncs, AttackFuncs)
	end
	unit:PerformAttack(hTarget,bUseCastAttackOrb,bProcessProcs,bSkipCooldown,bIgnoreInvis,bUseProjectile,bFakeAttack,bNeverMiss)
	unit.AttackFuncs = nil
end

function UniqueRandomInts(min, max, count)
	local output = {}
	while #output < count do
		local r = RandomInt(min, max)
		if not table.contains(output, r) then
			table.insert(output, r)
		end
	end
	return output
end

function ColorTableToCss(color)
	return "rgb(" .. color[1] .. ',' .. color[2] .. ',' .. color[3] .. ')'
end

function IsPlayerAbandoned( playerID )
	return PLAYER_DATA[playerID].IsAbandoned == true
end

function FindAllOwnedUnits(player)
	local summons = {}
	local pid = type(player) == "number" and player or player:GetPlayerID()
	local units = FindUnitsInRadius(PlayerResource:GetTeam(pid), Vector(0, 0, 0), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_PLAYER_CONTROLLED, FIND_ANY_ORDER, false)
	for _,v in ipairs(units) do
		if type(player) == "number" and ((v.GetPlayerID ~= nil and v:GetPlayerID() or v:GetPlayerOwnerID()) == pid) or v:GetPlayerOwner() == player then
			if not (v:HasModifier("modifier_dummy_unit") or v:HasModifier("modifier_containers_shopkeeper_unit") or v:HasModifier("modifier_teleport_passive")) and v ~= hero then
				table.insert(summons, v)
			end
		end
	end
	return summons
end

function RemoveAllOwnedUnits(playerId)
	local player = PlayerResource:GetPlayer(playerId)
	local hero = PlayerResource:GetSelectedHeroEntity(playerId)
	local courier = FindCourier(PlayerResource:GetTeam(playerId))
	for _,v in ipairs(FindAllOwnedUnits(player or playerId)) do
		if v ~= hero and v ~= courier then
			v:ClearNetworkableEntityInfo()
			v:ForceKill(false)
			UTIL_Remove(v)
		end
	end
end

function GetTeamPlayerCount(iTeam)
	local counter = 0
	for i = 0, 23 do
		if PlayerResource:IsValidPlayerID(i) and not IsPlayerAbandoned(i) then
			if PlayerResource:GetTeam(i) == iTeam then
				counter = counter + 1
			end
		end
	end
	return counter
end

function MakePlayerAbandoned(iPlayerID)
	if not PLAYER_DATA[iPlayerID].IsAbandoned then
		RemoveAllOwnedUnits(iPlayerID)
		local hero = PlayerResource:GetSelectedHeroEntity(iPlayerID)
		if IsValidEntity(hero) then
			PLAYER_DATA[iPlayerID].BeforeAbandon_Level = hero:GetLevel()
			PLAYER_DATA[iPlayerID].BeforeAbandon_HeroInventorySnapshot = {}
			hero:ClearNetworkableEntityInfo()
			hero:Stop()
			for i = 0, DOTA_STASH_SLOT_6 do
				local item = hero:GetItemInSlot(i)
				if item then
					local charges = item:GetCurrentCharges()
					local toWriteCharges
					if item:GetInitialCharges() ~= charges then
						toWriteCharges = charges
					end
					PLAYER_DATA[iPlayerID].BeforeAbandon_HeroInventorySnapshot[i] = {
						name = item:GetAbilityName(),
						stacks = toWriteCharges
					}
					hero:SellItem(item)
				end
			end


			--Saving hero for 20 seconds to make sure most of debuffs were already removed
			hero:DestroyAllModifiers()
			for i = 0, hero:GetAbilityCount() - 1 do
				local ability = hero:GetAbilityByIndex(i)
				if ability then
					ability:SetLevel(0)
					ability:SetActivated(false)
					--UTIL_Remove(ability)
				end
			end
			hero:AddNewModifier(hero, nil, "modifier_hero_selection_transformation", nil)
			Timers:CreateTimer(20, function()
				UTIL_Remove(hero)
			end)
		end
		local heroname = HeroSelection:GetSelectedHeroName(iPlayerID)
		--local notLinked = true
		if heroname then
			Notifications:TopToAll({hero=heroname, duration=10})
			Notifications:TopToAll({text=PlayerResource:GetPlayerName(iPlayerID), continue=true, style={color=ColorTableToCss(PLAYER_DATA[iPlayerID].Color or {0, 0, 0})}})
			Notifications:TopToAll({text="#game_player_abandoned_game", continue=true})

			for _,v in ipairs(GetLinkedHeroNames(heroname)) do
				local linkedHeroOwner = HeroSelection:GetSelectedHeroPlayer(v)
				if linkedHeroOwner then
					HeroSelection:ForceChangePlayerHeroMenu(linkedHeroOwner)
				end
			end
		end
		--if notLinked then
			HeroSelection:UpdateStatusForPlayer(iPlayerID, "hover", "npc_dota_hero_abaddon")
		--end
		PLAYER_DATA[iPlayerID].IsAbandoned = true
		local ptd = PlayerTables:GetTableValue("arena", "players_abandoned")
		table.insert(ptd, iPlayerID)
		PlayerTables:SetTableValue("arena", "players_abandoned", ptd)
		if not GameRules:IsCheatMode() then
			local teamLeft = GetOneRemainingTeam()
			if teamLeft then
				Timers:CreateTimer(30, function()
					local teamLeft = GetOneRemainingTeam()
					if teamLeft then
						GameMode:OnOneTeamLeft(teamLeft)
					end
				end)
			end
		end
	end
end

function GetOneRemainingTeam()
	local teamLeft
	for i = DOTA_TEAM_FIRST, DOTA_TEAM_CUSTOM_MAX do
		local count = GetTeamPlayerCount(i)
		if count > 0 then
			if teamLeft then
				return
			else
				teamLeft = i
			end
		end
	end
	return teamLeft
end

function CopyItem(item)
	local newItem = CreateItem(item:GetAbilityName(), caster, caster)
	newItem:SetPurchaseTime(item:GetPurchaseTime())
	newItem:SetPurchaser(item:GetPurchaser())
	newItem:SetOwner(item:GetOwner())
	newItem:SetCurrentCharges(item:GetCurrentCharges())
	return newItem
end

function math.round(x)
	if x%2 ~= 0.5 then
		return math.floor(x+0.5)
	end
	return x-0.5
end

function SafeHeal(unit, flAmount, hInflictor, overhead)
	if unit:IsAlive() then
		unit:Heal(flAmount, hInflictor)
		if overhead then
			SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, unit, flAmount, nil)
		end
	end
end

function InvokeCheatCommand(s)
	Convars:SetInt("sv_cheats", 1)
	SendToServerConsole(s)
end

function UnitVarToPlayerID(unitvar)
	if unitvar then
		if type(unitvar) == "number" then
			return unitvar
		elseif IsValidEntity(unitvar) then
			if unitvar.GetPlayerID and unitvar:GetPlayerID() > -1 then
				return unitvar:GetPlayerID()
			elseif unitvar.GetPlayerOwnerID then
				return unitvar:GetPlayerOwnerID()
			end
		end
	end
	return -1
end

function CreateSimpleBox(point1, point2)
	local hlen = point2.y-point1.y
	local cen = point1.y+hlen/2
	local new1 = Vector(point1.x, cen, 0)
	local new2 = Vector(point2.x, cen, point2.y)
	return Physics:CreateBox(new2, new1, hlen, true)
end

function CDOTA_BaseNPC:IsRealCreep()
	return self.SSpawner ~= nil and self.SpawnerType ~= nil
end

function FindUnitsInBox(teamNumber, vStartPos, vEndPos, cacheUnit, teamFilter, typeFilter, flagFilter)
	local hlen = (vEndPos.y-vStartPos.y) / 2
	local cen = vStartPos.y+hlen
	vStartPos.y = cen
	vEndPos.y = cen
	vStartPos.z = 0
	vEndPos.z = 0
	return FindUnitsInLine(teamNumber, vStartPos, vEndPos, cacheUnit, hlen, teamFilter, typeFilter, flagFilter)
end

function GetTrueItemCost(name)
	local cost = GetItemCost(name)
	if cost <= 0 then
		local tempItem = CreateItem(name, nil, nil)
		if not tempItem then
			print("[GetTrueItemCost] Warning: " .. name)
		else
			cost = tempItem:GetCost()
			UTIL_Remove(tempItem)
		end
	end
	return cost
end

function FindNearestEntity(vec3, units)
	local unit
	local range
	for _,v in ipairs(units) do
		if not range or (v:GetAbsOrigin()-vec3):Length2D() < range then
			unit = v
			range = (v:GetAbsOrigin()-vec3):Length2D()
		end
	end
	return unit
end

function FindCourier(team)
	if type(TEAMS_COURIERS[team]) == "table" then
		return TEAMS_COURIERS[team]
	end
end

function GetNotScaledDamage(damage, unit)
	return math.floor(damage/(1 + (unit:GetIntellect() * DEFAULT_SPELL_AMPLIFY_PER_INT) / 100) + 0.5)
end

function GetSpellDamageAmplify(unit)
	return unit:GetIntellect() * 0.0625
end

function CDOTA_BaseNPC:GetSpellDamageAmplify()
	return GetSpellDamageAmplify(self)
end

function IsUltimateAbility(ability)
	return bit.band(ability:GetAbilityType(), 1) == 1
end

function IsUltimateAbilityKV(abilityname)
	return GetKeyValue(abilityname, "AbilityType") == "DOTA_ABILITY_TYPE_ULTIMATE"
end

function RandomPositionAroundPoint(pos, radius)
	return RotatePosition(pos, QAngle(0, RandomInt(0,359), 0), pos + Vector(1, 1, 0) * RandomInt(0, radius))
end

function EvalString(str)
	return DebugCallFunction(loadstring(str))
end

function GetPlayersInTeam(team)
	local players = {}
	for playerID = 0, DOTA_MAX_TEAM_PLAYERS-1  do
		if PlayerResource:IsValidPlayerID(playerID) and (not team or PlayerResource:GetTeam(playerID) == team) and not PLAYER_DATA[playerID].IsAbandoned then
			table.insert(players, playerID)
		end
	end
	return players
end

function RemoveAbilityWithModifiers(unit, ability)
	for _,v in ipairs(unit:FindAllModifiers()) do
		if v:GetAbility() == ability then
			v:Destroy()
		end
	end
	if ability.DestroyHookParticles then
		ability:DestroyHookParticles()
	end
	unit:RemoveAbility(ability:GetAbilityName())
end

function CreateGlobalParticle(name, callback, pattach)
	local ps = {}
	for team = DOTA_TEAM_FIRST, DOTA_TEAM_CUSTOM_MAX do
		local f = FindFountain(team)
		if f then
			local p = ParticleManager:CreateParticleForTeam(name, pattach or PATTACH_WORLDORIGIN, f, team)
			callback(p)
			table.insert(ps, p)
		end
	end
	return ps
end

function WorldPosToMinimap(vec)
	local pct1 = ((vec.x + MAP_LENGTH) / (MAP_LENGTH * 2))
	local pct2 = ((MAP_LENGTH - vec.y) / (MAP_LENGTH * 2))
	return pct1*100 .. "% " .. pct2*100 .. "%"
end

function GetHeroTableByName(name)
	local output = {}
	local custom = NPC_HEROES_CUSTOM[name]
	if not custom then
		print("[GetHeroTableByName] Missing hero: " .. name)
		return
	end
	if custom.base_hero then
		table.merge(output, GetUnitKV(custom.base_hero))
		for i = 1, 24 do
			output["Ability" .. i] = nil
		end
		table.merge(output, custom)
	else
		table.merge(output, GetUnitKV(name))
	end
	return output
end

function CreateExplosion(position, minRadius, fullRdius, minForce, fullForce, teamNumber, teamFilter, typeFilter, flagFilter)
	for _,v in ipairs(FindUnitsInRadius(teamNumber, position, nil, fullRdius, teamFilter, typeFilter, flagFilter, FIND_CLOSEST, false)) do
		if IsPhysicsUnit(v) then
			local force = 0
			local len = (position - v:GetAbsOrigin()):Length2D()
			if len < minRadius then
				force = fullForce
			elseif len <= fullRdius then
				local forceNotFullLen = fullRdius - minRadius
				local forceMid = fullForce - minForce
				local forceLevel = (fullRdius - len)/forceNotFullLen
				force = minForce + (forceMid*forceLevel)
			end
			local velocity = (v:GetAbsOrigin() - position):Normalized() * force
			v:AddPhysicsVelocity(velocity)
		end
	end
end

function CEntityInstance:SetNetworkableEntityInfo(key, value)
	local t = CustomNetTables:GetTableValue("custom_entity_values", tostring(self:GetEntityIndex())) or {}
	t[key] = value
	CustomNetTables:SetTableValue("custom_entity_values", tostring(self:GetEntityIndex()), t)
end

function CEntityInstance:ClearNetworkableEntityInfo()
	CustomNetTables:SetTableValue("custom_entity_values", tostring(self:GetEntityIndex()), nil)
end

function IsInBox(point, point1, point2)
	print(point, point.x > point1.x, point.y > point1.y, point.x < point2.x, point.y < point2.y)
	return point.x > point1.x and point.y > point1.y and point.x < point2.x and point.y < point2.y
end

function CDOTA_BaseNPC_Hero:CalculateRespawnTime()
	local time = (5 + self:GetLevel() * 0.1) + (self.RespawnTimeModifier or 0)
	if self.talent_keys and self.talent_keys.respawn_time_reduction then
		time = time + self.talent_keys.respawn_time_reduction
	end
	return math.max(time, 3)
end

function CDOTA_BaseNPC_Hero:IsWukongsSummon()
	return self:HasModifier("modifier_monkey_king_fur_army_soldier") or self:HasModifier("modifier_monkey_king_fur_army_soldier_inactive") or self:HasModifier("modifier_monkey_king_fur_army_soldier_hidden")
end

function CDOTA_BaseNPC_Hero:GetTotalHealthReduction()
	local pct = self:GetModifierStackCount("modifier_kadash_immortality_health_penalty", self)
	local mod = self:FindModifierByName("modifier_stegius_brightness_of_desolate_effect")
	if mod then
		pct = pct + mod:GetAbility():GetAbilitySpecial("health_decrease_pct")
	end
	------------
	local sara_evolution = self:FindAbilityByName("sara_evolution")
	if sara_evolution then
		local dec = sara_evolution:GetSpecialValueFor("health_reduction_pct")
		return dec + ((100-dec) * pct * 0.01)
	end
	return pct
end

function CDOTA_BaseNPC_Hero:CalculateHealthReduction()
	self:CalculateStatBonus()
	local pct = self:GetTotalHealthReduction()
	self:SetMaxHealth(pct >= 100 and 1 or self:GetMaxHealth() - pct * (self:GetMaxHealth()/100))
end

function CDOTA_BaseNPC_Hero:ResetAbilityPoints()
	self:SetAbilityPoints(self:GetLevel() - self:GetAbilityPointsWastedAllOnTalents())
end

function GetFullHeroName(unit)
	return unit.UnitName or unit:GetUnitName()
end

function CDOTA_BaseNPC:GetFullName()
	return self.UnitName or (self.GetUnitName and self:GetUnitName()) or self:GetName()
end

function CDOTA_BaseNPC:DestroyAllModifiers()
	for _,v in ipairs(self:FindAllModifiers()) do
		v:Destroy()
	end
end

function CDOTA_BaseNPC:HasModelChanged()
	if self:HasModifier("modifier_terrorblade_metamorphosis") or self:HasModifier("modifier_monkey_king_transform") or self:HasModifier("modifier_lone_druid_true_form") then
		return true
	end
	for _, modifier in ipairs(self:FindAllModifiers()) do
		if modifier.DeclareFunctions and table.contains(modifier:DeclareFunctions(), MODIFIER_PROPERTY_MODEL_CHANGE) then
			if modifier.GetModifierModelChange and modifier:GetModifierModelChange() then
				return true
			end
		end
	end
	return false
end

function GetConnectionState(pid)
	if DebugConnectionStates then
		local map = {
			[3] = "DOTA_CONNECTION_STATE_DISCONNECTED",
			[6] = "DOTA_CONNECTION_STATE_FAILED",
			[0] = "DOTA_CONNECTION_STATE_UNKNOWN",
			[1] = "DOTA_CONNECTION_STATE_NOT_YET_CONNECTED",
			[4] = "DOTA_CONNECTION_STATE_ABANDONED",
			[2] = "DOTA_CONNECTION_STATE_CONNECTED",
			[5] = "DOTA_CONNECTION_STATE_LOADING",
		}
		CPrint(pid, map[PlayerResource:GetConnectionState(pid)])
	end
	return PlayerResource:IsFakeClient(pid) and DOTA_CONNECTION_STATE_CONNECTED or PlayerResource:GetConnectionState(pid)
end

function DebugCallFunction(fun)
	local status, nextCall = xpcall(fun, function (msg)
		return msg..'\n'..debug.traceback()..'\n'
	end)
	if not status then
		Timers:HandleEventError(nil, nil, nextCall)
	end
end
function CDOTA_BaseNPC:FindClearSpaceForUnitAndSetCamera(position)
	self:Stop()
	PlayerResource:SetCameraTarget(self:GetPlayerOwnerID(), self)
	FindClearSpaceForUnit(self, position, true)
	Timers:CreateTimer(0.1, function()
		if IsValidEntity(self) then
			PlayerResource:SetCameraTarget(self:GetPlayerOwnerID(), nil)
			self:Stop()
		end
	end)
end

function CDOTA_BaseNPC:SetPlayerStat(key, value)
	if self.GetPlayerOwnerID and self:GetPlayerOwnerID() > -1 then
		PlayerResource:SetPlayerStat(self:GetPlayerOwnerID(), key, value)
	end
end
function CDOTA_BaseNPC:GetPlayerStat(key)
	if self.GetPlayerOwnerID and self:GetPlayerOwnerID() > -1 then
		return PlayerResource:GetPlayerStat(self:GetPlayerOwnerID(), key)
	end
end
function CDOTA_BaseNPC:ModifyPlayerStat(key, value)
	if self.GetPlayerOwnerID and self:GetPlayerOwnerID() > -1 then
		return PlayerResource:ModifyPlayerStat(self:GetPlayerOwnerID(), key, value)
	end
end
function CDOTA_BaseNPC:IsTrueHero()
	return self:IsRealHero() and not self:IsTempestDouble() and not self:IsWukongsSummon()
end
function CDOTA_PlayerResource:SetPlayerStat(PlayerID, key, value)
	local pd = PLAYER_DATA[PlayerID]
	if not pd.HeroStats then pd.HeroStats = {} end
	pd.HeroStats[key] = value
end
function CDOTA_PlayerResource:GetPlayerStat(PlayerID, key)
	local pd = PLAYER_DATA[PlayerID]
	return pd.HeroStats == nil and 0 or (pd.HeroStats[key] or 0)
end
function CDOTA_PlayerResource:ModifyPlayerStat(PlayerID, key, value)
	local v = self:GetPlayerStat(PlayerID, key) + value
	self:SetPlayerStat(PlayerID, key, v)
	return v
end

function GetInGamePlayerCount()
	local counter = 0
	for i = 0, 23 do
		if PlayerResource:IsValidPlayerID(i) then
			counter = counter + 1
		end
	end
	return counter
end

function GetTeamAllPlayerCount(iTeam)
	local counter = 0
	for i = 0, 23 do
		if PlayerResource:IsValidPlayerID(i) then
			if PlayerResource:GetTeam(i) == iTeam then
				counter = counter + 1
			end
		end
	end
	return counter
end

function CDOTA_BaseNPC:UpdateAttackProjectile()
	local projectile
	for i = #ATTACK_MODIFIERS, 1, -1 do
		local attack_modifier = ATTACK_MODIFIERS[i]
		local apply = true
		if attack_modifier.modifiers then
			for _,v in ipairs(attack_modifier.modifiers) do
				if not self:HasModifier(v) then
					apply = false
					break
				end
			end
		end
		if apply and attack_modifier.modifier then
			apply = self:HasModifier(attack_modifier.modifier)
		end
		if apply then
			projectile = attack_modifier.projectile
			break
		end
	end
	projectile = projectile or self:GetKeyValue("ProjectileModel")
	self:SetRangedProjectileName(projectile)
	return projectile
end

function Lifesteal(ability, unit, target, damage)
	local target = keys.target
	local lifesteal = keys.damage * keys.percent * 0.01
	SafeHeal(caster, lifesteal, keys.ability, true)
end

function RecreateAbility(unit, ability)
	local name = ability:GetAbilityName()
	local level = ability:GetLevel()
	RemoveAbilityWithModifiers(unit, ability)
	ability = AddNewAbility(unit, name, true)
	if ability then
		ability:SetLevel(level)
	end
	return ability
end

function CDOTA_Buff:SetSharedKey(key, value)
	local t = CustomNetTables:GetTableValue("shared_modifiers", self:GetParent():GetEntityIndex() .. "_" .. self:GetName()) or {}
	t[key] = value
	CustomNetTables:SetTableValue("shared_modifiers", self:GetParent():GetEntityIndex() .. "_" .. self:GetName(), t)
end

--By Noya, from DotaCraft
function GetPreMitigationDamage(value, victim, attacker, damagetype)
	if damagetype == DAMAGE_TYPE_PHYSICAL then
		local armor = victim:GetPhysicalArmorValue()
		local reduction = ((armor)*0.06) / (1+0.06*(armor))
		local damage = value / (1 - reduction)
		return damage,reduction
	elseif damagetype == DAMAGE_TYPE_MAGICAL then
		local reduction = victim:GetMagicalArmorValue()*0.01
		local damage = value / (1 - reduction)

		return damage,reduction
	else
		return value,0
	end
end

function CDOTA_PlayerResource:SetPlayerTeam(playerID, newTeam)
	local oldTeam = self:GetTeam(playerID)
	local player = self:GetPlayer(playerID)
	local hero = self:GetSelectedHeroEntity(playerID)
	PlayerTables:RemovePlayerSubscription("dynamic_minimap_points_" .. oldTeam, playerID)
	local playerPickData = {}
	local tableData = PlayerTables:GetTableValue("hero_selection", oldTeam)
	if tableData and tableData[playerID] then
		table.merge(playerPickData, tableData[playerID])
		tableData[playerID] = nil
		PlayerTables:SetTableValue("hero_selection", oldTeam, tableData)
	end

	for _,v in ipairs(FindAllOwnedUnits(player)) do
		v:SetTeam(newTeam)
	end
	player:SetTeam(newTeam)

	PlayerResource:UpdateTeamSlot(playerID, newTeam, 1)
	PlayerResource:SetCustomTeamAssignment(playerID, newTeam)

	local newTableData = PlayerTables:GetTableValue("hero_selection", newTeam)
	if newTableData and playerPickData then
		newTableData[playerID] = playerPickData
		PlayerTables:SetTableValue("hero_selection", newTeam, newTableData)
	end
	--[[for _, v in ipairs(Entities:FindAllByClassname("npc_dota_courier") ) do
		v:SetControllableByPlayer(playerID, v:GetTeamNumber() == newTeam)
	end]]
	--FindCourier(oldTeam):SetControllableByPlayer(playerID, false)
	local targetCour = FindCourier(newTeam)
	if IsValidEntity(targetCour) then
		targetCour:SetControllableByPlayer(playerID, true)
	end
	PlayerTables:RemovePlayerSubscription("dynamic_minimap_points_" .. oldTeam, playerID)
	PlayerTables:AddPlayerSubscription("dynamic_minimap_points_" .. newTeam, playerID)

	for i = 0, hero:GetAbilityCount() - 1 do
		local skill = hero:GetAbilityByIndex(i)
		if skill then
			--print(skill.GetIntrinsicModifierName and skill:GetIntrinsicModifierName())
			if skill.GetIntrinsicModifierName and skill:GetIntrinsicModifierName() then
				RecreateAbility(hero, skill)
			end
		end
	end

	CustomGameEventManager:Send_ServerToPlayer(player, "arena_team_changed_update", {})
	PlayerResource:RefreshSelection()
end

function SimpleDamageReflect(victim, attacker, damage, flags, ability, damage_type)
	if victim:IsAlive() and not HasDamageFlag(flags, DOTA_DAMAGE_FLAG_REFLECTION) and attacker:GetTeamNumber() ~= victim:GetTeamNumber() then
		--print("Reflected " .. damage .. " damage from " .. victim:GetUnitName() .. " to " .. attacker:GetUnitName())
		ApplyDamage({
			victim = attacker,
			attacker = victim,
			damage = damage,
			damage_type = damage_type,
			damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION + DOTA_DAMAGE_FLAG_REFLECTION,
			ability = ability
		})
		return true
	end
	return false
end

function CDOTA_BaseNPC:GetLinkedHeroNames()
	return GetLinkedHeroNames(self:GetFullName())
end

function GetLinkedHeroNames(hero)
	local linked = GetKeyValue(hero, "LinkedHero")
	return linked and string.split(linked, " | ") or {}
end

function CDOTA_BaseNPC:GetLinkedHeroEntities()
	local linked = self:GetLinkedHeroNames()
	local ents = {}
	for _,v in ipairs(linked) do
		local plid = HeroSelection:GetSelectedHeroPlayer(v)
		if plid then
			local ent = PlayerResource:GetSelectedHeroEntity(plid)
			table.insert(ents, ent)
		end
	end
	return ents
end

function CDOTA_PlayerResource:SetDisableHelpForPlayerID(nPlayerID, nOtherPlayerID, disabled)
	if nPlayerID ~= nOtherPlayerID then
		if not PLAYER_DATA[nPlayerID].DisableHelp then
			PLAYER_DATA[nPlayerID].DisableHelp = {}
		end
		PLAYER_DATA[nPlayerID].DisableHelp[nOtherPlayerID] = disabled

		local disable_help_data = PlayerTables:GetTableValue("disable_help_data", nPlayerID)
		disable_help_data[nOtherPlayerID] = PLAYER_DATA[nPlayerID][nOtherPlayerID]
		PlayerTables:SetTableValue("disable_help_data", disable_help_data)
	end
end

function CDOTA_PlayerResource:IsDisableHelpSetForPlayerID(nPlayerID, nOtherPlayerID)
	return PLAYER_DATA[nPlayerID] ~= nil and PLAYER_DATA[nPlayerID].DisableHelp ~= nil and PLAYER_DATA[nPlayerID].DisableHelp[nOtherPlayerID] and PlayerResource:GetTeam(nPlayerID) == PlayerResource:GetTeam(nOtherPlayerID)
end

--TODO
--[[function CDOTA_BaseNPC:AddNewModifierShared(hCaster, hAbility, pszScriptName, hModifierTable)
	CustomNetTables:SetTableValue("shared_modifiers", self:GetEntityIndex() .. "_" .. pszScriptName, hModifierTable)
	return self:AddNewModifier(hCaster, hAbility, pszScriptName, hModifierTable)
end]]
