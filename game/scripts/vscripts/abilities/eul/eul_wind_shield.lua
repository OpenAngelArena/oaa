LinkLuaModifier("modifier_eul_wind_shield_passive", "abilities/eul/eul_wind_shield.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_eul_wind_shield_active", "abilities/eul/eul_wind_shield.lua", LUA_MODIFIER_MOTION_NONE) -- needs tooltip
LinkLuaModifier("modifier_eul_wind_shield_tornado_barrier", "abilities/eul/eul_wind_shield.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_eul_wind_shield_ventus", "abilities/eul/eul_wind_shield.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_eul_wind_shield_ventus_ally", "abilities/eul/eul_wind_shield.lua", LUA_MODIFIER_MOTION_NONE) -- needs tooltip

eul_wind_shield_oaa = class(AbilityBaseClass)

function eul_wind_shield_oaa:GetAOERadius()
  return self:GetSpecialValueFor("evasion_range_check")
end

function eul_wind_shield_oaa:GetIntrinsicModifierName()
	return "modifier_eul_wind_shield_passive"
end

function eul_wind_shield_oaa:OnSpellStart()
  local caster = self:GetCaster()

  -- Cast sound
  caster:EmitSound("Eul.WindControl")

  local duration = self:GetSpecialValueFor("active_duration")

  -- Apply the move speed and attack speed buff
  caster:AddNewModifier(caster, self, "modifier_eul_wind_shield_active", {duration = duration})

  -- Check for Tornado Barrier
  local shield = self:GetSpecialValueFor("all_damage_block") > 0
  if shield then
    caster:AddNewModifier(caster, self, "modifier_eul_wind_shield_tornado_barrier", {duration = duration})
  end

  -- Check for Ventus Deflect
  local deflect = self:GetSpecialValueFor("attack_projectile_deflect") == 1
  if deflect then
    caster:AddNewModifier(caster, self, "modifier_eul_wind_shield_ventus", {duration = duration})
  end
end

function eul_wind_shield_oaa:OnProjectileHit_ExtraData(target, location, extra_data)
  if not target or not location or not extra_data then
    return
  end

  local caster = self:GetCaster()
  local attacker_index = extra_data.attacker
  local original_attacker
  if attacker_index then
    original_attacker = EntIndexToHScript(attacker_index)
  end

  if not original_attacker or original_attacker:IsNull() then
    -- Imitate an attack because original attacker doesn't exist anymore
    local original_damage = extra_data.damage

    if not original_damage then
      return
    end

    -- Hit Sound
    target:EmitSound("Eul.Attack.Impact")

    local damage_table = {
      attacker = caster,
      victim = target,
      damage = original_damage,
      damage_type = DAMAGE_TYPE_PHYSICAL,
      damage_flags = DOTA_DAMAGE_FLAG_REFLECTION + DOTA_DAMAGE_FLAG_BYPASSES_PHYSICAL_BLOCK + DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION + DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL,
      ability = self,
    }

    ApplyDamage(damage_table)

    return true
  end

  -- Original attacker attacks the target (it will proc everything original attacker has, attack sound etc.)
  original_attacker:PerformAttack(target, true, true, true, false, false, false, false)

  return true
end

function eul_wind_shield_oaa:OnUnStolen()
  local caster = self:GetCaster()
  caster:RemoveModifierByName(self:GetIntrinsicModifierName())
end

---------------------------------------------------------------------------------------------------

modifier_eul_wind_shield_passive = class(ModifierBaseClass)

function modifier_eul_wind_shield_passive:IsHidden()
  return true
end

function modifier_eul_wind_shield_passive:IsDebuff()
  return false
end

function modifier_eul_wind_shield_passive:IsPurgable()
  return false
end

function modifier_eul_wind_shield_passive:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.move_speed_p = ability:GetSpecialValueFor("passive_move_speed")
    self.move_speed_a = ability:GetSpecialValueFor("active_move_speed")
  end
end

modifier_eul_wind_shield_passive.OnRefresh = modifier_eul_wind_shield_passive.OnCreated

function modifier_eul_wind_shield_passive:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_EVASION_CONSTANT,
    MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
  }
end

function modifier_eul_wind_shield_passive:GetModifierEvasion_Constant(params)
  if not IsServer() then
    return
  end

  local parent = self:GetParent()
  local ability = self:GetAbility()
  local attacker = params.attacker
  --local attacked_unit = params.unit

  if not attacker:IsRangedAttacker() then
    return 0
  end

  if parent:PassivesDisabled() then
    return 0
  end

  -- if parent ~= attacked_unit then
    -- print("Attacked unit:")
    -- print(attacked_unit)
  -- end

  -- if parent ~= attacker:GetAttackTarget() then
    -- print("GetAttackTarget")
    -- print(attacker:GetAttackTarget())
  -- end

  local distance = (parent:GetAbsOrigin() - attacker:GetAbsOrigin()):Length2D()
  if distance > ability:GetSpecialValueFor("evasion_range_check") then
    return ability:GetSpecialValueFor("evasion")
  end

  return 0
end

function modifier_eul_wind_shield_passive:GetModifierMoveSpeedBonus_Percentage()
  local parent = self:GetParent()
  if parent:HasModifier("modifier_eul_wind_shield_active") then
    return self.move_speed_a or 20
  end

  if parent:PassivesDisabled() then
    return 0
  end

  return self.move_speed_p or 4
end

---------------------------------------------------------------------------------------------------

modifier_eul_wind_shield_active = class(ModifierBaseClass)

function modifier_eul_wind_shield_active:IsHidden()
  return false
end

function modifier_eul_wind_shield_active:IsDebuff()
  return false
end

function modifier_eul_wind_shield_active:IsPurgable()
  return true
end

function modifier_eul_wind_shield_active:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.attack_speed = ability:GetSpecialValueFor("active_attack_speed")
  end
end

modifier_eul_wind_shield_active.OnRefresh = modifier_eul_wind_shield_active.OnCreated

function modifier_eul_wind_shield_active:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
  }
end

function modifier_eul_wind_shield_active:GetModifierAttackSpeedBonus_Constant()
  return self.attack_speed or 20
end

function modifier_eul_wind_shield_active:GetEffectName()
  return "particles/units/heroes/hero_windrunner/windrunner_windrun.vpcf"
end

function modifier_eul_wind_shield_active:GetEffectAttachType()
  return PATTACH_CENTER_FOLLOW --PATTACH_ABSORIGIN_FOLLOW
end

---------------------------------------------------------------------------------------------------

modifier_eul_wind_shield_tornado_barrier = class(ModifierBaseClass)

function modifier_eul_wind_shield_tornado_barrier:IsHidden()
  return true
end

function modifier_eul_wind_shield_tornado_barrier:IsDebuff()
  return false
end

function modifier_eul_wind_shield_tornado_barrier:IsPurgable()
  return true
end

function modifier_eul_wind_shield_tornado_barrier:OnCreated()
  local shield_hp = 0

  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    shield_hp = ability:GetSpecialValueFor("all_damage_block")
  end

  self.max_shield_hp = shield_hp

  if IsServer() then
    self:SetStackCount(0 - shield_hp)
  end
end

modifier_eul_wind_shield_tornado_barrier.OnRefresh = modifier_eul_wind_shield_tornado_barrier.OnCreated

function modifier_eul_wind_shield_tornado_barrier:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_INCOMING_DAMAGE_CONSTANT,
  }
end

function modifier_eul_wind_shield_tornado_barrier:GetModifierIncomingDamageConstant(event)
  local parent = self:GetParent()

  if not parent or parent:IsNull() then
    return 0
  end

  if IsClient() then
    -- Shield numbers (visual only)
    if event.report_max then
      return self.max_shield_hp
    else
      return math.abs(self:GetStackCount()) -- current shield hp
    end
  else
    -- Don't react to damage with HP removal flag
    if bit.band(event.damage_flags, DOTA_DAMAGE_FLAG_HPLOSS) == DOTA_DAMAGE_FLAG_HPLOSS then
      return 0
    end

    -- Don't react on self damage
    if event.attacker == parent then
      return 0
    end

    local damage = event.damage
    if damage < 0 then
      return 0
    end

    -- Get current (remaining) shield hp
    local shield_hp = math.abs(self:GetStackCount())

    -- Don't block more than remaining hp
    local block_amount = math.min(damage, shield_hp)

    -- Reduce shield hp (using negative stacks to not show them on the buff)
    self:SetStackCount(block_amount - shield_hp)

    -- Remove the shield if hp is reduced to nothing
    if self:GetStackCount() >= 0 then
      self:Destroy()
    end

    return -block_amount
  end
end

---------------------------------------------------------------------------------------------------

modifier_eul_wind_shield_ventus = class(ModifierBaseClass)

function modifier_eul_wind_shield_ventus:IsHidden()
  return true
end

function modifier_eul_wind_shield_ventus:IsDebuff()
  return false
end

function modifier_eul_wind_shield_ventus:IsPurgable() -- IsAura overrides this so we do OnIntervalThink
  return true
end

function modifier_eul_wind_shield_ventus:IsAura()
  return true
end

function modifier_eul_wind_shield_ventus:OnCreated()
  self.aura_radius = 0

  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.aura_radius = ability:GetSpecialValueFor("deflect_aura_radius")
  end

  if IsServer() then
    -- Start thinking
    self:StartIntervalThink(0)
  end
end

function modifier_eul_wind_shield_ventus:OnRefresh()
  self.aura_radius = self.aura_radius or 0

  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.aura_radius = ability:GetSpecialValueFor("deflect_aura_radius")
  end
end

function modifier_eul_wind_shield_ventus:OnIntervalThink()
  if not IsServer() then
    return
  end

  local parent = self:GetParent()
  if not parent or parent:IsNull() then
    self:StartIntervalThink(-1)
    return
  end

  -- Check if parent is dead
  if not parent:IsAlive() then
    self:StartIntervalThink(-1)
    return
  end

  -- Check if parent still has the primary buff
  if not parent:HasModifier("modifier_eul_wind_shield_active") then
    self:StartIntervalThink(-1)
    self:Destroy() -- manual purge
  end
end

function modifier_eul_wind_shield_ventus:GetModifierAura()
  return "modifier_eul_wind_shield_ventus_ally"
end

function modifier_eul_wind_shield_ventus:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_eul_wind_shield_ventus:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC)
end

function modifier_eul_wind_shield_ventus:GetAuraSearchFlags()
  return DOTA_UNIT_TARGET_FLAG_INVULNERABLE
end

function modifier_eul_wind_shield_ventus:GetAuraRadius()
  return self.aura_radius
end

function modifier_eul_wind_shield_ventus:DeclareFunctions()
  return {
    --MODIFIER_PROPERTY_AVOID_DAMAGE,
    MODIFIER_EVENT_ON_ATTACK_LANDED,
  }
end

-- 'modifier_eul_wind_shield_ventus_ally' does this and aura always applies to caster unless specified otherwise
-- function modifier_eul_wind_shield_ventus:GetModifierAvoidDamage(event)
  -- if event.ranged_attack == true and event.damage_category == DOTA_DAMAGE_CATEGORY_ATTACK then
    -- return 1
  -- end

  -- return 0
-- end

-- Attack deflection is basically 'damage avoid' + deflect attack projectile if it landed (evasion/miss didn't do its thing)
-- So attack deflection is anti-synergystic with Evasion and Miss chance but it counters True Strike and Accuracy
if IsServer() then
  function modifier_eul_wind_shield_ventus:OnAttackLanded(event)
    local parent = self:GetParent()
    local ability = self:GetAbility()
    local attacker = event.attacker
    local target = event.target

    -- Check if attacker exists
    if not attacker or attacker:IsNull() then
      return
    end

    -- Check if attacked entity exists
    if not target or target:IsNull() then
      return
    end

    -- Check if it's ranged attack, melee attacks should go through
    if not event.ranged_attack then
      return
    end

    -- Check for existence of GetUnitName method to determine if target is a unit or an item (or rune)
    -- items don't have that method -> nil; if the target is an item, don't continue
    if target.GetUnitName == nil then
      return
    end

    -- No need to proc if target is invulnerable, banished or dead
    if target:IsInvulnerable() or target:IsOutOfGame() or not target:IsAlive() then
      return
    end

    local team = target:GetTeamNumber()

    -- Check attacked entity team
    if team ~= parent:GetTeamNumber() then
      return
    end

    local target_location = target:GetAbsOrigin()
    local parent_location = parent:GetAbsOrigin()
    local aura_radius = self.aura_radius
    local distance = (target_location - parent_location):Length2D()

    -- Check distance to the parent
    if distance > aura_radius then
      return
    end

    local speed_pct = ability:GetSpecialValueFor("deflected_projectile_speed_pct")
    local vision_radius = ability:GetSpecialValueFor("deflected_projectile_vision")
    local buffer_range = ability:GetSpecialValueFor("deflect_buffer_range")

    local search_radius = attacker:GetAttackRange() + buffer_range

    -- Find closest enemy
    local enemies = FindUnitsInRadius(
      team,
      target_location,
      nil,
      search_radius,
      DOTA_UNIT_TARGET_TEAM_ENEMY,
      DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
      DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_NO_INVIS + DOTA_UNIT_TARGET_FLAG_NOT_ATTACK_IMMUNE,
      FIND_CLOSEST,
      false
    )

    local closest = enemies[1]

    -- If not found, don't continue
    if not closest then
      return
    end

    local info = {
      EffectName = attacker:GetRangedProjectileName(),
      Ability = ability,
      Source = target,
      vSourceLoc = target_location,
      Target = closest,
      iMoveSpeed = attacker:GetProjectileSpeed() * speed_pct * 0.01,
      bDodgeable = true,
      bProvidesVision = true,
      iVisionRadius = vision_radius,
      iVisionTeamNumber = team,
      --bIsAttack = true,
      --bReplaceExisting = false,
      --bIgnoreObstructions = false,
      iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_1, -- DOTA_PROJECTILE_ATTACHMENT_HITLOCATION
      bDrawsOnMinimap = false,
      bVisibleToEnemies = true,
      ExtraData = {
        attacker = attacker:GetEntityIndex(),
        damage = event.original_damage,
      }
    }

    -- Deflect the attack projectile to nearest enemy
    ProjectileManager:CreateTrackingProjectile(info)

    -- Deflect sound
    target:EmitSound("Eul.VentusProjectile")
  end
end

---------------------------------------------------------------------------------------------------

modifier_eul_wind_shield_ventus_ally = class(ModifierBaseClass)

function modifier_eul_wind_shield_ventus_ally:IsHidden()
  return false
end

function modifier_eul_wind_shield_ventus_ally:IsDebuff()
  return false
end

function modifier_eul_wind_shield_ventus_ally:IsPurgable() -- it's an aura buff so doesn't really work
  return true
end

function modifier_eul_wind_shield_ventus_ally:OnCreated()
  if IsServer() then
    local parent = self:GetParent()
     -- Particle
    self.part = ParticleManager:CreateParticle("particles/econ/items/windrunner/windranger_arcana/windranger_arcana_shackleshot_bolo_tornado_swirl.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
    ParticleManager:SetParticleControlEnt(self.part, 4, parent, PATTACH_ROOTBONE_FOLLOW, "attach_origin", Vector(0, 0, 0), false)
  end
end

function modifier_eul_wind_shield_ventus_ally:OnDestroy()
  if self.part then
    ParticleManager:DestroyParticle(self.part, true)
    ParticleManager:ReleaseParticleIndex(self.part)
  end
end

function modifier_eul_wind_shield_ventus_ally:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_AVOID_DAMAGE,
  }
end

-- Bug: Attack modifiers (debuffs on attack) are still applied
function modifier_eul_wind_shield_ventus_ally:GetModifierAvoidDamage(event)
  if event.ranged_attack == true and event.damage_category == DOTA_DAMAGE_CATEGORY_ATTACK then
    return 1
  end

  return 0
end
