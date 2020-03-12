-- Courier Spawner and maybe future handler

-- Taken from bb template
if Courier == nil then
  Debug.EnabledModules['courier:*'] = true
  DebugPrint ( 'creating new Courier object' )
  Courier = class({})
end

function Courier:Init ()
  Courier.hasCourier = {}
  LinkLuaModifier("modifier_custom_courier_stuff", "components/courier/courier.lua", LUA_MODIFIER_MOTION_NONE)
  Courier.enableCustomCourier = false -- if you want custom couriers just set this to true
  if Courier.enableCustomCourier then
    GameEvents:OnHeroInGame(Courier.SpawnCourier)
  else
    GameRules:GetGameModeEntity():SetFreeCourierModeEnabled(true)
    ListenToGameEvent("npc_spawned", Dynamic_Wrap(Courier, 'OnNpcSpawned'), self)
  end
end

function Courier.SpawnCourier(hero)
  if hero:GetTeamNumber() == DOTA_TEAM_NEUTRALS then
    return
  end
  if Courier.hasCourier[hero] then
    return
  end

  if hero:IsTempestDouble() or hero:IsClone() then
    return
  end

  Timers:CreateTimer(1, function ()
    DebugPrint("Creating Courier for Hero " .. hero:GetUnitName())

    local playerID = hero:GetPlayerOwnerID()
    -- Create a courier
    local courier_unit = CreateUnitByName("npc_dota_courier", hero:GetAbsOrigin(), true, hero, hero, hero:GetTeamNumber())
    courier_unit:SetOwner(hero)
    courier_unit:SetControllableByPlayer(playerID, true)
    courier_unit:SetMoveCapability(DOTA_UNIT_CAP_MOVE_FLY)
    courier_unit:RemoveAbility("courier_burst")
    courier_unit:RemoveAbility("courier_shield")
    courier_unit:RemoveAbility("courier_go_to_sideshop")
    courier_unit:RemoveAbility("courier_go_to_sideshop2")
    --courier_unit:RemoveAbility("nothing")   -- it doesnt give an error even if it didnt find an ability with that name
    courier_unit:AddNewModifier(hero, nil, "modifier_custom_courier_stuff", {})

    Courier.hasCourier[hero] = true
  end)
end

function Courier:OnNpcSpawned(keys)
  local npc
  if keys.entindex then
    npc = EntIndexToHScript(keys.entindex)
  end
  if not npc then
    return
  end
  if npc:IsCourier() then
    npc:AddNewModifier(npc, nil, "modifier_custom_courier_stuff", {})
  end
end

---------------------------------------------------------------------------------------------------

modifier_custom_courier_stuff = class({})

function modifier_custom_courier_stuff:IsHidden()
  return true
end

function modifier_custom_courier_stuff:IsPurgable()
  return false
end

function modifier_custom_courier_stuff:RemoveOnDeath()
  return false
end

function modifier_custom_courier_stuff:DeclareFunctions()
  local funcs = {}
  if Courier.enableCustomCourier then
    funcs = {
      MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
      MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
      MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
      MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
      MODIFIER_PROPERTY_MOVESPEED_LIMIT,
      MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE,
      MODIFIER_PROPERTY_VISUAL_Z_DELTA,
      MODIFIER_EVENT_ON_TAKEDAMAGE
    }
  else
    funcs = {
      MODIFIER_PROPERTY_TOTAL_CONSTANT_BLOCK,
    }
  end
  return funcs
end

function modifier_custom_courier_stuff:GetAbsoluteNoDamageMagical()
  return 1
end

function modifier_custom_courier_stuff:GetAbsoluteNoDamagePhysical()
  return 1
end

function modifier_custom_courier_stuff:GetAbsoluteNoDamagePure()
  return 1
end

function modifier_custom_courier_stuff:GetModifierExtraHealthBonus()
  return 5000 -- So Axe cannot kill it with Culling Blade
end

function modifier_custom_courier_stuff:CheckState()
  local state = {
    [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
    [MODIFIER_STATE_BLIND] = true,
  }
  if Courier.enableCustomCourier then
    state[MODIFIER_STATE_FLYING] = true
  end
  return state
end

function modifier_custom_courier_stuff:OnTakeDamage(event)
  if event.unit == self:GetParent() then
    --print("Courier has taken damage")
    local parent = self:GetParent()
    parent.taken_damage = true

    Timers:CreateTimer(1, function()
      parent.taken_damage = false
    end)
  end
end

function modifier_custom_courier_stuff:GetModifierMoveSpeed_Limit()
  local parent = self:GetParent()
  if parent.taken_damage then
    return 100
  end
  return 380
end

function modifier_custom_courier_stuff:GetModifierMoveSpeed_Absolute()
  local parent = self:GetParent()
  if parent.taken_damage then
    return 100
  end
  return 380
end

function modifier_custom_courier_stuff:GetVisualZDelta()
  return 220
end

function modifier_custom_courier_stuff:GetModifierTotal_ConstantBlock(keys)
  -- Block damage only from neutrals
  if keys.attacker:GetTeamNumber() == DOTA_TEAM_NEUTRALS then
    return keys.damage
  end
  return 0
end
