
/* global FindDotaHudElement, $, CustomNetTables */

interface DotaShopImage extends Panel {
  itemname : string;
}

let secretShopColumnsParent = FindDotaHudElement('GridSecretShopItems');

let buildingsColumn = CreateOrSelectBuildingsColumn();
let summonsColumn = CreateOrSelectSummonsColumn();
let elixirColumn = CreateOrSelectElixirColumn();

let secretShopColumn = secretShopColumnsParent.FindChild('ShopItems_secretshop');

secretShopColumn.Children().forEach(item => {
  let itemName = (<DotaShopImage>(item.FindChild('ItemImage'))).itemname;
  let itemTable = CustomNetTables.GetTableValue('info', itemName);
  if (itemTable !== null && itemTable !== undefined)
  {
    if(itemTable.SecretShopType === 'Buildings')
    {
      item.SetParent(buildingsColumn)
    }else if(itemTable.SecretShopType === 'Summons')
    {
      item.SetParent(summonsColumn)
    }else if(itemTable.SecretShopType === 'Elixirs')
    {
      item.SetParent(elixirColumn)
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

function CreateOrSelectBuildingsColumn( ) {
  let column = secretShopColumnsParent.FindChildTraverse('ShopItems_Buildings');
  if (column === null) {
    column = $.CreatePanel('Panel', $.GetContextPanel(), 'ShopItems_Buildings');
  }
  column.SetHasClass('ShopItemsColumn', true);
  column.SetParent(secretShopColumnsParent);
  return column;
}

function CreateOrSelectSummonsColumn( ) {
  let column = secretShopColumnsParent.FindChildTraverse('ShopItems_Summons');
  if (column === null) {
    column = $.CreatePanel('Panel', $.GetContextPanel(), 'ShopItems_Summons');
  }
  column.SetHasClass('ShopItemsColumn', true);
  column.SetParent(secretShopColumnsParent);
  return column;
}

function CreateOrSelectElixirColumn( ) {
  let column = secretShopColumnsParent.FindChildTraverse('ShopItems_Elixir');
  if (column === null) {
    column = $.CreatePanel('Panel', $.GetContextPanel(), 'ShopItems_Elixir');
  }
  column.SetHasClass('ShopItemsColumn', true);
  column.SetParent(secretShopColumnsParent);
  return column;
}




