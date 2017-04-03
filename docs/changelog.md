# OAA Changelog
Changelog starts at `2017-03-24 16:40 UTC+0100`

Last Update: `2017-03-27 22:47 UTC+0200`

## Translation Progress
* Chinese: 0%
* German: 27%
* Portuguese: 77%
* Russian: 65%
* Spanish: 0%

## Changes until now
* Added new Map
* Added Level 5 and 6 for normal Abilities and Level 4 and 5 for Ultimates to all Heros
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
`07a33e56577acdf503c608b4a5a966b5e4d3a403`
### Items
* Buff Travel Boots
  * Increased GPM from `60 90 120 150 180` to `60 120 240 480 960`

## Update 0.1.0 2017-03-27
`b1ea9ff41c15c80b8ec50186aca7d4fa0e91a890`
### Items
* Buffed Echo Sabre 
  * Reduced Cooldown from `5.0 5.0 5.0 5.0` to `5.0 4.0 3.0 2.0`
* Added Reverse Compatibility of Upgrade Cores to Reflex Cores
* Changed Stoneskin Armour
  * Added 1.5 second delay to Toggle
  * Fixed Toggle not respecting Cooldown
* Added Preemptive Purge Item
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
  * Reduced Split Damage from `40` to `10 20 30 40 50`
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
    * Reduced Duration from `3 4 5 6 8 10` to `3 4 5 6 7 8`
    * Reduced Damage from `120 160 200 240 400 1000` to `120 160 200 240 400 800`
* Nerfed Centaur
  * Stampede
    * Reduced Damage per Strength from `1.0 2.0 3.0 5.0 8.0` to `1.0 2.0 3.0 4.5 6.5`
* Nerfed Shadow Fiend
  * Necromastery
    * Reduced Damage per Soul from `2 2 2 2 3 5` to `2 2 2 2 2 2`
  * Requiem of Souls
    * Reduced Damage from `80 120 160 320 1000` to `80 120 160 320 640`
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
    * Reduced Mana per Hit from `28 40 52 64 88 184` to `28 40 52 64 78 96`
  * Mana Void
    * Reduced Damage per missing Mana from `0.6 0.85 1.1 1.6 3.6` to `0.6 0.85 1.1 1.4 1.9`
* Buffed Bristleback
  * Quill Spray
    * Increased Damage from `550.0` to `550.0 550.0 550.0 550.0 1100.0 2200.0`
* Nerfed Dragon Knight
  * Dragon Tail
    * Reduced Damage from `25 50 75 100 150 350` to `25 50 75 100 150 225`
* Nerfed Phantom Assasin
  * Coup de Grace
    * Reduced Crit Damage from `230 340 450 650 1000` to `230 340 450 560 750`
* Nerfed Phantom Lancer
  * Juxtapose
    * Reduced Max Illusions from `5 7 9 13 22` to `5 7 9 11 15`
* Buffed Ursa
  * Enrage
    * Reduced Scepter Cooldown from `30 24 18 18 18` to `30 24 18 15 12`


### Bosses
* Added Reflex Cores as guaranteed Drop of Tier 1 Bosses
* Nerfed Tier 2 Boss
  * Reduced Damage from `3750` to `255`
  * Reduced Health from `100000` to `75000`
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
`d664aa3b85f464b04ae5fe32a9b9c65fa645c6d9`
### Items
* Fixed Greater Travel Boots not working

## Update 0.2.0 2017-03-27
`ac9347374cde1186dc45dc9f282f8de5f7be84a7`
### Items
* Added Matyr's Mail
* Fixed Charge BKB Recipe
* Added Preemptive Core 3B

### Creeps
* Decreased XP for all Camps
  * Decreased Easy Camp XP from `25` to `20`
  * Decreased Medium Camp XP from `35` to `25`
  * Decreased Hard Camp XP from `40` to `30`

## Update 0.3.0
``
### Creeps
* Changed Creep XP
  * XP now also depends on Player Count

### Items
* Added Shroud of Shadows 
  * Make self/ally invisible + Not attackable
* Fixed Damage Reduction Tooltip of Preemptive Reflex Core
* Added Postactive Reflex Core
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

### Misc
* Added Automatic Courier Spawning before Game Start




## Template
```Markdown
## <Name> <Tag>
`<commit>`
### Creeps
### Items
### Heroes
### Bosses
### Duels
### UI
### Misc
```
```Markdown
* 'what' changed
  * explicit change
    * detailed description
```
