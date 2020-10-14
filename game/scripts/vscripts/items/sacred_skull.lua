LinkLuaModifier("modifier_intrinsic_multiplexer", "modifiers/modifier_intrinsic_multiplexer.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_sacred_skull_stacking_stats", "items/sacred_skull.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_sacred_skull_non_stacking_stats", "items/sacred_skull.lua", LUA_MODIFIER_MOTION_NONE)

item_sacred_skull = class(ItemBaseClass)

function item_sacred_skull:Precache(context)
  PrecacheResource("particle", "particles/items/sacred_skull/vermillion_robe_hit.vpcf", context)
  PrecacheResource("particle", "particles/items/sacred_skull/vermillion_robe_explosion.vpcf", context)
  PrecacheResource("particle", "particles/items/sacred_skull/huskar_inner_vitality_glyph.vpcf", context)
  PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_jakiro.vsndevts", context)
end

function item_sacred_skull:GetIntrinsicModifierName()
  return "modifier_intrinsic_multiplexer"
end

function item_sacred_skull:GetIntrinsicModifierNames()
  return {
    "modifier_item_sacred_skull_stacking_stats",
    "modifier_item_sacred_skull_non_stacking_stats"
  }
end

function item_sacred_skull:OnSpellStart()
  local caster = self:GetCaster()
  local damage_table = {}
  damage_table.attacker = caster
  damage_table.ability = self

  if not caster:IsInvulnerable() then
    local current_hp = caster:GetHealth()
    local current_hp_as_dmg = self:GetSpecialValueFor("health_cost")
    damage_table.damage = current_hp * current_hp_as_dmg * 0.01
    damage_table.damage_flags = bit.bor(DOTA_DAMAGE_FLAG_REFLECTION, DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION, DOTA_DAMAGE_FLAG_NON_LETHAL, DOTA_DAMAGE_FLAG_NO_DAMAGE_MULTIPLIERS, DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL)
    damage_table.damage_type = DAMAGE_TYPE_PURE
    damage_table.victim = caster
    ApplyDamage(damage_table)
    -- Hit Particle
    local particle = ParticleManager:CreateParticle("particles/items/sacred_skull/vermillion_robe_hit.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
    ParticleManager:DestroyParticle(particle, false)
    ParticleManager:ReleaseParticleIndex(particle)
  end

  -- Explosion particle
  local particle_boom = ParticleManager:CreateParticle("particles/items/sacred_skull/vermillion_robe_explosion.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
  ParticleManager:DestroyParticle(particle_boom, false)
  ParticleManager:ReleaseParticleIndex(particle_boom)
  
  -- Sound
  caster:EmitSound("Hero_Jakiro.LiquidFire")

  local caster_team = caster:GetTeamNumber()
  local caster_location = caster:GetAbsOrigin()
  local radius = self:GetSpecialValueFor("effect_radius")
  local target_units = bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC)

	local enemies = FindUnitsInRadius(
    caster_team,
    caster_location,
    nil,
    radius,
    DOTA_UNIT_TARGET_TEAM_ENEMY,
    target_units,
    DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
    FIND_ANY_ORDER,
    false
  )
  local allies = FindUnitsInRadius(
    caster_team,
    caster_location,
    nil,
    radius,
    DOTA_UNIT_TARGET_TEAM_FRIENDLY,
    target_units,
    DOTA_UNIT_TARGET_FLAG_NONE,
    FIND_ANY_ORDER,
    false
  )

  -- Calculate damage and heal
  local dmg_per_missing_hp = self:GetSpecialValueFor("damage_per_missing_hp")
  local heal_per_missing_hp = self:GetSpecialValueFor("heal_per_missing_hp")
  local missing_hp = caster:GetMaxHealth() - caster:GetHealth()
  damage_table.damage = missing_hp * dmg_per_missing_hp
  local heal_amount = missing_hp * heal_per_missing_hp

  -- Damage enemies
  for _, enemy in pairs(enemies) do
    if enemy and not enemy:IsNull() then
      -- Hit particle
      local particle = ParticleManager:CreateParticle("particles/items/sacred_skull/vermillion_robe_hit.vpcf", PATTACH_ABSORIGIN_FOLLOW, enemy)
      ParticleManager:DestroyParticle(particle, false)
      ParticleManager:ReleaseParticleIndex(particle)
      -- Damage
      damage_table.damage_type = DAMAGE_TYPE_MAGICAL
      damage_table.damage_flags = DOTA_DAMAGE_FLAG_NONE
      damage_table.victim = enemy
      ApplyDamage(damage_table)
    end
  end

  -- Heal allies (but not caster)
  for _, ally in pairs(allies) do
    if ally and not ally:IsNull() and ally ~= caster then
      -- Heal particle
      local particle = ParticleManager:CreateParticle("particles/items/sacred_skull/huskar_inner_vitality_glyph.vpcf", PATTACH_CENTER_FOLLOW, ally)
      --ParticleManager:DestroyParticle(particle, false)
      --ParticleManager:ReleaseParticleIndex(particle)
      -- Healing
      ally:Heal(heal_amount, self)
    end
  end
end

-- upgrades
item_sacred_skull_2 = item_sacred_skull
item_sacred_skull_3 = item_sacred_skull
item_sacred_skull_4 = item_sacred_skull

---------------------------------------------------------------------------------------------------
-- Parts of Sacred Skull that should stack with other Sacred Skulls

modifier_item_sacred_skull_stacking_stats = class(ModifierBaseClass)

function modifier_item_sacred_skull_stacking_stats:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.bonus_health = ability:GetSpecialValueFor("bonus_health")
    self.bonus_mana_regen = ability:GetSpecialValueFor("bonus_mana_regen")
    self.bonus_mana = ability:GetSpecialValueFor("bonus_mana")
    self.bonus_hp_regen = ability:GetSpecialValueFor("bonus_health_regen")
    self.bonus_int = ability:GetSpecialValueFor("bonus_intellect")
    self.bonus_magic_resist = ability:GetSpecialValueFor("bonus_magic_resistance")
  end
end

function modifier_item_sacred_skull_stacking_stats:OnRefreshed()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.bonus_health = ability:GetSpecialValueFor("bonus_health")
    self.bonus_mana_regen = ability:GetSpecialValueFor("bonus_mana_regen")
    self.bonus_mana = ability:GetSpecialValueFor("bonus_mana")
    self.bonus_hp_regen = ability:GetSpecialValueFor("bonus_health_regen")
    self.bonus_int = ability:GetSpecialValueFor("bonus_intellect")
    self.bonus_magic_resist = ability:GetSpecialValueFor("bonus_magic_resistance")
  end
end

function modifier_item_sacred_skull_stacking_stats:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_sacred_skull_stacking_stats:IsHidden()
  return true
end

function modifier_item_sacred_skull_stacking_stats:IsDebuff()
  return false
end

function modifier_item_sacred_skull_stacking_stats:IsPurgable()
  return false
end

function modifier_item_sacred_skull_stacking_stats:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_DEATH,
    MODIFIER_PROPERTY_HEALTH_BONUS, -- GetModifierHealthBonus
    MODIFIER_PROPERTY_MANA_BONUS, -- GetModifierManaBonus
    MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT, -- GetModifierConstantHealthRegen
    MODIFIER_PROPERTY_MANA_REGEN_CONSTANT, -- GetModifierConstantManaRegen
    MODIFIER_PROPERTY_STATS_INTELLECT_BONUS, -- GetModifierBonusStats_Intellect
    MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS, -- GetModifierMagicalResistanceBonus
  }
end

function modifier_item_sacred_skull_stacking_stats:GetModifierHealthBonus()
  return self.bonus_health or self:GetAbility():GetSpecialValueFor("bonus_health")
end

function modifier_item_sacred_skull_stacking_stats:GetModifierManaBonus()
  return self.bonus_mana or self:GetAbility():GetSpecialValueFor("bonus_mana")
end

function modifier_item_sacred_skull_stacking_stats:GetModifierConstantHealthRegen()
  return self.bonus_hp_regen or self:GetAbility():GetSpecialValueFor("bonus_health_regen")
end

function modifier_item_sacred_skull_stacking_stats:GetModifierConstantManaRegen()
  return self.bonus_mana_regen or self:GetAbility():GetSpecialValueFor("bonus_mana_regen")
end

function modifier_item_sacred_skull_stacking_stats:GetModifierBonusStats_Intellect()
  return self.bonus_int or self:GetAbility():GetSpecialValueFor("bonus_intellect")
end

function modifier_item_sacred_skull_stacking_stats:GetModifierMagicalResistanceBonus()
  return self.bonus_magic_resist or self:GetAbility():GetSpecialValueFor("bonus_magic_resistance")
end

function modifier_item_sacred_skull_stacking_stats:OnDeath(event)
  local caster = self:GetCaster()
  local dead = event.unit
  local ability = self:GetAbility()

  -- If dead unit is not the caster then dont continue
  if dead ~= caster then
    return
  end

  -- Check if dead unit is nil or its about to be deleted
  if not dead or dead:IsNull() then
    return
  end

  -- Check if caster is a real hero
  if not caster:IsRealHero() or caster:IsTempestDouble() then
    return
  end

  local caster_team = caster:GetTeamNumber()
  local death_location = caster:GetAbsOrigin()

  local heal_amount = ability:GetSpecialValueFor("death_heal_base") + caster:GetMaxHealth() * 0.5
  local units = FindUnitsInRadius(
    caster_team,
    death_location,
    nil,
    ability:GetSpecialValueFor("death_heal_radius"),
    DOTA_UNIT_TARGET_TEAM_FRIENDLY,
    bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC),
    DOTA_UNIT_TARGET_FLAG_NONE,
    FIND_ANY_ORDER,
    false
  )

  units = iter(units)
  units:each(function (unit)
    unit:Heal(heal_amount, ability)
  end)

  -- Add vision at death location
  local vision_radius = ability:GetSpecialValueFor("death_vision_radius")
  local vision_duration = ability:GetSpecialValueFor("death_vision_duration")
  AddFOWViewer(caster_team, death_location, vision_radius, vision_duration, false)
end

-------------------------------------------------------------------------
-- Parts of Sacred Skull that should NOT stack with other Sacred Skulls

modifier_item_sacred_skull_non_stacking_stats = class(ModifierBaseClass)

function modifier_item_sacred_skull_non_stacking_stats:IsHidden()
  return true
end

function modifier_item_sacred_skull_non_stacking_stats:IsDebuff()
  return false
end

function modifier_item_sacred_skull_non_stacking_stats:IsPurgable()
  return false
end

function modifier_item_sacred_skull_non_stacking_stats:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MP_REGEN_AMPLIFY_PERCENTAGE, -- GetModifierMPRegenAmplify_Percentage
    MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,    -- GetModifierSpellAmplify_Percentage
  }
end

-- Doesn't stack with Kaya items and Bloodstone
function modifier_item_sacred_skull_non_stacking_stats:GetModifierMPRegenAmplify_Percentage()
  local parent = self:GetParent()
  if not parent:HasModifier("modifier_item_kaya") and not parent:HasModifier("modifier_item_yasha_and_kaya") and not parent:HasModifier("modifier_item_kaya_and_sange") and not parent:HasModifier("modifier_item_bloodstone_non_stacking_stats") then
    return self:GetAbility():GetSpecialValueFor("mana_regen_multiplier")
  end
  return 0
end

-- Doesn't stack with Kaya items and Bloodstone
function modifier_item_sacred_skull_non_stacking_stats:GetModifierSpellAmplify_Percentage()
  local parent = self:GetParent()
  if not parent:HasModifier("modifier_item_kaya") and not parent:HasModifier("modifier_item_yasha_and_kaya") and not parent:HasModifier("modifier_item_kaya_and_sange") and not parent:HasModifier("modifier_item_bloodstone_non_stacking_stats") then
    return self:GetAbility():GetSpecialValueFor("spell_amp")
  end
  return 0
end
