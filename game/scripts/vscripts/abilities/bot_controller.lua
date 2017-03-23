LinkLuaModifier( "modifier_disable_control", "modifiers/modifier_disable_control", LUA_MODIFIER_MOTION_NONE )

function Control( keys )

	local caster = keys.caster
	local ability = keys.ability
	--local ability_level = ability:GetLevel() - 1

	-- Little bonus for bots because they dont farm and mostly walk around doing nothing
	caster:AddExperience(5,0,false,false)
	caster:ModifyGold(5,false,0)

	--if PlayerResource:GetSteamAccountID(caster:GetPlayerOwnerID()) ~= 0 then return end

	-- Search for heros within 1500 range
	local heroes = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, 1500, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE, FIND_ANY_ORDER, false)
	-- Search for creeps within 500 range
	local creeps = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, 500, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE, FIND_ANY_ORDER, false)
	
	-- If no heros nearbym and not maximum health but not super low health and within range of fountain, wait at foutain until fully regened
	if #heroes == 0 and caster:GetHealth() >= 400 and caster:GetHealth() < caster:GetMaxHealth() - 200 and caster:FindModifierByName("modifier_fountain_aura_buff") then
		caster:MoveToPosition(caster:GetAbsOrigin())
		return
	end
	
	-- If there are creeps nearby run away towards the center of the map
	if #creeps > 0 then
		caster:MoveToPosition(Vector(0,0,0))
		return
	end

	-- If there are hero(s) nearby and bot is low on health, let bot decide what todo
	if #heroes > 0 or caster:GetHealth() < 400 then
		caster:RemoveModifierByName("modifier_disable_control")
		return

	-- If none of the above conditions are made, disable all bot orders and force them to move to a semi-random part of the map
	else	
		caster:AddNewModifier( caster, self, "modifier_disable_control", {} )
		-- Only recieves a new move order command every 10 seconds to prevent going in circles
		if ability:IsCooldownReady() then
			caster:MoveToPosition(Vector(RandomInt(-6000, 6000), RandomInt(-6000, 6000), RandomInt(-6000, 6000)))
		end	
	end

	


	-- If the ability is on cooldown, do nothing
	if not ability:IsCooldownReady() then
		return nil
	end

	ability:StartCooldown(10)
	
end
