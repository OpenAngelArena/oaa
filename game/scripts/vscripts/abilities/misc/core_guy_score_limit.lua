LinkLuaModifier("modifier_core_shrine", "abilities/misc/core_shrine.lua", LUA_MODIFIER_MOTION_NONE)

core_guy_score_limit = class(AbilityBaseClass)

function core_guy_score_limit:GetIntrinsicModifierName()
  return "modifier_core_shrine"
end

function core_guy_score_limit:OnSpellStart()
  -- self.timesUsed = self.timesUsed or 1
  -- self.timesUsed = self.timesUsed + 1

  if IsServer() then
    PointsManager.timesUsedShrine = PointsManager.timesUsedShrine + 1

    -- Increase the score limit
    PointsManager:IncreaseLimit()

    -- Start the same cooldown on both shrines
    local cooldown = PointsManager.timesUsedShrine * LIMIT_INCREASE_STARTING_COOLDOWN
    local radiant_shrine = PointsManager.radiant_shrine
    local dire_shrine = PointsManager.dire_shrine
    if radiant_shrine and not radiant_shrine:IsNull() then
      if radiant_shrine.ability then
        radiant_shrine.ability:EndCooldown()
        radiant_shrine.ability:StartCooldown(cooldown)
      end
    end
    if dire_shrine and not dire_shrine:IsNull() then
      if dire_shrine.ability then
        dire_shrine.ability:EndCooldown()
        dire_shrine.ability:StartCooldown(cooldown)
      end
    end

    -- Just in case if we add a neutral extension shrine or something fails
    self:EndCooldown()
    self:StartCooldown(cooldown)
  end
end

function core_guy_score_limit:GetCooldown()
  --return (self.timesUsed or 1) * 60 * 10
  if IsServer() then
    return PointsManager.timesUsedShrine * LIMIT_INCREASE_STARTING_COOLDOWN
  else
    return 60 * 10 -- TODO: Fix the cooldown display on the client when you hover over the ability after extending, not a major issue
  end
end
