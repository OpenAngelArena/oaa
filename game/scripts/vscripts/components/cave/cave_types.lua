
CAVE_TYPE_STATS_HEALTH = 2
CAVE_TYPE_STATS_MANA = 3
CAVE_TYPE_STATS_DAMAGE = 4
CAVE_TYPE_STATS_ARMOUR = 5
CAVE_TYPE_STATS_GOLD = 6
CAVE_TYPE_STATS_EXP = 7
CAVE_TYPE_STATS_RESITS = 8


function MakeKFunctionForIndexPowerOffset (index, speed, offset, power)
  return function (k)
    return 1 + power*(CreepPower:GetBaseCavePowerForMinute(k * speed + offset)[index] - 1)
  end
end

local BaseCreepPowerMultiplier = 4 * _G.CAVE_ROOM_INTERVAL
local BaseCreepXPGOLDMultiplier = 4 * _G.CAVE_ROOM_INTERVAL
local CaveProgressionBuff = _G.CAVE_DIFFICULTY
local CaveXPGOLDBuff = _G.CAVE_BOUNTY

local BaseMultipliers = {
  -- CreepPower:GetBasePowerForMinute

  --  minute,                                   -- minute
  --  ((minute / 8) ^ 2 / 75) + 1,              -- hp
  --  minute,                                   -- mana
  --  (minute / 20) + 1,                        -- damage
  --  minute ^ 0.5,                             -- armor
  --  (minute / 2) + 1,                         -- gold
  --  ((21 * minute^2 - 19 * minute + 3002) / 3002) * self.numPlayersXPFactor * multFactor -- xp
  hp = partial(MakeKFunctionForIndexPowerOffset, CAVE_TYPE_STATS_HEALTH),
  mana = partial(MakeKFunctionForIndexPowerOffset, CAVE_TYPE_STATS_MANA),
  damage = partial(MakeKFunctionForIndexPowerOffset, CAVE_TYPE_STATS_DAMAGE),
  armour = partial(MakeKFunctionForIndexPowerOffset, CAVE_TYPE_STATS_ARMOUR),
  gold = partial(MakeKFunctionForIndexPowerOffset, CAVE_TYPE_STATS_GOLD),
  exp = partial(MakeKFunctionForIndexPowerOffset, CAVE_TYPE_STATS_EXP)
}

-- "creep name", Health, Mana, Damage, Armor, Gold Bounty, Exp Bounty
CaveTypes = {
  [1] = { -- 1 "Howl's it Going?"
    {                                                  --HP  MANA  DMG  ARM   GOLD   EXP  RESIST
      units = {
        {"npc_dota_neutral_custom_cave_big_pupper",    600,    0,  30,   1,   141,   204,  30},
        {"npc_dota_neutral_custom_cave_big_pupper",    600,    0,  30,   1,   141,   204,  30},
        {"npc_dota_neutral_custom_cave_big_pupper",    600,    0,  30,   1,   141,   204,  30},
        {"npc_dota_neutral_custom_cave_big_pupper",    600,    0,  30,   1,   141,   204,  30},
        {"npc_dota_neutral_custom_cave_big_pupper",    600,    0,  30,   1,   141,   204,  30},
        {"npc_dota_neutral_custom_cave_big_pupper",    600,    0,  30,   1,   141,   204,  30},
      },
      multiplier = {
        mana = BaseMultipliers.mana(BaseCreepPowerMultiplier, 0, CaveProgressionBuff), -- function (k) return 1 end,
        hp = BaseMultipliers.hp(BaseCreepPowerMultiplier, 0, CaveProgressionBuff), -- function (k) return 1 end,
        damage = BaseMultipliers.damage(BaseCreepPowerMultiplier, 0, CaveProgressionBuff), -- function (k) return 1 end,
        armour = BaseMultipliers.armour(BaseCreepPowerMultiplier, 0, CaveProgressionBuff), -- function (k) return 1 end,
        gold = BaseMultipliers.gold(BaseCreepXPGOLDMultiplier, 0, CaveXPGOLDBuff), -- function (k) return (16 * k + 9) / 9 end,
        exp = BaseMultipliers.exp(BaseCreepXPGOLDMultiplier, 0, CaveXPGOLDBuff), -- function (k) return (168 * k^2 + 2 * k + 15) / 15 end,
        magicResist = function(k) return 1 end,
      }
    }
  },
  [2] = { -- 2 "Horse Tomatina"
    {                                                  --HP  MANA  DMG  ARM   GOLD   EXP  RESIST
      units = {
        {"npc_dota_neutral_custom_cave_tomato",        450,    0,  38,  0.8,  142,   204,  40},
        {"npc_dota_neutral_custom_cave_tomato",        450,    0,  38,  0.8,  142,   204,  40},
        {"npc_dota_neutral_custom_cave_tomato",        450,    0,  38,  0.8,  142,   204,  40},
        {"npc_dota_neutral_custom_cave_big_horse",     750,    0,  19,  1.2,  142,   204,  40},
        {"npc_dota_neutral_custom_cave_big_horse",     750,    0,  19,  1.2,  142,   204,  40},
        {"npc_dota_neutral_custom_cave_big_horse",     750,    0,  19,  1.2,  142,   204,  40},
      },
      multiplier = {
        mana = BaseMultipliers.mana(BaseCreepPowerMultiplier, _G.CAVE_ROOM_INTERVAL, CaveProgressionBuff), -- function (k) return 1 end,
        hp = BaseMultipliers.hp(BaseCreepPowerMultiplier, _G.CAVE_ROOM_INTERVAL, CaveProgressionBuff), -- function (k) return 1 end,
        damage = BaseMultipliers.damage(BaseCreepPowerMultiplier, _G.CAVE_ROOM_INTERVAL, CaveProgressionBuff), -- function (k) return 1 end,
        armour = BaseMultipliers.armour(BaseCreepPowerMultiplier, _G.CAVE_ROOM_INTERVAL, CaveProgressionBuff), -- function (k) return 1 end,
        gold = BaseMultipliers.gold(BaseCreepXPGOLDMultiplier, _G.CAVE_ROOM_INTERVAL, CaveXPGOLDBuff), -- function (k) return (16 * k + 9) / 9 end,
        exp = BaseMultipliers.exp(BaseCreepXPGOLDMultiplier, _G.CAVE_ROOM_INTERVAL, CaveXPGOLDBuff), -- function (k) return (84 * k^2 + 43  * k + 13) / 13 end,
        magicResist = function(k) return 1 end,
      }
    }
  },
  [3] = { -- 3 "Draggin' it Around"
    {                                                  --HP  MANA  DMG  ARM   GOLD   EXP  RESIST
      units = {
        {"npc_dota_neutral_custom_cave_black_drake",   900,    0,  45,   1,   212,   309,  50},
        {"npc_dota_neutral_custom_cave_black_drake",   900,    0,  45,   1,   212,   309,  50},
        {"npc_dota_neutral_custom_cave_black_drake",   900,    0,  45,   1,   212,   309,  50},
        {"npc_dota_neutral_custom_cave_black_drake",   900,    0,  45,   1,   212,   309,  50},
      },
      multiplier = {
        mana = BaseMultipliers.mana(BaseCreepPowerMultiplier, 2 * _G.CAVE_ROOM_INTERVAL, CaveProgressionBuff), -- function (k) return 1 end,
        hp = BaseMultipliers.hp(BaseCreepPowerMultiplier, 2 * _G.CAVE_ROOM_INTERVAL, CaveProgressionBuff), -- function (k) return 1 end,
        damage = BaseMultipliers.damage(BaseCreepPowerMultiplier, 2 * _G.CAVE_ROOM_INTERVAL, CaveProgressionBuff), -- function (k) return 1 end,
        armour = BaseMultipliers.armour(BaseCreepPowerMultiplier, 2 * _G.CAVE_ROOM_INTERVAL, CaveProgressionBuff), -- function (k) return 1 end,
        gold = BaseMultipliers.gold(BaseCreepXPGOLDMultiplier, 2 * _G.CAVE_ROOM_INTERVAL, CaveXPGOLDBuff), -- function (k) return (16 * k + 13) / 13 end,
        exp = BaseMultipliers.exp(BaseCreepXPGOLDMultiplier, 2 * _G.CAVE_ROOM_INTERVAL, CaveXPGOLDBuff), -- function (k) return (84 * k^2 + 85 * k + 29) / 29 end,
        magicResist = function(k) return 1 end,
      }
    }
  },
  [4] = { -- 4 "Roashes Everywhere"
    {                                                  --HP  MANA  DMG  ARM   GOLD   EXP  RESIST
      units = {
        {"npc_dota_mini_roshan",                      1200,    0,  68,  1.2,  425,   614,  60},
        {"npc_dota_mini_roshan",                      1200,    0,  68,  1.2,  425,   614,  60},
      },
      multiplier = {
        mana = BaseMultipliers.mana(BaseCreepPowerMultiplier, 3 * _G.CAVE_ROOM_INTERVAL, CaveProgressionBuff), -- function (k) return 1 end,
        hp = BaseMultipliers.hp(BaseCreepPowerMultiplier, 3 * _G.CAVE_ROOM_INTERVAL, CaveProgressionBuff), -- function (k) return 1 end,
        damage = BaseMultipliers.damage(BaseCreepPowerMultiplier, 3 * _G.CAVE_ROOM_INTERVAL, CaveProgressionBuff), -- function (k) return 1 end,
        armour = BaseMultipliers.armour(BaseCreepPowerMultiplier, 3 * _G.CAVE_ROOM_INTERVAL, CaveProgressionBuff), -- function (k) return 1 end,
        gold = function (k) return 0 end,
        exp = BaseMultipliers.exp(BaseCreepXPGOLDMultiplier, 3 * _G.CAVE_ROOM_INTERVAL, CaveXPGOLDBuff), -- function (k) return (56 * k^2 + 85 * k + 37) / 37 end,
        magicResist = function(k) return 1 end,
      }
    }
  }
}
