LinkLuaModifier("modifier_minimap", "modifiers/modifier_minimap", LUA_MODIFIER_MOTION_NONE)

-- -- Drop out of self-include
-- if not Entities or not Entities.CreateByClassname then return end

-----------------------------------------------------------------

if not Minimap then
    Minimap = class({})
end

-- Called when game starts
function Minimap:InitializeCampIcons()
  self.Minimap_Camps = {}
  local minimap_camps = {'minimap_small_camp', 'minimap_medium_camp', 'minimap_hard_camp', 'minimap_ancient_camp', 'minimap_ancient_camp'}

  local camps = Entities:FindAllByName('creep_camp')
  for _,camp in pairs(camps) do
    for _,teamID in pairs({DOTA_TEAM_GOODGUYS, DOTA_TEAM_BADGUYS}) do
      DebugPrint("creating Minimap spawn for team " .. teamID .. " at " .. camp:GetAbsOrigin().x .. "|" .. camp:GetAbsOrigin().y)
      if not minimap_camps[camp:GetIntAttr('CreepType')] then
        Debug:EnableDebugging()
        DebugPrint("Invalid creep camp type " .. camp:GetIntAttr('CreepType'))
      else
        local dummy = CreateUnitByName(minimap_camps[camp:GetIntAttr('CreepType')], camp:GetAbsOrigin(), false, nil, nil, teamID)

        if not dummy then
          Debug:EnableDebugging()
          DebugPrint("Failed to create camp minimap icon " .. minimap_camps[camp:GetIntAttr('CreepType')])
        end

        dummy:AddNewModifier(dummy, nil, "modifier_minimap", {})
        table.insert(self.Minimap_Camps, dummy)
      end
    end
  end
end

function Minimap:Respawn()
  for _,minimap_camp in pairs(self.Minimap_Camps) do
    minimap_camp.Respawn = true
  end
end


function Minimap:SpawnBossIcon(hPit, iTier)
  local minimap_bosses = {'minimap_boss_tier1', 'minimap_boss_tier2', 'minimap_boss_tier3', 'minimap_boss_tier4', 'minimap_boss_tier5', 'minimap_boss_tier5'}
  if not self.Minimap_Bosses then
    self.Minimap_Bosses = {}
  end

  for _,teamID in pairs({DOTA_TEAM_GOODGUYS, DOTA_TEAM_BADGUYS}) do
    local boss_minimap_camp = CreateUnitByName(minimap_bosses[iTier], hPit:GetAbsOrigin(), false, nil, nil, teamID)
    boss_minimap_camp:AddNewModifier(boss_minimap_camp, nil, "modifier_minimap", {IsBoss = true})
    boss_minimap_camp.Respawn = true
  end
end

--To Add capture point icons
function Minimap:SpawnCaptureIcon(location)
  for _,teamID in pairs({DOTA_TEAM_GOODGUYS, DOTA_TEAM_BADGUYS}) do
    local capture_point_minimap = CreateUnitByName('minimap_capture_point', location, false, nil, nil, teamID)
    capture_point_minimap:AddNewModifier(capture_point_minimap, nil, "modifier_minimap", {IsCapture = true })
    capture_point_minimap.Respawn = true
  end
end
