-- These values are starting and minimum values for neutral creeps when 5vs5; values increase over time (check creep_power.lua)
-- "creep name", Health, Mana, Damage, Armor, Gold Bounty, Exp Bounty
CreepTypes = {
  -- 1 "easy camp" (CreepMax is 6 for all easy camps)
  {
    {                                              --HP   MANA  DMG   ARM   GOLD  EXP  -- expected gold is 85 and XP is 90
      {"npc_dota_neutral_custom_big_wolf",          480,  300,  35,   1.5,   35,  40},
      {"npc_dota_neutral_custom_small_wolf",        320,  200,  15,   0.5,   25,  25},
      {"npc_dota_neutral_custom_small_wolf",        320,  200,  15,   0.5,   25,  25}
    },
    {
      {"npc_dota_neutral_custom_kobold_foreman",    450,  300,  30,    1,    35,  35},
      {"npc_dota_neutral_custom_kobold_soldier",    380,  200,  20,    1,    30,  30},
      {"npc_dota_neutral_custom_kobold",            250,  200,  10,   0.5,   20,  25}
    },
    {
      {"npc_dota_neutral_dark_troll",               400,  200,  65,   0.75,  35,  35}, -- has Piercing
      {"npc_dota_neutral_forest_troll_berserker",   350,    0,  35,   0.75,  30,  30}, -- has Piercing
      {"npc_dota_neutral_forest_troll_high_priest", 300,  500,  15,   0.5,   20,  25}  -- has Piercing
    },
    {
      {"npc_dota_neutral_froglet",                  480,  300,  30,   1.5,   35,  40},
      {"npc_dota_neutral_tadpole",                  320,  200,  20,   0.5,   25,  25},
      {"npc_dota_neutral_tadpole",                  320,  200,  20,   0.5,   25,  25}
    }
  },
    -- 2 "medium camp" (CreepMax is 6 for all medium camps)
  {
    {                                              --HP   MANA  DMG   ARM   GOLD  EXP  -- expected gold is 60 and XP is 140
      {"npc_dota_neutral_custom_harpy_storm",       650,  300,  35,   1.3,   35,  80},
      {"npc_dota_neutral_custom_harpy_scout",       400,  200,  30,     1,   25,  60}
    },
    {
      {"npc_dota_neutral_custom_mud_golem",         525,    0,  35,    1,    15,  28}, -- multiply gold value by 2 and xp value by 2.5 because they split
      {"npc_dota_neutral_custom_mud_golem",         525,    0,  35,    1,    15,  28}
    },
    {
      {"npc_dota_neutral_custom_blue_tomato",       650,  300,  40,   1.3,   35,  80},
      {"npc_dota_neutral_custom_blue_potato",       400,    0,  35,   1.3,   25,  60}
    }
  },
    -- 3 "hard camp" (CreepMax is 6 for all hard camps)
  {
    {                                              --HP   MANA  DMG   ARM   GOLD  EXP  -- expected gold is 95 and XP 100
      {"npc_dota_neutral_custom_ghost",             800,  300,  40,   1.5,   45,  50}, -- has Piercing
      {"npc_dota_neutral_custom_small_ghost",       400,  200,  30,    1,    25,  25},
      {"npc_dota_neutral_custom_small_ghost",       400,  200,  30,    1,    25,  25}
    },
    {
      {"npc_dota_neutral_custom_centaur_khan",      800,  300,  50,   1.5,   45,  50},
      {"npc_dota_neutral_custom_small_centaur",     400,    0,  30,    1,    25,  25},
      {"npc_dota_neutral_custom_small_centaur",     400,    0,  30,    1,    25,  25}
    },
    {
      {"npc_dota_neutral_grown_frog_mage",          800,  350,  40,   1.5,   45,  50},
      {"npc_dota_neutral_grown_frog",               400,  350,  30,    1,    25,  25},
      {"npc_dota_neutral_grown_frog",               400,  350,  30,    1,    25,  25}
    },
    {
      {"npc_dota_neutral_satyr_hellcaller",         800,  400,  50,   1.5,   45,  50},
      {"npc_dota_neutral_satyr_soulstealer",        500,  600,  30,    1,    30,  30},
      {"npc_dota_neutral_satyr_trickster",          300,  500,  10,    1,    20,  25}
    }
  },
   -- 4 "ancient camp" (CreepMax is 8 for ancient camps)
  {
    {                                               --HP  MANA  DMG   ARM   GOLD  EXP  -- expected gold is 55-95 and XP is 115
      {"npc_dota_neutral_granite_golem",           1275,    0,  70,    2,   95,  115}
    },
    {
      {"npc_dota_neutral_rock_golem",              1200,    0,  40,    1,   55,  115}
    },
    {
      {"npc_dota_neutral_black_dragon",            1275,  500,  60,    3,   95,  115}
    },
    {
      {"npc_dota_neutral_prowler_acolyte",         1200,    0,  40,    3,   55,  115}
    },
    {
      {"npc_dota_neutral_ancient_frog",            1200,  450,  40,    3,   55,  115}
    },
    {
      {"npc_dota_neutral_ancient_frog_mage",       1275,  450,  60,    3,   95,  115}
    },
  },
   -- 5 "solo ancient corner camp" (CreepMax is 1)
  {
    {
      {"npc_dota_neutral_custom_black_dragon",     1500,  300,  80,    3,  105,  150}
    }
  },
   -- 6 "solo ancient mid camp" (CreepMax is 1)
  {
    {
      {"npc_dota_mini_roshan",                     1500,    0,  80,    5,  205,  25}
    },
    {
      {"npc_dota_neutral_custom_pine_cone",        1500,  300,  80,   10,  205,  25}
    },
    {
      {"npc_dota_neutral_custom_ogre_mauler",      1500,  400,  80,   10,  205,  25}
    },
  },
   -- 7 "solo prowler - part of the ancient camp" (CreepMax is 1)
  {
    {
      {"npc_dota_neutral_prowler_shaman",          1275,  400,  70,    3,   95,  115}
    }
  }
}
