
-- "creep name", Health, Mana, Damage, Armor, Gold Bounty, Exp Bounty
CaveTypes = {
  room1 = { -- 1 "Howl's it Going?"
    {                                         --HP    MANA  DMG   ARM   GOLD  EXP
      units = {
        {"npc_dota_neutral_alpha_wolf",           240,  0,    33,   0,    28,   120},
        {"npc_dota_neutral_alpha_wolf",           240,  0,    33,   0,    28,   120},
        {"npc_dota_neutral_alpha_wolf",           240,  0,    33,   0,    28,   120},
        {"npc_dota_neutral_alpha_wolf",           240,  0,    33,   0,    28,   120},
        {"npc_dota_neutral_alpha_wolf",           240,  0,    33,   0,    28,   120},
        {"npc_dota_neutral_alpha_wolf",           240,  0,    33,   0,    28,   120},
        {"npc_dota_neutral_alpha_wolf",           240,  0,    33,   0,    28,   120},
        {"npc_dota_neutral_alpha_wolf",           240,  0,    33,   0,    28,   120},
        {"npc_dota_neutral_alpha_wolf",           240,  0,    33,   0,    28,   120},
        {"npc_dota_neutral_alpha_wolf",           240,  0,    33,   0,    28,   120},
      },
      multiplier = {
        mana = function (k) return k end,
        hp = function (k) return k end,
      damage = function (k) return k end,
      armour = function (k) return k end,
      gold = function (k) return (16 * k + 9) / 9 end,
      exp = function (k) return (168 * k^2 + 2 * k + 15) / 15 end,
    }
  }
},
room2 = { -- 2 "Horse Tomatina"
  {                                                    --HP  MANA  DMG  ARM  GOLD  EXP
    units = {
      {"npc_dota_neutral_polar_furbolg_ursa_warrior",  950,    0,  55,   0,  68.4, 123.5},
      {"npc_dota_neutral_polar_furbolg_ursa_warrior",  950,    0,  55,   0,  68.4, 123.5},
      {"npc_dota_neutral_polar_furbolg_ursa_warrior",  950,    0,  55,   0,  68.4, 123.5},
      {"npc_dota_neutral_polar_furbolg_ursa_warrior",  950,    0,  55,   0,  68.4, 123.5},
      {"npc_dota_neutral_polar_furbolg_ursa_warrior",  950,    0,  55,   0,  68.4, 123.5},
      {"npc_dota_neutral_centaur_khan",               1100,    0,  55,   0,  68.4, 123.5},
      {"npc_dota_neutral_centaur_khan",               1100,    0,  55,   0,  68.4, 123.5},
      {"npc_dota_neutral_centaur_khan",               1100,    0,  55,   0,  68.4, 123.5},
      {"npc_dota_neutral_centaur_khan",               1100,    0,  55,   0,  68.4, 123.5},
      {"npc_dota_neutral_centaur_khan",               1100,    0,  55,   0,  68.4, 123.5},
    },
    multiplier = {
      mana = function (k) return k end,
      hp = function (k) return k end,
      damage = function (k) return k end,
      armour = function (k) return k end,
      gold = function (k) return (16 * k + 9) / 9 end,
      exp = function (k) return (84 * k^2 + 43  * k + 13) / 13 end,
    }
  }
},
room3 = { -- 3 "Draggin' it Around"
  {                                         --HP    MANA  DMG   ARM   GOLD  EXP
    units = {
      {"npc_dota_neutral_black_drake",      950,      0,  45,   -1,  136.5, 167.25},
      {"npc_dota_neutral_black_drake",      950,      0,  45,   -1,  136.5, 167.25},
      {"npc_dota_neutral_black_drake",      950,      0,  45,   -1,  136.5, 167.25},
      {"npc_dota_neutral_black_drake",      950,      0,  45,   -1,  136.5, 167.25},
      {"npc_dota_neutral_black_drake",      950,      0,  45,   -1,  136.5, 167.25},
      {"npc_dota_neutral_black_drake",      950,      0,  45,   -1,  136.5, 167.25},
      {"npc_dota_neutral_black_drake",      950,      0,  45,   -1,  136.5, 167.25},
      {"npc_dota_neutral_black_drake",      950,      0,  45,   -1,  136.5, 167.25},
    },
    multiplier = {
      mana = function (k) return k end,
      hp = function (k) return k end,
      damage = function (k) return k end,
      armour = function (k) return k end,
      gold = function (k) return (16 * k + 13) / 13 end,
      exp = function (k) return (84 * k^2 + 85 * k + 29) / 29 end,
      }
    }
  },
  room4 = { -- 4 "Roashes Everywhere"
    {                                         --HP    MANA  DMG   ARM   GOLD  EXP
      units = {
        {"npc_dota_mini_roshan",              5500,   0,    65,   15,   646,  753.5},
        {"npc_dota_mini_roshan",              5500,   0,    65,   15,   646,  753.5},
      },
      multiplier = {
        mana = function (k) return k end,
        hp = function (k) return k end,
        damage = function (k) return k end,
        armour = function (k) return k end,
        gold = function (k) return (16 * k + 17) / 17 end,
        exp = function (k) return (56 * k^2 + 85 * k + 37) / 37 end,
      }
    }
  }
}
