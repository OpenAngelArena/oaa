LinkLuaModifier("modifier_intrinsic_multiplexer", "modifiers/modifier_intrinsic_multiplexer.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_siege_mode_stacking_stats", "items/siege_mode.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_siege_mode_non_stacking_stats", "items/siege_mode.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_siege_mode_active", "items/siege_mode.lua", LUA_MODIFIER_MOTION_NONE)

---------------------------------------------------------------------------------------------------

item_siege_mode = class(TransformationBaseClass)

function item_siege_mode:GetIntrinsicModifierName()
  return "modifier_intrinsic_multiplexer"
end

function item_siege_mode:GetIntrinsicModifierNames()
  return {
    "modifier_item_siege_mode_stacking_stats",
    "modifier_item_siege_mode_non_stacking_stats"
  }
end

function item_siege_mode:GetTransformationModifierName()
  return "modifier_item_siege_mode_active"
end

item_siege_mode_2 = item_siege_mode

---------------------------------------------------------------------------------------------------

modifier_item_siege_mode_stacking_stats = class(ModifierBaseClass)

function modifier_item_siege_mode_stacking_stats:IsHidden()
  return true
end
function modifier_item_siege_mode_stacking_stats:IsDebuff()
  return false
end
function modifier_item_siege_mode_stacking_stats:IsPurgable()
  return false
end

function modifier_item_siege_mode_stacking_stats:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_siege_mode_stacking_stats:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.bonus_health = ability:GetSpecialValueFor("bonus_health")
    self.bonus_health_regen = ability:GetSpecialValueFor("bonus_health_regen")
    self.bonus_strength = ability:GetSpecialValueFor("bonus_strength")
    self.bonus_agility = ability:GetSpecialValueFor("bonus_agility")
    self.bonus_intellect = ability:GetSpecialValueFor("bonus_intellect")
  end
end

function modifier_item_siege_mode_stacking_stats:OnRefresh()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.bonus_health = ability:GetSpecialValueFor("bonus_health")
    self.bonus_health_regen = ability:GetSpecialValueFor("bonus_health_regen")
    self.bonus_strength = ability:GetSpecialValueFor("bonus_strength")
    self.bonus_agility = ability:GetSpecialValueFor("bonus_agility")
    self.bonus_intellect = ability:GetSpecialValueFor("bonus_intellect")
  end
end

function modifier_item_siege_mode_stacking_stats:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_HEALTH_BONUS,
    MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
    MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
    MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
    MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
  }
end

function modifier_item_siege_mode_stacking_stats:GetModifierHealthBonus()
  return self.bonus_health or self:GetAbility():GetSpecialValueFor("bonus_health")
end

function modifier_item_siege_mode_stacking_stats:GetModifierConstantHealthRegen()
  return self.bonus_health_regen or self:GetAbility():GetSpecialValueFor("bonus_health_regen")
end

function modifier_item_siege_mode_stacking_stats:GetModifierBonusStats_Strength()
  return self.bonus_strength or self:GetAbility():GetSpecialValueFor("bonus_strength")
end

function modifier_item_siege_mode_stacking_stats:GetModifierBonusStats_Agility()
  return self.bonus_agility or self:GetAbility():GetSpecialValueFor("bonus_agility")
end

function modifier_item_siege_mode_stacking_stats:GetModifierBonusStats_Intellect()
  return self.bonus_intellect or self:GetAbility():GetSpecialValueFor("bonus_intellect")
end

---------------------------------------------------------------------------------------------------
-- Parts of Siege Mode that should NOT stack with other Siege Modes

modifier_item_siege_mode_non_stacking_stats = class(ModifierBaseClass)

function modifier_item_siege_mode_non_stacking_stats:IsHidden()
  return true
end

function modifier_item_siege_mode_non_stacking_stats:IsDebuff()
  return false
end

function modifier_item_siege_mode_non_stacking_stats:IsPurgable()
  return false
end

function modifier_item_siege_mode_non_stacking_stats:OnCreated()
  local ability = self:GetAbility()

  if ability and not ability:IsNull() then
    self.attack_range = ability:GetSpecialValueFor("bonus_attack_range")
  end
end

function modifier_item_siege_mode_non_stacking_stats:OnRefresh()
  local ability = self:GetAbility()

  if ability and not ability:IsNull() then
    self.attack_range = ability:GetSpecialValueFor("bonus_attack_range")
  end
end

function modifier_item_siege_mode_non_stacking_stats:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
  }

  return funcs
end

function modifier_item_siege_mode_non_stacking_stats:GetModifierAttackRangeBonus()
  local parent = self:GetParent()
  if not parent:IsRangedAttacker() then
    return 0
  end

  -- Prevent stacking with Dragon Lance and Hurricane Pike
  if parent:HasModifier("modifier_item_dragon_lance") or parent:HasModifier("modifier_item_hurricane_pike") then
    return 0
  end

  return self.attack_range or self:GetAbility():GetSpecialValueFor("bonus_attack_range")
end

---------------------------------------------------------------------------------------------------

modifier_item_siege_mode_active = class(ModifierBaseClass)

function modifier_item_siege_mode_active:IsHidden()
  return false
end

function modifier_item_siege_mode_active:IsDebuff()
  return false
end

function modifier_item_siege_mode_active:IsPurgable()
  return true
end

function modifier_item_siege_mode_active:GetEffectName()
  return "particles/units/heroes/hero_oracle/oracle_fortune_purge_root_pnt.vpcf"
end

--[[
function modifier_item_siege_mode_active:OnCreated()
  local ability = self:GetAbility()

  if ability and not ability:IsNull() then
    self.atkRange = ability:GetSpecialValueFor("siege_attack_range")
    self.castRange = ability:GetSpecialValueFor("siege_cast_range")
    self.atkDmg = ability:GetSpecialValueFor("siege_attack_damage")
    self.atkRate = ability:GetSpecialValueFor("siege_attack_rate")
    self.moveSpeed = ability:GetSpecialValueFor("siege_move_speed")
    self.projectileSpeed = ability:GetSpecialValueFor("siege_projectile_speed")
  end

  if not IsServer() then
    return
  end

  local parent = self:GetParent()
  self.parentWasRanged = true
  -- Check if parent has Metamorphosis, Berserkers Rage, Dragon Form or True Form
  if not parent:HasModifier("modifier_terrorblade_metamorphosis") and not parent:HasAbility("troll_warlord_berserkers_rage") and not parent:HasModifier("modifier_dragon_knight_dragon_form") and not parent:HasModifier("modifier_lone_druid_true_form") then
    if not parent:IsRangedAttacker() then
      self.parentWasRanged = false
      parent:SetAttackCapability(DOTA_UNIT_CAP_RANGED_ATTACK)
    end
  end

  self:StartIntervalThink(0)
end

function modifier_item_siege_mode_active:OnRefresh()
  local ability = self:GetAbility()

  if ability and not ability:IsNull() then
    self.atkRange = ability:GetSpecialValueFor("siege_attack_range")
    self.castRange = ability:GetSpecialValueFor("siege_cast_range")
    self.atkDmg = ability:GetSpecialValueFor("siege_attack_damage")
    self.atkRate = ability:GetSpecialValueFor("siege_attack_rate")
    self.moveSpeed = ability:GetSpecialValueFor("siege_move_speed")
    self.projectileSpeed = ability:GetSpecialValueFor("siege_projectile_speed")
  end
end

function modifier_item_siege_mode_active:OnIntervalThink()
  if not IsServer() then
    return
  end

  local ability = self:GetAbility()
  if not ability or ability:IsNull() or ability:GetItemState() ~= 1 then
    self:StartIntervalThink(-1)
    self:Destroy()
  end
end
]]
function modifier_item_siege_mode_active:OnDestroy()
  if not IsServer() then
    return
  end

  local parent = self:GetParent()

  if not parent:IsRangedAttacker() then
    return
  end

  -- if self.parentWasRanged then
  parent:ChangeAttackProjectile()
    -- return
  -- end

  -- if parent:HasModifier("modifier_terrorblade_metamorphosis") or parent:HasAbility("troll_warlord_berserkers_rage") or parent:HasModifier("modifier_dragon_knight_dragon_form") or parent:HasModifier("modifier_lone_druid_true_form") then
    -- return
  -- end

  -- parent:SetAttackCapability(DOTA_UNIT_CAP_MELEE_ATTACK)
end

function modifier_item_siege_mode_active:DeclareFunctions()
  local funcs = {
    --MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
    --MODIFIER_PROPERTY_FIXED_ATTACK_RATE,
    --MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
    --MODIFIER_PROPERTY_CAST_RANGE_BONUS,
    --MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE,
    --MODIFIER_PROPERTY_PROJECTILE_SPEED_BONUS,
    MODIFIER_EVENT_ON_ATTACK_START,
    MODIFIER_EVENT_ON_ATTACK_LANDED,
    MODIFIER_EVENT_ON_ATTACK_FINISHED,
  }

  return funcs
end

-- function modifier_item_siege_mode_active:CheckState()
  -- if self:GetParent():IsRangedAttacker() then
    -- return {
      -- [MODIFIER_STATE_ROOTED] = true,
    -- }
  -- end
  -- return {}
-- end

--function modifier_item_siege_mode_active:GetModifierPreAttack_BonusDamage()
  --return self.atkDmg or 500
--end

--function modifier_item_siege_mode_active:GetModifierFixedAttackRate()
  --return self.atkRate or 0.7
--end

--function modifier_item_siege_mode_active:GetModifierAttackRangeBonus()
  --if self:GetParent():IsRangedAttacker() then
    --return self.atkRange or 600
  --end

  --return 0
--end

--function modifier_item_siege_mode_active:GetModifierCastRangeBonus()
  --return self.castRange or 0
--end

--function modifier_item_siege_mode_active:GetModifierMoveSpeed_Absolute()
  --return self.moveSpeed or 270
--end

--[[
function modifier_item_siege_mode_active:GetModifierProjectileSpeedBonus()
  local parent = self:GetParent()
  if not IsServer() or parent:HasModifier("modifier_item_princes_knife") then
    return 0
  end

  if self.checkProjectileSpeed then
    return 0
  else
    self.checkProjectileSpeed = true
    local projectile_speed = parent:GetProjectileSpeed()
    self.checkProjectileSpeed = false
    if projectile_speed > self.projectileSpeed then
      return self.projectileSpeed - projectile_speed
    end
  end

  return 0
end
]]

function modifier_item_siege_mode_active:OnAttackStart(event)
  if not IsServer() then
    return
  end

  local parent = self:GetParent()
  if event.attacker ~= parent then
    return
  end

  if not parent or parent:IsNull() then
    return
  end

  if not parent:IsRangedAttacker() then
    return
  end

  local target = event.target
  if not target or target:IsNull() then
    return
  end

  -- Only AttackStart is early enough to override the projectile
  parent:ChangeAttackProjectile()
end

function modifier_item_siege_mode_active:OnAttackLanded(event)
  if not IsServer() then
    return
  end

  local parent = self:GetParent()
  if event.attacker ~= parent then
    return
  end

  if not parent or parent:IsNull() then
    return
  end

  if parent:IsIllusion() then
    return
  end

  local target = event.target
  if not target or target:IsNull() then
    return
  end

  if target.GetUnitName == nil then
    return
  end

  -- Don't affect buildings, wards and invulnerable units.
  if target:IsTower() or target:IsBarracks() or target:IsBuilding() or target:IsOther() or target:IsInvulnerable() then
    return
  end

  local ability = self:GetAbility()
  if not ability or ability:IsNull() then
    return
  end

  local targetOrigin = target:GetAbsOrigin()

  -- set the targeting requirements for the actual targets
  local targetTeam = ability:GetAbilityTargetTeam()
  local targetType = ability:GetAbilityTargetType()
  local targetFlags = ability:GetAbilityTargetFlags()

  -- get the radius
  local splash_radius = ability:GetSpecialValueFor("active_splash_radius")
  local splash_damage = ability:GetSpecialValueFor("active_splash_damage")

  -- find all appropriate targets around the initial target
  local units = FindUnitsInRadius(
    parent:GetTeamNumber(),
    targetOrigin,
    nil,
    splash_radius,
    targetTeam,
    targetType,
    targetFlags,
    FIND_ANY_ORDER,
    false
  )

  -- get the wearer's damage
  local damage = event.original_damage

  -- get the damage modifier
  local actual_damage = damage*splash_damage*0.01

  -- Damage table
  local damage_table = {}
  damage_table.attacker = parent
  damage_table.damage_type = ability:GetAbilityDamageType() or DAMAGE_TYPE_PHYSICAL
  damage_table.ability = ability
  damage_table.damage = actual_damage
  damage_table.damage_flags = bit.bor(DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION, DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL)

  -- Show particle only if damage is above zero and only if there are units nearby
  if actual_damage > 0 and #units > 1 then
    local part = ParticleManager:CreateParticle("particles/econ/items/clockwerk/clockwerk_paraflare/clockwerk_para_rocket_flare_explosion.vpcf", PATTACH_CUSTOMORIGIN, target)
    ParticleManager:SetParticleControl(part, 3, targetOrigin)
    ParticleManager:ReleaseParticleIndex(part)
  end

  -- iterate through all targets
  for _, unit in pairs(units) do
    if unit and not unit:IsNull() and unit ~= target then
      damage_table.victim = unit
      ApplyDamage(damage_table)
    end
  end

  -- sound
  target:EmitSound("OAA_Item.SiegeMode.Explosion")
end

function modifier_item_siege_mode_active:OnAttackFinished(event)
  if not IsServer() then
    return
  end

  local parent = self:GetParent()
  if event.attacker == parent then

    if not parent:IsRangedAttacker() then
      return
    end

    -- Change the projectile (if a parent doesn't have modifier_item_siege_mode_active)
    parent:ChangeAttackProjectile()
  end
end

function modifier_item_siege_mode_active:GetTexture()
  return "custom/siege_mode_active"
end
