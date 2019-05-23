
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
  local source_index = filter_table.entindex_source_const
  local is_an_attack_projectile = filter_table.is_attack    -- values: 1 for yes or 0 for no

  local attacker
  if source_index then
		attacker = EntIndexToHScript(source_index)
	end

  if attacker and not attacker:IsNull() then
    if attacker:IsRealHero() and attacker:HasTalent("special_bonus_unique_wisp_4") and is_an_attack_projectile == 1 then
      if attacker:IsDisarmed() or attacker:IsStunned() or attacker:IsOutOfGame() or attacker:IsHexed() then
        return false
      end
    end
  end

  return true
end
