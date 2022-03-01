LinkLuaModifier("modifier_intrinsic_multiplexer", "modifiers/modifier_intrinsic_multiplexer.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_sacred_skull_stacking_stats", "items/sacred_skull.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_sacred_skull_non_stacking_stats", "items/sacred_skull.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_sacred_skull_dummy_stuff", "items/sacred_skull.lua", LUA_MODIFIER_MOTION_NONE)

item_sacred_skull = class(ItemBaseClass)

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
    damage_table.damage_flags = bit.bor(DOTA_DAMAGE_FLAG_REFLECTION, DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION, DOTA_DAMAGE_FLAG_NON_LETHAL, DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL)
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
    DOTA_UNIT_TARGET_FLAG_NONE,
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
  local max_hp = caster:GetMaxHealth()
  local missing_hp = 100*(max_hp - caster:GetHealth())/max_hp
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
      ParticleManager:DestroyParticle(particle, false)
      ParticleManager:ReleaseParticleIndex(particle)
      -- Healing
      ally:Heal(heal_amount, self)
      SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, ally, heal_amount, nil)
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

modifier_item_sacred_skull_stacking_stats.OnRefresh = modifier_item_sacred_skull_stacking_stats.OnCreated

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
    MODIFIER_PROPERTY_SPELL_LIFESTEAL_AMPLIFY_PERCENTAGE, -- GetModifierSpellLifestealRegenAmplify_Percentage
    MODIFIER_EVENT_ON_DEATH,
  }
end

-- Doesn't stack with Kaya items
function modifier_item_sacred_skull_non_stacking_stats:GetModifierMPRegenAmplify_Percentage()
  local parent = self:GetParent()
  if parent:HasModifier("modifier_item_kaya") or parent:HasModifier("modifier_item_yasha_and_kaya") or parent:HasModifier("modifier_item_kaya_and_sange") or parent:HasModifier("modifier_item_ethereal_blade") then
    return 0
  end
  return self:GetAbility():GetSpecialValueFor("mana_regen_multiplier")
end

-- Doesn't stack with Kaya items
function modifier_item_sacred_skull_non_stacking_stats:GetModifierSpellAmplify_Percentage()
  local parent = self:GetParent()
  if parent:HasModifier("modifier_item_kaya") or parent:HasModifier("modifier_item_yasha_and_kaya") or parent:HasModifier("modifier_item_kaya_and_sange") or parent:HasModifier("modifier_item_ethereal_blade") then
    return 0
  end
  return self:GetAbility():GetSpecialValueFor("spell_amp")
end

-- Doesn't stack with Kaya items
function modifier_item_sacred_skull_non_stacking_stats:GetModifierSpellLifestealRegenAmplify_Percentage()
  local parent = self:GetParent()
  if parent:HasModifier("modifier_item_kaya") or parent:HasModifier("modifier_item_yasha_and_kaya") or parent:HasModifier("modifier_item_kaya_and_sange") or parent:HasModifier("modifier_item_ethereal_blade") then
    return 0
  end
  return self:GetAbility():GetSpecialValueFor("spell_lifesteal_amp")
end

if IsServer() then
  function modifier_item_sacred_skull_non_stacking_stats:OnDeath(event)
    local parent = self:GetParent()
    local dead = event.unit
    local ability = self:GetAbility()

    -- If dead unit is not the parent then dont continue
    if dead ~= parent then
      return
    end

    -- Check if dead unit is nil or its about to be deleted
    if not dead or dead:IsNull() then
      return
    end

    -- Check if parent is a real hero
    if not parent:IsRealHero() or parent:IsTempestDouble() or parent:IsClone() then
      return
    end

    local parent_team = parent:GetTeamNumber()
    local death_location = parent:GetAbsOrigin()

    local heal_amount = 300 + parent:GetMaxHealth()
    local heal_radius = 1200

    if ability and not ability:IsNull() then
      heal_amount = ability:GetSpecialValueFor("death_heal_base") + parent:GetMaxHealth()
      heal_radius = ability:GetSpecialValueFor("death_heal_radius")
    end

    local units = FindUnitsInRadius(
      parent_team,
      death_location,
      nil,
      heal_radius,
      DOTA_UNIT_TARGET_TEAM_FRIENDLY,
      bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC),
      DOTA_UNIT_TARGET_FLAG_NONE,
      FIND_ANY_ORDER,
      false
    )

    for _, ally in pairs(units) do
      if ally and not ally:IsNull() then
        -- Heal particle
        local particle = ParticleManager:CreateParticle("particles/items/sacred_skull/huskar_inner_vitality_glyph.vpcf", PATTACH_CENTER_FOLLOW, ally)
        ParticleManager:DestroyParticle(particle, false)
        ParticleManager:ReleaseParticleIndex(particle)
        -- Healing
        ally:Heal(heal_amount, ability)
        SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, ally, heal_amount, nil)
      end
    end

    -- Add vision at death location
    --local vision_radius = ability:GetSpecialValueFor("death_vision_radius")
    local vision_duration = ability:GetSpecialValueFor("death_vision_duration")
    local dummy = CreateUnitByName("npc_dota_custom_dummy_unit", death_location, false, parent, parent, parent:GetTeamNumber())
    dummy:AddNewModifier(parent, ability, "modifier_sacred_skull_dummy_stuff", {})
    dummy:AddNewModifier(parent, ability, "modifier_kill", {duration = vision_duration})
    --AddFOWViewer(parent:GetTeamNumber(), death_location, vision_radius, vision_duration, false)
  end
end

---------------------------------------------------------------------------------------------------

modifier_sacred_skull_dummy_stuff = class(ModifierBaseClass)

function modifier_sacred_skull_dummy_stuff:IsHidden()
  return true
end

function modifier_sacred_skull_dummy_stuff:IsDebuff()
  return false
end

function modifier_sacred_skull_dummy_stuff:IsPurgable()
  return false
end

function modifier_sacred_skull_dummy_stuff:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
    MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
    MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
    MODIFIER_PROPERTY_BONUS_DAY_VISION,
    MODIFIER_PROPERTY_BONUS_NIGHT_VISION,
  }
end

function modifier_sacred_skull_dummy_stuff:GetAbsoluteNoDamagePhysical()
  return 1
end

function modifier_sacred_skull_dummy_stuff:GetAbsoluteNoDamageMagical()
  return 1
end

function modifier_sacred_skull_dummy_stuff:GetAbsoluteNoDamagePure()
  return 1
end

function modifier_sacred_skull_dummy_stuff:GetBonusDayVision()
  return self:GetAbility():GetSpecialValueFor("death_vision_radius")
end

function modifier_sacred_skull_dummy_stuff:GetBonusNightVision()
  return self:GetAbility():GetSpecialValueFor("death_vision_radius")
end

function modifier_sacred_skull_dummy_stuff:CheckState()
  local state = {
    [MODIFIER_STATE_UNSELECTABLE] = true,
    [MODIFIER_STATE_NOT_ON_MINIMAP] = true,
    [MODIFIER_STATE_NOT_ON_MINIMAP_FOR_ENEMIES] = true,
    [MODIFIER_STATE_NO_HEALTH_BAR] = true,
    [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
    [MODIFIER_STATE_OUT_OF_GAME] = true,
    [MODIFIER_STATE_NO_TEAM_MOVE_TO] = true,
    [MODIFIER_STATE_NO_TEAM_SELECT] = true,
    [MODIFIER_STATE_COMMAND_RESTRICTED] = true,
    [MODIFIER_STATE_ATTACK_IMMUNE] = true,
    [MODIFIER_STATE_MAGIC_IMMUNE] = true,
    [MODIFIER_STATE_FLYING] = true,
  }
  return state
end
