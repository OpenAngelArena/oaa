
MMRShuffle = Components:Register('MMRShuffle', COMPONENT_TEAM_SELECT)

function MMRShuffle:Init ()
  Debug:EnableDebugging()
  DebugPrint('MMR Shuffle init!')
  CustomGameEventManager:RegisterListener('mmrShuffle', partial(Dynamic_Wrap(MMRShuffle, 'Shuffle'), MMRShuffle))
end

local fakeMMR = {}
function MMRShuffle:GetMMR (playerId)
  local steamid = HeroSelection:GetSteamAccountID(playerId)
  local mmr = nil
  if Bottlepass.userData then
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

  local playerIds = totable(PlayerResource:GetAllTeamPlayerIDs())
  local totalPlayers = #playerIds

  DebugPrint('total players! ' .. totalPlayers)

  -- no team first
  for _,playerId in ipairs(playerIds) do
    PlayerResource:UpdateTeamSlot(playerId, DOTA_TEAM_NOTEAM, playerId)
    PlayerResource:SetCustomTeamAssignment(playerId, DOTA_TEAM_NOTEAM)
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
  DebugPrint('Teams are ' .. math.floor(radPreswap) .. ' vs ' .. math.floor(direPreswap))

  local function avgMMR (teamIds, extraPlayer)
    local total = 0
    local playerCount = #teamIds
    if extraPlayer then
      total = self:GetMMR(extraPlayer)
      playerCount = playerCount + 1
    end
    if playerCount == 0 then
      return total
    end
    for _,playerId in ipairs(teamIds) do
      total = total + self:GetMMR(playerId)
    end

    return total / playerCount
  end

  local function without (teamIds, excluded)
    local newList = {}
    for _,playerId in ipairs(teamIds) do
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

  for i = 1,#radPlayerIds do
    local playerId = radPlayerIds[i]
    local newRad = without(radPlayerIds, playerId)
    for j = 1,#direPlayerIds do
      local otherPlayerId = direPlayerIds[j]
      local newDire = without(direPlayerIds, otherPlayerId)
      local newDireMMR = avgMMR(newDire, playerId)
      local newRadMMR = avgMMR(newRad, otherPlayerId)
      local newDiff = math.abs(newDireMMR - newRadMMR)
      if newDiff < diffPreswap then
        diffPreswap = newDiff
        swapPlayers(i, j)
      end
    end
  end

  direPreswap = avgMMR(direPlayerIds)
  radPreswap = avgMMR(radPlayerIds)
  diffPreswap = math.abs(direPreswap - radPreswap)
  DebugPrint('Teams are ' .. math.floor(radPreswap) .. ' vs ' .. math.floor(direPreswap))

  radTeam = 0
  direTeam = 0
  for _,playerId in ipairs(radPlayerIds) do
    radTeam = radTeam + 1
    PlayerResource:UpdateTeamSlot(playerId, DOTA_TEAM_GOODGUYS, radTeam)
    PlayerResource:SetCustomTeamAssignment(playerId, DOTA_TEAM_GOODGUYS)
  end
  for _,playerId in ipairs(direPlayerIds) do
    direTeam = direTeam + 1
    PlayerResource:UpdateTeamSlot(playerId, DOTA_TEAM_BADGUYS, direTeam)
    PlayerResource:SetCustomTeamAssignment(playerId, DOTA_TEAM_BADGUYS)
  end
end
