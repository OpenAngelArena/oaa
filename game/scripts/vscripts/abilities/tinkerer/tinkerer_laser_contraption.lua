LinkLuaModifier("modifier_tinkerer_laser_contraption_thinker", "abilities/tinkerer/tinkerer_laser_contraption.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_tinkerer_laser_contraption_debuff", "abilities/tinkerer/tinkerer_laser_contraption.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_tinkerer_laser_contraption_node", "abilities/tinkerer/tinkerer_laser_contraption.lua", LUA_MODIFIER_MOTION_NONE)

tinkerer_laser_contraption = class({})

function tinkerer_laser_contraption:GetAOERadius()
  return self:GetSpecialValueFor("radius")
end

function tinkerer_laser_contraption:OnSpellStart()
  local caster = self:GetCaster()
  local cursor = self:GetCursorPosition()
  local team = caster:GetTeamNumber()
  local node_duration = self:GetSpecialValueFor("duration")
  local thinker_duration = node_duration + self:GetSpecialValueFor("delay")
  local radius = self:GetSpecialValueFor("radius")
  local effect_radius = radius * math.sqrt(2) + 50 -- because nodes form in a square

  local top = cursor + radius * Vector(0, 1, 0)
  local bottom = cursor + radius * Vector(0, -1, 0)
  local left = cursor + radius * Vector(-1, 0, 0)
  local right = cursor + radius * Vector(1, 0, 0)

  local top_left = left + radius * Vector(0, 1, 0)
  local top_right = right + radius * Vector(0, 1, 0)

  local bot_left = left + radius * Vector(0, -1, 0)
  local bot_right = right + radius * Vector(0, -1, 0)

  local positions = {}

  table.insert(positions, top)
  table.insert(positions, bottom)
  table.insert(positions, left)
  table.insert(positions, right)
  table.insert(positions, top_left)
  table.insert(positions, top_right)
  table.insert(positions, bot_left)
  table.insert(positions, bot_right)

  local kv = {
    duration = thinker_duration,
    start_x = tostring(top.x),
    start_y = tostring(top.y),
    end_x = tostring(bottom.x),
    end_y = tostring(bottom.y),
  }

  -- Create a thinker at the location
  local thinker = CreateModifierThinker(caster, self, "modifier_tinkerer_laser_contraption_thinker", kv, cursor, team, false)

  -- Destroy trees
  GridNav:DestroyTreesAroundPoint(cursor, effect_radius, true)

  -- Create nodes
  for _, pos in pairs(positions) do
    local node = CreateUnitByName("npc_dota_tinkerer_keen_node", pos, false, caster, caster, team)
    node:AddNewModifier(caster, self, "modifier_tinkerer_laser_contraption_node", {duration = node_duration})
    node:AddNewModifier(caster, self, 'modifier_kill', {duration = node_duration})
    node:SetNeverMoveToClearSpace(true)
  end

  local units = FindUnitsInRadius(
    team,
    cursor,
    nil,
    effect_radius,
    DOTA_UNIT_TARGET_TEAM_BOTH,
    bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC),
    DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
    FIND_ANY_ORDER,
    false
  )

  -- Unstuck all non-node units
  for _, unit in pairs(units) do
    if unit and not unit:IsNull() and unit:GetUnitName() ~= "npc_dota_tinkerer_keen_node" then
      local origin = unit:GetAbsOrigin()
      FindClearSpaceForUnit(unit, origin, true)
    end
  end

  local enemies = FindUnitsInLine(
    team,
    left,
    right,
    nil,
    2 * radius,
    self:GetAbilityTargetTeam(),
    self:GetAbilityTargetType(),
    DOTA_UNIT_TARGET_FLAG_NONE
  )

  -- Damage table
  local damage_table = {}
  damage_table.attacker = caster
  damage_table.damage = self:GetSpecialValueFor("initial_damage")
  damage_table.ability = self
  damage_table.damage_type = self:GetAbilityDamageType()

  -- Damage enemies
  for _, enemy in pairs(enemies) do
    if enemy and not enemy:IsNull() then
      damage_table.victim = enemy
      ApplyDamage(damage_table)
    end
  end
end

---------------------------------------------------------------------------------------------------

modifier_tinkerer_laser_contraption_thinker = class({})

function modifier_tinkerer_laser_contraption_thinker:IsHidden()
  return true
end

function modifier_tinkerer_laser_contraption_thinker:IsPurgable()
  return false
end

function modifier_tinkerer_laser_contraption_thinker:IsAura()
  return self:GetCaster():HasScepter()
end

function modifier_tinkerer_laser_contraption_thinker:GetModifierAura()
  return "modifier_harpy_null_field_oaa_effect"
end

function modifier_tinkerer_laser_contraption_thinker:GetAuraRadius()
  return self:GetAbility():GetSpecialValueFor("radius")
end

function modifier_tinkerer_laser_contraption_thinker:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_tinkerer_laser_contraption_thinker:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC)
end

function modifier_tinkerer_laser_contraption_thinker:GetAuraSearchFlags()
  return DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
end

function modifier_tinkerer_laser_contraption_thinker:OnCreated(kv)
  if not IsServer() then
    return
  end

  local delay = 0.5
  local dmg_interval = 0.25
  local dps = 75
  local radius = 300

  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    delay = ability:GetSpecialValueFor("delay")
    dmg_interval = ability:GetSpecialValueFor("damage_interval")
    dps = ability:GetSpecialValueFor("damage_per_second")
    radius = ability:GetSpecialValueFor("radius")
  end

  self.interval = dmg_interval
  self.dmg_per_interval = dmg_interval * dps
  self.width = 2 * radius
  self.established = false

  self.start_pos = Vector(tonumber(kv.start_x), tonumber(kv.start_y), 0)
  self.end_pos = Vector(tonumber(kv.end_x), tonumber(kv.end_y), 0)

  -- Start thinking
  self:StartIntervalThink(delay)
end

function modifier_tinkerer_laser_contraption_thinker:OnIntervalThink()
  if not IsServer() then
    return
  end

  local caster = self:GetCaster() or self:GetParent()

  local enemies = FindUnitsInLine(
    caster:GetTeamNumber(),
    self.start_pos,
    self.end_pos,
    nil,
    self.width,
    DOTA_UNIT_TARGET_TEAM_ENEMY,
    bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC),
    DOTA_UNIT_TARGET_FLAG_NONE
  )

  -- Damage table
  local damage_table = {}
  damage_table.attacker = caster
  damage_table.damage = self.dmg_per_interval

  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    damage_table.ability = ability
    damage_table.damage_type = ability:GetAbilityDamageType()
  end

  -- Damage enemies
  for _, enemy in pairs(enemies) do
    if enemy and not enemy:IsNull() then
      damage_table.victim = enemy
      ApplyDamage(damage_table)
    end
  end

  if not self.established then
    self.established = true
    -- Change thinking interval
    self:StartIntervalThink(self.interval)
  end
end

function modifier_tinkerer_laser_contraption_thinker:OnDestroy()
  if not IsServer() then
    return
  end
  local parent = self:GetParent()
  if self.particle then
    ParticleManager:DestroyParticle(self.particle, true)
    ParticleManager:ReleaseParticleIndex(self.particle)
  end
  if parent and not parent:IsNull() then
    parent:ForceKill(false)
  end
end

---------------------------------------------------------------------------------------------------
-- Scepter Blind and Leash effect provided by an aura of the thinker

modifier_tinkerer_laser_contraption_debuff = class({})

function modifier_tinkerer_laser_contraption_debuff:IsHidden()
  return not self:GetCaster():HasScepter()
end

function modifier_tinkerer_laser_contraption_debuff:IsDebuff()
  return true
end

function modifier_tinkerer_laser_contraption_debuff:IsPurgable()
  return false
end

function modifier_tinkerer_laser_contraption_debuff:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.blind_pct = ability:GetSpecialValueFor("scepter_blind")
  end
end

modifier_tinkerer_laser_contraption_debuff.OnRefresh = modifier_tinkerer_laser_contraption_debuff.OnCreated

function modifier_tinkerer_laser_contraption_debuff:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MISS_PERCENTAGE,
  }
end

function modifier_tinkerer_laser_contraption_debuff:GetModifierMiss_Percentage()
  return self.blind_pct or self:GetAbility():GetSpecialValueFor("scepter_blind")
end

function modifier_tinkerer_laser_contraption_debuff:CheckState()
  local state = {
    [MODIFIER_STATE_TETHERED] = true,
  }
  return state
end

---------------------------------------------------------------------------------------------------

modifier_tinkerer_laser_contraption_node = class(ModifierBaseClass)

function modifier_tinkerer_laser_contraption_node:IsHidden()
  return true
end

function modifier_tinkerer_laser_contraption_node:IsDebuff()
  return false
end

function modifier_tinkerer_laser_contraption_node:IsPurgable()
  return false
end

function modifier_tinkerer_laser_contraption_node:RemoveOnDeath()
  return true
end

function modifier_tinkerer_laser_contraption_node:DeclareFunctions()
	local funcs =
	{
    MODIFIER_PROPERTY_DISABLE_HEALING,
    MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
    MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
    MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
    MODIFIER_EVENT_ON_ATTACKED
	}
	return funcs
end

function modifier_tinkerer_laser_contraption_node:GetAbsoluteNoDamagePhysical()
  return 1
end

function modifier_tinkerer_laser_contraption_node:GetAbsoluteNoDamageMagical()
  return 1
end

function modifier_tinkerer_laser_contraption_node:GetAbsoluteNoDamagePure()
  return 1
end

function modifier_tinkerer_laser_contraption_node:GetDisableHealing()
  return 1
end

if IsServer() then
  function modifier_tinkerer_laser_contraption_node:OnAttacked(event)
    local parent = self:GetParent()
    if event.target ~= parent then
      return
    end

    local attacker = event.attacker
    if not attacker or attacker:IsNull() then
      return
    end

    local damage = 1
    local ability = self:GetAbility()
    if ability and not ability:IsNull() then
      damage = math.ceil(parent:GetMaxHealth() / ability:GetSpecialValueFor("attacks_to_destroy"))
    end

    if not attacker:IsRealHero() then
      damage = 1
    end

    if attacker == self:GetCaster() then
      damage = parent:GetMaxHealth()
    end

    -- To prevent dead staying in memory (preventing SetHealth(0) or SetHealth(-value) )
    if parent:GetHealth() - damage <= 0 then
      parent:Kill(ability, attacker)
    else
      parent:SetHealth(parent:GetHealth() - damage)
    end
  end
end

function modifier_tinkerer_laser_contraption_node:CheckState()
  local state = {
    [MODIFIER_STATE_MAGIC_IMMUNE] = true,
    [MODIFIER_STATE_NOT_ON_MINIMAP] = true,
    [MODIFIER_STATE_CANNOT_BE_MOTION_CONTROLLED] = true,
    [MODIFIER_STATE_SPECIALLY_DENIABLE] = true,
    [MODIFIER_STATE_NO_HEALTH_BAR] = true,
    [MODIFIER_STATE_STUNNED] = true,
  }
  return state
end
