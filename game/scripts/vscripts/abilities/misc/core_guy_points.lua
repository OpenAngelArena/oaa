
core_guy_points = class(AbilityBaseClass)

function core_guy_points:GetIntrinsicModifierName ()
  return "modifier_core_shrine"
end

function core_guy_points:OnSpellStart()
  local caster = self:GetCaster();

  self.timesUsed = self.timesUsed or 1
  self.timesUsed = self.timesUsed + 1

  if IsServer() then
    PointsManager:AddPoints(caster:GetTeamNumber(), 1)
  end
end

function core_guy_points:GetCooldown()
  return (self.timesUsed or 1) * 5 * 10
end
