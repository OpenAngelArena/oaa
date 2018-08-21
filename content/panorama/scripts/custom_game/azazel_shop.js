'use strict';
/* global FindDotaHudElement, $, CustomNetTables */
var secretShopColumnsParent = FindDotaHudElement('GridSecretShopItems');
var buildingsColumn = CreateOrSelectBuildingsColumn();
var summonsColumn = CreateOrSelectSummonsColumn();
var elixirColumn = CreateOrSelectElixirColumn();
var secretShopColumn = secretShopColumnsParent.FindChild('ShopItems_secretshop');
secretShopColumn.Children().forEach(function (item) {
  var itemName = (item.FindChild('ItemImage')).itemname;
  var itemTable = CustomNetTables.GetTableValue('info', itemName);
  if (itemTable !== null && itemTable !== undefined) {
    if (itemTable.SecretShopType === 'Buildings') {
      item.SetParent(buildingsColumn);
    } else if (itemTable.SecretShopType === 'Summons') {
      item.SetParent(summonsColumn);
    } else if (itemTable.SecretShopType === 'Elixirs') {
      item.SetParent(elixirColumn);
    }
    // item.SetPanelEvent(
    //   PanelEvent.ON_MOUSE_OVER,
    //   function(){
    //     $.DispatchEvent("DOTAShowAbilityShopItemTooltip", item, itemName);
    //   }
    // );
  }
});
secretShopColumn.visible = false;
// =================== Functions ===========================
function CreateOrSelectBuildingsColumn () {
  var column = secretShopColumnsParent.FindChildTraverse('ShopItems_Buildings');
  if (column === null) {
    column = $.CreatePanel('Panel', $.GetContextPanel(), 'ShopItems_Buildings');
  }
  column.SetHasClass('ShopItemsColumn', true);
  column.SetParent(secretShopColumnsParent);
  return column;
}
function CreateOrSelectSummonsColumn () {
  var column = secretShopColumnsParent.FindChildTraverse('ShopItems_Summons');
  if (column === null) {
    column = $.CreatePanel('Panel', $.GetContextPanel(), 'ShopItems_Summons');
  }
  column.SetHasClass('ShopItemsColumn', true);
  column.SetParent(secretShopColumnsParent);
  return column;
}
function CreateOrSelectElixirColumn () {
  var column = secretShopColumnsParent.FindChildTraverse('ShopItems_Elixir');
  if (column === null) {
    column = $.CreatePanel('Panel', $.GetContextPanel(), 'ShopItems_Elixir');
  }
  column.SetHasClass('ShopItemsColumn', true);
  column.SetParent(secretShopColumnsParent);
  return column;
}
