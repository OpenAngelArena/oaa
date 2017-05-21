
if Glyph == nil then
  Debug.EnabledModules['filters:glyph'] = true
  DebugPrint('Creating new Glyph Filter Object')
  Glyph = class({})
end

function Glyph:Init()
  FilterManager:AddFilter(FilterManager.ExecuteOrder, self, Dynamic_Wrap(Glyph, "Filter"))
end


function Glyph:Filter(keys)
  local order = keys.order_type
  local abilityEID = keys.entindex_ability
  local ability = EntIndexToHScript(abilityEID)
  local issuerID = keys.issuer_player_id_const
  local target = EntIndexToHScript(keys.entindex_target)

  if order == DOTA_UNIT_ORDER_GLYPH then
    -- Handle Glyph aka Ward Button
    DebugPrintTable(keys)
    return false
  elseif order == DOTA_UNIT_ORDER_RADAR then
    -- Handle Scan
    DebugPrintTable(keys)
    return true
  end

  return true
end
