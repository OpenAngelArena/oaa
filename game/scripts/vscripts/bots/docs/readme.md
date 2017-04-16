
# Instructions on making the bots work:

<br>

Note: that this will not work on games that have been uploaded to Valve via Dota Workshop. It will only work on games that are launched from your \addons\ directory via the **"dota\_launch\_custom\_game oaa aaa"** console command.

<br>

When you would start up a game, and use the **"dota\_launch\_custom\_game oaa aaa"** console command, copy and paste this instead:

**dota\_launch\_custom\_game oaa aaa; sv\_cheats 1; dota\_bot\_set\_difficulty 4; dota\_bot\_practice\_difficulty 4; dota\_all\_vision 1;**

The "oaa" is your addons directory name.

Optionally you can control which bots join by adding the following console command:

**dota\_bot\_force\_pick npc\_dota\_hero\_sven,npc\_dota\_hero\_lion,npc\_dota\_hero\_lina,npc\_dota\_hero\_zuus,npc\_dota\_hero\_death\_prophet,npc\_dota\_hero\_jakiro,npc\_dota\_hero\_dragon\_knight,npc\_dota\_hero\_sand\_king,npc\_dota\_hero\_skeleton\_king**

Then once you are in the "Team Select" screen or later you can paste in:

**dota\_bot\_populate**

The second time you want to run the game, in the console you can use the up button on your keyboard and it will bring up commands you've used previously, so you don’t have to keep going back and copying it.

<br>

# Notes:

<br>

You can remove dota\_all\_vision 1 if you don’t want to see your opponents.

dota\_bot\_practice\_difficulty is probably not doing anything, it’s probably using dota\_bot\_set\_difficulty, but I don’t want to risk them being even more dumb.

The bot code is located in the \scripts\vscripts\bots\ folder.

These bots are just for a bit of fun, however sometimes they will make some bad decisions.I wrote them a while back, and they take a lot of tweaking.

They haven't got some things like boss killing implemented.

I’ll probably update them and fix them some, but they’re not the main event here.

Feel free to send me any suggestions/code improvements.

Enjoy.

<br>
