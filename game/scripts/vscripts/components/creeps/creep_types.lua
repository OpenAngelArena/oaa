
-- "creep name", Health, Mana, Damage, Armor, Gold Bounty, Exp Bounty
CreepTypes = {
  -- 1 "easy camp"
  {
    {                                              --HP   MANA  DMG   ARM   GOLD  EXP
      {"npc_dota_neutral_custom_small_wolf",        400,  160,  15,    1,    31,  30},
      {"npc_dota_neutral_custom_small_wolf",        400,  160,  15,    1,    31,  30},
      {"npc_dota_neutral_custom_big_wolf",          600,  480,  35,    2,    85,  71}
    },
    {
      {"npc_dota_neutral_custom_kobold_foreman",    560,  500,  16,    1,    40,  35},
      {"npc_dota_neutral_custom_kobold_soldier",    480,    0,  12,    1,    36,  35},
      {"npc_dota_neutral_custom_kobold",            280,    0,  10,   0.5,   26,  30}
    },
  },
    -- 2 "medium camp"
  {
    {                                              --HP   MANA  DMG   ARM   GOLD  EXP
      {"npc_dota_neutral_custom_harpy_storm",       560,  500,  24,   1.2,   45,  82}, --expected gold is 75 and XP is 272
      {"npc_dota_neutral_custom_harpy_storm",       560,  500,  24,   1.2,   45,  82},
      {"npc_dota_neutral_custom_harpy_storm",       560,  500,  24,   1.2,   45,  82},
      {"npc_dota_neutral_custom_harpy_storm",       560,  500,  24,   1.2,   45,  82},
      {"npc_dota_neutral_custom_harpy_scout",       440,    0,  40,   0.7,   40,  61}
    },
    {
      {"npc_dota_neutral_custom_mud_golem",         480,    0,  12,    1,    33,  100},
      {"npc_dota_neutral_custom_mud_golem",         480,    0,  12,    1,    33,  100}
    },
    {
      {"npc_dota_neutral_custom_blue_potato",       480,    0,  28,   1.3,   50,  75},
      {"npc_dota_neutral_custom_blue_potato",       480,    0,  28,   1.3,   50,  75},
      {"npc_dota_neutral_custom_blue_tomato",       800,  500,  28,   1.3,   50,  75}
    }
  },
    -- 3 "hard camp"
  {
    {                                              --HP   MANA  DMG   ARM   GOLD  EXP
      {"npc_dota_neutral_custom_ghost",             800,  400,  30,   1.5,   76,  61}, --expected gold is 113 and XP 121
      {"npc_dota_neutral_custom_ghost",             800,  400,  30,   1.5,   76,  61}
    },
    {
      {"npc_dota_neutral_custom_centaur_khan",      800,  400,  30,   1.5,   76,  61},
      {"npc_dota_neutral_custom_small_centaur",     600,  240,  20,   0.8,   37,  60}
    },
    {
      {"npc_dota_neutral_satyr_trickster",          350,  160,  10,    1,    28,  27},
      {"npc_dota_neutral_satyr_soulstealer",        450,  480,  20,    1,    38,  40},
      {"npc_dota_neutral_satyr_hellcaller",         550,  480,  30,   1.5,   51,  53}
    }
  },
   -- 4 "ancient camp"
  {
    {
      {"npc_dota_neutral_prowler_acolyte",          900,    0,  30,    1,    79,  51},
      {"npc_dota_neutral_prowler_shaman",          1200,    0,  60,    2,   120, 100}
    }
  },
   -- 5 "solo camp" radiant
  {
    {
      {"npc_dota_neutral_custom_black_dragon",     1500,  500,  70,    3,   152, 156}
    }
  }
}
