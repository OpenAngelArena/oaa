modifier_echo_strike_oaa = class(ModifierBaseClass)

function modifier_echo_strike_oaa:IsHidden()
  return false
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

function modifier_echo_strike_oaa:OnCreated(kv)
  self.global = kv.isGlobal == 1

  if not self.global and IsServer() then
    local global_option = OAAOptions.settings.GLOBAL_MODS
    local global_mod = OAAOptions.global_mod
    if global_mod == false and global_option == "GM05" then
      print("modifier_echo_strike_oaa - Don't create multiple modifiers if there is a global one")
      self:Destroy()
    end
  end
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
  if not self.global then
    if attacker ~= parent then
      return
    end
  end

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
    attacker:PerformAttack(target, false, true, true, false, true, false, false)
  else
    -- Increment number of failures
    attacker.echo_strike_failure_counter = prngMult
  end
end

function modifier_echo_strike_oaa:GetTexture()
  if self:GetParent():IsRangedAttacker() then
    return "weaver_geminate_attack"
  else
    return "item_echo_sabre"
  end
end
