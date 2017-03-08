
-- "creep name", Health, Mana, Damage, Armor, Gold Bounty, Exp Bounty
CreepTypes = {
  -- 1 "easy camp"
  {
    {                                         --HP    MANA  DMG   ARM   GOLD  EXP
      {"npc_dota_neutral_kobold",               240,  0,    10,   0,    15,   25},
      {"npc_dota_neutral_kobold",               240,  0,    10,   0,    15,   25},
      {"npc_dota_neutral_kobold_taskmaster",    400,  0,    14,   1,    15,   25},
      {"npc_dota_neutral_kobold_tunneler",      325,  0,    14,   1,    15,   25}
    }
  },
    -- 2 "medium camp"
  {
    {                                         --HP    MANA  DMG   ARM   GOLD  EXP
      {"npc_dota_neutral_harpy_storm",          550,  400,  33,   2,    23,   35},
      {"npc_dota_neutral_harpy_storm",          550,  400,  33,   2,    23,   35},
      {"npc_dota_neutral_harpy_scout",          400,  0,    31,   1,    23,   35},
      {"npc_dota_neutral_harpy_scout",          400,  0,    31,   1,    23,   35}
    }
  },
    -- 3 "hard camp"
  {
    {                                         --HP    MANA  DMG   ARM   GOLD  EXP
      {"npc_dota_neutral_big_thunder_lizard",   1400, 400,  62,   2,    45,   40},
      {"npc_dota_neutral_small_thunder_lizard", 800,  400,  44,   2,    45,   40},
      {"npc_dota_neutral_small_thunder_lizard", 800,  400,  44,   2,    45,   40},
    },
    {
      {"npc_dota_neutral_rock_golem",           800,  400,  31,   4,    45,   40},
      {"npc_dota_neutral_rock_golem",           800,  400,  31,   4,    45,   40},
      {"npc_dota_neutral_granite_golem",        1700, 600,  82,   8,    45,   40}
    }
      -- {"npc_dota_neutral_jungle_stalker",       1600, 400,  55,   2,    61,   40},
  }
  -- ...
}
