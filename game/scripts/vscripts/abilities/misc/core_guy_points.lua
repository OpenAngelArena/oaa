
core_guy_points = class(AbilityBaseClass)

if IsServer() then
  function core_guy_points:OnAbilityPhaseStart()
    local caster = self:GetCaster();
    if self:GetManaCost() > caster.currentMana then
      return false
    end
    caster.currentMana = caster.currentMana - self:GetManaCost()
    return true
  end
end

function core_guy_points:OnSpellStart()
  local caster = self:GetCaster();

  self.timesUsed = self.timesUsed or 1
  self.timesUsed = self.timesUsed + 1

  if IsServer() then
    PointsManager:AddPoints(caster:GetTeamNumber(), 1)
  end
end

function core_guy_points:GetManaCost()
  return (self.timesUsed or 1) * 5
end
