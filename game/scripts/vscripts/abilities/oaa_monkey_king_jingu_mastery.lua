monkey_king_jingu_mastery_oaa = class(AbilityBaseClass)

LinkLuaModifier("modifier_monkey_king_jingu_mastery_oaa", "abilities/oaa_monkey_king_jingu_mastery.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_monkey_king_jingu_mastery_oaa_buff", "abilities/oaa_monkey_king_jingu_mastery.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_monkey_king_jingu_mastery_oaa_count_debuff", "abilities/oaa_monkey_king_jingu_mastery.lua", LUA_MODIFIER_MOTION_NONE)

function monkey_king_jingu_mastery_oaa:GetIntrinsicModifierName()
  return "modifier_monkey_king_jingu_mastery_oaa"
end

function monkey_king_jingu_mastery_oaa:IsStealable()
  return false
end

function monkey_king_jingu_mastery_oaa:ProcMagicStick()
  return false
end

---------------------------------------------------------------------------------------------------

modifier_monkey_king_jingu_mastery_oaa = class(ModifierBaseClass)

function modifier_monkey_king_jingu_mastery_oaa:IsHidden()
  return true
end

function modifier_monkey_king_jingu_mastery_oaa:IsDebuff()
  return false
end

function modifier_monkey_king_jingu_mastery_oaa:IsPurgable()
  return false
end

function modifier_monkey_king_jingu_mastery_oaa:RemoveOnDeath()
  return false
end

function modifier_monkey_king_jingu_mastery_oaa:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_ATTACK_LANDED,
  }
end

if IsServer() then
  function modifier_monkey_king_jingu_mastery_oaa:OnAttackLanded(event)
    local parent = self:GetParent()
    local ability = self:GetAbility()
    local attacker = event.attacker
    local target = event.target

    -- Check if attacker exists
    if not attacker or attacker:IsNull() then
      return
    end

    -- Check if attacker has this modifier
    if attacker ~= parent then
      return
    end

    -- No charge gain while broken or illusion
    if parent:PassivesDisabled() or parent:IsIllusion() then
      return
    end

    -- Check if attacked unit exists
    if not target or target:IsNull() then
      return
    end

    -- Check for existence of GetUnitName method to determine if target is a unit or an item (or rune)
    -- items don't have that method -> nil; if the target is an item, don't continue
    if target.GetUnitName == nil then
      return
    end

    -- Don't affect buildings, wards, invulnerable units and illusions.
    if target:IsTower() or target:IsBarracks() or target:IsBuilding() or target:IsOther() or target:IsInvulnerable() or target:IsIllusion() then
      return
    end

    -- Don't trigger when attacking allies or self
    if target == parent or target:GetTeamNumber() == parent:GetTeamNumber() then
      return
    end

    -- Don't trigger when attacking creeps
    if target:IsCreep() and not target:IsOAABoss() then
      return
    end

    -- Check if parent already has Jingu Mastery buff
    if parent:HasModifier("modifier_monkey_king_jingu_mastery_oaa_buff") then
      return
    end

    local counter_duration = ability:GetSpecialValueFor("counter_duration")
    target:AddNewModifier(parent, ability, "modifier_monkey_king_jingu_mastery_oaa_count_debuff", {duration = counter_duration})
  end
end

---------------------------------------------------------------------------------------------------

modifier_monkey_king_jingu_mastery_oaa_count_debuff = class(ModifierBaseClass)

function modifier_monkey_king_jingu_mastery_oaa_count_debuff:IsHidden() -- needs tooltip
  return false
end

function modifier_monkey_king_jingu_mastery_oaa_count_debuff:IsDebuff()
  return true
end

function modifier_monkey_king_jingu_mastery_oaa_count_debuff:IsPurgable()
  return false
end

function modifier_monkey_king_jingu_mastery_oaa_count_debuff:OnCreated()
  local parent = self:GetParent()

  if not IsServer() then
    return
  end

  self:SetStackCount(1)

  -- Particle
  parent.jingu_overhead_particle = ParticleManager:CreateParticle("particles/units/heroes/hero_monkey_king/monkey_king_quad_tap_stack.vpcf", PATTACH_OVERHEAD_FOLLOW, parent)
  --ParticleManager:SetParticleControl(parent.jingu_overhead_particle, 0, parent:GetAbsOrigin())
  ParticleManager:SetParticleControl(parent.jingu_overhead_particle, 1, Vector(0, self:GetStackCount(), 0))
end

function modifier_monkey_king_jingu_mastery_oaa_count_debuff:OnRefresh()
  local parent = self:GetParent()
  local caster = self:GetCaster()
  local ability = self:GetAbility()
  local required_hit = 4
  local max_duration = 35
  if ability and not ability:IsNull() then
    required_hit = ability:GetSpecialValueFor("required_hits")
    max_duration = ability:GetSpecialValueFor("max_duration")
  end

  if not IsServer() then
    return
  end

  if self:GetStackCount() + 1 >= required_hit then
    -- Add Jingu Mastery buff to the caster/attacker if valid and not dead
    if caster and not caster:IsNull() and caster:IsAlive() then
      caster:AddNewModifier(caster, ability, "modifier_monkey_king_jingu_mastery_oaa_buff", {duration = max_duration})
    end

    -- Remove debuff counter from the parent
    self:Destroy()
  else
    self:IncrementStackCount()

    -- Update particle
    --ParticleManager:SetParticleControl(parent.jingu_overhead_particle, 0, parent:GetAbsOrigin())
    ParticleManager:SetParticleControl(parent.jingu_overhead_particle, 1, Vector(0, self:GetStackCount(), 0))
  end
end

function modifier_monkey_king_jingu_mastery_oaa_count_debuff:OnDestroy()
  local parent = self:GetParent()
  if parent and parent.jingu_overhead_particle then
    ParticleManager:DestroyParticle(parent.jingu_overhead_particle, false)
    ParticleManager:ReleaseParticleIndex(parent.jingu_overhead_particle)
    parent.jingu_overhead_particle = nil
  end
end

---------------------------------------------------------------------------------------------------

modifier_monkey_king_jingu_mastery_oaa_buff = class(ModifierBaseClass)

function modifier_monkey_king_jingu_mastery_oaa_buff:IsHidden() -- needs tooltip
  return false
end

function modifier_monkey_king_jingu_mastery_oaa_buff:IsDebuff()
  return false
end

function modifier_monkey_king_jingu_mastery_oaa_buff:IsPurgable()
  return true
end

function modifier_monkey_king_jingu_mastery_oaa_buff:OnCreated()
  local parent = self:GetParent()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.bonus_damage = ability:GetSpecialValueFor("bonus_damage")
    self.lifesteal = ability:GetSpecialValueFor("lifesteal")
    self.charges = ability:GetSpecialValueFor("charges")
  else
    self.bonus_damage = 30
    self.lifesteal = 20
    self.charges = 4
  end

  if not IsServer() then
    return
  end

  self:SetStackCount(self.charges)

  -- Initial particle
  local jingu_start_particle = ParticleManager:CreateParticle("particles/units/heroes/hero_monkey_king/monkey_king_quad_tap_start.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
  ParticleManager:SetParticleControl(jingu_start_particle, 0, parent:GetAbsOrigin())
  ParticleManager:ReleaseParticleIndex(jingu_start_particle)

  -- Sound
  parent:EmitSound("Hero_MonkeyKing.IronCudgel")

  if parent.jingubuff_overhead_particle == nil then
    parent.jingubuff_overhead_particle = ParticleManager:CreateParticle("particles/units/heroes/hero_monkey_king/monkey_king_quad_tap_overhead.vpcf", PATTACH_OVERHEAD_FOLLOW, parent)
  end

  if parent.jingubuff_weapon_glow_particle == nil then
    parent.jingubuff_weapon_glow_particle = ParticleManager:CreateParticle("particles/units/heroes/hero_monkey_king/monkey_king_tap_buff.vpcf", PATTACH_ROOTBONE_FOLLOW, parent)
    ParticleManager:SetParticleControlEnt(parent.jingubuff_weapon_glow_particle, 0, parent, PATTACH_ROOTBONE_FOLLOW, "attach_hitloc", parent:GetAbsOrigin(), true)
    ParticleManager:SetParticleControlEnt(parent.jingubuff_weapon_glow_particle, 2, parent, PATTACH_POINT_FOLLOW, "attach_weapon_top", parent:GetAbsOrigin(), true)
    ParticleManager:SetParticleControlEnt(parent.jingubuff_weapon_glow_particle, 3, parent, PATTACH_POINT_FOLLOW, "attach_weapon_bot", parent:GetAbsOrigin(), true)
  end

  self:StartIntervalThink(0.1)
end

modifier_monkey_king_jingu_mastery_oaa_buff.OnRefresh = modifier_monkey_king_jingu_mastery_oaa_buff.OnCreated

function modifier_monkey_king_jingu_mastery_oaa_buff:OnIntervalThink()
  local parent = self:GetParent()

  if parent:HasModifier("modifier_monkey_king_transform") then
    self:OnDestroy()
  else
    if parent.jingubuff_overhead_particle == nil then
      parent.jingubuff_overhead_particle = ParticleManager:CreateParticle("particles/units/heroes/hero_monkey_king/monkey_king_quad_tap_overhead.vpcf", PATTACH_OVERHEAD_FOLLOW, parent)
    end

    if parent.jingubuff_weapon_glow_particle == nil then
      parent.jingubuff_weapon_glow_particle = ParticleManager:CreateParticle("particles/units/heroes/hero_monkey_king/monkey_king_tap_buff.vpcf", PATTACH_ROOTBONE_FOLLOW, parent)
      ParticleManager:SetParticleControlEnt(parent.jingubuff_weapon_glow_particle, 0, parent, PATTACH_ROOTBONE_FOLLOW, "attach_hitloc", parent:GetAbsOrigin(), true)
      ParticleManager:SetParticleControlEnt(parent.jingubuff_weapon_glow_particle, 2, parent, PATTACH_POINT_FOLLOW, "attach_weapon_top", parent:GetAbsOrigin(), true)
      ParticleManager:SetParticleControlEnt(parent.jingubuff_weapon_glow_particle, 3, parent, PATTACH_POINT_FOLLOW, "attach_weapon_bot", parent:GetAbsOrigin(), true)
    end
  end
end

function modifier_monkey_king_jingu_mastery_oaa_buff:OnDestroy()
  local parent = self:GetParent()

  if parent.jingubuff_overhead_particle then
    ParticleManager:DestroyParticle(parent.jingubuff_overhead_particle, false)
    ParticleManager:ReleaseParticleIndex(parent.jingubuff_overhead_particle)
    parent.jingubuff_overhead_particle = nil
  end

  if parent.jingubuff_weapon_glow_particle  then
    ParticleManager:DestroyParticle(parent.jingubuff_weapon_glow_particle, false)
    ParticleManager:ReleaseParticleIndex(parent.jingubuff_weapon_glow_particle)
    parent.jingubuff_weapon_glow_particle = nil
  end
end

function modifier_monkey_king_jingu_mastery_oaa_buff:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
    MODIFIER_EVENT_ON_TAKEDAMAGE,
    MODIFIER_EVENT_ON_ATTACK_LANDED,
  }
end

function modifier_monkey_king_jingu_mastery_oaa_buff:GetModifierPreAttack_BonusDamage()
  return self.bonus_damage
end

if IsServer() then
  function modifier_monkey_king_jingu_mastery_oaa_buff:OnAttackLanded(event)
    local parent = self:GetParent()
    local attacker = event.attacker
    local target = event.target

    -- Check if attacker exists
    if not attacker or attacker:IsNull() then
      return
    end

    -- Check if attacker has this modifier
    if attacker ~= parent then
      return
    end

    -- If attacker is an illusion or dead, dont continue and destroy the modifier
    if parent:IsIllusion() or not parent:IsAlive() then
      self:Destroy()
      return
    end

    -- Check if attacked unit exists
    if not target or target:IsNull() then
      return
    end

    -- Check for existence of GetUnitName method to determine if target is a unit or an item (or rune)
    -- items don't have that method -> nil; if the target is an item, don't continue
    if target.GetUnitName == nil then
      return
    end

    -- Don't affect buildings, wards and invulnerable units
    if target:IsTower() or target:IsBarracks() or target:IsBuilding() or target:IsOther() or target:IsInvulnerable() then
      return
    end

    -- Don't trigger when attacking self
    if target == parent then
      return
    end

    -- Lifesteal is handled in OnTakeDamage

    -- jingu hit pfx
    local hitPfx = ParticleManager:CreateParticle("particles/units/heroes/hero_monkey_king/monkey_king_quad_tap_hit.vpcf", PATTACH_ROOTBONE_FOLLOW, target)
    ParticleManager:SetParticleControl(hitPfx, 1, target:GetAbsOrigin())
    ParticleManager:ReleaseParticleIndex(hitPfx)

    -- Do not consume a charge if instant attack
    if event.no_attack_cooldown then
      return
    end

    -- Consume a charge
    self:DecrementStackCount()
    if self:GetStackCount() <= 0 then
      self:Destroy()
    end
  end

  function modifier_monkey_king_jingu_mastery_oaa_buff:OnTakeDamage(event)
    local parent = self:GetParent()
    local ability = self:GetAbility()
    local amount = self.lifesteal

    local attacker = event.attacker
    local damaged_unit = event.unit
    local damage = event.damage

    -- Check if attacker exists
    if not attacker or attacker:IsNull() then
      return
    end

    -- Check if attacker has this modifier
    if attacker ~= parent then
      return
    end

    -- Check if damaged entity exists (recently dead units could be marked as Null)
    if not damaged_unit or damaged_unit:IsNull() then
      return
    end

    -- Don't heal while dead
    if not parent:IsAlive() then
      return
    end

    if damage <= 0 or amount <= 0 then
      return
    end

    -- Normal lifesteal should not work for spells and magic damage attacks
    if event.damage_category ~= DOTA_DAMAGE_CATEGORY_ATTACK or event.damage_type ~= DAMAGE_TYPE_PHYSICAL then
      return
    end

    if parent:HasModifier("modifier_wukongs_command_oaa_no_lifesteal") then
      return
    end

    local parentTeam = parent:GetTeamNumber()

    local ufResult = UnitFilter(
      damaged_unit,
      DOTA_UNIT_TARGET_TEAM_ENEMY,
      bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO),
      bit.bor(DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, DOTA_UNIT_TARGET_FLAG_DEAD),
      parentTeam
    )

    if ufResult == UF_SUCCESS then
      local lifesteal_amount = damage * amount * 0.01
      parent:HealWithParams(lifesteal_amount, ability, true, true, parent, false)

      local part = ParticleManager:CreateParticle( "particles/generic_gameplay/generic_lifesteal.vpcf", PATTACH_ABSORIGIN, parent )
      ParticleManager:ReleaseParticleIndex( part )
    end
  end
end
