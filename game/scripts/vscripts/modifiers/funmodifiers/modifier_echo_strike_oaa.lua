LinkLuaModifier("modifier_echo_strike_cooldown_oaa", "modifiers/funmodifiers/modifier_echo_strike_oaa.lua", LUA_MODIFIER_MOTION_NONE)

modifier_echo_strike_oaa = class(ModifierBaseClass)

function modifier_echo_strike_oaa:IsHidden()
  return false
end

function modifier_echo_strike_oaa:IsDebuff()
  return false
end

function modifier_echo_strike_oaa:IsPurgable()
  return false
end

function modifier_echo_strike_oaa:RemoveOnDeath()
  local parent = self:GetParent()
  if parent:IsRealHero() and not parent:IsOAABoss() then
    return false
  end
  return true
end

function modifier_echo_strike_oaa:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_ATTACK_LANDED,
  }
end

function modifier_echo_strike_oaa:OnCreated(kv)
  self.chance = 25
  self.cooldown = 0.8
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

if IsServer() then
  function modifier_echo_strike_oaa:OnAttackLanded(event)
    local parent = self:GetParent()
    local attacker = event.attacker
    local target = event.target

    -- Check if attacker exists
    if not attacker or attacker:IsNull() then
      return
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

    -- No need to proc if target is invulnerable or dead
    if target:IsInvulnerable() or target:IsOutOfGame() or not target:IsAlive() then
      return
    end

    -- Don't proc if passive is on cooldown
    if attacker:HasModifier("modifier_echo_strike_cooldown_oaa") then
      return
    end

    if RandomInt(1, 100) <= self.chance then
      local useCastAttackOrb = false
      local processProcs = true
      local skipCooldown = true
      local ignoreInvis = false
      local useProjectile = attacker:IsRangedAttacker() -- only ranged units need a projectile
      local fakeAttack = false
      local neverMiss = not attacker:IsRangedAttacker() -- only ranged units can miss

      -- Perform the second attack (can trigger attack modifiers)
      attacker:PerformAttack(target, useCastAttackOrb, processProcs, skipCooldown, ignoreInvis, useProjectile, fakeAttack, neverMiss)

      -- Start cooldown by adding a modifier
      attacker:AddNewModifier(attacker, nil, "modifier_echo_strike_cooldown_oaa", {duration = self.cooldown})
    end
  end
end

function modifier_echo_strike_oaa:GetTexture()
  if self:GetParent():IsRangedAttacker() then
    return "weaver_geminate_attack"
  else
    return "item_echo_sabre"
  end
end

---------------------------------------------------------------------------------------------------

modifier_echo_strike_cooldown_oaa = class(ModifierBaseClass)

function modifier_echo_strike_cooldown_oaa:IsHidden()
  return true
end

function modifier_echo_strike_cooldown_oaa:IsDebuff()
  return false
end

function modifier_echo_strike_cooldown_oaa:IsPurgable()
  return false
end
