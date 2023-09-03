item_vampire = class(ItemBaseClass)

local vampire = {}

LinkLuaModifier("modifier_item_vampire", "items/vampire.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_vampire_active", "items/vampire.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_vampire_active_detect_life_effect", "items/vampire.lua", LUA_MODIFIER_MOTION_NONE)

--------------------------------------------------------------------------------

function item_vampire:GetIntrinsicModifierName()
  return "modifier_item_vampire"
end

function item_vampire:OnSpellStart()
  local caster = self:GetCaster()
  local modifierName = "modifier_item_vampire_active"

  caster:AddNewModifier(caster, self, modifierName, {duration = self:GetSpecialValueFor("duration")})
end

item_vampire_2 = item_vampire

--------------------------------------------------------------------------------

modifier_item_vampire = class(ModifierBaseClass)

function modifier_item_vampire:IsHidden()
  return true
end

function modifier_item_vampire:IsDebuff()
	return false
end

function modifier_item_vampire:IsPurgable()
	return false
end

function modifier_item_vampire:OnCreated()
  if not self.procRecords then
    self.procRecords = {}
  end
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.bonus_dmg = ability:GetSpecialValueFor("bonus_damage")
    self.bonus_str = ability:GetSpecialValueFor("bonus_strength")
    self.bonus_status_resist = ability:GetSpecialValueFor("bonus_status_resistance")
    self.bonus_attack_speed = ability:GetSpecialValueFor("bonus_attack_speed")
    self.bonus_night_vision = ability:GetSpecialValueFor("bonus_night_vision")
  end
end

modifier_item_vampire.OnRefresh = modifier_item_vampire.OnCreated

function modifier_item_vampire:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING,
    MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
    MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
    MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
    MODIFIER_PROPERTY_BONUS_NIGHT_VISION,
    MODIFIER_EVENT_ON_TAKEDAMAGE,
    MODIFIER_EVENT_ON_ATTACK_LANDED
  }
end

function modifier_item_vampire:GetModifierPreAttack_BonusDamage()
  return self.bonus_dmg or self:GetAbility():GetSpecialValueFor("bonus_damage")
end

function modifier_item_vampire:GetModifierBonusStats_Strength()
  return self.bonus_str or self:GetAbility():GetSpecialValueFor("bonus_strength")
end

function modifier_item_vampire:GetModifierStatusResistanceStacking()
  return self.bonus_status_resist or self:GetAbility():GetSpecialValueFor("bonus_status_resistance")
end

function modifier_item_vampire:GetModifierAttackSpeedBonus_Constant()
  return self.bonus_attack_speed or self:GetAbility():GetSpecialValueFor("bonus_attack_speed")
end

function modifier_item_vampire:GetBonusNightVision()
  return self.bonus_night_vision or self:GetAbility():GetSpecialValueFor("bonus_night_vision")
end

if IsServer() then
  -- Have to check for process_procs flag in OnAttackLanded as the flag won't be set in OnTakeDamage
  function modifier_item_vampire:OnAttackLanded(event)
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

    -- Check if attacked entity exists
    if not target or target:IsNull() then
      return
    end

    -- Check if attacked entity is an item, rune or something weird
    if target.GetUnitName == nil then
      return
    end

    self.procRecords[event.record] = true
  end

  function modifier_item_vampire:OnTakeDamage(event)
    local parent = self:GetParent()
    local spell = self:GetAbility()
    local attacker = event.attacker
    local damaged_unit = event.unit

    -- Check if attacker exists
    if not attacker or attacker:IsNull() then
      return
    end

    -- Check if attacker has this modifier
    if attacker ~= parent then
      return
    end

    -- Check if damaged entity exists
    if not damaged_unit or damaged_unit:IsNull() then
      return
    end

    vampire.lifesteal(self, event, spell, parent, spell:GetSpecialValueFor('lifesteal_percent'))
  end
end

--------------------------------------------------------------------------------

modifier_item_vampire_active = class(ModifierBaseClass)

function modifier_item_vampire_active:IsHidden()
  return false
end

function modifier_item_vampire_active:IsDebuff()
  return false
end

-- this doesn't do anything since it's an aura, and auras are undispellable no matter what you set here
function modifier_item_vampire_active:IsPurgable()
  return false
end

function modifier_item_vampire_active:IsAura()
  return self:GetStackCount() == 0
end

function modifier_item_vampire_active:GetModifierAura()
  return "modifier_item_vampire_active_detect_life_effect"
end

function modifier_item_vampire_active:GetAuraRadius()
  if self:GetStackCount() == 1 then
    return 1
  else
    local ability = self:GetAbility()
    if ability and not ability:IsNull() then
      return ability:GetSpecialValueFor("night_thirst_radius")
    else
      return 1200
    end
  end
end

function modifier_item_vampire_active:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_item_vampire_active:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC)
end

function modifier_item_vampire_active:OnCreated()
  if IsServer() then
    if not self.procRecords then
      self.procRecords = {}
    end

    local parent = self:GetParent()
    local ability = self:GetAbility()
    local interval = 1/4
    if ability and not ability:IsNull() then
      interval = 1 / ability:GetSpecialValueFor("ticks_per_second")
    end
    self:StartIntervalThink(interval)

    parent:EmitSound("Vampire.Activate.Begin")

    if self.particle == nil then
      self.particle = ParticleManager:CreateParticle( "particles/items/vampire/vampire.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent )
    end

    if not GameRules:IsDaytime() then
      self:SetStackCount(0)
    else
      self:SetStackCount(1)
    end
  end
end

function modifier_item_vampire_active:OnRefresh()
  if IsServer() then
    if not self.procRecords then
      self.procRecords = {}
    end

	if self.particle then
      ParticleManager:DestroyParticle(self.particle, true)
      ParticleManager:ReleaseParticleIndex(self.particle)
      self.particle = nil
    end

    local parent = self:GetParent()

    parent:EmitSound("Vampire.Activate.Begin")

    if self.particle == nil then
      self.particle = ParticleManager:CreateParticle( "particles/items/vampire/vampire.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent )
    end
  end
end

function modifier_item_vampire_active:OnDestroy()
  if IsServer() and self.particle then
    ParticleManager:DestroyParticle(self.particle, false)
    ParticleManager:ReleaseParticleIndex(self.particle)
    self.particle = nil
  end
end

function modifier_item_vampire_active:OnIntervalThink()
  if IsServer() then
    -- Don't do damage during the night
    if not GameRules:IsDaytime() then
      self:SetStackCount(0)
      return
    else
      self:SetStackCount(1)
    end
    local parent = self:GetParent()
    local spell = self:GetAbility()
    if not spell or spell:IsNull() then
      if not self:IsNull() then
        self:StartIntervalThink(-1)
        self:Destroy()
      end
      return
    end

    local damage = parent:GetHealth() * spell:GetSpecialValueFor('damage_per_second_pct') / 100
    damage = damage / spell:GetSpecialValueFor('ticks_per_second')

    local damageTable = {
      victim = parent,
      attacker = parent,
      damage = damage,
      damage_type = DAMAGE_TYPE_PURE,
      damage_flags = bit.bor(DOTA_DAMAGE_FLAG_HPLOSS, DOTA_DAMAGE_FLAG_NO_DAMAGE_MULTIPLIERS, DOTA_DAMAGE_FLAG_REFLECTION, DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION, DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL),
      ability = spell,
    }

    ApplyDamage( damageTable )
  end
end

function modifier_item_vampire_active:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
    MODIFIER_EVENT_ON_TAKEDAMAGE,
    MODIFIER_EVENT_ON_ATTACK_LANDED,
  }
end

function modifier_item_vampire_active:GetModifierPreAttack_BonusDamage()
  if self:GetStackCount() == 1 then
    return 0
  else
    local ability = self:GetAbility()
    if ability and not ability:IsNull() then
      return ability:GetSpecialValueFor("night_bonus_damage")
    else
      return 110
    end
  end
end

if IsServer() then
  -- Have to check for process_procs flag in OnAttackLanded as the flag won't be set in OnTakeDamage
  function modifier_item_vampire_active:OnAttackLanded(event)
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

    -- Check if attacked entity exists
    if not target or target:IsNull() then
      return
    end

    -- Check if attacked entity is an item, rune or something weird
    if target.GetUnitName == nil then
      return
    end

    self.procRecords[event.record] = true
  end

  function modifier_item_vampire_active:OnTakeDamage(event)
    local parent = self:GetParent()
    local spell = self:GetAbility()
    local attacker = event.attacker
    local damaged_unit = event.unit

    -- Check if attacker exists
    if not attacker or attacker:IsNull() then
      return
    end

    -- Check if attacker has this modifier
    if attacker ~= parent then
      return
    end

    -- Check if damaged entity exists
    if not damaged_unit or damaged_unit:IsNull() then
      return
    end

    self.isVampHeal = true
    vampire.lifesteal(self, event, spell, parent, spell:GetSpecialValueFor('active_lifesteal_percent'))
    self.isVampHeal = false
  end

  function vampire:lifesteal(event, spell, parent, amount)
    if not event or not parent or parent:IsNull() or not amount then
      return
    end

    local attacker = event.attacker
    local damaged_unit = event.unit
    local damage = event.damage

    -- Check if attacker exists
    if not attacker or attacker:IsNull() then
      return
    end

    if attacker ~= parent or not self.procRecords[event.record] then
      return
    end

    -- Check if damaged entity exists (recently dead units could be marked as Null)
    if not damaged_unit or damaged_unit:IsNull() then
      return
    end

    self.procRecords[event.record] = nil

    if damage <= 0 or amount <= 0 then
      return
    end

    if event.damage_category ~= DOTA_DAMAGE_CATEGORY_ATTACK then
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
      parent:HealWithParams(lifesteal_amount, spell, true, true, parent, false)

      local part = ParticleManager:CreateParticle( "particles/generic_gameplay/generic_lifesteal.vpcf", PATTACH_ABSORIGIN, parent )
      ParticleManager:ReleaseParticleIndex( part )

      if parent:HasModifier( "modifier_item_vampire_active" ) then
        ProjectileManager:CreateTrackingProjectile( {
          Target = parent,
          Source = damaged_unit,
          EffectName = "particles/items/vampire/vampire_projectile.vpcf",
          iMoveSpeed = 600,
          vSourceLoc = damaged_unit:GetOrigin(),
          bDodgeable = false,
          bProvidesVision = false,
        } )
      end

    else
      DebugPrint('Not lifestealing from ' .. tostring(damaged_unit:GetName()))
    end
  end
end

function modifier_item_vampire_active:GetTexture()
  return "custom/vampire_2_active"
end

---------------------------------------------------------------------------------------------------

modifier_item_vampire_active_detect_life_effect = class(ModifierBaseClass)

function modifier_item_vampire_active_detect_life_effect:IsHidden()
  return false
end

function modifier_item_vampire_active_detect_life_effect:IsDebuff()
  return true
end

function modifier_item_vampire_active_detect_life_effect:IsPurgable()
  return false
end

function modifier_item_vampire_active_detect_life_effect:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PROVIDES_FOW_POSITION,
	}
end

function modifier_item_vampire_active_detect_life_effect:GetModifierProvidesFOWVision()
	return 1
end

function modifier_item_vampire_active_detect_life_effect:GetTexture()
  return "custom/vampire_2_active"
end
