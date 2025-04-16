/* global $, GetDotaHud, Players, Entities, Abilities, Game, dotaunitorder_t, CustomNetTables */

const localPlayer = Players.GetLocalPlayer();
const DotaHUD = GetDotaHud();

$.RegisterForUnhandledEvent('StyleClassesChanged', function (panel) {
  if (panel == null) { return; }
  if (panel.paneltype === 'DOTAAbilityPanel' && panel.BHasClass('ShowingItemContextMenu')) {
    let currentlySelectedUnit = Players.GetQueryUnit(localPlayer);
    if (currentlySelectedUnit === -1) {
      currentlySelectedUnit = Players.GetLocalPlayerPortraitUnit();
    }
    if (currentlySelectedUnit !== Players.GetPlayerHeroEntityIndex(Players.GetLocalPlayer())) return;
    if (!Entities.IsRealHero(Players.GetLocalPlayerPortraitUnit())) { return; }
    const itemImage = panel.FindChildTraverse('ItemImage');
    const abilityIndex = itemImage.contextEntityIndex;
    const itemName = Abilities.GetAbilityName(abilityIndex);
    if (!isUpgradable(itemName)) { return; }
    const FindContextMenu = DotaHUD.FindChildTraverse('InventoryItemContextMenu');
    if (FindContextMenu) {
      const Buttons = FindContextMenu.FindChildTraverse('Contents');
      if (Buttons) {
        const FPanel = Buttons.FindChildTraverse('TestButton');
        if (!FPanel) {
          const panel = $.CreatePanel('Button', Buttons, 'TestButton');
          panel.visible = true;
          
          $.CreatePanel('Label', panel, 'TestText', { text: $.Localize('#DOTA_SHOP_DETAILS_UPGRADE') });
          panel.SetPanelEvent('onactivate', function () {
            buyUpgrade(localPlayer, itemName);
            $.DispatchEvent('DismissAllContextMenus');
          });
        }
      }
    }
  } 
});



function isUpgradable (itemName) {
  const allItems = CustomNetTables.GetTableValue('item_kv', 'upgrade_items');
  if (allItems && allItems[itemName]) {
    return allItems[itemName];
  }
  return false;
}

function buyUpgrade (ent, itemName) {
  const idsToPurchase = isUpgradable(itemName);
  const order = {};
  order.OrderType = dotaunitorder_t.DOTA_UNIT_ORDER_PURCHASE_ITEM;
  order.UnitIndex = ent;
  order.Queue = false;
  order.ShowEffects = true;
  for (const id of Object.values(idsToPurchase)) {
    order.AbilityIndex = Number(id);
    Game.PrepareUnitOrders(order);
  }
}

function GetItemID (itemName) {
  const allItems = CustomNetTables.GetTableValue('item_kv', 'custom_items');
  if (allItems && allItems[itemName]) {
    return allItems[(itemName)];
  }
  return null;
}
