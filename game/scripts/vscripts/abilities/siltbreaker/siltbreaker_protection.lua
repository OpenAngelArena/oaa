
function siltbreaker_protection_purge(kv)
  local unit = kv.unit
  if unit:IsStunned() or unit:IsSilenced() then
    unit:Purge( false, true, true, true, true )
  end
end

function siltbreaker_protection_trigger(kv)
  local unit = kv.unit
  local ability = kv.ability
  local protection_duration = ability:GetSpecialValueFor("duration")

  if ability:IsCooldownReady() and (unit:IsStunned() or unit:IsSilenced()) then
    unit:Purge( false, true, true, true, true )
    ability:CastAbility()
  end
end

