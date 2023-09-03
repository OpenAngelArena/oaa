LinkLuaModifier("modifier_item_sacred_skull_passives", "items/sacred_skull.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_sacred_skull_dummy_stuff", "items/sacred_skull.lua", LUA_MODIFIER_MOTION_NONE)

item_sacred_skull = class(ItemBaseClass)

function item_sacred_skull:GetIntrinsicModifierName()
  return "modifier_item_sacred_skull_passives"
end

function item_sacred_skull:OnSpellStart()
  local caster = self:GetCaster()
  local damage_table = {}
  damage_table.attacker = caster
  damage_table.ability = self

  -- if not caster:IsInvulnerable() then
    -- local current_hp = caster:GetHealth()
    -- local current_hp_as_dmg = self:GetSpecialValueFor("health_cost")
    -- damage_table.damage = current_hp * current_hp_as_dmg * 0.01
    -- damage_table.damage_flags = bit.bor(DOTA_DAMAGE_FLAG_REFLECTION, DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION, DOTA_DAMAGE_FLAG_NON_LETHAL, DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL)
    -- damage_table.damage_type = DAMAGE_TYPE_PURE
    -- damage_table.victim = caster
    -- ApplyDamage(damage_table)
    -- -- Hit Particle
    -- local particle = ParticleManager:CreateParticle("particles/items/sacred_skull/vermillion_robe_hit.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
    -- ParticleManager:DestroyParticle(particle, false)
    -- ParticleManager:ReleaseParticleIndex(particle)
  -- end

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
  -- local allies = FindUnitsInRadius(
    -- caster_team,
    -- caster_location,
    -- nil,
    -- radius,
    -- DOTA_UNIT_TARGET_TEAM_FRIENDLY,
    -- target_units,
    -- DOTA_UNIT_TARGET_FLAG_NONE,
    -- FIND_ANY_ORDER,
    -- false
  -- )

  -- Calculate damage and heal
  -- local dmg_per_missing_hp = self:GetSpecialValueFor("damage_per_missing_hp")
  -- local heal_per_missing_hp = self:GetSpecialValueFor("heal_per_missing_hp")
  -- local max_hp = caster:GetMaxHealth()
  -- local missing_hp = 100*(max_hp - caster:GetHealth())/max_hp
  -- damage_table.damage = missing_hp * dmg_per_missing_hp
  local current_mana = caster:GetMana()
  local missing_mana = caster:GetMaxMana() - current_mana
  local magic_damage = self:GetSpecialValueFor("base_dmg") + self:GetSpecialValueFor("magic_dmg_per_current_mana") * current_mana
  local physical_damage = self:GetSpecialValueFor("phys_dmg_per_missing_mana") * missing_mana

  damage_table.damage = magic_damage
  damage_table.damage_type = DAMAGE_TYPE_MAGICAL
  damage_table.damage_flags = DOTA_DAMAGE_FLAG_NONE
  -- local heal_amount = missing_hp * heal_per_missing_hp

  local damage_table_2 = {}
  damage_table_2.attacker = caster
  damage_table_2.ability = self
  damage_table_2.damage = physical_damage
  damage_table_2.damage_type = DAMAGE_TYPE_PHYSICAL
  damage_table_2.damage_flags = DOTA_DAMAGE_FLAG_BYPASSES_BLOCK

  -- Damage enemies
  for _, enemy in pairs(enemies) do
    if enemy and not enemy:IsNull() then
      -- Hit particle
      local particle = ParticleManager:CreateParticle("particles/items/sacred_skull/vermillion_robe_hit.vpcf", PATTACH_ABSORIGIN_FOLLOW, enemy)
      ParticleManager:DestroyParticle(particle, false)
      ParticleManager:ReleaseParticleIndex(particle)
      -- Magic Damage
      damage_table.victim = enemy
      ApplyDamage(damage_table)
      -- Physical Damage
      damage_table_2.victim = enemy
      if not enemy:IsNull() then
        ApplyDamage(damage_table_2)
      end
    end
  end

  -- Heal allies (but not caster)
  -- for _, ally in pairs(allies) do
    -- if ally and not ally:IsNull() and ally ~= caster then
      -- -- Heal particle
      -- local particle = ParticleManager:CreateParticle("particles/items/sacred_skull/huskar_inner_vitality_glyph.vpcf", PATTACH_CENTER_FOLLOW, ally)
      -- ParticleManager:DestroyParticle(particle, false)
      -- ParticleManager:ReleaseParticleIndex(particle)
      -- -- Healing
      -- ally:Heal(heal_amount, self)
      -- SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, ally, heal_amount, nil)
    -- end
  -- end
end

item_sacred_skull_2 = item_sacred_skull
item_sacred_skull_3 = item_sacred_skull
item_sacred_skull_4 = item_sacred_skull

---------------------------------------------------------------------------------------------------

modifier_item_sacred_skull_passives = class(ModifierBaseClass)

function modifier_item_sacred_skull_passives:IsHidden()
  return true
end

function modifier_item_sacred_skull_passives:IsDebuff()
  return false
end

function modifier_item_sacred_skull_passives:IsPurgable()
  return false
end

function modifier_item_sacred_skull_passives:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_sacred_skull_passives:OnCreated()
  self:OnRefresh()
  if IsServer() then
    self:StartIntervalThink(0.1)
  end
end

function modifier_item_sacred_skull_passives:OnRefresh()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.bonus_health = ability:GetSpecialValueFor("bonus_health")
    self.bonus_hp_regen = ability:GetSpecialValueFor("bonus_health_regen")
    self.bonus_mana = ability:GetSpecialValueFor("bonus_mana")
    self.bonus_mana_regen = ability:GetSpecialValueFor("bonus_mana_regen")
    self.bonus_str = ability:GetSpecialValueFor("bonus_strength")
    self.bonus_agi = ability:GetSpecialValueFor("bonus_agility")
    self.bonus_int = ability:GetSpecialValueFor("bonus_intellect")
    self.bonus_magic_resist = ability:GetSpecialValueFor("bonus_magic_resistance")
    self.spell_amp = ability:GetSpecialValueFor("spell_amp")
    self.spell_lifesteal_amp = ability:GetSpecialValueFor("spell_lifesteal_amp")
    self.mana_regen_amp = ability:GetSpecialValueFor("mana_regen_multiplier")
    self.hp_regen_amp = ability:GetSpecialValueFor("hp_regen_amp")
  end

  if IsServer() then
    self:OnIntervalThink()
  end
end

function modifier_item_sacred_skull_passives:OnIntervalThink()
  if self:IsFirstItemInInventory() then
    self:SetStackCount(2)
  else
    self:SetStackCount(1)
  end
end

function modifier_item_sacred_skull_passives:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_HEALTH_BONUS, -- GetModifierHealthBonus
    MODIFIER_PROPERTY_MANA_BONUS, -- GetModifierManaBonus
    MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT, -- GetModifierConstantHealthRegen
    MODIFIER_PROPERTY_MANA_REGEN_CONSTANT, -- GetModifierConstantManaRegen
    MODIFIER_PROPERTY_STATS_STRENGTH_BONUS, -- GetModifierBonusStats_Strength
    MODIFIER_PROPERTY_STATS_AGILITY_BONUS, -- GetModifierBonusStats_Agility
    MODIFIER_PROPERTY_STATS_INTELLECT_BONUS, -- GetModifierBonusStats_Intellect
    MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS, -- GetModifierMagicalResistanceBonus
    MODIFIER_PROPERTY_MP_REGEN_AMPLIFY_PERCENTAGE, -- GetModifierMPRegenAmplify_Percentage
    MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,    -- GetModifierSpellAmplify_Percentage
    MODIFIER_PROPERTY_SPELL_LIFESTEAL_AMPLIFY_PERCENTAGE, -- GetModifierSpellLifestealRegenAmplify_Percentage
    MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE, -- GetModifierHPRegenAmplify_Percentage
    MODIFIER_EVENT_ON_DEATH,
  }
end

function modifier_item_sacred_skull_passives:GetModifierHealthBonus()
  return self.bonus_health or self:GetAbility():GetSpecialValueFor("bonus_health")
end

function modifier_item_sacred_skull_passives:GetModifierManaBonus()
  return self.bonus_mana or self:GetAbility():GetSpecialValueFor("bonus_mana")
end

function modifier_item_sacred_skull_passives:GetModifierConstantHealthRegen()
  return self.bonus_hp_regen or self:GetAbility():GetSpecialValueFor("bonus_health_regen")
end

function modifier_item_sacred_skull_passives:GetModifierConstantManaRegen()
  return self.bonus_mana_regen or self:GetAbility():GetSpecialValueFor("bonus_mana_regen")
end

function modifier_item_sacred_skull_passives:GetModifierBonusStats_Strength()
  return self.bonus_str or self:GetAbility():GetSpecialValueFor("bonus_strength")
end

function modifier_item_sacred_skull_passives:GetModifierBonusStats_Agility()
  return self.bonus_agi or self:GetAbility():GetSpecialValueFor("bonus_agility")
end

function modifier_item_sacred_skull_passives:GetModifierBonusStats_Intellect()
  return self.bonus_int or self:GetAbility():GetSpecialValueFor("bonus_intellect")
end

function modifier_item_sacred_skull_passives:GetModifierMagicalResistanceBonus()
  return self.bonus_magic_resist or self:GetAbility():GetSpecialValueFor("bonus_magic_resistance")
end

-- Doesn't stack with Kaya items
function modifier_item_sacred_skull_passives:GetModifierMPRegenAmplify_Percentage()
  local parent = self:GetParent()
  if self:GetStackCount() ~= 2 or parent:HasModifier("modifier_item_kaya") or parent:HasModifier("modifier_item_yasha_and_kaya") or parent:HasModifier("modifier_item_kaya_and_sange") or parent:HasModifier("modifier_item_ethereal_blade") then
    return 0
  end
  return self.mana_regen_amp or self:GetAbility():GetSpecialValueFor("mana_regen_multiplier")
end

-- Doesn't stack with Kaya items
function modifier_item_sacred_skull_passives:GetModifierSpellAmplify_Percentage()
  local parent = self:GetParent()
  if self:GetStackCount() ~= 2 or parent:HasModifier("modifier_item_kaya") or parent:HasModifier("modifier_item_yasha_and_kaya") or parent:HasModifier("modifier_item_kaya_and_sange") or parent:HasModifier("modifier_item_ethereal_blade") then
    return 0
  end
  return self.spell_amp or self:GetAbility():GetSpecialValueFor("spell_amp")
end

-- Doesn't stack with Kaya items
function modifier_item_sacred_skull_passives:GetModifierSpellLifestealRegenAmplify_Percentage()
  local parent = self:GetParent()
  if self:GetStackCount() ~= 2 or parent:HasModifier("modifier_item_kaya") or parent:HasModifier("modifier_item_yasha_and_kaya") or parent:HasModifier("modifier_item_kaya_and_sange") or parent:HasModifier("modifier_item_ethereal_blade") then
    return 0
  end
  return self.spell_lifesteal_amp or self:GetAbility():GetSpecialValueFor("spell_lifesteal_amp")
end

function modifier_item_sacred_skull_passives:GetModifierHPRegenAmplify_Percentage()
  if self:GetStackCount() == 2 then
    return self.hp_regen_amp or self:GetAbility():GetSpecialValueFor("hp_regen_amp")
  else
    return 0
  end
end

if IsServer() then
  function modifier_item_sacred_skull_passives:OnDeath(event)
    -- Only the first item will proc
    if not self:IsFirstItemInInventory() then
      return
    end

    local parent = self:GetParent()
    local dead = event.unit
    local ability = self:GetAbility()

    -- Check if dead unit is nil or its about to be deleted
    if not dead or dead:IsNull() then
      return
    end

    -- If dead unit is not the parent then dont continue
    if dead ~= parent then
      return
    end

    -- Check if parent is a real hero (it's fine if it works on Spirit Bear)
    if not parent:IsRealHero() or parent:IsTempestDouble() or parent:IsClone() then
      return
    end

    local parent_team = parent:GetTeamNumber()
    local death_location = parent:GetAbsOrigin()

    local heal_amount = 100 + parent:GetMaxHealth() / 2
    local heal_radius = 1200
    local base_dmg = 75
    local magic_dmg_mult = 0.125 -- 15
    local phys_dmg_mult = 0.25
    local vision_duration = 30
    --local vision_radius = 1200

    if ability and not ability:IsNull() then
      heal_amount = ability:GetSpecialValueFor("death_heal_base") + parent:GetMaxHealth() / 2
      heal_radius = ability:GetSpecialValueFor("death_heal_radius")
      base_dmg = ability:GetSpecialValueFor("base_dmg")
      magic_dmg_mult = ability:GetSpecialValueFor("magic_dmg_per_current_mana") -- ability:GetSpecialValueFor("damage_per_missing_hp")
      phys_dmg_mult = ability:GetSpecialValueFor("phys_dmg_per_missing_mana")
      vision_duration = ability:GetSpecialValueFor("death_vision_duration")
      --vision_radius = ability:GetSpecialValueFor("death_vision_radius")
    end

    local allies = FindUnitsInRadius(
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

    for _, ally in pairs(allies) do
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
    local dummy = CreateUnitByName("npc_dota_custom_dummy_unit", death_location, false, parent, parent, parent_team)
    dummy:AddNewModifier(parent, ability, "modifier_sacred_skull_dummy_stuff", {})
    dummy:AddNewModifier(parent, ability, "modifier_kill", {duration = vision_duration})
    dummy:AddNewModifier(parent, ability, "modifier_generic_dead_tracker_oaa", {duration = vision_duration + MANUAL_GARBAGE_CLEANING_TIME})
    --AddFOWViewer(parent:GetTeamNumber(), death_location, vision_radius, vision_duration, false)

    if ability and ability:IsCooldownReady() then
      local enemies = FindUnitsInRadius(
        parent_team,
        death_location,
        nil,
        heal_radius,
        DOTA_UNIT_TARGET_TEAM_ENEMY,
        bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC),
        DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_ANY_ORDER,
        false
      )
      -- Calculate damage and heal
      local current_mana = parent:GetMana()
      local missing_mana = parent:GetMaxMana() - current_mana
      local magic_damage = base_dmg + magic_dmg_mult * current_mana
      local physical_damage = phys_dmg_mult * missing_mana

      local damage_table = {}
      damage_table.attacker = parent
      damage_table.ability = ability
      damage_table.damage = magic_damage
      damage_table.damage_type = DAMAGE_TYPE_MAGICAL
      damage_table.damage_flags = DOTA_DAMAGE_FLAG_NONE

      local damage_table_2 = {}
      damage_table_2.attacker = parent
      damage_table_2.ability = ability
      damage_table_2.damage = physical_damage
      damage_table_2.damage_type = DAMAGE_TYPE_PHYSICAL
      damage_table_2.damage_flags = DOTA_DAMAGE_FLAG_BYPASSES_BLOCK

      -- Damage enemies
      for _, enemy in pairs(enemies) do
        if enemy and not enemy:IsNull() then
          -- Hit particle
          local particle = ParticleManager:CreateParticle("particles/items/sacred_skull/vermillion_robe_hit.vpcf", PATTACH_ABSORIGIN_FOLLOW, enemy)
          ParticleManager:DestroyParticle(particle, false)
          ParticleManager:ReleaseParticleIndex(particle)
          -- Magic Damage
          damage_table.victim = enemy
          ApplyDamage(damage_table)
          -- Physical Damage
          if not enemy:IsNull() then
            damage_table_2.victim = enemy
            ApplyDamage(damage_table_2)
          end
        end
      end
    end
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
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    return ability:GetSpecialValueFor("death_vision_radius")
  end
  return 800
end

function modifier_sacred_skull_dummy_stuff:GetBonusNightVision()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    return ability:GetSpecialValueFor("death_vision_radius")
  end
  return 800
end

function modifier_sacred_skull_dummy_stuff:CheckState()
  return {
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
end
