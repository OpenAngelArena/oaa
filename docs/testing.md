# Testing Open Angel Arena
This is the continuation of [Install guide](/docs/install.md)
Here is a guide how you can modify and run the OAA

## Preparation
You first need to open `Dota 2 Tools` and load OAA project

## Building a map
For game to run you also need a map,
It is rebuilt by double-clicking `aaa.vmap` in `Asset browser` and then pressing `f9` and secting `Full compile` at top and `Build` at bottom of dialogue.
`It should be done evey time you make changes to the map`

## Running a game
Now when you are set, you can start debugging your game, for this you need to open `dota console` in `Asset Browser`(Button on top or a key `~` [located under `esc` and above `tab`])
Then a command to launch game is:
```
dota_launch_custom_game <mod name> <map name>
dota_launch_custom_game oaa aaa
```
after this dota client will start running a gamemode

## Debugging
To debug a game or any `panorama ui` you can use that `dota console` and commands `pause` and `unpause`
For debugging a `panorama ui`(This new blue-grey design, aka reborn, aka 7.00) you at any time can press `f6` ingame and click on objects to inspect them in panorama debugger, which also features `javascript console`
Ingame cheats, as -gold and -lvlup also work for any testing purposes

## Stop debugging
To exit a game and/or rerun it you can use simple command `disconnect` in `dota console`
