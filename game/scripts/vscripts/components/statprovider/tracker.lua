
if StatTracker == nil then
  --Debug:EnableDebugging()
  --DebugPrint('Creating new StatTracker object.')
  StatTracker = class({})
end

function StatTracker:Init()
  self.moduleName = "StatTracker"
  --CreateModifierThinker( nil, nil, "modifier_stat_tracker_oaa", {}, Vector( 0, 0, 0 ), DOTA_TEAM_NEUTRALS, false )
  local global_tracker = CreateUnitByName("npc_dota_custom_dummy_unit", Vector(0, 0, 0), false, nil, nil, DOTA_TEAM_NEUTRALS)
  global_tracker:AddNewModifier(xpm_thinker, nil, "modifier_oaa_thinker", {})
  global_tracker:AddNewModifier(xpm_thinker, nil, "modifier_stat_tracker_oaa", {})

  self.stats = {}
  for i = 0, DOTA_MAX_PLAYERS - 1 do
    if PlayerResource:IsValidPlayerID(i) then
      self.stats[i] = {
        damage_dealt_to_heroes = 0,
        damage_dealt_to_bosses = 0,
        damage_dealt_to_player_creeps = 0,
        damage_dealt_to_neutral_creeps = 0,
        damage_taken_from_players = 0,
        damage_taken_from_bosses = 0,
        damage_taken_from_neutral_creeps = 0,
      }
    end
  end

  ChatCommand:LinkDevCommand("-trackertest", Dynamic_Wrap(StatTracker, "StatTrackerCommand"), self)
end

function StatTracker:GetDamageDoneToHeroes(pID)
  local result = 0
  for i = 0, DOTA_MAX_PLAYERS - 1 do
    if PlayerResource:IsValidPlayerID(i) then
      if not pID ~= i then
        result = result + PlayerResource:GetDamageDoneToHero(pID, i)
      end
    end
  end
  return math.floor(result)
end

function StatTracker:StatTrackerCommand(keys)
  local text = string.lower(keys.text)
  local splitted = split(text, " ")
  local id = tonumber(splitted[2]) or 0

  print("Stored damage values: ")
  DeepPrintTable(StatTracker.stats[id])
  print("1 Valve damage dealt to heroes is "..tostring(PlayerResource:GetRawPlayerDamage(id)))
  print("2 Valve damage dealt to heroes is "..tostring(StatTracker:GetDamageDoneToHeroes(id)))
  print("Valve damage taken from heroes is "..tostring(PlayerResource:GetHeroDamageTaken(id, true)))
  print("Valve damage taken from creeps is "..tostring(PlayerResource:GetCreepDamageTaken(id, true)))
end

---------------------------------------------------------------------------------------------------

modifier_stat_tracker_oaa = class({})

function modifier_stat_tracker_oaa:IsHidden()
  return true
end

function modifier_stat_tracker_oaa:IsDebuff()
  return false
end

function modifier_stat_tracker_oaa:IsPurgable()
  return false
end

function modifier_stat_tracker_oaa:IsPermanent()
  return true
end

function modifier_stat_tracker_oaa:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_TAKEDAMAGE_KILLCREDIT,
  }
end

if IsServer() then
  function modifier_stat_tracker_oaa:OnTakeDamageKillCredit(event)
    local attacker = event.attacker
    local victim = event.unit
    local dmg_flags = event.damage_flags
    local damage = event.damage
    --local inflictor = event.inflictor

    -- Check if attacker exists
    if not attacker or attacker:IsNull() then
      return
    end

    -- Check if damaged entity exists
    if not victim or victim:IsNull() then
      return
    end

    -- Ignore self damage
    if victim == attacker then
      return
    end

    -- Check if damaged entity is an item, rune or something weird
    if victim.GetUnitName == nil then
      return
    end

    -- Don't track damage against buildings, wards and invulnerable units.
    if victim:IsTower() or victim:IsBarracks() or victim:IsBuilding() or victim:IsInvulnerable() then
      return
    end

    -- Check damage if 0 or negative
    if damage <= 0 then
      return
    end

    if attacker.GetTeamNumber = nil then
      return
    end

    local attacker_team = attacker:GetTeamNumber()
    local victim_team = victim:GetTeamNumber()
    local attacker_id
    local victim_id

    if attacker_team == DOTA_TEAM_NEUTRALS then
      -- Attacker is on neutral team
      if victim_team == DOTA_TEAM_NEUTRALS then
        -- Neutrals damaging each other, this is funny but we do not care about it
        return
      else
        victim_id = UnitVarToPlayerID(victim)
        if victim:IsRealHero() and not victim:IsTempestDouble() and not victim:IsSpiritBearOAA() then
          -- Victim is a player's hero
          if attacker:IsOAABoss() then
            -- Attacker is a boss
            StatTracker.stats[victim_id].damage_taken_from_bosses = StatTracker.stats[victim_id].damage_taken_from_bosses + damage
          else
            -- Attacker is a creep
            StatTracker.stats[victim_id].damage_taken_from_neutral_creeps = StatTracker.stats[victim_id].damage_taken_from_neutral_creeps + damage
          end
        else
          -- Victim is a player's creep, an illusion, a Tempest Double or Spirit Bear
          return
        end
      end
    else
      -- Attacker is on Radiant or Dire team
      if victim_team == DOTA_TEAM_NEUTRALS then
        -- Victim is a neutral
        -- It does not matter if attacker is a creep or not, it belongs to a player
        attacker_id = UnitVarToPlayerID(attacker)
        if victim:IsIllusion() then
          -- Neutral illusion of something -> ignore
          return
        end
        if victim:IsOAABoss() then
          -- Victim is a boss
          StatTracker.stats[attacker_id].damage_dealt_to_bosses = StatTracker.stats[attacker_id].damage_dealt_to_bosses + damage
        elseif victim:IsHero() or victim:IsConsideredHero() then
          -- Victim is a hero -> it's probably a boss or a boss creep
          StatTracker.stats[attacker_id].damage_dealt_to_bosses = StatTracker.stats[attacker_id].damage_dealt_to_bosses + damage
        else
          -- Victim is a neutral creep
          StatTracker.stats[attacker_id].damage_dealt_to_neutral_creeps = StatTracker.stats[attacker_id].damage_dealt_to_neutral_creeps + damage
        end
      else
        -- Victim is on Radiant or Dire team
        if victim_team == attacker_team then
          -- Victim and Attacker are allies -> do not track the damage
          return
        else
          victim_id = UnitVarToPlayerID(victim)
          attacker_id = UnitVarToPlayerID(attacker)
          if victim:IsRealHero() and not victim:IsTempestDouble() and not victim:IsSpiritBearOAA() then
            -- Victim is a player's hero
            -- It does not matter if attacker is a creep or not, it belongs to a player
            StatTracker.stats[victim_id].damage_taken_from_players = StatTracker.stats[victim_id].damage_taken_from_players + damage
            StatTracker.stats[attacker_id].damage_dealt_to_heroes = StatTracker.stats[attacker_id].damage_dealt_to_heroes + damage
          else
            -- Victim is a player's creep, an illusion, a Tempest Double or Spirit Bear
            StatTracker.stats[attacker_id].damage_dealt_to_player_creeps = StatTracker.stats[attacker_id].damage_dealt_to_player_creeps + damage
          end
        end
      end
    end

    -- Damage with HP removal flag
    if bit.band(dmg_flags, DOTA_DAMAGE_FLAG_HPLOSS) > 0 then
      print(tostring(attacker:GetUnitName()).." is dealing "..tostring(damage).." HP REMOVAL damage to "..tostring(victim:GetUnitName()))
    end
  end
end
