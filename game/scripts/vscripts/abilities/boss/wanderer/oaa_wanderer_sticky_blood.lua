LinkLuaModifier("modifier_wanderer_sticky_blood_passive", "abilities/boss/wanderer/oaa_wanderer_sticky_blood.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_wanderer_sticky_blood_debuff", "abilities/boss/wanderer/oaa_wanderer_sticky_blood.lua", LUA_MODIFIER_MOTION_NONE)

wanderer_sticky_blood = class(AbilityBaseClass)

function wanderer_sticky_blood:Precache(context)
  PrecacheResource("particle", "particles/units/heroes/hero_batrider/batrider_stickynapalm_impact.vpcf", context)
  PrecacheResource("particle", "particles/status_fx/status_effect_stickynapalm.vpcf", context)
  PrecacheResource("particle", "particles/units/heroes/hero_batrider/batrider_napalm_damage_debuff.vpcf", context)
  PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_batrider.vsndevts", context)
end

function wanderer_sticky_blood:GetIntrinsicModifierName()
  return "modifier_wanderer_sticky_blood_passive"
end

function wanderer_sticky_blood:ShouldUseResources()
  return true
end

---------------------------------------------------------------------------------------------------

modifier_wanderer_sticky_blood_passive = class(ModifierBaseClass)

function modifier_wanderer_sticky_blood_passive:IsHidden()
  return true
end

function modifier_wanderer_sticky_blood_passive:IsDebuff()
  return false
end

function modifier_wanderer_sticky_blood_passive:IsPurgable()
  return false
end

function modifier_wanderer_sticky_blood_passive:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.duration = ability:GetSpecialValueFor("duration")
    self.threshold = ability:GetSpecialValueFor("damage_threshold")
  else
    self.duration = 8
    self.threshold = 50
  end
end

modifier_wanderer_sticky_blood_passive.OnRefresh = modifier_wanderer_sticky_blood_passive.OnCreated

function modifier_wanderer_sticky_blood_passive:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_TAKEDAMAGE,
  }
end

if IsServer() then
  function modifier_wanderer_sticky_blood_passive:OnTakeDamage(event)
    local caster = self:GetParent() or self:GetCaster()
    local ability = self:GetAbility()
    local attacker = event.attacker
    local damage = event.damage
    local damaged_unit = event.unit

    -- Don't continue if attacker doesn't exist or it is about to be deleted
    if not attacker or attacker:IsNull() then
      return
    end

    -- Check if damaged entity exists
    if not damaged_unit or damaged_unit:IsNull() then
      return
    end

    -- Continue only if the caster/parent is the damaged unit
    if damaged_unit ~= caster then
      return
    end

    -- Don't continue if caster is the attacker (self damage)
    if caster == attacker then
      return
    end

    -- Don't continue If ability doesn't exist
    if not ability or ability:IsNull() then
      return
    end

    -- if Wanderer is not aggroed -> don't continue (It will continue if caster.isAggro is true or nil - intentional)
    if caster.isAggro == false then
      return
    end

    -- Don't proc while on cooldown
    if not ability:IsCooldownReady() then
      return
    end

    -- Don't continue if the attacker entity doesn't have IsHero method -> attacker entity is something weird
    if attacker.IsHero == nil then
      return
    end

    local damage_threshold = self.threshold
    -- If the damage is below the threshold -> don't continue
    if damage <= damage_threshold then
      return
    end

    if attacker:IsHero() then
      self:ProcStickyBlood(caster, ability, attacker)
    elseif attacker.GetPlayerOwner then
      local player = attacker:GetPlayerOwner()
      local hero_owner
      if player then
        hero_owner = player:GetAssignedHero()
      end
      if not hero_owner then
        hero_owner = PlayerResource:GetSelectedHeroEntity(UnitVarToPlayerID(attacker))
      end
      if hero_owner then
        self:ProcStickyBlood(caster, ability, hero_owner)
      end
    end
  end
end

function modifier_wanderer_sticky_blood_passive:ProcStickyBlood(caster, ability, unit)
  -- If unit is dead, spell immune or in a duel, don't do anything
  if not unit:IsAlive() or unit:IsMagicImmune() or unit:IsDebuffImmune() or Duels:IsActive() then
    return
  end

  -- Proc Sound
  caster:EmitSound("Hero_Batrider.StickyNapalm.Cast")

  -- Proc Particle
  local napalm_impact_particle = ParticleManager:CreateParticle("particles/units/heroes/hero_batrider/batrider_stickynapalm_impact.vpcf", PATTACH_WORLDORIGIN, caster)
  ParticleManager:SetParticleControl(napalm_impact_particle, 0, unit:GetAbsOrigin())
  ParticleManager:SetParticleControl(napalm_impact_particle, 1, Vector(400, 0, 0))
  ParticleManager:SetParticleControl(napalm_impact_particle, 2, caster:GetAbsOrigin())
  ParticleManager:ReleaseParticleIndex(napalm_impact_particle)

  -- Sound on unit
  EmitSoundOnLocationWithCaster(unit:GetAbsOrigin(), "Hero_Batrider.StickyNapalm.Impact", caster)

  -- Apply debuff
  unit:AddNewModifier(caster, ability, "modifier_wanderer_sticky_blood_debuff", {duration = self.duration})

  -- Start cooldown
  ability:UseResources(false, false, false, true)
end

function modifier_wanderer_sticky_blood_passive:CheckState()
  return {
    [MODIFIER_STATE_CANNOT_BE_MOTION_CONTROLLED] = true,
  }
end

function modifier_wanderer_sticky_blood_passive:GetPriority()
  return MODIFIER_PRIORITY_SUPER_ULTRA + 10000
end

---------------------------------------------------------------------------------------------------

modifier_wanderer_sticky_blood_debuff = class(ModifierBaseClass)

function modifier_wanderer_sticky_blood_debuff:IsHidden()
  return false
end

function modifier_wanderer_sticky_blood_debuff:IsDebuff()
  return true
end

function modifier_wanderer_sticky_blood_debuff:IsPurgable()
  return true
end

function modifier_wanderer_sticky_blood_debuff:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.bonus_damage = ability:GetSpecialValueFor("damage_per_stack")
    self.move_speed_slow = ability:GetSpecialValueFor("movement_speed_pct")
    self.turn_speed_slow = ability:GetSpecialValueFor("turn_rate_pct")
  else
    self.bonus_damage = 100
    self.move_speed_slow = -5
    self.turn_speed_slow = -70
  end

  if IsServer() then
    self:SetStackCount(1)
  end
end

function modifier_wanderer_sticky_blood_debuff:OnRefresh()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.bonus_damage = ability:GetSpecialValueFor("damage_per_stack")
    self.move_speed_slow = ability:GetSpecialValueFor("movement_speed_pct")
    self.turn_speed_slow = ability:GetSpecialValueFor("turn_rate_pct")
  else
    self.bonus_damage = 100
    self.move_speed_slow = -5
    self.turn_speed_slow = -70
  end

  if IsServer() and self:GetStackCount() then
    self:IncrementStackCount()
  end
end

function modifier_wanderer_sticky_blood_debuff:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    MODIFIER_PROPERTY_TURN_RATE_PERCENTAGE,
    MODIFIER_EVENT_ON_ATTACK_LANDED,
  }
end

function modifier_wanderer_sticky_blood_debuff:GetModifierMoveSpeedBonus_Percentage()
  return math.min(self.move_speed_slow, self:GetStackCount() * self.move_speed_slow)
end

function modifier_wanderer_sticky_blood_debuff:GetModifierTurnRate_Percentage()
  return self.turn_speed_slow
end

if IsServer() then
  function modifier_wanderer_sticky_blood_debuff:OnAttackLanded(event)
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local attacker = event.attacker
    local target = event.target

    -- Check if attacker exists
    if not attacker or attacker:IsNull() then
      return
    end

    -- Check if attacked unit exists
    if not target or target:IsNull() then
      return
    end

    -- If attacked target isn't the parent -> don't continue
    if target ~= parent then
      return
    end

    -- If caster doesn't exist or it is about to be deleted -> don't continue
    if not caster or caster:IsNull() then
      return
    end

    -- If attacker isn't the caster -> don't continue
    if attacker ~= caster then
      return
    end

    -- Don't affect towers, wards, spell immune units and invulnerable units.
    if target:IsMagicImmune() or target:IsTower() or target:IsOther() or target:IsInvulnerable() then
      return
    end

    if not caster:IsIllusion() then
      -- Damage particle
      local damage_debuff_particle = ParticleManager:CreateParticle("particles/units/heroes/hero_batrider/batrider_napalm_damage_debuff.vpcf", PATTACH_ABSORIGIN, parent)
      ParticleManager:ReleaseParticleIndex(damage_debuff_particle)
      -- Apply damage
      local damage_table = {}
      damage_table.victim = parent
      damage_table.damage_type = DAMAGE_TYPE_PURE
      damage_table.damage_flags = DOTA_DAMAGE_FLAG_NONE
      damage_table.attacker = caster
      damage_table.ability = self:GetAbility()
      damage_table.damage = self.bonus_damage * self:GetStackCount()
      ApplyDamage(damage_table)
    end
  end
end

function modifier_wanderer_sticky_blood_debuff:GetStatusEffectName()
  return "particles/status_fx/status_effect_stickynapalm.vpcf"
end

function modifier_wanderer_sticky_blood_debuff:StatusEffectPriority()
  return MODIFIER_PRIORITY_LOW
end
