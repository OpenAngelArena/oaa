
MMRShuffle = Components:Register('MMRShuffle', COMPONENT_TEAM_SELECT)

function MMRShuffle:Init ()
  Debug:EnableDebugging()
  DebugPrint('MMR Shuffle init!')
  self.moduleName = "MMR Shuffle"
  CustomGameEventManager:RegisterListener('mmrShuffle', partial(Dynamic_Wrap(MMRShuffle, 'Shuffle'), MMRShuffle))

  ListenToGameEvent("player_team", Dynamic_Wrap(MMRShuffle, 'UpdateAverageMMRs'), MMRShuffle)
  -- sent on each player load
  -- this makes us get real values on first load
  -- ....... maybe
  CustomGameEventManager:RegisterListener('updateAverageMMR', partial(Dynamic_Wrap(MMRShuffle, 'UpdateAverageMMRs'), MMRShuffle))

  self:UpdateAverageMMRs();
end

function MMRShuffle:UpdateAverageMMRs ()
  CustomNetTables:SetTableValue('oaa_settings', 'average_team_mmr', {
    dire = '--',
    radiant = '--',
  })
  Timers:CreateTimer(0.3, function()
    local direTeam = totable(PlayerResource:GetPlayerIDsForTeam(DOTA_TEAM_BADGUYS))
    local radTeam = totable(PlayerResource:GetPlayerIDsForTeam(DOTA_TEAM_GOODGUYS))

    self.averageTeamMMR = {
      dire = self:AverageMMR(direTeam),
      radiant = self:AverageMMR(radTeam)
    }

    self.mmrValues = {}
    for _, playerId in ipairs(direTeam) do
      self.mmrValues[playerId] = self:GetMMR(playerId)
    end
    for _, playerId in ipairs(radTeam) do
      self.mmrValues[playerId] = self:GetMMR(playerId)
    end

    CustomNetTables:SetTableValue('oaa_settings', 'player_mmr', self.mmrValues)
    CustomNetTables:SetTableValue('oaa_settings', 'average_team_mmr', self.averageTeamMMR)
  end)
end

function MMRShuffle:AverageMMR (teamIds, extraPlayer)
  local total = 0
  local playerCount = #teamIds
  if extraPlayer then
    total = self:GetMMR(extraPlayer)
    playerCount = playerCount + 1
  end
  if playerCount == 0 then
    return total
  end
  for _, playerId in ipairs(teamIds) do
    total = total + self:GetMMR(playerId)
  end

  return math.floor((total / playerCount) * 10) / 10
end

local fakeMMR = {}
function MMRShuffle:GetMMR (playerId)
  local steamid = tostring(PlayerResource:GetSteamAccountID(playerId))
  local mmr
  if Bottlepass.userData and steamid ~= "0" then
    mmr = Bottlepass.userData[steamid].unrankedMMR
  end
  if not mmr then
    mmr = fakeMMR[playerId] or RandomInt(800, 1200)
    fakeMMR[playerId] = mmr
  end
  return mmr
end

function MMRShuffle:Shuffle (aNumber, event)
  Debug:EnableDebugging()
  DebugPrint('Attempting shuffle! ' .. aNumber .. ' and ' .. event.PlayerID)
  local state = GameRules:State_Get()
  if state ~= DOTA_GAMERULES_STATE_CUSTOM_GAME_SETUP then
    return
  end
  local player = PlayerResource:GetPlayer(event.PlayerID)
  if not GameRules:PlayerHasCustomGameHostPrivileges(player) then
    DebugPrint('Only host can mmr shuffle')
    return
  end

  local radTeam = 0
  local direTeam = 0
  local radMMR = 0
  local direMMR = 0
  local radPlayerIds = {}
  local direPlayerIds = {}

  local allPlayerIds = totable(PlayerResource:GetAllPlayerIDs())
  local playerIds = totable(PlayerResource:GetAllTeamPlayerIDs())
  local totalPlayers = #playerIds

  DebugPrint('total players! ' .. totalPlayers)

  -- no team first for all IDs
  for _, playerId in ipairs(allPlayerIds) do
    if not PlayerResource:IsBlackBoxPlayer(playerId) then
      PlayerResource:UpdateTeamSlot(playerId, DOTA_TEAM_NOTEAM, playerId)
      PlayerResource:SetCustomTeamAssignment(playerId, DOTA_TEAM_NOTEAM)
    else
      PlayerResource:UpdateTeamSlot(playerId, DOTA_TEAM_SPECTATOR, playerId)
      PlayerResource:SetCustomTeamAssignment(playerId, DOTA_TEAM_SPECTATOR)
    end
  end

  while #playerIds > 0 do
    local choice = RandomInt(1, #playerIds)
    local playerId = playerIds[choice]
    local mmr = self:GetMMR(playerId)
    -- DebugPrint('player ' .. playerId .. ' has ' .. tostring(mmr or 'n/a') .. ' mmr')
    table.remove(playerIds, choice)
    local radChange = math.abs((direMMR / direTeam) - ((radMMR + mmr) / (radTeam + 1)))
    local direChange = math.abs((radMMR / radTeam) - ((direMMR + mmr) / (direTeam + 1)))

    if (radChange < direChange or direTeam >= totalPlayers / 2) and radTeam < totalPlayers / 2 then
      -- DebugPrint('Putting ' .. playerId .. ' onto team good')
      radTeam = radTeam + 1
      radMMR = radMMR + mmr
      table.insert(radPlayerIds, playerId)
    else
      -- DebugPrint('Putting ' .. playerId .. ' onto team bad')
      direTeam = direTeam + 1
      direMMR = direMMR + mmr
      table.insert(direPlayerIds, playerId)
    end
  end

  local direPreswap = direMMR / direTeam
  local radPreswap = radMMR / radTeam
  local diffPreswap = math.abs(direPreswap - radPreswap)
  --DebugPrint('Teams are ' .. math.floor(radPreswap) .. ' vs ' .. math.floor(direPreswap))

  local function without (teamIds, excluded)
    local newList = {}
    for _, playerId in ipairs(teamIds) do
      if playerId ~= excluded then
        table.insert(newList, playerId)
      end
    end
    return newList
  end

  local function swapPlayers (i, j)
    local radPlayer = radPlayerIds[i]
    table.remove(radPlayerIds, i)
    local direPlayer = direPlayerIds[j]
    table.remove(direPlayerIds, j)

    table.insert(radPlayerIds, direPlayer)
    table.insert(direPlayerIds, radPlayer)
  end

  for i = 1, #radPlayerIds do
    local playerId = radPlayerIds[i]
    local newRad = without(radPlayerIds, playerId)
    for j = 1, #direPlayerIds do
      local otherPlayerId = direPlayerIds[j]
      local newDire = without(direPlayerIds, otherPlayerId)
      local newDireMMR = self:AverageMMR(newDire, playerId)
      local newRadMMR = self:AverageMMR(newRad, otherPlayerId)
      local newDiff = math.abs(newDireMMR - newRadMMR)
      if newDiff < diffPreswap then
        diffPreswap = newDiff
        swapPlayers(i, j)
        playerId = radPlayerIds[i]
        newRad = without(radPlayerIds, playerId)
      end
    end
  end

  direPreswap = self:AverageMMR(direPlayerIds)
  radPreswap = self:AverageMMR(radPlayerIds)
  diffPreswap = math.abs(direPreswap - radPreswap)
  --DebugPrint('Teams are ' .. math.floor(radPreswap) .. ' vs ' .. math.floor(direPreswap))

  radTeam = 0
  direTeam = 0
  for _, playerId in ipairs(radPlayerIds) do
    radTeam = radTeam + 1
    PlayerResource:UpdateTeamSlot(playerId, DOTA_TEAM_GOODGUYS, radTeam)
    PlayerResource:SetCustomTeamAssignment(playerId, DOTA_TEAM_GOODGUYS)
  end
  for _, playerId in ipairs(direPlayerIds) do
    direTeam = direTeam + 1
    PlayerResource:UpdateTeamSlot(playerId, DOTA_TEAM_BADGUYS, direTeam)
    PlayerResource:SetCustomTeamAssignment(playerId, DOTA_TEAM_BADGUYS)
  end
end
