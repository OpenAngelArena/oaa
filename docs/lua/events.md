# Custom Events

Updated 2017-12-05

[< Lua][0]

## Intro

This is a list of events we have added to the game. All events **must** pass objects or else dota crashes lol thanks volvo. List the keys the object expects.

## Server to Client

### ngp_add_item
Display the Need/Greed/Padd UI for a given item.

**id**  
Type: `string` or `number`  
Unique ID for this item instance

**item**  
Type: `string`  
The npc name of the item.

**title**  
Type: `string`  
The pre-translated name of the item to display.

**description**  
Type: `string`  
Short description of item purpose to display.

**buildsInto**  
Type: `string[]`  
Array of string names of items to show in the hint box.

### ngp_expire_item
Remove a given Need/Greed/Pass UI instance for a player's screen. Used when the choice expires and the item is no longer available.

**id**  
Type: `string` or `number`
Unique ID for the item instance to dismiss

## Client to Server

### gamelength_vote
Vote on the length of the game.

**vote**  
Type: `string`  
Either "**short**" "**normal**" or "**long**"

### ngp_selection
Sent when a player has made their selection for a given Need/Greed/Pass instance.

### surrender_result
Sent when a player has made their selection for a given surrender instance.

**id**  
Type: `string` or `number`  
Unique ID for this item instance

**option**  
Type: `string`
Either `need`, `greed`, or `pass` depending on which button the player pressed.

[0]: README.md
