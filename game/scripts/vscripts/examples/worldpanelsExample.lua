require("libraries/worldpanels")

if not WorldPanelExample then
  WorldPanelExample = class({})
end

function WorldPanelExample:OnNPCSpawned(keys)
  --Apply a worldpanel health bar to every spawned hero unit
  local npc = EntIndexToHScript(keys.entindex)

  if npc.IsRealHero and npc:IsRealHero() and not npc.worldPanel then
    npc:AddNewModifier(npc, nil, "modifier_no_health", {})

    -- entityHeight could be loaded from the npc_heroes.txt "HealthBarOffset"
    npc.worldPanel = WorldPanels:CreateWorldPanelForAll(
      {layout = "file://{resources}/layout/custom_game/worldpanels/healthbar.xml",
        entity = npc:GetEntityIndex(),
        entityHeight = 210,
      })
  end
end

if not WorldPanelExample.initialized then
  LinkLuaModifier("modifier_no_health", "examples/modifier_no_health", LUA_MODIFIER_MOTION_NONE)

  Timers:CreateTimer(1, function()
    WorldPanels:CreateWorldPanelForAll(
      {layout = "file://{resources}/layout/custom_game/worldpanels/arrow.xml",
        position = GetGroundPosition(Vector(0,0,0), nil) + Vector(0,0,200),
        edgePadding = 5,
      })
    end)

  ListenToGameEvent('npc_spawned', Dynamic_Wrap(WorldPanelExample, 'OnNPCSpawned'), WorldPanelExample)
  WorldPanelExample.initialized = true
end