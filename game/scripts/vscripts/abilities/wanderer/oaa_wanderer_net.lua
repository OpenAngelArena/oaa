wanderer_net = class(AbilityBaseClass)

LinkLuaModifier("modifier_wanderer_net_cast", "abilities/wanderer/oaa_wanderer_net.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_wanderer_net_target", "abilities/wanderer/oaa_wanderer_net.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_wanderer_net_debuff", "abilities/wanderer/oaa_wanderer_net.lua", LUA_MODIFIER_MOTION_NONE)

function wanderer_net:Precache(context)
  PrecacheResource("particle", "particles/generic_gameplay/generic_has_quest.vpcf", context)
  PrecacheResource("particle", "particles/units/heroes/hero_siren/siren_net.vpcf", context)
  PrecacheResource("particle", "particles/units/heroes/hero_siren/siren_net_projectile.vpcf", context)
  PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_naga_siren.vsndevts", context)
end

function wanderer_net:GetIntrinsicModifierName()
  return "modifier_wanderer_net_cast"
end

function wanderer_net:OnSpellStart()
  local caster = self:GetCaster()
  local target = self:GetCursorTarget()

  if not target then
    return
  end

  local speed = self:GetSpecialValueFor("projectile_speed")
  -- Tracking Projectile table
  local info = {
    Target = target,
    Source = caster,
    Ability = self,
    bDodgeable = true,
    EffectName = "particles/units/heroes/hero_siren/siren_net_projectile.vpcf",
    iMoveSpeed = speed,
    --bProvidesVision = false,
    --bIsAttack = false,
    --bReplaceExisting = false,
    bIgnoreObstructions = false,
    --bVisibleToEnemies = true,
  }

  ProjectileManager:CreateTrackingProjectile(info)

  -- Calculate distance and max particle duration
  local distance = (target:GetAbsOrigin() - caster:GetAbsOrigin()):Length2D()
  local particle_duration = distance/speed

  -- Apply the warning particle (with a modifier)
  target:AddNewModifier(caster, self, "modifier_wanderer_net_target", {duration = particle_duration})

  -- Sound on cast
  caster:EmitSound("Hero_NagaSiren.Ensnare.Cast")
end

function wanderer_net:OnProjectileHit(target, location)
  -- If target doesn't exist or its about to be deleted -> don't continue
  if not target or target:IsNull() then
    return
  end

  -- Remove warning particle
  target:RemoveModifierByName("modifier_wanderer_net_target")

  -- Check for spell block
  if target:TriggerSpellAbsorb(self) then
    return
  end

  local caster = self:GetCaster()

  -- Check if caster was killed or deleted while Net was flying
  if not caster or caster:IsNull() then
    return
  end

  local duration = self:GetSpecialValueFor("duration")

  -- Apply the actual debuff
  target:AddNewModifier(caster, self, "modifier_wanderer_net_debuff", {duration = duration})

  -- Interrupt (mini-stun)
  target:Interrupt()

  -- Sound on target
  target:EmitSound("Hero_NagaSiren.Ensnare.Target")

  return true
end

---------------------------------------------------------------------------------------------------

modifier_wanderer_net_cast = class(ModifierBaseClass)

function modifier_wanderer_net_cast:IsHidden()
  return true
end

function modifier_wanderer_net_cast:IsDebuff()
  return false
end

function modifier_wanderer_net_cast:IsPurgable()
  return false
end

function modifier_wanderer_net_cast:DeclareFunctions()
  local funcs = {
    MODIFIER_EVENT_ON_ABILITY_START,
    MODIFIER_EVENT_ON_ABILITY_EXECUTED,
    MODIFIER_EVENT_ON_STATE_CHANGED,
    --MODIFIER_EVENT_ON_ORDER,
    --MODIFIER_EVENT_ON_DEATH,
  }
  return funcs
end

if IsServer() then
  function modifier_wanderer_net_cast:OnAbilityStart(event)
    local parent = self:GetParent()
    local ability = self:GetAbility()

    if event.unit ~= parent then
      return
    end

    if event.ability ~= ability then
      return
    end

    if not parent or parent:IsNull() or not ability or ability:IsNull() then
      return
    end

    self.warningFX = ParticleManager:CreateParticle("particles/generic_gameplay/generic_has_quest.vpcf", PATTACH_OVERHEAD_FOLLOW, parent)
    --self:AddParticle( self.warningFX, false, false, -1, false, true )

    local cast_point = ability:GetCastPoint()
    local interval = math.max(cast_point, 0.65) + 0.1

    self:StartIntervalThink(interval)
  end

  function modifier_wanderer_net_cast:OnIntervalThink()
    if self.warningFX then
      ParticleManager:DestroyParticle(self.warningFX, true)
      ParticleManager:ReleaseParticleIndex(self.warningFX)
      self.warningFX = nil
    end

    -- Stop thinking
    self:StartIntervalThink(-1)
  end

  function modifier_wanderer_net_cast:OnAbilityExecuted(event)
    local parent = self:GetParent()
    local ability = self:GetAbility()

    if event.unit ~= parent then
      return
    end

    if event.ability ~= ability then
      return
    end

    if not parent or parent:IsNull() or not ability or ability:IsNull() then
      return
    end

    if self.warningFX then
      ParticleManager:DestroyParticle(self.warningFX, true)
      ParticleManager:ReleaseParticleIndex(self.warningFX)
      self.warningFX = nil
    end
  end

  function modifier_wanderer_net_cast:OnStateChanged(event)
    local parent = self:GetParent()

    if event.unit ~= parent then
      return
    end

    if not parent or parent:IsNull() then
      if self.warningFX then
        ParticleManager:DestroyParticle(self.warningFX, true)
        ParticleManager:ReleaseParticleIndex(self.warningFX)
        self.warningFX = nil
      end
      return
    end

    if parent:IsSilenced() or parent:IsStunned() or parent:IsHexed() or parent:IsFrozen() or not parent:IsAlive() then
      if self.warningFX then
        ParticleManager:DestroyParticle(self.warningFX, true)
        ParticleManager:ReleaseParticleIndex(self.warningFX)
        self.warningFX = nil
      end
    end
  end
  --[[
  function modifier_wanderer_net_cast:OnDeath(event)
    local parent = self:GetParent()

    if event.unit ~= parent then
      return
    end

    if self.warningFX then
      ParticleManager:DestroyParticle(self.warningFX, true)
      ParticleManager:ReleaseParticleIndex(self.warningFX)
      self.warningFX = nil
    end
  end


  function modifier_wanderer_net_cast:OnOrder(event)
    local parent = self:GetParent()

    if event.unit ~= parent then
      return
    end

    if self.warningFX then
      ParticleManager:DestroyParticle(self.warningFX, true)
      ParticleManager:ReleaseParticleIndex(self.warningFX)
      self.warningFX = nil
    end
  end
  ]]
end

---------------------------------------------------------------------------------------------------

modifier_wanderer_net_target = class(ModifierBaseClass)

function modifier_wanderer_net_target:IsHidden()
  return true
end

function modifier_wanderer_net_target:IsDebuff()
  return false
end

function modifier_wanderer_net_target:IsPurgable()
  return false
end

function modifier_wanderer_net_target:GetEffectName()
  return "particles/generic_gameplay/generic_has_quest.vpcf"
end

function modifier_wanderer_net_target:GetEffectAttachType()
  return PATTACH_OVERHEAD_FOLLOW
end

---------------------------------------------------------------------------------------------------

modifier_wanderer_net_debuff = class(ModifierBaseClass)

function modifier_wanderer_net_debuff:IsHidden()
  return false
end

function modifier_wanderer_net_debuff:IsDebuff()
  return true
end

function modifier_wanderer_net_debuff:IsPurgable()
  return false
end

function modifier_wanderer_net_debuff:GetEffectName()
  return "particles/units/heroes/hero_siren/siren_net.vpcf"
end

function modifier_wanderer_net_debuff:GetEffectAttachType()
  return PATTACH_ABSORIGIN
end

function modifier_wanderer_net_debuff:CheckState()
  return {
    [MODIFIER_STATE_ROOTED] = true,
    [MODIFIER_STATE_PASSIVES_DISABLED] = true,
  }
end

function modifier_wanderer_net_debuff:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_DISABLE_HEALING,
  }
end

function modifier_wanderer_net_debuff:GetDisableHealing()
  return 1
end
