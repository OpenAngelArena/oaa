LinkLuaModifier( "modifier_disable_control", "modifiers/modifier_disable_control", LUA_MODIFIER_MOTION_NONE )

function Control( keys )

  local caster = keys.caster
  local ability = keys.ability
  local ArenaMiddle = nil
  local cooldown = 10
  local healthRetreat = 400
  local enemyHeroSearchRadius = 1500
  local creepSearchRadius = 500

  --local ability_level = ability:GetLevel() - 1

  -- Little bonus for bots because they dont farm and mostly walk around doing nothing

  position = caster:GetAbsOrigin()
  -- Hardcoded arenas coordinates, the top left corner and the bottom right corner
  if position.x < -5000 and position.y > 4500 then
    ArenaMiddle = Vector( -6627.2553710938+RandomInt(-400, 400), 6054.2856445313+RandomInt(-400, 400), 384)
  elseif position.x > 4500 and position.y < -4000 then
    ArenaMiddle = Vector( 6708.0649414063+RandomInt(-400, 400), -6133.7529296875+RandomInt(-400, 400), 410.38513183594)
  end

  -- If in Arena, find all tp scrolls and put them on cooldown so they cannot be used
  if ArenaMiddle then
    for slot =  DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_6 do
            item = caster:GetItemInSlot(slot)
            if item ~= nil then
                itemName = item:GetAbilityName()
                if itemName == "item_tpscroll" then
                    item:StartCooldown(5)
                    break
                end
            end
        end
    end

  --if PlayerResource:GetSteamAccountID(caster:GetPlayerOwnerID()) ~= 0 then return end

  -- Search for heros within 1500 range
  local heroes = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, enemyHeroSearchRadius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE, FIND_ANY_ORDER, false)
  -- Search for creeps within 500 range
  local creeps = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, creepSearchRadius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE, FIND_ANY_ORDER, false)

  -- If no heros nearbym and not maximum health but not super low health and within range of fountain, wait at foutain until fully regened
  if #heroes == 0 and caster:GetHealth() >= healthRetreat and caster:GetHealth() < caster:GetMaxHealth() - 200 and caster:FindModifierByName("modifier_fountain_aura_buff") then
    --caster:MoveToPosition(caster:GetAbsOrigin())
    return
  end

  -- If there are creeps nearby run away towards the center of the map
  if #creeps > 0 then
    --caster:MoveToPosition(Vector(0,0,0))
    return
  end

  -- If there are hero(s) nearby and bot is low on health, let bot decide what todo
  if #heroes > 0 or caster:GetHealth() < healthRetreat then
    caster:RemoveModifierByName("modifier_disable_control")
  -- If none of the above conditions are made, disable all bot orders and force them to move to a semi-random part of the map
  else
    caster:AddNewModifier( caster, ability, "modifier_disable_control", {} )
    -- Only recieves a new move order command every 10 seconds to prevent going in circles
    if ability:IsCooldownReady() then
      -- If bots are in a duel and the arena middle has been set move there, otherwise go to random spot
      if ArenaMiddle then
        --caster:MoveToPositionAggressive(ArenaMiddle)
        cooldown = 3
      else
        --caster:MoveToPosition(Vector(RandomInt(-6000, 6000), RandomInt(-6000, 6000), RandomInt(-6000, 6000)))
      end
    end
  end




  -- If the ability is on cooldown, do nothing
  if not ability:IsCooldownReady() then
    return nil
  end

  ability:StartCooldown(cooldown)

end
