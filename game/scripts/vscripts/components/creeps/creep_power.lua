
--defines creep property multipliers for power levels
--nth power level corresponds to creeps spawned at minute n
--if levels are not defined, GetPowerLevelPropertyMultiplier will interpolate values
CreepPowerTable = {
  --  LEVEL     HEALTH    MANA      DAMAGE    ARMOR     GOLD      EXP
  {   0,        1.0,      1.0,      1.0,      1.0,      1.0,      1.0},
  {   1000,     100.0,    100.0,    100.0,   100.0,     501.0,    100.0}
}
