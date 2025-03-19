LinkLuaModifier("modifier_item_giant_form_stacking_stats", "items/giant_form.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_giant_form_non_stacking_stats", "items/giant_form.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_giant_form_grow", "items/giant_form.lua", LUA_MODIFIER_MOTION_NONE)

---------------------------------------------------------------------------------------------------

item_giant_form = class(ItemBaseClass)

function item_giant_form:GetIntrinsicModifierName()
  return "modifier_intrinsic_multiplexer"
end

function item_giant_form:GetIntrinsicModifierNames()
  return {
    "modifier_item_giant_form_stacking_stats",
    "modifier_item_giant_form_non_stacking_stats"
  }
end

function item_giant_form:OnSpellStart()
  local caster = self:GetCaster()

  -- Apply Giant Form buff to caster
  caster:AddNewModifier(caster, self, "modifier_item_giant_form_grow", {duration = self:GetSpecialValueFor("duration")})

  -- Activation Sound
  caster:EmitSound("Hero_Treant.Overgrowth.CastAnim")
end

item_giant_form_2 = item_giant_form

---------------------------------------------------------------------------------------------------

modifier_item_giant_form_stacking_stats = class(ModifierBaseClass)

function modifier_item_giant_form_stacking_stats:IsHidden()
  return true
end

function modifier_item_giant_form_stacking_stats:IsDebuff()
  return false
end

function modifier_item_giant_form_stacking_stats:IsPurgable()
  return false
end

function modifier_item_giant_form_stacking_stats:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_giant_form_stacking_stats:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.bonus_health_regen = ability:GetSpecialValueFor("bonus_health_regen")
    self.bonus_damage = ability:GetSpecialValueFor("bonus_damage")
  end
end

modifier_item_giant_form_stacking_stats.OnRefresh = modifier_item_giant_form_stacking_stats.OnCreated

function modifier_item_giant_form_stacking_stats:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
    MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
    MODIFIER_EVENT_ON_ATTACK_LANDED,
  }
end

function modifier_item_giant_form_stacking_stats:GetModifierConstantHealthRegen()
  return self.bonus_health_regen or self:GetAbility():GetSpecialValueFor("bonus_health_regen")
end

function modifier_item_giant_form_stacking_stats:GetModifierPreAttack_BonusDamage()
  return self.bonus_damage or self:GetAbility():GetSpecialValueFor("bonus_damage")
end

if IsServer() then
  function modifier_item_giant_form_stacking_stats:OnAttackLanded(event)
    local parent = self:GetParent()
    if event.attacker ~= parent then
      return
    end

    if not parent or parent:IsNull() then
      return
    end

    if parent:IsIllusion() or parent:IsRangedAttacker() then
      return
    end

    -- Prevent some instant attacks proccing the cleave
    if event.no_attack_cooldown and not parent:InstantAttackCanProcCleave() then
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

    -- get the cleave parameters
    local start_radius = ability:GetSpecialValueFor("cleave_starting_width")
    local end_radius = ability:GetSpecialValueFor("cleave_ending_width")
    local distance = ability:GetSpecialValueFor("cleave_distance")
    local percent = ability:GetSpecialValueFor("cleave_percent")

    -- get the wearer's damage
    local damage = event.original_damage

    -- get the damage modifier
    local actual_damage = damage*percent*0.01

    DoCleaveAttack(parent, target, ability, actual_damage, start_radius, end_radius, distance, "particles/items_fx/battlefury_cleave.vpcf")
  end
end

---------------------------------------------------------------------------------------------------

modifier_item_giant_form_non_stacking_stats = class(ModifierBaseClass)

function modifier_item_giant_form_non_stacking_stats:IsHidden()
  return true
end

function modifier_item_giant_form_non_stacking_stats:IsDebuff()
  return false
end

function modifier_item_giant_form_non_stacking_stats:IsPurgable()
  return false
end

function modifier_item_giant_form_non_stacking_stats:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.range = ability:GetSpecialValueFor("bonus_attack_range_melee")
  end
end

modifier_item_giant_form_non_stacking_stats.OnRefresh = modifier_item_giant_form_non_stacking_stats.OnCreated

function modifier_item_giant_form_non_stacking_stats:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
  }
end

function modifier_item_giant_form_non_stacking_stats:GetModifierAttackRangeBonus()
  if self:GetParent():IsRangedAttacker() then
    return 0
  end

  return self.range or self:GetAbility():GetSpecialValueFor("bonus_attack_range_melee")
end

---------------------------------------------------------------------------------------------------

modifier_item_giant_form_grow = class(ModifierBaseClass)

function modifier_item_giant_form_grow:IsHidden()
  return false
end

function modifier_item_giant_form_grow:IsDebuff()
  return false
end

function modifier_item_giant_form_grow:IsPurgable()
  return true
end

function modifier_item_giant_form_grow:OnCreated()
  self:OnRefresh()
  if IsServer() then
    self:StartIntervalThink(0.1)
  end
end

function modifier_item_giant_form_grow:OnRefresh()
  local ability = self:GetAbility()
  if not ability or ability:IsNull() then
    return
  end

  self.atkDmg = ability:GetSpecialValueFor("giant_attack_damage")
  self.atkSpeed = ability:GetSpecialValueFor("giant_attack_speed_reduction")
  self.scale = ability:GetSpecialValueFor("giant_scale")
  self.bonus_to_primary_stat = ability:GetSpecialValueFor("giant_primary_attribute_bonus")

  self.bonus_stat_for_universal = math.ceil(self.bonus_to_primary_stat/3)
end

if IsServer() then
  function modifier_item_giant_form_grow:OnIntervalThink()
    local parent = self:GetParent()

    if not parent or parent:IsNull() then
      self:StartIntervalThink(-1)
      return
    end

    local attribute = parent:GetPrimaryAttribute()
    self:SetStackCount(0 - attribute)
    -- We can stop the interval if dynamic changing of the primary attribute doesn't exist
    -- Morphling ultimate changes primary attribute ...
    self:StartIntervalThink(-1)
  end
end

function modifier_item_giant_form_grow:CheckState()
  return {
    [MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
  }
end

function modifier_item_giant_form_grow:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
    MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
    MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
    MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
    --MODIFIER_PROPERTY_ATTACKSPEED_REDUCTION_PERCENTAGE,
    --MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
    MODIFIER_PROPERTY_ATTACKSPEED_PERCENTAGE,
    MODIFIER_PROPERTY_MODEL_SCALE,
    MODIFIER_EVENT_ON_ATTACK_LANDED,
  }
end

function modifier_item_giant_form_grow:GetModifierBonusStats_Strength()
  local attribute = math.abs(self:GetStackCount())
  if attribute == DOTA_ATTRIBUTE_STRENGTH then
    return self.bonus_to_primary_stat
  elseif attribute == DOTA_ATTRIBUTE_ALL then
    return self.bonus_stat_for_universal
  end
  return 0
end

function modifier_item_giant_form_grow:GetModifierBonusStats_Agility()
  local attribute = math.abs(self:GetStackCount())
  if attribute == DOTA_ATTRIBUTE_AGILITY then
    return self.bonus_to_primary_stat
  elseif attribute == DOTA_ATTRIBUTE_ALL then
    return self.bonus_stat_for_universal
  end
  return 0
end

function modifier_item_giant_form_grow:GetModifierBonusStats_Intellect()
  local attribute = math.abs(self:GetStackCount())
  if attribute == DOTA_ATTRIBUTE_INTELLECT then
    return self.bonus_to_primary_stat
  elseif attribute == DOTA_ATTRIBUTE_ALL then
    return self.bonus_stat_for_universal
  end
  return 0
end

function modifier_item_giant_form_grow:GetModifierPreAttack_BonusDamage()
  return self.atkDmg
end

function modifier_item_giant_form_grow:GetModifierModelScale()
  return self.scale
end

--function modifier_item_giant_form_grow:GetModifierAttackSpeedReductionPercentage()
  --return 0 - math.abs(self.atkSpeed)
--end

function modifier_item_giant_form_grow:GetModifierAttackSpeedPercentage()
  return 0 - math.abs(self.atkSpeed)
end

if IsServer() then
  -- function modifier_item_giant_form_grow:GetModifierAttackSpeedBonus_Constant()
    -- local parent = self:GetParent()
    -- if self.checkAttackSpeed then
      -- return 0
    -- else
      -- self.checkAttackSpeed = true
      -- local attack_speed = parent:GetAttackSpeed() * 100
      -- self.checkAttackSpeed = false
      -- return -attack_speed*0.01*self.atkSpeed
    -- end
  -- end

  function modifier_item_giant_form_grow:OnAttackLanded(event)
    local parent = self:GetParent()
    if event.attacker ~= parent then
      return
    end

    if not parent or parent:IsNull() then
      return
    end

    if parent:IsIllusion() or parent:IsRangedAttacker() then
      return
    end

    -- Prevent some instant attacks proccing the cleave
    if event.no_attack_cooldown and not parent:InstantAttackCanProcCleave() then
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
    local splash_radius = ability:GetSpecialValueFor("giant_splash_radius")
    local splash_damage = ability:GetSpecialValueFor("giant_splash_damage")

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
    local damage_table = {
      attacker = parent,
      damage = actual_damage,
      damage_type = DAMAGE_TYPE_PHYSICAL,
      damage_flags = bit.bor(DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION, DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL),
      ability = ability,
    }

    -- Show particle only if damage is above zero and only if there are units nearby
    if actual_damage > 0 and #units > 1 then
      local particle = ParticleManager:CreateParticle("particles/items/powertreads_splash.vpcf", PATTACH_POINT, target)
      ParticleManager:SetParticleControl(particle, 5, Vector(1, 0, splash_radius))
      ParticleManager:ReleaseParticleIndex(particle)
    end

    -- iterate through all targets
    for _, unit in pairs(units) do
      if unit and not unit:IsNull() and unit ~= target then
        damage_table.victim = unit
        ApplyDamage(damage_table)
      end
    end

    -- sound
    --target:EmitSound("")
  end
end

function modifier_item_giant_form_grow:GetTexture()
  return "custom/giant_form_2_active"
end
