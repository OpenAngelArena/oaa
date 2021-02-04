LinkLuaModifier("modifier_item_giant_form_passive", "items/giant_form.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_giant_form_grow", "items/giant_form.lua", LUA_MODIFIER_MOTION_NONE)

---------------------------------------------------------------------------------------------------

item_giant_form = class(TransformationBaseClass)

function item_giant_form:GetIntrinsicModifierName()
  return "modifier_item_giant_form_passive"
end

function item_giant_form:GetTransformationModifierName()
  return "modifier_item_giant_form_grow"
end

item_giant_form_2 = item_giant_form

---------------------------------------------------------------------------------------------------

modifier_item_giant_form_passive = class(ModifierBaseClass)

function modifier_item_giant_form_passive:IsHidden()
  return true
end
function modifier_item_giant_form_passive:IsDebuff()
  return false
end
function modifier_item_giant_form_passive:IsPurgable()
  return false
end

function modifier_item_giant_form_passive:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_giant_form_passive:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.bonus_health_regen = ability:GetSpecialValueFor("bonus_health_regen")
    self.bonus_strength = ability:GetSpecialValueFor("bonus_strength")
    self.bonus_damage = ability:GetSpecialValueFor("bonus_damage")
  end
end

function modifier_item_giant_form_passive:OnRefresh()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.bonus_health_regen = ability:GetSpecialValueFor("bonus_health_regen")
    self.bonus_strength = ability:GetSpecialValueFor("bonus_strength")
    self.bonus_damage = ability:GetSpecialValueFor("bonus_damage")
  end
end

function modifier_item_giant_form_passive:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
    MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
    MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
  }
end

function modifier_item_giant_form_passive:GetModifierConstantHealthRegen()
  return self.bonus_health_regen or 0
end

function modifier_item_giant_form_passive:GetModifierBonusStats_Strength()
  return self.bonus_strength or 0
end

function modifier_item_giant_form_passive:GetModifierPreAttack_BonusDamage()
  return self.bonus_damage or 0
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
  local ability = self:GetAbility()

  if ability and not ability:IsNull() then
    self.atkDmg = ability:GetSpecialValueFor("giant_attack_damage")
    self.atkSpeed = ability:GetSpecialValueFor("giant_attack_speed_reduction")
    self.scale = ability:GetSpecialValueFor("giant_scale")
  end
end

modifier_item_giant_form_grow.OnRefresh = modifier_item_giant_form_grow.OnCreated

function modifier_item_giant_form_grow:CheckState()
  local state = {
    [MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
  }
  return state
end

function modifier_item_giant_form_grow:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
    --MODIFIER_PROPERTY_ATTACKSPEED_REDUCTION_PERCENTAGE,
    MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
    MODIFIER_PROPERTY_MODEL_SCALE,
    MODIFIER_EVENT_ON_ATTACK_LANDED,
  }

  return funcs
end

function modifier_item_giant_form_grow:GetModifierPreAttack_BonusDamage()
  return self.atkDmg or 300
end

function modifier_item_giant_form_grow:GetModifierModelScale()
  return self.scale or 50
end

--function modifier_item_giant_form_grow:GetModifierAttackSpeedReductionPercentage()
  --return 50
--end

function modifier_item_giant_form_grow:GetModifierAttackSpeedBonus_Constant()
  if not IsServer() then
    return 0
  end

  local parent = self:GetParent()
  if self.checkAttackSpeed then
    return 0
  else
    self.checkAttackSpeed = true
    local attack_speed = parent:GetAttackSpeed() * 100
    self.checkAttackSpeed = false
    return -attack_speed*0.01*self.atkSpeed
  end
end

function modifier_item_giant_form_grow:OnAttackLanded(event)
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

  if parent:IsIllusion() or parent:IsRangedAttacker() then
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

  -- remove the initial target from the list
  for k, unit in pairs(units) do
    if unit == target then
      table.remove(units, k)
      break
    end
  end

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
  if actual_damage > 0 and #units > 0 then
    local particle = ParticleManager:CreateParticle("particles/items/powertreads_splash.vpcf", PATTACH_POINT, target)
    ParticleManager:SetParticleControl(particle, 5, Vector(1, 0, splash_radius))
    ParticleManager:ReleaseParticleIndex(particle)
  end

  -- iterate through all targets
  for k, unit in pairs(units) do
    if unit and not unit:IsNull() then
      damage_table.victim = unit
      ApplyDamage(damage_table)
    end
  end

  -- sound
  --target:EmitSound("")
end

function modifier_item_giant_form_grow:GetTexture()
  return "custom/giant_form_2_active"
end
