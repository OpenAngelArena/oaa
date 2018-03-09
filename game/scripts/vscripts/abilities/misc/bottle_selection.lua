bottle_selection = class( AbilityBaseClass )
LinkLuaModifier( "modifier_bottle_selection", "abilities/misc/bottle_selection.lua", LUA_MODIFIER_MOTION_NONE )

-----------------------------------------------------------------------------------------

function bottle_selection:GetIntrinsicModifierName()
	return "modifier_bottle_selection"
end

-----------------------------------------------------------------------------------------

modifier_bottle_selection = class(ModifierBaseClass)

-----------------------------------------------------------------------

function modifier_bottle_selection:IsHidden()
	return true
end

-----------------------------------------------------------------------

function modifier_bottle_selection:IsPurgable()
	return false
end

-----------------------------------------------------------------------

function modifier_bottle_selection:GetEffectName(  )
  local parent= self:GetParent()
  local teamID = parent:GetTeamNumber()
  if teamID == DOTA_TEAM_GOODGUYS then
    return  "particles/misc/aqua_oaa_rays.vpcf"
  elseif teamID == DOTA_TEAM_BADGUYS then
    return   "particles/misc/ruby_oaa_rays.vpcf"
  end
end

-----------------------------------------------------------------------

function modifier_bottle_selection:DeclareFunctions()
	local funcs =
	{
		MODIFIER_EVENT_ON_ORDER,
	}
	return funcs
end

-----------------------------------------------------------------------

function modifier_bottle_selection:CheckState()
  local state = {
    [MODIFIER_STATE_MAGIC_IMMUNE] = true,
    [MODIFIER_STATE_ATTACK_IMMUNE] = true,
    [MODIFIER_STATE_NO_HEALTH_BAR] = true,
  }

  return state
end


-----------------------------------------------------------------------

function modifier_bottle_selection:OnOrder( params )
	if IsServer() then
		local hOrderedUnit = params.unit
		local hTargetUnit = params.target
		local nOrderType = params.order_type
		if nOrderType ~= DOTA_UNIT_ORDER_MOVE_TO_TARGET then
			return
		end

		if hTargetUnit == nil or hTargetUnit ~= self:GetParent() then
			return
		end

		if hOrderedUnit ~= nil and hOrderedUnit:IsRealHero() then
      CustomGameEventManager:Send_ServerToPlayer(hOrderedUnit:GetPlayerOwner(), "show_announcement", nil )
			return
		end

	end

	return 0
end
-----------------------------------------------------------------------
