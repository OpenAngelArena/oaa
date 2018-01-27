
Bottlepass = Bottlepass or class({})

function Bottlepass:GetPlayerMMR (playerID)
  if not self.userData then
    return
  end
  local steamid = PlayerResource:GetSteamAccountID(playerID)

  return self.userData[steamid].mmr
end
