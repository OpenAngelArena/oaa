LinkLuaModifier("modifier_electrician_electric_shield_dc", "abilities/electrician/electrician_electric_shield.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_electrician_electric_shield_ac", "abilities/electrician/electrician_electric_shield.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_electrician_electric_shield_nc", "abilities/electrician/electrician_electric_shield.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_electrician_electric_shield_nc_buff", "abilities/electrician/electrician_electric_shield.lua", LUA_MODIFIER_MOTION_NONE)

electrician_electric_shield = class(AbilityBaseClass)

function electrician_electric_shield:GetManaCost(level)
  local caster = self:GetCaster()
  local flat_mana_cost = self:GetSpecialValueFor("flat_mana_cost")
  local max_mana_cost = self:GetSpecialValueFor("max_mana_cost")

  if max_mana_cost > 0 then
    local currentMana = caster:GetMana()
    local cost = flat_mana_cost

    if currentMana > flat_mana_cost then
      local fullCost = max_mana_cost * 0.01 * caster:GetMaxMana()
      cost = math.min(currentMana, fullCost)
    end

    -- GetManaCost gets called after paying the cost but before OnSpellStart occurs
    -- so we need to only track the cost the moment the spell is cast and never
    -- any other time
    if self.recordCost then
      self.usedCost = cost
      self.recordCost = false
    end

    return cost
  end

  return flat_mana_cost
end

function electrician_electric_shield:GetCastRange(location, target)
  return self:GetSpecialValueFor("aura_radius")
end

-- this is seemingly the only thing that gets called before OnSpellStart for this kind
-- of spell, at least as far as non-hacks go
function electrician_electric_shield:CastFilterResult()
  local caster = self:GetCaster()

  -- currently being nullified / demonically purged
  if caster:HasModifier("modifier_item_nullifier_mute") or caster:HasModifier("modifier_shadow_demon_purge_slow") then
    return UF_FAIL_CUSTOM
  end

	self.recordCost = true
	return UF_SUCCESS
end

function electrician_electric_shield:GetCustomCastError()
  local caster = self:GetCaster()

  if caster:HasModifier("modifier_item_nullifier_mute") or caster:HasModifier("modifier_shadow_demon_purge_slow") then
    return "#oaa_hud_error_cast_while_nullified"
  end
end

function electrician_electric_shield:OnSpellStart()
  local caster = self:GetCaster()
  local max_mana_cost = self:GetSpecialValueFor("max_mana_cost")
  local shield_duration = self:GetSpecialValueFor("duration")

  if max_mana_cost > 0 then
    local spent_mana = self.usedCost

    local magic_shield = self:GetSpecialValueFor("magical_shield_damage_block") ~= 0
    if magic_shield then
      caster:AddNewModifier(caster, self, "modifier_electrician_electric_shield_dc", {duration = shield_duration, spent_mana = spent_mana})
    else
      caster:AddNewModifier(caster, self, "modifier_electrician_electric_shield_nc", {duration = shield_duration, spent_mana = spent_mana})
      caster:AddNewModifier(caster, self, "modifier_electrician_electric_shield_nc_buff", {duration = shield_duration})
    end
  else
    caster:AddNewModifier(caster, self, "modifier_electrician_electric_shield_ac", {duration = shield_duration})
  end

  -- Cast Sound
  caster:EmitSound("Ability.static.start")
end

function electrician_electric_shield:ProcMagicStick()
  return true
end

--TODO: OnStolen (Rubick and Morphling)

---------------------------------------------------------------------------------------------------

modifier_electrician_electric_shield_dc = class(ModifierBaseClass)

function modifier_electrician_electric_shield_dc:IsHidden()
  return false
end

function modifier_electrician_electric_shield_dc:IsDebuff()
  return false
end

function modifier_electrician_electric_shield_dc:IsPurgable()
  return true
end

function modifier_electrician_electric_shield_dc:OnCreated(event)
  local ability = self:GetAbility()
  local parent = self:GetParent()

  if not ability or ability:IsNull() then
    return
  end

  -- Shield stuff
  local max_mana = parent:GetMaxMana()
  local max_mana_cost = max_mana * ability:GetSpecialValueFor("max_mana_cost") * 0.01
  local shield_per_mana = ability:GetSpecialValueFor("shield_per_mana")
  self.shield_block = ability:GetSpecialValueFor("magical_shield_damage_block") * 0.01
  self.max_shield_hp = max_mana_cost * shield_per_mana

  if IsServer() then
    local spent_mana = event.spent_mana -- only visible on the server
    local shield_hp = spent_mana * shield_per_mana
    self:SetStackCount(0 - shield_hp)

    -- create the shield particles
    self.particle = ParticleManager:CreateParticle("particles/hero/electrician/electrician_electric_shield.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
    ParticleManager:SetParticleControlEnt(self.particle, 1, parent, PATTACH_ABSORIGIN_FOLLOW, nil, parent:GetAbsOrigin(), true)

    -- Aura damage stuff
    local dmg_interval = ability:GetSpecialValueFor("aura_interval")
    local dps = ability:GetSpecialValueFor("aura_damage")
    self.dmg_radius = ability:GetSpecialValueFor("aura_radius")
    self.dmg_per_interval = dps * dmg_interval

    -- start thinking
    self:OnIntervalThink()
    self:StartIntervalThink(dmg_interval)
  end
end

function modifier_electrician_electric_shield_dc:OnRefresh(event)
  -- Destroy the old (previous) instance of shield particle
  if self.particle then
    ParticleManager:DestroyParticle(self.particle, false)
    ParticleManager:ReleaseParticleIndex(self.particle)
    self.particle = nil
  end

  -- Stop the previous instance of thinking
  if IsServer() then
    self:StartIntervalThink(-1)
  end

  self:OnCreated(event)
end

function modifier_electrician_electric_shield_dc:OnIntervalThink()
  if not IsServer() then
    return
  end

  local ability = self:GetAbility()
  local parent = self:GetParent()

  if not parent or parent:IsNull() or not ability or ability:IsNull() then
    return
  end

  local parentOrigin = parent:GetAbsOrigin()

  local enemies = FindUnitsInRadius(
    parent:GetTeamNumber(),
    parentOrigin,
    nil,
    self.dmg_radius,
    ability:GetAbilityTargetTeam(),
    ability:GetAbilityTargetType(),
    DOTA_UNIT_TARGET_FLAG_NONE,
    FIND_ANY_ORDER,
    false
  )

  local damage_table = {
    attacker = parent,
    damage = self.dmg_per_interval,
    damage_type = DAMAGE_TYPE_MAGICAL,
    damage_flags = DOTA_DAMAGE_FLAG_NONE,
    ability = ability,
  }

  for _, enemy in pairs(enemies) do
    -- Hit Particle
    local part = ParticleManager:CreateParticle("particles/items_fx/chain_lightning.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
    ParticleManager:SetParticleControlEnt(part, 0, enemy, PATTACH_POINT_FOLLOW, "attach_hitloc", enemy:GetAbsOrigin(), true)
    ParticleManager:SetParticleControlEnt(part, 1, parent, PATTACH_POINT_FOLLOW, "attach_hitloc", parentOrigin, true)
    ParticleManager:ReleaseParticleIndex(part)

    -- Hit Sound
    enemy:EmitSound("Hero_razor.lightning")

    -- Apply damage
    damage_table.victim = enemy
    ApplyDamage(damage_table)
  end
end

function modifier_electrician_electric_shield_dc:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_INCOMING_SPELL_DAMAGE_CONSTANT,
  }
end

function modifier_electrician_electric_shield_dc:GetModifierIncomingSpellDamageConstant(event)
  local parent = self:GetParent()
  local ability = self:GetAbility()

  if not parent or parent:IsNull() or not ability or ability:IsNull() then
    return 0
  end

  if IsClient() then
    -- Shield numbers (visual only)
    if event.report_max then
      return self.max_shield_hp
    else
      return math.abs(self:GetStackCount()) -- current shield hp
    end
  else
    -- Don't react to damage with HP removal flag
    if bit.band(event.damage_flags, DOTA_DAMAGE_FLAG_HPLOSS) == DOTA_DAMAGE_FLAG_HPLOSS then
      return 0
    end

    -- Don't react on self damage
    if event.attacker == parent then
      return 0
    end

    local damage = event.damage
    if damage < 0 then
      return 0
    end

    -- Get current (remaining) shield hp
    local shield_hp = math.abs(self:GetStackCount())

    -- Don't block more than remaining hp
    local block_amount = math.min(damage*self.shield_block, shield_hp)

    -- Reduce shield hp (using negative stacks to not show them on the buff)
    self:SetStackCount(block_amount - shield_hp)

    if block_amount > 0 then
      -- Visual effect (TODO: add unique visual effect)
      SendOverheadEventMessage(nil, OVERHEAD_ALERT_MAGICAL_BLOCK, parent, block_amount, nil)
    end

    -- Remove the shield if hp is reduced to nothing
    if self:GetStackCount() >= 0 then
      self:Destroy()
    end

    return -block_amount
  end
end

function modifier_electrician_electric_shield_dc:OnDestroy()
  if not IsServer() then
    return
  end

  -- Destroy the shield particle
  if self.particle then
    ParticleManager:DestroyParticle(self.particle, false)
    ParticleManager:ReleaseParticleIndex(self.particle)
  end

  -- Expire sound
  self:GetParent():EmitSound("Hero_Razor.StormEnd")
end

---------------------------------------------------------------------------------------------------

modifier_electrician_electric_shield_ac = class(ModifierBaseClass)

function modifier_electrician_electric_shield_ac:IsHidden()
  return false
end

function modifier_electrician_electric_shield_ac:IsDebuff()
  return false
end

function modifier_electrician_electric_shield_ac:IsPurgable()
  return true
end

function modifier_electrician_electric_shield_ac:OnCreated()
  local ability = self:GetAbility()
  local parent = self:GetParent()

  if not ability or ability:IsNull() then
    return
  end

  -- Shield stuff
  self.dmg_block = ability:GetSpecialValueFor("attack_damage_block")
  self.magic_resist = ability:GetSpecialValueFor("bonus_magic_resist")

  if IsServer() then
    -- create the shield particles
    self.particle = ParticleManager:CreateParticle("particles/hero/electrician/electrician_electric_shield.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
    ParticleManager:SetParticleControlEnt(self.particle, 1, parent, PATTACH_ABSORIGIN_FOLLOW, nil, parent:GetAbsOrigin(), true)

    -- Aura damage stuff
    local dmg_interval = ability:GetSpecialValueFor("aura_interval")
    local dps = ability:GetSpecialValueFor("aura_damage")
    self.dmg_radius = ability:GetSpecialValueFor("aura_radius")
    self.dmg_per_interval = dps * dmg_interval
    self.iteration = 0

    -- start thinking
    self:OnIntervalThink()
    self:StartIntervalThink(dmg_interval)
  end
end

function modifier_electrician_electric_shield_ac:OnRefresh()
  -- Destroy the old (previous) instance of shield particle
  if self.particle then
    ParticleManager:DestroyParticle(self.particle, false)
    ParticleManager:ReleaseParticleIndex(self.particle)
    self.particle = nil
  end

  -- Stop the previous instance of thinking
  if IsServer() then
    self:StartIntervalThink(-1)
  end

  self:OnCreated()
end

function modifier_electrician_electric_shield_ac:OnIntervalThink()
  if not IsServer() then
    return
  end

  local ability = self:GetAbility()
  local parent = self:GetParent()

  if not parent or parent:IsNull() or not ability or ability:IsNull() then
    return
  end

  local parentOrigin = parent:GetAbsOrigin()

  local enemies = FindUnitsInRadius(
    parent:GetTeamNumber(),
    parentOrigin,
    nil,
    self.dmg_radius,
    ability:GetAbilityTargetTeam(),
    ability:GetAbilityTargetType(),
    DOTA_UNIT_TARGET_FLAG_NONE,
    FIND_ANY_ORDER,
    false
  )

  -- Alternating damage type
  local dmg_type = DAMAGE_TYPE_MAGICAL
  if self.iteration == 0 or self.iteration % 2 == 0 then
    dmg_type = DAMAGE_TYPE_PHYSICAL
  end

  local damage_table = {
    attacker = parent,
    damage = self.dmg_per_interval,
    damage_type = dmg_type,
    damage_flags = DOTA_DAMAGE_FLAG_NONE,
    ability = ability,
  }

  for _, enemy in pairs(enemies) do
    -- Hit Particle
    local part = ParticleManager:CreateParticle("particles/items_fx/chain_lightning.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
    ParticleManager:SetParticleControlEnt(part, 0, enemy, PATTACH_POINT_FOLLOW, "attach_hitloc", enemy:GetAbsOrigin(), true)
    ParticleManager:SetParticleControlEnt(part, 1, parent, PATTACH_POINT_FOLLOW, "attach_hitloc", parentOrigin, true)
    ParticleManager:ReleaseParticleIndex(part)

    -- Hit Sound
    enemy:EmitSound("Hero_razor.lightning")

    -- Apply damage
    damage_table.victim = enemy
    ApplyDamage(damage_table)
  end

  self.iteration = self.iteration + 1
end

function modifier_electrician_electric_shield_ac:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_PHYSICAL_CONSTANT_BLOCK,
    MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
  }
end

function modifier_electrician_electric_shield_ac:GetModifierPhysical_ConstantBlock()
  return self.dmg_block
end

function modifier_electrician_electric_shield_ac:GetModifierMagicalResistanceBonus()
  return self.magic_resist
end

function modifier_electrician_electric_shield_ac:OnDestroy()
  if not IsServer() then
    return
  end

  -- Destroy the shield particle
  if self.particle then
    ParticleManager:DestroyParticle(self.particle, false)
    ParticleManager:ReleaseParticleIndex(self.particle)
  end

  -- Expire sound
  self:GetParent():EmitSound("Hero_Razor.StormEnd")
end

---------------------------------------------------------------------------------------------------

modifier_electrician_electric_shield_nc = class(ModifierBaseClass)

function modifier_electrician_electric_shield_nc:IsHidden()
  return false
end

function modifier_electrician_electric_shield_nc:IsDebuff()
  return false
end

function modifier_electrician_electric_shield_nc:IsPurgable()
  return true
end

function modifier_electrician_electric_shield_nc:OnCreated(event)
  local ability = self:GetAbility()
  local parent = self:GetParent()

  if not ability or ability:IsNull() then
    return
  end

  local max_mana = parent:GetMaxMana()
  local max_mana_cost = max_mana * ability:GetSpecialValueFor("max_mana_cost") * 0.01
  local shield_per_mana = ability:GetSpecialValueFor("shield_per_mana")
  self.shield_block = ability:GetSpecialValueFor("physical_shield_damage_block") * 0.01
  self.max_shield_hp = max_mana_cost * shield_per_mana

  if IsServer() then
    local spent_mana = event.spent_mana -- only visible on the server
    local shield_hp = spent_mana * shield_per_mana
    self:SetStackCount(0 - shield_hp)

    -- create the shield particles
    self.particle = ParticleManager:CreateParticle("particles/hero/electrician/electrician_electric_shield.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
    ParticleManager:SetParticleControlEnt(self.particle, 1, parent, PATTACH_ABSORIGIN_FOLLOW, nil, parent:GetAbsOrigin(), true)
  end
end

function modifier_electrician_electric_shield_nc:OnRefresh(event)
  -- Destroy the old (previous) instance of shield particle
  if self.particle then
    ParticleManager:DestroyParticle(self.particle, false)
    ParticleManager:ReleaseParticleIndex(self.particle)
    self.particle = nil
  end

  self:OnCreated(event)
end

function modifier_electrician_electric_shield_nc:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_INCOMING_PHYSICAL_DAMAGE_CONSTANT,
  }
end

function modifier_electrician_electric_shield_nc:GetModifierIncomingPhysicalDamageConstant(event)
  local parent = self:GetParent()
  local ability = self:GetAbility()

  if not parent or parent:IsNull() or not ability or ability:IsNull() then
    return 0
  end

  if IsClient() then
    -- Shield numbers (visual only)
    if event.report_max then
      return self.max_shield_hp
    else
      return math.abs(self:GetStackCount()) -- current shield hp
    end
  else
    -- Don't react to damage with HP removal flag
    if bit.band(event.damage_flags, DOTA_DAMAGE_FLAG_HPLOSS) == DOTA_DAMAGE_FLAG_HPLOSS then
      return 0
    end

    -- Don't react on self damage
    if event.attacker == parent then
      return 0
    end

    local damage = event.damage
    if damage < 0 then
      return 0
    end

    -- Get current (remaining) shield hp
    local shield_hp = math.abs(self:GetStackCount())

    -- Don't block more than remaining hp
    local block_amount = math.min(damage*self.shield_block, shield_hp)

    -- Reduce shield hp (using negative stacks to not show them on the buff)
    self:SetStackCount(block_amount - shield_hp)

    if block_amount > 0 then
      -- Visual effect (TODO: add unique visual effect)
      SendOverheadEventMessage(nil, OVERHEAD_ALERT_BLOCK, parent, block_amount, nil)
    end

    -- Remove the shield if hp is reduced to nothing
    if self:GetStackCount() >= 0 then
      self:Destroy()
    end

    return -block_amount
  end
end

function modifier_electrician_electric_shield_nc:OnDestroy()
  if not IsServer() then
    return
  end

  -- Destroy the shield particle
  if self.particle then
    ParticleManager:DestroyParticle(self.particle, false)
    ParticleManager:ReleaseParticleIndex(self.particle)
  end

  -- Expire sound
  self:GetParent():EmitSound("Hero_Razor.StormEnd")
end

---------------------------------------------------------------------------------------------------

modifier_electrician_electric_shield_nc_buff = class(ModifierBaseClass)

function modifier_electrician_electric_shield_nc_buff:IsHidden()
  return false
end

function modifier_electrician_electric_shield_nc_buff:IsDebuff()
  return false
end

function modifier_electrician_electric_shield_nc_buff:IsPurgable()
  return true
end

function modifier_electrician_electric_shield_nc_buff:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.dmg = ability:GetSpecialValueFor("bonus_attack_damage")
  else
    self.dmg = 25
  end
end

modifier_electrician_electric_shield_nc_buff.OnRefresh = modifier_electrician_electric_shield_nc_buff.OnCreated

function modifier_electrician_electric_shield_nc_buff:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
  }
end

function modifier_electrician_electric_shield_nc_buff:GetModifierPreAttack_BonusDamage()
  return self.dmg
end


--------------------------------------------------------------------------------
-- mana_pct_refund
--[[
function modifier_electrician_electric_shield:OnDestroy()
  if IsServer() then
    local parent = self:GetParent()
    local ability = self:GetAbility()

    if not parent or parent:IsNull() or not ability or ability:IsNull() then
      return
    end

    local manaRefundPercent = ability:GetSpecialValueFor("mana_pct_refund") / 100

    local firstCost = ability:GetManaCost(-1)
    local effectiveCost = ability:GetEffectiveManaCost(-1)

    if manaRefundPercent > 0 then
      local remainingShieldHP = 0 - self:GetStackCount()
      if remainingShieldHP > 0 then
        local shieldPerMana = ability:GetSpecialValueFor("shield_per_mana")
        local manaCost = (remainingShieldHP / shieldPerMana) * (effectiveCost / firstCost)
        parent:GiveMana(manaCost * manaRefundPercent)
      end
    end
  end
end
]]
