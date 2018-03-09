function allied_cyclone_damage(keys)
	if keys.caster:GetTeam() ~= keys.target:GetTeam() then
		local damage = {
			victim = keys.target,
			attacker = keys.caster,
			damage = keys.Damage,
			damage_type = DAMAGE_TYPE_MAGICAL,
		}
		ApplyDamage(damage)
	end
end

function allied_cyclone_Purge(keys)
  keys.target:EmitSound("DOTA_Item.Cyclone.Activate")
	if keys.caster:GetTeam() == keys.target:GetTeam() then
		keys.target:Purge(false,true,false,false,false)
  else
    if keys.target:TriggerSpellAbsorb(keys.ability) then
      return
    end
    keys.target:Purge(true, false, false, false, false)
	end
end
