-- Courier Spawner and maybe future handler


-- Taken from bb template
if Courier == nil then
  Debug.EnabledModules['courier:*'] = true
  DebugPrint ( 'creating new Courier object' )
  Courier = class({})
end

function Courier:Init ()
  Courier.hasCourier = {}
  Courier.hasCourier[DOTA_TEAM_BADGUYS] = false
  Courier.hasCourier[DOTA_TEAM_GOODGUYS] = false
end

function Courier:SpawnCourier (hero)
  DebugPrint("Creating Courier for Team " .. hero:GetTeamNumber())
  courier = hero:AddItemByName('item_courier')
  flying = hero:AddItemByName('item_flying_courier')
  Courier.hasCourier[hero:GetTeamNumber()] = true
end
