
local BaseMultipliers = {
  -- CreepPower:GetPowerForMinute

  --  minute,                                   -- minute
  --  ((minute / 8) ^ 2 / 75) + 1,              -- hp
  --  minute,                                   -- mana
  --  (minute / 20) + 1,                        -- damage
  --  minute ^ 0.5,                             -- armor
  --  (minute / 2) + 1,                         -- gold
  --  ((21 * minute^2 - 19 * minute + 3002) / 3002) * self.numPlayersXPFactor * multFactor -- xp
  mana = function (k) return CreepPower:GetPowerForMinute(k * 8)[3] end,
  hp = function (k) return CreepPower:GetPowerForMinute(k * 8)[2] end,
  damage = function (k) return CreepPower:GetPowerForMinute(k * 8)[4] end,
  armour = function (k) return CreepPower:GetPowerForMinute(k * 8)[5] end,
  gold = function (k) return CreepPower:GetPowerForMinute(k * 8)[5] end,
  exp = function (k) return CreepPower:GetPowerForMinute(k * 8)[6] end
}

-- "creep name", Health, Mana, Damage, Armor, Gold Bounty, Exp Bounty
CaveTypes = {
  [1] = { -- 1 "Howl's it Going?"
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
        mana = BaseMultipliers.mana, -- function (k) return 1 end,
        hp = BaseMultipliers.hp, -- function (k) return 1 end,
        damage = BaseMultipliers.damage, -- function (k) return 1 end,
        armour = BaseMultipliers.armour, -- function (k) return 1 end,
        gold = BaseMultipliers.gold, -- function (k) return (16 * k + 9) / 9 end,
        exp = BaseMultipliers.exp, -- function (k) return (168 * k^2 + 2 * k + 15) / 15 end,
      }
    }
  },
  [2] = { -- 2 "Horse Tomatina"
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
        mana = BaseMultipliers.mana, -- function (k) return 1 end,
        hp = BaseMultipliers.hp, -- function (k) return 1 end,
        damage = BaseMultipliers.damage, -- function (k) return 1 end,
        armour = BaseMultipliers.armour, -- function (k) return 1 end,
        gold = BaseMultipliers.gold, -- function (k) return (16 * k + 9) / 9 end,
        exp = BaseMultipliers.exp, -- function (k) return (84 * k^2 + 43  * k + 13) / 13 end,
      }
    }
  },
  [3] = { -- 3 "Draggin' it Around"
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
        mana = BaseMultipliers.mana, -- function (k) return 1 end,
        hp = BaseMultipliers.hp, -- function (k) return 1 end,
        damage = BaseMultipliers.damage, -- function (k) return 1 end,
        armour = BaseMultipliers.armour, -- function (k) return 1 end,
        gold = BaseMultipliers.gold, -- function (k) return (16 * k + 13) / 13 end,
        exp = BaseMultipliers.exp, -- function (k) return (84 * k^2 + 85 * k + 29) / 29 end,
      }
    }
  },
  [4] = { -- 4 "Roashes Everywhere"
    {                                         --HP    MANA  DMG   ARM   GOLD  EXP
      units = {
        {"npc_dota_mini_roshan",              5500,   0,    65,   15,   646,  753.5},
        {"npc_dota_mini_roshan",              5500,   0,    65,   15,   646,  753.5},
      },
      multiplier = {
        mana = BaseMultipliers.mana, -- function (k) return 1 end,
        hp = BaseMultipliers.hp, -- function (k) return 1 end,
        damage = BaseMultipliers.damage, -- function (k) return 1 end,
        armour = BaseMultipliers.armour, -- function (k) return 1 end,
        gold = function (k) return 0 end,
        exp = BaseMultipliers.exp, -- function (k) return (56 * k^2 + 85 * k + 37) / 37 end,
      }
    }
  }
}
