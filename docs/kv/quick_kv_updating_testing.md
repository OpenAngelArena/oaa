# Quick KV Updating/Testing

Updated 2017-12-05

[< KV][0]

## Setting up the Game
1. Ensure you have the proper Clone of oaa. Check that you have the following:
  - '\oaa\game\scripts\npc\npc_abilities_override.txt' - containing ~500 abilities in ~29,000 lines of data.
  - '\oaa\game\scripts\npc\npc_items_custom.txt' - containing ~270 items in ~27,000 lines of data.
  - '\oaa\game\resource\addon_english.txt' - containing a bunch of tooltips.
  - '\oaa\game\scripts\npc\items\files' - the ~270 individual items KV files.
  - '\oaa\game\scripts\npc\abilities\files' - the ~500 individual abilities KV files.
2. If you do not have the proper Clone, you'll have to Git one :D. 
3. Ensure Launch Options: Dota 2 > Properties > Set Launch Options > '-console'

## Playing the Game
1. Play Dota 2
2. Press console shortcut key
3. Type 'dota_launch_custom_game oaa oaa'
4. Press console shortcut key again to close.
5. Play and identify broke shit.
6. Disconnect from lobby when done. You don't need to close Dota 2
7. Make your KeyValue changes, compile using 'gulp'
8. Copy-paste the npc text into 'http://arhowk.github.io' to check for syntax errors if necessary.
9. Hop back into Dota 2.
8. Repeat 2-9 as necessary.

## Changing KeyValues
As you identify things that need changing about the items/abilities, you will modify the **individual files** contained in these directories:

- Hero Abilities - '\oaa\game\scripts\npc\abilities'
- Items - '\oaa\game\scripts\npc\items'

### Hero Abilities
These are fairly straight forward. One ability = one file. This makes them very easy to edit. 

### Items
These are a much bigger pain in the ass. One item's data spans across multiple files because many of the items are considered 'upgrades'. For instance, if you wanted to make Dagon Level 6 do more damage, you'd have to edit this damage value across 9 files because Dagon Level 6 data is contained in all 9 Dagon items (This also makes typos 9x more likely.)

## Compiling NPC Files -> One File
Editing the individual files is a necessary step in the workflow, however it won't effect the game until you compile this data into the files the game uses which are:

- npc_abilities_override.txt
- npc_items_custom.txt

You can compile these by running an automated script. Open Node.js command prompt which was included during installation according to 'oREADME.md'. Ensure the command 'npm i' (the install routine for gulp) has been run atleast once. To compile, simply type 'gulp' into Node.js command prompt compiles the various files.

IMPORTANT: At the moment I'm writing this the Node.js script does not properly compile. It will cause the abilities to be compiled into npc_abilities_custom.txt which is not correct. Chris or someone in coding needs to make sure Node.js (or whatever script they decide to use) works properly by the time you do your Test Stream.

[0]: README.md
