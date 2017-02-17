
-- "creep name", Health, Mana, Damage, Armor, Gold Bounty, Exp Bounty
CreepTypes = {
  -- 1 "easy camp"
  {
    {                                         --HP    MANA  DMG   ARM   GOLD  EXP
      {"npc_dota_neutral_kobold",               240,  0,    10,   0,    8,    25},
      {"npc_dota_neutral_kobold",               240,  0,    10,   0,    8,    25},
      {"npc_dota_neutral_kobold_taskmaster",    400,  0,    14,   1,    26,   25},
      {"npc_dota_neutral_kobold_tunneler",      325,  0,    14,   1,    18,   25}
    }
  },
    -- 2 "medium camp"
  {
    {                                         --HP    MANA  DMG   ARM   GOLD  EXP
      {"npc_dota_neutral_harpy_storm",          550,  400,  33,   2,    35,   35},
      {"npc_dota_neutral_harpy_storm",          550,  400,  33,   2,    35,   35},
      {"npc_dota_neutral_harpy_scout",          400,  0,    31,   1,    25,   35},
      {"npc_dota_neutral_harpy_scout",          400,  0,    31,   1,    25,   35}
    }
  },
    -- 3 "hard camp"
  {
    {                                         --HP    MANA  DMG   ARM   GOLD  EXP
      {"npc_dota_neutral_big_thunder_lizard",   1400, 400,  62,   2,    93,   40},
      {"npc_dota_neutral_small_thunder_lizard", 800,  400,  44,   2,    65,   40},
      {"npc_dota_neutral_small_thunder_lizard", 800,  400,  44,   2,    65,   40},
    },
    {
      {"npc_dota_neutral_rock_golem",           800,  400,  31,   4,    58,   40},
      {"npc_dota_neutral_rock_golem",           800,  400,  31,   4,    58,   40},
      {"npc_dota_neutral_granite_golem",        1700, 600,  82,   8,    114,  40}
    }
      -- {"npc_dota_neutral_jungle_stalker",       1600, 400,  55,   2,    61,   40},
  }
  -- ...
}
