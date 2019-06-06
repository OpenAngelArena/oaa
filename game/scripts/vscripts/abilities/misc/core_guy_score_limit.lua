
core_guy_score_limit = class(AbilityBaseClass)

if IsServer() then
  function core_guy_score_limit:OnAbilityPhaseStart()
    local caster = self:GetCaster();
    if self:GetManaCost() > caster.currentMana then
      return false
    end
    caster.currentMana = caster.currentMana - self:GetManaCost()
    return true
  end
end

function core_guy_score_limit:OnSpellStart()
  local caster = self:GetCaster();

  self.timesUsed = self.timesUsed or 1
  self.timesUsed = self.timesUsed + 1

  if IsServer() then
    print("Trying to increase score limit!")
    PointsManager:IncreaseLimit(10)
  end
end

function core_guy_score_limit:GetManaCost()
  return (self.timesUsed or 1) * 100
end
