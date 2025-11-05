Icons in **items** folder and subfolders are for item icons in the inventory.

Icons in **spellicons** folder and subfolders are for spell/ability icons and for the buffs/debuffs that items apply and for other custom modifiers.
Buffs/Debuffs from vanilla items need an icon for every item level (with the same name as the item).
Buffs/Debuffs from custom items usually need 1 icon because you can set the path to the icon in the modifier code with GetTexture.
This also means if the item is a passive, it doesn't need an icon in **spellicons**.
It is desirable for icons in **spellicons** and its subfolders to not have pips/dots in the corner.

Icons for the items in shop (e.g. when you hover over an item in the shop) go into: **content\panorama\images\items\custom**
**content\panorama\layout\custom_game\precache.xml** needs to be edited so the console doesn't give a red error how the icon cannot be found. 
(only 1st lvl of the item needs to be referenced, it is enough for some reason)
