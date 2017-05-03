/* global Players, $, GameEvents, Game, dynamicSort, GameUI, Entities, PlayerTables,
 GetItemCountInInventory, GetItemCountInCourier, GetPlayerGold, GetPlayerHeroName,
 DotaDefaultUIElement_t, CLICK_BEHAVIORS, DynamicSubscribePTListener */

var ItemList = {};
var ItemData = {};
var Itembuilds = {};
var SmallItems = [];
var SmallItemsAlwaysUpdated = [];
var SearchingFor = null;
var TabIndex = null;
var QuickBuyTarget = null;
var QuickBuyTargetAmount = 0;
var LastHero = null;
var ItemStocks = [];

function OpenCloseShop () {
  $('#ShopBase').ToggleClass('ShopBase_Out');
  if ($('#ShopBase').BHasClass('ShopBase_Out')) {
    Game.EmitSound('Shop.PanelUp');
    UpdateShop();
  } else {
    Game.EmitSound('Shop.PanelDown');
  }
}

function SearchItems () {
  var searchStr = $('#ShopSearchEntry').text.replace(/[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, '\\$&');
  if (SearchingFor !== searchStr) {
    SearchingFor = searchStr;
    var ShopSearchOverlay = $('#ShopSearchOverlay');
    $.Each(ShopSearchOverlay.Children(), function (child) {
      child.DestroyItemPanel();
    });
    $.GetContextPanel().SetHasClass('InSearchMode', searchStr.length > 0);
    if (searchStr.length > 0) {
      var FoundItems = [];
      for (var itemName in ItemData) {
        if (itemName.lastIndexOf('item_recipe_')) {
          for (var key in ItemData[itemName].names) {
            if (ItemData[itemName].names[key].search(new RegExp(searchStr, 'i')) > -1) {
              FoundItems.push({
                itemName: itemName,
                cost: ItemData[itemName].cost
              });
              break;
            }
          }
        }
      }
      FoundItems.sort(dynamicSort('cost'));
      $.Each(FoundItems, function (itemTable) {
        SnippetCreateSmallItem($.CreatePanel('Panel', ShopSearchOverlay, 'ShopSearchOverlay_item_' + itemTable.itemName), itemTable.itemName);
      });
    }
  }
}

function PushItemsToList () {
  var isTabSelected = false;
  for (var shopName in ItemList) {
    var TabButton = $.CreatePanel('RadioButton', $('#ShopTabs'), 'shop_tab_' + shopName);
    TabButton.AddClass('ShopTabButton');
    TabButton.style.width = (100 / Object.keys(ItemList).length) + '%';
    var TabButtonLabel = $.CreatePanel('Label', TabButton, '');
    TabButtonLabel.text = $.Localize('panorama_shop_shop_tab_' + shopName);
    TabButtonLabel.hittest = false;
    var SelectShopTabAction = (function (_shopName) {
      return function () {
        SelectShopTab(_shopName);
      };
    })(shopName);
    TabButton.SetPanelEvent('onactivate', SelectShopTabAction);
    var TabShopItemlistPanel = $.CreatePanel('Panel', $('#ShopItemsBase'), 'shop_panels_tab_' + shopName);
    TabShopItemlistPanel.AddClass('ItemsPageInnerContainer');
    FillShopTable(TabShopItemlistPanel, ItemList[shopName]);

    if (!isTabSelected) {
      SelectShopTab(shopName);
      isTabSelected = true;
    }
  }
}

function SelectShopTab (tabIndex) {
  if (TabIndex !== tabIndex) {
    if (TabIndex !== null) {
      $('#shop_panels_tab_' + TabIndex).RemoveClass('SelectedPage');
      $('#shop_tab_' + TabIndex).RemoveClass('ShopTabButtonSelected');
    }
    $('#shop_panels_tab_' + tabIndex).AddClass('SelectedPage');
    $('#shop_tab_' + tabIndex).AddClass('ShopTabButtonSelected');
    TabIndex = tabIndex;
  }
}

function FillShopTable (panel, shopData) {
  for (var groupName in shopData) {
    var groupPanel = $.CreatePanel('Panel', panel, panel.id + '_group_' + groupName);
    groupPanel.AddClass('ShopItemGroup');
    $.Each(shopData[groupName], function (itemName) {
      var itemPanel = $.CreatePanel('Panel', groupPanel, groupPanel.id + '_item_' + itemName);
      SnippetCreateSmallItem(itemPanel, itemName);
        // groupPanel.AddClass('ShopItemGroup')
    });
  }
}

function SnippetCreateSmallItem (panel, itemName, skipPush) {
  panel.BLoadLayoutSnippet('SmallItem');
  panel.itemName = itemName;
  panel.FindChildTraverse('SmallItemImage').itemname = itemName;
  if (itemName.lastIndexOf('item_recipe', 0) === 0) {
    panel.FindChildTraverse('SmallItemImage').SetImage('raw://resource/flash3/images/items/recipe.png'); // TODO
  }
  panel.SetPanelEvent('onactivate', function () {
    if (!$.GetContextPanel().BHasClass('InSearchMode')) {
      panel.SetFocus();
    }
    if (GameUI.IsAltDown()) {
      GameEvents.SendCustomGameEventToServer('custom_chat_send_message', {
        shop_item_name: panel.IsInQuickbuy ? QuickBuyTarget : itemName,
        isQuickbuy: panel.IsInQuickbuy,
        gold: GetRemainingPrice(panel.IsInQuickbuy ? QuickBuyTarget : itemName, {})
      });
    } else {
      ShowItemRecipe(itemName);
      if (GameUI.IsShiftDown()) {
        SetQuickbuyTarget(itemName);
      }
    }
  });
  panel.SetPanelEvent('oncontextmenu', function () {
    if (panel.BHasClass('CanBuy')) {
      SendItemBuyOrder(itemName);
    } else {
      GameEvents.SendEventClientSide('dota_hud_error_message', {
        'splitscreenplayer': 0,
        'reason': 80,
        'message': '#dota_hud_error_not_enough_gold'
      });
      Game.EmitSound('General.NoGold');
    }
  });
  panel.SetPanelEvent('onmouseover', function () {
    ItemShowTooltip(panel);
  });
  panel.SetPanelEvent('onmouseout', function () {
    ItemHideTooltip(panel);
  });
  panel.DestroyItemPanel = function () {
    var id1 = SmallItemsAlwaysUpdated.indexOf(panel);
    var id2 = SmallItems.indexOf(panel);
    if (id1 > -1) {
      SmallItemsAlwaysUpdated.splice(id1, 1);
    }
    if (id2 > -1) {
      SmallItems.splice(id2, 1);
    }
    panel.visible = false;
    panel.DeleteAsync(0);
  };
  if (!panel.IsInQuickbuy) {
    $.RegisterEventHandler('DragStart', panel, SmallItemOnDragStart);
    $.RegisterEventHandler('DragEnd', panel, SmallItemOnDragEnd);
  }
  UpdateSmallItem(panel);
  if (!skipPush) {
    SmallItems.push(panel);
  }
}

function SmallItemOnDragStart (panelId, dragCallbacks) {
  $.GetContextPanel().AddClass('DropDownMode');
  var panel = $('#' + panelId);
  var itemName = panel.itemName;
  ItemHideTooltip(panel);

  var displayPanel = $.CreatePanel('DOTAItemImage', panel, 'dragImage');
  displayPanel.itemname = itemName;
  if (itemName.lastIndexOf('item_recipe_', 0) === 0) {
    displayPanel.SetImage('raw://resource/flash3/images/items/recipe.png'); // TODO
  }

  dragCallbacks.displayPanel = displayPanel;
  dragCallbacks.offsetX = 0;
  dragCallbacks.offsetY = 0;
  return true;
}

function SmallItemOnDragEnd (panelId, draggedPanel) {
  $.GetContextPanel().RemoveClass('DropDownMode');
  draggedPanel.DeleteAsync(0);
  return true;
}

function ShowItemRecipe (itemName) {
  var currentItemData = ItemData[itemName];
  if (currentItemData == null) {
    return;
  }
  var RecipeData = currentItemData.Recipe;
  var BuildsIntoData = currentItemData.BuildsInto;
  var DropListData = currentItemData.DropListData;
  $.Each($('#ItemRecipeBoxRow1').Children(), function (child) {
    if (child.DestroyItemPanel !== null) {
      child.DestroyItemPanel();
    } else {
      child.DeleteAsync(0);
    }
  });
  $.Each($('#ItemRecipeBoxRow2').Children(), function (child) {
    if (child.DestroyItemPanel !== null) {
      child.DestroyItemPanel();
    } else {
      child.DeleteAsync(0);
    }
  });
  $.Each($('#ItemRecipeBoxRow3').Children(), function (child) {
    if (child.DestroyItemPanel !== null) {
      child.DestroyItemPanel();
    } else {
      child.DeleteAsync(0);
    }
  });

  $('#ItemRecipeBoxRow1').RemoveAndDeleteChildren();
  $('#ItemRecipeBoxRow2').RemoveAndDeleteChildren();
  $('#ItemRecipeBoxRow3').RemoveAndDeleteChildren();

  var itemPanel = $.CreatePanel('Panel', $('#ItemRecipeBoxRow2'), 'ItemRecipeBoxRow2_item_' + itemName);
  SnippetCreateSmallItem(itemPanel, itemName);
  itemPanel.style.align = 'center center';
  var len = 0;
  $('#ItemRecipeBoxDrops').visible = false;
  if (RecipeData !== null && RecipeData.items !== null) {
    $.Each(RecipeData.items[1], function (childName) {
      var itemPanel = $.CreatePanel('Panel', $('#ItemRecipeBoxRow3'), 'ItemRecipeBoxRow3_item_' + childName);
      SnippetCreateSmallItem(itemPanel, childName);
      itemPanel.style.align = 'center center';
    });
    len = Object.keys(RecipeData.items).length;
    if (RecipeData.visible && RecipeData.recipeItemName !== null) {
      len++;
      itemPanel = $.CreatePanel('Panel', $('#ItemRecipeBoxRow3'), 'ItemRecipeBoxRow3_item_' + RecipeData.recipeItemName);
      SnippetCreateSmallItem(itemPanel, RecipeData.recipeItemName);
      itemPanel.style.align = 'center center';
    }
  } else if (DropListData !== null) {
    $('#ItemRecipeBoxDrops').visible = true;
    $.Each($('#ItemRecipeBoxDrops').Children(), function (pan) {
      var unit = pan.id.replace('ItemRecipeBoxDrops_', '');
      pan.enabled = DropListData[unit] !== null;
      pan.RemoveAndDeleteChildren();
      if (DropListData[unit] !== null) {
        $.Each(DropListData[unit], function (chance) {
          var chancePanel = $.CreatePanel('Label', pan, '');
          chancePanel.AddClass('UnitItemlikeRecipePanelChance');
          chancePanel.text = chance + '%';
        });
      }
    });
  }
  $('#ItemRecipeBoxRow3').SetHasClass('ItemRecipeBoxRowLength7', len >= 7);
  $('#ItemRecipeBoxRow3').SetHasClass('ItemRecipeBoxRowLength8', len >= 8);
  $('#ItemRecipeBoxRow3').SetHasClass('ItemRecipeBoxRowLength9', len >= 9);
  if (BuildsIntoData !== null) {
    $.Each(BuildsIntoData, function (childName) {
      var itemPanel = $.CreatePanel('Panel', $('#ItemRecipeBoxRow1'), 'ItemRecipeBoxRow1_item_' + childName);
      SnippetCreateSmallItem(itemPanel, childName);
      itemPanel.style.align = 'center center';
    });
    $('#ItemRecipeBoxRow1').SetHasClass('ItemRecipeBoxRowLength7', Object.keys(BuildsIntoData).length >= 7);
    $('#ItemRecipeBoxRow1').SetHasClass('ItemRecipeBoxRowLength8', Object.keys(BuildsIntoData).length >= 8);
    $('#ItemRecipeBoxRow1').SetHasClass('ItemRecipeBoxRowLength9', Object.keys(BuildsIntoData).length >= 9);
  }
}

function SendItemBuyOrder (itemName) {
  var pid = Game.GetLocalPlayerID();
  var unit = Players.GetLocalPlayerPortraitUnit();
  unit = Entities.IsControllableByPlayer(unit, pid) ? unit : Players.GetPlayerHeroEntityIndex(pid);
  GameEvents.SendCustomGameEventToServer('panorama_shop_item_buy', {
    'itemName': itemName,
    'unit': unit
  });
}

function ItemShowTooltip (panel) {
  $.DispatchEvent('DOTAShowAbilityTooltipForEntityIndex', panel, panel.itemName, Players.GetLocalPlayerPortraitUnit());
}

function ItemHideTooltip (panel) {
  $.DispatchEvent('DOTAHideAbilityTooltip', panel);
}

function LoadItemsFromTable (data) {
  ItemList = data.ShopList;
  ItemData = data.ItemData;
  Itembuilds = data.Itembuilds;
  PushItemsToList();
}

function UpdateSmallItem (panel, gold) {
  try {
    var notpurchasable = !ItemData[panel.itemName].purchasable;
    panel.SetHasClass('CanBuy', GetRemainingPrice(panel.itemName, {}) <= (gold || PlayerTables.GetTableValue('arena', 'gold')[Game.GetLocalPlayerID()]) || notpurchasable);
    panel.SetHasClass('NotPurchasableItem', notpurchasable);
    if (ItemStocks[panel.itemName] !== null) {
      var CurrentTime = Game.GetGameTime();
      var RemainingTime = ItemStocks[panel.itemName].current_cooldown - (CurrentTime - ItemStocks[panel.itemName].current_last_purchased_time);
      var stock = ItemStocks[panel.itemName].current_stock;
      panel.FindChildTraverse('SmallItemStock').text = stock;
      if (stock === 0 && RemainingTime > 0) {
        panel.FindChildTraverse('StockTimer').text = Math.round(RemainingTime);
        panel.FindChildTraverse('StockOverlay').style.width = (RemainingTime / ItemStocks[panel.itemName].current_cooldown * 100) + '%';
      } else {
        panel.FindChildTraverse('StockTimer').text = '';
        panel.FindChildTraverse('StockOverlay').style.width = 0;
      }
    }
  } catch (err) {
    var index = SmallItems.indexOf(panel);
    if (index > -1) {
      SmallItems.splice(index, 1);
    } else {
      index = SmallItemsAlwaysUpdated.indexOf(panel);
      if (index > -1) {
        SmallItemsAlwaysUpdated.splice(index, 1);
      }
    }
  }
}

function GetRemainingPrice (itemName, ItemCounter, baseItem) {
  if (ItemCounter[itemName] === null) {
    ItemCounter[itemName] = 0;
  }
  ItemCounter[itemName] = ItemCounter[itemName] + 1;

  var itemCount = GetItemCountInInventory(Players.GetPlayerHeroEntityIndex(Game.GetLocalPlayerID()), itemName, true);
  var val = 0;
  if (itemCount < ItemCounter[itemName] || !baseItem) {
    if (ItemData[itemName] == null) {
      throw new Error('Unable to find item ' + itemName + '!');
    }
    var RecipeData = ItemData[itemName].Recipe;
    if (RecipeData !== null && RecipeData.items !== null) {
      $.Each(RecipeData.items[1], function (childName) {
        val += GetRemainingPrice(childName, ItemCounter, baseItem || itemName);
      });
      if (RecipeData.visible && RecipeData.recipeItemName !== null) {
        val += GetRemainingPrice(RecipeData.recipeItemName, ItemCounter, baseItem || itemName);
      }
    } else {
      val += ItemData[itemName].cost;
    }
  }
  return val;
}

function SetQuickbuyStickyItem (itemName) {
  $.Each($('#QuickBuyStickyButtonPanel').Children(), function (child) {
    child.DestroyItemPanel();
  });
  var itemPanel = $.CreatePanel('Panel', $('#QuickBuyStickyButtonPanel'), 'QuickBuyStickyButtonPanel_item_' + itemName);
  SnippetCreateSmallItem(itemPanel, itemName, true);
  itemPanel.AddClass('QuickBuyStickyItem');
  SmallItemsAlwaysUpdated.push(itemPanel);
}

function ClearQuickbuyItems () {
  QuickBuyTarget = null;
  QuickBuyTargetAmount = null;
  $.Each($('#QuickBuyPanelItems').Children(), function (child) {
    if (!child.BHasClass('DropDownValidTarget')) {
      child.DestroyItemPanel();
    } else {
      // child.visible = false
    }
  });
}

function RefreshQuickbuyItem (itemName) {
  MakeQuickbuyCheckItem(itemName, {}, {}, QuickBuyTargetAmount);
}

function MakeQuickbuyCheckItem (itemName, ItemCounter, ItemIndexer, sourceExpectedCount) {
  var RecipeData = ItemData[itemName].Recipe;
  if (ItemCounter[itemName] == null) {
    ItemCounter[itemName] = 0;
  }
  if (ItemIndexer[itemName] == null) {
    ItemIndexer[itemName] = 0;
  }
  ItemCounter[itemName] = ItemCounter[itemName] + 1;
  ItemIndexer[itemName] = ItemIndexer[itemName] + 1;
  var itemCount = GetItemCountInCourier(Players.GetPlayerHeroEntityIndex(Game.GetLocalPlayerID()), itemName, true) + GetItemCountInInventory(Players.GetPlayerHeroEntityIndex(Game.GetLocalPlayerID()), itemName, true);
  if ((itemCount < ItemCounter[itemName] || (itemName === QuickBuyTarget && itemCount - (sourceExpectedCount - 1) < ItemCounter[itemName]))) {
    if (RecipeData !== null && RecipeData.items !== null) {
      $.Each(RecipeData.items[1], function (childName) {
        MakeQuickbuyCheckItem(childName, ItemCounter, ItemIndexer);
      });
      if (RecipeData.visible && RecipeData.recipeItemName !== null) {
        MakeQuickbuyCheckItem(RecipeData.recipeItemName, ItemCounter, ItemIndexer);
      }
    } else if ($('#QuickBuyPanelItems').FindChildTraverse('QuickBuyPanelItems_item_' + itemName + '_id_' + ItemIndexer[itemName]) == null) {
      var itemPanel = $.CreatePanel('Panel', $('#QuickBuyPanelItems'), 'QuickBuyPanelItems_item_' + itemName + '_id_' + ItemIndexer[itemName]);
      itemPanel.IsInQuickbuy = true;
      SnippetCreateSmallItem(itemPanel, itemName);
      itemPanel.AddClass('QuickbuyItemPanel');
      SmallItemsAlwaysUpdated.push(itemPanel);
    }
  } else {
    if (itemName === QuickBuyTarget) {
      ClearQuickbuyItems();
    } else {
      RemoveQuickbuyItemChildren(itemName, ItemIndexer, false);
    }
  }
}

function RemoveQuickbuyItemChildren (itemName, ItemIndexer, bIncrease) {
  var RecipeData = ItemData[itemName].Recipe;
  if (bIncrease) {
    ItemIndexer[itemName] = (ItemIndexer[itemName] || 0) + 1;
  }
  RemoveQuckbuyPanel(itemName, ItemIndexer[itemName]);
  if (RecipeData !== null && RecipeData.items !== null) {
    $.Each(RecipeData.items[1], function (childName) {
      RemoveQuickbuyItemChildren(childName, ItemIndexer, true);
    });
    if (RecipeData.visible && RecipeData.recipeItemName !== null) {
      RemoveQuickbuyItemChildren(RecipeData.recipeItemName, ItemIndexer, true);
    }
  }
}

function RemoveQuckbuyPanel (itemName, index) {
  var panel = $('#QuickBuyPanelItems').FindChildTraverse('QuickBuyPanelItems_item_' + itemName + '_id_' + index);
  if (panel !== null) {
    panel.DestroyItemPanel();
  }
}

function SetQuickbuyTarget (itemName) {
  ClearQuickbuyItems();
  Game.EmitSound('Quickbuy.Confirmation');
  QuickBuyTarget = itemName;
  QuickBuyTargetAmount = GetItemCountInCourier(Players.GetPlayerHeroEntityIndex(Game.GetLocalPlayerID()), itemName, true);
  QuickBuyTargetAmount += GetItemCountInInventory(Players.GetPlayerHeroEntityIndex(Game.GetLocalPlayerID()), itemName, true) + 1;
  RefreshQuickbuyItem(itemName);
}

function ShowItemInShop (data) {
  if (data && data.itemName !== null) {
    $('#ShopBase').RemoveClass('ShopBase_Out');
    ShowItemRecipe(String(data.itemName));
  }
}

function UpdateShop () {
  SearchItems();
  UpdateItembuildsForHero();
  var gold = GetPlayerGold(Game.GetLocalPlayerID());
  $.Each(SmallItemsAlwaysUpdated, function (panel) {
    UpdateSmallItem(panel, gold);
  });
  if (!$('#ShopBase').BHasClass('ShopBase_Out')) {
    $.Each(SmallItems, function (panel) {
      UpdateSmallItem(panel, gold);
    });
  // $.GetContextPanel().SetHasClass('InRangeOfShop', Entities.IsInRangeOfShop(m_QueryUnit, 0, true))
  }
}

function AutoUpdateShop () {
  UpdateShop();
  $.Schedule(0.5, AutoUpdateShop);
}

function AutoUpdateQuickbuy () {
  if (QuickBuyTarget !== null) {
    RefreshQuickbuyItem(QuickBuyTarget);
  }
  $.Schedule(0.15, AutoUpdateQuickbuy);
}

function UpdateItembuildsForHero () {
  var heroName = GetPlayerHeroName(Game.GetLocalPlayerID());
  if (LastHero !== heroName) {
    LastHero = heroName;
    var DropRoot = $('#Itembuild_selectBox');
    var content = '';
    var SelectedTable;
    if (Itembuilds[heroName]) {
      $.Each(Itembuilds[heroName], function (build, i) {
        content = content + '<Label text="' + build.title + '" id="Itembuild_select_element_index_' + i + '"/>';
        if (SelectedTable == null) {
          SelectedTable = build;
        }
      });
    }
    DropRoot.BLoadLayoutFromString('<root><Panel><DropDown id="Itembuild_select"> ' + content + '</DropDown></Panel></root>', true, true);
    DropRoot.FindChildTraverse('Itembuild_select').SetPanelEvent('oninputsubmit', function () {
      var index = Number(DropRoot.FindChildTraverse('Itembuild_select').GetSelected().id.replace('Itembuild_select_element_index_', ''));
      if (Itembuilds[heroName] !== null && Itembuilds[heroName][index] !== null) {
        SelectItembuild(Itembuilds[heroName][index]);
      }
    });
    $.GetContextPanel().SetHasClass('ItembuildsHidden', SelectedTable == null);
    SelectItembuild(SelectedTable);
  }
}

function SelectItembuild (t) {
  var groupsRoot = $('#ItembuildPanelsRoot');
  groupsRoot.RemoveAndDeleteChildren();
  if (t !== null) {
    $('#Itembuild_author').text = t.author || '?';
    $('#Itembuild_patch').text = t.patch || '?';
    $.Each(t.items, function (groupData) {
      var groupRoot = $.CreatePanel('Panel', groupsRoot, '');
      groupRoot.AddClass('ItembuildItemGroup');
      var groupTitle = $.CreatePanel('Label', groupRoot, '');
      groupTitle.AddClass('ItembuildItemGroupTitle');
      groupTitle.text = $.Localize(groupData.title);
      var itemsRoot = $.CreatePanel('Panel', groupRoot, '');
      itemsRoot.AddClass('ItembuildItemGroupItemRoot');

      $.Each(groupData.content, function (itemName) {
        var itemPanel = $.CreatePanel('Panel', itemsRoot, 'shop_itembuild_items_' + itemName);
        SnippetCreateSmallItem(itemPanel, itemName);
      });
    });
  } else {
    $('#Itembuild_author').text = '';
    $('#Itembuild_patch').text = '';
  }
}

function SetItemStock (item, ItemStock) {
  ItemStocks[item] = ItemStock;
}

(function () {
  GameUI.SetDefaultUIEnabled(DotaDefaultUIElement_t.DOTA_DEFAULT_UI_INVENTORY_SHOP, true);
  GameUI.SetDefaultUIEnabled(DotaDefaultUIElement_t.DOTA_DEFAULT_UI_SHOP_SUGGESTEDITEMS, true);
  GameUI.SetDefaultUIEnabled(DotaDefaultUIElement_t.DOTA_DEFAULT_UI_INVENTORY_QUICKBUY, true);
  Game.Events.F4Pressed.push(OpenCloseShop);
  GameEvents.Subscribe('panorama_shop_open_close', OpenCloseShop);
  Game.Events.F5Pressed.push(function () {
    var bought = false;
    $.Each($('#QuickBuyPanelItems').Children(), function (child) {
      if (!child.BHasClass('DropDownValidTarget')) {
        UpdateSmallItem(child);
        if (child.BHasClass('CanBuy')) {
          SendItemBuyOrder(child.itemName);
          bought = true;
          return false;
        }
      }
    });
    if (!bought) {
      GameEvents.SendEventClientSide('dota_hud_error_message', {
        'splitscreenplayer': 0,
        'reason': 80,
        'message': '#dota_hud_error_not_enough_gold'
      });
      Game.EmitSound('General.NoGold');
    }
  });
  Game.Events.F8Pressed.push(function () {
    SendItemBuyOrder($('#QuickBuyStickyButtonPanel').GetChild(0).itemName);
  });
  Game.MouseEvents.OnLeftPressed.push(function (ClickBehaviors, eventName, arg) {
    if (ClickBehaviors === CLICK_BEHAVIORS.DOTA_CLICK_BEHAVIOR_NONE) {
      $('#ShopBase').AddClass('ShopBase_Out');
    }
  });

  GameEvents.Subscribe('panorama_shop_show_item', ShowItemInShop);
  GameEvents.Subscribe('dota_link_clicked', function (data) {
    if (data !== null && data.link !== null && data.link.lastIndexOf('dota.item.', 0) === 0) {
      $('#ShopBase').RemoveClass('ShopBase_Out');
      ShowItemRecipe(data.link.replace('dota.item.', ''));
    }
  });
  GameEvents.Subscribe('panorama_shop_show_item_if_open', function (data) {
    if (!$('#ShopBase').BHasClass('ShopBase_Out')) {
      ShowItemInShop(data);
    }
  });
  DynamicSubscribePTListener('panorama_shop_data', function (tableName, changesObject, deletionsObject) {
    if (changesObject.ShopList !== null) {
      LoadItemsFromTable(changesObject);
      SetQuickbuyStickyItem('item_shard_level');
    }
    var stocksChanges = changesObject['ItemStocks_team' + Players.GetTeam(Game.GetLocalPlayerID())];
    if (stocksChanges !== null) {
      for (var item in stocksChanges) {
        var ItemStock = stocksChanges[item];
        SetItemStock(item, ItemStock);
      }
    }
  });

  GameEvents.Subscribe('arena_team_changed_update', function () {
    var stockdata = PlayerTables.GetTableValue('panorama_shop_data', 'ItemStocks_team' + Players.GetTeam(Game.GetLocalPlayerID()));
    for (var item in stockdata) {
      var ItemStock = stockdata[item];
      SetItemStock(item, ItemStock);
    }
  });

  AutoUpdateShop();
  AutoUpdateQuickbuy();

  $.RegisterEventHandler('DragDrop', $('#QuickBuyStickyButtonPanel'), function (panelId, draggedPanel) {
    if (draggedPanel.itemname !== null) {
      SetQuickbuyStickyItem(draggedPanel.itemname);
    }
    draggedPanel.DeleteAsync(0);
  });

  $.RegisterEventHandler('DragDrop', $('#QuickBuyPanelItems'), function (panelId, draggedPanel) {
    if (draggedPanel.itemname !== null) {
      SetQuickbuyTarget(draggedPanel.itemname);
    }
    draggedPanel.DeleteAsync(0);
  });
})();
