
if StatTracker == nil then
  StatTracker = class({})
end

function StatTracker:Init()
  self.moduleName = "StatTracker"

  self.stats = {}
  for i = 0, DOTA_MAX_PLAYERS - 1 do
    if PlayerResource:IsValidPlayerID(i) then
      self:InitializeForId(i)
    end
  end

  --CreateModifierThinker( nil, nil, "modifier_stat_tracker_oaa", {}, Vector( 0, 0, 0 ), DOTA_TEAM_NEUTRALS, false )
  local global_tracker = CreateUnitByName("npc_dota_custom_dummy_unit", Vector(0, 0, 0), false, nil, nil, DOTA_TEAM_NEUTRALS)
  global_tracker:AddNewModifier(global_tracker, nil, "modifier_oaa_thinker", {})
  global_tracker:AddNewModifier(global_tracker, nil, "modifier_stat_tracker_oaa", {})

  self.global_tracker = global_tracker
  self.tracking = true -- to enable/disable tracking just change this bool

  ChatCommand:LinkDevCommand("-dmgtrackertest", Dynamic_Wrap(StatTracker, "TestDamageTracker"), self)
  ChatCommand:LinkDevCommand("-resettracker", Dynamic_Wrap(StatTracker, "ResetTracking"), self)
end

function StatTracker:InitializeForId(pID)
  self.stats[pID] = {
    damage_dealt_to_heroes = 0,
    damage_dealt_to_bosses = 0,
    damage_dealt_to_player_creeps = 0,
    damage_dealt_to_neutral_creeps = 0,
    damage_taken_from_players = 0,
    damage_taken_from_bosses = 0,
    damage_taken_from_neutral_creeps = 0,
  }
end

function StatTracker:GetDamageDoneToHeroes(pID)
  local result = 0
  for i = 0, DOTA_MAX_PLAYERS - 1 do
    if PlayerResource:IsValidPlayerID(i) then
      if pID == i then
        result = result + PlayerResource:GetDamageDoneToHero(pID, i)
      end
    end
  end
  return math.floor(result)
end

function StatTracker:TestDamageTracker(keys)
  local text = string.lower(keys.text)
  local splitted = split(text, " ")
  local id = tonumber(splitted[2]) or 0

  print("Stored damage values: ")
  DeepPrintTable(StatTracker.stats[id])
  --print("1 Valve damage dealt to heroes is "..tostring(PlayerResource:GetRawPlayerDamage(id)))
  --print("2 Valve damage dealt to heroes is "..tostring(StatTracker:GetDamageDoneToHeroes(id)))
  --print("Valve damage taken from heroes is "..tostring(PlayerResource:GetHeroDamageTaken(id, true))) -- 0 until the end of the game
  print("Valve damage taken from creeps is "..tostring(PlayerResource:GetCreepDamageTaken(id, true))) -- check if it counts player creeps too
end

function StatTracker:ResetTracking(keys)
  self.tracking = false
  self.global_tracker:ForceKillOAA(false)

  self.stats = {}
  for i = 0, DOTA_MAX_PLAYERS - 1 do
    if PlayerResource:IsValidPlayerID(i) then
      self:InitializeForId(i)
    end
  end

  print("Stored stats are reset. Global Damage Tracker will be definitely be removed in "..tostring(MANUAL_GARBAGE_CLEANING_TIME).." seconds.")

  local global_tracker = CreateUnitByName("npc_dota_custom_dummy_unit", Vector(0, 0, 0), false, nil, nil, DOTA_TEAM_NEUTRALS)
  global_tracker:AddNewModifier(global_tracker, nil, "modifier_oaa_thinker", {})
  global_tracker:AddNewModifier(global_tracker, nil, "modifier_stat_tracker_oaa", {})

  self.global_tracker = global_tracker
  self.tracking = true
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
    local victim = event.target
    local damage = event.damage

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

    -- Check if attacker or damaged entity are npcs
    if victim.GetUnitName == nil or attacker.GetTeamNumber == nil then
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

    if not StatTracker then
      return
    end

    if not StatTracker.tracking then
      return
    end

    --print("StatTracker damage tracker is working")

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
        -- Initialize for newly added bots to prevent an error
        if victim_id and not StatTracker.stats[victim_id] and PlayerResource:IsValidPlayerID(victim_id) then
          StatTracker:InitializeForId(victim_id)
        end
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
        -- Initialize for newly added bots to prevent an error
        if attacker_id and not StatTracker.stats[attacker_id] and PlayerResource:IsValidPlayerID(attacker_id) then
          StatTracker:InitializeForId(attacker_id)
        end
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
          -- Initialize for newly added bots to prevent an error
          if victim_id and not StatTracker.stats[victim_id] and PlayerResource:IsValidPlayerID(victim_id) then
            StatTracker:InitializeForId(victim_id)
          end
          if attacker_id and not StatTracker.stats[attacker_id] and PlayerResource:IsValidPlayerID(attacker_id) then
            StatTracker:InitializeForId(attacker_id)
          end
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
  end
end
