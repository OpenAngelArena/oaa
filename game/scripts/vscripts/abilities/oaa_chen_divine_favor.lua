chen_divine_favor_oaa = class(AbilityBaseClass)

LinkLuaModifier("modifier_chen_divine_favor_shield_oaa", "abilities/oaa_chen_divine_favor.lua", LUA_MODIFIER_MOTION_NONE)

function chen_divine_favor_oaa:Precache(context)
  PrecacheResource("particle", "particles/units/heroes/hero_chen/chen_divine_favor_custom.vpcf", context)
  PrecacheResource("particle", "particles/items_fx/wand_of_the_brine_buff.vpcf", context)
end

function chen_divine_favor_oaa:OnUpgrade()
  local caster = self:GetCaster()
  local ability_level = self:GetLevel()
  local vanilla_ability = caster:FindAbilityByName("chen_divine_favor")

	-- Check to not enter a level up loop
  if vanilla_ability and vanilla_ability:GetLevel() ~= ability_level then
    vanilla_ability:SetLevel(ability_level)
  end
end

function chen_divine_favor_oaa:GetAOERadius()
  return self:GetSpecialValueFor("effect_radius")
end

function chen_divine_favor_oaa:OnSpellStart()
  local caster = self:GetCaster()
  local target_pos = self:GetCursorPosition()
  local caster_team = caster:GetTeamNumber()

  local damage_table = {
    attacker = caster,
    damage_type = self:GetAbilityDamageType(),
    ability = self,
    damage = self:GetSpecialValueFor("damage"),
  }

  local radius = self:GetSpecialValueFor("effect_radius")
  local duration = self:GetSpecialValueFor("shield_duration")

  -- Particle
  local p = ParticleManager:CreateParticle("particles/units/heroes/hero_chen/chen_divine_favor_custom.vpcf", PATTACH_WORLDORIGIN, caster)
  ParticleManager:SetParticleControl(p, 0, Vector(target_pos.x, target_pos.y, target_pos.z+100))
  ParticleManager:ReleaseParticleIndex(p)

  -- Sound
  caster:EmitSound("Hero_Chen.DivineFavor.Target")

  -- Find enemies in the area
  local enemies = FindUnitsInRadius(
    caster_team,
    target_pos,
    nil,
    radius,
    DOTA_UNIT_TARGET_TEAM_ENEMY,
    bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC),
    DOTA_UNIT_TARGET_FLAG_NONE,
    FIND_ANY_ORDER,
    false
  )

  local allies = FindUnitsInRadius(
    caster_team,
    target_pos,
    nil,
    radius,
    DOTA_UNIT_TARGET_TEAM_FRIENDLY,
    bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC),
    DOTA_UNIT_TARGET_FLAG_INVULNERABLE,
    FIND_ANY_ORDER,
    false
  )

  -- Deal damage to each enemy
  for _, enemy in pairs(enemies) do
    if enemy and not enemy:IsNull() and not enemy:IsMagicImmune() and not enemy:IsInvulnerable() then
      -- Apply damage
      damage_table.victim = enemy
      ApplyDamage(damage_table)
    end
  end

  -- Do something for allies (shield, heal...)
  for _, ally in pairs(allies) do
    if ally and not ally:IsNull() then
      -- Apply physical damage shield
      ally:AddNewModifier(caster, self, "modifier_chen_divine_favor_shield_oaa", {duration = duration})
      -- Heal allies
      --ally:Heal(heal, self)
    end
  end
end

function chen_divine_favor_oaa:ProcsMagicStick()
  return true
end

function chen_divine_favor_oaa:IsStealable()
  return true
end

---------------------------------------------------------------------------------------------------

modifier_chen_divine_favor_shield_oaa = class(ModifierBaseClass)

function modifier_chen_divine_favor_shield_oaa:IsHidden()
  return false
end

function modifier_chen_divine_favor_shield_oaa:IsDebuff()
  return false
end

function modifier_chen_divine_favor_shield_oaa:IsPurgable()
  return true
end

function modifier_chen_divine_favor_shield_oaa:OnCreated()
  local ability = self:GetAbility()
  if ability then
    self.max_shield_hp = ability:GetSpecialValueFor("shield")
  end
  if IsServer() then
    self:SetStackCount(self.max_shield_hp)
  end
end

modifier_chen_divine_favor_shield_oaa.OnRefresh = modifier_chen_divine_favor_shield_oaa.OnCreated

function modifier_chen_divine_favor_shield_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_INCOMING_PHYSICAL_DAMAGE_CONSTANT,
  }
end

function modifier_chen_divine_favor_shield_oaa:GetModifierIncomingPhysicalDamageConstant(event)
  if IsClient() then
    if event.report_max then
      return self.max_shield_hp
    else
      return self:GetStackCount() -- current shield hp
    end
  else
    local parent = self:GetParent()
    local damage = event.damage
    local barrier_hp = self:GetStackCount()

    -- Don't block more than remaining hp
    local block_amount = math.min(damage, barrier_hp)

    -- Reduce barrier hp
    self:SetStackCount(barrier_hp - block_amount)

    if block_amount > 0 then
      -- Visual effect
      SendOverheadEventMessage(nil, OVERHEAD_ALERT_BLOCK, parent, block_amount, nil)
    end

    -- Remove the barrier if hp is reduced to nothing
    if self:GetStackCount() <= 0 then
      self:Destroy()
    end

    return -block_amount
  end
end

function modifier_chen_divine_favor_shield_oaa:GetEffectName()
  return "particles/items_fx/wand_of_the_brine_buff.vpcf"
end

function modifier_chen_divine_favor_shield_oaa:GetEffectAttachType()
  return PATTACH_ABSORIGIN_FOLLOW
end
