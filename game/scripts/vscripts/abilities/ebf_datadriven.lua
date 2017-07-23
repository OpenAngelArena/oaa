function hell_golem_splash(keys)
  local caster = keys.caster
  local target = keys.target
  local item = keys.ability
  local radius = item:GetSpecialValueFor("radius")
  local percent = item:GetSpecialValueFor("splash_damage")
  local damage = keys.damage_on_hit * percent * 0.01
  local nearbyUnits = FindUnitsInRadius(
    target:GetTeam(),
    target:GetAbsOrigin(),
    nil,
    radius,
    DOTA_UNIT_TARGET_TEAM_FRIENDLY,
    DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
    DOTA_UNIT_TARGET_FLAG_NONE,
    FIND_ANY_ORDER,
    false
  )
  for _,unit in pairs(nearbyUnits) do
    if unit ~= target then
      ApplyDamage({
        victim = unit,
        attacker = caster,
        --damage = damage / caster:GetSpellDamageAmp(),
        damage = damage,
        damage_type = DAMAGE_TYPE_PHYSICAL,
        ability = keys.ability
      })
    end
  end
end

function KillTarget(keys)
  if not keys.caster:IsAlive() then return end
  keys.target:ForceKill(true)
end
