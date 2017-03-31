if SellBlackList == nil then
  Debug.EnabledModules['sellblacklist:*'] = false
  DebugPrint('creating new SellBlackList object')
  SellBlackList = class({})
end

function SellBlackList:Init ()
  GameRules:GetGameModeEntity():SetExecuteOrderFilter( Dynamic_Wrap( SellBlackList, 'OrderFilter' ), self )

  ItemSellBlackList = {
    "item_upgrade_core",
  }
end

function SellBlackList:OrderFilter (filterTable)
  local order = filterTable.order_type
  local abilityEID = filterTable.entindex_ability
  local ability = EntIndexToHScript(abilityEID)
  local issuerID = filterTable.issuer_player_id_const

  if order == DOTA_UNIT_ORDER_SELL_ITEM then
    for _,v in ipairs(ItemSellBlackList) do
      if string.find(ability:GetName(), v) ~= nil then
        DebugPrint('Someone is trying to sell an item (' .. ability:GetName() .. ') on the blacklist(' .. v .. ').')
        Notifications:Bottom(PlayerResource:GetPlayer(issuerID), {
          text="You can't sell this Item!",
          duration=1.5,
          style={
            color="#b71c1c",
            ["font-size"]="28px"
          }
        })
        return false
      end
    end
  end

  return true
end
