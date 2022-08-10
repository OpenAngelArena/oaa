LinkLuaModifier("modifier_bottle_selection", "abilities/misc/bottle_selection.lua", LUA_MODIFIER_MOTION_NONE)

bottle_selection = class(AbilityBaseClass)

function bottle_selection:GetIntrinsicModifierName()
	return "modifier_bottle_selection"
end

-----------------------------------------------------------------------------------------

modifier_bottle_selection = class(ModifierBaseClass)

function modifier_bottle_selection:IsHidden()
	return true
end

function modifier_bottle_selection:IsPurgable()
	return false
end

function modifier_bottle_selection:GetEffectName()
  local parent= self:GetParent()
  local teamID = parent:GetTeamNumber()
  if teamID == DOTA_TEAM_GOODGUYS then
    return "particles/misc/aqua_oaa_rays.vpcf"
  elseif teamID == DOTA_TEAM_BADGUYS then
    return "particles/misc/ruby_oaa_rays.vpcf"
  end
end

function modifier_bottle_selection:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_ORDER,
  }
end

function modifier_bottle_selection:CheckState()
  return {
    [MODIFIER_STATE_MAGIC_IMMUNE] = true,
    [MODIFIER_STATE_ATTACK_IMMUNE] = true,
    [MODIFIER_STATE_NO_HEALTH_BAR] = true,
    [MODIFIER_STATE_INVULNERABLE] = true,
    [MODIFIER_STATE_NO_UNIT_COLLISION] = true, -- this should prevent getting stuck on the bottle
  }
end

if IsServer() then
  function modifier_bottle_selection:OnOrder(params)
		local hOrderedUnit = params.unit
		local hTargetUnit = params.target
		local nOrderType = params.order_type

    if GetMapName() ~= "captains_mode" then
      return
    end

		if nOrderType ~= DOTA_UNIT_ORDER_MOVE_TO_TARGET then
			return
		end

		if not hTargetUnit or hTargetUnit ~= self:GetParent() then
			return
		end

		if hOrderedUnit and hOrderedUnit:IsRealHero() then
      CustomGameEventManager:Send_ServerToPlayer(hOrderedUnit:GetPlayerOwner(), "show_announcement", nil)
		end
	end
end
