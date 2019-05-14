
SellBlackList = Components:Register('SellBlackList', COMPONENT_STRATEGY)

local ItemSellBlackList = {
  --"item_upgrade_core",
  "item_infinite_bottle",
  "item_farming_core",
  "item_arcane_origin",
  "item_phase_origin",
  "item_power_origin",
  "item_tranquil_origin",
  "item_travel_origin",
}

function SellBlackList:Init ()
  FilterManager:AddFilter(FilterManager.ExecuteOrder, self, Dynamic_Wrap(SellBlackList, "OrderFilter"))
end

function SellBlackList:OrderFilter (filterTable)
  local order = filterTable.order_type
  local abilityEID = filterTable.entindex_ability
  local ability = EntIndexToHScript(abilityEID)
  local issuerID = filterTable.issuer_player_id_const
  local target = EntIndexToHScript(filterTable.entindex_target)
  local targetIsShop = false
  if target then
    targetIsShop = string.find(target:GetName(), "shop") ~= nil
  end

  if order == DOTA_UNIT_ORDER_SELL_ITEM or (targetIsShop and order == DOTA_UNIT_ORDER_GIVE_ITEM) then
    for _,v in ipairs(ItemSellBlackList) do
      if string.find(ability:GetName(), v) ~= nil then
        DebugPrint('Someone is trying to sell an item (' .. ability:GetName() .. ') on the blacklist(' .. v .. ').')
        CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(issuerID), "custom_dota_hud_error_message", {reason=70, message=""})
        return false
      end
    end
  end

  return true
end
