# OAA Changelog
Changelog starts at `2017-03-24 16:40 UTC+0100`

## Translation Progress
| Language   | Progress |
| :------------- | :--- |
| Chinese        | 0%   |
| Czech          | 5%   |
| German         | 77%  |
| Hungarian      | 0%   |
| *Polish*       | 0%   |
| Portuguese     | 98%  |
| Russian        | 91%  |
| Spanish        | 4%   |
| *Turkish*      | 0%   |

*Italic*  means 'no translator'

## Changes before 0.0.1
* Added new Map
* Added Level 5 and 6 for normal Abilities and Level 4 and 5 for Ultimates to all Heroes
* Added new Items
* Added Upgrades to Items
* Added Upgrade Cores
* Added Bossed
* Added Creep Drops
* Added Boss Drops
* Added a Need-Greed-Pass System
* Added Bottles
* Added a Duel System
* Added Level Requirements for Abilities


## Update 0.0.1 2017-03-24 
[`07a33e56577acdf503c608b4a5a966b5e4d3a403`](https://github.com/OpenAngelArena/oaa/releases/tag/v0.0.1)
### Items
* Buff Travel Boots
  * Increased GPM from `60 90 120 150 180` to `60 120 240 480 960`


## Update 0.1.0 2017-03-27
[`b1ea9ff41c15c80b8ec50186aca7d4fa0e91a890`]](https://github.com/OpenAngelArena/oaa/releases/tag/v0.1.0)
### Items
* Buffed Echo Sabre 
  * Decreased Cooldown from `5.0 5.0 5.0 5.0` to `5.0 4.0 3.0 2.0`
* Added Reverse Compatibility of Upgrade Cores to Reflex Cores
* Changed Stoneskin Armour
  * Added 1.5 second delay to Toggle
  * Fixed Toggle not respecting Cooldown
* Added Dispel Orb
* Removed Combiner Core from all Recipes and replaced them with Upgrade Cores
* Nerfed Octarine Core
  * Nerfed Cooldown from `25 35` to `25 30`
* Nerfed Refresher Core
  * Nerfed Cooldown from `40 50 60` to `35 40 45`
* Fixed Stoneskin Armour Level 1 and 2 not sharing Cooldown
* Buffed Greater Travel Boots
  * Decreased Channel Time from `3.0` to `3.0 2.75 2.5 2.25 2`
  * Increased Movementspeed from `100 100 100 100 100` to `100 125 150 175 200`
  * Increased GPM from `60 120 240 480 960` to `150 300 600 1200 2400`
* Added Pullstaff Item aka 'Reverse Force Staff'
* Nerfed Greater Power Treads
  * Decreased Split Damage from `40` to `10 20 30 40 50`
* Buffed Abyssal Blade
  * Increased Melee Damage Block from `70 75 80 85 90` to `70 100 140 200 280`
  * Increased Ranged Damage Block from `35 40 45 50 55` to `35 50 70 100 140`
* Buffed Assault Cuirass
  * Increased Armour Aura from `5 7 9` to `5 10 20`
* Buffed Battle Fury
  * Increased Cleave Damage fron `35` to `35 45 55 65 75`
* Buffed Bloodstone
  * Increased Health from `475 675 900 1300 1600` to `475 1000 1800 2600 3200`
  * Increased Mana from `425 600 800 1200 1500` to `425 900 1600 2400 3000`
  * Increased Health Regeneration from `9 12 15 18 21` to `9 25 45 65 90`
  * Increased Mana Regeneration from `200 250 300 350 400` to `200 350 500 750 1000`
  * Increased Death Base Area Heal from `500 600 700 800 900` to `500 1000 1500 2000 2500`
  * Increased Death Bonus Area Heal per Charge from `30 40 50 60 70` to `30 60 120 240 480`
* Buffed Ethereal Blade
  * Increased Bonus Damage from `40` to `40 50 60 70 80`
* Buffed Hand of Midas
  * Increased XP Multiplier from `2.5 2.7 3.0` to `2.5 3.5 4.5`
  * Increased Bonus Gold from `190 230 275` to `190 380 760`
* Buffed Heavens Halberd
  * Increased Strength from `20 30 45` to `20 40 80`
  * Increased Lesser Maim Attack Speed Slow (Melee) from `20 30 40` to `20 40 60`
  * Increased Lesser Maim Attack Speed Slow (Ranged) from `10 15 20` to `10 20 30`
* Buffed Radiance
  * Increased Aura Damage from `50 75 110 170 225` to `50 100 200 350 550`
* Buffed Rod of Atos
  * Increased Bonus Health from `350 525 800` to `350 700 1400`
* Buffed Shivas Guard
  * Increased Bonus Armour from `15 30 45` to `15 40 70`
  * Decreased Aura Attack Speed from `-45 -50 -55` to `-45 -70 -110`
  * Increased Attack Damage from `200 300 450` to `200 400 600`

### Heroes
* Fixed Zeus Nimbus Cloud attacking too fast
* Fixed Talents for Additional Treants and Eidolons
* Tweaked Spawn Location of Beastmasters Hawk
* Changed Nature's Prophet
  * Nature's Call
    * Only spawning one Treant Type now
  * Teleportation
    * Decreased CastPoint from `3 3 3 3` to `3 3 3 3 3 1.5
* Nerfed Bloodseeker
  * Bloodbath
    * Decreased Duration from `3 4 5 6 8 10` to `3 4 5 6 7 8`
    * Decreased Damage from `120 160 200 240 400 1000` to `120 160 200 240 400 800`
* Nerfed Centaur
  * Stampede
    * Decreased Damage per Strength from `1.0 2.0 3.0 5.0 8.0` to `1.0 2.0 3.0 4.5 6.5`
* Nerfed Shadow Fiend
  * Necromastery
    * Decreased Damage per Soul from `2 2 2 2 3 5` to `2 2 2 2 2 2`
  * Requiem of Souls
    * Decreased Damage from `80 120 160 320 1000` to `80 120 160 320 640`
* Fixed Invoker Leveling Pattern
  * Invoker now gets an Ability Point for every Level
  * Invoker now can actually level his Abilities when he should
* Fixed Tusk
  * Frozen Sigil
    * Added Units for Level 5 and 6
* Fixed Naga Siren
  * Mirror Image
    * Added Level 5 and 6
* Nerfed Antimage
  * Mana Break
    * Decreased Mana per Hit from `28 40 52 64 88 184` to `28 40 52 64 78 96`
  * Mana Void
    * Decreased Damage per missing Mana from `0.6 0.85 1.1 1.6 3.6` to `0.6 0.85 1.1 1.4 1.9`
* Buffed Bristleback
  * Quill Spray
    * Increased Damage from `550.0` to `550.0 550.0 550.0 550.0 1100.0 2200.0`
* Nerfed Dragon Knight
  * Dragon Tail
    * Decreased Damage from `25 50 75 100 150 350` to `25 50 75 100 150 225`
* Nerfed Phantom Assasin
  * Coup de Grace
    * Decreased Crit Damage from `230 340 450 650 1000` to `230 340 450 560 750`
* Nerfed Phantom Lancer
  * Juxtapose
    * Decreased Max Illusions from `5 7 9 13 22` to `5 7 9 11 15`
* Buffed Ursa
  * Enrage
    * Decreased Scepter Cooldown from `30 24 18 18 18` to `30 24 18 15 12`

### Bosses
* Added Reflex Cores as guaranteed Drop of Tier 1 Bosses
* Nerfed Tier 2 Boss
  * Decreased Damage from `3750` to `255`
  * Decreased Health from `100000` to `75000`
* Buffed all 6 Tiers of Bosses
  * Added Magical Resistance of `15 20 25 30 35 40`

### Duels
* Fixed Item Cooldown not saved in Duels

### UI
* Fixed Level Dots not showing for Level 5 and 6 Abilities
* Added Icons to Stoneskin Armour, Dashstaff, Demon Blood and Metal Armour
* Added Minimap with Trees

### Misc
* Changed Strategy and Showcase time to `0`
* Decreased Respawn Time when killed by Creeps from `25` to `10`


## Hotfix 0.1.1 2017-03-27
[`d664aa3b85f464b04ae5fe32a9b9c65fa645c6d9`]](https://github.com/OpenAngelArena/oaa/releases/tag/v0.1.1)
### Items
* Fixed Greater Travel Boots not working


## Update 0.2.0 2017-03-27
[`ac9347374cde1186dc45dc9f282f8de5f7be84a7`]](https://github.com/OpenAngelArena/oaa/releases/tag/v0.2.0)
### Items
* Added Matyr's Mail
* Fixed Charge BKB Recipe
* Added Divine Reduction Orb

### Creeps
* Decreased XP for all Camps
  * Decreased Easy Camp XP from `25` to `20`
  * Decreased Medium Camp XP from `35` to `25`
  * Decreased Hard Camp XP from `40` to `30`


## Update 0.3.0 2017-04-03
[`67397b7a2a648bdafecf645ebb9b6193183eb970`]](https://github.com/OpenAngelArena/oaa/releases/tag/v0.3.0)
### Creeps
* Changed Creep XP
  * XP now also depends on Player Count

### Items
* Added Shroud of Shadows 
  * Make self/ally invisible + Not attackable
* Fixed Damage Reduction Tooltip of Preemptive Reflex Item
* Added Enrage Crystal
* Fixed Shroud Level 2 Targeting
* Fixed Phase Boots Level 1 Recipe
* Fixed Tranquil Boots Level 1 Recipe
* Added Shivas Cuirass Level 1 and 2
  * A Mix between Shivas Guard and Assault Cuirass
* Balanced Charge BKB
  * Increased Base Cooldown from `10` to `20`
  * Increased Max Charges from `17` to `99`
  * Decreased Immunity per Instances from `2` to `1`

### Heroes
* Fixed Talents
* Buffed Juggernaut
  * Buffed Omni Slash
    * Decreased Time per Bounce from `0.4` to `0.4 0.4 0.4 0.4 0.3 0.1`
* Balanced Templare Assassin
  * Balanced Refraction
    * Decreased Instances from `3 4 5 6 8 12` to `3 4 5 6 7 8`
    * Increased Damage from `20 40 60 80 120 280` to `20 40 60 80 160 480`

### Bosses
* Nerfed Tier 1 Boss
  * Decreased Damage from `1000` to `500-600`

### Bots
* default AI now takes Hero vs Hero fighting over
* Bots knows when they're in a duel and fight almost to the death
* Farming is more efficient
* A thousand little Tweaks and Bug fixes

### Misc
* Added Automatic Courier Spawning before Game Start


## Hotfix 0.3.1 2017-04-04
[`f40d9fe53d4b75903f68eece7a4a85d6e7e00c63`]](https://github.com/OpenAngelArena/oaa/releases/tag/v0.3.1)
### Duels
* Fixed Major Bug in Duels


## Update 0.4.0 2017-04-04
[`d064f0f294f395eb84f0e759fe4a6e178ac7078e`]](https://github.com/OpenAngelArena/oaa/releases/tag/v0.4.0)
### Items
* Nerfed Assault Cuirass
  * Decreased Bonus Armour from `10 20 40` to `0 15 20`
  * Decreased Aura Armour Buff from `5 10 20` to `5 6 7`
  * Decreased Aura Armour Debuff from `-5 -7 -9` to `-5 -6 -7`
* Buffed Lotus Orb
  * Increased Damage from `10 15` to `10 20`
  * Increased Armour from `10 15` to `10 20`
  * Decreased Duration from `6 8` to `6`
  * Increased Cast Range from `900` to `900 1200`
* Buffed Lotus Sphere
  * Increased Damage from `20 25` to `30 40`
  * Increased Armour from `18 20` to `20 25`
  * Increased Health Regeneration from `10 12` to `15 21`
  * Decreased Duration from `9 10` to `6 7`
  * Increased Range from `900` to `1200 1200`
  * Increased All Stats from `23 24` to `30 40`
  * Increased Mana Regeneration from `150 225` to `300 375`
  * Decreased Block Cooldown from `13.0` to `9.0 7.0`
* Nerfed Shivas Guard
  * Decreased Bonus Armour from `15 40 70` to `15 20 25`
  * Decreased Attack Speed from `-45 -70 -110` to `-45 -65 -85`
  * Decreased Blast Damage from `200 400 600` to `200 300 450`
* Buffed Linkes Sphere
  * Decreased Block Cooldown from `13.0` to `13.0 11.0`

### Heroes
* Nerfed Zeus
  * Nerfed Lightning Bolt
    * Decreased Damage from `100 175 275 350 515 1180` to `100 175 275 350 515 980`
    * Increased Mana Cost from `75 95 115 135 175 335` to `75 95 115 135 275 500`
  * Nerfed Static Field
    * Decreased Cast Range from `1200 1200 1200 1200 1400 1600` to `1200`
    * Decreased Radius from `1200 1200 1200 1200 1400 1600` to `1200 1200 1200 1200 1300 1500`
    * Decreased Percentage Damage from `4 6 8 10 11 12` to `4 6 8 10 10 10`
  * Nerfed Tundergods Wrath
    * Decreased Damage from `225 325 425 625 1425` to `225 325 425 625 1025`

### Bosses
* Buffed All Bosses
  * Added Percentage-Based-Damage-Reduction of 90%
  * Set Armour to `25`
  * Set Magical Resistance to `25`
* Nerfed Tier 1
  * Decreased Damage from `1000` to `500-600`


## Hotfix 0.4.1 2017-04-04
[`c5240f33c3f78e8b7760efc2bf0d12e9a0eb0f73`]](https://github.com/OpenAngelArena/oaa/releases/tag/v0.4.1)
### Duels
* Made Duels generally more stable

## Hotfix 0.4.2 2017-04-04
[`d4c5cbcd2948072592be1db4c90ae36c8ebf1d4a`]](https://github.com/OpenAngelArena/oaa/releases/tag/v0.4.2)
### Items
* Custom Bottle is now known as Infinity Bottle
* Changed Infinity Bottle
  * Remove Infinity Bottle when reaching zero Charges


## Update 0.5.0
[`622d721b54da759ae3d1cb5aaf668ef0fc5b9036`]](https://github.com/OpenAngelArena/oaa/releases/tag/v0.5.0)
* Updated Translations

### Items
* Added Icons to Items ([images](https://github.com/OpenAngelArena/oaa/pull/390))
  * Added Icons to Radiance Level 2 to 5
* Buffed All Level 1 Farming Boots
  * Changed Gold Cost to `100`
* Nerfed Charge BKB
  * Every Charge increases Cooldown by `5`
* Changed Enrage Crystal
  * Now works better
* Balanced Refresher Core
  * Decreased Cooldown from `195.0` to `150.0 105.0 60.0`
  * Decreased Bonus Cooldown from `35 40 45` to `27 30 33`
  * Decreased Hero Lifesteal from `40` to `25`
  * Decreased Creep Lifesteal from `10` to `5`
* Buffed Reduction Orb
  * Added `250` Health
  * Added `5` Armour
  * Added `5` Magical Resistance
* Buffed Dispel Orb and Greater Reduction Orb
  * Changed Recipe to need a Upgrade Core Level 2 or higher
  * Added `1000` Health
  * Added `10` Armour
  * Added `10` Magical Resistance
* Buffed Divine Dispel Orb and Divine Reduction Orb
  * Changed Recipe to need a Upgrade Core Level 4 or higher
  * Added `4000` Health
  * Added `20` Armour
  * Added `20` Magical Resistance
* Added missing Tooltip to Infinity Bottle
* Changed Greater Power Treads
  * Changed Scatter Shot to Splash
    * This means Effects like Crits apply to Enemies
    * Also added fany particles
* Added Audio-Visual Effects to Enrage Crystal
* Fixed Cast Glow of Lotus Orb Level 2 and higher
* Added Greater Phase Boots
  * Active now additionaly attacks all Creeps the user collides with

### Heroes
* Added Sound to Abaddon's Aphotic Shield 

### UI
* Updated the Loading Screen

### Misc
* Decreased ~Increased~ Loading Times


## Update 0.5.1
[`587e82d5460e1dd2a13b5bf343c15a7b46dc0dca`]](https://github.com/OpenAngelArena/oaa/releases/tag/v0.5.1)
* Updated Tooltips
* Updated Translations


## Hotfix 0.5.2
[`4e162af2dab16a81759330dcedcca1a21280641c`]](https://github.com/OpenAngelArena/oaa/releases/tag/v0.5.2)
### Heroes
* Nerfed Luna
  * Nerfed Eclipse
    * Decreased Duration from `1.6 1.9 2.2 2.5 3.0 4.0` to `1.6 1.9 2.2 2.5 2.8 3.1`


## Update 0.6.0
[`22ed9cc2d9f6cd11589b967be9c7dcdd24914234`]](https://github.com/OpenAngelArena/oaa/releases/tag/v0.5.3)
### Heroes
* Updated Talents of all Heroes

### Items
* Better Tooltips
* Added Icon to Shivas Cuirass
* Added Icon to Reflex Orbs
* Added Icon to Reflex Shards

### Bosses
* Added Charger Boss as Tier 4 Boss replacing the Placeholder Boss
  * 3 Phases
  * Hates Pillars

### Duels
* Fixed Problems with Teleportation

### UI
* Fixed Bug where blacklisted Items could be sold via Drag'n'Drop
* Made Error Message when trying to sell blacklisted Items better
* Added Custom Items to Shop

### Bots
* Fixed Bots trying to sell blacklisted Items


## Update 0.6.1
[`5fa599290f06e0b0be07c514d5b4fbe668354dc7`]](https://github.com/OpenAngelArena/oaa/releases/tag/v0.6.1)
* Updated Translations

### Items
* Added Stats to Reflex Orbs


## Update 0.7.0 Public Testing #1
[`fe37f7c42eccb83ac42aad89d7284d5254eea9c7`]](https://github.com/OpenAngelArena/oaa/releases/tag/v0.7.0)
### Items
* Nerfed Abyssal Blade
  * Increased Health from `250 500 1000 2000 4000` to `250 500 750 1250 2000`
  * Decreased Melee Damage Block from `70 100 140 200 280` to `70 100 130 160 190`
* Fixed Shivas Guard Level 2 needing Upgrade Core Level 3 or higher to build
  * Now needs Upgrade Core Level 1 or higher
* Added Infinity Bottle to Selling Blacklist
* Changed Trumps Fists
  * Disabled Frostbite Debuff
  * Disabled Corruption
* Changed Charge BKB
  * Recipe now costs `60`
* Changed Dragon Lancer
  * Removed Recipe
* Fixed Reflex Item Stats

### Heroes
* Nerfed Storm Spirit
  * Decreased Damage from `8 12 16 24 56` to `8 12 16 20 24`

### Bosses
* Buffed Charger
  * Increased Magical Resistance Debuff from `-180` to `-280`
  * Decreased Armour Debuff from `-240` to `-225`
  * Increased Pillar Damage from `800 1000 1200` to `8000 10000 12000`

### Misc
* Made Sell Blacklist wörk better


## Hotfix 0.7.1 Public Testing #1
[`1eb5f9d1b6c9320fd155fd4c35cb5eed941d975d`]](https://github.com/OpenAngelArena/oaa/releases/tag/v0.7.1)
### Creeps
* After Minute `60` Experience per Creep get multiplied with `1.5 ^ (minute - 60)`
### Items
* Fixed Trumps Fists
  * Decreased Zombification of People


## Update 0.7.2 Public Testing #1
[`f904de21df2699943df5b1079a750f36f6fb62e4`]](https://github.com/OpenAngelArena/oaa/releases/tag/v0.7.2)
### Items
* Added Icons to Trumps Fists


## Update 0.7.3
[`1d6919a30aac21c47720fb68c1b7e87c5166f671`]](https://github.com/OpenAngelArena/oaa/releases/tag/v0.7.3)
### Items
* Added Items to Shroud of Shadows
* Changed Trumps Fists
  * Fix Trump's Fists heal reduction disabling passive health regen

### Creeps
* Adapting a Bottle Only Creep Drop Policy
  * Creeps now only drop Bottles :bottle:


## Update 0.8.0
[`6d6205dce3d7d45776199d0d1d11b71cc14a88e3`]](https://github.com/OpenAngelArena/oaa/releases/tag/v0.8.0)
### Items
* Fixed Divine Dispel Orb Recipe
* Fixed Divine Reduction Orb Recipe
* Added Satanic Core - Octarine with Satanic


## Update 0.9.0
[`be69ee79cec319513320d915f90241e18bcfff13`]](https://github.com/OpenAngelArena/oaa/releases/tag/v0.9.0)
### Creeps
* Fixed 61 Minute Bug where Creep Power get scaled wrong at Minute 61

### Items
* Added Icon to Satanic Core

### Heroes
* Fixed Illusion Stats

### Duels
* Fixed Permadeath when a Player Disconnects and reconnects after the duel #522
* Now cleaning Duel Arenas of crap


## Update 0.9.1
[`da53ac0b4db318b8d0ca8896c36ae8585cbdfd5a`]](https://github.com/OpenAngelArena/oaa/releases/tag/v0.9.1)
### Items
* Nerfed Deadalus
  * Decreased Crit Multiplier from `240 300 350 400 450` to `240 260 280 300 320`
* Nerfed Octarine Core
  * Decreased Bonus Cooldown from `25 30` to `25 25`
  * Decreased Creep Lifesteal from `5 7` to `5 10`
  * Decreased Hero Lifesteal from `25 35` to `25 30`
* Nerfed Refresher Core
  * Increased Hero Lifesteal from `25` to `30`
  * Increased Creep Lifesteal from `5` to `10`
* Buffed Satanic Core
  * Fixed Unholy Spellsteal not working
  * Increased Strength from `32 33 34` to `38 55 75`
  * Decreased Bonus Cooldown from `35 40 45` to `25 25 25`
* Nerfed Dark Seer
  * Ion Shell now only targets Heros - not Creeps


## Map Update 0.10.0
[`a5691afc1d671f04f0d6edcba7ab32bb0b14477c`]](https://github.com/OpenAngelArena/oaa/releases/tag/v0.10.0)
* Updated Translation

### Map
* Moved Boss Arena Entrance closer to Team Spawn
* Moved Central Camps further away
* Fixed Camp Neutral Ground Overlays
* Illustrated the Paths between Camps better
* Switched Mid Level 3 Camps and First Level 2 Camps on each Side


## Hotfix 0.10.1
[`452dfb2215887ed24705169a3b560b49bdd5e905`]](https://github.com/OpenAngelArena/oaa/releases/tag/v0.10.1)
### Map
* Generated new Minimap


## Update 0.11.0
[`08c17310913a88e9a73b49aebf1c5285760e2efa`]](https://github.com/OpenAngelArena/oaa/releases/tag/v0.11.0)
### Items
* Added Invisibility Crystal
* Added Greater Enrage Crystal
* Added Doppelganger Crystal
* Added Divine Enrage Crystal
* Added Regeneration Crystal


## Update 0.12.0
[`f19a269e32c9e246883969a8bf6b68b791837fbc`]](https://github.com/OpenAngelArena/oaa/releases/tag/v0.12.0)
### Cave
* Added Farming Cave

### Items
* Added Audio-Visual Effects for Greater Boots of Travel

### Heroes
* Fixed Shadow Shaman
  * Added Level 4 and 5 to Serpend Ward

### Bosses
* Added Cliff Walking to all Bosses


## Hotfix 0.12.1
[`5c14ce2cc1bc607a002f11eb7e923df564d7a087`]](https://github.com/OpenAngelArena/oaa/releases/tag/v0.12.1)
* Updated Translations

### Duels
* Fixed Various Bugs


## Update 0.13.0
[`b9b2ef229d71bfd736c74513236878e6331c7612`]](https://github.com/OpenAngelArena/oaa/releases/tag/v0.13.0)
* Updated Tooltips

## Cave
* Fixed Baby Rosh size
* Now using creep scaling

## Items
* Fixed Greater Travel Boots

## Heroes
* Added more Talents


## Update 0.13.1
[`3d2e92c05c24777005e73bab82b7d11a2cd51032`]](https://github.com/OpenAngelArena/oaa/releases/tag/v0.13.1)
### Cave
* Added Magical Resistance for Creeps
* Rebalanced Creeps

### Bosses
* Decreased Toilet Boss Modelsize

### Heroes
* Fixed Illusion Stats for Illusions created by a different Hero

### UI
* Fixed Level Dot Styling for Heroes with 5 or 6 Abilities

### Bots
* Bots will now pick up and use Infinity Bottle
* Bots now use their spells against Creeps
* Bots now level talents and skills correctly with Priority on Farming Skills
* "When a bot gets beaten up by a neutral camp (or hero), the bot will invisibly ping to the other bots, who will come and throw bodies at the camp (or hero) until it has been culled." RamonNZ
* If you hold a smoke in the first slot of your backpack, all bots will follow you, and fight Heroes and Creeps
* If you hold a smoke in the second slot of your backpack, they will follow you, but won't fight Creeps, only Heroes
* Bots now do basic warding

### Misc
* Fixed too high Reincarnation Time when killed by Creeps


## Update 0.14.0
[`f8f3fd346cb5a087f6a5cd0ec08baed85486dbd0`]](https://github.com/OpenAngelArena/oaa/releases/tag/v0.14.0)
* Updated Tooltips
### Map
* [Video with Changes by Warpdragon](https://youtu.be/127ejnO1iIM)
* Switched 2 Camps
* Changed the Boss Arena Layout to go Counter-Clockwise not Clockwise
* Updated Texturing for Sharpness
* Enhanced Mini-Boss Room Entrance in Cave


## Hotfix 0.14.1
[`56de08ec510e9e480f666276f071f7f1428169f0`]](https://github.com/OpenAngelArena/oaa/releases/tag/v0.14.1)
* Update Tooltips

### Items
* Shroud of Shadow
  * Added Lore
  * Fixed Tooltip
  
### Duels
* Fixed Permadeath after Duels, again


## Update 0.15.0
[`0461d693fecaf04328a537bd44ef75b23d01cde5`]](https://github.com/OpenAngelArena/oaa/releases/tag/v0.15.0)
### Cave
* Fixed a Bug where you could get stuck between two rooms

### Items
* Reflex Cores
  * Fixed undocumented stuff
* Added Bubble Orb
* Added Tooltips for Refresher Core, Power Treads and Phase Boots
* Boots of Travel
  * Fixed Level 1 Recipe
  * Decreased Level 2 Recipe Cost to 500
* Lucience
  * Increased Health Regen Aura from `75 100 150` to `150 300 600`
* Radiance
  * Decreased Bonus Damage from `65 100 150 220 300` to `65 80 100 125 160`
  * Decreased Aura Damage from `50 100 200 350 550` to `50 100 150 225 350`
* Refresher Core
  * Level 1 now needs a Upgrade Core Level 2 or higher
  * Level 2 now needs a Upgrade Core Level 3 or higher
  * Level 3 now needs a Upgrade Core Level 4
* Trumps Fists
  * Level 1 now needs a Upgrade Core Level 3
  * Level 2 now needs a Upgrade Core Level 4
  * Increased All Stats from `32 34` to `35 40`
  * Increased Health from `450 550` to `500 750`
  * Increased Mana from `475 575` to `600 800`
  * Increased Heal Prevention Percentage from `-15 -75` to `-50 -100`
  * Decreased Heal Prevention Duration from `5` to `2`

### Heroes
* Fixed Zeus Cloud

### Bosses
* Added Tooltips to various Abilities


## Update 0.16.0 - Chris is back
[`d402627dc14afdf41f0b20bff261baa8488f9b25`]](https://github.com/OpenAngelArena/oaa/releases/tag/v0.16.0)
### Cave
* Fixed Mini Rosh Leash

### Items
* Lucience
  * Decreased Health Regen Aura `150 300 600` to `75 150 300`
* Bubble Orb
  * Updated Tooltips
  * Fixed various minor Bugs
* Assault Cuirass
  * Fixed Tooltips not displaying correctly
* Dragon Lance
  * Added more Tooltips
* Invisibility Crystal
  * Fixed Tooltips
* Greater Dispel Orb
  * Fixed Tooltips
* Divine Reflection Shard
  * Fixed Tooltip Typo
* Invincibility Shard
  * Complete Rewrite
  * Added Icon
* Added Stats to all Reflex Items
* Added Bottle Counter
* Refresher Core
  * Made non refreshable
  * Increased Level 1 Gold Cost from `2500` to `3500`
  * Increased Level 2 Gold Cost from `2500` to `8000`
  * Increased Level 3 Gold Cost from `3500` to `20000`
* Monkey King Bar
  * Added Icons
* Heavens Halberd
  * Added Icons
* Drum of Endurance
  * Level 2 now wont need any Upgrade Cores
* Desolator
  * Decreased Armour Corruption from `-7 -11 -16 -24 -32` to `-7 -9 -12 -16 -21`
* Pipe of Insight
  * Increased Damage Absorption from `400` to `400 800`
* Radiance
  * Increased Level 3 Gold Cost from `2500` to `3500`
  * Increased Level 4 Gold Cost from `3500` to `8000`
  * Increased Level 5 Gold Cost from `4500` to `20000`
* Divine Rapier
  * Increased Gold Cost to `50000`
  * Increased Damager from `330` to `10000`
* Spectaquila
  * Decreased Gold Cost from `1500` to `500`
* Satanic Core
  * Increased Level 1 Gold Cost from `1500` to `3500`
  * Increased Level 2 Gold Cost from `3500` to `8000`
  * Increased Level 3 Gold Cost from `4500` to `20000`
  * Level 1 now needs Satanic Level 2 and Octarine Core Level 2 instead of Satanic Level 1 and Octarine Core 1
* Shivas Cuirass
  * Level 1 now needs Upgrade Core Level 3 or higher
  * Level 2 now needs Upgrade Core Level 4
* Blade Mail
  * Removed Recipe


### Heroes
* Applied 7.05 Ability Changes and scaled Custom Levels accordingly
* Enabled Arc Warden
* Fixed Typo that prevented Elder Titan to have correct stats
* Lich
  * Fixed Sacrifice Tooltips to properly reflect how the skill works

### Bosses
* Charger
  * Added Tooltips
  * Changed to Ancient
  * Increased Magical Armour Debuff when Chargers runs into a pillar from `-280` to `-1500`
  * Decreased Magical Armour from `200` to `95`
* Added Shield Boss

### Misc
* Fixed Bugs around `modifier_generic_bonus`
* Fixed Memory Leak where entities did not get deleted correctly by Purge Tester
* Fixed Courier replacing the first two Items bought during PreGame for the first Player of every Team


## Update 0.17.0
[`d2f46c3790d72edbf0fa0dea44c35385fdc88908`]](https://github.com/OpenAngelArena/oaa/releases/tag/v0.17.0)
### Items
* Fixed Bug where Bottle Counter gets increased when creating Illusions
* Rewrite Lucience
* Added Heart Transplant


## Update 0.18.0
[`a1832aaa008d71b944e415a4a1c0ae375bf85399`]](https://github.com/OpenAngelArena/oaa/releases/tag/v0.18.0)
* Updated Tooltips
  
### Items
* Fixed Stacking Cooldown Reduction
* Bottle Counter
  * Changed to count Bottles not Charges
  * Made more stable

## Duel
* Added Rune Hill
* Added Triple Damage Rune

### Misc
* Fixed Automatic Courier Spawn
  * You now won't get any random Gold when spawning Couriers


## Update 0.19.0
[`6aea59c1c60eee01714fdc16e0b1920f1464ba15`]](https://github.com/OpenAngelArena/oaa/releases/tag/v0.19.0)
* Update Tooltips

### Creeps
* Buffed Creep Scaling

### Items
* Increased Recipe Cost of a lot of Items
  * Upgrade Core 1: 1500
  * Upgrade Core 2: 3500
  * Upgrade Core 3: 8000
  * Upgrade Core 4: 20000
* Greater Travel Boots
  * Increased GPM from `150 300 600 1200 2400` to `300 600 1200 2400 4800`

### Heroes
* Crystal Maiden
  * Brilliance Aura
    * Increased Aura Mana Regen from `1.0 1.5 2.0 3.0 3.5 5.0` to `1.0 1.5 2.0 3.0 5.0 13.0`
    * Increased Mana Regen from `2 3 4 8 9 12` to `2 3 4 8 16 48`
* Omniknight
  * Guardian Angel
    * Decreased Duration from `6.0 7.0 8.0 9.0 10.0` to `6.0 7.0 8.0 8.0 8.0`
    * Increased Radius from `600 600 600 600 600` to `600 600 600 800 1000`
    * Increased Scepter Duration from `8.0 9.0 10.0 11.0 12.0` to `8.0 9.0 10.0 10.5 11.0`
* Tidehunter
  * Anchor Smash
    * Decreased Damage Reduction from `-45 -50 -55 -60 -80 -160` to `-45 -50 -55 -60 -65 -70`

### Bosses
* Added The Twins - Zadkiel and Jophiel


## Update 0.20.0
[`b1ff4d9a37e6b562cfb5d3b3bbbf132b1d9211ea`]](https://github.com/OpenAngelArena/oaa/releases/tag/v0.20.0)
* Update Tooltips

### Bosses
* The Twins
  * Decreased Attack Rate from `1.0` to `0.75`
  * Decreased Health from `5000` to `3500`

### Duels
* Make Units Stop at the start of the Duel


### Update 0.21.0
[`9311104615207fafaf6e8976c879159191ce2e54`]](https://github.com/OpenAngelArena/oaa/releases/tag/v0.21.0)
* Updated Tooltips

### Creeps
* Tweaked Creep Progression
  * Decreased Armour
  Increased Damage
* Fixed smaller Ancients being stronger
* Slightly redistributed XP and Gold within camps. Total amounts per spawn still the same
* Made centaurs tankier so they wouldn't be a weaker camp compared to wolves


### Update 0.22.0 - Chris is back again
[`38a53f9403710665a6455787f496ec51b09eb971`]](https://github.com/OpenAngelArena/oaa/releases/tag/v0.22.0)
* Generated Tooltips
* Added new Languages

### Creeps
* Made Creeps Spread a bit
* Added Moving Doors
* Fixed Exponential Growth
* Decreased Creeps in Easy and Medium Camps by one
* Changed Progression to Buff 20~40 minutes, trying to keep lower Minutes' Multiplier the same
* Changed Hard Camps to spawn different Groups of Creeps

### Cave
* Decreased Creep Count in Rooms 1 to 3 by two

### Items
* Added New Icons for all Upgrade Cores, Reflex Core and the Reflex Orbs
* Added Glowing Icons for all Greater Boots
* Added Icon to Bottle Counter Buff
* Added Grater Tranquil Boots

### Heroes
* Keeper of the Light
  * Blinding Light
    * Decreased Miss Duration from `4.0 5.0 6.0 8.0 10.0` to `4.0 5.0 6.0 7.0 8.0`
* Sladar
  * Amplify Damage
    * Decreased Armour Reduction from `-10 -15 -20 -30 -50` to `-10 -15 -20 -25 -35`
* Luna
  * Eclipse
    * Decreased Beam Count from `5 8 11 17 40` to `5 8 11 13 15`
    * Decreased Scepter Beam Count from `6 12 18 30 78` to `6 12 18 24 30`
    * Decreased Duration from `2.4 4.2 6.0 9.6 24.0` to `2.4 4.2 6.0 7.2 8.4`
    * Decreased Scepter Duration from `1.8 3.6 5.4 9.0 23.0` to `1.8 3.6 5.4 7.2 9.0`
  * Moon Glaive
    * Decreased Bounces from `1 2 3 6 9 20` to `1 2 3 6 7 8`
    * Increased Damage Reduction per Bounce from `35` to `35 35 35 35 30 25`

### Bosses
* Added "stop fighting yourself" aka "Uriel the Mirror of Creation"
* Shielder
  * Increased Attack Damage from `500 600` to `2300 2350`
  * Decreased Attack Rate from `2.0` to `1.0`
  * Increased Health from `1000` to `5500`
  * Increased Health Regen from `3.5` to `8.5`
* The Twins
  * Changed Zadkiel's Model
  * Changed Jophiel's Model
  * Increased Zadkiel's Attack Damage from `500 600` to `700 750`
  * Made Jophiel Ranged
  * Increased Jophiel's Attack Range from `128` to `960`
* Tier 1 Boss is now literally Roshan
  
### Duels
*  Added Particle Effects while on the Rune Hill

### Map
* Added Doors to Cave
* Made Tier 1 Boss Pit more fancy

### Misc
* Fixed Illusion Progression even more


### Update 0.23.0 - Icon Update
[`745f31338eb5ce263ff18b9270cac512995787f6`]](https://github.com/OpenAngelArena/oaa/releases/tag/v0.23.0)
### Items
* Added Progressive Icons
  * Greater Power Treads, Grater Phase, Tranquil and Travel Boots
  * Reflex Shards and Orbs
  * Abyssal Blade
  * Aghanims
  * Aether Lens
  * Armlet of Mordiggian
  * Assault Cuirass
  * Battle Fury
  * Blade Mail
  * Bloodstone
  * Butterfly
  * Crimson Guard
  * Deadalus
  * Dragon
  * Desolator
  * Diffusal Blade
  * Dragon Lance
  * Drums
  * Eul's Scepter of Divinity
  * Radiance
  * Shroud of Shadows
  * Lucience
  * Stoneskin Armour
  * Trump's Fists
* Stoneskin Armour
  * Increased Level 1 Recipe Cost from `3500` to `8000`
  * Level 1 Requirements are now
    * Shivas Guard Level 3
    * Armlet of Mordiggian Level 2
    * Upgrade Core Level 3 or higher
  * Increased Level 2 Recipe Cost from `8000` to `20000`
  * Level 2 Requirements are now
    * Stoneskin Armour Level 1
    * Upgrade Core Level 4

### Bosses
* Roshan
  * Decreased Attack Damage from `500 600` to `225 250`
* Shielder
  * Decreased Attack Damage from `2300 2350` to `1300 1350`
  * Fixed negative Lifesteal Bug
  * Shield
    * Increased Damage Reduction from `10` to `15`
* Boss Resistance
  * Decreased Damage Reduction in Percent from `90` to `85`
* The Twins
  * Fixed not spawning

### Misc
* Fixed Automatic Courier swapping Items between Players


## Update 0.24.0
[`6cf270810ec8860d0dc6b34d374c9f992a1997e6`]](https://github.com/OpenAngelArena/oaa/releases/tag/v0.24.0)
* Updated Tooltips

### Creeps
* Changed Creeps to make them a bit tankier vs Spells
* Changed Progression

### Cave
* Made Doors faster
* Made Roshlings less tanky

### GetDotaStats
* Fixed missing Variables

### Misc
* Fixed Win Condition not applying correctly


### Update 0.24.1 - More Icons
[`d41f222edeab046ea0f43d6e58eff77e6c358708`]](https://github.com/OpenAngelArena/oaa/releases/tag/v0.24.1)
### Creeps
* Fixed Creep Progression

### Cave
* Roshlings
  * Removed Inherent Buff
  * Removed Devotion Buff

### Items
* Aghanims
  * Made Level 4 and 5 Icons look more fancy
* Aether Lens
  * Made Level 2 and 3 Icons look more fancy
* Eul's Scepter of Divinity
  * Made Level 2 Icon look more fancy
* Added Progressive Icons
  * Mask of Madness
  * Echo Sabre
  * Eye of Skadi
  * Linkes Sphere
  * Lotus Orb
  * Manta Style
  * Midas Hand
  * Mjollnir
  * Necronomicon
  * Octarine Core
  * Pipe of Insight
  * Refresher Orb
  * Ring of Aquila
  * Rod of Atos
  * Sange and Yasha
  * Satanic Core
  * Scythe of Vyse
  * Shiva's Guard
  * Silver Edge
  * Solar Crest
  * Veil of Discord

### Heroes
* Shadow Fiend
  * Necromastery
    * Increased Damage per Soul from `2 2 2 2 2 2` to `2 2 2 2 3 5`


## Icon Hotfix 0.24.2
[`1f650bb51587cd658d76aa2a813175205db5cea8`]](https://github.com/OpenAngelArena/oaa/releases/tag/v0.24.2)
### Items
* Fixed Icons
  * Scythe of Vyse
  * Refresher Orb
  * Manta Style
  * Shiva's Guard
  * Lucience


## Hotfix 0.24.3
[`6fdeb8be99c701af9ac694d0f63cc3c40f07a758`]](https://github.com/OpenAngelArena/oaa/releases/tag/v0.24.3)
### Items
* Heart of Tarrasque
  * Increased Health Regen from `3.25` tp `7`
* Trump's Fists
  * Made more consistent

### Bosses
* Shielder
  * Decreased Health from `5500` to `3500`
* Fixed Bug with Bloodrage and Boss Resistance

### Duels
* Fixed Bug where you potentially won't get teleported when casting a ability

### Misc
* Fixed Neutral Hero Kill increasing Points


## Update 0.25.0
[`88545ec54884198a25e68a5570f361df67434f67`]](https://github.com/OpenAngelArena/oaa/releases/tag/v0.25.0)
* Generated Tooltips

### Creeps
* Added Black Dragon to Hard Camps
* Added Tomato Warrior to Medium Camps
* Decreased Creep Count
* Decreased Creep Base Stats
* Decreased Creep Stat Progression
* Made Easy Camps harder to farm with Magical Damage
* Roshlings
  * Decreased Health
  * Increased Physical Armour
  * Decreased Attack Damage

### Items
* Added new Icons
  * [Black King Bar](https://github.com/OpenAngelArena/oaa/blob/bbc8b44e5c3a420d89173d34c6d025567abaad29/game/resource/flash3/images/items/black_king_bar.png)
  * [Charge BKB](https://github.com/OpenAngelArena/oaa/blob/bbc8b44e5c3a420d89173d34c6d025567abaad29/game/resource/flash3/images/items/custom/charge_bkb.png)
* Disabled Moonshard
* Buff Reflex Cores

### Heroes
* Fix Fix for the Fix to Ability Upgrades

### Duels
* Fix sometimes hanging when a Player dies to a Neutral
* Fix Bug with Reincarnation

### UI
* Don't show Ability Icons when you can't level up yet

### Misc
* Prevent disconnected Players from breaking the Game
* Refix Infinite Death on Reconnect


## Update 0.26.0
[`6227f700d73612ba78d6ee1a9a9e3c3cc0f9ed90`](https://github.com/OpenAngelArena/oaa/releases/tag/v0.26.0)
* Generated Tooltips

### Creeps
* Made Black Dragon Ancient
* Decreased Creep Count

### Cave
* Fixed Roshling Gold Formula
* Decreased Creep Count
* Increased Magical Armour from `10 30 50 70` to `25 40 55 70`
* Fixed Teleport teleporting Players outside the Cave 

### Heroes
* Fixed Doom's Doom Level 4 Scepter Damage

### Misc
* Added Dutch to Translations
* Disabled Skip Team Setup


## Update 0.27.0
[`1e6af1f435bc492dbd15c70a6223ecd30986adf9`](https://github.com/OpenAngelArena/oaa/releases/tag/v0.27.0)

### Items
* Applied patches 7.03 7.04 7.05
* Added Siege Mode
* Added New Icons
  * [Abyssal Blade 1](https://github.com/OpenAngelArena/oaa/blob/a700db52d5b39a3e8072024b602502661ff991d8/game/resource/flash3/images/items/custom/Abyssal_Blade_1.png)
  * [Abyssal Blade 1](https://github.com/OpenAngelArena/oaa/blob/a700db52d5b39a3e8072024b602502661ff991d8/game/resource/flash3/images/items/custom/Abyssal_Blade_2.png)
  * [Abyssal Blade 1]https://github.com/OpenAngelArena/oaa/blob/a700db52d5b39a3e8072024b602502661ff991d8/game/resource/flash3/images/items/custom/Abyssal_Blade_3.png()
  * [Abyssal Blade 1](https://github.com/OpenAngelArena/oaa/blob/a700db52d5b39a3e8072024b602502661ff991d8/game/resource/flash3/images/items/custom/Abyssal_Blade_4.png)
  * [Abyssal Blade 1](https://github.com/OpenAngelArena/oaa/blob/a700db52d5b39a3e8072024b602502661ff991d8/game/resource/flash3/images/items/custom/Abyssal_Blade_5.png)
  * [Assault Cuirass 1](https://github.com/OpenAngelArena/oaa/blob/6c84c410bd1cc5da631b8a240d806659698a3f56/game/resource/flash3/images/items/custom/assault_cuirass_1.png)
  * [Assault Cuirass 2](https://github.com/OpenAngelArena/oaa/blob/6c84c410bd1cc5da631b8a240d806659698a3f56/game/resource/flash3/images/items/custom/assault_cuirass_2.png)
  * [Assault Cuirass 3](https://github.com/OpenAngelArena/oaa/blob/6c84c410bd1cc5da631b8a240d806659698a3f56/game/resource/flash3/images/items/custom/assault_cuirass_3.png)
  * [Lotus Orb 1](https://github.com/OpenAngelArena/oaa/blob/000c048125c5e4c67854cfcbe564c8bdd48d93e0/game/resource/flash3/images/items/custom/lotus_orb_1.png)
  * [Refresher Orb 1](https://github.com/OpenAngelArena/oaa/blob/000c048125c5e4c67854cfcbe564c8bdd48d93e0/game/resource/flash3/images/items/custom/refresher_orb_1.png)
  * [Refresher Orb 2](https://github.com/OpenAngelArena/oaa/blob/000c048125c5e4c67854cfcbe564c8bdd48d93e0/game/resource/flash3/images/items/custom/refresher_orb_2.png)
  * [Crimson Guard 2](https://github.com/OpenAngelArena/oaa/blob/3fa69ad8273d87d80c74e64562557331a47ba913/game/resource/flash3/images/items/custom/crimson_guard_2.png)
  * [Silver Edge 2](https://github.com/OpenAngelArena/oaa/blob/3fa69ad8273d87d80c74e64562557331a47ba913/game/resource/flash3/images/items/custom/silver_edge_2.png)
  * [Silver Edge 3](https://github.com/OpenAngelArena/oaa/blob/3fa69ad8273d87d80c74e64562557331a47ba913/game/resource/flash3/images/items/custom/silver_edge_3.png)
  * [Silver Edge 4](https://github.com/OpenAngelArena/oaa/blob/3fa69ad8273d87d80c74e64562557331a47ba913/game/resource/flash3/images/items/custom/silver_edge_4.png)
  * [Silver Edge 5](https://github.com/OpenAngelArena/oaa/blob/3fa69ad8273d87d80c74e64562557331a47ba913/game/resource/flash3/images/items/custom/silver_edge_5.png)
  * [Battle Fury 1](https://github.com/OpenAngelArena/oaa/blob/6c84c410bd1cc5da631b8a240d806659698a3f56/game/resource/flash3/images/items/custom/battle_fury_1.png)
  * [Battle Fury 2](https://github.com/OpenAngelArena/oaa/blob/6c84c410bd1cc5da631b8a240d806659698a3f56/game/resource/flash3/images/items/custom/battle_fury_2.png)
  * [Battle Fury 3](https://github.com/OpenAngelArena/oaa/blob/6c84c410bd1cc5da631b8a240d806659698a3f56/game/resource/flash3/images/items/custom/battle_fury_3.png)
  * [Battle Fury 4](https://github.com/OpenAngelArena/oaa/blob/6c84c410bd1cc5da631b8a240d806659698a3f56/game/resource/flash3/images/items/custom/battle_fury_4.png)
  * [Bloodstone 1](https://github.com/OpenAngelArena/oaa/blob/6c84c410bd1cc5da631b8a240d806659698a3f56/game/resource/flash3/images/items/custom/bloodstone_1.png)
  * [Bloodstone 2](https://github.com/OpenAngelArena/oaa/blob/6c84c410bd1cc5da631b8a240d806659698a3f56/game/resource/flash3/images/items/custom/bloodstone_2.png)
  * [Bloodstone 3](https://github.com/OpenAngelArena/oaa/blob/6c84c410bd1cc5da631b8a240d806659698a3f56/game/resource/flash3/images/items/custom/bloodstone_3.png)
  * [Bloodstone 4](https://github.com/OpenAngelArena/oaa/blob/6c84c410bd1cc5da631b8a240d806659698a3f56/game/resource/flash3/images/items/custom/bloodstone_4.png)
  * [Bloodstone 5](https://github.com/OpenAngelArena/oaa/blob/6c84c410bd1cc5da631b8a240d806659698a3f56/game/resource/flash3/images/items/custom/bloodstone_5.png)
  * [Bloodthorn 1](https://github.com/OpenAngelArena/oaa/blob/6c84c410bd1cc5da631b8a240d806659698a3f56/game/resource/flash3/images/items/custom/bloodthorn_1.png)
  * [Bloodthorn 2](https://github.com/OpenAngelArena/oaa/blob/6c84c410bd1cc5da631b8a240d806659698a3f56/game/resource/flash3/images/items/custom/bloodthorn_2.png)
  * [Bloodthorn 3](https://github.com/OpenAngelArena/oaa/blob/6c84c410bd1cc5da631b8a240d806659698a3f56/game/resource/flash3/images/items/custom/bloodthorn_3.png)
  * [Bloodthorn 4](https://github.com/OpenAngelArena/oaa/blob/6c84c410bd1cc5da631b8a240d806659698a3f56/game/resource/flash3/images/items/custom/bloodthorn_4.png)
  * [Bloodthorn 5](https://github.com/OpenAngelArena/oaa/blob/6c84c410bd1cc5da631b8a240d806659698a3f56/game/resource/flash3/images/items/custom/bloodthorn_5.png)
  * [Desolator 1](https://github.com/OpenAngelArena/oaa/blob/6c84c410bd1cc5da631b8a240d806659698a3f56/game/resource/flash3/images/items/custom/desolator_1.png)
  * [Desolator 2](https://github.com/OpenAngelArena/oaa/blob/6c84c410bd1cc5da631b8a240d806659698a3f56/game/resource/flash3/images/items/custom/desolator_2.png)
  * [Desolator 3](https://github.com/OpenAngelArena/oaa/blob/6c84c410bd1cc5da631b8a240d806659698a3f56/game/resource/flash3/images/items/custom/desolator_3.png)
  * [Desolator 4](https://github.com/OpenAngelArena/oaa/blob/6c84c410bd1cc5da631b8a240d806659698a3f56/game/resource/flash3/images/items/custom/desolator_4.png)
  * [Desolator 5](https://github.com/OpenAngelArena/oaa/blob/6c84c410bd1cc5da631b8a240d806659698a3f56/game/resource/flash3/images/items/custom/desolator_5.png)
  * [Drums of Endurance 1](https://github.com/OpenAngelArena/oaa/blob/6c84c410bd1cc5da631b8a240d806659698a3f56/game/resource/flash3/images/items/custom/drums_1.png)
  * [Drums of Endurance 2](https://github.com/OpenAngelArena/oaa/blob/6c84c410bd1cc5da631b8a240d806659698a3f56/game/resource/flash3/images/items/custom/drums_2.png)
  * [Echo Sabre 1](https://github.com/OpenAngelArena/oaa/blob/6c84c410bd1cc5da631b8a240d806659698a3f56/game/resource/flash3/images/items/custom/echo_sabre_1.png)
  * [Echo Sabre 2](https://github.com/OpenAngelArena/oaa/blob/6c84c410bd1cc5da631b8a240d806659698a3f56/game/resource/flash3/images/items/custom/echo_sabre_2.png)
  * [Echo Sabre 3](https://github.com/OpenAngelArena/oaa/blob/6c84c410bd1cc5da631b8a240d806659698a3f56/game/resource/flash3/images/items/custom/echo_sabre_3.png)
  * [Echo Sabre 4](https://github.com/OpenAngelArena/oaa/blob/6c84c410bd1cc5da631b8a240d806659698a3f56/game/resource/flash3/images/items/custom/echo_sabre_4.png)
  * [Heart of Tarrasque 1](https://github.com/OpenAngelArena/oaa/blob/6c84c410bd1cc5da631b8a240d806659698a3f56/game/resource/flash3/images/items/custom/heart.png)
  * [Heart of Tarrasque 2](https://github.com/OpenAngelArena/oaa/blob/6c84c410bd1cc5da631b8a240d806659698a3f56/game/resource/flash3/images/items/custom/heart_2.png)
  * [Heart of Tarrasque 3](https://github.com/OpenAngelArena/oaa/blob/6c84c410bd1cc5da631b8a240d806659698a3f56/game/resource/flash3/images/items/custom/heart_3.png)
  * [Heart of Tarrasque 4](https://github.com/OpenAngelArena/oaa/blob/6c84c410bd1cc5da631b8a240d806659698a3f56/game/resource/flash3/images/items/custom/heart_4.png)
  * [Heart of Tarrasque 5](https://github.com/OpenAngelArena/oaa/blob/6c84c410bd1cc5da631b8a240d806659698a3f56/game/resource/flash3/images/items/custom/heart_5.png)
  * [Heart Transplant 1](https://github.com/OpenAngelArena/oaa/blob/6c84c410bd1cc5da631b8a240d806659698a3f56/game/resource/flash3/images/items/custom/heart_transplant.png)
  * [Heart Transplant 2](https://github.com/OpenAngelArena/oaa/blob/6c84c410bd1cc5da631b8a240d806659698a3f56/game/resource/flash3/images/items/custom/heart_transplant_2.png)
  * [Ethereal Blade 1](https://github.com/OpenAngelArena/oaa/blob/6c84c410bd1cc5da631b8a240d806659698a3f56/game/resource/flash3/images/items/custom/item_ethereal_blade.png)
  * [Ethereal Blade 2](https://github.com/OpenAngelArena/oaa/blob/6c84c410bd1cc5da631b8a240d806659698a3f56/game/resource/flash3/images/items/custom/item_ethereal_blade_2.png)
  * [Ethereal Blade 3](https://github.com/OpenAngelArena/oaa/blob/6c84c410bd1cc5da631b8a240d806659698a3f56/game/resource/flash3/images/items/custom/item_ethereal_blade_3.png)
  * [Ethereal Blade 4](https://github.com/OpenAngelArena/oaa/blob/6c84c410bd1cc5da631b8a240d806659698a3f56/game/resource/flash3/images/items/custom/item_ethereal_blade_4.png)
  * [Ethereal Blade 5](https://github.com/OpenAngelArena/oaa/blob/6c84c410bd1cc5da631b8a240d806659698a3f56/game/resource/flash3/images/items/custom/item_ethereal_blade_5.png)
  * [Greater Phase Boots 1](https://github.com/OpenAngelArena/oaa/blob/6c84c410bd1cc5da631b8a240d806659698a3f56/game/resource/flash3/images/items/custom/item_greater_phase.png)
  * [Greater Phase Boots 2](https://github.com/OpenAngelArena/oaa/blob/6c84c410bd1cc5da631b8a240d806659698a3f56/game/resource/flash3/images/items/custom/item_greater_phase_2.png)
  * [Greater Phase Boots 3](https://github.com/OpenAngelArena/oaa/blob/6c84c410bd1cc5da631b8a240d806659698a3f56/game/resource/flash3/images/items/custom/item_greater_phase_3.png)
  * [Greater Phase Boots 4](https://github.com/OpenAngelArena/oaa/blob/6c84c410bd1cc5da631b8a240d806659698a3f56/game/resource/flash3/images/items/custom/item_greater_phase_4.png)
  * [Greater Phase Boots 5](https://github.com/OpenAngelArena/oaa/blob/6c84c410bd1cc5da631b8a240d806659698a3f56/game/resource/flash3/images/items/custom/item_greater_phase_5.png)
  * [Greater Power Treads 1](https://github.com/OpenAngelArena/oaa/blob/6c84c410bd1cc5da631b8a240d806659698a3f56/game/resource/flash3/images/items/custom/item_greater_power_treads.png)
  * [Greater Power Treads 2](https://github.com/OpenAngelArena/oaa/blob/6c84c410bd1cc5da631b8a240d806659698a3f56/game/resource/flash3/images/items/custom/item_greater_power_treads_2.png)
  * [Greater Power Treads 3](https://github.com/OpenAngelArena/oaa/blob/6c84c410bd1cc5da631b8a240d806659698a3f56/game/resource/flash3/images/items/custom/item_greater_power_treads_3.png)
  * [Greater Power Treads 4](https://github.com/OpenAngelArena/oaa/blob/6c84c410bd1cc5da631b8a240d806659698a3f56/game/resource/flash3/images/items/custom/item_greater_power_treads_4.png)
  * [Greater Power Treads 5](https://github.com/OpenAngelArena/oaa/blob/6c84c410bd1cc5da631b8a240d806659698a3f56/game/resource/flash3/images/items/custom/item_greater_power_treads_5.png)
  * [Greater Tranquil Boots 1](https://github.com/OpenAngelArena/oaa/blob/6c84c410bd1cc5da631b8a240d806659698a3f56/game/resource/flash3/images/items/custom/item_greater_tranquils.png)
  * [Greater Tranquil Boots 2](https://github.com/OpenAngelArena/oaa/blob/6c84c410bd1cc5da631b8a240d806659698a3f56/game/resource/flash3/images/items/custom/item_greater_tranquils_2.png)
  * [Greater Tranquil Boots 3](https://github.com/OpenAngelArena/oaa/blob/6c84c410bd1cc5da631b8a240d806659698a3f56/game/resource/flash3/images/items/custom/item_greater_tranquils_3.png)
  * [Greater Tranquil Boots 4](https://github.com/OpenAngelArena/oaa/blob/6c84c410bd1cc5da631b8a240d806659698a3f56/game/resource/flash3/images/items/custom/item_greater_tranquils_4.png)
  * [Greater Tranquil Boots 5](https://github.com/OpenAngelArena/oaa/blob/6c84c410bd1cc5da631b8a240d806659698a3f56/game/resource/flash3/images/items/custom/item_greater_tranquils_5.png)
  * [Greater Travel Boots 1](https://github.com/OpenAngelArena/oaa/blob/6c84c410bd1cc5da631b8a240d806659698a3f56/game/resource/flash3/images/items/custom/item_greater_travels.png)
  * [Greater Travel Boots 2](https://github.com/OpenAngelArena/oaa/blob/6c84c410bd1cc5da631b8a240d806659698a3f56/game/resource/flash3/images/items/custom/item_greater_travels_2.png)
  * [Greater Travel Boots 3](https://github.com/OpenAngelArena/oaa/blob/6c84c410bd1cc5da631b8a240d806659698a3f56/game/resource/flash3/images/items/custom/item_greater_travels_3.png)
  * [Greater Travel Boots 4](https://github.com/OpenAngelArena/oaa/blob/6c84c410bd1cc5da631b8a240d806659698a3f56/game/resource/flash3/images/items/custom/item_greater_travels_4.png)
  * [Greater Travel Boots 5](https://github.com/OpenAngelArena/oaa/blob/6c84c410bd1cc5da631b8a240d806659698a3f56/game/resource/flash3/images/items/custom/item_greater_travels_5.png)
  * [Linkes Sphere 2](https://github.com/OpenAngelArena/oaa/blob/6c84c410bd1cc5da631b8a240d806659698a3f56/game/resource/flash3/images/items/custom/linkens_sphere_2.png)
  * [Pipe of Insight 2](https://github.com/OpenAngelArena/oaa/blob/6c84c410bd1cc5da631b8a240d806659698a3f56/game/resource/flash3/images/items/custom/pipe_of_insight_2.png)
  * [Ring of Aquila 1](https://github.com/OpenAngelArena/oaa/blob/6c84c410bd1cc5da631b8a240d806659698a3f56/game/resource/flash3/images/items/custom/ring_of_aquila.png)
  * [Ring of Aquila 2](https://github.com/OpenAngelArena/oaa/blob/6c84c410bd1cc5da631b8a240d806659698a3f56/game/resource/flash3/images/items/custom/ring_of_aquila_2.png)
  * [Ring of Aquila 3](https://github.com/OpenAngelArena/oaa/blob/6c84c410bd1cc5da631b8a240d806659698a3f56/game/resource/flash3/images/items/custom/ring_of_aquila_3.png)
  * [Sange and Yasha 1](https://github.com/OpenAngelArena/oaa/blob/6c84c410bd1cc5da631b8a240d806659698a3f56/game/resource/flash3/images/items/custom/sange_and_yasha_1.png)
  * [Sange and Yasha 2](https://github.com/OpenAngelArena/oaa/blob/6c84c410bd1cc5da631b8a240d806659698a3f56/game/resource/flash3/images/items/custom/sange_and_yasha_2.png)
  * [Scythe of Vyse 1](https://github.com/OpenAngelArena/oaa/blob/6c84c410bd1cc5da631b8a240d806659698a3f56/game/resource/flash3/images/items/custom/scythe_of_vyse_1.png)
  * [Scythe of Vyse 2](https://github.com/OpenAngelArena/oaa/blob/6c84c410bd1cc5da631b8a240d806659698a3f56/game/resource/flash3/images/items/custom/scythe_of_vyse_2.png)
  * [Scythe of Vyse 3](https://github.com/OpenAngelArena/oaa/blob/6c84c410bd1cc5da631b8a240d806659698a3f56/game/resource/flash3/images/items/custom/scythe_of_vyse_3.png)
  * [Scythe of Vyse 4](https://github.com/OpenAngelArena/oaa/blob/6c84c410bd1cc5da631b8a240d806659698a3f56/game/resource/flash3/images/items/custom/scythe_of_vyse_4.png)
  * [Scythe of Vyse 5](https://github.com/OpenAngelArena/oaa/blob/6c84c410bd1cc5da631b8a240d806659698a3f56/game/resource/flash3/images/items/custom/scythe_of_vyse_5.png)
  * [Shivas Cuirass 1](https://github.com/OpenAngelArena/oaa/blob/6c84c410bd1cc5da631b8a240d806659698a3f56/game/resource/flash3/images/items/custom/shivas_cuirass.png)
  * [Shivas Cuirass 2](https://github.com/OpenAngelArena/oaa/blob/6c84c410bd1cc5da631b8a240d806659698a3f56/game/resource/flash3/images/items/custom/shivas_cuirass.png)
  * [Shivas Guard 1](https://github.com/OpenAngelArena/oaa/blob/6c84c410bd1cc5da631b8a240d806659698a3f56/game/resource/flash3/images/items/custom/shivas_guard_1.png)
  * [Shivas Guard 2](https://github.com/OpenAngelArena/oaa/blob/6c84c410bd1cc5da631b8a240d806659698a3f56/game/resource/flash3/images/items/custom/shivas_guard_2.png)
  * [Shivas Guard 3](https://github.com/OpenAngelArena/oaa/blob/6c84c410bd1cc5da631b8a240d806659698a3f56/game/resource/flash3/images/items/custom/shivas_guard_3.png)
  * [Solar Crest 1](https://github.com/OpenAngelArena/oaa/blob/6c84c410bd1cc5da631b8a240d806659698a3f56/game/resource/flash3/images/items/custom/solar_crest_1.png)
  * [Solar Crest 2](https://github.com/OpenAngelArena/oaa/blob/6c84c410bd1cc5da631b8a240d806659698a3f56/game/resource/flash3/images/items/custom/solar_crest_2.png)
  * [Solar Crest 3](https://github.com/OpenAngelArena/oaa/blob/6c84c410bd1cc5da631b8a240d806659698a3f56/game/resource/flash3/images/items/custom/solar_crest_3.png)
  * [Solar Crest 4](https://github.com/OpenAngelArena/oaa/blob/6c84c410bd1cc5da631b8a240d806659698a3f56/game/resource/flash3/images/items/custom/solar_crest_4.png)
  * [Veil of Discord 1](https://github.com/OpenAngelArena/oaa/blob/6c84c410bd1cc5da631b8a240d806659698a3f56/game/resource/flash3/images/items/custom/veil_of_discord_1.png)
  * [Veil of Discord 2](https://github.com/OpenAngelArena/oaa/blob/6c84c410bd1cc5da631b8a240d806659698a3f56/game/resource/flash3/images/items/custom/veil_of_discord_2.png)
  * [Phase Boots](https://github.com/OpenAngelArena/oaa/blob/6c84c410bd1cc5da631b8a240d806659698a3f56/game/resource/flash3/images/items/phase_boots.png)
  * [Power Treads](https://github.com/OpenAngelArena/oaa/blob/6c84c410bd1cc5da631b8a240d806659698a3f56/game/resource/flash3/images/items/power_treads.png)
  * [Tranquil Boots](https://github.com/OpenAngelArena/oaa/blob/6c84c410bd1cc5da631b8a240d806659698a3f56/game/resource/flash3/images/items/tranquil_boots.png)
  * [Trave Boots 2](https://github.com/OpenAngelArena/oaa/blob/6c84c410bd1cc5da631b8a240d806659698a3f56/game/resource/flash3/images/items/travel_boots_2.png)
* Lucience
  * Decreased Toggle Cooldown from `3` to `1`
* Satanic Core
  * Decreased Hero Lifesteal from `50 65 80` to `35 45 55`
* Shivas Cuirass
  * Increased Bonus Armour from `40` to `45 50`
  * Increased Bonus Attack Speed from `30 40` to `50 60`
  * Increased Blast Radius from `900` to `900 1100`
  * Increased Aura Attack Speed Reduction from `-55` to `-85 -95`
  * Increased Aura Armour Reduction from `-5` to `-9 11`
  * Increased Aura Attack Speed Bonus from `25 30` to `35 45`
  * Increased Aura Armour Bonus from `10` to `9 11`
* Fixed Bubble Orb not removing Bubble
* Fixed Bloodstone Interaction with Illusions, Reincarnations and distant Kills

### Heroes
* Applied Patch 7.06 Talents and Abilities A-D
* Update Mass Serpent Wards to work properly with special Talents
* Update Call of the Wild for Boar spawn Talent
* Phoenix
  * Sun Ray
    * Decreased Damage in Percent from `1.5 3.25 5.0 6.75 10.0 20.0` to `1.5 3.25 5.0 6.75 6.75 6.75`
    * Decreased Heal in Percent from `0.625 1.25 1.875 2.5 3.75 8.75` to `0.625 1.25 1.875 2.5 2.5 2.5`

### Bosses
* Add Handling for Chen's Penitence to Boss Resistance

### Map
* Added Arena Shop
* Moved Boss Pit Arena Entrances


## Update 0.28.0
[`b5a8bb33a3669ed4189059f5823b202f63198e56`](https://github.com/OpenAngelArena/oaa/releases/tag/v0.28.0)
* Generated Tooltips

### Items
* Removed Combiner
* Added new Icons
  * [Lotus Orb 2](https://github.com/OpenAngelArena/oaa/blob/954e65b899095652acd64aa5d46d8848d4e91557/game/resource/flash3/images/items/custom/lotus_orb_2.png)
  * [Refresher Orb 2](https://github.com/OpenAngelArena/oaa/blob/954e65b899095652acd64aa5d46d8848d4e91557/game/resource/flash3/images/items/custom/refresher_orb_2%20.png)
* Fixed Siege Mode 2 not doing anything on Activation
* Deadalus
  * Increased Bonus Damage from `80 105 130 155 180` to `80 120 180 270 360`
  * Decreased Crit Chance from `30 35 40 45 50` to `30`
  * Increased Crit Multiplier from `235 255 275 295 315` to `235 260 285 310 335`
* Bloodthorn
  * Decreased Bonus Damage from `60 90 120 170 250` to `60 90 135 200 270`
  * Decreased Crit Chance from `20 22 25 27 30` to `20`
  * Increased Crit Multiplier from `175 190 210 230 250` to `175 195 215 235 255`
  * Decreased Crit Multiplier on Target from `145 160 180 200 220` to `145 160 175 190 205`

### Heroes
* Juggernaut
  * Blade Dance
    * Decreased Crit Chance from `20 25 30 35 40 50` to `20 25 30 35 40 45`
* Lycan
  * Shapeshift
    * Decreased Crit Multiplier from `160 180 200 240 370` to `160 180 200 220 240`
* Brewmaster
  * Drunken Brawler
    * Decreased Crit Multiplier from `230 230 230 230 280 330` to `230`
* Phantom Assassin
  * Coup de Grace
    * Increased Crit Bonus from `230 340 450 560 750` to `230 340 450 560 770`

### Bosses
* Uriel 
  * Decreased Physical Armour from `250` to `75`
  * Decreased Magical Armour from `200` to `20`


## Hotfix 0.28.1
[`617f671b8e9a1a212d828b4909280a2a169bedd5`](https://github.com/OpenAngelArena/oaa/releases/tag/v0.28.1)

### Items
* Octarine Core
  * Reduced Hero Lifesteal from `25 35` to `25 30`
* Satanic 
  * Increased Lifesteal from `25` to `25 30 35 40 45`
  * Increased Unholy Lifesteal from `175` to `175 170 165 160 155`
* Satanic Core
  * Decreased Hero Lifesteal from `35 45 55` to `35`
  * Decreased Unholy Creep Spellsteal from `200` to `190 180 170`
  * Decreased Unholy Hero Spellsteal from `200` to `165`


## Update 0.29.0 - Chris is back again again
[`617f671b8e9a1a212d828b4909280a2a169bedd5`](https://github.com/OpenAngelArena/oaa/releases/tag/v0.29.0)
* Generated Tooltips

### Cave
* Roshlings
  * Made Creep Heros

### Items
* Reworked Pull Staff to work more like Pudges Hook than a reverse Force Staff
* Added Insta-Kill Dev-Dagon
* Shivas Cuirass
  * Decreased Bonus Armour from `45 50` to `40 45`
  * Increased Aura Armour Reduction from `-9 11` to `-15 -20`
  * Increased Aura Bonus Armour from `9 11` to `15 20`
* Removed Proximity Radiance
* Fixed Refresher Items not sharing a Cooldown
* Octarine Core
  * Increased Bonus Intelligence from `25 35` to `25 38`
* Satanic Core
  * Increased Bonus Strength from `38 55 75` to `28 45 65`
  * Increased Bonus Intelligence from `25 35 45` to `28 45 65`
  * Removed Bonus Damage
* Crimson Guard
  * Increased Active Melee Damage Block from `60` to `60 90`
  * Increased Active Ranged Damage Block from `60` to `60 90`
* Refresher
  * Increased Bonus Health Regen from `12 16` to `12 18`
* Refresher Core
  * Changed Bonus Intelligence from `40 45 50` to `28 45 65`
  * Decreased Bonus Health from `600 700 800` to `500`
  * Decreased Bonus Mana from `600` to `500`

### Shops
* Disabled Universal Shop
* Make Secret Shop Items purchasable in Home Shop
* Make only Dust of Appearance and Sentry Wards purchasable from Arena Shop
* Rearrange Item List in Home Shop

### Heroes
* Applied Patch 7.06b

### UI
* Added Quick Stat Display
* Added Version Display in upper right Corner

### Misc
* Creeps now spawn 30 seconds after Game Start
* PreGame Time increased to 30 seconds
* Massive Icon and Item related formatting and naming fixes


## Hotfix 0.29.1 - Chrono breaks stuff
[`f2fae07f265ad915e42d9ccd3a861246ba6ec334`](https://github.com/OpenAngelArena/oaa/releases/tag/v0.29.1)

### Items
* Fixed Some Files pointing to renamed Files


## Update 0.30.0
[`5852e4d64c20141bb0dd2adcdf239665cc37bd26`](https://github.com/OpenAngelArena/oaa/releases/tag/v0.30.0)

### Items
* Fixed Siege Mode becoming unuseable if you die while it's active
* Added Missing Spell Icons

### Heroes
* Rewrite Rearm and make it not refresh Reflex Items 

### Bosses
* Lock out enemy Players from Tier 1 Bosses


## Hotfix 0.30.1
[`37fd9ed8ee4cb1d9149f0bd07087d0994791c1e4`](https://github.com/OpenAngelArena/oaa/releases/tag/v0.30.1)

### Items
* Fix Greater Travel Boots Pointing to renamed Files


## Update 0.31.0
[`e04c1ce79454e2b44ce6f0cd278997e91a2203b2`](https://github.com/OpenAngelArena/oaa/releases/tag/v0.31.0)

### Bosses
* Make Boss Resistance use Damage Block
* Set Charger Pillars to 1 Health

### UI
* Make Quick Stat Display more clear
* Handle leveling up talents properly in the UI


## Update 0.32.0
[`cdac449b268d84717d1731972ab657288afa2117`](https://github.com/OpenAngelArena/oaa/releases/tag/v0.32.0)

### Items
* Rewrite Stoneskin

### Bosses
* Fix Shilder's Shield due to boss resisitance

### Misc
* Changed Glyph to drop Ward instead


## Update 0.33.0
[`e02212ade6eb27bd18b90465da40abf905134ebf`](https://github.com/OpenAngelArena/oaa/releases/tag/v0.33.0)

### Creeps
* Reduce existing Creep Search Range for Creep Spawner

### Items
* Fix modifier and channel icons for Greater Travel Boots
* Added New Icons
  * [Pull Staff](https://github.com/OpenAngelArena/oaa/blob/09fa69fd32b3e47d72163f564ac11f26472b1f89/game/resource/flash3/images/items/custom/pull_staff.png)
  * [Force Staff](https://github.com/OpenAngelArena/oaa/blob/09fa69fd32b3e47d72163f564ac11f26472b1f89/game/resource/flash3/images/items/force_staff.png)

### Shops 
* Updated Main Shop Item List

### Bosses
* Added New Bosses to Tier 1.5
  * Simple Boss 1
  * Simple Boss 2
  * Simple Boss 5

  
## Update 0.34.0
[`b8a4c62535b2ff12bdbf178e52611faf9eda27c9`](https://github.com/OpenAngelArena/oaa/releases/tag/v0.34.0)
* Generated Translations

### Items
* Fixed a bunch of Modifiers being purgeable when they shouldn't be
* Fixed Pull Staff to make sure you land in a decent spot 

### Bosses
* Fixed Simple Boss Abilities

### Duels
* Purge runes after Duel

### UI
* Added In-Game Info Panel for new Players

### Map
* Cleared out the Area near the new Camp


## Update 0.35.0
[`3086a45785b41fd4526a00f4efe44993ba35bab9`](https://github.com/OpenAngelArena/oaa/releases/tag/v0.35.0)
* Generated Translations

### Items
* Satanic Core tweaks and fixes
* Heart Transplant fixes
* Fixed Lucience resetting on death
* Fixed Greater Power Treads, Greater Tranquil Boots, and active Greater Phase Boots and Siege Mode spitting out errors when upgrading them.
* Fixed Greater Power Treads splash damage not splashing off of or affecting spell immune creeps.
* Fixed Greater Phase Boots phase attack not proccing on spell immune creeps.
* Greater Phase Boots Phase attack now deals reduced damage
* Siege Mode now uses its alternative icon while active
* Make Pull Staff blockable by Linken's and similar effects
* Greater Power Treads
  * Increased Melee Split Damage from `10 20 30 40 50` to `20 30 40 50 60`
  * Increased Ranged Split Damage from `10 20 30 40 50` to `20 30 40 50 60`
* Invisibility Crystal
  * Increased Cooldown from `10.0` to `15.0`
  * Added Fade Delay of `0.8`
* Regeneration Crystal
  * Increased Cooldown from `10.0` to `20.0`

### Bosses
* Added Simple Boss 6 
* Added Simple Boss 7

### UI
* Move Game Info Button

## Update 0.35.1
[`9f3f93646552852abb9b07a15cc5e042088b3b12`](https://github.com/OpenAngelArena/oaa/releases/tag/v0.35.1)
* Generated Translations

### Items
* Added Sange and Yasha 3 and 4

### Shops
* Fixed Bloodstone not apprearing
* Replaced Maelstorm with Mjollnir


## Update 0.35.2
[`f398cd3867d32cc9f56c6fe7e92d04be1e2d8b5a`](https://github.com/OpenAngelArena/oaa/releases/tag/v0.35.2)
* Generated Tooltips

### Creeps
* Reduced Creeps' initial power by 20%
* Changed Progression so that the 20% weakening won't matter as much later
* Changed Ghost Spawn Chance from 1/3 to 1/5 and Black Dragon Spawn Chance from 1/5 to 1/8

### Items
* Fixed Siege Mode Damage Bonus not applying

### Heroes
* Fixed Winter Wyvers Cold Embrace not working

### Misc
* Make wards invisible unless you get close to them


## Update 1.0.0 - Public Alpha Release
[`b03ed6c01a792354fb36abe1bd69cd92a6104866`](https://github.com/OpenAngelArena/oaa/releases/tag/v1.0.0)
* Generated Tooltips

### Items
* Added new Icons
  * [Necronomicon 3](https://github.com/OpenAngelArena/oaa/blob/beccbb47d537c084599458716d5cff444385aa45/game/resource/flash3/images/items/custom/necronomicon_3.png)
  * [Necronomicon 4](https://github.com/OpenAngelArena/oaa/blob/beccbb47d537c084599458716d5cff444385aa45/game/resource/flash3/images/items/custom/necronomicon_4.png)
  * [Necronomicon 5](https://github.com/OpenAngelArena/oaa/blob/beccbb47d537c084599458716d5cff444385aa45/game/resource/flash3/images/items/custom/necronomicon_5.png)
  * [Necronomicon 6](https://github.com/OpenAngelArena/oaa/blob/beccbb47d537c084599458716d5cff444385aa45/game/resource/flash3/images/items/custom/necronomicon_6.png)
  * [Satanic Core 1](https://github.com/OpenAngelArena/oaa/blob/beccbb47d537c084599458716d5cff444385aa45/game/resource/flash3/images/items/custom/satanic_core_1.png)
  * [Satanic Core 2](https://github.com/OpenAngelArena/oaa/blob/beccbb47d537c084599458716d5cff444385aa45/game/resource/flash3/images/items/custom/satanic_core_2.png)
  * [Satanic Core 3](https://github.com/OpenAngelArena/oaa/blob/beccbb47d537c084599458716d5cff444385aa45/game/resource/flash3/images/items/custom/satanic_core_3.png)

### Bosses
* Added Simple Boss 3


## Update 1.0.1
[`e3a6ffc7eb9898f1b5b10987852a72aba1d6d4db`](https://github.com/OpenAngelArena/oaa/releases/tag/v1.0.1)

### Heroes
* Keeper of The Light
  * Illuminate
    * Increased Damage per Second from `100.0 100.0 100.0 100.0 100.0 100.0` to `100.0 100.0 100.0 100.0 120.0 215.0`

### Duels
* Prevent people from getting stuck in trees or game ending after duel

### Misc
* Gave Fountain Auto Doom on Attack


## Update 1.1.0-0
[`5432a954a6a2522b49c9ee2f3ebd01aa01fd43b2`](https://github.com/OpenAngelArena/oaa/releases/tag/v1.1.0-0)
* Generated Tooltips

### Items
* Fix refresher orb 2 not having an Icon
* Rework Reflection Shards
* Greater Guardian Greaves now give you Creep Assist Gold

### Shops
* Replaced Bloodstone with Bloodthorn

## Update 1.1.0-1
[`06e762c0efb79e439131adf502685bb6c1d596a7`](https://github.com/OpenAngelArena/oaa/releases/tag/v1.1.0-1)
* Generated Tooltips
* Applied Dota Patch 7.06c

### Items
* Added audiovisual effects for Teleportation Shard blink

### Bosses
* Buff Simple Bosses and increase their Model Size

### UI
* Move Info Panel Button to be closer to Stats Display


## Template
```Markdown
## <Type> <Tag> - <Name>
[`<commit>`](link to tag)
### Creeps
### Cave
### Items
### Shop
### Heroes
### Bosses
### Duels
### UI
### Bots
### Map
### GetDotaStats
### Misc
```
```Markdown
* 'what' changed
  * explicit change
    * detailed description
```
