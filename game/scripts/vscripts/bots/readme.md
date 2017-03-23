<br>

**#Instructions on making the bots work:**

<br>

When you start up a game, and use the "dota\_launch\_custom\_game aaa aaa" console command, copy and paste this instead:

**dota\_launch\_custom\_game aaa aaa; sv\_cheats 1; dota\_bot\_set\_difficulty 4; dota\_bot\_practice\_difficulty 4; dota\_all\_vision 1;**

(remove dota\_all\_vision 1 if you don’t want to see your opponents)

Then once the game starts and either in the "Team Select" screen or the "Choose Your Hero" screen, paste in:

**dota\_bot\_populate**

The second time you want to run the game, in the console you can use the up button on your keyboard and it will bring up commands you've used previously, so you don’t have to keep going back and copying it.

dota\_bot\_practice\_difficulty is probably not doing anything, it’s probably using dota\_bot\_set\_difficulty, but I don’t want to risk them being even more dumb.

<br>

<br>

**#Option #2:**

<br>

There is the other option if you don't want to use the console every time…

You can edit this file:
**\scripts\vscripts\gamemode.lua**

<br>
And under:

**BAREBONES\_VERSION = "1.00"**

Add this line:

**local bPopulated = false;  //add this**

<br>
Also inside of the function:

function GameMode:InitGameMode()

under:

  **DebugPrint('[BAREBONES] Done loading Barebones gamemode!\n\n')**

Add this line:

  **GameRules:GetGameModeEntity():SetThink( "OnThink2", self, "GlobalThink", 2 )  //add this**

<br>
Then add in this function at the bottom somewhere:

**function GameMode:OnThink2()**

**if (bPopulated == false) then**

**SendToServerConsole( "sv\_cheats 1" )**

**SendToServerConsole( "dota\_bot\_set\_difficulty 4" )**

**SendToServerConsole( "dota\_bot\_practice\_difficulty 4" )**

-- **SendToServerConsole( "dota\_bot\_force\_pick npc\_dota\_hero\_sven,npc\_dota\_hero\_death\_prophet,npc\_dota\_hero\_dragon\_knight,npc\_dota\_hero\_zuus,npc\_dota\_hero\_lina,npc\_dota\_hero\_warlock,npc\_dota\_hero\_tidehunter,npc\_dota\_hero\_axe,npc\_dota\_hero\_bristleback" )**  -- if you want to choose the bots

**SendToServerConsole( "dota\_all\_vision 1" )**	--get vision of enemy bots 

**SendToServerConsole( "dota\_bot\_populate" )**

**-- SendToServerConsole( "dota\_give\_gold 9999999" )** –if you want money

**-- SendToServerConsole( "cl\_showpos 1" )**	--slow the location on the screen	

**bPopulated = true**

**end**

**end**


Don't forget to backup your edited gamemode.lua, or it might get overwritten.

<br>

<br>

**#Notes:**

<br>

The bots will be located in the \scripts\vscripts\bots\ folder.

These bots are just for a bit of fun, and they will do some very dumb things. 

I wrote them about 2-3 weeks ago, so they haven’t got duelling or boss killing properly implemented.

I’ll probably update them and fix them some, but they’re not the main event here.

Feel free to send me any suggestions/code improvements.

Enjoy

<br>

<br>
