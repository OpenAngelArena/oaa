modifier_echo_strike_oaa = class(ModifierBaseClass)

function modifier_echo_strike_oaa:IsHidden()
  return true
end

function modifier_echo_strike_oaa:IsPurgable()
  return false
end

function modifier_echo_strike_oaa:RemoveOnDeath()
  return false
end

function modifier_echo_strike_oaa:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_ATTACK_LANDED,
  }
end

function modifier_echo_strike_oaa:OnAttackLanded(event)
  if not IsServer() then
    return
  end

  local parent = self:GetParent()
  local attacker = event.attacker
  local target = event.target

  -- Check if attacker exists
  if not attacker or attacker:IsNull() then
    return
  end
  
  if not attacker.echo_strike_failure_counter then
    attacker.echo_strike_failure_counter = 0
  end

  -- Check if attacker has this modifier
  --if attacker ~= parent then
    --return
  --end

    -- Check if attacked unit exists
  if not target or target:IsNull() then
    return
  end

  -- Check for existence of GetUnitName method to determine if target is a unit or an item (or rune)
  -- items don't have that method -> nil; if the target is an item, don't continue
  if target.GetUnitName == nil then
    return
  end

  local chance = 25/100

  -- Get number of failures
  local prngMult = attacker.echo_strike_failure_counter + 1

  -- compared prng to slightly less prng
  if RandomFloat(0.0, 1.0) <= (PrdCFinder:GetCForP(chance) * prngMult) then
    -- Reset failure count
    attacker.echo_strike_failure_counter = 0

    -- Perform the second attack (can trigger attack modifiers)
    attacker:PerformAttack(target, false, true, true, false, false, false, false)
  else
    -- Increment number of failures
    attacker.echo_strike_failure_counter = prngMult
  end
end

--function modifier_echo_strike_oaa:GetTexture()
  --return ""
--end