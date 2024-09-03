LinkLuaModifier("modifier_boss_kraken_shell_passive", "abilities/boss/boss_kraken_shell.lua", LUA_MODIFIER_MOTION_NONE)

boss_kraken_shell = class(AbilityBaseClass)

function boss_kraken_shell:Precache(context)
  PrecacheResource("particle", "particles/units/heroes/hero_tidehunter/tidehunter_krakenshell_purge.vpcf", context)
  PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_tidehunter.vsndevts", context)
end

function boss_kraken_shell:GetIntrinsicModifierName()
  return "modifier_boss_kraken_shell_passive"
end

---------------------------------------------------------------------------------------------------

modifier_boss_kraken_shell_passive = class(ModifierBaseClass)

function modifier_boss_kraken_shell_passive:IsHidden()
  return true
end

function modifier_boss_kraken_shell_passive:IsDebuff()
  return false
end

function modifier_boss_kraken_shell_passive:IsPurgable()
  return false
end

function modifier_boss_kraken_shell_passive:RemoveOnDeath()
  return true
end

function modifier_boss_kraken_shell_passive:OnCreated()
	local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.damage_threshold = ability:GetSpecialValueFor("damage_threshold")
  else
    self.damage_threshold = 200
  end
end

function modifier_boss_kraken_shell_passive:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_TAKEDAMAGE
  }
end

if IsServer() then
  function modifier_boss_kraken_shell_passive:OnTakeDamage(event)
    local parent = self:GetParent()
    local attacker = event.attacker
    local damaged_unit = event.unit
    local damage = event.damage

    -- Check if attacker exists
    if not attacker or attacker:IsNull() then
      return
    end

    -- Check if damaged entity exists
    if not damaged_unit or damaged_unit:IsNull() then
      return
    end

    -- Check if damaged entity has this modifier
    if damaged_unit ~= parent then
      return
    end

    if parent:PassivesDisabled() or parent:IsIllusion() or not parent:IsAlive() then
      return
    end

    -- Don't trigger on self damage or on damage originating from allies
    if attacker == parent or attacker:GetTeamNumber() == parent:GetTeamNumber() then
      return
    end

    if damage <= 0 then
      return
    end

    -- Init dmg counter
    if not self.damage_received then
      self.damage_received = 0
    end

    -- Increase dmg counter
    self.damage_received = self.damage_received + damage

    if self.damage_received >= self.damage_threshold then
      -- Sound
      parent:EmitSound("Hero_Tidehunter.KrakenShell")

      -- Particle
      local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_tidehunter/tidehunter_krakenshell_purge.vpcf", PATTACH_ABSORIGIN, parent)
      ParticleManager:ReleaseParticleIndex(fx)

      -- Strong Dispel (for the boss)
      parent:Purge(false, true, false, true, true)

      -- Reset the dmg counter
      self.damage_received = 0
    end
  end
end
