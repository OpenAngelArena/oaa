LinkLuaModifier("modifier_core_shrine", "abilities/misc/core_shrine.lua", LUA_MODIFIER_MOTION_NONE)

core_guy_score_limit = class(AbilityBaseClass)

function core_guy_score_limit:GetIntrinsicModifierName()
  return "modifier_core_shrine"
end

function core_guy_score_limit:OnSpellStart()
  self.timesUsed = self.timesUsed or 1
  self.timesUsed = self.timesUsed + 1

  if IsServer() then
    -- Increase the score limit
    PointsManager:IncreaseLimit()
  end
end

function core_guy_score_limit:GetCooldown()
  return (self.timesUsed or 1) * 60 * 10 -- first usage at 10 minutes
end
