
-- Taken from bb template
if NGP == nil then
    DebugPrint ( 'creating new need greed pass controller.' )
    NGP = class({})
end

NGP.itemIndex = 0
NGP.activeItems = {}

function NGP:Init ()

  -- set initial values for ngp store
  CustomNetTables:SetTableValue( 'ngp', 'good', {
  })
  CustomNetTables:SetTableValue( 'ngp', 'bad', {
  })

  CustomGameEventManager:RegisterListener('ngp_selection', Dynamic_Wrap(NGP, 'PlayerVote'))
end

function NGP:PlayerVote (eventSourceIndex, args)
  DebugPrintTable(eventSourceIndex)
  -- DebugPrintTable(args)
  local playerID = eventSourceIndex.PlayerID
  local id = eventSourceIndex.id
  local option = eventSourceIndex.option
  local team = ShortTeamName(PlayerResource:GetTeam(playerID))
  local item = NGP.activeItems[tonumber(id)]

  if item.team ~= team then
    DebugPrint("NGP mismatch " .. item.team .. " vs " .. team)
    return
  end

  DebugPrint(team)
  item.votes[playerID] = option
end

function NGP:GiveItemToTeam (item, team)
  local ngpItems = CustomNetTables:GetTableValue('ngp', team)

  DebugPrint('item index will be ' .. NGP.itemIndex)
  DebugPrintTable(ngpItems)
  item.id = NGP.itemIndex
  NGP.itemIndex = NGP.itemIndex + 1

  item.team = team
  NGP.activeItems[item.id] = item

  NGP.activeItems[item.id].votes = {}


  ngpItems[item.id] = item

  CustomNetTables:SetTableValue('ngp', team, ngpItems)

  Timers:CreateTimer(60, function ()
    NGP:FinishVoting(NGP.activeItems[item.id])
  end)
end

function NGP:FinishVoting (item)
  local needVotes = {}
  local greedVotes = {}
  local passVotes = {}
  for i = 0,19 do
    if item.votes[i] then
      if item.votes[i] == 'need' then
        table.insert(needVotes, i)
      elseif item.votes[i] == 'greed' then
        table.insert(greedVotes, i)
      elseif item.votes[i] == 'pass' then
        table.insert(passVotes, i)
      end
    end
  end

  if #needVotes > 0 then
    -- someone voted need! decide between them...
    local winningPlayer = needVotes[math.random(1, #needVotes)]
    DebugPrint(winningPlayer .. ' won!!')
    NGP:GiveItemToPlayer(item, winningPlayer)
    return
  end
  if #greedVotes > 0 then
    -- someone voted need! decide between them...
    local winningPlayer = greedVotes[math.random(1, #greedVotes)]
    DebugPrint(winningPlayer .. ' won!!')
    NGP:GiveItemToPlayer(item, winningPlayer)
    return
  end
end

function NGP:GiveItemToPlayer (item, playerId)
  local player = PlayerResource:GetPlayer(playerId)
  if player == nil then
    DebugPrint('Player is null while trying to give them their reward!')
    return
  end
  local hero = player:GetAssignedHero()
  if hero == nil then
    DebugPrint('Hero of player is null while trying to give them their reward!')
    return
  end
  -- local itemHandle = CreateItem(item.item, hero, hero)
  hero:AddItemByName(item.item)
end

function ShortTeamName(teamId)
  DebugPrint(teamId)
  if teamId == 2 then
    return 'good'
  else
    return 'bad'
  end
end
