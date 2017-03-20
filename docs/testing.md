# Testing Open Angel Arena
This is the continuation of [Install guide](/docs/install.md)
Here is a guide how you can modify and run the OAA

## Preparation
You first need to open dev tools and load OAA project
Also dont forget `node.js command prompt` from previous guide and ensure it is in `Open Angel Arena` directory

## Building a game
When you have just downloaded the sources you need to build evrything before running
To begin with you need your command prompt, where you should type
```
dota 2 beta\addons\oaa> gulp
```
this part builds npcs and custom scripts.
`You should rerun it every time you want to realunch OAA with new settings/files/localizations`

## Building a map
For game to run you also need a map,
It is rebuilt by double-clicking `aaa.vmap` in `Asset browser` and then pressing `f9` and secting `Full compile` at top and `Build` at bottom of dialogue.
`It should be done evey time you make changes to the map`

## Running a game
Now when you are set, you can start debugging your game, for this you need to open `dota console` in `Asset Browser`(Button on top)
Then a command to launch game is:
```
dota_launch_custom_game (mod name) (map name)
dota_launch_custom_game oaa aaa
```
after this dota client will start running a gamemode

## Debugging
To debug a game or any `panorama ui` you can use that `dota console` and commands `pause` and `unpause`
For debugging a `panorama ui`(This new blue-grey design, aka reborn, aka 7.00) you at any time can press `f6` ingame and click on objects to inspect them in panorama debugger, which also features `javascript console`
Ingame cheats, as -gols and -lvlup also work for any testing purposes

## Stop debugging
To exit a game and/or rerun it you can use simple command `disconnect` in `dota console`
