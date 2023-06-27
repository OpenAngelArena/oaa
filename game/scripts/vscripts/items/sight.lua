LinkLuaModifier("modifier_intrinsic_multiplexer", "modifiers/modifier_intrinsic_multiplexer.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_far_sight_stacking_stats", "items/sight.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_far_sight_non_stacking_stats", "items/sight.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_far_sight_dummy_stuff", "items/sight.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_far_sight_true_sight", "items/sight.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_generic_dead_tracker_oaa", "modifiers/modifier_generic_dead_tracker_oaa.lua", LUA_MODIFIER_MOTION_NONE)

item_far_sight = class(ItemBaseClass)

function item_far_sight:GetAOERadius()
  return self:GetSpecialValueFor("reveal_radius")
end

function item_far_sight:GetIntrinsicModifierName()
  return "modifier_intrinsic_multiplexer"
end

function item_far_sight:GetIntrinsicModifierNames()
  return {
    "modifier_item_far_sight_stacking_stats",
    "modifier_item_far_sight_non_stacking_stats"
  }
end

function item_far_sight:OnSpellStart()
  local caster = self:GetCaster()
  local target = self:GetCursorPosition()
  local casterTeam = caster:GetTeamNumber()
  local revealDuration = self:GetSpecialValueFor("reveal_duration")

  --AddFOWViewer(casterTeam, target, self:GetSpecialValueFor("reveal_radius"), revealDuration, false)
  --local trueSightThinker = CreateModifierThinker(caster, self, "modifier_item_far_sight_true_sight", {duration = revealDuration}, target, casterTeam, false)

  local dummy = CreateUnitByName("npc_dota_custom_dummy_unit", target, false, caster, caster, casterTeam)
  dummy:AddNewModifier(caster, self, "modifier_far_sight_dummy_stuff", {})
  dummy:AddNewModifier(caster, self, "modifier_item_far_sight_true_sight", {})
  dummy:AddNewModifier(caster, self, "modifier_kill", {duration = revealDuration})
  dummy:AddNewModifier(caster, self, "modifier_generic_dead_tracker_oaa", {duration = revealDuration + MANUAL_GARBAGE_CLEANING_TIME})

  dummy:MakeVisibleToTeam(casterTeam, revealDuration)
  --dummy:MakeVisibleToTeam(DOTA_TEAM_BADGUYS, revealDuration)
end

item_far_sight_2 = item_far_sight
item_far_sight_3 = item_far_sight
item_far_sight_4 = item_far_sight
item_far_sight_5 = item_far_sight

---------------------------------------------------------------------------------------------------

modifier_item_far_sight_stacking_stats = class(ModifierBaseClass)

function modifier_item_far_sight_stacking_stats:IsHidden()
  return true
end

function modifier_item_far_sight_stacking_stats:IsDebuff()
  return false
end

function modifier_item_far_sight_stacking_stats:IsPurgable()
  return false
end

function modifier_item_far_sight_stacking_stats:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_far_sight_stacking_stats:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.health = ability:GetSpecialValueFor("bonus_health")
    self.health_regen = ability:GetSpecialValueFor("bonus_health_regen")
    self.mana = ability:GetSpecialValueFor("bonus_mana")
    self.mana_regen = ability:GetSpecialValueFor("bonus_mana_regen")
    self.armor = ability:GetSpecialValueFor("bonus_armor")
    self.worst_attr = ability:GetSpecialValueFor("bonus_to_worst_attribute")
    --self.strength = ability:GetSpecialValueFor("bonus_strength")
    --self.agility = ability:GetSpecialValueFor("bonus_agility")
    --self.intellect = ability:GetSpecialValueFor("bonus_intellect")
  end

  if IsServer() then
    local parent = self:GetParent()
    if not parent:IsHero() then
      self:SetStackCount(DOTA_ATTRIBUTE_MAX+1)
      return
    end

    local stats = {}
    -- DOTA_ATTRIBUTE_INVALID = -1
    -- DOTA_ATTRIBUTE_STRENGTH = 0
    -- DOTA_ATTRIBUTE_AGILITY = 1
    -- DOTA_ATTRIBUTE_INTELLECT = 2
    -- DOTA_ATTRIBUTE_MAX = 3
    stats[DOTA_ATTRIBUTE_STRENGTH+1] = parent:GetBaseStrength() + parent:GetStrengthGain() * 49
    stats[DOTA_ATTRIBUTE_AGILITY+1] = parent:GetBaseAgility() + parent:GetAgilityGain() * 49
    stats[DOTA_ATTRIBUTE_INTELLECT+1] = parent:GetBaseIntellect() + parent:GetIntellectGain() * 49

    local attribute = DOTA_ATTRIBUTE_STRENGTH
    local min_v = stats[1]
    for k, v in ipairs(stats) do
      if v < min_v then
        min_v = v
        attribute = k-1
      end
    end

    self:SetStackCount(attribute)
  end
end

function modifier_item_far_sight_stacking_stats:OnRefresh()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.health = ability:GetSpecialValueFor("bonus_health")
    self.health_regen = ability:GetSpecialValueFor("bonus_health_regen")
    self.mana = ability:GetSpecialValueFor("bonus_mana")
    self.mana_regen = ability:GetSpecialValueFor("bonus_mana_regen")
    self.armor = ability:GetSpecialValueFor("bonus_armor")
    self.worst_attr = ability:GetSpecialValueFor("bonus_to_worst_attribute")
    --self.strength = ability:GetSpecialValueFor("bonus_strength")
    --self.agility = ability:GetSpecialValueFor("bonus_agility")
    --self.intellect = ability:GetSpecialValueFor("bonus_intellect")
  end

  if IsServer() then
    local parent = self:GetParent()
    if not parent:IsHero() then
      self:SetStackCount(DOTA_ATTRIBUTE_MAX+1)
      return
    end

    local stats = {}
    stats[DOTA_ATTRIBUTE_STRENGTH+1] = parent:GetBaseStrength() + parent:GetStrengthGain() * 49
    stats[DOTA_ATTRIBUTE_AGILITY+1] = parent:GetBaseAgility() + parent:GetAgilityGain() * 49
    stats[DOTA_ATTRIBUTE_INTELLECT+1] = parent:GetBaseIntellect() + parent:GetIntellectGain() * 49

    local attribute = DOTA_ATTRIBUTE_STRENGTH
    local min_v = stats[1]
    for k, v in ipairs(stats) do
      if v < min_v then
        min_v = v
        attribute = k-1
      end
    end

    self:SetStackCount(attribute)
  end
end

function modifier_item_far_sight_stacking_stats:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_HEALTH_BONUS,
    MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
    MODIFIER_PROPERTY_MANA_BONUS,
    MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
    MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
    MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
    MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
    MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
  }
end

function modifier_item_far_sight_stacking_stats:GetModifierHealthBonus()
  return self.health or self:GetAbility():GetSpecialValueFor("bonus_health")
end

function modifier_item_far_sight_stacking_stats:GetModifierConstantHealthRegen()
  return self.health_regen or self:GetAbility():GetSpecialValueFor("bonus_health_regen")
end

function modifier_item_far_sight_stacking_stats:GetModifierManaBonus()
  return self.mana or self:GetAbility():GetSpecialValueFor("bonus_mana")
end

function modifier_item_far_sight_stacking_stats:GetModifierConstantManaRegen()
  return self.mana_regen or self:GetAbility():GetSpecialValueFor("bonus_mana_regen")
end

function modifier_item_far_sight_stacking_stats:GetModifierPhysicalArmorBonus()
  return self.armor or self:GetAbility():GetSpecialValueFor("bonus_armor")
end

function modifier_item_far_sight_stacking_stats:GetModifierBonusStats_Strength()
  local attribute = self:GetStackCount()
  if attribute ~= DOTA_ATTRIBUTE_STRENGTH then
    return 0
  end

  return self.worst_attr or self:GetAbility():GetSpecialValueFor("bonus_to_worst_attribute")
  --return self.strength or self:GetAbility():GetSpecialValueFor("bonus_strength")
end

function modifier_item_far_sight_stacking_stats:GetModifierBonusStats_Agility()
  local attribute = self:GetStackCount()
  if attribute ~= DOTA_ATTRIBUTE_AGILITY then
    return 0
  end

  return self.worst_attr or self:GetAbility():GetSpecialValueFor("bonus_to_worst_attribute")
  --return self.agility or self:GetAbility():GetSpecialValueFor("bonus_agility")
end

function modifier_item_far_sight_stacking_stats:GetModifierBonusStats_Intellect()
  local attribute = self:GetStackCount()
  if attribute ~= DOTA_ATTRIBUTE_INTELLECT then
    return 0
  end

  return self.worst_attr or self:GetAbility():GetSpecialValueFor("bonus_to_worst_attribute")
  --return self.intellect or self:GetAbility():GetSpecialValueFor("bonus_intellect")
end

---------------------------------------------------------------------------------------------------

modifier_item_far_sight_non_stacking_stats = class(ModifierBaseClass)

function modifier_item_far_sight_non_stacking_stats:IsHidden()
  return true
end

function modifier_item_far_sight_non_stacking_stats:IsDebuff()
  return false
end

function modifier_item_far_sight_non_stacking_stats:IsPurgable()
  return false
end

function modifier_item_far_sight_non_stacking_stats:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.vision = ability:GetSpecialValueFor("bonus_vision_percentage")
    self.cast_range = ability:GetSpecialValueFor("bonus_cast_range")
  end
end

function modifier_item_far_sight_non_stacking_stats:OnRefresh()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.vision = ability:GetSpecialValueFor("bonus_vision_percentage")
    self.cast_range = ability:GetSpecialValueFor("bonus_cast_range")
  end
end

function modifier_item_far_sight_non_stacking_stats:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_BONUS_VISION_PERCENTAGE,
    MODIFIER_PROPERTY_CAST_RANGE_BONUS_STACKING,
  }
end

function modifier_item_far_sight_non_stacking_stats:GetBonusVisionPercentage()
  return self.vision or self:GetAbility():GetSpecialValueFor("bonus_vision_percentage")
end

function modifier_item_far_sight_non_stacking_stats:GetModifierCastRangeBonusStacking()
  local parent = self:GetParent()

  -- Prevent stacking with Aether Lens
  if parent:HasModifier("modifier_item_aether_lens") then
    return 0
  end

  return self.cast_range or self:GetAbility():GetSpecialValueFor("bonus_cast_range")
end

---------------------------------------------------------------------------------------------------

modifier_item_far_sight_true_sight = class(ModifierBaseClass)

function modifier_item_far_sight_true_sight:IsHidden()
  return true
end

function modifier_item_far_sight_true_sight:IsPurgable()
  return false
end

function modifier_item_far_sight_true_sight:IsAura()
  return true
end

function modifier_item_far_sight_true_sight:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.revealRadius = ability:GetSpecialValueFor("reveal_radius")
  else
    self.revealRadius = 750
  end

  if IsServer() then
    local parent = self:GetParent()
    local parent_location = parent:GetAbsOrigin()
    local parent_team = parent:GetTeamNumber()
    local enemy_team = DOTA_TEAM_BADGUYS
    if parent_team == enemy_team then
      enemy_team = DOTA_TEAM_GOODGUYS
    end

    local enemies = FindUnitsInRadius(
      parent_team,
      parent:GetAbsOrigin(),
      nil,
      self.revealRadius,
      DOTA_UNIT_TARGET_TEAM_ENEMY,
      bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC),
      DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
      FIND_ANY_ORDER,
      false
    )

    -- Reveal the dummy if the enemy is there
    for _, enemy in pairs(enemies) do
      if enemy and not enemy:IsNull() and not self.made_visible then
        if enemy:GetTeamNumber() ~= DOTA_TEAM_NEUTRALS then
          parent:MakeVisibleToTeam(enemy_team, 8)
          self.made_visible = true
          break
        end
      end
    end

    -- New particles
    local index1 = ParticleManager:CreateParticleForTeam("particles/items/far_sight/far_sight_green.vpcf", PATTACH_WORLDORIGIN, parent, parent_team)
    ParticleManager:SetParticleControl(index1, 0, parent_location)
    ParticleManager:SetParticleControl(index1, 1, Vector(self.revealRadius-100, 0, 0))

    local index2 = ParticleManager:CreateParticleForTeam("particles/items/far_sight/far_sight_red.vpcf", PATTACH_WORLDORIGIN, parent, enemy_team)
    ParticleManager:SetParticleControl(index2, 0, parent_location)
    ParticleManager:SetParticleControl(index2, 1, Vector(self.revealRadius-100, 0, 0))

    -- Dust Particle
    local dust_radius = self.revealRadius --ability:GetSpecialValueFor("dust_radius")
    local index3 = ParticleManager:CreateParticle("particles/items_fx/dust_of_appearance.vpcf", PATTACH_WORLDORIGIN, parent)
    ParticleManager:SetParticleControl(index3, 0, parent_location)
    ParticleManager:SetParticleControl(index3, 1, Vector(dust_radius, dust_radius, dust_radius))

    self.particle1 = index1
    self.particle2 = index2
    self.particle3 = index3

    -- Start thinking
    self:StartIntervalThink(1)
  end
end

function modifier_item_far_sight_true_sight:OnIntervalThink()
  if not IsServer() then
    return
  end
  local ability = self:GetAbility()
  if not ability or ability:IsNull() then
    return
  end

  local parent = self:GetParent()
  if not parent or parent:IsNull() or not parent:IsAlive() then
    return
  end

  local caster = ability:GetCaster()
  local dust_duration = ability:GetSpecialValueFor("dust_duration")
  local dust_radius = ability:GetSpecialValueFor("dust_radius")

  local enemies = FindUnitsInRadius(
    caster:GetTeamNumber(),
    parent:GetAbsOrigin(),
    nil,
    dust_radius,
    DOTA_UNIT_TARGET_TEAM_ENEMY,
    bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC),
    DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
    FIND_ANY_ORDER,
    false
  )
  local parent_team = parent:GetTeamNumber()
  local enemy_team = DOTA_TEAM_BADGUYS
  if parent_team == enemy_team then
    enemy_team = DOTA_TEAM_GOODGUYS
  end

  for _, enemy in pairs(enemies) do
    if enemy and not enemy:IsNull() then
      enemy:AddNewModifier(caster, ability, "modifier_item_dustofappearance", {duration = dust_duration})
      -- Reveal the dummy when the valid enemy walks into the area
      if enemy:GetTeamNumber() ~= DOTA_TEAM_NEUTRALS and not self.made_visible then
        parent:MakeVisibleToTeam(enemy_team, 8)
        self.made_visible = true
      end
    end
  end
end

function modifier_item_far_sight_true_sight:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_DEATH,
  }
end

if IsServer() then
  function modifier_item_far_sight_true_sight:OnDeath(event)
    if event.unit == self:GetParent() then
      if self.particle1 then
        ParticleManager:DestroyParticle(self.particle1, true)
        ParticleManager:ReleaseParticleIndex(self.particle1)
        self.particle1 = nil
      end

      if self.particle2 then
        ParticleManager:DestroyParticle(self.particle2, true)
        ParticleManager:ReleaseParticleIndex(self.particle2)
        self.particle2 = nil
      end

      if self.particle3 then
        ParticleManager:DestroyParticle(self.particle3, true)
        ParticleManager:ReleaseParticleIndex(self.particle3)
        self.particle3 = nil
      end
    end
  end
end

function modifier_item_far_sight_true_sight:GetModifierAura()
  return "modifier_truesight"
end

function modifier_item_far_sight_true_sight:GetAuraRadius()
  return self.revealRadius
end

function modifier_item_far_sight_true_sight:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_item_far_sight_true_sight:GetAuraSearchType()
  return DOTA_UNIT_TARGET_ALL
end

function modifier_item_far_sight_true_sight:GetAuraSearchFlags()
  return bit.bor(DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, DOTA_UNIT_TARGET_FLAG_INVULNERABLE)
end

function modifier_item_far_sight_true_sight:OnDestroy()
  if self.particle1 then
    ParticleManager:DestroyParticle(self.particle1, true)
    ParticleManager:ReleaseParticleIndex(self.particle1)
  end
  if self.particle2 then
    ParticleManager:DestroyParticle(self.particle2, true)
    ParticleManager:ReleaseParticleIndex(self.particle2)
  end
  if self.particle3 then
    ParticleManager:DestroyParticle(self.particle3, true)
    ParticleManager:ReleaseParticleIndex(self.particle3)
  end
end

---------------------------------------------------------------------------------------------------

modifier_far_sight_dummy_stuff = class(ModifierBaseClass)

function modifier_far_sight_dummy_stuff:IsHidden()
  return true
end

function modifier_far_sight_dummy_stuff:IsDebuff()
  return false
end

function modifier_far_sight_dummy_stuff:IsPurgable()
  return false
end

function modifier_far_sight_dummy_stuff:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.revealRadius = ability:GetSpecialValueFor("reveal_radius")
  else
    self.revealRadius = 750
  end
end

function modifier_far_sight_dummy_stuff:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
    MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
    MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
    MODIFIER_PROPERTY_BONUS_DAY_VISION,
    MODIFIER_PROPERTY_BONUS_NIGHT_VISION,
  }
end

function modifier_far_sight_dummy_stuff:GetAbsoluteNoDamagePhysical()
  return 1
end

function modifier_far_sight_dummy_stuff:GetAbsoluteNoDamageMagical()
  return 1
end

function modifier_far_sight_dummy_stuff:GetAbsoluteNoDamagePure()
  return 1
end

function modifier_far_sight_dummy_stuff:GetBonusDayVision()
  return self.revealRadius
end

function modifier_far_sight_dummy_stuff:GetBonusNightVision()
  return self.revealRadius
end

function modifier_far_sight_dummy_stuff:CheckState()
  return {
    [MODIFIER_STATE_UNSELECTABLE] = true,
    [MODIFIER_STATE_NOT_ON_MINIMAP] = true,
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
