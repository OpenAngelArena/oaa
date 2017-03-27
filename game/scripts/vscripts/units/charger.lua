
function Spawn (entityKeyValues)
  thisEntity:FindAbilityByName("boss_charger_summon_pillar")

  thisEntity:SetContextThink( "ChargerThink", ChargerThink , 1)
  print("Starting AI for "..thisEntity:GetUnitName().." "..thisEntity:GetEntityIndex())
end

function ChargerThink ()
end
