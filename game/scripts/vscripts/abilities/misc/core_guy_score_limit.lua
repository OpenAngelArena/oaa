
core_guy_score_limit = class(AbilityBaseClass)

function core_guy_score_limit:OnSpellStart()
  local caster = self:GetCaster();

  self.timesUsed = self.timesUsed or 0
  self.timesUsed = self.timesUsed + 1

  if IsServer() then
    print("Trying to increase score limit!")
    PointsManager:IncreaseLimit(10)
  end
end

function core_guy_score_limit:GetManaCost()
  return (self.timesUsed or 0) * 10
end
