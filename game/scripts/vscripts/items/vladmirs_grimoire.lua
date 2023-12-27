LinkLuaModifier("modifier_item_vladmirs_grimoire_passive", "items/vladmirs_grimoire.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_vladmirs_grimoire_aura_effect", "items/vladmirs_grimoire.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_vladmirs_grimoire_active", "items/vladmirs_grimoire.lua", LUA_MODIFIER_MOTION_NONE)

item_vladmirs_grimoire_1 = class(ItemBaseClass)

function item_vladmirs_grimoire_1:OnSpellStart()
  local caster = self:GetCaster()
  local ability = self

  local units = FindUnitsInRadius(
    caster:GetTeamNumber(),
    caster:GetAbsOrigin(),
    nil,
    FIND_UNITS_EVERYWHERE,
    DOTA_UNIT_TARGET_TEAM_FRIENDLY,
    bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO),
    bit.bor(DOTA_UNIT_TARGET_FLAG_PLAYER_CONTROLLED, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD),
    FIND_ANY_ORDER,
    false
  )

  local function CheckIfValid(unit)
    if not unit or unit:IsNull() then
      return false
    end
    if unit.IsBaseNPC == nil or unit.HasModifier == nil or unit.GetUnitName == nil then
      return false
    end
    local name = unit:GetUnitName()
    local valid_name = name ~= "npc_dota_custom_dummy_unit" and name ~= "npc_dota_elder_titan_ancestral_spirit" and name ~= "aghsfort_mars_bulwark_soldier" and name ~= "npc_dota_monkey_clone_oaa"
    local not_thinker = not unit:HasModifier("modifier_oaa_thinker") and not unit:IsPhantomBlocker()

    return not unit:IsCourier() and unit:HasMovementCapability() and not_thinker and valid_name -- and not unit:IsZombie()
  end

  iter(units)
    :filter(function (unit)
      return unit ~= caster and CheckIfValid(unit) and unit:GetPlayerOwnerID() == caster:GetPlayerOwnerID()
    end)
    :foreach(function (unit)
      -- Banish modifier
      unit:AddNewModifier(caster, ability, "modifier_item_vladmirs_grimoire_active", {duration = ability:GetSpecialValueFor("banish_duration")})

      -- Disjoint disjointable projectiles
      ProjectileManager:ProjectileDodge(unit)

      -- Absolute Purge (Strong Dispel + removing most undispellable buffs and debuffs)
      unit:AbsolutePurge()

      -- Hide it
      unit:AddNoDraw()
      unit:SetAbsOrigin(Vector(-10000, -10000, -10000))
    end)

  -- Activation Sound
  caster:EmitSound("Miniboss.Tormenter.Base.Open")
end

function item_vladmirs_grimoire_1:GetIntrinsicModifierName()
  return "modifier_item_vladmirs_grimoire_passive"
end

item_vladmirs_grimoire_2 = item_vladmirs_grimoire_1
item_vladmirs_grimoire_3 = item_vladmirs_grimoire_1
item_vladmirs_grimoire_4 = item_vladmirs_grimoire_1
item_vladmirs_grimoire_5 = item_vladmirs_grimoire_1

------------------------------------------------------------------------------

modifier_item_vladmirs_grimoire_passive = class(ModifierBaseClass)

function modifier_item_vladmirs_grimoire_passive:IsHidden()
  return true
end

function modifier_item_vladmirs_grimoire_passive:IsDebuff()
  return false
end

function modifier_item_vladmirs_grimoire_passive:IsPurgable()
  return false
end

function modifier_item_vladmirs_grimoire_passive:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_vladmirs_grimoire_passive:OnCreated()
  self:OnRefresh()
end

function modifier_item_vladmirs_grimoire_passive:OnRefresh()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.stats = ability:GetSpecialValueFor("bonus_all_stats")
    self.health = ability:GetSpecialValueFor("bonus_health")
    self.mana = ability:GetSpecialValueFor("bonus_mana")
    self.aura_radius = ability:GetSpecialValueFor("aura_radius")
  end
end

function modifier_item_vladmirs_grimoire_passive:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
    MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
    MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
    MODIFIER_PROPERTY_HEALTH_BONUS,
    MODIFIER_PROPERTY_MANA_BONUS,
  }
end

function modifier_item_vladmirs_grimoire_passive:GetModifierBonusStats_Strength()
  return self.stats or self:GetAbility():GetSpecialValueFor("bonus_all_stats")
end

function modifier_item_vladmirs_grimoire_passive:GetModifierBonusStats_Agility()
  return self.stats or self:GetAbility():GetSpecialValueFor("bonus_all_stats")
end

function modifier_item_vladmirs_grimoire_passive:GetModifierBonusStats_Intellect()
  return self.stats or self:GetAbility():GetSpecialValueFor("bonus_all_stats")
end

function modifier_item_vladmirs_grimoire_passive:GetModifierHealthBonus()
  return self.health or self:GetAbility():GetSpecialValueFor("bonus_health")
end

function modifier_item_vladmirs_grimoire_passive:GetModifierManaBonus()
  return self.mana or self:GetAbility():GetSpecialValueFor("bonus_mana")
end

--------------------------------------------------------------------------
-- aura stuff

function modifier_item_vladmirs_grimoire_passive:IsAura()
  return true
end

function modifier_item_vladmirs_grimoire_passive:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO)
end

function modifier_item_vladmirs_grimoire_passive:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_item_vladmirs_grimoire_passive:GetAuraRadius()
  return self.aura_radius or self:GetAbility():GetSpecialValueFor("aura_radius")
end

function modifier_item_vladmirs_grimoire_passive:GetAuraEntityReject(hTarget)
  return hTarget:HasModifier("modifier_item_imba_vladmir_blood_aura")
end

function modifier_item_vladmirs_grimoire_passive:GetModifierAura()
  return "modifier_item_vladmirs_grimoire_aura_effect"
end

---------------------------------------------------------------------------------------------------
-- Custom Vladmir Aura effect
modifier_item_vladmirs_grimoire_aura_effect = class({})

function modifier_item_vladmirs_grimoire_aura_effect:IsHidden()
  local parent = self:GetParent()
  return parent:HasModifier("modifier_item_vladmir_aura")
end

function modifier_item_vladmirs_grimoire_aura_effect:IsDebuff()
  return false
end

function modifier_item_vladmirs_grimoire_aura_effect:IsPurgable()
  return false
end

function modifier_item_vladmirs_grimoire_aura_effect:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
    MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
    MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE,
    MODIFIER_PROPERTY_TOTAL_CONSTANT_BLOCK,
    MODIFIER_PROPERTY_TOOLTIP,
    MODIFIER_PROPERTY_TOOLTIP2,
    MODIFIER_EVENT_ON_TAKEDAMAGE,
  }
end

function modifier_item_vladmirs_grimoire_aura_effect:GetModifierPhysicalArmorBonus()
  local ability = self:GetAbility()
  if not ability or ability:IsNull() then
    return 0
  end
  local parent = self:GetParent()
  if parent:HasModifier("modifier_item_vladmir_aura") then
    return 0
  end
  return ability:GetSpecialValueFor("armor_aura")
end

function modifier_item_vladmirs_grimoire_aura_effect:GetModifierConstantManaRegen()
  local ability = self:GetAbility()
  if not ability or ability:IsNull() then
    return 0
  end
  local parent = self:GetParent()
  if parent:HasModifier("modifier_item_vladmir_aura") then
    return 0
  end
  return ability:GetSpecialValueFor("mana_regen_aura")
end

function modifier_item_vladmirs_grimoire_aura_effect:GetModifierBaseDamageOutgoing_Percentage()
  local ability = self:GetAbility()
  if not ability or ability:IsNull() then
    return 0
  end
  local parent = self:GetParent()
  if parent:HasModifier("modifier_item_vladmir_aura") then
    return 0
  end
  return ability:GetSpecialValueFor("damage_aura")
end

if IsServer() then
  function modifier_item_vladmirs_grimoire_aura_effect:GetModifierTotal_ConstantBlock(event)
    local ability = self:GetAbility()
    if not ability or ability:IsNull() then
      return 0
    end

    local attacker = event.attacker
    if not attacker or attacker:IsNull() then
      return 0
    end

    if attacker.IsBaseNPC == nil then
      return 0
    end

    if not attacker:IsBaseNPC() then
      return 0
    end

    local dmg_reduction = ability:GetSpecialValueFor("damage_reduction_against_bosses")

    -- Block damage from from bosses
    if attacker:IsOAABoss() then
      return event.damage * dmg_reduction / 100
    end

    return 0
  end

  function modifier_item_vladmirs_grimoire_aura_effect:OnTakeDamage(event)
    local parent = self:GetParent()
    local ability = self:GetAbility()
    local attacker = event.attacker
    local damaged_unit = event.unit
    local damage = event.damage
    local inflictor = event.inflictor

    if not ability or ability:IsNull() then
      return
    end

    -- Check if parent already has Vladmir Aura
    if parent:HasModifier("modifier_item_vladmir_aura") then
      return
    end

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

    -- Ignore self damage
    if damaged_unit == attacker then
      return
    end

    -- Check if entity is an item, rune or something weird
    if damaged_unit.GetUnitName == nil then
      return
    end

    -- Don't affect buildings, wards and invulnerable units.
    if damaged_unit:IsTower() or damaged_unit:IsBarracks() or damaged_unit:IsBuilding() or damaged_unit:IsOther() or damaged_unit:IsInvulnerable() then
      return
    end

    -- Normal lifesteal should not work for spells and magic damage attacks
    if inflictor or event.damage_category == DOTA_DAMAGE_CATEGORY_SPELL or event.damage_type ~= DAMAGE_TYPE_PHYSICAL then
      return
    end

    -- Calculate the lifesteal (heal) amount
    local lifesteal = ability:GetSpecialValueFor("lifesteal_aura")
    local heal_amount = damage * lifesteal / 100

    -- Normal Lifesteal (physical dmg attacks)
    if heal_amount > 0 then
      attacker:HealWithParams(heal_amount, nil, true, true, attacker, false)
      -- Particle
      local particle = ParticleManager:CreateParticle("particles/generic_gameplay/generic_lifesteal.vpcf", PATTACH_ABSORIGIN_FOLLOW, attacker)
      ParticleManager:ReleaseParticleIndex(particle)
    end
  end
end

function modifier_item_vladmirs_grimoire_aura_effect:OnTooltip()
  local ability = self:GetAbility()
  if not ability or ability:IsNull() then
    return 0
  end
  return ability:GetSpecialValueFor("lifesteal_aura")
end

function modifier_item_vladmirs_grimoire_aura_effect:OnTooltip2()
  local ability = self:GetAbility()
  if not ability or ability:IsNull() then
    return 0
  end
  return ability:GetSpecialValueFor("damage_reduction_against_bosses")
end

---------------------------------------------------------------------------------------------------

modifier_item_vladmirs_grimoire_active = class(ModifierBaseClass)

function modifier_item_vladmirs_grimoire_active:IsHidden()
  return true
end

function modifier_item_vladmirs_grimoire_active:IsDebuff()
  return false
end

function modifier_item_vladmirs_grimoire_active:IsPurgable()
  return false
end

function modifier_item_vladmirs_grimoire_active:CheckState()
  return {
    [MODIFIER_STATE_ROOTED] = true,
    [MODIFIER_STATE_ATTACK_IMMUNE] = true,
    [MODIFIER_STATE_MAGIC_IMMUNE] = true,
    [MODIFIER_STATE_SILENCED] = true,
    [MODIFIER_STATE_MUTED] = true,
    [MODIFIER_STATE_INVULNERABLE] = true,
    [MODIFIER_STATE_UNSELECTABLE] = true,
    [MODIFIER_STATE_NO_HEALTH_BAR] = true,
    [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
    [MODIFIER_STATE_NOT_ON_MINIMAP] = true,
    [MODIFIER_STATE_OUT_OF_GAME] = true,
    [MODIFIER_STATE_BLIND] = true,
    [MODIFIER_STATE_DISARMED] = true,
    [MODIFIER_STATE_COMMAND_RESTRICTED] = true,
  }
end

function modifier_item_vladmirs_grimoire_active:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_DEATH,
	}
end

if IsServer() then
  function modifier_item_vladmirs_grimoire_active:OnDeath(event)
    if event.unit == self:GetCaster() then
      self.killer = event.attacker
      self:Destroy()
    end
  end


  function modifier_item_vladmirs_grimoire_active:OnDestroy()
    local parent = self:GetParent()
    local caster = self:GetCaster()

    if not caster or caster:IsNull() then
      if parent and not parent:IsNull() and parent:IsAlive() then
        parent:ForceKillOAA(false)
        return
      end
    end

    if not caster:IsAlive() then
      if parent and not parent:IsNull() and parent:IsAlive() then
        parent:Kill(self:GetAbility(), self.killer)
        return
      end
    end

    local direction = caster:GetForwardVector()
    -- Remove vertical component
    direction.z = 0
    local point = caster:GetAbsOrigin() + direction * 200

    -- Unhide
    --parent:SetAbsOrigin(point)
    FindClearSpaceForUnit(parent, point, true)
    parent:RemoveNoDraw()
    parent:AddNewModifier(parent, nil, "modifier_phased", {duration = FrameTime()})
    caster:AddNewModifier(caster, nil, "modifier_phased", {duration = FrameTime()})
    caster:EmitSound("Miniboss.Tormenter.Base.Close")
  end
end