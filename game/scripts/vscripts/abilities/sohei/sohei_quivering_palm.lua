sohei_quivering_palm = class(AbilityBaseClass)

LinkLuaModifier("modifier_sohei_quivering_palm_passive", "abilities/sohei/sohei_quivering_palm.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_sohei_quivering_palm_debuff", "abilities/sohei/sohei_quivering_palm.lua", LUA_MODIFIER_MOTION_NONE)

function sohei_quivering_palm:GetIntrinsicModifierName()
  return "modifier_sohei_quivering_palm_passive"
end

function sohei_quivering_palm:OnHeroCalculateStatBonus()
  local caster = self:GetCaster()

  if caster:HasScepter() or self:IsStolen() then
    self:SetHidden(false)
    if self:GetLevel() <= 0 then
      self:SetLevel(1)
    end
  else
    self:SetHidden(true)
  end
end

function sohei_quivering_palm:OnSpellStart()
  local caster = self:GetCaster()

  -- Find enemy heroes everywhere
  local heroes = FindUnitsInRadius(
    caster:GetTeamNumber(),
    caster:GetAbsOrigin(),
    nil,
    FIND_UNITS_EVERYWHERE,
    DOTA_UNIT_TARGET_TEAM_ENEMY,
    DOTA_UNIT_TARGET_HERO,
    DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
    FIND_ANY_ORDER,
    false
  )

  if #heroes < 1 then
    --print("No enemy heroes on the map")
    self:EndCooldown()
    self:StartCooldown(1)
    self:RefundManaCost()
    return
  end

  local heroes_with_modifier = {}
  for _, hero in pairs(heroes) do
    if hero and not hero:IsNull() and hero:HasModifier("modifier_sohei_quivering_palm_debuff") then
      table.insert(heroes_with_modifier, hero)
    end
  end

  if #heroes_with_modifier < 1 then
    --print("No heroes with the modifier")
    self:EndCooldown()
    self:StartCooldown(1)
    self:RefundManaCost()
    return
  end

  local passive = caster:FindModifierByName("modifier_sohei_quivering_palm_passive")
  local last_attacked = passive.last_attacked_unit

  if last_attacked and not last_attacked:IsNull() then
    -- Check if target marked by the passive died or dispelled the debuff, if yes find a new one
    if not last_attacked:IsAlive() or not last_attacked:FindModifierByNameAndCaster("modifier_sohei_quivering_palm_debuff", caster) then
      last_attacked = self:FindLastAttackedWithDebuff(heroes_with_modifier, "modifier_sohei_quivering_palm_debuff")
    end
  else
    -- Target marked by the passive doesn't exist, find a new one
    last_attacked = self:FindLastAttackedWithDebuff(heroes_with_modifier, "modifier_sohei_quivering_palm_debuff")
  end

  self:QuiveringPalmEffect(last_attacked)
end

function sohei_quivering_palm:FindLastAttackedWithDebuff(candidates, debuff_name)
  local last_attacked = nil
  local current_time = GameRules:GetGameTime()
  local caster = self:GetCaster()
  local difference = self:GetSpecialValueFor("max_duration") or 10
  for _, hero in pairs(candidates) do
    if hero and not hero:IsNull() then
      local debuff = hero:FindModifierByNameAndCaster(debuff_name, caster)
      if debuff then
        local debuff_creation_time = debuff:GetCreationTime()
        if current_time - debuff_creation_time < difference then
          difference = current_time - debuff_creation_time
          last_attacked = hero
        end
      end
    end
  end

  return last_attacked
end

function sohei_quivering_palm:QuiveringPalmEffect(victim)
  if not victim then
    --print("No valid target")
    self:EndCooldown()
    self:StartCooldown(1)
    self:RefundManaCost()
    return
  end

  if not victim:IsHero() then
    --print("No valid target")
    self:EndCooldown()
    self:StartCooldown(1)
    self:RefundManaCost()
    return
  end

  local caster = self:GetCaster()

  -- Sound
  victim:EmitSound("Sohei.QuiveringPalm")

  -- Kill illusions
  if victim:IsIllusion() then
    victim:Kill(self, caster)
    return
  end

  -- Check if caster has Momentum Strike learned, if not apply regular knockback
  local momentum_strike = caster:FindAbilityByName("sohei_momentum_strike")
  if momentum_strike and momentum_strike:GetLevel() > 0 then
    -- Knockback parameters
    local distance = momentum_strike:GetSpecialValueFor("knockback_distance")/2
    local speed = momentum_strike:GetSpecialValueFor("knockback_speed")/2
    local duration = distance / speed
    local collision_radius = momentum_strike:GetSpecialValueFor("collision_radius")

    local direction = -victim:GetForwardVector() -- victim:GetAbsOrigin() - position_in_front_of_them
    direction.z = 0
    direction = direction:Normalized()

    -- Apply Momentum Strike Knockback to the enemy
    victim:RemoveModifierByName("modifier_sohei_momentum_strike_knockback")
    victim:AddNewModifier(caster, momentum_strike, "modifier_sohei_momentum_strike_knockback", {
      duration = duration,
      distance = distance,
      speed = speed,
      collision_radius = collision_radius,
      direction_x = direction.x,
      direction_y = direction.y,
    })
  end

  -- Calculate damage
  local caster_str = caster:GetStrength()
  local victim_str = victim:GetStrength()
  local diff_multiplier = self:GetSpecialValueFor("str_diff_multiplier")
  local base_damage = self:GetSpecialValueFor("base_damage")
  local attack_damage = caster:GetAverageTrueAttackDamage(nil)
  local bonus_damage = math.max((caster_str - victim_str) * diff_multiplier, 0)

  local damage_table = {
    attacker = caster,
    victim = victim,
    damage = base_damage + attack_damage + bonus_damage,
    damage_type = self:GetAbilityDamageType(),
    damage_flags = DOTA_DAMAGE_FLAG_BYPASSES_BLOCK,
    ability = self,
  }
  ApplyDamage(damage_table)
end

function sohei_quivering_palm:OnUnStolen()
  local caster = self:GetCaster()
  local modifier = caster:FindModifierByName("modifier_sohei_quivering_palm_passive")
  if modifier then
    caster:RemoveModifierByName("modifier_sohei_quivering_palm_passive")
  end
end

---------------------------------------------------------------------------------------------------

modifier_sohei_quivering_palm_passive = class(ModifierBaseClass)

function modifier_sohei_quivering_palm_passive:IsHidden()
  return true
end

function modifier_sohei_quivering_palm_passive:IsDebuff()
  return false
end

function modifier_sohei_quivering_palm_passive:IsPurgable()
  return false
end

function modifier_sohei_quivering_palm_passive:RemoveOnDeath()
  return false
end

function modifier_sohei_quivering_palm_passive:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_ATTACK_LANDED,
  }
end

if IsServer() then
  function modifier_sohei_quivering_palm_passive:OnAttackLanded(event)
    local parent = self:GetParent()
    local ability = self:GetAbility()
    local attacker = event.attacker
    local target = event.target

    -- Check if attacker exists
    if not attacker or attacker:IsNull() then
      return
    end

    if attacker ~= parent then
      return
    end

    -- Check if attacker is an illusion
    if attacker:IsIllusion() then
      return
    end

    -- Check if attacked entity exists
    if not target or target:IsNull() then
      return
    end

    -- Check if its an item, rune, or something weird
    if target.GetUnitName == nil then
      return
    end

    -- Check if its a hero or illusion of a hero
    if not target:IsHero() then
      return
    end

    -- Applying the debuff
    target:AddNewModifier(attacker, ability, "modifier_sohei_quivering_palm_debuff", {duration = ability:GetSpecialValueFor("max_duration")})

    -- Last attacked hero (can be illusion too)
    self.last_attacked_unit = target
  end
end

---------------------------------------------------------------------------------------------------

modifier_sohei_quivering_palm_debuff = class(ModifierBaseClass)

function modifier_sohei_quivering_palm_debuff:IsHidden()
  return false
end

function modifier_sohei_quivering_palm_debuff:IsDebuff()
  return true
end

function modifier_sohei_quivering_palm_debuff:IsPurgable()
  return true
end

function modifier_sohei_quivering_palm_debuff:RemoveOnDeath()
  return true
end
