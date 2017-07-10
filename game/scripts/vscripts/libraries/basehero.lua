
function CDOTA_BaseNPC_Hero:GetNetworth ()
  return GetNetworth(self)
end

function CDOTA_BaseNPC_Hero:ModifyGold (playerID, goldAmmt, reliable, nReason)
  return Gold:ModifyGold(playerID, goldAmmt, reliable, nReason)
end
