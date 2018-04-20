if SurrenderManager == nil then
  Debug.EnabledModules['surrender:*'] = true
  DebugPrint ( 'Creating new SurrenderManager object.' )
  SurrenderManager = class({})
end

function SurrenderManager:Init ()
  DebugPrint ('Init SurrenderManager')
  -- Register chat commands
  -- ChatCommand:LinkCommand("-surrender", Dynamic_Wrap(SurrenderManager, "CheckSurrenderConditions"), self)
  ChatCommand:LinkCommand("-s", Dynamic_Wrap(SurrenderManager, "CheckSurrenderConditions"), self)
end

function SurrenderManager:CheckSurrenderConditions(keys)
  -- DebugPrint ('CheckSurrenderConditions')
  -- local score = CustomNetTables:GetTableValue('team_scores', 'score')
  -- local scoreDiff = math.abs(score.goodguys - score.badguys)
  -- local textToShow = scoreDiff
  -- DebugPrint(textToShow)
  Notifications:TopToAll({text="#duel_not_enough_players", duration=3.0})
end
