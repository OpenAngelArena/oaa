LinkLuaModifier("modifier_tinkerer_laser_contraption_thinker", "abilities/tinkerer/tinkerer_laser_contraption.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_tinkerer_laser_contraption_debuff", "abilities/tinkerer/tinkerer_laser_contraption.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_tinkerer_laser_contraption_node", "abilities/tinkerer/tinkerer_laser_contraption.lua", LUA_MODIFIER_MOTION_NONE)

local square_shape = false

local function ApplyLaser(source, attach_source, target, attach_target)
  local particle_name = "particles/econ/items/tinker/tinker_ti10_immortal_laser/tinker_ti10_immortal_laser.vpcf" --"particles/units/heroes/hero_tinker/tinker_laser.vpcf"
  local part = ParticleManager:CreateParticle(particle_name, PATTACH_POINT_FOLLOW, target)
  if source:ScriptLookupAttachment(attach_source) ~= 0 then
    ParticleManager:SetParticleControlEnt(part, 9, source, PATTACH_POINT_FOLLOW, attach_source, source:GetAbsOrigin(), true)
  else
    ParticleManager:SetParticleControl(part, 9, source:GetAbsOrigin())
  end
  if target:ScriptLookupAttachment(attach_target) ~= 0 then
    ParticleManager:SetParticleControlEnt(part, 1, target, PATTACH_POINT_FOLLOW, attach_target, target:GetAbsOrigin(), true)
  else
    ParticleManager:SetParticleControl(part, 1, target:GetAbsOrigin())
  end
  ParticleManager:ReleaseParticleIndex(part)
end

tinkerer_laser_contraption = class({})

function tinkerer_laser_contraption:GetAOERadius()
  return self:GetSpecialValueFor("radius")
end

function tinkerer_laser_contraption:OnAbilityPhaseStart()
  if not IsServer() then
    return
  end

  local caster = self:GetCaster()

  -- Sound during casting
  caster:EmitSound("Hero_Tinker.LaserAnim")

  return true
end

function tinkerer_laser_contraption:OnAbilityPhaseInterrupted()
  if not IsServer() then
    return
  end

  -- Interrupt casting sound
  self:GetCaster():StopSound("Hero_Tinker.LaserAnim")
end

function tinkerer_laser_contraption:OnSpellStart()
  local caster = self:GetCaster()
  local cursor = self:GetCursorPosition()
  if not cursor then
    return
  end
  local team = caster:GetTeamNumber()
  local total_duration = self:GetSpecialValueFor("duration") + self:GetSpecialValueFor("delay")
  local radius = self:GetSpecialValueFor("radius")

  local effect_radius
  local positions = {}
  local kv = {
    duration = total_duration,
    center_x = tostring(cursor.x),
    center_y = tostring(cursor.y),
  }

  if square_shape then
	effect_radius = radius * math.sqrt(2) + 50 -- because nodes form in a square

	local top = cursor + radius * Vector(0, 1, 0)
	local bottom = cursor + radius * Vector(0, -1, 0)
	local left = cursor + radius * Vector(-1, 0, 0)
	local right = cursor + radius * Vector(1, 0, 0)

	local top_left = left + radius * Vector(0, 1, 0)
	local top_right = right + radius * Vector(0, 1, 0)

	local bot_left = left + radius * Vector(0, -1, 0)
	local bot_right = right + radius * Vector(0, -1, 0)

	local p1 = left + radius * 0.5 * Vector(0, 1, 0)
	local p2 = right + radius * 0.5 * Vector(0, 1, 0)
	local p3 = left + radius * 0.5 * Vector(0, -1, 0)
	local p4 = right + radius * 0.5 * Vector(0, -1, 0)
	local p5 = top + radius * 0.5 * Vector(1, 0, 0)
	local p6 = top + radius * 0.5 * Vector(-1, 0, 0)
	local p7 = bottom + radius * 0.5 * Vector(1, 0, 0)
	local p8 = bottom + radius * 0.5 * Vector(-1, 0, 0)

	table.insert(positions, top)
	table.insert(positions, bottom)
	table.insert(positions, left)
	table.insert(positions, right)
	table.insert(positions, top_left)
	table.insert(positions, top_right)
	table.insert(positions, bot_left)
	table.insert(positions, bot_right)
	table.insert(positions, p1)
	table.insert(positions, p2)
	table.insert(positions, p3)
	table.insert(positions, p4)
	table.insert(positions, p5)
	table.insert(positions, p6)
	table.insert(positions, p7)
	table.insert(positions, p8)
  else
    effect_radius = radius + 100
    for i = 1, 16 do
      local angle = math.pi * 2 / 16 * i
      local pos = cursor + Vector(math.cos(angle), math.sin(angle), 0) * radius
      table.insert(positions, pos)
    end
  end

  -- Create a thinker at the location
  local thinker = CreateModifierThinker(caster, self, "modifier_tinkerer_laser_contraption_thinker", kv, cursor, team, false)

  -- Destroy trees
  GridNav:DestroyTreesAroundPoint(cursor, effect_radius, true)

  -- Create nodes
  for _, pos in pairs(positions) do
    local node = CreateUnitByName("npc_dota_tinkerer_keen_node", pos, false, caster, caster, team)
    node:AddNewModifier(caster, self, "modifier_tinkerer_laser_contraption_node", {duration = total_duration})
    node:AddNewModifier(caster, self, 'modifier_kill', {duration = total_duration})
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

  -- Visual effect
  ApplyLaser(caster, "attach_attack2", thinker, "attach_hitloc")

  -- Damage table
  local damage_table = {}
  damage_table.attacker = caster
  damage_table.damage = self:GetSpecialValueFor("initial_damage")
  damage_table.ability = self
  damage_table.damage_type = self:GetAbilityDamageType()

  -- Unstuck all non-node units and damage non-spell-immune enemies if non-square shape
  for _, unit in pairs(units) do
    if unit and not unit:IsNull() and unit:GetUnitName() ~= "npc_dota_tinkerer_keen_node" then
      local origin = unit:GetAbsOrigin()
      FindClearSpaceForUnit(unit, origin, true)
      if unit:GetTeamNumber() ~= team and not unit:IsMagicImmune() and not square_shape then
        damage_table.victim = unit
        ApplyDamage(damage_table)
      end
    end
  end

  if square_shape then
    local enemies = FindUnitsInLine(
      team,
      cursor + radius * Vector(-1, 0, 0),
      cursor + radius * Vector(1, 0, 0),
      nil,
      radius,
      self:GetAbilityTargetTeam(),
      self:GetAbilityTargetType(),
      DOTA_UNIT_TARGET_FLAG_NONE
    )

    -- Damage enemies in a square
    for _, enemy in pairs(enemies) do
      if enemy and not enemy:IsNull() and not enemy:IsMagicImmune() then
        damage_table.victim = enemy
        ApplyDamage(damage_table)
      end
    end
  end

  -- Sound
  caster:EmitSound("Hero_Tinker.Laser")
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
  return "modifier_tinkerer_laser_contraption_debuff"
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
  local dmg_interval = 2
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
  self.rad_or_width = radius
  self.established = false

  local center = Vector(tonumber(kv.center_x), tonumber(kv.center_y), 0)
  self.center = center
  if square_shape then
    self.start_pos = center + radius * Vector(0, 1, 0)
    self.end_pos = center + radius * Vector(0, -1, 0)
  end

  -- Start thinking
  self:StartIntervalThink(delay)
end

function modifier_tinkerer_laser_contraption_thinker:OnIntervalThink()
  if not IsServer() then
    return
  end

  local parent = self:GetParent()
  local caster = self:GetCaster() or parent

  if not parent or parent:IsNull() or not parent:IsAlive() then
    return
  end

  local enemies = {}
  if square_shape then
    enemies = FindUnitsInLine(
      caster:GetTeamNumber(),
      self.start_pos,
      self.end_pos,
      nil,
      self.rad_or_width,
      DOTA_UNIT_TARGET_TEAM_ENEMY,
      bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC),
      DOTA_UNIT_TARGET_FLAG_NONE
    )
  else
    enemies = FindUnitsInRadius(
      caster:GetTeamNumber(),
      self.center,
      nil,
      self.rad_or_width,
      DOTA_UNIT_TARGET_TEAM_ENEMY,
      bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC),
      DOTA_UNIT_TARGET_FLAG_NONE,
      FIND_ANY_ORDER,
      false
    )
  end

  local allies = FindUnitsInRadius(
    caster:GetTeamNumber(),
    self.center,
    nil,
    self.rad_or_width * math.sqrt(2) + 10,
    DOTA_UNIT_TARGET_TEAM_FRIENDLY,
    DOTA_UNIT_TARGET_BASIC,
    DOTA_UNIT_TARGET_FLAG_NONE,
    FIND_ANY_ORDER,
    false
  )

  -- Store nodes
  local nodes = {}
  for _, unit in pairs(allies) do
    if unit and not unit:IsNull() and unit:IsAlive() and unit:GetUnitName() == "npc_dota_tinkerer_keen_node" then
      table.insert(nodes, unit)
    end
  end

  -- Damage table
  local damage_table = {}
  damage_table.attacker = caster
  damage_table.damage = self.dmg_per_interval * #nodes / 16
  damage_table.damage_type = DAMAGE_TYPE_MAGICAL

  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    damage_table.ability = ability
    damage_table.damage_type = ability:GetAbilityDamageType()
  end

  -- Visual effect - lasers
  for _, node in pairs(nodes) do
    if node and not node:IsNull() and node:IsAlive() then
      ApplyLaser(node, "attach_attack1", parent, "attach_hitloc")
    end
  end

  -- Damage enemies
  for _, enemy in pairs(enemies) do
    if enemy and not enemy:IsNull() then
      -- Actual damage
      damage_table.victim = enemy
      ApplyDamage(damage_table)
    end
  end

  -- Sound
  parent:EmitSound("Hero_Tinker.LaserImpact")

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
    --[MODIFIER_STATE_NO_HEALTH_BAR] = true,
    [MODIFIER_STATE_STUNNED] = true,
  }
  return state
end

function modifier_tinkerer_laser_contraption_node:OnDestroy()
  if not IsServer() then
    return
  end
  local parent = self:GetParent()
  if parent and not parent:IsNull() then
    parent:AddNoDraw()
    -- Sound
    --parent:EmitSound("Hero_Rattletrap.Power_Cog.Destroy")
  end
end
