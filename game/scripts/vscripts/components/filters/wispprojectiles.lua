
if WispProjectileFilter == nil then
  --Debug:EnableDebugging()
  DebugPrint('Creating new WispProjectileFilter object')
  WispProjectileFilter = class({})
end

function WispProjectileFilter:Init()
  FilterManager:AddFilter(FilterManager.TrackingProjectile, self, Dynamic_Wrap(WispProjectileFilter, 'Filter'))
end

function WispProjectileFilter:Filter(filter_table)
  --Debug:EnableDebugging()
  local can_be_dodged = filter_table.dodgeable              -- values: 1 for yes or 0 for no
  local ability_index = filter_table.entindex_ability_const -- value if not ability: -1
  local source_index = filter_table.entindex_source_const
  local target_index = filter_table.entindex_target_const
  local expire_time = filter_table.expire_time
  local is_an_attack_projectile = filter_table.is_attack    -- values: 1 for yes or 0 for no
  local max_impact_time = filter_table.max_impact_time
  local projectile_speed = filter_table.move_speed

  local attacker
  if filter_table.entindex_source_const then
		attacker = EntIndexToHScript(filter_table.entindex_source_const)
	end

  if attacker and not attacker:IsNull() then
    if attacker:IsRealHero() and attacker:HasTalent("special_bonus_unique_wisp_4") and is_an_attack_projectile == 1 then
      if attacker:IsDisarmed() or attacker:IsStunned() or attacker:IsOutOfGame() or attacker:IsHexed() or attacker:IsCommandRestricted() then
        return false
      end
    end
  end

  return true
end
