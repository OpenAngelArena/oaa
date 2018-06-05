# Chat commands

Updated 2018-02-14

[< Dota 2 Tools][0]

Commands to be used for debugging and testing purposes, currently requires the game to either be in tools mode or have sv_cheats 1 enabled. To use these, type them into the chat prompt like you would when messaging allies or using normal Dota cheats.
<br>
<br>
-list/-help - Displays a list of all available chat commands.
<br>
-addbots - Adds Bots (not the same bots that RamonNZ added).
<br>
-nofog - Removes fog of war revealing everything.
<br>
-fog - Re-adds fog of war.
<br>
-duel - Forces duel start.
<br>
-end_duel - Ends a duel.
<br>
-god - Toggles invunerability.
<br>
-disarm - Toggles disarm on player.
<br>
-dagger - Gives global blink dagger.
<br>
-dagon - Gives insta-kill dagon.
<br>
-core x - Can be used to give upgrade cores, core 1, core 2, core 3, core 4, -core by itself gives core level 1.
<br>
-addability x - Give abilities. Accepts partial names. -add fury_swipes will give Ursa's fury swipes, it uses the technical name for abilities, so some names may not work -add greevils will not add greevils greed because its tehnical name is goblins greed.
<br>
-give x y - Gives Items. Accepts partial names. Does not give receipes, can be given a third input to specify a number, e.g. -give heart 3 gives a level 3 heart of Tarrasque.
<br>
-fixspawn - This makes all heros teleport back to their fountain, this should be useful when bots or playres have bugged out and have become stuck in a strange part of the map.
<br>
-kill_limit x - Sets the kill limit win condition to the specified number.
<br>
-addpoints x - Adds specified number of points to the user's team. Adds 1 point if no number specified.
<br>
-add_enemy_points x - Adds specified number of points to the enemy team. Adds 1 point if no number specified.
<br>
-switchhero x - Switch hero. Accepts partial names. Uses internal names, so -switchhero obsidian switches to Outworld Devourer, because his internal name is obsidian_destroyer.
<br>
-loadout x - Gives a pre-determined set of items. -loadout tank gives max level Heart, Stoneskin, and Satanic Core. -loadout damage gives max level Daedalus, Desolator, and Moon Shard.
<br>
-scepter x - Gives an Aghanim's Scepter of the specified level. Gives level 1 if no level specified.
<br>
-print_modifiers - Prints names of all modifiers on user's hero to console.
<br>
-tptest - Teleports all heroes to the middle of the map. Used for testing the Duel teleportation code.
<br>
-lazer - Gives the user the HP/Mana drain laser ability that the Fountain uses.
<br>
-spawncamps - Forces neutral creep camps to spawn
<br>
-getpos - Prints the position coordinates of the user's hero in chat.

[0]: README.md
