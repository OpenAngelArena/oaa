
ShadowTowers = Components:Register('ShadowTowers', COMPONENT_GAME_IN_PROGRESS)

function ShadowTowers:Init ()
  -- Debug:EnableDebugging()
  DebugPrint('ShadowTowers init!')
  FilterManager:AddFilter(FilterManager.ModifierGained, self, Dynamic_Wrap(ShadowTowers, "ShadowAmuletFilter"))
end

function ShadowTowers:ShadowAmuletFilter (filterTable)
  local name = filterTable.name_const
  local parent_index = filterTable.entindex_parent_const

  if not parent_index or not name then
    return true
  end

  if name ~= "modifier_item_shadow_amulet_fade" then
    return true
  end

  local parent = EntIndexToHScript(parent_index)

  -- [components\filters\shadowtowers:19] Applying modifier modifier_item_shadow_amulet_fade to npc_azazel_tower_watch
  if parent and parent.GetUnitName and parent:GetUnitName():sub(1, 10) == "npc_azazel" then
    return false
  end

  return true
end
