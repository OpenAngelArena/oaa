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
  local minimap_camps = {'minimap_small_camp', 'minimap_medium_camp', 'minimap_hard_camp', 'minimap_ancient_camp'}

  local camps = Entities:FindAllByName('creep_camp')
  for _,camp in pairs(camps) do
    for _,teamID in pairs({DOTA_TEAM_GOODGUYS, DOTA_TEAM_BADGUYS}) do
      print("creating Minimap spawn for team " .. teamID .. " at " .. camp:GetAbsOrigin().x .. "|" .. camp:GetAbsOrigin().y)
      local dummy = CreateUnitByName(minimap_camps[camp:GetIntAttr('CreepType')], camp:GetAbsOrigin(), false, nil, nil, teamID)
      dummy:AddNewModifier(dummy, nil, "modifier_minimap", {})
      table.insert(self.Minimap_Camps, dummy)
    end
  end
end

function Minimap:Respawn()
  for _,minimap_camp in pairs(self.Minimap_Camps) do
    minimap_camp.Respawn = true
  end
end


function Minimap:SpawnBossIcon(hPit, iTier)
  local minimap_bosses = {'minimap_boss_tier1', 'minimap_boss_tier2', 'minimap_boss_tier3', 'minimap_boss_tier4', 'minimap_boss_tier4', 'minimap_boss_tier4'}
  if not self.Minimap_Bosses then
    self.Minimap_Bosses = {}
  end

  for _,teamID in pairs({DOTA_TEAM_GOODGUYS, DOTA_TEAM_BADGUYS}) do
    local boss_minimap_camp = CreateUnitByName(minimap_bosses[iTier], hPit:GetAbsOrigin(), false, nil, nil, teamID)
    boss_minimap_camp:AddNewModifier(boss_minimap_camp, nil, "modifier_minimap", {IsBoss = true})
    boss_minimap_camp.Respawn = true
  end
end



