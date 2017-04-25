
function MakeKFunctionForIndexPowerOffset (index, power, offset)
  return function (k)
    return CreepPower:GetPowerForMinute(k * power + offset)[index]
  end
end

local BaseCreepPowerMultiplier = 18
local BaseCreepXPGOLDMultiplier = 8

local BaseMultipliers = {
  -- CreepPower:GetPowerForMinute

  --  minute,                                   -- minute
  --  ((minute / 8) ^ 2 / 75) + 1,              -- hp
  --  minute,                                   -- mana
  --  (minute / 20) + 1,                        -- damage
  --  minute ^ 0.5,                             -- armor
  --  (minute / 2) + 1,                         -- gold
  --  ((21 * minute^2 - 19 * minute + 3002) / 3002) * self.numPlayersXPFactor * multFactor -- xp
  mana = partial(MakeKFunctionForIndexPowerOffset, 3),
  hp = partial(MakeKFunctionForIndexPowerOffset, 2),
  damage = partial(MakeKFunctionForIndexPowerOffset, 4),
  armour = partial(MakeKFunctionForIndexPowerOffset, 5),
  gold = partial(MakeKFunctionForIndexPowerOffset, 5),
  exp = partial(MakeKFunctionForIndexPowerOffset, 6)
}

-- "creep name", Health, Mana, Damage, Armor, Gold Bounty, Exp Bounty
CaveTypes = {
  [1] = { -- 1 "Howl's it Going?"
    {                                         --HP    MANA  DMG   ARM   GOLD  EXP
      units = {
        {"npc_dota_neutral_alpha_wolf",           240,  0,    33,   1,    19,   60, 10},
        {"npc_dota_neutral_alpha_wolf",           240,  0,    33,   1,    19,   60, 10},
        {"npc_dota_neutral_alpha_wolf",           240,  0,    33,   1,    19,   60, 10},
        {"npc_dota_neutral_alpha_wolf",           240,  0,    33,   1,    19,   60, 10},
        {"npc_dota_neutral_alpha_wolf",           240,  0,    33,   1,    19,   60, 10},
        {"npc_dota_neutral_alpha_wolf",           240,  0,    33,   1,    19,   60, 10},
        {"npc_dota_neutral_alpha_wolf",           240,  0,    33,   1,    19,   60, 10},
        {"npc_dota_neutral_alpha_wolf",           240,  0,    33,   1,    19,   60, 10},
        {"npc_dota_neutral_alpha_wolf",           240,  0,    33,   1,    19,   60, 10},
        {"npc_dota_neutral_alpha_wolf",           240,  0,    33,   1,    19,   60, 10},
      },
      multiplier = {
        mana = BaseMultipliers.mana(BaseCreepPowerMultiplier, 0), -- function (k) return 1 end,
        hp = BaseMultipliers.hp(BaseCreepPowerMultiplier, 0), -- function (k) return 1 end,
        damage = BaseMultipliers.damage(BaseCreepPowerMultiplier, 0), -- function (k) return 1 end,
        armour = BaseMultipliers.armour(BaseCreepPowerMultiplier, 0), -- function (k) return 1 end,
        gold = BaseMultipliers.gold(BaseCreepXPGOLDMultiplier, 0), -- function (k) return (16 * k + 9) / 9 end,
        exp = BaseMultipliers.exp(BaseCreepXPGOLDMultiplier, 0), -- function (k) return (168 * k^2 + 2 * k + 15) / 15 end,
        magicResist = function(k) return 1 end,
      }
    }
  },
  [2] = { -- 2 "Horse Tomatina"
    {                                                    --HP  MANA  DMG  ARM  GOLD  EXP
      units = {
        {"npc_dota_neutral_polar_furbolg_ursa_warrior",  950,    0,  55,   1,  19, 60, 30},
        {"npc_dota_neutral_polar_furbolg_ursa_warrior",  950,    0,  55,   1,  19, 60, 30},
        {"npc_dota_neutral_polar_furbolg_ursa_warrior",  950,    0,  55,   1,  19, 60, 30},
        {"npc_dota_neutral_polar_furbolg_ursa_warrior",  950,    0,  55,   1,  19, 60, 30},
        {"npc_dota_neutral_polar_furbolg_ursa_warrior",  950,    0,  55,   1,  19, 60, 30},
        {"npc_dota_neutral_centaur_khan",               1100,    0,  55,   1,  19, 60, 30},
        {"npc_dota_neutral_centaur_khan",               1100,    0,  55,   1,  19, 60, 30},
        {"npc_dota_neutral_centaur_khan",               1100,    0,  55,   1,  19, 60, 30},
        {"npc_dota_neutral_centaur_khan",               1100,    0,  55,   1,  19, 60, 30},
        {"npc_dota_neutral_centaur_khan",               1100,    0,  55,   1,  19, 60, 30},
      },
      multiplier = {
        mana = BaseMultipliers.mana(BaseCreepPowerMultiplier, 2), -- function (k) return 1 end,
        hp = BaseMultipliers.hp(BaseCreepPowerMultiplier, 2), -- function (k) return 1 end,
        damage = BaseMultipliers.damage(BaseCreepPowerMultiplier, 2), -- function (k) return 1 end,
        armour = BaseMultipliers.armour(BaseCreepPowerMultiplier, 2), -- function (k) return 1 end,
        gold = BaseMultipliers.gold(BaseCreepXPGOLDMultiplier, 2), -- function (k) return (16 * k + 9) / 9 end,
        exp = BaseMultipliers.exp(BaseCreepXPGOLDMultiplier, 2), -- function (k) return (84 * k^2 + 43  * k + 13) / 13 end,
        magicResist = function(k) return 1 end,
      }
    }
  },
  [3] = { -- 3 "Draggin' it Around"
    {                                         --HP    MANA  DMG   ARM   GOLD  EXP
      units = {
        {"npc_dota_neutral_black_drake",      1600,      0,  65,   1,  24, 75, 50},
        {"npc_dota_neutral_black_drake",      1600,      0,  65,   1,  24, 75, 50},
        {"npc_dota_neutral_black_drake",      1600,      0,  65,   1,  24, 75, 50},
        {"npc_dota_neutral_black_drake",      1600,      0,  65,   1,  24, 75, 50},
        {"npc_dota_neutral_black_drake",      1600,      0,  65,   1,  24, 75, 50},
        {"npc_dota_neutral_black_drake",      1600,      0,  65,   1,  24, 75, 50},
        {"npc_dota_neutral_black_drake",      1600,      0,  65,   1,  24, 75, 50},
        {"npc_dota_neutral_black_drake",      1600,      0,  65,   1,  24, 75, 50},
      },
      multiplier = {
        mana = BaseMultipliers.mana(BaseCreepPowerMultiplier, 4), -- function (k) return 1 end,
        hp = BaseMultipliers.hp(BaseCreepPowerMultiplier, 4), -- function (k) return 1 end,
        damage = BaseMultipliers.damage(BaseCreepPowerMultiplier, 4), -- function (k) return 1 end,
        armour = BaseMultipliers.armour(BaseCreepPowerMultiplier, 4), -- function (k) return 1 end,
        gold = BaseMultipliers.gold(BaseCreepXPGOLDMultiplier, 4), -- function (k) return (16 * k + 13) / 13 end,
        exp = BaseMultipliers.exp(BaseCreepXPGOLDMultiplier, 4), -- function (k) return (84 * k^2 + 85 * k + 29) / 29 end,
        magicResist = function(k) return 1 end,
      }
    }
  },
  [4] = { -- 4 "Roashes Everywhere"
    {                                         --HP    MANA  DMG   ARM   GOLD  EXP
      units = {
        {"npc_dota_mini_roshan",              5500,   0,    65,   15,   95,  300, 70},
        {"npc_dota_mini_roshan",              5500,   0,    65,   15,   95,  300, 70},
      },
      multiplier = {
        mana = BaseMultipliers.mana(BaseCreepPowerMultiplier, 6), -- function (k) return 1 end,
        hp = BaseMultipliers.hp(BaseCreepPowerMultiplier, 6), -- function (k) return 1 end,
        damage = BaseMultipliers.damage(BaseCreepPowerMultiplier, 6), -- function (k) return 1 end,
        armour = BaseMultipliers.armour(BaseCreepPowerMultiplier, 6), -- function (k) return 1 end,
        gold = function (k) return 0 end,
        exp = BaseMultipliers.exp(BaseCreepXPGOLDMultiplier, 6), -- function (k) return (56 * k^2 + 85 * k + 37) / 37 end,
        magicResist = function(k) return 1 end,
      }
    }
  }
}
