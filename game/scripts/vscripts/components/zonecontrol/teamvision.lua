
if TeamVision == nil then
  --Debug:EnableDebugging()
  DebugPrint('Creating new TeamVision object.')
  TeamVision = class({})
end

function TeamVision:Init()
  self.moduleName = "Team Vision"

  GameEvents:OnHeroSelection(partial(TeamVision.AddVision, TeamVision))
end

function TeamVision:AddVision()
  --Debug:EnableDebugging()
  DebugPrint('Started Adding Vision.')
  -- Find all buildings on the map
  local buildings = FindUnitsInRadius(
    DOTA_TEAM_GOODGUYS,
    Vector(0,0,0),
    nil,
    FIND_UNITS_EVERYWHERE,
    DOTA_UNIT_TARGET_TEAM_BOTH,
    DOTA_UNIT_TARGET_BUILDING,
    DOTA_UNIT_TARGET_FLAG_INVULNERABLE,
    FIND_ANY_ORDER,
    false
  )

  -- local fountains = Entities:FindAllByClassname("ent_dota_fountain")
  -- local radiant_fountain
  -- local dire_fountain
  -- for _, entity in pairs(fountains) do
    -- if entity:GetTeamNumber() == DOTA_TEAM_GOODGUYS then
      -- radiant_fountain = entity
    -- elseif entity:GetTeamNumber() == DOTA_TEAM_BADGUYS then
      -- dire_fountain = entity
    -- end
  -- end

  -- Iterate through each found entity and check its name
  for _, building in pairs(buildings) do
    if building and not building:IsNull() then
      local building_name = building:GetName()

      -- Check if it's a Healing Shrine
      if string.find(building_name, "filler") or string.find(building_name, "_shrine") then
        --print(building:GetTeamNumber())
        building:AddNewModifier(building, nil, "modifier_generic_vision_dummy_stuff", {})
        building:AddNewModifier(building, nil, "modifier_shrine_oaa", {})
        --building:RemoveModifierByName("modifier_invulnerable")
      elseif string.find(building_name, "watch_tower") then
        building:RemoveModifierByName("modifier_invulnerable")
      end
    end
  end
end
