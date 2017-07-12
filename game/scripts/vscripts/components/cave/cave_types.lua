
function MakeKFunctionForIndexPowerOffset (index, speed, offset, power)
  return function (k)
    return 1 + power*(CreepPower:GetBasePowerForMinute(k * speed + offset, 1)[index] - 1)
  end
end

local BaseCreepPowerMultiplier = 12
local BaseCreepXPGOLDMultiplier = 12
local CaveProgressionBuff = 6
local CaveXPGOLDBuff = 2

local BaseMultipliers = {
  -- CreepPower:GetBasePowerForMinute

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
  gold = partial(MakeKFunctionForIndexPowerOffset, 6),
  exp = partial(MakeKFunctionForIndexPowerOffset, 7)
}

-- "creep name", Health, Mana, Damage, Armor, Gold Bounty, Exp Bounty
CaveTypes = {
  [1] = { -- 1 "Howl's it Going?"
    {                                            --HP  MANA  DMG   ARM   GOLD  EXP RESIST
      units = {
        {"npc_dota_neutral_custom_big_pupper",    400,  0,    45,   1,   144,   60, 24},
        {"npc_dota_neutral_custom_big_pupper",    400,  0,    45,   1,   144,   60, 24},
        {"npc_dota_neutral_custom_big_pupper",    400,  0,    45,   1,   144,   60, 24},
        {"npc_dota_neutral_custom_big_pupper",    400,  0,    45,   1,   144,   60, 24},
        {"npc_dota_neutral_custom_big_pupper",    400,  0,    45,   1,   144,   60, 24},
        {"npc_dota_neutral_custom_big_pupper",    400,  0,    45,   1,   144,   60, 24},
      },
      multiplier = {
        mana = BaseMultipliers.mana(BaseCreepPowerMultiplier, 1, CaveProgressionBuff), -- function (k) return 1 end,
        hp = BaseMultipliers.hp(BaseCreepPowerMultiplier, 1, CaveProgressionBuff), -- function (k) return 1 end,
        damage = BaseMultipliers.damage(BaseCreepPowerMultiplier, 1, CaveProgressionBuff), -- function (k) return 1 end,
        armour = BaseMultipliers.armour(BaseCreepPowerMultiplier, 1, CaveProgressionBuff), -- function (k) return 1 end,
        gold = BaseMultipliers.gold(BaseCreepXPGOLDMultiplier, 1, CaveXPGOLDBuff), -- function (k) return (16 * k + 9) / 9 end,
        exp = BaseMultipliers.exp(BaseCreepXPGOLDMultiplier, 1, CaveXPGOLDBuff), -- function (k) return (168 * k^2 + 2 * k + 15) / 15 end,
        magicResist = function(k) return 1 end,
      }
    }
  },
  [2] = { -- 2 "Horse Tomatina"
    {                                                    --HP  MANA  DMG   ARM   GOLD  EXP RESIST
      units = {
        {"npc_dota_neutral_custom_cave_tomato",           300,  0,    60,   1,   144,   60, 36},
        {"npc_dota_neutral_custom_cave_tomato",           300,  0,    60,   1,   144,   60, 36},
        {"npc_dota_neutral_custom_cave_tomato",           300,  0,    60,   1,   144,   60, 36},
        {"npc_dota_neutral_custom_big_horse",             500,  0,    25,   2,   144,   60, 36},
        {"npc_dota_neutral_custom_big_horse",             500,  0,    25,   2,   144,   60, 36},
        {"npc_dota_neutral_custom_big_horse",             500,  0,    25,   2,   144,   60, 36},
      },
      multiplier = {
        mana = BaseMultipliers.mana(BaseCreepPowerMultiplier, 4, CaveProgressionBuff), -- function (k) return 1 end,
        hp = BaseMultipliers.hp(BaseCreepPowerMultiplier, 4, CaveProgressionBuff), -- function (k) return 1 end,
        damage = BaseMultipliers.damage(BaseCreepPowerMultiplier, 4, CaveProgressionBuff), -- function (k) return 1 end,
        armour = BaseMultipliers.armour(BaseCreepPowerMultiplier, 4, CaveProgressionBuff), -- function (k) return 1 end,
        gold = BaseMultipliers.gold(BaseCreepXPGOLDMultiplier, 4, CaveXPGOLDBuff), -- function (k) return (16 * k + 9) / 9 end,
        exp = BaseMultipliers.exp(BaseCreepXPGOLDMultiplier, 4, CaveXPGOLDBuff), -- function (k) return (84 * k^2 + 43  * k + 13) / 13 end,
        magicResist = function(k) return 1 end,
      }
    }
  },
  [3] = { -- 3 "Draggin' it Around"
    {                                        --HP  MANA  DMG   ARM   GOLD  EXP RESIST
      units = {
        {"npc_dota_neutral_black_drake",       600,  0,   70,   1,   216,   90, 48},
        {"npc_dota_neutral_black_drake",       600,  0,   70,   1,   216,   90, 48},
        {"npc_dota_neutral_black_drake",       600,  0,   70,   1,   216,   90, 48},
        {"npc_dota_neutral_black_drake",       600,  0,   70,   1,   216,   90, 48},
      },
      multiplier = {
        mana = BaseMultipliers.mana(BaseCreepPowerMultiplier, 7, CaveProgressionBuff), -- function (k) return 1 end,
        hp = BaseMultipliers.hp(BaseCreepPowerMultiplier, 7, CaveProgressionBuff), -- function (k) return 1 end,
        damage = BaseMultipliers.damage(BaseCreepPowerMultiplier, 7, CaveProgressionBuff), -- function (k) return 1 end,
        armour = BaseMultipliers.armour(BaseCreepPowerMultiplier, 7, CaveProgressionBuff), -- function (k) return 1 end,
        gold = BaseMultipliers.gold(BaseCreepXPGOLDMultiplier, 7, CaveXPGOLDBuff), -- function (k) return (16 * k + 13) / 13 end,
        exp = BaseMultipliers.exp(BaseCreepXPGOLDMultiplier, 7, CaveXPGOLDBuff), -- function (k) return (84 * k^2 + 85 * k + 29) / 29 end,
        magicResist = function(k) return 1 end,
      }
    }
  },
  [4] = { -- 4 "Roashes Everywhere"
    {                                         --HP    MANA  DMG   ARM   GOLD  EXP RESIST
      units = {
        {"npc_dota_mini_roshan",               900,   0,    100,  1.5,  432,  180, 60},
        {"npc_dota_mini_roshan",               900,   0,    100,  1.5,  432,  180, 60},
      },
      multiplier = {
        mana = BaseMultipliers.mana(BaseCreepPowerMultiplier, 10, CaveProgressionBuff), -- function (k) return 1 end,
        hp = BaseMultipliers.hp(BaseCreepPowerMultiplier, 10, CaveProgressionBuff), -- function (k) return 1 end,
        damage = BaseMultipliers.damage(BaseCreepPowerMultiplier, 10, CaveProgressionBuff), -- function (k) return 1 end,
        armour = BaseMultipliers.armour(BaseCreepPowerMultiplier, 10, CaveProgressionBuff), -- function (k) return 1 end,
        gold = function (k) return 0 end,
        exp = BaseMultipliers.exp(BaseCreepXPGOLDMultiplier, 10, CaveXPGOLDBuff), -- function (k) return (56 * k^2 + 85 * k + 37) / 37 end,
        magicResist = function(k) return 1 end,
      }
    }
  }
}
